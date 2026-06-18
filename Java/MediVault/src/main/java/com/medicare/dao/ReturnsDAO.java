package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IReturnsDAO;
import com.medicare.entity.Returns;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ReturnsDAO implements IReturnsDAO {

    private Returns mapRow(ResultSet rs) throws SQLException {
        Returns r = new Returns();
        r.setReturnId(rs.getInt("ReturnID"));
        r.setReturnType(rs.getString("ReturnType"));
        r.setBatchId(rs.getInt("BatchID"));
        int invId = rs.getInt("InvoiceID");
        r.setInvoiceId(rs.wasNull() ? null : invId);
        r.setQuantity(rs.getInt("Quantity"));
        r.setReason(rs.getNString("Reason"));
        r.setAccountId(rs.getInt("AccountID"));
        r.setRestoreStock(rs.getBoolean("RestoreStock"));
        if (rs.getTimestamp("CreatedAt") != null)
            r.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
        return r;
    }

    @Override
    public int insert(Returns r) {
        String sql = "INSERT INTO Returns (ReturnType, BatchID, InvoiceID, Quantity, Reason, AccountID, RestoreStock) " +
                "VALUES (?,?,?,?,?,?,?); SELECT SCOPE_IDENTITY();";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, r.getReturnType());
            ps.setInt(2, r.getBatchId());
            if (r.getInvoiceId() != null) ps.setInt(3, r.getInvoiceId()); else ps.setNull(3, Types.INTEGER);
            ps.setInt(4, r.getQuantity());
            ps.setNString(5, r.getReason());
            ps.setInt(6, r.getAccountId());
            ps.setBoolean(7, r.isRestoreStock());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return -1;
    }

    @Override
    public Returns findById(int id) {
        String sql = "SELECT * FROM Returns WHERE ReturnID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    @Override
    public List<Returns> findAll() {
        List<Returns> list = new ArrayList<>();
        String sql = "SELECT * FROM Returns ORDER BY CreatedAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<Returns> findByInvoice(int invoiceId) {
        List<Returns> list = new ArrayList<>();
        String sql = "SELECT * FROM Returns WHERE InvoiceID = ? ORDER BY CreatedAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, invoiceId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public int sumReturnedQty(int invoiceId, int batchId) {
        String sql = "SELECT ISNULL(SUM(Quantity), 0) FROM Returns " +
                "WHERE InvoiceID = ? AND BatchID = ? AND ReturnType = 'CUSTOMER_RETURN'";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, invoiceId);
            ps.setInt(2, batchId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }
}