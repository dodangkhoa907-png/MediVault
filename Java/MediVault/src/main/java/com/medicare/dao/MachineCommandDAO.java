package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IMachineCommandDAO;
import com.medicare.entity.MachineCommand;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class MachineCommandDAO implements IMachineCommandDAO {

    private MachineCommand mapRow(ResultSet rs) throws SQLException {
        MachineCommand m = new MachineCommand();
        m.setCommandId(rs.getInt("CommandID"));
        m.setDetailId(rs.getInt("DetailID"));
        m.setMachineSlotCode(rs.getString("MachineSlotCode"));
        m.setQuantity(rs.getInt("Quantity"));
        m.setStatus(rs.getString("Status"));
        if (rs.getTimestamp("CreatedAt") != null)
            m.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
        if (rs.getTimestamp("ProcessedAt") != null)
            m.setProcessedAt(rs.getTimestamp("ProcessedAt").toLocalDateTime());
        m.setRetryCount(rs.getInt("RetryCount"));
        m.setErrorMessage(rs.getNString("ErrorMessage"));
        return m;
    }

    // Servlet lấy danh sách lệnh đang chờ xử lý
    public List<MachineCommand> findPending() {
        List<MachineCommand> list = new ArrayList<>();
        String sql = "SELECT * FROM MachineCommands WHERE Status = 'PENDING' ORDER BY CreatedAt ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    // Cập nhật trạng thái lệnh (PENDING → PROCESSING → DONE / FAILED)
    public boolean updateStatus(int commandId, String newStatus) {
        String sql = "UPDATE MachineCommands SET Status=?, ProcessedAt=GETDATE() WHERE CommandID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, newStatus);
            ps.setInt(2, commandId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // Thử lại lệnh thất bại — tăng RetryCount, reset về PENDING
    public boolean retryFailed(int commandId, String errorMessage) {
        String sql = "UPDATE MachineCommands " +
                "SET Status = CASE WHEN RetryCount >= 5 THEN 'FAILED' ELSE 'PENDING' END, " +
                "    RetryCount = RetryCount + 1, " +
                "    ErrorMessage = ? " +
                "WHERE CommandID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setNString(1, errorMessage);
            ps.setInt(2, commandId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // Insert thủ công (thường do Trigger tự tạo, nhưng để phòng khi cần)
    public boolean insert(MachineCommand m) {
        String sql = "INSERT INTO MachineCommands (DetailID, MachineSlotCode, Quantity) VALUES (?,?,?)";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, m.getDetailId());
            ps.setString(2, m.getMachineSlotCode());
            ps.setInt(3, m.getQuantity());
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }
}