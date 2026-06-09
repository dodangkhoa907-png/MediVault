package com.medivault.controller.pos;

import com.medivault.dao.*;
import com.medivault.dao.interfaces.*;
import com.medivault.entity.*;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.util.List;

@WebServlet("/pos")
public class PosServlet extends HttpServlet {

    private final IMedicineDAO      medicineDAO  = new MedicineDAO();
    private final IBatchesDAO       batchesDAO   = new BatchesDAO();
    private final ICustomerDAO      customerDAO  = new CustomerDAO();
    private final IInvoiceDAO       invoiceDAO   = new InvoiceDAO();
    private final ICategoryDAO      categoryDAO  = new CategoryDAO();
    private final IStaffAuditLogDAO staffAuditDAO = new StaffAuditLogDAO();

    private static final int POS_ACCOUNT_ID = 1;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");

        if ("search".equals(action)) {
            String q = req.getParameter("q");
            List<Medicines> list = (q != null && !q.trim().isEmpty())
                    ? medicineDAO.search(q.trim()) : medicineDAO.findAll();
            resp.setContentType("application/json;charset=UTF-8");
            PrintWriter out = resp.getWriter();
            out.print("[");
            for (int i = 0; i < list.size(); i++) {
                Medicines m = list.get(i);
                int totalQty = batchesDAO.getTotalQuantity(m.getMedicineId());
                Batches nb   = batchesDAO.findNearestExpiry(m.getMedicineId());
                String expiry  = nb != null ? nb.getExpiryDate().toString() : "";
                String batchNo = nb != null ? nb.getBatchNumber() : "";
                if (i > 0) out.print(",");
                out.printf("{\"id\":%d,\"code\":\"%s\",\"name\":\"%s\",\"unit\":\"%s\"," +
                                "\"price\":%s,\"stock\":%d,\"catId\":%d," +
                                "\"rx\":%b,\"expiry\":\"%s\",\"batchNo\":\"%s\"}",
                        m.getMedicineId(), esc(m.getMedicineCode()),
                        esc(m.getMedicineName()), esc(m.getUnit()),
                        m.getSellingPrice(), totalQty, m.getCategoryId(),
                        m.isPrescriptionRequired(), expiry, esc(batchNo));
            }
            out.print("]");
            return;
        }

        if ("find-customer".equals(action)) {
            String phone = req.getParameter("phone");
            Customer c = customerDAO.findByPhone(phone);
            resp.setContentType("application/json;charset=UTF-8");
            PrintWriter out = resp.getWriter();
            if (c == null) {
                out.print("{\"found\":false}");
            } else {
                out.printf("{\"found\":true,\"id\":%d,\"name\":\"%s\",\"phone\":\"%s\"}",
                        c.getCustomerId(), esc(c.getCustomerName()), esc(c.getPhone()));
            }
            return;
        }
        if ("inventory".equals(action)) {
            resp.setContentType("application/json;charset=UTF-8");
            PrintWriter out = resp.getWriter();
            List<Medicines> meds = medicineDAO.findAll();
            out.print("[");
            boolean first = true;
            for (Medicines m : meds) {
                List<Batches> batches = batchesDAO.findAllByMedicine(m.getMedicineId());
                int totalQty = batchesDAO.getTotalQuantity(m.getMedicineId());
                for (Batches b : batches) {
                    if (!first) out.print(",");
                    out.printf("{\"medId\":%d,\"medName\":\"%s\",\"medCode\":\"%s\",\"unit\":\"%s\"," +
                                    "\"totalStock\":%d,\"batchNo\":\"%s\",\"expiryDate\":\"%s\"," +
                                    "\"currentQty\":%d,\"initialQty\":%d,\"importPrice\":%s}",
                            m.getMedicineId(), esc(m.getMedicineName()), esc(m.getMedicineCode()),
                            esc(m.getUnit()), totalQty, esc(b.getBatchNumber()),
                            b.getExpiryDate().toString(), b.getCurrentQuantity(),
                            b.getInitialQuantity(), b.getImportPrice());
                    first = false;
                }
                // Thuốc không có lô nào vẫn hiển thị
                if (batches.isEmpty()) {
                    if (!first) out.print(",");
                    out.printf("{\"medId\":%d,\"medName\":\"%s\",\"medCode\":\"%s\",\"unit\":\"%s\"," +
                                    "\"totalStock\":0,\"batchNo\":\"\",\"expiryDate\":\"\"," +
                                    "\"currentQty\":0,\"initialQty\":0,\"importPrice\":\"0\"}",
                            m.getMedicineId(), esc(m.getMedicineName()),
                            esc(m.getMedicineCode()), esc(m.getUnit()));
                    first = false;
                }
            }
            out.print("]");
            return;
        }

