package com.medivault.controller;

import com.medivault.entity.Account;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebFilter("/*")
public class AuthFilter implements Filter {

    public void doFilter(ServletRequest request, ServletResponse response,
                         FilterChain chain) throws IOException, ServletException {
        HttpServletRequest  req  = (HttpServletRequest)  request;
        HttpServletResponse resp = (HttpServletResponse) response;

        String uri      = req.getRequestURI();
        String ctx      = req.getContextPath();
        String query    = req.getQueryString(); // lấy query string để check API call

        // ── 1. Public URLs — không cần đăng nhập ──
        boolean isPublic = uri.equals(ctx + "/login")
                || uri.equals(ctx + "/staff-login")
                || uri.startsWith(ctx + "/assets")
                || uri.startsWith(ctx + "/css")
                || uri.startsWith(ctx + "/js")
                || uri.startsWith(ctx + "/WEB-INF")
                || uri.equals(ctx + "/otp-verify");

        HttpSession session = req.getSession(false);
        Account adminAcc = session != null ? (Account) session.getAttribute("adminAccount") : null;
        Account staffAcc = session != null ? (Account) session.getAttribute("staffAccount") : null;

        // ── Nếu đã login rồi mà vào trang login → redirect về đúng chỗ ──
        if (uri.equals(ctx + "/login")) {
            // CHỈ redirect nếu đã login là ADMIN
            // staffAccount KHÔNG redirect về /dashboard — gây redirect loop!
            if (adminAcc != null) { resp.sendRedirect(ctx + "/dashboard"); return; }
            chain.doFilter(request, response); return;
        }
        if (uri.equals(ctx + "/staff-login")) {
            if (staffAcc != null && staffAcc.getRoleId() != 1) {
                resp.sendRedirect(ctx + "/staff-dashboard"); return;
            }
            chain.doFilter(request, response); return;
        }

        if (isPublic) { chain.doFilter(request, response); return; }

        // ── 2. /pos — PUBLIC hoàn toàn, không cần login ──
        // POS là quầy bán hàng công cộng, ai cũng dùng được
        // Điểm danh được xử lý riêng qua sidebar hover trong pos.jsp
        if (uri.startsWith(ctx + "/pos")) {
            chain.doFilter(request, response);
            return;
        }

        // ── 3. /dashboard — dùng chung, DashboardServlet tự phân luồng ──
        if (uri.equals(ctx + "/dashboard") || uri.equals(ctx + "/dashboard/")) {
            if (adminAcc == null && staffAcc == null) {
                resp.sendRedirect(ctx + "/login");
                return;
            }
            chain.doFilter(request, response);
            return;
        }

        // ── 4. Trang chỉ dành cho Admin ──
        boolean isAdminOnly = uri.startsWith(ctx + "/accounts")
                || uri.startsWith(ctx + "/reports")
                || uri.startsWith(ctx + "/categories")
                || uri.startsWith(ctx + "/shifts")
                || uri.startsWith(ctx + "/invoices")
                || uri.startsWith(ctx + "/customers")
                || uri.startsWith(ctx + "/medicines")
                || uri.startsWith(ctx + "/account-detail-api");

        if (isAdminOnly) {
            if (adminAcc == null) {
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

        // ── 5. Trang chỉ dành cho Staff ──
        if (uri.startsWith(ctx + "/staff-dashboard")
                || uri.equals(ctx + "/staff-profile")) {
            if (staffAcc == null) {
                resp.sendRedirect(ctx + "/staff-login");
                return;
            }
            chain.doFilter(request, response);
            return;
        }

        // ── 6. Logout — luôn cho qua ──
        if (uri.equals(ctx + "/logout")) {
            chain.doFilter(request, response);
            return;
        }

        // ── 7. Các URL khác — cần ít nhất 1 session ──
        if (adminAcc == null && staffAcc == null) {
            resp.sendRedirect(ctx + "/login");
            return;
        }

        chain.doFilter(request, response);
    }
}