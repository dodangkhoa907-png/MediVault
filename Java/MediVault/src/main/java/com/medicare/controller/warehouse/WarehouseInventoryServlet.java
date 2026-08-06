package com.medicare.controller.warehouse;

import com.medicare.config.CacheManager;
import com.medicare.dao.BatchesDAO;
import com.medicare.dao.CategoryDAO;
import com.medicare.dao.ManufacturerDAO;
import com.medicare.dao.MedicineDAO;
import com.medicare.dao.ShelfDAO;
import com.medicare.dao.interfaces.IBatchesDAO;
import com.medicare.dao.interfaces.IMedicineDAO;
import com.medicare.entity.Account;
import com.medicare.entity.Batches;
import com.medicare.entity.Medicines;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * WarehouseInventoryServlet — Quản lý tồn kho chuyên sâu cho Quản lý kho (roleId 3 = Thủ kho).
 * URL: /warehouse-inventory&amp;q=&lt;keyword&gt;
 *
 * <p>Đây là bản "mở rộng" của trang thuốc bên admin dành riêng cho thủ kho: danh sách
 * thuốc kèm tồn kho thực tế (SUM CurrentQuantity theo lô), HSD gần nhất, trạng thái
 * sắp hết hàng, cùng 2 bảng chuyên sâu Lô cận hạn / Lô đã hết hạn.</p>
 */
@WebServlet("/warehouse-inventory")
public class WarehouseInventoryServlet extends HttpServlet {

    private static final int ROLE_WAREHOUSE = 3;

    private final IMedicineDAO medicineDAO   = new MedicineDAO();
    private final IBatchesDAO  batchesDAO    = new BatchesDAO();
    private final CategoryDAO     categoryDAO     = new CategoryDAO();
    private final ManufacturerDAO manufacturerDAO = new ManufacturerDAO();
    private final ShelfDAO        shelfDAO        = new ShelfDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        Account acc = com.medicare.util.WarehouseAuth.require(req, resp);
        if (acc == null) return;

        // ── AJAX: chi tiết đầy đủ 1 thuốc + toàn bộ lô (modal "👁️ Xem chi tiết" trên bảng) ──
        if ("detail".equals(req.getParameter("action"))) {
            apiGetDetail(req, resp);
            return;
        }

        String q = req.getParameter("q");
        boolean hasKeyword = q != null && !q.trim().isEmpty();

        // Danh sách đầy đủ (cache 30s) — dùng làm map tên thuốc + danh sách mặc định
        MedicineDAO mdao = (MedicineDAO) medicineDAO;
        List<Medicines> allMeds = CacheManager.getShort("wh.allMedsStock", mdao::findAllWithStock);

        List<Medicines> displayMeds = new java.util.ArrayList<>(hasKeyword ? mdao.searchWithStock(q.trim()) : allMeds);

        // Sắp xếp mặc định FEFO (Hạn dùng gần nhất -> Trạng thái ưu tiên -> Tên thuốc)
        displayMeds.sort((m1, m2) -> {
            String exp1 = m1.getNearestExpiry() != null && !m1.getNearestExpiry().isEmpty() ? m1.getNearestExpiry() : "9999-12-31";
            String exp2 = m2.getNearestExpiry() != null && !m2.getNearestExpiry().isEmpty() ? m2.getNearestExpiry() : "9999-12-31";
            int cExp = exp1.compareTo(exp2);
            if (cExp != 0) return cExp;

            int st1 = m1.getTotalStock() == 0 ? 1 : (m1.getMinInventory() > 0 && m1.getTotalStock() <= m1.getMinInventory() ? 2 : 3);
            int st2 = m2.getTotalStock() == 0 ? 1 : (m2.getMinInventory() > 0 && m2.getTotalStock() <= m2.getMinInventory() ? 2 : 3);
            int cSt = Integer.compare(st1, st2);
            if (cSt != 0) return cSt;

            return m1.getMedicineName().compareToIgnoreCase(m2.getMedicineName());
        });

        // Map medicineId → tên thuốc (để hiển thị tên trong bảng lô cận/hết hạn)
        Map<Integer, String> medNameMap = new HashMap<>();
        for (Medicines m : allMeds) medNameMap.put(m.getMedicineId(), m.getMedicineName());

        // Map categoryId → tên danh mục. Bảng tồn kho có cột "Danh mục" để thủ kho quét/lọc
        // theo nhóm hàng, nhưng Medicines chỉ mang CategoryID — nên nạp bảng danh mục 1 lần
        // (cache 15 phút, dữ liệu gần như tĩnh) rồi tra cứu tại JSP thay vì join thêm.
        Map<Integer, String> catNameMap = CacheManager.get15("wh.catNameMap", () -> {
            Map<Integer, String> map = new HashMap<>();
            categoryDAO.findAll().forEach(c -> map.put(c.getCategoryId(), c.getCategoryName()));
            return map;
        });

        // Thống kê nhanh (tính từ allMeds để nhất quán với dữ liệu đang hiển thị)
        int lowStock = 0;
        for (Medicines m : allMeds) {
            if (m.getMinInventory() > 0 && m.getTotalStock() <= m.getMinInventory()) lowStock++;
        }
        List<Batches> expiringBatches = CacheManager.getShort("wh.expiringBatches", batchesDAO::findExpiringSoon);
        List<Batches> expiredBatches  = CacheManager.getShort("wh.expiredBatches",  batchesDAO::findExpired);

