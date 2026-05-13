package com.medivault.entity;

import java.time.LocalDateTime;

public class Medicines {
    private int medicineId;
    private String medicineCodex;

    //định danh
    private String medicineName;
    private String genericName;
    private String barcode;
    private String registrationNumber;

    //phân loại
    private int categoryID;
    private int manufacturerID;
    private String unit;

    //vị trí
    private int shelfId;

    //bảo quản
    private double storageTempMin;
    private double storageTempMax;
    private String storageConditions;

    //Sử dụng
    private String dosage;
    private String contraindications;
    private boolean isPrescriptionRequired;

    //giá & kho
    private double sellingPrice;
    private int minInventory;

    //trang thai
    private boolean status;
    private LocalDateTime createdAt;

    public Medicines() {
    }

    public Medicines(int medicineId, String medicineCodex, String medicineName, String genericName, String barcode, String registrationNumber, int categoryID, int manufacturerID, String unit, int shelfId, double storageTempMin, double storageTempMax, String storageConditions, String dosage, String contraindications, boolean isPrescriptionRequired, double sellingPrice, int minInventory, boolean status, LocalDateTime createdAt) {
        this.medicineId = medicineId;
        this.medicineCodex = medicineCodex;
        this.medicineName = medicineName;
        this.genericName = genericName;
        this.barcode = barcode;
        this.registrationNumber = registrationNumber;
        this.categoryID = categoryID;
        this.manufacturerID = manufacturerID;
        this.unit = unit;
        this.shelfId = shelfId;
        this.storageTempMin = storageTempMin;
        this.storageTempMax = storageTempMax;
        this.storageConditions = storageConditions;
        this.dosage = dosage;
        this.contraindications = contraindications;
        this.isPrescriptionRequired = isPrescriptionRequired;
        this.sellingPrice = sellingPrice;
        this.minInventory = minInventory;
        this.status = status;
        this.createdAt = createdAt;
    }

    public int getMedicineId() {
        return medicineId;
    }

    public void setMedicineId(int medicineId) {
        this.medicineId = medicineId;
    }

    public String getMedicineCodex() {
        return medicineCodex;
    }

    public void setMedicineCodex(String medicineCodex) {
        this.medicineCodex = medicineCodex;
    }

    public String getMedicineName() {
        return medicineName;
    }

    public void setMedicineName(String medicineName) {
        this.medicineName = medicineName;
    }

    public String getGenericName() {
        return genericName;
    }

    public void setGenericName(String genericName) {
        this.genericName = genericName;
    }

    public String getBarcode() {
        return barcode;
    }

    public void setBarcode(String barcode) {
        this.barcode = barcode;
    }

    public String getRegistrationNumber() {
        return registrationNumber;
    }

    public void setRegistrationNumber(String registrationNumber) {
        this.registrationNumber = registrationNumber;
    }

    public int getCategoryID() {
        return categoryID;
    }

    public void setCategoryID(int categoryID) {
        this.categoryID = categoryID;
    }

    public int getManufacturerID() {
        return manufacturerID;
    }

    public void setManufacturerID(int manufacturerID) {
        this.manufacturerID = manufacturerID;
    }

    public String getUnit() {
        return unit;
    }

    public void setUnit(String unit) {
        this.unit = unit;
    }

    public int getShelfId() {
        return shelfId;
    }

    public void setShelfId(int shelfId) {
        this.shelfId = shelfId;
    }

    public double getStorageTempMin() {
        return storageTempMin;
    }

    public void setStorageTempMin(double storageTempMin) {
        this.storageTempMin = storageTempMin;
    }

    public double getStorageTempMax() {
        return storageTempMax;
    }

    public void setStorageTempMax(double storageTempMax) {
        this.storageTempMax = storageTempMax;
    }

    public String getStorageConditions() {
        return storageConditions;
    }

    public void setStorageConditions(String storageConditions) {
        this.storageConditions = storageConditions;
    }

    public String getDosage() {
        return dosage;
    }

    public void setDosage(String dosage) {
        this.dosage = dosage;
    }

    public String getContraindications() {
        return contraindications;
    }

    public void setContraindications(String contraindications) {
        this.contraindications = contraindications;
    }

    public boolean isIsPrescriptionRequired() {
        return isPrescriptionRequired;
    }

    public void setIsPrescriptionRequired(boolean isPrescriptionRequired) {
        this.isPrescriptionRequired = isPrescriptionRequired;
    }

    public double getSellingPrice() {
        return sellingPrice;
    }

    public void setSellingPrice(double sellingPrice) {
        this.sellingPrice = sellingPrice;
    }

    public int getMinInventory() {
        return minInventory;
    }

    public void setMinInventory(int minInventory) {
        this.minInventory = minInventory;
    }

    public boolean isStatus() {
        return status;
    }

    public void setStatus(boolean status) {
        this.status = status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    @Override
    public String toString() {
        return "Medicines{" + "medicineId=" + medicineId + ", medicineCodex=" + medicineCodex + ", medicineName=" + medicineName + ", genericName=" + genericName + ", barcode=" + barcode + ", registrationNumber=" + registrationNumber + ", categoryID=" + categoryID + ", manufacturerID=" + manufacturerID + ", unit=" + unit + ", shelfId=" + shelfId + ", storageTempMin=" + storageTempMin + ", storageTempMax=" + storageTempMax + ", storageConditions=" + storageConditions + ", dosage=" + dosage + ", contraindications=" + contraindications + ", isPrescriptionRequired=" + isPrescriptionRequired + ", sellingPrice=" + sellingPrice + ", minInventory=" + minInventory + ", status=" + status + ", createdAt=" + createdAt + '}';
    }




}
