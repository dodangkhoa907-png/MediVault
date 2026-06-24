package com.medicare.controller.admin;

import com.medicare.dao.AccountDAO;
import com.medicare.dao.PasswordResetDAO;
import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.dao.interfaces.IPasswordResetDAO;
import com.medicare.entity.PasswordResetRequest;
import com.medicare.entity.Account;
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

    private final IAccountDAO dao = new AccountDAO();
    private final IPasswordResetDAO resetDAO = new PasswordResetDAO();

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
                SidebarHelper.load(req);

                req.getRequestDispatcher("/WEB-INF/views/admin/admin-delete-confirm.jsp").forward(req, resp);
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
                java.util.Set<Integer> idsSet = com.medicare.util.SessionTracker.getOnlineSet();
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
            case "purge-confirm" -> {
                // Admin đã gõ "delete" (lowercase chính xác) → xóa vĩnh viễn ngay, không OTP
                Integer tid = (Integer) req.getSession().getAttribute("deleteTargetId");
                String cWord = req.getParameter("confirmWord");
                if (tid == null) {
                    resp.sendRedirect(req.getContextPath() + "/accounts?action=trash"); return;
                }
                if (!"delete".equals(cWord != null ? cWord.trim() : "")) {
                    resp.sendRedirect(req.getContextPath() + "/accounts?action=trash&msg=invalid-word"); return;
                }
                Account delTarget2 = dao.findById(tid);
                if (delTarget2 == null) {
                    resp.sendRedirect(req.getContextPath() + "/accounts?action=trash&msg=not-found"); return;
                }
                // Bảo vệ: không cho xóa vĩnh viễn admin gốc (ID=1)
                if (tid == 1) {
                    resp.sendRedirect(req.getContextPath() + "/accounts?action=trash&msg=protected-admin"); return;
                }
                if (delTarget2.getRoleId() == 1 && dao.countActiveAdmins() <= 1) {
                    resp.sendRedirect(req.getContextPath() + "/accounts?msg=last-admin"); return;
                }
                String delName2 = (String) req.getSession().getAttribute("deleteTargetName");
                try {
                    boolean deleted2 = dao.forceDelete(tid);
                    if (!deleted2) {
                        resp.sendRedirect(req.getContextPath() + "/accounts?action=trash&msg=system-error"); return;
                    }
                    AuditHelper.log(req, "Xóa vĩnh viễn tài khoản", "Account",
                            "Xóa vĩnh viễn (xác nhận delete): " + (delName2 != null ? delName2 : String.valueOf(tid)));
                    req.getSession().removeAttribute("deleteTargetId");
                    req.getSession().removeAttribute("deleteTargetName");
                    resp.sendRedirect(req.getContextPath() + "/accounts?action=trash&msg=purged");
                } catch (Exception e) {
                    System.err.println("[AccountServlet] forceDelete failed ID " + tid + ": " + e.getMessage());
                    resp.sendRedirect(req.getContextPath() + "/accounts?action=trash&msg=system-error&details="
                            + java.net.URLEncoder.encode(e.getMessage(), "UTF-8"));
                }
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

        // ── Auto-generate username từ SĐT nếu admin bỏ trống ──
        // Ưu tiên: username nhập tay → nếu trống → dùng SĐT → nếu SĐT cũng trống → giữ nguyên
        if ((username == null || username.trim().isEmpty()) && ValidationUtil.notBlank(phone)) {
            username = phone.trim().replaceAll("[^0-9]", ""); // chỉ giữ số
        }

        List<String> errors = new java.util.ArrayList<>(ValidationUtil.validateAccount(
                username, fullName, email, phone, citizenId, position));
        errors.addAll(ValidationUtil.validatePassword(password));
        // CitizenId là NOT NULL trong DB — bắt buộc nhập khi tạo mới
        if (!ValidationUtil.notBlank(citizenId))
            errors.add("Số CMND/CCCD không được để trống.");
        // Chặn username reserved (admin, root, system...)
        if (ValidationUtil.notBlank(username) && ValidationUtil.isReservedUsername(username))
            errors.add("Tên đăng nhập '" + username + "' là tên hệ thống — không được phép sử dụng.");
        else if (ValidationUtil.notBlank(username) && dao.isUsernameTaken(username))
            errors.add("Tên đăng nhập '" + username + "' đã tồn tại.");
        if (ValidationUtil.notBlank(email) && dao.isEmailTaken(email, -1))
            errors.add("Email '" + email + "' đã được dùng.");
        // ── Kiểm tra SĐT trùng ──
        if (ValidationUtil.notBlank(phone) && dao.isPhoneTaken(phone, -1))
            errors.add("Số điện thoại '" + phone.trim() + "' đã được dùng bởi tài khoản khác.");

        if (!errors.isEmpty()) {
            Account draft = new Account();
            // Nếu username lỗi (trùng/reserved) → clear để admin nhập lại
            boolean usernameErr = errors.stream().anyMatch(e -> e.contains("Tên đăng nhập"));
            draft.setUsername(usernameErr ? "" : (username != null ? username : ""));
            draft.setFullName(fullName != null ? fullName : "");
            draft.setEmail(email != null ? email : "");
            draft.setPhone(phone != null ? phone : "");
            draft.setCitizenId(citizenId != null ? citizenId : "");
            draft.setPosition(position != null ? position : "");
            draft.setRoleId(roleStr != null && !roleStr.isEmpty() ? Integer.parseInt(roleStr) : 2);
            req.setAttribute("account", draft);
            req.setAttribute("errors", errors);
            req.setAttribute("errorMsg", ValidationUtil.joinErrors(errors));
            SidebarHelper.load(req);

            req.getRequestDispatcher("/WEB-INF/views/admin/account-form.jsp").forward(req, resp);
            return;
        }

        Account a = new Account();
        a.setUsername(username.trim());
        a.setFullName(fullName.trim());
        a.setEmail(email != null ? email.trim() : null);
        a.setPhone(phone != null ? phone.trim() : null);
        // CitizenId là NOT NULL trong DB — dùng empty string nếu null (phòng thủ thêm)
        a.setCitizenId(citizenId != null && !citizenId.trim().isEmpty() ? citizenId.trim() : "");
        a.setPosition(position != null ? position.trim() : null);
        a.setRoleId(Integer.parseInt(roleStr));
        a.setPasswordHash(PasswordUtil.hashPassword(password));

        boolean ok = dao.insert(a);
        if (ok) {
            // 1. Ghi log lịch sử hệ thống (Giữ nguyên chức năng cũ)
            AuditHelper.log(req, "Tạo tài khoản", "Account",
                    "Admin tạo tài khoản @" + username + " (" + fullName + ")");

            // 2. TỰ ĐỘNG GỬI EMAIL THÔNG BÁO TÀI KHOẢN MỚI CHO NHÂN VIÊN (Thêm mới)
            if (email != null && !email.trim().isEmpty()) {
                String staffEmail = email.trim();
                String emailHtml = "<div style=\"font-family:Arial,sans-serif;max-width:520px;margin:auto;padding:24px\">"
                        + "<div style=\"background:linear-gradient(135deg,#1E3A8A,#3B82F6);border-radius:14px;padding:20px 24px;margin-bottom:20px;color:#fff\">"
                        + "<h2 style=\"margin:0;font-size:18px\">🎉 Tài khoản MediVault của bạn đã được tạo!</h2>"
                        + "<p style=\"margin:6px 0 0;opacity:.8;font-size:13px\">Hệ thống quản lý kho dược và ca trực MediVault</p>"
                        + "</div>"
                        + "<p style=\"font-size:14px;color:#1C0F3F\">Xin chào <strong>" + fullName.trim() + "</strong>,</p>"
                        + "<p style=\"font-size:13.5px;color:#374151;line-height:1.7\">"
                        + "Tài khoản của bạn đã được khởi tạo thành công trên hệ thống bởi Ban quản trị. Dưới đây là thông tin đăng nhập chi tiết của bạn:"
                        + "</p>"
                        + "<div style=\"background:#F8FAFC;border:1px solid #E2E8F0;border-radius:12px;padding:18px 20px;margin:18px 0;\">"
                        + "<p style=\"margin:0 0 6px;font-size:14px;color:#334155\">👤 Tên đăng nhập: <strong style=\"color:#0F172A;\">@" + username.trim() + "</strong></p>"
                        + "<p style=\"margin:0 0 12px;font-size:14px;color:#334155\">💼 Chức vụ: <strong>" + (position != null ? position.trim() : "Nhân viên") + "</strong></p>"
                        + "<hr style=\"border:0;border-top:1px solid #E2E8F0;margin:12px 0;\">"
                        + "<p style=\"margin:0 0 8px;font-size:12px;font-weight:700;color:#1E3A8A;letter-spacing:1px;text-transform:uppercase\">🔑 Mật khẩu</p>"
                        + "<p style=\"margin:0;font-size:13px;color:#374151;line-height:1.6\">Mật khẩu đăng nhập sẽ được <strong>Admin cung cấp trực tiếp</strong> cho bạn. Vui lòng liên hệ Ban quản trị để nhận mật khẩu.</p>"
                        + "<p style=\"margin:8px 0 0;font-size:12px;color:#6B7280\">💡 Sau khi nhận mật khẩu, hãy đổi mật khẩu ngay lần đăng nhập đầu tiên.</p>"
                        + "</div>"
                        + "<p style=\"font-size:12px;color:#999\">Đây là email tự động từ hệ thống MediVault, vui lòng không phản hồi email này.</p>"
                        + "</div>";

                // Thực hiện gửi email thông báo tài khoản
                EmailUtil.sendEmail(staffEmail, "[MediVault] 🎉 Tài khoản của bạn đã được tạo thành công", emailHtml);
            }

            // 3. Xử lý điều hướng trang (Giữ nguyên chức năng cũ - LUÔN ĐẶT Ở CUỐI KHỐI LỆNH)
            Account created = dao.findByUsername(username.trim());
            // Thông báo cho nhân viên mới
            if (created != null) {
                StaffNotifHelper.accountCreated(created.getAccountId(),
                        fullName != null ? fullName.trim() : username.trim());
                StaffNotifHelper.faceEnrollReminder(created.getAccountId());
            }
            String redirect = req.getParameter("redirect");
            if ("schedule".equals(redirect) && created != null) {
                // Lưu & Xếp lịch ngay → redirect sang trang xếp lịch pre-fill
                resp.sendRedirect(req.getContextPath()
                        + "/shift-schedules?action=new&accountId=" + created.getAccountId()
                        + "&msg=account-created");
            } else {
                // Tạo xong → về danh sách, hiện toast thành công
                resp.sendRedirect(req.getContextPath() + "/accounts?msg=created");
            }
        } else {
            // Thất bại (Giữ nguyên chức năng cũ)
            req.setAttribute("error", "Tạo tài khoản thất bại — kiểm tra log Tomcat!");
            req.setAttribute("account", a);
            SidebarHelper.load(req);

            req.getRequestDispatcher("/WEB-INF/views/admin/dashboard.jsp").forward(req, resp);
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
            // Password để trống = giữ nguyên, không bắt buộc khi edit
            // Nếu nhập thì phải hợp lệ (≥6 ký tự)
            if (ValidationUtil.notBlank(password))
                errors.addAll(ValidationUtil.validatePassword(password));
        }

        // ── BƯỚC 2: Validate trùng lặp ──────────────────────────
        Account current = null;
        boolean emailChanged = false, phoneChanged = false;
        if (isNew) {
            // Tạo mới: check username + email + phone
            if (ValidationUtil.notBlank(username) && dao.isUsernameTaken(username))
                errors.add("Tên đăng nhập '" + username + "' đã tồn tại.");
            if (ValidationUtil.notBlank(email) && dao.isEmailTaken(email, -1))
                errors.add("Email '" + email + "' đã được dùng bởi tài khoản khác.");
            if (ValidationUtil.notBlank(phone) && dao.isPhoneTaken(phone, -1))
                errors.add("Số điện thoại '" + phone.trim() + "' đã được dùng bởi tài khoản khác.");
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
                if (phoneChanged && dao.isPhoneTaken(phone, Integer.parseInt(idStr)))
                    errors.add("Số điện thoại '" + phone.trim() + "' đã được dùng bởi tài khoản khác.");
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
            SidebarHelper.load(req);

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
        // CitizenId là NOT NULL trong DB — dùng empty string nếu null
        a.setCitizenId(citizenId != null && !citizenId.trim().isEmpty() ? citizenId.trim() : "");
        a.setPosition(position != null ? position.trim() : null);
        a.setRoleId(Integer.parseInt(roleStr));



        if (isNew) {
            // ── TẠO MỚI: admin tự cấp MK, lưu thẳng không OTP ──
            a.setPasswordHash(PasswordUtil.hashPassword(password));
            boolean ok = dao.insert(a);
            if (ok) {
                AuditHelper.log(req, "Tạo tài khoản", "Account",
                        "Admin tạo @" + (username != null ? username : "") + " (" + fullName + ")");
                resp.sendRedirect(req.getContextPath() + "/accounts?msg=created");
            } else {
                req.setAttribute("errors", java.util.List.of("Tạo tài khoản thất bại — kiểm tra log!"));
                req.setAttribute("account", a);
                SidebarHelper.load(req);

                req.getRequestDispatcher("/WEB-INF/views/admin/account-form.jsp").forward(req, resp);
            }

        } else {
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

        // Validate mật khẩu (chữ hoa + thường + số + đặc biệt + ≥8 ký tự)
        java.util.List<String> pwErrors = ValidationUtil.validatePassword(newPassword);
        if (!pwErrors.isEmpty()) {
            req.setAttribute("staffInfo", staff);
            req.setAttribute("error", String.join(" ", pwErrors));
            SidebarHelper.load(req);

            req.getRequestDispatcher("/WEB-INF/views/admin/admin-set-password.jsp").forward(req, resp);
            return;
        }
        if (!newPassword.equals(confirmPw)) {
            req.setAttribute("staffInfo", staff);
            req.setAttribute("error", "Mật khẩu xác nhận không khớp!");
            SidebarHelper.load(req);

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
                    + "<div style=\"background:#F0FDF4;border:2px solid #86EFAC;border-radius:12px;padding:18px 20px;margin:18px 0;\">"
                    + "<p style=\"margin:0 0 8px;font-size:12px;font-weight:700;color:#15803D;letter-spacing:1px;text-transform:uppercase\">🔑 Mật khẩu đã được đặt lại</p>"
                    + "<p style=\"margin:0;font-size:13px;color:#374151;line-height:1.6\">Mật khẩu mới sẽ được <strong>Admin cung cấp trực tiếp</strong> cho bạn. Vui lòng liên hệ Ban quản trị.</p>"
                    + "<p style=\"margin:8px 0 0;font-size:12px;color:#6B7280\">"
                    + "💡 Sau khi nhận mật khẩu, hãy đổi ngay khi đăng nhập.</p>"
                    + "</div>"
                    + "<p style=\"font-size:12px;color:#999\">Nếu bạn không yêu cầu điều này, hãy liên hệ Admin ngay lập tức.</p>"
                    + "</div>";
            EmailUtil.sendEmail(staffEmail,
                    "[MediVault] ✅ Tài khoản @" + staff.getUsername() + " đã được mở khóa",
                    emailHtml);
        }

        // Thông báo cho nhân viên
        StaffNotifHelper.passwordReset(targetId);

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


}