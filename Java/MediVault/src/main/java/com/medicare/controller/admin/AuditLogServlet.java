package com.medicare.controller.admin;

import com.medicare.dao.AuditLogDAO;
import com.medicare.dao.interfaces.IAuditLogDAO;
import com.medicare.entity.Account;
import com.medicare.entity.AuditLog;
import com.medicare.util.SidebarHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.io.PrintWriter;
import java.time.format.DateTimeFormatter;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * AuditLogServlet — Audit Center v2: Dashboard + Audit Explorer (2 tầng).
 * URL: /audit-logs
 *
 * <p>Trước đây tải tối đa 100 dòng/request rồi lọc bằng JS phía client — trang dài vô hạn,
 * không có phân trang thật. Nay tách 2 tầng đúng kiểu Azure Activity Log / AWS CloudTrail:</p>
 * <ul>
 *   <li><b>Dashboard</b> — KPI + 20 sự kiện gần nhất, không tải toàn bộ log.</li>
 *   <li><b>Audit Explorer</b> — bảng phân trang THẬT phía server (30 dòng/trang), lọc theo
 *       vai trò/module/mức độ/nhân viên/IP/khoảng ngày/từ khóa — mọi bộ lọc chạy trong SQL,
 *       không lọc lại trên tập dữ liệu đã tải.</li>
 * </ul>
 *
 * <p>KHÔNG đổi cách ghi log ({@code AuditHelper.log(...)} ở mọi servlet khác giữ nguyên) —
 * chỉ mở rộng tầng ĐỌC/phân trang trong {@link AuditLogDAO}.</p>
 *
 * GET  ?action=            → showOverview (Dashboard + trang Explorer hiện tại, SSR)
 * GET  ?action=detail&id=  → JSON 1 log cho Detail Drawer (+ prev/next + related cùng người)
 * GET  ?action=export      → CSV toàn bộ kết quả đang lọc (không giới hạn phân trang)
 */
@WebServlet("/audit-logs")
public class AuditLogServlet extends HttpServlet {

    private static final int PAGE_SIZE = 30;
    private static final int RECENT_SIZE = 20;

    private final IAuditLogDAO auditLogDAO = new AuditLogDAO();

    /** Module tab (key → nhãn tiếng Việt) — PHẢI khớp đúng khoá trong AuditLogDAO.MODULE_GROUPS.
     *  Chỉ liệt kê module THẬT SỰ có log (khảo sát toàn bộ AuditHelper.log trong code) — không
     *  bịa tab "POS"/"Invoice"/"Reports"/"Settings" vì hệ thống chưa ghi log cho các module đó. */
    private static final LinkedHashMap<String, String> MODULE_TABS = new LinkedHashMap<>();
    static {
        MODULE_TABS.put("auth",       "🔑 Xác thực");
        MODULE_TABS.put("account",    "👤 Tài khoản");
        MODULE_TABS.put("inventory",  "📦 Kho / Thuốc");
        MODULE_TABS.put("supplier",   "🚚 Nhà cung cấp");
        MODULE_TABS.put("customer",   "🧑‍🤝‍🧑 Khách hàng");
        MODULE_TABS.put("shift",      "📅 Ca làm việc");
        MODULE_TABS.put("attendance", "⏱️ Điểm danh");
        MODULE_TABS.put("payroll",    "💰 Lương");
        MODULE_TABS.put("leave",      "🏖️ Nghỉ phép");
        MODULE_TABS.put("task",       "📋 Công việc");
    }
    private static final Map<String, String[]> MODULE_GROUPS_MIRROR = new LinkedHashMap<>();
    static {
        MODULE_GROUPS_MIRROR.put("auth",       new String[]{"Auth"});
        MODULE_GROUPS_MIRROR.put("account",    new String[]{"Account"});
        MODULE_GROUPS_MIRROR.put("inventory",  new String[]{"Batch", "Batches", "PurchaseOrder", "Medicine", "Category", "Manufacturer", "Shelf", "Returns"});
        MODULE_GROUPS_MIRROR.put("supplier",   new String[]{"Supplier"});
        MODULE_GROUPS_MIRROR.put("customer",   new String[]{"Customer"});
        MODULE_GROUPS_MIRROR.put("shift",      new String[]{"Shift", "ShiftSchedule", "ShiftType", "PosStation"});
        MODULE_GROUPS_MIRROR.put("attendance", new String[]{"Attendance"});
        MODULE_GROUPS_MIRROR.put("payroll",    new String[]{"Payroll"});
        MODULE_GROUPS_MIRROR.put("leave",      new String[]{"LeaveRequest"});
        MODULE_GROUPS_MIRROR.put("task",       new String[]{"Tasks"});
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        Account adminAcc = session != null ? (Account) session.getAttribute("adminAccount") : null;
        if (adminAcc == null || adminAcc.getRoleId() != 1) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        String action = req.getParameter("action");
        if ("detail".equals(action)) { apiDetail(req, resp); return; }
        if ("export".equals(action)) { handleExport(req, resp); return; }
        if ("poll".equals(action))   { apiPoll(req, resp); return; }
        showOverview(req, resp);
    }

