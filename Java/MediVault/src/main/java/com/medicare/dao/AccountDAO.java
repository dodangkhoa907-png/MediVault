package com.medicare.dao;

import com.medicare.config.DBContext;
import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.entity.Account;
import com.medicare.util.ValidationUtil;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class AccountDAO implements IAccountDAO {

    private Account mapRow(ResultSet rs) throws SQLException {
        Account a = new Account();
        a.setAccountId(rs.getInt("AccountID"));
        a.setUsername(rs.getString("Username"));
        a.setPasswordHash(rs.getString("PasswordHash"));
        // Unicode columns
        a.setFullName(rs.getString("FullName"));
        a.setEmail(rs.getString("Email"));
        a.setPhone(rs.getString("Phone"));
        a.setRoleId(rs.getInt("RoleID"));
        a.setActive(rs.getBoolean("IsActive"));
        a.setCitizenId(rs.getString("CitizenId"));
        a.setPosition(rs.getString("Position"));
        a.setProfessionalCertNo(rs.getString("ProfessionalCertNo"));
        a.setDeleted(rs.getBoolean("IsDeleted"));
        if (rs.getTimestamp("DeletedAt") != null)
            a.setDeletedAt(rs.getTimestamp("DeletedAt").toLocalDateTime());
        if (rs.getDate("ProfessionalCertExp") != null)
            a.setProfessionalCertExp(rs.getDate("ProfessionalCertExp").toLocalDate());
        if (rs.getDate("TrainingDate") != null)
            a.setTrainingDate(rs.getDate("TrainingDate").toLocalDate());
        a.setFaceEnrollmentPath(rs.getString("FaceEnrollmentPath"));
        try { a.setLicenseFilePath(rs.getString("LicenseFilePath")); } catch (SQLException ignored) {}
        try { a.setFaceVector(rs.getString("FaceVector")); } catch (SQLException ignored) {}
        try {
            Timestamp fe = rs.getTimestamp("FaceEnrolledAt");
            if (fe != null) a.setFaceEnrolledAt(fe.toLocalDateTime());
        } catch (SQLException ignored) {}
        // ── Face re-enroll (cột optional — bọc try/catch để không vỡ khi query cũ) ──
        try { a.setFaceReenrollStatus(rs.getString("FaceReenrollStatus")); } catch (SQLException ignored) {}
        try { a.setFaceReenrollReason(rs.getString("FaceReenrollReason")); } catch (SQLException ignored) {}
        try {
            Timestamp rr = rs.getTimestamp("FaceReenrollRequestedAt");
            if (rr != null) a.setFaceReenrollRequestedAt(rr.toLocalDateTime());
        } catch (SQLException ignored) {}
        try { a.setFaceReenrollHandledBy((Integer) rs.getObject("FaceReenrollHandledBy")); } catch (SQLException ignored) {}
        try {
            Timestamp rh = rs.getTimestamp("FaceReenrollHandledAt");
            if (rh != null) a.setFaceReenrollHandledAt(rh.toLocalDateTime());
        } catch (SQLException ignored) {}
        if (rs.getTimestamp("CreatedAt") != null)
            a.setCreatedAt(rs.getTimestamp("CreatedAt").toLocalDateTime());
        if (rs.getTimestamp("LastLoginAt") != null)
            a.setLastLoginAt(rs.getTimestamp("LastLoginAt").toLocalDateTime());
        // Cột thêm sau (database/warehouse_export_migration.sql) — try/catch để DB chưa chạy
        // migration vẫn không vỡ các câu SELECT * hiện có (giống PackagingSpec/ExpectedDate).
        try { a.setWarehouseManager(rs.getBoolean("IsWarehouseManager")); } catch (SQLException ignored) {}
        return a;
    }

    // ================================================================
    // VALIDATE trước khi insert/update
    // ================================================================

    /**
     * Kiểm tra tính hợp lệ của Account.
     * Servlet gọi cái này trước khi gọi insert/update.
     * Trả về danh sách lỗi — rỗng = OK.
     */
    public List<String> validate(Account a) {
        return ValidationUtil.validateAccount(
                a.getUsername(),
                a.getFullName(),
                a.getEmail(),
                a.getPhone(),
                a.getCitizenId(),
                a.getPosition()
        );
    }

    /**
     * Kiểm tra username đã tồn tại chưa (dùng khi tạo mới).
     */
    public boolean isUsernameTaken(String username) {
        String sql = "SELECT 1 FROM Accounts WHERE Username = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, username.trim());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next(); // true = đã tồn tại
            }
        } catch (Exception e) { e.printStackTrace(); }
        return false;
    }

    /**
     * Kiểm tra email đã tồn tại chưa (dùng khi tạo mới hoặc cập nhật).
     * excludeId: bỏ qua account hiện tại khi update (truyền -1 khi insert)
     */
    public boolean isEmailTaken(String email, int excludeId) {
        if (email == null || email.trim().isEmpty()) return false;
        String sql = "SELECT 1 FROM Accounts WHERE Email = ? AND AccountID != ? AND IsDeleted = 0";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, email.trim());
            ps.setInt(2, excludeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (Exception e) { e.printStackTrace(); }
        return false;
    }

    /**
     * Kiểm tra số điện thoại đã tồn tại chưa.
     * excludeId: bỏ qua account hiện tại khi update (truyền -1 khi insert)
     */
    public boolean isPhoneTaken(String phone, int excludeId) {
        if (phone == null || phone.trim().isEmpty()) return false;
        String sql = "SELECT 1 FROM Accounts WHERE Phone = ? AND AccountID != ? AND IsDeleted = 0";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, phone.trim());
            ps.setInt(2, excludeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (Exception e) { e.printStackTrace(); }
        return false;
    }

    /**
     * Kiểm tra CCCD đã tồn tại chưa.
     * excludeId: bỏ qua account hiện tại khi update (truyền -1 khi insert)
     */
    public boolean isCitizenIdTaken(String citizenId, int excludeId) {
        if (citizenId == null || citizenId.trim().isEmpty()) return false;
        String sql = "SELECT 1 FROM Accounts WHERE CitizenId = ? AND AccountID != ? AND IsDeleted = 0";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, citizenId.trim());
            ps.setInt(2, excludeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (Exception e) { e.printStackTrace(); }
        return false;
    }

    // ================================================================
    // QUERIES
    // ================================================================

    public Account findByUsername(String username) {
        String sql = "SELECT * FROM Accounts WHERE Username = ? AND IsActive = 1 AND IsDeleted = 0";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    /** Tìm kể cả TK bị khóa (IsActive=0) — dùng cho staff-login để phát hiện TK bị khóa */
    @Override
    public Account findByUsernameAny(String username) {
        String sql = "SELECT * FROM Accounts WHERE Username = ? AND IsDeleted = 0";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    /** Tìm theo email kể cả TK bị khóa (IsActive=0) — dùng cho quên mật khẩu chỉ nhập email. */
    @Override
    public Account findByEmailAny(String email) {
        String sql = "SELECT * FROM Accounts WHERE Email = ? AND IsDeleted = 0";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    public Account findById(int id) {
        String sql = "SELECT * FROM Accounts WHERE AccountID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (Exception e) { e.printStackTrace(); }
        return null;
    }

    public List<Account> findAll() {
        List<Account> list = new ArrayList<>();
        String sql = "SELECT * FROM Accounts WHERE IsDeleted = 0 ORDER BY FullName";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public List<Account> findAllStaff() {
        List<Account> list = new ArrayList<>();
        String sql = "SELECT * FROM Accounts WHERE RoleID != 1 AND IsDeleted = 0 ORDER BY FullName";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    // ================================================================
    // INSERT — validate trước khi lưu
    // ================================================================

    /**
     * Tạo tài khoản mới.
     * Servlet PHẢI gọi validate() + isUsernameTaken() trước khi gọi insert().
     */
    public boolean insert(Account a) {
        // Double-check validate tại DAO (bảo vệ tầng thứ 2)
        List<String> errors = validate(a);
        if (!errors.isEmpty()) {
            throw new RuntimeException("Validate thất bại: " + ValidationUtil.joinErrors(errors));
        }

        String sql = "INSERT INTO Accounts " +
                "(Username, PasswordHash, FullName, Email, Phone, RoleID, CitizenId, Position, IsActive) " +
                "VALUES (?,?,?,?,?,?,?,?,1)";

        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, a.getUsername().trim());
            ps.setString(2, a.getPasswordHash());
            ps.setString(3, a.getFullName().trim());
            ps.setString(4, a.getEmail() != null ? a.getEmail().trim() : null);
            ps.setString(5, a.getPhone() != null ? a.getPhone().trim() : null);
            ps.setInt(6, a.getRoleId());
            String cid = a.getCitizenId();
            ps.setString(7, (cid != null && !cid.trim().isEmpty()) ? cid.trim() : null);
            String pos = a.getPosition();
            ps.setString(8, (pos != null && !pos.trim().isEmpty()) ? pos.trim() : null);
            return ps.executeUpdate() > 0;
        } catch (Exception e) {
            throw new RuntimeException("SQL INSERT thất bại: " + e.getMessage(), e);
        }
    }

    // ================================================================
    // UPDATE — validate trước khi lưu
    // ================================================================

    /**
     * Cập nhật thông tin tài khoản.
     * Không cho đổi Username và PasswordHash ở đây (có method riêng).
     */
    public boolean update(Account a) {
        // Validate chỉ các field có trong form edit (không validate username vì không đổi được)
        if (a.getFullName() == null || a.getFullName().trim().isEmpty()) {
            System.err.println("[AccountDAO] update thất bại — FullName trống");
            return false;
        }
        String sql = "UPDATE Accounts SET " +
                "FullName=?, Email=?, Phone=?, RoleID=?, CitizenId=?, Position=?, " +
                "ProfessionalCertNo=?, ProfessionalCertExp=?, TrainingDate=?, IsWarehouseManager=? " +
                "WHERE AccountID=?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, a.getFullName().trim());
            ps.setString(2, a.getEmail() != null ? a.getEmail().trim() : null);
            ps.setString(3, a.getPhone() != null ? a.getPhone().trim() : null);
            ps.setInt(4, a.getRoleId());
            String cidUpd = a.getCitizenId();
            ps.setString(5, (cidUpd != null && !cidUpd.trim().isEmpty()) ? cidUpd.trim() : null);
            ps.setString(6, a.getPosition() != null ? a.getPosition().trim() : null);
            // 3 field chuyên môn — nullable
            ps.setString(7, a.getProfessionalCertNo());
            if (a.getProfessionalCertExp() != null)
                ps.setDate(8, java.sql.Date.valueOf(a.getProfessionalCertExp()));
            else ps.setNull(8, java.sql.Types.DATE);
            if (a.getTrainingDate() != null)
                ps.setDate(9, java.sql.Date.valueOf(a.getTrainingDate()));
            else ps.setNull(9, java.sql.Types.DATE);
            ps.setBoolean(10, a.isWarehouseManager());
            ps.setInt(11, a.getAccountId());
            int rows = ps.executeUpdate();
            System.out.println("[AccountDAO] update accountId=" + a.getAccountId() + " → rows=" + rows);
            return rows > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // ================================================================
    // CÁC METHOD KHÁC
    // ================================================================

    public boolean updateLastLogin(int accountId) {
        String sql = "UPDATE Accounts SET LastLoginAt = GETDATE() WHERE AccountID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }


    /** Đếm số tài khoản Admin đang active — dùng để bảo vệ admin cuối cùng */
    public int countActiveAdmins() {
        String sql = "SELECT COUNT(*) FROM Accounts WHERE RoleID = 1 AND IsActive = 1";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) return rs.getInt(1);
        } catch (Exception e) { e.printStackTrace(); }
        return 0;
    }


    /** Soft delete — đánh dấu xóa, giữ trong DB 30 ngày.
     *  Username được đổi thành __del_<id>_<orig> để giải phóng unique slot cho tài khoản mới. */
    public boolean softDelete(int accountId) {
        String sql = "UPDATE Accounts SET IsDeleted = 1, DeletedAt = GETDATE(), " +
                     "Username = CONCAT('__del_', CAST(AccountID AS NVARCHAR), '_', Username) " +
                     "WHERE AccountID = ? AND IsDeleted = 0";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Khôi phục tài khoản đã soft delete — cũng khôi phục username gốc (bỏ tiền tố __del_<id>_) */
    public boolean restore(int accountId) {
        // Khôi phục username gốc bằng cách bỏ tiền tố "__del_<id>_" (nếu có).
        // Nếu username gốc đã bị tài khoản khác chiếm, giữ nguyên username hiện tại.
        String sql = "UPDATE Accounts SET IsDeleted = 0, DeletedAt = NULL, " +
                "Username = CASE " +
                "  WHEN Username LIKE CONCAT('__del_', CAST(AccountID AS NVARCHAR(20)), '_%') " +
                "    AND NOT EXISTS (" +
                "      SELECT 1 FROM Accounts a2 WHERE a2.IsDeleted = 0 AND a2.AccountID != AccountID " +
                "      AND a2.Username = SUBSTRING(Username, " +
                "        LEN(CONCAT('__del_', CAST(AccountID AS NVARCHAR(20)), '_')) + 1, LEN(Username))" +
                "    ) " +
                "  THEN SUBSTRING(Username, LEN(CONCAT('__del_', CAST(AccountID AS NVARCHAR(20)), '_')) + 1, LEN(Username)) " +
                "  ELSE Username " +
                "END " +
                "WHERE AccountID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Hard delete — xóa vĩnh viễn (chỉ dùng sau 30 ngày) */
    public boolean hardDelete(int accountId) {
        String sql = "DELETE FROM Accounts WHERE AccountID = ? AND IsDeleted = 1 " +
                "AND DATEDIFF(day, DeletedAt, GETDATE()) >= 30";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Lấy danh sách đã soft delete — trang thùng rác */
    public List<Account> findDeleted() {
        List<Account> list = new ArrayList<>();
        String sql = "SELECT * FROM Accounts WHERE IsDeleted = 1 ORDER BY DeletedAt DESC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    public boolean toggleActive(int accountId) {
        String sql = "UPDATE Accounts SET IsActive = 1 - IsActive WHERE AccountID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    public boolean resetPassword(int accountId, String newHash) {
        // Không cần validate hash vì đã qua PasswordUtil.hashPassword()
        String sql = "UPDATE Accounts SET PasswordHash = ? WHERE AccountID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, newHash);
            ps.setInt(2, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Force delete — xóa vĩnh viễn NGAY (không cần đủ 30 ngày, dành cho admin) */
    /**
     * Xóa vĩnh viễn tài khoản (đã trong thùng rác).
     * Xử lý FK constraints trước khi DELETE:
     *   - Xóa PasswordResetRequests (không có giá trị lưu trữ)
     *   - SET NULL cho AuditLogs (lịch sử vẫn giữ, chỉ mất tên người dùng)
     *   - Các bảng kinh doanh (Invoices, Shifts...) giữ nguyên — không xóa
     */
    public boolean forceDelete(int accountId) {
        java.sql.Connection cn = null;
        try {
            cn = DBContext.getConnection();
            cn.setAutoCommit(false);

            // ── Dựa trên 9 FK thực tế trong DB (sys.foreign_keys) ──
            // Thứ tự: xử lý con trước, cha sau

            // LeaveRequests.ApprovedBy → SET NULL
            exec(cn, "UPDATE LeaveRequests SET ApprovedBy = NULL WHERE ApprovedBy = ?", accountId);
            // LeaveRequests.AccountID → DELETE
            exec(cn, "DELETE FROM LeaveRequests WHERE AccountID = ?", accountId);

            // Payroll.ConfirmedBy → SET NULL
            exec(cn, "UPDATE Payroll SET ConfirmedBy = NULL WHERE ConfirmedBy = ?", accountId);
            // Payroll.AccountID → DELETE
            exec(cn, "DELETE FROM Payroll WHERE AccountID = ?", accountId);

            // Attendance.AccountID → DELETE
            exec(cn, "DELETE FROM Attendance WHERE AccountID = ?", accountId);

            // ShiftSchedules.CreatedBy → SET NULL
            exec(cn, "UPDATE ShiftSchedules SET CreatedBy = NULL WHERE CreatedBy = ?", accountId);
            // ShiftSchedules.AccountID → DELETE
            exec(cn, "DELETE FROM ShiftSchedules WHERE AccountID = ?", accountId);

            // Invoices.ShiftID → SET NULL trước khi xóa Shifts
            exec(cn, "UPDATE Invoices SET ShiftID = NULL WHERE ShiftID IN (SELECT ShiftID FROM Shifts WHERE AccountID = ?)", accountId);
            // Shifts.AccountID → DELETE
            exec(cn, "DELETE FROM Shifts WHERE AccountID = ?", accountId);

            // AuditLog.AccountID → SET NULL (giữ lịch sử)
            exec(cn, "UPDATE AuditLog SET AccountID = NULL WHERE AccountID = ?", accountId);

            // PasswordResetRequests — bảng có thể chưa tồn tại
            try { exec(cn, "DELETE FROM PasswordResetRequests WHERE AccountID = ?", accountId); }
            catch (Exception ignored) {}

            // StaffAuditLogs — bảng có thể chưa tồn tại
            try { exec(cn, "UPDATE StaffAuditLogs SET AccountID = NULL WHERE AccountID = ?", accountId); }
            catch (Exception ignored) {}

            // Xóa tài khoản (bỏ AND IsDeleted = 1 — forceDelete không cần điều kiện này)
            int rows;
            try (java.sql.PreparedStatement ps = cn.prepareStatement(
                    "DELETE FROM Accounts WHERE AccountID = ?")) {
                ps.setInt(1, accountId);
                rows = ps.executeUpdate();
            }

            if (rows == 0) { cn.rollback(); return false; }
            cn.commit();
            return true;

        } catch (Exception e) {
            System.out.println("[forceDelete] FAILED at AccountID=" + accountId + ": " + e.getMessage());
            e.printStackTrace();
            if (cn != null) { try { cn.rollback(); } catch (Exception ignored) {} }
            return false;
        } finally {
            if (cn != null) { try { cn.setAutoCommit(true); cn.close(); } catch (Exception ignored) {} }
        }
    }

    private void exec(java.sql.Connection cn, String sql, int param) throws Exception {
        try (java.sql.PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, param);
            ps.executeUpdate();
        }
    }

    public boolean updateAvatar(int accountId, String path) {
        String sql = "UPDATE Accounts SET FaceEnrollmentPath = ? WHERE AccountID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, path);
            ps.setInt(2, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Lưu đường dẫn file PDF giấy phép hành nghề (bằng chứng thật, thay vì chỉ gõ tay số chứng chỉ). */
    @Override
    public boolean updateLicenseFilePath(int accountId, String path) {
        String sql = "UPDATE Accounts SET LicenseFilePath = ? WHERE AccountID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, path);
            ps.setInt(2, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    @Override
    public boolean updateFaceVector(int accountId, String faceVectorJson) {
        String sql = "UPDATE Accounts SET FaceVector = ?, FaceEnrolledAt = " +
                (faceVectorJson == null ? "NULL" : "GETDATE()") + " WHERE AccountID = ?";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            if (faceVectorJson == null) {
                ps.setNull(1, java.sql.Types.NVARCHAR);
            } else {
                ps.setNString(1, faceVectorJson);
            }
            ps.setInt(2, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    // ── Face re-enroll request flow ──────────────────────────────────────────

    /** Nhân viên gửi yêu cầu đăng ký lại khuôn mặt → set PENDING + lý do. */
    public boolean requestFaceReenroll(int accountId, String reason) {
        String sql = "UPDATE Accounts SET FaceReenrollStatus = 'PENDING', " +
                "FaceReenrollReason = ?, FaceReenrollRequestedAt = GETDATE(), " +
                "FaceReenrollHandledBy = NULL, FaceReenrollHandledAt = NULL " +
                "WHERE AccountID = ? AND (FaceReenrollStatus IS NULL OR FaceReenrollStatus <> 'PENDING')";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            if (reason == null || reason.trim().isEmpty()) ps.setNull(1, Types.NVARCHAR);
            else ps.setNString(1, reason.trim());
            ps.setInt(2, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /**
     * Admin DUYỆT yêu cầu → xóa FaceVector (buộc đăng ký lại từ đầu),
     * xóa trạng thái PENDING, ghi người/lúc xử lý.
     */
    public boolean approveFaceReenroll(int accountId, int adminId) {
        String sql = "UPDATE Accounts SET FaceVector = NULL, FaceEnrolledAt = NULL, " +
                "FaceReenrollStatus = NULL, FaceReenrollHandledBy = ?, FaceReenrollHandledAt = GETDATE() " +
                "WHERE AccountID = ? AND FaceReenrollStatus = 'PENDING'";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, adminId);
            ps.setInt(2, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Admin TỪ CHỐI yêu cầu → xóa PENDING, giữ nguyên khuôn mặt cũ. */
    public boolean rejectFaceReenroll(int accountId, int adminId, String note) {
        String sql = "UPDATE Accounts SET FaceReenrollStatus = NULL, " +
                "FaceReenrollReason = ?, FaceReenrollHandledBy = ?, FaceReenrollHandledAt = GETDATE() " +
                "WHERE AccountID = ? AND FaceReenrollStatus = 'PENDING'";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            if (note == null || note.trim().isEmpty()) ps.setNull(1, Types.NVARCHAR);
            else ps.setNString(1, note.trim());
            ps.setInt(2, adminId);
            ps.setInt(3, accountId);
            return ps.executeUpdate() > 0;
        } catch (Exception e) { e.printStackTrace(); return false; }
    }

    /** Danh sách yêu cầu đăng ký lại khuôn mặt đang chờ duyệt (cho admin). */
    public List<Account> findPendingFaceReenroll() {
        List<Account> list = new ArrayList<>();
        String sql = "SELECT * FROM Accounts WHERE FaceReenrollStatus = 'PENDING' " +
                "AND IsDeleted = 0 ORDER BY FaceReenrollRequestedAt ASC";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    /** Email toàn bộ admin đang active — để gửi thông báo yêu cầu đổi khuôn mặt. */
    public List<String> findActiveAdminEmails() {
        List<String> emails = new ArrayList<>();
        String sql = "SELECT Email FROM Accounts WHERE RoleID = 1 AND IsActive = 1 " +
                "AND IsDeleted = 0 AND Email IS NOT NULL AND Email <> ''";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) emails.add(rs.getString("Email"));
        } catch (Exception e) { e.printStackTrace(); }
        return emails;
    }

    @Override
    public List<Account> findAllWithFaceVector() {
        List<Account> list = new ArrayList<>();
        String sql = "SELECT * FROM Accounts " +
                "WHERE FaceVector IS NOT NULL AND IsActive = 1 AND IsDeleted = 0";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (Exception e) { e.printStackTrace(); }
        return list;
    }

    @Override
    public List<Account> findAccountsByIds(List<Integer> ids) {
        List<Account> list = new ArrayList<>();
        if (ids == null || ids.isEmpty()) return list;

        StringBuilder placeholders = new StringBuilder();
        for (int i = 0; i < ids.size(); i++) {
            placeholders.append("?");
            if (i < ids.size() - 1) placeholders.append(",");
        }

        String sql = "SELECT * FROM Accounts WHERE AccountID IN (" + placeholders.toString() + ") AND IsDeleted = 0";
        try (Connection cn = DBContext.getConnection();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            for (int i = 0; i < ids.size(); i++) {
                ps.setInt(i + 1, ids.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return list;
    }

    // ── Presence tracking ─────────────────────────────────────────────────────

    @Override
    public void updateLastActive(int accountId) {
        String sql = "UPDATE Accounts SET LastActiveAt = GETDATE() WHERE AccountID = ?";
        try (java.sql.Connection cn = com.medicare.config.DBContext.getConnection();
             java.sql.PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, accountId);
            ps.executeUpdate();
        } catch (Exception e) { /* non-critical — silent */ }
    }

    @Override
    public List<Integer> findOnlineAccountIds(int minutesThreshold) {
        String sql = "SELECT AccountID FROM Accounts " +
                     "WHERE LastActiveAt IS NOT NULL " +
                     "AND DATEDIFF(MINUTE, LastActiveAt, GETDATE()) < ?";
        List<Integer> ids = new ArrayList<>();
        try (java.sql.Connection cn = com.medicare.config.DBContext.getConnection();
             java.sql.PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, minutesThreshold);
            try (java.sql.ResultSet rs = ps.executeQuery()) {
                while (rs.next()) ids.add(rs.getInt("AccountID"));
            }
        } catch (Exception e) { /* silent */ }
        return ids;
    }
}