<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<% String activeNav = "attendance"; %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length()>=2 ? fullName.substring(0,1).toUpperCase()+fullName.substring(1,2).toUpperCase() : fullName.toUpperCase();
%>
<!DOCTYPE html><html lang="vi"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Lịch sử điểm danh — medicare</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--ink:#0B1628;--blue:#1558A8;--cyan:#3ABDE0;--surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;--green:#059669;--red:#DC2626;--sidebar:232px;--radius:14px}
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
.tab{padding:12px 18px;font-size:13px;font-weight:600;color:var(--muted);text-decoration:none;border-bottom:2.5px solid transparent;transition:all .18s}
.tab:hover{color:var(--ink)}.tab.active{color:var(--blue);border-bottom-color:var(--blue)}
.content{padding:22px 26px;flex:1}
/* Filter */
.filter-row{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);padding:16px 20px;margin-bottom:18px;display:flex;gap:12px;align-items:flex-end;flex-wrap:wrap}
.fi{display:flex;flex-direction:column;gap:5px}
.fi label{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.fi input,.fi select{border:1.5px solid var(--border);border-radius:8px;padding:7px 11px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);background:var(--surface);outline:none}
.fi input:focus,.fi select:focus{border-color:var(--blue);background:#fff}
.btn-filter{padding:8px 20px;background:var(--blue);color:#fff;border:none;border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer}
.table-card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}
.table-card-head{padding:14px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
.table-card-head h2{font-size:14px;font-weight:800;color:var(--ink)}
.tc-sub{font-size:12px;color:var(--muted)}
table{width:100%;border-collapse:collapse}
thead th{padding:9px 16px;background:#F8FAFC;font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;border-bottom:1px solid var(--border);white-space:nowrap}
tbody td{padding:11px 16px;font-size:13px;border-bottom:1px solid #F1F5F9;vertical-align:middle}
tbody tr:last-child td{border-bottom:none}tbody tr:hover td{background:#F7FBFF}
.staff-av{width:28px;height:28px;border-radius:7px;background:linear-gradient(135deg,var(--blue),#4F81D9);color:#fff;display:inline-flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;margin-right:7px}
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 9px;border-radius:20px;font-size:11px;font-weight:700}
.badge-ok{background:#ECFDF5;color:#065F46}.badge-late{background:#FEF3C7;color:#92400E}
.badge-method{background:#EFF6FF;color:#1558A8;font-size:10px}
.empty-box{padding:40px;text-align:center;color:var(--muted)}
</style></head>
<body>
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>
<div class="main">
  <header class="topbar"><div style="font-size:15px">✅</div><span class="topbar-title">Điểm danh</span></header>
  <div class="tab-bar">
    <a href="${pageContext.request.contextPath}/attendance?action=live"    class="tab">🟢 Đang làm việc</a>
    <a href="${pageContext.request.contextPath}/attendance?action=list"    class="tab active">📋 Lịch sử</a>
    <a href="${pageContext.request.contextPath}/attendance?action=monthly" class="tab">📊 Tổng hợp tháng</a>
  </div>
  <div class="content">
    <form method="get" action="${pageContext.request.contextPath}/attendance">
      <input type="hidden" name="action" value="list">
      <div class="filter-row">
        <div class="fi"><label>Từ ngày</label><input type="date" name="from" value="${filterFrom}"></div>
        <div class="fi"><label>Đến ngày</label><input type="date" name="to" value="${filterTo}"></div>
        <div class="fi"><label>Nhân viên</label>
          <select name="accountId">
            <option value="">-- Tất cả --</option>
            <c:forEach var="s" items="${allStaff}">
              <option value="${s.accountId}" ${filterAcc==s.accountId?'selected':''}>${s.fullName}</option>
            </c:forEach>
          </select>
        </div>
        <button type="submit" class="btn-filter">🔍 Lọc</button>
      </div>
    </form>
    <div class="table-card">
      <div class="table-card-head"><h2>📋 Lịch sử điểm danh</h2><span class="tc-sub">${fn:length(attendanceList)} bản ghi</span></div>
      <c:choose>
        <c:when test="${empty attendanceList}">
          <div class="empty-box"><div style="font-size:36px;margin-bottom:10px">📋</div><p>Không có dữ liệu điểm danh.</p></div>
        </c:when>
        <c:otherwise>
          <table>
            <thead><tr><th>#</th><th>Nhân viên</th><th>Check-in</th><th>Check-out</th><th>Giờ thực</th><th>Trễ</th><th>OT</th><th>Phương thức</th></tr></thead>
            <tbody>
              <c:forEach var="att" items="${attendanceList}">
                <tr>
                  <td style="color:var(--muted);font-size:12px">#${att.attendanceId}</td>
                  <td><span class="staff-av">${fn:substring(att.staffName,0,1)}</span><strong>${att.staffName}</strong></td>
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
                      <c:otherwise><span class="badge badge-ok">Đúng</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td>${att.overtimeHours > 0 ? att.overtimeHours.concat('h') : '—'}</td>
                  <td><span class="badge badge-method">${att.checkInMethod}</span></td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </c:otherwise>
      </c:choose>
    </div>
  </div>
</div>
</body></html>
