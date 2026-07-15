package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IManufacturerDAO;
import com.medicare.entity.Manufacturer;
import com.medicare.util.MojibakeUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ManufacturerDAO implements IManufacturerDAO {

    private Manufacturer mapRow(ResultSet rs) throws SQLException {
        return new Manufacturer(
                rs.getInt("ManufacturerID"),
                MojibakeUtil.fix(rs.getString("Name")),
                rs.getString("Country"),
                MojibakeUtil.fix(rs.getString("Address"))
        );
    }

    public List<Manufacturer> findAll() {
        List<Manufacturer> list = new ArrayList<>();
        String sql = "SELECT * FROM Manufacturers ORDER BY Name";
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
        String sql = "INSERT INTO Manufacturers (Name, Country, Address) VALUES (?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, m.getName());
            ps.setString(2, m.getCountry());
            ps.setNString(3, m.getAddress());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    public boolean update(Manufacturer m) {
        String sql = "UPDATE Manufacturers SET Name=?, Country=?, Address=? WHERE ManufacturerID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, m.getName());
            ps.setString(2, m.getCountry());
            ps.setNString(3, m.getAddress());
            ps.setInt(4, m.getManufacturerId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Xóa manufacturer. Trả false nếu vẫn còn thuốc đang dùng. */
    public boolean delete(int id) {
        String checkSql = "SELECT COUNT(*) FROM Medicines WHERE ManufacturerID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(checkSql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) return false;
            }
        } catch (Exception e) { e.printStackTrace(); return false; }
        String sql = "DELETE FROM Manufacturers WHERE ManufacturerID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Tạo manufacturer mới và trả về ID mới (0 nếu thất bại) */
    public int insertGetId(Manufacturer m) {
        String sql = "INSERT INTO Manufacturers (Name, Country, Address) VALUES (?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setNString(1, m.getName());
            ps.setString(2, m.getCountry() != null ? m.getCountry() : "");
            ps.setNString(3, m.getAddress() != null ? m.getAddress() : "");
            if (ps.executeUpdate() > 0) {
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (keys.next()) return keys.getInt(1);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }
}