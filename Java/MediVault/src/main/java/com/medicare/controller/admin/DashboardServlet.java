package com.medicare.controller.admin;

import com.medicare.config.DBContext;
import com.medicare.dao.*;
import com.medicare.dao.interfaces.*;
import com.medicare.entity.*;
import com.medicare.util.SidebarHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;
import java.time.LocalDate;
import java.util.*;

@WebServlet("/dashboard")
public class DashboardServlet extends HttpServlet {

    private final IMedicineDAO      medicineDAO = new MedicineDAO();
    private final IBatchesDAO       batchesDAO  = new BatchesDAO();
    private final IAccountDAO       accountDAO  = new AccountDAO();
    private final IPasswordResetDAO resetDAO    = new PasswordResetDAO();
    private final ILeaveRequestDAO  leaveDAO    = new LeaveRequestDAO();
    private final IInvoiceDAO       invoiceDAO  = new InvoiceDAO();
    private final IShiftDAO         shiftDAO    = new ShiftDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        Account adminAcc = session != null ? (Account) session.getAttribute("adminAccount") : null;

        if (adminAcc == null || adminAcc.getRoleId() != 1) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        // ── AJAX endpoints ──
        String action = req.getParameter("action");
        if ("realtime-stats".equals(action)) {
            handleRealtimeStats(resp);
            return;
        }

        // ── Stats (cache 3 phút — chậm đổi, tránh query lại mỗi lần vào dashboard) ──
        req.setAttribute("totalMedicines", com.medicare.config.CacheManager.get("dash.totalMed",   medicineDAO::countAll));
        req.setAttribute("lowStockCount",  com.medicare.config.CacheManager.get("dash.lowStock",   medicineDAO::countLowStock));
        req.setAttribute("expiryCount",    com.medicare.config.CacheManager.get("dash.expiry",     () -> batchesDAO.findExpiringSoon().size()));
        req.setAttribute("expiredCount",   com.medicare.config.CacheManager.get("dash.expired",    () -> batchesDAO.findExpired().size()));

        // ── Doanh thu hôm nay ──
        LocalDate today = LocalDate.now();
        List<Invoice> todayInvoiceList = invoiceDAO.findByDateRange(today, today);
        java.math.BigDecimal todayRevenueSum = java.math.BigDecimal.ZERO;
        for (Invoice inv : todayInvoiceList) {
            if (inv.getFinalAmount() != null) todayRevenueSum = todayRevenueSum.add(inv.getFinalAmount());
        }
        req.setAttribute("todayRevenue",  todayRevenueSum.longValue());
        req.setAttribute("todayInvoices", todayInvoiceList.size());

        // ── Accounts (cache 30s — dùng chung key với các trang admin khác) ──
        List<Account> allAccounts = com.medicare.config.CacheManager.getShort(
                "ref.allStaff", accountDAO::findAllStaff);
        req.setAttribute("accounts",       allAccounts);
        long activeCount = allAccounts.stream().filter(Account::isActive).count();
        req.setAttribute("activeAccounts", activeCount);

        Set<String> onlineStaffStr = new HashSet<>();
        for (Integer id : com.medicare.util.SessionTracker.getOnlineSet()) {
            onlineStaffStr.add(String.valueOf(id));
        }
        req.setAttribute("onlineStaff",      onlineStaffStr);
        req.setAttribute("onlineStaffCount", onlineStaffStr.size());

        // ── Pending Resets & Leave ──
        // KHÔNG set "pendingResetCount"/"pendingLeaveCount" thủ công ở đây — để
        // SidebarHelper.load(req) bên dưới set qua cache 30s dùng chung với sidebar
        // (trước đây set trước làm vô hiệu hoá cache của SidebarHelper cho riêng
        // trang Dashboard — chính là trang admin vào nhiều nhất, nên full-scan mỗi lần).
        List<PasswordResetRequest> pendingResets = resetDAO.findAllPending();
        req.setAttribute("pendingResets", pendingResets);
        List<LeaveRequest> pendingLeaves = leaveDAO.findPending();
        req.setAttribute("pendingLeaves", pendingLeaves);

