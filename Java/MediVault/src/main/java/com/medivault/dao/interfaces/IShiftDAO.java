package com.medivault.dao.interfaces;

import com.medivault.entity.Shift;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public interface IShiftDAO {

    // ── Staff ─────────────────────────────────────────────────────
    boolean openShift(int accountId, BigDecimal openingCash);
    boolean closeShift(int shiftId, BigDecimal closingCash, String notes);
    Shift findCurrent(int accountId);

    // ── Admin ─────────────────────────────────────────────────────
    boolean forceClose(int shiftId, String notes);
    boolean delete(int shiftId);
    int countAll();

    // ── Query ─────────────────────────────────────────────────────
    List<Shift> findAll();
    List<Shift> findByAccount(int accountId);
    List<Shift> findByDateRange(LocalDate from, LocalDate to);
    Shift findById(int id);

    // ── NEW: query theo status ────────────────────────────────────
    /** Tìm theo status: OPEN | CLOSED | FORCE_CLOSED | ABANDONED */
    List<Shift> findByStatus(String status);
    boolean setClosingCash(int shiftId, BigDecimal closingCash);
}