package com.medicare.controller.admin;

import com.medicare.dao.AccountDAO;
import com.medicare.dao.TaskDAO;
import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.dao.interfaces.ITaskDAO;
import com.medicare.entity.Account;
import com.medicare.entity.Task;
import com.medicare.util.AuditHelper;
import com.medicare.util.SidebarHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

/**
 * TaskManagementServlet — "🎯 Giao task & Tiến độ kho", trang Admin mới theo tài liệu
 * "Phân hệ Quản lý &amp; Giao Task Thủ kho" mục III. Admin TẠO/HUỶ task &amp; dự án,
 * theo dõi Kanban + Watchdog + KPI Audit; việc BÁO HOÀN THÀNH vẫn do Thủ kho tự bấm
 * bên {@code warehouse-task.jsp} (đúng phân vai: Admin giao — Thủ kho báo xong).
 *
 * URL: /task-management
 */
@WebServlet("/task-management")
public class TaskManagementServlet extends HttpServlet {

    private static final int ROLE_WAREHOUSE = 3;

    private final ITaskDAO taskDAO = new TaskDAO();
    private final IAccountDAO accountDAO = new AccountDAO();

    private static final java.util.Set<String> AJAX_ACTIONS = java.util.Set.of(
            "move-status", "assign", "checklist-add", "checklist-toggle", "checklist-delete", "comment-add");

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        Account admin = requireAdmin(req, resp);
        if (admin == null) return;

        // ── Kanban redesign — Task Detail panel (AJAX JSON), không render lại cả trang ──
        if ("task-detail".equals(req.getParameter("action"))) {
            apiTaskDetail(req, resp);
            return;
        }

        List<Task> watchdog = taskDAO.findWatchdog();
        List<Task> kanban = taskDAO.findKanban();
        List<Task> kpiAudit = taskDAO.findKpiAudit();
        List<Account> warehouseStaff = accountDAO.findAllStaff().stream()
                .filter(a -> a.getRoleId() == ROLE_WAREHOUSE)
                .collect(Collectors.toList());

        req.setAttribute("watchdog", watchdog);
        req.setAttribute("kanban", kanban);
        req.setAttribute("kpiAudit", kpiAudit);
        req.setAttribute("warehouseStaff", warehouseStaff);
        req.setAttribute("fullName", admin.getFullName());
        req.setAttribute("initials", initialsOf(admin));

        // ── Analytics (bottom charts) ──
        java.util.Map<String, Integer> statByStatus   = taskDAO.countByStatusAll();
        java.util.Map<String, Integer> statByModule    = taskDAO.countByModule();
        java.util.Map<String, Integer> statByAssignee = taskDAO.countByAssignee();
        java.util.Map<String, Integer> statByPriority = taskDAO.countByPriority();
        req.setAttribute("statByStatus",   statByStatus);
        req.setAttribute("statByAssignee", statByAssignee);
        req.setAttribute("statByModule",   statByModule);
        req.setAttribute("statByPriority", statByPriority);
        req.setAttribute("avgCompletionHours", taskDAO.avgCompletionHours());
        req.setAttribute("overdueCount",       taskDAO.countOverdue());

        // EL không tự serialize Map sang JSON (${map} chỉ in ra Map.toString() kiểu Java,
        // KHÔNG parse được bằng JS) — build sẵn JSON string ở đây, JSP chỉ nhúng thẳng.
        req.setAttribute("statByStatusJson",   mapToJson(statByStatus));
        req.setAttribute("statByAssigneeJson", mapToJson(statByAssignee));
        req.setAttribute("statByModuleJson",   mapToJson(statByModule));
        req.setAttribute("statByPriorityJson", mapToJson(statByPriority));

        // ── Summary cards (Row 1) — tính sẵn ở tầng Java, JSP chỉ hiển thị ──
        int totalTasks = statByStatus.values().stream().mapToInt(Integer::intValue).sum();
        long todayTasks = kanban.stream().filter(t -> t.getDueDate() != null
                && t.getDueDate().toLocalDate().equals(java.time.LocalDate.now())).count();
        long inProgressCount = kanban.stream().filter(t -> "IN_PROGRESS".equals(t.getStatus())).count();
        long highPriorityCount = kanban.stream().filter(t -> "HIGH".equals(t.getPriority()) && !t.isDone()).count();
        int warehouseRelated = statByModule.entrySet().stream()
                .filter(e -> !"Chung".equals(e.getKey())).mapToInt(java.util.Map.Entry::getValue).sum();
        req.setAttribute("totalTasks", totalTasks);
        req.setAttribute("todayTasksCount", todayTasks);
        req.setAttribute("inProgressCount", inProgressCount);
        req.setAttribute("highPriorityCount", highPriorityCount);
        req.setAttribute("warehouseRelatedCount", warehouseRelated);
        req.setAttribute("completedCount", kpiAudit.size());

