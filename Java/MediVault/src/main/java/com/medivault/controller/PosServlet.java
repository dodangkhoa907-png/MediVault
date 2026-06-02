package com.medivault.controller;

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

/**
 * PosServlet — Giao diện bán hàng PUBLIC (không cần đăng nhập)
 * Mọi tương tác với DB đều qua Interface, không gọi DAO trực tiếp.
 */
@WebServlet("/pos")
public class PosServlet extends HttpServlet {

    // ── Chỉ khai báo qua Interface ──
    private final IMedicineDAO  medicineDAO  = new MedicineDAO();
    private final IBatchesDAO   batchesDAO   = new BatchesDAO();
    private final ICustomerDAO  customerDAO  = new CustomerDAO();
    private final IInvoiceDAO   invoiceDAO   = new InvoiceDAO();
    private final ICategoryDAO  categoryDAO  = new CategoryDAO();

    // AccountID mặc định cho POS không đăng nhập (account "pos" hoặc account hệ thống)
    private static final int POS_ACCOUNT_ID = 1;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");

        // ── API: Tìm kiếm thuốc → JSON ──
        if ("search".equals(action)) {
            String q = req.getParameter("q");
            List<Medicines> list = (q != null && !q.trim().isEmpty())
                    ? medicineDAO.search(q.trim())
                    : medicineDAO.findAll();
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

        // ── API: Tìm khách hàng → JSON ──
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

        // ── Serve POS Page ──
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
                // Lấy accountId từ session nếu có, không thì dùng POS_ACCOUNT_ID
                HttpSession session = req.getSession(false);
                Account acc = session != null ? (Account) session.getAttribute("staffAccount") : null;
                if (acc == null) acc = session != null ? (Account) session.getAttribute("adminAccount") : null;
                int accountId = acc != null ? acc.getAccountId() : POS_ACCOUNT_ID;

                Integer customerId  = parseIntOrNull(req.getParameter("customerId"));
                String  payMethod   = req.getParameter("paymentMethod");
                String  discStr     = req.getParameter("discount");
                BigDecimal discount = (discStr != null && !discStr.isEmpty())
                        ? new BigDecimal(discStr) : BigDecimal.ZERO;

                // Bước 1: Tạo PENDING
                int invoiceId = invoiceDAO.createPending(
                        accountId, null, customerId, null, payMethod);
                if (invoiceId < 0) {
                    out.print("{\"ok\":false,\"msg\":\"Không thể tạo hóa đơn!\"}");
                    return;
                }

                // Bước 2: Thêm từng sản phẩm FIFO
                String[] medIds = req.getParameterValues("medId[]");
                String[] qtys   = req.getParameterValues("qty[]");
                if (medIds != null) {
                    for (int i = 0; i < medIds.length; i++) {
                        int medId = Integer.parseInt(medIds[i]);
                        int qty   = Integer.parseInt(qtys[i]);
                        if (!invoiceDAO.addItemByFIFO(invoiceId, medId, qty)) {
                            invoiceDAO.cancel(invoiceId);
                            out.printf("{\"ok\":false,\"msg\":\"Thuốc ID %d không đủ tồn kho!\"}", medId);
                            return;
                        }
                    }
                }

                // Bước 3: Hoàn tất
                if (invoiceDAO.complete(invoiceId, discount)) {
                    Invoice inv = invoiceDAO.findById(invoiceId);
                    out.printf("{\"ok\":true,\"invoiceId\":%d,\"invoiceCode\":\"%s\",\"total\":%s}",
                            invoiceId,
                            inv != null ? esc(inv.getInvoiceCode()) : "",
                            inv != null ? inv.getFinalAmount() : "0");
                } else {
                    invoiceDAO.cancel(invoiceId);
                    out.print("{\"ok\":false,\"msg\":\"Hoàn tất hóa đơn thất bại!\"}");
                }

            } catch (Exception e) {
                e.printStackTrace();
                out.printf("{\"ok\":false,\"msg\":\"Lỗi hệ thống: %s\"}", esc(e.getMessage()));
            }
            return;
        }

        out.print("{\"ok\":false,\"msg\":\"Unknown action\"}");
    }

    private Integer parseIntOrNull(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (Exception e) { return null; }
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\","\\\\").replace("\"","\\\"").replace("\n"," ").replace("\r","");
    }
}