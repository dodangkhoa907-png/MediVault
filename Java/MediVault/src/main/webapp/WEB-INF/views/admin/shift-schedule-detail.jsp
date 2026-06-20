<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<% String activeNav = "shifts"; %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    com.medicare.entity.ShiftSchedule sc = (com.medicare.entity.ShiftSchedule) request.getAttribute("schedule");
    if (sc == null) { response.sendRedirect(request.getContextPath() + "/shifts"); return; }
    String staffName = sc.getStaffName() != null ? sc.getStaffName() : "NV #" + sc.getAccountId();
    String[] parts = staffName.trim().split("\\s+");
    String ini = parts.length >= 2
        ? ("" + parts[0].charAt(0) + parts[parts.length-1].charAt(0)).toUpperCase()
        : staffName.substring(0, Math.min(2, staffName.length())).toUpperCase();
    String msg = request.getParameter("msg");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Chi tiết lịch ca — Medicare</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;
}
html,body{min-height:100%;font-family:'Outfit',sans-serif;background:var(--surface);color:var(--ink)}
body{display:flex;align-items:flex-start;justify-content:center;padding:40px 16px}
.container{width:100%;max-width:640px;animation:fadeUp .35s ease both}
@keyframes fadeUp{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)}}
.back-row{margin-bottom:16px}
.btn-back{display:inline-flex;align-items:center;gap:6px;padding:8px 16px;
  background:var(--white);border:1.5px solid var(--border);border-radius:10px;
  font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;color:var(--muted);
  text-decoration:none;transition:all .18s}
