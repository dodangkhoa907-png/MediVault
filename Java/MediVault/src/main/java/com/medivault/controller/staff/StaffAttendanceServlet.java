package com.medivault.controller.staff;

import com.medivault.dao.*;
import com.medivault.dao.interfaces.*;
import com.medivault.entity.*;
import com.medivault.util.AuditHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

/**
 * StaffAttendanceServlet — Check-in / Check-out với đầy đủ logic phạt.
 *
 * CHECK-IN timeline:
 *   PlannedStart           → đúng giờ (CONFIRMED)
 *   +5p grace              → vẫn CONFIRMED
 *   +5p → +LateToleranceMin → LATE, trừ (phút - 5) × penaltyRate
 *   Sau LateToleranceMin   → vẫn check-in được, ABSENT, trừ hết phút trễ × penaltyRate
 *
 * CHECK-OUT / AUTO-CLOSE timeline:
 *   PlannedEnd             → check-out bình thường
 *   +5p grace              → vẫn không phạt
 *   +5p → +20p             → phạt (phút - 5) × penaltyRate
 *   +20p                   → server tự đóng, phạt toàn bộ phút lố
 */
@WebServlet("/staff-checkin")
public class StaffAttendanceServlet extends HttpServlet {

    private final IAttendanceDAO    attendanceDAO = new AttendanceDAO();
    private final IShiftScheduleDAO scheduleDAO   = new ShiftScheduleDAO();

    // ── Grace periods (phút) ─────────────────────────────────────────────────
    private static final int CHECKIN_GRACE_MINUTES  = 5;   // 5p sau PlannedStart vẫn OK
    private static final int CHECKOUT_GRACE_MINUTES = 5;   // 5p sau PlannedEnd vẫn OK
    private static final int AUTO_CLOSE_MINUTES     = 20;  // 20p sau PlannedEnd → tự đóng

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String uid = req.getParameter("uid");
        if (uid == null || uid.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/staff-login"); return;
        }
        HttpSession session = req.getSession(false);
        Account staff = session != null
                ? (Account) session.getAttribute("staffAccount_" + uid) : null;
        if (staff == null) {
            resp.sendRedirect(req.getContextPath() + "/staff-login"); return;
        }

        ShiftSchedule todaySchedule = scheduleDAO.findTodaySchedule(staff.getAccountId());
        Attendance activeAtt        = attendanceDAO.findActiveByAccount(staff.getAccountId());
        java.util.List<ShiftSchedule> upcoming = scheduleDAO.findUpcoming(staff.getAccountId(), 7);

        req.setAttribute("staffUid",      uid);
        req.setAttribute("todaySchedule", todaySchedule);
        req.setAttribute("activeAtt",     activeAtt);
        req.setAttribute("upcoming",      upcoming);
        req.setAttribute("today",         LocalDate.now());
        req.getRequestDispatcher("/WEB-INF/views/staff/staff-checkin.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String uid = req.getParameter("uid");
        if (uid == null || uid.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/staff-login"); return;
        }
        HttpSession session = req.getSession(false);
        Account staff = session != null
                ? (Account) session.getAttribute("staffAccount_" + uid) : null;
        if (staff == null) {
            resp.sendRedirect(req.getContextPath() + "/staff-login"); return;
        }

        String action = req.getParameter("action");
        if ("checkin".equals(action))       handleCheckIn(req, resp, staff, uid);
        else if ("checkout".equals(action)) handleCheckOut(req, resp, staff, uid);
        else resp.sendRedirect(req.getContextPath() + "/staff-checkin?uid=" + uid);
    }

