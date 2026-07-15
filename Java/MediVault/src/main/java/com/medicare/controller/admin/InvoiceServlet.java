package com.medicare.controller.admin;

import com.medicare.dao.*;
import com.medicare.dao.interfaces.*;
import com.medicare.entity.*;
import com.medicare.util.SidebarHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.*;

/**
 * InvoiceServlet — Quản lý Hóa đơn bán hàng (đọc/xem, KHÔNG sửa/xóa).
 * URL: /invoices
 *
 * Đây là sổ ghi nhận tài chính — mọi hóa đơn (COMPLETED/CANCELLED/PENDING) đều
 * hiển thị đầy đủ, không ẩn để admin đối soát được toàn bộ. Servlet này CHỦ Ý
 * không có action hủy/sửa hóa đơn COMPLETED: hủy 1 hóa đơn đã hoàn tất nghĩa là
 * phải hoàn trả tồn kho (Batches.CurrentQuantity) — đó là phạm vi của tính năng
 * "Trả hàng" (Returns) chưa được xây, nên không làm nửa vời ở đây để tránh lệch
 * sổ sách (đã bán trừ kho nhưng "hủy" mà không cộng lại kho).
 */
@WebServlet("/invoices")
public class InvoiceServlet extends HttpServlet {

    private final IInvoiceDAO       invoiceDAO      = new InvoiceDAO();
    private final IInvoiceDetailDAO detailDAO       = new InvoiceDetailDAO();
    private final IAccountDAO       accountDAO      = new AccountDAO();
    private final ICustomerDAO      customerDAO     = new CustomerDAO();
    private final IPrescriptionDAO  prescriptionDAO = new PrescriptionDAO();
    private final IShiftDAO         shiftDAO        = new ShiftDAO();

