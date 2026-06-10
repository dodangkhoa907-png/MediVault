package com.medivault.controller;

import com.medivault.dao.*;
import com.medivault.dao.interfaces.*;
import com.medivault.entity.*;
import com.medivault.util.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * LeaveRequestServlet — Xin nghỉ (staff) + Duyệt (admin).
 * URL: /leave-requests
 *
 * ADMIN: list / pending / approve / reject
 * STAFF: my / new / submit
 */
@WebServlet("/leave-requests")
public class LeaveRequestServlet extends HttpServlet {

    private final ILeaveRequestDAO  leaveDAO    = new LeaveRequestDAO();
    private final IShiftScheduleDAO scheduleDAO = new ShiftScheduleDAO();
    private final IShiftDAO         shiftDAO    = new ShiftDAO();
    private final IPayrollDAO       payrollDAO  = new PayrollDAO();
    private final IAccountDAO       accountDAO  = new AccountDAO();
    private final IShiftTypeDAO     typeDAO     = new ShiftTypeDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "pending";

        HttpSession session = req.getSession(false);
        Account adminAcc = session != null ? (Account) session.getAttribute("adminAccount") : null;

        if ("my".equals(action) || "new".equals(action)) {
            handleStaffView(req, resp, action);
        } else {
            if (adminAcc == null || adminAcc.getRoleId() != 1) {
                resp.sendRedirect(req.getContextPath() + "/login"); return;
            }
            switch (action) {
                case "list"    -> showAdminList(req, resp);
                case "pending" -> showPending(req, resp);
                default        -> showPending(req, resp);
            }
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");
        HttpSession session = req.getSession(false);
        Account adminAcc = session != null ? (Account) session.getAttribute("adminAccount") : null;

        if ("submit".equals(action)) {
            handleStaffSubmit(req, resp);
        } else if ("approve".equals(action) || "reject".equals(action)) {
            if (adminAcc == null || adminAcc.getRoleId() != 1) {
                resp.sendRedirect(req.getContextPath() + "/login"); return;
            }
            handleAdminDecision(req, resp, adminAcc, action);
        } else {
            resp.sendRedirect(req.getContextPath() + "/leave-requests");
        }
    }

    // ── Admin: danh sách tháng ────────────────────────────────────────────────
    private void showAdminList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        int month = LocalDate.now().getMonthValue();
        int year  = LocalDate.now().getYear();
        try {
            if (req.getParameter("month") != null)
                month = Integer.parseInt(req.getParameter("month"));
            if (req.getParameter("year") != null)
                year  = Integer.parseInt(req.getParameter("year"));
        } catch (NumberFormatException ignored) {}

        req.setAttribute("leaves",  leaveDAO.findByMonth(month, year));
        req.setAttribute("month",   month);
        req.setAttribute("year",    year);
        NotificationUtil.loadAdminNotifications(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/leave-request-list.jsp").forward(req, resp);
    }

