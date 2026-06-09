package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.dao.interfaces.IAccountDAO;
import com.medivault.entity.Account;
import com.medivault.util.ValidationUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class AccountDAO implements IAccountDAO {

    private Account mapRow(ResultSet rs) throws SQLException {
        Account a = new Account();
        a.setAccountId(rs.getInt("AccountID"));
        a.setUsername(rs.getString("Username"));
        a.setPasswordHash(rs.getString("PasswordHash"));
        a.setFullName(rs.getString("FullName"));
        a.setEmail(rs.getString("Email"));
        a.setPhone(rs.getString("Phone"));
        a.setRoleId(rs.getInt("RoleID"));
        a.setActive(rs.getBoolean("IsActive"));
        a.setCitizenId(rs.getString("CitizenId"));
        a.setPosition(rs.getString("Position"));
        a.setProfessionalCertNo(rs.getString("ProfessionalCertNo"));
        a.setDeleted(rs.getBoolean("IsDeleted"));
        if (rs.getTimestamp("DeletedAt") != null)
            a.setDeletedAt(rs.getTimestamp("DeletedAt").toLocalDateTime());
        if (rs.getDate("ProfessionalCertExp") != null)
            a.setProfessionalCertExp(rs.getDate("ProfessionalCertExp").toLocalDate());
        if (rs.getDate("TrainingDate") != null)
            a.setTrainingDate(rs.getDate("TrainingDate").toLocalDate());
        a.setFaceEnrollmentPath(rs.getString("FaceEnrollmentPath"));
        if (rs.getTimestamp("CreatedAt") != null)
            a.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
        if (rs.getTimestamp("LastLoginAt") != null)
            a.setLastLoginAt(rs.getTimestamp("LastLoginAt").toLocalDateTime());
        return a;
    }

    // ================================================================
    // VALIDATE trước khi insert/update
    // ================================================================

    /**
     * Kiểm tra tính hợp lệ của Account.
     * Servlet gọi cái này trước khi gọi insert/update.
     * Trả về danh sách lỗi — rỗng = OK.
     */
    public List<String> validate(Account a) {
        return ValidationUtil.validateAccount(
                a.getUsername(),
                a.getFullName(),
                a.getEmail(),
                a.getPhone(),
                a.getCitizenId(),
                a.getPosition()
        );
    }

    /**
     * Kiểm tra username đã tồn tại chưa (dùng khi tạo mới).
     */
    public boolean isUsernameTaken(String username) {
        String sql = "SELECT 1 FROM Accounts WHERE Username = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, username.trim());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next(); // true = đã tồn tại
            }
        } catch (Exception e) { e.printStackTrace(); }
        return false;
    }

    /**
     * Kiểm tra email đã tồn tại chưa (dùng khi tạo mới hoặc cập nhật).
     * excludeId: bỏ qua account hiện tại khi update (truyền -1 khi insert)
     */
    public boolean isEmailTaken(String email, int excludeId) {
        if (email == null || email.trim().isEmpty()) return false;
        String sql = "SELECT 1 FROM Accounts WHERE Email = ? AND AccountID != ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, email.trim());
            ps.setInt(2, excludeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (Exception e) { e.printStackTrace(); }
        return false;
    }

    // ================================================================
    // QUERIES
    // ================================================================

    public Account findByUsername(String username) {
        String sql = "SELECT * FROM Accounts WHERE Username = ? AND IsActive = 1 AND IsDeleted = 0";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    /** Tìm kể cả TK bị khóa (IsActive=0) — dùng cho staff-login để phát hiện TK bị khóa */
    @Override
    public Account findByUsernameAny(String username) {
        String sql = "SELECT * FROM Accounts WHERE Username = ? AND IsDeleted = 0";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    public Account findById(int id) {
        String sql = "SELECT * FROM Accounts WHERE AccountID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    public List<Account> findAll() {
        List<Account> list = new ArrayList<>();
        String sql = "SELECT * FROM Accounts WHERE IsDeleted = 0 ORDER BY FullName";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public List<Account> findAllStaff() {
        List<Account> list = new ArrayList<>();
        String sql = "SELECT * FROM Accounts WHERE RoleID != 1 AND IsDeleted = 0 ORDER BY FullName";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    // ================================================================
    // INSERT — validate trước khi lưu
    // ================================================================

    /**
     * Tạo tài khoản mới.
     * Servlet PHẢI gọi validate() + isUsernameTaken() trước khi gọi insert().
     */
    public boolean insert(Account a) {
        // Double-check validate tại DAO (bảo vệ tầng thứ 2)
        List<String> errors = validate(a);
        if (!errors.isEmpty()) {
            System.err.println("[AccountDAO] insert thất bại — lỗi validate: "
                    + ValidationUtil.joinErrors(errors));
            return false;
        }

        String sql = "INSERT INTO Accounts " +
                "(Username, PasswordHash, FullName, Email, Phone, RoleID, CitizenId, Position, IsActive) " +
                "VALUES (?,?,?,?,?,?,?,?,1)";

        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, a.getUsername().trim());
            ps.setString(2, a.getPasswordHash());
            ps.setString(3, a.getFullName().trim());
            ps.setString(4, a.getEmail() != null ? a.getEmail().trim() : null);
            ps.setString(5, a.getPhone() != null ? a.getPhone().trim() : null);
            ps.setInt(6, a.getRoleId());
            ps.setString(7, a.getCitizenId() != null ? a.getCitizenId().trim() : null);
            ps.setString(8, a.getPosition() != null ? a.getPosition().trim() : null);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // ================================================================
    // UPDATE — validate trước khi lưu
    // ================================================================

    /**
     * Cập nhật thông tin tài khoản.
     * Không cho đổi Username và PasswordHash ở đây (có method riêng).
     */
    public boolean update(Account a) {
        // Validate chỉ các field có trong form edit (không validate username vì không đổi được)
        if (a.getFullName() == null || a.getFullName().trim().isEmpty()) {
            System.err.println("[AccountDAO] update thất bại — FullName trống");
            return false;
        }
        String sql = "UPDATE Accounts SET " +
                "FullName=?, Email=?, Phone=?, RoleID=?, CitizenId=?, Position=?, " +
                "ProfessionalCertNo=?, ProfessionalCertExp=?, TrainingDate=? " +
                "WHERE AccountID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, a.getFullName().trim());
            ps.setString(2, a.getEmail() != null ? a.getEmail().trim() : null);
            ps.setString(3, a.getPhone() != null ? a.getPhone().trim() : null);
            ps.setInt(4, a.getRoleId());
            ps.setString(5, a.getCitizenId() != null ? a.getCitizenId().trim() : null);
            ps.setString(6, a.getPosition() != null ? a.getPosition().trim() : null);
            // 3 field chuyên môn — nullable
            ps.setString(7, a.getProfessionalCertNo());
            if (a.getProfessionalCertExp() != null)
                ps.setDate(8, java.sql.Date.valueOf(a.getProfessionalCertExp()));
            else ps.setNull(8, java.sql.Types.DATE);
            if (a.getTrainingDate() != null)
                ps.setDate(9, java.sql.Date.valueOf(a.getTrainingDate()));
            else ps.setNull(9, java.sql.Types.DATE);
            ps.setInt(10, a.getAccountId());
            int rows = ps.executeUpdate();
            System.out.println("[AccountDAO] update accountId=" + a.getAccountId() + " → rows=" + rows);
            return rows > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // ================================================================
    // CÁC METHOD KHÁC
    // ================================================================

    public boolean updateLastLogin(int accountId) {
        String sql = "UPDATE Accounts SET LastLoginAt = GETDATE() WHERE AccountID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }


    /** Đếm số tài khoản Admin đang active — dùng để bảo vệ admin cuối cùng */
    public int countActiveAdmins() {
        String sql = "SELECT COUNT(*) FROM Accounts WHERE RoleID = 1 AND IsActive = 1";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }


    /** Soft delete — đánh dấu xóa, giữ trong DB 30 ngày */
    public boolean softDelete(int accountId) {
        String sql = "UPDATE Accounts SET IsDeleted = 1, DeletedAt = GETDATE() WHERE AccountID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Khôi phục tài khoản đã soft delete */
    public boolean restore(int accountId) {
        String sql = "UPDATE Accounts SET IsDeleted = 0, DeletedAt = NULL WHERE AccountID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Hard delete — xóa vĩnh viễn (chỉ dùng sau 30 ngày) */
    public boolean hardDelete(int accountId) {
        String sql = "DELETE FROM Accounts WHERE AccountID = ? AND IsDeleted = 1 " +
                "AND DATEDIFF(day, DeletedAt, GETDATE()) >= 30";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Lấy danh sách đã soft delete — trang thùng rác */
    public List<Account> findDeleted() {
        List<Account> list = new ArrayList<>();
        String sql = "SELECT * FROM Accounts WHERE IsDeleted = 1 ORDER BY DeletedAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public boolean toggleActive(int accountId) {
        String sql = "UPDATE Accounts SET IsActive = 1 - IsActive WHERE AccountID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    public boolean resetPassword(int accountId, String newHash) {
        // Không cần validate hash vì đã qua PasswordUtil.hashPassword()
        String sql = "UPDATE Accounts SET PasswordHash = ? WHERE AccountID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, newHash);
            ps.setInt(2, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Force delete — xóa vĩnh viễn NGAY (không cần đủ 30 ngày, dành cho admin) */
    /**
     * Xóa vĩnh viễn tài khoản (đã trong thùng rác).
     * Xử lý FK constraints trước khi DELETE:
     *   - Xóa PasswordResetRequests (không có giá trị lưu trữ)
     *   - SET NULL cho AuditLogs (lịch sử vẫn giữ, chỉ mất tên người dùng)
     *   - Các bảng kinh doanh (Invoices, Shifts...) giữ nguyên — không xóa
     */
    public boolean forceDelete(int accountId) {
        java.sql.Connection cn = null;
        try {
            cn = DBContext.getConnection();
            cn.setAutoCommit(false);

            // 1. Xóa PasswordResetRequests — không có giá trị lưu trữ
            try (java.sql.PreparedStatement ps = cn.prepareStatement(
                    "DELETE FROM PasswordResetRequests WHERE AccountID = ?")) {
                ps.setInt(1, accountId); ps.executeUpdate();
            }

            // 2. SET NULL cho AuditLogs (nullable, giữ lịch sử)
            try (java.sql.PreparedStatement ps = cn.prepareStatement(
                    "UPDATE AuditLogs SET AccountID = NULL WHERE AccountID = ?")) {
                ps.setInt(1, accountId); ps.executeUpdate();
            }

            // 3. SET NULL cho các bảng nullable khác nếu có
            for (String tbl : new String[]{"PointTransactions", "OrderLogs"}) {
                try (java.sql.PreparedStatement ps = cn.prepareStatement(
                        "UPDATE " + tbl + " SET AccountID = NULL WHERE AccountID = ?")) {
                    ps.setInt(1, accountId); ps.executeUpdate();
                } catch (Exception ignored) { /* bảng có thể chưa có */ }
            }

            // 4. Xóa tài khoản
            try (java.sql.PreparedStatement ps = cn.prepareStatement(
                    "DELETE FROM Accounts WHERE AccountID = ? AND IsDeleted = 1")) {
                ps.setInt(1, accountId);
                int rows = ps.executeUpdate();
                if (rows == 0) { cn.rollback(); return false; }
            }

            cn.commit();
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            if (cn != null) { try { cn.rollback(); } catch (Exception ignored) {} }
            return false;
        } finally {
            if (cn != null) { try { cn.setAutoCommit(true); cn.close(); } catch (Exception ignored) {} }
        }
    }
    public boolean updateAvatar(int accountId, String path) {
        String sql = "UPDATE Accounts SET FaceEnrollmentPath = ? WHERE AccountID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, path);
            ps.setInt(2, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}