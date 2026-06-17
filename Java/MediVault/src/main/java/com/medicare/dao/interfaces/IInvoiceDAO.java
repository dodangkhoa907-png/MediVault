package com.medicare.dao.interfaces;

import com.medicare.entity.Invoice;
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
     * @param shiftId  ID ca làm việc hiện tại (null nếu không có ca)
     * @return invoiceId nếu thành công, -1 nếu lỗi
     */
    int completeSaleTransaction(int accountId, Integer shiftId, Integer customerId,
                                String paymentMethod, BigDecimal discount,
                                int[] medicineIds, int[] quantities);

    // Truy vấn
    Invoice findById(int id);
    Invoice findByCode(String invoiceCode);
    List<Invoice> findByShift(int shiftId);
    List<Invoice> findByCustomer(int customerId);
    List<Invoice> findByDateRange(LocalDate from, LocalDate to);
    BigDecimal sumRevenueByDateRange(LocalDate from, LocalDate to);

    BigDecimal sumCashRevenueByShift(int shiftId);

    // ════════════════════════════════════════════════════════════
    //  BÁO CÁO DOANH THU — dùng cho ReportServlet (/reports)
    // ════════════════════════════════════════════════════════════

    /** Doanh thu GỘP (trước giảm giá) = SUM(InvoiceDetails.SubTotal) trong khoảng ngày. */
    BigDecimal sumGrossRevenueByDateRange(LocalDate from, LocalDate to);

    /** Giá vốn hàng bán (COGS) = SUM(Quantity * Batches.ImportPrice) trong khoảng ngày. */
    BigDecimal sumCOGSByDateRange(LocalDate from, LocalDate to);

    /** Tổng tiền giảm giá đã áp dụng cho khách (Invoices.DiscountAmount) trong khoảng ngày. */
    BigDecimal sumDiscountByDateRange(LocalDate from, LocalDate to);

    /** Tổng tiền hàng bị khách trả lại (Returns.ReturnType = CUSTOMER_RETURN) trong khoảng ngày. */
    BigDecimal sumRefundByDateRange(LocalDate from, LocalDate to);

    /** Số hóa đơn COMPLETED trong khoảng ngày. */
    int countInvoicesByDateRange(LocalDate from, LocalDate to);

    /** Doanh thu gộp theo Hãng sản xuất, sắp giảm dần. Key = tên hãng. */
    java.util.LinkedHashMap<String, BigDecimal> revenueByManufacturer(LocalDate from, LocalDate to);

    /** Doanh thu gộp theo Nhóm thuốc, sắp giảm dần. Key = tên nhóm. */
    java.util.LinkedHashMap<String, BigDecimal> revenueByCategory(LocalDate from, LocalDate to);

    /** Doanh thu theo khung giờ trong ngày (0-23, đã quy đổi giờ VN). Key = giờ. */
    java.util.TreeMap<Integer, BigDecimal> revenueByHour(LocalDate from, LocalDate to);

    /** Doanh thu thực tế (FinalAmount) theo từng ngày trong khoảng — dùng cho chart trend. Key = "yyyy-MM-dd". */
    java.util.TreeMap<String, BigDecimal> dailyRevenueByDateRange(LocalDate from, LocalDate to);

    /**
     * Doanh thu + Giá vốn theo từng ngày — dùng cho Grouped Column Chart so sánh Doanh thu/Giá vốn/Lợi nhuận.
     * Key = "yyyy-MM-dd", Value = [revenue, cogs] (lợi nhuận = revenue - cogs, tính ở tầng Servlet).
     */
    java.util.TreeMap<String, BigDecimal[]> dailyFinanceByDateRange(LocalDate from, LocalDate to);

    // ════════════════════════════════════════════════════════════
    //  DANH SÁCH HÓA ĐƠN (lọc + phân trang) — dùng cho InvoiceServlet (/invoices)
    // ════════════════════════════════════════════════════════════

    /**
     * Lọc hóa đơn theo nhiều điều kiện tùy chọn (truyền null/"" để bỏ qua điều kiện đó).
     * @param from,to       khoảng ngày (theo CreatedAt)
     * @param status        COMPLETED | CANCELLED | PENDING | null (tất cả)
     * @param paymentMethod CASH | CARD | TRANSFER | EWALLET | QR_CODE | null (tất cả)
     * @param accountId     lọc theo nhân viên lập hóa đơn | null (tất cả)
     * @param keyword       tìm theo InvoiceCode hoặc tên/SĐT khách hàng | null (bỏ qua)
     * @param page          trang hiện tại, bắt đầu từ 1
     * @param pageSize      số dòng mỗi trang
     */
    List<Invoice> findFiltered(LocalDate from, LocalDate to, String status, String paymentMethod,
                               Integer accountId, String keyword, int page, int pageSize);

    /** Đếm tổng số hóa đơn khớp với cùng bộ lọc trên — dùng để tính số trang. */
    int countFiltered(LocalDate from, LocalDate to, String status, String paymentMethod,
                      Integer accountId, String keyword);
}