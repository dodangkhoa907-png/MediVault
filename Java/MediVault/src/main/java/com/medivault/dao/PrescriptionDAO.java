package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.entity.Prescription;
import java.sql.*;

public class PrescriptionDAO extends DBContext {
    public void insert(Prescription p) {
        String sql = "INSERT INTO Prescriptions (CustomerID, DoctorName, HospitalName, PrescriptionDate, ImagePath) VALUES (?,?,?,?,?)";
        try (Connection conn = getConnection(); PreparedStatement ps = conn.prepareStatement(sql)) {
            if (p.getCustomerId() != null) ps.setInt(1, p.getCustomerId()); else ps.setNull(1, Types.INTEGER);
            ps.setNString(2, p.getDoctorName());
            ps.setNString(3, p.getHospitalName());
            ps.setDate(4, Date.valueOf(p.getPrescriptionDate()));
            ps.setString(5, p.getImagePath());
            ps.executeUpdate();
        } catch (Exception e) { e.printStackTrace(); }
    }
}