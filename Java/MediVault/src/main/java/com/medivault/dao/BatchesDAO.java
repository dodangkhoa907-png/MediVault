package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.dao.interfaces.IBatchesDAO;
import com.medivault.entity.Batches;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class BatchesDAO implements IBatchesDAO {

    private Batches mapRow(ResultSet rs) throws SQLException {
        Batches b = new Batches();
        b.setBatchId(rs.getInt("BatchID"));
        b.setMedicineId(rs.getInt("MedicineID"));
        b.setBatchNumber(rs.getString("BatchNumber"));
        if (rs.getDate("ManufactureDate") != null)
            b.setManufactureDate(rs.getDate("ManufactureDate").toLocalDate());
        if (rs.getDate("ImportDate") != null)
            b.setImportDate(rs.getDate("ImportDate").toLocalDate());
        b.setExpiryDate(rs.getDate("ExpiryDate").toLocalDate());
        b.setImportPrice(rs.getBigDecimal("ImportPrice"));
        b.setInitialQuantity(rs.getInt("InitialQuantity"));
        b.setCurrentQuantity(rs.getInt("CurrentQuantity"));
        return b;
    }

    public List<Batches> findAll() {
        List<Batches> list = new ArrayList<>();
        String sql = "SELECT * FROM Batches ORDER BY ExpiryDate ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public List<Batches> findByMedicine(int medicineId) {
        List<Batches> list = new ArrayList<>();
        String sql = "SELECT * FROM Batches WHERE MedicineID = ? AND CurrentQuantity > 0 ORDER BY ExpiryDate ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, medicineId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public List<Batches> findExpiringSoon() {
        List<Batches> list = new ArrayList<>();
        String sql = "SELECT * FROM Batches WHERE ExpiryDate <= DATEADD(day, 30, GETDATE()) AND CurrentQuantity > 0 ORDER BY ExpiryDate ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public List<Batches> findExpired() {
        List<Batches> list = new ArrayList<>();
        String sql = "SELECT * FROM Batches WHERE ExpiryDate < CAST(GETDATE() AS DATE) AND CurrentQuantity > 0";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public boolean insert(Batches b) {
        String sql = "INSERT INTO Batches (MedicineID, POID, SupplierID, BatchNumber, " +
                "ManufactureDate, ImportDate, ExpiryDate, ImportPrice, InitialQuantity, CurrentQuantity) " +
                "VALUES (?,?,?,?,?,?,?,?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, b.getMedicineId());
            ps.setObject(2, b.getPoId());
            ps.setObject(3, b.getSupplierId());
            ps.setString(4, b.getBatchNumber());
            ps.setObject(5, b.getManufactureDate() != null ? Date.valueOf(b.getManufactureDate()) : null);
            ps.setDate(6, b.getImportDate() != null ? Date.valueOf(b.getImportDate()) : Date.valueOf(java.time.LocalDate.now()));
            ps.setDate(7, Date.valueOf(b.getExpiryDate()));
            ps.setBigDecimal(8, b.getImportPrice());
            ps.setInt(9, b.getInitialQuantity());
            ps.setInt(10, b.getInitialQuantity());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}