    // ── Admin: đơn chờ duyệt ─────────────────────────────────────────────────
    private void showPending(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        List<LeaveRequest> pending = leaveDAO.findPending();
        req.setAttribute("pending", pending);
        NotificationUtil.loadAdminNotifications(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/leave-request-pending.jsp").forward(req, resp);
    }

    // ── Admin: duyệt / từ chối ───────────────────────────────────────────────
    private void handleAdminDecision(HttpServletRequest req, HttpServletResponse resp,
                                     Account admin, String action) throws IOException {
        int leaveId = parseInt(req.getParameter("id"), 0);
        String notes = req.getParameter("notes");
        boolean ok;

        if ("approve".equals(action)) {
            // 1. Tính số tiền khấu trừ từ ca nghỉ
            BigDecimal deductAmount = calcDeductAmount(leaveId);

            // 2. Approve đơn
            ok = leaveDAO.approve(leaveId, admin.getAccountId(), notes, deductAmount);

            if (ok) {
                LeaveRequest lr = leaveDAO.findById(leaveId);
                if (lr != null) {
                    // 3. Cập nhật ShiftSchedules.Status = ON_LEAVE
                    ShiftSchedule ss = scheduleDAO.findByAccountAndDate(
                            lr.getAccountId(), lr.getLeaveDate());
                    if (ss != null) {
                        scheduleDAO.updateStatus(ss.getScheduleId(), "ON_LEAVE");

                        // 4. Tự đóng Shift thực tế nếu đang mở
                        Shift openShift = shiftDAO.findCurrent(lr.getAccountId());
                        if (openShift != null) {
                            // Kiểm tra shift này thuộc ngày nghỉ
                            if (openShift.getStartTime().toLocalDate()
                                    .equals(lr.getLeaveDate())) {
                                shiftDAO.forceClose(openShift.getShiftId(),
                                        "[Auto-đóng do nghỉ phép được duyệt]");
                            }
                        }
                    }

                    // 5. Gửi email thông báo cho staff
                    Account staff = accountDAO.findById(lr.getAccountId());
                    if (staff != null && staff.getEmail() != null) {
                        sendStaffNotification(staff, lr, true, deductAmount, notes);
                    }

                    AuditHelper.log(req, "Duyệt đơn nghỉ", "LeaveRequest",
                            "Duyệt đơn ID " + leaveId + " — trừ "
                                    + deductAmount.toPlainString() + "đ");
                }
            }
        } else {
            ok = leaveDAO.reject(leaveId, admin.getAccountId(), notes);
            if (ok) {
                LeaveRequest lr = leaveDAO.findById(leaveId);
                // Restore ShiftSchedules về SCHEDULED nếu đang LEAVE_PENDING
                if (lr != null) {
                    ShiftSchedule ss = scheduleDAO.findByAccountAndDate(
                            lr.getAccountId(), lr.getLeaveDate());
                    if (ss != null && "LEAVE_PENDING".equals(ss.getStatus())) {
                        scheduleDAO.updateStatus(ss.getScheduleId(), "SCHEDULED");
                    }
                    // Gửi email từ chối
                    Account staff = accountDAO.findById(lr.getAccountId());
                    if (staff != null && staff.getEmail() != null) {
                        sendStaffNotification(staff, lr, false, BigDecimal.ZERO, notes);
                    }
                }
                AuditHelper.log(req, "Từ chối đơn nghỉ", "LeaveRequest",
                        "Từ chối đơn ID " + leaveId);
            }
        }
        resp.sendRedirect(req.getContextPath() + "/leave-requests?action=pending&msg="
                + (ok ? action + "d" : "error"));
    }

    // ── Staff: xem đơn của tôi ───────────────────────────────────────────────
    private void handleStaffView(HttpServletRequest req, HttpServletResponse resp, String action)
            throws ServletException, IOException {
        String uid = req.getParameter("uid");
        if (uid == null) { resp.sendRedirect(req.getContextPath() + "/staff-login"); return; }
        HttpSession session = req.getSession(false);
        Account staff = session != null
                ? (Account) session.getAttribute("staffAccount_" + uid) : null;
        if (staff == null) { resp.sendRedirect(req.getContextPath() + "/staff-login"); return; }

        req.setAttribute("staffUid", uid);

        if ("new".equals(action)) {
            // Form xin nghỉ — truyền thêm lịch ca để staff chọn nghỉ ca nào
            int month = LocalDate.now().getMonthValue();
            int year  = LocalDate.now().getYear();
            List<ShiftSchedule> mySchedules = scheduleDAO.findByAccountAndMonth(
                    staff.getAccountId(), month, year);
            // Lọc chỉ ca SCHEDULED/LEAVE_PENDING trong tương lai
            mySchedules = mySchedules.stream()
                    .filter(s -> !s.getWorkDate().isBefore(LocalDate.now()))
                    .filter(s -> "SCHEDULED".equals(s.getStatus())
                            || "LEAVE_PENDING".equals(s.getStatus()))
                    .collect(java.util.stream.Collectors.toList());

            req.setAttribute("mySchedules", mySchedules);
            req.setAttribute("today", LocalDate.now().toString());
            NotificationUtil.loadStaffNotifications(req, staff.getAccountId());
            req.getRequestDispatcher("/WEB-INF/views/staff/leave-request-form.jsp")
                    .forward(req, resp);
        } else {
            int month = LocalDate.now().getMonthValue();
            int year  = LocalDate.now().getYear();
            List<LeaveRequest> leaves = leaveDAO.findByAccountAndMonth(
                    staff.getAccountId(), month, year);
            req.setAttribute("leaves", leaves);
            req.setAttribute("month",  month);
            req.setAttribute("year",   year);
            NotificationUtil.loadStaffNotifications(req, staff.getAccountId());
            req.getRequestDispatcher("/WEB-INF/views/staff/leave-request-my.jsp")
                    .forward(req, resp);
        }
    }

    // ── Staff: gửi đơn ───────────────────────────────────────────────────────
    private void handleStaffSubmit(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String uid = req.getParameter("uid");
        if (uid == null) { resp.sendRedirect(req.getContextPath() + "/staff-login"); return; }
        HttpSession session = req.getSession(false);
        Account staff = session != null
                ? (Account) session.getAttribute("staffAccount_" + uid) : null;
        if (staff == null) { resp.sendRedirect(req.getContextPath() + "/staff-login"); return; }

        String dateStr    = req.getParameter("leaveDate");
        String leaveType  = req.getParameter("leaveType");
        String reason     = req.getParameter("reason");
        String schedIdStr = req.getParameter("scheduleId"); // có thể null

        if (dateStr == null || leaveType == null || reason == null || reason.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath()
                    + "/leave-requests?action=new&uid=" + uid + "&msg=invalid"); return;
        }

        LocalDate date = LocalDate.parse(dateStr);
        if (leaveDAO.existsByAccountAndDate(staff.getAccountId(), date)) {
            resp.sendRedirect(req.getContextPath()
                    + "/leave-requests?action=new&uid=" + uid + "&msg=exists"); return;
        }

        LeaveRequest lr = new LeaveRequest();
        lr.setAccountId(staff.getAccountId());
        lr.setLeaveDate(date);
        lr.setLeaveType(leaveType);
        lr.setReason(reason.trim());

        boolean ok = leaveDAO.insert(lr);
        if (ok) {
            // Cập nhật ShiftSchedules.Status → LEAVE_PENDING nếu có lịch ca ngày đó
            if (schedIdStr != null && !schedIdStr.isEmpty()) {
                scheduleDAO.updateStatus(Integer.parseInt(schedIdStr), "LEAVE_PENDING");
            } else {
                ShiftSchedule ss = scheduleDAO.findByAccountAndDate(staff.getAccountId(), date);
                if (ss != null && "SCHEDULED".equals(ss.getStatus())) {
                    scheduleDAO.updateStatus(ss.getScheduleId(), "LEAVE_PENDING");
                }
            }

            // Gửi email thông báo cho admin
            notifyAdmin(staff, lr, req);

            AuditHelper.log(req, "Xin nghỉ phép", "LeaveRequest",
                    "@" + staff.getUsername() + " xin nghỉ " + leaveType + " ngày " + date,
                    staff.getAccountId());
        }
        resp.sendRedirect(req.getContextPath() + "/leave-requests?action=my&uid=" + uid
                + "&msg=" + (ok ? "submitted" : "error"));
    }

