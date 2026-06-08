package com.medivault.filter;

import com.medivault.entity.Account;
import jakarta.servlet.*; // Đảm bảo dùng jakarta.* nếu Tomcat của bạn là bản mới (Tomcat 10+)
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

@WebFilter("/*")
public class MaintenanceFilter implements Filter {

    // true = BẬT BẢO TRÌ, false = TẮT BẢO TRÌ
    public static boolean isMaintenanceMode = true;

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse resp = (HttpServletResponse) response;
        String path = req.getRequestURI();

        if (!isMaintenanceMode) {
            chain.doFilter(request, response);
            return;
        }

        // Loại trừ trang bảo trì và các tài nguyên tĩnh để không bị lặp vòng chuyển hướng
        boolean isExceptionPath = path.contains("/maintenance.jsp")
                || path.contains("/assets/")
                || path.contains("/css/")
                || path.contains("/js/")
                || path.contains("/login")
                || path.contains("/logout");

        if (isExceptionPath) {
            chain.doFilter(request, response);
            return;
        }

        // Kiểm tra quyền Admin
        HttpSession session = req.getSession(false);
        Account currentAcc = (session != null) ? (Account) session.getAttribute("adminAccount") : null;

        if (currentAcc != null && currentAcc.getRoleId() == 1) {
            chain.doFilter(request, response);
            return;
        }

        // Trả về mã lỗi 503 và chuyển hướng người dùng thường về trang bảo trì
        resp.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
        resp.sendRedirect(req.getContextPath() + "/maintenance.jsp");
    }

    @Override
    public void destroy() {
    }
}