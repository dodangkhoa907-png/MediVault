package com.medicare.controller.warehouse;

import com.medicare.config.CacheManager;
import com.medicare.config.DBContext;
import com.medicare.dao.*;
import com.medicare.dao.interfaces.*;
import com.medicare.entity.Account;
import com.medicare.entity.Batches;
import com.medicare.entity.Medicines;
import com.medicare.entity.Shelf;
import com.medicare.entity.StockMovements;
import com.medicare.util.SidebarHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.*;

/**
 * WarehouseInventoryServlet — Trung tâm Quản lý tồn kho đa tab cho Quản lý kho (roleId 3 = Thủ kho).
 * URL: /warehouse-inventory?uid=<id>&tab=<inventory|reorder|movement|recall>
 *
 * <p>Tích hợp 4 tab theo đúng thiết kế:</p>
 * 1. Danh mục tồn kho (mặc định)
 * 2. Gợi ý đặt hàng (ROP & Cảnh báo tồn kho đa tầng)
 * 3. Dồn chung điều chỉnh (Xuất kho & Điều chỉnh tồn FEFO)
 * 4. Thu hồi khẩn cấp (Xử lý công văn & Ngừng bán lô khẩn cấp)
 */
@WebServlet("/warehouse-inventory")
public class WarehouseInventoryServlet extends HttpServlet {

