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
        ensureExportTablesExist();
        List<ExportReason> list = new ArrayList<>();
        String sql = "SELECT * FROM ExportReasons WHERE IsActive = 1 ORDER BY ReasonID";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapReason(rs));
        } catch (Exception e) { e.printStackTrace(); }

        if (list.isEmpty()) {
            seedReasonsIfEmpty();
            try (Connection cn = DBContext.getConnection();
                 PreparedStatement ps = cn.prepareStatement(sql);
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapReason(rs));
            } catch (Exception e) { e.printStackTrace(); }
        }

        if (list.isEmpty()) {
            list = getDefaultFallbackReasons();
        }
        return list;
    }

    private synchronized void ensureExportTablesExist() {
        try (Connection cn = DBContext.getConnection()) {
            seedReasonsIfEmpty();

            String check1 = "SELECT COUNT(*) FROM sys.tables WHERE name = 'WarehouseExports'";
            boolean hasExports = false;
            try (PreparedStatement ps = cn.prepareStatement(check1); ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) hasExports = true;
            }
            if (!hasExports) {
                String createExports = "CREATE TABLE WarehouseExports (" +
                        "ExportID INT IDENTITY(1,1) PRIMARY KEY," +
                        "ReasonID INT NOT NULL," +
                        "Status VARCHAR(20) NOT NULL DEFAULT 'PENDING'," +
                        "Receiver NVARCHAR(255) NULL," +
                        "Notes NVARCHAR(500) NULL," +
                        "IsFefoOverridden BIT NOT NULL DEFAULT 0," +
                        "OverrideReason NVARCHAR(500) NULL," +
                        "OverrideBy INT NULL," +
                        "CreatedBy INT NOT NULL," +
                        "CreatedAt DATETIME NOT NULL DEFAULT GETDATE()," +
                        "ConfirmedAt DATETIME NULL" +
                        ")";
                try (PreparedStatement ps = cn.prepareStatement(createExports)) { ps.executeUpdate(); }
                try {
                    String altCode = "ALTER TABLE WarehouseExports ADD ExportCode AS ('PX' + RIGHT('00000' + CAST(ExportID AS VARCHAR(10)), 6))";
                    try (PreparedStatement ps = cn.prepareStatement(altCode)) { ps.executeUpdate(); }
                } catch (Exception ignored) {}
            }

            String check2 = "SELECT COUNT(*) FROM sys.tables WHERE name = 'WarehouseExportDetails'";
            boolean hasDetails = false;
            try (PreparedStatement ps = cn.prepareStatement(check2); ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) hasDetails = true;
            }
            if (!hasDetails) {
                String createDetails = "CREATE TABLE WarehouseExportDetails (" +
                        "ExportDetailID INT IDENTITY(1,1) PRIMARY KEY," +
                        "ExportID INT NOT NULL," +
                        "MedicineID INT NOT NULL," +
                        "BatchID INT NOT NULL," +
                        "RequestedQuantity INT NOT NULL," +
                        "AllocatedQuantity INT NOT NULL," +
                        "IsFefoOverridden BIT NOT NULL DEFAULT 0" +
                        ")";
                try (PreparedStatement ps = cn.prepareStatement(createDetails)) { ps.executeUpdate(); }
            }

            String check3 = "SELECT COUNT(*) FROM sys.tables WHERE name = 'ExportStatusHistory'";
            boolean hasHistory = false;
            try (PreparedStatement ps = cn.prepareStatement(check3); ResultSet rs = ps.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) hasHistory = true;
            }
            if (!hasHistory) {
                String createHistory = "CREATE TABLE ExportStatusHistory (" +
                        "HistoryID INT IDENTITY(1,1) PRIMARY KEY," +
                        "ExportID INT NOT NULL," +
                        "Status VARCHAR(20) NOT NULL," +
                        "AccountID INT NULL," +
                        "Notes NVARCHAR(500) NULL," +
                        "CreatedAt DATETIME NOT NULL DEFAULT GETDATE()" +
                        ")";
                try (PreparedStatement ps = cn.prepareStatement(createHistory)) { ps.executeUpdate(); }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void seedReasonsIfEmpty() {
        String checkSql = "SELECT COUNT(*) FROM sys.tables WHERE name = 'ExportReasons'";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(checkSql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next() && rs.getInt(1) == 0) {
                String createSql = "CREATE TABLE ExportReasons (" +
                        "ReasonID INT IDENTITY(1,1) PRIMARY KEY," +
                        "ReasonCode VARCHAR(30) NOT NULL," +
                        "ReasonName NVARCHAR(100) NOT NULL," +
                        "Description NVARCHAR(255) NULL," +
                        "RequiresReceiver BIT NOT NULL DEFAULT 0," +
                        "IsActive BIT NOT NULL DEFAULT 1" +
                        ")";
                try (PreparedStatement cps = cn.prepareStatement(createSql)) { cps.executeUpdate(); }
            }
        } catch (Exception ignored) {}

        // BUG THẬT (đã fix): hàm tên "IfEmpty" nhưng KHÔNG hề kiểm tra bảng đã có dữ liệu
        // chưa — INSERT chạy vô điều kiện mỗi lần gọi. Hàm này lại bị gọi từ
        // ensureExportTablesExist(), mà ensureExportTablesExist() chạy ở ĐẦU MỖI LẦN tải
        // trang Xuất kho (findReasons()) VÀ mỗi lần xác nhận phiếu xuất (confirmExport()) —
        // nghĩa là mỗi lần vào trang hoặc xuất kho thành công lại chèn thêm 7 dòng lý do
        // trùng lặp vào ExportReasons, dồn lại thành hàng chục/hàng trăm thẻ trùng y hệt
        // nhau hiển thị ở bước "Chọn loại xuất kho" (đúng hiện tượng trong ảnh báo lỗi).
        // Thêm guard COUNT(*) — chỉ seed khi bảng THẬT SỰ trống, đúng như tên hàm.
        try (Connection cn = DBContext.getConnection();
             PreparedStatement cps = cn.prepareStatement("SELECT COUNT(*) FROM ExportReasons");
             ResultSet crs = cps.executeQuery()) {
            if (crs.next() && crs.getInt(1) > 0) return; // đã có dữ liệu — không seed lại
        } catch (Exception ignored) {}

        String insertSql = "INSERT INTO ExportReasons (ReasonCode, ReasonName, Description, RequiresReceiver, IsActive) VALUES " +
                "('RETAIL_SALE', N'Bán lẻ (POS)', N'Xuất thuốc phục vụ bán hàng trực tiếp tại quầy POS', 0, 1)," +
                "('CUSTOMER_ORDER', N'Đơn hàng khách (Portal)', N'Xuất thuốc cho đơn hàng đặt qua Cổng khách hàng', 1, 1)," +
                "('TRANSFER', N'Chuyển kho / Điều chuyển', N'Xuất chuyển thuốc sang kho chi nhánh, tủ trực hoặc khoa phòng khác', 1, 1)," +
                "('RETURN_SUPPLIER', N'Trả nhà cung cấp', N'Xuất trả lại thuốc kém chất lượng, lỗi sản xuất hoặc cận hạn cho NCC', 1, 1)," +
                "('EXPIRED_DISPOSAL', N'Tiêu huỷ hết hạn', N'Xuất tiêu huỷ thuốc quá hạn sử dụng, biến chất hoặc nứt vỡ', 0, 1)," +
                "('INTERNAL_USAGE', N'Sử dụng nội bộ', N'Xuất dùng cho đào tạo, kiểm nghiệm, mẫu thử hoặc nghiên cứu nội bộ', 0, 1)," +
                "('ADJUSTMENT', N'Điều chỉnh tồn kho', N'Xuất cân bằng số lượng sau kỳ kiểm kê kho phát hiện chênh lệch', 0, 1)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(insertSql)) {
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }

    private List<ExportReason> getDefaultFallbackReasons() {
        List<ExportReason> list = new ArrayList<>();
        list.add(createReason(1, "RETAIL_SALE", "Bán lẻ (POS)", "Xuất thuốc phục vụ bán hàng trực tiếp tại quầy POS", false));
        list.add(createReason(2, "CUSTOMER_ORDER", "Đơn hàng khách (Portal)", "Xuất thuốc cho đơn hàng đặt qua Cổng khách hàng", true));
        list.add(createReason(3, "TRANSFER", "Chuyển kho / Điều chuyển", "Xuất chuyển thuốc sang kho chi nhánh, tủ trực hoặc khoa phòng khác", true));
        list.add(createReason(4, "RETURN_SUPPLIER", "Trả nhà cung cấp", "Xuất trả lại thuốc kém chất lượng, lỗi sản xuất hoặc cận hạn cho NCC", true));
        list.add(createReason(5, "EXPIRED_DISPOSAL", "Tiêu huỷ hết hạn", "Xuất tiêu huỷ thuốc quá hạn sử dụng, biến chất hoặc nứt vỡ", false));
        list.add(createReason(6, "INTERNAL_USAGE", "Sử dụng nội bộ", "Xuất dùng cho đào tạo, kiểm nghiệm, mẫu thử hoặc nghiên cứu nội bộ", false));
        list.add(createReason(7, "ADJUSTMENT", "Điều chỉnh tồn kho", "Xuất cân bằng số lượng sau kỳ kiểm kê kho phát hiện chênh lệch", false));
        return list;
    }

    private ExportReason createReason(int id, String code, String name, String desc, boolean reqRec) {
        ExportReason r = new ExportReason();
        r.setReasonId(id);
        r.setReasonCode(code);
        r.setReasonName(name);
        r.setDescription(desc);
        r.setRequiresReceiver(reqRec);
        r.setActive(true);
        return r;
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

        for (ExportReason r : getDefaultFallbackReasons()) {
            if (r.getReasonId() == reasonId) return r;
        }
        return null;
    }

    @Override
    public int confirmExport(WarehouseExport header, List<WarehouseExportDetail> lines, int accountId) {
        ensureExportTablesExist();
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
        String sql = "WITH bs AS (" +
                "  SELECT MedicineID, SUM(CurrentQuantity) AS TotalStock" +
                "  FROM Batches WHERE ExpiryDate > CAST(GETDATE() AS DATE) AND Status = 'ACTIVE'" +
                "  GROUP BY MedicineID" +
                ")," +
                "nb AS (" +
                "  SELECT MedicineID, ExpiryDate AS NearestExpiry, BatchNumber AS NearestBatchNo," +
                "         ROW_NUMBER() OVER (PARTITION BY MedicineID ORDER BY ExpiryDate ASC) AS rn" +
                "  FROM Batches" +
                "  WHERE CurrentQuantity > 0 AND ExpiryDate > CAST(GETDATE() AS DATE) AND Status = 'ACTIVE'" +
                ") " +
                "SELECT m.*, ISNULL(bs.TotalStock,0) AS TotalStock," +
                "  CONVERT(VARCHAR(10), nb.NearestExpiry, 120) AS NearestExpiry," +
                "  nb.NearestBatchNo," +
                "  c.CategoryName, mf.Name AS ManufacturerName, s.ShelfName " +
                "FROM Medicines m JOIN (" +
                "  SELECT TOP (?) d.MedicineID, MAX(e.CreatedAt) AS LastAt " +
                "  FROM WarehouseExportDetails d JOIN WarehouseExports e ON e.ExportID = d.ExportID " +
                "  GROUP BY d.MedicineID ORDER BY MAX(e.CreatedAt) DESC" +
                ") recent ON recent.MedicineID = m.MedicineID " +
                "LEFT JOIN bs ON bs.MedicineID = m.MedicineID " +
                "LEFT JOIN nb ON nb.MedicineID = m.MedicineID AND nb.rn = 1 " +
                "LEFT JOIN Categories c ON c.CategoryID = m.CategoryID " +
                "LEFT JOIN Manufacturers mf ON mf.ManufacturerID = m.ManufacturerID " +
                "LEFT JOIN Shelves s ON s.ShelfID = m.ShelfID " +
                "ORDER BY recent.LastAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            MedicineDAO mDao = new MedicineDAO();
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mDao.mapRowWithStock(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }
}
