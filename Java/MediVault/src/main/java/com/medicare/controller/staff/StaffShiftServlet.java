package com.medicare.controller.staff;

import com.medicare.dao.ShiftDAO;
import com.medicare.dao.ShiftScheduleDAO;
import com.medicare.dao.interfaces.IShiftDAO;
import com.medicare.dao.interfaces.IShiftScheduleDAO;
import com.medicare.dao.AttendanceDAO;
import com.medicare.dao.interfaces.IAttendanceDAO;
import com.medicare.entity.Account;
import com.medicare.entity.Shift;
import com.medicare.util.AuditHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.List;

/**
 * StaffShiftServlet — Nhân viên xem / mở / đóng ca của mình.
 * GET  /staff-my-shifts?uid={staffId}    → hiện trang ca làm việc
 * POST /staff-shift?action=open|close&uid={staffId} → xử lý mở/đóng
 */
@WebServlet(urlPatterns = {"/staff-my-shifts", "/staff-shift"})
public class StaffShiftServlet extends HttpServlet {

    private final IShiftDAO         shiftDAO     = new ShiftDAO();
    private final IShiftScheduleDAO scheduleDAO  = new ShiftScheduleDAO();
    private final IAttendanceDAO    attDAO       = new AttendanceDAO();

    // ── GET: hiện trang xem ca ────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String uid = req.getParameter("uid");
        if (uid == null || uid.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/staff-login");
            return;
        }

        HttpSession session = req.getSession(false);
        Account staffAcc = session != null
                ? (Account) session.getAttribute("staffAccount_" + uid) : null;
        if (staffAcc == null) {
            resp.sendRedirect(req.getContextPath() + "/staff-login");
            return;
        }
        if (staffAcc.getRoleId() == 1) {
            resp.sendRedirect(req.getContextPath() + "/dashboard");
            return;
        }

        // Ca đang mở
        Shift currentShift = shiftDAO.findCurrent(staffAcc.getAccountId());
        req.setAttribute("currentShift", currentShift);

        // Lịch ca hôm nay (để hiện widget)
        req.setAttribute("todaySchedule",
                scheduleDAO.findTodaySchedule(staffAcc.getAccountId()));

        // Toàn bộ lịch sử ca (mới nhất trước)
        List<Shift> allShifts = shiftDAO.findByAccount(staffAcc.getAccountId());
        req.setAttribute("allShifts", allShifts);

        req.getRequestDispatcher("/WEB-INF/views/staff/staff-my-shifts.jsp")
                .forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        String uid = req.getParameter("uid");
        if (uid == null || uid.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/staff-login");
            return;
        }

        HttpSession session = req.getSession(false);
        Account staffAcc = session != null
                ? (Account) session.getAttribute("staffAccount_" + uid) : null;
        if (staffAcc == null) {
            resp.sendRedirect(req.getContextPath() + "/staff-login");
            return;
        }

        String action = req.getParameter("action");

        if ("open".equals(action)) {
            handleOpen(req, resp, staffAcc, uid);
        } else if ("close".equals(action)) {
            handleClose(req, resp, staffAcc, uid);
        } else {
            resp.sendRedirect(req.getContextPath() + "/staff-dashboard?uid=" + uid);
        }
    }

    // ── Mở ca ────────────────────────────────────────────────────────────────
    private void handleOpen(HttpServletRequest req, HttpServletResponse resp,
                            Account staffAcc, String uid) throws IOException {
        BigDecimal openingCash = parseCash(req.getParameter("openingCash"));

        // FIX 5: không cho mở ca khi Attendance chưa check-out
        if (attDAO.findActiveByAccount(staffAcc.getAccountId()) == null
                && shiftDAO.findCurrent(staffAcc.getAccountId()) != null) {
            resp.sendRedirect(req.getContextPath() + "/staff-my-shifts?uid=" + uid + "&msg=already-open");
            return;
        }

        boolean ok = shiftDAO.openShift(staffAcc.getAccountId(), openingCash);

        if (ok) {
            AuditHelper.log(req, "Mở ca làm việc", "Shift",
                    "Staff @" + staffAcc.getUsername() + " mở ca — tiền đầu ca: " + openingCash,
                    staffAcc.getAccountId());
        }

        String msg = ok ? "opened" : "already-open";
        resp.sendRedirect(req.getContextPath() + "/staff-my-shifts?uid=" + uid + "&msg=" + msg);
    }

    // ── Đóng ca ───────────────────────────────────────────────────────────────
    private void handleClose(HttpServletRequest req, HttpServletResponse resp,
                             Account staffAcc, String uid) throws IOException {
        String shiftIdStr  = req.getParameter("shiftId");
        String closingCashStr = req.getParameter("closingCash");
        String notes       = req.getParameter("notes");

        // FIX 4: validate closingCash bắt buộc
        if (closingCashStr == null || closingCashStr.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/staff-my-shifts?uid=" + uid + "&msg=need-cash");
            return;
        }
        BigDecimal closingCash = parseCash(closingCashStr);

        if (shiftIdStr == null || shiftIdStr.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/staff-dashboard?uid=" + uid + "&msg=error");
            return;
        }

        int shiftId;
        try { shiftId = Integer.parseInt(shiftIdStr); }
        catch (NumberFormatException e) {
            resp.sendRedirect(req.getContextPath() + "/staff-dashboard?uid=" + uid + "&msg=error");
            return;
        }

        // Kiểm tra ca thuộc về nhân viên này
        Shift shift = shiftDAO.findById(shiftId);
        if (shift == null || shift.getAccountId() != staffAcc.getAccountId()) {
            resp.sendRedirect(req.getContextPath() + "/staff-dashboard?uid=" + uid + "&msg=error");
            return;
        }

        boolean ok = shiftDAO.closeShift(shiftId, closingCash, notes);

        if (ok) {
            AuditHelper.log(req, "Đóng ca làm việc", "Shift",
                    "Staff @" + staffAcc.getUsername() + " đóng ca #" + shiftId
                            + " — tiền cuối ca: " + closingCash,
                    staffAcc.getAccountId());
        }

        String msg = ok ? "closed" : "error";
        resp.sendRedirect(req.getContextPath() + "/staff-my-shifts?uid=" + uid + "&msg=" + msg);
    }

    // ── Helper ────────────────────────────────────────────────────────────────
    private BigDecimal parseCash(String s) {
        if (s == null || s.isEmpty()) return BigDecimal.ZERO;
        try { return new BigDecimal(s); }
        catch (NumberFormatException e) { return BigDecimal.ZERO; }
    }
}