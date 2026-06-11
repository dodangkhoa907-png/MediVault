package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IManufacturerDAO;
import com.medicare.entity.Manufacturer;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ManufacturerDAO implements IManufacturerDAO {

    private Manufacturer mapRow(ResultSet rs) throws SQLException {
        return new Manufacturer(
                rs.getInt("ManufacturerID"),
                rs.getNString("ManufacturerName"),
                rs.getString("Country"),
                rs.getNString("Address")
        );
    }

    public List<Manufacturer> findAll() {
        List<Manufacturer> list = new ArrayList<>();
        String sql = "SELECT * FROM Manufacturers ORDER BY ManufacturerName";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public Manufacturer findById(int id) {
        String sql = "SELECT * FROM Manufacturers WHERE ManufacturerID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    public boolean insert(Manufacturer m) {
        String sql = "INSERT INTO Manufacturers (ManufacturerName, Country, Address) VALUES (?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, m.getName());
            ps.setString(2, m.getCountry());
            ps.setNString(3, m.getAddress());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    public boolean update(Manufacturer m) {
        String sql = "UPDATE Manufacturers SET ManufacturerName=?, Country=?, Address=? WHERE ManufacturerID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, m.getName());
            ps.setString(2, m.getCountry());
            ps.setNString(3, m.getAddress());
            ps.setInt(4, m.getManufacturerId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}