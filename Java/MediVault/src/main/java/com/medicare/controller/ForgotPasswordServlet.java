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

        // ══ PHA 2 — người dùng nhập mã OTP nhận được trong email ══
        // Chỉ tới bước này tài khoản mới bị khoá (xem PasswordResetHelper.confirmOtp).
        if ("verify-otp".equals(req.getParameter("action"))) {
            // Lấy tên TRƯỚC khi confirmOtp() dọn session, để trang login chào đúng tên
            Integer pendingId = PasswordResetHelper.pendingAccountId(req);
            PasswordResetHelper.Result vr = PasswordResetHelper.confirmOtp(
                    req, req.getParameter("otp"), accountDAO, resetDAO);
            switch (vr) {
                case SENT -> {
                    Account done = (pendingId != null) ? accountDAO.findById(pendingId) : null;
                    String nm = (done == null) ? ""
                            : (done.getFullName() != null && !done.getFullName().isEmpty()
                               ? done.getFullName() : done.getUsername());
                    resp.sendRedirect(req.getContextPath() + "/staff-login?success=reset-sent&name="
                            + java.net.URLEncoder.encode(nm, "UTF-8"));
                }
                case OTP_WRONG -> {
                    req.setAttribute("otpStage", true);
                    req.setAttribute("error", "Mã xác minh không đúng. Vui lòng kiểm tra lại email.");
                    req.getRequestDispatcher(VIEW).forward(req, resp);
                }
                case OTP_EXPIRED -> {
                    req.setAttribute("error", "Mã xác minh đã hết hạn (quá 10 phút). Vui lòng gửi lại yêu cầu.");
                    req.getRequestDispatcher(VIEW).forward(req, resp);
                }
                case OTP_LOCKED_OUT -> {
                    req.setAttribute("error", "Bạn đã nhập sai mã quá nhiều lần. Vui lòng gửi lại yêu cầu mới.");
                    req.getRequestDispatcher(VIEW).forward(req, resp);
                }
                default -> {   // OTP_MISSING / INSERT_FAILED
                    req.setAttribute("error", "Phiên xác minh đã hết hạn hoặc lỗi hệ thống. Vui lòng thử lại từ đầu.");
                    req.getRequestDispatcher(VIEW).forward(req, resp);
                }
            }
            return;
        }

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

        // ══ PHA 1 — chỉ gửi mã xác minh về email, KHÔNG khoá tài khoản ══
        PasswordResetHelper.Result r = PasswordResetHelper.requestOtp(req, staff, resetDAO);
        switch (r) {
            case OTP_SENT -> {
                req.setAttribute("otpStage", true);
                req.setAttribute("otpEmail", PasswordResetHelper.maskEmail(staff.getEmail()));
                req.getRequestDispatcher(VIEW).forward(req, resp);
            }
            case RATE_LIMITED -> {
                req.setAttribute("error", "Tài khoản @" + staff.getUsername()
                        + " đã gửi quá 3 yêu cầu hôm nay. Vui lòng thử lại vào ngày mai hoặc liên hệ Admin!");
                req.getRequestDispatcher(VIEW).forward(req, resp);
            }
            case INSERT_FAILED -> {
                req.setAttribute("error", "Lỗi hệ thống khi tạo yêu cầu. Vui lòng thử lại sau vài giây hoặc liên hệ Admin!");
                req.getRequestDispatcher(VIEW).forward(req, resp);
            }
            default -> // ALREADY_PENDING → đã có yêu cầu đang chờ Admin xử lý
                resp.sendRedirect(req.getContextPath()
                        + "/staff-login?success=reset-sent&name="
                        + java.net.URLEncoder.encode(staff.getFullName(), "UTF-8"));
        }
    }

}
