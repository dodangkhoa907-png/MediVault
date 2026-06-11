package com.medicare.controller;

import jakarta.servlet.annotation.WebListener;
import jakarta.servlet.http.*;

/**
 * SessionListener — Tự động gọi SessionTracker.logout() khi session expire/destroy.
 *
 * Giải quyết vấn đề: staff đóng tab không bấm logout
 * → session tự expire sau timeout → sessionDestroyed() được gọi
 * → xóa khỏi onlineStaff → dashboard hiển thị Offline đúng.
 *
 * Không cần contextInitialized/contextDestroyed vì AuthFilter không cần lifecycle hook.
 */
@WebListener
public class SessionListener implements HttpSessionListener {

    @Override
    public void sessionCreated(HttpSessionEvent se) {
        // Không cần xử lý — SessionTracker.login() đã được gọi trong StaffLoginServlet
    }

    @Override
    public void sessionDestroyed(HttpSessionEvent se) {
        HttpSession session = se.getSession();
        try {
            // Duyệt tất cả attribute trong session tìm "staffAccount_{id}"
            java.util.Enumeration<String> names = session.getAttributeNames();
            while (names.hasMoreElements()) {
                String name = names.nextElement();
                if (name.startsWith("staffAccount_")) {
                    Object val = session.getAttribute(name);
                    if (val instanceof com.medicare.entity.Account) {
                        com.medicare.entity.Account a = (com.medicare.entity.Account) val;
                        com.medicare.util.SessionTracker.logout(a.getAccountId());
                    }
                }
            }
        } catch (IllegalStateException e) {
            // Session đã invalidated — bỏ qua
        }
    }
}