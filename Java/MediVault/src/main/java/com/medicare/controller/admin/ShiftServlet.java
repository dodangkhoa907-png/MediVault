package com.medicare.controller.admin;

import com.medicare.dao.AccountDAO;
import com.medicare.dao.InvoiceDAO;
import com.medicare.dao.LeaveRequestDAO;
import com.medicare.dao.ShiftDAO;
import com.medicare.dao.ShiftScheduleDAO;
import com.medicare.dao.ShiftTypeDAO;
import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.dao.interfaces.IInvoiceDAO;
import com.medicare.dao.interfaces.ILeaveRequestDAO;
import com.medicare.dao.interfaces.IShiftDAO;
import com.medicare.dao.interfaces.IShiftScheduleDAO;
import com.medicare.dao.interfaces.IShiftTypeDAO;
import com.medicare.entity.Account;
import com.medicare.entity.Shift;
import com.medicare.entity.ShiftSchedule;
import com.medicare.util.AuditHelper;
import com.medicare.util.SidebarHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.*;

@WebServlet("/shifts")
public class ShiftServlet extends HttpServlet {

    private final IShiftDAO         shiftDAO    = new ShiftDAO();
    private final IAccountDAO       accountDAO  = new AccountDAO();
    private final IInvoiceDAO       invoiceDAO  = new InvoiceDAO();
    private final IShiftScheduleDAO scheduleDAO = new ShiftScheduleDAO();
    private final IShiftTypeDAO     shiftTypeDAO = new ShiftTypeDAO();
    private final ILeaveRequestDAO  leaveDAO    = new LeaveRequestDAO();

    // ── GET ───────────────────────────────────────────────────────────────────
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
        if (action == null) action = "list";

