<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>${po.poCode} — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;
}
html,body{min-height:100%;font-family:'Outfit',sans-serif;background:var(--surface);color:var(--ink)}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Outfit',sans-serif;font-size:16px;font-weight:700;color:var(--ink)}
.btn-back{display:inline-flex;align-items:center;gap:6px;padding:6px 14px;border-radius:9px;border:1.5px solid var(--border);background:var(--white);color:var(--ink);font-size:13px;font-weight:600;text-decoration:none}
.btn-back:hover{border-color:var(--blue);color:var(--blue)}

    
.topbar-right{margin-left:auto}
.user-av-sm{width:32px;height:32px;border-radius:50%;background:linear-gradient(135deg,#3ABDE0,#1558A8);display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.content{max-width:880px;margin:28px auto;padding:0 20px 40px}
.info-card{background:var(--white);border:1px solid var(--border);border-radius:16px;padding:24px;margin-bottom:18px;display:grid;grid-template-columns:repeat(4,1fr);gap:18px}
.info-item .lbl{font-size:10.5px;font-weight:700;text-transform:uppercase;letter-spacing:.4px;color:var(--muted);margin-bottom:4px}
.info-item .val{font-size:15px;font-weight:800;color:var(--ink)}
.info-item.full{grid-column:1/-1}
.table-card{background:var(--white);border:1px solid var(--border);border-radius:16px;overflow:hidden}
.table-card-head{padding:18px 24px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
.table-card-head h2{font-size:15px;font-weight:800}
.table-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse}
thead th{padding:10px 16px;background:#F8FAFC;font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;white-space:nowrap;border-bottom:1px solid var(--border)}
tbody td{padding:12px 16px;font-size:13px;color:var(--ink);border-bottom:1px solid #F1F5F9}
tbody tr:last-child td{border-bottom:none}
.empty-row{text-align:center;padding:48px;color:var(--muted)}
.hint-box{background:#EFF6FF;border:1px solid #BFDBFE;border-radius:10px;padding:12px 16px;margin-bottom:18px;font-size:12.5px;color:#1558A8;display:flex;gap:10px;align-items:flex-start}
.btn-primary{display:inline-flex;align-items:center;gap:7px;padding:9px 16px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;border-radius:10px;font-family:'Outfit',sans-serif;font-size:12.5px;font-weight:700;cursor:pointer;text-decoration:none}
</style>
</head>
<body>
<div class="topbar">
  <a href="${pageContext.request.contextPath}/purchase-orders" class="btn-back">← Đơn đặt hàng</a>
  <span class="topbar-title">${po.poCode}</span>
  <div class="topbar-right"><div class="user-av-sm"><%= initials %></div></div>
</div>

<div class="content">

  <div class="hint-box">
    <span style="font-size:15px;flex-shrink:0">💡</span>
    <div>Để thêm lô hàng vào đơn này: vào <strong>Kho thuốc</strong> → chọn thuốc cần nhập → "Thêm lô mới" → chọn
      <strong>${po.poCode}</strong> trong danh sách "đơn đã có".</div>
  </div>

  <div class="info-card">
    <div class="info-item"><div class="lbl">Nhà cung cấp</div><div class="val">${supplier != null ? supplier.supplierName : '—'}</div></div>
    <div class="info-item"><div class="lbl">Người tạo</div><div class="val">${creator != null ? creator.fullName : '—'}</div></div>
    <div class="info-item"><div class="lbl">Ngày đặt</div><div class="val" style="font-size:13px">${fn:substring(po.orderDate.toString(),0,16)}</div></div>
    <div class="info-item"><div class="lbl">Tổng giá trị</div><div class="val" style="color:var(--blue)"><fmt:formatNumber value="${po.totalValue}" type="number" maxFractionDigits="0"/>đ</div></div>
    <c:if test="${not empty po.notes}">
      <div class="info-item full"><div class="lbl">Ghi chú</div><div class="val" style="font-size:13px;font-weight:500">${po.notes}</div></div>
    </c:if>
  </div>

  <div class="table-card">
    <div class="table-card-head">
      <h2>📦 Các lô hàng thuộc đơn này (${fn:length(batches)})</h2>
      <a href="${pageContext.request.contextPath}/medicines" class="btn-primary">＋ Thêm lô hàng</a>
    </div>
    <div class="table-wrap">
      <table>
        <thead>
          <tr><th>Thuốc</th><th>Số lô</th><th>HSD</th><th>Giá nhập</th><th>SL nhập</th><th>SL còn</th><th>Thành tiền</th></tr>
        </thead>
        <tbody>
          <c:if test="${empty batches}">
            <tr><td colspan="7" class="empty-row">Đơn này chưa có lô hàng nào.</td></tr>
          </c:if>
          <c:forEach var="b" items="${batches}">
            <tr>
              <td style="font-weight:700">${medicineMap[b.medicineId] != null ? medicineMap[b.medicineId].medicineName : 'ID ' += b.medicineId}</td>
              <td style="font-family:monospace">${b.batchNumber}</td>
              <td style="color:var(--muted)">${b.expiryDate}</td>
              <td><fmt:formatNumber value="${b.importPrice}" type="number" maxFractionDigits="0"/>đ</td>
              <td>${b.initialQuantity}</td>
              <td>${b.currentQuantity}</td>
              <td style="font-weight:800"><fmt:formatNumber value="${b.importPrice * b.initialQuantity}" type="number" maxFractionDigits="0"/>đ</td>
            </tr>
          </c:forEach>
        </tbody>
      </table>
    </div>
  </div>
</div>
</body>
</html>

