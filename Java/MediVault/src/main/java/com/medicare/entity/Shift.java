package com.medicare.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class Shift {
    private int shiftId;
    private int accountId;
    private String fullName;   // JOIN từ Accounts.FullName
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private BigDecimal openingCash;
    private BigDecimal closingCash;
    private String notes;
    private int gracePeriodMinutes;
    private String status; // OPEN | CLOSED | FORCE_CLOSED | SYSTEM_CLOSED | ABANDONED

    // ── Tiện ích — tính từ status (không cần check endTime nữa) ──
    public boolean isOpen()        { return "OPEN".equals(status) || (status == null && endTime == null); }
    public boolean isClosed()      { return "CLOSED".equals(status); }
    public boolean isForceClose()  { return "FORCE_CLOSED".equals(status); }
    public boolean isAbandoned()     { return "ABANDONED".equals(status); }
    public boolean isSystemClosed()  { return "SYSTEM_CLOSED".equals(status); }

    public String getStatusLabel() {
        if (status == null) return endTime == null ? "Đang mở" : "Đã đóng";
        return switch (status) {
            case "OPEN"         -> "Đang mở";
            case "CLOSED"       -> "Đã đóng";
            case "FORCE_CLOSED" -> "Đóng cưỡng chế";
            case "ABANDONED"      -> "Bỏ ca";
            case "SYSTEM_CLOSED"  -> "Hệ thống tự đóng";
            default               -> status;
        };
    }

    public String getStatusBadgeClass() {
        if (status == null) return endTime == null ? "badge-open" : "badge-closed";
        return switch (status) {
            case "OPEN"         -> "badge-open";
            case "FORCE_CLOSED" -> "badge-force-close";
            case "ABANDONED"      -> "badge-abandoned";
            case "SYSTEM_CLOSED"  -> "badge-system-closed";
            default               -> "badge-closed";
        };
    }

    /**
     * Tính thời lượng ca — hiển thị dạng "2g 30p" hoặc "Đang chạy Xg Yp".
     * Dùng trực tiếp trong JSP: ${s.durationDisplay}
     */
    public String getDurationDisplay() {
        java.time.LocalDateTime from = startTime;
        java.time.LocalDateTime to   = isOpen() ? java.time.LocalDateTime.now() : endTime;
        if (from == null || to == null) return "—";
        long totalMinutes = java.time.temporal.ChronoUnit.MINUTES.between(from, to);
        if (totalMinutes < 0) totalMinutes = 0;
        long hours   = totalMinutes / 60;
        long minutes = totalMinutes % 60;
        String display = (hours > 0 ? hours + "g " : "") + minutes + "p";
        return display.trim().isEmpty() ? "< 1p" : display.trim();
    }

    // ── Getters & Setters ──
    public int getShiftId()                      { return shiftId; }
    public void setShiftId(int v)                { this.shiftId = v; }
    public int getAccountId()                    { return accountId; }
    public void setAccountId(int v)              { this.accountId = v; }
    public String getFullName()                  { return fullName; }
    public void setFullName(String v)            { this.fullName = v; }
    public LocalDateTime getStartTime()          { return startTime; }
    public void setStartTime(LocalDateTime v)    { this.startTime = v; }
    public LocalDateTime getEndTime()            { return endTime; }
    public void setEndTime(LocalDateTime v)      { this.endTime = v; }
    public BigDecimal getOpeningCash()           { return openingCash; }
    public void setOpeningCash(BigDecimal v)     { this.openingCash = v; }
    public BigDecimal getClosingCash()           { return closingCash; }
    public void setClosingCash(BigDecimal v)     { this.closingCash = v; }
    public String getNotes()                     { return notes; }
    public void setNotes(String v)               { this.notes = v; }
    public int getGracePeriodMinutes()           { return gracePeriodMinutes; }
    public void setGracePeriodMinutes(int v)     { this.gracePeriodMinutes = v; }
    public String getStatus()                    { return status; }
    public void setStatus(String v)              { this.status = v; }
}