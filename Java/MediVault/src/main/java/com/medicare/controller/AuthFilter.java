package com.medicare.controller;

import com.medicare.dao.AccountDAO;
import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.entity.Account;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.Set;

@WebFilter(urlPatterns = "/*", asyncSupported = true)
public class AuthFilter implements Filter {

    // ── Tên cookie lưu nhận dạng đăng nhập ──
    private static final String COOKIE_ADMIN          = "mv_admin_uid";       // session 8h, KHÔNG auto-restore
    private static final String COOKIE_ADMIN_REMEMBER = "mv_admin_remember";  // 7 ngày, CÓ auto-restore
    private static final String COOKIE_STAFF = "mv_staff_uid";
    private static final int    COOKIE_MAX_AGE = 60 * 60 * 24 * 7; // 7 ngày (Remember Me)

    // ── Chặn ADMIN theo IP — CHỈ áp dụng cho admin, KHÔNG áp dụng cho staff/POS/portal.
    // 172.29.48.1 = IP WiFi của máy admin. Cho phép thêm localhost để admin vẫn test được
    // trực tiếp trên máy chủ (127.0.0.1 / ::1 — Tomcat có thể trả 1 trong 2 dạng tuỳ kết nối).
    // Áp dụng ở CẢ 2 nơi: lúc đăng nhập (LoginServlet gọi isAdminIpAllowed) VÀ mọi request admin
    // sau đó (isAdminOnly bên dưới) — để cookie/session admin bị lộ từ máy khác cũng không dùng được.
    private static final Set<String> ADMIN_IP_WHITELIST = Set.of(
            "172.29.48.1",
            "127.0.0.1", "0:0:0:0:0:0:0:1", "::1"
    );

    public static boolean isAdminIpAllowed(HttpServletRequest req) {
        String ip = req.getRemoteAddr();
        return ip != null && ADMIN_IP_WHITELIST.contains(ip);
    }

    private final IAccountDAO accountDAO = new AccountDAO();

    // ── Tiện ích: đọc giá trị cookie theo tên ──
    private String getCookieValue(HttpServletRequest req, String name) {
        Cookie[] cookies = req.getCookies();
        if (cookies == null) return null;
        for (Cookie c : cookies) {
            if (name.equals(c.getName())) return c.getValue();
        }
        return null;
    }

    // ── Tiện ích: set cookie Remember Me ──
    private void setRememberCookie(HttpServletResponse resp, String name, String value) {
        Cookie c = new Cookie(name, value);
        c.setMaxAge(COOKIE_MAX_AGE);
        c.setPath("/");
        c.setHttpOnly(true);   // bảo mật: JS không đọc được
        resp.addCookie(c);
    }

    // ── Tiện ích: xóa cookie ──
    private void clearCookie(HttpServletResponse resp, String name) {
        Cookie c = new Cookie(name, "");
        c.setMaxAge(0);
        c.setPath("/");
        resp.addCookie(c);
    }

    // ── Ghi cookie sau khi login thành công — GỌI TỪ LoginServlet / StaffLoginServlet ──
    public static void writeAdminCookie(HttpServletResponse resp, int accountId) {
        Cookie c = new Cookie("mv_admin_uid", String.valueOf(accountId));
        c.setMaxAge(60 * 60 * 8);
        c.setPath("/");
        c.setHttpOnly(true);
        resp.addCookie(c);
    }

    /** Remember Me: ghi cookie dài hạn mv_admin_remember (7 ngày) — KHÁC cookie session thường */
    public static void writeAdminCookieLong(HttpServletResponse resp, int accountId, int maxAgeSeconds) {
        // Ghi cookie Remember Me riêng (mv_admin_remember) — AuthFilter chỉ restore loại này
        Cookie c = new Cookie("mv_admin_remember", String.valueOf(accountId));
        c.setMaxAge(maxAgeSeconds);
        c.setPath("/");
        c.setHttpOnly(true);
        resp.addCookie(c);
        // Cũng ghi cookie session bình thường để request hiện tại hoạt động
        Cookie s = new Cookie("mv_admin_uid", String.valueOf(accountId));
        s.setMaxAge(60 * 60 * 8);
        s.setPath("/");
        s.setHttpOnly(true);
        resp.addCookie(s);
    }

