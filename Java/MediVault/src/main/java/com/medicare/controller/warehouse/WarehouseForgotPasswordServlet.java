package com.medicare.controller.warehouse;

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
 * WarehouseForgotPasswordServlet — Quên mật khẩu RIÊNG cho Quản lý kho (roleId 3 = Thủ kho).
 * URL: /warehouse-forgot-password
 *
 * <p>Trang &amp; luồng riêng, KHÔNG dùng chung với nhân viên bán ({@code /forgot-password}),
 * nhưng dùng CHUNG logic lõi qua {@link PasswordResetHelper}. Chỉ nhận roleId 3;
 * redirect thành công về {@code /warehouse-login}.</p>
 */
@WebServlet("/warehouse-forgot-password")
public class WarehouseForgotPasswordServlet extends HttpServlet {

    private static final int    ROLE_WAREHOUSE = 3;
    private static final String VIEW = "/WEB-INF/views/warehouse/warehouse-forgot-password.jsp";

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

        // ══ PHA 2 — nhập mã OTP nhận được trong email. Chỉ tới bước này TK mới bị khoá ══
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
                    resp.sendRedirect(req.getContextPath() + "/warehouse-login?success=reset-sent&name="
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
                default -> {
                    req.setAttribute("error", "Phiên xác minh đã hết hạn hoặc lỗi hệ thống. Vui lòng thử lại từ đầu.");
                    req.getRequestDispatcher(VIEW).forward(req, resp);
                }
            }
            return;
        }

        String email = req.getParameter("email");
        if (email == null || email.trim().isEmpty()) {
            req.setAttribute("error", "Vui lòng nhập email!");
            req.getRequestDispatcher(VIEW).forward(req, resp);
            return;
        }

        // Chỉ nhận đúng tài khoản Quản lý kho (roleId 3) — tra thẳng theo email, không cần username
        Account acc = accountDAO.findByEmailAny(email.trim());
        if (acc == null || acc.getRoleId() != ROLE_WAREHOUSE) {
            req.setAttribute("error", "Không tìm thấy tài khoản Quản lý kho với email này!");
            req.getRequestDispatcher(VIEW).forward(req, resp);
            return;
        }

        // ══ PHA 1 — chỉ gửi mã xác minh về email, KHÔNG khoá tài khoản ══
        PasswordResetHelper.Result r = PasswordResetHelper.requestOtp(req, acc, resetDAO);
        switch (r) {
            case OTP_SENT -> {
                req.setAttribute("otpStage", true);
                req.setAttribute("otpEmail", PasswordResetHelper.maskEmail(acc.getEmail()));
                req.getRequestDispatcher(VIEW).forward(req, resp);
            }
            case RATE_LIMITED -> {
                req.setAttribute("error", "Tài khoản @" + acc.getUsername()
                        + " đã gửi quá 3 yêu cầu hôm nay. Vui lòng thử lại vào ngày mai hoặc liên hệ Admin!");
                req.getRequestDispatcher(VIEW).forward(req, resp);
            }
            case INSERT_FAILED -> {
                req.setAttribute("error", "Lỗi hệ thống khi tạo yêu cầu. Vui lòng thử lại sau vài giây hoặc liên hệ Admin!");
                req.getRequestDispatcher(VIEW).forward(req, resp);
            }
            default -> {
                String displayName = acc.getFullName() != null && !acc.getFullName().isEmpty()
                        ? acc.getFullName() : acc.getUsername();
                resp.sendRedirect(req.getContextPath()
                        + "/warehouse-login?success=reset-sent&name="
                        + java.net.URLEncoder.encode(displayName, "UTF-8"));
            }
        }
    }
}
