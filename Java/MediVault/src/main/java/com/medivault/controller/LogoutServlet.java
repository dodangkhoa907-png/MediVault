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
        // "from" param: trang nào gọi logout → biết nên redirect về đâu
        // staff pages truyền ?from=staff, admin pages không truyền (mặc định)
        String from = req.getParameter("from");
        String redirectUrl = "/login"; // mặc định về admin login

        if (session != null) {
            Account staffAcc = (Account) session.getAttribute("staffAccount");
            Account adminAcc = (Account) session.getAttribute("adminAccount");

            if ("staff".equals(from) || (staffAcc != null && adminAcc == null)) {
                redirectUrl = "/staff-login";
            }
            if (staffAcc != null) com.medivault.util.SessionTracker.logout(staffAcc.getAccountId());
            session.invalidate();
        }

        resp.sendRedirect(req.getContextPath() + redirectUrl);
    }
}