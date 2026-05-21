package com.medivault.entity;

import java.math.BigDecimal;

public class InvoiceDetail {
    private int detailId;
    private int invoiceId;
    private int batchId;
    private int quantity;
    private BigDecimal unitPrice;
    private BigDecimal subTotal; // computed: quantity * unitPrice

    public InvoiceDetail() {}

    public InvoiceDetail(int detailId, int invoiceId, int batchId, int quantity, BigDecimal unitPrice, BigDecimal subTotal) {
        this.detailId = detailId;
        this.invoiceId = invoiceId;
        this.batchId = batchId;
        this.quantity = quantity;
        this.unitPrice = unitPrice;
        this.subTotal = subTotal;
    }

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