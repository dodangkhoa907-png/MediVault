package com.medicare.dao.interfaces;

import com.medicare.entity.PurchaseOrders;
import java.util.List;

/**
 * IPurchaseOrderDAO — Quản lý đơn đặt hàng (PurchaseOrders).
 *
 * Mỗi lô thuốc (Batches) PHẢI thuộc 1 đơn đặt hàng (FK_Batch_PO, NOT NULL).
 * Luồng chuẩn: tạo PO (chọn nhà cung cấp) → thêm các lô hàng vào PO đó →
 * TotalValue tự tính lại = SUM(ImportPrice * InitialQuantity) của các lô thuộc PO.
 */
public interface IPurchaseOrderDAO {

    /** Tạo đơn mới, trả về POID vừa tạo, -1 nếu lỗi. */
    int insert(PurchaseOrders po);

    PurchaseOrders findById(int id);

    /** Tất cả đơn, mới nhất lên trước. */
    List<PurchaseOrders> findAll();

    /** N đơn gần đây nhất — dùng cho dropdown "chọn đơn có sẵn" khi nhập lô. */
    List<PurchaseOrders> findRecent(int limit);

    /** Số lô hàng đã thuộc về 1 đơn — hiển thị ở danh sách/chi tiết đơn. */
    int countBatches(int poId);

    /** Tính lại TotalValue = SUM(ImportPrice * InitialQuantity) của các lô thuộc đơn này. */
    boolean recalcTotalValue(int poId);
}