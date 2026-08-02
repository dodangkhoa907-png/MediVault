package com.medicare.util;

import com.medicare.entity.Account;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.util.Enumeration;

/**
 * WarehouseAuth — nguồn sự thật DUY NHẤT về "ai đang đăng nhập portal Kho".
 *
 * <p>Trước đây mỗi servlet Kho tự đọc {@code request.getParameter("uid")} rồi tra
 * {@code session.getAttribute("staffAccount_" + uid)}. Hệ quả:</p>
 * <ul>
 *   <li>ID tài khoản lộ trên thanh địa chỉ ({@code ?uid=20}) và nằm lại trong lịch sử
 *       trình duyệt — máy dùng chung là người sau đọc được.</li>
 *   <li>10 servlet có 10 bản sao cùng một đoạn kiểm tra, lệch nhau là sinh lỗ hổng.</li>
 *   <li>Mất {@code uid} khi chuyển trang là văng về màn đăng nhập dù session vẫn sống.</li>
 * </ul>
 *
 * <p>Nay danh tính lấy TỪ SESSION, không lấy từ URL. URL sạch: {@code /warehouse-inventory}.</p>
 *
 * <p><b>Vì sao vẫn phải quét {@code staffAccount_*}:</b> Thủ kho vào hệ thống được bằng
 * HAI cửa — {@code /warehouse-login} (đặt sẵn {@code warehouseUser}) và {@code /staff-login}
 * (roleId 3 cũng bị đẩy sang /warehouse-dashboard nhưng chỉ đặt {@code staffAccount_<id>}).
 * Bỏ nhánh quét là cửa thứ hai gãy, và mọi phiên đang đăng nhập sẵn lúc triển khai cũng bị
 * đá ra. Quét xong thì ghi lại vào {@code warehouseUser} để các request sau đi đường nhanh.</p>
 */
public final class WarehouseAuth {

    /** Khoá session chuẩn cho người dùng portal Kho. */
    public static final String SESSION_KEY = "warehouseUser";

    /** roleId của Thủ kho / Quản lý kho. */
    private static final int ROLE_WAREHOUSE = 3;

    private WarehouseAuth() {}

    /**
     * Ghi danh tính Thủ kho vào session — gọi NGAY SAU khi đăng nhập thành công.
     * Chỉ ghi khi đúng roleId 3 để không có đường nào đưa nhầm vai trò khác vào portal Kho.
     */
    public static void login(HttpSession session, Account acc) {
        if (session == null || acc == null) return;
        if (acc.getRoleId() != ROLE_WAREHOUSE) return;
        session.setAttribute(SESSION_KEY, acc);
    }

    /**
     * Thủ kho đang đăng nhập trên session này, hoặc {@code null} nếu không có.
     * KHÔNG đọc bất kỳ tham số nào từ URL.
     */
    public static Account current(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) return null;

        Object direct = session.getAttribute(SESSION_KEY);
        if (direct instanceof Account acc && acc.getRoleId() == ROLE_WAREHOUSE) {
            return acc;
        }

        // Vào bằng /staff-login, hoặc phiên đã mở từ trước bản cập nhật này.
        Enumeration<String> names = session.getAttributeNames();
        while (names.hasMoreElements()) {
            String name = names.nextElement();
            if (!name.startsWith("staffAccount_")) continue;
            if (session.getAttribute(name) instanceof Account acc
                    && acc.getRoleId() == ROLE_WAREHOUSE) {
                session.setAttribute(SESSION_KEY, acc);   // nâng cấp phiên cũ
                return acc;
            }
        }
        return null;
    }

    /**
     * Như {@link #current} nhưng tự đẩy về trang đăng nhập Kho khi chưa có danh tính.
     *
     * @return Account nếu hợp lệ; {@code null} nghĩa là ĐÃ redirect — servlet phải
     *         {@code return} ngay, không được ghi gì thêm vào response.
     */
    public static Account require(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        Account acc = current(req);
        if (acc == null) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login");
            return null;
        }
        // JSP Kho vẫn đọc 2 attribute này để render tên/ảnh đại diện và badge sidebar.
        req.setAttribute("staffAcc", acc);
        req.setAttribute("staffUid", String.valueOf(acc.getAccountId()));
        return acc;
    }
}
