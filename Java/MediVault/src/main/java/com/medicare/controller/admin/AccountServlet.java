package com.medicare.controller.admin;

import com.medicare.dao.AccountDAO;
import com.medicare.dao.PasswordResetDAO;
import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.dao.interfaces.IPasswordResetDAO;
import com.medicare.entity.PasswordResetRequest;
import com.medicare.entity.Account;
import com.medicare.service.AccountService;
import com.medicare.service.ServiceResult;
import com.medicare.service.interfaces.IAccountService;
import com.medicare.util.PasswordUtil;
import com.medicare.util.ValidationUtil;
import com.medicare.util.AuditHelper;
import com.medicare.util.StaffNotifHelper;
import com.medicare.util.SidebarHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import com.medicare.util.EmailUtil;
import com.medicare.util.OtpUtil;
import jakarta.servlet.http.HttpSession;
import java.util.List;

import java.io.IOException;
import java.io.PrintWriter;


@WebServlet("/accounts")
public class AccountServlet extends HttpServlet {

    private final IAccountDAO      dao             = new AccountDAO();
    private final IPasswordResetDAO resetDAO        = new PasswordResetDAO();
    private final IAccountService  accountService  = new AccountService();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        java.lang.String action = req.getParameter("action");
        if (action == null) action = "list";
        switch (action) {
            case "list"   -> showList(req, resp);
            case "new"    -> showForm(req, resp, null);
            case "edit"   -> {
                int id = Integer.parseInt(req.getParameter("id"));
                showForm(req, resp, dao.findById(id));
            }
            case "toggle" -> {
                int toggleId = Integer.parseInt(req.getParameter("id"));
                Account toggleAcc = dao.findById(toggleId);
                // Bảo vệ: không cho khóa/xóa tài khoản admin gốc (ID=1)
                if (toggleId == 1) {
                    resp.sendRedirect(req.getContextPath() + "/accounts?msg=protected-admin");
                    return;
                }
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
                SidebarHelper.load(req);

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
            case "trash" -> {
                req.setAttribute("deletedAccounts", dao.findDeleted());
                SidebarHelper.load(req);

                req.getRequestDispatcher("/WEB-INF/views/admin/account-trash.jsp").forward(req, resp);
            }
            case "admin-reset-otp-page" -> {
                // Kiểm tra session còn đủ dữ liệu không
                Integer targetId = (Integer) req.getSession().getAttribute("adminResetTargetId");
                if (targetId == null) { resp.sendRedirect(req.getContextPath() + "/accounts"); return; }
                Account staffInfo = dao.findById(targetId);
                req.setAttribute("staffInfo", staffInfo);
                SidebarHelper.load(req);

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
                SidebarHelper.load(req);

                req.getRequestDispatcher("/WEB-INF/views/admin/admin-set-password.jsp").forward(req, resp);
            }
            case "online-status" -> {
                resp.setContentType("application/json;charset=UTF-8");
                // Presence tracking: dùng LastActiveAt (3 phút) thay vì in-memory set
                // → loại bỏ Ghost Online 30 phút khi tab crash/mất mạng
                java.util.List<Integer> onlineList = dao.findOnlineAccountIds(3);
                java.io.PrintWriter pw = resp.getWriter();
                pw.print("{\"onlineCount\":" + onlineList.size() + ",\"onlineIds\":[");
                for (int i = 0; i < onlineList.size(); i++) {
                    if (i > 0) pw.print(",");
                    pw.print("\"" + onlineList.get(i) + "\"");
                }
                pw.print("]}");
                return;
            }
            default -> showList(req, resp);
        }
    }



