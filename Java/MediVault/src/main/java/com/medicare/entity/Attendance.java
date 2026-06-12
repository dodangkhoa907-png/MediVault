package com.medicare.entity;

import java.time.LocalDateTime;

public class Attendance {
    private int attendanceId;
    private Integer scheduleId;
    private Integer shiftId;
    private int accountId;
    private LocalDateTime checkInTime;
    private LocalDateTime checkOutTime;
    private String checkInMethod;   // WEB_BUTTON | QR_CODE | NFC_CARD | ADMIN
    private String checkInNote;
    private int lateMinutes;
    private int earlyLeaveMinutes;
    private Double actualHours;
    private double overtimeHours;
    private boolean isAutoClose;
    private String attendanceStatus;
    private java.math.BigDecimal penaltyAmount;  // Số tiền phạt (0 nếu chưa xử lý)
    private java.math.BigDecimal handoverCash;   // Tiền bàn giao két khi check-out // NEW — tổng hợp tình trạng

    // ── Join fields ──
    private String staffName;
    private String shiftTypeName;
    private LocalDateTime plannedEnd;

    // ── Tiện ích ──
    public boolean isCheckedOut()  { return checkOutTime != null; }
    public boolean isActive()      { return checkOutTime == null; }
    public boolean isLate()        { return lateMinutes > 0; }
    public boolean isEarlyLeave()  { return earlyLeaveMinutes > 0; }
    public boolean isOvertime()    { return overtimeHours > 0; }
    public boolean isOnTime()           { return "ON_TIME".equals(attendanceStatus); }
    public boolean isLateUnexcused()    { return "LATE_UNEXCUSED".equals(attendanceStatus); }
    public boolean isSystemClosed()     { return "SYSTEM_CLOSED".equals(attendanceStatus); }
    public boolean isAbsent()           { return "ABSENT".equals(attendanceStatus); }
    public boolean isForceCheckout()    { return "FORCE_CHECKOUT".equals(attendanceStatus); }
    public boolean isPendingReview()    { return isLateUnexcused() || isSystemClosed(); }

    /** Label hiển thị cho badge */
    public String getStatusLabel() {
        if (attendanceStatus == null)
            return checkOutTime == null ? "Đang làm" : "Đã về";
        return switch (attendanceStatus) {
            case "CHECKED_IN"    -> "Đang làm";
            case "ON_TIME"       -> "Đúng giờ";
            case "LATE"          -> "Đến trễ " + lateMinutes + "p";
            case "EARLY_LEAVE"   -> "Về sớm " + earlyLeaveMinutes + "p";
            case "LATE_EARLY"    -> "Trễ & Về sớm";
            case "OVERTIME"      -> "Tăng ca +" + String.format("%.1f",overtimeHours) + "h";
            case "NO_SCHEDULE"   -> "Ca tự do";
            case "FORCE_CHECKOUT"  -> "Admin đóng";
            case "LATE_UNEXCUSED"  -> "Trễ chờ duyệt";
            case "SYSTEM_CLOSED"   -> "Hệ thống tự đóng";
            case "ABSENT"          -> "Vắng mặt";
            default                -> attendanceStatus;
        };
    }

    public String getStatusBadgeClass() {
        if (attendanceStatus == null) return "badge-working";
        return switch (attendanceStatus) {
            case "CHECKED_IN"    -> "badge-working";
            case "ON_TIME"       -> "badge-on-time";
            case "LATE"          -> "badge-late";
            case "EARLY_LEAVE"   -> "badge-early";
            case "LATE_EARLY"    -> "badge-late-early";
            case "OVERTIME"      -> "badge-overtime";
            case "NO_SCHEDULE"   -> "badge-free";
            case "FORCE_CHECKOUT"  -> "badge-force";
            case "LATE_UNEXCUSED"  -> "badge-unexcused";
            case "SYSTEM_CLOSED"   -> "badge-system-closed";
            case "ABSENT"          -> "badge-absent";
            default                -> "badge-default";
        };
    }

    /** Màu hex cho badge — dùng trực tiếp trong JSP nếu cần */
    public String getStatusColor() {
        if (attendanceStatus == null) return "#059669";
        return switch (attendanceStatus) {
            case "ON_TIME"       -> "#059669"; // green
            case "LATE","LATE_EARLY" -> "#D97706"; // amber
            case "EARLY_LEAVE"   -> "#7C3AED"; // purple
            case "OVERTIME"      -> "#1558A8"; // blue
            case "FORCE_CHECKOUT"  -> "#DC2626"; // red
            case "LATE_UNEXCUSED"  -> "#D97706"; // amber
            case "SYSTEM_CLOSED"   -> "#6366F1"; // indigo — chờ xử lý
            case "ABSENT"          -> "#DC2626"; // red
            case "NO_SCHEDULE"     -> "#64748B"; // slate
            default                -> "#059669";
        };
    }

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
    public String getAttendanceStatus()           { return attendanceStatus; }
    public void setAttendanceStatus(String v)     { this.attendanceStatus = v; }
    public String getStaffName()                  { return staffName; }
    public void setStaffName(String v)            { this.staffName = v; }
    public String getShiftTypeName()              { return shiftTypeName; }
    public void setShiftTypeName(String v)        { this.shiftTypeName = v; }
    public LocalDateTime getPlannedEnd()          { return plannedEnd; }
    public void setPlannedEnd(LocalDateTime v)    { this.plannedEnd = v; }
    public java.math.BigDecimal getPenaltyAmount()              { return penaltyAmount; }
    public void setPenaltyAmount(java.math.BigDecimal v)        { this.penaltyAmount = v; }
    public java.math.BigDecimal getHandoverCash()               { return handoverCash; }
    public void setHandoverCash(java.math.BigDecimal v)         { this.handoverCash = v; }
}