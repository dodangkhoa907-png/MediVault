package com.medicare.controller.admin;

import com.medicare.dao.AuditLogDAO;
import com.medicare.dao.interfaces.IAuditLogDAO;
import com.medicare.entity.Account;
import com.medicare.entity.AuditLog;
import com.medicare.util.SidebarHelper;
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
        int pageSize = 100; // tải nhiều hơn để lọc theo Role/Nhân viên/Loại phía client cho đủ dữ liệu
        String pageStr = req.getParameter("page");
        String keyword = req.getParameter("search");
        String fromDate = req.getParameter("from");
        String toDate   = req.getParameter("to");

        if (pageStr != null && !pageStr.isEmpty()) {
            try { page = Integer.parseInt(pageStr); }
            catch (NumberFormatException ignored) { page = 1; }
        }

        List<AuditLog> logs  = auditLogDAO.findPaginated(page, pageSize, keyword, fromDate, toDate);
        int total            = auditLogDAO.countAll(keyword, fromDate, toDate);
        int totalPages       = (int) Math.ceil((double) total / pageSize);
        if (totalPages < 1) totalPages = 1;

        req.setAttribute("auditLogs",     logs);
        req.setAttribute("currentPage",   page);
        req.setAttribute("totalPages",    totalPages);
        req.setAttribute("searchKeyword", keyword);
        req.setAttribute("filterFrom",    fromDate);
        req.setAttribute("filterTo",      toDate);

        com.medicare.dao.interfaces.IAccountDAO accountDAO = new com.medicare.dao.AccountDAO();
        com.medicare.dao.interfaces.IPasswordResetDAO resetDAO = new com.medicare.dao.PasswordResetDAO();

        // Tất cả tài khoản (gồm admin) — cho dropdown lọc theo người + map role.
        // Cache 30s (giống pattern reference-data ở MedicineServlet): chuyển tab liên tục
        // dùng lại cache thay vì SELECT * FROM Accounts mỗi lần.
        java.util.List<com.medicare.entity.Account> allAccounts =
                com.medicare.config.CacheManager.getShort("audit.allAccounts", accountDAO::findAll);
        java.util.Map<Integer,Integer> roleMap = new java.util.HashMap<>();
        for (com.medicare.entity.Account a : allAccounts) roleMap.put(a.getAccountId(), a.getRoleId());
        req.setAttribute("auditAccounts", allAccounts);
        req.setAttribute("auditRoleMap", roleMap);
        req.setAttribute("activeAccounts", (long) allAccounts.stream()
                .filter(com.medicare.entity.Account::isActive).count());
        req.setAttribute("todayRevenue",   0L);
        req.setAttribute("todayInvoices",  0);
        // expiryCount KHÔNG set thủ công ở đây — để SidebarHelper.load(req) bên dưới set qua
        // cache 30s dùng chung với sidebar (trước đây gọi thẳng batchesDAO.findExpiringSoon()
        // ở đây khiến cache của SidebarHelper bị vô hiệu hoá, full-scan bảng Batches mỗi lần).

        java.util.List<com.medicare.entity.PasswordResetRequest> pendingResets = resetDAO.findAllPending();
        req.setAttribute("pendingResets",     pendingResets);
        req.setAttribute("pendingResetCount", pendingResets.size());
        java.util.Map<Integer, com.medicare.entity.Account> resetAccountMap = new java.util.HashMap<>();
        java.util.Set<Integer> resetAccountIds = new java.util.HashSet<>();
        for (com.medicare.entity.PasswordResetRequest pr : pendingResets) resetAccountIds.add(pr.getAccountId());
        if (!resetAccountIds.isEmpty()) {
            for (com.medicare.entity.Account a : accountDAO.findAccountsByIds(new java.util.ArrayList<>(resetAccountIds))) {
                resetAccountMap.put(a.getAccountId(), a);
            }
        }
        req.setAttribute("resetAccountMap", resetAccountMap);
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/admin/audit-log-list.jsp").forward(req, resp);
    }
}