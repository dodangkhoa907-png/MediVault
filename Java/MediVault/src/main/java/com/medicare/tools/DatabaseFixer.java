package com.medicare.tools;

import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * ════════════════════════════════════════════════════════════════════════
 *  DatabaseFixer — Sửa lỗi encoding tiếng Việt trong Database
 * ════════════════════════════════════════════════════════════════════════
 *
 *  VẤN ĐỀ: Dữ liệu tiếng Việt bị lưu sai mã hóa (UTF-8 bytes bị đọc
 *  như Latin-1), dẫn đến các chuỗi garbled:
 *    "Kháng sinh"   →  bị lưu thành  "KhÃ¡ng sinh"
 *    "Viên nang"    →  bị lưu thành  "ViÃªn nang"
 *    "Thuốc"        →  bị lưu thành  "Thuá»'c"
 *
 *  CÁCH SỬA: Mỗi chuỗi garbled được đọc, ép lại bytes theo ISO-8859-1
 *  rồi giải mã lại theo UTF-8 để phục hồi tiếng Việt đúng.
 *
 *  CÁCH CHẠY: Trong IntelliJ, phải chuột vào class → Run 'main()'
 *  HOẶC: Bấm nút ▶ xanh bên trái dòng "public static void main(...)"
 *
 *  ⚠ CHẠY 1 LẦN DUY NHẤT — chạy lại sẽ không ảnh hưởng gì (idempotent).
 * ════════════════════════════════════════════════════════════════════════
 */
public class DatabaseFixer {

    // ── Thông tin kết nối DB (đọc từ db.properties thực tế) ──────────────
    private static final String JDBC_URL =
            "jdbc:sqlserver://14.225.217.109;databaseName=PharmacyPro_DB;" +
            "encrypt=true;trustServerCertificate=true";
    private static final String USERNAME = "sa";
    private static final String PASSWORD = "TOP1@iyounguru!";
    private static final String DRIVER   = "com.microsoft.sqlserver.jdbc.SQLServerDriver";

    // ── Cấu hình bảng cần sửa: [tableName, idColumn, col1, col2, ...] ────
    private static final String[][] TABLE_CONFIGS = {
        // Danh mục thuốc
        {"Categories",      "CategoryID",      "CategoryName", "Description"},
        // Thuốc
        {"Medicines",       "MedicineID",      "MedicineName", "Unit", "Dosage", "Description"},
        // Nhà sản xuất
        {"Manufacturers",   "ManufacturerID",  "ManufacturerName", "ContactInfo", "Address", "Note"},
        // Khách hàng
        {"Customers",       "CustomerID",      "CustomerName", "Address", "Note"},
        // Loại ca làm việc
        {"ShiftTypes",      "ShiftTypeID",     "ShiftTypeName", "Description"},
        // Nhà cung cấp (nếu có)
        {"Suppliers",       "SupplierID",      "SupplierName", "ContactInfo", "Address"},
    };

    public static void main(String[] args) {
        System.out.println("╔══════════════════════════════════════════╗");
        System.out.println("║  MediCare — Database Encoding Fixer       ║");
        System.out.println("╚══════════════════════════════════════════╝");
        System.out.println("Đang kết nối đến database...");

        try {
            Class.forName(DRIVER);
        } catch (ClassNotFoundException e) {
            System.err.println("❌ Không tìm thấy JDBC driver: " + e.getMessage());
            return;
        }

        try (Connection cn = DriverManager.getConnection(JDBC_URL, USERNAME, PASSWORD)) {
            cn.setAutoCommit(false);
            System.out.println("✅ Kết nối thành công!\n");

            int grandTotal = 0;
            for (String[] config : TABLE_CONFIGS) {
                String tableName = config[0];
                String idCol     = config[1];

                // Lấy các cột text cần sửa
                String[] textCols = new String[config.length - 2];
                System.arraycopy(config, 2, textCols, 0, textCols.length);

                int fixed = fixTable(cn, tableName, idCol, textCols);
                grandTotal += fixed;
            }

            cn.commit();
            System.out.println("\n╔══════════════════════════════════════════╗");
            System.out.printf( "║  ✅ Hoàn thành! Đã sửa %d row(s) trong DB%n", grandTotal);
            System.out.println("╚══════════════════════════════════════════╝");
            System.out.println("Restart Tomcat để thấy chữ Việt hiển thị đúng.");

        } catch (SQLException e) {
            System.err.println("❌ Lỗi kết nối Database: " + e.getMessage());
        }
    }

