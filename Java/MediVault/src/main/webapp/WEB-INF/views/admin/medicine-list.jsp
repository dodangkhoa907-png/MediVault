<%@ page contentType="text/html;charset=UTF-8" %>
<% String activeNav = "medicines"; %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
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
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Kho thuốc — medicare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;--cyan-soft:#EBF8FD;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;--sidebar:232px;
}
html,body{height:100%;font-family:'Outfit',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}
/* ── SIDEBAR ── */
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-icon{width:36px;height:36px;background:linear-gradient(135deg,#3ABDE0,#1558A8);border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:18px}
.logo-text{font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-sub{font-size:10px;color:rgba(255,255,255,.45);font-weight:500;letter-spacing:.5px;text-transform:uppercase}
.nav-section{padding:10px 12px 4px;flex-shrink:0}
.nav-label{font-size:9.5px;font-weight:700;color:rgba(255,255,255,.3);letter-spacing:1px;text-transform:uppercase;padding:0 8px;margin-bottom:4px}
.nav-item{display:flex;align-items:center;gap:9px;padding:9px 10px;border-radius:10px;color:rgba(255,255,255,.6);text-decoration:none;font-size:13.5px;font-weight:500;transition:all .16s;margin-bottom:2px}
.nav-item:hover{background:rgba(255,255,255,.07);color:#fff}
.nav-item.active{background:rgba(58,189,224,.15);color:#fff;border:1px solid rgba(58,189,224,.2)}
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06);flex-shrink:0}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08)}
.user-av{width:34px;height:34px;border-radius:50%;background:linear-gradient(135deg,#3ABDE0,#1558A8);display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:800;color:#fff;flex-shrink:0}
.user-name{font-size:13px;font-weight:700;color:#fff}
.user-role{font-size:11px;color:rgba(255,255,255,.4)}
.logout-btn{margin-left:auto;width:30px;height:30px;border-radius:8px;display:flex;align-items:center;justify-content:center;color:rgba(255,255,255,.4);text-decoration:none;font-size:16px;transition:all .15s}
.logout-btn:hover{background:rgba(220,38,38,.2);color:#DC2626}
/* ── MAIN ── */
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Outfit',sans-serif;font-size:16px;color:var(--ink)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.btn-primary{height:36px;padding:0 16px;background:var(--blue);color:#fff;border:none;border-radius:9px;font-size:13px;font-weight:700;cursor:pointer;text-decoration:none;display:inline-flex;align-items:center;gap:6px;font-family:inherit;transition:all .15s}
.btn-primary:hover{background:#0d3d63}
.content{padding:24px 28px;flex:1}
.page-header{margin-bottom:20px}
.page-title{font-family:'Outfit',sans-serif;font-size:26px;color:var(--ink)}
.page-sub{font-size:13px;color:var(--muted);margin-top:3px}
/* ── STATS ── */
.stats-row{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:22px}
.stat-card{background:var(--white);border:1px solid var(--border);border-radius:14px;padding:16px 18px}
.stat-val{font-size:26px;font-weight:800;color:var(--ink)}
.stat-lbl{font-size:12px;color:var(--muted);margin-top:3px}
.stat-card.warn .stat-val{color:var(--gold)}
.stat-card.danger .stat-val{color:var(--red)}
/* ── TOOLBAR ── */
.toolbar{display:flex;align-items:center;gap:10px;margin-bottom:16px;flex-wrap:wrap}
.search-wrap{position:relative;flex:1;min-width:220px}
.search-wrap input{width:100%;height:38px;padding:0 12px 0 38px;border:1.5px solid var(--border);border-radius:10px;font-size:13.5px;font-family:inherit;outline:none;transition:.15s;background:var(--white)}
.search-wrap input:focus{border-color:var(--blue)}
.search-icon{position:absolute;left:11px;top:50%;transform:translateY(-50%);font-size:15px;color:var(--muted)}
.filter-select{height:38px;padding:0 10px;border:1.5px solid var(--border);border-radius:10px;font-size:13px;font-family:inherit;background:var(--white);outline:none;cursor:pointer}
.btn-filter{height:38px;padding:0 16px;border:1.5px solid var(--blue);border-radius:10px;background:var(--white);color:var(--blue);font-size:13px;font-weight:600;cursor:pointer;font-family:inherit}
/* ── TABLE ── */
.table-wrap{background:var(--white);border:1px solid var(--border);border-radius:16px;overflow:hidden}
table{width:100%;border-collapse:collapse}
thead th{padding:11px 14px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:var(--muted);background:#F8FAFE;border-bottom:1px solid var(--border);text-align:left;white-space:nowrap}
tbody td{padding:12px 14px;font-size:13.5px;border-bottom:.5px solid #F0F4FB;vertical-align:middle}
tbody tr:last-child td{border-bottom:none}
tbody tr:hover td{background:#FAFBFF}
.med-name{font-weight:700;color:var(--ink)}
.med-code{font-size:11px;color:var(--muted);font-family:monospace;margin-top:1px}
.badge{display:inline-flex;align-items:center;padding:3px 9px;border-radius:20px;font-size:11px;font-weight:700}
.badge-green{background:#D1FAE5;color:#065F46}
.badge-red{background:#FEE2E2;color:#991B1B}
.badge-gold{background:#FEF3C7;color:#92400E}
.badge-gray{background:#F1F5F9;color:#64748B}
.badge-blue{background:#EFF6FF;color:#1D4ED8}
.stock-val{font-weight:800;font-size:14px}
.stock-ok{color:var(--green)}
.stock-low{color:var(--gold)}
.stock-out{color:var(--red)}
.price-val{font-weight:700;color:var(--blue)}
.action-btns{display:flex;gap:6px;flex-wrap:nowrap}
.btn-sm{height:30px;padding:0 10px;border-radius:8px;font-size:12px;font-weight:600;cursor:pointer;border:1.5px solid;font-family:inherit;white-space:nowrap;text-decoration:none;display:inline-flex;align-items:center;gap:4px;transition:all .12s}
.btn-detail{color:var(--blue);border-color:#BFDBFE;background:#EFF6FF}
.btn-detail:hover{background:#DBEAFE}
.btn-edit{color:#7C3AED;border-color:#DDD6FE;background:#F5F3FF}
.btn-edit:hover{background:#EDE9FE}
.btn-toggle{color:var(--gold);border-color:#FDE68A;background:#FFFBEB}
.btn-toggle:hover{background:#FEF3C7}
.btn-del{color:var(--red);border-color:#FECACA;background:#FFF5F5}
.btn-del:hover{background:#FEE2E2}
.empty-row td{text-align:center;padding:40px;color:var(--muted);font-size:14px}
/* ── TOAST ── */
.toast{position:fixed;top:18px;right:24px;z-index:999;padding:12px 20px;border-radius:12px;font-size:13.5px;font-weight:600;box-shadow:0 4px 24px rgba(0,0,0,.12)}
.toast-ok{background:#ECFDF5;color:#065F46;border:1px solid #A7F3D0}
.toast-warn{background:#FFFBEB;color:#92400E;border:1px solid #FDE68A}
.toast-err{background:#FFF5F5;color:#991B1B;border:1px solid #FECACA}
</style>
</head>
<body>
<%-- Toast --%>
<% if ("created".equals(msg)) { %><div class="toast toast-ok">✅ Đã thêm thuốc mới thành công!</div>
<% } else if ("updated".equals(msg)) { %><div class="toast toast-ok">✅ Đã cập nhật thông tin thuốc!</div>
<% } else if ("deleted".equals(msg)) { %><div class="toast toast-warn">🗑️ Đã ẩn thuốc khỏi danh sách.</div>
<% } else if ("has-stock".equals(msg)) { %><div class="toast toast-err">⚠️ Không thể xóa — thuốc còn tồn kho!</div>
<% } else if ("error".equals(msg)) { %><div class="toast toast-err">❌ Có lỗi xảy ra, thử lại!</div>
<% } %>

<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">
  <div class="topbar">
    <span class="topbar-title">💊 Kho thuốc</span>
    <div class="topbar-right">
      <a href="${pageContext.request.contextPath}/medicines?action=new" class="btn-primary">＋ Thêm thuốc mới</a>
    </div>
  </div>

  <div class="content">
    <div class="page-header">
      <div class="page-title">Quản lý kho thuốc</div>
      <div class="page-sub">Danh sách toàn bộ thuốc, tồn kho và lô hàng</div>
    </div>

    <%-- Stats --%>
    <div class="stats-row">
      <div class="stat-card">
        <div class="stat-val">${totalActive}</div>
        <div class="stat-lbl">💊 Thuốc đang kinh doanh</div>
      </div>
      <div class="stat-card warn">
        <div class="stat-val">${lowStock}</div>
        <div class="stat-lbl">⚠️ Sắp hết hàng</div>
      </div>
      <div class="stat-card">
        <div class="stat-val">${fn:length(medicines)}</div>
        <div class="stat-lbl">📦 Tổng số thuốc</div>
      </div>
      <div class="stat-card">
        <div class="stat-val">${fn:length(categories)}</div>
        <div class="stat-lbl">🗂️ Danh mục</div>
      </div>
    </div>

    <%-- Toolbar --%>
    <form method="get" action="${pageContext.request.contextPath}/medicines">
      <div class="toolbar">
        <div class="search-wrap">
          <span class="search-icon">🔍</span>
          <input type="text" name="q" placeholder="Tìm theo tên, hoạt chất, barcode, mã thuốc..."
                 value="${keyword}" id="searchInput" />
        </div>
        <select class="filter-select" id="catFilter" onchange="applyFilter()">
          <option value="">Tất cả danh mục</option>
          <c:forEach var="cat" items="${categories}">
            <option value="${cat.categoryId}">${cat.categoryName}</option>
          </c:forEach>
        </select>
        <select class="filter-select" id="statusFilter" onchange="applyFilter()">
          <option value="">Tất cả trạng thái</option>
          <option value="active">Đang kinh doanh</option>
          <option value="inactive">Đã ẩn</option>
          <option value="low">Sắp hết hàng</option>
          <option value="out">Hết hàng</option>
        </select>
        <button type="submit" class="btn-filter">🔍 Tìm</button>
      </div>
    </form>

    <%-- Table --%>
    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>#</th>
            <th>Thuốc</th>
            <th>Danh mục</th>
            <th>Đơn vị</th>
            <th>Giá bán</th>
            <th>Tồn kho</th>
            <th>Loại</th>
            <th>Trạng thái</th>
            <th>Thao tác</th>
          </tr>
        </thead>
        <tbody id="medTable">
          <c:choose>
            <c:when test="${empty medicines}">
              <tr class="empty-row"><td colspan="9">💊 Chưa có thuốc nào. <a href="${pageContext.request.contextPath}/medicines?action=new">Thêm thuốc đầu tiên</a></td></tr>
            </c:when>
            <c:otherwise>
              <c:forEach var="m" items="${medicines}" varStatus="st">
                <c:set var="stock" value="${stockMap[m.medicineId]}" />
                <tr data-name="${fn:toLowerCase(m.medicineName)}"
                    data-cat="${m.categoryId}"
                    data-status="${m.status ? 'active' : 'inactive'}"
                    data-stock="${stock}">
                  <td style="color:var(--muted);font-size:12px">#${st.index + 1}</td>
                  <td>
                    <div class="med-name">${m.medicineName}</div>
                    <div class="med-code">${m.medicineCode}
                      <c:if test="${not empty m.genericName}"> · ${m.genericName}</c:if>
                    </div>
                  </td>
                  <td>
                    <c:forEach var="cat" items="${categories}">
                      <c:if test="${cat.categoryId == m.categoryId}">
                        <span class="badge badge-blue">${cat.categoryName}</span>
                      </c:if>
                    </c:forEach>
                  </td>
                  <td>${m.unit}</td>
                  <td class="price-val">
                    <fmt:formatNumber value="${m.sellingPrice}" type="number" maxFractionDigits="0"/>đ
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${stock == 0}">
                        <span class="stock-val stock-out">0</span>
                        <span class="badge badge-red" style="margin-left:4px">Hết hàng</span>
                      </c:when>
                      <c:when test="${stock <= m.minInventory}">
                        <span class="stock-val stock-low">${stock}</span>
                        <span class="badge badge-gold" style="margin-left:4px">Sắp hết</span>
                      </c:when>
                      <c:otherwise>
                        <span class="stock-val stock-ok">${stock}</span>
                      </c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${m.prescriptionRequired}">
                        <span class="badge badge-red">Kê toa</span>
                      </c:when>
                      <c:otherwise>
                        <span class="badge badge-green">OTC</span>
                      </c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${m.status}">
                        <span class="badge badge-green">Đang bán</span>
                      </c:when>
                      <c:otherwise>
                        <span class="badge badge-gray">Đã ẩn</span>
                      </c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <div class="action-btns">
                      <a href="${pageContext.request.contextPath}/medicines?action=detail&id=${m.medicineId}"
                         class="btn-sm btn-detail">📦 Lô hàng</a>
                      <a href="${pageContext.request.contextPath}/medicines?action=edit&id=${m.medicineId}"
                         class="btn-sm btn-edit">✏️</a>
                      <form method="post" action="${pageContext.request.contextPath}/medicines" style="display:inline">
                        <input type="hidden" name="action" value="toggle-medicine"/>
                        <input type="hidden" name="id" value="${m.medicineId}"/>
                        <button type="submit" class="btn-sm btn-toggle"
                                title="${m.status ? 'Ẩn thuốc' : 'Kích hoạt lại'}">
                          ${m.status ? '🙈 Ẩn' : '👁 Hiện'}
                        </button>
                      </form>
                      <c:if test="${stock == 0}">
                        <form method="post" action="${pageContext.request.contextPath}/medicines" style="display:inline"
                              onsubmit="return confirm('Xóa thuốc ${m.medicineName}? Không thể hoàn tác!')">
                          <input type="hidden" name="action" value="delete-medicine"/>
                          <input type="hidden" name="id" value="${m.medicineId}"/>
                          <button type="submit" class="btn-sm btn-del">🗑️</button>
                        </form>
                      </c:if>
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

<script>
const t = document.querySelector('.toast');
if (t) setTimeout(() => { t.style.opacity='0'; t.style.transition='opacity .4s'; setTimeout(()=>t.remove(),400); }, 3000);

function applyFilter() {
  const cat    = document.getElementById('catFilter').value;
  const status = document.getElementById('statusFilter').value;
  let visible  = 0;
  document.querySelectorAll('#medTable tr[data-name]').forEach(row => {
    const matchCat = !cat    || row.dataset.cat    === cat;
    const stock    = parseInt(row.dataset.stock)   || 0;
    const isActive = row.dataset.status === 'active';
    const minInv   = parseInt(row.dataset.minInventory) || 10;
    let matchStatus = true;
    if      (status === 'active')   matchStatus = isActive;
    else if (status === 'inactive') matchStatus = !isActive;
    else if (status === 'low')      matchStatus = stock > 0 && stock <= minInv;
    else if (status === 'out')      matchStatus = stock === 0;
    const show = matchCat && matchStatus;
    row.style.display = show ? '' : 'none';
    if (show) visible++;
  });
}
</script>
</body>
</html>
