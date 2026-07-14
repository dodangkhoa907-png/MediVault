package com.medicare.controller.admin;

import com.medicare.dao.SupplierDAO;
import com.medicare.entity.Account;
import com.medicare.entity.Supplier;
import com.medicare.util.AuditHelper;
import com.medicare.util.SidebarHelper;
import com.medicare.util.ValidationUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * SupplierServlet — CRUD Nhà cung cấp. URL: /suppliers
 * Không xóa cứng (NCC gắn với đơn nhập) — dùng bật/tắt hoạt động (toggleActive).
 */
@WebServlet("/suppliers")
public class SupplierServlet extends HttpServlet {

    private final SupplierDAO dao = new SupplierDAO();

    private boolean guard(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession s = req.getSession(false);
        Account a = s != null ? (Account) s.getAttribute("adminAccount") : null;
        if (a == null || a.getRoleId() != 1) { resp.sendRedirect(req.getContextPath() + "/login"); return false; }
        return true;
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!guard(req, resp)) return;
        String action = req.getParameter("action");
        if (action == null) action = "list";
        switch (action) {
            case "new"  -> showForm(req, resp, null);
            case "edit" -> showForm(req, resp, dao.findById(parseInt(req.getParameter("id"))));
            case "toggle" -> {
                int id = parseInt(req.getParameter("id"));
                if (id > 0) { dao.toggleActive(id); AuditHelper.log(req, "Đổi trạng thái NCC", "Supplier", id, "Toggle NCC ID " + id); }
                resp.sendRedirect(req.getContextPath() + "/suppliers?msg=updated");
            }
            default -> showList(req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!guard(req, resp)) return;
        req.setCharacterEncoding("UTF-8");

        String idStr = req.getParameter("supplierId");
        String name  = req.getParameter("supplierName");
        if (ValidationUtil.isBlank(name)) {
            req.setAttribute("error", "Tên nhà cung cấp không được để trống!");
            showForm(req, resp, buildFrom(req));
            return;
        }

        Supplier s = buildFrom(req);
        boolean isNew = ValidationUtil.isBlank(idStr);
        if (isNew) {
            s.setActive(true);
            boolean ok = dao.insert(s);
            if (ok) AuditHelper.log(req, "Tạo nhà cung cấp", "Supplier", "Thêm NCC: " + name.trim());
            resp.sendRedirect(req.getContextPath() + "/suppliers?msg=" + (ok ? "created" : "error"));
        } else {
            s.setSupplierId(Integer.parseInt(idStr));
            boolean ok = dao.update(s);
            if (ok) AuditHelper.log(req, "Sửa nhà cung cấp", "Supplier", "Sửa NCC: " + name.trim());
            resp.sendRedirect(req.getContextPath() + "/suppliers?msg=" + (ok ? "updated" : "error"));
        }
    }

    private Supplier buildFrom(HttpServletRequest req) {
        Supplier s = new Supplier();
        s.setSupplierName(trim(req.getParameter("supplierName")));
        s.setContactName(trim(req.getParameter("contactName")));
        s.setPhone(trim(req.getParameter("phone")));
        s.setEmail(trim(req.getParameter("email")));
        s.setAddress(trim(req.getParameter("address")));
        s.setLicenseNumber(trim(req.getParameter("licenseNumber")));
        s.setActive("on".equals(req.getParameter("isActive")));
        return s;
    }

    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setAttribute("suppliers", dao.findAll());
        SidebarHelper.load(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/supplier-list.jsp").forward(req, resp);
    }

    private void showForm(HttpServletRequest req, HttpServletResponse resp, Supplier s)
            throws ServletException, IOException {
        req.setAttribute("supplier", s);
        SidebarHelper.load(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/supplier-form.jsp").forward(req, resp);
    }

    private String trim(String s) { return s == null ? null : s.trim(); }
    private int parseInt(String s) { try { return Integer.parseInt(s); } catch (Exception e) { return 0; } }
}