    private static final int PAGE_SIZE = 20;

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
        if ("detail".equals(action)) {
            showDetail(req, resp);
        } else if ("detail-json".equals(action)) {
            detailJson(req, resp);
        } else {
            showList(req, resp);
        }
    }

    // ── DETAIL JSON (cho offcanvas — xem tại chỗ không chuyển trang) ─────────
    private void detailJson(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        java.io.PrintWriter out = resp.getWriter();
        int id = parseIntOr(req.getParameter("id"), 0);
        Invoice inv = invoiceDAO.findById(id);
        if (inv == null) { out.print("{\"ok\":false}"); return; }

        List<InvoiceDetail> details = detailDAO.findByInvoice(id);
        BigDecimal grossTotal = BigDecimal.ZERO;
        for (InvoiceDetail d : details)
            if (d.getSubTotal() != null) grossTotal = grossTotal.add(d.getSubTotal());

        Account  staff    = accountDAO.findById(inv.getAccountId());
        Customer customer = inv.getCustomerId() != null ? customerDAO.findById(inv.getCustomerId()) : null;

        StringBuilder items = new StringBuilder();
        for (int i = 0; i < details.size(); i++) {
            InvoiceDetail d = details.get(i);
            if (i > 0) items.append(",");
            items.append("{\"name\":\"").append(jsonEsc(d.getMedicineName()))
                 .append("\",\"batch\":\"").append(jsonEsc(d.getBatchNumber()))
                 .append("\",\"qty\":").append(d.getQuantity())
                 .append(",\"price\":").append(d.getUnitPrice() != null ? d.getUnitPrice().toPlainString() : "0")
                 .append(",\"subtotal\":").append(d.getSubTotal() != null ? d.getSubTotal().toPlainString() : "0")
                 .append("}");
        }

        out.print("{\"ok\":true"
                + ",\"id\":" + inv.getInvoiceId()
                + ",\"code\":\"" + jsonEsc(inv.getInvoiceCode()) + "\""
                + ",\"time\":\"" + (inv.getCreatedAt() != null
                        ? inv.getCreatedAt().toString().replace("T", " ").substring(0, 16) : "") + "\""
                + ",\"staff\":\"" + jsonEsc(staff != null ? staff.getFullName() : "ID " + inv.getAccountId()) + "\""
                + ",\"customer\":\"" + jsonEsc(customer != null ? customer.getCustomerName() : "") + "\""
                + ",\"customerPhone\":\"" + jsonEsc(customer != null && customer.getPhone() != null ? customer.getPhone() : "") + "\""
                + ",\"method\":\"" + jsonEsc(inv.getPaymentMethod()) + "\""
                + ",\"status\":\"" + jsonEsc(inv.getStatus()) + "\""
                + ",\"station\":" + (inv.getPosStation() != null ? inv.getPosStation() : 0)
                + ",\"gross\":" + grossTotal.toPlainString()
                + ",\"discount\":" + (inv.getDiscountAmount() != null ? inv.getDiscountAmount().toPlainString() : "0")
                + ",\"total\":" + (inv.getFinalAmount() != null ? inv.getFinalAmount().toPlainString() : "0")
                + ",\"items\":[" + items + "]}");
    }

    private String jsonEsc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    // ── LIST (lọc + phân trang) ─────────────────────────────────────────────
    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String fromStr  = trimToNull(req.getParameter("from"));
        String toStr    = trimToNull(req.getParameter("to"));
        String status   = trimToNull(req.getParameter("status"));
        String payment  = trimToNull(req.getParameter("payment"));
        String staffStr = trimToNull(req.getParameter("staff"));
        String keyword  = trimToNull(req.getParameter("q"));
        int page = parseIntOr(req.getParameter("page"), 1);
        if (page < 1) page = 1;

        LocalDate from = parseDateOrNull(fromStr);
        LocalDate to   = parseDateOrNull(toStr);
        // Nếu chỉ nhập 1 trong 2 mốc — bỏ qua lọc ngày để tránh lệch BETWEEN
        if (from == null || to == null) { from = null; to = null; }

        Integer accountId = null;
        if (staffStr != null) {
            try { accountId = Integer.parseInt(staffStr); } catch (NumberFormatException ignored) {}
        }

        List<Invoice> invoices = invoiceDAO.findFiltered(from, to, status, payment, accountId, keyword, page, PAGE_SIZE);
        int totalCount = invoiceDAO.countFiltered(from, to, status, payment, accountId, keyword);
        int totalPages = Math.max(1, (int) Math.ceil(totalCount / (double) PAGE_SIZE));
        if (page > totalPages) page = totalPages;

        // Map accountId/customerId → entity để JSP hiển thị tên (tránh N+1 query trùng)
        Map<Integer, Account>  accountMap  = new HashMap<>();
        Map<Integer, Customer> customerMap = new HashMap<>();
        for (Invoice inv : invoices) {
            accountMap.computeIfAbsent(inv.getAccountId(), accountDAO::findById);
            if (inv.getCustomerId() != null) {
                customerMap.computeIfAbsent(inv.getCustomerId(), customerDAO::findById);
            }
        }

        req.setAttribute("invoices",    invoices);
        req.setAttribute("accountMap",  accountMap);
        req.setAttribute("customerMap", customerMap);
        req.setAttribute("allStaff",    accountDAO.findAllStaff());
        req.setAttribute("totalCount",  totalCount);
        req.setAttribute("currentPage", page);
        req.setAttribute("totalPages",  totalPages);
        req.setAttribute("filterFrom",    fromStr);
        req.setAttribute("filterTo",      toStr);
        req.setAttribute("filterStatus",  status);
        req.setAttribute("filterPayment", payment);
        req.setAttribute("filterStaff",   staffStr);
        req.setAttribute("filterKeyword", keyword);
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/admin/invoice-list.jsp").forward(req, resp);
    }

    // ── DETAIL ────────────────────────────────────────────────────────────────
    private void showDetail(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        int id = parseIntOr(req.getParameter("id"), 0);
        Invoice inv = invoiceDAO.findById(id);
        if (inv == null) {
            resp.sendRedirect(req.getContextPath() + "/invoices?msg=not-found");
            return;
        }

        List<InvoiceDetail> details = detailDAO.findByInvoice(id);

        // Tổng tiền hàng TRƯỚC giảm giá — tính từ chi tiết để đối chiếu minh bạch
        // với DiscountAmount/FinalAmount (FinalAmount = SUM(SubTotal) - DiscountAmount,
        // đảm bảo bởi trigger TRG_UpdateInvoiceTotal trong DB).
        BigDecimal grossTotal = BigDecimal.ZERO;
        for (InvoiceDetail d : details) {
            if (d.getSubTotal() != null) grossTotal = grossTotal.add(d.getSubTotal());
        }

        Account  staff      = accountDAO.findById(inv.getAccountId());
        Customer customer   = inv.getCustomerId() != null ? customerDAO.findById(inv.getCustomerId()) : null;
        Prescription presc  = inv.getPrescriptionId() != null ? prescriptionDAO.findById(inv.getPrescriptionId()) : null;
        Shift shift          = inv.getShiftId() != null ? shiftDAO.findById(inv.getShiftId()) : null;

        req.setAttribute("inv",        inv);
        req.setAttribute("details",    details);
        req.setAttribute("grossTotal", grossTotal);
        req.setAttribute("staff",      staff);
        req.setAttribute("customer",   customer);
        req.setAttribute("presc",      presc);
        req.setAttribute("shift",      shift);
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/admin/invoice-detail.jsp").forward(req, resp);
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    private String trimToNull(String s) {
        if (s == null) return null;
        s = s.trim();
        return s.isEmpty() ? null : s;
    }

    private LocalDate parseDateOrNull(String s) {
        if (s == null) return null;
        try { return LocalDate.parse(s); } catch (DateTimeParseException e) { return null; }
    }

    private int parseIntOr(String s, int def) {
        if (s == null || s.isEmpty()) return def;
        try { return Integer.parseInt(s); } catch (NumberFormatException e) { return def; }
    }
}