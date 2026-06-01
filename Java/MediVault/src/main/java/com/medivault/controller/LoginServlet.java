package com.medivault.controller;

import com.medivault.dao.AccountDAO;
import com.medivault.entity.Account;
import com.medivault.util.EmailUtil;
import com.medivault.util.OtpUtil;
import com.medivault.util.PasswordUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    private final AccountDAO accountDAO = new AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        // Nếu đã đăng nhập rồi thì redirect thẳng vào dashboard
        if (req.getSession().getAttribute("account") != null) {
            resp.sendRedirect(req.getContextPath() + "/dashboard");
            return;
        }
        req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String username = req.getParameter("username");
        String password = req.getParameter("password");

        // Validate không để trống
        if (username == null || username.trim().isEmpty() ||
                password == null || password.trim().isEmpty()) {
            req.setAttribute("error", "Vui lòng nhập đầy đủ thông tin!");
            req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
            return;
        }

        Account account = accountDAO.findByUsername(username.trim());

        // Sai username hoặc mật khẩu
        if (account == null || !PasswordUtil.checkPassword(password, account.getPasswordHash())) {
            req.setAttribute("error", "Tên đăng nhập hoặc mật khẩu không đúng!");
            req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
            return;
        }

// Tài khoản bị khóa
        if (!account.isActive()) {
            req.setAttribute("error", "Tài khoản đã bị khóa. Liên hệ quản trị viên!");
            req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
            return;
        }

// Admin (roleId == 1) → vào thẳng dashboard, không cần OTP
        if (account.getRoleId() == 1) {
            req.getSession().setAttribute("account", account);
            accountDAO.updateLastLogin(account.getAccountId());
            resp.sendRedirect(req.getContextPath() + "/dashboard");
            return;
        }

// Nhân viên (roleId == 2, 3) → gửi OTP
        String otp = OtpUtil.generate(6);
        HttpSession session = req.getSession();
        session.setAttribute("otpCode",        otp);
        session.setAttribute("otpExpiry",      System.currentTimeMillis() + 5 * 60 * 1000L);
        session.setAttribute("pendingAccount", account);

        try {
            EmailUtil.sendEmail(account.getEmail(),
                    "[MediVault] Mã xác thực đăng nhập",
                    "Mã OTP của bạn là: " + otp + "\nHiệu lực 5 phút.");
            resp.sendRedirect(req.getContextPath() + "/otp-verify");
        } catch (Exception e) {
            req.setAttribute("error", "Không gửi được email OTP. Kiểm tra cấu hình EmailUtil!");
            req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
        }

    }
}