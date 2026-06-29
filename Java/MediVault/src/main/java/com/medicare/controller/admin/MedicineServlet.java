package com.medicare.controller.admin;

import com.medicare.dao.*;
import com.medicare.entity.*;
import com.medicare.service.MedicineService;
import com.medicare.service.ServiceResult;
import com.medicare.service.interfaces.IMedicineService;
import com.medicare.util.AuditHelper;
import com.medicare.util.SidebarHelper;
import com.medicare.util.ValidationUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.File;
import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

@WebServlet("/medicines")
@MultipartConfig(fileSizeThreshold = 1024 * 512, maxFileSize = 3 * 1024 * 1024, maxRequestSize = 6 * 1024 * 1024)
public class MedicineServlet extends HttpServlet {

    private static final int PAGE_SIZE = 20;

    private final MedicineDAO medicineDAO = new MedicineDAO();
    private final BatchesDAO batchesDAO = new BatchesDAO();
    private final CategoryDAO categoryDAO = new CategoryDAO();
    private final ManufacturerDAO manufacturerDAO = new ManufacturerDAO();
    private final SupplierDAO supplierDAO = new SupplierDAO();
    private final ShelfDAO shelfDAO = new ShelfDAO();
    private final PurchaseOrderDAO poDAO = new PurchaseOrderDAO();
    private final IMedicineService medicineService = new MedicineService();

    // ── GET ───────────────────────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        if (action == null)
            action = "list";

