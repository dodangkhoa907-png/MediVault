package com.medivault.controller;

import com.medivault.dao.interfaces.IAccountDAO;
import com.medivault.entity.Account;
import com.medivault.util.PasswordUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/login")
public class LoginServlet extends HttpServlet {

    private final IAccountDAO accountDAO = new com.medivault.dao.AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        // Dùng getSession(false) — KHÔNG tạo session mới nếu chưa có
        HttpSession s = req.getSession(false);

        // Chỉ redirect nếu ADMIN đã đăng nhập
        // KHÔNG redirect nếu chỉ có staffAccount — admin cần thấy form login!
        if (s != null) {
            Account adminAcc = (Account) s.getAttribute("adminAccount");
            if (adminAcc != null) {
                resp.sendRedirect(req.getContextPath() + "/dashboard");
                return;
            }
        }
        req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String username = req.getParameter("username");
        String password = req.getParameter("password");

        if (username == null || username.trim().isEmpty() ||
                password == null || password.trim().isEmpty()) {
            req.setAttribute("error", "Vui lòng nhập đầy đủ thông tin!");
            req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
            return;
        }

        Account account = accountDAO.findByUsername(username.trim());

        if (account == null || !PasswordUtil.checkPassword(password, account.getPasswordHash())) {
            req.setAttribute("error", "Tên đăng nhập hoặc mật khẩu không đúng!");
            req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
            return;
        }

        if (!account.isActive()) {
            req.setAttribute("error", "Tài khoản đã bị khóa. Liên hệ quản trị viên!");
            req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
            return;
        }

        if (account.getRoleId() != 1) {
            req.setAttribute("error", "Tài khoản nhân viên vui lòng đăng nhập tại trang nhân viên!");
            req.getRequestDispatcher("/WEB-INF/views/login.jsp").forward(req, resp);
            return;
        }

        // OK → chỉ set "adminAccount"
        // KHÔNG invalidate session vì admin và staff có thể chạy song song
        HttpSession session = req.getSession(true);
        session.setAttribute("adminAccount", account);
        session.removeAttribute("staffAccount"); // đảm bảo không dính staffAccount
        accountDAO.updateLastLogin(account.getAccountId());
        resp.sendRedirect(req.getContextPath() + "/dashboard");
    }
}