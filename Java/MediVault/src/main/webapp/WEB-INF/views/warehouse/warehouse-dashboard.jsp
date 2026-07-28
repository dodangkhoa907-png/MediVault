<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) request.getAttribute("staffAcc");
    String uid = (String) request.getAttribute("staffUid");
    String ctx = request.getContextPath();
    if (acc == null) { response.sendRedirect(ctx + "/warehouse-login"); return; }
    String fullName = acc.getFullName() != null && !acc.getFullName().isEmpty() ? acc.getFullName() : acc.getUsername();
    String initials = fullName.substring(0,1).toUpperCase();
    Object totalMed = request.getAttribute("totalMedicines");
    Object lowStock = request.getAttribute("lowStockCount");
    Object expiry   = request.getAttribute("expiryCount");
    Object expired  = request.getAttribute("expiredCount");
    Object activeAtt = request.getAttribute("activeAtt");
    com.medicare.entity.Shift currentShift = (com.medicare.entity.Shift) request.getAttribute("currentShift");
    boolean working = activeAtt != null;
    String activeNav = "dashboard";

    int _hr = java.time.LocalTime.now().getHour();
    String greeting = _hr < 12 ? "Chào buổi sáng" : _hr < 18 ? "Chào buổi chiều" : "Chào buổi tối";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Quản lý kho — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400..800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= ctx %>/css/staff-portal.css">
<link rel="stylesheet" href="<%= ctx %>/css/warehouse-portal.css?v=5">
<style>
/* CSS riêng cho trang chủ Kho (chrome dùng chung ở warehouse-portal.css) */

