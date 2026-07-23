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
<link rel="stylesheet" href="<%= ctx %>/css/warehouse-portal.css?v=3">
<style>
/* CSS riêng cho trang chủ Kho (chrome dùng chung ở warehouse-portal.css) */

/* ── Banner chào hỏi — mượn từ staff-dashboard.jsp, tông Indigo/Deep Cobalt ── */
.welcome{
  border-radius:20px;padding:28px 32px;margin-bottom:22px;
  background:linear-gradient(140deg,#1E1B4B 0%,#3730A3 55%,#4338CA 100%);
  display:flex;align-items:center;gap:20px;color:#fff;
  position:relative;overflow:hidden;
}
.welcome::before{content:'';position:absolute;top:-60px;right:-40px;width:240px;height:240px;
  border-radius:50%;background:rgba(129,140,248,.14);pointer-events:none}
.welcome::after{content:'';position:absolute;bottom:-80px;right:100px;width:180px;height:180px;
  border-radius:50%;background:rgba(99,102,241,.18);pointer-events:none}
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

/* ── Lịch làm việc tuần này — mượn từ staff-dashboard.jsp ── */
.wk-panel{background:var(--white);border:1px solid var(--border);border-radius:18px;margin-bottom:22px;overflow:hidden}
.wk-panel-head{background:linear-gradient(135deg,#3730A3 0%,#4338CA 100%);padding:13px 20px;
  display:flex;align-items:center;justify-content:space-between}
.wk-panel-title{font-size:14.5px;font-weight:800;color:#fff;display:flex;align-items:center;gap:8px}
.wk-panel-meta{display:flex;align-items:center;gap:8px;flex-shrink:0}
.wk-panel-range{font-size:11.5px;color:rgba(255,255,255,.65);font-weight:750}
.wk-panel-count{font-size:11px;font-weight:750;background:rgba(255,255,255,.18);color:#fff;padding:2px 10px;border-radius:20px}
.wk-cols{display:grid;grid-template-columns:repeat(7,1fr);border-top:1px solid var(--border)}
.wk-col{border-right:1px solid #EDEDFA;padding:10px 7px 12px;min-height:110px;position:relative}
.wk-col:last-child{border-right:none}
.wk-col-head{text-align:center;margin-bottom:9px}
.wk-col-dayname{font-size:9.5px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;color:#9694B5;margin-bottom:4px}
.wk-col-num{font-size:24px;font-weight:800;color:var(--ink);line-height:1}
.wk-col.wk-today{background:linear-gradient(180deg,var(--surface) 0%,#F8F8FF 100%)}
.wk-col.wk-today .wk-col-dayname{color:var(--main)}
.wk-col.wk-today .wk-col-num{color:var(--main)}
.wk-today-dot{display:inline-block;width:5px;height:5px;background:var(--main);border-radius:50%;margin-left:3px;vertical-align:middle;margin-bottom:1px}
.wk-col.wk-active-col{background:linear-gradient(180deg,#ECFDF5 0%,#F0FDF4 100%)}
.wk-col.wk-active-col .wk-col-dayname{color:var(--ok)}
.wk-col.wk-active-col .wk-col-num{color:var(--ok)}
.wk-live{position:absolute;top:7px;right:5px;font-size:8.5px;font-weight:750;background:var(--ok);color:#fff;padding:1px 6px;border-radius:8px;letter-spacing:.2px}
.wk-chip{background:#fff;border:1.5px solid var(--border);border-radius:8px;padding:6px 7px;margin-bottom:5px}
.wk-today .wk-chip{border-color:#C7D2FE;background:#FAFAFF}
.wk-active-col .wk-chip{border-color:#A7F3D0;background:#F0FDF9}
.wk-chip-name{font-size:10.5px;font-weight:750;color:var(--deep);line-height:1.3;margin-bottom:3px}
.wk-active-col .wk-chip-name{color:#065F46}
.wk-chip-time{font-size:10px;color:#64748B;margin-bottom:4px;line-height:1.3}
.wk-chip-pos{display:inline-flex;align-items:center;gap:2px;font-size:10px;font-weight:800;color:#fff;background:var(--main);padding:2px 7px;border-radius:5px;white-space:nowrap}
.wk-active-col .wk-chip-pos{background:var(--ok)}
.wk-no-shift{text-align:center;padding-top:18px;color:#D1D5DB;font-size:20px}

.hero{margin-bottom:24px}
.hero h1{font-size:24px;font-weight:800;letter-spacing:-.5px}
.hero h1 span{color:var(--main)}
.hero p{color:var(--muted);font-size:14px;margin-top:5px}
.status-chip{display:inline-flex;align-items:center;gap:7px;margin-top:12px;padding:6px 13px;border-radius:20px;font-size:12.5px;font-weight:700}
.status-chip.on{background:var(--okbg);color:var(--ok)}
.status-chip.off{background:#F1F5F4;color:var(--muted)}
.status-chip .d{width:8px;height:8px;border-radius:50%;background:currentColor}

.bottom-grid{display:grid;grid-template-columns:1.4fr 1fr;gap:20px;align-items:start}
@media(max-width:900px){.bottom-grid{grid-template-columns:1fr}}
.card{background:#fff;border:1px solid #E7E8F1;border-radius:16px;box-shadow:0 1px 2px rgba(30,27,75,.04),0 12px 30px -18px rgba(30,27,75,.12)}
.card-head{padding:16px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;gap:12px}
.card-head h2{font-size:13px;font-weight:800;text-transform:uppercase;letter-spacing:.8px;color:var(--muted)}
.shift-body{padding:20px}
.shift-row{display:flex;align-items:center;gap:14px;padding:12px 0;border-bottom:1px solid #EDEDFA}
.shift-row:last-child{border-bottom:none}
.shift-row .ic{width:38px;height:38px;border-radius:10px;display:grid;place-items:center;font-size:17px;flex:none}
.shift-row.on .ic{background:var(--okbg);color:var(--ok)}
.shift-row.off .ic{background:var(--surface);color:var(--muted)}
.shift-row .lbl{font-size:12px;color:var(--muted);font-weight:600}
.shift-row .val{font-size:14px;font-weight:750;color:var(--ink)}
.shift-cta{margin:4px 20px 20px;display:flex;gap:10px}
.shift-cta a{flex:1;text-align:center;padding:10px;border-radius:10px;font-size:13px;font-weight:750;text-decoration:none;transition:.15s}
.shift-cta .primary{background:linear-gradient(135deg,var(--main),var(--deep));color:#fff}
.shift-cta .primary:hover{opacity:.92}
.shift-cta .secondary{background:var(--surface);color:var(--deep);border:1px solid var(--border)}
.pf-field{padding:13px 20px;border-bottom:1px solid #EDEDFA;display:flex;align-items:center;justify-content:space-between;gap:10px}
.pf-field:last-child{border-bottom:none}
.pf-label{display:flex;align-items:center;gap:9px;font-size:13px;font-weight:650;color:var(--ink)}
.pf-label .ic{font-size:15px}
.pf-value{font-size:16px;font-weight:800;color:var(--ink);font-variant-numeric:tabular-nums}
.pf-value.warn{color:var(--gold)}
.pf-value.danger{color:var(--danger)}
</style>
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

    <!-- Welcome banner — mượn từ staff-dashboard.jsp -->
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

    <!-- Lịch làm việc tuần này — mượn từ staff-dashboard.jsp -->
    <div class="wk-panel">
      <div class="wk-panel-head">
        <div class="wk-panel-title">📅 Lịch làm việc tuần này</div>
        <div class="wk-panel-meta">
          <span class="wk-panel-range" id="wkRange"></span>
          <span class="wk-panel-count" id="wkCount"></span>
        </div>
      </div>
      <div class="wk-cols" id="wkCols"></div>
    </div>
    <script>
    const _wkSched=[<c:forEach var="sc" items="${upcomingSchedules}" varStatus="lp">{date:'${sc.workDate}',name:'<c:out value="${sc.shiftTypeName}"/>',start:'${not empty sc.plannedStart ? fn:substring(sc.plannedStart.toString(),11,16) : ""}',end:'${not empty sc.plannedEnd ? fn:substring(sc.plannedEnd.toString(),11,16) : ""}',pos:${sc.posStation},status:'${sc.status}'}${!lp.last?',':''}</c:forEach>];
    (function(){
      var cols=document.getElementById('wkCols');
      var rangEl=document.getElementById('wkRange');
      var cntEl=document.getElementById('wkCount');
      if(!cols)return;
      var dn=['CN','T2','T3','T4','T5','T6','T7'];
      var today=new Date().toISOString().split('T')[0];
      var base=new Date(); base.setHours(0,0,0,0);
      var days=[];
      for(var i=0;i<7;i++){var dd=new Date(base);dd.setDate(base.getDate()+i);days.push({key:dd.toISOString().split('T')[0],d:dd});}
      var fmt=function(d){return d.getDate()+'/'+(d.getMonth()+1);};
      if(rangEl)rangEl.textContent=fmt(days[0].d)+' – '+fmt(days[6].d)+'/'+days[6].d.getFullYear();
      var byDate={};
      _wkSched.forEach(function(s){if(!byDate[s.date])byDate[s.date]=[];byDate[s.date].push(s);});
      var total=_wkSched.length;
      if(cntEl)cntEl.textContent=total>0?total+' ca lịch':'Chưa có ca';
      days.forEach(function(item){
        var key=item.key, d=item.d;
        var isToday=key===today;
        var shifts=byDate[key]||[];
        var isActive=shifts.some(function(s){return s.status==='CONFIRMED';});
        var cls='wk-col'+(isActive?' wk-active-col':isToday?' wk-today':'');
        var liveBadge=isActive?'<span class="wk-live">● Đang ca</span>':'';
        var todayDot=isToday?'<span class="wk-today-dot"></span>':'';
        var shiftsHtml='';
        if(shifts.length){
          shifts.forEach(function(s){
            var posHtml=s.pos>0
              ?'<div class="wk-chip-pos">🖥️ Quầy '+s.pos+'</div>'
              :'<div class="wk-chip-pos" style="background:#94A3B8">Chưa có quầy</div>';
            shiftsHtml+='<div class="wk-chip"><div class="wk-chip-name">'+s.name+'</div>'
              +'<div class="wk-chip-time">⏰ '+s.start+(s.end?' – '+s.end:'')+'</div>'
              +posHtml+'</div>';
          });
        }else{
          shiftsHtml='<div class="wk-no-shift">—</div>';
        }
        cols.innerHTML+='<div class="'+cls+'">'+liveBadge
          +'<div class="wk-col-head"><div class="wk-col-dayname">'+dn[d.getDay()]+todayDot+'</div>'
          +'<div class="wk-col-num">'+d.getDate()+'</div></div>'+shiftsHtml+'</div>';
      });
    })();
    </script>

    <div class="hero">
      <h1>Không gian làm việc <span>Quản lý kho</span></h1>
      <p>Nhập kho, kiểm soát tồn &amp; bán hàng — mọi thao tác kho ở đây.</p>
      <% if (working) { %>
        <span class="status-chip on"><span class="d"></span> Đang trong ca làm việc</span>
      <% } else { %>
        <span class="status-chip off"><span class="d"></span> Chưa điểm danh vào ca</span>
      <% } %>
    </div>

    <div class="bottom-grid">
      <div class="card">
        <div class="card-head"><div class="wh-ic ok">🕒</div><h2>Ca làm việc hôm nay</h2></div>
        <div class="shift-body">
          <div class="shift-row <%= working ? "on" : "off" %>">
            <div class="ic"><%= working ? "✅" : "⏳" %></div>
            <div>
              <div class="lbl">Trạng thái điểm danh</div>
              <div class="val"><%= working ? "Đang làm việc" : "Chưa điểm danh" %></div>
            </div>
          </div>
          <div class="shift-row <%= currentShift != null ? "on" : "off" %>">
            <div class="ic">🗓️</div>
            <div>
              <div class="lbl">Ca đang mở</div>
              <div class="val"><%= currentShift != null ? "Có ca đang mở" : "Không có ca nào đang mở" %></div>
            </div>
          </div>
        </div>
        <div class="shift-cta">
          <a class="primary" href="<%= ctx %>/staff-checkin?uid=<%= uid %>">🕒 Điểm danh ngay</a>
          <a class="secondary" href="<%= ctx %>/pos?uid=<%= uid %>">🛒 Mở màn bán hàng</a>
        </div>
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
</body>
</html>