    // ── Helper: tính tiền khấu trừ từ ca nghỉ ───────────────────────────────
    private BigDecimal calcDeductAmount(int leaveId) {
        try {
            LeaveRequest lr = leaveDAO.findById(leaveId);
            if (lr == null || "ANNUAL".equals(lr.getLeaveType())) return BigDecimal.ZERO;
            if ("SICK".equals(lr.getLeaveType())) return BigDecimal.ZERO; // nghỉ ốm không trừ

            ShiftSchedule ss = scheduleDAO.findByAccountAndDate(
                    lr.getAccountId(), lr.getLeaveDate());
            if (ss == null) return BigDecimal.ZERO;

            ShiftType st = typeDAO.findById(ss.getShiftTypeId());
            if (st == null) return BigDecimal.ZERO;

            // Tính số giờ ca × HourlyRate
            double hours = st.getPlannedHours();
            BigDecimal deduct = st.getHourlyRate().multiply(BigDecimal.valueOf(hours));

            // Đột xuất trừ thêm 20%
            if ("SUDDEN".equals(lr.getLeaveType())) {
                deduct = deduct.multiply(BigDecimal.valueOf(1.2));
            }
            return deduct;
        } catch (Exception e) {
            e.printStackTrace();
            return BigDecimal.ZERO;
        }
    }

