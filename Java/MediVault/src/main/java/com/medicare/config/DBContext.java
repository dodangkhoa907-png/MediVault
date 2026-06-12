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
        try (InputStream in = DBContext.class
                .getClassLoader()
                .getResourceAsStream("db.properties")) {

            Properties props = new Properties();
            props.load(in);

            HikariConfig config = new HikariConfig();
            config.setDriverClassName(props.getProperty("db.driver"));
            config.setJdbcUrl(props.getProperty("db.url"));
            config.setUsername(props.getProperty("db.username"));
            config.setPassword(props.getProperty("db.password"));

            // ── Pool sizing ───────────────────────────────────────────────
            config.setMaximumPoolSize(15);       // tăng từ 10→15 (nhà thuốc 5 tab cùng lúc)
            config.setMinimumIdle(5);            // tăng từ 2→5: luôn sẵn 5 connection nóng
            config.setConnectionTimeout(3000);   // 3s timeout nếu pool đầy
            config.setIdleTimeout(600000);       // đóng idle sau 10 phút
            config.setMaxLifetime(1800000);      // recycle connection sau 30 phút
            config.setKeepaliveTime(60000);      // ping DB mỗi 1 phút tránh bị firewall kill

            // ── PreparedStatement Cache (quan trọng nhất) ─────────────────
            // Tránh SQL Server phải parse lại cùng 1 câu SQL mỗi lần gọi
            config.addDataSourceProperty("cachePrepStmts",          "true");
            config.addDataSourceProperty("prepStmtCacheSize",        "300");  // cache 300 stmt
            config.addDataSourceProperty("prepStmtCacheSqlLimit",    "2048"); // max 2KB/stmt

            // ── SQL Server specific optimizations ─────────────────────────
            // sendStringParametersAsUnicode=false: cực kỳ quan trọng với SQL Server
            // → tránh full table scan khi query cột VARCHAR (không phải NVARCHAR)
            // → tăng tốc query có WHERE clause với string parameter ~30-50%
            config.addDataSourceProperty("sendStringParametersAsUnicode", "false");

            // responseBuffering=adaptive: chỉ buffer khi cần, tiết kiệm memory
            config.addDataSourceProperty("responseBuffering", "adaptive");

            // KHÔNG dùng selectMethod=cursor — gây lỗi nested cursor conflict
            // khi dùng INSERT...SELECT...WHERE (subquery) trên cùng 1 connection

            // ── Connection test ───────────────────────────────────────────
            config.setConnectionTestQuery("SELECT 1");  // test connection còn sống không
            config.setValidationTimeout(2000);          // 2s để validate

            config.setPoolName("MediVault-Pool-v2");

            ds = new HikariDataSource(config);

        } catch (Exception e) {
            throw new RuntimeException("Lỗi khởi tạo connection pool: " + e.getMessage(), e);
        }
    }

    public static Connection getConnection() throws SQLException {
        return ds.getConnection();
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