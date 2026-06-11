package com.medicare.controller;

import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.dao.AccountDAO;
import com.medicare.util.PasswordUtil;
import com.medicare.util.ValidationUtil;
import com.medicare.entity.Account;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import com.medicare.util.AuditHelper;

import java.io.IOException;

@WebServlet("/otp-verify")
public class OtpServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession session = req.getSession();

        boolean hasPending       = session.getAttribute("pendingAccount")       != null;
        boolean hasPendingNew    = session.getAttribute("pendingNewAccount")    != null;
        boolean hasPendingUpdate = session.getAttribute("pendingUpdateAccount") != null;

        if (!hasPending && !hasPendingNew && !hasPendingUpdate) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        req.getRequestDispatcher("/WEB-INF/views/otp-verify.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession session = req.getSession();

        // ── CASE 3: Xác nhận thay đổi email/phone tài khoản ──
        Account pendingUpdate = (Account) session.getAttribute("pendingUpdateAccount");
        if (pendingUpdate != null) {
            String inputOtp = req.getParameter("otpCode");
            String savedOtp = (String) session.getAttribute("updateAccOtpCode");
            Long   expiry   = (Long)   session.getAttribute("updateAccOtpExpiry");
            String newPw    = (String) session.getAttribute("updateAccNewPassword");

            if (expiry == null || System.currentTimeMillis() > expiry) {
                session.removeAttribute("pendingUpdateAccount");
                session.removeAttribute("updateAccOtpCode");
                session.removeAttribute("updateAccOtpExpiry");
                session.removeAttribute("updateAccNewPassword");
                resp.sendRedirect(req.getContextPath() + "/accounts?msg=otp-expired");
                return;
            }

            if (savedOtp == null || !savedOtp.equals(inputOtp)) {
                req.setAttribute("error", "Mã OTP không đúng!");
                req.getRequestDispatcher("/WEB-INF/views/otp-verify.jsp").forward(req, resp);
                return;
            }

            // OTP đúng → lưu thay đổi
            IAccountDAO accDao = new AccountDAO();
            accDao.update(pendingUpdate);
            if (ValidationUtil.notBlank(newPw) && ValidationUtil.isValidPassword(newPw)) {
                accDao.resetPassword(pendingUpdate.getAccountId(), PasswordUtil.hashPassword(newPw));
            }
            AuditHelper.log(req, "Cập nhật tài khoản", "Account",
                    "Cập nhật thông tin @" + pendingUpdate.getUsername()
                            + (ValidationUtil.notBlank(newPw) ? " + đổi mật khẩu" : ""));
            session.removeAttribute("pendingUpdateAccount");
            session.removeAttribute("updateAccOtpCode");
            session.removeAttribute("updateAccOtpExpiry");
            session.removeAttribute("updateAccNewPassword");
            resp.sendRedirect(req.getContextPath() + "/accounts?msg=updated");
            return;
        }

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
            new com.medicare.dao.AccountDAO().insert(pendingNew);
            AuditHelper.log(req, "Tạo tài khoản", "Account",
                    "Tạo tài khoản @" + pendingNew.getUsername()
                            + " (" + (pendingNew.getRoleId() == 2 ? "Dược sĩ" : "Thủ kho") + ")"
                            + " - " + pendingNew.getEmail());
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

        // Set đúng key theo role — KHÔNG dùng "account" chung nữa
        if (pending.getRoleId() == 1) {
            session.setAttribute("adminAccount", pending);
        } else {
            session.setAttribute("staffAccount", pending);
        }

        ((IAccountDAO) new com.medicare.dao.AccountDAO()).updateLastLogin(pending.getAccountId());

        switch (pending.getRoleId()) {
            case 1 -> resp.sendRedirect(req.getContextPath() + "/dashboard");
            case 2 -> resp.sendRedirect(req.getContextPath() + "/dashboard");
            default -> resp.sendRedirect(req.getContextPath() + "/dashboard");
        }
    }
}