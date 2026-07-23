package com.medicare.controller;

import com.medicare.entity.Account;
import com.medicare.util.AuditHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/logout")
public class LogoutServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        // sendBeacon gửi POST — delegate sang doGet
        doGet(req, resp);
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        String from      = req.getParameter("from");
        String staffUid  = req.getParameter("uid");
        String redirectUrl = "/login";

        if (session != null) {

            // ── STAFF/WAREHOUSE logout: chỉ xóa staffAccount của uid này, KHÔNG đụng admin ──
            // Cả 2 role dùng chung session "staffAccount_<uid>", nên xác định đúng trang đăng
            // nhập để quay lại phải dựa vào roleId THẬT của tài khoản, KHÔNG dựa vào tham số
            // "from" (dễ bị JSP gọi sai/hardcode nhầm, như warehouse-sidebar.jsp trước đây).
            if ("staff".equals(from) || "warehouse".equals(from) || staffUid != null) {
                redirectUrl = "/staff-login";
                if (staffUid != null && !staffUid.isEmpty()) {
                    Account staffAcc = (Account) session.getAttribute("staffAccount_" + staffUid);
                    if (staffAcc != null) {
                        if (staffAcc.getRoleId() == 3) redirectUrl = "/warehouse-login";
                        AuditHelper.log(req, "Đăng xuất", "Auth",
                                "Staff @" + staffAcc.getUsername() + " đăng xuất",
                                staffAcc.getAccountId());
                        com.medicare.util.SessionTracker.logout(staffAcc.getAccountId());
                        session.removeAttribute("staffAccount_" + staffUid);
                    }
                }
                // Không invalidate session, không xóa adminAccount
                AuthFilter.clearAllCookies(resp);
                resp.sendRedirect(req.getContextPath() + redirectUrl);
                return;
            }

            // ── ADMIN logout: chỉ xóa adminAccount, KHÔNG đụng staffAccount ──
            Account adminAcc = (Account) session.getAttribute("adminAccount");
            if (adminAcc != null) {
                AuditHelper.log(req, "Đăng xuất Admin", "Auth",
                        "Admin @" + adminAcc.getUsername() + " đăng xuất",
                        adminAcc.getAccountId());
                com.medicare.util.SessionTracker.logout(adminAcc.getAccountId());
                session.removeAttribute("adminAccount");
            }
        }

        AuthFilter.clearAllCookies(resp);
        resp.sendRedirect(req.getContextPath() + redirectUrl);
    }
}