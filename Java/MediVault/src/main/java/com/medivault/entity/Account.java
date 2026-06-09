package com.medivault.entity;

import java.time.LocalDate;
import java.time.LocalDateTime;

public class Account {
    private int accountId;
    private String username;
    private String passwordHash;
    private String fullName;
    private String email;
    private String phone;
    private int roleId;
    private String citizenId;
    private String professionalCertNo;
    private LocalDate professionalCertExp;
    private String position;
    private LocalDate trainingDate;
    private boolean isActive;
    private String faceEnrollmentPath;
    private LocalDateTime createdAt;
    private LocalDateTime lastLoginAt;
    private boolean deleted;
    private java.time.LocalDateTime deletedAt;

    public Account() {
    }

    public Account(int accountId, String username, String passwordHash, String fullName, String email, String phone, int roleId, String citizenId, String professionalCertNo, LocalDate professionalCertExp, String position, LocalDate trainingDate, boolean isActive, String faceEnrollmentPath, LocalDateTime createdAt, LocalDateTime lastLoginAt, boolean deleted, LocalDateTime deletedAt) {
        this.accountId = accountId;
        this.username = username;
        this.passwordHash = passwordHash;
        this.fullName = fullName;
        this.email = email;
        this.phone = phone;
        this.roleId = roleId;
        this.citizenId = citizenId;
        this.professionalCertNo = professionalCertNo;
        this.professionalCertExp = professionalCertExp;
        this.position = position;
        this.trainingDate = trainingDate;
        this.isActive = isActive;
        this.faceEnrollmentPath = faceEnrollmentPath;
        this.createdAt = createdAt;
        this.lastLoginAt = lastLoginAt;
        this.deleted = deleted;
        this.deletedAt = deletedAt;
    }

    public int getAccountId() {
        return accountId;
    }

    public void setAccountId(int accountId) {
        this.accountId = accountId;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public int getRoleId() {
        return roleId;
    }

    public void setRoleId(int roleId) {
        this.roleId = roleId;
    }

    public String getCitizenId() {
        return citizenId;
    }

    public void setCitizenId(String citizenId) {
        this.citizenId = citizenId;
    }

    public String getProfessionalCertNo() {
        return professionalCertNo;
    }

    public void setProfessionalCertNo(String professionalCertNo) {
        this.professionalCertNo = professionalCertNo;
    }

    public LocalDate getProfessionalCertExp() {
        return professionalCertExp;
    }

    public void setProfessionalCertExp(LocalDate professionalCertExp) {
        this.professionalCertExp = professionalCertExp;
    }

    public String getPosition() {
        return position;
    }

    public void setPosition(String position) {
        this.position = position;
    }

    public LocalDate getTrainingDate() {
        return trainingDate;
    }

    public void setTrainingDate(LocalDate trainingDate) {
        this.trainingDate = trainingDate;
    }

    public boolean isActive() {
        return isActive;
    }

    public void setActive(boolean active) {
        isActive = active;
    }

    public String getFaceEnrollmentPath() {
        return faceEnrollmentPath;
    }

    public void setFaceEnrollmentPath(String faceEnrollmentPath) {
        this.faceEnrollmentPath = faceEnrollmentPath;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getLastLoginAt() {
        return lastLoginAt;
    }

    public void setLastLoginAt(LocalDateTime lastLoginAt) {
        this.lastLoginAt = lastLoginAt;
    }

    public boolean isDeleted() {
        return deleted;
    }

    public void setDeleted(boolean deleted) {
        this.deleted = deleted;
    }

    public LocalDateTime getDeletedAt() {
        return deletedAt;
    }

    public void setDeletedAt(LocalDateTime deletedAt) {
        this.deletedAt = deletedAt;
    }

    @Override
    public String toString() {
        return "Account{" +
                "accountId=" + accountId +
                ", username='" + username + '\'' +
                ", passwordHash='" + passwordHash + '\'' +
                ", fullName='" + fullName + '\'' +
                ", email='" + email + '\'' +
                ", phone='" + phone + '\'' +
                ", roleId=" + roleId +
                ", citizenId='" + citizenId + '\'' +
                ", professionalCertNo='" + professionalCertNo + '\'' +
                ", professionalCertExp=" + professionalCertExp +
                ", position='" + position + '\'' +
                ", trainingDate=" + trainingDate +
                ", isActive=" + isActive +
                ", faceEnrollmentPath='" + faceEnrollmentPath + '\'' +
                ", createdAt=" + createdAt +
                ", lastLoginAt=" + lastLoginAt +
                ", deleted=" + deleted +
                ", deletedAt=" + deletedAt +
                '}';
    }
}