        switch (action) {
            case "list"        -> showList(req, resp);
            case "chart-data"  -> handleChartData(req, resp);
            case "detail"      -> showDetail(req, resp);
            case "force-close" -> handleForceClose(req, resp);
            case "delete"      -> handleDelete(req, resp);
            default            -> showList(req, resp);
        }
    }

    // ── POST ──────────────────────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");

        HttpSession session = req.getSession(false);
        Account adminAcc = session != null ? (Account) session.getAttribute("adminAccount") : null;
        if (adminAcc == null || adminAcc.getRoleId() != 1) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        String action = req.getParameter("action");
        if (action == null) action = "";

        switch (action) {
            case "open"                  -> handleOpenShift(req, resp);
            case "close"                 -> handleCloseShift(req, resp);
            case "force-close"           -> handleForceClosePost(req, resp);
            // ── Schedule actions (từ shift-list.jsp) ──
            case "schedule-bulk"         -> handleScheduleBulk(req, resp);
            case "schedule-bulk-update"  -> handleScheduleBulkUpdate(req, resp);
            case "schedule-bulk-delete"  -> handleScheduleBulkDelete(req, resp);
            case "schedule-update"       -> handleScheduleUpdate(req, resp);
            case "schedule-delete-staff" -> handleScheduleDeleteStaff(req, resp);
            case "cancel-schedule"       -> handleCancelSchedule(req, resp);
            default            -> resp.sendRedirect(req.getContextPath() + "/shifts");
        }
    }

    // ── LIST ──────────────────────────────────────────────────────────────────
    private void showList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Filter params
        String fromStr    = req.getParameter("from");
        String toStr      = req.getParameter("to");
        String accountStr = req.getParameter("accountId");
        String statusStr  = req.getParameter("status"); // "open" | "closed" | ""

        List<Shift> allShifts;

        // Lọc theo khoảng ngày
        if (fromStr != null && !fromStr.isEmpty() && toStr != null && !toStr.isEmpty()) {
            try {
                LocalDate from = LocalDate.parse(fromStr);
                LocalDate to   = LocalDate.parse(toStr);
                allShifts = shiftDAO.findByDateRange(from, to);
            } catch (DateTimeParseException e) {
                allShifts = shiftDAO.findAll();
            }
        } else if (accountStr != null && !accountStr.isEmpty()) {
            try {
                allShifts = shiftDAO.findByAccount(Integer.parseInt(accountStr));
            } catch (NumberFormatException e) {
                allShifts = shiftDAO.findAll();
            }
        } else {
            allShifts = shiftDAO.findAll();
        }

        // Lọc theo status — dùng Status field (OPEN/CLOSED/FORCE_CLOSED)
        if (statusStr != null && !statusStr.isEmpty()) {
            if ("open".equals(statusStr)) {
                allShifts = allShifts.stream()
                        .filter(s -> s.isOpen())
                        .collect(java.util.stream.Collectors.toList());
            } else if ("closed".equals(statusStr)) {
                allShifts = allShifts.stream()
                        .filter(s -> s.isClosed() || s.isForceClose())
                        .collect(java.util.stream.Collectors.toList());
            } else if ("force-closed".equals(statusStr)) {
                allShifts = allShifts.stream()
                        .filter(s -> s.isForceClose())
                        .collect(java.util.stream.Collectors.toList());
            }
        }

        // Map accountId → Account để hiển thị tên nhân viên
        Map<Integer, Account> accountMap = new HashMap<>();
        for (Shift s : allShifts) {
            if (!accountMap.containsKey(s.getAccountId())) {
                Account a = accountDAO.findById(s.getAccountId());
                if (a != null) accountMap.put(s.getAccountId(), a);
            }
        }

        // Thống kê tổng quan — dùng Status field
        List<Shift> openShifts = allShifts.stream()
                .filter(s -> s.isOpen())
                .collect(java.util.stream.Collectors.toList());
        long forceClosedCount = allShifts.stream().filter(s -> s.isForceClose()).count();
        req.setAttribute("forceClosedCount", forceClosedCount);

        req.setAttribute("shifts",       allShifts);
        req.setAttribute("accountMap",   accountMap);
        req.setAttribute("openShifts",   openShifts);
        req.setAttribute("openCount",    openShifts.size());
        req.setAttribute("totalCount",   allShifts.size());
        req.setAttribute("allStaff",     accountDAO.findAllStaff());
        req.setAttribute("filterFrom",   fromStr);
        req.setAttribute("filterTo",     toStr);
        req.setAttribute("filterAcc",    accountStr);
        req.setAttribute("filterStatus", statusStr);
        // Status summary cho filter dropdown
        req.setAttribute("openCount",        openShifts.size());
        req.setAttribute("forceClosedShifts", allShifts.stream()
                .filter(s -> s.isForceClose()).count());

        // ── Dữ liệu cho Tab Lịch ca (tuần) ──────────────────────────────────
        java.time.LocalDate today2 = java.time.LocalDate.now();
        java.time.LocalDate monday = today2.minusDays(today2.getDayOfWeek().getValue() - 1);
        // Navigate tuần
        String wStr = req.getParameter("w");
        if (wStr != null) {
            try { monday = monday.plusWeeks(Integer.parseInt(wStr)); } catch (Exception ignored) {}
        }
        java.time.LocalDate sunday = monday.plusDays(6);
        // 7 ngày trong tuần
        java.util.List<java.time.LocalDate> weekDays = new java.util.ArrayList<>();
        java.util.List<String> weekDayNames = java.util.Arrays.asList("T2","T3","T4","T5","T6","T7","CN");
        for (int i = 0; i < 7; i++) weekDays.add(monday.plusDays(i));
        // Lịch ca tuần này
        java.util.List<com.medicare.entity.ShiftSchedule> weekSchedules =
                scheduleDAO.findByDateRange(monday, sunday);
        req.setAttribute("weekDays",     weekDays);
        req.setAttribute("weekDayNames", weekDayNames);
        req.setAttribute("weekStart",    monday.toString());
        req.setAttribute("weekEnd",      sunday.toString());
        req.setAttribute("today",        today2);
        req.setAttribute("schedules",    weekSchedules);
        // ── Dữ liệu cho Tab Loại ca ──────────────────────────────────────────
        req.setAttribute("shiftTypes",   shiftTypeDAO.findAll());

        // ── Dữ liệu cho Tab Nghỉ phép ────────────────────────────────────────
        java.util.List<com.medicare.entity.LeaveRequest> pendingLeaves = leaveDAO.findPending();
        req.setAttribute("pendingLeaves",     pendingLeaves);
        req.setAttribute("pendingLeaveCount", pendingLeaves.size());

        // ── Dữ liệu biểu đồ: tổng tiền đầu/cuối ca theo tháng hiện tại ──
        int chartMonth = java.time.LocalDate.now().getMonthValue();
        int chartYear  = java.time.LocalDate.now().getYear();
        try {
            String cm = req.getParameter("chartMonth");
            String cy = req.getParameter("chartYear");
            if (cm != null && !cm.isEmpty()) chartMonth = Integer.parseInt(cm);
            if (cy != null && !cy.isEmpty()) chartYear  = Integer.parseInt(cy);
        } catch (Exception ignored) {}
        java.time.LocalDate chartFrom = java.time.LocalDate.of(chartYear, chartMonth, 1);
        java.time.LocalDate chartTo   = chartFrom.withDayOfMonth(chartFrom.lengthOfMonth());
        java.util.List<Shift> monthShifts = shiftDAO.findByDateRange(chartFrom, chartTo);
        req.setAttribute("monthShifts",  monthShifts);
        req.setAttribute("chartMonth",   chartMonth);
        req.setAttribute("chartYear",    chartYear);

        SidebarHelper.load(req);


        req.getRequestDispatcher("/WEB-INF/views/admin/shift-list.jsp").forward(req, resp);
    }

    // ── DETAIL ────────────────────────────────────────────────────────────────
    private void showDetail(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        int id = parseIntOr(req.getParameter("id"), 0);
        Shift shift = shiftDAO.findById(id);
        if (shift == null) {
            resp.sendRedirect(req.getContextPath() + "/shifts?msg=not-found");
            return;
        }
        Account staff = accountDAO.findById(shift.getAccountId());
        req.setAttribute("shift", shift);
        req.setAttribute("staff", staff);
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/admin/shift-detail.jsp").forward(req, resp);
    }

    // ── FORCE CLOSE (GET confirm page) ───────────────────────────────────────
    private void handleForceClose(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        int id = parseIntOr(req.getParameter("id"), 0);
        Shift shift = shiftDAO.findById(id);
        if (shift == null || !shift.isOpen()) {
            resp.sendRedirect(req.getContextPath() + "/shifts?msg=already-closed");
            return;
        }
        Account staff = accountDAO.findById(shift.getAccountId());
        req.setAttribute("shift", shift);
        req.setAttribute("staff", staff);
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/admin/shift-force-close.jsp").forward(req, resp);
    }

    // ── FORCE CLOSE (POST) ────────────────────────────────────────────────────
    private void handleForceClosePost(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int shiftId = parseIntOr(req.getParameter("shiftId"), 0);
        String notes = req.getParameter("notes");
        Shift shift = shiftDAO.findById(shiftId);
        if (shift == null) { resp.sendRedirect(req.getContextPath() + "/shifts"); return; }

        // ── Tự tính ClosingCash = OpeningCash + Doanh thu tiền mặt trong ca ──
        try {
            java.math.BigDecimal cashRevenue =
                    invoiceDAO.sumCashRevenueByShift(shiftId);
            java.math.BigDecimal opening =
                    shift.getOpeningCash() != null ? shift.getOpeningCash() : java.math.BigDecimal.ZERO;
            java.math.BigDecimal closing = opening.add(
                    cashRevenue != null ? cashRevenue : java.math.BigDecimal.ZERO);
            shiftDAO.setClosingCash(shiftId, closing);
        } catch (Exception ignored) {}

        boolean ok = shiftDAO.forceClose(shiftId, notes);
        if (ok) {
            Account staff = accountDAO.findById(shift.getAccountId());
            String staffName = staff != null ? staff.getFullName() : "ID " + shift.getAccountId();
            AuditHelper.log(req, "Force đóng ca", "Shift",
                    "Admin đóng ca ID " + shiftId + " của " + staffName);
        }
        resp.sendRedirect(req.getContextPath() + "/shifts?msg=" + (ok ? "force-closed" : "error"));
    }

    // ── DELETE ────────────────────────────────────────────────────────────────
    private void handleDelete(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int id = parseIntOr(req.getParameter("id"), 0);
        Shift shift = shiftDAO.findById(id);
        boolean ok = shiftDAO.delete(id);
        if (ok && shift != null) {
            Account staff = accountDAO.findById(shift.getAccountId());
            String staffName = staff != null ? staff.getFullName() : "ID " + shift.getAccountId();
            AuditHelper.log(req, "Xóa ca làm việc", "Shift",
                    "Xóa ca ID " + id + " của " + staffName);
        }
        String msg = ok ? "deleted" : "delete-failed"; // delete-failed = có hóa đơn liên kết
        resp.sendRedirect(req.getContextPath() + "/shifts?msg=" + msg);
    }

    // ── OPEN SHIFT (Admin mở ca hộ nhân viên) ────────────────────────────────
    private void handleOpenShift(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int accountId = parseIntOr(req.getParameter("accountId"), 0);
        // Tiền đầu ca = 0 (không nhập thủ công nữa — lấy từ ShiftSchedule nếu có)
        BigDecimal cash = BigDecimal.ZERO;

        boolean ok = shiftDAO.openShift(accountId, cash);
        if (ok) {
            Account staff = accountDAO.findById(accountId);
            String staffName = staff != null ? staff.getFullName() : "ID " + accountId;
            AuditHelper.log(req, "Mở ca làm việc", "Shift",
                    "Mở ca cho " + staffName);
        }
        resp.sendRedirect(req.getContextPath() + "/shifts?msg=" + (ok ? "opened" : "already-open"));
    }

    // ── CLOSE SHIFT (Admin đóng ca hộ) ───────────────────────────────────────
    private void handleCloseShift(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int shiftId = parseIntOr(req.getParameter("shiftId"), 0);
        String cashStr = req.getParameter("closingCash");
        String notes   = req.getParameter("notes");
        BigDecimal cash = BigDecimal.ZERO;
        try { if (cashStr != null && !cashStr.isEmpty()) cash = new BigDecimal(cashStr); }
        catch (NumberFormatException ignored) {}

        boolean ok = shiftDAO.closeShift(shiftId, cash, notes);
        if (ok) {
            Shift shift = shiftDAO.findById(shiftId);
            if (shift != null) {
                Account staff = accountDAO.findById(shift.getAccountId());
                AuditHelper.log(req, "Đóng ca làm việc", "Shift",
                        "Đóng ca ID " + shiftId + " của "
                                + (staff != null ? staff.getFullName() : "") + " — tiền cuối ca: " + cash);
            }
        }
        resp.sendRedirect(req.getContextPath() + "/shifts?msg=" + (ok ? "closed" : "error"));
    }

    // ── Chart Data API: trả JSON tiền đầu/cuối ca theo ngày trong tháng ──────
    private void handleChartData(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int month = parseIntOr(req.getParameter("month"), java.time.LocalDate.now().getMonthValue());
        int year  = parseIntOr(req.getParameter("year"),  java.time.LocalDate.now().getYear());
        java.time.LocalDate from = java.time.LocalDate.of(year, month, 1);
        java.time.LocalDate to   = from.withDayOfMonth(from.lengthOfMonth());

        java.util.List<Shift> shifts = shiftDAO.findByDateRange(from, to);

        // Group theo ngày: tổng openingCash và closingCash
        java.util.TreeMap<String, long[]> daily = new java.util.TreeMap<>();
        for (Shift s : shifts) {
            if (s.getStartTime() == null) continue;
            String dayKey = s.getStartTime().toLocalDate().toString();
            daily.putIfAbsent(dayKey, new long[]{0, 0});
            if (s.getOpeningCash() != null)
                daily.get(dayKey)[0] += s.getOpeningCash().longValue();
            if (s.getClosingCash() != null)
                daily.get(dayKey)[1] += s.getClosingCash().longValue();
        }

        // Build JSON thủ công — tránh dependency ngoài
        StringBuilder labels  = new StringBuilder();
        StringBuilder opening = new StringBuilder();
        StringBuilder closing = new StringBuilder();
        boolean first = true;
        for (java.util.Map.Entry<String, long[]> e : daily.entrySet()) {
            if (!first) { labels.append(","); opening.append(","); closing.append(","); }
            String dd = e.getKey().substring(8); // lấy ngày dd từ yyyy-MM-dd
            labels.append("\"").append(dd).append("/").append(month).append("\"");
            opening.append(e.getValue()[0]);
            closing.append(e.getValue()[1]);
            first = false;
        }

        String json = "{" +
                "\"labels\":[" + labels + "]," +
                "\"opening\":[" + opening + "]," +
                "\"closing\":[" + closing + "]}";

        resp.setContentType("application/json;charset=UTF-8");
        resp.getWriter().print(json);
    }

    // ── Helper ────────────────────────────────────────────────────────────────
    private int parseIntOr(String s, int def) {
        if (s == null || s.isEmpty()) return def;
        try { return Integer.parseInt(s); } catch (NumberFormatException e) { return def; }
    }

    // ════════════════════════════════════════════════════════
    //  SCHEDULE HANDLERS — gọi từ shift-list.jsp modals
    // ════════════════════════════════════════════════════════

    /** Xếp ca mới (bulk: nhiều NV × nhiều ca × khoảng ngày) */
    private void handleScheduleBulk(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        Account admin = (Account) req.getSession(false).getAttribute("adminAccount");
        String[] accIds    = req.getParameterValues("accountId");
        String[] typeIds   = req.getParameterValues("shiftTypeId");
        String   dateFrom  = req.getParameter("dateFrom");
        String   dateTo    = req.getParameter("dateTo");

        if (accIds == null || typeIds == null || dateFrom == null || dateFrom.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/shifts?msg=invalid"); return;
        }

        int created = 0, skipped = 0;
        try {
            java.time.LocalDate from = java.time.LocalDate.parse(dateFrom);
            java.time.LocalDate to   = (dateTo != null && !dateTo.isEmpty())
                    ? java.time.LocalDate.parse(dateTo) : from;
            for (String aId : accIds)
                for (String tId : typeIds)
                    for (java.time.LocalDate d = from; !d.isAfter(to); d = d.plusDays(1)) {
                        int r = scheduleDAO.schedule(
                                Integer.parseInt(aId), Integer.parseInt(tId),
                                d, admin.getAccountId());
                        if (r > 0) created++; else skipped++;
                    }
            AuditHelper.log(req, "Xếp lịch ca", "ShiftSchedule",
                    "Tạo " + created + " ca, bỏ qua " + skipped + " đã tồn tại");
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/shifts?msg=error"); return;
        }
        resp.sendRedirect(req.getContextPath()
                + "/shifts?msg=created&count=" + created + "&skip=" + skipped);
    }

    /** Sửa 1 ca (từ modal chip click) */
    private void handleScheduleUpdate(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        Account admin   = (Account) req.getSession(false).getAttribute("adminAccount");
        int scheduleId  = parseIntOr(req.getParameter("scheduleId"), 0);
        int shiftTypeId = parseIntOr(req.getParameter("shiftTypeId"), 0);
        int lateTol     = parseIntOr(req.getParameter("lateToleranceMinutes"), 10);
        String notes    = req.getParameter("notes");

        if (scheduleId == 0) {
            resp.sendRedirect(req.getContextPath() + "/shifts?msg=invalid"); return;
        }
        boolean ok = scheduleDAO.update(scheduleId, shiftTypeId, lateTol, notes,
                admin.getAccountId());
        if (ok) AuditHelper.log(req, "Sửa lịch ca", "ShiftSchedule",
                "Sửa ca ID " + scheduleId);
        resp.sendRedirect(req.getContextPath() + "/shifts?msg=" + (ok ? "updated" : "error"));
    }

    /** Sửa nhiều ca đã chọn (bulk update) */
    private void handleScheduleBulkUpdate(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        Account admin    = (Account) req.getSession(false).getAttribute("adminAccount");
        String[] ids     = req.getParameterValues("scheduleIds");
        int shiftTypeId  = parseIntOr(req.getParameter("shiftTypeId"), 0);
        int lateTol      = parseIntOr(req.getParameter("lateToleranceMinutes"), -1); // -1 = giữ nguyên
        String notes     = req.getParameter("notes");

        if (ids == null || ids.length == 0) {
            resp.sendRedirect(req.getContextPath() + "/shifts?msg=invalid"); return;
        }
        int updated = 0;
        for (String id : ids) {
            int sid = parseIntOr(id, 0);
            if (sid == 0) continue;
            // Nếu không chọn loại ca mới → chỉ update lateTol và notes
            // scheduleDAO.update() với shiftTypeId=0 → giữ nguyên shiftType hiện tại
            int effectiveLateTol = lateTol >= 0 ? lateTol : 10; // fallback 10 phút
            boolean ok = scheduleDAO.update(
                    sid,
                    shiftTypeId > 0 ? shiftTypeId : getExistingShiftTypeId(sid),
                    effectiveLateTol,
                    (notes != null && !notes.trim().isEmpty()) ? notes.trim() : null,
                    admin.getAccountId());
            if (ok) updated++;
        }
        AuditHelper.log(req, "Sửa hàng loạt lịch ca", "ShiftSchedule",
                "Đã sửa " + updated + " ca");
        resp.sendRedirect(req.getContextPath() + "/shifts?msg=updated&count=" + updated);
    }

    /** Lấy shiftTypeId hiện tại của 1 schedule — dùng khi bulk update không đổi loại ca */
    private int getExistingShiftTypeId(int scheduleId) {
        try {
            ShiftSchedule sc = scheduleDAO.findById(scheduleId);
            return sc != null ? sc.getShiftTypeId() : 0;
        } catch (Exception e) { return 0; }
    }

    /** Xóa 1 nhân viên khỏi ca trong ngày */
    private void handleScheduleDeleteStaff(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int scheduleId = parseIntOr(req.getParameter("scheduleId"), 0);
        ShiftSchedule sc = scheduleDAO.findById(scheduleId);
        boolean ok = scheduleDAO.cancel(scheduleId);
        if (ok && sc != null)
            AuditHelper.log(req, "Hủy ca nhân viên", "ShiftSchedule",
                    "Hủy ca " + sc.getShiftTypeName() + " ngày " + sc.getWorkDate()
                            + " của " + sc.getStaffName());
        resp.sendRedirect(req.getContextPath() + "/shifts?msg=" + (ok ? "cancelled" : "error"));
    }

    /** Xóa nhiều ca đã chọn (bulk delete — hard delete, không chỉ set CANCELLED) */
    private void handleScheduleBulkDelete(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String[] ids = req.getParameterValues("scheduleIds");
        if (ids == null || ids.length == 0) {
            resp.sendRedirect(req.getContextPath() + "/shifts?msg=invalid"); return;
        }
        int deleted = 0;
        int failed  = 0;
        for (String id : ids) {
            int sid = parseIntOr(id, 0);
            if (sid == 0) continue;
            // Dùng delete() — hard delete, chỉ xóa ca chưa check-in
            boolean ok = scheduleDAO.delete(sid);
            if (ok) deleted++; else failed++;
        }
        AuditHelper.log(req, "Xóa hàng loạt lịch ca", "ShiftSchedule",
                "Đã xóa " + deleted + " ca" + (failed > 0 ? ", " + failed + " không thể xóa" : ""));
        String msg = deleted > 0 ? "deleted&count=" + deleted : "error";
        resp.sendRedirect(req.getContextPath() + "/shifts?msg=" + msg);
    }

    /** Cancel 1 ca (từ chip × button) */
    private void handleCancelSchedule(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        int scheduleId = parseIntOr(req.getParameter("scheduleId"), 0);
        ShiftSchedule sc = scheduleDAO.findById(scheduleId);
        boolean ok = scheduleDAO.cancel(scheduleId);
        if (ok && sc != null)
            AuditHelper.log(req, "Hủy lịch ca", "ShiftSchedule",
                    "Hủy ca " + sc.getShiftTypeName() + " ngày " + sc.getWorkDate());
        resp.sendRedirect(req.getContextPath() + "/shifts?msg=" + (ok ? "cancelled" : "error"));
    }

}