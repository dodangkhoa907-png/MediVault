package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IAttendanceDAO;
import com.medicare.entity.Attendance;
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

        // ── NEW: đọc AttendanceStatus ──
        try {
            String st = rs.getString("AttendanceStatus");
            a.setAttendanceStatus(st != null ? st :
                    (a.getCheckOutTime() == null ? "CHECKED_IN" : "ON_TIME"));
        } catch (SQLException ignored) {
            // Cột chưa tồn tại → fallback tính từ dữ liệu
            a.setAttendanceStatus(computeStatus(a));
        }

        // Join fields
        try { a.setStaffName(rs.getNString("StaffName")); }       catch (SQLException e) {}
        try { a.setShiftTypeName(rs.getNString("ShiftTypeName")); } catch (SQLException e) {}
        try {
            Timestamp pe = rs.getTimestamp("PlannedEnd");
            if (pe != null) a.setPlannedEnd(pe.toLocalDateTime());
        } catch (SQLException e) {}
        return a;
    }

    /** Tính status từ field nếu cột chưa tồn tại trong DB */
    private String computeStatus(Attendance a) {
        if (a.getCheckOutTime() == null) return "CHECKED_IN";
        if (a.isAutoClose())             return "FORCE_CHECKOUT";
        if (a.getScheduleId() == null)   return "NO_SCHEDULE";
        if (a.getOvertimeHours() > 0)    return "OVERTIME";
        if (a.getLateMinutes() > 0 && a.getEarlyLeaveMinutes() > 0) return "LATE_EARLY";
        if (a.getLateMinutes() > 0)      return "LATE";
        if (a.getEarlyLeaveMinutes() > 0)return "EARLY_LEAVE";
        return "ON_TIME";
    }

    private static final String SELECT_FULL =
            "SELECT att.*, a.FullName AS StaffName, " +
                    "st.Name AS ShiftTypeName, ss.PlannedEnd " +
                    "FROM Attendance att " +
                    "JOIN Accounts a ON a.AccountID = att.AccountID " +
                    "LEFT JOIN ShiftSchedules ss ON ss.ScheduleID = att.ScheduleID " +
                    "LEFT JOIN ShiftTypes st ON st.ShiftTypeID = ss.ShiftTypeID ";

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
        String sql = SELECT_FULL +
                "WHERE att.AccountID=? AND att.CheckOutTime IS NULL " +
                "ORDER BY att.CheckInTime DESC";
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
        String sql = SELECT_FULL +
                "WHERE att.AccountID=? AND MONTH(att.CheckInTime)=? AND YEAR(att.CheckInTime)=? " +
                "ORDER BY att.CheckInTime DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId); ps.setInt(2, month); ps.setInt(3, year);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<Attendance> findCurrentlyWorking() {
        List<Attendance> list = new ArrayList<>();
        // Dùng view V_CurrentlyWorking
        String sql = "SELECT att.*, a.FullName AS StaffName, " +
                "st.Name AS ShiftTypeName, ss.PlannedEnd " +
                "FROM V_CurrentlyWorking v " +
                "JOIN Attendance att ON att.AttendanceID = v.AttendanceID " +
                "JOIN Accounts a ON a.AccountID = att.AccountID " +
                "LEFT JOIN ShiftSchedules ss ON ss.ScheduleID = att.ScheduleID " +
                "LEFT JOIN ShiftTypes st ON st.ShiftTypeID = ss.ShiftTypeID";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) {
            // Fallback nếu view chưa có
            String fallback = SELECT_FULL + "WHERE att.CheckOutTime IS NULL";
            try (Connection cn = DBContext.getConnection();
                 PreparedStatement ps = cn.prepareStatement(fallback);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            } catch (Exception ex) { ex.printStackTrace(); }
        }
        return list;
    }

    /** Tìm theo status — dùng cho báo cáo đi trễ/vắng */
    public List<Attendance> findByStatusAndMonth(String status, int month, int year) {
        List<Attendance> list = new ArrayList<>();
        String sql = SELECT_FULL +
                "WHERE att.AttendanceStatus=? " +
                "AND MONTH(att.CheckInTime)=? AND YEAR(att.CheckInTime)=? " +
                "ORDER BY att.CheckInTime DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, status); ps.setInt(2, month); ps.setInt(3, year);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<Attendance> findByAccountAndDateRange(int accountId, LocalDate from, LocalDate to) {
        // accountId=0 → lấy tất cả nhân viên
        List<Attendance> list = new ArrayList<>();
        String sql = accountId > 0
                ? SELECT_FULL + "WHERE att.AccountID=? AND CAST(att.CheckInTime AS DATE) BETWEEN ? AND ? ORDER BY att.CheckInTime DESC"
                : SELECT_FULL + "WHERE CAST(att.CheckInTime AS DATE) BETWEEN ? AND ? ORDER BY att.CheckInTime DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            int p = 1;
            if (accountId > 0) ps.setInt(p++, accountId);
            ps.setDate(p++, Date.valueOf(from));
            ps.setDate(p,   Date.valueOf(to));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public Attendance findByScheduleId(int scheduleId) {
        String sql = SELECT_FULL + "WHERE att.ScheduleID=?";
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
        String sql = SELECT_FULL + "WHERE att.AttendanceID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, attendanceId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    @Override
    public int checkInWithPenalty(int accountId, int scheduleId, String method,
                                  BigDecimal openingCash, BigDecimal penaltyAmount,
                                  int lateMinutes, String status) {
        // Tìm ShiftID đang mở của nhân viên để gán vào Attendance
        // → SP_AutoCloseOverdueShifts cần ShiftID để đóng bảng Shifts
        Integer shiftId = findCurrentShiftId(accountId);

        String sql = shiftId != null
                ? "INSERT INTO Attendance (AccountID, ScheduleID, ShiftID, CheckInMethod, "
                  + "LateMinutes, PenaltyAmount, AttendanceStatus) "
                  + "VALUES (?,?,?,?,?,?,?); SELECT SCOPE_IDENTITY();"
                : "INSERT INTO Attendance (AccountID, ScheduleID, CheckInMethod, "
                  + "LateMinutes, PenaltyAmount, AttendanceStatus) "
                  + "VALUES (?,?,?,?,?,?); SELECT SCOPE_IDENTITY();";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.setInt(2, scheduleId);
            int p = 3;
            if (shiftId != null) ps.setInt(p++, shiftId);
            ps.setString(p++, method != null ? method : "WEB_BUTTON");
            ps.setInt(p++, lateMinutes);
            ps.setBigDecimal(p++, penaltyAmount != null ? penaltyAmount : BigDecimal.ZERO);
            ps.setString(p, status != null ? status : "CONFIRMED");
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return -1;
    }

    @Override
    public boolean checkOutWithPenalty(int accountId, BigDecimal penaltyAmount,
                                       String notes, boolean isAutoClose) {
        String sql =
                "UPDATE Attendance SET "
                        + "  CheckOutTime     = GETDATE(), "
                        + "  AttendanceStatus = CASE "
                        + "      WHEN AttendanceStatus = 'CONFIRMED' THEN 'ON_TIME' "
                        + "      WHEN AttendanceStatus = 'LATE' THEN 'LATE' "
                        + "      ELSE AttendanceStatus END, "
                        + "  PenaltyAmount    = ISNULL(PenaltyAmount,0) + ?, "
                        + "  IsAutoClose      = ?, "
                        + "  CheckInNote      = ? "
                        + "WHERE AccountID = ? AND CheckOutTime IS NULL";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setBigDecimal(1, penaltyAmount != null ? penaltyAmount : BigDecimal.ZERO);
            ps.setBoolean(2, isAutoClose);
            ps.setNString(3, notes);
            ps.setInt(4, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Tìm ShiftID đang mở (EndTime IS NULL) của nhân viên */
    private Integer findCurrentShiftId(int accountId) {
        String sql = "SELECT TOP 1 ShiftID FROM Shifts WHERE AccountID=? AND EndTime IS NULL ORDER BY StartTime DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    @Override
    public int countByStatus(String status) {
        String sql = "SELECT COUNT(*) FROM Attendance WHERE AttendanceStatus=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, status);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }
}