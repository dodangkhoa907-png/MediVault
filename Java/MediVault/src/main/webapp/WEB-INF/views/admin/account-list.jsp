<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    com.medivault.entity.Account acc = (com.medivault.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    if (acc.getRoleId() != 1) { response.sendRedirect(request.getContextPath() + "/dashboard"); return; }
    java.lang.String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    java.lang.String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
    java.lang.String msg = request.getParameter("msg");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Quản lý tài khoản — MediVault</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&family=DM+Serif+Display:ital@0;1&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;--cyan-soft:#EBF8FD;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;--sidebar:232px;
}
html,body{height:100%;font-family:'Outfit',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar::after{content:'';position:absolute;top:0;right:0;bottom:0;width:1px;background:linear-gradient(180deg,transparent,rgba(58,189,224,.12) 30%,rgba(58,189,224,.12) 70%,transparent)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-icon{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;box-shadow:0 4px 16px rgba(58,189,224,.35)}
.logo-text{font-family:'Outfit',sans-serif;font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
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
.user-av{width:34px;height:34px;flex-shrink:0;border-radius:9px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.user-name{font-size:12.5px;font-weight:600;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:110px}
.user-role{font-size:10px;color:rgba(255,255,255,.35);margin-top:1px}
.logout-btn{margin-left:auto;width:28px;height:28px;flex-shrink:0;border-radius:8px;background:rgba(220,38,38,.12);border:none;display:flex;align-items:center;justify-content:center;color:rgba(220,38,38,.7);font-size:13px;cursor:pointer;text-decoration:none;transition:all .18s}
.logout-btn:hover{background:rgba(220,38,38,.2);color:#DC2626}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0;overflow-x:hidden}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'DM Serif Display',serif;font-size:16px;color:var(--ink)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px;flex-shrink:0}
.topbar-user{display:flex;align-items:center;gap:8px;padding:5px 12px 5px 7px;border:1.5px solid var(--border);border-radius:20px;text-decoration:none;color:inherit;transition:all .18s}
.topbar-user:hover{border-color:var(--cyan);background:var(--cyan-soft)}
.topbar-av{width:28px;height:28px;border-radius:8px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;color:#fff}
.topbar-name{font-size:13px;font-weight:600;color:var(--navy);max-width:110px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.content{padding:26px 28px;flex:1;min-width:0;overflow-x:auto}
.page-head{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:22px}
.breadcrumb{font-size:11.5px;color:var(--muted);font-weight:500;margin-bottom:4px}
.page-head h1{font-family:'DM Serif Display',serif;font-size:26px;color:var(--ink)}
.btn-primary{display:inline-flex;align-items:center;gap:7px;padding:10px 20px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;cursor:pointer;text-decoration:none;transition:all .22s;box-shadow:0 4px 14px rgba(21,88,168,.25)}
.btn-primary:hover{transform:translateY(-1px);box-shadow:0 6px 20px rgba(21,88,168,.35)}
.btn-trash{display:inline-flex;align-items:center;gap:6px;padding:9px 16px;background:#FEF2F2;border:1.5px solid #FECACA;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;color:var(--red);text-decoration:none;transition:all .18s}
.btn-trash:hover{background:#FEE2E2;border-color:#FCA5A5}
.stats-row{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:22px}
.stat-mini{background:var(--white);border:1px solid var(--border);border-radius:14px;padding:16px 18px;display:flex;align-items:center;gap:14px;transition:box-shadow .2s,transform .18s}
.stat-mini:hover{box-shadow:0 4px 16px rgba(21,88,168,.08);transform:translateY(-1px)}
.stat-mini-icon{width:42px;height:42px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0}
.ic-blue{background:rgba(58,189,224,.12)}.ic-green{background:rgba(5,150,105,.1)}.ic-red{background:rgba(220,38,38,.1)}.ic-gold{background:rgba(217,119,6,.12)}
.stat-mini-val{font-family:'DM Serif Display',serif;font-size:24px;color:var(--ink);line-height:1}
.stat-mini-lbl{font-size:11.5px;color:var(--muted);font-weight:500;margin-top:2px}
.card{background:var(--white);border:1px solid var(--border);border-radius:18px;overflow:hidden}
.card-head{padding:20px 24px 14px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
.card-title{font-family:'DM Serif Display',serif;font-size:18px;color:var(--ink)}
.card-sub{font-size:12.5px;color:var(--muted);margin-top:2px}
/* Filter */
.filter-bar{display:flex;gap:10px;align-items:center;padding:13px 22px;border-bottom:1px solid var(--border);background:var(--surface);flex-wrap:wrap}
.fsearch{flex:1;min-width:200px;max-width:300px;position:relative}
.fsearch input{width:100%;height:36px;padding:0 13px 0 36px;background:#fff;border:1.5px solid var(--border);border-radius:10px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);outline:none;transition:all .18s}
.fsearch input:focus{border-color:var(--cyan);box-shadow:0 0 0 3px rgba(58,189,224,.1)}
.fsearch::before{content:'🔍';position:absolute;left:12px;top:50%;transform:translateY(-50%);font-size:12px;pointer-events:none;opacity:.45}
.fselect{height:36px;padding:0 12px;background:#fff;border:1.5px solid var(--border);border-radius:10px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);outline:none;cursor:pointer;transition:all .18s}
.fselect:focus{border-color:var(--cyan)}
.fchip{height:36px;padding:0 14px;background:#fff;border:1.5px solid var(--border);border-radius:10px;font-family:'Outfit',sans-serif;font-size:12.5px;font-weight:600;color:var(--navy);cursor:pointer;transition:all .18s;white-space:nowrap}
.fchip:hover{border-color:var(--cyan);color:var(--blue)}
.fchip.clear{color:var(--muted)}.fchip.clear:hover{border-color:var(--red);color:var(--red)}
/* Table */
.tbl-wrap{overflow-x:auto}
.tbl{width:100%;border-collapse:collapse;font-size:13px}
.tbl th{padding:10px 16px;background:var(--surface);border-bottom:1px solid var(--border);font-size:10.5px;font-weight:700;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;white-space:nowrap}
.tbl td{padding:12px 16px;border-bottom:1px solid #F4F7FC;vertical-align:middle}
.tbl tbody tr{cursor:pointer;transition:background .12s}
.tbl tbody tr:hover{background:#F7FBFF}
.tbl tbody tr:last-child td{border-bottom:none}
.cell-user{display:flex;align-items:center;gap:10px}
.av{width:34px;height:34px;border-radius:9px;flex-shrink:0;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff;overflow:hidden}
.cell-name{font-size:13.5px;font-weight:600;color:var(--ink)}
.cell-sub{font-size:11.5px;color:var(--muted);margin-top:1px}
/* Badges */
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:600;white-space:nowrap}
.b-green{background:rgba(5,150,105,.1);color:var(--green)}
.b-red{background:rgba(220,38,38,.1);color:var(--red)}
.b-blue{background:rgba(21,88,168,.1);color:var(--blue)}
.b-gold{background:rgba(217,119,6,.1);color:var(--gold)}
.b-gray{background:#F1F5F9;color:#64748B}
/* Row actions */
.act-group{display:flex;gap:6px}
.act-btn{padding:5px 10px;border-radius:7px;font-size:12px;font-weight:600;text-decoration:none;cursor:pointer;border:none;font-family:'Outfit',sans-serif;transition:all .15s;white-space:nowrap}
.act-view{background:rgba(21,88,168,.08);color:var(--blue)}.act-view:hover{background:rgba(21,88,168,.16)}
.act-del{background:rgba(220,38,38,.08);color:var(--red)}.act-del:hover{background:rgba(220,38,38,.16)}
/* Pagination */
.pagination{display:flex;align-items:center;justify-content:space-between;padding:14px 24px;border-top:1px solid var(--border)}
.pg-info{font-size:12.5px;color:var(--muted)}
.pg-btns{display:flex;gap:5px}
.pg-btn{width:32px;height:32px;border-radius:8px;display:inline-flex;align-items:center;justify-content:center;font-size:13px;font-weight:600;text-decoration:none;color:var(--navy);background:var(--surface);border:1.5px solid var(--border);transition:all .15s}
.pg-btn:hover{border-color:var(--cyan);color:var(--blue)}.pg-btn.on{background:var(--blue);border-color:var(--blue);color:#fff}.pg-btn.off{opacity:.4;pointer-events:none}
/* Empty */
.empty{padding:48px 24px;text-align:center;color:var(--muted)}.empty .ei{font-size:36px;margin-bottom:10px}
/* Toast */
.toast{position:fixed;top:20px;right:24px;padding:12px 20px;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;display:flex;align-items:center;gap:8px;box-shadow:0 8px 32px rgba(0,0,0,.2);z-index:999;transition:opacity .4s}
.toast-ok{background:#064e3b;color:#fff}.toast-warn{background:#92400E;color:#fff}
@keyframes fadeUp{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)}}
.stat-mini:nth-child(1){animation:fadeUp .3s .05s ease both}.stat-mini:nth-child(2){animation:fadeUp .3s .1s ease both}.stat-mini:nth-child(3){animation:fadeUp .3s .15s ease both}.stat-mini:nth-child(4){animation:fadeUp .3s .2s ease both}
.card{animation:fadeUp .35s .1s ease both}
</style>
</head>
<body>
<%@ include file="/WEB-INF/views/loading.jsp" %>

<aside class="sidebar">
  <div class="sidebar-logo">
    <div class="logo-icon">💊</div>
    <div>
      <div class="logo-text">Medi<span>Vault</span></div>
      <div class="logo-sub">Admin Console</div>
    </div>
  </div>
  <nav class="nav-section">
    <div class="nav-label">Tổng quan</div>
    <a href="${pageContext.request.contextPath}/dashboard" class="nav-item">
      <span>🏠</span> Trang chủ
    </a>
  </nav>
  <nav class="nav-section">
    <div class="nav-label">Quản lý</div>
    <a href="${pageContext.request.contextPath}/accounts" class="nav-item active">
      <span>👤</span> Tài khoản
    </a>
    <a href="${pageContext.request.contextPath}/shifts" class="nav-item"><span>🕐</span> Ca làm việc</a>
    <a href="${pageContext.request.contextPath}/medicines" class="nav-item"><span>💊</span> Kho thuốc</a>
    <a href="${pageContext.request.contextPath}/invoices" class="nav-item"><span>🧾</span> Hóa đơn</a>
    <a href="${pageContext.request.contextPath}/customers" class="nav-item"><span>👥</span> Khách hàng</a>
    <a href="${pageContext.request.contextPath}/returns" class="nav-item"><span>↩️</span> Trả hàng</a>
  </nav>
  <nav class="nav-section">
    <div class="nav-label">Phân tích</div>
    <a href="${pageContext.request.contextPath}/audit-logs" class="nav-item"><span>📋</span> Nhật ký</a>
    <a href="${pageContext.request.contextPath}/reports" class="nav-item"><span>📊</span> Báo cáo</a>
  </nav>
  <div class="sidebar-footer">
    <div class="sidebar-user">
      <div class="user-av"><%= initials %></div>
      <div>
        <div class="user-name"><%= fullName %></div>
        <div class="user-role">Admin</div>
      </div>
      <a href="${pageContext.request.contextPath}/logout" class="logout-btn" title="Đăng xuất">⏻</a>
    </div>
  </div>
</aside>

<div class="main">
  <header class="topbar">
    <span class="topbar-title">👤 Quản lý tài khoản</span>
    <div class="topbar-right">
      <a href="${pageContext.request.contextPath}/dashboard" class="topbar-user" style="font-size:13px;font-weight:500;color:var(--muted);text-decoration:none;padding:6px 12px;border:1.5px solid var(--border);border-radius:8px;">← Dashboard</a>
      <div class="topbar-user">
        <div class="topbar-av"><%= initials %></div>
        <span class="topbar-name"><%= fullName %></span>
      </div>
    </div>
  </header>

  <div class="content">
    <div class="page-head">
      <div>
        <div class="breadcrumb">MediVault › Quản lý › Tài khoản</div>
        <h1>Tài khoản nhân viên</h1>
      </div>
      <div style="display:flex;gap:10px;align-items:center">
      <a href="${pageContext.request.contextPath}/accounts?action=trash" class="btn-secondary" style="background:#fef2f2;color:#dc2626;border:1px solid #fecaca;padding:9px 16px;border-radius:8px;font-size:13px;font-weight:600;text-decoration:none">🗑️ Thùng rác</a>
      <a href="${pageContext.request.contextPath}/accounts?action=new" class="btn-primary">＋ Tạo tài khoản</a>
    </div>
    </div>

    <%-- STATS --%>
    <%
      java.util.List<com.medivault.entity.Account> allList =
          (java.util.List<com.medivault.entity.Account>) request.getAttribute("accounts");
      if (allList == null) allList = new java.util.ArrayList<>();
      long cntAll    = allList.size();
      long cntActive = allList.stream().filter(com.medivault.entity.Account::isActive).count();
      long cntLocked = cntAll - cntActive;
      long cntAdmin  = allList.stream().filter(a -> a.getRoleId() == 1).count();
    %>
    <div class="stats-row">
      <div class="stat-mini">
        <div class="stat-mini-icon ic-blue">👥</div>
        <div><div class="stat-mini-val"><%= cntAll %></div><div class="stat-mini-lbl">Tổng tài khoản</div></div>
      </div>
      <div class="stat-mini">
        <div class="stat-mini-icon ic-green">✅</div>
        <div><div class="stat-mini-val"><%= cntActive %></div><div class="stat-mini-lbl">Đang hoạt động</div></div>
      </div>
      <div class="stat-mini">
        <div class="stat-mini-icon ic-red">🔒</div>
        <div><div class="stat-mini-val"><%= cntLocked %></div><div class="stat-mini-lbl">Đã khóa</div></div>
      </div>
      <div class="stat-mini">
        <div class="stat-mini-icon ic-gold">🛡️</div>
        <div><div class="stat-mini-val"><%= cntAdmin %></div><div class="stat-mini-lbl">Quản trị viên</div></div>
      </div>
    </div>

    <%-- TABLE --%>
    <div class="card">
      <div class="card-head">
        <div>
          <div class="card-title">Danh sách tài khoản</div>
          <div class="card-sub">Nhấn vào hàng để xem chi tiết nhân viên</div>
        </div>
      </div>

      <div class="filter-bar">
          <div class="fsearch">
            <input type="text" id="searchInput" placeholder="Tìm tên, email, CCCD…" autocomplete="off">
          </div>
          <select id="roleFilter" class="fselect">
            <option value="">Tất cả chức vụ</option>
            <option value="2">💊 Dược sĩ</option>
            <option value="3">📦 Thủ kho</option>
          </select>
          <select id="statusFilter" class="fselect">
            <option value="">Tất cả trạng thái</option>
            <option value="1">🟢 Đang online</option>
            <option value="active">✅ Hoạt động</option>
            <option value="0">🔒 Đã khóa</option>
          </select>
          <button type="button" class="fchip" onclick="applyFilter()">🔍 Lọc</button>
          <button type="button" class="fchip clear" onclick="clearFilter()">✕ Xóa lọc</button>
        </div>

      <div class="tbl-wrap">
        <table class="tbl">
          <thead>
            <tr>
              <th style="width:44px">#</th>
              <th>Nhân viên</th>
              <th>Email</th>
              <th>Điện thoại</th>
              <th>CCCD</th>
              <th style="min-width:95px">Chức vụ</th>
              <th>Chuyên môn</th>
              <th>Trạng thái</th>
              <th>Đăng nhập cuối</th>
              <th style="width:180px">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <c:choose>
              <c:when test="${empty accounts}">
                <tr><td colspan="10">
                  <div class="empty"><div class="ei">👤</div><p>Không tìm thấy tài khoản nào.</p></div>
                </td></tr>
              </c:when>
              <c:otherwise>
                <c:forEach var="a" items="${accounts}" varStatus="st">
                  <tr onclick="location.href='${pageContext.request.contextPath}/accounts?action=view&id=${a.accountId}'"
                      data-name="${fn:toLowerCase(not empty a.fullName ? a.fullName : a.username)} @${fn:toLowerCase(a.username)} ${not empty a.email ? fn:toLowerCase(a.email) : ''} ${not empty a.citizenId ? a.citizenId : ''}"
                      data-role="${a.roleId}"
                      data-status="${a.active ? '1' : '0'}" data-acc-id="${a.accountId}">
                    <td style="color:var(--muted);font-size:12px">${st.count}</td>
                    <td>
                      <div class="cell-user">
                        <c:set var="dn" value="${not empty a.fullName ? a.fullName : a.username}"/>
                        <div class="av">
                          ${fn:toUpperCase(fn:substring(dn,0,1))}${fn:toUpperCase(fn:substring(dn,1,2))}
                        </div>
                        <div>
                          <div class="cell-name">${not empty a.fullName ? a.fullName : '—'}</div>
                          <div class="cell-sub">@${a.username}</div>
                        </div>
                      </div>
                    </td>
                    <td style="color:var(--muted);font-size:13px">${not empty a.email ? a.email : '—'}</td>
                    <td style="color:var(--muted);font-size:13px">${not empty a.phone ? a.phone : '—'}</td>
                    <td style="color:var(--muted);font-size:13px">${not empty a.citizenId ? a.citizenId : '—'}</td>
                    <td>
                      <c:choose>
                        <c:when test="${a.roleId==1}"><span class="badge b-red">Admin</span></c:when>
                        <c:when test="${a.roleId==2}"><span class="badge b-blue">Dược sĩ</span></c:when>
                        <c:otherwise><span class="badge b-gold">Thủ kho</span></c:otherwise>
                      </c:choose>
                    </td>
                    <td style="color:var(--muted);font-size:12.5px">${not empty a.position ? a.position : '—'}</td>
                    <td class="status-badge-cell">
                      <c:choose>
                          <c:when test="${!a.active}">
                            <span class="badge b-red">🔒 Đã khóa</span>
                          </c:when>
                          <c:when test="${onlineStaff != null && onlineStaff.contains(a.accountId.toString())}">
                            <span class="badge b-green">🟢 Đang online</span>
                          </c:when>
                          <c:otherwise>
                            <span class="badge" style="background:#F1F5F9;color:#64748B">⚫ Offline</span>
                          </c:otherwise>
                        </c:choose>
                    </td>
                    <td style="color:var(--muted);font-size:12px">
                      <c:choose>
                        <c:when test="${a.lastLoginAt != null}">
                          ${a.lastLoginAt.dayOfMonth}/${a.lastLoginAt.monthValue}/${a.lastLoginAt.year} ${a.lastLoginAt.hour}:<c:if test="${a.lastLoginAt.minute lt 10}">0</c:if>${a.lastLoginAt.minute}
                        </c:when>
                        <c:otherwise>Chưa đăng nhập</c:otherwise>
                      </c:choose>
                    </td>
                    <td onclick="event.stopPropagation()">
                      <div class="act-group">
                        <a href="${pageContext.request.contextPath}/accounts?action=view&id=${a.accountId}" class="act-btn act-view">👁 Xem</a>
                        <a href="${pageContext.request.contextPath}/accounts?action=delete&id=${a.accountId}"
                           onclick="return confirm('Chuyển tài khoản @${a.username} vào thùng rác?')"
                           class="act-btn" style="background:#fef2f2;color:#dc2626;border:1px solid #fecaca">🗑️</a>
                      </div>
                    </td>
                  </tr>
                </c:forEach>
              </c:otherwise>
            </c:choose>
          </tbody>
        </table>
      </div>

      <%
        Integer curPage   = (Integer) request.getAttribute("currentPage");
        Integer totPages  = (Integer) request.getAttribute("totalPages");
        Integer totRecs   = (Integer) request.getAttribute("totalRecords");
        if (curPage  == null) curPage  = 1;
        if (totPages == null) totPages = 1;
        if (totRecs  == null) totRecs  = allList.size();
      %>
      <div class="pagination">
        <div class="pg-info">Trang <%= curPage %> / <%= totPages %> &nbsp;·&nbsp; Tổng <%= totRecs %> tài khoản</div>
        <div class="pg-btns">
          <% if (curPage > 1) { %>
          <a href="?page=<%= curPage-1 %>&q=${param.q}&role=${param.role}&status=${param.status}" class="pg-btn">‹</a>
          <% } else { %><span class="pg-btn off">‹</span><% } %>
          <% for (int p = Math.max(1,curPage-2); p <= Math.min(totPages,curPage+2); p++) { %>
          <a href="?page=<%= p %>&q=${param.q}&role=${param.role}&status=${param.status}"
             class="pg-btn <%= p==curPage?"on":"" %>"><%= p %></a>
          <% } %>
          <% if (curPage < totPages) { %>
          <a href="?page=<%= curPage+1 %>&q=${param.q}&role=${param.role}&status=${param.status}" class="pg-btn">›</a>
          <% } else { %><span class="pg-btn off">›</span><% } %>
        </div>
      </div>
    </div>
  </div>
</div>

<% if ("created".equals(msg)) { %><div class="toast toast-ok">✅ Tạo tài khoản thành công!</div>
<% } else if ("updated".equals(msg)) { %><div class="toast toast-ok">✅ Cập nhật thành công!</div>
<% } else if ("locked".equals(msg)) { %><div class="toast toast-warn">🔒 Đã khóa tài khoản.</div>
<% } else if ("unlocked".equals(msg)) {
     String unlockedNameParam = request.getParameter("name");
%><div class="toast toast-ok" style="flex-direction:column;align-items:flex-start;gap:3px">
  <div>🔓 Đã mở khóa tài khoản thành công!</div>
  <% if (unlockedNameParam != null && !unlockedNameParam.isEmpty()) { %>
  <div style="font-size:12px;opacity:.8">📧 Đã gửi email thông báo đến <strong><%= unlockedNameParam %></strong></div>
  <% } %>
</div>
<% } else if ("deleted".equals(msg)) { %><div class="toast toast-warn">🗑️ Đã chuyển vào thùng rác.</div>
<% } else if ("nochange".equals(msg)) { %><div class="toast toast-warn">ℹ️ Không có thay đổi nào được ghi nhận.</div>
<% } else if ("last-admin".equals(msg)) { %><div class="toast toast-warn">⚠️ Không thể thực hiện — đây là Admin duy nhất!</div>
<% } else if ("in-reset".equals(msg)) { %><div class="toast toast-warn">🔒 Không thể mở khóa — tài khoản đang chờ đặt lại mật khẩu!</div>
<% } else if ("otp-expired".equals(msg)) { %><div class="toast toast-warn">⏱️ Mã OTP đã hết hạn.</div>
<% } %>

<script>
const t = document.querySelector('.toast');
if (t) setTimeout(() => { t.style.opacity='0'; t.style.transition='opacity .4s'; setTimeout(()=>t.remove(),400); }, 3000);

// ── REALTIME FILTER ──────────────────────────────────────────
function applyFilter() {
    const q      = (document.getElementById('searchInput').value || '').toLowerCase().trim();
    const role   = document.getElementById('roleFilter').value;
    const status = document.getElementById('statusFilter').value;
    let visible  = 0;

    document.querySelectorAll('tbody tr[data-name]').forEach(row => {
        const name   = (row.dataset.name   || '').toLowerCase();
        const rId    = row.dataset.role    || '';
        const isAct  = row.dataset.status  || '';
        // online: check badge text
        const badge  = row.querySelector('td:nth-child(8) .badge');
        const isOnline = badge && badge.textContent.includes('online');

        const matchQ = !q || name.includes(q);
        const matchRole = !role || rId === role;
        let matchStatus = true;
        if (status === '1')      matchStatus = isOnline;
        else if (status === 'active') matchStatus = isAct === '1';
        else if (status === '0') matchStatus = isAct === '0';

        const show = matchQ && matchRole && matchStatus;
        row.style.display = show ? '' : 'none';
        if (show) visible++;
    });

    // Cập nhật empty state
    const empty = document.getElementById('emptyRow');
    const emptyMsg = document.getElementById('noResultMsg');
    if (empty) empty.style.display = visible === 0 ? '' : 'none';
    if (emptyMsg) emptyMsg.style.display = visible === 0 ? '' : 'none';
}

function clearFilter() {
    document.getElementById('searchInput').value = '';
    document.getElementById('roleFilter').value = '';
    document.getElementById('statusFilter').value = '';
    applyFilter();
}

// Realtime: gõ là lọc ngay
document.getElementById('searchInput').addEventListener('input', applyFilter);
document.getElementById('roleFilter').addEventListener('change', applyFilter);
document.getElementById('statusFilter').addEventListener('change', applyFilter);

// Enter trong search box cũng lọc
document.getElementById('searchInput').addEventListener('keydown', e => {
    if (e.key === 'Enter') { e.preventDefault(); applyFilter(); }
});
</script>
<script>
// Polling online status mỗi 15s — không reload trang
async function refreshOnlineStatus() {
  try {
    const res = await fetch('${pageContext.request.contextPath}/accounts?action=online-status', {
      headers: {'X-Requested-With': 'XMLHttpRequest'}
    });
    if (!res.ok) return;
    const data = await res.json();
    if (!data.onlineIds) return;
    document.querySelectorAll('tbody tr[data-status]').forEach(row => {
      const accId = row.dataset.accId;
      if (!accId) return;
      const td = row.querySelector('.status-badge-cell');
      if (!td) return;
      const isActive = row.dataset.status === '1';
      const isOnline = data.onlineIds.includes(accId);
      if (!isActive) {
        td.innerHTML = '<span class="badge b-red">🔒 Đã khóa</span>';
      } else if (isOnline) {
        td.innerHTML = '<span class="badge b-green" style="background:rgba(5,150,105,.1);color:#059669">🟢 Đang online</span>';
      } else {
        td.innerHTML = '<span class="badge" style="background:#F1F5F9;color:#64748B">⚫ Offline</span>';
      }
    });
  } catch(e) {}
}
refreshOnlineStatus();
setInterval(refreshOnlineStatus, 15000);
</script>
</body>
</html>