    // ── Helper: gửi email admin khi có đơn mới ───────────────────────────────
    private void notifyAdmin(Account staff, LeaveRequest lr, HttpServletRequest req) {
        try {
            String adminEmail = accountDAO.findAll().stream()
                    .filter(a -> a.getRoleId() == 1 && a.getEmail() != null)
                    .map(Account::getEmail).findFirst().orElse(null);
            if (adminEmail == null) return;

            String subject = "[MediVault] 🏖️ Đơn xin nghỉ mới — " + staff.getFullName();
            String body =
                    "<h2>Đơn xin nghỉ phép mới</h2>"
                            + "<p><b>Nhân viên:</b> " + staff.getFullName() + " (@" + staff.getUsername() + ")</p>"
                            + "<p><b>Ngày nghỉ:</b> " + lr.getLeaveDate() + "</p>"
                            + "<p><b>Loại:</b> " + lr.getLeaveTypeLabel() + "</p>"
                            + "<p><b>Lý do:</b> " + lr.getReason() + "</p>"
                            + "<hr><p><a href='" + req.getRequestURL().toString().split("/leave")[0]
                            + "/leave-requests?action=pending'>👉 Vào hệ thống để duyệt</a></p>";
            EmailUtil.sendEmail(adminEmail, subject, body);
        } catch (Exception ignored) {}
    }

    // ── Helper: gửi email staff khi đơn được xử lý ──────────────────────────
    private void sendStaffNotification(Account staff, LeaveRequest lr,
                                       boolean approved, BigDecimal deduct, String adminNote) {
        try {
            if (staff.getEmail() == null) return;
            String subject = approved
                    ? "[MediVault] ✅ Đơn nghỉ ngày " + lr.getLeaveDate() + " đã được duyệt"
                    : "[MediVault] ❌ Đơn nghỉ ngày " + lr.getLeaveDate() + " bị từ chối";
            String body = "<h2>" + (approved ? "✅ Đơn nghỉ đã được duyệt" : "❌ Đơn nghỉ bị từ chối") + "</h2>"
                    + "<p><b>Ngày nghỉ:</b> " + lr.getLeaveDate() + "</p>"
                    + "<p><b>Loại:</b> " + lr.getLeaveTypeLabel() + "</p>"
                    + (approved && deduct.compareTo(BigDecimal.ZERO) > 0
                    ? "<p><b>Khấu trừ lương:</b> " + String.format("%,.0f", deduct) + "đ</p>" : "")
                    + (adminNote != null && !adminNote.trim().isEmpty()
                    ? "<p><b>Ghi chú Admin:</b> " + adminNote + "</p>" : "")
                    + (approved ? "<p>Ca làm việc ngày này đã được cập nhật trạng thái <b>Nghỉ phép</b>.</p>" : "");
            EmailUtil.sendEmail(staff.getEmail(), subject, body);
        } catch (Exception ignored) {}
    }

    private int parseInt(String s, int def) {
        try { return s != null ? Integer.parseInt(s) : def; }
        catch (NumberFormatException e) { return def; }
    }
}