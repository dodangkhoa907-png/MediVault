<%@ page contentType="text/html;charset=UTF-8" %>
<% String activeNav = "invoices"; %>
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
<title>Hóa đơn — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;--sidebar:232px;--radius:14px;
}
html,body{height:100%;font-family:'Outfit',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-text{font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-text span{color:var(--cyan)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:12px 0 4px;flex-shrink:0}
.nav-label{font-size:9px;font-weight:700;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:500;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.14);font-weight:600}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--cyan);border-radius:2px}
.nav-badge{margin-left:auto;background:#DC2626;color:#fff;font-size:10px;font-weight:700;padding:1px 7px;border-radius:20px;min-width:20px;text-align:center}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50;flex-shrink:0}
.topbar-title{font-family:'Outfit',sans-serif;font-size:16px;font-weight:700;color:var(--ink)}

    
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.topbar-pill{display:inline-flex;align-items:center;gap:6px;padding:4px 12px;border-radius:20px;font-size:12.5px;font-weight:700;background:#EFF6FF;color:var(--blue)}
.topbar-user{display:flex;align-items:center;gap:8px;padding:5px 12px 5px 7px;border:1.5px solid var(--border);border-radius:20px;text-decoration:none;color:inherit}
.topbar-av{width:28px;height:28px;border-radius:8px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;color:#fff}
.topbar-name{font-size:13px;font-weight:600;color:var(--navy)}
.content{padding:22px 26px;flex:1;min-width:0}
.page-head{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:20px}
.page-head-left .breadcrumb{font-size:11.5px;color:var(--muted);font-weight:500;margin-bottom:4px}
.page-head-left h1{font-size:26px;color:var(--ink)}
.section-tabs{display:flex;gap:6px;background:var(--white);border:1px solid var(--border);border-radius:12px;padding:4px;width:fit-content;margin-bottom:18px}
.section-tab{padding:8px 18px;border-radius:9px;font-size:13px;font-weight:600;color:var(--muted);text-decoration:none;transition:all .15s;display:inline-flex;align-items:center;gap:6px}
.section-tab:hover{background:var(--surface);color:var(--ink)}
.section-tab.active{background:linear-gradient(135deg,var(--blue),var(--cyan));color:#fff;box-shadow:0 3px 10px rgba(21,88,168,.25)}
.section-tab.disabled{cursor:not-allowed;opacity:.55;pointer-events:none}
.table-card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}
.filter-row{display:flex;gap:10px;align-items:center;padding:16px 20px;border-bottom:1px solid var(--border);flex-wrap:wrap}
.filter-row input,.filter-row select{height:38px;padding:0 12px;border:1.5px solid var(--border);border-radius:9px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);background:var(--surface);outline:none}
.filter-row input[type="date"]{min-width:130px}
.filter-search{flex:1;min-width:180px}
.filter-search input{width:100%}
.filter-chip{height:38px;padding:0 16px;border-radius:9px;background:var(--blue);color:#fff;border:none;font-size:12.5px;font-weight:700;cursor:pointer;text-decoration:none;display:inline-flex;align-items:center}
.filter-clear{height:38px;padding:0 14px;border-radius:9px;background:var(--surface);border:1.5px solid var(--border);color:var(--muted);font-size:12.5px;font-weight:600;cursor:pointer;text-decoration:none;display:inline-flex;align-items:center}
.table-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse}
thead th{padding:10px 16px;background:#F8FAFC;font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;white-space:nowrap;border-bottom:1px solid var(--border)}
tbody td{padding:12px 16px;font-size:13px;color:var(--ink);border-bottom:1px solid #F1F5F9;vertical-align:middle}
tbody tr:last-child td{border-bottom:none}
tbody tr:hover td{background:#F7FBFF}
tbody tr{cursor:pointer}
.inv-code{font-family:monospace;font-weight:700;color:var(--blue)}
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:700}
.badge-completed{background:#ECFDF5;color:var(--green)}
.badge-cancelled{background:#FEF2F2;color:var(--red)}
.badge-pending{background:#FFFBEB;color:var(--gold)}
.pay-badge{font-size:11.5px;font-weight:600;color:var(--muted)}
.empty-row{text-align:center;padding:48px;color:var(--muted)}
.pagination{display:flex;align-items:center;justify-content:space-between;padding:14px 20px;border-top:1px solid var(--border)}
.pagination-info{font-size:12.5px;color:var(--muted)}
.pagination-btns{display:flex;gap:5px}
.page-btn{width:32px;height:32px;border-radius:8px;display:inline-flex;align-items:center;justify-content:center;font-size:13px;font-weight:600;text-decoration:none;color:var(--navy);background:var(--surface);border:1.5px solid var(--border)}
.page-btn:hover{border-color:var(--cyan);color:var(--blue)}
.page-btn.active{background:var(--blue);border-color:var(--blue);color:#fff}
.page-btn.disabled{opacity:.4;pointer-events:none}
</style>
</head>
<body>

<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">
  <header class="topbar">
    <div class="topbar-title">🧾 Hóa đơn</div>
    <div class="topbar-right">
      <span class="topbar-pill">📋 ${totalCount} hóa đơn</span>
      <a href="${pageContext.request.contextPath}/admin-profile" class="topbar-user">
        <div class="topbar-av"><%= initials %></div>
        <span class="topbar-name"><%= fullName %></span>
      </a>
    </div>
  </header>

  <div class="content">
    <div class="page-head">
      <div class="page-head-left">
        <div class="breadcrumb">medicare › Quản lý › Hóa đơn</div>
        <h1>Hóa đơn bán hàng</h1>
      </div>
    </div>

    <div class="section-tabs">
      <a href="${pageContext.request.contextPath}/invoices" class="section-tab active">🧾 Hóa đơn</a>
      <a href="${pageContext.request.contextPath}/returns" class="section-tab">↩️ Trả hàng</a>
    </div>

    <div class="table-card">
      <form method="get" action="${pageContext.request.contextPath}/invoices" class="filter-row">
        <div class="filter-search">
          <input type="text" name="q" placeholder="Tìm mã HĐ, tên/SĐT khách hàng…" value="${filterKeyword}">
        </div>
        <input type="date" name="from" value="${filterFrom}" title="Từ ngày">
        <input type="date" name="to" value="${filterTo}" title="Đến ngày">
        <select name="status">
          <option value="">Tất cả trạng thái</option>
          <option value="COMPLETED" ${filterStatus == 'COMPLETED' ? 'selected' : ''}>Hoàn tất</option>
          <option value="CANCELLED" ${filterStatus == 'CANCELLED' ? 'selected' : ''}>Đã hủy</option>
          <option value="PENDING"   ${filterStatus == 'PENDING'   ? 'selected' : ''}>Đang xử lý</option>
        </select>
        <select name="payment">
          <option value="">Tất cả thanh toán</option>
          <option value="CASH"     ${filterPayment == 'CASH'     ? 'selected' : ''}>Tiền mặt</option>
          <option value="CARD"     ${filterPayment == 'CARD'     ? 'selected' : ''}>Thẻ</option>
          <option value="TRANSFER" ${filterPayment == 'TRANSFER' ? 'selected' : ''}>Chuyển khoản</option>
          <option value="EWALLET"  ${filterPayment == 'EWALLET'  ? 'selected' : ''}>Ví điện tử</option>
          <option value="QR_CODE"  ${filterPayment == 'QR_CODE'  ? 'selected' : ''}>QR Code</option>
        </select>
        <select name="staff">
          <option value="">Tất cả nhân viên</option>
          <c:forEach var="s" items="${allStaff}">
            <option value="${s.accountId}" ${filterStaff == s.accountId.toString() ? 'selected' : ''}>${s.fullName}</option>
          </c:forEach>
        </select>
        <button type="submit" class="filter-chip">🔍 Lọc</button>
        <a href="${pageContext.request.contextPath}/invoices" class="filter-clear">✕ Xóa lọc</a>
      </form>

      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Mã HĐ</th><th>Thời gian</th><th>Nhân viên</th><th>Khách hàng</th>
              <th>Thanh toán</th><th>Giảm giá</th><th>Thành tiền</th><th>Trạng thái</th>
            </tr>
          </thead>
          <tbody>
            <c:if test="${empty invoices}">
              <tr><td colspan="8" class="empty-row">Không có hóa đơn nào khớp với bộ lọc hiện tại.</td></tr>
            </c:if>
            <c:forEach var="inv" items="${invoices}">
              <tr onclick="openInvOff(${inv.invoiceId})" style="cursor:pointer">
                <td><span class="inv-code">${inv.invoiceCode}</span></td>
                <td style="color:var(--muted);font-size:12.5px">${fn:substring(inv.createdAt.toString(),0,16)}</td>
                <td>${accountMap[inv.accountId] != null ? accountMap[inv.accountId].fullName : 'ID ' += inv.accountId}</td>
                <td>
                  <c:choose>
                    <c:when test="${inv.customerId != null && customerMap[inv.customerId] != null}">${customerMap[inv.customerId].customerName}</c:when>
                    <c:otherwise><span style="color:var(--muted)">Khách vãng lai</span></c:otherwise>
                  </c:choose>
                </td>
                <td><span class="pay-badge">
                  <c:choose>
                    <c:when test="${inv.paymentMethod == 'CASH'}">💵 Tiền mặt</c:when>
                    <c:when test="${inv.paymentMethod == 'CARD'}">💳 Thẻ</c:when>
                    <c:when test="${inv.paymentMethod == 'TRANSFER'}">🏦 Chuyển khoản</c:when>
                    <c:when test="${inv.paymentMethod == 'EWALLET'}">📱 Ví điện tử</c:when>
                    <c:when test="${inv.paymentMethod == 'QR_CODE'}">🔲 QR Code</c:when>
                    <c:otherwise>${inv.paymentMethod}</c:otherwise>
                  </c:choose>
                </span></td>
                <td>
                  <c:choose>
                    <c:when test="${inv.discountAmount != null && inv.discountAmount > 0}">
                      <span style="color:var(--red)">-<fmt:formatNumber value="${inv.discountAmount}" type="number" maxFractionDigits="0"/>đ</span>
                    </c:when>
                    <c:otherwise><span style="color:var(--muted)">—</span></c:otherwise>
                  </c:choose>
                </td>
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

      <div class="pagination">
        <div class="pagination-info">Trang ${currentPage} / ${totalPages} · Tổng ${totalCount} hóa đơn</div>
        <div class="pagination-btns">
          <c:set var="qs" value="q=${filterKeyword}&from=${filterFrom}&to=${filterTo}&status=${filterStatus}&payment=${filterPayment}&staff=${filterStaff}"/>
          <a href="${pageContext.request.contextPath}/invoices?${qs}&page=${currentPage - 1}"
             class="page-btn ${currentPage <= 1 ? 'disabled' : ''}">‹</a>
          <c:forEach begin="${currentPage - 2 > 1 ? currentPage - 2 : 1}"
                     end="${currentPage + 2 < totalPages ? currentPage + 2 : totalPages}" var="p">
            <a href="${pageContext.request.contextPath}/invoices?${qs}&page=${p}"
               class="page-btn ${p == currentPage ? 'active' : ''}">${p}</a>
          </c:forEach>
          <a href="${pageContext.request.contextPath}/invoices?${qs}&page=${currentPage + 1}"
             class="page-btn ${currentPage >= totalPages ? 'disabled' : ''}">›</a>
        </div>
      </div>
    </div>
  </div>
</div>

<%-- ══ OFFCANVAS chi tiết hóa đơn — xem tại chỗ, không chuyển trang ══ --%>
<div id="invOffBackdrop" style="display:none;position:fixed;inset:0;z-index:900;background:rgba(11,22,40,.45);backdrop-filter:blur(3px)" onclick="closeInvOff()"></div>
<aside id="invOffcanvas" style="position:fixed;top:0;right:-480px;bottom:0;width:460px;max-width:94vw;z-index:901;background:#fff;box-shadow:-16px 0 50px rgba(0,0,0,.25);display:flex;flex-direction:column;transition:right .28s cubic-bezier(.2,.7,.3,1)">
  <div style="padding:18px 22px;background:linear-gradient(135deg,#0F2645,#1558A8);color:#fff;display:flex;align-items:center;justify-content:space-between;flex-shrink:0">
    <div>
      <div style="font-size:16px;font-weight:800" id="ioCode">—</div>
      <div style="font-size:11.5px;opacity:.75;margin-top:2px" id="ioTime">—</div>
    </div>
    <button onclick="closeInvOff()" style="background:rgba(255,255,255,.15);border:none;color:#fff;width:32px;height:32px;border-radius:9px;font-size:15px;cursor:pointer">✕</button>
  </div>
  <div id="invOffBody" style="flex:1;overflow-y:auto;padding:18px 22px">
    <div style="text-align:center;color:#94a3b8;padding:30px 0">Đang tải…</div>
  </div>
  <div style="padding:14px 22px;border-top:1px solid #e2e8f0;display:flex;gap:10px;flex-shrink:0">
    <button onclick="printInvOff()" style="flex:1;padding:11px;background:#EFF6FF;color:#1558A8;border:1.5px solid #BFDBFE;border-radius:10px;font-weight:700;font-size:13px;cursor:pointer;font-family:inherit">🖨️ In lại hóa đơn</button>
    <a id="ioFullLink" href="#" style="flex:1;padding:11px;background:#1558A8;color:#fff;border:none;border-radius:10px;font-weight:700;font-size:13px;cursor:pointer;font-family:inherit;text-decoration:none;text-align:center">📄 Trang đầy đủ</a>
  </div>
</aside>

<script>
const IO_CTX = '${pageContext.request.contextPath}';
let _ioData = null;

function openInvOff(id) {
  document.getElementById('invOffBackdrop').style.display = 'block';
  document.getElementById('invOffcanvas').style.right = '0';
  document.getElementById('ioFullLink').href = IO_CTX + '/invoices?action=detail&id=' + id;
  const body = document.getElementById('invOffBody');
  body.innerHTML = '<div style="text-align:center;color:#94a3b8;padding:30px 0">Đang tải…</div>';
  fetch(IO_CTX + '/invoices?action=detail-json&id=' + id)
    .then(r => r.json())
    .then(d => {
      if (!d.ok) { body.innerHTML = '<div style="color:#DC2626;text-align:center;padding:24px 0">Không tải được hóa đơn.</div>'; return; }
      _ioData = d;
      document.getElementById('ioCode').textContent = d.code;
      document.getElementById('ioTime').textContent = d.time + (d.station > 0 ? ' · Quầy ' + d.station : '');
      const fmtV = n => new Intl.NumberFormat('vi-VN').format(n) + 'đ';
      const mLbl = { CASH:'💵 Tiền mặt', CARD:'💳 Thẻ', TRANSFER:'🏦 CK', EWALLET:'📱 Ví', QR_CODE:'🔲 QR' };
      const stLbl = { COMPLETED:['✅ Hoàn tất','#ECFDF5','#047857'], CANCELLED:['❌ Đã hủy','#FEF2F2','#B91C1C'], PENDING:['⏳ Đang xử lý','#FFFBEB','#B45309'] };
      const st = stLbl[d.status] || [d.status,'#F1F5F9','#475569'];
      body.innerHTML =
        '<div style="display:grid;grid-template-columns:1fr 1fr;gap:9px;margin-bottom:16px;font-size:12.5px">'
        + ioCell('Nhân viên lập', d.staff)
        + ioCell('Khách hàng', d.customer ? d.customer + (d.customerPhone ? '<br><span style=\'color:#94a3b8;font-size:11px\'>' + d.customerPhone + '</span>' : '') : '<span style="color:#94a3b8">Khách vãng lai</span>')
        + ioCell('Thanh toán', mLbl[d.method] || d.method)
        + ioCell('Trạng thái', '<span style="background:' + st[1] + ';color:' + st[2] + ';padding:2px 10px;border-radius:12px;font-weight:800;font-size:11.5px">' + st[0] + '</span>')
        + '</div>'
        + '<div style="font-size:11px;font-weight:800;color:#94a3b8;letter-spacing:.6px;margin-bottom:8px">DANH MỤC THUỐC (' + d.items.length + ')</div>'
        + d.items.map(it =>
            '<div style="display:flex;justify-content:space-between;align-items:center;background:#F8FAFC;border-radius:11px;padding:10px 13px;margin-bottom:7px">'
          + '<div style="min-width:0"><div style="font-weight:700;font-size:13px">' + it.name + '</div>'
          + '<div style="font-size:11px;color:#94a3b8">Lô ' + (it.batch || '—') + ' · SL ' + it.qty + ' × ' + fmtV(it.price) + '</div></div>'
          + '<b style="font-size:12.5px;white-space:nowrap;margin-left:10px">' + fmtV(it.subtotal) + '</b></div>').join('')
        + '<div style="border-top:1.5px dashed #e2e8f0;margin-top:14px;padding-top:12px;font-size:13px">'
        + '<div style="display:flex;justify-content:space-between;padding:3px 0"><span style="color:#64748b">Tiền hàng</span><b>' + fmtV(d.gross) + '</b></div>'
        + (d.discount > 0 ? '<div style="display:flex;justify-content:space-between;padding:3px 0"><span style="color:#64748b">Giảm giá</span><b style="color:#DC2626">−' + fmtV(d.discount) + '</b></div>' : '')
        + '<div style="display:flex;justify-content:space-between;align-items:center;background:#EFF6FF;border-radius:11px;padding:11px 14px;margin-top:8px">'
        + '<span style="font-weight:700;color:#1558A8;font-size:12.5px">TỔNG THANH TOÁN</span>'
        + '<b style="font-size:19px;color:#0F2645">' + fmtV(d.total) + '</b></div></div>';
    })
    .catch(() => { body.innerHTML = '<div style="color:#DC2626;text-align:center;padding:24px 0">Lỗi kết nối.</div>'; });
}
function ioCell(label, value) {
  return '<div style="background:#F8FAFC;border-radius:10px;padding:9px 12px">'
    + '<div style="font-size:10px;font-weight:800;color:#94a3b8;text-transform:uppercase;letter-spacing:.5px">' + label + '</div>'
    + '<div style="font-weight:700;margin-top:3px">' + value + '</div></div>';
}
function closeInvOff() {
  document.getElementById('invOffcanvas').style.right = '-480px';
  document.getElementById('invOffBackdrop').style.display = 'none';
}
document.addEventListener('keydown', e => { if (e.key === 'Escape') closeInvOff(); });

function printInvOff() {
  if (!_ioData) return;
  const d = _ioData;
  const fmtV = n => new Intl.NumberFormat('vi-VN').format(n) + 'đ';
  const w = window.open('', '_blank', 'width=420,height=640');
  w.document.write('<html><head><title>' + d.code + '</title><style>'
    + 'body{font-family:monospace;font-size:12px;width:300px;margin:10px auto}h2{text-align:center;font-size:15px;margin:4px 0}'
    + '.c{text-align:center}.r{display:flex;justify-content:space-between;padding:1.5px 0}hr{border:none;border-top:1px dashed #000;margin:7px 0}'
    + '</style></head><body>'
    + '<h2>💊 MediCare</h2><div class="c">HÓA ĐƠN BÁN LẺ</div><div class="c">' + d.code + ' · ' + d.time + '</div><hr>'
    + '<div class="r"><span>Nhân viên:</span><span>' + d.staff + '</span></div>'
    + (d.customer ? '<div class="r"><span>Khách:</span><span>' + d.customer + '</span></div>' : '')
    + '<hr>'
    + d.items.map(it => '<div>' + it.name + '</div><div class="r"><span>' + it.qty + ' x ' + fmtV(it.price) + '</span><span>' + fmtV(it.subtotal) + '</span></div>').join('')
    + '<hr>'
    + (d.discount > 0 ? '<div class="r"><span>Giảm giá</span><span>-' + fmtV(d.discount) + '</span></div>' : '')
    + '<div class="r" style="font-weight:bold;font-size:14px"><span>TỔNG</span><span>' + fmtV(d.total) + '</span></div>'
    + '<hr><div class="c">Cảm ơn quý khách!</div>'
    + '</body></html>');
  w.document.close();
  w.focus();
  setTimeout(() => { w.print(); w.close(); }, 250);
}
</script>
</body>
</html>

