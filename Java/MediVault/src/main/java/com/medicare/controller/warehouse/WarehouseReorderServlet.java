package com.medicare.controller.warehouse;

import com.medicare.config.CacheManager;
import com.medicare.config.DBContext;
import com.medicare.dao.PurchaseOrderDAO;
import com.medicare.dao.SupplierDAO;
import com.medicare.entity.Account;
import com.medicare.entity.PurchaseOrderDetail;
import com.medicare.entity.PurchaseOrders;
import com.medicare.entity.Supplier;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * WarehouseReorderServlet — Gợi ý đặt hàng tự động (ROP) + Cảnh báo tồn kho đa tầng
 * theo hạn dùng, dành riêng cho Quản lý kho (roleId 3 = Thủ kho).
 * URL: /warehouse-reorder
 *
 * <p>Thủ kho chỉ XEM gợi ý (do {@link com.medicare.service.ReorderAlertService} tự tạo mỗi giờ),
 * KHÔNG tự duyệt — việc duyệt/xác nhận nhận hàng do Admin thực hiện qua màn /purchase-orders
 * có sẵn (đây chỉ là điều hướng "Xem chi tiết đơn" sang route đó).</p>
 */
@WebServlet("/warehouse-reorder")
public class WarehouseReorderServlet extends HttpServlet {

    private static final int ROLE_WAREHOUSE = 3;

    // Notes cố định do ReorderAlertService gắn khi tạo phiếu — dùng để lọc đúng PO do HỆ THỐNG
    // tự sinh, tránh lẫn với PO Status=PENDING mà Admin tự tạo thủ công qua màn nhập kho.
    private static final String AUTO_NOTES_PREFIX = "Tự động đề xuất bởi hệ thống";

    private final PurchaseOrderDAO poDAO = new PurchaseOrderDAO();
    private final SupplierDAO supplierDAO = new SupplierDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        Account acc = com.medicare.util.WarehouseAuth.require(req, resp);
        if (acc == null) return;

        // ── "Xem đơn" mở MODAL ngay trong trang, không điều hướng sang /purchase-orders
        // của Admin — trước đây làm vậy khiến Thủ kho bị "văng" từ giao diện teal (Warehouse
        // Console) sang giao diện xanh dương (Admin Console) giữa chừng thao tác, một luồng
        // giao diện lạc hẳn khỏi bối cảnh đang làm. Chỉ đọc — Thủ kho không có quyền sửa PO. ──
        if ("po-detail".equals(req.getParameter("action"))) {
            apiPoDetail(req, resp);
            return;
        }

        List<Map<String, Object>> pendingSuggestions =
                CacheManager.getShort("wh.reorderPending", this::findPendingSuggestions);
        List<Map<String, Object>> tierLight =    // 91-180 ngày
                CacheManager.getShort("wh.expTierLight", () -> findExpiryTier(91, 180, "ACTIVE"));
        List<Map<String, Object>> tierRestricted = // 31-90 ngày
                CacheManager.getShort("wh.expTierRestricted", () -> findExpiryTier(31, 90, "ACTIVE"));
        List<Map<String, Object>> tierQuarantined = // đã cách ly (<=30 ngày)
                CacheManager.getShort("wh.expTierQuarantined", this::findQuarantined);

