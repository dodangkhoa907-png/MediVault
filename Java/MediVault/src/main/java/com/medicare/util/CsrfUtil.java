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

        // Ưu tiên form field, fallback sang header (AJAX)
        String requestToken = req.getParameter(FORM_PARAM);
        if (requestToken == null || requestToken.isEmpty())
            requestToken = req.getHeader(HEADER_NAME);

        return sessionToken.equals(requestToken);
    }

    // ── AppFilter helper ──────────────────────────────────────────────────

    /**
     * Đặt CSRF token vào request attribute để JSP có thể đọc bằng ${csrfToken}.
     * Gọi từ AppFilter trước khi forward.
     */
    public static void injectToRequest(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) return;
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
        // Public endpoints (login, otp...) không cần CSRF vì chưa có session
        String uri = req.getRequestURI();
        String ctx = req.getContextPath();
        return !uri.equals(ctx + "/login")
                && !uri.equals(ctx + "/staff-login")
                && !uri.equals(ctx + "/forgot-password")
                && !uri.equals(ctx + "/otp-verify")
                && !uri.startsWith(ctx + "/nfc-checkin")
                && !uri.startsWith(ctx + "/api/nfc");
    }

    // ── Private ───────────────────────────────────────────────────────────

    private static String generateToken() {
        byte[] bytes = new byte[32]; // 256-bit token
        SECURE_RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
