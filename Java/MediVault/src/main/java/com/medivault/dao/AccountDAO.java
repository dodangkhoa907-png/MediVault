package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.entity.Account;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class AccountDAO {

    // Hàm chuyển đổi dòng dữ liệu từ Database thành Đối tượng Java
    private Account mapRow(ResultSet rs) throws SQLException {
        Account a = new Account();
        a.setAccountId(rs.getInt("AccountID"));
        a.setUsername(rs.getString("Username"));
        a.setFullName(rs.getString("FullName"));
        a.setEmail(rs.getString("Email"));
        a.setPhone(rs.getString("Phone"));
        a.setCitizenId(rs.getString("CitizenID"));
        a.setPosition(rs.getString("Position"));
        a.setRoleId(rs.getInt("RoleID"));
        a.setActive(rs.getBoolean("IsActive"));
        a.setDeleted(rs.getBoolean("IsDeleted"));

        // ĐÃ THÊM: Ánh xạ cột trạng thái chờ khôi phục mật khẩu từ CSDL
        a.setPendingReset(rs.getBoolean("IsPendingReset"));

        a.setProfessionalCertNo(rs.getString("ProfessionalCertNo"));
        a.setFaceEnrollmentPath(rs.getString("FaceEnrollmentPath"));
        a.setCreatedAt(rs.getTimestamp("CreatedAt"));
        a.setLastLoginAt(rs.getTimestamp("LastLoginAt"));
        return a;
    }

    // Tự động Khóa và Bật cờ chờ Reset khi nhân viên bấm Quên mật khẩu
    public boolean lockAndSetPendingReset(String usernameOrEmail) {
        String sql = "UPDATE Accounts SET IsActive = 0, IsPendingReset = 1 WHERE Username = ? OR Email = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, usernameOrEmail);
            ps.setString(2, usernameOrEmail);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }

    // Hàm lấy thông tin chi tiết một tài khoản bằng ID
    public Account findById(int id) {
        String sql = "SELECT * FROM Accounts WHERE AccountID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return null;
    }

    // Đảo trạng thái kích hoạt (0 thành 1, hoặc 1 thành 0)
    public void toggleActive(int id) {
        String sql = "UPDATE Accounts SET IsActive = CASE WHEN IsActive = 1 THEN 0 ELSE 1 END WHERE AccountID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }

    // Đếm số lượng Admin tối cao đang hoạt động (Để tránh việc Admin tự khóa chính mình)
    public int countActiveAdmins() {
        String sql = "SELECT COUNT(*) FROM Accounts WHERE RoleID = 1 AND IsActive = 1 AND IsDeleted = 0";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return 0;
    }
}