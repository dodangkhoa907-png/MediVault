package com.medicare.service;

import com.medicare.dao.AccountDAO;
import com.medicare.dao.PasswordResetDAO;
import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.dao.interfaces.IPasswordResetDAO;
import com.medicare.entity.Account;
import com.medicare.service.interfaces.IAccountService;
import com.medicare.util.*;

import java.util.ArrayList;
import java.util.List;

/**
 * AccountService — Tầng nghiệp vụ cho quản lý tài khoản.
 *
 * Trước đây logic create/reset nằm trực tiếp trong AccountServlet (300+ dòng).
 * Nay tách ra đây để dễ test, dễ maintain, Servlet chỉ lo HTTP.
 */
public class AccountService implements IAccountService {

    private final IAccountDAO       accountDAO = new AccountDAO();
    private final IPasswordResetDAO resetDAO   = new PasswordResetDAO();

    // ── Tạo tài khoản ─────────────────────────────────────────────────────

    @Override
    public ServiceResult<Account> createAccount(
            String username, String fullName,
            String email, String phone,
            String citizenId, String position,
            int roleId, String password) {

        // ── Bước 1: Auto-generate username từ SĐT nếu admin bỏ trống ──────
        if (ValidationUtil.isBlank(username) && ValidationUtil.notBlank(phone)) {
            username = phone.trim().replaceAll("[^0-9]", "");
        }

        // ── Bước 2: Validate format ──────────────────────────────────────
        List<String> errors = new ArrayList<>(
                ValidationUtil.validateAccount(username, fullName, email, phone, citizenId, position));
        errors.addAll(ValidationUtil.validatePassword(password));

        if (!ValidationUtil.notBlank(citizenId))
            errors.add("Số CMND/CCCD không được để trống.");

        if (ValidationUtil.notBlank(username)) {
            if (ValidationUtil.isReservedUsername(username))
                errors.add("Tên đăng nhập '" + username + "' là tên hệ thống — không được phép sử dụng.");
            else if (accountDAO.isUsernameTaken(username))
                errors.add("Tên đăng nhập '" + username + "' đã tồn tại.");
        }
        if (ValidationUtil.notBlank(email)    && accountDAO.isEmailTaken(email, -1))
            errors.add("Email '" + email + "' đã được dùng.");
        if (ValidationUtil.notBlank(phone)    && accountDAO.isPhoneTaken(phone, -1))
            errors.add("Số điện thoại '" + phone.trim() + "' đã được dùng bởi tài khoản khác.");

        if (!errors.isEmpty()) return ServiceResult.fail(errors);

        // ── Bước 3: Tạo entity + hash password ───────────────────────────
        Account a = new Account();
        a.setUsername(username.trim());
        a.setFullName(fullName.trim());
        a.setEmail(email    != null ? email.trim()    : null);
        a.setPhone(phone    != null ? phone.trim()    : null);
        a.setCitizenId(citizenId != null && !citizenId.trim().isEmpty() ? citizenId.trim() : "");
        a.setPosition(position  != null ? position.trim() : null);
        a.setRoleId(roleId);
        a.setPasswordHash(PasswordUtil.hashPassword(password));

        // ── Bước 4: Insert DB ─────────────────────────────────────────────
        boolean ok = accountDAO.insert(a);
        if (!ok) return ServiceResult.fail("Tạo tài khoản thất bại — kiểm tra log Tomcat!");

        // ── Bước 5: Gửi email chào mừng (async nếu có email) ─────────────
        if (email != null && !email.trim().isEmpty()) {
            String html = buildWelcomeEmailHtml(fullName, username, position);
            EmailUtil.sendEmail(
                    email.trim(),
                    "[MediVault] 🎉 Tài khoản của bạn đã được tạo thành công",
                    html);
        }

        // ── Bước 6: Lấy lại entity vừa tạo + gửi notification nội bộ ────
        Account created = accountDAO.findByUsername(username.trim());
        if (created != null) {
            StaffNotifHelper.accountCreated(created.getAccountId(),
                    fullName != null ? fullName.trim() : username.trim());
            StaffNotifHelper.faceEnrollReminder(created.getAccountId());
        }

        return ServiceResult.ok(created);
    }

    // ── Đặt lại mật khẩu ──────────────────────────────────────────────────

    @Override
    public ServiceResult<Void> setPassword(int targetId, String newPassword, boolean isResetFlow) {
        Account staff = accountDAO.findById(targetId);
        if (staff == null) return ServiceResult.fail("Tài khoản không tồn tại!");

        // Validate mật khẩu mới
        List<String> pwErrors = ValidationUtil.validatePassword(newPassword);
        if (!pwErrors.isEmpty()) return ServiceResult.fail(pwErrors);

        // Cập nhật hash
        accountDAO.resetPassword(targetId, PasswordUtil.hashPassword(newPassword));

        // Hoàn tất reset request trong DB (xóa khỏi danh sách chờ)
        resetDAO.complete(targetId);

        // Nếu là reset flow: mở khóa tài khoản (staff có thể đang bị block)
        if (isResetFlow && !staff.isActive()) {
            accountDAO.toggleActive(targetId);
        }

        // Gửi email thông báo cho nhân viên
        String staffEmail = staff.getEmail();
        if (staffEmail != null && !staffEmail.isEmpty()) {
            String html = buildPasswordResetEmailHtml(staff, isResetFlow);
            EmailUtil.sendEmail(
                    staffEmail,
                    "[MediVault] ✅ Tài khoản @" + staff.getUsername() + " đã được cập nhật mật khẩu",
                    html);
        }

        // Thông báo nội bộ
        StaffNotifHelper.passwordReset(targetId);

        return ServiceResult.ok();
    }

