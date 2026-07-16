package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IInvoiceDAO;
import com.medicare.entity.Invoice;
import java.math.BigDecimal;
import java.sql.*;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * InvoiceDAO — Quản lý hóa đơn bán hàng
 *
 * Flow bán hàng chuẩn:
 *   1. createPending()       → tạo hóa đơn PENDING
 *   2. addItemByFIFO()       → gọi SP_AddSaleByFEFO cho từng thuốc (trừ kho theo HSD gần nhất trước)
 *   3. complete()            → chốt hóa đơn COMPLETED + tính tiền
 *   4. (nếu lỗi) cancel()   → hủy hóa đơn CANCELLED
 */
public class InvoiceDAO implements IInvoiceDAO {

    private Invoice mapRow(ResultSet rs) throws SQLException {
        Invoice inv = new Invoice();
        inv.setInvoiceId(rs.getInt("InvoiceID"));
        inv.setInvoiceCode(rs.getString("InvoiceCode"));
        inv.setAccountId(rs.getInt("AccountID"));
        inv.setShiftId((Integer) rs.getObject("ShiftID"));
        inv.setCustomerId((Integer) rs.getObject("CustomerID"));
        inv.setPrescriptionId((Integer) rs.getObject("PrescriptionID"));
        inv.setFinalAmount(rs.getBigDecimal("FinalAmount"));
        inv.setDiscountAmount(rs.getBigDecimal("DiscountAmount"));
        inv.setPaymentMethod(rs.getString("PaymentMethod"));
        inv.setStatus(rs.getString("Status"));
        if (rs.getTimestamp("CreatedAt") != null)
            inv.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
        try { inv.setPosStation((Integer) rs.getObject("PosStation")); } catch (SQLException ignored) {}
        return inv;
    }

    // ================================================================
    // FLOW BÁN HÀNG — gọi theo thứ tự
    // ================================================================

    /**
     * Bước 1: Tạo hóa đơn trạng thái PENDING.
     * Trả về InvoiceID vừa tạo, -1 nếu lỗi.
     */
    public int createPending(int accountId, Integer shiftId,
                             Integer customerId, Integer prescriptionId,
                             String paymentMethod) {
        String sql = "INSERT INTO Invoices (AccountID, ShiftID, CustomerID, PrescriptionID, PaymentMethod) " +
                "VALUES (?,?,?,?,?); SELECT SCOPE_IDENTITY();";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            if (shiftId != null) ps.setInt(2, shiftId); else ps.setNull(2, Types.INTEGER);
            if (customerId != null) ps.setInt(3, customerId); else ps.setNull(3, Types.INTEGER);
            if (prescriptionId != null) ps.setInt(4, prescriptionId); else ps.setNull(4, Types.INTEGER);
            ps.setString(5, paymentMethod != null ? paymentMethod : "CASH");
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return -1;
    }

    /**
     * Bước 2: Thêm 1 loại thuốc vào hóa đơn theo FEFO (First Expire, First Out).
     * Gọi Stored Procedure SP_AddSaleByFEFO trong DB.
     * SP tự chọn lô có HSD gần nhất trước (không phải lô nhập trước) → trừ kho → tạo InvoiceDetail.
     */
    public boolean addItemByFIFO(int invoiceId, int medicineId, int quantity) {
        try (Connection cn = DBContext.getConnection();
             CallableStatement cs = cn.prepareCall("{CALL SP_AddSaleByFEFO(?, ?, ?)}")) {
            cs.setInt(1, invoiceId);
            cs.setInt(2, medicineId);
            cs.setInt(3, quantity);
            cs.execute();
            return true;
        } catch (Exception e) {
            // SP sẽ ném lỗi "Khong du ton kho" nếu thiếu hàng
            System.err.println("[InvoiceDAO] addItemByFIFO lỗi: " + e.getMessage());
            return false;
        }
    }

