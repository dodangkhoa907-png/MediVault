package com.medicare.entity;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

public class ShiftSchedule {
    private int scheduleId;
    private int accountId;
    private int shiftTypeId;
    private LocalDate workDate;
    private LocalDateTime plannedStart;
    private LocalDateTime plannedEnd;
    private int lateToleranceMinutes;
    private String status;
    // SCHEDULED | CONFIRMED | LATE | ABSENT | ON_LEAVE | LEAVE_PENDING | CANCELLED
    private BigDecimal openingCash;          // Admin set từng ngày, tối thiểu 50,000đ
    private BigDecimal penaltyRatePerMinute;  // Phạt mỗi phút trễ/lố giờ (mặc định 5,000đ) | CONFIRMED | LATE | ABSENT | ON_LEAVE | LEAVE_PENDING | CANCELLED
    private String notes;
    private int createdBy;
    private LocalDateTime createdAt;

    // ── Join fields ──
    private String staffName;
    private String shiftTypeName;
    private int startHour;
    private int endHour;

    public BigDecimal getOpeningCash()               { return openingCash; }
    public void setOpeningCash(BigDecimal v)         { this.openingCash = v; }
    public BigDecimal getPenaltyRatePerMinute()      { return penaltyRatePerMinute != null ? penaltyRatePerMinute : new BigDecimal("5000"); }
    public void setPenaltyRatePerMinute(BigDecimal v){ this.penaltyRatePerMinute = v; }

    // ── Tiện ích ──
    public boolean isScheduled()    { return "SCHEDULED".equals(status); }
    public boolean isConfirmed()    { return "CONFIRMED".equals(status); }
    public boolean isLate()         { return "LATE".equals(status); }
    public boolean isAbsent()       { return "ABSENT".equals(status); }
    public boolean isOnLeave()      { return "ON_LEAVE".equals(status); }
    public boolean isLeavePending() { return "LEAVE_PENDING".equals(status); }
    public boolean isCancelled()    { return "CANCELLED".equals(status); }

    public String getStatusLabel() {
        if (status == null) return "—";
        return switch (status) {
            case "SCHEDULED"     -> "Chưa vào";
            case "CONFIRMED"     -> "Đã check-in";
            case "LATE"          -> "Đến trễ";
            case "ABSENT"        -> "Vắng mặt";
            case "ON_LEAVE"      -> "Nghỉ phép";
            case "LEAVE_PENDING" -> "Chờ duyệt nghỉ";
            case "CANCELLED"     -> "Đã hủy";
            default              -> status;
        };
    }

    public String getStatusIcon() {
        if (status == null) return "⏳";
        return switch (status) {
            case "SCHEDULED"     -> "⏳";
            case "CONFIRMED"     -> "✅";
            case "LATE"          -> "⚠️";
            case "ABSENT"        -> "❌";
            case "ON_LEAVE"      -> "🏖️";
            case "LEAVE_PENDING" -> "📋";
            case "CANCELLED"     -> "🚫";
            default              -> "❓";
        };
    }

    // ── Getters & Setters ──
    public int getScheduleId()                   { return scheduleId; }
    public void setScheduleId(int v)             { this.scheduleId = v; }
    public int getAccountId()                    { return accountId; }
    public void setAccountId(int v)              { this.accountId = v; }
    public int getShiftTypeId()                  { return shiftTypeId; }
    public void setShiftTypeId(int v)            { this.shiftTypeId = v; }
    public LocalDate getWorkDate()               { return workDate; }
    public void setWorkDate(LocalDate v)         { this.workDate = v; }
    public LocalDateTime getPlannedStart()       { return plannedStart; }
    public void setPlannedStart(LocalDateTime v) { this.plannedStart = v; }
    public LocalDateTime getPlannedEnd()         { return plannedEnd; }
    public void setPlannedEnd(LocalDateTime v)   { this.plannedEnd = v; }
    public int getLateToleranceMinutes()         { return lateToleranceMinutes; }
    public void setLateToleranceMinutes(int v)   { this.lateToleranceMinutes = v; }
    public String getStatus()                    { return status; }
    public void setStatus(String v)              { this.status = v; }
    public String getNotes()                     { return notes; }
    public void setNotes(String v)               { this.notes = v; }
    public int getCreatedBy()                    { return createdBy; }
    public void setCreatedBy(int v)              { this.createdBy = v; }
    public LocalDateTime getCreatedAt()          { return createdAt; }
    public void setCreatedAt(LocalDateTime v)    { this.createdAt = v; }
    public String getStaffName()                 { return staffName; }
    public void setStaffName(String v)           { this.staffName = v; }
    public String getShiftTypeName()             { return shiftTypeName; }
    public void setShiftTypeName(String v)       { this.shiftTypeName = v; }
    public int getStartHour()                    { return startHour; }
    public void setStartHour(int v)              { this.startHour = v; }
    public int getEndHour()                      { return endHour; }
    public void setEndHour(int v)                { this.endHour = v; }
}