package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IPayrollDAO;
import com.medicare.entity.Payroll;
import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class PayrollDAO implements IPayrollDAO {

    private Payroll mapRow(ResultSet rs) throws SQLException {
        Payroll p = new Payroll();
        p.setPayrollId(rs.getInt("PayrollID"));
        p.setAccountId(rs.getInt("AccountID"));
        p.setPayMonth(rs.getInt("PayMonth"));
        p.setPayYear(rs.getInt("PayYear"));
        p.setTotalScheduledDays(rs.getInt("TotalScheduledDays"));
        p.setTotalWorkedDays(rs.getInt("TotalWorkedDays"));
        p.setTotalHours(rs.getBigDecimal("TotalHours"));
        p.setOvertimeHours(rs.getBigDecimal("OvertimeHours"));
        p.setBaseSalary(rs.getBigDecimal("BaseSalary"));
        p.setOvertimePay(rs.getBigDecimal("OvertimePay"));
        p.setAllowance(rs.getBigDecimal("Allowance"));
        p.setBonus(rs.getBigDecimal("Bonus"));
        p.setDeduction(rs.getBigDecimal("Deduction"));
        p.setNetSalary(rs.getBigDecimal("NetSalary"));
        p.setStatus(rs.getString("Status"));
        int cb = rs.getInt("ConfirmedBy");
        p.setConfirmedBy(rs.wasNull() ? null : cb);
        if (rs.getTimestamp("ConfirmedAt") != null)
            p.setConfirmedAt(rs.getTimestamp("ConfirmedAt").toLocalDateTime());
        if (rs.getTimestamp("PaidAt") != null)
            p.setPaidAt(rs.getTimestamp("PaidAt").toLocalDateTime());
        p.setNotes(rs.getNString("Notes"));
        if (rs.getTimestamp("CreatedAt") != null)
            p.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
        try { p.setStaffName(rs.getNString("StaffName")); }           catch (SQLException ignored) {}
        try { p.setConfirmedByName(rs.getNString("ConfirmedByName")); } catch (SQLException ignored) {}
        return p;
    }

    private static final String SELECT_FULL =
        "SELECT p.*, a.FullName AS StaffName, cb.FullName AS ConfirmedByName "
        + "FROM Payroll p "
        + "JOIN Accounts a ON a.AccountID = p.AccountID "
        + "LEFT JOIN Accounts cb ON cb.AccountID = p.ConfirmedBy ";

    @Override
    public int generate(int accountId, int month, int year) {
        String sql = "{call SP_GeneratePayroll(?,?,?)}";
        try (Connection cn = DBContext.getConnection();
             CallableStatement cs = cn.prepareCall(sql)) {
            cs.setInt(1, accountId);
            cs.setByte(2, (byte) month);
            cs.setShort(3, (short) year);
            try (ResultSet rs = cs.executeQuery()) {
                if (rs.next()) return rs.getInt("PayrollID");
            }
        } catch (Exception e) { e.printStackTrace(); }
        return -1;
    }

    @Override
    public boolean updateBonus(int payrollId, BigDecimal bonus, String notes) {
        String sql = "UPDATE Payroll SET Bonus=?, Notes=? "
                + "WHERE PayrollID=? AND Status='DRAFT'";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setBigDecimal(1, bonus != null ? bonus : BigDecimal.ZERO);
            ps.setNString(2, notes);
            ps.setInt(3, payrollId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public boolean confirm(int payrollId, int confirmedBy) {
        String sql = "UPDATE Payroll SET Status='CONFIRMED', "
                + "ConfirmedBy=?, ConfirmedAt=GETDATE() "
                + "WHERE PayrollID=? AND Status='DRAFT'";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, confirmedBy);
            ps.setInt(2, payrollId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public boolean markPaid(int payrollId) {
        String sql = "UPDATE Payroll SET Status='PAID', PaidAt=GETDATE() "
                + "WHERE PayrollID=? AND Status='CONFIRMED'";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, payrollId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public List<Payroll> findByMonth(int month, int year) {
        List<Payroll> list = new ArrayList<>();
        String sql = SELECT_FULL
                + "WHERE p.PayMonth=? AND p.PayYear=? "
                + "ORDER BY a.FullName ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, month);
            ps.setInt(2, year);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<Payroll> findByAccount(int accountId) {
        List<Payroll> list = new ArrayList<>();
        String sql = SELECT_FULL
                + "WHERE p.AccountID=? "
                + "ORDER BY p.PayYear DESC, p.PayMonth DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public Payroll findByAccountAndMonth(int accountId, int month, int year) {
        String sql = SELECT_FULL
                + "WHERE p.AccountID=? AND p.PayMonth=? AND p.PayYear=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.setInt(2, month);
            ps.setInt(3, year);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    @Override
    public Payroll findById(int payrollId) {
        String sql = SELECT_FULL + "WHERE p.PayrollID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, payrollId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }
}
