package com.medivault.controller.staff;

import com.medivault.dao.ShiftDAO;
import com.medivault.dao.interfaces.IShiftDAO;
import com.medivault.entity.Account;
import com.medivault.entity.Shift;
import com.medivault.util.AuditHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;

/**
 * StaffShiftServlet — Nhân viên tự mở/đóng ca của mình.
 * URL: POST /staff-shift?action=open|close&uid={staffId}
 */
@WebServlet("/staff-shift")
public class StaffShiftServlet extends HttpServlet {

    private final IShiftDAO shiftDAO = new ShiftDAO();

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

        boolean ok = shiftDAO.openShift(staffAcc.getAccountId(), openingCash);

        if (ok) {
            AuditHelper.log(req, "Mở ca làm việc", "Shift",
                    "Staff @" + staffAcc.getUsername() + " mở ca — tiền đầu ca: " + openingCash,
                    staffAcc.getAccountId());
        }

        String msg = ok ? "shift-opened" : "shift-already-open";
        resp.sendRedirect(req.getContextPath() + "/staff-dashboard?uid=" + uid + "&msg=" + msg);
    }

    // ── Đóng ca ───────────────────────────────────────────────────────────────
    private void handleClose(HttpServletRequest req, HttpServletResponse resp,
                             Account staffAcc, String uid) throws IOException {
        String shiftIdStr  = req.getParameter("shiftId");
        BigDecimal closingCash = parseCash(req.getParameter("closingCash"));
        String notes       = req.getParameter("notes");

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

        String msg = ok ? "shift-closed" : "error";
        resp.sendRedirect(req.getContextPath() + "/staff-dashboard?uid=" + uid + "&msg=" + msg);
    }

    // ── Helper ────────────────────────────────────────────────────────────────
    private BigDecimal parseCash(String s) {
        if (s == null || s.isEmpty()) return BigDecimal.ZERO;
        try { return new BigDecimal(s); }
        catch (NumberFormatException e) { return BigDecimal.ZERO; }
    }
}
