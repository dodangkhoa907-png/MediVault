package com.medicare.util;

import com.medicare.dao.AttendanceDAO;
import com.medicare.dao.LeaveRequestDAO;
import com.medicare.dao.BatchesDAO;
import com.medicare.dao.PasswordResetDAO;
import com.medicare.dao.interfaces.IAttendanceDAO;
import com.medicare.dao.interfaces.ILeaveRequestDAO;
import com.medicare.dao.interfaces.IBatchesDAO;
import com.medicare.dao.interfaces.IPasswordResetDAO;
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
 */
public class SidebarHelper {

    private static final ILeaveRequestDAO leaveDAO   = new LeaveRequestDAO();
    private static final IAttendanceDAO   attDAO     = new AttendanceDAO();
    private static final IBatchesDAO      batchDAO   = new BatchesDAO();
    private static final IPasswordResetDAO resetDAO  = new PasswordResetDAO();

    public static void load(HttpServletRequest req) {
        try {
            // Chỉ load nếu chưa có (tránh double query khi Servlet đã set)
            if (req.getAttribute("pendingLeaveCount") == null) {
                req.setAttribute("pendingLeaveCount",
                        leaveDAO.findPending().size());
            }
            if (req.getAttribute("pendingLateCount") == null) {
                req.setAttribute("pendingLateCount",
                        attDAO.countByStatus("LATE_UNEXCUSED"));
            }
            if (req.getAttribute("expiryCount") == null) {
                req.setAttribute("expiryCount",
                        batchDAO.findExpiringSoon().size());
            }
            if (req.getAttribute("pendingResetCount") == null) {
                req.setAttribute("pendingResetCount",
                        resetDAO.findAllPending().size());
            }
        } catch (Exception e) {
            // Không để sidebar fail crash trang
            e.printStackTrace();
        }
    }
}