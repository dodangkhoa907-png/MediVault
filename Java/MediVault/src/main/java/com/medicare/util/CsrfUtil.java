package com.medicare.util;

import jakarta.servlet.http.*;

import java.security.SecureRandom;
import java.util.Base64;

/**
 * CsrfUtil — Tiện ích chống tấn công CSRF (Cross-Site Request Forgery).
 *
 * Cách hoạt động:
 *   1. Trên mỗi GET request có session: gọi getOrCreate() → nhận token.
 *      AppFilter tự đặt token vào request attribute "csrfToken".
 *   2. JSP nhúng token vào form:
 *      {@code <input type="hidden" name="_csrf" value="${csrfToken}">}
 *   3. Trên POST request: AppFilter gọi isValid() để kiểm tra.
 *
 * AJAX requests: gửi token qua header "X-CSRF-Token" thay vì form field.
 *   {@code fetch(url, { headers: { 'X-CSRF-Token': csrfMeta } })}
 *
 * Lưu ý cho Frontend (antigravity):
 *   - Thêm vào tất cả form POST: {@code <input type="hidden" name="_csrf" value="${csrfToken}">}
 *   - Thêm meta tag vào head: {@code <meta name="csrf-token" content="${csrfToken}">}
 *   - Với fetch API: header {@code 'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content}
 */
public final class CsrfUtil {

    private static final String SESSION_ATTR   = "_csrf_token";
    private static final String REQUEST_ATTR   = "csrfToken";
    private static final String FORM_PARAM     = "_csrf";
    private static final String HEADER_NAME    = "X-CSRF-Token";

    private static final SecureRandom SECURE_RANDOM = new SecureRandom();

    private CsrfUtil() {}

    // ── Token management ─────────────────────────────────────────────────

    /**
     * Trả về CSRF token hiện tại của session, hoặc tạo mới nếu chưa có.
     * Thread-safe: HttpSession synchronize internally.
     */
    public static String getOrCreate(HttpSession session) {
        String token = (String) session.getAttribute(SESSION_ATTR);
        if (token == null) {
            token = generateToken();
            session.setAttribute(SESSION_ATTR, token);
        }
        return token;
    }

    /**
     * Sinh token mới (thay thế token cũ trong session).
     * Nên gọi sau mỗi lần login thành công để tránh session fixation.
     */
    public static String rotate(HttpSession session) {
        String token = generateToken();
        session.setAttribute(SESSION_ATTR, token);
        return token;
    }

    // ── Validation ────────────────────────────────────────────────────────

    /**
     * Kiểm tra CSRF token trong POST request có hợp lệ không.
     * Tìm token theo thứ tự: form field "_csrf" → header "X-CSRF-Token".
     *
     * @return true nếu token khớp; false nếu session null, token null/không khớp
     */
    public static boolean isValid(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) return false;

        String sessionToken = (String) session.getAttribute(SESSION_ATTR);
        if (sessionToken == null) return false;

        String requestToken;
        if (isMultipart(req)) {
            // ── Request multipart (form upload ảnh, hoặc fetch gửi FormData) ──
            // KHÔNG gọi getParameter() ở đây: với multipart, các field nằm trong BODY và
            // việc đụng vào getParameter() từ Filter có thể kích hoạt parse body sớm, khiến
            // servlet phía sau đọc file upload thất bại. Vì vậy token của luồng multipart
            // phải đi bằng 1 trong 2 đường KHÔNG nằm trong body:
            //   • form HTML  → gắn vào action:  action="...?_csrf=${csrfToken}"
            //   • fetch/AJAX → gắn vào header:  X-CSRF-Token
            requestToken = fromQueryString(req.getQueryString());
        } else {
            requestToken = req.getParameter(FORM_PARAM);
        }

        if (requestToken == null || requestToken.isEmpty())
            requestToken = req.getHeader(HEADER_NAME);

