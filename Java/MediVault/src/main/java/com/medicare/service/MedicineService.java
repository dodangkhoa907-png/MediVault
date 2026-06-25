package com.medicare.service;

import com.medicare.dao.*;
import com.medicare.entity.*;
import com.medicare.service.interfaces.IMedicineService;
import com.medicare.util.ValidationUtil;

import java.util.ArrayList;
import java.util.List;

/**
 * MedicineService — Tầng nghiệp vụ cho Thuốc + Lô hàng.
 *
 * Trước đây logic PO-creation khi nhập lô nằm trực tiếp trong MedicineServlet.
 * Nay được tách ra đây để Servlet chỉ lo HTTP request/response.
 */
public class MedicineService implements IMedicineService {

    private final MedicineDAO      medicineDAO  = new MedicineDAO();
    private final BatchesDAO       batchesDAO   = new BatchesDAO();
    private final PurchaseOrderDAO poDAO        = new PurchaseOrderDAO();
    private final SupplierDAO      supplierDAO  = new SupplierDAO();

    // ── Thuốc ──────────────────────────────────────────────────────────────

    @Override
    public ServiceResult<Medicines> saveMedicine(Medicines m, boolean isNew) {
        List<String> errors = new ArrayList<>();

        if (ValidationUtil.isBlank(m.getMedicineName()))
            errors.add("Tên thuốc không được để trống!");
        if (ValidationUtil.isBlank(m.getUnit()))
            errors.add("Đơn vị không được để trống!");
        if (m.getSellingPrice() == null)
            errors.add("Giá bán không được để trống!");
        if (m.getCategoryId() <= 0)
            errors.add("Vui lòng chọn danh mục!");
        if (m.getManufacturerId() <= 0)
            errors.add("Vui lòng chọn nhà sản xuất!");

        if (!errors.isEmpty()) return ServiceResult.fail(errors);

        boolean ok = isNew ? medicineDAO.insert(m) : medicineDAO.update(m);
        if (!ok) return ServiceResult.fail("Lưu thuốc thất bại — kiểm tra log Tomcat!");

        return ServiceResult.ok(m);
    }

    @Override
    public ServiceResult<Void> deleteMedicine(int medicineId) {
        if (batchesDAO.getTotalQuantity(medicineId) > 0)
            return ServiceResult.fail("Không thể xóa: thuốc này vẫn còn tồn kho!");
        boolean ok = medicineDAO.delete(medicineId);
        return ok ? ServiceResult.ok() : ServiceResult.fail("Xóa thuốc thất bại!");
    }

    // ── Lô hàng ────────────────────────────────────────────────────────────

    @Override
    public ServiceResult<Batches> saveBatch(
            Batches b, boolean isNew,
            String poMode, String poIdStr,
            String newSupplierId, String newPoNotes,
            int adminAccountId) {

        if (!isNew) {
            // Cập nhật lô — không cần xử lý PO
            boolean ok = batchesDAO.update(b);
            return ok ? ServiceResult.ok(b) : ServiceResult.fail("Cập nhật lô thất bại!");
        }

        // ── Nhập lô mới: bắt buộc gắn vào một Đơn đặt hàng ──────────────
        // (FK_Batch_PO NOT NULL trong DB)
        int poId       = -1;
        int supplierId = -1;

        if ("existing".equals(poMode)) {
            if (ValidationUtil.isBlank(poIdStr))
                return ServiceResult.fail("Vui lòng chọn đơn đặt hàng đã có!");

            PurchaseOrders po;
            try {
                po = poDAO.findById(Integer.parseInt(poIdStr));
            } catch (NumberFormatException e) {
                return ServiceResult.fail("ID đơn đặt hàng không hợp lệ!");
            }
            if (po == null)
                return ServiceResult.fail("Đơn đặt hàng không tồn tại, vui lòng chọn lại!");

            poId       = po.getPoId();
            supplierId = po.getSupplierId();

        } else {
            // mode = "new" — tạo đơn đặt hàng mới ngay
            if (ValidationUtil.isBlank(newSupplierId))
                return ServiceResult.fail("Vui lòng chọn nhà cung cấp cho đơn đặt hàng mới!");

            int supId;
            try {
                supId = Integer.parseInt(newSupplierId);
            } catch (NumberFormatException e) {
                return ServiceResult.fail("ID nhà cung cấp không hợp lệ!");
            }

            PurchaseOrders newPo = new PurchaseOrders();
            newPo.setSupplierId(supId);
            newPo.setAccountId(adminAccountId);
            newPo.setNotes(!ValidationUtil.isBlank(newPoNotes) ? newPoNotes.trim() : null);

            poId = poDAO.insert(newPo);
            if (poId <= 0)
                return ServiceResult.fail("Không tạo được đơn đặt hàng mới, vui lòng thử lại!");

            supplierId = supId;
        }

        b.setPoId(poId);
        b.setSupplierId(supplierId);

        boolean ok = batchesDAO.insert(b);
        if (!ok) return ServiceResult.fail("Nhập lô thất bại — kiểm tra log Tomcat!");

        // Cập nhật lại tổng giá trị đơn
        poDAO.recalcTotalValue(poId);

        return ServiceResult.ok(b);
    }

    @Override
    public ServiceResult<Void> deleteBatch(int batchId) {
        Batches b = batchesDAO.findById(batchId);
        if (b != null && b.getCurrentQuantity() > 0)
            return ServiceResult.fail("Không thể xóa lô còn hàng trong kho!");
        boolean ok = batchesDAO.delete(batchId);
        return ok ? ServiceResult.ok() : ServiceResult.fail("Xóa lô thất bại!");
    }
}
