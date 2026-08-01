package com.medicare.controller.warehouse;

import com.medicare.config.CacheManager;
import com.medicare.config.DBContext;
import com.medicare.dao.*;
import com.medicare.dao.interfaces.*;
import com.medicare.entity.Account;
import com.medicare.entity.Attendance;
import com.medicare.entity.Shift;
import com.medicare.entity.Task;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;

/**
 * WarehouseDashboardServlet — Trang làm việc RIÊNG của Quản lý kho (roleId 3 = Thủ kho).
 * URL: /warehouse-dashboard?uid=&lt;id&gt;
 *
 * <p>Bố cục theo góp ý tái thiết kế (bỏ "Lịch làm việc tuần" — không phù hợp với Thủ
 * kho làm giờ hành chính; thay bằng Control Tower: Task &amp; SLA deadline, Cảnh báo
 * thu hồi khẩn cấp, biểu đồ Nhập-Xuất 7 ngày):</p>
 * <ul>
 *   <li>Widget 1 — Task/Dự án Admin giao sắp/đã quá hạn (dùng lại {@link Task#getZone()}).</li>
 *   <li>Widget 2 — Lô đang bị thu hồi khẩn cấp (Batches.Status='RECALLED').</li>
 *   <li>Widget 3 — Biểu đồ Nhập/Xuất 7 ngày (Nhập = Batches mới tạo; Xuất = StockMovements
 *       loại OUT/EXPIRED — PO nhận hàng hiện KHÔNG ghi StockMovements nên dùng Batches.CreatedAt
 *       làm nguồn Nhập, không bịa thêm cột/luồng ghi log mới).</li>
 * </ul>
 */
@WebServlet(urlPatterns = {"/warehouse", "/warehouse-dashboard"})
public class WarehouseDashboardServlet extends HttpServlet {

    private static final int ROLE_WAREHOUSE = 3;

