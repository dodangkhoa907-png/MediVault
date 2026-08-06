package com.medicare.controller;

import com.medicare.dao.CustomerDAO;
import com.medicare.dao.InvoiceDAO;
import com.medicare.dao.LoyaltyDAO;
import com.medicare.entity.Customer;
import com.medicare.entity.Invoice;
import com.medicare.entity.LoyaltyCard;
import com.medicare.dao.PrescriptionDAO;
import com.medicare.dao.interfaces.IPrescriptionDAO;
import com.medicare.entity.Prescription;
import com.medicare.util.AuditHelper;
import com.medicare.util.EmailUtil;
import com.medicare.util.OtpUtil;
import com.medicare.util.PasswordResetHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.time.LocalDate;
import java.util.List;

/**
 * CustomerPortalServlet — Cổng thông tin KHÁCH HÀNG (mobile-first).
 * URL: /portal
 *
 * Đăng nhập bằng Email + OTP: khách nhập Email đã cấp tại POS → hệ thống gửi
 * mã OTP 6 số vào đúng Gmail đó → nhập mã mới vào được portal.
 * Session key riêng: "portalCustomer" — độc lập admin/staff session.
 *
 * GET  /portal                    → login page hoặc portal (nếu đã đăng nhập)
 * GET  /portal?action=invoice-detail&id=X  → JSON chi tiết hóa đơn (chỉ HĐ của chính khách)
 * POST action=request-otp email=...         → gửi OTP về Gmail, sang bước nhập mã
 * POST action=verify-otp   otp=...          → xác minh OTP, vào portal
 * POST action=logout                        → thoát
 * POST action=update-profile  (hồ sơ sức khỏe: dị ứng, bệnh nền, DOB…)
 * POST action=redeem   points=X&label=...   → đổi điểm lấy ưu đãi
 */
@WebServlet("/portal")
public class CustomerPortalServlet extends HttpServlet {

    private final CustomerDAO customerDAO = new CustomerDAO();
    private final LoyaltyDAO  loyaltyDAO  = new LoyaltyDAO();
    private final InvoiceDAO  invoiceDAO  = new InvoiceDAO();
    private final IPrescriptionDAO prescriptionDAO = new PrescriptionDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String action = req.getParameter("action");
        HttpSession session = req.getSession(false);
        Customer me = session != null ? (Customer) session.getAttribute("portalCustomer") : null;

        if ("invoice-detail".equals(action)) {
            handleInvoiceDetail(req, resp, me);
            return;
        }
        if ("prescription-detail".equals(action)) {
            handlePrescriptionDetail(req, resp, me);
            return;
        }

        if (me == null) {
            req.getRequestDispatcher("/WEB-INF/views/portal/portal-login.jsp").forward(req, resp);
            return;
        }

        // Đọc lại bản mới nhất từ DB (hồ sơ có thể vừa được cập nhật ở POS)
        Customer fresh = customerDAO.findById(me.getCustomerId());
        if (fresh == null) {
            session.removeAttribute("portalCustomer");
            resp.sendRedirect(req.getContextPath() + "/portal");
            return;
        }
        session.setAttribute("portalCustomer", fresh);

        LoyaltyCard card = loyaltyDAO.getOrCreateCard(fresh.getCustomerId());
        List<Invoice> invoices = invoiceDAO.findByCustomer(fresh.getCustomerId());
        List<String[]> pointHistory = loyaltyDAO.history(fresh.getCustomerId(), 20);
        java.util.Map<Integer, Integer> invoicePoints = loyaltyDAO.earnedPointsByInvoice(fresh.getCustomerId());
        List<Prescription> prescriptions = prescriptionDAO.findByCustomer(fresh.getCustomerId());

