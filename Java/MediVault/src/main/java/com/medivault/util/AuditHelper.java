package com.medivault.util;

import com.medivault.dao.AuditLogDAO;
import com.medivault.dao.interfaces.IAuditLogDAO;
import com.medivault.entity.Account;
import com.medivault.entity.AuditLog;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;

/**
 * AuditHelper — Tiện ích ghi nhật ký.
 *
 * Dùng ở mọi Servlet:
 *   AuditHelper.log(req, "Tạo tài khoản", "Account", null, "Tạo @khanh - Dược sĩ");
 *   AuditHelper.log(req, "Xóa tài khoản", "Account", 5,   "Xóa @khanh");
 */
public class AuditHelper {

    private static IAuditLogDAO getDao() { return new AuditLogDAO(); }

    /**
     * Ghi 1 dòng audit log.
     * @param req         HttpServletRequest (IP + session)
     * @param action      Hành động, VD: "Tạo tài khoản"
     * @param entityType  Mô-đun, VD: "Account", "Invoice"
     * @param entityId    ID của đối tượng (nullable)
     * @param description Chi tiết
     */
    public static void log(HttpServletRequest req,
                           String action, String entityType,
                           Integer entityId, String description) {
        try {
            AuditLog entry = new AuditLog();
            entry.setAction(action);
            entry.setEntityType(entityType);
            entry.setEntityId(entityId);
            entry.setDescription(description);
            entry.setIpAddress(getIp(req));

            HttpSession session = req.getSession(false);
            if (session != null) {
                Account admin = (Account) session.getAttribute("adminAccount");
                if (admin != null) {
                    entry.setAccountId(admin.getAccountId());
                } else {
                    java.util.Enumeration<String> names = session.getAttributeNames();
                    while (names.hasMoreElements()) {
                        String name = names.nextElement();
                        if (name.startsWith("staffAccount_")) {
                            Object val = session.getAttribute(name);
                            if (val instanceof Account) {
                                entry.setAccountId(((Account) val).getAccountId());
                                break;
                            }
                        }
                    }
                }
            }

            getDao().insert(entry);
        } catch (Exception e) {
            System.err.println("[AuditHelper] Lỗi ghi log: " + e.getMessage());
        }
    }

    /** Overload không cần entityId — tự lấy accountId từ session */
    public static void log(HttpServletRequest req,
                           String action, String entityType, String description) {
        log(req, action, entityType, null, description);
    }

    /**
     * Overload truyền accountId trực tiếp — dùng khi gọi từ StaffLoginServlet,
     * LogoutServlet để tránh nhầm sang adminAccount trong cùng session.
     */
    public static void log(HttpServletRequest req,
                           String action, String entityType,
                           String description, int accountId) {
        try {
            AuditLog entry = new AuditLog();
            entry.setAction(action);
            entry.setEntityType(entityType);
            entry.setEntityId(null);
            entry.setDescription(description);
            entry.setIpAddress(getIp(req));
            entry.setAccountId(accountId);
            getDao().insert(entry);
        } catch (Exception e) {
            System.err.println("[AuditHelper] Lỗi ghi log: " + e.getMessage());
        }
    }

    private static String getIp(HttpServletRequest req) {
        String ip = req.getHeader("X-Forwarded-For");
        if (ip != null && !ip.isEmpty() && !"unknown".equalsIgnoreCase(ip))
            return ip.split(",")[0].trim();
        ip = req.getHeader("X-Real-IP");
        if (ip != null && !ip.isEmpty()) return ip;
        return req.getRemoteAddr();
    }
}