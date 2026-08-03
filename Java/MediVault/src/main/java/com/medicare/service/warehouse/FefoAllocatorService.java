package com.medicare.service.warehouse;

import com.medicare.dao.BatchesDAO;
import com.medicare.dao.interfaces.IBatchesDAO;
import com.medicare.entity.Batches;

import java.util.ArrayList;
import java.util.List;

/**
 * FefoAllocatorService — bộ máy phân bổ FEFO thuần tuý (không chạm DB ghi, không biết gì về
 * HTTP/servlet). Đầu vào: 1 thuốc + số lượng yêu cầu. Đầu ra: danh sách lô cần lấy, ưu tiên
 * hạn dùng gần nhất trước, cho tới khi đủ số lượng hoặc hết hàng khả dụng.
 *
 * Đây là NƠI DUY NHẤT trong module Xuất kho tính toán "lấy lô nào, bao nhiêu" — Controller/JSP
 * không được tự tính lại (đúng yêu cầu "never calculate FEFO in JavaScript").
 */
public class FefoAllocatorService {

    private final IBatchesDAO batchesDAO;

    public FefoAllocatorService() {
        this(new BatchesDAO());
    }

    public FefoAllocatorService(IBatchesDAO batchesDAO) {
        this.batchesDAO = batchesDAO;
    }

    /**
     * Phân bổ FEFO cho 1 thuốc: {@link IBatchesDAO#findByMedicine} đã trả đúng các lô ACTIVE,
     * còn tồn, sắp theo ExpiryDate ASC — chỉ cần lấy lần lượt tới khi đủ requestedQty.
     */
    public AllocationResult allocate(int medicineId, int requestedQty) {
        List<Batches> batches = batchesDAO.findByMedicine(medicineId);
        List<LotAllocation> allocations = new ArrayList<>();
        int remaining = Math.max(0, requestedQty);
        for (Batches b : batches) {
            if (remaining <= 0) break;
            int take = Math.min(remaining, b.getCurrentQuantity());
            if (take <= 0) continue;
            allocations.add(new LotAllocation(b.getBatchId(), b.getBatchNumber(), b.getExpiryDate(),
                    b.getCurrentQuantity(), take));
            remaining -= take;
        }
        return new AllocationResult(medicineId, requestedQty, allocations, remaining);
    }
}
