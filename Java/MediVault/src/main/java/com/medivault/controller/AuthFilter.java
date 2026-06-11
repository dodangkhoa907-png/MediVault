package com.medivault.controller;

import com.medivault.dao.AccountDAO;
import com.medivault.dao.interfaces.IAccountDAO;
import com.medivault.entity.Account;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebFilter("/*")
public class AuthFilter implements Filter {

    // ── Tên cookie lưu nhận dạng đăng nhập ──
    private static final String COOKIE_ADMIN = "mv_admin_uid";
    private static final String COOKIE_STAFF = "mv_staff_uid";
    private static final int    COOKIE_MAX_AGE = 60 * 60 * 24 * 7; // 7 ngày (Remember Me)

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

    /** Remember Me: cookie với thời gian tùy chỉnh (giây) */
    public static void writeAdminCookieLong(HttpServletResponse resp, int accountId, int maxAgeSeconds) {
        Cookie c = new Cookie("mv_admin_uid", String.valueOf(accountId));
        c.setMaxAge(maxAgeSeconds);
        c.setPath("/");
        c.setHttpOnly(true);
        resp.addCookie(c);
    }

    public static void writeStaffCookie(HttpServletResponse resp, int accountId) {
        Cookie c = new Cookie("mv_staff_uid", String.valueOf(accountId));
        c.setMaxAge(60 * 60 * 8);
        c.setPath("/");
        c.setHttpOnly(true);
        resp.addCookie(c);
    }

    // ── Xóa cả 2 cookie khi logout ──
    public static void clearAllCookies(HttpServletResponse resp) {
        Cookie a = new Cookie("mv_admin_uid", "");
        a.setMaxAge(0); a.setPath("/"); resp.addCookie(a);
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
                || uri.startsWith(ctx + "/WEB-INF")
                || uri.equals(ctx + "/otp-verify")
                || uri.startsWith(ctx + "/staff-shift")
                || uri.equals(ctx + "/forgot-password")
                || uri.startsWith(ctx + "/admin/confirm-reset")
                || uri.equals(ctx + "/staff-ping")
                // ── NFC: không cần session — xác thực bằng cardId ──
                || uri.startsWith(ctx + "/nfc-checkin")
                || uri.startsWith(ctx + "/api/nfc");

        // ── 2. Lấy session hiện tại (không tạo mới) ──
        HttpSession session = req.getSession(false);
        Account adminAcc = session != null ? (Account) session.getAttribute("adminAccount") : null;

        // Lấy staffAccount từ URL param uid — mỗi tab tự mang uid của mình
        Account staffAcc = null;
        String reqUid = req.getParameter("uid");
        if (reqUid != null && !reqUid.isEmpty() && session != null) {
            staffAcc = (Account) session.getAttribute("staffAccount_" + reqUid);
        }

        if (staffAcc == null && session != null) {
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

            // Restore adminAccount từ cookie nếu chưa có trong session
            if (adminAcc == null) {
                String adminCookieVal = getCookieValue(req, COOKIE_ADMIN);
                if (adminCookieVal != null && !adminCookieVal.isEmpty()) {
                    try {
                        int uid = Integer.parseInt(adminCookieVal);
                        Account a = accountDAO.findById(uid);
                        // Validate: tồn tại + active + là admin + chưa bị xóa
                        if (a != null && a.isActive() && a.getRoleId() == 1 && !a.isDeleted()) {
                            if (session == null) session = req.getSession(true);
                            session.setAttribute("adminAccount", a);
                            adminAcc = a;
                            // Gia hạn cookie thêm 8 tiếng nữa
                            setRememberCookie(resp, COOKIE_ADMIN, adminCookieVal);
                        } else {
                            // Cookie không hợp lệ → xóa đi
                            clearCookie(resp, COOKIE_ADMIN);
                        }
                    } catch (NumberFormatException ignored) {
                        clearCookie(resp, COOKIE_ADMIN);
                    }
                }
            }

            // Restore staffAccount từ DB khi session mất hoàn toàn (Ctrl+R, timeout)
            // Chỉ restore nếu URL có uid — không đoán uid
            if (staffAcc == null && reqUid != null && !reqUid.isEmpty()) {
                try {
                    int uid = Integer.parseInt(reqUid);
                    Account a = accountDAO.findById(uid);
                    if (a != null && a.isActive() && a.getRoleId() != 1 && !a.isDeleted()) {
                        if (session == null) session = req.getSession(true);
                        session.setAttribute("staffAccount_" + uid, a);
                        staffAcc = a;
                        com.medivault.util.SessionTracker.login(uid);
                    }
                } catch (NumberFormatException ignored) {}
            }
        }

        // ── 4. Xử lý login page redirect ──
        if (uri.equals(ctx + "/") || uri.equals(ctx)) {
            if (adminAcc != null) {
                resp.sendRedirect(ctx + "/login");
            } else if (staffAcc != null) {
                resp.sendRedirect(ctx + "/staff-dashboard?uid=" + staffAcc.getAccountId());
            }
            return; // Chặn lại không cho chạy tiếp xuống dưới
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
                || uri.startsWith(ctx + "/account-detail-api")
                || uri.startsWith(ctx + "/audit-logs")
                || uri.startsWith(ctx + "/admin/reset-requests")
                || uri.startsWith(ctx + "/shift-schedules")
                || uri.startsWith(ctx + "/attendance")
                || uri.startsWith(ctx + "/payroll")
                || uri.startsWith(ctx + "/shift-types");

        if (isAdminOnly) {
            if (adminAcc == null) {
                // Lưu trang định vào để sau login redirect đúng chỗ
                String qs = req.getQueryString();
                String fullUri = uri + (qs != null ? "?" + qs : "");
                req.getSession(true).setAttribute("redirectAfterLogin", fullUri);
                resp.sendRedirect(ctx + "/login");
                return;
            }
            if (adminAcc.getRoleId() != 1) {
                resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền!");
                return;
            }
            chain.doFilter(request, response);
            return;
        }

        // ── 8. Trang chỉ dành cho Staff ──
        if (uri.startsWith(ctx + "/staff-dashboard")
                || uri.equals(ctx + "/staff-profile")
                || uri.startsWith(ctx + "/staff-my-shifts")
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