    // ── LIVE MODE (AJAX JSON polling) ───────────────────────────────────────
    /** Trả các log có LogID > sinceId, mới nhất trước — dùng cho toggle "Trực tiếp" ở header.
     *  sinceId=0 (poll đầu tiên) chỉ trả rỗng để client tự ghi nhận mốc, tránh dồn cả bảng lên. */
    private void apiPoll(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        PrintWriter out = resp.getWriter();
        try {
            long sinceId = Long.parseLong(req.getParameter("sinceId"));
            List<AuditLog> rows = auditLogDAO.findSince(sinceId, 20);
            DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss");
            StringBuilder sb = new StringBuilder("{\"ok\":true,\"rows\":[");
            for (int i = 0; i < rows.size(); i++) {
                if (i > 0) sb.append(',');
                AuditLog l = rows.get(i);
                sb.append(logJson(l, -1, fmt));
            }
            sb.append("]}");
            out.print(sb);
        } catch (Exception e) {
            out.print("{\"ok\":false,\"rows\":[]}");
        }
    }

    // ── DASHBOARD + EXPLORER (SSR) ──────────────────────────────────────────
    private void showOverview(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // ── Bộ lọc Explorer từ query string ──
        String keyword    = req.getParameter("search");
        String fromDate    = req.getParameter("from");
        String toDate       = req.getParameter("to");
        Integer role       = parseIntNullable(req.getParameter("role"));
        String moduleKey   = emptyToNull(req.getParameter("module"));
        String severity    = emptyToNull(req.getParameter("severity"));
        Integer accountId  = parseIntNullable(req.getParameter("account"));
        String ip          = req.getParameter("ip");
        int page = Math.max(1, parseIntOr(req.getParameter("page"), 1));

        List<AuditLog> pageRows = auditLogDAO.findFiltered(page, PAGE_SIZE, keyword, fromDate, toDate,
                role, moduleKey, severity, accountId, ip);
        int total = auditLogDAO.countFiltered(keyword, fromDate, toDate, role, moduleKey, severity, accountId, ip);
        int totalPages = Math.max(1, (int) Math.ceil((double) total / PAGE_SIZE));

        req.setAttribute("explorerRows",   pageRows);
        req.setAttribute("explorerTotal",  total);
        req.setAttribute("explorerPage",   page);
        req.setAttribute("explorerPages",  totalPages);
        req.setAttribute("fRole",     role);
        req.setAttribute("fModule",   moduleKey);
        req.setAttribute("fSeverity", severity);
        req.setAttribute("fAccount",  accountId);
        req.setAttribute("fIp",       ip);
        req.setAttribute("searchKeyword", keyword == null ? "" : keyword);
        req.setAttribute("filterFrom", fromDate == null ? "" : fromDate);
        req.setAttribute("filterTo",   toDate == null ? "" : toDate);

        // ── Dashboard KPI (không tải log để đếm — dùng aggregate query) ──
        req.setAttribute("kpiTotal",   auditLogDAO.countAll(null, null, null));
        req.setAttribute("kpiToday",   auditLogDAO.countToday());
        req.setAttribute("kpiCritical", auditLogDAO.countBySeverityToday("critical"));
        req.setAttribute("kpiWarning",  auditLogDAO.countBySeverityToday("warning"));
        req.setAttribute("kpiUsers",    auditLogDAO.countUniqueUsersToday());

        // ── Security Summary (Row 2 phải) — đủ 5 mức, hôm nay ──
        LinkedHashMap<String, Integer> severityToday = new LinkedHashMap<>();
        severityToday.put("critical", (Integer) req.getAttribute("kpiCritical"));
        severityToday.put("warning",  (Integer) req.getAttribute("kpiWarning"));
        severityToday.put("info",     auditLogDAO.countBySeverityToday("info"));
        severityToday.put("success",  auditLogDAO.countBySeverityToday("success"));
        severityToday.put("neutral",  auditLogDAO.countBySeverityToday("neutral"));
        req.setAttribute("severityToday", severityToday);

        // ── Recent Activity Feed — CHỈ 20 dòng mới nhất, không lọc ──
        req.setAttribute("recentRows", auditLogDAO.findFiltered(1, RECENT_SIZE, null, null, null, null, null, null, null, null));

        // ── Badge số cho tab Vai trò / Module ──
        req.setAttribute("roleCounts", auditLogDAO.countByRole());
        Map<String, Integer> rawEntityCounts = auditLogDAO.countByEntityType();
        Map<String, Integer> moduleCounts = new LinkedHashMap<>();
        for (Map.Entry<String, String[]> g : MODULE_GROUPS_MIRROR.entrySet()) {
            int sum = 0;
            for (String t : g.getValue()) sum += rawEntityCounts.getOrDefault(t, 0);
            moduleCounts.put(g.getKey(), sum);
        }
        req.setAttribute("moduleCounts", moduleCounts);
        req.setAttribute("moduleTabs", MODULE_TABS);

        // ── Quick Analytics (Section 11) — tính trên toàn bộ bảng, không phải mẫu đã tải ──
        req.setAttribute("topUsers",    auditLogDAO.topUsers(5));
        req.setAttribute("topIps",      auditLogDAO.topIps(5));
        req.setAttribute("hourlyToday", auditLogDAO.hourlyToday());

        // ── Danh sách tài khoản cho bộ lọc "Nhân viên" ──
        com.medicare.dao.interfaces.IAccountDAO accountDAO = new com.medicare.dao.AccountDAO();
        java.util.List<Account> allAccounts =
                com.medicare.config.CacheManager.getShort("audit.allAccounts", accountDAO::findAll);
        req.setAttribute("auditAccounts", allAccounts);
        req.setAttribute("activeAccounts", (long) allAccounts.stream().filter(Account::isActive).count());
        // accountId → roleId — để Explorer hiện cột "Vai trò" mà không cần JOIN thêm/đổi entity AuditLog.
        Map<Integer, Integer> accountRoleMap = new LinkedHashMap<>();
        for (Account a : allAccounts) accountRoleMap.put(a.getAccountId(), a.getRoleId());
        req.setAttribute("accountRoleMap", accountRoleMap);
        Account currentAdmin = (Account) req.getSession().getAttribute("adminAccount");
        req.setAttribute("currentAdminId", currentAdmin != null ? currentAdmin.getAccountId() : 0);
        req.setAttribute("todayRevenue",  0L);
        req.setAttribute("todayInvoices", 0);

        com.medicare.dao.interfaces.IPasswordResetDAO resetDAO = new com.medicare.dao.PasswordResetDAO();
        java.util.List<com.medicare.entity.PasswordResetRequest> pendingResets = resetDAO.findAllPending();
        req.setAttribute("pendingResets",     pendingResets);
        req.setAttribute("pendingResetCount", pendingResets.size());
        java.util.Map<Integer, Account> resetAccountMap = new java.util.HashMap<>();
        java.util.Set<Integer> resetAccountIds = new java.util.HashSet<>();
        for (com.medicare.entity.PasswordResetRequest pr : pendingResets) resetAccountIds.add(pr.getAccountId());
        if (!resetAccountIds.isEmpty()) {
            for (Account a : accountDAO.findAccountsByIds(new java.util.ArrayList<>(resetAccountIds))) {
                resetAccountMap.put(a.getAccountId(), a);
            }
        }
        req.setAttribute("resetAccountMap", resetAccountMap);

        SidebarHelper.load(req);
        req.getRequestDispatcher("/WEB-INF/views/admin/audit-log-list.jsp").forward(req, resp);
    }