    public static void writeStaffCookie(HttpServletResponse resp, int accountId) {
        Cookie c = new Cookie("mv_staff_uid", String.valueOf(accountId));
        c.setMaxAge(60 * 60 * 8);
        c.setPath("/");
        c.setHttpOnly(true);
        resp.addCookie(c);
    }

    // ── Xóa tất cả cookie khi logout ──
    public static void clearAllCookies(HttpServletResponse resp) {
        Cookie a = new Cookie("mv_admin_uid", "");
        a.setMaxAge(0); a.setPath("/"); resp.addCookie(a);
        Cookie r = new Cookie("mv_admin_remember", ""); // xóa Remember Me
        r.setMaxAge(0); r.setPath("/"); resp.addCookie(r);
        Cookie s = new Cookie("mv_staff_uid", "");
        s.setMaxAge(0); s.setPath("/"); resp.addCookie(s);
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response,
                         FilterChain chain) throws IOException, ServletException {
        HttpServletRequest  req  = (HttpServletRequest)  request;
        HttpServletResponse resp = (HttpServletResponse) response;

        String uri = req.getRequestURI();
        String ctx = req.getContextPath();

        // ── 1. Public URLs — không cần đăng nhập ──
        boolean isPublic = uri.equals(ctx + "/login")
                || uri.equals(ctx + "/staff-login")
                || uri.startsWith(ctx + "/assets")
                || uri.startsWith(ctx + "/css")
                || uri.startsWith(ctx + "/js")
                || uri.startsWith(ctx + "/models")   // face-api.js model files (manifest + weights)
                || uri.startsWith(ctx + "/WEB-INF")
                || uri.equals(ctx + "/otp-verify")
                || uri.startsWith(ctx + "/staff-shift")
                || uri.equals(ctx + "/forgot-password")
                || uri.startsWith(ctx + "/admin/confirm-reset")
                || uri.equals(ctx + "/staff-ping")
                // ── NFC: không cần session — xác thực bằng cardId ──
                || uri.startsWith(ctx + "/nfc-checkin")
                || uri.startsWith(ctx + "/api/nfc")
                // ── Customer Portal: khách hàng đăng nhập bằng SĐT, tự quản session riêng ──
                || uri.startsWith(ctx + "/portal");

        // ── 2. Lấy session hiện tại (không tạo mới) ──
        HttpSession session = req.getSession(false);
        Account adminAcc = session != null ? (Account) session.getAttribute("adminAccount") : null;
        // Chặn ADMIN theo IP — CHỈ admin, không đụng tới staffAcc bên dưới. Nếu IP hiện tại
        // không nằm trong whitelist thì coi như CHƯA đăng nhập cho MỌI quyết định routing bên
        // dưới (redirect "/", "/login", "/dashboard", isAdminOnly...) — nhưng KHÔNG xoá
        // session.removeAttribute, để mạng chập chờn/đổi IP tạm thời không tự đăng xuất admin
        // thật; request tiếp theo từ đúng IP whitelist vẫn dùng lại được session cũ bình thường.
        if (adminAcc != null && !isAdminIpAllowed(req)) {
            adminAcc = null;
        }

        // Lấy staffAccount từ URL param uid — mỗi tab tự mang uid của mình
        Account staffAcc = null;
        String reqUid = req.getParameter("uid");
        if (reqUid != null && !reqUid.isEmpty() && session != null) {
            staffAcc = (Account) session.getAttribute("staffAccount_" + reqUid);
        }

        // Chỉ quét toàn bộ staffAccount_* khi request KHÔNG mang uid cụ thể — nếu URL
        // đã chỉ rõ uid mà không khớp session nào thì coi như KHÔNG có danh tính, tránh
        // việc rơi về nhầm 1 tài khoản khác còn sót trong session (máy dùng chung).
        boolean uidSpecified = reqUid != null && !reqUid.isEmpty();
        if (staffAcc == null && session != null && !uidSpecified) {
            java.util.Enumeration<String> names = session.getAttributeNames();
            while (names.hasMoreElements()) {
                String name = names.nextElement();
                if (name.startsWith("staffAccount_")) {
                    Object val = session.getAttribute(name);
                    if (val instanceof Account) {
                        staffAcc = (Account) val;
                        break;
                    }
                }
            }
        }

        // ── 3. REMEMBER ME — Tự restore session từ cookie nếu session đã mất ──
        //    Xảy ra khi: Ctrl+R reload, session timeout, Tomcat restart
        //    Không áp dụng cho trang public và logout
        if (!isPublic && !uri.equals(ctx + "/logout") && !uri.startsWith(ctx + "/pos")) {

            // Restore adminAccount — CHỈ khi có cookie Remember Me (mv_admin_remember)
            // Cookie session thường (mv_admin_uid) KHÔNG restore → admin phải login lại sau khi đóng browser
            // KHÔNG restore nếu IP hiện tại không nằm trong whitelist — cookie Remember Me lộ ra
            // máy/mạng khác cũng không tự đăng nhập lại được.
            if (adminAcc == null && isAdminIpAllowed(req)) {
                String rememberVal = getCookieValue(req, COOKIE_ADMIN_REMEMBER);
                if (rememberVal != null && !rememberVal.isEmpty()) {
                    try {
                        int uid = Integer.parseInt(rememberVal);
                        Account a = accountDAO.findById(uid);
                        if (a != null && a.isActive() && a.getRoleId() == 1 && !a.isDeleted()) {
                            if (session == null) session = req.getSession(true);
                            session.setAttribute("adminAccount", a);
                            adminAcc = a;
                            // Gia hạn Remember Me thêm 7 ngày
                            setRememberCookie(resp, COOKIE_ADMIN_REMEMBER, rememberVal);
                        } else {
                            clearCookie(resp, COOKIE_ADMIN_REMEMBER);
                        }
                    } catch (NumberFormatException ignored) {
                        clearCookie(resp, COOKIE_ADMIN_REMEMBER);
                    }
                }
            }

        }

        // ── 4. Root URL "/" — redirect theo trạng thái login ──
        if (uri.equals(ctx + "/") || uri.equals(ctx)) {
            if (adminAcc != null) {
                resp.sendRedirect(ctx + "/dashboard");      // đã login admin → vào dashboard
            } else if (staffAcc != null) {
                resp.sendRedirect(ctx + "/staff-dashboard?uid=" + staffAcc.getAccountId());
            } else {
                resp.sendRedirect(ctx + "/login");           // chưa login → về login
            }
            return;
        }

        // ── 4b. /login — nếu đã login admin thì redirect vào dashboard ──
        if (uri.equals(ctx + "/login")) {
            if (adminAcc != null) {
                resp.sendRedirect(ctx + "/dashboard");
                return;
            }
            chain.doFilter(request, response);
            return;
        }
        if (uri.equals(ctx + "/staff-login")) {
            // Không redirect nếu đang ở staff-login (cho phép login staff mới)
            chain.doFilter(request, response); return;
        }

        if (isPublic) { chain.doFilter(request, response); return; }

        // ── 5. /pos — PUBLIC hoàn toàn ──
        if (uri.startsWith(ctx + "/pos")) {
            chain.doFilter(request, response);
            return;
        }

        // ── 6. /dashboard — cho cả 2 role, DashboardServlet tự phân luồng ──
        if (uri.equals(ctx + "/dashboard") || uri.equals(ctx + "/dashboard/")) {
            if (adminAcc == null && staffAcc == null) {
                resp.sendRedirect(ctx + "/login");
                return;
            }
            chain.doFilter(request, response);
            return;
        }

        // ── 7. Trang chỉ dành cho Admin ──
        boolean isAdminOnly = uri.startsWith(ctx + "/accounts")
                || uri.startsWith(ctx + "/reports")
                || uri.startsWith(ctx + "/categories")
                || uri.startsWith(ctx + "/shifts")
                || uri.startsWith(ctx + "/invoices")
                || uri.startsWith(ctx + "/customers")
                || uri.startsWith(ctx + "/medicines")
                || uri.startsWith(ctx + "/purchase-orders")
                || uri.startsWith(ctx + "/returns")
                || uri.startsWith(ctx + "/suppliers")
                || uri.startsWith(ctx + "/shelves")
                || uri.startsWith(ctx + "/account-detail-api")
                || uri.startsWith(ctx + "/audit-logs")
                || uri.startsWith(ctx + "/admin/reset-requests")
                || uri.startsWith(ctx + "/shift-schedules")
                || uri.startsWith(ctx + "/attendance")
                || uri.startsWith(ctx + "/payroll")
                || uri.startsWith(ctx + "/shift-types");

        if (isAdminOnly) {
            boolean hasAccess = false;
            if (adminAcc != null && adminAcc.getRoleId() == 1) {
                hasAccess = true;
            } else if (staffAcc != null && staffAcc.getRoleId() == 3) {
                boolean isStorekeeperAllowed = uri.startsWith(ctx + "/medicines")
                        || uri.startsWith(ctx + "/categories")
                        || uri.startsWith(ctx + "/shelves")
                        || uri.startsWith(ctx + "/suppliers")
                        || uri.startsWith(ctx + "/purchase-orders")
                        || uri.startsWith(ctx + "/returns");
                if (isStorekeeperAllowed) {
                    hasAccess = true;
                }
            }

            if (!hasAccess) {
                // Nếu là AJAX request (polling online-status) → trả 401 thay vì redirect HTML
                String xrw = req.getHeader("X-Requested-With");
                if ("XMLHttpRequest".equals(xrw)) {
                    resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                    resp.setContentType("application/json;charset=UTF-8");
                    resp.getWriter().print("{\"error\":\"session_expired\"}");
                    return;
                }
                // Browser navigate → redirect về login
                String qs = req.getQueryString();
                String fullUri = uri + (qs != null ? "?" + qs : "");
                req.getSession(true).setAttribute("redirectAfterLogin", fullUri);
                resp.sendRedirect(ctx + "/login");
                return;
            }
            chain.doFilter(request, response);
            return;
        }

        // ── 8. Trang chỉ dành cho Staff ──
        if (uri.startsWith(ctx + "/staff-dashboard")
                || uri.equals(ctx + "/staff-profile")
                || uri.startsWith(ctx + "/staff-notifications")
                || uri.startsWith(ctx + "/staff-my-shifts")
                || uri.startsWith(ctx + "/staff-my-invoices")
                || uri.startsWith(ctx + "/staff-checkin")
                || (uri.startsWith(ctx + "/leave-requests")
                && req.getParameter("uid") != null)) {
            if (staffAcc == null) {
                resp.sendRedirect(ctx + "/staff-login");
                return;
            }
            chain.doFilter(request, response);
            return;
        }

        // ── 9. Logout — luôn cho qua ──
        if (uri.equals(ctx + "/logout")) {
            chain.doFilter(request, response);
            return;
        }

        // ── 10. Các URL khác — cần ít nhất 1 session ──
        if (adminAcc == null && staffAcc == null) {
            resp.sendRedirect(ctx + "/login");
            return;
        }

        chain.doFilter(request, response);
    }
}