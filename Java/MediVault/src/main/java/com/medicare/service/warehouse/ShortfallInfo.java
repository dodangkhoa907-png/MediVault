package com.medicare.service.warehouse;

/** Thuốc không đủ tồn kho để đáp ứng số lượng yêu cầu — dữ liệu cho khối cảnh báo ở Bước 3. */
public class ShortfallInfo {
    private final int medicineId;
    private final int requestedQuantity;
    private final int availableQuantity;
    private final int missingQuantity;

    public ShortfallInfo(int medicineId, int requestedQuantity, int availableQuantity, int missingQuantity) {
        this.medicineId = medicineId;
        this.requestedQuantity = requestedQuantity;
        this.availableQuantity = availableQuantity;
        this.missingQuantity = missingQuantity;
    }

    public int getMedicineId() { return medicineId; }
    public int getRequestedQuantity() { return requestedQuantity; }
    public int getAvailableQuantity() { return availableQuantity; }
    public int getMissingQuantity() { return missingQuantity; }
}