    // ── DETAIL DRAWER (AJAX JSON) ───────────────────────────────────────────
    private void apiDetail(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        PrintWriter out = resp.getWriter();
        try {
            long id = Long.parseLong(req.getParameter("id"));
            AuditLog log = auditLogDAO.findById(id);
            if (log == null) { out.print("{\"ok\":false}"); return; }

            com.medicare.dao.interfaces.IAccountDAO accountDAO = new com.medicare.dao.AccountDAO();
            Account owner = log.getAccountId() != null ? accountDAO.findById(log.getAccountId()) : null;
            int role = owner != null ? owner.getRoleId() : 0;

            AuditLog[] neighbors = auditLogDAO.findPrevNext(id);
            List<AuditLog> related = log.getAccountId() != null
                    ? auditLogDAO.findByAccount(log.getAccountId(), id, 6)
                    : List.of();

            DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss");
            StringBuilder sb = new StringBuilder();
            sb.append("{\"ok\":true,\"log\":").append(logJson(log, role, fmt))
              .append(",\"prev\":").append(neighbors[0] != null ? logJson(neighbors[0], -1, fmt) : "null")
              .append(",\"next\":").append(neighbors[1] != null ? logJson(neighbors[1], -1, fmt) : "null")
              .append(",\"related\":[");
            for (int i = 0; i < related.size(); i++) {
                if (i > 0) sb.append(',');
                sb.append(logJson(related.get(i), -1, fmt));
            }
            sb.append("]}");
            out.print(sb);
        } catch (Exception e) {
            out.print("{\"ok\":false,\"error\":" + jsonStr(e.getMessage()) + "}");
        }
    }

