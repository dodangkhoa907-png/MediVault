package com.medicare.controller.admin;

import com.medicare.config.AppCache;
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
 * POST action=delete&id=X → xóa (chỉ khi không có lịch liên kết)
 */
@WebServlet("/shift-types")
public class ShiftTypeServlet extends HttpServlet {

    private final IShiftTypeDAO dao = new ShiftTypeDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        Account admin = getAdmin(req, resp); if (admin == null) return;
        resp.sendRedirect(req.getContextPath() + "/shifts?tab=types");
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
            case "delete" -> handleDelete(req, resp, admin);
            case "bulk-delete" -> handleBulkDelete(req, resp, admin);
            default -> resp.sendRedirect(req.getContextPath() + "/shifts?tab=types");
        }
    }

    private void handleCreate(HttpServletRequest req, HttpServletResponse resp, Account admin)
            throws IOException {
        try {
            ShiftType st = parseForm(req);
            boolean ok = dao.insert(st);
            if (ok) AuditHelper.log(req, "Tạo loại ca", "ShiftType",
                    "Admin tạo loại ca: " + st.getName() + ", " + st.getHourlyRate() + "đ/h");
            resp.sendRedirect(req.getContextPath() + "/shifts?tab=types&msg=" + (ok ? "type-saved" : "type-err"));
        } catch (IllegalArgumentException e) {
            String reason = e.getMessage() != null ? e.getMessage() : "type-err";
            resp.sendRedirect(req.getContextPath() + "/shifts?tab=types&msg=" + reason);
        }
    }

    private void handleUpdate(HttpServletRequest req, HttpServletResponse resp, Account admin)
            throws IOException {
        int id = parseInt(req.getParameter("shiftTypeId"), 0);
        if (id == 0) { resp.sendRedirect(req.getContextPath() + "/shifts?tab=types&msg=type-err"); return; }
        try {
            ShiftType st = parseForm(req);
            st.setShiftTypeId(id);
            boolean ok = dao.update(st);
            if (ok) AuditHelper.log(req, "Sửa loại ca", "ShiftType",
                    "Sửa loại ca ID " + id + ": " + st.getName());
            resp.sendRedirect(req.getContextPath() + "/shifts?tab=types&msg=" + (ok ? "type-saved" : "type-err"));
        } catch (IllegalArgumentException e) {
            String reason = e.getMessage() != null ? e.getMessage() : "type-err";
            resp.sendRedirect(req.getContextPath() + "/shifts?tab=types&msg=" + reason);
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
        AppCache.invalidateShiftTypes();
        resp.sendRedirect(req.getContextPath() + "/shifts?tab=types&msg=type-saved");
    }

    private void handleDelete(HttpServletRequest req, HttpServletResponse resp, Account admin)
            throws IOException {
        int id = parseInt(req.getParameter("id"), 0);
        ShiftType st = dao.findById(id);
        if (st == null) { resp.sendRedirect(req.getContextPath() + "/shifts?tab=types"); return; }
        // Chỉ xóa khi inactive — bắt buộc phải tạm dừng trước
        if (st.isActive()) {
            resp.sendRedirect(req.getContextPath() + "/shifts?tab=types&msg=type-err"); return;
        }
        // Kiểm tra còn ShiftSchedule nào đang dùng loại ca này không
        // (dùng ShiftScheduleDAO — inject trực tiếp vì Servlet không extends HttpServlet với DI)
        com.medicare.dao.ShiftScheduleDAO scheduleDAO = new com.medicare.dao.ShiftScheduleDAO();
        boolean hasSchedules = scheduleDAO.existsByShiftTypeId(id);
        if (hasSchedules) {
            // Không cho xóa — còn lịch ca đang dùng loại này
            resp.sendRedirect(req.getContextPath() + "/shifts?tab=types&msg=type-has-schedules"); return;
        }
        boolean ok = dao.delete(id);
        if (ok) {
            AppCache.invalidateShiftTypes();
            AuditHelper.log(req, "Xóa loại ca", "ShiftType", "Xóa loại ca: " + st.getName());
        }
        resp.sendRedirect(req.getContextPath() + "/shifts?tab=types&msg=" + (ok ? "type-deleted" : "type-err"));
    }

    /**
     * Xóa nhiều loại ca cùng lúc. Cho phép tích chọn cả loại ca đang "Đang dùng",
     * nhưng mỗi ID vẫn phải qua đúng 2 điều kiện như xóa đơn lẻ:
     *   1) Phải đang inactive (Tạm dừng) — nếu đang active thì báo lỗi, không xóa.
     *   2) Không còn ShiftSchedule nào tham chiếu — nếu còn thì báo lỗi, không xóa.
     * Trả về kết quả tổng hợp qua query string để JSP hiển thị chi tiết.
     */
    private void handleBulkDelete(HttpServletRequest req, HttpServletResponse resp, Account admin)
            throws IOException {
        String idsParam = req.getParameter("ids");
        if (idsParam == null || idsParam.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/shifts?tab=types"); return;
        }

        com.medicare.dao.ShiftScheduleDAO scheduleDAO = new com.medicare.dao.ShiftScheduleDAO();

        int deletedCount = 0;
        java.util.List<String> skippedActive = new java.util.ArrayList<>();
        java.util.List<String> skippedHasSchedule = new java.util.ArrayList<>();

        for (String idStr : idsParam.split(",")) {
            int id = parseInt(idStr.trim(), 0);
            if (id == 0) continue;

            ShiftType st = dao.findById(id);
            if (st == null) continue;

            if (st.isActive()) {
                skippedActive.add(st.getName());
                continue;
            }
            if (scheduleDAO.existsByShiftTypeId(id)) {
                skippedHasSchedule.add(st.getName());
                continue;
            }

            boolean ok = dao.delete(id);
            if (ok) {
                deletedCount++;
                AuditHelper.log(req, "Xóa loại ca", "ShiftType", "Xóa loại ca: " + st.getName());
            }
        }

        if (deletedCount > 0) AppCache.invalidateShiftTypes();

        StringBuilder msg = new StringBuilder(req.getContextPath() + "/shifts?tab=types&msg=type-bulk-deleted");
        msg.append("&deleted=").append(deletedCount);
        if (!skippedActive.isEmpty()) {
            msg.append("&skippedActive=").append(java.net.URLEncoder.encode(
                    String.join(", ", skippedActive), java.nio.charset.StandardCharsets.UTF_8));
        }
        if (!skippedHasSchedule.isEmpty()) {
            msg.append("&skippedSchedule=").append(java.net.URLEncoder.encode(
                    String.join(", ", skippedHasSchedule), java.nio.charset.StandardCharsets.UTF_8));
        }
        resp.sendRedirect(msg.toString());
    }

    private ShiftType parseForm(HttpServletRequest req) {
        String name = req.getParameter("name");
        String startTime = req.getParameter("startTime"); // HH:mm
        String endTime   = req.getParameter("endTime");
        String rateStr   = req.getParameter("hourlyRate");
        String allowStr  = req.getParameter("allowanceAmount");

        if (name == null || name.trim().isEmpty()) {
            throw new IllegalArgumentException("type-err-name");
        }
        if (startTime == null || startTime.isEmpty() || endTime == null || endTime.isEmpty()) {
            throw new IllegalArgumentException("type-err-time");
        }
        BigDecimal rate;
        try {
            rate = new BigDecimal(rateStr);
        } catch (Exception e) {
            throw new IllegalArgumentException("type-err-rate");
        }
        if (rate.compareTo(new BigDecimal("50000")) < 0) {
            throw new IllegalArgumentException("type-err-rate");
        }

        try {
            int sh = Integer.parseInt(startTime.split(":")[0]);
            int sm = Integer.parseInt(startTime.split(":")[1]);
            int eh = Integer.parseInt(endTime.split(":")[0]);
            int em = Integer.parseInt(endTime.split(":")[1]);
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
        } catch (Exception e) {
            throw new IllegalArgumentException("type-err-time");
        }
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