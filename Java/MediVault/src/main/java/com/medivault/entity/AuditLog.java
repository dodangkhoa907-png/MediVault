package com.medivault.entity;

import java.time.LocalDateTime;

public class AuditLog {
    private long logId;
    private Integer accountId;
    private String action;
    private String entityType;
    private Integer entityId;
    private String description;
    private String ipAddress;
    private LocalDateTime createdAt;

    public AuditLog() {}

    public long getLogId() { return logId; }
    public void setLogId(long logId) { this.logId = logId; }
    public Integer getAccountId() { return accountId; }
    public void setAccountId(Integer accountId) { this.accountId = accountId; }
    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }
    public String getEntityType() { return entityType; }
    public void setEntityType(String entityType) { this.entityType = entityType; }
    public Integer getEntityId() { return entityId; }
    public void setEntityId(Integer entityId) { this.entityId = entityId; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getIpAddress() { return ipAddress; }
    public void setIpAddress(String ipAddress) { this.ipAddress = ipAddress; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}