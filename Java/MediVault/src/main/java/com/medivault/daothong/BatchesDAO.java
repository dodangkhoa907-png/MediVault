package com.medivault.daothong;

import com.medivault.config.DBContext;
import com.medivault.entity.Batches;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class BatchesDAO extends DBContext {
    public List<Batches> getByMedicine(int medicineId) {
        List<Batches> list = new ArrayList<>();
        String sql = "SELECT * FROM Batches WHERE MedicineID = ? AND CurrentQuantity > 0 ORDER BY ExpiryDate ASC";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, medicineId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Batches b = new Batches();
                    b.setBatchId(rs.getInt("BatchID"));
                    b.setBatchNumber(rs.getString("BatchNumber"));
                    b.setExpiryDate(rs.getDate("ExpiryDate").toLocalDate());
                    b.setCurrentQuantity(rs.getInt("CurrentQuantity"));
                    b.setImportPrice(rs.getBigDecimal("ImportPrice"));
                    list.add(b);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }
}