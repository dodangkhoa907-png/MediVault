package com.medicare.controller.warehouse;

import com.medicare.dao.ShelfDAO;
import com.medicare.entity.Account;
import com.medicare.entity.Shelf;
import com.medicare.util.AuditHelper;
import com.medicare.util.SidebarHelper;
import com.medicare.util.ValidationUtil;
import com.medicare.util.WarehouseAuth;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * WarehouseShelfServlet — "Quản lý kệ" trong Warehouse Console, CRUD đầy đủ cho Thủ kho
 * (roleId 3). URL: /warehouse-shelf
 *
 * <p>Trước đây chỉ đọc — sửa/thêm/xoá phải qua Admin ({@code /shelves}). Theo yêu cầu, Thủ kho
 * giờ tự quản lý được kệ ngay tại trang của mình, làm chi tiết hơn bản Admin: thêm/sửa qua
 * modal (không văng trang), tìm kiếm theo tên/vị trí, và khi xoá bị chặn thì hiện luôn DANH
 * SÁCH thuốc đang gán trên kệ đó (Admin chỉ báo chung chung "còn thuốc").</p>
 */
@WebServlet("/warehouse-shelf")
public class WarehouseShelfServlet extends HttpServlet {

    private final ShelfDAO shelfDAO = new ShelfDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        Account acc = WarehouseAuth.require(req, resp);
        if (acc == null) return;

        if ("detail".equals(req.getParameter("action"))) {
            apiDetail(req, resp);
            return;
        }

        // Tìm kiếm lọc ngay trên trình duyệt (JS, không round-trip) — server chỉ cần đổ
        // TOÀN BỘ danh sách kèm dữ liệu để JS lọc tức thì, giống các trang Kho khác.
        List<Shelf> shelves = shelfDAO.findAll();
        List<Map<String, Object>> rows = new ArrayList<>();
        int totalMedicines = 0;
        int emptyShelves = 0;
        for (Shelf s : shelves) {
            int count = shelfDAO.countMedicinesOnShelf(s.getShelfId());
            totalMedicines += count;
            if (count == 0) emptyShelves++;
            Map<String, Object> row = new LinkedHashMap<>();
            row.put("shelf", s);
            row.put("medicineCount", count);
            rows.add(row);
        }

        req.setAttribute("shelfRows", rows);
        req.setAttribute("shelfCount", shelves.size());
        req.setAttribute("totalMedicinesOnShelves", totalMedicines);
        req.setAttribute("emptyShelfCount", emptyShelves);
        req.setAttribute("activeNav", "shelves");

