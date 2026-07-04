package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IPurchaseOrderDAO;
import com.medicare.entity.Batches;
import com.medicare.entity.PurchaseOrders;
import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
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
        try { po.setStatus(rs.getString("Status")); } catch (SQLException ignored) {}
        try { po.setPaymentMethod(rs.getString("PaymentMethod")); } catch (SQLException ignored) {}
        try { po.setDiscountAmount(rs.getBigDecimal("DiscountAmount")); } catch (SQLException ignored) {}
        return po;
    }

    /**
     * Tạo phiếu nhập nhiều dòng trong 1 TRANSACTION: insert 1 PurchaseOrder rồi
     * insert N Batches (mỗi dòng = 1 lô). Toàn bộ thành công hoặc rollback hết.
     * POCode là computed ('PN'+POID) nên KHÔNG set. Trả về POID mới, -1 nếu lỗi.
     */
    public int createWithBatches(PurchaseOrders po, List<Batches> lines) {
        String poSql = "INSERT INTO PurchaseOrders " +
                "(SupplierID, AccountID, OrderDate, TotalValue, Notes, Status, PaymentMethod, DiscountAmount) " +
                "VALUES (?,?,GETDATE(),?,?,?,?,?); SELECT SCOPE_IDENTITY();";
        String bSql = "INSERT INTO Batches (MedicineID, POID, SupplierID, BatchNumber, " +
                "ManufactureDate, ImportDate, ExpiryDate, ImportPrice, InitialQuantity, CurrentQuantity) " +
                "VALUES (?,?,?,?,?,?,?,?,?,?)";
        Connection cn = null;
        try {
            cn = DBContext.getConnection();
            cn.setAutoCommit(false);
            int poId;
            try (PreparedStatement ps = cn.prepareStatement(poSql)) {
                ps.setInt(1, po.getSupplierId());
                ps.setInt(2, po.getAccountId());
                ps.setBigDecimal(3, po.getTotalValue() != null ? po.getTotalValue() : BigDecimal.ZERO);
                ps.setNString(4, po.getNotes());
                ps.setString(5, po.getStatus() != null ? po.getStatus() : "COMPLETED");
                if (po.getPaymentMethod() != null && !po.getPaymentMethod().isEmpty())
                    ps.setString(6, po.getPaymentMethod());
                else ps.setNull(6, Types.VARCHAR);
                ps.setBigDecimal(7, po.getDiscountAmount() != null ? po.getDiscountAmount() : BigDecimal.ZERO);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next() || rs.getBigDecimal(1) == null) { cn.rollback(); return -1; }
                    poId = rs.getBigDecimal(1).intValue();
                }
            }
            try (PreparedStatement ps = cn.prepareStatement(bSql)) {
                for (Batches b : lines) {
                    ps.setInt(1, b.getMedicineId());
                    ps.setInt(2, poId);
                    ps.setInt(3, po.getSupplierId());
                    ps.setString(4, b.getBatchNumber());
                    ps.setObject(5, b.getManufactureDate() != null ? Date.valueOf(b.getManufactureDate()) : null);
                    ps.setDate(6, b.getImportDate() != null ? Date.valueOf(b.getImportDate()) : Date.valueOf(LocalDate.now()));
                    ps.setDate(7, Date.valueOf(b.getExpiryDate()));
                    ps.setBigDecimal(8, b.getImportPrice());
                    ps.setInt(9, b.getInitialQuantity());
                    ps.setInt(10, b.getInitialQuantity());
                    ps.addBatch();
                }
                ps.executeBatch();
            }
            cn.commit();
            return poId;
        } catch (Exception e) {
            e.printStackTrace();
            if (cn != null) try { cn.rollback(); } catch (Exception ignored) {}
            return -1;
        } finally {
            if (cn != null) try { cn.setAutoCommit(true); cn.close(); } catch (Exception ignored) {}
        }
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