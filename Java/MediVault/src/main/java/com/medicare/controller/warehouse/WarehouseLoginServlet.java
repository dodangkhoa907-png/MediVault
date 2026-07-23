package com.medicare.controller.warehouse;

import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.dao.interfaces.IPasswordResetDAO;
import com.medicare.entity.Account;
import com.medicare.entity.PasswordResetRequest;
import com.medicare.util.AuditHelper;
import com.medicare.util.PasswordUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;

/**
 * WarehouseLoginServlet — Trang đăng nhập RIÊNG cho Quản lý kho / Thủ kho (roleId 3).
 * URL: /warehouse-login
 *
 * <p>Khớp đúng quy ước roleId đang dùng xuyên suốt hệ thống (account-form.jsp,
 * StaffInvoiceServlet...): <b>roleId 2 = Dược sĩ bán hàng</b>, <b>roleId 3 = Thủ kho</b>.
 * Chỉ chấp nhận roleId == 3:</p>
 * <ul>
 *   <li>roleId 1 (Admin)          → mời sang trang quản trị.</li>
 *   <li>roleId 2 (Dược sĩ bán hàng) → mời sang portal nhân viên bán hàng.</li>
 * </ul>
 *
 * <p>Tái sử dụng cơ chế session đa-tab của staff (staffAccount_&lt;uid&gt; + staffUid +
 * SessionTracker) để không phải sửa lại AuthFilter phần restore — chỉ khác ĐÍCH đến sau
 * khi đăng nhập là /warehouse-dashboard.</p>
 */
@WebServlet("/warehouse-login")
public class WarehouseLoginServlet extends HttpServlet {

    private static final int ROLE_WAREHOUSE = 3;

    private final IAccountDAO       accountDAO = new com.medicare.dao.AccountDAO();
    private final IPasswordResetDAO resetDAO   = new com.medicare.dao.PasswordResetDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession s = req.getSession(false);
        if (s != null) {
            String uid = (String) s.getAttribute("staffUid");
            if (uid != null) {
                Account acc = (Account) s.getAttribute("staffAccount_" + uid);
                if (acc != null && acc.getRoleId() == ROLE_WAREHOUSE) {
                    resp.sendRedirect(req.getContextPath() + "/warehouse-dashboard?uid=" + uid);
                    return;
                }
            }
        }
        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-login.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String username = req.getParameter("username");
        String password = req.getParameter("password");

        if (username == null || username.trim().isEmpty()
                || password == null || password.trim().isEmpty()) {
            fail(req, resp, "Vui lòng nhập đầy đủ thông tin!");
            return;
        }

        Account account = accountDAO.findByUsernameAny(username.trim());

        // ── Username không tồn tại HOẶC sai mật khẩu → GỘP CHUNG 1 thông báo.
        // Không được tách riêng "không tồn tại" / role trước khi xác minh mật khẩu — nếu
        // không, ai đó chỉ cần gõ đúng USERNAME (không cần đúng mật khẩu) là dò được tài
        // khoản đó có tồn tại hay không và role gì (kể cả tài khoản Admin) — lỗ hổng dò
        // tài khoản (user/role enumeration), tuyệt đối không được để lộ trước khi có mật khẩu đúng.
        if (account == null || !PasswordUtil.checkPassword(password, account.getPasswordHash())) {
            fail(req, resp, "Tài khoản hoặc mật khẩu không đúng!");
            return;
        }

        // Mật khẩu ĐÃ đúng — tới đây chắc chắn là chủ tài khoản thật, tiết lộ role-mismatch
        // lúc này mới an toàn. Chỉ Thủ kho (roleId 3) được vào portal Quản lý kho.
        if (account.getRoleId() == 1) {
            fail(req, resp, "Tài khoản Admin vui lòng đăng nhập tại trang quản trị.");
            return;
        }
        if (account.getRoleId() != ROLE_WAREHOUSE) {
            fail(req, resp, "Tài khoản này là Dược sĩ bán hàng — vui lòng đăng nhập tại trang Nhân viên.");
            return;
        }

        // Mật khẩu đúng → kiểm tra khóa
        if (!account.isActive()) {
            PasswordResetRequest pending = resetDAO.findPendingByAccountId(account.getAccountId());
            if (pending == null) pending = resetDAO.findConfirmedByAccountId(account.getAccountId());
            if (pending != null) {
                req.setAttribute("lockedForReset", true);
                req.setAttribute("lockedName",
                        account.getFullName() != null ? account.getFullName() : account.getUsername());
            } else {
                req.setAttribute("error",
                        "Tài khoản đang bị tạm khóa hoặc bảo trì. Vui lòng liên hệ quản trị viên.");
            }
            req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-login.jsp").forward(req, resp);
            return;
        }

        // Đăng nhập thành công — dùng cùng cơ chế session của staff
        HttpSession session = req.getSession(true);
        int id = account.getAccountId();
        session.setAttribute("staffAccount_" + id, account);
        session.setAttribute("staffUid", String.valueOf(id));

        String token = com.medicare.util.SessionTracker.login(id);
        accountDAO.updateLastLogin(id);
        AuditHelper.log(req, "Đăng nhập", "Auth",
                "Quản lý kho @" + account.getUsername() + " đăng nhập thành công", id);

        resp.sendRedirect(req.getContextPath()
                + "/warehouse-dashboard?uid=" + id + "&token=" + token);
    }

    private void fail(HttpServletRequest req, HttpServletResponse resp, String msg)
            throws ServletException, IOException {
        req.setAttribute("error", msg);
        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-login.jsp").forward(req, resp);
    }
}
