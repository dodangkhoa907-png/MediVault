package com.medivault.entity;

import java.time.LocalDateTime;

public class StockMovements {
    private int movementId;
    private int batchId;
    private String movementType; // IN | OUT | RETURN | EXPIRED | ADJUSTMENT
    private int quantity;
    private String refTable;
    private Integer refId;
    private Integer accountId;
    private String notes;
    private LocalDateTime createdAt;

    public StockMovements() {}

    public StockMovements(int movementId, int batchId, String movementType, int quantity, String refTable, Integer refId, Integer accountId, String notes, LocalDateTime createdAt) {
        this.movementId = movementId;
        this.batchId = batchId;
        this.movementType = movementType;
        this.quantity = quantity;
        this.refTable = refTable;
        this.refId = refId;
        this.accountId = accountId;
        this.notes = notes;
        this.createdAt = createdAt;
    }

    public int getMovementId() { return movementId; }
    public void setMovementId(int movementId) { this.movementId = movementId; }
    public int getBatchId() { return batchId; }
    public void setBatchId(int batchId) { this.batchId = batchId; }
    public String getMovementType() { return movementType; }
    public void setMovementType(String movementType) { this.movementType = movementType; }
    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }
    public String getRefTable() { return refTable; }
    public void setRefTable(String refTable) { this.refTable = refTable; }
    public Integer getRefId() { return refId; }
    public void setRefId(Integer refId) { this.refId = refId; }
    public Integer getAccountId() { return accountId; }
    public void setAccountId(Integer accountId) { this.accountId = accountId; }
    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}