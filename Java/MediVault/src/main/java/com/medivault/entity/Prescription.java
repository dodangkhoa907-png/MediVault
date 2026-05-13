package com.medivault.entity;

import java.time.LocalDateTime;

public class Prescription {
    private int prescriptionID;
    private int customerID;
    private String doctorName;
    private String hospitalName;
    private LocalDateTime prescriptionDate;
    private String imagePath;
    private String notes;
    private LocalDateTime createdAt;

    public Prescription() {
    }

    public Prescription(int prescriptionID, int customerID, String doctorName, String hospitalName, LocalDateTime prescriptionDate, String imagePath, String notes, LocalDateTime CreatedAt) {
        this.prescriptionID = prescriptionID;
        this.customerID = customerID;
        this.doctorName = doctorName;
        this.hospitalName = hospitalName;
        this.prescriptionDate = prescriptionDate;
        this.imagePath = imagePath;
        this.notes = notes;
        this.createdAt = createdAt;
    }

    public int getPrescriptionID() {
        return prescriptionID;
    }

    public void setPrescriptionID(int prescriptionID) {
        this.prescriptionID = prescriptionID;
    }

    public int getCustomerID() {
        return customerID;
    }

    public void setCustomerID(int customerID) {
        this.customerID = customerID;
    }

    public String getDoctorName() {
        return doctorName;
    }

    public void setDoctorName(String doctorName) {
        this.doctorName = doctorName;
    }

    public String getHospitalName() {
        return hospitalName;
    }

    public void setHospitalName(String hospitalName) {
        this.hospitalName = hospitalName;
    }

    public LocalDateTime getPrescriptionDate() {
        return prescriptionDate;
    }

    public void setPrescriptionDate(LocalDateTime prescriptionDate) {
        this.prescriptionDate = prescriptionDate;
    }

    public String getImagePath() {
        return imagePath;
    }

    public void setImagePath(String imagePath) {
        this.imagePath = imagePath;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public LocalDateTime getcreatedAt() {
        return createdAt;
    }

    public void setcreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    @Override
    public String toString() {
        return "Prescription{" + "prescriptionID=" + prescriptionID + ", customerID=" + customerID + ", doctorName=" + doctorName + ", hospitalName=" + hospitalName + ", prescriptionDate=" + prescriptionDate + ", imagePath=" + imagePath + ", notes=" + notes + ", CreatedAt=" + createdAt + '}';
    }

}
