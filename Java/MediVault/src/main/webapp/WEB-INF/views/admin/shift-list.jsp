<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%
    com.medivault.entity.Account acc = (com.medivault.entity.Account) session.getAttribute("adminAccount");
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
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Ca làm việc — MediVault</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;--amber:#F59E0B;
  --sidebar:232px;--radius:14px;
}
html,body{height:100%;font-family:'Outfit',sans-serif;background:var(--surface);color:var(--ink)}
body{display:flex}

/* ── SIDEBAR ── */
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-icon{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0}
.logo-text{font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-text span{color:var(--cyan)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:12px 0 4px;flex-shrink:0}
.nav-label{font-size:9px;font-weight:700;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:500;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.14);font-weight:600}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--cyan);border-radius:2px}
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06);flex-shrink:0}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08)}
.user-av{width:34px;height:34px;flex-shrink:0;border-radius:9px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.user-name{font-size:12.5px;font-weight:600;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:110px}
.user-role{font-size:10px;color:rgba(255,255,255,.35);margin-top:1px}
.logout-btn{margin-left:auto;width:28px;height:28px;flex-shrink:0;border-radius:8px;background:rgba(220,38,38,.12);border:none;display:flex;align-items:center;justify-content:center;color:rgba(220,38,38,.7);font-size:13px;cursor:pointer;text-decoration:none;transition:all .18s}
.logout-btn:hover{background:rgba(220,38,38,.2);color:#DC2626}

/* ── MAIN ── */
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0}

/* ── TOPBAR ── */
.topbar{height:60px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50;flex-shrink:0}
.topbar-left{display:flex;align-items:center;gap:10px}
.topbar-icon{width:34px;height:34px;border-radius:9px;background:linear-gradient(135deg,rgba(21,88,168,.12),rgba(58,189,224,.12));display:flex;align-items:center;justify-content:center;font-size:15px}
.topbar-title{font-size:16px;font-weight:800;color:var(--ink)}
.topbar-sub{font-size:12px;color:var(--muted);margin-left:2px}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.topbar-pill{display:inline-flex;align-items:center;gap:6px;padding:4px 12px;border-radius:20px;font-size:12.5px;font-weight:700}
.pill-total{background:#EFF6FF;color:var(--blue)}
.pill-open{background:#ECFDF5;color:var(--green)}
.topbar-user{display:flex;align-items:center;gap:8px;padding:5px 12px 5px 7px;border:1.5px solid var(--border);border-radius:20px;text-decoration:none;color:inherit;transition:all .18s}
.topbar-user:hover{border-color:var(--cyan)}
.topbar-av{width:26px;height:26px;border-radius:7px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:10px;font-weight:800;color:#fff}
.topbar-name{font-size:12.5px;font-weight:600;color:var(--navy)}

/* ── CONTENT ── */
.content{padding:22px 26px;flex:1;min-width:0}

/* ── SUMMARY STRIP ── */
.summary-strip{
  display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin-bottom:20px;
}
.sum-card{
  background:var(--white);border:1px solid var(--border);border-radius:var(--radius);
  padding:14px 18px;display:flex;align-items:center;gap:12px;
  transition:box-shadow .2s,transform .18s;
}
.sum-card:hover{box-shadow:0 4px 16px rgba(21,88,168,.08);transform:translateY(-1px)}
.sum-icon{width:38px;height:38px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0}
.sum-ic-blue{background:#EFF6FF}.sum-ic-green{background:#ECFDF5}.sum-ic-amber{background:#FFFBEB}
.sum-num{font-size:22px;font-weight:900;color:var(--ink);line-height:1}
.sum-lbl{font-size:11px;color:var(--muted);font-weight:600;text-transform:uppercase;letter-spacing:.5px;margin-top:2px}

/* ── TWO-COLUMN LAYOUT (form + filter) ── */
.top-row{display:grid;grid-template-columns:1fr 1.4fr;gap:14px;margin-bottom:20px;align-items:start}

/* ── OPEN SHIFT PANEL ── */
.open-panel{
  background:var(--white);border:1.5px solid #BFDBFE;border-radius:var(--radius);
  overflow:hidden;
}
.open-panel-head{
  background:linear-gradient(135deg,#EFF6FF,#F0FDF4);
  padding:12px 18px;display:flex;align-items:center;gap:8px;
  border-bottom:1px solid #DBEAFE;
}
.open-panel-head h3{font-size:13px;font-weight:800;color:#1558A8}
.open-panel-body{padding:14px 18px}
.open-row{display:flex;flex-direction:column;gap:10px}
.fg{display:flex;flex-direction:column;gap:4px}
.fg label{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.fg select,.fg input[type=number]{
  border:1.5px solid var(--border);border-radius:8px;padding:8px 11px;
  font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);
  background:var(--surface);outline:none;transition:border .18s;width:100%
}
.fg select:focus,.fg input:focus{border-color:var(--blue);background:#fff}
.btn-open{
  display:inline-flex;align-items:center;justify-content:center;gap:7px;
  padding:9px 0;background:linear-gradient(135deg,#10B981,#059669);
  color:#fff;border:none;border-radius:9px;font-family:'Outfit',sans-serif;
  font-size:13px;font-weight:700;cursor:pointer;width:100%;
  box-shadow:0 3px 10px rgba(5,150,105,.25);transition:all .18s;
}
.btn-open:hover{opacity:.9;transform:translateY(-1px)}

/* ── FILTER PANEL ── */
.filter-panel{
  background:var(--white);border:1px solid var(--border);border-radius:var(--radius);
  overflow:hidden;
}
.filter-panel-head{
  padding:12px 18px;border-bottom:1px solid var(--border);
  display:flex;align-items:center;gap:8px;
}
.filter-panel-head h3{font-size:13px;font-weight:800;color:var(--ink)}
.filter-body{padding:14px 18px}
.filter-grid{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.fi{display:flex;flex-direction:column;gap:4px}
.fi label{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.fi input,.fi select{
  border:1.5px solid var(--border);border-radius:8px;padding:7px 10px;
  font-family:'Outfit',sans-serif;font-size:12.5px;color:var(--ink);
  background:var(--surface);outline:none;transition:border .18s;
}
.fi input:focus,.fi select:focus{border-color:var(--blue);background:#fff}
.filter-actions{display:flex;gap:8px;margin-top:12px}
.btn-filter{
  flex:1;padding:8px 0;background:var(--blue);color:#fff;border:none;
  border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;
  cursor:pointer;transition:background .18s;
}
.btn-filter:hover{background:#0D3F85}
.btn-reset{
  padding:8px 14px;background:var(--surface);color:var(--muted);
  border:1.5px solid var(--border);border-radius:8px;font-family:'Outfit',sans-serif;
  font-size:13px;font-weight:600;cursor:pointer;text-decoration:none;
  display:inline-flex;align-items:center;transition:all .18s;
}
.btn-reset:hover{border-color:var(--red);color:var(--red)}

/* ── TABLE CARD ── */
.table-card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}
.table-card-head{
  padding:14px 20px;border-bottom:1px solid var(--border);
  display:flex;align-items:center;justify-content:space-between;
}
.table-card-head h2{font-size:14px;font-weight:800;color:var(--ink)}
.table-card-sub{font-size:12px;color:var(--muted)}
.tbl-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse}
thead th{
  padding:10px 16px;background:#F8FAFC;
  font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;
  color:var(--muted);text-align:left;white-space:nowrap;
  border-bottom:1px solid var(--border);
}
tbody td{
  padding:12px 16px;font-size:13px;color:var(--ink);
  border-bottom:1px solid #F1F5F9;vertical-align:middle;
}
tbody tr:last-child td{border-bottom:none}
tbody tr:hover td{background:#F7FBFF}
tbody tr{cursor:pointer;transition:background .12s}

/* Staff cell */
.staff-cell{display:flex;align-items:center;gap:9px}
.staff-av{
  width:30px;height:30px;border-radius:8px;flex-shrink:0;
  background:linear-gradient(135deg,#1558A8,#4F81D9);
  color:#fff;display:flex;align-items:center;justify-content:center;
  font-size:12px;font-weight:800;
}
.staff-name{font-weight:700;color:var(--ink);font-size:13px}
.staff-role{font-size:11px;color:var(--muted)}

/* Time cell */
.time-main{font-size:13px;font-weight:600;color:var(--ink)}
.time-date{font-size:11px;color:var(--muted);margin-top:1px}

/* Duration */
.dur-active{color:var(--green);font-weight:700;font-size:12.5px}

/* Status badges */
.badge{display:inline-flex;align-items:center;gap:5px;padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:700;white-space:nowrap}
.badge-open{background:#ECFDF5;color:#065F46}
.badge-closed{background:#F1F5F9;color:#475569}
.dot{width:6px;height:6px;border-radius:50%;flex-shrink:0}
.dot-open{background:#10B981;animation:pulse 1.5s infinite}
.dot-closed{background:#94A3B8}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.35}}

/* Role badge */
.role-ds{background:#EFF6FF;color:#1558A8;padding:2px 8px;border-radius:5px;font-size:10.5px;font-weight:700}
.role-tk{background:#FFFBEB;color:#92400E;padding:2px 8px;border-radius:5px;font-size:10.5px;font-weight:700}

/* Cash */
.cash{font-variant-numeric:tabular-nums;font-weight:600;font-size:13px}
.cash-empty{color:var(--muted);font-size:12px}

/* Action buttons */
.act-wrap{display:flex;gap:5px;flex-wrap:nowrap}
.act{
  padding:5px 10px;border-radius:7px;font-size:11.5px;font-weight:700;
  border:none;cursor:pointer;text-decoration:none;display:inline-flex;
  align-items:center;gap:4px;white-space:nowrap;transition:all .15s;
}
.act-view{background:#EFF6FF;color:#1558A8}.act-view:hover{background:#DBEAFE}
.act-close{background:#FEF3C7;color:#92400E}.act-close:hover{background:#FDE68A}
.act-del{background:#FEF2F2;color:#991B1B}.act-del:hover{background:#FECACA}

/* Empty */
.empty-box{padding:56px 20px;text-align:center;color:var(--muted)}
.empty-box .ei{font-size:44px;margin-bottom:12px}
.empty-box p{font-size:13.5px}

/* Toast */
.toast{
  position:fixed;top:20px;right:24px;padding:12px 20px;border-radius:11px;
  font-size:13px;font-weight:700;color:#fff;z-index:9999;
  display:flex;align-items:center;gap:8px;
  box-shadow:0 4px 20px rgba(0,0,0,.15);animation:slideIn .3s ease;
}
.toast-ok{background:#059669}.toast-err{background:#DC2626}
.toast-warn{background:#D97706}.toast-info{background:#1558A8}
@keyframes slideIn{from{transform:translateX(60px);opacity:0}to{transform:translateX(0);opacity:1}}

/* Animations */
@keyframes fadeUp{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}
.sum-card:nth-child(1){animation:fadeUp .3s .05s ease both}
.sum-card:nth-child(2){animation:fadeUp .3s .1s ease both}
.sum-card:nth-child(3){animation:fadeUp .3s .15s ease both}
.table-card{animation:fadeUp .35s .15s ease both}
</style>
</head>
<body>

<%-- ── SIDEBAR ── --%>
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
    <a href="${pageContext.request.contextPath}/dashboard" class="nav-item"><span>🏠</span> Trang chủ</a>
  </nav>
  <nav class="nav-section">
    <div class="nav-label">Quản lý</div>
    <a href="${pageContext.request.contextPath}/accounts"  class="nav-item"><span>👤</span> Tài khoản</a>
    <a href="${pageContext.request.contextPath}/shifts"    class="nav-item active"><span>🕐</span> Ca làm việc</a>
    <a href="${pageContext.request.contextPath}/medicines" class="nav-item"><span>💊</span> Kho thuốc</a>
    <a href="${pageContext.request.contextPath}/invoices"  class="nav-item"><span>🧾</span> Hóa đơn</a>
    <a href="${pageContext.request.contextPath}/customers" class="nav-item"><span>👥</span> Khách hàng</a>
    <a href="${pageContext.request.contextPath}/returns"   class="nav-item"><span>↩️</span> Trả hàng</a>
  </nav>
  <nav class="nav-section">
    <div class="nav-label">Phân tích</div>
    <a href="${pageContext.request.contextPath}/audit-logs" class="nav-item"><span>📋</span> Nhật ký</a>
    <a href="${pageContext.request.contextPath}/reports"    class="nav-item"><span>📊</span> Báo cáo</a>
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

<%-- ── MAIN ── --%>
<div class="main">

  <%-- Toast --%>
  <c:if test="${not empty param.msg}">
    <c:choose>
      <c:when test="${param.msg == 'opened'}">      <div class="toast toast-ok"   id="toast">✅ Mở ca thành công!</div></c:when>
      <c:when test="${param.msg == 'closed'}">      <div class="toast toast-ok"   id="toast">✅ Đóng ca thành công!</div></c:when>
      <c:when test="${param.msg == 'force-closed'}"><div class="toast toast-info" id="toast">🔒 Admin đã đóng ca.</div></c:when>
      <c:when test="${param.msg == 'deleted'}">     <div class="toast toast-ok"   id="toast">🗑️ Xóa ca thành công!</div></c:when>
      <c:when test="${param.msg == 'delete-failed'}"><div class="toast toast-err" id="toast">❌ Không thể xóa — ca đã có hóa đơn liên kết!</div></c:when>
      <c:when test="${param.msg == 'already-open'}"><div class="toast toast-warn" id="toast">⚠️ Nhân viên đang có ca chưa đóng!</div></c:when>
      <c:otherwise>                                <div class="toast toast-err"  id="toast">⚠️ Có lỗi xảy ra. Vui lòng thử lại.</div></c:otherwise>
    </c:choose>
  </c:if>

  <%-- Topbar --%>
  <header class="topbar">
    <div class="topbar-left">
      <div class="topbar-icon">🕐</div>
      <div>
        <div class="topbar-title">Ca làm việc</div>
      </div>
    </div>
    <div class="topbar-right">
      <span class="topbar-pill pill-total">📋 ${totalCount} ca</span>
      <span class="topbar-pill pill-open">🟢 ${openCount} đang mở</span>
      <a href="${pageContext.request.contextPath}/dashboard" class="topbar-user">
        <div class="topbar-av"><%= initials %></div>
        <span class="topbar-name"><%= fullName %></span>
      </a>
    </div>
  </header>

  <div class="content">

    <%-- ── Summary strip ── --%>
    <div class="summary-strip">
      <div class="sum-card">
        <div class="sum-icon sum-ic-blue">📋</div>
        <div>
          <div class="sum-num">${totalCount}</div>
          <div class="sum-lbl">Tổng ca</div>
        </div>
      </div>
      <div class="sum-card">
        <div class="sum-icon sum-ic-green">🟢</div>
        <div>
          <div class="sum-num" style="color:var(--green)">${openCount}</div>
          <div class="sum-lbl">Đang mở</div>
        </div>
      </div>
      <div class="sum-card">
        <div class="sum-icon sum-ic-amber">👥</div>
        <div>
          <div class="sum-num">${fn:length(allStaff)}</div>
          <div class="sum-lbl">Nhân viên</div>
        </div>
      </div>
    </div>

    <%-- ── Top row: open form + filter ── --%>
    <div class="top-row">

      <%-- Mở ca --%>
      <div class="open-panel">
        <div class="open-panel-head">
          <span>➕</span>
          <h3>Mở ca mới cho nhân viên</h3>
        </div>
        <div class="open-panel-body">
          <form method="post" action="${pageContext.request.contextPath}/shifts">
            <input type="hidden" name="action" value="open">
            <div class="open-row">
              <div class="fg">
                <label>Nhân viên</label>
                <select name="accountId" required>
                  <option value="">-- Chọn nhân viên --</option>
                  <c:forEach var="staff" items="${allStaff}">
                    <option value="${staff.accountId}">
                      ${staff.fullName} (${staff.roleId == 2 ? 'Dược sĩ' : 'Thủ kho'})
                    </option>
                  </c:forEach>
                </select>
              </div>
              <div class="fg">
                <label>Tiền đầu ca (VNĐ)</label>
                <input type="number" name="openingCash" min="0" step="1000" placeholder="0" value="0">
              </div>
              <button type="submit" class="btn-open">🚀 Mở ca</button>
            </div>
          </form>
        </div>
      </div>

      <%-- Filter --%>
      <div class="filter-panel">
        <div class="filter-panel-head">
          <span>🔍</span>
          <h3>Lọc danh sách</h3>
        </div>
        <div class="filter-body">
          <form method="get" action="${pageContext.request.contextPath}/shifts">
            <div class="filter-grid">
              <div class="fi">
                <label>Từ ngày</label>
                <input type="date" name="from" value="${filterFrom}">
              </div>
              <div class="fi">
                <label>Đến ngày</label>
                <input type="date" name="to" value="${filterTo}">
              </div>
              <div class="fi">
                <label>Nhân viên</label>
                <select name="accountId">
                  <option value="">-- Tất cả --</option>
                  <c:forEach var="staff" items="${allStaff}">
                    <option value="${staff.accountId}"
                      ${filterAcc == staff.accountId ? 'selected' : ''}>
                      ${staff.fullName}
                    </option>
                  </c:forEach>
                </select>
              </div>
              <div class="fi">
                <label>Trạng thái</label>
                <select name="status">
                  <option value=""      ${empty filterStatus              ? 'selected' : ''}>-- Tất cả --</option>
                  <option value="open"   ${filterStatus == 'open'   ? 'selected' : ''}>🟢 Đang mở</option>
                  <option value="closed" ${filterStatus == 'closed' ? 'selected' : ''}>⚫ Đã đóng</option>
                </select>
              </div>
            </div>
            <div class="filter-actions">
              <button type="submit" class="btn-filter">🔍 Lọc</button>
              <a href="${pageContext.request.contextPath}/shifts" class="btn-reset">↺ Reset</a>
            </div>
          </form>
        </div>
      </div>

    </div><%-- /top-row --%>

    <%-- ── Table card ── --%>
    <div class="table-card">
      <div class="table-card-head">
        <h2>📋 Danh sách ca làm việc</h2>
        <span class="table-card-sub">${totalCount} ca — mới nhất trước</span>
      </div>
      <div class="tbl-wrap">
        <c:choose>
          <c:when test="${empty shifts}">
            <div class="empty-box">
              <div class="ei">🕐</div>
              <p>Không có ca làm việc nào phù hợp.</p>
            </div>
          </c:when>
          <c:otherwise>
            <table>
              <thead>
                <tr>
                  <th style="width:44px">#</th>
                  <th>Nhân viên</th>
                  <th>Bắt đầu</th>
                  <th>Kết thúc</th>
                  <th>Thời lượng</th>
                  <th>Tiền đầu ca</th>
                  <th>Tiền cuối ca</th>
                  <th>Trạng thái</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="shift" items="${shifts}">
                  <c:set var="staff" value="${accountMap[shift.accountId]}"/>
                  <tr onclick="location.href='${pageContext.request.contextPath}/shifts?action=detail&id=${shift.shiftId}'">

                    <%-- # --%>
                    <td style="color:var(--muted);font-size:12px;font-weight:600">#${shift.shiftId}</td>

                    <%-- Staff --%>
                    <td>
                      <div class="staff-cell">
                        <div class="staff-av">
                          ${not empty staff ? fn:substring(staff.fullName,0,1) : '?'}
                        </div>
                        <div>
                          <div class="staff-name">${not empty staff ? staff.fullName : 'ID '.concat(shift.accountId)}</div>
                          <span class="${staff.roleId == 2 ? 'role-ds' : 'role-tk'}">
                            ${staff.roleId == 2 ? 'Dược sĩ' : 'Thủ kho'}
                          </span>
                        </div>
                      </div>
                    </td>

                    <%-- Bắt đầu --%>
                    <td>
                      <c:if test="${not empty shift.startTime}">
                        <div class="time-main">${fn:substring(shift.startTime.toString(),11,16)}</div>
                        <div class="time-date">${fn:substring(shift.startTime.toString(),8,10)}/${fn:substring(shift.startTime.toString(),5,7)}/${fn:substring(shift.startTime.toString(),0,4)}</div>
                      </c:if>
                    </td>

                    <%-- Kết thúc --%>
                    <td>
                      <c:choose>
                        <c:when test="${not empty shift.endTime}">
                          <div class="time-main">${fn:substring(shift.endTime.toString(),11,16)}</div>
                          <div class="time-date">${fn:substring(shift.endTime.toString(),8,10)}/${fn:substring(shift.endTime.toString(),5,7)}/${fn:substring(shift.endTime.toString(),0,4)}</div>
                        </c:when>
                        <c:otherwise>
                          <span class="dur-active">⏳ Đang làm</span>
                        </c:otherwise>
                      </c:choose>
                    </td>

                    <%-- Thời lượng --%>
                    <td>
                      <c:choose>
                        <c:when test="${not empty shift.endTime}">
                          <span class="duration-text" data-start="${shift.startTime}" data-end="${shift.endTime}">—</span>
                        </c:when>
                        <c:otherwise>
                          <span class="duration-text dur-active" data-start="${shift.startTime}" data-end="">⏱</span>
                        </c:otherwise>
                      </c:choose>
                    </td>

                    <%-- Tiền đầu ca --%>
                    <td>
                      <c:choose>
                        <c:when test="${not empty shift.openingCash}">
                          <span class="cash"><fmt:formatNumber value="${shift.openingCash}" type="number" maxFractionDigits="0"/>đ</span>
                        </c:when>
                        <c:otherwise><span class="cash-empty">—</span></c:otherwise>
                      </c:choose>
                    </td>

                    <%-- Tiền cuối ca --%>
                    <td>
                      <c:choose>
                        <c:when test="${not empty shift.closingCash}">
                          <span class="cash"><fmt:formatNumber value="${shift.closingCash}" type="number" maxFractionDigits="0"/>đ</span>
                        </c:when>
                        <c:otherwise><span class="cash-empty">—</span></c:otherwise>
                      </c:choose>
                    </td>

                    <%-- Trạng thái --%>
                    <td>
                      <c:choose>
                        <c:when test="${empty shift.endTime}">
                          <span class="badge badge-open"><span class="dot dot-open"></span>Đang mở</span>
                        </c:when>
                        <c:otherwise>
                          <span class="badge badge-closed"><span class="dot dot-closed"></span>Đã đóng</span>
                        </c:otherwise>
                      </c:choose>
                    </td>

                    <%-- Thao tác --%>
                    <td onclick="event.stopPropagation()">
                      <div class="act-wrap">
                        <a href="${pageContext.request.contextPath}/shifts?action=detail&id=${shift.shiftId}"
                           class="act act-view">🔍 Chi tiết</a>
                        <c:if test="${empty shift.endTime}">
                          <a href="${pageContext.request.contextPath}/shifts?action=force-close&id=${shift.shiftId}"
                             class="act act-close">🔒 Đóng</a>
                        </c:if>
                        <c:if test="${not empty shift.endTime}">
                          <a href="${pageContext.request.contextPath}/shifts?action=delete&id=${shift.shiftId}"
                             class="act act-del"
                             onclick="return confirm('Xóa ca này? Chỉ xóa được nếu không có hóa đơn liên kết.')">🗑️</a>
                        </c:if>
                      </div>
                    </td>

                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </c:otherwise>
        </c:choose>
      </div>
    </div><%-- /table-card --%>

  </div><%-- /content --%>
</div><%-- /main --%>

<script>
const toast = document.getElementById('toast');
if (toast) setTimeout(() => { toast.style.opacity = '0'; setTimeout(() => toast.remove(), 400); }, 3500);

function calcDuration(startStr, endStr) {
    if (!startStr) return '—';
    const start = new Date(startStr.replace('T', ' '));
    const end   = endStr ? new Date(endStr.replace('T', ' ')) : new Date();
    const diff  = Math.floor((end - start) / 60000);
    if (isNaN(diff) || diff < 0) return '—';
    const h = Math.floor(diff / 60), m = diff % 60;
    return h > 0 ? (h + 'g ' + m + 'p') : (m + ' phút');
}

document.querySelectorAll('.duration-text').forEach(el => {
    const s = el.dataset.start, e = el.dataset.end;
    if (s) el.textContent = calcDuration(s, e || '');
});

setInterval(() => {
    document.querySelectorAll('.duration-text.dur-active').forEach(el => {
        const s = el.dataset.start;
        if (s) el.textContent = calcDuration(s, '');
    });
}, 60000);
</script>
</body>
</html>
