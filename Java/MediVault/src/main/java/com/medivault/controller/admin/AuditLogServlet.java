package com.medivault.controller.admin;

import com.medivault.dao.AuditLogDAO;
import com.medivault.dao.interfaces.IAuditLogDAO;
import com.medivault.entity.Account;
import com.medivault.entity.AuditLog;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import java.util.List;
import java.io.IOException;


@WebServlet("/audit-logs")
public class AuditLogServlet extends HttpServlet {

    private final IAuditLogDAO auditLogDAO = new AuditLogDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Chỉ admin mới được xem
        HttpSession _sess = req.getSession(false);
        Account adminAcc = _sess != null
                ? (Account) _sess.getAttribute("adminAccount") : null;
        if (adminAcc == null || adminAcc.getRoleId() != 1) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        int page = 1;
        int pageSize = 20;
        String pageStr = req.getParameter("page");
        String keyword = req.getParameter("search");

        if (pageStr != null && !pageStr.isEmpty()) {
            try { page = Integer.parseInt(pageStr); }
            catch (NumberFormatException ignored) { page = 1; }
        }

        List<AuditLog> logs  = auditLogDAO.findPaginated(page, pageSize, keyword);
        int total            = auditLogDAO.countAll(keyword);
        int totalPages       = (int) Math.ceil((double) total / pageSize);
        if (totalPages < 1) totalPages = 1;

        req.setAttribute("auditLogs",     logs);
        req.setAttribute("currentPage",   page);
        req.setAttribute("totalPages",    totalPages);
        req.setAttribute("searchKeyword", keyword);

        com.medivault.dao.interfaces.IAccountDAO accountDAO = new com.medivault.dao.AccountDAO();
        com.medivault.dao.interfaces.IBatchesDAO batchesDAO = new com.medivault.dao.BatchesDAO();
        com.medivault.dao.interfaces.IPasswordResetDAO resetDAO = new com.medivault.dao.PasswordResetDAO();

        java.util.List<com.medivault.entity.Account> allAccounts = accountDAO.findAllStaff();
        req.setAttribute("activeAccounts", (long) allAccounts.stream()
                .filter(com.medivault.entity.Account::isActive).count());
        req.setAttribute("expiryCount",    batchesDAO.findExpiringSoon().size());
        req.setAttribute("todayRevenue",   0L);
        req.setAttribute("todayInvoices",  0);

        java.util.List<com.medivault.entity.PasswordResetRequest> pendingResets = resetDAO.findAllPending();
        req.setAttribute("pendingResets",     pendingResets);
        req.setAttribute("pendingResetCount", pendingResets.size());
        java.util.Map<Integer, com.medivault.entity.Account> resetAccountMap = new java.util.HashMap<>();
        for (com.medivault.entity.PasswordResetRequest pr : pendingResets) {
            com.medivault.entity.Account a = accountDAO.findById(pr.getAccountId());
            if (a != null) resetAccountMap.put(pr.getAccountId(), a);
        }
        req.setAttribute("resetAccountMap", resetAccountMap);
        req.getRequestDispatcher("/WEB-INF/views/admin/audit-log-list.jsp").forward(req, resp);
    }
}