<%@ page contentType="text/html;charset=UTF-8"  pageEncoding="UTF-8" %>
<% String activeNav = "medicines"; %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length() >= 2 ? fullName.substring(0,2).toUpperCase() : fullName.toUpperCase();
    String msg = request.getParameter("msg");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
    
    
    
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Vị trí kệ — MediCare</title>

<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;--cyan-soft:#EBF8FD;--surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;--green:#059669;--red:#DC2626;--gold:#D97706;--sidebar:232px;}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}
/* Sidebar CSS: dùng bản chuẩn từ sidebar.jsp include bên dưới, không định nghĩa lại ở đây. */
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-size:16px;font-weight:750}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.btn-primary{height:36px;padding:0 16px;background:var(--blue);color:#fff;border:none;border-radius:9px;font-size:13px;font-weight:750;text-decoration:none;display:inline-flex;align-items:center;gap:6px}
.btn-primary:hover{background:#0d3d63}
.content{padding:24px 28px;flex:1}
.page-header{margin-bottom:20px}
.page-title{font-size:26px;font-weight:800}.page-sub{font-size:13px;color:var(--muted);margin-top:3px}
.toast-bar{padding:12px 18px;border-radius:11px;margin-bottom:18px;font-size:13.5px;font-weight:750}
.toast-ok{background:#D1FAE5;color:#065F46;border:1px solid #A7F3D0}
.toast-del{background:#FEE2E2;color:#991B1B;border:1px solid #FECACA}
.toast-warn{background:#FFFBEB;color:#92400E;border:1px solid #FDE68A}
.card{background:var(--white);border:1px solid var(--border);border-radius:16px;overflow:hidden;box-shadow:0 2px 8px rgba(21,88,168,.04)}
table{width:100%;border-collapse:collapse}
thead th{padding:12px 16px;text-align:left;font-size:12px;font-weight:750;color:var(--muted);letter-spacing:.5px;text-transform:uppercase;background:var(--surface);border-bottom:1px solid var(--border)}
tbody tr{border-bottom:1px solid var(--border)}tbody tr:last-child{border-bottom:none}tbody tr:hover{background:#F8FAFF}
td{padding:14px 16px;font-size:13.5px;vertical-align:middle}.td-id{color:var(--muted);font-size:12px;font-weight:750}.td-muted{color:var(--muted);font-size:12.5px}
.actions{display:flex;gap:6px}
.btn-edit{height:30px;padding:0 12px;background:var(--cyan-soft);border:1.5px solid rgba(58,189,224,.3);border-radius:7px;font-size:12px;font-weight:750;color:var(--blue);text-decoration:none;display:inline-flex;align-items:center;gap:4px}
.btn-del{height:30px;padding:0 12px;background:#FEF2F2;border:1.5px solid #FECACA;border-radius:7px;font-size:12px;font-weight:750;color:var(--red);cursor:pointer;display:inline-flex;align-items:center;gap:4px;font-family:inherit}
.btn-del:hover{background:#FEE2E2}
.empty{padding:48px;text-align:center;color:var(--muted)}.empty-icon{font-size:40px;margin-bottom:12px}
.badge{display:inline-flex;align-items:center;padding:2px 10px;border-radius:20px;font-size:11px;font-weight:750}
.b-retail{background:#EFF6FF;color:#1558A8}.b-storage{background:#F5F3FF;color:#7C3AED}.b-machine{background:#ECFDF5;color:#059669}
.section-tabs{display:flex;gap:6px;background:var(--white);border:1px solid var(--border);border-radius:12px;padding:4px;width:fit-content;margin-bottom:20px;flex-wrap:wrap}
.section-tab{padding:8px 16px;border-radius:9px;font-size:13px;font-weight:750;color:var(--muted);text-decoration:none;white-space:nowrap}
.section-tab:hover{background:var(--surface);color:var(--ink)}.section-tab.active{background:linear-gradient(135deg,var(--blue),var(--cyan));color:#fff;box-shadow:0 3px 10px rgba(21,88,168,.25)}
</style>
    
<meta name="csrf-token" content="${csrfToken}">
<script src="${pageContext.request.contextPath}/js/csrf.js"></script>
</head>
<body>
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>
<div class="main">
  <div class="topbar">
    <span class="topbar-title">📍 Vị trí kệ</span>
    <div class="topbar-right"><a href="${pageContext.request.contextPath}/shelves?action=new" class="btn-primary">+ Thêm kệ</a></div>
  </div>
  <div class="content">
    <div class="page-header"><div class="page-title">Vị trí kệ</div>
      <div class="page-sub">Sơ đồ vị trí lưu thuốc trong nhà thuốc — <c:out value="${shelves.size()}"/> kệ</div></div>
    <div class="section-tabs">
      <a href="${pageContext.request.contextPath}/medicines" class="section-tab">💊 Thuốc &amp; Lô hàng</a>
      <a href="${pageContext.request.contextPath}/purchase-orders" class="section-tab">📑 Đơn đặt hàng</a>
      <a href="${pageContext.request.contextPath}/categories" class="section-tab">🏷️ Danh mục</a>
      <a href="${pageContext.request.contextPath}/suppliers" class="section-tab">🏭 Nhà cung cấp</a>
      <a href="${pageContext.request.contextPath}/shelves" class="section-tab active">📍 Vị trí kệ</a>
    </div>
    <% if ("created".equals(msg)) { %><div class="toast-bar toast-ok">✅ Đã thêm kệ!</div><% } %>
    <% if ("updated".equals(msg)) { %><div class="toast-bar toast-ok">✅ Đã cập nhật kệ!</div><% } %>
    <% if ("deleted".equals(msg)) { %><div class="toast-bar toast-del">🗑️ Đã xóa kệ!</div><% } %>
    <% if ("has-medicine".equals(msg)) { %><div class="toast-bar toast-warn">⚠️ Không thể xóa: kệ đang có thuốc được gán. Chuyển thuốc sang kệ khác trước.</div><% } %>
    <div class="card">
      <table>
        <thead><tr><th>#</th><th>Tên kệ</th><th>Loại</th><th>Mã ngăn máy</th><th>Ghi chú vị trí</th><th>Tự động</th><th style="width:150px">Thao tác</th></tr></thead>
        <tbody>
          <c:choose>
            <c:when test="${empty shelves}">
              <tr><td colspan="7"><div class="empty"><div class="empty-icon">📍</div><div>Chưa có kệ nào — hãy thêm kệ đầu tiên!</div></div></td></tr>
            </c:when>
            <c:otherwise>
              <c:forEach var="sh" items="${shelves}" varStatus="st">
                <tr>
                  <td class="td-id">${st.count}</td>
                  <td><strong><c:out value="${sh.shelfName}"/></strong></td>
                  <td><c:choose>
                    <c:when test="${sh.shelfType == 'STORAGE'}"><span class="badge b-storage">📦 Kho</span></c:when>
                    <c:when test="${sh.shelfType == 'MACHINE'}"><span class="badge b-machine">🤖 Máy bán</span></c:when>
                    <c:otherwise><span class="badge b-retail">🛒 Quầy bán</span></c:otherwise>
                  </c:choose></td>
                  <td class="td-muted"><c:out value="${not empty sh.machineSlotCode ? sh.machineSlotCode : '—'}"/></td>
                  <td class="td-muted"><c:out value="${not empty sh.locationNotes ? sh.locationNotes : '—'}"/></td>
                  <td class="td-muted">${sh.automated ? '✅ Có' : '—'}</td>
                  <td><div class="actions">
                    <a href="${pageContext.request.contextPath}/shelves?action=edit&id=${sh.shelfId}" class="btn-edit">✏️ Sửa</a>
                    <button class="btn-del" onclick="confirmDelete(${sh.shelfId}, '${sh.shelfName}')">🗑️ Xóa</button>
                  </div></td>
                </tr>
              </c:forEach>
            </c:otherwise>
          </c:choose>
        </tbody>
      </table>
    </div>
  </div>
</div>
<div id="delModal" style="display:none;position:fixed;inset:0;background:rgba(11,22,40,.5);z-index:200;align-items:center;justify-content:center">
  <div style="background:#fff;border-radius:16px;padding:28px 32px;max-width:400px;width:90%">
    <div style="font-size:22px;margin-bottom:12px">🗑️</div>
    <div style="font-size:16px;font-weight:750;margin-bottom:8px">Xóa vị trí kệ?</div>
    <div style="font-size:13px;color:var(--muted);margin-bottom:20px" id="delMsg"></div>
    <div style="display:flex;gap:10px;justify-content:flex-end">
      <button onclick="document.getElementById('delModal').style.display='none'" style="height:36px;padding:0 16px;border:1.5px solid var(--border);border-radius:9px;background:#fff;font-weight:750;cursor:pointer;font-family:inherit">Hủy</button>
      <a id="delLink" href="#" style="height:36px;padding:0 16px;background:#DC2626;color:#fff;border-radius:9px;font-weight:750;text-decoration:none;display:inline-flex;align-items:center">Xóa</a>
    </div>
  </div>
</div>
<script>
function confirmDelete(id, name){
  document.getElementById('delMsg').textContent = 'Xóa kệ "' + name + '"? Chỉ xóa được khi kệ không còn thuốc nào.';
  document.getElementById('delLink').href = '${pageContext.request.contextPath}/shelves?action=delete&id=' + id;
  const m = document.getElementById('delModal'); m.style.display='flex';
  m.onclick = e => { if(e.target===m) m.style.display='none'; };
}
</script>
</body>
</html>