        req.setAttribute("me",           fresh);
        req.setAttribute("card",         card);
        req.setAttribute("invoices",     invoices);
        req.setAttribute("pointHistory", pointHistory);
        req.setAttribute("invoicePoints", invoicePoints);
        req.setAttribute("prescriptions", prescriptions);
        req.getRequestDispatcher("/WEB-INF/views/portal/customer-portal.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "request-otp"    -> handleRequestOtp(req, resp);
            case "verify-otp"     -> handleVerifyOtp(req, resp);
            case "logout"         -> handleLogout(req, resp);
            case "update-profile" -> handleUpdateProfile(req, resp);
            case "redeem"         -> handleRedeem(req, resp);
            default               -> resp.sendRedirect(req.getContextPath() + "/portal");
        }
    }

    // ── ĐĂNG NHẬP BẰNG EMAIL + OTP (2 bước) ──────────────────────────────────
    private static final java.util.regex.Pattern EMAIL_RX =
            java.util.regex.Pattern.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");

    private static final int  OTP_LENGTH      = 6;
    private static final long OTP_TTL_MS      = 10 * 60 * 1000L;  // 10 phút
    private static final int  OTP_MAX_TRIES   = 5;

    private static final String S_OTP_CODE   = "portal_otp_code";
    private static final String S_OTP_CUST   = "portal_otp_customerId";
    private static final String S_OTP_EMAIL  = "portal_otp_email";
    private static final String S_OTP_EXP    = "portal_otp_exp";
    private static final String S_OTP_TRIES  = "portal_otp_tries";

    /** BƯỚC 1 — khách nhập Email → tìm khách, sinh OTP, gửi vào đúng Gmail đã cấp tại POS. */
    private void handleRequestOtp(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {
        String email = req.getParameter("email");
        if (email == null || !EMAIL_RX.matcher(email.trim()).matches()) {
            req.setAttribute("loginError", "Email không hợp lệ. Vui lòng nhập đúng định dạng email.");
            req.getRequestDispatcher("/WEB-INF/views/portal/portal-login.jsp").forward(req, resp);
            return;
        }
        email = email.trim();
        Customer c = customerDAO.findByEmail(email);
        if (c == null) {
            req.setAttribute("loginError",
                    "Email chưa được liên kết với tài khoản nào. Vui lòng nhờ dược sĩ cập nhật Email vào hồ sơ tại quầy MediCare.");
            req.setAttribute("emailPrefill", email);
            req.getRequestDispatcher("/WEB-INF/views/portal/portal-login.jsp").forward(req, resp);
            return;
        }

        String code = OtpUtil.generate(OTP_LENGTH);
        HttpSession session = req.getSession(true);
        session.setAttribute(S_OTP_CODE,  code);
        session.setAttribute(S_OTP_CUST,  c.getCustomerId());
        session.setAttribute(S_OTP_EMAIL, c.getEmail());
        session.setAttribute(S_OTP_EXP,   System.currentTimeMillis() + OTP_TTL_MS);
        session.setAttribute(S_OTP_TRIES, 0);

        EmailUtil.sendEmail(c.getEmail(), "[MediCare] Mã đăng nhập Customer Portal", buildOtpEmail(c, code));
        AuditHelper.log(req, "Portal yêu cầu OTP đăng nhập", "Customer", c.getCustomerId(),
                "Đã gửi OTP đăng nhập portal tới " + c.getEmail());

        req.setAttribute("maskedEmail", PasswordResetHelper.maskEmail(c.getEmail()));
        req.setAttribute("emailForResend", c.getEmail());
        req.getRequestDispatcher("/WEB-INF/views/portal/portal-otp.jsp").forward(req, resp);
    }

    /** BƯỚC 2 — khách nhập mã OTP nhận được trong Gmail → đúng thì mới tạo phiên đăng nhập. */
    private void handleVerifyOtp(HttpServletRequest req, HttpServletResponse resp)
            throws IOException, ServletException {
        HttpSession session = req.getSession(false);
        Object custObj = session != null ? session.getAttribute(S_OTP_CUST) : null;
        if (!(custObj instanceof Integer)) {
            req.setAttribute("loginError", "Phiên xác minh đã hết hạn. Vui lòng đăng nhập lại.");
            req.getRequestDispatcher("/WEB-INF/views/portal/portal-login.jsp").forward(req, resp);
            return;
        }

        long exp = session.getAttribute(S_OTP_EXP) instanceof Long ? (Long) session.getAttribute(S_OTP_EXP) : 0;
        if (System.currentTimeMillis() > exp) {
            clearOtpSession(session);
            req.setAttribute("loginError", "Mã OTP đã hết hạn. Vui lòng yêu cầu mã mới.");
            req.getRequestDispatcher("/WEB-INF/views/portal/portal-login.jsp").forward(req, resp);
            return;
        }

        int tries = session.getAttribute(S_OTP_TRIES) instanceof Integer ? (Integer) session.getAttribute(S_OTP_TRIES) : 0;
        if (tries >= OTP_MAX_TRIES) {
            clearOtpSession(session);
            req.setAttribute("loginError", "Bạn đã nhập sai OTP quá nhiều lần. Vui lòng đăng nhập lại.");
            req.getRequestDispatcher("/WEB-INF/views/portal/portal-login.jsp").forward(req, resp);
            return;
        }

        String input = req.getParameter("otp");
        String code  = (String) session.getAttribute(S_OTP_CODE);
        if (input == null || !code.equals(input.trim())) {
            session.setAttribute(S_OTP_TRIES, tries + 1);
            req.setAttribute("otpError", "Mã OTP không đúng. Còn " + (OTP_MAX_TRIES - tries - 1) + " lần thử.");
            req.setAttribute("maskedEmail", PasswordResetHelper.maskEmail((String) session.getAttribute(S_OTP_EMAIL)));
            req.setAttribute("emailForResend", session.getAttribute(S_OTP_EMAIL));
            req.getRequestDispatcher("/WEB-INF/views/portal/portal-otp.jsp").forward(req, resp);
            return;
        }

        int customerId = (Integer) custObj;
        clearOtpSession(session);
        Customer c = customerDAO.findById(customerId);
        if (c == null) {
            req.setAttribute("loginError", "Tài khoản không còn tồn tại.");
            req.getRequestDispatcher("/WEB-INF/views/portal/portal-login.jsp").forward(req, resp);
            return;
        }

        session.setAttribute("portalCustomer", c);
        AuditHelper.log(req, "Portal login", "Customer", c.getCustomerId(),
                "Khách " + c.getCustomerName() + " đăng nhập portal qua OTP email (" + c.getEmail() + ")");
        resp.sendRedirect(req.getContextPath() + "/portal");
    }

    private void clearOtpSession(HttpSession session) {
        session.removeAttribute(S_OTP_CODE);
        session.removeAttribute(S_OTP_CUST);
        session.removeAttribute(S_OTP_EMAIL);
        session.removeAttribute(S_OTP_EXP);
        session.removeAttribute(S_OTP_TRIES);
    }

    private String buildOtpEmail(Customer c, String code) {
        return """
            <div style="font-family:Arial,sans-serif;max-width:520px;margin:auto;padding:24px">
              <div style="background:linear-gradient(135deg,#0d9488,#0f766e);border-radius:14px;
                          padding:20px 24px;margin-bottom:20px;color:#fff">
                <h2 style="margin:0;font-size:18px">🔑 Mã đăng nhập MediCare Portal</h2>
                <p style="margin:6px 0 0;opacity:.85;font-size:13px">Xác nhận chính bạn đang đăng nhập</p>
              </div>
              <p style="font-size:14px;color:#0f172a">Xin chào <strong>%s</strong>,</p>
              <p style="font-size:13.5px;color:#334155;line-height:1.7">
                Nhập mã dưới đây để đăng nhập Customer Portal MediCare:
              </p>
              <div style="text-align:center;margin:22px 0">
                <div style="display:inline-block;background:#f1f5f9;border:2px dashed #0d9488;
                            border-radius:12px;padding:16px 30px;font-size:30px;font-weight:800;
                            letter-spacing:9px;color:#0d9488;font-family:monospace">%s</div>
              </div>
              <p style="font-size:12.5px;color:#64748b;line-height:1.6">
                Mã có hiệu lực trong <strong>10 phút</strong>.
              </p>
              <div style="background:#fffbeb;border:1px solid #fde68a;border-radius:10px;
                          padding:12px 15px;margin-top:18px">
                <p style="margin:0;font-size:12.5px;color:#92400e">
                  ⚠️ <strong>Bạn KHÔNG yêu cầu việc này?</strong> Hãy bỏ qua email này.
                </p>
              </div>
            </div>
            """.formatted(c.getCustomerName(), code);
    }

    private void handleLogout(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        if (session != null) session.removeAttribute("portalCustomer");
        resp.sendRedirect(req.getContextPath() + "/portal");
    }

    // ── Khách tự cập nhật HỒ SƠ SỨC KHỎE ─────────────────────────────────────
    private void handleUpdateProfile(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        HttpSession session = req.getSession(false);
        Customer me = session != null ? (Customer) session.getAttribute("portalCustomer") : null;
        if (me == null) { resp.sendRedirect(req.getContextPath() + "/portal"); return; }

        String email   = trimOrNull(req.getParameter("email"));
        String address = trimOrNull(req.getParameter("address"));
        String gender  = req.getParameter("gender");
        String allergy = trimOrNull(req.getParameter("allergy"));
        String chronic = trimOrNull(req.getParameter("chronic"));
        LocalDate dob = null;
        String dobStr = req.getParameter("dob");
        if (dobStr != null && !dobStr.isEmpty()) {
            try {
                dob = LocalDate.parse(dobStr);
                if (!dob.isBefore(LocalDate.now())) dob = null; // CK_Cust_DOB
            } catch (Exception ignored) {}
        }
        if (email != null && !email.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$")) email = null;

        boolean ok = customerDAO.updateProfileFromPortal(
                me.getCustomerId(), email, address, dob, gender, allergy, chronic);
        if (ok) {
            AuditHelper.log(req, "Portal cập nhật hồ sơ", "Customer", me.getCustomerId(),
                    "Khách " + me.getCustomerName() + " tự cập nhật hồ sơ sức khỏe qua portal");
        }
        resp.sendRedirect(req.getContextPath() + "/portal?msg=" + (ok ? "profile-saved" : "error") + "#account");
    }

    // ── ĐỔI ĐIỂM lấy ưu đãi ───────────────────────────────────────────────────
    private void handleRedeem(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        HttpSession session = req.getSession(false);
        Customer me = session != null ? (Customer) session.getAttribute("portalCustomer") : null;
        if (me == null) { out.print("{\"ok\":false,\"reason\":\"unauthorized\"}"); return; }

        int points = 0;
        try { points = Integer.parseInt(req.getParameter("points")); } catch (Exception ignored) {}
        String label = trimOrNull(req.getParameter("label"));
        // Chỉ chấp nhận các gói đổi cố định — chống client tự chế số điểm
        if (points != 100 && points != 300 && points != 500) {
            out.print("{\"ok\":false,\"reason\":\"invalid_offer\"}"); return;
        }

        boolean ok = loyaltyDAO.redeem(me.getCustomerId(), points,
                "Đổi ưu đãi: " + (label != null ? label : points + " điểm"));
        if (ok) {
            AuditHelper.log(req, "Portal đổi điểm", "Customer", me.getCustomerId(),
                    "Khách " + me.getCustomerName() + " đổi " + points + " điểm — " + label);
            LoyaltyCard card = loyaltyDAO.findByCustomer(me.getCustomerId());
            out.print("{\"ok\":true,\"remaining\":" + (card != null ? card.getAvailablePoints() : 0) + "}");
        } else {
            out.print("{\"ok\":false,\"reason\":\"not_enough_points\"}");
        }
    }

    // ── Chi tiết hóa đơn (AJAX) — chỉ trả HĐ thuộc về chính khách ─────────────
    private void handleInvoiceDetail(HttpServletRequest req, HttpServletResponse resp, Customer me)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        if (me == null) { out.print("{\"ok\":false,\"reason\":\"unauthorized\"}"); return; }

        int invId = 0;
        try { invId = Integer.parseInt(req.getParameter("id")); } catch (Exception ignored) {}

        StringBuilder items = new StringBuilder();
        String header = null;
        Integer prescriptionId = null;
        String sql = "SELECT inv.InvoiceCode, inv.FinalAmount, inv.DiscountAmount, inv.PaymentMethod, " +
                "inv.PrescriptionID, inv.PosStation, " +
                "CONVERT(VARCHAR(16), inv.CreatedAt, 120) AS CreatedAt, " +
                "m.MedicineName, m.Unit, b.BatchNumber, " +
                "CONVERT(VARCHAR(10), b.ExpiryDate, 120) AS ExpiryDate, " +
                "id.Quantity, id.UnitPrice, id.SubTotal " +
                "FROM Invoices inv " +
                "JOIN InvoiceDetails id ON id.InvoiceID = inv.InvoiceID " +
                "JOIN Batches b ON b.BatchID = id.BatchID " +
                "JOIN Medicines m ON m.MedicineID = b.MedicineID " +
                "WHERE inv.InvoiceID = ? AND inv.CustomerID = ?";  // ràng buộc chính chủ
        try (java.sql.Connection cn = com.medicare.config.DBContext.getConnection();
             java.sql.PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, invId);
            ps.setInt(2, me.getCustomerId());
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                boolean first = true;
                while (rs.next()) {
                    if (header == null) {
                        int pos = rs.getInt("PosStation");
                        boolean posNull = rs.wasNull();
                        Object presObj = rs.getObject("PrescriptionID");
                        prescriptionId = presObj != null ? rs.getInt("PrescriptionID") : null;
                        header = "\"code\":\"" + esc(rs.getString("InvoiceCode")) + "\"" +
                                ",\"time\":\"" + rs.getString("CreatedAt") + "\"" +
                                ",\"total\":" + rs.getBigDecimal("FinalAmount").toPlainString() +
                                ",\"discount\":" + (rs.getBigDecimal("DiscountAmount") != null
                                        ? rs.getBigDecimal("DiscountAmount").toPlainString() : "0") +
                                ",\"method\":\"" + esc(rs.getString("PaymentMethod")) + "\"" +
                                ",\"station\":" + (posNull ? "null" : pos) +
                                ",\"prescription\":" + (prescriptionId != null) +
                                ",\"prescriptionId\":" + (prescriptionId != null ? prescriptionId : "null") +
                                ",\"points\":" + loyaltyDAO.sumEarnedForInvoice(invId);
                    }
                    if (!first) items.append(",");
                    String exp = rs.getString("ExpiryDate");
                    items.append("{\"name\":\"").append(esc(rs.getString("MedicineName")))
                         .append("\",\"unit\":\"").append(esc(rs.getString("Unit")))
                         .append("\",\"batch\":\"").append(esc(rs.getString("BatchNumber")))
                         .append("\",\"expiry\":").append(exp != null ? "\"" + exp + "\"" : "null")
                         .append(",\"qty\":").append(rs.getInt("Quantity"))
                         .append(",\"price\":").append(rs.getBigDecimal("UnitPrice").toPlainString())
                         .append(",\"subtotal\":").append(rs.getBigDecimal("SubTotal").toPlainString())
                         .append("}");
                    first = false;
                }
            }
        } catch (Exception e) { e.printStackTrace(); }

        if (header == null) { out.print("{\"ok\":false,\"reason\":\"not_found\"}"); return; }
        out.print("{\"ok\":true," + header + ",\"items\":[" + items + "]}");
    }

    // ── Chi tiết đơn thuốc (AJAX) ─────────────────────────────────────────────
    private void handlePrescriptionDetail(HttpServletRequest req, HttpServletResponse resp, Customer me)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        if (me == null) { out.print("{\"ok\":false,\"reason\":\"unauthorized\"}"); return; }

        int prescId = 0;
        try { prescId = Integer.parseInt(req.getParameter("id")); } catch (Exception ignored) {}

        StringBuilder items = new StringBuilder();
        String header = null;

        String sqlPresc = "SELECT DoctorName, HospitalName, Notes, ImagePath, " +
                "CONVERT(VARCHAR(10), PrescriptionDate, 120) AS PrescriptionDate " +
                "FROM Prescriptions WHERE PrescriptionID = ? AND CustomerID = ?";

        String sqlDetails = "SELECT pd.DosageQuantity, pd.DosageUnit, pd.Frequency, pd.Duration, pd.UsageInstruction, pd.TotalPrescribedQty, " +
                "m.MedicineName, m.Unit " +
                "FROM PrescriptionDetails pd " +
                "JOIN Medicines m ON m.MedicineID = pd.MedicineID " +
                "WHERE pd.PrescriptionID = ?";

        try (java.sql.Connection cn = com.medicare.config.DBContext.getConnection()) {
            try (java.sql.PreparedStatement ps = cn.prepareStatement(sqlPresc)) {
                ps.setInt(1, prescId);
                ps.setInt(2, me.getCustomerId());
                try (java.sql.ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        header = "\"doctor\":\"" + esc(rs.getString("DoctorName")) + "\"" +
                                ",\"hospital\":\"" + esc(rs.getString("HospitalName")) + "\"" +
                                ",\"notes\":\"" + esc(rs.getString("Notes")) + "\"" +
                                ",\"date\":\"" + rs.getString("PrescriptionDate") + "\"" +
                                ",\"imagePath\":" + (rs.getString("ImagePath") != null ? "\"" + esc(rs.getString("ImagePath")) + "\"" : "null");
                    }
                }
            }
            if (header != null) {
                try (java.sql.PreparedStatement ps = cn.prepareStatement(sqlDetails)) {
                    ps.setInt(1, prescId);
                    try (java.sql.ResultSet rs = ps.executeQuery()) {
                        boolean first = true;
                        while (rs.next()) {
                            if (!first) items.append(",");
                            items.append("{\"name\":\"").append(esc(rs.getString("MedicineName")))
                                 .append("\",\"unit\":\"").append(esc(rs.getString("Unit")))
                                 .append("\",\"dosageQty\":").append(rs.getDouble("DosageQuantity"))
                                 .append(",\"dosageUnit\":\"").append(esc(rs.getString("DosageUnit")))
                                 .append("\",\"frequency\":\"").append(esc(rs.getString("Frequency")))
                                 .append("\",\"duration\":").append(rs.getInt("Duration"))
                                 .append(",\"instruction\":\"").append(esc(rs.getString("UsageInstruction")))
                                 .append("\",\"totalQty\":").append(rs.getInt("TotalPrescribedQty"))
                                 .append("}");
                            first = false;
                        }
                    }
                }
            }
        } catch (Exception e) { e.printStackTrace(); }

        if (header == null) { out.print("{\"ok\":false,\"reason\":\"not_found\"}"); return; }
        out.print("{\"ok\":true," + header + ",\"items\":[" + items + "]}");
    }

    private String trimOrNull(String s) {
        if (s == null) return null;
        String t = s.trim();
        return t.isEmpty() ? null : t;
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
