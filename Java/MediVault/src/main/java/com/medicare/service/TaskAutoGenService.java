package com.medicare.service;

import com.medicare.config.DBContext;
import com.medicare.dao.AccountDAO;
import com.medicare.dao.InvoiceDAO;
import com.medicare.dao.TaskDAO;
import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.dao.interfaces.IInvoiceDAO;
import com.medicare.dao.interfaces.ITaskDAO;
import com.medicare.entity.Account;
import com.medicare.util.EmailUtil;
import com.medicare.util.StaffNotifHelper;
import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.logging.Logger;

/**
 * TaskAutoGenService — Type A "System-Generated Tasks" của mô-đun To-do List (mục 5,
 * portal Quản lý kho). KHÔNG tự tính lại ROP/hạn dùng từ đầu — chỉ lắng nghe 3 tín hiệu
 * NGHIỆP VỤ đã tồn tại sẵn trong hệ thống và biến chúng thành 1 Task có thể giao/nhận/
 * tích [✓] hoàn thành với audit log (đúng luồng ở mục 3 của tài liệu):
 *
 *   1) Hạn dùng   — Batches sắp/đã bị {@link ReorderAlertService} cách ly (≤60 ngày, còn ACTIVE
 *                   hoặc đã QUARANTINE) → Task "dán tem off-price / kiểm định".
 *   2) ROP        — PurchaseOrders do ReorderAlertService tự đề xuất (PENDING, Notes riêng)
 *                   → Task "đếm thực tế & duyệt phiếu đặt hàng".
 *   3) Lệch ca    — Shifts vừa CLOSED có ClosingCash lệch so với (OpeningCash + doanh thu
 *                   tiền mặt trong ca, từ {@link InvoiceDAO#sumCashRevenueByShift}) quá
 *                   50.000đ → Task giao thẳng cho chủ ca đối soát.
 *
 * Mỗi tín hiệu đều chống tạo trùng qua {@link ITaskDAO#existsOpenTaskForRef}, nên chạy lại
 * nhiều lần (mỗi giờ) là an toàn. Theo đúng mẫu @WebListener + ScheduledExecutorService của
 * {@link ReorderAlertService}, không dùng Quartz.
 */
@WebListener
public class TaskAutoGenService implements ServletContextListener {

    private static final Logger log = Logger.getLogger(TaskAutoGenService.class.getName());
    private static final BigDecimal CASH_TOLERANCE = BigDecimal.valueOf(50000);

