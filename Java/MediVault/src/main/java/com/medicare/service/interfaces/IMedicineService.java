package com.medicare.service.interfaces;

import com.medicare.entity.Batches;
import com.medicare.entity.Medicines;
import com.medicare.service.ServiceResult;

/**
 * IMedicineService — Nghiệp vụ quản lý thuốc và lô hàng.
 */
public interface IMedicineService {

    /**
     * Lưu thuốc mới hoặc cập nhật thuốc hiện có.
     * Thực hiện validate trước khi gọi DAO.
     */
    ServiceResult<Medicines> saveMedicine(Medicines m, boolean isNew);

    /**
     * Xóa mềm thuốc.
     * Chặn nếu còn tồn kho.
     */
    ServiceResult<Void> deleteMedicine(int medicineId);

    /**
     * Nhập lô mới hoặc cập nhật lô hiện có.
     * Khi nhập lô mới: bắt buộc liên kết với Đơn đặt hàng (FK).
     * Xử lý 2 mode: "existing" (dùng PO có sẵn) và "new" (tạo PO mới).
     *
     * @param b           Thông tin lô hàng (đã được set medicineId, batchNumber, expiryDate, importPrice, qty)
     * @param isNew       true = nhập lô mới | false = sửa lô
     * @param poMode      "existing" | "new" (chỉ cần khi isNew=true)
     * @param poIdStr     ID đơn đặt hàng có sẵn (chỉ cần khi poMode="existing")
     * @param newSupplierId ID nhà cung cấp để tạo PO mới (chỉ cần khi poMode="new")
     * @param newPoNotes  Ghi chú PO mới (tùy chọn)
     * @param adminAccountId ID admin đang thực hiện (dùng cho PO mới)
     */
    ServiceResult<Batches> saveBatch(
            Batches b, boolean isNew,
            String poMode, String poIdStr,
            String newSupplierId, String newPoNotes,
            int adminAccountId);

    /**
     * Xóa lô hàng.
     * Chặn nếu CurrentQuantity > 0.
     */
    ServiceResult<Void> deleteBatch(int batchId);
}
