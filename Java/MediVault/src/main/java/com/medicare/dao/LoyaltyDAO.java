package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.entity.LoyaltyCard;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * LoyaltyDAO — thẻ tích điểm khách hàng (LoyaltyCards + LoyaltyTiers + PointTransactions).
 *
 * Quy tắc điểm: 1 điểm / 10.000đ hóa đơn COMPLETED.
 * Thăng hạng tự động: TierID = hạng cao nhất có MinPoints <= TotalPoints.
 */
public class LoyaltyDAO {

    /** 1 điểm cho mỗi X đồng hóa đơn */
    public static final long VND_PER_POINT = 10_000L;

    private LoyaltyCard mapCard(ResultSet rs) throws SQLException {
        LoyaltyCard c = new LoyaltyCard();
        c.setCardId(rs.getInt("CardID"));
        c.setCardCode(rs.getString("CardCode"));
        c.setCustomerId(rs.getInt("CustomerID"));
        c.setTierId(rs.getInt("TierID"));
        c.setTotalPoints(rs.getInt("TotalPoints"));
        c.setUsedPoints(rs.getInt("UsedPoints"));
        if (rs.getTimestamp("IssuedAt") != null)
            c.setIssuedAt(rs.getTimestamp("IssuedAt").toLocalDateTime());
        c.setActive(rs.getBoolean("IsActive"));
        try { c.setTierName(rs.getNString("TierName")); } catch (SQLException ignored) {}
        try { c.setDiscountPct(rs.getBigDecimal("DiscountPct")); } catch (SQLException ignored) {}
        try {
            c.setNextTierName(rs.getNString("NextTierName"));
            c.setNextTierMinPoints(rs.getInt("NextTierMin"));
        } catch (SQLException ignored) {}
        return c;
    }

    private static final String SELECT_CARD =
            "SELECT lc.*, t.TierName, t.DiscountPct, " +
            "  nt.TierName AS NextTierName, ISNULL(nt.MinPoints, 0) AS NextTierMin " +
            "FROM LoyaltyCards lc " +
            "JOIN LoyaltyTiers t ON t.TierID = lc.TierID " +
            "OUTER APPLY (SELECT TOP 1 TierName, MinPoints FROM LoyaltyTiers " +
            "             WHERE MinPoints > lc.TotalPoints ORDER BY MinPoints ASC) nt ";

    /** Thẻ của khách — tạo mới (hạng thấp nhất) nếu chưa có. */
    public LoyaltyCard getOrCreateCard(int customerId) {
        LoyaltyCard card = findByCustomer(customerId);
        if (card != null) return card;
        String sql = "INSERT INTO LoyaltyCards (CustomerID, TierID) " +
                "SELECT ?, (SELECT TOP 1 TierID FROM LoyaltyTiers ORDER BY MinPoints ASC) " +
                "WHERE NOT EXISTS (SELECT 1 FROM LoyaltyCards WHERE CustomerID = ?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, customerId);
            ps.setInt(2, customerId);
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
        return findByCustomer(customerId);
    }

    public LoyaltyCard findByCustomer(int customerId) {
        String sql = SELECT_CARD + "WHERE lc.CustomerID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, customerId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapCard(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    /**
     * Tích điểm từ hóa đơn (1 điểm / 10.000đ). Tự tạo thẻ nếu khách chưa có,
     * ghi PointTransactions EARN và thăng hạng tự động.
     * @return số điểm được cộng (0 nếu không đủ mức hoặc lỗi)
     */
    public int earnFromInvoice(int customerId, int invoiceId, java.math.BigDecimal finalAmount,
                               Integer staffAccountId) {
        if (finalAmount == null) return 0;
        int points = (int) (finalAmount.longValue() / VND_PER_POINT);
        if (points <= 0) return 0;
        LoyaltyCard card = getOrCreateCard(customerId);
        if (card == null) return 0;

        String sql = "UPDATE LoyaltyCards SET TotalPoints = TotalPoints + ? WHERE CardID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, points);
            ps.setInt(2, card.getCardId());
            if (ps.executeUpdate() == 0) return 0;
        } catch (Exception e) { e.printStackTrace(); return 0; }

        logTransaction(card.getCardId(), invoiceId, "EARN", points,
                card.getAvailablePoints(), card.getAvailablePoints() + points,
                "Tích điểm hóa đơn", staffAccountId);
        recalcTier(card.getCardId());
        return points;
    }

    /**
     * Đổi điểm lấy ưu đãi. Kiểm tra số dư trước khi trừ (điều kiện trong UPDATE
     * chống race). @return true nếu đổi thành công.
     */
    public boolean redeem(int customerId, int points, String note) {
        if (points <= 0) return false;
        LoyaltyCard card = findByCustomer(customerId);
        if (card == null || card.getAvailablePoints() < points) return false;

        String sql = "UPDATE LoyaltyCards SET UsedPoints = UsedPoints + ? " +
                "WHERE CardID = ? AND TotalPoints - UsedPoints >= ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, points);
            ps.setInt(2, card.getCardId());
            ps.setInt(3, points);
            if (ps.executeUpdate() == 0) return false;
        } catch (Exception e) { e.printStackTrace(); return false; }

        logTransaction(card.getCardId(), null, "REDEEM", points,
                card.getAvailablePoints(), card.getAvailablePoints() - points, note, null);
        return true;
    }

    /** Lịch sử giao dịch điểm (mới nhất trước) — hiển thị trong portal. */
    public List<String[]> history(int customerId, int limit) {
        List<String[]> list = new ArrayList<>();
        String sql = "SELECT TOP (?) pt.TransType, pt.Points, pt.Note, " +
                "CONVERT(VARCHAR(16), pt.CreatedAt, 120) AS CreatedAt " +
                "FROM PointTransactions pt " +
                "JOIN LoyaltyCards lc ON lc.CardID = pt.CardID " +
                "WHERE lc.CustomerID = ? ORDER BY pt.CreatedAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            ps.setInt(2, customerId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(new String[]{
                            rs.getString("TransType"),
                            String.valueOf(rs.getInt("Points")),
                            rs.getNString("Note") != null ? rs.getNString("Note") : "",
                            rs.getString("CreatedAt")
                    });
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    private void logTransaction(int cardId, Integer invoiceId, String type, int points,
                                int before, int after, String note, Integer accountId) {
        String sql = "INSERT INTO PointTransactions " +
                "(CardID, InvoiceID, TransType, Points, BalanceBefore, BalanceAfter, Note, AccountID) " +
                "VALUES (?,?,?,?,?,?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, cardId);
            if (invoiceId == null) ps.setNull(2, Types.INTEGER); else ps.setInt(2, invoiceId);
            ps.setString(3, type);
            ps.setInt(4, points);
            ps.setInt(5, before);
            ps.setInt(6, after);
            ps.setNString(7, note);
            if (accountId == null) ps.setNull(8, Types.INTEGER); else ps.setInt(8, accountId);
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }

    /** Thăng hạng tự động theo tổng điểm tích lũy. */
    private void recalcTier(int cardId) {
        String sql = "UPDATE lc SET lc.TierID = t.TierID " +
                "FROM LoyaltyCards lc " +
                "CROSS APPLY (SELECT TOP 1 TierID FROM LoyaltyTiers " +
                "             WHERE MinPoints <= lc.TotalPoints ORDER BY MinPoints DESC) t " +
                "WHERE lc.CardID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, cardId);
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }
}
