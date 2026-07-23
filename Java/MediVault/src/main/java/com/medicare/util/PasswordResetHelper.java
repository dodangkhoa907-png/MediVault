package com.medicare.util;

import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.dao.interfaces.IPasswordResetDAO;
import com.medicare.entity.Account;
import com.medicare.entity.PasswordResetRequest;
import jakarta.servlet.http.HttpServletRequest;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

/**
 * PasswordResetHelper — Logic LÕI của luồng "quên mật khẩu", dùng CHUNG cho cả
 * portal Nhân viên ({@code /forgot-password}) và Quản lý kho
 * ({@code /warehouse-forgot-password}).
 *
 * <p>Servlet gọi tự lo phần riêng của từng portal (validate input, tìm account,
 * khớp email, chọn trang JSP + trang login để redirect về). Phần chung — chống
 * spam, tạo token, khóa tài khoản, gửi email cho Admin &amp; nhân sự, ghi audit —
 * nằm ở {@link #submit}.</p>
 */
public final class PasswordResetHelper {

    private PasswordResetHelper() {}

    /** Kết quả xử lý để servlet quyết định hiển thị gì. */
    public enum Result { SENT, ALREADY_PENDING, RATE_LIMITED, INSERT_FAILED }

    /**
     * Xử lý phần lõi: chống quá 3 lần/ngày, tạo token 24h, khóa tài khoản, gửi
     * email cho Admin + nhân sự, ghi audit. KHÔNG đụng tới JSP/redirect.
     *
     * @param staff account ĐÃ được servlet xác thực (tồn tại, đúng role, khớp email)
     */
    public static Result submit(HttpServletRequest req, Account staff,
                                IAccountDAO accountDAO, IPasswordResetDAO resetDAO) {
        // Dọn record quá hạn trước
        resetDAO.expireOld();

        // Giới hạn 3 lần/ngày
        if (resetDAO.countTodayByAccountId(staff.getAccountId()) >= 3) {
            return Result.RATE_LIMITED;
        }

        // Đang có yêu cầu chờ xử lý → không tạo thêm
        PasswordResetRequest existing = resetDAO.findPendingByAccountId(staff.getAccountId());
        if (existing == null) existing = resetDAO.findConfirmedByAccountId(staff.getAccountId());
        if (existing != null) return Result.ALREADY_PENDING;

        // Tạo token mới + insert (retry 1 lần phòng UUID trùng cực hiếm)
        LocalDateTime expiresAt = LocalDateTime.now().plusHours(24);
        String token = UUID.randomUUID().toString().replace("-", "");
        PasswordResetRequest resetReq = new PasswordResetRequest(staff.getAccountId(), token, expiresAt);
        boolean inserted = tryInsert(resetDAO, resetReq);
        if (!inserted) {
            token = UUID.randomUUID().toString().replace("-", "")
                    + Long.toHexString(System.currentTimeMillis());
            resetReq = new PasswordResetRequest(staff.getAccountId(), token, expiresAt);
            inserted = tryInsert(resetDAO, resetReq);
        }
        if (!inserted) {
            System.err.println("[PasswordReset] insert thất bại 2 lần cho accountId="
                    + staff.getAccountId() + " username=" + staff.getUsername());
            return Result.INSERT_FAILED;
        }

        // Khóa tài khoản ngay lập tức
        if (staff.isActive()) {
            accountDAO.toggleActive(staff.getAccountId());
        }

        // Email cho Admin
        String adminEmail = accountDAO.findAll().stream()
                .filter(a -> a.getRoleId() == 1)
                .map(Account::getEmail)
                .filter(e -> e != null && !e.isEmpty())
                .findFirst().orElse(null);
        if (adminEmail != null) {
            EmailUtil.sendEmail(adminEmail,
                    "[MediVault] 🔐 Yêu cầu đặt lại mật khẩu — " + staff.getFullName(),
                    buildAdminEmail(staff));
        }

        // Email xác nhận cho nhân sự
        EmailUtil.sendEmail(staff.getEmail(),
                "[MediVault] Yêu cầu đặt lại mật khẩu đã được ghi nhận",
                buildStaffConfirmEmail(staff));

        AuditHelper.log(req, "Yêu cầu đặt lại mật khẩu", "Auth",
                "@" + staff.getUsername() + " gửi yêu cầu reset mật khẩu — tài khoản bị khóa tự động",
                staff.getAccountId());

        return Result.SENT;
    }

    private static boolean tryInsert(IPasswordResetDAO dao, PasswordResetRequest r) {
        try {
            return dao.insert(r);
        } catch (Exception ex) {
            System.err.println("[PasswordReset] insert exception: " + ex.getMessage());
            ex.printStackTrace();
            return false;
        }
    }

    // ── Email gửi Admin ──
    private static String buildAdminEmail(Account staff) {
        return """
            <div style="font-family:Arial,sans-serif;max-width:560px;margin:auto;padding:24px">
              <div style="background:linear-gradient(135deg,#1558A8,#0D3F85);border-radius:14px;
                          padding:20px 24px;margin-bottom:20px;color:#fff">
                <h2 style="margin:0;font-size:18px">🔐 Yêu cầu đặt lại mật khẩu</h2>
                <p style="margin:6px 0 0;opacity:.8;font-size:13px">Nhân sự vừa gửi yêu cầu — tài khoản đã bị khóa tự động</p>
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
                  Vào trang quản lý tài khoản, tìm nhân sự <strong>@%s</strong>,
                  đặt mật khẩu mới (xác nhận bằng OTP) rồi tài khoản sẽ tự mở khóa.
                </p>
              </div>
              <p style="margin-top:20px;font-size:11px;color:#999">
                Thông báo tự động từ hệ thống MediVault. Vui lòng không trả lời email này.
              </p>
            </div>
            """.formatted(
                staff.getFullName(), staff.getUsername(), staff.getEmail(),
                DateTimeFormatter.ofPattern("HH:mm dd/MM/yyyy").format(LocalDateTime.now()),
                staff.getUsername());
    }

    // ── Email xác nhận gửi cho nhân sự ──
    private static String buildStaffConfirmEmail(Account staff) {
        return """
            <div style="font-family:Arial,sans-serif;max-width:520px;margin:auto;padding:24px">
              <div style="background:linear-gradient(135deg,#6D28D9,#5B21B6);border-radius:14px;
                          padding:20px 24px;margin-bottom:20px;color:#fff">
                <h2 style="margin:0;font-size:18px">📬 Yêu cầu đã được ghi nhận</h2>
                <p style="margin:6px 0 0;opacity:.8;font-size:13px">Tài khoản của bạn đang được xử lý</p>
              </div>
              <p style="font-size:14px;color:#1C0F3F">📋 Thông tin yêu cầu từ: <strong>%s</strong>,</p>
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
