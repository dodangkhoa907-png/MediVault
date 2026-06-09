package com.medivault.controller.admin;

import com.medivault.dao.AccountDAO;
import com.medivault.dao.ShiftDAO;
import com.medivault.dao.interfaces.IAccountDAO;
import com.medivault.dao.interfaces.IShiftDAO;
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

    private final IShiftDAO   shiftDAO   = new ShiftDAO();
    private final IAccountDAO accountDAO = new AccountDAO();

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

        // Lọc theo status
        if ("open".equals(statusStr)) {
            allShifts = allShifts.stream()
                    .filter(s -> s.getEndTime() == null)
                    .collect(java.util.stream.Collectors.toList());
        } else if ("closed".equals(statusStr)) {
            allShifts = allShifts.stream()
                    .filter(s -> s.getEndTime() != null)
                    .collect(java.util.stream.Collectors.toList());
        }

        // Map accountId → Account để hiển thị tên nhân viên
        Map<Integer, Account> accountMap = new HashMap<>();
        for (Shift s : allShifts) {
            if (!accountMap.containsKey(s.getAccountId())) {
                Account a = accountDAO.findById(s.getAccountId());
                if (a != null) accountMap.put(s.getAccountId(), a);
            }
        }

        // Thống kê tổng quan
        List<Shift> openShifts = allShifts.stream()
                .filter(s -> s.getEndTime() == null)
                .collect(java.util.stream.Collectors.toList());

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
        if (shift == null || shift.getEndTime() != null) {
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
