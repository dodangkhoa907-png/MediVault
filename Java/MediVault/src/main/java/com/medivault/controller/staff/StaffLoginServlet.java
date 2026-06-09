package com.medivault.controller.staff;

import com.medivault.dao.interfaces.IAccountDAO;
import com.medivault.dao.interfaces.IPasswordResetDAO;
import com.medivault.entity.Account;
import com.medivault.entity.PasswordResetRequest;
import com.medivault.util.PasswordUtil;
import com.medivault.util.AuditHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/staff-login")
public class StaffLoginServlet extends HttpServlet {

    private final IAccountDAO       accountDAO = new com.medivault.dao.AccountDAO();
    private final IPasswordResetDAO resetDAO   = new com.medivault.dao.PasswordResetDAO();

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

        // ── 2. Tìm thấy tài khoản → kiểm tra khóa NGAY (trước cả check password) ──
        if (account != null && account.getRoleId() != 1 && !account.isActive()) {
            // TK tồn tại + bị khóa → báo ngay, không cần check mk
            PasswordResetRequest pending =
                    resetDAO.findPendingByAccountId(account.getAccountId());
            if (pending == null)
                pending = resetDAO.findConfirmedByAccountId(account.getAccountId());

            if (pending != null) {
                // Khóa do reset request → banner vàng (không tiết lộ lý do)
                req.setAttribute("lockedForReset", true);
                req.setAttribute("lockedName",
                        account.getFullName() != null
                                ? account.getFullName() : account.getUsername());
            } else {
                // Khóa thông thường
                req.setAttribute("error",
                        "Tài khoản đang bị tạm khóa hoặc bảo trì. Vui lòng liên hệ quản trị viên.");
            }
            req.getRequestDispatcher("/WEB-INF/views/staff/staff-login.jsp").forward(req, resp);
            return;
        }

        // ── 3. Username không tồn tại hoặc sai mật khẩu ──
        if (account == null || !PasswordUtil.checkPassword(password, account.getPasswordHash())) {
            req.setAttribute("error", "Tên đăng nhập hoặc mật khẩu không đúng!");
            req.getRequestDispatcher("/WEB-INF/views/staff/staff-login.jsp").forward(req, resp);
            return;
        }

        // ── 4. Tài khoản Admin không đăng nhập ở đây ──
        if (account.getRoleId() == 1) {
            req.setAttribute("error", "Tài khoản Admin vui lòng đăng nhập tại trang quản trị!");
            req.getRequestDispatcher("/WEB-INF/views/staff/staff-login.jsp").forward(req, resp);
            return;
        }

        // ── 5. Đăng nhập thành công ──
        HttpSession session = req.getSession(true);
        int staffId = account.getAccountId();
        session.setAttribute("staffAccount_" + staffId, account);

        String token = com.medivault.util.SessionTracker.login(staffId);
        accountDAO.updateLastLogin(staffId);
        AuditHelper.log(req, "Đăng nhập", "Auth",
                "Staff @" + account.getUsername() + " đăng nhập thành công",
                staffId);
        resp.sendRedirect(req.getContextPath()
                + "/staff-dashboard?uid=" + staffId + "&token=" + token);
    }
}