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
        HttpSession s = req.getSession(false);
        if (s != null) {
            String uid = (String) s.getAttribute("staffUid");
            // BUG THẬT (đã fix): staffAccount_<uid>/staffUid là session key DÙNG CHUNG với
            // Warehouse (xem WarehouseLoginServlet — cố tình tái sử dụng để không phải sửa
            // AuthFilter). "staffUid" chỉ là con trỏ "tab vừa chạm gần nhất", có thể đang trỏ
            // tới 1 tài khoản Thủ kho (roleId 3) nếu người dùng vừa đăng nhập/thao tác bên
            // Warehouse ở tab khác. Trước đây đoạn này KHÔNG kiểm tra role — cứ thấy staffUid
            // có giá trị là tự redirect sang /staff-dashboard, rồi StaffDashboardServlet lại
            // bắn tiếp sang /warehouse-dashboard vì thấy roleId=3 → vòng lặp, và trang login
            // KHÔNG BAO GIỜ hiện ra để đăng nhập tài khoản staff khác (uid khác) được nữa.
            // Fix: chỉ tự-redirect khi tài khoản dưới staffUid THẬT SỰ là tài khoản staff
            // (roleId != 3) — nếu không, coi như "chưa đăng nhập staff" và hiện form login.
            if (uid != null) {
                Object acc = s.getAttribute("staffAccount_" + uid);
                if (acc instanceof com.medicare.entity.Account
                        && ((com.medicare.entity.Account) acc).getRoleId() != 3) {
                    resp.sendRedirect(req.getContextPath() + "/staff-dashboard?uid=" + uid);
                    return;
                }
            }
        }
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
        // roleId 3 (Thủ kho = Quản lý kho) có portal riêng — dù đăng nhập qua trang staff
        // vẫn đưa về /warehouse-dashboard cho nhất quán.
        String dest = account.getRoleId() == 3 ? "/warehouse-dashboard" : "/staff-dashboard";
        resp.sendRedirect(req.getContextPath()
                + dest + "?uid=" + staffId + "&token=" + token);
    }
}