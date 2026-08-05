package com.medicare.config;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;

/**
 * DBContext v2 — HikariCP tối ưu hóa:
 *   - preparedStatementCache: tránh re-parse SQL mỗi query (~10-20ms/query)
 *   - minimumIdle=5: luôn có 5 connection sẵn sàng
 *   - keepaliveTime: tránh connection bị firewall/DB kill sau idle
 *   - SQL Server specific: sendStringParametersAsUnicode=false (tăng tốc NVARCHAR query ~30%)
 */
public class DBContext {

    private static final HikariDataSource ds;

    static {
        // ══ FIX MÚI GIỜ — PHẢI ĐẶT TRƯỚC TIÊN, TRƯỚC KHI TẠO POOL ══
        // Server host có thể chạy JVM mặc định UTC (không phải giờ VN).
        // JDBC driver SQL Server cache timezone/Calendar tại thời điểm driver
        // được load lần đầu, nên phải set TimeZone.setDefault() ở đây — TRƯỚC
        // khi HikariDataSource (và driver SQL Server bên trong nó) được khởi tạo.
        // Đặt trong @WebListener riêng KHÔNG đủ tin cậy vì thứ tự nạp listener
        // của Tomcat không đảm bảo chạy trước class loading của DBContext.
        java.util.TimeZone vnTz = java.util.TimeZone.getTimeZone("Asia/Ho_Chi_Minh");
        java.util.TimeZone.setDefault(vnTz);
        System.setProperty("user.timezone", "Asia/Ho_Chi_Minh");
        System.out.println("[DBContext] Đã set JVM timezone = Asia/Ho_Chi_Minh. "
                + "Giờ JVM hiện tại: " + new java.util.Date());

        try (InputStream in = DBContext.class
                .getClassLoader()
                .getResourceAsStream("db.properties")) {

            Properties props = new Properties();
            if (in != null) props.load(in);

            // Biến môi trường ĐÈ giá trị trong db.properties — dùng khi deploy Docker/Render.
            // db.properties chỉ còn là fallback cho dev local (chạy trực tiếp trong IDE/Tomcat
            // máy mình), KHÔNG được đóng gói mật khẩu thật vào image production nữa. Đọc biến
            // môi trường trước, rỗng/không có thì mới rơi về giá trị trong file.
            HikariConfig config = new HikariConfig();
            config.setDriverClassName(env("DB_DRIVER", props.getProperty("db.driver")));
            config.setJdbcUrl(env("DB_URL", props.getProperty("db.url")));
            config.setUsername(env("DB_USERNAME", props.getProperty("db.username")));
            config.setPassword(env("DB_PASSWORD", props.getProperty("db.password")));

            // ── Pool sizing ───────────────────────────────────────────────
            // DB đặt từ xa (network latency mỗi query) + click liên tục → cần nhiều
            // connection hơn và CHỜ được connection thay vì fail (đỡ crash).
            config.setMaximumPoolSize(30);       // 15→30: chịu được bùng nổ request khi bấm liên tục
            config.setMinimumIdle(8);            // luôn sẵn 8 connection nóng
            config.setConnectionTimeout(8000);   // 3s→8s: chờ connection thay vì báo lỗi ngay
            config.setIdleTimeout(600000);       // đóng idle sau 10 phút
            config.setMaxLifetime(1800000);      // recycle connection sau 30 phút
            config.setKeepaliveTime(60000);      // ping DB mỗi 1 phút tránh bị firewall kill
            config.setLeakDetectionThreshold(20000); // cảnh báo log nếu connection giữ >20s (bắt rò rỉ)

            // ── PreparedStatement Cache (quan trọng nhất) ─────────────────
            // Tránh SQL Server phải parse lại cùng 1 câu SQL mỗi lần gọi
            config.addDataSourceProperty("cachePrepStmts",          "true");
            config.addDataSourceProperty("prepStmtCacheSize",        "250");  // cache 250 stmt
            config.addDataSourceProperty("prepStmtCacheSqlLimit",    "2048"); // max 2KB/stmt

            // BẮT BUỘC: sendStringParametersAsUnicode=true để lưu tiếng Việt (NVARCHAR) không bị lỗi Mojibake
            config.addDataSourceProperty("sendStringParametersAsUnicode", "true");

            // responseBuffering=adaptive: chỉ buffer khi cần, tiết kiệm memory
            config.addDataSourceProperty("responseBuffering", "adaptive");

            // KHÔNG dùng selectMethod=cursor — gây lỗi nested cursor conflict
            // khi dùng INSERT...SELECT...WHERE (subquery) trên cùng 1 connection

            // ── SET options BẮT BUỘC cho SQL Server ───────────────────────
            // Bảng Medicines có cột tính toán MedicineCode + có indexed view/
            // filtered index trong schema. Mọi INSERT/UPDATE lên các bảng đó
            // yêu cầu các SET option này ON, nếu không sẽ báo:
            //   "UPDATE/INSERT failed because ... SET options ... 'QUOTED_IDENTIFIER'"
            // → khiến thêm thuốc thất bại (msg=error) và ShiftAutoClose lỗi mỗi phút.
            // connectionInitSql chạy 1 lần khi tạo connection vật lý (session-level).
            config.setConnectionInitSql(
                    "SET QUOTED_IDENTIFIER ON; SET ARITHABORT ON; SET ANSI_NULLS ON; "
                  + "SET ANSI_PADDING ON; SET ANSI_WARNINGS ON; "
                  + "SET CONCAT_NULL_YIELDS_NULL ON; SET NUMERIC_ROUNDABORT OFF");

            // ── Connection test ───────────────────────────────────────────
            // KHÔNG set connectionTestQuery: driver mssql-jdbc hỗ trợ JDBC4 isValid(),
            // HikariCP validate bằng isValid() (nhẹ, cục bộ) thay vì bắn "SELECT 1"
            // round-trip tới DB TỪ XA mỗi lần mượn connection → giảm mạnh độ trễ.
            config.setValidationTimeout(2000);          // 2s để validate

            // PHẢI ÂM (-1), KHÔNG được để 0: HikariCP vẫn thử kết nối 1 lần lúc khởi động dù
            // =0, và nếu lần thử đó fail ngay trong bước setup connection (chạy
            // connectionInitSql phía trên — SET QUOTED_IDENTIFIER...) thay vì lúc mở socket,
            // nó ném ConnectionSetupException NGAY LẬP TỨC bất kể initializationFailTimeout=0,

            // làm sập cả Tomcat lúc start (đã xảy ra thực tế: "Read timed out" ngay tại
            // PoolBase.setupConnection). Giá trị ÂM mới thực sự bỏ qua hẳn bước fail-fast này,
            // để pool khởi tạo rỗng và tự tạo connection khi có request đầu tiên.
            config.setInitializationFailTimeout(-1);

            config.setPoolName("MediVault-Pool-v2");

            ds = new HikariDataSource(config);

        } catch (Exception e) {
            throw new RuntimeException("Lỗi khởi tạo connection pool: " + e.getMessage(), e);
        }
    }

    public static Connection getConnection() throws SQLException {
        return ds.getConnection();
    }

    /** Ưu tiên biến môi trường {@code name}; rỗng/không có thì rơi về {@code fallback} (từ db.properties). */
    private static String env(String name, String fallback) {
        String v = System.getenv(name);
        return (v != null && !v.trim().isEmpty()) ? v.trim() : fallback;
    }

    public static void main(String[] args) {
        try (Connection c = getConnection()) {
            System.out.println("✅ Kết nối thành công: " + c.getCatalog());
            System.out.println("   Pool: " + ds.getPoolName());
        } catch (SQLException e) {
            System.err.println("❌ Kết nối thất bại: " + e.getMessage());
        }
    }
}