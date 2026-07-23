package com.medicare.entity;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;

public class Task {
    private int taskId;
    private String title;
    private String description;
    private String taskType;   // SYSTEM_AUTO | MANUAL
    private String priority;   // HIGH | MEDIUM | LOW
    private String status;     // PENDING | IN_PROGRESS | COMPLETED_ON_TIME | COMPLETED_LATE | CANCELLED
    private Integer assignedTo;
    private String assignedToName;   // JOIN Accounts.FullName
    private Integer createdBy;
    private String createdByName;    // JOIN Accounts.FullName
    private String refTable;
    private Integer refId;
    private LocalDateTime dueDate;   // = "TargetDeadline" (mốc bắt buộc báo xong trước)
    private LocalDateTime createdAt;
    private LocalDateTime completedAt; // = "TimeSubmitted" (thời điểm bấm Báo hoàn thành)
    private Integer completedBy;
    private String completedByName;

    // ── Dự án dài hạn (Milestones) ──
    private boolean isProject;
    private Integer parentTaskId;
    private int progressPercentage;
    private String lastNudgeZone;

    public String getPriorityLabel() {
        if (priority == null) return "—";
        return switch (priority) {
            case "HIGH"   -> "Cao";
            case "MEDIUM" -> "Trung bình";
            case "LOW"    -> "Thấp";
            default        -> priority;
        };
    }

    public String getStatusLabel() {
        if (status == null) return "—";
        return switch (status) {
            case "PENDING"           -> "Chờ xử lý";
            case "IN_PROGRESS"       -> "Đang làm";
            case "COMPLETED_ON_TIME" -> "Hoàn thành đúng hạn";
            case "COMPLETED_LATE"    -> "Hoàn thành trễ hạn";
            case "CANCELLED"         -> "Đã huỷ";
            default                   -> status;
        };
    }

    public boolean isDone() {
        return "COMPLETED_ON_TIME".equals(status) || "COMPLETED_LATE".equals(status)
                || "CANCELLED".equals(status);
    }

    /**
     * Vùng cảnh báo hạn chót (mục II.2 tài liệu): SAFE (&gt;48h) / WARNING (24-48h) /
     * CRITICAL (trong ngày chót) / OVERDUE (đã quá hạn). Tính TẠI THỜI ĐIỂM ĐỌC từ
     * dueDate — KHÔNG lưu cứng, luôn khớp thực tế mà không cần job đồng bộ.
     * Trả về null nếu không có hạn (dueDate null) hoặc task đã xong/huỷ (hết áp lực).
     */
    public String getZone() {
        if (dueDate == null || isDone()) return null;
        long hoursLeft = ChronoUnit.HOURS.between(LocalDateTime.now(), dueDate);
        if (hoursLeft < 0)  return "OVERDUE";
        if (hoursLeft <= 24) return "CRITICAL";
        if (hoursLeft <= 48) return "WARNING";
        return "SAFE";
    }

    public String getZoneLabel() {
        String z = getZone();
        if (z == null) return null;
        return switch (z) {
            case "OVERDUE"  -> "Đã quá hạn";
            case "CRITICAL" -> "Sắp tới hạn (≤24h)";
            case "WARNING"  -> "Cảnh báo (24-48h)";
            default          -> "Còn thời gian";
        };
    }

    /** Class CSS badge tái dùng theo quy ước .wh-ic/.badge đã có (warn/danger/ok). */
    public String getZoneCssClass() {
        String z = getZone();
        if (z == null) return "";
        return switch (z) {
            case "OVERDUE", "CRITICAL" -> "danger";
            case "WARNING"              -> "warn";
            default                      -> "ok";
        };
    }

    private static final DateTimeFormatter DTF = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    // JSTL <fmt:formatDate> chỉ nhận java.util.Date — Task dùng LocalDateTime nên PHẢI
    // format sẵn thành String ở đây rồi dùng ${t.dueDateDisplay} trong JSP, KHÔNG được
    // truyền thẳng ${t.dueDate} vào fmt:formatDate (sẽ ném lỗi runtime khi có giá trị).
    public String getDueDateDisplay()       { return dueDate == null ? "" : dueDate.format(DTF); }
    public String getCompletedAtDisplay()   { return completedAt == null ? "" : completedAt.format(DTF); }
    public String getCreatedAtDisplay()     { return createdAt == null ? "" : createdAt.format(DTF); }

    public int getTaskId()                        { return taskId; }
    public void setTaskId(int v)                  { this.taskId = v; }
    public String getTitle()                      { return title; }
    public void setTitle(String v)                { this.title = v; }
    public String getDescription()                { return description; }
    public void setDescription(String v)          { this.description = v; }
    public String getTaskType()                   { return taskType; }
    public void setTaskType(String v)             { this.taskType = v; }
    public String getPriority()                   { return priority; }
    public void setPriority(String v)             { this.priority = v; }
    public String getStatus()                     { return status; }
    public void setStatus(String v)               { this.status = v; }
    public Integer getAssignedTo()                { return assignedTo; }
    public void setAssignedTo(Integer v)          { this.assignedTo = v; }
    public String getAssignedToName()             { return assignedToName; }
    public void setAssignedToName(String v)       { this.assignedToName = v; }
    public Integer getCreatedBy()                 { return createdBy; }
    public void setCreatedBy(Integer v)           { this.createdBy = v; }
    public String getCreatedByName()              { return createdByName; }
    public void setCreatedByName(String v)        { this.createdByName = v; }
    public String getRefTable()                   { return refTable; }
    public void setRefTable(String v)             { this.refTable = v; }
    public Integer getRefId()                     { return refId; }
    public void setRefId(Integer v)               { this.refId = v; }
    public LocalDateTime getDueDate()              { return dueDate; }
    public void setDueDate(LocalDateTime v)       { this.dueDate = v; }
    public LocalDateTime getCreatedAt()            { return createdAt; }
    public void setCreatedAt(LocalDateTime v)     { this.createdAt = v; }
    public LocalDateTime getCompletedAt()          { return completedAt; }
    public void setCompletedAt(LocalDateTime v)   { this.completedAt = v; }
    public Integer getCompletedBy()               { return completedBy; }
    public void setCompletedBy(Integer v)         { this.completedBy = v; }
    public String getCompletedByName()             { return completedByName; }
    public void setCompletedByName(String v)      { this.completedByName = v; }

    public boolean getIsProject()                 { return isProject; }
    public void setIsProject(boolean v)           { this.isProject = v; }
    public Integer getParentTaskId()               { return parentTaskId; }
    public void setParentTaskId(Integer v)        { this.parentTaskId = v; }
    public int getProgressPercentage()             { return progressPercentage; }
    public void setProgressPercentage(int v)      { this.progressPercentage = v; }
    public String getLastNudgeZone()               { return lastNudgeZone; }
    public void setLastNudgeZone(String v)        { this.lastNudgeZone = v; }
}
