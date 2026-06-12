package com.medicare.controller.admin;

import com.medicare.dao.AccountDAO;
import com.medicare.dao.PasswordResetDAO;
import com.medicare.dao.LeaveRequestDAO;
import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.dao.interfaces.IMedicineDAO;
import com.medicare.dao.interfaces.IBatchesDAO;
import com.medicare.dao.interfaces.IPasswordResetDAO;
import com.medicare.dao.interfaces.ILeaveRequestDAO;
import com.medicare.dao.MedicineDAO;
import com.medicare.dao.BatchesDAO;
import com.medicare.entity.Account;
import com.medicare.entity.PasswordResetRequest;
import com.medicare.util.SidebarHelper;
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
    private final ILeaveRequestDAO  leaveDAO    = new LeaveRequestDAO();

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
        for (Integer id : com.medicare.util.SessionTracker.getOnlineSet()) {
            onlineStaffStr.add(String.valueOf(id));
        }
        req.setAttribute("onlineStaff", onlineStaffStr);

        // ── Pending Reset Requests → hiện trong chuông thông báo ──
        List<PasswordResetRequest> pendingResets = resetDAO.findAllPending();
        req.setAttribute("pendingResets",     pendingResets);
        req.setAttribute("pendingResetCount", pendingResets.size());

        // ── Pending Leave Requests → badge trên nav ──
        int pendingLeaveCount = leaveDAO.findPending().size();
        req.setAttribute("pendingLeaveCount", pendingLeaveCount);

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

        SidebarHelper.load(req);


        req.getRequestDispatcher("/WEB-INF/views/admin/dashboard.jsp").forward(req, resp);
    }
}