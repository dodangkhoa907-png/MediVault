package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.dao.interfaces.IShiftTypeDAO;
import com.medivault.entity.ShiftType;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ShiftTypeDAO implements IShiftTypeDAO {

    private ShiftType mapRow(ResultSet rs) throws SQLException {
        ShiftType s = new ShiftType();
        s.setShiftTypeId(rs.getInt("ShiftTypeID"));
        s.setName(rs.getNString("Name"));
        s.setStartHour(rs.getInt("StartHour"));
        s.setStartMinute(rs.getInt("StartMinute"));
        s.setEndHour(rs.getInt("EndHour"));
        s.setEndMinute(rs.getInt("EndMinute"));
        s.setHourlyRate(rs.getBigDecimal("HourlyRate"));
        s.setOvertimeMultiplier(rs.getBigDecimal("OvertimeMultiplier"));
        s.setAllowanceAmount(rs.getBigDecimal("AllowanceAmount"));
        s.setActive(rs.getBoolean("IsActive"));
        if (rs.getTimestamp("CreatedAt") != null)
            s.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
        return s;
    }

    @Override
    public List<ShiftType> findAll() {
        List<ShiftType> list = new ArrayList<>();
        String sql = "SELECT * FROM ShiftTypes ORDER BY ShiftTypeID";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<ShiftType> findAllActive() {
        List<ShiftType> list = new ArrayList<>();
        String sql = "SELECT * FROM ShiftTypes WHERE IsActive = 1 ORDER BY StartHour";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public ShiftType findById(int shiftTypeId) {
        String sql = "SELECT * FROM ShiftTypes WHERE ShiftTypeID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, shiftTypeId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    @Override
    public boolean insert(ShiftType st) {
        String sql = "INSERT INTO ShiftTypes "
                + "(Name, StartHour, StartMinute, EndHour, EndMinute, "
                + "HourlyRate, OvertimeMultiplier, AllowanceAmount) "
                + "VALUES (?,?,?,?,?,?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, st.getName());
            ps.setInt(2, st.getStartHour());
            ps.setInt(3, st.getStartMinute());
            ps.setInt(4, st.getEndHour());
            ps.setInt(5, st.getEndMinute());
            ps.setBigDecimal(6, st.getHourlyRate());
            ps.setBigDecimal(7, st.getOvertimeMultiplier());
            ps.setBigDecimal(8, st.getAllowanceAmount());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public boolean update(ShiftType st) {
        String sql = "UPDATE ShiftTypes SET Name=?, StartHour=?, StartMinute=?, "
                + "EndHour=?, EndMinute=?, HourlyRate=?, OvertimeMultiplier=?, "
                + "AllowanceAmount=? WHERE ShiftTypeID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, st.getName());
            ps.setInt(2, st.getStartHour());
            ps.setInt(3, st.getStartMinute());
            ps.setInt(4, st.getEndHour());
            ps.setInt(5, st.getEndMinute());
            ps.setBigDecimal(6, st.getHourlyRate());
            ps.setBigDecimal(7, st.getOvertimeMultiplier());
            ps.setBigDecimal(8, st.getAllowanceAmount());
            ps.setInt(9, st.getShiftTypeId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public boolean setActive(int shiftTypeId, boolean active) {
        String sql = "UPDATE ShiftTypes SET IsActive=? WHERE ShiftTypeID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setBoolean(1, active);
            ps.setInt(2, shiftTypeId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}
