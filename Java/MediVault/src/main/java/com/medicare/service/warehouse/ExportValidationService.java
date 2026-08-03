package com.medicare.service.warehouse;

import com.medicare.dao.BatchesDAO;
import com.medicare.dao.WarehouseExportDAO;
import com.medicare.dao.interfaces.IBatchesDAO;
import com.medicare.dao.interfaces.IWarehouseExportDAO;
import com.medicare.entity.Batches;
import com.medicare.entity.ExportReason;

import java.util.HashMap;
import java.util.Map;

/**
 * ExportValidationService — kiểm tra 1 phiếu xuất kho TRƯỚC khi ghi: loại xuất kho hợp lệ,
 * Người/Nơi nhận bắt buộc theo loại, và mỗi dòng thuốc có đủ tồn kho hay không (dòng ghi đè
 * FEFO được kiểm riêng bằng {@link #validateOverrideLine}, không qua FEFO engine).
 */
public class ExportValidationService {

    private final IWarehouseExportDAO exportDAO;
    private final FefoAllocatorService allocator;
    private final IBatchesDAO batchesDAO;

    public ExportValidationService() {
        this(new WarehouseExportDAO(), new FefoAllocatorService(), new BatchesDAO());
    }

    public ExportValidationService(IWarehouseExportDAO exportDAO, FefoAllocatorService allocator, IBatchesDAO batchesDAO) {
        this.exportDAO = exportDAO;
        this.allocator = allocator;
        this.batchesDAO = batchesDAO;
    }

    /** Kiểm tra loại xuất kho + Người/Nơi nhận. Trả về ExportReason nếu hợp lệ, null nếu không (đã ghi lỗi vào result). */
    public ExportReason validateHeader(int reasonId, String receiver, ValidationResult result) {
        ExportReason reason = exportDAO.findReasonById(reasonId);
        if (reason == null || !reason.isActive()) {
            result.addError("Loại xuất kho không hợp lệ.");
            return null;
        }
        if (reason.isRequiresReceiver() && (receiver == null || receiver.trim().isEmpty())) {
            result.addError("Loại xuất kho \"" + reason.getReasonName() + "\" bắt buộc nhập Người/Nơi nhận.");
        }
        return reason;
    }

    /** Kiểm tra 1 dòng theo FEFO tự động — trả về AllocationResult để ExportService tái sử dụng, ghi shortfall vào result nếu thiếu hàng. */
    public AllocationResult validateFefoLine(int medicineId, int requestedQty, ValidationResult result) {
        if (requestedQty <= 0) {
            result.addError("Số lượng xuất phải lớn hơn 0.");
            return null;
        }
        AllocationResult alloc = allocator.allocate(medicineId, requestedQty);
        if (!alloc.isFullyAllocated()) {
            result.addShortfall(new ShortfallInfo(medicineId, requestedQty, alloc.getAllocatedTotal(), alloc.getShortfall()));
        }
        return alloc;
    }

    /**
     * Kiểm tra 1 dòng GHI ĐÈ (Quản lý kho tự chọn lô): mỗi lô phải thuộc đúng thuốc, còn ACTIVE,
     * đủ tồn TẠI THỜI ĐIỂM XÁC NHẬN (đọc lại DB, không tin số availableQty client gửi trước đó),
     * và tổng số lượng các lô phải khớp đúng requestedQty.
     */
    public boolean validateOverrideLine(ExportLineRequest line, ValidationResult result) {
        int sum = 0;
        Map<Integer, Batches> seen = new HashMap<>();
        for (ExportLineRequest.ManualAllocation m : line.getManualAllocations()) {
            if (seen.containsKey(m.getBatchId())) {
                result.addError("Lô #" + m.getBatchId() + " bị chọn trùng trong cùng 1 dòng ghi đè.");
                return false;
            }
            Batches b = batchesDAO.findById(m.getBatchId());
            if (b == null || b.getMedicineId() != line.getMedicineId() || !"ACTIVE".equals(b.getStatus())) {
                result.addError("Lô #" + m.getBatchId() + " không hợp lệ cho thuốc này.");
                return false;
            }
            if (m.getQuantity() <= 0 || m.getQuantity() > b.getCurrentQuantity()) {
                result.addError("Lô " + b.getBatchNumber() + " chỉ còn " + b.getCurrentQuantity()
                        + " — không đủ cho số lượng ghi đè (" + m.getQuantity() + ").");
                return false;
            }
            seen.put(m.getBatchId(), b);
            sum += m.getQuantity();
        }
        if (sum != line.getRequestedQuantity()) {
            result.addError("Tổng số lượng ghi đè (" + sum + ") không khớp số lượng yêu cầu (" + line.getRequestedQuantity() + ").");
            return false;
        }
        return true;
    }
}
