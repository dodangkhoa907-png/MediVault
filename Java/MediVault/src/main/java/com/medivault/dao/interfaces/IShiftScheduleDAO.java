package com.medivault.dao.interfaces;

import com.medivault.entity.ShiftSchedule;
import java.time.LocalDate;
import java.util.List;

public interface IShiftScheduleDAO {

    // ── Admin ──────────────────────────────────────────────────────
    /** Xếp 1 ca cho nhân viên (gọi SP_ScheduleShift) */
    int schedule(int accountId, int shiftTypeId, LocalDate workDate, int createdBy);

    /** Hủy lịch ca */
    boolean cancel(int scheduleId);

    /** Toàn bộ lịch ca (admin xem) */
    List<ShiftSchedule> findAll();

    /** Lịch ca theo ngày (admin xem tất cả nhân viên) */
    List<ShiftSchedule> findByDate(LocalDate date);

    /** Lịch ca trong khoảng ngày */
    List<ShiftSchedule> findByDateRange(LocalDate from, LocalDate to);

    /** Lịch ca của 1 nhân viên trong tháng */
    List<ShiftSchedule> findByAccountAndMonth(int accountId, int month, int year);

    // ── Staff ──────────────────────────────────────────────────────
    /** Lịch ca của staff hôm nay */
    ShiftSchedule findTodaySchedule(int accountId);

    /** Lịch ca của staff từ hôm nay trở đi (7 ngày) */
    List<ShiftSchedule> findUpcoming(int accountId, int days);

    /** Lịch ca của staff theo ngày cụ thể */
    ShiftSchedule findByAccountAndDate(int accountId, LocalDate date);

    // ── Chung ──────────────────────────────────────────────────────
    ShiftSchedule findById(int scheduleId);

    /** Cập nhật trạng thái */
    boolean updateStatus(int scheduleId, String status);
}
