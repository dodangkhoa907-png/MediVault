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
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/pos")
public class PosServlet extends HttpServlet {

    private final IMedicineDAO   medicineDAO   = new MedicineDAO();
    private final IBatchesDAO    batchesDAO    = new BatchesDAO();
    private final ICustomerDAO   customerDAO   = new CustomerDAO();
    private final ICategoryDAO   categoryDAO   = new CategoryDAO();
    private final ISaleService   saleService   = new SaleService();
    private final IAccountDAO    accountDAO    = new AccountDAO();
    private final IAttendanceDAO attendanceDAO = new AttendanceDAO();
    private final IShiftScheduleDAO scheduleDAO = new ShiftScheduleDAO();

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

        if ("face-descriptors".equals(action)) {
            // Trả JSON: [{accountId, name, descriptor}] cho client-side face matching
            resp.setContentType("application/json;charset=UTF-8");
            PrintWriter out = resp.getWriter();
            List<Account> enrolled = accountDAO.findAllWithFaceVector();
            out.print("[");
            boolean first = true;
            for (Account a : enrolled) {
                if (a.getFaceVector() == null || a.getFaceVector().isEmpty()) continue;
                if (!first) out.print(",");
                String name = a.getFullName() != null ? a.getFullName() : a.getUsername();
                out.printf("{\"accountId\":%d,\"name\":\"%s\",\"descriptor\":%s}",
                        a.getAccountId(), esc(name), a.getFaceVector());
                first = false;
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
        if ("shift-summary".equals(action)) {
            resp.setContentType("application/json;charset=UTF-8");
            PrintWriter out = resp.getWriter();
            handleShiftSummary(req, out);
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

        // Multi-POS: đọc station từ query param (nếu có), lưu vào session
        String stationParam = req.getParameter("station");
        if (stationParam != null && !stationParam.isEmpty()) {
            try {
                int st = Integer.parseInt(stationParam);
                if (st >= 1 && st <= 10) req.getSession(true).setAttribute("posStation", st);
            } catch (NumberFormatException ignored) {}
        }

        // Tính screen state từ session
        HttpSession sess = req.getSession(false);
        Integer posStationObj = sess != null ? (Integer) sess.getAttribute("posStation") : null;
        int posStation = posStationObj != null ? posStationObj : 0;
        String posStateS  = sess != null ? (String)  sess.getAttribute("posState")     : null;
        Account staffAccS = sess != null ? (Account) sess.getAttribute("staffAccount") : null;
        boolean hasStaff  = staffAccS != null && staffAccS.getRoleId() != 1;

        String screenState;
        if (posStation == 0)                              screenState = "STATION_SELECT";
        else if (hasStaff && "ACTIVE".equals(posStateS)) screenState = "ACTIVE";
        else if (hasStaff && "PAUSED".equals(posStateS)) screenState = "PAUSED";
        else                                              screenState = "IDLE";

        req.setAttribute("screenState", screenState);
        req.setAttribute("categories",  categoryDAO.findAll());

        // Luôn tải danh sách thuốc — POS bán hàng bình thường không cần điểm danh
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

        if ("set-station".equals(action)) {
            String stStr = req.getParameter("station");
            if (stStr != null) {
                try {
                    int st = Integer.parseInt(stStr);
                    if (st >= 1 && st <= 10) {
                        req.getSession(true).setAttribute("posStation", st);
                        out.print("{\"ok\":true,\"station\":" + st + "}");
                    } else {
                        out.print("{\"ok\":false}");
                    }
                } catch (NumberFormatException e) {
                    out.print("{\"ok\":false}");
                }
            } else {
                out.print("{\"ok\":false}");
            }
            return;
        }

        if ("open-shift".equals(action))  { handleOpenShift(req, out); return; }
        if ("pos-pause".equals(action))   { req.getSession(true).setAttribute("posState","PAUSED");  out.print("{\"ok\":true}"); return; }
        if ("pos-resume".equals(action))  { req.getSession(true).setAttribute("posState","ACTIVE");  out.print("{\"ok\":true}"); return; }
        if ("pos-end-shift".equals(action)) { handleEndShift(req, out); return; }

        if ("pos-face-checkin".equals(action)) {
            handlePosFaceCheckin(req, resp, out);
            return;
        }

        if ("create-qr".equals(action))       { handleCreateQr(req, out);      return; }
        if ("check-qr-status".equals(action)) { handleCheckQrStatus(req, out); return; }
        if ("cancel-qr".equals(action))       { handleCancelQr(req, out);      return; }

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

                // Đọc posStation từ request hoặc session
                Integer posStation = parseIntOrNull(req.getParameter("posStation"));
                if (posStation == null && req.getSession(false) != null) {
                    posStation = (Integer) req.getSession(false).getAttribute("posStation");
                }
                if (posStation == null) posStation = 1;

                ServiceResult<Invoice> result = saleService.completeSale(
                        accountId, customerId, payMethod, discount,
                        medicineIds, quantities, req.getRemoteAddr());

                if (result.isOk()) {
                    Invoice inv = result.getData();
                    out.printf("{\"ok\":true,\"invoiceId\":%d,\"invoiceCode\":\"%s\",\"total\":%s}",
                            inv != null ? inv.getInvoiceId()  : 0,
                            inv != null ? esc(inv.getInvoiceCode()) : "",
                            inv != null ? inv.getFinalAmount() : "0");
                    // Push tồn kho mới tới tất cả medicine-list tabs qua SSE
                    com.medicare.controller.admin.InventorySSEServlet.broadcast();
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

    // ── Face check-in từ POS (không cần đăng nhập trước) ──────────────────────
    private void handlePosFaceCheckin(HttpServletRequest req, HttpServletResponse resp,
                                      PrintWriter out) throws IOException {
        String accIdStr   = req.getParameter("accountId");
        String stationStr = req.getParameter("station");

        if (accIdStr == null || accIdStr.isEmpty()) {
            out.print("{\"ok\":false,\"reason\":\"missing_accountId\"}");
            return;
        }

        int accountId;
        try { accountId = Integer.parseInt(accIdStr); }
        catch (NumberFormatException e) {
            out.print("{\"ok\":false,\"reason\":\"invalid_accountId\"}");
            return;
        }

        Account staff = accountDAO.findById(accountId);
        if (staff == null || !staff.isActive() || staff.getRoleId() == 1) {
            out.print("{\"ok\":false,\"reason\":\"staff_not_found\"}");
            return;
        }

        // Đang chờ duyệt đổi khuôn mặt → chặn điểm danh bằng khuôn mặt cũ
        if (staff.isFaceReenrollPending()) {
            out.print("{\"ok\":false,\"reason\":\"reenroll_pending\"}");
            return;
        }

        // Verify khuôn mặt PHÍA SERVER — không tin kết quả so khớp từ client.
        // Client phải gửi kèm descriptor; server đối chiếu 1-vs-N với ngưỡng chặt.
        String descriptorJson = req.getParameter("descriptor");
        String verifyResult = com.medicare.util.FaceVerifier.verify(
                accountId, descriptorJson, accountDAO.findAllWithFaceVector());
        if (!"MATCH".equals(verifyResult)) {
            out.print("{\"ok\":false,\"reason\":\"" + verifyResult + "\"}");
            return;
        }

        HttpSession session = req.getSession(true);

        // Kiểm tra sai quầy POS trước khi set session
        ShiftSchedule schedule = scheduleDAO.findTodaySchedule(accountId);
        if (schedule != null && schedule.getPosStation() > 0) {
            Integer sessStation = (Integer) session.getAttribute("posStation");
            int currentSt = sessStation != null ? sessStation : 0;
            if (currentSt > 0 && schedule.getPosStation() != currentSt) {
                String n = staff.getFullName() != null ? staff.getFullName() : staff.getUsername();
                out.printf("{\"ok\":false,\"reason\":\"wrong-station\",\"correctStation\":%d,\"name\":\"%s\"}",
                        schedule.getPosStation(), esc(n));
                return;
            }
        }

        // Lưu session
        session.setAttribute("staffAccount", staff);
        session.setAttribute("staffAccount_" + accountId, staff);
        session.setAttribute("staffUid", String.valueOf(accountId));

        // Lưu station vào session
        if (stationStr != null && !stationStr.isEmpty()) {
            try {
                int st = Integer.parseInt(stationStr);
                if (st >= 1) session.setAttribute("posStation", st);
            } catch (NumberFormatException ignored) {}
        }

        accountDAO.updateLastActive(accountId);
        accountDAO.updateLastLogin(accountId);

        // Kiểm tra đã check-in chưa
        String posState  = (String) session.getAttribute("posState");
        Attendance activeAtt = attendanceDAO.findActiveByAccount(accountId);
        if (activeAtt != null) {
            String name = staff.getFullName() != null ? staff.getFullName() : staff.getUsername();
            if ("ACTIVE".equals(posState)) {
                // Đã active → client chỉ cần reload
                out.printf("{\"ok\":true,\"staffId\":%d,\"name\":\"%s\",\"status\":\"already-active\"}",
                        accountId, esc(name));
            } else {
                out.printf("{\"ok\":true,\"staffId\":%d,\"name\":\"%s\",\"status\":\"already-in\"}",
                        accountId, esc(name));
            }
            return;
        }

        // Thử tạo attendance nếu có lịch ca hôm nay
        String checkInStatus;
        if (schedule != null) {
            LocalDateTime now          = LocalDateTime.now();
            LocalDateTime plannedStart = schedule.getPlannedStart();
            LocalDateTime plannedEnd   = schedule.getPlannedEnd();

            if (now.isAfter(plannedStart.minusMinutes(15)) &&
                now.isBefore(plannedEnd.plusMinutes(30))) {
                long lateMinutes = Math.max(0, ChronoUnit.MINUTES.between(plannedStart, now));
                String attStatus = lateMinutes <= 5 ? "CONFIRMED" :
                                   lateMinutes <= schedule.getLateToleranceMinutes() + 5 ? "LATE" : "ABSENT";
                BigDecimal penalty = BigDecimal.ZERO;
                if (lateMinutes > 5) {
                    penalty = schedule.getPenaltyRatePerMinute()
                            .multiply(BigDecimal.valueOf(Math.max(0, lateMinutes - 5)));
                }
                attendanceDAO.checkInWithPenalty(accountId, schedule.getScheduleId(),
                        "FACE_ID", BigDecimal.ZERO, penalty, (int) lateMinutes, attStatus);
                checkInStatus = "checked-in";
            } else {
                checkInStatus = "out-of-schedule";
            }
        } else {
            checkInStatus = "no-schedule";
        }

        String name = staff.getFullName() != null ? staff.getFullName() : staff.getUsername();
        out.printf("{\"ok\":true,\"staffId\":%d,\"name\":\"%s\",\"status\":\"%s\"}",
                accountId, esc(name), checkInStatus);
    }

    // ── PayOS QR handlers ────────────────────────────────────────────────────────
    private void handleCreateQr(HttpServletRequest req, PrintWriter out) {
        if (!com.medicare.config.PayOSConfig.isConfigured()) {
            out.print("{\"ok\":false,\"msg\":\"PayOS chưa được cấu hình — điền CLIENT_ID/API_KEY/CHECKSUM_KEY vào PayOSConfig.java\"}");
            return;
        }
        try {
            long amount = Math.round(Double.parseDouble(req.getParameter("amount")));
            if (amount < 1000) {
                out.print("{\"ok\":false,\"msg\":\"Số tiền tối thiểu 1,000đ\"}");
                return;
            }
            long   orderCode = System.currentTimeMillis() % 100_000_000L;
            String desc      = "MV " + orderCode;   // ASCII, ≤25 chars
            String baseUrl   = req.getScheme() + "://" + req.getServerName()
                             + ":" + req.getServerPort() + req.getContextPath();

            java.util.Map<String, Object> result =
                com.medicare.service.PayOSService.createPayment(orderCode, amount, desc, baseUrl);

            if (Boolean.TRUE.equals(result.get("ok"))) {
                out.printf("{\"ok\":true,\"qrCode\":\"%s\",\"checkoutUrl\":\"%s\",\"orderCode\":%d,\"amount\":%d}",
                    esc((String) result.get("qrCode")),
                    esc((String) result.get("checkoutUrl")),
                    orderCode, amount);
            } else {
                out.printf("{\"ok\":false,\"msg\":\"%s\"}", esc((String) result.get("msg")));
            }
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"ok\":false,\"msg\":\"Lỗi kết nối PayOS\"}");
        }
    }

    private void handleCheckQrStatus(HttpServletRequest req, PrintWriter out) {
        String codeParam = req.getParameter("orderCode");
        if (codeParam == null || codeParam.isBlank()) { out.print("{\"status\":\"UNKNOWN\"}"); return; }
        try {
            long orderCode = Long.parseLong(codeParam);
            String status  = com.medicare.service.PayOSService.checkStatus(orderCode);
            out.printf("{\"status\":\"%s\"}", status);
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"status\":\"UNKNOWN\"}");
        }
    }

    private void handleCancelQr(HttpServletRequest req, PrintWriter out) {
        String codeParam = req.getParameter("orderCode");
        if (codeParam == null || codeParam.isBlank()) { out.print("{\"ok\":false}"); return; }
        try {
            long orderCode = Long.parseLong(codeParam);
            boolean ok     = com.medicare.service.PayOSService.cancelPayment(orderCode);
            out.printf("{\"ok\":%b}", ok);
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"ok\":false}");
        }
    }

    private void handleOpenShift(HttpServletRequest req, PrintWriter out) {
        HttpSession session = req.getSession(false);
        Account staff = session != null ? (Account) session.getAttribute("staffAccount") : null;
        if (staff == null) { out.print("{\"ok\":false,\"reason\":\"not_logged_in\"}"); return; }
        BigDecimal openingCash = BigDecimal.ZERO;
        String cashStr = req.getParameter("openingCash");
        if (cashStr != null && !cashStr.isEmpty()) {
            try { openingCash = new BigDecimal(cashStr); } catch (Exception ignored) {}
        }
        ShiftSchedule schedule = scheduleDAO.findTodaySchedule(staff.getAccountId());
        if (schedule != null && openingCash.compareTo(BigDecimal.ZERO) > 0) {
            ((ShiftScheduleDAO) scheduleDAO).updateOpeningCash(schedule.getScheduleId(), openingCash);
        }
        session.setAttribute("posState", "ACTIVE");
        session.setAttribute("posOpeningCash", openingCash);
        out.print("{\"ok\":true}");
    }

    private void handleEndShift(HttpServletRequest req, PrintWriter out) {
        HttpSession session = req.getSession(false);
        Account staff = session != null ? (Account) session.getAttribute("staffAccount") : null;
        if (staff == null) { out.print("{\"ok\":false,\"reason\":\"not_logged_in\"}"); return; }

        // Accept actual cash counted by staff
        BigDecimal closingCash = BigDecimal.ZERO;
        String ccStr = req.getParameter("closingCash");
        if (ccStr != null && !ccStr.isEmpty()) {
            try { closingCash = new BigDecimal(ccStr); } catch (Exception ignored) {}
        }

        Integer posStation = session != null ? (Integer)    session.getAttribute("posStation")    : null;
        BigDecimal opening = session != null ? (BigDecimal) session.getAttribute("posOpeningCash") : BigDecimal.ZERO;
        if (opening == null) opening = BigDecimal.ZERO;

        int invoiceCount = 0;
        BigDecimal cashTotal = BigDecimal.ZERO, qrTotal = BigDecimal.ZERO, cardTotal = BigDecimal.ZERO;
        boolean hasSt = posStation != null && posStation > 0;
        String sql = "SELECT " +
            "ISNULL(SUM(CASE WHEN PaymentMethod='CASH' THEN FinalAmount ELSE 0 END),0) AS CashTotal," +
            "ISNULL(SUM(CASE WHEN PaymentMethod='QR_CODE' THEN FinalAmount ELSE 0 END),0) AS QrTotal," +
            "ISNULL(SUM(CASE WHEN PaymentMethod='CARD' THEN FinalAmount ELSE 0 END),0) AS CardTotal," +
            "COUNT(*) AS InvoiceCnt FROM Invoices " +
            "WHERE AccountID=? AND CAST(CreatedAt AS DATE)=CAST(GETDATE() AS DATE) AND Status='COMPLETED'" +
            (hasSt ? " AND PosStation=?" : "");
        try (java.sql.Connection cn = com.medicare.config.DBContext.getConnection();
             java.sql.PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, staff.getAccountId());
            if (hasSt) ps.setInt(2, posStation);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    cashTotal = rs.getBigDecimal("CashTotal"); if (cashTotal == null) cashTotal = BigDecimal.ZERO;
                    qrTotal   = rs.getBigDecimal("QrTotal");   if (qrTotal   == null) qrTotal   = BigDecimal.ZERO;
                    cardTotal = rs.getBigDecimal("CardTotal");  if (cardTotal == null) cardTotal  = BigDecimal.ZERO;
                    invoiceCount = rs.getInt("InvoiceCnt");
                }
            }
        } catch (Exception e) { e.printStackTrace(); }

        // Record actual handover cash in attendance checkout
        attendanceDAO.checkOut(staff.getAccountId(), closingCash, "Đóng ca từ POS", false);

        session.removeAttribute("posState");
        session.removeAttribute("staffAccount");
        session.removeAttribute("staffUid");
        session.removeAttribute("posOpeningCash");

        BigDecimal total = cashTotal.add(qrTotal).add(cardTotal);
        String name = staff.getFullName() != null ? staff.getFullName() : staff.getUsername();
        out.printf("{\"ok\":true,\"staffName\":\"%s\",\"invoiceCount\":%d," +
                   "\"cashTotal\":%s,\"qrTotal\":%s,\"cardTotal\":%s," +
                   "\"totalRevenue\":%s,\"openingCash\":%s,\"closingCash\":%s}",
                esc(name), invoiceCount,
                cashTotal.toPlainString(), qrTotal.toPlainString(), cardTotal.toPlainString(),
                total.toPlainString(), opening.toPlainString(), closingCash.toPlainString());
    }

    private void handleShiftSummary(HttpServletRequest req, PrintWriter out) {
        HttpSession session = req.getSession(false);
        Account staff = session != null ? (Account) session.getAttribute("staffAccount") : null;
        if (staff == null) { out.print("{\"ok\":false,\"reason\":\"not_logged_in\"}"); return; }

        Integer posStation = session != null ? (Integer)    session.getAttribute("posStation")    : null;
        BigDecimal opening = session != null ? (BigDecimal) session.getAttribute("posOpeningCash") : BigDecimal.ZERO;
        if (opening == null) opening = BigDecimal.ZERO;

        BigDecimal cashTotal = BigDecimal.ZERO, qrTotal = BigDecimal.ZERO, cardTotal = BigDecimal.ZERO;
        int invoiceCount = 0;
        boolean hasSt = posStation != null && posStation > 0;
        String sql = "SELECT " +
            "ISNULL(SUM(CASE WHEN PaymentMethod='CASH' THEN FinalAmount ELSE 0 END),0) AS CashTotal," +
            "ISNULL(SUM(CASE WHEN PaymentMethod='QR_CODE' THEN FinalAmount ELSE 0 END),0) AS QrTotal," +
            "ISNULL(SUM(CASE WHEN PaymentMethod='CARD' THEN FinalAmount ELSE 0 END),0) AS CardTotal," +
            "COUNT(*) AS InvoiceCnt FROM Invoices " +
            "WHERE AccountID=? AND CAST(CreatedAt AS DATE)=CAST(GETDATE() AS DATE) AND Status='COMPLETED'" +
            (hasSt ? " AND PosStation=?" : "");
        try (java.sql.Connection cn = com.medicare.config.DBContext.getConnection();
             java.sql.PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, staff.getAccountId());
            if (hasSt) ps.setInt(2, posStation);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    cashTotal = rs.getBigDecimal("CashTotal"); if (cashTotal == null) cashTotal = BigDecimal.ZERO;
                    qrTotal   = rs.getBigDecimal("QrTotal");   if (qrTotal   == null) qrTotal   = BigDecimal.ZERO;
                    cardTotal = rs.getBigDecimal("CardTotal");  if (cardTotal == null) cardTotal  = BigDecimal.ZERO;
                    invoiceCount = rs.getInt("InvoiceCnt");
                }
            }
        } catch (Exception e) { e.printStackTrace(); }

        // Get check-in time from active attendance record
        String checkInTime = "";
        try {
            com.medicare.entity.Attendance active = attendanceDAO.findActiveByAccount(staff.getAccountId());
            if (active != null && active.getCheckInTime() != null) {
                checkInTime = active.getCheckInTime()
                    .format(java.time.format.DateTimeFormatter.ofPattern("HH:mm"));
            }
        } catch (Exception ignored) {}

        BigDecimal expectedCash = opening.add(cashTotal);
        String name = staff.getFullName() != null ? staff.getFullName() : staff.getUsername();
        out.printf("{\"ok\":true,\"staffName\":\"%s\",\"invoiceCount\":%d," +
                   "\"cashTotal\":%s,\"qrTotal\":%s,\"cardTotal\":%s," +
                   "\"openingCash\":%s,\"expectedCash\":%s,\"posStation\":%d,\"checkInTime\":\"%s\"}",
                esc(name), invoiceCount,
                cashTotal.toPlainString(), qrTotal.toPlainString(), cardTotal.toPlainString(),
                opening.toPlainString(), expectedCash.toPlainString(),
                posStation != null ? posStation : 0, checkInTime);
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