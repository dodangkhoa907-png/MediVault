package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IMedicineDAO;
import com.medicare.entity.Medicines;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class MedicineDAO implements IMedicineDAO {

    private Medicines mapRow(ResultSet rs) throws SQLException {
        Medicines m = new Medicines();
        m.setMedicineId(rs.getInt("MedicineID"));
        m.setMedicineCode(rs.getString("MedicineCode"));
        m.setMedicineName(rs.getNString("MedicineName"));
        m.setGenericName(rs.getNString("GenericName"));
        m.setBarcode(rs.getString("Barcode"));
        m.setRegistrationNumber(rs.getString("RegistrationNumber"));
        m.setCategoryId(rs.getInt("CategoryID"));
        m.setManufacturerId(rs.getInt("ManufacturerID"));
        m.setUnit(rs.getNString("Unit"));
        m.setShelfId(rs.getInt("ShelfID"));
        m.setDosage(rs.getNString("Dosage"));
        m.setContraindications(rs.getNString("Contraindications"));
        m.setPrescriptionRequired(rs.getBoolean("IsPrescriptionRequired"));
        m.setSellingPrice(rs.getBigDecimal("SellingPrice"));
        m.setMinInventory(rs.getInt("MinInventory"));
        m.setStatus(rs.getBoolean("Status"));
        m.setExpiryAlertDays(rs.getInt("ExpiryAlertDays"));
        if (rs.getTimestamp("CreatedAt") != null)
            m.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
        return m;
    }

    public List<Medicines> findAll() {
        List<Medicines> list = new ArrayList<>();
        String sql = "SELECT * FROM Medicines WHERE Status = 1 ORDER BY MedicineName";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public Medicines findById(int id) {
        String sql = "SELECT * FROM Medicines WHERE MedicineID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    public Medicines findByBarcode(String barcode) {
        String sql = "SELECT * FROM Medicines WHERE Barcode = ? AND Status = 1";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, barcode);
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
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    // Thuốc sắp hết hàng (CurrentQuantity <= MinInventory)
    public List<Medicines> findLowStock() {
        List<Medicines> list = new ArrayList<>();
        String sql = "SELECT m.* FROM Medicines m " +
                "LEFT JOIN (SELECT MedicineID, SUM(CurrentQuantity) AS TotalQty " +
                "           FROM Batches GROUP BY MedicineID) b ON m.MedicineID = b.MedicineID " +
                "WHERE m.Status = 1 AND ISNULL(b.TotalQty, 0) <= m.MinInventory " +
                "ORDER BY ISNULL(b.TotalQty, 0) ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public int countAll() {
        String sql = "SELECT COUNT(*) FROM Medicines WHERE Status = 1";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    public int countLowStock() {
        String sql = "SELECT COUNT(*) FROM Medicines m " +
                "LEFT JOIN (SELECT MedicineID, SUM(CurrentQuantity) AS TotalQty " +
                "           FROM Batches GROUP BY MedicineID) b ON m.MedicineID = b.MedicineID " +
                "WHERE m.Status = 1 AND ISNULL(b.TotalQty, 0) <= m.MinInventory";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    public boolean insert(Medicines m) {
        String sql = "INSERT INTO Medicines (MedicineName, GenericName, Barcode, RegistrationNumber, " +
                "CategoryID, ManufacturerID, Unit, ShelfID, Dosage, Contraindications, " +
                "IsPrescriptionRequired, SellingPrice, MinInventory, ExpiryAlertDays) " +
                "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, m.getMedicineName());
            ps.setNString(2, m.getGenericName());
            ps.setString(3, m.getBarcode());
            ps.setString(4, m.getRegistrationNumber());
            ps.setInt(5, m.getCategoryId());
            ps.setInt(6, m.getManufacturerId());
            ps.setNString(7, m.getUnit());
            ps.setInt(8, m.getShelfId());
            ps.setNString(9, m.getDosage());
            ps.setNString(10, m.getContraindications());
            ps.setBoolean(11, m.isPrescriptionRequired());
            ps.setBigDecimal(12, m.getSellingPrice());
            ps.setInt(13, m.getMinInventory());
            ps.setInt(14, m.getExpiryAlertDays());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    public boolean update(Medicines m) {
        String sql = "UPDATE Medicines SET MedicineName=?, GenericName=?, Barcode=?, " +
                "RegistrationNumber=?, CategoryID=?, ManufacturerID=?, Unit=?, ShelfID=?, " +
                "Dosage=?, Contraindications=?, IsPrescriptionRequired=?, " +
                "SellingPrice=?, MinInventory=?, ExpiryAlertDays=? WHERE MedicineID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, m.getMedicineName());
            ps.setNString(2, m.getGenericName());
            ps.setString(3, m.getBarcode());
            ps.setString(4, m.getRegistrationNumber());
            ps.setInt(5, m.getCategoryId());
            ps.setInt(6, m.getManufacturerId());
            ps.setNString(7, m.getUnit());
            ps.setInt(8, m.getShelfId());
            ps.setNString(9, m.getDosage());
            ps.setNString(10, m.getContraindications());
            ps.setBoolean(11, m.isPrescriptionRequired());
            ps.setBigDecimal(12, m.getSellingPrice());
            ps.setInt(13, m.getMinInventory());
            ps.setInt(14, m.getExpiryAlertDays());
            ps.setInt(15, m.getMedicineId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // Xóa mềm — chỉ set Status = 0, không xóa thật
    public boolean delete(int id) {
        String sql = "UPDATE Medicines SET Status = 0 WHERE MedicineID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // Lấy tất cả kể cả đã ẩn — dùng cho trang quản lý kho
    public List<Medicines> findAllIncludeInactive() {
        List<Medicines> list = new ArrayList<>();
        String sql = "SELECT * FROM Medicines ORDER BY Status DESC, MedicineName";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    // Toggle Status 0 ↔ 1
    public boolean toggleStatus(int id) {
        String sql = "UPDATE Medicines SET Status = 1 - Status WHERE MedicineID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}