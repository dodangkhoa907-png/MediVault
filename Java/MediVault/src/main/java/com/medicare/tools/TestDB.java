package com.medicare.tools;

import com.medicare.config.DBContext;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

public class TestDB {
    public static void main(String[] args) {
        try (Connection cn = DBContext.getConnection();
             Statement st = cn.createStatement();
             ResultSet rs = st.executeQuery("SELECT CategoryID, CategoryName FROM Categories")) {
            while (rs.next()) {
                System.out.println("ID: " + rs.getInt(1) + " - Name: " + rs.getString(2));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
