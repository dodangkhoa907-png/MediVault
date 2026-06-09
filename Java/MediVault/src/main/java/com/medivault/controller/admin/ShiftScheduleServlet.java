package com.medivault.controller.admin;

import com.medivault.dao.*;
import com.medivault.dao.interfaces.*;
import com.medivault.entity.*;
import com.medivault.util.AuditHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.List;

/**
 * ShiftScheduleServlet — Admin xếp/xem/hủy lịch ca.
 * URL: /shift-schedules
 *
 * GET  ?action=list              → danh sách lịch ca (filter ngày/nhân viên)
 * GET  ?action=today             → lịch hôm nay
 * GET  ?action=week              → lịch tuần hiện tại
 * GET  ?action=new               → form xếp ca mới
 * GET  ?action=cancel&id=X       → hủy lịch ca
 * POST action=create             → lưu lịch ca mới (1 ca hoặc bulk nhiều ngày)
 */
@WebServlet("/shift-schedules")
public class ShiftScheduleServlet extends HttpServlet {

    private final IShiftScheduleDAO scheduleDAO = new ShiftScheduleDAO();
    private final IShiftTypeDAO     typeDAO     = new ShiftTypeDAO();
    private final IAccountDAO       accountDAO  = new AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        Account admin = session != null ? (Account) session.getAttribute("adminAccount") : null;
        if (admin == null || admin.getRoleId() != 1) {
            resp.sendRedirect(req.getContextPath() + "/login"); return;
        }

        String action = req.getParameter("action");
        if (action == null) action = "week";

        switch (action) {
            case "list"   -> showList(req, resp);
            case "today"  -> showByDate(req, resp, LocalDate.now());
            case "week"   -> showWeek(req, resp);
            case "new"    -> showForm(req, resp);
            case "cancel" -> handleCancel(req, resp, admin);
            default       -> showWeek(req, resp);
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
        if ("create".equals(action)) handleCreate(req, resp, admin);
        else resp.sendRedirect(req.getContextPath() + "/shift-schedules");
    }

    // ── Danh sách có filter ──────────────────────────────────────────────────
    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String fromStr = req.getParameter("from");
        String toStr   = req.getParameter("to");

        List<ShiftSchedule> schedules;
        if (fromStr != null && !fromStr.isEmpty() && toStr != null && !toStr.isEmpty()) {
            try {
                schedules = scheduleDAO.findByDateRange(
                        LocalDate.parse(fromStr), LocalDate.parse(toStr));
            } catch (DateTimeParseException e) {
                schedules = scheduleDAO.findByDateRange(
                        LocalDate.now(), LocalDate.now().plusDays(6));
            }
        } else {
            schedules = scheduleDAO.findByDateRange(
                    LocalDate.now(), LocalDate.now().plusDays(6));
        }

        req.setAttribute("schedules", schedules);
        req.setAttribute("filterFrom", fromStr != null ? fromStr : LocalDate.now().toString());
        req.setAttribute("filterTo",   toStr   != null ? toStr   : LocalDate.now().plusDays(6).toString());
        req.setAttribute("allStaff",   accountDAO.findAllStaff());
        loadNavData(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/shift-schedule-list.jsp")
                .forward(req, resp);
    }

