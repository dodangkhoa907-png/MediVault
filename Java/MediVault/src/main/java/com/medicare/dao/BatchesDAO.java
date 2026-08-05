package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IBatchesDAO;
import com.medicare.entity.Batches;
import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class BatchesDAO implements IBatchesDAO {

    private Batches mapRow(ResultSet rs) throws SQLException {
        Batches b = new Batches();
        b.setBatchId(rs.getInt("BatchID"));
        b.setMedicineId(rs.getInt("MedicineID"));
        b.setPoId(rs.getInt("POID"));
        b.setSupplierId(rs.getInt("SupplierID"));
        b.setBatchNumber(rs.getString("BatchNumber"));
        if (rs.getDate("ManufactureDate") != null)
            b.setManufactureDate(rs.getDate("ManufactureDate").toLocalDate());
        if (rs.getDate("ImportDate") != null)
            b.setImportDate(rs.getDate("ImportDate").toLocalDate());
        b.setExpiryDate(rs.getDate("ExpiryDate").toLocalDate());
        b.setImportPrice(rs.getBigDecimal("ImportPrice"));
        b.setInitialQuantity(rs.getInt("InitialQuantity"));
        b.setCurrentQuantity(rs.getInt("CurrentQuantity"));
        if (rs.getString("Status") != null)
            b.setStatus(rs.getString("Status"));
        if (rs.getTimestamp("CreatedAt") != null)
            b.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
        return b;
    }

    public List<Batches> findAll() {
        List<Batches> list = new ArrayList<>();
        String sql = "SELECT * FROM Batches WHERE Status = 'ACTIVE' ORDER BY ExpiryDate ASC";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next())
                list.add(mapRow(rs));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<Batches> findByMedicine(int medicineId) {
        List<Batches> list = new ArrayList<>();
        String sql = "SELECT * FROM Batches WHERE MedicineID = ? AND CurrentQuantity > 0 AND Status = 'ACTIVE' ORDER BY ExpiryDate ASC";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, medicineId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next())
                    list.add(mapRow(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    // Tất cả lô của 1 thuốc (trừ CANCELLED) — dùng cho trang quản lý lô
    public List<Batches> findAllByMedicine(int medicineId) {
        List<Batches> list = new ArrayList<>();
        String sql = "SELECT * FROM Batches WHERE MedicineID = ? AND Status != 'CANCELLED' ORDER BY ExpiryDate ASC";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, medicineId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next())
                    list.add(mapRow(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    // Các lô thuộc 1 đơn đặt hàng — dùng cho trang chi tiết Đơn đặt hàng
    public List<Batches> findByPO(int poId) {
        List<Batches> list = new ArrayList<>();
        String sql = "SELECT * FROM Batches WHERE POID = ? AND Status != 'CANCELLED' ORDER BY CreatedAt DESC";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, poId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next())
                    list.add(mapRow(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<Batches> findExpiringSoon() {
        List<Batches> list = new ArrayList<>();
        String sql = "SELECT * FROM Batches WHERE ExpiryDate >= CAST(GETDATE() AS DATE) AND ExpiryDate <= DATEADD(day, 30, GETDATE()) AND CurrentQuantity > 0 AND Status = 'ACTIVE' ORDER BY ExpiryDate ASC";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next())
                list.add(mapRow(rs));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public List<Batches> findExpired() {
        List<Batches> list = new ArrayList<>();
        String sql = "SELECT * FROM Batches WHERE ExpiryDate < CAST(GETDATE() AS DATE) AND CurrentQuantity > 0 AND Status = 'ACTIVE'";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next())
                list.add(mapRow(rs));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    public boolean insert(Batches b) {
        String checkSql = "SELECT BatchID FROM Batches WHERE MedicineID = ? AND BatchNumber = ? AND Status != 'CANCELLED'";
        String updateSql = "UPDATE Batches SET CurrentQuantity = CurrentQuantity + ?, InitialQuantity = InitialQuantity + ?, ImportPrice = ?, ImportDate = ?, Status = 'ACTIVE' WHERE BatchID = ?";
        String insertSql = "INSERT INTO Batches (MedicineID, POID, SupplierID, BatchNumber, " +
                "ManufactureDate, ImportDate, ExpiryDate, ImportPrice, InitialQuantity, CurrentQuantity) " +
                "VALUES (?,?,?,?,?,?,?,?,?,?)";
        try (Connection cn = DBContext.getConnection()) {
            try (PreparedStatement checkPs = cn.prepareStatement(checkSql)) {
                checkPs.setInt(1, b.getMedicineId());
                checkPs.setString(2, b.getBatchNumber());
                try (ResultSet rs = checkPs.executeQuery()) {
                    if (rs.next()) {
                        int batchId = rs.getInt("BatchID");
                        try (PreparedStatement upPs = cn.prepareStatement(updateSql)) {
                            upPs.setInt(1, b.getInitialQuantity());
                            upPs.setInt(2, b.getInitialQuantity());
                            upPs.setBigDecimal(3, b.getImportPrice());
                            upPs.setDate(4, b.getImportDate() != null ? Date.valueOf(b.getImportDate()) : Date.valueOf(java.time.LocalDate.now()));
                            upPs.setInt(5, batchId);
                            return upPs.executeUpdate() > 0;
                        }
                    }
                }
            }
            try (PreparedStatement ps = cn.prepareStatement(insertSql)) {
                ps.setInt(1, b.getMedicineId());
                if (b.getPoId() > 0) ps.setInt(2, b.getPoId()); else ps.setNull(2, Types.INTEGER);
                if (b.getSupplierId() > 0) ps.setInt(3, b.getSupplierId()); else ps.setNull(3, Types.INTEGER);
                ps.setString(4, b.getBatchNumber());
                if (b.getManufactureDate() != null) ps.setDate(5, Date.valueOf(b.getManufactureDate())); else ps.setNull(5, Types.DATE);
                ps.setDate(6, b.getImportDate() != null ? Date.valueOf(b.getImportDate()) : Date.valueOf(java.time.LocalDate.now()));
                ps.setDate(7, Date.valueOf(b.getExpiryDate()));
                ps.setBigDecimal(8, b.getImportPrice());
                ps.setInt(9, b.getInitialQuantity());
                ps.setInt(10, b.getInitialQuantity());
                return ps.executeUpdate() > 0;
            }
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /** Tổng tồn kho của 1 thuốc từ tất cả lô còn hàng */
    public int getTotalQuantity(int medicineId) {
        String sql = "SELECT ISNULL(SUM(CurrentQuantity),0) FROM Batches " +
                "WHERE MedicineID=? AND ExpiryDate > CAST(GETDATE() AS DATE) AND Status = 'ACTIVE'";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, medicineId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next())
                    return rs.getInt(1);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    /** Lô gần hết hạn nhất còn tồn kho (FEFO) */
    public Batches findNearestExpiry(int medicineId) {
        String sql = "SELECT TOP 1 * FROM Batches " +
                "WHERE MedicineID=? AND CurrentQuantity>0 AND Status = 'ACTIVE' " +
                "AND ExpiryDate > CAST(GETDATE() AS DATE) " +
                "ORDER BY ExpiryDate ASC";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, medicineId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next())
                    return mapRow(rs);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public Batches findById(int batchId) {
        String sql = "SELECT * FROM Batches WHERE BatchID = ?";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, batchId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next())
                    return mapRow(rs);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    /** Tìm lô theo thuốc + số lô — dùng để phát hiện lô trùng khi nhập nhanh */
    public Batches findByMedicineAndBatchNumber(int medicineId, String batchNumber) {
        String sql = "SELECT TOP 1 * FROM Batches WHERE MedicineID = ? AND BatchNumber = ? " +
                "AND Status != 'CANCELLED' ORDER BY CreatedAt DESC";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, medicineId);
            ps.setString(2, batchNumber);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next())
                    return mapRow(rs);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    /** Bổ sung hàng vào lô: +qty vào cả InitialQuantity lẫn CurrentQuantity */
    public boolean addStock(int batchId, int qty) {
        if (qty <= 0) return false;
        String sql = "UPDATE Batches SET InitialQuantity = InitialQuantity + ?, CurrentQuantity = CurrentQuantity + ? " +
                "WHERE BatchID = ? AND Status = 'ACTIVE'";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, qty);
            ps.setInt(2, qty);
            ps.setInt(3, batchId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /** Cập nhật lô — chỉ cho sửa số lô, ngày sản xuất, ngày hết hạn và giá nhập.
     *  ImportDate KHÔNG được sửa để bảo toàn lịch sử nhập hàng (GPP). */
    public boolean update(Batches b) {
        String sql = "UPDATE Batches SET BatchNumber=?, ManufactureDate=?, " +
                "ExpiryDate=?, ImportPrice=? WHERE BatchID=?";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, b.getBatchNumber());
            ps.setObject(2, b.getManufactureDate() != null ? Date.valueOf(b.getManufactureDate()) : null);
            ps.setDate(3, Date.valueOf(b.getExpiryDate()));
            ps.setBigDecimal(4, b.getImportPrice());
            ps.setInt(5, b.getBatchId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /** Hủy lô (CANCELLED) — chỉ khi chưa có bán hàng nào (CurrentQuantity = InitialQuantity) */
    public boolean delete(int batchId) {
        String sql = "UPDATE Batches SET Status = 'CANCELLED' WHERE BatchID = ? AND CurrentQuantity = InitialQuantity AND Status = 'ACTIVE'";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, batchId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /** Tiêu hủy lô (DESTROYED) — hết hạn / hỏng hóc, có thể còn tồn kho */
    public boolean destroyBatch(int batchId) {
        String sql = "UPDATE Batches SET Status = 'DESTROYED' WHERE BatchID = ? AND Status = 'ACTIVE'";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, batchId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /** Kiểm tra lô đã có lịch sử bán hàng (CurrentQuantity < InitialQuantity) */
    public boolean hasSalesHistory(int batchId) {
        String sql = "SELECT COUNT(*) FROM Batches WHERE BatchID = ? AND CurrentQuantity < InitialQuantity";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, batchId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1) > 0;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    /** Kiểm tra trùng số lô cho cùng thuốc + nhà cung cấp */
    public boolean existsBatchNumber(String batchNumber, int medicineId, int supplierId, int excludeBatchId) {
        String sql = "SELECT COUNT(*) FROM Batches WHERE BatchNumber = ? AND MedicineID = ? AND SupplierID = ? AND BatchID != ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, batchNumber);
            ps.setInt(2, medicineId);
            ps.setInt(3, supplierId);
            ps.setInt(4, excludeBatchId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1) > 0;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    /** Tổng tồn kho tất cả thuốc — 1 query thay N queries trong showList() */
    public Map<Integer, Integer> getTotalQuantityMap() {
        Map<Integer, Integer> map = new HashMap<>();
        String sql = "SELECT MedicineID, ISNULL(SUM(CurrentQuantity),0) AS TotalStock" +
                " FROM Batches WHERE ExpiryDate > CAST(GETDATE() AS DATE) AND Status = 'ACTIVE'" +
                " GROUP BY MedicineID";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next())
                map.put(rs.getInt("MedicineID"), rs.getInt("TotalStock"));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return map;
    }

    /**
     * Hạn dùng THỰC TẾ (số ngày) của từng thuốc — tính trung bình (ExpiryDate - ImportDate)
     * trên các lô ĐÃ TỪNG nhập trong quá khứ, không phải số tháng admin gõ tay. Dùng để đối
     * chiếu HSD khi tạo phiếu nhập mới (purchase-order-form.jsp): nếu thuốc X luôn có lô với
     * hạn dùng ~730 ngày kể từ ngày nhập, lô mới lệch nhiều khỏi con số đó → khả năng gõ nhầm.
     * Bỏ qua lô CANCELLED (không phản ánh hạn dùng thật của thuốc) và lô thiếu ImportDate.
     */
    public Map<Integer, Integer> getAvgShelfLifeDaysMap() {
        Map<Integer, Integer> map = new HashMap<>();
        String sql = "SELECT MedicineID, AVG(DATEDIFF(DAY, ImportDate, ExpiryDate)) AS AvgDays" +
                " FROM Batches" +
                " WHERE Status != 'CANCELLED' AND ImportDate IS NOT NULL AND ExpiryDate IS NOT NULL" +
                " GROUP BY MedicineID";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                int days = rs.getInt("AvgDays");
                if (days > 0) map.put(rs.getInt("MedicineID"), days);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return map;
    }

    /**
     * Giá nhập TRUNG BÌNH thực tế của từng thuốc — tính trên các lô ĐÃ TỪNG nhập trong quá khứ,
     * dùng để đối chiếu giá nhập khi tạo phiếu nhập mới (purchase-order-form.jsp), giống hệt cách
     * getAvgShelfLifeDaysMap() đối chiếu HSD: nếu thuốc X luôn nhập ~5.000đ mà lô mới gõ 50.000đ,
     * khả năng gõ nhầm số 0 hoặc sai đơn vị. Bỏ qua lô CANCELLED (không phản ánh giá nhập thật).
     */
    public Map<Integer, java.math.BigDecimal> getAvgImportPriceMap() {
        Map<Integer, java.math.BigDecimal> map = new HashMap<>();
        String sql = "SELECT MedicineID, AVG(ImportPrice) AS AvgPrice" +
                " FROM Batches" +
                " WHERE Status != 'CANCELLED' AND ImportPrice IS NOT NULL" +
                " GROUP BY MedicineID";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                java.math.BigDecimal avg = rs.getBigDecimal("AvgPrice");
                if (avg != null) map.put(rs.getInt("MedicineID"), avg);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return map;
    }

    /**
     * Lô nhập GẦN NHẤT của mỗi thuốc (theo ImportDate, hoà bằng CreatedAt) — dùng để gợi ý
     * "giá nhập lần trước" và "số lô gần nhất" trên wizard Nhập kho. Chỉ gợi ý, không ràng
     * buộc gì; ROW_NUMBER thay vì MAX(...) vì cần lấy CẢ BỘ (giá, số lô, ngày) của đúng 1 lô,
     * không phải trộn giá của lô này với số lô của lô khác.
     */
    public Map<Integer, Batches> getLatestBatchMap() {
        Map<Integer, Batches> map = new HashMap<>();
        // + SupplierID: cho phép wizard Nhập kho tự điền sẵn "Nhà cung cấp" theo lần nhập gần
        // nhất của đúng thuốc đó — khác với BatchNumber/ImportPrice/ngày tháng (đặc thù RIÊNG
        // của từng lô vật lý, tự điền sai là nguy hiểm), nhà cung cấp là thông tin ổn định
        // (ai thường bán thuốc này), tự điền sai chỉ cần đổi lại combo, không rủi ro dữ liệu.
        String sql = "SELECT MedicineID, SupplierID, BatchNumber, ImportPrice, ImportDate FROM (" +
                "  SELECT MedicineID, SupplierID, BatchNumber, ImportPrice, ImportDate," +
                "         ROW_NUMBER() OVER (PARTITION BY MedicineID ORDER BY ImportDate DESC, CreatedAt DESC) AS rn" +
                "  FROM Batches WHERE Status != 'CANCELLED'" +
                ") x WHERE rn = 1";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Batches b = new Batches();
                b.setSupplierId(rs.getInt("SupplierID"));
                b.setBatchNumber(rs.getString("BatchNumber"));
                b.setImportPrice(rs.getBigDecimal("ImportPrice"));
                if (rs.getDate("ImportDate") != null) b.setImportDate(rs.getDate("ImportDate").toLocalDate());
                map.put(rs.getInt("MedicineID"), b);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return map;
    }

    /** Tóm tắt lô cho tất cả thuốc trong 1 query — dùng cho medicine-list hover card + tab badges */
    public void loadBatchSummary(
            Map<Integer, Integer> activeCountOut,
            Map<Integer, Integer> soonCountOut,
            Map<Integer, Integer> expiredCountOut,
            Map<Integer, String>  nearestExpiryOut) {
        String sql =
            "SELECT MedicineID," +
            " COUNT(*) AS ac," +
            " SUM(CASE WHEN ExpiryDate > GETDATE() AND ExpiryDate <= DATEADD(DAY,90,GETDATE()) THEN 1 ELSE 0 END) AS sc," +
            " SUM(CASE WHEN ExpiryDate <= CAST(GETDATE() AS DATE) THEN 1 ELSE 0 END) AS ec," +
            " MIN(CASE WHEN ExpiryDate > CAST(GETDATE() AS DATE) THEN ExpiryDate ELSE NULL END) AS ne" +
            " FROM Batches WHERE Status='ACTIVE' GROUP BY MedicineID";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                int mid = rs.getInt("MedicineID");
                activeCountOut.put(mid, rs.getInt("ac"));
                soonCountOut.put(mid, rs.getInt("sc"));
                expiredCountOut.put(mid, rs.getInt("ec"));
                java.sql.Date ne = rs.getDate("ne");
                if (ne != null) nearestExpiryOut.put(mid, ne.toString());
            }
        } catch (Exception e) { e.printStackTrace(); }
    }

    /** Gói 4 map kết quả của loadBatchSummary() lại thành 1 object để cache chung được. */
    public static class BatchSummaryBundle {
        public final Map<Integer, Integer> activeCount;
        public final Map<Integer, Integer> soonCount;
        public final Map<Integer, Integer> expiredCount;
        public final Map<Integer, String>  nearestExpiry;
        public BatchSummaryBundle(Map<Integer, Integer> activeCount, Map<Integer, Integer> soonCount,
                                   Map<Integer, Integer> expiredCount, Map<Integer, String> nearestExpiry) {
            this.activeCount = activeCount;
            this.soonCount = soonCount;
            this.expiredCount = expiredCount;
            this.nearestExpiry = nearestExpiry;
        }
    }

    /**
     * Bản cache 30s của loadBatchSummary() — dùng CHUNG key "med.batchSummary" với cả trang
     * danh sách thuốc (MedicineServlet) lẫn kết nối SSE ban đầu (InventorySSEServlet), tránh
     * chạy lại query GROUP BY tốn kém này 2 lần liên tiếp mỗi khi vào trang Kho hàng — trang
     * gọi loadBatchSummary() 1 lần, rồi ngay sau đó SSE tự kết nối và gọi lại y hệt query đó
     * lần nữa nếu không cache chung. broadcast() sau khi bán hàng PHẢI invalidate key này
     * trước khi gọi lại, để không đẩy dữ liệu cũ.
     */
    public BatchSummaryBundle getCachedBatchSummary() {
        return com.medicare.config.CacheManager.getShort("med.batchSummary", () -> {
            Map<Integer, Integer> activeCount  = new HashMap<>();
            Map<Integer, Integer> soonCount    = new HashMap<>();
            Map<Integer, Integer> expiredCount = new HashMap<>();
            Map<Integer, String>  nearestExpiry = new HashMap<>();
            loadBatchSummary(activeCount, soonCount, expiredCount, nearestExpiry);
            return new BatchSummaryBundle(activeCount, soonCount, expiredCount, nearestExpiry);
        });
    }

    /** Tổng số lô theo thuốc */
    public int countByMedicine(int medicineId) {
        String sql = "SELECT COUNT(*) FROM Batches WHERE MedicineID = ?";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, medicineId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next())
                    return rs.getInt(1);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    @Override
    public boolean adjustQuantity(int batchId, int delta) {
        String sql = "UPDATE Batches SET CurrentQuantity = CurrentQuantity + ? " +
                "WHERE BatchID = ? AND CurrentQuantity + ? >= 0";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, delta);
            ps.setInt(2, batchId);
            ps.setInt(3, delta);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public boolean recallBatch(int batchId) {
        String sql = "UPDATE Batches SET Status = 'RECALLED' WHERE BatchID = ? AND Status = 'ACTIVE'";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, batchId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

}