        // So sánh theo kiểu không phụ thuộc thời gian (chống timing attack)
        return requestToken != null && constantTimeEquals(sessionToken, requestToken);
    }

    /** Request có phải multipart/form-data không (body chứa file upload). */
    private static boolean isMultipart(HttpServletRequest req) {
        String ct = req.getContentType();
        return ct != null && ct.toLowerCase().startsWith("multipart/");
    }

    /** Bóc giá trị _csrf từ query string thô, không đụng tới getParameter(). */
    private static String fromQueryString(String qs) {
        if (qs == null || qs.isEmpty()) return null;
        for (String pair : qs.split("&")) {
            int eq = pair.indexOf('=');
            if (eq <= 0) continue;
            if (FORM_PARAM.equals(pair.substring(0, eq))) {
                String raw = pair.substring(eq + 1);
                try {
                    return java.net.URLDecoder.decode(raw, java.nio.charset.StandardCharsets.UTF_8);
                } catch (Exception e) {
                    return raw;
                }
            }
        }
        return null;
    }

    /** So sánh chuỗi với thời gian không đổi theo nội dung. */
    private static boolean constantTimeEquals(String a, String b) {
        byte[] x = a.getBytes(java.nio.charset.StandardCharsets.UTF_8);
        byte[] y = b.getBytes(java.nio.charset.StandardCharsets.UTF_8);
        return java.security.MessageDigest.isEqual(x, y);
    }

    // ── AppFilter helper ──────────────────────────────────────────────────

    /**
     * Đặt CSRF token vào request attribute để JSP có thể đọc bằng ${csrfToken}.
     * Gọi từ AppFilter trước khi forward.
     */
    public static void injectToRequest(HttpServletRequest req) {
        // getSession(TRUE) — cố ý tạo session nếu chưa có. Trước đây dùng getSession(false)
        // nên trang nào render khi chưa có session sẽ nhận ${csrfToken} RỖNG, form in ra
        // token rỗng và mọi POST từ trang đó sẽ bị chặn oan. Có token ngay từ lần vào đầu
        // tiên thì mới bảo vệ được cả những trang chưa đăng nhập (vd màn POS kiosk).
        HttpSession session = req.getSession(true);
        String token = getOrCreate(session);
        req.setAttribute(REQUEST_ATTR, token);
    }

    /**
     * Kiểm tra request này có cần validate CSRF không.
     * Bỏ qua: GET/HEAD/OPTIONS + public endpoints + multipart uploads.
     */
    public static boolean requiresValidation(HttpServletRequest req) {
        String method = req.getMethod();
        // Chỉ validate POST/PUT/DELETE/PATCH
        if ("GET".equals(method) || "HEAD".equals(method) || "OPTIONS".equals(method))
            return false;

        String uri = req.getRequestURI();
        String ctx = req.getContextPath();

        // ── Miễn CSRF cho 2 nhóm, VÀ CHỈ 2 nhóm này ──────────────────────────────
        // (1) Các form ĐĂNG NHẬP / khôi phục mật khẩu: người dùng chưa có phiên làm việc
        //     nào để bảo vệ, mà chặn nhầm ở đây thì hỏng luôn đường vào hệ thống.
        //     Rủi ro còn lại chỉ là "login CSRF" — mức độ thấp hơn nhiều.
        // (2) Endpoint gọi bởi THIẾT BỊ, không phải trình duyệt (máy quét thẻ NFC) —
        //     không có chỗ nào để đính token vào.
        // Ngoài 2 nhóm trên, MỌI POST khác đều phải có token hợp lệ.
        return !uri.equals(ctx + "/login")
                && !uri.equals(ctx + "/staff-login")
                && !uri.equals(ctx + "/warehouse-login")
                && !uri.equals(ctx + "/forgot-password")
                && !uri.equals(ctx + "/warehouse-forgot-password")
                && !uri.equals(ctx + "/otp-verify")
                && !uri.startsWith(ctx + "/nfc-checkin")
                && !uri.startsWith(ctx + "/api/nfc")
                // /logout: staff-dashboard.jsp/staff-profile.jsp tự logout bằng
                // navigator.sendBeacon() khi ĐÓNG TAB THẬT SỰ (không phải chuyển trang) —
                // sendBeacon() không có cách nào gắn header tuỳ ý nên không thể mang token.
                // Ép CSRF ở đây vô nghĩa: bị dụ logout ép buộc chỉ gây phiền (phải đăng nhập
                // lại), không rò rỉ dữ liệu hay đổi trạng thái nghiệp vụ nào.
                && !uri.equals(ctx + "/logout");
    }

    // ── Private ───────────────────────────────────────────────────────────

    private static String generateToken() {
        byte[] bytes = new byte[32]; // 256-bit token
        SECURE_RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
