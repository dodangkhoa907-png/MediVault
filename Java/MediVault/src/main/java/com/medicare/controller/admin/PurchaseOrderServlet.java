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
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/admin/purchase-order-form.jsp").forward(req, resp);
    }

    // ── SAVE (tạo đơn mới) ────────────────────────────────────────────────────
    private void handleSave(HttpServletRequest req, HttpServletResponse resp, Account adminAcc)
            throws ServletException, IOException {
        List<String> errors = new ArrayList<>();
        String supId = req.getParameter("supplierId");
        String notes = req.getParameter("notes");

        if (ValidationUtil.isBlank(supId)) errors.add("Vui lòng chọn nhà cung cấp!");

        if (!errors.isEmpty()) {
            req.setAttribute("errors", errors);
            showForm(req, resp);
            return;
        }

        PurchaseOrders po = new PurchaseOrders();
        po.setSupplierId(Integer.parseInt(supId));
        po.setAccountId(adminAcc.getAccountId());
        po.setNotes(notes != null ? notes.trim() : null);

        int poId = poDAO.insert(po);
        if (poId > 0) {
            AuditHelper.log(req, "Tạo đơn đặt hàng", "PurchaseOrder", poId,
                    "Tạo đơn đặt hàng mới từ NCC ID " + supId);
            resp.sendRedirect(req.getContextPath() + "/purchase-orders?action=detail&id=" + poId + "&msg=created");
        } else {
            resp.sendRedirect(req.getContextPath() + "/purchase-orders?msg=error");
        }
    }

    private int parseIntOr(String s, int def) {
        if (s == null || s.isEmpty()) return def;
        try { return Integer.parseInt(s); } catch (NumberFormatException e) { return def; }
    }
}