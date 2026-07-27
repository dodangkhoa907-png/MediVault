package com.medicare.controller.admin;

import com.medicare.dao.ShelfDAO;
import com.medicare.entity.Account;
import com.medicare.entity.Shelf;
import com.medicare.util.AuditHelper;
import com.medicare.util.SidebarHelper;
import com.medicare.util.ValidationUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * ShelfServlet — CRUD Vị trí kệ. URL: /shelves
 * Xóa được nếu không còn thuốc nào gán vào kệ (guard bằng countMedicinesOnShelf).
 */
@WebServlet("/shelves")
public class ShelfServlet extends HttpServlet {

    private final ShelfDAO dao = new ShelfDAO();

    private Account getAuthorizedUser(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) return null;
        Account admin = (Account) session.getAttribute("adminAccount");
        if (admin != null && (admin.getRoleId() == 1 || admin.getRoleId() == 3)) {
            return admin;
        }
        String uidStr = (String) session.getAttribute("staffUid");
        if (uidStr != null) {
            try {
                Account staff = (Account) session.getAttribute("staffAccount_" + uidStr);
                if (staff != null && (staff.getRoleId() == 1 || staff.getRoleId() == 3)) {
                    return staff;
                }
            } catch (Exception ignored) {}
        }
        return null;
    }

    private boolean guard(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Account user = getAuthorizedUser(req);
        if (user == null) { resp.sendRedirect(req.getContextPath() + "/login"); return false; }
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
            case "delete" -> {
                int id = parseInt(req.getParameter("id"));
                if (id > 0) {
                    int used = dao.countMedicinesOnShelf(id);
                    if (used > 0) { resp.sendRedirect(req.getContextPath() + "/shelves?msg=has-medicine"); return; }
                    boolean ok = dao.delete(id);
                    if (ok) AuditHelper.log(req, "Xóa vị trí kệ", "Shelf", id, "Xóa kệ ID " + id);
                    resp.sendRedirect(req.getContextPath() + "/shelves?msg=" + (ok ? "deleted" : "error"));
                    return;
                }
                resp.sendRedirect(req.getContextPath() + "/shelves");
            }
            default -> showList(req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!guard(req, resp)) return;
        req.setCharacterEncoding("UTF-8");

        String idStr = req.getParameter("shelfId");
        String name  = req.getParameter("shelfName");
        if (ValidationUtil.isBlank(name)) {
            req.setAttribute("error", "Tên kệ không được để trống!");
            showForm(req, resp, buildFrom(req));
            return;
        }

        Shelf s = buildFrom(req);
        boolean isNew = ValidationUtil.isBlank(idStr);
        if (isNew) {
            boolean ok = dao.insert(s);
            if (ok) AuditHelper.log(req, "Tạo vị trí kệ", "Shelf", "Thêm kệ: " + name.trim());
            resp.sendRedirect(req.getContextPath() + "/shelves?msg=" + (ok ? "created" : "error"));
        } else {
            s.setShelfId(Integer.parseInt(idStr));
            boolean ok = dao.update(s);
            if (ok) AuditHelper.log(req, "Sửa vị trí kệ", "Shelf", "Sửa kệ: " + name.trim());
            resp.sendRedirect(req.getContextPath() + "/shelves?msg=" + (ok ? "updated" : "error"));
        }
    }

    private Shelf buildFrom(HttpServletRequest req) {
        Shelf s = new Shelf();
        s.setShelfName(trim(req.getParameter("shelfName")));
        String type = req.getParameter("shelfType");
        s.setShelfType(ValidationUtil.isBlank(type) ? "RETAIL" : type);
        s.setLocationNotes(trim(req.getParameter("locationNotes")));
        s.setMachineSlotCode(trim(req.getParameter("machineSlotCode")));
        s.setMotorId(trim(req.getParameter("motorId")));
        s.setAutomated("on".equals(req.getParameter("isAutomated")));
        return s;
    }

    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setAttribute("shelves", dao.findAll());
        SidebarHelper.load(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/shelf-list.jsp").forward(req, resp);
    }

    private void showForm(HttpServletRequest req, HttpServletResponse resp, Shelf s)
            throws ServletException, IOException {
        req.setAttribute("shelf", s);
        SidebarHelper.load(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/shelf-form.jsp").forward(req, resp);
    }

    private String trim(String s) { return s == null ? null : s.trim(); }
    private int parseInt(String s) { try { return Integer.parseInt(s); } catch (Exception e) { return 0; } }
}
