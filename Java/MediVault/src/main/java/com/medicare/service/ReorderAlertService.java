package com.medicare.service;

import com.medicare.config.DBContext;
import com.medicare.dao.MedicineDAO;
import com.medicare.dao.PurchaseOrderDAO;
import com.medicare.entity.Batches;
import com.medicare.entity.Medicines;
import com.medicare.entity.PurchaseOrders;
import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.logging.Logger;

/**
 * ReorderAlertService — Background service cho portal Quản lý kho (roleId 3):
 *   1) Tự động cách ly (Status='QUARANTINE') các lô cận hạn ≤30 ngày — SP_AddSaleByFEFO
 *      chỉ bán lô Status='ACTIVE' nên lô bị cách ly tự động ngừng được bán, không cần sửa SP.
 *   2) Tính ROP (Reorder Point) từng thuốc đang kinh doanh, tự tạo phiếu đặt hàng gợi ý
 *      (PurchaseOrders Status='PENDING' — CHƯA tạo Batches, kho chưa tăng) khi tồn kho
 *      chạm ngưỡng, để Admin duyệt qua màn Quản lý phiếu nhập có sẵn.
 *
 * Chạy mỗi 1 giờ (thực tế nên 24h/lần, nhưng rút ngắn xuống 1h để demo được trong buổi
 * bảo vệ đồ án mà không phải chờ qua ngày) — theo đúng mẫu @WebListener + ScheduledExecutorService
 * của {@link ShiftAutoCloseService}, KHÔNG dùng Quartz hay thư viện lập lịch ngoài nào.
 */
@WebListener
public class ReorderAlertService implements ServletContextListener {

    private static final Logger log = Logger.getLogger(ReorderAlertService.class.getName());

