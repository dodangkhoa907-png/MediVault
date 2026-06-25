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
     *   - Tạo hóa đơn + trừ kho theo FIFO (qua SP_AddSaleByFIFO)
     *   - Ghi log audit
     *
     * @param accountId    ID nhân viên thực hiện
     * @param customerId   ID khách hàng (null nếu khách vãng lai)
     * @param paymentMethod CASH | CARD | TRANSFER
     * @param discount     Giảm giá tuyệt đối (0 nếu không có)
     * @param medicineIds  Mảng ID thuốc
     * @param quantities   Mảng số lượng tương ứng
     * @param remoteAddr   IP client (để ghi audit log)
     * @return ServiceResult chứa Invoice hoàn chỉnh nếu thành công
     */
    ServiceResult<Invoice> completeSale(
            int accountId,
            Integer customerId,
            String paymentMethod,
            BigDecimal discount,
            int[] medicineIds,
            int[] quantities,
            String remoteAddr);
}
