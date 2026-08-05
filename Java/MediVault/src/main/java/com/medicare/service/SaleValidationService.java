package com.medicare.service;

import com.medicare.dao.BatchesDAO;
import com.medicare.dao.interfaces.IBatchesDAO;
import com.medicare.entity.Batches;
import com.medicare.service.warehouse.AllocationResult;
import com.medicare.service.warehouse.FefoAllocatorService;
import com.medicare.service.warehouse.LotAllocation;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * SaleValidationService — lớp cảnh báo rủi ro hạn dùng cho bán hàng POS, mirror đúng cách
 * {@code ExportValidationService} đang làm cho module Xuất kho (xem file đó để đối chiếu):
 * dùng CHUNG {@link FefoAllocatorService} — không viết lại thuật toán chọn lô lần 2, chỉ thêm
 * lớp đánh giá "có đáng dừng lại hỏi dược sĩ không" trước khi thanh toán.
 */
public class SaleValidationService {

    private final FefoAllocatorService allocator;
    private final IBatchesDAO batchesDAO;

    public SaleValidationService() {
        this(new FefoAllocatorService(), new BatchesDAO());
    }

    public SaleValidationService(FefoAllocatorService allocator, IBatchesDAO batchesDAO) {
        this.allocator = allocator;
        this.batchesDAO = batchesDAO;
    }

    /**
     * Xem trước cách FEFO sẽ chia lô cho 1 dòng thuốc trong giỏ hàng — KHÔNG ghi gì vào DB.
     * risky khi: (a) đơn bị chia ≥2 lô ({@link AllocationResult#isRisky()}), HOẶC
     * (b) biết {@code durationDays} và lô gần hạn nhất trong số lô cấp không đủ hạn cho cả liệu trình.
     */
    public SaleLinePreview previewLine(int medicineId, int requestedQty, Integer durationDays) {
        AllocationResult alloc = allocator.allocate(medicineId, requestedQty);

        boolean durationRisk = false;
        if (durationDays != null && durationDays > 0) {
            LotAllocation nearest = alloc.nearestExpiryLot();
            if (nearest != null && nearest.getExpiryDate() != null) {
                long daysLeft = ChronoUnit.DAYS.between(LocalDate.now(), nearest.getExpiryDate());
                durationRisk = daysLeft < durationDays;
            }
        }
        boolean risky = alloc.isRisky() || durationRisk;

        LotAllocation suggested = risky ? findSingleSufficientBatch(medicineId, requestedQty, durationDays) : null;
        return new SaleLinePreview(medicineId, requestedQty, alloc, risky, suggested);
    }

    /**
     * Tìm 1 lô ĐƠN LẺ đủ cả số lượng lẫn hạn dùng cho liệu trình — gợi ý "lấy hết từ lô này"
     * thay vì chia nhiều lô. Ưu tiên lô có hạn gần nhất trong số các lô ĐẠT điều kiện (vẫn giữ
     * tinh thần giảm lãng phí của FEFO, chỉ loại các lô KHÔNG đủ hạn thay vì bỏ qua hoàn toàn).
     * Trả về null nếu không có lô nào đơn lẻ đáp ứng được — khi đó bắt buộc phải chia lô nếu
     * muốn bán đủ số lượng.
     */
    private LotAllocation findSingleSufficientBatch(int medicineId, int requestedQty, Integer durationDays) {
        List<Batches> candidates = batchesDAO.findByMedicine(medicineId); // đã ORDER BY ExpiryDate ASC
        LocalDate today = LocalDate.now();
        for (Batches b : candidates) {
            if (b.getCurrentQuantity() < requestedQty) continue;
            if (durationDays != null && durationDays > 0 && b.getExpiryDate() != null) {
                long daysLeft = ChronoUnit.DAYS.between(today, b.getExpiryDate());
                if (daysLeft < durationDays) continue;
            }
            return new LotAllocation(b.getBatchId(), b.getBatchNumber(), b.getExpiryDate(),
                    b.getCurrentQuantity(), requestedQty);
        }
        return null;
    }

    /**
     * Đối chiếu lại 1 dòng đã được dược sĩ CHỌN TAY (sau khi thấy cảnh báo rủi ro) với tồn kho
     * THẬT tại thời điểm xác nhận — không tin số liệu client gửi lên trước đó, đúng nguyên tắc
     * {@code ExportValidationService.validateOverrideLine} đang áp dụng cho Xuất kho.
     * Trả về danh sách lỗi (rỗng = hợp lệ, an toàn để ghi DB).
     */
    public List<String> validateManualLine(SaleLineRequest line) {
        List<String> errors = new ArrayList<>();
        int sum = 0;
        Set<Integer> seen = new HashSet<>();
        for (SaleLineRequest.ManualAllocation m : line.getManualAllocations()) {
            if (!seen.add(m.getBatchId())) {
                errors.add("Lô #" + m.getBatchId() + " bị chọn trùng trong cùng 1 dòng.");
                continue;
            }
            Batches b = batchesDAO.findById(m.getBatchId());
            if (b == null || b.getMedicineId() != line.getMedicineId() || !"ACTIVE".equals(b.getStatus())) {
                errors.add("Lô #" + m.getBatchId() + " không hợp lệ cho thuốc này.");
                continue;
            }
            if (m.getQuantity() <= 0 || m.getQuantity() > b.getCurrentQuantity()) {
                errors.add("Lô " + b.getBatchNumber() + " chỉ còn " + b.getCurrentQuantity()
                        + " — không đủ cho số lượng đã chọn (" + m.getQuantity() + ").");
                continue;
            }
            sum += m.getQuantity();
        }
        if (sum != line.getRequestedQuantity()) {
            errors.add("Tổng số lượng đã chọn (" + sum + ") không khớp số lượng yêu cầu ("
                    + line.getRequestedQuantity() + ").");
        }
        return errors;
    }
}
