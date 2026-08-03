package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IMedicineBarcodeDAO;
import com.medicare.entity.MedicineBarcode;
import com.medicare.entity.Medicines;
import com.medicare.util.MojibakeUtil;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class MedicineBarcodeDAO implements IMedicineBarcodeDAO {

    private MedicineBarcode mapRow(ResultSet rs) throws SQLException {
        MedicineBarcode b = new MedicineBarcode();
        b.setBarcodeId(rs.getInt("BarcodeID"));
        b.setMedicineId(rs.getInt("MedicineID"));
        b.setBarcode(rs.getString("Barcode"));
        b.setBarcodeType(rs.getString("BarcodeType"));
        b.setCreatedBy((Integer) rs.getObject("CreatedBy"));
        if (rs.getTimestamp("CreatedAt") != null) b.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
        if (rs.getTimestamp("LastScannedAt") != null) b.setLastScannedAt(rs.getTimestamp("LastScannedAt").toLocalDateTime());
        b.setScanCount(rs.getInt("ScanCount"));
        b.setLastSource(rs.getString("LastSource"));
        try {
            String uname = rs.getString("CreatedByName");
            if (uname != null) b.setCreatedByName(MojibakeUtil.fix(uname));
        } catch (SQLException ignored) {}
        return b;
    }

    @Override
    public Medicines findMedicineByAnyBarcode(String barcode) {
        if (barcode == null || barcode.trim().isEmpty()) return null;
        String sql = "SELECT MedicineID FROM MedicineBarcodes WHERE Barcode = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, barcode.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Medicines m = new MedicineDAO().findById(rs.getInt("MedicineID"));
                    return (m != null && m.isStatus()) ? m : null;
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    @Override
    public MedicineBarcode findByBarcode(String barcode) {
        String sql = "SELECT b.*, a.FullName AS CreatedByName FROM MedicineBarcodes b "
                + "LEFT JOIN Accounts a ON b.CreatedBy = a.AccountID WHERE b.Barcode = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, barcode);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    @Override
    public boolean existsForOtherMedicine(String barcode, int excludeMedicineId) {
        String sql = "SELECT 1 FROM MedicineBarcodes WHERE Barcode = ? AND MedicineID <> ? "
                + "UNION SELECT 1 FROM Medicines WHERE Barcode = ? AND MedicineID <> ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, barcode);
            ps.setInt(2, excludeMedicineId);
            ps.setString(3, barcode);
            ps.setInt(4, excludeMedicineId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (Exception e) { e.printStackTrace(); return true; } // lỗi DB → an toàn từ chối, không cho gán trùng
    }

    @Override
    public boolean insert(int medicineId, String barcode, String barcodeType, Integer createdBy, String source) {
        String sql = "INSERT INTO MedicineBarcodes (MedicineID, Barcode, BarcodeType, CreatedBy, LastSource, LastScannedAt, ScanCount) "
                + "VALUES (?, ?, ?, ?, ?, GETDATE(), 1)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, medicineId);
            ps.setString(2, barcode);
            ps.setString(3, barcodeType);
            if (createdBy != null) ps.setInt(4, createdBy); else ps.setNull(4, Types.INTEGER);
            ps.setString(5, source);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public void recordScan(int medicineId, String barcode, String source) {
        String update = "UPDATE MedicineBarcodes SET ScanCount = ScanCount + 1, LastScannedAt = GETDATE(), LastSource = ? WHERE Barcode = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(update)) {
            ps.setString(1, source);
            ps.setString(2, barcode);
            int updated = ps.executeUpdate();
            if (updated == 0) {
                // Quét trúng Medicines.Barcode "chính" nhưng chưa có dòng lịch sử — tự tạo (primary),
                // để lần sau trở đi tích luỹ ScanCount bình thường, không cần backfill migration riêng.
                insert(medicineId, barcode, "primary", null, source);
            }
        } catch (Exception e) { e.printStackTrace(); }
    }

    @Override
    public List<MedicineBarcode> findHistory(int medicineId) {
        List<MedicineBarcode> list = new ArrayList<>();
        String sql = "SELECT b.*, a.FullName AS CreatedByName FROM MedicineBarcodes b "
                + "LEFT JOIN Accounts a ON b.CreatedBy = a.AccountID WHERE b.MedicineID = ? ORDER BY b.CreatedAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, medicineId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }
}
