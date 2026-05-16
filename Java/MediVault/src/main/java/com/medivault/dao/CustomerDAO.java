package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.entity.Customer;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CustomerDAO {

    private Customer mapRow(ResultSet rs) throws SQLException {
        Customer c = new Customer();
        c.setCustomerId(rs.getInt("CustomerID"));
        c.setCustomerName(rs.getNString("CustomerName"));
        c.setPhone(rs.getString("Phone"));
        c.setEmail(rs.getString("Email"));
        c.setAddress(rs.getNString("Address"));
        Date dob = rs.getDate("DateOfBirth");
        if (dob != null) c.setDateOfBirth(dob.toLocalDate());
        c.setGender(rs.getString("Gender"));
        c.setNationalId(rs.getString("NationalId"));
        c.setAllergyHistory(rs.getNString("AllergyHistory"));
        c.setChronicDisease(rs.getNString("ChronicDisease"));
        c.setPoints(rs.getInt("Points"));
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
                "DateOfBirth, Gender, NationalId, AllergyHistory, ChronicDisease) " +
                "VALUES (?,?,?,?,?,?,?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, c.getCustomerName());
            ps.setString(2, c.getPhone());
            ps.setString(3, c.getEmail());
            ps.setNString(4, c.getAddress());
            ps.setObject(5, c.getDateOfBirth() != null ? Date.valueOf(c.getDateOfBirth()) : null);
            ps.setString(6, c.getGender());
            ps.setString(7, c.getNationalId());
            ps.setNString(8, c.getAllergyHistory());
            ps.setNString(9, c.getChronicDisease());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    public boolean update(Customer c) {
        String sql = "UPDATE Customers SET CustomerName=?, Phone=?, Email=?, Address=?, " +
                "DateOfBirth=?, Gender=?, NationalId=?, AllergyHistory=?, ChronicDisease=? " +
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
            ps.setNString(8, c.getAllergyHistory());
            ps.setNString(9, c.getChronicDisease());
            ps.setInt(10, c.getCustomerId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}