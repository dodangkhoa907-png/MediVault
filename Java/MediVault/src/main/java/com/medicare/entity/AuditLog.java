package com.medicare.entity;

import java.time.LocalDateTime;

/**
 * AuditLog — Map đúng với bảng AuditLog trong DB:
 * LogID, AccountID, Action, EntityType, EntityID, Description, IPAddress, CreatedAt
 */
public class AuditLog {

    private long   logId;
    private Integer accountId;
    private String  username;     // JOIN từ Accounts khi query — không có cột này trong DB
    private String  action;
    private String  entityType;
    private Integer entityId;
    private String  description;
    private String  ipAddress;
    private LocalDateTime createdAt;

    public AuditLog() {}

    // ── Getters & Setters ──
    public long getLogId()                    { return logId; }
    public void setLogId(long logId)          { this.logId = logId; }

    public Integer getAccountId()             { return accountId; }
    public void setAccountId(Integer id)      { this.accountId = id; }

    public String getUsername()               { return username; }
    public void setUsername(String username)  { this.username = username; }

    public String getAction()                 { return action; }
    public void setAction(String action)      { this.action = action; }

    public String getEntityType()             { return entityType; }
    public void setEntityType(String t)       { this.entityType = t; }

    public Integer getEntityId()              { return entityId; }
    public void setEntityId(Integer id)       { this.entityId = id; }

    public String getDescription()            { return description; }
    public void setDescription(String d)      { this.description = d; }

    public String getIpAddress()              { return ipAddress; }
    public void setIpAddress(String ip)       { this.ipAddress = ip; }

    public LocalDateTime getCreatedAt()           { return createdAt; }
    public void setCreatedAt(LocalDateTime t)     { this.createdAt = t; }

    @Override
    public String toString() {
        return "AuditLog{logId=" + logId + ", accountId=" + accountId
                + ", action='" + action + "', entityType='" + entityType
                + "', createdAt=" + createdAt + "}";
    }
}