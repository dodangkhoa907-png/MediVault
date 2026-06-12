package com.medicare.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class Medicines {
    private int medicineId;
    private String medicineCode; // computed
    private String medicineName;
    private String genericName;
    private String barcode;
    private String registrationNumber;
    private Integer categoryId;
    private Integer manufacturerId;
    private String unit;
    private Integer shelfId;
    private BigDecimal storageTempMin;
    private BigDecimal storageTempMax;
    private String storageConditions;
    private String dosage;
    private BigDecimal defaultDosageMin;
    private BigDecimal defaultDosageMax;
    private String dosageWarning;
    private int expiryAlertDays;
    private String contraindications;
    private boolean isPrescriptionRequired;
    private BigDecimal sellingPrice;
    private int minInventory;
    private boolean status;
    private LocalDateTime createdAt;

    public Medicines() {
    }

    public Medicines(int medicineId, String medicineCode, String medicineName, String genericName, String barcode, String registrationNumber, Integer categoryId, Integer manufacturerId, String unit, Integer shelfId, BigDecimal storageTempMin, BigDecimal storageTempMax, String storageConditions, String dosage, BigDecimal defaultDosageMin, BigDecimal defaultDosageMax, String dosageWarning, int expiryAlertDays, String contraindications, boolean isPrescriptionRequired, BigDecimal sellingPrice, int minInventory, boolean status, LocalDateTime createdAt) {
        this.medicineId = medicineId;
        this.medicineCode = medicineCode;
        this.medicineName = medicineName;
        this.genericName = genericName;
        this.barcode = barcode;
        this.registrationNumber = registrationNumber;
        this.categoryId = categoryId;
        this.manufacturerId = manufacturerId;
        this.unit = unit;
        this.shelfId = shelfId;
        this.storageTempMin = storageTempMin;
        this.storageTempMax = storageTempMax;
        this.storageConditions = storageConditions;
        this.dosage = dosage;
        this.defaultDosageMin = defaultDosageMin;
        this.defaultDosageMax = defaultDosageMax;
        this.dosageWarning = dosageWarning;
        this.expiryAlertDays = expiryAlertDays;
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

    public String getMedicineCode() {
        return medicineCode;
    }

    public void setMedicineCode(String medicineCode) {
        this.medicineCode = medicineCode;
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

    public Integer getCategoryId() {
        return categoryId;
    }

    public void setCategoryId(Integer categoryId) {
        this.categoryId = categoryId;
    }

    public Integer getManufacturerId() {
        return manufacturerId;
    }

    public void setManufacturerId(Integer manufacturerId) {
        this.manufacturerId = manufacturerId;
    }

    public String getUnit() {
        return unit;
    }

    public void setUnit(String unit) {
        this.unit = unit;
    }

    public Integer getShelfId() {
        return shelfId;
    }

    public void setShelfId(Integer shelfId) {
        this.shelfId = shelfId;
    }

    public BigDecimal getStorageTempMin() {
        return storageTempMin;
    }

    public void setStorageTempMin(BigDecimal storageTempMin) {
        this.storageTempMin = storageTempMin;
    }

    public BigDecimal getStorageTempMax() {
        return storageTempMax;
    }

    public void setStorageTempMax(BigDecimal storageTempMax) {
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

    public BigDecimal getDefaultDosageMin() {
        return defaultDosageMin;
    }

    public void setDefaultDosageMin(BigDecimal defaultDosageMin) {
        this.defaultDosageMin = defaultDosageMin;
    }

    public BigDecimal getDefaultDosageMax() {
        return defaultDosageMax;
    }

    public void setDefaultDosageMax(BigDecimal defaultDosageMax) {
        this.defaultDosageMax = defaultDosageMax;
    }

    public String getDosageWarning() {
        return dosageWarning;
    }

    public void setDosageWarning(String dosageWarning) {
        this.dosageWarning = dosageWarning;
    }

    public int getExpiryAlertDays() {
        return expiryAlertDays;
    }

    public void setExpiryAlertDays(int expiryAlertDays) {
        this.expiryAlertDays = expiryAlertDays;
    }

    public String getContraindications() {
        return contraindications;
    }

    public void setContraindications(String contraindications) {
        this.contraindications = contraindications;
    }

    public boolean isPrescriptionRequired() {
        return isPrescriptionRequired;
    }

    public void setPrescriptionRequired(boolean prescriptionRequired) {
        isPrescriptionRequired = prescriptionRequired;
    }

    public BigDecimal getSellingPrice() {
        return sellingPrice;
    }

    public void setSellingPrice(BigDecimal sellingPrice) {
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
}