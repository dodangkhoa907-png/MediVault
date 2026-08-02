package com.medicare.controller.warehouse;

import com.medicare.dao.PurchaseOrderDAO;
import com.medicare.dao.SupplierDAO;
import com.medicare.entity.Account;
import com.medicare.entity.PurchaseOrders;
import com.medicare.entity.Supplier;
import com.medicare.util.SidebarHelper;
import com.medicare.util.WarehouseAuth;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * WarehousePurchaseOrderServlet — "Đơn hàng" trong Warehouse Console, dành riêng cho Thủ kho
 * (roleId 3). URL: /warehouse-orders
 *
 * <p>CHỈ ĐỌC — tạo/duyệt PO vẫn do Admin thực hiện qua {@code /purchase-orders}. Trang này cho
 * Thủ kho một nơi để THEO DÕI trạng thái giao hàng của các đơn (đã đặt / quá hạn / đã nhận) mà
 * không phải văng sang giao diện Admin. Dựng lại hoàn toàn giao diện cho Warehouse Console (khác
 * bảng của Admin) — dùng chung {@link PurchaseOrderDAO} đã có, không thêm bảng mới.</p>
 *
 * <p>Trạng thái thực tế trong DB hiện chỉ có {@code PENDING}/{@code COMPLETED} (xem
 * {@link PurchaseOrderDAO#confirmReceived}) — nhận hàng là MỘT LẦN trọn gói, chưa hỗ trợ nhận
 * từng phần. Nên "Quá hạn" ở đây là suy ra (PENDING mà ExpectedDate đã qua), và "SL đã nhận"
 * chỉ có 2 giá trị thực tế: 0 (chưa nhận) hoặc bằng SL đặt (đã nhận xong) — cho tới khi luồng
 * Nhận hàng từng phần (nếu làm) được thêm.</p>
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
}
