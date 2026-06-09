package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.dao.interfaces.IStaffAuditLogDAO;
import com.medivault.entity.StaffAuditLog;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class StaffAuditLogDAO implements IStaffAuditLogDAO {

    @Override
    public boolean log(StaffAuditLog log) {
        String sql = "INSERT INTO StaffAuditLogs (AccountID, Action, Details, IPAddress) VALUES (?, ?, ?, ?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, log.getAccountId());
            ps.setNString(2, log.getAction());
            ps.setNString(3, log.getDetails());
            ps.setString(4, log.getIpAddress());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    @Override
    public List<StaffAuditLog> findRecentByAccount(int accountId, int limit) {
        List<StaffAuditLog> list = new ArrayList<>();
        String sql = "SELECT TOP (?) LogID, AccountID, Action, Details, IPAddress, CreatedAt " +
                "FROM StaffAuditLogs WHERE AccountID = ? ORDER BY CreatedAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            ps.setInt(2, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    StaffAuditLog log = new StaffAuditLog();
                    log.setLogId(rs.getInt("LogID"));
                    log.setAccountId(rs.getInt("AccountID"));
                    log.setAction(rs.getNString("Action"));
                    log.setDetails(rs.getNString("Details"));
                    log.setIpAddress(rs.getString("IPAddress"));
                    if (rs.getTimestamp("CreatedAt") != null)
                        log.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
                    list.add(log);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }
}