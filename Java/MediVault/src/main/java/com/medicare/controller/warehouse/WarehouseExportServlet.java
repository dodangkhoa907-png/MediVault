package com.medicare.controller.warehouse;

import com.medicare.dao.BatchesDAO;
import com.medicare.dao.MedicineDAO;
import com.medicare.dao.PurchaseOrderDAO;
import com.medicare.dao.WarehouseExportDAO;
import com.medicare.entity.Account;
import com.medicare.entity.Batches;
import com.medicare.entity.ExportReason;
import com.medicare.entity.ExportStatusHistory;
import com.medicare.entity.Medicines;
import com.medicare.entity.PurchaseOrders;
import com.medicare.entity.WarehouseExport;
import com.medicare.entity.WarehouseExportDetail;
import com.medicare.service.ServiceResult;
import com.medicare.service.warehouse.AllocationResult;
import com.medicare.service.warehouse.ExportLineRequest;
import com.medicare.service.warehouse.ExportService;
import com.medicare.service.warehouse.ExportSubmission;
import com.medicare.service.warehouse.LotAllocation;
import com.medicare.util.AuditHelper;
import com.medicare.util.BarcodeService;
import com.medicare.util.SidebarHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * WarehouseExportServlet — module Xuất kho (FEFO). Controller CHỈ điều phối request/response;
 * mọi phân bổ FEFO và ghi transaction đều đi qua {@link ExportService}
 * (Controller → Service → FEFO Engine → DAO → DB, đúng kiến trúc module yêu cầu).
 */
@WebServlet("/warehouse-export")
public class WarehouseExportServlet extends HttpServlet {

    private final MedicineDAO medicineDAO = new MedicineDAO();
    private final BatchesDAO batchesDAO = new BatchesDAO();
    private final WarehouseExportDAO exportDAO = new WarehouseExportDAO();
    private final PurchaseOrderDAO poDAO = new PurchaseOrderDAO();
    private final BarcodeService barcodeService = new BarcodeService();
    private final ExportService exportService = new ExportService();

    private static final DateTimeFormatter DTF = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private Account requireWarehouseStaff(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        return com.medicare.util.WarehouseAuth.require(req, resp);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  GET
    // ══════════════════════════════════════════════════════════════════════

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Account acc = requireWarehouseStaff(req, resp);
        if (acc == null) return;

        String action = req.getParameter("action");
        if ("allocate".equals(action))         { apiAllocate(req, resp); return; }
        if ("lookup-barcode".equals(action))   { apiLookupBarcode(req, resp); return; }
        if ("search-medicine".equals(action))  { apiSearchMedicine(req, resp); return; }
        if ("recent-medicines".equals(action)) { apiRecentMedicines(req, resp); return; }
        if ("list".equals(action))             { apiList(req, resp); return; }
        if ("detail".equals(action))           { apiDetail(req, resp); return; }
        if ("print".equals(action))            { doPrint(req, resp, acc); return; }

        renderPage(req, resp, acc);
    }

    private void renderPage(HttpServletRequest req, HttpServletResponse resp, Account acc)
            throws ServletException, IOException {
        req.setAttribute("staffAcc", acc);
        req.setAttribute("staffUid", String.valueOf(acc.getAccountId()));
        req.setAttribute("reasons", exportDAO.findReasons());
        req.setAttribute("recentMedicines", exportDAO.findRecentMedicines(8));

        req.setAttribute("kpiPending", exportDAO.countByStatus("PENDING"));
        req.setAttribute("kpiCompletedToday", exportDAO.countCompletedToday());
        req.setAttribute("kpiMedicinesToday", exportDAO.countDistinctMedicinesToday());
        req.setAttribute("kpiNearExpiryToday", exportDAO.countNearExpiryLotsToday());

        // Category/Manufacturer cho form "Tạo nhanh thuốc" trong wizard "Phát hiện mã vạch mới"
        // (Option B) — cùng dữ liệu WarehouseImportServlet truyền cho JSP Nhập kho.
        req.setAttribute("bcCategories", new com.medicare.dao.CategoryDAO().findAll());
        req.setAttribute("bcManufacturers", new com.medicare.dao.ManufacturerDAO().findAll());

        // Danh sách kệ cho nút "Xếp kệ nhanh" ở Bước 3 (Phân bổ FEFO) — khi thấy 1 thuốc
        // "Chưa xếp kệ" ngay lúc soạn phiếu, thủ kho gán luôn tại chỗ, không phải chạy sang
        // trang Quản lý kệ riêng rồi quay lại.
        req.setAttribute("shelves", new com.medicare.dao.ShelfDAO().findAll());

        req.setAttribute("activeNav", "export");
        SidebarHelper.loadWarehouse(req, acc.getAccountId());

        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-export.jsp").forward(req, resp);
    }

