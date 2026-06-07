package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.dao.interfaces.IPasswordResetDAO;
import com.medivault.entity.PasswordResetRequest;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class PasswordResetDAO implements IPasswordResetDAO {

    private PasswordResetRequest mapRow(ResultSet rs) throws SQLException {
        return new PasswordResetRequest(
                rs.getInt("RequestID"),
                rs.getInt("AccountID"),
                rs.getString("Token"),
                rs.getString("Status"),
                rs.getTimestamp("RequestedAt") != null ? rs.getTimestamp("RequestedAt").toLocalDateTime() : null,
                rs.getTimestamp("ExpiresAt")   != null ? rs.getTimestamp("ExpiresAt").toLocalDateTime()   : null,
                rs.getTimestamp("ConfirmedAt") != null ? rs.getTimestamp("ConfirmedAt").toLocalDateTime() : null,
                rs.getTimestamp("CompletedAt") != null ? rs.getTimestamp("CompletedAt").toLocalDateTime() : null
        );
    }

    @Override
    public boolean insert(PasswordResetRequest req) {
        String sql = "INSERT INTO PasswordResetRequests (AccountID, Token, ExpiresAt) VALUES (?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, req.getAccountId());
            ps.setString(2, req.getToken());
            ps.setTimestamp(3, Timestamp.valueOf(req.getExpiresAt()));
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public PasswordResetRequest findByToken(String token) {
        String sql = "SELECT * FROM PasswordResetRequests WHERE Token = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, token);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    @Override
    public PasswordResetRequest findPendingByAccountId(int accountId) {
        String sql = "SELECT * FROM PasswordResetRequests WHERE AccountID = ? AND Status = 'PENDING' AND ExpiresAt > GETDATE()";
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
    public PasswordResetRequest findConfirmedByAccountId(int accountId) {
        String sql = "SELECT * FROM PasswordResetRequests WHERE AccountID = ? AND Status = 'CONFIRMED'";
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
    public List<PasswordResetRequest> findAllPending() {
        List<PasswordResetRequest> list = new ArrayList<>();
        String sql = "SELECT * FROM PasswordResetRequests WHERE Status IN ('PENDING','CONFIRMED') ORDER BY RequestedAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public boolean confirm(String token) {
        String sql = "UPDATE PasswordResetRequests SET Status='CONFIRMED', ConfirmedAt=GETDATE() WHERE Token=? AND Status='PENDING' AND ExpiresAt > GETDATE()";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, token);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public boolean complete(int accountId) {
        // Đánh dấu COMPLETED cho cả PENDING và CONFIRMED (xóa khỏi chuông thông báo)
        String sql = "UPDATE PasswordResetRequests SET Status='COMPLETED', CompletedAt=GETDATE() WHERE AccountID=? AND Status IN ('PENDING','CONFIRMED')";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public boolean expireOld() {
        String sql = "UPDATE PasswordResetRequests SET Status='EXPIRED' WHERE Status='PENDING' AND ExpiresAt <= GETDATE()";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);) {
            return ps.executeUpdate() >= 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}