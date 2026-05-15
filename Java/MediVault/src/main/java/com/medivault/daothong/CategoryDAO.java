package com.medivault.daothong;

import com.medivault.config.DBContext;
import com.medivault.entity.Category;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CategoryDAO extends DBContext {
    public List<Category> getAll() {
        List<Category> list = new ArrayList<>();
        String sql = "SELECT * FROM Categories";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(new Category(rs.getInt("CategoryID"), rs.getNString("CategoryName"), rs.getNString("Description")));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }
}