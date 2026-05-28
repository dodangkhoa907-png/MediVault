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
        String sql = "SELECT * FROM Accounts WHERE Username = ? AND IsActive = 1";
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
        String sql = "SELECT * FROM Accounts ORDER BY FullName";
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
        List<String> errors = ValidationUtil.validateAccount(
                a.getUsername(), a.getFullName(),
                a.getEmail(), a.getPhone(),
                a.getCitizenId(), a.getPosition()
        );
        if (!errors.isEmpty()) {
            System.err.println("[AccountDAO] update thất bại — lỗi validate: "
                    + ValidationUtil.joinErrors(errors));
            return false;
        }

        String sql = "UPDATE Accounts SET " +
                "FullName=?, Email=?, Phone=?, RoleID=?, CitizenId=?, Position=? " +
                "WHERE AccountID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, a.getFullName().trim());
            ps.setString(2, a.getEmail() != null ? a.getEmail().trim() : null);
            ps.setString(3, a.getPhone() != null ? a.getPhone().trim() : null);
            ps.setInt(4, a.getRoleId());
            ps.setString(5, a.getCitizenId() != null ? a.getCitizenId().trim() : null);
            ps.setString(6, a.getPosition() != null ? a.getPosition().trim() : null);
            ps.setInt(7, a.getAccountId());
            return ps.executeUpdate() > 0;
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
}