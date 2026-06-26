package com.medicare.service;

import com.medicare.dao.InvoiceDAO;
import com.medicare.dao.ShiftDAO;
import com.medicare.dao.StaffAuditLogDAO;
import com.medicare.dao.interfaces.IInvoiceDAO;
import com.medicare.dao.interfaces.IShiftDAO;
import com.medicare.dao.interfaces.IStaffAuditLogDAO;
import com.medicare.entity.Invoice;
import com.medicare.entity.Shift;
import com.medicare.entity.StaffAuditLog;
import com.medicare.service.interfaces.ISaleService;

import java.math.BigDecimal;

/**
 * SaleService — Orchestrates toàn bộ quy trình bán hàng POS.
 *
 * Trước đây logic này nằm rải rác trong PosServlet + InvoiceDAO.
 * Servlet chỉ parse HTTP params → gọi service → trả JSON.
 */
public class SaleService implements ISaleService {

    private final IInvoiceDAO       invoiceDAO = new InvoiceDAO();
    private final IShiftDAO         shiftDAO   = new ShiftDAO();
    private final IStaffAuditLogDAO auditDAO   = new StaffAuditLogDAO();

    @Override
    public ServiceResult<Invoice> completeSale(
            int accountId,
            Integer customerId,
            String paymentMethod,
            BigDecimal discount,
            int[] medicineIds,
            int[] quantities,
            String remoteAddr) {

        // Validate đầu vào cơ bản
        if (medicineIds == null || medicineIds.length == 0)
            return ServiceResult.fail("Giỏ hàng trống!");
        if (quantities == null || quantities.length != medicineIds.length)
            return ServiceResult.fail("Dữ liệu giỏ hàng không hợp lệ!");

        // Lấy ca làm việc đang mở — null nếu không có (vẫn cho phép bán)
        Shift currentShift = shiftDAO.findCurrent(accountId);
        Integer shiftId = (currentShift != null) ? currentShift.getShiftId() : null;

        // Chạy transaction: tạo hóa đơn → trừ kho FIFO → hoàn tất
        int invoiceId = invoiceDAO.completeSaleTransaction(
                accountId, shiftId, customerId,
                paymentMethod, discount,
                medicineIds, quantities);

        if (invoiceId > 0) {
            // Ghi audit log bán hàng
            auditDAO.log(new StaffAuditLog(
                    accountId,
                    "Thanh toán bán hàng",
                    "Lập thành công hóa đơn mã ID: " + invoiceId,
                    remoteAddr));

            Invoice inv = invoiceDAO.findById(invoiceId);
            return ServiceResult.ok(inv);
        }

        return ServiceResult.fail("Thanh toán thất bại! Kiểm tra lại tồn kho.");
    }
}
