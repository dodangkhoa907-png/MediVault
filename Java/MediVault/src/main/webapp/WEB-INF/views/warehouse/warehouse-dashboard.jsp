<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%--
  warehouse-dashboard.jsp — Trang chủ Quản lý kho (Warehouse Console)

  Thiết kế lại 2026-08-02 (bản độ sâu):
  • Hero teal sâu làm điểm neo mắt đầu tiên, thay banner phẳng.
  • SIGNATURE "Đường chân trời hạn dùng": biến chi phối nghiệp vụ kho dược là SỐ
    NGÀY CÒN LẠI, nên trang chủ có một dải thời gian thật — mỗi lô là một vạch
    đặt đúng vị trí theo ngày còn lại, trên nền 4 vùng đã là quy ước của hệ thống.
    Thay cho việc thêm một biểu đồ tròn vô thưởng vô phạt.
  • Lưới 12 cột lệch (8/4, 7/5) thay vì xếp chồng các chữ nhật bằng nhau.

  Yêu cầu từ servlet: staffAcc, staffUid, totalMedicines, lowStockCount,
  expiryCount, expiredCount, currentShift, activeAtt, urgentTasks,
  activeRecalls, stockTrendJson, horizonJson.
--%>
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

    int nTotal = totalMed != null ? (Integer) totalMed : 0;
    int nLow   = lowStock != null ? (Integer) lowStock : 0;
    int nSoon  = expiry   != null ? (Integer) expiry   : 0;
    int nDead  = expired  != null ? (Integer) expired  : 0;

    Object horizonJson = request.getAttribute("horizonJson");
    String horizon = horizonJson != null ? horizonJson.toString() : "[]";

    int _hr = java.time.LocalTime.now().getHour();
    String greeting = _hr < 12 ? "Chào buổi sáng" : _hr < 18 ? "Chào buổi chiều" : "Chào buổi tối";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Trang chủ Quản lý kho — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400..800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= ctx %>/css/staff-portal.css">
<link rel="stylesheet" href="<%= ctx %>/css/warehouse-portal.css?v=11">
<style>
a{text-decoration:none;color:inherit}
.wh-shell{max-width:1560px}

/* Thẻ KPI trên trang chủ là LỐI TẮT (không phải bộ lọc như trang Tồn kho) nên
   bỏ dòng mô tả, giữ 4 thẻ trên một hàng để mắt quét ngang một nhịp. */
.wh-kpis.compact{margin-bottom:24px}
.wh-kpis.compact .wh-kpi{padding:17px 18px}
.wh-kpis.compact .wh-kpi .num{font-size:28px}

.chart-body{padding:20px 22px 22px}
.hz-empty{padding:26px 22px;text-align:center;color:var(--muted);font-size:13.5px}

