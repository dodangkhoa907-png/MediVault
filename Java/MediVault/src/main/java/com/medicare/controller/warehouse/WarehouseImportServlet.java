package com.medicare.controller.warehouse;

import com.medicare.dao.AccountDAO;
import com.medicare.dao.BatchesDAO;
import com.medicare.dao.MedicineDAO;
import com.medicare.dao.SupplierDAO;
import com.medicare.dao.PurchaseOrderDAO;
import com.medicare.entity.Account;
import com.medicare.entity.Batches;
import com.medicare.entity.Medicines;
import com.medicare.entity.Supplier;
import com.medicare.entity.PurchaseOrders;
import com.medicare.util.SidebarHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@WebServlet("/warehouse-import")
public class WarehouseImportServlet extends HttpServlet {

    private static final int ROLE_WAREHOUSE = 3;

    private final BatchesDAO batchesDAO = new BatchesDAO();
    private final MedicineDAO medicineDAO = new MedicineDAO();
    private final SupplierDAO supplierDAO = new SupplierDAO();
    private final PurchaseOrderDAO poDAO = new PurchaseOrderDAO();
    private final AccountDAO accountDAO = new AccountDAO();

    private static final java.time.format.DateTimeFormatter DATE_TIME_VN =
            java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    /** Danh tinh Thu kho lay tu SESSION (WarehouseAuth) — khong con doc ?uid= tren URL. */
    private Account requireWarehouseStaff(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        return com.medicare.util.WarehouseAuth.require(req, resp);
    }

    private final com.medicare.util.BarcodeService barcodeService = new com.medicare.util.BarcodeService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Account acc = requireWarehouseStaff(req, resp);
        if (acc == null) return;

        // ── Barcode redesign (Phần 1) — tra cứu AJAX, không render lại trang ──
        if ("lookup-barcode".equals(req.getParameter("action"))) {
            apiLookupBarcode(req, resp);
            return;
        }

        String uid = String.valueOf(acc.getAccountId());   // tu SESSION, khong tu URL

        // findAllWithStock (không phải findAll): wizard nhập kho cần tồn hiện tại và
        // ngưỡng tối thiểu để xem trước "tồn sau khi nhập" ngay tại bước xác nhận —
        // thủ kho thấy được hệ quả trước khi bấm, thay vì nhập xong mới đi kiểm tra.
        List<Medicines> medicines = ((MedicineDAO) medicineDAO).findAllWithStock();
        List<Supplier> suppliers = supplierDAO.findAll();
        List<PurchaseOrders> pos = poDAO.findAll();

        // Gợi ý "giá nhập / số lô lần gần nhất" theo từng thuốc — chỉ để hiển thị tham khảo
        // ngay cạnh ô nhập, KHÔNG tự điền: giá và số lô vẫn phải gõ tay theo đúng phiếu/hộp
        // thật đang cầm trên tay.
        Map<Integer, Batches> latestByMedicine = batchesDAO.getLatestBatchMap();

        req.setAttribute("staffUid", uid);
        req.setAttribute("staffAcc", acc);
        req.setAttribute("medicines", medicines);
        req.setAttribute("suppliers", suppliers);
        req.setAttribute("pos", pos);
        req.setAttribute("latestByMedicine", latestByMedicine);
        req.setAttribute("recentImports", loadRecentImports());
        // Danh sách ưu tiên ngay trong ô chọn Thuốc — thay vì bắt thủ kho nhớ/mở riêng trang
        // Gợi ý đặt hàng rồi quay lại đây gõ tên tay. 3 tầng, tầng cao nhất trước:
        //  1) "Có lô hết hạn" — medicine đang có ít nhất 1 lô ExpiryDate < hôm nay mà vẫn còn
        //     tồn (CurrentQuantity > 0, Status='ACTIVE') — TẦNG ƯU TIÊN CAO NHẤT: lô đó sắp
        //     phải xuất huỷ (xem warehouse-inventory.jsp), thuốc phải nhập bù NGAY kẻo đứt hàng,
        //     dù tổng tồn (gộp cả lô hết hạn) trông có vẻ vẫn "đủ" nên 2 tầng dưới có thể bỏ sót.
        //  2) "Cần nhập gấp" — đã có phiếu đề xuất PENDING do ReorderAlertService tự sinh, đã
        //     qua đúng công thức điểm đặt hàng lại (ROP).
        //  3) "Sắp hết" — tồn <= ngưỡng tối thiểu nhưng job giờ chưa kịp quét tới, tính thẳng ở
        //     client từ data-stock/data-min có sẵn trên mỗi option, không cần query thêm.
        req.setAttribute("urgentMedicineIds", findUrgentReorderMedicineIds());
        req.setAttribute("expiredMedicineIds", findExpiredMedicineIds());
        // Đi thẳng từ nút giỏ hàng "Gợi ý đặt hàng" ở Tồn kho / cảnh báo hạn dùng — trước đây
        // nút đó chỉ đưa tới /warehouse-reorder để XEM gợi ý, không tới được chỗ thao tác thật
        // (nhập kho). Nay truyền medicineId qua để JS pre-select sẵn đúng thuốc ở Bước 1.
        req.setAttribute("preSelectMedicineId", req.getParameter("medicineId"));

