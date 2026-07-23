package com.medicare.controller.warehouse;

import com.medicare.dao.*;
import com.medicare.dao.interfaces.*;
import com.medicare.entity.Account;
import com.medicare.entity.Attendance;
import com.medicare.entity.Shift;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;

/**
 * WarehouseDashboardServlet — Trang làm việc RIÊNG của Quản lý kho (roleId 3 = Thủ kho).
 * URL: /warehouse-dashboard?uid=&lt;id&gt;
 *
 * <p>Chỉ roleId 3 vào được. roleId 1 → /dashboard; roleId 2 (Dược sĩ bán hàng) → /staff-dashboard.</p>
 *
 * <p>Tập trung số liệu tồn kho + hành động nhanh (nhập kho quét barcode, bán hàng POS,
 * ca làm việc). Dùng chung cache 3 phút với admin cho các đếm nặng.</p>
 */
@WebServlet("/warehouse-dashboard")
public class WarehouseDashboardServlet extends HttpServlet {

    private static final int ROLE_WAREHOUSE = 3;

    private final IMedicineDAO      medicineDAO   = new MedicineDAO();
    private final IBatchesDAO       batchesDAO    = new BatchesDAO();
    private final IShiftDAO         shiftDAO      = new ShiftDAO();
    private final IAttendanceDAO    attendanceDAO = new AttendanceDAO();
    private final IShiftScheduleDAO scheduleDAO   = new ShiftScheduleDAO();
    private final com.medicare.dao.interfaces.ITaskDAO taskDAO = new com.medicare.dao.TaskDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String uid = req.getParameter("uid");
        if (uid == null || uid.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login"); return;
        }
        HttpSession session = req.getSession(false);
        if (session == null) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login"); return;
        }
        Account acc = (Account) session.getAttribute("staffAccount_" + uid);
        if (acc == null) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login"); return;
        }
        // Phân luồng đúng portal theo role
        if (acc.getRoleId() == 1) {
            resp.sendRedirect(req.getContextPath() + "/dashboard"); return;
        }
        if (acc.getRoleId() != ROLE_WAREHOUSE) {
            resp.sendRedirect(req.getContextPath() + "/staff-dashboard?uid=" + uid); return;
        }

        req.setAttribute("staffUid", uid);
        req.setAttribute("staffAcc", acc);

        // ── Số liệu tồn kho (cache 3 phút — dùng chung key với admin dashboard) ──
        req.setAttribute("totalMedicines",
                com.medicare.config.CacheManager.get("dash.totalMed", medicineDAO::countAll));
        req.setAttribute("lowStockCount",
                com.medicare.config.CacheManager.get("dash.lowStock", medicineDAO::countLowStock));
        req.setAttribute("expiryCount",
                com.medicare.config.CacheManager.get("dash.expiry", () -> batchesDAO.findExpiringSoon().size()));
        req.setAttribute("expiredCount",
                com.medicare.config.CacheManager.get("dash.expired", () -> batchesDAO.findExpired().size()));

        // ── Ca làm việc hiện tại + trạng thái điểm danh ──
        Shift currentShift = shiftDAO.findCurrent(acc.getAccountId());
        req.setAttribute("currentShift", currentShift);
        Attendance activeAtt = attendanceDAO.findActiveByAccount(acc.getAccountId());
        req.setAttribute("activeAtt", activeAtt);

        // ── Lịch ca sắp tới (7 ngày) — hiển thị widget lịch tuần, giống staff-dashboard ──
        req.setAttribute("upcomingSchedules",
                scheduleDAO.findUpcoming(acc.getAccountId(), 7));

        // ── Badge "Nhiệm vụ & SOP" trên sidebar (task của tôi + task chung chưa ai nhận) ──
        req.setAttribute("myOpenTaskCount", taskDAO.countMyOpenTasks(acc.getAccountId()));

        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-dashboard.jsp")
                .forward(req, resp);
    }
}
