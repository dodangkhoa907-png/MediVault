package com.medicare.dao.interfaces;

import com.medicare.entity.LeaveRequest;
import java.time.LocalDate;
import java.util.List;

public interface ILeaveRequestDAO {

    // ── Staff ──────────────────────────────────────────────────────
    /** Gửi đơn xin nghỉ */
    boolean insert(LeaveRequest lr);

    /** Đơn của nhân viên theo tháng */
    List<LeaveRequest> findByAccountAndMonth(int accountId, int month, int year);

    /** Đơn của nhân viên (tất cả) */
    List<LeaveRequest> findByAccount(int accountId);

    // ── Admin ──────────────────────────────────────────────────────
    /** Tất cả đơn đang PENDING */
    List<LeaveRequest> findPending();

    /** Duyệt / từ chối đơn */
    boolean approve(int leaveId, int approvedBy, String notes, java.math.BigDecimal deductAmount);
    boolean reject(int leaveId, int approvedBy, String notes);

    /** Tất cả đơn trong tháng (admin xem) */
    List<LeaveRequest> findByMonth(int month, int year);

    // ── Chung ──────────────────────────────────────────────────────
    LeaveRequest findById(int leaveId);

    /** Kiểm tra nhân viên đã có đơn nghỉ ngày đó chưa */
    boolean existsByAccountAndDate(int accountId, LocalDate date);
}
