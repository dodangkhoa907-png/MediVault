package com.medivault.controller;

import com.medivault.dao.interfaces.IAccountDAO;
import com.medivault.entity.Account;
import com.medivault.util.PasswordUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/staff-login")
public class StaffLoginServlet extends HttpServlet {

    private final IAccountDAO accountDAO = new com.medivault.dao.AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        // Dùng getSession(false) — KHÔNG tạo session mới nếu chưa có
        HttpSession s = req.getSession(false);
        Account acc = s != null ? (Account) s.getAttribute("staffAccount") : null;
        if (acc != null) {
            resp.sendRedirect(req.getContextPath() + "/staff-dashboard");
            return;
        }
        req.getRequestDispatcher("/WEB-INF/views/staff-login.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String username = req.getParameter("username");
        String password = req.getParameter("password");

        if (username == null || username.trim().isEmpty() ||
                password == null || password.trim().isEmpty()) {
            req.setAttribute("error", "Vui lòng nhập đầy đủ thông tin!");
            req.getRequestDispatcher("/WEB-INF/views/staff-login.jsp").forward(req, resp);
            return;
        }

        Account account = accountDAO.findByUsername(username.trim());

        if (account == null || !PasswordUtil.checkPassword(password, account.getPasswordHash())) {
            req.setAttribute("error", "Tên đăng nhập hoặc mật khẩu không đúng!");
            req.getRequestDispatcher("/WEB-INF/views/staff-login.jsp").forward(req, resp);
            return;
        }

        if (!account.isActive()) {
            req.setAttribute("error", "Tài khoản đã bị khóa. Liên hệ quản trị viên!");
            req.getRequestDispatcher("/WEB-INF/views/staff-login.jsp").forward(req, resp);
            return;
        }

        if (account.getRoleId() == 1) {
            req.setAttribute("error", "Tài khoản Admin vui lòng đăng nhập tại trang quản trị!");
            req.getRequestDispatcher("/WEB-INF/views/staff-login.jsp").forward(req, resp);
            return;
        }

        // OK → invalidate session cũ trước (có thể còn "adminAccount" thừa từ lần thử login admin)
        // rồi tạo session mới sạch chỉ chứa "staffAccount"
        HttpSession old = req.getSession(false);
        if (old != null) old.invalidate();
        HttpSession session = req.getSession(true);
        session.setAttribute("staffAccount", account);
        com.medivault.util.SessionTracker.login(account.getAccountId());
        session.removeAttribute("adminAccount"); // Đảm bảo không còn adminAccount thừa
        accountDAO.updateLastLogin(account.getAccountId());
        resp.sendRedirect(req.getContextPath() + "/staff-dashboard");
    }
}