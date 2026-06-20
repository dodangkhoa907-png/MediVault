package com.medicare.controller.admin;

import com.medicare.dao.*;
import com.medicare.dao.interfaces.*;
import com.medicare.entity.*;
import com.medicare.util.AuditHelper;
import com.medicare.util.SidebarHelper;
import com.medicare.util.ValidationUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.util.*;

/**
 * ReturnsServlet — Trả hàng (khách trả) / Hủy hàng hết hạn / Thu hồi.
 * URL: /returns
 *
 * Insert vào bảng Returns sẽ tự kích hoạt trigger TRG_ProcessReturn — servlet
 * này CHỈ chịu trách nhiệm validate đúng số liệu trước khi insert (không tự
 * cập nhật Batches.CurrentQuantity, DB trigger lo phần đó).
 *
 * Validate quan trọng nhất: 1 dòng hóa đơn (InvoiceID+BatchID) không được trả
 * vượt quá số lượng đã bán trừ đi số đã trả trước đó — tránh "trả khống" làm
 * sai lệch doanh thu/kho.
 */
@WebServlet("/returns")
public class ReturnsServlet extends HttpServlet {

    private final IReturnsDAO       returnsDAO  = new ReturnsDAO();
    private final IInvoiceDAO       invoiceDAO  = new InvoiceDAO();
    private final IInvoiceDetailDAO detailDAO   = new InvoiceDetailDAO();
    private final IBatchesDAO       batchesDAO  = new BatchesDAO();
    private final IMedicineDAO      medicineDAO = new MedicineDAO();
    private final IAccountDAO       accountDAO  = new AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        Account adminAcc = session != null ? (Account) session.getAttribute("adminAccount") : null;
        if (adminAcc == null || adminAcc.getRoleId() != 1) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        String action = req.getParameter("action");
        if (action == null) action = "list";

        switch (action) {
            case "list" -> showList(req, resp);
            case "new"  -> showForm(req, resp);
            default     -> showList(req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        HttpSession session = req.getSession(false);
        Account adminAcc = session != null ? (Account) session.getAttribute("adminAccount") : null;
        if (adminAcc == null || adminAcc.getRoleId() != 1) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        String action = req.getParameter("action");
        if ("save".equals(action)) {
            handleSave(req, resp, adminAcc);
        } else {
            resp.sendRedirect(req.getContextPath() + "/returns");
        }
    }

    // ── LIST ──────────────────────────────────────────────────────────────────
    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        List<Returns> returns = returnsDAO.findAll();

        Map<Integer, Account>  accountMap  = new HashMap<>();
        Map<Integer, Batches>  batchMap    = new HashMap<>();
        Map<Integer, Medicines> medicineMap = new HashMap<>();
        for (Returns r : returns) {
            accountMap.computeIfAbsent(r.getAccountId(), accountDAO::findById);
            Batches b = batchMap.computeIfAbsent(r.getBatchId(), batchesDAO::findById);
            if (b != null) medicineMap.computeIfAbsent(b.getMedicineId(), medicineDAO::findById);
        }

        req.setAttribute("returns",     returns);
        req.setAttribute("accountMap",  accountMap);
        req.setAttribute("batchMap",    batchMap);
        req.setAttribute("medicineMap", medicineMap);
        req.setAttribute("totalCount",  returns.size());
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/admin/returns-list.jsp").forward(req, resp);
    }

