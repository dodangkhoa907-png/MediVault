<%@ page contentType="text/html;charset=UTF-8" language="java"  pageEncoding="UTF-8" %>
<% String activeNav = "attendance"; %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length()>=2 ? fullName.substring(0,1).toUpperCase()+fullName.substring(1,2).toUpperCase() : fullName.toUpperCase();
%>
<!DOCTYPE html><html lang="vi"><head>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
    
    
    
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Lịch sử điểm danh — MediVault</title>

<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--ink:#0B1628;--blue:#1558A8;--cyan:#3ABDE0;--surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;--green:#059669;--red:#DC2626;--amber:#D97706;--purple:#7C3AED;--indigo:#6366F1;--sidebar:232px;--radius:14px}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif;background:var(--surface);color:var(--ink)}body{display:flex}
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06)}
.logo-icon{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:16px}
.logo-text{font-size:16px;font-weight:800;color:#fff}.logo-text span{color:var(--cyan)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:12px 0 4px}.nav-label{font-size:9px;font-weight:750;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:750;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.14);font-weight:750}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--cyan);border-radius:2px}
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06)}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08)}
.user-av{width:34px;height:34px;border-radius:9px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.user-name{font-size:12.5px;font-weight:750;color:#fff;max-width:110px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.user-role{font-size:10px;color:rgba(255,255,255,.35);margin-top:1px}
.logout-btn{margin-left:auto;width:28px;height:28px;border-radius:8px;background:rgba(220,38,38,.12);border:none;display:flex;align-items:center;justify-content:center;color:rgba(220,38,38,.7);font-size:13px;cursor:pointer;text-decoration:none}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Plus Jakarta Sans',sans-serif;font-size:16px;font-weight:750;color:var(--ink)}

    
.tab-bar{display:flex;gap:4px;padding:0 26px;background:var(--white);border-bottom:1px solid var(--border)}
.tab{padding:12px 18px;font-size:13px;font-weight:750;color:var(--muted);text-decoration:none;border-bottom:2.5px solid transparent;transition:all .18s;position:relative}
.tab:hover{color:var(--ink)}.tab.active{color:var(--blue);border-bottom-color:var(--blue)}
.tab-badge{position:absolute;top:8px;right:4px;background:var(--red);color:#fff;font-size:10px;font-weight:750;min-width:16px;height:16px;border-radius:8px;display:inline-flex;align-items:center;justify-content:center;padding:0 4px}
.content{padding:22px 26px;flex:1}
/* Alerts */
.alert-box{border-radius:10px;padding:12px 16px;margin-bottom:16px;display:flex;align-items:center;gap:10px;font-size:13px;font-weight:750}
.alert-warn{background:#FFFBEB;border:1.5px solid #FDE68A;color:#92400E}
.alert-info{background:#EFF6FF;border:1.5px solid #BFDBFE;color:#1558A8}
/* Filter */
.filter-row{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);padding:14px 20px;margin-bottom:16px;display:flex;gap:10px;align-items:flex-end;flex-wrap:wrap}
.fi{display:flex;flex-direction:column;gap:4px}
.fi label{font-size:10px;font-weight:750;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.fi input,.fi select{border:1.5px solid var(--border);border-radius:8px;padding:7px 10px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;color:var(--ink);background:var(--surface);outline:none;height:38px}
.fi input:focus,.fi select:focus{border-color:var(--blue);background:#fff}
.btn-filter{padding:7px 18px;background:var(--blue);color:#fff;border:none;border-radius:8px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;font-weight:750;cursor:pointer;height:34px}
.btn-reset{padding:7px 12px;background:var(--surface);color:var(--muted);border:1.5px solid var(--border);border-radius:8px;font-size:13px;font-weight:750;cursor:pointer;text-decoration:none;display:inline-flex;align-items:center;height:34px}
/* Quick filter pills */
.qfilter-row{display:flex;gap:8px;margin-bottom:14px;flex-wrap:wrap}
.qf{padding:5px 12px;border-radius:20px;font-size:12px;font-weight:750;text-decoration:none;border:1.5px solid var(--border);color:var(--muted);background:var(--white);transition:all .15s}
.qf:hover{border-color:var(--blue);color:var(--blue)}
.qf.active{background:var(--blue);color:#fff;border-color:var(--blue)}
.qf-warn.active{background:#D97706;border-color:#D97706;color:#fff}
.qf-red.active{background:#DC2626;border-color:#DC2626;color:#fff}
/* Table */
.table-card{background:#fff;border:1px solid rgba(213,224,240,.45);border-radius:var(--radius);overflow:hidden;box-shadow:0 1px 3px rgba(15,38,69,.03),0 4px 12px rgba(15,38,69,.04)}
.table-card-head{padding:14px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:8px}
.table-card-head h2{font-size:14px;font-weight:800;color:var(--ink)}
.tc-sub{font-size:12px;color:var(--muted)}
table{width:100%;border-collapse:collapse}
thead th{padding:9px 14px;background:#F8FAFC;font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;border-bottom:1px solid var(--border);white-space:nowrap}
tbody td{padding:10px 14px;font-size:13px;border-bottom:1px solid #F1F5F9;vertical-align:middle}
tbody tr:last-child td{border-bottom:none}
tbody tr:hover td{background:#F7FBFF}
.staff-av{width:28px;height:28px;border-radius:7px;background:linear-gradient(135deg,var(--blue),#4F81D9);color:#fff;display:inline-flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;margin-right:7px;flex-shrink:0}
/* Badges */
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 8px;border-radius:20px;font-size:11px;font-weight:750;white-space:nowrap}
.badge-working{background:#ECFDF5;color:#065F46}
.badge-on-time{background:#ECFDF5;color:#065F46}
.badge-late{background:#FEF3C7;color:#92400E}
.badge-late-early{background:#FEF3C7;color:#92400E}
.badge-early{background:#F5F3FF;color:#6D28D9}
.badge-overtime{background:#EFF6FF;color:#1558A8}
.badge-absent{background:#FEF2F2;color:#991B1B}
.badge-free{background:#F1F5F9;color:#64748B}
.badge-force{background:#FEF2F2;color:#DC2626}
/* 2 badge mới */
.badge-unexcused{background:#FFFBEB;color:#92400E;border:1px solid #FDE68A}
.badge-system-closed{background:#EEF2FF;color:#4338CA;border:1px solid #C7D2FE}
.badge-method{background:#EFF6FF;color:#1558A8;font-size:10px}
/* Action buttons trong bảng */
.btn-sm{display:inline-flex;align-items:center;gap:4px;padding:4px 10px;border-radius:7px;font-family:'Plus Jakarta Sans',sans-serif;font-size:11.5px;font-weight:750;cursor:pointer;border:none;text-decoration:none;transition:all .15s}
.btn-resolve{background:#EEF2FF;color:#4338CA;border:1.5px solid #C7D2FE}
.btn-resolve:hover{background:#E0E7FF}
.btn-excuse{background:#FFFBEB;color:#92400E;border:1.5px solid #FDE68A}
.btn-excuse:hover{background:#FEF3C7}
/* Modal resolve */
.modal-overlay{position:fixed;inset:0;background:rgba(11,22,40,.5);z-index:500;display:flex;align-items:center;justify-content:center;opacity:0;pointer-events:none;transition:opacity .2s}
.modal-overlay.open{opacity:1;pointer-events:auto}
.modal{background:var(--white);border-radius:16px;width:460px;max-width:92vw;box-shadow:0 20px 60px rgba(0,0,0,.2);transform:translateY(14px);transition:transform .22s}
.modal-overlay.open .modal{transform:translateY(0)}
.modal-head{padding:16px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
.modal-title{font-size:14px;font-weight:800;color:var(--ink)}
.modal-close{width:26px;height:26px;border-radius:7px;border:none;background:var(--surface);color:var(--muted);font-size:13px;cursor:pointer;display:flex;align-items:center;justify-content:center}
.modal-close:hover{background:#FEE2E2;color:var(--red)}
.modal-body{padding:20px}
.mfg{display:flex;flex-direction:column;gap:4px;margin-bottom:12px}
.mfg label{font-size:10.5px;font-weight:750;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.mfg textarea,.mfg select,.mfg input{border:1.5px solid var(--border);border-radius:8px;padding:8px 11px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;color:var(--ink);background:var(--surface);outline:none;width:100%}
.mfg textarea:focus,.mfg select:focus{border-color:var(--blue);background:#fff}
.modal-foot{padding:12px 20px;border-top:1px solid var(--border);display:flex;justify-content:flex-end;gap:8px}
.btn-cancel{padding:8px 16px;background:var(--surface);color:var(--muted);border:1.5px solid var(--border);border-radius:8px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;font-weight:750;cursor:pointer}
.btn-save{padding:8px 20px;background:var(--blue);color:#fff;border:none;border-radius:8px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;font-weight:750;cursor:pointer}
.btn-penalize{background:#DC2626;color:#fff;border:none;border-radius:8px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;font-weight:750;cursor:pointer;padding:8px 16px}
.empty-box{padding:40px;text-align:center;color:var(--muted)}
.toast{position:fixed;top:18px;right:22px;padding:11px 18px;border-radius:10px;font-size:13px;font-weight:750;color:#fff;z-index:999;display:flex;align-items:center;gap:8px;box-shadow:0 4px 18px rgba(0,0,0,.15);animation:slideIn .3s ease}
.toast-ok{background:#059669}.toast-err{background:#DC2626}.toast-info{background:#1558A8}
@keyframes slideIn{from{transform:translateX(80px);opacity:0}to{transform:translateX(0);opacity:1}}
/* Note preview */
.note-preview{font-size:11.5px;color:var(--muted);max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;cursor:pointer}
.note-preview:hover{color:var(--ink)}
select,option{font-family:inherit;font-size:inherit}
.cdd{position:relative;user-select:none;display:inline-block}
.cdd-btn{display:flex;align-items:center;gap:6px;padding:9px 14px;background:var(--white,#fff);border:1.5px solid var(--border,#D5E0F0);border-radius:10px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;font-weight:750;color:var(--ink,#0B1628);cursor:pointer;transition:all .18s;white-space:nowrap}
.cdd-btn:hover{border-color:var(--cyan,#3ABDE0);background:var(--cyan-soft,#EBF8FD)}
.cdd-btn.open{border-color:var(--cyan,#3ABDE0);box-shadow:0 0 0 3px rgba(58,189,224,.12)}
.cdd-arrow{font-size:9px;color:var(--muted,#7A90B0);transition:transform .2s}
.cdd-btn.open .cdd-arrow{transform:rotate(180deg)}
.cdd-menu{position:absolute;top:calc(100% + 6px);left:0;min-width:100%;background:var(--white,#fff);border:1.5px solid var(--border,#D5E0F0);border-radius:12px;padding:6px;box-shadow:0 12px 36px rgba(15,38,69,.15);z-index:200;opacity:0;transform:translateY(-6px);pointer-events:none;transition:all .18s ease;max-height:260px;overflow-y:auto}
.cdd-menu.show{opacity:1;transform:translateY(0);pointer-events:auto}
.cdd-menu::-webkit-scrollbar{width:4px}
.cdd-menu::-webkit-scrollbar-thumb{background:var(--border,#D5E0F0);border-radius:4px}
.cdd-opt{padding:8px 14px;border-radius:8px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;font-weight:600;color:var(--ink,#0B1628);cursor:pointer;transition:all .12s;white-space:nowrap}
.cdd-opt:hover{background:var(--surface,#F1F5FB);color:var(--blue,#1558A8)}
.cdd-opt.active{background:linear-gradient(135deg,var(--blue,#1558A8),#0D3F85);color:#fff;font-weight:750}
</style>
    
</head><body>
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>
<div class="main">

<%-- Toast --%>
<c:if test="${not empty param.msg}">
  <c:choose>
    <c:when test="${param.msg=='checked-out'}"><div class="toast toast-ok" id="toast">✅ Đã đóng ca!</div></c:when>
    <c:when test="${param.msg=='resolved'}"><div class="toast toast-ok" id="toast">✅ Đã xử lý ca SYSTEM_CLOSED!</div></c:when>
    <c:when test="${param.msg=='excuse-resolved'}"><div class="toast toast-ok" id="toast">✅ Đã duyệt lý do trễ!</div></c:when>
    <c:when test="${param.msg=='error'}"><div class="toast toast-err" id="toast">❌ Có lỗi xảy ra!</div></c:when>
  </c:choose>
</c:if>

<header class="topbar">
  <div style="font-size:15px">✅</div>
  <span class="topbar-title">Điểm danh</span>
</header>

<div class="tab-bar">
  <a href="${pageContext.request.contextPath}/attendance?action=live" class="tab">🟢 Đang làm việc</a>
  <a href="${pageContext.request.contextPath}/attendance?action=list" class="tab active">
    📋 Lịch sử
    <c:if test="${(systemClosedCount + lateUnexcusedCount) > 0}">
      <span class="tab-badge">${systemClosedCount + lateUnexcusedCount}</span>
    </c:if>
  </a>
  <a href="${pageContext.request.contextPath}/attendance?action=monthly" class="tab">📊 Tổng hợp tháng</a>
</div>

<div class="content">

  <%-- Alert nếu có bản ghi chờ xử lý --%>
  <c:if test="${systemClosedCount > 0}">
    <div class="alert-box alert-warn">
      🔒 <strong>${systemClosedCount} ca bị hệ thống tự đóng</strong> đang chờ Admin giải quyết
      <a href="${pageContext.request.contextPath}/attendance?action=list&status=SYSTEM_CLOSED"
         style="margin-left:8px;color:#92400E;font-weight:750;font-size:12px">Xem ngay →</a>
    </div>
  </c:if>


  <%-- Filter row --%>
  <form method="get" action="${pageContext.request.contextPath}/attendance">
    <input type="hidden" name="action" value="list">
    <div class="filter-row">
      <div class="fi"><label>Từ ngày</label><input type="date" name="from" value="${filterFrom}"></div>
      <div class="fi"><label>Đến ngày</label><input type="date" name="to"   value="${filterTo}"></div>
      <div class="fi"><label>Nhân viên</label>
        <input type="hidden" name="accountId" id="hAccountId" value="${filterAcc}">
        <div class="cdd" id="cddAccountId">
          <div class="cdd-btn" onclick="toggleCdd('cddAccountId')">
            <span class="cdd-label"><c:choose><c:when test="${empty filterAcc}">— Tất cả —</c:when><c:otherwise><c:forEach var="s" items="${allStaff}"><c:if test="${filterAcc==s.accountId.toString()}">${s.fullName}</c:if></c:forEach></c:otherwise></c:choose></span>
            <span class="cdd-arrow">▼</span>
          </div>
          <div class="cdd-menu">
            <div class="cdd-opt ${empty filterAcc?'active':''}" data-val="" onclick="pickCdd('cddAccountId','hAccountId',this,false)">— Tất cả —</div>
            <c:forEach var="s" items="${allStaff}">
              <div class="cdd-opt ${filterAcc==s.accountId.toString()?'active':''}" data-val="${s.accountId}" onclick="pickCdd('cddAccountId','hAccountId',this,false)">${s.fullName}</div>
            </c:forEach>
          </div>
        </div>
      </div>
      <div class="fi"><label>Trạng thái</label>
        <input type="hidden" name="status" id="hStatus" value="${filterStatus}">
        <div class="cdd" id="cddStatus">
          <div class="cdd-btn" onclick="toggleCdd('cddStatus')">
            <span class="cdd-label"><c:choose>
              <c:when test="${filterStatus=='ON_TIME'}">✅ Đúng giờ</c:when>
              <c:when test="${filterStatus=='LATE'}">⚠️ Trễ</c:when>
              <c:when test="${filterStatus=='LATE_UNEXCUSED'}">⏳ Trễ chờ duyệt</c:when>
              <c:when test="${filterStatus=='SYSTEM_CLOSED'}">🔒 Hệ thống tự đóng</c:when>
              <c:when test="${filterStatus=='FORCE_CHECKOUT'}">🔐 Admin đóng</c:when>
              <c:when test="${filterStatus=='ABSENT'}">❌ Vắng</c:when>
              <c:otherwise>— Tất cả —</c:otherwise>
            </c:choose></span>
            <span class="cdd-arrow">▼</span>
          </div>
          <div class="cdd-menu">
            <div class="cdd-opt ${empty filterStatus?'active':''}" data-val="" onclick="pickCdd('cddStatus','hStatus',this,false)">— Tất cả —</div>
            <div class="cdd-opt ${filterStatus=='ON_TIME'?'active':''}" data-val="ON_TIME" onclick="pickCdd('cddStatus','hStatus',this,false)">✅ Đúng giờ</div>
            <div class="cdd-opt ${filterStatus=='LATE'?'active':''}" data-val="LATE" onclick="pickCdd('cddStatus','hStatus',this,false)">⚠️ Trễ</div>
            <div class="cdd-opt ${filterStatus=='LATE_UNEXCUSED'?'active':''}" data-val="LATE_UNEXCUSED" onclick="pickCdd('cddStatus','hStatus',this,false)">⏳ Trễ chờ duyệt</div>
            <div class="cdd-opt ${filterStatus=='SYSTEM_CLOSED'?'active':''}" data-val="SYSTEM_CLOSED" onclick="pickCdd('cddStatus','hStatus',this,false)">🔒 Hệ thống tự đóng</div>
            <div class="cdd-opt ${filterStatus=='FORCE_CHECKOUT'?'active':''}" data-val="FORCE_CHECKOUT" onclick="pickCdd('cddStatus','hStatus',this,false)">🔐 Admin đóng</div>
            <div class="cdd-opt ${filterStatus=='ABSENT'?'active':''}" data-val="ABSENT" onclick="pickCdd('cddStatus','hStatus',this,false)">❌ Vắng</div>
          </div>
        </div>
      </div>
      <button type="submit" class="btn-filter">🔍 Lọc</button>
      <a href="${pageContext.request.contextPath}/attendance?action=list" class="btn-reset">↺ Reset</a>
    </div>
  </form>

  <%-- Quick filter pills --%>
  <div class="qfilter-row">
    <a href="${pageContext.request.contextPath}/attendance?action=list" class="qf ${empty filterStatus?'active':''}">Tất cả</a>
    <a href="${pageContext.request.contextPath}/attendance?action=list&status=SYSTEM_CLOSED"  class="qf qf-red ${filterStatus=='SYSTEM_CLOSED'?'active':''}">🔒 Chờ giải trình (${systemClosedCount})</a>
    <a href="${pageContext.request.contextPath}/attendance?action=list&status=LATE_UNEXCUSED" class="qf qf-warn ${filterStatus=='LATE_UNEXCUSED'?'active':''}">⏰ Trễ (${lateUnexcusedCount})</a>
    <a href="${pageContext.request.contextPath}/attendance?action=list&status=LATE"           class="qf ${filterStatus=='LATE'?'active':''}">⚠️ Trễ</a>
    <a href="${pageContext.request.contextPath}/attendance?action=list&status=ABSENT"         class="qf ${filterStatus=='ABSENT'?'active':''}">❌ Vắng</a>
  </div>

  <%-- Table --%>
  <div class="table-card">
    <div class="table-card-head">
      <h2>📋 Lịch sử điểm danh</h2>
      <span class="tc-sub">${fn:length(attendanceList)} bản ghi</span>
    </div>
    <c:choose>
      <c:when test="${empty attendanceList}">
        <div class="empty-box"><div style="font-size:36px;margin-bottom:10px">📋</div><p>Không có dữ liệu điểm danh.</p></div>
      </c:when>
      <c:otherwise>
        <table>
          <thead>
            <tr>
              <th>#</th><th>Nhân viên</th><th>Check-in</th><th>Check-out</th>
              <th>Giờ thực</th><th>Trễ</th><th>Phương thức</th>
              <th>Bàn giao két</th><th>Trạng thái</th><th>Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="att" items="${attendanceList}">
              <tr>
                <td style="color:var(--muted);font-size:12px">#${att.attendanceId}</td>
                <td>
                  <div style="display:flex;align-items:center">
                    <div class="staff-av">${fn:substring(att.staffName,0,1)}</div>
                    <strong>${att.staffName}</strong>
                  </div>
                </td>
                <td>
                  <div style="font-weight:750">${fn:substring(att.checkInTime.toString(),11,16)}</div>
                  <div style="font-size:11px;color:var(--muted)">${fn:substring(att.checkInTime.toString(),0,10)}</div>
                </td>
                <td>
                  <c:choose>
                    <c:when test="${not empty att.checkOutTime}">
                      <div style="font-weight:750">${fn:substring(att.checkOutTime.toString(),11,16)}</div>
                      <div style="font-size:11px;color:var(--muted)">${fn:substring(att.checkOutTime.toString(),0,10)}</div>
                    </c:when>
                    <c:otherwise><span style="color:var(--green);font-weight:750;font-size:12px">⏳ Đang làm</span></c:otherwise>
                  </c:choose>
                </td>
                <td style="font-weight:750">
                  <c:if test="${att.actualHours != null}"><fmt:formatNumber value="${att.actualHours}" pattern="0.0"/>h</c:if>
                  <c:if test="${att.actualHours == null}">—</c:if>
                </td>
                <td>
                  <c:choose>
                    <c:when test="${att.lateMinutes > 0}"><span class="badge badge-late">+${att.lateMinutes}p</span></c:when>
                    <c:otherwise><span class="badge badge-on-time">Đúng</span></c:otherwise>
                  </c:choose>
                </td>
                <td><span class="badge badge-method">${att.checkInMethod}</span></td>
                <td>
                  <c:choose>
                    <c:when test="${att.handoverCash != null and att.handoverCash > 0}">
                      <span style="font-size:12.5px;font-weight:750;color:var(--ink)">
                        <fmt:formatNumber value="${att.handoverCash}" type="number" maxFractionDigits="0"/>đ
                      </span>
                    </c:when>
                    <c:otherwise><span style="color:var(--muted);font-size:12px">—</span></c:otherwise>
                  </c:choose>
                </td>
                <td>
                  <c:choose>
                    <c:when test="${att.attendanceStatus == 'SYSTEM_CLOSED'}">
                      <span class="badge badge-system-closed">🔒 Hệ thống tự đóng</span>
                    </c:when>
                    <c:when test="${att.attendanceStatus == 'LATE_UNEXCUSED'}">
                      <span class="badge badge-warn">⏰ Trễ (đã ghi nhận)</span>
                    </c:when>
                    <c:when test="${att.attendanceStatus == 'FORCE_CHECKOUT'}">
                      <span class="badge badge-force">🔐 Admin đóng</span>
                    </c:when>
                    <c:when test="${att.attendanceStatus == 'ABSENT'}">
                      <span class="badge badge-absent">❌ Vắng</span>
                    </c:when>
                    <c:when test="${att.attendanceStatus == 'ON_TIME'}">
                      <span class="badge badge-on-time">✅ Đúng giờ</span>
                    </c:when>
                    <c:when test="${att.attendanceStatus == 'LATE' or att.attendanceStatus == 'LATE_EARLY'}">
                      <span class="badge badge-late">⚠️ Trễ</span>
                    </c:when>
                    <c:when test="${att.attendanceStatus == 'OVERTIME'}">
                      <span class="badge badge-overtime">🔵 OT</span>
                    </c:when>
                    <c:otherwise>
                      <span class="badge" style="background:#F1F5F9;color:#64748B">${att.attendanceStatus}</span>
                    </c:otherwise>
                  </c:choose>
                  <%-- Hiện note ngắn nếu có --%>
                  <c:if test="${not empty att.checkInNote}">
                    <div class="note-preview" title="${att.checkInNote}">${fn:substring(att.checkInNote,0,40)}${fn:length(att.checkInNote)>40?'…':''}</div>
                  </c:if>
                </td>
                <td>
                  <c:if test="${att.attendanceStatus == 'SYSTEM_CLOSED'}">
                    <button class="btn-sm btn-resolve"
                            onclick="openResolveModal(${att.attendanceId},'system','${fn:escapeXml(att.staffName)}','${fn:escapeXml(att.checkInNote)}')">
                      🔒 Giải quyết
                    </button>
                  </c:if>

                </td>
              </tr>
            </c:forEach>
          </tbody>
        </table>
      </c:otherwise>
    </c:choose>
  </div>
</div>
</div>

<%-- Modal giải quyết --%>
<div class="modal-overlay" id="resolveModal">
  <div class="modal">
    <div class="modal-head">
      <span class="modal-title" id="modalTitle">Giải quyết ca</span>
      <button class="modal-close" onclick="closeModal()">✕</button>
    </div>
    <div class="modal-body">
      <form id="resolveForm" method="post" action="${pageContext.request.contextPath}/attendance">
        <input type="hidden" name="attendanceId" id="resolveAttId">
        <input type="hidden" name="action"       id="resolveAction">
        <div class="mfg">
          <label>Ghi chú của nhân viên</label>
          <textarea id="staffNote" rows="3" readonly style="background:#F8FAFC;color:var(--muted);resize:none"></textarea>
        </div>
        <div class="mfg">
          <label>Quyết định của Admin</label>
          <input type="hidden" name="decision" id="resolveDecision" value="excuse">
          <div class="cdd" id="cddResolveDecision">
            <div class="cdd-btn" onclick="toggleCdd('cddResolveDecision')">
              <span class="cdd-label">✅ Chấp nhận — không phạt</span>
              <span class="cdd-arrow">▼</span>
            </div>
            <div class="cdd-menu">
              <div class="cdd-opt active" data-val="excuse" onclick="pickCdd('cddResolveDecision','resolveDecision',this,false)">✅ Chấp nhận — không phạt</div>
              <div class="cdd-opt" data-val="penalize" onclick="pickCdd('cddResolveDecision','resolveDecision',this,false)">❌ Phạt (50,000đ cố định)</div>
            </div>
          </div>
        </div>
        <div class="mfg">
          <label>Ghi chú Admin</label>
          <textarea name="adminNote" rows="2" placeholder="VD: Chấp nhận vì lý do hợp lý / Vi phạm lần 2..."></textarea>
        </div>
      </form>
    </div>
    <div class="modal-foot">
      <button class="btn-cancel" onclick="closeModal()">Hủy</button>
      <button class="btn-save" onclick="submitResolve()">💾 Xác nhận</button>
    </div>
  </div>
</div>

<script>
function toggleCdd(id){var w=document.getElementById(id),m=w.querySelector('.cdd-menu'),b=w.querySelector('.cdd-btn');var open=m.classList.contains('show');document.querySelectorAll('.cdd-menu.show').forEach(function(x){x.classList.remove('show');x.closest('.cdd').querySelector('.cdd-btn').classList.remove('open')});if(!open){m.classList.add('show');b.classList.add('open');var act=m.querySelector('.cdd-opt.active');if(act)act.scrollIntoView({block:'nearest'})}}
function pickCdd(wId,hId,el,autoSubmit){document.getElementById(hId).value=el.dataset.val;var w=document.getElementById(wId);w.querySelector('.cdd-label').textContent=el.textContent;w.querySelectorAll('.cdd-opt').forEach(function(o){o.classList.remove('active')});el.classList.add('active');w.querySelector('.cdd-menu').classList.remove('show');w.querySelector('.cdd-btn').classList.remove('open');if(autoSubmit){var f=w.closest('form');if(f)f.submit()}}
document.addEventListener('click',function(e){if(!e.target.closest('.cdd')){document.querySelectorAll('.cdd-menu.show').forEach(function(m){m.classList.remove('show');m.closest('.cdd').querySelector('.cdd-btn').classList.remove('open')})}});

const toast = document.getElementById('toast');
if (toast) setTimeout(()=>{toast.style.opacity='0';setTimeout(()=>toast.remove(),400)},3500);

function openResolveModal(attId, type, name, note) {
  // Chỉ dùng cho SYSTEM_CLOSED — trễ không cần duyệt nữa
  if (type !== 'system') return;
  document.getElementById('resolveAttId').value = attId;
  document.getElementById('resolveAction').value = 'resolve-system-closed';
  document.getElementById('modalTitle').textContent = '🔒 Giải quyết ca tự đóng — ' + name;
  document.getElementById('staffNote').value = note || '(Không có ghi chú)';
  document.getElementById('resolveModal').classList.add('open');
}
function closeModal() { document.getElementById('resolveModal').classList.remove('open'); }
function submitResolve() { document.getElementById('resolveForm').submit(); }
document.getElementById('resolveModal').addEventListener('click', function(e){
  if (e.target === this) closeModal();
});
</script>
</body></html>