    private ScheduledExecutorService scheduler;
    private final ITaskDAO taskDAO = new TaskDAO();
    private final IInvoiceDAO invoiceDAO = new InvoiceDAO();
    private final IAccountDAO accountDAO = new AccountDAO();

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "task-autogen");
            t.setDaemon(true);
            return t;
        });
        scheduler.scheduleAtFixedRate(this::run, 2, 1, TimeUnit.HOURS);
        log.info("[TaskAutoGen] Service started — checking every 1 hour");
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        if (scheduler != null) {
            scheduler.shutdownNow();
            log.info("[TaskAutoGen] Service stopped");
        }
    }

    private void run() {
        try { scanExpiringBatches(); }
        catch (Exception e) { log.warning("[TaskAutoGen] Lỗi quét hạn dùng: " + e.getMessage()); }
        try { scanReorderSuggestions(); }
        catch (Exception e) { log.warning("[TaskAutoGen] Lỗi quét gợi ý ROP: " + e.getMessage()); }
        try { scanShiftCashDiscrepancy(); }
        catch (Exception e) { log.warning("[TaskAutoGen] Lỗi quét lệch ca: " + e.getMessage()); }
        try { scanDeadlineNudges(); }
        catch (Exception e) { log.warning("[TaskAutoGen] Lỗi quét nhắc hạn chót: " + e.getMessage()); }
    }

    /**
     * Vùng cảnh báo hạn chót (mục II.2 tài liệu "Giao Task &amp; Tiến độ kho") — quét
     * task/dự án chưa xong có DueDate, tính vùng NGAY TẠI ĐÂY (giống hệt công thức
     * {@link com.medicare.entity.Task#getZone()}, không lưu cứng IsOverdue), chỉ nhắc
     * lại khi vùng thay đổi so với LastNudgeZone đã lưu — chống spam mỗi giờ.
     */
    private void scanDeadlineNudges() throws Exception {
        String sql = "SELECT TaskID, Title, AssignedTo, DueDate, LastNudgeZone FROM Tasks " +
                "WHERE Status IN ('PENDING','IN_PROGRESS') AND DueDate IS NOT NULL " +
                "AND AssignedTo IS NOT NULL AND DueDate <= DATEADD(HOUR, 48, GETDATE())";
        int nudged = 0;
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                int taskId = rs.getInt("TaskID");
                String title = rs.getString("Title");
                int assignedTo = rs.getInt("AssignedTo");
                LocalDateTime dueDate = rs.getTimestamp("DueDate").toLocalDateTime();
                String lastZone = rs.getString("LastNudgeZone");

                long hoursLeft = ChronoUnit.HOURS.between(LocalDateTime.now(), dueDate);
                String zone = hoursLeft < 0 ? "OVERDUE" : (hoursLeft <= 24 ? "CRITICAL" : "WARNING");
                if (zone.equals(lastZone)) continue; // đã nhắc đúng vùng này rồi, bỏ qua

                StaffNotifHelper.taskDeadlineWarning(assignedTo, title, zone);
                Account acc = accountDAO.findById(assignedTo);
                if (acc != null && acc.getEmail() != null && !acc.getEmail().isBlank()) {
                    EmailUtil.sendEmail(acc.getEmail(),
                            "[MediCare] Nhắc hạn công việc: " + title,
                            "<p>Công việc <b>" + title + "</b> " +
                            ("OVERDUE".equals(zone) ? "đã <b>quá hạn</b> báo hoàn thành."
                                    : "còn <b>" + hoursLeft + " giờ</b> để báo hoàn thành.") +
                            "</p><p>Vào MediCare &gt; Nhiệm vụ &amp; SOP để xử lý.</p>");
                }
                updateLastNudgeZone(taskId, zone);
                nudged++;
            }
        }
        if (nudged > 0) log.info("[TaskAutoGen] Đã nhắc hạn chót " + nudged + " task");
    }

    private void updateLastNudgeZone(int taskId, String zone) {
        String sql = "UPDATE Tasks SET LastNudgeZone = ? WHERE TaskID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, zone);
            ps.setInt(2, taskId);
            ps.executeUpdate();
        } catch (Exception e) {
            log.warning("[TaskAutoGen] Lỗi cập nhật LastNudgeZone TaskID=" + taskId + ": " + e.getMessage());
        }
    }

    /** Lô còn ACTIVE/đã QUARANTINE, còn hạn, cận hạn <=60 ngày — chưa có task mở nào. */
    private void scanExpiringBatches() throws Exception {
        String sql = "SELECT b.BatchID, b.BatchNumber, b.ExpiryDate, b.Status, m.MedicineName " +
                "FROM Batches b JOIN Medicines m ON m.MedicineID = b.MedicineID " +
                "WHERE b.Status IN ('ACTIVE','QUARANTINE') " +
                "AND b.ExpiryDate <= DATEADD(day, 60, GETDATE()) AND b.ExpiryDate > CAST(GETDATE() AS DATE)";
        int created = 0;
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                int batchId = rs.getInt("BatchID");
                if (taskDAO.existsOpenTaskForRef("Batches", batchId)) continue;

                boolean quarantined = "QUARANTINE".equals(rs.getString("Status"));
                String title = "Đã đến hạn kiểm định & dán tem off-price cho Lô " + rs.getString("BatchNumber")
                        + " (" + rs.getString("MedicineName") + ")";
                String desc = "Còn " + java.time.temporal.ChronoUnit.DAYS.between(
                        LocalDateTime.now(), rs.getTimestamp("ExpiryDate").toLocalDateTime()) + " ngày hết hạn.";
                taskDAO.insertSystemTask(title, desc, quarantined ? "HIGH" : "MEDIUM",
                        null, "Batches", batchId, null);
                created++;
            }
        }
        if (created > 0) log.info("[TaskAutoGen] Đã tạo " + created + " task hạn dùng");
    }

    /** PurchaseOrders do ReorderAlertService tự đề xuất (PENDING, Notes riêng) — chưa có task mở nào. */
    private void scanReorderSuggestions() throws Exception {
        String sql = "SELECT po.POID, m.MedicineName " +
                "FROM PurchaseOrders po " +
                "JOIN PurchaseOrderDetails d ON d.POID = po.POID " +
                "JOIN Medicines m ON m.MedicineID = d.MedicineID " +
                "WHERE po.Status = 'PENDING' AND po.Notes LIKE 'Tự động đề xuất bởi hệ thống%'";
        int created = 0;
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                int poId = rs.getInt("POID");
                if (taskDAO.existsOpenTaskForRef("PurchaseOrders", poId)) continue;

                String title = "Sản phẩm " + rs.getString("MedicineName")
                        + " đã chạm ngưỡng tồn an toàn (Safety Stock)";
                String desc = "Tiến hành đếm thực tế và duyệt phiếu đặt hàng đề xuất #" + poId + ".";
                taskDAO.insertSystemTask(title, desc, "MEDIUM", null, "PurchaseOrders", poId, null);
                created++;
            }
        }
        if (created > 0) log.info("[TaskAutoGen] Đã tạo " + created + " task ROP/gợi ý đặt hàng");
    }

    /** Ca vừa CLOSED trong 7 ngày gần đây, ClosingCash lệch quá 50.000đ so với kỳ vọng — giao cho chủ ca. */
    private void scanShiftCashDiscrepancy() throws Exception {
        String sql = "SELECT ShiftID, AccountID, OpeningCash, ClosingCash, StartTime " +
                "FROM Shifts WHERE Status = 'CLOSED' AND EndTime >= DATEADD(day, -7, GETDATE()) " +
                "AND ClosingCash IS NOT NULL";
        int created = 0;
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                int shiftId = rs.getInt("ShiftID");
                if (taskDAO.existsOpenTaskForRef("Shifts", shiftId)) continue;

                BigDecimal opening = rs.getBigDecimal("OpeningCash");
                BigDecimal closing = rs.getBigDecimal("ClosingCash");
                if (opening == null) opening = BigDecimal.ZERO;

                BigDecimal expected = opening.add(invoiceDAO.sumCashRevenueByShift(shiftId));
                BigDecimal diff = closing.subtract(expected);
                if (diff.abs().compareTo(CASH_TOLERANCE) <= 0) continue;

                int accountId = rs.getInt("AccountID");
                String dateLabel = rs.getTimestamp("StartTime").toLocalDateTime().toLocalDate().toString();
                String title = "Ca ngày " + dateLabel + " bị lệch " + formatMoney(diff) + "đ tiền mặt";
                String desc = "Tiến hành đối soát nhật ký hóa đơn của ca (kỳ vọng " + formatMoney(expected)
                        + "đ, thực đóng " + formatMoney(closing) + "đ).";
                taskDAO.insertSystemTask(title, desc, "HIGH", accountId, "Shifts", shiftId, null);
                created++;
            }
        }
        if (created > 0) log.info("[TaskAutoGen] Đã tạo " + created + " task lệch ca");
    }

    private String formatMoney(BigDecimal v) {
        return String.format("%,.0f", v).replace(',', '.');
    }
}
