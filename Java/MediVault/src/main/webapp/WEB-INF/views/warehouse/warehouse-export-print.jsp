<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%--
  warehouse-export-print.jsp — Phiếu xuất kho dạng in (không sidebar/topbar), cùng tinh thần
  popup in lại hoá đơn ở invoice-list.jsp: mở tab mới, gọi window.print(), người dùng tự
  chọn "Lưu PDF" ở hộp thoại in của trình duyệt nếu muốn xuất file.

  Bản sửa 2026-08-06 — trước đây KHÔNG khai báo @page nên trình duyệt tự chọn khổ giấy/tỉ lệ
  (thường rơi vào "Custom size" + scale rất nhỏ như 20%, chữ bé tí không đọc được khi in thật).
  Giờ khoá cứng khổ A4 + margin hợp lý, bỏ padding trùng lặp lúc in, và dãn layout để dùng hết
  chiều rộng trang thay vì co cụm 1 góc.
--%>
<%
    com.medicare.entity.WarehouseExport export = (com.medicare.entity.WarehouseExport) request.getAttribute("export");
    @SuppressWarnings("unchecked")
    java.util.List<com.medicare.entity.WarehouseExportDetail> details =
            (java.util.List<com.medicare.entity.WarehouseExportDetail>) request.getAttribute("details");
    java.time.format.DateTimeFormatter dtf = java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
    java.time.format.DateTimeFormatter df = java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy");

    String status = export.getStatus() != null ? export.getStatus() : "";
    String statusLabel;
    String statusClass;
    switch (status) {
        case "CONFIRMED": statusLabel = "Đã xác nhận"; statusClass = "ok"; break;
        case "PENDING":   statusLabel = "Chờ xử lý";   statusClass = "pending"; break;
        case "CANCELLED": statusLabel = "Đã huỷ";      statusClass = "cancel"; break;
        case "REVERSED":  statusLabel = "Đã hoàn trả"; statusClass = "reverse"; break;
        default:          statusLabel = status;        statusClass = "pending";
    }

    int totalQty = 0;
    if (details != null) for (com.medicare.entity.WarehouseExportDetail d : details) totalQty += d.getAllocatedQuantity();
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Phiếu xuất kho <%= export.getExportCode() %> — MediCare</title>
<style>
  :root{
    --ink:#161B22; --muted:#6B7280; --line:#D9DEE3; --line-soft:#EAEDF0;
    --main:#0F766E; --main-dp:#0B5B54; --soft:#F0FDFA;
    --ok-bg:#ECFDF5; --ok-c:#047857;
    --pending-bg:#FFFBEB; --pending-c:#B45309;
    --cancel-bg:#FEF2F2; --cancel-c:#B91C1C;
    --reverse-bg:#F3F4F6; --reverse-c:#4B5563;
  }
  *{box-sizing:border-box}
  html,body{margin:0;padding:0}
  body{
    font-family:'Segoe UI',-apple-system,BlinkMacSystemFont,Roboto,Arial,sans-serif;
    color:var(--ink); background:#EEF1F3; -webkit-font-smoothing:antialiased;
  }

  /* ── Khổ giấy: khoá cứng A4 để trình duyệt không tự chọn "Custom size" + scale lạ ── */
  @page{ size:A4; margin:14mm 16mm 16mm; }

  .toolbar{
    max-width:800px;margin:0 auto;padding:16px 0 0;display:flex;justify-content:flex-end;gap:8px;
  }
  .toolbar button{
    padding:9px 20px;border-radius:9px;border:1px solid var(--main);background:var(--main);color:#fff;
    font-size:13px;font-weight:700;cursor:pointer;font-family:inherit;
  }
  .toolbar button:hover{background:var(--main-dp)}
  .toolbar .ghost{background:#fff;color:var(--main)}

  .page-shell{max-width:800px;margin:0 auto;padding:20px 0 48px}
  .doc{
    background:#fff;padding:22mm 16mm;border-radius:4px;
    box-shadow:0 1px 3px rgba(15,23,22,.08),0 12px 32px -12px rgba(15,23,22,.18);
  }

  /* ── Masthead ── */
  .hd{display:flex;justify-content:space-between;align-items:flex-start;gap:24px;
      border-bottom:2.5px solid var(--main);padding-bottom:16px;margin-bottom:20px}
  .hd-brand{display:flex;align-items:center;gap:10px}
  .hd-mark{width:34px;height:34px;border-radius:9px;background:linear-gradient(135deg,var(--main),var(--main-dp));
      color:#fff;display:flex;align-items:center;justify-content:center;font-weight:800;font-size:14px;flex-shrink:0}
  .hd-brand-text .eyebrow{font-size:10px;font-weight:800;letter-spacing:.09em;color:var(--muted);text-transform:uppercase}
  .hd h1{font-size:19px;margin:1px 0 0;color:var(--ink);letter-spacing:-.01em}
  .hd-right{text-align:right;flex-shrink:0}
  .code{font-family:'Consolas','Courier New',monospace;font-size:21px;font-weight:800;color:var(--main-dp);letter-spacing:.02em}
  .status-pill{display:inline-block;margin-top:6px;padding:3px 11px;border-radius:20px;font-size:11px;font-weight:800;letter-spacing:.02em}
  .status-pill.ok{background:var(--ok-bg);color:var(--ok-c)}
  .status-pill.pending{background:var(--pending-bg);color:var(--pending-c)}
  .status-pill.cancel{background:var(--cancel-bg);color:var(--cancel-c)}
  .status-pill.reverse{background:var(--reverse-bg);color:var(--reverse-c)}

  /* ── Thông tin phiếu ── */
  .meta{
    display:grid;grid-template-columns:1fr 1fr;gap:0;
    border:1px solid var(--line-soft);border-radius:8px;overflow:hidden;margin-bottom:22px;
  }
  .meta .cell{padding:9px 14px;border-bottom:1px solid var(--line-soft);font-size:12.5px}
  .meta .cell:nth-child(odd){border-right:1px solid var(--line-soft)}
  .meta .cell.full{grid-column:1/-1}
  .meta .cell:last-child, .meta .cell:nth-last-child(2):nth-child(odd){border-bottom:none}
  .meta .lbl{display:block;color:var(--muted);font-size:10.5px;font-weight:700;text-transform:uppercase;letter-spacing:.04em;margin-bottom:2px}
  .meta .val{font-weight:600}
  .meta .val.warn{color:var(--pending-c)}

  /* ── Bảng chi tiết ── */
  table{width:100%;border-collapse:collapse;margin-bottom:4px}
  thead{display:table-header-group}
  th{background:var(--soft);color:var(--main-dp);border:1px solid var(--line);padding:9px 10px;
     font-size:11px;font-weight:800;text-transform:uppercase;letter-spacing:.03em;text-align:left}
  td{border:1px solid var(--line);padding:8px 10px;font-size:12.5px;vertical-align:top}
  tbody tr{page-break-inside:avoid;break-inside:avoid}
  td.num, th.num{text-align:right;font-variant-numeric:tabular-nums}
  td.mono{font-family:'Consolas','Courier New',monospace;font-size:11.5px;color:#374151}
  .idx{color:var(--muted);font-variant-numeric:tabular-nums}
  .override-tag{display:inline-block;margin-left:5px;padding:1px 6px;border-radius:5px;background:var(--pending-bg);
      color:var(--pending-c);font-size:10px;font-weight:800}
  tfoot td{border:none;border-top:2px solid var(--ink);padding:8px 10px;font-size:12.5px;font-weight:800}

  /* ── Chữ ký ── */
  .sign{display:flex;justify-content:space-between;gap:16px;margin-top:56px;text-align:center;page-break-inside:avoid}
  .sign div{flex:1;font-size:12.5px}
  .sign .role{font-weight:800;color:var(--ink)}
  .sign .hint{color:var(--muted);font-size:10.5px;margin-top:2px}
  .sign .line{margin-top:64px;border-top:1px solid #333;padding-top:6px}

  .doc-footer{margin-top:28px;padding-top:12px;border-top:1px solid var(--line-soft);
      display:flex;justify-content:space-between;font-size:10.5px;color:var(--muted)}

  @media print{
    body{background:#fff}
    .toolbar{display:none}
    .page-shell{max-width:none;padding:0}
    .doc{box-shadow:none;border-radius:0;padding:0;width:100%}
    * { -webkit-print-color-adjust:exact !important; print-color-adjust:exact !important; }
  }
</style>
</head>
<body>
  <div class="toolbar">
    <button class="ghost" onclick="window.close()">Đóng</button>
    <button onclick="window.print()">🖨️ In phiếu</button>
  </div>

  <div class="page-shell">
    <div class="doc">
      <div class="hd">
        <div class="hd-brand">
          <div class="hd-mark">MC</div>
          <div class="hd-brand-text">
            <div class="eyebrow">MediCare Pharmacy · Warehouse Console</div>
            <h1>Phiếu xuất kho</h1>
          </div>
        </div>
        <div class="hd-right">
          <div class="code"><%= export.getExportCode() %></div>
          <span class="status-pill <%= statusClass %>"><%= statusLabel %></span>
        </div>
      </div>

      <div class="meta">
        <div class="cell"><span class="lbl">Loại xuất kho</span><span class="val"><%= export.getReasonName() %></span></div>
        <div class="cell"><span class="lbl">Người / nơi nhận</span><span class="val"><%= export.getReceiver() != null ? export.getReceiver() : "—" %></span></div>
        <div class="cell"><span class="lbl">Người tạo phiếu</span><span class="val"><%= export.getCreatedByName() != null ? export.getCreatedByName() : "—" %></span></div>
        <div class="cell"><span class="lbl">Ngày tạo</span><span class="val"><%= export.getCreatedAt() != null ? export.getCreatedAt().format(dtf) : "—" %></span></div>
        <div class="cell"><span class="lbl">Ngày xác nhận</span><span class="val"><%= export.getConfirmedAt() != null ? export.getConfirmedAt().format(dtf) : "—" %></span></div>
        <div class="cell"><span class="lbl">Tổng số dòng thuốc</span><span class="val"><%= details != null ? details.size() : 0 %> dòng · <%= totalQty %> đơn vị</span></div>
        <% if (export.getNotes() != null && !export.getNotes().isEmpty()) { %>
        <div class="cell full"><span class="lbl">Ghi chú</span><span class="val"><%= export.getNotes() %></span></div>
        <% } %>
        <% if (export.isFefoOverridden()) { %>
        <div class="cell full"><span class="lbl">Ghi đè phân bổ FEFO</span><span class="val warn"><%= export.getOverrideReason() != null ? export.getOverrideReason() : "—" %></span></div>
        <% } %>
      </div>

      <table>
        <thead>
          <tr>
            <th style="width:32px">#</th>
            <th>Thuốc</th>
            <th style="width:110px">Mã vạch</th>
            <th style="width:100px">Số lô</th>
            <th style="width:90px">Hạn dùng</th>
            <th class="num" style="width:70px">SL</th>
          </tr>
        </thead>
        <tbody>
          <% int i = 1; for (com.medicare.entity.WarehouseExportDetail d : details) { %>
          <tr>
            <td class="idx"><%= i++ %></td>
            <td><%= d.getMedicineName() %></td>
            <td class="mono"><%= d.getBarcode() != null ? d.getBarcode() : "—" %></td>
            <td class="mono"><%= d.getBatchNumber() %></td>
            <td><%= d.getExpiryDate() != null ? d.getExpiryDate().format(df) : "—" %></td>
            <td class="num"><%= d.getAllocatedQuantity() %><% if (d.isFefoOverridden()) { %><span class="override-tag">GHI ĐÈ</span><% } %></td>
          </tr>
          <% } %>
        </tbody>
        <tfoot>
          <tr><td colspan="5">Tổng cộng</td><td class="num"><%= totalQty %></td></tr>
        </tfoot>
      </table>

      <div class="sign">
        <div><div class="role">Thủ kho</div><div class="hint">Ký &amp; ghi rõ họ tên</div><div class="line"></div></div>
        <div><div class="role">Người nhận</div><div class="hint">Ký &amp; ghi rõ họ tên</div><div class="line"></div></div>
        <div><div class="role">Quản lý kho</div><div class="hint">Ký &amp; ghi rõ họ tên</div><div class="line"></div></div>
      </div>

      <div class="doc-footer">
        <span>Chứng từ điện tử — in từ MediCare Warehouse Console</span>
        <span id="printedAt"></span>
      </div>
    </div>
  </div>

  <script>
    document.getElementById('printedAt').textContent =
      'In lúc: ' + new Date().toLocaleString('vi-VN', { hour12:false });
  </script>
</body>
</html>
