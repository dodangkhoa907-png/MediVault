package com.medicare.dao.interfaces;

import com.medicare.entity.Account;
import java.util.List;

public interface IAccountDAO {
    Account findByUsername(String username);
    /** Tìm kể cả TK bị khóa (IsActive=0) — dùng cho login */
    Account findByUsernameAny(String username);
    /** Tìm theo email, kể cả TK bị khóa — dùng cho quên mật khẩu chỉ nhập email (vd Quản lý kho) */
    Account findByEmailAny(String email);
    Account findById(int id);
    List<Account> findAll();
    boolean insert(Account a);
    boolean updateLastLogin(int accountId);
    boolean toggleActive(int accountId);
    boolean resetPassword(int accountId, String newHash);
    boolean isEmailTaken(String email, int excludeId);
    boolean isPhoneTaken(String phone, int excludeId);
    boolean isCitizenIdTaken(String citizenId, int excludeId);
    boolean update(Account a);
    boolean isUsernameTaken(String username);
    int countActiveAdmins();
    boolean softDelete(int accountId);
    boolean restore(int accountId);
    boolean hardDelete(int accountId);
    List<Account> findDeleted();
    List<Account> findAllStaff();
    boolean forceDelete(int accountId);
    boolean updateAvatar(int accountId, String path);
    /** Lưu đường dẫn file PDF giấy phép hành nghề đã upload (bằng chứng thật). */
    boolean updateLicenseFilePath(int accountId, String path);
    /** Lưu Face Vector (JSON array 128 số) + cập nhật FaceEnrolledAt = GETDATE() */
    boolean updateFaceVector(int accountId, String faceVectorJson);
    /** Lấy danh sách (accountId, faceVector) của toàn bộ staff đã đăng ký mặt — dùng cho verification */
    List<Account> findAllWithFaceVector();
    /** Truy xuất hàng loạt account dựa trên list ID (giải quyết N+1 queries) */
    List<Account> findAccountsByIds(List<Integer> ids);
    /** Presence tracking: cập nhật thời điểm staff còn active (gọi mỗi ping) */
    void updateLastActive(int accountId);
    /** Presence tracking: trả về danh sách accountId đã ping trong N phút gần nhất */
    List<Integer> findOnlineAccountIds(int minutesThreshold);

    // ── Face re-enroll request flow ──
    boolean requestFaceReenroll(int accountId, String reason);
    boolean approveFaceReenroll(int accountId, int adminId);
    boolean rejectFaceReenroll(int accountId, int adminId, String note);
    List<Account> findPendingFaceReenroll();
    List<String> findActiveAdminEmails();
}