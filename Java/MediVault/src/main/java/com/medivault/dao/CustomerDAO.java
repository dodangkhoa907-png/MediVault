package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.entity.Customer;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CustomerDAO extends DBContext {
    public List<Customer> getAll() {
        List<Customer> list = new ArrayList<>();
        String sql = "SELECT * FROM Customers";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql); ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Customer c = new Customer();
                c.setCustomerId(rs.getInt("CustomerID"));
                c.setCustomerName(rs.getNString("CustomerName"));
                c.setPhone(rs.getString("Phone"));
                c.setEmail(rs.getString("Email"));
                c.setAddress(rs.getNString("Address"));
                c.setAllergyHistory(rs.getNString("AllergyHistory"));
                c.setPoints(rs.getInt("Points"));
                list.add(c);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public void insert(Customer c) {
        String sql = "INSERT INTO Customers (CustomerName, Phone, Email, Address, AllergyHistory) VALUES (?,?,?,?,?)";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setNString(1, c.getCustomerName());
            ps.setString(2, c.getPhone());
            ps.setString(3, c.getEmail());
            ps.setNString(4, c.getAddress());
            ps.setNString(5, c.getAllergyHistory());
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }
}
