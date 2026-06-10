package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.dao.interfaces.IShiftDAO;
import com.medivault.entity.Shift;
import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class ShiftDAO implements IShiftDAO {

    private Shift mapRow(ResultSet rs) throws SQLException {
        Shift s = new Shift();
        s.setShiftId(rs.getInt("ShiftID"));
        s.setAccountId(rs.getInt("AccountID"));
        if (rs.getTimestamp("StartTime") != null)
            s.setStartTime(rs.getTimestamp("StartTime").toLocalDateTime());
        if (rs.getTimestamp("EndTime") != null)
            s.setEndTime(rs.getTimestamp("EndTime").toLocalDateTime());
        s.setOpeningCash(rs.getBigDecimal("OpeningCash"));
        s.setClosingCash(rs.getBigDecimal("ClosingCash"));
        s.setNotes(rs.getNString("Notes"));
        s.setGracePeriodMinutes(rs.getInt("GracePeriodMinutes"));
        // ── NEW: đọc Status (nếu cột chưa tồn tại thì fallback từ EndTime) ──
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
        // Status='OPEN' là DEFAULT nên không cần set
        String sql = "INSERT INTO Shifts (AccountID, OpeningCash) VALUES (?, ?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.setBigDecimal(2, openingCash != null ? openingCash : BigDecimal.ZERO);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public boolean closeShift(int shiftId, BigDecimal closingCash, String notes) {
        // Trigger TRG_Shift_UpdateStatus tự set Status='CLOSED'
        String sql = "UPDATE Shifts SET EndTime=GETDATE(), ClosingCash=?, Notes=? " +
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
        // Notes chứa "[Admin" → trigger set Status='FORCE_CLOSED'
        String sql = "UPDATE Shifts SET EndTime=GETDATE(), Notes=?, Status='FORCE_CLOSED' " +
                "WHERE ShiftID=? AND EndTime IS NULL";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, notes != null ? notes : "[Admin đóng ca]");
            ps.setInt(2, shiftId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Tìm ca đang mở của nhân viên (Status='OPEN') */
    @Override
    public Shift findCurrent(int accountId) {
        String sql = "SELECT TOP 1 * FROM Shifts " +
                "WHERE AccountID=? AND EndTime IS NULL " +
                "ORDER BY StartTime DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    /** Tìm theo status */
    public List<Shift> findByStatus(String status) {
        List<Shift> list = new ArrayList<>();
        String sql = "SELECT * FROM Shifts WHERE Status=? ORDER BY StartTime DESC";
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
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement("SELECT * FROM Shifts ORDER BY StartTime DESC");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<Shift> findByAccount(int accountId) {
        List<Shift> list = new ArrayList<>();
        String sql = "SELECT * FROM Shifts WHERE AccountID=? ORDER BY StartTime DESC";
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
        String sql = "SELECT * FROM Shifts WHERE CAST(StartTime AS DATE) BETWEEN ? AND ? " +
                "ORDER BY StartTime DESC";
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
        String sql = "SELECT * FROM Shifts WHERE ShiftID=?";
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