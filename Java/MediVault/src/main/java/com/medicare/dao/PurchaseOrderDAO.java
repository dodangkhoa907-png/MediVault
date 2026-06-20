package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IPurchaseOrderDAO;
import com.medicare.entity.PurchaseOrders;
import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class PurchaseOrderDAO implements IPurchaseOrderDAO {

    private PurchaseOrders mapRow(ResultSet rs) throws SQLException {
        PurchaseOrders po = new PurchaseOrders();
        po.setPoId(rs.getInt("POID"));
        po.setPoCode(rs.getString("POCode"));
        po.setSupplierId(rs.getInt("SupplierID"));
        po.setAccountId(rs.getInt("AccountID"));
        if (rs.getTimestamp("OrderDate") != null)
            po.setOrderDate(rs.getTimestamp("OrderDate").toLocalDateTime());
        po.setTotalValue(rs.getBigDecimal("TotalValue"));
        po.setNotes(rs.getNString("Notes"));
        return po;
    }

    @Override
    public int insert(PurchaseOrders po) {
        String sql = "INSERT INTO PurchaseOrders (SupplierID, AccountID, Notes) " +
                "VALUES (?,?,?); SELECT SCOPE_IDENTITY();";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, po.getSupplierId());
            ps.setInt(2, po.getAccountId());
            ps.setNString(3, po.getNotes());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return -1;
    }

    @Override
    public PurchaseOrders findById(int id) {
        String sql = "SELECT * FROM PurchaseOrders WHERE POID = ?";
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
    public List<PurchaseOrders> findAll() {
        List<PurchaseOrders> list = new ArrayList<>();
        String sql = "SELECT * FROM PurchaseOrders ORDER BY OrderDate DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<PurchaseOrders> findRecent(int limit) {
        List<PurchaseOrders> list = new ArrayList<>();
        String sql = "SELECT TOP (?) * FROM PurchaseOrders ORDER BY OrderDate DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public int countBatches(int poId) {
        String sql = "SELECT COUNT(*) FROM Batches WHERE POID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, poId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    @Override
    public boolean recalcTotalValue(int poId) {
        String sql = "UPDATE PurchaseOrders SET TotalValue = (" +
                "  SELECT ISNULL(SUM(ImportPrice * InitialQuantity), 0) FROM Batches WHERE POID = ?" +
                ") WHERE POID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, poId);
            ps.setInt(2, poId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}