        SidebarHelper.loadWarehouse(req, acc.getAccountId());

        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-shelf.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        Account acc = WarehouseAuth.require(req, resp);
        if (acc == null) return;
        req.setCharacterEncoding("UTF-8");

        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "create" -> doCreate(req, resp);
            case "update" -> doUpdate(req, resp);
            case "delete" -> handleDelete(req, resp);
            default -> resp.sendRedirect(req.getContextPath() + "/warehouse-shelf");
        }
    }

    private void doCreate(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String name = trim(req.getParameter("shelfName"));
        if (ValidationUtil.isBlank(name)) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-shelf?msg=name-required");
            return;
        }
        if (nameExists(name, null)) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-shelf?msg=name-dup");
            return;
        }
        Shelf s = buildFrom(req, name);
        boolean ok = shelfDAO.insert(s);
        if (ok) AuditHelper.log(req, "Tạo vị trí kệ", "Shelf", "Thủ kho thêm kệ: " + name);
        resp.sendRedirect(req.getContextPath() + "/warehouse-shelf?msg=" + (ok ? "created" : "error"));
    }

    private void doUpdate(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        int id = parseInt(req.getParameter("shelfId"));
        if (id <= 0) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-shelf?msg=error");
            return;
        }
        String name = trim(req.getParameter("shelfName"));
        if (ValidationUtil.isBlank(name)) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-shelf?msg=name-required");
            return;
        }
        if (nameExists(name, id)) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-shelf?msg=name-dup");
            return;
        }
        Shelf s = buildFrom(req, name);
        s.setShelfId(id);
        boolean ok = shelfDAO.update(s);
        if (ok) AuditHelper.log(req, "Sửa vị trí kệ", "Shelf", "Thủ kho sửa kệ: " + name);
        resp.sendRedirect(req.getContextPath() + "/warehouse-shelf?msg=" + (ok ? "updated" : "error"));
    }

    private void handleDelete(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        int id = parseInt(req.getParameter("id"));
        if (id <= 0) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-shelf");
            return;
        }
        // Chặn xoá kệ còn thuốc — JS đã hiện sẵn danh sách thuốc chặn ở modal chi tiết
        // (qua action=detail), nhưng vẫn kiểm lại ở server phòng khi bị qua mặt.
        int used = shelfDAO.countMedicinesOnShelf(id);
        if (used > 0) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-shelf?msg=has-medicine");
            return;
        }
        boolean ok = shelfDAO.delete(id);
        if (ok) AuditHelper.log(req, "Xóa vị trí kệ", "Shelf", id, "Thủ kho xóa kệ ID " + id);
        resp.sendRedirect(req.getContextPath() + "/warehouse-shelf?msg=" + (ok ? "deleted" : "error"));
    }

    // ── AJAX: chi tiết 1 kệ + danh sách thuốc đang gán — dùng chung cho modal "Xem chi tiết",
    // đổ dữ liệu vào modal Sửa, và xem trước danh sách chặn xoá. ──
    private void apiDetail(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        PrintWriter out = resp.getWriter();
        try {
            int id = Integer.parseInt(req.getParameter("id"));
            Shelf s = shelfDAO.findById(id);
            if (s == null) { out.print("{\"ok\":false,\"msg\":\"Không tìm thấy kệ này.\"}"); return; }

            List<Map<String, Object>> meds = shelfDAO.findMedicinesOnShelf(id);

            StringBuilder sb = new StringBuilder("{\"ok\":true,\"shelf\":{");
            sb.append("\"id\":").append(s.getShelfId()).append(',');
            sb.append("\"name\":").append(jsonStr(s.getShelfName())).append(',');
            sb.append("\"type\":").append(jsonStr(s.getShelfType())).append(',');
            sb.append("\"slotCode\":").append(jsonStr(s.getMachineSlotCode())).append(',');
            sb.append("\"motorId\":").append(jsonStr(s.getMotorId())).append(',');
            sb.append("\"notes\":").append(jsonStr(s.getLocationNotes())).append(',');
            sb.append("\"automated\":").append(s.isAutomated());
            sb.append("},\"medicineCount\":").append(meds.size()).append(",\"medicines\":[");
            for (int i = 0; i < meds.size(); i++) {
                if (i > 0) sb.append(',');
                Map<String, Object> m = meds.get(i);
                sb.append("{\"id\":").append(m.get("id")).append(',');
                sb.append("\"code\":").append(jsonStr((String) m.get("code"))).append(',');
                sb.append("\"name\":").append(jsonStr((String) m.get("name"))).append(',');
                sb.append("\"unit\":").append(jsonStr((String) m.get("unit"))).append('}');
            }
            sb.append("]}");
            out.print(sb);
        } catch (Exception e) {
            out.print("{\"ok\":false,\"msg\":" + jsonStr("Lỗi tải dữ liệu: " + e.getMessage()) + "}");
        }
    }

    private boolean nameExists(String name, Integer excludeId) {
        for (Shelf s : shelfDAO.findAll()) {
            if (excludeId != null && s.getShelfId() == excludeId) continue;
            if (name.equalsIgnoreCase(trim(s.getShelfName()))) return true;
        }
        return false;
    }

    private Shelf buildFrom(HttpServletRequest req, String name) {
        Shelf s = new Shelf();
        s.setShelfName(name);
        String type = req.getParameter("shelfType");
        s.setShelfType(ValidationUtil.isBlank(type) ? "RETAIL" : type);
        s.setLocationNotes(trim(req.getParameter("locationNotes")));
        s.setMachineSlotCode(trim(req.getParameter("machineSlotCode")));
        s.setMotorId(trim(req.getParameter("motorId")));
        return s;
    }

    private static String jsonStr(String s) {
        if (s == null) return "\"\"";
        return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"")
                       .replace("\n", "\\n").replace("\r", "\\r").replace("\t", "\\t") + "\"";
    }

    private String trim(String s) { return s == null ? null : s.trim(); }
    private int parseInt(String s) { try { return Integer.parseInt(s); } catch (Exception e) { return 0; } }
}