    // ── Lịch theo ngày ──────────────────────────────────────────────────────
    private void showByDate(HttpServletRequest req, HttpServletResponse resp, LocalDate date)
            throws ServletException, IOException {
        req.setAttribute("schedules", scheduleDAO.findByDate(date));
        req.setAttribute("workDate",  date);
        req.setAttribute("allStaff",  accountDAO.findAllStaff());
        loadNavData(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/shift-schedule-list.jsp")
                .forward(req, resp);
    }

    // ── Lịch tuần ──────────────────────────────────────────────────────────
    private void showWeek(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        LocalDate today  = LocalDate.now();
        // Thứ 2 tuần này
        LocalDate monday = today.minusDays(today.getDayOfWeek().getValue() - 1);
        LocalDate sunday = monday.plusDays(6);

        List<ShiftSchedule> schedules = scheduleDAO.findByDateRange(monday, sunday);
        req.setAttribute("schedules",  schedules);
        req.setAttribute("weekStart",  monday);
        req.setAttribute("weekEnd",    sunday);
        req.setAttribute("today",      today);
        req.setAttribute("allStaff",   accountDAO.findAllStaff());
        req.setAttribute("shiftTypes", typeDAO.findAllActive());
        loadNavData(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/shift-schedule-week.jsp")
                .forward(req, resp);
    }

    // ── Form xếp ca ─────────────────────────────────────────────────────────
    private void showForm(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setAttribute("allStaff",   accountDAO.findAllStaff());
        req.setAttribute("shiftTypes", typeDAO.findAllActive());
        req.setAttribute("today",      LocalDate.now().toString());
        loadNavData(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/shift-schedule-form.jsp")
                .forward(req, resp);
    }

    // ── Tạo lịch ca ─────────────────────────────────────────────────────────
    private void handleCreate(HttpServletRequest req, HttpServletResponse resp, Account admin)
            throws IOException {
        String[] accountIds  = req.getParameterValues("accountId");
        String[] shiftTypes  = req.getParameterValues("shiftTypeId");
        String   dateFromStr = req.getParameter("dateFrom");
        String   dateToStr   = req.getParameter("dateTo");

        if (accountIds == null || shiftTypes == null || dateFromStr == null || dateFromStr.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/shift-schedules?action=new&msg=invalid");
            return;
        }

        int created = 0, skipped = 0;
        try {
            LocalDate from = LocalDate.parse(dateFromStr);
            LocalDate to   = (dateToStr != null && !dateToStr.isEmpty())
                    ? LocalDate.parse(dateToStr) : from;

            for (String accIdStr : accountIds) {
                int accId = Integer.parseInt(accIdStr);
                for (String stIdStr : shiftTypes) {
                    int stId = Integer.parseInt(stIdStr);
                    // Xếp từng ngày trong khoảng
                    for (LocalDate d = from; !d.isAfter(to); d = d.plusDays(1)) {
                        int result = scheduleDAO.schedule(accId, stId, d, admin.getAccountId());
                        if (result > 0) created++;
                        else skipped++; // -1 = đã tồn tại
                    }
                }
            }
            AuditHelper.log(req, "Xếp lịch ca", "ShiftSchedule",
                    "Tạo " + created + " lịch ca từ " + dateFromStr + " đến " + (dateToStr != null ? dateToStr : dateFromStr));
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/shift-schedules?msg=error");
            return;
        }

        resp.sendRedirect(req.getContextPath() + "/shift-schedules?msg=created&count=" + created + "&skip=" + skipped);
    }

    // ── Hủy lịch ca ─────────────────────────────────────────────────────────
    private void handleCancel(HttpServletRequest req, HttpServletResponse resp, Account admin)
            throws IOException {
        String idStr = req.getParameter("id");
        if (idStr == null) { resp.sendRedirect(req.getContextPath() + "/shift-schedules"); return; }
        boolean ok = scheduleDAO.cancel(Integer.parseInt(idStr));
        if (ok) AuditHelper.log(req, "Hủy lịch ca", "ShiftSchedule", "Hủy lịch ca ID " + idStr);
        resp.sendRedirect(req.getContextPath() + "/shift-schedules?msg=" + (ok ? "cancelled" : "error"));
    }

    private void loadNavData(HttpServletRequest req) {
        // Số đơn nghỉ đang chờ duyệt — dùng cho badge trên navbar
        try {
            ILeaveRequestDAO leaveDAO = new LeaveRequestDAO();
            req.setAttribute("pendingLeaveCount", leaveDAO.findPending().size());
        } catch (Exception ignored) {}
    }
}
