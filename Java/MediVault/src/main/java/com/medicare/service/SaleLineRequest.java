package com.medicare.service;

import java.util.ArrayList;
import java.util.List;

/**
 * 1 dòng thuốc trong giỏ hàng POS lúc thanh toán. Bình thường chỉ có medicineId +
 * requestedQuantity, hệ thống tự phân bổ FEFO (qua {@link com.medicare.service.warehouse.FefoAllocatorService},
 * dùng CHUNG với module Xuất kho — không viết lại thuật toán chọn lô lần 2).
 *
 * Nếu dòng này được xác định "risky" ở bước xem trước (xem {@link SaleValidationService#previewLine})
 * và dược sĩ đã tự chọn cách xử lý, dòng mang sẵn danh sách lô đã chọn tay
 * ({@link #manualAllocations}) — server vẫn đối chiếu lại tồn kho THẬT trước khi ghi
 * (không tin số liệu client gửi lên), giống hệt cách {@code ExportValidationService.validateOverrideLine}
 * đang làm cho Xuất kho.
 */
public class SaleLineRequest {
    private final int medicineId;
    private final int requestedQuantity;
    /** Số ngày dùng thuốc — null = OTC hoặc dược sĩ không nhập, bỏ qua kiểm tra hạn/liệu trình. */
    private final Integer durationDays;
    private final boolean manualChosen;
    private final List<ManualAllocation> manualAllocations;

    public SaleLineRequest(int medicineId, int requestedQuantity, Integer durationDays,
                            boolean manualChosen, List<ManualAllocation> manualAllocations) {
        this.medicineId = medicineId;
        this.requestedQuantity = requestedQuantity;
        this.durationDays = durationDays;
        this.manualChosen = manualChosen;
        this.manualAllocations = manualAllocations == null ? new ArrayList<>() : manualAllocations;
    }

    public int getMedicineId() { return medicineId; }
    public int getRequestedQuantity() { return requestedQuantity; }
    public Integer getDurationDays() { return durationDays; }
    public boolean isManualChosen() { return manualChosen; }
    public List<ManualAllocation> getManualAllocations() { return manualAllocations; }

    /** 1 cặp (lô, số lượng) do dược sĩ tự chọn tay khi hệ thống cảnh báo rủi ro hạn dùng. */
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
