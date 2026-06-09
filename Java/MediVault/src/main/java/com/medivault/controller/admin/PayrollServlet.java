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
import java.util.List;

/**
 * PayrollServlet — Admin quản lý bảng lương.
 * URL: /payroll
 *
 * GET  ?action=list&month=&year=   → danh sách bảng lương tháng
 * GET  ?action=detail&id=X         → chi tiết 1 nhân viên
 * GET  ?action=generate&month=&year= → tính lương tất cả nhân viên tháng đó
 * POST action=confirm&id=X         → xác nhận bảng lương
 * POST action=paid&id=X            → đánh dấu đã trả lương
 * POST action=updateBonus&id=X     → cập nhật thưởng/ghi chú
 */
@WebServlet("/payroll")
public class PayrollServlet extends HttpServlet {

    private final IPayrollDAO   payrollDAO  = new PayrollDAO();
    private final IAccountDAO   accountDAO  = new AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession session = req.getSession(false);
        Account admin = session != null ? (Account) session.getAttribute("adminAccount") : null;
        if (admin == null || admin.getRoleId() != 1) {
            resp.sendRedirect(req.getContextPath() + "/login"); return;
        }

        String action = req.getParameter("action");
        if (action == null) action = "list";

        switch (action) {
            case "list"     -> showList(req, resp);
            case "detail"   -> showDetail(req, resp);
            case "generate" -> handleGenerate(req, resp, admin);
            default         -> showList(req, resp);
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
            case "confirm"     -> handleConfirm(req, resp, admin);
            case "paid"        -> handleMarkPaid(req, resp, admin);
            case "updateBonus" -> handleUpdateBonus(req, resp);
            default            -> resp.sendRedirect(req.getContextPath() + "/payroll");
        }
    }

    // ── Danh sách bảng lương tháng ───────────────────────────────────────────
    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        int month = LocalDate.now().getMonthValue();
        int year  = LocalDate.now().getYear();
        try {
            if (req.getParameter("month") != null && !req.getParameter("month").isEmpty())
                month = Integer.parseInt(req.getParameter("month"));
            if (req.getParameter("year") != null && !req.getParameter("year").isEmpty())
                year  = Integer.parseInt(req.getParameter("year"));
        } catch (NumberFormatException ignored) {}

        List<Payroll> list = payrollDAO.findByMonth(month, year);

        // Thống kê tổng
        BigDecimal totalNet  = list.stream()
                .map(p -> p.getNetSalary() != null ? p.getNetSalary() : BigDecimal.ZERO)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        long paidCount       = list.stream().filter(Payroll::isPaid).count();
        long confirmedCount  = list.stream().filter(Payroll::isConfirmed).count();
        long draftCount      = list.stream().filter(Payroll::isDraft).count();

        req.setAttribute("payrolls",      list);
        req.setAttribute("month",         month);
        req.setAttribute("year",          year);
        req.setAttribute("totalNet",      totalNet);
        req.setAttribute("paidCount",     paidCount);
        req.setAttribute("confirmedCount",confirmedCount);
        req.setAttribute("draftCount",    draftCount);
        req.setAttribute("allStaff",      accountDAO.findAllStaff());
        req.getRequestDispatcher("/WEB-INF/views/admin/payroll-list.jsp")
                .forward(req, resp);
    }

    // ── Chi tiết bảng lương 1 nhân viên ─────────────────────────────────────
    private void showDetail(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String idStr = req.getParameter("id");
        if (idStr == null) { resp.sendRedirect(req.getContextPath() + "/payroll"); return; }

        Payroll payroll = payrollDAO.findById(Integer.parseInt(idStr));
        if (payroll == null) { resp.sendRedirect(req.getContextPath() + "/payroll?msg=not-found"); return; }

        req.setAttribute("payroll", payroll);
        req.getRequestDispatcher("/WEB-INF/views/admin/payroll-detail.jsp")
                .forward(req, resp);
    }

    // ── Tính lương tháng cho tất cả nhân viên (GET vì idempotent) ───────────
    private void handleGenerate(HttpServletRequest req, HttpServletResponse resp, Account admin)
            throws IOException {
        int month = LocalDate.now().getMonthValue();
        int year  = LocalDate.now().getYear();
        try {
            if (req.getParameter("month") != null && !req.getParameter("month").isEmpty())
                month = Integer.parseInt(req.getParameter("month"));
            if (req.getParameter("year") != null && !req.getParameter("year").isEmpty())
                year  = Integer.parseInt(req.getParameter("year"));
        } catch (NumberFormatException ignored) {}

        List<Account> allStaff = accountDAO.findAllStaff();
        int generated = 0;
        for (Account staff : allStaff) {
            int pid = payrollDAO.generate(staff.getAccountId(), month, year);
            if (pid > 0) generated++;
        }

        AuditHelper.log(req, "Tính lương", "Payroll",
                "Tạo " + generated + " bảng lương tháng " + month + "/" + year);
        resp.sendRedirect(req.getContextPath() + "/payroll?month=" + month
                + "&year=" + year + "&msg=generated&count=" + generated);
    }

    // ── Xác nhận bảng lương ─────────────────────────────────────────────────
    private void handleConfirm(HttpServletRequest req, HttpServletResponse resp, Account admin)
            throws IOException {
        int id = parseIntOr(req.getParameter("id"), 0);
        boolean ok = payrollDAO.confirm(id, admin.getAccountId());
        if (ok) {
            Payroll p = payrollDAO.findById(id);
            AuditHelper.log(req, "Xác nhận bảng lương", "Payroll",
                    "Xác nhận bảng lương ID " + id
                    + (p != null ? " — " + p.getMonthLabel() : ""));
        }
        resp.sendRedirect(req.getContextPath() + "/payroll?action=detail&id=" + id
                + "&msg=" + (ok ? "confirmed" : "error"));
    }

    // ── Đánh dấu đã trả lương ────────────────────────────────────────────────
    private void handleMarkPaid(HttpServletRequest req, HttpServletResponse resp, Account admin)
            throws IOException {
        int id = parseIntOr(req.getParameter("id"), 0);
        boolean ok = payrollDAO.markPaid(id);
        if (ok) AuditHelper.log(req, "Trả lương", "Payroll", "Đã trả lương ID " + id);
        resp.sendRedirect(req.getContextPath() + "/payroll?action=detail&id=" + id
                + "&msg=" + (ok ? "paid" : "error"));
    }

    // ── Cập nhật thưởng / ghi chú ────────────────────────────────────────────
    private void handleUpdateBonus(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int    id    = parseIntOr(req.getParameter("id"), 0);
        String bStr  = req.getParameter("bonus");
        String notes = req.getParameter("notes");
        BigDecimal bonus = BigDecimal.ZERO;
        try { if (bStr != null && !bStr.isEmpty()) bonus = new BigDecimal(bStr); }
        catch (NumberFormatException ignored) {}

        boolean ok = payrollDAO.updateBonus(id, bonus, notes);
        resp.sendRedirect(req.getContextPath() + "/payroll?action=detail&id=" + id
                + "&msg=" + (ok ? "updated" : "error"));
    }

    private int parseIntOr(String s, int def) {
        try { return s != null ? Integer.parseInt(s) : def; }
        catch (NumberFormatException e) { return def; }
    }
}
