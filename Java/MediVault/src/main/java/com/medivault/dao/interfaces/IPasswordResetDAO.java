package com.medivault.dao.interfaces;

import com.medivault.entity.PasswordResetRequest;
import java.util.List;

public interface IPasswordResetDAO {
    // Tạo yêu cầu mới
    boolean insert(PasswordResetRequest req);

    // Tìm theo token — admin click link mail
    PasswordResetRequest findByToken(String token);

    // Tìm PENDING của 1 staff — kiểm tra đã có yêu cầu chưa
    PasswordResetRequest findPendingByAccountId(int accountId);

    // Tìm CONFIRMED của 1 staff — dùng khi admin đặt mật khẩu mới để auto mở khóa
    PasswordResetRequest findConfirmedByAccountId(int accountId);

    // Lấy tất cả PENDING + CONFIRMED — hiện badge trong account-list
    List<PasswordResetRequest> findAllPending();

    // Cập nhật status → CONFIRMED (admin xác nhận)
    boolean confirm(String token);

    // Cập nhật status → COMPLETED (admin đặt mật khẩu mới xong)
    boolean complete(int accountId);

    // Expire các request quá hạn — gọi định kỳ hoặc khi check
    boolean expireOld();

    int countTodayByAccountId(int accountId);
    // Lấy danh sách account bị chặn hôm nay (>= 3 lần)
    List<Integer> findBlockedAccountIds();

    // Reset count hôm nay về 0 — admin unlock
    boolean resetTodayCount(int accountId);


}