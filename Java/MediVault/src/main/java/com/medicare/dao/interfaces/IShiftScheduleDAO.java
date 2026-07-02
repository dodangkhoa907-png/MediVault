package com.medicare.dao.interfaces;

import com.medicare.entity.ShiftSchedule;
import com.medicare.entity.Account;

import java.time.LocalDate;
import java.util.List;

public interface IShiftScheduleDAO {

    // ── CREATE ────────────────────────────────────────────────────
    int schedule(int accountId, int shiftTypeId, LocalDate workDate, int createdBy);

    // ── READ ──────────────────────────────────────────────────────
    ShiftSchedule findById(int scheduleId);
    List<ShiftSchedule> findAll();
    List<ShiftSchedule> findByDate(LocalDate date);
    List<ShiftSchedule> findByDateRange(LocalDate from, LocalDate to);
    List<ShiftSchedule> findByAccount(int accountId);
    List<ShiftSchedule> findByAccountAndMonth(int accountId, int month, int year);
    ShiftSchedule findTodaySchedule(int accountId);
    List<ShiftSchedule> findUpcoming(int accountId, int days);
    ShiftSchedule findByAccountAndDate(int accountId, LocalDate date);

    /** Tất cả lịch ca hôm nay kèm PosStation — cho sơ đồ quầy */
    List<ShiftSchedule> findTodayAll();

    // ── UPDATE ────────────────────────────────────────────────────
    boolean updateStatus(int scheduleId, String status);
    boolean update(int scheduleId, int shiftTypeId,
                   int lateToleranceMinutes, String notes, int updatedBy);

    // ── DELETE ────────────────────────────────────────────────────
    boolean cancel(int scheduleId);
    boolean delete(int scheduleId);

    // ── COUNT ─────────────────────────────────────────────────────
    int countAbsent(LocalDate from, LocalDate to);

    // ── CHECK ─────────────────────────────────────────────────────
    /** Kiểm tra có ShiftSchedule nào dùng shiftTypeId này không — dùng trước khi xóa ShiftType */
    boolean existsByShiftTypeId(int shiftTypeId);

    // ── Điều phối người thay (nghỉ đột xuất) ──
    /** Nhân viên "Off" ngày đó, có thể làm thay */
    List<Account> findAvailableSubstitutes(LocalDate date, int excludeAccountId);
    /** Tạo lịch ca cho người làm thay (copy ca gốc) — trả ScheduleID mới, -1 nếu lỗi */
    int assignSubstitute(ShiftSchedule original, int substituteAccountId, int createdBy);
}