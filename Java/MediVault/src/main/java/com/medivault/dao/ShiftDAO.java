package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.dao.interfaces.IMedicineDAO;
import com.medivault.dao.interfaces.IShiftDAO;
import com.medivault.entity.Shift;
import java.sql.*;
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
        return s;
    }

    // Mở ca mới — gọi khi nhân viên bắt đầu ca làm
    public boolean openShift(int accountId, java.math.BigDecimal openingCash) {
        String sql = "INSERT INTO Shifts (AccountID, OpeningCash) VALUES (?, ?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.setBigDecimal(2, openingCash);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // Đóng ca — gọi khi nhân viên kết thúc ca
    public boolean closeShift(int shiftId, java.math.BigDecimal closingCash, String notes) {
        String sql = "UPDATE Shifts SET EndTime = GETDATE(), ClosingCash = ?, Notes = ? WHERE ShiftID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setBigDecimal(1, closingCash);
            ps.setNString(2, notes);
            ps.setInt(3, shiftId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // Lấy ca đang mở của nhân viên (EndTime IS NULL)
    public Shift findCurrent(int accountId) {
        String sql = "SELECT * FROM Shifts WHERE AccountID = ? AND EndTime IS NULL " +
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

    public Shift findById(int id) {
        String sql = "SELECT * FROM Shifts WHERE ShiftID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    // Lịch sử ca của 1 nhân viên
    public List<Shift> findByAccount(int accountId) {
        List<Shift> list = new ArrayList<>();
        String sql = "SELECT * FROM Shifts WHERE AccountID = ? ORDER BY StartTime DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }
}