import java.sql.*;

public class TestDB {
    public static void main(String[] args) throws Exception {
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        try (Connection c = DriverManager.getConnection(
                "jdbc:sqlserver://14.225.217.109;databaseName=PharmacyPro_DB;encrypt=true;trustServerCertificate=true",
                "sa", "TOP1@iyounguru!")) {
            System.out.println("Categories:");
            try (Statement s = c.createStatement();
                    ResultSet rs = s.executeQuery("SELECT CategoryId, CategoryName FROM Categories")) {
                while (rs.next()) {
                    System.out.println(rs.getInt(1) + ": " + rs.getString(2));
                }
            }
            System.out.println("Medicines:");
            try (Statement s = c.createStatement();
                    ResultSet rs = s.executeQuery("SELECT MedicineId, MedicineName, Unit FROM Medicines")) {
                while (rs.next()) {
                    System.out.println(rs.getInt(1) + ": " + rs.getString(2) + " [" + rs.getString(3) + "]");
                }
            }
        }
    }
}
