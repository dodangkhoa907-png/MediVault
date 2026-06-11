<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%
    // Lấy uid: từ URL param (login redirect) hoặc session
    String _uid = request.getParameter("uid");
    if (_uid != null && !_uid.isEmpty()) {
        } else {
        _uid = (String) session.getAttribute("staffUid");
    }
    if (_uid == null || _uid.isEmpty()) { response.sendRedirect(request.getContextPath() + "/staff-login"); return; }

    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("staffAccount_" + _uid);
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/staff-login"); return; }
    if (acc.getRoleId() == 1) { response.sendRedirect(request.getContextPath() + "/dashboard"); return; }

    java.lang.String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    java.lang.String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
    java.lang.String roleName = acc.getRoleId() == 2 ? "Dược sĩ bán hàng" : "Thủ kho";
    java.lang.String roleIcon = acc.getRoleId() == 2 ? "💊" : "📦";
    java.lang.String roleTag  = acc.getRoleId() == 2 ? "pharmacist" : "warehouse";

    Integer totalMeds   = (Integer) request.getAttribute("totalMedicines");
    Integer lowStock    = (Integer) request.getAttribute("lowStockCount");
    Integer expiryCount = (Integer) request.getAttribute("expiryCount");
    if (totalMeds   == null) totalMeds   = 0;
    if (lowStock    == null) lowStock    = 0;
    if (expiryCount == null) expiryCount = 0;
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta name="ctx" content="${pageContext.request.contextPath}">
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>medicare — <%= roleName %></title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&family=DM+Serif+Display:ital@0;1&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#12082A;--dp:#1C0F3F;--mid:#2D1B69;--main:#6D28D9;
  --light:#A78BFA;--soft:#F5F3FF;--white:#fff;
  --muted:#7C6FAA;--border:#E2DCF5;--surface:#FAFAFA;
  --green:#059669;--red:#DC2626;--gold:#D97706;--cyan:#5EEAD4;
  --sidebar:228px;
}
html,body{height:100%;font-family:'Outfit',sans-serif}
body{display:flex;background:var(--soft);color:var(--ink)}

/* ── SIDEBAR ── */
.sidebar{
  width:var(--sidebar);min-height:100vh;
  background:linear-gradient(175deg,#0E0520 0%,#1C0F3F 45%,#3B1FA0 100%);
  display:flex;flex-direction:column;
  position:fixed;left:0;top:0;bottom:0;z-index:100;
  box-shadow:4px 0 24px rgba(0,0,0,.2);
}
.sidebar::after{
  content:'';position:absolute;top:0;right:0;bottom:0;width:1px;
  background:linear-gradient(180deg,transparent,rgba(167,139,250,.15) 30%,rgba(167,139,250,.15) 70%,transparent);
}

.sidebar-logo{
  height:66px;padding:0 20px;
  display:flex;align-items:center;gap:11px;
  border-bottom:1px solid rgba(255,255,255,.06);
  flex-shrink:0;
}
.logo-gem{
  width:36px;height:36px;border-radius:10px;
  background:linear-gradient(135deg,var(--light),var(--main));
  display:flex;align-items:center;justify-content:center;
  font-size:16px;flex-shrink:0;
  box-shadow:0 4px 16px rgba(109,40,217,.4);
}
.logo-name{font-family:'Outfit',sans-serif;font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-name span{color:var(--light)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}

.nav-block{padding:12px 0 4px;flex-shrink:0}
.nav-label{
  font-size:9px;font-weight:700;letter-spacing:1.8px;text-transform:uppercase;
  color:rgba(255,255,255,.2);padding:0 20px 6px;
}
.nav-item{
  display:flex;align-items:center;gap:10px;
  padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;
  font-size:13px;font-weight:500;color:rgba(255,255,255,.5);
  text-decoration:none;transition:all .18s;position:relative;cursor:pointer;
}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{
  color:#fff;background:rgba(167,139,250,.15);font-weight:600;
}
.nav-item.active::before{
  content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);
  width:3px;height:56%;background:var(--light);border-radius:2px;
}
.nav-icon{width:18px;height:18px;display:flex;align-items:center;justify-content:center;font-size:14px;flex-shrink:0;opacity:.85}
.nav-item.active .nav-icon{opacity:1}
.nav-badge{
  margin-left:auto;background:#DC2626;color:#fff;
  font-size:10px;font-weight:700;padding:1px 7px;border-radius:20px;min-width:20px;text-align:center;
}

.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06);flex-shrink:0}
.user-card{
  display:flex;align-items:center;gap:10px;
  padding:10px 12px;border-radius:12px;
  background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08);
}
.user-av{
  width:34px;height:34px;flex-shrink:0;border-radius:9px;
  background:linear-gradient(135deg,var(--light),var(--main));
  display:flex;align-items:center;justify-content:center;
  font-size:13px;font-weight:800;color:#fff;
}
.user-name{font-size:12.5px;font-weight:600;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:108px}
.user-role{font-size:10px;color:rgba(255,255,255,.35);margin-top:1px}
.logout-btn{
  margin-left:auto;width:28px;height:28px;flex-shrink:0;
  border-radius:8px;background:rgba(220,38,38,.12);border:none;
  display:flex;align-items:center;justify-content:center;
  color:rgba(220,38,38,.7);font-size:13px;cursor:pointer;
  text-decoration:none;transition:all .18s;
}
.logout-btn:hover{background:rgba(220,38,38,.2);color:#DC2626}

/* ── MAIN ── */
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0}