    // ── Tạo tài khoản trực tiếp — Admin tự cấp, không cần OTP ──────────
    private void handleCreate(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String username  = req.getParameter("username");
        String fullName  = req.getParameter("fullName");
        String email     = req.getParameter("email");
        String phone     = req.getParameter("phone");
        String citizenId = req.getParameter("citizenId");
        String position  = req.getParameter("position");
        String password  = req.getParameter("password");
        String roleStr   = req.getParameter("roleId");
        int roleId = 2;
        try { roleId = Integer.parseInt(roleStr); } catch (Exception ignored) {}

        ServiceResult<Account> result = accountService.createAccount(
                username, fullName, email, phone, citizenId, position, roleId, password);

        if (result.isFail()) {
            Account draft = new Account();
            List<String> errors = result.hasErrors() ? result.getErrors() : List.of(result.getMessage());
            boolean usernameErr = errors.stream().anyMatch(e -> e.contains("Tên đăng nhập"));
            draft.setUsername(usernameErr ? "" : (username != null ? username : ""));
            draft.setFullName(fullName != null ? fullName : "");
            draft.setEmail(email != null ? email : "");
            draft.setPhone(phone != null ? phone : "");
            draft.setCitizenId(citizenId != null ? citizenId : "");
            draft.setPosition(position != null ? position : "");
            draft.setRoleId(roleId);
            req.setAttribute("account", draft);
            req.setAttribute("errors", errors);
            req.setAttribute("errorMsg", ValidationUtil.joinErrors(errors));
            SidebarHelper.load(req);
            req.getRequestDispatcher("/WEB-INF/views/admin/account-form.jsp").forward(req, resp);
            return;
        }

        Account created = result.getData();
        AuditHelper.log(req, "Tạo tài khoản", "Account",
                "Admin tạo tài khoản @" + (created != null ? created.getUsername() : username)
                + " (" + fullName + ")");

        String redirect = req.getParameter("redirect");
        if ("schedule".equals(redirect) && created != null) {
            resp.sendRedirect(req.getContextPath()
                    + "/shift-schedules?action=new&accountId=" + created.getAccountId()
                    + "&msg=account-created");
        } else if ("more".equals(redirect)) {
            resp.sendRedirect(req.getContextPath() + "/accounts?action=new&msg=created-more");
        } else {
            resp.sendRedirect(req.getContextPath() + "/accounts?msg=created");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        String action = req.getParameter("action");
        // Tạo tài khoản trực tiếp (không OTP) — admin tự cấp
        if ("create-otp".equals(action) || "create".equals(action)) {
            handleCreate(req, resp);
            return;
        }
        // ── Admin gửi lại OTP (resend) ──
        if ("admin-reset-otp-resend".equals(action)) {
            handleAdminResetOtpResend(req, resp); return;
        }
        // delete-otp flow đã bỏ — dùng purge-confirm thay thế
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
        // ── AJAX: Admin lưu face descriptor cho nhân viên ──
        if ("save-face".equals(action)) {
            handleSaveFace(req, resp);
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

        // Tạo mới (không có accountId) → delegate về handleCreate (đã xử lý validation + service)
        if (isNew) {
            handleCreate(req, resp);
            return;
        }

        // ── BƯỚC 1: Validate format (chỉ cho luồng EDIT) ────────
        List<String> errors;
        {
            errors = new java.util.ArrayList<>(ValidationUtil.validateAccount(
                    "skip", fullName, email, phone, citizenId, position));
            errors.removeIf(e -> e.toLowerCase().contains("tên đăng nhập"));
            // Password để trống = giữ nguyên, không bắt buộc khi edit
            // Nếu nhập thì phải hợp lệ (≥6 ký tự)
            if (ValidationUtil.notBlank(password))
                errors.addAll(ValidationUtil.validatePassword(password));
        }

        // ── BƯỚC 2: Validate trùng lặp (EDIT — chỉ check field thực sự thay đổi) ──
        Account current = dao.findById(Integer.parseInt(idStr));
        boolean emailChanged = false, phoneChanged = false;
        if (current != null) {
            emailChanged = ValidationUtil.notBlank(email)
                    && !email.trim().equals(current.getEmail() != null ? current.getEmail() : "");
            phoneChanged = ValidationUtil.notBlank(phone)
                    && !phone.trim().equals(current.getPhone() != null ? current.getPhone() : "");
            boolean citizenIdChanged = ValidationUtil.notBlank(citizenId)
                    && !citizenId.trim().equals(current.getCitizenId() != null ? current.getCitizenId() : "");

            if (emailChanged && dao.isEmailTaken(email, Integer.parseInt(idStr)))
                errors.add("Email '" + email + "' đã được dùng bởi tài khoản khác.");
            if (phoneChanged && dao.isPhoneTaken(phone, Integer.parseInt(idStr)))
                errors.add("Số điện thoại '" + phone.trim() + "' đã được dùng bởi tài khoản khác.");
            if (citizenIdChanged && dao.isCitizenIdTaken(citizenId, Integer.parseInt(idStr)))
                errors.add("Số CCCD '" + citizenId.trim() + "' đã được dùng bởi tài khoản khác.");
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
            SidebarHelper.load(req);

            req.getRequestDispatcher("/WEB-INF/views/admin/account-form.jsp").forward(req, resp);
            return;
        }

        // ── BƯỚC 4: Lưu chỉnh sửa ────────────────────────────────
        Account a = new Account();
        // Khi edit: lấy username hiện tại từ DB, không cho thay đổi
        a.setUsername(current != null ? current.getUsername() : (username != null ? username.trim() : ""));
        a.setFullName(fullName.trim());
        a.setEmail(email != null ? email.trim() : null);
        a.setPhone(phone != null ? phone.trim() : null);
        a.setCitizenId(citizenId != null && !citizenId.trim().isEmpty() ? citizenId.trim() : null);
        a.setPosition(position != null ? position.trim() : null);
        a.setRoleId(Integer.parseInt(roleStr));

        {
            // ── CHỈNH SỬA ──────────────────────────────────────────────────────
            int editId = Integer.parseInt(idStr);
            a.setAccountId(editId);

            // Giữ lại thông tin chuyên môn từ DB (không có trong form edit)
            if (current != null) {
                if (current.getProfessionalCertNo()  != null) a.setProfessionalCertNo(current.getProfessionalCertNo());
                if (current.getProfessionalCertExp() != null) a.setProfessionalCertExp(current.getProfessionalCertExp());
                if (current.getTrainingDate()        != null) a.setTrainingDate(current.getTrainingDate());
            }

            // ── Admin có muốn đổi MK không? ────────────────────────────────────
            // JS gửi hidden field "confirmWord" = "update" (viết thường chính xác)
            // Chỉ cần gõ "update" là đủ — MK mới sẽ nhập ở trang riêng sau OTP.
            String confirmWord = req.getParameter("confirmWord");
            boolean wantChangePw = "update".equals(
                    confirmWord != null ? confirmWord.trim() : "");

            if (wantChangePw) {
                // ── Luồng đổi MK: gửi OTP về Gmail admin ──────────────────────
                // Không cần nhập MK ở đây — sẽ nhập ở trang admin-set-password sau OTP

                // Kiểm tra có pending reset (luồng forgot-password) không
                PasswordResetRequest pendingReset = resetDAO.findPendingByAccountId(editId);
                if (pendingReset == null) pendingReset = resetDAO.findConfirmedByAccountId(editId);
                boolean isResetFlow = (pendingReset != null);

                // Update thông tin cá nhân khác (nếu có thay đổi) trước khi vào OTP
                boolean hasInfoChange = current != null && (
                        !eq(fullName,  current.getFullName())  ||
                                !eq(email,     current.getEmail())     ||
                                !eq(phone,     current.getPhone())     ||
                                !eq(citizenId, current.getCitizenId()) ||
                                !eq(position,  current.getPosition())  ||
                                a.getRoleId() != current.getRoleId());
                if (hasInfoChange) {
                    dao.update(a); // Lưu thông tin cá nhân trước
                    AuditHelper.log(req, "Cập nhật tài khoản", "Account",
                            "Cập nhật thông tin @" + (current != null ? current.getUsername() : editId)
                                    + " (trước khi đổi MK)");
                }

                HttpSession sess = req.getSession();
                sess.setAttribute("adminResetTargetId",    editId);
                sess.setAttribute("adminResetIsResetFlow", isResetFlow);

                Account adminAccPw = (Account) sess.getAttribute("adminAccount");
                String  adminEmail = adminAccPw != null ? adminAccPw.getEmail() : null;
                String  staffName  = current != null ? current.getFullName()
                        : "@" + editId;

                String otp = OtpUtil.generate(6);
                sess.setAttribute("adminResetOtpCode",   otp);
                sess.setAttribute("adminResetOtpExpiry", System.currentTimeMillis() + 5 * 60 * 1000L);

                if (adminEmail != null) {
                    String body =
                            "<div style=\"font-family:Arial,sans-serif;max-width:500px;margin:auto;padding:24px\">"
                                    + "<div style=\"background:linear-gradient(135deg,#1558A8,#0D3F85);border-radius:14px;"
                                    + "padding:20px 24px;margin-bottom:20px;color:#fff\">"
                                    + "<h2 style=\"margin:0;font-size:18px\">🔐 Xác nhận đổi mật khẩu</h2>"
                                    + "<p style=\"margin:6px 0 0;opacity:.8;font-size:13px\">Nhập mã để xác nhận</p></div>"
                                    + "<p style=\"font-size:14px;color:#0B1628\">Đổi mật khẩu cho <strong>"
                                    + staffName + "</strong>.</p>"
                                    + "<div style=\"background:#F1F5FB;border-radius:12px;padding:20px;"
                                    + "text-align:center;margin:20px 0\">"
                                    + "<div style=\"font-size:36px;font-weight:900;letter-spacing:10px;"
                                    + "color:#1558A8\">" + otp + "</div>"
                                    + "<p style=\"font-size:12px;color:#7A90B0;margin-top:8px\">Hiệu lực 5 phút</p>"
                                    + "</div><p style=\"font-size:12px;color:#999\">Nếu không phải bạn, "
                                    + "bỏ qua email này.</p></div>";
                    EmailUtil.sendEmail(adminEmail,
                            "[MediVault] OTP đổi mật khẩu — " + staffName, body);
                }
                resp.sendRedirect(req.getContextPath() + "/accounts?action=admin-reset-otp-page");
                return;
            }

            // ── Luồng thông tin thường (không đổi MK) ──────────────────────────
            boolean nothingChanged = current != null
                    && eq(fullName,   current.getFullName())
                    && eq(email,      current.getEmail())
                    && eq(phone,      current.getPhone())
                    && eq(citizenId,  current.getCitizenId())
                    && eq(position,   current.getPosition())
                    && a.getRoleId() == current.getRoleId();

            if (nothingChanged) {
                resp.sendRedirect(req.getContextPath() + "/accounts?msg=nochange");
                return;
            }

            // Bảo vệ: không cho đổi role của admin cuối cùng
            if (current != null && current.getRoleId() == 1
                    && a.getRoleId() != 1 && dao.countActiveAdmins() <= 1) {
                req.setAttribute("errors", java.util.List.of(
                        "Không thể đổi role — đây là Admin duy nhất đang hoạt động!"));
                req.setAttribute("account", a);
                SidebarHelper.load(req);

                req.getRequestDispatcher("/WEB-INF/views/admin/account-form.jsp").forward(req, resp);
                return;
            }

            boolean saved = dao.update(a);
            if (!saved) {
                req.setAttribute("errors", java.util.List.of("Lưu thất bại — kiểm tra log Tomcat!"));
                req.setAttribute("account", a);
                SidebarHelper.load(req);

                req.getRequestDispatcher("/WEB-INF/views/admin/account-form.jsp").forward(req, resp);
                return;
            }
            AuditHelper.log(req, "Cập nhật tài khoản", "Account",
                    "Cập nhật thông tin @" + (current != null ? current.getUsername() : editId));
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
        req.setAttribute("onlineStaff", com.medicare.util.SessionTracker.getOnlineSet());
        req.setAttribute("pendingReenroll", dao.findPendingFaceReenroll());
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/admin/account-list.jsp").forward(req, resp);
    }

    private void showForm(HttpServletRequest req, HttpServletResponse resp, Account account)
            throws ServletException, IOException {
        req.setAttribute("account", account);
        SidebarHelper.load(req);

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

        Boolean verified = (Boolean) (sess != null ? sess.getAttribute("adminResetOtpVerified") : null);
        if (!Boolean.TRUE.equals(verified)) {
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

        // Validate confirm match trước khi gọi service
        if (!newPassword.equals(confirmPw)) {
            req.setAttribute("staffInfo", staff);
            req.setAttribute("error", "Mật khẩu xác nhận không khớp!");
            SidebarHelper.load(req);
            req.getRequestDispatcher("/WEB-INF/views/admin/admin-set-password.jsp").forward(req, resp);
            return;
        }

        ServiceResult<Void> result = accountService.setPassword(
                targetId, newPassword, Boolean.TRUE.equals(isResetFlow));

        if (result.isFail()) {
            req.setAttribute("staffInfo", staff);
            req.setAttribute("error", result.firstError());
            SidebarHelper.load(req);
            req.getRequestDispatcher("/WEB-INF/views/admin/admin-set-password.jsp").forward(req, resp);
            return;
        }

        AuditHelper.log(req, "Đặt lại mật khẩu", "Account",
                "Admin đặt mật khẩu mới cho @" + staff.getUsername()
                + (Boolean.TRUE.equals(isResetFlow) ? " (theo yêu cầu staff)" : " (chủ động)"));

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

    // ── Admin lưu face descriptor cho nhân viên (AJAX POST) ──────────────────
    private void handleSaveFace(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        java.io.PrintWriter out = resp.getWriter();

        String accIdStr    = req.getParameter("accountId");
        String descriptorJson = req.getParameter("descriptor");

        if (accIdStr == null || accIdStr.isEmpty() || descriptorJson == null || descriptorJson.isEmpty()) {
            out.print("{\"ok\":false,\"reason\":\"missing_params\"}");
            return;
        }

        int accountId;
        try { accountId = Integer.parseInt(accIdStr.trim()); }
        catch (NumberFormatException e) {
            out.print("{\"ok\":false,\"reason\":\"invalid_accountId\"}");
            return;
        }

        // Validate: phải là JSON array 128 phần tử
        String d = descriptorJson.trim();
        if (!d.startsWith("[") || !d.endsWith("]")) {
            out.print("{\"ok\":false,\"reason\":\"bad_format\"}");
            return;
        }
        String[] parts = d.substring(1, d.length() - 1).split(",");
        if (parts.length != 128) {
            out.print("{\"ok\":false,\"reason\":\"bad_length:" + parts.length + "\"}");
            return;
        }

        Account staff = dao.findById(accountId);
        if (staff == null) {
            out.print("{\"ok\":false,\"reason\":\"not_found\"}");
            return;
        }

        dao.updateFaceVector(accountId, descriptorJson);
        out.print("{\"ok\":true}");
    }


}