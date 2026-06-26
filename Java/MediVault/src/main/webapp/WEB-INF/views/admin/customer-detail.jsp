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
<title>${customer.customerName} — MediCare</title>
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

    
.topbar-right{margin-left:auto;display:flex;gap:10px}
.btn-edit{display:inline-flex;align-items:center;gap:6px;padding:8px 16px;border-radius:9px;background:var(--blue);color:#fff;font-size:13px;font-weight:700;text-decoration:none}
.user-av-sm{width:32px;height:32px;border-radius:50%;background:linear-gradient(135deg,#3ABDE0,#1558A8);display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.content{max-width:880px;margin:28px auto;padding:0 20px 40px}
.profile-head{display:flex;align-items:center;gap:16px;margin-bottom:18px}
.profile-av{width:60px;height:60px;border-radius:16px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:24px;font-weight:800;color:#fff;flex-shrink:0}
.profile-name{font-size:22px;font-weight:800}
.profile-sub{font-size:13px;color:var(--muted);margin-top:2px}
.kpi-strip{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin-bottom:18px}
.kpi{background:var(--white);border:1px solid var(--border);border-radius:14px;padding:14px 18px;display:flex;align-items:center;gap:12px}
.kpi-icon{width:40px;height:40px;border-radius:11px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0}
.kpi-blue{background:#EFF6FF}.kpi-green{background:#ECFDF5}.kpi-amber{background:#FFFBEB}
.kpi-num{font-size:19px;font-weight:900}
.kpi-lbl{font-size:11px;color:var(--muted);font-weight:600;text-transform:uppercase}
.info-card{background:var(--white);border:1px solid var(--border);border-radius:16px;padding:22px 24px;margin-bottom:18px;display:grid;grid-template-columns:repeat(3,1fr);gap:16px}
.info-item .lbl{font-size:10.5px;font-weight:700;text-transform:uppercase;letter-spacing:.4px;color:var(--muted);margin-bottom:4px}
.info-item .val{font-size:13.5px;font-weight:700;color:var(--ink)}
.info-item.full{grid-column:1/-1}
.info-item.medical .val{color:#92400E}
.table-card{background:var(--white);border:1px solid var(--border);border-radius:16px;overflow:hidden}
.table-card-head{padding:18px 24px;border-bottom:1px solid var(--border)}
.table-card-head h2{font-size:15px;font-weight:800}
.table-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse}
thead th{padding:10px 16px;background:#F8FAFC;font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;white-space:nowrap;border-bottom:1px solid var(--border)}
tbody td{padding:12px 16px;font-size:13px;color:var(--ink);border-bottom:1px solid #F1F5F9}
tbody tr:last-child td{border-bottom:none}
tbody tr{cursor:pointer}
tbody tr:hover td{background:#F7FBFF}
.inv-code{font-family:monospace;font-weight:700;color:var(--blue)}
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:700}
.badge-completed{background:#ECFDF5;color:var(--green)}
.badge-cancelled{background:#FEF2F2;color:var(--red)}
.badge-pending{background:#FFFBEB;color:var(--gold)}
.empty-row{text-align:center;padding:48px;color:var(--muted)}
</style>
</head>
<body>
<div class="topbar">
  <a href="${pageContext.request.contextPath}/customers" class="btn-back">← Khách hàng</a>
  <span class="topbar-title">Hồ sơ khách hàng</span>
  <div class="topbar-right">
    <a href="${pageContext.request.contextPath}/customers?action=edit&id=${customer.customerId}" class="btn-edit">✏️ Sửa</a>
    <div class="user-av-sm"><%= initials %></div>
  </div>
</div>

<div class="content">

  <div class="profile-head">
    <div class="profile-av">${fn:toUpperCase(fn:substring(customer.customerName,0,1))}</div>
    <div>
      <div class="profile-name">${customer.customerName}</div>
      <div class="profile-sub">${not empty customer.phone ? customer.phone : 'Chưa có SĐT'} · Khách hàng từ ${customer.createdAt != null ? fn:substring(customer.createdAt.toString(),0,10) : '—'}</div>
    </div>
  </div>

  <div class="kpi-strip">
    <div class="kpi">
      <div class="kpi-icon kpi-blue">🧾</div>
      <div><div class="kpi-num">${fn:length(invoices)}</div><div class="kpi-lbl">Hóa đơn</div></div>
    </div>
    <div class="kpi">
      <div class="kpi-icon kpi-green">💰</div>
      <div><div class="kpi-num"><fmt:formatNumber value="${totalSpent}" type="number" maxFractionDigits="0"/>đ</div><div class="kpi-lbl">Tổng chi tiêu</div></div>
    </div>
    <div class="kpi">
      <div class="kpi-icon kpi-amber">🎂</div>
      <div><div class="kpi-num" style="font-size:15px">${customer.dateOfBirth != null ? customer.dateOfBirth : '—'}</div><div class="kpi-lbl">Ngày sinh</div></div>
    </div>
  </div>

  <div class="info-card">
    <div class="info-item"><div class="lbl">Email</div><div class="val">${not empty customer.email ? customer.email : '—'}</div></div>
    <div class="info-item"><div class="lbl">Giới tính</div><div class="val">
      <c:choose>
        <c:when test="${customer.gender == 'M'}">Nam</c:when>
        <c:when test="${customer.gender == 'F'}">Nữ</c:when>
        <c:otherwise>—</c:otherwise>
      </c:choose>
    </div></div>
    <div class="info-item"><div class="lbl">Nghề nghiệp</div><div class="val">${not empty customer.occupation ? customer.occupation : '—'}</div></div>
    <div class="info-item full"><div class="lbl">Địa chỉ</div><div class="val">${not empty customer.address ? customer.address : '—'}</div></div>
    <c:if test="${not empty customer.allergyHistory}">
      <div class="info-item full medical"><div class="lbl">⚠️ Tiền sử dị ứng</div><div class="val">${customer.allergyHistory}</div></div>
    </c:if>
    <c:if test="${not empty customer.chronicDisease}">
      <div class="info-item full medical"><div class="lbl">⚠️ Bệnh mạn tính</div><div class="val">${customer.chronicDisease}</div></div>
    </c:if>
  </div>

  <div class="table-card">
    <div class="table-card-head"><h2>📋 Lịch sử mua hàng</h2></div>
    <div class="table-wrap">
      <table>
        <thead><tr><th>Mã HĐ</th><th>Thời gian</th><th>Thanh toán</th><th>Thành tiền</th><th>Trạng thái</th></tr></thead>
        <tbody>
          <c:if test="${empty invoices}">
            <tr><td colspan="5" class="empty-row">Khách hàng chưa có hóa đơn nào.</td></tr>
          </c:if>
          <c:forEach var="inv" items="${invoices}">
            <tr onclick="location.href='${pageContext.request.contextPath}/invoices?action=detail&id=${inv.invoiceId}'">
              <td><span class="inv-code">${inv.invoiceCode}</span></td>
              <td style="color:var(--muted);font-size:12.5px">${fn:substring(inv.createdAt.toString(),0,16)}</td>
              <td>${inv.paymentMethod}</td>
              <td style="font-weight:800"><fmt:formatNumber value="${inv.finalAmount}" type="number" maxFractionDigits="0"/>đ</td>
              <td>
                <c:choose>
                  <c:when test="${inv.status == 'COMPLETED'}"><span class="badge badge-completed">✅ Hoàn tất</span></c:when>
                  <c:when test="${inv.status == 'CANCELLED'}"><span class="badge badge-cancelled">❌ Đã hủy</span></c:when>
                  <c:otherwise><span class="badge badge-pending">⏳ Đang xử lý</span></c:otherwise>
                </c:choose>
              </td>
            </tr>
          </c:forEach>
        </tbody>
      </table>
    </div>
  </div>
</div>
</body>
</html>
