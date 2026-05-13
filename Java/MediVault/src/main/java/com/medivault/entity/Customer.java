package com.medivault.entity;

import java.time.LocalDateTime;

public class Customer {
    private int customerId;
    private String customerName;
    private String phone;
    private String email;
    private String address;
    private LocalDateTime dateOfBirth;
    private String gender;
    private int points;
    private LocalDateTime createdAt;

    public Customer() {
    }

    public Customer(int customerId, String customerName, String phone, String email, String address, LocalDateTime dateOfBirth, String gender, int points, LocalDateTime createdAt) {
        this.customerId = customerId;
        this.customerName = customerName;
        this.phone = phone;
        this.email = email;
        this.address = address;
        this.dateOfBirth = dateOfBirth;
        this.gender = gender;
        this.points = points;
        this.createdAt = createdAt;
    }

    public int getCustomerId() {
        return customerId;
    }

    public void setCustomerId(int customerId) {
        this.customerId = customerId;
    }

    public String getCustomerName() {
        return customerName;
    }

    public void setCustomerName(String customerName) {
        this.customerName = customerName;
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

    public LocalDateTime getDateOfBirth() {
        return dateOfBirth;
    }

    public void setDateOfBirth(LocalDateTime dateOfBirth) {
        this.dateOfBirth = dateOfBirth;
    }

    public String getGender() {
        return gender;
    }

    public void setGender(String gender) {
        this.gender = gender;
    }

    public int getPoints() {
        return points;
    }

    public void setPoints(int points) {
        this.points = points;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    @Override
    public String toString() {
        return "Customers{" + "customerId=" + customerId + ", customerName=" + customerName + ", phone=" + phone + ", email=" + email + ", address=" + address + ", dateOfBirth=" + dateOfBirth + ", gender=" + gender + ", points=" + points + ", createdAt=" + createdAt + '}';
    }


}
