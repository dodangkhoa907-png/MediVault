package com.medicare.controller.warehouse;

import com.medicare.dao.AccountDAO;
import com.medicare.dao.BatchesDAO;
import com.medicare.dao.MedicineDAO;
import com.medicare.dao.ShelfDAO;
import com.medicare.dao.StockMovementsDAO;
import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.dao.interfaces.IBatchesDAO;
import com.medicare.dao.interfaces.IMedicineDAO;
import com.medicare.dao.interfaces.IShelfDAO;
import com.medicare.dao.interfaces.IStockMovementsDAO;
import com.medicare.entity.Account;
import com.medicare.entity.Batches;
import com.medicare.entity.Medicines;
import com.medicare.entity.Shelf;
import com.medicare.entity.StockMovements;
import com.medicare.util.AuditHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * WarehouseRecallServlet — "Thu hồi lô khẩn cấp" cho Quản lý kho (roleId 3 = Thủ kho).
 * URL: /warehouse-recall?uid=&lt;id&gt;
 *
 * <p>Khi có công văn thu hồi (Cục Quản lý Dược / lỗi chất lượng), thủ kho tìm đúng lô theo
 * số lô, xem thông tin (tồn, vị trí kệ) rồi xác nhận thu hồi — lô bị đổi Status='RECALLED'
 * nên {@code SP_AddSaleByFEFO} (chỉ chọn Status='ACTIVE') sẽ TỰ ĐỘNG ngừng bán lô này ở POS.
 * Sự kiện được ghi lại vào StockMovements (MovementType=ADJUSTMENT, Quantity=0) và AuditLog.</p>
 */
@WebServlet("/warehouse-recall")
public class WarehouseRecallServlet extends HttpServlet {

    private static final int ROLE_WAREHOUSE = 3;

    private final IBatchesDAO        batchesDAO        = new BatchesDAO();
    private final IMedicineDAO       medicineDAO       = new MedicineDAO();
    private final IShelfDAO          shelfDAO          = new ShelfDAO();
    private final IStockMovementsDAO stockMovementsDAO = new StockMovementsDAO();
    private final IAccountDAO        accountDAO        = new AccountDAO();

    /** Dòng hiển thị trong bảng "Lịch sử thu hồi" — gộp thông tin từ nhiều bảng cho JSP. */
    public static class RecallHistoryRow {
        public String batchNumber;
        public String medicineName;
        public String reason;
        public String recalledBy;
        public java.time.LocalDateTime createdAt;
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        Account acc = requireWarehouseAccount(req, resp);
        if (acc == null) return;

        String uid = req.getParameter("uid");

        req.setAttribute("staffUid", uid);
        req.setAttribute("staffAcc", acc);
        req.setAttribute("medicines", medicineDAO.findAll());
        req.setAttribute("history", loadRecallHistory());

        String msg = req.getParameter("msg");
        if (msg != null) req.setAttribute("msg", msg);

        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-recall.jsp")
                .forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        Account acc = requireWarehouseAccount(req, resp);
        if (acc == null) return;

        String uid = req.getParameter("uid");
        String action = req.getParameter("action");

        req.setAttribute("staffUid", uid);
        req.setAttribute("staffAcc", acc);
        req.setAttribute("medicines", medicineDAO.findAll());
        req.setAttribute("history", loadRecallHistory());

        if ("confirm-recall".equals(action)) {
            handleConfirmRecall(req, resp, acc, uid);
            return;
        }

        // Mặc định: "search" — tìm lô theo thuốc + số lô, KHÔNG thu hồi ngay.
        handleSearch(req);
        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-recall.jsp")
                .forward(req, resp);
    }

