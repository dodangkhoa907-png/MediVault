package com.medicare.controller.warehouse;

import com.medicare.config.CacheManager;
import com.medicare.config.DBContext;
import com.medicare.entity.Account;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * WarehouseReorderServlet — Gợi ý đặt hàng tự động (ROP) + Cảnh báo tồn kho đa tầng
 * theo hạn dùng, dành riêng cho Quản lý kho (roleId 3 = Thủ kho).
 * URL: /warehouse-reorder?uid=&lt;id&gt;
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

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String uid = req.getParameter("uid");
        resp.sendRedirect(req.getContextPath() + "/warehouse-inventory?uid=" + (uid != null ? uid : "") + "&tab=reorder");
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
