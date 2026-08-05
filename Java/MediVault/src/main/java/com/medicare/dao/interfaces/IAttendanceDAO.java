package com.medicare.dao.interfaces;

import com.medicare.entity.Attendance;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;

public interface IAttendanceDAO {

    // ── Check-in / Check-out ──────────────────────────────────────
    /** Trả về AttendanceID tạo mới, -1 nếu lỗi */
    int checkIn(int accountId, String method, BigDecimal openingCash, String note);
    boolean checkOut(int accountId, BigDecimal closingCash, String notes, boolean isAutoClose);

    /**
     * Check-out ĐÚNG 1 bản ghi Attendance theo AttendanceID cụ thể (không dò "bản ghi mở mới nhất
     * theo AccountID" như SP_CheckOut/checkOut()). Dùng khi đã xác định chính xác bản ghi cần đóng
     * (VD: "Tan ca" từ quầy X — occupant có thể có NHIỀU bản ghi Attendance còn mở do lỗi cũ, nếu
     * đóng nhầm bản ghi khác thì quầy X vẫn hiện "đang bận" mãi dù đã tan ca).
     */
    boolean checkOutById(int attendanceId, BigDecimal closingCash, String notes, boolean isAutoClose);

    // ── Query ─────────────────────────────────────────────────────
    /** Ca đang active (chưa check-out) của nhân viên */
    Attendance findActiveByAccount(int accountId);

    /**
     * Nhân viên đang check-in active tại quầy POS chỉ định hôm nay.
     * Dùng để tra "ai đang đứng quầy số X" khi session không có staffAccount.
     */
    Attendance findActiveByStation(int posStation);

    /**
     * Toàn bộ danh sách "quầy POS -> tên nhân viên đang đứng quầy" (chưa check-out) hôm nay,
     * 1 query duy nhất — dùng cho modal chọn quầy trong POS, để biết quầy nào đang có người
     * làm TRƯỚC KHI chọn, tránh chọn nhầm quầy người khác đang dùng.
     */
    Map<Integer, String> findActiveStaffByStation();

    /** Lịch sử theo tháng */
    List<Attendance> findByAccountAndMonth(int accountId, int month, int year);

    /** Tất cả đang làm việc ngay lúc này */
    List<Attendance> findCurrentlyWorking();

    /** Lịch sử theo khoảng ngày */
    List<Attendance> findByAccountAndDateRange(int accountId, LocalDate from, LocalDate to);

    /** Theo scheduleId */
    Attendance findByScheduleId(int scheduleId);

    Attendance findById(int attendanceId);
    int countByStatus(String status);

    // ── NEW: query theo status ────────────────────────────────────
    /**
     * Tìm theo AttendanceStatus trong tháng — dùng cho báo cáo.
     * status: ON_TIME | LATE | EARLY_LEAVE | LATE_EARLY |
     *         OVERTIME | NO_SCHEDULE | FORCE_CHECKOUT
     */
    List<Attendance> findByStatusAndMonth(String status, int month, int year);
    /**
     * @param scheduleId {@code null} = mở ca không theo lịch (đúng ý nghĩa cột
     *                   Attendance.ScheduleID NULL trong schema) — dùng cho Thủ kho
     *                   (roleId 3), vốn không được xếp ShiftSchedule như nhân viên bán hàng.
     */
    int checkInWithPenalty(int accountId, Integer scheduleId, String method,
                           BigDecimal openingCash, BigDecimal penaltyAmount,
                           int lateMinutes, String status, Integer posStation);

    boolean checkOutWithPenalty(int accountId, BigDecimal penaltyAmount,
                                String notes, boolean isAutoClose);

    /** Cập nhật quầy POS thực tế cho 1 bản ghi Attendance đang mở (chưa checkout). */
    boolean updatePosStation(int attendanceId, int posStation);

}