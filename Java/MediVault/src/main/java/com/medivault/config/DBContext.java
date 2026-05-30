package com.medivault.config;

import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public class DBContext {

    private static final Properties props = new Properties();

    static {
        try (InputStream in = DBContext.class
                .getClassLoader()
                .getResourceAsStream("db.properties")) {
            props.load(in);
            Class.forName(props.getProperty("db.driver"));
        } catch (Exception e) {
            throw new RuntimeException("Lỗi kết nối DB: " + e.getMessage(), e);
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(
                props.getProperty("db.url"),
                props.getProperty("db.username"),
                props.getProperty("db.password"));
    }

    // Chạy main này để test kết nối DB
    public static void main(String[] args) {
        try (Connection c = getConnection()) {
            System.out.println("Kết nối thành công: " + c.getCatalog());
        } catch (SQLException e) {
            System.err.println("Kết nối thất bại: " + e.getMessage());
        }
    }
}