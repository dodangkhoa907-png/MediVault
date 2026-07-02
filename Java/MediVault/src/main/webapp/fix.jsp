<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.medicare.config.DBContext" %>
<%@ page import="java.sql.*" %>
<!DOCTYPE html>
<html>
<head><title>Fix Mojibake Tool</title><style>body{font-family:sans-serif;padding:20px;}</style></head>
<body>
    <h2>⚡ HỆ THỐNG ĐANG TỰ ĐỘNG KHÔI PHỤC TIẾNG VIỆT...</h2>
    <ul>
    <%
    try (Connection con = DBContext.getConnection()) {
        int catFixed = 0;
        int medFixed = 0;

        // --- Sửa bảng Category ---
        try (PreparedStatement sel = con.prepareStatement("SELECT CategoryId, CategoryName, Description FROM Categories");
             ResultSet rs = sel.executeQuery();
             PreparedStatement upd = con.prepareStatement("UPDATE Categories SET CategoryName = ?, Description = ? WHERE CategoryId = ?")) {
            while (rs.next()) {
                int id = rs.getInt("CategoryId");
                String name = rs.getString("CategoryName");
                String desc = rs.getString("Description");
                
                boolean changed = false;
                String fixedName = name;
                if (name != null) {
                    try {
                        byte[] b = name.getBytes("Cp1252"); // Mấu chốt: Phải dùng Cp1252 thay vì ISO-8859-1
                        String r = new String(b, "UTF-8");
                        if (!r.contains("\uFFFD") && !r.equals(name)) { fixedName = r; changed = true; }
                    } catch(Exception e){}
                }
                
                String fixedDesc = desc;
                if (desc != null) {
                    try {
                        byte[] b = desc.getBytes("Cp1252");
                        String r = new String(b, "UTF-8");
                        if (!r.contains("\uFFFD") && !r.equals(desc)) { fixedDesc = r; changed = true; }
                    } catch(Exception e){}
                }
                
                if (changed) {
                    upd.setString(1, fixedName);
                    upd.setString(2, fixedDesc);
                    upd.setInt(3, id);
                    upd.executeUpdate();
                    catFixed++;
                }
            }
        }
        
        // --- Sửa bảng Medicines ---
        try (PreparedStatement sel = con.prepareStatement("SELECT MedicineId, MedicineName, GenericName, Unit, Dosage, StorageConditions, Contraindications FROM Medicines");
             ResultSet rs = sel.executeQuery();
             PreparedStatement upd = con.prepareStatement("UPDATE Medicines SET MedicineName=?, GenericName=?, Unit=?, Dosage=?, StorageConditions=?, Contraindications=? WHERE MedicineId=?")) {
            while (rs.next()) {
                int id = rs.getInt("MedicineId");
                String[] cols = { "MedicineName", "GenericName", "Unit", "Dosage", "StorageConditions", "Contraindications" };
                String[] vals = new String[6];
                
                boolean changed = false;
                for (int i=0; i<cols.length; i++) {
                    String val = rs.getString(cols[i]);
                    vals[i] = val;
                    if (val != null) {
                        try {
                            byte[] b = val.getBytes("Cp1252");
                            String r = new String(b, "UTF-8");
                            if (!r.contains("\uFFFD") && !r.equals(val)) {
                                vals[i] = r;
                                changed = true;
                            }
                        } catch(Exception e){}
                    }
                }
                
                if (changed) {
                    for (int i=0; i<6; i++) upd.setString(i+1, vals[i]);
                    upd.setInt(7, id);
                    upd.executeUpdate();
                    medFixed++;
                }
            }
        }
        
        out.println("<li>✅ Tự động dịch mã chuẩn cho <b>" + catFixed + "</b> dòng trong Danh Mục.</li>");
        out.println("<li>✅ Tự động dịch mã chuẩn cho <b>" + medFixed + "</b> dòng trong Kho Thuốc.</li>");
    } catch (Exception e) {
        out.println("<li style='color:red;'>❌ Lỗi hệ thống: " + e.getMessage() + "</li>");
    }
    %>
    </ul>
    <h3 style="color:green;">🚀 HOÀN TẤT!</h3>
    <p>Nhấn F5 tại trang sản phẩm, tất cả dấu câu đã được trả về nguyên vẹn.</p>
</body>
</html>
