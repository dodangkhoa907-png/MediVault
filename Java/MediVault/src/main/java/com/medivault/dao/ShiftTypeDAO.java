package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.dao.interfaces.IShiftTypeDAO;
import com.medivault.entity.ShiftType;
import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ShiftTypeDAO implements IShiftTypeDAO {

    /** Lương tối thiểu 50,000đ/giờ */
    public static final BigDecimal MIN_HOURLY_RATE = new BigDecimal("50000");

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

    /** Validate lương trước khi lưu — throw nếu vi phạm */
    private void validateHourlyRate(BigDecimal rate) {
        if (rate == null || rate.compareTo(MIN_HOURLY_RATE) < 0) {
            throw new IllegalArgumentException(
                    "Lương giờ tối thiểu là 50,000đ/giờ. Giá trị nhập: "
                            + (rate != null ? rate.toPlainString() : "null"));
        }
    }

    @Override
    public List<ShiftType> findAll() {
        List<ShiftType> list = new ArrayList<>();
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(
                     "SELECT * FROM ShiftTypes ORDER BY ShiftTypeID");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<ShiftType> findAllActive() {
        List<ShiftType> list = new ArrayList<>();
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(
                     "SELECT * FROM ShiftTypes WHERE IsActive=1 ORDER BY StartHour");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public ShiftType findById(int id) {
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(
                     "SELECT * FROM ShiftTypes WHERE ShiftTypeID=?")) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    @Override
    public boolean insert(ShiftType st) {
        // Java-side validation trước khi đến DB
        validateHourlyRate(st.getHourlyRate());

        String sql = "INSERT INTO ShiftTypes "
                + "(Name,StartHour,StartMinute,EndHour,EndMinute,"
                + "HourlyRate,OvertimeMultiplier,AllowanceAmount) "
                + "VALUES (?,?,?,?,?,?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, st.getName());
            ps.setInt(2, st.getStartHour());
            ps.setInt(3, st.getStartMinute());
            ps.setInt(4, st.getEndHour());
            ps.setInt(5, st.getEndMinute());
            ps.setBigDecimal(6, st.getHourlyRate());
            ps.setBigDecimal(7, st.getOvertimeMultiplier() != null
                    ? st.getOvertimeMultiplier() : new BigDecimal("1.5"));
            ps.setBigDecimal(8, st.getAllowanceAmount() != null
                    ? st.getAllowanceAmount() : BigDecimal.ZERO);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public boolean update(ShiftType st) {
        // Java-side validation
        validateHourlyRate(st.getHourlyRate());

        String sql = "UPDATE ShiftTypes SET Name=?,StartHour=?,StartMinute=?,"
                + "EndHour=?,EndMinute=?,HourlyRate=?,OvertimeMultiplier=?,AllowanceAmount=? "
                + "WHERE ShiftTypeID=?";
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
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public boolean setActive(int id, boolean active) {
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(
                     "UPDATE ShiftTypes SET IsActive=? WHERE ShiftTypeID=?")) {
            ps.setBoolean(1, active); ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
    @Override
    public boolean delete(int id) {
        String sql = "DELETE FROM ShiftTypes WHERE ShiftTypeID = ? AND IsActive = 0 "
                + "AND NOT EXISTS (SELECT 1 FROM ShiftSchedules WHERE ShiftTypeID = ?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id); ps.setInt(2, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}