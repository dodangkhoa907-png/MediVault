package com.medicare.dao.interfaces;

import com.medicare.entity.Task;
import java.time.LocalDateTime;
import java.util.List;

public interface ITaskDAO {

    /** Task tự động do hệ thống sinh — CreatedBy luôn NULL (ràng buộc CK_Task_Origin). */
    int insertSystemTask(String title, String description, String priority,
                          Integer assignedTo, String refTable, Integer refId, LocalDateTime dueDate);

    /** Task Manager tự tạo và giao việc — CreatedBy bắt buộc khác NULL. */
    int insertManualTask(String title, String description, String priority,
                          Integer assignedTo, int createdBy, LocalDateTime dueDate);

    /** Đã có task CHƯA đóng (PENDING/IN_PROGRESS) nào trỏ tới bản ghi nguồn này chưa — chống tạo trùng mỗi lần job chạy. */
    boolean existsOpenTaskForRef(String refTable, int refId);

    /** "Nhiệm vụ hôm nay": của riêng tôi + các task chung chưa ai nhận (AssignedTo NULL), chưa xong. */
    List<Task> findMyOpenTasks(int accountId);

    /** Toàn bộ board cho màn Quản lý Task (JOIN sẵn tên người liên quan), lọc theo Status/Priority (NULL = không lọc). */
    List<Task> findBoard(String status, String priority);

    int countMyOpenTasks(int accountId);

    boolean claim(int taskId, int accountId);          // nhận task chung (AssignedTo đang NULL) về mình, chuyển IN_PROGRESS

    /** Đánh dấu hoàn thành — tự tính COMPLETED_ON_TIME/COMPLETED_LATE bằng GETDATE() so DueDate ngay trong SQL. */
    boolean markComplete(int taskId, int completedBy);
    boolean cancel(int taskId);

    // ── Dự án dài hạn (Milestones) — mục IV.2 tài liệu "Strategic Projects" ──

    /** Tạo Dự án dài hạn (IsProject=1) — Admin giao cho 1 Thủ kho, có hạn báo cáo tổng. */
    int insertProject(String title, String description, String priority,
                       Integer assignedTo, int createdBy, LocalDateTime dueDate);

    /** Thêm 1 mốc (milestone) con vào Dự án — ParentTaskID trỏ về Dự án cha, kế thừa AssignedTo của cha. */
    int insertMilestone(int parentTaskId, String title, String description, LocalDateTime dueDate);

    /** Danh sách milestone con của 1 Dự án, theo thứ tự tạo. */
    List<Task> findMilestones(int parentTaskId);

    /** Danh sách Dự án (IsProject=1) được giao cho 1 tài khoản, kèm % tiến độ hiện tại. */
    List<Task> findMyProjects(int accountId);

    /**
     * Tính lại % tiến độ Dự án cha = số milestone COMPLETED_* / tổng số milestone,
     * gọi ngay sau khi 1 milestone đổi trạng thái (markComplete/cancel một sub-task).
     */
    void recalcProjectProgress(int parentTaskId);

    // ── Admin: Watchdog / Kanban / KPI Audit — mục III tài liệu ──

    /** Task/Dự án CHƯA xong và DueDate đã/sắp tới trong 48h (Vùng Vàng + Vùng Đỏ) — cho Watchdog widget. */
    List<Task> findWatchdog();

    /** Toàn bộ task cho Kanban (nhóm theo Status ở tầng JSP), không lọc theo AssignedTo — góc nhìn Admin. */
    List<Task> findKanban();

    /** Bảng Nhật ký Liêm chính Thời gian: task đã có kết quả (COMPLETED_ON_TIME/LATE), mới nhất trước. */
    List<Task> findKpiAudit();
}