        // ── Yêu cầu đăng ký lại khuôn mặt (nhân viên gửi lên) — cache 30s ──
        List<Account> pendingReenroll = com.medicare.config.CacheManager.getShort(
                "dash.pendingReenroll", () -> ((AccountDAO) accountDAO).findPendingFaceReenroll());
        req.setAttribute("pendingReenroll",      pendingReenroll);
        req.setAttribute("pendingReenrollCount", pendingReenroll.size());

        // ── Account maps (N+1 avoid) ──
        Map<Integer, Account> resetAccountMap   = new HashMap<>();
        List<Integer>         blockedIds        = resetDAO.findBlockedAccountIds();
        Map<Integer, Account> blockedAccountMap = new HashMap<>();
        Set<Integer> accountIdsToFetch = new HashSet<>(blockedIds);
        for (PasswordResetRequest pr : pendingResets) accountIdsToFetch.add(pr.getAccountId());
        if (!accountIdsToFetch.isEmpty()) {
            List<Account> fetched = accountDAO.findAccountsByIds(new ArrayList<>(accountIdsToFetch));
            Map<Integer, Account> fetchedMap = new HashMap<>();
            for (Account a : fetched) fetchedMap.put(a.getAccountId(), a);
            for (Integer bid : blockedIds) { Account a = fetchedMap.get(bid); if (a != null) blockedAccountMap.put(bid, a); }
            for (PasswordResetRequest pr : pendingResets) { Account a = fetchedMap.get(pr.getAccountId()); if (a != null) resetAccountMap.put(pr.getAccountId(), a); }
        }
        req.setAttribute("blockedAccountMap", blockedAccountMap);
        req.setAttribute("resetAccountMap",   resetAccountMap);

        // ── Chart data (JSON strings for JS) ──
        // Biểu đồ tổng hợp NẶNG (JOIN nhiều bảng) — cache 5 phút, chậm đổi
        req.setAttribute("chartDailyJson", com.medicare.config.CacheManager.get5("dash.chartDaily", this::buildDailyRevenueJson));
        req.setAttribute("chartTopJson",   com.medicare.config.CacheManager.get5("dash.chartTop",   this::buildTop5MedicinesJson));
        req.setAttribute("chartCatJson",   com.medicare.config.CacheManager.get5("dash.chartCat",   this::buildCategoryJson));

        // ── Recent invoices (top 5 hôm nay, fallback 5 gần nhất) ──
        List<Invoice> recentInvoices = todayInvoiceList.size() >= 5
                ? todayInvoiceList.subList(0, 5)
                : invoiceDAO.findByDateRange(today.minusDays(7), today)
                            .stream().limit(5).collect(java.util.stream.Collectors.toList());
        req.setAttribute("recentInvoices", recentInvoices);