    // ── Email HTML helpers (private) ───────────────────────────────────────

    private String buildWelcomeEmailHtml(String fullName, String username, String position) {
        return "<div style=\"font-family:Arial,sans-serif;max-width:520px;margin:auto;padding:24px\">"
                + "<div style=\"background:linear-gradient(135deg,#1E3A8A,#3B82F6);border-radius:14px;"
                + "padding:20px 24px;margin-bottom:20px;color:#fff\">"
                + "<h2 style=\"margin:0;font-size:18px\">🎉 Tài khoản MediVault của bạn đã được tạo!</h2>"
                + "<p style=\"margin:6px 0 0;opacity:.8;font-size:13px\">Hệ thống quản lý kho dược và ca trực MediVault</p>"
                + "</div>"
                + "<p style=\"font-size:14px;color:#1C0F3F\">Xin chào <strong>" + escHtml(fullName) + "</strong>,</p>"
                + "<p style=\"font-size:13.5px;color:#374151;line-height:1.7\">"
                + "Tài khoản của bạn đã được khởi tạo thành công trên hệ thống bởi Ban quản trị.</p>"
                + "<div style=\"background:#F8FAFC;border:1px solid #E2E8F0;border-radius:12px;"
                + "padding:18px 20px;margin:18px 0\">"
                + "<p style=\"margin:0 0 6px;font-size:14px;color:#334155\">👤 Tên đăng nhập: "
                + "<strong style=\"color:#0F172A\">@" + escHtml(username) + "</strong></p>"
                + "<p style=\"margin:0 0 12px;font-size:14px;color:#334155\">💼 Chức vụ: "
                + "<strong>" + escHtml(position != null ? position : "Nhân viên") + "</strong></p>"
                + "<hr style=\"border:0;border-top:1px solid #E2E8F0;margin:12px 0\">"
                + "<p style=\"margin:0 0 8px;font-size:12px;font-weight:700;color:#1E3A8A;"
                + "letter-spacing:1px;text-transform:uppercase\">🔑 Mật khẩu</p>"
                + "<p style=\"margin:0;font-size:13px;color:#374151;line-height:1.6\">"
                + "Mật khẩu đăng nhập sẽ được <strong>Admin cung cấp trực tiếp</strong> cho bạn.</p>"
                + "<p style=\"margin:8px 0 0;font-size:12px;color:#6B7280\">"
                + "💡 Sau khi nhận mật khẩu, hãy đổi ngay lần đăng nhập đầu tiên.</p>"
                + "</div>"
                + "<p style=\"font-size:12px;color:#999\">Đây là email tự động từ MediVault, vui lòng không phản hồi.</p>"
                + "</div>";
    }

    private String buildPasswordResetEmailHtml(Account staff, boolean isResetFlow) {
        String title   = isResetFlow ? "✅ Mật khẩu đã được cập nhật!" : "🔐 Mật khẩu đã được đặt lại!";
        String subText = isResetFlow ? "Tài khoản của bạn đã được mở khóa" : "Admin vừa đặt lại mật khẩu cho bạn";
        String extraNote = isResetFlow
                ? " Tài khoản của bạn đã được <strong>mở khóa</strong> và bạn có thể đăng nhập lại ngay."
                : "";

        return "<div style=\"font-family:Arial,sans-serif;max-width:520px;margin:auto;padding:24px\">"
                + "<div style=\"background:linear-gradient(135deg,#059669,#047857);border-radius:14px;"
                + "padding:20px 24px;margin-bottom:20px;color:#fff\">"
                + "<h2 style=\"margin:0;font-size:18px\">" + title + "</h2>"
                + "<p style=\"margin:6px 0 0;opacity:.8;font-size:13px\">" + subText + "</p></div>"
                + "<p style=\"font-size:14px;color:#1C0F3F\">Xin chào <strong>"
                + escHtml(staff.getFullName()) + "</strong>,</p>"
                + "<p style=\"font-size:13.5px;color:#374151;line-height:1.7\">"
                + "Mật khẩu tài khoản <strong>@" + escHtml(staff.getUsername()) + "</strong>"
                + " đã được đặt lại thành công." + extraNote + "</p>"
                + "<div style=\"background:#F0FDF4;border:2px solid #86EFAC;border-radius:12px;"
                + "padding:18px 20px;margin:18px 0\">"
                + "<p style=\"margin:0 0 8px;font-size:12px;font-weight:700;color:#15803D;"
                + "letter-spacing:1px;text-transform:uppercase\">🔑 Mật khẩu đã được đặt lại</p>"
                + "<p style=\"margin:0;font-size:13px;color:#374151;line-height:1.6\">"
                + "Mật khẩu mới sẽ được <strong>Admin cung cấp trực tiếp</strong>. Liên hệ Ban quản trị.</p>"
                + "<p style=\"margin:8px 0 0;font-size:12px;color:#6B7280\">"
                + "💡 Sau khi nhận mật khẩu, hãy đổi ngay khi đăng nhập.</p>"
                + "</div>"
                + "<p style=\"font-size:12px;color:#999\">"
                + "Nếu bạn không yêu cầu điều này, hãy liên hệ Admin ngay lập tức.</p></div>";
    }

    private static String escHtml(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;").replace("'", "&#39;");
    }
}
