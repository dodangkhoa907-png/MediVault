package com.medicare.controller.staff;

import com.medicare.config.AppCache;
import com.medicare.dao.AccountDAO;
import com.medicare.entity.Account;
import com.medicare.util.AuditHelper;
import com.medicare.util.EmailUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

/**
 * FaceReenrollServlet — Luồng XIN ĐĂNG KÝ LẠI KHUÔN MẶT.
 * URL: /face-reenroll
 *
 * NHÂN VIÊN (từ "Hồ sơ của tôi"):
 *   POST action=request  uid=X  reason=...
 *        → set FaceReenrollStatus = PENDING → chặn quét mặt điểm danh
 *          (vẫn đăng nhập bình thường) → gửi mail cho toàn bộ admin.
 *
 * ADMIN (từ trang quản lý nhân viên):
 *   POST action=approve  accountId=X
 *        → xóa FaceVector (buộc đăng ký lại từ đầu) → gửi mail cho NV.
 *   POST action=reject   accountId=X  note=...
 *        → giữ khuôn mặt cũ, hủy yêu cầu → gửi mail cho NV.
 *
 * Response JSON: {"ok":true} hoặc {"ok":false,"reason":"..."}
 */
@WebServlet("/face-reenroll")
public class FaceReenrollServlet extends HttpServlet {

    private final AccountDAO dao = new AccountDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");
        req.setCharacterEncoding("UTF-8");

