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
        // Kiểm tra session staffUid — nếu đã login thì redirect luôn
        HttpSession s = req.getSession(false);
        if (s != null) {
            String staffUid = (String) s.getAttribute("staffUid");
            if (staffUid != null && !staffUid.isEmpty()) {
                Account acc = (Account) s.getAttribute("staffAccount_" + staffUid);
                if (acc != null) {
                    resp.sendRedirect(req.getContextPath() + "/staff-dashboard?uid=" + staffUid);
                    return;
                }
            }
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

        // OK → lưu với key riêng "staffAccount_{id}"
        HttpSession session = req.getSession(true);
        int staffId = account.getAccountId();
        session.setAttribute("staffAccount_" + staffId, account);

        // login() tạo token mới → tab cũ cùng account sẽ bị kick khi ping
        String token = com.medivault.util.SessionTracker.login(staffId);
        accountDAO.updateLastLogin(staffId);

        // Redirect kèm uid + token → tab lưu vào sessionStorage, dùng để ping
        resp.sendRedirect(req.getContextPath() + "/staff-dashboard?uid=" + staffId + "&token=" + token);
    }
}