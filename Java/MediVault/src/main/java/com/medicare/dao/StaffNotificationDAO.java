package com.medicare.dao;

import com.medicare.config.DBContext;
import java.sql.*;
import java.time.LocalDateTime;
import java.util.*;

/**
 * StaffNotificationDAO — CRUD cho bảng StaffNotifications.
 * Dùng cho notification bell trên staff dashboard.
 */
public class StaffNotificationDAO {

    // ── DTO nhẹ — cần getters cho JSTL EL access ──
    public static class Notif {
        private int id;
        private int accountId;
        private String type;
        private String title;
        private String message;
        private boolean isRead;
        private LocalDateTime createdAt;
        private LocalDateTime expiresAt;

        public int getId() { return id; }
        public void setId(int id) { this.id = id; }
        public int getAccountId() { return accountId; }
        public void setAccountId(int accountId) { this.accountId = accountId; }
        public String getType() { return type; }
        public void setType(String type) { this.type = type; }
        public String getTitle() { return title; }
        public void setTitle(String title) { this.title = title; }
        public String getMessage() { return message; }
        public void setMessage(String message) { this.message = message; }
        public boolean isIsRead() { return isRead; }
        public void setIsRead(boolean isRead) { this.isRead = isRead; }
        public LocalDateTime getCreatedAt() { return createdAt; }
        public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
        public LocalDateTime getExpiresAt() { return expiresAt; }
        public void setExpiresAt(LocalDateTime expiresAt) { this.expiresAt = expiresAt; }
    }

    private Notif map(ResultSet rs) throws SQLException {
        Notif n = new Notif();
        n.setId(rs.getInt("NotificationID"));
        n.setAccountId(rs.getInt("AccountID"));
        n.setType(rs.getString("Type"));
        n.setTitle(rs.getString("Title"));
        n.setMessage(rs.getString("Message"));
        n.setIsRead(rs.getBoolean("IsRead"));
        if (rs.getTimestamp("CreatedAt") != null)
            n.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
        if (rs.getTimestamp("ExpiresAt") != null)
            n.setExpiresAt(rs.getTimestamp("ExpiresAt").toLocalDateTime());
        return n;
    }

    // ── Lấy thông báo chưa đọc (chưa hết hạn) ──
    public List<Notif> findUnread(int accountId) {
        String sql = "SELECT * FROM StaffNotifications "
                + "WHERE AccountID = ? AND IsRead = 0 "
                + "AND (ExpiresAt IS NULL OR ExpiresAt > GETDATE()) "
                + "ORDER BY CreatedAt DESC";
        List<Notif> list = new ArrayList<>();
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(map(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    // ── Đếm thông báo chưa đọc ──
    public int countUnread(int accountId) {
        String sql = "SELECT COUNT(*) FROM StaffNotifications "
                + "WHERE AccountID = ? AND IsRead = 0 "
                + "AND (ExpiresAt IS NULL OR ExpiresAt > GETDATE())";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    // ── Tạo thông báo mới ──
    public boolean insert(int accountId, String type, String title, String message) {
        return insert(accountId, type, title, message, null);
    }

    public boolean insert(int accountId, String type, String title, String message,
                          LocalDateTime expiresAt) {
        String sql = "INSERT INTO StaffNotifications(AccountID,Type,Title,Message,ExpiresAt) "
                + "VALUES(?,?,?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.setString(2, type);
            ps.setString(3, title);
            ps.setString(4, message);
            if (expiresAt != null) ps.setTimestamp(5, Timestamp.valueOf(expiresAt));
            else ps.setNull(5, Types.TIMESTAMP);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // ── Đánh dấu đã đọc 1 thông báo ──
    public boolean markRead(int notifId, int accountId) {
        String sql = "UPDATE StaffNotifications SET IsRead = 1 "
                + "WHERE NotificationID = ? AND AccountID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, notifId);
            ps.setInt(2, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // ── Đánh dấu tất cả đã đọc ──
    public int markAllRead(int accountId) {
        String sql = "UPDATE StaffNotifications SET IsRead = 1 "
                + "WHERE AccountID = ? AND IsRead = 0";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            return ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); return 0; }
    }

    // ── Xóa thông báo đã đọc cũ hơn X ngày ──
    public int cleanupOld(int daysOld) {
        String sql = "DELETE FROM StaffNotifications "
                + "WHERE IsRead = 1 AND CreatedAt < DATEADD(DAY, -?, GETDATE())";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, daysOld);
            return ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); return 0; }
    }

    // ── Tạo notification cho NHIỀU nhân viên cùng lúc (bulk) ──
    public void insertBulk(int[] accountIds, String type, String title, String message) {
        String sql = "INSERT INTO StaffNotifications(AccountID,Type,Title,Message) VALUES(?,?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            for (int accId : accountIds) {
                ps.setInt(1, accId);
                ps.setString(2, type);
                ps.setString(3, title);
                ps.setString(4, message);
                ps.addBatch();
            }
            ps.executeBatch();
        } catch (Exception e) { e.printStackTrace(); }
    }
}