        // ── Kanban redesign — toàn bộ dữ liệu board nhúng sẵn dạng JSON (SSR, cùng kiểu Audit
        // Center) để JS vẽ 7 cột + kéo-thả, không cần round-trip AJAX riêng lúc tải trang. ──
        StringBuilder kb = new StringBuilder("[");
        for (int i = 0; i < kanban.size(); i++) {
            if (i > 0) kb.append(',');
            kb.append(taskJson(kanban.get(i)));
        }
        kb.append(']');
        req.setAttribute("kanbanTasksJson", kb.toString());

        SidebarHelper.load(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/task-management.jsp").forward(req, resp);
    }

    /** action=task-detail&id= — JSON đầy đủ cho Task Detail panel: task + checklist + comment
     *  + Warehouse Information (TaskRefResolver giải mã RefTable/RefID) + milestone (nếu là dự án). */
    private void apiTaskDetail(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        PrintWriter out = resp.getWriter();
        try {
            int id = Integer.parseInt(req.getParameter("id"));
            Task t = taskDAO.findById(id);
            if (t == null) { out.print("{\"ok\":false}"); return; }

            com.medicare.util.TaskRefResolver.RefInfo ref =
                    com.medicare.util.TaskRefResolver.resolve(t.getRefTable(), t.getRefId());

            StringBuilder sb = new StringBuilder("{\"ok\":true,\"task\":").append(taskJson(t))
                    .append(",\"checklist\":[");
            List<com.medicare.entity.TaskChecklistItem> items = taskDAO.findChecklist(id);
            for (int i = 0; i < items.size(); i++) {
                if (i > 0) sb.append(',');
                var it = items.get(i);
                sb.append("{\"id\":").append(it.getChecklistItemId())
                  .append(",\"text\":").append(jstr(it.getItemText()))
                  .append(",\"done\":").append(it.isDone()).append('}');
            }
            sb.append("],\"comments\":[");
            List<com.medicare.entity.TaskComment> comments = taskDAO.findComments(id);
            DateTimeFormatter dtf = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
            for (int i = 0; i < comments.size(); i++) {
                if (i > 0) sb.append(',');
                var c = comments.get(i);
                sb.append("{\"id\":").append(c.getTaskCommentId())
                  .append(",\"name\":").append(jstr(c.getAccountName()))
                  .append(",\"body\":").append(jstr(c.getBody()))
                  .append(",\"time\":").append(jstr(c.getCreatedAt() != null ? c.getCreatedAt().format(dtf) : ""))
                  .append('}');
            }
            sb.append("],\"ref\":{\"found\":").append(ref.found)
              .append(",\"module\":").append(jstr(ref.moduleLabel))
              .append(",\"title\":").append(jstr(ref.title))
              .append(",\"rows\":[");
            for (int i = 0; i < ref.rows.size(); i++) {
                if (i > 0) sb.append(',');
                sb.append("[").append(jstr(ref.rows.get(i)[0])).append(',').append(jstr(ref.rows.get(i)[1])).append(']');
            }
            sb.append("]}");
            if (t.getIsProject()) {
                sb.append(",\"milestones\":[");
                List<Task> ms = taskDAO.findMilestones(id);
                for (int i = 0; i < ms.size(); i++) {
                    if (i > 0) sb.append(',');
                    sb.append(taskJson(ms.get(i)));
                }
                sb.append(']');
            }
            sb.append('}');
            out.print(sb);
        } catch (Exception e) {
            out.print("{\"ok\":false}");
        }
    }

