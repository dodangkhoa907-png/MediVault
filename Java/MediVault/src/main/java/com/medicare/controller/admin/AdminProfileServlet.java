package com.medicare.controller.admin;

import com.medicare.dao.AccountDAO;
import com.medicare.entity.Account;
import com.medicare.util.SidebarHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * AdminProfileServlet — Trang HỒ SƠ RIÊNG của Admin (đặc quyền).
 * URL: /admin-profile — KHÔNG nằm trong sidebar, chỉ vào qua chip tên góc phải.
 * Luôn hiển thị admin ĐANG đăng nhập (lấy từ session), không cần id.
 */
@WebServlet("/admin-profile")
public class AdminProfileServlet extends HttpServlet {

    private final AccountDAO dao = new AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession s = req.getSession(false);
        Account admin = s != null ? (Account) s.getAttribute("adminAccount") : null;
        if (admin == null || admin.getRoleId() != 1) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        Account fresh = dao.findById(admin.getAccountId());
        req.setAttribute("admin", fresh != null ? fresh : admin);
        SidebarHelper.load(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/admin-profile.jsp").forward(req, resp);
    }
}
