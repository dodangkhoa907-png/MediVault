package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.entity.Shelf;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ShelfDAO {

    private Shelf mapRow(ResultSet rs) throws SQLException {
        Shelf s = new Shelf();
        s.setShelfId(rs.getInt("ShelfID"));
        s.setShelfName(rs.getNString("ShelfName"));
        s.setMachineSlotCode(rs.getString("MachineSlotCode"));
        s.setMotorId(rs.getString("MotorID"));
        s.setLocationNotes(rs.getNString("LocationNotes"));
        s.setAutomated(rs.getBoolean("IsAutomated"));
        return s;
    }

    public List<Shelf> findAll() {
        List<Shelf> list = new ArrayList<>();
        String sql = "SELECT * FROM Shelves ORDER BY ShelfName";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public Shelf findById(int id) {
        String sql = "SELECT * FROM Shelves WHERE ShelfID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    public Shelf findBySlotCode(String slotCode) {
        String sql = "SELECT * FROM Shelves WHERE MachineSlotCode = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, slotCode);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    public boolean insert(Shelf s) {
        String sql = "INSERT INTO Shelves (ShelfName, MachineSlotCode, MotorID, LocationNotes) VALUES (?,?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, s.getShelfName());
            ps.setString(2, s.getMachineSlotCode());
            ps.setString(3, s.getMotorId());
            ps.setNString(4, s.getLocationNotes());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    public boolean update(Shelf s) {
        String sql = "UPDATE Shelves SET ShelfName=?, MachineSlotCode=?, MotorID=?, LocationNotes=? WHERE ShelfID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, s.getShelfName());
            ps.setString(2, s.getMachineSlotCode());
            ps.setString(3, s.getMotorId());
            ps.setNString(4, s.getLocationNotes());
            ps.setInt(5, s.getShelfId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}