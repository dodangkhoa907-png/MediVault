package com.medivault.controller;

import com.medivault.entity.Account;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/staff-profile")
public class StaffProfileServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // AuthFilter đã đảm bảo staffAccount tồn tại trước khi vào đây
        HttpSession session = req.getSession(false);
        Account staffAcc = session != null
                ? (Account) session.getAttribute("staffAccount") : null;

        if (staffAcc == null) {
            resp.sendRedirect(req.getContextPath() + "/staff-login");
            return;
        }
        if (staffAcc.getRoleId() == 1) {
            resp.sendRedirect(req.getContextPath() + "/dashboard");
            return;
        }

        req.getRequestDispatcher("/WEB-INF/views/staff-profile.jsp").forward(req, resp);
    }
}