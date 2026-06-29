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
import com.medicare.util.StaffNotifHelper;
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
            case "detail"      -> showDetail(req, resp);
            case "force-close" -> handleForceClose(req, resp);
            case "delete"      -> handleDelete(req, resp);
            case "pos-online"  -> handlePosOnline(req, resp);
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

        // ── Dữ liệu cho Modal Xóa ca — hiển thị 1 THÁNG ─────────────────────
        // Navigate tháng cho modal xóa: param "delMonth" (YYYY-MM)
        String delMonthStr = req.getParameter("delMonth");
        java.time.YearMonth delMonth = java.time.YearMonth.now();
        if (delMonthStr != null && !delMonthStr.isBlank()) {
            try { delMonth = java.time.YearMonth.parse(delMonthStr); } catch (Exception ignored) {}
        }
        java.time.LocalDate monthStart = delMonth.atDay(1);
        java.time.LocalDate monthEnd   = delMonth.atEndOfMonth();
        // Mở rộng sang tuần đầu/cuối để bảng calendar đủ 6 hàng
        java.time.LocalDate calStart = monthStart.minusDays(monthStart.getDayOfWeek().getValue() - 1);
        java.time.LocalDate calEnd   = monthEnd.plusDays(7 - monthEnd.getDayOfWeek().getValue());
        java.util.List<com.medicare.entity.ShiftSchedule> monthSchedules =
                scheduleDAO.findByDateRange(calStart, calEnd);

        java.util.List<java.time.LocalDate> monthDays = new java.util.ArrayList<>();
        for (java.time.LocalDate d = calStart; !d.isAfter(calEnd); d = d.plusDays(1)) {
            monthDays.add(d);
        }

        req.setAttribute("monthSchedules", monthSchedules);
        req.setAttribute("monthDays",      monthDays);
        req.setAttribute("delMonth",       delMonth.toString());
        req.setAttribute("delMonthLabel",  delMonth.getMonth().getDisplayName(
                java.time.format.TextStyle.FULL, new java.util.Locale("vi", "VN"))
                + " " + delMonth.getYear());
        req.setAttribute("prevDelMonth",   delMonth.minusMonths(1).toString());
        req.setAttribute("nextDelMonth",   delMonth.plusMonths(1).toString());
        req.setAttribute("calStart",       calStart.toString());
        req.setAttribute("calEnd",         calEnd.toString());

        // ── Dữ liệu cho Tab Loại ca ──────────────────────────────────────────
        req.setAttribute("shiftTypes",   shiftTypeDAO.findAll());

        // ── Dữ liệu cho Tab Nghỉ phép ────────────────────────────────────────
        java.util.List<com.medicare.entity.LeaveRequest> pendingLeaves = leaveDAO.findPending();
        req.setAttribute("pendingLeaves",     pendingLeaves);
        req.setAttribute("pendingLeaveCount", pendingLeaves.size());

        // ── Dữ liệu sơ đồ quầy POS hôm nay ──────────────────────────────────
        java.util.List<ShiftSchedule> todaySchedules =
                ((ShiftScheduleDAO) scheduleDAO).findTodayAll();
        req.setAttribute("todaySchedules", todaySchedules);

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

    // ── POS Online Status (AJAX) ──────────────────────────────────────────────
    private void handlePosOnline(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        // Lấy tất cả session trên server → tìm session nào có posStation > 0 và còn active
        // Cách đơn giản: đọc ShiftSchedules hôm nay có status CONFIRMED → quầy của họ = online
        java.util.List<ShiftSchedule> todaySchedules =
                ((ShiftScheduleDAO) scheduleDAO).findTodayAll();
        java.util.Set<Integer> onlineStations = new java.util.LinkedHashSet<>();
        for (ShiftSchedule ss : todaySchedules) {
            if (ss.getPosStation() > 0
                    && ("CONFIRMED".equals(ss.getStatus()) || "LATE".equals(ss.getStatus()))) {
                onlineStations.add(ss.getPosStation());
            }
        }
        // Thêm stations đang trong session active (có posStation set)
        // Lấy session context để kiểm tra sessions đang active
        try {
            jakarta.servlet.http.HttpSession curSess = req.getSession(false);
            Object posStObj = curSess != null ? curSess.getAttribute("posStation") : null;
            if (posStObj instanceof Integer && (Integer) posStObj > 0) {
                onlineStations.add((Integer) posStObj);
            }
        } catch (Exception ignored) {}

        java.io.PrintWriter out = resp.getWriter();
        out.print("{\"onlineStations\":[");
        boolean first = true;
        for (int st : onlineStations) {
            if (!first) out.print(",");
            out.print(st);
            first = false;
        }
        out.print("]}");
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
        int      posStation = parseIntOr(req.getParameter("posStation"), 0);

        if (accIds == null || typeIds == null || dateFrom == null || dateFrom.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/shifts?msg=invalid"); return;
        }

        int created = 0, skipped = 0;
        try {
            java.time.LocalDate from = java.time.LocalDate.parse(dateFrom);
            java.time.LocalDate to   = (dateTo != null && !dateTo.isEmpty())
                    ? java.time.LocalDate.parse(dateTo) : from;

            // ── Xử lý ngày quá khứ thông minh ──
            // Nếu toàn bộ range đều quá khứ → chặn hoàn toàn
            // Nếu range bắt đầu từ quá khứ nhưng kết thúc ở tương lai → bỏ qua ngày quá khứ, tạo từ hôm nay
            java.time.LocalDate today = java.time.LocalDate.now();
            if (to.isBefore(today)) {
                // Toàn bộ range đã qua → không thể tạo
                resp.sendRedirect(req.getContextPath()
                        + "/shifts?msg=past-date"); return;
            }
            // Đẩy from lên today nếu from < today (bỏ qua ngày quá khứ trong range)
            int pastDaysSkipped = 0;
            if (from.isBefore(today)) {
                pastDaysSkipped = (int) java.time.temporal.ChronoUnit.DAYS.between(from, today);
                from = today;
            }

            for (String aId : accIds)
                for (String tId : typeIds)
                    for (java.time.LocalDate d = from; !d.isAfter(to); d = d.plusDays(1)) {
                        int r = scheduleDAO.schedule(
                                Integer.parseInt(aId), Integer.parseInt(tId),
                                d, admin.getAccountId());
                        if (r > 0) {
                            created++;
                            if (posStation > 0)
                                ((com.medicare.dao.ShiftScheduleDAO) scheduleDAO).updatePosStation(r, posStation);
                        } else skipped++;
                    }
            // Cộng pastDaysSkipped vào skipped cho mỗi combo (staff × type)
            skipped += pastDaysSkipped * accIds.length * typeIds.length;
            AuditHelper.log(req, "Xếp lịch ca", "ShiftSchedule",
                    "Tạo " + created + " ca, bỏ qua " + skipped + " đã tồn tại");
            // Notify từng nhân viên
            if (created > 0) {
                String dateRange = from + " → " + to;
                for (String aId : accIds) {
                    try {
                        StaffNotifHelper.shiftAssignedBulk(
                                Integer.parseInt(aId), created / accIds.length, dateRange);
                    } catch (Exception ignored) {}
                }
            }
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
        int posStation  = parseIntOr(req.getParameter("posStation"), -1); // -1 = không thay đổi

        if (scheduleId == 0) {
            resp.sendRedirect(req.getContextPath() + "/shifts?msg=invalid"); return;
        }
        ShiftScheduleDAO dao = (ShiftScheduleDAO) scheduleDAO;
        boolean ok = dao.update(scheduleId, shiftTypeId, lateTol, notes,
                admin.getAccountId(), posStation);
        if (ok) AuditHelper.log(req, "Sửa lịch ca", "ShiftSchedule",
                "Sửa ca ID " + scheduleId + (posStation > 0 ? " → Quầy " + posStation : ""));
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