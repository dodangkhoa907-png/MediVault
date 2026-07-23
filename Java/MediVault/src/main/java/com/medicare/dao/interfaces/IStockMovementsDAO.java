package com.medicare.dao.interfaces;

import com.medicare.entity.StockMovements;
import java.util.List;

/**
 * IStockMovementsDAO — Sổ cái nhập/xuất/điều chỉnh kho (bảng StockMovements).
 *
 * MovementType hợp lệ (CHECK constraint CK_SM_Type trong DB): IN, OUT, RETURN, EXPIRED, ADJUSTMENT.
 * Dùng chung bởi tính năng "Xuất kho/Điều chỉnh tồn thủ công" và "Thu hồi lô khẩn cấp".
 */
public interface IStockMovementsDAO {
    /** Ghi 1 dòng vào sổ cái. Trả về true nếu insert thành công. */
    boolean insert(StockMovements m);

    /** Lịch sử di chuyển kho của 1 lô cụ thể, mới nhất trước. */
    List<StockMovements> findByBatch(int batchId);

    /** Lịch sử di chuyển kho trong khoảng ngày (dùng cho trang "Lịch sử nhập-xuất kho"). */
    List<StockMovements> findByDateRange(java.time.LocalDate from, java.time.LocalDate to);

    /** Lịch sử di chuyển kho do 1 tài khoản (thủ kho) thực hiện — dùng cho đối soát. */
    List<StockMovements> findByAccount(int accountId, java.time.LocalDate from, java.time.LocalDate to);
}
