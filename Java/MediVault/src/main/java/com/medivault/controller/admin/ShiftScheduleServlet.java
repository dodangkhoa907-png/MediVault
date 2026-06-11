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
 * ShiftScheduleServlet — CRUD đầy đủ lịch ca.
 * URL: /shift-schedules
 *
 * GET  ?action=week              → lịch tuần (default)
 * GET  ?action=list              → danh sách + filter
 * GET  ?action=new               → form tạo mới
 * GET  ?action=detail&id=X       → chi tiết 1 lịch ca
 * GET  ?action=edit&id=X         → form sửa
 * GET  ?action=cancel&id=X       → hủy (soft delete)
 * GET  ?action=delete&id=X       → xóa hẳn (nếu chưa có điểm danh)
 * POST action=create             → lưu mới (bulk)
 * POST action=update             → lưu chỉnh sửa
 */
@WebServlet("/shift-schedules")
public class ShiftScheduleServlet extends HttpServlet {

    private final IShiftScheduleDAO scheduleDAO = new ShiftScheduleDAO();
    private final IShiftTypeDAO     typeDAO     = new ShiftTypeDAO();
    private final IAccountDAO       accountDAO  = new AccountDAO();
    private final ILeaveRequestDAO  leaveDAO    = new LeaveRequestDAO();

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
            case "week"   -> showWeek(req, resp);
            case "list"   -> showList(req, resp);
            case "new"    -> showCreateForm(req, resp);
            case "detail" -> showDetail(req, resp);
            case "edit"   -> showEditForm(req, resp);
            case "cancel" -> handleCancel(req, resp, admin);
            case "delete" -> handleDelete(req, resp, admin);
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
        switch (action != null ? action : "") {
            case "create" -> handleCreate(req, resp, admin);
            case "update" -> handleUpdate(req, resp, admin);
            default       -> resp.sendRedirect(req.getContextPath() + "/shift-schedules");
        }
    }

    // ── WEEK VIEW ─────────────────────────────────────────────────────────────
    private void showWeek(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        LocalDate today  = LocalDate.now();
        LocalDate monday = today.minusDays(today.getDayOfWeek().getValue() - 1);
        LocalDate sunday = monday.plusDays(6);

        // Cho phép navigate tuần trước/sau
        String weekOffset = req.getParameter("w");
        if (weekOffset != null) {
            try {
                int offset = Integer.parseInt(weekOffset);
                monday = monday.plusWeeks(offset);
                sunday = monday.plusDays(6);
            } catch (NumberFormatException ignored) {}
        }

        req.setAttribute("schedules",  scheduleDAO.findByDateRange(monday, sunday));
        req.setAttribute("weekStart",  monday);
        req.setAttribute("weekEnd",    sunday);
        req.setAttribute("today",      today);
        req.setAttribute("allStaff",   accountDAO.findAllStaff());
        req.setAttribute("shiftTypes", typeDAO.findAllActive());
        loadNavBadges(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/shift-schedule-week.jsp").forward(req, resp);
    }

    // ── LIST WITH FILTER ──────────────────────────────────────────────────────
    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String fromStr    = req.getParameter("from");
        String toStr      = req.getParameter("to");
        String accIdStr   = req.getParameter("accountId");
        String statusStr  = req.getParameter("status");

        LocalDate from = LocalDate.now();
        LocalDate to   = LocalDate.now().plusDays(13);
        try {
            if (fromStr != null && !fromStr.isEmpty()) from = LocalDate.parse(fromStr);
            if (toStr   != null && !toStr.isEmpty())   to   = LocalDate.parse(toStr);
        } catch (DateTimeParseException ignored) {}

        List<ShiftSchedule> schedules;
        if (accIdStr != null && !accIdStr.isEmpty()) {
            schedules = scheduleDAO.findByAccount(Integer.parseInt(accIdStr));
            // Lọc ngày
            final LocalDate fFrom = from, fTo = to;
            schedules = schedules.stream()
                    .filter(s -> !s.getWorkDate().isBefore(fFrom) && !s.getWorkDate().isAfter(fTo))
                    .collect(java.util.stream.Collectors.toList());
        } else {
            schedules = scheduleDAO.findByDateRange(from, to);
        }

        // Lọc status
        if (statusStr != null && !statusStr.isEmpty()) {
            final String st = statusStr;
            schedules = schedules.stream()
                    .filter(s -> st.equals(s.getStatus()))
                    .collect(java.util.stream.Collectors.toList());
        }

        req.setAttribute("schedules",   schedules);
        req.setAttribute("filterFrom",  from.toString());
        req.setAttribute("filterTo",    to.toString());
        req.setAttribute("filterAcc",   accIdStr);
        req.setAttribute("filterStatus",statusStr);
        req.setAttribute("allStaff",    accountDAO.findAllStaff());
        loadNavBadges(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/shift-schedule-list.jsp").forward(req, resp);
    }

    // ── DETAIL ────────────────────────────────────────────────────────────────
    private void showDetail(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        int id = parseInt(req.getParameter("id"), 0);
        ShiftSchedule sc = scheduleDAO.findById(id);
        if (sc == null) {
            resp.sendRedirect(req.getContextPath() + "/shift-schedules?msg=not-found"); return;
        }
        req.setAttribute("schedule",   sc);
        req.setAttribute("shiftTypes", typeDAO.findAllActive());
        loadNavBadges(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/shift-schedule-detail.jsp").forward(req, resp);
    }

    // ── FORM TẠO MỚI ─────────────────────────────────────────────────────────
    private void showCreateForm(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setAttribute("allStaff",   accountDAO.findAllStaff());
        req.setAttribute("shiftTypes", typeDAO.findAllActive());
        req.setAttribute("today",      LocalDate.now().toString());
        // Pre-fill ngày từ tham số (nếu click từ tuần grid)
        String preDate = req.getParameter("date");
        if (preDate != null) req.setAttribute("preDate", preDate);
        loadNavBadges(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/shift-schedule-form.jsp").forward(req, resp);
    }

    // ── FORM SỬA ─────────────────────────────────────────────────────────────
    private void showEditForm(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        int id = parseInt(req.getParameter("id"), 0);
        ShiftSchedule sc = scheduleDAO.findById(id);
        if (sc == null || (!sc.isScheduled() && !sc.isLeavePending())) {
            resp.sendRedirect(req.getContextPath()
                    + "/shift-schedules?msg=cannot-edit&id=" + id); return;
        }
        req.setAttribute("schedule",   sc);
        req.setAttribute("shiftTypes", typeDAO.findAllActive());
        req.setAttribute("allStaff",   accountDAO.findAllStaff());
        loadNavBadges(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/shift-schedule-edit.jsp").forward(req, resp);
    }

    // ── POST CREATE (bulk) ────────────────────────────────────────────────────
    private void handleCreate(HttpServletRequest req, HttpServletResponse resp, Account admin)
            throws IOException {
        String[] accountIds  = req.getParameterValues("accountId");
        String[] shiftTypeIds = req.getParameterValues("shiftTypeId");
        String dateFromStr   = req.getParameter("dateFrom");
        String dateToStr     = req.getParameter("dateTo");

        if (accountIds == null || shiftTypeIds == null
                || dateFromStr == null || dateFromStr.isEmpty()) {
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
                for (String stIdStr : shiftTypeIds) {
                    int stId = Integer.parseInt(stIdStr);
                    for (LocalDate d = from; !d.isAfter(to); d = d.plusDays(1)) {
                        int r = scheduleDAO.schedule(accId, stId, d, admin.getAccountId());
                        if (r > 0) created++; else skipped++;
                    }
                }
            }
            AuditHelper.log(req, "Xếp lịch ca", "ShiftSchedule",
                    "Tạo " + created + " ca, bỏ qua " + skipped + " đã tồn tại");
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/shift-schedules?msg=error"); return;
        }
        resp.sendRedirect(req.getContextPath()
                + "/shift-schedules?msg=created&count=" + created + "&skip=" + skipped);
    }

    // ── POST UPDATE (sửa 1 ca) ────────────────────────────────────────────────
    private void handleUpdate(HttpServletRequest req, HttpServletResponse resp, Account admin)
            throws IOException {
        int scheduleId         = parseInt(req.getParameter("scheduleId"), 0);
        int shiftTypeId        = parseInt(req.getParameter("shiftTypeId"), 0);
        int lateTolerance      = parseInt(req.getParameter("lateToleranceMinutes"), 10);
        String notes           = req.getParameter("notes");

        if (scheduleId == 0 || shiftTypeId == 0) {
            resp.sendRedirect(req.getContextPath() + "/shift-schedules?msg=invalid"); return;
        }

        boolean ok = scheduleDAO.update(scheduleId, shiftTypeId, lateTolerance, notes,
                admin.getAccountId());
        if (ok) {
            AuditHelper.log(req, "Sửa lịch ca", "ShiftSchedule",
                    "Sửa lịch ca ID " + scheduleId
                            + " → ShiftType " + shiftTypeId + ", dung sai " + lateTolerance + "p");
        }
        resp.sendRedirect(req.getContextPath()
                + "/shift-schedules?action=detail&id=" + scheduleId
                + "&msg=" + (ok ? "updated" : "error"));
    }

    // ── CANCEL (soft delete) ──────────────────────────────────────────────────
    private void handleCancel(HttpServletRequest req, HttpServletResponse resp, Account admin)
            throws IOException {
        int id = parseInt(req.getParameter("id"), 0);
        ShiftSchedule sc = scheduleDAO.findById(id);
        boolean ok = scheduleDAO.cancel(id);
        if (ok && sc != null)
            AuditHelper.log(req, "Hủy lịch ca", "ShiftSchedule",
                    "Hủy ca " + sc.getShiftTypeName() + " ngày " + sc.getWorkDate()
                            + " của " + sc.getStaffName());
        resp.sendRedirect(req.getContextPath()
                + "/shift-schedules?msg=" + (ok ? "cancelled" : "error"));
    }

    // ── DELETE (hard delete) ──────────────────────────────────────────────────
    private void handleDelete(HttpServletRequest req, HttpServletResponse resp, Account admin)
            throws IOException {
        int id = parseInt(req.getParameter("id"), 0);
        ShiftSchedule sc = scheduleDAO.findById(id);
        boolean ok = scheduleDAO.delete(id);
        if (ok && sc != null) {
            AuditHelper.log(req, "Xóa lịch ca", "ShiftSchedule",
                    "Xóa ca " + sc.getShiftTypeName() + " ngày " + sc.getWorkDate()
                            + " của " + sc.getStaffName());
        }
        String msg = ok ? "deleted" : "delete-failed"; // delete-failed = đã có điểm danh
        resp.sendRedirect(req.getContextPath() + "/shift-schedules?msg=" + msg);
    }

    // ── Helper ────────────────────────────────────────────────────────────────
    private void loadNavBadges(HttpServletRequest req) {
        try {
            req.setAttribute("pendingLeaveCount", leaveDAO.findPending().size());
        } catch (Exception ignored) {}
    }

    private int parseInt(String s, int def) {
        try { return s != null ? Integer.parseInt(s) : def; }
        catch (NumberFormatException e) { return def; }
    }
}