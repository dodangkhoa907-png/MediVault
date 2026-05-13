package com.medivault.entity;

import java.time.LocalDateTime;

public class Account {
    private int accountId;
    private String userName;
    private String passwordHash;
    private String fullName;
    private String email;
    private String phone;
    private int roleId;
    private boolean isActive;
    private LocalDateTime createdAt;
    private LocalDateTime lastLoginAt;

    public Account() {
    }

    public Account(int accountId, String userName, String passwordHash, String fullName, String email, String phone, int roleId, boolean isActive, LocalDateTime createdAt, LocalDateTime lastLoginAt) {
        this.accountId = accountId;
        this.userName = userName;
        this.passwordHash = passwordHash;
        this.fullName = fullName;
        this.email = email;
        this.phone = phone;
        this.roleId = roleId;
        this.isActive = isActive;
        this.createdAt = createdAt;
        this.lastLoginAt = lastLoginAt;
    }

    public int getAccountId() {
        return accountId;
    }

    public void setAccountId(int accountId) {
        this.accountId = accountId;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
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

    public boolean isActive() {
        return isActive;
    }

    public void setActive(boolean isActive) {
        this.isActive = isActive;
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

    @Override
    public String toString() {
        return "Account{"
                + "accountId=" + accountId
                + ", userName='" + userName + "'"
                + ", fullName='" + fullName + "'"
                + ", email='" + email + "'"
                + ", roleId=" + roleId
                + ", isActive=" + isActive
                + "}";
    }
}
