package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IMedicineDAO;
import com.medicare.entity.Medicines;
import com.medicare.util.MojibakeUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class MedicineDAO implements IMedicineDAO {

    private Medicines mapRow(ResultSet rs) throws SQLException {
        Medicines m = new Medicines();
        m.setMedicineId(rs.getInt("MedicineID"));
        m.setMedicineCode(rs.getString("MedicineCode"));
        m.setMedicineName(MojibakeUtil.fix(rs.getString("MedicineName")));
        m.setGenericName(MojibakeUtil.fix(rs.getString("GenericName")));
        m.setBarcode(rs.getString("Barcode"));
        m.setRegistrationNumber(rs.getString("RegistrationNumber"));
        m.setCategoryId(rs.getInt("CategoryID"));
        m.setManufacturerId(rs.getInt("ManufacturerID"));
        m.setUnit(MojibakeUtil.fix(rs.getString("Unit")));
        m.setShelfId(rs.getInt("ShelfID"));
        m.setDosage(MojibakeUtil.fix(rs.getString("Dosage")));
        m.setContraindications(MojibakeUtil.fix(rs.getString("Contraindications")));
        m.setPrescriptionRequired(rs.getBoolean("IsPrescriptionRequired"));
        m.setSellingPrice(rs.getBigDecimal("SellingPrice"));
        m.setMinInventory(rs.getInt("MinInventory"));
        m.setStorageConditions(MojibakeUtil.fix(rs.getString("StorageConditions")));
        m.setStatus(rs.getBoolean("Status"));
        m.setExpiryAlertDays(rs.getInt("ExpiryAlertDays"));
        try { m.setShelfLifeMonths((Integer) rs.getObject("ShelfLifeMonths")); } catch (Exception ignored) {}
        if (rs.getTimestamp("CreatedAt") != null)
            m.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
        try { m.setPackagingSpec(rs.getString("PackagingSpec")); } catch (Exception ignored) {}
        try { m.setImageUrl(rs.getString("ImageUrl")); } catch (Exception ignored) {}
        return m;
    }

    public List<Medicines> findAll() {
        List<Medicines> list = new ArrayList<>();
        String sql = "SELECT * FROM Medicines WHERE Status = 1 ORDER BY MedicineName";
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

    public Medicines findById(int id) {
        String sql = "SELECT * FROM Medicines WHERE MedicineID = ?";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next())
                    return mapRow(rs);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public Medicines findByBarcode(String barcode) {
        String sql = "SELECT * FROM Medicines WHERE Barcode = ? AND Status = 1";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, barcode);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next())
                    return mapRow(rs);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    /**
     * Bắt TRÙNG khi tạo thuốc mới: khớp Barcode HOẶC Số đăng ký HOẶC trùng
     * chính xác tên thuốc (không phân biệt hoa thường). Trả thuốc đã tồn tại
     * để servlet gợi ý "Nhập lô mới cho thuốc này?", hoặc null nếu không trùng.
     */
    public Medicines findDuplicate(String barcode, String registrationNo, String name) {
        boolean hasBarcode = barcode != null && !barcode.trim().isEmpty();
        boolean hasReg     = registrationNo != null && !registrationNo.trim().isEmpty();
        boolean hasName    = name != null && !name.trim().isEmpty();
        if (!hasBarcode && !hasReg && !hasName) return null;

        StringBuilder sql = new StringBuilder("SELECT TOP 1 * FROM Medicines WHERE (");
        List<String> conds = new ArrayList<>();
        if (hasBarcode) conds.add("Barcode = ?");
        if (hasReg)     conds.add("RegistrationNumber = ?");
        if (hasName)    conds.add("LOWER(MedicineName) = LOWER(?)");
        sql.append(String.join(" OR ", conds)).append(")");

        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql.toString())) {
            int i = 1;
            if (hasBarcode) ps.setString(i++, barcode.trim());
            if (hasReg)     ps.setNString(i++, registrationNo.trim());
            if (hasName)    ps.setNString(i++, name.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    // Tìm kiếm theo tên hoặc barcode — dùng cho màn hình bán hàng
    public List<Medicines> search(String keyword) {
        List<Medicines> list = new ArrayList<>();
        String sql = "SELECT * FROM Medicines WHERE Status = 1 AND " +
                "(MedicineName LIKE ? OR GenericName LIKE ? OR Barcode LIKE ? OR MedicineCode LIKE ?) " +
                "ORDER BY MedicineName";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql)) {
            String kw = "%" + keyword + "%";
            ps.setNString(1, kw);
            ps.setNString(2, kw);
            ps.setString(3, kw);
            ps.setString(4, kw);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next())
                    list.add(mapRow(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    // Thuốc sắp hết hàng (CurrentQuantity <= MinInventory)
    public List<Medicines> findLowStock() {
        List<Medicines> list = new ArrayList<>();
        String sql = "SELECT m.* FROM Medicines m " +
                "LEFT JOIN (SELECT MedicineID, SUM(CurrentQuantity) AS TotalQty " +
                "           FROM Batches GROUP BY MedicineID) b ON m.MedicineID = b.MedicineID " +
                "WHERE m.Status = 1 AND ISNULL(b.TotalQty, 0) > 0 " +
                "  AND ISNULL(b.TotalQty, 0) <= m.MinInventory AND m.MinInventory > 0 " +
                "ORDER BY ISNULL(b.TotalQty, 0) ASC";
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

    public int countAll() {
        String sql = "SELECT COUNT(*) FROM Medicines WHERE Status = 1";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            if (rs.next())
                return rs.getInt(1);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    public int countLowStock() {
        String sql = "SELECT COUNT(*) FROM Medicines m " +
                "LEFT JOIN (SELECT MedicineID, SUM(CurrentQuantity) AS TotalQty " +
                "           FROM Batches GROUP BY MedicineID) b ON m.MedicineID = b.MedicineID " +
                "WHERE m.Status = 1 AND ISNULL(b.TotalQty, 0) > 0 " +
                "  AND ISNULL(b.TotalQty, 0) <= m.MinInventory AND m.MinInventory > 0";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            if (rs.next())
                return rs.getInt(1);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    /** setInt an toàn cho cột Integer nullable (ShelfID nullable; Category/Manufacturer
     *  NOT NULL nhưng nếu null thì để DB báo lỗi rõ thay vì NPE khi unbox). */
    private static void setIntOrNull(PreparedStatement ps, int idx, Integer val) throws java.sql.SQLException {
        if (val == null) ps.setNull(idx, java.sql.Types.INTEGER);
        else ps.setInt(idx, val);
    }

    public boolean insert(Medicines m) {
        String sql = "INSERT INTO Medicines (MedicineName, GenericName, Barcode, RegistrationNumber, " +
                "CategoryID, ManufacturerID, Unit, ShelfID, Dosage, Contraindications, " +
                "StorageConditions, IsPrescriptionRequired, SellingPrice, MinInventory, ExpiryAlertDays, " +
                "PackagingSpec, ShelfLifeMonths) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, m.getMedicineName());
            ps.setNString(2, m.getGenericName());
            ps.setString(3, m.getBarcode());
            ps.setString(4, m.getRegistrationNumber());
            setIntOrNull(ps, 5, m.getCategoryId());
            setIntOrNull(ps, 6, m.getManufacturerId());
            ps.setNString(7, m.getUnit());
            setIntOrNull(ps, 8, m.getShelfId());
            ps.setNString(9, m.getDosage());
            ps.setNString(10, m.getContraindications());
            ps.setNString(11, m.getStorageConditions());
            ps.setBoolean(12, m.isPrescriptionRequired());
            ps.setBigDecimal(13, m.getSellingPrice());
            ps.setInt(14, m.getMinInventory());
            ps.setInt(15, m.getExpiryAlertDays());
            ps.setNString(16, m.getPackagingSpec());
            setIntOrNull(ps, 17, m.getShelfLifeMonths());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public int insertGetId(Medicines m) {
        String sql = "INSERT INTO Medicines (MedicineName, GenericName, Barcode, RegistrationNumber, " +
                "CategoryID, ManufacturerID, Unit, ShelfID, Dosage, Contraindications, " +
                "StorageConditions, IsPrescriptionRequired, SellingPrice, MinInventory, ExpiryAlertDays, " +
                "PackagingSpec, ShelfLifeMonths) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setNString(1, m.getMedicineName());
            ps.setNString(2, m.getGenericName());
            ps.setString(3, m.getBarcode());
            ps.setString(4, m.getRegistrationNumber());
            setIntOrNull(ps, 5, m.getCategoryId());
            setIntOrNull(ps, 6, m.getManufacturerId());
            ps.setNString(7, m.getUnit());
            setIntOrNull(ps, 8, m.getShelfId());
            ps.setNString(9, m.getDosage());
            ps.setNString(10, m.getContraindications());
            ps.setNString(11, m.getStorageConditions());
            ps.setBoolean(12, m.isPrescriptionRequired());
            ps.setBigDecimal(13, m.getSellingPrice());
            ps.setInt(14, m.getMinInventory());
            ps.setInt(15, m.getExpiryAlertDays());
            ps.setNString(16, m.getPackagingSpec());
            setIntOrNull(ps, 17, m.getShelfLifeMonths());
            if (ps.executeUpdate() > 0) {
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (keys.next()) return keys.getInt(1);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return -1;
    }

    public boolean update(Medicines m) {
        String sql = "UPDATE Medicines SET MedicineName=?, GenericName=?, Barcode=?, " +
                "RegistrationNumber=?, CategoryID=?, ManufacturerID=?, Unit=?, ShelfID=?, " +
                "Dosage=?, Contraindications=?, StorageConditions=?, IsPrescriptionRequired=?, " +
                "SellingPrice=?, MinInventory=?, ExpiryAlertDays=?, PackagingSpec=?, ImageUrl=?, " +
                "ShelfLifeMonths=? " +
                "WHERE MedicineID=?";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, m.getMedicineName());
            ps.setNString(2, m.getGenericName());
            ps.setString(3, m.getBarcode());
            ps.setString(4, m.getRegistrationNumber());
            setIntOrNull(ps, 5, m.getCategoryId());
            setIntOrNull(ps, 6, m.getManufacturerId());
            ps.setNString(7, m.getUnit());
            setIntOrNull(ps, 8, m.getShelfId());
            ps.setNString(9, m.getDosage());
            ps.setNString(10, m.getContraindications());
            ps.setNString(11, m.getStorageConditions());
            ps.setBoolean(12, m.isPrescriptionRequired());
            ps.setBigDecimal(13, m.getSellingPrice());
            ps.setInt(14, m.getMinInventory());
            ps.setInt(15, m.getExpiryAlertDays());
            ps.setNString(16, m.getPackagingSpec());
            ps.setString(17, m.getImageUrl());
            setIntOrNull(ps, 18, m.getShelfLifeMonths());
            ps.setInt(19, m.getMedicineId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public boolean updateImageUrl(int medicineId, String imageUrl) {
        String sql = "UPDATE Medicines SET ImageUrl = ? WHERE MedicineID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, imageUrl);
            ps.setInt(2, medicineId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    /** Cập nhật chỉ vị trí kệ — dùng khi người dùng thay đổi kệ từ form lô hàng */
    public boolean updateShelf(int medicineId, int shelfId) {
        String sql = "UPDATE Medicines SET ShelfID = ? WHERE MedicineID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, shelfId);
            ps.setInt(2, medicineId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // Xóa mềm — chỉ set Status = 0, không xóa thật
    public boolean delete(int id) {
        String sql = "UPDATE Medicines SET Status = 0 WHERE MedicineID = ?";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // Lấy tất cả kể cả đã ẩn — dùng cho trang quản lý kho
    public List<Medicines> findAllIncludeInactive() {
        List<Medicines> list = new ArrayList<>();
        String sql = "SELECT * FROM Medicines ORDER BY Status DESC, MedicineName";
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

    // Toggle Status 0 ↔ 1
    public boolean toggleStatus(int id) {
        String sql = "UPDATE Medicines SET Status = 1 - Status WHERE MedicineID = ?";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // ── Single-query methods replacing N+1 patterns ──────────────────────────

    private static final String STOCK_CTE = "WITH bs AS (" +
            "  SELECT MedicineID, SUM(CurrentQuantity) AS TotalStock" +
            "  FROM Batches WHERE ExpiryDate > CAST(GETDATE() AS DATE)" +
            "  GROUP BY MedicineID" +
            ")," +
            "nb AS (" +
            "  SELECT MedicineID, ExpiryDate AS NearestExpiry, BatchNumber AS NearestBatchNo," +
            "         ROW_NUMBER() OVER (PARTITION BY MedicineID ORDER BY ExpiryDate ASC) AS rn" +
            "  FROM Batches" +
            "  WHERE CurrentQuantity > 0 AND ExpiryDate > CAST(GETDATE() AS DATE)" +
            ") ";

    private Medicines mapRowWithStock(ResultSet rs) throws SQLException {
        Medicines m = mapRow(rs);
        m.setTotalStock(rs.getInt("TotalStock"));
        String exp = rs.getString("NearestExpiry");
        m.setNearestExpiry(exp != null ? exp : "");
        String bn = rs.getString("NearestBatchNo");
        m.setNearestBatchNo(bn != null ? bn : "");
        return m;
    }

    /** Tìm kiếm có tổng tồn kho + lô gần hết hạn — 1 query thay vì N+1. */
    public List<Medicines> searchWithStock(String keyword) {
        List<Medicines> list = new ArrayList<>();
        String sql = STOCK_CTE +
                "SELECT m.*, ISNULL(bs.TotalStock,0) AS TotalStock," +
                "  CONVERT(VARCHAR(10), nb.NearestExpiry, 120) AS NearestExpiry," +
                "  nb.NearestBatchNo" +
                " FROM Medicines m" +
                " LEFT JOIN bs ON bs.MedicineID = m.MedicineID" +
                " LEFT JOIN nb ON nb.MedicineID = m.MedicineID AND nb.rn = 1" +
                " WHERE m.Status = 1" +
                "  AND (m.MedicineName LIKE ? OR m.GenericName LIKE ? OR m.Barcode LIKE ? OR m.MedicineCode LIKE ?)" +
                " ORDER BY m.MedicineName";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql)) {
            String kw = "%" + keyword + "%";
            ps.setNString(1, kw);
            ps.setNString(2, kw);
            ps.setString(3, kw);
            ps.setString(4, kw);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next())
                    list.add(mapRowWithStock(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    /**
     * Phân trang danh sách thuốc cho trang quản lý kho.
     * Hỗ trợ lọc theo keyword (tên/code/barcode) và danh mục.
     * Dùng OFFSET...FETCH NEXT của SQL Server — không load toàn bộ bảng.
     *
     * @param keyword  từ khóa tìm kiếm (null/empty = không lọc)
     * @param catId    ID danh mục (null = không lọc)
     * @param page     trang bắt đầu từ 1
     * @param pageSize số bản ghi mỗi trang
     */
    public List<Medicines> findPaged(String keyword, Integer catId, int page, int pageSize) {
        List<Medicines> list = new ArrayList<>();
        boolean hasKeyword = keyword != null && !keyword.trim().isEmpty();
        boolean hasCat = catId != null;

        StringBuilder sql = new StringBuilder(
                "SELECT * FROM Medicines WHERE 1=1");
        if (hasKeyword)
            sql.append(
                    " AND (MedicineName LIKE ? OR GenericName LIKE ? OR MedicineCode LIKE ? OR Barcode LIKE ?)");
        if (hasCat)
            sql.append(" AND CategoryID = ?");
        sql.append(" ORDER BY Status DESC, MedicineName");
        sql.append(" OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");

        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql.toString())) {
            int idx = 1;
            if (hasKeyword) {
                String kw = "%" + keyword.trim() + "%";
                ps.setNString(idx++, kw);
                ps.setNString(idx++, kw);
                ps.setString(idx++, kw);
                ps.setString(idx++, kw);
            }
            if (hasCat)
                ps.setInt(idx++, catId);
            ps.setInt(idx++, (page - 1) * pageSize);
            ps.setInt(idx, pageSize);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next())
                    list.add(mapRow(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    /**
     * Đếm tổng số thuốc thỏa điều kiện — dùng kết hợp với findPaged().
     */
    public int countForList(String keyword, Integer catId) {
        boolean hasKeyword = keyword != null && !keyword.trim().isEmpty();
        boolean hasCat = catId != null;

        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM Medicines WHERE 1=1");
        if (hasKeyword)
            sql.append(
                    " AND (MedicineName LIKE ? OR GenericName LIKE ? OR MedicineCode LIKE ? OR Barcode LIKE ?)");
        if (hasCat)
            sql.append(" AND CategoryID = ?");

        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql.toString())) {
            int idx = 1;
            if (hasKeyword) {
                String kw = "%" + keyword.trim() + "%";
                ps.setNString(idx++, kw);
                ps.setNString(idx++, kw);
                ps.setString(idx++, kw);
                ps.setString(idx++, kw);
            }
            if (hasCat)
                ps.setInt(idx, catId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next())
                    return rs.getInt(1);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return 0;
    }

    /** Tất cả thuốc active + tồn kho — 1 query thay vì N+1. */
    public List<Medicines> findAllWithStock() {
        List<Medicines> list = new ArrayList<>();
        String sql = STOCK_CTE +
                "SELECT m.*, ISNULL(bs.TotalStock,0) AS TotalStock," +
                "  CONVERT(VARCHAR(10), nb.NearestExpiry, 120) AS NearestExpiry," +
                "  nb.NearestBatchNo" +
                " FROM Medicines m" +
                " LEFT JOIN bs ON bs.MedicineID = m.MedicineID" +
                " LEFT JOIN nb ON nb.MedicineID = m.MedicineID AND nb.rn = 1" +
                " WHERE m.Status = 1" +
                " ORDER BY m.MedicineName";
        try (Connection cn = DBContext.getConnection();
                PreparedStatement ps = cn.prepareStatement(sql);
                ResultSet rs = ps.executeQuery()) {
            while (rs.next())
                list.add(mapRowWithStock(rs));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }
}