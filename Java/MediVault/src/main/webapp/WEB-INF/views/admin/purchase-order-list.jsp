<%@ page contentType="text/html;charset=UTF-8" %>
<% String activeNav = "purchase-orders"; %>
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
<title>Đơn đặt hàng — MediCare</title>
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
.topbar{height:60px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50;flex-shrink:0}
.topbar-title{font-size:16px;font-weight:800;color:var(--ink)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.topbar-pill{display:inline-flex;align-items:center;gap:6px;padding:4px 12px;border-radius:20px;font-size:12.5px;font-weight:700;background:#EFF6FF;color:var(--blue)}
.topbar-user{display:flex;align-items:center;gap:8px;padding:5px 12px 5px 7px;border:1.5px solid var(--border);border-radius:20px;text-decoration:none;color:inherit}
.topbar-av{width:26px;height:26px;border-radius:7px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:10px;font-weight:800;color:#fff}
.topbar-name{font-size:12.5px;font-weight:600;color:var(--navy)}
.content{padding:22px 26px;flex:1;min-width:0}
.page-head{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:20px}
.page-head-left .breadcrumb{font-size:11.5px;color:var(--muted);font-weight:500;margin-bottom:4px}
.page-head-left h1{font-size:26px;color:var(--ink)}
.section-tabs{display:flex;gap:6px;background:var(--white);border:1px solid var(--border);border-radius:12px;padding:4px;width:fit-content;margin-bottom:18px}
.section-tab{padding:8px 18px;border-radius:9px;font-size:13px;font-weight:600;color:var(--muted);text-decoration:none;transition:all .15s}
.section-tab:hover{background:var(--surface);color:var(--ink)}
.section-tab.active{background:linear-gradient(135deg,var(--blue),var(--cyan));color:#fff;box-shadow:0 3px 10px rgba(21,88,168,.25)}
.btn-primary{display:inline-flex;align-items:center;gap:7px;padding:10px 18px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;border-radius:10px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;text-decoration:none}
.btn-primary:hover{transform:translateY(-1px)}
.table-card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}
.table-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse}
thead th{padding:10px 16px;background:#F8FAFC;font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;white-space:nowrap;border-bottom:1px solid var(--border)}
tbody td{padding:13px 16px;font-size:13px;color:var(--ink);border-bottom:1px solid #F1F5F9;vertical-align:middle}
tbody tr:last-child td{border-bottom:none}
tbody tr:hover td{background:#F7FBFF}
.po-code{font-family:monospace;font-weight:700;color:var(--blue)}
.btn-detail{display:inline-flex;align-items:center;gap:5px;padding:5px 11px;background:#EFF6FF;color:var(--blue);border:1.5px solid #BFDBFE;border-radius:7px;font-size:12px;font-weight:700;text-decoration:none}
.btn-detail:hover{background:#DBEAFE}
.empty-row{text-align:center;padding:48px;color:var(--muted)}
.toast{position:fixed;top:18px;right:22px;padding:11px 18px;border-radius:10px;font-size:13px;font-weight:700;color:#fff;z-index:9999;box-shadow:0 4px 18px rgba(0,0,0,.15)}
.toast-ok{background:var(--green)}.toast-err{background:var(--red)}
</style>
</head>
<body>

<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">
  <c:if test="${not empty param.msg}">
    <c:choose>
      <c:when test="${param.msg == 'created'}"><div class="toast toast-ok" id="toast">✅ Tạo đơn đặt hàng thành công!</div></c:when>
      <c:when test="${param.msg == 'not-found'}"><div class="toast toast-err" id="toast">❌ Không tìm thấy đơn đặt hàng!</div></c:when>
      <c:otherwise><div class="toast toast-err" id="toast">❌ Có lỗi xảy ra!</div></c:otherwise>
    </c:choose>
  </c:if>

  <header class="topbar">
    <div class="topbar-title">📑 Đơn đặt hàng</div>
    <div class="topbar-right">
      <span class="topbar-pill">📋 ${fn:length(pos)} đơn</span>
      <a href="${pageContext.request.contextPath}/dashboard" class="topbar-user">
        <div class="topbar-av"><%= initials %></div>
        <span class="topbar-name"><%= fullName %></span>
      </a>
    </div>
  </header>

  <div class="content">
    <div class="page-head">
      <div class="page-head-left">
        <div class="breadcrumb">medicare › Quản lý › Đơn đặt hàng</div>
        <h1>Đơn đặt hàng</h1>
      </div>
      <a href="${pageContext.request.contextPath}/purchase-orders?action=new" class="btn-primary">＋ Tạo đơn mới</a>
    </div>

    <div class="section-tabs">
      <a href="${pageContext.request.contextPath}/medicines" class="section-tab">💊 Thuốc &amp; Lô hàng</a>
      <a href="${pageContext.request.contextPath}/purchase-orders" class="section-tab active">📑 Đơn đặt hàng</a>
    </div>

    <div class="table-card">
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Mã đơn</th><th>Nhà cung cấp</th><th>Người tạo</th>
              <th>Ngày đặt</th><th>Số lô hàng</th><th>Tổng giá trị</th><th></th>
            </tr>
          </thead>
          <tbody>
            <c:if test="${empty pos}">
              <tr><td colspan="7" class="empty-row">Chưa có đơn đặt hàng nào. Bấm "Tạo đơn mới" để bắt đầu nhập kho.</td></tr>
            </c:if>
            <c:forEach var="po" items="${pos}">
              <tr onclick="location.href='${pageContext.request.contextPath}/purchase-orders?action=detail&id=${po.poId}'">
                <td><span class="po-code">${po.poCode}</span></td>
                <td style="font-weight:600">${supplierMap[po.supplierId] != null ? supplierMap[po.supplierId].supplierName : 'NCC #'.concat(po.supplierId)}</td>
                <td>${accountMap[po.accountId] != null ? accountMap[po.accountId].fullName : 'ID '.concat(po.accountId)}</td>
                <td style="color:var(--muted);font-size:12.5px">${fn:substring(po.orderDate.toString(),0,16)}</td>
                <td>${batchCountMap[po.poId]} lô</td>
                <td style="font-weight:800"><fmt:formatNumber value="${po.totalValue}" type="number" maxFractionDigits="0"/>đ</td>
                <td><a href="${pageContext.request.contextPath}/purchase-orders?action=detail&id=${po.poId}" class="btn-detail" onclick="event.stopPropagation()">Xem →</a></td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>
<script>
setTimeout(()=>{ const t=document.getElementById('toast'); if(t) t.style.display='none'; }, 3500);
</script>
</body>
</html>
