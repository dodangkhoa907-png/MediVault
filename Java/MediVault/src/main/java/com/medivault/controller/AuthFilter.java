package com.medivault.controller;

import com.medivault.entity.Account;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebFilter("/*")
public class AuthFilter implements Filter {
    jhgfdfdtshdy
    @Override
    public void doFilter(ServletRequest request, ServletResponse response,
                         FilterChain chain) throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse resp = (HttpServletResponse) response;

        String uri = req.getRequestURI();
        String ctx = req.getContextPath();

        // Cho qua: trang login + file tĩnh CSS/JS/IMG
        boolean isPublic = uri.equals(ctx + "/login")
                || uri.startsWith(ctx + "/assets")
                || uri.startsWith(ctx + "/css")
                || uri.startsWith(ctx + "/js")
                || uri.startsWith(ctx + "/WEB-INF");

        if (isPublic) { chain.doFilter(request, response); return; }

        Account account = (Account) req.getSession().getAttribute("account");

        // Chưa đăng nhập → về login
        if (account == null) {
            resp.sendRedirect(ctx + "/login");
            return;
        }

        // Staff cố vào trang admin → báo lỗi
        if (uri.startsWith(ctx + "/admin") && account.getRoleId() != 1) {
            resp.sendError(HttpServletResponse.SC_FORBIDDEN, "Không có quyền truy cập!");
            return;
        }

        chain.doFilter(request, response);
    }
}