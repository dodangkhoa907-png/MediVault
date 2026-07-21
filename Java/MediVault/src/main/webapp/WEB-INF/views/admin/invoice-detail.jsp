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
<title>${inv.invoiceCode} — MediCare</title>


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
.banner{border-radius:14px;padding:14px 20px;margin-bottom:18px;font-size:13.5px;font-weight:750;display:flex;align-items:center;gap:10px}
.banner-cancelled{background:#FEF2F2;color:#991B1B;border:1.5px solid #FECACA}
.banner-pending{background:#FFFBEB;color:#92400E;border:1.5px solid #FDE68A}
.info-card{background:var(--white);border:1px solid var(--border);border-radius:16px;padding:24px;margin-bottom:18px;display:grid;grid-template-columns:repeat(4,1fr);gap:18px}
.info-item .lbl{font-size:10.5px;font-weight:750;text-transform:uppercase;letter-spacing:.4px;color:var(--muted);margin-bottom:4px}
.info-item .val{font-size:14.5px;font-weight:800;color:var(--ink)}
.info-item.full{grid-column:1/-1}
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:750}
.badge-completed{background:#ECFDF5;color:var(--green)}
.badge-cancelled{background:#FEF2F2;color:var(--red)}
.badge-pending{background:#FFFBEB;color:var(--gold)}
.table-card{background:#fff;border:1px solid rgba(213,224,240,.45);border-radius:16px;overflow:hidden;margin-bottom:18px;box-shadow:0 1px 3px rgba(15,38,69,.03),0 4px 12px rgba(15,38,69,.04)}
.table-card-head{padding:18px 24px;border-bottom:1px solid var(--border)}
.table-card-head h2{font-size:15px;font-weight:800}
.table-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse}
thead th{padding:10px 16px;background:#F8FAFC;font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;white-space:nowrap;border-bottom:1px solid var(--border)}
tbody td{padding:12px 16px;font-size:13px;color:var(--ink);border-bottom:1px solid #F1F5F9}
tbody tr:last-child td{border-bottom:none}
.totals-card{background:var(--white);border:1px solid var(--border);border-radius:16px;padding:22px 24px;margin-left:auto;max-width:360px}
.totals-row{display:flex;justify-content:space-between;align-items:center;padding:7px 0;font-size:13.5px}
.totals-row.final{border-top:1.5px solid var(--border);margin-top:8px;padding-top:14px;font-size:17px;font-weight:800}
.totals-row .lbl{color:var(--muted)}
.totals-row .val{font-weight:750;color:var(--ink)}
.totals-row.discount .val{color:var(--red)}
.empty-row{text-align:center;padding:48px;color:var(--muted)}
.hint-box{background:#EFF6FF;border:1px solid #BFDBFE;border-radius:10px;padding:12px 16px;margin-bottom:18px;font-size:12px;color:#1558A8}
</style>
    
</head>
<body>
<div class="topbar">
  <a href="${pageContext.request.contextPath}/invoices" class="btn-back">← Hóa đơn</a>
  <span class="topbar-title">${inv.invoiceCode}</span>
  <div class="topbar-right">
    <c:if test="${inv.status == 'COMPLETED'}">
      <a href="${pageContext.request.contextPath}/returns?action=new&invoiceId=${inv.invoiceId}"
         style="display:inline-flex;align-items:center;gap:6px;padding:8px 16px;border-radius:9px;background:#FFF7ED;color:#C2410C;font-size:13px;font-weight:750;text-decoration:none;margin-right:10px">↩️ Tạo phiếu trả hàng</a>
    </c:if>
    <div class="user-av-sm"><%= initials %></div>
  </div>
</div>

<div class="content">

  <c:if test="${inv.status == 'CANCELLED'}">
    <div class="banner banner-cancelled">❌ Hóa đơn này đã bị hủy — không tính vào doanh thu.</div>
  </c:if>
  <c:if test="${inv.status == 'PENDING'}">
    <div class="banner banner-pending">⏳ Hóa đơn đang ở trạng thái xử lý, chưa hoàn tất thanh toán.</div>
  </c:if>

  <div class="info-card">
    <div class="info-item">
      <div class="lbl">Trạng thái</div>
      <div class="val">
        <c:choose>
          <c:when test="${inv.status == 'COMPLETED'}"><span class="badge badge-completed">✅ Hoàn tất</span></c:when>
          <c:when test="${inv.status == 'CANCELLED'}"><span class="badge badge-cancelled">❌ Đã hủy</span></c:when>
          <c:otherwise><span class="badge badge-pending">⏳ Đang xử lý</span></c:otherwise>
        </c:choose>
      </div>
    </div>
    <div class="info-item"><div class="lbl">Thời gian lập</div><div class="val" style="font-size:13px">${fn:substring(inv.createdAt.toString(),0,16)}</div></div>
    <div class="info-item"><div class="lbl">Nhân viên lập</div><div class="val">${staff != null ? staff.fullName : 'ID ' += inv.accountId}</div></div>
    <div class="info-item">
      <div class="lbl">Phương thức TT</div>
      <div class="val" style="font-size:13px">
        <c:choose>
          <c:when test="${inv.paymentMethod == 'CASH'}">💵 Tiền mặt</c:when>
          <c:when test="${inv.paymentMethod == 'CARD'}">💳 Thẻ</c:when>
          <c:when test="${inv.paymentMethod == 'TRANSFER'}">🏦 Chuyển khoản</c:when>
          <c:when test="${inv.paymentMethod == 'EWALLET'}">📱 Ví điện tử</c:when>
          <c:when test="${inv.paymentMethod == 'QR_CODE'}">🔲 QR Code</c:when>
          <c:otherwise>${inv.paymentMethod}</c:otherwise>
        </c:choose>
      </div>
    </div>

    <div class="info-item"><div class="lbl">Khách hàng</div><div class="val" style="font-size:13.5px">${customer != null ? customer.customerName : 'Khách vãng lai'}</div></div>
    <c:if test="${customer != null}">
      <div class="info-item"><div class="lbl">SĐT khách hàng</div><div class="val" style="font-size:13.5px">${customer.phone}</div></div>
    </c:if>
    <c:if test="${shift != null}">
      <div class="info-item"><div class="lbl">Ca làm việc</div><div class="val" style="font-size:13.5px">#${shift.shiftId}</div></div>
    </c:if>
    <c:if test="${presc != null}">
      <div class="info-item"><div class="lbl">Đơn thuốc kèm theo</div><div class="val" style="font-size:13.5px">BS ${presc.doctorName != null ? presc.doctorName : '—'}</div></div>
    </c:if>
  </div>

  <div class="table-card">
    <div class="table-card-head"><h2>💊 Chi tiết sản phẩm (${fn:length(details)} dòng)</h2></div>
    <div class="table-wrap">
      <table>
        <thead>
          <tr><th>Thuốc</th><th>Số lô</th><th>HSD</th><th>Đơn giá</th><th>SL</th><th>Thành tiền</th></tr>
        </thead>
        <tbody>
          <c:if test="${empty details}">
            <tr><td colspan="6" class="empty-row">Hóa đơn không có dòng chi tiết nào.</td></tr>
          </c:if>
          <c:forEach var="d" items="${details}">
            <tr>
              <td style="font-weight:750">${d.medicineName}</td>
              <td style="font-family:monospace;color:var(--muted)">${d.batchNumber}</td>
              <td style="color:var(--muted)">${d.expiryDate}</td>
              <td><fmt:formatNumber value="${d.unitPrice}" type="number" maxFractionDigits="0"/>đ</td>
              <td>${d.quantity} ${d.unit}</td>
              <td style="font-weight:800"><fmt:formatNumber value="${d.subTotal}" type="number" maxFractionDigits="0"/>đ</td>
            </tr>
          </c:forEach>
        </tbody>
      </table>
    </div>
  </div>

  <div class="totals-card">
    <div class="totals-row"><span class="lbl">Tổng tiền hàng</span><span class="val"><fmt:formatNumber value="${grossTotal}" type="number" maxFractionDigits="0"/>đ</span></div>
    <div class="totals-row discount"><span class="lbl">Giảm giá</span><span class="val">-<fmt:formatNumber value="${inv.discountAmount}" type="number" maxFractionDigits="0"/>đ</span></div>
    <div class="totals-row final"><span class="lbl">Thành tiền</span><span class="val"><fmt:formatNumber value="${inv.finalAmount}" type="number" maxFractionDigits="0"/>đ</span></div>
  </div>

  <c:if test="${grossTotal - inv.discountAmount != inv.finalAmount}">
    <div class="hint-box" style="margin-top:14px;background:#FFFBEB;border-color:#FDE68A;color:#92400E">
      ⚠️ Tổng tiền hàng − Giảm giá không khớp với Thành tiền lưu trong hệ thống. Có thể dữ liệu đã bị chỉnh sửa thủ công ngoài luồng chuẩn — nên kiểm tra lại.
    </div>
  </c:if>

</div>
</body>
</html>