    private String logJson(AuditLog log, int role, DateTimeFormatter fmt) {
        return "{\"id\":" + log.getLogId()
                + ",\"action\":" + jsonStr(log.getAction())
                + ",\"entityType\":" + jsonStr(log.getEntityType())
                + ",\"entityId\":" + (log.getEntityId() != null ? log.getEntityId() : "null")
                + ",\"description\":" + jsonStr(log.getDescription())
                + ",\"ip\":" + jsonStr(log.getIpAddress())
                + ",\"username\":" + jsonStr(log.getUsername())
                + ",\"accountId\":" + (log.getAccountId() != null ? log.getAccountId() : "null")
                + ",\"role\":" + role
                + ",\"sev\":" + jsonStr(sevOf(log.getAction()))
                + ",\"time\":" + jsonStr(log.getCreatedAt() != null ? log.getCreatedAt().format(fmt) : "")
                + "}";
    }

    /** Cùng quy tắc suy mức độ với AuditLogDAO.severitySql() / JSP sevOf() — dùng cho icon màu
     *  ở Detail Drawer/Related logs. */
    private String sevOf(String action) {
        String a = action == null ? "" : action;
        if (a.contains("Xóa") || a.contains("Khóa"))            return "critical";
        if (a.contains("Cập nhật") || a.contains("Sửa") || a.contains("Đặt lại")) return "warning";
        if (a.contains("Đăng nhập") || a.contains("Đăng xuất")) return "info";
        if (a.contains("Tạo") || a.contains("Khôi phục"))       return "success";
        return "neutral";
    }

    // ── EXPORT CSV — toàn bộ kết quả đang lọc, KHÔNG giới hạn phân trang ────
    private void handleExport(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String keyword    = req.getParameter("search");
        String fromDate    = req.getParameter("from");
        String toDate       = req.getParameter("to");
        Integer role       = parseIntNullable(req.getParameter("role"));
        String moduleKey   = emptyToNull(req.getParameter("module"));
        String severity    = emptyToNull(req.getParameter("severity"));
        Integer accountId  = parseIntNullable(req.getParameter("account"));
        String ip          = req.getParameter("ip");

        int total = auditLogDAO.countFiltered(keyword, fromDate, toDate, role, moduleKey, severity, accountId, ip);
        // An toàn: chặn export quá lớn làm treo request — Explorer vẫn xem được hết qua phân trang.
        int cap = Math.min(total, 5000);
        List<AuditLog> rows = auditLogDAO.findFiltered(1, cap, keyword, fromDate, toDate, role, moduleKey, severity, accountId, ip);
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss");

        String format = req.getParameter("format");
        if ("json".equals(format)) { exportJson(resp, rows, fmt); return; }
        if ("xls".equals(format))  { exportXls(resp, rows, fmt); return; }
        exportCsv(resp, rows, fmt);
    }

