<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<% String activeNav = "shifts"; %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
    String activeTab = request.getParameter("tab") != null ? request.getParameter("tab") : "list";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Ca làm việc — MediVault</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;--amber:#F59E0B;
  --purple:#7C3AED;
  --ca-long:#7C3AED;--ca-std:#1558A8;--ca-part:#059669;
  --ca-open:#D97706;--ca-absent:#DC2626;--ca-leave:#6366F1;
  --sidebar:232px;--radius:14px;
}
html,body{height:100%;font-family:'Outfit',sans-serif;background:var(--surface);color:var(--ink)}
body{display:flex}

/* ── SIDEBAR ── */
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-icon{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0}
.logo-text{font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-text span{color:var(--cyan)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:12px 0 4px;flex-shrink:0}
.nav-label{font-size:9px;font-weight:700;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:500;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.14);font-weight:600}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--cyan);border-radius:2px}
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06);flex-shrink:0}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08)}
.user-av{width:34px;height:34px;flex-shrink:0;border-radius:9px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.user-name{font-size:12.5px;font-weight:600;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:110px}
.user-role{font-size:10px;color:rgba(255,255,255,.35);margin-top:1px}
.logout-btn{margin-left:auto;width:28px;height:28px;flex-shrink:0;border-radius:8px;background:rgba(220,38,38,.12);border:none;display:flex;align-items:center;justify-content:center;color:rgba(220,38,38,.7);font-size:13px;cursor:pointer;text-decoration:none;transition:all .18s}
.logout-btn:hover{background:rgba(220,38,38,.2);color:#DC2626}

/* ── MAIN LAYOUT ── */
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0}
.topbar{height:60px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50;flex-shrink:0}
.topbar-left{display:flex;align-items:center;gap:10px}
.topbar-icon{width:34px;height:34px;border-radius:9px;background:linear-gradient(135deg,rgba(21,88,168,.12),rgba(58,189,224,.12));display:flex;align-items:center;justify-content:center;font-size:15px}
.topbar-title{font-size:16px;font-weight:800;color:var(--ink)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.topbar-pill{display:inline-flex;align-items:center;gap:6px;padding:4px 12px;border-radius:20px;font-size:12.5px;font-weight:700}
.pill-total{background:#EFF6FF;color:var(--blue)}
.pill-open{background:#ECFDF5;color:var(--green)}
.pill-staff{background:#F5F3FF;color:var(--purple)}
.topbar-user{display:flex;align-items:center;gap:8px;padding:5px 12px 5px 7px;border:1.5px solid var(--border);border-radius:20px;text-decoration:none;color:inherit;transition:all .18s}
.topbar-user:hover{border-color:var(--cyan)}
.topbar-av{width:26px;height:26px;border-radius:7px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:10px;font-weight:800;color:#fff}
.topbar-name{font-size:12.5px;font-weight:600;color:var(--navy)}
.content{padding:22px 26px;flex:1;min-width:0}

/* ── KPI STRIP ── */
.kpi-strip{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-bottom:20px}
.kpi{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);padding:14px 18px;display:flex;align-items:center;gap:12px;transition:box-shadow .2s,transform .18s}
.kpi:hover{box-shadow:0 4px 16px rgba(21,88,168,.08);transform:translateY(-1px)}
.kpi-icon{width:40px;height:40px;border-radius:11px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0}
.kpi-blue{background:#EFF6FF}.kpi-green{background:#ECFDF5}
.kpi-amber{background:#FFFBEB}.kpi-purple{background:#F5F3FF}
.kpi-num{font-size:24px;font-weight:900;line-height:1}
.kpi-lbl{font-size:11px;color:var(--muted);font-weight:600;text-transform:uppercase;letter-spacing:.5px;margin-top:3px}

/* ── TABS ── */
.tab-bar{display:flex;gap:2px;background:var(--white);border:1px solid var(--border);border-radius:12px;padding:4px;margin-bottom:20px;width:fit-content}
.tab-btn{padding:8px 20px;border-radius:9px;font-size:13px;font-weight:600;cursor:pointer;border:none;background:transparent;color:var(--muted);transition:all .18s;display:flex;align-items:center;gap:6px}
.tab-btn:hover{color:var(--ink);background:var(--surface)}
.tab-btn.active{background:linear-gradient(135deg,var(--blue),var(--cyan));color:#fff;box-shadow:0 3px 10px rgba(21,88,168,.25)}
.tab-pane{display:none}
.tab-pane.active{display:block}

/* ── TOAST ── */
.toast{position:fixed;top:18px;right:22px;padding:11px 18px;border-radius:10px;font-size:13px;font-weight:700;color:#fff;z-index:9999;display:flex;align-items:center;gap:8px;box-shadow:0 4px 18px rgba(0,0,0,.15);animation:slideIn .3s ease}
.toast-ok{background:var(--green)}.toast-err{background:var(--red)}.toast-warn{background:var(--gold)}.toast-info{background:var(--blue)}
@keyframes slideIn{from{transform:translateX(120%);opacity:0}to{transform:translateX(0);opacity:1}}

/* ── LEGEND & NAV ── */
.legend{display:flex;gap:12px;align-items:center;flex-wrap:wrap}
.leg-item{display:flex;align-items:center;gap:5px;font-size:11.5px;font-weight:600;color:var(--muted)}
.leg-dot{width:10px;height:10px;border-radius:50%;flex-shrink:0}
.view-toggle{display:flex;background:#F1F5FB;border-radius:8px;padding:3px;gap:2px}
.vt-btn{padding:5px 14px;border-radius:6px;border:none;font-family:'Outfit',sans-serif;font-size:12px;font-weight:600;cursor:pointer;background:transparent;color:var(--muted);transition:all .18s}
.vt-btn.active{background:#fff;color:var(--blue);box-shadow:0 1px 4px rgba(0,0,0,.1)}
.nav-arrow{display:inline-flex;align-items:center;justify-content:center;width:28px;height:28px;border-radius:7px;background:var(--surface);border:1px solid var(--border);font-size:15px;color:var(--muted);cursor:pointer;transition:all .15s;text-decoration:none}
.nav-arrow:hover{background:var(--border);color:var(--ink)}
.btn-today{padding:5px 12px;border-radius:7px;background:var(--surface);border:1px solid var(--border);font-size:12px;font-weight:600;color:var(--muted);cursor:pointer;transition:all .15s;text-decoration:none}
.btn-today:hover{background:var(--border)}
.nav-period{font-size:14px;font-weight:700;color:var(--ink);min-width:110px;text-align:center}

/* ── CHART ── */
.chart-card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden;margin-bottom:20px}
.chart-card-head{padding:16px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px}
.chart-card-head h3{font-size:15px;font-weight:700;color:var(--ink)}
.chart-sub{font-size:12px;color:var(--muted);margin-top:2px;display:block}
.chart-legend{padding:10px 20px;display:flex;gap:16px;border-top:1px solid var(--border)}
.chart-legend span{font-size:12px;color:var(--muted);display:flex;align-items:center;gap:5px}

/* ─────────────────────────────────────────────────────────
   DOT CALENDAR — Mỗi nhân viên 1 hàng, dots theo ngày
   ───────────────────────────────────────────────────────── */
.sched-card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}

/* Header strip */
.sched-header{padding:14px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px}

/* Grid: [label 140px] + [7 cols equal] */
.dc-grid{min-width:680px;overflow-x:auto}
.dc-head-row{display:grid;grid-template-columns:140px repeat(7,1fr);border-bottom:1px solid var(--border)}
.dc-head-label{padding:10px 14px;font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:var(--muted)}
.dc-head-day{padding:10px 8px;text-align:center;font-size:10px;font-weight:700;color:var(--muted);border-left:1px solid var(--border)}
.dc-head-day .dn{font-size:17px;font-weight:900;color:var(--ink);display:block;line-height:1.1;margin-top:2px}
.dc-head-day.today-hd{background:rgba(21,88,168,.04)}
.dc-head-day.today-hd .dn{color:var(--blue)}

/* Staff row */
.dc-row{display:grid;grid-template-columns:140px repeat(7,1fr);border-bottom:0.5px solid #EEF2F8;min-height:52px;align-items:center}
.dc-row:last-child{border-bottom:none}
.dc-row:hover{background:#FAFCFF}

/* Staff label cell */
.dc-staff-cell{padding:8px 14px;display:flex;align-items:center;gap:8px}
.dc-av{width:30px;height:30px;border-radius:8px;flex-shrink:0;background:linear-gradient(135deg,#1558A8,#4F81D9);color:#fff;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800}
.dc-staff-name{font-size:12.5px;font-weight:600;color:var(--ink);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:88px}
.dc-staff-role{font-size:10px;color:var(--muted)}

/* Day cell với dots */
.dc-day-cell{padding:6px 4px;border-left:1px solid var(--border);min-height:52px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:3px;position:relative}
.dc-day-cell.today-dc{background:rgba(21,88,168,.03)}
.dc-day-cell.empty-dc{color:var(--muted);font-size:10px}

/* Dot chính */
.dc-dot{
  width:28px;height:28px;border-radius:8px;
  display:flex;align-items:center;justify-content:center;
  font-size:10px;font-weight:800;cursor:pointer;
  position:relative;transition:transform .15s,box-shadow .15s;
  text-decoration:none;color:inherit;
}
.dc-dot:hover{transform:scale(1.15);box-shadow:0 4px 12px rgba(0,0,0,.15);z-index:5}
.dc-dot.dot-std{background:rgba(21,88,168,.12);color:#1558A8;border:1.5px solid rgba(21,88,168,.2)}
.dc-dot.dot-long{background:rgba(124,58,237,.12);color:#7C3AED;border:1.5px solid rgba(124,58,237,.2)}
.dc-dot.dot-part{background:rgba(5,150,105,.12);color:#059669;border:1.5px solid rgba(5,150,105,.2)}
.dc-dot.dot-open{background:rgba(217,119,6,.15);color:#D97706;border:1.5px solid rgba(217,119,6,.3);animation:pulse-dot 2s infinite}
.dc-dot.dot-absent{background:rgba(220,38,38,.1);color:#DC2626;border:1.5px solid rgba(220,38,38,.2)}
.dc-dot.dot-leave{background:rgba(99,102,241,.1);color:#6366F1;border:1.5px solid rgba(99,102,241,.2)}
@keyframes pulse-dot{0%,100%{border-color:rgba(217,119,6,.3)}50%{border-color:rgba(217,119,6,.7)}}

/* Tooltip khi hover dot */
.dc-dot-wrap{position:relative;display:inline-block}
.dc-tooltip{
  display:none;position:absolute;z-index:300;
  bottom:calc(100% + 8px);left:50%;transform:translateX(-50%);
  background:#0B1628;color:#fff;border-radius:10px;
  padding:10px 14px;min-width:190px;max-width:230px;
  box-shadow:0 8px 24px rgba(0,0,0,.25);pointer-events:none;
  font-family:'Outfit',sans-serif;
}
.dc-tooltip::after{content:'';position:absolute;top:100%;left:50%;transform:translateX(-50%);border:6px solid transparent;border-top-color:#0B1628}
.dc-dot-wrap:hover .dc-tooltip{display:block}
.tt-name{font-size:13px;font-weight:700;color:#fff;margin-bottom:6px;padding-bottom:5px;border-bottom:1px solid rgba(255,255,255,.15)}
.tt-row{font-size:11.5px;color:rgba(255,255,255,.8);padding:2px 0;display:flex;align-items:center;gap:5px}

/* Add dot button on empty cell */
.dc-add-btn{
  width:26px;height:26px;border-radius:7px;
  background:transparent;border:1.5px dashed var(--border);
  color:var(--muted);font-size:14px;cursor:pointer;
  display:flex;align-items:center;justify-content:center;
  opacity:0;transition:all .15s;text-decoration:none;
}
.dc-day-cell:hover .dc-add-btn{opacity:1}
.dc-day-cell:hover .dc-add-btn:hover{background:var(--blue);border-color:var(--blue);color:#fff}

/* Empty state row */
.dc-empty{padding:32px;text-align:center;color:var(--muted);font-size:13px;grid-column:1/-1}

/* ─────────────────────────────────────────────────────────
   TABLE: Danh sách ca
   ───────────────────────────────────────────────────────── */
.table-card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}
.table-card-head{padding:14px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:10px}
.table-card-head h2{font-size:14px;font-weight:800;color:var(--ink)}
.table-card-sub{font-size:12px;color:var(--muted)}
.tbl-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse}
thead th{padding:10px 16px;background:#F8FAFC;font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;white-space:nowrap;border-bottom:1px solid var(--border)}
tbody td{padding:11px 16px;font-size:13px;color:var(--ink);border-bottom:1px solid #F1F5F9;vertical-align:middle}
tbody tr:last-child td{border-bottom:none}
tbody tr:hover td{background:#F7FBFF}
tbody tr{cursor:pointer}
.staff-cell{display:flex;align-items:center;gap:9px}
.staff-av{width:30px;height:30px;border-radius:8px;flex-shrink:0;background:linear-gradient(135deg,#1558A8,#4F81D9);color:#fff;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800}
.staff-name{font-weight:700;color:var(--ink);font-size:13px}
.staff-role{font-size:11px;color:var(--muted)}
.time-main{font-size:13px;font-weight:600;color:var(--ink)}
.time-date{font-size:11px;color:var(--muted);margin-top:1px}
.dur-active{color:var(--green);font-weight:700;font-size:12.5px;display:flex;align-items:center;gap:4px}
.cash-val{font-size:12.5px;font-weight:700;color:var(--ink)}
.cash-empty{color:var(--muted)}
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 9px;border-radius:20px;font-size:11.5px;font-weight:700;white-space:nowrap}
.badge-open{background:#ECFDF5;color:var(--green)}
.badge-closed{background:#F1F5F9;color:#64748B}
.badge-force{background:#FFF7ED;color:var(--gold)}
.btn-detail{display:inline-flex;align-items:center;gap:5px;padding:5px 11px;background:#EFF6FF;color:var(--blue);border:1.5px solid #BFDBFE;border-radius:7px;font-size:12px;font-weight:700;text-decoration:none;transition:all .18s;cursor:pointer}
.btn-detail:hover{background:#DBEAFE}
.btn-close-shift{display:inline-flex;align-items:center;gap:5px;padding:5px 11px;background:#FFFBEB;color:var(--gold);border:1.5px solid #FDE68A;border-radius:7px;font-size:12px;font-weight:700;text-decoration:none;transition:all .18s}
.btn-close-shift:hover{background:#FEF3C7}
.btn-del{width:28px;height:28px;display:inline-flex;align-items:center;justify-content:center;border-radius:7px;background:#FEF2F2;border:1.5px solid #FECACA;color:var(--red);font-size:13px;cursor:pointer;text-decoration:none;transition:all .18s}
.btn-del:hover{background:#FEE2E2}

/* ── FILTER PANEL (compact, inline) ── */
.filter-row{display:flex;align-items:flex-end;gap:10px;flex-wrap:wrap;margin-bottom:16px;padding:14px 20px;background:var(--white);border:1px solid var(--border);border-radius:var(--radius)}
.fi{display:flex;flex-direction:column;gap:4px;min-width:120px}
.fi label{font-size:10px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.fi input,.fi select{border:1.5px solid var(--border);border-radius:8px;padding:7px 10px;font-family:'Outfit',sans-serif;font-size:12.5px;color:var(--ink);background:var(--surface);outline:none;transition:border .18s;height:36px}
.fi input:focus,.fi select:focus{border-color:var(--blue);background:#fff}
.btn-filter{padding:7px 18px;background:var(--blue);color:#fff;border:none;border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;height:36px;transition:background .18s}
.btn-filter:hover{background:#0D3F85}
.btn-reset{padding:7px 14px;background:var(--surface);color:var(--muted);border:1.5px solid var(--border);border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;cursor:pointer;text-decoration:none;display:inline-flex;align-items:center;height:36px;transition:all .18s}
.btn-reset:hover{border-color:var(--red);color:var(--red)}

/* ── SHIFT TYPES TAB ── */
.types-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:16px}
.types-header h2{font-size:16px;font-weight:800;color:var(--ink)}
.btn-add-type{display:inline-flex;align-items:center;gap:7px;padding:8px 18px;background:linear-gradient(135deg,var(--blue),var(--cyan));color:#fff;border:none;border-radius:9px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;text-decoration:none;box-shadow:0 3px 10px rgba(21,88,168,.2);transition:all .18s}
.btn-add-type:hover{opacity:.9;transform:translateY(-1px)}
.types-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:14px}
.type-card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden;transition:box-shadow .2s,transform .18s}
.type-card:hover{box-shadow:0 6px 24px rgba(21,88,168,.1);transform:translateY(-2px)}
.type-card-head{padding:14px 18px;display:flex;align-items:center;gap:12px;border-bottom:1px solid var(--border)}
.type-dot{width:10px;height:10px;border-radius:3px;flex-shrink:0}
.type-name{font-size:14px;font-weight:800;color:var(--ink);flex:1}
.type-badge{font-size:10px;font-weight:700;padding:2px 8px;border-radius:10px}
.type-active{background:#ECFDF5;color:var(--green)}
.type-inactive{background:#FEF2F2;color:var(--red)}
.type-card-body{padding:14px 18px}
.type-row{display:flex;justify-content:space-between;align-items:center;margin-bottom:8px}
.type-row:last-child{margin-bottom:0}
.type-lbl{font-size:11.5px;color:var(--muted);font-weight:600}
.type-val{font-size:13px;font-weight:700;color:var(--ink)}
.type-dur{font-size:11px;color:var(--muted);font-weight:500;margin-top:2px}
.type-card-foot{padding:10px 18px;border-top:1px solid var(--border);display:flex;gap:8px}
.btn-edit-type{flex:1;padding:7px 0;background:#EFF6FF;color:var(--blue);border:1.5px solid #BFDBFE;border-radius:8px;font-family:'Outfit',sans-serif;font-size:12.5px;font-weight:700;cursor:pointer;transition:all .18s}
.btn-edit-type:hover{background:#DBEAFE}
.btn-toggle-type{padding:7px 14px;background:var(--surface);color:var(--muted);border:1.5px solid var(--border);border-radius:8px;font-family:'Outfit',sans-serif;font-size:12.5px;font-weight:700;cursor:pointer;transition:all .18s}
.btn-toggle-type:hover{border-color:var(--amber);color:var(--gold)}
.btn-del-type{padding:7px 12px;background:#FEF2F2;color:var(--red);border:1.5px solid #FECACA;border-radius:8px;font-family:'Outfit',sans-serif;font-size:12.5px;font-weight:700;cursor:pointer;transition:all .18s}
.btn-del-type:hover{background:#FEE2E2}
.empty-state{text-align:center;padding:48px 20px;color:var(--muted)}
.empty-state .es-icon{font-size:40px;margin-bottom:12px;display:block}
.empty-state h3{font-size:15px;font-weight:700;color:var(--ink);margin-bottom:6px}
.empty-state p{font-size:13px}

/* ── MODAL (dùng cho cả ShiftType + Quick-schedule) ── */
.modal-overlay{
  position:fixed;inset:0;background:rgba(11,22,40,.5);z-index:400;
  display:flex;align-items:center;justify-content:center;
  opacity:0;pointer-events:none;transition:opacity .2s;
}
.modal-overlay.open{opacity:1;pointer-events:auto}
.modal{background:var(--white);border-radius:16px;width:520px;max-width:94vw;max-height:90vh;overflow-y:auto;box-shadow:0 24px 80px rgba(0,0,0,.2);transform:translateY(20px);transition:transform .22s}
.modal-overlay.open .modal{transform:translateY(0)}
.modal-head{padding:18px 22px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;background:var(--white);z-index:1}
.modal-title{font-size:15px;font-weight:800;color:var(--ink)}
.modal-close{width:28px;height:28px;border-radius:7px;border:none;background:var(--surface);color:var(--muted);font-size:14px;cursor:pointer;display:flex;align-items:center;justify-content:center;transition:all .15s}
.modal-close:hover{background:#FEE2E2;color:var(--red)}
.modal-body{padding:22px}
.mfg{display:flex;flex-direction:column;gap:5px;margin-bottom:14px}
.mfg label{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.mfg input,.mfg select,.mfg textarea{border:1.5px solid var(--border);border-radius:9px;padding:9px 12px;font-family:'Outfit',sans-serif;font-size:13.5px;color:var(--ink);background:var(--surface);outline:none;transition:border .18s;width:100%}
.mfg input:focus,.mfg select:focus,.mfg textarea:focus{border-color:var(--blue);background:#fff}
.mfg-row{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.modal-foot{padding:14px 22px;border-top:1px solid var(--border);display:flex;justify-content:flex-end;gap:8px}
.btn-cancel-m{padding:8px 18px;background:var(--surface);color:var(--muted);border:1.5px solid var(--border);border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;cursor:pointer;transition:all .18s}
.btn-cancel-m:hover{border-color:var(--muted)}
.btn-save-m{padding:8px 22px;background:linear-gradient(135deg,var(--blue),var(--cyan));color:#fff;border:none;border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;box-shadow:0 3px 10px rgba(21,88,168,.2);transition:all .18s}
.btn-save-m:hover{opacity:.9}
.field-hint{font-size:11px;color:var(--muted);margin-top:3px}
.field-err{font-size:11px;color:var(--red);margin-top:3px;display:none}

/* Staff chips in quick-schedule modal */
.staff-chips-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(130px,1fr));gap:8px}
.sch-chip{border:1.5px solid var(--border);border-radius:10px;padding:8px 10px;cursor:pointer;transition:all .18s;position:relative}
.sch-chip:has(input:checked){border-color:var(--blue);background:#EFF6FF}
.sch-chip input{position:absolute;opacity:0;width:0;height:0}
.sch-chip-av{width:28px;height:28px;border-radius:7px;background:linear-gradient(135deg,#1558A8,#4F81D9);color:#fff;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;margin-bottom:4px}
.sch-chip-name{font-size:12px;font-weight:700;color:var(--ink)}
.sch-chip-role{font-size:10px;color:var(--muted)}
/* ShiftType cards in modal */
.stype-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(140px,1fr));gap:8px}
.stype-card{border:1.5px solid var(--border);border-radius:10px;padding:10px 12px;cursor:pointer;transition:all .18s;position:relative;text-align:center}
.stype-card:has(input:checked){border-color:var(--blue);background:#EFF6FF}
.stype-card input{position:absolute;opacity:0;width:0;height:0}
.stype-name{font-size:12.5px;font-weight:700;color:var(--ink);margin-top:4px}
.stype-time{font-size:11px;color:var(--muted);margin-top:2px}
.stype-rate{font-size:11px;color:var(--green);font-weight:700;margin-top:3px}
.dur-preview{font-size:12px;color:var(--muted);padding:8px 12px;background:var(--surface);border-radius:8px;margin-top:-6px;margin-bottom:14px}

/* ── MODAL XẾP CA ĐẦY ĐỦ ── */
.sched-overlay{position:fixed;inset:0;background:rgba(11,22,40,.55);z-index:600;display:flex;align-items:center;justify-content:center;opacity:0;pointer-events:none;transition:opacity .22s}
.sched-overlay.open{opacity:1;pointer-events:auto}
.sched-modal{background:var(--white);border-radius:18px;width:640px;max-width:95vw;max-height:88vh;overflow-y:auto;box-shadow:0 28px 80px rgba(0,0,0,.22);transform:translateY(20px);transition:transform .24s;display:flex;flex-direction:column}
.sched-overlay.open .sched-modal{transform:translateY(0)}
.sched-modal-head{padding:18px 24px 14px;border-bottom:0.5px solid var(--border);display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;background:var(--white);z-index:1;border-radius:18px 18px 0 0}
.sched-modal-title{font-size:16px;font-weight:800;color:var(--ink);display:flex;align-items:center;gap:8px}
.sched-modal-close{width:28px;height:28px;border-radius:8px;border:none;background:var(--surface);color:var(--muted);font-size:14px;cursor:pointer;display:flex;align-items:center;justify-content:center;transition:all .15s}
.sched-modal-close:hover{background:#FEE2E2;color:var(--red)}
.sched-modal-body{padding:20px 24px;flex:1}
.sched-section{margin-bottom:20px}
.sched-section-title{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.6px;margin-bottom:10px;display:flex;align-items:center;gap:6px}
/* Staff chips */
.staff-chips-wrap{display:flex;flex-wrap:wrap;gap:8px;padding:10px;background:var(--surface);border-radius:10px;border:1.5px solid var(--border);min-height:50px}
.sc-chip{display:flex;align-items:center;gap:7px;padding:6px 12px;background:var(--white);border:1.5px solid var(--border);border-radius:20px;font-size:12.5px;cursor:pointer;transition:all .18s;user-select:none}
.sc-chip input[type=checkbox]{accent-color:var(--blue);width:13px;height:13px}
.sc-chip:has(input:checked){background:#EFF6FF;border-color:var(--blue)}
.sc-chip-name{font-weight:600;color:var(--ink)}
.sc-chip-role{font-size:10px;color:var(--muted)}
.sc-all-btn{font-size:11.5px;color:var(--blue);font-weight:600;cursor:pointer;background:none;border:none;padding:0;margin-bottom:6px}
/* ShiftType cards — dạng checkbox multi-select */
.stype-cards-wrap{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:8px}
.stc{border:1.5px solid var(--border);border-radius:12px;padding:12px 14px;cursor:pointer;transition:all .18s;position:relative;text-align:center;user-select:none}
.stc:has(input:checked){border-color:var(--blue);background:#EFF6FF}
.stc input{position:absolute;opacity:0;width:0;height:0}
.stc-icon{font-size:22px;margin-bottom:5px}
.stc-name{font-size:12.5px;font-weight:700;color:var(--ink)}
.stc-time{font-size:10.5px;color:var(--muted);margin-top:2px}
.stc-rate{font-size:11px;color:var(--green);font-weight:700;margin-top:4px}
/* Ngày */
.date-row{display:grid;grid-template-columns:1fr 28px 1fr;gap:8px;align-items:center}
.date-sep{text-align:center;font-weight:700;color:var(--muted);font-size:15px}
.sched-fi{display:flex;flex-direction:column;gap:4px}
.sched-fi label{font-size:10px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.sched-fi input,.sched-fi textarea{border:1.5px solid var(--border);border-radius:9px;padding:8px 11px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);background:var(--surface);outline:none;transition:border .18s;width:100%}
.sched-fi input:focus,.sched-fi textarea:focus{border-color:var(--blue);background:#fff}
/* Preview box */
.sched-preview{background:var(--surface);border:1px solid var(--border);border-radius:9px;padding:10px 14px;font-size:12.5px;color:var(--muted);display:none;margin-top:10px}
.sched-preview strong{color:var(--ink)}
.sched-preview .sched-preview-count{font-size:15px;font-weight:800;color:var(--blue)}
/* Footer */
.sched-modal-foot{padding:14px 24px;border-top:0.5px solid var(--border);display:flex;justify-content:space-between;align-items:center;position:sticky;bottom:0;background:var(--white);border-radius:0 0 18px 18px}
.btn-sched-cancel{padding:8px 18px;background:var(--surface);color:var(--muted);border:1.5px solid var(--border);border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;cursor:pointer;transition:all .18s}
.btn-sched-cancel:hover{border-color:var(--red);color:var(--red)}
.btn-sched-submit{padding:8px 26px;background:linear-gradient(135deg,var(--blue),var(--cyan));color:#fff;border:none;border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;box-shadow:0 3px 12px rgba(21,88,168,.25);transition:all .18s}
.btn-sched-submit:hover{opacity:.9;transform:translateY(-1px)}

/* ── WEEK GRID CSS (bị thiếu) ── */
.week-nav-row{display:flex;align-items:center;gap:10px;margin-bottom:16px;flex-wrap:wrap}
.week-period{font-size:15px;font-weight:800;color:var(--ink)}
.week-sub{font-size:12px;color:var(--muted)}
.btn-nav{padding:5px 12px;border:1.5px solid var(--border);border-radius:8px;background:var(--white);font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;color:var(--ink);cursor:pointer;text-decoration:none;transition:all .18s;display:inline-flex;align-items:center}
.btn-nav:hover{border-color:var(--blue);color:var(--blue)}
.week-grid{display:grid;grid-template-columns:repeat(7,1fr);gap:8px;margin-bottom:20px}
.day-col{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden;min-height:160px}
.day-col.today-col{border-color:var(--blue);box-shadow:0 0 0 2px rgba(21,88,168,.1)}
.day-head{padding:10px 8px;border-bottom:1px solid var(--border);text-align:center}
.day-name{font-size:10px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.day-date{font-size:20px;font-weight:900;color:var(--ink);margin-top:1px;line-height:1}
.day-col.today-col .day-date{color:var(--blue)}
.day-body{padding:7px}
.shift-chip{padding:6px 8px;border-radius:8px;margin-bottom:5px;font-size:11.5px;cursor:pointer;transition:opacity .15s;position:relative}
.shift-chip:hover{opacity:.82}
.chip-morning{background:#EFF6FF;border:1px solid #BFDBFE}
.chip-afternoon{background:#FFF7ED;border:1px solid #FED7AA}
.chip-night{background:#F5F3FF;border:1px solid #DDD6FE}
.chip-name{font-weight:700;color:var(--ink);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;font-size:11.5px;max-width:100%}
.chip-time{font-size:10px;color:var(--muted);margin-top:1px}
.chip-status{display:inline-flex;align-items:center;gap:3px;font-size:10px;font-weight:700;margin-top:3px;padding:1px 6px;border-radius:10px}
.st-scheduled{background:#DBEAFE;color:#1E40AF}
.st-confirmed{background:#D1FAE5;color:#065F46}
.st-absent{background:#FEE2E2;color:#991B1B}
.st-leave{background:#FEF3C7;color:#92400E}
.st-sys-closed{background:#EEF2FF;color:#4338CA}
.chip-cancel{position:absolute;top:3px;right:3px;width:15px;height:15px;border-radius:50%;background:rgba(220,38,38,.1);border:none;color:var(--red);font-size:9px;cursor:pointer;display:none;align-items:center;justify-content:center;line-height:1}
.shift-chip:hover .chip-cancel{display:flex}
.day-add{display:flex;align-items:center;justify-content:center;padding:7px;color:var(--muted);font-size:11px;border:1.5px dashed var(--border);border-radius:8px;cursor:pointer;transition:all .18s;margin-top:4px;background:transparent;width:100%;box-sizing:border-box}
.day-add:hover{border-color:var(--blue);color:var(--blue);background:#EFF6FF}
.empty-day{color:var(--muted);font-size:11px;text-align:center;padding:18px 0}
/* Quick form */
.quick-form-card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);padding:16px 20px;margin-bottom:16px}
.quick-form-card h3{font-size:13px;font-weight:800;color:var(--ink);margin-bottom:12px;display:flex;align-items:center;gap:6px}
.qf-grid{display:grid;grid-template-columns:1fr 1fr 1fr auto;gap:10px;align-items:flex-end}
.qfi{display:flex;flex-direction:column;gap:4px}
.qfi label{font-size:10px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.qfi select,.qfi input{border:1.5px solid var(--border);border-radius:8px;padding:7px 10px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);background:var(--surface);outline:none;height:36px;width:100%}
.qfi select:focus,.qfi input:focus{border-color:var(--blue);background:#fff}
.btn-qf-submit{padding:7px 20px;background:var(--blue);color:#fff;border:none;border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;height:36px;white-space:nowrap;transition:background .18s}
.btn-qf-submit:hover{background:#0D3F85}
/* Modal search staff */
.staff-search-wrap{position:relative;margin-bottom:8px}
.staff-search-input{width:100%;border:1.5px solid var(--border);border-radius:9px;padding:8px 12px 8px 36px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);background:var(--surface);outline:none;transition:border .18s;box-sizing:border-box}
.staff-search-input:focus{border-color:var(--blue);background:#fff}
.staff-search-icon{position:absolute;left:11px;top:50%;transform:translateY(-50%);color:var(--muted);font-size:14px;pointer-events:none}
.staff-chips-wrap{display:flex;flex-wrap:wrap;gap:8px;padding:10px;background:var(--surface);border-radius:10px;border:1.5px solid var(--border);min-height:50px;max-height:180px;overflow-y:auto}
.sc-chip{display:flex;align-items:center;gap:7px;padding:6px 12px;background:var(--white);border:1.5px solid var(--border);border-radius:20px;font-size:12.5px;cursor:pointer;transition:all .18s;user-select:none}
.sc-chip.hidden{display:none}
.sc-chip input[type=checkbox]{accent-color:var(--blue);width:13px;height:13px;flex-shrink:0}
.sc-chip:has(input:checked){background:#EFF6FF;border-color:var(--blue)}
.sc-chip-name{font-weight:600;color:var(--ink)}
.sc-chip-role{font-size:10px;color:var(--muted)}
.sc-all-btn{font-size:12px;color:var(--blue);font-weight:600;cursor:pointer;background:none;border:none;padding:0;margin-bottom:6px;display:inline-flex;align-items:center;gap:4px}

/* ── CHIP TOOLTIP (hover info đầy đủ) ── */
.chip-wrap{position:relative;display:block}
.chip-tooltip{
  display:none;position:absolute;z-index:200;
  bottom:calc(100% + 8px);left:50%;transform:translateX(-50%);
  background:#0B1628;color:#fff;border-radius:12px;
  padding:12px 16px;min-width:210px;max-width:260px;
  box-shadow:0 8px 28px rgba(0,0,0,.3);pointer-events:none;
  font-family:'Outfit',sans-serif;
}
.chip-tooltip::after{
  content:'';position:absolute;top:100%;left:50%;
  transform:translateX(-50%);
  border:7px solid transparent;border-top-color:#0B1628
}
/* Mở rộng chiều cao cột để tooltip không bị clip */
.day-body{overflow:visible!important}
.week-grid{overflow:visible!important}
.day-col{overflow:visible!important}
.chip-wrap:hover .chip-tooltip{display:block}
.chip-wrap:hover .shift-chip{opacity:.9}
.tt-head{font-size:13px;font-weight:800;color:#fff;margin-bottom:8px;padding-bottom:7px;border-bottom:1px solid rgba(255,255,255,.15)}
.tt-row{font-size:12px;color:rgba(255,255,255,.8);padding:3px 0;display:flex;align-items:flex-start;gap:7px;line-height:1.4}
.tt-icon{flex-shrink:0;width:14px;text-align:center}
.tt-val{color:#fff;font-weight:500}
.tt-badge{display:inline-block;padding:2px 8px;border-radius:8px;font-size:11px;font-weight:700}
.tt-scheduled{background:#1E40AF;color:#DBEAFE}
.tt-confirmed{background:#065F46;color:#D1FAE5}
.tt-absent{background:#991B1B;color:#FEE2E2}
.tt-leave{background:#92400E;color:#FEF3C7}
.tt-sys{background:#4338CA;color:#EEF2FF}

/* ── CHIP ACTION BUTTONS (edit/delete) ── */
.chip-actions{display:flex;gap:4px;margin-top:5px}
.chip-btn{display:inline-flex;align-items:center;justify-content:center;gap:3px;padding:3px 8px;border-radius:6px;font-size:10.5px;font-weight:700;cursor:pointer;border:none;font-family:'Outfit',sans-serif;transition:all .15s;white-space:nowrap}
.chip-btn-edit{background:#EFF6FF;color:#1558A8}
.chip-btn-edit:hover{background:#DBEAFE}
.chip-btn-del{background:#FEF2F2;color:#DC2626}
.chip-btn-del:hover{background:#FEE2E2}
.chip-btn-add-next{background:#ECFDF5;color:#059669}
.chip-btn-add-next:hover{background:#D1FAE5}
/* Chip đang active (CONFIRMED) — không edit được */
.chip-active-note{font-size:10px;color:#059669;font-weight:600;margin-top:4px;padding:2px 6px;background:#ECFDF5;border-radius:5px;display:inline-block}
/* Edit modal */
.edit-modal-overlay{position:fixed;inset:0;background:rgba(11,22,40,.5);z-index:700;display:flex;align-items:center;justify-content:center;opacity:0;pointer-events:none;transition:opacity .2s}
.edit-modal-overlay.open{opacity:1;pointer-events:auto}
.edit-modal{background:var(--white);border-radius:16px;width:480px;max-width:94vw;box-shadow:0 24px 70px rgba(0,0,0,.22);transform:translateY(16px);transition:transform .22s}
.edit-modal-overlay.open .edit-modal{transform:translateY(0)}
.em-head{padding:16px 20px;border-bottom:0.5px solid var(--border);display:flex;align-items:center;justify-content:space-between}
.em-title{font-size:14px;font-weight:800;color:var(--ink)}
.em-close{width:26px;height:26px;border-radius:7px;border:none;background:var(--surface);color:var(--muted);font-size:13px;cursor:pointer;display:flex;align-items:center;justify-content:center}
.em-close:hover{background:#FEE2E2;color:var(--red)}
.em-body{padding:18px 20px}
.em-row{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:12px}
.em-fg{display:flex;flex-direction:column;gap:4px}
.em-fg.full{grid-column:1/-1}
.em-fg label{font-size:10px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.em-fg select,.em-fg input,.em-fg textarea{border:1.5px solid var(--border);border-radius:8px;padding:8px 10px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);background:var(--surface);outline:none;width:100%;transition:border .18s}
.em-fg select:focus,.em-fg input:focus,.em-fg textarea:focus{border-color:var(--blue);background:#fff}
.em-foot{padding:12px 20px;border-top:0.5px solid var(--border);display:flex;justify-content:flex-end;gap:8px}
.em-cancel{padding:7px 16px;background:var(--surface);color:var(--muted);border:1.5px solid var(--border);border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;cursor:pointer}
.em-submit{padding:7px 20px;background:var(--blue);color:#fff;border:none;border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer}
/* Delete modal */
.del-modal-overlay{position:fixed;inset:0;background:rgba(11,22,40,.5);z-index:700;display:flex;align-items:center;justify-content:center;opacity:0;pointer-events:none;transition:opacity .2s}
.del-modal-overlay.open{opacity:1;pointer-events:auto}
.del-modal{background:var(--white);border-radius:16px;width:560px;max-width:94vw;max-height:85vh;overflow-y:auto;box-shadow:0 24px 70px rgba(0,0,0,.22);transform:translateY(16px);transition:transform .22s}
.del-modal-overlay.open .del-modal{transform:translateY(0)}
.dm-head{padding:16px 20px;border-bottom:0.5px solid var(--border);display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;background:var(--white);z-index:1}
.dm-title{font-size:14px;font-weight:800;color:var(--ink)}
.dm-close{width:26px;height:26px;border-radius:7px;border:none;background:var(--surface);color:var(--muted);font-size:13px;cursor:pointer;display:flex;align-items:center;justify-content:center}
.dm-close:hover{background:#FEE2E2;color:var(--red)}
.dm-body{padding:16px 20px}
.dm-staff-row{display:flex;align-items:center;gap:10px;padding:10px 14px;background:var(--surface);border-radius:10px;margin-bottom:14px}
.dm-staff-av{width:36px;height:36px;border-radius:9px;background:linear-gradient(135deg,#1558A8,#4F81D9);color:#fff;display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:800;flex-shrink:0}
.dm-date-row{display:grid;grid-template-columns:1fr 24px 1fr;gap:8px;align-items:center;margin-bottom:12px}
.dm-sep{text-align:center;color:var(--muted);font-weight:700}
.dm-fg{display:flex;flex-direction:column;gap:4px}
.dm-fg label{font-size:10px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.dm-fg input,.dm-fg select{border:1.5px solid var(--border);border-radius:8px;padding:7px 10px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);background:var(--surface);outline:none;width:100%}
.dm-preview{margin-top:10px;padding:10px 14px;background:var(--surface);border-radius:9px;font-size:12.5px;color:var(--muted);display:none}
.dm-preview strong{color:var(--ink)}
.dm-list{max-height:200px;overflow-y:auto;border:0.5px solid var(--border);border-radius:9px;margin-top:10px}
.dm-item{display:flex;align-items:center;justify-content:space-between;padding:9px 14px;border-bottom:0.5px solid var(--border);font-size:12.5px}
.dm-item:last-child{border-bottom:none}
.dm-item-check{accent-color:var(--red)}
.dm-item-info{flex:1;margin-left:8px}
.dm-item-name{font-weight:600;color:var(--ink)}
.dm-item-meta{font-size:11px;color:var(--muted)}
.dm-foot{padding:12px 20px;border-top:0.5px solid var(--border);display:flex;justify-content:space-between;align-items:center;position:sticky;bottom:0;background:var(--white)}
.dm-cancel{padding:7px 16px;background:var(--surface);color:var(--muted);border:1.5px solid var(--border);border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;cursor:pointer}
.dm-confirm{padding:7px 20px;background:#DC2626;color:#fff;border:none;border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer}
.dm-count{font-size:12px;color:var(--muted)}

/* ── SELECT MODE (edit/delete checkbox overlay) ── */
.sel-chip-wrap{position:relative}
.sel-chip-check{position:absolute;top:6px;left:6px;width:18px;height:18px;
  accent-color:var(--blue);cursor:pointer;z-index:10;display:none}
.sel-chip-check.del-mode{accent-color:#DC2626}
.select-mode-active .sel-chip-check{display:block}
.shift-chip.chip-selected{outline:2.5px solid var(--blue);outline-offset:1px}
.shift-chip.chip-selected-del{outline:2.5px solid #DC2626;outline-offset:1px}
/* Modal chọn ca (edit/delete) — dùng lại sched-overlay CSS */
.selmode-overlay{position:fixed;inset:0;background:rgba(11,22,40,.5);z-index:700;
  display:flex;align-items:center;justify-content:center;
  opacity:0;pointer-events:none;transition:opacity .2s}
.selmode-overlay.open{opacity:1;pointer-events:auto}
.selmode-modal{background:var(--white);border-radius:18px;width:900px;max-width:96vw;
  max-height:90vh;overflow-y:auto;box-shadow:0 28px 80px rgba(0,0,0,.25);
  transform:translateY(18px);transition:transform .24s;display:flex;flex-direction:column}
.selmode-overlay.open .selmode-modal{transform:translateY(0)}
.sm-head{padding:16px 22px;border-bottom:0.5px solid var(--border);display:flex;
  align-items:center;justify-content:space-between;position:sticky;top:0;
  background:var(--white);z-index:2;border-radius:18px 18px 0 0;gap:12px}
.sm-title{font-size:15px;font-weight:800;color:var(--ink);flex-shrink:0}
.sm-selected-badge{background:#EFF6FF;color:#1558A8;padding:3px 12px;border-radius:20px;
  font-size:12px;font-weight:700;display:none}
.sm-selected-badge.del-badge{background:#FEF2F2;color:#DC2626}
.sm-selected-badge.show{display:inline-block}
.sm-close{width:28px;height:28px;border-radius:8px;border:none;background:var(--surface);
  color:var(--muted);font-size:14px;cursor:pointer;display:flex;align-items:center;
  justify-content:center;flex-shrink:0}
.sm-close:hover{background:#FEE2E2;color:var(--red)}
.sm-instructions{padding:10px 22px;background:#F8FAFC;border-bottom:0.5px solid var(--border);
  font-size:12.5px;color:var(--muted);display:flex;align-items:center;gap:8px}
.sm-body{padding:16px 22px;flex:1}
/* Grid trong modal select — nhỏ hơn, 7 cột */
.sm-week-grid{display:grid;grid-template-columns:repeat(7,1fr);gap:6px;margin-bottom:0}
.sm-day-col{background:var(--surface);border:1px solid var(--border);border-radius:10px;
  overflow:visible;min-height:80px}
.sm-day-col.sm-today{border-color:var(--blue)}
.sm-day-head{padding:7px 6px;border-bottom:0.5px solid var(--border);text-align:center}
.sm-day-name{font-size:9px;font-weight:700;color:var(--muted);text-transform:uppercase}
.sm-day-date{font-size:16px;font-weight:900;color:var(--ink);line-height:1}
.sm-today .sm-day-date{color:var(--blue)}
.sm-day-body{padding:5px}
.sm-chip{padding:6px 8px;border-radius:7px;margin-bottom:4px;font-size:11px;
  cursor:pointer;transition:all .15s;position:relative;border:2px solid transparent;
  user-select:none}
.sm-chip:hover{opacity:.85}
.sm-chip.sm-morning{background:#EFF6FF}
.sm-chip.sm-afternoon{background:#FFF7ED}
.sm-chip.sm-night{background:#F5F3FF}
.sm-chip.sm-selected-edit{border-color:var(--blue)!important;background:#DBEAFE!important}
.sm-chip.sm-selected-del{border-color:#DC2626!important;background:#FEE2E2!important}
.sm-chip.sm-locked{opacity:.45;cursor:not-allowed}
.sm-chip-name{font-weight:700;color:var(--ink);font-size:11px;
  white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.sm-chip-type{font-size:10px;color:var(--muted)}
.sm-chip-status{font-size:9.5px;font-weight:700;margin-top:2px;
  padding:1px 5px;border-radius:8px;display:inline-block}
.sm-lock-badge{font-size:9px;color:var(--muted);font-style:italic;margin-top:2px;display:block}
.sm-empty{font-size:10.5px;color:var(--muted);text-align:center;padding:12px 0}
.sm-add-btn{display:flex;align-items:center;justify-content:center;
  padding:5px;color:var(--muted);font-size:10px;border:1px dashed var(--border);
  border-radius:6px;cursor:pointer;transition:all .18s;margin-top:3px;background:transparent}
.sm-add-btn:hover{border-color:var(--blue);color:var(--blue);background:#EFF6FF}
.sm-foot{padding:14px 22px;border-top:0.5px solid var(--border);display:flex;
  justify-content:space-between;align-items:center;position:sticky;bottom:0;
  background:var(--white);border-radius:0 0 18px 18px;gap:10px}
.sm-foot-hint{font-size:12px;color:var(--muted);flex:1}
.sm-cancel-btn{padding:8px 18px;background:var(--surface);color:var(--muted);
  border:1.5px solid var(--border);border-radius:8px;font-family:'Outfit',sans-serif;
  font-size:13px;font-weight:600;cursor:pointer}
.sm-action-btn{padding:8px 22px;border:none;border-radius:8px;font-family:'Outfit',sans-serif;
  font-size:13px;font-weight:700;cursor:pointer;transition:all .18s;opacity:.5;cursor:not-allowed}
.sm-action-btn.enabled{opacity:1;cursor:pointer}
.sm-action-edit{background:var(--blue);color:#fff}
.sm-action-del{background:#DC2626;color:#fff}
/* Edit panel (hiện khi đã chọn ca để sửa) */
.sm-edit-panel{background:var(--surface);border-radius:10px;padding:14px 16px;
  margin-top:14px;border:1px solid var(--border);display:none}
.sm-edit-panel.show{display:block}
.sm-edit-panel h4{font-size:12px;font-weight:700;color:var(--ink);margin-bottom:10px}
.sm-edit-grid{display:grid;grid-template-columns:1fr 1fr 1fr;gap:10px}
.sm-efg{display:flex;flex-direction:column;gap:4px}
.sm-efg label{font-size:10px;font-weight:700;color:var(--muted);
  text-transform:uppercase;letter-spacing:.5px}
.sm-efg select,.sm-efg input{border:1.5px solid var(--border);border-radius:8px;
  padding:7px 10px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);
  background:#fff;outline:none;width:100%}
.sm-efg select:focus,.sm-efg input:focus{border-color:var(--blue)}
.sm-efg.span2{grid-column:span 2}
.sm-efg.span3{grid-column:span 3}
</style>
</head>
<body>

<%-- ── SIDEBAR ── --%>
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">

  <%-- Toast --%>
  <c:if test="${not empty param.msg}">
    <c:choose>
      <c:when test="${param.msg == 'opened'}">       <div class="toast toast-ok"   id="toast">✅ Mở ca thành công!</div></c:when>
      <c:when test="${param.msg == 'closed'}">       <div class="toast toast-ok"   id="toast">✅ Đóng ca thành công!</div></c:when>
      <c:when test="${param.msg == 'force-closed'}"> <div class="toast toast-info" id="toast">🔒 Admin đã đóng ca.</div></c:when>
      <c:when test="${param.msg == 'deleted'}">      <div class="toast toast-ok"   id="toast">🗑️ Xóa ca thành công!</div></c:when>
      <c:when test="${param.msg == 'created'}">      <div class="toast toast-ok"   id="toast">✅ Xếp ca thành công!</div></c:when>
      <c:when test="${param.msg == 'updated'}">      <div class="toast toast-ok"   id="toast">✅ Cập nhật ca thành công!</div></c:when>
      <c:when test="${param.msg == 'cancelled'}">    <div class="toast toast-info" id="toast">🚫 Đã hủy lịch ca!</div></c:when>
      <c:when test="${param.msg == 'delete-failed'}"><div class="toast toast-err"  id="toast">❌ Không thể xóa — ca đã có hóa đơn!</div></c:when>
      <c:when test="${param.msg == 'already-open'}"> <div class="toast toast-warn" id="toast">⚠️ Nhân viên đang có ca chưa đóng!</div></c:when>
      <c:when test="${param.msg == 'sched-created'}"><div class="toast toast-ok" id="toast">✅ Đã xếp ${param.count} lịch ca! <c:if test="${param.skip > 0}">(bỏ qua ${param.skip} đã tồn tại)</c:if></div></c:when>
      <c:when test="${param.msg == 'quick-sched'}"><div class="toast toast-ok" id="toast">✅ Xếp ca nhanh thành công!</div></c:when>
      <c:when test="${param.msg == 'cancelled'}"><div class="toast toast-info" id="toast">🗑️ Đã hủy lịch ca.</div></c:when>
      <c:when test="${param.msg == 'sched-exists'}"><div class="toast toast-warn" id="toast">⚠️ Lịch ca đã tồn tại, bỏ qua.</div></c:when>
      <c:when test="${param.msg == 'sched-updated'}"><div class="toast toast-ok" id="toast">✅ Đã cập nhật lịch ca!</div></c:when>
      <c:when test="${param.msg == 'bulk-updated'}"><div class="toast toast-ok" id="toast">✅ Đã cập nhật ${param.count} ca!</div></c:when>
      <c:when test="${param.msg == 'bulk-deleted'}"><div class="toast toast-ok" id="toast">🗑️ Đã xóa ${param.count} ca!</div></c:when>
      <c:when test="${param.msg == 'sched-update-err'}"><div class="toast toast-err" id="toast">❌ Không thể sửa — ca đang hoạt động!</div></c:when>
      <c:when test="${param.msg == 'sched-deleted'}"><div class="toast toast-ok" id="toast">🗑️ Đã xóa ${param.count} lịch ca!<c:if test="${not empty param.skip}"> (bỏ qua ${param.skip} ca đang hoạt động)</c:if></div></c:when>
      <c:when test="${param.msg == 'quick-sched'}"><div class="toast toast-ok" id="toast">✅ Xếp ca nhanh thành công!</div></c:when>
      <c:when test="${param.msg == 'cancelled'}"><div class="toast toast-info" id="toast">🗑️ Đã hủy lịch ca.</div></c:when>
      <c:when test="${param.msg == 'type-saved'}">   <div class="toast toast-ok"   id="toast">✅ Lưu loại ca thành công!</div></c:when>
      <c:when test="${param.msg == 'type-deleted'}"> <div class="toast toast-ok"   id="toast">🗑️ Xóa loại ca thành công!</div></c:when>
      <c:when test="${param.msg == 'type-err'}">     <div class="toast toast-err"  id="toast">❌ Lỗi khi lưu loại ca!</div></c:when>
      <c:when test="${param.msg == 'sched-bulk-ok'}"><div class="toast toast-ok" id="toast">✅ Đã xếp ${param.count} lịch ca! <c:if test="${param.skip > 0}">(bỏ qua ${param.skip} trùng)</c:if></div></c:when>
      <c:when test="${param.msg == 'sched-bulk-err'}"><div class="toast toast-err" id="toast">❌ Lỗi khi xếp ca!</div></c:when>
      <c:otherwise>                                  <div class="toast toast-warn" id="toast">⚠️ Có lỗi xảy ra.</div></c:otherwise>
    </c:choose>
  </c:if>

  <%-- Topbar --%>
  <header class="topbar">
    <div class="topbar-left">
      <div class="topbar-icon">🕐</div>
      <div class="topbar-title">Ca làm việc</div>
    </div>
    <div class="topbar-right">
      <span class="topbar-pill pill-total">📋 ${totalCount} ca</span>
      <span class="topbar-pill pill-open">🟢 ${openCount} đang mở</span>
      <span class="topbar-pill pill-staff">👥 ${fn:length(allStaff)} nhân viên</span>
      <a href="${pageContext.request.contextPath}/dashboard" class="topbar-user">
        <div class="topbar-av"><%= initials %></div>
        <span class="topbar-name"><%= fullName %></span>
      </a>
    </div>
  </header>

  <div class="content">

    <%-- KPI strip --%>
    <div class="kpi-strip">
      <div class="kpi">
        <div class="kpi-icon kpi-blue">📋</div>
        <div><div class="kpi-num">${totalCount}</div><div class="kpi-lbl">Tổng ca</div></div>
      </div>
      <div class="kpi">
        <div class="kpi-icon kpi-green">🟢</div>
        <div><div class="kpi-num" style="color:var(--green)">${openCount}</div><div class="kpi-lbl">Đang mở</div></div>
      </div>
      <div class="kpi">
        <div class="kpi-icon kpi-amber">⚠️</div>
        <div><div class="kpi-num" style="color:var(--gold)">${forceClosedCount}</div><div class="kpi-lbl">Đóng muộn</div></div>
      </div>
      <div class="kpi">
        <div class="kpi-icon kpi-purple">👥</div>
        <div><div class="kpi-num" style="color:var(--purple)">${fn:length(allStaff)}</div><div class="kpi-lbl">Nhân viên</div></div>
      </div>
    </div>

    <%-- Tab bar --%>
    <div class="tab-bar">
      <button class="tab-btn <%= ("week".equals(activeTab)||"list".equals(activeTab)) ? "active" : "" %>" onclick="switchTab('list',this)">📅 Ca làm việc</button>
      <button class="tab-btn <%= "revenue".equals(activeTab) ? "active" : "" %>"  onclick="switchTab('revenue',this)">💰 Doanh thu</button>
      <button class="tab-btn <%= "types".equals(activeTab) ? "active" : "" %>"    onclick="switchTab('types',this)">⚙️ Loại ca</button>
      <button class="tab-btn <%= "leave".equals(activeTab) ? "active" : "" %>"    onclick="switchTab('leave',this)">
        🏖️ Nghỉ phép
        <c:if test="${pendingLeaveCount > 0}">
          <span style="background:#DC2626;color:#fff;font-size:10px;font-weight:800;
                       padding:1px 6px;border-radius:10px;margin-left:4px">${pendingLeaveCount}</span>
        </c:if>
      </button>
    </div>

    <%-- ══════════════════════════════════════════════
         TAB: LỊCH CA TUẦN (Week Grid)
         ══════════════════════════════════════════════ --%>
    <div id="tab-list" class="tab-pane <%= ("week".equals(activeTab)||"list".equals(activeTab)) ? "active" : "" %>">


      <%-- Week navigation --%>
      <div class="week-nav-row">
        <a href="${pageContext.request.contextPath}/shifts?tab=list&w=${param.w != null ? param.w - 1 : -1}" class="btn-nav">‹</a>
        <span class="week-period">📅 Tuần ${weekStart} → ${weekEnd}</span>
        <a href="${pageContext.request.contextPath}/shifts?tab=list&w=${param.w != null ? param.w + 1 : 1}"  class="btn-nav">›</a>
        <a href="${pageContext.request.contextPath}/shifts?tab=list" class="btn-nav">Hôm nay</a>
        <span class="week-sub">✕ để hủy • hover để xem chi tiết</span>
        <div style="margin-left:auto;display:flex;gap:8px;align-items:center">
          <button onclick="openEditSelectModal()" style="display:inline-flex;align-items:center;gap:6px;padding:9px 16px;background:#fff;color:#1558A8;border:1.5px solid #BFDBFE;border-radius:10px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;transition:all .18s" onmouseover="this.style.background='#EFF6FF'" onmouseout="this.style.background='#fff'">
            ✏️ Sửa ca
          </button>
          <button onclick="openDeleteSelectModal()" style="display:inline-flex;align-items:center;gap:6px;padding:9px 16px;background:#fff;color:#DC2626;border:1.5px solid #FECACA;border-radius:10px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;transition:all .18s" onmouseover="this.style.background='#FEF2F2'" onmouseout="this.style.background='#fff'">
            🗑️ Xóa ca
          </button>
          <button onclick="openFullSchedModal()" style="display:inline-flex;align-items:center;gap:6px;padding:9px 18px;background:linear-gradient(135deg,var(--blue),var(--cyan));color:#fff;border:none;border-radius:10px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;box-shadow:0 3px 12px rgba(21,88,168,.25);transition:all .18s">
            + Xếp ca mới
          </button>
        </div>
      </div>

      <%-- 7-day grid --%>
      <div class="week-grid">
        <c:forEach begin="0" end="6" var="i">
          <c:set var="dayDate" value="${weekDays[i]}"/>
          <c:set var="isToday" value="${dayDate.equals(today)}"/>
          <div class="day-col ${isToday ? 'today-col' : ''}">
            <div class="day-head">
              <div class="day-name">${weekDayNames[i]}</div>
              <div class="day-date">${dayDate.dayOfMonth}</div>
              <div style="font-size:9px;color:var(--muted)">${dayDate.monthValue}/${dayDate.year}</div>
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
                  <div class="chip-wrap">
                    <div class="shift-chip ${chipClass}">
                      <div class="chip-name">${sc.staffName}</div>
                      <div class="chip-time">${sc.shiftTypeName}</div>
                      <div class="chip-status
                        <c:choose>
                          <c:when test="${sc.status=='CONFIRMED'}">st-confirmed</c:when>
                          <c:when test="${sc.status=='ABSENT'}">st-absent</c:when>
                          <c:when test="${sc.status=='ON_LEAVE' or sc.status=='LEAVE_PENDING'}">st-leave</c:when>
                          <c:when test="${sc.status=='SYSTEM_CLOSED'}">st-sys-closed</c:when>
                          <c:otherwise>st-scheduled</c:otherwise>
                        </c:choose>
                      ">
                        <c:choose>
                          <c:when test="${sc.status=='CONFIRMED'}">✅ Đúng giờ</c:when>
                          <c:when test="${sc.status=='ABSENT'}">❌ Vắng</c:when>
                          <c:when test="${sc.status=='ON_LEAVE'}">🏖️ Nghỉ phép</c:when>
                          <c:when test="${sc.status=='SYSTEM_CLOSED'}">🔒 Hệ thống đóng</c:when>
                          <c:otherwise>⏳ Chưa vào</c:otherwise>
                        </c:choose>
                      </div>
                      <c:if test="${sc.status=='SCHEDULED' or sc.status=='LEAVE_PENDING'}">
                        <button class="chip-cancel"
                          onclick="event.stopPropagation();cancelSchedule(${sc.scheduleId})">✕</button>
                      </c:if>
                    </div>
                    <%-- TOOLTIP hover --%>
                    <div class="chip-tooltip">
                      <div class="tt-head">${sc.staffName}</div>
                      <div class="tt-row"><span class="tt-icon">📋</span><span>${sc.shiftTypeName}</span></div>
                      <c:if test="${not empty sc.plannedStart}">
                        <div class="tt-row"><span class="tt-icon">🕐</span>
                          <span><span class="tt-val">${fn:substring(sc.plannedStart.toString(),11,16)}</span>
                          → <span class="tt-val">${fn:substring(sc.plannedEnd.toString(),11,16)}</span></span>
                        </div>
                      </c:if>
                      <div class="tt-row"><span class="tt-icon">📅</span>
                        <span>${sc.workDate.dayOfMonth}/${sc.workDate.monthValue}/${sc.workDate.year}</span>
                      </div>
                      <div class="tt-row"><span class="tt-icon">📌</span>
                        <span class="tt-badge
                          <c:choose>
                            <c:when test="${sc.status=='CONFIRMED'}">tt-confirmed</c:when>
                            <c:when test="${sc.status=='ABSENT'}">tt-absent</c:when>
                            <c:when test="${sc.status=='ON_LEAVE' or sc.status=='LEAVE_PENDING'}">tt-leave</c:when>
                            <c:when test="${sc.status=='SYSTEM_CLOSED'}">tt-sys</c:when>
                            <c:otherwise>tt-scheduled</c:otherwise>
                          </c:choose>
                        ">
                          <c:choose>
                            <c:when test="${sc.status=='CONFIRMED'}">✅ Đã check-in</c:when>
                            <c:when test="${sc.status=='ABSENT'}">❌ Vắng mặt</c:when>
                            <c:when test="${sc.status=='ON_LEAVE'}">🏖️ Nghỉ phép</c:when>
                            <c:when test="${sc.status=='LEAVE_PENDING'}">⏳ Chờ duyệt nghỉ</c:when>
                            <c:when test="${sc.status=='SYSTEM_CLOSED'}">🔒 Hệ thống tự đóng</c:when>
                            <c:otherwise>⏳ Chưa vào ca</c:otherwise>
                          </c:choose>
                        </span>
                      </div>
                      <c:if test="${not empty sc.notes}">
                        <div class="tt-row"><span class="tt-icon">💬</span>
                          <span style="color:rgba(255,255,255,.6)">${fn:substring(sc.notes,0,60)}${fn:length(sc.notes)>60?'…':''}</span>
                        </div>
                      </c:if>
                      <c:if test="${sc.lateToleranceMinutes > 0}">
                        <div class="tt-row"><span class="tt-icon">⏱</span>
                          <span>Cho phép trễ <span class="tt-val">${sc.lateToleranceMinutes}p</span></span>
                        </div>
                      </c:if>
                    </div>
                  </div>
                </c:if>
              </c:forEach>
              <c:if test="${!hasShift}">
                <div class="empty-day">Trống</div>
              </c:if>
              <a onclick="openSchedModalForDay('${dayDate}','')" class="day-add">＋ Thêm ca</a>
            </div>
          </div>
        </c:forEach>
      </div>

      <%-- ────────────────────────── DANH SÁCH CA ────────────────────────── --%>
      <div style="display:flex;align-items:center;gap:12px;margin:24px 0 16px">
        <div style="flex:1;height:1px;background:var(--border)"></div>
        <span style="font-size:12px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.6px;padding:0 4px">📋 Danh sách ca làm việc</span>
        <div style="flex:1;height:1px;background:var(--border)"></div>
      </div>

      <%-- Filter inline (compact 1 row) --%>
      <form method="get" action="${pageContext.request.contextPath}/shifts">
        <input type="hidden" name="tab" value="list">
        <div class="filter-row">
          <div class="fi">
            <label>Từ ngày</label>
            <input type="date" name="from" value="${filterFrom}">
          </div>
          <div class="fi">
            <label>Đến ngày</label>
            <input type="date" name="to" value="${filterTo}">
          </div>
          <div class="fi">
            <label>Nhân viên</label>
            <select name="accountId">
              <option value="">— Tất cả —</option>
              <c:forEach var="staff" items="${allStaff}">
                <option value="${staff.accountId}" ${filterAcc == staff.accountId.toString() ? 'selected' : ''}>${staff.fullName}</option>
              </c:forEach>
            </select>
          </div>
          <div class="fi">
            <label>Trạng thái</label>
            <select name="status">
              <option value="">— Tất cả —</option>
              <option value="open"         ${'open'         == filterStatus ? 'selected' : ''}>Đang mở</option>
              <option value="closed"       ${'closed'       == filterStatus ? 'selected' : ''}>Đã đóng</option>
              <option value="force-closed" ${'force-closed' == filterStatus ? 'selected' : ''}>Đóng muộn</option>
            </select>
          </div>
          <button type="submit" class="btn-filter">🔍 Lọc</button>
          <a href="${pageContext.request.contextPath}/shifts?tab=list" class="btn-reset">↺ Reset</a>
        </div>
      </form>

      <%-- Table --%>
      <div class="table-card">
        <div class="table-card-head">
          <div>
            <h2>📋 Danh sách ca làm việc</h2>
            <span class="table-card-sub">${totalCount} ca — mới nhất trước</span>
          </div>
          <div style="position:relative;max-width:250px;flex:1">
            <span style="position:absolute;left:11px;top:50%;transform:translateY(-50%);font-size:12px;opacity:.4;pointer-events:none">🔍</span>
            <input type="text" id="shiftSearch" placeholder="Tìm nhân viên, trạng thái..."
              autocomplete="off"
              style="width:100%;height:34px;padding:0 12px 0 32px;border:1.5px solid var(--border);border-radius:8px;font-family:'Outfit',sans-serif;font-size:12.5px;outline:none;background:#fff"
              oninput="filterShiftTable(this.value)">
          </div>
        </div>
        <div class="tbl-wrap">
          <table>
            <thead>
              <tr>
                <th>#</th><th>Nhân viên</th><th>Bắt đầu</th><th>Kết thúc</th>
                <th>Thời lượng</th><th>Tiền đầu ca</th><th>Tiền cuối ca</th>
                <th>Trạng thái</th><th>Thao tác</th>
              </tr>
            </thead>
            <tbody id="shiftTbody">
              <c:if test="${empty shifts}">
                <tr><td colspan="9">
                  <div class="empty-state">
                    <span class="es-icon">🕐</span>
                    <h3>Chưa có ca nào</h3>
                    <p>Điều chỉnh bộ lọc hoặc mở ca mới</p>
                  </div>
                </td></tr>
              </c:if>
              <c:forEach var="s" items="${shifts}">
                <c:set var="staff" value="${accountMap[s.accountId]}"/>
                <c:set var="ini"   value="${not empty staff ? fn:toUpperCase(fn:substring(not empty staff.fullName ? staff.fullName : '?',0,1)) : '?'}"/>
                <tr onclick="location.href='${pageContext.request.contextPath}/shifts?action=detail&id=${s.shiftId}'">
                  <td style="font-weight:800;color:var(--muted)">#${s.shiftId}</td>
                  <td>
                    <div class="staff-cell">
                      <div class="staff-av">${ini}</div>
                      <div>
                        <div class="staff-name">${not empty staff ? staff.fullName : 'ID '.concat(s.accountId)}</div>
                        <div class="staff-role">${not empty staff ? (staff.roleId == 2 ? 'Dược sĩ' : 'Thủ kho') : ''}</div>
                      </div>
                    </div>
                  </td>
                  <td>
                    <div class="time-main"><c:if test="${not empty s.startTime}">${fn:substring(s.startTime.toString(),11,16)}</c:if></div>
                    <div class="time-date"><c:if test="${not empty s.startTime}">${fn:substring(s.startTime.toString(),0,10)}</c:if></div>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${not empty s.endTime}">
                        <div class="time-main">${fn:substring(s.endTime.toString(),11,16)}</div>
                        <div class="time-date">${fn:substring(s.endTime.toString(),0,10)}</div>
                      </c:when>
                      <c:otherwise><span class="dur-active">⏱️ Đang làm</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${s.open}"><span class="dur-active">⏱️ ${s.durationDisplay}</span></c:when>
                      <c:otherwise><span style="font-size:13px;font-weight:600">${s.durationDisplay}</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${not empty s.openingCash and s.openingCash > 0}">
                        <span class="cash-val"><fmt:formatNumber value="${s.openingCash}" type="number" maxFractionDigits="0"/>đ</span>
                      </c:when>
                      <c:otherwise><span class="cash-empty">0đ</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${not empty s.closingCash}">
                        <span class="cash-val"><fmt:formatNumber value="${s.closingCash}" type="number" maxFractionDigits="0"/>đ</span>
                      </c:when>
                      <c:otherwise><span class="cash-empty">—</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${s.open}">      <span class="badge badge-open">🟢 Đang mở</span></c:when>
                      <c:when test="${s.closed}">    <span class="badge badge-closed">✔ Đã đóng</span></c:when>
                      <c:when test="${s.forceClose}"><span class="badge badge-force">🔒 Đóng muộn</span></c:when>
                      <c:otherwise>                 <span class="badge badge-closed">• ${s.status}</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td onclick="event.stopPropagation()">
                    <div style="display:flex;gap:6px;align-items:center">
                      <a href="${pageContext.request.contextPath}/shifts?action=detail&id=${s.shiftId}" class="btn-detail">🔍 Chi tiết</a>
                      <c:if test="${s.open}">
                        <a href="${pageContext.request.contextPath}/shifts?action=force-close&id=${s.shiftId}" class="btn-close-shift">🔒 Đóng</a>
                      </c:if>
                      <c:if test="${!s.open}">
                        <a href="${pageContext.request.contextPath}/shifts?action=delete&id=${s.shiftId}"
                           class="btn-del" title="Xóa"
                           onclick="return confirm('Xóa ca #${s.shiftId}?')">🗑</a>
                      </c:if>
                    </div>
                  </td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </div>
      </div>
    </div><%-- end tab-list --%>


    <%-- ════════════════════════════════════════════════
         TAB: DOANH THU CA LÀM VIỆC
         Thuật toán: Tiền cuối ca - Tiền đầu ca = Doanh thu
         ca đó. Tổng hợp theo ngày/tháng/nhân viên.
         ════════════════════════════════════════════════ --%>
    <div id="tab-revenue" class="tab-pane <%= "revenue".equals(activeTab) ? "active" : "" %>">

      <%-- KPI strip --%>
      <div style="display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-bottom:20px">
        <div style="background:var(--white);border:1px solid var(--border);border-radius:12px;padding:16px 18px;display:flex;align-items:center;gap:12px">
          <div style="width:40px;height:40px;border-radius:11px;background:#EFF6FF;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0">📥</div>
          <div>
            <div style="font-size:10px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:3px">Tổng tiền đầu ca</div>
            <div id="kpiOpening" style="font-size:22px;font-weight:900;color:var(--ink)">—</div>
          </div>
        </div>
        <div style="background:var(--white);border:1px solid var(--border);border-radius:12px;padding:16px 18px;display:flex;align-items:center;gap:12px">
          <div style="width:40px;height:40px;border-radius:11px;background:#ECFDF5;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0">📤</div>
          <div>
            <div style="font-size:10px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:3px">Tổng tiền cuối ca</div>
            <div id="kpiClosing" style="font-size:22px;font-weight:900;color:var(--ink)">—</div>
          </div>
        </div>
        <div style="background:var(--white);border:1px solid var(--border);border-radius:12px;padding:16px 18px;display:flex;align-items:center;gap:12px">
          <div style="width:40px;height:40px;border-radius:11px;background:#FFFBEB;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0">💰</div>
          <div>
            <div style="font-size:10px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:3px">Doanh thu (chênh lệch)</div>
            <div id="kpiDiff" style="font-size:22px;font-weight:900;color:var(--ink)">—</div>
          </div>
        </div>
        <div style="background:var(--white);border:1px solid var(--border);border-radius:12px;padding:16px 18px;display:flex;align-items:center;gap:12px">
          <div style="width:40px;height:40px;border-radius:11px;background:#F5F3FF;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0">📅</div>
          <div>
            <div style="font-size:10px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:3px">Ngày có ca</div>
            <div id="kpiDays" style="font-size:22px;font-weight:900;color:var(--ink)">—</div>
          </div>
        </div>
      </div>

      <%-- Ghi chú thuật toán --%>
      <div style="background:#EFF6FF;border:1px solid #BFDBFE;border-radius:10px;padding:12px 16px;margin-bottom:16px;font-size:13px;color:#1558A8;display:flex;gap:10px;align-items:flex-start">
        <span style="font-size:16px;flex-shrink:0">💡</span>
        <div>
          <strong>Thuật toán tính doanh thu:</strong>
          Mỗi ca làm việc có 2 mốc tiền mặt: <strong>Tiền đầu ca</strong> (nhân viên mở ca nhập) và
          <strong>Tiền cuối ca</strong> (nhân viên đóng ca nhập). Doanh thu ca = Cuối − Đầu.
          Tổng doanh thu tháng = Tổng tất cả (Cuối − Đầu) của các ca đã đóng trong tháng đó.
          Biểu đồ dưới hiển thị theo từng ngày để Admin theo dõi xu hướng.
        </div>
      </div>

      <%-- Chart card --%>
      <div class="chart-card">
        <div class="chart-card-head">
          <div>
            <h3>📈 Doanh thu theo ca làm việc</h3>
            <span id="chartTrend" style="font-size:12px;color:var(--muted);margin-top:4px;display:inline-block;padding:2px 8px;border-radius:8px"></span>
          </div>
          <div style="display:flex;align-items:center;gap:8px;flex-wrap:wrap">
            <select id="chartMonthSel" onchange="loadChart()" style="border:1.5px solid var(--border);border-radius:8px;padding:5px 10px;font-family:'Outfit',sans-serif;font-size:12.5px;color:var(--ink);background:var(--surface);outline:none">
              <c:forEach begin="1" end="12" var="m">
                <option value="${m}">Tháng ${m}</option>
              </c:forEach>
            </select>
            <select id="chartYearSel" onchange="loadChart()" style="border:1.5px solid var(--border);border-radius:8px;padding:5px 10px;font-family:'Outfit',sans-serif;font-size:12.5px;color:var(--ink);background:var(--surface);outline:none">
              <option value="2025">2025</option>
              <option value="2026">2026</option>
              <option value="2027">2027</option>
            </select>
            <div style="display:flex;border:1px solid var(--border);border-radius:8px;overflow:hidden">
              <button id="btnLine" onclick="setChartType('line')" style="padding:5px 12px;border:none;font-family:'Outfit',sans-serif;font-size:12px;font-weight:600;cursor:pointer;background:#1558A8;color:#fff;transition:all .18s">Đường</button>
              <button id="btnBar"  onclick="setChartType('bar')"  style="padding:5px 12px;border:none;font-family:'Outfit',sans-serif;font-size:12px;font-weight:600;cursor:pointer;background:transparent;color:#7A90B0;transition:all .18s">Cột</button>
            </div>
          </div>
        </div>
        <div style="padding:16px 20px;height:260px"><canvas id="cashChart"></canvas></div>
        <div style="padding:10px 20px;border-top:1px solid var(--border);display:flex;gap:16px">
          <span style="font-size:12px;color:var(--muted);display:flex;align-items:center;gap:5px">
            <span style="width:10px;height:10px;border-radius:3px;background:#1558A8;display:inline-block"></span> Tiền đầu ca
          </span>
          <span style="font-size:12px;color:var(--muted);display:flex;align-items:center;gap:5px">
            <span style="width:10px;height:10px;border-radius:3px;background:#059669;display:inline-block"></span> Tiền cuối ca
          </span>
          <span style="font-size:12px;color:var(--muted);display:flex;align-items:center;gap:5px">
            <span style="width:10px;height:10px;border-radius:3px;background:#F59E0B;display:inline-block"></span> Doanh thu (chênh lệch)
          </span>
        </div>
      </div>

      <%-- Bảng chi tiết doanh thu theo ca --%>
      <div class="table-card">
        <div class="table-card-head">
          <div>
            <h2>📊 Chi tiết doanh thu từng ca</h2>
            <span class="table-card-sub">Chỉ hiển thị ca đã đóng — doanh thu = tiền cuối − tiền đầu</span>
          </div>
        </div>
        <div class="tbl-wrap">
          <table>
            <thead>
              <tr>
                <th>#</th>
                <th>Nhân viên</th>
                <th>Ngày</th>
                <th>Bắt đầu</th>
                <th>Kết thúc</th>
                <th>Tiền đầu ca</th>
                <th>Tiền cuối ca</th>
                <th>Doanh thu</th>
              </tr>
            </thead>
            <tbody>
              <c:if test="${empty monthShifts}">
                <tr><td colspan="8" style="text-align:center;padding:40px;color:var(--muted)">
                  Chưa có ca nào trong tháng này. Chọn tháng khác hoặc kiểm tra lại dữ liệu.
                </td></tr>
              </c:if>
              <c:forEach var="s" items="${monthShifts}">
                <c:if test="${not empty s.endTime}">
                  <c:set var="rev" value="${(s.closingCash != null ? s.closingCash : 0) - (s.openingCash != null ? s.openingCash : 0)}"/>
                  <tr>
                    <td style="color:var(--muted);font-size:12px">#${s.shiftId}</td>
                    <td>
                      <div style="font-weight:700">${accountMap[s.accountId] != null ? accountMap[s.accountId].fullName : 'ID '.concat(s.accountId)}</div>
                    </td>
                    <td style="font-size:12.5px;color:var(--muted)">${fn:substring(s.startTime.toString(),0,10)}</td>
                    <td style="font-weight:600">${fn:substring(s.startTime.toString(),11,16)}</td>
                    <td style="font-weight:600">${fn:substring(s.endTime.toString(),11,16)}</td>
                    <td>
                      <span style="font-weight:600">
                        <c:choose>
                          <c:when test="${s.openingCash != null}"><fmt:formatNumber value="${s.openingCash}" type="number" maxFractionDigits="0"/>đ</c:when>
                          <c:otherwise><span style="color:var(--muted)">0đ</span></c:otherwise>
                        </c:choose>
                      </span>
                    </td>
                    <td>
                      <span style="font-weight:600">
                        <c:choose>
                          <c:when test="${s.closingCash != null}"><fmt:formatNumber value="${s.closingCash}" type="number" maxFractionDigits="0"/>đ</c:when>
                          <c:otherwise><span style="color:var(--muted)">—</span></c:otherwise>
                        </c:choose>
                      </span>
                    </td>
                    <td>
                      <c:choose>
                        <c:when test="${s.closingCash != null and s.openingCash != null}">
                          <span style="font-weight:800;color:${s.closingCash >= s.openingCash ? '#059669' : '#DC2626'}">
                            ${s.closingCash >= s.openingCash ? '+' : ''}
                            <fmt:formatNumber value="${s.closingCash - s.openingCash}" type="number" maxFractionDigits="0"/>đ
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
    </div><%-- end tab-revenue --%>

    <%-- ════════════════════════════════
         TAB 3: LOẠI CA
         ════════════════════════════════ --%>
    <div id="tab-types" class="tab-pane <%= "types".equals(activeTab) ? "active" : "" %>">
      <div class="types-header">
        <div>
          <h2>⚙️ Loại ca làm việc</h2>
          <p style="font-size:12.5px;color:var(--muted);margin-top:4px">Quản lý ca mẫu — Ca sáng, Ca chiều, Ca part-time...</p>
        </div>
        <button class="btn-add-type" onclick="openTypeModal()">+ Thêm loại ca</button>
      </div>
      <div class="types-grid">
        <c:if test="${empty shiftTypes}">
          <div class="empty-state" style="grid-column:1/-1">
            <span class="es-icon">⚙️</span>
            <h3>Chưa có loại ca nào</h3>
            <p>Tạo loại ca đầu tiên để bắt đầu xếp lịch</p>
          </div>
        </c:if>
        <c:forEach var="st" items="${shiftTypes}">
          <div class="type-card">
            <div class="type-card-head">
              <div class="type-dot" style="background:var(--ca-std)"></div>
              <div>
                <div class="type-name">${st.name}</div>
                <div class="type-dur">${st.startHour}:${st.startMinute < 10 ? '0' : ''}${st.startMinute} – ${st.endHour}:${st.endMinute < 10 ? '0' : ''}${st.endMinute}</div>
              </div>
              <span class="type-badge ${st.active ? 'type-active' : 'type-inactive'}">${st.active ? '✅ Đang dùng' : '⏸ Tạm dừng'}</span>
            </div>
            <div class="type-card-body">
              <div class="type-row">
                <span class="type-lbl">🕐 Giờ làm</span>
                <span class="type-val">${st.startHour}:${st.startMinute<10?'0':''}${st.startMinute} – ${st.endHour}:${st.endMinute<10?'0':''}${st.endMinute}</span>
              </div>
              <div class="type-row">
                <span class="type-lbl">💰 Lương giờ</span>
                <span class="type-val" style="color:var(--green)"><fmt:formatNumber value="${st.hourlyRate}" type="number" maxFractionDigits="0"/>đ/h</span>
              </div>
              <c:if test="${st.allowanceAmount > 0}">
                <div class="type-row">
                  <span class="type-lbl">🎁 Phụ cấp</span>
                  <span class="type-val"><fmt:formatNumber value="${st.allowanceAmount}" type="number" maxFractionDigits="0"/>đ</span>
                </div>
              </c:if>
            </div>
            <div class="type-card-foot">
              <button class="btn-edit-type" onclick="editType(${st.shiftTypeId},'${st.name}',${st.startHour},${st.startMinute},${st.endHour},${st.endMinute},${st.hourlyRate},${st.allowanceAmount})">✏️ Sửa</button>
              <button class="btn-toggle-type" onclick="toggleType(${st.shiftTypeId},${st.active})">${st.active ? '⏸ Tạm dừng' : '▶️ Kích hoạt'}</button>
              <c:if test="${!st.active}">
                <button class="btn-del-type" onclick="deleteType(${st.shiftTypeId},'${st.name}')">🗑</button>
              </c:if>
            </div>
          </div>
        </c:forEach>
      </div>
    </div><%-- end tab-types --%>

    <%-- ════════════════════════════════
         TAB 4: NGHỈ PHÉP
         ════════════════════════════════ --%>
    <div id="tab-leave" class="tab-pane <%= "leave".equals(activeTab) ? "active" : "" %>">
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:16px;flex-wrap:wrap;gap:10px">
        <div>
          <h2 style="font-size:16px;font-weight:800;color:var(--ink)">🏖️ Đơn xin nghỉ phép</h2>
          <p style="font-size:12.5px;color:var(--muted);margin-top:3px">Duyệt hoặc từ chối đơn xin nghỉ của nhân viên</p>
        </div>
        <a href="${pageContext.request.contextPath}/leave-requests?action=list"
           style="font-size:13px;font-weight:600;color:var(--blue);text-decoration:none;
                  padding:7px 14px;border:1.5px solid var(--blue);border-radius:9px;
                  transition:all .18s"
           onmouseover="this.style.background='#EFF6FF'" onmouseout="this.style.background=''">
          📋 Xem tất cả đơn →
        </a>
      </div>

      <div class="table-card">
        <div class="table-card-head">
          <h2>⏳ Đơn chờ duyệt</h2>
          <span class="table-card-sub">${pendingLeaveCount} đơn đang chờ</span>
        </div>
        <c:choose>
          <c:when test="${empty pendingLeaves}">
            <div style="text-align:center;padding:48px 24px;color:var(--muted)">
              <div style="font-size:44px;margin-bottom:12px">✅</div>
              <div style="font-size:14px;font-weight:600;color:var(--ink);margin-bottom:4px">Không có đơn nào chờ duyệt</div>
              <div style="font-size:13px">Tất cả đơn đã được xử lý!</div>
            </div>
          </c:when>
          <c:otherwise>
            <table>
              <thead>
                <tr>
                  <th>Nhân viên</th>
                  <th>Ngày nghỉ</th>
                  <th>Loại</th>
                  <th>Lý do</th>
                  <th>Gửi lúc</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="lr" items="${pendingLeaves}">
                  <tr>
                    <td><strong>${lr.staffName}</strong></td>
                    <td style="font-weight:700;color:var(--ink)">${lr.leaveDate}</td>
                    <td>
                      <span style="padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:700;
                        background:<c:choose>
                          <c:when test="${lr.leaveType=='ANNUAL'}">#ECFDF5;color:#065F46</c:when>
                          <c:when test="${lr.leaveType=='SICK'}">#FFF7ED;color:#92400E</c:when>
                          <c:when test="${lr.leaveType=='UNPAID'}">#F5F3FF;color:#5B21B6</c:when>
                          <c:otherwise>#EFF6FF;color:#1E40AF</c:otherwise>
                        </c:choose>">
                        <c:choose>
                          <c:when test="${lr.leaveType=='ANNUAL'}">🌴 Phép năm</c:when>
                          <c:when test="${lr.leaveType=='SICK'}">🤒 Nghỉ ốm</c:when>
                          <c:when test="${lr.leaveType=='UNPAID'}">💸 Không lương</c:when>
                          <c:otherwise>⚡ Đột xuất</c:otherwise>
                        </c:choose>
                      </span>
                    </td>
                    <td style="max-width:180px;font-size:12.5px;color:var(--muted)">${lr.reason}</td>
                    <td style="font-size:12px;color:var(--muted);white-space:nowrap">
                      ${fn:substring(lr.requestedAt.toString(),0,16)}
                    </td>
                    <td>
                      <div style="display:flex;gap:6px;align-items:center">
                        <form method="post" action="${pageContext.request.contextPath}/leave-requests">
                          <input type="hidden" name="action"       value="approve">
                          <input type="hidden" name="id"           value="${lr.leaveId}">
                          <input type="hidden" name="deductAmount" value="0">
                          <button type="submit"
                                  style="padding:5px 12px;background:#ECFDF5;color:#065F46;border:1px solid #A7F3D0;
                                         border-radius:7px;font-size:12px;font-weight:700;cursor:pointer;
                                         transition:all .18s"
                                  onmouseover="this.style.background='#A7F3D0'"
                                  onmouseout="this.style.background='#ECFDF5'">
                            ✅ Duyệt
                          </button>
                        </form>
                        <form method="post" action="${pageContext.request.contextPath}/leave-requests">
                          <input type="hidden" name="action" value="reject">
                          <input type="hidden" name="id"     value="${lr.leaveId}">
                          <button type="submit"
                                  onclick="return confirm('Từ chối đơn nghỉ của ${lr.staffName}?')"
                                  style="padding:5px 12px;background:#FEF2F2;color:#991B1B;border:1px solid #FECACA;
                                         border-radius:7px;font-size:12px;font-weight:700;cursor:pointer;
                                         transition:all .18s"
                                  onmouseover="this.style.background='#FECACA'"
                                  onmouseout="this.style.background='#FEF2F2'">
                            ✕ Từ chối
                          </button>
                        </form>
                      </div>
                    </td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </c:otherwise>
        </c:choose>
      </div>
    </div><%-- end tab-leave --%>

  </div><%-- end content --%>
</div><%-- end main --%>

<%-- ══════════════════════════════════════════════════════
     MODAL 1: Xếp ca mới (Quick Schedule — KHÔNG redirect)
     ══════════════════════════════════════════════════════ --%>
<div class="modal-overlay" id="schedModal">
  <div class="modal">
    <div class="modal-head">
      <span class="modal-title">📅 Xếp lịch ca mới</span>
      <button class="modal-close" onclick="closeSchedModal()">✕</button>
    </div>
    <div class="modal-body">
      <form id="schedForm" method="post" action="${pageContext.request.contextPath}/shifts">
        <input type="hidden" name="action" value="schedule-bulk">

        <%-- Nhân viên --%>
        <div class="mfg">
          <label>Nhân viên <span style="color:var(--red)">*</span></label>
          <div class="staff-chips-grid" id="staffChipsGrid">
            <c:forEach var="staff" items="${allStaff}">
              <c:set var="sn" value="${not empty staff.fullName ? staff.fullName : staff.username}"/>
              <c:set var="si" value="${fn:toUpperCase(fn:substring(sn,0,1))}${fn:toUpperCase(fn:substring(sn,1,2))}"/>
              <label class="sch-chip">
                <input type="checkbox" name="accountIds" value="${staff.accountId}">
                <div class="sch-chip-av">${si}</div>
                <div class="sch-chip-name">${sn}</div>
                <div class="sch-chip-role">#${staff.accountId} • ${staff.roleId==2?'Dược sĩ':'Thủ kho'}</div>
              </label>
            </c:forEach>
          </div>
          <div class="field-hint">Có thể chọn nhiều nhân viên — mỗi người sẽ được tạo 1 lịch ca riêng</div>
        </div>

        <%-- Loại ca --%>
        <div class="mfg">
          <label>Loại ca <span style="color:var(--red)">*</span></label>
          <div class="stype-grid">
            <c:forEach var="st" items="${shiftTypes}">
              <c:if test="${st.active}">
                <label class="stype-card" onclick="updateSchedPreview()">
                  <input type="radio" name="shiftTypeId" value="${st.shiftTypeId}" required>
                  <div style="font-size:20px">
                    <c:choose>
                      <c:when test="${st.startHour < 12}">☀️</c:when>
                      <c:when test="${st.startHour < 18}">⛅</c:when>
                      <c:otherwise>🌙</c:otherwise>
                    </c:choose>
                  </div>
                  <div class="stype-name">${st.name}</div>
                  <div class="stype-time">${st.startHour}:${st.startMinute<10?'0':''}${st.startMinute} – ${st.endHour}:${st.endMinute<10?'0':''}${st.endMinute}</div>
                  <div class="stype-rate"><fmt:formatNumber value="${st.hourlyRate}" type="number" maxFractionDigits="0"/>đ/giờ</div>
                </label>
              </c:if>
            </c:forEach>
          </div>
        </div>

        <%-- Khoảng ngày --%>
        <div class="mfg-row">
          <div class="mfg">
            <label>Từ ngày <span style="color:var(--red)">*</span></label>
            <input type="date" name="fromDate" id="schedFrom" required onchange="updateSchedPreview()">
          </div>
          <div class="mfg">
            <label>Đến ngày</label>
            <input type="date" name="toDate" id="schedTo" onchange="updateSchedPreview()">
            <span class="field-hint">Bỏ trống = chỉ 1 ngày</span>
          </div>
        </div>

        <div class="dur-preview" id="schedPreview" style="display:none"></div>

        <div class="mfg">
          <label>Ghi chú</label>
          <textarea name="note" rows="2" placeholder="Ghi chú tùy chọn..."></textarea>
        </div>
      </form>
    </div>
    <div class="modal-foot">
      <button class="btn-cancel-m" onclick="closeSchedModal()">Hủy</button>
      <button class="btn-save-m" onclick="submitSchedForm()">📅 Xếp lịch ca</button>
    </div>
  </div>
</div>

<%-- ══════════════════════════════════════
     MODAL 2: Thêm/Sửa loại ca
     ══════════════════════════════════════ --%>
<div class="modal-overlay" id="typeModal">
  <div class="modal">
    <div class="modal-head">
      <span class="modal-title" id="modalTitle">Thêm loại ca mới</span>
      <button class="modal-close" onclick="closeTypeModal()">✕</button>
    </div>
    <div class="modal-body">
      <form id="typeForm" method="post" action="${pageContext.request.contextPath}/shift-types">
        <input type="hidden" name="action" id="typeAction" value="create">
        <input type="hidden" name="shiftTypeId" id="editTypeId" value="">
        <div class="mfg">
          <label>Tên loại ca *</label>
          <input type="text" name="name" id="typeName" placeholder="VD: Ca sáng Long Châu" required>
        </div>
        <div class="mfg-row">
          <div class="mfg">
            <label>Giờ bắt đầu *</label>
            <input type="time" name="startTime" id="typeStartTime" required value="06:00">
          </div>
          <div class="mfg">
            <label>Giờ kết thúc *</label>
            <input type="time" name="endTime" id="typeEndTime" required value="14:00">
          </div>
        </div>
        <div id="durPreview" class="dur-preview"></div>
        <div class="mfg">
          <label>Lương theo giờ (VNĐ) *</label>
          <input type="number" name="hourlyRate" id="typeRate" min="50000" step="1000"
                 placeholder="Tối thiểu 50,000đ" required value="60000"
                 oninput="validateRate(this)">
          <span class="field-err" id="rateErr">⚠️ Tối thiểu 50,000đ/giờ</span>
          <span class="field-hint">Tổng lương ca sẽ tự tính</span>
        </div>
        <div class="mfg">
          <label>Phụ cấp ca (VNĐ)</label>
          <input type="number" name="allowanceAmount" id="typeAllowance" min="0" step="1000" value="0" placeholder="0">
          <span class="field-hint">Thêm vào ngoài lương giờ (không bắt buộc)</span>
        </div>
      </form>
    </div>
    <div class="modal-foot">
      <button class="btn-cancel-m" onclick="closeTypeModal()">Hủy</button>
      <button class="btn-save-m" onclick="submitTypeForm()">💾 Lưu loại ca</button>
    </div>
  </div>
</div>

<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
<%-- ════════════════════════════════════════════════════════
     MODAL XẾP CA ĐẦY ĐỦ — nhiều NV + nhiều ca + khoảng ngày
     POST /shifts?action=schedule-bulk
     ════════════════════════════════════════════════════════ --%>
<div class="sched-overlay" id="fullSchedModal">
  <div class="sched-modal">
    <div class="sched-modal-head">
      <span class="sched-modal-title">📅 Xếp lịch ca làm việc</span>
      <button class="sched-modal-close" onclick="closeFullSchedModal()">✕</button>
    </div>
    <div class="sched-modal-body">
      <form id="fullSchedForm" method="post" action="${pageContext.request.contextPath}/shifts">
        <input type="hidden" name="action" value="schedule-bulk">

        <%-- Nhân viên --%>
        <div class="sched-section">
          <div class="sched-section-title">👤 Nhân viên <span style="color:var(--red)">*</span></div>
          <div class="staff-search-wrap">
            <span class="staff-search-icon">🔍</span>
            <input type="text" class="staff-search-input" id="staffSearchInput"
                   placeholder="Tìm theo tên, tài khoản, email, SĐT..."
                   oninput="filterStaffChips(this.value)"
                   autocomplete="off">
          </div>
          <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:6px">
            <button type="button" class="sc-all-btn" onclick="toggleAllStaff()">☑️ Chọn tất cả</button>
            <span id="staffSearchCount" style="font-size:11px;color:var(--muted)"></span>
          </div>
          <div class="staff-chips-wrap" id="fullStaffChips">
            <c:forEach var="s" items="${allStaff}">
              <c:set var="sn2" value="${not empty s.fullName ? s.fullName : s.username}"/>
              <c:set var="si2" value="${fn:toUpperCase(fn:substring(sn2,0,1))}${fn:toUpperCase(fn:substring(sn2,1,2))}"/>
              <label class="sc-chip" onclick="updateFullPreview()" data-search="${fn:toLowerCase(sn2)} ${fn:toLowerCase(s.username)} ${fn:toLowerCase(s.email != null ? s.email : '')} ${s.phone != null ? s.phone : ''}">
                <input type="checkbox" name="accountId" value="${s.accountId}">
                <div class="user-av" style="width:22px;height:22px;font-size:9px;border-radius:6px;background:linear-gradient(135deg,#1558A8,#4F81D9);color:#fff;display:inline-flex;align-items:center;justify-content:center;font-weight:800;flex-shrink:0">${si2}</div>
                <span class="sc-chip-name">${sn2}</span>
                <span class="sc-chip-role">${s.roleId==2?'DS':'TK'}</span>
              </label>
            </c:forEach>
          </div>
        </div>

        <%-- Loại ca — checkbox multi-select --%>
        <div class="sched-section">
          <div class="sched-section-title">🕐 Loại ca <span style="color:var(--red)">*</span> <span style="color:var(--muted);font-weight:400;font-size:10px">Có thể chọn nhiều</span></div>
          <div class="stype-cards-wrap" id="fullStypeCards">
            <c:forEach var="st" items="${shiftTypes}">
              <c:if test="${st.active}">
                <label class="stc" onclick="updateFullPreview()">
                  <input type="checkbox" name="shiftTypeId" value="${st.shiftTypeId}">
                  <div class="stc-icon">
                    <c:choose>
                      <c:when test="${st.startHour < 12}">☀️</c:when>
                      <c:when test="${st.startHour < 18}">☀️</c:when>
                      <c:otherwise>🌙</c:otherwise>
                    </c:choose>
                  </div>
                  <div class="stc-name">${st.name}</div>
                  <div class="stc-time">${st.startHour}:${st.startMinute < 10 ? '0' : ''}${st.startMinute} – ${st.endHour}:${st.endMinute < 10 ? '0' : ''}${st.endMinute}</div>
                  <div class="stc-rate"><fmt:formatNumber value="${st.hourlyRate}" type="number" maxFractionDigits="0"/>đ/giờ</div>
                </label>
              </c:if>
            </c:forEach>
          </div>
        </div>

        <%-- Khoảng ngày --%>
        <div class="sched-section">
          <div class="sched-section-title">📆 Khoảng ngày <span style="color:var(--red)">*</span></div>
          <div class="date-row">
            <div class="sched-fi">
              <label>Từ ngày</label>
              <input type="date" name="dateFrom" id="fsDateFrom" required onchange="updateFullPreview()">
            </div>
            <div class="date-sep">→</div>
            <div class="sched-fi">
              <label>Đến ngày</label>
              <input type="date" name="dateTo" id="fsDateTo" onchange="updateFullPreview()">
              <span style="font-size:11px;color:var(--muted);margin-top:2px">Để trống = chỉ 1 ngày</span>
            </div>
          </div>
        </div>

        <%-- Ghi chú --%>
        <div class="sched-section">
          <div class="sched-section-title">📝 Ghi chú <span style="color:var(--muted);font-weight:400">(tùy chọn)</span></div>
          <div class="sched-fi">
            <textarea name="note" rows="2" placeholder="Ghi chú cho lịch ca này..."></textarea>
          </div>
        </div>

        <%-- Preview tự động --%>
        <div class="sched-preview" id="fullSchedPreview">
          <div>📅 <span id="fpDays" class="sched-preview-count">—</span> ngày
             × <span id="fpStaff" class="sched-preview-count">—</span> nhân viên
             × <span id="fpTypes" class="sched-preview-count">—</span> loại ca
             = <strong><span id="fpTotal" class="sched-preview-count">—</span> lịch ca</strong>
          </div>
          <div style="font-size:11px;color:var(--muted);margin-top:4px">
            💡 Lịch ca đã tồn tại sẽ tự động bỏ qua
          </div>
        </div>

      </form>
    </div>
    <div class="sched-modal-foot">
      <button type="button" class="btn-sched-cancel" onclick="closeFullSchedModal()">Hủy</button>
      <button type="button" class="btn-sched-submit" onclick="submitFullSched()">📅 Xếp lịch ca</button>
    </div>
  </div>
</div>


<%-- ════════════════════════════════════════════════════
     MODAL EDIT LỊCH CA (cho ca chưa vào — SCHEDULED)
     POST /shifts?action=schedule-update
     ════════════════════════════════════════════════════ --%>
<div class="edit-modal-overlay" id="editSchedModal">
  <div class="edit-modal">
    <div class="em-head">
      <span class="em-title" id="editModalTitle">✏️ Sửa lịch ca</span>
      <button class="em-close" onclick="closeEditModal()">✕</button>
    </div>
    <div class="em-body">
      <form id="editSchedForm" method="post" action="${pageContext.request.contextPath}/shifts">
        <input type="hidden" name="action" value="schedule-update">
        <input type="hidden" name="scheduleId" id="editSchedId">

        <%-- Loại ca --%>
        <div class="em-fg" style="margin-bottom:12px">
          <label>Loại ca <span style="color:var(--red)">*</span></label>
          <select name="shiftTypeId" id="editShiftType" required>
            <option value="">-- Chọn --</option>
            <c:forEach var="st" items="${shiftTypes}">
              <c:if test="${st.active}">
                <option value="${st.shiftTypeId}"
                  data-label="${st.name} (${st.startHour}:${st.startMinute < 10 ? '0' : ''}${st.startMinute}–${st.endHour}:${st.endMinute < 10 ? '0' : ''}${st.endMinute})">
                  ${st.name} — ${st.startHour}:${st.startMinute < 10 ? '0' : ''}${st.startMinute}→${st.endHour}:${st.endMinute < 10 ? '0' : ''}${st.endMinute}
                  (<fmt:formatNumber value="${st.hourlyRate}" type="number" maxFractionDigits="0"/>đ/giờ)
                </option>
              </c:if>
            </c:forEach>
          </select>
        </div>

        <%-- Dung sai trễ --%>
        <div class="em-row">
          <div class="em-fg">
            <label>Cho phép trễ (phút)</label>
            <input type="number" name="lateToleranceMinutes" id="editLateTol"
                   min="0" max="120" step="5" value="10">
            <span style="font-size:10.5px;color:var(--muted);margin-top:2px">Mặc định 10 phút</span>
          </div>
          <div class="em-fg">
            <label>Ngày làm việc</label>
            <input type="text" id="editWorkDate" readonly
                   style="background:#F8FAFC;color:var(--muted);cursor:default">
          </div>
        </div>

        <%-- Ghi chú --%>
        <div class="em-fg full" style="margin-bottom:0">
          <label>Ghi chú</label>
          <textarea name="notes" id="editNotes" rows="2"
                    placeholder="Ghi chú cho ca này..."></textarea>
        </div>
      </form>
    </div>
    <div class="em-foot">
      <button class="em-cancel" onclick="closeEditModal()">Hủy</button>
      <button class="em-submit" onclick="submitEditSched()">💾 Lưu thay đổi</button>
    </div>
  </div>
</div>

<%-- ════════════════════════════════════════════════════
     MODAL XÓA LỊCH CA THEO NHÂN VIÊN
     POST /shifts?action=schedule-delete-staff
     ════════════════════════════════════════════════════ --%>
<div class="del-modal-overlay" id="deleteStaffModal">
  <div class="del-modal">
    <div class="dm-head">
      <span class="dm-title">🗑️ Xóa lịch ca của nhân viên</span>
      <button class="dm-close" onclick="closeDeleteModal()">✕</button>
    </div>
    <div class="dm-body">
      <%-- Info nhân viên --%>
      <div class="dm-staff-row">
        <div class="dm-staff-av" id="delStaffAv">NV</div>
        <div>
          <div style="font-size:13px;font-weight:700;color:var(--ink)" id="delStaffName">—</div>
          <div style="font-size:11.5px;color:var(--muted)">Chỉ xóa lịch ca chưa check-in (SCHEDULED)</div>
        </div>
      </div>

      <%-- Chú ý --%>
      <div style="background:#FEF2F2;border:1px solid #FECACA;border-radius:9px;padding:10px 14px;font-size:12.5px;color:#991B1B;margin-bottom:14px;display:flex;gap:8px">
        <span>⚠️</span>
        <span>Ca đang làm hoặc đã điểm danh <strong>không thể xóa</strong>. Hệ thống sẽ tự bỏ qua các ca đó.</span>
      </div>

      <%-- Khoảng ngày --%>
      <div class="dm-date-row">
        <div class="dm-fg">
          <label>Từ ngày <span style="color:var(--red)">*</span></label>
          <input type="date" id="delFromDate" oninput="loadDelPreview()">
        </div>
        <div class="dm-sep">→</div>
        <div class="dm-fg">
          <label>Đến ngày</label>
          <input type="date" id="delToDate" oninput="loadDelPreview()">
          <span style="font-size:10.5px;color:var(--muted);margin-top:2px">Để trống = chỉ 1 ngày</span>
        </div>
      </div>

      <%-- Preview: hiện danh sách ca sẽ bị xóa --%>
      <div id="delPreviewBox" style="display:none">
        <div style="font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:6px">
          Các lịch ca sẽ bị xóa (<span id="delCount">0</span>)
        </div>
        <div class="dm-list" id="delItemsList"></div>
      </div>
      <div id="delEmptyBox" style="display:none;text-align:center;padding:20px;color:var(--muted);font-size:13px">
        Không tìm thấy lịch ca nào có thể xóa trong khoảng ngày này.
      </div>
      <div id="delLoadingBox" style="display:none;text-align:center;padding:14px;color:var(--muted);font-size:13px">
        ⏳ Đang tải...
      </div>
    </div>
    <div class="dm-foot">
      <span class="dm-count" id="delTotalCount"></span>
      <div style="display:flex;gap:8px">
        <button class="dm-cancel" onclick="closeDeleteModal()">Hủy</button>
        <button class="dm-confirm" id="delConfirmBtn" onclick="submitDeleteStaff()" disabled
                style="opacity:.5;cursor:not-allowed">🗑️ Xác nhận xóa</button>
      </div>
    </div>
  </div>
</div>



<%-- ════════════════════════════════════════════════════════
     MODAL CHỌN CA ĐỂ SỬA
     ════════════════════════════════════════════════════════ --%>
<div class="selmode-overlay" id="editSelectModal">
  <div class="selmode-modal">
    <div class="sm-head">
      <span class="sm-title">✏️ Chọn ca muốn sửa</span>
      <span class="sm-selected-badge" id="editSelBadge">0 ca đã chọn</span>
      <div style="display:flex;gap:8px;margin-left:auto">
        <button class="sm-cancel-btn" onclick="closeEditSelectModal()">Hủy</button>
        <button id="editSelActionBtn" class="sm-action-btn sm-action-edit"
                onclick="applyEditSel()">✏️ Sửa ca đã chọn</button>
      </div>
      <button class="sm-close" onclick="closeEditSelectModal()">✕</button>
    </div>
    <div class="sm-instructions">
      💡 <span>Click vào chip ca để <strong>chọn/bỏ chọn</strong>. Chỉ chọn được ca chưa check-in (SCHEDULED). Ca đang làm / đã điểm danh bị khóa.</span>
    </div>
    <div class="sm-body">
      <%-- Week nav mini --%>
      <div style="display:flex;align-items:center;gap:8px;margin-bottom:12px">
        <a href="${pageContext.request.contextPath}/shifts?tab=list&w=${param.w != null ? param.w - 1 : -1}" class="btn-nav" style="font-size:12px;padding:4px 10px">‹</a>
        <span style="font-size:13px;font-weight:700;color:var(--ink)">📅 ${weekStart} → ${weekEnd}</span>
        <a href="${pageContext.request.contextPath}/shifts?tab=list&w=${param.w != null ? param.w + 1 : 1}" class="btn-nav" style="font-size:12px;padding:4px 10px">›</a>
      </div>
      <%-- Grid chọn ca --%>
      <div class="sm-week-grid" id="editWeekGrid">
        <c:forEach begin="0" end="6" var="i">
          <c:set var="dayDate" value="${weekDays[i]}"/>
          <c:set var="isToday" value="${dayDate.equals(today)}"/>
          <div class="sm-day-col ${isToday ? 'sm-today' : ''}">
            <div class="sm-day-head">
              <div class="sm-day-name">${weekDayNames[i]}</div>
              <div class="sm-day-date">${dayDate.dayOfMonth}</div>
              <div style="font-size:8px;color:var(--muted)">${dayDate.monthValue}/${dayDate.year}</div>
            </div>
            <div class="sm-day-body">
              <c:set var="hasSched" value="false"/>
              <c:forEach var="sc" items="${schedules}">
                <c:if test="${sc.workDate.equals(dayDate)}">
                  <c:set var="hasSched" value="true"/>
                  <c:set var="isEditable" value="${sc.status == 'SCHEDULED' or sc.status == 'LEAVE_PENDING'}"/>
                  <c:set var="smChipClass">sm-chip <c:choose>
                    <c:when test="${sc.startHour < 12}">sm-morning</c:when>
                    <c:when test="${sc.startHour < 20}">sm-afternoon</c:when>
                    <c:otherwise>sm-night</c:otherwise>
                  </c:choose> ${!isEditable ? 'sm-locked' : ''}</c:set>
                  <div class="${smChipClass}"
                       id="edit-chip-${sc.scheduleId}"
                       data-sched-id="${sc.scheduleId}"
                       data-shift-type-id="${sc.shiftTypeId}"
                       data-shift-type-name="${sc.shiftTypeName}"
                       data-late-tol="${sc.lateToleranceMinutes}"
                       data-notes="${sc.notes}"
                       data-staff="${sc.staffName}"
                       data-date="${sc.workDate}"
                       data-editable="${isEditable}"
                       onclick="toggleEditChip(this)">
                    <div class="sm-chip-name">${sc.staffName}</div>
                    <div class="sm-chip-type">${sc.shiftTypeName}</div>
                    <div class="sm-chip-status" style="background:<c:choose>
                      <c:when test="${sc.status=='CONFIRMED'}">#D1FAE5;color:#065F46</c:when>
                      <c:when test="${sc.status=='ABSENT'}">#FEE2E2;color:#991B1B</c:when>
                      <c:when test="${sc.status=='SCHEDULED'}">#DBEAFE;color:#1E40AF</c:when>
                      <c:otherwise>#F1F5F9;color:#64748B</c:otherwise>
                    </c:choose>">
                      <c:choose>
                        <c:when test="${sc.status=='CONFIRMED'}">✅ Đang làm</c:when>
                        <c:when test="${sc.status=='ABSENT'}">❌ Vắng</c:when>
                        <c:when test="${sc.status=='SCHEDULED'}">⏳ Chưa vào</c:when>
                        <c:otherwise>${sc.status}</c:otherwise>
                      </c:choose>
                    </div>
                    <c:if test="${!isEditable}">
                      <span class="sm-lock-badge">🔒 Không thể sửa</span>
                    </c:if>
                  </div>
                </c:if>
              </c:forEach>
              <c:if test="${!hasSched}"><div class="sm-empty">Trống</div></c:if>
            </div>
          </div>
        </c:forEach>
      </div>

      <%-- Panel chỉnh sửa — hiện khi đã chọn ít nhất 1 ca --%>
      <div class="sm-edit-panel" id="editPanel">
        <h4>⚙️ Thông tin chỉnh sửa (áp dụng cho tất cả ca đã chọn)</h4>
        <div class="sm-edit-grid">
          <div class="sm-efg">
            <label>Loại ca <span style="color:var(--red)">*</span></label>
            <select id="smEditShiftType">
              <option value="">-- Giữ nguyên --</option>
              <c:forEach var="st" items="${shiftTypes}">
                <c:if test="${st.active}">
                  <option value="${st.shiftTypeId}">
                    ${st.name} (${st.startHour}:${st.startMinute<10?'0':''}${st.startMinute}→${st.endHour}:${st.endMinute<10?'0':''}${st.endMinute})
                    — <fmt:formatNumber value="${st.hourlyRate}" type="number" maxFractionDigits="0"/>đ/h
                  </option>
                </c:if>
              </c:forEach>
            </select>
          </div>
          <div class="sm-efg">
            <label>Cho phép trễ (phút)</label>
            <input type="number" id="smEditLateTol" min="0" max="120" step="5"
                   placeholder="Giữ nguyên" value="">
            <span style="font-size:10px;color:var(--muted);margin-top:2px">Để trống = giữ nguyên</span>
          </div>
          <div class="sm-efg">
            <label>Xem trước</label>
            <div id="smEditPreview" style="font-size:12px;color:var(--muted);padding:8px;background:#F8FAFC;border-radius:7px;min-height:36px">
              Chọn ca để xem trước
            </div>
          </div>
          <div class="sm-efg span3">
            <label>Ghi chú</label>
            <input type="text" id="smEditNotes" placeholder="Ghi chú (để trống = giữ nguyên)">
          </div>
        </div>
      </div>
    </div>
    <div class="sm-foot">
      <span class="sm-foot-hint" id="editSelHint">Click vào chip ca để chọn</span>
      <button class="sm-cancel-btn" onclick="closeEditSelectModal()">Hủy</button>
      <button id="editSelFootBtn" class="sm-action-btn sm-action-edit"
              onclick="applyEditSel()">✏️ Lưu thay đổi</button>
    </div>
  </div>
</div>

<%-- ════════════════════════════════════════════════════════
     MODAL CHỌN CA ĐỂ XÓA
     ════════════════════════════════════════════════════════ --%>
<div class="selmode-overlay" id="deleteSelectModal">
  <div class="selmode-modal">
    <div class="sm-head">
      <span class="sm-title">🗑️ Chọn ca muốn xóa</span>
      <span class="sm-selected-badge del-badge" id="deleteSelBadge">0 ca đã chọn</span>
      <div style="display:flex;gap:8px;margin-left:auto">
        <button class="sm-cancel-btn" onclick="closeDeleteSelectModal()">Hủy</button>
        <button id="deleteSelActionBtn" class="sm-action-btn sm-action-del"
                onclick="applyDeleteSel()">🗑️ Xóa ca đã chọn</button>
      </div>
      <button class="sm-close" onclick="closeDeleteSelectModal()">✕</button>
    </div>
    <div class="sm-instructions" style="background:#FEF9F9">
      ⚠️ <span>Click để chọn ca cần xóa. Chỉ xóa được ca <strong>chưa check-in</strong>. Ca đang làm / đã điểm danh không thể xóa.</span>
    </div>
    <div class="sm-body">
      <div style="display:flex;align-items:center;gap:8px;margin-bottom:12px">
        <a href="${pageContext.request.contextPath}/shifts?tab=list&w=${param.w != null ? param.w - 1 : -1}" class="btn-nav" style="font-size:12px;padding:4px 10px">‹</a>
        <span style="font-size:13px;font-weight:700;color:var(--ink)">📅 ${weekStart} → ${weekEnd}</span>
        <a href="${pageContext.request.contextPath}/shifts?tab=list&w=${param.w != null ? param.w + 1 : 1}" class="btn-nav" style="font-size:12px;padding:4px 10px">›</a>
      </div>
      <div class="sm-week-grid" id="deleteWeekGrid">
        <c:forEach begin="0" end="6" var="i">
          <c:set var="dayDate" value="${weekDays[i]}"/>
          <c:set var="isToday" value="${dayDate.equals(today)}"/>
          <div class="sm-day-col ${isToday ? 'sm-today' : ''}">
            <div class="sm-day-head">
              <div class="sm-day-name">${weekDayNames[i]}</div>
              <div class="sm-day-date">${dayDate.dayOfMonth}</div>
              <div style="font-size:8px;color:var(--muted)">${dayDate.monthValue}/${dayDate.year}</div>
            </div>
            <div class="sm-day-body">
              <c:set var="hasSched2" value="false"/>
              <c:forEach var="sc" items="${schedules}">
                <c:if test="${sc.workDate.equals(dayDate)}">
                  <c:set var="hasSched2" value="true"/>
                  <c:set var="isDeletable" value="${sc.status == 'SCHEDULED' or sc.status == 'LEAVE_PENDING' or sc.status == 'CANCELLED'}"/>
                  <c:set var="smChipClass2">sm-chip <c:choose>
                    <c:when test="${sc.startHour < 12}">sm-morning</c:when>
                    <c:when test="${sc.startHour < 20}">sm-afternoon</c:when>
                    <c:otherwise>sm-night</c:otherwise>
                  </c:choose> ${!isDeletable ? 'sm-locked' : ''}</c:set>
                  <div class="${smChipClass2}"
                       id="del-chip-${sc.scheduleId}"
                       data-sched-id="${sc.scheduleId}"
                       data-deletable="${isDeletable}"
                       onclick="toggleDelChip(this)">
                    <div class="sm-chip-name">${sc.staffName}</div>
                    <div class="sm-chip-type">${sc.shiftTypeName}</div>
                    <div class="sm-chip-status" style="background:<c:choose>
                      <c:when test="${sc.status=='CONFIRMED'}">#D1FAE5;color:#065F46</c:when>
                      <c:when test="${sc.status=='ABSENT'}">#FEE2E2;color:#991B1B</c:when>
                      <c:when test="${sc.status=='SCHEDULED'}">#DBEAFE;color:#1E40AF</c:when>
                      <c:otherwise>#F1F5F9;color:#64748B</c:otherwise>
                    </c:choose>">
                      <c:choose>
                        <c:when test="${sc.status=='CONFIRMED'}">✅ Đang làm</c:when>
                        <c:when test="${sc.status=='ABSENT'}">❌ Vắng</c:when>
                        <c:when test="${sc.status=='SCHEDULED'}">⏳ Chưa vào</c:when>
                        <c:otherwise>${sc.status}</c:otherwise>
                      </c:choose>
                    </div>
                    <c:if test="${!isDeletable}">
                      <span class="sm-lock-badge">🔒 Không thể xóa</span>
                    </c:if>
                  </div>
                </c:if>
              </c:forEach>
              <c:if test="${!hasSched2}"><div class="sm-empty">Trống</div></c:if>
            </div>
          </div>
        </c:forEach>
      </div>
      <%-- Danh sách ca đã chọn để xóa --%>
      <div id="delSelSummary" style="display:none;margin-top:14px;background:#FEF2F2;
           border:1px solid #FECACA;border-radius:10px;padding:12px 16px">
        <div style="font-size:12px;font-weight:700;color:#991B1B;margin-bottom:8px">
          🗑️ Ca sẽ bị xóa (<span id="delSelCount">0</span>):
        </div>
        <div id="delSelList" style="display:flex;flex-wrap:wrap;gap:6px"></div>
      </div>
    </div>
    <div class="sm-foot">
      <span class="sm-foot-hint" id="deleteSelHint">Click vào chip ca để chọn</span>
      <button class="sm-cancel-btn" onclick="closeDeleteSelectModal()">Hủy</button>
      <button id="deleteSelFootBtn" class="sm-action-btn sm-action-del"
              onclick="applyDeleteSel()">🗑️ Xóa ca đã chọn</button>
    </div>
  </div>
</div>

<%-- Schedules JSON cho JS delete preview --%>
<script id="schedDataScript">
const SCHED_LIST = [
  <c:forEach var="sc" items="${schedules}" varStatus="st">
  {
    id: ${sc.scheduleId},
    accountId: ${sc.accountId},
    staffName: "${sc.staffName}",
    shiftTypeName: "${sc.shiftTypeName}",
    workDate: "${sc.workDate}",
    status: "${sc.status}",
    plannedStart: "${not empty sc.plannedStart ? fn:substring(sc.plannedStart.toString(),11,16) : ''}",
    plannedEnd: "${not empty sc.plannedEnd ? fn:substring(sc.plannedEnd.toString(),11,16) : ''}"
  }${!st.last ? ',' : ''}
  </c:forEach>
];
</script>

<script>
const ctx_path = '${pageContext.request.contextPath}';

// ── Tab switching ─────────────────────────────────
function switchTab(tab, btn) {
  document.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
  document.getElementById('tab-' + tab).classList.add('active');
  if (btn) btn.classList.add('active');
  // Load chart khi vào tab doanh thu
  if (tab === 'revenue') setTimeout(loadChart, 50);
}

// ── Period label ──────────────────────────────────
(function() {
  const weekStart = new Date('${weekStart}');
  const weekEnd   = new Date('${weekEnd}');
  const opts = { day:'numeric', month:'numeric' };
  const label = document.getElementById('periodLabel');
  if (label && weekStart && !isNaN(weekStart)) {
    label.textContent = weekStart.toLocaleDateString('vi-VN', opts)
      + ' – ' + weekEnd.toLocaleDateString('vi-VN', opts);
  }
})();

// ── Toast auto-hide ───────────────────────────────
const toast = document.getElementById('toast');
if (toast) setTimeout(() => { toast.style.opacity='0'; toast.style.transition='opacity .5s'; setTimeout(()=>toast.remove(),500); }, 3500);

// ── Search table ──────────────────────────────────
function filterShiftTable(q) {
  q = (q||'').toLowerCase().trim();
  document.querySelectorAll('#shiftTbody tr').forEach(row => {
    row.style.display = (!q || row.textContent.toLowerCase().includes(q)) ? '' : 'none';
  });
}

// ══════════════════════════════════════════════════
//  MODAL: Xếp ca mới (Quick Schedule)
// ══════════════════════════════════════════════════
function openSchedModal(preDate, preAccountId) {
  // Pre-fill ngày nếu có
  const today = new Date().toISOString().split('T')[0];
  document.getElementById('schedFrom').value = preDate || today;
  document.getElementById('schedTo').value   = '';
  // Pre-check nhân viên nếu có
  if (preAccountId) {
    const cb = document.querySelector('#staffChipsGrid input[value="'+preAccountId+'"]');
    if (cb) cb.checked = true;
  }
  // Uncheck all radio
  document.querySelectorAll('#schedForm input[name="shiftTypeId"]').forEach(r => r.checked = false);
  updateSchedPreview();
  document.getElementById('schedModal').classList.add('open');
}
function openSchedModalForDay(date, accountId) {
  openSchedModal(date, accountId);
}
function closeSchedModal() {
  document.getElementById('schedModal').classList.remove('open');
}
function updateSchedPreview() {
  const from = document.getElementById('schedFrom').value;
  const to   = document.getElementById('schedTo').value;
  const prev = document.getElementById('schedPreview');
  if (!from) { prev.style.display='none'; return; }
  const checkedStaff = document.querySelectorAll('#staffChipsGrid input:checked').length;
  const fromD = new Date(from);
  const toD   = to ? new Date(to) : fromD;
  if (isNaN(fromD) || isNaN(toD)) { prev.style.display='none'; return; }
  const days = Math.max(1, Math.round((toD - fromD) / 86400000) + 1);
  const total = days * Math.max(1, checkedStaff);
  prev.style.display = 'block';
  prev.innerHTML = '📅 <strong>' + days + ' ngày</strong> × <strong>' + Math.max(1,checkedStaff) + ' nhân viên</strong> = tạo <strong>' + total + ' lịch ca</strong>';
}
function submitSchedForm() {
  const checkedStaff = document.querySelectorAll('#staffChipsGrid input:checked').length;
  const checkedType  = document.querySelector('#schedForm input[name="shiftTypeId"]:checked');
  const from = document.getElementById('schedFrom').value;
  if (checkedStaff === 0) { alert('Vui lòng chọn ít nhất 1 nhân viên!'); return; }
  if (!checkedType) { alert('Vui lòng chọn loại ca!'); return; }
  if (!from) { alert('Vui lòng chọn ngày bắt đầu!'); return; }
  document.getElementById('schedForm').submit();
}
document.getElementById('schedModal').addEventListener('click', function(e) {
  if (e.target === this) closeSchedModal();
});
// Update preview khi tick nhân viên
document.querySelectorAll('#staffChipsGrid input').forEach(cb => {
  cb.addEventListener('change', updateSchedPreview);
});

// ══════════════════════════════════════════════════
//  MODAL: ShiftType CRUD
// ══════════════════════════════════════════════════
function openTypeModal() {
  document.getElementById('modalTitle').textContent = 'Thêm loại ca mới';
  document.getElementById('typeAction').value = 'create';
  document.getElementById('editTypeId').value = '';
  document.getElementById('typeForm').reset();
  document.getElementById('typeStartTime').value = '06:00';
  document.getElementById('typeEndTime').value   = '14:00';
  document.getElementById('typeRate').value      = '60000';
  updateDurPreview();
  document.getElementById('typeModal').classList.add('open');
}
function editType(id, name, sh, sm, eh, em, rate, allow) {
  document.getElementById('modalTitle').textContent = 'Sửa loại ca';
  document.getElementById('typeAction').value = 'update';
  document.getElementById('editTypeId').value = id;
  document.getElementById('typeName').value   = name;
  document.getElementById('typeStartTime').value = String(sh).padStart(2,'0')+':'+String(sm).padStart(2,'0');
  document.getElementById('typeEndTime').value   = String(eh).padStart(2,'0')+':'+String(em).padStart(2,'0');
  document.getElementById('typeRate').value      = rate;
  document.getElementById('typeAllowance').value = allow;
  updateDurPreview();
  document.getElementById('typeModal').classList.add('open');
}
function closeTypeModal() { document.getElementById('typeModal').classList.remove('open'); }
document.getElementById('typeModal').addEventListener('click', function(e) {
  if (e.target === this) closeTypeModal();
});
function updateDurPreview() {
  const s = document.getElementById('typeStartTime').value;
  const e = document.getElementById('typeEndTime').value;
  const p = document.getElementById('durPreview');
  if (!s || !e) { p.textContent = ''; return; }
  const sh = parseInt(s.split(':')[0]), sm = parseInt(s.split(':')[1]);
  const eh = parseInt(e.split(':')[0]), em = parseInt(e.split(':')[1]);
  let dur = (eh * 60 + em - sh * 60 - sm) / 60;
  if (dur <= 0) dur += 24;
  const rate = parseInt(document.getElementById('typeRate').value) || 60000;
  const total = Math.round(dur * rate);
  const caType = dur >= 10 ? '🟣 Ca dài/gãy' : dur >= 7 ? '🔵 Ca tiêu chuẩn' : '🟢 Part-time';
  p.innerHTML = caType + ' &nbsp;|&nbsp; ⏱ ' + dur.toFixed(1) + ' tiếng &nbsp;|&nbsp; 💰 Tổng lương: <strong>' + total.toLocaleString('vi') + 'đ</strong>';
}
['typeStartTime','typeEndTime','typeRate'].forEach(id => {
  const el = document.getElementById(id);
  if (el) el.addEventListener('input', updateDurPreview);
});
function validateRate(el) {
  const err = document.getElementById('rateErr');
  if (parseInt(el.value) < 50000) { err.style.display='block'; el.style.borderColor='var(--red)'; }
  else { err.style.display='none'; el.style.borderColor=''; }
  updateDurPreview();
}
function submitTypeForm() {
  const rate = parseInt(document.getElementById('typeRate').value);
  if (rate < 50000) { validateRate(document.getElementById('typeRate')); return; }
  document.getElementById('typeForm').submit();
}
function toggleType(id, active) {
  if (confirm(active ? 'Tạm dừng loại ca này?' : 'Kích hoạt lại loại ca này?')) {
    const f = document.createElement('form');
    f.method = 'post';
    f.action = ctx_path + '/shift-types';
    f.innerHTML = '<input name="action" value="toggle"><input name="shiftTypeId" value="'+id+'">';
    document.body.appendChild(f); f.submit();
  }
}
function deleteType(id, name) {
  if (confirm('Xóa loại ca "'+name+'"?\nChỉ xóa được khi không còn lịch ca nào dùng loại này.')) {
    location.href = ctx_path + '/shift-types?action=delete&id=' + id;
  }
}

// ══════════════════════════════════════════════════
//  BIỂU ĐỒ DOANH THU CA
// ══════════════════════════════════════════════════
let cashChartInstance = null;
let _chartType = 'line';

function setChartType(t) {
  _chartType = t;
  const btnLine = document.getElementById('btnLine');
  const btnBar  = document.getElementById('btnBar');
  if (btnLine) { btnLine.style.background = t==='line' ? '#1558A8' : 'transparent'; btnLine.style.color = t==='line' ? '#fff' : '#7A90B0'; }
  if (btnBar)  { btnBar.style.background  = t==='bar'  ? '#1558A8' : 'transparent'; btnBar.style.color  = t==='bar'  ? '#fff' : '#7A90B0'; }
  loadChart();
}

async function loadChart() {
  const mSel = document.getElementById('chartMonthSel');
  const ySel = document.getElementById('chartYearSel');
  const canvas = document.getElementById('cashChart');
  if (!mSel || !ySel || !canvas) return;
  try {
    const res  = await fetch(ctx_path + '/shifts?action=chart-data&month=' + mSel.value + '&year=' + ySel.value);
    const data = await res.json();
    if (cashChartInstance) cashChartInstance.destroy();
    const fmt  = v => new Intl.NumberFormat('vi-VN').format(v) + 'đ';
    const sumO = (data.opening||[]).reduce((a,b)=>a+b,0);
    const sumC = (data.closing||[]).reduce((a,b)=>a+b,0);
    const diff = sumC - sumO;
    const days = (data.labels||[]).length;
    const el = id => document.getElementById(id);
    if (el('kpiOpening')) el('kpiOpening').textContent = fmt(sumO);
    if (el('kpiClosing')) el('kpiClosing').textContent = fmt(sumC);
    if (el('kpiDiff'))  { el('kpiDiff').textContent = (diff>=0?'+':'')+fmt(diff); el('kpiDiff').style.color = diff>=0?'#059669':'#DC2626'; }
    if (el('kpiDays'))    el('kpiDays').textContent = days + ' ngày';
    const trend = el('chartTrend');
    if (trend && days >= 2) {
      const last = (data.closing||[])[days-1]||0;
      const prev = (data.closing||[])[days-2]||0;
      const pct  = prev > 0 ? ((last-prev)/prev*100).toFixed(1) : 0;
      const up   = last >= prev;
      trend.textContent = (up?'▲ ':'▼ ') + Math.abs(pct) + '% so hôm qua';
      trend.style.background = up?'rgba(5,150,105,.12)':'rgba(220,38,38,.12)';
      trend.style.color = up?'#059669':'#DC2626';
    }
    cashChartInstance = new Chart(canvas.getContext('2d'), {
      type: _chartType,
      data: {
        labels: data.labels||[],
        datasets: [
          { label:'Tiền đầu ca',  data:data.opening||[], borderColor:'#1558A8', backgroundColor:_chartType==='bar'?'rgba(21,88,168,.7)':'rgba(21,88,168,.08)', borderWidth:_chartType==='bar'?0:2, pointRadius:4, fill:_chartType==='line', tension:.4 },
          { label:'Tiền cuối ca', data:data.closing||[], borderColor:'#059669', backgroundColor:_chartType==='bar'?'rgba(5,150,105,.7)':'rgba(5,150,105,.08)', borderWidth:_chartType==='bar'?0:2, pointRadius:4, fill:_chartType==='line', tension:.4 }
        ]
      },
      options:{
        responsive:true, maintainAspectRatio:false,
        interaction:{mode:'index',intersect:false},
        plugins:{
          legend:{display:false},
          tooltip:{backgroundColor:'rgba(11,22,40,.92)',titleColor:'#fff',bodyColor:'#ccc',padding:10,cornerRadius:8,
            callbacks:{label:c=>' '+c.dataset.label+': '+new Intl.NumberFormat('vi-VN').format(c.raw)+'đ'}}
        },
        scales:{
          y:{ticks:{callback:v=>new Intl.NumberFormat('vi-VN',{notation:'compact'}).format(v)+'đ',font:{family:'Outfit',size:11},color:'#7A90B0'},grid:{color:'rgba(0,0,0,0.04)'}},
          x:{ticks:{font:{family:'Outfit',size:11},color:'#7A90B0'},grid:{display:false}}
        }
      }
    });
  } catch(e) { console.warn('Chart error', e); }
}

document.addEventListener('DOMContentLoaded', () => {
  const mSel = document.getElementById('chartMonthSel');
  const ySel = document.getElementById('chartYearSel');
  if (ySel) ySel.value = String(new Date().getFullYear());
  if (mSel) mSel.value = String(new Date().getMonth()+1);
  // Chỉ auto-load chart nếu đang ở tab revenue
  if (document.getElementById('tab-revenue') && document.getElementById('tab-revenue').classList.contains('active')) loadChart();
});

// ── Hủy lịch ca từ week grid ─────────────────────────────────────────────
function cancelSchedule(scheduleId) {
  if (confirm('Hủy lịch ca này?')) {
    // POST đến /shifts?action=cancel-schedule&id=X
    const f = document.createElement('form');
    f.method = 'post';
    f.action = ctx_path + '/shifts';
    f.innerHTML = '<input name="action" value="cancel-schedule">' +
                  '<input name="scheduleId" value="' + scheduleId + '">';
    document.body.appendChild(f);
    f.submit();
  }
}

// ══════════════════════════════════════════════════════
//  FULL SCHEDULE MODAL — nhiều NV + nhiều ca + range ngày
// ══════════════════════════════════════════════════════
function openFullSchedModal(preDate, preAccountId) {
  const today = new Date().toISOString().split('T')[0];
  const fromEl = document.getElementById('fsDateFrom');
  const toEl   = document.getElementById('fsDateTo');
  if (fromEl) fromEl.value = preDate || today;
  if (toEl)   toEl.value   = '';

  // Uncheck all staff & types
  document.querySelectorAll('#fullStaffChips input').forEach(cb => cb.checked = false);
  document.querySelectorAll('#fullStypeCards input').forEach(cb => cb.checked = false);

  // Pre-check nhân viên nếu có
  if (preAccountId) {
    const cb = document.querySelector('#fullStaffChips input[value="' + preAccountId + '"]');
    if (cb) cb.checked = true;
  }

  updateFullPreview();
  document.getElementById('fullSchedModal').classList.add('open');
  // Đóng modal xếp ca cũ nếu đang mở
  const old = document.getElementById('schedModal');
  if (old) old.classList.remove('open');
}

function closeFullSchedModal() {
  document.getElementById('fullSchedModal').classList.remove('open');
}

function toggleAllStaff() {
  const visibleCbs = [...document.querySelectorAll('#fullStaffChips .sc-chip:not(.hidden) input')];
  if (visibleCbs.length === 0) return;
  const allChecked = visibleCbs.every(cb => cb.checked);
  visibleCbs.forEach(cb => { cb.checked = !allChecked; });
  updateFullPreview();
}

function updateFullPreview() {
  const staffCount = document.querySelectorAll('#fullStaffChips .sc-chip:not(.hidden) input:checked').length;
  const typeCount  = document.querySelectorAll('#fullStypeCards input:checked').length;
  const fromVal    = document.getElementById('fsDateFrom')?.value;
  const toVal      = document.getElementById('fsDateTo')?.value;
  const preview    = document.getElementById('fullSchedPreview');

  if (!fromVal || staffCount === 0 || typeCount === 0) {
    if (preview) preview.style.display = 'none';
    return;
  }

  const fromD = new Date(fromVal);
  const toD   = toVal ? new Date(toVal) : fromD;
  const days  = Math.max(1, Math.round((toD - fromD) / 86400000) + 1);
  const total = days * staffCount * typeCount;

  document.getElementById('fpDays').textContent  = days;
  document.getElementById('fpStaff').textContent = staffCount;
  document.getElementById('fpTypes').textContent = typeCount;
  document.getElementById('fpTotal').textContent = total;
  if (preview) preview.style.display = 'block';
}

function submitFullSched() {
  const staffCount = document.querySelectorAll('#fullStaffChips .sc-chip:not(.hidden) input:checked').length;
  const typeCount  = document.querySelectorAll('#fullStypeCards input:checked').length;
  const fromVal    = document.getElementById('fsDateFrom')?.value;

  if (staffCount === 0) { alert('Vui lòng chọn ít nhất 1 nhân viên!'); return; }
  if (typeCount  === 0) { alert('Vui lòng chọn ít nhất 1 loại ca!');    return; }
  if (!fromVal)         { alert('Vui lòng chọn ngày bắt đầu!');          return; }

  document.getElementById('fullSchedForm').submit();
}

// Click outside to close
document.getElementById('fullSchedModal').addEventListener('click', function(e) {
  if (e.target === this) closeFullSchedModal();
});

// Update preview khi tick nhân viên / loại ca
document.querySelectorAll('#fullStaffChips input, #fullStypeCards input').forEach(cb => {
  cb.addEventListener('change', updateFullPreview);
});

// Đổi hàm openSchedModal và openSchedModalForDay → gọi modal mới
function openSchedModal(preDate, preAccountId) {
  openFullSchedModal(preDate, preAccountId);
}
function openSchedModalForDay(date, accountId) {
  openFullSchedModal(date, accountId);
}


// ── Tìm kiếm nhân viên trong modal ───────────────────────────────────────
function filterStaffChips(q) {
  q = (q || '').toLowerCase().trim();
  const chips = document.querySelectorAll('#fullStaffChips .sc-chip');
  let visible = 0;
  chips.forEach(chip => {
    const search = (chip.dataset.search || '').toLowerCase();
    const match = !q || search.includes(q);
    chip.classList.toggle('hidden', !match);
    if (match) visible++;
  });
  const countEl = document.getElementById('staffSearchCount');
  if (countEl) {
    countEl.textContent = q ? visible + ' kết quả' : '';
  }
  updateFullPreview();
}

// Xóa search khi đóng modal
const _origClose = closeFullSchedModal;
closeFullSchedModal = function() {
  const si = document.getElementById('staffSearchInput');
  if (si) { si.value = ''; filterStaffChips(''); }
  _origClose();
};


// ════════════════════════════════════════════════════════
//  EDIT MODAL — sửa lịch ca SCHEDULED
// ════════════════════════════════════════════════════════
function openEditModal(schedId, shiftTypeId, shiftTypeName, lateTol, notes, staffName, workDate) {
  document.getElementById('editSchedId').value   = schedId;
  document.getElementById('editShiftType').value  = shiftTypeId;
  document.getElementById('editLateTol').value    = lateTol || 10;
  document.getElementById('editNotes').value      = notes && notes !== 'null' ? notes : '';
  document.getElementById('editWorkDate').value   = workDate;
  document.getElementById('editModalTitle').textContent = '✏️ Sửa ca ' + staffName + ' — ' + workDate;
  document.getElementById('editSchedModal').classList.add('open');
}
function closeEditModal() {
  document.getElementById('editSchedModal').classList.remove('open');
}
function submitEditSched() {
  const stId = document.getElementById('editShiftType').value;
  if (!stId) { alert('Vui lòng chọn loại ca!'); return; }
  document.getElementById('editSchedForm').submit();
}
document.getElementById('editSchedModal').addEventListener('click', function(e) {
  if (e.target === this) closeEditModal();
});

// ════════════════════════════════════════════════════════
//  ADD NEXT DAY — xếp ca ngày hôm sau (ca đang chạy)
// ════════════════════════════════════════════════════════
function openAddNextDay(accountId, staffName, shiftTypeId, workDate) {
  // Tính ngày hôm sau
  const d = new Date(workDate);
  d.setDate(d.getDate() + 1);
  const nextDate = d.toISOString().split('T')[0];
  // Mở modal xếp ca đầy đủ với pre-fill
  openFullSchedModal(nextDate, accountId);
}

// ════════════════════════════════════════════════════════
//  DELETE STAFF MODAL — xóa lịch ca theo nhân viên
// ════════════════════════════════════════════════════════
let _delAccountId = null;
let _delItems     = [];

function openDeleteStaffModal(accountId, staffName, refDate) {
  _delAccountId = accountId;
  _delItems     = [];

  // Set staff info
  const ini = staffName.split(' ').map(w=>w[0]).join('').substring(0,2).toUpperCase();
  document.getElementById('delStaffAv').textContent   = ini;
  document.getElementById('delStaffName').textContent = staffName;

  // Set default date range = tuần hiện tại
  document.getElementById('delFromDate').value = refDate || new Date().toISOString().split('T')[0];
  document.getElementById('delToDate').value   = '';

  document.getElementById('delPreviewBox').style.display  = 'none';
  document.getElementById('delEmptyBox').style.display    = 'none';
  document.getElementById('delLoadingBox').style.display  = 'none';
  document.getElementById('delConfirmBtn').disabled       = true;
  document.getElementById('delConfirmBtn').style.opacity  = '.5';
  document.getElementById('delConfirmBtn').style.cursor   = 'not-allowed';
  document.getElementById('delTotalCount').textContent    = '';
  document.getElementById('delItemsList').innerHTML       = '';

  document.getElementById('deleteStaffModal').classList.add('open');

  // Load preview ngay
  loadDelPreview();
}

function closeDeleteModal() {
  document.getElementById('deleteStaffModal').classList.remove('open');
}

function loadDelPreview() {
  if (!_delAccountId) return;
  const from = document.getElementById('delFromDate').value;
  const to   = document.getElementById('delToDate').value || from;
  if (!from) { document.getElementById('delPreviewBox').style.display = 'none'; return; }

  // Lọc từ SCHED_LIST (data đã inject từ server)
  const fromD = new Date(from);
  const toD   = new Date(to);

  _delItems = (typeof SCHED_LIST !== 'undefined' ? SCHED_LIST : []).filter(sc => {
    if (sc.accountId != _delAccountId) return false;
    const d = new Date(sc.workDate);
    if (d < fromD || d > toD) return false;
    // Chỉ xóa được SCHEDULED, LEAVE_PENDING, CANCELLED
    return ['SCHEDULED','LEAVE_PENDING','CANCELLED'].includes(sc.status);
  });

  const listEl  = document.getElementById('delItemsList');
  const preview = document.getElementById('delPreviewBox');
  const empty   = document.getElementById('delEmptyBox');
  const countEl = document.getElementById('delCount');
  const totalEl = document.getElementById('delTotalCount');
  const btnEl   = document.getElementById('delConfirmBtn');

  listEl.innerHTML = '';

  if (_delItems.length === 0) {
    preview.style.display = 'none';
    empty.style.display   = 'block';
    btnEl.disabled        = true;
    btnEl.style.opacity   = '.5';
    btnEl.style.cursor    = 'not-allowed';
    totalEl.textContent   = '';
    return;
  }

  empty.style.display   = 'none';
  preview.style.display = 'block';
  countEl.textContent   = _delItems.length;
  totalEl.textContent   = _delItems.length + ' lịch ca sẽ bị xóa';
  btnEl.disabled        = false;
  btnEl.style.opacity   = '1';
  btnEl.style.cursor    = 'pointer';

  _delItems.forEach(sc => {
    const row = document.createElement('div');
    row.className = 'dm-item';
    const timeStr = sc.plannedStart ? sc.plannedStart + '→' + sc.plannedEnd : '';
    const statusBg = sc.status === 'SCHEDULED' ? '#DBEAFE' : '#FEF3C7';
    const statusColor = sc.status === 'SCHEDULED' ? '#1E40AF' : '#92400E';
    row.innerHTML = `
      <div class="dm-item-info">
        <div class="dm-item-name">${sc.shiftTypeName}</div>
        <div class="dm-item-meta">${sc.workDate} ${timeStr}</div>
      </div>
      <span style="font-size:10.5px;font-weight:700;padding:2px 8px;border-radius:6px;background:${statusBg};color:${statusColor}">${sc.status}</span>
    `;
    listEl.appendChild(row);
  });
}

function submitDeleteStaff() {
  if (!_delAccountId || _delItems.length === 0) return;
  const from = document.getElementById('delFromDate').value;
  const to   = document.getElementById('delToDate').value || from;
  if (!confirm('Xác nhận xóa ' + _delItems.length + ' lịch ca của nhân viên này?')) return;

  const f = document.createElement('form');
  f.method = 'post';
  f.action = ctx_path + '/shifts';
  f.innerHTML =
    '<input name="action" value="schedule-delete-staff">' +
    '<input name="accountId" value="' + _delAccountId + '">' +
    '<input name="dateFrom"  value="' + from + '">' +
    '<input name="dateTo"    value="' + to   + '">';
  // Thêm từng scheduleId để xóa chính xác
  _delItems.forEach(sc => {
    const inp = document.createElement('input');
    inp.name  = 'scheduleIds';
    inp.value = sc.id;
    f.appendChild(inp);
  });
  document.body.appendChild(f);
  f.submit();
}

document.getElementById('deleteStaffModal').addEventListener('click', function(e) {
  if (e.target === this) closeDeleteModal();
});


// ════════════════════════════════════════════════════════
//  EDIT SELECT MODAL
// ════════════════════════════════════════════════════════
let _editSelIds = new Set(); // scheduleId đã chọn

function openEditSelectModal() {
  _editSelIds.clear();
  // Reset tất cả chip
  document.querySelectorAll('#editWeekGrid .sm-chip').forEach(ch => {
    ch.classList.remove('sm-selected-edit');
  });
  document.getElementById('editPanel').classList.remove('show');
  updateEditSelUI();
  document.getElementById('editSelectModal').classList.add('open');
}
function closeEditSelectModal() {
  document.getElementById('editSelectModal').classList.remove('open');
}

function toggleEditChip(el) {
  if (el.dataset.editable !== 'true') return; // locked
  const id = el.dataset.schedId;
  if (_editSelIds.has(id)) {
    _editSelIds.delete(id);
    el.classList.remove('sm-selected-edit');
  } else {
    _editSelIds.add(id);
    el.classList.add('sm-selected-edit');
  }
  updateEditSelUI();
}

function updateEditSelUI() {
  const count = _editSelIds.size;
  const badge = document.getElementById('editSelBadge');
  const hint  = document.getElementById('editSelHint');
  const btn1  = document.getElementById('editSelActionBtn');
  const btn2  = document.getElementById('editSelFootBtn');
  const panel = document.getElementById('editPanel');
  const prev  = document.getElementById('smEditPreview');

  badge.textContent = count + ' ca đã chọn';
  badge.classList.toggle('show', count > 0);

  if (count === 0) {
    hint.textContent = 'Click vào chip ca để chọn';
    btn1.classList.remove('enabled');
    btn2.classList.remove('enabled');
    panel.classList.remove('show');
  } else {
    hint.textContent = count + ' ca đã chọn — điều chỉnh bên dưới rồi bấm Lưu';
    btn1.classList.add('enabled');
    btn2.classList.add('enabled');
    panel.classList.add('show');
    // Preview
    const stSel = document.getElementById('smEditShiftType');
    const stName = stSel.options[stSel.selectedIndex]?.text || 'Giữ nguyên';
    const lat = document.getElementById('smEditLateTol').value;
    prev.textContent = count + ' ca sẽ được cập nhật' +
      (stSel.value ? ' → ' + stName : '') +
      (lat ? ', trễ ' + lat + 'p' : '');
  }
}

// Update preview khi đổi loại ca
document.getElementById('smEditShiftType')?.addEventListener('change', updateEditSelUI);
document.getElementById('smEditLateTol')?.addEventListener('input', updateEditSelUI);

function applyEditSel() {
  if (_editSelIds.size === 0) return;
  const stId  = document.getElementById('smEditShiftType').value;
  const lat   = document.getElementById('smEditLateTol').value;
  const notes = document.getElementById('smEditNotes').value;

  if (!stId && !lat && !notes.trim()) {
    alert('Vui lòng chọn ít nhất 1 thông tin cần thay đổi (loại ca, dung sai, hoặc ghi chú)!');
    return;
  }
  // Không bắt buộc chọn loại ca — để trống = giữ nguyên loại ca hiện tại
  if (!confirm('Lưu thay đổi cho ' + _editSelIds.size + ' ca đã chọn?')) return;

  const f = document.createElement('form');
  f.method = 'post';
  f.action = ctx_path + '/shifts';
  let html = '<input name="action" value="schedule-bulk-update">'
    + '<input name="shiftTypeId" value="' + stId + '">'
    + '<input name="lateToleranceMinutes" value="' + (lat || '10') + '">'
    + '<input name="notes" value="' + notes.replace(/"/g,'&quot;') + '">';
  _editSelIds.forEach(id => {
    html += '<input name="scheduleIds" value="' + id + '">';
  });
  f.innerHTML = html;
  document.body.appendChild(f);
  f.submit();
}

document.getElementById('editSelectModal').addEventListener('click', function(e) {
  if (e.target === this) closeEditSelectModal();
});

// ════════════════════════════════════════════════════════
//  DELETE SELECT MODAL
// ════════════════════════════════════════════════════════
let _delSelIds = new Set();

function openDeleteSelectModal() {
  _delSelIds.clear();
  document.querySelectorAll('#deleteWeekGrid .sm-chip').forEach(ch => {
    ch.classList.remove('sm-selected-del');
  });
  document.getElementById('delSelSummary').style.display = 'none';
  document.getElementById('delSelList').innerHTML = '';
  updateDelSelUI();
  document.getElementById('deleteSelectModal').classList.add('open');
}
function closeDeleteSelectModal() {
  document.getElementById('deleteSelectModal').classList.remove('open');
}

function toggleDelChip(el) {
  if (el.dataset.deletable !== 'true') return;
  const id = el.dataset.schedId;
  if (_delSelIds.has(id)) {
    _delSelIds.delete(id);
    el.classList.remove('sm-selected-del');
  } else {
    _delSelIds.add(id);
    el.classList.add('sm-selected-del');
  }
  updateDelSelUI();
}

function updateDelSelUI() {
  const count   = _delSelIds.size;
  const badge   = document.getElementById('deleteSelBadge');
  const hint    = document.getElementById('deleteSelHint');
  const btn1    = document.getElementById('deleteSelActionBtn');
  const btn2    = document.getElementById('deleteSelFootBtn');
  const summary = document.getElementById('delSelSummary');
  const listEl  = document.getElementById('delSelList');
  const countEl = document.getElementById('delSelCount');

  badge.textContent = count + ' ca đã chọn';
  badge.classList.toggle('show', count > 0);

  if (count === 0) {
    hint.textContent = 'Click vào chip ca để chọn';
    btn1.classList.remove('enabled');
    btn2.classList.remove('enabled');
    summary.style.display = 'none';
    listEl.innerHTML = '';
    return;
  }

  hint.textContent = count + ' ca sẽ bị xóa vĩnh viễn';
  btn1.classList.add('enabled');
  btn2.classList.add('enabled');
  summary.style.display = 'block';
  countEl.textContent = count;

  // Build tag list
  listEl.innerHTML = '';
  _delSelIds.forEach(id => {
    const chip = document.getElementById('del-chip-' + id);
    if (!chip) return;
    const name = chip.querySelector('.sm-chip-name')?.textContent || '';
    const type = chip.querySelector('.sm-chip-type')?.textContent || '';
    const tag = document.createElement('span');
    tag.style.cssText = 'background:#fff;border:1px solid #FECACA;border-radius:6px;padding:3px 8px;font-size:11.5px;font-weight:600;color:#991B1B';
    tag.textContent = name + ' · ' + type;
    listEl.appendChild(tag);
  });
}

function applyDeleteSel() {
  if (_delSelIds.size === 0) return;
  if (!confirm('Xóa vĩnh viễn ' + _delSelIds.size + ' ca đã chọn?\nHành động này không thể hoàn tác!')) return;

  const f = document.createElement('form');
  f.method = 'post';
  f.action = ctx_path + '/shifts';
  let html = '<input name="action" value="schedule-bulk-delete">';
  _delSelIds.forEach(id => {
    html += '<input name="scheduleIds" value="' + id + '">';
  });
  f.innerHTML = html;
  document.body.appendChild(f);
  f.submit();
}

document.getElementById('deleteSelectModal').addEventListener('click', function(e) {
  if (e.target === this) closeDeleteSelectModal();
});

function openChipEditModal(scheduleId, staffName, workDate, currentTypeId) {
  // Mở modal sửa ca inline (editSchedModal hoặc editSchedForm)
  const modal = document.getElementById('editSchedModal');
  if (!modal) return;
  document.getElementById('editSchedStaffName')  && (document.getElementById('editSchedStaffName').textContent = staffName);
  document.getElementById('editSchedDate')        && (document.getElementById('editSchedDate').textContent = workDate);
  document.getElementById('editSchedId')          && (document.getElementById('editSchedId').value = scheduleId);
  // Pre-select loại ca
  const sel = document.getElementById('editSchedTypeId');
  if (sel) sel.value = currentTypeId;
  modal.classList.add('open');
}
</script>
</body>
</html>
