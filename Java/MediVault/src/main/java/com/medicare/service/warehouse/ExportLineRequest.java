package com.medicare.service.warehouse;

import java.util.ArrayList;
import java.util.List;

/**
 * 1 dòng thuốc do wizard Xuất kho gửi lên ở bước Xác nhận. Bình thường chỉ có medicineId +
 * requestedQuantity, hệ thống tự phân bổ FEFO. Nếu Quản lý kho ghi đè (override), dòng này
 * mang sẵn danh sách lô đã chọn tay ({@link #manualAllocations}) — server vẫn phải đối chiếu
 * lại với dữ liệu tồn kho THẬT trước khi ghi (không tin số liệu client gửi lên).
 */
public class ExportLineRequest {
    private final int medicineId;
    private final int requestedQuantity;
    private final boolean overridden;
    private final List<ManualAllocation> manualAllocations;

    public ExportLineRequest(int medicineId, int requestedQuantity, boolean overridden, List<ManualAllocation> manualAllocations) {
        this.medicineId = medicineId;
        this.requestedQuantity = requestedQuantity;
        this.overridden = overridden;
        this.manualAllocations = manualAllocations == null ? new ArrayList<>() : manualAllocations;
    }

    public int getMedicineId() { return medicineId; }
    public int getRequestedQuantity() { return requestedQuantity; }
    public boolean isOverridden() { return overridden; }
    public List<ManualAllocation> getManualAllocations() { return manualAllocations; }

    /** 1 cặp (lô, số lượng) do Quản lý kho tự chọn tay khi ghi đè FEFO. */
    public static class ManualAllocation {
        private final int batchId;
        private final int quantity;

        public ManualAllocation(int batchId, int quantity) {
            this.batchId = batchId;
            this.quantity = quantity;
        }

        public int getBatchId() { return batchId; }
        public int getQuantity() { return quantity; }
    }
}
