package com.medicare.controller.admin;

import com.medicare.dao.*;
import com.medicare.dao.interfaces.*;
import com.medicare.entity.*;
import com.medicare.util.AuditHelper;
import com.medicare.util.SidebarHelper;
import com.medicare.util.ValidationUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;

/**
 * CustomerServlet — Quản lý Khách hàng (CRM cơ bản).
 * URL: /customers
 *
 * Không có action xóa: khách hàng có thể đã gắn với Invoices/Prescriptions
 * (FK tham chiếu), xóa thẳng dễ vỡ dữ liệu lịch sử bán hàng. Nếu sau này cần
 * "vô hiệu hóa" khách hàng, nên thêm cột IsActive vào bảng Customers trước.
 */
@WebServlet("/customers")
public class CustomerServlet extends HttpServlet {

    private final ICustomerDAO customerDAO = new CustomerDAO();
    private final IInvoiceDAO  invoiceDAO  = new InvoiceDAO();

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
            case "list"   -> showList(req, resp);
            case "detail" -> showDetail(req, resp);
            case "new"    -> showForm(req, resp, null);
            case "edit"   -> showForm(req, resp, customerDAO.findById(parseIntOr(req.getParameter("id"), 0)));
            default       -> showList(req, resp);
        }
    }

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
        if ("save".equals(action)) {
            handleSave(req, resp);
        } else {
            resp.sendRedirect(req.getContextPath() + "/customers");
        }
    }

    // ── LIST ──────────────────────────────────────────────────────────────────
    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        List<Customer> customers = customerDAO.findAll();
        req.setAttribute("customers",  customers);
        req.setAttribute("totalCount", customers.size());
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/admin/customer-list.jsp").forward(req, resp);
    }

    // ── DETAIL (kèm lịch sử mua hàng) ────────────────────────────────────────
    private void showDetail(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        int id = parseIntOr(req.getParameter("id"), 0);
        Customer customer = customerDAO.findById(id);
        if (customer == null) {
            resp.sendRedirect(req.getContextPath() + "/customers?msg=not-found");
            return;
        }

        List<Invoice> invoices = invoiceDAO.findByCustomer(id);
        java.math.BigDecimal totalSpent = java.math.BigDecimal.ZERO;
        for (Invoice inv : invoices) {
            if (inv.getFinalAmount() != null) totalSpent = totalSpent.add(inv.getFinalAmount());
        }

        req.setAttribute("customer",   customer);
        req.setAttribute("invoices",   invoices);
        req.setAttribute("totalSpent", totalSpent);
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/admin/customer-detail.jsp").forward(req, resp);
    }

    // ── FORM (tạo / sửa) ──────────────────────────────────────────────────────
    private void showForm(HttpServletRequest req, HttpServletResponse resp, Customer c)
            throws ServletException, IOException {
        req.setAttribute("customer", c);
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/admin/customer-form.jsp").forward(req, resp);
    }

    // ── SAVE ──────────────────────────────────────────────────────────────────
    private void handleSave(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        List<String> errors = new ArrayList<>();
        String idStr = req.getParameter("customerId");
        boolean isNew = ValidationUtil.isBlank(idStr);

        String name    = req.getParameter("customerName");
        String phone   = req.getParameter("phone");
        String email   = req.getParameter("email");
        String address = req.getParameter("address");
        String dobStr  = req.getParameter("dateOfBirth");
        String gender  = req.getParameter("gender");
        String natId   = req.getParameter("nationalId");
        String occup   = req.getParameter("occupation");
        String allergy = req.getParameter("allergyHistory");
        String chronic = req.getParameter("chronicDisease");

        if (ValidationUtil.isBlank(name)) errors.add("Vui lòng nhập họ tên khách hàng!");

        LocalDate dob = null;
        if (!ValidationUtil.isBlank(dobStr)) {
            try {
                dob = LocalDate.parse(dobStr);
                if (!dob.isBefore(LocalDate.now())) errors.add("Ngày sinh không hợp lệ!");
            } catch (DateTimeParseException e) { errors.add("Ngày sinh không hợp lệ!"); }
        }

        // Số điện thoại trùng — Phone là UNIQUE trong DB, kiểm tra trước để báo lỗi rõ ràng
        if (!ValidationUtil.isBlank(phone)) {
            Customer existing = customerDAO.findByPhone(phone.trim());
            boolean phoneTaken = existing != null &&
                    (isNew || existing.getCustomerId() != Integer.parseInt(idStr));
            if (phoneTaken) errors.add("Số điện thoại này đã thuộc về khách hàng khác!");
        }

        if (!errors.isEmpty()) {
            req.setAttribute("errors", errors);
            Customer formBack = new Customer();
            if (!isNew) formBack.setCustomerId(Integer.parseInt(idStr));
            formBack.setCustomerName(name);
            formBack.setPhone(phone);
            formBack.setEmail(email);
            formBack.setAddress(address);
            formBack.setGender(gender);
            formBack.setNationalId(natId);
            formBack.setOccupation(occup);
            formBack.setAllergyHistory(allergy);
            formBack.setChronicDisease(chronic);
            req.setAttribute("customer", formBack);
            SidebarHelper.load(req);
            req.getRequestDispatcher("/WEB-INF/views/admin/customer-form.jsp").forward(req, resp);
            return;
        }

        Customer c = new Customer();
        c.setCustomerName(name.trim());
        c.setPhone(ValidationUtil.isBlank(phone) ? null : phone.trim());
        c.setEmail(ValidationUtil.isBlank(email) ? null : email.trim());
        c.setAddress(ValidationUtil.isBlank(address) ? null : address.trim());
        c.setDateOfBirth(dob);
        c.setGender(ValidationUtil.isBlank(gender) ? null : gender);
        c.setNationalId(ValidationUtil.isBlank(natId) ? null : natId.trim());
        c.setOccupation(ValidationUtil.isBlank(occup) ? null : occup.trim());
        c.setAllergyHistory(ValidationUtil.isBlank(allergy) ? null : allergy.trim());
        c.setChronicDisease(ValidationUtil.isBlank(chronic) ? null : chronic.trim());

        boolean ok;
        if (isNew) {
            ok = customerDAO.insert(c);
            if (ok) AuditHelper.log(req, "Tạo khách hàng", "Customer", "Tạo khách hàng mới: " + name);
        } else {
            c.setCustomerId(Integer.parseInt(idStr));
            ok = customerDAO.update(c);
            if (ok) AuditHelper.log(req, "Sửa khách hàng", "Customer", "Sửa thông tin khách hàng: " + name);
        }

        resp.sendRedirect(req.getContextPath() + "/customers?msg=" + (ok ? (isNew ? "created" : "updated") : "error"));
    }

    private int parseIntOr(String s, int def) {
        if (s == null || s.isEmpty()) return def;
        try { return Integer.parseInt(s); } catch (NumberFormatException e) { return def; }
    }
}