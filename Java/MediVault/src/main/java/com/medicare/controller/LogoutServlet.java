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
                // Portal Kho không còn gắn ?uid= vào URL (id tài khoản không được lộ trên thanh
                // địa chỉ) nên link đăng xuất từ đó KHÔNG mang uid. Thiếu uid mà vẫn đi tiếp thì
                // nhánh dưới bị bỏ qua: session KHÔNG được xoá — người dùng bấm "Đăng xuất" xong
                // vẫn đang đăng nhập. Vì vậy suy ra danh tính từ chính session khi thiếu uid.
                if ((staffUid == null || staffUid.isEmpty()) && "warehouse".equals(from)) {
                    Account whAcc = com.medicare.util.WarehouseAuth.current(req);
                    if (whAcc != null) staffUid = String.valueOf(whAcc.getAccountId());
                }
                if (staffUid != null && !staffUid.isEmpty()) {
                    Account staffAcc = (Account) session.getAttribute("staffAccount_" + staffUid);
                    if (staffAcc != null) {
                        if (staffAcc.getRoleId() == 3) redirectUrl = "/warehouse-login";
                        AuditHelper.log(req, "Đăng xuất", "Auth",
                                "Staff @" + staffAcc.getUsername() + " đăng xuất",
                                staffAcc.getAccountId());
                        com.medicare.util.SessionTracker.logout(staffAcc.getAccountId());
                        session.removeAttribute("staffAccount_" + staffUid);
                        // Xoá luôn danh tính portal Kho, nếu không WarehouseAuth.current() vẫn
                        // trả về tài khoản vừa đăng xuất và người dùng quay lại /warehouse-* được.
                        if (staffAcc.getRoleId() == 3) {
                            session.removeAttribute(com.medicare.util.WarehouseAuth.SESSION_KEY);
                        }
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