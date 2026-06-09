package com.medivault.entity;

import java.time.LocalDateTime;

public class Attendance {
    private int attendanceId;
    private Integer scheduleId;    // NULL nếu check-in không theo lịch
    private Integer shiftId;       // Link sang Shifts
    private int accountId;
    private LocalDateTime checkInTime;
    private LocalDateTime checkOutTime;
    private String checkInMethod;  // WEB_BUTTON | QR_CODE | NFC_CARD | ADMIN
    private String checkInNote;
    private int lateMinutes;       // Tính tự động bởi trigger DB
    private int earlyLeaveMinutes; // Tính tự động khi check-out
    private Double actualHours;    // Computed column trong DB
    private double overtimeHours;
    private boolean isAutoClose;

    // ── Fields join (dùng khi query có JOIN) ──
    private String staffName;
    private String shiftTypeName;
    private LocalDateTime plannedEnd; // từ ShiftSchedules

    public Attendance() {}

    // ── Tiện ích ──
    public boolean isCheckedOut()  { return checkOutTime != null; }
    public boolean isActive()      { return checkOutTime == null; }
    public boolean isLate()        { return lateMinutes > 0; }

    // ── Getters & Setters ──
    public int getAttendanceId()                  { return attendanceId; }
    public void setAttendanceId(int v)            { this.attendanceId = v; }
    public Integer getScheduleId()                { return scheduleId; }
    public void setScheduleId(Integer v)          { this.scheduleId = v; }
    public Integer getShiftId()                   { return shiftId; }
    public void setShiftId(Integer v)             { this.shiftId = v; }
    public int getAccountId()                     { return accountId; }
    public void setAccountId(int v)               { this.accountId = v; }
    public LocalDateTime getCheckInTime()         { return checkInTime; }
    public void setCheckInTime(LocalDateTime v)   { this.checkInTime = v; }
    public LocalDateTime getCheckOutTime()        { return checkOutTime; }
    public void setCheckOutTime(LocalDateTime v)  { this.checkOutTime = v; }
    public String getCheckInMethod()              { return checkInMethod; }
    public void setCheckInMethod(String v)        { this.checkInMethod = v; }
    public String getCheckInNote()                { return checkInNote; }
    public void setCheckInNote(String v)          { this.checkInNote = v; }
    public int getLateMinutes()                   { return lateMinutes; }
    public void setLateMinutes(int v)             { this.lateMinutes = v; }
    public int getEarlyLeaveMinutes()             { return earlyLeaveMinutes; }
    public void setEarlyLeaveMinutes(int v)       { this.earlyLeaveMinutes = v; }
    public Double getActualHours()                { return actualHours; }
    public void setActualHours(Double v)          { this.actualHours = v; }
    public double getOvertimeHours()              { return overtimeHours; }
    public void setOvertimeHours(double v)        { this.overtimeHours = v; }
    public boolean isAutoClose()                  { return isAutoClose; }
    public void setAutoClose(boolean v)           { this.isAutoClose = v; }
    public String getStaffName()                  { return staffName; }
    public void setStaffName(String v)            { this.staffName = v; }
    public String getShiftTypeName()              { return shiftTypeName; }
    public void setShiftTypeName(String v)        { this.shiftTypeName = v; }
    public LocalDateTime getPlannedEnd()          { return plannedEnd; }
    public void setPlannedEnd(LocalDateTime v)    { this.plannedEnd = v; }
}
