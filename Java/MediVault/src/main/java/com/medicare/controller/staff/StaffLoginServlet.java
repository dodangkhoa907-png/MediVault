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
            if (uid != null && s.getAttribute("staffAccount_" + uid) != null) {
                resp.sendRedirect(req.getContextPath() + "/staff-dashboard?uid=" + uid);
                return;
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

        // ── 2. Username không tồn tại ──
        if (account == null) {
            req.setAttribute("error", "Tài khoản \"" + username.trim()
                    + "\" không tồn tại trong hệ thống. Vui lòng kiểm tra lại hoặc liên hệ Admin!");
            req.getRequestDispatcher("/WEB-INF/views/staff/staff-login.jsp").forward(req, resp);
            return;
        }

        // ── 3. Tài khoản Admin không đăng nhập ở portal nhân viên ──
        if (account.getRoleId() == 1) {
            req.setAttribute("error", "Tài khoản Admin vui lòng đăng nhập tại trang quản trị.");
            req.getRequestDispatcher("/WEB-INF/views/staff/staff-login.jsp").forward(req, resp);
            return;
        }

        // ── 4. Sai mật khẩu (phải check TRƯỚC inactive để không leak thông tin TK bị khóa) ──
        if (!PasswordUtil.checkPassword(password, account.getPasswordHash())) {
            req.setAttribute("error", "Mật khẩu không đúng! Vui lòng thử lại.");
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
        resp.sendRedirect(req.getContextPath()
                + "/staff-dashboard?uid=" + staffId + "&token=" + token);
    }
}