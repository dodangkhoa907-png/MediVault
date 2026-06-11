package com.medicare.entity;

import java.time.LocalDateTime;

public class Returns {
    private int returnId;
    private String returnType; // CUSTOMER_RETURN | EXPIRED_DESTROY | RECALL
    private int batchId;
    private Integer invoiceId;
    private int quantity;
    private String reason;
    private int accountId;
    private boolean restoreStock;
    private LocalDateTime createdAt;

    public Returns() {}

    public Returns(int returnId, String returnType, int batchId, Integer invoiceId, int quantity, String reason, int accountId, boolean restoreStock, LocalDateTime createdAt) {
        this.returnId = returnId;
        this.returnType = returnType;
        this.batchId = batchId;
        this.invoiceId = invoiceId;
        this.quantity = quantity;
        this.reason = reason;
        this.accountId = accountId;
        this.restoreStock = restoreStock;
        this.createdAt = createdAt;
    }

    public int getReturnId() { return returnId; }
    public void setReturnId(int returnId) { this.returnId = returnId; }
    public String getReturnType() { return returnType; }
    public void setReturnType(String returnType) { this.returnType = returnType; }
    public int getBatchId() { return batchId; }
    public void setBatchId(int batchId) { this.batchId = batchId; }
    public Integer getInvoiceId() { return invoiceId; }
    public void setInvoiceId(Integer invoiceId) { this.invoiceId = invoiceId; }
    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }
    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
    public int getAccountId() { return accountId; }
    public void setAccountId(int accountId) { this.accountId = accountId; }
    public boolean isRestoreStock() { return restoreStock; }
    public void setRestoreStock(boolean restoreStock) { this.restoreStock = restoreStock; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}