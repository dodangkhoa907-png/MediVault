package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.ITaskDAO;
import com.medicare.entity.Task;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * TaskDAO — Mô-đun "To-do List / Task Management" (Quản Lý Task &amp; SOP) cho portal
 * Quản lý kho. Xem database/tasks_module_migration.sql về ràng buộc CK_Task_Origin
 * (SYSTEM_AUTO luôn CreatedBy NULL, MANUAL luôn phải có CreatedBy).
 */
public class TaskDAO implements ITaskDAO {

    private Task mapRow(ResultSet rs) throws SQLException {
        Task t = new Task();
        t.setTaskId(rs.getInt("TaskID"));
        t.setTitle(rs.getString("Title"));
        t.setDescription(rs.getString("Description"));
        t.setTaskType(rs.getString("TaskType"));
        t.setPriority(rs.getString("Priority"));
        t.setStatus(rs.getString("Status"));
        t.setAssignedTo((Integer) rs.getObject("AssignedTo"));
        t.setAssignedToName(rs.getString("AssignedToName"));
        t.setCreatedBy((Integer) rs.getObject("CreatedBy"));
        t.setCreatedByName(rs.getString("CreatedByName"));
        t.setRefTable(rs.getString("RefTable"));
        t.setRefId((Integer) rs.getObject("RefID"));
        if (rs.getTimestamp("DueDate") != null) t.setDueDate(rs.getTimestamp("DueDate").toLocalDateTime());
        if (rs.getTimestamp("CreatedAt") != null) t.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
        if (rs.getTimestamp("CompletedAt") != null) t.setCompletedAt(rs.getTimestamp("CompletedAt").toLocalDateTime());
        t.setCompletedBy((Integer) rs.getObject("CompletedBy"));
        t.setCompletedByName(rs.getString("CompletedByName"));
        t.setIsProject(rs.getBoolean("IsProject"));
        t.setParentTaskId((Integer) rs.getObject("ParentTaskID"));
        t.setProgressPercentage(rs.getInt("ProgressPercentage"));
        t.setLastNudgeZone(rs.getString("LastNudgeZone"));
        return t;
    }

    private static final String SELECT_JOINED =
            "SELECT t.*, " +
            "       a1.FullName AS AssignedToName, " +
            "       a2.FullName AS CreatedByName, " +
            "       a3.FullName AS CompletedByName " +
            "FROM Tasks t " +
            "LEFT JOIN Accounts a1 ON a1.AccountID = t.AssignedTo " +
            "LEFT JOIN Accounts a2 ON a2.AccountID = t.CreatedBy " +
            "LEFT JOIN Accounts a3 ON a3.AccountID = t.CompletedBy ";

