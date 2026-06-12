package com.medicare.entity;

import java.time.LocalDate;
import java.time.LocalDateTime;

public class Prescription {
    private int prescriptionId;
    private Integer customerId;
    private String doctorName;
    private String hospitalName;
    private LocalDate prescriptionDate;
    private String imagePath;
    private String notes;
    private LocalDateTime createdAt;

    public Prescription() {}

    public Prescription(int prescriptionId, Integer customerId, String doctorName, String hospitalName, LocalDate prescriptionDate, String imagePath, String notes, LocalDateTime createdAt) {
        this.prescriptionId = prescriptionId;
        this.customerId = customerId;
        this.doctorName = doctorName;
        this.hospitalName = hospitalName;
        this.prescriptionDate = prescriptionDate;
        this.imagePath = imagePath;
        this.notes = notes;
        this.createdAt = createdAt;
    }

    public int getPrescriptionId() { return prescriptionId; }
    public void setPrescriptionId(int prescriptionId) { this.prescriptionId = prescriptionId; }
    public Integer getCustomerId() { return customerId; }
    public void setCustomerId(Integer customerId) { this.customerId = customerId; }
    public String getDoctorName() { return doctorName; }
    public void setDoctorName(String doctorName) { this.doctorName = doctorName; }
    public String getHospitalName() { return hospitalName; }
    public void setHospitalName(String hospitalName) { this.hospitalName = hospitalName; }
    public LocalDate getPrescriptionDate() { return prescriptionDate; }
    public void setPrescriptionDate(LocalDate prescriptionDate) { this.prescriptionDate = prescriptionDate; }
    public String getImagePath() { return imagePath; }
    public void setImagePath(String imagePath) { this.imagePath = imagePath; }
    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}