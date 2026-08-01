package com.medicare.controller.warehouse;

import com.medicare.dao.BatchesDAO;
import com.medicare.dao.MedicineDAO;
import com.medicare.dao.StockMovementsDAO;
import com.medicare.dao.AccountDAO;
import com.medicare.dao.interfaces.IBatchesDAO;
import com.medicare.dao.interfaces.IMedicineDAO;
import com.medicare.dao.interfaces.IStockMovementsDAO;
import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.entity.Account;
import com.medicare.entity.Batches;
import com.medicare.entity.Medicines;
import com.medicare.entity.StockMovements;
import com.medicare.util.AuditHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * WarehouseStockMovementServlet — Xuất kho / Điều chỉnh tồn kho thủ công có xác thực đúng lô (FEFO).
 *
 * Bối cảnh: ở POS, SP_AddSaleByFEFO tự chọn lô — con người không can thiệp được nên khâu bán lẻ
 * đã an toàn. Rủi ro "lấy nhầm lô" nằm ở thao tác THỦ CÔNG trong kho (hủy hết hạn/hỏng, điều
 * chỉnh sau kiểm kê, xuất nội bộ) — lúc thủ kho tự tay cầm hộp thuốc, có thể cầm nhầm lô.
 *
 * Cách chặn: hệ thống dùng batchesDAO.findNearestExpiry() để CHỈ ĐỊNH đúng lô phải lấy theo FEFO,
 * thủ kho phải quét/nhập ĐÚNG số lô đó mới được xác nhận thao tác — sai lô thì chặn lại, không trừ kho.
 *
 * Gate: chỉ role Thủ kho (roleId == 3), session "staffAccount_<uid>" — giống StaffDashboardServlet.
 */
@WebServlet("/warehouse-stock-movement")
public class WarehouseStockMovementServlet extends HttpServlet {

    private final IBatchesDAO batchesDAO = new BatchesDAO();
    private final IMedicineDAO medicineDAO = new MedicineDAO();
    private final IStockMovementsDAO stockMovementsDAO = new StockMovementsDAO();
    private final IAccountDAO accountDAO = new AccountDAO();