        req.setAttribute("categories", categoryDAO.findAll());
        req.setAttribute("medicines",  medicineDAO.findAll());
        req.getRequestDispatcher("/WEB-INF/views/pos.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();

        String action = req.getParameter("action");

        if ("complete-sale".equals(action)) {
            try {
                HttpSession session = req.getSession(false);
                Account acc = null;
                if (session != null) {
                    // Ưu tiên lấy staffAccount theo uid nếu có
                    String uid = req.getParameter("uid");
                    if (uid != null && !uid.isEmpty())
                        acc = (Account) session.getAttribute("staffAccount_" + uid);
                    if (acc == null)
                        acc = (Account) session.getAttribute("adminAccount");
                }
                int accountId = acc != null ? acc.getAccountId() : POS_ACCOUNT_ID;

                Integer customerId = parseIntOrNull(req.getParameter("customerId"));
                String  payMethod  = req.getParameter("paymentMethod");
                String  discStr    = req.getParameter("discount");
                BigDecimal discount = (discStr != null && !discStr.isEmpty())
                        ? new BigDecimal(discStr) : BigDecimal.ZERO;

                String[] medIdStrs = req.getParameterValues("medId[]");
                String[] qtyStrs   = req.getParameterValues("qty[]");

                if (medIdStrs == null || medIdStrs.length == 0) {
                    out.print("{\"ok\":false,\"msg\":\"Giỏ hàng trống!\"}");
                    return;
                }

                int[] medicineIds = new int[medIdStrs.length];
                int[] quantities  = new int[qtyStrs.length];
                for (int i = 0; i < medIdStrs.length; i++) {
                    medicineIds[i] = Integer.parseInt(medIdStrs[i]);
                    quantities[i]  = Integer.parseInt(qtyStrs[i]);
                }

                int invoiceId = invoiceDAO.completeSaleTransaction(
                        accountId, customerId, payMethod, discount, medicineIds, quantities);

                if (invoiceId > 0) {
                    // Ghi log giao dịch bán hàng vào StaffAuditLogs
                    staffAuditDAO.log(new StaffAuditLog(
                            accountId,
                            "Thanh toán bán hàng",
                            "Lập thành công hóa đơn mã ID: " + invoiceId,
                            req.getRemoteAddr()
                    ));

                    Invoice inv = invoiceDAO.findById(invoiceId);
                    out.printf("{\"ok\":true,\"invoiceId\":%d,\"invoiceCode\":\"%s\",\"total\":%s}",
                            invoiceId,
                            inv != null ? esc(inv.getInvoiceCode()) : "",
                            inv != null ? inv.getFinalAmount() : "0");
                } else {
                    out.print("{\"ok\":false,\"msg\":\"Thanh toán thất bại! Kiểm tra lại tồn kho.\"}");
                }

            } catch (Exception e) {
                e.printStackTrace();
                out.printf("{\"ok\":false,\"msg\":\"Lỗi hệ thống: %s\"}", esc(e.getMessage()));
            }
            return;
        }

        out.print("{\"ok\":false,\"msg\":\"Unknown action\"}");
    }

    // ── Helpers ──────────────────────────────────────────────
    private Integer parseIntOrNull(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return null; }
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\","\\\\").replace("\"","\\\"").replace("\n"," ").replace("\r","");
    }
}