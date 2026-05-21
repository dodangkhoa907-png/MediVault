package com.medivault.entity;

public class PrescriptionDetails {
    private int prescriptionDetailId;
    private int prescriptionID;
    private int medicineID;
    private double dosageQuantity;
    private String dosageUnit;
    private String frequency;
    private Integer duration;
    private String usageInstruction;
    private int totalPrescribedQty;

    public PrescriptionDetails() {
    }

    public PrescriptionDetails(int prescriptionDetailId, int prescriptionID, int medicineID, double dosageQuantity, String dosageUnit, String frequency, Integer duration, String usageInstruction, int totalPrescribedQty) {
        this.prescriptionDetailId = prescriptionDetailId;
        this.prescriptionID = prescriptionID;
        this.medicineID = medicineID;
        this.dosageQuantity = dosageQuantity;
        this.dosageUnit = dosageUnit;
        this.frequency = frequency;
        this.duration = duration;
        this.usageInstruction = usageInstruction;
        this.totalPrescribedQty = totalPrescribedQty;
    }

    public int getPrescriptionDetailId() {
        return prescriptionDetailId;
    }

    public void setPrescriptionDetailId(int prescriptionDetailId) {
        this.prescriptionDetailId = prescriptionDetailId;
    }

    public int getPrescriptionID() {
        return prescriptionID;
    }

    public void setPrescriptionID(int prescriptionID) {
        this.prescriptionID = prescriptionID;
    }

    public int getMedicineID() {
        return medicineID;
    }

    public void setMedicineID(int medicineID) {
        this.medicineID = medicineID;
    }

    public double getDosageQuantity() {
        return dosageQuantity;
    }

    public void setDosageQuantity(double dosageQuantity) {
        this.dosageQuantity = dosageQuantity;
    }

    public String getDosageUnit() {
        return dosageUnit;
    }

    public void setDosageUnit(String dosageUnit) {
        this.dosageUnit = dosageUnit;
    }

    public String getFrequency() {
        return frequency;
    }

    public void setFrequency(String frequency) {
        this.frequency = frequency;
    }

    public Integer getDuration() {
        return duration;
    }

    public void setDuration(Integer duration) {
        this.duration = duration;
    }

    public String getUsageInstruction() {
        return usageInstruction;
    }

    public void setUsageInstruction(String usageInstruction) {
        this.usageInstruction = usageInstruction;
    }

    public int getTotalPrescribedQty() {
        return totalPrescribedQty;
    }

    public void setTotalPrescribedQty(int totalPrescribedQty) {
        this.totalPrescribedQty = totalPrescribedQty;
    }
}
