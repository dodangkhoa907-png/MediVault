<%@ page contentType="text/html;charset=UTF-8" %>
<% String activeNav = "audit"; %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    int roleId = acc.getRoleId();
    java.lang.String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    java.lang.String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();

    Integer expiryCount     = (Integer) request.getAttribute("expiryCount");
    Integer pendingResetCount = (Integer) request.getAttribute("pendingResetCount");
    if (expiryCount      == null) expiryCount      = 0;
    if (pendingResetCount == null) pendingResetCount = 0;

    @SuppressWarnings("unchecked")
    java.util.List<com.medicare.entity.PasswordResetRequest> pendingResets =
        (java.util.List<com.medicare.entity.PasswordResetRequest>) request.getAttribute("pendingResets");
    @SuppressWarnings("unchecked")
    java.util.Map<Integer, com.medicare.entity.Account> resetAccountMap =
        (java.util.Map<Integer, com.medicare.entity.Account>) request.getAttribute("resetAccountMap");
    if (pendingResets   == null) pendingResets   = new java.util.ArrayList<>();
    if (resetAccountMap == null) resetAccountMap = new java.util.HashMap<>();

    @SuppressWarnings("unchecked")
    java.util.List<com.medicare.entity.AuditLog> auditLogs =
        (java.util.List<com.medicare.entity.AuditLog>) request.getAttribute("auditLogs");
    if (auditLogs == null) auditLogs = new java.util.ArrayList<>();

    Integer currentPage = (Integer) request.getAttribute("currentPage");
    Integer totalPages  = (Integer) request.getAttribute("totalPages");
    java.lang.String searchKeyword = (java.lang.String) request.getAttribute("searchKeyword");
    if (currentPage  == null) currentPage  = 1;
    if (totalPages   == null) totalPages   = 1;
    if (searchKeyword == null) searchKeyword = "";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>medicare — Nhật ký hệ thống</title>
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

