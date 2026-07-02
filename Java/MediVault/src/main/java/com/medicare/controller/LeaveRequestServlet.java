package com.medicare.controller;

import com.medicare.dao.*;
import com.medicare.dao.interfaces.*;
import com.medicare.entity.*;
import com.medicare.util.*;
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
    private final IShiftScheduleDAO scheduleDAO    = new ShiftScheduleDAO();
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
        } else if ("substitutes".equals(action)) {
            handleSubstitutesApi(req, resp, adminAcc);
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

    /** AJAX (admin): danh sách người có thể làm thay cho 1 đơn nghỉ đột xuất. */
    private void handleSubstitutesApi(HttpServletRequest req, HttpServletResponse resp,
                                      Account adminAcc) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        if (adminAcc == null || adminAcc.getRoleId() != 1) {
            resp.getWriter().print("{\"ok\":false,\"reason\":\"unauthorized\"}"); return;
        }
        int leaveId = parseInt(req.getParameter("id"), 0);
        LeaveRequest lr = leaveDAO.findById(leaveId);
        if (lr == null) { resp.getWriter().print("{\"ok\":false,\"reason\":\"not_found\"}"); return; }

        List<Account> subs = scheduleDAO.findAvailableSubstitutes(lr.getLeaveDate(), lr.getAccountId());
        StringBuilder sb = new StringBuilder("{\"ok\":true,\"substitutes\":[");
        for (int i = 0; i < subs.size(); i++) {
            Account s = subs.get(i);
            String nm = s.getFullName() != null ? s.getFullName() : s.getUsername();
            String role = s.getRoleId() == 2 ? "Dược sĩ" : "Thủ kho";
            if (i > 0) sb.append(",");
            sb.append("{\"accountId\":").append(s.getAccountId())
              .append(",\"name\":\"").append(jsonEsc(nm)).append("\"")
              .append(",\"role\":\"").append(role).append("\"")
              .append(",\"phone\":\"").append(jsonEsc(s.getPhone() != null ? s.getPhone() : "")).append("\"}");
        }
        sb.append("]}");
        resp.getWriter().print(sb.toString());
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
        } else if ("submit-emergency".equals(action)) {
            handleEmergencySubmit(req, resp);
        } else if ("approve-sudden".equals(action)) {
            if (adminAcc == null || adminAcc.getRoleId() != 1) {
                resp.sendRedirect(req.getContextPath() + "/login"); return;
            }
            handleApproveSudden(req, resp, adminAcc);
        } else if ("approve".equals(action) || "reject".equals(action)) {
            if (adminAcc == null || adminAcc.getRoleId() != 1) {
                resp.sendRedirect(req.getContextPath() + "/login"); return;
            }
            handleAdminDecision(req, resp, adminAcc, action);
        } else {
            resp.sendRedirect(req.getContextPath() + "/leave-requests");
        }
    }

    // ── STAFF: gửi đơn NGHỈ ĐỘT XUẤT (ca trong 48h + ảnh minh chứng) ──────────
    private void handleEmergencySubmit(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String uid = req.getParameter("uid");
        if (uid == null) { resp.sendRedirect(req.getContextPath() + "/staff-login"); return; }
        HttpSession session = req.getSession(false);
        Account staff = session != null
                ? (Account) session.getAttribute("staffAccount_" + uid) : null;
        if (staff == null) { resp.sendRedirect(req.getContextPath() + "/staff-login"); return; }

        String schedIdStr = req.getParameter("scheduleId");
        String reason     = req.getParameter("reason");
        String evidence   = req.getParameter("evidenceData"); // base64 dataURL (tùy chọn)

        if (schedIdStr == null || schedIdStr.isEmpty() || reason == null || reason.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath()
                    + "/leave-requests?action=my&uid=" + uid + "&msg=invalid"); return;
        }

        int schedId = parseInt(schedIdStr, 0);
        ShiftSchedule ss = scheduleDAO.findById(schedId);
        // Validate: ca thuộc chính staff, chưa nghỉ/hủy, và nằm trong 48h tới
        if (ss == null || ss.getAccountId() != staff.getAccountId()) {
            resp.sendRedirect(req.getContextPath()
                    + "/leave-requests?action=my&uid=" + uid + "&msg=invalid"); return;
        }
        java.time.LocalDateTime now = java.time.LocalDateTime.now();
        if (ss.getPlannedStart() == null
                || ss.getPlannedStart().isAfter(now.plusHours(48))
                || ss.getPlannedEnd().isBefore(now)) {
            resp.sendRedirect(req.getContextPath()
                    + "/leave-requests?action=my&uid=" + uid + "&msg=not-emergency"); return;
        }
        if (!("SCHEDULED".equals(ss.getStatus()) || "LEAVE_PENDING".equals(ss.getStatus())
                || "CONFIRMED".equals(ss.getStatus()))) {
            resp.sendRedirect(req.getContextPath()
                    + "/leave-requests?action=my&uid=" + uid + "&msg=invalid"); return;
        }

        LocalDate date = ss.getWorkDate();
        if (leaveDAO.existsByAccountAndDate(staff.getAccountId(), date)) {
            resp.sendRedirect(req.getContextPath()
                    + "/leave-requests?action=my&uid=" + uid + "&msg=exists"); return;
        }

        // Lưu ảnh minh chứng (nếu có)
        String evidencePath = saveEvidence(req, evidence, staff.getAccountId());

        LeaveRequest lr = new LeaveRequest();
        lr.setAccountId(staff.getAccountId());
        lr.setLeaveDate(date);
        lr.setLeaveType("SUDDEN");
        lr.setReason(reason.trim());
        lr.setEvidencePath(evidencePath);

        boolean ok = leaveDAO.insert(lr);
        if (ok) {
            scheduleDAO.updateStatus(ss.getScheduleId(), "LEAVE_PENDING");
            notifyAdminEmergency(staff, lr, ss, req);   // ALERT ĐỎ
            AuditHelper.log(req, "Xin nghỉ đột xuất", "LeaveRequest",
                    "@" + staff.getUsername() + " XIN NGHỈ ĐỘT XUẤT ca ngày " + date
                            + " — lý do: " + reason.trim(),
                    staff.getAccountId());
        }
        resp.sendRedirect(req.getContextPath() + "/leave-requests?action=my&uid=" + uid
                + "&msg=" + (ok ? "emergency-submitted" : "error"));
    }

    // ── ADMIN: duyệt nghỉ đột xuất + điều phối người thay ─────────────────────
    private void handleApproveSudden(HttpServletRequest req, HttpServletResponse resp,
                                     Account admin) throws IOException {
        int leaveId = parseInt(req.getParameter("id"), 0);
        String notes = req.getParameter("notes");
        Integer subId = null;
        String subStr = req.getParameter("substituteId");
        if (subStr != null && !subStr.isEmpty() && !"0".equals(subStr)) {
            subId = parseInt(subStr, 0);
            if (subId == 0) subId = null;
        }

        LeaveRequest lr = leaveDAO.findById(leaveId);
        if (lr == null || !lr.isPending()) {
            resp.sendRedirect(req.getContextPath()
                    + "/leave-requests?action=pending&msg=error"); return;
        }

        BigDecimal deductAmount = calcDeductAmount(leaveId);
        boolean ok = leaveDAO.approveWithSubstitute(leaveId, admin.getAccountId(),
                notes, deductAmount, subId);
        if (!ok) {
            resp.sendRedirect(req.getContextPath()
                    + "/leave-requests?action=pending&msg=error"); return;
        }

        ShiftSchedule original = scheduleDAO.findByAccountAndDate(lr.getAccountId(), lr.getLeaveDate());
        if (original != null) {
            scheduleDAO.updateStatus(original.getScheduleId(), "ON_LEAVE");
            // Tự đóng ca đang mở nếu thuộc ngày nghỉ
            Shift openShift = shiftDAO.findCurrent(lr.getAccountId());
            if (openShift != null
                    && openShift.getStartTime().toLocalDate().equals(lr.getLeaveDate())) {
                shiftDAO.forceClose(openShift.getShiftId(),
                        "[Auto-đóng do nghỉ đột xuất được duyệt]");
            }
        }

        // Điều phối người thay
        Account substitute = null;
        if (subId != null && original != null) {
            int newSchedId = scheduleDAO.assignSubstitute(original, subId, admin.getAccountId());
            if (newSchedId > 0) {
                substitute = accountDAO.findById(subId);
                if (substitute != null && substitute.getEmail() != null) {
                    notifySubstitute(substitute, lr, original, req);
                }
            }
        }

        // Email cho người xin nghỉ
        Account staff = accountDAO.findById(lr.getAccountId());
        if (staff != null && staff.getEmail() != null) {
            lr.setLeaveType("SUDDEN");
            sendStaffNotification(staff, lr, true, deductAmount, notes);
        }

        AuditHelper.log(req, "Duyệt nghỉ đột xuất", "LeaveRequest",
                "Duyệt đơn đột xuất ID " + leaveId
                        + (substitute != null ? " — người thay: " + substitute.getFullName() : " — chưa có người thay")
                        + " — trừ " + deductAmount.toPlainString() + "đ");

        resp.sendRedirect(req.getContextPath()
                + "/leave-requests?action=pending&msg=approved");
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
        req.setAttribute("pending",      pending);
        req.setAttribute("pendingCount", pending.size());
        com.medicare.util.SidebarHelper.load(req);
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

                        // 4. Tự đóng Shift nếu đang mở VÀ thuộc ngày nghỉ
                        // (không tạo Attendance giả — SP_GeneratePayroll đọc LeaveRequests trực tiếp)
                        Shift openShift = shiftDAO.findCurrent(lr.getAccountId());
                        if (openShift != null
                                && openShift.getStartTime().toLocalDate().equals(lr.getLeaveDate())) {
                            shiftDAO.forceClose(openShift.getShiftId(),
                                    "[Auto-đóng do nghỉ phép được duyệt]");
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

        // ── Kiểm tra đang có đơn PENDING không → truyền cho JSP ──────────────
        boolean hasPendingLeave = leaveDAO.findByAccount(staff.getAccountId()).stream()
                .anyMatch(l -> "PENDING".equals(l.getStatus()));
        req.setAttribute("hasPendingLeave", hasPendingLeave);

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

            // Ca trong 48h tới — cho nút "Xin nghỉ đột xuất"
            java.time.LocalDateTime now = java.time.LocalDateTime.now();
            List<ShiftSchedule> emergencyShifts = scheduleDAO
                    .findUpcoming(staff.getAccountId(), 3).stream()
                    .filter(s -> s.getPlannedStart() != null
                            && !s.getPlannedStart().isAfter(now.plusHours(48))
                            && s.getPlannedEnd() != null && s.getPlannedEnd().isAfter(now))
                    .filter(s -> "SCHEDULED".equals(s.getStatus())
                            || "CONFIRMED".equals(s.getStatus()))
                    .collect(java.util.stream.Collectors.toList());
            req.setAttribute("emergencyShifts", emergencyShifts);

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

        // ── BLOCK: chỉ được 1 đơn PENDING tại một thời điểm ──────────────────
        boolean hasPending = leaveDAO.findByAccount(staff.getAccountId()).stream()
                .anyMatch(l -> "PENDING".equals(l.getStatus()));
        if (hasPending) {
            resp.sendRedirect(req.getContextPath()
                    + "/leave-requests?action=my&uid=" + uid + "&msg=has-pending"); return;
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

            String firstName = staff.getFullName() != null
                    ? staff.getFullName().trim().replaceAll(".*\\s", "") // lấy tên cuối (firstName)
                    : staff.getUsername();

            String subject = approved
                    ? "[MediVault] ✅ Đơn nghỉ ngày " + lr.getLeaveDate() + " đã được duyệt"
                    : "[MediVault] ❌ Đơn nghỉ ngày " + lr.getLeaveDate() + " bị từ chối";

            // ── Câu nhắn riêng theo loại nghỉ (khi được duyệt) ──────────────
            String personalMsg = "";
            if (approved) {
                switch (lr.getLeaveType() != null ? lr.getLeaveType() : "") {
                    case "SICK" ->
                            personalMsg = "<p style='margin:14px 0;padding:14px 18px;background:#FFF7ED;"
                                    + "border-left:4px solid #F59E0B;border-radius:8px;font-size:14px;color:#92400E'>"
                                    + "🤒 <b>" + firstName + "</b> ơi, nhớ nghỉ ngơi thật nhiều và uống thuốc đúng giờ nhé! "
                                    + "Sức khỏe là quan trọng nhất — chúc bạn mau bình phục và có một ngày tốt lành! 💪</p>";
                    case "ANNUAL" ->
                            personalMsg = "<p style='margin:14px 0;padding:14px 18px;background:#ECFDF5;"
                                    + "border-left:4px solid #059669;border-radius:8px;font-size:14px;color:#065F46'>"
                                    + "🌴 <b>" + firstName + "</b> ơi, chúc bạn có một ngày nghỉ phép thật vui vẻ và thư giãn! "
                                    + "Nạp đầy năng lượng rồi quay lại chiến tiếp nha! 😄✨</p>";
                    case "SUDDEN" ->
                            personalMsg = "<p style='margin:14px 0;padding:14px 18px;background:#EFF6FF;"
                                    + "border-left:4px solid #3B82F6;border-radius:8px;font-size:14px;color:#1E40AF'>"
                                    + "⚡ <b>" + firstName + "</b> ơi, đơn nghỉ đột xuất của bạn đã được duyệt. "
                                    + "Hy vọng mọi việc sẽ ổn thỏa, chúc bạn xử lý được mọi chuyện và sớm trở lại nhé! 🙏</p>";
                    case "UNPAID" ->
                            personalMsg = "<p style='margin:14px 0;padding:14px 18px;background:#F5F3FF;"
                                    + "border-left:4px solid #7C3AED;border-radius:8px;font-size:14px;color:#5B21B6'>"
                                    + "💼 <b>" + firstName + "</b> ơi, đơn nghỉ không lương đã được ghi nhận. "
                                    + "Dù không có lương hôm đó nhưng hi vọng thời gian nghỉ sẽ giúp bạn sắp xếp được mọi việc. "
                                    + "Quay lại làm việc thật khoẻ nhé! 💜</p>";
                    default ->
                            personalMsg = "<p style='margin:14px 0;font-size:14px;color:#374151'>"
                                    + "Chúc bạn có một ngày nghỉ thật tốt lành, " + firstName + "! 😊</p>";
                }
            }

            String body =
                    "<div style='font-family:\"Outfit\",sans-serif;max-width:520px;margin:0 auto;"
                            + "background:#fff;border-radius:14px;overflow:hidden;border:1px solid #E5E7EB'>"
                            + "<div style='padding:24px 28px;background:linear-gradient(135deg,#1558A8,#3ABDE0)'>"
                            + "<div style='font-size:22px;font-weight:800;color:#fff;letter-spacing:-.3px'>💊 MediVault</div>"
                            + "<div style='font-size:12px;color:rgba(255,255,255,.65);margin-top:3px;letter-spacing:1px;text-transform:uppercase'>"
                            + (approved ? "Thông báo duyệt đơn nghỉ" : "Thông báo từ chối đơn nghỉ")
                            + "</div></div>"
                            + "<div style='padding:24px 28px'>"
                            + "<h2 style='font-size:18px;font-weight:800;color:#0B1628;margin-bottom:4px'>"
                            + (approved ? "✅ Đơn nghỉ của bạn đã được duyệt!" : "❌ Đơn nghỉ của bạn bị từ chối")
                            + "</h2>"
                            + "<p style='font-size:13px;color:#7A90B0;margin-bottom:18px'>Ngày " + lr.getLeaveDate() + "</p>"
                            + "<table style='width:100%;border-collapse:collapse;margin-bottom:16px'>"
                            + "<tr><td style='padding:8px 12px;background:#F8FAFC;font-size:12px;font-weight:700;color:#7A90B0;width:120px;border-radius:6px 0 0 6px'>Loại nghỉ</td>"
                            + "<td style='padding:8px 12px;font-size:13px;font-weight:600;color:#0B1628'>" + lr.getLeaveTypeLabel() + "</td></tr>"
                            + "<tr><td style='padding:8px 12px;background:#F8FAFC;font-size:12px;font-weight:700;color:#7A90B0'>Ngày nghỉ</td>"
                            + "<td style='padding:8px 12px;font-size:13px;font-weight:600;color:#0B1628'>" + lr.getLeaveDate() + "</td></tr>"
                            + (approved && deduct != null && deduct.compareTo(BigDecimal.ZERO) > 0
                            ? "<tr><td style='padding:8px 12px;background:#FEF2F2;font-size:12px;font-weight:700;color:#991B1B'>Khấu trừ</td>"
                              + "<td style='padding:8px 12px;font-size:13px;font-weight:700;color:#DC2626'>"
                              + String.format("%,.0f", deduct) + "đ</td></tr>" : "")
                            + (adminNote != null && !adminNote.trim().isEmpty()
                            ? "<tr><td style='padding:8px 12px;background:#F8FAFC;font-size:12px;font-weight:700;color:#7A90B0'>Ghi chú</td>"
                              + "<td style='padding:8px 12px;font-size:13px;color:#374151'>" + adminNote + "</td></tr>" : "")
                            + "</table>"
                            + personalMsg
                            + "</div>"
                            + "<div style='padding:14px 28px;background:#F8FAFC;font-size:11px;color:#B0BEC5;text-align:center;border-top:1px solid #E5E7EB'>"
                            + "MediVault · Hệ thống quản lý nhà thuốc</div>"
                            + "</div>";

            EmailUtil.sendEmail(staff.getEmail(), subject, body);
        } catch (Exception ignored) {}
    }

    // ── Helper: lưu ảnh minh chứng base64 dataURL → đĩa, trả path tương đối ────
    private String saveEvidence(HttpServletRequest req, String dataUrl, int accountId) {
        if (dataUrl == null || !dataUrl.startsWith("data:image")) return null;
        try {
            int comma = dataUrl.indexOf(',');
            if (comma < 0) return null;
            String meta = dataUrl.substring(0, comma);
            String b64  = dataUrl.substring(comma + 1);
            String ext  = meta.contains("png") ? "png" : "jpg";
            byte[] bytes = java.util.Base64.getDecoder().decode(b64);
            if (bytes.length > 3_000_000) return null; // chặn ảnh quá lớn (>3MB)

            String dir = req.getServletContext().getRealPath("/uploads/leave");
            java.io.File folder = new java.io.File(dir);
            if (!folder.exists()) folder.mkdirs();
            String fileName = "leave_" + accountId + "_" + System.currentTimeMillis() + "." + ext;
            java.nio.file.Files.write(new java.io.File(folder, fileName).toPath(), bytes);
            return "uploads/leave/" + fileName;   // phục vụ qua contextPath
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    // ── Helper: ALERT ĐỎ gửi admin khi có đơn nghỉ đột xuất ───────────────────
    private void notifyAdminEmergency(Account staff, LeaveRequest lr, ShiftSchedule ss,
                                      HttpServletRequest req) {
        try {
            List<String> adminEmails = accountDAO.findActiveAdminEmails();
            if (adminEmails.isEmpty()) return;
            String base = req.getRequestURL().toString().split("/leave")[0];
            String shiftInfo = ss.getShiftTypeName() != null
                    ? ss.getShiftTypeName() + " (" + ss.getStartHour() + "h–" + ss.getEndHour() + "h)"
                    : "ca ngày " + lr.getLeaveDate();
            String subject = "🔴🚨 [MediVault] NGHỈ ĐỘT XUẤT — " + staff.getFullName()
                    + " — " + shiftInfo;
            String body =
                    "<div style='font-family:Segoe UI,Arial,sans-serif;max-width:560px;margin:auto'>"
                    + "<div style='background:linear-gradient(135deg,#dc2626,#991b1b);color:#fff;padding:20px 24px;border-radius:12px 12px 0 0'>"
                    + "<h2 style='margin:0;font-size:19px'>🚨 XIN NGHỈ ĐỘT XUẤT — CẦN XỬ LÝ GẤP</h2></div>"
                    + "<div style='border:1px solid #eee;border-top:none;padding:22px 24px;border-radius:0 0 12px 12px'>"
                    + "<p><b>" + esc(staff.getFullName()) + "</b> (@" + esc(staff.getUsername())
                    + ") vừa xin <b style='color:#dc2626'>nghỉ đột xuất</b>.</p>"
                    + "<table style='width:100%;border-collapse:collapse;margin:12px 0'>"
                    + "<tr><td style='padding:7px 10px;background:#fef2f2;font-weight:700;width:120px'>Ca nghỉ</td>"
                    + "<td style='padding:7px 10px'>" + esc(shiftInfo) + "</td></tr>"
                    + "<tr><td style='padding:7px 10px;background:#fef2f2;font-weight:700'>Ngày</td>"
                    + "<td style='padding:7px 10px'>" + lr.getLeaveDate() + "</td></tr>"
                    + "<tr><td style='padding:7px 10px;background:#fef2f2;font-weight:700'>Quầy POS</td>"
                    + "<td style='padding:7px 10px'>" + (ss.getPosStation() > 0 ? "Quầy " + ss.getPosStation() : "Chưa gán") + "</td></tr>"
                    + "<tr><td style='padding:7px 10px;background:#fef2f2;font-weight:700'>Lý do</td>"
                    + "<td style='padding:7px 10px'>" + esc(lr.getReason()) + "</td></tr>"
                    + "</table>"
                    + (lr.getEvidencePath() != null
                        ? "<p><a href='" + base + "/" + lr.getEvidencePath() + "'>📎 Xem ảnh minh chứng</a></p>" : "")
                    + "<p style='background:#fffbeb;border-left:4px solid #f59e0b;padding:10px 14px;border-radius:6px'>"
                    + "⚡ Hãy <b>duyệt & tìm người thay</b> hoặc <b>từ chối</b> sớm để không thiếu người trực quầy.</p>"
                    + "<p style='text-align:center;margin:22px 0'>"
                    + "<a href='" + base + "/leave-requests?action=pending' "
                    + "style='background:#dc2626;color:#fff;text-decoration:none;padding:12px 28px;border-radius:8px;font-weight:700'>Vào xử lý ngay</a></p>"
                    + "<p style='color:#888;font-size:12px;margin-top:16px'>MediVault Pharmacy System</p>"
                    + "</div></div>";
            for (String to : adminEmails) EmailUtil.sendEmail(to, subject, body);
        } catch (Exception ignored) {}
    }

    // ── Helper: báo người được phân công làm thay ─────────────────────────────
    private void notifySubstitute(Account sub, LeaveRequest lr, ShiftSchedule ss,
                                  HttpServletRequest req) {
        try {
            String shiftInfo = ss.getShiftTypeName() != null
                    ? ss.getShiftTypeName() + " (" + ss.getStartHour() + "h–" + ss.getEndHour() + "h)"
                    : "ca ngày " + lr.getLeaveDate();
            String name = sub.getFullName() != null ? sub.getFullName() : sub.getUsername();
            String subject = "📌 [MediVault] Bạn được phân công làm thay ca ngày " + lr.getLeaveDate();
            String body =
                    "<div style='font-family:Segoe UI,Arial,sans-serif;max-width:560px;margin:auto'>"
                    + "<div style='background:linear-gradient(135deg,#1558A8,#3ABDE0);color:#fff;padding:20px 24px;border-radius:12px 12px 0 0'>"
                    + "<h2 style='margin:0;font-size:18px'>📌 Phân công làm thay ca</h2></div>"
                    + "<div style='border:1px solid #eee;border-top:none;padding:22px 24px;border-radius:0 0 12px 12px'>"
                    + "<p>Chào <b>" + esc(name) + "</b>,</p>"
                    + "<p>Bạn được phân công <b>làm thay ca</b> cho một đồng nghiệp xin nghỉ đột xuất:</p>"
                    + "<table style='width:100%;border-collapse:collapse;margin:12px 0'>"
                    + "<tr><td style='padding:7px 10px;background:#eff6ff;font-weight:700;width:120px'>Ca</td>"
                    + "<td style='padding:7px 10px'>" + esc(shiftInfo) + "</td></tr>"
                    + "<tr><td style='padding:7px 10px;background:#eff6ff;font-weight:700'>Ngày</td>"
                    + "<td style='padding:7px 10px'>" + lr.getLeaveDate() + "</td></tr>"
                    + "<tr><td style='padding:7px 10px;background:#eff6ff;font-weight:700'>Quầy POS</td>"
                    + "<td style='padding:7px 10px'>" + (ss.getPosStation() > 0 ? "Quầy " + ss.getPosStation() : "Chưa gán") + "</td></tr>"
                    + "</table>"
                    + "<p>Lịch ca đã được thêm vào tài khoản của bạn. Vui lòng đăng nhập để xem chi tiết.</p>"
                    + "<p style='color:#888;font-size:12px;margin-top:16px'>MediVault Pharmacy System</p>"
                    + "</div></div>";
            EmailUtil.sendEmail(sub.getEmail(), subject, body);
        } catch (Exception ignored) {}
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
    }

    private String jsonEsc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private int parseInt(String s, int def) {
        try { return s != null ? Integer.parseInt(s) : def; }
        catch (NumberFormatException e) { return def; }
    }
}