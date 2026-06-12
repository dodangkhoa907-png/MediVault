<%@ page contentType="text/html;charset=UTF-8" language="java" %>
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
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Lịch sử điểm danh — MediVault</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--ink:#0B1628;--blue:#1558A8;--cyan:#3ABDE0;--surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;--green:#059669;--red:#DC2626;--amber:#D97706;--purple:#7C3AED;--indigo:#6366F1;--sidebar:232px;--radius:14px}
html,body{height:100%;font-family:'Outfit',sans-serif;background:var(--surface);color:var(--ink)}body{display:flex}
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06)}
.logo-icon{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:16px}
.logo-text{font-size:16px;font-weight:800;color:#fff}.logo-text span{color:var(--cyan)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:12px 0 4px}.nav-label{font-size:9px;font-weight:700;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:500;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.14);font-weight:600}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--cyan);border-radius:2px}
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06)}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08)}
.user-av{width:34px;height:34px;border-radius:9px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.user-name{font-size:12.5px;font-weight:600;color:#fff;max-width:110px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.user-role{font-size:10px;color:rgba(255,255,255,.35);margin-top:1px}
.logout-btn{margin-left:auto;width:28px;height:28px;border-radius:8px;background:rgba(220,38,38,.12);border:none;display:flex;align-items:center;justify-content:center;color:rgba(220,38,38,.7);font-size:13px;cursor:pointer;text-decoration:none}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh}
.topbar{height:60px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-size:16px;font-weight:800;color:var(--ink)}
.tab-bar{display:flex;gap:4px;padding:0 26px;background:var(--white);border-bottom:1px solid var(--border)}
.tab{padding:12px 18px;font-size:13px;font-weight:600;color:var(--muted);text-decoration:none;border-bottom:2.5px solid transparent;transition:all .18s;position:relative}
.tab:hover{color:var(--ink)}.tab.active{color:var(--blue);border-bottom-color:var(--blue)}
.tab-badge{position:absolute;top:8px;right:4px;background:var(--red);color:#fff;font-size:10px;font-weight:700;min-width:16px;height:16px;border-radius:8px;display:inline-flex;align-items:center;justify-content:center;padding:0 4px}
.content{padding:22px 26px;flex:1}
/* Alerts */
.alert-box{border-radius:10px;padding:12px 16px;margin-bottom:16px;display:flex;align-items:center;gap:10px;font-size:13px;font-weight:600}
.alert-warn{background:#FFFBEB;border:1.5px solid #FDE68A;color:#92400E}
.alert-info{background:#EFF6FF;border:1.5px solid #BFDBFE;color:#1558A8}
/* Filter */
.filter-row{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);padding:14px 20px;margin-bottom:16px;display:flex;gap:10px;align-items:flex-end;flex-wrap:wrap}
.fi{display:flex;flex-direction:column;gap:4px}
.fi label{font-size:10px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.fi input,.fi select{border:1.5px solid var(--border);border-radius:8px;padding:7px 10px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);background:var(--surface);outline:none;height:34px}
.fi input:focus,.fi select:focus{border-color:var(--blue);background:#fff}
.btn-filter{padding:7px 18px;background:var(--blue);color:#fff;border:none;border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;height:34px}
.btn-reset{padding:7px 12px;background:var(--surface);color:var(--muted);border:1.5px solid var(--border);border-radius:8px;font-size:13px;font-weight:600;cursor:pointer;text-decoration:none;display:inline-flex;align-items:center;height:34px}
/* Quick filter pills */
.qfilter-row{display:flex;gap:8px;margin-bottom:14px;flex-wrap:wrap}
.qf{padding:5px 12px;border-radius:20px;font-size:12px;font-weight:600;text-decoration:none;border:1.5px solid var(--border);color:var(--muted);background:var(--white);transition:all .15s}
.qf:hover{border-color:var(--blue);color:var(--blue)}
.qf.active{background:var(--blue);color:#fff;border-color:var(--blue)}
.qf-warn.active{background:#D97706;border-color:#D97706;color:#fff}
.qf-red.active{background:#DC2626;border-color:#DC2626;color:#fff}
/* Table */
.table-card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}
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
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 8px;border-radius:20px;font-size:11px;font-weight:700;white-space:nowrap}
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
.btn-sm{display:inline-flex;align-items:center;gap:4px;padding:4px 10px;border-radius:7px;font-family:'Outfit',sans-serif;font-size:11.5px;font-weight:700;cursor:pointer;border:none;text-decoration:none;transition:all .15s}
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
.mfg label{font-size:10.5px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.mfg textarea,.mfg select,.mfg input{border:1.5px solid var(--border);border-radius:8px;padding:8px 11px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);background:var(--surface);outline:none;width:100%}
.mfg textarea:focus,.mfg select:focus{border-color:var(--blue);background:#fff}
.modal-foot{padding:12px 20px;border-top:1px solid var(--border);display:flex;justify-content:flex-end;gap:8px}
.btn-cancel{padding:8px 16px;background:var(--surface);color:var(--muted);border:1.5px solid var(--border);border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;cursor:pointer}
.btn-save{padding:8px 20px;background:var(--blue);color:#fff;border:none;border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer}
.btn-penalize{background:#DC2626;color:#fff;border:none;border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;padding:8px 16px}
.empty-box{padding:40px;text-align:center;color:var(--muted)}
.toast{position:fixed;top:18px;right:22px;padding:11px 18px;border-radius:10px;font-size:13px;font-weight:700;color:#fff;z-index:999;display:flex;align-items:center;gap:8px;box-shadow:0 4px 18px rgba(0,0,0,.15);animation:slideIn .3s ease}
.toast-ok{background:#059669}.toast-err{background:#DC2626}.toast-info{background:#1558A8}
@keyframes slideIn{from{transform:translateX(80px);opacity:0}to{transform:translateX(0);opacity:1}}
/* Note preview */
.note-preview{font-size:11.5px;color:var(--muted);max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;cursor:pointer}
.note-preview:hover{color:var(--ink)}
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
         style="margin-left:8px;color:#92400E;font-weight:700;font-size:12px">Xem ngay →</a>
    </div>
  </c:if>


  <%-- Filter row --%>
  <form method="get" action="${pageContext.request.contextPath}/attendance">
    <input type="hidden" name="action" value="list">
    <div class="filter-row">
      <div class="fi"><label>Từ ngày</label><input type="date" name="from" value="${filterFrom}"></div>
      <div class="fi"><label>Đến ngày</label><input type="date" name="to"   value="${filterTo}"></div>
      <div class="fi"><label>Nhân viên</label>
        <select name="accountId">
          <option value="">— Tất cả —</option>
          <c:forEach var="s" items="${allStaff}">
            <option value="${s.accountId}" ${filterAcc==s.accountId.toString()?'selected':''}>${s.fullName}</option>
          </c:forEach>
        </select>
      </div>
      <div class="fi"><label>Trạng thái</label>
        <select name="status">
          <option value="">— Tất cả —</option>
          <option value="ON_TIME"        ${filterStatus=='ON_TIME'?'selected':''}>✅ Đúng giờ</option>
          <option value="LATE"           ${filterStatus=='LATE'?'selected':''}>⚠️ Trễ</option>
          <option value="LATE_UNEXCUSED" ${filterStatus=='LATE_UNEXCUSED'?'selected':''}>⏳ Trễ chờ duyệt</option>
          <option value="SYSTEM_CLOSED"  ${filterStatus=='SYSTEM_CLOSED'?'selected':''}>🔒 Hệ thống tự đóng</option>
          <option value="FORCE_CHECKOUT" ${filterStatus=='FORCE_CHECKOUT'?'selected':''}>🔐 Admin đóng</option>
          <option value="ABSENT"         ${filterStatus=='ABSENT'?'selected':''}>❌ Vắng</option>
        </select>
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
                  <div style="font-weight:600">${fn:substring(att.checkInTime.toString(),11,16)}</div>
                  <div style="font-size:11px;color:var(--muted)">${fn:substring(att.checkInTime.toString(),0,10)}</div>
                </td>
                <td>
                  <c:choose>
                    <c:when test="${not empty att.checkOutTime}">
                      <div style="font-weight:600">${fn:substring(att.checkOutTime.toString(),11,16)}</div>
                      <div style="font-size:11px;color:var(--muted)">${fn:substring(att.checkOutTime.toString(),0,10)}</div>
                    </c:when>
                    <c:otherwise><span style="color:var(--green);font-weight:700;font-size:12px">⏳ Đang làm</span></c:otherwise>
                  </c:choose>
                </td>
                <td style="font-weight:700">
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
                      <span style="font-size:12.5px;font-weight:700;color:var(--ink)">
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
          <select name="decision" id="resolveDecision">
            <option value="excuse">✅ Chấp nhận — không phạt</option>
            <option value="penalize">❌ Phạt (50,000đ cố định)</option>
          </select>
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
