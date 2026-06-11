package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.dao.interfaces.ILeaveRequestDAO;
import com.medivault.entity.LeaveRequest;
import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

public class LeaveRequestDAO implements ILeaveRequestDAO {

    private LeaveRequest mapRow(ResultSet rs) throws SQLException {
        LeaveRequest lr = new LeaveRequest();
        lr.setLeaveId(rs.getInt("LeaveID"));
        lr.setAccountId(rs.getInt("AccountID"));
        if (rs.getDate("LeaveDate") != null)
            lr.setLeaveDate(rs.getDate("LeaveDate").toLocalDate());
        lr.setLeaveType(rs.getString("LeaveType"));
        lr.setReason(rs.getNString("Reason"));
        lr.setStatus(rs.getString("Status"));
        int ab = rs.getInt("ApprovedBy");
        lr.setApprovedBy(rs.wasNull() ? null : ab);
        if (rs.getTimestamp("ApprovedAt") != null)
            lr.setApprovedAt(rs.getTimestamp("ApprovedAt").toLocalDateTime());
        lr.setDeductHours(rs.getBigDecimal("DeductHours"));
        lr.setDeductAmount(rs.getBigDecimal("DeductAmount"));
        if (rs.getTimestamp("RequestedAt") != null)
            lr.setRequestedAt(rs.getTimestamp("RequestedAt").toLocalDateTime());
        lr.setNotes(rs.getNString("Notes"));
        try { lr.setStaffName(rs.getNString("StaffName")); }       catch (SQLException ignored) {}
        try { lr.setApprovedByName(rs.getNString("ApprovedByName")); } catch (SQLException ignored) {}
        return lr;
    }

    private static final String SELECT_FULL =
        "SELECT lr.*, a.FullName AS StaffName, "
        + "ab.FullName AS ApprovedByName "
        + "FROM LeaveRequests lr "
        + "JOIN Accounts a ON a.AccountID = lr.AccountID "
        + "LEFT JOIN Accounts ab ON ab.AccountID = lr.ApprovedBy ";

    @Override
    public boolean insert(LeaveRequest lr) {
        String sql = "INSERT INTO LeaveRequests (AccountID, LeaveDate, LeaveType, Reason) "
                + "VALUES (?,?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, lr.getAccountId());
            ps.setDate(2, Date.valueOf(lr.getLeaveDate()));
            ps.setString(3, lr.getLeaveType());
            ps.setNString(4, lr.getReason());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public List<LeaveRequest> findByAccountAndMonth(int accountId, int month, int year) {
        List<LeaveRequest> list = new ArrayList<>();
        String sql = SELECT_FULL
                + "WHERE lr.AccountID = ? "
                + "AND MONTH(lr.LeaveDate) = ? AND YEAR(lr.LeaveDate) = ? "
                + "ORDER BY lr.LeaveDate DESC";
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
    public List<LeaveRequest> findByAccount(int accountId) {
        List<LeaveRequest> list = new ArrayList<>();
        String sql = SELECT_FULL
                + "WHERE lr.AccountID = ? ORDER BY lr.LeaveDate DESC";
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
    public List<LeaveRequest> findPending() {
        List<LeaveRequest> list = new ArrayList<>();
        String sql = SELECT_FULL
                + "WHERE lr.Status = 'PENDING' ORDER BY lr.RequestedAt ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public boolean approve(int leaveId, int approvedBy, String notes, BigDecimal deductAmount) {
        String sql = "UPDATE LeaveRequests SET Status='APPROVED', "
                + "ApprovedBy=?, ApprovedAt=GETDATE(), Notes=?, DeductAmount=? "
                + "WHERE LeaveID=? AND Status='PENDING'";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, approvedBy);
            ps.setNString(2, notes);
            ps.setBigDecimal(3, deductAmount != null ? deductAmount : BigDecimal.ZERO);
            ps.setInt(4, leaveId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public boolean reject(int leaveId, int approvedBy, String notes) {
        String sql = "UPDATE LeaveRequests SET Status='REJECTED', "
                + "ApprovedBy=?, ApprovedAt=GETDATE(), Notes=? "
                + "WHERE LeaveID=? AND Status='PENDING'";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, approvedBy);
            ps.setNString(2, notes);
            ps.setInt(3, leaveId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public List<LeaveRequest> findByMonth(int month, int year) {
        List<LeaveRequest> list = new ArrayList<>();
        String sql = SELECT_FULL
                + "WHERE MONTH(lr.LeaveDate) = ? AND YEAR(lr.LeaveDate) = ? "
                + "ORDER BY lr.LeaveDate ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, month);
            ps.setInt(2, year);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public LeaveRequest findById(int leaveId) {
        String sql = SELECT_FULL + "WHERE lr.LeaveID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, leaveId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    @Override
    public boolean existsByAccountAndDate(int accountId, LocalDate date) {
        String sql = "SELECT 1 FROM LeaveRequests "
                + "WHERE AccountID=? AND LeaveDate=? AND Status != 'REJECTED'";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.setDate(2, Date.valueOf(date));
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}
