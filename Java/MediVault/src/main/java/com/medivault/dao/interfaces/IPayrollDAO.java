package com.medivault.dao.interfaces;

import com.medivault.entity.Payroll;
import java.math.BigDecimal;
import java.util.List;

public interface IPayrollDAO {

    // ── Tạo / Tính lương ──────────────────────────────────────────
    /** Tạo bảng lương draft (gọi SP_GeneratePayroll) */
    int generate(int accountId, int month, int year);

    /** Cập nhật thưởng / ghi chú thủ công */
    boolean updateBonus(int payrollId, BigDecimal bonus, String notes);

    // ── Workflow ──────────────────────────────────────────────────
    boolean confirm(int payrollId, int confirmedBy);
    boolean markPaid(int payrollId);

    // ── Query ─────────────────────────────────────────────────────
    /** Tất cả bảng lương tháng (admin xem) */
    List<Payroll> findByMonth(int month, int year);

    /** Bảng lương của 1 nhân viên */
    List<Payroll> findByAccount(int accountId);

    /** Bảng lương cụ thể của nhân viên trong tháng */
    Payroll findByAccountAndMonth(int accountId, int month, int year);

    Payroll findById(int payrollId);
}
