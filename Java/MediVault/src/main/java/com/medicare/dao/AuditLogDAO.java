package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IAuditLogDAO;
import com.medicare.entity.AuditLog;
import com.medicare.util.MojibakeUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class AuditLogDAO implements IAuditLogDAO {

    // Map đúng cột DB: LogID, AccountID, Action, EntityType, EntityID, Description, IPAddress, CreatedAt
    // JOIN thêm a.Username từ Accounts
    private AuditLog mapRow(ResultSet rs) throws SQLException {
        AuditLog log = new AuditLog();
        log.setLogId(rs.getLong("LogID"));
        log.setAccountId((Integer) rs.getObject("AccountID"));
        // MojibakeUtil.fix(): các dòng cũ ghi TRƯỚC khi sendStringParametersAsUnicode=true được
        // bật ở DBContext bị lưu sai (UTF-8 đọc nhầm thành Windows-1252) — cùng lỗi/cùng cách sửa
        // đã áp dụng ở ShelfDAO, MedicineDAO... DAO này trước đây bị bỏ sót. Dòng ghi MỚI đã đúng
        // ngay từ đầu nên fix() không đụng gì tới chúng (chỉ sửa khi phát hiện đúng mẫu lỗi).
        log.setAction(MojibakeUtil.fix(rs.getString("Action")));
        log.setEntityType(MojibakeUtil.fix(rs.getString("EntityType")));
        log.setEntityId((Integer) rs.getObject("EntityID"));
        log.setDescription(MojibakeUtil.fix(rs.getString("Description")));
        log.setIpAddress(rs.getString("IPAddress"));
        // CreatedAt được lưu theo GETDATE() của SQL Server (UTC trên server host) — cộng 7h
        // để hiển thị đúng giờ Việt Nam, đồng bộ cách InvoiceDAO đang xử lý (xem InvoiceDAO#454).
        if (rs.getTimestamp("CreatedAt") != null)
            log.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime().plusHours(7));
        // Username từ JOIN (có thể null nếu account đã bị xóa)
        try {
            String uname = rs.getString("Username");
            log.setUsername(uname != null ? MojibakeUtil.fix(uname) : "Hệ thống");
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

    // Ghép điều kiện WHERE động cho keyword + khoảng ngày — CHỈ thêm điều kiện nào thực sự
    // có giá trị (không dùng kiểu "? IS NULL OR ..." — xem lý do hiệu năng ở comment cũ bên
    // dưới), để câu không lọc gì vẫn seek được index IX_AuditLog_CreatedAt như trước giờ.
    // fromDate/toDate là chuỗi "yyyy-MM-dd" theo giờ VN; CreatedAt lưu theo giờ server (UTC-ish,
    // hiển thị phải +7h — xem mapRow) nên quy đổi ngược -7h khi so sánh cho đúng mốc giờ VN.
    private void appendDateRange(List<String> conditions, List<String> params, String fromDate, String toDate) {
        if (fromDate != null && !fromDate.trim().isEmpty()) {
            conditions.add("l.CreatedAt >= DATEADD(hour, -7, CAST(? AS DATETIME))");
            params.add(fromDate.trim());
        }
        if (toDate != null && !toDate.trim().isEmpty()) {
            conditions.add("l.CreatedAt < DATEADD(hour, -7, DATEADD(day, 1, CAST(? AS DATETIME)))");
            params.add(toDate.trim());
        }
    }

    @Override
    public List<AuditLog> findPaginated(int page, int pageSize, String keyword, String fromDate, String toDate) {
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
        // Fix: chỉ thêm WHERE khi thực sự có lọc, cho phép seek index IX_AuditLog_CreatedAt
        // (xem database/performance_indexes.sql) qua ORDER BY+OFFSET/FETCH khi không lọc gì.
        List<String> conditions = new ArrayList<>();
        List<String> params = new ArrayList<>();
        if (like != null) {
            conditions.add("(l.Action LIKE ? OR l.EntityType LIKE ? OR l.Description LIKE ? OR a.Username LIKE ?)");
            params.add(like); params.add(like); params.add(like); params.add(like);
        }
        appendDateRange(conditions, params, fromDate, toDate);
        String where = conditions.isEmpty() ? "" : "WHERE " + String.join(" AND ", conditions) + " ";

        String sql = "SELECT l.*, a.Username FROM AuditLog l "
                + "LEFT JOIN Accounts a ON l.AccountID = a.AccountID "
                + where
                + "ORDER BY l.CreatedAt DESC "
                + "OFFSET " + offset + " ROWS FETCH NEXT " + fetch + " ROWS ONLY";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            for (int i = 0; i < params.size(); i++) ps.setString(i + 1, params.get(i));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public int countAll(String keyword, String fromDate, String toDate) {
        String like = (keyword == null || keyword.trim().isEmpty()) ? null : "%" + keyword.trim() + "%";
        boolean hasRange = (fromDate != null && !fromDate.trim().isEmpty())
                || (toDate != null && !toDate.trim().isEmpty());
        // Cùng lý do như findPaginated — không lọc gì thì đếm thẳng COUNT(*) trên AuditLog,
        // cache 15s (bảng chỉ tăng dần, không cần chính xác tuyệt đối tới từng giây) để 2 lần
        // gọi liên tiếp (data + count) trong cùng 1 request không phải quét/đếm 2 lần.
        if (like == null && !hasRange) {
            return com.medicare.config.CacheManager.getShort("auditlog.countAll", this::countAllNoFilter);
        }
        List<String> conditions = new ArrayList<>();
        List<String> params = new ArrayList<>();
        if (like != null) {
            conditions.add("(l.Action LIKE ? OR l.EntityType LIKE ? OR l.Description LIKE ? OR a.Username LIKE ?)");
            params.add(like); params.add(like); params.add(like); params.add(like);
        }
        appendDateRange(conditions, params, fromDate, toDate);
        String sql = "SELECT COUNT(*) FROM AuditLog l "
                + "LEFT JOIN Accounts a ON l.AccountID = a.AccountID "
                + "WHERE " + String.join(" AND ", conditions);
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            for (int i = 0; i < params.size(); i++) ps.setString(i + 1, params.get(i));
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

    // ════════════════════════════════════════════════════════════════════
    //  AUDIT EXPLORER v2 — lọc nhiều chiều + phân trang server-side (30/trang)
    // ════════════════════════════════════════════════════════════════════

    /** Mảnh WHERE cố định cho severity — suy từ Action, KHÔNG dùng input người dùng trực tiếp
     *  trong SQL (switch chỉ trả về 1 trong các mảnh literal cố định, an toàn khỏi injection). */
    private String severitySql(String severity) {
        if (severity == null) return null;
        switch (severity) {
            case "critical": return "(l.Action LIKE N'%Xóa%' OR l.Action LIKE N'%Khóa%')";
            case "warning":  return "(l.Action LIKE N'%Cập nhật%' OR l.Action LIKE N'%Sửa%' OR l.Action LIKE N'%Đặt lại%')";
            case "info":     return "(l.Action LIKE N'%Đăng nhập%' OR l.Action LIKE N'%Đăng xuất%')";
            case "success":  return "(l.Action LIKE N'%Tạo%' OR l.Action LIKE N'%Khôi phục%')";
            case "neutral":  return "(l.Action NOT LIKE N'%Xóa%' AND l.Action NOT LIKE N'%Khóa%' "
                    + "AND l.Action NOT LIKE N'%Cập nhật%' AND l.Action NOT LIKE N'%Sửa%' AND l.Action NOT LIKE N'%Đặt lại%' "
                    + "AND l.Action NOT LIKE N'%Đăng nhập%' AND l.Action NOT LIKE N'%Đăng xuất%' "
                    + "AND l.Action NOT LIKE N'%Tạo%' AND l.Action NOT LIKE N'%Khôi phục%')";
            default: return null;
        }
    }

    /** Module tab → danh sách EntityType THẬT (khảo sát toàn bộ lời gọi AuditHelper.log trong
     *  code) — cố tình KHÔNG bịa thêm tab "POS"/"Invoice"/"Reports"/"Settings" như gợi ý chung
     *  chung, vì hệ thống hiện KHÔNG ghi log cho các module đó (bán hàng qua POS thành công
     *  không gọi AuditHelper.log). Tab rỗng gây hiểu nhầm "audit bị hỏng" nên bỏ hẳn. */
    private static final Map<String, String[]> MODULE_GROUPS = new LinkedHashMap<>();
    static {
        MODULE_GROUPS.put("auth",       new String[]{"Auth"});
        MODULE_GROUPS.put("account",    new String[]{"Account"});
        MODULE_GROUPS.put("inventory",  new String[]{"Batch", "Batches", "PurchaseOrder", "Medicine", "Category", "Manufacturer", "Shelf", "Returns", "WarehouseExport"});
        MODULE_GROUPS.put("supplier",   new String[]{"Supplier"});
        MODULE_GROUPS.put("customer",   new String[]{"Customer"});
        MODULE_GROUPS.put("shift",      new String[]{"Shift", "ShiftSchedule", "ShiftType", "PosStation"});
        MODULE_GROUPS.put("attendance", new String[]{"Attendance"});
        MODULE_GROUPS.put("payroll",    new String[]{"Payroll"});
        MODULE_GROUPS.put("leave",      new String[]{"LeaveRequest"});
        MODULE_GROUPS.put("task",       new String[]{"Tasks"});
    }

    /** Mảnh WHERE cố định cho module tab — chỉ trả literal IN(...) từ MODULE_GROUPS, an toàn
     *  khỏi injection vì moduleKey không được nhúng thẳng, chỉ dùng để TRA BẢNG cố định. */
    private String moduleGroupSql(String moduleKey) {
        String[] types = moduleKey == null ? null : MODULE_GROUPS.get(moduleKey);
        if (types == null || types.length == 0) return null;
        StringBuilder sb = new StringBuilder("l.EntityType IN (");
        for (int i = 0; i < types.length; i++) {
            if (i > 0) sb.append(',');
            sb.append("N'").append(types[i].replace("'", "''")).append('\'');
        }
        return sb.append(')').toString();
    }

    /** Ghép mọi điều kiện lọc của Explorer thành WHERE + danh sách tham số theo đúng thứ tự. */
    private void buildExplorerWhere(List<String> conditions, List<String> params,
            String keyword, String fromDate, String toDate,
            Integer role, String entityType, String severity, Integer accountId, String ip) {
        String like = (keyword == null || keyword.trim().isEmpty()) ? null : "%" + keyword.trim() + "%";
        if (like != null) {
            conditions.add("(l.Action LIKE ? OR l.EntityType LIKE ? OR l.Description LIKE ? OR a.Username LIKE ?)");
            params.add(like); params.add(like); params.add(like); params.add(like);
        }
        appendDateRange(conditions, params, fromDate, toDate);
        if (role != null) {
            conditions.add("a.RoleID = ?");
            params.add(String.valueOf(role));
        }
        String modFrag = moduleGroupSql(entityType);
        if (modFrag != null) conditions.add(modFrag);
        String sevFrag = severitySql(severity);
        if (sevFrag != null) conditions.add(sevFrag);
        if (accountId != null) {
            conditions.add("l.AccountID = ?");
            params.add(String.valueOf(accountId));
        }
        if (ip != null && !ip.trim().isEmpty()) {
            conditions.add("l.IPAddress LIKE ?");
            params.add("%" + ip.trim() + "%");
        }
    }

    @Override
    public List<AuditLog> findFiltered(int page, int pageSize, String keyword, String fromDate, String toDate,
            Integer role, String entityType, String severity, Integer accountId, String ip) {
        List<AuditLog> list = new ArrayList<>();
        int offset = Math.max(0, (page - 1) * pageSize);
        int fetch  = Math.max(1, pageSize);

        List<String> conditions = new ArrayList<>();
        List<String> params = new ArrayList<>();
        buildExplorerWhere(conditions, params, keyword, fromDate, toDate, role, entityType, severity, accountId, ip);
        String where = conditions.isEmpty() ? "" : "WHERE " + String.join(" AND ", conditions) + " ";

        String sql = "SELECT l.*, a.Username FROM AuditLog l "
                + "LEFT JOIN Accounts a ON l.AccountID = a.AccountID "
                + where
                + "ORDER BY l.CreatedAt DESC "
                + "OFFSET " + offset + " ROWS FETCH NEXT " + fetch + " ROWS ONLY";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            for (int i = 0; i < params.size(); i++) ps.setString(i + 1, params.get(i));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public int countFiltered(String keyword, String fromDate, String toDate,
            Integer role, String entityType, String severity, Integer accountId, String ip) {
        List<String> conditions = new ArrayList<>();
        List<String> params = new ArrayList<>();
        buildExplorerWhere(conditions, params, keyword, fromDate, toDate, role, entityType, severity, accountId, ip);
        String where = conditions.isEmpty() ? "" : "WHERE " + String.join(" AND ", conditions);

        String sql = "SELECT COUNT(*) FROM AuditLog l "
                + "LEFT JOIN Accounts a ON l.AccountID = a.AccountID " + where;
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            for (int i = 0; i < params.size(); i++) ps.setString(i + 1, params.get(i));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    @Override
    public AuditLog findById(long logId) {
        String sql = "SELECT l.*, a.Username FROM AuditLog l LEFT JOIN Accounts a ON l.AccountID = a.AccountID WHERE l.LogID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setLong(1, logId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    @Override
    public List<AuditLog> findByAccount(int accountId, long excludeLogId, int limit) {
        List<AuditLog> list = new ArrayList<>();
        String sql = "SELECT TOP (?) l.*, a.Username FROM AuditLog l LEFT JOIN Accounts a ON l.AccountID = a.AccountID "
                + "WHERE l.AccountID = ? AND l.LogID <> ? ORDER BY l.CreatedAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            ps.setInt(2, accountId);
            ps.setLong(3, excludeLogId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public AuditLog[] findPrevNext(long logId) {
        AuditLog[] result = new AuditLog[2]; // [0]=trước (cũ hơn), [1]=sau (mới hơn)
        AuditLog current = findById(logId);
        if (current == null || current.getCreatedAt() == null) return result;
        // CreatedAt hiển thị đã +7h ở mapRow — trừ lại 7h để so đúng với cột lưu trong DB.
        java.time.LocalDateTime raw = current.getCreatedAt().minusHours(7);
        String prevSql = "SELECT TOP 1 l.*, a.Username FROM AuditLog l LEFT JOIN Accounts a ON l.AccountID = a.AccountID "
                + "WHERE l.CreatedAt < ? ORDER BY l.CreatedAt DESC";
        String nextSql = "SELECT TOP 1 l.*, a.Username FROM AuditLog l LEFT JOIN Accounts a ON l.AccountID = a.AccountID "
                + "WHERE l.CreatedAt > ? ORDER BY l.CreatedAt ASC";
        try (Connection cn = DBContext.getConnection()) {
            try (PreparedStatement ps = cn.prepareStatement(prevSql)) {
                ps.setTimestamp(1, Timestamp.valueOf(raw));
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) result[0] = mapRow(rs); }
            }
            try (PreparedStatement ps = cn.prepareStatement(nextSql)) {
                ps.setTimestamp(1, Timestamp.valueOf(raw));
                try (ResultSet rs = ps.executeQuery()) { if (rs.next()) result[1] = mapRow(rs); }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return result;
    }

    @Override
    public Map<Integer, Integer> countByRole() {
        Map<Integer, Integer> map = new LinkedHashMap<>();
        String sql = "SELECT ISNULL(a.RoleID,0) AS RoleID, COUNT(*) AS N FROM AuditLog l "
                + "LEFT JOIN Accounts a ON l.AccountID = a.AccountID GROUP BY a.RoleID";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) map.put(rs.getInt("RoleID"), rs.getInt("N"));
        } catch (Exception e) { e.printStackTrace(); }
        return map;
    }

    @Override
    public Map<String, Integer> countByEntityType() {
        Map<String, Integer> map = new LinkedHashMap<>();
        String sql = "SELECT ISNULL(EntityType,N'Khác') AS T, COUNT(*) AS N FROM AuditLog GROUP BY EntityType";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) map.put(rs.getString("T"), rs.getInt("N"));
        } catch (Exception e) { e.printStackTrace(); }
        return map;
    }

    // ── Dashboard KPI (Section 1) — hôm nay tính theo NGÀY VIỆT NAM, giống appendDateRange ──
    @Override
    public int countToday() {
        String today = java.time.LocalDate.now().toString();
        String sql = "SELECT COUNT(*) FROM AuditLog "
                + "WHERE CreatedAt >= DATEADD(hour,-7,CAST(? AS DATETIME)) "
                + "AND CreatedAt < DATEADD(hour,-7,DATEADD(day,1,CAST(? AS DATETIME)))";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, today); ps.setString(2, today);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) return rs.getInt(1); }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    @Override
    public int countBySeverityToday(String severity) {
        String sevFrag = severitySql(severity);
        if (sevFrag == null) return 0;
        String today = java.time.LocalDate.now().toString();
        String sql = "SELECT COUNT(*) FROM AuditLog l "
                + "WHERE l.CreatedAt >= DATEADD(hour,-7,CAST(? AS DATETIME)) "
                + "AND l.CreatedAt < DATEADD(hour,-7,DATEADD(day,1,CAST(? AS DATETIME))) "
                + "AND " + sevFrag;
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, today); ps.setString(2, today);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) return rs.getInt(1); }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    @Override
    public Map<String, Integer> topUsers(int limit) {
        Map<String, Integer> map = new LinkedHashMap<>();
        String sql = "SELECT TOP (?) ISNULL(a.Username,N'Hệ thống') AS U, COUNT(*) AS N FROM AuditLog l "
                + "LEFT JOIN Accounts a ON l.AccountID = a.AccountID GROUP BY a.Username ORDER BY N DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) map.put(rs.getString("U"), rs.getInt("N"));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return map;
    }

    @Override
    public Map<String, Integer> topIps(int limit) {
        Map<String, Integer> map = new LinkedHashMap<>();
        String sql = "SELECT TOP (?) IPAddress, COUNT(*) AS N FROM AuditLog "
                + "WHERE IPAddress IS NOT NULL AND IPAddress <> '' GROUP BY IPAddress ORDER BY N DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) map.put(rs.getString("IPAddress"), rs.getInt("N"));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return map;
    }

    @Override
    public int[] hourlyToday() {
        int[] hours = new int[24];
        String today = java.time.LocalDate.now().toString();
        // Giờ VN = giờ lưu DB + 7h (xem mapRow) — cộng 7 vào DATEPART(HOUR,...) rồi %24.
        String sql = "SELECT DATEPART(HOUR, CreatedAt) AS H, COUNT(*) AS N FROM AuditLog "
                + "WHERE CreatedAt >= DATEADD(hour,-7,CAST(? AS DATETIME)) "
                + "AND CreatedAt < DATEADD(hour,-7,DATEADD(day,1,CAST(? AS DATETIME))) "
                + "GROUP BY DATEPART(HOUR, CreatedAt)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, today); ps.setString(2, today);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    int h = (rs.getInt("H") + 7) % 24;
                    hours[h] += rs.getInt("N");
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return hours;
    }

    @Override
    public List<AuditLog> findSince(long sinceId, int limit) {
        List<AuditLog> list = new ArrayList<>();
        if (sinceId <= 0) return list;
        String sql = "SELECT TOP (?) l.*, a.Username FROM AuditLog l LEFT JOIN Accounts a ON l.AccountID = a.AccountID "
                + "WHERE l.LogID > ? ORDER BY l.LogID DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, Math.max(1, limit));
            ps.setLong(2, sinceId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public int countUniqueUsersToday() {
        String today = java.time.LocalDate.now().toString();
        String sql = "SELECT COUNT(DISTINCT AccountID) FROM AuditLog "
                + "WHERE AccountID IS NOT NULL "
                + "AND CreatedAt >= DATEADD(hour,-7,CAST(? AS DATETIME)) "
                + "AND CreatedAt < DATEADD(hour,-7,DATEADD(day,1,CAST(? AS DATETIME)))";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, today); ps.setString(2, today);
            try (ResultSet rs = ps.executeQuery()) { if (rs.next()) return rs.getInt(1); }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }
}