    private static final DateTimeFormatter DTF = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    // ── Gate dùng chung cho GET/POST — trả về staff account hợp lệ hoặc null (đã redirect) ──
    private Account requireWarehouseStaff(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String uid = req.getParameter("uid");
        if (uid == null || uid.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login");
            return null;
        }
        HttpSession session = req.getSession(false);
        if (session == null) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login");
            return null;
        }
        Account staffAcc = (Account) session.getAttribute("staffAccount_" + uid);
        if (staffAcc == null) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login");
            return null;
        }
        if (staffAcc.getRoleId() != 3) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Chỉ Thủ kho được truy cập chức năng này!");
            return null;
        }
        return staffAcc;
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        Account staffAcc = requireWarehouseStaff(req, resp);
        if (staffAcc == null) return;

        // ── AJAX: gợi ý lô hệ thống chỉ định (FEFO) khi chọn thuốc ──
        String action = req.getParameter("action");
        if ("suggest-batch".equals(action)) {
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
            return;
        }

        String medIdParam = req.getParameter("medicineId");
        String medQuery = (medIdParam != null && !medIdParam.isEmpty()) ? "&medicineId=" + medIdParam : "";
        resp.sendRedirect(req.getContextPath() + "/warehouse-inventory?uid=" + req.getParameter("uid") + "&tab=movement" + medQuery);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        Account staffAcc = requireWarehouseStaff(req, resp);
        if (staffAcc == null) return;

        String uid = req.getParameter("uid");
        String medicineIdStr = req.getParameter("medicineId");
        String enteredBatchNumber = req.getParameter("enteredBatchNumber");
        String movementType = req.getParameter("movementType"); // OUT | EXPIRED | ADJUSTMENT
        String adjustDirection = req.getParameter("adjustDirection"); // DECREASE | INCREASE (chỉ dùng khi ADJUSTMENT)
        String quantityStr = req.getParameter("quantity");
        String reason = req.getParameter("reason");

        String error = null;
        Integer medicineId = null;
        Integer quantity = null;

        // ── Validate input cơ bản ──
        if (medicineIdStr == null || medicineIdStr.isEmpty()) {
            error = "Vui lòng chọn thuốc cần xuất/điều chỉnh.";
        } else if (!("OUT".equals(movementType) || "EXPIRED".equals(movementType) || "ADJUSTMENT".equals(movementType))) {
            error = "Loại di chuyển kho không hợp lệ.";
        } else if (enteredBatchNumber == null || enteredBatchNumber.trim().isEmpty()) {
            error = "Vui lòng quét hoặc nhập số lô.";
        } else if (reason == null || reason.trim().isEmpty()) {
            error = "Vui lòng nhập lý do thao tác.";
        }

        if (error == null) {
            try {
                medicineId = Integer.parseInt(medicineIdStr);
            } catch (NumberFormatException e) {
                error = "Thuốc không hợp lệ.";
            }
        }
        if (error == null) {
            try {
                quantity = Integer.parseInt(quantityStr);
                if (quantity <= 0) error = "Số lượng phải lớn hơn 0.";
            } catch (NumberFormatException e) {
                error = "Số lượng không hợp lệ.";
            }
        }

        Batches expectedBatch = null;
        if (error == null) {
            // ── Lô mà HỆ THỐNG chỉ định theo FEFO — thủ kho phải lấy đúng lô này ──
            expectedBatch = batchesDAO.findNearestExpiry(medicineId);
            if (expectedBatch == null) {
                error = "Không có lô nào còn tồn kho khả dụng (còn hạn, ACTIVE) cho thuốc này.";
            }
        }

        if (error == null) {
            // ── Đối chiếu số lô thủ kho nhập/quét với lô hệ thống chỉ định ──
            if (!expectedBatch.getBatchNumber().trim().equalsIgnoreCase(enteredBatchNumber.trim())) {
                error = "Sai lô! Hệ thống yêu cầu lấy lô " + expectedBatch.getBatchNumber()
                        + " (HSD: " + expectedBatch.getExpiryDate() + "), bạn nhập lô " + enteredBatchNumber + ".";
            }
        }

        if (error == null) {
            // ── Tính delta: ADJUSTMENT + INCREASE = tăng (kiểm kê thừa), còn lại = giảm ──
            int delta = ("ADJUSTMENT".equals(movementType) && "INCREASE".equals(adjustDirection))
                    ? quantity
                    : -quantity;

            boolean ok = batchesDAO.adjustQuantity(expectedBatch.getBatchId(), delta);
            if (!ok) {
                error = "Không đủ tồn kho lô này để xuất/điều chỉnh.";
            } else {
                StockMovements sm = new StockMovements();
                sm.setBatchId(expectedBatch.getBatchId());
                sm.setMovementType(movementType);
                sm.setQuantity(delta);
                sm.setRefTable("Manual");
                sm.setRefId(null);
                sm.setAccountId(staffAcc.getAccountId());
                sm.setNotes(reason.trim());
                stockMovementsDAO.insert(sm);

                AuditHelper.log(req, "Điều chỉnh tồn kho thủ công", "Batches",
                        "Lô " + expectedBatch.getBatchNumber() + ": " + movementType + " " + delta
                                + " (" + reason.trim() + ")",
                        staffAcc.getAccountId());

                resp.sendRedirect(req.getContextPath() + "/warehouse-inventory?uid=" + uid + "&tab=movement&msg=success");
                return;
            }
        }

        // ── Có lỗi: forward lại JSP kèm lỗi + giữ lại dữ liệu đã nhập, KHÔNG trừ kho ──
        req.setAttribute("error", error);
        req.setAttribute("expectedBatch", expectedBatch);
        req.setAttribute("f_medicineId", medicineIdStr);
        req.setAttribute("f_enteredBatchNumber", enteredBatchNumber);
        req.setAttribute("f_movementType", movementType);
        req.setAttribute("f_adjustDirection", adjustDirection);
        req.setAttribute("f_quantity", quantityStr);
        req.setAttribute("f_reason", reason);
        renderPage(req, resp, staffAcc);
    }

    /** Chuẩn bị dữ liệu chung cho trang: danh sách thuốc + lịch sử di chuyển kho 7 ngày gần nhất. */
    private void renderPage(HttpServletRequest req, HttpServletResponse resp, Account staffAcc)
            throws ServletException, IOException {

        String kw = req.getParameter("kw");
        List<Medicines> medicines = (kw != null && !kw.trim().isEmpty())
                ? medicineDAO.searchWithStock(kw.trim())
                : medicineDAO.findAllWithStock();
        req.setAttribute("medicines", medicines);

        // ── Lịch sử di chuyển kho 7 ngày gần nhất — join thủ công tên thuốc/số lô ──
        List<StockMovements> movements = stockMovementsDAO.findByDateRange(
                LocalDate.now().minusDays(7), LocalDate.now());

        Map<Integer, Batches> batchCache = new HashMap<>();
        Map<Integer, String> medNameCache = new HashMap<>();
        Map<Integer, String> accNameCache = new HashMap<>();
        List<MovementRow> rows = new ArrayList<>();

        for (StockMovements m : movements) {
            Batches b = batchCache.computeIfAbsent(m.getBatchId(), batchesDAO::findById);
            String medName = "?";
            String batchNo = "?";
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

            MovementRow row = new MovementRow();
            row.movementId = m.getMovementId();
            row.medicineName = medName;
            row.batchNumber = batchNo;
            row.movementType = m.getMovementType();
            row.quantity = m.getQuantity();
            row.notes = m.getNotes();
            row.accountName = accName;
            row.createdAt = m.getCreatedAt() != null ? m.getCreatedAt().format(DTF) : "";
            rows.add(row);
        }
        req.setAttribute("movementRows", rows);
        req.setAttribute("staffAcc", staffAcc);
        req.setAttribute("uid", req.getParameter("uid"));
        // Pre-chọn thuốc khi vào trang qua link "?medicineId=X" (nút 👁️ ở warehouse-inventory.jsp) —
        // trước đây f_medicineId chỉ được set trong doPost() lúc redisplay form sau lỗi validate,
        // nên đi thẳng từ link ngoài vào (GET thường) không pre-select được gì, ô "Chọn thuốc" trống trơn.
        if (req.getAttribute("f_medicineId") == null) {
            req.setAttribute("f_medicineId", req.getParameter("medicineId"));
        }

        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-stock-movement.jsp")
                .forward(req, resp);
    }

    private static String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    /** DTO hiển thị 1 dòng lịch sử di chuyển kho đã join tên thuốc/số lô/người thực hiện. */
    public static class MovementRow {
        private int movementId;
        private String medicineName;
        private String batchNumber;
        private String movementType;
        private int quantity;
        private String notes;
        private String accountName;
        private String createdAt;

        public int getMovementId() { return movementId; }
        public String getMedicineName() { return medicineName; }
        public String getBatchNumber() { return batchNumber; }
        public String getMovementType() { return movementType; }
        public int getQuantity() { return quantity; }
        public String getNotes() { return notes; }
        public String getAccountName() { return accountName; }
        public String getCreatedAt() { return createdAt; }
    }
}
