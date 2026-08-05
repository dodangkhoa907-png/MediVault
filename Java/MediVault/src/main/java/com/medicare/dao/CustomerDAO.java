package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.ICustomerDAO;
import com.medicare.entity.Customer;
import com.medicare.util.MojibakeUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CustomerDAO implements ICustomerDAO {

    private Customer mapRow(ResultSet rs) throws SQLException {
        Customer c = new Customer();
        c.setCustomerId(rs.getInt("CustomerID"));
        try { c.setCustomerCode(rs.getString("CustomerCode")); } catch (SQLException ignored) {}
        c.setCustomerName(MojibakeUtil.fix(rs.getString("CustomerName")));
        c.setPhone(rs.getString("Phone"));
        c.setEmail(rs.getString("Email"));
        c.setAddress(MojibakeUtil.fix(rs.getString("Address")));
        Date dob = rs.getDate("DateOfBirth");
        if (dob != null) c.setDateOfBirth(dob.toLocalDate());
        c.setGender(rs.getString("Gender"));
        c.setNationalId(rs.getString("NationalId"));
        c.setOccupation(MojibakeUtil.fix(rs.getString("Occupation")));
        c.setAllergyHistory(MojibakeUtil.fix(rs.getString("AllergyHistory")));
        c.setChronicDisease(MojibakeUtil.fix(rs.getString("ChronicDisease")));
        if (rs.getTimestamp("CreatedAt") != null)
            c.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
        try { c.setNfcCardUid(rs.getString("NfcCardUid")); } catch (SQLException ignored) {}
        return c;
    }

    public List<Customer> findAll() {
        List<Customer> list = new ArrayList<>();
        String sql = "SELECT * FROM Customers ORDER BY CustomerName";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public Customer findById(int id) {
        String sql = "SELECT * FROM Customers WHERE CustomerID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    public Customer findByPhone(String phone) {
        String sql = "SELECT * FROM Customers WHERE Phone = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, phone);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    public boolean insert(Customer c) {
        String sql = "INSERT INTO Customers (CustomerName, Phone, Email, Address, " +
                "DateOfBirth, Gender, NationalId, Occupation, AllergyHistory, ChronicDisease) " +
                "VALUES (?,?,?,?,?,?,?,?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setNString(1, c.getCustomerName());
            ps.setString(2, c.getPhone());
            ps.setString(3, c.getEmail());
            ps.setNString(4, c.getAddress());
            ps.setObject(5, c.getDateOfBirth() != null ? Date.valueOf(c.getDateOfBirth()) : null);
            ps.setString(6, c.getGender());
            ps.setString(7, c.getNationalId());
            ps.setNString(8, c.getOccupation());
            ps.setNString(9, c.getAllergyHistory());
            ps.setNString(10, c.getChronicDisease());
            if (ps.executeUpdate() == 0) return false;
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    int newId = rs.getInt(1);
                    c.setCustomerId(newId);
                    c.setCustomerCode(assignCustomerCode(cn, newId));
                }
            }
            return true;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Sinh Mã khách hàng duy nhất (KH + 6 số theo CustomerID) và lưu vào DB. */
    private String assignCustomerCode(Connection cn, int customerId) throws SQLException {
        String code = "KH" + String.format("%06d", customerId);
        try (PreparedStatement ps = cn.prepareStatement(
                "UPDATE Customers SET CustomerCode = ? WHERE CustomerID = ?")) {
            ps.setString(1, code);
            ps.setInt(2, customerId);
            ps.executeUpdate();
        }
        return code;
    }

    /** Đăng nhập Portal: cần đúng cả SĐT lẫn Mã khách hàng (cấp tại POS). */
    public Customer findByPhoneAndCode(String phone, String code) {
        String sql = "SELECT * FROM Customers WHERE Phone = ? AND CustomerCode = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, phone);
            ps.setString(2, code);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    /** Tìm khách theo UID thẻ NFC đã liên kết. */
    public Customer findByNfcUid(String uid) {
        if (uid == null || uid.trim().isEmpty()) return null;
        String sql = "SELECT * FROM Customers WHERE NfcCardUid = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, uid.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    /**
     * Liên kết thẻ NFC với khách hàng. Thẻ chỉ gán được cho 1 khách
     * (unique index) và không ghi đè thẻ đã gán cho người khác.
     */
    public boolean linkNfcCard(int customerId, String uid) {
        if (uid == null || uid.trim().isEmpty()) return false;
        String sql = "UPDATE Customers SET NfcCardUid = ? WHERE CustomerID = ? " +
                "AND NOT EXISTS (SELECT 1 FROM Customers WHERE NfcCardUid = ? AND CustomerID != ?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, uid.trim());
            ps.setInt(2, customerId);
            ps.setString(3, uid.trim());
            ps.setInt(4, customerId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Tạo nhanh khách tại POS (chỉ tên + SĐT + giới tính) — trả CustomerID mới, -1 nếu lỗi. */
    public int quickCreate(String name, String phone, String gender) {
        String sql = "INSERT INTO Customers (CustomerName, Phone, Gender) VALUES (?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setNString(1, name);
            ps.setString(2, phone);
            if (gender == null || gender.isEmpty()) ps.setNull(3, Types.VARCHAR);
            else ps.setString(3, gender);
            if (ps.executeUpdate() == 0) return -1;
            try (ResultSet rs = ps.getGeneratedKeys()) {
                if (rs.next()) {
                    int newId = rs.getInt(1);
                    assignCustomerCode(cn, newId);
                    return newId;
                }
            }
        } catch (Exception e) { e.printStackTrace(); }
        return -1;
    }

    /** Khách tự cập nhật hồ sơ từ Customer Portal (không đổi được SĐT/tên tại đây). */
    public boolean updateProfileFromPortal(int customerId, String email, String address,
                                           java.time.LocalDate dob, String gender,
                                           String allergy, String chronic) {
        String sql = "UPDATE Customers SET Email=?, Address=?, DateOfBirth=?, Gender=?, " +
                "AllergyHistory=?, ChronicDisease=? WHERE CustomerID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, email);
            ps.setNString(2, address);
            ps.setObject(3, dob != null ? Date.valueOf(dob) : null);
            if (gender == null || gender.isEmpty()) ps.setNull(4, Types.VARCHAR);
            else ps.setString(4, gender);
            ps.setNString(5, allergy);
            ps.setNString(6, chronic);
            ps.setInt(7, customerId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    public boolean update(Customer c) {
        String sql = "UPDATE Customers SET CustomerName=?, Phone=?, Email=?, Address=?, " +
                "DateOfBirth=?, Gender=?, NationalId=?, Occupation=?, AllergyHistory=?, ChronicDisease=? " +
                "WHERE CustomerID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, c.getCustomerName());
            ps.setString(2, c.getPhone());
            ps.setString(3, c.getEmail());
            ps.setNString(4, c.getAddress());
            ps.setObject(5, c.getDateOfBirth() != null ? Date.valueOf(c.getDateOfBirth()) : null);
            ps.setString(6, c.getGender());
            ps.setString(7, c.getNationalId());
            ps.setNString(8, c.getOccupation());
            ps.setNString(9, c.getAllergyHistory());
            ps.setNString(10, c.getChronicDisease());
            ps.setInt(11, c.getCustomerId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}