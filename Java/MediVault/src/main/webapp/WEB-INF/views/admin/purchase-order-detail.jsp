<%@ page contentType="text/html;charset=UTF-8"  pageEncoding="UTF-8" %>
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
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
    
    
    
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>${po.poCode} — MediCare</title>


<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;
}
html,body{min-height:100%;font-family:'Plus Jakarta Sans',sans-serif;background:var(--surface);color:var(--ink)}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Plus Jakarta Sans',sans-serif;font-size:16px;font-weight:750;color:var(--ink)}
.btn-back{display:inline-flex;align-items:center;gap:6px;padding:6px 14px;border-radius:9px;border:1.5px solid var(--border);background:var(--white);color:var(--ink);font-size:13px;font-weight:750;text-decoration:none}
.btn-back:hover{border-color:var(--blue);color:var(--blue)}

    
.topbar-right{margin-left:auto}
.user-av-sm{width:32px;height:32px;border-radius:50%;background:linear-gradient(135deg,#3ABDE0,#1558A8);display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.content{max-width:880px;margin:28px auto;padding:0 20px 40px}
.info-card{background:var(--white);border:1px solid var(--border);border-radius:16px;padding:24px;margin-bottom:18px;display:grid;grid-template-columns:repeat(4,1fr);gap:18px}
.info-item .lbl{font-size:10.5px;font-weight:750;text-transform:uppercase;letter-spacing:.4px;color:var(--muted);margin-bottom:4px}
.info-item .val{font-size:15px;font-weight:800;color:var(--ink)}
.info-item.full{grid-column:1/-1}
.table-card{background:#fff;border:1px solid rgba(213,224,240,.45);border-radius:16px;overflow:hidden;box-shadow:0 1px 3px rgba(15,38,69,.03),0 4px 12px rgba(15,38,69,.04)}
.table-card-head{padding:18px 24px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
.table-card-head h2{font-size:15px;font-weight:800}
.table-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse}
thead th{padding:10px 16px;background:#F8FAFC;font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;white-space:nowrap;border-bottom:1px solid var(--border)}
tbody td{padding:12px 16px;font-size:13px;color:var(--ink);border-bottom:1px solid #F1F5F9}
tbody tr:last-child td{border-bottom:none}
.empty-row{text-align:center;padding:48px;color:var(--muted)}
.hint-box{background:#EFF6FF;border:1px solid #BFDBFE;border-radius:10px;padding:12px 16px;margin-bottom:18px;font-size:12.5px;color:#1558A8;display:flex;gap:10px;align-items:flex-start}
.btn-primary{display:inline-flex;align-items:center;gap:7px;padding:9px 16px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;border-radius:10px;font-family:'Plus Jakarta Sans',sans-serif;font-size:12.5px;font-weight:750;cursor:pointer;text-decoration:none}
</style>
    
<meta name="csrf-token" content="${csrfToken}">
<script src="${pageContext.request.contextPath}/js/csrf.js"></script>
</head>
<body>
<div class="topbar">
  <a href="${pageContext.request.contextPath}/purchase-orders" class="btn-back">← Đơn đặt hàng</a>
  <span class="topbar-title">${po.poCode}</span>
  <div class="topbar-right"><div class="user-av-sm"><%= initials %></div></div>
</div>

<div class="content">

  <%-- Toast kết quả nhận hàng --%>
  <c:if test="${param.msg == 'po-pending'}">
    <div style="background:#EFF6FF;border:1px solid #BFDBFE;color:#1558A8;border-radius:11px;padding:12px 18px;margin-bottom:16px;font-size:13.5px;font-weight:750">
      📋 Đã tạo phiếu nhập — đơn đang <b>CHỜ HÀNG VỀ</b>. Kho CHƯA tăng. Khi hàng tới, bấm <b>"Xác nhận Hàng Đã Tới"</b> bên dưới.
    </div>
  </c:if>
  <c:if test="${param.msg == 'received'}">
    <div style="background:#D1FAE5;border:1px solid #A7F3D0;color:#065F46;border-radius:11px;padding:12px 18px;margin-bottom:16px;font-size:13.5px;font-weight:750">
      ✅ Đã xác nhận hàng về — các lô đã được nhập kho, tồn kho đã tăng!
    </div>
  </c:if>
  <c:if test="${param.msg == 'receive-fail'}">
    <div style="background:#FEE2E2;border:1px solid #FECACA;color:#991B1B;border-radius:11px;padding:12px 18px;margin-bottom:16px;font-size:13.5px;font-weight:750">
      ❌ Không thể xác nhận hàng về.
      <c:choose>
        <c:when test="${not empty param.receiveErr}">
          <div style="margin-top:6px;font-weight:600;font-size:12.5px">Lý do: <c:out value="${param.receiveErr}"/></div>
        </c:when>
        <c:otherwise>
          Đơn không ở trạng thái Chờ xử lý hoặc không có dòng hàng.
        </c:otherwise>
      </c:choose>
    </div>
  </c:if>

  <%-- Banner trạng thái + nút DONE --%>
  <c:choose>
    <c:when test="${po.status == 'PENDING'}">
      <div style="background:#FFFBEB;border:1.5px solid #FDE68A;border-radius:14px;padding:16px 20px;margin-bottom:18px;display:flex;align-items:center;gap:14px;flex-wrap:wrap">
        <div style="font-size:26px">⏳</div>
        <div style="flex:1;min-width:220px">
          <div style="font-size:14.5px;font-weight:800;color:#92400E">Đơn đang CHỜ HÀNG VỀ</div>
          <div style="font-size:12.5px;color:#B45309;margin-top:2px">Kho <b>chưa tăng</b> viên nào. Khi xe hàng tới &amp; đếm khớp số lượng, bấm nút bên phải — hệ thống sẽ tự tạo lô và cộng tồn kho.</div>
        </div>
        <form method="post" action="${pageContext.request.contextPath}/purchase-orders"
              onsubmit="return confirm('Xác nhận hàng đã về đủ? Hệ thống sẽ tạo lô và CỘNG TỒN KHO ngay.')">
          <input type="hidden" name="_csrf" value="${csrfToken}">
          <input type="hidden" name="action" value="confirm"/>
          <input type="hidden" name="id" value="${po.poId}"/>
          <button type="submit" style="background:linear-gradient(135deg,#059669,#047857);color:#fff;border:none;border-radius:12px;padding:13px 22px;font-size:14.5px;font-weight:800;cursor:pointer;font-family:inherit;box-shadow:0 6px 18px rgba(5,150,105,.35)">
            ✅ Xác nhận Hàng Đã Tới
          </button>
        </form>
      </div>
    </c:when>
    <c:otherwise>
      <div style="background:#ECFDF5;border:1.5px solid #A7F3D0;border-radius:14px;padding:13px 20px;margin-bottom:18px;display:flex;align-items:center;gap:12px">
        <div style="font-size:22px">✅</div>
        <div style="font-size:13.5px;font-weight:800;color:#065F46">Đơn ĐÃ NHẬP KHO — các lô bên dưới đã được cộng vào tồn.</div>
      </div>
    </c:otherwise>
  </c:choose>

  <div class="info-card">
    <div class="info-item"><div class="lbl">Nhà cung cấp</div><div class="val">${supplier != null ? supplier.supplierName : '—'}</div></div>
    <div class="info-item"><div class="lbl">Người tạo</div><div class="val">${creator != null ? creator.fullName : '—'}</div></div>
    <div class="info-item"><div class="lbl">Ngày đặt</div><div class="val" style="font-size:13px">${fn:substring(po.orderDate.toString(),0,16)}</div></div>
    <div class="info-item"><div class="lbl">Tổng giá trị</div><div class="val" style="color:var(--blue)"><fmt:formatNumber value="${po.totalValue}" type="number" maxFractionDigits="0"/>đ</div></div>
    <div class="info-item"><div class="lbl">Người liên hệ NCC</div><div class="val" style="font-size:13px">${supplier != null && not empty supplier.contactName ? supplier.contactName : '—'}</div></div>
    <div class="info-item"><div class="lbl">SĐT NCC</div><div class="val" style="font-size:13px">${supplier != null && not empty supplier.phone ? supplier.phone : '—'}</div></div>
    <div class="info-item"><div class="lbl">Thanh toán</div><div class="val" style="font-size:13px">
      <c:choose>
        <c:when test="${po.paymentMethod == 'CASH'}">💵 Tiền mặt</c:when>
        <c:when test="${po.paymentMethod == 'TRANSFER'}">🏦 Chuyển khoản</c:when>
        <c:when test="${po.paymentMethod == 'DEBT'}">📝 Ghi nợ</c:when>
        <c:otherwise>—</c:otherwise>
      </c:choose>
    </div></div>
    <div class="info-item"><div class="lbl">Chiết khấu</div><div class="val" style="font-size:13px"><fmt:formatNumber value="${po.discountAmount}" type="number" maxFractionDigits="0"/>đ</div></div>
    <div class="info-item full"><div class="lbl">Địa chỉ NCC (đặt hàng ở đâu)</div><div class="val" style="font-size:13px;font-weight:750">${supplier != null && not empty supplier.address ? supplier.address : 'Chưa cập nhật địa chỉ — vào tab Nhà cung cấp để bổ sung.'}</div></div>
    <c:if test="${not empty po.notes}">
      <div class="info-item full"><div class="lbl">Ghi chú</div><div class="val" style="font-size:13px;font-weight:750">${po.notes}</div></div>
    </c:if>
  </div>

  <%-- CHỨNG TỪ: các dòng hàng ĐÃ ĐẶT (luôn hiển thị, kể cả khi chưa nhập kho) --%>
  <div class="table-card" style="margin-bottom:18px">
    <div class="table-card-head">
      <h2>🧾 Hàng đã đặt trong đơn (${fn:length(podLines)})</h2>
    </div>
    <div class="table-wrap">
      <table>
        <thead>
          <tr><th>Thuốc</th><th>Số lô dự kiến</th><th>HSD</th><th>SL đặt</th><th>Giá nhập</th><th>Thành tiền</th></tr>
        </thead>
        <tbody>
          <c:if test="${empty podLines}">
            <tr><td colspan="6" class="empty-row">Đơn này không có dòng hàng chi tiết (đơn tạo trước khi nâng cấp hệ thống).</td></tr>
          </c:if>
          <c:forEach var="d" items="${podLines}">
            <tr>
              <td style="font-weight:750">${d.medicineName}</td>
              <td style="font-family:monospace">${not empty d.batchNumber ? d.batchNumber : '—'}</td>
              <td style="color:var(--muted)">${d.expiryDate != null ? d.expiryDate : '—'}</td>
              <td style="font-weight:750">${d.quantity}</td>
              <td><fmt:formatNumber value="${d.importPrice}" type="number" maxFractionDigits="0"/>đ</td>
              <td style="font-weight:800"><fmt:formatNumber value="${d.importPrice * d.quantity}" type="number" maxFractionDigits="0"/>đ</td>
            </tr>
          </c:forEach>
        </tbody>
      </table>
    </div>
  </div>

  <div class="table-card">
    <div class="table-card-head">
      <h2>📦 Lô ĐÃ NHẬP KHO từ đơn này (${fn:length(batches)})</h2>
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
              <td style="font-weight:750">${medicineMap[b.medicineId] != null ? medicineMap[b.medicineId].medicineName : 'ID ' += b.medicineId}</td>
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

