package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.entity.Supplier;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class SupplierDAO {

    private Supplier mapRow(ResultSet rs) throws SQLException {
        Supplier s = new Supplier();
        s.setSupplierId(rs.getInt("SupplierID"));
        s.setSupplierName(rs.getNString("SupplierName"));
        s.setContactName(rs.getNString("ContactName"));
        s.setPhone(rs.getString("Phone"));
        s.setEmail(rs.getString("Email"));
        s.setAddress(rs.getNString("Address"));
        s.setLicenseNumber(rs.getString("LicenseNumber"));
        s.setActive(rs.getBoolean("IsActive"));
        return s;
    }

    public List<Supplier> findAll() {
        List<Supplier> list = new ArrayList<>();
        String sql = "SELECT * FROM Suppliers ORDER BY SupplierName";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public List<Supplier> findAllActive() {
        List<Supplier> list = new ArrayList<>();
        String sql = "SELECT * FROM Suppliers WHERE IsActive = 1 ORDER BY SupplierName";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public Supplier findById(int id) {
        String sql = "SELECT * FROM Suppliers WHERE SupplierID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    public boolean insert(Supplier s) {
        String sql = "INSERT INTO Suppliers (SupplierName, ContactName, Phone, Email, Address, LicenseNumber) " +
                "VALUES (?,?,?,?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, s.getSupplierName());
            ps.setNString(2, s.getContactName());
            ps.setString(3, s.getPhone());
            ps.setString(4, s.getEmail());
            ps.setNString(5, s.getAddress());
            ps.setString(6, s.getLicenseNumber());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    public boolean update(Supplier s) {
        String sql = "UPDATE Suppliers SET SupplierName=?, ContactName=?, Phone=?, " +
                "Email=?, Address=?, LicenseNumber=? WHERE SupplierID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, s.getSupplierName());
            ps.setNString(2, s.getContactName());
            ps.setString(3, s.getPhone());
            ps.setString(4, s.getEmail());
            ps.setNString(5, s.getAddress());
            ps.setString(6, s.getLicenseNumber());
            ps.setInt(7, s.getSupplierId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    public boolean toggleActive(int id) {
        String sql = "UPDATE Suppliers SET IsActive = 1 - IsActive WHERE SupplierID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}