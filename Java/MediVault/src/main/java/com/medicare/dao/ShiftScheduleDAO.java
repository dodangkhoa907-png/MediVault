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
        try { s.setPosStation(rs.getInt("PosStation")); }           catch (SQLException ignored) {}
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
                + "AND ss.Status != 'CANCELLED' "
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
                + "WHERE ss.AccountID = ? AND ss.WorkDate = ? "
                + "AND ss.Status NOT IN ('CANCELLED','ABSENT') "
                + "ORDER BY ss.PlannedStart ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.setDate(2, java.sql.Date.valueOf(java.time.LocalDate.now()));
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) return mapRow(rs); }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    @Override
    public List<ShiftSchedule> findUpcoming(int accountId, int days) {
        List<ShiftSchedule> list = new ArrayList<>();
        String sql = SELECT_FULL
                + "WHERE ss.AccountID = ? "
                + "AND ss.WorkDate BETWEEN ? AND DATEADD(DAY,?,?) "
                + "AND ss.Status NOT IN ('CANCELLED') "
                + "ORDER BY ss.WorkDate ASC, ss.PlannedStart ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            java.sql.Date _today = java.sql.Date.valueOf(java.time.LocalDate.now());
            ps.setInt(1, accountId);
            ps.setDate(2, _today);
            ps.setInt(3, days - 1);
            ps.setDate(4, _today);
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

    /** Gán quầy POS cho lịch ca */
    public boolean updatePosStation(int scheduleId, int posStation) {
        String sql = "UPDATE ShiftSchedules SET PosStation=? WHERE ScheduleID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, posStation);
            ps.setInt(2, scheduleId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /**
     * Fallback bulk update: gán quầy POS cho tất cả ca trong khoảng ngày của 1 nhân viên.
     * Chỉ update nếu PosStation = 0 (chưa được gán), tránh ghi đè quầy đã thiết lập trước.
     */
    public void updatePosStationInDateRange(int accountId, LocalDate from, LocalDate to, int posStation) {
        String sql = "UPDATE ShiftSchedules SET PosStation=? "
                   + "WHERE AccountID=? AND WorkDate BETWEEN ? AND ? "
                   + "AND (PosStation IS NULL OR PosStation=0) AND Status NOT IN ('CANCELLED')";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, posStation);
            ps.setInt(2, accountId);
            ps.setDate(3, Date.valueOf(from));
            ps.setDate(4, Date.valueOf(to));
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
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
        return update(scheduleId, shiftTypeId, lateToleranceMinutes, notes, updatedBy, -1);
    }

    public boolean update(int scheduleId, int shiftTypeId,
                          int lateToleranceMinutes, String notes, int updatedBy, int posStation) {
        String sql =
                "UPDATE ss SET "
                        + "  ss.ShiftTypeID = ?, "
                        + "  ss.LateToleranceMinutes = ?, "
                        + "  ss.Notes = ?, "
                        + "  ss.PosStation = CASE WHEN ? >= 0 THEN ? ELSE ss.PosStation END, "
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
                        + "AND ss.Status IN ('SCHEDULED','LEAVE_PENDING','CONFIRMED')";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, shiftTypeId);
            ps.setInt(2, lateToleranceMinutes);
            ps.setNString(3, notes);
            ps.setInt(4, posStation);           // sentinel check
            ps.setInt(5, posStation);           // actual value
            ps.setInt(6, shiftTypeId);
            ps.setInt(7, scheduleId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Tất cả lịch ca hôm nay — cho sơ đồ quầy POS */
    public List<ShiftSchedule> findTodayAll() {
        List<ShiftSchedule> list = new ArrayList<>();
        String sql = SELECT_FULL
                + "WHERE ss.WorkDate = CAST(GETDATE() AS DATE) "
                + "AND ss.Status NOT IN ('CANCELLED') "
                + "ORDER BY ss.PosStation ASC, ss.PlannedStart ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    // ── DELETE ────────────────────────────────────────────────────────────────
    /**
     * Hủy ca — CHỈ khi nhân viên CHƯA vào ca. Ca đã check-in (CONFIRMED/LATE)
     * hoặc đã có bản ghi điểm danh thì KHÔNG được hủy (chống mất dấu ca đang chạy
     * và giữ nguyên lịch sử chấm công).
     */
    @Override
    public boolean cancel(int scheduleId) {
        String sql = "UPDATE ShiftSchedules SET Status='CANCELLED' "
                + "WHERE ScheduleID=? "
                + "AND Status IN ('SCHEDULED','LEAVE_PENDING') "
                + "AND NOT EXISTS (SELECT 1 FROM Attendance WHERE ScheduleID=?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, scheduleId);
            ps.setInt(2, scheduleId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
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
    // ── CHECK tồn tại theo ShiftType ──────────────────────────────────────────
    /**
     * Kiểm tra có ShiftSchedule nào đang dùng shiftTypeId này không.
     * Dùng để bảo vệ khi admin muốn xóa loại ca — không xóa được nếu còn lịch ca.
     * Không lọc theo Status vì dù CANCELLED hay COMPLETED vẫn có historical record.
     */
    public boolean existsByShiftTypeId(int shiftTypeId) {
        String sql = "SELECT TOP 1 1 FROM ShiftSchedules WHERE ShiftTypeID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, shiftTypeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (Exception e) {
            e.printStackTrace();
            return true; // an toàn: nếu lỗi DB thì chặn xóa
        }
    }

    // ── ĐIỀU PHỐI NGƯỜI THAY (nghỉ đột xuất) ──────────────────────────────────

    /**
     * Danh sách nhân viên "Off" ngày đó — có thể được điều phối làm thay.
     * Điều kiện: active, không phải admin, không bị xóa, và KHÔNG có lịch ca
     * (non-cancelled) nào trong ngày đó. Loại trừ chính người xin nghỉ.
     */
    public List<com.medicare.entity.Account> findAvailableSubstitutes(LocalDate date, int excludeAccountId) {
        List<com.medicare.entity.Account> list = new ArrayList<>();
        String sql =
                "SELECT a.AccountID, a.FullName, a.Username, a.RoleID, a.Phone "
              + "FROM Accounts a "
              + "WHERE a.RoleID <> 1 AND a.IsActive = 1 AND a.IsDeleted = 0 "
              + "AND a.AccountID <> ? "
              + "AND NOT EXISTS ("
              + "   SELECT 1 FROM ShiftSchedules ss "
              + "   WHERE ss.AccountID = a.AccountID AND ss.WorkDate = ? "
              + "   AND ss.Status <> 'CANCELLED') "
              + "ORDER BY a.FullName";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, excludeAccountId);
            ps.setDate(2, Date.valueOf(date));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    com.medicare.entity.Account a = new com.medicare.entity.Account();
                    a.setAccountId(rs.getInt("AccountID"));
                    a.setFullName(rs.getNString("FullName"));
                    a.setUsername(rs.getString("Username"));
                    a.setRoleId(rs.getInt("RoleID"));
                    a.setPhone(rs.getString("Phone"));
                    list.add(a);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    /**
     * Tạo lịch ca cho người làm thay — copy nguyên ca gốc (giờ giấc, quầy POS,
     * tiền đầu ca, mức phạt) sang tài khoản người thay, status SCHEDULED.
     * @return ScheduleID mới, hoặc -1 nếu lỗi (VD người thay đã có ca trùng).
     */
    public int assignSubstitute(ShiftSchedule original, int substituteAccountId, int createdBy) {
        String sql =
                "INSERT INTO ShiftSchedules "
              + "(AccountID, ShiftTypeID, WorkDate, PlannedStart, PlannedEnd, "
              + " LateToleranceMinutes, Status, Notes, CreatedBy, OpeningCash, "
              + " PenaltyRatePerMinute, PosStation) "
              + "VALUES (?,?,?,?,?,?, 'SCHEDULED', ?, ?, ?, ?, ?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setInt(1, substituteAccountId);
            ps.setInt(2, original.getShiftTypeId());
            ps.setDate(3, Date.valueOf(original.getWorkDate()));
            ps.setTimestamp(4, Timestamp.valueOf(original.getPlannedStart()));
            ps.setTimestamp(5, Timestamp.valueOf(original.getPlannedEnd()));
            ps.setInt(6, original.getLateToleranceMinutes());
            ps.setNString(7, "[Làm thay ca nghỉ đột xuất]");
            ps.setInt(8, createdBy);
            if (original.getOpeningCash() != null) ps.setBigDecimal(9, original.getOpeningCash());
            else ps.setNull(9, Types.DECIMAL);
            ps.setBigDecimal(10, original.getPenaltyRatePerMinute());
            ps.setInt(11, original.getPosStation());
            if (ps.executeUpdate() == 0) return -1;
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return -1;
    }
}