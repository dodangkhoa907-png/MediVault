package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IInvoiceDetailDAO;
import com.medicare.entity.InvoiceDetail;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * InvoiceDetailDAO — Chi tiết từng dòng hóa đơn
 *
 * Lưu ý: Trong flow bán hàng bình thường, InvoiceDetails được tạo
 * tự động bởi SP_AddSaleByFIFO — KHÔNG insert thủ công.
 * DAO này chủ yếu dùng để ĐỌC dữ liệu (hiển thị hóa đơn, báo cáo).
 */
public class InvoiceDetailDAO implements IInvoiceDetailDAO {

    private InvoiceDetail mapRow(ResultSet rs) throws SQLException {
        InvoiceDetail d = new InvoiceDetail();
        d.setDetailId(rs.getInt("DetailID"));
        d.setInvoiceId(rs.getInt("InvoiceID"));
        d.setBatchId(rs.getInt("BatchID"));
        d.setQuantity(rs.getInt("Quantity"));
        d.setUnitPrice(rs.getBigDecimal("UnitPrice"));
        d.setSubTotal(rs.getBigDecimal("SubTotal")); // computed column
        return d;
    }

    /**
     * Lấy toàn bộ dòng chi tiết của 1 hóa đơn.
     * JOIN thêm MedicineName để hiển thị trên màn hình.
     */
    public List<InvoiceDetail> findByInvoice(int invoiceId) {
        List<InvoiceDetail> list = new ArrayList<>();
        String sql = "SELECT d.*, m.MedicineName, m.Unit, b.BatchNumber, b.ExpiryDate " +
                "FROM InvoiceDetails d " +
                "JOIN Batches b  ON d.BatchID   = b.BatchID " +
                "JOIN Medicines m ON b.MedicineID = m.MedicineID " +
                "WHERE d.InvoiceID = ? " +
                "ORDER BY d.DetailID";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, invoiceId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    InvoiceDetail d = mapRow(rs);
                    // Gắn thêm thông tin hiển thị
                    d.setMedicineName(rs.getNString("MedicineName"));
                    d.setUnit(rs.getNString("Unit"));
                    d.setBatchNumber(rs.getString("BatchNumber"));
                    if (rs.getDate("ExpiryDate") != null)
                        d.setExpiryDate(rs.getDate("ExpiryDate").toLocalDate());
                    list.add(d);
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    /**
     * Insert thủ công 1 dòng — chỉ dùng khi KHÔNG qua SP_AddSaleByFIFO.
     * Ví dụ: nhập hàng trả lại, điều chỉnh tồn kho thủ công.
     */
    public boolean insert(InvoiceDetail d) {
        String sql = "INSERT INTO InvoiceDetails (InvoiceID, BatchID, Quantity, UnitPrice) " +
                "VALUES (?,?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, d.getInvoiceId());
            ps.setInt(2, d.getBatchId());
            ps.setInt(3, d.getQuantity());
            ps.setBigDecimal(4, d.getUnitPrice());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /**
     * Insert nhiều dòng cùng lúc trong 1 transaction.
     * Dùng batch insert để tối ưu performance.
     */
    public boolean insertList(List<InvoiceDetail> details) {
        if (details == null || details.isEmpty()) return false;
        String sql = "INSERT INTO InvoiceDetails (InvoiceID, BatchID, Quantity, UnitPrice) " +
                "VALUES (?,?,?,?)";
        try (Connection cn = DBContext.getConnection()) {
            cn.setAutoCommit(false); // bắt đầu transaction
            try (PreparedStatement ps = cn.prepareStatement(sql)) {
                for (InvoiceDetail d : details) {
                    ps.setInt(1, d.getInvoiceId());
                    ps.setInt(2, d.getBatchId());
                    ps.setInt(3, d.getQuantity());
                    ps.setBigDecimal(4, d.getUnitPrice());
                    ps.addBatch();
                }
                ps.executeBatch();
                cn.commit();
                return true;
            } catch (Exception e) {
                cn.rollback(); // rollback nếu lỗi
                e.printStackTrace();
                return false;
            }
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}