    private void handleSearch(HttpServletRequest req) {
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

    private void handleConfirmRecall(HttpServletRequest req, HttpServletResponse resp,
                                      Account acc, String uid) throws IOException, ServletException {
        String batchIdStr = req.getParameter("batchId");
        String reason = req.getParameter("reason");

        if (reason == null || reason.trim().isEmpty()) {
            req.setAttribute("error", "Bắt buộc phải ghi rõ lý do thu hồi trước khi xác nhận.");
            reRenderConfirmForm(req, batchIdStr);
            req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-recall.jsp").forward(req, resp);
            return;
        }

        int batchId;
        try {
            batchId = Integer.parseInt(batchIdStr.trim());
        } catch (Exception e) {
            req.setAttribute("error", "Lô không hợp lệ.");
            req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-recall.jsp").forward(req, resp);
            return;
        }

        // Lấy thông tin lô TRƯỚC khi đổi trạng thái — để còn số lô/tên thuốc ghi audit.
        Batches batch = batchesDAO.findById(batchId);
        if (batch == null) {
            req.setAttribute("error", "Không tìm thấy lô cần thu hồi.");
            req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-recall.jsp").forward(req, resp);
            return;
        }
        Medicines med = medicineDAO.findById(batch.getMedicineId());
        String medicineName = med != null ? med.getMedicineName() : "(không rõ)";

        boolean ok = batchesDAO.recallBatch(batchId);
        if (!ok) {
            req.setAttribute("error", "Lô này đã không còn hoạt động, có thể đã được xử lý trước đó.");
            reRenderConfirmForm(req, batchIdStr);
            req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-recall.jsp").forward(req, resp);
            return;
        }

        // Ghi sổ cái kho — ADJUSTMENT, Quantity=0 (KHÔNG trừ tồn vật lý, hàng còn chờ thu gom).
        StockMovements mv = new StockMovements();
        mv.setBatchId(batchId);
        mv.setMovementType("ADJUSTMENT");
        mv.setQuantity(0);
        mv.setRefTable("Recall");
        mv.setRefId(null);
        mv.setAccountId(acc.getAccountId());
        mv.setNotes("THU HỒI KHẨN CẤP: " + reason.trim());
        stockMovementsDAO.insert(mv);

        AuditHelper.log(req, "Thu hồi lô khẩn cấp", "Batches",
                "Lô " + batch.getBatchNumber() + " (thuốc " + medicineName + ") — Lý do: " + reason.trim(),
                acc.getAccountId());

        resp.sendRedirect(req.getContextPath() + "/warehouse-recall?uid=" + uid + "&msg=recalled");
    }

    /** Khi thu hồi thất bại/thiếu lý do, hiển thị lại đúng card xác nhận (không mất ngữ cảnh). */
    private void reRenderConfirmForm(HttpServletRequest req, String batchIdStr) {
        try {
            int batchId = Integer.parseInt(batchIdStr.trim());
            Batches batch = batchesDAO.findById(batchId);
            if (batch != null) {
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
            }
        } catch (Exception ignored) { }
    }

    /** Lịch sử thu hồi 30 ngày gần nhất — lọc thủ công các dòng ADJUSTMENT có ghi chú thu hồi. */
    private List<RecallHistoryRow> loadRecallHistory() {
        List<RecallHistoryRow> rows = new ArrayList<>();
        List<StockMovements> movements = stockMovementsDAO.findByDateRange(
                LocalDate.now().minusDays(30), LocalDate.now());

        for (StockMovements m : movements) {
            if (!"ADJUSTMENT".equals(m.getMovementType())) continue;
            String notes = m.getNotes();
            if (notes == null || !notes.contains("THU HỒI")) continue;

            RecallHistoryRow row = new RecallHistoryRow();
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
            } else {
                row.recalledBy = "—";
            }
            row.createdAt = m.getCreatedAt();
            rows.add(row);
        }
        return rows;
    }

    /** Gate roleId==3, giống hệt WarehouseInventoryServlet. */
    private Account requireWarehouseAccount(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String uid = req.getParameter("uid");
        HttpSession session = req.getSession(false);
        Account acc = (uid != null && session != null)
                ? (Account) session.getAttribute("staffAccount_" + uid) : null;
        if (acc == null || acc.getRoleId() != ROLE_WAREHOUSE) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login");
            return null;
        }
        return acc;
    }
}
