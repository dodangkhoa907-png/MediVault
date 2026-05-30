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

        // Đăng nhập thành công
        accountDAO.updateLastLogin(account.getAccountId());
        HttpSession session = req.getSession();
        session.setAttribute("account", account);
        session.setAttribute("roleId", account.getRoleId());

        switch (account.getRoleId()) {
            case 1: resp.sendRedirect(req.getContextPath() + "/dashboard?view=admin"); break;
            case 2: resp.sendRedirect(req.getContextPath() + "/dashboard?view=manager"); break;
            default: resp.sendRedirect(req.getContextPath() + "/dashboard?view=staff"); break;
        }
        // Đăng nhập thành công → sinh OTP, gửi email, chuyển sang trang nhập OTP
        String otp = OtpUtil.generate(6);
        HttpSession session1 = req.getSession();
        session.setAttribute("otpCode",      otp);
        session.setAttribute("otpExpiry",    System.currentTimeMillis() + 5 * 60 * 1000); // 5 phút
        session.setAttribute("pendingAccount", account);  // lưu tạm, chưa đặt "account"

        try {
            EmailUtil.sendEmail(
                    account.getEmail(),
                    "[MediVault] Mã xác thực OTP",
                    "Mã OTP của bạn là: " + otp + "\nMã có hiệu lực trong 5 phút."
            );
            resp.sendRedirect(req.getContextPath() + "/otp-verify");
        } catch (Exception e) {
            req.setAttribute("error", "Không thể gửi OTP. Vui lòng thử lại!");
            req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
        }
    }
}