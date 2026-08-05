package com.medicare.dao.interfaces;

import com.medicare.entity.Task;
import com.medicare.entity.TaskChecklistItem;
import com.medicare.entity.TaskComment;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public interface ITaskDAO {

    Task findById(int taskId);

    /** Cập nhật EstimatedHours/RefTable/RefID sau khi tạo (form tạo task giữ nguyên
     *  insertManualTask() cũ, các trường mới chỉ update thêm nếu người dùng có điền). */
    boolean updateExtras(int taskId, java.math.BigDecimal estimatedHours, String refTable, Integer refId);

    // ── Kanban redesign — di chuyển cột (KHÔNG cho phép move thẳng sang Done, phải qua
    // markComplete() để tính đúng ON_TIME/LATE) ──
    boolean moveStatus(int taskId, String newStatus);
    /** Gán/bỏ gán người phụ trách mà KHÔNG đổi Status (accountId=null để bỏ gán). */
    boolean assign(int taskId, Integer accountId);

    // ── Checklist (database/tasks_kanban_migration.sql — TaskChecklistItems) ──
    List<TaskChecklistItem> findChecklist(int taskId);
    int addChecklistItem(int taskId, String itemText);
    boolean toggleChecklistItem(int checklistItemId, boolean done);
    boolean deleteChecklistItem(int checklistItemId);

    // ── Comments (TaskComments) ──
    List<TaskComment> findComments(int taskId);
    int addComment(int taskId, int accountId, String body);

    // ── Analytics (bottom charts, Admin) ──
    Map<String, Integer> countByStatusAll();
    Map<String, Integer> countByAssignee();
    /** "Module" suy từ RefTable (SYSTEM_AUTO task) — task MANUAL không có RefTable rơi vào "Chung". */
    Map<String, Integer> countByModule();
    Map<String, Integer> countByPriority();
    /** Giờ trung bình từ CreatedAt → CompletedAt của các task đã COMPLETED_*. */
    double avgCompletionHours();
    int countOverdue();

    /** Task tự động do hệ thống sinh — CreatedBy luôn NULL (ràng buộc CK_Task_Origin). */
    int insertSystemTask(String title, String description, String priority,
                          Integer assignedTo, String refTable, Integer refId, LocalDateTime dueDate);

    /** Task Manager tự tạo và giao việc — CreatedBy bắt buộc khác NULL. */
    int insertManualTask(String title, String description, String priority,
                          Integer assignedTo, int createdBy, LocalDateTime dueDate);

    /** Sườn code: Gửi yêu cầu Tạo nhiệm vụ mới từ Thủ kho lên Admin để chờ duyệt (Status = 'APPROVAL_PENDING'). */
    int requestTaskApproval(String title, String description, String priority,
                            Integer assignedTo, int createdBy, LocalDateTime dueDate);

    /** Sườn code: Admin duyệt yêu cầu tạo nhiệm vụ (chuyển Status -> 'PENDING'). */
    boolean approveTaskRequest(int taskId, int adminId);

    /** Sườn code: Admin từ chối yêu cầu tạo nhiệm vụ (chuyển Status -> 'REJECTED'). */
    boolean rejectTaskRequest(int taskId, int adminId, String reason);

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
