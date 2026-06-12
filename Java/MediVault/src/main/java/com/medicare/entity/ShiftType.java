package com.medicare.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class ShiftType {
    private int shiftTypeId;
    private String name;           // Ca sáng / Ca chiều / Ca tối
    private int startHour;
    private int startMinute;
    private int endHour;
    private int endMinute;
    private BigDecimal hourlyRate;
    private BigDecimal overtimeMultiplier;
    private BigDecimal allowanceAmount;
    private boolean isActive;
    private LocalDateTime createdAt;

    public ShiftType() {}

    // ── Tiện ích: mô tả giờ dạng "06:00 – 14:00" ──
    public String getTimeRange() {
        return String.format("%02d:%02d – %02d:%02d",
                startHour, startMinute, endHour, endMinute);
    }

    // ── Tính tổng giờ của ca (xử lý ca qua đêm) ──
    public double getPlannedHours() {
        int startTotal = startHour * 60 + startMinute;
        int endTotal   = endHour   * 60 + endMinute;
        if (endTotal <= startTotal) endTotal += 24 * 60; // qua đêm
        return (endTotal - startTotal) / 60.0;
    }

    // ── Getters & Setters ──
    public int getShiftTypeId()                      { return shiftTypeId; }
    public void setShiftTypeId(int v)                { this.shiftTypeId = v; }
    public String getName()                          { return name; }
    public void setName(String v)                    { this.name = v; }
    public int getStartHour()                        { return startHour; }
    public void setStartHour(int v)                  { this.startHour = v; }
    public int getStartMinute()                      { return startMinute; }
    public void setStartMinute(int v)                { this.startMinute = v; }
    public int getEndHour()                          { return endHour; }
    public void setEndHour(int v)                    { this.endHour = v; }
    public int getEndMinute()                        { return endMinute; }
    public void setEndMinute(int v)                  { this.endMinute = v; }
    public BigDecimal getHourlyRate()                { return hourlyRate; }
    public void setHourlyRate(BigDecimal v)          { this.hourlyRate = v; }
    public BigDecimal getOvertimeMultiplier()        { return overtimeMultiplier; }
    public void setOvertimeMultiplier(BigDecimal v)  { this.overtimeMultiplier = v; }
    public BigDecimal getAllowanceAmount()            { return allowanceAmount; }
    public void setAllowanceAmount(BigDecimal v)     { this.allowanceAmount = v; }
    public boolean isActive()                        { return isActive; }
    public void setActive(boolean v)                 { this.isActive = v; }
    public LocalDateTime getCreatedAt()              { return createdAt; }
    public void setCreatedAt(LocalDateTime v)        { this.createdAt = v; }
}
