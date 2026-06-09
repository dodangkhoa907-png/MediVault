package com.medivault.controller.admin;

import com.medivault.dao.AccountDAO;
import com.medivault.dao.PasswordResetDAO;
import com.medivault.dao.interfaces.IAccountDAO;
import com.medivault.dao.interfaces.IPasswordResetDAO;
import com.medivault.entity.PasswordResetRequest;
import com.medivault.entity.Account;
import com.medivault.util.PasswordUtil;
import com.medivault.util.ValidationUtil;
import com.medivault.util.AuditHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import com.medivault.util.EmailUtil;
import com.medivault.util.OtpUtil;
import jakarta.servlet.http.HttpSession;
import java.util.List;

import java.io.IOException;
import java.io.PrintWriter;
import java.time.LocalDate;


@WebServlet("/accounts")
public class AccountServlet extends HttpServlet {

    private final IAccountDAO dao = new AccountDAO();
    private final IPasswordResetDAO resetDAO = new PasswordResetDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        java.lang.String action = req.getParameter("action");
        if (action == null) action = "list";
        switch (action) {
            case "create-otp" -> handleCreateWithOtp(req, resp);
            case "list"   -> showList(req, resp);
            case "new"    -> showForm(req, resp, null);
            case "edit"   -> {
                int id = Integer.parseInt(req.getParameter("id"));
                showForm(req, resp, dao.findById(id));
            }
            case "toggle" -> {
                int toggleId = Integer.parseInt(req.getParameter("id"));
                Account toggleAcc = dao.findById(toggleId);
                // Bảo vệ: không cho khóa admin cuối cùng đang active
                if (toggleAcc != null && toggleAcc.getRoleId() == 1
                        && toggleAcc.isActive() && dao.countActiveAdmins() <= 1) {
                    resp.sendRedirect(req.getContextPath() + "/accounts?msg=last-admin");
                    return;
                }
                // Bảo vệ: không cho mở khóa khi TK đang trong reset flow (chờ admin set MK mới)
                if (toggleAcc != null && !toggleAcc.isActive()) {
                    PasswordResetRequest pr = resetDAO.findPendingByAccountId(toggleId);
                    if (pr == null) pr = resetDAO.findConfirmedByAccountId(toggleId);
                    if (pr != null) {
                        resp.sendRedirect(req.getContextPath() + "/accounts?msg=in-reset");
                        return;
                    }
                }
                dao.toggleActive(toggleId);
                resp.sendRedirect(req.getContextPath() + "/accounts?msg=updated");
            }
            case "view" -> {
                int id = Integer.parseInt(req.getParameter("id"));
                Account a = dao.findById(id);
                req.setAttribute("account", a);
                req.getRequestDispatcher("/WEB-INF/views/admin/account-detail.jsp").forward(req, resp);
            }
            case "delete" -> {
                // Bước 1: Chuyển vào thùng rác — KHÔNG cần OTP
                int id = Integer.parseInt(req.getParameter("id"));
                Account del = dao.findById(id);
                if (del != null && del.getRoleId() == 1 && dao.countActiveAdmins() <= 1) {
                    resp.sendRedirect(req.getContextPath() + "/accounts?msg=last-admin");
                    return;
                }
                if (del == null) { resp.sendRedirect(req.getContextPath() + "/accounts"); return; }
                dao.softDelete(id);
                AuditHelper.log(req, "Xóa tài khoản", "Account",
                        "Chuyển vào thùng rác: @" + (del.getUsername()) + " (" + del.getFullName() + ")");
                resp.sendRedirect(req.getContextPath() + "/accounts?msg=deleted");
            }
            case "restore" -> {
                int rid = Integer.parseInt(req.getParameter("id"));
                Account rAcc = dao.findById(rid);
                dao.restore(rid);
                AuditHelper.log(req, "Khôi phục tài khoản", "Account",
                        "Khôi phục từ thùng rác: @" + (rAcc != null ? rAcc.getUsername() : rid));
                resp.sendRedirect(req.getContextPath() + "/accounts?action=trash&msg=restored");
            }
            case "purge" -> {
                // Bước 1: Lưu target + hiện trang nhập "delete" trước khi gửi OTP
                int id = Integer.parseInt(req.getParameter("id"));
                Account del = dao.findById(id);
                if (del == null) { resp.sendRedirect(req.getContextPath() + "/accounts?action=trash"); return; }
                // Chỉ lưu target vào session, CHƯA gửi OTP
                req.getSession().setAttribute("deleteTargetId",   id);
                req.getSession().setAttribute("deleteTargetName",
                        del.getFullName() != null ? del.getFullName() : del.getUsername());
                // Forward sang trang nhập "delete" (Bước 1/2)
                req.setAttribute("deleteTarget", del);
                req.getRequestDispatcher("/WEB-INF/views/admin/admin-delete-confirm.jsp").forward(req, resp);
            }
            case "trash" -> {
                req.setAttribute("deletedAccounts", dao.findDeleted());
                req.getRequestDispatcher("/WEB-INF/views/admin/account-trash.jsp").forward(req, resp);
            }
            case "admin-reset-otp-page" -> {
                // Kiểm tra session còn đủ dữ liệu không
                Integer targetId = (Integer) req.getSession().getAttribute("adminResetTargetId");
                if (targetId == null) { resp.sendRedirect(req.getContextPath() + "/accounts"); return; }
                Account staffInfo = dao.findById(targetId);
                req.setAttribute("staffInfo", staffInfo);
                req.getRequestDispatcher("/WEB-INF/views/admin/admin-otp-confirm.jsp").forward(req, resp);
            }
            case "admin-set-password-page" -> {
                // Hiện trang set mật khẩu mới sau khi OTP đã verified
                Boolean otpOk = (Boolean) req.getSession().getAttribute("adminResetOtpVerified");
                Integer tid   = (Integer) req.getSession().getAttribute("adminResetTargetId");
                if (!Boolean.TRUE.equals(otpOk) || tid == null) {
                    resp.sendRedirect(req.getContextPath() + "/accounts"); return;
                }
                Account staffInfo = dao.findById(tid);
                req.setAttribute("staffInfo", staffInfo);
                req.getRequestDispatcher("/WEB-INF/views/admin/admin-set-password.jsp").forward(req, resp);
            }
            case "online-status" -> {
                resp.setContentType("application/json;charset=UTF-8");
                java.util.Set<Integer> idsSet = com.medivault.util.SessionTracker.getOnlineSet();
                java.io.PrintWriter pw = resp.getWriter();
                pw.print("{\"onlineCount\":" + idsSet.size() + ",\"onlineIds\":[");
                boolean isFirst = true;
                for (Integer oid : idsSet) {
                    if (!isFirst) pw.print(",");
                    pw.print("\"" + oid + "\"");
                    isFirst = false;
                }
                pw.print("]}");
                return;
            }
            case "delete-otp-page" -> {
                // Bước 2: admin đã nhập "delete" → gửi OTP + hiện trang nhập OTP
                Integer tid = (Integer) req.getSession().getAttribute("deleteTargetId");
                if (tid == null) { resp.sendRedirect(req.getContextPath() + "/accounts?action=trash"); return; }
                Account delTarget = dao.findById(tid);
                if (delTarget == null) { resp.sendRedirect(req.getContextPath() + "/accounts?action=trash"); return; }

                // Tạo OTP + gửi email admin
                Account adminAcc2 = (Account) req.getSession().getAttribute("adminAccount");
                String adminEmail2 = adminAcc2 != null ? adminAcc2.getEmail() : null;
                String otp2 = OtpUtil.generate(6);
                req.getSession().setAttribute("deleteOtpCode",   otp2);
                req.getSession().setAttribute("deleteOtpExpiry", System.currentTimeMillis() + 5 * 60 * 1000L);

                if (adminEmail2 != null) {
                    String staffLabel2 = (delTarget.getFullName() != null ? delTarget.getFullName() : "")
                            + " (@" + delTarget.getUsername() + ")";
                    String body2 = "<div style=\"font-family:Arial,sans-serif;max-width:500px;margin:auto;padding:24px\">"
                            + "<div style=\"background:linear-gradient(135deg,#DC2626,#991B1B);border-radius:14px;"
                            + "padding:20px 24px;margin-bottom:20px;color:#fff\">"
                            + "<h2 style=\"margin:0;font-size:18px\">🗑️ Xác nhận xóa vĩnh viễn</h2>"
                            + "<p style=\"margin:6px 0 0;opacity:.8;font-size:13px\">Thao tác KHÔNG THỂ hoàn tác!</p></div>"
                            + "<p style=\"font-size:14px;color:#0B1628\">Tài khoản bị xóa vĩnh viễn: <strong>"
                            + staffLabel2 + "</strong></p>"
                            + "<div style=\"background:#F1F5FB;border-radius:12px;padding:20px;text-align:center;margin:16px 0\">"
                            + "<div style=\"font-size:36px;font-weight:900;letter-spacing:10px;color:#DC2626\">" + otp2 + "</div>"
                            + "<p style=\"font-size:12px;color:#7A90B0;margin-top:8px\">Hiệu lực 5 phút</p></div>"
                            + "<p style=\"font-size:12px;color:#999\">Nếu không phải bạn, bỏ qua email này.</p></div>";
                    EmailUtil.sendEmail(adminEmail2,
                            "[MediVault] ⚠️ OTP xóa vĩnh viễn @" + delTarget.getUsername(), body2);
                }

                req.setAttribute("deleteTarget", delTarget);
                req.getRequestDispatcher("/WEB-INF/views/admin/admin-delete-otp.jsp").forward(req, resp);
            }
            default -> showList(req, resp);
        }
    }



    private void handleCreateWithOtp(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String username  = req.getParameter("username");
        String fullName  = req.getParameter("fullName");
        String email     = req.getParameter("email");
        String phone     = req.getParameter("phone");
        String citizenId = req.getParameter("citizenId");
        String position  = req.getParameter("position");
        String password  = req.getParameter("password");
        String roleStr   = req.getParameter("roleId");

        List<String> errors = ValidationUtil.validateAccount(
                username, fullName, email, phone, citizenId, position);
        if (!ValidationUtil.isValidPassword(password))
            errors.add("Mật khẩu phải có ít nhất 6 ký tự.");
        if (ValidationUtil.notBlank(username) && dao.isUsernameTaken(username))
            errors.add("Tên đăng nhập '" + username + "' đã tồn tại.");
        if (ValidationUtil.notBlank(email) && dao.isEmailTaken(email, -1))
            errors.add("Email '" + email + "' đã được dùng.");

        if (!errors.isEmpty()) {
            // Giữ lại toàn bộ form data đã nhập → account-form.jsp dùng để pre-populate
            Account draft = new Account();
            draft.setUsername(username != null ? username : "");
            draft.setFullName(fullName != null ? fullName : "");
            draft.setEmail(email != null ? email : "");
            draft.setPhone(phone != null ? phone : "");
            draft.setCitizenId(citizenId != null ? citizenId : "");
            draft.setPosition(position != null ? position : "");
            draft.setRoleId(roleStr != null ? Integer.parseInt(roleStr) : 2);
            // Không set passwordHash (không re-populate password vì bảo mật)
            req.setAttribute("account", draft);  // JSP dùng để fill lại form
            req.setAttribute("errors", errors);
            req.setAttribute("errorMsg", ValidationUtil.joinErrors(errors));
            req.getRequestDispatcher("/WEB-INF/views/admin/account-form.jsp").forward(req, resp);
            return;
        }

        // Build pending account — chưa save DB
        Account pending = new Account();
        pending.setUsername(username.trim());
        pending.setFullName(fullName.trim());
        pending.setEmail(email != null ? email.trim() : null);
        pending.setPhone(phone != null ? phone.trim() : null);
        pending.setCitizenId(citizenId != null ? citizenId.trim() : null);
        pending.setPosition(position != null ? position.trim() : null);
        pending.setRoleId(Integer.parseInt(roleStr));
        pending.setPasswordHash(PasswordUtil.hashPassword(password));

        String otp = OtpUtil.generate(6);
        HttpSession session = req.getSession();
        session.setAttribute("pendingNewAccount", pending);
        session.setAttribute("newAccOtpCode",     otp);
        session.setAttribute("newAccOtpExpiry",   System.currentTimeMillis() + 5 * 60 * 1000L);

        try {
            EmailUtil.sendEmail(email,
                    "[MediVault] Mã xác nhận tài khoản",
                    "Mã OTP của bạn là: " + otp + "\nHiệu lực 5 phút.");
            resp.sendRedirect(req.getContextPath() + "/otp-verify");
        } catch (Exception e) {
            req.setAttribute("error", "Không gửi được email OTP!");
            req.getRequestDispatcher("/WEB-INF/views/admin/account-form.jsp").forward(req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        String action = req.getParameter("action");
        if ("create-otp".equals(action)) {
            handleCreateWithOtp(req, resp);
            return;
        }
        // ── Admin gửi lại OTP (resend) ──
        if ("admin-reset-otp-resend".equals(action)) {
            handleAdminResetOtpResend(req, resp); return;
        }
        if ("delete-otp".equals(action)) {
            handleDeleteOtp(req, resp); return;
        }
        if ("delete-otp-resend".equals(action)) {
            handleDeleteOtpResend(req, resp); return;
        }
        // ── Admin gửi OTP để xác nhận đặt lại mật khẩu cho staff ──
        if ("admin-reset-otp".equals(action)) {
            handleAdminResetOtp(req, resp); return;
        }
        // ── Admin xác nhận OTP + set mật khẩu mới ──
        if ("admin-set-password".equals(action)) {
            handleAdminSetPassword(req, resp); return;
        }
        // ── AJAX: Gửi OTP xác nhận thay đổi email/phone ──
        if ("send-otp".equals(action)) {
            handleSendUpdateOtp(req, resp);
            return;
        }
        // ── AJAX: Xác minh OTP inline ──
        if ("verify-otp".equals(action)) {
            handleVerifyUpdateOtp(req, resp);
            return;
        }

        java.lang.String idStr    = req.getParameter("accountId");
        java.lang.String username = req.getParameter("username");
        java.lang.String fullName = req.getParameter("fullName");
        java.lang.String email    = req.getParameter("email");
        java.lang.String phone    = req.getParameter("phone");
        java.lang.String citizenId= req.getParameter("citizenId");
        java.lang.String position = req.getParameter("position");
        java.lang.String password    = req.getParameter("password");
        java.lang.String oldPassword = req.getParameter("oldPassword");
        java.lang.String roleStr     = req.getParameter("roleId");
        java.lang.String certNo      = req.getParameter("professionalCertNo");
        java.lang.String certExpStr  = req.getParameter("professionalCertExp");
        java.lang.String trainingStr = req.getParameter("trainingDate");

        boolean isNew = (idStr == null || idStr.isEmpty());

        // ── BƯỚC 1: Validate format ──────────────────────────────
        // Khi edit: username readonly không đổi được, bỏ qua validate username
        List<String> errors;
        if (isNew) {
            errors = new java.util.ArrayList<>(ValidationUtil.validateAccount(
                    username, fullName, email, phone, citizenId, position));
            if (!ValidationUtil.isValidPassword(password))
                errors.add("Mật khẩu phải có ít nhất 6 ký tự.");
        } else {
            errors = new java.util.ArrayList<>(ValidationUtil.validateAccount(
                    "skip", fullName, email, phone, citizenId, position));
            errors.removeIf(e -> e.toLowerCase().contains("tên đăng nhập"));
        }

        // ── BƯỚC 2: Validate trùng lặp ──────────────────────────
        Account current = null;
        boolean emailChanged = false, phoneChanged = false;
        if (isNew) {
            // Tạo mới: check username + email luôn
            if (ValidationUtil.notBlank(username) && dao.isUsernameTaken(username))
                errors.add("Tên đăng nhập '" + username + "' đã tồn tại.");
            if (ValidationUtil.notBlank(email) && dao.isEmailTaken(email, -1))
                errors.add("Email '" + email + "' đã được dùng bởi tài khoản khác.");
        } else {
            // Edit: chỉ query DB nếu email/phone THỰC SỰ thay đổi so với giá trị cũ
            current = dao.findById(Integer.parseInt(idStr));
            if (current != null) {
                emailChanged = ValidationUtil.notBlank(email)
                        && !email.trim().equals(current.getEmail() != null ? current.getEmail() : "");
                phoneChanged = ValidationUtil.notBlank(phone)
                        && !phone.trim().equals(current.getPhone() != null ? current.getPhone() : "");

                if (emailChanged && dao.isEmailTaken(email, Integer.parseInt(idStr)))
                    errors.add("Email '" + email + "' đã được dùng bởi tài khoản khác.");
                // phone chưa có isPhoneTaken trong DAO — bỏ qua hoặc thêm sau
            }
        }
        // ── BƯỚC 3: Nếu có lỗi → GỬI LẠI FORM + GIỮ DỮ LIỆU ──
        if (!errors.isEmpty()) {
            req.setAttribute("errors", errors);     // list lỗi → JSP lặp hiển thị
            req.setAttribute("errorMsg", ValidationUtil.joinErrors(errors));

            // GIỮ LẠI GIÁ TRỊ NGƯỜI DÙNG ĐÃ NHẬP — quan trọng!
            Account draft = new Account();
            if (!isNew) draft.setAccountId(Integer.parseInt(idStr));
            draft.setUsername(username);
            draft.setFullName(fullName);
            draft.setEmail(email);
            draft.setPhone(phone);
            draft.setCitizenId(citizenId);
            draft.setPosition(position);
            if (ValidationUtil.notBlank(roleStr)) draft.setRoleId(Integer.parseInt(roleStr));

            req.setAttribute("account", draft);     // JSP dùng để pre-fill form
            req.getRequestDispatcher("/WEB-INF/views/admin/account-form.jsp").forward(req, resp);
            return;
        }

        // ── BƯỚC 4: Dữ liệu hợp lệ → Lưu DB ────────────────────
        Account a = new Account();
        if (isNew) {
            a.setUsername(username != null ? username.trim() : "");
        } else {
            // Khi edit: lấy username hiện tại từ DB, không cho thay đổi
            a.setUsername(current != null ? current.getUsername() : (username != null ? username.trim() : ""));
        }
        a.setFullName(fullName.trim());
        a.setEmail(email != null ? email.trim() : null);
        a.setPhone(phone != null ? phone.trim() : null);
        a.setCitizenId(citizenId != null ? citizenId.trim() : null);
        a.setPosition(position != null ? position.trim() : null);
        a.setRoleId(Integer.parseInt(roleStr));



        if (isNew) {
            a.setPasswordHash(PasswordUtil.hashPassword(password));
            dao.insert(a);
            resp.sendRedirect(req.getContextPath() + "/accounts?msg=created");
        } else {
            int editId = Integer.parseInt(idStr);
            a.setAccountId(editId);

            // ── Thông tin chuyên môn ──
            if (ValidationUtil.notBlank(certNo)) a.setProfessionalCertNo(certNo.trim());
            try { if (ValidationUtil.notBlank(certExpStr))
                a.setProfessionalCertExp(LocalDate.parse(certExpStr)); } catch (Exception ignored) {}
            try { if (ValidationUtil.notBlank(trainingStr))
                a.setTrainingDate(LocalDate.parse(trainingStr)); } catch (Exception ignored) {}

            // ── No-change detection ──
            boolean nothingChanged = current != null
                    && eq(fullName, current.getFullName())
                    && eq(email, current.getEmail())
                    && eq(phone, current.getPhone())
                    && eq(citizenId, current.getCitizenId())
                    && eq(position, current.getPosition())
                    && a.getRoleId() == current.getRoleId()
                    && eq(certNo, current.getProfessionalCertNo())
                    && eq(certExpStr, current.getProfessionalCertExp() != null ? current.getProfessionalCertExp().toString() : "")
                    && eq(trainingStr, current.getTrainingDate() != null ? current.getTrainingDate().toString() : "")
                    && !ValidationUtil.notBlank(password);

            if (nothingChanged) {
                resp.sendRedirect(req.getContextPath() + "/accounts?msg=nochange");
                return;
            }


            // Nếu JS đã verify OTP inline → bỏ qua, tiếp tục lưu
            String otpVerifiedFlag = req.getParameter("otpVerified");
            boolean otpAlreadyDone = "true".equals(otpVerifiedFlag);

            if (!otpAlreadyDone && (emailChanged || phoneChanged)) {
                // Trường hợp JS bị tắt hoặc bypass → vẫn an toàn
                req.setAttribute("errors", java.util.List.of(
                        "Email/SĐT thay đổi cần xác nhận OTP. Vui lòng dùng trình duyệt hỗ trợ JavaScript."));
                req.setAttribute("account", a);
                req.getRequestDispatcher("/WEB-INF/views/admin/account-form.jsp").forward(req, resp);
                return;
            }

            // ── Đổi mật khẩu: kiểm tra staff có pending reset không ──
            if (ValidationUtil.notBlank(password) && ValidationUtil.isValidPassword(password)) {
                // Lấy account admin hiện tại
                Account adminAcc = (Account) req.getSession().getAttribute("adminAccount");
                String adminEmail = adminAcc != null ? adminAcc.getEmail() : null;

                // Kiểm tra staff có pending reset request không
                PasswordResetRequest pendingReset = resetDAO.findPendingByAccountId(editId);
                if (pendingReset == null) pendingReset = resetDAO.findConfirmedByAccountId(editId);
                boolean isResetFlow = (pendingReset != null);

                // Lưu thông tin tạm vào session để dùng sau OTP
                HttpSession sess = req.getSession();
                sess.setAttribute("adminResetTargetId",       editId);
                sess.setAttribute("adminResetNewPassword",    password);
                sess.setAttribute("adminResetIsResetFlow",    isResetFlow);

                // Tạo OTP + gửi về GMAIL ADMIN
                String otp = OtpUtil.generate(6);
                sess.setAttribute("adminResetOtpCode",   otp);
                sess.setAttribute("adminResetOtpExpiry", System.currentTimeMillis() + 5 * 60 * 1000L);

                String staffName = current != null ? current.getFullName() : "@" + String.valueOf(editId);
                String otpEmailBody = "<div style=\"font-family:Arial,sans-serif;max-width:500px;margin:auto;padding:24px\">"
                        + "<div style=\"background:linear-gradient(135deg,#1558A8,#0D3F85);border-radius:14px;"
                        + "padding:20px 24px;margin-bottom:20px;color:#fff\">"
                        + "<h2 style=\"margin:0;font-size:18px\">🔐 Xác nhận đặt lại mật khẩu</h2>"
                        + "<p style=\"margin:6px 0 0;opacity:.8;font-size:13px\">Nhập mã bên dưới để xác nhận</p></div>"
                        + "<p style=\"font-size:14px;color:#0B1628\">Bạn vừa yêu cầu đặt lại mật khẩu cho nhân viên "
                        + "<strong>" + staffName + "</strong>.</p>"
                        + "<div style=\"background:#F1F5FB;border-radius:12px;padding:20px;text-align:center;margin:20px 0\">"
                        + "<div style=\"font-size:36px;font-weight:900;letter-spacing:10px;color:#1558A8\">" + otp + "</div>"
                        + "<p style=\"font-size:12px;color:#7A90B0;margin-top:8px\">Hiệu lực 5 phút</p></div>"
                        + "<p style=\"font-size:12px;color:#999\">Nếu không phải bạn thực hiện, bỏ qua email này.</p></div>";

                if (adminEmail != null) {
                    EmailUtil.sendEmail(adminEmail, "[MediVault] OTP xác nhận đặt lại mật khẩu — " + staffName, otpEmailBody);
                }

                // Redirect sang trang OTP xác nhận của admin
                resp.sendRedirect(req.getContextPath() + "/accounts?action=admin-reset-otp-page");
                return;
            }

            // Bảo vệ: không cho đổi role admin cuối cùng thành non-admin
            if (current != null && current.getRoleId() == 1
                    && a.getRoleId() != 1 && dao.countActiveAdmins() <= 1) {
                req.setAttribute("errors", java.util.List.of(
                        "Không thể thay đổi role — đây là tài khoản Admin duy nhất đang hoạt động!"));
                req.setAttribute("account", a);
                req.getRequestDispatcher("/WEB-INF/views/admin/account-form.jsp").forward(req, resp);
                return;
            }

            boolean saved = dao.update(a);
            if (!saved) {
                req.setAttribute("errors", java.util.List.of("Lưu thất bại — kiểm tra log Tomcat!"));
                req.setAttribute("account", a);
                req.getRequestDispatcher("/WEB-INF/views/admin/account-form.jsp").forward(req, resp);
                return;
            }
            resp.sendRedirect(req.getContextPath() + "/accounts?msg=updated");
        }
    }

    /** So sánh 2 string null-safe, trim cả 2 trước khi so sánh */
    private static boolean eq(String formVal, String dbVal) {
        String a = formVal != null ? formVal.trim() : "";
        String b = dbVal   != null ? dbVal.trim()   : "";
        return a.equals(b);
    }

    // ── AJAX: Gửi OTP xác nhận đổi email/phone ──────────────────────
    private void handleSendUpdateOtp(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        try {
            String newEmail = req.getParameter("email");
            String newPhone = req.getParameter("phone");
            String idStr    = req.getParameter("accountId");
            if (idStr == null || idStr.isEmpty()) {
                out.print(json(false, "Thiếu accountId")); return;
            }

            int editId = Integer.parseInt(idStr);
            Account current = dao.findById(editId);
            String origEmail = current != null && current.getEmail() != null ? current.getEmail() : "";
            String origPhone = current != null && current.getPhone() != null ? current.getPhone() : "";
            newEmail = newEmail != null ? newEmail.trim() : "";
            newPhone = newPhone != null ? newPhone.trim() : "";

            boolean emailChanged = !newEmail.equals(origEmail);
            boolean phoneChanged = !newPhone.equals(origPhone);
            String sendTo = emailChanged ? newEmail : origEmail;

            if (!ValidationUtil.notBlank(sendTo)) {
                out.print(json(false, "Không có email để gửi")); return;
            }

            String otp = OtpUtil.generate(6);
            HttpSession sess = req.getSession();
            sess.setAttribute("inlineOtpCode",   otp);
            sess.setAttribute("inlineOtpExpiry",  System.currentTimeMillis() + 5 * 60 * 1000L);
            sess.setAttribute("inlineOtpAccId",   editId);

            String what = emailChanged && phoneChanged ? "email và số điện thoại"
                    : emailChanged ? "email" : "số điện thoại";
            EmailUtil.sendEmail(sendTo,
                    "[MediVault] Mã OTP xác nhận thay đổi thông tin",
                    "Mã OTP xác nhận thay đổi " + what + " tài khoản @"
                            + (current != null ? current.getUsername() : "") + ": " + otp
                            + "\nHiệu lực 5 phút.");
            out.print(json(true, null));
        } catch (Exception e) {
            e.printStackTrace();
            out.print(json(false, e.getMessage() != null ? e.getMessage() : "Lỗi hệ thống"));
        }
    }

    // ── AJAX: Xác minh OTP inline ────────────────────────────────────
    private void handleVerifyUpdateOtp(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        HttpSession sess = req.getSession(false);
        if (sess == null) { out.print(json(false, "Session hết hạn")); return; }

        String inputOtp = req.getParameter("otpCode");
        String savedOtp = (String) sess.getAttribute("inlineOtpCode");
        Long   expiry   = (Long)   sess.getAttribute("inlineOtpExpiry");

        if (expiry == null || System.currentTimeMillis() > expiry) {
            sess.removeAttribute("inlineOtpCode");
            out.print(json(false, "OTP đã hết hạn, vui lòng gửi lại"));
            return;
        }
        if (savedOtp == null || !savedOtp.equals(inputOtp)) {
            out.print(json(false, "Mã OTP không đúng"));
            return;
        }

        sess.removeAttribute("inlineOtpCode");
        sess.removeAttribute("inlineOtpExpiry");
        sess.removeAttribute("inlineOtpAccId");
        out.print(json(true, null));
    }

    private static String json(boolean ok, String msg) {
        if (msg == null) return "{\"ok\":true}";
        String safe = msg.replace("\\", "\\\\").replace("\"", "\\\"");
        return "{\"ok\":" + ok + ",\"msg\":\"" + safe + "\"}";
    }

    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setAttribute("accounts", dao.findAllStaff());
        req.setAttribute("onlineStaff", com.medivault.util.SessionTracker.getOnlineSet());
        req.getRequestDispatcher("/WEB-INF/views/admin/account-list.jsp").forward(req, resp);
    }

    private void showForm(HttpServletRequest req, HttpServletResponse resp, Account account)
            throws ServletException, IOException {
        req.setAttribute("account", account);
        req.getRequestDispatcher("/WEB-INF/views/admin/account-form.jsp").forward(req, resp);
    }

    // ── Trang OTP xác nhận đặt lại mật khẩu (GET) ──────────────────
    // Được gọi từ doGet khi action=admin-reset-otp-page
    // (Thêm vào doGet case)

    // ── Xử lý admin nhập OTP xác nhận đặt lại mk (POST action=admin-reset-otp) ──
    private void handleAdminResetOtp(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");
        java.io.PrintWriter out = resp.getWriter();
        HttpSession sess = req.getSession(false);
        if (sess == null) { out.print(json(false, "Session hết hạn!")); return; }

        String inputOtp  = req.getParameter("otp");
        String storedOtp = (String)  sess.getAttribute("adminResetOtpCode");
        Long   expiry    = (Long)    sess.getAttribute("adminResetOtpExpiry");

        if (storedOtp == null || expiry == null) {
            out.print(json(false, "OTP đã hết hạn hoặc không hợp lệ!")); return;
        }
        if (System.currentTimeMillis() > expiry) {
            sess.removeAttribute("adminResetOtpCode");
            out.print(json(false, "OTP đã hết hạn! Vui lòng thử lại.")); return;
        }
        if (!storedOtp.equals(inputOtp != null ? inputOtp.trim() : "")) {
            out.print(json(false, "Mã OTP không đúng!")); return;
        }

        // OTP đúng → xóa otp, đánh dấu verified
        sess.removeAttribute("adminResetOtpCode");
        sess.removeAttribute("adminResetOtpExpiry");
        sess.setAttribute("adminResetOtpVerified", true);

        out.print(json(true, "OK"));
    }

    // ── Xử lý admin submit mật khẩu mới (POST action=admin-set-password) ──
    private void handleAdminSetPassword(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        HttpSession sess = req.getSession(false);

        // Kiểm tra OTP đã verified chưa
        Boolean verified = (Boolean) (sess != null ? sess.getAttribute("adminResetOtpVerified") : null);
        if (!Boolean.TRUE.equals(verified)) {
            req.setAttribute("errors", java.util.List.of("Phiên xác nhận OTP không hợp lệ. Vui lòng thử lại."));
            resp.sendRedirect(req.getContextPath() + "/accounts");
            return;
        }

        Integer targetId    = (Integer) sess.getAttribute("adminResetTargetId");
        Boolean isResetFlow = (Boolean) sess.getAttribute("adminResetIsResetFlow");
        String newPassword  = req.getParameter("newPassword");
        String confirmPw    = req.getParameter("confirmPassword");

        if (targetId == null) {
            resp.sendRedirect(req.getContextPath() + "/accounts");
            return;
        }

        Account staff = dao.findById(targetId);
        if (staff == null) {
            resp.sendRedirect(req.getContextPath() + "/accounts?msg=error");
            return;
        }

        // Validate mật khẩu
        if (!ValidationUtil.notBlank(newPassword) || !ValidationUtil.isValidPassword(newPassword)) {
            req.setAttribute("staffInfo", staff);
            req.setAttribute("error", "Mật khẩu phải có ít nhất 6 ký tự!");
            req.getRequestDispatcher("/WEB-INF/views/admin/admin-set-password.jsp").forward(req, resp);
            return;
        }
        if (!newPassword.equals(confirmPw)) {
            req.setAttribute("staffInfo", staff);
            req.setAttribute("error", "Mật khẩu xác nhận không khớp!");
            req.getRequestDispatcher("/WEB-INF/views/admin/admin-set-password.jsp").forward(req, resp);
            return;
        }

        // Đặt mật khẩu mới
        dao.resetPassword(targetId, PasswordUtil.hashPassword(newPassword));
        AuditHelper.log(req, "Đặt lại mật khẩu", "Account",
                "Admin đặt mật khẩu mới cho @" + staff.getUsername()
                        + (Boolean.TRUE.equals(isResetFlow) ? " (theo yêu cầu staff)" : " (chủ động)"));

        // Hoàn tất reset request (nếu có) — xóa khỏi chuông thông báo
        resetDAO.complete(targetId);

        // Nếu là reset flow: mở khóa tài khoản
        if (Boolean.TRUE.equals(isResetFlow)) {
            if (!staff.isActive()) {
                dao.toggleActive(targetId);
            }
        }

        // Gửi email thông báo cho staff — kèm mật khẩu mới
        String staffEmail = staff.getEmail();
        if (staffEmail != null && !staffEmail.isEmpty()) {
            String emailHtml = "<div style=\"font-family:Arial,sans-serif;max-width:520px;margin:auto;padding:24px\">"
                    + "<div style=\"background:linear-gradient(135deg,#059669,#047857);border-radius:14px;"
                    + "padding:20px 24px;margin-bottom:20px;color:#fff\">"
                    + "<h2 style=\"margin:0;font-size:18px\">✅ Mật khẩu đã được cập nhật!</h2>"
                    + (Boolean.TRUE.equals(isResetFlow)
                    ? "<p style=\"margin:6px 0 0;opacity:.8;font-size:13px\">Tài khoản của bạn đã được mở khóa</p>"
                    : "<p style=\"margin:6px 0 0;opacity:.8;font-size:13px\">Admin vừa đặt lại mật khẩu cho bạn</p>")
                    + "</div>"
                    + "<p style=\"font-size:14px;color:#1C0F3F\">Xin chào <strong>" + staff.getFullName() + "</strong>,</p>"
                    + "<p style=\"font-size:13.5px;color:#374151;line-height:1.7\">"
                    + "Mật khẩu tài khoản <strong>@" + staff.getUsername() + "</strong> đã được đặt lại thành công."
                    + (Boolean.TRUE.equals(isResetFlow) ? " Tài khoản của bạn đã được <strong>mở khóa</strong> và bạn có thể đăng nhập lại ngay." : "")
                    + "</p>"
                    // ── Hiện mật khẩu mới rõ ràng ──
                    + "<div style=\"background:#F0FDF4;border:2px solid #86EFAC;border-radius:12px;padding:18px 20px;margin:18px 0;\">"
                    + "<p style=\"margin:0 0 8px;font-size:12px;font-weight:700;color:#15803D;letter-spacing:1px;text-transform:uppercase\">🔑 Mật khẩu mới của bạn</p>"
                    + "<div style=\"font-size:22px;font-weight:900;color:#166534;letter-spacing:3px;font-family:monospace;background:#fff;"
                    + "border:1px solid #86EFAC;border-radius:8px;padding:10px 16px;display:inline-block\">"
                    + newPassword
                    + "</div>"
                    + "<p style=\"margin:10px 0 0;font-size:12px;color:#D97706;font-weight:600\">"
                    + "⚠️ Vui lòng <strong>không chia sẻ mật khẩu này</strong> với bất kỳ ai!</p>"
                    + "<p style=\"margin:6px 0 0;font-size:12px;color:#6B7280\">"
                    + "💡 Khuyến nghị: Đổi mật khẩu ngay sau khi đăng nhập lần đầu.</p>"
                    + "</div>"
                    + "<p style=\"font-size:12px;color:#999\">Nếu bạn không yêu cầu điều này, hãy liên hệ Admin ngay lập tức.</p>"
                    + "</div>";
            EmailUtil.sendEmail(staffEmail,
                    "[MediVault] ✅ Tài khoản @" + staff.getUsername() + " đã được mở khóa — Mật khẩu mới",
                    emailHtml);
        }

        // Xóa session tạm
        sess.removeAttribute("adminResetOtpVerified");
        sess.removeAttribute("adminResetTargetId");
        sess.removeAttribute("adminResetNewPassword");
        sess.removeAttribute("adminResetIsResetFlow");

        String staffName = staff.getFullName() != null ? staff.getFullName() : staff.getUsername();
        resp.sendRedirect(req.getContextPath() + "/accounts?msg=unlocked&name="
                + java.net.URLEncoder.encode(staffName, "UTF-8"));
    }


    // ── Gửi lại OTP (resend) ──────────────────────────────────────────
    private void handleAdminResetOtpResend(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        java.io.PrintWriter out = resp.getWriter();
        HttpSession sess = req.getSession(false);
        if (sess == null) { resp.setStatus(400); return; }

        Integer targetId = (Integer) sess.getAttribute("adminResetTargetId");
        if (targetId == null) { resp.setStatus(400); return; }

        Account admin  = (Account) sess.getAttribute("adminAccount");
        Account staff  = dao.findById(targetId);
        if (admin == null || staff == null) { resp.setStatus(400); return; }

        String otp = OtpUtil.generate(6);
        sess.setAttribute("adminResetOtpCode",   otp);
        sess.setAttribute("adminResetOtpExpiry", System.currentTimeMillis() + 5 * 60 * 1000L);

        String staffName  = staff.getFullName() != null ? staff.getFullName() : "@" + staff.getUsername();
        String adminEmail = admin.getEmail();
        if (adminEmail != null) {
            String body = "<div style=\"font-family:Arial,sans-serif;max-width:500px;margin:auto;padding:24px\">"
                    + "<h2 style=\"color:#1558A8\">🔐 OTP mới — Đặt lại mật khẩu</h2>"
                    + "<p>Nhân viên: <strong>" + staffName + "</strong></p>"
                    + "<div style=\"background:#F1F5FB;border-radius:12px;padding:20px;text-align:center;margin:16px 0\">"
                    + "<div style=\"font-size:36px;font-weight:900;letter-spacing:10px;color:#1558A8\">" + otp + "</div>"
                    + "<p style=\"font-size:12px;color:#7A90B0;margin-top:8px\">Hiệu lực 5 phút</p></div></div>";
            EmailUtil.sendEmail(adminEmail, "[MediVault] OTP mới — " + staffName, body);
        }
        out.print(json(true, null));
    }

    private void handleDeleteOtp(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        HttpSession sess = req.getSession(false);
        if (sess == null) { resp.sendRedirect(req.getContextPath() + "/accounts"); return; }

        String  inputOtp  = req.getParameter("otp");
        String  storedOtp = (String)  sess.getAttribute("deleteOtpCode");
        Long    expiry    = (Long)    sess.getAttribute("deleteOtpExpiry");
        Integer targetId  = (Integer) sess.getAttribute("deleteTargetId");

        if (storedOtp == null || expiry == null || targetId == null) {
            req.setAttribute("deleteError", "Phiên xác nhận đã hết hạn!");
            req.setAttribute("deleteTarget", dao.findById(targetId != null ? targetId : -1));
            req.getRequestDispatcher("/WEB-INF/views/admin/admin-delete-otp.jsp").forward(req, resp);
            return;
        }
        if (System.currentTimeMillis() > expiry) {
            sess.removeAttribute("deleteOtpCode");
            sess.removeAttribute("deleteOtpExpiry");
            sess.removeAttribute("deleteTargetId");
            sess.removeAttribute("deleteTargetName");
            resp.sendRedirect(req.getContextPath() + "/accounts?msg=otp-expired");
            return;
        }
        if (!storedOtp.equals(inputOtp != null ? inputOtp.trim() : "")) {
            req.setAttribute("deleteTarget", dao.findById(targetId));
            req.setAttribute("deleteError", "❌ Mã OTP không đúng! Vui lòng thử lại.");
            req.getRequestDispatcher("/WEB-INF/views/admin/admin-delete-otp.jsp").forward(req, resp);
            return;
        }

        // OTP đúng → forceDelete vĩnh viễn (xử lý FK + xóa hẳn)
        Account del = dao.findById(targetId);
        String delName = (String) sess.getAttribute("deleteTargetName");
        if (del != null && del.getRoleId() == 1 && dao.countActiveAdmins() <= 1) {
            resp.sendRedirect(req.getContextPath() + "/accounts?msg=last-admin");
        } else {
            dao.forceDelete(targetId);
            AuditHelper.log(req, "Xóa vĩnh viễn tài khoản", "Account",
                    "Xóa vĩnh viễn (OTP xác nhận): " + (delName != null ? delName : String.valueOf(targetId)));
            sess.removeAttribute("deleteOtpCode");
            sess.removeAttribute("deleteOtpExpiry");
            sess.removeAttribute("deleteTargetId");
            sess.removeAttribute("deleteTargetName");
            sess.removeAttribute("deleteFromTrash");
            resp.sendRedirect(req.getContextPath() + "/accounts?action=trash&msg=purged");
        }
    }

    private void handleDeleteOtpResend(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        HttpSession sess = req.getSession(false);
        if (sess == null) { resp.setStatus(400); return; }

        Integer targetId = (Integer) sess.getAttribute("deleteTargetId");
        Account admin    = (Account) sess.getAttribute("adminAccount");
        if (targetId == null || admin == null) { resp.setStatus(400); return; }

        Account del = dao.findById(targetId);
        if (del == null) { resp.setStatus(400); return; }

        String otp = OtpUtil.generate(6);
        sess.setAttribute("deleteOtpCode",   otp);
        sess.setAttribute("deleteOtpExpiry", System.currentTimeMillis() + 5 * 60 * 1000L);

        String adminEmail = admin.getEmail();
        if (adminEmail != null) {
            String staffLabel = (del.getFullName() != null ? del.getFullName() : "")
                    + " (@" + del.getUsername() + ")";
            String body = "<div style=\"font-family:Arial,sans-serif;max-width:500px;margin:auto;padding:24px\">"
                    + "<h2 style=\"color:#DC2626\">🗑️ OTP mới — Xác nhận xóa</h2>"
                    + "<p>Tài khoản: <strong>" + staffLabel + "</strong></p>"
                    + "<div style=\"background:#F1F5FB;border-radius:12px;padding:20px;text-align:center;margin:16px 0\">"
                    + "<div style=\"font-size:36px;font-weight:900;letter-spacing:10px;color:#DC2626\">" + otp + "</div>"
                    + "<p style=\"font-size:12px;color:#7A90B0;margin-top:8px\">Hiệu lực 5 phút</p></div></div>";
            EmailUtil.sendEmail(adminEmail,
                    "[MediVault] OTP mới — Xóa @" + del.getUsername(), body);
        }
        resp.getWriter().print(json(true, null));
    }


}