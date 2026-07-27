package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IStockMovementsDAO;
import com.medicare.entity.StockMovements;

import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * StockMovementsDAO — Sổ cái nhập/xuất/điều chỉnh kho.
 * Xem {@link IStockMovementsDAO} về MovementType hợp lệ.
 */
public class StockMovementsDAO implements IStockMovementsDAO {

    private StockMovements mapRow(ResultSet rs) throws SQLException {
        StockMovements m = new StockMovements();
        m.setMovementId(rs.getInt("MovementID"));
        m.setBatchId(rs.getInt("BatchID"));
        m.setMovementType(rs.getString("MovementType"));
        m.setQuantity(rs.getInt("Quantity"));
        m.setRefTable(rs.getString("RefTable"));
        m.setRefId((Integer) rs.getObject("RefID"));
        m.setAccountId((Integer) rs.getObject("AccountID"));
        m.setNotes(rs.getString("Notes"));
        if (rs.getTimestamp("CreatedAt") != null)
            m.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
        return m;
    }

    @Override
    public boolean insert(StockMovements m) {
        String sql = "INSERT INTO StockMovements (BatchID, MovementType, Quantity, RefTable, RefID, AccountID, Notes) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, m.getBatchId());
            ps.setString(2, m.getMovementType());
            ps.setInt(3, m.getQuantity());
            ps.setString(4, m.getRefTable());
            if (m.getRefId() != null) ps.setInt(5, m.getRefId()); else ps.setNull(5, Types.INTEGER);
            if (m.getAccountId() != null) ps.setInt(6, m.getAccountId()); else ps.setNull(6, Types.INTEGER);
            ps.setNString(7, m.getNotes());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public List<StockMovements> findByBatch(int batchId) {
        List<StockMovements> list = new ArrayList<>();
        String sql = "SELECT * FROM StockMovements WHERE BatchID = ? ORDER BY CreatedAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, batchId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<StockMovements> findByDateRange(LocalDate from, LocalDate to) {
        List<StockMovements> list = new ArrayList<>();
        // Range trực tiếp trên CreatedAt (sargable) — theo pattern đã chuẩn hoá ở InvoiceDAO/AttendanceDAO.
        String sql = "SELECT * FROM StockMovements WHERE CreatedAt >= ? AND CreatedAt < ? ORDER BY CreatedAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(from));
            ps.setDate(2, Date.valueOf(to.plusDays(1)));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<StockMovements> findByAccount(int accountId, LocalDate from, LocalDate to) {
        List<StockMovements> list = new ArrayList<>();
        String sql = "SELECT * FROM StockMovements WHERE AccountID = ? AND CreatedAt >= ? AND CreatedAt < ? ORDER BY CreatedAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.setDate(2, Date.valueOf(from));
            ps.setDate(3, Date.valueOf(to.plusDays(1)));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }
}
