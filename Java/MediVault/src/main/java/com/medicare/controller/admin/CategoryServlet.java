package com.medicare.controller.admin;

import com.medicare.entity.Category;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.List;

/**
 * MODULE MẪU — CategoryServlet
 * Flow chuẩn: GET list → GET form → POST save → redirect
 * Các Servlet khác copy y chang, chỉ đổi DAO + Entity + JSP
 */
@WebServlet("/categories")
public class CategoryServlet extends HttpServlet {

    private final com.medicare.dao.interfaces.ICategoryDAO dao = new com.medicare.dao.CategoryDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if (action == null) action = "list";

        switch (action) {
            case "list" -> showList(req, resp);
            case "new"  -> showForm(req, resp, null);
            case "edit" -> {
                int id = Integer.parseInt(req.getParameter("id"));
                showForm(req, resp, dao.findById(id));
            }
            case "delete" -> {
                int id = Integer.parseInt(req.getParameter("id"));
                dao.delete(id);
                resp.sendRedirect(req.getContextPath() + "/categories?msg=deleted");
            }
            default -> showList(req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        String idStr = req.getParameter("categoryId");
        String name  = req.getParameter("categoryName");
        String desc  = req.getParameter("description");

        // Validate đơn giản
        if (name == null || name.trim().isEmpty()) {
            req.setAttribute("error", "Tên danh mục không được trống!");
            showForm(req, resp, null);
            return;
        }

        Category c = new Category();
        c.setCategoryName(name.trim());
        c.setDescription(desc != null ? desc.trim() : "");

        if (idStr != null && !idStr.isEmpty()) {
            // Update
            c.setCategoryId(Integer.parseInt(idStr));
            dao.update(c);
            resp.sendRedirect(req.getContextPath() + "/categories?msg=updated");
        } else {
            // Insert
            dao.insert(c);
            resp.sendRedirect(req.getContextPath() + "/categories?msg=created");
        }
    }

    // ── helpers ──────────────────────────────────────────────

    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        List<Category> list = dao.findAll();
        req.setAttribute("categories", list);
        req.getRequestDispatcher("/WEB-INF/views/admin/category-list.jsp").forward(req, resp);
    }

    private void showForm(HttpServletRequest req, HttpServletResponse resp, Category category)
            throws ServletException, IOException {
        req.setAttribute("category", category); // null = new, có giá trị = edit
        req.getRequestDispatcher("/WEB-INF/views/admin/category-form.jsp").forward(req, resp);
    }
}