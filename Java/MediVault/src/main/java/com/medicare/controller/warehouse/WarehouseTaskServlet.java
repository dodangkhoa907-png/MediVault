package com.medicare.controller.warehouse;

import com.medicare.config.CacheManager;
import com.medicare.dao.AccountDAO;
import com.medicare.dao.TaskDAO;
import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.dao.interfaces.ITaskDAO;
import com.medicare.entity.Account;
import com.medicare.entity.Task;
import com.medicare.util.AuditHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * WarehouseTaskServlet — "Quản Lý Task &amp; SOP (To-do List)", tab thứ 2 trong 5 tab
 * Backoffice của mục 5 (portal Quản lý kho, roleId 3). Type A (system-auto, xem
 * {@link com.medicare.service.TaskAutoGenService}) hiển thị lẫn với Type B (Manager tự
 * tạo/giao qua form POST action=create ở đây).
 * URL: /warehouse-task
 */
@WebServlet("/warehouse-task")
public class WarehouseTaskServlet extends HttpServlet {

    private static final int ROLE_WAREHOUSE = 3;

    private final ITaskDAO taskDAO = new TaskDAO();
    private final IAccountDAO accountDAO = new AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        Account acc = com.medicare.util.WarehouseAuth.require(req, resp);
        if (acc == null) return;

        // ── Kanban redesign — Task Detail panel (AJAX JSON) ──
        if ("task-detail".equals(req.getParameter("action"))) {
            apiTaskDetail(req, resp);
            return;
        }

        String statusFilter   = req.getParameter("status");
        String priorityFilter = req.getParameter("priority");

        req.setAttribute("staffAcc", acc);
        req.setAttribute("myTasks", taskDAO.findMyOpenTasks(acc.getAccountId()));
        req.setAttribute("board", taskDAO.findBoard(statusFilter, priorityFilter));
        req.setAttribute("statusFilter", statusFilter);
        req.setAttribute("priorityFilter", priorityFilter);

        List<Account> assignees = CacheManager.getShort("wh.taskAssignees",
                () -> accountDAO.findAllStaff().stream()
                        .filter(a -> a.getRoleId() == ROLE_WAREHOUSE)
                        .collect(Collectors.toList()));
        req.setAttribute("assignees", assignees);
        req.setAttribute("myOpenTaskCount", taskDAO.countMyOpenTasks(acc.getAccountId()));
        // Trang này trước đây chỉ set myOpenTaskCount, thiếu expiryCount ⇒ badge "Quản lý
        // tồn kho" trên sidebar biến mất khi đứng ở trang Nhiệm vụ. loadWarehouse() không
        // ghi đè myOpenTaskCount vừa set ở trên (chỉ set khi còn null), chỉ bổ sung expiryCount.
        com.medicare.util.SidebarHelper.loadWarehouse(req, acc.getAccountId());

        // ── Dự án dài hạn (Strategic Projects) — mục IV.2 tài liệu, Admin giao qua /task-management ──
        List<Task> myProjects = taskDAO.findMyProjects(acc.getAccountId());
        Map<Integer, List<Task>> milestonesByProject = new LinkedHashMap<>();
        for (Task p : myProjects) milestonesByProject.put(p.getTaskId(), taskDAO.findMilestones(p.getTaskId()));
        req.setAttribute("myProjects", myProjects);
        req.setAttribute("milestonesByProject", milestonesByProject);

        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-task.jsp")
                .forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        Account acc = com.medicare.util.WarehouseAuth.require(req, resp);
        if (acc == null) return;

        String action = req.getParameter("action");

        // ── Kanban redesign — action AJAX JSON (kéo-thả, checklist, comment) ──
        if (WH_AJAX_ACTIONS.contains(action)) {
            handleWhAjaxAction(req, resp, acc, action);
            return;
        }

        boolean ok = false;
        String msg;

        try {
            switch (action == null ? "" : action) {
                case "create" -> {
                    msg = handleCreate(req, acc);
                    ok = msg == null;
                    if (ok) msg = "Đã tạo công việc mới!";
                }
                case "claim" -> {
                    int taskId = Integer.parseInt(req.getParameter("taskId"));
                    ok = taskDAO.claim(taskId, acc.getAccountId());
                    msg = ok ? "Đã nhận việc thành công!" : "Task này đã có người nhận rồi.";
                    if (ok) AuditHelper.log(req, "Nhận task", "Tasks", "TaskID=" + taskId, acc.getAccountId());
                }
                case "complete" -> {
                    int taskId = Integer.parseInt(req.getParameter("taskId"));
                    ok = taskDAO.markComplete(taskId, acc.getAccountId());
                    msg = ok ? "Đã đánh dấu hoàn thành!" : "Task không tồn tại hoặc đã đóng.";
                    if (ok) AuditHelper.log(req, "Báo hoàn thành task", "Tasks", "TaskID=" + taskId, acc.getAccountId());
                }
                case "cancel" -> {
                    int taskId = Integer.parseInt(req.getParameter("taskId"));
                    ok = taskDAO.cancel(taskId);
                    msg = ok ? "Đã huỷ task." : "Task không tồn tại hoặc đã đóng.";
                    if (ok) AuditHelper.log(req, "Huỷ task (Thủ kho)", "Tasks", "TaskID=" + taskId, acc.getAccountId());
                }
                default -> msg = "Thao tác không hợp lệ.";
            }
        } catch (NumberFormatException e) {
            msg = "Dữ liệu không hợp lệ.";
        }

