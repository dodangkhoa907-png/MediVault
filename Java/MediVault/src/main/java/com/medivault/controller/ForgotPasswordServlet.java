package com.medivault.controller;

import com.medivault.dao.AccountDAO;
import com.medivault.dao.PasswordResetDAO;
import com.medivault.dao.interfaces.IAccountDAO;
import com.medivault.dao.interfaces.IPasswordResetDAO;
import com.medivault.entity.Account;
import com.medivault.entity.PasswordResetRequest;
import com.medivault.util.EmailUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.time.LocalDateTime;
import java.util.UUID;

@WebServlet("/forgot-password")
public class ForgotPasswordServlet extends HttpServlet {

    private final IAccountDAO accountDAO = new AccountDAO();
    private final IPasswordResetDAO resetDAO = new PasswordResetDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.getRequestDispatcher("/WEB-INF/views/forgot-password.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        String username = req.getParameter("username");
        String email    = req.getParameter("email");

        // ── Validate input ──
        if (username == null || username.trim().isEmpty()
                || email == null || email.trim().isEmpty()) {
            req.setAttribute("error", "Vui lòng nhập đầy đủ thông tin!");
            req.getRequestDispatcher("/WEB-INF/views/forgot-password.jsp").forward(req, resp);
            return;
        }

        // ── Tìm account ──
        Account staff = accountDAO.findByUsername(username.trim());
        if (staff == null || staff.getRoleId() == 1) {
            req.setAttribute("error", "Không tìm thấy tài khoản nhân viên!");
            req.getRequestDispatcher("/WEB-INF/views/forgot-password.jsp").forward(req, resp);
            return;
        }

        // ── Kiểm tra email khớp ──
        if (!email.trim().equalsIgnoreCase(staff.getEmail())) {
            req.setAttribute("error", "Email không khớp với tài khoản!");
            req.getRequestDispatcher("/WEB-INF/views/forgot-password.jsp").forward(req, resp);
            return;
        }

        // ── Kiểm tra đã có request PENDING/CONFIRMED chưa ──
        PasswordResetRequest existing = resetDAO.findPendingByAccountId(staff.getAccountId());
        if (existing == null) existing = resetDAO.findConfirmedByAccountId(staff.getAccountId());
        if (existing != null) {
            req.setAttribute("error", "Yêu cầu đặt lại mật khẩu đã được gửi! Vui lòng chờ admin xử lý.");
            req.getRequestDispatcher("/WEB-INF/views/forgot-password.jsp").forward(req, resp);
            return;
        }

        // ── Tạo token + request ──
        String token = UUID.randomUUID().toString().replace("-", "");
        LocalDateTime expiresAt = LocalDateTime.now().plusHours(24);
        PasswordResetRequest resetReq = new PasswordResetRequest(
                staff.getAccountId(), token, expiresAt);

        if (!resetDAO.insert(resetReq)) {
            req.setAttribute("error", "Lỗi hệ thống! Vui lòng thử lại.");
            req.getRequestDispatcher("/WEB-INF/views/forgot-password.jsp").forward(req, resp);
            return;
        }

        // ── KHÓA TÀI KHOẢN NGAY LẬP TỨC ──
        if (staff.isActive()) {
            accountDAO.toggleActive(staff.getAccountId());
        }

        // ── Gửi email thông báo cho Admin ──
        String adminEmail = accountDAO.findAll().stream()
                .filter(a -> a.getRoleId() == 1)
                .map(Account::getEmail)
                .filter(e -> e != null && !e.isEmpty())
                .findFirst().orElse(null);

        if (adminEmail != null) {
            String subject = "[MediVault] 🔐 Yêu cầu đặt lại mật khẩu — " + staff.getFullName();
            EmailUtil.sendEmail(adminEmail, subject, buildAdminEmail(staff, expiresAt));
        }

        // ── Gửi email xác nhận cho chính Staff ──
        EmailUtil.sendEmail(staff.getEmail(),
                "[MediVault] Yêu cầu đặt lại mật khẩu đã được ghi nhận",
                buildStaffConfirmEmail(staff));

        // ── Redirect về forgot-password với success message ──
        resp.sendRedirect(req.getContextPath()
                + "/forgot-password?success=sent&name="
                + java.net.URLEncoder.encode(staff.getFullName(), "UTF-8"));
    }

