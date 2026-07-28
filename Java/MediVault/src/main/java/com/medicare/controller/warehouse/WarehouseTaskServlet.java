package com.medicare.controller.warehouse;

import com.medicare.config.CacheManager;
import com.medicare.dao.AccountDAO;
import com.medicare.dao.TaskDAO;
import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.dao.interfaces.ITaskDAO;
import com.medicare.entity.Account;
import com.medicare.entity.Task;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * WarehouseTaskServlet — "Quản Lý Task &amp; SOP (To-do List)", tab thứ 2 trong 5 tab
 * Backoffice của mục 5 (portal Quản lý kho, roleId 3). Type A (system-auto, xem
 * {@link com.medicare.service.TaskAutoGenService}) hiển thị lẫn với Type B (Manager tự
 * tạo/giao qua form POST action=create ở đây).
 * URL: /warehouse-task?uid=&lt;id&gt;
 */
@WebServlet("/warehouse-task")
public class WarehouseTaskServlet extends HttpServlet {

    private static final int ROLE_WAREHOUSE = 3;

    private final ITaskDAO taskDAO = new TaskDAO();
    private final IAccountDAO accountDAO = new AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String uid = req.getParameter("uid");
        HttpSession session = req.getSession(false);
        Account acc = (uid != null && session != null)
                ? (Account) session.getAttribute("staffAccount_" + uid) : null;
        if (acc == null || acc.getRoleId() != ROLE_WAREHOUSE) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login");
            return;
        }

        String statusFilter   = req.getParameter("status");
        String priorityFilter = req.getParameter("priority");

        req.setAttribute("staffUid", uid);
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

        String uid = req.getParameter("uid");
        HttpSession session = req.getSession(false);
        Account acc = (uid != null && session != null)
                ? (Account) session.getAttribute("staffAccount_" + uid) : null;
        if (acc == null || acc.getRoleId() != ROLE_WAREHOUSE) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login");
            return;
        }

        String action = req.getParameter("action");
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
                }
                case "complete" -> {
                    int taskId = Integer.parseInt(req.getParameter("taskId"));
                    ok = taskDAO.markComplete(taskId, acc.getAccountId());
                    msg = ok ? "Đã đánh dấu hoàn thành!" : "Task không tồn tại hoặc đã đóng.";
                }
                case "cancel" -> {
                    int taskId = Integer.parseInt(req.getParameter("taskId"));
                    ok = taskDAO.cancel(taskId);
                    msg = ok ? "Đã huỷ task." : "Task không tồn tại hoặc đã đóng.";
                }
                default -> msg = "Thao tác không hợp lệ.";
            }
        } catch (NumberFormatException e) {
            msg = "Dữ liệu không hợp lệ.";
        }

        String encoded = java.net.URLEncoder.encode(msg, java.nio.charset.StandardCharsets.UTF_8);
        resp.sendRedirect(req.getContextPath() + "/warehouse-task?uid=" + uid + "&msg=" + encoded + "&ok=" + ok);
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
        return taskId > 0 ? null : "Không thể tạo công việc, vui lòng thử lại.";
    }
}
