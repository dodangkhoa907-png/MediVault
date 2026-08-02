package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IShelfDAO;
import com.medicare.entity.Shelf;
import com.medicare.util.MojibakeUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class ShelfDAO implements IShelfDAO {

    private Shelf mapRow(ResultSet rs) throws SQLException {
        Shelf s = new Shelf();
        s.setShelfId(rs.getInt("ShelfID"));
        s.setShelfName(MojibakeUtil.fix(rs.getString("ShelfName")));
        s.setMachineSlotCode(rs.getString("MachineSlotCode"));
        s.setMotorId(rs.getString("MotorID"));
        s.setLocationNotes(MojibakeUtil.fix(rs.getString("LocationNotes")));
        try { s.setShelfType(rs.getString("ShelfType")); } catch (SQLException ignored) {}
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
        // IsAutomated là CỘT TÍNH TOÁN (MachineSlotCode IS NOT NULL) → KHÔNG insert.
        String sql = "INSERT INTO Shelves (ShelfName, ShelfType, MachineSlotCode, MotorID, LocationNotes) VALUES (?,?,?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, s.getShelfName());
            ps.setString(2, s.getShelfType() != null ? s.getShelfType() : "RETAIL"); // NOT NULL
            ps.setString(3, s.getMachineSlotCode());
            ps.setString(4, s.getMotorId());
            ps.setNString(5, s.getLocationNotes());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    public boolean update(Shelf s) {
        String sql = "UPDATE Shelves SET ShelfName=?, ShelfType=?, MachineSlotCode=?, MotorID=?, LocationNotes=? WHERE ShelfID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, s.getShelfName());
            ps.setString(2, s.getShelfType() != null ? s.getShelfType() : "RETAIL");
            ps.setString(3, s.getMachineSlotCode());
            ps.setString(4, s.getMotorId());
            ps.setNString(5, s.getLocationNotes());
            ps.setInt(6, s.getShelfId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Danh sách rút gọn các thuốc đang gán trên kệ — cho modal "Xem chi tiết" và để chặn xoá
     *  có LÝ DO RÕ RÀNG (thủ kho thấy ngay cần chuyển thuốc nào đi trước), thay vì chỉ báo
     *  chung chung "còn thuốc" như bên Admin. */
    public List<Map<String, Object>> findMedicinesOnShelf(int shelfId) {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT MedicineID, MedicineCode, MedicineName, Unit FROM Medicines WHERE ShelfID = ? ORDER BY MedicineName";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, shelfId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> m = new LinkedHashMap<>();
                    m.put("id", rs.getInt("MedicineID"));
                    m.put("code", MojibakeUtil.fix(rs.getString("MedicineCode")));
                    m.put("name", MojibakeUtil.fix(rs.getString("MedicineName")));
                    m.put("unit", MojibakeUtil.fix(rs.getString("Unit")));
                    list.add(m);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    /** Đếm số thuốc đang đặt trên kệ — dùng để chặn xóa kệ đang có hàng. */
    public int countMedicinesOnShelf(int shelfId) {
        String sql = "SELECT COUNT(*) FROM Medicines WHERE ShelfID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, shelfId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 1; // an toàn: lỗi DB coi như đang dùng → chặn xóa
    }

    /** Xóa kệ — CHỈ khi không còn thuốc nào đặt trên kệ. */
    public boolean delete(int shelfId) {
        if (countMedicinesOnShelf(shelfId) > 0) return false;
        String sql = "DELETE FROM Shelves WHERE ShelfID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, shelfId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}