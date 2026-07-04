package com.medicare.controller.admin;

import com.medicare.dao.*;
import com.medicare.entity.*;
import com.medicare.util.AuditHelper;
import com.medicare.util.SidebarHelper;
import com.medicare.util.ValidationUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.*;

/**
 * PurchaseOrderServlet — Quản lý Đơn đặt hàng (PurchaseOrders).
 * URL: /purchase-orders
 *
 * Mỗi lô thuốc (Batches) bắt buộc thuộc 1 đơn đặt hàng (FK_Batch_PO NOT NULL).
 * Servlet này cho phép tạo đơn (chọn nhà cung cấp) trước, sau đó các lô hàng
 * được thêm vào (từ trang Kho thuốc → batch-form.jsp) sẽ tham chiếu đến đây.
 */
@WebServlet("/purchase-orders")
public class PurchaseOrderServlet extends HttpServlet {

    private final PurchaseOrderDAO poDAO       = new PurchaseOrderDAO();
    private final BatchesDAO       batchesDAO  = new BatchesDAO();
    private final SupplierDAO      supplierDAO = new SupplierDAO();
    private final AccountDAO       accountDAO  = new AccountDAO();
    private final MedicineDAO      medicineDAO = new MedicineDAO();

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
            case "list"   -> showList(req, resp);
            case "detail" -> showDetail(req, resp);
            case "new"    -> showForm(req, resp);
            default       -> showList(req, resp);
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
            resp.sendRedirect(req.getContextPath() + "/purchase-orders");
        }
    }

    // ── LIST ──────────────────────────────────────────────────────────────────
    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        List<PurchaseOrders> pos = poDAO.findAll();

        Map<Integer, Supplier> supplierMap = new HashMap<>();
        Map<Integer, Account>  accountMap  = new HashMap<>();
        Map<Integer, Integer>  batchCountMap = new HashMap<>();
        for (PurchaseOrders po : pos) {
            supplierMap.computeIfAbsent(po.getSupplierId(), supplierDAO::findById);
            accountMap.computeIfAbsent(po.getAccountId(), accountDAO::findById);
            batchCountMap.put(po.getPoId(), poDAO.countBatches(po.getPoId()));
        }

        req.setAttribute("pos",           pos);
        req.setAttribute("supplierMap",   supplierMap);
        req.setAttribute("accountMap",    accountMap);
        req.setAttribute("batchCountMap", batchCountMap);
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/admin/purchase-order-list.jsp").forward(req, resp);
    }

    // ── DETAIL ────────────────────────────────────────────────────────────────
    private void showDetail(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        int id = parseIntOr(req.getParameter("id"), 0);
        PurchaseOrders po = poDAO.findById(id);
        if (po == null) {
            resp.sendRedirect(req.getContextPath() + "/purchase-orders?msg=not-found");
            return;
        }

        Supplier supplier = supplierDAO.findById(po.getSupplierId());
        Account  creator  = accountDAO.findById(po.getAccountId());
        List<Batches> batches = batchesDAO.findByPO(id);

        Map<Integer, Medicines> medicineMap = new HashMap<>();
        for (Batches b : batches) {
            medicineMap.computeIfAbsent(b.getMedicineId(), medicineDAO::findById);
        }

        req.setAttribute("po",          po);
        req.setAttribute("supplier",    supplier);
        req.setAttribute("creator",     creator);
        req.setAttribute("batches",     batches);
        req.setAttribute("medicineMap", medicineMap);
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/admin/purchase-order-detail.jsp").forward(req, resp);
    }

    // ── FORM (tạo mới) ───────────────────────────────────────────────────────
    private void showForm(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setAttribute("suppliers", supplierDAO.findAllActive());
        req.setAttribute("medicines", medicineDAO.findAll()); // cho dropdown dòng hàng
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/admin/purchase-order-form.jsp").forward(req, resp);
    }

    // ── SAVE (tạo phiếu nhập nhiều dòng → PO + N Batches trong 1 transaction) ──
    private void handleSave(HttpServletRequest req, HttpServletResponse resp, Account adminAcc)
            throws ServletException, IOException {
        List<String> errors = new ArrayList<>();
        String supId  = req.getParameter("supplierId");
        String notes  = req.getParameter("notes");
        String status = req.getParameter("status");
        String payment = req.getParameter("paymentMethod");
        BigDecimal discount = parseMoney(req.getParameter("discountAmount"));

        if (ValidationUtil.isBlank(supId)) errors.add("Vui lòng chọn nhà cung cấp!");

        // Các dòng hàng (mỗi dòng = 1 lô)
        String[] medIds   = req.getParameterValues("lineMedicineId");
        String[] qtys     = req.getParameterValues("lineQty");
        String[] prices   = req.getParameterValues("linePrice");
        String[] batchNos = req.getParameterValues("lineBatchNo");
        String[] expiries = req.getParameterValues("lineExpiry");
        String[] mfDates  = req.getParameterValues("lineMfDate");

        List<Batches> lines = new ArrayList<>();
        BigDecimal totalGoods = BigDecimal.ZERO;
        int n = medIds != null ? medIds.length : 0;
        for (int i = 0; i < n; i++) {
            String midS = medIds[i];
            if (ValidationUtil.isBlank(midS)) continue; // dòng trống → bỏ qua
            int row = i + 1;
            int medId = 0, qty = 0;
            try { medId = Integer.parseInt(midS); } catch (Exception e) { errors.add("Dòng " + row + ": thuốc không hợp lệ."); continue; }
            try { qty = Integer.parseInt(qtys[i]); } catch (Exception ignored) {}
            BigDecimal price = parseMoney(prices != null ? prices[i] : null);
            String batchNo = batchNos != null ? batchNos[i] : null;
            String expiryS = expiries != null ? expiries[i] : null;

            if (qty <= 0)                         errors.add("Dòng " + row + ": số lượng phải > 0.");
            if (ValidationUtil.isBlank(batchNo))  errors.add("Dòng " + row + ": thiếu số lô.");
            LocalDate expiry = null;
            if (ValidationUtil.isBlank(expiryS)) {
                errors.add("Dòng " + row + ": thiếu hạn dùng.");
            } else {
                try {
                    expiry = LocalDate.parse(expiryS);
                    if (!expiry.isAfter(LocalDate.now())) errors.add("Dòng " + row + ": HSD phải sau hôm nay.");
                } catch (Exception e) { errors.add("Dòng " + row + ": HSD không hợp lệ."); }
            }
            if (!errors.isEmpty()) continue;

            Batches b = new Batches();
            b.setMedicineId(medId);
            b.setBatchNumber(batchNo.trim());
            b.setExpiryDate(expiry);
            b.setImportPrice(price);
            b.setInitialQuantity(qty);
            b.setImportDate(LocalDate.now());
            if (mfDates != null && !ValidationUtil.isBlank(mfDates[i])) {
                try { b.setManufactureDate(LocalDate.parse(mfDates[i])); } catch (Exception ignored) {}
            }
            lines.add(b);
            totalGoods = totalGoods.add(price.multiply(BigDecimal.valueOf(qty)));
        }

        if (lines.isEmpty() && errors.isEmpty())
            errors.add("Phiếu nhập phải có ít nhất 1 dòng thuốc!");

        if (!errors.isEmpty()) {
            req.setAttribute("errors", errors);
            showForm(req, resp);
            return;
        }

        PurchaseOrders po = new PurchaseOrders();
        po.setSupplierId(Integer.parseInt(supId));
        po.setAccountId(adminAcc.getAccountId());
        po.setNotes(ValidationUtil.isBlank(notes) ? null : notes.trim());
        po.setStatus("PENDING".equals(status) ? "PENDING" : "COMPLETED");
        po.setPaymentMethod(ValidationUtil.isBlank(payment) ? null : payment);
        po.setDiscountAmount(discount);
        po.setTotalValue(totalGoods); // giá trị hàng (chưa trừ CK)

        int poId = poDAO.createWithBatches(po, lines);
        if (poId > 0) {
            AuditHelper.log(req, "Tạo phiếu nhập kho", "PurchaseOrder", poId,
                    "Phiếu nhập " + lines.size() + " lô từ NCC ID " + supId
                    + " — tổng " + totalGoods.toPlainString() + "đ");
            resp.sendRedirect(req.getContextPath() + "/purchase-orders?action=detail&id=" + poId + "&msg=created");
        } else {
            req.setAttribute("errors", List.of("Lỗi khi lưu phiếu nhập — vui lòng thử lại."));
            showForm(req, resp);
        }
    }

    private BigDecimal parseMoney(String s) {
        if (s == null) return BigDecimal.ZERO;
        s = s.replaceAll("[^0-9.]", "");
        if (s.isEmpty()) return BigDecimal.ZERO;
        try { return new BigDecimal(s); } catch (Exception e) { return BigDecimal.ZERO; }
    }

    private int parseIntOr(String s, int def) {
        if (s == null || s.isEmpty()) return def;
        try { return Integer.parseInt(s); } catch (NumberFormatException e) { return def; }
    }
}