    @Override
    public int insertSystemTask(String title, String description, String priority,
                                 Integer assignedTo, String refTable, Integer refId, LocalDateTime dueDate) {
        String sql = "INSERT INTO Tasks (Title, Description, TaskType, Priority, Status, AssignedTo, CreatedBy, RefTable, RefID, DueDate) " +
                "VALUES (?, ?, 'SYSTEM_AUTO', ?, 'PENDING', ?, NULL, ?, ?, ?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setNString(1, title);
            ps.setNString(2, description);
            ps.setString(3, priority);
            if (assignedTo != null) ps.setInt(4, assignedTo); else ps.setNull(4, Types.INTEGER);
            ps.setString(5, refTable);
            if (refId != null) ps.setInt(6, refId); else ps.setNull(6, Types.INTEGER);
            if (dueDate != null) ps.setTimestamp(7, Timestamp.valueOf(dueDate)); else ps.setNull(7, Types.TIMESTAMP);
            int affected = ps.executeUpdate();
            if (affected > 0) {
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (keys.next()) return keys.getInt(1);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return -1;
    }

    @Override
    public int insertManualTask(String title, String description, String priority,
                                 Integer assignedTo, int createdBy, LocalDateTime dueDate) {
        String sql = "INSERT INTO Tasks (Title, Description, TaskType, Priority, Status, AssignedTo, CreatedBy, DueDate) " +
                "VALUES (?, ?, 'MANUAL', ?, 'PENDING', ?, ?, ?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setNString(1, title);
            ps.setNString(2, description);
            ps.setString(3, priority);
            if (assignedTo != null) ps.setInt(4, assignedTo); else ps.setNull(4, Types.INTEGER);
            ps.setInt(5, createdBy);
            if (dueDate != null) ps.setTimestamp(6, Timestamp.valueOf(dueDate)); else ps.setNull(6, Types.TIMESTAMP);
            int affected = ps.executeUpdate();
            if (affected > 0) {
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (keys.next()) return keys.getInt(1);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return -1;
    }

    @Override
    public boolean existsOpenTaskForRef(String refTable, int refId) {
        String sql = "SELECT TOP 1 1 FROM Tasks WHERE RefTable = ? AND RefID = ? AND Status IN ('PENDING','IN_PROGRESS')";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, refTable);
            ps.setInt(2, refId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (Exception e) { e.printStackTrace(); return true; } // lỗi => coi như đã có, tránh spam trùng
    }

    @Override
    public List<Task> findMyOpenTasks(int accountId) {
        List<Task> list = new ArrayList<>();
        String sql = SELECT_JOINED +
                "WHERE (t.AssignedTo = ? OR t.AssignedTo IS NULL) AND t.Status IN ('PENDING','IN_PROGRESS') " +
                "ORDER BY CASE t.Priority WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 ELSE 3 END, t.DueDate ASC, t.CreatedAt ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<Task> findBoard(String status, String priority) {
        List<Task> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder(SELECT_JOINED).append("WHERE 1=1 ");
        if (status != null && !status.isEmpty())   sql.append("AND t.Status = ? ");
        if (priority != null && !priority.isEmpty()) sql.append("AND t.Priority = ? ");
        sql.append("ORDER BY CASE t.Status WHEN 'PENDING' THEN 1 WHEN 'IN_PROGRESS' THEN 2 ")
           .append("WHEN 'COMPLETED_ON_TIME' THEN 3 WHEN 'COMPLETED_LATE' THEN 3 ELSE 4 END, ")
           .append("CASE t.Priority WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 ELSE 3 END, t.CreatedAt DESC");
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql.toString())) {
            int idx = 1;
            if (status != null && !status.isEmpty())   ps.setString(idx++, status);
            if (priority != null && !priority.isEmpty()) ps.setString(idx++, priority);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public int countMyOpenTasks(int accountId) {
        String sql = "SELECT COUNT(*) FROM Tasks WHERE (AssignedTo = ? OR AssignedTo IS NULL) AND Status IN ('PENDING','IN_PROGRESS')";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    @Override
    public boolean claim(int taskId, int accountId) {
        String sql = "UPDATE Tasks SET AssignedTo = ?, Status = 'IN_PROGRESS' " +
                "WHERE TaskID = ? AND AssignedTo IS NULL AND Status = 'PENDING'";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.setInt(2, taskId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public boolean markComplete(int taskId, int completedBy) {
        // Tính ON_TIME/LATE bằng đồng hồ SQL Server (GETDATE()), không tin đồng hồ JVM —
        // DueDate NULL (task không có hạn) mặc định coi là ON_TIME.
        String sql = "UPDATE Tasks SET " +
                "Status = CASE WHEN DueDate IS NULL OR GETDATE() <= DueDate " +
                "         THEN 'COMPLETED_ON_TIME' ELSE 'COMPLETED_LATE' END, " +
                "CompletedAt = GETDATE(), CompletedBy = ? " +
                "WHERE TaskID = ? AND Status NOT IN ('COMPLETED_ON_TIME','COMPLETED_LATE','CANCELLED')";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, completedBy);
            ps.setInt(2, taskId);
            boolean ok = ps.executeUpdate() > 0;
            if (ok) {
                Integer parentId = findParentIdOf(taskId);
                if (parentId != null) recalcProjectProgress(parentId);
            }
            return ok;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public boolean cancel(int taskId) {
        String sql = "UPDATE Tasks SET Status = 'CANCELLED' " +
                "WHERE TaskID = ? AND Status NOT IN ('COMPLETED_ON_TIME','COMPLETED_LATE','CANCELLED')";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, taskId);
            boolean ok = ps.executeUpdate() > 0;
            if (ok) {
                Integer parentId = findParentIdOf(taskId);
                if (parentId != null) recalcProjectProgress(parentId);
            }
            return ok;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    private Integer findParentIdOf(int taskId) throws SQLException {
        String sql = "SELECT ParentTaskID FROM Tasks WHERE TaskID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, taskId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return (Integer) rs.getObject(1);
            }
        }
        return null;
    }

    // ── Dự án dài hạn (Milestones) ──

    @Override
    public int insertProject(String title, String description, String priority,
                              Integer assignedTo, int createdBy, LocalDateTime dueDate) {
        String sql = "INSERT INTO Tasks (Title, Description, TaskType, Priority, Status, AssignedTo, CreatedBy, DueDate, IsProject) " +
                "VALUES (?, ?, 'MANUAL', ?, 'PENDING', ?, ?, ?, 1)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setNString(1, title);
            ps.setNString(2, description);
            ps.setString(3, priority);
            if (assignedTo != null) ps.setInt(4, assignedTo); else ps.setNull(4, Types.INTEGER);
            ps.setInt(5, createdBy);
            if (dueDate != null) ps.setTimestamp(6, Timestamp.valueOf(dueDate)); else ps.setNull(6, Types.TIMESTAMP);
            int affected = ps.executeUpdate();
            if (affected > 0) {
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (keys.next()) return keys.getInt(1);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return -1;
    }

    @Override
    public int insertMilestone(int parentTaskId, String title, String description, LocalDateTime dueDate) {
        // Milestone kế thừa AssignedTo + CreatedBy của Dự án cha — cùng 1 người phụ trách.
        String sql = "INSERT INTO Tasks (Title, Description, TaskType, Priority, Status, AssignedTo, CreatedBy, DueDate, ParentTaskID) " +
                "SELECT ?, ?, 'MANUAL', p.Priority, 'PENDING', p.AssignedTo, p.CreatedBy, ?, p.TaskID " +
                "FROM Tasks p WHERE p.TaskID = ? AND p.IsProject = 1";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setNString(1, title);
            ps.setNString(2, description);
            if (dueDate != null) ps.setTimestamp(3, Timestamp.valueOf(dueDate)); else ps.setNull(3, Types.TIMESTAMP);
            ps.setInt(4, parentTaskId);
            int affected = ps.executeUpdate();
            if (affected > 0) {
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (keys.next()) return keys.getInt(1);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return -1;
    }

    @Override
    public List<Task> findMilestones(int parentTaskId) {
        List<Task> list = new ArrayList<>();
        String sql = SELECT_JOINED + "WHERE t.ParentTaskID = ? ORDER BY t.TaskID ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, parentTaskId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<Task> findMyProjects(int accountId) {
        List<Task> list = new ArrayList<>();
        String sql = SELECT_JOINED +
                "WHERE t.IsProject = 1 AND t.AssignedTo = ? AND t.Status <> 'CANCELLED' " +
                "ORDER BY t.DueDate ASC, t.CreatedAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public void recalcProjectProgress(int parentTaskId) {
        // % tiến độ = milestone COMPLETED_ON_TIME/LATE / tổng milestone (CANCELLED không tính vào tổng).
        String sql = "UPDATE Tasks SET ProgressPercentage = ISNULL((" +
                "  SELECT CAST(ROUND(100.0 * SUM(CASE WHEN m.Status IN ('COMPLETED_ON_TIME','COMPLETED_LATE') THEN 1 ELSE 0 END) " +
                "         / NULLIF(COUNT(*), 0), 0) AS INT) " +
                "  FROM Tasks m WHERE m.ParentTaskID = ? AND m.Status <> 'CANCELLED'" +
                "), 0) WHERE TaskID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, parentTaskId);
            ps.setInt(2, parentTaskId);
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }

    // ── Admin: Watchdog / Kanban / KPI Audit ──

    @Override
    public List<Task> findWatchdog() {
        List<Task> list = new ArrayList<>();
        String sql = SELECT_JOINED +
                "WHERE t.DueDate IS NOT NULL AND t.Status IN ('PENDING','IN_PROGRESS') " +
                "AND t.DueDate <= DATEADD(HOUR, 48, GETDATE()) " +
                "ORDER BY t.DueDate ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<Task> findKanban() {
        List<Task> list = new ArrayList<>();
        String sql = SELECT_JOINED +
                "WHERE t.Status <> 'CANCELLED' " +
                "ORDER BY CASE t.Status WHEN 'PENDING' THEN 1 WHEN 'IN_PROGRESS' THEN 2 ELSE 3 END, " +
                "CASE t.Priority WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 ELSE 3 END, t.CreatedAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<Task> findKpiAudit() {
        List<Task> list = new ArrayList<>();
        String sql = SELECT_JOINED +
                "WHERE t.Status IN ('COMPLETED_ON_TIME','COMPLETED_LATE') " +
                "ORDER BY t.CompletedAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }
}
