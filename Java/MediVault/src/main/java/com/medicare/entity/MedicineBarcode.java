package com.medicare.entity;

import java.time.LocalDateTime;

/**
 * MedicineBarcode — 1 dòng trong bảng MedicineBarcodes (mỗi thuốc có thể có nhiều mã vạch:
 * primary/secondary/supplier/internal/qr) + số liệu lịch sử quét (ScanCount/LastScannedAt/LastSource).
 */
public class MedicineBarcode {

    private int barcodeId;
    private int medicineId;
    private String barcode;
    private String barcodeType;
    private Integer createdBy;
    private String createdByName; // JOIN từ Accounts khi cần hiển thị
    private LocalDateTime createdAt;
    private LocalDateTime lastScannedAt;
    private int scanCount;
    private String lastSource;

    public int getBarcodeId()                 { return barcodeId; }
    public void setBarcodeId(int v)            { this.barcodeId = v; }

    public int getMedicineId()                 { return medicineId; }
    public void setMedicineId(int v)           { this.medicineId = v; }

    public String getBarcode()                 { return barcode; }
    public void setBarcode(String v)            { this.barcode = v; }

    public String getBarcodeType()              { return barcodeType; }
    public void setBarcodeType(String v)        { this.barcodeType = v; }

    public Integer getCreatedBy()               { return createdBy; }
    public void setCreatedBy(Integer v)         { this.createdBy = v; }

    public String getCreatedByName()            { return createdByName; }
    public void setCreatedByName(String v)      { this.createdByName = v; }

    public LocalDateTime getCreatedAt()         { return createdAt; }
    public void setCreatedAt(LocalDateTime v)   { this.createdAt = v; }

    public LocalDateTime getLastScannedAt()     { return lastScannedAt; }
    public void setLastScannedAt(LocalDateTime v){ this.lastScannedAt = v; }

    public int getScanCount()                   { return scanCount; }
    public void setScanCount(int v)             { this.scanCount = v; }

    public String getLastSource()                { return lastSource; }
    public void setLastSource(String v)          { this.lastSource = v; }
}
