<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%
    String uid = request.getParameter("uid");
    if (uid == null || uid.isEmpty()) { response.sendRedirect(request.getContextPath()+"/staff-login"); return; }
    com.medicare.entity.Account staffAcc = (com.medicare.entity.Account) session.getAttribute("staffAccount_"+uid);
    if (staffAcc == null) { response.sendRedirect(request.getContextPath()+"/staff-login"); return; }
    String sName = staffAcc.getFullName() != null ? staffAcc.getFullName() : staffAcc.getUsername();
    String sInit = sName.length()>=2 ? sName.substring(0,1).toUpperCase()+sName.substring(1,2).toUpperCase() : sName.toUpperCase();
    String sRoleName = staffAcc.getRoleId() == 2 ? "Dược sĩ bán hàng" : "Thủ kho";
%>
<!DOCTYPE html><html lang="vi"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Điểm danh — medicare</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#12082A;--dp:#1C0F3F;--mid:#2D1B69;--main:#6D28D9;
  --light:#A78BFA;--soft:#F5F3FF;--white:#fff;
  --muted:#7C6FAA;--border:#E2DCF5;--surface:#FAFAFA;
  --green:#059669;--red:#DC2626;--gold:#D97706;--cyan:#5EEAD4;
  --sidebar:228px;--radius:14px;
}
html,body{height:100%;font-family:'Outfit',sans-serif;background:var(--soft);color:var(--ink)}body{display:flex}
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#0E0520 0%,#1C0F3F 45%,#3B1FA0 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 24px rgba(0,0,0,.2)}
.sidebar::after{content:'';position:absolute;top:0;right:0;bottom:0;width:1px;background:linear-gradient(180deg,transparent,rgba(167,139,250,.15) 30%,rgba(167,139,250,.15) 70%,transparent)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-gem{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,var(--light),var(--main));display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;box-shadow:0 4px 16px rgba(109,40,217,.4)}
.logo-name{font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-name span{color:var(--light)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-block{padding:12px 0 4px;flex-shrink:0}
.nav-label{font-size:9px;font-weight:700;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:500;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(167,139,250,.15);font-weight:600}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--light);border-radius:2px}
.nav-icon{width:18px;height:18px;display:flex;align-items:center;justify-content:center;font-size:14px;flex-shrink:0;opacity:.85}
.nav-item.active .nav-icon{opacity:1}
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06);flex-shrink:0}
.user-card{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08)}
.user-av{width:34px;height:34px;flex-shrink:0;border-radius:9px;background:linear-gradient(135deg,var(--light),var(--main));display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:800;color:#fff}
.user-name{font-size:12.5px;font-weight:600;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:108px}
.user-role{font-size:10px;color:rgba(255,255,255,.35);margin-top:1px}
.logout-btn{margin-left:auto;width:28px;height:28px;flex-shrink:0;border-radius:8px;background:rgba(220,38,38,.12);border:none;display:flex;align-items:center;justify-content:center;color:rgba(220,38,38,.7);font-size:13px;cursor:pointer;text-decoration:none;transition:all .18s}
.logout-btn:hover{background:rgba(220,38,38,.2);color:#DC2626}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0}
.topbar{height:58px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 24px;gap:12px;position:sticky;top:0;z-index:50}
.topbar-title{font-size:15px;font-weight:800;color:var(--ink)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:8px}
.content{padding:20px 24px;flex:1}

.toast{position:fixed;top:18px;right:22px;padding:11px 18px;border-radius:10px;font-size:13px;font-weight:700;color:#fff;z-index:9999;display:flex;align-items:center;gap:8px;box-shadow:0 4px 18px rgba(0,0,0,.15);animation:slideIn .3s ease}
.toast-ok{background:#059669}.toast-err{background:#DC2626}.toast-info{background:#1558A8}.toast-warn{background:#D97706}
@keyframes slideIn{from{transform:translateX(60px);opacity:0}to{transform:translateX(0);opacity:1}}

/* Check-in widget */
.checkin-wrap{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:20px}
/* Trạng thái ca */
.status-card{border-radius:var(--radius);overflow:hidden}
.status-working{background:linear-gradient(135deg,#ECFDF5,#F0FDF4);border:1.5px solid #A7F3D0}
.status-idle{background:linear-gradient(135deg,#EFF6FF,#F8FAFF);border:1.5px solid #BFDBFE}
.sc-head{padding:16px 20px;display:flex;align-items:center;justify-content:space-between}
.sc-badge{display:inline-flex;align-items:center;gap:6px;padding:4px 12px;border-radius:20px;font-size:12px;font-weight:800}
.sc-badge-on{background:#D1FAE5;color:#065F46}.sc-badge-off{background:#DBEAFE;color:#1E40AF}
.dot-live{width:8px;height:8px;border-radius:50%;background:#10B981;animation:pulse 1.4s infinite}
.dot-idle{width:8px;height:8px;border-radius:50%;background:#93C5FD}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.3}}
.sc-timer{font-size:36px;font-weight:900;font-variant-numeric:tabular-nums;letter-spacing:-1px;padding:0 20px;color:var(--green)}
.sc-timer-idle{font-size:18px;font-weight:700;color:var(--blue)}
.sc-meta{display:grid;grid-template-columns:1fr 1fr;gap:8px;padding:12px 20px}
.sc-meta-item{background:rgba(255,255,255,.7);border-radius:8px;padding:8px 12px}
.sc-meta-label{font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:#6EE7B7}
.sc-meta-label-idle{color:#93C5FD}
.sc-meta-val{font-size:13px;font-weight:700;color:#065F46;margin-top:2px}
.sc-meta-val-idle{color:#1558A8}

/* Forms */
.form-card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}
.form-head{padding:13px 18px;border-bottom:1px solid var(--border);display:flex;align-items:center;gap:8px}
.form-head h3{font-size:13.5px;font-weight:800;color:var(--ink)}
.form-body{padding:16px 18px}
.fg{display:flex;flex-direction:column;gap:5px;margin-bottom:12px}
.fg label{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.fg input,.fg textarea{border:1.5px solid var(--border);border-radius:8px;padding:8px 12px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);background:var(--surface);outline:none;transition:border .18s;width:100%}
.fg input:focus,.fg textarea:focus{border-color:var(--blue);background:#fff}
.btn-checkin{width:100%;padding:12px 0;background:linear-gradient(135deg,#059669,#047857);color:#fff;border:none;border-radius:10px;font-family:'Outfit',sans-serif;font-size:15px;font-weight:800;cursor:pointer;box-shadow:0 4px 12px rgba(5,150,105,.3);transition:all .18s}
.btn-checkin:hover{opacity:.9;transform:translateY(-1px)}
.btn-checkout{width:100%;padding:12px 0;background:linear-gradient(135deg,#DC2626,#B91C1C);color:#fff;border:none;border-radius:10px;font-family:'Outfit',sans-serif;font-size:15px;font-weight:800;cursor:pointer;box-shadow:0 4px 12px rgba(220,38,38,.25);transition:all .18s}
.btn-checkout:hover{opacity:.9;transform:translateY(-1px)}

/* Schedule table */
.table-card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}
.table-card-head{padding:13px 18px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
.table-card-head h2{font-size:13.5px;font-weight:800;color:var(--ink)}
table{width:100%;border-collapse:collapse}
thead th{padding:8px 14px;background:#F8FAFC;font-size:10px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;border-bottom:1px solid var(--border)}
tbody td{padding:10px 14px;font-size:13px;border-bottom:1px solid #F1F5F9;vertical-align:middle}
tbody tr:last-child td{border-bottom:none}
.badge{display:inline-flex;align-items:center;gap:4px;padding:2px 9px;border-radius:20px;font-size:11px;font-weight:700}
.badge-today{background:#DBEAFE;color:#1E40AF}.badge-upcoming{background:#F5F3FF;color:#6D28D9}
.badge-confirmed{background:#D1FAE5;color:#065F46}.badge-absent{background:#FEE2E2;color:#991B1B}
.today-row td{background:#FFFBEB;font-weight:600}
.empty-box{padding:30px;text-align:center;color:var(--muted)}
</style></head>
<body>
<aside class="sidebar">
  <div class="sidebar-logo">
    <div class="logo-gem">💊</div>
    <div>
      <div class="logo-name">Medi<span>Vault</span></div>
      <div class="logo-sub">Staff Portal</div>
    </div>
  </div>
  <nav class="nav-block">
    <div class="nav-label">Tổng quan</div>
    <a href="${pageContext.request.contextPath}/staff-dashboard?uid=${staffUid}" class="nav-item">
      <span class="nav-icon">🏠</span> Trang chủ
    </a>
  </nav>
  <nav class="nav-block">
    <div class="nav-label">Cá nhân</div>
    <a href="${pageContext.request.contextPath}/staff-profile?uid=${staffUid}"   class="nav-item">
      <span class="nav-icon">👤</span> Hồ sơ của tôi
    </a>
    <a href="${pageContext.request.contextPath}/staff-checkin?uid=${staffUid}"   class="nav-item active">
      <span class="nav-icon">✅</span> Điểm danh
    </a>
    <a href="${pageContext.request.contextPath}/staff-my-shifts?uid=${staffUid}" class="nav-item">
      <span class="nav-icon">🕐</span> Ca làm việc
    </a>
    <a href="${pageContext.request.contextPath}/leave-requests?action=my&uid=${staffUid}" class="nav-item">
      <span class="nav-icon">🏖️</span> Xin nghỉ phép
    </a>
  </nav>
  <nav class="nav-block">
    <div class="nav-label">Bán hàng</div>
    <a href="${pageContext.request.contextPath}/pos?uid=${staffUid}" class="nav-item">
      <span class="nav-icon">🛒</span> Bán thuốc (POS)
    </a>
  </nav>
  <div class="sidebar-footer">
    <div class="user-card">
      <div class="user-av"><%= sInit %></div>
      <div style="min-width:0">
        <div class="user-name"><%= sName %></div>
        <div class="user-role"><%= sRoleName %></div>
      </div>
      <a href="${pageContext.request.contextPath}/logout?from=staff&uid=${staffUid}" class="logout-btn">⏻</a>
    </div>
  </div>
</aside>

<div class="main">
  <c:if test="${not empty param.msg}">
    <c:choose>
      <c:when test="${param.msg=='checked-in'}"><div class="toast toast-ok" id="toast">✅ Check-in thành công!</div></c:when>
      <c:when test="${param.msg=='checked-out'}"><div class="toast toast-ok" id="toast">✅ Check-out thành công!</div></c:when>
      <c:when test="${param.msg=='already-in'}"><div class="toast toast-warn" id="toast">⚠️ Bạn đang có ca đang mở!</div></c:when>
      <c:when test="${param.msg=='no-schedule'}"><div class="toast toast-err" id="toast">🚫 Hôm nay bạn không có lịch làm việc!</div></c:when>
      <c:when test="${param.msg=='too-early'}"><div class="toast toast-warn" id="toast">⏰ Chưa đến giờ ca! Vui lòng đợi đến giờ bắt đầu.</div></c:when>
      <c:when test="${param.msg=='too-late'}"><div class="toast toast-err" id="toast">❌ Ca đã kết thúc hơn 20 phút, không thể check-in!</div></c:when>
      <c:when test="${param.msg=='checked-in'}"><div class="toast toast-ok" id="toast">✅ Check-in thành công — Đúng giờ!</div></c:when>
      <c:when test="${param.msg=='checked-in-late'}"><div class="toast toast-warn" id="toast">⚠️ Check-in thành công — Ghi nhận trễ giờ!</div></c:when>
      <c:when test="${param.msg=='checked-in-absent'}"><div class="toast toast-err" id="toast">❌ Check-in ghi nhận VẮNG — Trễ quá giờ cho phép!</div></c:when>
      <c:when test="${param.msg=='checked-out'}"><div class="toast toast-ok" id="toast">👋 Check-out thành công!</div></c:when>
      <c:otherwise><div class="toast toast-err" id="toast">❌ Có lỗi xảy ra!</div></c:otherwise>
    </c:choose>
  </c:if>
  <header class="topbar">
    <div style="font-size:15px">✅</div>
    <span class="topbar-title">Điểm danh</span>
    <div class="topbar-right">
      <span style="font-size:13px;font-weight:700;color:var(--muted)" id="clock"></span>
    </div>
  </header>
  <div class="content">
    <div class="checkin-wrap">
      <%-- Trạng thái hiện tại --%>
      <c:choose>
        <c:when test="${not empty activeAtt}">
          <div class="status-card status-working">
            <div class="sc-head">
              <span class="sc-badge sc-badge-on"><span class="dot-live"></span> Đang làm việc</span>
              <span style="font-size:12px;color:#6EE7B7">Ca #${activeAtt.shiftId}</span>
            </div>
            <div class="sc-timer" id="checkinTimer" data-time="${activeAtt.checkInTime}">--:--:--</div>
            <div style="font-size:12px;color:#6EE7B7;padding:0 20px 10px">Thời gian làm việc</div>
            <div class="sc-meta">
              <div class="sc-meta-item">
                <div class="sc-meta-label">Check-in</div>
                <div class="sc-meta-val">${fn:substring(activeAtt.checkInTime.toString(),11,16)}</div>
              </div>
              <div class="sc-meta-item">
                <div class="sc-meta-label">Trễ</div>
                <div class="sc-meta-val" style="${activeAtt.lateMinutes>0?'color:var(--red)':''}">
                  ${activeAtt.lateMinutes>0 ? activeAtt.lateMinutes.concat(' phút') : 'Đúng giờ'}
                </div>
              </div>
              <div class="sc-meta-item">
                <div class="sc-meta-label">Phương thức</div>
                <div class="sc-meta-val">${activeAtt.checkInMethod}</div>
              </div>
              <c:if test="${not empty activeAtt.plannedEnd}">
                <div class="sc-meta-item">
                  <div class="sc-meta-label">Kết thúc ca</div>
                  <div class="sc-meta-val">${fn:substring(activeAtt.plannedEnd.toString(),11,16)}</div>
                </div>
              </c:if>
            </div>
          </div>
        </c:when>
        <c:otherwise>
          <div class="status-card status-idle">
            <div class="sc-head">
              <span class="sc-badge sc-badge-off"><span class="dot-idle"></span> Chưa check-in</span>
            </div>
            <div style="padding:16px 20px 8px">
              <c:if test="${not empty todaySchedule}">
                <div style="font-size:13px;font-weight:700;color:var(--blue);margin-bottom:8px">📅 Ca hôm nay: ${todaySchedule.shiftTypeName}</div>
                <div style="font-size:12px;color:var(--muted)">
                  ${fn:substring(todaySchedule.plannedStart.toString(),11,16)} – ${fn:substring(todaySchedule.plannedEnd.toString(),11,16)}
                </div>
              </c:if>
              <c:if test="${empty todaySchedule}">
                <div style="font-size:13px;color:var(--muted)">Không có lịch ca hôm nay.<br>Bạn vẫn có thể mở ca tự do.</div>
              </c:if>
            </div>
            <div class="sc-meta">
              <div class="sc-meta-item" style="grid-column:1/-1">
                <div class="sc-meta-label sc-meta-label-idle">Thời gian hiện tại</div>
                <div class="sc-meta-val sc-meta-val-idle" id="currentTime" style="font-size:22px;font-weight:900">--:--</div>
              </div>
            </div>
          </div>
        </c:otherwise>
      </c:choose>

      <%-- Form check-in hoặc check-out --%>
      <c:choose>
        <c:when test="${not empty activeAtt}">
          <div class="form-card">
            <div class="form-head"><span>📤</span><h3>Kết thúc ca làm việc</h3></div>
            <div class="form-body">
              <form method="post" action="${pageContext.request.contextPath}/staff-checkin">
                <input type="hidden" name="action" value="checkout">
                <input type="hidden" name="uid"    value="${staffUid}">

                <div class="fg">
                  <label style="font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px">
                    💰 Tiền mặt bàn giao két <span style="color:#DC2626">*</span>
                  </label>
                  <input type="number" name="handoverCash" id="coHandoverCash"
                         min="0" step="1000" required
                         placeholder="Nhập số tiền mặt trong két (VNĐ)"
                         oninput="updateCoPreview(this.value)"
                         style="border:1.5px solid var(--border);border-radius:8px;
                                padding:9px 12px;font-size:13px;width:100%;
                                font-family:'Outfit',sans-serif;outline:none">
                  <div id="coPreview" style="display:none;margin-top:6px;padding:7px 12px;
                       border-radius:8px;font-size:12.5px;font-weight:700;text-align:center"></div>
                </div>
                <div class="fg"><label>📝 Ghi chú bàn giao</label>
                  <textarea name="notes" rows="2"
                    placeholder="Ghi chú tình trạng ca, thuốc tủ khóa, vấn đề phát sinh..."></textarea>
                </div>
                <button type="submit" class="btn-checkout"
                        onclick="return confirmCheckout(this.form)">
                  ✅ Check-out — Bàn giao ca
                </button>
              </form>
            </div>
          </div>
        </c:when>
        <c:otherwise>
          <div class="form-card">
            <div class="form-head"><span>📥</span><h3>Check-in bắt đầu ca</h3></div>
            <div class="form-body">
              <c:choose>
                <c:when test="${not empty todaySchedule}">
                  <%-- Có lịch ca → cho check-in --%>
                  <div style="background:#ECFDF5;border:1px solid #A7F3D0;border-radius:8px;padding:12px 16px;margin-bottom:14px">
                    <div style="font-size:13px;font-weight:700;color:#065F46;margin-bottom:4px">
                      ✅ Ca hôm nay: <strong>${todaySchedule.shiftTypeName}</strong>
                    </div>
                    <div style="font-size:12px;color:#059669">
                      🕐 ${fn:substring(todaySchedule.plannedStart.toString(),11,16)} – ${fn:substring(todaySchedule.plannedEnd.toString(),11,16)}
                      &nbsp;|&nbsp; ⏱️ Cho phép trễ ${todaySchedule.lateToleranceMinutes} phút
                    </div>
                    <c:if test="${not empty todaySchedule.openingCash}">
                      <div style="font-size:12px;color:#059669;margin-top:4px">
                        💰 Tiền đầu ca: <strong><fmt:formatNumber value="${todaySchedule.openingCash}" type="number" maxFractionDigits="0"/>đ</strong>
                        (do Admin thiết lập)
                      </div>
                    </c:if>
                  </div>
                  <form method="post" action="${pageContext.request.contextPath}/staff-checkin">
                    <input type="hidden" name="action" value="checkin">
                    <input type="hidden" name="uid"    value="${staffUid}">
                    <button type="submit" class="btn-checkin">🟢 Check-in — Bắt đầu ca</button>
                  </form>
                </c:when>
                <c:otherwise>
                  <%-- Không có lịch ca → ẩn nút, hiện alert --%>
                  <div style="background:#FEF2F2;border:1.5px solid #FECACA;border-radius:10px;padding:16px;text-align:center">
                    <div style="font-size:22px;margin-bottom:8px">🚫</div>
                    <div style="font-size:13.5px;font-weight:700;color:#991B1B;margin-bottom:6px">
                      Hôm nay bạn không có lịch làm việc
                    </div>
                    <div style="font-size:12.5px;color:#B91C1C;line-height:1.6">
                      Nếu có sự nhầm lẫn, vui lòng liên hệ Admin<br>
                      để được xếp ca trước khi điểm danh.
                    </div>
                  </div>
                </c:otherwise>
              </c:choose>
            </div>
          </div>
        </c:otherwise>
      </c:choose>
    </div>

    <%-- Lịch ca sắp tới --%>
    <div class="table-card">
      <div class="table-card-head"><h2>📅 Lịch ca của tôi (7 ngày tới)</h2>
        <span style="font-size:12px;color:var(--muted)">${fn:length(upcoming)} ca</span>
      </div>
      <c:choose>
        <c:when test="${empty upcoming}">
          <div class="empty-box"><p>Chưa có lịch ca nào được xếp. Liên hệ admin để được xếp ca.</p></div>
        </c:when>
        <c:otherwise>
          <table>
            <thead><tr><th>Ngày</th><th>Ca</th><th>Giờ</th><th>Trạng thái</th></tr></thead>
            <tbody>
              <c:forEach var="sc" items="${upcoming}">
                <c:set var="isToday" value="${sc.workDate.equals(today)}"/>
                <tr class="${isToday?'today-row':''}">
                  <td>
                    ${isToday?'<strong>Hôm nay</strong> — ':''}
                    ${sc.workDate.dayOfMonth}/${sc.workDate.monthValue}/${sc.workDate.year}
                    <c:if test="${isToday}"><span class="badge badge-today">Hôm nay</span></c:if>
                  </td>
                  <td>${sc.shiftTypeName}</td>
                  <td style="font-weight:600">
                    ${fn:substring(sc.plannedStart.toString(),11,16)} – ${fn:substring(sc.plannedEnd.toString(),11,16)}
                  </td>
                  <td>
                    <span class="badge
                      <c:choose>
                        <c:when test="${sc.status=='CONFIRMED'}">badge-confirmed</c:when>
                        <c:when test="${sc.status=='ABSENT'}">badge-absent</c:when>
                        <c:otherwise>badge-upcoming</c:otherwise>
                      </c:choose>">
                      <c:choose>
                        <c:when test="${sc.status=='CONFIRMED'}">✅ Đã check-in</c:when>
                        <c:when test="${sc.status=='ABSENT'}">❌ Vắng</c:when>
                        <c:otherwise>⏳ Sắp tới</c:otherwise>
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

// Clock
const clockEl = document.getElementById('clock');
const curEl   = document.getElementById('currentTime');
function updateClock(){
  const n = new Date();
  const t = [n.getHours(),n.getMinutes(),n.getSeconds()].map(v=>String(v).padStart(2,'0')).join(':');
  const tm= [n.getHours(),n.getMinutes()].map(v=>String(v).padStart(2,'0')).join(':');
  if(clockEl) clockEl.textContent = t;
  if(curEl)   curEl.textContent   = tm;
}
updateClock(); setInterval(updateClock,1000);

// Timer ca đang mở
const timerEl = document.getElementById('checkinTimer');
if (timerEl) {
  const startRaw = timerEl.dataset.time;
  const start = new Date(startRaw.replace('T',' '));
  function tick(){
    const diff = Math.floor((new Date()-start)/1000);
    if(isNaN(diff)||diff<0){timerEl.textContent='--:--:--';return;}
    timerEl.textContent=[Math.floor(diff/3600),Math.floor((diff%3600)/60),diff%60]
      .map(v=>String(v).padStart(2,'0')).join(':');
  }
  tick(); setInterval(tick,1000);
}
</script>

<script>
function confirmCheckout(form) {
  const cash = form.handoverCash?.value;
  if (!cash || parseInt(cash) < 0) {
    alert('⚠️ Vui lòng nhập số tiền bàn giao két trước khi kết thúc ca!');
    form.handoverCash?.focus();
    return false;
  }
  const amt = parseInt(cash).toLocaleString('vi-VN');
  return confirm('Xác nhận kết thúc ca?\n💰 Tiền bàn giao: ' + amt + 'đ');
}
function updateCoPreview(val) {
  const el = document.getElementById('coPreview');
  if (!el) return;
  const n = parseInt(val);
  if (isNaN(n) || n < 0) { el.style.display='none'; return; }
  el.style.display = 'block';
  el.style.background = '#ECFDF5';
  el.style.color = '#065F46';
  el.textContent = '💰 ' + n.toLocaleString('vi-VN') + 'đ';
}
</script>
</body></html>
