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
<title>Nhà cung cấp — MediCare</title>

<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;--cyan-soft:#EBF8FD;--surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;--green:#059669;--red:#DC2626;--gold:#D97706;--sidebar:232px;}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}
/* Sidebar CSS: dùng bản chuẩn từ sidebar.jsp include bên dưới, không định nghĩa lại ở đây. */
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-size:16px;font-weight:750;color:var(--ink)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.btn-primary{height:36px;padding:0 16px;background:var(--blue);color:#fff;border:none;border-radius:9px;font-size:13px;font-weight:750;cursor:pointer;text-decoration:none;display:inline-flex;align-items:center;gap:6px;font-family:inherit}
.btn-primary:hover{background:#0d3d63}
.content{padding:24px 28px;flex:1}
.page-header{margin-bottom:20px;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px}
.page-title{font-size:26px;font-weight:800}.page-sub{font-size:13px;color:var(--muted);margin-top:3px}
.toast-bar{padding:12px 18px;border-radius:11px;margin-bottom:18px;font-size:13.5px;font-weight:750;display:flex;align-items:center;gap:8px}
.toast-ok{background:#D1FAE5;color:#065F46;border:1px solid #A7F3D0}
.toast-del{background:#FEE2E2;color:#991B1B;border:1px solid #FECACA}
.card{background:var(--white);border:1px solid var(--border);border-radius:16px;overflow:hidden;box-shadow:0 2px 8px rgba(21,88,168,.04)}
table{width:100%;border-collapse:collapse}
thead th{padding:12px 16px;text-align:left;font-size:12px;font-weight:750;color:var(--muted);letter-spacing:.5px;text-transform:uppercase;background:var(--surface);border-bottom:1px solid var(--border)}
tbody tr{border-bottom:1px solid var(--border)}tbody tr:last-child{border-bottom:none}tbody tr:hover{background:#F8FAFF}
td{padding:14px 16px;font-size:13.5px;color:var(--ink);vertical-align:middle}
.td-id{color:var(--muted);font-size:12px;font-weight:750}.td-muted{color:var(--muted);font-size:12.5px}
.actions{display:flex;gap:6px}
.btn-edit{height:30px;padding:0 12px;background:var(--cyan-soft);border:1.5px solid rgba(58,189,224,.3);border-radius:7px;font-size:12px;font-weight:750;color:var(--blue);text-decoration:none;display:inline-flex;align-items:center;gap:4px}
.btn-edit:hover{background:#D0F4FC}
.btn-tog{height:30px;padding:0 12px;background:#FFF7ED;border:1.5px solid #FED7AA;border-radius:7px;font-size:12px;font-weight:750;color:var(--gold);text-decoration:none;display:inline-flex;align-items:center;gap:4px}
.btn-tog:hover{background:#FFEDD5}
.empty{padding:48px;text-align:center;color:var(--muted)}.empty-icon{font-size:40px;margin-bottom:12px}
.badge{display:inline-flex;align-items:center;padding:2px 10px;border-radius:20px;font-size:11px;font-weight:750}
.b-on{background:#D1FAE5;color:#065F46}.b-off{background:#F1F5F9;color:#64748B}
.section-tabs{display:flex;gap:6px;background:var(--white);border:1px solid var(--border);border-radius:12px;padding:4px;width:fit-content;margin-bottom:20px;flex-wrap:wrap}
.section-tab{padding:8px 16px;border-radius:9px;font-size:13px;font-weight:750;color:var(--muted);text-decoration:none;transition:all .15s;white-space:nowrap}
.section-tab:hover{background:var(--surface);color:var(--ink)}
.section-tab.active{background:linear-gradient(135deg,var(--blue),var(--cyan));color:#fff;box-shadow:0 3px 10px rgba(21,88,168,.25)}
</style>
    
</head>
<body>
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>
<div class="main">
  <div class="topbar">
    <span class="topbar-title">🏭 Nhà cung cấp</span>
    <div class="topbar-right">
      <a href="${pageContext.request.contextPath}/suppliers?action=new" class="btn-primary">+ Thêm nhà cung cấp</a>
    </div>
  </div>
  <div class="content">
    <div class="page-header">
      <div><div class="page-title">Nhà cung cấp</div>
        <div class="page-sub">Danh sách đối tác cung cấp thuốc — <c:out value="${suppliers.size()}"/> NCC</div></div>
    </div>
    <div class="section-tabs">
      <a href="${pageContext.request.contextPath}/medicines" class="section-tab">💊 Thuốc &amp; Lô hàng</a>
      <a href="${pageContext.request.contextPath}/purchase-orders" class="section-tab">📑 Đơn đặt hàng</a>
      <a href="${pageContext.request.contextPath}/categories" class="section-tab">🏷️ Danh mục</a>
      <a href="${pageContext.request.contextPath}/suppliers" class="section-tab active">🏭 Nhà cung cấp</a>
      <a href="${pageContext.request.contextPath}/shelves" class="section-tab">📍 Vị trí kệ</a>
    </div>
    <% if ("created".equals(msg)) { %><div class="toast-bar toast-ok">✅ Đã thêm nhà cung cấp!</div><% } %>
    <% if ("updated".equals(msg)) { %><div class="toast-bar toast-ok">✅ Đã cập nhật!</div><% } %>
    <% if ("error".equals(msg)) { %><div class="toast-bar toast-del">❌ Có lỗi xảy ra!</div><% } %>

    <div class="card">
      <table>
        <thead><tr>
          <th>#</th><th>Tên NCC</th><th>Người liên hệ</th><th>SĐT</th><th>Email</th><th>Giấy phép</th><th>Trạng thái</th><th style="width:170px">Thao tác</th>
        </tr></thead>
        <tbody>
          <c:choose>
            <c:when test="${empty suppliers}">
              <tr><td colspan="8"><div class="empty"><div class="empty-icon">🏭</div><div>Chưa có nhà cung cấp nào — hãy thêm mới!</div></div></td></tr>
            </c:when>
            <c:otherwise>
              <c:forEach var="s" items="${suppliers}" varStatus="st">
                <tr>
                  <td class="td-id">${st.count}</td>
                  <td><strong><c:out value="${s.supplierName}"/></strong></td>
                  <td class="td-muted"><c:out value="${not empty s.contactName ? s.contactName : '—'}"/></td>
                  <td class="td-muted"><c:out value="${not empty s.phone ? s.phone : '—'}"/></td>
                  <td class="td-muted"><c:out value="${not empty s.email ? s.email : '—'}"/></td>
                  <td class="td-muted"><c:out value="${not empty s.licenseNumber ? s.licenseNumber : '—'}"/></td>
                  <td><c:choose><c:when test="${s.active}"><span class="badge b-on">● Đang hợp tác</span></c:when><c:otherwise><span class="badge b-off">● Ngừng</span></c:otherwise></c:choose></td>
                  <td><div class="actions">
                    <a href="${pageContext.request.contextPath}/suppliers?action=edit&id=${s.supplierId}" class="btn-edit">✏️ Sửa</a>
                    <a href="${pageContext.request.contextPath}/suppliers?action=toggle&id=${s.supplierId}" class="btn-tog">${s.active ? '⏸️ Ngừng' : '▶️ Bật'}</a>
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
</body>
</html>
