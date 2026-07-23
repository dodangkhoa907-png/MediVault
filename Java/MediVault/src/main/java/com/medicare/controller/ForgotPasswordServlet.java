package com.medicare.controller;

import com.medicare.dao.AccountDAO;
import com.medicare.dao.PasswordResetDAO;
import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.dao.interfaces.IPasswordResetDAO;
import com.medicare.entity.Account;
import com.medicare.util.PasswordResetHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;

/**
 * ForgotPasswordServlet — Quên mật khẩu cho NHÂN VIÊN BÁN HÀNG (portal staff).
 * URL: /forgot-password
 *
 * <p>Quản lý kho (roleId 2) có trang RIÊNG: {@code /warehouse-forgot-password}.
 * Phần logic lõi (tạo token, khóa TK, gửi email, audit) dùng chung qua
 * {@link PasswordResetHelper}.</p>
 */
@WebServlet("/forgot-password")
public class ForgotPasswordServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/forgot-password.jsp";

    private final IAccountDAO accountDAO = new AccountDAO();
    private final IPasswordResetDAO resetDAO = new PasswordResetDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        String username = req.getParameter("username");
        String email    = req.getParameter("email");

        // ── 1. Validate input ──
        if (username == null || username.trim().isEmpty()
                || email == null || email.trim().isEmpty()) {
            req.setAttribute("error", "Vui lòng nhập đầy đủ thông tin!");
            req.getRequestDispatcher(VIEW).forward(req, resp);
            return;
        }

        // ── 2. Tìm account (kể cả TK bị khóa) — không nhận Admin ──
        Account staff = accountDAO.findByUsernameAny(username.trim());
        if (staff == null || staff.getRoleId() == 1) {
            req.setAttribute("error", "Không tìm thấy tài khoản nhân viên!");
            req.getRequestDispatcher(VIEW).forward(req, resp);
            return;
        }

        // ── 3. Kiểm tra email khớp ──
        if (staff.getEmail() == null || !email.trim().equalsIgnoreCase(staff.getEmail().trim())) {
            req.setAttribute("error", "Email không khớp với tài khoản!");
            req.getRequestDispatcher(VIEW).forward(req, resp);
            return;
        }

        // ── 4. Xử lý phần lõi (dùng chung với Quản lý kho) ──
        PasswordResetHelper.Result r = PasswordResetHelper.submit(req, staff, accountDAO, resetDAO);
        switch (r) {
            case RATE_LIMITED -> {
                req.setAttribute("error", "Tài khoản @" + staff.getUsername()
                        + " đã gửi quá 3 yêu cầu hôm nay. Vui lòng thử lại vào ngày mai hoặc liên hệ Admin!");
                req.getRequestDispatcher(VIEW).forward(req, resp);
            }
            case INSERT_FAILED -> {
                req.setAttribute("error", "Lỗi hệ thống khi tạo yêu cầu. Vui lòng thử lại sau vài giây hoặc liên hệ Admin!");
                req.getRequestDispatcher(VIEW).forward(req, resp);
            }
            default -> // SENT hoặc ALREADY_PENDING → coi như đã gửi
                resp.sendRedirect(req.getContextPath()
                        + "/staff-login?success=reset-sent&name="
                        + java.net.URLEncoder.encode(staff.getFullName(), "UTF-8"));
        }
    }
}
