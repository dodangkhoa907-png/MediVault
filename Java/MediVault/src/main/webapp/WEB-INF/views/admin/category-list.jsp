<%@ page contentType="text/html;charset=UTF-8"  pageEncoding="UTF-8" %>
<% String activeNav = "medicines"; %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
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
<title>Danh mục thuốc — MediCare</title>


<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;--cyan-soft:#EBF8FD;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;--sidebar:232px;
}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-icon{width:36px;height:36px;background:linear-gradient(135deg,#3ABDE0,#1558A8);border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:18px}
.logo-text{font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-sub{font-size:10px;color:rgba(255,255,255,.45);font-weight:750;letter-spacing:.5px;text-transform:uppercase}
.nav-section{padding:10px 12px 4px;flex-shrink:0}
.nav-label{font-size:9.5px;font-weight:750;color:rgba(255,255,255,.3);letter-spacing:1px;text-transform:uppercase;padding:0 8px;margin-bottom:4px}
.nav-item{display:flex;align-items:center;gap:9px;padding:9px 10px;border-radius:10px;color:rgba(255,255,255,.6);text-decoration:none;font-size:13.5px;font-weight:750;transition:all .16s;margin-bottom:2px}
.nav-item:hover{background:rgba(255,255,255,.07);color:#fff}
.nav-item.active{background:rgba(58,189,224,.15);color:#fff;border:1px solid rgba(58,189,224,.2)}
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06);flex-shrink:0}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08)}
.user-av{width:34px;height:34px;border-radius:50%;background:linear-gradient(135deg,#3ABDE0,#1558A8);display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:800;color:#fff;flex-shrink:0}
.user-name{font-size:13px;font-weight:750;color:#fff}
.user-role{font-size:11px;color:rgba(255,255,255,.4)}
.logout-btn{margin-left:auto;width:30px;height:30px;border-radius:8px;display:flex;align-items:center;justify-content:center;color:rgba(255,255,255,.4);text-decoration:none;font-size:16px;transition:all .15s}
.logout-btn:hover{background:rgba(220,38,38,.2);color:#DC2626}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Plus Jakarta Sans',sans-serif;font-size:16px;font-weight:750;color:var(--ink)}

    
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.btn-primary{height:36px;padding:0 16px;background:var(--blue);color:#fff;border:none;border-radius:9px;font-size:13px;font-weight:750;cursor:pointer;text-decoration:none;display:inline-flex;align-items:center;gap:6px;font-family:inherit;transition:all .15s}
.btn-primary:hover{background:#0d3d63}
.content{padding:24px 28px;flex:1}
.page-header{margin-bottom:20px;display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px}
.page-title{font-size:26px;font-weight:800;color:var(--ink)}
.page-sub{font-size:13px;color:var(--muted);margin-top:3px}
.toast-bar{padding:12px 18px;border-radius:11px;margin-bottom:18px;font-size:13.5px;font-weight:750;display:flex;align-items:center;gap:8px}
.toast-ok{background:#D1FAE5;color:#065F46;border:1px solid #A7F3D0}
.toast-del{background:#FEE2E2;color:#991B1B;border:1px solid #FECACA}
.card{background:var(--white);border:1px solid var(--border);border-radius:16px;overflow:hidden;box-shadow:0 2px 8px rgba(21,88,168,.04)}
table{width:100%;border-collapse:collapse}
thead th{padding:12px 16px;text-align:left;font-size:12px;font-weight:750;color:var(--muted);letter-spacing:.5px;text-transform:uppercase;background:var(--surface);border-bottom:1px solid var(--border)}
tbody tr{border-bottom:1px solid var(--border)}
tbody tr:last-child{border-bottom:none}
tbody tr:hover{background:#F8FAFF}
td{padding:14px 16px;font-size:13.5px;color:var(--ink);vertical-align:middle}
.td-id{color:var(--muted);font-size:12px;font-weight:750}
.td-desc{color:var(--muted);font-size:12.5px}
.actions{display:flex;gap:6px}
.btn-edit{height:30px;padding:0 12px;background:var(--cyan-soft);border:1.5px solid rgba(58,189,224,.3);border-radius:7px;font-size:12px;font-weight:750;color:var(--blue);text-decoration:none;display:inline-flex;align-items:center;gap:4px;transition:all .15s}
.btn-edit:hover{background:#D0F4FC;border-color:var(--cyan)}
.btn-del{height:30px;padding:0 12px;background:#FEF2F2;border:1.5px solid #FECACA;border-radius:7px;font-size:12px;font-weight:750;color:var(--red);cursor:pointer;display:inline-flex;align-items:center;gap:4px;transition:all .15s;font-family:inherit}
.btn-del:hover{background:#FEE2E2}
.empty{padding:48px;text-align:center;color:var(--muted)}
.empty-icon{font-size:40px;margin-bottom:12px}
.badge{display:inline-flex;align-items:center;padding:2px 9px;border-radius:20px;font-size:11px;font-weight:750;background:rgba(21,88,168,.08);color:var(--blue)}
/* ── SECTION TABS ── */
.section-tabs{display:flex;gap:6px;background:var(--white);border:1px solid var(--border);border-radius:12px;padding:4px;width:fit-content;margin-bottom:20px}
.section-tab{padding:8px 18px;border-radius:9px;font-size:13px;font-weight:750;color:var(--muted);text-decoration:none;transition:all .15s}
.section-tab:hover{background:var(--surface);color:var(--ink)}
.section-tab.active{background:linear-gradient(135deg,var(--blue),var(--cyan));color:#fff;box-shadow:0 3px 10px rgba(21,88,168,.25)}
</style>
    
</head>
<body>

<!-- SIDEBAR -->
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<!-- MAIN -->
<div class="main">
  <div class="topbar">
    <span class="topbar-title">🏷️ Danh mục thuốc</span>
    <div class="topbar-right">
      <a href="${pageContext.request.contextPath}/categories?action=new" class="btn-primary">+ Thêm danh mục</a>
    </div>
  </div>

  <div class="content">
    <div class="page-header">
      <div>
        <div class="page-title">Danh mục thuốc</div>
        <div class="page-sub">Phân loại thuốc theo nhóm — <c:out value="${categories.size()}"/> danh mục</div>
      </div>
    </div>

    <%-- Section tabs — navigate giữa Thuốc / Đơn đặt hàng / Danh mục --%>
    <div class="section-tabs">
      <a href="${pageContext.request.contextPath}/medicines" class="section-tab">💊 Thuốc &amp; Lô hàng</a>
      <a href="${pageContext.request.contextPath}/purchase-orders" class="section-tab">📑 Đơn đặt hàng</a>
      <a href="${pageContext.request.contextPath}/categories" class="section-tab active">🏷️ Danh mục</a>
      <a href="${pageContext.request.contextPath}/suppliers" class="section-tab">🏭 Nhà cung cấp</a>
      <a href="${pageContext.request.contextPath}/shelves" class="section-tab">📍 Vị trí kệ</a>
    </div>

    <% if ("created".equals(msg)) { %><div class="toast-bar toast-ok">✅ Đã thêm danh mục mới thành công!</div><% } %>
    <% if ("updated".equals(msg)) { %><div class="toast-bar toast-ok">✅ Đã cập nhật danh mục!</div><% } %>
    <% if ("deleted".equals(msg)) { %><div class="toast-bar toast-del">🗑️ Đã xóa danh mục!</div><% } %>

    <div class="card">
      <table>
        <thead>
          <tr>
            <th>#</th>
            <th>Tên danh mục</th>
            <th>Mô tả</th>
            <th style="width:140px">Thao tác</th>
          </tr>
        </thead>
        <tbody>
          <c:choose>
            <c:when test="${empty categories}">
              <tr><td colspan="4">
                <div class="empty">
                  <div class="empty-icon">🏷️</div>
                  <div>Chưa có danh mục nào — hãy thêm danh mục đầu tiên!</div>
                </div>
              </td></tr>
            </c:when>
            <c:otherwise>
              <c:forEach var="cat" items="${categories}" varStatus="st">
                <tr>
                  <td class="td-id">${st.count}</td>
                  <td><strong><c:out value="${cat.categoryName}"/></strong></td>
                  <td class="td-desc"><c:out value="${cat.description}"/></td>
                  <td>
                    <div class="actions">
                      <a href="${pageContext.request.contextPath}/categories?action=edit&id=${cat.categoryId}" class="btn-edit">✏️ Sửa</a>
                      <button class="btn-del" onclick="confirmDelete(${cat.categoryId}, '${cat.categoryName}')">🗑️ Xóa</button>
                    </div>
                  </td>
                </tr>
              </c:forEach>
            </c:otherwise>
          </c:choose>
        </tbody>
      </table>
    </div>
  </div>
</div>

<!-- Delete confirm modal -->
<div id="delModal" style="display:none;position:fixed;inset:0;background:rgba(11,22,40,.5);z-index:200;align-items:center;justify-content:center">
  <div style="background:#fff;border-radius:16px;padding:28px 32px;max-width:400px;width:90%;box-shadow:0 20px 60px rgba(0,0,0,.2)">
    <div style="font-size:22px;margin-bottom:12px">🗑️</div>
    <div style="font-size:16px;font-weight:750;color:var(--ink);margin-bottom:8px">Xóa danh mục?</div>
    <div style="font-size:13px;color:var(--muted);margin-bottom:20px" id="delMsg"></div>
    <div style="display:flex;gap:10px;justify-content:flex-end">
      <button onclick="document.getElementById('delModal').style.display='none'" style="height:36px;padding:0 16px;border:1.5px solid var(--border);border-radius:9px;background:#fff;font-size:13px;font-weight:750;cursor:pointer;font-family:inherit">Hủy</button>
      <a id="delLink" href="#" style="height:36px;padding:0 16px;background:#DC2626;color:#fff;border-radius:9px;font-size:13px;font-weight:750;text-decoration:none;display:inline-flex;align-items:center">Xóa</a>
    </div>
  </div>
</div>

<script>
function confirmDelete(id, name) {
  document.getElementById('delMsg').textContent = 'Xóa danh mục "' + name + '"? Hành động này không thể hoàn tác.';
  document.getElementById('delLink').href = '${pageContext.request.contextPath}/categories?action=delete&id=' + id;
  const m = document.getElementById('delModal');
  m.style.display = 'flex';
  m.onclick = function(e){ if(e.target===m) m.style.display='none'; };
}
</script>
</body>
</html>
