package com.medivault.controller;

import com.medivault.dao.AccountDAO;
import com.medivault.entity.Account;
import com.medivault.dao.MedicineDAO;
import com.medivault.dao.BatchesDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.io.IOException;

@WebServlet("/dashboard")
public class DashboardServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        Account account = (session != null) ? (Account) session.getAttribute("account") : null;
        if (account == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        MedicineDAO medicineDAO = new MedicineDAO();
        BatchesDAO  batchesDAO  = new BatchesDAO();
        AccountDAO accountDAO  = new AccountDAO();

        req.setAttribute("totalMedicines", medicineDAO.countAll());
        req.setAttribute("lowStockCount",  medicineDAO.countLowStock());
        req.setAttribute("expiryCount",     batchesDAO.findExpiringSoon().size());
        req.setAttribute("expiredCount",   batchesDAO.findExpired().size());
        
        java.util.List<Account> allAccounts = accountDAO.findAll();
        req.setAttribute("accounts",       allAccounts);
        req.setAttribute("activeAccounts", allAccounts.stream().filter(Account::isActive).count());
        req.getRequestDispatcher("/WEB-INF/views/dashboard.jsp").forward(req, resp);
    }


}