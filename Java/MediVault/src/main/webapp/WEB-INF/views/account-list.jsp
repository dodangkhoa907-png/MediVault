<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    com.medivault.entity.Account acc = (com.medivault.entity.Account) session.getAttribute("account");
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
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@700;800;900&family=Plus+Jakarta+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --navy:#101A33;--navy2:#1D2D50;--blue:#114C7D;--sky:#46CAF4;
  --surface:#F0F4F9;--border:#DDE6F0;--muted:#6B82A0;--white:#fff;
  --green:#1a7a4a;--red:#e74c3c;--gold:#b8750a;--sidebar:220px;
}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif}
body{display:flex;background:var(--surface);color:var(--navy)}

/* ── SIDEBAR ── */
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(180deg,var(--navy) 0%,#182845 55%,var(--blue) 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100}
.sidebar-logo{padding:20px 18px 18px;display:flex;align-items:center;gap:10px;border-bottom:1px solid rgba(255,255,255,.07)}
.logo-icon{width:38px;height:38px;background:rgba(70,202,244,.15);border:1.5px solid rgba(70,202,244,.3);border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:18px}
.logo-text{font-family:'Nunito',sans-serif;font-size:17px;font-weight:900;color:#fff;letter-spacing:-.3px;line-height:1.1}
.logo-text span{color:var(--sky)}
.logo-sub{font-size:9.5px;color:rgba(255,255,255,.35);letter-spacing:1px;text-transform:uppercase}
.nav-section{padding:16px 0 8px}
.nav-label{font-size:9px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:rgba(255,255,255,.25);padding:0 18px 8px}
.nav-item{display:flex;align-items:center;gap:10px;padding:10px 18px;margin:1px 8px;border-radius:10px;font-size:13px;font-weight:500;color:rgba(255,255,255,.55);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:#fff;background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(70,202,244,.13);font-weight:600}
.nav-item.active::before{content:'';position:absolute;left:-8px;top:50%;transform:translateY(-50%);width:3px;height:60%;background:var(--sky);border-radius:4px}
.sidebar-footer{margin-top:auto;padding:16px 18px;border-top:1px solid rgba(255,255,255,.07)}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:8px 10px;border-radius:10px;background:rgba(255,255,255,.05)}
.user-av{width:32px;height:32px;background:linear-gradient(135deg,var(--sky),var(--blue));border-radius:8px;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff;flex-shrink:0}
.user-name{font-size:12.5px;font-weight:600;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:110px}
.user-role{font-size:10.5px;color:rgba(255,255,255,.35)}
.logout-btn{margin-left:auto;color:rgba(255,255,255,.3);text-decoration:none;font-size:13px;transition:color .15s}
.logout-btn:hover{color:var(--red)}

/* ── MAIN ── */
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0;overflow-x:hidden}
.topbar{height:60px;background:#fff;border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:16px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Nunito',sans-serif;font-size:16px;font-weight:800;color:var(--navy)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:8px}
.topbar-user{display:flex;align-items:center;gap:8px;padding:4px 10px;border:1.5px solid var(--border);border-radius:10px;text-decoration:none;color:inherit}
.topbar-av{width:28px;height:28px;background:linear-gradient(135deg,var(--sky),var(--blue));border-radius:7px;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;color:#fff}
.topbar-name{font-size:13px;font-weight:600;color:var(--navy);max-width:120px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}

.content{padding:28px;flex:1;min-width:0;overflow-x:auto}
.page-head{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:24px}
.breadcrumb{font-size:11.5px;color:var(--muted);font-weight:500;margin-bottom:4px}
.page-head h1{font-family:'Nunito',sans-serif;font-size:24px;font-weight:900;letter-spacing:-.4px}
.btn-primary{display:inline-flex;align-items:center;gap:7px;padding:10px 20px;background:var(--blue);color:#fff;border:none;border-radius:10px;font-size:13.5px;font-weight:600;font-family:inherit;cursor:pointer;text-decoration:none;transition:background .2s}
.btn-primary:hover{background:#0d3d63}

/* STATS */
.stats-row{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:24px}
.stat-mini{background:#fff;border:1px solid var(--border);border-radius:14px;padding:16px 18px;display:flex;align-items:center;gap:14px}
.stat-mini-icon{width:42px;height:42px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0}
.ic-blue{background:rgba(70,202,244,.12)}
.ic-green{background:rgba(26,122,74,.1)}
.ic-red{background:rgba(231,76,60,.1)}
.ic-gold{background:rgba(252,218,124,.2)}
.stat-mini-val{font-family:'Nunito',sans-serif;font-size:22px;font-weight:900;color:var(--navy);line-height:1}
.stat-mini-lbl{font-size:11.5px;color:var(--muted);font-weight:500;margin-top:2px}

/* TABLE CARD */
.card{background:#fff;border:1px solid var(--border);border-radius:16px;overflow:hidden}
.card-head{display:flex;align-items:center;justify-content:space-between;padding:18px 22px 14px;border-bottom:1px solid var(--border)}
.card-title{font-family:'Nunito',sans-serif;font-size:16px;font-weight:800;color:var(--navy)}
.card-sub{font-size:12px;color:var(--muted)}

.filter-bar{display:flex;align-items:center;gap:10px;padding:12px 22px;border-bottom:1px solid var(--border);background:#fafcff;flex-wrap:wrap}
.fsearch{flex:1;min-width:200px;max-width:280px;position:relative}
.fsearch input{width:100%;height:34px;padding:0 12px 0 32px;border:1.5px solid var(--border);border-radius:8px;font-size:13px;font-family:inherit;outline:none;transition:border-color .2s;background:#fff}
.fsearch input:focus{border-color:var(--sky)}
.fsearch::before{content:'🔍';position:absolute;left:10px;top:50%;transform:translateY(-50%);font-size:11px}
.fselect{height:34px;padding:0 28px 0 10px;border:1.5px solid var(--border);border-radius:8px;font-size:13px;font-family:inherit;color:var(--navy);background:#fff url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='10' height='6' fill='none'%3E%3Cpath stroke='%236B82A0' stroke-width='1.5' stroke-linecap='round' d='M1 1l4 4 4-4'/%3E%3C/svg%3E") no-repeat right 8px center;appearance:none;cursor:pointer;outline:none}
.fselect:focus{border-color:var(--sky)}
.fchip{height:34px;padding:0 14px;border:1.5px solid var(--border);border-radius:8px;font-size:12.5px;font-weight:500;color:var(--muted);background:#fff;cursor:pointer;transition:all .15s;white-space:nowrap}
.fchip:hover{background:var(--blue);border-color:var(--blue);color:#fff}
.fchip.clear:hover{background:#e74c3c;border-color:#e74c3c;color:#fff}

.tbl{width:100%;border-collapse:collapse}
.tbl thead{background:#f8fbff}
.tbl th{padding:11px 16px;text-align:left;font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.6px;border-bottom:1px solid var(--border);white-space:nowrap}
.tbl td{padding:12px 16px;font-size:13.5px;border-bottom:1px solid #f0f4f9;vertical-align:middle}
.tbl tr:last-child td{border-bottom:none}
.tbl tbody tr{transition:background .12s;cursor:pointer}
.tbl tbody tr:hover{background:#f4f8ff}

.cell-user{display:flex;align-items:center;gap:10px}
.av{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,var(--sky),var(--blue));display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff;flex-shrink:0;overflow:hidden}
.av img{width:100%;height:100%;object-fit:cover}
.cell-name{font-weight:600;color:var(--navy);font-size:13.5px}
.cell-sub{font-size:11.5px;color:var(--muted)}

.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 9px;border-radius:20px;font-size:11.5px;font-weight:600;white-space:nowrap}
.badge::before{content:'●';font-size:7px}
.b-blue{background:rgba(70,202,244,.12);color:var(--blue)}
.b-green{background:rgba(26,122,74,.1);color:var(--green)}
.b-red{background:rgba(231,76,60,.1);color:var(--red)}
.b-gold{background:rgba(252,218,124,.2);color:var(--gold)}
.b-gray{background:#f0f4f9;color:var(--muted)}

.act-group{display:flex;gap:6px}
.act-btn{height:30px;padding:0 12px;border-radius:7px;border:1.5px solid;font-size:12px;font-weight:600;cursor:pointer;text-decoration:none;display:inline-flex;align-items:center;gap:4px;transition:all .15s;font-family:inherit;white-space:nowrap}
.act-view{border-color:var(--border);color:var(--navy);background:#fff}
.act-view:hover{border-color:var(--sky);color:var(--blue);background:#f0fbff}
.act-edit{border-color:#c0d9f0;color:var(--blue);background:#e8f2fc}
.act-edit:hover{background:#d1e8f8}
.act-lock{border-color:#f5dfa8;color:var(--gold);background:#fff8e6}
.act-lock:hover{background:#ffefc2}
.act-unlock{border-color:#c0d9f0;color:var(--blue);background:#e8f2fc}
.act-unlock:hover{background:#d1e8f8}

.empty{text-align:center;padding:60px;color:var(--muted)}
.empty .ei{font-size:40px;margin-bottom:12px}

.pagination{display:flex;align-items:center;justify-content:space-between;padding:14px 22px;border-top:1px solid var(--border);background:#fafcff}
.pg-info{font-size:12.5px;color:var(--muted)}
.pg-btns{display:flex;gap:4px}
.pg-btn{min-width:32px;height:32px;padding:0 8px;border:1.5px solid var(--border);border-radius:8px;font-size:13px;font-weight:500;color:var(--navy);background:#fff;cursor:pointer;display:flex;align-items:center;justify-content:center;text-decoration:none;transition:all .15s}
.pg-btn:hover{border-color:var(--blue);color:var(--blue)}
.pg-btn.on{background:var(--blue);border-color:var(--blue);color:#fff}
.pg-btn.off{opacity:.4;pointer-events:none}

.tbl-wrap{overflow-x:auto}

/* TOAST */
.toast{position:fixed;top:20px;right:24px;padding:12px 20px;border-radius:10px;font-size:13.5px;font-weight:600;display:flex;align-items:center;gap:8px;box-shadow:0 8px 32px rgba(0,0,0,.2);z-index:999;animation:toastIn .3s ease}
@keyframes toastIn{from{opacity:0;transform:translateY(-10px)}to{opacity:1;transform:translateY(0)}}
.toast-ok{background:#064e3b;color:#fff}
.toast-warn{background:#7f1d1d;color:#fff}
</style>
</head>
<body>

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
  </nav>
  <nav class="nav-section">
    <div class="nav-label">Phân tích</div>
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
      <a href="${pageContext.request.contextPath}/accounts?action=new" class="btn-primary">＋ Tạo tài khoản</a>
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

      <form method="get" action="${pageContext.request.contextPath}/accounts" id="ff">
        <div class="filter-bar">
          <div class="fsearch">
            <input type="text" name="q" placeholder="Tìm tên, email, CCCD…" value="${param.q}">
          </div>
          <select name="role" class="fselect" onchange="ff.submit()">
            <option value="">Tất cả chức vụ</option>
            <option value="1" ${param.role=='1'?'selected':''}>🛡️ Admin</option>
            <option value="2" ${param.role=='2'?'selected':''}>💊 Dược sĩ</option>
            <option value="3" ${param.role=='3'?'selected':''}>📦 Thủ kho</option>
          </select>
          <select name="status" class="fselect" onchange="ff.submit()">
            <option value="">Tất cả trạng thái</option>
            <option value="1" ${param.status=='1'?'selected':''}>Hoạt động</option>
            <option value="0" ${param.status=='0'?'selected':''}>Đã khóa</option>
          </select>
          <button type="submit" class="fchip">🔍 Lọc</button>
          <a href="${pageContext.request.contextPath}/accounts" class="fchip clear">✕ Xóa lọc</a>
        </div>
      </form>

      <div class="tbl-wrap">
        <table class="tbl">
          <thead>
            <tr>
              <th style="width:44px">#</th>
              <th>Nhân viên</th>
              <th>Email</th>
              <th>Điện thoại</th>
              <th>CCCD</th>
              <th>Chức vụ</th>
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
                  <tr onclick="location.href='${pageContext.request.contextPath}/accounts?action=view&id=${a.accountId}'">
                    <td style="color:var(--muted);font-size:12px">${st.count}</td>
                    <td>
                      <div class="cell-user">
                        <c:set var="dn" value="${not empty a.fullName ? a.fullName : a.username}"/>
                        <div class="av">
                          <c:choose>
                            <c:when test="${not empty a.faceEnrollmentPath}">
                              <img src="${pageContext.request.contextPath}/${a.faceEnrollmentPath}" alt="">
                            </c:when>
                            <c:otherwise>
                              ${fn:toUpperCase(fn:substring(dn,0,1))}${fn:toUpperCase(fn:substring(dn,1,2))}
                            </c:otherwise>
                          </c:choose>
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
                    <td>
                      <c:choose>
                        <c:when test="${a.active}"><span class="badge b-green">Hoạt động</span></c:when>
                        <c:otherwise><span class="badge b-gray">Đã khóa</span></c:otherwise>
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
<% } else if ("unlocked".equals(msg)) { %><div class="toast toast-ok">🔓 Đã mở khóa tài khoản.</div>
<% } %>

<script>
const t = document.querySelector('.toast');
if (t) setTimeout(() => { t.style.opacity='0'; t.style.transition='opacity .4s'; setTimeout(()=>t.remove(),400); }, 3000);
</script>
</body>
</html>