        // Bảng kanban kéo-thả gọi đúng 3 action claim/complete/cancel ở trên qua fetch,
        // nên chỉ cần trả JSON thay vì redirect — không có luồng nghiệp vụ nào mới, và
        // form submit thường (không JS) vẫn redirect y như cũ.
        if ("1".equals(req.getParameter("ajax"))) {
            resp.setContentType("application/json;charset=UTF-8");
            resp.setHeader("Cache-Control", "no-store");
            resp.getWriter().print("{\"ok\":" + ok + ",\"msg\":\"" +
                    msg.replace("\\", "\\\\").replace("\"", "\\\"") + "\"}");
            return;
        }

        String encoded = java.net.URLEncoder.encode(msg, java.nio.charset.StandardCharsets.UTF_8);
        resp.sendRedirect(req.getContextPath() + "/warehouse-task?msg=" + encoded + "&ok=" + ok);
    }

    private String handleCreate(HttpServletRequest req, Account acc) {
        String title = req.getParameter("title");
        if (title == null || title.isBlank()) return "Tiêu đề công việc không được để trống.";
        title = title.trim();
        if (title.length() > 255) title = title.substring(0, 255);

        String description = req.getParameter("description");
        if (description != null && description.length() > 1000) description = description.substring(0, 1000);

        String priority = req.getParameter("priority");
        if (!"HIGH".equals(priority) && !"MEDIUM".equals(priority) && !"LOW".equals(priority)) priority = "MEDIUM";

        Integer assignedTo = null;
        String assignedToRaw = req.getParameter("assignedTo");
        if (assignedToRaw != null && !assignedToRaw.isBlank()) {
            try { assignedTo = Integer.parseInt(assignedToRaw); } catch (NumberFormatException ignored) { }
        }

        LocalDateTime dueDate = null;
        String dueDateRaw = req.getParameter("dueDate"); // input type=datetime-local -> "yyyy-MM-ddTHH:mm"
        if (dueDateRaw != null && !dueDateRaw.isBlank()) {
            try { dueDate = LocalDateTime.parse(dueDateRaw); } catch (Exception ignored) { }
        }

        int taskId = taskDAO.insertManualTask(title, description, priority, assignedTo, acc.getAccountId(), dueDate);
        if (taskId <= 0) return "Không thể tạo công việc, vui lòng thử lại.";
        AuditHelper.log(req, "Tạo công việc (Thủ kho)", "Tasks", "TaskID=" + taskId + ": " + title, acc.getAccountId());
        return null;
    }

    private static final java.util.Set<String> WH_AJAX_ACTIONS = java.util.Set.of(
            "move-status", "checklist-add", "checklist-toggle", "checklist-delete", "comment-add");

    /** Kéo-thả Kanban ("Nhiệm vụ của tôi" cũng dùng chung) + checklist + comment. */
    private void handleWhAjaxAction(HttpServletRequest req, HttpServletResponse resp, Account acc, String action)
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
                            "TaskID=" + taskId + " → " + newStatus, acc.getAccountId());
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
                    int id = taskDAO.addComment(taskId, acc.getAccountId(), body.trim());
                    out.print(id > 0 ? "{\"ok\":true,\"id\":" + id + "}" : "{\"ok\":false}");
                }
                default -> out.print("{\"ok\":false}");
            }
        } catch (Exception e) {
            out.print("{\"ok\":false}");
        }
    }

    /** action=task-detail&id= — JSON đầy đủ cho Task Detail panel (Nhiệm vụ của tôi + Board). */
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

            StringBuilder sb = new StringBuilder("{\"ok\":true,\"task\":").append(taskJson(t)).append(",\"checklist\":[");
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
            sb.append("]}}");
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
                + ",\"assignedToName\":" + jstr(t.getAssignedToName())
                + ",\"createdByName\":" + jstr(t.getCreatedByName())
                + ",\"dueDate\":" + jstr(t.getDueDate() != null ? t.getDueDate().format(dtf) : "")
                + ",\"createdAt\":" + jstr(t.getCreatedAt() != null ? t.getCreatedAt().format(dtf) : "")
                + ",\"zone\":" + jstr(t.getZone())
                + ",\"estimatedHours\":" + (t.getEstimatedHours() != null ? t.getEstimatedHours().toPlainString() : "null")
                + "}";
    }

    private String jstr(String s) {
        if (s == null) return "\"\"";
        return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r") + "\"";
    }
}
