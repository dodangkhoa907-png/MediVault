<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<% String activeNav = "shifts"; %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length()>=2 ? fullName.substring(0,1).toUpperCase()+fullName.substring(1,2).toUpperCase() : fullName.toUpperCase();
%>
<!DOCTYPE html><html lang="vi"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Xếp ca — medicare</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--ink:#0B1628;--blue:#1558A8;--cyan:#3ABDE0;--surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;--green:#059669;--sidebar:232px;--radius:14px}
html,body{height:100%;font-family:'Outfit',sans-serif;background:var(--surface);color:var(--ink)}
body{display:flex}
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100}
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
.logout-btn:hover{background:rgba(220,38,38,.2);color:#DC2626}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh}
.topbar{height:60px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-size:16px;font-weight:800;color:var(--ink)}
.topbar-right{margin-left:auto}
.btn-back{padding:7px 16px;border:1.5px solid var(--border);border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;color:var(--muted);text-decoration:none;transition:all .18s}
.btn-back:hover{border-color:var(--blue);color:var(--blue)}
.content{padding:28px 32px;flex:1;max-width:820px}
.page-title{font-size:20px;font-weight:900;color:var(--ink);margin-bottom:6px}
.page-sub{font-size:13px;color:var(--muted);margin-bottom:24px}
.card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden;margin-bottom:20px}
.card-head{padding:14px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;gap:8px}
.card-head h2{font-size:14px;font-weight:800;color:var(--ink)}
.card-body{padding:20px}
.form-grid{display:grid;grid-template-columns:1fr 1fr;gap:16px}
.form-grid-3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:16px}
.fg{display:flex;flex-direction:column;gap:6px}
.fg.full{grid-column:1/-1}
.fg label{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.fg select,.fg input{border:1.5px solid var(--border);border-radius:8px;padding:9px 12px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);background:var(--surface);outline:none;transition:border .18s;width:100%}
.fg select:focus,.fg input:focus{border-color:var(--blue);background:#fff}
.fg small{font-size:11px;color:var(--muted)}
.staff-chips{display:flex;flex-wrap:wrap;gap:8px;padding:10px;background:var(--surface);border-radius:8px;border:1.5px solid var(--border);min-height:48px}
.staff-chip{display:flex;align-items:center;gap:6px;padding:5px 10px;background:var(--white);border:1.5px solid var(--border);border-radius:20px;font-size:12.5px;cursor:pointer;transition:all .18s}
.staff-chip input[type=checkbox]{accent-color:var(--blue)}
.staff-chip:has(input:checked){background:#EFF6FF;border-color:var(--blue)}
.shift-type-cards{display:grid;grid-template-columns:repeat(3,1fr);gap:10px}
.st-card{padding:12px;border:2px solid var(--border);border-radius:10px;cursor:pointer;transition:all .18s;text-align:center;position:relative}
.st-card:has(input:checked){border-color:var(--blue);background:#EFF6FF}
.st-card input{position:absolute;opacity:0;width:0;height:0}
.st-card-icon{font-size:22px;margin-bottom:6px}
.st-card-name{font-size:13px;font-weight:800;color:var(--ink)}
.st-card-time{font-size:11px;color:var(--muted);margin-top:2px}
.st-card-rate{font-size:11px;color:var(--green);font-weight:700;margin-top:4px}
.date-range{display:grid;grid-template-columns:1fr auto 1fr;gap:10px;align-items:center}
.date-sep{font-size:13px;color:var(--muted);font-weight:700;text-align:center}
.info-box{background:#EFF6FF;border:1px solid #BFDBFE;border-radius:10px;padding:12px 16px;font-size:12.5px;color:#1558A8;margin-top:16px}
.form-actions{display:flex;gap:10px;margin-top:20px}
.btn-submit{padding:10px 28px;background:var(--blue);color:#fff;border:none;border-radius:9px;font-family:'Outfit',sans-serif;font-size:14px;font-weight:700;cursor:pointer;transition:background .18s}
.btn-submit:hover{background:#0D3F85}
.btn-cancel{padding:10px 20px;background:var(--surface);color:var(--muted);border:1.5px solid var(--border);border-radius:9px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;cursor:pointer;text-decoration:none;transition:all .18s}
.btn-cancel:hover{border-color:#DC2626;color:#DC2626}
</style></head>
<body>
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">
  <header class="topbar">
    <div style="font-size:15px">📅</div>
    <span class="topbar-title">Xếp lịch ca mới</span>
    <div class="topbar-right">
      <a href="${pageContext.request.contextPath}/shift-schedules" class="btn-back">← Quay lại lịch tuần</a>
    </div>
  </header>
  <div class="content">
    <div class="page-title">Xếp lịch ca làm việc</div>
    <div class="page-sub">Chọn nhân viên + loại ca + khoảng ngày. Hệ thống tự tính giờ bắt đầu/kết thúc.</div>

    <form method="post" action="${pageContext.request.contextPath}/shift-schedules">
      <input type="hidden" name="action" value="create">

      <%-- Chọn nhân viên --%>
      <div class="card">
        <div class="card-head"><span>👤</span><h2>Nhân viên</h2></div>
        <div class="card-body">
          <div class="fg"><label>Chọn (có thể chọn nhiều)</label>
            <div class="staff-chips">
              <c:forEach var="s" items="${allStaff}">
                <label class="staff-chip">
                  <input type="checkbox" name="accountId" value="${s.accountId}">
                  ${s.fullName}
                  <span style="font-size:10px;color:var(--muted)">#${s.accountId}</span>
                </label>
              </c:forEach>
            </div>
          </div>
        </div>
      </div>

      <%-- Chọn loại ca --%>
      <div class="card">
        <div class="card-head"><span>🕐</span><h2>Loại ca</h2></div>
        <div class="card-body">
          <div class="shift-type-cards">
            <c:forEach var="st" items="${shiftTypes}">
              <label class="st-card">
                <input type="checkbox" name="shiftTypeId" value="${st.shiftTypeId}">
                <div class="st-card-icon">
                  <c:choose>
                    <c:when test="${st.startHour < 12}">🌅</c:when>
                    <c:when test="${st.startHour < 20}">☀️</c:when>
                    <c:otherwise>🌙</c:otherwise>
                  </c:choose>
                </div>
                <div class="st-card-name">${st.name}</div>
                <div class="st-card-time">${st.startHour}:00 – ${st.endHour}:00</div>
                <div class="st-card-rate"><fmt:formatNumber value="${st.hourlyRate}" type="number" maxFractionDigits="0"/>đ/giờ</div>
              </label>
            </c:forEach>
          </div>
        </div>
      </div>

      <%-- Khoảng ngày --%>
      <div class="card">
        <div class="card-head"><span>📆</span><h2>Khoảng ngày</h2></div>
        <div class="card-body">
          <div class="date-range">
            <div class="fg"><label>Từ ngày</label>
              <input type="date" name="dateFrom" value="${today}" required></div>
            <div class="date-sep">→</div>
            <div class="fg"><label>Đến ngày</label>
              <input type="date" name="dateTo" value="${today}">
              <small>Để trống = chỉ 1 ngày</small></div>
          </div>
          <div class="info-box">
            💡 Nếu chọn nhiều nhân viên + nhiều loại ca + khoảng ngày → hệ thống tự tạo tất cả tổ hợp. Lịch ca đã tồn tại sẽ tự động bỏ qua.
          </div>
        </div>
      </div>

      <div class="form-actions">
        <button type="submit" class="btn-submit">📅 Xếp lịch ca</button>
        <a href="${pageContext.request.contextPath}/shift-schedules" class="btn-cancel">Hủy</a>
      </div>
    </form>
  </div>
</div>
</body></html>
