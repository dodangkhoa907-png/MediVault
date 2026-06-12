package com.medicare.config;

import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.SQLException;
import java.util.Properties;

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

            // Pool settings
            config.setMaximumPoolSize(10);       // tối đa 10 connection dùng song song
            config.setMinimumIdle(2);            // giữ sẵn 2 connection
            config.setConnectionTimeout(3000);   // timeout 3s nếu pool đầy
            config.setIdleTimeout(600000);       // đóng connection rảnh sau 10 phút
            config.setMaxLifetime(1800000);      // tái tạo connection sau 30 phút
            config.setPoolName("MediVault-Pool");

            ds = new HikariDataSource(config);

        } catch (Exception e) {
            throw new RuntimeException("Lỗi khởi tạo connection pool: " + e.getMessage(), e);
        }
    }

    public static Connection getConnection() throws SQLException {
        return ds.getConnection(); // lấy từ pool — nhanh hơn ~100x so với tạo mới
    }

    // Test kết nối
    public static void main(String[] args) {
        try (Connection c = getConnection()) {
            System.out.println("Kết nối thành công: " + c.getCatalog());
        } catch (SQLException e) {
            System.err.println("Kết nối thất bại: " + e.getMessage());
        }
    }
}