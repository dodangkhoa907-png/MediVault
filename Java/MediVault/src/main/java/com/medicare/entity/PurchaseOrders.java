package com.medicare.entity;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

public class PurchaseOrders {
    private int poId;
    private String poCode; // computed
    private int supplierId;
    private int accountId;
    private LocalDateTime orderDate;
    private LocalDate expectedDate; // nullable — Ngày giao dự kiến, dùng để tính "Quá hạn"
    private BigDecimal totalValue;
    private String notes;
    private String status;          // PENDING | COMPLETED
    private String paymentMethod;   // CASH | TRANSFER | DEBT
    private BigDecimal discountAmount;

    public PurchaseOrders() {}

    public PurchaseOrders(int poId, String poCode, int supplierId, int accountId, LocalDateTime orderDate, BigDecimal totalValue, String notes) {
        this.poId = poId;
        this.poCode = poCode;
        this.supplierId = supplierId;
        this.accountId = accountId;
        this.orderDate = orderDate;
        this.totalValue = totalValue;
        this.notes = notes;
    }

    public int getPoId() { return poId; }
    public void setPoId(int poId) { this.poId = poId; }
    public String getPoCode() { return poCode; }
    public void setPoCode(String poCode) { this.poCode = poCode; }
    public int getSupplierId() { return supplierId; }
    public void setSupplierId(int supplierId) { this.supplierId = supplierId; }
    public int getAccountId() { return accountId; }
    public void setAccountId(int accountId) { this.accountId = accountId; }
    public LocalDateTime getOrderDate() { return orderDate; }
    public void setOrderDate(LocalDateTime orderDate) { this.orderDate = orderDate; }
    public LocalDate getExpectedDate() { return expectedDate; }
    public void setExpectedDate(LocalDate expectedDate) { this.expectedDate = expectedDate; }
    public BigDecimal getTotalValue() { return totalValue; }
    public void setTotalValue(BigDecimal totalValue) { this.totalValue = totalValue; }
    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }
    public BigDecimal getDiscountAmount() { return discountAmount; }
    public void setDiscountAmount(BigDecimal discountAmount) { this.discountAmount = discountAmount; }
}