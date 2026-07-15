<%@ page contentType="text/html;charset=UTF-8"  pageEncoding="UTF-8" %>
<% String activeNav = "returns"; %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
    String msg = request.getParameter("msg");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
    
    
    
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Trả hàng — MediCare</title>


<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;--sidebar:232px;--radius:14px;
}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-text{font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-text span{color:var(--cyan)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:12px 0 4px;flex-shrink:0}
.nav-label{font-size:9px;font-weight:750;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:750;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.14);font-weight:750}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--cyan);border-radius:2px}
.nav-badge{margin-left:auto;background:#DC2626;color:#fff;font-size:10px;font-weight:750;padding:1px 7px;border-radius:20px;min-width:20px;text-align:center}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50;flex-shrink:0}
.topbar-title{font-family:'Plus Jakarta Sans',sans-serif;font-size:16px;font-weight:750;color:var(--ink)}

    
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.topbar-pill{display:inline-flex;align-items:center;gap:6px;padding:4px 12px;border-radius:20px;font-size:12.5px;font-weight:750;background:#EFF6FF;color:var(--blue)}
.topbar-user{display:flex;align-items:center;gap:8px;padding:5px 12px 5px 7px;border:1.5px solid var(--border);border-radius:20px;text-decoration:none;color:inherit}
.topbar-av{width:28px;height:28px;border-radius:8px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;color:#fff}
.topbar-name{font-size:13px;font-weight:750;color:var(--navy)}
.content{padding:22px 26px;flex:1;min-width:0}
.page-head{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:18px}
.page-head-left .breadcrumb{font-size:11.5px;color:var(--muted);font-weight:750;margin-bottom:4px}
.page-head-left h1{font-size:26px;color:var(--ink)}
.btn-primary{display:inline-flex;align-items:center;gap:7px;padding:10px 18px;background:#C2410C;color:#fff;border:none;border-radius:10px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;font-weight:750;cursor:pointer;text-decoration:none}
.btn-primary:hover{transform:translateY(-1px)}
.section-tabs{display:flex;gap:6px;background:var(--white);border:1px solid var(--border);border-radius:12px;padding:4px;width:fit-content;margin-bottom:18px}
.section-tab{padding:8px 18px;border-radius:9px;font-size:13px;font-weight:750;color:var(--muted);text-decoration:none;transition:all .15s}
.section-tab:hover{background:var(--surface);color:var(--ink)}
.section-tab.active{background:linear-gradient(135deg,var(--blue),var(--cyan));color:#fff;box-shadow:0 3px 10px rgba(21,88,168,.25)}
.table-card{background:#fff;border:1px solid rgba(213,224,240,.45);border-radius:var(--radius);overflow:hidden;box-shadow:0 1px 3px rgba(15,38,69,.03),0 4px 12px rgba(15,38,69,.04)}
.table-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse}
thead th{padding:10px 16px;background:#F8FAFC;font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;white-space:nowrap;border-bottom:1px solid var(--border)}
tbody td{padding:12px 16px;font-size:13px;color:var(--ink);border-bottom:1px solid #F1F5F9;vertical-align:middle}
tbody tr:last-child td{border-bottom:none}
tbody tr:hover td{background:#F7FBFF}
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11px;font-weight:750;white-space:nowrap}
.badge-customer{background:#EFF6FF;color:var(--blue)}
.badge-expired{background:#FEF2F2;color:var(--red)}
.badge-recall{background:#FFFBEB;color:var(--gold)}
.badge-yes{background:#ECFDF5;color:var(--green)}
.badge-no{background:#F1F5F9;color:#64748B}
.reason-cell{max-width:220px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;color:var(--muted);font-size:12.5px}
.empty-row{text-align:center;padding:48px;color:var(--muted)}
.toast{position:fixed;top:18px;right:22px;padding:11px 18px;border-radius:10px;font-size:13px;font-weight:750;color:#fff;z-index:9999;box-shadow:0 4px 18px rgba(0,0,0,.15)}
.toast-ok{background:var(--green)}.toast-err{background:var(--red)}
</style>
    
</head>
<body>

<% if ("created".equals(msg)) { %><div class="toast toast-ok" id="toast">✅ Đã tạo phiếu thành công! Kho đã được cập nhật.</div>
<% } else if ("error".equals(msg)) { %><div class="toast toast-err" id="toast">❌ Có lỗi xảy ra!</div>
<% } else if ("invalid-invoice".equals(msg)) { %><div class="toast toast-err" id="toast">❌ Hóa đơn không hợp lệ hoặc chưa hoàn tất!</div>
<% } else if ("invalid-batch".equals(msg)) { %><div class="toast toast-err" id="toast">❌ Lô thuốc không tồn tại!</div>
<% } %>

<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">
  <header class="topbar">
    <div class="topbar-title">↩️ Trả hàng</div>
    <div class="topbar-right">
      <span class="topbar-pill">📋 ${totalCount} phiếu</span>
      <a href="${pageContext.request.contextPath}/admin-profile" class="topbar-user">
        <div class="topbar-av"><%= initials %></div>
        <span class="topbar-name"><%= fullName %></span>
      </a>
    </div>
  </header>

  <div class="content">
    <div class="page-head">
      <div class="page-head-left">
        <div class="breadcrumb">medicare › Quản lý › Trả hàng</div>
        <h1>Trả hàng &amp; hủy hàng</h1>
      </div>
      <a href="${pageContext.request.contextPath}/returns?action=new" class="btn-primary">＋ Tạo phiếu</a>
    </div>

    <div class="section-tabs">
      <a href="${pageContext.request.contextPath}/invoices" class="section-tab">🧾 Hóa đơn</a>
      <a href="${pageContext.request.contextPath}/returns" class="section-tab active">↩️ Trả hàng</a>
    </div>

    <div class="table-card">
      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>#</th><th>Loại</th><th>Sản phẩm</th><th>SL</th><th>Hóa đơn liên quan</th>
              <th>Cộng lại kho?</th><th>Lý do</th><th>Người xử lý</th><th>Thời gian</th>
            </tr>
          </thead>
          <tbody>
            <c:if test="${empty returns}">
              <tr><td colspan="9" class="empty-row">Chưa có phiếu trả/hủy hàng nào.</td></tr>
            </c:if>
            <c:forEach var="r" items="${returns}">
              <c:set var="batch" value="${batchMap[r.batchId]}"/>
              <tr>
                <td style="color:var(--muted);font-size:12px">#${r.returnId}</td>
                <td>
                  <c:choose>
                    <c:when test="${r.returnType == 'CUSTOMER_RETURN'}"><span class="badge badge-customer">🧾 Khách trả</span></c:when>
                    <c:when test="${r.returnType == 'EXPIRED_DESTROY'}"><span class="badge badge-expired">🗑️ Hết hạn</span></c:when>
                    <c:otherwise><span class="badge badge-recall">⚠️ Thu hồi</span></c:otherwise>
                  </c:choose>
                </td>
                <td style="font-weight:750">
                  ${batch != null && medicineMap[batch.medicineId] != null ? medicineMap[batch.medicineId].medicineName : 'Lô #' += r.batchId}
                  <div style="font-size:11px;color:var(--muted);font-weight:400">Lô ${batch != null ? batch.batchNumber : '—'}</div>
                </td>
                <td style="font-weight:800">${r.quantity}</td>
                <td>
                  <c:if test="${r.invoiceId != null}">
                    <a href="${pageContext.request.contextPath}/invoices?action=detail&id=${r.invoiceId}" style="color:var(--blue);font-family:monospace;font-size:12.5px">Xem HĐ →</a>
                  </c:if>
                  <c:if test="${r.invoiceId == null}"><span style="color:var(--muted)">—</span></c:if>
                </td>
                <td>
                  <c:choose>
                    <c:when test="${r.restoreStock}"><span class="badge badge-yes">✅ Có</span></c:when>
                    <c:otherwise><span class="badge badge-no">— Không</span></c:otherwise>
                  </c:choose>
                </td>
                <td class="reason-cell" title="${r.reason}">${r.reason}</td>
                <td>${accountMap[r.accountId] != null ? accountMap[r.accountId].fullName : 'ID ' += r.accountId}</td>
                <td style="color:var(--muted);font-size:12.5px">${fn:substring(r.createdAt.toString(),0,16)}</td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<script>
const t = document.getElementById('toast');
if (t) setTimeout(() => { t.style.opacity='0'; t.style.transition='opacity .4s'; setTimeout(()=>t.remove(),400); }, 4000);
</script>
</body>
</html>

