package com.medivault.controller.admin;

import com.medivault.dao.AccountDAO;
import com.medivault.dao.InvoiceDAO;
import com.medivault.dao.LeaveRequestDAO;
import com.medivault.dao.ShiftDAO;
import com.medivault.dao.ShiftScheduleDAO;
import com.medivault.dao.ShiftTypeDAO;
import com.medivault.dao.interfaces.IAccountDAO;
import com.medivault.dao.interfaces.IInvoiceDAO;
import com.medivault.dao.interfaces.ILeaveRequestDAO;
import com.medivault.dao.interfaces.IShiftDAO;
import com.medivault.dao.interfaces.IShiftScheduleDAO;
import com.medivault.dao.interfaces.IShiftTypeDAO;
import com.medivault.entity.ShiftSchedule;
import com.medivault.entity.Account;
import com.medivault.entity.Shift;
import com.medivault.util.AuditHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.*;

@WebServlet("/shifts")
public class ShiftServlet extends HttpServlet {

    private final IShiftDAO         shiftDAO    = new ShiftDAO();
    private final IAccountDAO       accountDAO  = new AccountDAO();
    private final IInvoiceDAO       invoiceDAO  = new InvoiceDAO();
    private final IShiftScheduleDAO scheduleDAO = new ShiftScheduleDAO();
    private final IShiftTypeDAO     shiftTypeDAO = new ShiftTypeDAO();
    private final ILeaveRequestDAO  leaveDAO    = new LeaveRequestDAO();

    // ── GET ───────────────────────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        Account adminAcc = session != null ? (Account) session.getAttribute("adminAccount") : null;
        if (adminAcc == null || adminAcc.getRoleId() != 1) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        String action = req.getParameter("action");
        if (action == null) action = "list";

