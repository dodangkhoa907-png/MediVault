package com.medivault.entity;

public class Supplier {
    private int supplierId;
    private String supplierName;
    private String contactName;
    private String phone;
    private String email;
    private String address;
    private String licenseNumber;
    private boolean isActive;

    public Supplier() {
    }

    public Supplier(int supplierId, String supplierName, String contactName, String phone, String email, String address, String licenseNumber, boolean isActive) {
        this.supplierId = supplierId;
        this.supplierName = supplierName;
        this.contactName = contactName;
        this.phone = phone;
        this.email = email;
        this.address = address;
        this.licenseNumber = licenseNumber;
        this.isActive = isActive;
    }

    public int getSupplierId() {
        return supplierId;
    }

    public void setSupplierId(int supplierId) {
        this.supplierId = supplierId;
    }

    public String getSupplierName() {
        return supplierName;
    }

    public void setSupplierName(String supplierName) {
        this.supplierName = supplierName;
    }

    public String getContactName() {
        return contactName;
    }

    public void setContactName(String contactName) {
        this.contactName = contactName;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getAddress() {
        return address;
    }

    public void setAddress(String address) {
        this.address = address;
    }

    public String getLicenseNumber() {
        return licenseNumber;
    }

    public void setLicenseNumber(String licenseNumber) {
        this.licenseNumber = licenseNumber;
    }

    public boolean isActive() {
        return isActive;
    }

    public void setActive(boolean isActive) {
        this.isActive = isActive;
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder();
        sb.append("Supplier{");
        sb.append("supplierId=").append(supplierId);
        sb.append(", supplierName=").append(supplierName);
        sb.append(", contactName=").append(contactName);
        sb.append(", phone=").append(phone);
        sb.append(", email=").append(email);
        sb.append(", address=").append(address);
        sb.append(", licenseNumber=").append(licenseNumber);
        sb.append(", isActive=").append(isActive);
        sb.append('}');
        return sb.toString();
    }
}
