package com.medivault.dao.interfaces;

import com.medivault.entity.Invoice;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public interface IInvoiceDAO {
    // Flow bán hàng — gọi theo thứ tự 1 → 2 → 3
    int createPending(int accountId, Integer shiftId,
                      Integer customerId, Integer prescriptionId,
                      String paymentMethod);
    boolean addItemByFIFO(int invoiceId, int medicineId, int quantity);
    boolean complete(int invoiceId, BigDecimal discountAmount);
    boolean cancel(int invoiceId);

    /**
     * Thực hiện toàn bộ flow bán hàng trong 1 transaction:
     * createPending → addItemByFIFO (từng SP) → complete
     * Nếu bất kỳ bước nào lỗi → rollback toàn bộ
     * @return invoiceId nếu thành công, -1 nếu lỗi
     */
    int completeSaleTransaction(int accountId, Integer customerId,
                                String paymentMethod, BigDecimal discount,
                                int[] medicineIds, int[] quantities);

    // Truy vấn
    Invoice findById(int id);
    Invoice findByCode(String invoiceCode);
    List<Invoice> findByShift(int shiftId);
    List<Invoice> findByCustomer(int customerId);
    List<Invoice> findByDateRange(LocalDate from, LocalDate to);
    BigDecimal sumRevenueByDateRange(LocalDate from, LocalDate to);
}