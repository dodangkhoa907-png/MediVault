package com.medivault.controller;

import com.medivault.dao.AccountDAO;
import com.medivault.entity.Account;
import com.medivault.util.PasswordUtil;
import com.medivault.util.ValidationUtil;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.List;

@WebServlet("/accounts")
public class AccountServlet extends HttpServlet {

    private final AccountDAO dao = new AccountDAO();

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
                dao.toggleActive(Integer.parseInt(req.getParameter("id")));
                resp.sendRedirect(req.getContextPath() + "/accounts?msg=updated");
            }
            default -> showList(req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        java.lang.String idStr    = req.getParameter("accountId");
        java.lang.String username = req.getParameter("username");
        java.lang.String fullName = req.getParameter("fullName");
        java.lang.String email    = req.getParameter("email");
        java.lang.String phone    = req.getParameter("phone");
        java.lang.String citizenId= req.getParameter("citizenId");
        java.lang.String position = req.getParameter("position");
        java.lang.String password = req.getParameter("password");
        java.lang.String roleStr  = req.getParameter("roleId");

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
        if (ValidationUtil.notBlank(email) && dao.isEmailTaken(email, excludeId))
            errors.add("Email '" + email + "' đã được dùng bởi tài khoản khác.");

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
            a.setAccountId(Integer.parseInt(idStr));
            dao.update(a);
            // Đổi mật khẩu nếu nhập mới
            if (ValidationUtil.notBlank(password) && ValidationUtil.isValidPassword(password)) {
                dao.resetPassword(a.getAccountId(), PasswordUtil.hashPassword(password));
            }
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