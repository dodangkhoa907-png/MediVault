package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IPosStationDAO;
import com.medicare.entity.PosStation;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class PosStationDAO implements IPosStationDAO {

    private PosStation mapRow(ResultSet rs) throws SQLException {
        PosStation p = new PosStation();
        p.setPosStationId(rs.getInt("PosStationID"));
        p.setStationName(rs.getNString("StationName"));
        p.setActive(rs.getBoolean("IsActive"));
        return p;
    }

    @Override
    public List<PosStation> findAll() {
        List<PosStation> list = new ArrayList<>();
        String sql = "SELECT * FROM PosStations ORDER BY PosStationID";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    @Override
    public List<PosStation> findAllActive() {
        List<PosStation> list = new ArrayList<>();
        String sql = "SELECT * FROM PosStations WHERE IsActive = 1 ORDER BY PosStationID";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    @Override
    public PosStation findById(int id) {
        String sql = "SELECT * FROM PosStations WHERE PosStationID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    @Override
    public boolean insert(PosStation pos) {
        String sql = "INSERT INTO PosStations (StationName, IsActive) VALUES (?, ?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setNString(1, pos.getStationName());
            ps.setBoolean(2, pos.isActive());
            int affected = ps.executeUpdate();
            if (affected > 0) {
                try (ResultSet gk = ps.getGeneratedKeys()) {
                    if (gk.next()) {
                        pos.setPosStationId(gk.getInt(1));
                    }
                }
                return true;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    @Override
    public boolean update(PosStation pos) {
        String sql = "UPDATE PosStations SET StationName = ?, IsActive = ? WHERE PosStationID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, pos.getStationName());
            ps.setBoolean(2, pos.isActive());
            ps.setInt(3, pos.getPosStationId());
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    @Override
    public boolean delete(int id) {
        // Gỡ liên kết của các ca ngày hôm nay hoặc lịch sử khỏi quầy này trước khi xóa
        String updateSchedulesSql = "UPDATE ShiftSchedules SET PosStation = 0 WHERE PosStation = ?";
        String deleteStationSql = "DELETE FROM PosStations WHERE PosStationID = ?";
        
        Connection cn = null;
        try {
            cn = DBContext.getConnection();
            cn.setAutoCommit(false);
            
            try (PreparedStatement psUpdate = cn.prepareStatement(updateSchedulesSql);
                 PreparedStatement psDelete = cn.prepareStatement(deleteStationSql)) {
                
                psUpdate.setInt(1, id);
                psUpdate.executeUpdate();
                
                psDelete.setInt(1, id);
                int affected = psDelete.executeUpdate();
                
                cn.commit();
                return affected > 0;
            } catch (Exception e) {
                cn.rollback();
                throw e;
            }
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            if (cn != null) {
                try {
                    cn.setAutoCommit(true);
                    cn.close();
                } catch (Exception ignored) {}
            }
        }
        return false;
    }
}
