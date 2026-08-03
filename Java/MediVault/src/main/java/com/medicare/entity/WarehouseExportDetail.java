package com.medicare.entity;

/** 1 dòng phân bổ xuất kho: 1 (thuốc, lô) đã được FEFO chọn + số lượng lấy từ lô đó. */
public class WarehouseExportDetail {
    private int exportDetailId;
    private int exportId;
    private int medicineId;
    private int batchId;
    private int requestedQuantity;
    private int allocatedQuantity;
    private boolean fefoOverridden;

    // Transient — populated by JOIN queries for review/print/detail views
    private String medicineName;
    private String medicineCode;
    private String barcode;
    private String batchNumber;
    private java.time.LocalDate expiryDate;

    public int getExportDetailId() { return exportDetailId; }
    public void setExportDetailId(int exportDetailId) { this.exportDetailId = exportDetailId; }

    public int getExportId() { return exportId; }
    public void setExportId(int exportId) { this.exportId = exportId; }

    public int getMedicineId() { return medicineId; }
    public void setMedicineId(int medicineId) { this.medicineId = medicineId; }

    public int getBatchId() { return batchId; }
    public void setBatchId(int batchId) { this.batchId = batchId; }

    public int getRequestedQuantity() { return requestedQuantity; }
    public void setRequestedQuantity(int requestedQuantity) { this.requestedQuantity = requestedQuantity; }

    public int getAllocatedQuantity() { return allocatedQuantity; }
    public void setAllocatedQuantity(int allocatedQuantity) { this.allocatedQuantity = allocatedQuantity; }

    public boolean isFefoOverridden() { return fefoOverridden; }
    public void setFefoOverridden(boolean fefoOverridden) { this.fefoOverridden = fefoOverridden; }

    public String getMedicineName() { return medicineName; }
    public void setMedicineName(String medicineName) { this.medicineName = medicineName; }

    public String getMedicineCode() { return medicineCode; }
    public void setMedicineCode(String medicineCode) { this.medicineCode = medicineCode; }

    public String getBarcode() { return barcode; }
    public void setBarcode(String barcode) { this.barcode = barcode; }

    public String getBatchNumber() { return batchNumber; }
    public void setBatchNumber(String batchNumber) { this.batchNumber = batchNumber; }

    public java.time.LocalDate getExpiryDate() { return expiryDate; }
    public void setExpiryDate(java.time.LocalDate expiryDate) { this.expiryDate = expiryDate; }
}
