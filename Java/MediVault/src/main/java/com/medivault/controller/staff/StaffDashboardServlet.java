package com.medivault.controller.staff;

import com.medivault.dao.BatchesDAO;
import com.medivault.dao.MedicineDAO;
import com.medivault.dao.ShiftDAO;
import com.medivault.dao.StaffAuditLogDAO;
import com.medivault.dao.interfaces.IBatchesDAO;
import com.medivault.dao.interfaces.IMedicineDAO;
import com.medivault.dao.interfaces.IShiftDAO;
import com.medivault.dao.interfaces.IStaffAuditLogDAO;
import com.medivault.entity.Account;
import com.medivault.entity.Shift;
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

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String uid = req.getParameter("uid");
        if (uid == null || uid.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/staff-login");
            return;
        }

        HttpSession session = req.getSession(false);
        if (session == null) {
            resp.sendRedirect(req.getContextPath() + "/staff-login");
            return;
        }

        Account staffAcc = (Account) session.getAttribute("staffAccount_" + uid);
        if (staffAcc == null) {
            resp.sendRedirect(req.getContextPath() + "/staff-login");
            return;
        }
        if (staffAcc.getRoleId() == 1) {
            resp.sendRedirect(req.getContextPath() + "/dashboard");
            return;
        }

        // ── Toast messages ──
        String msg = req.getParameter("msg");
        if (msg != null) req.setAttribute("msg", msg);

        // ── Staff info ──
        req.setAttribute("staffUid",       uid);
        req.setAttribute("staffAcc",       staffAcc);

        // ── Inventory stats ──
        req.setAttribute("totalMedicines", medicineDAO.countAll());
        req.setAttribute("lowStockCount",  medicineDAO.countLowStock());
        req.setAttribute("expiryCount",    batchesDAO.findExpiringSoon().size());

        // ── Ca làm việc hiện tại ──
        Shift currentShift = shiftDAO.findCurrent(staffAcc.getAccountId());
        req.setAttribute("currentShift", currentShift);

        // ── Lịch sử ca gần nhất (3 ca) ──
        List<Shift> recentShifts = shiftDAO.findByAccount(staffAcc.getAccountId());
        // Bỏ ca đang mở ra khỏi lịch sử
        recentShifts.removeIf(s -> s.getEndTime() == null);
        req.setAttribute("recentShifts", recentShifts.subList(0, Math.min(3, recentShifts.size())));

        // ── Activity log ──
        req.setAttribute("recentLogs",
                staffAuditDAO.findRecentByAccount(staffAcc.getAccountId(), 10));

        req.getRequestDispatcher("/WEB-INF/views/staff/staff-dashboard.jsp")
                .forward(req, resp);
    }
}
