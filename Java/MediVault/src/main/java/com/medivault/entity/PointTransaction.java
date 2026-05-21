package com.medivault.entity;

import java.time.LocalDateTime;

public class PointTransaction {
    private int transId;
    private int cardId;
    private Integer invoiceId;
    private String transType; // EARN | REDEEM | EXPIRE | ADJUST
    private int points;
    private int balanceBefore;
    private int balanceAfter;
    private String note;
    private LocalDateTime createdAt;
    private Integer accountId;

    public PointTransaction() {}

    public PointTransaction(int transId, int cardId, Integer invoiceId, String transType, int points, int balanceBefore, int balanceAfter, String note, LocalDateTime createdAt, Integer accountId) {
        this.transId = transId;
        this.cardId = cardId;
        this.invoiceId = invoiceId;
        this.transType = transType;
        this.points = points;
        this.balanceBefore = balanceBefore;
        this.balanceAfter = balanceAfter;
        this.note = note;
        this.createdAt = createdAt;
        this.accountId = accountId;
    }

    public int getTransId() { return transId; }
    public void setTransId(int transId) { this.transId = transId; }
    public int getCardId() { return cardId; }
    public void setCardId(int cardId) { this.cardId = cardId; }
    public Integer getInvoiceId() { return invoiceId; }
    public void setInvoiceId(Integer invoiceId) { this.invoiceId = invoiceId; }
    public String getTransType() { return transType; }
    public void setTransType(String transType) { this.transType = transType; }
    public int getPoints() { return points; }
    public void setPoints(int points) { this.points = points; }
    public int getBalanceBefore() { return balanceBefore; }
    public void setBalanceBefore(int balanceBefore) { this.balanceBefore = balanceBefore; }
    public int getBalanceAfter() { return balanceAfter; }
    public void setBalanceAfter(int balanceAfter) { this.balanceAfter = balanceAfter; }
    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public Integer getAccountId() { return accountId; }
    public void setAccountId(Integer accountId) { this.accountId = accountId; }
}