/* ── TOPBAR ── */
.topbar{
  height:62px;background:var(--white);
  border-bottom:1px solid var(--border);
  display:flex;align-items:center;padding: 28px;gap:14px;
  position:sticky;top:0;z-index:50;
}
.topbar-greeting{
  font-family:'Outfit',sans-serif;font-size:14px;font-weight:500;color:var(--muted);
}
.topbar-greeting strong{color:var(--ink);font-weight:700}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px;flex-shrink:0}
.clock-pill{
  display:flex;align-items:center;gap:6px;padding:6px 13px;
  background:var(--soft);border:1.5px solid var(--border);border-radius:20px;
  font-size:13px;font-weight:700;color:var(--main);font-variant-numeric:tabular-nums;
}
.clock-sep{animation:blink 1s step-end infinite}
@keyframes blink{0%,100%{opacity:1}50%{opacity:0}}
.clock-date{font-size:11px;font-weight:500;color:var(--muted);border-left:1px solid var(--border);padding-left:8px;margin-left:2px;font-variant-numeric:initial}
.topbar-av{
  width:34px;height:34px;border-radius:9px;
  background:linear-gradient(135deg,var(--light),var(--main));
  display:flex;align-items:center;justify-content:center;
  font-size:12px;font-weight:800;color:#fff;
  text-decoration:none;
  box-shadow:0 3px 10px rgba(109,40,217,.2);
  transition:transform .18s;
}
.topbar-av:hover{transform:scale(1.05)}

/* ── CONTENT ── */
.content{padding:26px 28px;flex:1}

