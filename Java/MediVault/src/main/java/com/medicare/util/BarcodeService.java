package com.medicare.util;

import com.medicare.dao.MedicineBarcodeDAO;
import com.medicare.dao.MedicineDAO;
import com.medicare.dao.interfaces.IMedicineBarcodeDAO;
import com.medicare.dao.interfaces.IMedicineDAO;
import com.medicare.entity.Medicines;

import java.math.BigDecimal;

/**
 * Lõi tra cứu/gán/tạo nhanh mã vạch — dùng chung cho WarehouseImportServlet (Part 1) và
 * PosServlet (Part 2) để 2 nơi không tự viết 2 luồng khác nhau (đúng yêu cầu "Reuse current
 * APIs where possible" của đề bài redesign barcode).
 *
 * <p>Luồng tra cứu 1 mã vạch (dùng bởi action=lookup-barcode ở cả 2 servlet):</p>
 * <ol>
 *   <li>{@code MedicineDAO.findByBarcode()} — cột Barcode "chính" trên Medicines (đường cũ,
 *       có index IX_Medicines_Barcode, nhanh nhất, KHÔNG đổi hành vi cũ).</li>
 *   <li>Nếu miss: {@code MedicineBarcodeDAO.findMedicineByAnyBarcode()} — mã vạch phụ/NCC/nội
 *       bộ/QR đã bind qua bảng MedicineBarcodes (mới, additive).</li>
 *   <li>Nếu tìm thấy ở bước nào: ghi nhận lượt quét (ScanCount/LastScannedAt) — KHÔNG ghi 1 dòng
 *       AuditLog cho mỗi lượt quét trùng lặp (sẽ làm phình bảng AuditLog vô ích); AuditLog chỉ
 *       dùng cho sự kiện đáng chú ý (mã vạch mới/tạo thuốc mới/bind mã vạch) — xem lời gọi
 *       AuditHelper.log() ở nơi các hành động đó thực sự xảy ra trong servlet.</li>
 * </ol>
 */
public final class BarcodeService {

    private final IMedicineDAO medicineDAO = new MedicineDAO();
    private final IMedicineBarcodeDAO barcodeDAO = new MedicineBarcodeDAO();

    /** Tra cứu 1 mã vạch — trả Medicines nếu khớp (đã ghi nhận lượt quét), null nếu là mã vạch mới. */
    public Medicines lookup(String barcode, String source) {
        if (barcode == null || barcode.trim().isEmpty()) return null;
        String code = barcode.trim();
        Medicines m = medicineDAO.findByBarcode(code);
        if (m == null) m = barcodeDAO.findMedicineByAnyBarcode(code);
        if (m != null) barcodeDAO.recordScan(m.getMedicineId(), code, source);
        return m;
    }

    /** Mã vạch này đã thuộc về 1 thuốc khác chưa (chặn gán trùng — mục BARCODE VALIDATION). */
    public boolean isConflict(String barcode, int excludeMedicineId) {
        return barcodeDAO.existsForOtherMedicine(barcode, excludeMedicineId);
    }

    /** Option A của wizard "Phát hiện mã vạch mới": gán mã vạch vào 1 thuốc ĐÃ CÓ. Nếu thuốc đó
     *  chưa có Barcode chính nào thì đặt luôn làm chính (updateBarcode); ngược lại thêm 1 dòng
     *  'secondary' trong MedicineBarcodes (thuốc đã có Barcode chính, mã vạch mới là mã phụ —
     *  ví dụ hộp cùng thuốc nhưng NCC khác in mã vạch khác). */
    public boolean bindToExisting(int medicineId, String barcode, Integer accountId, String source) {
        if (isConflict(barcode, medicineId)) return false;
        Medicines target = medicineDAO.findById(medicineId);
        if (target == null) return false;
        boolean hasPrimary = target.getBarcode() != null && !target.getBarcode().trim().isEmpty();
        if (!hasPrimary) {
            return medicineDAO.updateBarcode(medicineId, barcode)
                    && barcodeDAO.insert(medicineId, barcode, "primary", accountId, source);
        }
        return barcodeDAO.insert(medicineId, barcode, "secondary", accountId, source);
    }

    /** Option B của wizard: tạo thuốc hoàn toàn mới, mã vạch vừa quét trở thành Barcode chính. */
    public Medicines quickCreate(String name, String genericName, String barcode, Integer categoryId,
            Integer manufacturerId, String unit, BigDecimal sellingPrice, boolean prescriptionRequired,
            String storageConditions, Integer accountId, String source) {
        if (isConflict(barcode, -1)) return null; // -1: chưa có medicineId thật, so mọi thuốc

        Medicines m = new Medicines();
        m.setMedicineName(name);
        m.setGenericName(genericName);
        m.setBarcode(barcode);
        m.setCategoryId(categoryId);
        m.setManufacturerId(manufacturerId);
        m.setUnit(unit);
        m.setSellingPrice(sellingPrice != null ? sellingPrice : BigDecimal.ZERO);
        m.setPrescriptionRequired(prescriptionRequired);
        m.setStorageConditions(storageConditions);
        m.setMinInventory(0);
        m.setExpiryAlertDays(30);

        int newId = ((MedicineDAO) medicineDAO).insertGetId(m);
        if (newId <= 0) return null;
        barcodeDAO.insert(newId, barcode, "primary", accountId, source);
        return medicineDAO.findById(newId);
    }

    /** JSON gọn cho 1 Medicines — dùng ở phản hồi lookup/quick-create-medicine của cả 2 servlet,
     *  để FE điền ngay các trường (NCC/đơn vị/giá) mà không cần round-trip thứ 2. */
    public static String medicineJson(Medicines m) {
        if (m == null) return "null";
        return "{\"id\":" + m.getMedicineId()
                + ",\"name\":" + jstr(m.getMedicineName())
                + ",\"code\":" + jstr(m.getMedicineCode())
                + ",\"barcode\":" + jstr(m.getBarcode())
                + ",\"unit\":" + jstr(m.getUnit())
                + ",\"price\":" + (m.getSellingPrice() != null ? m.getSellingPrice().toPlainString() : "0")
                + ",\"categoryId\":" + m.getCategoryId()
                + ",\"manufacturerId\":" + m.getManufacturerId()
                + ",\"rx\":" + m.isPrescriptionRequired()
                + ",\"storageConditions\":" + jstr(m.getStorageConditions())
                + "}";
    }

    private static String jstr(String s) {
        if (s == null) return "\"\"";
        return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r") + "\"";
    }
}
