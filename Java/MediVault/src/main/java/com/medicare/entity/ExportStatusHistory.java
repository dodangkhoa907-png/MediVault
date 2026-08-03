package com.medicare.entity;

import java.time.LocalDateTime;

public class ExportStatusHistory {
    private int historyId;
    private int exportId;
    private String status;
    private Integer accountId;
    private String notes;
    private LocalDateTime createdAt;

    // Transient — populated by JOIN queries
    private String accountName;

    public int getHistoryId() { return historyId; }
    public void setHistoryId(int historyId) { this.historyId = historyId; }

    public int getExportId() { return exportId; }
    public void setExportId(int exportId) { this.exportId = exportId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Integer getAccountId() { return accountId; }
    public void setAccountId(Integer accountId) { this.accountId = accountId; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public String getAccountName() { return accountName; }
    public void setAccountName(String accountName) { this.accountName = accountName; }
}
