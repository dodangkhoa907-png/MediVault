package com.medicare.controller.admin;

import com.medicare.config.DBContext;
import com.medicare.entity.Account;
import com.medicare.util.MojibakeUtil;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.*;

/**
 * Servlet sửa lỗi encoding một lần — chỉ dùng khi cần repair dữ liệu mojibake trong DB.
 * Truy cập: GET /admin/fix-encoding (chỉ admin)
 */
@WebServlet("/admin/fix-encoding")
public class EncodingRepairServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        if (!isAdmin(req)) { resp.sendRedirect(req.getContextPath() + "/login"); return; }
        resp.setContentType("text/html;charset=UTF-8");
        PrintWriter out = resp.getWriter();
        out.println("""
            <!DOCTYPE html><html lang="vi"><head><meta charset="UTF-8">
            <title>Sửa lỗi Encoding — MediVault Admin</title>
            <style>
            body{font-family:system-ui,sans-serif;max-width:720px;margin:40px auto;padding:20px;background:#f5f7fa}
            h1{color:#0F2645;font-size:22px}
            .warn{background:#FFFBEB;border:1px solid #FDE68A;border-radius:10px;padding:14px 18px;margin:20px 0;color:#92400E;font-size:14px}
            table{width:100%;border-collapse:collapse;margin:16px 0;font-size:13px}
            th{background:#0F2645;color:#fff;padding:10px 12px;text-align:left}
            td{padding:8px 12px;border-bottom:1px solid #E2E8F0}
            tr:nth-child(even) td{background:#f8fafc}
            .btn{display:inline-block;padding:12px 28px;background:#DC2626;color:#fff;border:none;border-radius:10px;font-size:15px;font-weight:700;cursor:pointer;font-family:inherit}
            .btn:hover{background:#b91c1c}
            .info{font-size:13px;color:#64748B;margin-bottom:8px}
            </style></head><body>
            <h1>🔧 Sửa lỗi Mojibake — Encoding Repair Tool</h1>
            <div class="warn">
            ⚠️ Công cụ này sẽ đọc tất cả dữ liệu văn bản tiếng Việt trong DB, áp dụng thuật toán
            giải mã UTF-8 bị lưu nhầm sang Windows-1252, và cập nhật lại những dòng bị lỗi.
            Chỉ chạy <strong>một lần</strong> hoặc khi DB được seed lại với dữ liệu cũ.
            </div>
            <p class="info">Các bảng sẽ được kiểm tra và sửa:</p>
            <table>
            <tr><th>Bảng</th><th>Cột văn bản tiếng Việt</th></tr>
            <tr><td>Categories</td><td>CategoryName, Description</td></tr>
            <tr><td>Medicines</td><td>MedicineName, GenericName, Unit, Dosage, Contraindications, StorageConditions</td></tr>
            <tr><td>Manufacturers</td><td>ManufacturerName, Address</td></tr>
            <tr><td>Suppliers</td><td>SupplierName, ContactName, Address</td></tr>
            <tr><td>Shelves</td><td>ShelfName, LocationNotes</td></tr>
            <tr><td>Customers</td><td>CustomerName, Address, Occupation, AllergyHistory, ChronicDisease</td></tr>
            </table>
            <form method="post">
            <button type="submit" class="btn">▶ Chạy Repair</button>
            </form>
            </body></html>
            """);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        if (!isAdmin(req)) { resp.sendRedirect(req.getContextPath() + "/login"); return; }
        resp.setContentType("text/html;charset=UTF-8");
        PrintWriter out = resp.getWriter();

        Map<String, int[]> results = new LinkedHashMap<>();
        List<String> errors = new ArrayList<>();

        try {
            results.put("Categories", repairCategories(errors));
            results.put("Medicines", repairMedicines(errors));
            results.put("Manufacturers", repairManufacturers(errors));
            results.put("Suppliers", repairSuppliers(errors));
            results.put("Shelves", repairShelves(errors));
            results.put("Customers", repairCustomers(errors));
        } catch (Exception e) {
            errors.add("Lỗi nghiêm trọng: " + e.getMessage());
        }

        int totalChecked = results.values().stream().mapToInt(a -> a[0]).sum();
        int totalFixed   = results.values().stream().mapToInt(a -> a[1]).sum();

        out.println("<!DOCTYPE html><html lang=\"vi\"><head><meta charset=\"UTF-8\">");
        out.println("<title>Kết quả Repair</title>");
        out.println("<style>body{font-family:system-ui,sans-serif;max-width:720px;margin:40px auto;padding:20px;background:#f5f7fa}");
        out.println("h1{color:#0F2645}h2{font-size:16px;margin-top:28px}");
        out.println(".ok{background:#D1FAE5;border:1px solid #6EE7B7;border-radius:10px;padding:14px 18px;color:#065F46;font-size:14px;margin-bottom:20px}");
        out.println(".err{background:#FEE2E2;border:1px solid #FCA5A5;border-radius:10px;padding:14px 18px;color:#7F1D1D;font-size:13px;margin-bottom:16px}");
        out.println("table{width:100%;border-collapse:collapse;font-size:13px}");
        out.println("th{background:#0F2645;color:#fff;padding:10px 12px;text-align:left}");
        out.println("td{padding:8px 12px;border-bottom:1px solid #E2E8F0}");
        out.println("tr:nth-child(even) td{background:#f8fafc}");
        out.println(".fixed{color:#059669;font-weight:700}.none{color:#94A3B8}");
        out.println("a{color:#1558A8}</style></head><body>");
        out.println("<h1>✅ Kết quả Repair</h1>");
        out.printf("<div class=\"ok\">Đã kiểm tra <strong>%d</strong> dòng, sửa <strong>%d</strong> dòng bị lỗi encoding.</div>%n",
                totalChecked, totalFixed);

        out.println("<table><tr><th>Bảng</th><th>Đã kiểm tra</th><th>Đã sửa</th></tr>");
        results.forEach((table, counts) -> {
            String fixedClass = counts[1] > 0 ? "fixed" : "none";
            out.printf("<tr><td>%s</td><td>%d</td><td class=\"%s\">%d</td></tr>%n",
                    table, counts[0], fixedClass, counts[1]);
        });
        out.println("</table>");

        if (!errors.isEmpty()) {
            out.println("<h2>⚠️ Lỗi gặp phải</h2><div class=\"err\"><ul>");
            errors.forEach(e -> out.printf("<li>%s</li>%n", htmlEscape(e)));
            out.println("</ul></div>");
        }

        out.printf("<p style=\"font-size:13px;color:#64748B;margin-top:24px\">Repair hoàn thành. "
                + "<a href=\"%s/categories\">→ Danh mục</a> · "
                + "<a href=\"%s/medicines\">→ Thuốc</a></p>%n",
                req.getContextPath(), req.getContextPath());
        out.println("</body></html>");
    }

    // ── Table repair methods ────────────────────────────────────────────────

    private int[] repairCategories(List<String> errors) {
        return repairTable(
            "SELECT CategoryID, CategoryName, Description FROM Categories",
            "UPDATE Categories SET CategoryName=?, Description=? WHERE CategoryID=?",
            errors,
            (rs, ps) -> {
                int id = rs.getInt(1);
                String name  = fix(rs.getString(2));
                String desc  = fix(rs.getString(3));
                String orig1 = rs.getString(2);
                String orig2 = rs.getString(3);
                if (!Objects.equals(name, orig1) || !Objects.equals(desc, orig2)) {
                    ps.setNString(1, name);
                    ps.setNString(2, desc);
                    ps.setInt(3, id);
                    return true;
                }
                return false;
            }
        );
    }

    private int[] repairMedicines(List<String> errors) {
        return repairTable(
            "SELECT MedicineID, MedicineName, GenericName, Unit, Dosage, Contraindications, StorageConditions FROM Medicines",
            "UPDATE Medicines SET MedicineName=?, GenericName=?, Unit=?, Dosage=?, Contraindications=?, StorageConditions=? WHERE MedicineID=?",
            errors,
            (rs, ps) -> {
                int id  = rs.getInt(1);
                String n1 = fix(rs.getString(2)), o1 = rs.getString(2);
                String n2 = fix(rs.getString(3)), o2 = rs.getString(3);
                String n3 = fix(rs.getString(4)), o3 = rs.getString(4);
                String n4 = fix(rs.getString(5)), o4 = rs.getString(5);
                String n5 = fix(rs.getString(6)), o5 = rs.getString(6);
                String n6 = fix(rs.getString(7)), o6 = rs.getString(7);
                if (!eq(n1,o1)||!eq(n2,o2)||!eq(n3,o3)||!eq(n4,o4)||!eq(n5,o5)||!eq(n6,o6)) {
                    ps.setNString(1, n1); ps.setNString(2, n2); ps.setNString(3, n3);
                    ps.setNString(4, n4); ps.setNString(5, n5); ps.setNString(6, n6);
                    ps.setInt(7, id);
                    return true;
                }
                return false;
            }
        );
    }

    private int[] repairManufacturers(List<String> errors) {
        return repairTable(
            "SELECT ManufacturerID, ManufacturerName, Address FROM Manufacturers",
            "UPDATE Manufacturers SET ManufacturerName=?, Address=? WHERE ManufacturerID=?",
            errors,
            (rs, ps) -> {
                int id = rs.getInt(1);
                String n1 = fix(rs.getString(2)), o1 = rs.getString(2);
                String n2 = fix(rs.getString(3)), o2 = rs.getString(3);
                if (!eq(n1,o1)||!eq(n2,o2)) {
                    ps.setNString(1, n1); ps.setNString(2, n2); ps.setInt(3, id);
                    return true;
                }
                return false;
            }
        );
    }

    private int[] repairSuppliers(List<String> errors) {
        return repairTable(
            "SELECT SupplierID, SupplierName, ContactName, Address FROM Suppliers",
            "UPDATE Suppliers SET SupplierName=?, ContactName=?, Address=? WHERE SupplierID=?",
            errors,
            (rs, ps) -> {
                int id = rs.getInt(1);
                String n1 = fix(rs.getString(2)), o1 = rs.getString(2);
                String n2 = fix(rs.getString(3)), o2 = rs.getString(3);
                String n3 = fix(rs.getString(4)), o3 = rs.getString(4);
                if (!eq(n1,o1)||!eq(n2,o2)||!eq(n3,o3)) {
                    ps.setNString(1, n1); ps.setNString(2, n2); ps.setNString(3, n3);
                    ps.setInt(4, id);
                    return true;
                }
                return false;
            }
        );
    }

    private int[] repairShelves(List<String> errors) {
        return repairTable(
            "SELECT ShelfID, ShelfName, LocationNotes FROM Shelves",
            "UPDATE Shelves SET ShelfName=?, LocationNotes=? WHERE ShelfID=?",
            errors,
            (rs, ps) -> {
                int id = rs.getInt(1);
                String n1 = fix(rs.getString(2)), o1 = rs.getString(2);
                String n2 = fix(rs.getString(3)), o2 = rs.getString(3);
                if (!eq(n1,o1)||!eq(n2,o2)) {
                    ps.setNString(1, n1); ps.setNString(2, n2); ps.setInt(3, id);
                    return true;
                }
                return false;
            }
        );
    }

    private int[] repairCustomers(List<String> errors) {
        return repairTable(
            "SELECT CustomerID, CustomerName, Address, Occupation, AllergyHistory, ChronicDisease FROM Customers",
            "UPDATE Customers SET CustomerName=?, Address=?, Occupation=?, AllergyHistory=?, ChronicDisease=? WHERE CustomerID=?",
            errors,
            (rs, ps) -> {
                int id = rs.getInt(1);
                String n1 = fix(rs.getString(2)), o1 = rs.getString(2);
                String n2 = fix(rs.getString(3)), o2 = rs.getString(3);
                String n3 = fix(rs.getString(4)), o3 = rs.getString(4);
                String n4 = fix(rs.getString(5)), o4 = rs.getString(5);
                String n5 = fix(rs.getString(6)), o5 = rs.getString(6);
                if (!eq(n1,o1)||!eq(n2,o2)||!eq(n3,o3)||!eq(n4,o4)||!eq(n5,o5)) {
                    ps.setNString(1, n1); ps.setNString(2, n2); ps.setNString(3, n3);
                    ps.setNString(4, n4); ps.setNString(5, n5); ps.setInt(6, id);
                    return true;
                }
                return false;
            }
        );
    }

    // ── Generic repair executor ─────────────────────────────────────────────

    @FunctionalInterface
    interface RowProcessor {
        boolean process(ResultSet rs, PreparedStatement ps) throws Exception;
    }

    private int[] repairTable(String selectSql, String updateSql,
                               List<String> errors, RowProcessor processor) {
        int checked = 0, fixed = 0;
        try (Connection cn = DBContext.getConnection();
             PreparedStatement sel = cn.prepareStatement(selectSql);
             PreparedStatement upd = cn.prepareStatement(updateSql);
             ResultSet rs = sel.executeQuery()) {

            while (rs.next()) {
                checked++;
                try {
                    if (processor.process(rs, upd)) {
                        upd.executeUpdate();
                        fixed++;
                    }
                } catch (Exception e) {
                    errors.add(selectSql.substring(0, 30) + "... row " + checked + ": " + e.getMessage());
                }
            }
        } catch (Exception e) {
            errors.add("Query failed [" + selectSql.substring(0, Math.min(40, selectSql.length())) + "]: " + e.getMessage());
        }
        return new int[]{checked, fixed};
    }

    // ── Helpers ─────────────────────────────────────────────────────────────

    private static String fix(String s) { return MojibakeUtil.fix(s); }
    private static boolean eq(String a, String b) { return Objects.equals(a, b); }

    private static boolean isAdmin(HttpServletRequest req) {
        Account acc = (Account) req.getSession(false) != null
                ? (Account) req.getSession().getAttribute("adminAccount") : null;
        return acc != null;
    }

    private static String htmlEscape(String s) {
        return s == null ? "" : s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
    }
}
