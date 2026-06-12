package com.medicare.util;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

/**
 * ValidationUtil — Kiểm tra tính hợp lệ dữ liệu đầu vào
 *
 * Cách dùng trong DAO/Servlet:
 *   List<String> errors = ValidationUtil.validateAccount(username, email, phone, ...);
 *   if (!errors.isEmpty()) { // có lỗi → không insert }
 */
public class ValidationUtil {

    // ── Regex patterns ──────────────────────────────────────
    // Email: có @ và domain hợp lệ
    private static final Pattern EMAIL =
            Pattern.compile("^[a-zA-Z0-9._%+\\-]+@[a-zA-Z0-9.\\-]+\\.[a-zA-Z]{2,}$");

    // Phone VN: 0 + 9 số (tổng 10), hoặc +84 + 9 số
    private static final Pattern PHONE =
            Pattern.compile("^(0[3-9][0-9]{8}|\\+84[3-9][0-9]{8})$");

    // Username: chữ/số/dấu gạch dưới, 4-50 ký tự
    private static final Pattern USERNAME =
            Pattern.compile("^[a-zA-Z0-9_]{4,50}$");

    // CMND/CCCD: 9 hoặc 12 số
    private static final Pattern CITIZEN_ID =
            Pattern.compile("^[0-9]{9}$|^[0-9]{12}$");

    // Mật khẩu: ít nhất 6 ký tự, KHÔNG chứa khoảng trắng bất kỳ
    private static final Pattern PASSWORD =
            Pattern.compile("^[^\\s]{6,}$");

    // ── Public validators ────────────────────────────────────

    /** Kiểm tra email hợp lệ */
    public static boolean isValidEmail(String email) {
        return email != null && EMAIL.matcher(email.trim()).matches();
    }

    /** Kiểm tra số điện thoại VN hợp lệ */
    public static boolean isValidPhone(String phone) {
        return phone != null && PHONE.matcher(phone.trim()).matches();
    }

    /** Kiểm tra username hợp lệ */
    public static boolean isValidUsername(String username) {
        return username != null && USERNAME.matcher(username.trim()).matches();
    }

    /** Kiểm tra CMND/CCCD hợp lệ */
    public static boolean isValidCitizenId(String id) {
        return id == null || id.trim().isEmpty() || CITIZEN_ID.matcher(id.trim()).matches();
    }

    /** Kiểm tra chuỗi không rỗng */
    public static boolean notBlank(String s) {
        return s != null && !s.trim().isEmpty();
    }

    /** Kiểm tra độ dài tối đa */
    public static boolean maxLength(String s, int max) {
        return s == null || s.trim().length() <= max;
    }

    /** Kiểm tra mật khẩu: ít nhất 6 ký tự, không chứa khoảng trắng */
    public static boolean isValidPassword(String pw) {
        return pw != null && PASSWORD.matcher(pw).matches();
    }

    // ── Validate Account (dùng trước insert/update) ─────────

    /**
     * Validate đầy đủ cho Account.
     * @return danh sách lỗi (rỗng = hợp lệ)
     */
    public static List<String> validateAccount(String username, String fullName,
                                               String email, String phone,
                                               String citizenId, String position) {

        List<String> errors = new ArrayList<>();

        // Username
        if (!notBlank(username))
            errors.add("Tên đăng nhập không được để trống.");
        else if (!isValidUsername(username))
            errors.add("Tên đăng nhập chỉ gồm chữ, số, dấu gạch dưới (4-50 ký tự).");

        // Họ tên
        if (!notBlank(fullName))
            errors.add("Họ tên không được để trống.");
        else if (!maxLength(fullName, 200))
            errors.add("Họ tên không quá 200 ký tự.");

        // Email
        if (notBlank(email) && !isValidEmail(email))
            errors.add("Email không đúng định dạng (ví dụ: abc@gmail.com).");

        // Số điện thoại
        if (notBlank(phone) && !isValidPhone(phone))
            errors.add("Số điện thoại không hợp lệ (phải là 10 số, bắt đầu bằng 03x-09x).");

        // CMND/CCCD
        if (notBlank(citizenId)) {
            String cid = citizenId.trim();
            if (cid.length() != 9 && cid.length() != 12) {
                errors.add("Số CMND/CCCD không hợp lệ (phải có đúng 9 hoặc 12 chữ số).");
            } else if (!cid.matches("^[0-9]+$")) {
                errors.add("Số CMND/CCCD chỉ được chứa các ký tự số.");
            }
        }

        // Chức vụ
        if (notBlank(position) && position.trim().length() > 100) {
            errors.add("Chức vụ nhập vào quá dài (không được vượt quá 100 ký tự).");
        }
        return errors;

    }

    /**
     * Validate nhanh cho Customer.
     */
    public static List<String> validateCustomer(String customerName, String phone, String email) {
        List<String> errors = new ArrayList<>();

        if (!notBlank(customerName))
            errors.add("Tên khách hàng không được để trống.");
        else if (!maxLength(customerName, 100))
            errors.add("Tên khách hàng không quá 100 ký tự.");

        if (notBlank(phone) && !isValidPhone(phone))
            errors.add("Số điện thoại không hợp lệ.");

        if (notBlank(email) && !isValidEmail(email))
            errors.add("Email không đúng định dạng.");

        return errors;
    }

    /**
     * Gộp list lỗi thành 1 chuỗi hiển thị trên JSP.
     * Dùng: String msg = ValidationUtil.joinErrors(errors);
     */
    public static String joinErrors(List<String> errors) {
        return String.join(" | ", errors);
    }
    public static boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }
}