    private String taskJson(Task t) {
        DateTimeFormatter dtf = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
        return "{\"id\":" + t.getTaskId()
                + ",\"title\":" + jstr(t.getTitle())
                + ",\"description\":" + jstr(t.getDescription())
                + ",\"status\":" + jstr(t.getStatus())
                + ",\"statusLabel\":" + jstr(t.getStatusLabel())
                + ",\"column\":" + jstr(t.getKanbanColumn())
                + ",\"priority\":" + jstr(t.getPriority())
                + ",\"priorityLabel\":" + jstr(t.getPriorityLabel())
                + ",\"taskType\":" + jstr(t.getTaskType())
                + ",\"assignedTo\":" + (t.getAssignedTo() != null ? t.getAssignedTo() : "null")
                + ",\"assignedToName\":" + jstr(t.getAssignedToName())
                + ",\"createdByName\":" + jstr(t.getCreatedByName())
                + ",\"completedByName\":" + jstr(t.getCompletedByName())
                + ",\"dueDate\":" + jstr(t.getDueDate() != null ? t.getDueDate().format(dtf) : "")
                + ",\"createdAt\":" + jstr(t.getCreatedAt() != null ? t.getCreatedAt().format(dtf) : "")
                + ",\"completedAt\":" + jstr(t.getCompletedAt() != null ? t.getCompletedAt().format(dtf) : "")
                + ",\"zone\":" + jstr(t.getZone())
                + ",\"isProject\":" + t.getIsProject()
                + ",\"progressPercentage\":" + t.getProgressPercentage()
                + ",\"estimatedHours\":" + (t.getEstimatedHours() != null ? t.getEstimatedHours().toPlainString() : "null")
                + ",\"refTable\":" + jstr(t.getRefTable())
                + ",\"refId\":" + (t.getRefId() != null ? t.getRefId() : "null")
                + ",\"module\":" + jstr(com.medicare.util.TaskRefResolver.moduleLabel(t.getRefTable()))
                + "}";
    }

    private String mapToJson(java.util.Map<String, Integer> map) {
        StringBuilder sb = new StringBuilder("{");
        boolean first = true;
        for (var e : map.entrySet()) {
            if (!first) sb.append(',');
            first = false;
            sb.append(jstr(e.getKey())).append(':').append(e.getValue());
        }
        return sb.append('}').toString();
    }

    private String jstr(String s) {
        if (s == null) return "\"\"";
        return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r") + "\"";
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        Account admin = requireAdmin(req, resp);
        if (admin == null) return;

        String action = req.getParameter("action");

        // ── Kanban redesign — action AJAX JSON (kéo-thả, checklist, comment) ──
        if (AJAX_ACTIONS.contains(action)) {
            handleAjaxAction(req, resp, admin, action);
            return;
        }

        boolean ok;
        String msg;

        try {
            switch (action == null ? "" : action) {
                case "create-task" -> {
                    msg = handleCreateTask(req, admin);
                    ok = msg == null;
                    if (ok) msg = "Đã giao task mới!";
                }
                case "create-project" -> {
                    msg = handleCreateProject(req, admin);
                    ok = msg == null;
                    if (ok) msg = "Đã tạo Dự án dài hạn mới!";
                }
                case "cancel" -> {
                    int taskId = Integer.parseInt(req.getParameter("taskId"));
                    ok = taskDAO.cancel(taskId);
                    msg = ok ? "Đã huỷ." : "Không huỷ được (đã xong hoặc đã huỷ trước đó).";
                    if (ok) AuditHelper.log(req, "Huỷ task/dự án", "Tasks", "TaskID=" + taskId, admin.getAccountId());
                }
                default -> { ok = false; msg = "Thao tác không hợp lệ."; }
            }
        } catch (NumberFormatException e) {
            ok = false; msg = "Dữ liệu không hợp lệ.";
        }

        String encoded = URLEncoder.encode(msg, StandardCharsets.UTF_8);
        resp.sendRedirect(req.getContextPath() + "/task-management?msg=" + encoded + "&ok=" + ok);
    }

