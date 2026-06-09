package com.medivault.controller.staff;

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

/**
 * StaffAttendanceServlet — Staff tự check-in / check-out.
 * URL: /staff-checkin
 *
 * GET  ?uid=X                    → trang check-in của staff (xem ca hôm nay + nút)
 * POST action=checkin&uid=X      → thực hiện check-in
 * POST action=checkout&uid=X     → thực hiện check-out
 */
@WebServlet("/staff-checkin")
public class StaffAttendanceServlet extends HttpServlet {

    private final IAttendanceDAO    attendanceDAO = new AttendanceDAO();
    private final IShiftScheduleDAO scheduleDAO   = new ShiftScheduleDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String uid = req.getParameter("uid");
        if (uid == null || uid.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/staff-login"); return;
        }
        HttpSession session = req.getSession(false);
        Account staff = session != null
                ? (Account) session.getAttribute("staffAccount_" + uid) : null;
        if (staff == null) { resp.sendRedirect(req.getContextPath() + "/staff-login"); return; }

        // Lịch ca hôm nay
        ShiftSchedule todaySchedule = scheduleDAO.findTodaySchedule(staff.getAccountId());
        // Check-in hiện tại (nếu có)
        Attendance activeAtt = attendanceDAO.findActiveByAccount(staff.getAccountId());
        // Lịch 7 ngày tới
        java.util.List<ShiftSchedule> upcoming = scheduleDAO.findUpcoming(staff.getAccountId(), 7);

        req.setAttribute("staffUid",      uid);
        req.setAttribute("todaySchedule", todaySchedule);
        req.setAttribute("activeAtt",     activeAtt);
        req.setAttribute("upcoming",      upcoming);
        req.setAttribute("today",         LocalDate.now());
        req.getRequestDispatcher("/WEB-INF/views/staff/staff-checkin.jsp")
                .forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String uid = req.getParameter("uid");
        if (uid == null || uid.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/staff-login"); return;
        }
        HttpSession session = req.getSession(false);
        Account staff = session != null
                ? (Account) session.getAttribute("staffAccount_" + uid) : null;
        if (staff == null) { resp.sendRedirect(req.getContextPath() + "/staff-login"); return; }

        String action = req.getParameter("action");
        if ("checkin".equals(action))  handleCheckIn(req, resp, staff, uid);
        else if ("checkout".equals(action)) handleCheckOut(req, resp, staff, uid);
        else resp.sendRedirect(req.getContextPath() + "/staff-checkin?uid=" + uid);
    }

    // ── Check-in ─────────────────────────────────────────────────────────────
    private void handleCheckIn(HttpServletRequest req, HttpServletResponse resp,
                               Account staff, String uid) throws IOException {
        // Kiểm tra đã check-in chưa
        if (attendanceDAO.findActiveByAccount(staff.getAccountId()) != null) {
            resp.sendRedirect(req.getContextPath() + "/staff-checkin?uid=" + uid + "&msg=already-in");
            return;
        }

        String cashStr = req.getParameter("openingCash");
        BigDecimal cash = BigDecimal.ZERO;
        try { if (cashStr != null && !cashStr.isEmpty()) cash = new BigDecimal(cashStr); }
        catch (NumberFormatException ignored) {}

        int attId = attendanceDAO.checkIn(staff.getAccountId(), "WEB_BUTTON", cash, null);
        if (attId > 0) {
            AuditHelper.log(req, "Check-in", "Attendance",
                    "@" + staff.getUsername() + " check-in lúc " + java.time.LocalTime.now().toString().substring(0,5),
                    staff.getAccountId());
            resp.sendRedirect(req.getContextPath() + "/staff-checkin?uid=" + uid + "&msg=checked-in");
        } else {
            resp.sendRedirect(req.getContextPath() + "/staff-checkin?uid=" + uid + "&msg=error");
        }
    }

    // ── Check-out ────────────────────────────────────────────────────────────
    private void handleCheckOut(HttpServletRequest req, HttpServletResponse resp,
                                Account staff, String uid) throws IOException {
        String cashStr = req.getParameter("closingCash");
        String notes   = req.getParameter("notes");
        BigDecimal cash = BigDecimal.ZERO;
        try { if (cashStr != null && !cashStr.isEmpty()) cash = new BigDecimal(cashStr); }
        catch (NumberFormatException ignored) {}

        boolean ok = attendanceDAO.checkOut(staff.getAccountId(), cash, notes, false);
        if (ok) {
            AuditHelper.log(req, "Check-out", "Attendance",
                    "@" + staff.getUsername() + " check-out",
                    staff.getAccountId());
        }
        resp.sendRedirect(req.getContextPath() + "/staff-checkin?uid=" + uid
                + "&msg=" + (ok ? "checked-out" : "error"));
    }
}
