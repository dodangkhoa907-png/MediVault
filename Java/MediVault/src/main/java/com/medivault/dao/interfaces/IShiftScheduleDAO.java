package com.medivault.dao.interfaces;

import com.medivault.entity.ShiftSchedule;
import java.math.BigDecimal;
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

    // ── UPDATE ────────────────────────────────────────────────────
    boolean updateStatus(int scheduleId, String status);
    boolean update(int scheduleId, int shiftTypeId,
                   int lateToleranceMinutes, String notes, int updatedBy);

    // ── DELETE ────────────────────────────────────────────────────
    boolean cancel(int scheduleId);
    boolean delete(int scheduleId);

    // ── COUNT ─────────────────────────────────────────────────────
    int countAbsent(LocalDate from, LocalDate to);
}