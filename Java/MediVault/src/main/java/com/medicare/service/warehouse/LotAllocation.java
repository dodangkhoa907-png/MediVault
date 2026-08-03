package com.medicare.service.warehouse;

import java.time.LocalDate;

/** 1 lô được FEFO engine chọn để đáp ứng 1 phần (hoặc toàn bộ) số lượng yêu cầu của 1 thuốc. */
public class LotAllocation {
    private final int batchId;
    private final String batchNumber;
    private final LocalDate expiryDate;
    private final int availableQuantity;
    private final int allocatedQuantity;

    public LotAllocation(int batchId, String batchNumber, LocalDate expiryDate, int availableQuantity, int allocatedQuantity) {
        this.batchId = batchId;
        this.batchNumber = batchNumber;
        this.expiryDate = expiryDate;
        this.availableQuantity = availableQuantity;
        this.allocatedQuantity = allocatedQuantity;
    }

    public int getBatchId() { return batchId; }
    public String getBatchNumber() { return batchNumber; }
    public LocalDate getExpiryDate() { return expiryDate; }
    public int getAvailableQuantity() { return availableQuantity; }
    public int getAllocatedQuantity() { return allocatedQuantity; }
}
