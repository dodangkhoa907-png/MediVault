package com.medicare.service.warehouse;

import com.medicare.dao.WarehouseExportDAO;
import com.medicare.dao.interfaces.IWarehouseExportDAO;
import com.medicare.entity.Account;
import com.medicare.entity.ExportReason;
import com.medicare.entity.WarehouseExport;
import com.medicare.entity.WarehouseExportDetail;
import com.medicare.service.ServiceResult;

import java.util.ArrayList;
import java.util.List;

/**
 * ExportService — tầng nghiệp vụ của module Xuất kho. Controller (WarehouseExportServlet)
 * KHÔNG được tự tính FEFO hay tự UPDATE Batches — mọi quyết định "lấy lô nào, bao nhiêu" và
 * mọi ghi DB đều đi qua đây (Controller → Service → FEFO Engine → DAO → DB, đúng yêu cầu module).
 */
public class ExportService {

    private final IWarehouseExportDAO exportDAO;
    private final FefoAllocatorService allocator;
    private final ExportValidationService validationService;

    public ExportService() {
        this(new WarehouseExportDAO(), new FefoAllocatorService(), new ExportValidationService());
    }

    public ExportService(IWarehouseExportDAO exportDAO, FefoAllocatorService allocator, ExportValidationService validationService) {
        this.exportDAO = exportDAO;
        this.allocator = allocator;
        this.validationService = validationService;
    }

    /** Bước 3 (AJAX): xem trước phân bổ FEFO cho 1 thuốc — KHÔNG ghi gì vào DB. */
    public AllocationResult previewAllocation(int medicineId, int requestedQty) {
        return allocator.allocate(medicineId, requestedQty);
    }

    /**
     * Bước 5 (Xác nhận) — điểm ghi DUY NHẤT của cả wizard: kiểm tra lại toàn bộ (không tin dữ
     * liệu FE gửi lên), rồi giao cho DAO ghi transaction. Trả về ExportID khi thành công.
     */
    public ServiceResult<Integer> submit(ExportSubmission submission, Account actingAccount) {
        ValidationResult result = new ValidationResult();

        ExportReason reason = validationService.validateHeader(submission.getReasonId(), submission.getReceiver(), result);

        boolean wantsOverride = submission.hasAnyOverride();
        if (wantsOverride && !actingAccount.isWarehouseManager()) {
            result.addError("Chỉ Quản lý kho mới được ghi đè phân bổ FEFO.");
        }
        if (wantsOverride && (submission.getOverrideReason() == null || submission.getOverrideReason().trim().isEmpty())) {
            result.addError("Vui lòng nhập lý do ghi đè phân bổ FEFO.");
        }
        if (submission.getLines() == null || submission.getLines().isEmpty()) {
            result.addError("Chưa chọn thuốc nào để xuất kho.");
        }

        List<WarehouseExportDetail> allLines = new ArrayList<>();
        if (reason != null && submission.getLines() != null) {
            for (ExportLineRequest line : submission.getLines()) {
                boolean useOverride = line.isOverridden() && actingAccount.isWarehouseManager();
                if (useOverride) {
                    if (validationService.validateOverrideLine(line, result)) {
                        for (ExportLineRequest.ManualAllocation m : line.getManualAllocations()) {
                            allLines.add(buildDetail(line.getMedicineId(), m.getBatchId(),
                                    line.getRequestedQuantity(), m.getQuantity(), true));
                        }
                    }
                } else {
                    AllocationResult alloc = validationService.validateFefoLine(line.getMedicineId(), line.getRequestedQuantity(), result);
                    if (alloc != null && alloc.isFullyAllocated()) {
                        for (LotAllocation la : alloc.getAllocations()) {
                            allLines.add(buildDetail(line.getMedicineId(), la.getBatchId(),
                                    line.getRequestedQuantity(), la.getAllocatedQuantity(), false));
                        }
                    }
                }
            }
        }

        if (!result.isValid()) {
            List<String> errors = new ArrayList<>(result.getErrors());
            for (ShortfallInfo s : result.getShortfalls()) {
                errors.add("Thuốc #" + s.getMedicineId() + " thiếu " + s.getMissingQuantity()
                        + " (yêu cầu " + s.getRequestedQuantity() + ", còn " + s.getAvailableQuantity() + ").");
            }
            return ServiceResult.fail(errors);
        }

        WarehouseExport header = new WarehouseExport();
        header.setReasonId(submission.getReasonId());
        header.setReceiver(submission.getReceiver());
        header.setNotes(submission.getNotes());
        header.setFefoOverridden(wantsOverride);
        if (wantsOverride) {
            header.setOverrideReason(submission.getOverrideReason());
            header.setOverrideBy(actingAccount.getAccountId());
        }

        int exportId = exportDAO.confirmExport(header, allLines, actingAccount.getAccountId());
        if (exportId <= 0) {
            String err = exportDAO instanceof WarehouseExportDAO
                    ? ((WarehouseExportDAO) exportDAO).getLastConfirmError() : null;
            return ServiceResult.fail(err != null ? err : "Không thể ghi phiếu xuất kho — vui lòng thử lại.");
        }
        return ServiceResult.ok(exportId);
    }

    public ServiceResult<Void> cancel(int exportId, Account actingAccount, String reason) {
        boolean ok = exportDAO.cancelExport(exportId, actingAccount.getAccountId(), reason);
        if (!ok) {
            String err = exportDAO instanceof WarehouseExportDAO
                    ? ((WarehouseExportDAO) exportDAO).getLastConfirmError() : null;
            return ServiceResult.fail(err != null ? err : "Không thể huỷ phiếu xuất kho.");
        }
        return ServiceResult.ok();
    }

    public ServiceResult<Void> reverse(int exportId, Account actingAccount, String reason) {
        if (reason == null || reason.trim().isEmpty()) {
            return ServiceResult.fail("Vui lòng nhập lý do hoàn trả.");
        }
        boolean ok = exportDAO.reverseExport(exportId, actingAccount.getAccountId(), reason);
        if (!ok) {
            String err = exportDAO instanceof WarehouseExportDAO
                    ? ((WarehouseExportDAO) exportDAO).getLastConfirmError() : null;
            return ServiceResult.fail(err != null ? err : "Không thể hoàn trả phiếu xuất kho.");
        }
        return ServiceResult.ok();
    }

    private WarehouseExportDetail buildDetail(int medicineId, int batchId, int requestedQty, int allocatedQty, boolean overridden) {
        WarehouseExportDetail d = new WarehouseExportDetail();
        d.setMedicineId(medicineId);
        d.setBatchId(batchId);
        d.setRequestedQuantity(requestedQty);
        d.setAllocatedQuantity(allocatedQty);
        d.setFefoOverridden(overridden);
        return d;
    }
}
