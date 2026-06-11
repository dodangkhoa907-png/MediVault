package com.medicare.entity;

import java.time.LocalDateTime;

public class StaffAuditLog {
    private int logId;
    private int accountId;
    private String action;
    private String details;
    private String ipAddress;
    private LocalDateTime createdAt;

    public StaffAuditLog() {}

    public StaffAuditLog(int accountId, String action, String details, String ipAddress) {
        this.accountId = accountId;
        this.action    = action;
        this.details   = details;
        this.ipAddress = ipAddress;
    }

    public int getLogId()                          { return logId; }
    public void setLogId(int logId)                { this.logId = logId; }

    public int getAccountId()                      { return accountId; }
    public void setAccountId(int accountId)        { this.accountId = accountId; }

    public String getAction()                      { return action; }
    public void setAction(String action)           { this.action = action; }

    public String getDetails()                     { return details; }
    public void setDetails(String details)         { this.details = details; }

    public String getIpAddress()                   { return ipAddress; }
    public void setIpAddress(String ipAddress)     { this.ipAddress = ipAddress; }

    public LocalDateTime getCreatedAt()            { return createdAt; }
    public void setCreatedAt(LocalDateTime v)      { this.createdAt = v; }
}