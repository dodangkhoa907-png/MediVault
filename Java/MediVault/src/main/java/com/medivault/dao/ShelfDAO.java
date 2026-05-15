package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.entity.Shelf;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ShelfDAO extends DBContext {
    public List<Shelf> getAll() {
        List<Shelf> list = new ArrayList<>();
        String sql = "SELECT * FROM Shelves";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Shelf s = new Shelf();
                s.setShelfId(rs.getInt("ShelfID"));
                s.setShelfName(rs.getNString("ShelfName"));
                s.setMachineSlotCode(rs.getString("MachineSlotCode"));
                s.setMotorId(rs.getString("MotorID"));
                s.setAutomated(rs.getBoolean("IsAutomated")); // Cột tính toán trong SQL
                list.add(s);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }
}