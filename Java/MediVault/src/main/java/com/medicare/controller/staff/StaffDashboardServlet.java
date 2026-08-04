package com.medicare.controller.staff;

import com.medicare.dao.*;
import com.medicare.dao.interfaces.*;
import com.medicare.entity.*;
import com.medicare.util.NotificationUtil;
import com.medicare.dao.StaffNotificationDAO;
import com.medicare.util.StaffNotifHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.util.List;

@WebServlet("/staff-dashboard")
public class StaffDashboardServlet extends HttpServlet {

    private final IMedicineDAO      medicineDAO   = new MedicineDAO();
    private final IBatchesDAO       batchesDAO    = new BatchesDAO();
    private final IStaffAuditLogDAO staffAuditDAO = new StaffAuditLogDAO();
    private final IShiftDAO         shiftDAO      = new ShiftDAO();
    private final IShiftScheduleDAO scheduleDAO   = new ShiftScheduleDAO();
    private final IAttendanceDAO    attendanceDAO = new AttendanceDAO();
    private final StaffNotificationDAO staffNotifDAO = new StaffNotificationDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String uid = req.getParameter("uid");
        if (uid == null || uid.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/staff-login"); return;
        }
        HttpSession session = req.getSession(false);
        if (session == null) {
            resp.sendRedirect(req.getContextPath() + "/staff-login"); return;
        }
        Account staffAcc = (Account) session.getAttribute("staffAccount_" + uid);
        if (staffAcc == null) {
            resp.sendRedirect(req.getContextPath() + "/staff-login"); return;
        }
        if (staffAcc.getRoleId() == 1) {
            resp.sendRedirect(req.getContextPath() + "/dashboard"); return;
        }
        // roleId 3 (Thủ kho = Quản lý kho) có portal riêng. URL sạch, KHÔNG kèm ?uid= —
        // portal Kho lấy danh tính từ session (WarehouseAuth), và id tài khoản không được
        // để lộ trên thanh địa chỉ / lịch sử trình duyệt của máy dùng chung.
        if (staffAcc.getRoleId() == 3) {
            com.medicare.util.WarehouseAuth.login(session, staffAcc);
            resp.sendRedirect(req.getContextPath() + "/warehouse-dashboard"); return;
        }

        req.setAttribute("staffUid", uid);
        req.setAttribute("staffAcc", staffAcc);

        // Inventory stats
        req.setAttribute("totalMedicines", medicineDAO.countAll());
        req.setAttribute("lowStockCount",  medicineDAO.countLowStock());
        req.setAttribute("expiryCount",    batchesDAO.findExpiringSoon().size());

        // Ca làm việc hiện tại
        Shift currentShift = shiftDAO.findCurrent(staffAcc.getAccountId());
        req.setAttribute("currentShift", currentShift);

        // Attendance đang active (check-in chưa check-out)
        // Dùng để hiển thị trạng thái "Đang làm việc" kể cả khi Shift chưa mở
        Attendance activeAtt = attendanceDAO.findActiveByAccount(staffAcc.getAccountId());
        req.setAttribute("activeAtt", activeAtt);

        // Lịch sử ca gần nhất (3 ca đã đóng)
        List<Shift> recentShifts = shiftDAO.findByAccount(staffAcc.getAccountId());
        recentShifts.removeIf(s -> s.isOpen());
        req.setAttribute("recentShifts",
                recentShifts.subList(0, Math.min(3, recentShifts.size())));

        // ── Lịch ca sắp tới (7 ngày) — hiển thị widget ──
        req.setAttribute("upcomingSchedules",
                scheduleDAO.findUpcoming(staffAcc.getAccountId(), 7));

        // ── Lịch ca hôm nay ──
        req.setAttribute("todaySchedule",
                scheduleDAO.findTodaySchedule(staffAcc.getAccountId()));

        // Activity log
        req.setAttribute("recentLogs",
                staffAuditDAO.findRecentByAccount(staffAcc.getAccountId(), 10));

        // ── Staff notifications (đơn nghỉ được duyệt/từ chối hôm nay) ──
        NotificationUtil.loadStaffNotifications(req, staffAcc.getAccountId());

        // ── Staff notifications (bell) ──
        req.setAttribute("staffNotifications", staffNotifDAO.findUnread(staffAcc.getAccountId()));
        req.setAttribute("staffNotifCount",    staffNotifDAO.countUnread(staffAcc.getAccountId()));

        // ── Shift reminder: nếu có ca trong 30 phút tới → tạo reminder ──
        @SuppressWarnings("unchecked")
        java.util.List<ShiftSchedule> upcoming =
                (java.util.List<ShiftSchedule>) req.getAttribute("upcomingSchedules");
        if (upcoming != null) {
            java.time.LocalDateTime now = java.time.LocalDateTime.now();
            for (ShiftSchedule ts : upcoming) {
                if (ts.getPlannedStart() != null && "SCHEDULED".equals(ts.getStatus())) {
                    long minUntil = java.time.Duration.between(now, ts.getPlannedStart()).toMinutes();
                    if (minUntil > 0 && minUntil <= 15) {
                        StaffNotifHelper.shiftReminder(staffAcc.getAccountId(),
                                ts.getShiftTypeName(),
                                ts.getPlannedStart().toLocalTime().toString().substring(0,5));
                    }
                }
            }
        }

        req.getRequestDispatcher("/WEB-INF/views/staff/staff-dashboard.jsp")
                .forward(req, resp);
    }
}