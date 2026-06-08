package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.dao.interfaces.IAuditLogDAO;
import com.medivault.entity.AuditLog;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class AuditLogDAO implements IAuditLogDAO {

    // Map đúng cột DB: LogID, AccountID, Action, EntityType, EntityID, Description, IPAddress, CreatedAt
    // JOIN thêm a.Username từ Accounts
    private AuditLog mapRow(ResultSet rs) throws SQLException {
        AuditLog log = new AuditLog();
        log.setLogId(rs.getLong("LogID"));
        log.setAccountId((Integer) rs.getObject("AccountID"));
        log.setAction(rs.getString("Action"));
        log.setEntityType(rs.getString("EntityType"));
        log.setEntityId((Integer) rs.getObject("EntityID"));
        log.setDescription(rs.getNString("Description"));
        log.setIpAddress(rs.getString("IPAddress"));
        if (rs.getTimestamp("CreatedAt") != null)
            log.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
        // Username từ JOIN (có thể null nếu account đã bị xóa)
        try {
            String uname = rs.getString("Username");
            log.setUsername(uname != null ? uname : "Hệ thống");
        } catch (SQLException ignored) {
            log.setUsername("Hệ thống");
        }
        return log;
    }

    @Override
    public boolean insert(AuditLog log) {
        String sql = "INSERT INTO AuditLog (AccountID, Action, EntityType, EntityID, Description, IPAddress) "
                + "VALUES (?, ?, ?, ?, ?, ?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            if (log.getAccountId() != null) ps.setInt(1, log.getAccountId());
            else ps.setNull(1, Types.INTEGER);
            ps.setString(2, log.getAction());
            ps.setString(3, log.getEntityType());
            if (log.getEntityId() != null) ps.setInt(4, log.getEntityId());
            else ps.setNull(4, Types.INTEGER);
            ps.setNString(5, log.getDescription());
            ps.setString(6, log.getIpAddress());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public List<AuditLog> findPaginated(int page, int pageSize, String keyword) {
        List<AuditLog> list = new ArrayList<>();
        int offset = (page - 1) * pageSize;
        String sql = "SELECT l.*, a.Username FROM AuditLog l "
                + "LEFT JOIN Accounts a ON l.AccountID = a.AccountID "
                + "WHERE (? IS NULL OR l.Action LIKE ? OR l.EntityType LIKE ? "
                + "  OR l.Description LIKE ? OR a.Username LIKE ?) "
                + "ORDER BY l.CreatedAt DESC "
                + "OFFSET ? ROWS FETCH NEXT ? ROWS ONLY";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            String like = (keyword == null || keyword.trim().isEmpty())
                    ? null : "%" + keyword.trim() + "%";
            ps.setString(1, like); ps.setString(2, like);
            ps.setString(3, like); ps.setString(4, like);
            ps.setString(5, like);
            ps.setInt(6, offset); ps.setInt(7, pageSize);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public int countAll(String keyword) {
        String sql = "SELECT COUNT(*) FROM AuditLog l "
                + "LEFT JOIN Accounts a ON l.AccountID = a.AccountID "
                + "WHERE (? IS NULL OR l.Action LIKE ? OR l.EntityType LIKE ? "
                + "  OR l.Description LIKE ? OR a.Username LIKE ?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            String like = (keyword == null || keyword.trim().isEmpty())
                    ? null : "%" + keyword.trim() + "%";
            ps.setString(1, like); ps.setString(2, like);
            ps.setString(3, like); ps.setString(4, like);
            ps.setString(5, like);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }
}