    private static final int ROLE_WAREHOUSE = 3;
    private static final String AUTO_NOTES_PREFIX = "Tự động đề xuất bởi hệ thống";
    private static final DateTimeFormatter DTF = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private final IMedicineDAO       medicineDAO       = new MedicineDAO();
    private final IBatchesDAO        batchesDAO        = new BatchesDAO();
    private final CategoryDAO           categoryDAO       = new CategoryDAO();
    private final ManufacturerDAO       manufacturerDAO   = new ManufacturerDAO();
    private final ShelfDAO              shelfDAO          = new ShelfDAO();
    private final IStockMovementsDAO stockMovementsDAO = new StockMovementsDAO();
    private final IAccountDAO        accountDAO        = new AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String uid = req.getParameter("uid");
        HttpSession session = req.getSession(false);
        Account acc = (uid != null && session != null)
                ? (Account) session.getAttribute("staffAccount_" + uid) : null;
        if (acc == null || acc.getRoleId() != ROLE_WAREHOUSE) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login");
            return;
        }

        // ── AJAX: chi tiết đầy đủ 1 thuốc + toàn bộ lô (modal "👁️ Xem chi tiết" trên bảng) ──
        if ("detail".equals(req.getParameter("action"))) {
            apiGetDetail(req, resp);
            return;
        }

        // ── AJAX: gợi ý lô hệ thống chỉ định (FEFO) khi chọn thuốc ──
        if ("suggest-batch".equals(req.getParameter("action"))) {
            apiSuggestBatch(req, resp);
            return;
        }

        String tab = req.getParameter("tab");
        if (tab == null || tab.trim().isEmpty()) {
            tab = "inventory";
        }

        loadAllData(req, acc, uid, tab);
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-inventory.jsp")
                .forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String uid = req.getParameter("uid");
        HttpSession session = req.getSession(false);
        Account acc = (uid != null && session != null)
                ? (Account) session.getAttribute("staffAccount_" + uid) : null;
        if (acc == null || acc.getRoleId() != ROLE_WAREHOUSE) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login");
            return;
        }

        String action = req.getParameter("action");
        String tab = req.getParameter("tab");
        if (tab == null || tab.isEmpty()) tab = "inventory";

        if ("recall-search".equals(action)) {
            handleRecallSearch(req);
            tab = "recall";
        }

        loadAllData(req, acc, uid, tab);
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-inventory.jsp")
                .forward(req, resp);
    }

    private void loadAllData(HttpServletRequest req, Account acc, String uid, String currentTab) {
        String q = req.getParameter("q");
        boolean hasKeyword = q != null && !q.trim().isEmpty();

        MedicineDAO mdao = (MedicineDAO) medicineDAO;
        List<Medicines> allMeds = CacheManager.getShort("wh.allMedsStock", mdao::findAllWithStock);
        List<Medicines> displayMeds = hasKeyword ? mdao.searchWithStock(q.trim()) : allMeds;

        Map<Integer, String> medNameMap = new HashMap<>();
        for (Medicines m : allMeds) medNameMap.put(m.getMedicineId(), m.getMedicineName());

        int lowStock = 0;
        for (Medicines m : allMeds) {
            if (m.getMinInventory() > 0 && m.getTotalStock() <= m.getMinInventory()) lowStock++;
        }
        List<Batches> expiringBatches = CacheManager.getShort("wh.expiringBatches", batchesDAO::findExpiringSoon);
        List<Batches> expiredBatches  = CacheManager.getShort("wh.expiredBatches",  batchesDAO::findExpired);

        // Reorder data
        List<Map<String, Object>> pendingSuggestions = CacheManager.getShort("wh.reorderPending", this::findPendingSuggestions);
        List<Map<String, Object>> tierLight = CacheManager.getShort("wh.expTierLight", () -> findExpiryTier(91, 180, "ACTIVE"));
        List<Map<String, Object>> tierRestricted = CacheManager.getShort("wh.expTierRestricted", () -> findExpiryTier(31, 90, "ACTIVE"));
        List<Map<String, Object>> tierQuarantined = CacheManager.getShort("wh.expTierQuarantined", this::findQuarantined);

        // Movement data
        List<WarehouseStockMovementServlet.MovementRow> movementRows = loadMovementRows();

        // Recall data
        List<WarehouseRecallServlet.RecallHistoryRow> recallHistory = loadRecallHistory();

        req.setAttribute("staffUid",          uid);
        req.setAttribute("staffAcc",          acc);
        req.setAttribute("currentTab",        currentTab);
        req.setAttribute("activeNav",         currentTab);
        req.setAttribute("keyword",           hasKeyword ? q.trim() : "");
        req.setAttribute("medicines",         displayMeds);
        req.setAttribute("allMedicines",      allMeds);
        req.setAttribute("medNameMap",        medNameMap);
        req.setAttribute("totalActive",        allMeds.size());
        req.setAttribute("lowStockCount",      lowStock);
        req.setAttribute("expiringBatches",    expiringBatches);
        req.setAttribute("expiredBatches",     expiredBatches);
        req.setAttribute("pendingSuggestions", pendingSuggestions);
        req.setAttribute("tierLight",          tierLight);
        req.setAttribute("tierRestricted",     tierRestricted);
        req.setAttribute("tierQuarantined",    tierQuarantined);
        req.setAttribute("movementRows",       movementRows);
        req.setAttribute("history",            recallHistory);
    }

    private void handleRecallSearch(HttpServletRequest req) {
        String medicineIdStr = req.getParameter("medicineId");
        String batchNumber   = req.getParameter("batchNumber");

        if (medicineIdStr == null || medicineIdStr.trim().isEmpty()
                || batchNumber == null || batchNumber.trim().isEmpty()) {
            req.setAttribute("error", "Vui lòng chọn thuốc và nhập số lô cần tìm.");
            return;
        }

        int medicineId;
        try {
            medicineId = Integer.parseInt(medicineIdStr.trim());
        } catch (NumberFormatException e) {
            req.setAttribute("error", "Thuốc không hợp lệ.");
            return;
        }

        Batches batch = batchesDAO.findByMedicineAndBatchNumber(medicineId, batchNumber.trim());
        if (batch == null) {
            req.setAttribute("error", "Không tìm thấy lô \"" + batchNumber.trim() + "\" của thuốc đã chọn.");
            return;
        }

        Medicines med = medicineDAO.findById(batch.getMedicineId());
        String medicineName = med != null ? med.getMedicineName() : "(không rõ)";
        String shelfName = null;
        if (med != null && med.getShelfId() != null) {
            Shelf shelf = shelfDAO.findById(med.getShelfId());
            if (shelf != null) shelfName = shelf.getShelfName();
        }

        req.setAttribute("foundBatch",   batch);
        req.setAttribute("foundMedName", medicineName);
        req.setAttribute("foundShelf",   shelfName != null ? shelfName : "Chưa gán kệ");

        if (!"ACTIVE".equalsIgnoreCase(batch.getStatus())) {
            req.setAttribute("error", "Lô này hiện không ở trạng thái ACTIVE (đang là \""
                    + batch.getStatus() + "\") — có thể đã được xử lý (thu hồi/hủy) trước đó, không cần thao tác thêm.");
        }
    }

    private void apiSuggestBatch(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        String medIdStr = req.getParameter("medicineId");
        try {
            int medId = Integer.parseInt(medIdStr);
            Batches b = batchesDAO.findNearestExpiry(medId);
            if (b == null) {
                resp.getWriter().print("{\"ok\":false,\"message\":\"Không có lô nào còn tồn kho khả dụng cho thuốc này.\"}");
            } else {
                resp.getWriter().print("{\"ok\":true,\"batchNumber\":\"" + escapeJson(b.getBatchNumber())
                        + "\",\"expiryDate\":\"" + b.getExpiryDate()
                        + "\",\"currentQuantity\":" + b.getCurrentQuantity() + "}");
            }
        } catch (NumberFormatException e) {
            resp.getWriter().print("{\"ok\":false,\"message\":\"Thuốc không hợp lệ\"}");
        }
    }

    private List<Map<String, Object>> findPendingSuggestions() {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT po.POID, po.OrderDate, po.TotalValue, s.SupplierName, " +
                "       m.MedicineName, d.Quantity " +
                "FROM PurchaseOrders po " +
                "JOIN PurchaseOrderDetails d ON d.POID = po.POID " +
                "JOIN Medicines m ON m.MedicineID = d.MedicineID " +
                "JOIN Suppliers s ON s.SupplierID = po.SupplierID " +
                "WHERE po.Status = 'PENDING' AND po.Notes LIKE ? " +
                "ORDER BY po.OrderDate DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, AUTO_NOTES_PREFIX + "%");
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    row.put("poId", rs.getInt("POID"));
                    row.put("orderDate", rs.getTimestamp("OrderDate"));
                    row.put("totalValue", rs.getBigDecimal("TotalValue"));
                    row.put("supplierName", rs.getString("SupplierName"));
                    row.put("medicineName", rs.getString("MedicineName"));
                    row.put("quantity", rs.getInt("Quantity"));
                    list.add(row);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    private List<Map<String, Object>> findExpiryTier(int fromDays, int toDays, String status) {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT b.BatchNumber, b.CurrentQuantity, b.ExpiryDate, m.MedicineName " +
                "FROM Batches b JOIN Medicines m ON m.MedicineID = b.MedicineID " +
                "WHERE b.Status = ? " +
                "AND b.ExpiryDate BETWEEN DATEADD(day, ?, GETDATE()) AND DATEADD(day, ?, GETDATE()) " +
                "ORDER BY b.ExpiryDate ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setInt(2, fromDays);
            ps.setInt(3, toDays);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapBatchRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    private List<Map<String, Object>> findQuarantined() {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT b.BatchNumber, b.CurrentQuantity, b.ExpiryDate, m.MedicineName " +
                "FROM Batches b JOIN Medicines m ON m.MedicineID = b.MedicineID " +
                "WHERE b.Status = 'QUARANTINE' " +
                "ORDER BY b.ExpiryDate ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapBatchRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    private Map<String, Object> mapBatchRow(ResultSet rs) throws java.sql.SQLException {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("batchNumber", rs.getString("BatchNumber"));
        row.put("medicineName", rs.getString("MedicineName"));
        row.put("currentQuantity", rs.getInt("CurrentQuantity"));
        row.put("expiryDate", rs.getDate("ExpiryDate"));
        return row;
    }

    private List<WarehouseStockMovementServlet.MovementRow> loadMovementRows() {
        List<StockMovements> movements = stockMovementsDAO.findByDateRange(
                LocalDate.now().minusDays(7), LocalDate.now());
        Map<Integer, Batches> batchCache = new HashMap<>();
        Map<Integer, String> medNameCache = new HashMap<>();
        Map<Integer, String> accNameCache = new HashMap<>();
        List<WarehouseStockMovementServlet.MovementRow> rows = new ArrayList<>();

        for (StockMovements m : movements) {
            Batches b = batchCache.computeIfAbsent(m.getBatchId(), batchesDAO::findById);
            String medName = "?", batchNo = "?";
            if (b != null) {
                batchNo = b.getBatchNumber();
                medName = medNameCache.computeIfAbsent(b.getMedicineId(), mid -> {
                    Medicines med = medicineDAO.findById(mid);
                    return med != null ? med.getMedicineName() : "?";
                });
            }
            String accName = "?";
            if (m.getAccountId() != null) {
                accName = accNameCache.computeIfAbsent(m.getAccountId(), aid -> {
                    Account a = accountDAO.findById(aid);
                    return a != null ? (a.getFullName() != null ? a.getFullName() : a.getUsername()) : "?";
                });
            }

            WarehouseStockMovementServlet.MovementRow row = new WarehouseStockMovementServlet.MovementRow();
            try {
                java.lang.reflect.Field f1 = row.getClass().getDeclaredField("movementId"); f1.setAccessible(true); f1.set(row, m.getMovementId());
                java.lang.reflect.Field f2 = row.getClass().getDeclaredField("medicineName"); f2.setAccessible(true); f2.set(row, medName);
                java.lang.reflect.Field f3 = row.getClass().getDeclaredField("batchNumber"); f3.setAccessible(true); f3.set(row, batchNo);
                java.lang.reflect.Field f4 = row.getClass().getDeclaredField("movementType"); f4.setAccessible(true); f4.set(row, m.getMovementType());
                java.lang.reflect.Field f5 = row.getClass().getDeclaredField("quantity"); f5.setAccessible(true); f5.set(row, m.getQuantity());
                java.lang.reflect.Field f6 = row.getClass().getDeclaredField("notes"); f6.setAccessible(true); f6.set(row, m.getNotes());
                java.lang.reflect.Field f7 = row.getClass().getDeclaredField("accountName"); f7.setAccessible(true); f7.set(row, accName);
                java.lang.reflect.Field f8 = row.getClass().getDeclaredField("createdAt"); f8.setAccessible(true); f8.set(row, m.getCreatedAt() != null ? m.getCreatedAt().format(DTF) : "");
            } catch (Exception ignored) {}
            rows.add(row);
        }
        return rows;
    }

    private List<WarehouseRecallServlet.RecallHistoryRow> loadRecallHistory() {
        List<WarehouseRecallServlet.RecallHistoryRow> rows = new ArrayList<>();
        List<StockMovements> movements = stockMovementsDAO.findByDateRange(
                LocalDate.now().minusDays(30), LocalDate.now());
        for (StockMovements m : movements) {
            if (!"ADJUSTMENT".equals(m.getMovementType())) continue;
            String notes = m.getNotes();
            if (notes == null || !notes.contains("THU HỒI")) continue;

            WarehouseRecallServlet.RecallHistoryRow row = new WarehouseRecallServlet.RecallHistoryRow();
            Batches batch = batchesDAO.findById(m.getBatchId());
            if (batch != null) {
                row.batchNumber = batch.getBatchNumber();
                Medicines med = medicineDAO.findById(batch.getMedicineId());
                row.medicineName = med != null ? med.getMedicineName() : "(không rõ)";
            } else {
                row.batchNumber = "#" + m.getBatchId();
                row.medicineName = "(không rõ)";
            }
            row.reason = notes.replaceFirst("^THU HỒI KHẨN CẤP:\\s*", "");
            if (m.getAccountId() != null) {
                Account who = accountDAO.findById(m.getAccountId());
                row.recalledBy = who != null
                        ? (who.getFullName() != null && !who.getFullName().isEmpty() ? who.getFullName() : who.getUsername())
                        : ("#" + m.getAccountId());
            } else { row.recalledBy = "—"; }
            row.createdAt = m.getCreatedAt();
            rows.add(row);
        }
        return rows;
    }

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

            List<Batches> batches = batchesDAO.findAllByMedicine(id);
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

    private static String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
