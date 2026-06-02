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

        HttpSession session = req.getSession(false);
        Account staffAcc = session != null
                ? (Account) session.getAttribute("staffAccount") : null;

        // Không có staffAccount → về staff-login
        if (staffAcc == null) {
            resp.sendRedirect(req.getContextPath() + "/staff-login");
            return;
        }
        // Admin vô nhầm → về admin dashboard
        if (staffAcc.getRoleId() == 1) {
            resp.sendRedirect(req.getContextPath() + "/dashboard");
            return;
        }

        req.setAttribute("totalMedicines", medicineDAO.countAll());
        req.setAttribute("lowStockCount",  medicineDAO.countLowStock());
        req.setAttribute("expiryCount",    batchesDAO.findExpiringSoon().size());
        req.getRequestDispatcher("/WEB-INF/views/staff-dashboard.jsp").forward(req, resp);
    }
}