    // ── FORM (tạo mới) ───────────────────────────────────────────────────────
    private void showForm(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String invoiceIdStr = req.getParameter("invoiceId");
        String invoiceCode  = req.getParameter("invoiceCode");
        String batchIdStr   = req.getParameter("batchId");

        // Tìm theo mã hóa đơn (từ ô search ở form chọn nhanh) → resolve ra invoiceId rồi redirect
        if (!ValidationUtil.isBlank(invoiceCode) && ValidationUtil.isBlank(invoiceIdStr)) {
            Invoice found = invoiceDAO.findByCode(invoiceCode.trim().toUpperCase());
            if (found == null) {
                req.setAttribute("searchError", "Không tìm thấy hóa đơn mã \"" + invoiceCode + "\"!");
                req.setAttribute("mode", "CHOOSE");
                prepareChooseMode(req);
                SidebarHelper.load(req);
                req.getRequestDispatcher("/WEB-INF/views/admin/returns-form.jsp").forward(req, resp);
                return;
            }
            resp.sendRedirect(req.getContextPath() + "/returns?action=new&invoiceId=" + found.getInvoiceId());
            return;
        }

        if (!ValidationUtil.isBlank(invoiceIdStr)) {
            // ── Mode: KHÁCH TRẢ HÀNG (CUSTOMER_RETURN) ──
            int invoiceId = Integer.parseInt(invoiceIdStr);
            Invoice inv = invoiceDAO.findById(invoiceId);
            if (inv == null || !"COMPLETED".equals(inv.getStatus())) {
                resp.sendRedirect(req.getContextPath() + "/returns?msg=invalid-invoice");
                return;
            }
            List<InvoiceDetail> details = detailDAO.findByInvoice(invoiceId);
            // Số lượng còn được trả của mỗi dòng = đã bán - đã trả trước đó
            Map<Integer, Integer> returnableMap = new HashMap<>(); // key = batchId
            for (InvoiceDetail d : details) {
                int already = returnsDAO.sumReturnedQty(invoiceId, d.getBatchId());
                returnableMap.put(d.getBatchId(), Math.max(0, d.getQuantity() - already));
            }
            req.setAttribute("mode",         "CUSTOMER_RETURN");
            req.setAttribute("invoice",      inv);
            req.setAttribute("details",      details);
            req.setAttribute("returnableMap", returnableMap);

        } else if (!ValidationUtil.isBlank(batchIdStr)) {
            // ── Mode: HỦY HẾT HẠN / THU HỒI (EXPIRED_DESTROY | RECALL) ──
            int batchId = Integer.parseInt(batchIdStr);
            Batches batch = batchesDAO.findById(batchId);
            if (batch == null) {
                resp.sendRedirect(req.getContextPath() + "/returns?msg=invalid-batch");
                return;
            }
            Medicines medicine = medicineDAO.findById(batch.getMedicineId());
            req.setAttribute("mode",     "WRITE_OFF");
            req.setAttribute("batch",    batch);
            req.setAttribute("medicine", medicine);

        } else {
            // ── Mode: CHỌN — chưa biết tạo loại phiếu nào ──
            req.setAttribute("mode", "CHOOSE");
            prepareChooseMode(req);
        }

        SidebarHelper.load(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/returns-form.jsp").forward(req, resp);
    }

    /** Chuẩn bị danh sách lô hết hạn/sắp hết hạn để admin chọn nhanh cho mục Hủy hàng. */
    private void prepareChooseMode(HttpServletRequest req) {
        List<Batches> candidates = new ArrayList<>();
        candidates.addAll(batchesDAO.findExpired());
        candidates.addAll(batchesDAO.findExpiringSoon());
        Map<Integer, Medicines> medMap = new HashMap<>();
        for (Batches b : candidates) {
            medMap.computeIfAbsent(b.getMedicineId(), medicineDAO::findById);
        }
        req.setAttribute("expiringBatches", candidates);
        req.setAttribute("medMapChoose",    medMap);
    }

    // ── SAVE ──────────────────────────────────────────────────────────────────
    private void handleSave(HttpServletRequest req, HttpServletResponse resp, Account adminAcc)
            throws ServletException, IOException {
        List<String> errors = new ArrayList<>();
        String returnType = req.getParameter("returnType");
        String batchIdStr = req.getParameter("batchId");
        String qtyStr      = req.getParameter("quantity");
        String reason      = req.getParameter("reason");

        if (ValidationUtil.isBlank(returnType) ||
                !List.of("CUSTOMER_RETURN", "EXPIRED_DESTROY", "RECALL").contains(returnType)) {
            errors.add("Loại phiếu không hợp lệ!");
        }
        if (ValidationUtil.isBlank(batchIdStr)) errors.add("Vui lòng chọn lô thuốc!");
        if (ValidationUtil.isBlank(reason) || reason.trim().length() < 3) {
            errors.add("Vui lòng nhập lý do (tối thiểu 3 ký tự) — bắt buộc theo quy định!");
        }
        int quantity = 0;
        try {
            quantity = Integer.parseInt(qtyStr);
            if (quantity <= 0) errors.add("Số lượng phải lớn hơn 0!");
        } catch (Exception e) { errors.add("Số lượng không hợp lệ!"); }

        int batchId = ValidationUtil.isBlank(batchIdStr) ? 0 : Integer.parseInt(batchIdStr);
        Integer invoiceId = null;
        boolean restoreStock;

        if ("CUSTOMER_RETURN".equals(returnType)) {
            String invIdStr = req.getParameter("invoiceId");
            if (ValidationUtil.isBlank(invIdStr)) {
                errors.add("Thiếu thông tin hóa đơn!");
            } else {
                invoiceId = Integer.parseInt(invIdStr);
                Invoice inv = invoiceDAO.findById(invoiceId);
                if (inv == null || !"COMPLETED".equals(inv.getStatus())) {
                    errors.add("Hóa đơn không hợp lệ hoặc chưa hoàn tất!");
                } else if (errors.isEmpty() && batchId > 0) {
                    // Chặn trả vượt số đã bán trừ số đã trả trước đó
                    List<InvoiceDetail> details = detailDAO.findByInvoice(invoiceId);
                    InvoiceDetail matched = details.stream()
                            .filter(d -> d.getBatchId() == batchId).findFirst().orElse(null);
                    if (matched == null) {
                        errors.add("Lô này không thuộc hóa đơn đã chọn!");
                    } else {
                        int already = returnsDAO.sumReturnedQty(invoiceId, batchId);
                        int maxReturnable = matched.getQuantity() - already;
                        if (quantity > maxReturnable) {
                            errors.add("Số lượng trả (" + quantity + ") vượt quá số có thể trả (" + maxReturnable + ")!");
                        }
                    }
                }
            }
            // "Hàng còn nguyên, có thể bán lại?" — admin tự quyết định qua checkbox
            restoreStock = "on".equals(req.getParameter("restoreStock"));
        } else {
            // EXPIRED_DESTROY / RECALL — không bao giờ cộng lại kho
            restoreStock = false;
            if (batchId > 0) {
                Batches batch = batchesDAO.findById(batchId);
                if (batch == null) {
                    errors.add("Lô thuốc không tồn tại!");
                } else if (quantity > batch.getCurrentQuantity()) {
                    errors.add("Số lượng hủy (" + quantity + ") vượt quá tồn kho hiện tại (" + batch.getCurrentQuantity() + ")!");
                }
            }
        }

        if (!errors.isEmpty()) {
            req.setAttribute("errors", errors);
            forwardToFormWithErrors(req, resp, returnType, batchId, invoiceId, qtyStr, reason);
            return;
        }

        Returns r = new Returns();
        r.setReturnType(returnType);
        r.setBatchId(batchId);
        r.setInvoiceId(invoiceId);
        r.setQuantity(quantity);
        r.setReason(reason.trim());
        r.setAccountId(adminAcc.getAccountId());
        r.setRestoreStock(restoreStock);

        int newId = returnsDAO.insert(r);
        if (newId > 0) {
            AuditHelper.log(req, "Tạo phiếu trả/hủy hàng", "Returns", newId,
                    returnType + " — SL: " + quantity + " — " + reason);
            resp.sendRedirect(req.getContextPath() + "/returns?msg=created");
        } else {
            resp.sendRedirect(req.getContextPath() + "/returns?msg=error");
        }
    }

    /** Dựng lại đúng context của form (CUSTOMER_RETURN/WRITE_OFF) rồi forward — KHÔNG redirect,
     *  để giữ nguyên "errors" + dữ liệu admin vừa nhập (qty/reason) trong request hiện tại. */
    private void forwardToFormWithErrors(HttpServletRequest req, HttpServletResponse resp,
                                         String returnType, int batchId, Integer invoiceId,
                                         String preservedQty, String preservedReason)
            throws ServletException, IOException {
        req.setAttribute("preservedQty",    preservedQty);
        req.setAttribute("preservedReason", preservedReason);
        req.setAttribute("preservedBatchId", batchId);

        if ("CUSTOMER_RETURN".equals(returnType) && invoiceId != null) {
            Invoice inv = invoiceDAO.findById(invoiceId);
            List<InvoiceDetail> details = detailDAO.findByInvoice(invoiceId);
            Map<Integer, Integer> returnableMap = new HashMap<>();
            for (InvoiceDetail d : details) {
                int already = returnsDAO.sumReturnedQty(invoiceId, d.getBatchId());
                returnableMap.put(d.getBatchId(), Math.max(0, d.getQuantity() - already));
            }
            req.setAttribute("mode",          "CUSTOMER_RETURN");
            req.setAttribute("invoice",        inv);
            req.setAttribute("details",        details);
            req.setAttribute("returnableMap",  returnableMap);
        } else if (batchId > 0) {
            Batches batch = batchesDAO.findById(batchId);
            Medicines medicine = batch != null ? medicineDAO.findById(batch.getMedicineId()) : null;
            req.setAttribute("mode",     "WRITE_OFF");
            req.setAttribute("batch",    batch);
            req.setAttribute("medicine", medicine);
        } else {
            req.setAttribute("mode", "CHOOSE");
            prepareChooseMode(req);
        }

        SidebarHelper.load(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/returns-form.jsp").forward(req, resp);
    }
}