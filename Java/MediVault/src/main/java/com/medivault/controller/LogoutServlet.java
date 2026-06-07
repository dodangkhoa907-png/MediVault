package com.medivault.controller;

import com.medivault.entity.Account;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/logout")
public class LogoutServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        String from = req.getParameter("from");
        String redirectUrl = "/login"; // mặc định về admin login

        if (session != null) {
            Account adminAcc = (Account) session.getAttribute("adminAccount");

            // Lấy uid từ URL param (tab này mang uid của mình khi bấm logout)
            String staffUid = req.getParameter("uid");
            Account staffAcc = null;
            if (staffUid != null && !staffUid.isEmpty()) {
                staffAcc = (Account) session.getAttribute("staffAccount_" + staffUid);
            }

            if ("staff".equals(from) || (staffAcc != null && adminAcc == null)) {
                redirectUrl = "/staff-login";
            }
            if (staffAcc != null) {
                com.medivault.util.SessionTracker.logout(staffAcc.getAccountId());
                session.removeAttribute("staffAccount_" + staffAcc.getAccountId());
            }
            if (adminAcc != null) {
                com.medivault.util.SessionTracker.logout(adminAcc.getAccountId());
                session.removeAttribute("adminAccount");
            }
        }

        // ── Xóa cả 2 Remember Me cookie khi logout ──
        AuthFilter.clearAllCookies(resp);

        resp.sendRedirect(req.getContextPath() + redirectUrl);
    }
}