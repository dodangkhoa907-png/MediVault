package com.medicare.service.interfaces;

import com.medicare.entity.Invoice;
import com.medicare.service.ServiceResult;

import java.math.BigDecimal;

/**
 * ISaleService — Nghiệp vụ bán hàng tại POS.
 * Tách biệt khỏi InvoiceDAO (DAO chỉ lo DB, Service lo orchestration).
 */
public interface ISaleService {

    /**
     * Hoàn tất giao dịch bán hàng:
     *   - Tự lấy ca làm việc hiện tại của nhân viên
     *   - Tạo hóa đơn + trừ kho theo FEFO (qua {@link com.medicare.service.warehouse.FefoAllocatorService}
     *     — hạn dùng gần nhất trước — hoặc theo lô dược sĩ đã chọn tay cho dòng risky)
     *   - Ghi log audit
     *
     * @param accountId    ID nhân viên thực hiện
     * @param customerId   ID khách hàng (null nếu khách vãng lai)
     * @param paymentMethod CASH | CARD | TRANSFER
     * @param discount     Giảm giá tuyệt đối (0 nếu không có)
     * @param medicineIds  Mảng ID thuốc
     * @param quantities   Mảng số lượng tương ứng
     * @param manualAllocationsByIndex key = vị trí trong medicineIds/quantities, value = lô dược
     *        sĩ đã tự chọn cho dòng đó sau khi thấy cảnh báo rủi ro hạn dùng ở bước xem trước
     *        (action=preview-sale). null/rỗng = mọi dòng để hệ thống tự phân bổ FEFO.
     * @param remoteAddr   IP client (để ghi audit log)
     * @param posStation   Quầy POS đang bán (null nếu không xác định) — ghi vào hóa đơn để
     *                      báo cáo đầu/cuối ca lọc đúng theo quầy
     * @return ServiceResult chứa Invoice hoàn chỉnh nếu thành công
     */
    ServiceResult<Invoice> completeSale(
            int accountId,
            Integer customerId,
            String paymentMethod,
            BigDecimal discount,
            int[] medicineIds,
            int[] quantities,
            java.util.Map<Integer, java.util.List<com.medicare.service.SaleLineRequest.ManualAllocation>> manualAllocationsByIndex,
            String remoteAddr,
            Integer posStation);
}
