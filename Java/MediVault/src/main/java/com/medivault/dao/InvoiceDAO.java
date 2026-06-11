package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.dao.interfaces.IInvoiceDAO;
import com.medivault.entity.Invoice;
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
 *   2. addItemByFIFO()       → gọi SP_AddSaleByFIFO cho từng thuốc
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
     * Bước 2: Thêm 1 loại thuốc vào hóa đơn theo FIFO.
     * Gọi Stored Procedure SP_AddSaleByFIFO trong DB.
     * SP tự chọn lô cũ nhất → trừ kho → tạo InvoiceDetail → đẩy lệnh máy.
     */
    public boolean addItemByFIFO(int invoiceId, int medicineId, int quantity) {
        String sql = "EXEC SP_AddSaleByFIFO ?, ?, ?";
        try (Connection cn = DBContext.getConnection();
             CallableStatement cs = cn.prepareCall(sql)) {
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
     * @return invoiceId nếu thành công, -1 nếu lỗi
     */
    public int completeSaleTransaction(int accountId, Integer customerId,
                                       String paymentMethod, java.math.BigDecimal discount,
                                       int[] medicineIds, int[] quantities) {
        Connection cn = null;
        try {
            cn = DBContext.getConnection();
            cn.setAutoCommit(false);  // ── Bắt đầu transaction ──

            // Bước 1: Tạo Invoice PENDING
            String sqlInsert = "INSERT INTO Invoices (AccountID, CustomerID, PaymentMethod) " +
                    "VALUES (?,?,?); SELECT SCOPE_IDENTITY();";
            int invoiceId = -1;
            try (PreparedStatement ps = cn.prepareStatement(sqlInsert)) {
                ps.setInt(1, accountId);
                if (customerId != null) ps.setInt(2, customerId);
                else ps.setNull(2, Types.INTEGER);
                ps.setString(3, paymentMethod != null ? paymentMethod : "CASH");
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) invoiceId = rs.getInt(1);
                }
            }
            if (invoiceId < 0) throw new Exception("Không tạo được hóa đơn");

            // Bước 2: Thêm từng sản phẩm qua SP (FIFO) — cùng connection, cùng transaction
            String sqlSP = "EXEC SP_AddSaleByFIFO ?, ?, ?";
            for (int i = 0; i < medicineIds.length; i++) {
                try (CallableStatement cs = cn.prepareCall(sqlSP)) {
                    cs.setInt(1, invoiceId);
                    cs.setInt(2, medicineIds[i]);
                    cs.setInt(3, quantities[i]);
                    cs.execute();
                } catch (SQLException spEx) {
                    // SP ném lỗi (VD: không đủ tồn kho) → rollback
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
                if (ps.executeUpdate() == 0) throw new Exception("Không complete được hóa đơn");
            }

            cn.commit();  // ── Commit thành công ──
            return invoiceId;

        } catch (Exception e) {
            // ── Rollback toàn bộ nếu có lỗi ──
            System.err.println("[InvoiceDAO] completeSaleTransaction rollback: " + e.getMessage());
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

}