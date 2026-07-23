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

        PasswordResetHelper.Result r = PasswordResetHelper.submit(req, acc, accountDAO, resetDAO);
        switch (r) {
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
