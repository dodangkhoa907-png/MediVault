package com.medivault.entity;

import java.math.BigDecimal;
import java.time.LocalDate;

public class InvoiceDetail {
    private String medicineName;
    private String unit;
    private String batchNumber;
    private java.time.LocalDate expiryDate;

    private int detailId;
    private int invoiceId;
    private int batchId;
    private int quantity;
    private BigDecimal unitPrice;
    private BigDecimal subTotal; // computed: quantity * unitPrice

    public InvoiceDetail() {
    }

    public InvoiceDetail(String medicineName, String unit, String batchNumber, LocalDate expiryDate, int detailId, int invoiceId, int batchId, int quantity, BigDecimal unitPrice, BigDecimal subTotal) {
        this.medicineName = medicineName;
        this.unit = unit;
        this.batchNumber = batchNumber;
        this.expiryDate = expiryDate;
        this.detailId = detailId;
        this.invoiceId = invoiceId;
        this.batchId = batchId;
        this.quantity = quantity;
        this.unitPrice = unitPrice;
        this.subTotal = subTotal;
    }

    public String getMedicineName() { return medicineName; }
    public void setMedicineName(String medicineName) { this.medicineName = medicineName; }

    public String getUnit() { return unit; }
    public void setUnit(String unit) { this.unit = unit; }

    public String getBatchNumber() { return batchNumber; }
    public void setBatchNumber(String batchNumber) { this.batchNumber = batchNumber; }

    public java.time.LocalDate getExpiryDate() { return expiryDate; }
    public void setExpiryDate(java.time.LocalDate expiryDate) { this.expiryDate = expiryDate; }
    public int getDetailId() { return detailId; }
    public void setDetailId(int detailId) { this.detailId = detailId; }
    public int getInvoiceId() { return invoiceId; }
    public void setInvoiceId(int invoiceId) { this.invoiceId = invoiceId; }
    public int getBatchId() { return batchId; }
    public void setBatchId(int batchId) { this.batchId = batchId; }
    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }
    public BigDecimal getUnitPrice() { return unitPrice; }
    public void setUnitPrice(BigDecimal unitPrice) { this.unitPrice = unitPrice; }
    public BigDecimal getSubTotal() { return subTotal; }
    public void setSubTotal(BigDecimal subTotal) { this.subTotal = subTotal; }
}