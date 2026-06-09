package com.medivault.controller.admin;

import com.medivault.dao.AccountDAO;
import com.medivault.dao.PasswordResetDAO;
import com.medivault.dao.interfaces.IAccountDAO;
import com.medivault.dao.interfaces.IPasswordResetDAO;
import com.medivault.entity.Account;
import com.medivault.entity.PasswordResetRequest;
import com.medivault.util.AuditHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

/**
 * Endpoint cho realtime polling từ dashboard.jsp:
 *   GET /admin/reset-requests?action=count   → JSON {count, latestName}
 *   GET /admin/reset-requests?action=list-html → HTML snippet notif items
 */
@WebServlet("/admin/reset-requests")
public class ResetRequestServlet extends HttpServlet {

    private final IPasswordResetDAO resetDAO  = new PasswordResetDAO();
    private final IAccountDAO       accountDAO = new AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Chỉ admin mới được gọi
        HttpSession session = req.getSession(false);
        Account admin = session != null ? (Account) session.getAttribute("adminAccount") : null;
        if (admin == null || admin.getRoleId() != 1) {
            resp.setStatus(403); return;
        }

        String action = req.getParameter("action");
        if ("count".equals(action)) {
            handleCount(req, resp);
        } else if ("list-html".equals(action)) {
            handleListHtml(req, resp);
        } else if ("unlock-reset".equals(action)) {   // ← THÊM VÀO ĐÂY
            int accountId = Integer.parseInt(req.getParameter("id"));
            resetDAO.resetTodayCount(accountId);
            AuditHelper.log(req, "Mở khóa gửi lại forgot-password", "Auth", accountId,
                    "Admin cho phép @" + accountId + " gửi lại yêu cầu reset MK");
            resp.sendRedirect(req.getContextPath() + "/dashboard?msg=reset-unblocked");
        } else {
            resp.setStatus(400);
        }
    }

    private void handleCount(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        List<PasswordResetRequest> list = resetDAO.findAllPending();
        String latestName = "";
        if (!list.isEmpty()) {
            Account a = accountDAO.findById(list.get(0).getAccountId());
            latestName = a != null ? esc(a.getFullName()) : "";
        }
        PrintWriter out = resp.getWriter();
        out.print("{\"count\":" + list.size() + ",\"latestName\":\"" + latestName + "\"}");
    }

    private void handleListHtml(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("text/html;charset=UTF-8");
        List<PasswordResetRequest> list = resetDAO.findAllPending();
        PrintWriter out = resp.getWriter();
        String ctx = req.getContextPath();

        for (PasswordResetRequest pr : list) {
            Account staff = accountDAO.findById(pr.getAccountId());
            String name = staff != null ? esc(staff.getFullName()) : ("ID " + pr.getAccountId());
            String user = staff != null ? esc(staff.getUsername()) : "";
            String editUrl = ctx + "/accounts?action=edit&id=" + pr.getAccountId();
            boolean confirmed = "CONFIRMED".equals(pr.getStatus());
            String badgeHtml = confirmed
                    ? "<span class='notif-status-badge'>Đã xác nhận</span>"
                    : "<span class='notif-status-badge notif-badge-pending'>Chờ xử lý</span>";

            out.println("<a href='" + editUrl + "' class='notif-item notif-item-reset' style='text-decoration:none;display:flex'>");
            out.println("  <div class='notif-dot notif-dot-amber'></div>");
            out.println("  <div style='flex:1'>");
            out.println("    <div class='notif-text'>🔐 <strong>" + name + "</strong> yêu cầu đổi mật khẩu " + badgeHtml + "</div>");
            out.println("    <div class='notif-time'>@" + user + " • Bấm để đặt mật khẩu mới</div>");
            out.println("  </div><span class='notif-arrow'>→</span></a>");
        }

        // Giữ lại item login (không xóa)
        // Phần còn lại (thuốc hết hạn, login time) giữ nguyên — JS chỉ prepend reset items
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
                .replace("\"","&quot;").replace("'","&#x27;");
    }
}