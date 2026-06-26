package com.medicare.controller.pos;

import com.medicare.dao.*;
import com.medicare.dao.interfaces.*;
import com.medicare.entity.*;
import com.medicare.service.SaleService;
import com.medicare.service.ServiceResult;
import com.medicare.service.interfaces.ISaleService;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/pos")
public class PosServlet extends HttpServlet {

    private final IMedicineDAO  medicineDAO  = new MedicineDAO();
    private final IBatchesDAO   batchesDAO   = new BatchesDAO();
    private final ICustomerDAO  customerDAO  = new CustomerDAO();
    private final ICategoryDAO  categoryDAO  = new CategoryDAO();
    private final ISaleService  saleService  = new SaleService();

    private static final int POS_ACCOUNT_ID = 1;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        resp.setContentType("text/html; charset=UTF-8");

        String action = req.getParameter("action");

        if ("search".equals(action)) {
            String q = req.getParameter("q");
            // searchWithStock / findAllWithStock: 1 JOIN query thay N+1
            List<Medicines> list = (q != null && !q.trim().isEmpty())
                    ? medicineDAO.searchWithStock(q.trim())
                    : medicineDAO.findAllWithStock();
            resp.setContentType("application/json;charset=UTF-8");
            PrintWriter out = resp.getWriter();
            out.print("[");
            for (int i = 0; i < list.size(); i++) {
                Medicines m = list.get(i);
                if (i > 0) out.print(",");
                out.printf("{\"id\":%d,\"code\":\"%s\",\"name\":\"%s\",\"unit\":\"%s\"," +
                                "\"price\":%s,\"stock\":%d,\"catId\":%d," +
                                "\"rx\":%b,\"expiry\":\"%s\",\"batchNo\":\"%s\"}",
                        m.getMedicineId(), esc(m.getMedicineCode()),
                        esc(m.getMedicineName()), esc(m.getUnit()),
                        m.getSellingPrice(), m.getTotalStock(), m.getCategoryId(),
                        m.isPrescriptionRequired(),
                        esc(m.getNearestExpiry()), esc(m.getNearestBatchNo()));
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
            // Single JOIN query: medicine + all batches — thay 1000+ queries
            resp.setContentType("application/json;charset=UTF-8");
            PrintWriter out = resp.getWriter();
            out.print("[");
            String sql =
                "WITH bs AS (" +
                "  SELECT MedicineID, ISNULL(SUM(CurrentQuantity),0) AS TotalStock" +
                "  FROM Batches WHERE ExpiryDate > CAST(GETDATE() AS DATE) GROUP BY MedicineID" +
                ")" +
                "SELECT m.MedicineID, m.MedicineName, m.MedicineCode, m.Unit," +
                "  ISNULL(bs.TotalStock,0) AS TotalStock," +
                "  b.BatchNumber, CONVERT(VARCHAR(10),b.ExpiryDate,120) AS ExpiryDate," +
                "  b.CurrentQuantity, b.InitialQuantity, b.ImportPrice" +
                " FROM Medicines m" +
                " LEFT JOIN bs ON bs.MedicineID = m.MedicineID" +
                " LEFT JOIN Batches b ON b.MedicineID = m.MedicineID" +
                " WHERE m.Status = 1" +
                " ORDER BY m.MedicineName, b.ExpiryDate DESC";
            try (java.sql.Connection cn = com.medicare.config.DBContext.getConnection();
                 java.sql.PreparedStatement ps = cn.prepareStatement(sql);
                 java.sql.ResultSet rs = ps.executeQuery()) {
                boolean first = true;
                while (rs.next()) {
                    if (!first) out.print(",");
                    out.printf("{\"medId\":%d,\"medName\":\"%s\",\"medCode\":\"%s\",\"unit\":\"%s\"," +
                                    "\"totalStock\":%d,\"batchNo\":\"%s\",\"expiryDate\":\"%s\"," +
                                    "\"currentQty\":%d,\"initialQty\":%d,\"importPrice\":\"%s\"}",
                            rs.getInt("MedicineID"), esc(rs.getNString("MedicineName")),
                            esc(rs.getString("MedicineCode")), esc(rs.getNString("Unit")),
                            rs.getInt("TotalStock"),
                            esc(rs.getString("BatchNumber") != null ? rs.getString("BatchNumber") : ""),
                            rs.getString("ExpiryDate") != null ? rs.getString("ExpiryDate") : "",
                            rs.getInt("CurrentQuantity"), rs.getInt("InitialQuantity"),
                            rs.getBigDecimal("ImportPrice") != null ? rs.getBigDecimal("ImportPrice").toPlainString() : "0");
                    first = false;
                }
            } catch (Exception e) { e.printStackTrace(); }
            out.print("]");
            return;
        }

        // Single CTE query thay N+1 (getTotalQuantity + findNearestExpiry per medicine)
        List<Medicines> medicines = medicineDAO.findAllWithStock();
        Map<Integer, Integer> stockMap   = new HashMap<>();
        Map<Integer, String>  batchNoMap = new HashMap<>();
        Map<Integer, String>  expiryMap  = new HashMap<>();
        for (Medicines m : medicines) {
            int mid = m.getMedicineId();
            stockMap.put(mid,   m.getTotalStock());
            batchNoMap.put(mid, m.getNearestBatchNo() != null ? m.getNearestBatchNo() : "");
            expiryMap.put(mid,  m.getNearestExpiry()  != null ? m.getNearestExpiry()  : "");
        }
        req.setAttribute("categories", categoryDAO.findAll());
        req.setAttribute("medicines",  medicines);
        req.setAttribute("stockMap",   stockMap);
        req.setAttribute("batchNoMap", batchNoMap);
        req.setAttribute("expiryMap",  expiryMap);

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

                int[] medicineIds = medIdStrs != null ? new int[medIdStrs.length] : new int[0];
                int[] quantities  = qtyStrs   != null ? new int[qtyStrs.length]   : new int[0];
                for (int i = 0; i < medicineIds.length; i++) {
                    medicineIds[i] = Integer.parseInt(medIdStrs[i]);
                    quantities[i]  = Integer.parseInt(qtyStrs[i]);
                }

                ServiceResult<Invoice> result = saleService.completeSale(
                        accountId, customerId, payMethod, discount,
                        medicineIds, quantities, req.getRemoteAddr());

                if (result.isOk()) {
                    Invoice inv = result.getData();
                    out.printf("{\"ok\":true,\"invoiceId\":%d,\"invoiceCode\":\"%s\",\"total\":%s}",
                            inv != null ? inv.getInvoiceId()  : 0,
                            inv != null ? esc(inv.getInvoiceCode()) : "",
                            inv != null ? inv.getFinalAmount() : "0");
                } else {
                    out.printf("{\"ok\":false,\"msg\":\"%s\"}", esc(result.firstError()));
                }

            } catch (Throwable e) {
                e.printStackTrace();
                String errMsg = e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName();
                out.printf("{\"ok\":false,\"msg\":\"Lỗi hệ thống: %s\"}", esc(errMsg));
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