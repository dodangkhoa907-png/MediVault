package com.medivault.entity;

import java.time.LocalDateTime;


public class Shift {
    private int shiftId;
    private int accountId;
    private LocalDateTime startTime;
    private LocalDateTime endTime;
    private double openingCash;
    private Double closingCash;
    private String notes;

    public Shift() {
    }

    public Shift(int shiftId, int accountId, LocalDateTime startTime, LocalDateTime endTime, double openingCash, Double closingCash, String notes) {
        this.shiftId = shiftId;
        this.accountId = accountId;
        this.startTime = startTime;
        this.endTime = endTime;
        this.openingCash = openingCash;
        this.closingCash = closingCash;
        this.notes = notes;
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

    public double getOpeningCash() {
        return openingCash;
    }

    public void setOpeningCash(double openingCash) {
        this.openingCash = openingCash;
    }

    public Double getClosingCash() {
        return closingCash;
    }

    public void setClosingCash(Double closingCash) {
        this.closingCash = closingCash;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    @Override
    public String toString() {
        return "Shift{" + "shiftId=" + shiftId + ", accountId=" + accountId + ", startTime=" + startTime + ", endTime=" + endTime + ", openingCash=" + openingCash + ", closingCash=" + closingCash + ", notes=" + notes + '}';
    }
}
