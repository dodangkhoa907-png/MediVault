package com.medicare.controller.staff;

import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.dao.interfaces.IPasswordResetDAO;
import com.medicare.entity.Account;
import com.medicare.entity.PasswordResetRequest;
import com.medicare.util.PasswordUtil;
import com.medicare.util.AuditHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/staff-login")
public class StaffLoginServlet extends HttpServlet {

    private final IAccountDAO       accountDAO = new com.medicare.dao.AccountDAO();
    private final IPasswordResetDAO resetDAO   = new com.medicare.dao.PasswordResetDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        // ĐÃ GỠ: auto-redirect vào /staff-dashboard khi session cũ còn sống ("đã đăng nhập
        // rồi thì bỏ qua form"). Lý do: hệ thống có single-session enforcement thật sự
        // (xem SessionTracker — mỗi tài khoản chỉ 1 tab, đăng nhập mới phải tạo token mới
        // và KICK tab cũ). Auto-redirect ở đây đi vòng qua toàn bộ cơ chế đó — mở tab mới
        // rồi vào thẳng /staff-login sẽ được âm thầm gắn vào session cũ mà KHÔNG tạo token
        // mới, KHÔNG kick tab cũ → 2 tab cùng sống song song, người dùng cảm giác "tự nhiên
        // đăng nhập được" dù chưa hề bấm nút nào. Nay luôn hiện form: chỉ có POST (submit
        // đúng mật khẩu) mới thật sự tạo phiên/đá tab cũ, đúng như thiết kế SessionTracker.
        req.getRequestDispatcher("/WEB-INF/views/staff/staff-login.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String username = req.getParameter("username");
        String password = req.getParameter("password");

        // ── 1. Validate không trống ──
        if (username == null || username.trim().isEmpty() ||
                password == null || password.trim().isEmpty()) {
            req.setAttribute("error", "Vui lòng nhập đầy đủ thông tin!");
            req.getRequestDispatcher("/WEB-INF/views/staff/staff-login.jsp").forward(req, resp);
            return;
        }

        // findByUsernameAny: tìm kể cả TK bị khóa (IsActive=0)
        Account account = accountDAO.findByUsernameAny(username.trim());

        // ── 2+4. Username không tồn tại HOẶC sai mật khẩu → GỘP CHUNG 1 thông báo.
        // Không được tách riêng "không tồn tại" / role trước khi xác minh mật khẩu — nếu
        // không, ai đó chỉ cần gõ đúng USERNAME (không cần đúng mật khẩu) là dò được tài
        // khoản đó có tồn tại hay không và role gì (kể cả tài khoản Admin) — lỗ hổng dò
        // tài khoản (user/role enumeration), tuyệt đối không được để lộ trước khi có mật khẩu đúng.
        if (account == null || !PasswordUtil.checkPassword(password, account.getPasswordHash())) {
            req.setAttribute("error", "Tài khoản hoặc mật khẩu không đúng!");
            req.getRequestDispatcher("/WEB-INF/views/staff/staff-login.jsp").forward(req, resp);
            return;
        }

        // ── 3. Mật khẩu ĐÃ đúng — tới đây chắc chắn là chủ tài khoản thật, tiết lộ
        // role-mismatch lúc này mới an toàn (không giúp kẻ tấn công dò tài khoản). ──
        if (account.getRoleId() == 1) {
            req.setAttribute("error", "Tài khoản Admin vui lòng đăng nhập tại trang quản trị.");
            req.getRequestDispatcher("/WEB-INF/views/staff/staff-login.jsp").forward(req, resp);
            return;
        }
        // BUG THẬT (đã fix): trước đây nhánh này KHÔNG tồn tại — tài khoản Thủ kho
        // (roleId 3) gõ đúng mật khẩu ở trang staff-login vẫn được cho đăng nhập, chỉ
        // lặng lẽ redirect sang /warehouse-dashboard, không hề báo "sai chỗ đăng nhập".
        // Trong khi đó WarehouseLoginServlet lại chặn đúng chiều ngược lại (roleId 2 bị
        // báo lỗi "vui lòng đăng nhập tại trang Nhân viên"). Hai trang phải đối xứng —
        // nay chặn roleId 3 tại đây, không tạo session, không đăng nhập hộ.
        if (account.getRoleId() == 3) {
            req.setAttribute("error", "Tài khoản này là Thủ kho — vui lòng đăng nhập tại trang Quản lý kho.");
            req.getRequestDispatcher("/WEB-INF/views/staff/staff-login.jsp").forward(req, resp);
            return;
        }

        // ── 5. MK đúng rồi → kiểm tra TK có bị khóa không ──
        if (!account.isActive()) {
            PasswordResetRequest pending =
                    resetDAO.findPendingByAccountId(account.getAccountId());
            if (pending == null)
                pending = resetDAO.findConfirmedByAccountId(account.getAccountId());

            if (pending != null) {
                req.setAttribute("lockedForReset", true);
                req.setAttribute("lockedName",
                        account.getFullName() != null
                                ? account.getFullName() : account.getUsername());
            } else {
                req.setAttribute("error",
                        "Tài khoản đang bị tạm khóa hoặc bảo trì. Vui lòng liên hệ quản trị viên.");
            }
            req.getRequestDispatcher("/WEB-INF/views/staff/staff-login.jsp").forward(req, resp);
            return;
        }

        // ── 6. Đăng nhập thành công ──
        HttpSession session = req.getSession(true);
        int staffId = account.getAccountId();
        session.setAttribute("staffAccount_" + staffId, account);
        session.setAttribute("staffUid", String.valueOf(staffId)); // lưu uid để doGet kiểm tra

        // Tạo token mới (nếu đã có session cũ → token mới sẽ kick tab cũ — đây là đúng)
        String token = com.medicare.util.SessionTracker.login(staffId);
        accountDAO.updateLastLogin(staffId);
        AuditHelper.log(req, "Đăng nhập", "Auth",
                "Staff @" + account.getUsername() + " đăng nhập thành công",
                staffId);
        // Tới đây chắc chắn account.getRoleId() == 2 (Dược sĩ bán hàng) — roleId 1 và 3
        // đã bị chặn với thông báo lỗi ở trên, không còn nhánh "đăng nhập hộ" nữa.
        resp.sendRedirect(req.getContextPath()
                + "/staff-dashboard?uid=" + staffId + "&token=" + token);
    }
}