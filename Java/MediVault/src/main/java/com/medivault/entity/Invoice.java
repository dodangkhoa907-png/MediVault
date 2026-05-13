package com.medivault.entity;

import java.time.LocalDateTime;

public class Invoice {

    private int invoiceID;
    private String invoiceCode;
    private LocalDateTime createdAt;
    private int accountID;
    private int shiftID;
    private int customerID;
    private int prescriptionID;
    private double finalAmount;
    private double discountAmount;
    private String paymentMethod;
    private String status;

    public Invoice() {
    }

    public Invoice(int invoiceID, String invoiceCode, LocalDateTime createdAt, int accountID, int shiftID, int customerID, int prescriptionID, double finalAmount, double discountAmount, String paymentMethod, String status) {
        this.invoiceID = invoiceID;
        this.invoiceCode = invoiceCode;
        this.createdAt = createdAt;
        this.accountID = accountID;
        this.shiftID = shiftID;
        this.customerID = customerID;
        this.prescriptionID = prescriptionID;
        this.finalAmount = finalAmount;
        this.discountAmount = discountAmount;
        this.paymentMethod = paymentMethod;
        this.status = status;
    }

    public int getInvoiceID() {
        return invoiceID;
    }

    public void setInvoiceID(int invoiceID) {
        this.invoiceID = invoiceID;
    }

    public String getInvoiceCode() {
        return invoiceCode;
    }

    public void setInvoiceCode(String invoiceCode) {
        this.invoiceCode = invoiceCode;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public int getAccountID() {
        return accountID;
    }

    public void setAccountID(int accountID) {
        this.accountID = accountID;
    }

    public int getShiftID() {
        return shiftID;
    }

    public void setShiftID(int shiftID) {
        this.shiftID = shiftID;
    }

    public int getCustomerID() {
        return customerID;
    }

    public void setCustomerID(int customerID) {
        this.customerID = customerID;
    }

    public int getPrescriptionID() {
        return prescriptionID;
    }

    public void setPrescriptionID(int prescriptionID) {
        this.prescriptionID = prescriptionID;
    }

    public double getFinalAmount() {
        return finalAmount;
    }

    public void setFinalAmount(double finalAmount) {
        this.finalAmount = finalAmount;
    }

    public double getDiscountAmount() {
        return discountAmount;
    }

    public void setDiscountAmount(double discountAmount) {
        this.discountAmount = discountAmount;
    }

    public String getPaymentMethod() {
        return paymentMethod;
    }

    public void setPaymentMethod(String paymentMethod) {
        this.paymentMethod = paymentMethod;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    @Override
    public String toString() {
        return "Invoice{" + "invoiceID=" + invoiceID + ", invoiceCode=" + invoiceCode + ", createdAt=" + createdAt + ", accountID=" + accountID + ", shiftID=" + shiftID + ", customerID=" + customerID + ", prescriptionID=" + prescriptionID + ", finalAmount=" + finalAmount + ", discountAmount=" + discountAmount + ", paymentMethod=" + paymentMethod + ", status=" + status + '}';
    }





}
