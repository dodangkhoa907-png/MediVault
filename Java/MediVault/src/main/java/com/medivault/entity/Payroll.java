package com.medivault.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class Payroll {
    private int payrollId;
    private int accountId;
    private int payMonth;           // 1-12
    private int payYear;
    private int totalScheduledDays; // Tổng ngày được xếp ca
    private int totalWorkedDays;    // Thực tế có mặt
    private BigDecimal totalHours;
    private BigDecimal overtimeHours;
    private BigDecimal baseSalary;
    private BigDecimal overtimePay;
    private BigDecimal allowance;
    private BigDecimal bonus;       // Admin nhập tay
    private BigDecimal deduction;   // Tổng khấu trừ
    private BigDecimal netSalary;   // Computed: base+OT+allow+bonus-deduct
    private String status;          // DRAFT | CONFIRMED | PAID
    private Integer confirmedBy;
    private LocalDateTime confirmedAt;
    private LocalDateTime paidAt;
    private String notes;
    private LocalDateTime createdAt;

    // ── Fields join ──
    private String staffName;
    private String confirmedByName;

    public Payroll() {}

    // ── Tiện ích ──
    public boolean isDraft()      { return "DRAFT".equals(status); }
    public boolean isConfirmed()  { return "CONFIRMED".equals(status); }
    public boolean isPaid()       { return "PAID".equals(status); }

    public String getMonthLabel() {
        return String.format("Tháng %d/%d", payMonth, payYear);
    }

    // Tính absence rate
    public double getAbsenceRate() {
        if (totalScheduledDays == 0) return 0.0;
        return (totalScheduledDays - totalWorkedDays) * 100.0 / totalScheduledDays;
    }

    // ── Getters & Setters ──
    public int getPayrollId()                        { return payrollId; }
    public void setPayrollId(int v)                  { this.payrollId = v; }
    public int getAccountId()                        { return accountId; }
    public void setAccountId(int v)                  { this.accountId = v; }
    public int getPayMonth()                         { return payMonth; }
    public void setPayMonth(int v)                   { this.payMonth = v; }
    public int getPayYear()                          { return payYear; }
    public void setPayYear(int v)                    { this.payYear = v; }
    public int getTotalScheduledDays()               { return totalScheduledDays; }
    public void setTotalScheduledDays(int v)         { this.totalScheduledDays = v; }
    public int getTotalWorkedDays()                  { return totalWorkedDays; }
    public void setTotalWorkedDays(int v)            { this.totalWorkedDays = v; }
    public BigDecimal getTotalHours()                { return totalHours; }
    public void setTotalHours(BigDecimal v)          { this.totalHours = v; }
    public BigDecimal getOvertimeHours()             { return overtimeHours; }
    public void setOvertimeHours(BigDecimal v)       { this.overtimeHours = v; }
    public BigDecimal getBaseSalary()                { return baseSalary; }
    public void setBaseSalary(BigDecimal v)          { this.baseSalary = v; }
    public BigDecimal getOvertimePay()               { return overtimePay; }
    public void setOvertimePay(BigDecimal v)         { this.overtimePay = v; }
    public BigDecimal getAllowance()                  { return allowance; }
    public void setAllowance(BigDecimal v)           { this.allowance = v; }
    public BigDecimal getBonus()                     { return bonus; }
    public void setBonus(BigDecimal v)               { this.bonus = v; }
    public BigDecimal getDeduction()                 { return deduction; }
    public void setDeduction(BigDecimal v)           { this.deduction = v; }
    public BigDecimal getNetSalary()                 { return netSalary; }
    public void setNetSalary(BigDecimal v)           { this.netSalary = v; }
    public String getStatus()                        { return status; }
    public void setStatus(String v)                  { this.status = v; }
    public Integer getConfirmedBy()                  { return confirmedBy; }
    public void setConfirmedBy(Integer v)            { this.confirmedBy = v; }
    public LocalDateTime getConfirmedAt()            { return confirmedAt; }
    public void setConfirmedAt(LocalDateTime v)      { this.confirmedAt = v; }
    public LocalDateTime getPaidAt()                 { return paidAt; }
    public void setPaidAt(LocalDateTime v)           { this.paidAt = v; }
    public String getNotes()                         { return notes; }
    public void setNotes(String v)                   { this.notes = v; }
    public LocalDateTime getCreatedAt()              { return createdAt; }
    public void setCreatedAt(LocalDateTime v)        { this.createdAt = v; }
    public String getStaffName()                     { return staffName; }
    public void setStaffName(String v)               { this.staffName = v; }
    public String getConfirmedByName()               { return confirmedByName; }
    public void setConfirmedByName(String v)         { this.confirmedByName = v; }
}