    /** Kéo-thả Kanban + checklist + comment — mọi thao tác "vặt" trên Task Detail panel, trả
     *  JSON gọn, KHÔNG redirect/reload cả trang (đúng tinh thần "no popup, quick feedback"). */
    private void handleAjaxAction(HttpServletRequest req, HttpServletResponse resp, Account admin, String action)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        try {
            switch (action) {
                case "move-status" -> {
                    int taskId = Integer.parseInt(req.getParameter("taskId"));
                    String newStatus = req.getParameter("status");
                    boolean ok = taskDAO.moveStatus(taskId, newStatus);
                    if (ok) AuditHelper.log(req, "Đổi trạng thái task", "Tasks",
                            "TaskID=" + taskId + " → " + newStatus, admin.getAccountId());
                    out.print(ok ? "{\"ok\":true}" : "{\"ok\":false}");
                }
                case "assign" -> {
                    int taskId = Integer.parseInt(req.getParameter("taskId"));
                    Integer accountId = parseIntOrNull(req.getParameter("accountId"));
                    boolean ok = taskDAO.assign(taskId, accountId);
                    if (ok) AuditHelper.log(req, "Gán người phụ trách task", "Tasks",
                            "TaskID=" + taskId + " → " + (accountId != null ? "#" + accountId : "bỏ gán"), admin.getAccountId());
                    out.print(ok ? "{\"ok\":true}" : "{\"ok\":false}");
                }
                case "checklist-add" -> {
                    int taskId = Integer.parseInt(req.getParameter("taskId"));
                    String text = req.getParameter("text");
                    if (text == null || text.isBlank()) { out.print("{\"ok\":false}"); return; }
                    int id = taskDAO.addChecklistItem(taskId, text.trim());
                    out.print(id > 0 ? "{\"ok\":true,\"id\":" + id + "}" : "{\"ok\":false}");
                }
                case "checklist-toggle" -> {
                    int itemId = Integer.parseInt(req.getParameter("itemId"));
                    boolean done = "true".equals(req.getParameter("done"));
                    out.print(taskDAO.toggleChecklistItem(itemId, done) ? "{\"ok\":true}" : "{\"ok\":false}");
                }
                case "checklist-delete" -> {
                    int itemId = Integer.parseInt(req.getParameter("itemId"));
                    out.print(taskDAO.deleteChecklistItem(itemId) ? "{\"ok\":true}" : "{\"ok\":false}");
                }
                case "comment-add" -> {
                    int taskId = Integer.parseInt(req.getParameter("taskId"));
                    String body = req.getParameter("body");
                    if (body == null || body.isBlank()) { out.print("{\"ok\":false}"); return; }
                    int id = taskDAO.addComment(taskId, admin.getAccountId(), body.trim());
                    out.print(id > 0 ? "{\"ok\":true,\"id\":" + id + "}" : "{\"ok\":false}");
                }
                default -> out.print("{\"ok\":false}");
            }
        } catch (Exception e) {
            out.print("{\"ok\":false}");
        }
    }

    private String handleCreateTask(HttpServletRequest req, Account admin) {
        String title = req.getParameter("title");
        if (title == null || title.isBlank()) return "Tiêu đề không được để trống.";
        title = title.trim();
        if (title.length() > 255) title = title.substring(0, 255);

        String description = req.getParameter("description");
        if (description == null || description.isBlank()) return "Mô tả không được để trống — ghi rõ yêu cầu cho Thủ kho.";
        description = description.trim();
        if (description.length() > 1000) description = description.substring(0, 1000);

        String priority = req.getParameter("priority");
        if (!"HIGH".equals(priority) && !"MEDIUM".equals(priority) && !"LOW".equals(priority)) priority = "MEDIUM";

        Integer assignedTo = parseIntOrNull(req.getParameter("assignedTo"));

        String dueDateRaw = req.getParameter("dueDate");
        if (dueDateRaw == null || dueDateRaw.isBlank()) return "Hạn báo xong trước không được để trống.";
        LocalDateTime dueDate = parseDateTimeOrNull(dueDateRaw);
        if (dueDate == null) return "Hạn báo xong trước không hợp lệ.";
        if (dueDate.isBefore(LocalDateTime.now())) return "Hạn báo xong trước phải là một thời điểm trong TƯƠNG LAI, không thể chọn ngày/giờ đã qua.";

        int taskId = taskDAO.insertManualTask(title, description, priority, assignedTo, admin.getAccountId(), dueDate);
        if (taskId > 0) {
            // Estimated Hours / RefTable+RefID — cả 2 đều TÙY CHỌN (advanced), không bắt buộc
            // như 5 trường trên. RefTable/RefID gõ tay (chưa có picker tìm lô/thuốc/PO trong
            // drawer) — người giao việc phải biết đúng ID nếu muốn liên kết tới 1 bản ghi kho.
            java.math.BigDecimal estHours = parseHoursOrNull(req.getParameter("estimatedHours"));
            String refTable = req.getParameter("refTable");
            Integer refId = parseIntOrNull(req.getParameter("refId"));
            if (estHours != null || (refTable != null && !refTable.isBlank() && refId != null)) {
                taskDAO.updateExtras(taskId, estHours, refTable, refId);
            }
            AuditHelper.log(req, "Giao task", "Tasks", "TaskID=" + taskId + ": " + title, admin.getAccountId());
            return null;
        }
        return "Không thể tạo task, vui lòng thử lại.";
    }

    private String handleCreateProject(HttpServletRequest req, Account admin) {
        String title = req.getParameter("title");
        if (title == null || title.isBlank()) return "Tên Dự án không được để trống.";
        title = title.trim();
        if (title.length() > 255) title = title.substring(0, 255);

        String description = req.getParameter("description");
        if (description == null || description.isBlank()) return "Mô tả không được để trống — ghi rõ bối cảnh/mục tiêu chiến dịch.";
        description = description.trim();
        if (description.length() > 1000) description = description.substring(0, 1000);

        String priority = req.getParameter("priority");
        if (!"HIGH".equals(priority) && !"MEDIUM".equals(priority) && !"LOW".equals(priority)) priority = "MEDIUM";

        Integer assignedTo = parseIntOrNull(req.getParameter("assignedTo"));
        if (assignedTo == null) return "Dự án dài hạn bắt buộc phải giao cho 1 Thủ kho cụ thể.";

        String dueDateRaw = req.getParameter("dueDate");
        if (dueDateRaw == null || dueDateRaw.isBlank()) return "Hạn báo cáo tổng không được để trống.";
        LocalDateTime dueDate = parseDateTimeOrNull(dueDateRaw);
        if (dueDate == null) return "Hạn báo cáo tổng không hợp lệ.";
        if (dueDate.isBefore(LocalDateTime.now())) return "Hạn báo cáo tổng phải là một thời điểm trong TƯƠNG LAI, không thể chọn ngày/giờ đã qua.";

        // Mốc con (milestones) — validate TRƯỚC KHI tạo Dự án, tránh tạo dở dang nếu 1 mốc sai
        String[] mTitles = req.getParameterValues("milestoneTitle");
        String[] mDueDates = req.getParameterValues("milestoneDueDate");
        if (mTitles != null) {
            for (int i = 0; i < mTitles.length; i++) {
                if (mTitles[i] == null || mTitles[i].isBlank()) continue;
                String mDueRaw = (mDueDates != null && i < mDueDates.length) ? mDueDates[i] : null;
                if (mDueRaw != null && !mDueRaw.isBlank()) {
                    LocalDateTime mDue = parseDateTimeOrNull(mDueRaw);
                    if (mDue == null) return "Hạn mốc \"" + mTitles[i].trim() + "\" không hợp lệ.";
                    if (mDue.isBefore(LocalDateTime.now()))
                        return "Hạn mốc \"" + mTitles[i].trim() + "\" phải ở tương lai, không thể chọn ngày/giờ đã qua.";
                }
            }
        }

        int projectId = taskDAO.insertProject(title, description, priority, assignedTo, admin.getAccountId(), dueDate);
        if (projectId <= 0) return "Không thể tạo Dự án, vui lòng thử lại.";

        int created = 0;
        if (mTitles != null) {
            for (int i = 0; i < mTitles.length; i++) {
                if (mTitles[i] == null || mTitles[i].isBlank()) continue;
                LocalDateTime mDue = (mDueDates != null && i < mDueDates.length)
                        ? parseDateTimeOrNull(mDueDates[i]) : null;
                if (taskDAO.insertMilestone(projectId, mTitles[i].trim(), null, mDue) > 0) created++;
            }
        }
        if (created > 0) taskDAO.recalcProjectProgress(projectId);

        AuditHelper.log(req, "Tạo dự án dài hạn", "Tasks",
                "TaskID=" + projectId + ": " + title + " (" + created + " mốc)", admin.getAccountId());
        return null;
    }

    private Integer parseIntOrNull(String s) {
        if (s == null || s.isBlank()) return null;
        try { return Integer.parseInt(s.trim()); } catch (NumberFormatException e) { return null; }
    }

    private java.math.BigDecimal parseHoursOrNull(String s) {
        if (s == null || s.isBlank()) return null;
        try { return new java.math.BigDecimal(s.trim()); } catch (NumberFormatException e) { return null; }
    }

    private LocalDateTime parseDateTimeOrNull(String s) {
        if (s == null || s.isBlank()) return null;
        try { return LocalDateTime.parse(s); } catch (Exception e) { return null; } // input type=datetime-local
    }

    private String initialsOf(Account acc) {
        String name = acc.getFullName() != null && !acc.getFullName().isEmpty() ? acc.getFullName() : acc.getUsername();
        return name.substring(0, 1).toUpperCase();
    }

    private Account requireAdmin(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        HttpSession session = req.getSession(false);
        Account admin = session != null ? (Account) session.getAttribute("adminAccount") : null;
        if (admin == null || admin.getRoleId() != 1) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return null;
        }
        return admin;
    }
}
