package com.medivault.controller;

import com.medivault.dao.AccountDAO;
import com.medivault.dao.PasswordResetDAO;
import com.medivault.dao.interfaces.IAccountDAO;
import com.medivault.dao.interfaces.IMedicineDAO;
import com.medivault.dao.interfaces.IBatchesDAO;
import com.medivault.dao.interfaces.IPasswordResetDAO;
import com.medivault.dao.MedicineDAO;
import com.medivault.dao.BatchesDAO;
import com.medivault.entity.Account;
import com.medivault.entity.PasswordResetRequest;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;

@WebServlet("/dashboard")
public class DashboardServlet extends HttpServlet {

    private final IMedicineDAO      medicineDAO = new MedicineDAO();
    private final IBatchesDAO       batchesDAO  = new BatchesDAO();
    private final IAccountDAO       accountDAO  = new AccountDAO();
    private final IPasswordResetDAO resetDAO    = new PasswordResetDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        Account adminAcc = session != null ? (Account) session.getAttribute("adminAccount") : null;

        if (adminAcc == null || adminAcc.getRoleId() != 1) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        // ── Stats ──
        req.setAttribute("totalMedicines", medicineDAO.countAll());
        req.setAttribute("lowStockCount",  medicineDAO.countLowStock());
        req.setAttribute("expiryCount",    batchesDAO.findExpiringSoon().size());
        req.setAttribute("expiredCount",   batchesDAO.findExpired().size());

        List<Account> allAccounts = accountDAO.findAllStaff();
        req.setAttribute("accounts",       allAccounts);
        req.setAttribute("activeAccounts", allAccounts.stream()
                .filter(Account::isActive).count());

        java.util.Set<String> onlineStaffStr = new java.util.HashSet<>();
        for (Integer id : com.medivault.util.SessionTracker.getOnlineSet()) {
            onlineStaffStr.add(String.valueOf(id));
        }
        req.setAttribute("onlineStaff", onlineStaffStr);

        // ── Pending Reset Requests → hiện trong chuông thông báo ──
        List<PasswordResetRequest> pendingResets = resetDAO.findAllPending();
        req.setAttribute("pendingResets",     pendingResets);
        req.setAttribute("pendingResetCount", pendingResets.size());

        // Map accountId → Account để JSP hiện tên nhân viên
        java.util.Map<Integer, Account> resetAccountMap = new java.util.HashMap<>();
        List<Integer> blockedIds = resetDAO.findBlockedAccountIds();
        java.util.Map<Integer, Account> blockedAccountMap = new java.util.HashMap<>();
        for (Integer bid : blockedIds) {
            Account a = accountDAO.findById(bid);
            if (a != null) blockedAccountMap.put(bid, a);
        }
        req.setAttribute("blockedAccountMap", blockedAccountMap);
        for (PasswordResetRequest pr : pendingResets) {
            Account a = accountDAO.findById(pr.getAccountId());
            if (a != null) resetAccountMap.put(pr.getAccountId(), a);
        }
        req.setAttribute("resetAccountMap", resetAccountMap);

        req.getRequestDispatcher("/WEB-INF/views/dashboard.jsp").forward(req, resp);
    }
}