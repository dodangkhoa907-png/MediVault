package com.medicare.entity;

import java.time.LocalDateTime;

/** Chứng từ xuất kho (header) — tương đương PurchaseOrders nhưng cho chiều xuất. */
public class WarehouseExport {
    private int exportId;
    private String exportCode; // computed: 'PX' + ExportID
    private int reasonId;
    private String status = "PENDING"; // PENDING | CONFIRMED | CANCELLED | REVERSED
    private String receiver;
    private String notes;
    private boolean fefoOverridden;
    private String overrideReason;
    private Integer overrideBy;
    private int createdBy;
    private LocalDateTime createdAt;
    private LocalDateTime confirmedAt;

    // Transient — populated by JOIN queries for list/detail views
    private String reasonName;
    private String reasonCode;
    private String createdByName;

    public int getExportId() { return exportId; }
    public void setExportId(int exportId) { this.exportId = exportId; }

    public String getExportCode() { return exportCode; }
    public void setExportCode(String exportCode) { this.exportCode = exportCode; }

    public int getReasonId() { return reasonId; }
    public void setReasonId(int reasonId) { this.reasonId = reasonId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getReceiver() { return receiver; }
    public void setReceiver(String receiver) { this.receiver = receiver; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    public boolean isFefoOverridden() { return fefoOverridden; }
    public void setFefoOverridden(boolean fefoOverridden) { this.fefoOverridden = fefoOverridden; }

    public String getOverrideReason() { return overrideReason; }
    public void setOverrideReason(String overrideReason) { this.overrideReason = overrideReason; }

    public Integer getOverrideBy() { return overrideBy; }
    public void setOverrideBy(Integer overrideBy) { this.overrideBy = overrideBy; }

    public int getCreatedBy() { return createdBy; }
    public void setCreatedBy(int createdBy) { this.createdBy = createdBy; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getConfirmedAt() { return confirmedAt; }
    public void setConfirmedAt(LocalDateTime confirmedAt) { this.confirmedAt = confirmedAt; }

    public String getReasonName() { return reasonName; }
    public void setReasonName(String reasonName) { this.reasonName = reasonName; }

    public String getReasonCode() { return reasonCode; }
    public void setReasonCode(String reasonCode) { this.reasonCode = reasonCode; }

    public String getCreatedByName() { return createdByName; }
    public void setCreatedByName(String createdByName) { this.createdByName = createdByName; }
}
