package com.medivault.dao.interfaces;

import com.medivault.entity.Shift;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public interface IShiftDAO {

    // ── Staff operations ──────────────────────────────────────────────────────

    /** Mở ca mới cho nhân viên */
    boolean openShift(int accountId, BigDecimal openingCash);

    /** Đóng ca hiện tại */
    boolean closeShift(int shiftId, BigDecimal closingCash, String notes);

    /** Ca đang mở của nhân viên (EndTime IS NULL) */
    Shift findCurrent(int accountId);

    // ── Admin queries ──────────────────────────────────────────────────────────

    /** Tất cả ca, sắp xếp mới nhất trước */
    List<Shift> findAll();

    /** Ca của 1 nhân viên */
    List<Shift> findByAccount(int accountId);

    /** Ca theo khoảng ngày (StartTime) */
    List<Shift> findByDateRange(LocalDate from, LocalDate to);

    /** Tìm theo ID */
    Shift findById(int id);

    /** Xóa ca (chỉ cho phép khi chưa có hóa đơn liên kết) */
    boolean delete(int shiftId);

    /** Đếm tổng số ca */
    int countAll();

    /** Admin force-close ca đang mở (shift không có end time) */
    boolean forceClose(int shiftId, String notes);
}
