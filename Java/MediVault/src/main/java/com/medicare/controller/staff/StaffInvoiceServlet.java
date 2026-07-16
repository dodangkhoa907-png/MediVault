package com.medicare.controller.staff;

import com.medicare.dao.AccountDAO;
import com.medicare.dao.CustomerDAO;
import com.medicare.dao.InvoiceDAO;
import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.dao.interfaces.ICustomerDAO;
import com.medicare.dao.interfaces.IInvoiceDAO;
import com.medicare.entity.Account;
import com.medicare.entity.Customer;
import com.medicare.entity.Invoice;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * "Hóa đơn của tôi" — mỗi nhân viên bán hàng (POS) chỉ xem được hóa đơn CHÍNH MÌNH đã bán,
 * mặc định lọc theo ngày hôm nay (giống cách AuditLog ghi nhận hành động theo account/thời gian,
 * nhưng đây là góc nhìn tự-phục-vụ của nhân viên, không phải sổ toàn hệ thống như /invoices bên admin).
 * URL: /staff-my-invoices
 */
@WebServlet("/staff-my-invoices")
public class StaffInvoiceServlet extends HttpServlet {

    private final IInvoiceDAO  invoiceDAO  = new InvoiceDAO();
    private final IAccountDAO  accountDAO  = new AccountDAO();
    private final ICustomerDAO customerDAO = new CustomerDAO();

    private static final int PAGE_SIZE = 20;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String uid = req.getParameter("uid");
        HttpSession session = req.getSession(false);
        Account staffAcc = (uid != null && !uid.isEmpty() && session != null)
                ? (Account) session.getAttribute("staffAccount_" + uid) : null;
        if (staffAcc == null) {
            resp.sendRedirect(req.getContextPath() + "/staff-login");
            return;
        }
        // Dược sĩ (roleId=2) mới có quyền bán hàng POS — Thủ kho không có hóa đơn nào để xem.
        if (staffAcc.getRoleId() != 2) {
            resp.sendRedirect(req.getContextPath() + "/staff-dashboard?uid=" + uid);
            return;
        }

        String dateStr = req.getParameter("date");
        LocalDate date = parseDateOrToday(dateStr);
        int page = parseIntOr(req.getParameter("page"), 1);
        if (page < 1) page = 1;

        int accountId = staffAcc.getAccountId();
        List<Invoice> invoices = invoiceDAO.findFiltered(date, date, null, null, accountId, null, page, PAGE_SIZE);
        int totalCount = invoiceDAO.countFiltered(date, date, null, null, accountId, null);
        int totalPages = Math.max(1, (int) Math.ceil(totalCount / (double) PAGE_SIZE));
        if (page > totalPages) page = totalPages;

        Map<Integer, Customer> customerMap = new HashMap<>();
        for (Invoice inv : invoices) {
            if (inv.getCustomerId() != null) {
                customerMap.computeIfAbsent(inv.getCustomerId(), customerDAO::findById);
            }
        }

        req.setAttribute("staffAcc",    staffAcc);
        req.setAttribute("uid",         uid);
        req.setAttribute("invoices",    invoices);
        req.setAttribute("customerMap", customerMap);
        req.setAttribute("totalCount",  totalCount);
        req.setAttribute("currentPage", page);
        req.setAttribute("totalPages",  totalPages);
        req.setAttribute("filterDate",  date.toString());
        req.setAttribute("todayStr",    LocalDate.now().toString());

        req.getRequestDispatcher("/WEB-INF/views/staff/staff-invoices.jsp").forward(req, resp);
    }

    private LocalDate parseDateOrToday(String s) {
        if (s == null || s.isBlank()) return LocalDate.now();
        try { return LocalDate.parse(s); } catch (DateTimeParseException e) { return LocalDate.now(); }
    }

    private int parseIntOr(String s, int def) {
        if (s == null || s.isEmpty()) return def;
        try { return Integer.parseInt(s); } catch (NumberFormatException e) { return def; }
    }
}
