package com.medivault.dao.interfaces;

import com.medivault.entity.Attendance;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public interface IAttendanceDAO {

    // ── Check-in / Check-out ──────────────────────────────────────
    /** Trả về AttendanceID tạo mới, -1 nếu lỗi */
    int checkIn(int accountId, String method, BigDecimal openingCash, String note);
    boolean checkOut(int accountId, BigDecimal closingCash, String notes, boolean isAutoClose);

    // ── Query ─────────────────────────────────────────────────────
    /** Ca đang active (chưa check-out) của nhân viên */
    Attendance findActiveByAccount(int accountId);

    /** Lịch sử theo tháng */
    List<Attendance> findByAccountAndMonth(int accountId, int month, int year);

    /** Tất cả đang làm việc ngay lúc này */
    List<Attendance> findCurrentlyWorking();

    /** Lịch sử theo khoảng ngày */
    List<Attendance> findByAccountAndDateRange(int accountId, LocalDate from, LocalDate to);

    /** Theo scheduleId */
    Attendance findByScheduleId(int scheduleId);

    Attendance findById(int attendanceId);

    // ── NEW: query theo status ────────────────────────────────────
    /**
     * Tìm theo AttendanceStatus trong tháng — dùng cho báo cáo.
     * status: ON_TIME | LATE | EARLY_LEAVE | LATE_EARLY |
     *         OVERTIME | NO_SCHEDULE | FORCE_CHECKOUT
     */
    List<Attendance> findByStatusAndMonth(String status, int month, int year);
    int checkInWithPenalty(int accountId, int scheduleId, String method,
                           BigDecimal openingCash, BigDecimal penaltyAmount,
                           int lateMinutes, String status);

    boolean checkOutWithPenalty(int accountId, BigDecimal penaltyAmount,
                                String notes, boolean isAutoClose);

}