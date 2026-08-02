package com.medicare.controller.pos;

import com.medicare.dao.*;
import com.medicare.dao.interfaces.*;
import com.medicare.entity.*;
import com.medicare.service.SaleService;
import com.medicare.service.ServiceResult;
import com.medicare.service.interfaces.ISaleService;
import com.medicare.util.ValidationUtil;
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
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

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

    // ── Action GET yêu cầu đã có nhân viên xác thực (đọc PII khách hàng) ──
    private static final java.util.Set<String> NEEDS_STAFF_GET = java.util.Set.of(
            "find-customer", "nfc-lookup", "search-customers", "pos-customer-detail",
            "list-customers", "customer-detail", "shift-summary", "my-invoices");

    // ── Action POST được phép chạy TRƯỚC khi có nhân viên xác thực (chọn quầy,
    // check-in khuôn mặt, thanh toán QR đang chờ...) — mọi action POST khác đều
    // bắt buộc phải có identity trong session (chặn "bấm bill" không đăng nhập). ──
    private static final java.util.Set<String> BOOTSTRAP_ACTIONS = java.util.Set.of(
            "set-station", "pos-face-checkin", "pos-face-identify",
            "pos-pause", "pos-resume", "create-qr", "check-qr-status", "cancel-qr");

    /** Có BẤT KỲ tài khoản nào (admin/nhân viên) đã xác thực trên session này chưa. */
    private boolean hasAnyPosIdentity(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) return false;
        if (session.getAttribute("adminAccount") instanceof Account) return true;
        if (session.getAttribute("staffAccount") instanceof Account) return true;
        java.util.Enumeration<String> names = session.getAttributeNames();
        while (names.hasMoreElements()) {
            String name = names.nextElement();
            if (name.startsWith("staffAccount_") && session.getAttribute(name) instanceof Account) {
                return true;
            }
        }
        return false;
    }

    // ── Idempotency cho complete-sale ─────────────────────────────────────────
    // Nếu FE gửi trùng clientRequestId (double-submit do click liên tục, mạng lag khiến
    // race giữa các lượt poll QR, F5 giữa lúc đang xử lý...) thì KHÔNG xử lý lại / trừ kho
    // lần nữa — trả thẳng kết quả của lượt xử lý đầu tiên. TTL đơn giản, đủ cho tải POS thấp.
    private static final ConcurrentMap<String, String> saleResponseCache = new ConcurrentHashMap<>();
    private static final ConcurrentMap<String, Long>   saleResponseCacheTime = new ConcurrentHashMap<>();
    private static final long SALE_CACHE_TTL_MS = 10 * 60 * 1000L;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        resp.setContentType("text/html; charset=UTF-8");

        String action = req.getParameter("action");

        // ── Chặn action lộ thông tin khách hàng (PII) khi chưa có nhân viên nào
        // xác thực trên session này. Không áp dụng cho action render trang /
        // tra cứu sản phẩm — những cái đó cần public cho màn hình chờ check-in. ──
        if (action != null && NEEDS_STAFF_GET.contains(action) && !hasAnyPosIdentity(req)) {
            resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            resp.setContentType("application/json;charset=UTF-8");
            resp.getWriter().print("{\"ok\":false,\"error\":\"unauthorized\"}");
            return;
        }

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
            String phone = ValidationUtil.normalizePhoneVN(req.getParameter("phone"));
            Customer c = customerDAO.findByPhone(phone);
            resp.setContentType("application/json;charset=UTF-8");
            PrintWriter out = resp.getWriter();
            out.print(customerJson(c));
            return;
        }

        // NFC: tra thẻ — trả khách nếu đã liên kết, {found:false} nếu thẻ trắng
        if ("nfc-lookup".equals(action)) {
            String uid = req.getParameter("uid");
            Customer c = ((com.medicare.dao.CustomerDAO) customerDAO).findByNfcUid(uid);
            resp.setContentType("application/json;charset=UTF-8");
            resp.getWriter().print(customerJson(c));
            return;
        }

        // Panel quản lý khách trong POS: tìm/liệt kê theo tên hoặc SĐT
        if ("search-customers".equals(action)) {
            resp.setContentType("application/json;charset=UTF-8");
            handleSearchCustomers(req, resp.getWriter());
            return;
        }

        // Xem chi tiết 1 khách trong POS: hồ sơ + điểm/hạng + lịch sử mua gần đây
        if ("pos-customer-detail".equals(action)) {
            resp.setContentType("application/json;charset=UTF-8");
            handleCustomerDetail(req, resp.getWriter());
            return;
        }

        if ("list-customers".equals(action)) {
            String q = req.getParameter("q");
            List<Customer> list = customerDAO.findAll();
            resp.setContentType("application/json;charset=UTF-8");
            PrintWriter out = resp.getWriter();
            out.print("[");
            boolean first = true;
            for (Customer c : list) {
                if (q != null && !q.trim().isEmpty()) {
                    String query = q.trim().toLowerCase();
                    boolean matchName = c.getCustomerName() != null && c.getCustomerName().toLowerCase().contains(query);
                    boolean matchPhone = c.getPhone() != null && c.getPhone().contains(query);
                    if (!matchName && !matchPhone) continue;
                }
                if (!first) out.print(",");
                out.printf("{\"id\":%d,\"name\":\"%s\",\"phone\":\"%s\",\"email\":\"%s\",\"address\":\"%s\"," +
                           "\"dateOfBirth\":\"%s\",\"gender\":\"%s\",\"nationalId\":\"%s\",\"occupation\":\"%s\"," +
                           "\"allergyHistory\":\"%s\",\"chronicDisease\":\"%s\"}",
                        c.getCustomerId(),
                        esc(c.getCustomerName()),
                        esc(c.getPhone()),
                        esc(c.getEmail()),
                        esc(c.getAddress()),
                        c.getDateOfBirth() != null ? c.getDateOfBirth().toString() : "",
                        esc(c.getGender()),
                        esc(c.getNationalId()),
                        esc(c.getOccupation()),
                        esc(c.getAllergyHistory()),
                        esc(c.getChronicDisease()));
                first = false;
            }
            out.print("]");
            return;
        }

        if ("customer-detail".equals(action)) {
            int id = parseIntOrNull(req.getParameter("id")) != null ? parseIntOrNull(req.getParameter("id")) : 0;
            Customer c = customerDAO.findById(id);
            resp.setContentType("application/json;charset=UTF-8");
            PrintWriter out = resp.getWriter();
            if (c == null) {
                out.print("{\"ok\":false}");
            } else {
                out.printf("{\"ok\":true,\"id\":%d,\"name\":\"%s\",\"phone\":\"%s\",\"email\":\"%s\",\"address\":\"%s\"," +
                           "\"dateOfBirth\":\"%s\",\"gender\":\"%s\",\"nationalId\":\"%s\",\"occupation\":\"%s\"," +
                           "\"allergyHistory\":\"%s\",\"chronicDisease\":\"%s\"}",
                        c.getCustomerId(),
                        esc(c.getCustomerName()),
                        esc(c.getPhone()),
                        esc(c.getEmail()),
                        esc(c.getAddress()),
                        c.getDateOfBirth() != null ? c.getDateOfBirth().toString() : "",
                        esc(c.getGender()),
                        esc(c.getNationalId()),
                        esc(c.getOccupation()),
                        esc(c.getAllergyHistory()),
                        esc(c.getChronicDisease()));
            }
            return;
        }
        if ("shift-summary".equals(action)) {
            resp.setContentType("application/json;charset=UTF-8");
            PrintWriter out = resp.getWriter();
            handleShiftSummary(req, out);
            return;
        }

        if ("my-invoices".equals(action)) {
            resp.setContentType("application/json;charset=UTF-8");
            PrintWriter out = resp.getWriter();
            handleMyInvoices(req, out);
            return;
        }

        // Ai đang đứng quầy nào (chưa check-out hôm nay) — hiện trong modal chọn quầy, để
        // biết trước quầy nào đang có người trước khi chọn (tránh chọn nhầm quầy người khác).
        if ("station-staff".equals(action)) {
            resp.setContentType("application/json;charset=UTF-8");
            PrintWriter out = resp.getWriter();
            Map<Integer, String> staffByStation = attendanceDAO.findActiveStaffByStation();
            StringBuilder sb = new StringBuilder("{");
            boolean first = true;
            for (Map.Entry<Integer, String> e : staffByStation.entrySet()) {
                if (!first) sb.append(",");
                sb.append("\"").append(e.getKey()).append("\":\"").append(esc(e.getValue())).append("\"");
                first = false;
            }
            sb.append("}");
            out.print(sb);
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
                "  FROM Batches WHERE ExpiryDate > CAST(GETDATE() AS DATE) AND Status = 'ACTIVE' GROUP BY MedicineID" +
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
                            rs.getInt("MedicineID"), esc(rs.getString("MedicineName")),
                            esc(rs.getString("MedicineCode")), esc(rs.getString("Unit")),
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
                if (st >= 1) req.getSession(true).setAttribute("posStation", st);
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

        // Danh sách quầy POS động từ DB (đồng bộ với admin CRUD quầy ở shift-list)
        req.setAttribute("posStations",
                new com.medicare.dao.PosStationDAO().findAllActive());

        req.getRequestDispatcher("/WEB-INF/views/pos/pos.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();

        String action = req.getParameter("action");

        // ── Chặn mọi action mutate dữ liệu / bán hàng khi chưa có nhân viên nào
        // xác thực trên session này. Danh sách BOOTSTRAP_ACTIONS là các bước cần
        // public để nhân viên còn CHƯA đăng nhập có thể chọn quầy + check-in mặt. ──
        if ((action == null || !BOOTSTRAP_ACTIONS.contains(action)) && !hasAnyPosIdentity(req)) {
            resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print("{\"ok\":false,\"error\":\"unauthorized\"}");
            return;
        }

        if ("set-station".equals(action)) {
            String stStr = req.getParameter("station");
            if (stStr != null) {
                try {
                    int st = Integer.parseInt(stStr);
                    if (st >= 1) {
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

        if ("quick-create-customer".equals(action)) { handleQuickCreateCustomer(req, out); return; }
        if ("link-nfc".equals(action))              { handleLinkNfc(req, out); return; }

        if ("open-shift".equals(action))  { handleOpenShift(req, out); return; }
        if ("pos-pause".equals(action))   { req.getSession(true).setAttribute("posState","PAUSED");  out.print("{\"ok\":true}"); return; }
        if ("pos-resume".equals(action))  { req.getSession(true).setAttribute("posState","ACTIVE");  out.print("{\"ok\":true}"); return; }
        if ("pos-end-shift".equals(action)) { handleEndShift(req, out); return; }

        if ("pos-face-checkin".equals(action)) {
            handlePosFaceCheckin(req, resp, out);
            return;
        }

        if ("pos-face-identify".equals(action)) {
            String descriptorJson = req.getParameter("descriptor");
            if (descriptorJson == null || descriptorJson.trim().isEmpty()) {
                out.print("{\"ok\":false,\"reason\":\"missing_descriptor\"}");
                return;
            }
            Account matched = com.medicare.util.FaceVerifier.identify(
                    descriptorJson, accountDAO.findAllWithFaceVector());
            if (matched == null) {
                out.print("{\"ok\":false,\"reason\":\"no_match\"}");
            } else if (!matched.isActive()) {
                out.print("{\"ok\":false,\"reason\":\"staff_not_found\"}");
            } else if (matched.isFaceReenrollPending()) {
                out.print("{\"ok\":false,\"reason\":\"reenroll_pending\"}");
            } else {
                String name = matched.getFullName() != null ? matched.getFullName() : matched.getUsername();
                out.printf("{\"ok\":true,\"accountId\":%d,\"name\":\"%s\"}", matched.getAccountId(), esc(name));
            }
            return;
        }

        if ("create-qr".equals(action))       { handleCreateQr(req, out);      return; }
        if ("check-qr-status".equals(action)) { handleCheckQrStatus(req, out); return; }
        if ("cancel-qr".equals(action))       { handleCancelQr(req, out);      return; }

        if ("save-customer".equals(action)) {
            try {
                String idStr = req.getParameter("customerId");
                boolean isNew = idStr == null || idStr.trim().isEmpty() || "0".equals(idStr.trim());

                String name    = req.getParameter("customerName");
                String phone   = req.getParameter("phone");
                String email   = req.getParameter("email");
                String address = req.getParameter("address");
                String dobStr  = req.getParameter("dateOfBirth");
                String gender  = req.getParameter("gender");
                String natId   = req.getParameter("nationalId");
                String occup   = req.getParameter("occupation");
                String allergy = req.getParameter("allergyHistory");
                String chronic = req.getParameter("chronicDisease");

                if (name == null || name.trim().isEmpty()) {
                    out.print("{\"ok\":false,\"msg\":\"Vui lòng nhập họ tên khách hàng!\"}");
                    return;
                }

                LocalDate dob = null;
                if (dobStr != null && !dobStr.trim().isEmpty()) {
                    try {
                        dob = LocalDate.parse(dobStr.trim());
                        if (!dob.isBefore(LocalDate.now())) {
                            out.print("{\"ok\":false,\"msg\":\"Ngày sinh không hợp lệ!\"}");
                            return;
                        }
                    } catch (Exception e) {
                        out.print("{\"ok\":false,\"msg\":\"Ngày sinh không đúng định dạng!\"}");
                        return;
                    }
                }

                if (phone != null && !phone.trim().isEmpty()) {
                    Customer existing = customerDAO.findByPhone(phone.trim());
                    boolean phoneTaken = existing != null &&
                            (isNew || existing.getCustomerId() != Integer.parseInt(idStr.trim()));
                    if (phoneTaken) {
                        out.print("{\"ok\":false,\"msg\":\"Số điện thoại này đã thuộc về khách hàng khác!\"}");
                        return;
                    }
                }

                Customer c = new Customer();
                c.setCustomerName(name.trim());
                c.setPhone(phone == null || phone.trim().isEmpty() ? null : phone.trim());
                c.setEmail(email == null || email.trim().isEmpty() ? null : email.trim());
                c.setAddress(address == null || address.trim().isEmpty() ? null : address.trim());
                c.setDateOfBirth(dob);
                c.setGender(gender == null || gender.trim().isEmpty() ? null : gender.trim());
                c.setNationalId(natId == null || natId.trim().isEmpty() ? null : natId.trim());
                c.setOccupation(occup == null || occup.trim().isEmpty() ? null : occup.trim());
                c.setAllergyHistory(allergy == null || allergy.trim().isEmpty() ? null : allergy.trim());
                c.setChronicDisease(chronic == null || chronic.trim().isEmpty() ? null : chronic.trim());

                boolean ok;
                if (isNew) {
                    ok = customerDAO.insert(c);
                    if (ok) {
                        Customer created = null;
                        if (c.getPhone() != null && !c.getPhone().isEmpty()) {
                            created = customerDAO.findByPhone(c.getPhone());
                        }
                        if (created == null) {
                            // fallback tìm theo ID lớn nhất của tên này
                            List<Customer> all = customerDAO.findAll();
                            if (!all.isEmpty()) {
                                created = all.stream()
                                    .filter(x -> x.getCustomerName().equals(c.getCustomerName()))
                                    .max((x, y) -> Integer.compare(x.getCustomerId(), y.getCustomerId()))
                                    .orElse(null);
                            }
                        }
                        int newId = created != null ? created.getCustomerId() : 0;
                        out.printf("{\"ok\":true,\"msg\":\"Thêm khách hàng thành công!\",\"id\":%d,\"name\":\"%s\",\"phone\":\"%s\"}",
                                newId, esc(c.getCustomerName()), esc(c.getPhone() != null ? c.getPhone() : ""));
                    } else {
                        out.print("{\"ok\":false,\"msg\":\"Lỗi khi lưu vào cơ sở dữ liệu!\"}");
                    }
                } else {
                    c.setCustomerId(Integer.parseInt(idStr.trim()));
                    ok = customerDAO.update(c);
                    if (ok) {
                        out.printf("{\"ok\":true,\"msg\":\"Cập nhật khách hàng thành công!\",\"id\":%d,\"name\":\"%s\",\"phone\":\"%s\"}",
                                c.getCustomerId(), esc(c.getCustomerName()), esc(c.getPhone() != null ? c.getPhone() : ""));
                    } else {
                        out.print("{\"ok\":false,\"msg\":\"Lỗi khi cập nhật vào cơ sở dữ liệu!\"}");
                    }
                }
            } catch (Exception e) {
                e.printStackTrace();
                out.printf("{\"ok\":false,\"msg\":\"Lỗi hệ thống: %s\"}", esc(e.getMessage()));
            }
            return;
        }

        if ("complete-sale".equals(action)) {
            String clientReqId = req.getParameter("clientRequestId");
            if (clientReqId != null && !clientReqId.isBlank()) {
                long now = System.currentTimeMillis();
                saleResponseCacheTime.forEach((k, t) -> {
                    if (now - t > SALE_CACHE_TTL_MS) {
                        saleResponseCache.remove(k);
                        saleResponseCacheTime.remove(k);
                    }
                });
                String placeholder = "{\"ok\":false,\"msg\":\"Giao dịch này đang được xử lý, vui lòng đợi…\"}";
                String existing = saleResponseCache.putIfAbsent(clientReqId, placeholder);
                if (existing != null) {
                    // Yêu cầu trùng lặp (double-submit) — KHÔNG xử lý lại, trả kết quả gốc
                    out.print(existing);
                    return;
                }
                saleResponseCacheTime.put(clientReqId, now);
            }
            try {
                HttpSession session = req.getSession(false);
                Account acc = null;
                if (session != null) {
                    String uid = req.getParameter("uid");
                    if (uid != null && !uid.isEmpty())
                        acc = (Account) session.getAttribute("staffAccount_" + uid);
                    if (acc == null)
                        acc = (Account) session.getAttribute("staffAccount");
                    // KHÔNG lấy adminAccount — admin không phải người đứng quầy POS
                }

                // Đọc posStation từ request hoặc session (cần sớm để tra attendance)
                Integer posStation = parseIntOrNull(req.getParameter("posStation"));
                if (posStation == null && session != null) {
                    posStation = (Integer) session.getAttribute("posStation");
                }
                if (posStation == null) posStation = 1;

                // Fallback: nếu không có staffAccount trong session, tra xem ai đang
                // check-in active tại quầy này hôm nay (theo ShiftSchedule.PosStation)
                if (acc == null && posStation > 0) {
                    Attendance activeAtt = attendanceDAO.findActiveByStation(posStation);
                    if (activeAtt != null) {
                        acc = accountDAO.findById(activeAtt.getAccountId());
                    }
                }

                // POS bán bình thường không bắt buộc mở ca — chưa điểm danh thì
                // hóa đơn ghi về tài khoản POS mặc định
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

                String jsonResp;
                if (result.isOk()) {
                    Invoice inv = result.getData();
                    // Tích điểm loyalty (1 điểm / 10.000đ) nếu hóa đơn gắn khách hàng
                    int earned = 0;
                    if (customerId != null && inv != null) {
                        earned = new com.medicare.dao.LoyaltyDAO().earnFromInvoice(
                                customerId, inv.getInvoiceId(), inv.getFinalAmount(), accountId);
                    }
                    jsonResp = String.format(
                            "{\"ok\":true,\"invoiceId\":%d,\"invoiceCode\":\"%s\",\"total\":%s,\"earnedPoints\":%d}",
                            inv != null ? inv.getInvoiceId()  : 0,
                            inv != null ? esc(inv.getInvoiceCode()) : "",
                            inv != null ? inv.getFinalAmount() : "0",
                            earned);
                    // Push tồn kho mới tới tất cả medicine-list tabs qua SSE
                    com.medicare.controller.admin.InventorySSEServlet.broadcast();
                } else {
                    jsonResp = String.format("{\"ok\":false,\"msg\":\"%s\"}", esc(result.firstError()));
                }
                if (clientReqId != null && !clientReqId.isBlank()) saleResponseCache.put(clientReqId, jsonResp);
                out.print(jsonResp);

            } catch (Throwable e) {
                e.printStackTrace();
                // Lỗi hệ thống thật sự — bỏ cache để lượt thử lại (cùng clientRequestId) không
                // bị kẹt mãi ở placeholder "đang xử lý" trong lúc chờ TTL hết hạn.
                if (clientReqId != null && !clientReqId.isBlank()) saleResponseCache.remove(clientReqId);
                String errMsg = e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName();
                out.printf("{\"ok\":false,\"msg\":\"Lỗi hệ thống: %s\"}", esc(errMsg));
            }
            return;
        }

        out.print("{\"ok\":false,\"msg\":\"Unknown action\"}");
    }

    // ── Customer helpers (tạo nhanh + NFC + loyalty) ──────────────────────────

    /**
     * Panel Khách hàng trong POS: trả danh sách khách (tối đa 50) lọc theo tên
     * hoặc SĐT. Nhẹ — chỉ id/tên/SĐT/hasNfc; điểm/dị ứng lấy khi chọn (find-customer).
     */
    private void handleSearchCustomers(HttpServletRequest req, PrintWriter out) {
        String q = req.getParameter("q");
        String kw = q != null ? q.trim() : "";
        String kwNoAccent = ValidationUtil.stripDiacritics(kw);
        // Nếu query gõ toàn số → so khớp theo SĐT đã chuẩn hoá (bỏ dấu cách/gạch/+84)
        // để không bỏ sót khách khi người dùng gõ/dán SĐT có định dạng khác trong DB.
        String kwDigits = kw.replaceAll("[^0-9]", "");
        boolean isPhoneQuery = !kwDigits.isEmpty()
                && kw.replaceAll("[0-9+\\-\\s().]", "").isEmpty();

        List<Customer> all = customerDAO.findAll();
        // rank 0 = khớp đầu chuỗi (ưu tiên nhất), 1 = khớp chứa ở giữa, bỏ qua nếu không khớp
        List<int[]> ranked = new java.util.ArrayList<>(); // [rank, indexInAll]
        for (int i = 0; i < all.size(); i++) {
            Customer c = all.get(i);
            String name  = c.getCustomerName() != null ? c.getCustomerName() : "";
            String phone = c.getPhone() != null ? c.getPhone() : "";
            String nameNoAccent = ValidationUtil.stripDiacritics(name);
            String phoneDigits  = phone.replaceAll("[^0-9]", "");

            int rank;
            if (kwNoAccent.isEmpty()) {
                rank = 0;
            } else if (nameNoAccent.startsWith(kwNoAccent)
                    || (isPhoneQuery && phoneDigits.startsWith(kwDigits))) {
                rank = 0;
            } else if (nameNoAccent.contains(kwNoAccent)
                    || (isPhoneQuery && phoneDigits.contains(kwDigits))) {
                rank = 1;
            } else {
                continue;
            }
            ranked.add(new int[]{rank, i});
        }
        ranked.sort((a, b) -> a[0] != b[0] ? a[0] - b[0] : a[1] - b[1]);

        StringBuilder sb = new StringBuilder("[");
        int n = 0;
        for (int[] r : ranked) {
            if (n >= 50) break;
            Customer c = all.get(r[1]);
            String name  = c.getCustomerName() != null ? c.getCustomerName() : "";
            String phone = c.getPhone() != null ? c.getPhone() : "";
            if (n > 0) sb.append(",");
            sb.append("{\"id\":").append(c.getCustomerId())
              .append(",\"name\":\"").append(esc(name)).append("\"")
              .append(",\"phone\":\"").append(esc(phone)).append("\"")
              .append(",\"hasNfc\":").append(c.getNfcCardUid() != null && !c.getNfcCardUid().isEmpty())
              .append("}");
            n++;
        }
        sb.append("]");
        out.print(sb);
    }

    /**
     * Chi tiết 1 khách cho POS (trang xem hồ sơ trong POS): thông tin + điểm/hạng
     * + tối đa 10 hóa đơn gần nhất của khách. Chỉ đọc, an toàn cho nhân viên.
     */
    private void handleCustomerDetail(HttpServletRequest req, PrintWriter out) {
        int id = parseIntOrZero(req.getParameter("id"));
        Customer c = customerDAO.findById(id);
        if (c == null) { out.print("{\"ok\":false,\"reason\":\"not_found\"}"); return; }

        com.medicare.entity.LoyaltyCard card = new com.medicare.dao.LoyaltyDAO().findByCustomer(id);
        String allergy = c.getAllergyHistory() != null ? c.getAllergyHistory().trim() : "";
        String chronic = c.getChronicDisease() != null ? c.getChronicDisease().trim() : "";

        StringBuilder inv = new StringBuilder();
        int count = 0;
        java.math.BigDecimal total = java.math.BigDecimal.ZERO;
        String sql = "SELECT TOP 10 InvoiceCode, FinalAmount, PaymentMethod, Status, " +
                "CONVERT(VARCHAR(16), CreatedAt, 120) AS CreatedAt " +
                "FROM Invoices WHERE CustomerID = ? ORDER BY CreatedAt DESC";
        String sqlTotal = "SELECT ISNULL(SUM(FinalAmount),0) AS T, COUNT(*) AS N " +
                "FROM Invoices WHERE CustomerID = ? AND Status = 'COMPLETED'";
        try (java.sql.Connection cn = com.medicare.config.DBContext.getConnection()) {
            try (java.sql.PreparedStatement ps = cn.prepareStatement(sql)) {
                ps.setInt(1, id);
                try (java.sql.ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        if (count > 0) inv.append(",");
                        java.math.BigDecimal amt = rs.getBigDecimal("FinalAmount");
                        if (amt == null) amt = java.math.BigDecimal.ZERO;
                        inv.append("{\"code\":\"").append(esc(rs.getString("InvoiceCode")))
                           .append("\",\"time\":\"").append(rs.getString("CreatedAt"))
                           .append("\",\"amount\":").append(amt.toPlainString())
                           .append(",\"method\":\"").append(esc(rs.getString("PaymentMethod")))
                           .append("\",\"status\":\"").append(esc(rs.getString("Status"))).append("\"}");
                        count++;
                    }
                }
            }
            try (java.sql.PreparedStatement ps = cn.prepareStatement(sqlTotal)) {
                ps.setInt(1, id);
                try (java.sql.ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) total = rs.getBigDecimal("T");
                }
            }
        } catch (Exception e) { e.printStackTrace(); }

        out.print("{\"ok\":true"
                + ",\"id\":" + c.getCustomerId()
                + ",\"name\":\"" + esc(c.getCustomerName()) + "\""
                + ",\"phone\":\"" + esc(c.getPhone() != null ? c.getPhone() : "") + "\""
                + ",\"email\":\"" + esc(c.getEmail() != null ? c.getEmail() : "") + "\""
                + ",\"address\":\"" + esc(c.getAddress() != null ? c.getAddress() : "") + "\""
                + ",\"gender\":\"" + esc(c.getGender() != null ? c.getGender() : "") + "\""
                + ",\"dob\":\"" + (c.getDateOfBirth() != null ? c.getDateOfBirth().toString() : "") + "\""
                + ",\"allergy\":\"" + esc(allergy) + "\""
                + ",\"chronic\":\"" + esc(chronic) + "\""
                + ",\"points\":" + (card != null ? card.getAvailablePoints() : 0)
                + ",\"tier\":\"" + esc(card != null && card.getTierName() != null ? card.getTierName() : "") + "\""
                + ",\"hasNfc\":" + (c.getNfcCardUid() != null && !c.getNfcCardUid().isEmpty())
                + ",\"nfcUid\":\"" + esc(c.getNfcCardUid() != null ? c.getNfcCardUid() : "") + "\""
                + ",\"invoiceCount\":" + count
                + ",\"totalSpent\":" + (total != null ? total.toPlainString() : "0")
                + ",\"invoices\":[" + inv + "]}");
    }

    private int parseIntOrZero(String s) {
        try { return Integer.parseInt(s); } catch (Exception e) { return 0; }
    }

    /** JSON khách hàng cho POS: kèm cảnh báo dị ứng + điểm/hạng thẻ. */
    private String customerJson(Customer c) {
        if (c == null) return "{\"found\":false}";
        com.medicare.entity.LoyaltyCard card =
                new com.medicare.dao.LoyaltyDAO().findByCustomer(c.getCustomerId());
        String allergy = c.getAllergyHistory() != null ? c.getAllergyHistory().trim() : "";
        return "{\"found\":true,\"id\":" + c.getCustomerId()
                + ",\"name\":\"" + esc(c.getCustomerName()) + "\""
                + ",\"phone\":\"" + esc(c.getPhone() != null ? c.getPhone() : "") + "\""
                + ",\"allergy\":\"" + esc(allergy) + "\""
                + ",\"points\":" + (card != null ? card.getAvailablePoints() : 0)
                + ",\"tier\":\"" + esc(card != null && card.getTierName() != null ? card.getTierName() : "") + "\""
                + ",\"hasNfc\":" + (c.getNfcCardUid() != null && !c.getNfcCardUid().isEmpty()) + "}";
    }

    /**
     * Tạo nhanh khách tại quầy — chỉ SĐT + Tên (+ giới tính). Flow "1 giây":
     * dược sĩ gõ đủ 10 số → không thấy → bấm [Tạo mới] → 2 trường → Lưu & Chọn.
     */
    private void handleQuickCreateCustomer(HttpServletRequest req, PrintWriter out) {
        String phone  = req.getParameter("phone");
        String name   = req.getParameter("name");
        String gender = req.getParameter("gender");

        if (phone == null || !phone.trim().matches("^0\\d{9}$")) {
            out.print("{\"ok\":false,\"reason\":\"invalid_phone\"}"); return;
        }
        if (name == null || name.trim().length() < 2) {
            out.print("{\"ok\":false,\"reason\":\"invalid_name\"}"); return;
        }
        phone = phone.trim();
        if (customerDAO.findByPhone(phone) != null) {
            out.print("{\"ok\":false,\"reason\":\"phone_exists\"}"); return;
        }
        if (gender != null && !gender.isEmpty()
                && !gender.equals("M") && !gender.equals("F")) gender = null;

        com.medicare.dao.CustomerDAO dao = (com.medicare.dao.CustomerDAO) customerDAO;
        int newId = dao.quickCreate(name.trim(), phone, gender);
        if (newId <= 0) { out.print("{\"ok\":false,\"reason\":\"db_error\"}"); return; }

        // Tạo luôn thẻ tích điểm hạng khởi điểm
        new com.medicare.dao.LoyaltyDAO().getOrCreateCard(newId);

        com.medicare.util.AuditHelper.log(req, "Tạo khách hàng (POS)", "Customer", newId,
                "Tạo nhanh khách tại quầy: " + name.trim() + " — " + phone);
        out.print("{\"ok\":true,\"id\":" + newId + ",\"name\":\"" + esc(name.trim())
                + "\",\"phone\":\"" + phone + "\",\"points\":0,\"tier\":\"\",\"allergy\":\"\"}");
    }

    /**
     * Liên kết thẻ NFC trắng với khách (tra theo SĐT). Thẻ đã gán cho người
     * khác thì từ chối. Nếu SĐT chưa có tài khoản → client mở form tạo nhanh.
     */
    private void handleLinkNfc(HttpServletRequest req, PrintWriter out) {
        String uid   = req.getParameter("uid");
        String phone = req.getParameter("phone");
        if (uid == null || uid.trim().isEmpty()) {
            out.print("{\"ok\":false,\"reason\":\"missing_uid\"}"); return;
        }
        com.medicare.dao.CustomerDAO dao = (com.medicare.dao.CustomerDAO) customerDAO;

        Customer owner = dao.findByNfcUid(uid);
        if (owner != null) {
            out.print("{\"ok\":false,\"reason\":\"uid_taken\",\"name\":\""
                    + esc(owner.getCustomerName()) + "\"}"); return;
        }
        Customer c = customerDAO.findByPhone(phone != null ? phone.trim() : "");
        if (c == null) { out.print("{\"ok\":false,\"reason\":\"phone_not_found\"}"); return; }

        boolean ok = dao.linkNfcCard(c.getCustomerId(), uid);
        if (ok) {
            com.medicare.util.AuditHelper.log(req, "Liên kết thẻ NFC", "Customer", c.getCustomerId(),
                    "Gán thẻ NFC " + uid.trim() + " cho khách " + c.getCustomerName());
            out.print(customerJson(dao.findById(c.getCustomerId())).replaceFirst(
                    "\\{\"found\":true", "{\"ok\":true,\"found\":true"));
        } else {
            out.print("{\"ok\":false,\"reason\":\"db_error\"}");
        }
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

        // Kiểm tra sai quầy POS trước khi set session — dùng ca ĐANG DIỄN RA theo giờ hiện
        // tại (không phải luôn ca sớm nhất trong ngày), vì nhân viên "2 ca/ngày" có thể đổi
        // quầy giữa Ca Chiều và Ca Tối (xem findActiveOrNearestSchedule để biết chi tiết bug cũ).
        ShiftSchedule schedule = scheduleDAO.findActiveOrNearestSchedule(accountId);
        if (schedule != null && schedule.getPosStation() > 0) {
            // Ưu tiên "station" của CHÍNH request này (đúng quầy trình duyệt đang đứng ngay
            // lúc quét mặt, client luôn gửi kèm — xem pos.jsp) thay vì session.posStation, vốn
            // có thể còn SÓT giá trị quầy cũ (test/chuyển quầy mà set-station chưa kịp chạy lại,
            // hoặc tab khác cùng session ghi đè) — khiến quét mặt ĐÚNG người vẫn bị từ chối oan
            // vì so sánh với 1 số quầy không còn đúng thực tế.
            int currentSt = 0;
            if (stationStr != null && !stationStr.isEmpty()) {
                try { currentSt = Integer.parseInt(stationStr); } catch (NumberFormatException ignored) {}
            }
            if (currentSt <= 0) {
                Integer sessStation = (Integer) session.getAttribute("posStation");
                currentSt = sessStation != null ? sessStation : 0;
            }
            if (currentSt > 0 && schedule.getPosStation() != currentSt) {
                String n = staff.getFullName() != null ? staff.getFullName() : staff.getUsername();
                // Kèm tên ca + khung giờ để màn POS hiện thông báo rõ ràng như modal chi tiết
                // ca bên Admin (trước đây chỉ có mỗi số quầy, khó hiểu ngay tại quầy bán).
                String shiftName = schedule.getShiftTypeName() != null ? schedule.getShiftTypeName() : "";
                String timeRange = "";
                if (schedule.getPlannedStart() != null && schedule.getPlannedEnd() != null) {
                    java.time.format.DateTimeFormatter hm = java.time.format.DateTimeFormatter.ofPattern("HH:mm");
                    timeRange = schedule.getPlannedStart().format(hm) + "–" + schedule.getPlannedEnd().format(hm);
                }
                out.printf("{\"ok\":false,\"reason\":\"wrong-station\",\"correctStation\":%d,\"name\":\"%s\",\"shiftName\":\"%s\",\"timeRange\":\"%s\"}",
                        schedule.getPosStation(), esc(n), esc(shiftName), esc(timeRange));
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

    /**
     * "Hóa đơn của tôi" — danh sách bill CHÍNH nhân viên đang đăng nhập
     * đã tạo trong ca hôm nay (lọc theo quầy nếu đã chọn) + tổng doanh thu.
     */
    private void handleMyInvoices(HttpServletRequest req, PrintWriter out) {
        HttpSession session = req.getSession(false);
        Account staff = session != null ? (Account) session.getAttribute("staffAccount") : null;
        if (staff == null) { out.print("{\"ok\":false,\"reason\":\"not_logged_in\"}"); return; }

        Integer posStation = (Integer) session.getAttribute("posStation");
        boolean hasSt = posStation != null && posStation > 0;

        StringBuilder sb = new StringBuilder();
        java.math.BigDecimal total = java.math.BigDecimal.ZERO;
        int count = 0;
        String sql = "SELECT InvoiceID, InvoiceCode, FinalAmount, PaymentMethod, Status, " +
                "CONVERT(VARCHAR(5), CreatedAt, 108) AS CreatedTime " +
                "FROM Invoices " +
                "WHERE AccountID = ? AND CAST(CreatedAt AS DATE) = CAST(GETDATE() AS DATE) " +
                (hasSt ? "AND PosStation = ? " : "") +
                "ORDER BY CreatedAt DESC";
        try (java.sql.Connection cn = com.medicare.config.DBContext.getConnection();
             java.sql.PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, staff.getAccountId());
            if (hasSt) ps.setInt(2, posStation);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    if (count > 0) sb.append(",");
                    java.math.BigDecimal amt = rs.getBigDecimal("FinalAmount");
                    if (amt == null) amt = java.math.BigDecimal.ZERO;
                    String status = rs.getString("Status");
                    if ("COMPLETED".equals(status)) total = total.add(amt);
                    sb.append("{\"code\":\"").append(esc(rs.getString("InvoiceCode")))
                      .append("\",\"time\":\"").append(rs.getString("CreatedTime"))
                      .append("\",\"amount\":").append(amt.toPlainString())
                      .append(",\"method\":\"").append(esc(rs.getString("PaymentMethod")))
                      .append("\",\"status\":\"").append(esc(status)).append("\"}");
                    count++;
                }
            }
        } catch (Exception e) { e.printStackTrace(); }

        String name = staff.getFullName() != null ? staff.getFullName() : staff.getUsername();
        out.print("{\"ok\":true,\"staffName\":\"" + esc(name) + "\",\"count\":" + count
                + ",\"totalRevenue\":" + total.toPlainString()
                + ",\"invoices\":[" + sb + "]}");
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