        switch (action) {
            case "list" -> showList(req, resp);
            case "new" -> showMedicineForm(req, resp, null);
            case "edit" -> {
                int id = Integer.parseInt(req.getParameter("id"));
                Medicines found = medicineDAO.findById(id);
                if (found == null) req.setAttribute("editNotFound", true);
                showMedicineForm(req, resp, found);
            }
            case "api-med"       -> apiGetMedicine(req, resp);
            case "api-batches"   -> apiGetBatches(req, resp);
            case "api-stats"     -> apiGetStats(resp);
            case "api-stock-map" -> apiGetStockMap(resp);
            case "detail" -> showDetail(req, resp);
            case "new-batch" -> showBatchForm(req, resp, null);
            case "edit-batch" -> {
                int bid = Integer.parseInt(req.getParameter("id"));
                showBatchForm(req, resp, batchesDAO.findById(bid));
            }
            default -> showList(req, resp);
        }
    }

    // ── POST ──────────────────────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");
        if (action == null)
            action = "";

        switch (action) {
            case "save-medicine" -> saveMedicine(req, resp);
            case "delete-medicine" -> deleteMedicine(req, resp);
            case "toggle-medicine" -> toggleMedicine(req, resp);
            case "save-batch" -> saveBatch(req, resp);
            case "add-stock" -> addStock(req, resp);
            case "delete-batch" -> deleteBatch(req, resp);
            case "destroy-batch" -> destroyBatch(req, resp);
            case "create-category-ajax"    -> createCategoryAjax(req, resp);
            case "create-manufacturer-ajax" -> createManufacturerAjax(req, resp);
            case "delete-manufacturer-ajax" -> deleteManufacturerAjax(req, resp);
            case "create-po-ajax"           -> createPoAjax(req, resp);
            default -> resp.sendRedirect(req.getContextPath() + "/medicines");
        }
    }

    // ── LIST (server-side pagination) ─────────────────────────────────────────
    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String keyword = req.getParameter("q");
        Integer catId = null;
        try {
            catId = Integer.parseInt(req.getParameter("catId"));
        } catch (Exception ignored) {
        }

        int pageSize = PAGE_SIZE;
        try {
            int ps = Integer.parseInt(req.getParameter("pageSize"));
            if (ps == 10 || ps == 20 || ps == 50 || ps == 100) pageSize = ps;
        } catch (Exception ignored) {}

        int page = 1;
        try {
            page = Math.max(1, Integer.parseInt(req.getParameter("page")));
        } catch (Exception ignored) {
        }

        int total = medicineDAO.countForList(keyword, catId);
        int totalPages = Math.max(1, (int) Math.ceil((double) total / pageSize));
        page = Math.min(page, totalPages);

        List<Medicines> list = medicineDAO.findPaged(keyword, catId, page, pageSize);

        // 1 query cho toàn bộ tồn kho — nhanh hơn N queries per trang
        Map<Integer, Integer> stockMap = batchesDAO.getTotalQuantityMap();

        // Batch summaries cho hover card + tab badge counts
        Map<Integer, Integer> activeBatchCountMap  = new HashMap<>();
        Map<Integer, Integer> expiringSoonCountMap  = new HashMap<>();
        Map<Integer, Integer> expiredBatchCountMap  = new HashMap<>();
        Map<Integer, String>  nearestExpiryMap      = new HashMap<>();
        batchesDAO.loadBatchSummary(activeBatchCountMap, expiringSoonCountMap, expiredBatchCountMap, nearestExpiryMap);

        // Counts cho tab badge (toàn bộ DB, không phụ thuộc page)
        int totalOutOfStock   = (int) stockMap.values().stream().filter(s -> s == null || s == 0).count();
        int totalExpiringSoon = (int) expiringSoonCountMap.values().stream().filter(v -> v > 0).count();
        int totalExpiredMeds  = (int) expiredBatchCountMap.values().stream().filter(v -> v > 0).count();

        String statusFilter = req.getParameter("statusFilter");
        req.setAttribute("medicines", list);
        req.setAttribute("stockMap", stockMap);
        req.setAttribute("categories", categoryDAO.findAll());
        req.setAttribute("manufacturers", manufacturerDAO.findAll());
        req.setAttribute("shelves", shelfDAO.findAll());
        req.setAttribute("suppliers", supplierDAO.findAllActive());
        req.setAttribute("statusFilter", statusFilter != null ? statusFilter : "");
        req.setAttribute("activeBatchCountMap", activeBatchCountMap);
        req.setAttribute("expiringSoonCountMap", expiringSoonCountMap);
        req.setAttribute("expiredBatchCountMap", expiredBatchCountMap);
        req.setAttribute("nearestExpiryMap", nearestExpiryMap);
        req.setAttribute("totalOutOfStock", totalOutOfStock);
        req.setAttribute("totalExpiringSoon", totalExpiringSoon);
        req.setAttribute("totalExpiredMeds", totalExpiredMeds);
        req.setAttribute("keyword", keyword);
        req.setAttribute("catId", catId);
        req.setAttribute("currentPage", page);
        req.setAttribute("totalPages", totalPages);
        req.setAttribute("totalCount", total);
        req.setAttribute("pageSize", pageSize);
        req.setAttribute("pageFrom", (page - 1) * pageSize + 1);
        req.setAttribute("pageTo",   Math.min(page * pageSize, total));
        req.setAttribute("totalActive", medicineDAO.countAll());
        req.setAttribute("lowStock", medicineDAO.countLowStock());
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/admin/medicine-list.jsp").forward(req, resp);
    }

    // ── DETAIL (danh sách lô của 1 thuốc) ────────────────────────────────────
    private void showDetail(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        int id = Integer.parseInt(req.getParameter("id"));
        Medicines m = medicineDAO.findById(id);
        if (m == null) {
            resp.sendRedirect(req.getContextPath() + "/medicines");
            return;
        }

        req.setAttribute("medicine", m);
        req.setAttribute("batches", batchesDAO.findAllByMedicine(id));
        req.setAttribute("totalStock", batchesDAO.getTotalQuantity(id));
        req.setAttribute("today", LocalDate.now());
        req.setAttribute("today90", LocalDate.now().plusDays(90)); // dùng cho FEFO color-code HSD
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/admin/medicine-detail.jsp").forward(req, resp);
    }

    // ── FORM THUỐC ────────────────────────────────────────────────────────────
    private void showMedicineForm(HttpServletRequest req, HttpServletResponse resp, Medicines m)
            throws ServletException, IOException {
        req.setAttribute("medicine", m);
        req.setAttribute("categories", categoryDAO.findAll());
        req.setAttribute("manufacturers", manufacturerDAO.findAll());
        req.setAttribute("shelves", shelfDAO.findAll());

        // Edit mode: truyền dữ liệu lô & tồn kho
        if (m != null && m.getMedicineId() > 0) {
            int medId = m.getMedicineId();
            List<Batches> activeBatches = batchesDAO.findByMedicine(medId);
            req.setAttribute("batches", activeBatches);
            req.setAttribute("totalStock", batchesDAO.getTotalQuantity(medId));
            req.setAttribute("today", LocalDate.now());
            req.setAttribute("today90", LocalDate.now().plusDays(90));
            // Giá nhập lần cuối — dùng để cảnh báo bất thường trong modal nhập lô
            if (!activeBatches.isEmpty())
                req.setAttribute("lastImportPrice", activeBatches.get(0).getImportPrice());
        }

        SidebarHelper.load(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/medicine-form.jsp").forward(req, resp);
    }

    // ── FORM LÔ ───────────────────────────────────────────────────────────────
    private void showBatchForm(HttpServletRequest req, HttpServletResponse resp, Batches b)
            throws ServletException, IOException {
        String midStr = req.getParameter("medicineId");
        int medicineId = (b != null) ? b.getMedicineId()
                : (midStr != null ? Integer.parseInt(midStr) : 0);

        // Đơn đặt hàng gần đây — để chọn "đơn có sẵn" khi nhập lô mới
        List<PurchaseOrders> recentPOs = poDAO.findRecent(15);
        Map<Integer, Supplier> poSupplierMap = new HashMap<>();
        for (PurchaseOrders po : recentPOs) {
            poSupplierMap.computeIfAbsent(po.getSupplierId(), supplierDAO::findById);
        }

        req.setAttribute("batch", b);
        req.setAttribute("isNew", b == null || b.getBatchId() == 0);
        req.setAttribute("medicine", medicineDAO.findById(medicineId));
        req.setAttribute("suppliers", supplierDAO.findAllActive());
        req.setAttribute("shelves", shelfDAO.findAll());
        req.setAttribute("recentPOs", recentPOs);
        req.setAttribute("poSupplierMap", poSupplierMap);
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/admin/batch-form.jsp").forward(req, resp);
    }

    // ── SAVE THUỐC ────────────────────────────────────────────────────────────
    private void saveMedicine(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {
        List<String> errors = new ArrayList<>();
        String idStr = req.getParameter("medicineId");
        boolean isNew = (idStr == null || idStr.isBlank());

        String name = req.getParameter("medicineName");
        String price = req.getParameter("sellingPrice");
        String unit = req.getParameter("unit");
        String catId = req.getParameter("categoryId");
        String mfrId = req.getParameter("manufacturerId");

        if (ValidationUtil.isBlank(name))
            errors.add("Tên thuốc không được để trống!");
        if (ValidationUtil.isBlank(unit))
            errors.add("Đơn vị không được để trống!");
        if (ValidationUtil.isBlank(price))
            errors.add("Giá bán không được để trống!");
        if (ValidationUtil.isBlank(catId))
            errors.add("Vui lòng chọn danh mục!");
        if (ValidationUtil.isBlank(mfrId))
            errors.add("Vui lòng chọn nhà sản xuất!");

        // Validate initial stock (only for new medicine when admin declares existing qty)
        int initialQty = 0;
        LocalDate initialExpiry = null;
        if (isNew) {
            String initQtyStr    = req.getParameter("initialQuantity");
            String initExpiryStr = req.getParameter("initialExpiryDate");
            try { initialQty = Integer.parseInt(initQtyStr); } catch (Exception ignored) {}
            if (initialQty > 0) {
                if (ValidationUtil.isBlank(initExpiryStr)) {
                    errors.add("Ngày hết hạn lô đầu tiên bắt buộc khi có số lượng ban đầu!");
                } else {
                    try {
                        initialExpiry = LocalDate.parse(initExpiryStr);
                        if (!initialExpiry.isAfter(LocalDate.now()))
                            errors.add("Ngày hết hạn lô ban đầu phải sau ngày hôm nay!");
                    } catch (Exception e) {
                        errors.add("Ngày hết hạn lô ban đầu không hợp lệ!");
                    }
                }
            }
        }

        if (!errors.isEmpty()) {
            req.setAttribute("errors", errors);
            showMedicineForm(req, resp, buildMedicineFromRequest(req, isNew ? null : Integer.parseInt(idStr)));
            return;
        }

        Medicines m = buildMedicineFromRequest(req, isNew ? null : Integer.parseInt(idStr));

        Part imagePart = null;
        try { imagePart = req.getPart("imageFile"); } catch (Exception ignored) {}

        if (isNew) {
            int newId = medicineDAO.insertGetId(m);
            if (newId > 0) {
                String imgUrl = saveImage(imagePart, newId);
                if (imgUrl != null) medicineDAO.updateImageUrl(newId, imgUrl);
                AuditHelper.log(req, "Thêm thuốc", "Medicine", "Thêm thuốc: " + m.getMedicineName());
                if (initialQty > 0 && initialExpiry != null) {
                    Batches initBatch = new Batches();
                    initBatch.setMedicineId(newId);
                    initBatch.setBatchNumber("INIT-" + newId + "-" + (System.currentTimeMillis() % 100000));
                    initBatch.setImportDate(LocalDate.now());
                    initBatch.setExpiryDate(initialExpiry);
                    initBatch.setInitialQuantity(initialQty);
                    String initPriceStr = req.getParameter("initialImportPrice");
                    try { initBatch.setImportPrice(new BigDecimal(initPriceStr)); }
                    catch (Exception ignored) { initBatch.setImportPrice(BigDecimal.ZERO); }
                    batchesDAO.insert(initBatch);
                    AuditHelper.log(req, "Nhập lô ban đầu", "Batch",
                            "Lô đầu thuốc ID=" + newId + ": SL=" + initialQty);
                }
                resp.sendRedirect(req.getContextPath() + "/medicines?msg=created");
            } else {
                resp.sendRedirect(req.getContextPath() + "/medicines?msg=error");
            }
        } else {
            String newImgUrl = saveImage(imagePart, m.getMedicineId());
            if (newImgUrl != null) m.setImageUrl(newImgUrl);
            boolean ok = medicineDAO.update(m);
            if (ok)
                AuditHelper.log(req, "Cập nhật thuốc", "Medicine", "Sửa thuốc: " + m.getMedicineName());
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
        String bidStr  = req.getParameter("batchId");
        boolean isNew  = (bidStr == null || bidStr.isBlank());
        String poMode  = req.getParameter("poMode");
        String returnTo = req.getParameter("returnTo"); // "edit" khi gọi từ modal trong medicine-form

        String batchNo = req.getParameter("batchNumber");
        String expiry  = req.getParameter("expiryDate");
        String qty     = req.getParameter("initialQuantity");
        String price   = req.getParameter("importPrice");
        String midStr  = req.getParameter("medicineId");

        if (ValidationUtil.isBlank(batchNo))  errors.add("Số lô không được để trống!");
        if (ValidationUtil.isBlank(expiry))   errors.add("Ngày hết hạn không được để trống!");
        if (isNew && ValidationUtil.isBlank(qty)) errors.add("Số lượng không được để trống!");
        if (ValidationUtil.isBlank(price))    errors.add("Giá nhập không được để trống!");

        LocalDate parsedExpiry = null;
        LocalDate parsedMfDate = null;
        if (!ValidationUtil.isBlank(expiry)) {
            try {
                parsedExpiry = LocalDate.parse(expiry);
                if (isNew && !parsedExpiry.isAfter(LocalDate.now()))
                    errors.add("Ngày hết hạn phải sau ngày hôm nay!");
            } catch (Exception e) {
                errors.add("Ngày hết hạn không hợp lệ!");
            }
        }
        String mfDate = req.getParameter("manufactureDate");
        if (!ValidationUtil.isBlank(mfDate)) {
            try {
                parsedMfDate = LocalDate.parse(mfDate);
                if (parsedExpiry != null && parsedMfDate.isAfter(parsedExpiry))
                    errors.add("Ngày sản xuất không thể sau ngày hết hạn!");
            } catch (Exception e) {
                errors.add("Ngày sản xuất không hợp lệ!");
            }
        }

        int medicineId = 0;
        try { medicineId = Integer.parseInt(midStr); } catch (Exception ignored) {}

        // Redirect destination — về edit page nếu gọi từ modal
        final String baseEdit   = req.getContextPath() + "/medicines?action=edit&id=" + medicineId;
        final String baseDetail = req.getContextPath() + "/medicines?action=detail&id=" + medicineId;
        final String base       = "edit".equals(returnTo) ? baseEdit : baseDetail;

        if (!errors.isEmpty()) {
            if ("edit".equals(returnTo)) {
                resp.sendRedirect(base + "&batchErr=" + java.net.URLEncoder.encode(errors.get(0), "UTF-8"));
                return;
            }
            req.setAttribute("errors", errors);
            showBatchForm(req, resp, isNew ? null : batchesDAO.findById(Integer.parseInt(bidStr)));
            return;
        }

        // ── SMART BATCH DETECTION (chỉ cho nhập nhanh từ modal: isNew + poMode=none) ──
        if (isNew && "none".equals(poMode)) {
            Batches existing = batchesDAO.findByMedicineAndBatchNumber(medicineId, batchNo.trim());
            if (existing != null) {
                // Case 3: lô đã hết hạn hoặc bị tiêu hủy
                if ("DESTROYED".equals(existing.getStatus())
                        || existing.getExpiryDate().isBefore(LocalDate.now())) {
                    resp.sendRedirect(base + "&batchErr=" + java.net.URLEncoder.encode(
                            "Lô '" + batchNo.trim() + "' đã hết hạn hoặc bị tiêu hủy — hãy dùng số lô mới.", "UTF-8"));
                    return;
                }
                // Case 1: lô còn hoạt động → cộng thêm
                int addQty = 0;
                try { addQty = Integer.parseInt(qty); } catch (Exception ignored) {}
                if (addQty <= 0) {
                    resp.sendRedirect(base + "&batchErr=" + java.net.URLEncoder.encode(
                            "Số lượng nhập phải lớn hơn 0!", "UTF-8"));
                    return;
                }
                boolean ok = batchesDAO.addStock(existing.getBatchId(), addQty);
                if (ok) AuditHelper.log(req, "Bổ sung vào lô", "Batch",
                        "Lô " + batchNo.trim() + " (thuốc ID=" + medicineId + "): +" + addQty);
                resp.sendRedirect(base + "&msg=" + (ok ? "batch-stock-added" : "batch-stock-fail")
                        + "&addedQty=" + addQty);
                return;
                // Case 2: lô chưa tồn tại → fall-through bên dưới để insert bình thường
            }
        }

        // ── NORMAL SAVE (insert mới hoặc update lô từ batch-form.jsp) ────────────
        Batches b = new Batches();
        b.setMedicineId(medicineId);
        b.setBatchNumber(batchNo.trim());
        b.setExpiryDate(parsedExpiry);
        b.setImportPrice(new BigDecimal(price));
        b.setInitialQuantity(isNew ? Integer.parseInt(qty) : 0);
        if (parsedMfDate != null) b.setManufactureDate(parsedMfDate);
        if (isNew) b.setImportDate(LocalDate.now());
        if (!isNew) b.setBatchId(Integer.parseInt(bidStr));

        Account adminAcc = (Account) req.getSession(false).getAttribute("adminAccount");
        int adminId = adminAcc != null ? adminAcc.getAccountId() : 1;

        ServiceResult<Batches> result = medicineService.saveBatch(
                b, isNew, poMode,
                req.getParameter("poId"),
                req.getParameter("newPoSupplierId"),
                req.getParameter("newPoNotes"),
                adminId);

        if (result.isFail()) {
            if ("edit".equals(returnTo)) {
                String errMsg = result.hasErrors() ? result.getErrors().get(0) : result.getMessage();
                resp.sendRedirect(base + "&batchErr=" + java.net.URLEncoder.encode(errMsg != null ? errMsg : "Lỗi không xác định", "UTF-8"));
                return;
            }
            req.setAttribute("errors", result.hasErrors() ? result.getErrors() : List.of(result.getMessage()));
            showBatchForm(req, resp, isNew ? null : b);
            return;
        }

        AuditHelper.log(req, isNew ? "Nhập lô thuốc" : "Sửa lô thuốc", "Batch",
                (isNew ? "Nhập lô " : "Sửa lô ") + batchNo + (isNew ? " — SL: " + qty : ""));
        resp.sendRedirect(base + "&msg=" + (isNew ? "batch-added" : "batch-updated"));
    }

    // ── HỦY LÔ (CANCELLED) ───────────────────────────────────────────────────
    private void deleteBatch(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int batchId    = Integer.parseInt(req.getParameter("id"));
        int medicineId = Integer.parseInt(req.getParameter("medicineId"));
        Batches b = batchesDAO.findById(batchId);

        ServiceResult<Void> result = medicineService.deleteBatch(batchId);
        if (result.isFail()) {
            String msg = result.getMessage() != null && result.getMessage().contains("lịch sử bán")
                    ? "batch-has-sales" : "batch-has-stock";
            resp.sendRedirect(req.getContextPath() + "/medicines?action=detail&id=" + medicineId + "&msg=" + msg);
            return;
        }
        if (b != null)
            AuditHelper.log(req, "Hủy lô thuốc (CANCELLED)", "Batch",
                    "Hủy lô " + b.getBatchNumber() + " — chưa có bán hàng");
        resp.sendRedirect(req.getContextPath() + "/medicines?action=detail&id=" + medicineId + "&msg=batch-deleted");
    }

    // ── TIÊU HỦY LÔ (DESTROYED) ──────────────────────────────────────────────
    private void destroyBatch(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int batchId    = Integer.parseInt(req.getParameter("id"));
        int medicineId = Integer.parseInt(req.getParameter("medicineId"));
        Batches b = batchesDAO.findById(batchId);

        ServiceResult<Void> result = medicineService.destroyBatch(batchId);
        if (result.isFail()) {
            resp.sendRedirect(req.getContextPath() + "/medicines?action=detail&id=" + medicineId + "&msg=batch-destroy-fail");
            return;
        }
        if (b != null)
            AuditHelper.log(req, "Tiêu hủy lô thuốc (DESTROYED)", "Batch",
                    "Tiêu hủy lô " + b.getBatchNumber() + " — SL còn lại lúc tiêu hủy: " + b.getCurrentQuantity());
        resp.sendRedirect(req.getContextPath() + "/medicines?action=detail&id=" + medicineId + "&msg=batch-destroyed");
    }

    // ── NHẬP THÊM VÀO LÔ (ADD STOCK) ────────────────────────────────────────
    private void addStock(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        int batchId = 0;
        int medicineId = 0;
        int qty = 0;
        try { batchId = Integer.parseInt(req.getParameter("batchId")); } catch (Exception ignored) {}
        try { medicineId = Integer.parseInt(req.getParameter("medicineId")); } catch (Exception ignored) {}
        try { qty = Integer.parseInt(req.getParameter("qty")); } catch (Exception ignored) {}

        String base = req.getContextPath() + "/medicines?action=detail&id=" + medicineId;

        if (qty <= 0) {
            resp.sendRedirect(base + "&msg=stock-qty-invalid");
            return;
        }

        Batches batch = batchesDAO.findById(batchId);
        if (batch == null || !"ACTIVE".equals(batch.getStatus())) {
            resp.sendRedirect(base + "&msg=batch-not-found");
            return;
        }

        boolean ok = batchesDAO.addStock(batchId, qty);
        if (ok)
            AuditHelper.log(req, "Nhập thêm vào lô", "Batch",
                    "Lô " + batch.getBatchNumber() + ": bổ sung +" + qty);
        resp.sendRedirect(base + "&msg=" + (ok ? "stock-added" : "stock-add-fail"));
    }

    // ── Helper: build Medicines từ request ────────────────────────────────────
    private Medicines buildMedicineFromRequest(HttpServletRequest req, Integer id) {
        Medicines m = new Medicines();
        if (id != null)
            m.setMedicineId(id);

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

        try {
            m.setCategoryId(Integer.parseInt(req.getParameter("categoryId")));
        } catch (Exception ignored) {
        }
        try {
            m.setManufacturerId(Integer.parseInt(req.getParameter("manufacturerId")));
        } catch (Exception ignored) {
        }
        try {
            m.setShelfId(Integer.parseInt(req.getParameter("shelfId")));
        } catch (Exception ignored) {
        }
        try {
            m.setSellingPrice(new BigDecimal(req.getParameter("sellingPrice")));
        } catch (Exception ignored) {
        }
        try {
            m.setMinInventory(Integer.parseInt(req.getParameter("minInventory")));
        } catch (Exception ignored) {
        }
        try {
            m.setExpiryAlertDays(Integer.parseInt(req.getParameter("expiryAlertDays")));
        } catch (Exception ignored) {
        }
        m.setPackagingSpec(req.getParameter("packagingSpec"));
        // Existing image URL is passed as hidden field; preserved unless a new image is uploaded
        m.setImageUrl(req.getParameter("existingImageUrl"));

        return m;
    }

    // ── Image upload helper ───────────────────────────────────────────────────
    private String saveImage(Part imagePart, int medicineId) {
        try {
            if (imagePart == null || imagePart.getSize() == 0) return null;
            String ct = imagePart.getContentType();
            if (ct == null || !ct.startsWith("image/")) return null;

            String ext = ".jpg";
            if (ct.contains("png"))  ext = ".png";
            else if (ct.contains("webp")) ext = ".webp";
            else if (ct.contains("gif"))  ext = ".gif";

            String uploadDir = getServletContext().getRealPath("/uploads/medicines");
            File dir = new File(uploadDir);
            if (!dir.exists()) dir.mkdirs();

            // Remove any old image files for this medicine (different extensions)
            for (String e : new String[]{".jpg", ".jpeg", ".png", ".webp", ".gif"}) {
                File old = new File(uploadDir + File.separator + medicineId + e);
                if (old.exists()) old.delete();
            }

            String filename = medicineId + ext;
            imagePart.write(uploadDir + File.separator + filename);
            return "uploads/medicines/" + filename;
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }

    // ── JSON API: lấy thông tin thuốc cho drawer edit ─────────────────────────
    private void apiGetMedicine(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        try {
            int id = Integer.parseInt(req.getParameter("id"));
            Medicines m = medicineDAO.findById(id);
            if (m == null) { out.print("{\"error\":\"not found\"}"); return; }

            // Lookup names for display in detail modal
            String catName = "";
            String mfrName = "";
            String shelfName = "";
            if (m.getCategoryId() != null) {
                var cat = categoryDAO.findById(m.getCategoryId());
                if (cat != null) catName = cat.getCategoryName();
            }
            if (m.getManufacturerId() != null) {
                var mfr = manufacturerDAO.findById(m.getManufacturerId());
                if (mfr != null) mfrName = mfr.getName();
            }
            if (m.getShelfId() != null) {
                var shelf = shelfDAO.findById(m.getShelfId());
                if (shelf != null) shelfName = shelf.getShelfName();
            }
            // Total stock from batches
            Map<Integer, Integer> stockMap = batchesDAO.getTotalQuantityMap();
            int totalStock = stockMap.getOrDefault(m.getMedicineId(), 0);

            StringBuilder sb = new StringBuilder("{");
            sb.append("\"id\":").append(m.getMedicineId()).append(',');
            sb.append("\"medicineCode\":").append(jsonStr(m.getMedicineCode())).append(',');
            sb.append("\"medicineName\":").append(jsonStr(m.getMedicineName())).append(',');
            sb.append("\"genericName\":").append(jsonStr(m.getGenericName())).append(',');
            sb.append("\"barcode\":").append(jsonStr(m.getBarcode())).append(',');
            sb.append("\"registrationNumber\":").append(jsonStr(m.getRegistrationNumber())).append(',');
            sb.append("\"unit\":").append(jsonStr(m.getUnit())).append(',');
            sb.append("\"categoryId\":").append(m.getCategoryId() != null ? m.getCategoryId() : 0).append(',');
            sb.append("\"categoryName\":").append(jsonStr(catName)).append(',');
            sb.append("\"manufacturerId\":").append(m.getManufacturerId() != null ? m.getManufacturerId() : 0).append(',');
            sb.append("\"manufacturerName\":").append(jsonStr(mfrName)).append(',');
            sb.append("\"shelfId\":").append(m.getShelfId() != null ? m.getShelfId() : 0).append(',');
            sb.append("\"shelfName\":").append(jsonStr(shelfName)).append(',');
            sb.append("\"sellingPrice\":").append(m.getSellingPrice() != null ? m.getSellingPrice().toPlainString() : "0").append(',');
            sb.append("\"minInventory\":").append(m.getMinInventory()).append(',');
            sb.append("\"expiryAlertDays\":").append(m.getExpiryAlertDays()).append(',');
            sb.append("\"isPrescriptionRequired\":").append(m.isPrescriptionRequired()).append(',');
            sb.append("\"status\":").append(m.isStatus()).append(',');
            sb.append("\"totalStock\":").append(totalStock).append(',');
            sb.append("\"dosage\":").append(jsonStr(m.getDosage())).append(',');
            sb.append("\"contraindications\":").append(jsonStr(m.getContraindications())).append(',');
            sb.append("\"storageConditions\":").append(jsonStr(m.getStorageConditions())).append(',');
            sb.append("\"packagingSpec\":").append(jsonStr(m.getPackagingSpec())).append(',');
            sb.append("\"imageUrl\":").append(jsonStr(m.getImageUrl()));
            sb.append('}');
            out.print(sb);
        } catch (Exception e) {
            out.print("{\"error\":\"" + e.getMessage() + "\"}");
        }
    }
    private String jsonStr(String s) {
        if (s == null) return "\"\"";
        return "\"" + s.replace("\\","\\\\").replace("\"","\\\"")
                       .replace("\n","\\n").replace("\r","\\r").replace("\t","\\t") + "\"";
    }

    private void apiGetBatches(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        try {
            int medicineId = Integer.parseInt(req.getParameter("medicineId"));
            List<Batches> list = batchesDAO.findAllByMedicine(medicineId);
            StringBuilder sb = new StringBuilder("[");
            for (int i = 0; i < list.size(); i++) {
                Batches b = list.get(i);
                if (i > 0) sb.append(',');
                sb.append('{');
                sb.append("\"batchId\":").append(b.getBatchId()).append(',');
                sb.append("\"batchNumber\":").append(jsonStr(b.getBatchNumber())).append(',');
                sb.append("\"importDate\":").append(jsonStr(b.getImportDate() != null ? b.getImportDate().toString() : "")).append(',');
                sb.append("\"manufactureDate\":").append(jsonStr(b.getManufactureDate() != null ? b.getManufactureDate().toString() : "")).append(',');
                sb.append("\"expiryDate\":").append(jsonStr(b.getExpiryDate() != null ? b.getExpiryDate().toString() : "")).append(',');
                sb.append("\"initialQty\":").append(b.getInitialQuantity()).append(',');
                sb.append("\"currentQty\":").append(b.getCurrentQuantity()).append(',');
                sb.append("\"importPrice\":").append(b.getImportPrice() != null ? b.getImportPrice().toPlainString() : "0").append(',');
                sb.append("\"status\":").append(jsonStr(b.getStatus()));
                sb.append('}');
            }
            sb.append(']');
            out.print(sb);
        } catch (Exception e) {
            out.print("[]");
        }
    }

    // ── AJAX: Live stats cho polling từ medicine-list ─────────────────────────
    private void apiGetStats(HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-cache");
        PrintWriter out = resp.getWriter();
        try {
            Map<Integer, Integer> stockMap        = batchesDAO.getTotalQuantityMap();
            Map<Integer, Integer> expiringSoonMap = new HashMap<>();
            Map<Integer, Integer> expiredMap      = new HashMap<>();
            batchesDAO.loadBatchSummary(new HashMap<>(), expiringSoonMap, expiredMap, new HashMap<>());
            int total        = medicineDAO.countAll();
            int lowStock     = medicineDAO.countLowStock();
            int expiringSoon = (int) expiringSoonMap.values().stream().filter(v -> v > 0).count();
            int expired      = (int) expiredMap.values().stream().filter(v -> v > 0).count();
            String ts = java.time.LocalTime.now().format(java.time.format.DateTimeFormatter.ofPattern("HH:mm"));
            out.printf("{\"total\":%d,\"lowStock\":%d,\"expiringSoon\":%d,\"expired\":%d,\"ts\":\"%s\"}",
                    total, lowStock, expiringSoon, expired, ts);
        } catch (Exception e) {
            out.print("{\"total\":0,\"lowStock\":0,\"expiringSoon\":0,\"expired\":0,\"ts\":\"\"}");
        }
    }

    // ── AJAX: Map tồn kho tất cả thuốc {medId: stock} ────────────────────────
    private void apiGetStockMap(HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-cache");
        PrintWriter out = resp.getWriter();
        try {
            Map<Integer, Integer> stockMap = batchesDAO.getTotalQuantityMap();
            StringBuilder sb = new StringBuilder("{");
            boolean first = true;
            for (Map.Entry<Integer, Integer> e : stockMap.entrySet()) {
                if (!first) sb.append(',');
                sb.append('"').append(e.getKey()).append("\":").append(e.getValue() != null ? e.getValue() : 0);
                first = false;
            }
            sb.append('}');
            out.print(sb);
        } catch (Exception e) {
            out.print("{}");
        }
    }

    // ── AJAX: Tạo danh mục mới inline
    // ──────────────────────────────────────────────────────
    private void createCategoryAjax(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        try {
            String name = req.getParameter("categoryName");
            String desc = req.getParameter("description");
            if (name == null || name.trim().isEmpty()) {
                out.print("{\"ok\":false,\"error\":\"Tên danh mục không được để trống!\"}");
                return;
            }
            Category cat = new Category();
            cat.setCategoryName(name.trim());
            cat.setDescription(desc != null ? desc.trim() : "");
            int newId = categoryDAO.insertGetId(cat);
            if (newId > 0) {
                try {
                    AuditHelper.log(req, "Tạo danh mục thuốc", "Category", "Thêm danh mục: " + name.trim());
                } catch (Exception ignored) {
                }
                out.print(
                        "{\"ok\":true,\"id\":" + newId + ",\"name\":\"" + name.trim().replace("\"", "&quot;") + "\"}");
            } else {
                out.print("{\"ok\":false,\"error\":\"Lỗi khi lưu danh mục, vui lòng thử lại!\"}");
            }
        } catch (Throwable e) {
            e.printStackTrace();
            out.print("{\"ok\":false,\"error\":\"Lỗi kết nối cơ sở dữ liệu: " + e.getClass().getSimpleName() + "\"}");
        }
    }

    // ── AJAX: Tạo nhà sản xuất mới inline
    // ──────────────────────────────────────────────
    private void createManufacturerAjax(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        try {
            String name = req.getParameter("name");
            String country = req.getParameter("country");
            String contact = req.getParameter("contactInfo");
            if (name == null || name.trim().isEmpty()) {
                out.print("{\"ok\":false,\"error\":\"Tên nhà sản xuất không được để trống!\"}");
                return;
            }
            Manufacturer mfr = new Manufacturer();
            mfr.setName(name.trim());
            mfr.setCountry(country != null ? country.trim() : "");
            mfr.setAddress(contact != null ? contact.trim() : "");
            int newId = manufacturerDAO.insertGetId(mfr);
            if (newId > 0) {
                try {
                    AuditHelper.log(req, "Tạo nhà sản xuất", "Manufacturer", "Thêm NSX: " + name.trim());
                } catch (Exception ignored) {
                }
                out.print(
                        "{\"ok\":true,\"id\":" + newId + ",\"name\":\"" + name.trim().replace("\"", "&quot;") + "\"}");
            } else {
                out.print("{\"ok\":false,\"error\":\"Lỗi khi lưu nhà sản xuất, vui lòng thử lại!\"}");
            }
        } catch (Throwable e) {
            e.printStackTrace();
            out.print("{\"ok\":false,\"error\":\"Lỗi kết nối cơ sở dữ liệu: " + e.getClass().getSimpleName() + "\"}");
        }
    }

    private void deleteManufacturerAjax(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        try {
            int id = Integer.parseInt(req.getParameter("id"));
            boolean ok = manufacturerDAO.delete(id);
            if (ok) {
                try { AuditHelper.log(req, "Xóa nhà sản xuất", "Manufacturer", "Xóa NSX ID=" + id); } catch (Exception ignored) {}
                out.print("{\"ok\":true}");
            } else {
                out.print("{\"ok\":false,\"error\":\"Không thể xóa — NSX này đang được dùng bởi một hoặc nhiều thuốc!\"}");
            }
        } catch (Exception e) {
            out.print("{\"ok\":false,\"error\":\"" + e.getMessage() + "\"}");
        }
    }

    private void createPoAjax(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        try {
            HttpSession session = req.getSession(false);
            Account adminAcc = session != null ? (Account) session.getAttribute("adminAccount") : null;
            if (adminAcc == null) { out.print("{\"ok\":false,\"error\":\"Chưa đăng nhập!\"}"); return; }
            String supId = req.getParameter("supplierId");
            String notes = req.getParameter("notes");
            if (supId == null || supId.isBlank()) { out.print("{\"ok\":false,\"error\":\"Vui lòng chọn nhà cung cấp!\"}"); return; }
            PurchaseOrders po = new PurchaseOrders();
            po.setSupplierId(Integer.parseInt(supId));
            po.setAccountId(adminAcc.getAccountId());
            po.setNotes(notes != null ? notes.trim() : null);
            int poId = poDAO.insert(po);
            if (poId > 0) {
                try { AuditHelper.log(req, "Tạo đơn đặt hàng", "PurchaseOrder", poId, "Tạo đơn từ kho thuốc, NCC ID=" + supId); } catch (Exception ignored) {}
                out.print("{\"ok\":true,\"poId\":" + poId + "}");
            } else {
                out.print("{\"ok\":false,\"error\":\"Lỗi tạo đơn đặt hàng, thử lại!\"}");
            }
        } catch (Exception e) {
            out.print("{\"ok\":false,\"error\":\"" + e.getMessage() + "\"}");
        }
    }
}