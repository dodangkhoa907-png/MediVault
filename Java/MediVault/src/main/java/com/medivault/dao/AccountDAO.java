package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.entity.Account;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class AccountDAO {

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

    // LoginServlet dùng cái này
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

    public boolean insert(Account a) {
        String sql = "INSERT INTO Accounts (Username, PasswordHash, FullName, " +
                "Email, Phone, RoleID, CitizenId, Position, IsActive) " +
                "VALUES (?,?,?,?,?,?,?,?,1)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, a.getUsername());
            ps.setString(2, a.getPasswordHash());
            ps.setString(3, a.getFullName());
            ps.setString(4, a.getEmail());
            ps.setString(5, a.getPhone());
            ps.setInt(6, a.getRoleId());
            ps.setString(7, a.getCitizenId());
            ps.setString(8, a.getPosition());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

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
        String sql = "UPDATE Accounts SET PasswordHash = ? WHERE AccountID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, newHash);
            ps.setInt(2, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}