    private final IMedicineDAO   medicineDAO   = new MedicineDAO();
    private final IBatchesDAO    batchesDAO    = new BatchesDAO();
    private final IShiftDAO      shiftDAO      = new ShiftDAO();
    private final IAttendanceDAO attendanceDAO = new AttendanceDAO();
    private final ITaskDAO       taskDAO       = new TaskDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String uid = req.getParameter("uid");
        if (uid == null || uid.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login"); return;
        }
        HttpSession session = req.getSession(false);
        if (session == null) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login"); return;
        }
        Account acc = (Account) session.getAttribute("staffAccount_" + uid);
        if (acc == null) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login"); return;
        }
        if (acc.getRoleId() == 1) {
            resp.sendRedirect(req.getContextPath() + "/dashboard"); return;
        }
        if (acc.getRoleId() != ROLE_WAREHOUSE) {
            resp.sendRedirect(req.getContextPath() + "/staff-dashboard?uid=" + uid); return;
        }

        req.setAttribute("staffUid", uid);
        req.setAttribute("staffAcc", acc);

        // ── Số liệu tồn kho (cache 3 phút — dùng chung key với admin dashboard) ──
        req.setAttribute("totalMedicines",
                CacheManager.get("dash.totalMed", medicineDAO::countAll));
        req.setAttribute("lowStockCount",
                CacheManager.get("dash.lowStock", medicineDAO::countLowStock));
        req.setAttribute("expiryCount",
                CacheManager.get("dash.expiry", () -> batchesDAO.findExpiringSoon().size()));
        req.setAttribute("expiredCount",
                CacheManager.get("dash.expired", () -> batchesDAO.findExpired().size()));

        // ── Ca làm việc hiện tại + trạng thái điểm danh ──
        Shift currentShift = shiftDAO.findCurrent(acc.getAccountId());
        req.setAttribute("currentShift", currentShift);
        Attendance activeAtt = attendanceDAO.findActiveByAccount(acc.getAccountId());
        req.setAttribute("activeAtt", activeAtt);

        // ── Badge "Nhiệm vụ & SOP" trên sidebar ──
        req.setAttribute("myOpenTaskCount", taskDAO.countMyOpenTasks(acc.getAccountId()));

        // ── Widget 1: Task/Dự án sắp/đã quá hạn (chỉ zone WARNING/CRITICAL/OVERDUE) ──
        List<Task> urgentTasks = taskDAO.findMyOpenTasks(acc.getAccountId()).stream()
                .filter(t -> t.getZone() != null && !"SAFE".equals(t.getZone()))
                .limit(5)
                .collect(Collectors.toList());
        req.setAttribute("urgentTasks", urgentTasks);

        // ── Widget 2: Lô đang bị thu hồi khẩn cấp ──
        req.setAttribute("activeRecalls",
                CacheManager.getShort("wh.activeRecalls", this::findActiveRecalls));

        // ── Widget 3: Biểu đồ Nhập/Xuất 7 ngày ──
        req.setAttribute("stockTrendJson",
                CacheManager.get5("wh.stockTrend7d", this::buildStockTrendJson));

        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-dashboard.jsp")
                .forward(req, resp);
    }

    /** Lô đang ở trạng thái RECALLED (chưa được xử lý/thu gom xong) — cho banner cảnh báo đỏ. */
    private List<Map<String, Object>> findActiveRecalls() {
        List<Map<String, Object>> list = new ArrayList<>();
        String sql = "SELECT b.BatchNumber, m.MedicineName " +
                "FROM Batches b JOIN Medicines m ON m.MedicineID = b.MedicineID " +
                "WHERE b.Status = 'RECALLED' ORDER BY b.BatchID DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("batchNumber", rs.getString("BatchNumber"));
                row.put("medicineName", rs.getString("MedicineName"));
                list.add(row);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    /**
     * JSON {labels:[...], nhap:[...], xuat:[...]} cho biểu đồ Chart.js 7 ngày gần nhất.
     * Nhập = SUM(Batches.InitialQuantity) theo ngày tạo lô (PO nhận hàng hiện không ghi
     * StockMovements nên đây là nguồn "nhập kho" đáng tin cậy duy nhất đang có sẵn).
     * Xuất = SUM(ABS(StockMovements.Quantity)) loại OUT/EXPIRED theo ngày.
     */
    private String buildStockTrendJson() {
        Map<String, Long> nhapMap = new HashMap<>();
        Map<String, Long> xuatMap = new HashMap<>();

        String nhapSql = "SELECT CAST(CreatedAt AS DATE) AS Day, ISNULL(SUM(InitialQuantity),0) AS Qty " +
                "FROM Batches WHERE CreatedAt >= DATEADD(DAY,-6,CAST(GETDATE() AS DATE)) " +
                "GROUP BY CAST(CreatedAt AS DATE)";
        String xuatSql = "SELECT CAST(CreatedAt AS DATE) AS Day, ISNULL(SUM(ABS(Quantity)),0) AS Qty " +
                "FROM StockMovements WHERE MovementType IN ('OUT','EXPIRED') " +
                "AND CreatedAt >= DATEADD(DAY,-6,CAST(GETDATE() AS DATE)) " +
                "GROUP BY CAST(CreatedAt AS DATE)";
        try (Connection cn = DBContext.getConnection()) {
            try (PreparedStatement ps = cn.prepareStatement(nhapSql); ResultSet rs = ps.executeQuery()) {
                while (rs.next()) nhapMap.put(rs.getDate("Day").toLocalDate().toString(), rs.getLong("Qty"));
            }
            try (PreparedStatement ps = cn.prepareStatement(xuatSql); ResultSet rs = ps.executeQuery()) {
                while (rs.next()) xuatMap.put(rs.getDate("Day").toLocalDate().toString(), rs.getLong("Qty"));
            }
        } catch (Exception e) { e.printStackTrace(); }

        LocalDate today = LocalDate.now();
        StringBuilder labels = new StringBuilder("[");
        StringBuilder nhap = new StringBuilder("[");
        StringBuilder xuat = new StringBuilder("[");
        for (int i = 6; i >= 0; i--) {
            LocalDate d = today.minusDays(i);
            if (i < 6) { labels.append(","); nhap.append(","); xuat.append(","); }
            labels.append('"').append(String.format("%02d/%02d", d.getDayOfMonth(), d.getMonthValue())).append('"');
            nhap.append(nhapMap.getOrDefault(d.toString(), 0L));
            xuat.append(xuatMap.getOrDefault(d.toString(), 0L));
        }
        labels.append("]"); nhap.append("]"); xuat.append("]");
        return "{\"labels\":" + labels + ",\"nhap\":" + nhap + ",\"xuat\":" + xuat + "}";
    }
}