.btn-back:hover{border-color:var(--blue);color:var(--blue)}
.card{background:var(--white);border-radius:16px;box-shadow:0 6px 28px rgba(21,88,168,.08);overflow:hidden}
.card-header{background:linear-gradient(135deg,var(--navy),var(--blue));padding:22px 26px;color:#fff}
.ch-top{display:flex;align-items:center;gap:14px}
.ch-av{width:48px;height:48px;border-radius:13px;background:rgba(255,255,255,.15);
  display:flex;align-items:center;justify-content:center;font-size:16px;font-weight:800;color:#fff;flex-shrink:0}
.ch-name{font-size:18px;font-weight:700}
.ch-type{font-size:13px;opacity:.75;margin-top:2px}
.ch-badge{margin-left:auto;padding:5px 14px;border-radius:20px;font-size:12px;font-weight:700}
.badge-scheduled{background:rgba(147,197,253,.25);color:#93C5FD}
.badge-confirmed{background:rgba(110,231,183,.25);color:#6EE7B7}
.badge-absent{background:rgba(252,165,165,.25);color:#FCA5A5}
.badge-leave{background:rgba(253,224,71,.25);color:#FDE047}
.badge-system{background:rgba(148,163,184,.25);color:#94A3B8}
.info-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px;padding:22px 26px}
.info-item{background:var(--surface);border-radius:10px;padding:12px 14px}
.info-label{font-size:10.5px;font-weight:700;color:var(--muted);letter-spacing:.5px;text-transform:uppercase;margin-bottom:4px}
.info-val{font-size:14px;font-weight:600;color:var(--ink)}
.notes-sec{padding:0 26px 22px}
.notes-label{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px}
.notes-val{font-size:13px;color:var(--ink);background:var(--surface);border-radius:10px;padding:12px 14px;line-height:1.6}
.action-row{display:flex;gap:10px;padding:0 26px 24px}
.btn-act{flex:1;padding:11px;border-radius:10px;border:none;font-family:'Outfit',sans-serif;
  font-size:13px;font-weight:700;cursor:pointer;transition:all .18s;text-align:center;text-decoration:none;display:flex;align-items:center;justify-content:center;gap:5px}
.btn-edit{background:#EFF6FF;color:var(--blue);border:1.5px solid #BFDBFE}
.btn-edit:hover{background:#DBEAFE}
.btn-cancel{background:#FEF2F2;color:var(--red);border:1.5px solid #FECACA}
.btn-cancel:hover{background:#FEE2E2}
.btn-list{background:var(--white);color:var(--muted);border:1.5px solid var(--border)}
.btn-list:hover{border-color:var(--blue);color:var(--blue)}
.toast{position:fixed;top:20px;right:24px;padding:12px 20px;border-radius:11px;font-size:13.5px;font-weight:600;
  box-shadow:0 8px 32px rgba(0,0,0,.2);z-index:999;transition:opacity .4s;color:#fff}
.toast-ok{background:#064e3b}.toast-warn{background:#92400E}.toast-err{background:#991B1B}
</style>
</head>
<body>
<div class="container">
  <div class="back-row">
    <a href="${pageContext.request.contextPath}/shifts" class="btn-back">← Quay lại Ca làm việc</a>
  </div>

  <div class="card">
    <div class="card-header">
      <div class="ch-top">
        <div class="ch-av"><%= ini %></div>
        <div>
          <div class="ch-name"><%= staffName %></div>
          <div class="ch-type">${schedule.shiftTypeName}</div>
        </div>
        <span class="ch-badge
          <c:choose>
            <c:when test="${schedule.status=='CONFIRMED'}">badge-confirmed</c:when>
            <c:when test="${schedule.status=='ABSENT'}">badge-absent</c:when>
            <c:when test="${schedule.status=='ON_LEAVE' or schedule.status=='LEAVE_PENDING'}">badge-leave</c:when>
            <c:when test="${schedule.status=='SYSTEM_CLOSED'}">badge-system</c:when>
            <c:otherwise>badge-scheduled</c:otherwise>
          </c:choose>
        ">
          ${schedule.statusIcon} ${schedule.statusLabel}
        </span>
      </div>
    </div>

    <div class="info-grid">
      <div class="info-item">
        <div class="info-label">Ngày làm việc</div>
        <div class="info-val">${schedule.workDate.dayOfMonth}/${schedule.workDate.monthValue}/${schedule.workDate.year}</div>
      </div>
      <div class="info-item">
        <div class="info-label">Loại ca</div>
        <div class="info-val">${schedule.shiftTypeName}</div>
      </div>
      <c:if test="${not empty schedule.plannedStart}">
        <div class="info-item">
          <div class="info-label">Giờ bắt đầu</div>
          <div class="info-val">${fn:substring(schedule.plannedStart.toString(),11,16)}</div>
        </div>
      </c:if>
      <c:if test="${not empty schedule.plannedEnd}">
        <div class="info-item">
          <div class="info-label">Giờ kết thúc</div>
          <div class="info-val">${fn:substring(schedule.plannedEnd.toString(),11,16)}</div>
        </div>
      </c:if>
      <div class="info-item">
        <div class="info-label">Cho phép trễ</div>
        <div class="info-val">${schedule.lateToleranceMinutes} phút</div>
      </div>
      <div class="info-item">
        <div class="info-label">Mã lịch ca</div>
        <div class="info-val">#${schedule.scheduleId}</div>
      </div>
      <c:if test="${not empty schedule.openingCash}">
        <div class="info-item">
          <div class="info-label">Tiền đầu ca</div>
          <div class="info-val"><fmt:formatNumber value="${schedule.openingCash}" type="number" maxFractionDigits="0"/>đ</div>
        </div>
      </c:if>
      <c:if test="${not empty schedule.createdAt}">
        <div class="info-item">
          <div class="info-label">Tạo lúc</div>
          <div class="info-val">${fn:substring(schedule.createdAt.toString(),0,16)}</div>
        </div>
      </c:if>
    </div>

    <c:if test="${not empty schedule.notes}">
      <div class="notes-sec">
        <div class="notes-label">Ghi chú</div>
        <div class="notes-val">${schedule.notes}</div>
      </div>
    </c:if>

    <div class="action-row">
      <c:if test="${schedule.status == 'SCHEDULED' or schedule.status == 'LEAVE_PENDING'}">
        <a href="${pageContext.request.contextPath}/shift-schedules?action=edit&id=${schedule.scheduleId}" class="btn-act btn-edit">✏️ Sửa</a>
        <a href="${pageContext.request.contextPath}/shift-schedules?action=cancel&id=${schedule.scheduleId}"
           class="btn-act btn-cancel" onclick="return confirm('Hủy lịch ca này?')">🗑 Hủy ca</a>
      </c:if>
      <a href="${pageContext.request.contextPath}/shifts" class="btn-act btn-list">← Danh sách</a>
    </div>
  </div>
</div>

<% if ("updated".equals(msg)) { %><div class="toast toast-ok">✅ Đã cập nhật lịch ca!</div><% }
   else if ("error".equals(msg)) { %><div class="toast toast-err">❌ Có lỗi xảy ra!</div><% }
   else if ("cancelled".equals(msg)) { %><div class="toast toast-warn">🗑 Đã hủy lịch ca!</div><% } %>
<script>
const t = document.querySelector('.toast');
if (t) setTimeout(() => { t.style.opacity='0'; setTimeout(()=>t.remove(),400); }, 3000);
</script>
</body>
</html>
