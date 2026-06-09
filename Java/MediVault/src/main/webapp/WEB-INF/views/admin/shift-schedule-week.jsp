<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    com.medivault.entity.Account acc = (com.medivault.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length()>=2 ? fullName.substring(0,1).toUpperCase()+fullName.substring(1,2).toUpperCase() : fullName.toUpperCase();
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Lịch ca tuần — MediVault</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;--surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;--green:#059669;--red:#DC2626;--amber:#F59E0B;--sidebar:232px;--radius:14px}
html,body{height:100%;font-family:'Outfit',sans-serif;background:var(--surface);color:var(--ink)}
body{display:flex}
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06)}
.logo-icon{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:16px}
.logo-text{font-size:16px;font-weight:800;color:#fff}.logo-text span{color:var(--cyan)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:12px 0 4px}
.nav-label{font-size:9px;font-weight:700;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:500;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.14);font-weight:600}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--cyan);border-radius:2px}
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06)}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08)}
.user-av{width:34px;height:34px;border-radius:9px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.user-name{font-size:12.5px;font-weight:600;color:#fff;max-width:110px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.user-role{font-size:10px;color:rgba(255,255,255,.35);margin-top:1px}
.logout-btn{margin-left:auto;width:28px;height:28px;border-radius:8px;background:rgba(220,38,38,.12);border:none;display:flex;align-items:center;justify-content:center;color:rgba(220,38,38,.7);font-size:13px;cursor:pointer;text-decoration:none;transition:all .18s}
.logout-btn:hover{background:rgba(220,38,38,.2);color:var(--red)}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh}
.topbar{height:60px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-size:16px;font-weight:800;color:var(--ink)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.topbar-pill{display:inline-flex;align-items:center;gap:6px;padding:4px 12px;border-radius:20px;font-size:12.5px;font-weight:700}
.pill-blue{background:#EFF6FF;color:var(--blue)}
.btn-primary{padding:7px 16px;background:var(--blue);color:#fff;border:none;border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;text-decoration:none;display:inline-flex;align-items:center;gap:6px;transition:background .18s}
.btn-primary:hover{background:#0D3F85}
.content{padding:22px 26px;flex:1}

/* Toast */
.toast{position:fixed;top:20px;right:24px;padding:12px 20px;border-radius:11px;font-size:13px;font-weight:700;color:#fff;z-index:9999;display:flex;align-items:center;gap:8px;box-shadow:0 4px 20px rgba(0,0,0,.15);animation:slideIn .3s ease}
.toast-ok{background:#059669}.toast-err{background:#DC2626}.toast-info{background:#1558A8}
@keyframes slideIn{from{transform:translateX(60px);opacity:0}to{transform:translateX(0);opacity:1}}

/* Week nav */
.week-nav{display:flex;align-items:center;gap:12px;margin-bottom:20px}
.week-title{font-size:15px;font-weight:800;color:var(--ink)}
.week-sub{font-size:12px;color:var(--muted)}
.btn-nav{padding:6px 14px;border:1.5px solid var(--border);border-radius:8px;background:var(--white);font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;color:var(--ink);cursor:pointer;text-decoration:none;transition:all .18s}
.btn-nav:hover{border-color:var(--blue);color:var(--blue)}

/* Week grid */
.week-grid{display:grid;grid-template-columns:repeat(7,1fr);gap:8px;margin-bottom:20px}
.day-col{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden;min-height:160px}
.day-col.today{border-color:var(--blue);box-shadow:0 0 0 2px rgba(21,88,168,.12)}
.day-head{padding:10px 12px;border-bottom:1px solid var(--border);text-align:center}
.day-name{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.day-date{font-size:18px;font-weight:900;color:var(--ink);margin-top:2px}
.day-col.today .day-date{color:var(--blue)}
.day-body{padding:8px}
.shift-chip{padding:6px 8px;border-radius:8px;margin-bottom:5px;font-size:11.5px;cursor:pointer;transition:all .15s;position:relative}
.chip-morning{background:#EFF6FF;border:1px solid #BFDBFE}
.chip-afternoon{background:#FFF7ED;border:1px solid #FED7AA}
.chip-night{background:#F5F3FF;border:1px solid #DDD6FE}
.chip-name{font-weight:700;color:var(--ink);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.chip-time{font-size:10.5px;color:var(--muted);margin-top:2px}
.chip-status{display:inline-flex;align-items:center;gap:3px;font-size:10px;font-weight:700;margin-top:3px;padding:1px 6px;border-radius:10px}
.st-scheduled{background:#DBEAFE;color:#1E40AF}
.st-confirmed{background:#D1FAE5;color:#065F46}
.st-absent{background:#FEE2E2;color:#991B1B}
.st-leave{background:#FEF3C7;color:#92400E}
.chip-cancel{position:absolute;top:4px;right:4px;width:16px;height:16px;border-radius:50%;background:rgba(220,38,38,.1);border:none;color:var(--red);font-size:9px;cursor:pointer;display:none;align-items:center;justify-content:center}
.shift-chip:hover .chip-cancel{display:flex}
.day-add{display:flex;align-items:center;justify-content:center;padding:8px;color:var(--muted);font-size:11px;border:1.5px dashed var(--border);border-radius:8px;cursor:pointer;transition:all .18s;text-decoration:none;margin-top:4px}
.day-add:hover{border-color:var(--blue);color:var(--blue);background:#EFF6FF}
.empty-day{color:var(--muted);font-size:11px;text-align:center;padding:20px 0}

/* Form panel */
.form-card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden;margin-bottom:20px}
.form-head{padding:14px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;gap:8px}
.form-head h2{font-size:14px;font-weight:800;color:var(--ink)}
.form-body{padding:18px 20px}
.form-grid{display:grid;grid-template-columns:1fr 1fr 1fr;gap:12px}
.fg{display:flex;flex-direction:column;gap:5px}
.fg label{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.fg select,.fg input{border:1.5px solid var(--border);border-radius:8px;padding:8px 11px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);background:var(--surface);outline:none;transition:border .18s}
.fg select:focus,.fg input:focus{border-color:var(--blue);background:#fff}
.fg small{font-size:11px;color:var(--muted)}
.form-actions{display:flex;gap:10px;margin-top:16px;align-items:center}
.btn-submit{padding:9px 24px;background:var(--blue);color:#fff;border:none;border-radius:9px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;transition:background .18s}
.btn-submit:hover{background:#0D3F85}
.btn-ghost{padding:9px 16px;background:transparent;border:1.5px solid var(--border);border-radius:9px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;color:var(--muted);cursor:pointer;text-decoration:none;transition:all .18s}
.btn-ghost:hover{border-color:var(--red);color:var(--red)}
</style>
</head>
<body>
<aside class="sidebar">
  <div class="sidebar-logo">
    <div class="logo-icon">💊</div>
    <div><div class="logo-text">Medi<span>Vault</span></div><div class="logo-sub">Admin Console</div></div>
  </div>
  <nav class="nav-section">
    <div class="nav-label">Tổng quan</div>
    <a href="${pageContext.request.contextPath}/dashboard" class="nav-item">🏠 Trang chủ</a>
  </nav>
  <nav class="nav-section">
    <div class="nav-label">Quản lý</div>
    <a href="${pageContext.request.contextPath}/accounts"         class="nav-item">👤 Tài khoản</a>
    <a href="${pageContext.request.contextPath}/shifts"           class="nav-item">🕐 Ca làm việc</a>
    <a href="${pageContext.request.contextPath}/shift-schedules"  class="nav-item active">📅 Lịch ca</a>
    <a href="${pageContext.request.contextPath}/attendance"       class="nav-item">✅ Điểm danh</a>
    <a href="${pageContext.request.contextPath}/leave-requests"   class="nav-item">🏖️ Nghỉ phép
      <c:if test="${pendingLeaveCount > 0}"><span style="margin-left:auto;background:#DC2626;color:#fff;border-radius:10px;padding:1px 7px;font-size:10px">${pendingLeaveCount}</span></c:if>
    </a>
    <a href="${pageContext.request.contextPath}/payroll"          class="nav-item">💰 Bảng lương</a>
    <a href="${pageContext.request.contextPath}/medicines"        class="nav-item">💊 Kho thuốc</a>
    <a href="${pageContext.request.contextPath}/invoices"         class="nav-item">🧾 Hóa đơn</a>
  </nav>
  <nav class="nav-section">
    <div class="nav-label">Phân tích</div>
    <a href="${pageContext.request.contextPath}/audit-logs" class="nav-item">📋 Nhật ký</a>
    <a href="${pageContext.request.contextPath}/reports"    class="nav-item">📊 Báo cáo</a>
  </nav>
  <div class="sidebar-footer">
    <div class="sidebar-user">
      <div class="user-av"><%= initials %></div>
      <div><div class="user-name"><%= fullName %></div><div class="user-role">Admin</div></div>
      <a href="${pageContext.request.contextPath}/logout" class="logout-btn">⏻</a>
    </div>
  </div>
</aside>

<div class="main">
  <c:if test="${not empty param.msg}">
    <c:choose>
      <c:when test="${param.msg=='created'}"><div class="toast toast-ok" id="toast">✅ Đã xếp ${param.count} lịch ca!<c:if test="${param.skip > 0}"> (bỏ qua ${param.skip} đã tồn tại)</c:if></div></c:when>
      <c:when test="${param.msg=='cancelled'}"><div class="toast toast-info" id="toast">🗑️ Đã hủy lịch ca.</div></c:when>
      <c:when test="${param.msg=='invalid'}"><div class="toast toast-err" id="toast">❌ Dữ liệu không hợp lệ!</div></c:when>
      <c:otherwise><div class="toast toast-err" id="toast">⚠️ Có lỗi xảy ra!</div></c:otherwise>
    </c:choose>
  </c:if>

  <header class="topbar">
    <div style="width:34px;height:34px;border-radius:9px;background:linear-gradient(135deg,rgba(21,88,168,.12),rgba(58,189,224,.12));display:flex;align-items:center;justify-content:center;font-size:15px">📅</div>
    <span class="topbar-title">Lịch ca làm việc</span>
    <div class="topbar-right">
      <span class="topbar-pill pill-blue">${fn:length(schedules)} ca tuần này</span>
      <a href="${pageContext.request.contextPath}/shift-schedules?action=new" class="btn-primary">➕ Xếp ca mới</a>
    </div>
  </header>

  <div class="content">
    <%-- Form xếp ca nhanh --%>
    <div class="form-card">
      <div class="form-head"><span>🗓️</span><h2>Xếp ca nhanh</h2></div>
      <div class="form-body">
        <form method="post" action="${pageContext.request.contextPath}/shift-schedules">
          <input type="hidden" name="action" value="create">
          <div class="form-grid">
            <div class="fg">
              <label>Nhân viên</label>
              <select name="accountId" required>
                <option value="">-- Chọn --</option>
                <c:forEach var="s" items="${allStaff}">
                  <option value="${s.accountId}">${s.fullName}</option>
                </c:forEach>
              </select>
            </div>
            <div class="fg">
              <label>Loại ca</label>
              <select name="shiftTypeId" required>
                <option value="">-- Chọn --</option>
                <c:forEach var="st" items="${shiftTypes}">
                  <option value="${st.shiftTypeId}">${st.name} (${st.startHour}:00–${st.endHour}:00)</option>
                </c:forEach>
              </select>
            </div>
            <div class="fg">
              <label>Ngày làm</label>
              <input type="date" name="dateFrom" value="${today}" required>
              <small>Để xếp nhiều ngày, dùng nút "Xếp ca mới"</small>
            </div>
          </div>
          <div class="form-actions">
            <button type="submit" class="btn-submit">📅 Xếp ca</button>
            <a href="${pageContext.request.contextPath}/shift-schedules?action=new" class="btn-ghost">Xếp nhiều ngày →</a>
          </div>
        </form>
      </div>
    </div>

    <%-- Week nav --%>
    <div class="week-nav">
      <div class="week-title">📅 Tuần ${weekStart} → ${weekEnd}</div>
      <span class="week-sub">Nhấn vào ca để xem chi tiết | ✕ để hủy</span>
    </div>

    <%-- 7-day grid --%>
    <div class="week-grid">
      <c:forEach begin="0" end="6" var="i">
        <c:set var="dayDate" value="${weekStart.plusDays(i)}"/>
        <c:set var="isToday" value="${dayDate.equals(today)}"/>
        <div class="day-col ${isToday ? 'today' : ''}">
          <div class="day-head">
            <div class="day-name">
              <c:choose>
                <c:when test="${i==0}">T2</c:when><c:when test="${i==1}">T3</c:when>
                <c:when test="${i==2}">T4</c:when><c:when test="${i==3}">T5</c:when>
                <c:when test="${i==4}">T6</c:when><c:when test="${i==5}">T7</c:when>
                <c:otherwise>CN</c:otherwise>
              </c:choose>
            </div>
            <div class="day-date">${dayDate.dayOfMonth}</div>
          </div>
          <div class="day-body">
            <c:set var="hasShift" value="false"/>
            <c:forEach var="sc" items="${schedules}">
              <c:if test="${sc.workDate.equals(dayDate)}">
                <c:set var="hasShift" value="true"/>
                <c:set var="chipClass">
                  <c:choose>
                    <c:when test="${sc.startHour < 12}">chip-morning</c:when>
                    <c:when test="${sc.startHour < 20}">chip-afternoon</c:when>
                    <c:otherwise>chip-night</c:otherwise>
                  </c:choose>
                </c:set>
                <div class="shift-chip ${chipClass}">
                  <div class="chip-name">${sc.staffName}</div>
                  <div class="chip-time">${sc.shiftTypeName}</div>
                  <div class="chip-status
                    <c:choose>
                      <c:when test="${sc.status=='CONFIRMED'}">st-confirmed</c:when>
                      <c:when test="${sc.status=='ABSENT'}">st-absent</c:when>
                      <c:when test="${sc.status=='ON_LEAVE'}">st-leave</c:when>
                      <c:otherwise>st-scheduled</c:otherwise>
                    </c:choose>
                  ">
                    <c:choose>
                      <c:when test="${sc.status=='CONFIRMED'}">✅ Đúng giờ</c:when>
                      <c:when test="${sc.status=='ABSENT'}">❌ Vắng</c:when>
                      <c:when test="${sc.status=='ON_LEAVE'}">🏖️ Nghỉ phép</c:when>
                      <c:otherwise>⏳ Chưa vào</c:otherwise>
                    </c:choose>
                  </div>
                  <c:if test="${sc.status=='SCHEDULED'}">
                    <button class="chip-cancel"
                      onclick="event.stopPropagation();if(confirm('Hủy ca này?'))location.href='${pageContext.request.contextPath}/shift-schedules?action=cancel&id=${sc.scheduleId}'">✕</button>
                  </c:if>
                </div>
              </c:if>
            </c:forEach>
            <c:if test="${!hasShift}">
              <div class="empty-day">Trống</div>
            </c:if>
            <a href="${pageContext.request.contextPath}/shift-schedules?action=new&date=${dayDate}" class="day-add">＋ Thêm ca</a>
          </div>
        </div>
      </c:forEach>
    </div>
  </div>
</div>

<script>
const toast = document.getElementById('toast');
if (toast) setTimeout(()=>{toast.style.opacity='0';setTimeout(()=>toast.remove(),400)},3500);
</script>
</body></html>
