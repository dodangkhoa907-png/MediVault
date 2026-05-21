package com.medivault.entity;

import java.math.BigDecimal;

public class LoyaltyTier {
    private int tierId;
    private String tierName;
    private int minPoints;
    private BigDecimal discountPct;
    private String description;

    public LoyaltyTier() {}

    public LoyaltyTier(int tierId, String tierName, int minPoints, BigDecimal discountPct, String description) {
        this.tierId = tierId;
        this.tierName = tierName;
        this.minPoints = minPoints;
        this.discountPct = discountPct;
        this.description = description;
    }

    public int getTierId() { return tierId; }
    public void setTierId(int tierId) { this.tierId = tierId; }
    public String getTierName() { return tierName; }
    public void setTierName(String tierName) { this.tierName = tierName; }
    public int getMinPoints() { return minPoints; }
    public void setMinPoints(int minPoints) { this.minPoints = minPoints; }
    public BigDecimal getDiscountPct() { return discountPct; }
    public void setDiscountPct(BigDecimal discountPct) { this.discountPct = discountPct; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
}