/* Welcome banner */
.welcome{
  border-radius:20px;padding:28px 32px;margin-bottom:24px;
  background:linear-gradient(140deg,#1C0F3F 0%,#3B1FA0 55%,#6D28D9 100%);
  display:flex;align-items:center;gap:20px;color:#fff;
  position:relative;overflow:hidden;
}
.welcome::before{
  content:'';position:absolute;top:-60px;right:-40px;
  width:240px;height:240px;border-radius:50%;
  background:rgba(167,139,250,.1);pointer-events:none;
}
.welcome::after{
  content:'';position:absolute;bottom:-80px;right:100px;
  width:180px;height:180px;border-radius:50%;
  background:rgba(109,40,217,.15);pointer-events:none;
}
.welcome-av{
  width:58px;height:58px;border-radius:16px;flex-shrink:0;
  background:rgba(255,255,255,.15);border:2px solid rgba(255,255,255,.25);
  display:flex;align-items:center;justify-content:center;
  font-family:'DM Serif Display',serif;font-size:22px;color:#fff;
}
.welcome-body{flex:1;min-width:0}
.welcome-body h2{
  font-family:'DM Serif Display',serif;font-size:22px;font-weight:400;
  color:#fff;margin-bottom:4px;
}
.welcome-body p{font-size:13.5px;color:rgba(255,255,255,.6)}
.welcome-role-badge{
  flex-shrink:0;
  background:rgba(255,255,255,.12);border:1px solid rgba(255,255,255,.18);
  border-radius:14px;padding:12px 18px;text-align:center;
}
.wrb-icon{font-size:22px;display:block;margin-bottom:5px}
.wrb-text{font-size:12px;font-weight:600;color:rgba(255,255,255,.8)}

/* Stats */
.stats-row{display:grid;grid-template-columns:repeat(3,1fr);gap:14px;margin-bottom:22px}
.stat-card{
  background:var(--white);border:1px solid var(--border);border-radius:16px;
  padding:18px 20px;display:flex;flex-direction:column;gap:8px;
  transition:box-shadow .2s,transform .18s;
  animation:fadeUp .4s ease both;
}
.stat-card:hover{box-shadow:0 6px 24px rgba(109,40,217,.09);transform:translateY(-2px)}
.stat-top{display:flex;align-items:center;justify-content:space-between}
.stat-lbl{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.6px}
.stat-ic{width:36px;height:36px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:16px}
.ic-p{background:rgba(109,40,217,.1)}
.ic-r{background:rgba(220,38,38,.1)}
.ic-g{background:rgba(5,150,105,.1)}
.ic-o{background:rgba(217,119,6,.1)}
.stat-val{font-family:'DM Serif Display',serif;font-size:30px;color:var(--ink)}
.stat-note{font-size:12px;color:var(--muted)}
.stat-warn{color:var(--red);font-weight:600}

/* Section heading */
.sec-head{display:flex;align-items:center;justify-content:space-between;margin-bottom:14px}
.sec-title{font-family:'DM Serif Display',serif;font-size:18px;color:var(--ink)}
.sec-sub{font-size:12.5px;color:var(--muted);margin-top:1px}
/* ── Shift widget (inline — staff-dashboard-shift-section removed) ── */
.shift-widget{background:#fff;border:1.5px solid #E8EDF5;border-radius:16px;overflow:hidden;margin-bottom:20px}
.shift-widget-header{padding:16px 20px;border-bottom:1px solid #F1F5F9;display:flex;align-items:center;justify-content:space-between}
.shift-widget-header h3{margin:0;font-size:15px;font-weight:800;color:#0B1628;display:flex;align-items:center;gap:8px}
.shift-active{background:linear-gradient(135deg,#ECFDF5,#F0FFF4);border:1.5px solid #A7F3D0;border-radius:12px;margin:16px;padding:18px 20px}
.shift-active-top{display:flex;align-items:center;justify-content:space-between;margin-bottom:14px;flex-wrap:wrap;gap:8px}
.shift-live-badge{display:inline-flex;align-items:center;gap:7px;background:#D1FAE5;color:#065F46;border-radius:20px;padding:4px 12px;font-size:12px;font-weight:800}
.dot-live{width:8px;height:8px;border-radius:50%;background:#10B981;animation:pulse 1.4s infinite}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.3}}
.shift-timer{font-size:28px;font-weight:900;color:#059669;font-variant-numeric:tabular-nums;letter-spacing:-1px}
.shift-timer-label{font-size:11px;color:#6EE7B7;font-weight:700;text-transform:uppercase;letter-spacing:.5px;margin-top:2px}
.shift-meta{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-top:14px}
.shift-meta-item{background:rgba(255,255,255,.7);border-radius:8px;padding:9px 12px}
.shift-meta-label{font-size:10px;font-weight:800;color:#6EE7B7;text-transform:uppercase;letter-spacing:.5px}
.shift-meta-val{font-size:13px;font-weight:700;color:#065F46;margin-top:3px}
.shift-close-form{padding:16px 20px;border-top:1px solid #D1FAE5;background:rgba(236,253,245,.5)}
.shift-close-form h4{font-size:13px;font-weight:800;color:#065F46;margin:0 0 12px}
.shift-close-row{display:flex;gap:10px;flex-wrap:wrap;align-items:flex-end}
.shift-close-row .fg{display:flex;flex-direction:column;gap:5px;flex:1;min-width:140px}
.shift-close-row label{font-size:11px;font-weight:700;color:#059669;text-transform:uppercase;letter-spacing:.5px}
.shift-close-row input,.shift-close-row textarea{border:1.5px solid #A7F3D0;border-radius:8px;padding:8px 12px;font-size:13px;background:#fff;font-family:'Outfit',sans-serif}
.shift-close-row input:focus,.shift-close-row textarea:focus{outline:none;border-color:#059669}
.btn-close-shift{background:linear-gradient(135deg,#059669,#047857);color:#fff;border:none;border-radius:8px;padding:9px 20px;font-size:13px;font-weight:800;cursor:pointer;align-self:flex-end;white-space:nowrap}
.btn-close-shift:hover{opacity:.9}
.shift-empty{padding:30px 20px;text-align:center;color:#94A3B8}
.shift-empty .icon{font-size:36px;margin-bottom:10px}
.shift-empty p{font-size:13px;margin:0}
.shift-open-form{padding:16px 20px;border-top:1px solid #F1F5F9}
.shift-open-form h4{font-size:13px;font-weight:800;color:#1558A8;margin:0 0 12px}
.shift-open-row{display:flex;gap:10px;align-items:flex-end;flex-wrap:wrap}
.shift-open-row .fg{display:flex;flex-direction:column;gap:5px}
.shift-open-row label{font-size:11px;font-weight:700;color:#64748B;text-transform:uppercase;letter-spacing:.5px}
.shift-open-row input{border:1.5px solid #BFDBFE;border-radius:8px;padding:8px 12px;font-size:13px;min-width:150px;font-family:'Outfit',sans-serif}
.btn-open-shift{background:linear-gradient(135deg,#1558A8,#0D3F85);color:#fff;border:none;border-radius:8px;padding:9px 20px;font-size:13px;font-weight:800;cursor:pointer}
.btn-open-shift:hover{opacity:.9}
.shift-history{padding:0 20px 16px}
.shift-history-title{font-size:12px;font-weight:800;color:#94A3B8;text-transform:uppercase;letter-spacing:.5px;margin:14px 0 10px}
.shift-history-item{display:flex;align-items:center;justify-content:space-between;padding:9px 12px;background:#F8FAFC;border-radius:8px;margin-bottom:6px;font-size:12px}
.shift-history-item .hi-date{color:#475569;font-weight:600}
.shift-history-item .hi-dur{color:#64748B}
.shift-history-item .hi-cash{color:#059669;font-weight:700}

/* Bottom grid */
.bottom-grid{display:grid;grid-template-columns:1fr 1fr;gap:16px}

/* Profile card */
.profile-card{
  background:var(--white);border:1px solid var(--border);border-radius:18px;overflow:hidden;
  animation:fadeUp .5s .1s ease both;
}
.profile-head{
  padding:20px 22px 16px;border-bottom:1px solid var(--border);
  background:linear-gradient(135deg,#FAFAFA,#F5F3FF);
  display:flex;align-items:center;gap:14px;
}
.profile-av{
  width:48px;height:48px;border-radius:13px;flex-shrink:0;
  background:linear-gradient(135deg,var(--light),var(--main));
  display:flex;align-items:center;justify-content:center;
  font-family:'DM Serif Display',serif;font-size:20px;color:#fff;
  box-shadow:0 4px 14px rgba(109,40,217,.25);
}
.profile-head-name{font-size:14px;font-weight:700;color:var(--ink)}
.profile-head-role{font-size:12px;color:var(--muted);margin-top:2px;display:flex;align-items:center;gap:5px}
.role-dot{width:6px;height:6px;border-radius:50%;background:var(--light)}
.profile-field{padding:13px 22px;border-bottom:1px solid #F8F7FF;display:flex;flex-direction:column;gap:2px}
.profile-field:last-child{border-bottom:none}
.pf-label{font-size:10.5px;font-weight:700;text-transform:uppercase;letter-spacing:.6px;color:var(--muted)}
.pf-value{font-size:13.5px;font-weight:500;color:var(--ink)}
.pf-value.empty{color:var(--muted);font-style:italic;font-weight:400}
.edit-link{
  display:block;margin:14px 22px 18px;padding:10px;
  background:var(--soft);border:1.5px solid var(--border);border-radius:10px;
  text-align:center;text-decoration:none;font-size:13px;font-weight:600;color:var(--main);
  transition:all .18s;
}
.edit-link:hover{background:rgba(167,139,250,.12);border-color:var(--light)}

/* Shift card */
.shift-card{
  background:var(--white);border:1px solid var(--border);border-radius:18px;overflow:hidden;
  animation:fadeUp .5s .15s ease both;
}
.shift-head{
  padding:20px 22px 14px;border-bottom:1px solid var(--border);
  background:linear-gradient(135deg,#FAFAFA,#F0FDF4);
}
.shift-head-title{font-size:14px;font-weight:700;color:var(--ink);margin-bottom:2px}
.shift-head-sub{font-size:12px;color:var(--muted)}
.shift-body{padding:20px 22px}
.shift-today{
  background:linear-gradient(135deg,#F5F3FF,#EDE9FE);
  border:1px solid var(--border);border-radius:12px;padding:16px 18px;
  margin-bottom:14px;
}
.shift-today-lbl{font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);margin-bottom:6px}
.shift-today-time{font-family:'DM Serif Display',serif;font-size:24px;color:var(--main)}
.shift-today-note{font-size:12px;color:var(--muted);margin-top:4px}

/* Progress tasks */
.task-section-lbl{font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);margin-bottom:10px}
.task-item{
  display:flex;align-items:center;gap:12px;
  padding:10px 14px;border-radius:10px;margin-bottom:6px;
  background:var(--soft);border:1px solid var(--border);
  font-size:13px;font-weight:500;color:var(--ink);
  transition:background .15s;
}
.task-item:last-child{margin-bottom:0}
.task-check{
  width:20px;height:20px;border-radius:6px;flex-shrink:0;
  border:2px solid var(--border);cursor:pointer;
  display:flex;align-items:center;justify-content:center;font-size:11px;
  transition:all .18s;
}
.task-check.done{background:var(--green);border-color:var(--green);color:#fff}
.task-check.pending{border-color:var(--light)}
.task-text{flex:1}
.task-text.done{text-decoration:line-through;color:var(--muted)}
.task-time{font-size:11px;color:var(--muted);font-weight:400}

@keyframes fadeUp{from{opacity:0;transform:translateY(16px)}to{opacity:1;transform:translateY(0)}}

/* ── Activity Log ── */
.log-card{
  background:var(--white);border:1px solid var(--border);border-radius:18px;
  overflow:hidden;margin-top:16px;
  animation:fadeUp .5s .2s ease both;
}
.log-head{
  padding:18px 22px 14px;border-bottom:1px solid var(--border);
  background:linear-gradient(135deg,#FAFAFA,#F5F3FF);
  display:flex;align-items:center;justify-content:space-between;
}
.log-head-title{font-size:14px;font-weight:700;color:var(--ink)}
.log-head-sub{font-size:12px;color:var(--muted);margin-top:2px}
.log-table{width:100%;border-collapse:collapse}
.log-table th{
  font-size:10.5px;font-weight:700;text-transform:uppercase;letter-spacing:.6px;
  color:var(--muted);padding:10px 18px;background:var(--soft);
  border-bottom:1px solid var(--border);text-align:left;
}
.log-table td{
  padding:11px 18px;font-size:13px;color:var(--ink);
  border-bottom:1px solid #F8F7FF;vertical-align:middle;
}
.log-table tr:last-child td{border-bottom:none}
.log-table tr:hover td{background:#FAFAFA}
.log-badge{
  display:inline-flex;align-items:center;gap:4px;
  padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:600;
}
.lb-green{background:rgba(5,150,105,.1);color:var(--green)}
.lb-gray{background:rgba(124,111,170,.1);color:var(--muted)}
.lb-blue{background:rgba(109,40,217,.1);color:var(--main)}
.log-ip{font-family:monospace;font-size:12px;color:var(--muted)}
.log-time{font-size:12px;color:var(--muted);white-space:nowrap}
.log-empty{text-align:center;padding:28px;color:var(--muted);font-size:13px}

.badge{display:inline-flex;align-items:center;gap:5px;padding:3px 10px;border-radius:20px;font-size:12px;font-weight:600}
.b-purple{background:rgba(109,40,217,.1);color:var(--main)}
.b-green{background:rgba(5,150,105,.1);color:var(--green)}
</style>
</head>
<body>

<!-- SIDEBAR -->
<aside class="sidebar">
  <div class="sidebar-logo">
    <div class="logo-gem">💊</div>
    <div>
      <div class="logo-name">Medi<span>Vault</span></div>
      <div class="logo-sub"><%= roleName %></div>
    </div>
  </div>

  <nav class="nav-block">
    <div class="nav-label">Tổng quan</div>
    <a href="${pageContext.request.contextPath}/staff-dashboard?uid=<%= _uid %>" class="nav-item active">
      <span class="nav-icon">🏠</span> Trang chủ
    </a>
  </nav>

  <nav class="nav-block">
    <div class="nav-label">Cá nhân</div>
    <a href="${pageContext.request.contextPath}/staff-profile?uid=<%= _uid %>" class="nav-item">
      <span class="nav-icon">👤</span> Hồ sơ của tôi
    </a>
    <a href="${pageContext.request.contextPath}/staff-checkin?uid=<%= _uid %>" class="nav-item">
      <span class="nav-icon">✅</span> Điểm danh
    </a>
    <a href="${pageContext.request.contextPath}/staff-my-shifts?uid=<%= _uid %>" class="nav-item">
      <span class="nav-icon">🕐</span> Ca làm việc
    </a>
    <a href="${pageContext.request.contextPath}/leave-requests?action=my&uid=<%= _uid %>" class="nav-item">
      <span class="nav-icon">🏖️</span> Xin nghỉ phép
    </a>
  </nav>

  <% if (acc.getRoleId() == 2) { %>
  <nav class="nav-block">
    <div class="nav-label">Bán hàng</div>
    <a href="${pageContext.request.contextPath}/pos?uid=<%= _uid %>" class="nav-item">
      <span class="nav-icon">🛒</span> Bán thuốc (POS)
    </a>
    <a href="${pageContext.request.contextPath}/staff-dashboard?uid=<%= _uid %>" class="nav-item" style="opacity:.5;cursor:default">
      <span class="nav-icon">🧾</span> Hóa đơn của tôi
    </a>
  </nav>
  <% } else { %>
  <nav class="nav-block">
    <div class="nav-label">Kho hàng</div>
    <a href="${pageContext.request.contextPath}/staff-dashboard?uid=<%= _uid %>" class="nav-item" style="opacity:.5;cursor:default">
      <span class="nav-icon">📦</span> Quản lý kho
    </a>
    <a href="${pageContext.request.contextPath}/staff-dashboard?uid=<%= _uid %>" class="nav-item" style="opacity:.5;cursor:default">
      <span class="nav-icon">⚠️</span> Hàng sắp hết
      <% if (lowStock > 0) { %><span class="nav-badge"><%= lowStock %></span><% } %>
    </a>
    <a href="${pageContext.request.contextPath}/staff-dashboard?uid=<%= _uid %>" class="nav-item" style="opacity:.5;cursor:default">
      <span class="nav-icon">⏰</span> Sắp hết hạn
      <% if (expiryCount > 0) { %><span class="nav-badge"><%= expiryCount %></span><% } %>
    </a>
  </nav>
  <% } %>

  <div class="sidebar-footer">
    <div class="user-card">
      <div class="user-av"><%= initials %></div>
      <div style="min-width:0">
        <div class="user-name"><%= fullName %></div>
        <div class="user-role"><%= roleName %></div>
      </div>
      <a href="${pageContext.request.contextPath}/logout?from=staff&uid=<%= _uid %>" class="logout-btn" title="Đăng xuất">⏻</a>
    </div>
  </div>
</aside>

<!-- MAIN -->
<div class="main">
  <header class="topbar">
    <div class="topbar-greeting">Xin chào, <strong><%= fullName %></strong></div>
    <div class="topbar-right">
      <div class="clock-pill">
        <span id="cH">00</span><span class="clock-sep">:</span><span id="cM">00</span>
        <span class="clock-date" id="cDate"></span>
      </div>
      <a href="${pageContext.request.contextPath}/staff-profile" class="topbar-av" title="Hồ sơ của tôi"><%= initials %></a>
    </div>
  </header>

  <div class="content">

    <!-- Welcome -->
    <div class="welcome">
      <div class="welcome-av"><%= initials %></div>
      <div class="welcome-body">
        <h2>Chào buổi sáng, <%= fullName %>!</h2>
        <p>Chúc bạn có một ca làm việc hiệu quả · <span id="welcomeDate"></span></p>
      </div>
      <div class="welcome-role-badge">
        <span class="wrb-icon"><%= roleIcon %></span>
        <div class="wrb-text"><%= roleName %></div>
      </div>
    </div>

    <!-- Stats -->
    <div class="stats-row">
      <div class="stat-card">
        <div class="stat-top">
          <span class="stat-lbl">Tổng thuốc kho</span>
          <div class="stat-ic ic-p">💊</div>
        </div>
        <div class="stat-val"><%= totalMeds %></div>
        <div class="stat-note">Mặt hàng đang kinh doanh</div>
      </div>
      <div class="stat-card">
        <div class="stat-top">
          <span class="stat-lbl">Sắp hết hạn</span>
          <div class="stat-ic ic-r">⏰</div>
        </div>
        <div class="stat-val"><%= expiryCount %></div>
        <div class="stat-note <%= expiryCount > 0 ? "stat-warn" : "" %>">
          <%= expiryCount > 0 ? "⚠ Cần xử lý sớm" : "✓ Không có" %>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-top">
          <span class="stat-lbl">Tồn kho thấp</span>
          <div class="stat-ic ic-o">📦</div>
        </div>
        <div class="stat-val"><%= lowStock %></div>
        <div class="stat-note <%= lowStock > 0 ? "stat-warn" : "" %>">
          <%= lowStock > 0 ? "⚠ Cần nhập thêm" : "✓ Đủ hàng" %>
        </div>
      </div>
    </div>

    <!-- Bottom grid -->
    <div class="bottom-grid">

      <!-- Profile info -->
      <div class="profile-card">
        <div class="profile-head">
          <div class="profile-av"><%= initials %></div>
          <div>
            <div class="profile-head-name"><%= fullName %></div>
            <div class="profile-head-role">
              <div class="role-dot"></div>
              <%= roleName %>
            </div>
          </div>
        </div>
        <div class="profile-field">
          <div class="pf-label">Tên đăng nhập</div>
          <div class="pf-value">@<%= acc.getUsername() %></div>
        </div>
        <div class="profile-field">
          <div class="pf-label">Email</div>
          <div class="pf-value <%= acc.getEmail()==null?"empty":"" %>">
            <%= acc.getEmail()!=null ? acc.getEmail() : "Chưa cập nhật" %>
          </div>
        </div>
        <div class="profile-field">
          <div class="pf-label">Số điện thoại</div>
          <div class="pf-value <%= acc.getPhone()==null?"empty":"" %>">
            <%= acc.getPhone()!=null ? acc.getPhone() : "Chưa cập nhật" %>
          </div>
        </div>
        <div class="profile-field">
          <div class="pf-label">Trạng thái</div>
          <div class="pf-value"><span class="badge b-green">● Đang hoạt động</span></div>
        </div>
        <a href="${pageContext.request.contextPath}/staff-profile" class="edit-link">Xem & Cập nhật hồ sơ →</a>
      </div>

      <!-- Shift widget — kết nối thực từ DB -->
      <div class="shift-widget">
        <div class="shift-widget-header">
          <h3>🕐 Ca làm việc</h3>
          <c:if test="${not empty currentShift}">
            <a href="${pageContext.request.contextPath}/staff-my-shifts?uid=${staffUid}"
               style="font-size:12px;color:#059669;font-weight:700;text-decoration:none">
              Ca #${currentShift.shiftId} →
            </a>
          </c:if>
          <c:if test="${empty currentShift}">
            <a href="${pageContext.request.contextPath}/staff-my-shifts?uid=${staffUid}"
               style="font-size:12px;color:#7A90B0;text-decoration:none">Xem lịch sử →</a>
          </c:if>
        </div>

        <c:choose>
          <%-- Ca đang mở --%>
          <c:when test="${not empty currentShift}">
            <div class="shift-active">
              <div class="shift-active-top">
                <span class="shift-live-badge">
                  <span class="dot-live"></span> Đang làm việc
                </span>
                <div style="text-align:right">
                  <div class="shift-timer" id="shiftTimer">00:00:00</div>
                  <div class="shift-timer-label">Thời gian làm việc</div>
                </div>
              </div>
              <div class="shift-meta">
                <div class="shift-meta-item">
                  <div class="shift-meta-label">Bắt đầu</div>
                  <div class="shift-meta-val" id="shiftStartDisplay">
                    ${fn:substring(currentShift.startTime.toString(),11,16)}
                    <span style="font-size:11px;opacity:.7">
                      ${fn:substring(currentShift.startTime.toString(),8,10)}/${fn:substring(currentShift.startTime.toString(),5,7)}
                    </span>
                  </div>
                </div>
                <div class="shift-meta-item">
                  <div class="shift-meta-label">Tiền đầu ca</div>
                  <div class="shift-meta-val">
                    <c:if test="${not empty currentShift.openingCash}">
                      <fmt:formatNumber value="${currentShift.openingCash}" type="number" maxFractionDigits="0"/>đ
                    </c:if>
                    <c:if test="${empty currentShift.openingCash}">0đ</c:if>
                  </div>
                </div>
              </div>
            </div>
            <div class="shift-close-form">
                <div style="background:linear-gradient(135deg,#FEF3C7,#FFFBEB);border:1.5px solid #FDE68A;border-radius:10px;padding:12px 16px;margin-top:8px">
                    <div style="font-size:12.5px;font-weight:700;color:#92400E;margin-bottom:4px">🔒 Đóng ca qua NFC hoặc Admin</div>
                    <div style="font-size:11.5px;color:#B45309;line-height:1.6">
                        • Ca tự đóng sau 20 phút kết thúc giờ<br>• Trễ &gt; 5 phút → bị trừ tiền phạt
                    </div>
                </div>
            </div>
          </c:when>

          <%-- Chưa có ca --%>
          <c:otherwise>
            <div class="shift-empty">
              <div class="icon">🌙</div>
              <p>Bạn chưa có ca làm việc đang mở.<br>Bắt đầu ca mới để ghi nhận thời gian.</p>
            </div>
            <div class="shift-open-form">
                <c:choose>
                    <c:when test="${not empty todaySchedule}">
                        <div style="background:#F0FDF4;border:1.5px solid #BBF7D0;border-radius:10px;padding:12px 16px">
                            <div style="font-size:13px;font-weight:700;color:#065F46;margin-bottom:4px">📋 ${todaySchedule.shiftTypeName}</div>
                            <div style="font-size:11.5px;color:#059669;margin-bottom:8px">
                                🕐 <c:if test="${not empty todaySchedule.plannedStart}">${fn:substring(todaySchedule.plannedStart.toString(),11,16)}</c:if>–<c:if test="${not empty todaySchedule.plannedEnd}">${fn:substring(todaySchedule.plannedEnd.toString(),11,16)}</c:if>
                            </div>
                            <a href="${pageContext.request.contextPath}/staff-checkin?uid=${staffUid}"
                               style="display:block;text-align:center;background:#10B981;color:#fff;padding:8px;border-radius:8px;font-size:13px;font-weight:700;text-decoration:none">
                                ✅ Đến trang Điểm danh
                            </a>
                        </div>
                    </c:when>
                    <c:otherwise>
                        <div style="background:#FEF2F2;border:1.5px solid #FECACA;border-radius:10px;padding:12px 16px;text-align:center">
                            <div style="font-size:16px;margin-bottom:4px">🚫</div>
                            <div style="font-size:12.5px;font-weight:700;color:#991B1B">Không có lịch ca hôm nay</div>
                            <div style="font-size:11.5px;color:#B91C1C;margin-top:3px">Liên hệ Admin để xếp ca</div>
                        </div>
                    </c:otherwise>
                </c:choose>
            </div>
          </c:otherwise>
        </c:choose>

        <%-- Lịch sử ca gần nhất --%>
        <c:if test="${not empty recentShifts}">
          <div class="shift-history">
            <div class="shift-history-title">Ca gần nhất</div>
            <c:forEach var="s" items="${recentShifts}">
              <div class="shift-history-item">
                <span class="hi-date">
                  ${fn:substring(s.startTime.toString(),8,10)}/${fn:substring(s.startTime.toString(),5,7)}
                  ${fn:substring(s.startTime.toString(),11,16)} →
                  <c:choose>
                    <c:when test="${not empty s.endTime}">${fn:substring(s.endTime.toString(),11,16)}</c:when>
                    <c:otherwise>—</c:otherwise>
                  </c:choose>
                </span>
                <span class="hi-cash">
                  <c:if test="${not empty s.closingCash}">
                    <fmt:formatNumber value="${s.closingCash}" type="number" maxFractionDigits="0"/>đ
                  </c:if>
                </span>
              </div>
            </c:forEach>
          </div>
        </c:if>

      </div><%-- /shift-widget --%>

    </div>

    <%-- ── Nhật ký hoạt động gần đây ── --%>
    <div class="log-card">
      <div class="log-head">
        <div>
          <div class="log-head-title">🕐 Nhật ký hoạt động</div>
          <div class="log-head-sub">10 thao tác gần nhất của bạn</div>
        </div>
      </div>
      <table class="log-table">
        <thead>
          <tr>
            <th>Thời gian</th>
            <th>Hành động</th>
            <th>Chi tiết</th>
            <th>IP</th>
          </tr>
        </thead>
        <tbody>
          <c:choose>
            <c:when test="${empty recentLogs}">
              <tr><td colspan="4" class="log-empty">Chưa có hoạt động nào được ghi nhận.</td></tr>
            </c:when>
            <c:otherwise>
              <c:forEach var="log" items="${recentLogs}">
                <tr>
                  <td class="log-time">${log.createdAt}</td>
                  <td>
                    <c:choose>
                      <c:when test="${log.action == 'Đăng nhập'}">
                        <span class="log-badge lb-green">✓ ${log.action}</span>
                      </c:when>
                      <c:when test="${log.action == 'Đăng xuất'}">
                        <span class="log-badge lb-gray">↩ ${log.action}</span>
                      </c:when>
                      <c:otherwise>
                        <span class="log-badge lb-blue">● ${log.action}</span>
                      </c:otherwise>
                    </c:choose>
                  </td>
                  <td>${log.details}</td>
                  <td class="log-ip">${log.ipAddress}</td>
                </tr>
              </c:forEach>
            </c:otherwise>
          </c:choose>
        </tbody>
      </table>
    </div>

  </div>
</div>

<script>
function updateClock(){
  const now=new Date();
  const h=now.getHours().toString().padStart(2,'0');
  const m=now.getMinutes().toString().padStart(2,'0');
  const days=['CN','T2','T3','T4','T5','T6','T7'];
  const d=now.getDate().toString().padStart(2,'0');
  const mo=(now.getMonth()+1).toString().padStart(2,'0');
  document.getElementById('cH').textContent=h;
  document.getElementById('cM').textContent=m;
  document.getElementById('cDate').textContent=days[now.getDay()]+', '+d+'/'+mo;
  if(document.getElementById('welcomeDate'))
    document.getElementById('welcomeDate').textContent=days[now.getDay()]+' '+d+'/'+mo+'/'+now.getFullYear();
  // Greeting
  const hr=now.getHours();
  const greeting=hr<12?'Chào buổi sáng':hr<18?'Chào buổi chiều':'Chào buổi tối';
  document.querySelector('.welcome-body h2').textContent=greeting+', <%= fullName %>!';
}
updateClock(); setInterval(updateClock,1000);

// ── Shift timer — đếm giờ ca đang mở ──────────────────────────────
<c:if test="${not empty currentShift}">
(function(){
  const startRaw = '${currentShift.startTime}';
  // LocalDateTime format: "2026-06-09T19:00:00" hoặc "2026-06-09 19:00:00"
  const shiftStart = new Date(startRaw.replace('T', ' '));
  const timerEl    = document.getElementById('shiftTimer');
  function tick() {
    if (!timerEl) return;
    const diff = Math.floor((new Date() - shiftStart) / 1000);
    if (isNaN(diff) || diff < 0) { timerEl.textContent = '00:00:00'; return; }
    const h = String(Math.floor(diff / 3600)).padStart(2, '0');
    const m = String(Math.floor((diff % 3600) / 60)).padStart(2, '0');
    const s = String(diff % 60).padStart(2, '0');
    timerEl.textContent = h + ':' + m + ':' + s;
  }
  tick(); setInterval(tick, 1000);
})();
</c:if>

</script>
<script>
// Lưu staffUid vào sessionStorage của tab này
(function(){
  const urlUid = new URLSearchParams(location.search).get('uid');
  if (urlUid) sessionStorage.setItem('staffUid', urlUid);
  const uid = sessionStorage.getItem('staffUid');
  if (uid) {
    // Gắn ?uid= vào tất cả link staff trong trang
    document.querySelectorAll('a[href*="staff-"]').forEach(a => {
      const url = new URL(a.href, location.origin);
      if (!url.searchParams.has('uid')) {
        url.searchParams.set('uid', uid);
        a.href = url.toString();
      }
    });
  }
})();
</script>
<script>
/* ── Single Session Enforcement ──────────────────────────────
   Ping server mỗi 10s để kiểm tra token còn hợp lệ không.
   Nếu tab mới login cùng account → token mới ghi đè →
   ping trả về kicked=true → tab này bị kick về login.
   ─────────────────────────────────────────────────────────── */
(function() {
  // Lấy uid + token từ URL (lần đầu vào) hoặc sessionStorage (request sau)
  const params = new URLSearchParams(location.search);
  const urlUid   = params.get('uid');
  const urlToken = params.get('token');

  if (urlUid)   sessionStorage.setItem('staffUid',   urlUid);
  if (urlToken) sessionStorage.setItem('staffToken', urlToken);

  sessionStorage.setItem('tabId', Math.random().toString(36).slice(2) + Date.now());

  // Chỉ logout khi đóng tab thật sự — dùng pagehide (đáng tin hơn beforeunload)
  let _navigating = false;
  document.addEventListener('click', function(e) {
    const a = e.target.closest('a[href]');
    if (a && a.hostname === location.hostname) _navigating = true;
  });
  document.addEventListener('submit', function() { _navigating = true; });
  window.addEventListener('pagehide', function(e) {
    // e.persisted = true → BFCache (không đóng thật), _navigating = đang chuyển trang
    if (e.persisted || _navigating) { _navigating = false; return; }
    const uid = sessionStorage.getItem('staffUid');
    const ctx = document.querySelector('meta[name="ctx"]')?.content || '';
    if (uid) {
      navigator.sendBeacon(ctx + '/logout?from=staff&uid=' + uid);
    }
  });
  const uid   = sessionStorage.getItem('staffUid');
  const token = sessionStorage.getItem('staffToken');
  const tabId = sessionStorage.getItem('tabId');

  if (!uid || !token) return;

  // Inject uid vào mọi link staff trong trang
  document.querySelectorAll('a[href]').forEach(function(a) {
    try {
      const href = a.getAttribute('href') || '';
      if (!href || href.startsWith('#') || href.startsWith('javascript')) return;
      if (href.match(/staff-(dashboard|profile)|logout/)) {
        if (!href.includes('uid=')) {
          a.href = href + (href.includes('?') ? '&' : '?') + 'uid=' + uid;
        }
        if (href.includes('logout') && !href.includes('uid=')) {
          a.href = href + (href.includes('?') ? '&' : '?') + 'uid=' + uid;
        }
      }
    } catch(e) {}
  });

  // Bắt đầu ping mỗi 10 giây
  setInterval(async function() {
    try {
      const ctx = document.querySelector('meta[name="ctx"]')?.content || '';
      const res = await fetch(ctx + '/staff-ping?uid=' + uid + '&token=' + token + '&tabId=' + tabId, {
        cache: 'no-store'
      });
      const data = await res.json();
      if (!data.ok && data.reason === 'kicked') {
        sessionStorage.removeItem('staffUid');
        sessionStorage.removeItem('staffToken');
        // Hiện thông báo + redirect về login
        alert('⚠️ Tài khoản của bạn đã đăng nhập ở thiết bị khác.\nBạn sẽ được chuyển về trang đăng nhập.');
        location.href = ctx + '/staff-login';
      }
    } catch(e) { /* mạng lỗi — bỏ qua, thử lại sau */ }
  }, 10000);
})();
</script>
</body>
</html>
