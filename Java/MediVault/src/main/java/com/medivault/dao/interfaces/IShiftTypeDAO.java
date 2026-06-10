package com.medivault.dao.interfaces;

import com.medivault.entity.ShiftType;
import java.util.List;

public interface IShiftTypeDAO {

    // ── READ ──────────────────────────────────────────────────────────────────
    /** Tất cả loại ca (cả active lẫn inactive) */
    List<ShiftType> findAll();

    /** Chỉ loại ca đang active — dùng cho dropdown xếp lịch */
    List<ShiftType> findAllActive();

    /** Tìm theo ID */
    ShiftType findById(int id);

    // ── CREATE ────────────────────────────────────────────────────────────────
    /** Tạo mới — validate HourlyRate >= 50,000đ */
    boolean insert(ShiftType st);

    // ── UPDATE ────────────────────────────────────────────────────────────────
    /** Sửa — validate HourlyRate >= 50,000đ */
    boolean update(ShiftType st);

    /** Bật/tắt trạng thái active */
    boolean setActive(int id, boolean active);

    // ── DELETE ────────────────────────────────────────────────────────────────
    /** Xóa — chỉ khi IsActive=0 và không có ShiftSchedules liên kết */
    boolean delete(int id);
}