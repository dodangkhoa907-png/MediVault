package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IShiftDAO;
import com.medicare.entity.Shift;
import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class ShiftDAO implements IShiftDAO {

    // ── Câu SQL base JOIN Accounts để lấy FullName ──────────────────────────
    private static final String BASE_SELECT =
            "SELECT s.*, a.FullName FROM Shifts s " +
                    "LEFT JOIN Accounts a ON a.AccountID = s.AccountID ";

    private Shift mapRow(ResultSet rs) throws SQLException {
        Shift s = new Shift();
        s.setShiftId(rs.getInt("ShiftID"));
        s.setAccountId(rs.getInt("AccountID"));
        // FullName từ JOIN — try/catch để tương thích query cũ không JOIN
        try { s.setFullName(rs.getString("FullName")); } catch (SQLException ignored) {}
        if (rs.getTimestamp("StartTime") != null)
            s.setStartTime(rs.getTimestamp("StartTime").toLocalDateTime());
        if (rs.getTimestamp("EndTime") != null)
            s.setEndTime(rs.getTimestamp("EndTime").toLocalDateTime());
        s.setOpeningCash(rs.getBigDecimal("OpeningCash"));
        s.setClosingCash(rs.getBigDecimal("ClosingCash"));
        s.setNotes(rs.getNString("Notes"));
        s.setGracePeriodMinutes(rs.getInt("GracePeriodMinutes"));
        try {
            String st = rs.getString("Status");
            s.setStatus(st != null ? st : (s.getEndTime() == null ? "OPEN" : "CLOSED"));
        } catch (SQLException ignored) {
            s.setStatus(s.getEndTime() == null ? "OPEN" : "CLOSED");
        }
        return s;
    }

    @Override
    public boolean openShift(int accountId, BigDecimal openingCash) {
        if (findCurrent(accountId) != null) return false;
        // Explicit StartTime để tránh DB dùng GETDATE()=UTC
        String sql = "INSERT INTO Shifts (AccountID, OpeningCash, StartTime) VALUES (?, ?, DATEADD(HOUR,7,GETUTCDATE()))";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.setBigDecimal(2, openingCash != null ? openingCash : BigDecimal.ZERO);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public boolean closeShift(int shiftId, BigDecimal closingCash, String notes) {
        // FIX: GETDATE()=UTC → dùng DATEADD(HOUR,7,GETUTCDATE()) = giờ VN
        String sql = "UPDATE Shifts SET EndTime=DATEADD(HOUR,7,GETUTCDATE()), ClosingCash=?, Notes=?, Status='CLOSED' " +
                "WHERE ShiftID=? AND EndTime IS NULL";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setBigDecimal(1, closingCash != null ? closingCash : BigDecimal.ZERO);
            ps.setNString(2, notes);
            ps.setInt(3, shiftId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public boolean forceClose(int shiftId, String notes) {
        String sql = "UPDATE Shifts SET EndTime=DATEADD(HOUR,7,GETUTCDATE()), Notes=?, Status='FORCE_CLOSED' " +
                "WHERE ShiftID=? AND EndTime IS NULL";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, notes != null ? notes : "[Admin đóng ca]");
            ps.setInt(2, shiftId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public Shift findCurrent(int accountId) {
        String sql = BASE_SELECT +
                "WHERE s.AccountID=? AND s.EndTime IS NULL " +
                "ORDER BY s.StartTime DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    public List<Shift> findByStatus(String status) {
        List<Shift> list = new ArrayList<>();
        String sql = BASE_SELECT + "WHERE s.Status=? ORDER BY s.StartTime DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, status);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public boolean setClosingCash(int shiftId, BigDecimal closingCash) {
        return false;
    }

    @Override
    public List<Shift> findAll() {
        List<Shift> list = new ArrayList<>();
        String sql = BASE_SELECT + "ORDER BY s.StartTime DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<Shift> findByAccount(int accountId) {
        List<Shift> list = new ArrayList<>();
        String sql = BASE_SELECT + "WHERE s.AccountID=? ORDER BY s.StartTime DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<Shift> findByDateRange(LocalDate from, LocalDate to) {
        List<Shift> list = new ArrayList<>();
        String sql = BASE_SELECT +
                "WHERE CAST(s.StartTime AS DATE) BETWEEN ? AND ? " +
                "ORDER BY s.StartTime DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(from));
            ps.setDate(2, Date.valueOf(to));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public Shift findById(int id) {
        String sql = BASE_SELECT + "WHERE s.ShiftID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    @Override
    public boolean delete(int shiftId) {
        String sql = "DELETE FROM Shifts WHERE ShiftID=? " +
                "AND NOT EXISTS (SELECT 1 FROM Invoices WHERE ShiftID=?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, shiftId); ps.setInt(2, shiftId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public int countAll() {
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement("SELECT COUNT(*) FROM Shifts");
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }
}