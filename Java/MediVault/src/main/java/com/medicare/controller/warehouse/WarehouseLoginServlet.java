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
        // ĐÃ GỠ: auto-redirect vào /warehouse-dashboard khi session cũ còn sống — cùng lý do
        // đã gỡ ở StaffLoginServlet. Hệ thống có single-session enforcement thật sự
        // (SessionTracker: đăng nhập mới tạo token mới, KICK tab cũ). Auto-redirect ở đây
        // đi vòng qua cơ chế đó: mở tab mới vào /warehouse-login được gắn thẳng vào session
        // cũ, không tạo token mới, không kick tab cũ → 2 tab cùng sống, người dùng thấy như
        // "tự động ghi nhớ đăng nhập" dù chưa hề bấm gì. Nay luôn hiện form; chỉ POST đúng
        // mật khẩu mới thật sự tạo phiên.
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
        // Danh tính chuẩn của portal Kho — mọi servlet Kho đọc từ đây, không đọc từ URL nữa.
        com.medicare.util.WarehouseAuth.login(session, account);

        com.medicare.util.SessionTracker.login(id);
        accountDAO.updateLastLogin(id);
        AuditHelper.log(req, "Đăng nhập", "Auth",
                "Quản lý kho @" + account.getUsername() + " đăng nhập thành công", id);

        // URL sạch: không còn ?uid=&token= — id tài khoản không được phép nằm trên thanh
        // địa chỉ (lưu lại trong lịch sử trình duyệt, lộ trên máy dùng chung).
        resp.sendRedirect(req.getContextPath() + "/warehouse-dashboard");
    }

    private void fail(HttpServletRequest req, HttpServletResponse resp, String msg)
            throws ServletException, IOException {
        req.setAttribute("error", msg);
        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-login.jsp").forward(req, resp);
    }
}
