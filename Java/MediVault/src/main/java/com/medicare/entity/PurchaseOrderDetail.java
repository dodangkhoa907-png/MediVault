package com.medicare.entity;

import java.math.BigDecimal;
import java.time.LocalDate;

/**
 * PurchaseOrderDetail — 1 dòng thuốc trong phiếu nhập (PurchaseOrderDetails).
 * Khi đơn PENDING: chỉ tồn tại ở đây, kho CHƯA tăng.
 * Khi bấm "Xác nhận hàng đã về": mỗi dòng sinh ra 1 Batch tương ứng.
 */
public class PurchaseOrderDetail {
    private int poDetailId;
    private int poId;
    private int medicineId;
    private int quantity;
    private BigDecimal importPrice;
    private String batchNumber;
    private LocalDate expiryDate;
    private LocalDate manufactureDate;
    private String medicineName; // JOIN từ Medicines — hiển thị

    public int getPoDetailId() { return poDetailId; }
    public void setPoDetailId(int poDetailId) { this.poDetailId = poDetailId; }
    public int getPoId() { return poId; }
    public void setPoId(int poId) { this.poId = poId; }
    public int getMedicineId() { return medicineId; }
    public void setMedicineId(int medicineId) { this.medicineId = medicineId; }
    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }
    public BigDecimal getImportPrice() { return importPrice; }
    public void setImportPrice(BigDecimal importPrice) { this.importPrice = importPrice; }
    public String getBatchNumber() { return batchNumber; }
    public void setBatchNumber(String batchNumber) { this.batchNumber = batchNumber; }
    public LocalDate getExpiryDate() { return expiryDate; }
    public void setExpiryDate(LocalDate expiryDate) { this.expiryDate = expiryDate; }
    public LocalDate getManufactureDate() { return manufactureDate; }
    public void setManufactureDate(LocalDate manufactureDate) { this.manufactureDate = manufactureDate; }
    public String getMedicineName() { return medicineName; }
    public void setMedicineName(String medicineName) { this.medicineName = medicineName; }
}
