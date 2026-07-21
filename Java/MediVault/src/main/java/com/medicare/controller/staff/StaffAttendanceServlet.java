package com.medicare.controller.staff;

import com.medicare.dao.*;
import com.medicare.dao.interfaces.IShiftDAO;
import com.medicare.dao.interfaces.*;
import com.medicare.entity.*;
import com.medicare.util.AuditHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
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
    private final IShiftDAO         shiftDAO      = new ShiftDAO();
    private final IAccountDAO       accountDAO    = new AccountDAO();

    // ── Face recognition: logic verify chặt nằm trong com.medicare.util.FaceVerifier

    // ── Grace periods (phút) ─────────────────────────────────────────────────
    private static final int CHECKIN_GRACE_MINUTES  = 5;   // 5p sau PlannedStart vẫn OK
    private static final int CHECKOUT_GRACE_MINUTES = 5;   // 5p sau PlannedEnd vẫn OK
    // Auto-close ca ĐANG ACTIVE bị bỏ quên chưa checkout nằm ở ShiftAutoCloseService riêng,
    // không phải ở đây — hằng số 20p trước đây bị dùng SAI làm mốc chặn CHECK-IN (đã sửa,
    // xem performCheckIn) nên xóa luôn để khỏi gây hiểu nhầm lần sau.

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
        req.setAttribute("currentShift",  shiftDAO.findCurrent(staff.getAccountId()));
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
        if ("checkin".equals(action))            handleCheckIn(req, resp, staff, uid);
        else if ("checkout".equals(action))       handleCheckOut(req, resp, staff, uid);
        else if ("face-checkin".equals(action))   handleFaceCheckIn(req, resp, staff, uid);
        else if ("face-checkout".equals(action))  handleFaceCheckOut(req, resp, staff, uid);
        else resp.sendRedirect(req.getContextPath() + "/staff-checkin?uid=" + uid);
    }

    // ── CHECK-IN ─────────────────────────────────────────────────────────────
    private void handleCheckIn(HttpServletRequest req, HttpServletResponse resp,
                               Account staff, String uid) throws IOException {
        String msg = performCheckIn(req, staff, "WEB_BUTTON", null);
        resp.sendRedirect(req.getContextPath() + "/staff-checkin?uid=" + uid + "&msg=" + msg);
    }

    /**
     * Lõi nghiệp vụ check-in (validate giờ, tính phạt, mở Shift, ghi AuditLog).
     * Dùng chung cho cả nút bấm thường (WEB_BUTTON) và xác minh khuôn mặt (FACE_ID).
     * @param openingCashOverride Tiền đầu ca do CHÍNH nhân viên nhập (face check-in flow).
     *                            Null → fallback dùng giá trị Admin set sẵn trong lịch ca.
     * @return mã msg để build redirect / JSON response
     */
    private String performCheckIn(HttpServletRequest req, Account staff, String method,
                                  BigDecimal openingCashOverride) {
        // 1. Đã check-in rồi?
        if (attendanceDAO.findActiveByAccount(staff.getAccountId()) != null) {
            return "already-in";
        }

        // 2. Phải có lịch ca hôm nay
        ShiftSchedule schedule = scheduleDAO.findTodaySchedule(staff.getAccountId());
        if (schedule == null) {
            return "no-schedule";
        }

        // 3. Validate giờ check-in
        LocalDateTime now         = LocalDateTime.now();
        LocalDateTime plannedStart = schedule.getPlannedStart();
        LocalDateTime plannedEnd   = schedule.getPlannedEnd();

        if (now.isBefore(plannedStart)) {
            return "too-early";
        }
        // BUG CŨ: dùng plannedEnd + AUTO_CLOSE_MINUTES (20p) làm mốc chặn check-in — nhưng
        // AUTO_CLOSE_MINUTES là hằng số của luồng CHECK-OUT/tự đóng ca ĐANG ACTIVE (xem class
        // JavaDoc), không liên quan gì tới việc có nên cho BẮT ĐẦU check-in mới hay không. Hệ
        // quả: nhân viên vẫn bấm check-in được tới 20 phút SAU KHI ca đã kết thúc hoàn toàn
        // (vd. ca 18:00–23:00 vẫn cho check-in tới 23:20) — vô lý vì ca gần như không còn thời
        // gian để làm việc. Mốc đúng: chặn NGAY khi đã qua giờ kết thúc ca (plannedEnd) — trong
        // suốt khoảng ca đang diễn ra (kể cả trễ nặng, quá LateToleranceMinutes) vẫn cho check-in
        // và đánh dấu ABSENT + phạt đủ, đúng như JavaDoc mô tả — chỉ chặn hẳn sau khi ca đã hết giờ.
        if (now.isAfter(plannedEnd)) {
            return "too-late";
        }

        // 4. Tính trễ và phạt
        long lateMinutes = ChronoUnit.MINUTES.between(plannedStart, now);
        BigDecimal penaltyAmount = BigDecimal.ZERO;
        String attendanceStatus  = "CONFIRMED";

        if (lateMinutes > CHECKIN_GRACE_MINUTES) {
            long penaltyMinutes = lateMinutes - CHECKIN_GRACE_MINUTES;
            BigDecimal rate = schedule.getPenaltyRatePerMinute();
            penaltyAmount = rate.multiply(BigDecimal.valueOf(penaltyMinutes));

            if (lateMinutes > schedule.getLateToleranceMinutes() + CHECKIN_GRACE_MINUTES) {
                attendanceStatus = "ABSENT";
            } else {
                attendanceStatus = "LATE";
            }
        }

        // 5. OpeningCash: ưu tiên giá trị nhân viên tự nhập (face check-in),
        //    fallback về giá trị Admin set sẵn trong lịch ca, cuối cùng là 0.
        BigDecimal openingCash;
        if (openingCashOverride != null) {
            openingCash = openingCashOverride;
        } else if (schedule.getOpeningCash() != null) {
            openingCash = schedule.getOpeningCash();
        } else {
            openingCash = BigDecimal.ZERO;
        }

        // 6. Thực hiện check-in
        int attId = attendanceDAO.checkInWithPenalty(
                staff.getAccountId(), schedule.getScheduleId(),
                method, openingCash, penaltyAmount,
                (int) lateMinutes, attendanceStatus);

        if (attId <= 0) return "error";

        scheduleDAO.updateStatus(schedule.getScheduleId(), attendanceStatus);
        if (shiftDAO.findCurrent(staff.getAccountId()) == null) {
            shiftDAO.openShift(staff.getAccountId(), openingCash);
        }

        String msg = "CONFIRMED".equals(attendanceStatus) ? "checked-in"
                : "LATE".equals(attendanceStatus)      ? "checked-in-late"
                  : "checked-in-absent";

        String methodLabel = "FACE_ID".equals(method) ? " (qua nhận diện khuôn mặt)" : "";
        AuditHelper.log(req, "Check-in", "Attendance",
                "@" + staff.getUsername() + " check-in" + methodLabel + " — "
                        + attendanceStatus + (lateMinutes > 5 ? " (trễ " + lateMinutes + "p, phạt "
                                                                + penaltyAmount.toPlainString() + "đ)" : " đúng giờ")
                        + " — tiền đầu ca: " + openingCash.toPlainString() + "đ",
                staff.getAccountId());
        return msg;
    }

    // ── CHECK-OUT ────────────────────────────────────────────────────────────
    private void handleCheckOut(HttpServletRequest req, HttpServletResponse resp,
                                Account staff, String uid) throws IOException {
        String notes = req.getParameter("notes");
        String handoverStr = req.getParameter("handoverCash");
        String msg = performCheckOut(req, staff, "WEB_BUTTON", notes, handoverStr);
        resp.sendRedirect(req.getContextPath() + "/staff-checkin?uid=" + uid + "&msg=" + msg);
    }

    /**
     * Lõi nghiệp vụ check-out (tính phạt về trễ, đóng Shift, ghi AuditLog).
     * Dùng chung cho cả nút bấm thường (WEB_BUTTON) và xác minh khuôn mặt (FACE_ID).
     */
    private String performCheckOut(HttpServletRequest req, Account staff, String method,
                                   String notes, String handoverStr) {
        Attendance activeAtt = attendanceDAO.findActiveByAccount(staff.getAccountId());
        if (activeAtt == null) {
            return "not-in";
        }

        BigDecimal penaltyAmount = BigDecimal.ZERO;
        if (activeAtt.getScheduleId() != null) {
            ShiftSchedule schedule = scheduleDAO.findById(activeAtt.getScheduleId());
            if (schedule != null && schedule.getPlannedEnd() != null) {
                LocalDateTime now       = LocalDateTime.now();
                LocalDateTime deadline  = schedule.getPlannedEnd()
                        .plusMinutes(CHECKOUT_GRACE_MINUTES);

                if (now.isAfter(deadline)) {
                    long overMinutes = ChronoUnit.MINUTES.between(deadline, now);
                    BigDecimal rate  = schedule.getPenaltyRatePerMinute();
                    penaltyAmount    = rate.multiply(BigDecimal.valueOf(overMinutes));
                }
            }
        }

        BigDecimal handoverCash = BigDecimal.ZERO;
        if (handoverStr != null && !handoverStr.trim().isEmpty()) {
            try { handoverCash = new BigDecimal(handoverStr.trim()); }
            catch (NumberFormatException ignored) {}
        }
        String fullNote = (handoverStr != null && !handoverStr.isEmpty()
                ? "[Bàn giao két: " + handoverCash.toPlainString() + "đ] " : "")
                + (notes != null && !notes.trim().isEmpty() ? notes.trim() : "");

        boolean ok = attendanceDAO.checkOutWithPenalty(
                staff.getAccountId(), penaltyAmount, fullNote, false);

        if (ok) {
            com.medicare.entity.Shift openShift = shiftDAO.findCurrent(staff.getAccountId());
            if (openShift != null) {
                shiftDAO.closeShift(openShift.getShiftId(), handoverCash, fullNote);
            }
            String methodLabel = "FACE_ID".equals(method) ? " (qua nhận diện khuôn mặt)" : "";
            AuditHelper.log(req, "Check-out", "Attendance",
                    "@" + staff.getUsername() + " check-out" + methodLabel
                            + (penaltyAmount.compareTo(BigDecimal.ZERO) > 0
                            ? " — phạt về trễ: " + penaltyAmount.toPlainString() + "đ" : ""),
                    staff.getAccountId());
        }
        return ok ? "checked-out" : "error";
    }

    // ── FACE CHECK-IN / CHECK-OUT (xác minh chính chủ trước khi điểm danh) ───
    private void handleFaceCheckIn(HttpServletRequest req, HttpServletResponse resp,
                                   Account staff, String uid) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        String descriptor = req.getParameter("descriptor");
        String verifyResult = verifyFace(staff, descriptor);
        if (!"MATCH".equals(verifyResult)) {
            writeJson(resp, jsonError(verifyResult));
            return;
        }
        BigDecimal openingCash = null;
        String openingCashStr = req.getParameter("openingCash");
        if (openingCashStr != null && !openingCashStr.trim().isEmpty()) {
            try { openingCash = new BigDecimal(openingCashStr.trim()); }
            catch (NumberFormatException ignored) {}
        }
        String msg = performCheckIn(req, staff, "FACE_ID", openingCash);
        writeJson(resp, "{\"ok\":true,\"msg\":\"" + msg + "\"}");
    }

    private void handleFaceCheckOut(HttpServletRequest req, HttpServletResponse resp,
                                    Account staff, String uid) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        String descriptor = req.getParameter("descriptor");
        String verifyResult = verifyFace(staff, descriptor);
        if (!"MATCH".equals(verifyResult)) {
            writeJson(resp, jsonError(verifyResult));
            return;
        }
        String notes = req.getParameter("notes");
        String handoverStr = req.getParameter("handoverCash");
        String msg = performCheckOut(req, staff, "FACE_ID", notes, handoverStr);
        writeJson(resp, "{\"ok\":true,\"msg\":\"" + msg + "\"}");
    }

    /**
     * So khớp descriptor gửi từ client với FaceVector — verify CHẶT qua FaceVerifier:
     * ngưỡng 0.45 + đối chiếu 1-vs-N toàn bộ nhân viên đã đăng ký mặt
     * (mặt phải khớp đúng chính chủ VÀ không gần mặt người khác).
     * @return "MATCH" hoặc mã lỗi: "no_face_enrolled" | "missing_descriptor"
     *         | "invalid_descriptor" | "no_match" | "impersonation" | "ambiguous"
     */
    private String verifyFace(Account staff, String descriptorJson) {
        // Đang chờ duyệt đổi khuôn mặt → chặn điểm danh bằng khuôn mặt cũ
        Account fresh = accountDAO.findById(staff.getAccountId());
        if (fresh != null && fresh.isFaceReenrollPending()) {
            return "reenroll_pending";
        }
        java.util.List<Account> allEnrolled = accountDAO.findAllWithFaceVector();
        return com.medicare.util.FaceVerifier.verify(
                staff.getAccountId(), descriptorJson, allEnrolled);
    }

    private void writeJson(HttpServletResponse resp, String json) throws IOException {
        try (PrintWriter out = resp.getWriter()) {
            out.print(json);
        }
    }

    private String jsonError(String reason) {
        return "{\"ok\":false,\"reason\":\"" + reason + "\"}";
    }
}