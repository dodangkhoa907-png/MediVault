package com.medivault.entity;

import java.time.LocalDateTime;

public class PurchaseOrders {
    private int POID;
    private String poCode;
    private int supplierId;
    private int accountId;
    private LocalDateTime orderDate;
    private double totalValue;
    private String notes;

    public PurchaseOrders() {
    }

    public PurchaseOrders(int POID, String poCode, int supplierId, int accountId, LocalDateTime orderDate, double totalValue, String notes) {
        this.POID = POID;
        this.poCode = poCode;
        this.supplierId = supplierId;
        this.accountId = accountId;
        this.orderDate = orderDate;
        this.totalValue = totalValue;
        this.notes = notes;
    }

    public int getPOID() {
        return POID;
    }

    public void setPOID(int POID) {
        this.POID = POID;
    }

    public String getPoCode() {
        return poCode;
    }

    public void setPoCode(String poCode) {
        this.poCode = poCode;
    }

    public int getSupplierId() {
        return supplierId;
    }

    public void setSupplierId(int supplierId) {
        this.supplierId = supplierId;
    }

    public int getAccountId() {
        return accountId;
    }

    public void setAccountId(int accountId) {
        this.accountId = accountId;
    }

    public LocalDateTime getOrderDate() {
        return orderDate;
    }

    public void setOrderDate(LocalDateTime orderDate) {
        this.orderDate = orderDate;
    }

    public double getTotalValue() {
        return totalValue;
    }

    public void setTotalValue(double totalValue) {
        this.totalValue = totalValue;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    @Override
    public String toString() {
        return "PurchaseOrders{" + "POID=" + POID + ", poCode=" + poCode + ", supplierId=" + supplierId + ", accountId=" + accountId + ", orderDate=" + orderDate + ", totalValue=" + totalValue + ", notes=" + notes + '}';
    }




}