        // ── Ca trực hôm nay ──
        List<Shift> todayShifts = shiftDAO.findByDateRange(today, today);
        req.setAttribute("todayShifts", todayShifts);

        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/admin/dashboard.jsp").forward(req, resp);
    }

    // ── AJAX: realtime numbers (poll every 60s) ──
    private void handleRealtimeStats(HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-cache");
        LocalDate today = LocalDate.now();
        // Cache 30s — endpoint này được poll mỗi 60s từ mỗi tab admin đang mở dashboard;
        // không cần query DB mới cho mỗi lượt poll của mỗi tab.
        List<Invoice> list = com.medicare.config.CacheManager.getShort(
                "dash.todayInvoices", () -> invoiceDAO.findByDateRange(today, today));
        long revenue = 0;
        for (Invoice inv : list) {
            if (inv.getFinalAmount() != null) revenue += inv.getFinalAmount().longValue();
        }
        int expiring = com.medicare.config.CacheManager.get("dash.expiry",
                () -> batchesDAO.findExpiringSoon().size());
        resp.getWriter().write(String.format(
                "{\"revenue\":%d,\"orders\":%d,\"warnings\":%d}",
                revenue, list.size(), expiring
        ));
    }

    // ── Doanh thu 30 ngày gần nhất ──
    private String buildDailyRevenueJson() {
        Map<String, Long> map = new LinkedHashMap<>();
        String sql = "SELECT CAST(CreatedAt AS DATE) AS Day, ISNULL(SUM(FinalAmount),0) AS Revenue " +
                "FROM Invoices WHERE Status='COMPLETED' " +
                "AND CAST(CreatedAt AS DATE)>=DATEADD(DAY,-29,CAST(GETDATE() AS DATE)) " +
                "GROUP BY CAST(CreatedAt AS DATE) ORDER BY CAST(CreatedAt AS DATE)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                map.put(rs.getDate("Day").toLocalDate().toString(), rs.getLong("Revenue"));
            }
        } catch (Exception e) { e.printStackTrace(); }

        LocalDate today = LocalDate.now();
        StringBuilder labels = new StringBuilder("[");
        StringBuilder values = new StringBuilder("[");
        for (int i = 29; i >= 0; i--) {
            LocalDate d = today.minusDays(i);
            if (i < 29) { labels.append(","); values.append(","); }
            labels.append('"')
                  .append(String.format("%02d/%02d", d.getDayOfMonth(), d.getMonthValue()))
                  .append('"');
            values.append(map.getOrDefault(d.toString(), 0L));
        }
        labels.append("]"); values.append("]");
        return "{\"labels\":" + labels + ",\"values\":" + values + "}";
    }

    // ── Top 5 thuốc bán chạy tháng này ──
    private String buildTop5MedicinesJson() {
        StringBuilder names = new StringBuilder("[");
        StringBuilder qtys  = new StringBuilder("[");
        String sql = "SELECT TOP 5 m.MedicineName, SUM(id.Quantity) AS TotalQty " +
                "FROM InvoiceDetails id " +
                "JOIN Batches b ON b.BatchID=id.BatchID " +
                "JOIN Medicines m ON m.MedicineID=b.MedicineID " +
                "JOIN Invoices i ON i.InvoiceID=id.InvoiceID " +
                "WHERE i.Status='COMPLETED' " +
                "AND YEAR(i.CreatedAt)=YEAR(GETDATE()) AND MONTH(i.CreatedAt)=MONTH(GETDATE()) " +
                "GROUP BY m.MedicineID,m.MedicineName ORDER BY TotalQty DESC";
        int count = 0;
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                if (count++ > 0) { names.append(","); qtys.append(","); }
                String name = rs.getString("MedicineName").replace("\\", "\\\\").replace("\"", "\\\"");
                names.append('"').append(name).append('"');
                qtys.append(rs.getLong("TotalQty"));
            }
        } catch (Exception e) { e.printStackTrace(); }
        if (count == 0) return "{\"names\":[\"Chưa có dữ liệu\"],\"quantities\":[0]}";
        names.append("]"); qtys.append("]");
        return "{\"names\":" + names + ",\"quantities\":" + qtys + "}";
    }

    // ── Tỷ trọng doanh thu theo danh mục tháng này ──
    private String buildCategoryJson() {
        StringBuilder names = new StringBuilder("[");
        StringBuilder revs  = new StringBuilder("[");
        String sql = "SELECT TOP 8 c.CategoryName, ISNULL(SUM(id.SubTotal),0) AS Revenue " +
                "FROM InvoiceDetails id " +
                "JOIN Batches b ON b.BatchID=id.BatchID " +
                "JOIN Medicines m ON m.MedicineID=b.MedicineID " +
                "JOIN Categories c ON c.CategoryID=m.CategoryID " +
                "JOIN Invoices i ON i.InvoiceID=id.InvoiceID " +
                "WHERE i.Status='COMPLETED' " +
                "AND YEAR(i.CreatedAt)=YEAR(GETDATE()) AND MONTH(i.CreatedAt)=MONTH(GETDATE()) " +
                "GROUP BY c.CategoryID,c.CategoryName ORDER BY Revenue DESC";
        int count = 0;
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                if (count++ > 0) { names.append(","); revs.append(","); }
                String name = rs.getString("CategoryName").replace("\\", "\\\\").replace("\"", "\\\"");
                names.append('"').append(name).append('"');
                revs.append(rs.getLong("Revenue"));
            }
        } catch (Exception e) { e.printStackTrace(); }
        if (count == 0) return "{\"names\":[\"Chưa có dữ liệu\"],\"revenues\":[1]}";
        names.append("]"); revs.append("]");
        return "{\"names\":" + names + ",\"revenues\":" + revs + "}";
    }
}
