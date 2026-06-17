package com.medicare.controller;

import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;
import java.util.TimeZone;

/**
 * AppTimeZoneListener — Ép JVM của Tomcat chạy theo giờ Việt Nam (Asia/Ho_Chi_Minh, UTC+7).
 *
 * VẤN ĐỀ ĐÃ XẢY RA: Server host ở nước ngoài, JVM mặc định chạy theo UTC.
 * Mọi LocalDateTime.now() trong toàn bộ code (StaffAttendanceServlet, ShiftDAO,
 * InvoiceDAO, AuditHelper...) đều trả về giờ UTC, lệch 7 giờ so với giờ thật VN.
 * Điều này gây sai lệch nghiêm trọng: giờ check-in/check-out, tính phạt trễ giờ,
 * giờ trên audit log, đồng hồ hiển thị trên dashboard — tất cả đều sai.
 *
 * GIẢI PHÁP: Set TimeZone.setDefault() ngay khi ServletContext khởi tạo (trước khi
 * bất kỳ servlet/filter nào chạy). Từ đây, mọi LocalDateTime.now(), new Date(),
 * Calendar.getInstance() trong toàn app đều tự động dùng giờ VN — không cần sửa
 * từng dòng code rải rác ở hàng chục file.
 *
 * LƯU Ý QUAN TRỌNG: Listener này phải được Tomcat nạp SỚM NHẤT. Servlet 3.0+ tự động
 * quét @WebListener nên không cần khai báo trong web.xml, nhưng nếu muốn chắc chắn
 * thứ tự nạp, có thể thêm <listener> đầu tiên trong web.xml.
 */
@WebListener
public class AppTimeZoneListener implements ServletContextListener {

    private static final String APP_TIMEZONE = "Asia/Ho_Chi_Minh";

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        TimeZone vnTimeZone = TimeZone.getTimeZone(APP_TIMEZONE);
        TimeZone.setDefault(vnTimeZone);
        System.setProperty("user.timezone", APP_TIMEZONE);

        System.out.println("[AppTimeZoneListener] JVM timezone set to "
                + APP_TIMEZONE + " — current JVM time: " + new java.util.Date());
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        // Không cần xử lý
    }
}