    // ── CHECK-IN ─────────────────────────────────────────────────────────────
    private void handleCheckIn(HttpServletRequest req, HttpServletResponse resp,
                               Account staff, String uid) throws IOException {
        // 1. Đã check-in rồi?
        if (attendanceDAO.findActiveByAccount(staff.getAccountId()) != null) {
            resp.sendRedirect(req.getContextPath()
                    + "/staff-checkin?uid=" + uid + "&msg=already-in"); return;
        }

        // 2. Phải có lịch ca hôm nay
        ShiftSchedule schedule = scheduleDAO.findTodaySchedule(staff.getAccountId());
        if (schedule == null) {
            resp.sendRedirect(req.getContextPath()
                    + "/staff-checkin?uid=" + uid + "&msg=no-schedule"); return;
        }

        // 3. Validate giờ check-in
        LocalDateTime now         = LocalDateTime.now();
        LocalDateTime plannedStart = schedule.getPlannedStart();
        LocalDateTime plannedEnd   = schedule.getPlannedEnd();

        // Chưa đến giờ ca (trước PlannedStart)
        if (now.isBefore(plannedStart)) {
            resp.sendRedirect(req.getContextPath()
                    + "/staff-checkin?uid=" + uid + "&msg=too-early"); return;
        }

        // Quá giờ auto-close (sau PlannedEnd + 20p)
        if (now.isAfter(plannedEnd.plusMinutes(AUTO_CLOSE_MINUTES))) {
            resp.sendRedirect(req.getContextPath()
                    + "/staff-checkin?uid=" + uid + "&msg=too-late"); return;
        }

        // 4. Tính trễ và phạt
        long lateMinutes = ChronoUnit.MINUTES.between(plannedStart, now);
        BigDecimal penaltyAmount = BigDecimal.ZERO;
        String attendanceStatus  = "CONFIRMED";

        if (lateMinutes > CHECKIN_GRACE_MINUTES) {
            // Phút bị tính phạt = (lateMinutes - grace)
            long penaltyMinutes = lateMinutes - CHECKIN_GRACE_MINUTES;
            BigDecimal rate = schedule.getPenaltyRatePerMinute(); // mặc định 5000đ/phút
            penaltyAmount = rate.multiply(BigDecimal.valueOf(penaltyMinutes));

            // Sau LateToleranceMinutes → ABSENT (vẫn cho vào nhưng mark absent)
            if (lateMinutes > schedule.getLateToleranceMinutes() + CHECKIN_GRACE_MINUTES) {
                attendanceStatus = "ABSENT";
            } else {
                attendanceStatus = "LATE";
            }
        }

        // 5. OpeningCash từ lịch ca (admin set), staff không nhập
        BigDecimal openingCash = schedule.getOpeningCash() != null
                ? schedule.getOpeningCash() : BigDecimal.ZERO;

        // 6. Thực hiện check-in
        int attId = attendanceDAO.checkInWithPenalty(
                staff.getAccountId(), schedule.getScheduleId(),
                "WEB_BUTTON", openingCash, penaltyAmount,
                (int) lateMinutes, attendanceStatus);

        if (attId > 0) {
            // Cập nhật trạng thái lịch ca
            scheduleDAO.updateStatus(schedule.getScheduleId(), attendanceStatus);

            String msg = "CONFIRMED".equals(attendanceStatus) ? "checked-in"
                    : "LATE".equals(attendanceStatus)      ? "checked-in-late"
                      : "checked-in-absent";

            AuditHelper.log(req, "Check-in", "Attendance",
                    "@" + staff.getUsername() + " check-in — "
                            + attendanceStatus + (lateMinutes > 5 ? " (trễ " + lateMinutes + "p, phạt "
                                                                    + penaltyAmount.toPlainString() + "đ)" : " đúng giờ"),
                    staff.getAccountId());
            resp.sendRedirect(req.getContextPath() + "/staff-checkin?uid=" + uid + "&msg=" + msg);
        } else {
            resp.sendRedirect(req.getContextPath() + "/staff-checkin?uid=" + uid + "&msg=error");
        }
    }

    // ── CHECK-OUT ────────────────────────────────────────────────────────────
    private void handleCheckOut(HttpServletRequest req, HttpServletResponse resp,
                                Account staff, String uid) throws IOException {
        Attendance activeAtt = attendanceDAO.findActiveByAccount(staff.getAccountId());
        if (activeAtt == null) {
            resp.sendRedirect(req.getContextPath()
                    + "/staff-checkin?uid=" + uid + "&msg=not-in"); return;
        }

        // Tính phạt về trễ nếu có lịch ca
        BigDecimal penaltyAmount = BigDecimal.ZERO;
        if (activeAtt.getScheduleId() != null) {
            ShiftSchedule schedule = scheduleDAO.findById(activeAtt.getScheduleId());
            if (schedule != null && schedule.getPlannedEnd() != null) {
                LocalDateTime now       = LocalDateTime.now();
                LocalDateTime deadline  = schedule.getPlannedEnd()
                        .plusMinutes(CHECKOUT_GRACE_MINUTES); // PlannedEnd + 5p grace

                if (now.isAfter(deadline)) {
                    long overMinutes = ChronoUnit.MINUTES.between(deadline, now);
                    BigDecimal rate  = schedule.getPenaltyRatePerMinute();
                    penaltyAmount    = rate.multiply(BigDecimal.valueOf(overMinutes));
                }
            }
        }

        String notes = req.getParameter("notes");
        boolean ok = attendanceDAO.checkOutWithPenalty(
                staff.getAccountId(), penaltyAmount, notes, false);

        if (ok) {
            AuditHelper.log(req, "Check-out", "Attendance",
                    "@" + staff.getUsername() + " check-out"
                            + (penaltyAmount.compareTo(BigDecimal.ZERO) > 0
                            ? " — phạt về trễ: " + penaltyAmount.toPlainString() + "đ" : ""),
                    staff.getAccountId());
        }
        resp.sendRedirect(req.getContextPath() + "/staff-checkin?uid=" + uid
                + "&msg=" + (ok ? "checked-out" : "error"));
    }
}