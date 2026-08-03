package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IWarehouseExportDAO;
import com.medicare.entity.ExportReason;
import com.medicare.entity.ExportStatusHistory;
import com.medicare.entity.Medicines;
import com.medicare.entity.WarehouseExport;
import com.medicare.entity.WarehouseExportDetail;

import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * WarehouseExportDAO — chứng từ Xuất kho. {@link #confirmExport} và {@link #reverseExport} là
 * 2 điểm ghi TRANSACTION duy nhất chạm vào tồn kho, cấu trúc giống hệt
 * {@code PurchaseOrderDAO.createWithBatches()}/{@code confirmReceived()}: 1 Connection dùng
 * chung cho mọi câu lệnh, autoCommit(false), commit/rollback thủ công.
 *
 * QUAN TRỌNG: việc trừ/cộng Batches.CurrentQuantity và ghi StockMovements được VIẾT THẲNG SQL
 * trong lớp này (không gọi BatchesDAO/StockMovementsDAO) — 2 DAO đó tự mở Connection riêng nên
 * gọi chúng ở đây sẽ PHÁ vỡ tính transaction (đúng cách InvoiceDAO.completeSaleTransaction() đã
 * làm khi gọi SP_AddSaleByFEFO trên cùng 1 Connection).
 */
public class WarehouseExportDAO implements IWarehouseExportDAO {

    private final ThreadLocal<String> lastConfirmError = new ThreadLocal<>();

    /** Lý do thất bại của lần gọi confirmExport()/reverseExport() gần nhất trên THREAD HIỆN TẠI. */
    public String getLastConfirmError() { return lastConfirmError.get(); }

    // ══════════════════════════════════════════════════════════════════════
    //  MAPPERS
    // ══════════════════════════════════════════════════════════════════════

    private ExportReason mapReason(ResultSet rs) throws SQLException {
        ExportReason r = new ExportReason();
        r.setReasonId(rs.getInt("ReasonID"));
        r.setReasonCode(rs.getString("ReasonCode"));
        r.setReasonName(rs.getString("ReasonName"));
        r.setDescription(rs.getString("Description"));
        r.setRequiresReceiver(rs.getBoolean("RequiresReceiver"));
        r.setActive(rs.getBoolean("IsActive"));
        return r;
    }

    private WarehouseExport mapExport(ResultSet rs) throws SQLException {
        WarehouseExport e = new WarehouseExport();
        e.setExportId(rs.getInt("ExportID"));
        e.setExportCode(rs.getString("ExportCode"));
        e.setReasonId(rs.getInt("ReasonID"));
        e.setStatus(rs.getString("Status"));
        e.setReceiver(rs.getString("Receiver"));
        e.setNotes(rs.getString("Notes"));
        e.setFefoOverridden(rs.getBoolean("IsFefoOverridden"));
        e.setOverrideReason(rs.getString("OverrideReason"));
        e.setOverrideBy((Integer) rs.getObject("OverrideBy"));
        e.setCreatedBy(rs.getInt("CreatedBy"));
        if (rs.getTimestamp("CreatedAt") != null) e.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
        if (rs.getTimestamp("ConfirmedAt") != null) e.setConfirmedAt(rs.getTimestamp("ConfirmedAt").toLocalDateTime());
        try { e.setReasonName(rs.getString("ReasonName")); } catch (SQLException ignored) {}
        try { e.setReasonCode(rs.getString("ReasonCode")); } catch (SQLException ignored) {}
        try { e.setCreatedByName(rs.getString("CreatedByName")); } catch (SQLException ignored) {}
        return e;
    }

    private WarehouseExportDetail mapDetail(ResultSet rs) throws SQLException {
        WarehouseExportDetail d = new WarehouseExportDetail();
        d.setExportDetailId(rs.getInt("ExportDetailID"));
        d.setExportId(rs.getInt("ExportID"));
        d.setMedicineId(rs.getInt("MedicineID"));
        d.setBatchId(rs.getInt("BatchID"));
        d.setRequestedQuantity(rs.getInt("RequestedQuantity"));
        d.setAllocatedQuantity(rs.getInt("AllocatedQuantity"));
        d.setFefoOverridden(rs.getBoolean("IsFefoOverridden"));
        try { d.setMedicineName(rs.getString("MedicineName")); } catch (SQLException ignored) {}
        try { d.setMedicineCode(rs.getString("MedicineCode")); } catch (SQLException ignored) {}
        try { d.setBarcode(rs.getString("Barcode")); } catch (SQLException ignored) {}
        try { d.setBatchNumber(rs.getString("BatchNumber")); } catch (SQLException ignored) {}
        try {
            Date exp = rs.getDate("ExpiryDate");
            if (exp != null) d.setExpiryDate(exp.toLocalDate());
        } catch (SQLException ignored) {}
        return d;
    }

    private ExportStatusHistory mapHistory(ResultSet rs) throws SQLException {
        ExportStatusHistory h = new ExportStatusHistory();
        h.setHistoryId(rs.getInt("HistoryID"));
        h.setExportId(rs.getInt("ExportID"));
        h.setStatus(rs.getString("Status"));
        h.setAccountId((Integer) rs.getObject("AccountID"));
        h.setNotes(rs.getString("Notes"));
        if (rs.getTimestamp("CreatedAt") != null) h.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
        try { h.setAccountName(rs.getString("AccountName")); } catch (SQLException ignored) {}
        return h;
    }

    private Medicines mapMedicineLite(ResultSet rs) throws SQLException {
        Medicines m = new Medicines();
        m.setMedicineId(rs.getInt("MedicineID"));
        m.setMedicineCode(rs.getString("MedicineCode"));
        m.setMedicineName(rs.getString("MedicineName"));
        m.setBarcode(rs.getString("Barcode"));
        m.setUnit(rs.getString("Unit"));
        m.setSellingPrice(rs.getBigDecimal("SellingPrice"));
        return m;
    }

    // ══════════════════════════════════════════════════════════════════════
    //  ExportReasons
    // ══════════════════════════════════════════════════════════════════════

    @Override
    public List<ExportReason> findReasons() {
        List<ExportReason> list = new ArrayList<>();
        String sql = "SELECT * FROM ExportReasons WHERE IsActive = 1 ORDER BY ReasonID";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapReason(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public ExportReason findReasonById(int reasonId) {
        String sql = "SELECT * FROM ExportReasons WHERE ReasonID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, reasonId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapReason(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Confirm — điểm ghi transaction duy nhất chạm tồn kho theo chiều XUẤT
    // ══════════════════════════════════════════════════════════════════════

    @Override
    public int confirmExport(WarehouseExport header, List<WarehouseExportDetail> lines, int accountId) {
        lastConfirmError.remove();
        if (lines == null || lines.isEmpty()) {
            lastConfirmError.set("Phiếu xuất kho không có dòng thuốc nào.");
            return -1;
        }

        String headerSql = "INSERT INTO WarehouseExports " +
                "(ReasonID, Status, Receiver, Notes, IsFefoOverridden, OverrideReason, OverrideBy, CreatedBy, CreatedAt, ConfirmedAt) " +
                "VALUES (?, 'CONFIRMED', ?, ?, ?, ?, ?, ?, GETDATE(), GETDATE()); SELECT SCOPE_IDENTITY();";
        String detailSql = "INSERT INTO WarehouseExportDetails " +
                "(ExportID, MedicineID, BatchID, RequestedQuantity, AllocatedQuantity, IsFefoOverridden) VALUES (?,?,?,?,?,?)";
        String adjustSql = "UPDATE Batches SET CurrentQuantity = CurrentQuantity - ? " +
                "WHERE BatchID = ? AND CurrentQuantity - ? >= 0";
        String movementSql = "INSERT INTO StockMovements (BatchID, MovementType, Quantity, RefTable, RefID, AccountID, Notes) " +
                "VALUES (?, 'OUT', ?, 'WarehouseExports', ?, ?, ?)";
        String historySql = "INSERT INTO ExportStatusHistory (ExportID, Status, AccountID, Notes) VALUES (?, 'CONFIRMED', ?, ?)";

        Connection cn = null;
        try {
            cn = DBContext.getConnection();
            cn.setAutoCommit(false);

            int exportId;
            try (PreparedStatement ps = cn.prepareStatement(headerSql)) {
                ps.setInt(1, header.getReasonId());
                ps.setNString(2, header.getReceiver());
                ps.setNString(3, header.getNotes());
                ps.setBoolean(4, header.isFefoOverridden());
                ps.setNString(5, header.getOverrideReason());
                if (header.getOverrideBy() != null) ps.setInt(6, header.getOverrideBy()); else ps.setNull(6, Types.INTEGER);
                ps.setInt(7, accountId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next() || rs.getBigDecimal(1) == null) {
                        cn.rollback();
                        lastConfirmError.set("Không tạo được phiếu xuất kho.");
                        return -1;
                    }
                    exportId = rs.getBigDecimal(1).intValue();
                }
            }

            try (PreparedStatement dPs = cn.prepareStatement(detailSql);
                 PreparedStatement aPs = cn.prepareStatement(adjustSql);
                 PreparedStatement mPs = cn.prepareStatement(movementSql)) {
                for (WarehouseExportDetail line : lines) {
                    dPs.setInt(1, exportId);
                    dPs.setInt(2, line.getMedicineId());
                    dPs.setInt(3, line.getBatchId());
                    dPs.setInt(4, line.getRequestedQuantity());
                    dPs.setInt(5, line.getAllocatedQuantity());
                    dPs.setBoolean(6, line.isFefoOverridden());
                    dPs.executeUpdate();

                    aPs.setInt(1, line.getAllocatedQuantity());
                    aPs.setInt(2, line.getBatchId());
                    aPs.setInt(3, line.getAllocatedQuantity());
                    int rows = aPs.executeUpdate();
                    if (rows == 0) {
                        cn.rollback();
                        lastConfirmError.set("Lô #" + line.getBatchId() + " không còn đủ tồn kho — có thể đã bị người khác xuất trước. Vui lòng làm lại từ Bước 3.");
                        return -1;
                    }

                    mPs.setInt(1, line.getBatchId());
                    mPs.setInt(2, line.getAllocatedQuantity());
                    mPs.setInt(3, exportId);
                    mPs.setInt(4, accountId);
                    mPs.setNString(5, "Xuất kho " + (header.getNotes() != null ? header.getNotes() : ""));
                    mPs.executeUpdate();
                }
            }

            try (PreparedStatement hPs = cn.prepareStatement(historySql)) {
                hPs.setInt(1, exportId);
                hPs.setInt(2, accountId);
                hPs.setNString(3, "Tạo và xác nhận phiếu xuất kho");
                hPs.executeUpdate();
            }

            cn.commit();
            return exportId;
        } catch (Exception e) {
            String errMsg = e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName();
            lastConfirmError.set(errMsg);
            System.err.println("[WarehouseExportDAO] confirmExport thất bại: " + errMsg);
            e.printStackTrace();
            if (cn != null) try { cn.rollback(); } catch (Exception ignored) {}
            return -1;
        } finally {
            if (cn != null) try { cn.setAutoCommit(true); cn.close(); } catch (Exception ignored) {}
        }
    }

    @Override
    public boolean cancelExport(int exportId, int accountId, String reason) {
        lastConfirmError.remove();
        Connection cn = null;
        try {
            cn = DBContext.getConnection();
            cn.setAutoCommit(false);

            try (PreparedStatement ps = cn.prepareStatement(
                    "UPDATE WarehouseExports SET Status = 'CANCELLED' WHERE ExportID = ? AND Status = 'PENDING'")) {
                ps.setInt(1, exportId);
                if (ps.executeUpdate() == 0) {
                    cn.rollback();
                    lastConfirmError.set("Phiếu không tồn tại hoặc đã được xác nhận/huỷ trước đó.");
                    return false;
                }
            }
            try (PreparedStatement ps = cn.prepareStatement(
                    "INSERT INTO ExportStatusHistory (ExportID, Status, AccountID, Notes) VALUES (?, 'CANCELLED', ?, ?)")) {
                ps.setInt(1, exportId);
                ps.setInt(2, accountId);
                ps.setNString(3, reason);
                ps.executeUpdate();
            }
            cn.commit();
            return true;
        } catch (Exception e) {
            lastConfirmError.set(e.getMessage());
            e.printStackTrace();
            if (cn != null) try { cn.rollback(); } catch (Exception ignored) {}
            return false;
        } finally {
            if (cn != null) try { cn.setAutoCommit(true); cn.close(); } catch (Exception ignored) {}
        }
    }

    @Override
    public boolean reverseExport(int exportId, int accountId, String reason) {
        lastConfirmError.remove();
        Connection cn = null;
        try {
            cn = DBContext.getConnection();
            cn.setAutoCommit(false);

            try (PreparedStatement ps = cn.prepareStatement(
                    "SELECT 1 FROM WarehouseExports WHERE ExportID = ? AND Status = 'CONFIRMED'")) {
                ps.setInt(1, exportId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        cn.rollback();
                        lastConfirmError.set("Chỉ hoàn trả được phiếu đang ở trạng thái Đã xác nhận.");
                        return false;
                    }
                }
            }

            List<WarehouseExportDetail> lines = new ArrayList<>();
            try (PreparedStatement ps = cn.prepareStatement(
                    "SELECT * FROM WarehouseExportDetails WHERE ExportID = ?")) {
                ps.setInt(1, exportId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) lines.add(mapDetail(rs));
                }
            }
            if (lines.isEmpty()) {
                cn.rollback();
                lastConfirmError.set("Phiếu không có dòng thuốc nào để hoàn trả.");
                return false;
            }

            try (PreparedStatement aPs = cn.prepareStatement(
                    "UPDATE Batches SET CurrentQuantity = CurrentQuantity + ? WHERE BatchID = ?");
                 PreparedStatement mPs = cn.prepareStatement(
                    "INSERT INTO StockMovements (BatchID, MovementType, Quantity, RefTable, RefID, AccountID, Notes) " +
                    "VALUES (?, 'IN', ?, 'WarehouseExports', ?, ?, ?)")) {
                for (WarehouseExportDetail line : lines) {
                    aPs.setInt(1, line.getAllocatedQuantity());
                    aPs.setInt(2, line.getBatchId());
                    aPs.executeUpdate();

                    mPs.setInt(1, line.getBatchId());
                    mPs.setInt(2, line.getAllocatedQuantity());
                    mPs.setInt(3, exportId);
                    mPs.setInt(4, accountId);
                    mPs.setNString(5, "Hoàn trả phiếu xuất kho — " + (reason != null ? reason : ""));
                    mPs.executeUpdate();
                }
            }

            try (PreparedStatement ps = cn.prepareStatement(
                    "UPDATE WarehouseExports SET Status = 'REVERSED' WHERE ExportID = ?")) {
                ps.setInt(1, exportId);
                ps.executeUpdate();
            }
            try (PreparedStatement ps = cn.prepareStatement(
                    "INSERT INTO ExportStatusHistory (ExportID, Status, AccountID, Notes) VALUES (?, 'REVERSED', ?, ?)")) {
                ps.setInt(1, exportId);
                ps.setInt(2, accountId);
                ps.setNString(3, reason);
                ps.executeUpdate();
            }

            cn.commit();
            return true;
        } catch (Exception e) {
            String errMsg = e.getMessage() != null ? e.getMessage() : e.getClass().getSimpleName();
            lastConfirmError.set(errMsg);
            System.err.println("[WarehouseExportDAO] reverseExport thất bại: " + errMsg);
            e.printStackTrace();
            if (cn != null) try { cn.rollback(); } catch (Exception ignored) {}
            return false;
        } finally {
            if (cn != null) try { cn.setAutoCommit(true); cn.close(); } catch (Exception ignored) {}
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    //  Queries
    // ══════════════════════════════════════════════════════════════════════

    private static final String EXPORT_JOIN_SQL =
            "SELECT e.*, r.ReasonName, r.ReasonCode, a.FullName AS CreatedByName " +
            "FROM WarehouseExports e " +
            "JOIN ExportReasons r ON r.ReasonID = e.ReasonID " +
            "LEFT JOIN Accounts a ON a.AccountID = e.CreatedBy ";

    @Override
    public WarehouseExport findById(int exportId) {
        String sql = EXPORT_JOIN_SQL + "WHERE e.ExportID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, exportId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapExport(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    @Override
    public List<WarehouseExportDetail> findDetails(int exportId) {
        List<WarehouseExportDetail> list = new ArrayList<>();
        String sql = "SELECT d.*, m.MedicineName, m.MedicineCode, m.Barcode, b.BatchNumber, b.ExpiryDate " +
                "FROM WarehouseExportDetails d " +
                "JOIN Medicines m ON m.MedicineID = d.MedicineID " +
                "JOIN Batches b ON b.BatchID = d.BatchID " +
                "WHERE d.ExportID = ? ORDER BY d.ExportDetailID";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, exportId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapDetail(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<ExportStatusHistory> findHistory(int exportId) {
        List<ExportStatusHistory> list = new ArrayList<>();
        String sql = "SELECT h.*, a.FullName AS AccountName FROM ExportStatusHistory h " +
                "LEFT JOIN Accounts a ON a.AccountID = h.AccountID " +
                "WHERE h.ExportID = ? ORDER BY h.CreatedAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, exportId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapHistory(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<WarehouseExport> findPaged(String status, LocalDate from, LocalDate to, String keyword, int page, int pageSize) {
        List<WarehouseExport> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder(EXPORT_JOIN_SQL + "WHERE 1=1 ");
        List<Object> params = new ArrayList<>();
        if (status != null && !status.trim().isEmpty()) {
            sql.append("AND e.Status = ? ");
            params.add(status.trim());
        }
        if (from != null) {
            sql.append("AND e.CreatedAt >= ? ");
            params.add(Date.valueOf(from));
        }
        if (to != null) {
            sql.append("AND e.CreatedAt < ? ");
            params.add(Date.valueOf(to.plusDays(1)));
        }
        if (keyword != null && !keyword.trim().isEmpty()) {
            sql.append("AND (e.ExportCode LIKE ? OR e.Receiver LIKE ? OR a.FullName LIKE ?) ");
            String kw = "%" + keyword.trim() + "%";
            params.add(kw); params.add(kw); params.add(kw);
        }
        sql.append("ORDER BY e.CreatedAt DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");
        int offset = Math.max(0, (page - 1) * pageSize);

        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql.toString())) {
            int i = 1;
            for (Object p : params) {
                if (p instanceof Date) ps.setDate(i++, (Date) p);
                else ps.setNString(i++, (String) p);
            }
            ps.setInt(i++, offset);
            ps.setInt(i, pageSize);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapExport(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public int countByStatus(String status) {
        String sql = "SELECT COUNT(*) FROM WarehouseExports WHERE Status = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, status);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    @Override
    public int countCompletedToday() {
        String sql = "SELECT COUNT(*) FROM WarehouseExports " +
                "WHERE Status = 'CONFIRMED' AND CAST(ConfirmedAt AS DATE) = CAST(GETDATE() AS DATE)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    @Override
    public int countDistinctMedicinesToday() {
        String sql = "SELECT COUNT(DISTINCT d.MedicineID) FROM WarehouseExportDetails d " +
                "JOIN WarehouseExports e ON e.ExportID = d.ExportID " +
                "WHERE e.Status = 'CONFIRMED' AND CAST(e.ConfirmedAt AS DATE) = CAST(GETDATE() AS DATE)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    @Override
    public int countNearExpiryLotsToday() {
        String sql = "SELECT COUNT(DISTINCT d.BatchID) FROM WarehouseExportDetails d " +
                "JOIN WarehouseExports e ON e.ExportID = d.ExportID " +
                "JOIN Batches b ON b.BatchID = d.BatchID " +
                "JOIN Medicines m ON m.MedicineID = d.MedicineID " +
                "WHERE e.Status = 'CONFIRMED' AND CAST(e.ConfirmedAt AS DATE) = CAST(GETDATE() AS DATE) " +
                "AND b.ExpiryDate <= DATEADD(DAY, m.ExpiryAlertDays, GETDATE())";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    @Override
    public List<Medicines> findRecentMedicines(int limit) {
        List<Medicines> list = new ArrayList<>();
        String sql = "SELECT m.MedicineID, m.MedicineCode, m.MedicineName, m.Barcode, m.Unit, m.SellingPrice " +
                "FROM Medicines m JOIN (" +
                "  SELECT TOP (?) d.MedicineID, MAX(e.CreatedAt) AS LastAt " +
                "  FROM WarehouseExportDetails d JOIN WarehouseExports e ON e.ExportID = d.ExportID " +
                "  GROUP BY d.MedicineID ORDER BY MAX(e.CreatedAt) DESC" +
                ") recent ON recent.MedicineID = m.MedicineID " +
                "ORDER BY recent.LastAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapMedicineLite(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }
}