        // Barcode redesign (Phần 1) — Category/Manufacturer cho form "Tạo nhanh thuốc" trong
        // wizard "Phát hiện mã vạch mới" (Option B), tránh thủ kho phải rời trang.
        req.setAttribute("bcCategories", new com.medicare.dao.CategoryDAO().findAll());
        req.setAttribute("bcManufacturers", new com.medicare.dao.ManufacturerDAO().findAll());

        // Define activeNav for sidebar
        req.setAttribute("activeNav", "inventory");

        // 2 badge sidebar — SidebarHelper.load() cũ chỉ set expiryCount, thiếu myOpenTaskCount
        // nên badge "Nhiệm vụ & SOP" biến mất đúng lúc thủ kho đang ở trang Nhập kho.
        SidebarHelper.loadWarehouse(req, acc.getAccountId());

        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-import.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        Account acc = requireWarehouseStaff(req, resp);
        if (acc == null) return;

        // ── Barcode redesign (Phần 1) — wizard "Phát hiện mã vạch mới": trả JSON, không
        // redirect/render lại trang (đúng yêu cầu "NO page reload"). ──
        String action = req.getParameter("action");
        if ("quick-create-medicine".equals(action)) { handleQuickCreateMedicine(req, resp, acc); return; }
        if ("bind-barcode".equals(action))          { handleBindBarcode(req, resp, acc); return; }

        String uid = String.valueOf(acc.getAccountId());   // tu SESSION, khong tu URL