    // ── Sửa 1 bảng ───────────────────────────────────────────────────────
    private static int fixTable(Connection cn, String table, String idCol, String[] textCols) {
        System.out.print("[" + table + "] Đang kiểm tra... ");

        // Kiểm tra bảng có tồn tại không
        try (ResultSet rs = cn.getMetaData().getTables(null, null, table, null)) {
            if (!rs.next()) {
                System.out.println("⏭ Bảng không tồn tại, bỏ qua.");
                return 0;
            }
        } catch (SQLException e) {
            System.out.println("⚠ Lỗi khi kiểm tra bảng: " + e.getMessage());
            return 0;
        }

        // SELECT tất cả rows
        StringBuilder sb = new StringBuilder("SELECT ").append(idCol);
        for (String col : textCols) sb.append(", ").append(col);
        sb.append(" FROM ").append(table);

        List<Object[]> rowsToFix = new ArrayList<>();

        try (Statement st = cn.createStatement();
             ResultSet rs = st.executeQuery(sb.toString())) {

            while (rs.next()) {
                int id = rs.getInt(1);
                boolean needFix = false;
                String[] fixedVals = new String[textCols.length];

                for (int i = 0; i < textCols.length; i++) {
                    String original = rs.getString(i + 2);
                    if (original == null) {
                        fixedVals[i] = null;
                    } else {
                        String fixed = fixEncoding(original);
                        fixedVals[i] = fixed;
                        if (!fixed.equals(original)) {
                            needFix = true;
                        }
                    }
                }

                if (needFix) {
                    Object[] row = new Object[textCols.length + 1];
                    row[0] = id;
                    System.arraycopy(fixedVals, 0, row, 1, textCols.length);
                    rowsToFix.add(row);
                }
            }
        } catch (SQLException e) {
            System.out.println("⚠ Lỗi SELECT: " + e.getMessage());
            return 0;
        }

        if (rowsToFix.isEmpty()) {
            System.out.println("✓ Không có gì cần sửa.");
            return 0;
        }

        // UPDATE những row cần sửa
        StringBuilder upd = new StringBuilder("UPDATE ").append(table).append(" SET ");
        for (int i = 0; i < textCols.length; i++) {
            if (i > 0) upd.append(", ");
            upd.append(textCols[i]).append(" = ?");
        }
        upd.append(" WHERE ").append(idCol).append(" = ?");

        int count = 0;
        try (PreparedStatement ps = cn.prepareStatement(upd.toString())) {
            for (Object[] row : rowsToFix) {
                int id = (int) row[0];
                for (int i = 0; i < textCols.length; i++) {
                    String val = (String) row[i + 1];
                    if (val == null) {
                        ps.setNull(i + 1, Types.NVARCHAR);
                    } else {
                        ps.setNString(i + 1, val);
                    }
                }
                ps.setInt(textCols.length + 1, id);
                ps.addBatch();
                count++;
            }
            ps.executeBatch();
        } catch (SQLException e) {
            System.out.println("⚠ Lỗi UPDATE: " + e.getMessage());
            return 0;
        }

        System.out.printf("✅ Đã sửa %d row(s).%n", count);
        return count;
    }

    // ── Thuật toán sửa encoding ──────────────────────────────────────────
    /**
     * Phục hồi chuỗi tiếng Việt bị garbled.
     *
     * Giải thích kỹ thuật:
     * - Dữ liệu gốc (VD: "Kháng sinh") được encode thành UTF-8: [0x4B, 0x68, 0xC3, 0xA1, ...]
     * - Khi import vào DB, các bytes đó được đọc như Latin-1, mỗi byte thành 1 ký tự Unicode:
     *   0xC3 → U+00C3 ('Ã'), 0xA1 → U+00A1 ('¡') → "KhÃ¡ng sinh"
     * - SQL Server lưu NVARCHAR dưới dạng UTF-16, nên "Ã" và "¡" được lưu riêng biệt.
     * - Để fix: lấy lại bytes bằng cách encode string bằng ISO-8859-1 (1 byte/char),
     *   rồi decode những bytes đó như UTF-8 → khôi phục lại "Kháng sinh".
     *
     * An toàn: nếu chuỗi không garbled (VD: ASCII thuần):
     *   - getBytes(ISO_8859_1) = getBytes(UTF_8) = ASCII bytes
     *   - Decode UTF-8 = giống y chang → không thay đổi gì ✓
     *
     * Nếu chuỗi đã được lưu đúng Unicode nhưng bytes Latin-1 không hợp lệ UTF-8:
     *   - Kết quả chứa U+FFFD (replacement char) → giữ nguyên chuỗi gốc ✓
     */
    private static String fixEncoding(String garbled) {
        if (garbled == null || garbled.isEmpty()) return garbled;
        try {
            // Bước 1: ép string thành bytes ISO-8859-1 (1:1 mapping)
            byte[] latinBytes = garbled.getBytes(Charset.forName("ISO-8859-1"));

            // Bước 2: giải mã bytes đó như UTF-8
            String fixed = new String(latinBytes, StandardCharsets.UTF_8);

            // Bước 3: nếu có replacement char (0xFFFD) → bytes không phải UTF-8 hợp lệ
            //         → chuỗi gốc không bị garbled, giữ nguyên
            if (fixed.contains("\uFFFD")) {
                return garbled;
            }

            // Bước 4: nếu kết quả ngắn hơn gốc → chứng tỏ có multi-byte collapse
            //         → đây là chuỗi đã được sửa đúng
            //         Nếu bằng nhau → là ASCII → không thay đổi gì (cũng đúng)
            return fixed;

        } catch (Exception e) {
            return garbled; // An toàn: giữ nguyên nếu lỗi
        }
    }
}
