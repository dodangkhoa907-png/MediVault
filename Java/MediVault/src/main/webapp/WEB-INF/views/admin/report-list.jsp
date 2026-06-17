<%@ page contentType="text/html;charset=UTF-8" %>
<% String activeNav = "reports"; %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    java.lang.String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    java.lang.String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();

    Integer expiryCount = (Integer) request.getAttribute("expiryCount");
    if (expiryCount == null) expiryCount = 0;

    java.math.BigDecimal grossRevenue = (java.math.BigDecimal) request.getAttribute("grossRevenue");
    java.math.BigDecimal discount     = (java.math.BigDecimal) request.getAttribute("discount");
    java.math.BigDecimal refund       = (java.math.BigDecimal) request.getAttribute("refund");
    java.math.BigDecimal cogs         = (java.math.BigDecimal) request.getAttribute("cogs");
    java.math.BigDecimal netRevenue   = (java.math.BigDecimal) request.getAttribute("netRevenue");
    java.math.BigDecimal grossProfit  = (java.math.BigDecimal) request.getAttribute("grossProfit");
    if (grossRevenue == null) grossRevenue = java.math.BigDecimal.ZERO;
    if (discount     == null) discount     = java.math.BigDecimal.ZERO;
    if (refund        == null) refund        = java.math.BigDecimal.ZERO;
    if (cogs          == null) cogs          = java.math.BigDecimal.ZERO;
    if (netRevenue    == null) netRevenue    = java.math.BigDecimal.ZERO;
    if (grossProfit   == null) grossProfit   = java.math.BigDecimal.ZERO;
    Integer invoiceCount = (Integer) request.getAttribute("invoiceCount");
    if (invoiceCount == null) invoiceCount = 0;

    Integer repMonth = (Integer) request.getAttribute("repMonth");
    Integer repYear  = (Integer) request.getAttribute("repYear");
    if (repMonth == null) repMonth = java.time.LocalDate.now().getMonthValue();
    if (repYear  == null) repYear  = java.time.LocalDate.now().getYear();

    Double netRevenuePct  = (Double) request.getAttribute("netRevenuePct");
    Double grossProfitPct = (Double) request.getAttribute("grossProfitPct");
    Double cogsPct        = (Double) request.getAttribute("cogsPct");
    Double deductPct      = (Double) request.getAttribute("deductPct");

    boolean profitPositive = grossProfit.compareTo(java.math.BigDecimal.ZERO) >= 0;
%>
<%!
    /** Badge nhỏ "▲ 12.4% so tháng trước" — null nếu tháng trước không có dữ liệu để so sánh. */
    private String trendBadgeHtml(Double pct, boolean invertColor) {
        if (pct == null) return "<span style=\"font-size:10.5px;color:#B8C4D9;margin-top:4px;display:inline-block\">Chưa có dữ liệu tháng trước</span>";
        boolean up = pct >= 0;
        boolean good = invertColor ? !up : up; // với Giá vốn: tăng = xấu (đỏ), giảm = tốt (xanh)
        String color = good ? "#059669" : "#DC2626";
        String bg    = good ? "rgba(5,150,105,.1)" : "rgba(220,38,38,.1)";
        String arrow = up ? "▲" : "▼";
        String val   = String.format("%.1f", Math.abs(pct));
        return "<span style=\"display:inline-flex;align-items:center;gap:3px;font-size:10.5px;font-weight:700;padding:2px 8px;border-radius:20px;background:" + bg + ";color:" + color + ";margin-top:5px\">" + arrow + " " + val + "% so tháng trước</span>";
    }
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Báo cáo doanh thu — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;--cyan-soft:#EBF8FD;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;--amber:#F59E0B;--purple:#7C3AED;
  --sidebar:232px;--radius:14px;
}
html,body{height:100%;font-family:'Outfit',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}