/* Hoạt động gần đây: dòng nhỏ, mốc thời gian bên phải */
.act-row{display:flex;align-items:center;gap:13px;padding:13px 22px;border-bottom:1px solid var(--line)}
.act-row:last-child{border-bottom:none}
.act-row .bd{flex:1;min-width:0}
.act-row .t1{font-size:13px;font-weight:750;color:var(--ink);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.act-row .t2{font-size:11.5px;color:var(--muted);margin-top:2px}
.act-row .n{font-size:14px;font-weight:800;font-variant-numeric:tabular-nums;flex:none}
</style>
<meta name="csrf-token" content="${csrfToken}">
<script src="<%= ctx %>/js/csrf.js"></script>
<script src="<%= ctx %>/js/warehouse-ui.js" defer></script>
</head>
<body class="wh">
<%@ include file="/WEB-INF/views/icons.jsp" %>
<%@ include file="warehouse-sidebar.jsp" %>

<div class="main">
  <header class="wh-topbar">
    <div class="crumb">Tổng quan</div>
    <div class="right">
      <div class="wh-clock">
        <span id="cH">00</span><span class="sep">:</span><span id="cM">00</span>
        <span class="date" id="cDate"></span>
      </div>
      <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc của <%= fullName %>"><%= initials %></a>
    </div>
  </header>

  <div class="wh-shell wh-anim">

    <!-- ══ HERO ══ -->
    <div class="wh-hero">
        <div class="wh-hero-row">
          <div class="wh-hero-av"><%= initials %></div>
          <div class="wh-hero-bd">
            <h1><%= greeting %>, <%= fullName %></h1>
            <p class="sub">Nhập kho, kiểm soát tồn theo lô và xử lý nhiệm vụ — mọi thao tác kho ở một nơi.
              <span id="helloDate"></span></p>
          </div>
          <span class="wh-chip <%= working ? "on" : "off" %>">
            <span class="d"></span> <%= working ? "Đang trong ca làm việc" : "Chưa điểm danh vào ca" %>
          </span>
      </div>
    </div>

    <!-- ══ Cảnh báo phải xử lý ngay — luôn nằm trên mọi thứ khác ══ -->
    <c:if test="${not empty activeRecalls}">
      <div class="wh-note danger" role="alert">
        <svg><use href="#ic-siren"/></svg>
        <span>
          <b>${activeRecalls.size()} lô đang bị thu hồi khẩn cấp</b> — cần cách ly khỏi kệ ngay.
          <c:forEach var="r" items="${activeRecalls}" end="2">
            <br>Lô <b>${fn:escapeXml(r.batchNumber)}</b> — ${fn:escapeXml(r.medicineName)}.
          </c:forEach>
          <br><a href="<%= ctx %>/warehouse-recall" style="font-weight:800;text-decoration:underline">Xem chi tiết thu hồi →</a>
        </span>
      </div>
    </c:if>

    <c:if test="${not empty urgentTasks}">
      <div class="wh-note warn">
        <svg><use href="#ic-clock-alert"/></svg>
        <span>
          <b>${urgentTasks.size()} nhiệm vụ Admin giao sắp hoặc đã đến hạn báo cáo.</b>
          <c:forEach var="t" items="${urgentTasks}">
            <br>${fn:escapeXml(t.title)} — hạn ${t.dueDateDisplay} <span class="wh-badge ${t.zoneCssClass}">${t.zoneLabel}</span>
          </c:forEach>
          <br><a href="<%= ctx %>/warehouse-task" style="font-weight:800;text-decoration:underline">Xem &amp; báo cáo ngay →</a>
        </span>
      </div>
    </c:if>

    <!-- ══ 4 chỉ số — mỗi thẻ là lối tắt tới đúng lát cắt bên Tồn kho ══ -->
    <div class="wh-kpis compact">
      <a class="wh-kpi k-total" href="<%= ctx %>/warehouse-inventory">
        <span class="ic"><svg><use href="#ic-pill"/></svg></span>
        <span class="body">
          <span class="num"><%= nTotal %></span>
          <span class="lbl">Thuốc đang kinh doanh</span>
        </span>
      </a>
      <a class="wh-kpi k-low <%= nLow == 0 ? "is-zero" : "" %>" href="<%= ctx %>/warehouse-inventory">
        <span class="ic"><svg><use href="#ic-trend-down"/></svg></span>
        <span class="body">
          <span class="num"><%= nLow %></span>
          <span class="lbl">Sắp hết hàng</span>
        </span>
      </a>
      <a class="wh-kpi k-soon <%= nSoon == 0 ? "is-zero" : "" %>" href="<%= ctx %>/warehouse-reorder">
        <span class="ic"><svg><use href="#ic-clock-alert"/></svg></span>
        <span class="body">
          <span class="num"><%= nSoon %></span>
          <span class="lbl">Lô cận hạn</span>
        </span>
      </a>
      <a class="wh-kpi k-dead <%= nDead == 0 ? "is-zero" : "" %>" href="<%= ctx %>/warehouse-inventory">
        <span class="ic"><svg><use href="#ic-ban"/></svg></span>
        <span class="body">
          <span class="num"><%= nDead %></span>
          <span class="lbl">Lô đã hết hạn</span>
        </span>
      </a>
    </div>

    <!-- ══ Lưới lệch 8/4 ══ -->
    <div class="wh-g12">

      <!-- ── SIGNATURE: Đường chân trời hạn dùng ── -->
      <div class="c8">
        <div class="wh-card" style="margin-bottom:0">
          <div class="wh-card-head">
            <div class="wh-ic warn"><svg><use href="#ic-clock-alert"/></svg></div>
            <div class="tt">
              <h2>Đường chân trời hạn dùng</h2>
              <div class="desc">Mỗi vạch là một lô còn tồn, đặt theo số ngày còn lại trước hạn.</div>
            </div>
            <div class="sp">
              <a class="wh-btn" href="<%= ctx %>/warehouse-reorder">
                Xử lý <svg><use href="#ic-arrow-right"/></svg>
              </a>
            </div>
          </div>
          <div class="wh-horizon">
            <div class="wh-hz-track" id="hzTrack" role="img" aria-label="Phân bố lô theo số ngày còn lại trước hạn dùng">
              <div class="wh-hz-zone" style="left:0;width:14%">
                <span class="zl" style="color:#B91C1C">Quá hạn</span>
                <span class="zn" id="hzN0" style="color:#B91C1C">0</span>
              </div>
              <div class="wh-hz-zone" style="left:14%;width:22%">
                <span class="zl" style="color:#92400E">≤ 30 ngày</span>
                <span class="zn" id="hzN1" style="color:#92400E">0</span>
              </div>
              <div class="wh-hz-zone" style="left:36%;width:24%">
                <span class="zl" style="color:#A16207">31–90 ngày</span>
                <span class="zn" id="hzN2" style="color:#A16207">0</span>
              </div>
              <div class="wh-hz-zone" style="left:60%;width:40%">
                <span class="zl" style="color:#047857">Trên 90 ngày</span>
                <span class="zn" id="hzN3" style="color:#047857">0</span>
              </div>
            </div>
            <div class="wh-hz-legend">
              <span><i style="background:#DC2626"></i> Quá hạn — xuất huỷ</span>
              <span><i style="background:#F59E0B"></i> Cách ly — ngừng bán</span>
              <span><i style="background:#CA8A04"></i> Ưu tiên bán trước</span>
              <span><i style="background:#10B981"></i> An toàn</span>
            </div>
          </div>
          <div class="hz-empty" id="hzEmpty" hidden>
            Không có lô nào trong vùng cảnh báo. Toàn bộ hàng trong kho còn hạn dài. 🎉
          </div>
        </div>
      </div>

      <!-- ── Thao tác nhanh ── -->
      <div class="c4">
        <div class="wh-card" style="margin-bottom:0">
          <div class="wh-card-head">
            <div class="wh-ic ok"><svg><use href="#ic-zap"/></svg></div>
            <div class="tt">
              <h2>Thao tác nhanh</h2>
              <div class="desc">Việc hay làm nhất trong ca.</div>
            </div>
          </div>
          <div class="wh-quick">
            <a class="primary" href="<%= ctx %>/warehouse-stock-movement">
              <span class="ic"><svg><use href="#ic-out"/></svg></span>
              <span class="bd">
                <span class="t1">Xuất / Điều chỉnh kho</span>
                <span class="t2">Xuất hàng, huỷ hết hạn, chỉnh sau kiểm kê</span>
              </span>
              <svg class="go"><use href="#ic-arrow-right"/></svg>
            </a>
            <a href="<%= ctx %>/warehouse-import">
              <span class="ic"><svg><use href="#ic-box-in"/></svg></span>
              <span class="bd">
                <span class="t1">Nhập lô mới</span>
                <span class="t2">Ghi nhận hàng vừa về kho</span>
              </span>
              <svg class="go"><use href="#ic-arrow-right"/></svg>
            </a>
            <a href="<%= ctx %>/warehouse-task">
              <span class="ic"><svg><use href="#ic-clipboard"/></svg></span>
              <span class="bd">
                <span class="t1">Nhiệm vụ &amp; SOP</span>
                <span class="t2">Báo hoàn thành việc được giao</span>
              </span>
              <svg class="go"><use href="#ic-arrow-right"/></svg>
            </a>
            <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>">
              <span class="ic"><svg><use href="#ic-clock"/></svg></span>
              <span class="bd">
                <span class="t1">Điểm danh &amp; Ca làm việc</span>
                <span class="t2"><%= currentShift != null ? "Có ca đang mở" : "Không có ca nào đang mở" %></span>
              </span>
              <svg class="go"><use href="#ic-arrow-right"/></svg>
            </a>
          </div>
        </div>
      </div>

      <!-- ── Biểu đồ Nhập–Xuất ── -->
      <div class="c7">
        <div class="wh-card" style="margin-bottom:0">
          <div class="wh-card-head">
            <div class="wh-ic info"><svg><use href="#ic-bar-chart"/></svg></div>
            <div class="tt">
              <h2>Nhập &ndash; Xuất kho</h2>
              <div class="desc">Lượng hàng vào và ra kho trong 7 ngày gần nhất.</div>
            </div>
          </div>
          <div class="chart-body"><canvas id="stockTrendChart" height="120"></canvas></div>
        </div>
      </div>

      <!-- ── Lô cần chú ý sớm nhất ── -->
      <div class="c5">
        <div class="wh-card" style="margin-bottom:0">
          <div class="wh-card-head">
            <div class="wh-ic danger"><svg><use href="#ic-package"/></svg></div>
            <div class="tt">
              <h2>Cần xử lý sớm nhất</h2>
              <div class="desc">5 lô có hạn dùng gần nhất còn tồn trong kho.</div>
            </div>
          </div>
          <div id="soonList"></div>
        </div>
      </div>

    </div>
  </div>
</div>

<script>
function tickClock(){
  var d = new Date(), pad = function(n){ return n < 10 ? '0' + n : n; };
  document.getElementById('cH').textContent = pad(d.getHours());
  document.getElementById('cM').textContent = pad(d.getMinutes());
  var days = ['CN','T2','T3','T4','T5','T6','T7'];
  document.getElementById('cDate').textContent = days[d.getDay()] + ' ' + pad(d.getDate()) + '/' + pad(d.getMonth() + 1);
  var wd = document.getElementById('helloDate');
  if (wd) wd.textContent = '· ' + days[d.getDay()] + ' ' + pad(d.getDate()) + '/' + pad(d.getMonth() + 1) + '/' + d.getFullYear();
}
tickClock(); setInterval(tickClock, 1000);
</script>

<script>
/* ══ Đường chân trời hạn dùng ══════════════════════════════════════════════
   Trục KHÔNG tuyến tính theo ngày. Nếu chia đều 0→365 thì toàn bộ vùng nguy
   hiểm (0–30 ngày) bị nén vào 8% bề ngang bên trái — đúng chỗ cần nhìn rõ nhất
   lại nhỏ nhất. Nên mỗi vùng được cấp một khoảng cố định, rộng theo mức độ
   khẩn chứ không theo độ dài thời gian. */
(function () {
  'use strict';
  var data = <%= horizon %>;
  var track = document.getElementById('hzTrack');
  if (!track) return;

  var ZONES = [
    { max: -1,   from: 0,  to: 14,  color: '#DC2626', n: 0 },   // quá hạn
    { max: 30,   from: 14, to: 36,  color: '#F59E0B', n: 0 },   // ≤30 — cách ly
    { max: 90,   from: 36, to: 60,  color: '#CA8A04', n: 0 },   // 31–90 — ưu tiên bán
    { max: 1e9,  from: 60, to: 100, color: '#10B981', n: 0 }    // >90 — an toàn
  ];
  function zoneOf(d){ for (var i = 0; i < ZONES.length; i++) if (d <= ZONES[i].max) return i; return 3; }

  data.forEach(function (b) {
    var zi = zoneOf(b.d), z = ZONES[zi];
    z.n++;
    // Vị trí trong vùng: phân bố đều theo thứ tự để các vạch không chồng khít
    // lên nhau khi nhiều lô có cùng số ngày.
    var span = z.to - z.from;
    var pct = z.from + span * (0.12 + 0.76 * Math.random());
    var tick = document.createElement('div');
    tick.className = 'wh-hz-tick';
    tick.style.left = pct.toFixed(2) + '%';
    tick.style.background = z.color;
    tick.title = b.n + ' · Lô ' + b.b + ' · tồn ' + b.q +
                 (b.d < 0 ? ' · quá hạn ' + Math.abs(b.d) + ' ngày' : ' · còn ' + b.d + ' ngày');
    track.appendChild(tick);
  });

  ZONES.forEach(function (z, i) {
    var el = document.getElementById('hzN' + i);
    if (el) el.textContent = z.n;
  });

  if (!data.length) {
    track.parentNode.hidden = true;
    document.getElementById('hzEmpty').hidden = false;
  }

  /* ── Danh sách 5 lô gấp nhất — cùng nguồn dữ liệu, không truy vấn thêm ── */
  var list = document.getElementById('soonList');
  var top5 = data.slice().sort(function (a, b) { return a.d - b.d; }).slice(0, 5);
  if (!top5.length) {
    list.innerHTML = '<div class="wh-empty good"><div class="art">🎉</div>' +
      '<div class="t">Không có lô nào cần gấp</div>' +
      '<div class="d">Không lô nào sắp hết hạn hoặc quá hạn còn tồn trong kho.</div></div>';
    return;
  }
  list.innerHTML = top5.map(function (b) {
    var over = b.d < 0;
    var cls = over ? 'out' : (b.d <= 30 ? 'low' : 'soon');
    var label = over ? 'Quá hạn ' + Math.abs(b.d) + 'n' : 'Còn ' + b.d + 'n';
    return '<div class="act-row">' +
      '<span class="wh-ic sm ' + (over ? 'danger' : 'warn') + '"><svg><use href="#' +
        (over ? 'ic-ban' : 'ic-clock-alert') + '"/></svg></span>' +
      '<span class="bd"><span class="t1">' + esc(b.n) + '</span>' +
      '<span class="t2">Lô ' + esc(b.b) + ' · tồn ' + b.q + '</span></span>' +
      '<span class="wh-badge ' + cls + '">' + label + '</span></div>';
  }).join('');

  function esc(s){
    return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
      return ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' })[c];
    });
  }
})();
</script>