        String action = req.getParameter("action");
        if ("approve".equals(action) || "reject".equals(action)) {
            handleAdminDecision(req, resp, action);
        } else {
            handleStaffRequest(req, resp);
        }
    }

    // ── NHÂN VIÊN gửi yêu cầu ────────────────────────────────────────────────
    private void handleStaffRequest(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String uid = req.getParameter("uid");
        if (uid == null || uid.isEmpty()) {
            writeJson(resp, "{\"ok\":false,\"reason\":\"missing_uid\"}"); return;
        }
        HttpSession session = req.getSession(false);
        Account staff = session != null
                ? (Account) session.getAttribute("staffAccount_" + uid) : null;
        if (staff == null) {
            writeJson(resp, "{\"ok\":false,\"reason\":\"unauthorized\"}"); return;
        }

        // Đọc lại trạng thái mới nhất từ DB (session có thể cũ)
        Account fresh = dao.findById(staff.getAccountId());
        if (fresh == null) {
            writeJson(resp, "{\"ok\":false,\"reason\":\"not_found\"}"); return;
        }
        if (fresh.isFaceReenrollPending()) {
            writeJson(resp, "{\"ok\":false,\"reason\":\"already_pending\"}"); return;
        }
        if (!fresh.isFaceEnrolled()) {
            // Chưa có khuôn mặt thì cứ vào đăng ký thẳng, không cần xin duyệt
            writeJson(resp, "{\"ok\":false,\"reason\":\"no_face_to_reenroll\"}"); return;
        }

        String reason = req.getParameter("reason");
        boolean ok = dao.requestFaceReenroll(staff.getAccountId(), reason);
        if (!ok) {
            writeJson(resp, "{\"ok\":false,\"reason\":\"db_error\"}"); return;
        }

        // Cập nhật session để UI phản ánh ngay
        staff.setFaceReenrollStatus("PENDING");
        staff.setFaceReenrollReason(reason);
        staff.setFaceReenrollRequestedAt(java.time.LocalDateTime.now());
        session.setAttribute("staffAccount_" + uid, staff);
        AppCache.invalidateStaff();

        AuditHelper.log(req, "FACE_REENROLL_REQUEST", "Account", staff.getAccountId(),
                "@" + staff.getUsername() + " xin đăng ký lại khuôn mặt — lý do: "
                        + (reason != null ? reason : "(không nêu)"));

        notifyAdmins(fresh, reason);
        writeJson(resp, "{\"ok\":true}");
    }

    // ── ADMIN duyệt / từ chối ────────────────────────────────────────────────
    private void handleAdminDecision(HttpServletRequest req, HttpServletResponse resp,
                                     String action) throws IOException {
        HttpSession session = req.getSession(false);
        Account admin = session != null ? (Account) session.getAttribute("adminAccount") : null;
        if (admin == null || admin.getRoleId() != 1) {
            writeJson(resp, "{\"ok\":false,\"reason\":\"unauthorized\"}"); return;
        }

        String idStr = req.getParameter("accountId");
        int accountId;
        try { accountId = Integer.parseInt(idStr); }
        catch (Exception e) { writeJson(resp, "{\"ok\":false,\"reason\":\"invalid_account_id\"}"); return; }

        Account target = dao.findById(accountId);
        if (target == null) { writeJson(resp, "{\"ok\":false,\"reason\":\"account_not_found\"}"); return; }
        if (!target.isFaceReenrollPending()) {
            writeJson(resp, "{\"ok\":false,\"reason\":\"no_pending_request\"}"); return;
        }

        boolean ok;
        if ("approve".equals(action)) {
            ok = dao.approveFaceReenroll(accountId, admin.getAccountId());
            if (ok) {
                AppCache.invalidateStaff();
                AuditHelper.log(req, "FACE_REENROLL_APPROVE", "Account", accountId,
                        "Duyệt yêu cầu đăng ký lại khuôn mặt của " + target.getFullName()
                                + " (ID " + accountId + ") — đã xóa khuôn mặt cũ");
                notifyStaffApproved(req, target);
            }
        } else {
            String note = req.getParameter("note");
            ok = dao.rejectFaceReenroll(accountId, admin.getAccountId(), note);
            if (ok) {
                AppCache.invalidateStaff();
                AuditHelper.log(req, "FACE_REENROLL_REJECT", "Account", accountId,
                        "Từ chối yêu cầu đăng ký lại khuôn mặt của " + target.getFullName()
                                + " (ID " + accountId + ")" + (note != null ? " — " + note : ""));
                notifyStaffRejected(target, note);
            }
        }
        writeJson(resp, ok ? "{\"ok\":true}" : "{\"ok\":false,\"reason\":\"db_error\"}");
    }

    // ── Email helpers ────────────────────────────────────────────────────────
    private void notifyAdmins(Account staff, String reason) {
        List<String> admins = dao.findActiveAdminEmails();
        if (admins.isEmpty()) return;
        String name = staff.getFullName() != null ? staff.getFullName() : staff.getUsername();
        String subject = "🔴 [MediCare] Yêu cầu đăng ký lại khuôn mặt — " + name;
        String body =
                "<div style='font-family:Segoe UI,Arial,sans-serif;max-width:560px;margin:auto'>"
                + "<div style='background:linear-gradient(135deg,#dc2626,#b91c1c);color:#fff;padding:20px 24px;border-radius:12px 12px 0 0'>"
                + "<h2 style='margin:0;font-size:18px'>🔴 Yêu cầu đổi khuôn mặt điểm danh</h2></div>"
                + "<div style='border:1px solid #eee;border-top:none;padding:22px 24px;border-radius:0 0 12px 12px'>"
                + "<p>Nhân viên <b>" + esc(name) + "</b> (@" + esc(staff.getUsername())
                + ", ID " + staff.getAccountId() + ") vừa gửi yêu cầu <b>đăng ký lại khuôn mặt</b>.</p>"
                + "<p style='background:#fef2f2;border-left:4px solid #dc2626;padding:10px 14px;border-radius:6px'>"
                + "<b>Lý do:</b><br>" + esc(reason != null && !reason.trim().isEmpty() ? reason : "(không nêu)") + "</p>"
                + "<p>Trong lúc chờ duyệt, nhân viên <b>không thể quét khuôn mặt để điểm danh</b> "
                + "(vẫn đăng nhập & bán hàng bình thường).</p>"
                + "<p>Vui lòng vào <b>Quản trị → Nhân viên & Khách hàng</b> để <b>duyệt</b> hoặc <b>từ chối</b>.</p>"
                + "<p style='color:#888;font-size:12px;margin-top:20px'>MediCare Pharmacy System</p>"
                + "</div></div>";
        for (String to : admins) EmailUtil.sendEmail(to, subject, body);
    }

    private void notifyStaffApproved(HttpServletRequest req, Account staff) {
        if (staff.getEmail() == null || staff.getEmail().isEmpty()) return;
        String name = staff.getFullName() != null ? staff.getFullName() : staff.getUsername();
        String base = req.getScheme() + "://" + req.getServerName()
                + ":" + req.getServerPort() + req.getContextPath();
        String subject = "✅ [MediCare] Yêu cầu đăng ký lại khuôn mặt đã được duyệt";
        String body =
                "<div style='font-family:Segoe UI,Arial,sans-serif;max-width:560px;margin:auto'>"
                + "<div style='background:linear-gradient(135deg,#059669,#047857);color:#fff;padding:20px 24px;border-radius:12px 12px 0 0'>"
                + "<h2 style='margin:0;font-size:18px'>✅ Yêu cầu đã được duyệt</h2></div>"
                + "<div style='border:1px solid #eee;border-top:none;padding:22px 24px;border-radius:0 0 12px 12px'>"
                + "<p>Chào <b>" + esc(name) + "</b>,</p>"
                + "<p>Yêu cầu <b>đăng ký lại khuôn mặt</b> của bạn đã được quản trị viên <b>duyệt</b>. "
                + "Khuôn mặt cũ đã được xóa.</p>"
                + "<p>Vui lòng đăng nhập vào tài khoản nhân viên và <b>đăng ký khuôn mặt mới</b> "
                + "(giống như lần đầu chưa tạo khuôn mặt điểm danh).</p>"
                + "<p style='text-align:center;margin:24px 0'>"
                + "<a href='" + base + "/staff-login' style='background:#059669;color:#fff;text-decoration:none;"
                + "padding:12px 28px;border-radius:8px;font-weight:700'>Đăng nhập & đăng ký lại</a></p>"
                + "<p style='color:#888;font-size:12px;margin-top:20px'>MediCare Pharmacy System</p>"
                + "</div></div>";
        EmailUtil.sendEmail(staff.getEmail(), subject, body);
    }

    private void notifyStaffRejected(Account staff, String note) {
        if (staff.getEmail() == null || staff.getEmail().isEmpty()) return;
        String name = staff.getFullName() != null ? staff.getFullName() : staff.getUsername();
        String subject = "❌ [MediCare] Yêu cầu đăng ký lại khuôn mặt bị từ chối";
        String body =
                "<div style='font-family:Segoe UI,Arial,sans-serif;max-width:560px;margin:auto'>"
                + "<div style='background:linear-gradient(135deg,#6b7280,#4b5563);color:#fff;padding:20px 24px;border-radius:12px 12px 0 0'>"
                + "<h2 style='margin:0;font-size:18px'>❌ Yêu cầu bị từ chối</h2></div>"
                + "<div style='border:1px solid #eee;border-top:none;padding:22px 24px;border-radius:0 0 12px 12px'>"
                + "<p>Chào <b>" + esc(name) + "</b>,</p>"
                + "<p>Yêu cầu <b>đăng ký lại khuôn mặt</b> của bạn đã bị quản trị viên <b>từ chối</b>. "
                + "Khuôn mặt điểm danh hiện tại vẫn được giữ nguyên.</p>"
                + (note != null && !note.trim().isEmpty()
                    ? "<p style='background:#f9fafb;border-left:4px solid #6b7280;padding:10px 14px;border-radius:6px'>"
                      + "<b>Ghi chú:</b><br>" + esc(note) + "</p>" : "")
                + "<p>Nếu cần, vui lòng liên hệ trực tiếp quản lý.</p>"
                + "<p style='color:#888;font-size:12px;margin-top:20px'>MediCare Pharmacy System</p>"
                + "</div></div>";
        EmailUtil.sendEmail(staff.getEmail(), subject, body);
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
    }

    private void writeJson(HttpServletResponse resp, String json) throws IOException {
        try (PrintWriter out = resp.getWriter()) { out.print(json); }
    }
}