/* SIDEBAR */
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-icon{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;box-shadow:0 4px 16px rgba(58,189,224,.35)}
.logo-text{font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-text span{color:var(--cyan)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:12px 0 4px;flex-shrink:0}
.nav-label{font-size:9px;font-weight:700;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:500;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.14);font-weight:600}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--cyan);border-radius:2px}
.nav-icon{width:18px;text-align:center;font-size:14px;flex-shrink:0;opacity:.8}
.nav-item.active .nav-icon{opacity:1}
.nav-badge{margin-left:auto;background:#DC2626;color:#fff;font-size:10px;font-weight:700;padding:1px 7px;border-radius:20px;min-width:20px;text-align:center}
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06);flex-shrink:0}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08)}
.user-avatar-sm{width:34px;height:34px;flex-shrink:0;border-radius:9px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.user-info-sm .name{font-size:12.5px;font-weight:600;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:110px}
.user-info-sm .role{font-size:10px;color:rgba(255,255,255,.35);margin-top:1px}
.logout-btn{margin-left:auto;width:28px;height:28px;flex-shrink:0;border-radius:8px;background:rgba(220,38,38,.12);border:none;display:flex;align-items:center;justify-content:center;color:rgba(220,38,38,.7);font-size:13px;cursor:pointer;text-decoration:none;transition:all .18s}
.logout-btn:hover{background:rgba(220,38,38,.2);color:#DC2626}

/* MAIN */
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0}

/* TOPBAR */
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding: 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Outfit',sans-serif;font-size:16px;color:var(--ink)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px;flex-shrink:0}
.topbar-clock{display:flex;align-items:center;gap:5px;padding:6px 13px;background:var(--surface);border:1.5px solid var(--border);border-radius:20px;font-size:13px;font-weight:700;color:var(--navy);font-variant-numeric:tabular-nums}
.clock-sep{animation:blink 1s step-end infinite}
@keyframes blink{0%,100%{opacity:1}50%{opacity:0}}
.clock-date{font-size:11px;font-weight:500;color:var(--muted);border-left:1px solid var(--border);padding-left:8px;margin-left:2px}
.notif-wrap{position:relative}
.topbar-icon-btn{width:34px;height:34px;border-radius:9px;background:var(--surface);border:1.5px solid var(--border);cursor:pointer;font-size:15px;display:flex;align-items:center;justify-content:center;position:relative;transition:all .18s}
.topbar-icon-btn:hover{border-color:var(--cyan);background:var(--cyan-soft)}
.topbar-notif-badge{position:absolute;top:-4px;right:-4px;background:#DC2626;color:#fff;font-size:9px;font-weight:800;padding:1px 4px;border-radius:10px;min-width:16px;text-align:center}
.notif-dropdown{position:absolute;top:calc(100% + 8px);right:0;width:300px;background:#fff;border:1px solid var(--border);border-radius:16px;box-shadow:0 12px 40px rgba(0,0,0,.12);opacity:0;visibility:hidden;transform:translateY(-8px);transition:all .2s;z-index:200;overflow:hidden}
.notif-dropdown.open{opacity:1;visibility:visible;transform:translateY(0)}
.notif-head{display:flex;align-items:center;justify-content:space-between;padding:14px 16px;border-bottom:1px solid var(--border)}
.notif-head-title{font-size:13px;font-weight:700;color:var(--ink)}
.notif-clear{background:none;border:none;cursor:pointer;font-size:12px;color:var(--muted);padding:0}
.notif-item{display:flex;align-items:flex-start;gap:10px;padding:12px 16px;border-bottom:1px solid #F8FAFC;transition:background .15s}
.notif-item:hover{background:var(--surface)}
.notif-dot{width:8px;height:8px;border-radius:50%;background:#DC2626;margin-top:4px;flex-shrink:0}
.notif-dot.old{background:var(--muted);opacity:.4}
.notif-text{font-size:12.5px;color:var(--ink);font-weight:500}
.notif-time{font-size:11px;color:var(--muted);margin-top:2px}
.topbar-user{display:flex;align-items:center;gap:8px;padding:5px 12px 5px 7px;border:1.5px solid var(--border);border-radius:20px;text-decoration:none;color:inherit;transition:all .18s}
.topbar-user:hover{border-color:var(--cyan);background:var(--cyan-soft)}
.topbar-user-avatar{width:28px;height:28px;border-radius:8px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;color:#fff}
.topbar-user-name{font-size:13px;font-weight:600;color:var(--navy);max-width:110px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}

/* CONTENT */
.content{padding:26px 28px;flex:1;min-width:0}
.page-head{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:22px}
.page-head-left .breadcrumb{font-size:11.5px;color:var(--muted);font-weight:500;margin-bottom:4px}
.page-head-left h1{font-family:'Outfit',sans-serif;font-size:28px;color:var(--ink)}

/* Table card */
.table-card{background:var(--white);border:1px solid var(--border);border-radius:18px;overflow:hidden}
.table-card-header{padding:20px 24px 14px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
.table-card-title{font-family:'Outfit',sans-serif;font-size:18px;color:var(--ink)}
.table-card-subtitle{font-size:12.5px;color:var(--muted);margin-top:2px}

/* Filter */
.filter-row{display:flex;gap:10px;align-items:center;padding:14px 24px;border-bottom:1px solid var(--border);flex-wrap:wrap}
.filter-search{position:relative;flex:1;min-width:220px}
.filter-search input{width:100%;padding:8px 14px 8px 36px;background:var(--surface);border:1.5px solid var(--border);border-radius:10px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);outline:none;transition:all .18s}
.filter-search input:focus{border-color:var(--cyan);background:#fff}
.filter-search::before{content:'🔍';position:absolute;left:12px;top:50%;transform:translateY(-50%);font-size:12px;pointer-events:none;opacity:.45}
.filter-chip{padding:8px 14px;background:var(--surface);border:1.5px solid var(--border);border-radius:10px;font-size:12.5px;font-weight:600;color:var(--navy);cursor:pointer;text-decoration:none;transition:all .18s;white-space:nowrap}
.filter-chip:hover{border-color:var(--cyan);color:var(--blue)}
.btn-primary{display:inline-flex;align-items:center;gap:7px;padding:9px 18px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;border-radius:10px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;cursor:pointer;text-decoration:none;transition:all .2s}
.btn-primary:hover{transform:translateY(-1px)}

/* Table */
.table-wrap{overflow-x:auto}
.data-table{width:100%;border-collapse:collapse;font-size:13px}
.data-table th{padding:10px 16px;background:var(--surface);border-bottom:1px solid var(--border);font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;white-space:nowrap}
.data-table td{padding:13px 16px;border-bottom:1px solid #F4F7FC;vertical-align:middle}
.data-table tbody tr:hover{background:#FAFCFF}
.data-table tbody tr:last-child td{border-bottom:none}

/* Badge */
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:600}
.badge-green{background:rgba(5,150,105,.1);color:var(--green)}
.badge-red{background:rgba(220,38,38,.1);color:var(--red)}
.badge-blue{background:rgba(21,88,168,.1);color:var(--blue)}
.badge-gold{background:rgba(217,119,6,.1);color:var(--gold)}
.badge-gray{background:rgba(122,144,176,.1);color:var(--muted)}

/* Empty */
.empty-state{padding:48px 24px;text-align:center;color:var(--muted)}
.empty-state .icon{font-size:36px;margin-bottom:10px}
.empty-state p{font-size:13.5px}

/* Pagination */
.pagination{display:flex;align-items:center;justify-content:space-between;padding:14px 24px;border-top:1px solid var(--border)}
.pagination-info{font-size:12.5px;color:var(--muted)}
.pagination-btns{display:flex;gap:5px}
.page-btn{width:32px;height:32px;border-radius:8px;display:inline-flex;align-items:center;justify-content:center;font-size:13px;font-weight:600;text-decoration:none;color:var(--navy);background:var(--surface);border:1.5px solid var(--border);transition:all .15s}
.page-btn:hover{border-color:var(--cyan);color:var(--blue)}
.page-btn.active{background:var(--blue);border-color:var(--blue);color:#fff}
.page-btn.disabled{opacity:.4;pointer-events:none}

/* Log-specific */
.log-action{font-size:13px;font-weight:600;color:var(--ink)}
.log-desc{font-size:12px;color:var(--muted);margin-top:2px;max-width:320px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.log-time{font-size:12px;color:var(--muted);white-space:nowrap}
.log-ip{font-size:11.5px;color:var(--muted);font-family:monospace}
.log-id{font-size:11px;color:var(--muted);opacity:.6}
</style>
</head>
<body>

<!-- SIDEBAR -->
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<!-- MAIN -->
<div class="main">
    <!-- TOPBAR -->
    <header class="topbar">
        <span class="topbar-title">📋 Nhật ký hệ thống</span>
        <div class="topbar-right">
            <div class="topbar-clock">
                <span id="clockH">00</span><span class="clock-sep">:</span><span id="clockM">00</span>
                <span class="clock-date" id="clockDate"></span>
            </div>
            <div class="notif-wrap">
                <button class="topbar-icon-btn" onclick="toggleNotif()" title="Thông báo">
                    🔔
                    <% int totalNotif = expiryCount + pendingResetCount; %>
                    <% if (totalNotif > 0) { %>
                    <span class="topbar-notif-badge"><%= totalNotif > 9 ? "9+" : totalNotif %></span>
                    <% } %>
                </button>
                <div class="notif-dropdown" id="notifDropdown">
                    <div class="notif-head">
                        <span class="notif-head-title">🔔 Thông báo</span>
                        <button class="notif-clear" onclick="closeNotif()">Đóng ✕</button>
                    </div>
                    <div class="notif-list">
                        <% for (com.medicare.entity.PasswordResetRequest pr : pendingResets) {
                               com.medicare.entity.Account staffPr = resetAccountMap.get(pr.getAccountId());
                               java.lang.String staffPrName = staffPr != null ? staffPr.getFullName() : ("ID " + pr.getAccountId());
                               java.lang.String staffPrUser = staffPr != null ? staffPr.getUsername() : "";
                        %>
                        <a href="<%= request.getContextPath() %>/accounts?action=edit&id=<%= pr.getAccountId() %>"
                           class="notif-item" style="text-decoration:none;display:flex;background:rgba(245,158,11,.06);border-left:3px solid #F59E0B">
                            <div class="notif-dot" style="background:#D97706"></div>
                            <div style="flex:1">
                                <div class="notif-text">🔐 <strong><%= staffPrName %></strong> yêu cầu đổi mật khẩu</div>
                                <div class="notif-time">@<%= staffPrUser %> · Bấm để đặt mật khẩu mới</div>
                            </div>
                        </a>
                        <% } %>
                        <% if (expiryCount > 0) { %>
                        <div class="notif-item"><div class="notif-dot"></div><div><div class="notif-text">⚠️ Có <%= expiryCount %> mặt hàng sắp hết hạn</div><div class="notif-time">Hôm nay</div></div></div>
                        <% } else { %>
                        <div class="notif-item"><div class="notif-dot old"></div><div><div class="notif-text">✅ Không có thuốc nào sắp hết hạn</div><div class="notif-time">Hôm nay</div></div></div>
                        <% } %>
                    </div>
                </div>
            </div>
            <a href="<%= request.getContextPath() %>/accounts?action=view&id=<%= acc.getAccountId() %>" class="topbar-user">
                <div class="topbar-user-avatar"><%= initials %></div>
                <span class="topbar-user-name"><%= fullName %></span>
            </a>
        </div>
    </header>

    <!-- CONTENT -->
    <div class="content">
        <div class="page-head">
            <div class="page-head-left">
                <div class="breadcrumb">medicare › Phân tích › Nhật ký</div>
                <h1>Nhật ký hệ thống</h1>
            </div>
        </div>

        <div class="table-card">
            <div class="table-card-header">
                <div>
                    <div class="table-card-title">📋 Lịch sử hoạt động</div>
                    <div class="table-card-subtitle">Ghi lại toàn bộ thao tác của admin và nhân viên</div>
                </div>
            </div>

            <!-- Filter / Search -->
            <form method="get" action="${pageContext.request.contextPath}/audit-logs" class="filter-row" id="filterForm">
                <div class="filter-search">
                    <input type="text" name="search" id="searchInput"
                           placeholder="Tìm theo hành động, module, mô tả, username…"
                           value="<%= searchKeyword %>">
                </div>
                <button type="submit" class="btn-primary">🔍 Lọc</button>
                <% if (!searchKeyword.isEmpty()) { %>
                <a href="${pageContext.request.contextPath}/audit-logs" class="filter-chip">✕ Xóa lọc</a>
                <% } %>
            </form>

            <!-- Table -->
            <div class="table-wrap">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Người thực hiện</th>
                            <th>Hành động</th>
                            <th>Module</th>
                            <th>Mô tả</th>
                            <th>IP</th>
                            <th>Thời gian</th>
                        </tr>
                    </thead>
                    <tbody>
                    <% if (auditLogs.isEmpty()) { %>
                        <tr>
                            <td colspan="7">
                                <div class="empty-state">
                                    <div class="icon">📋</div>
                                    <p>Chưa có nhật ký nào<% if (!searchKeyword.isEmpty()) { %> khớp với "<%= searchKeyword %>"<% } %>.</p>
                                </div>
                            </td>
                        </tr>
                    <% } else {
                           java.time.format.DateTimeFormatter dtf = java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss");
                           for (com.medicare.entity.AuditLog log : auditLogs) {
                               java.lang.String actionBadge = "badge-gray";
                               java.lang.String act = log.getAction() != null ? log.getAction() : "";
                               if (act.contains("Tạo") || act.contains("Khôi phục"))         actionBadge = "badge-green";
                               else if (act.contains("Xóa") || act.contains("Khóa"))          actionBadge = "badge-red";
                               else if (act.contains("Đăng nhập") || act.contains("Đăng xuất")) actionBadge = "badge-blue";
                               else if (act.contains("Cập nhật") || act.contains("Sửa") || act.contains("Đặt lại")) actionBadge = "badge-gold";
                    %>
                        <tr>
                            <td class="log-id">#<%= log.getLogId() %></td>
                            <td>
                                <% java.lang.String uname = log.getUsername() != null ? log.getUsername() : "Hệ thống"; %>
                                <span style="font-weight:600;color:var(--ink)">@<%= uname %></span>
                            </td>
                            <td><span class="badge <%= actionBadge %>"><%= act %></span></td>
                            <td><span style="font-size:12.5px;color:var(--navy);font-weight:500"><%= log.getEntityType() != null ? log.getEntityType() : "—" %></span></td>
                            <td>
                                <div class="log-desc" title="<%= log.getDescription() != null ? log.getDescription() : "" %>">
                                    <%= log.getDescription() != null ? log.getDescription() : "—" %>
                                </div>
                            </td>
                            <td class="log-ip"><%= log.getIpAddress() != null ? log.getIpAddress() : "—" %></td>
                            <td class="log-time">
                                <%= log.getCreatedAt() != null ? log.getCreatedAt().format(dtf) : "—" %>
                            </td>
                        </tr>
                    <% }} %>
                    </tbody>
                </table>
            </div>

            <!-- Pagination -->
            <div class="pagination">
                <div class="pagination-info">
                    Trang <%= currentPage %> / <%= totalPages %>
                </div>
                <div class="pagination-btns">
                    <a href="${pageContext.request.contextPath}/audit-logs?page=<%= currentPage - 1 %>&search=<%= searchKeyword %>"
                       class="page-btn <%= currentPage <= 1 ? "disabled" : "" %>">‹</a>
                    <%
                       int start = Math.max(1, currentPage - 2);
                       int end   = Math.min(totalPages, currentPage + 2);
                       for (int p = start; p <= end; p++) {
                    %>
                    <a href="${pageContext.request.contextPath}/audit-logs?page=<%= p %>&search=<%= searchKeyword %>"
                       class="page-btn <%= p == currentPage ? "active" : "" %>"><%= p %></a>
                    <% } %>
                    <a href="${pageContext.request.contextPath}/audit-logs?page=<%= currentPage + 1 %>&search=<%= searchKeyword %>"
                       class="page-btn <%= currentPage >= totalPages ? "disabled" : "" %>">›</a>
                </div>
            </div>
        </div>
    </div>
</div>

<script>
// Clock
function updateClock() {
    const now = new Date();
    document.getElementById('clockH').textContent = String(now.getHours()).padStart(2,'0');
    document.getElementById('clockM').textContent = String(now.getMinutes()).padStart(2,'0');
    const days = ['CN','T2','T3','T4','T5','T6','T7'];
    document.getElementById('clockDate').textContent =
        days[now.getDay()] + ', ' + String(now.getDate()).padStart(2,'0') + '/' + String(now.getMonth()+1).padStart(2,'0');
}
updateClock(); setInterval(updateClock, 1000);

// Notif dropdown
function toggleNotif() { document.getElementById('notifDropdown').classList.toggle('open'); }
function closeNotif()  { document.getElementById('notifDropdown').classList.remove('open'); }
document.addEventListener('click', e => {
    const wrap = document.querySelector('.notif-wrap');
    if (wrap && !wrap.contains(e.target)) closeNotif();
});

// Search on Enter
document.getElementById('searchInput').addEventListener('keydown', e => {
    if (e.key === 'Enter') document.getElementById('filterForm').submit();
});
</script>
</body>
</html>
