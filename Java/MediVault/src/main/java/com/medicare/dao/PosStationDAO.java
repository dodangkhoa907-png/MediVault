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

    /**
     * Quầy đang được sử dụng? = còn ca hôm nay/tương lai (chưa hủy) gán vào quầy này.
     * Dùng để CHẶN xóa quầy khi đang có nhân viên làm/được xếp lịch tại đó.
     */
    public boolean isInUse(int id) {
        String sql = "SELECT TOP 1 1 FROM ShiftSchedules "
                + "WHERE PosStation = ? AND WorkDate >= CAST(GETDATE() AS DATE) "
                + "AND Status NOT IN ('CANCELLED','ON_LEAVE')";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (Exception e) {
            e.printStackTrace();
            return true; // an toàn: lỗi DB thì coi như đang dùng → chặn xóa
        }
    }

    /**
     * Xóa quầy — CHỈ khi không còn ca hôm nay/tương lai nào gán vào quầy.
     * KHÔNG đụng vào lịch sử (ca quá khứ giữ nguyên PosStation để báo cáo đúng).
     */
    @Override
    public boolean delete(int id) {
        if (isInUse(id)) return false;
        String sql = "DELETE FROM PosStations WHERE PosStationID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }
}
