package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.dao.interfaces.IAttendanceDAO;
import com.medivault.entity.Attendance;
import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class AttendanceDAO implements IAttendanceDAO {

    private Attendance mapRow(ResultSet rs) throws SQLException {
        Attendance a = new Attendance();
        a.setAttendanceId(rs.getInt("AttendanceID"));
        int sid = rs.getInt("ScheduleID");
        a.setScheduleId(rs.wasNull() ? null : sid);
        int shid = rs.getInt("ShiftID");
        a.setShiftId(rs.wasNull() ? null : shid);
        a.setAccountId(rs.getInt("AccountID"));
        if (rs.getTimestamp("CheckInTime") != null)
            a.setCheckInTime(rs.getTimestamp("CheckInTime").toLocalDateTime());
        if (rs.getTimestamp("CheckOutTime") != null)
            a.setCheckOutTime(rs.getTimestamp("CheckOutTime").toLocalDateTime());
        a.setCheckInMethod(rs.getString("CheckInMethod"));
        a.setCheckInNote(rs.getNString("CheckInNote"));
        a.setLateMinutes(rs.getInt("LateMinutes"));
        a.setEarlyLeaveMinutes(rs.getInt("EarlyLeaveMinutes"));
        double actual = rs.getDouble("ActualHours");
        a.setActualHours(rs.wasNull() ? null : actual);
        a.setOvertimeHours(rs.getDouble("OvertimeHours"));
        a.setAutoClose(rs.getBoolean("IsAutoClose"));

        // Cột JOIN
        try { a.setStaffName(rs.getNString("StaffName")); }       catch (SQLException ignored) {}
        try { a.setShiftTypeName(rs.getNString("ShiftTypeName")); } catch (SQLException ignored) {}
        try {
            Timestamp pe = rs.getTimestamp("PlannedEnd");
            if (pe != null) a.setPlannedEnd(pe.toLocalDateTime());
        } catch (SQLException ignored) {}
        return a;
    }

    private static final String SELECT_FULL =
        "SELECT att.*, a.FullName AS StaffName, "
        + "st.Name AS ShiftTypeName, ss.PlannedEnd "
        + "FROM Attendance att "
        + "JOIN Accounts a ON a.AccountID = att.AccountID "
        + "LEFT JOIN ShiftSchedules ss ON ss.ScheduleID = att.ScheduleID "
        + "LEFT JOIN ShiftTypes st ON st.ShiftTypeID = ss.ShiftTypeID ";

    @Override
    public int checkIn(int accountId, String method, BigDecimal openingCash, String note) {
        String sql = "{call SP_CheckIn(?,?,?,?)}";
        try (Connection cn = DBContext.getConnection();
             CallableStatement cs = cn.prepareCall(sql)) {
            cs.setInt(1, accountId);
            cs.setString(2, method != null ? method : "WEB_BUTTON");
            cs.setBigDecimal(3, openingCash != null ? openingCash : BigDecimal.ZERO);
            cs.setNString(4, note);
            try (ResultSet rs = cs.executeQuery()) {
                if (rs.next()) return rs.getInt("AttendanceID");
            }
        } catch (Exception e) { e.printStackTrace(); }
        return -1;
    }

    @Override
    public boolean checkOut(int accountId, BigDecimal closingCash, String notes, boolean isAutoClose) {
        String sql = "{call SP_CheckOut(?,?,?,?)}";
        try (Connection cn = DBContext.getConnection();
             CallableStatement cs = cn.prepareCall(sql)) {
            cs.setInt(1, accountId);
            cs.setBigDecimal(2, closingCash != null ? closingCash : BigDecimal.ZERO);
            cs.setNString(3, notes);
            cs.setBoolean(4, isAutoClose);
            cs.execute();
            return true;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public Attendance findActiveByAccount(int accountId) {
        String sql = SELECT_FULL
                + "WHERE att.AccountID = ? AND att.CheckOutTime IS NULL "
                + "ORDER BY att.CheckInTime DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    @Override
    public List<Attendance> findByAccountAndMonth(int accountId, int month, int year) {
        List<Attendance> list = new ArrayList<>();
        String sql = SELECT_FULL
                + "WHERE att.AccountID = ? "
                + "AND MONTH(att.CheckInTime) = ? AND YEAR(att.CheckInTime) = ? "
                + "ORDER BY att.CheckInTime DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.setInt(2, month);
            ps.setInt(3, year);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<Attendance> findCurrentlyWorking() {
        List<Attendance> list = new ArrayList<>();
        // Dùng View V_CurrentlyWorking
        String sql = "SELECT att.*, a.FullName AS StaffName, "
                + "st.Name AS ShiftTypeName, ss.PlannedEnd "
                + "FROM V_CurrentlyWorking v "
                + "JOIN Attendance att ON att.AttendanceID = v.AttendanceID "
                + "JOIN Accounts a ON a.AccountID = att.AccountID "
                + "LEFT JOIN ShiftSchedules ss ON ss.ScheduleID = att.ScheduleID "
                + "LEFT JOIN ShiftTypes st ON st.ShiftTypeID = ss.ShiftTypeID";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) {
            // Fallback nếu view chưa tồn tại
            String fallback = SELECT_FULL + "WHERE att.CheckOutTime IS NULL";
            try (Connection cn = DBContext.getConnection();
                 PreparedStatement ps = cn.prepareStatement(fallback);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            } catch (Exception ex) { ex.printStackTrace(); }
        }
        return list;
    }

    @Override
    public List<Attendance> findByAccountAndDateRange(int accountId, LocalDate from, LocalDate to) {
        List<Attendance> list = new ArrayList<>();
        String sql = SELECT_FULL
                + "WHERE att.AccountID = ? "
                + "AND CAST(att.CheckInTime AS DATE) BETWEEN ? AND ? "
                + "ORDER BY att.CheckInTime DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.setDate(2, Date.valueOf(from));
            ps.setDate(3, Date.valueOf(to));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public Attendance findByScheduleId(int scheduleId) {
        String sql = SELECT_FULL + "WHERE att.ScheduleID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, scheduleId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    @Override
    public Attendance findById(int attendanceId) {
        String sql = SELECT_FULL + "WHERE att.AttendanceID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, attendanceId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }
}
