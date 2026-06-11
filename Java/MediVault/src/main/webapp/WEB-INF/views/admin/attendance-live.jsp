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
<title>Điểm danh trực tiếp — medicare</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--ink:#0B1628;--blue:#1558A8;--cyan:#3ABDE0;--surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;--green:#059669;--red:#DC2626;--amber:#F59E0B;--sidebar:232px;--radius:14px}
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
.logout-btn:hover{background:rgba(220,38,38,.2);color:var(--red)}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh}
.topbar{height:60px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-size:16px;font-weight:800;color:var(--ink)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.topbar-pill{display:inline-flex;align-items:center;gap:6px;padding:4px 12px;border-radius:20px;font-size:12.5px;font-weight:700}
.pill-green{background:#ECFDF5;color:var(--green)}.pill-blue{background:#EFF6FF;color:var(--blue)}
.tab-bar{display:flex;gap:4px;padding:0 26px;background:var(--white);border-bottom:1px solid var(--border)}
.tab{padding:12px 18px;font-size:13px;font-weight:600;color:var(--muted);text-decoration:none;border-bottom:2.5px solid transparent;transition:all .18s}
.tab:hover{color:var(--ink)}.tab.active{color:var(--blue);border-bottom-color:var(--blue)}
.content{padding:22px 26px;flex:1}
.summary-strip{display:grid;grid-template-columns:repeat(3,1fr);gap:12px;margin-bottom:20px}
.sum-card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);padding:14px 18px;display:flex;align-items:center;gap:12px}
.sum-icon{width:38px;height:38px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:16px}
.sum-ic-green{background:#ECFDF5}.sum-ic-blue{background:#EFF6FF}.sum-ic-amber{background:#FFFBEB}
.sum-num{font-size:22px;font-weight:900;line-height:1}.sum-lbl{font-size:11px;color:var(--muted);font-weight:600;text-transform:uppercase;letter-spacing:.5px;margin-top:2px}
/* Live cards */
.live-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:14px;margin-bottom:24px}
.live-card{background:linear-gradient(135deg,#ECFDF5,#F0FDF4);border:1.5px solid #A7F3D0;border-radius:var(--radius);padding:18px;position:relative;overflow:hidden}
.live-card::before{content:'';position:absolute;top:0;right:0;width:80px;height:80px;background:rgba(16,185,129,.08);border-radius:50%;transform:translate(20px,-20px)}
.lc-badge{display:inline-flex;align-items:center;gap:6px;background:#D1FAE5;color:#065F46;border-radius:20px;padding:3px 10px;font-size:11px;font-weight:800;margin-bottom:10px}
.lc-dot{width:7px;height:7px;border-radius:50%;background:#10B981;animation:pulse 1.4s infinite}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.3}}
.lc-name{font-size:16px;font-weight:900;color:var(--ink)}
.lc-role{font-size:12px;color:#6EE7B7;margin-top:2px}
.lc-timer{font-size:28px;font-weight:900;color:var(--green);font-variant-numeric:tabular-nums;letter-spacing:-1px;margin:10px 0 4px}
.lc-since{font-size:12px;color:#059669;font-weight:600}
.lc-meta{display:flex;gap:10px;margin-top:12px}
.lc-meta-item{flex:1;background:rgba(255,255,255,.7);border-radius:8px;padding:7px 10px}
.lc-meta-label{font-size:10px;color:#6EE7B7;font-weight:700;text-transform:uppercase}
.lc-meta-val{font-size:12px;font-weight:700;color:#065F46;margin-top:2px}
.lc-actions{margin-top:12px;display:flex;gap:6px}
.btn-force-out{flex:1;padding:7px 0;background:rgba(220,38,38,.1);border:1px solid rgba(220,38,38,.2);border-radius:8px;font-family:'Outfit',sans-serif;font-size:12px;font-weight:700;color:var(--red);cursor:pointer;transition:all .18s}
.btn-force-out:hover{background:rgba(220,38,38,.2)}
.btn-detail{padding:7px 14px;background:rgba(21,88,168,.1);border:1px solid rgba(21,88,168,.2);border-radius:8px;font-family:'Outfit',sans-serif;font-size:12px;font-weight:700;color:var(--blue);cursor:pointer;text-decoration:none;transition:all .18s}
.btn-detail:hover{background:rgba(21,88,168,.15)}
/* Lịch hôm nay */
.table-card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}
.table-card-head{padding:14px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
.table-card-head h2{font-size:14px;font-weight:800;color:var(--ink)}
table{width:100%;border-collapse:collapse}
thead th{padding:9px 16px;background:#F8FAFC;font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;border-bottom:1px solid var(--border)}
tbody td{padding:11px 16px;font-size:13px;border-bottom:1px solid #F1F5F9;vertical-align:middle}
tbody tr:last-child td{border-bottom:none}
.badge{display:inline-flex;align-items:center;gap:5px;padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:700}
.badge-working{background:#ECFDF5;color:#065F46}
.badge-scheduled{background:#EFF6FF;color:#1E40AF}
.badge-absent{background:#FEF2F2;color:#991B1B}
.badge-leave{background:#FEF3C7;color:#92400E}
.empty-box{padding:40px;text-align:center;color:var(--muted)}
.toast{position:fixed;top:20px;right:24px;padding:12px 20px;border-radius:11px;font-size:13px;font-weight:700;color:#fff;z-index:9999;display:flex;align-items:center;gap:8px;box-shadow:0 4px 20px rgba(0,0,0,.15);animation:slideIn .3s ease}
.toast-ok{background:#059669}.toast-err{background:#DC2626}
@keyframes slideIn{from{transform:translateX(60px);opacity:0}to{transform:translateX(0);opacity:1}}
</style></head>
<body>
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">
  <c:if test="${not empty param.msg}">
    <c:choose>
      <c:when test="${param.msg=='checked-out'}"><div class="toast toast-ok" id="toast">✅ Đã đóng ca nhân viên!</div></c:when>
      <c:otherwise><div class="toast toast-err" id="toast">❌ Có lỗi xảy ra!</div></c:otherwise>
    </c:choose>
  </c:if>
  <header class="topbar">
    <div style="font-size:15px">✅</div>
    <span class="topbar-title">Điểm danh</span>
    <div class="topbar-right">
      <span class="topbar-pill pill-green">🟢 ${workCount} đang làm việc</span>
      <span class="topbar-pill pill-blue">📋 ${fn:length(todaySchedules)} ca hôm nay</span>
    </div>
  </header>

  <div class="tab-bar">
    <a href="${pageContext.request.contextPath}/attendance?action=live"    class="tab active">🟢 Đang làm việc</a>
    <a href="${pageContext.request.contextPath}/attendance?action=list"    class="tab">📋 Lịch sử</a>
    <a href="${pageContext.request.contextPath}/attendance?action=monthly" class="tab">📊 Tổng hợp tháng</a>
  </div>

  <div class="content">
    <div class="summary-strip">
      <div class="sum-card"><div class="sum-icon sum-ic-green">🟢</div><div><div class="sum-num" style="color:var(--green)">${workCount}</div><div class="sum-lbl">Đang làm việc</div></div></div>
      <div class="sum-card"><div class="sum-icon sum-ic-blue">📋</div><div><div class="sum-num">${fn:length(todaySchedules)}</div><div class="sum-lbl">Ca hôm nay</div></div></div>
      <div class="sum-card"><div class="sum-icon sum-ic-amber">⚠️</div><div>
        <c:set var="absent" value="${fn:length(todaySchedules) - workCount}"/>
        <div class="sum-num" style="color:var(--amber)">${absent > 0 ? absent : 0}</div>
        <div class="sum-lbl">Chưa vào ca</div>
      </div></div>
    </div>

    <%-- Live cards --%>
    <c:choose>
      <c:when test="${not empty working}">
        <div class="live-grid">
          <c:forEach var="att" items="${working}">
            <div class="live-card">
              <div class="lc-badge"><span class="lc-dot"></span> Đang làm việc</div>
              <div class="lc-name">${att.staffName}</div>
              <div class="lc-role">${att.shiftTypeName != null ? att.shiftTypeName : 'Ca không theo lịch'}</div>
              <div class="lc-timer" data-checkin="${att.checkInTime}">--:--:--</div>
              <div class="lc-since">Từ ${fn:substring(att.checkInTime.toString(),11,16)}</div>
              <div class="lc-meta">
                <div class="lc-meta-item">
                  <div class="lc-meta-label">Check-in</div>
                  <div class="lc-meta-val">${fn:substring(att.checkInTime.toString(),11,16)}</div>
                </div>
                <div class="lc-meta-item">
                  <div class="lc-meta-label">Đến trễ</div>
                  <div class="lc-meta-val" style="${att.lateMinutes>0?'color:var(--red)':''}">
                    ${att.lateMinutes > 0 ? att.lateMinutes.concat(' phút') : 'Đúng giờ'}
                  </div>
                </div>
                <div class="lc-meta-item">
                  <div class="lc-meta-label">Phương thức</div>
                  <div class="lc-meta-val">${att.checkInMethod}</div>
                </div>
              </div>
              <div class="lc-actions">
                <form method="post" action="${pageContext.request.contextPath}/attendance" style="flex:1">
                  <input type="hidden" name="action" value="admin-checkout">
                  <input type="hidden" name="accountId" value="${att.accountId}">
                  <button type="submit" class="btn-force-out"
                          onclick="return confirm('Force checkout ${att.staffName}?')">
                    🔒 Đóng ca
                  </button>
                </form>
                <a href="${pageContext.request.contextPath}/attendance?action=list&accountId=${att.accountId}" class="btn-detail">📋 Lịch sử</a>
              </div>
            </div>
          </c:forEach>
        </div>
      </c:when>
      <c:otherwise>
        <div class="empty-box"><div style="font-size:44px;margin-bottom:12px">🌙</div><p style="font-size:13.5px">Không có nhân viên nào đang làm việc ngay lúc này.</p></div>
      </c:otherwise>
    </c:choose>

    <%-- Lịch hôm nay --%>
    <div class="table-card">
      <div class="table-card-head">
        <h2>📋 Lịch ca hôm nay</h2>
        <a href="${pageContext.request.contextPath}/shift-schedules" style="font-size:12px;color:var(--blue);text-decoration:none;font-weight:700">Quản lý lịch →</a>
      </div>
      <c:choose>
        <c:when test="${empty todaySchedules}">
          <div class="empty-box"><p>Chưa có lịch ca hôm nay.</p></div>
        </c:when>
        <c:otherwise>
          <table>
            <thead><tr>
              <th>Nhân viên</th><th>Ca</th><th>Giờ kế hoạch</th><th>Trạng thái</th>
            </tr></thead>
            <tbody>
              <c:forEach var="sc" items="${todaySchedules}">
                <tr>
                  <td style="font-weight:700">${sc.staffName}</td>
                  <td>${sc.shiftTypeName}</td>
                  <td>${fn:substring(sc.plannedStart.toString(),11,16)} – ${fn:substring(sc.plannedEnd.toString(),11,16)}</td>
                  <td>
                    <span class="badge
                      <c:choose>
                        <c:when test="${sc.status=='CONFIRMED'}">badge-working</c:when>
                        <c:when test="${sc.status=='ABSENT'}">badge-absent</c:when>
                        <c:when test="${sc.status=='ON_LEAVE'}">badge-leave</c:when>
                        <c:otherwise>badge-scheduled</c:otherwise>
                      </c:choose>">
                      <c:choose>
                        <c:when test="${sc.status=='CONFIRMED'}">✅ Đã vào ca</c:when>
                        <c:when test="${sc.status=='ABSENT'}">❌ Vắng mặt</c:when>
                        <c:when test="${sc.status=='ON_LEAVE'}">🏖️ Nghỉ phép</c:when>
                        <c:otherwise>⏳ Chưa vào</c:otherwise>
                      </c:choose>
                    </span>
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

<script>
const toast = document.getElementById('toast');
if (toast) setTimeout(()=>{toast.style.opacity='0';setTimeout(()=>toast.remove(),400)},3500);

function calcDur(startStr) {
  const s = new Date(startStr.replace('T',' '));
  const diff = Math.floor((new Date()-s)/1000);
  if(isNaN(diff)||diff<0) return '--:--:--';
  return [Math.floor(diff/3600),Math.floor((diff%3600)/60),diff%60]
    .map(v=>String(v).padStart(2,'0')).join(':');
}
document.querySelectorAll('.lc-timer[data-checkin]').forEach(el => {
  const tick = () => { el.textContent = calcDur(el.dataset.checkin); };
  tick(); setInterval(tick, 1000);
});
// Auto reload mỗi 60 giây để cập nhật live
setTimeout(() => location.reload(), 60000);
</script>
</body></html>
