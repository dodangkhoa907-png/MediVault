package com.medicare.util;

import com.medicare.dao.AttendanceDAO;
import com.medicare.dao.LeaveRequestDAO;
import com.medicare.dao.BatchesDAO;
import com.medicare.dao.PasswordResetDAO;
import com.medicare.dao.TaskDAO;
import com.medicare.dao.interfaces.IAttendanceDAO;
import com.medicare.dao.interfaces.ILeaveRequestDAO;
import com.medicare.dao.interfaces.IBatchesDAO;
import com.medicare.dao.interfaces.IPasswordResetDAO;
import com.medicare.dao.interfaces.ITaskDAO;
import jakarta.servlet.http.HttpServletRequest;

/**
 * SidebarHelper — Load tất cả badge counts cho sidebar admin.
 * Gọi ở cuối mỗi Servlet.doGet() trước khi forward JSP:
 *   SidebarHelper.load(req);
 *
 * Set các attributes:
 *   pendingLeaveCount  — đơn nghỉ phép chờ duyệt
 *   pendingLateCount   — điểm danh trễ chờ duyệt (LATE_UNEXCUSED)
 *   pendingResetCount  — yêu cầu reset mật khẩu chờ duyệt
 *   expiryCount        — thuốc sắp hết hạn
 *   taskWatchdogCount  — task/dự án Thủ kho sắp/đã quá hạn báo xong (≤48h)
 */
public class SidebarHelper {

    private static final ILeaveRequestDAO leaveDAO   = new LeaveRequestDAO();
    private static final IAttendanceDAO   attDAO     = new AttendanceDAO();
    private static final IBatchesDAO      batchDAO   = new BatchesDAO();
    private static final IPasswordResetDAO resetDAO  = new PasswordResetDAO();
    private static final ITaskDAO         taskDAO    = new TaskDAO();

    public static void load(HttpServletRequest req) {
        // Mỗi badge được wrap riêng — 1 bảng chưa tạo không crash cả sidebar.
        // Cache 30s (CacheManager.getShort): chuyển trang liên tục dùng cache thay vì
        // query lại 4 lần/trang → hết lag, nhẹ pool. Trễ tối đa 30s là chấp nhận được.

        if (req.getAttribute("pendingLeaveCount") == null) {
            try {
                req.setAttribute("pendingLeaveCount",
                        com.medicare.config.CacheManager.getShort("sidebar.pendingLeave",
                                () -> leaveDAO.findPending().size()));
            } catch (Exception e) {
                req.setAttribute("pendingLeaveCount", 0);
                System.err.println("[SidebarHelper] pendingLeave: " + e.getMessage());
            }
        }

        if (req.getAttribute("pendingLateCount") == null) {
            try {
                req.setAttribute("pendingLateCount",
                        com.medicare.config.CacheManager.getShort("sidebar.pendingLate",
                                () -> attDAO.countByStatus("LATE_UNEXCUSED")));
            } catch (Exception e) {
                req.setAttribute("pendingLateCount", 0);
                System.err.println("[SidebarHelper] pendingLate: " + e.getMessage());
            }
        }

        if (req.getAttribute("expiryCount") == null) {
            try {
                req.setAttribute("expiryCount",
                        com.medicare.config.CacheManager.getShort("sidebar.expiryCount",
                                () -> batchDAO.findExpiringSoon().size()));
            } catch (Exception e) {
                req.setAttribute("expiryCount", 0);
                System.err.println("[SidebarHelper] expiryCount: " + e.getMessage());
            }
        }

        if (req.getAttribute("pendingResetCount") == null) {
            try {
                req.setAttribute("pendingResetCount",
                        com.medicare.config.CacheManager.getShort("sidebar.pendingReset",
                                () -> resetDAO.findAllPending().size()));
            } catch (Exception e) {
                // Bảng PasswordResetRequests chưa tạo → set 0, không crash
                req.setAttribute("pendingResetCount", 0);
                System.err.println("[SidebarHelper] pendingReset (table missing?): " + e.getMessage());
            }
        }

        if (req.getAttribute("taskWatchdogCount") == null) {
            try {
                req.setAttribute("taskWatchdogCount",
                        com.medicare.config.CacheManager.getShort("sidebar.taskWatchdog",
                                () -> taskDAO.findWatchdog().size()));
            } catch (Exception e) {
                // Cột IsProject/ParentTaskID/... chưa migrate → set 0, không crash
                req.setAttribute("taskWatchdogCount", 0);
                System.err.println("[SidebarHelper] taskWatchdog (chưa chạy tasks_projects_migration.sql?): " + e.getMessage());
            }
        }
    }

    /**
     * Badge cho sidebar portal Kho (warehouse-sidebar.jsp): "Quản lý tồn kho" (expiryCount)
     * và "Nhiệm vụ &amp; SOP" (myOpenTaskCount, riêng theo từng thủ kho).
     *
     * Trước đây mỗi servlet Kho tự set 2 attribute này rời rạc — Dashboard và Task set đủ,
     * còn Inventory/StockMovement/Reorder/Recall/Import/Profile thiếu myOpenTaskCount (có
     * trang còn thiếu cả expiryCount), nên badge "Nhiệm vụ & SOP" HIỆN ở trang chủ rồi
     * BIẾN MẤT ngay khi chuyển sang trang khác — không phải do hết việc, mà do trang đó
     * không set attribute nên sidebar coi như null. Gọi đúng 1 hàm này ở mọi trang Kho để
     * badge nhất quán bất kể đang đứng ở trang nào.
     */
    public static void loadWarehouse(HttpServletRequest req, int warehouseAccountId) {
        load(req); // expiryCount (+ các badge admin khác, vô hại nếu trang Kho không dùng tới)

        if (req.getAttribute("myOpenTaskCount") == null) {
            try {
                req.setAttribute("myOpenTaskCount", taskDAO.countMyOpenTasks(warehouseAccountId));
            } catch (Exception e) {
                req.setAttribute("myOpenTaskCount", 0);
                System.err.println("[SidebarHelper] myOpenTaskCount: " + e.getMessage());
            }
        }
    }
}