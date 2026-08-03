<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%--
  warehouse-export-print.jsp — Phiếu xuất kho dạng in (không sidebar/topbar), cùng tinh thần
  popup in lại hoá đơn ở invoice-list.jsp: mở tab mới, gọi window.print(), người dùng tự
  chọn "Lưu PDF" ở hộp thoại in của trình duyệt nếu muốn xuất file.
--%>
<%
    com.medicare.entity.WarehouseExport export = (com.medicare.entity.WarehouseExport) request.getAttribute("export");
    @SuppressWarnings("unchecked")
    java.util.List<com.medicare.entity.WarehouseExportDetail> details =
            (java.util.List<com.medicare.entity.WarehouseExportDetail>) request.getAttribute("details");
    java.time.format.DateTimeFormatter dtf = java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
    java.time.format.DateTimeFormatter df = java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<title>Phiếu xuất kho <%= export.getExportCode() %> — MediCare</title>
<style>
  *{box-sizing:border-box;font-family:'Segoe UI',Arial,sans-serif}
  body{margin:0;padding:32px;color:#1a1a1a;background:#fff}
  .doc{max-width:760px;margin:0 auto}
  .hd{display:flex;justify-content:space-between;align-items:flex-start;border-bottom:2px solid #0F766E;padding-bottom:16px;margin-bottom:20px}
  .hd h1{font-size:20px;margin:0 0 4px;color:#0F766E}
  .hd .sub{font-size:12.5px;color:#555}
  .code{font-family:'Courier New',monospace;font-size:22px;font-weight:800;text-align:right}
  .meta{display:grid;grid-template-columns:1fr 1fr;gap:8px 24px;margin-bottom:22px;font-size:13px}
  .meta .lbl{color:#777;display:inline-block;min-width:110px}
  table{width:100%;border-collapse:collapse;margin-bottom:22px}
  th,td{border:1px solid #ccc;padding:8px 10px;font-size:12.5px;text-align:left}
  th{background:#F0FDFA;color:#0F766E}
  td.num{text-align:right}
  .sign{display:flex;justify-content:space-between;margin-top:50px;text-align:center;font-size:12.5px}
  .sign div{width:200px}
  .sign .line{margin-top:60px;border-top:1px solid #333;padding-top:6px;font-weight:700}
  .toolbar{max-width:760px;margin:0 auto 16px;text-align:right}
  .toolbar button{padding:8px 18px;border-radius:8px;border:1px solid #0F766E;background:#0F766E;color:#fff;
    font-size:13px;font-weight:700;cursor:pointer}
  @media print{.toolbar{display:none}}
</style>
</head>
<body>
  <div class="toolbar"><button onclick="window.print()">🖨️ In phiếu</button></div>
  <div class="doc">
    <div class="hd">
      <div>
        <h1>PHIẾU XUẤT KHO</h1>
        <div class="sub">MediCare Pharmacy — Warehouse Console</div>
      </div>
      <div class="code"><%= export.getExportCode() %></div>
    </div>

    <div class="meta">
      <div><span class="lbl">Loại xuất kho:</span><b><%= export.getReasonName() %></b></div>
      <div><span class="lbl">Trạng thái:</span><b><%= export.getStatus() %></b></div>
      <div><span class="lbl">Người/Nơi nhận:</span><%= export.getReceiver() != null ? export.getReceiver() : "—" %></div>
      <div><span class="lbl">Người tạo:</span><%= export.getCreatedByName() != null ? export.getCreatedByName() : "—" %></div>
      <div><span class="lbl">Ngày tạo:</span><%= export.getCreatedAt() != null ? export.getCreatedAt().format(dtf) : "—" %></div>
      <div><span class="lbl">Ngày xác nhận:</span><%= export.getConfirmedAt() != null ? export.getConfirmedAt().format(dtf) : "—" %></div>
      <% if (export.getNotes() != null && !export.getNotes().isEmpty()) { %>
      <div style="grid-column:1/-1"><span class="lbl">Ghi chú:</span><%= export.getNotes() %></div>
      <% } %>
      <% if (export.isFefoOverridden()) { %>
      <div style="grid-column:1/-1;color:#B45309"><span class="lbl">Ghi đè FEFO:</span><%= export.getOverrideReason() != null ? export.getOverrideReason() : "—" %></div>
      <% } %>
    </div>

    <table>
      <thead><tr><th>#</th><th>Thuốc</th><th>Mã vạch</th><th>Số lô</th><th>Hạn dùng</th><th>Số lượng</th></tr></thead>
      <tbody>
        <% int i = 1; for (com.medicare.entity.WarehouseExportDetail d : details) { %>
        <tr>
          <td><%= i++ %></td>
          <td><%= d.getMedicineName() %></td>
          <td><%= d.getBarcode() != null ? d.getBarcode() : "—" %></td>
          <td><%= d.getBatchNumber() %></td>
          <td><%= d.getExpiryDate() != null ? d.getExpiryDate().format(df) : "—" %></td>
          <td class="num"><%= d.getAllocatedQuantity() %><%= d.isFefoOverridden() ? " (ghi đè)" : "" %></td>
        </tr>
        <% } %>
      </tbody>
    </table>

    <div class="sign">
      <div><div class="line">Thủ kho</div></div>
      <div><div class="line">Người nhận</div></div>
      <div><div class="line">Quản lý kho</div></div>
    </div>
  </div>
</body>
</html>
