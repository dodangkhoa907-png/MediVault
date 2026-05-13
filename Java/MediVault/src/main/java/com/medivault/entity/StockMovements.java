package com.medivault.entity;

import java.time.LocalDateTime;

public class StockMovements {
    private int movementId;
    private int batchId;
    private String movementType;
    private int quantity;
    private String refTable;
    private int refId;
    private int accountId;
    private String notes;
    private LocalDateTime createdAt;

    public StockMovements() {
    }

    public StockMovements(int movementId, int batchId, String movementType, int quantity, String refTable, int refId, int accountId, String notes, LocalDateTime createdAt) {
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

    public int getMovementId() {
        return movementId;
    }

    public void setMovementId(int movementId) {
        this.movementId = movementId;
    }

    public int getBatchId() {
        return batchId;
    }

    public void setBatchId(int batchId) {
        this.batchId = batchId;
    }

    public String getMovementType() {
        return movementType;
    }

    public void setMovementType(String movementType) {
        this.movementType = movementType;
    }

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }

    public String getRefTable() {
        return refTable;
    }

    public void setRefTable(String refTable) {
        this.refTable = refTable;
    }

    public int getRefId() {
        return refId;
    }

    public void setRefId(int refId) {
        this.refId = refId;
    }

    public int getAccountId() {
        return accountId;
    }

    public void setAccountId(int accountId) {
        this.accountId = accountId;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    @Override
    public String toString() {
        return "StockMovements{" + "movementId=" + movementId + ", batchId=" + batchId + ", movementType=" + movementType + ", quantity=" + quantity + ", refTable=" + refTable + ", refId=" + refId + ", accountId=" + accountId + ", notes=" + notes + ", createdAt=" + createdAt + '}';
    }


}
