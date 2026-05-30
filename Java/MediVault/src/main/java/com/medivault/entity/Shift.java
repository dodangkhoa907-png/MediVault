package com.medivault.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class Shift {
    private int shiftId;
    private int accountId;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private BigDecimal openingCash;
    private BigDecimal closingCash;
    private String notes;
    private int gracePeriodMinutes;

    public Shift() {
    }

    public Shift(int shiftId, int accountId, LocalDateTime startTime, LocalDateTime endTime, BigDecimal openingCash, BigDecimal closingCash, String notes, int gracePeriodMinutes) {
        this.shiftId = shiftId;
        this.accountId = accountId;
        this.startTime = startTime;
        this.endTime = endTime;
        this.openingCash = openingCash;
        this.closingCash = closingCash;
        this.notes = notes;
        this.gracePeriodMinutes = gracePeriodMinutes;
    }

    public int getShiftId() {
        return shiftId;
    }

    public void setShiftId(int shiftId) {
        this.shiftId = shiftId;
    }

    public int getAccountId() {
        return accountId;
    }

    public void setAccountId(int accountId) {
        this.accountId = accountId;
    }

    public LocalDateTime getStartTime() {
        return startTime;
    }

    public void setStartTime(LocalDateTime startTime) {
        this.startTime = startTime;
    }

    public LocalDateTime getEndTime() {
        return endTime;
    }

    public void setEndTime(LocalDateTime endTime) {
        this.endTime = endTime;
    }

    public BigDecimal getOpeningCash() {
        return openingCash;
    }

    public void setOpeningCash(BigDecimal openingCash) {
        this.openingCash = openingCash;
    }

    public BigDecimal getClosingCash() {
        return closingCash;
    }

    public void setClosingCash(BigDecimal closingCash) {
        this.closingCash = closingCash;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public int getGracePeriodMinutes() {
        return gracePeriodMinutes;
    }

    public void setGracePeriodMinutes(int gracePeriodMinutes) {
        this.gracePeriodMinutes = gracePeriodMinutes;
    }
}