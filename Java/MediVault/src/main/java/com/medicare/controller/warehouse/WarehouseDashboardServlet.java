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
 * URL: /warehouse-dashboard
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

        // WarehouseAuth chi tra ve tai khoan roleId==3; admin/nhan vien ban hang khong lot qua
        // duoc nen 2 nhanh dieu huong theo role truoc day thanh thua. Danh tinh tu SESSION.
        Account acc = com.medicare.util.WarehouseAuth.require(req, resp);
        if (acc == null) return;
        String uid = String.valueOf(acc.getAccountId());

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

        // ── Widget 4: "Đường chân trời hạn dùng" ──
        // Dải thời gian trên trang chủ cần TỪNG LÔ (số ngày còn lại + tên thuốc), không
        // chỉ 2 con số đếm như expiryCount/expiredCount. Dùng lại đúng 2 truy vấn đã có
        // sẵn (findExpired + findExpiringSoon) rồi gộp, không thêm SQL mới.
        req.setAttribute("horizonJson",
                CacheManager.getShort("wh.horizon", () -> buildHorizonJson(medicineDAO)));

        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-dashboard.jsp")
                .forward(req, resp);
    }

    /**
     * JSON cho "Đường chân trời hạn dùng": mỗi lô còn tồn là một điểm
     * {@code {d: số ngày còn lại, n: tên thuốc, b: số lô, q: tồn}}.
     *
     * <p>Số ngày âm = đã quá hạn. Chỉ lấy lô còn tồn ({@code currentQuantity > 0}) —
     * lô đã xuất hết không còn là rủi ro, đưa lên dải chỉ làm nhiễu.</p>
     */
    private String buildHorizonJson(IMedicineDAO medDao) {
        // BUG THẬT (đã fix): trước đây gộp findExpired() + findExpiringSoon() — nhưng
        // findExpiringSoon() giới hạn cứng "ExpiryDate <= DATEADD(day, 30, GETDATE())"
        // (xem BatchesDAO), nên rows chỉ bao giờ chứa lô ĐÃ quá hạn hoặc hạn TRONG 30
        // NGÀY. Widget "Đường chân trời hạn dùng" hứa hẹn 4 vùng (Quá hạn/≤30/31–90/
        // >90) nhưng 2 vùng "31–90 ngày" và "Trên 90 ngày" KHÔNG BAO GIỜ có dữ liệu để
        // hiển thị — không phải do kho trống, mà do nguồn dữ liệu chưa từng truy vấn tới
        // đó. Đổi sang findAll() (mọi lô ACTIVE, không giới hạn hạn dùng) — vòng lặp bên
        // dưới đã tự lọc currentQuantity<=0 nên không cần siết thêm ở tầng query.
        List<com.medicare.entity.Batches> rows = batchesDAO.findAll();

        Map<Integer, String> names = new HashMap<>();
        for (com.medicare.entity.Medicines m : medDao.findAll()) {
            names.put(m.getMedicineId(), m.getMedicineName());
        }

        LocalDate today = LocalDate.now();
        StringBuilder sb = new StringBuilder("[");
        boolean first = true;
        for (com.medicare.entity.Batches b : rows) {
            if (b.getExpiryDate() == null || b.getCurrentQuantity() <= 0) continue;
            long days = java.time.temporal.ChronoUnit.DAYS.between(today, b.getExpiryDate());
            if (!first) sb.append(',');
            first = false;
            sb.append("{\"d\":").append(days)
              .append(",\"n\":").append(jsonStr(names.getOrDefault(b.getMedicineId(), "—")))
              .append(",\"b\":").append(jsonStr(b.getBatchNumber()))
              .append(",\"q\":").append(b.getCurrentQuantity())
              .append('}');
        }
        return sb.append(']').toString();
    }

    private static String jsonStr(String s) {
        if (s == null) return "\"\"";
        return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"")
                       .replace("\n", " ").replace("\r", " ") + "\"";
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
