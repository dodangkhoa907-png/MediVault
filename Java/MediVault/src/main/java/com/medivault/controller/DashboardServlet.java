package com.medivault.controller;

import com.medivault.dao.AccountDAO;
import com.medivault.dao.interfaces.IAccountDAO;
import com.medivault.dao.interfaces.IMedicineDAO;
import com.medivault.dao.interfaces.IBatchesDAO;
import com.medivault.dao.MedicineDAO;
import com.medivault.dao.BatchesDAO;
import com.medivault.entity.Account;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;

@WebServlet("/dashboard")
public class DashboardServlet extends HttpServlet {

    private final IMedicineDAO medicineDAO = new MedicineDAO();
    private final IBatchesDAO  batchesDAO  = new BatchesDAO();
    private final IAccountDAO  accountDAO  = new AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        // /dashboard CHỈ dành cho ADMIN — đọc adminAccount, không quan tâm staffAccount
        Account adminAcc = session != null ? (Account) session.getAttribute("adminAccount") : null;

        if (adminAcc == null || adminAcc.getRoleId() != 1) {
            // Không có adminAccount hợp lệ → về trang login admin
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        // ── Admin đã xác thực → load data và forward ──
        req.setAttribute("totalMedicines", medicineDAO.countAll());
        req.setAttribute("lowStockCount",  medicineDAO.countLowStock());
        req.setAttribute("expiryCount",    batchesDAO.findExpiringSoon().size());
        req.setAttribute("expiredCount",   batchesDAO.findExpired().size());
        List<Account> allAccounts = accountDAO.findAllStaff();
        req.setAttribute("accounts",       allAccounts);
        req.setAttribute("onlineStaff", com.medivault.util.SessionTracker.getOnlineSet());
        req.setAttribute("activeAccounts", allAccounts.stream()
                .filter(Account::isActive).count());
        req.getRequestDispatcher("/WEB-INF/views/dashboard.jsp").forward(req, resp);
    }
}