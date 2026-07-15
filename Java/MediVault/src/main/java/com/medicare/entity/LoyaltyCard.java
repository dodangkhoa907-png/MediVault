package com.medicare.entity;

import java.time.LocalDateTime;

public class LoyaltyCard {
    private int cardId;
    private String cardCode; // computed: CARD000001
    private int customerId;
    private int tierId;
    private int totalPoints;
    private int usedPoints;
    private LocalDateTime issuedAt;
    private LocalDateTime expiredAt;
    private boolean isActive;

    // ── Join fields (từ LoyaltyTiers) ──
    private String tierName;
    private java.math.BigDecimal discountPct;
    private String nextTierName;      // hạng kế tiếp (null nếu đã max)
    private int nextTierMinPoints;    // mốc điểm hạng kế tiếp

    public LoyaltyCard() {}

    public LoyaltyCard(int cardId, String cardCode, int customerId, int tierId, int totalPoints, int usedPoints, LocalDateTime issuedAt, LocalDateTime expiredAt, boolean isActive) {
        this.cardId = cardId;
        this.cardCode = cardCode;
        this.customerId = customerId;
        this.tierId = tierId;
        this.totalPoints = totalPoints;
        this.usedPoints = usedPoints;
        this.issuedAt = issuedAt;
        this.expiredAt = expiredAt;
        this.isActive = isActive;
    }

    public int getCardId() { return cardId; }
    public void setCardId(int cardId) { this.cardId = cardId; }
    public String getCardCode() { return cardCode; }
    public void setCardCode(String cardCode) { this.cardCode = cardCode; }
    public int getCustomerId() { return customerId; }
    public void setCustomerId(int customerId) { this.customerId = customerId; }
    public int getTierId() { return tierId; }
    public void setTierId(int tierId) { this.tierId = tierId; }
    public int getTotalPoints() { return totalPoints; }
    public void setTotalPoints(int totalPoints) { this.totalPoints = totalPoints; }
    public int getUsedPoints() { return usedPoints; }
    public void setUsedPoints(int usedPoints) { this.usedPoints = usedPoints; }
    public LocalDateTime getIssuedAt() { return issuedAt; }
    public void setIssuedAt(LocalDateTime issuedAt) { this.issuedAt = issuedAt; }
    public LocalDateTime getExpiredAt() { return expiredAt; }
    public void setExpiredAt(LocalDateTime expiredAt) { this.expiredAt = expiredAt; }
    public boolean isActive() { return isActive; }
    public void setActive(boolean active) { isActive = active; }

    public String getTierName() { return tierName; }
    public void setTierName(String v) { this.tierName = v; }
    public java.math.BigDecimal getDiscountPct() { return discountPct; }
    public void setDiscountPct(java.math.BigDecimal v) { this.discountPct = v; }
    public String getNextTierName() { return nextTierName; }
    public void setNextTierName(String v) { this.nextTierName = v; }
    public int getNextTierMinPoints() { return nextTierMinPoints; }
    public void setNextTierMinPoints(int v) { this.nextTierMinPoints = v; }

    /** Điểm khả dụng = tổng tích − đã dùng */
    public int getAvailablePoints() { return totalPoints - usedPoints; }
}