        try {
            int medicineId = Integer.parseInt(req.getParameter("medicineId"));
            int supplierId = Integer.parseInt(req.getParameter("supplierId"));
            int poId = 0;
            String poIdStr = req.getParameter("poId");
            if (poIdStr != null && !poIdStr.trim().isEmpty()) {
                poId = Integer.parseInt(poIdStr);
            }

            String batchNumber = req.getParameter("batchNumber");
            LocalDate manufactureDate = LocalDate.parse(req.getParameter("manufactureDate"));
            LocalDate expiryDate = LocalDate.parse(req.getParameter("expiryDate"));
            LocalDate importDate = LocalDate.parse(req.getParameter("importDate"));
            BigDecimal importPrice = new BigDecimal(req.getParameter("importPrice"));
            int quantity = Integer.parseInt(req.getParameter("quantity"));

            // Chặn cứng dữ liệu KHÔNG THỂ có thật, không phải chuyện "rủi ro nghiệp vụ" như lô
            // sắp hết hạn (cái đó JS chỉ cảnh báo mềm ở bước 3, vẫn cho ghi). Đây là bất khả thi
            // vật lý — không có lý do nghiệp vụ nào hợp thức hoá được, nên chặn ở tầng server
            // dù JS đã chặn từ trước, phòng khi JS bị tắt hoặc bị qua mặt.
            if (!expiryDate.isAfter(manufactureDate)) {
                resp.sendRedirect(req.getContextPath() + "/warehouse-import?msg=import-error");
                return;
            }
            if (importDate.isBefore(manufactureDate)) {
                resp.sendRedirect(req.getContextPath() + "/warehouse-import?msg=import-error");
                return;
            }
            // HSD đã trôi qua quá khứ = lô ĐÃ HẾT HẠN — khác NSX (NSX ở quá khứ là bình thường,
            // thuốc nào cũng sản xuất trước khi nhập). Không có lý do nghiệp vụ nào để NHẬP KHO
            // MỚI một lô đã hết hạn, nên chặn cứng ở đây luôn, không chỉ cảnh báo mềm như trước.
            if (!expiryDate.isAfter(LocalDate.now())) {
                resp.sendRedirect(req.getContextPath() + "/warehouse-import?msg=import-error");
                return;
            }

            Batches batch = new Batches();
            batch.setMedicineId(medicineId);
            batch.setSupplierId(supplierId);
            batch.setBatchNumber(batchNumber);
            batch.setManufactureDate(manufactureDate);
            batch.setExpiryDate(expiryDate);
            batch.setImportDate(importDate);
            batch.setImportPrice(importPrice);
            batch.setInitialQuantity(quantity);
            batch.setCurrentQuantity(quantity);
            batch.setCreatedAt(LocalDateTime.now());

            boolean ok;
            if (poId > 0) {
                // Đã chọn PO có sẵn — gắn lô vào đúng PO đó, insert thẳng như cũ (nhánh này
                // vốn đã đúng, KHÔNG phải nguồn gây lỗi).
                batch.setPoId(poId);
                ok = batchesDAO.insert(batch);
            } else {
                // BUG THẬT Ở ĐÂY (đã fix): không chọn PO thì Batches.poId để nguyên giá trị
                // mặc định 0 của kiểu int — POID là khoá ngoại tới PurchaseOrders, không có
                // đơn nào mang id 0, nên INSERT luôn vi phạm FK. BatchesDAO.insert() lại tự
                // bắt Exception rồi trả về false thay vì ném lên, và dòng gọi trước đây
                // "batchesDAO.insert(batch);" bỏ luôn giá trị trả về — nên request vẫn redirect
                // sang trang "thành công" trong khi KHÔNG có dòng nào được ghi vào DB.
                //
                // Cách sửa: thủ kho đang ghi nhận hàng ĐÃ VỀ TAY ngay lúc này (khác với Admin
                // "đặt hàng cho tương lai"), nên tự tạo 1 Phiếu nhập (PurchaseOrders) trạng thái
                // COMPLETED để có POID hợp lệ — dùng lại đúng PurchaseOrderDAO.createWithBatches()
                // mà MedicineService (nhập kho bên Admin) đang dùng, không viết luồng insert mới.
                // Lợi ích phụ: phiếu này hiện thẳng trong "Đơn đặt hàng" của Admin, có lịch sử
                // đầy đủ thay vì trôi mất không dấu vết.
                PurchaseOrders po = new PurchaseOrders();
                po.setSupplierId(supplierId);
                po.setAccountId(acc.getAccountId());
                po.setStatus("COMPLETED");
                po.setNotes("Nhập nhanh bởi Thủ kho — " + acc.getFullName());
                po.setTotalValue(importPrice.multiply(BigDecimal.valueOf(quantity)));
                int newPoId = poDAO.createWithBatches(po, List.of(batch));
                ok = newPoId > 0;
            }

            if (!ok) {
                resp.sendRedirect(req.getContextPath() + "/warehouse-import?msg=import-error");
                return;
            }

            resp.sendRedirect(req.getContextPath() + "/warehouse-import?msg=success");
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/warehouse-import?msg=import-error");
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  BARCODE REDESIGN (Phần 1) — tra cứu / tạo nhanh / bind mã vạch, AJAX JSON
    // ══════════════════════════════════════════════════════════════════════

    /** action=lookup-barcode&barcode=...&source=camera|usb|manual — GET, gọi mỗi lần quét.
     *  Khớp → JSON {"ok":true,"found":true,"medicine":{...}}. Không khớp → {"ok":true,"found":false}
     *  ("mã vạch mới", KHÔNG phải lỗi — đúng tinh thần "Never interrupt the workflow"). */
    private void apiLookupBarcode(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        String barcode = req.getParameter("barcode");
        String source  = normSource(req.getParameter("source"));
        Medicines m = barcodeService.lookup(barcode, source);
        PrintWriter out = resp.getWriter();
        if (m != null) {
            out.print("{\"ok\":true,\"found\":true,\"medicine\":" + com.medicare.util.BarcodeService.medicineJson(m) + "}");
        } else {
            out.print("{\"ok\":true,\"found\":false}");
        }
    }

    /** action=quick-create-medicine — POST, Option B của wizard "Phát hiện mã vạch mới":
     *  tạo thuốc hoàn toàn mới ngay tại chỗ, mã vừa quét trở thành Barcode chính. Trả về
     *  thuốc mới để JS chọn thẳng vào Bước 1 mà KHÔNG reload trang. */
    private void handleQuickCreateMedicine(HttpServletRequest req, HttpServletResponse resp, Account acc) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        try {
            String name = req.getParameter("name");
            String barcode = req.getParameter("barcode");
            String unit = req.getParameter("unit");
            if (name == null || name.trim().length() < 2) { out.print("{\"ok\":false,\"reason\":\"invalid_name\"}"); return; }
            if (barcode == null || barcode.trim().isEmpty()) { out.print("{\"ok\":false,\"reason\":\"invalid_barcode\"}"); return; }
            if (unit == null || unit.trim().isEmpty()) { out.print("{\"ok\":false,\"reason\":\"invalid_unit\"}"); return; }
            Integer categoryId = parseIntOrNull(req.getParameter("categoryId"));
            Integer manufacturerId = parseIntOrNull(req.getParameter("manufacturerId"));
            if (categoryId == null) { out.print("{\"ok\":false,\"reason\":\"invalid_category\"}"); return; }
            if (manufacturerId == null) { out.print("{\"ok\":false,\"reason\":\"invalid_manufacturer\"}"); return; }

            BigDecimal price;
            try { price = new BigDecimal(req.getParameter("sellingPrice")); }
            catch (Exception e) { price = BigDecimal.ZERO; }

            Medicines created = barcodeService.quickCreate(
                    name.trim(), req.getParameter("genericName"), barcode.trim(),
                    categoryId, manufacturerId, unit.trim(), price,
                    "on".equals(req.getParameter("prescriptionRequired")) || "true".equals(req.getParameter("prescriptionRequired")),
                    req.getParameter("storageConditions"), acc.getAccountId(), normSource(req.getParameter("source")));

            if (created == null) { out.print("{\"ok\":false,\"reason\":\"conflict_or_db_error\"}"); return; }

            com.medicare.util.AuditHelper.log(req, "Tạo nhanh thuốc từ quét mã vạch", "Medicine",
                    created.getMedicineId(), "Mã vạch " + barcode.trim() + " — " + created.getMedicineName());

            out.print("{\"ok\":true,\"medicine\":" + com.medicare.util.BarcodeService.medicineJson(created) + "}");
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"ok\":false,\"reason\":\"server_error\"}");
        }
    }

    /** action=bind-barcode — POST, Option A của wizard: gán mã vạch vừa quét vào 1 thuốc ĐÃ CÓ
     *  (thủ kho tự tìm/chọn thuốc). */
    private void handleBindBarcode(HttpServletRequest req, HttpServletResponse resp, Account acc) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        try {
            Integer medicineId = parseIntOrNull(req.getParameter("medicineId"));
            String barcode = req.getParameter("barcode");
            if (medicineId == null) { out.print("{\"ok\":false,\"reason\":\"invalid_medicine\"}"); return; }
            if (barcode == null || barcode.trim().isEmpty()) { out.print("{\"ok\":false,\"reason\":\"invalid_barcode\"}"); return; }

            boolean ok = barcodeService.bindToExisting(medicineId, barcode.trim(), acc.getAccountId(), normSource(req.getParameter("source")));
            if (!ok) { out.print("{\"ok\":false,\"reason\":\"conflict_or_db_error\"}"); return; }

            Medicines m = medicineDAO.findById(medicineId);
            com.medicare.util.AuditHelper.log(req, "Gán mã vạch", "Medicine", medicineId,
                    "Gán mã vạch " + barcode.trim() + " vào thuốc " + (m != null ? m.getMedicineName() : "#" + medicineId));

            out.print("{\"ok\":true,\"medicine\":" + com.medicare.util.BarcodeService.medicineJson(m) + "}");
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"ok\":false,\"reason\":\"server_error\"}");
        }
    }

    private String normSource(String s) {
        if ("camera".equals(s) || "usb".equals(s) || "manual".equals(s)) return s;
        return "manual";
    }

    private Integer parseIntOrNull(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (NumberFormatException e) { return null; }
    }

    /**
     * 20 phiếu nhập gần nhất — cùng dữ liệu Admin thấy ở "Đơn đặt hàng" (PurchaseOrderDAO),
     * dựng lại đúng pattern PurchaseOrderServlet.showList() để thủ kho xem lại lô mình vừa
     * nhập ngay tại trang Nhập kho, không phải hỏi Admin hay đoán xem có ghi vào DB hay chưa.
     */
    /**
     * ID các thuốc đang có phiếu đề xuất đặt hàng PENDING do {@code ReorderAlertService}
     * tự sinh (cùng điều kiện lọc với {@code WarehouseReorderServlet.findPendingSuggestions()}
     * — Notes bắt đầu bằng đúng tiền tố hệ thống, tránh lẫn PO Admin tự tạo tay). Đây là tín
     * hiệu ưu tiên MẠNH NHẤT: đã qua đúng công thức điểm đặt hàng lại (ROP), không phải suy
     * đoán tồn/ngưỡng đơn thuần.
     */
    private Set<Integer> findUrgentReorderMedicineIds() {
        Set<Integer> ids = new HashSet<>();
        String sql = "SELECT DISTINCT d.MedicineID FROM PurchaseOrders po " +
                "JOIN PurchaseOrderDetails d ON d.POID = po.POID " +
                "WHERE po.Status = 'PENDING' AND po.Notes LIKE N'Tự động đề xuất bởi hệ thống%'";
        try (Connection cn = com.medicare.config.DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) ids.add(rs.getInt("MedicineID"));
        } catch (Exception e) {
            e.printStackTrace();
        }
        return ids;
    }

    /**
     * ID các thuốc đang có ít nhất 1 lô ĐÃ HẾT HẠN mà vẫn còn tồn trong kho — tái dùng thẳng
     * {@link BatchesDAO#findExpired()} (đúng nguồn dữ liệu với bảng "Quá hạn" bên Tồn kho),
     * không viết SQL riêng.
     */
    private Set<Integer> findExpiredMedicineIds() {
        Set<Integer> ids = new HashSet<>();
        for (Batches b : batchesDAO.findExpired()) ids.add(b.getMedicineId());
        return ids;
    }

    private List<Map<String, Object>> loadRecentImports() {
        List<Map<String, Object>> rows = new java.util.ArrayList<>();
        for (PurchaseOrders po : poDAO.findRecent(20)) {
            Map<String, Object> row = new HashMap<>();
            Supplier sup = supplierDAO.findById(po.getSupplierId());
            Account by = accountDAO.findById(po.getAccountId());
            row.put("po", po);
            row.put("supplierName", sup != null ? sup.getSupplierName() : "—");
            row.put("byName", by != null ? by.getFullName() : "—");
            row.put("batchCount", poDAO.countBatches(po.getPoId()));
            // Ngày giờ format SẴN ở đây, không để JSP tự lo: <fmt:formatDate> của JSTL chỉ
            // nhận java.util.Date/Calendar, đưa LocalDateTime vào là ném exception giữa lúc
            // render → response đứt ngang (500) và phần <script> cuối trang không kịp gửi,
            // khiến các combo box "biến mất" trên màn hình. Đây chính là lỗi đã xảy ra.
            row.put("whenText", po.getOrderDate() != null
                    ? po.getOrderDate().format(DATE_TIME_VN) : "—");
            rows.add(row);
        }
        return rows;
    }
}
