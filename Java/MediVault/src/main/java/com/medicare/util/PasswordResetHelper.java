package com.medicare.util;

import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.dao.interfaces.IPasswordResetDAO;
import com.medicare.entity.Account;
import com.medicare.entity.PasswordResetRequest;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

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
    public enum Result {
        OTP_SENT,          // pha 1 OK — đã gửi mã xác minh về email chính chủ
        SENT,              // pha 2 OK — đã khoá TK, tạo token, báo Admin
        ALREADY_PENDING, RATE_LIMITED, INSERT_FAILED,
        OTP_MISSING,       // chưa qua pha 1 (hoặc session đã hết)
        OTP_EXPIRED,       // quá 10 phút
        OTP_WRONG,         // sai mã
        OTP_LOCKED_OUT     // sai quá số lần cho phép
    }

    // ── Cấu hình OTP ──────────────────────────────────────────────────────────
    private static final int  OTP_LENGTH      = 6;
    private static final long OTP_TTL_MS      = 10 * 60 * 1000L;  // 10 phút
    private static final int  OTP_MAX_ATTEMPT = 5;                // chống dò mã

    // Khoá lưu trạng thái OTP trong session của CHÍNH trình duyệt đang yêu cầu
    private static final String S_CODE  = "pwreset_otp_code";
    private static final String S_UID   = "pwreset_otp_uid";
    private static final String S_EXP   = "pwreset_otp_exp";
    private static final String S_TRIES = "pwreset_otp_tries";

    /**
     * PHA 1 — gửi mã xác minh về email đã đăng ký. <b>KHÔNG đụng gì tới tài khoản.</b>
     *
     * <p>Trước đây bước này khoá tài khoản ngay lập tức, trong khi điều kiện kích hoạt
     * chỉ là "biết username + email" — hai thứ mà đồng nghiệp nào cũng biết. Hệ quả: bất
     * kỳ ai cũng vô hiệu hoá được tài khoản người khác giữa ca làm (DoS qua chức năng
     * quên mật khẩu). Rate-limit 3 lần/ngày không cứu được vì chỉ cần 1 lần là khoá.</p>
     *
     * <p>Nay việc khoá được dời sang {@link #confirmOtp} — chỉ chạy sau khi người yêu cầu
     * chứng minh mình đọc được hộp thư của chính chủ. Tính năng "đóng băng tài khoản khi
     * nghi bị chiếm" vẫn giữ nguyên, chỉ đổi thứ được phép bấm cò.</p>
     *
     * @param staff account ĐÃ được servlet xác thực (tồn tại, đúng role, khớp email)
     */
    public static Result requestOtp(HttpServletRequest req, Account staff,
                                    IPasswordResetDAO resetDAO) {
        resetDAO.expireOld();

        if (resetDAO.countTodayByAccountId(staff.getAccountId()) >= 3) {
            return Result.RATE_LIMITED;
        }

        PasswordResetRequest existing = resetDAO.findPendingByAccountId(staff.getAccountId());
        if (existing == null) existing = resetDAO.findConfirmedByAccountId(staff.getAccountId());
        if (existing != null) return Result.ALREADY_PENDING;

        String code = OtpUtil.generate(OTP_LENGTH);
        HttpSession session = req.getSession(true);
        session.setAttribute(S_CODE,  code);
        session.setAttribute(S_UID,   staff.getAccountId());
        session.setAttribute(S_EXP,   System.currentTimeMillis() + OTP_TTL_MS);
        session.setAttribute(S_TRIES, 0);

        EmailUtil.sendEmail(staff.getEmail(),
                "[MediVault] Mã xác minh yêu cầu đặt lại mật khẩu",
                buildOtpEmail(staff, code));

        AuditHelper.log(req, "Gửi mã xác minh reset mật khẩu", "Auth",
                "@" + staff.getUsername() + " yêu cầu reset — đã gửi OTP về email, CHƯA khoá tài khoản",
                staff.getAccountId());

        return Result.OTP_SENT;
    }

    /** accountId đang chờ xác minh OTP trong session này (null nếu không có). */
    public static Integer pendingAccountId(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) return null;
        Object uid = session.getAttribute(S_UID);
        return (uid instanceof Integer) ? (Integer) uid : null;
    }

    /**
     * PHA 2 — nhập đúng OTP thì mới: tạo token 24h, <b>khoá tài khoản</b>, báo Admin,
     * gửi email xác nhận cho nhân sự, ghi audit.
     */
    public static Result confirmOtp(HttpServletRequest req, String inputCode,
                                    IAccountDAO accountDAO, IPasswordResetDAO resetDAO) {
        HttpSession session = req.getSession(false);
        if (session == null) return Result.OTP_MISSING;

        Object code = session.getAttribute(S_CODE);
        Object uid  = session.getAttribute(S_UID);
        Object exp  = session.getAttribute(S_EXP);
        if (!(code instanceof String) || !(uid instanceof Integer) || !(exp instanceof Long)) {
            return Result.OTP_MISSING;
        }

        if (System.currentTimeMillis() > (Long) exp) {
            clearOtp(session);
            return Result.OTP_EXPIRED;
        }

        // Chống dò mã: 6 chữ số mà cho thử vô hạn thì vẫn brute-force được
        int tries = (session.getAttribute(S_TRIES) instanceof Integer)
                ? (Integer) session.getAttribute(S_TRIES) : 0;
        if (tries >= OTP_MAX_ATTEMPT) {
            clearOtp(session);
            return Result.OTP_LOCKED_OUT;
        }

        if (inputCode == null || !((String) code).equals(inputCode.trim())) {
            session.setAttribute(S_TRIES, tries + 1);
            return Result.OTP_WRONG;
        }

        // ── OTP hợp lệ → từ đây mới được đụng vào tài khoản ──
        clearOtp(session);
        int accountId = (Integer) uid;
        Account staff = accountDAO.findById(accountId);
        if (staff == null) return Result.OTP_MISSING;

        LocalDateTime expiresAt = LocalDateTime.now().plusHours(24);
        String token = UUID.randomUUID().toString().replace("-", "");
        PasswordResetRequest resetReq = new PasswordResetRequest(accountId, token, expiresAt);
        boolean inserted = tryInsert(resetDAO, resetReq);
        if (!inserted) {
            token = UUID.randomUUID().toString().replace("-", "")
                    + Long.toHexString(System.currentTimeMillis());
            resetReq = new PasswordResetRequest(accountId, token, expiresAt);
            inserted = tryInsert(resetDAO, resetReq);
        }
        if (!inserted) {
            System.err.println("[PasswordReset] insert thất bại 2 lần cho accountId="
                    + accountId + " username=" + staff.getUsername());
            return Result.INSERT_FAILED;
        }

        // Khoá tài khoản — giờ đã chắc chắn do chính chủ yêu cầu
        if (staff.isActive()) {
            accountDAO.toggleActive(accountId);
        }

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

        EmailUtil.sendEmail(staff.getEmail(),
                "[MediVault] Yêu cầu đặt lại mật khẩu đã được ghi nhận",
                buildStaffConfirmEmail(staff));

        AuditHelper.log(req, "Xác minh OTP reset mật khẩu", "Auth",
                "@" + staff.getUsername() + " đã xác minh OTP — tài khoản bị khoá, chờ Admin đặt mật khẩu mới",
                accountId);

        return Result.SENT;
    }

    /** Che bớt email khi hiện lên màn hình: nguyenvana@gmail.com → ngu***na@gmail.com */
    public static String maskEmail(String email) {
        if (email == null) return "";
        int at = email.indexOf('@');
        if (at <= 3) return email;
        return email.substring(0, 3) + "***" + email.substring(Math.max(3, at - 2));
    }

    private static void clearOtp(HttpSession session) {
        session.removeAttribute(S_CODE);
        session.removeAttribute(S_UID);
        session.removeAttribute(S_EXP);
        session.removeAttribute(S_TRIES);
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

    // ── Email chứa mã OTP gửi cho chính chủ (PHA 1) ──
    private static String buildOtpEmail(Account staff, String code) {
        return """
            <div style="font-family:Arial,sans-serif;max-width:520px;margin:auto;padding:24px">
              <div style="background:linear-gradient(135deg,#0F766E,#115E59);border-radius:14px;
                          padding:20px 24px;margin-bottom:20px;color:#fff">
                <h2 style="margin:0;font-size:18px">🔑 Mã xác minh đặt lại mật khẩu</h2>
                <p style="margin:6px 0 0;opacity:.85;font-size:13px">Xác nhận chính bạn là người gửi yêu cầu</p>
              </div>
              <p style="font-size:14px;color:#1C2B29">Xin chào <strong>%s</strong>,</p>
              <p style="font-size:13.5px;color:#334155;line-height:1.7">
                Có yêu cầu đặt lại mật khẩu cho tài khoản <strong>@%s</strong>.
                Nhập mã dưới đây để xác nhận:
              </p>
              <div style="text-align:center;margin:22px 0">
                <div style="display:inline-block;background:#F1F5F9;border:2px dashed #0F766E;
                            border-radius:12px;padding:16px 30px;font-size:30px;font-weight:800;
                            letter-spacing:9px;color:#0F766E;font-family:monospace">%s</div>
              </div>
              <p style="font-size:12.5px;color:#64748B;line-height:1.6">
                Mã có hiệu lực trong <strong>10 phút</strong>.<br>
                Sau khi xác nhận, tài khoản sẽ <strong>tạm khoá</strong> để bảo vệ, và Admin sẽ
                đặt mật khẩu mới cho bạn.
              </p>
              <div style="background:#FFFBEB;border:1px solid #FDE68A;border-radius:10px;
                          padding:12px 15px;margin-top:18px">
                <p style="margin:0;font-size:12.5px;color:#92400E">
                  ⚠️ <strong>Bạn KHÔNG yêu cầu việc này?</strong> Hãy bỏ qua email — tài khoản của bạn
                  vẫn hoạt động bình thường và không có gì thay đổi.
                </p>
              </div>
            </div>
            """.formatted(staff.getFullName(), staff.getUsername(), code);
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
