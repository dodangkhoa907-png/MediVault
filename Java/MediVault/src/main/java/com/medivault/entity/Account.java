package com.medivault.entity;

import java.sql.Timestamp;

public class Account {
    private int accountId;
    private String username;
    private String password;
    private String fullName;
    private String email;
    private String phone;
    private String citizenId;
    private String position;
    private int roleId;
    private boolean isActive;
    private boolean isDeleted;

    // ĐÃ THÊM: Biến cờ hiệu trạng thái chờ reset mật khẩu
    private boolean isPendingReset;

    private String professionalCertNo;
    private String faceEnrollmentPath;
    private Timestamp createdAt;
    private Timestamp lastLoginAt;

    public Account() {}

    // --- GETTER & SETTER ---
    public int getAccountId() { return accountId; }
    public void setAccountId(int accountId) { this.accountId = accountId; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getCitizenId() { return citizenId; }
    public void setCitizenId(String citizenId) { this.citizenId = citizenId; }

    public String getPosition() { return position; }
    public void setPosition(String position) { this.position = position; }

    public int getRoleId() { return roleId; }
    public void setRoleId(int roleId) { this.roleId = roleId; }

    public boolean isActive() { return isActive; }
    public void setActive(boolean active) { this.isActive = active; }

    public boolean isDeleted() { return isDeleted; }
    public void setDeleted(boolean deleted) { this.isDeleted = deleted; }

    // ĐÃ THÊM: Getter và Setter cho thuộc tính PendingReset
    public boolean isPendingReset() { return isPendingReset; }
    public void setPendingReset(boolean pendingReset) { this.isPendingReset = pendingReset; }

    public String getProfessionalCertNo() { return professionalCertNo; }
    public void setProfessionalCertNo(String professionalCertNo) { this.professionalCertNo = professionalCertNo; }

    public String getFaceEnrollmentPath() { return faceEnrollmentPath; }
    public void setFaceEnrollmentPath(String faceEnrollmentPath) { this.faceEnrollmentPath = faceEnrollmentPath; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public Timestamp getLastLoginAt() { return lastLoginAt; }
    public void setLastLoginAt(Timestamp lastLoginAt) { this.lastLoginAt = lastLoginAt; }
}