    // ── Email gửi Admin ──
    private String buildAdminEmail(Account staff, LocalDateTime expiresAt) {
        return """
            <div style="font-family:Arial,sans-serif;max-width:560px;margin:auto;padding:24px">
              <div style="background:linear-gradient(135deg,#1558A8,#0D3F85);border-radius:14px;
                          padding:20px 24px;margin-bottom:20px;color:#fff">
                <h2 style="margin:0;font-size:18px">🔐 Yêu cầu đặt lại mật khẩu</h2>
                <p style="margin:6px 0 0;opacity:.8;font-size:13px">Nhân viên vừa gửi yêu cầu — tài khoản đã bị khóa tự động</p>
              </div>
              <table style="width:100%%;border-collapse:collapse;margin:0 0 20px">
                <tr><td style="padding:10px 12px;background:#f1f5fb;border-radius:6px 0 0 0;
                               font-weight:700;font-size:13px;color:#7A90B0;width:140px">Họ tên</td>
                    <td style="padding:10px 12px;font-size:13px;color:#0B1628">%s</td></tr>
                <tr><td style="padding:10px 12px;background:#f1f5fb;font-weight:700;font-size:13px;color:#7A90B0">Username</td>
                    <td style="padding:10px 12px;font-size:13px;color:#0B1628">@%s</td></tr>
                <tr><td style="padding:10px 12px;background:#f1f5fb;font-weight:700;font-size:13px;color:#7A90B0">Email</td>
                    <td style="padding:10px 12px;font-size:13px;color:#0B1628">%s</td></tr>
                <tr><td style="padding:10px 12px;background:#f1f5fb;border-radius:0 0 0 6px;
                               font-weight:700;font-size:13px;color:#7A90B0">Yêu cầu lúc</td>
                    <td style="padding:10px 12px;font-size:13px;color:#0B1628">%s</td></tr>
              </table>
              <div style="background:#FEF2F2;border:1px solid #FECACA;border-radius:10px;
                          padding:14px 16px;margin-bottom:20px">
                <strong style="color:#991B1B">⚠️ Tài khoản đã bị khóa tự động.</strong>
                <p style="color:#7F1D1D;font-size:13px;margin:6px 0 0">
                  Vào trang quản lý tài khoản, tìm nhân viên <strong>@%s</strong>,
                  đặt mật khẩu mới (xác nhận bằng OTP) rồi tài khoản sẽ tự mở khóa.
                </p>
              </div>
              <a href="#" style="display:inline-block;padding:12px 28px;
                 background:linear-gradient(135deg,#1558A8,#0D3F85);color:#fff;
                 border-radius:10px;text-decoration:none;font-weight:700;font-size:14px">
                → Vào trang quản lý tài khoản
              </a>
              <p style="margin-top:20px;font-size:11px;color:#999">
                Thông báo tự động từ hệ thống MediVault. Vui lòng không trả lời email này.
              </p>
            </div>
            """.formatted(
                staff.getFullName(), staff.getUsername(),
                staff.getEmail(),
                java.time.format.DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy")
                        .format(LocalDateTime.now()),
                staff.getUsername());
    }

    // ── Email xác nhận gửi cho Staff ──
    private String buildStaffConfirmEmail(Account staff) {
        return """
            <div style="font-family:Arial,sans-serif;max-width:520px;margin:auto;padding:24px">
              <div style="background:linear-gradient(135deg,#6D28D9,#5B21B6);border-radius:14px;
                          padding:20px 24px;margin-bottom:20px;color:#fff">
                <h2 style="margin:0;font-size:18px">📬 Yêu cầu đã được ghi nhận</h2>
                <p style="margin:6px 0 0;opacity:.8;font-size:13px">Tài khoản của bạn đang được xử lý</p>
              </div>
              <p style="font-size:14px;color:#1C0F3F">Xin chào <strong>%s</strong>,</p>
              <p style="font-size:13.5px;color:#4C1D95;line-height:1.7">
                Yêu cầu đặt lại mật khẩu của tài khoản <strong>@%s</strong> đã được ghi nhận.<br>
                Tài khoản của bạn sẽ <strong>tạm thời bị khóa</strong> trong khi chờ Admin xử lý.
              </p>
              <div style="background:#F5F3FF;border:1px solid #D8D0F5;border-radius:10px;
                          padding:14px 18px;margin:20px 0">
                <p style="margin:0;font-size:13px;color:#4C1D95;font-weight:600">
                  ⏳ Admin sẽ đặt mật khẩu mới cho bạn và bạn sẽ nhận được email thông báo ngay sau đó.
                </p>
                <p style="margin:8px 0 0;font-size:12px;color:#6D28D9">
                  🔒 Vui lòng không chia sẻ mật khẩu mới với bất kỳ ai!
                </p>
              </div>
              <p style="font-size:12px;color:#999;margin-top:20px">
                Nếu bạn không thực hiện yêu cầu này, hãy liên hệ Admin ngay lập tức.
              </p>
            </div>
            """.formatted(staff.getFullName(), staff.getUsername());
    }
}