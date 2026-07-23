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
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
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

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        Account admin = requireAdmin(req, resp);
        if (admin == null) return;

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

        SidebarHelper.load(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/task-management.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        Account admin = requireAdmin(req, resp);
        if (admin == null) return;

        String action = req.getParameter("action");
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

    private String handleCreateTask(HttpServletRequest req, Account admin) {
        String title = req.getParameter("title");
        if (title == null || title.isBlank()) return "Tiêu đề không được để trống.";
        title = title.trim();
        if (title.length() > 255) title = title.substring(0, 255);

        String description = req.getParameter("description");
        if (description != null && description.length() > 1000) description = description.substring(0, 1000);

        String priority = req.getParameter("priority");
        if (!"HIGH".equals(priority) && !"MEDIUM".equals(priority) && !"LOW".equals(priority)) priority = "MEDIUM";

        Integer assignedTo = parseIntOrNull(req.getParameter("assignedTo"));
        LocalDateTime dueDate = parseDateTimeOrNull(req.getParameter("dueDate"));

        int taskId = taskDAO.insertManualTask(title, description, priority, assignedTo, admin.getAccountId(), dueDate);
        if (taskId > 0) {
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
        if (description != null && description.length() > 1000) description = description.substring(0, 1000);

        String priority = req.getParameter("priority");
        if (!"HIGH".equals(priority) && !"MEDIUM".equals(priority) && !"LOW".equals(priority)) priority = "MEDIUM";

        Integer assignedTo = parseIntOrNull(req.getParameter("assignedTo"));
        if (assignedTo == null) return "Dự án dài hạn bắt buộc phải giao cho 1 Thủ kho cụ thể.";
        LocalDateTime dueDate = parseDateTimeOrNull(req.getParameter("dueDate"));

        int projectId = taskDAO.insertProject(title, description, priority, assignedTo, admin.getAccountId(), dueDate);
        if (projectId <= 0) return "Không thể tạo Dự án, vui lòng thử lại.";

        // Mốc con (milestones) — 2 mảng song song milestoneTitle[]/milestoneDueDate[]
        String[] mTitles = req.getParameterValues("milestoneTitle");
        String[] mDueDates = req.getParameterValues("milestoneDueDate");
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
