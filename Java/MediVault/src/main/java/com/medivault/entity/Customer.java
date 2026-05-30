package com.medivault.entity;

import java.time.LocalDate;
import java.time.LocalDateTime;

public class Customer {
    private int customerId;
    private String customerName;
    private String phone;
    private String email;
    private String address;
    private LocalDate dateOfBirth;
    private String gender; // M | F | OTHER
    private String nationalId;
    private String occupation;
    private String allergyHistory;
    private String chronicDisease;
    private LocalDateTime createdAt;

    public Customer() {}

    public Customer(int customerId, String customerName, String phone, String address, String email, LocalDate dateOfBirth, String gender, String nationalId, String occupation, String allergyHistory, String chronicDisease, LocalDateTime createdAt) {
        this.customerId = customerId;
        this.customerName = customerName;
        this.phone = phone;
        this.address = address;
        this.email = email;
        this.dateOfBirth = dateOfBirth;
        this.gender = gender;
        this.nationalId = nationalId;
        this.occupation = occupation;
        this.allergyHistory = allergyHistory;
        this.chronicDisease = chronicDisease;
        this.createdAt = createdAt;
    }

    public int getCustomerId() { return customerId; }
    public void setCustomerId(int customerId) { this.customerId = customerId; }
    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getAddress() { return address; }
    public void setAddress(String address) { this.address = address; }
    public LocalDate getDateOfBirth() { return dateOfBirth; }
    public void setDateOfBirth(LocalDate dateOfBirth) { this.dateOfBirth = dateOfBirth; }
    public String getGender() { return gender; }
    public void setGender(String gender) { this.gender = gender; }
    public String getNationalId() { return nationalId; }
    public void setNationalId(String nationalId) { this.nationalId = nationalId; }
    public String getOccupation() { return occupation; }
    public void setOccupation(String occupation) { this.occupation = occupation; }
    public String getAllergyHistory() { return allergyHistory; }
    public void setAllergyHistory(String allergyHistory) { this.allergyHistory = allergyHistory; }
    public String getChronicDisease() { return chronicDisease; }
    public void setChronicDisease(String chronicDisease) { this.chronicDisease = chronicDisease; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}