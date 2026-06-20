package com.medicare.dao.interfaces;

import com.medicare.entity.Returns;
import java.util.List;

/**
 * IReturnsDAO — Trả hàng / hủy hàng hết hạn / thu hồi.
 *
 * Insert vào Returns sẽ tự kích hoạt trigger TRG_ProcessReturn trong DB:
 *  - Nếu RestoreStock=1: Batches.CurrentQuantity được CỘNG lại tự động.
 *  - Luôn ghi 1 dòng StockMovements (RETURN/EXPIRED/ADJUSTMENT) để truy vết.
 * → DAO này KHÔNG cần tự cập nhật Batches — chỉ insert đúng là đủ.
 */
public interface IReturnsDAO {

    /** Tạo phiếu mới, trả về ReturnID vừa tạo, -1 nếu lỗi. */
    int insert(Returns r);

    Returns findById(int id);

    /** Tất cả phiếu, mới nhất lên trước. */
    List<Returns> findAll();

    /** Các phiếu CUSTOMER_RETURN đã tạo cho 1 hóa đơn — dùng để tính SL còn được trả. */
    List<Returns> findByInvoice(int invoiceId);

    /** Tổng SL đã trả của 1 dòng (InvoiceID + BatchID cụ thể) — chặn trả vượt số đã bán. */
    int sumReturnedQty(int invoiceId, int batchId);
}