package com.medicare.controller.warehouse;

import com.medicare.dao.PurchaseOrderDAO;
import com.medicare.dao.SupplierDAO;
import com.medicare.entity.Account;
import com.medicare.entity.PurchaseOrders;
import com.medicare.entity.Supplier;
import com.medicare.util.AuditHelper;
import com.medicare.util.SidebarHelper;
import com.medicare.util.WarehouseAuth;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * WarehousePurchaseOrderServlet — "Đơn hàng" trong Warehouse Console, dành riêng cho Thủ kho
 * (roleId 3). URL: /warehouse-orders
 */
@WebServlet("/warehouse-orders")
public class WarehousePurchaseOrderServlet extends HttpServlet {

    private final PurchaseOrderDAO poDAO = new PurchaseOrderDAO();
    private final SupplierDAO supplierDAO = new SupplierDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        Account acc = WarehouseAuth.require(req, resp);
        if (acc == null) return;

        List<PurchaseOrders> all = poDAO.findAll();
        Map<Integer, Integer> orderedMap = poDAO.sumOrderedQtyMap();
        Map<Integer, Integer> receivedMap = poDAO.sumReceivedQtyMap();

        // Cache tên NCC trong request — nhiều đơn có thể cùng 1 NCC, tránh gọi DB lặp lại.
        Map<Integer, String> supplierNameCache = new HashMap<>();

        LocalDate today = LocalDate.now();
        List<Map<String, Object>> rows = new ArrayList<>();
        int cntPending = 0, cntOverdue = 0, cntCompleted = 0;

        for (PurchaseOrders po : all) {
            boolean completed = "COMPLETED".equals(po.getStatus());
            boolean overdue = !completed && po.getExpectedDate() != null && po.getExpectedDate().isBefore(today);

            if (completed) cntCompleted++;
            else if (overdue) cntOverdue++;
            else cntPending++;

            int ordered = orderedMap.getOrDefault(po.getPoId(), 0);
            int received = receivedMap.getOrDefault(po.getPoId(), 0);
            int progressPct = ordered > 0 ? Math.min(100, Math.round(received * 100f / ordered)) : 0;

            String supName = supplierNameCache.computeIfAbsent(po.getSupplierId(), sid -> {
                Supplier s = supplierDAO.findById(sid);
                return s != null ? s.getSupplierName() : "—";
            });

            Map<String, Object> row = new LinkedHashMap<>();
            row.put("po", po);
            row.put("supplierName", supName);
            row.put("orderedQty", ordered);
            row.put("receivedQty", received);
            row.put("progressPct", progressPct);
            row.put("overdue", overdue);
            rows.add(row);
        }

        req.setAttribute("poRows", rows);
        req.setAttribute("cntPending", cntPending);
        req.setAttribute("cntOverdue", cntOverdue);
        req.setAttribute("cntCompleted", cntCompleted);
        req.setAttribute("cntTotal", all.size());
        req.setAttribute("activeNav", "orders");

        SidebarHelper.loadWarehouse(req, acc.getAccountId());

        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-orders.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        Account acc = WarehouseAuth.require(req, resp);
        if (acc == null) return;

        String action = req.getParameter("action");
        if ("confirm-receive".equals(action)) {
            int poId = 0;
            try {
                poId = Integer.parseInt(req.getParameter("poId"));
            } catch (Exception ignored) {}

            if (poId > 0) {
                int created = poDAO.confirmReceived(poId);
                if (created > 0) {
                    PurchaseOrders po = poDAO.findById(poId);
                    String poCode = po != null ? po.getPoCode() : ("#" + poId);
                    AuditHelper.log(req, "Nhận hàng kho", "PurchaseOrder", poId,
                            "Xác nhận nhận hàng — đã tạo " + created + " lô vào kho (Đơn " + poCode + ")");
                    resp.sendRedirect(req.getContextPath() + "/warehouse-orders?msg=receive-success&poCode=" + URLEncoder.encode(poCode, StandardCharsets.UTF_8));
                    return;
                } else {
                    String err = poDAO.getLastConfirmError();
                    if (err != null && (err.contains("không có dòng hàng") || err.contains("chưa có"))) {
                        // Đơn chưa có dòng chi tiết -> tự chuyển sang trang Nhập kho chi tiết
                        PurchaseOrders po = poDAO.findById(poId);
                        int supplierId = po != null ? po.getSupplierId() : 0;
                        resp.sendRedirect(req.getContextPath() + "/warehouse-import?poId=" + poId + (supplierId > 0 ? "&supplierId=" + supplierId : ""));
                        return;
                    }
                    resp.sendRedirect(req.getContextPath() + "/warehouse-orders?msg=receive-fail&err=" + (err != null ? URLEncoder.encode(err, StandardCharsets.UTF_8) : ""));
                    return;
                }
            }
        }
        resp.sendRedirect(req.getContextPath() + "/warehouse-orders");
    }
}
