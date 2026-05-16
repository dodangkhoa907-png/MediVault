package com.medivault.controller;

import com.medivault.entity.Account;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

@WebServlet("/dashboard")
public class DashboardServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        Account account = (session != null) ? (Account) session.getAttribute("account") : null;
        if (account == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        // TODO: Châu xong MedicineDAO thì thêm thống kê vào đây
        req.getRequestDispatcher("/WEB-INF/views/admin-dashboard.jsp").forward(req, resp);
    }
}