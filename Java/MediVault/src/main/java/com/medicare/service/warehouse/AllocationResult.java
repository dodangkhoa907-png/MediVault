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
}
