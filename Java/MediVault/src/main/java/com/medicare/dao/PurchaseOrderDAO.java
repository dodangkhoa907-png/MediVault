package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IPurchaseOrderDAO;
import com.medicare.entity.Batches;
import com.medicare.entity.PurchaseOrders;
import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class PurchaseOrderDAO implements IPurchaseOrderDAO {

    // ThreadLocal — PurchaseOrderDAO được servlet giữ như 1 instance dùng chung cho MỌI
    // request (xem PurchaseOrderServlet/MedicineService: `private final ... = new PurchaseOrderDAO()`),
    // nên KHÔNG được dùng field thường ở đây: 2 admin xác nhận nhận hàng cùng lúc trên 2 đơn
    // khác nhau sẽ ghi đè lỗi của nhau. ThreadLocal đảm bảo mỗi thread (mỗi request) có bản riêng.
    private final ThreadLocal<String> lastConfirmError = new ThreadLocal<>();

    /** Lý do thất bại của lần gọi confirmReceived() gần nhất trên THREAD HIỆN TẠI — null nếu thành công/chưa gọi. */
    public String getLastConfirmError() { return lastConfirmError.get(); }

    private PurchaseOrders mapRow(ResultSet rs) throws SQLException {
        PurchaseOrders po = new PurchaseOrders();
        po.setPoId(rs.getInt("POID"));
        po.setPoCode(rs.getString("POCode"));
        po.setSupplierId(rs.getInt("SupplierID"));
        po.setAccountId(rs.getInt("AccountID"));
        if (rs.getTimestamp("OrderDate") != null)
            po.setOrderDate(rs.getTimestamp("OrderDate").toLocalDateTime());
        po.setTotalValue(rs.getBigDecimal("TotalValue"));
        po.setNotes(rs.getString("Notes"));
        try { po.setStatus(rs.getString("Status")); } catch (SQLException ignored) {}
        try { po.setPaymentMethod(rs.getString("PaymentMethod")); } catch (SQLException ignored) {}
        try { po.setDiscountAmount(rs.getBigDecimal("DiscountAmount")); } catch (SQLException ignored) {}
        // Cột thêm sau (migration warehouse_po_expected_date_migration.sql) — try/catch để DB
        // chưa chạy migration vẫn không vỡ các câu SELECT * hiện có.
        try {
            Date exp = rs.getDate("ExpectedDate");
            if (exp != null) po.setExpectedDate(exp.toLocalDate());
        } catch (SQLException ignored) {}
        return po;
    }

    /**
     * Tạo phiếu nhập nhiều dòng trong 1 TRANSACTION.
     * LUÔN ghi PurchaseOrders + PurchaseOrderDetails (chứng từ).
     * Chỉ khi receiveNow=true (hàng đã về) mới INSERT thêm Batches (kho tăng).
     * Đơn PENDING: kho CHƯA tăng viên nào — chờ bấm "Xác nhận hàng đã về".
     * POCode là computed ('PN'+POID) nên KHÔNG set. Trả về POID mới, -1 nếu lỗi.
     */
    public int createWithBatches(PurchaseOrders po, List<Batches> lines) {
        boolean receiveNow = !"PENDING".equals(po.getStatus());
        String poSql = "INSERT INTO PurchaseOrders " +
                "(SupplierID, AccountID, OrderDate, TotalValue, Notes, Status, PaymentMethod, DiscountAmount) " +
                "VALUES (?,?,GETDATE(),?,?,?,?,?); SELECT SCOPE_IDENTITY();";
        String dSql = "INSERT INTO PurchaseOrderDetails " +
                "(POID, MedicineID, Quantity, ImportPrice, BatchNumber, ExpiryDate, ManufactureDate) " +
                "VALUES (?,?,?,?,?,?,?)";
        Connection cn = null;
        try {
            cn = DBContext.getConnection();
            cn.setAutoCommit(false);
            int poId;
            try (PreparedStatement ps = cn.prepareStatement(poSql)) {
                ps.setInt(1, po.getSupplierId());
                ps.setInt(2, po.getAccountId());
                ps.setBigDecimal(3, po.getTotalValue() != null ? po.getTotalValue() : BigDecimal.ZERO);
                ps.setNString(4, po.getNotes());
                ps.setString(5, po.getStatus() != null ? po.getStatus() : "COMPLETED");
                if (po.getPaymentMethod() != null && !po.getPaymentMethod().isEmpty())
                    ps.setString(6, po.getPaymentMethod());
                else ps.setNull(6, Types.VARCHAR);
                ps.setBigDecimal(7, po.getDiscountAmount() != null ? po.getDiscountAmount() : BigDecimal.ZERO);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next() || rs.getBigDecimal(1) == null) { cn.rollback(); return -1; }
                    poId = rs.getBigDecimal(1).intValue();
                }
            }
            // Chứng từ: luôn lưu chi tiết dòng hàng
            try (PreparedStatement ps = cn.prepareStatement(dSql)) {
                for (Batches b : lines) {
                    ps.setInt(1, poId);
                    ps.setInt(2, b.getMedicineId());
                    ps.setInt(3, b.getInitialQuantity());
                    ps.setBigDecimal(4, b.getImportPrice());
                    ps.setString(5, b.getBatchNumber());
                    ps.setObject(6, b.getExpiryDate() != null ? Date.valueOf(b.getExpiryDate()) : null);
                    ps.setObject(7, b.getManufactureDate() != null ? Date.valueOf(b.getManufactureDate()) : null);
                    ps.addBatch();
                }
                ps.executeBatch();
            }
            // Hàng đã về ngay lúc tạo → nhập kho luôn
            if (receiveNow) {
                insertBatchesFromLines(cn, poId, po.getSupplierId(), lines);
            }
            cn.commit();
            return poId;
        } catch (Exception e) {
            e.printStackTrace();
            if (cn != null) try { cn.rollback(); } catch (Exception ignored) {}
            return -1;
        } finally {
            if (cn != null) try { cn.setAutoCommit(true); cn.close(); } catch (Exception ignored) {}
        }
    }

    private void insertBatchesFromLines(Connection cn, int poId, int supplierId, List<Batches> lines)
            throws SQLException {
        String checkSql = "SELECT BatchID FROM Batches WHERE MedicineID = ? AND BatchNumber = ? AND Status != 'CANCELLED'";
        String updateSql = "UPDATE Batches SET CurrentQuantity = CurrentQuantity + ?, InitialQuantity = InitialQuantity + ?, ImportPrice = ?, ImportDate = ?, Status = 'ACTIVE' WHERE BatchID = ?";
        String insertSql = "INSERT INTO Batches (MedicineID, POID, SupplierID, BatchNumber, " +
                "ManufactureDate, ImportDate, ExpiryDate, ImportPrice, InitialQuantity, CurrentQuantity) " +
                "VALUES (?,?,?,?,?,?,?,?,?,?)";
        try (PreparedStatement checkPs = cn.prepareStatement(checkSql);
             PreparedStatement updatePs = cn.prepareStatement(updateSql);
             PreparedStatement insertPs = cn.prepareStatement(insertSql)) {

            for (Batches b : lines) {
                String batchNo = b.getBatchNumber() != null && !b.getBatchNumber().isEmpty()
                        ? b.getBatchNumber() : ("PO" + poId + "-" + b.getMedicineId());

                checkPs.setInt(1, b.getMedicineId());
                checkPs.setString(2, batchNo);
                try (ResultSet rs = checkPs.executeQuery()) {
                    if (rs.next()) {
                        int batchId = rs.getInt("BatchID");
                        updatePs.setInt(1, b.getInitialQuantity());
                        updatePs.setInt(2, b.getInitialQuantity());
                        updatePs.setBigDecimal(3, b.getImportPrice());
                        updatePs.setDate(4, b.getImportDate() != null ? Date.valueOf(b.getImportDate()) : Date.valueOf(java.time.LocalDate.now()));
                        updatePs.setInt(5, batchId);
                        updatePs.executeUpdate();
                    } else {
                        insertPs.setInt(1, b.getMedicineId());
                        insertPs.setInt(2, poId);
                        insertPs.setInt(3, supplierId);
                        insertPs.setString(4, batchNo);
                        insertPs.setObject(5, b.getManufactureDate() != null ? Date.valueOf(b.getManufactureDate()) : null);
                        insertPs.setDate(6, b.getImportDate() != null ? Date.valueOf(b.getImportDate()) : Date.valueOf(java.time.LocalDate.now()));
                        insertPs.setDate(7, Date.valueOf(b.getExpiryDate()));
                        insertPs.setBigDecimal(8, b.getImportPrice());
                        insertPs.setInt(9, b.getInitialQuantity());
                        insertPs.setInt(10, b.getInitialQuantity());
                        insertPs.executeUpdate();
                    }
                }
            }
        }
    }

    /** Thêm 1 dòng chi tiết vào đơn (dùng khi gắn lô vào đơn ĐÃ CÓ, đơn để PENDING). */
    public boolean addDetail(int poId, Batches b) {
        String sql = "INSERT INTO PurchaseOrderDetails " +
                "(POID, MedicineID, Quantity, ImportPrice, BatchNumber, ExpiryDate, ManufactureDate) " +
                "VALUES (?,?,?,?,?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, poId);
            ps.setInt(2, b.getMedicineId());
            ps.setInt(3, b.getInitialQuantity());
            ps.setBigDecimal(4, b.getImportPrice());
            ps.setString(5, b.getBatchNumber());
            ps.setObject(6, b.getExpiryDate() != null ? Date.valueOf(b.getExpiryDate()) : null);
            ps.setObject(7, b.getManufactureDate() != null ? Date.valueOf(b.getManufactureDate()) : null);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Trạng thái 1 đơn (PENDING/COMPLETED) — null nếu không có. */
    public String getStatus(int poId) {
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement("SELECT Status FROM PurchaseOrders WHERE POID=?")) {
            ps.setInt(1, poId);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) return rs.getString(1); }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    /** Chi tiết dòng hàng của 1 phiếu (kèm tên thuốc để hiển thị). */
    public List<com.medicare.entity.PurchaseOrderDetail> findDetails(int poId) {
        List<com.medicare.entity.PurchaseOrderDetail> list = new ArrayList<>();
        String sql = "SELECT d.*, m.MedicineName FROM PurchaseOrderDetails d " +
                "JOIN Medicines m ON m.MedicineID = d.MedicineID WHERE d.POID = ? ORDER BY d.PODetailID";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, poId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    com.medicare.entity.PurchaseOrderDetail d = new com.medicare.entity.PurchaseOrderDetail();
                    d.setPoDetailId(rs.getInt("PODetailID"));
                    d.setPoId(rs.getInt("POID"));
                    d.setMedicineId(rs.getInt("MedicineID"));
                    d.setQuantity(rs.getInt("Quantity"));
                    d.setImportPrice(rs.getBigDecimal("ImportPrice"));
                    d.setBatchNumber(rs.getString("BatchNumber"));
                    if (rs.getDate("ExpiryDate") != null)      d.setExpiryDate(rs.getDate("ExpiryDate").toLocalDate());
                    if (rs.getDate("ManufactureDate") != null) d.setManufactureDate(rs.getDate("ManufactureDate").toLocalDate());
                    d.setMedicineName(rs.getString("MedicineName"));
                    list.add(d);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    /**
     * "Xác nhận hàng đã về" (Done) — TRIGGER nhập kho, chạy trong 1 TRANSACTION:
     *   1. Đọc toàn bộ PurchaseOrderDetails của đơn (chỉ khi đơn đang PENDING).
     *   2. INSERT INTO Batches cho từng dòng → tồn kho TĂNG tại đây.
     *   3. UPDATE PurchaseOrders SET Status='COMPLETED'.
     * Trả về số lô đã tạo, -1 nếu lỗi/đơn không ở trạng thái PENDING.
     */
    public int confirmReceived(int poId) {
        lastConfirmError.remove();
        Connection cn = null;
        try {
            cn = DBContext.getConnection();
            cn.setAutoCommit(false);

            // Khóa trạng thái: chỉ đơn PENDING mới được nhận (chống bấm Done 2 lần)
            int supplierId;
            try (PreparedStatement ps = cn.prepareStatement(
                    "SELECT SupplierID FROM PurchaseOrders WHERE POID = ? AND Status = 'PENDING'")) {
                ps.setInt(1, poId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        cn.rollback();
                        lastConfirmError.set("Đơn không tồn tại hoặc đã được xác nhận trước đó (không còn ở trạng thái Chờ xử lý).");
                        return -1;
                    }
                    supplierId = rs.getInt(1);
                }
            }

            // Đọc chi tiết dòng hàng
            List<Batches> lines = new ArrayList<>();
            try (PreparedStatement ps = cn.prepareStatement(
                    "SELECT * FROM PurchaseOrderDetails WHERE POID = ? ORDER BY PODetailID")) {
                ps.setInt(1, poId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        Batches b = new Batches();
                        b.setMedicineId(rs.getInt("MedicineID"));
                        b.setInitialQuantity(rs.getInt("Quantity"));
                        b.setImportPrice(rs.getBigDecimal("ImportPrice"));
                        b.setBatchNumber(rs.getString("BatchNumber"));
                        if (rs.getDate("ExpiryDate") != null) b.setExpiryDate(rs.getDate("ExpiryDate").toLocalDate());
                        if (rs.getDate("ManufactureDate") != null) b.setManufactureDate(rs.getDate("ManufactureDate").toLocalDate());
                        b.setImportDate(LocalDate.now()); // ngày nhập kho = ngày hàng về thật
                        lines.add(b);
                    }
                }
            }
            if (lines.isEmpty()) {
                cn.rollback();
                lastConfirmError.set("Đơn không có dòng hàng nào để nhập kho.");
                return -1;
            }

            // Kiểm tra trùng (MedicineID, BatchNumber) TRƯỚC khi insert — đơn PENDING này có thể
            // được tạo TRƯỚC khi validate trùng lô lúc lưu phiếu tồn tại (hoặc số lô đã bị 1 đơn
            // khác chiếm sau đó). Không kiểm tra trước, lỗi sẽ rơi thẳng vào UNIQUE KEY constraint
            // của SQL Server — vẫn đúng nhưng thông báo tiếng Anh khó hiểu với admin.
            try (PreparedStatement ps = cn.prepareStatement(
                    "SELECT TOP 1 BatchNumber FROM Batches WHERE MedicineID = ? AND BatchNumber = ? AND Status != 'CANCELLED'")) {
                for (Batches b : lines) {
                    ps.setInt(1, b.getMedicineId());
                    ps.setString(2, b.getBatchNumber());
                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            cn.rollback();
                            lastConfirmError.set("Số lô '" + b.getBatchNumber()
                                    + "' đã tồn tại trong kho cho thuốc này (MedicineID=" + b.getMedicineId()
                                    + ") — đổi số lô trên dòng hàng này trước khi xác nhận.");
                            return -1;
                        }
                    }
                }
            }

            insertBatchesFromLines(cn, poId, supplierId, lines);

            try (PreparedStatement ps = cn.prepareStatement(
                    "UPDATE PurchaseOrders SET Status = 'COMPLETED' WHERE POID = ?")) {
                ps.setInt(1, poId);
                ps.executeUpdate();
            }
            cn.commit();
            return lines.size();
        } catch (Exception e) {
            // QUAN TRỌNG: không nuốt lỗi — nếu DB có trigger chặn HSD cận date (RAISERROR),
            // lỗi đó rơi vào đây. Trước đây chỉ printStackTrace() rồi trả -1 chung chung,
            // khiến admin tưởng "nhập kho thất bại ngẫu nhiên" trong khi thực ra trigger đã
            // chặn đúng — nhưng cũng chặn LUÔN toàn bộ đơn (kể cả các dòng hợp lệ) vì cả đơn
            // chạy chung 1 transaction. Lộ rõ message thật để admin biết lô nào bị chặn và vì sao.
            String errMsg = e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName();
            lastConfirmError.set(errMsg);
            System.err.println("[PurchaseOrderDAO] confirmReceived thất bại (POID=" + poId + "): " + errMsg);
            e.printStackTrace();
            if (cn != null) try { cn.rollback(); } catch (Exception ignored) {}
            return -1;
        } finally {
            if (cn != null) try { cn.setAutoCommit(true); cn.close(); } catch (Exception ignored) {}
        }
    }

    @Override
    public int insert(PurchaseOrders po) {
        String sql = "INSERT INTO PurchaseOrders (SupplierID, AccountID, Notes) " +
                "VALUES (?,?,?); SELECT SCOPE_IDENTITY();";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, po.getSupplierId());
            ps.setInt(2, po.getAccountId());
            ps.setNString(3, po.getNotes());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return -1;
    }

    @Override
    public PurchaseOrders findById(int id) {
        String sql = "SELECT * FROM PurchaseOrders WHERE POID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    @Override
    public List<PurchaseOrders> findAll() {
        List<PurchaseOrders> list = new ArrayList<>();
        String sql = "SELECT * FROM PurchaseOrders ORDER BY OrderDate DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<PurchaseOrders> findRecent(int limit) {
        List<PurchaseOrders> list = new ArrayList<>();
        String sql = "SELECT TOP (?) * FROM PurchaseOrders ORDER BY OrderDate DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public int countBatches(int poId) {
        String sql = "SELECT COUNT(*) FROM Batches WHERE POID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, poId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    /** Map POID → tổng SL đã đặt (SUM Quantity từ PurchaseOrderDetails) — cột "SL đặt"/progress
     *  ở trang Đơn hàng (Warehouse). 1 query cho MỌI đơn, tránh N+1 khi render cả danh sách. */
    public Map<Integer, Integer> sumOrderedQtyMap() {
        Map<Integer, Integer> map = new HashMap<>();
        String sql = "SELECT POID, SUM(Quantity) AS Qty FROM PurchaseOrderDetails GROUP BY POID";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) map.put(rs.getInt("POID"), rs.getInt("Qty"));
        } catch (Exception e) { e.printStackTrace(); }
        return map;
    }

    /** Map POID → tổng SL đã THỰC SỰ nhập kho (SUM InitialQuantity từ Batches theo POID) —
     *  cột "SL đã nhận"/progress. Batches chỉ sinh ra lúc {@link #confirmReceived}, nên trước
     *  khi nhận sẽ không có dòng nào (map không chứa POID đó, coi như 0). */
    public Map<Integer, Integer> sumReceivedQtyMap() {
        Map<Integer, Integer> map = new HashMap<>();
        String sql = "SELECT POID, SUM(InitialQuantity) AS Qty FROM Batches WHERE POID IS NOT NULL GROUP BY POID";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) map.put(rs.getInt("POID"), rs.getInt("Qty"));
        } catch (Exception e) { e.printStackTrace(); }
        return map;
    }

    @Override
    public boolean recalcTotalValue(int poId) {
        String sql = "UPDATE PurchaseOrders SET TotalValue = (" +
                "  SELECT ISNULL(SUM(ImportPrice * InitialQuantity), 0) FROM Batches WHERE POID = ?" +
                ") WHERE POID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, poId);
            ps.setInt(2, poId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}