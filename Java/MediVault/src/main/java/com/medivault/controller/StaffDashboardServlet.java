package com.medivault.controller;

import com.medivault.dao.BatchesDAO;
import com.medivault.dao.MedicineDAO;
import com.medivault.dao.interfaces.IBatchesDAO;
import com.medivault.dao.interfaces.IMedicineDAO;
import com.medivault.entity.Account;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

/**
 * StaffDashboardServlet — URL riêng cho nhân viên: /staff-dashboard
 * TÁCH HOÀN TOÀN khỏi /dashboard của admin → không bao giờ đụng nhau.
 */
@WebServlet("/staff-dashboard")
public class StaffDashboardServlet extends HttpServlet {

    private final IMedicineDAO medicineDAO = new MedicineDAO();
    private final IBatchesDAO  batchesDAO  = new BatchesDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // uid LUÔN lấy từ URL param — KHÔNG lưu vào session vì session chia sẻ giữa tabs
        String uid = req.getParameter("uid");
        if (uid == null || uid.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/staff-login");
            return;
        }

        HttpSession session = req.getSession(false);
        if (session == null) { resp.sendRedirect(req.getContextPath() + "/staff-login"); return; }

        Account staffAcc = (Account) session.getAttribute("staffAccount_" + uid);
        if (staffAcc == null) {
            resp.sendRedirect(req.getContextPath() + "/staff-login");
            return;
        }
        if (staffAcc.getRoleId() == 1) {
            resp.sendRedirect(req.getContextPath() + "/dashboard");
            return;
        }
        // Truyền uid xuống JSP để gắn vào links
        req.setAttribute("staffUid", uid);

        req.setAttribute("totalMedicines", medicineDAO.countAll());
        req.setAttribute("lowStockCount",  medicineDAO.countLowStock());
        req.setAttribute("expiryCount",    batchesDAO.findExpiringSoon().size());
        req.getRequestDispatcher("/WEB-INF/views/staff-dashboard.jsp").forward(req, resp);
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