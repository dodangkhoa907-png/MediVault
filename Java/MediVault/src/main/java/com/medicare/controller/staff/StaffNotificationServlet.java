package com.medicare.controller.staff;

import com.medicare.dao.StaffNotificationDAO;
import com.medicare.dao.StaffNotificationDAO.Notif;
import com.medicare.entity.Account;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

/**
 * StaffNotificationServlet — API JSON cho notification bell.
 * GET  /staff-notifications?uid=X         → lấy thông báo chưa đọc (JSON)
 * POST /staff-notifications?action=read&id=Y&uid=X  → đánh dấu đã đọc
 * POST /staff-notifications?action=readAll&uid=X     → đánh dấu tất cả
 */
@WebServlet("/staff-notifications")
public class StaffNotificationServlet extends HttpServlet {

    private final StaffNotificationDAO dao = new StaffNotificationDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Account staff = getStaff(req);
        if (staff == null) { resp.setStatus(401); return; }

        List<Notif> unread = dao.findUnread(staff.getAccountId());
        int count = unread.size();

        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        StringBuilder sb = new StringBuilder();
        sb.append("{\"count\":").append(count).append(",\"items\":[");
        for (int i = 0; i < unread.size(); i++) {
            Notif n = unread.get(i);
            if (i > 0) sb.append(",");
            sb.append("{");
            sb.append("\"id\":").append(n.getId()).append(",");
            sb.append("\"type\":\"").append(esc(n.getType())).append("\",");
            sb.append("\"title\":\"").append(esc(n.getTitle())).append("\",");
            sb.append("\"message\":\"").append(esc(n.getMessage())).append("\",");
            sb.append("\"createdAt\":\"").append(n.getCreatedAt() != null ? n.getCreatedAt().toString() : "").append("\"");
            sb.append("}");
        }
        sb.append("]}");
        out.print(sb);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        Account staff = getStaff(req);
        if (staff == null) { resp.setStatus(401); return; }

        String action = req.getParameter("action");
        resp.setContentType("application/json;charset=UTF-8");

        if ("read".equals(action)) {
            int id = 0;
            try { id = Integer.parseInt(req.getParameter("id")); } catch (Exception e) {}
            boolean ok = dao.markRead(id, staff.getAccountId());
            resp.getWriter().print("{\"ok\":" + ok + "}");
        } else if ("readAll".equals(action)) {
            int count = dao.markAllRead(staff.getAccountId());
            resp.getWriter().print("{\"ok\":true,\"count\":" + count + "}");
        }
    }

    private Account getStaff(HttpServletRequest req) {
        String uid = req.getParameter("uid");
        if (uid == null) return null;
        HttpSession session = req.getSession(false);
        if (session == null) return null;
        return (Account) session.getAttribute("staffAccount_" + uid);
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\","\\\\").replace("\"","\\\"").replace("\n"," ").replace("\r","");
    }
}