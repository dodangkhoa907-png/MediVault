package com.medicare.tools;

import com.medicare.config.DBContext;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

public class FixDB {
    public static void main(String[] args) {
        try (Connection cn = DBContext.getConnection()) {
            System.out.println("Checking Categories...");
            try (PreparedStatement ps = cn.prepareStatement("SELECT CategoryID, CategoryName FROM Categories");
                 ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    System.out.println(rs.getInt(1) + ": " + rs.getString(2));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
