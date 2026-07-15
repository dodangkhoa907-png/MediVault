package com.medicare.entity;

public class PosStation {
    private int posStationId;
    private String stationName;
    private boolean isActive;

    public PosStation() {}

    public PosStation(int posStationId, String stationName, boolean isActive) {
        this.posStationId = posStationId;
        this.stationName = stationName;
        this.isActive = isActive;
    }

    public int getPosStationId() {
        return posStationId;
    }

    public void setPosStationId(int posStationId) {
        this.posStationId = posStationId;
    }

    public String getStationName() {
        return stationName;
    }

    public void setStationName(String stationName) {
        this.stationName = stationName;
    }

    public boolean isActive() {
        return isActive;
    }

    public void setActive(boolean active) {
        isActive = active;
    }

    @Override
    public String toString() {
        return "PosStation{posStationId=" + posStationId + ", stationName='" + stationName + "', isActive=" + isActive + "}";
    }
}
