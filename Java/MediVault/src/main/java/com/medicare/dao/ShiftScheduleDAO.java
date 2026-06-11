package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IShiftScheduleDAO;
import com.medicare.entity.ShiftSchedule;

import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class ShiftScheduleDAO implements IShiftScheduleDAO {

    private ShiftSchedule mapRow(ResultSet rs) throws SQLException {
        ShiftSchedule s = new ShiftSchedule();
        s.setScheduleId(rs.getInt("ScheduleID"));
        s.setAccountId(rs.getInt("AccountID"));
        s.setShiftTypeId(rs.getInt("ShiftTypeID"));
        if (rs.getDate("WorkDate") != null)
            s.setWorkDate(rs.getDate("WorkDate").toLocalDate());
        if (rs.getTimestamp("PlannedStart") != null)
            s.setPlannedStart(rs.getTimestamp("PlannedStart").toLocalDateTime());
        if (rs.getTimestamp("PlannedEnd") != null)
            s.setPlannedEnd(rs.getTimestamp("PlannedEnd").toLocalDateTime());
        s.setLateToleranceMinutes(rs.getInt("LateToleranceMinutes"));
        s.setStatus(rs.getString("Status"));
        s.setNotes(rs.getNString("Notes"));
        s.setCreatedBy(rs.getInt("CreatedBy"));
        if (rs.getTimestamp("CreatedAt") != null)
            s.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
        // ── NEW: OpeningCash + PenaltyRate do Admin set ──
        try { s.setOpeningCash(rs.getBigDecimal("OpeningCash")); }             catch (SQLException ignored) {}
        try { s.setPenaltyRatePerMinute(rs.getBigDecimal("PenaltyRatePerMinute")); } catch (SQLException ignored) {}
        try { s.setStaffName(rs.getNString("StaffName")); }        catch (SQLException ignored) {}
        try { s.setShiftTypeName(rs.getNString("ShiftTypeName")); } catch (SQLException ignored) {}
        try { s.setStartHour(rs.getInt("StartHour")); }             catch (SQLException ignored) {}
        try { s.setEndHour(rs.getInt("EndHour")); }                 catch (SQLException ignored) {}
        return s;
    }

    private static final String SELECT_FULL =
            "SELECT ss.*, a.FullName AS StaffName, "
                    + "st.Name AS ShiftTypeName, st.StartHour, st.EndHour "
                    + "FROM ShiftSchedules ss "
                    + "JOIN Accounts a    ON a.AccountID    = ss.AccountID "
                    + "JOIN ShiftTypes st ON st.ShiftTypeID = ss.ShiftTypeID ";

    // ── CREATE ────────────────────────────────────────────────────────────────
    @Override
    public int schedule(int accountId, int shiftTypeId, LocalDate workDate, int createdBy) {
        try (Connection cn = DBContext.getConnection();
             CallableStatement cs = cn.prepareCall("{call SP_ScheduleShift(?,?,?,?)}")) {
            cs.setInt(1, accountId);
            cs.setInt(2, shiftTypeId);
            cs.setDate(3, Date.valueOf(workDate));
            cs.setInt(4, createdBy);
            try (ResultSet rs = cs.executeQuery()) {
                if (rs.next()) return rs.getInt("NewScheduleID");
            }
        } catch (Exception e) { e.printStackTrace(); }
        return -1;
    }

    // ── READ ──────────────────────────────────────────────────────────────────
    @Override
    public ShiftSchedule findById(int scheduleId) {
        String sql = SELECT_FULL + "WHERE ss.ScheduleID = ?";
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
    public List<ShiftSchedule> findAll() {
        List<ShiftSchedule> list = new ArrayList<>();
        String sql = SELECT_FULL + "ORDER BY ss.WorkDate DESC, ss.PlannedStart ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<ShiftSchedule> findByDate(LocalDate date) {
        List<ShiftSchedule> list = new ArrayList<>();
        String sql = SELECT_FULL + "WHERE ss.WorkDate = ? ORDER BY ss.PlannedStart ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(date));
            try (ResultSet rs = ps.executeQuery()) { while (rs.next()) list.add(mapRow(rs)); }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<ShiftSchedule> findByDateRange(LocalDate from, LocalDate to) {
        List<ShiftSchedule> list = new ArrayList<>();
        String sql = SELECT_FULL
                + "WHERE ss.WorkDate BETWEEN ? AND ? "
                + "ORDER BY ss.WorkDate ASC, ss.PlannedStart ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(from)); ps.setDate(2, Date.valueOf(to));
            try (ResultSet rs = ps.executeQuery()) { while (rs.next()) list.add(mapRow(rs)); }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<ShiftSchedule> findByAccount(int accountId) {
        List<ShiftSchedule> list = new ArrayList<>();
        String sql = SELECT_FULL
                + "WHERE ss.AccountID = ? AND ss.Status != 'CANCELLED' "
                + "ORDER BY ss.WorkDate DESC, ss.PlannedStart ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) { while (rs.next()) list.add(mapRow(rs)); }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<ShiftSchedule> findByAccountAndMonth(int accountId, int month, int year) {
        List<ShiftSchedule> list = new ArrayList<>();
        String sql = SELECT_FULL
                + "WHERE ss.AccountID = ? AND MONTH(ss.WorkDate)=? AND YEAR(ss.WorkDate)=? "
                + "ORDER BY ss.WorkDate ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId); ps.setInt(2, month); ps.setInt(3, year);
            try (ResultSet rs = ps.executeQuery()) { while (rs.next()) list.add(mapRow(rs)); }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public ShiftSchedule findTodaySchedule(int accountId) {
        String sql = SELECT_FULL
                + "WHERE ss.AccountID = ? AND ss.WorkDate = CAST(GETDATE() AS DATE) "
                + "AND ss.Status NOT IN ('CANCELLED','ABSENT') "
                + "ORDER BY ss.PlannedStart ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) return mapRow(rs); }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    @Override
    public List<ShiftSchedule> findUpcoming(int accountId, int days) {
        List<ShiftSchedule> list = new ArrayList<>();
        String sql = SELECT_FULL
                + "WHERE ss.AccountID = ? "
                + "AND ss.WorkDate BETWEEN CAST(GETDATE() AS DATE) "
                + "AND CAST(DATEADD(DAY,?,GETDATE()) AS DATE) "
                + "AND ss.Status NOT IN ('CANCELLED') "
                + "ORDER BY ss.WorkDate ASC, ss.PlannedStart ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId); ps.setInt(2, days - 1);
            try (ResultSet rs = ps.executeQuery()) { while (rs.next()) list.add(mapRow(rs)); }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public ShiftSchedule findByAccountAndDate(int accountId, LocalDate date) {
        String sql = SELECT_FULL + "WHERE ss.AccountID = ? AND ss.WorkDate = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId); ps.setDate(2, Date.valueOf(date));
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) return mapRow(rs); }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    // ── UPDATE ────────────────────────────────────────────────────────────────
    @Override
    public boolean updateStatus(int scheduleId, String status) {
        String sql = "UPDATE ShiftSchedules SET Status=? WHERE ScheduleID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, status); ps.setInt(2, scheduleId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** NEW: Admin set OpeningCash cho từng lịch ca (≥ 50,000đ) */
    public boolean updateOpeningCash(int scheduleId, java.math.BigDecimal openingCash) {
        String sql = "UPDATE ShiftSchedules SET OpeningCash=? WHERE ScheduleID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setBigDecimal(1, openingCash);
            ps.setInt(2, scheduleId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public boolean update(int scheduleId, int shiftTypeId,
                          int lateToleranceMinutes, String notes, int updatedBy) {
        String sql =
                "UPDATE ss SET "
                        + "  ss.ShiftTypeID = ?, "
                        + "  ss.LateToleranceMinutes = ?, "
                        + "  ss.Notes = ?, "
                        + "  ss.PlannedStart = DATEADD(MINUTE, st.StartMinute, "
                        + "                    DATEADD(HOUR,   st.StartHour,   CAST(ss.WorkDate AS DATETIME))), "
                        + "  ss.PlannedEnd   = CASE "
                        + "      WHEN st.EndHour < st.StartHour "
                        + "      THEN DATEADD(MINUTE, st.EndMinute, DATEADD(HOUR, st.EndHour, "
                        + "           DATEADD(DAY, 1, CAST(ss.WorkDate AS DATETIME)))) "
                        + "      ELSE DATEADD(MINUTE, st.EndMinute, DATEADD(HOUR, st.EndHour, "
                        + "           CAST(ss.WorkDate AS DATETIME))) END "
                        + "FROM ShiftSchedules ss "
                        + "JOIN ShiftTypes st ON st.ShiftTypeID = ? "
                        + "WHERE ss.ScheduleID = ? "
                        + "AND ss.Status IN ('SCHEDULED','LEAVE_PENDING')";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, shiftTypeId);
            ps.setInt(2, lateToleranceMinutes);
            ps.setNString(3, notes);
            ps.setInt(4, shiftTypeId);
            ps.setInt(5, scheduleId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // ── DELETE ────────────────────────────────────────────────────────────────
    @Override
    public boolean cancel(int scheduleId) {
        return updateStatus(scheduleId, "CANCELLED");
    }

    @Override
    public boolean delete(int scheduleId) {
        String sql =
                "DELETE FROM ShiftSchedules WHERE ScheduleID = ? "
                        + "AND NOT EXISTS (SELECT 1 FROM Attendance WHERE ScheduleID = ?) "
                        + "AND Status IN ('SCHEDULED','CANCELLED','LEAVE_PENDING')";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, scheduleId); ps.setInt(2, scheduleId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // ── COUNT ─────────────────────────────────────────────────────────────────
    @Override
    public int countAbsent(LocalDate from, LocalDate to) {
        String sql = "SELECT COUNT(*) FROM ShiftSchedules "
                + "WHERE Status='ABSENT' AND WorkDate BETWEEN ? AND ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(from)); ps.setDate(2, Date.valueOf(to));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }
}