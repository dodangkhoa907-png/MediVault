package com.medicare.entity;

import java.time.LocalDateTime;

public class OrderLog {
    private long logId;
    private int invoiceId;
    private String oldStatus;
    private String newStatus; // PENDING | COMPLETED | CANCELLED | REFUNDED
    private LocalDateTime changedAt;
    private Integer accountId;
    private String source;
    private String note;

    public OrderLog() {}

    public OrderLog(long logId, int invoiceId, String oldStatus, String newStatus, LocalDateTime changedAt, Integer accountId, String source, String note) {
        this.logId = logId;
        this.invoiceId = invoiceId;
        this.oldStatus = oldStatus;
        this.newStatus = newStatus;
        this.changedAt = changedAt;
        this.accountId = accountId;
        this.source = source;
        this.note = note;
    }

    public long getLogId() { return logId; }
    public void setLogId(long logId) { this.logId = logId; }
    public int getInvoiceId() { return invoiceId; }
    public void setInvoiceId(int invoiceId) { this.invoiceId = invoiceId; }
    public String getOldStatus() { return oldStatus; }
    public void setOldStatus(String oldStatus) { this.oldStatus = oldStatus; }
    public String getNewStatus() { return newStatus; }
    public void setNewStatus(String newStatus) { this.newStatus = newStatus; }
    public LocalDateTime getChangedAt() { return changedAt; }
    public void setChangedAt(LocalDateTime changedAt) { this.changedAt = changedAt; }
    public Integer getAccountId() { return accountId; }
    public void setAccountId(Integer accountId) { this.accountId = accountId; }
    public String getSource() { return source; }
    public void setSource(String source) { this.source = source; }
    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
}