        req.setAttribute("staffAcc", acc);
        req.setAttribute("pendingSuggestions", pendingSuggestions);
        req.setAttribute("tierLight", tierLight);
        req.setAttribute("tierRestricted", tierRestricted);
        req.setAttribute("tierQuarantined", tierQuarantined);
        // 2 badge sidebar — trang này trước đây không set gì, cả 2 badge đều biến mất ở đây.
        com.medicare.util.SidebarHelper.loadWarehouse(req, acc.getAccountId());

        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-reorder.jsp")
                .forward(req, resp);
    }

    /**
     * JSON chi tiết 1 phiếu đề xuất cho modal "Xem đơn" — CHỈ ĐỌC, gọi thẳng
     * {@link PurchaseOrderDAO#findById} / {@link PurchaseOrderDAO#findDetails} đã có sẵn,
     * không thêm SQL mới, không đụng gì tới PurchaseOrderServlet của Admin.
     */
    private void apiPoDetail(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();

        int poId = 0;
        try { poId = Integer.parseInt(req.getParameter("id")); } catch (Exception ignored) {}
        PurchaseOrders po = poId > 0 ? poDAO.findById(poId) : null;
        if (po == null) { out.print("{\"ok\":false}"); return; }

        Supplier sup = supplierDAO.findById(po.getSupplierId());
        List<PurchaseOrderDetail> lines = poDAO.findDetails(poId);
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

        StringBuilder sb = new StringBuilder();
        sb.append("{\"ok\":true")
          .append(",\"poId\":").append(po.getPoId())
          .append(",\"status\":\"").append(esc(po.getStatus())).append('"')
          .append(",\"orderDate\":\"").append(po.getOrderDate() != null ? po.getOrderDate().format(fmt) : "").append('"')
          .append(",\"supplierName\":\"").append(esc(sup != null ? sup.getSupplierName() : "—")).append('"')
          .append(",\"totalValue\":").append(po.getTotalValue() != null ? po.getTotalValue().toPlainString() : "0")
          .append(",\"lines\":[");
        for (int i = 0; i < lines.size(); i++) {
            PurchaseOrderDetail d = lines.get(i);
            if (i > 0) sb.append(',');
            sb.append("{\"medicineName\":\"").append(esc(d.getMedicineName()))
              .append("\",\"quantity\":").append(d.getQuantity())
              .append(",\"importPrice\":").append(d.getImportPrice() != null ? d.getImportPrice().toPlainString() : "0")
              .append('}');
        }
        sb.append("]}");
        out.print(sb);
    }

    private static String esc(String s) {
        return s == null ? "" : s.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    /** Phiếu đặt hàng gợi ý (PENDING, do hệ thống tự tạo) — mỗi phiếu 1 dòng thuốc. */
    private List<Map<String, Object>> findPendingSuggestions() {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT po.POID, po.OrderDate, po.TotalValue, s.SupplierName, " +
                "       m.MedicineName, d.Quantity " +
                "FROM PurchaseOrders po " +
                "JOIN PurchaseOrderDetails d ON d.POID = po.POID " +
                "JOIN Medicines m ON m.MedicineID = d.MedicineID " +
                "JOIN Suppliers s ON s.SupplierID = po.SupplierID " +
                "WHERE po.Status = 'PENDING' AND po.Notes LIKE ? " +
                "ORDER BY po.OrderDate DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, AUTO_NOTES_PREFIX + "%");
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("poId", rs.getInt("POID"));
                    row.put("orderDate", rs.getTimestamp("OrderDate"));
                    row.put("totalValue", rs.getBigDecimal("TotalValue"));
                    row.put("supplierName", rs.getString("SupplierName"));
                    row.put("medicineName", rs.getString("MedicineName"));
                    row.put("quantity", rs.getInt("Quantity"));
                    list.add(row);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    /** Lô theo tầng cảnh báo hạn dùng: fromDays &lt;= còn lại &lt;= toDays, lọc theo Status. */
    private List<Map<String, Object>> findExpiryTier(int fromDays, int toDays, String status) {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT b.BatchNumber, b.CurrentQuantity, b.ExpiryDate, m.MedicineName " +
                "FROM Batches b JOIN Medicines m ON m.MedicineID = b.MedicineID " +
                "WHERE b.Status = ? " +
                "AND b.ExpiryDate BETWEEN DATEADD(day, ?, GETDATE()) AND DATEADD(day, ?, GETDATE()) " +
                "ORDER BY b.ExpiryDate ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, fromDays);
            ps.setInt(3, toDays);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapBatchRow(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    /** Lô đã bị ReorderAlertService cách ly (Status='QUARANTINE', tức còn <=30 ngày lúc cách ly). */
    private List<Map<String, Object>> findQuarantined() {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT b.BatchNumber, b.CurrentQuantity, b.ExpiryDate, m.MedicineName " +
                "FROM Batches b JOIN Medicines m ON m.MedicineID = b.MedicineID " +
                "WHERE b.Status = 'QUARANTINE' " +
                "ORDER BY b.ExpiryDate ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapBatchRow(rs));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    private Map<String, Object> mapBatchRow(ResultSet rs) throws java.sql.SQLException {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("batchNumber", rs.getString("BatchNumber"));
        row.put("medicineName", rs.getString("MedicineName"));
        row.put("currentQuantity", rs.getInt("CurrentQuantity"));
        row.put("expiryDate", rs.getDate("ExpiryDate"));
        return row;
    }
}
