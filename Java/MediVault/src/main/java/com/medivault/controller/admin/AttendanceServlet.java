package com.medivault.controller.admin;

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
import java.time.format.DateTimeParseException;
import java.util.List;

/**
 * AttendanceServlet — Admin xem điểm danh.
 * URL: /attendance
 *
 * GET  ?action=live              → ai đang làm việc ngay lúc này
 * GET  ?action=list&from=&to=    → lịch sử điểm danh
 * GET  ?action=monthly&month=&year= → tổng hợp theo tháng
 * POST action=admin-checkout&accountId=X → admin force checkout nhân viên
 */
@WebServlet("/attendance")
public class AttendanceServlet extends HttpServlet {

    private final IAttendanceDAO    attendanceDAO = new AttendanceDAO();
    private final IAccountDAO       accountDAO    = new AccountDAO();
    private final IShiftScheduleDAO scheduleDAO   = new ShiftScheduleDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        Account admin = session != null ? (Account) session.getAttribute("adminAccount") : null;
        if (admin == null || admin.getRoleId() != 1) {
            resp.sendRedirect(req.getContextPath() + "/login"); return;
        }

        String action = req.getParameter("action");
        if (action == null) action = "live";

        switch (action) {
            case "live"    -> showLive(req, resp);
            case "list"    -> showList(req, resp);
            case "monthly" -> showMonthly(req, resp);
            default        -> showLive(req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        HttpSession session = req.getSession(false);
        Account admin = session != null ? (Account) session.getAttribute("adminAccount") : null;
        if (admin == null || admin.getRoleId() != 1) {
            resp.sendRedirect(req.getContextPath() + "/login"); return;
        }
        String action = req.getParameter("action");
        if ("admin-checkout".equals(action)) handleAdminCheckout(req, resp, admin);
        else resp.sendRedirect(req.getContextPath() + "/attendance");
    }

    // ── Đang làm việc realtime ────────────────────────────────────────────────
    private void showLive(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        List<Attendance> working = attendanceDAO.findCurrentlyWorking();
        req.setAttribute("working",    working);
        req.setAttribute("workCount",  working.size());
        req.setAttribute("todaySchedules", scheduleDAO.findByDate(LocalDate.now()));
        req.getRequestDispatcher("/WEB-INF/views/admin/attendance-live.jsp")
                .forward(req, resp);
    }

    // ── Lịch sử điểm danh ────────────────────────────────────────────────────
    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String fromStr   = req.getParameter("from");
        String toStr     = req.getParameter("to");
        String accIdStr  = req.getParameter("accountId");

        LocalDate from = LocalDate.now().minusDays(6);
        LocalDate to   = LocalDate.now();
        try {
            if (fromStr != null && !fromStr.isEmpty()) from = LocalDate.parse(fromStr);
            if (toStr   != null && !toStr.isEmpty())   to   = LocalDate.parse(toStr);
        } catch (DateTimeParseException ignored) {}

        List<Attendance> list;
        if (accIdStr != null && !accIdStr.isEmpty()) {
            list = attendanceDAO.findByAccountAndDateRange(
                    Integer.parseInt(accIdStr), from, to);
        } else {
            // Lấy tất cả: loop qua mỗi nhân viên (đơn giản hóa)
            list = new java.util.ArrayList<>();
            for (Account staff : accountDAO.findAllStaff()) {
                list.addAll(attendanceDAO.findByAccountAndDateRange(
                        staff.getAccountId(), from, to));
            }
            list.sort((a, b) -> b.getCheckInTime().compareTo(a.getCheckInTime()));
        }

        req.setAttribute("attendanceList", list);
        req.setAttribute("filterFrom",     from.toString());
        req.setAttribute("filterTo",       to.toString());
        req.setAttribute("filterAcc",      accIdStr);
        req.setAttribute("allStaff",       accountDAO.findAllStaff());
        req.getRequestDispatcher("/WEB-INF/views/admin/attendance-list.jsp")
                .forward(req, resp);
    }

    // ── Tổng hợp theo tháng ──────────────────────────────────────────────────
    private void showMonthly(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        int month = LocalDate.now().getMonthValue();
        int year  = LocalDate.now().getYear();
        try {
            if (req.getParameter("month") != null)
                month = Integer.parseInt(req.getParameter("month"));
            if (req.getParameter("year") != null)
                year  = Integer.parseInt(req.getParameter("year"));
        } catch (NumberFormatException ignored) {}

        // Tổng hợp điểm danh từng nhân viên trong tháng
        List<Account> allStaff = accountDAO.findAllStaff();
        List<java.util.Map<String, Object>> summary = new java.util.ArrayList<>();
        for (Account staff : allStaff) {
            List<Attendance> records =
                    attendanceDAO.findByAccountAndMonth(staff.getAccountId(), month, year);
            double totalHours = records.stream()
                    .filter(a -> a.getActualHours() != null)
                    .mapToDouble(Attendance::getActualHours).sum();
            long workedDays = records.stream().filter(Attendance::isCheckedOut).count();
            int totalLate   = records.stream().mapToInt(Attendance::getLateMinutes).sum();

            java.util.Map<String, Object> row = new java.util.LinkedHashMap<>();
            row.put("staff",       staff);
            row.put("workedDays",  workedDays);
            row.put("totalHours",  String.format("%.1f", totalHours));
            row.put("totalLate",   totalLate);
            row.put("records",     records);
            summary.add(row);
        }

        req.setAttribute("summary",    summary);
        req.setAttribute("month",      month);
        req.setAttribute("year",       year);
        req.getRequestDispatcher("/WEB-INF/views/admin/attendance-monthly.jsp")
                .forward(req, resp);
    }

    // ── Admin force checkout ──────────────────────────────────────────────────
    private void handleAdminCheckout(HttpServletRequest req, HttpServletResponse resp, Account admin)
            throws IOException {
        String accIdStr = req.getParameter("accountId");
        if (accIdStr == null) { resp.sendRedirect(req.getContextPath() + "/attendance"); return; }

        int accountId = Integer.parseInt(accIdStr);
        boolean ok = attendanceDAO.checkOut(accountId, BigDecimal.ZERO, "[Admin đóng ca]", true);
        if (ok) {
            Account staff = accountDAO.findById(accountId);
            AuditHelper.log(req, "Admin đóng ca", "Attendance",
                    "Force checkout: " + (staff != null ? "@" + staff.getUsername() : "ID " + accountId));
        }
        resp.sendRedirect(req.getContextPath() + "/attendance?action=live&msg=" + (ok ? "checked-out" : "error"));
    }
}
