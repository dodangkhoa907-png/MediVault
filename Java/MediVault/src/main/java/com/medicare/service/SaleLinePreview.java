package com.medicare.service;

import com.medicare.service.warehouse.AllocationResult;
import com.medicare.service.warehouse.LotAllocation;

/**
 * Kết quả xem trước 1 dòng bán hàng (action=preview-sale) — KHÔNG ghi gì vào DB. FE dùng
 * {@link #isRisky()} để quyết định có cần dừng lại hỏi dược sĩ hay cứ thanh toán thẳng.
 */
public class SaleLinePreview {
    private final int medicineId;
    private final int requestedQuantity;
    private final AllocationResult fefoAllocation;
    private final boolean risky;
    /** Lô ĐƠN LẺ đủ cả số lượng lẫn hạn dùng cho liệu trình — null nếu không risky hoặc
     *  không có lô nào đơn lẻ đáp ứng được (khi đó bắt buộc phải chia lô nếu muốn đủ hàng). */
    private final LotAllocation suggestedSingleBatch;

    public SaleLinePreview(int medicineId, int requestedQuantity, AllocationResult fefoAllocation,
                            boolean risky, LotAllocation suggestedSingleBatch) {
        this.medicineId = medicineId;
        this.requestedQuantity = requestedQuantity;
        this.fefoAllocation = fefoAllocation;
        this.risky = risky;
        this.suggestedSingleBatch = suggestedSingleBatch;
    }

    public int getMedicineId() { return medicineId; }
    public int getRequestedQuantity() { return requestedQuantity; }
    public AllocationResult getFefoAllocation() { return fefoAllocation; }
    public boolean isRisky() { return risky; }
    public LotAllocation getSuggestedSingleBatch() { return suggestedSingleBatch; }
}
