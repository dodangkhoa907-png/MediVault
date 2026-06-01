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
        HttpSession session = req.getSession();

        boolean hasPending    = session.getAttribute("pendingAccount")    != null;
        boolean hasPendingNew = session.getAttribute("pendingNewAccount") != null;

        if (!hasPending && !hasPendingNew) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        req.getRequestDispatcher("/WEB-INF/views/otp-verify.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession session = req.getSession();

        // ── CASE 1: Xác nhận tạo tài khoản nhân viên ──
        Account pendingNew = (Account) session.getAttribute("pendingNewAccount");
        if (pendingNew != null) {
            String inputOtp = req.getParameter("otpCode");
            String savedOtp = (String) session.getAttribute("newAccOtpCode");
            Long   expiry   = (Long)   session.getAttribute("newAccOtpExpiry");

            if (expiry == null || System.currentTimeMillis() > expiry) {
                session.removeAttribute("pendingNewAccount");
                session.removeAttribute("newAccOtpCode");
                session.removeAttribute("newAccOtpExpiry");
                resp.sendRedirect(req.getContextPath() + "/accounts?msg=otp-expired");
                return;
            }

            if (savedOtp == null || !savedOtp.equals(inputOtp)) {
                req.setAttribute("error", "Mã OTP không đúng!");
                req.getRequestDispatcher("/WEB-INF/views/otp-verify.jsp").forward(req, resp);
                return;
            }

            // OTP đúng → save DB
            new AccountDAO().insert(pendingNew);
            session.removeAttribute("pendingNewAccount");
            session.removeAttribute("newAccOtpCode");
            session.removeAttribute("newAccOtpExpiry");
            resp.sendRedirect(req.getContextPath() + "/dashboard?msg=created");
            return;
        }

        // ── CASE 2: Xác nhận đăng nhập nhân viên ──
        String inputOtp = req.getParameter("otpCode");
        String savedOtp = (String) session.getAttribute("otpCode");
        Long   expiry   = (Long)   session.getAttribute("otpExpiry");
        Account pending = (Account) session.getAttribute("pendingAccount");

        if (expiry == null || System.currentTimeMillis() > expiry) {
            req.setAttribute("error", "Mã OTP đã hết hạn. Vui lòng đăng nhập lại!");
            session.invalidate();
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        if (savedOtp == null || !savedOtp.equals(inputOtp)) {
            req.setAttribute("error", "Mã OTP không đúng!");
            req.getRequestDispatcher("/WEB-INF/views/otp-verify.jsp").forward(req, resp);
            return;
        }

        // OTP đúng → đăng nhập hoàn tất
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