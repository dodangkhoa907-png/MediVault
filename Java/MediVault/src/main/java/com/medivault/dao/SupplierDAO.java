package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.entity.Supplier;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class SupplierDAO extends DBContext {
    public List<Supplier> getAllActive() {
        List<Supplier> list = new ArrayList<>();
        String sql = "SELECT * FROM Suppliers WHERE IsActive = 1";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Supplier s = new Supplier();
                s.setSupplierId(rs.getInt("SupplierID"));
                s.setSupplierName(rs.getNString("SupplierName"));
                s.setContactName(rs.getNString("ContactName"));
                s.setPhone(rs.getString("Phone"));
                s.setEmail(rs.getString("Email"));
                s.setAddress(rs.getNString("Address")); // Bổ sung địa chỉ
                s.setLicenseNumber(rs.getString("LicenseNumber")); // Bổ sung GPKD
                s.setActive(rs.getBoolean("IsActive"));
                list.add(s);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }
}