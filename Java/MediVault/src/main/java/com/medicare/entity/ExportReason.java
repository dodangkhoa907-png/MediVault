package com.medicare.entity;

public class ExportReason {
    private int reasonId;
    private String reasonCode;
    private String reasonName;
    private String description;
    private boolean requiresReceiver;
    private boolean isActive;

    public int getReasonId() { return reasonId; }
    public void setReasonId(int reasonId) { this.reasonId = reasonId; }

    public String getReasonCode() { return reasonCode; }
    public void setReasonCode(String reasonCode) { this.reasonCode = reasonCode; }

    public String getReasonName() { return reasonName; }
    public void setReasonName(String reasonName) { this.reasonName = reasonName; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public boolean isRequiresReceiver() { return requiresReceiver; }
    public void setRequiresReceiver(boolean requiresReceiver) { this.requiresReceiver = requiresReceiver; }

    public boolean isActive() { return isActive; }
    public void setActive(boolean active) { isActive = active; }
}
