package com.medicare.dao.interfaces;

import com.medicare.entity.AuditLog;
import java.util.List;
import java.util.Map;

public interface IAuditLogDAO {
    boolean insert(AuditLog log);
    List<AuditLog> findPaginated(int page, int pageSize, String keyword, String fromDate, String toDate);
    int countAll(String keyword, String fromDate, String toDate);

    // ── Audit Explorer v2 — lọc + phân trang phía server (30 dòng/trang) ──
    List<AuditLog> findFiltered(int page, int pageSize, String keyword, String fromDate, String toDate,
                                 Integer role, String entityType, String severity, Integer accountId, String ip);
    int countFiltered(String keyword, String fromDate, String toDate,
                       Integer role, String entityType, String severity, Integer accountId, String ip);

    AuditLog findById(long logId);
    /** Nhật ký khác của CÙNG người, gần đây nhất, loại trừ chính log đang xem. */
    List<AuditLog> findByAccount(int accountId, long excludeLogId, int limit);
    /** [trước, sau] theo thời gian (CreatedAt) — 1 trong 2 có thể null nếu ở đầu/cuối danh sách. */
    AuditLog[] findPrevNext(long logId);

    /** Đếm số dòng theo RoleID (JOIN Accounts) — cho badge số trên tab Vai trò. */
    Map<Integer, Integer> countByRole();
    /** Đếm số dòng theo EntityType thô trong DB — cho badge số trên tab Module. */
    Map<String, Integer> countByEntityType();

    // ── Dashboard KPI (Section 1) ──
    int countToday();
    int countBySeverityToday(String severity);
    int countUniqueUsersToday();

    // ── Quick Analytics (Section 11) — tính trên TOÀN BỘ bảng, không phải mẫu đã tải ──
    Map<String, Integer> topUsers(int limit);
    Map<String, Integer> topIps(int limit);
    /** 24 phần tử, chỉ số 0-23 = giờ trong ngày (giờ VN), giá trị = số sự kiện hôm nay. */
    int[] hourlyToday();

    /** Live Mode (Investigation Center v3) — log mới hơn sinceId, mới nhất trước, tối đa limit dòng.
     *  Dùng cho polling định kỳ; sinceId=0 nghĩa là "chưa có gì" nên trả rỗng (poll đầu tiên chỉ
     *  ghi nhận mốc, không đẩy dồn cả bảng lên client). */
    List<AuditLog> findSince(long sinceId, int limit);
}