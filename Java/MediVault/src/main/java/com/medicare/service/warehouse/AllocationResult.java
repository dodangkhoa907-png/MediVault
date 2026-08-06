package com.medicare.service.warehouse;

import java.util.Collections;
import java.util.List;

/** Kết quả phân bổ FEFO cho 1 thuốc: có thể đủ hàng (shortfall=0) hoặc thiếu (shortfall&gt;0). */
public class AllocationResult {
    private final int medicineId;
    private final int requestedQuantity;
    private final List<LotAllocation> allocations;
    private final int shortfall;

    public AllocationResult(int medicineId, int requestedQuantity, List<LotAllocation> allocations, int shortfall) {
        this.medicineId = medicineId;
        this.requestedQuantity = requestedQuantity;
        this.allocations = allocations == null ? Collections.emptyList() : allocations;
        this.shortfall = shortfall;
    }

    public int getMedicineId() { return medicineId; }
    public int getRequestedQuantity() { return requestedQuantity; }
    public List<LotAllocation> getAllocations() { return allocations; }
    public int getShortfall() { return shortfall; }
    public boolean isFullyAllocated() { return shortfall <= 0; }
    public int getAllocatedTotal() { return requestedQuantity - shortfall; }

    /**
     * true nếu đơn này bị chia ra từ ≥ 2 lô khác nhau — nghĩa là ít nhất 1 phần hàng đến từ lô
     * KHÔNG phải lô có hạn dùng xa nhất trong lô đã cấp. Đáng cảnh báo vì người nhận/khách hàng
     * có thể vô tình dùng lẫn lộn hàng gần hạn với hàng còn hạn dài mà không biết phân biệt.
     */
    public boolean isRisky() { return allocations.size() > 1; }

    /**
     * Lô có hạn dùng GẦN NHẤT trong số các lô đã cấp — null nếu chưa cấp lô nào.
     * FefoAllocatorService luôn cấp lô theo thứ tự ExpiryDate ASC (xem IBatchesDAO#findByMedicine),
     * nên phần tử đầu danh sách chính là lô gần hạn nhất — không cần dò lại.
     */
    public LotAllocation nearestExpiryLot() {
        return allocations.isEmpty() ? null : allocations.get(0);
    }
}
