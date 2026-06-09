package com.medivault.entity;

import java.time.LocalDate;
import java.time.LocalDateTime;

public class ShiftSchedule {
    private int scheduleId;
    private int accountId;
    private int shiftTypeId;
    private LocalDate workDate;
    private LocalDateTime plannedStart;
    private LocalDateTime plannedEnd;
    private int lateToleranceMinutes;  // Cho phép trễ tối đa X phút
    private String status;
    // SCHEDULED | CONFIRMED | ABSENT | ON_LEAVE | CANCELLED
    private String notes;
    private int createdBy;
    private LocalDateTime createdAt;

    // ── Fields join từ bảng khác (dùng khi query có JOIN) ──
    private String staffName;       // từ Accounts.FullName
    private String shiftTypeName;   // từ ShiftTypes.Name
    private int startHour;
    private int endHour;

    public ShiftSchedule() {}

    // ── Tiện ích ──
    public boolean isOpen()       { return "SCHEDULED".equals(status); }
    public boolean isConfirmed()  { return "CONFIRMED".equals(status); }
    public boolean isAbsent()     { return "ABSENT".equals(status); }
    public boolean isOnLeave()    { return "ON_LEAVE".equals(status); }

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
