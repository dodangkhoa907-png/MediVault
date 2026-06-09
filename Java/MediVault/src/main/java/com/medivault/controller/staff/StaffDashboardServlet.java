package com.medivault.controller.staff;

import com.medivault.dao.BatchesDAO;
import com.medivault.dao.MedicineDAO;
import com.medivault.dao.StaffAuditLogDAO;
import com.medivault.dao.interfaces.IBatchesDAO;
import com.medivault.dao.interfaces.IMedicineDAO;
import com.medivault.dao.interfaces.IStaffAuditLogDAO;
import com.medivault.entity.Account;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/staff-dashboard")
public class StaffDashboardServlet extends HttpServlet {

    private final IMedicineDAO      medicineDAO  = new MedicineDAO();
    private final IBatchesDAO       batchesDAO   = new BatchesDAO();
    private final IStaffAuditLogDAO staffAuditDAO = new StaffAuditLogDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

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

        req.setAttribute("staffUid",       uid);
        req.setAttribute("totalMedicines", medicineDAO.countAll());
        req.setAttribute("lowStockCount",  medicineDAO.countLowStock());
        req.setAttribute("expiryCount",    batchesDAO.findExpiringSoon().size());

        // Lấy 10 hoạt động gần nhất của nhân viên này
        req.setAttribute("recentLogs", staffAuditDAO.findRecentByAccount(staffAcc.getAccountId(), 10));

        req.getRequestDispatcher("/WEB-INF/views/staff/staff-dashboard.jsp").forward(req, resp);
    }
}