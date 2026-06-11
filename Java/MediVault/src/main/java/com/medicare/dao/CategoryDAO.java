package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.ICategoryDAO;
import com.medicare.entity.Category;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CategoryDAO implements ICategoryDAO {

    private Category mapRow(ResultSet rs) throws SQLException {
        return new Category(
                rs.getInt("CategoryID"),
                rs.getNString("CategoryName"),
                rs.getNString("Description")
        );
    }

    public List<Category> findAll() {
        List<Category> list = new ArrayList<>();
        String sql = "SELECT * FROM Categories ORDER BY CategoryName";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public Category findById(int id) {
        String sql = "SELECT * FROM Categories WHERE CategoryID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    public boolean insert(Category c) {
        String sql = "INSERT INTO Categories (CategoryName, Description) VALUES (?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, c.getCategoryName());
            ps.setNString(2, c.getDescription());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    public boolean update(Category c) {
        String sql = "UPDATE Categories SET CategoryName=?, Description=? WHERE CategoryID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, c.getCategoryName());
            ps.setNString(2, c.getDescription());
            ps.setInt(3, c.getCategoryId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    public boolean delete(int id) {
        String sql = "DELETE FROM Categories WHERE CategoryID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}