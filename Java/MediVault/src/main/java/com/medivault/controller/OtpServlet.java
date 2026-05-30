package com.medivault.controller;

import com.medivault.dao.AccountDAO;
import com.medivault.entity.Account;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;

@WebServlet("/otp-verify")
public class OtpServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        // Nếu không có pendingAccount → về login
        if (req.getSession().getAttribute("pendingAccount") == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        req.getRequestDispatcher("/WEB-INF/views/otp-verify.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession session = req.getSession();
        String inputOtp  = req.getParameter("otp");
        String savedOtp  = (String) session.getAttribute("otpCode");
        Long   expiry    = (Long)   session.getAttribute("otpExpiry");
        Account pending  = (Account) session.getAttribute("pendingAccount");

        // Hết hạn
        if (expiry == null || System.currentTimeMillis() > expiry) {
            req.setAttribute("error", "Mã OTP đã hết hạn. Vui lòng đăng nhập lại!");
            session.invalidate();
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        // Sai OTP
        if (savedOtp == null || !savedOtp.equals(inputOtp)) {
            req.setAttribute("error", "Mã OTP không đúng!");
            req.getRequestDispatcher("/WEB-INF/views/otp-verify.jsp").forward(req, resp);
            return;
        }

        // OTP đúng → xác thực hoàn tất
        session.removeAttribute("otpCode");
        session.removeAttribute("otpExpiry");
        session.removeAttribute("pendingAccount");
        session.setAttribute("account", pending);
        session.setAttribute("roleId",  pending.getRoleId());

        new AccountDAO().updateLastLogin(pending.getAccountId());

        switch (pending.getRoleId()) {
            case 1 -> resp.sendRedirect(req.getContextPath() + "/dashboard?view=admin");
            case 2 -> resp.sendRedirect(req.getContextPath() + "/dashboard?view=manager");
            default -> resp.sendRedirect(req.getContextPath() + "/dashboard?view=staff");
        }
    }
}