/* SIDEBAR */
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-text{font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-text span{color:var(--cyan)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:12px 0 4px;flex-shrink:0}
.nav-label{font-size:9px;font-weight:700;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:500;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.14);font-weight:600}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--cyan);border-radius:2px}
.nav-icon{width:18px;text-align:center;font-size:14px;flex-shrink:0;opacity:.8}
.nav-item.active .nav-icon{opacity:1}
.nav-badge{margin-left:auto;background:#DC2626;color:#fff;font-size:10px;font-weight:700;padding:1px 7px;border-radius:20px;min-width:20px;text-align:center}

/* MAIN */
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0}
.topbar{height:60px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50;flex-shrink:0}
.topbar-left{display:flex;align-items:center;gap:10px}
.topbar-icon{width:34px;height:34px;border-radius:9px;background:linear-gradient(135deg,rgba(21,88,168,.12),rgba(58,189,224,.12));display:flex;align-items:center;justify-content:center;font-size:15px}
.topbar-title{font-size:16px;font-weight:800;color:var(--ink)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.topbar-pill{display:inline-flex;align-items:center;gap:6px;padding:4px 12px;border-radius:20px;font-size:12.5px;font-weight:700;white-space:nowrap}
.pill-period{background:#EFF6FF;color:var(--blue)}
.pill-invoice{background:#ECFDF5;color:var(--green)}
.topbar-user{display:flex;align-items:center;gap:8px;padding:5px 12px 5px 7px;border:1.5px solid var(--border);border-radius:20px;text-decoration:none;color:inherit;transition:all .18s}
.topbar-user:hover{border-color:var(--cyan)}
.topbar-av{width:26px;height:26px;border-radius:7px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:10px;font-weight:800;color:#fff}
.topbar-name{font-size:12.5px;font-weight:600;color:var(--navy)}
.content{padding:22px 26px;flex:1;min-width:0}

/* PAGE HEAD + FILTER */
.page-head{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:20px;flex-wrap:wrap;gap:12px}
.page-head-left .breadcrumb{font-size:11.5px;color:var(--muted);font-weight:500;margin-bottom:4px}
.page-head-left h1{font-size:26px;color:var(--ink)}
.month-filter{display:flex;gap:8px;align-items:center;background:var(--white);border:1px solid var(--border);border-radius:12px;padding:6px;}
.month-filter select{border:none;background:transparent;border-radius:8px;padding:7px 10px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;color:var(--ink);outline:none;cursor:pointer}
.month-filter select:hover{background:var(--surface)}

/* KPI STRIP */
.kpi-strip{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-bottom:16px}
.kpi{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);padding:14px 18px;display:flex;align-items:center;gap:12px;position:relative;overflow:hidden}
.kpi-icon{width:40px;height:40px;border-radius:11px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0}
.kpi-blue{background:#EFF6FF}.kpi-green{background:#ECFDF5}.kpi-amber{background:#FFFBEB}.kpi-purple{background:#F5F3FF}.kpi-red{background:#FEF2F2}
.kpi-num{font-size:21px;font-weight:900;line-height:1.15;white-space:nowrap}
.kpi-lbl{font-size:11px;color:var(--muted);font-weight:600;text-transform:uppercase;letter-spacing:.4px;margin-top:3px}

/* SECTION HEAD */
.section-head{display:flex;align-items:center;gap:8px;margin:26px 0 14px}
.section-head h2{font-size:15px;font-weight:800;color:var(--ink)}
.section-head .line{flex:1;height:1px;background:var(--border)}

/* CHART GRID */
.chart-grid{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:20px}
.chart-card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}
.chart-card-head{padding:14px 18px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:8px}
.chart-card-head h3{font-size:13.5px;font-weight:700;color:var(--ink)}
.chart-card-body{padding:14px 18px;height:240px}
.chart-legend{display:flex;gap:14px;padding:8px 18px 12px;flex-wrap:wrap}
.leg-item{display:flex;align-items:center;gap:5px;font-size:11.5px;font-weight:600;color:var(--muted)}
.leg-dot{width:10px;height:10px;border-radius:3px;flex-shrink:0}
.view-toggle{display:flex;background:#F1F5FB;border-radius:8px;padding:3px;gap:2px}
.vt-btn{padding:5px 12px;border-radius:6px;border:none;font-family:'Outfit',sans-serif;font-size:12px;font-weight:600;cursor:pointer;background:transparent;color:var(--muted)}
.vt-btn.active{background:#fff;color:var(--blue);box-shadow:0 1px 4px rgba(0,0,0,.1)}

/* INFO BOX (đối soát quỹ ca) */
.info-box{background:#EFF6FF;border:1px solid #BFDBFE;border-radius:10px;padding:12px 16px;margin-bottom:16px;font-size:12.5px;color:#1558A8;display:flex;gap:10px;align-items:flex-start}

/* TABLE */
.table-card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}
.table-card-head{padding:14px 20px;border-bottom:1px solid var(--border)}
.table-card-head h2{font-size:14px;font-weight:800;color:var(--ink)}
.table-card-sub{font-size:12px;color:var(--muted)}
.tbl-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse}
thead th{padding:10px 16px;background:#F8FAFC;font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;white-space:nowrap;border-bottom:1px solid var(--border)}
tbody td{padding:11px 16px;font-size:13px;color:var(--ink);border-bottom:1px solid #F1F5F9;vertical-align:middle}
tbody tr:last-child td{border-bottom:none}
tbody tr:hover td{background:#F7FBFF}
.empty-row{text-align:center;padding:40px;color:var(--muted)}
</style>
</head>
<body>

<%-- ── SIDEBAR ── --%>
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">
  <header class="topbar">
    <div class="topbar-left">
      <div class="topbar-icon">📊</div>
      <div class="topbar-title">Báo cáo doanh thu</div>
    </div>
    <div class="topbar-right">
      <span class="topbar-pill pill-period">🗓️ Tháng <%= repMonth %>/<%= repYear %></span>
      <span class="topbar-pill pill-invoice">🧾 <%= invoiceCount %> hóa đơn</span>
      <a href="${pageContext.request.contextPath}/dashboard" class="topbar-user">
        <div class="topbar-av"><%= initials %></div>
        <span class="topbar-name"><%= fullName %></span>
      </a>
    </div>
  </header>

  <div class="content">

    <div class="page-head">
      <div class="page-head-left">
        <div class="breadcrumb">medicare › Phân tích › Báo cáo</div>
        <h1>Báo cáo doanh thu</h1>
      </div>
      <form method="get" action="${pageContext.request.contextPath}/reports" class="month-filter">
        <select name="month" onchange="this.form.submit()">
          <c:forEach begin="1" end="12" var="m">
            <option value="${m}" ${m == repMonth ? 'selected' : ''}>Tháng ${m}</option>
          </c:forEach>
        </select>
        <select name="year" onchange="this.form.submit()">
          <option value="2025" ${repYear == 2025 ? 'selected' : ''}>2025</option>
          <option value="2026" ${repYear == 2026 ? 'selected' : ''}>2026</option>
          <option value="2027" ${repYear == 2027 ? 'selected' : ''}>2027</option>
        </select>
      </form>
    </div>

    <%-- ════════════════ KPI TÀI CHÍNH ════════════════ --%>
    <div class="kpi-strip">
      <div class="kpi" style="flex-direction:column;align-items:flex-start;gap:2px">
        <div style="display:flex;align-items:center;gap:12px;width:100%">
          <div class="kpi-icon kpi-blue">💵</div>
          <div>
            <div class="kpi-num"><fmt:formatNumber value="${netRevenue}" type="number" maxFractionDigits="0"/>đ</div>
            <div class="kpi-lbl">Doanh thu thuần</div>
          </div>
        </div>
        <%= trendBadgeHtml(netRevenuePct, false) %>
      </div>
      <div class="kpi" style="flex-direction:column;align-items:flex-start;gap:2px">
        <div style="display:flex;align-items:center;gap:12px;width:100%">
          <div class="kpi-icon kpi-amber">📦</div>
          <div>
            <div class="kpi-num"><fmt:formatNumber value="${cogs}" type="number" maxFractionDigits="0"/>đ</div>
            <div class="kpi-lbl">Giá vốn hàng bán</div>
          </div>
        </div>
        <%= trendBadgeHtml(cogsPct, true) %>
      </div>
      <div class="kpi" style="flex-direction:column;align-items:flex-start;gap:2px">
        <div style="display:flex;align-items:center;gap:12px;width:100%">
          <div class="kpi-icon <%= profitPositive ? "kpi-green" : "kpi-red" %>">📈</div>
          <div>
            <div class="kpi-num" style="color:<%= profitPositive ? "#059669" : "#DC2626" %>">
              <fmt:formatNumber value="${grossProfit}" type="number" maxFractionDigits="0"/>đ
            </div>
            <div class="kpi-lbl">Lợi nhuận gộp</div>
          </div>
        </div>
        <%= trendBadgeHtml(grossProfitPct, false) %>
      </div>
      <div class="kpi" style="flex-direction:column;align-items:flex-start;gap:2px">
        <div style="display:flex;align-items:center;gap:12px;width:100%">
          <div class="kpi-icon kpi-purple">🔻</div>
          <div>
            <div class="kpi-num"><fmt:formatNumber value="${discount + refund}" type="number" maxFractionDigits="0"/>đ</div>
            <div class="kpi-lbl">Giảm giá &amp; trả hàng</div>
          </div>
        </div>
        <span style="font-size:10.5px;color:var(--muted);margin-top:5px"><% if (deductPct != null) { %><%= String.format("%.1f", deductPct) %>% doanh thu gộp<% } else { %>—<% } %></span>
      </div>
    </div>

    <%-- ════════════════ HERO CHART: Doanh thu — Giá vốn — Lợi nhuận gộp ════════════════ --%>
    <div class="chart-card" style="margin-bottom:16px">
      <div class="chart-card-head">
        <h3>📊 Doanh thu — Giá vốn — Lợi nhuận gộp theo ngày</h3>
        <span style="font-size:11.5px;color:var(--muted)">Khoảng cách giữa cột xanh dương và cột xám càng lớn → lợi nhuận càng cao</span>
      </div>
      <div class="chart-card-body" style="height:280px"><canvas id="financeChart"></canvas></div>
      <div class="chart-legend">
        <span class="leg-item"><span class="leg-dot" style="background:#1558A8"></span> Doanh thu</span>
        <span class="leg-item"><span class="leg-dot" style="background:#94A3B8"></span> Giá vốn</span>
        <span class="leg-item"><span class="leg-dot" style="background:#059669"></span> Lợi nhuận gộp</span>
      </div>
    </div>

    <%-- ════════════════ CHARTS: Giảm trừ + Giờ vàng ════════════════ --%>
    <div class="chart-grid">
      <div class="chart-card">
        <div class="chart-card-head">
          <h3>🌊 Các khoản giảm trừ doanh thu</h3>
        </div>
        <div class="chart-card-body"><canvas id="waterfallChart"></canvas></div>
        <c:if test="${refund == 0}">
          <div style="padding:0 18px 12px;font-size:11px;color:#7C6FAA">⚠️ Chưa có luồng xử lý "trả hàng" nên mục này hiện luôn 0đ.</div>
        </c:if>
      </div>
      <div class="chart-card">
        <div class="chart-card-head"><h3>🕐 Doanh thu theo khung giờ (giờ vàng)</h3></div>
        <div class="chart-card-body"><canvas id="peakHourChart"></canvas></div>
      </div>
    </div>

    <%-- ════════════════ CHARTS: Hãng sản xuất + Nhóm thuốc ════════════════ --%>
    <div class="chart-grid">
      <div class="chart-card">
        <div class="chart-card-head"><h3>🏭 Doanh thu theo Hãng sản xuất (Top 7)</h3></div>
        <div class="chart-card-body" style="height:300px"><canvas id="mfgChart"></canvas></div>
      </div>
      <div class="chart-card">
        <div class="chart-card-head"><h3>💊 Doanh thu theo Nhóm thuốc</h3></div>
        <div class="chart-card-body"><canvas id="catChart"></canvas></div>
      </div>
    </div>

    <%-- ════════════════ ĐỐI SOÁT QUỸ CA (chuyển từ shift-list.jsp) ════════════════ --%>
    <div class="section-head"><h2>💼 Đối soát quỹ ca làm việc</h2><div class="line"></div></div>

    <div class="info-box">
      <span style="font-size:15px;flex-shrink:0">💡</span>
      <div>
        <strong>Lưu ý:</strong> phần này KHÔNG phải doanh thu thực — đây là đối soát quỹ tiền mặt
        <strong>nội bộ giữa các nhân viên</strong> khi giao/nhận ca: Tiền cuối ca − Tiền đầu ca.
        Doanh thu thực của nhà thuốc (từ hóa đơn) được tính ở các thẻ và biểu đồ phía trên.
      </div>
    </div>

    <div class="kpi-strip">
      <div class="kpi">
        <div class="kpi-icon kpi-blue">📥</div>
        <div><div class="kpi-num" id="kpiOpening">—</div><div class="kpi-lbl">Tổng tiền đầu ca</div></div>
      </div>
      <div class="kpi">
        <div class="kpi-icon kpi-green">📤</div>
        <div><div class="kpi-num" id="kpiClosing">—</div><div class="kpi-lbl">Tổng tiền cuối ca</div></div>
      </div>
      <div class="kpi">
        <div class="kpi-icon kpi-amber">💰</div>
        <div><div class="kpi-num" id="kpiDiff">—</div><div class="kpi-lbl">Chênh lệch</div></div>
      </div>
      <div class="kpi">
        <div class="kpi-icon kpi-purple">📅</div>
        <div><div class="kpi-num" id="kpiDays">—</div><div class="kpi-lbl">Ngày có ca</div></div>
      </div>
    </div>

    <div class="chart-card" style="margin-bottom:20px">
      <div class="chart-card-head">
        <h3>📊 Đối soát quỹ theo ca</h3>
        <div class="view-toggle">
          <button id="btnLine" class="vt-btn active" onclick="setCashChartType('line')">Đường</button>
          <button id="btnBar"  class="vt-btn"        onclick="setCashChartType('bar')">Cột</button>
        </div>
      </div>
      <div class="chart-card-body"><canvas id="cashChart"></canvas></div>
      <div class="chart-legend">
        <span class="leg-item"><span class="leg-dot" style="background:#1558A8"></span> Tiền đầu ca</span>
        <span class="leg-item"><span class="leg-dot" style="background:#059669"></span> Tiền cuối ca</span>
      </div>
    </div>

    <div class="table-card">
      <div class="table-card-head">
        <h2>📋 Chi tiết đối soát từng ca</h2>
        <span class="table-card-sub">Chỉ hiển thị ca đã đóng — chênh lệch = tiền cuối − tiền đầu</span>
      </div>
      <div class="tbl-wrap">
        <table>
          <thead>
            <tr>
              <th>#</th><th>Nhân viên</th><th>Ngày</th><th>Bắt đầu</th><th>Kết thúc</th>
              <th>Tiền đầu ca</th><th>Tiền cuối ca</th><th>Chênh lệch</th>
            </tr>
          </thead>
          <tbody>
            <c:if test="${empty monthShifts}">
              <tr><td colspan="8" class="empty-row">Chưa có ca nào trong tháng này.</td></tr>
            </c:if>
            <c:forEach var="s" items="${monthShifts}">
              <c:if test="${not empty s.endTime}">
                <tr>
                  <td style="color:var(--muted);font-size:12px">#${s.shiftId}</td>
                  <td><div style="font-weight:700">${accountMap[s.accountId] != null ? accountMap[s.accountId].fullName : 'ID '.concat(s.accountId)}</div></td>
                  <td style="font-size:12.5px;color:var(--muted)">${fn:substring(s.startTime.toString(),0,10)}</td>
                  <td style="font-weight:600">${fn:substring(s.startTime.toString(),11,16)}</td>
                  <td style="font-weight:600">${fn:substring(s.endTime.toString(),11,16)}</td>
                  <td>
                    <c:choose>
                      <c:when test="${s.openingCash != null}"><span style="font-weight:600"><fmt:formatNumber value="${s.openingCash}" type="number" maxFractionDigits="0"/>đ</span></c:when>
                      <c:otherwise><span style="color:var(--muted)">0đ</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${s.closingCash != null}"><span style="font-weight:600"><fmt:formatNumber value="${s.closingCash}" type="number" maxFractionDigits="0"/>đ</span></c:when>
                      <c:otherwise><span style="color:var(--muted)">—</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${s.closingCash != null and s.openingCash != null}">
                        <span style="font-weight:800;color:${s.closingCash >= s.openingCash ? '#059669' : '#DC2626'}">
                          ${s.closingCash >= s.openingCash ? '+' : ''}<fmt:formatNumber value="${s.closingCash - s.openingCash}" type="number" maxFractionDigits="0"/>đ
                        </span>
                      </c:when>
                      <c:otherwise><span style="color:var(--muted)">—</span></c:otherwise>
                    </c:choose>
                  </td>
                </tr>
              </c:if>
            </c:forEach>
          </tbody>
        </table>
      </div>
    </div>

  </div>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
<script>
const ctx_path  = '${pageContext.request.contextPath}';
const REP_MONTH = <%= repMonth %>;
const REP_YEAR  = <%= repYear %>;
const fmt = v => new Intl.NumberFormat('vi-VN').format(v) + 'đ';

let cashChartInstance = null, financeChart = null, waterfallChart = null, peakHourChart = null, mfgChart = null, catChart = null;
let _cashChartType = 'line';

const PALETTE = ['#1558A8','#3ABDE0','#059669','#D97706','#7C3AED','#DC2626','#0EA5E9','#94A3B8'];

function setCashChartType(t) {
  _cashChartType = t;
  document.getElementById('btnLine').classList.toggle('active', t === 'line');
  document.getElementById('btnBar').classList.toggle('active', t === 'bar');
  loadAllCharts();
}

async function loadAllCharts() {
  try {
    const res  = await fetch(ctx_path + '/reports?action=chart-data&month=' + REP_MONTH + '&year=' + REP_YEAR);
    const data = await res.json();
    renderCashChart(data);
    renderFinanceChart(data);
    renderWaterfallChart(data);
    renderPeakHourChart(data);
    renderHorizontalBar('mfgChart', mfgChart, data.mfgLabels, data.mfgValues, c => mfgChart = c);
    renderDoughnut('catChart', catChart, data.catLabels, data.catValues, c => catChart = c);
  } catch (e) { console.warn('Report chart error', e); }
}

function renderCashChart(data) {
  const canvas = document.getElementById('cashChart');
  const sumO = (data.cashOpening||[]).reduce((a,b)=>a+b,0);
  const sumC = (data.cashClosing||[]).reduce((a,b)=>a+b,0);
  const diff = sumC - sumO;
  const days = (data.cashLabels||[]).length;
  document.getElementById('kpiOpening').textContent = fmt(sumO);
  document.getElementById('kpiClosing').textContent = fmt(sumC);
  const kd = document.getElementById('kpiDiff');
  kd.textContent = (diff>=0?'+':'') + fmt(diff);
  kd.style.color = diff>=0 ? '#059669' : '#DC2626';
  document.getElementById('kpiDays').textContent = days + ' ngày';

  if (cashChartInstance) cashChartInstance.destroy();
  cashChartInstance = new Chart(canvas.getContext('2d'), {
    type: _cashChartType,
    data: {
      labels: data.cashLabels||[],
      datasets: [
        { label:'Tiền đầu ca',  data:data.cashOpening||[], borderColor:'#1558A8', backgroundColor:_cashChartType==='bar'?'rgba(21,88,168,.7)':'rgba(21,88,168,.08)', borderWidth:_cashChartType==='bar'?0:2, pointRadius:3, fill:_cashChartType==='line', tension:.4 },
        { label:'Tiền cuối ca', data:data.cashClosing||[], borderColor:'#059669', backgroundColor:_cashChartType==='bar'?'rgba(5,150,105,.7)':'rgba(5,150,105,.08)', borderWidth:_cashChartType==='bar'?0:2, pointRadius:3, fill:_cashChartType==='line', tension:.4 }
      ]
    },
    options: baseChartOptions()
  });
}

// 📊 Grouped Column Chart — Doanh thu / Giá vốn / Lợi nhuận gộp theo ngày
function renderFinanceChart(data) {
  const canvas = document.getElementById('financeChart');
  if (financeChart) financeChart.destroy();
  financeChart = new Chart(canvas.getContext('2d'), {
    type: 'bar',
    data: {
      labels: data.finLabels||[],
      datasets: [
        { label:'Doanh thu',      data:data.finRevenue||[], backgroundColor:'#1558A8', borderRadius:4, maxBarThickness:18 },
        { label:'Giá vốn',        data:data.finCogs||[],    backgroundColor:'#CBD5E1', borderRadius:4, maxBarThickness:18 },
        { label:'Lợi nhuận gộp',  data:data.finProfit||[],  backgroundColor:'#059669', borderRadius:4, maxBarThickness:18 }
      ]
    },
    options: { ...baseChartOptions(), plugins:{ ...baseChartOptions().plugins, legend:{display:false} } }
  });
}

// 🌊 Waterfall Chart (floating-bar trick) — Doanh thu gộp → Giảm giá → Trả hàng → Doanh thu thuần
function renderWaterfallChart(data) {
  const canvas = document.getElementById('waterfallChart');
  if (waterfallChart) waterfallChart.destroy();
  const gross = data.wfGross||0, disc = data.wfDiscount||0, ref = data.wfRefund||0, net = data.wfNet||0;
  const labels = ['Doanh thu gộp', 'Giảm giá', 'Trả hàng', 'Doanh thu thuần'];
  const base   = [0, net + ref, net, 0];
  const value  = [gross, disc, ref, net];
  const colors = ['#1558A8', '#DC2626', '#F59E0B', '#059669'];

  waterfallChart = new Chart(canvas.getContext('2d'), {
    type: 'bar',
    data: {
      labels,
      datasets: [
        { label:'_base', data: base, backgroundColor:'transparent', borderWidth:0, stack:'wf' },
        { label:'Giá trị', data: value, backgroundColor: colors, borderRadius:5, stack:'wf', maxBarThickness:54 }
      ]
    },
    options: {
      responsive:true, maintainAspectRatio:false,
      scales:{
        x:{ stacked:true, ticks:{font:{family:'Outfit',size:11},color:'#7A90B0'}, grid:{display:false} },
        y:{ stacked:true, ticks:{callback:v=>new Intl.NumberFormat('vi-VN',{notation:'compact'}).format(v)+'đ',font:{family:'Outfit',size:11},color:'#7A90B0'}, grid:{color:'rgba(0,0,0,0.04)'} }
      },
      plugins:{
        legend:{display:false},
        tooltip:{
          backgroundColor:'rgba(11,22,40,.92)',titleColor:'#fff',bodyColor:'#ccc',padding:10,cornerRadius:8,
          filter: item => item.datasetIndex === 1,
          callbacks:{ label: c => ' ' + fmt(c.raw) }
        }
      }
    }
  });
}

// 🕐 Area Chart — Doanh thu theo khung giờ (peak hours)
function renderPeakHourChart(data) {
  const canvas = document.getElementById('peakHourChart');
  if (peakHourChart) peakHourChart.destroy();
  const grad = canvas.getContext('2d').createLinearGradient(0,0,0,220);
  grad.addColorStop(0, 'rgba(217,119,6,.35)');
  grad.addColorStop(1, 'rgba(217,119,6,0)');
  peakHourChart = new Chart(canvas.getContext('2d'), {
    type: 'line',
    data: {
      labels: data.hourLabels||[],
      datasets: [{ label:'Doanh thu', data:data.hourValues||[], borderColor:'#D97706', backgroundColor:grad, borderWidth:2, pointRadius:0, pointHoverRadius:4, fill:true, tension:.4 }]
    },
    options: baseChartOptions()
  });
}

// 🏭 Horizontal Bar Chart — Doanh thu theo Hãng sản xuất (tên dài → cột ngang dễ đọc)
function renderHorizontalBar(canvasId, existing, labels, values, setRef) {
  const canvas = document.getElementById(canvasId);
  if (existing) existing.destroy();
  // Sắp giảm dần để cột cao nhất nằm trên cùng
  const items = (labels||[]).map((l,i)=>({l, v:(values||[])[i]||0})).sort((a,b)=>b.v-a.v);
  const chart = new Chart(canvas.getContext('2d'), {
    type: 'bar',
    data: {
      labels: items.map(it=>it.l),
      datasets: [{ data: items.map(it=>it.v), backgroundColor:'#1558A8', borderRadius:5, maxBarThickness:20 }]
    },
    options: {
      indexAxis: 'y',
      responsive:true, maintainAspectRatio:false,
      plugins:{
        legend:{display:false},
        tooltip:{backgroundColor:'rgba(11,22,40,.92)',titleColor:'#fff',bodyColor:'#ccc',padding:10,cornerRadius:8,
          callbacks:{label:c=>' '+fmt(c.raw)}}
      },
      scales:{
        x:{ticks:{callback:v=>new Intl.NumberFormat('vi-VN',{notation:'compact'}).format(v)+'đ',font:{family:'Outfit',size:11},color:'#7A90B0'},grid:{color:'rgba(0,0,0,0.04)'}},
        y:{ticks:{font:{family:'Outfit',size:11.5},color:'#334155'},grid:{display:false}}
      }
    }
  });
  setRef(chart);
}

function renderDoughnut(canvasId, existing, labels, values, setRef) {
  const canvas = document.getElementById(canvasId);
  if (existing) existing.destroy();
  const chart = new Chart(canvas.getContext('2d'), {
    type: 'doughnut',
    data: {
      labels: labels||[],
      datasets: [{ data: values||[], backgroundColor: PALETTE, borderWidth: 2, borderColor: '#fff' }]
    },
    options: {
      responsive:true, maintainAspectRatio:false,
      cutout: '62%',
      plugins:{
        legend:{ position:'right', labels:{ boxWidth:10, font:{family:'Outfit',size:11}, color:'#7A90B0' } },
        tooltip:{ callbacks:{ label:c => ' ' + c.label + ': ' + fmt(c.raw) } }
      }
    }
  });
  setRef(chart);
}

function baseChartOptions() {
  return {
    responsive:true, maintainAspectRatio:false,
    interaction:{mode:'index',intersect:false},
    plugins:{
      legend:{display:false},
      tooltip:{backgroundColor:'rgba(11,22,40,.92)',titleColor:'#fff',bodyColor:'#ccc',padding:10,cornerRadius:8,
        callbacks:{label:c=>' '+c.dataset.label+': '+fmt(c.raw)}}
    },
    scales:{
      y:{ticks:{callback:v=>new Intl.NumberFormat('vi-VN',{notation:'compact'}).format(v)+'đ',font:{family:'Outfit',size:11},color:'#7A90B0'},grid:{color:'rgba(0,0,0,0.04)'}},
      x:{ticks:{font:{family:'Outfit',size:11},color:'#7A90B0'},grid:{display:false}}
    }
  };
}

loadAllCharts();
</script>
</body>
</html>
