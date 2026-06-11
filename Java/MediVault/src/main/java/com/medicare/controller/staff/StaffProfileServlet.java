package com.medicare.controller.staff;

import com.medicare.entity.Account;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/staff-profile")
public class StaffProfileServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // AuthFilter đã đảm bảo staffAccount tồn tại trước khi vào đây
        // uid LUÔN từ URL param — không lưu session
        String uid = req.getParameter("uid");
        if (uid == null || uid.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/staff-login");
            return;
        }

        HttpSession session = req.getSession(false);
        if (session == null) { resp.sendRedirect(req.getContextPath() + "/staff-login"); return; }

        Account staffAcc = (Account) session.getAttribute("staffAccount_" + uid);
        if (staffAcc == null) { resp.sendRedirect(req.getContextPath() + "/staff-login"); return; }
        if (staffAcc.getRoleId() == 1) { resp.sendRedirect(req.getContextPath() + "/dashboard"); return; }
        req.setAttribute("staffUid", uid);

        req.getRequestDispatcher("/WEB-INF/views/staff/staff-profile.jsp").forward(req, resp);
    }
    // Lấy staff uid từ cookie mv_staff_uid
    private String getStaffUid(jakarta.servlet.http.HttpServletRequest req) {
        jakarta.servlet.http.Cookie[] cookies = req.getCookies();
        if (cookies != null) {
            for (jakarta.servlet.http.Cookie ck : cookies) {
                if ("mv_staff_uid".equals(ck.getName())) return ck.getValue();
            }
        }
        return "";
    }

}