/* ── Banner chào hỏi ── */
.welcome{
  border-radius:20px;padding:28px 32px;margin-bottom:20px;
  background:linear-gradient(140deg,#042F2E 0%,#115E59 55%,#0F766E 100%);
  display:flex;align-items:center;gap:20px;color:#fff;
  position:relative;overflow:hidden;
}
.welcome::before{content:'';position:absolute;top:-60px;right:-40px;width:240px;height:240px;
  border-radius:50%;background:rgba(45,212,191,.14);pointer-events:none}
.welcome::after{content:'';position:absolute;bottom:-80px;right:100px;width:180px;height:180px;
  border-radius:50%;background:rgba(20,184,166,.18);pointer-events:none}
.welcome-av{width:58px;height:58px;border-radius:16px;flex-shrink:0;
  background:rgba(255,255,255,.15);border:2px solid rgba(255,255,255,.25);
  display:flex;align-items:center;justify-content:center;font-size:22px;color:#fff}
.welcome-body{flex:1;min-width:0}
.welcome-body h2{font-size:22px;font-weight:800;color:#fff;margin-bottom:4px;letter-spacing:-.3px}
.welcome-body p{font-size:13.5px;color:rgba(255,255,255,.65)}
.welcome-role-badge{flex-shrink:0;background:rgba(255,255,255,.12);border:1px solid rgba(255,255,255,.18);
  border-radius:14px;padding:12px 18px;text-align:center}
.wrb-icon{font-size:22px;display:block;margin-bottom:5px}
.wrb-text{font-size:12px;font-weight:750;color:rgba(255,255,255,.85)}

/* ── Widget 1: Task &amp; SLA Deadline ── */
.sla-card{border-radius:16px;padding:16px 20px;margin-bottom:14px;background:#FFFBEB;border:1px solid #FDE68A}
.sla-head{display:flex;align-items:center;gap:9px;margin-bottom:10px}
.sla-head .ic{font-size:17px}
.sla-head strong{font-size:13.5px;color:#92400E}
.sla-list{display:flex;flex-direction:column;gap:8px}
.sla-item{display:flex;align-items:center;justify-content:space-between;gap:10px;background:#fff;
  border:1px solid #FDE68A;border-radius:10px;padding:9px 13px}
.sla-item .si-title{font-size:12.5px;font-weight:700;color:var(--ink)}
.sla-item .si-due{font-size:11px;color:var(--muted);margin-top:1px}
.sla-item .badge{display:inline-block;padding:2px 9px;border-radius:20px;font-size:11px;font-weight:750;white-space:nowrap}
.badge.danger{background:var(--dangerbg);color:var(--danger)}
.badge.warn{background:var(--goldbg);color:var(--gold)}
.sla-cta{display:inline-block;margin-top:10px;font-size:12.5px;font-weight:750;color:var(--main);text-decoration:none}
.sla-cta:hover{text-decoration:underline}

/* ── Widget 2: Cảnh báo thu hồi khẩn cấp ── */
.recall-card{border-radius:16px;padding:16px 20px;margin-bottom:20px;background:#FEF2F2;border:1.5px solid #FCA5A5}
.recall-head{display:flex;align-items:center;gap:9px;margin-bottom:8px}
.recall-head .ic{font-size:18px}
.recall-head strong{font-size:13.5px;color:#991B1B}
.recall-item{font-size:12.5px;color:#7F1D1D;padding:5px 0}
.recall-item b{font-weight:800}
.recall-cta{display:inline-block;margin-top:6px;font-size:12.5px;font-weight:750;color:#991B1B;text-decoration:underline}

.hero{margin-bottom:20px}
.hero h1{font-size:24px;font-weight:800;letter-spacing:-.5px}
.hero h1 span{color:var(--main)}
.hero p{color:var(--muted);font-size:14px;margin-top:5px}
.status-chip{display:inline-flex;align-items:center;gap:7px;margin-top:12px;padding:6px 13px;border-radius:20px;font-size:12.5px;font-weight:700}
.status-chip.on{background:var(--okbg);color:var(--ok)}
.status-chip.off{background:#F3EFEB;color:var(--muted)}
.status-chip .d{width:8px;height:8px;border-radius:50%;background:currentColor}

/* ── Bố cục 2 cột: Chỉ số &amp; biểu đồ (60%) | Thao tác nhanh (40%) ── */
.bottom-grid{display:grid;grid-template-columns:1.5fr 1fr;gap:20px;align-items:start}
@media(max-width:900px){.bottom-grid{grid-template-columns:1fr}}
.card{background:#fff;border:1px solid #E4E9E7;border-radius:16px;box-shadow:0 1px 2px rgba(4,47,46,.04),0 12px 30px -18px rgba(4,47,46,.12);margin-bottom:20px}
.card-head{padding:16px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;gap:12px}
.card-head h2{font-size:13px;font-weight:800;text-transform:uppercase;letter-spacing:.8px;color:var(--muted)}
.chart-body{padding:16px 20px}
.pf-field{padding:13px 20px;border-bottom:1px solid #EAEFED;display:flex;align-items:center;justify-content:space-between;gap:10px}
.pf-field:last-child{border-bottom:none}
.pf-label{display:flex;align-items:center;gap:9px;font-size:13px;font-weight:650;color:var(--ink)}
.pf-label .ic{font-size:15px}
.pf-value{font-size:16px;font-weight:800;color:var(--ink);font-variant-numeric:tabular-nums}
.pf-value.warn{color:var(--gold)}
.pf-value.danger{color:var(--danger)}

/* ── Thao tác nhanh (cột phải) ── */
.qa-list{padding:14px}
.qa-item{display:flex;align-items:center;gap:13px;padding:13px 14px;border-radius:12px;margin-bottom:9px;
  text-decoration:none;color:inherit;border:1px solid var(--border);background:var(--surface);transition:.15s}
.qa-item:last-child{margin-bottom:0}
.qa-item:hover{border-color:var(--main);background:#fff;box-shadow:0 4px 14px -6px rgba(15,118,110,.2)}
.qa-item.primary{background:linear-gradient(135deg,var(--main),var(--deep));border-color:transparent;color:#fff}
.qa-item.primary .qa-ic{background:rgba(255,255,255,.18);color:#fff}
.qa-ic{width:38px;height:38px;border-radius:10px;flex:none;display:grid;place-items:center;font-size:17px;background:var(--soft);color:var(--main)}
.qa-body{flex:1;min-width:0}
.qa-title{font-size:13.5px;font-weight:750}
.qa-sub{font-size:11.5px;opacity:.7;margin-top:1px}
.qa-arrow{font-size:15px;opacity:.5;flex:none}
</style>
<meta name="csrf-token" content="${csrfToken}">
<script src="${pageContext.request.contextPath}/js/csrf.js"></script>
</head>
<body class="wh">

<%@ include file="warehouse-sidebar.jsp" %>

<div class="main">
  <header class="wh-topbar">
    <div class="crumb">Trang chủ</div>
    <div class="right">
      <div class="wh-clock">
        <span id="cH">00</span><span class="sep">:</span><span id="cM">00</span>
        <span class="date" id="cDate"></span>
      </div>
      <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc"><%= initials %></a>
    </div>
  </header>

  <div class="wh-content">

    <!-- Welcome banner -->
    <div class="welcome">
      <div class="welcome-av"><%= initials %></div>
      <div class="welcome-body">
        <h2><%= greeting %>, <%= fullName %>!</h2>
        <p>Chúc bạn có một ca làm việc hiệu quả · <span id="welcomeDate"></span></p>
      </div>
      <div class="welcome-role-badge">
        <span class="wrb-icon">📦</span>
        <div class="wrb-text">Thủ kho</div>
      </div>
    </div>

    <!-- ══ Widget 1: Task & SLA Deadline — nổi bật ngay dưới banner chào hỏi ══ -->
    <c:if test="${not empty urgentTasks}">
      <div class="sla-card">
        <div class="sla-head"><span class="ic">🚨</span><strong>${urgentTasks.size()} nhiệm vụ Admin giao sắp/đã đến hạn báo xong</strong></div>
        <div class="sla-list">
          <c:forEach var="t" items="${urgentTasks}">
            <div class="sla-item">
              <div>
                <div class="si-title">${fn:escapeXml(t.title)}</div>
                <div class="si-due">Hạn: ${t.dueDateDisplay}</div>
              </div>
              <span class="badge ${t.zoneCssClass}">${t.zoneLabel}</span>
            </div>
          </c:forEach>
        </div>
        <a class="sla-cta" href="<%= ctx %>/warehouse-task?uid=<%= uid %>">Xem &amp; Báo cáo ngay →</a>
      </div>
    </c:if>

    <!-- ══ Widget 2: Cảnh báo thu hồi khẩn cấp ══ -->
    <c:if test="${not empty activeRecalls}">
      <div class="recall-card">
        <div class="recall-head"><span class="ic">🚨</span><strong>CẢNH BÁO: ${activeRecalls.size()} lô đang bị khóa khẩn cấp — cần cách ly ngay!</strong></div>
        <c:forEach var="r" items="${activeRecalls}" end="2">
          <div class="recall-item">Lô <b>${fn:escapeXml(r.batchNumber)}</b> (${fn:escapeXml(r.medicineName)}) đang bị thu hồi.</div>
        </c:forEach>
        <a class="recall-cta" href="<%= ctx %>/warehouse-recall?uid=<%= uid %>">Xem chi tiết thu hồi →</a>
      </div>
    </c:if>

    <div class="hero">
      <h1>Không gian làm việc <span>Quản lý kho</span></h1>
      <p>Nhập kho, kiểm soát tồn &amp; xử lý nhiệm vụ — mọi thao tác kho ở đây.</p>
      <% if (working) { %>
        <span class="status-chip on"><span class="d"></span> Đang trong ca làm việc</span>
      <% } else { %>
        <span class="status-chip off"><span class="d"></span> Chưa điểm danh vào ca</span>
      <% } %>
    </div>

    <div class="bottom-grid">
      <!-- ══ CỘT 1 (60%): Biểu đồ Nhập-Xuất + Tổng quan tồn kho ══ -->
      <div>
        <div class="card">
          <div class="card-head"><div class="wh-ic">📈</div><h2>Nhập - Xuất kho 7 ngày gần nhất</h2></div>
          <div class="chart-body"><canvas id="stockTrendChart" height="90"></canvas></div>
        </div>

        <div class="card">
          <div class="card-head"><div class="wh-ic">📦</div><h2>Tổng quan tồn kho</h2></div>
          <div class="pf-field">
            <span class="pf-label"><span class="ic">💊</span> Thuốc đang kinh doanh</span>
            <span class="pf-value"><%= totalMed != null ? totalMed : 0 %></span>
          </div>
          <div class="pf-field">
            <span class="pf-label"><span class="ic">📉</span> Sắp hết hàng</span>
            <span class="pf-value <%= (lowStock != null && ((Integer) lowStock) > 0) ? "warn" : "" %>"><%= lowStock != null ? lowStock : 0 %></span>
          </div>
          <div class="pf-field">
            <span class="pf-label"><span class="ic">⏳</span> Lô cận hạn dùng</span>
            <span class="pf-value <%= (expiry != null && ((Integer) expiry) > 0) ? "warn" : "" %>"><%= expiry != null ? expiry : 0 %></span>
          </div>
          <div class="pf-field">
            <span class="pf-label"><span class="ic">⛔</span> Lô đã hết hạn</span>
            <span class="pf-value <%= (expired != null && ((Integer) expired) > 0) ? "danger" : "" %>"><%= expired != null ? expired : 0 %></span>
          </div>
        </div>
      </div>

      <!-- ══ CỘT 2 (40%): Thao tác nhanh ══ -->
      <div class="card">
        <div class="card-head"><div class="wh-ic ok">⚡</div><h2>Thao tác nhanh</h2></div>
        <div class="qa-list">
          <a class="qa-item primary" href="<%= ctx %>/warehouse-stock-movement?uid=<%= uid %>">
            <div class="qa-ic">📦</div>
            <div class="qa-body"><div class="qa-title">Xuất / Điều chỉnh kho nhanh</div><div class="qa-sub">Xuất hàng, hủy hết hạn, điều chỉnh kiểm kê</div></div>
            <div class="qa-arrow">→</div>
          </a>
          <a class="qa-item" href="<%= ctx %>/warehouse-task?uid=<%= uid %>">
            <div class="qa-ic">📋</div>
            <div class="qa-body"><div class="qa-title">Cập nhật báo cáo Task</div><div class="qa-sub">Xem &amp; báo hoàn thành nhiệm vụ được giao</div></div>
            <div class="qa-arrow">→</div>
          </a>
          <a class="qa-item" href="<%= ctx %>/warehouse-reorder?uid=<%= uid %>">
            <div class="qa-ic">💡</div>
            <div class="qa-body"><div class="qa-title">Gợi ý đặt hàng (ROP)</div><div class="qa-sub">Xem đề xuất tự động, Admin duyệt phiếu nhập</div></div>
            <div class="qa-arrow">→</div>
          </a>
          <a class="qa-item" href="<%= ctx %>/staff-checkin?uid=<%= uid %>">
            <div class="qa-ic">🕒</div>
            <div class="qa-body"><div class="qa-title">Điểm danh &amp; Ca làm việc</div><div class="qa-sub"><%= currentShift != null ? "Có ca đang mở" : "Không có ca nào đang mở" %></div></div>
            <div class="qa-arrow">→</div>
          </a>
        </div>
      </div>
    </div>
  </div>
</div>

<script>
function tickClock(){
  var d=new Date(), pad=function(n){return n<10?'0'+n:n};
  document.getElementById('cH').textContent=pad(d.getHours());
  document.getElementById('cM').textContent=pad(d.getMinutes());
  var days=['CN','T2','T3','T4','T5','T6','T7'];
  document.getElementById('cDate').textContent=days[d.getDay()]+' '+pad(d.getDate())+'/'+pad(d.getMonth()+1);
  var wd=document.getElementById('welcomeDate');
  if(wd) wd.textContent=days[d.getDay()]+' '+pad(d.getDate())+'/'+pad(d.getMonth()+1)+'/'+d.getFullYear();
}
tickClock(); setInterval(tickClock,1000);
</script>

<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
<script>
(function(){
  if (typeof Chart === 'undefined') return;
  var trend = <%=request.getAttribute("stockTrendJson")%>;
  var canvas = document.getElementById('stockTrendChart');
  if (!canvas || !trend) return;
  Chart.defaults.font.family = "'Plus Jakarta Sans', sans-serif";
  Chart.defaults.color = '#69756F';
  new Chart(canvas.getContext('2d'), {
    type: 'bar',
    data: {
      labels: trend.labels,
      datasets: [
        { label: 'Nhập kho', data: trend.nhap, backgroundColor: 'rgba(5,150,105,.75)', borderRadius: 5, maxBarThickness: 22 },
        { label: 'Xuất kho', data: trend.xuat, backgroundColor: 'rgba(15,118,110,.75)', borderRadius: 5, maxBarThickness: 22 }
      ]
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: { legend: { position: 'top', labels: { boxWidth: 10, font: { size: 11.5, weight: '700' } } } },
      scales: {
        y: { beginAtZero: true, grid: { color: 'rgba(226,229,238,.6)' } },
        x: { grid: { display: false } }
      }
    }
  });
})();
</script>
</body>
</html>
