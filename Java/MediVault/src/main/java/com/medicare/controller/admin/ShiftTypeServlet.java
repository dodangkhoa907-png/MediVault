package com.medicare.controller.admin;

import com.medicare.dao.ShiftTypeDAO;
import com.medicare.dao.interfaces.IShiftTypeDAO;
import com.medicare.entity.Account;
import com.medicare.entity.ShiftType;
import com.medicare.util.AuditHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;

/**
 * ShiftTypeServlet — CRUD loại ca làm việc
 * URL: /shift-types
 * POST action=create  → tạo mới
 * POST action=update  → sửa
 * POST action=toggle  → bật/tắt
 * GET  action=delete&id=X → xóa (chỉ khi không có lịch liên kết)
 */
@WebServlet("/shift-types")
public class ShiftTypeServlet extends HttpServlet {

    private final IShiftTypeDAO dao = new ShiftTypeDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        Account admin = getAdmin(req, resp); if (admin == null) return;
        String action = req.getParameter("action");
        if ("delete".equals(action)) handleDelete(req, resp, admin);
        else resp.sendRedirect(req.getContextPath() + "/shifts?tab=types");
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        Account admin = getAdmin(req, resp); if (admin == null) return;
        String action = req.getParameter("action");
        switch (action != null ? action : "") {
            case "create" -> handleCreate(req, resp, admin);
            case "update" -> handleUpdate(req, resp, admin);
            case "toggle" -> handleToggle(req, resp, admin);
            default -> resp.sendRedirect(req.getContextPath() + "/shifts?tab=types");
        }
    }

    private void handleCreate(HttpServletRequest req, HttpServletResponse resp, Account admin)
            throws IOException {
        ShiftType st = parseForm(req);
        if (st == null) { resp.sendRedirect(req.getContextPath() + "/shifts?tab=types&msg=type-err"); return; }
        try {
            boolean ok = dao.insert(st);
            if (ok) AuditHelper.log(req, "Tạo loại ca", "ShiftType",
                    "Admin tạo loại ca: " + st.getName() + ", " + st.getHourlyRate() + "đ/h");
            resp.sendRedirect(req.getContextPath() + "/shifts?tab=types&msg=" + (ok ? "type-saved" : "type-err"));
        } catch (IllegalArgumentException e) {
            resp.sendRedirect(req.getContextPath() + "/shifts?tab=types&msg=type-err");
        }
    }

    private void handleUpdate(HttpServletRequest req, HttpServletResponse resp, Account admin)
            throws IOException {
        int id = parseInt(req.getParameter("shiftTypeId"), 0);
        ShiftType st = parseForm(req);
        if (st == null || id == 0) { resp.sendRedirect(req.getContextPath() + "/shifts?tab=types&msg=type-err"); return; }
        st.setShiftTypeId(id);
        try {
            boolean ok = dao.update(st);
            if (ok) AuditHelper.log(req, "Sửa loại ca", "ShiftType",
                    "Sửa loại ca ID " + id + ": " + st.getName());
            resp.sendRedirect(req.getContextPath() + "/shifts?tab=types&msg=" + (ok ? "type-saved" : "type-err"));
        } catch (IllegalArgumentException e) {
            resp.sendRedirect(req.getContextPath() + "/shifts?tab=types&msg=type-err");
        }
    }

    private void handleToggle(HttpServletRequest req, HttpServletResponse resp, Account admin)
            throws IOException {
        int id = parseInt(req.getParameter("shiftTypeId"), 0);
        if (id == 0) { resp.sendRedirect(req.getContextPath() + "/shifts?tab=types"); return; }
        ShiftType existing = dao.findById(id);
        if (existing != null) {
            dao.setActive(id, !existing.isActive());
            AuditHelper.log(req, "Toggle loại ca", "ShiftType",
                    (existing.isActive() ? "Tạm dừng" : "Kích hoạt") + " loại ca ID " + id);
        }
        resp.sendRedirect(req.getContextPath() + "/shifts?tab=types&msg=type-saved");
    }

    private void handleDelete(HttpServletRequest req, HttpServletResponse resp, Account admin)
            throws IOException {
        int id = parseInt(req.getParameter("id"), 0);
        ShiftType st = dao.findById(id);
        if (st == null) { resp.sendRedirect(req.getContextPath() + "/shifts?tab=types"); return; }
        // Chỉ xóa khi inactive
        if (st.isActive()) {
            resp.sendRedirect(req.getContextPath() + "/shifts?tab=types&msg=type-err"); return;
        }
        // TODO: check không có ShiftSchedule dùng loại này
        boolean ok = dao.delete(id);
        if (ok) AuditHelper.log(req, "Xóa loại ca", "ShiftType", "Xóa loại ca: " + st.getName());
        resp.sendRedirect(req.getContextPath() + "/shifts?tab=types&msg=" + (ok ? "type-deleted" : "type-err"));
    }

    private ShiftType parseForm(HttpServletRequest req) {
        try {
            String name = req.getParameter("name");
            String startTime = req.getParameter("startTime"); // HH:mm
            String endTime   = req.getParameter("endTime");
            String rateStr   = req.getParameter("hourlyRate");
            String allowStr  = req.getParameter("allowanceAmount");
            if (name == null || name.trim().isEmpty()) return null;
            int sh = Integer.parseInt(startTime.split(":")[0]);
            int sm = Integer.parseInt(startTime.split(":")[1]);
            int eh = Integer.parseInt(endTime.split(":")[0]);
            int em = Integer.parseInt(endTime.split(":")[1]);
            BigDecimal rate = new BigDecimal(rateStr);
            BigDecimal allow = allowStr != null && !allowStr.isEmpty()
                    ? new BigDecimal(allowStr) : BigDecimal.ZERO;
            ShiftType st = new ShiftType();
            st.setName(name.trim());
            st.setStartHour(sh); st.setStartMinute(sm);
            st.setEndHour(eh);   st.setEndMinute(em);
            st.setHourlyRate(rate);
            st.setAllowanceAmount(allow);
            st.setOvertimeMultiplier(new BigDecimal("1.5"));
            st.setActive(true);
            return st;
        } catch (Exception e) { return null; }
    }

    private Account getAdmin(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        HttpSession session = req.getSession(false);
        Account a = session != null ? (Account) session.getAttribute("adminAccount") : null;
        if (a == null || a.getRoleId() != 1) { resp.sendRedirect(req.getContextPath() + "/login"); return null; }
        return a;
    }

    private int parseInt(String s, int def) {
        try { return s != null ? Integer.parseInt(s) : def; }
        catch (NumberFormatException e) { return def; }
    }
}