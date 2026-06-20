package com.medicare.util;

import com.medicare.dao.StaffNotificationDAO;
import java.time.LocalDateTime;

/**
 * StaffNotifHelper — helper tĩnh để tạo notification cho nhân viên.
 * Gọi từ AccountServlet, ShiftServlet, LeaveRequestServlet...
 */
public class StaffNotifHelper {

    private static final StaffNotificationDAO dao = new StaffNotificationDAO();

    /** TK vừa được tạo */
    public static void accountCreated(int accountId, String fullName) {
        dao.insert(accountId, "ACCOUNT_CREATED",
                "🎉 Chào mừng " + fullName + "!",
                "Tài khoản của bạn đã được tạo thành công. Liên hệ Admin để nhận mật khẩu đăng nhập.");
    }

    /** Nhắc nhở đăng ký khuôn mặt (gửi ngay sau khi tạo tài khoản) */
    public static void faceEnrollReminder(int accountId) {
        dao.insert(accountId, "FACE_ENROLL_REMINDER",
                "📷 Bạn chưa đăng ký khuôn mặt",
                "Hãy đăng ký khuôn mặt ngay để có thể điểm danh nhanh bằng khuôn mặt. Vào Dashboard để đăng ký.");
    }

    /** Được xếp ca làm việc */
    public static void shiftAssigned(int accountId, String shiftTypeName, String dateStr) {
        dao.insert(accountId, "SHIFT_ASSIGNED",
                "📅 Ca mới: " + shiftTypeName,
                "Bạn được xếp " + shiftTypeName + " vào ngày " + dateStr + ".");
    }

    /** Được xếp ca bulk (nhiều ngày) */
    public static void shiftAssignedBulk(int accountId, int shiftCount, String dateRange) {
        dao.insert(accountId, "SHIFT_ASSIGNED",
                "📅 Xếp " + shiftCount + " ca mới",
                "Bạn được xếp " + shiftCount + " ca làm trong khoảng " + dateRange + ". Kiểm tra lịch ca.");
    }

    /** Nhắc nhở trước ca (15 phút) — có thời hạn */
    public static void shiftReminder(int accountId, String shiftTypeName, String time) {
        dao.insert(accountId, "SHIFT_REMINDER",
                "⏰ Sắp tới ca: " + shiftTypeName,
                "Ca " + shiftTypeName + " bắt đầu lúc " + time + ". Hãy chuẩn bị!",
                LocalDateTime.now().plusHours(2)); // Hết hạn sau 2 giờ
    }

    /** Đơn nghỉ phép được duyệt */
    public static void leaveApproved(int accountId, String dateRange) {
        dao.insert(accountId, "LEAVE_APPROVED",
                "✅ Đơn nghỉ phép được duyệt",
                "Đơn nghỉ phép " + dateRange + " đã được Admin phê duyệt.");
    }

    /** Đơn nghỉ phép bị từ chối */
    public static void leaveRejected(int accountId, String dateRange, String reason) {
        dao.insert(accountId, "LEAVE_REJECTED",
                "❌ Đơn nghỉ phép bị từ chối",
                "Đơn nghỉ phép " + dateRange + " bị từ chối" + (reason != null ? ": " + reason : "."));
    }

    /** Mật khẩu đã được reset */
    public static void passwordReset(int accountId) {
        dao.insert(accountId, "PASSWORD_RESET",
                "🔑 Mật khẩu đã được đặt lại",
                "Mật khẩu của bạn đã được Admin đặt lại. Liên hệ Admin để nhận mật khẩu mới.");
    }

    /** Thông báo chung */
    public static void general(int accountId, String title, String message) {
        dao.insert(accountId, "GENERAL", title, message);
    }
}