package com.medicare.entity;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

public class Batches {
    private int batchId;
    private int medicineId;
    private int poId;
    private int supplierId;
    private String batchNumber;
    private LocalDate manufactureDate;
    private LocalDate importDate;
    private LocalDate expiryDate;
    private BigDecimal importPrice;
    private int initialQuantity;
    private int currentQuantity;
    private LocalDateTime createdAt;

    public Batches() {
    }

    public Batches(int batchId, int medicineId, int poId, int supplierId, String batchNumber, LocalDate manufactureDate, LocalDate importDate, LocalDate expiryDate, BigDecimal importPrice, int initialQuantity, int currentQuantity, LocalDateTime createdAt) {
        this.batchId = batchId;
        this.medicineId = medicineId;
        this.poId = poId;
        this.supplierId = supplierId;
        this.batchNumber = batchNumber;
        this.manufactureDate = manufactureDate;
        this.importDate = importDate;
        this.expiryDate = expiryDate;
        this.importPrice = importPrice;
        this.initialQuantity = initialQuantity;
        this.currentQuantity = currentQuantity;
        this.createdAt = createdAt;
    }

    public int getBatchId() {
        return batchId;
    }

    public void setBatchId(int batchId) {
        this.batchId = batchId;
    }

    public int getMedicineId() {
        return medicineId;
    }

    public void setMedicineId(int medicineId) {
        this.medicineId = medicineId;
    }

    public int getPoId() {
        return poId;
    }

    public void setPoId(int poId) {
        this.poId = poId;
    }

    public int getSupplierId() {
        return supplierId;
    }

    public void setSupplierId(int supplierId) {
        this.supplierId = supplierId;
    }

    public String getBatchNumber() {
        return batchNumber;
    }

    public void setBatchNumber(String batchNumber) {
        this.batchNumber = batchNumber;
    }

    public LocalDate getManufactureDate() {
        return manufactureDate;
    }

    public void setManufactureDate(LocalDate manufactureDate) {
        this.manufactureDate = manufactureDate;
    }

    public LocalDate getImportDate() {
        return importDate;
    }

    public void setImportDate(LocalDate importDate) {
        this.importDate = importDate;
    }

    public LocalDate getExpiryDate() {
        return expiryDate;
    }

    public void setExpiryDate(LocalDate expiryDate) {
        this.expiryDate = expiryDate;
    }

    public BigDecimal getImportPrice() {
        return importPrice;
    }

    public void setImportPrice(BigDecimal importPrice) {
        this.importPrice = importPrice;
    }

    public int getInitialQuantity() {
        return initialQuantity;
    }

    public void setInitialQuantity(int initialQuantity) {
        this.initialQuantity = initialQuantity;
    }

    public int getCurrentQuantity() {
        return currentQuantity;
    }

    public void setCurrentQuantity(int currentQuantity) {
        this.currentQuantity = currentQuantity;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}