    private ScheduledExecutorService scheduler;
    private final PurchaseOrderDAO purchaseOrderDAO = new PurchaseOrderDAO();
    private final MedicineDAO medicineDAO = new MedicineDAO();

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "reorder-alert");
            t.setDaemon(true); // tắt cùng JVM, không giữ Tomcat sống khi shutdown
            return t;
        });

        // Chạy mỗi 1 giờ, delay đầu 1 giờ sau khi Tomcat khởi động
        scheduler.scheduleAtFixedRate(this::run, 1, 1, TimeUnit.HOURS);
        log.info("[ReorderAlert] Service started — checking every 1 hour");
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        if (scheduler != null) {
            scheduler.shutdownNow();
            log.info("[ReorderAlert] Service stopped");
        }
    }

    /** Toàn bộ được bọc try-catch riêng từng bước — service chạy nền liên tục, không được crash. */
    private void run() {
        try {
            quarantineExpiringBatches();
        } catch (Exception e) {
            log.warning("[ReorderAlert] Lỗi cách ly lô cận hạn: " + e.getMessage());
        }
        try {
            generateReorderSuggestions();
        } catch (Exception e) {
            log.warning("[ReorderAlert] Lỗi tính ROP / tạo gợi ý đặt hàng: " + e.getMessage());
        }
    }

    /**
     * Tự động cách ly lô cận hạn ≤30 ngày (nhưng chưa hết hạn) — chuyển Status sang 'QUARANTINE'.
     * Cột Status trên bảng Batches là VARCHAR không có CHECK constraint, và SP_AddSaleByFEFO
     * đã tự lọc WHERE Status='ACTIVE', nên đổi Status là đủ để chặn bán, không cần sửa SP.
     */
    private void quarantineExpiringBatches() {
        String sql = "UPDATE Batches SET Status = 'QUARANTINE' " +
                "WHERE Status = 'ACTIVE' " +
                "AND ExpiryDate <= DATEADD(day, 30, GETDATE()) " +
                "AND ExpiryDate > CAST(GETDATE() AS DATE)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            int affected = ps.executeUpdate();
            log.info("[ReorderAlert] Đã cách ly " + affected + " lô cận hạn dùng (<=30 ngày)");
        } catch (Exception e) {
            log.warning("[ReorderAlert] Lỗi UPDATE cách ly lô cận hạn: " + e.getMessage());
        }
    }

    /** Duyệt từng thuốc đang kinh doanh (Status=1), tính ROP và tạo gợi ý đặt hàng nếu cần. */
    private void generateReorderSuggestions() {
        List<Medicines> actives = medicineDAO.findAll(); // findAll() đã lọc WHERE Status = 1
        if (actives.isEmpty()) return;

        Integer adminAccountId = findFirstAdmin();
        if (adminAccountId == null) {
            log.warning("[ReorderAlert] Không tìm thấy tài khoản Admin (RoleID=1) — bỏ qua tạo gợi ý đặt hàng.");
            return;
        }

        int created = 0;
        for (Medicines m : actives) {
            try {
                if (processMedicine(m, adminAccountId)) created++;
            } catch (Exception e) {
                log.warning("[ReorderAlert] Lỗi xử lý ROP MedicineID=" + m.getMedicineId() + ": " + e.getMessage());
            }
        }
        if (created > 0) log.info("[ReorderAlert] Đã tạo " + created + " phiếu đề xuất đặt hàng mới");
    }

    /** @return true nếu đã tạo 1 phiếu đề xuất đặt hàng cho thuốc này. */
    private boolean processMedicine(Medicines m, int adminAccountId) throws SQLException {
        int medicineId = m.getMedicineId();

        double avgDaily = avgDailyConsumption(medicineId);
        if (avgDaily <= 0) return false; // không có dữ liệu bán 30 ngày gần nhất → bỏ qua

        int[] leadTimeAndSupplier = leadTimeAndSupplier(medicineId);
        if (leadTimeAndSupplier == null) return false; // chưa từng nhập lô nào → chưa đủ dữ liệu

        int leadTimeDays = leadTimeAndSupplier[0];
        int supplierId = leadTimeAndSupplier[1];

        int rop = (int) Math.ceil(avgDaily * leadTimeDays) + m.getMinInventory();
        int currentStock = currentActiveStock(medicineId);

        if (currentStock > rop) return false; // còn đủ hàng, chưa chạm ngưỡng

        if (hasPendingPO(medicineId)) return false; // đã có gợi ý PENDING chờ Admin duyệt, tránh tạo trùng mỗi giờ

        int suggestQty = Math.max(1, (int) Math.ceil(rop * 2.0 - currentStock));

        PurchaseOrders po = new PurchaseOrders();
        po.setSupplierId(supplierId);
        po.setAccountId(adminAccountId);
        po.setStatus("PENDING"); // PENDING → PurchaseOrderDAO.createWithBatches CHỈ ghi chứng từ, kho chưa tăng
        po.setNotes("Tự động đề xuất bởi hệ thống — tồn kho dưới ngưỡng ROP (an toàn)");
        po.setPaymentMethod(null);
        po.setDiscountAmount(BigDecimal.ZERO);
        BigDecimal unitPrice = m.getSellingPrice() != null ? m.getSellingPrice() : BigDecimal.ZERO;
        po.setTotalValue(unitPrice.multiply(BigDecimal.valueOf(suggestQty)));

        // Dòng chi tiết chỉ có MedicineID + số lượng đề xuất — số lô/HSD/NSX CHƯA xác định vì
        // hàng chưa về (đây mới là "gợi ý", Admin sẽ điền số lô thật lúc xác nhận nhận hàng).
        Batches line = new Batches();
        line.setMedicineId(medicineId);
        line.setInitialQuantity(suggestQty);
        line.setImportPrice(unitPrice);

        List<Batches> lines = new ArrayList<>();
        lines.add(line);

        int poId = purchaseOrderDAO.createWithBatches(po, lines);
        if (poId > 0) {
            log.info("[ReorderAlert] Tạo phiếu đề xuất POID=" + poId + " cho MedicineID=" + medicineId
                    + " (SL đề xuất=" + suggestQty + ", tồn hiện tại=" + currentStock + ", ROP=" + rop + ")");
            return true;
        }
        return false;
    }

    /** Tiêu thụ trung bình/ngày trong 30 ngày gần nhất (0 nếu không có dữ liệu bán). */
    private double avgDailyConsumption(int medicineId) throws SQLException {
        String sql = "SELECT AVG(daily_qty) FROM (" +
                "  SELECT CAST(inv.CreatedAt AS DATE) AS d, SUM(id.Quantity) AS daily_qty" +
                "  FROM InvoiceDetails id" +
                "  JOIN Invoices inv ON inv.InvoiceID = id.InvoiceID" +
                "  JOIN Batches b ON b.BatchID = id.BatchID" +
                "  WHERE b.MedicineID = ? AND inv.Status = 'COMPLETED'" +
                "    AND inv.CreatedAt >= DATEADD(day, -30, GETDATE())" +
                "  GROUP BY CAST(inv.CreatedAt AS DATE)" +
                ") x";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, medicineId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    double v = rs.getDouble(1);
                    return rs.wasNull() ? 0d : v;
                }
            }
        }
        return 0d;
    }

    /** {LeadTimeDays, SupplierID} của lô gần nhất đã nhập thuốc này — null nếu chưa từng nhập. */
    private int[] leadTimeAndSupplier(int medicineId) throws SQLException {
        String sql = "SELECT TOP 1 s.LeadTimeDays, b.SupplierID " +
                "FROM Batches b JOIN Suppliers s ON s.SupplierID = b.SupplierID " +
                "WHERE b.MedicineID = ? ORDER BY b.CreatedAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, medicineId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new int[]{rs.getInt(1), rs.getInt(2)};
                }
            }
        }
        return null;
    }

    /** Tổng tồn kho thực tế (chỉ tính lô Status='ACTIVE') của 1 thuốc. */
    private int currentActiveStock(int medicineId) throws SQLException {
        String sql = "SELECT ISNULL(SUM(CurrentQuantity), 0) FROM Batches WHERE MedicineID = ? AND Status = 'ACTIVE'";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, medicineId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        }
        return 0;
    }

    /** Đã có phiếu Status='PENDING' nào chứa thuốc này chưa — tránh tạo gợi ý trùng mỗi giờ. */
    private boolean hasPendingPO(int medicineId) throws SQLException {
        String sql = "SELECT TOP 1 1 FROM PurchaseOrders po " +
                "JOIN PurchaseOrderDetails d ON d.POID = po.POID " +
                "WHERE po.Status = 'PENDING' AND d.MedicineID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, medicineId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /** Tài khoản Admin đầu tiên tìm được — dùng làm AccountID của phiếu đề xuất tự động. */
    private Integer findFirstAdmin() {
        String sql = "SELECT TOP 1 AccountID FROM Accounts WHERE RoleID = 1 AND IsDeleted = 0";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) {
            log.warning("[ReorderAlert] Lỗi tìm tài khoản Admin: " + e.getMessage());
        }
        return null;
    }
}
