package com.medivault.controller;

import com.medivault.dao.*;
import com.medivault.dao.interfaces.*;
import com.medivault.entity.*;
import com.medivault.util.AuditHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * LeaveRequestServlet — Xin nghỉ (staff) + Duyệt đơn (admin).
 * URL: /leave-requests
 *
 * --- ADMIN ---
 * GET  ?action=list              → tất cả đơn (filter tháng)
 * GET  ?action=pending           → đơn chờ duyệt
 * POST action=approve&id=X       → duyệt đơn
 * POST action=reject&id=X        → từ chối đơn
 *
 * --- STAFF ---
 * GET  ?action=my&uid=X          → đơn của tôi
 * GET  ?action=new&uid=X         → form xin nghỉ
 * POST action=submit&uid=X       → gửi đơn xin nghỉ
 */
@WebServlet("/leave-requests")
public class LeaveRequestServlet extends HttpServlet {

    private final ILeaveRequestDAO  leaveDAO   = new LeaveRequestDAO();
    private final IShiftScheduleDAO scheduleDAO = new ShiftScheduleDAO();
    private final IAccountDAO       accountDAO  = new AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "pending";

        HttpSession session = req.getSession(false);
        Account adminAcc = session != null ? (Account) session.getAttribute("adminAccount") : null;

        // Phân luồng admin / staff
        if ("my".equals(action) || "new".equals(action)) {
            handleStaffView(req, resp, action);
        } else {
            // Admin only
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

    // ── Admin: danh sách tất cả ──────────────────────────────────────────────
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

        req.setAttribute("leaves",       leaveDAO.findByMonth(month, year));
        req.setAttribute("month",        month);
        req.setAttribute("year",         year);
        req.setAttribute("pendingCount", leaveDAO.findPending().size());
        req.getRequestDispatcher("/WEB-INF/views/admin/leave-request-list.jsp")
                .forward(req, resp);
    }

    // ── Admin: đơn chờ duyệt ─────────────────────────────────────────────────
    private void showPending(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        List<LeaveRequest> pending = leaveDAO.findPending();
        req.setAttribute("pending",      pending);
        req.setAttribute("pendingCount", pending.size());
        req.getRequestDispatcher("/WEB-INF/views/admin/leave-request-pending.jsp")
                .forward(req, resp);
    }

    // ── Admin: duyệt / từ chối ───────────────────────────────────────────────
    private void handleAdminDecision(HttpServletRequest req, HttpServletResponse resp,
                                     Account admin, String action) throws IOException {
        String idStr = req.getParameter("id");
        String notes = req.getParameter("notes");
        if (idStr == null) { resp.sendRedirect(req.getContextPath() + "/leave-requests"); return; }

        int leaveId = Integer.parseInt(idStr);
        boolean ok;

        if ("approve".equals(action)) {
            String deductStr = req.getParameter("deductAmount");
            BigDecimal deduct = BigDecimal.ZERO;
            try { if (deductStr != null && !deductStr.isEmpty()) deduct = new BigDecimal(deductStr); }
            catch (NumberFormatException ignored) {}

            ok = leaveDAO.approve(leaveId, admin.getAccountId(), notes, deduct);
            if (ok) {
                // Cập nhật trạng thái lịch ca ngày đó → ON_LEAVE
                LeaveRequest lr = leaveDAO.findById(leaveId);
                if (lr != null) {
                    ShiftSchedule ss = scheduleDAO.findByAccountAndDate(
                            lr.getAccountId(), lr.getLeaveDate());
                    if (ss != null) scheduleDAO.updateStatus(ss.getScheduleId(), "ON_LEAVE");
                }
                AuditHelper.log(req, "Duyệt đơn nghỉ", "LeaveRequest", "Duyệt đơn ID " + leaveId);
            }
        } else {
            ok = leaveDAO.reject(leaveId, admin.getAccountId(), notes);
            if (ok) AuditHelper.log(req, "Từ chối đơn nghỉ", "LeaveRequest", "Từ chối đơn ID " + leaveId);
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

        if ("new".equals(action)) {
            req.setAttribute("staffUid", uid);
            req.setAttribute("today",    LocalDate.now().toString());
            req.getRequestDispatcher("/WEB-INF/views/staff/leave-request-form.jsp")
                    .forward(req, resp);
        } else {
            int month = LocalDate.now().getMonthValue();
            int year  = LocalDate.now().getYear();
            req.setAttribute("leaves",   leaveDAO.findByAccountAndMonth(staff.getAccountId(), month, year));
            req.setAttribute("staffUid", uid);
            req.setAttribute("month",    month);
            req.setAttribute("year",     year);
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

        String dateStr   = req.getParameter("leaveDate");
        String leaveType = req.getParameter("leaveType");
        String reason    = req.getParameter("reason");

        if (dateStr == null || leaveType == null) {
            resp.sendRedirect(req.getContextPath() + "/leave-requests?action=new&uid=" + uid + "&msg=invalid");
            return;
        }

        LocalDate date = LocalDate.parse(dateStr);

        // Kiểm tra đã có đơn ngày đó chưa
        if (leaveDAO.existsByAccountAndDate(staff.getAccountId(), date)) {
            resp.sendRedirect(req.getContextPath() + "/leave-requests?action=new&uid=" + uid + "&msg=exists");
            return;
        }

        LeaveRequest lr = new LeaveRequest();
        lr.setAccountId(staff.getAccountId());
        lr.setLeaveDate(date);
        lr.setLeaveType(leaveType);
        lr.setReason(reason);

        boolean ok = leaveDAO.insert(lr);
        if (ok) {
            AuditHelper.log(req, "Xin nghỉ", "LeaveRequest",
                    "@" + staff.getUsername() + " xin nghỉ " + leaveType + " ngày " + date,
                    staff.getAccountId());
        }
        resp.sendRedirect(req.getContextPath() + "/leave-requests?action=my&uid=" + uid
                + "&msg=" + (ok ? "submitted" : "error"));
    }
}