        switch (action) {
            case "list"        -> showList(req, resp);
            case "detail"      -> showDetail(req, resp);
            case "force-close" -> handleForceClose(req, resp);
            case "delete"      -> handleDelete(req, resp);
            default            -> showList(req, resp);
        }
    }

    // ── POST ──────────────────────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        HttpSession session = req.getSession(false);
        Account adminAcc = session != null ? (Account) session.getAttribute("adminAccount") : null;
        if (adminAcc == null || adminAcc.getRoleId() != 1) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "open"        -> handleOpenShift(req, resp);
            case "close"       -> handleCloseShift(req, resp);
            case "force-close" -> handleForceClosePost(req, resp);
            default            -> resp.sendRedirect(req.getContextPath() + "/shifts");
        }
    }

    // ── LIST ──────────────────────────────────────────────────────────────────
    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Filter params
        String fromStr    = req.getParameter("from");
        String toStr      = req.getParameter("to");
        String accountStr = req.getParameter("accountId");
        String statusStr  = req.getParameter("status"); // "open" | "closed" | ""

        List<Shift> allShifts;

        // Lọc theo khoảng ngày
        if (fromStr != null && !fromStr.isEmpty() && toStr != null && !toStr.isEmpty()) {
            try {
                LocalDate from = LocalDate.parse(fromStr);
                LocalDate to   = LocalDate.parse(toStr);
                allShifts = shiftDAO.findByDateRange(from, to);
            } catch (DateTimeParseException e) {
                allShifts = shiftDAO.findAll();
            }
        } else if (accountStr != null && !accountStr.isEmpty()) {
            try {
                allShifts = shiftDAO.findByAccount(Integer.parseInt(accountStr));
            } catch (NumberFormatException e) {
                allShifts = shiftDAO.findAll();
            }
        } else {
            allShifts = shiftDAO.findAll();
        }

        // Lọc theo status — dùng Status field (OPEN/CLOSED/FORCE_CLOSED)
        if (statusStr != null && !statusStr.isEmpty()) {
            if ("open".equals(statusStr)) {
                allShifts = allShifts.stream()
                        .filter(s -> s.isOpen())
                        .collect(java.util.stream.Collectors.toList());
            } else if ("closed".equals(statusStr)) {
                allShifts = allShifts.stream()
                        .filter(s -> s.isClosed() || s.isForceClose())
                        .collect(java.util.stream.Collectors.toList());
            } else if ("force-closed".equals(statusStr)) {
                allShifts = allShifts.stream()
                        .filter(s -> s.isForceClose())
                        .collect(java.util.stream.Collectors.toList());
            }
        }

        // Map accountId → Account để hiển thị tên nhân viên
        Map<Integer, Account> accountMap = new HashMap<>();
        for (Shift s : allShifts) {
            if (!accountMap.containsKey(s.getAccountId())) {
                Account a = accountDAO.findById(s.getAccountId());
                if (a != null) accountMap.put(s.getAccountId(), a);
            }
        }

        // Thống kê tổng quan — dùng Status field
        List<Shift> openShifts = allShifts.stream()
                .filter(s -> s.isOpen())
                .collect(java.util.stream.Collectors.toList());
        long forceClosedCount = allShifts.stream().filter(s -> s.isForceClose()).count();
        req.setAttribute("forceClosedCount", forceClosedCount);

        req.setAttribute("shifts",       allShifts);
        req.setAttribute("accountMap",   accountMap);
        req.setAttribute("openShifts",   openShifts);
        req.setAttribute("openCount",    openShifts.size());
        req.setAttribute("totalCount",   allShifts.size());
        req.setAttribute("allStaff",     accountDAO.findAllStaff());
        req.setAttribute("filterFrom",   fromStr);
        req.setAttribute("filterTo",     toStr);
        req.setAttribute("filterAcc",    accountStr);
        req.setAttribute("filterStatus", statusStr);
        // Status summary cho filter dropdown
        req.setAttribute("openCount",        openShifts.size());
        req.setAttribute("forceClosedShifts", allShifts.stream()
                .filter(s -> s.isForceClose()).count());

        // ── Dữ liệu cho Tab Lịch ca (tuần) ──────────────────────────────────
        java.time.LocalDate today2 = java.time.LocalDate.now();
        java.time.LocalDate monday = today2.minusDays(today2.getDayOfWeek().getValue() - 1);
        // Navigate tuần
        String wStr = req.getParameter("w");
        if (wStr != null) {
            try { monday = monday.plusWeeks(Integer.parseInt(wStr)); } catch (Exception ignored) {}
        }
        java.time.LocalDate sunday = monday.plusDays(6);
        // 7 ngày trong tuần
        java.util.List<java.time.LocalDate> weekDays = new java.util.ArrayList<>();
        java.util.List<String> weekDayNames = java.util.Arrays.asList("T2","T3","T4","T5","T6","T7","CN");
        for (int i = 0; i < 7; i++) weekDays.add(monday.plusDays(i));
        // Lịch ca tuần này
        java.util.List<com.medivault.entity.ShiftSchedule> weekSchedules =
                scheduleDAO.findByDateRange(monday, sunday);
        req.setAttribute("weekDays",     weekDays);
        req.setAttribute("weekDayNames", weekDayNames);
        req.setAttribute("weekStart",    monday.toString());
        req.setAttribute("weekEnd",      sunday.toString());
        req.setAttribute("today",        today2);
        req.setAttribute("schedules",    weekSchedules);
        // ── Dữ liệu cho Tab Loại ca ──────────────────────────────────────────
        req.setAttribute("shiftTypes",   shiftTypeDAO.findAll());

        // ── Dữ liệu cho Tab Nghỉ phép ────────────────────────────────────────
        java.util.List<com.medivault.entity.LeaveRequest> pendingLeaves = leaveDAO.findPending();
        req.setAttribute("pendingLeaves",     pendingLeaves);
        req.setAttribute("pendingLeaveCount", pendingLeaves.size());

        // Navbar badges (giống các servlet khác)
        loadNavbarData(req);

        req.getRequestDispatcher("/WEB-INF/views/admin/shift-list.jsp").forward(req, resp);
    }

    // ── DETAIL ────────────────────────────────────────────────────────────────
    private void showDetail(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        int id = parseIntOr(req.getParameter("id"), 0);
        Shift shift = shiftDAO.findById(id);
        if (shift == null) {
            resp.sendRedirect(req.getContextPath() + "/shifts?msg=not-found");
            return;
        }
        Account staff = accountDAO.findById(shift.getAccountId());
        req.setAttribute("shift", shift);
        req.setAttribute("staff", staff);
        loadNavbarData(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/shift-detail.jsp").forward(req, resp);
    }

    // ── FORCE CLOSE (GET confirm page) ───────────────────────────────────────
    private void handleForceClose(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        int id = parseIntOr(req.getParameter("id"), 0);
        Shift shift = shiftDAO.findById(id);
        if (shift == null || !shift.isOpen()) {
            resp.sendRedirect(req.getContextPath() + "/shifts?msg=already-closed");
            return;
        }
        Account staff = accountDAO.findById(shift.getAccountId());
        req.setAttribute("shift", shift);
        req.setAttribute("staff", staff);
        loadNavbarData(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/shift-force-close.jsp").forward(req, resp);
    }

    // ── FORCE CLOSE (POST) ────────────────────────────────────────────────────
    private void handleForceClosePost(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int shiftId = parseIntOr(req.getParameter("shiftId"), 0);
        String notes = req.getParameter("notes");
        Shift shift = shiftDAO.findById(shiftId);
        if (shift == null) { resp.sendRedirect(req.getContextPath() + "/shifts"); return; }

        // ── Tự tính ClosingCash = OpeningCash + Doanh thu tiền mặt trong ca ──
        try {
            java.math.BigDecimal cashRevenue =
                    invoiceDAO.sumCashRevenueByShift(shiftId);
            java.math.BigDecimal opening =
                    shift.getOpeningCash() != null ? shift.getOpeningCash() : java.math.BigDecimal.ZERO;
            java.math.BigDecimal closing = opening.add(
                    cashRevenue != null ? cashRevenue : java.math.BigDecimal.ZERO);
            shiftDAO.setClosingCash(shiftId, closing);
        } catch (Exception ignored) {}

        boolean ok = shiftDAO.forceClose(shiftId, notes);
        if (ok) {
            Account staff = accountDAO.findById(shift.getAccountId());
            String staffName = staff != null ? staff.getFullName() : "ID " + shift.getAccountId();
            AuditHelper.log(req, "Force đóng ca", "Shift",
                    "Admin đóng ca ID " + shiftId + " của " + staffName);
        }
        resp.sendRedirect(req.getContextPath() + "/shifts?msg=" + (ok ? "force-closed" : "error"));
    }

    // ── DELETE ────────────────────────────────────────────────────────────────
    private void handleDelete(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int id = parseIntOr(req.getParameter("id"), 0);
        Shift shift = shiftDAO.findById(id);
        boolean ok = shiftDAO.delete(id);
        if (ok && shift != null) {
            Account staff = accountDAO.findById(shift.getAccountId());
            String staffName = staff != null ? staff.getFullName() : "ID " + shift.getAccountId();
            AuditHelper.log(req, "Xóa ca làm việc", "Shift",
                    "Xóa ca ID " + id + " của " + staffName);
        }
        String msg = ok ? "deleted" : "delete-failed"; // delete-failed = có hóa đơn liên kết
        resp.sendRedirect(req.getContextPath() + "/shifts?msg=" + msg);
    }

    // ── OPEN SHIFT (Admin mở ca hộ nhân viên) ────────────────────────────────
    private void handleOpenShift(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int accountId = parseIntOr(req.getParameter("accountId"), 0);
        String cashStr = req.getParameter("openingCash");
        BigDecimal cash = BigDecimal.ZERO;
        try { if (cashStr != null && !cashStr.isEmpty()) cash = new BigDecimal(cashStr); }
        catch (NumberFormatException ignored) {}

        boolean ok = shiftDAO.openShift(accountId, cash);
        if (ok) {
            Account staff = accountDAO.findById(accountId);
            String staffName = staff != null ? staff.getFullName() : "ID " + accountId;
            AuditHelper.log(req, "Mở ca làm việc", "Shift",
                    "Mở ca cho " + staffName + " — tiền đầu ca: " + cash);
        }
        resp.sendRedirect(req.getContextPath() + "/shifts?msg=" + (ok ? "opened" : "already-open"));
    }

    // ── CLOSE SHIFT (Admin đóng ca hộ) ───────────────────────────────────────
    private void handleCloseShift(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int shiftId = parseIntOr(req.getParameter("shiftId"), 0);
        String cashStr = req.getParameter("closingCash");
        String notes   = req.getParameter("notes");
        BigDecimal cash = BigDecimal.ZERO;
        try { if (cashStr != null && !cashStr.isEmpty()) cash = new BigDecimal(cashStr); }
        catch (NumberFormatException ignored) {}

        boolean ok = shiftDAO.closeShift(shiftId, cash, notes);
        if (ok) {
            Shift shift = shiftDAO.findById(shiftId);
            if (shift != null) {
                Account staff = accountDAO.findById(shift.getAccountId());
                AuditHelper.log(req, "Đóng ca làm việc", "Shift",
                        "Đóng ca ID " + shiftId + " của "
                                + (staff != null ? staff.getFullName() : "") + " — tiền cuối ca: " + cash);
            }
        }
        resp.sendRedirect(req.getContextPath() + "/shifts?msg=" + (ok ? "closed" : "error"));
    }

    // ── Helper: load navbar badges giống DashboardServlet ────────────────────
    private void loadNavbarData(HttpServletRequest req) {
        try {
            com.medivault.dao.interfaces.IPasswordResetDAO resetDAO = new com.medivault.dao.PasswordResetDAO();
            java.util.List<com.medivault.entity.PasswordResetRequest> pendingResets = resetDAO.findAllPending();
            req.setAttribute("pendingResets",     pendingResets);
            req.setAttribute("pendingResetCount", pendingResets.size());
            Map<Integer, Account> resetAccountMap = new HashMap<>();
            for (com.medivault.entity.PasswordResetRequest pr : pendingResets) {
                Account a = accountDAO.findById(pr.getAccountId());
                if (a != null) resetAccountMap.put(pr.getAccountId(), a);
            }
            req.setAttribute("resetAccountMap", resetAccountMap);
        } catch (Exception e) {
            req.setAttribute("pendingResetCount", 0);
        }
    }

    // ── Helper ────────────────────────────────────────────────────────────────
    private int parseIntOr(String s, int def) {
        if (s == null || s.isEmpty()) return def;
        try { return Integer.parseInt(s); } catch (NumberFormatException e) { return def; }
    }
}