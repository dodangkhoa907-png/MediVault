package com.medivault.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class PurchaseOrders {
    private int poId;
    private String poCode; // computed
    private Integer supplierId;
    private Integer accountId;
    private LocalDateTime orderDate;
    private BigDecimal totalValue;
    private String notes;

    public PurchaseOrders() {}

    public int getPoId() { return poId; }
    public void setPoId(int poId) { this.poId = poId; }
    public String getPoCode() { return poCode; }
    public void setPoCode(String poCode) { this.poCode = poCode; }
    public Integer getSupplierId() { return supplierId; }
    public void setSupplierId(Integer supplierId) { this.supplierId = supplierId; }
    public Integer getAccountId() { return accountId; }
    public void setAccountId(Integer accountId) { this.accountId = accountId; }
    public LocalDateTime getOrderDate() { return orderDate; }
    public void setOrderDate(LocalDateTime orderDate) { this.orderDate = orderDate; }
    public BigDecimal getTotalValue() { return totalValue; }
    public void setTotalValue(BigDecimal totalValue) { this.totalValue = totalValue; }
    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }
}