<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
<script>
(function(){
  if (typeof Chart === 'undefined') return;
  var trend = <%= request.getAttribute("stockTrendJson") %>;
  var canvas = document.getElementById('stockTrendChart');
  if (!canvas || !trend) return;
  Chart.defaults.font.family = "'Plus Jakarta Sans', sans-serif";
  Chart.defaults.color = '#69756F';
  var ctx2 = canvas.getContext('2d');
  var gIn = ctx2.createLinearGradient(0, 0, 0, 220);
  gIn.addColorStop(0, 'rgba(16,185,129,.95)'); gIn.addColorStop(1, 'rgba(16,185,129,.45)');
  var gOut = ctx2.createLinearGradient(0, 0, 0, 220);
  gOut.addColorStop(0, 'rgba(15,118,110,.95)'); gOut.addColorStop(1, 'rgba(15,118,110,.42)');
  new Chart(ctx2, {
    type: 'bar',
    data: {
      labels: trend.labels,
      datasets: [
        { label: 'Nhập kho', data: trend.nhap, backgroundColor: gIn,  borderRadius: 8, maxBarThickness: 26 },
        { label: 'Xuất kho', data: trend.xuat, backgroundColor: gOut, borderRadius: 8, maxBarThickness: 26 }
      ]
    },
    options: {
      responsive: true, maintainAspectRatio: false,
      plugins: {
        legend: { position: 'top', align: 'end',
          labels: { boxWidth: 10, boxHeight: 10, usePointStyle: true, pointStyle: 'circle',
                    padding: 16, font: { size: 12, weight: '700' } } },
        tooltip: { backgroundColor: '#0B1F1D', padding: 12, cornerRadius: 12, displayColors: true,
                   titleFont: { size: 12.5, weight: '800' }, bodyFont: { size: 12.5 } }
      },
      scales: {
        y: { beginAtZero: true, border: { display: false },
             grid: { color: 'rgba(226,231,229,.75)' }, ticks: { precision: 0, padding: 8 } },
        x: { border: { display: false }, grid: { display: false }, ticks: { padding: 6 } }
      }
    }
  });
})();
</script>
</body>
</html>
