package com.medivault.controller.admin;

import com.medivault.dao.*;
import com.medivault.entity.*;
import com.medivault.util.AuditHelper;
import com.medivault.util.ValidationUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

@WebServlet("/medicines")
public class MedicineServlet extends HttpServlet {

    private final MedicineDAO     medicineDAO     = new MedicineDAO();
    private final BatchesDAO      batchesDAO      = new BatchesDAO();
    private final CategoryDAO     categoryDAO     = new CategoryDAO();
    private final ManufacturerDAO manufacturerDAO = new ManufacturerDAO();
    private final SupplierDAO     supplierDAO     = new SupplierDAO();
    private final ShelfDAO        shelfDAO        = new ShelfDAO();

    // ── GET ───────────────────────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null) action = "list";

        switch (action) {
            case "list"        -> showList(req, resp);
            case "new"         -> showMedicineForm(req, resp, null);
            case "edit"        -> {
                int id = Integer.parseInt(req.getParameter("id"));
                showMedicineForm(req, resp, medicineDAO.findById(id));
            }
            case "detail"      -> showDetail(req, resp);
            case "new-batch"   -> showBatchForm(req, resp, null);
            case "edit-batch"  -> {
                int bid = Integer.parseInt(req.getParameter("id"));
                showBatchForm(req, resp, batchesDAO.findById(bid));
            }
            default            -> showList(req, resp);
        }
    }

    // ── POST ──────────────────────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "save-medicine"   -> saveMedicine(req, resp);
            case "delete-medicine" -> deleteMedicine(req, resp);
            case "toggle-medicine" -> toggleMedicine(req, resp);
            case "save-batch"      -> saveBatch(req, resp);
            case "delete-batch"    -> deleteBatch(req, resp);
            default -> resp.sendRedirect(req.getContextPath() + "/medicines");
        }
    }

    // ── LIST ──────────────────────────────────────────────────────────────────
    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String keyword = req.getParameter("q");
        List<Medicines> list = (keyword != null && !keyword.trim().isEmpty())
                ? medicineDAO.search(keyword.trim())
                : medicineDAO.findAllIncludeInactive();

        // Gắn tồn kho vào từng thuốc để hiển thị
        Map<Integer, Integer> stockMap = new HashMap<>();
        for (Medicines m : list)
            stockMap.put(m.getMedicineId(), batchesDAO.getTotalQuantity(m.getMedicineId()));

        req.setAttribute("medicines",   list);
        req.setAttribute("stockMap",    stockMap);
        req.setAttribute("categories",  categoryDAO.findAll());
        req.setAttribute("keyword",     keyword);
        req.setAttribute("totalActive", medicineDAO.countAll());
        req.setAttribute("lowStock",    medicineDAO.countLowStock());
        req.getRequestDispatcher("/WEB-INF/views/admin/medicine-list.jsp").forward(req, resp);
    }

    // ── DETAIL (danh sách lô của 1 thuốc) ────────────────────────────────────
    private void showDetail(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        int id = Integer.parseInt(req.getParameter("id"));
        Medicines m = medicineDAO.findById(id);
        if (m == null) { resp.sendRedirect(req.getContextPath() + "/medicines"); return; }

        req.setAttribute("medicine",   m);
        req.setAttribute("batches",    batchesDAO.findAllByMedicine(id));
        req.setAttribute("totalStock", batchesDAO.getTotalQuantity(id));
        req.getRequestDispatcher("/WEB-INF/views/admin/medicine-detail.jsp").forward(req, resp);
    }

    // ── FORM THUỐC ────────────────────────────────────────────────────────────
    private void showMedicineForm(HttpServletRequest req, HttpServletResponse resp, Medicines m)
            throws ServletException, IOException {
        req.setAttribute("medicine",      m);
        req.setAttribute("categories",    categoryDAO.findAll());
        req.setAttribute("manufacturers", manufacturerDAO.findAll());
        req.setAttribute("shelves",       shelfDAO.findAll());
        req.getRequestDispatcher("/WEB-INF/views/admin/medicine-form.jsp").forward(req, resp);
    }

    // ── FORM LÔ ───────────────────────────────────────────────────────────────
    private void showBatchForm(HttpServletRequest req, HttpServletResponse resp, Batches b)
            throws ServletException, IOException {
        String midStr = req.getParameter("medicineId");
        int medicineId = (b != null) ? b.getMedicineId()
                : (midStr != null ? Integer.parseInt(midStr) : 0);

        req.setAttribute("batch",     b);
        req.setAttribute("medicine",  medicineDAO.findById(medicineId));
        req.setAttribute("suppliers", supplierDAO.findAll());
        req.getRequestDispatcher("/WEB-INF/views/admin/batch-form.jsp").forward(req, resp);
    }

    // ── SAVE THUỐC ────────────────────────────────────────────────────────────
    private void saveMedicine(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {
        List<String> errors = new ArrayList<>();
        String idStr = req.getParameter("medicineId");
        boolean isNew = (idStr == null || idStr.isBlank());

        String name  = req.getParameter("medicineName");
        String price = req.getParameter("sellingPrice");
        String unit  = req.getParameter("unit");
        String catId = req.getParameter("categoryId");
        String mfrId = req.getParameter("manufacturerId");

        if (ValidationUtil.isBlank(name))  errors.add("Tên thuốc không được để trống!");
        if (ValidationUtil.isBlank(unit))  errors.add("Đơn vị không được để trống!");
        if (ValidationUtil.isBlank(price)) errors.add("Giá bán không được để trống!");
        if (ValidationUtil.isBlank(catId)) errors.add("Vui lòng chọn danh mục!");
        if (ValidationUtil.isBlank(mfrId)) errors.add("Vui lòng chọn nhà sản xuất!");

        if (!errors.isEmpty()) {
            req.setAttribute("errors", errors);
            showMedicineForm(req, resp, buildMedicineFromRequest(req, isNew ? null : Integer.parseInt(idStr)));
            return;
        }

        Medicines m = buildMedicineFromRequest(req, isNew ? null : Integer.parseInt(idStr));

        if (isNew) {
            boolean ok = medicineDAO.insert(m);
            if (ok) AuditHelper.log(req, "Thêm thuốc", "Medicine", "Thêm thuốc: " + m.getMedicineName());
            resp.sendRedirect(req.getContextPath() + "/medicines?msg=" + (ok ? "created" : "error"));
        } else {
            boolean ok = medicineDAO.update(m);
            if (ok) AuditHelper.log(req, "Cập nhật thuốc", "Medicine", "Sửa thuốc: " + m.getMedicineName());
            resp.sendRedirect(req.getContextPath() + "/medicines?msg=" + (ok ? "updated" : "error"));
        }
    }

    // ── DELETE THUỐC (soft) ───────────────────────────────────────────────────
    private void deleteMedicine(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int id = Integer.parseInt(req.getParameter("id"));
        Medicines m = medicineDAO.findById(id);
        // Chặn xóa nếu còn tồn kho
        if (batchesDAO.getTotalQuantity(id) > 0) {
            resp.sendRedirect(req.getContextPath() + "/medicines?msg=has-stock");
            return;
        }
        boolean ok = medicineDAO.delete(id);
        if (ok && m != null)
            AuditHelper.log(req, "Xóa thuốc", "Medicine", "Ẩn thuốc: " + m.getMedicineName());
        resp.sendRedirect(req.getContextPath() + "/medicines?msg=" + (ok ? "deleted" : "error"));
    }

    // ── TOGGLE ACTIVE THUỐC ───────────────────────────────────────────────────
    private void toggleMedicine(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int id = Integer.parseInt(req.getParameter("id"));
        medicineDAO.toggleStatus(id);
        Medicines m = medicineDAO.findById(id);
        if (m != null)
            AuditHelper.log(req, "Đổi trạng thái thuốc", "Medicine",
                    (m.isStatus() ? "Kích hoạt" : "Ẩn") + " thuốc: " + m.getMedicineName());
        resp.sendRedirect(req.getContextPath() + "/medicines?msg=updated");
    }

    // ── SAVE LÔ ───────────────────────────────────────────────────────────────
    private void saveBatch(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {
        List<String> errors = new ArrayList<>();
        String bidStr = req.getParameter("batchId");
        boolean isNew = (bidStr == null || bidStr.isBlank());

        String batchNo  = req.getParameter("batchNumber");
        String expiry   = req.getParameter("expiryDate");
        String qty      = req.getParameter("initialQuantity");
        String price    = req.getParameter("importPrice");
        String midStr   = req.getParameter("medicineId");

        if (ValidationUtil.isBlank(batchNo)) errors.add("Số lô không được để trống!");
        if (ValidationUtil.isBlank(expiry))  errors.add("Ngày hết hạn không được để trống!");
        if (ValidationUtil.isBlank(qty))     errors.add("Số lượng không được để trống!");
        if (ValidationUtil.isBlank(price))   errors.add("Giá nhập không được để trống!");

        // Kiểm tra ngày hết hạn phải > hôm nay
        if (!ValidationUtil.isBlank(expiry)) {
            try {
                LocalDate exp = LocalDate.parse(expiry);
                if (!exp.isAfter(LocalDate.now()))
                    errors.add("Ngày hết hạn phải sau ngày hôm nay!");
            } catch (Exception e) { errors.add("Ngày hết hạn không hợp lệ!"); }
        }

        int medicineId = midStr != null ? Integer.parseInt(midStr) : 0;

        if (!errors.isEmpty()) {
            req.setAttribute("errors", errors);
            showBatchForm(req, resp, isNew ? null : batchesDAO.findById(Integer.parseInt(bidStr)));
            return;
        }

        Batches b = new Batches();
        b.setMedicineId(medicineId);
        b.setBatchNumber(batchNo.trim());
        b.setExpiryDate(LocalDate.parse(expiry));
        b.setImportPrice(new BigDecimal(price));

        String mfDate = req.getParameter("manufactureDate");
        String supId  = req.getParameter("supplierId");
        if (!ValidationUtil.isBlank(mfDate)) b.setManufactureDate(LocalDate.parse(mfDate));
        b.setImportDate(LocalDate.now());
        if (!ValidationUtil.isBlank(supId)) b.setSupplierId(Integer.parseInt(supId));

        boolean ok;
        if (isNew) {
            b.setInitialQuantity(Integer.parseInt(qty));
            ok = batchesDAO.insert(b);
            if (ok) AuditHelper.log(req, "Nhập lô thuốc", "Batch",
                    "Nhập lô " + batchNo + " — SL: " + qty);
        } else {
            b.setBatchId(Integer.parseInt(bidStr));
            ok = batchesDAO.update(b);
            if (ok) AuditHelper.log(req, "Sửa lô thuốc", "Batch", "Sửa lô " + batchNo);
        }

        resp.sendRedirect(req.getContextPath() + "/medicines?action=detail&id=" + medicineId
                + "&msg=" + (ok ? (isNew ? "batch-added" : "batch-updated") : "error"));
    }

    // ── DELETE LÔ ─────────────────────────────────────────────────────────────
    private void deleteBatch(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int batchId    = Integer.parseInt(req.getParameter("id"));
        int medicineId = Integer.parseInt(req.getParameter("medicineId"));
        Batches b = batchesDAO.findById(batchId);

        // Chặn xóa lô còn hàng
        if (b != null && b.getCurrentQuantity() > 0) {
            resp.sendRedirect(req.getContextPath() + "/medicines?action=detail&id=" + medicineId + "&msg=batch-has-stock");
            return;
        }
        boolean ok = batchesDAO.delete(batchId);
        if (ok && b != null)
            AuditHelper.log(req, "Xóa lô thuốc", "Batch", "Xóa lô " + b.getBatchNumber());
        resp.sendRedirect(req.getContextPath() + "/medicines?action=detail&id=" + medicineId
                + "&msg=" + (ok ? "batch-deleted" : "error"));
    }

    // ── Helper: build Medicines từ request ────────────────────────────────────
    private Medicines buildMedicineFromRequest(HttpServletRequest req, Integer id) {
        Medicines m = new Medicines();
        if (id != null) m.setMedicineId(id);

        m.setMedicineName(req.getParameter("medicineName"));
        m.setGenericName(req.getParameter("genericName"));
        m.setBarcode(req.getParameter("barcode"));
        m.setRegistrationNumber(req.getParameter("registrationNumber"));
        m.setUnit(req.getParameter("unit"));
        m.setDosage(req.getParameter("dosage"));
        m.setContraindications(req.getParameter("contraindications"));
        m.setStorageConditions(req.getParameter("storageConditions"));
        m.setPrescriptionRequired("on".equals(req.getParameter("isPrescriptionRequired")));
        m.setStatus(true);

        try { m.setCategoryId(Integer.parseInt(req.getParameter("categoryId"))); } catch (Exception ignored) {}
        try { m.setManufacturerId(Integer.parseInt(req.getParameter("manufacturerId"))); } catch (Exception ignored) {}
        try { m.setShelfId(Integer.parseInt(req.getParameter("shelfId"))); } catch (Exception ignored) {}
        try { m.setSellingPrice(new BigDecimal(req.getParameter("sellingPrice"))); } catch (Exception ignored) {}
        try { m.setMinInventory(Integer.parseInt(req.getParameter("minInventory"))); } catch (Exception ignored) {}
        try { m.setExpiryAlertDays(Integer.parseInt(req.getParameter("expiryAlertDays"))); } catch (Exception ignored) {}

        return m;
    }
}