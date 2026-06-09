package com.medivault.dao.interfaces;

import com.medivault.entity.Attendance;
import java.time.LocalDate;
import java.util.List;

public interface IAttendanceDAO {

    // ── Check-in / Check-out ───────────────────────────────────────
    /** Check-in (gọi SP_CheckIn) — trả về AttendanceID tạo mới, -1 nếu lỗi */
    int checkIn(int accountId, String method, java.math.BigDecimal openingCash, String note);

    /** Check-out (gọi SP_CheckOut) */
    boolean checkOut(int accountId, java.math.BigDecimal closingCash, String notes, boolean isAutoClose);

    // ── Query ──────────────────────────────────────────────────────
    /** Bản ghi check-in đang active (chưa check-out) của nhân viên */
    Attendance findActiveByAccount(int accountId);

    /** Lịch sử điểm danh của 1 nhân viên trong tháng */
    List<Attendance> findByAccountAndMonth(int accountId, int month, int year);

    /** Tất cả đang làm việc ngay lúc này (admin xem) */
    List<Attendance> findCurrentlyWorking();

    /** Lịch sử điểm danh của 1 nhân viên trong khoảng ngày */
    List<Attendance> findByAccountAndDateRange(int accountId, LocalDate from, LocalDate to);

    /** Theo scheduleId */
    Attendance findByScheduleId(int scheduleId);

    Attendance findById(int attendanceId);
}