        req.setAttribute("staffAcc",   acc);
        req.setAttribute("keyword",    hasKeyword ? q.trim() : "");
        req.setAttribute("medicines",  displayMeds);
        req.setAttribute("medNameMap", medNameMap);
        req.setAttribute("catNameMap", catNameMap);
        req.setAttribute("totalActive",     allMeds.size());
        req.setAttribute("lowStockCount",   lowStock);
        req.setAttribute("expiringBatches", expiringBatches);
        req.setAttribute("expiredBatches",  expiredBatches);
        // 2 badge sidebar (expiryCount + myOpenTaskCount) — trước đây trang này chỉ tự set
        // expiryCount nên badge "Nhiệm vụ & SOP" biến mất khi đứng ở trang Tồn kho.
        com.medicare.util.SidebarHelper.loadWarehouse(req, acc.getAccountId());

        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-inventory.jsp")
                .forward(req, resp);
    }

    // ── AJAX: toàn bộ thông tin sản phẩm + toàn bộ lô (kể cả hết hàng/hết hạn) cho modal
    // "👁️ Xem chi tiết" — thủ kho cần thấy hết mọi lô đang có, không chỉ lô FEFO gần nhất
    // (khác với warehouse-stock-movement chỉ gợi ý 1 lô để xuất/điều chỉnh). ──
    private void apiGetDetail(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        PrintWriter out = resp.getWriter();
        try {
            int id = Integer.parseInt(req.getParameter("id"));
            Medicines m = medicineDAO.findById(id);
            if (m == null) { out.print("{\"error\":\"not found\"}"); return; }

            String catName = "", mfrName = "", shelfName = "";
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

            List<Batches> batches = batchesDAO.findAllByMedicine(id); // kể cả hết hàng/hết hạn
            // findById() ở trên là SELECT * thường, KHÔNG join tồn kho — m.getTotalStock() sẽ luôn
            // là 0 nếu dùng trực tiếp. Phải lấy qua getTotalQuantityMap() (cùng nguồn dữ liệu với
            // bảng danh sách) để số ở modal khớp đúng số cột "Tồn kho" thủ kho vừa nhìn thấy.
            int totalStock = batchesDAO.getTotalQuantityMap().getOrDefault(id, 0);

            StringBuilder sb = new StringBuilder("{");
            sb.append("\"medicine\":{");
            sb.append("\"id\":").append(m.getMedicineId()).append(',');
            sb.append("\"medicineCode\":").append(jsonStr(m.getMedicineCode())).append(',');
            sb.append("\"medicineName\":").append(jsonStr(m.getMedicineName())).append(',');
            sb.append("\"genericName\":").append(jsonStr(m.getGenericName())).append(',');
            sb.append("\"barcode\":").append(jsonStr(m.getBarcode())).append(',');
            sb.append("\"registrationNumber\":").append(jsonStr(m.getRegistrationNumber())).append(',');
            sb.append("\"unit\":").append(jsonStr(m.getUnit())).append(',');
            sb.append("\"categoryName\":").append(jsonStr(catName)).append(',');
            sb.append("\"manufacturerName\":").append(jsonStr(mfrName)).append(',');
            sb.append("\"shelfName\":").append(jsonStr(shelfName)).append(',');
            sb.append("\"sellingPrice\":").append(m.getSellingPrice() != null ? m.getSellingPrice().toPlainString() : "0").append(',');
            sb.append("\"minInventory\":").append(m.getMinInventory()).append(',');
            sb.append("\"totalStock\":").append(totalStock).append(',');
            sb.append("\"isPrescriptionRequired\":").append(m.isPrescriptionRequired()).append(',');
            sb.append("\"dosage\":").append(jsonStr(m.getDosage())).append(',');
            sb.append("\"dosageWarning\":").append(jsonStr(m.getDosageWarning())).append(',');
            sb.append("\"contraindications\":").append(jsonStr(m.getContraindications())).append(',');
            sb.append("\"storageConditions\":").append(jsonStr(m.getStorageConditions())).append(',');
            sb.append("\"packagingSpec\":").append(jsonStr(m.getPackagingSpec()));
            sb.append("},\"batches\":[");
            for (int i = 0; i < batches.size(); i++) {
                Batches b = batches.get(i);
                if (i > 0) sb.append(',');
                sb.append('{');
                sb.append("\"batchNumber\":").append(jsonStr(b.getBatchNumber())).append(',');
                sb.append("\"expiryDate\":").append(jsonStr(b.getExpiryDate() != null ? b.getExpiryDate().toString() : "")).append(',');
                sb.append("\"importDate\":").append(jsonStr(b.getImportDate() != null ? b.getImportDate().toString() : "")).append(',');
                sb.append("\"currentQuantity\":").append(b.getCurrentQuantity()).append(',');
                sb.append("\"initialQuantity\":").append(b.getInitialQuantity()).append(',');
                sb.append("\"status\":").append(jsonStr(b.getStatus()));
                sb.append('}');
            }
            sb.append("]}");
            out.print(sb);
        } catch (Exception e) {
            out.print("{\"error\":\"" + e.getMessage() + "\"}");
        }
    }

    private static String jsonStr(String s) {
        if (s == null) return "\"\"";
        return "\"" + s.replace("\\","\\\\").replace("\"","\\\"")
                       .replace("\n","\\n").replace("\r","\\r").replace("\t","\\t") + "\"";
    }
}
