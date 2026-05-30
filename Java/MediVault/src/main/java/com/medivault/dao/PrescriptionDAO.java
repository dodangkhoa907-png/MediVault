package com.medivault.dao;

import com.medivault.config.DBContext;
import com.medivault.dao.interfaces.IMachineCommandDAO;
import com.medivault.dao.interfaces.IPrescriptionDAO;
import com.medivault.entity.Prescription;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class PrescriptionDAO implements IPrescriptionDAO {

    private Prescription mapRow(ResultSet rs) throws SQLException {
        Prescription p = new Prescription();
        p.setPrescriptionId(rs.getInt("PrescriptionID"));
        p.setCustomerId(rs.getObject("CustomerID") != null ? rs.getInt("CustomerID") : null);
        p.setDoctorName(rs.getNString("DoctorName"));
        p.setHospitalName(rs.getNString("HospitalName"));
        if (rs.getDate("PrescriptionDate") != null)
            p.setPrescriptionDate(rs.getDate("PrescriptionDate").toLocalDate());
        p.setImagePath(rs.getString("ImagePath"));
        p.setNotes(rs.getNString("Notes"));
        return p;
    }

    public boolean insert(Prescription p) {
        String sql = "INSERT INTO Prescriptions (CustomerID, DoctorName, HospitalName, " +
                "PrescriptionDate, ImagePath, Notes) VALUES (?,?,?,?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            if (p.getCustomerId() != null) ps.setInt(1, p.getCustomerId());
            else ps.setNull(1, Types.INTEGER);
            ps.setNString(2, p.getDoctorName());
            ps.setNString(3, p.getHospitalName());
            ps.setDate(4, Date.valueOf(p.getPrescriptionDate()));
            ps.setString(5, p.getImagePath());
            ps.setNString(6, p.getNotes());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    public Prescription findById(int id) {
        String sql = "SELECT * FROM Prescriptions WHERE PrescriptionID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    public List<Prescription> findByCustomer(int customerId) {
        List<Prescription> list = new ArrayList<>();
        String sql = "SELECT * FROM Prescriptions WHERE CustomerID = ? ORDER BY PrescriptionDate DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, customerId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }
}