    /** action=print&exportId= — phiếu xuất kho dạng in, không sidebar/topbar. */
    private void doPrint(HttpServletRequest req, HttpServletResponse resp, Account acc)
            throws ServletException, IOException {
        int exportId = parseIntOrDefault(req.getParameter("exportId"), -1);
        WarehouseExport export = exportId > 0 ? exportDAO.findById(exportId) : null;
        if (export == null) {
            resp.sendError(HttpServletResponse.SC_NOT_FOUND);
            return;
        }
        req.setAttribute("export", export);
        req.setAttribute("details", exportDAO.findDetails(exportId));
        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-export-print.jsp").forward(req, resp);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  POST
    // ══════════════════════════════════════════════════════════════════════

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        Account acc = requireWarehouseStaff(req, resp);
        if (acc == null) return;

        String action = req.getParameter("action");
        if ("quick-create-medicine".equals(action)) { handleQuickCreateMedicine(req, resp, acc); return; }
        if ("bind-barcode".equals(action))          { handleBindBarcode(req, resp, acc); return; }
        if ("assign-shelf".equals(action))          { handleAssignShelf(req, resp, acc); return; }
        if ("confirm".equals(action))               { handleConfirm(req, resp, acc); return; }
        if ("cancel".equals(action))                { handleCancel(req, resp, acc); return; }
        if ("reverse".equals(action))                { handleReverse(req, resp, acc); return; }
        if ("purchase-suggestion".equals(action))    { handlePurchaseSuggestion(req, resp, acc); return; }

        resp.sendRedirect(req.getContextPath() + "/warehouse-export");
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Step 3 — FEFO preview (AJAX, không ghi gì)
    // ══════════════════════════════════════════════════════════════════════

    private void apiAllocate(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        PrintWriter out = resp.getWriter();
        try {
            int medicineId = Integer.parseInt(req.getParameter("medicineId"));
            int qty = Integer.parseInt(req.getParameter("qty"));
            Medicines med = medicineDAO.findById(medicineId);
            AllocationResult result = exportService.previewAllocation(medicineId, qty);
            out.print(allocationJson(med, result));
        } catch (Exception e) {
            out.print("{\"ok\":false,\"reason\":\"invalid_request\"}");
        }
    }

    private String allocationJson(Medicines med, AllocationResult result) {
        StringBuilder sb = new StringBuilder();
        sb.append("{\"ok\":true,\"medicineId\":").append(result.getMedicineId())
          .append(",\"medicineName\":").append(jstr(med != null ? med.getMedicineName() : null))
          .append(",\"unit\":").append(jstr(med != null ? med.getUnit() : null))
          .append(",\"shelfName\":").append(jstr(med != null ? findShelfName(med.getShelfId()) : null))
          .append(",\"storageConditions\":").append(jstr(med != null ? med.getStorageConditions() : null))
          .append(",\"requestedQuantity\":").append(result.getRequestedQuantity())
          .append(",\"shortfall\":").append(result.getShortfall())
          // risky = đơn bị chia ≥ 2 lô khác hạn dùng — FE dùng để tự hiện cảnh báo + gợi ý ghi đè,
          // xem AllocationResult.isRisky() để biết định nghĩa đầy đủ.
          .append(",\"risky\":").append(result.isRisky())
          .append(",\"lots\":[");
        List<LotAllocation> lots = result.getAllocations();
        for (int i = 0; i < lots.size(); i++) {
            LotAllocation la = lots.get(i);
            if (i > 0) sb.append(',');
            sb.append("{\"batchId\":").append(la.getBatchId())
              .append(",\"batchNumber\":").append(jstr(la.getBatchNumber()))
              .append(",\"expiryDate\":").append(jstr(la.getExpiryDate() != null ? la.getExpiryDate().toString() : null))
              .append(",\"availableQuantity\":").append(la.getAvailableQuantity())
              .append(",\"allocatedQuantity\":").append(la.getAllocatedQuantity())
              .append('}');
        }
        sb.append("]}");
        return sb.toString();
    }

    private String findShelfName(Integer shelfId) {
        if (shelfId == null) return null;
        com.medicare.entity.Shelf s = new com.medicare.dao.ShelfDAO().findById(shelfId);
        return s != null ? s.getShelfName() : null;
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Step 2 — tìm kiếm / mã vạch / gần đây
    // ══════════════════════════════════════════════════════════════════════

    private void apiSearchMedicine(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        PrintWriter out = resp.getWriter();
        String kw = req.getParameter("kw");
        List<Medicines> list = (kw != null && !kw.trim().isEmpty())
                ? medicineDAO.searchForExport(kw.trim())
                : new ArrayList<>();
        out.print(medicinesJson(list));
    }

    private void apiRecentMedicines(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        resp.getWriter().print(medicinesJson(exportDAO.findRecentMedicines(8)));
    }

    private String medicinesJson(List<Medicines> list) {
        StringBuilder sb = new StringBuilder("{\"ok\":true,\"medicines\":[");
        for (int i = 0; i < list.size(); i++) {
            if (i > 0) sb.append(',');
            sb.append(BarcodeService.medicineJson(list.get(i)));
        }
        sb.append("]}");
        return sb.toString();
    }

    /** action=lookup-barcode — giống hệt WarehouseImportServlet, dùng chung BarcodeService. */
    private void apiLookupBarcode(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        String barcode = req.getParameter("barcode");
        String source = normSource(req.getParameter("source"));
        Medicines m = barcodeService.lookup(barcode, source);
        PrintWriter out = resp.getWriter();
        if (m != null) {
            out.print("{\"ok\":true,\"found\":true,\"medicine\":" + BarcodeService.medicineJson(m) + "}");
        } else {
            out.print("{\"ok\":true,\"found\":false}");
        }
    }

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

            AuditHelper.log(req, "Tạo nhanh thuốc từ quét mã vạch (Xuất kho)", "Medicine",
                    created.getMedicineId(), "Mã vạch " + barcode.trim() + " — " + created.getMedicineName());

            out.print("{\"ok\":true,\"medicine\":" + BarcodeService.medicineJson(created) + "}");
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"ok\":false,\"reason\":\"server_error\"}");
        }
    }

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
            AuditHelper.log(req, "Gán mã vạch (Xuất kho)", "Medicine", medicineId,
                    "Gán mã vạch " + barcode.trim() + " vào thuốc " + (m != null ? m.getMedicineName() : "#" + medicineId));

            out.print("{\"ok\":true,\"medicine\":" + BarcodeService.medicineJson(m) + "}");
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"ok\":false,\"reason\":\"server_error\"}");
        }
    }

    /** action=assign-shelf — gán/đổi vị trí kệ ngay tại Bước 3 khi thấy thuốc "Chưa xếp kệ".
     *  ShelfID nằm trên Medicines (không phải theo lô), giống hệt chỗ Admin gán qua medicine-form.jsp
     *  — dùng lại MedicineDAO.updateShelf() sẵn có, không tạo đường ghi mới. */
    private void handleAssignShelf(HttpServletRequest req, HttpServletResponse resp, Account acc) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        try {
            Integer medicineId = parseIntOrNull(req.getParameter("medicineId"));
            Integer shelfId = parseIntOrNull(req.getParameter("shelfId"));
            if (medicineId == null) { out.print("{\"ok\":false,\"reason\":\"invalid_medicine\"}"); return; }
            if (shelfId == null) { out.print("{\"ok\":false,\"reason\":\"invalid_shelf\"}"); return; }

            Medicines med = medicineDAO.findById(medicineId);
            if (med == null) { out.print("{\"ok\":false,\"reason\":\"medicine_not_found\"}"); return; }

            boolean ok = medicineDAO.updateShelf(medicineId, shelfId);
            if (!ok) { out.print("{\"ok\":false,\"reason\":\"db_error\"}"); return; }

            String shelfName = findShelfName(shelfId);
            AuditHelper.log(req, "Xếp kệ nhanh (Xuất kho)", "Medicine", medicineId,
                    med.getMedicineName() + " → " + (shelfName != null ? shelfName : "Kệ #" + shelfId));

            out.print("{\"ok\":true,\"shelfId\":" + shelfId + ",\"shelfName\":" + jstr(shelfName) + "}");
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"ok\":false,\"reason\":\"server_error\"}");
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  History / Export List / Detail
    // ══════════════════════════════════════════════════════════════════════

    private void apiList(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        String status = req.getParameter("status");
        String kw = req.getParameter("kw");
        LocalDate from = parseDateOrNull(req.getParameter("from"));
        LocalDate to = parseDateOrNull(req.getParameter("to"));
        int page = parseIntOrDefault(req.getParameter("page"), 1);
        List<WarehouseExport> list = exportDAO.findPaged(status, from, to, kw, page, 20);

        StringBuilder sb = new StringBuilder("{\"ok\":true,\"exports\":[");
        for (int i = 0; i < list.size(); i++) {
            if (i > 0) sb.append(',');
            sb.append(exportHeaderJson(list.get(i)));
        }
        sb.append("]}");
        resp.getWriter().print(sb.toString());
    }

    private void apiDetail(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        int exportId = parseIntOrDefault(req.getParameter("exportId"), -1);
        WarehouseExport export = exportId > 0 ? exportDAO.findById(exportId) : null;
        if (export == null) { resp.getWriter().print("{\"ok\":false,\"reason\":\"not_found\"}"); return; }

        List<WarehouseExportDetail> details = exportDAO.findDetails(exportId);
        List<ExportStatusHistory> history = exportDAO.findHistory(exportId);

        StringBuilder sb = new StringBuilder("{\"ok\":true,\"export\":").append(exportHeaderJson(export))
                .append(",\"details\":[");
        for (int i = 0; i < details.size(); i++) {
            if (i > 0) sb.append(',');
            sb.append(detailJson(details.get(i)));
        }
        sb.append("],\"history\":[");
        for (int i = 0; i < history.size(); i++) {
            if (i > 0) sb.append(',');
            ExportStatusHistory h = history.get(i);
            sb.append("{\"status\":").append(jstr(h.getStatus()))
              .append(",\"accountName\":").append(jstr(h.getAccountName()))
              .append(",\"notes\":").append(jstr(h.getNotes()))
              .append(",\"createdAt\":").append(jstr(h.getCreatedAt() != null ? h.getCreatedAt().format(DTF) : null))
              .append('}');
        }
        sb.append("]}");
        resp.getWriter().print(sb.toString());
    }

    private String exportHeaderJson(WarehouseExport e) {
        return "{\"exportId\":" + e.getExportId()
                + ",\"exportCode\":" + jstr(e.getExportCode())
                + ",\"reasonName\":" + jstr(e.getReasonName())
                + ",\"reasonCode\":" + jstr(e.getReasonCode())
                + ",\"status\":" + jstr(e.getStatus())
                + ",\"receiver\":" + jstr(e.getReceiver())
                + ",\"notes\":" + jstr(e.getNotes())
                + ",\"fefoOverridden\":" + e.isFefoOverridden()
                + ",\"createdByName\":" + jstr(e.getCreatedByName())
                + ",\"createdAt\":" + jstr(e.getCreatedAt() != null ? e.getCreatedAt().format(DTF) : null)
                + ",\"confirmedAt\":" + jstr(e.getConfirmedAt() != null ? e.getConfirmedAt().format(DTF) : null)
                + "}";
    }

    private String detailJson(WarehouseExportDetail d) {
        return "{\"medicineId\":" + d.getMedicineId()
                + ",\"medicineName\":" + jstr(d.getMedicineName())
                + ",\"medicineCode\":" + jstr(d.getMedicineCode())
                + ",\"barcode\":" + jstr(d.getBarcode())
                + ",\"batchNumber\":" + jstr(d.getBatchNumber())
                + ",\"expiryDate\":" + jstr(d.getExpiryDate() != null ? d.getExpiryDate().toString() : null)
                + ",\"requestedQuantity\":" + d.getRequestedQuantity()
                + ",\"allocatedQuantity\":" + d.getAllocatedQuantity()
                + ",\"fefoOverridden\":" + d.isFefoOverridden()
                + "}";
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Step 5 — Confirm / Cancel / Reverse
    // ══════════════════════════════════════════════════════════════════════

    private void handleConfirm(HttpServletRequest req, HttpServletResponse resp, Account acc) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        try {
            int reasonId = Integer.parseInt(req.getParameter("reasonId"));
            String receiver = req.getParameter("receiver");
            String notes = req.getParameter("notes");
            String overrideReason = req.getParameter("overrideReason");

            String[] medicineIds = req.getParameterValues("medicineId");
            String[] qtys = req.getParameterValues("requestedQty");
            String[] overriddenFlags = req.getParameterValues("overridden");
            String[] overrideBatchIds = req.getParameterValues("overrideBatchId");

            if (medicineIds == null || medicineIds.length == 0) {
                out.print("{\"ok\":false,\"errors\":[\"Chưa chọn thuốc nào để xuất kho.\"]}");
                return;
            }

            List<ExportLineRequest> lines = new ArrayList<>();
            for (int i = 0; i < medicineIds.length; i++) {
                int medicineId = Integer.parseInt(medicineIds[i]);
                int qty = Integer.parseInt(qtys[i]);
                boolean overridden = overriddenFlags != null && i < overriddenFlags.length && "1".equals(overriddenFlags[i]);
                List<ExportLineRequest.ManualAllocation> manual = new ArrayList<>();
                if (overridden && overrideBatchIds != null && i < overrideBatchIds.length
                        && overrideBatchIds[i] != null && !overrideBatchIds[i].trim().isEmpty()) {
                    manual.add(new ExportLineRequest.ManualAllocation(Integer.parseInt(overrideBatchIds[i].trim()), qty));
                }
                lines.add(new ExportLineRequest(medicineId, qty, overridden, manual));
            }

            ExportSubmission submission = new ExportSubmission(reasonId, receiver, notes, overrideReason, lines);
            ServiceResult<Integer> result = exportService.submit(submission, acc);

            if (!result.isOk()) {
                out.print("{\"ok\":false,\"errors\":" + jarr(result.getErrors() != null ? result.getErrors() : List.of(result.firstError())) + "}");
                return;
            }

            int exportId = result.getData();
            WarehouseExport saved = exportDAO.findById(exportId);
            AuditHelper.log(req, "Xác nhận phiếu xuất kho", "WarehouseExport", exportId,
                    "Phiếu " + (saved != null ? saved.getExportCode() : "#" + exportId)
                            + " — " + lines.size() + " dòng thuốc"
                            + (submission.hasAnyOverride() ? " (có ghi đè FEFO)" : ""));
            if (submission.hasAnyOverride()) {
                AuditHelper.log(req, "Ghi đè phân bổ FEFO", "WarehouseExport", exportId, overrideReason);
            }

            out.print("{\"ok\":true,\"exportId\":" + exportId
                    + ",\"exportCode\":" + jstr(saved != null ? saved.getExportCode() : null) + "}");
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"ok\":false,\"errors\":[\"Yêu cầu không hợp lệ.\"]}");
        }
    }

    private void handleCancel(HttpServletRequest req, HttpServletResponse resp, Account acc) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        int exportId = parseIntOrDefault(req.getParameter("exportId"), -1);
        String reason = req.getParameter("reason");
        ServiceResult<Void> result = exportService.cancel(exportId, acc, reason);
        if (!result.isOk()) { out.print("{\"ok\":false,\"reason\":" + jstr(result.firstError()) + "}"); return; }
        AuditHelper.log(req, "Huỷ phiếu xuất kho", "WarehouseExport", exportId, reason);
        out.print("{\"ok\":true}");
    }

    private void handleReverse(HttpServletRequest req, HttpServletResponse resp, Account acc) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        int exportId = parseIntOrDefault(req.getParameter("exportId"), -1);
        String reason = req.getParameter("reason");
        ServiceResult<Void> result = exportService.reverse(exportId, acc, reason);
        if (!result.isOk()) { out.print("{\"ok\":false,\"reason\":" + jstr(result.firstError()) + "}"); return; }
        AuditHelper.log(req, "Hoàn trả (Reverse) phiếu xuất kho", "WarehouseExport", exportId, reason);
        out.print("{\"ok\":true}");
    }

    /** action=purchase-suggestion — tạo nhanh 1 Phiếu đặt hàng PENDING cho phần thiếu hụt. */
    private void handlePurchaseSuggestion(HttpServletRequest req, HttpServletResponse resp, Account acc) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        try {
            int medicineId = Integer.parseInt(req.getParameter("medicineId"));
            int missingQty = Integer.parseInt(req.getParameter("missingQty"));
            Medicines med = medicineDAO.findById(medicineId);
            if (med == null || missingQty <= 0) { out.print("{\"ok\":false,\"reason\":\"invalid_request\"}"); return; }

            Map<Integer, Batches> latestByMedicine = batchesDAO.getLatestBatchMap();
            Batches latest = latestByMedicine.get(medicineId);
            if (latest == null || latest.getSupplierId() <= 0) {
                out.print("{\"ok\":false,\"reason\":\"no_supplier_history\",\"message\":" +
                        jstr("Thuốc này chưa từng nhập kho lần nào — vào trang Nhập kho / Gợi ý đặt hàng để chọn nhà cung cấp thủ công.") + "}");
                return;
            }

            PurchaseOrders po = new PurchaseOrders();
            po.setSupplierId(latest.getSupplierId());
            po.setAccountId(acc.getAccountId());
            po.setNotes("Đề xuất từ module Xuất kho — thiếu " + missingQty + " " + (med.getUnit() != null ? med.getUnit() : "")
                    + " (" + med.getMedicineName() + ")");
            int poId = poDAO.insert(po);
            if (poId <= 0) { out.print("{\"ok\":false,\"reason\":\"db_error\"}"); return; }

            Map<Integer, BigDecimal> avgPriceMap = batchesDAO.getAvgImportPriceMap();
            Batches suggestion = new Batches();
            suggestion.setMedicineId(medicineId);
            suggestion.setInitialQuantity(missingQty);
            suggestion.setImportPrice(avgPriceMap.getOrDefault(medicineId, BigDecimal.ZERO));
            poDAO.addDetail(poId, suggestion);

            AuditHelper.log(req, "Tạo đề xuất mua hàng từ Xuất kho", "PurchaseOrder", poId,
                    "Thiếu " + missingQty + " — " + med.getMedicineName());

            out.print("{\"ok\":true,\"poId\":" + poId + "}");
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"ok\":false,\"reason\":\"server_error\"}");
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Helpers
    // ══════════════════════════════════════════════════════════════════════

    private String normSource(String s) {
        if ("camera".equals(s) || "usb".equals(s) || "manual".equals(s)) return s;
        return "manual";
    }

    private Integer parseIntOrNull(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (NumberFormatException e) { return null; }
    }

    private int parseIntOrDefault(String s, int def) {
        Integer v = parseIntOrNull(s);
        return v != null ? v : def;
    }

    private LocalDate parseDateOrNull(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return LocalDate.parse(s.trim()); } catch (Exception e) { return null; }
    }

    private static String jstr(String s) {
        if (s == null) return "null";
        return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r") + "\"";
    }

    private static String jarr(List<String> items) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < items.size(); i++) {
            if (i > 0) sb.append(',');
            sb.append(jstr(items.get(i)));
        }
        return sb.append(']').toString();
    }
}
