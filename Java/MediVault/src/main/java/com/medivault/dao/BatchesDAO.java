package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.entity.Batches;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class BatchesDAO extends DBContext {
    public List<Batches> getExpiringBatches() {
        List<Batches> list = new ArrayList<>();
        String sql = "SELECT * FROM Batches WHERE ExpiryDate <= DATEADD(day, 30, GETDATE()) AND CurrentQuantity > 0";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Batches b = new Batches();
                b.setBatchId(rs.getInt("BatchID"));
                b.setMedicineId(rs.getInt("MedicineID"));
                b.setBatchNumber(rs.getString("BatchNumber"));
                // Sửa/Bổ sung:
                b.setManufactureDate(rs.getDate("ManufactureDate").toLocalDate());
                b.setImportDate(rs.getDate("ImportDate").toLocalDate());
                b.setExpiryDate(rs.getDate("ExpiryDate").toLocalDate());
                b.setImportPrice(rs.getBigDecimal("ImportPrice"));
                b.setInitialQuantity(rs.getInt("InitialQuantity"));
                b.setCurrentQuantity(rs.getInt("CurrentQuantity"));
                list.add(b);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }
}