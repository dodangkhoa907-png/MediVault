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
                dao.toggleActive(Integer.parseInt(req.getParameter("id")));
                resp.sendRedirect(req.getContextPath() + "/accounts?msg=updated");
            }
            case "view" -> {
                int id = Integer.parseInt(req.getParameter("id"));
                Account a = dao.findById(id);
                req.setAttribute("account", a);
                req.getRequestDispatcher("/WEB-INF/views/account-detail.jsp").forward(req, resp);
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
            return;  // ← dừng lại, không chạy xuống update/insert
        }

        java.lang.String idStr       = req.getParameter("accountId");
        java.lang.String username    = req.getParameter("username");
        java.lang.String fullName    = req.getParameter("fullName");
        java.lang.String email       = req.getParameter("email");
        java.lang.String phone       = req.getParameter("phone");
        java.lang.String citizenId   = req.getParameter("citizenId");
        java.lang.String position    = req.getParameter("position");
        java.lang.String password    = req.getParameter("password");
        java.lang.String oldPassword = req.getParameter("oldPassword");
        java.lang.String roleStr     = req.getParameter("roleId");
        java.lang.String certNo      = req.getParameter("professionalCertNo");
        java.lang.String certExpStr  = req.getParameter("professionalCertExp");
        java.lang.String trainingStr = req.getParameter("trainingDate");

        boolean isNew = (idStr == null || idStr.isEmpty());

        // ── BƯỚC 1: Validate format ──────────────────────────────
        List<String> errors = ValidationUtil.validateAccount(
                username, fullName, email, phone, citizenId, position
        );

        // Validate password (bắt buộc khi tạo mới)

        if (isNew && !ValidationUtil.isValidPassword(password))
            errors.add("Mật khẩu phải có ít nhất 6 ký tự.");

        // ── BƯỚC 2: Validate trùng lặp ──────────────────────────
        if (isNew && ValidationUtil.notBlank(username) && dao.isUsernameTaken(username))
            errors.add("Tên đăng nhập '" + username + "' đã tồn tại.");

        int excludeId = isNew ? -1 : Integer.parseInt(idStr);
        if (ValidationUtil.notBlank(email) && dao.isEmailTaken(email, excludeId)) {
            // Khi edit: chỉ báo lỗi nếu email thực sự bị trùng với TÀI KHOẢN KHÁC
            // (excludeId đã loại chính mình, nếu vẫn trùng thì mới lỗi)
            errors.add("Email '" + email + "' đã được dùng bởi tài khoản khác.");
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
        a.setUsername(username.trim());
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

            // ── Kiểm tra email/phone thay đổi → yêu cầu OTP ──
            Account current = dao.findById(editId);
            boolean emailChanged = current != null && ValidationUtil.notBlank(email)
                    && !email.trim().equals(current.getEmail() != null ? current.getEmail() : "");
            boolean phoneChanged = current != null && ValidationUtil.notBlank(phone)
                    && !phone.trim().equals(current.getPhone() != null ? current.getPhone() : "");

            if (emailChanged || phoneChanged) {
                // Gửi OTP tới email MỚI (nếu email đổi) hoặc email cũ (nếu chỉ đổi phone)
                String sendTo = emailChanged ? email.trim()
                        : (current.getEmail() != null ? current.getEmail() : "");

                if (ValidationUtil.notBlank(sendTo)) {
                    String otp = OtpUtil.generate(6);
                    HttpSession sess = req.getSession();
                    sess.setAttribute("pendingUpdateAccount", a);
                    sess.setAttribute("updateAccOtpCode",    otp);
                    sess.setAttribute("updateAccOtpExpiry",  System.currentTimeMillis() + 5 * 60 * 1000L);
                    sess.setAttribute("updateAccNewPassword", ValidationUtil.notBlank(password) && ValidationUtil.isValidPassword(password) ? password : null);
                    try {
                        String what = emailChanged && phoneChanged ? "email và số điện thoại"
                                : emailChanged ? "email" : "số điện thoại";
                        EmailUtil.sendEmail(sendTo,
                                "[MediVault] Xác nhận thay đổi thông tin tài khoản",
                                "Mã OTP xác nhận thay đổi " + what + " cho tài khoản @" + (current != null ? current.getUsername() : "") + ": " + otp + "\nHiệu lực 5 phút.");
                        resp.sendRedirect(req.getContextPath() + "/otp-verify?mode=update");
                    } catch (Exception e) {
                        req.setAttribute("error", "Không gửi được email OTP xác nhận!");
                        req.getRequestDispatcher("/WEB-INF/views/account-form.jsp").forward(req, resp);
                    }
                    return;
                }
            }

            // ── Đổi mật khẩu: yêu cầu nhập mật khẩu cũ ──
            if (ValidationUtil.notBlank(password) && ValidationUtil.isValidPassword(password)) {
                if (ValidationUtil.notBlank(oldPassword)) {
                    Account cur = dao.findById(editId);
                    if (cur == null || !PasswordUtil.checkPassword(oldPassword, cur.getPasswordHash())) {
                        req.setAttribute("errors", java.util.List.of("Mật khẩu cũ không đúng!"));
                        req.setAttribute("account", a);
                        req.getRequestDispatcher("/WEB-INF/views/account-form.jsp").forward(req, resp);
                        return;
                    }
                    dao.resetPassword(editId, PasswordUtil.hashPassword(password));
                } else {
                    // Không nhập mật khẩu cũ → báo lỗi yêu cầu nhập
                    req.setAttribute("errors", java.util.List.of("Vui lòng nhập mật khẩu cũ để xác nhận khi đổi mật khẩu!"));
                    req.setAttribute("account", a);
                    req.getRequestDispatcher("/WEB-INF/views/account-form.jsp").forward(req, resp);
                    return;
                }
            }

            dao.update(a);
            resp.sendRedirect(req.getContextPath() + "/accounts?msg=updated");
        }
    }

    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setAttribute("accounts", dao.findAll());
        req.getRequestDispatcher("/WEB-INF/views/account-list.jsp").forward(req, resp);
    }

    private void showForm(HttpServletRequest req, HttpServletResponse resp, Account account)
            throws ServletException, IOException {
        req.setAttribute("account", account);
        req.getRequestDispatcher("/WEB-INF/views/account-form.jsp").forward(req, resp);
    }
}