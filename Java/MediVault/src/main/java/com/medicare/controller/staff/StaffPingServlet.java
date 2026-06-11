package com.medicare.controller.staff;

import com.medicare.util.SessionTracker;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/staff-ping")
public class StaffPingServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        resp.setContentType("application/json;charset=UTF-8");
        // Không cache — luôn trả kết quả mới nhất
        resp.setHeader("Cache-Control", "no-store");

        String uidStr = req.getParameter("uid");
        String token  = req.getParameter("token");
        String tabId = req.getParameter("tabId");

        if (uidStr == null || token == null || uidStr.isEmpty() || token.isEmpty()) {
            resp.getWriter().print("{\"ok\":false,\"reason\":\"invalid\"}");
            return;
        }

        try {
            int uid = Integer.parseInt(uidStr);
            boolean valid = SessionTracker.isValidSession(uid, token, tabId);
            if (valid) {
                resp.getWriter().print("{\"ok\":true}");
            } else {
                // Token không khớp = tab mới đã login, tab này bị kick
                resp.getWriter().print("{\"ok\":false,\"reason\":\"kicked\"}");
            }
        } catch (NumberFormatException e) {
            resp.getWriter().print("{\"ok\":false,\"reason\":\"invalid\"}");
        }
    }
}