<%@ page contentType="text/html;charset=UTF-8" %>
<% String activeNav = "dashboard"; %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    com.medivault.entity.Account acc = (com.medivault.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    int roleId = acc.getRoleId();
    java.lang.String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    java.lang.String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();

    // Stats từ DashboardServlet (fallback về 0 nếu chưa có)
    Long todayRevenue  = (Long)   request.getAttribute("todayRevenue");
    Integer todayInvoice = (Integer) request.getAttribute("todayInvoices");
    Integer expiryCount  = (Integer) request.getAttribute("expiryCount");
    Long activeAccountsLong = (Long) request.getAttribute("activeAccounts");
    int activeAccounts = activeAccountsLong != null ? activeAccountsLong.intValue() : 0;
    if (todayRevenue   == null) todayRevenue   = 0L;
    if (todayInvoice   == null) todayInvoice   = 0;
    if (expiryCount    == null) expiryCount    = 0;

    // Trang hiện tại
    java.lang.String currentPage = request.getParameter("view");
    if (currentPage == null) currentPage = "dashboard";

    // Pending reset requests — từ DashboardServlet
    @SuppressWarnings("unchecked")
    java.util.List<com.medivault.entity.PasswordResetRequest> pendingResets =
        (java.util.List<com.medivault.entity.PasswordResetRequest>) request.getAttribute("pendingResets");
    @SuppressWarnings("unchecked")
    java.util.Map<Integer, com.medivault.entity.Account> resetAccountMap =
        (java.util.Map<Integer, com.medivault.entity.Account>) request.getAttribute("resetAccountMap");
    Integer pendingResetCount = (Integer) request.getAttribute("pendingResetCount");
    if (pendingResets     == null) pendingResets     = new java.util.ArrayList<>();
    if (resetAccountMap   == null) resetAccountMap   = new java.util.HashMap<>();
    if (pendingResetCount == null) pendingResetCount = 0;

    @SuppressWarnings("unchecked")
    java.util.Map<Integer, com.medivault.entity.Account> blockedMap =
        (java.util.Map<Integer, com.medivault.entity.Account>) request.getAttribute("blockedAccountMap");
    if (blockedMap == null) blockedMap = new java.util.HashMap<>();
%>

<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MediVault — Dashboard</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;--cyan-soft:#EBF8FD;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;--sidebar:232px;
  --purple:#6D28D9;
}
html,body{height:100%;font-family:'Outfit',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}

/* ── SIDEBAR ── */
.sidebar{
  width:var(--sidebar);min-height:100vh;
  background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);
  display:flex;flex-direction:column;
  position:fixed;left:0;top:0;bottom:0;z-index:100;
  box-shadow:4px 0 32px rgba(0,0,0,.18);
}
.sidebar::after{
  content:'';position:absolute;top:0;right:0;bottom:0;width:1px;
  background:linear-gradient(180deg,transparent,rgba(58,189,224,.12) 30%,rgba(58,189,224,.12) 70%,transparent);
}
.sidebar-logo{
  height:66px;padding:0 20px;
  display:flex;align-items:center;gap:11px;
  border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0;
}
.logo-icon{
  width:36px;height:36px;border-radius:10px;
  background:linear-gradient(135deg,var(--cyan),var(--blue));
  display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;
  box-shadow:0 4px 16px rgba(58,189,224,.35);
}
.logo-text{font-family:'Outfit',sans-serif;font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-text span{color:var(--cyan)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}

.nav-section{padding:12px 0 4px;flex-shrink:0}
.nav-label{font-size:9px;font-weight:700;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{
  display:flex;align-items:center;gap:10px;
  padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;
  font-size:13px;font-weight:500;color:rgba(255,255,255,.5);
  text-decoration:none;transition:all .18s;position:relative;
}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.14);font-weight:600}
.nav-item.active::before{
  content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);
  width:3px;height:56%;background:var(--cyan);border-radius:2px;
}
.nav-icon{width:18px;text-align:center;font-size:14px;flex-shrink:0;opacity:.8}
.nav-item.active .nav-icon{opacity:1}
.nav-badge{
  margin-left:auto;background:#DC2626;color:#fff;
  font-size:10px;font-weight:700;padding:1px 7px;border-radius:20px;min-width:20px;text-align:center;
}
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06);flex-shrink:0}
.sidebar-user{
  display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;
  background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08);
}
.user-avatar-sm{
  width:34px;height:34px;flex-shrink:0;border-radius:9px;
  background:linear-gradient(135deg,var(--cyan),var(--blue));
  display:flex;align-items:center;justify-content:center;
  font-size:12px;font-weight:800;color:#fff;
}
.user-info-sm .name{font-size:12.5px;font-weight:600;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:110px}
.user-info-sm .role{font-size:10px;color:rgba(255,255,255,.35);margin-top:1px}
.logout-btn{
  margin-left:auto;width:28px;height:28px;flex-shrink:0;border-radius:8px;
  background:rgba(220,38,38,.12);border:none;
  display:flex;align-items:center;justify-content:center;
  color:rgba(220,38,38,.7);font-size:13px;cursor:pointer;text-decoration:none;transition:all .18s;
}
.logout-btn:hover{background:rgba(220,38,38,.2);color:#DC2626}

/* ── MAIN ── */
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0;overflow-x:hidden}