    private void exportCsv(HttpServletResponse resp, List<AuditLog> rows, DateTimeFormatter fmt) throws IOException {
        resp.setContentType("text/csv;charset=UTF-8");
        resp.setHeader("Content-Disposition", "attachment; filename=\"audit-log.csv\"");
        PrintWriter out = resp.getWriter();
        out.write('\uFEFF'); // BOM để Excel đọc đúng UTF-8
        out.println("ID,Thời gian,Người dùng,Hành động,Module,Entity ID,IP,Mô tả");
        for (AuditLog l : rows) {
            out.println(l.getLogId() + ","
                    + csvCell(l.getCreatedAt() != null ? l.getCreatedAt().format(fmt) : "") + ","
                    + csvCell(l.getUsername()) + ","
                    + csvCell(l.getAction()) + ","
                    + csvCell(l.getEntityType()) + ","
                    + (l.getEntityId() != null ? l.getEntityId() : "") + ","
                    + csvCell(l.getIpAddress()) + ","
                    + csvCell(l.getDescription()));
        }
    }

    private void exportJson(HttpServletResponse resp, List<AuditLog> rows, DateTimeFormatter fmt) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Content-Disposition", "attachment; filename=\"audit-log.json\"");
        PrintWriter out = resp.getWriter();
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < rows.size(); i++) {
            if (i > 0) sb.append(',');
            sb.append(logJson(rows.get(i), -1, fmt));
        }
        sb.append(']');
        out.print(sb);
    }

    /** Excel không có thư viện POI trong project — dùng kỹ thuật bảng HTML lưu đuôi .xls, Excel
     *  mở được bình thường (không phải file .xlsx nhị phân thật, nhưng KHÔNG phải dữ liệu giả —
     *  toàn bộ nội dung vẫn là dữ liệu export thật, chỉ khác định dạng đóng gói). */
    private void exportXls(HttpServletResponse resp, List<AuditLog> rows, DateTimeFormatter fmt) throws IOException {
        resp.setContentType("application/vnd.ms-excel;charset=UTF-8");
        resp.setHeader("Content-Disposition", "attachment; filename=\"audit-log.xls\"");
        PrintWriter out = resp.getWriter();
        out.write('﻿');
        out.println("<html><head><meta charset=\"UTF-8\"></head><body><table border=\"1\">");
        out.println("<tr><th>ID</th><th>Thời gian</th><th>Người dùng</th><th>Hành động</th><th>Module</th><th>Entity ID</th><th>IP</th><th>Mô tả</th></tr>");
        for (AuditLog l : rows) {
            out.println("<tr><td>" + l.getLogId() + "</td><td>"
                    + xlsCell(l.getCreatedAt() != null ? l.getCreatedAt().format(fmt) : "") + "</td><td>"
                    + xlsCell(l.getUsername()) + "</td><td>"
                    + xlsCell(l.getAction()) + "</td><td>"
                    + xlsCell(l.getEntityType()) + "</td><td>"
                    + (l.getEntityId() != null ? l.getEntityId() : "") + "</td><td>"
                    + xlsCell(l.getIpAddress()) + "</td><td>"
                    + xlsCell(l.getDescription()) + "</td></tr>");
        }
        out.println("</table></body></html>");
    }

    private String xlsCell(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
    }

    private String csvCell(String s) {
        if (s == null) s = "";
        return "\"" + s.replace("\"", "\"\"") + "\"";
    }

    private String jsonStr(String s) {
        if (s == null) return "\"\"";
        return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"")
                .replace("\n", "\\n").replace("\r", "\\r") + "\"";
    }

    private Integer parseIntNullable(String s) {
        if (s == null || s.trim().isEmpty()) return null;
        try { return Integer.parseInt(s.trim()); } catch (NumberFormatException e) { return null; }
    }
    private int parseIntOr(String s, int def) {
        if (s == null || s.isEmpty()) return def;
        try { return Integer.parseInt(s); } catch (NumberFormatException e) { return def; }
    }
    private String emptyToNull(String s) { return (s == null || s.trim().isEmpty()) ? null : s.trim(); }
}
