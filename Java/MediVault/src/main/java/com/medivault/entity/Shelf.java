package com.medivault.entity;

public class Shelf {
    private int shelfId;
    private String shelfName;
    private String machineSlotCode;
    private String motorId;
    private String locationNotes;
    private boolean isAutomated; // computed column

    public Shelf() {}

    public Shelf(int shelfId, String shelfName, String machineSlotCode, String motorId, String locationNotes, boolean isAutomated) {
        this.shelfId = shelfId;
        this.shelfName = shelfName;
        this.machineSlotCode = machineSlotCode;
        this.motorId = motorId;
        this.locationNotes = locationNotes;
        this.isAutomated = isAutomated;
    }

    public int getShelfId() { return shelfId; }
    public void setShelfId(int shelfId) { this.shelfId = shelfId; }
    public String getShelfName() { return shelfName; }
    public void setShelfName(String shelfName) { this.shelfName = shelfName; }
    public String getMachineSlotCode() { return machineSlotCode; }
    public void setMachineSlotCode(String machineSlotCode) { this.machineSlotCode = machineSlotCode; }
    public String getMotorId() { return motorId; }
    public void setMotorId(String motorId) { this.motorId = motorId; }
    public String getLocationNotes() { return locationNotes; }
    public void setLocationNotes(String locationNotes) { this.locationNotes = locationNotes; }
    public boolean isAutomated() { return isAutomated; }
    public void setAutomated(boolean automated) { isAutomated = automated; }
}