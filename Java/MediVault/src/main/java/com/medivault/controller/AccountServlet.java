package com.medivault.controller;

import com.medivault.dao.AccountDAO;
import com.medivault.dao.interfaces.IAccountDAO;
import com.medivault.entity.Account;
import com.medivault.util.PasswordUtil;
import com.medivault.util.ValidationUtil;
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
                dao.toggleActive(toggleId);
                resp.sendRedirect(req.getContextPath() + "/accounts?msg=updated");
            }
            case "view" -> {
                int id = Integer.parseInt(req.getParameter("id"));
                Account a = dao.findById(id);
                req.setAttribute("account", a);
                req.getRequestDispatcher("/WEB-INF/views/account-detail.jsp").forward(req, resp);
            }
            case "delete" -> {
                int id = Integer.parseInt(req.getParameter("id"));
                Account del = dao.findById(id);
                // Bảo vệ: không xóa admin cuối cùng
                if (del != null && del.getRoleId() == 1 && dao.countActiveAdmins() <= 1) {
                    resp.sendRedirect(req.getContextPath() + "/accounts?msg=last-admin");
                    return;
                }
                dao.softDelete(id);
                resp.sendRedirect(req.getContextPath() + "/accounts?msg=deleted");
            }
            case "restore" -> {
                dao.restore(Integer.parseInt(req.getParameter("id")));
                resp.sendRedirect(req.getContextPath() + "/accounts?action=trash&msg=restored");
            }
            case "purge" -> {
                int id = Integer.parseInt(req.getParameter("id"));
                boolean ok = dao.hardDelete(id);
                resp.sendRedirect(req.getContextPath() + "/accounts?action=trash&msg=" + (ok ? "purged" : "not-ready"));
            }
            case "trash" -> {
                req.setAttribute("deletedAccounts", dao.findDeleted());
                req.getRequestDispatcher("/WEB-INF/views/account-trash.jsp").forward(req, resp);
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
            req.getRequestDispatcher("/WEB-INF/views/account-form.jsp").forward(req, resp);
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
            req.getRequestDispatcher("/WEB-INF/views/account-form.jsp").forward(req, resp);
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
            req.getRequestDispatcher("/WEB-INF/views/account-form.jsp").forward(req, resp);
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
                req.getRequestDispatcher("/WEB-INF/views/account-form.jsp").forward(req, resp);
                return;
            }

            // ── Đổi mật khẩu: yêu cầu mật khẩu cũ ──
            if (ValidationUtil.notBlank(password) && ValidationUtil.isValidPassword(password)) {
                if (!ValidationUtil.notBlank(oldPassword)) {
                    req.setAttribute("errors", java.util.List.of("Vui lòng nhập mật khẩu hiện tại để xác nhận đổi mật khẩu!"));
                    req.setAttribute("account", a);
                    req.getRequestDispatcher("/WEB-INF/views/account-form.jsp").forward(req, resp);
                    return;
                }
                if (current == null || !PasswordUtil.checkPassword(oldPassword, current.getPasswordHash())) {
                    req.setAttribute("errors", java.util.List.of("Mật khẩu hiện tại không đúng!"));
                    req.setAttribute("account", a);
                    req.getRequestDispatcher("/WEB-INF/views/account-form.jsp").forward(req, resp);
                    return;
                }
                dao.resetPassword(editId, PasswordUtil.hashPassword(password));
                // Gửi thông báo đổi mật khẩu về email admin
                try {
                    String uname = current != null ? current.getUsername() : String.valueOf(editId);
                    EmailUtil.sendEmail("dodangkhoa907@gmail.com",
                            "[MediVault] Mat khau tai khoan @" + uname + " da duoc doi",
                            "Admin da dat lai mat khau cho tai khoan @" + uname + ".\nNeu khong phai ban thuc hien, kiem tra ngay.");
                } catch (Exception ignored) {}
            }

            // Bảo vệ: không cho đổi role admin cuối cùng thành non-admin
            if (current != null && current.getRoleId() == 1
                    && a.getRoleId() != 1 && dao.countActiveAdmins() <= 1) {
                req.setAttribute("errors", java.util.List.of(
                        "Không thể thay đổi role — đây là tài khoản Admin duy nhất đang hoạt động!"));
                req.setAttribute("account", a);
                req.getRequestDispatcher("/WEB-INF/views/account-form.jsp").forward(req, resp);
                return;
            }

            boolean saved = dao.update(a);
            if (!saved) {
                req.setAttribute("errors", java.util.List.of("Lưu thất bại — kiểm tra log Tomcat!"));
                req.setAttribute("account", a);
                req.getRequestDispatcher("/WEB-INF/views/account-form.jsp").forward(req, resp);
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
        req.getRequestDispatcher("/WEB-INF/views/account-list.jsp").forward(req, resp);
    }

    private void showForm(HttpServletRequest req, HttpServletResponse resp, Account account)
            throws ServletException, IOException {
        req.setAttribute("account", account);
        req.getRequestDispatcher("/WEB-INF/views/account-form.jsp").forward(req, resp);
    }

}