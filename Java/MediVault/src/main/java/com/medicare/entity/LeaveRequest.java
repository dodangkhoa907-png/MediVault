package com.medicare.entity;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

public class LeaveRequest {
    private int leaveId;
    private int accountId;
    private LocalDate leaveDate;
    private String leaveType;   // ANNUAL | SICK | UNPAID | SUDDEN
    private String reason;
    private String status;      // PENDING | APPROVED | REJECTED
    private Integer approvedBy;
    private LocalDateTime approvedAt;
    private BigDecimal deductHours;
    private BigDecimal deductAmount;
    private LocalDateTime requestedAt;
    private String notes;       // Ghi chú của admin khi duyệt

    // ── Fields join ──
    private String staffName;
    private String approvedByName;

    public LeaveRequest() {}

    // ── Tiện ích ──
    public boolean isPending()   { return "PENDING".equals(status); }
    public boolean isApproved()  { return "APPROVED".equals(status); }
    public boolean isRejected()  { return "REJECTED".equals(status); }

    public String getLeaveTypeLabel() {
        if (leaveType == null) return "";
        return switch (leaveType) {
            case "ANNUAL"  -> "Nghỉ phép năm";
            case "SICK"    -> "Nghỉ ốm";
            case "UNPAID"  -> "Nghỉ không lương";
            case "SUDDEN"  -> "Nghỉ đột xuất";
            default        -> leaveType;
        };
    }

    // ── Getters & Setters ──
    public int getLeaveId()                        { return leaveId; }
    public void setLeaveId(int v)                  { this.leaveId = v; }
    public int getAccountId()                      { return accountId; }
    public void setAccountId(int v)                { this.accountId = v; }
    public LocalDate getLeaveDate()                { return leaveDate; }
    public void setLeaveDate(LocalDate v)          { this.leaveDate = v; }
    public String getLeaveType()                   { return leaveType; }
    public void setLeaveType(String v)             { this.leaveType = v; }
    public String getReason()                      { return reason; }
    public void setReason(String v)                { this.reason = v; }
    public String getStatus()                      { return status; }
    public void setStatus(String v)                { this.status = v; }
    public Integer getApprovedBy()                 { return approvedBy; }
    public void setApprovedBy(Integer v)           { this.approvedBy = v; }
    public LocalDateTime getApprovedAt()           { return approvedAt; }
    public void setApprovedAt(LocalDateTime v)     { this.approvedAt = v; }
    public BigDecimal getDeductHours()             { return deductHours; }
    public void setDeductHours(BigDecimal v)       { this.deductHours = v; }
    public BigDecimal getDeductAmount()            { return deductAmount; }
    public void setDeductAmount(BigDecimal v)      { this.deductAmount = v; }
    public LocalDateTime getRequestedAt()          { return requestedAt; }
    public void setRequestedAt(LocalDateTime v)    { this.requestedAt = v; }
    public String getNotes()                       { return notes; }
    public void setNotes(String v)                 { this.notes = v; }
    public String getStaffName()                   { return staffName; }
    public void setStaffName(String v)             { this.staffName = v; }
    public String getApprovedByName()              { return approvedByName; }
    public void setApprovedByName(String v)        { this.approvedByName = v; }
}
