package com.medivault.util;

import com.medivault.dao.LeaveRequestDAO;
import com.medivault.dao.PasswordResetDAO;
import com.medivault.dao.interfaces.ILeaveRequestDAO;
import com.medivault.dao.interfaces.IPasswordResetDAO;
import jakarta.servlet.http.HttpServletRequest;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * NotificationUtil — load tất cả badge/notification cho admin.
 *
 * Gọi loadAdminNotifications(req) từ mọi servlet admin để có:
 * - pendingLeaveCount   → badge chuông xin nghỉ
 * - pendingResetCount   → badge chuông reset mật khẩu
 * - totalNotifCount     → tổng badge chuông
 * - notifications       → List<Map> cho dropdown popup
 */
public class NotificationUtil {

    private static final ILeaveRequestDAO leaveDAO = new LeaveRequestDAO();
    private static final IPasswordResetDAO resetDAO = new PasswordResetDAO();

    /** Gọi từ mọi Servlet admin — set attributes cho JSP */
    public static void loadAdminNotifications(HttpServletRequest req) {
        try {
            int leaveCount = leaveDAO.findPending().size();
            int resetCount = 0;
            try { resetCount = resetDAO.findAllPending().size(); } catch (Exception ignored) {}

            int total = leaveCount + resetCount;

            req.setAttribute("pendingLeaveCount", leaveCount);
            req.setAttribute("pendingResetCount", resetCount);
            req.setAttribute("totalNotifCount",   total);

            // Build notification list cho dropdown
            List<Map<String, Object>> notifs = new ArrayList<>();

            if (leaveCount > 0) {
                Map<String, Object> n = new LinkedHashMap<>();
                n.put("icon",  "🏖️");
                n.put("title", leaveCount + " đơn xin nghỉ chờ duyệt");
                n.put("sub",   "Nhấn để xem và duyệt");
                n.put("link",  req.getContextPath() + "/leave-requests?action=pending");
                n.put("badge", "badge-amber");
                notifs.add(n);
            }

            if (resetCount > 0) {
                Map<String, Object> n = new LinkedHashMap<>();
                n.put("icon",  "🔐");
                n.put("title", resetCount + " yêu cầu đặt lại mật khẩu");
                n.put("sub",   "Nhấn để xử lý");
                n.put("link",  req.getContextPath() + "/accounts?action=reset-requests");
                n.put("badge", "badge-red");
                notifs.add(n);
            }

            if (notifs.isEmpty()) {
                Map<String, Object> n = new LinkedHashMap<>();
                n.put("icon",  "✅");
                n.put("title", "Không có thông báo mới");
                n.put("sub",   "");
                n.put("link",  "#");
                n.put("badge", "badge-gray");
                notifs.add(n);
            }

            req.setAttribute("notifications", notifs);
        } catch (Exception e) {
            e.printStackTrace();
            req.setAttribute("pendingLeaveCount", 0);
            req.setAttribute("pendingResetCount", 0);
            req.setAttribute("totalNotifCount",   0);
        }
    }

    /** Gọi từ Staff servlet — set thông báo cho nhân viên */
    public static void loadStaffNotifications(HttpServletRequest req, int accountId) {
        try {
            // Đơn xin nghỉ vừa được duyệt/từ chối
            java.time.LocalDate now = java.time.LocalDate.now();
            List<com.medivault.entity.LeaveRequest> recent =
                    leaveDAO.findByAccountAndMonth(accountId, now.getMonthValue(), now.getYear());

            long approvedToday = recent.stream()
                    .filter(lr -> lr.isApproved()
                            && lr.getApprovedAt() != null
                            && lr.getApprovedAt().toLocalDate().equals(now))
                    .count();

            long rejectedToday = recent.stream()
                    .filter(lr -> lr.isRejected()
                            && lr.getApprovedAt() != null
                            && lr.getApprovedAt().toLocalDate().equals(now))
                    .count();

            long pendingCount = recent.stream().filter(lr -> lr.isPending()).count();

            req.setAttribute("staffApprovedToday",  approvedToday);
            req.setAttribute("staffRejectedToday",  rejectedToday);
            req.setAttribute("staffPendingLeave",   pendingCount);
            req.setAttribute("staffLeaveNotifCount", approvedToday + rejectedToday);
            req.setAttribute("staffLeaveRecent",    recent);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}