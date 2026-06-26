package com.medicare.service.interfaces;

import com.medicare.entity.Account;
import com.medicare.service.ServiceResult;

/**
 * IAccountService — Nghiệp vụ quản lý tài khoản nhân viên.
 */
public interface IAccountService {

    /**
     * Tạo tài khoản mới:
     *   1. Validate dữ liệu (username/email/phone/password)
     *   2. Insert vào DB
     *   3. Gửi email thông báo (nếu có email)
     *   4. Gửi thông báo nội bộ cho nhân viên mới
     *
     * @return ServiceResult chứa Account vừa tạo nếu thành công;
     *         fail với danh sách lỗi validation nếu thất bại
     */
    ServiceResult<Account> createAccount(
            String username, String fullName,
            String email, String phone,
            String citizenId, String position,
            int roleId, String password);

    /**
     * Đặt lại mật khẩu cho nhân viên (sau khi admin đã xác nhận OTP):
     *   1. Cập nhật hash mật khẩu
     *   2. Mở khóa tài khoản nếu đang trong reset flow
     *   3. Hoàn tất reset request trong DB
     *   4. Gửi email thông báo cho nhân viên
     *   5. Gửi thông báo nội bộ
     *
     * @param targetId     ID nhân viên cần đặt lại mật khẩu
     * @param newPassword  Mật khẩu mới (plain text — sẽ được hash trong service)
     * @param isResetFlow  true = staff đã yêu cầu forgot-password (cần mở khóa)
     */
    ServiceResult<Void> setPassword(int targetId, String newPassword, boolean isResetFlow);
}
