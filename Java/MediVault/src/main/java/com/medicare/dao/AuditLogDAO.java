package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IAuditLogDAO;
import com.medicare.entity.AuditLog;
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
        log.setDescription(rs.getString("Description"));
        log.setIpAddress(rs.getString("IPAddress"));
        // CreatedAt được lưu theo GETDATE() của SQL Server (UTC trên server host) — cộng 7h
        // để hiển thị đúng giờ Việt Nam, đồng bộ cách InvoiceDAO đang xử lý (xem InvoiceDAO#454).
        if (rs.getTimestamp("CreatedAt") != null)
            log.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime().plusHours(7));
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
            ps.setNString(2, log.getAction());
            ps.setNString(3, log.getEntityType());
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
        // offset & pageSize là INT nội bộ (không phải input người dùng) → nhúng thẳng an toàn.
        // Tránh lỗi driver mssql-jdbc trả 0 dòng khi OFFSET/FETCH bị tham số hóa (? ROWS).
        int offset = Math.max(0, (page - 1) * pageSize);
        int fetch  = Math.max(1, pageSize);
        String like = (keyword == null || keyword.trim().isEmpty()) ? null : "%" + keyword.trim() + "%";

        // QUAN TRỌNG: "WHERE (? IS NULL OR col LIKE ?)" buộc SQL Server phải build 1 plan
        // "an toàn cho mọi trường hợp" — gần như luôn chọn SCAN toàn bảng AuditLog thay vì
        // SEEK theo CreatedAt, kể cả khi keyword=null (trường hợp phổ biến NHẤT — mỗi lần
        // vào trang không tìm kiếm gì). Bảng này phình nhanh nhất hệ thống (mọi thao tác admin
        // đều insert vào đây) nên đây chính là nguyên nhân "cực lag" khi vào /audit-logs.
        // Fix: tách hẳn 2 câu SQL — không keyword thì KHÔNG có WHERE, cho phép seek index
        // IX_AuditLog_CreatedAt (xem database/performance_indexes.sql) qua ORDER BY+OFFSET/FETCH.
        String sql = like == null
                ? "SELECT l.*, a.Username FROM AuditLog l "
                  + "LEFT JOIN Accounts a ON l.AccountID = a.AccountID "
                  + "ORDER BY l.CreatedAt DESC "
                  + "OFFSET " + offset + " ROWS FETCH NEXT " + fetch + " ROWS ONLY"
                : "SELECT l.*, a.Username FROM AuditLog l "
                  + "LEFT JOIN Accounts a ON l.AccountID = a.AccountID "
                  + "WHERE l.Action LIKE ? OR l.EntityType LIKE ? "
                  + "  OR l.Description LIKE ? OR a.Username LIKE ? "
                  + "ORDER BY l.CreatedAt DESC "
                  + "OFFSET " + offset + " ROWS FETCH NEXT " + fetch + " ROWS ONLY";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            if (like != null) {
                ps.setString(1, like); ps.setString(2, like);
                ps.setString(3, like); ps.setString(4, like);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public int countAll(String keyword) {
        String like = (keyword == null || keyword.trim().isEmpty()) ? null : "%" + keyword.trim() + "%";
        // Cùng lý do như findPaginated — không keyword thì đếm thẳng COUNT(*) trên AuditLog,
        // cache 15s (bảng chỉ tăng dần, không cần chính xác tuyệt đối tới từng giây) để 2 lần
        // gọi liên tiếp (data + count) trong cùng 1 request không phải quét/đếm 2 lần.
        if (like == null) {
            return com.medicare.config.CacheManager.getShort("auditlog.countAll", this::countAllNoFilter);
        }
        String sql = "SELECT COUNT(*) FROM AuditLog l "
                + "LEFT JOIN Accounts a ON l.AccountID = a.AccountID "
                + "WHERE l.Action LIKE ? OR l.EntityType LIKE ? "
                + "  OR l.Description LIKE ? OR a.Username LIKE ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, like); ps.setString(2, like);
            ps.setString(3, like); ps.setString(4, like);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    private int countAllNoFilter() {
        String sql = "SELECT COUNT(*) FROM AuditLog";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }
}