    /**
     * Bước 3: Chốt hóa đơn → COMPLETED.
     * Tính FinalAmount = tổng SubTotal - discount.
     */
    public boolean complete(int invoiceId, BigDecimal discountAmount) {
        String sql = "UPDATE Invoices SET " +
                "  Status = 'COMPLETED', " +
                "  DiscountAmount = ?, " +
                "  FinalAmount = (" +
                "      SELECT ISNULL(SUM(SubTotal), 0) FROM InvoiceDetails WHERE InvoiceID = ?" +
                "  ) - ? " +
                "WHERE InvoiceID = ? AND Status = 'PENDING'";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            BigDecimal disc = discountAmount != null ? discountAmount : BigDecimal.ZERO;
            ps.setBigDecimal(1, disc);
            ps.setInt(2, invoiceId);
            ps.setBigDecimal(3, disc);
            ps.setInt(4, invoiceId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /**
     * Hủy hóa đơn → CANCELLED (khi có lỗi hoặc khách đổi ý).
     */
    public boolean cancel(int invoiceId) {
        String sql = "UPDATE Invoices SET Status = 'CANCELLED' " +
                "WHERE InvoiceID = ? AND Status = 'PENDING'";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, invoiceId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // ================================================================
    // TRUY VẤN
    // ================================================================

    public Invoice findById(int id) {
        String sql = "SELECT * FROM Invoices WHERE InvoiceID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    public Invoice findByCode(String invoiceCode) {
        String sql = "SELECT * FROM Invoices WHERE InvoiceCode = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, invoiceCode);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    public List<Invoice> findByShift(int shiftId) {
        List<Invoice> list = new ArrayList<>();
        String sql = "SELECT * FROM Invoices WHERE ShiftID = ? AND Status = 'COMPLETED' " +
                "ORDER BY CreatedAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, shiftId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public List<Invoice> findByCustomer(int customerId) {
        List<Invoice> list = new ArrayList<>();
        String sql = "SELECT * FROM Invoices WHERE CustomerID = ? AND Status = 'COMPLETED' " +
                "ORDER BY CreatedAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, customerId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public List<Invoice> findByDateRange(LocalDate from, LocalDate to) {
        List<Invoice> list = new ArrayList<>();
        String sql = "SELECT * FROM Invoices " +
                "WHERE Status = 'COMPLETED' " +
                "  AND CAST(CreatedAt AS DATE) BETWEEN ? AND ? " +
                "ORDER BY CreatedAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(from));
            ps.setDate(2, Date.valueOf(to));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    // Doanh thu trong khoảng ngày — dùng cho ReportServlet
    public BigDecimal sumRevenueByDateRange(LocalDate from, LocalDate to) {
        String sql = "SELECT ISNULL(SUM(FinalAmount), 0) FROM Invoices " +
                "WHERE Status = 'COMPLETED' AND CAST(CreatedAt AS DATE) BETWEEN ? AND ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(from));
            ps.setDate(2, Date.valueOf(to));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getBigDecimal(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return BigDecimal.ZERO;
    }
    /**
     * Flow bán hàng trong 1 transaction duy nhất.
     * createPending → addItemByFIFO × N → complete
     * Nếu lỗi ở bất kỳ bước nào → rollback toàn bộ → không có dữ liệu lửng.
     *
     * @param shiftId  Ca làm việc hiện tại (null nếu không có ca đang mở)
     * @return invoiceId nếu thành công, -1 nếu lỗi
     */
    // ThreadLocal — InvoiceDAO được servlet giữ như 1 instance dùng chung cho MỌI request
    // (xem PosServlet/SaleService: `private final ... = new InvoiceDAO()`), nên KHÔNG được
    // dùng field thường ở đây: 2 nhân viên bán hàng ở 2 quầy POS thanh toán cùng lúc sẽ ghi
    // đè lỗi của nhau. ThreadLocal đảm bảo mỗi thread (mỗi request) có bản riêng.
    private final ThreadLocal<String> lastSaleError = new ThreadLocal<>();

    public String getLastSaleError() { return lastSaleError.get(); }

    public int completeSaleTransaction(int accountId, Integer shiftId, Integer customerId,
                                       String paymentMethod, java.math.BigDecimal discount,
                                       int[] medicineIds, int[] quantities) {
        lastSaleError.remove();
        Connection cn = null;
        try {
            cn = DBContext.getConnection();
            cn.setAutoCommit(false);

            // Bước 1: Tạo Invoice PENDING — bao gồm ShiftID
            int invoiceId;
            String sqlInsert = "INSERT INTO Invoices (AccountID, ShiftID, CustomerID, PaymentMethod) " +
                    "VALUES (?,?,?,?)";
            try (PreparedStatement ps = cn.prepareStatement(sqlInsert, Statement.RETURN_GENERATED_KEYS)) {
                ps.setInt(1, accountId);
                if (shiftId != null) ps.setInt(2, shiftId); else ps.setNull(2, Types.INTEGER);
                if (customerId != null) ps.setInt(3, customerId); else ps.setNull(3, Types.INTEGER);
                ps.setString(4, paymentMethod != null ? paymentMethod : "CASH");
                ps.executeUpdate();
                try (ResultSet keys = ps.getGeneratedKeys()) {
                    if (keys.next()) invoiceId = keys.getInt(1);
                    else throw new Exception("Không lấy được InvoiceID sau INSERT");
                }
            }
            if (invoiceId <= 0) throw new Exception("InvoiceID không hợp lệ: " + invoiceId);

            // Bước 2: Thêm từng sản phẩm qua SP (FEFO — hạn dùng gần nhất trước) — cùng connection, cùng transaction
            for (int i = 0; i < medicineIds.length; i++) {
                try (CallableStatement cs = cn.prepareCall("{CALL SP_AddSaleByFEFO(?, ?, ?)}")) {
                    cs.setInt(1, invoiceId);
                    cs.setInt(2, medicineIds[i]);
                    cs.setInt(3, quantities[i]);
                    cs.execute();
                } catch (SQLException spEx) {
                    throw new Exception("Thuốc ID " + medicineIds[i] + ": " + spEx.getMessage(), spEx);
                }
            }

            // Bước 3: Complete Invoice
            java.math.BigDecimal disc = discount != null ? discount : java.math.BigDecimal.ZERO;
            String sqlComplete = "UPDATE Invoices SET Status = 'COMPLETED', " +
                    "DiscountAmount = ?, " +
                    "FinalAmount = (SELECT ISNULL(SUM(SubTotal),0) FROM InvoiceDetails WHERE InvoiceID = ?) - ? " +
                    "WHERE InvoiceID = ? AND Status = 'PENDING'";
            try (PreparedStatement ps = cn.prepareStatement(sqlComplete)) {
                ps.setBigDecimal(1, disc);
                ps.setInt(2, invoiceId);
                ps.setBigDecimal(3, disc);
                ps.setInt(4, invoiceId);
                if (ps.executeUpdate() == 0) throw new Exception("Không complete được hóa đơn (ID=" + invoiceId + ")");
            }

            cn.commit();
            return invoiceId;

        } catch (Exception e) {
            lastSaleError.set(e.getMessage());
            System.err.println("[InvoiceDAO] completeSaleTransaction rollback: " + e.getMessage());
            e.printStackTrace();
            if (cn != null) {
                try { cn.rollback(); } catch (SQLException rb) { rb.printStackTrace(); }
            }
            return -1;
        } finally {
            if (cn != null) {
                try { cn.setAutoCommit(true); cn.close(); } catch (SQLException ex) { ex.printStackTrace(); }
            }
        }
    }

    // ── NEW ───────────────────────────────────────────────────────────────────

    /** Tổng doanh thu TIỀN MẶT trong ca — dùng để tự tính ClosingCash */
    @Override
    public BigDecimal sumCashRevenueByShift(int shiftId) {
        String sql = "SELECT ISNULL(SUM(FinalAmount), 0) FROM Invoices " +
                "WHERE ShiftID = ? AND PaymentMethod = 'CASH' AND Status = 'COMPLETED'";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, shiftId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getBigDecimal(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return BigDecimal.ZERO;
    }

    // ════════════════════════════════════════════════════════════
    //  BÁO CÁO DOANH THU — dùng cho ReportServlet (/reports)
    //  Lưu ý: CreatedAt được lưu theo GETDATE() của SQL Server (UTC trên server host),
    //  nên việc lọc theo ngày (CAST(...AS DATE)) giữ NGUYÊN quy ước hiện có của toàn hệ
    //  thống (giống InvoiceDAO.findByDateRange, ShiftDAO...) để không gây lệch dữ liệu
    //  so với các báo cáo khác. Riêng phần "doanh thu theo giờ" (revenueByHour) CẦN quy
    //  đổi +7h vì mục đích của nó là xác định khung giờ thực tế trong ngày VN.
    // ════════════════════════════════════════════════════════════

    @Override
    public BigDecimal sumGrossRevenueByDateRange(LocalDate from, LocalDate to) {
        String sql = "SELECT ISNULL(SUM(id.SubTotal), 0) " +
                "FROM InvoiceDetails id JOIN Invoices inv ON inv.InvoiceID = id.InvoiceID " +
                "WHERE inv.Status = 'COMPLETED' AND CAST(inv.CreatedAt AS DATE) BETWEEN ? AND ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(from));
            ps.setDate(2, Date.valueOf(to));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getBigDecimal(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return BigDecimal.ZERO;
    }

    @Override
    public BigDecimal sumCOGSByDateRange(LocalDate from, LocalDate to) {
        String sql = "SELECT ISNULL(SUM(id.Quantity * b.ImportPrice), 0) " +
                "FROM InvoiceDetails id " +
                "JOIN Invoices inv ON inv.InvoiceID = id.InvoiceID " +
                "JOIN Batches b    ON b.BatchID = id.BatchID " +
                "WHERE inv.Status = 'COMPLETED' AND CAST(inv.CreatedAt AS DATE) BETWEEN ? AND ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(from));
            ps.setDate(2, Date.valueOf(to));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getBigDecimal(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return BigDecimal.ZERO;
    }

    @Override
    public BigDecimal sumDiscountByDateRange(LocalDate from, LocalDate to) {
        String sql = "SELECT ISNULL(SUM(DiscountAmount), 0) FROM Invoices " +
                "WHERE Status = 'COMPLETED' AND CAST(CreatedAt AS DATE) BETWEEN ? AND ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(from));
            ps.setDate(2, Date.valueOf(to));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getBigDecimal(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return BigDecimal.ZERO;
    }

    @Override
    public BigDecimal sumRefundByDateRange(LocalDate from, LocalDate to) {
        // Từ 2026-06-19: đã có ReturnsServlet/ReturnsDAO ghi vào bảng Returns
        // (xem TRG_ProcessReturn) → số liệu này giờ phản ánh đúng giá trị thực.
        String sql = "SELECT ISNULL(SUM(r.Quantity * id.UnitPrice), 0) " +
                "FROM Returns r " +
                "JOIN InvoiceDetails id ON id.InvoiceID = r.InvoiceID AND id.BatchID = r.BatchID " +
                "WHERE r.ReturnType = 'CUSTOMER_RETURN' AND CAST(r.CreatedAt AS DATE) BETWEEN ? AND ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(from));
            ps.setDate(2, Date.valueOf(to));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getBigDecimal(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return BigDecimal.ZERO;
    }

    @Override
    public int countInvoicesByDateRange(LocalDate from, LocalDate to) {
        String sql = "SELECT COUNT(*) FROM Invoices " +
                "WHERE Status = 'COMPLETED' AND CAST(CreatedAt AS DATE) BETWEEN ? AND ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(from));
            ps.setDate(2, Date.valueOf(to));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    @Override
    public java.util.LinkedHashMap<String, BigDecimal> revenueByManufacturer(LocalDate from, LocalDate to) {
        java.util.LinkedHashMap<String, BigDecimal> result = new java.util.LinkedHashMap<>();
        String sql = "SELECT m.Name AS Label, SUM(id.SubTotal) AS Rev " +
                "FROM InvoiceDetails id " +
                "JOIN Invoices inv      ON inv.InvoiceID = id.InvoiceID " +
                "JOIN Batches b         ON b.BatchID = id.BatchID " +
                "JOIN Medicines me      ON me.MedicineID = b.MedicineID " +
                "JOIN Manufacturers m   ON m.ManufacturerID = me.ManufacturerID " +
                "WHERE inv.Status = 'COMPLETED' AND CAST(inv.CreatedAt AS DATE) BETWEEN ? AND ? " +
                "GROUP BY m.Name ORDER BY Rev DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(from));
            ps.setDate(2, Date.valueOf(to));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.put(rs.getString("Label"), rs.getBigDecimal("Rev"));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return result;
    }

    @Override
    public java.util.LinkedHashMap<String, BigDecimal> revenueByCategory(LocalDate from, LocalDate to) {
        java.util.LinkedHashMap<String, BigDecimal> result = new java.util.LinkedHashMap<>();
        String sql = "SELECT c.CategoryName AS Label, SUM(id.SubTotal) AS Rev " +
                "FROM InvoiceDetails id " +
                "JOIN Invoices inv   ON inv.InvoiceID = id.InvoiceID " +
                "JOIN Batches b      ON b.BatchID = id.BatchID " +
                "JOIN Medicines me   ON me.MedicineID = b.MedicineID " +
                "JOIN Categories c   ON c.CategoryID = me.CategoryID " +
                "WHERE inv.Status = 'COMPLETED' AND CAST(inv.CreatedAt AS DATE) BETWEEN ? AND ? " +
                "GROUP BY c.CategoryName ORDER BY Rev DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(from));
            ps.setDate(2, Date.valueOf(to));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.put(rs.getString("Label"), rs.getBigDecimal("Rev"));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return result;
    }

    @Override
    public java.util.TreeMap<Integer, BigDecimal> revenueByHour(LocalDate from, LocalDate to) {
        java.util.TreeMap<Integer, BigDecimal> result = new java.util.TreeMap<>();
        for (int h = 0; h < 24; h++) result.put(h, BigDecimal.ZERO); // luôn đủ 24 mốc giờ
        // +7h để quy đổi CreatedAt (UTC trên server) → giờ VN trước khi lấy khung giờ
        String sql = "SELECT DATEPART(HOUR, DATEADD(HOUR, 7, inv.CreatedAt)) AS Hr, " +
                "       SUM(inv.FinalAmount) AS Rev " +
                "FROM Invoices inv " +
                "WHERE inv.Status = 'COMPLETED' AND CAST(inv.CreatedAt AS DATE) BETWEEN ? AND ? " +
                "GROUP BY DATEPART(HOUR, DATEADD(HOUR, 7, inv.CreatedAt))";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(from));
            ps.setDate(2, Date.valueOf(to));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.put(rs.getInt("Hr"), rs.getBigDecimal("Rev"));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return result;
    }

    @Override
    public java.util.TreeMap<String, BigDecimal> dailyRevenueByDateRange(LocalDate from, LocalDate to) {
        java.util.TreeMap<String, BigDecimal> result = new java.util.TreeMap<>();
        String sql = "SELECT CAST(inv.CreatedAt AS DATE) AS Day, SUM(inv.FinalAmount) AS Rev " +
                "FROM Invoices inv " +
                "WHERE inv.Status = 'COMPLETED' AND CAST(inv.CreatedAt AS DATE) BETWEEN ? AND ? " +
                "GROUP BY CAST(inv.CreatedAt AS DATE) ORDER BY Day";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(from));
            ps.setDate(2, Date.valueOf(to));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.put(rs.getDate("Day").toString(), rs.getBigDecimal("Rev"));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return result;
    }

    @Override
    public java.util.TreeMap<String, BigDecimal[]> dailyFinanceByDateRange(LocalDate from, LocalDate to) {
        java.util.TreeMap<String, BigDecimal[]> result = new java.util.TreeMap<>();
        String sqlRev = "SELECT CAST(CreatedAt AS DATE) AS Day, ISNULL(SUM(FinalAmount),0) AS Rev FROM Invoices " +
                "WHERE Status = 'COMPLETED' AND CAST(CreatedAt AS DATE) BETWEEN ? AND ? " +
                "GROUP BY CAST(CreatedAt AS DATE)";
        String sqlCogs = "SELECT CAST(inv.CreatedAt AS DATE) AS Day, SUM(id.Quantity * b.ImportPrice) AS Cogs " +
                "FROM InvoiceDetails id " +
                "JOIN Invoices inv ON inv.InvoiceID = id.InvoiceID " +
                "JOIN Batches b    ON b.BatchID = id.BatchID " +
                "WHERE inv.Status = 'COMPLETED' AND CAST(inv.CreatedAt AS DATE) BETWEEN ? AND ? " +
                "GROUP BY CAST(inv.CreatedAt AS DATE)";
        try (Connection cn = DBContext.getConnection()) {
            try (PreparedStatement ps = cn.prepareStatement(sqlRev)) {
                ps.setDate(1, Date.valueOf(from));
                ps.setDate(2, Date.valueOf(to));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        String day = rs.getDate("Day").toString();
                        result.computeIfAbsent(day, k -> new BigDecimal[]{BigDecimal.ZERO, BigDecimal.ZERO})[0] = rs.getBigDecimal("Rev");
                    }
                }
            }
            try (PreparedStatement ps = cn.prepareStatement(sqlCogs)) {
                ps.setDate(1, Date.valueOf(from));
                ps.setDate(2, Date.valueOf(to));
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        String day = rs.getDate("Day").toString();
                        result.computeIfAbsent(day, k -> new BigDecimal[]{BigDecimal.ZERO, BigDecimal.ZERO})[1] = rs.getBigDecimal("Cogs");
                    }
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return result;
    }

    // ════════════════════════════════════════════════════════════
    //  DANH SÁCH HÓA ĐƠN (lọc + phân trang) — dùng cho InvoiceServlet (/invoices)
    // ════════════════════════════════════════════════════════════

    @Override
    public List<Invoice> findFiltered(LocalDate from, LocalDate to, String status, String paymentMethod,
                                      Integer accountId, String keyword, int page, int pageSize) {
        List<Invoice> list = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
                "SELECT inv.* FROM Invoices inv " +
                        "LEFT JOIN Customers c ON c.CustomerID = inv.CustomerID WHERE 1=1");
        List<Object> params = new ArrayList<>();
        appendInvoiceFilters(sql, params, from, to, status, paymentMethod, accountId, keyword);
        sql.append(" ORDER BY inv.CreatedAt DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");

        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql.toString())) {
            int idx = bindInvoiceParams(ps, params);
            int safePage = Math.max(page, 1);
            ps.setInt(idx++, (safePage - 1) * pageSize);
            ps.setInt(idx, pageSize);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public int countFiltered(LocalDate from, LocalDate to, String status, String paymentMethod,
                             Integer accountId, String keyword) {
        StringBuilder sql = new StringBuilder(
                "SELECT COUNT(*) FROM Invoices inv " +
                        "LEFT JOIN Customers c ON c.CustomerID = inv.CustomerID WHERE 1=1");
        List<Object> params = new ArrayList<>();
        appendInvoiceFilters(sql, params, from, to, status, paymentMethod, accountId, keyword);

        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql.toString())) {
            bindInvoiceParams(ps, params);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }

    /** Gắn các điều kiện lọc (tùy chọn) vào câu SQL + danh sách param theo đúng thứ tự "?". */
    private void appendInvoiceFilters(StringBuilder sql, List<Object> params,
                                      LocalDate from, LocalDate to, String status, String paymentMethod,
                                      Integer accountId, String keyword) {
        if (from != null && to != null) {
            sql.append(" AND CAST(inv.CreatedAt AS DATE) BETWEEN ? AND ?");
            params.add(Date.valueOf(from));
            params.add(Date.valueOf(to));
        }
        if (status != null && !status.isEmpty()) {
            sql.append(" AND inv.Status = ?");
            params.add(status);
        }
        if (paymentMethod != null && !paymentMethod.isEmpty()) {
            sql.append(" AND inv.PaymentMethod = ?");
            params.add(paymentMethod);
        }
        if (accountId != null) {
            sql.append(" AND inv.AccountID = ?");
            params.add(accountId);
        }
        if (keyword != null && !keyword.isBlank()) {
            sql.append(" AND (inv.InvoiceCode LIKE ? OR c.CustomerName LIKE ? OR c.Phone LIKE ?)");
            String kw = "%" + keyword.trim() + "%";
            params.add(kw); params.add(kw); params.add(kw);
        }
    }

    private int bindInvoiceParams(PreparedStatement ps, List<Object> params) throws SQLException {
        int idx = 1;
        for (Object p : params) ps.setObject(idx++, p);
        return idx;
    }

}