package com.medivault.filter;
import com.medivault.entity.Account;
import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

@WebFilter("/*")
public class MaintenanceFilter implements Filter {

    // Thiết lập trạng thái bảo trì hệ thống (true = đang bảo trì, false = hoạt động thường)
    public static boolean isMaintenanceMode = true;

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {}

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse resp = (HttpServletResponse) response;
        String path = req.getRequestURI();

        // 1. Nếu không ở trạng thái bảo trì -> Cho qua luôn
        if (!isMaintenanceMode) {
            chain.doFilter(request, response);
            return;
        }

        // 2. Định nghĩa các đường dẫn tài nguyên ngoại lệ không áp dụng chặn để tránh lặp vòng lặp
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

        // 3. ĐẶC QUYỀN ADMIN: Kiểm tra thông tin phiên làm việc (Session)
        HttpSession session = req.getSession(false);
        Account currentAcc = (session != null) ? (Account) session.getAttribute("adminAccount") : null;

        if (currentAcc != null && currentAcc.getRoleId() == 1) {
            // Cho phép Admin truy cập hệ thống bình thường để làm việc/cấu hình/gỡ lỗi bảo trì
            chain.doFilter(request, response);
            return;
        }

        // 4. Các đối tượng nhân viên khác hoặc khách -> Đẩy ra trang bảo trì
        resp.setStatus(HttpServletResponse.SC_SERVICE_UNAVAILABLE);
        resp.sendRedirect(req.getContextPath() + "/maintenance.jsp");
    }

    @Override
    public void destroy() {}
}
