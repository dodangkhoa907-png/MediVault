package com.medicare.dao.interfaces;

import com.medicare.entity.MedicineBarcode;
import com.medicare.entity.Medicines;
import java.util.List;

/**
 * Đa mã vạch/lịch sử quét cho 1 thuốc (bảng MedicineBarcodes — additive, không đụng
 * cột Medicines.Barcode hiện có). Xem database/barcode_multi_migration.sql.
 */
public interface IMedicineBarcodeDAO {

    /** Tìm thuốc qua BẤT KỲ mã vạch phụ nào đã bind (không tính Medicines.Barcode chính —
     *  cái đó vẫn tra bằng MedicineDAO.findByBarcode() như cũ). */
    Medicines findMedicineByAnyBarcode(String barcode);

    /** Dòng MedicineBarcodes khớp đúng mã vạch này (để kiểm tra xung đột/hiển thị lịch sử). */
    MedicineBarcode findByBarcode(String barcode);

    /** Mã vạch này đã bị gán cho thuốc KHÁC (khác excludeMedicineId) chưa — chặn 1 mã vạch
     *  thuộc 2 thuốc (mục BARCODE VALIDATION). */
    boolean existsForOtherMedicine(String barcode, int excludeMedicineId);

    /** Gán 1 mã vạch mới cho 1 thuốc (secondary/supplier/internal/qr/primary). */
    boolean insert(int medicineId, String barcode, String barcodeType, Integer createdBy, String source);

    /** Ghi nhận 1 lượt quét trúng — tăng ScanCount/cập nhật LastScannedAt/LastSource. Nếu mã vạch
     *  này chưa có dòng nào (trường hợp quét trúng Medicines.Barcode "chính" cũ, chưa từng được
     *  bind qua bảng này) thì tự tạo 1 dòng 'primary' để bắt đầu tích luỹ lịch sử — không cần
     *  chạy migration backfill riêng. */
    void recordScan(int medicineId, String barcode, String source);

    /** Toàn bộ mã vạch của 1 thuốc, mới tạo trước — cho khung "Lịch sử mã vạch". */
    List<MedicineBarcode> findHistory(int medicineId);
}
