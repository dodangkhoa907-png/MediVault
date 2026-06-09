package com.medivault.entity;

import java.time.LocalDateTime;

public class PasswordResetRequest {

    private int requestId;
    private int accountId;
    private String token;
    private String status;
    private LocalDateTime requestedAt;
    private LocalDateTime expiresAt;
    private LocalDateTime confirmedAt;
    private LocalDateTime completedAt;

    // ─── CONSTRUCTORS ───

    public PasswordResetRequest() {
    }

    /**
     * Constructor đầy đủ tham số (Thường dùng khi lấy dữ liệu từ DB lên)
     */
    public PasswordResetRequest(int requestId, int accountId, String token, String status,
                                LocalDateTime requestedAt, LocalDateTime expiresAt,
                                LocalDateTime confirmedAt, LocalDateTime completedAt) {
        this.requestId = requestId;
        this.accountId = accountId;
        this.token = token;
        this.status = status;
        this.requestedAt = requestedAt;
        this.expiresAt = expiresAt;
        this.confirmedAt = confirmedAt;
        this.completedAt = completedAt;
    }

    /**
     * Constructor dùng khi tạo mới một yêu cầu (Trước khi lưu vào DB)
     */
    public PasswordResetRequest(int accountId, String token, LocalDateTime expiresAt) {
        this.accountId = accountId;
        this.token = token;
        this.status = "PENDING"; // Giá trị mặc định giống DB
        this.requestedAt = LocalDateTime.now(); // Thời gian hiện tại
        this.expiresAt = expiresAt;
    }

    // ─── GETTERS AND SETTERS ───

    public int getRequestId() {
        return requestId;
    }

    public void setRequestId(int requestId) {
        this.requestId = requestId;
    }

    public int getAccountId() {
        return accountId;
    }

    public void setAccountId(int accountId) {
        this.accountId = accountId;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getRequestedAt() {
        return requestedAt;
    }

    public void setRequestedAt(LocalDateTime requestedAt) {
        this.requestedAt = requestedAt;
    }

    public LocalDateTime getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(LocalDateTime expiresAt) {
        this.expiresAt = expiresAt;
    }

    public LocalDateTime getConfirmedAt() {
        return confirmedAt;
    }

    public void setConfirmedAt(LocalDateTime confirmedAt) {
        this.confirmedAt = confirmedAt;
    }

    public LocalDateTime getCompletedAt() {
        return completedAt;
    }

    public void setCompletedAt(LocalDateTime completedAt) {
        this.completedAt = completedAt;
    }

    // ─── TOSTRING (Hỗ trợ in log debug nhanh) ───

    @Override
    public String toString() {
        return "PasswordResetRequest{" +
                "requestId=" + requestId +
                ", accountId=" + accountId +
                ", token='" + token + '\'' +
                ", status='" + status + '\'' +
                ", requestedAt=" + requestedAt +
                ", expiresAt=" + expiresAt +
                ", confirmedAt=" + confirmedAt +
                ", completedAt=" + completedAt +
                '}';
    }
}