/* ── TOPBAR ── */
.topbar{
  height:62px;background:var(--white);border-bottom:1px solid var(--border);
  display:flex;align-items:center;padding:0 28px;gap:14px;
  position:sticky;top:0;z-index:50;
}
.topbar-title{font-family:'Outfit',sans-serif;font-size:16px;color:var(--ink)}
.topbar-search{flex:1;max-width:340px;position:relative}
.topbar-search input{
  width:100%;padding:8px 14px 8px 36px;
  background:var(--surface);border:1.5px solid var(--border);border-radius:20px;
  font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);outline:none;transition:all .2s;
}
.topbar-search input:focus{border-color:var(--cyan);background:#fff;box-shadow:0 0 0 3px rgba(58,189,224,.1)}
.topbar-search::before{content:'🔍';position:absolute;left:12px;top:50%;transform:translateY(-50%);font-size:13px;pointer-events:none;opacity:.5}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px;flex-shrink:0}
.topbar-clock{
  display:flex;align-items:center;gap:5px;padding:6px 13px;
  background:var(--surface);border:1.5px solid var(--border);border-radius:20px;
  font-size:13px;font-weight:700;color:var(--navy);font-variant-numeric:tabular-nums;
}
.clock-sep{animation:blink 1s step-end infinite}
@keyframes blink{0%,100%{opacity:1}50%{opacity:0}}
.clock-date{font-size:11px;font-weight:500;color:var(--muted);border-left:1px solid var(--border);padding-left:8px;margin-left:2px;font-variant-numeric:initial}
.notif-wrap{position:relative}
.topbar-icon-btn{
  width:34px;height:34px;border-radius:9px;background:var(--surface);
  border:1.5px solid var(--border);cursor:pointer;font-size:15px;
  display:flex;align-items:center;justify-content:center;position:relative;transition:all .18s;
}
.topbar-icon-btn:hover{border-color:var(--cyan);background:var(--cyan-soft)}
.topbar-notif-badge{
  position:absolute;top:-4px;right:-4px;
  background:#DC2626;color:#fff;font-size:9px;font-weight:800;
  padding:1px 4px;border-radius:10px;min-width:16px;text-align:center;
}
.notif-dropdown{
  position:absolute;top:calc(100% + 8px);right:0;
  width:300px;background:#fff;border:1px solid var(--border);border-radius:16px;
  box-shadow:0 12px 40px rgba(0,0,0,.12);opacity:0;visibility:hidden;
  transform:translateY(-8px);transition:all .2s;z-index:200;overflow:hidden;
}
.notif-dropdown.open{opacity:1;visibility:visible;transform:translateY(0)}
.notif-head{display:flex;align-items:center;justify-content:space-between;padding:14px 16px;border-bottom:1px solid var(--border)}
.notif-head-title{font-size:13px;font-weight:700;color:var(--ink)}
.notif-clear{background:none;border:none;cursor:pointer;font-size:12px;color:var(--muted);padding:0}
.notif-clear:hover{color:var(--red)}
.notif-item{display:flex;align-items:flex-start;gap:10px;padding:12px 16px;border-bottom:1px solid #F8FAFC;transition:background .15s}
.notif-item:hover{background:var(--surface)}
.notif-item:last-child{border-bottom:none}
.notif-dot{width:8px;height:8px;border-radius:50%;background:#DC2626;margin-top:4px;flex-shrink:0}
.notif-dot.old{background:var(--muted);opacity:.4}
@keyframes pulseDot{0%,100%{opacity:1;transform:scale(1)}50%{opacity:.4;transform:scale(1.4)}}
.notif-text{font-size:12.5px;color:var(--ink);font-weight:500}
.notif-time{font-size:11px;color:var(--muted);margin-top:2px}
.topbar-user{
  display:flex;align-items:center;gap:8px;padding:5px 12px 5px 7px;
  border:1.5px solid var(--border);border-radius:20px;text-decoration:none;color:inherit;
  transition:all .18s;
}
.topbar-user:hover{border-color:var(--cyan);background:var(--cyan-soft)}
.topbar-user-avatar{
  width:28px;height:28px;border-radius:8px;
  background:linear-gradient(135deg,var(--cyan),var(--blue));
  display:flex;align-items:center;justify-content:center;
  font-size:11px;font-weight:800;color:#fff;
}
.topbar-user-name{font-size:13px;font-weight:600;color:var(--navy);max-width:110px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}

/* ── CONTENT ── */
.content{padding:26px 28px;flex:1;min-width:0;overflow-x:auto}
.page-head{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:22px}
.page-head-left .breadcrumb{font-size:11.5px;color:var(--muted);font-weight:500;margin-bottom:4px}
.page-head-left h1{font-family:'Outfit',sans-serif;font-size:28px;color:var(--ink)}
.btn-primary{
  display:inline-flex;align-items:center;gap:7px;padding:10px 20px;
  background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;
  border:none;border-radius:11px;font-family:'Outfit',sans-serif;
  font-size:13.5px;font-weight:600;cursor:pointer;text-decoration:none;
  transition:all .22s;box-shadow:0 4px 14px rgba(21,88,168,.25);
}
.btn-primary:hover{transform:translateY(-1px);box-shadow:0 6px 20px rgba(21,88,168,.35)}

/* Alert */
.alert-card{
  background:#FFFBEB;border:1px solid #FDE68A;border-radius:14px;
  padding:14px 20px;display:flex;align-items:center;gap:14px;margin-bottom:20px;
}
.alert-icon{font-size:20px}
.alert-text strong{color:#92400E;font-size:13.5px;display:block}
.alert-text p{font-size:12.5px;color:#78350F;margin-top:2px}
.alert-link{
  margin-left:auto;padding:7px 16px;background:#D97706;color:#fff;
  border-radius:8px;font-size:12.5px;font-weight:600;text-decoration:none;white-space:nowrap;transition:background .18s;
}
.alert-link:hover{background:#B45309}

/* Stats */
.stats-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:22px}
.stat-card{
  background:var(--white);border:1px solid var(--border);border-radius:16px;
  padding:20px;position:relative;overflow:hidden;
  transition:box-shadow .2s,transform .18s;
}
.stat-card:hover{box-shadow:0 6px 24px rgba(21,88,168,.08);transform:translateY(-2px)}
.stat-card::before{content:'';position:absolute;top:0;left:0;bottom:0;width:3px;border-radius:2px}
.stat-card:nth-child(1)::before{background:linear-gradient(180deg,#F59E0B,#D97706)}
.stat-card:nth-child(2)::before{background:linear-gradient(180deg,var(--green),#047857)}
.stat-card:nth-child(3)::before{background:linear-gradient(180deg,var(--red),#B91C1C)}
.stat-card:nth-child(4)::before{background:linear-gradient(180deg,var(--cyan),var(--blue))}
.stat-card-top{display:flex;align-items:center;justify-content:space-between;margin-bottom:12px}
.stat-label{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.6px}
.stat-icon{width:36px;height:36px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:16px}
.stat-icon.gold{background:rgba(245,158,11,.12)}
.stat-icon.green{background:rgba(5,150,105,.1)}
.stat-icon.red{background:rgba(220,38,38,.1)}
.stat-icon.blue{background:rgba(58,189,224,.12)}
.stat-value{font-family:'Outfit',sans-serif;font-size:32px;color:var(--ink);line-height:1;margin-bottom:8px}
.stat-diff{font-size:12px;color:var(--muted)}
.stat-diff .up{color:var(--green);font-weight:600}
.stat-diff .down{color:var(--red);font-weight:600}

/* Table card */
.table-card{background:var(--white);border:1px solid var(--border);border-radius:18px;overflow:hidden}
.table-card-header{padding:20px 24px 14px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
.table-card-title{font-family:'Outfit',sans-serif;font-size:18px;color:var(--ink)}
.table-card-subtitle{font-size:12.5px;color:var(--muted);margin-top:2px}

/* Filter */
.filter-row{display:flex;gap:10px;align-items:center;padding:14px 24px;border-bottom:1px solid var(--border);flex-wrap:wrap}
.filter-search{position:relative;flex:1;min-width:200px}
.filter-search input{
  width:100%;padding:8px 14px 8px 36px;
  background:var(--surface);border:1.5px solid var(--border);border-radius:10px;
  font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);outline:none;transition:all .18s;
}
.filter-search input:focus{border-color:var(--cyan);background:#fff}
.filter-search::before{content:'🔍';position:absolute;left:12px;top:50%;transform:translateY(-50%);font-size:12px;pointer-events:none;opacity:.45}
.filter-select{
  padding:8px 12px;background:var(--surface);border:1.5px solid var(--border);border-radius:10px;
  font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);outline:none;cursor:pointer;transition:all .18s;
}
.filter-select:focus{border-color:var(--cyan)}
.filter-chip{
  padding:8px 14px;background:var(--surface);border:1.5px solid var(--border);border-radius:10px;
  font-size:12.5px;font-weight:600;color:var(--navy);cursor:pointer;text-decoration:none;
  transition:all .18s;white-space:nowrap;
}
.filter-chip:hover{border-color:var(--cyan);color:var(--blue)}

/* Table */
.table-wrap{overflow-x:auto}
.data-table{width:100%;border-collapse:collapse;font-size:13px}
.data-table th{
  padding:10px 16px;background:var(--surface);border-bottom:1px solid var(--border);
  font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);
  text-align:left;white-space:nowrap;
}
.data-table td{padding:13px 16px;border-bottom:1px solid #F4F7FC;vertical-align:middle}
.data-table tbody tr:hover{background:#FAFCFF}
.data-table tbody tr:last-child td{border-bottom:none}
.cell-user{display:flex;align-items:center;gap:10px}
.cell-avatar{
  width:34px;height:34px;border-radius:9px;flex-shrink:0;
  background:linear-gradient(135deg,var(--cyan),var(--blue));
  display:flex;align-items:center;justify-content:center;
  font-size:12px;font-weight:800;color:#fff;
}
.cell-user-name{font-size:13.5px;font-weight:600;color:var(--ink)}
.cell-user-sub{font-size:11.5px;color:var(--muted);margin-top:1px}

/* Badges */
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:600}
.badge-green{background:rgba(5,150,105,.1);color:var(--green)}
.badge-red{background:rgba(220,38,38,.1);color:var(--red)}
.badge-blue{background:rgba(21,88,168,.1);color:var(--blue)}
.badge-gold{background:rgba(217,119,6,.1);color:var(--gold)}

/* Actions */
.action-group{display:flex;gap:6px}
.action-btn{
  padding:5px 11px;border-radius:7px;font-size:12px;font-weight:600;
  text-decoration:none;cursor:pointer;border:none;font-family:'Outfit',sans-serif;transition:all .15s;
}
.action-btn-edit{background:rgba(21,88,168,.08);color:var(--blue)}
.action-btn-edit:hover{background:rgba(21,88,168,.16)}
.action-btn-toggle-off{background:rgba(220,38,38,.08);color:var(--red)}
.action-btn-toggle-off:hover{background:rgba(220,38,38,.16)}
.action-btn-toggle-on{background:rgba(5,150,105,.08);color:var(--green)}
.action-btn-toggle-on:hover{background:rgba(5,150,105,.16)}

/* Empty state */
.empty-state{padding:48px 24px;text-align:center;color:var(--muted)}
.empty-state .icon{font-size:36px;margin-bottom:10px}
.empty-state p{font-size:13.5px}

/* Pagination */
.pagination{
  display:flex;align-items:center;justify-content:space-between;
  padding:14px 24px;border-top:1px solid var(--border);
}
.pagination-info{font-size:12.5px;color:var(--muted)}
.pagination-btns{display:flex;gap:5px}
.page-btn{
  width:32px;height:32px;border-radius:8px;display:inline-flex;align-items:center;justify-content:center;
  font-size:13px;font-weight:600;text-decoration:none;color:var(--navy);
  background:var(--surface);border:1.5px solid var(--border);transition:all .15s;
}
.page-btn:hover{border-color:var(--cyan);color:var(--blue)}
.page-btn.active{background:var(--blue);border-color:var(--blue);color:#fff}
.page-btn.disabled{opacity:.4;pointer-events:none}

/* Toast */
.toast-base{
  position:fixed;top:20px;right:24px;padding:12px 20px;border-radius:11px;
  font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;
  display:flex;align-items:center;gap:8px;
  box-shadow:0 8px 32px rgba(0,0,0,.2);z-index:999;transition:opacity .4s;
}
</style>
</head>
<body>
<%@ include file="/WEB-INF/views/loading.jsp" %>


<!-- ───────── SIDEBAR ───────── -->
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<!-- ───────── MAIN ───────── -->
<div class="main">

    <!-- TOPBAR -->
    <header class="topbar">
        <span class="topbar-title">🏠 Dashboard</span>
        <div class="topbar-search">
            <input type="text" id="globalSearch" placeholder="Tìm kiếm…">
        </div>
        <div class="topbar-right">
            <div class="topbar-clock">
                <span id="clockH">00</span><span class="clock-sep">:</span><span id="clockM">00</span>
                <span class="clock-date" id="clockDate"></span>
            </div>
            <div class="notif-wrap">
                <button class="topbar-icon-btn" onclick="toggleNotif()" title="Thông báo">
                    🔔
                    <%
                        int totalNotifCount = expiryCount + pendingResetCount;
                    %>
                    <% if (totalNotifCount > 0) { %>
                    <span class="topbar-notif-badge" id="notifBadge"><%= totalNotifCount > 9 ? "9+" : totalNotifCount %></span>
                    <% } %>
                </button>
                <div class="notif-dropdown" id="notifDropdown">
                    <div class="notif-head">
                        <span class="notif-head-title">🔔 Thông báo</span>
                        <button class="notif-clear" onclick="closeNotif()">Đóng ✕</button>
                    </div>
                    <div class="notif-list" id="notifList">
                        <%-- ── Blocked accounts (quá 3 lần forgot-password hôm nay) ── --%>
                        <% for (java.util.Map.Entry<Integer, com.medivault.entity.Account> bEntry : blockedMap.entrySet()) {
                               com.medivault.entity.Account bAcc = bEntry.getValue(); %>
                        <div class="notif-item" style="background:rgba(220,38,38,.04);border-left:3px solid #DC2626">
                          <div class="notif-dot" style="background:#DC2626;animation:pulseDot 1.8s ease-in-out infinite"></div>
                          <div style="flex:1">
                            <div class="notif-text">🚫 <strong>@<%= bAcc.getUsername() %></strong> bị chặn gửi yêu cầu reset MK (quá 3 lần hôm nay)</div>
                            <div class="notif-time" style="margin-top:4px">
                              <a href="<%= request.getContextPath() %>/admin/reset-requests?action=unlock-reset&id=<%= bAcc.getAccountId() %>"
                                 onclick="return confirm('Cho phép @<%= bAcc.getUsername() %> gửi lại yêu cầu reset mật khẩu?')"
                                 style="color:#DC2626;font-weight:700;font-size:11.5px">🔓 Cho phép gửi lại</a>
                            </div>
                          </div>
                        </div>
                        <% } %>

                        <%-- ── Reset requests — hiện đầu tiên, ưu tiên cao nhất ── --%>
                        <% for (com.medivault.entity.PasswordResetRequest pr : pendingResets) {
                               com.medivault.entity.Account staffPr = resetAccountMap.get(pr.getAccountId());
                               String staffPrName = staffPr != null ? staffPr.getFullName() : ("ID " + pr.getAccountId());
                               String staffPrUser = staffPr != null ? staffPr.getUsername() : "";
                               String editUrl = request.getContextPath() + "/accounts?action=edit&id=" + pr.getAccountId();
                               boolean isConfirmed = "CONFIRMED".equals(pr.getStatus());
                        %>
                        <a href="<%= editUrl %>" class="notif-item" style="text-decoration:none;display:flex;cursor:pointer;
                           background:rgba(245,158,11,.06);border-left:3px solid #F59E0B">
                          <div class="notif-dot" style="background:#D97706;animation:pulseDot 1.8s ease-in-out infinite"></div>
                          <div style="flex:1">
                            <div class="notif-text">🔐 <strong><%= staffPrName %></strong> yêu cầu đổi mật khẩu
                              <span style="display:inline-block;padding:1px 7px;border-radius:10px;font-size:10.5px;font-weight:700;margin-left:5px;
                                   background:<%= isConfirmed ? "#FEF3C7" : "#FEE2E2" %>;color:<%= isConfirmed ? "#92400E" : "#991B1B" %>">
                                <%= isConfirmed ? "Đã xác nhận" : "Chờ xử lý" %>
                              </span>
                            </div>
                            <div class="notif-time">@<%= staffPrUser %> · Bấm để đặt mật khẩu mới</div>
                          </div>
                          <span style="font-size:13px;color:var(--muted);margin-left:auto;align-self:center">→</span>
                        </a>
                        <% } %>

                        <%-- ── Thuốc hết hạn ── --%>
                        <% if (expiryCount > 0) { %>
                        <div class="notif-item"><div class="notif-dot"></div><div><div class="notif-text">⚠️ Có <%= expiryCount %> mặt hàng sắp hết hạn</div><div class="notif-time">Hôm nay</div></div></div>
                        <% } else { %>
                        <div class="notif-item"><div class="notif-dot old"></div><div><div class="notif-text">✅ Không có thuốc nào sắp hết hạn</div><div class="notif-time">Hôm nay</div></div></div>
                        <% } %>
                        <div class="notif-item"><div class="notif-dot old"></div><div><div class="notif-text">👤 Admin <%= fullName %> đăng nhập</div><div class="notif-time" id="loginTime"></div></div></div>
                    </div>
                </div>
            </div>
            <a href="<%= request.getContextPath() %>/accounts?action=view&id=<%= acc.getAccountId() %>" class="topbar-user" title="Xem hồ sơ của tôi">
                <div class="topbar-user-avatar"><%= initials %></div>
                <span class="topbar-user-name"><%= fullName %></span>
            </a>
        </div>
    </header>

    <!-- CONTENT -->
    <div class="content">

        <!-- Page heading -->
        <div class="page-head">
            <div class="page-head-left">
                <div class="breadcrumb">MediVault › Trang chủ</div>
                <h1>Dashboard</h1>
            </div>
            <div style="display:flex;gap:10px;align-items:center">
                <a href="${pageContext.request.contextPath}/accounts?action=new" class="btn-primary">
                    ＋ Tạo tài khoản mới
                </a>
            </div>
        </div>

        <!-- Alert nếu có thuốc sắp hết hạn -->
        <% if (expiryCount > 0) { %>
        <div class="alert-card">
            <div class="alert-icon">⚠️</div>
            <div class="alert-text">
                <strong><%= expiryCount %> mặt hàng sắp hết hạn</strong>
                <p>Kiểm tra và xử lý trước khi hết hạn sử dụng để tránh thiệt hại.</p>
            </div>
            <a href="${pageContext.request.contextPath}/medicines?filter=expiry" class="alert-link">Xem ngay →</a>
        </div>
        <% } %>

        <!-- STAT CARDS -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-card-top">
                    <span class="stat-label">Doanh thu hôm nay</span>
                    <div class="stat-icon gold">💰</div>
                </div>
                <div class="stat-value">
                    <% java.text.NumberFormat nf = java.text.NumberFormat.getInstance(new java.util.Locale("vi","VN"));
                       out.print(nf.format(todayRevenue)); %>đ
                </div>
                <div class="stat-diff"><span>Từ hóa đơn đã thanh toán</span></div>
            </div>
            <div class="stat-card">
                <div class="stat-card-top">
                    <span class="stat-label">Hóa đơn hôm nay</span>
                    <div class="stat-icon green">🧾</div>
                </div>
                <div class="stat-value"><%= todayInvoice %></div>
                <div class="stat-diff"><span>Tổng số hóa đơn trong ngày</span></div>
            </div>
            <div class="stat-card">
                <div class="stat-card-top">
                    <span class="stat-label">Thuốc sắp hết hạn</span>
                    <div class="stat-icon red">⏰</div>
                </div>
                <div class="stat-value"><%= expiryCount %></div>
                <div class="stat-diff">
                    <% if (expiryCount > 0) { %><span class="down">▲ Cần xử lý</span><% } else { %><span class="up">✓ Không có</span><% } %>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-card-top">
                    <span class="stat-label">Tài khoản kích hoạt</span>
                    <div class="stat-icon blue">👤</div>
                </div>
                <div class="stat-value"><%= activeAccounts %></div>
                <div class="stat-diff"><span id="onlineCountText">Đang tải...</span></div>
            </div>
        </div>

        <!-- TABLE CARD -->
        <div class="table-card">
            <div class="table-card-header">
                <div>
                    <div class="table-card-title">Danh sách tài khoản nhân viên</div>
                    <div class="table-card-subtitle">Quản lý và phân quyền tài khoản hệ thống</div>
                </div>
            </div>

            <!-- Filter row -->
            <form method="get" action="${pageContext.request.contextPath}/dashboard" id="filterForm" onsubmit="return false">
                <div class="filter-row">
                    <div class="filter-search">
                        <input type="text" name="q" placeholder="Tìm theo tên, email…"
                               value="${param.q}">
                    </div>
                    <select name="role" class="filter-select" onchange="filterTable()">
                        <option value="">Tất cả chức vụ</option>
                        <option value="1" ${param.role == '1' ? 'selected' : ''}>🛡️ Admin</option>
                        <option value="2" ${param.role == '2' ? 'selected' : ''}>💊 Dược sĩ</option>
                        <option value="3" ${param.role == '3' ? 'selected' : ''}>📦 Thủ kho</option>
                    </select>
                    <select name="status" class="filter-select" onchange="filterTable()">
                        <option value="">Tất cả trạng thái</option>
                        <option value="1" ${param.status == '1' ? 'selected' : ''}>Đang hoạt động</option>
                        <option value="0" ${param.status == '0' ? 'selected' : ''}>Đã khóa</option>
                    </select>
                    <button type="button" class="filter-chip" onclick="filterTable()">🔍 Lọc</button>
                    <a href="${pageContext.request.contextPath}/dashboard" class="filter-chip">✕ Xóa lọc</a>
                </div>
            </form>

            <div class="table-wrap">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th style="width:44px">#</th>
                            <th>Nhân viên</th>
                            <th>Email</th>
                            <th>Số điện thoại</th>
                            <th>Chức vụ</th>
                            <th>Trạng thái</th>
                            <th style="width:160px">Thao tác</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${empty accounts}">
                                <tr>
                                    <td colspan="7">
                                        <div class="empty-state">
                                            <div class="icon">👤</div>
                                            <p>Không tìm thấy tài khoản nào.</p>
                                        </div>
                                    </td>
                                </tr>
                            </c:when>
                            <c:otherwise>
                                <c:forEach var="a" items="${accounts}" varStatus="st">
                                    <tr>
                                        <td style="color:var(--text-muted); font-size:12px;">${st.count}</td>
                                        <td>
                                            <div class="cell-user">
                                                <c:set var="displayName" value="${not empty a.fullName ? a.fullName : a.username}"/>
                                                <div class="cell-avatar">
                                                    ${fn:toUpperCase(fn:substring(displayName, 0, 1))}${fn:toUpperCase(fn:substring(displayName, 1, 2))}
                                                </div>
                                                <div>
                                                    <div class="cell-user-name">${a.fullName != null ? a.fullName : '—'}</div>
                                                    <div class="cell-user-sub">@${a.username}</div>
                                                </div>
                                            </div>
                                        </td>
                                        <td style="color:var(--text-muted); font-size:13px;">
                                            ${a.email != null ? a.email : '—'}
                                        </td>
                                        <td style="color:var(--text-muted); font-size:13px;">
                                            ${a.phone != null ? a.phone : '—'}
                                        </td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${a.roleId == 1}">
                                                    <span class="badge badge-red">Admin</span>
                                                </c:when>
                                                <c:when test="${a.roleId == 2}">
                                                    <span class="badge badge-blue">Dược sĩ</span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="badge badge-gold">Thủ kho</span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td class="status-badge-cell">
                                            <c:choose>
                                                <c:when test="${!a.active}">
                                                    <span class="badge badge-red">🔒 Đã khóa</span>
                                                </c:when>
                                                <c:when test="${onlineStaff != null && onlineStaff.contains(a.accountId.toString())}">
                                                    <span class="badge badge-green" title="Đang đăng nhập">🟢 Online</span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="badge" style="background:#F1F5F9;color:#64748B">⚫ Offline</span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td>
                                            <div class="action-group">
                                                <a href="${pageContext.request.contextPath}/accounts?action=edit&id=${a.accountId}"
                                                   class="action-btn action-btn-edit">✏️ Sửa</a>
                                                <form method="post" action="${pageContext.request.contextPath}/accounts"
                                                      style="display:inline"
                                                      onsubmit="return confirm('Xác nhận thay đổi trạng thái tài khoản này?')">
                                                    <input type="hidden" name="action" value="toggle">
                                                    <input type="hidden" name="accountId" value="${a.accountId}">
                                                    <button type="submit"
                                                        class="action-btn ${a.active ? 'action-btn-toggle-off' : 'action-btn-toggle-on'}"
                                                        ${a.active ? '🔒 Khóa' : '🔓 Mở'}
                                                    </button>
                                                </form>
                                            </div>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>

            <!-- Pagination -->
            <% Integer curPage = (Integer) request.getAttribute("currentPage");
               Integer totPages = (Integer) request.getAttribute("totalPages");
               Integer totRecords = (Integer) request.getAttribute("totalRecords");
               if (curPage == null) curPage = 1;
               if (totPages == null) totPages = 1;
               if (totRecords == null) totRecords = 0;
            %>
            <div class="pagination">
                <div class="pagination-info">
                    Hiển thị trang <%= curPage %> / <%= totPages %>
                    &nbsp;·&nbsp; Tổng <%= totRecords %> tài khoản
                </div>
                <div class="pagination-btns">
                    <% if (curPage > 1) { %>
                    <a href="?page=<%= curPage - 1 %>&q=${param.q}&role=${param.role}&status=${param.status}"
                       class="page-btn">‹</a>
                    <% } else { %>
                    <span class="page-btn disabled">‹</span>
                    <% } %>

                    <% for (int p = Math.max(1, curPage - 2); p <= Math.min(totPages, curPage + 2); p++) { %>
                    <a href="?page=<%= p %>&q=${param.q}&role=${param.role}&status=${param.status}"
                       class="page-btn <%= p == curPage ? "active" : "" %>"><%= p %></a>
                    <% } %>

                    <% if (curPage < totPages) { %>
                    <a href="?page=<%= curPage + 1 %>&q=${param.q}&role=${param.role}&status=${param.status}"
                       class="page-btn">›</a>
                    <% } else { %>
                    <span class="page-btn disabled">›</span>
                    <% } %>
                </div>
            </div>
        </div>

    </div><!-- /content -->
</div><!-- /main -->

<!-- Toast thông báo -->
<% java.lang.String msg = request.getParameter("msg"); %>
<% if ("created".equals(msg)) { %>
<div id="toast" class="toast-base" style="background:#064e3b;color:#fff">✅ Tài khoản mới đã được tạo thành công!</div>
<% } else if ("locked".equals(msg)) { %>
<div id="toast" class="toast-base" style="background:#7f1d1d;color:#fff">🔒 Đã khóa tài khoản.</div>
<% } else if ("unlocked".equals(msg)) { %>
<div id="toast" class="toast-base" style="background:#064e3b;color:#fff">🔓 Đã mở khóa tài khoản.</div>
<% } else if ("reset-unblocked".equals(msg)) { %>
<div id="toast" class="toast-base" style="background:#1e40af;color:#fff">🔓 Đã cho phép nhân viên gửi lại yêu cầu đặt lại mật khẩu!</div>
<% } %>

<script>
    // ── Real-time online status polling (mỗi 15s) ──
    async function refreshOnlineStatus() {
        try {
            const res = await fetch('${pageContext.request.contextPath}/accounts?action=online-status', {
                headers: {'X-Requested-With': 'XMLHttpRequest'}
            });
            if (!res.ok) return;
            const data = await res.json();

            // Cập nhật số online trong stat card
            const onlineText = document.getElementById('onlineCountText');
            if (onlineText) {
                const cnt = data.onlineCount || 0;
                onlineText.textContent = cnt > 0
                    ? '🟢 ' + cnt + ' đang online'
                    : '⚫ Không có ai online';
                onlineText.style.color = cnt > 0 ? 'var(--green)' : 'var(--text-muted)';
                onlineText.style.fontWeight = cnt > 0 ? '600' : '';
            }

            // Cập nhật badge từng row trong table
            if (data.onlineIds) {
                document.querySelectorAll('tbody tr[data-name]').forEach(row => {
                    const accId = row.dataset.accId;
                    if (!accId) return;
                    const statusTd = row.querySelector('.status-badge-cell');
                    if (!statusTd) return;
                    const isOnline = data.onlineIds.includes(accId);
                    const isActive = row.dataset.status === '1';
                    if (!isActive) {
                        statusTd.innerHTML = '<span class="badge badge-red">🔒 Đã khóa</span>';
                    } else if (isOnline) {
                        statusTd.innerHTML = '<span class="badge badge-green" title="Đang đăng nhập">🟢 Online</span>';
                    } else {
                        statusTd.innerHTML = '<span class="badge" style="background:#F1F5F9;color:#64748B">⚫ Offline</span>';
                    }
                });
            }
        } catch(e) { /* silent fail */ }
    }

    // Chạy ngay + mỗi 15 giây
    refreshOnlineStatus();
    setInterval(refreshOnlineStatus, 15000);

    function updateClock() {
        const now = new Date();
        const h = now.getHours().toString().padStart(2,'0');
        const m = now.getMinutes().toString().padStart(2,'0');
        const days = ['CN','T2','T3','T4','T5','T6','T7'];
        const d = now.getDate().toString().padStart(2,'0');
        const mo = (now.getMonth()+1).toString().padStart(2,'0');
        if(document.getElementById('clockH')) document.getElementById('clockH').textContent = h;
        if(document.getElementById('clockM')) document.getElementById('clockM').textContent = m;
        if(document.getElementById('clockDate')) document.getElementById('clockDate').textContent = days[now.getDay()] + ', ' + d + '/' + mo;
        if(document.getElementById('loginTime')) document.getElementById('loginTime').textContent = h + ':' + m + ' hôm nay';
    }
    updateClock(); setInterval(updateClock, 1000);
    function toggleNotif() { document.getElementById('notifDropdown').classList.toggle('open'); }
    function closeNotif() { document.getElementById('notifDropdown').classList.remove('open'); }
    document.addEventListener('click', function(e) { const w = document.querySelector('.notif-wrap'); if(w && !w.contains(e.target)) closeNotif(); });

    // Auto-hide toast
    const toast = document.getElementById('toast');
    if (toast) setTimeout(() => { toast.style.opacity = '0'; setTimeout(() => toast.remove(), 400); }, 3000);

    // Realtime search with debounce
    let searchTimer;
    document.getElementById('globalSearch').addEventListener('input', function() {
        clearTimeout(searchTimer);
        const q = this.value;
        searchTimer = setTimeout(() => {
            if (q.length > 1) {
                document.querySelector('[name="q"]').value = q;
                document.getElementById('filterForm').submit();
            }
        }, 600);
    });
</script>

<script>
function filterTable() {
  const q      = (document.querySelector('#filterForm [name="q"]')?.value || '').toLowerCase();
  const role   = document.querySelector('#filterForm [name="role"]')?.value || '';
  const status = document.querySelector('#filterForm [name="status"]')?.value || '';
  document.querySelectorAll('tbody tr[data-name]').forEach(row => {
    const show = (!q      || (row.dataset.name  || '').toLowerCase().includes(q))
              && (!role   || row.dataset.role   === role)
              && (!status || row.dataset.status === status);
    row.style.display = show ? '' : 'none';
  });
}
document.querySelector('#filterForm [name="q"]')
  ?.addEventListener('input', filterTable);
</script>

</body>
</html>
