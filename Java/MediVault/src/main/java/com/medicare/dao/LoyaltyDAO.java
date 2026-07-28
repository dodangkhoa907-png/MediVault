package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.entity.LoyaltyCard;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * LoyaltyDAO — thẻ tích điểm khách hàng (LoyaltyCards + LoyaltyTiers + PointTransactions).
 *
 * Quy tắc điểm: 1 điểm / 1.000đ hóa đơn COMPLETED.
 * Thăng hạng tự động: TierID = hạng cao nhất có MinPoints <= TotalPoints.
 */
public class LoyaltyDAO {

    /** 1 điểm cho mỗi X đồng hóa đơn */
    public static final long VND_PER_POINT = 1_000L;

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
        try { c.setTierName(rs.getString("TierName")); } catch (SQLException ignored) {}
        try { c.setDiscountPct(rs.getBigDecimal("DiscountPct")); } catch (SQLException ignored) {}
        try {
            c.setNextTierName(rs.getString("NextTierName"));
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
     * Tích điểm từ hóa đơn (1 điểm / 1.000đ). Tự tạo thẻ nếu khách chưa có,
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
        return redeem(customerId, points, note, null);
    }

    public boolean redeem(int customerId, int points, String note, Integer invoiceId) {
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

        logTransaction(card.getCardId(), invoiceId, "REDEEM", points,
                card.getAvailablePoints(), card.getAvailablePoints() - points, note, null);
        return true;
    }

    /**
     * Xử lý điểm khi khách trả hàng (CUSTOMER_RETURN):
     *  1) Trừ lại điểm đã tích lũy tương ứng giá trị hàng trả (khách không còn giữ hàng
     *     thì không được giữ điểm đã cộng cho phần đó nữa).
     *  2) Hoàn lại điểm khách đã dùng để mua đúng hóa đơn này (nếu có) — khách trả hàng
     *     mua bằng điểm thì phải được trả lại điểm đã đổi, tránh mất điểm oan.
     * An toàn khi gọi nhiều lần cho cùng hóa đơn (trả hàng nhiều đợt): phần đã hoàn
     * trước đó được trừ ra nhờ sumRefundedForInvoice().
     */
    public void adjustForReturn(int customerId, int invoiceId, java.math.BigDecimal returnValue,
                                Integer staffAccountId) {
        LoyaltyCard card = findByCustomer(customerId);
        if (card == null || returnValue == null) return;

        // 1) Trừ điểm đã tích từ phần hàng trả — không trừ vượt quá số điểm khả dụng hiện có
        int earnedToReverse = (int) (returnValue.longValue() / VND_PER_POINT);
        if (earnedToReverse > 0) {
            int actualDeduct = Math.min(earnedToReverse, card.getAvailablePoints());
            if (actualDeduct > 0) {
                String sql = "UPDATE LoyaltyCards SET TotalPoints = TotalPoints - ? WHERE CardID = ?";
                try (Connection cn = DBContext.getConnection();
                     PreparedStatement ps = cn.prepareStatement(sql)) {
                    ps.setInt(1, actualDeduct);
                    ps.setInt(2, card.getCardId());
                    if (ps.executeUpdate() > 0) {
                        logTransaction(card.getCardId(), invoiceId, "ADJUST", -actualDeduct,
                                card.getAvailablePoints(), card.getAvailablePoints() - actualDeduct,
                                "Tru diem tich luy do tra hang", staffAccountId);
                    }
                } catch (Exception e) { e.printStackTrace(); }
            }
        }

        // 2) Hoàn điểm đã dùng để mua đúng hóa đơn này (nếu còn phần chưa hoàn)
        int redeemed        = sumRedeemedForInvoice(invoiceId);
        int refundedAlready = sumRefundedForInvoice(invoiceId);
        int refundable       = redeemed - refundedAlready;
        if (refundable > 0) {
            LoyaltyCard fresh = findByCustomer(customerId);
            if (fresh != null) {
                String sql = "UPDATE LoyaltyCards SET UsedPoints = UsedPoints - ? " +
                        "WHERE CardID = ? AND UsedPoints >= ?";
                try (Connection cn = DBContext.getConnection();
                     PreparedStatement ps = cn.prepareStatement(sql)) {
                    ps.setInt(1, refundable);
                    ps.setInt(2, fresh.getCardId());
                    ps.setInt(3, refundable);
                    if (ps.executeUpdate() > 0) {
                        logTransaction(fresh.getCardId(), invoiceId, "ADJUST", refundable,
                                fresh.getAvailablePoints(), fresh.getAvailablePoints() + refundable,
                                "Hoan diem da dung do tra hang", staffAccountId);
                    }
                } catch (Exception e) { e.printStackTrace(); }
            }
        }

        recalcTier(card.getCardId());
    }

    /** Tổng điểm đã REDEEM cho 1 hóa đơn cụ thể. */
    public int sumRedeemedForInvoice(int invoiceId) {
        String sql = "SELECT ISNULL(SUM(Points),0) FROM PointTransactions " +
                "WHERE InvoiceID = ? AND TransType = 'REDEEM'";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, invoiceId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    /** Tổng điểm đã hoàn (ADJUST dương) cho 1 hóa đơn — tránh hoàn lặp khi trả hàng nhiều đợt. */
    public int sumRefundedForInvoice(int invoiceId) {
        String sql = "SELECT ISNULL(SUM(Points),0) FROM PointTransactions " +
                "WHERE InvoiceID = ? AND TransType = 'ADJUST' AND Points > 0";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, invoiceId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
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
                            rs.getString("Note") != null ? rs.getString("Note") : "",
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
