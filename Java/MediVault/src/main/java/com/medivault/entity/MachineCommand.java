package com.medivault.entity;

import java.time.LocalDateTime;

public class MachineCommand {
    private int commandId;
    private int detailId;
    private String machineSlotCode;
    private int quantity;
    private String status; // PENDING | PROCESSING | DONE | FAILED | CANCELLED
    private LocalDateTime createdAt;
    private LocalDateTime processedAt;
    private int retryCount;
    private String errorMessage;

    public MachineCommand() {}

    public MachineCommand(int commandId, int detailId, String machineSlotCode, int quantity, String status, LocalDateTime createdAt, LocalDateTime processedAt, int retryCount, String errorMessage) {
        this.commandId = commandId;
        this.detailId = detailId;
        this.machineSlotCode = machineSlotCode;
        this.quantity = quantity;
        this.status = status;
        this.createdAt = createdAt;
        this.processedAt = processedAt;
        this.retryCount = retryCount;
        this.errorMessage = errorMessage;
    }

    public int getCommandId() { return commandId; }
    public void setCommandId(int commandId) { this.commandId = commandId; }
    public int getDetailId() { return detailId; }
    public void setDetailId(int detailId) { this.detailId = detailId; }
    public String getMachineSlotCode() { return machineSlotCode; }
    public void setMachineSlotCode(String machineSlotCode) { this.machineSlotCode = machineSlotCode; }
    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getProcessedAt() { return processedAt; }
    public void setProcessedAt(LocalDateTime processedAt) { this.processedAt = processedAt; }
    public int getRetryCount() { return retryCount; }
    public void setRetryCount(int retryCount) { this.retryCount = retryCount; }
    public String getErrorMessage() { return errorMessage; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }
}