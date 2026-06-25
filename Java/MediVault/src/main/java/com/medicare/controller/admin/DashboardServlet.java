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

        // ── Stats ──
        req.setAttribute("totalMedicines", medicineDAO.countAll());
        req.setAttribute("lowStockCount",  medicineDAO.countLowStock());
        req.setAttribute("expiryCount",    batchesDAO.findExpiringSoon().size());
        req.setAttribute("expiredCount",   batchesDAO.findExpired().size());

        // ── Doanh thu hôm nay ──
        LocalDate today = LocalDate.now();
        List<Invoice> todayInvoiceList = invoiceDAO.findByDateRange(today, today);
        java.math.BigDecimal todayRevenueSum = java.math.BigDecimal.ZERO;
        for (Invoice inv : todayInvoiceList) {
            if (inv.getFinalAmount() != null) todayRevenueSum = todayRevenueSum.add(inv.getFinalAmount());
        }
        req.setAttribute("todayRevenue",  todayRevenueSum.longValue());
        req.setAttribute("todayInvoices", todayInvoiceList.size());

        // ── Accounts ──
        List<Account> allAccounts = accountDAO.findAllStaff();
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
        List<PasswordResetRequest> pendingResets = resetDAO.findAllPending();
        req.setAttribute("pendingResets",     pendingResets);
        req.setAttribute("pendingResetCount", pendingResets.size());
        int pendingLeaveCount = leaveDAO.findPending().size();
        req.setAttribute("pendingLeaveCount", pendingLeaveCount);

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
        req.setAttribute("chartDailyJson", buildDailyRevenueJson());
        req.setAttribute("chartTopJson",   buildTop5MedicinesJson());
        req.setAttribute("chartCatJson",   buildCategoryJson());

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
        List<Invoice> list = invoiceDAO.findByDateRange(today, today);
        long revenue = 0;
        for (Invoice inv : list) {
            if (inv.getFinalAmount() != null) revenue += inv.getFinalAmount().longValue();
        }
        resp.getWriter().write(String.format(
                "{\"revenue\":%d,\"orders\":%d,\"warnings\":%d}",
                revenue, list.size(), batchesDAO.findExpiringSoon().size()
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
                "JOIN Medicines m ON m.MedicineID=id.MedicineID " +
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
                "JOIN Medicines m ON m.MedicineID=id.MedicineID " +
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
