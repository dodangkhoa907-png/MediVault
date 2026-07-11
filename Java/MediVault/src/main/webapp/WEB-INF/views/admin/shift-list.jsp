<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" language="java" %>
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
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50;flex-shrink:0}
.topbar-title{font-family:'Outfit',sans-serif;font-size:16px;font-weight:700;color:var(--ink)}
.topbar-left{display:flex;align-items:center;gap:10px}
.topbar-icon{width:34px;height:34px;border-radius:9px;background:linear-gradient(135deg,rgba(21,88,168,.12),rgba(58,189,224,.12));display:flex;align-items:center;justify-content:center;font-size:15px}

    
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.topbar-pill{display:inline-flex;align-items:center;gap:6px;padding:4px 12px;border-radius:20px;font-size:12.5px;font-weight:700}
.pill-total{background:#EFF6FF;color:var(--blue)}
.pill-open{background:#ECFDF5;color:var(--green)}
.pill-staff{background:#F5F3FF;color:var(--purple)}
.topbar-user{display:flex;align-items:center;gap:8px;padding:5px 12px 5px 7px;border:1.5px solid var(--border);border-radius:20px;text-decoration:none;color:inherit;transition:all .18s}
.topbar-user:hover{border-color:var(--cyan)}
.topbar-av{width:28px;height:28px;border-radius:8px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;color:#fff}
.topbar-name{font-size:13px;font-weight:600;color:var(--navy)}
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
.modal-overlay{display:none;position:fixed;inset:0;background:rgba(11,22,40,.5);z-index:9999;align-items:center;justify-content:center}
.modal-overlay.open{display:flex}
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
/* ── Custom 24h time picker ── */
.time24-wrap{display:flex;align-items:center;gap:4px}
.time24-sel{flex:1;border:1.5px solid var(--border);border-radius:9px;padding:9px 8px;font-family:'Outfit',sans-serif;font-size:15px;font-weight:700;color:var(--ink);background:var(--surface);outline:none;transition:border .18s;text-align:center;cursor:pointer;appearance:none;-webkit-appearance:none}
.time24-sel:focus{border-color:var(--blue);background:#fff}
.time24-colon{font-size:20px;font-weight:800;color:var(--ink);flex-shrink:0;line-height:1;padding:0 2px;margin-top:-1px}
.modal-foot{padding:14px 22px;border-top:1px solid var(--border);display:flex;justify-content:flex-end;gap:8px}
.btn-cancel-m{padding:8px 18px;background:var(--surface);color:var(--muted);border:1.5px solid var(--border);border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;cursor:pointer;transition:all .18s}
.btn-cancel-m:hover{border-color:var(--muted)}
.btn-save-m{padding:8px 22px;background:linear-gradient(135deg,var(--blue),var(--cyan));color:#fff;border:none;border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;box-shadow:0 3px 10px rgba(21,88,168,.2);transition:all .18s}
.btn-save-m:hover{opacity:.9}
.field-hint{font-size:11px;color:var(--muted);margin-top:3px}
.field-err{font-size:11px;color:var(--red);margin-top:3px;display:none}
.field-err.show{display:block}
.sched-fi input.err,.sched-fi select.err{border-color:var(--red)!important}

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
.dur-warn{font-size:12px;font-weight:700;color:#991B1B;background:#FEF2F2;border:1.5px solid #FECACA;
  border-radius:8px;padding:10px 12px;margin-top:-6px;margin-bottom:14px;line-height:1.5}

/* ── MODAL XẾP CA ĐẦY ĐỦ ── */
.sched-overlay{display:none;position:fixed;inset:0;background:rgba(11,22,40,.55);z-index:9999;align-items:center;justify-content:center}
.sched-overlay.open{display:flex}
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
/* ══ LỊCH TUẦN 3D — cột không co dưới 150px: màn hẹp tự xuống hàng (4+3)
      thay vì bóp méo chữ khi zoom 100%.
      LƯU Ý: KHÔNG dùng perspective/will-change ở đây — chúng tạo 3D-context
      làm hỏng hit-test click của các phần tử con (nút + Thêm ca, thẻ ca).
      Hiệu ứng nâng dùng translateY thuần → an toàn tuyệt đối với click. ══ */
.week-grid{display:grid;grid-template-columns:repeat(7,minmax(0,1fr));gap:10px;margin-bottom:20px}
@media(max-width:1420px){.week-grid{grid-template-columns:repeat(4,minmax(150px,1fr))}}
@media(max-width:900px){.week-grid{grid-template-columns:repeat(2,minmax(150px,1fr))}}
.day-col{
  background:linear-gradient(160deg,#ffffff 0%,#f6f9ff 100%);
  border:1px solid rgba(213,224,240,.8);border-radius:16px;overflow:visible;min-height:96px;
  box-shadow:0 1px 2px rgba(15,38,69,.05),0 10px 22px -14px rgba(15,38,69,.28);
  transition:box-shadow .18s,border-color .18s;
  position:relative;z-index:0}
.day-col:hover{
  border-color:#BFDBFE;
  box-shadow:0 4px 8px rgba(15,38,69,.07),0 24px 38px -16px rgba(21,88,168,.35)}
.day-col.today-col{
  border-color:var(--blue);
  background:linear-gradient(160deg,#ffffff 0%,#eef6ff 100%);
  box-shadow:0 0 0 2px rgba(21,88,168,.14),0 14px 28px -14px rgba(21,88,168,.4)}
.day-col.past-col{opacity:.55}
.day-col.past-col:hover{opacity:.8}
.day-col.past-col .day-head{background:var(--surface)}
.day-head{padding:11px 8px;border-bottom:1px solid var(--border);text-align:center;border-radius:16px 16px 0 0}
.day-name{font-size:10.5px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.7px}
.day-date{font-size:22px;font-weight:900;color:var(--ink);margin-top:2px;line-height:1}
.day-col.today-col .day-date{color:var(--blue)}
.day-col.today-col .day-name::after{content:' •';color:var(--cyan)}
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
.day-add{display:flex;align-items:center;justify-content:center;padding:7px;color:var(--muted);font-size:11px;border:1.5px dashed var(--border);border-radius:8px;cursor:pointer;transition:all .18s;margin-top:4px;background:transparent;width:100%;box-sizing:border-box;font-family:'Outfit',sans-serif;outline:none}
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

/* ════════════════════════════════════════════════════
   GROUPED STAFF CARD — week calendar (new design)
   Mỗi nhân viên/ngày = 1 card gom tất cả ca
   ════════════════════════════════════════════════════ */
.staff-card{
  background:var(--white);border:1px solid var(--border);border-radius:10px;
  margin-bottom:6px;cursor:pointer;transition:box-shadow .18s,border-color .18s;
  position:relative;overflow:visible;z-index:1;
}
.staff-card:hover{border-color:#93C5FD;box-shadow:0 3px 14px rgba(21,88,168,.13)}
.staff-card-head{
  display:flex;align-items:center;gap:7px;padding:7px 9px 5px;
}
.scard-av{
  width:26px;height:26px;border-radius:7px;flex-shrink:0;font-size:10px;
  font-weight:800;color:#fff;display:flex;align-items:center;justify-content:center;
}
.scard-av.av-morning  {background:linear-gradient(135deg,#3B82F6,#1D4ED8)}
.scard-av.av-afternoon{background:linear-gradient(135deg,#F97316,#C2410C)}
.scard-av.av-night    {background:linear-gradient(135deg,#7C3AED,#4C1D95)}
.scard-name{font-size:11.5px;font-weight:700;color:var(--ink);
  white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:calc(100% - 60px)}
.scard-count{margin-left:auto;flex-shrink:0;font-size:9.5px;font-weight:700;
  padding:2px 6px;border-radius:10px;background:#EFF6FF;color:#1558A8}
.scard-first{padding:0 9px 6px;font-size:10px;color:var(--muted);line-height:1.3}
.scard-first-type{font-weight:600;color:var(--ink);font-size:11px}
.scard-first-time{font-size:10px;color:var(--muted)}
.scard-status-bar{
  margin:0 9px 7px;display:flex;align-items:center;gap:4px;flex-wrap:wrap
}
.scard-dot{width:7px;height:7px;border-radius:50%;flex-shrink:0}
.scard-dot.st-ok   {background:#059669}
.scard-dot.st-warn {background:#F59E0B}
.scard-dot.st-err  {background:#DC2626}
.scard-dot.st-pend {background:#93C5FD}
.scard-status-txt{font-size:10px;font-weight:600}
/* Cancel X button hiện khi hover */
.scard-cancel-btn{
  position:absolute;top:5px;right:5px;width:16px;height:16px;border-radius:50%;
  background:rgba(220,38,38,.1);border:none;color:var(--red);font-size:9px;
  cursor:pointer;display:none;align-items:center;justify-content:center;line-height:1;
  z-index:10;
}
.staff-card:hover .scard-cancel-btn{display:flex}

/* ── Tooltip popup (hover) ── */
.scard-tooltip{
  display:none;position:absolute;z-index:500;
  left:calc(100% + 8px);top:-4px;
  background:#0B1628;color:#fff;border-radius:10px;
  padding:10px 12px;min-width:180px;max-width:220px;
  box-shadow:0 6px 24px rgba(0,0,0,.3);
  pointer-events:auto;
  font-family:'Outfit',sans-serif;
}
/* Nếu cột cuối → hiện bên trái */
.day-col:nth-child(6) .scard-tooltip,
.day-col:nth-child(7) .scard-tooltip{
  left:auto;right:calc(100% + 10px);
}
.scard-tooltip::before{
  content:'';position:absolute;top:12px;left:-5px;
  border:5px solid transparent;border-right-color:#0B1628;border-left:none;
}
.day-col:nth-child(6) .scard-tooltip::before,
.day-col:nth-child(7) .scard-tooltip::before{
  left:auto;right:-5px;
  border-right:none;border-left-color:#0B1628;
}
/* tooltip đã thay bằng inline detail panel */
.stt-name{font-size:11.5px;font-weight:700;color:#fff;margin-bottom:5px;
  padding-bottom:5px;border-bottom:1px solid rgba(255,255,255,.12)}
.stt-shift{padding:4px 0;border-bottom:1px solid rgba(255,255,255,.06)}
.stt-shift:last-child{border-bottom:none}
.stt-shift-name{font-size:10.5px;font-weight:700;color:#fff;margin-bottom:1px}
.stt-shift-time{font-size:9.5px;color:rgba(255,255,255,.6);margin-bottom:2px}
.stt-badge{display:inline-flex;align-items:center;gap:2px;font-size:9px;
  font-weight:700;padding:1px 6px;border-radius:6px;margin-top:1px}
.stt-badge.ok  {background:#D1FAE5;color:#065F46}
.stt-badge.warn{background:#FEF9C3;color:#92400E}
.stt-badge.err {background:#FEE2E2;color:#991B1B}
.stt-badge.pend{background:#DBEAFE;color:#1E40AF}
/* Action bar (nhỏ gọn bên trong tooltip) */
.stt-actions{
  display:flex;gap:4px;margin-top:6px;padding-top:6px;
  border-top:1px solid rgba(255,255,255,.1);pointer-events:auto;
}
.stt-btn{
  flex:1;padding:4px 2px;border-radius:5px;border:none;
  font-family:'Outfit',sans-serif;font-size:9.5px;font-weight:700;
  cursor:pointer;transition:all .15s;text-align:center;
}
.stt-btn:hover{opacity:.82;transform:scale(1.03)}
.stt-btn.view{background:rgba(21,88,168,.15);color:#93C5FD}
.stt-btn.edit{background:rgba(249,115,22,.15);color:#FDBA74}
.stt-btn.del {background:rgba(220,38,38,.15);color:#FCA5A5}


/* ════════════════════════════════════════════════════
   DETAIL MODAL — overlay giống modal sửa/xóa
   ════════════════════════════════════════════════════ */
.detail-overlay{display:none;position:fixed;inset:0;background:rgba(11,22,40,.5);z-index:9999;align-items:center;justify-content:center}
.detail-overlay.open{display:flex}
.detail-modal{background:var(--white);border-radius:16px;width:540px;max-width:94vw;
  box-shadow:0 24px 70px rgba(0,0,0,.22);
  transform:translateY(16px);transition:transform .22s;overflow:hidden}
.detail-overlay.open .detail-modal{transform:translateY(0)}
.sdp-header{
  background:linear-gradient(135deg,var(--navy),var(--blue));padding:16px 22px;color:#fff;
  display:flex;align-items:center;gap:12px;
}
.sdp-av{width:38px;height:38px;border-radius:10px;background:rgba(255,255,255,.15);
  display:flex;align-items:center;justify-content:center;font-size:14px;font-weight:800;color:#fff;flex-shrink:0}
.sdp-name{font-size:15px;font-weight:700}
.sdp-type{font-size:11.5px;opacity:.7;margin-top:1px}
.sdp-badge{margin-left:auto;padding:3px 10px;border-radius:14px;font-size:10.5px;font-weight:700}
.sdp-badge.ok{background:rgba(110,231,183,.2);color:#6EE7B7}
.sdp-badge.pend{background:rgba(147,197,253,.2);color:#93C5FD}
.sdp-badge.err{background:rgba(252,165,165,.2);color:#FCA5A5}
.sdp-badge.warn{background:rgba(253,224,71,.2);color:#FDE047}
.sdp-close{margin-left:8px;width:28px;height:28px;border-radius:7px;background:rgba(255,255,255,.12);
  border:none;color:#fff;font-size:13px;cursor:pointer;display:flex;align-items:center;justify-content:center}
.sdp-close:hover{background:rgba(255,255,255,.2)}
.sdp-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:8px;padding:16px 20px}
.sdp-item{background:var(--surface);border-radius:8px;padding:9px 11px}
.sdp-label{font-size:9.5px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.4px;margin-bottom:2px}
.sdp-val{font-size:13px;font-weight:600;color:var(--ink)}
/* ── Timeline ── */
.sdp-timeline-wrap{padding:14px 20px 10px}
.sdp-sec-label{font-size:10px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px}
.sdp-timeline{position:relative;height:62px;background:var(--surface);border-radius:10px;overflow:visible;padding:0 4px}
.sdp-tl-track{position:absolute;top:34px;left:0;right:0;height:3px;background:var(--border);border-radius:2px}
.sdp-tl-seg{position:absolute;height:5px;border-radius:3px;top:33px}
.sdp-tl-seg.morning{background:linear-gradient(90deg,#3B82F6,#60A5FA)}
.sdp-tl-seg.afternoon{background:linear-gradient(90deg,#F97316,#FB923C)}
.sdp-tl-seg.night{background:linear-gradient(90deg,#7C3AED,#A78BFA)}
.sdp-tl-marker{position:absolute;top:6px;transform:translateX(-50%);text-align:center}
.sdp-tl-time{font-size:12px;font-weight:700;color:var(--ink)}
.sdp-tl-label{font-size:8.5px;color:var(--muted);margin-top:1px;white-space:nowrap;max-width:60px;overflow:hidden;text-overflow:ellipsis}
.sdp-tl-dot{position:absolute;top:31px;width:11px;height:11px;border-radius:50%;border:2px solid var(--white);transform:translateX(-50%);z-index:2}
/* ── Info chips ── */
.sdp-info-row{display:flex;gap:6px;padding:4px 20px 12px;flex-wrap:wrap}
.sdp-chip{display:flex;align-items:center;gap:5px;background:var(--surface);border-radius:8px;padding:7px 11px}
.sdp-chip-icon{font-size:12px;flex-shrink:0}
.sdp-chip-val{font-size:12.5px;font-weight:600;color:var(--ink)}
.sdp-notes{padding:0 20px 12px}
.sdp-notes-box{background:#FFFBEB;border:1px solid #FDE68A;border-radius:8px;padding:9px 12px;font-size:12px;color:#78350F}
.sdp-actions{display:flex;gap:8px;padding:0 20px 16px}
.sdp-btn{flex:1;padding:9px;border-radius:8px;border:none;font-family:'Outfit',sans-serif;
  font-size:12px;font-weight:700;cursor:pointer;transition:all .18s;text-align:center}
.sdp-btn:hover{transform:translateY(-1px)}
.sdp-btn.edit{background:#EFF6FF;color:var(--blue);border:1.5px solid #BFDBFE}
.sdp-btn.edit:hover{background:#DBEAFE}
.sdp-btn.del{background:#FEF2F2;color:var(--red);border:1.5px solid #FECACA}
.sdp-btn.del:hover{background:#FEE2E2}
.sdp-btn.close-btn{background:var(--surface);color:var(--muted);border:1.5px solid var(--border)}
.sdp-btn.close-btn:hover{border-color:var(--blue);color:var(--blue)}

/* ── Mini hover tooltip (nhỏ gọn, chỉ hiện thông tin cơ bản) ── */
.scard-mini-tip{
  display:none;position:absolute;z-index:200;
  left:50%;bottom:calc(100% + 6px);transform:translateX(-50%);
  background:#0B1628;color:#fff;border-radius:8px;
  padding:7px 10px;min-width:130px;max-width:180px;
  box-shadow:0 4px 16px rgba(0,0,0,.25);pointer-events:none;
  font-family:'Outfit',sans-serif;text-align:center;white-space:nowrap;
}
.scard-mini-tip::after{
  content:'';position:absolute;top:100%;left:50%;transform:translateX(-50%);
  border:5px solid transparent;border-top-color:#0B1628;
}
.staff-card:hover .scard-mini-tip{display:block}
/* Card selected state */
.staff-card.selected{border-color:var(--blue);box-shadow:0 0 0 2px rgba(21,88,168,.2)}

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
.edit-modal-overlay{display:none;position:fixed;inset:0;background:rgba(11,22,40,.5);z-index:9999;align-items:center;justify-content:center}
.edit-modal-overlay.open{display:flex}
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
.del-modal-overlay{display:none;position:fixed;inset:0;background:rgba(11,22,40,.5);z-index:9999;align-items:center;justify-content:center}
.del-modal-overlay.open{display:flex}
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
.selmode-overlay{display:none;position:fixed;inset:0;background:rgba(11,22,40,.5);z-index:9999;align-items:center;justify-content:center}
.selmode-overlay.open{display:flex}
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

/* ── Multi-select xóa loại ca ── */
.btn-select-mode{display:inline-flex;align-items:center;gap:6px;padding:8px 16px;
  background:var(--surface);color:var(--ink);border:1.5px solid var(--border);border-radius:9px;
  font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;margin-right:8px}
.btn-select-mode.active{background:var(--blue);color:#fff;border-color:var(--blue)}
.type-card{position:relative}
.type-card-checkbox{display:none;position:absolute;top:14px;left:14px;width:20px;height:20px;
  accent-color:var(--blue);cursor:pointer;z-index:5}
.types-grid.select-mode .type-card-checkbox{display:block}
.types-grid.select-mode .type-card{padding-left:38px;transition:border-color .15s}
.types-grid.select-mode .type-card.checked{border:2px solid var(--blue);background:rgba(21,88,168,.03)}
.types-grid.select-mode .type-card-foot{pointer-events:none;opacity:.45}
.bulk-delete-bar{display:none;align-items:center;justify-content:space-between;gap:14px;
  background:#FEF2F2;border:1.5px solid #FECACA;border-radius:12px;padding:12px 18px;margin-bottom:14px}
.bulk-delete-bar.show{display:flex}
.bulk-delete-count{font-size:13px;font-weight:700;color:#991B1B}
.bulk-delete-actions{display:flex;gap:10px}
.btn-bulk-delete{background:#DC2626;color:#fff;border:none;padding:8px 18px;border-radius:9px;
  font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer}
.btn-bulk-delete:disabled{opacity:.5;cursor:not-allowed}
.btn-bulk-cancel{background:#fff;color:var(--muted);border:1.5px solid var(--border);padding:8px 18px;
  border-radius:9px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer}

/* ── POS MAP ── */
.pos-station-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(250px,1fr));gap:18px}
.pos-station-card{border-radius:18px;padding:20px;border:1.5px solid var(--border);transition:all .25s cubic-bezier(0.4, 0, 0.2, 1);position:relative;overflow:hidden;background:#fff;box-shadow:0 10px 30px rgba(21,88,168,0.02)}
.pos-station-card:hover{transform:translateY(-2px);box-shadow:0 12px 36px rgba(21,88,168,0.06)}
.pos-station-card.online{border-color:rgba(5,150,105,0.25);background:linear-gradient(180deg, #ffffff 0%, #f6fdfa 100%)}
.pos-station-card.offline{border-color:var(--border);background:linear-gradient(180deg, #ffffff 0%, #fafbfc 100%)}
.pos-station-card.offline .pos-st-number{color:var(--muted)}
.pos-st-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:14px;border-bottom:1.5px solid rgba(21,88,168,0.04);padding-bottom:12px}
.pos-station-card.online .pos-st-header{border-bottom-color:rgba(5,150,105,0.08)}
.pos-st-number{font-size:16px;font-weight:800;color:var(--navy);letter-spacing:-.3px}
.pos-station-card.online .pos-st-number{color:var(--green)}
.pos-st-dot{width:8px;height:8px;border-radius:50%;flex-shrink:0}
.pos-st-dot.online{background:#10b981;box-shadow:0 0 0 3px rgba(16,185,129,0.25);animation:posGlow 2s ease-in-out infinite}
.pos-st-dot.offline{background:#cbd5e1}
@keyframes posGlow{0%,100%{box-shadow:0 0 0 3px rgba(16,185,129,0.25)}50%{box-shadow:0 0 0 6px rgba(16,185,129,0.1)}}
.pos-st-badge{font-size:9px;font-weight:800;letter-spacing:.6px;text-transform:uppercase;padding:3px 8px;border-radius:20px}
.pos-st-badge.online{background:#ecfdf5;color:#047857;border:1px solid rgba(16,185,129,0.2)}
.pos-st-badge.offline{background:#f1f5f9;color:#64748b;border:1px solid rgba(100,116,139,0.1)}
.pos-st-staff-list{display:flex;flex-direction:column;gap:8px}
.pos-st-staff-row{display:flex;align-items:center;justify-content:space-between;padding:8px 10px;border-radius:10px;background:rgba(255,255,255,0.6);border:1.5px solid rgba(21,88,168,0.02);transition:all 0.2s;margin:0 -4px}
.pos-st-staff-row:hover{background:#fff;border-color:rgba(21,88,168,0.1);box-shadow:0 4px 12px rgba(21,88,168,0.04);transform:translateX(2px)}
.pos-st-av{width:32px;height:32px;border-radius:10px;font-size:11px;font-weight:800;color:#fff;display:flex;align-items:center;justify-content:center;flex-shrink:0}
.pos-st-av.online{background:linear-gradient(135deg,var(--blue),var(--cyan))}
.pos-st-av.offline{background:linear-gradient(135deg,var(--muted),#cbd5e1)}
.pos-st-staff-name{font-size:12.5px;font-weight:700;color:var(--ink);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.pos-st-staff-meta{font-size:10.5px;color:var(--muted);margin-top:1px}
.pos-st-empty{font-size:12px;color:var(--muted);font-style:italic;padding:12px 0;text-align:center;background:rgba(21,88,168,0.01);border:1.5px dashed rgba(21,88,168,0.06);border-radius:10px}
.pos-unassigned-list{display:flex;flex-wrap:wrap;gap:8px}
.pos-unas-chip{padding:6px 12px;border-radius:8px;background:#fff;border:1.5px solid #fde68a;font-size:12px;font-weight:600;color:#92400e;box-shadow:0 2px 6px rgba(146,64,14,0.04)}
.btn-pos-add-staff {
  padding: 5px 12px;
  border-radius: 8px;
  border: none;
  background: linear-gradient(135deg, var(--blue), var(--cyan));
  font-family: inherit;
  font-size: 11px;
  font-weight: 700;
  cursor: pointer;
  color: #fff;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  box-shadow: 0 3px 8px rgba(21, 88, 168, 0.15);
  transition: all 0.2s ease;
}
.btn-pos-add-staff:hover {
  opacity: 0.9;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(21, 88, 168, 0.25);
}
.pos-st-btn {
  border: none;
  background: transparent;
  cursor: pointer;
  font-size: 12px;
  padding: 6px;
  border-radius: 8px;
  transition: all 0.18s;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}
.pos-st-btn.edit:hover {
  background: rgba(217, 119, 6, 0.12);
  color: var(--gold);
}
.pos-st-btn.delete:hover {
  background: rgba(220, 38, 38, 0.12);
  color: var(--red);
}
</style>
</head>
<body>

<%-- ── SIDEBAR ── --%>
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">

  <%-- Toast --%>
  <c:if test="${not empty param.msg}">
    <c:choose>
      <c:when test="${param.msg == 'counter-added'}">   <div class="toast toast-ok"   id="toast">✅ Thêm quầy thành công!</div></c:when>
      <c:when test="${param.msg == 'counter-updated'}"> <div class="toast toast-ok"   id="toast">✅ Cập nhật quầy thành công!</div></c:when>
      <c:when test="${param.msg == 'counter-deleted'}"> <div class="toast toast-ok"   id="toast">🗑️ Xóa quầy thành công!</div></c:when>
      <c:when test="${param.msg == 'counter-in-use'}">  <div class="toast toast-err"  id="toast">🚫 Không thể xóa quầy — đang có nhân viên được xếp lịch/làm việc tại quầy này!</div></c:when>
      <c:when test="${param.msg == 'shift-active'}">    <div class="toast toast-err"  id="toast">🚫 Không thể xóa/hủy — nhân viên ĐANG trong ca làm việc!</div></c:when>
      <c:when test="${param.msg == 'opened'}">       <div class="toast toast-ok"   id="toast">✅ Mở ca thành công!</div></c:when>
      <c:when test="${param.msg == 'closed'}">       <div class="toast toast-ok"   id="toast">✅ Đóng ca thành công!</div></c:when>
      <c:when test="${param.msg == 'force-closed'}"> <div class="toast toast-info" id="toast">🔒 Admin đã đóng ca.</div></c:when>
      <c:when test="${param.msg == 'deleted'}">      <div class="toast toast-ok"   id="toast">🗑️ Xóa ca thành công!</div></c:when>
      <c:when test="${param.msg == 'created'}">
        <c:choose>
          <c:when test="${param.count == '0' and param.skip != '0'}">
            <div class="toast toast-warn" id="toast">⚠️ Không có ca mới — ${param.skip} ca đã tồn tại (bị bỏ qua)</div>
          </c:when>
          <c:when test="${param.count != '0' and param.skip != '0'}">
            <div class="toast toast-ok" id="toast">✅ Đã xếp ${param.count} ca mới! (bỏ qua ${param.skip} ca đã tồn tại)</div>
          </c:when>
          <c:when test="${param.count != '0'}">
            <div class="toast toast-ok" id="toast">✅ Xếp ${param.count} ca thành công!</div>
          </c:when>
          <c:otherwise>
            <div class="toast toast-ok" id="toast">✅ Xếp ca thành công!</div>
          </c:otherwise>
        </c:choose>
      </c:when>
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
      <c:when test="${param.msg == 'type-bulk-deleted'}">
        <div class="toast <c:choose><c:when test='${param.deleted > 0 and empty param.skippedActive and empty param.skippedSchedule}'>toast-ok</c:when><c:when test='${param.deleted == 0}'>toast-err</c:when><c:otherwise>toast-warn</c:otherwise></c:choose>" id="toast">
          <c:if test="${param.deleted > 0}">🗑️ Đã xóa ${param.deleted} loại ca. </c:if>
          <c:if test="${not empty param.skippedActive}">⚠️ Bỏ qua (đang dùng): ${param.skippedActive}. </c:if>
          <c:if test="${not empty param.skippedSchedule}">⚠️ Bỏ qua (còn lịch ca): ${param.skippedSchedule}.</c:if>
        </div>
      </c:when>
      <c:when test="${param.msg == 'quick-sched'}"><div class="toast toast-ok" id="toast">✅ Xếp ca nhanh thành công!</div></c:when>
      <c:when test="${param.msg == 'cancelled'}"><div class="toast toast-info" id="toast">🗑️ Đã hủy lịch ca.</div></c:when>
      <c:when test="${param.msg == 'type-saved'}">   <div class="toast toast-ok"   id="toast">✅ Lưu loại ca thành công!</div></c:when>
      <c:when test="${param.msg == 'type-deleted'}"> <div class="toast toast-ok"   id="toast">🗑️ Xóa loại ca thành công!</div></c:when>
      <c:when test="${param.msg == 'type-err'}">     <div class="toast toast-err"  id="toast">❌ Lỗi khi lưu loại ca!</div></c:when>
      <c:when test="${param.msg == 'type-err-name'}"> <div class="toast toast-err"  id="toast">⚠️ Bạn chưa nhập tên loại ca!</div></c:when>
      <c:when test="${param.msg == 'type-err-time'}"> <div class="toast toast-err"  id="toast">⚠️ Vui lòng chọn đầy đủ giờ bắt đầu và kết thúc!</div></c:when>
      <c:when test="${param.msg == 'type-err-rate'}"> <div class="toast toast-err"  id="toast">⚠️ Lương theo giờ phải từ 50,000đ trở lên!</div></c:when>
      <c:when test="${param.msg == 'past-date'}"><div class="toast toast-err" id="toast">⛔ Không thể xếp ca cho ngày đã qua! Chỉ được xếp từ hôm nay trở đi.</div></c:when>
      <c:when test="${param.msg == 'type-has-schedules'}"><div class="toast toast-err" id="toast">⚠️ Không thể xóa — loại ca này còn lịch ca đang dùng!</div></c:when>
      <c:when test="${param.msg == 'type-has-schedules'}"><div class="toast toast-err" id="toast">⚠️ Không thể xóa — loại ca này còn lịch ca đang dùng!</div></c:when>
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
      <a href="${pageContext.request.contextPath}/admin-profile" class="topbar-user">
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
      <%-- Tab "💰 Doanh thu" đã được chuyển hẳn sang trang Báo cáo (/reports) — xem report-list.jsp --%>
      <button class="tab-btn <%= "types".equals(activeTab) ? "active" : "" %>"    onclick="switchTab('types',this)">⚙️ Loại ca</button>
      <button class="tab-btn <%= "leave".equals(activeTab) ? "active" : "" %>"    onclick="switchTab('leave',this)">
        🏖️ Nghỉ phép
        <c:if test="${pendingLeaveCount > 0}">
          <span style="background:#DC2626;color:#fff;font-size:10px;font-weight:800;
                       padding:1px 6px;border-radius:10px;margin-left:4px">${pendingLeaveCount}</span>
        </c:if>
      </button>
      <button class="tab-btn <%= "pos-map".equals(activeTab) ? "active" : "" %>" onclick="switchTab('pos-map',this)">🖥️ Sơ đồ quầy POS</button>
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
        <span class="week-sub">click = xem chi tiết + sửa/xóa • ✕ để hủy nhanh</span>
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

      <%-- 7-day GROUPED STAFF GRID
           Mỗi nhân viên/ngày = 1 card compact.
           Hover = tooltip đầy đủ tất cả ca + R/E/D actions.
      --%>
      <div class="week-grid">
        <c:forEach begin="0" end="6" var="i">
          <c:set var="dayDate" value="${weekDays[i]}"/>
          <c:set var="isToday" value="${dayDate.equals(today)}"/>
          <c:set var="isPastDay" value="${dayDate.isBefore(today)}"/>
            <div class="day-col ${isToday ? 'today-col' : ''} ${isPastDay ? 'past-col' : ''}">
            <div class="day-head">
              <div class="day-name">${weekDayNames[i]}</div>
              <div class="day-date">${dayDate.dayOfMonth}</div>
              <div style="font-size:9px;color:var(--muted)">${dayDate.monthValue}/${dayDate.year}</div>
            </div>
            <div class="day-body">
              <%
                /* ── Group schedules theo accountId cho ngày này (Java scriptlet)
                   Dùng LinkedHashMap giữ thứ tự insert (ca sớm nhất của mỗi NV).
                   key = accountId, value = List<ShiftSchedule>
                   schedules đã ORDER BY PlannedStart ASC từ DAO.               */
                java.util.List<com.medicare.entity.ShiftSchedule> allSched =
                    (java.util.List<com.medicare.entity.ShiftSchedule>) request.getAttribute("schedules");
                java.time.LocalDate curDate =
                    (java.time.LocalDate) pageContext.getAttribute("dayDate");

                java.util.LinkedHashMap<Integer, java.util.List<com.medicare.entity.ShiftSchedule>> byStaff =
                    new java.util.LinkedHashMap<>();

                if (allSched != null && curDate != null) {
                    for (com.medicare.entity.ShiftSchedule sc : allSched) {
                        if (!curDate.equals(sc.getWorkDate())) continue;
                        byStaff.computeIfAbsent(sc.getAccountId(),
                            k -> new java.util.ArrayList<>()).add(sc);
                    }
                }
                pageContext.setAttribute("staffGroupDay", byStaff);
                pageContext.setAttribute("hasAnyShift", !byStaff.isEmpty());
              %>

              <c:choose>
                <c:when test="${empty staffGroupDay}">
                  <div class="empty-day">Trống</div>
                </c:when>
                <c:otherwise>
                  <%-- Lặp qua từng nhóm NV (đã gom bởi Java scriptlet) --%>
                  <c:forEach var="entry" items="${staffGroupDay}">
                    <%
                      /* Lấy list ca của NV này trong ngày — đã sắp xếp theo giờ */
                      @SuppressWarnings("unchecked")
                      java.util.Map.Entry<Integer,
                        java.util.List<com.medicare.entity.ShiftSchedule>> grpEntry =
                            (java.util.Map.Entry<Integer,
                              java.util.List<com.medicare.entity.ShiftSchedule>>)
                              pageContext.getAttribute("entry");

                      java.util.List<com.medicare.entity.ShiftSchedule> grpList = grpEntry.getValue();
                      com.medicare.entity.ShiftSchedule firstSc = grpList.get(0);
                      int totalShifts = grpList.size();

                      /* Avatar class theo ca đầu tiên trong ngày */
                      String avClass = firstSc.getStartHour() < 12 ? "av-morning"
                                     : firstSc.getStartHour() < 20 ? "av-afternoon" : "av-night";
                      /* Initials từ staffName */
                      String sn = firstSc.getStaffName() != null ? firstSc.getStaffName() : "?";
                      String ini = sn.length() >= 2
                          ? ("" + sn.charAt(0)).toUpperCase()
                          : sn.substring(0,1).toUpperCase();
                      /* Lấy chữ cái họ và tên — ví dụ "Le Thi Tu Van" → "LV" */
                      String[] parts = sn.trim().split("\\s+");
                      if (parts.length >= 2)
                          ini = ("" + parts[0].charAt(0) + parts[parts.length-1].charAt(0)).toUpperCase();

                      /* Giờ ca đầu tiên (hiển thị trên card) */
                      String firstTime = "";
                      if (firstSc.getPlannedStart() != null) {
                          java.time.LocalDateTime ps = firstSc.getPlannedStart();
                          java.time.LocalDateTime pe = firstSc.getPlannedEnd();
                          firstTime = String.format("%02d:%02d", ps.getHour(), ps.getMinute());
                          if (pe != null)
                              firstTime += " → " + String.format("%02d:%02d", pe.getHour(), pe.getMinute());
                      }

                      /* Status tổng của card (worst-case: Vắng > Chưa vào > OK) */
                      boolean anyAbsent   = grpList.stream().anyMatch(s -> "ABSENT".equals(s.getStatus()));
                      boolean allConfirmed= grpList.stream().allMatch(s -> "CONFIRMED".equals(s.getStatus()));
                      boolean anyScheduled= grpList.stream().anyMatch(s -> "SCHEDULED".equals(s.getStatus()) || "LEAVE_PENDING".equals(s.getStatus()));
                      String dotClass = anyAbsent ? "st-err" : allConfirmed ? "st-ok" : anyScheduled ? "st-pend" : "st-warn";
                      String dotLabel = anyAbsent ? "Có ca vắng"
                                      : allConfirmed ? "Đã check-in"
                                      : anyScheduled ? "Chưa vào" : "Đang làm";

                      /* Có ca nào có thể hủy không */
                      boolean hasCancellable = grpList.stream().anyMatch(s ->
                          "SCHEDULED".equals(s.getStatus()) || "LEAVE_PENDING".equals(s.getStatus()));
                      int firstCancellableId = grpList.stream()
                          .filter(s -> "SCHEDULED".equals(s.getStatus()) || "LEAVE_PENDING".equals(s.getStatus()))
                          .mapToInt(com.medicare.entity.ShiftSchedule::getScheduleId)
                          .findFirst().orElse(0);

                      pageContext.setAttribute("grpList",   grpList);
                      pageContext.setAttribute("firstSc",   firstSc);
                      pageContext.setAttribute("avClass",   avClass);
                      pageContext.setAttribute("ini",       ini);
                      pageContext.setAttribute("firstTime", firstTime);
                      pageContext.setAttribute("totalShifts", totalShifts);
                      pageContext.setAttribute("dotClass",  dotClass);
                      pageContext.setAttribute("dotLabel",  dotLabel);
                      pageContext.setAttribute("hasCancellable", hasCancellable);
                      pageContext.setAttribute("firstCancelId", firstCancellableId);
                    %>

                    <%-- ── STAFF CARD ── --%>
                    <div class="staff-card"
                         data-sched-id="${firstSc.scheduleId}"
                         data-staff-name="${fn:escapeXml(firstSc.staffName)}"
                         data-shift-type="${fn:escapeXml(firstSc.shiftTypeName)}"
                         data-shift-type-id="${firstSc.shiftTypeId}"
                         data-status="${firstSc.status}"
                         data-work-date="${firstSc.workDate}" data-is-past="${dayDate.isBefore(today)}"
                         data-late-tol="${firstSc.lateToleranceMinutes}"
                         data-notes="${fn:escapeXml(firstSc.notes)}"
                         data-pos-station="${firstSc.posStation}"
                         data-total="${totalShifts}"
                         data-planned-start="${not empty firstSc.plannedStart ? fn:substring(firstSc.plannedStart.toString(),11,16) : ''}"
                         data-planned-end="${not empty firstSc.plannedEnd ? fn:substring(firstSc.plannedEnd.toString(),11,16) : ''}"
                         data-shifts-json='<%
                           StringBuilder sjb = new StringBuilder("[");
                           boolean sfirst = true;
                           for (com.medicare.entity.ShiftSchedule ss : grpList) {
                               if (!sfirst) sjb.append(",");
                               sfirst = false;
                               sjb.append("{");
                               sjb.append("\"id\":").append(ss.getScheduleId()).append(",");
                               sjb.append("\"type\":\"").append(ss.getShiftTypeName() != null ? ss.getShiftTypeName().replace("\"","") : "").append("\",");
                               sjb.append("\"typeId\":").append(ss.getShiftTypeId()).append(",");
                               sjb.append("\"status\":\"").append(ss.getStatus() != null ? ss.getStatus() : "").append("\",");
                               sjb.append("\"late\":").append(ss.getLateToleranceMinutes()).append(",");
                               String noteVal = ss.getNotes() != null ? ss.getNotes().replace("\"","\\\"").replace("'","") : "";
                               sjb.append("\"notes\":\"").append(noteVal).append("\",");
                               String ps = ss.getPlannedStart() != null ? ss.getPlannedStart().toString().substring(11,16) : "";
                               String pe = ss.getPlannedEnd() != null ? ss.getPlannedEnd().toString().substring(11,16) : "";
                               sjb.append("\"start\":\"").append(ps).append("\",");
                               sjb.append("\"end\":\"").append(pe).append("\"");
                               sjb.append("}");
                           }
                           sjb.append("]");
                           out.print(sjb.toString());
                         %>'
                         onclick="showDetailPanel(this)">



                      <%-- Header: avatar + tên + badge số ca --%>
                      <div class="staff-card-head">
                        <div class="scard-av ${avClass}">${ini}</div>
                        <div class="scard-name">${firstSc.staffName}</div>
                        <c:if test="${totalShifts > 1}">
                          <span class="scard-count">${totalShifts} ca</span>
                        </c:if>
                      </div>

                      <%-- Tất cả ca trong ngày (compact) --%>
                      <div class="scard-first">
                        <c:forEach var="grpSc" items="${grpList}" varStatus="gs">
                          <div style="display:flex;align-items:center;gap:5px;${gs.index > 0 ? 'margin-top:3px;padding-top:3px;border-top:1px dashed rgba(0,0,0,.06)' : ''}">
                            <span style="width:6px;height:6px;border-radius:50%;flex-shrink:0;background:${grpSc.startHour < 12 ? '#3B82F6' : grpSc.startHour < 20 ? '#F97316' : '#7C3AED'}"></span>
                            <span class="scard-first-type" style="font-size:11px">${grpSc.shiftTypeName}</span>
                            <c:if test="${not empty grpSc.plannedStart}">
                              <span class="scard-first-time">${fn:substring(grpSc.plannedStart.toString(),11,16)} → ${fn:substring(grpSc.plannedEnd.toString(),11,16)}</span>
                            </c:if>
                          </div>
                        </c:forEach>
                      </div>

                      <%-- Status dot --%>
                      <div class="scard-status-bar">
                        <span class="scard-dot ${dotClass}"></span>
                        <span class="scard-status-txt"
                          style="color:${dotClass == 'st-ok' ? '#059669' : dotClass == 'st-err' ? '#DC2626' : dotClass == 'st-pend' ? '#1558A8' : '#D97706'}">
                          ${dotLabel}
                        </span>
                      </div>

<%-- Mini tooltip hover --%>
                      <div class="scard-mini-tip">
                        <div style="font-size:10.5px;font-weight:700">${firstSc.shiftTypeName}</div>
                        <c:if test="${not empty firstSc.plannedStart}">
                          <div style="font-size:9.5px;color:rgba(255,255,255,.65);margin-top:2px">
                            ${fn:substring(firstSc.plannedStart.toString(),11,16)} → ${fn:substring(firstSc.plannedEnd.toString(),11,16)}
                          </div>
                        </c:if>
                        <c:if test="${totalShifts > 1}">
                          <div style="font-size:9px;color:#93C5FD;margin-top:2px">${totalShifts} ca trong ngày</div>
                        </c:if>
                      </div>

                    </div><%-- end staff-card --%>
                  </c:forEach>
                </c:otherwise>
              </c:choose>

              <c:if test="${!dayDate.isBefore(today)}">
                <button type="button" onclick="(function(d){var m=document.getElementById('fullSchedModal');if(!m)return;document.querySelectorAll('#fullStaffChips input,#fullStypeCards input').forEach(function(c){c.checked=false;});var f=document.getElementById('fsDateFrom');if(f)f.value=d;var t=document.getElementById('fsDateTo');if(t)t.value='';if(typeof updateFullPreview==='function')updateFullPreview();m.classList.add('open');m.style.display='flex';}('${dayDate}'))" class="day-add">＋ Thêm ca</button>
              </c:if>
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
                        <div class="staff-name">${not empty staff ? staff.fullName : 'ID ' += s.accountId}</div>
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


    <%-- ════════════════════════════════
         TAB 3: LOẠI CA
         ════════════════════════════════ --%>
    <div id="tab-types" class="tab-pane <%= "types".equals(activeTab) ? "active" : "" %>">
      <div class="types-header">
        <div>
          <h2>⚙️ Loại ca làm việc</h2>
          <p style="font-size:12.5px;color:var(--muted);margin-top:4px">Quản lý ca mẫu — Ca sáng, Ca chiều, Ca part-time...</p>
        </div>
        <div>
          <button class="btn-select-mode" id="typeSelectModeBtn" onclick="toggleTypeSelectMode()">☑️ Chọn</button>
          <button class="btn-add-type" onclick="openTypeModal()">+ Thêm loại ca</button>
        </div>
      </div>

      <div class="bulk-delete-bar" id="typeBulkDeleteBar">
        <span class="bulk-delete-count" id="typeBulkDeleteCount">Đã chọn 0 loại ca</span>
        <div class="bulk-delete-actions">
          <button class="btn-bulk-cancel" onclick="cancelTypeSelectMode()">Hủy</button>
          <button class="btn-bulk-delete" id="typeBulkDeleteBtn" disabled onclick="submitBulkDeleteTypes()">🗑 Xóa các loại ca đã chọn</button>
        </div>
      </div>

      <div class="types-grid" id="typesGrid">
        <c:if test="${empty shiftTypes}">
          <div class="empty-state" style="grid-column:1/-1">
            <span class="es-icon">⚙️</span>
            <h3>Chưa có loại ca nào</h3>
            <p>Tạo loại ca đầu tiên để bắt đầu xếp lịch</p>
          </div>
        </c:if>
        <c:forEach var="st" items="${shiftTypes}">
          <div class="type-card" data-type-id="${st.shiftTypeId}" onclick="onTypeCardClick(event, ${st.shiftTypeId})">
            <input type="checkbox" class="type-card-checkbox" data-type-id="${st.shiftTypeId}"
                   data-type-name="${st.name}"
                   onclick="event.stopPropagation(); onTypeCheckboxChange(${st.shiftTypeId})">
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

    <%-- ══════════════════════════════════════════════
         TAB: SƠ ĐỒ QUẦY POS
         ══════════════════════════════════════════════ --%>
    <div id="tab-pos-map" class="tab-pane <%= "pos-map".equals(activeTab) ? "active" : "" %>">
      
      <!-- Hướng dẫn CRUD Sơ đồ quầy POS -->
      <div class="pos-guide-card" style="margin-bottom:20px; background:var(--white); border:1px solid var(--border); border-radius:var(--radius); overflow:hidden; box-shadow:0 4px 16px rgba(21,88,168,0.03);">
        <div class="pos-guide-header" onclick="togglePosGuide()" style="padding:14px 20px; background:linear-gradient(135deg,rgba(21,88,168,0.05),rgba(58,189,224,0.05)); display:flex; align-items:center; justify-content:space-between; cursor:pointer; user-select:none;">
          <div style="display:flex; align-items:center; gap:10px;">
            <span style="font-size:18px;">💡</span>
            <span style="font-weight:700; color:var(--navy); font-size:14px; font-family:'Outfit',sans-serif;">Hướng Dẫn Thao Tác Ca & Quầy POS (C-R-U-D)</span>
          </div>
          <span id="posGuideIcon" style="font-size:12px; color:var(--muted); transition:transform 0.2s;">▼</span>
        </div>
        <div id="posGuideBody" style="padding:18px 20px; border-top:1px solid var(--border); display:none; flex-direction:column; gap:14px;">
          <div style="display:grid; grid-template-columns:repeat(auto-fit,minmax(200px,1fr)); gap:16px;">
            <div style="background:rgba(21,88,168,0.02); border:1px solid var(--border); border-radius:10px; padding:12px 14px;">
              <div style="font-weight:800; color:var(--blue); font-size:12px; margin-bottom:6px; display:flex; align-items:center; gap:6px;">
                <span style="width:20px; height:20px; border-radius:50%; background:var(--blue); color:#fff; display:inline-flex; align-items:center; justify-content:center; font-size:10px;">C</span>
                CREATE (Thêm ca / quầy)
              </div>
              <p style="font-size:11.5px; color:var(--muted); line-height:1.4;">Nhấn nút <strong style="color:var(--blue);">➕ Thêm NV</strong> ở mỗi thẻ Quầy. Bạn có thể xếp ca mới hoặc chọn nhanh từ danh sách ca chưa chia quầy hôm nay.</p>
            </div>
            
            <div style="background:rgba(5,150,105,0.02); border:1px solid var(--border); border-radius:10px; padding:12px 14px;">
              <div style="font-weight:800; color:var(--green); font-size:12px; margin-bottom:6px; display:flex; align-items:center; gap:6px;">
                <span style="width:20px; height:20px; border-radius:50%; background:var(--green); color:#fff; display:inline-flex; align-items:center; justify-content:center; font-size:10px;">R</span>
                READ (Xem thông tin)
              </div>
              <p style="font-size:11.5px; color:var(--muted); line-height:1.4;">Theo dõi thời gian thực kết nối mạng (<b>Online/Offline</b>) của từng quầy. Xem danh sách nhân viên, loại ca, giờ làm và trạng thái check-in.</p>
            </div>
            
            <div style="background:rgba(217,119,6,0.02); border:1px solid var(--border); border-radius:10px; padding:12px 14px;">
              <div style="font-weight:800; color:var(--gold); font-size:12px; margin-bottom:6px; display:flex; align-items:center; gap:6px;">
                <span style="width:20px; height:20px; border-radius:50%; background:var(--gold); color:#fff; display:inline-flex; align-items:center; justify-content:center; font-size:10px;">U</span>
                UPDATE (Sửa phân công)
              </div>
              <p style="font-size:11.5px; color:var(--muted); line-height:1.4;">Nhấn biểu tượng bút chì <strong style="color:var(--gold);">✏️</strong> ở dòng nhân viên để đổi Quầy làm việc, đổi Loại ca, chỉnh giờ trễ cho phép hoặc viết ghi chú.</p>
            </div>
            
            <div style="background:rgba(220,38,38,0.02); border:1px solid var(--border); border-radius:10px; padding:12px 14px;">
              <div style="font-weight:800; color:var(--red); font-size:12px; margin-bottom:6px; display:flex; align-items:center; gap:6px;">
                <span style="width:20px; height:20px; border-radius:50%; background:var(--red); color:#fff; display:inline-flex; align-items:center; justify-content:center; font-size:10px;">D</span>
                DELETE (Gỡ / Hủy ca)
              </div>
              <p style="font-size:11.5px; color:var(--muted); line-height:1.4;">Nhấn nút thùng rác <strong style="color:var(--red);">🗑️</strong> bên cạnh nhân viên để gỡ khỏi quầy hoặc hủy lịch ca/xóa vĩnh viễn lịch làm việc.</p>
            </div>
          </div>
        </div>
      </div>

      <div class="table-card">
        <div class="table-card-head" style="justify-content:space-between">
          <div>
            <h2>🖥️ Sơ đồ quầy POS hôm nay</h2>
            <div class="table-card-sub" id="posMapDate">—</div>
          </div>
          <div style="display:flex;align-items:center;gap:10px">
            <div style="display:flex;align-items:center;gap:6px;font-size:12px;color:var(--muted)">
              <span style="width:10px;height:10px;border-radius:50%;background:linear-gradient(135deg,#059669,#10b981);display:inline-block"></span>Online
              <span style="width:10px;height:10px;border-radius:50%;background:#CBD5E1;display:inline-block;margin-left:8px"></span>Offline
            </div>
            <button onclick="openPosManagerModal()" style="padding:6px 14px;border-radius:8px;border:1px solid var(--border);background:var(--white);font-size:12px;font-weight:600;cursor:pointer;color:var(--blue);display:inline-flex;align-items:center;gap:4px">🖥️ Quản lý quầy</button>
            <button onclick="refreshPosMap()" style="padding:6px 14px;border-radius:8px;border:1px solid var(--border);background:var(--white);font-size:12px;font-weight:600;cursor:pointer;color:var(--blue)">↻ Làm mới</button>
          </div>
        </div>
        <div style="padding:20px">
          <div class="pos-station-grid" id="posStationGrid">
            <%-- render bằng JS --%>
          </div>
          <div id="posUnassigned" style="margin-top:18px;display:none">
            <div style="font-size:12px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.8px;margin-bottom:8px">Chưa gán quầy hôm nay</div>
            <div class="pos-unassigned-list" id="posUnassignedList"></div>
          </div>
        </div>
      </div>
    </div><%-- end tab-pos-map --%>

  </div><%-- end content --%>
</div><%-- end main --%>

<%-- ══════════════════════════════════════
     MODAL POS 4: Quản lý Quầy POS (CRUD)
     ══════════════════════════════════════ --%>
<div class="modal-overlay" id="posManagerModal">
  <div class="modal" style="max-width: 600px;">
    <div class="modal-head">
      <span class="modal-title">🖥️ Quản lý danh sách quầy POS</span>
      <button class="modal-close" onclick="closePosManagerModal()">✕</button>
    </div>
    <div class="modal-body">
      <!-- Form thêm quầy mới -->
      <form id="posCounterAddForm" method="post" action="${pageContext.request.contextPath}/shifts" style="margin-bottom: 20px; background: var(--surface); padding: 14px; border-radius: 10px; border: 1.5px solid var(--border);">
        <input type="hidden" name="action" value="pos-counter-add">
        <div style="display: flex; gap: 10px; align-items: flex-end;">
          <div style="flex: 1; display: flex; flex-direction: column; gap: 4px;">
            <label style="font-size: 10px; font-weight: 700; color: var(--muted); text-transform: uppercase; letter-spacing: .5px;">Tên quầy mới</label>
            <input type="text" name="stationName" placeholder="Ví dụ: Quầy số 6" required style="border: 1.5px solid var(--border); border-radius: 8px; padding: 7px 10px; font-family: inherit; font-size: 13px; background: #fff; outline: none; height: 36px; width: 100%; box-sizing: border-box;">
          </div>
          <button type="submit" class="btn-save-m" style="height: 36px; padding: 0 16px; border-radius: 8px;">➕ Thêm quầy</button>
        </div>
      </form>

      <!-- Danh sách quầy hiện tại -->
      <div style="max-height: 300px; overflow-y: auto;">
        <table style="width: 100%; border-collapse: collapse; font-size: 13px;">
          <thead>
            <tr>
              <th style="padding: 8px; text-align: left; background: var(--surface); font-weight: 700; border-bottom: 1.5px solid var(--border);">Mã</th>
              <th style="padding: 8px; text-align: left; background: var(--surface); font-weight: 700; border-bottom: 1.5px solid var(--border);">Tên Quầy</th>
              <th style="padding: 8px; text-align: center; background: var(--surface); font-weight: 700; border-bottom: 1.5px solid var(--border); width: 120px;">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <c:forEach var="ps" items="${posStations}">
              <tr style="border-bottom: 1px solid var(--border);">
                <td style="padding: 10px 8px; font-weight: 600; color: var(--muted);">#${ps.posStationId}</td>
                <td style="padding: 10px 8px;">
                  <span id="lblStation-${ps.posStationId}" style="font-weight: 700; color: var(--navy);">${fn:escapeXml(ps.stationName)}</span>
                  <form id="editForm-${ps.posStationId}" method="post" action="${pageContext.request.contextPath}/shifts" style="display: none; margin: 0;">
                    <input type="hidden" name="action" value="pos-counter-update">
                    <input type="hidden" name="posStationId" value="${ps.posStationId}">
                    <input type="text" name="stationName" value="${fn:escapeXml(ps.stationName)}" required style="border: 1.5px solid var(--blue); border-radius: 6px; padding: 4px 8px; font-size: 13px; font-family: inherit; width: 100%; box-sizing: border-box;">
                  </form>
                </td>
                <td style="padding: 10px 8px; text-align: center;">
                  <div style="display: flex; gap: 4px; justify-content: center; align-items: center;">
                    <!-- Edit Button -->
                    <button id="btnEdit-${ps.posStationId}" onclick="showEditCounterRow(${ps.posStationId})" style="border: none; background: transparent; cursor: pointer; font-size: 13px; padding: 4px 8px; border-radius: 6px; color: var(--gold);" title="Sửa tên">✏️</button>
                    <button id="btnSave-${ps.posStationId}" onclick="submitEditCounterRow(${ps.posStationId})" style="display: none; border: none; background: var(--green); color: #fff; cursor: pointer; font-size: 11px; font-weight: 700; padding: 4px 8px; border-radius: 6px;" title="Lưu">Lưu</button>
                    <button id="btnCancel-${ps.posStationId}" onclick="hideEditCounterRow(${ps.posStationId})" style="display: none; border: 1px solid var(--border); background: #fff; cursor: pointer; font-size: 11px; font-weight: 700; padding: 4px 8px; border-radius: 6px; color: var(--muted);" title="Hủy">Hủy</button>

                    <!-- Delete Form -->
                    <form method="post" action="${pageContext.request.contextPath}/shifts" style="margin:0;" onsubmit="return confirm('Bạn có chắc chắn muốn xóa ${fn:escapeXml(ps.stationName)}?\nLưu ý: Các ca làm việc đang gán vào quầy này sẽ trở thành Chưa gán quầy.')">
                      <input type="hidden" name="action" value="pos-counter-delete">
                      <input type="hidden" name="posStationId" value="${ps.posStationId}">
                      <button type="submit" style="border: none; background: transparent; cursor: pointer; font-size: 13px; padding: 4px 8px; border-radius: 6px; color: var(--red);" title="Xóa quầy">🗑️</button>
                    </form>
                  </div>
                </td>
              </tr>
            </c:forEach>
            <c:if test="${empty posStations}">
              <tr>
                <td colspan="3" style="padding: 20px; text-align: center; color: var(--muted);">Chưa có quầy POS nào.</td>
              </tr>
            </c:if>
          </tbody>
        </table>
      </div>
    </div>
    <div class="modal-foot">
      <button class="btn-cancel-m" onclick="closePosManagerModal()" style="width: 100%;">Đóng</button>
    </div>
  </div>
</div>

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
                <input type="checkbox" name="accountId" value="${staff.accountId}">
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
            <input type="date" name="dateFrom" id="schedFrom" required onchange="updateSchedPreview()" min="${today}">
          </div>
          <div class="mfg">
            <label>Đến ngày</label>
            <input type="date" name="dateTo" id="schedTo" onchange="updateSchedPreview()" min="${today}">
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
            <div class="time24-wrap">
              <select class="time24-sel" id="typeStartH" onchange="syncTime('start')" title="Giờ (00–23)"></select>
              <span class="time24-colon">:</span>
              <select class="time24-sel" id="typeStartM" onchange="syncTime('start')" title="Phút"></select>
            </div>
            <input type="hidden" name="startTime" id="typeStartTime" value="06:00">
          </div>
          <div class="mfg">
            <label>Giờ kết thúc *</label>
            <div class="time24-wrap">
              <select class="time24-sel" id="typeEndH" onchange="syncTime('end')" title="Giờ (00–23)"></select>
              <span class="time24-colon">:</span>
              <select class="time24-sel" id="typeEndM" onchange="syncTime('end')" title="Phút"></select>
            </div>
            <input type="hidden" name="endTime" id="typeEndTime" value="14:00">
          </div>
        </div>
        <div id="durPreview" class="dur-preview"></div>
        <div id="durWarn" class="dur-warn" style="display:none"></div>
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
  </div><%-- end .modal --%>
</div><%-- end #typeModal .modal-overlay --%>

<!-- ==========================================
     MODAL POS 1: Xếp lịch & Gán quầy POS (Create)
     ========================================== -->
<div class="modal-overlay" id="posAddStaffModal">
  <div class="modal" style="max-width: 500px;">
    <div class="modal-head">
      <span class="modal-title" id="posAddTitle">➕ Xếp nhân viên vào Quầy</span>
      <button class="modal-close" onclick="closePosAddModal()">✕</button>
    </div>
    <div class="modal-body">
      <form id="posAddForm" method="post" action="${pageContext.request.contextPath}/shifts">
        <input type="hidden" name="action" value="pos-assign">
        <input type="hidden" name="posStation" id="posAddStationNum">
        <input type="hidden" name="tab" value="pos-map">

        <!-- Lựa chọn phương thức -->
        <div class="mfg">
          <label style="font-weight:700;">Phương thức thêm</label>
          <div style="display:flex; gap:10px; margin-top:6px;">
            <label style="flex:1; display:flex; align-items:center; gap:8px; padding:10px; border:1.5px solid var(--border); border-radius:8px; cursor:pointer;" id="lblOptAssign">
              <input type="radio" name="addOption" value="assign" checked onclick="toggleAddOption('assign')">
              <div style="font-size:12px; font-weight:600;">Gán ca có sẵn</div>
            </label>
            <label style="flex:1; display:flex; align-items:center; gap:8px; padding:10px; border:1.5px solid var(--border); border-radius:8px; cursor:pointer;" id="lblOptCreate">
              <input type="radio" name="addOption" value="create" onclick="toggleAddOption('create')">
              <div style="font-size:12px; font-weight:600;">Xếp ca mới</div>
            </label>
          </div>
        </div>

        <!-- Option 1: Gán từ ca chưa chia quầy hôm nay -->
        <div id="secOptAssign" class="mfg">
          <label>Chọn ca làm việc hôm nay <span style="color:var(--red)">*</span></label>
          <select name="scheduleId" id="posAddScheduleSelect" style="width:100%; padding:8px 12px; border:1.5px solid var(--border); border-radius:8px; font-family:'Outfit',sans-serif; font-size:13px; margin-top:6px;">
            <!-- populate bằng JS -->
          </select>
          <div id="posAddUnassignedEmpty" style="font-size:12.5px; color:var(--gold); display:none; margin-top:6px; background:#FFFBEB; padding:8px 12px; border-radius:8px; border:1px solid #FDE68A;">
            ⚠️ Hôm nay không có ca làm việc nào chưa gán quầy. Vui lòng chuyển sang tab "Xếp ca mới" bên cạnh để tạo ca.
          </div>
        </div>

        <!-- Option 2: Tạo ca mới hôm nay & gán quầy -->
        <div id="secOptCreate" class="mfg" style="display:none;">
          <div class="mfg" style="margin-bottom:12px;">
            <label>Chọn nhân viên <span style="color:var(--red)">*</span></label>
            <select name="accountId" style="width:100%; padding:8px 12px; border:1.5px solid var(--border); border-radius:8px; font-family:'Outfit',sans-serif; font-size:13px; margin-top:6px;">
              <option value="">-- Chọn nhân viên --</option>
              <c:forEach var="s" items="${allStaff}">
                <option value="${s.accountId}">${not empty s.fullName ? s.fullName : s.username} (#${s.accountId} - ${s.roleId==2?'Dược sĩ':'Thủ kho'})</option>
              </c:forEach>
            </select>
          </div>
          <div class="mfg">
            <label>Chọn loại ca <span style="color:var(--red)">*</span></label>
            <select name="shiftTypeId" style="width:100%; padding:8px 12px; border:1.5px solid var(--border); border-radius:8px; font-family:'Outfit',sans-serif; font-size:13px; margin-top:6px;">
              <option value="">-- Chọn loại ca --</option>
              <c:forEach var="st" items="${shiftTypes}">
                <c:if test="${st.active}">
                  <option value="${st.shiftTypeId}">${st.name} (${st.startHour}:${st.startMinute<10?'0':''}${st.startMinute} - ${st.endHour}:${st.endMinute<10?'0':''}${st.endMinute})</option>
                </c:if>
              </c:forEach>
            </select>
          </div>
        </div>
      </form>
    </div>
    <div class="modal-foot">
      <button class="btn-cancel-m" onclick="closePosAddModal()">Hủy</button>
      <button class="btn-save-m" onclick="submitPosAddForm()" style="background:var(--blue); color:#fff; border:none;">💾 Lưu phân công</button>
    </div>
  </div>
</div>

<!-- ==========================================
     MODAL POS 2: Sửa phân công (Update)
     ========================================== -->
<div class="modal-overlay" id="posEditStaffModal">
  <div class="modal" style="max-width: 500px;">
    <div class="modal-head">
      <span class="modal-title">✏️ Sửa phân công Quầy POS</span>
      <button class="modal-close" onclick="closePosEditModal()">✕</button>
    </div>
    <div class="modal-body">
      <form id="posEditForm" method="post" action="${pageContext.request.contextPath}/shifts">
        <input type="hidden" name="action" value="schedule-update">
        <input type="hidden" name="scheduleId" id="posEditScheduleId">
        <input type="hidden" name="tab" value="pos-map">

        <div class="mfg" style="margin-bottom:12px;">
          <label>Nhân viên</label>
          <input type="text" id="posEditStaffName" readonly style="width:100%; padding:8px 12px; border:1.5px solid var(--border); border-radius:8px; background:var(--surface); font-family:'Outfit',sans-serif; font-size:13px; color:var(--ink); font-weight:600; margin-top:6px;">
        </div>

        <div class="mfg" style="margin-bottom:12px;">
          <label>Quầy làm việc</label>
          <select name="posStation" id="posEditStationSelect" style="width:100%; padding:8px 12px; border:1.5px solid var(--border); border-radius:8px; font-family:'Outfit',sans-serif; font-size:13px; margin-top:6px;">
            <option value="0">-- Chưa gán quầy --</option>
            <c:forEach var="ps" items="${posStations}">
              <option value="${ps.posStationId}">${fn:escapeXml(ps.stationName)}</option>
            </c:forEach>
          </select>
        </div>

        <div class="mfg" style="margin-bottom:12px;">
          <label>Loại ca</label>
          <select name="shiftTypeId" id="posEditShiftTypeSelect" style="width:100%; padding:8px 12px; border:1.5px solid var(--border); border-radius:8px; font-family:'Outfit',sans-serif; font-size:13px; margin-top:6px;">
            <c:forEach var="st" items="${shiftTypes}">
              <c:if test="${st.active}">
                <option value="${st.shiftTypeId}">${st.name} (${st.startHour}:${st.startMinute<10?'0':''}${st.startMinute} - ${st.endHour}:${st.endMinute<10?'0':''}${st.endMinute})</option>
              </c:if>
            </c:forEach>
          </select>
        </div>

        <div class="mfg-row" style="margin-bottom:12px;">
          <div class="mfg" style="flex:1;">
            <label>Phút trễ cho phép</label>
            <input type="number" name="lateToleranceMinutes" id="posEditLateTol" min="0" max="60" style="width:100%; padding:8px 12px; border:1.5px solid var(--border); border-radius:8px; font-family:'Outfit',sans-serif; font-size:13px; margin-top:6px;">
          </div>
        </div>

        <div class="mfg">
          <label>Ghi chú</label>
          <textarea name="notes" id="posEditNotes" rows="2" style="width:100%; padding:8px 12px; border:1.5px solid var(--border); border-radius:8px; font-family:'Outfit',sans-serif; font-size:13px; margin-top:6px; resize:vertical;"></textarea>
        </div>
      </form>
    </div>
    <div class="modal-foot">
      <button class="btn-cancel-m" onclick="closePosEditModal()">Hủy</button>
      <button class="btn-save-m" onclick="submitPosEditForm()" style="background:var(--blue); color:#fff; border:none;">💾 Lưu thay đổi</button>
    </div>
  </div>
</div>

<!-- ==========================================
     MODAL POS 3: Gỡ / Hủy / Xóa ca (Delete Options)
     ========================================== -->
<div class="modal-overlay" id="posDeleteModal">
  <div class="modal" style="max-width: 460px;">
    <div class="modal-head" style="border-bottom:none; padding-bottom:0;">
      <span class="modal-title" style="color:var(--red); font-size:16px;">⚠️ Chọn thao tác gỡ/xóa nhân viên</span>
      <button class="modal-close" onclick="closePosDeleteModal()">✕</button>
    </div>
    <div class="modal-body" style="padding-top:10px;">
      <div style="font-size:13px; color:var(--ink); font-weight:600; margin-bottom:16px;">
        Hệ thống hỗ trợ các hình thức gỡ bỏ nhân viên <span id="posDeleteStaffName" style="color:var(--blue);"></span> khỏi quầy làm việc hôm nay:
      </div>
      
      <div style="display:flex; flex-direction:column; gap:12px;">
        <!-- Option 1: Unassign -->
        <form method="post" action="${pageContext.request.contextPath}/shifts" style="margin:0;">
          <input type="hidden" name="action" value="pos-unassign">
          <input type="hidden" name="scheduleId" class="posDeleteScheduleId">
          <button type="submit" style="width:100%; display:flex; align-items:flex-start; gap:10px; padding:12px; border:1.5px solid var(--border); border-radius:10px; background:#fff; text-align:left; cursor:pointer; transition:all 0.2s;" onmouseover="this.style.borderColor='var(--blue)'; this.style.background='rgba(21,88,168,0.02)'" onmouseout="this.style.borderColor='var(--border)'; this.style.background='#fff'">
            <span style="font-size:18px; line-height:1;">🔄</span>
            <div>
              <div style="font-weight:700; color:var(--blue); font-size:13px;">Gỡ nhân viên khỏi quầy</div>
              <div style="font-size:11px; color:var(--muted); margin-top:2px;">Vẫn giữ ca làm việc hôm nay của nhân viên nhưng đưa về trạng thái "Chưa gán quầy".</div>
            </div>
          </button>
        </form>

        <!-- Option 2: Cancel -->
        <form method="post" action="${pageContext.request.contextPath}/shifts" style="margin:0;">
          <input type="hidden" name="action" value="schedule-delete-staff">
          <input type="hidden" name="mode" value="cancel">
          <input type="hidden" name="tab" value="pos-map">
          <input type="hidden" name="scheduleId" class="posDeleteScheduleId">
          <button type="submit" style="width:100%; display:flex; align-items:flex-start; gap:10px; padding:12px; border:1.5px solid var(--border); border-radius:10px; background:#fff; text-align:left; cursor:pointer; transition:all 0.2s;" onmouseover="this.style.borderColor='var(--gold)'; this.style.background='rgba(217,119,6,0.02)'" onmouseout="this.style.borderColor='var(--border)'; this.style.background='#fff'">
            <span style="font-size:18px; line-height:1;">🚫</span>
            <div>
              <div style="font-weight:700; color:var(--gold); font-size:13px;">Hủy lịch ca (Cancel)</div>
              <div style="font-size:11px; color:var(--muted); margin-top:2px;">Chuyển ca làm việc của nhân viên thành trạng thái "Đã hủy" (vẫn lưu vết lịch sử).</div>
            </div>
          </button>
        </form>

        <!-- Option 3: Delete -->
        <form method="post" action="${pageContext.request.contextPath}/shifts" style="margin:0;">
          <input type="hidden" name="action" value="schedule-delete-staff">
          <input type="hidden" name="mode" value="delete">
          <input type="hidden" name="tab" value="pos-map">
          <input type="hidden" name="scheduleId" class="posDeleteScheduleId">
          <button type="submit" style="width:100%; display:flex; align-items:flex-start; gap:10px; padding:12px; border:1.5px solid var(--border); border-radius:10px; background:#fff; text-align:left; cursor:pointer; transition:all 0.2s;" onmouseover="this.style.borderColor='var(--red)'; this.style.background='rgba(220,38,38,0.02)'" onmouseout="this.style.borderColor='var(--border)'; this.style.background='#fff'">
            <span style="font-size:18px; line-height:1;">🗑️</span>
            <div>
              <div style="font-weight:700; color:var(--red); font-size:13px;">Xóa vĩnh viễn ca</div>
              <div style="font-size:11px; color:var(--muted); margin-top:2px;">Xóa hoàn toàn lịch ca khỏi cơ sở dữ liệu. Lưu ý: Chỉ thực hiện được nếu nhân viên chưa check-in.</div>
            </div>
          </button>
        </form>
      </div>
    </div>
    <div class="modal-foot" style="border-top:none; padding-top:0;">
      <button class="btn-cancel-m" onclick="closePosDeleteModal()" style="width:100%;">Quay lại</button>
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
              <input type="date" name="dateFrom" id="fsDateFrom"
                     onchange="clearFsErr('errDateFrom','fsDateFrom');updateFullPreview()" min="${today}">
              <span class="field-err" id="errDateFrom"></span>
            </div>
            <div class="date-sep">→</div>
            <div class="sched-fi">
              <label>Đến ngày</label>
              <input type="date" name="dateTo" id="fsDateTo"
                     onchange="clearFsErr('errDateTo','fsDateTo');updateFullPreview()" min="${today}">
              <span class="field-err" id="errDateTo"></span>
              <span style="font-size:11px;color:var(--muted);margin-top:2px">Để trống = chỉ 1 ngày</span>
            </div>
          </div>
        </div>

        <%-- Quầy POS --%>
        <div class="sched-section">
          <div class="sched-section-title">🖥️ Quầy POS <span style="color:var(--red)">*</span></div>
          <div class="sched-fi">
            <select name="posStation" id="fsPosStation"
                    style="width:100%;max-width:240px;padding:8px 10px;border:1.5px solid var(--border);border-radius:8px;font-size:13px;font-family:inherit;color:var(--navy);background:#fff"
                    onchange="clearFsErr('errPosStation','fsPosStation')">
              <option value="0">— Chưa gán quầy —</option>
              <c:forEach var="ps" items="${posStations}">
                <option value="${ps.posStationId}">🖥️ ${fn:escapeXml(ps.stationName)}</option>
              </c:forEach>
            </select>
            <span class="field-err" id="errPosStation"></span>
            <span style="font-size:11px;color:var(--muted);margin-top:4px;display:block">Nhân viên sẽ làm tại quầy POS này trong ca</span>
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
     MODAL THÊM 1 CA NHANH cho 1 ngày (bấm "+ Thêm ca" ở ô ngày)
     POST /shifts?action=schedule-bulk (1 NV × 1 loại ca × 1 ngày)
     ════════════════════════════════════════════════════ --%>
<div class="edit-modal-overlay" id="quickShiftModal">
  <div class="edit-modal">
    <div class="em-head">
      <span class="em-title" id="quickShiftTitle">➕ Thêm ca làm mới</span>
      <button class="em-close" onclick="closeQuickShift()">✕</button>
    </div>
    <div class="em-body">
      <form id="quickShiftForm" method="post" action="${pageContext.request.contextPath}/shifts">
        <input type="hidden" name="action" value="schedule-bulk">
        <input type="hidden" name="dateFrom" id="qsDate">

        <div class="em-fg" style="margin-bottom:12px">
          <label>Nhân viên <span style="color:var(--red)">*</span></label>
          <select name="accountId" id="qsStaff" required
                  style="width:100%;padding:9px 11px;border:1.5px solid var(--border);border-radius:8px;font-size:13px;font-family:inherit;color:var(--navy);background:#fff">
            <option value="">— Chọn nhân viên —</option>
            <c:forEach var="s" items="${allStaff}">
              <option value="${s.accountId}">${not empty s.fullName ? s.fullName : s.username} · ${s.roleId==2?'Dược sĩ':'Thủ kho'}</option>
            </c:forEach>
          </select>
        </div>

        <div class="em-fg" style="margin-bottom:12px">
          <label>Loại ca <span style="color:var(--red)">*</span></label>
          <select name="shiftTypeId" id="qsType" required
                  style="width:100%;padding:9px 11px;border:1.5px solid var(--border);border-radius:8px;font-size:13px;font-family:inherit;color:var(--navy);background:#fff">
            <option value="">— Chọn loại ca —</option>
            <c:forEach var="st" items="${shiftTypes}">
              <c:if test="${st.active}">
                <option value="${st.shiftTypeId}">${st.name} (${st.startHour}:${st.startMinute<10?'0':''}${st.startMinute}–${st.endHour}:${st.endMinute<10?'0':''}${st.endMinute})</option>
              </c:if>
            </c:forEach>
          </select>
        </div>

        <div class="em-fg" style="margin-bottom:12px">
          <label>Quầy POS <span style="color:var(--muted);font-weight:400">(tùy chọn)</span></label>
          <select name="posStation" id="qsPos"
                  style="width:100%;padding:9px 11px;border:1.5px solid var(--border);border-radius:8px;font-size:13px;font-family:inherit;color:var(--navy);background:#fff">
            <option value="0">— Chưa gán quầy —</option>
            <c:forEach var="ps" items="${posStations}">
              <option value="${ps.posStationId}">🖥️ ${fn:escapeXml(ps.stationName)}</option>
            </c:forEach>
          </select>
        </div>

        <div class="em-fg">
          <label>Ghi chú <span style="color:var(--muted);font-weight:400">(tùy chọn)</span></label>
          <textarea name="note" rows="2" placeholder="Ghi chú cho ca này..."
                    style="width:100%;padding:9px 11px;border:1.5px solid var(--border);border-radius:8px;font-size:13px;font-family:inherit;resize:vertical"></textarea>
        </div>
      </form>
    </div>
    <div class="em-foot" style="display:flex;gap:10px;padding:14px 20px;border-top:1px solid var(--border)">
      <button type="button" onclick="closeQuickShift()" style="flex:1;padding:10px;background:#f1f5f9;color:#475569;border:none;border-radius:9px;font-weight:700;cursor:pointer;font-family:inherit">Hủy</button>
      <button type="button" onclick="submitQuickShift()" style="flex:2;padding:10px;background:linear-gradient(135deg,var(--blue),var(--cyan));color:#fff;border:none;border-radius:9px;font-weight:800;cursor:pointer;font-family:inherit">✓ Thêm ca</button>
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

        <%-- Quầy POS --%>
        <div class="em-fg" style="margin-bottom:12px">
          <label>🖥️ Làm tại quầy POS</label>
          <select name="posStation" id="editPosStation">
            <option value="0">— Chưa gán quầy —</option>
            <c:forEach var="ps" items="${posStations}">
              <option value="${ps.posStationId}">${fn:escapeXml(ps.stationName)}</option>
            </c:forEach>
          </select>
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
                  <c:set var="isEditable" value="${(sc.status == 'SCHEDULED' or sc.status == 'LEAVE_PENDING' or sc.status == 'CONFIRMED') and !sc.workDate.isBefore(today)}"/>
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
                       data-pos-station="${sc.posStation}"
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
        <a href="${pageContext.request.contextPath}/shifts?tab=list&delMonth=${prevDelMonth}" class="btn-nav" style="font-size:12px;padding:4px 10px">‹</a>
        <span style="font-size:13px;font-weight:700;color:var(--ink)">📅 ${delMonthLabel}</span>
        <a href="${pageContext.request.contextPath}/shifts?tab=list&delMonth=${nextDelMonth}" class="btn-nav" style="font-size:12px;padding:4px 10px">›</a>
      </div>
      
      <%-- Lưới lịch tháng (7 cột) --%>
      <div style="display:grid;grid-template-columns:repeat(7, 1fr);gap:6px;border:1px solid var(--border);border-radius:12px;overflow:hidden;background:var(--surface)">
        <%-- Header (T2 - CN) --%>
        <c:forEach var="dn" items="${weekDayNames}">
          <div style="text-align:center;padding:8px 0;font-size:11px;font-weight:700;color:var(--muted);background:#F8FAFC;border-bottom:1px solid var(--border)">
            ${dn}
          </div>
        </c:forEach>
        
        <%-- Các ô ngày --%>
        <c:forEach var="dayDate" items="${monthDays}">
          <c:set var="isToday" value="${dayDate.equals(today)}"/>
          <c:set var="isCurrentMonth" value="${fn:startsWith(dayDate.toString(), delMonth)}"/>
          <div style="min-height:90px;background:#fff;padding:6px;display:flex;flex-direction:column;gap:4px;border-right:1px solid var(--border);border-bottom:1px solid var(--border);opacity:${isCurrentMonth ? '1' : '0.5'};${isToday ? 'background:#F0FDF4' : ''}">
            <div style="font-size:11px;font-weight:${isToday ? '800' : '600'};color:${isToday ? 'var(--green)' : 'var(--ink)'};text-align:right;margin-bottom:4px">
              ${dayDate.dayOfMonth}
            </div>
            
            <c:forEach var="sc" items="${monthSchedules}">
              <c:if test="${sc.workDate.equals(dayDate)}">
                <c:set var="isDeletable" value="${(sc.status == 'SCHEDULED' or sc.status == 'LEAVE_PENDING' or sc.status == 'CANCELLED') and !sc.workDate.isBefore(today)}"/>
                <c:set var="smChipClass2">sm-chip <c:choose>
                  <c:when test="${sc.startHour < 12}">sm-morning</c:when>
                  <c:when test="${sc.startHour < 20}">sm-afternoon</c:when>
                  <c:otherwise>sm-night</c:otherwise>
                </c:choose> ${!isDeletable ? 'sm-locked' : ''}</c:set>
                
                <div class="${smChipClass2}"
                     id="del-chip-${sc.scheduleId}"
                     data-sched-id="${sc.scheduleId}"
                     data-deletable="${isDeletable}"
                     onclick="toggleDelChip(this)"
                     style="padding:4px;font-size:9.5px;border-radius:6px;margin-bottom:2px">
                  <div class="sm-chip-name" style="font-size:10px">${sc.staffName}</div>
                  <div style="font-size:8.5px;opacity:0.8">${sc.shiftTypeName}</div>
                  <c:if test="${!isDeletable}">
                    <div style="font-size:8px;color:#991B1B;margin-top:2px">🔒 KHÓA</div>
                  </c:if>
                </div>
              </c:if>
            </c:forEach>
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

<%-- ══ DETAIL MODAL OVERLAY — redesigned UX ══ --%>
<div class="detail-overlay" id="detailOverlay" onclick="if(event.target===this)closeDetailPanel()">
  <div class="detail-modal">

    <%-- ── Header ── --%>
    <div class="sdp-header">
      <div class="sdp-av" id="sdpAv">?</div>
      <div style="flex:1;min-width:0">
        <div class="sdp-name" id="sdpName">—</div>
        <div style="display:flex;align-items:center;gap:8px;margin-top:3px;flex-wrap:wrap">
          <span style="font-size:11.5px;opacity:.7" id="sdpDate">—</span>
          <span style="font-size:10px;opacity:.4">•</span>
          <span class="sdp-badge pend" id="sdpBadge">—</span>
        </div>
      </div>
      <button class="sdp-close" onclick="closeDetailPanel()" title="Đóng">✕</button>
    </div>

    <%-- ── Timeline thời gian làm việc ── --%>
    <div class="sdp-timeline-wrap">
      <div class="sdp-sec-label">Thời gian làm việc</div>
      <div class="sdp-timeline" id="sdpTimeline"></div>
    </div>

    <%-- ── Info chips (gọn, dễ scan) ── --%>
    <div class="sdp-info-row">
      <div class="sdp-chip" id="sdpChipId"><span class="sdp-chip-icon">#</span><span class="sdp-chip-val" id="sdpId">—</span></div>
      <div class="sdp-chip" id="sdpChipType"><span class="sdp-chip-icon">📋</span><span class="sdp-chip-val" id="sdpShiftType">—</span></div>
      <div class="sdp-chip" id="sdpChipLate"><span class="sdp-chip-icon">⏱</span><span class="sdp-chip-val" id="sdpLate">—</span></div>
      <div class="sdp-chip" id="sdpChipTotal"><span class="sdp-chip-icon">📊</span><span class="sdp-chip-val" id="sdpTotal">—</span></div>
      <div class="sdp-chip" id="sdpChipPos"><span class="sdp-chip-icon">🖥️</span><span class="sdp-chip-val" id="sdpPos">—</span></div>
    </div>

    <%-- ── Notes ── --%>
    <div class="sdp-notes" id="sdpNotesWrap" style="display:none">
      <div class="sdp-notes-box" id="sdpNotes"></div>
    </div>

    <%-- ── Actions ── --%>
    <div class="sdp-actions" id="sdpActions">
      <button class="sdp-btn edit" id="sdpEditBtn" onclick="editFromPanel()">✏️ Sửa ca</button>
      <button class="sdp-btn del" id="sdpDelBtn" onclick="deleteFromPanel()">🗑 Hủy ca</button>
      <button class="sdp-btn close-btn" onclick="closeDetailPanel()">✕ Đóng</button>
    </div>
  </div>
</div>

<%-- ══ SAFETY FUNCTIONS — defined before main script; main script overrides with full versions if it loads ══ --%>
<script id="safetyFns">
function openFullSchedModal(preDate, preAccountId) {
  var today = new Date().toISOString().split('T')[0];
  var m = document.getElementById('fullSchedModal');
  if (!m) return;
  var f = document.getElementById('fsDateFrom'); if (f) f.value = preDate || today;
  var t = document.getElementById('fsDateTo');   if (t) t.value = '';
  document.querySelectorAll('#fullStaffChips input,#fullStypeCards input').forEach(function(c){c.checked=false;});
  if (preAccountId) { var cb=document.querySelector('#fullStaffChips input[value="'+preAccountId+'"]'); if(cb)cb.checked=true; }
  m.classList.add('open'); m.style.display='flex';
}
function closeFullSchedModal()  { var m=document.getElementById('fullSchedModal');    if(m){m.classList.remove('open');m.style.display='';} }
function openSchedModal(d,id)   { openFullSchedModal(d,id); }
function openSchedModalForDay(d,id){ openFullSchedModal(d,id); }
function closeSchedModal()      { var m=document.getElementById('schedModal');         if(m){m.classList.remove('open');m.style.display='';} }
function openEditSelectModal()  { var m=document.getElementById('editSelectModal');    if(m){m.classList.add('open');m.style.display='flex';} }
function closeEditSelectModal() { var m=document.getElementById('editSelectModal');    if(m){m.classList.remove('open');m.style.display='';} }
function openDeleteSelectModal(){ var m=document.getElementById('deleteSelectModal');  if(m){m.classList.add('open');m.style.display='flex';} }
function closeDeleteSelectModal(){ var m=document.getElementById('deleteSelectModal'); if(m){m.classList.remove('open');m.style.display='';} }
function closeDetailPanel()     { var m=document.getElementById('detailOverlay');      if(m){m.classList.remove('open');m.style.display='';} }
function closeEditModal()       { var m=document.getElementById('editSchedModal');     if(m){m.classList.remove('open');m.style.display='';} }
function closeDeleteModal()     { var m=document.getElementById('deleteStaffModal');   if(m){m.classList.remove('open');m.style.display='';} }
function closeQuickShift()      { var m=document.getElementById('quickShiftModal');    if(m){m.classList.remove('open');m.style.display='';} }
function closeTypeModal()       { var m=document.getElementById('typeModal');          if(m){m.classList.remove('open');m.style.display='';} }
function switchTab(tab, btn) {
  document.querySelectorAll('.tab-pane').forEach(function(p){p.classList.remove('active');});
  document.querySelectorAll('.tab-btn').forEach(function(b){b.classList.remove('active');});
  var tp=document.getElementById('tab-'+tab); if(tp)tp.classList.add('active');
  if(btn)btn.classList.add('active');
}
</script>
<%-- POS data block in its own <script> — isolated so a data syntax error can't kill the main functions --%>
<script>
var _posCtx = '${pageContext.request.contextPath}';
var _todaySchedules = <%
  StringBuilder _tsb = new StringBuilder("[");
  java.util.List<com.medicare.entity.ShiftSchedule> _todayList =
      (java.util.List<com.medicare.entity.ShiftSchedule>) request.getAttribute("todaySchedules");
  if (_todayList != null) {
    boolean _fts = true;
    for (com.medicare.entity.ShiftSchedule _ts : _todayList) {
      if (!_fts) _tsb.append(",");
      _fts = false;
      String _sn = _ts.getStaffName()    != null ? _ts.getStaffName().replace("\\","\\\\").replace("'","\\'").replace("\n","\\n").replace("\r","") : "";
      String _sp = _ts.getShiftTypeName()!= null ? _ts.getShiftTypeName().replace("\\","\\\\").replace("'","\\'").replace("\n","\\n").replace("\r","") : "";
      String _ss = _ts.getStatus()       != null ? _ts.getStatus() : "";
      String _sn2= _ts.getNotes()        != null ? _ts.getNotes().replace("\\","\\\\").replace("'","\\'").replace("\n","\\n").replace("\r","") : "";
      _tsb.append("{")
          .append("scheduleId:").append(_ts.getScheduleId()).append(",")
          .append("staffName:'").append(_sn).append("',")
          .append("posStation:").append(_ts.getPosStation()).append(",")
          .append("status:'").append(_ss).append("',")
          .append("shiftType:'").append(_sp).append("',")
          .append("startHour:").append(_ts.getStartHour()).append(",")
          .append("endHour:").append(_ts.getEndHour()).append(",")
          .append("shiftTypeId:").append(_ts.getShiftTypeId()).append(",")
          .append("lateToleranceMinutes:").append(_ts.getLateToleranceMinutes()).append(",")
          .append("notes:'").append(_sn2).append("'")
          .append("}");
    }
  }
  _tsb.append("]");
  out.print(_tsb.toString());
%>;
var _posStations = <%
  StringBuilder _psb = new StringBuilder("[");
  java.util.List<com.medicare.entity.PosStation> _psList =
      (java.util.List<com.medicare.entity.PosStation>) request.getAttribute("posStations");
  if (_psList != null) {
    boolean _fps = true;
    for (com.medicare.entity.PosStation _ps : _psList) {
      if (!_fps) _psb.append(",");
      _fps = false;
      String _pn = _ps.getStationName() != null ? _ps.getStationName().replace("\\","\\\\").replace("'","\\'").replace("\n","\\n").replace("\r","") : "";
      _psb.append("{id:").append(_ps.getPosStationId()).append(",name:'").append(_pn).append("'}");
    }
  }
  _psb.append("]");
  out.print(_psb.toString());
%>;
</script>

<script>
const ctx_path = '${pageContext.request.contextPath}';
console.log('[MediVault] Main script block loaded OK — ctx_path=' + ctx_path);

// ── Tab switching ─────────────────────────────────
function switchTab(tab, btn) {
  document.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
  document.getElementById('tab-' + tab).classList.add('active');
  if (btn) btn.classList.add('active');
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
  const sm = document.getElementById('schedModal');
  if (sm) { sm.classList.add('open'); sm.style.display = 'flex'; }
}
function openSchedModalForDay(date, accountId) {
  const today = new Date().toISOString().split('T')[0];
  if (date && date < today) {
    alert('⛔ Không thể xếp ca cho ngày ' + date + ' — ngày này đã qua!');
    return;
  }
  openSchedModal(date, accountId);
}
function closeSchedModal() {
  const sm = document.getElementById('schedModal');
  if (sm) { sm.classList.remove('open'); sm.style.display = ''; }
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
  const schedFromVal = document.getElementById('schedFrom').value; // name=dateFrom
  const todayStr = new Date().toISOString().split('T')[0];
  if (schedFromVal && schedFromVal < todayStr) {
    alert('⛔ Không thể xếp ca cho ngày đã qua!');
    return;
  }
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

// ── 24h time-picker helpers ──
(function buildTimeSelects() {
  ['Start','End'].forEach(which => {
    const hSel = document.getElementById('type' + which + 'H');
    const mSel = document.getElementById('type' + which + 'M');
    if (!hSel || !mSel) return;
    for (let h = 0; h < 24; h++) {
      const opt = document.createElement('option');
      opt.value = String(h).padStart(2,'0');
      opt.textContent = String(h).padStart(2,'0');
      hSel.appendChild(opt);
    }
    for (let m = 0; m < 60; m += 5) {
      const opt = document.createElement('option');
      opt.value = String(m).padStart(2,'0');
      opt.textContent = String(m).padStart(2,'0');
      mSel.appendChild(opt);
    }
  });
  setTime24('Start', '06:00');
  setTime24('End',   '14:00');
})();

function setTime24(which, hhmm) {
  const parts = (hhmm || '00:00').split(':');
  const h = String(parseInt(parts[0]||0)).padStart(2,'0');
  const rawM = parseInt(parts[1]||0);
  const m = String(Math.round(rawM / 5) * 5 % 60).padStart(2,'0');
  const hSel = document.getElementById('type' + which + 'H');
  const mSel = document.getElementById('type' + which + 'M');
  if (hSel) hSel.value = h;
  if (mSel) mSel.value = m;
  const hidden = document.getElementById('type' + which + 'Time');
  if (hidden) hidden.value = h + ':' + m;
}

function syncTime(which) {
  const cap   = which === 'start' ? 'Start' : 'End';
  const h     = document.getElementById('type' + cap + 'H').value;
  const m     = document.getElementById('type' + cap + 'M').value;
  const hidden = document.getElementById('type' + cap + 'Time');
  if (hidden) hidden.value = h + ':' + m;
  updateDurPreview();
}

function openTypeModal() {
  document.getElementById('modalTitle').textContent = 'Thêm loại ca mới';
  document.getElementById('typeAction').value = 'create';
  document.getElementById('editTypeId').value = '';
  document.getElementById('typeForm').reset();
  setTime24('Start', '06:00');
  setTime24('End',   '14:00');
  document.getElementById('typeRate').value = '60000';
  updateDurPreview();
  const tm1 = document.getElementById('typeModal');
  if (tm1) { tm1.classList.add('open'); tm1.style.display = 'flex'; }
}
function editType(id, name, sh, sm, eh, em, rate, allow) {
  document.getElementById('modalTitle').textContent = 'Sửa loại ca';
  document.getElementById('typeAction').value = 'update';
  document.getElementById('editTypeId').value = id;
  document.getElementById('typeName').value   = name;
  setTime24('Start', String(sh).padStart(2,'0')+':'+String(sm).padStart(2,'0'));
  setTime24('End',   String(eh).padStart(2,'0')+':'+String(em).padStart(2,'0'));
  document.getElementById('typeRate').value      = rate;
  document.getElementById('typeAllowance').value = allow;
  updateDurPreview();
  const tm2 = document.getElementById('typeModal');
  if (tm2) { tm2.classList.add('open'); tm2.style.display = 'flex'; }
}
function closeTypeModal() {
  const tm = document.getElementById('typeModal');
  if (tm) { tm.classList.remove('open'); tm.style.display = ''; }
}
document.getElementById('typeModal').addEventListener('click', function(e) {
  if (e.target === this) closeTypeModal();
});
function updateDurPreview() {
  const s = document.getElementById('typeStartTime').value;
  const e = document.getElementById('typeEndTime').value;
  const p = document.getElementById('durPreview');
  const warnEl = document.getElementById('durWarn');
  if (!s || !e) { p.textContent = ''; if (warnEl) warnEl.style.display = 'none'; return; }
  const sh = parseInt(s.split(':')[0]), sm = parseInt(s.split(':')[1]);
  const eh = parseInt(e.split(':')[0]), em = parseInt(e.split(':')[1]);
  let dur = (eh * 60 + em - sh * 60 - sm) / 60;
  if (dur <= 0) dur += 24; // ca qua đêm (VD: 22:00 → 06:00)
  const rate = parseInt(document.getElementById('typeRate').value) || 60000;
  const total = Math.round(dur * rate);

  const MAX_SAFE_HOURS = 10; // chuẩn an toàn theo luật lao động VN thông thường
  const isTooLong = dur > MAX_SAFE_HOURS;

  const caType = isTooLong ? '🔴 Vượt ngưỡng an toàn' : dur >= 8 ? '🔵 Ca tiêu chuẩn' : '🟢 Part-time';
  const startLabel = String(sh).padStart(2,'0') + ':' + String(sm).padStart(2,'0');
  const endLabel   = String(eh).padStart(2,'0') + ':' + String(em).padStart(2,'0');
  const crossDay   = (eh * 60 + em) <= (sh * 60 + sm) ? ' (qua ngày sau)' : '';
  p.innerHTML = caType + ' &nbsp;|&nbsp; 🕐 ' + startLabel + ' → ' + endLabel + crossDay
              + ' &nbsp;|&nbsp; ⏱ ' + dur.toFixed(1) + ' tiếng &nbsp;|&nbsp; 💰 Tổng lương: <strong>' + total.toLocaleString('vi') + 'đ</strong>';
  p.style.color = isTooLong ? '#DC2626' : '';
  p.style.fontWeight = isTooLong ? '700' : '';

  if (warnEl) {
    if (isTooLong) {
      warnEl.style.display = 'block';
      warnEl.textContent = '🔴 Cảnh báo: ca dài ' + dur.toFixed(1) + ' tiếng — vượt quá ' + MAX_SAFE_HOURS + ' tiếng/ca theo chuẩn an toàn lao động. Vui lòng kiểm tra lại giờ bắt đầu/kết thúc, hoặc tự chịu trách nhiệm nếu chủ ý tạo ca đặc biệt dài.';
    } else {
      warnEl.style.display = 'none';
    }
  }
}
// typeRate still needs the listener; typeStartTime/typeEndTime are now hidden (selects handle syncTime)
['typeStartH','typeStartM','typeEndH','typeEndM','typeRate'].forEach(id => {
  const el = document.getElementById(id);
  if (el) el.addEventListener('change', updateDurPreview);
});
function validateRate(el) {
  const err = document.getElementById('rateErr');
  if (parseInt(el.value) < 50000) { err.style.display='block'; el.style.borderColor='var(--red)'; }
  else { err.style.display='none'; el.style.borderColor=''; }
  updateDurPreview();
}
function submitTypeForm() {
  const nameEl = document.getElementById('typeName');
  if (!nameEl.value || !nameEl.value.trim()) {
    alert('⚠️ Vui lòng nhập tên loại ca!');
    nameEl.focus();
    return;
  }
  const startEl = document.getElementById('typeStartTime');
  const endEl   = document.getElementById('typeEndTime');
  if (!startEl.value || !endEl.value) {
    alert('⚠️ Vui lòng chọn đầy đủ giờ bắt đầu và giờ kết thúc!');
    return;
  }
  const rate = parseInt(document.getElementById('typeRate').value);
  if (isNaN(rate) || rate < 50000) { validateRate(document.getElementById('typeRate')); return; }
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
//  MULTI-SELECT XÓA LOẠI CA
// ══════════════════════════════════════════════════
let _typeSelectMode = false;
let _selectedTypeIds = new Set();

function toggleTypeSelectMode() {
  _typeSelectMode = !_typeSelectMode;
  const grid = document.getElementById('typesGrid');
  const btn  = document.getElementById('typeSelectModeBtn');
  const bar  = document.getElementById('typeBulkDeleteBar');

  if (_typeSelectMode) {
    grid.classList.add('select-mode');
    btn.classList.add('active');
    btn.textContent = '✕ Thoát chọn';
    bar.classList.add('show');
  } else {
    cancelTypeSelectMode();
  }
}

function cancelTypeSelectMode() {
  _typeSelectMode = false;
  _selectedTypeIds.clear();
  const grid = document.getElementById('typesGrid');
  grid.classList.remove('select-mode');
  document.getElementById('typeSelectModeBtn').classList.remove('active');
  document.getElementById('typeSelectModeBtn').textContent = '☑️ Chọn';
  document.getElementById('typeBulkDeleteBar').classList.remove('show');
  grid.querySelectorAll('.type-card-checkbox').forEach(cb => cb.checked = false);
  grid.querySelectorAll('.type-card.checked').forEach(c => c.classList.remove('checked'));
  updateTypeBulkDeleteBar();
}

function onTypeCardClick(evt, id) {
  if (!_typeSelectMode) return; // không ở chế độ chọn → click card vẫn để Sửa/Tạm dừng hoạt động bình thường
  const checkbox = document.querySelector('.type-card-checkbox[data-type-id="'+id+'"]');
  if (checkbox) { checkbox.checked = !checkbox.checked; onTypeCheckboxChange(id); }
}

function onTypeCheckboxChange(id) {
  const checkbox = document.querySelector('.type-card-checkbox[data-type-id="'+id+'"]');
  const card = document.querySelector('.type-card[data-type-id="'+id+'"]');
  if (!checkbox) return;
  if (checkbox.checked) { _selectedTypeIds.add(id); card?.classList.add('checked'); }
  else { _selectedTypeIds.delete(id); card?.classList.remove('checked'); }
  updateTypeBulkDeleteBar();
}

function updateTypeBulkDeleteBar() {
  const count = _selectedTypeIds.size;
  document.getElementById('typeBulkDeleteCount').textContent = 'Đã chọn ' + count + ' loại ca';
  document.getElementById('typeBulkDeleteBtn').disabled = count === 0;
}

function submitBulkDeleteTypes() {
  if (_selectedTypeIds.size === 0) return;
  const names = [..._selectedTypeIds].map(id => {
    const cb = document.querySelector('.type-card-checkbox[data-type-id="'+id+'"]');
    return cb ? cb.dataset.typeName : id;
  }).join(', ');

  if (!confirm('Xóa ' + _selectedTypeIds.size + ' loại ca đã chọn?\n(' + names + ')\n\nChỉ xóa được các loại ca đang Tạm dừng và không còn lịch ca nào dùng. Loại ca đang Dùng hoặc còn lịch sẽ tự động bỏ qua.')) return;

  const f = document.createElement('form');
  f.method = 'post';
  f.action = ctx_path + '/shift-types';
  f.innerHTML = '<input name="action" value="bulk-delete">'
              + '<input name="ids" value="' + [..._selectedTypeIds].join(',') + '">';
  document.body.appendChild(f);
  f.submit();
}

// ── Hủy lịch ca từ week grid ─────────────────────────────────────────────

// ════════════════════════════════════════════════════════
//  INLINE DETAIL PANEL — click card → hiện panel chi tiết
// ════════════════════════════════════════════════════════
let _activeCard = null;  // card đang được chọn
let _activeSchedId = null;
let _activeShiftTypeId = null;
let _activeLateTol = null;
let _activeNotes = null;
let _activeStaffName = null;
let _activeWorkDate = null;
let _activeStatus = null;
let _activePosStation = 0;

function showDetailPanel(cardEl) {
  try {
  if (_activeCard) _activeCard.classList.remove('selected');
  if (_activeCard === cardEl) { closeDetailPanel(); return; }

  _activeCard = cardEl;
  cardEl.classList.add('selected');

  // Đọc data
  _activeSchedId     = cardEl.dataset.schedId;
  _activeShiftTypeId = cardEl.dataset.shiftTypeId;
  _activeLateTol     = cardEl.dataset.lateTol || '10';
  _activeNotes       = cardEl.dataset.notes;
  _activeStaffName   = cardEl.dataset.staffName;
  _activeWorkDate    = cardEl.dataset.workDate;
  _activeStatus      = cardEl.dataset.status;
  _activePosStation  = cardEl.dataset.posStation || 0;
  const total        = cardEl.dataset.total;

  // Parse all shifts JSON
  let shifts = [];
  try { shifts = JSON.parse(cardEl.dataset.shiftsJson || '[]'); } catch(e) {}
  const firstShift = shifts[0] || {};

  // Initials
  const parts = _activeStaffName.trim().split(/\s+/);
  const ini = parts.length >= 2
    ? (parts[0][0] + parts[parts.length-1][0]).toUpperCase()
    : _activeStaffName.substring(0,2).toUpperCase();

  // ── Header ──
  document.getElementById('sdpAv').textContent   = ini;
  document.getElementById('sdpName').textContent  = _activeStaffName;
  document.getElementById('sdpDate').textContent  = formatDate(_activeWorkDate);

  // Status badge
  const badge = document.getElementById('sdpBadge');
  const statusMap = {
    SCHEDULED:     { cls:'pend', label:'⏳ Chưa vào' },
    CONFIRMED:     { cls:'ok',   label:'✅ Đã check-in' },
    ABSENT:        { cls:'err',  label:'❌ Vắng mặt' },
    ON_LEAVE:      { cls:'warn', label:'🏖️ Nghỉ phép' },
    LEAVE_PENDING: { cls:'warn', label:'⏳ Chờ duyệt' },
    SYSTEM_CLOSED: { cls:'pend', label:'🔒 Đóng' },
    CANCELLED:     { cls:'err',  label:'🚫 Đã hủy' },
  };
  const st = statusMap[_activeStatus] || { cls:'pend', label:_activeStatus };
  badge.className = 'sdp-badge ' + st.cls;
  badge.textContent = st.label;

  // ── Timeline ──
  renderTimeline(shifts);

  // ── Info chips ──
  document.getElementById('sdpId').textContent        = _activeSchedId;
  document.getElementById('sdpShiftType').textContent  = firstShift.type || '—';
  document.getElementById('sdpLate').textContent       = _activeLateTol + 'p trễ';
  document.getElementById('sdpTotal').textContent      = total + ' ca/ngày';
  const posNum = parseInt(_activePosStation) || 0;
  const posChip = document.getElementById('sdpChipPos');
  document.getElementById('sdpPos').textContent = posNum > 0 ? 'Quầy ' + posNum : 'Chưa gán';
  posChip.style.background = posNum > 0 ? '#eff6ff' : '#f8fafc';
  posChip.style.color      = posNum > 0 ? '#1d4ed8' : '#94a3b8';

  // Notes
  const nw = document.getElementById('sdpNotesWrap');
  if (_activeNotes && _activeNotes !== 'null' && _activeNotes.trim()) {
    nw.style.display = '';
    document.getElementById('sdpNotes').textContent = '💬 ' + _activeNotes;
  } else { nw.style.display = 'none'; }

  // Actions
  const isPast  = cardEl.dataset.isPast === 'true';
  const canEdit = !isPast && (_activeStatus === 'SCHEDULED' || _activeStatus === 'LEAVE_PENDING');
  document.getElementById('sdpEditBtn').style.display = canEdit ? '' : 'none';
  document.getElementById('sdpDelBtn').style.display  = canEdit ? '' : 'none';

  const dov = document.getElementById('detailOverlay');
  if (dov) { dov.classList.add('open'); dov.style.display = 'flex'; }
  } catch(err) { console.error('[showDetailPanel]', err); }
}

// ── Render timeline bar ──
function renderTimeline(shifts) {
  const box = document.getElementById('sdpTimeline');
  if (!shifts.length) { box.innerHTML = '<div style="padding:16px;text-align:center;color:var(--muted);font-size:12px">Không có dữ liệu</div>'; return; }

  function toMin(t) { if (!t) return 0; const [h,m]=t.split(':').map(Number); return h*60+m; }
  function fmtH(m)  { return String(Math.floor((m%1440)/60)).padStart(2,'0')+':'+String(m%60).padStart(2,'0'); }
  function getColor(m) { return m<720?'#3B82F6':m<1200?'#F97316':'#7C3AED'; }
  function getCls(m)   { return m<720?'morning':m<1200?'afternoon':'night'; }

  // Tính range
  let lo=1440, hi=0;
  shifts.forEach(s => { let a=toMin(s.start),b=toMin(s.end); if(b<=a)b+=1440; lo=Math.min(lo,a); hi=Math.max(hi,b); });
  const pad=60, rS=Math.max(0,lo-pad), rE=Math.min(2880,hi+pad), rL=rE-rS;
  function pct(v) { return ((v-rS)/rL*100); }

  // Container padding 3% mỗi bên
  const PL=3, PR=3;
  function pos(v) { return (PL + pct(v)*(100-PL-PR)/100).toFixed(1); }

  let h = '<div class="sdp-tl-track" style="left:'+PL+'%;right:'+PR+'%"></div>';

  shifts.forEach(s => {
    let a=toMin(s.start), b=toMin(s.end);
    if(b<=a) b+=1440;
    const col=getColor(a), cls=getCls(a);
    const lp=pos(a), rp=pos(b), wp=(parseFloat(rp)-parseFloat(lp)).toFixed(1);

    // Bar segment
    h += '<div class="sdp-tl-seg '+cls+'" style="left:'+lp+'%;width:'+wp+'%"></div>';

    // Start marker
    h += '<div class="sdp-tl-marker" style="left:'+lp+'%">'
       +   '<div class="sdp-tl-time">'+s.start+'</div>'
       +   '<div class="sdp-tl-label">'+( s.type||'' )+'</div>'
       + '</div>';
    h += '<div class="sdp-tl-dot" style="left:'+lp+'%;background:'+col+'"></div>';

    // End marker
    h += '<div class="sdp-tl-marker" style="left:'+rp+'%">'
       +   '<div class="sdp-tl-time">'+fmtH(b)+'</div>'
       + '</div>';
    h += '<div class="sdp-tl-dot" style="left:'+rp+'%;background:'+col+'"></div>';
  });

  box.innerHTML = h;
}

function closeDetailPanel() {
  if (_activeCard) _activeCard.classList.remove('selected');
  _activeCard = null;
  const dov = document.getElementById('detailOverlay');
  if (dov) { dov.classList.remove('open'); dov.style.display = ''; }
}

function formatDate(dateStr) {
  if (!dateStr) return '—';
  const d = new Date(dateStr);
  return d.getDate() + '/' + (d.getMonth()+1) + '/' + d.getFullYear();
}

// ── Sửa ca: mở modal edit đã có, pre-fill cho ca đang xem ──
function editFromPanel() {
  if (!_activeSchedId) return;
  // Đóng detail modal trước → mở edit modal sau (không chồng 2 modal)
  closeDetailPanel();
  setTimeout(function() {
    openEditModal(
      _activeSchedId,
      _activeShiftTypeId,
      document.getElementById('sdpShiftType')
        ? document.getElementById('sdpShiftType').textContent : '',
      _activeLateTol,
      _activeNotes && _activeNotes !== 'null' ? _activeNotes : '',
      _activeStaffName,
      _activeWorkDate,
      _activePosStation,
      _activeStatus
    );
  }, 220); // đợi animation đóng xong (transition 0.2s)
}

// ── Xóa ca: đóng detail modal → confirm → POST ──
function deleteFromPanel() {
  if (!_activeSchedId) return;
  closeDetailPanel();
  setTimeout(function() {
    cancelSchedule(parseInt(_activeSchedId));
  }, 220);
}

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
  console.log('[openFullSchedModal] called with', preDate, preAccountId);
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
  const m = document.getElementById('fullSchedModal');
  if (m) { m.classList.add('open'); m.style.display = 'flex'; }
  // Đóng modal xếp ca cũ nếu đang mở
  const old = document.getElementById('schedModal');
  if (old) { old.classList.remove('open'); old.style.display = ''; }
}

function closeFullSchedModal() {
  const m = document.getElementById('fullSchedModal');
  if (m) { m.classList.remove('open'); m.style.display = ''; }
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

function showFsErr(errId, inputId, msg) {
  const errEl = document.getElementById(errId);
  if (errEl) { errEl.textContent = msg; errEl.classList.add('show'); }
  const inp = inputId && document.getElementById(inputId);
  if (inp) inp.classList.add('err');
}
function clearFsErr(errId, inputId) {
  const errEl = document.getElementById(errId);
  if (errEl) { errEl.textContent = ''; errEl.classList.remove('show'); }
  const inp = inputId && document.getElementById(inputId);
  if (inp) inp.classList.remove('err');
}

function submitFullSched() {
  const staffCount = document.querySelectorAll('#fullStaffChips .sc-chip:not(.hidden) input:checked').length;
  const typeCount  = document.querySelectorAll('#fullStypeCards input:checked').length;
  const fromVal    = document.getElementById('fsDateFrom')?.value;
  const toVal      = document.getElementById('fsDateTo')?.value;
  const posVal     = parseInt(document.getElementById('fsPosStation')?.value || '0');
  const todayFs    = new Date().toISOString().split('T')[0];

  // Clear inline errors
  ['errDateFrom','errDateTo','errPosStation'].forEach(id => clearFsErr(id));

  if (staffCount === 0) { alert('Vui lòng chọn ít nhất 1 nhân viên!'); return; }
  if (typeCount  === 0) { alert('Vui lòng chọn ít nhất 1 loại ca!');    return; }

  let hasErr = false;
  if (!fromVal) {
    showFsErr('errDateFrom','fsDateFrom','Vui lòng chọn ngày bắt đầu');
    hasErr = true;
  } else if (fromVal < todayFs) {
    showFsErr('errDateFrom','fsDateFrom','Không thể xếp ca cho ngày đã qua');
    hasErr = true;
  }
  if (toVal && fromVal && toVal < fromVal) {
    showFsErr('errDateTo','fsDateTo','Ngày kết thúc phải sau ngày bắt đầu');
    hasErr = true;
  }
  if (posVal === 0) {
    showFsErr('errPosStation','fsPosStation','Vui lòng chọn quầy POS cho ca làm việc');
    hasErr = true;
  }

  if (hasErr) {
    // Scroll first error into view
    const firstErr = document.querySelector('#fullSchedModal .field-err.show');
    if (firstErr) firstErr.scrollIntoView({ behavior: 'smooth', block: 'center' });
    return;
  }

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

// Nút "Xếp ca mới" (top) vẫn dùng modal xếp hàng loạt
function openSchedModal(preDate, preAccountId) {
  openFullSchedModal(preDate, preAccountId);
}
function openSchedModalForDay(date, accountId) {
  openFullSchedModal(date, accountId);
}

// ── THÊM 1 CA NHANH cho 1 ngày (nút "+ Thêm ca" ở ô ngày) ──────────────────
function openQuickShift(date) {
  const today = new Date().toISOString().split('T')[0];
  if (date && date < today) {
    alert('⛔ Không thể xếp ca cho ngày ' + date + ' — ngày này đã qua!');
    return;
  }
  const f = document.getElementById('quickShiftForm');
  if (f) f.reset();
  document.getElementById('qsDate').value = date;
  // Hiển thị ngày (dd/mm/yyyy) trên tiêu đề
  let label = date;
  const p = (date || '').split('-');
  if (p.length === 3) label = p[2] + '/' + p[1] + '/' + p[0];
  document.getElementById('quickShiftTitle').textContent = '➕ Thêm ca — ' + label;
  const qsm = document.getElementById('quickShiftModal');
  if (qsm) { qsm.classList.add('open'); qsm.style.display = 'flex'; }
}
function closeQuickShift() {
  const qsm = document.getElementById('quickShiftModal');
  if (qsm) { qsm.classList.remove('open'); qsm.style.display = ''; }
}
function submitQuickShift() {
  const staff = document.getElementById('qsStaff').value;
  const type  = document.getElementById('qsType').value;
  if (!staff) { alert('Vui lòng chọn nhân viên!'); return; }
  if (!type)  { alert('Vui lòng chọn loại ca!');   return; }
  document.getElementById('quickShiftForm').submit();
}
// Click nền ngoài để đóng
document.getElementById('quickShiftModal').addEventListener('click', function(e) {
  if (e.target === this) closeQuickShift();
});


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
function openEditModal(schedId, shiftTypeId, shiftTypeName, lateTol, notes, staffName, workDate, posStation, status) {
  const isConfirmed = (status === 'CONFIRMED');
  document.getElementById('editSchedId').value      = schedId;
  document.getElementById('editShiftType').value    = shiftTypeId;
  document.getElementById('editShiftType').disabled = isConfirmed; // ca đang chạy → khóa loại ca
  document.getElementById('editLateTol').value      = lateTol || 10;
  document.getElementById('editNotes').value        = notes && notes !== 'null' ? notes : '';
  document.getElementById('editWorkDate').value     = workDate;
  document.getElementById('editPosStation').value   = posStation || 0;
  document.getElementById('editModalTitle').textContent =
    (isConfirmed ? '🟢 Đang ca — ' : '✏️ ') + 'Sửa ca ' + staffName + ' — ' + workDate;
  const ems = document.getElementById('editSchedModal');
  if (ems) { ems.classList.add('open'); ems.style.display = 'flex'; }
}
function closeEditModal() {
  const ems = document.getElementById('editSchedModal');
  if (ems) { ems.classList.remove('open'); ems.style.display = ''; }
}
function submitEditSched() {
  const stSel = document.getElementById('editShiftType');
  stSel.disabled = false; // re-enable để value được gửi trong POST (disabled inputs bị bỏ qua)
  if (!stSel.value) { alert('Vui lòng chọn loại ca!'); return; }
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

  const dsModal = document.getElementById('deleteStaffModal');
  if (dsModal) { dsModal.classList.add('open'); dsModal.style.display = 'flex'; }

  // Load preview ngay
  loadDelPreview();
}

function closeDeleteModal() {
  const dsModal = document.getElementById('deleteStaffModal');
  if (dsModal) { dsModal.classList.remove('open'); dsModal.style.display = ''; }
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
  document.querySelectorAll('#editWeekGrid .sm-chip').forEach(ch => {
    ch.classList.remove('sm-selected-edit');
  });
  document.getElementById('editPanel').classList.remove('show');
  updateEditSelUI();
  const esm = document.getElementById('editSelectModal');
  if (esm) { esm.classList.add('open'); esm.style.display = 'flex'; }
}
function closeEditSelectModal() {
  const esm = document.getElementById('editSelectModal');
  if (esm) { esm.classList.remove('open'); esm.style.display = ''; }
}

function toggleEditChip(el) {
  if (el.dataset.editable !== 'true') return;
  const id = el.dataset.schedId;
  if (_editSelIds.has(id)) {
    _editSelIds.delete(id);
    el.classList.remove('sm-selected-edit');
  } else {
    _editSelIds.add(id);
    el.classList.add('sm-selected-edit');
  }
  // Pre-fill panel khi chỉ có đúng 1 ca được chọn
  if (_editSelIds.size === 1) {
    const selEl = document.querySelector('#editWeekGrid .sm-chip.sm-selected-edit');
    if (selEl) {
      const typeId  = selEl.dataset.shiftTypeId;
      const lateTol = selEl.dataset.lateTol;
      const notes   = selEl.dataset.notes;
      const stSel   = document.getElementById('smEditShiftType');
      if (typeId) stSel.value = typeId;
      if (lateTol) document.getElementById('smEditLateTol').value = lateTol;
      document.getElementById('smEditNotes').value = (notes && notes !== 'null') ? notes : '';
    }
  } else if (_editSelIds.size > 1) {
    // Nhiều ca → reset về "giữ nguyên"
    document.getElementById('smEditShiftType').value = '';
    document.getElementById('smEditLateTol').value   = '';
    document.getElementById('smEditNotes').value     = '';
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
    panel.classList.add('open');
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
  const dsm = document.getElementById('deleteSelectModal');
  if (dsm) { dsm.classList.add('open'); dsm.style.display = 'flex'; }
}
function closeDeleteSelectModal() {
  const dsm = document.getElementById('deleteSelectModal');
  if (dsm) { dsm.classList.remove('open'); dsm.style.display = ''; }
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
  modal.classList.add('open'); modal.style.display = 'flex';
}

// ════════════════════════════════════════════════════════════
//  POS MAP — Sơ đồ quầy POS  (_posCtx/_todaySchedules/_posStations defined in separate data block above)
// ════════════════════════════════════════════════════════════
let _posOnlineIds = [];  // accountIds đang online ở POS (từ polling)
let _posMapInterval = null;

function initPosMap() {
  const now = new Date();
  const el  = document.getElementById('posMapDate');
  if (el) el.textContent = 'Hôm nay: ' + now.getDate() + '/' + (now.getMonth()+1) + '/' + now.getFullYear();
  renderPosMap();
  refreshPosOnlineStatus();
}

async function refreshPosOnlineStatus() {
  try {
    const res  = await fetch(_posCtx + '/shifts?action=pos-online', { headers: {'X-Requested-With':'XMLHttpRequest'} });
    if (!res.ok) return;
    const data = await res.json();
    _posOnlineIds = data.onlineStations || [];  // array of station numbers that are online
    renderPosMap();
  } catch(e) {}
}

function renderPosMap() {
  const grid    = document.getElementById('posStationGrid');
  const unasList= document.getElementById('posUnassignedList');
  const unasWrap= document.getElementById('posUnassigned');
  if (!grid) return;

  // Nhóm theo quầy
  const stationMap = {};  // station# → [{staffName, status, shiftType}]
  const unassigned = [];

  _todaySchedules.forEach(s => {
    if (s.posStation > 0) {
      if (!stationMap[s.posStation]) stationMap[s.posStation] = [];
      stationMap[s.posStation].push(s);
    } else {
      unassigned.push(s);
    }
  });

  // Render các quầy từ database
  let html = '';
  if (_posStations.length === 0) {
    html = '<div style="grid-column: 1/-1; text-align: center; padding: 40px; color: var(--muted); font-size: 14.5px; font-weight: 500; background: rgba(21,88,168,0.01); border: 2px dashed rgba(21,88,168,0.08); border-radius: 14px;">⚠️ Chưa có quầy POS nào được thiết lập. Hãy nhấn nút "Quản lý quầy" để thêm.</div>';
  } else {
    _posStations.forEach(station => {
      const st = station.id;
      const stationName = station.name;
      const staffList  = stationMap[st] || [];
      const isOnline   = _posOnlineIds.includes(st);
      const cls        = isOnline ? 'online' : 'offline';
      const badgeTxt   = isOnline ? '🟢 ĐANG ONLINE' : '⚫ OFFLINE';

      html += '<div class="pos-station-card ' + cls + '">';
      html += '<div class="pos-st-header">';
      html +=   '<span class="pos-st-number">' + escHtml(stationName) + '</span>';
      html +=   '<div style="display:flex;align-items:center;gap:6px">';
      html +=     '<button onclick="openPosAddModal(' + st + ')" class="btn-pos-add-staff">➕ Thêm NV</button>';
      html +=     '<span class="pos-st-badge ' + cls + '" style="display:none">' + badgeTxt + '</span>';
      html +=     '<span class="pos-st-dot ' + cls + '" title="' + badgeTxt + '"></span>';
      html +=   '</div>';
      html += '</div>';

      html += '<div class="pos-st-staff-list">';
      if (staffList.length === 0) {
        html += '<div class="pos-st-empty">Chưa có nhân viên được xếp</div>';
      } else {
        staffList.forEach(s => {
          const initials = s.staffName.length >= 2
            ? (s.staffName.charAt(0) + s.staffName.split(' ').pop().charAt(0)).toUpperCase()
            : s.staffName.charAt(0).toUpperCase();
          const staffOnline = isOnline; // nếu quầy online → nhân viên ca đó online
          const avCls = staffOnline ? 'online' : 'offline';
          
          // Map status to visual styles
          let statusLabel = s.status || '';
          let statusColor = '#64748b';
          let statusBg = '#f1f5f9';
          let statusBorder = 'rgba(100,116,139,0.1)';
          
          if (s.status === 'CONFIRMED') {
            statusLabel = 'Đang làm';
            statusColor = '#047857';
            statusBg = '#ecfdf5';
            statusBorder = 'rgba(16,185,129,0.2)';
          } else if (s.status === 'SCHEDULED') {
            statusLabel = 'Chưa vào';
            statusColor = '#1d4ed8';
            statusBg = '#eff6ff';
            statusBorder = 'rgba(37,99,235,0.2)';
          } else if (s.status === 'LATE') {
            statusLabel = 'Đến trễ';
            statusColor = '#b45309';
            statusBg = '#fffbeb';
            statusBorder = 'rgba(217,119,6,0.2)';
          }
          
          html += '<div class="pos-st-staff-row">';
          html +=   '<div style="display:flex;align-items:center;gap:10px;min-width:0;flex:1;">';
          html +=     '<div class="pos-st-av ' + avCls + '">' + initials + '</div>';
          html +=     '<div style="min-width:0">';
          html +=       '<div class="pos-st-staff-name">' + escHtml(s.staffName) + '</div>';
          html +=       '<div class="pos-st-staff-meta">' + escHtml(s.shiftType) + ' · ' + s.startHour + ':00–' + s.endHour + ':00</div>';
          html +=     '</div>';
          html +=   '</div>';
          html +=   '<div style="display:flex;align-items:center;gap:6px;">';
          html +=     '<span style="font-size:9.5px;font-weight:800;padding:2px 7px;border-radius:20px;color:' + statusColor + ';background:' + statusBg + ';border:1px solid ' + statusBorder + ';">' + statusLabel + '</span>';
          html +=     '<div class="pos-st-actions">';
          html +=       '<button onclick="openPosEditModal(' + s.scheduleId + ')" class="pos-st-btn edit" title="Sửa phân công">✏️</button>';
          html +=       '<button onclick="handlePosDeleteClick(' + s.scheduleId + ', \'' + escHtml(s.staffName) + '\')" class="pos-st-btn delete" title="Gỡ / Xóa nhân viên">🗑️</button>';
          html +=     '</div>';
          html +=   '</div>';
          html += '</div>';
        });
      }
      html += '</div>';
      html += '</div>';
    });
  }
  grid.innerHTML = html;

  // Render unassigned
  if (unassigned.length > 0) {
    unasList.innerHTML = unassigned.map(s => {
      return '<div class="pos-unas-chip" onclick="openQuickAssignModal(' + s.scheduleId + ', \'' + escHtml(s.staffName) + '\', \'' + escHtml(s.shiftType) + '\')" style="cursor:pointer; transition:all 0.2s;" onmouseover="this.style.background=\'#fef08a\'; this.style.transform=\'translateY(-1px)\'" onmouseout="this.style.background=\'#fff\'; this.style.transform=\'translateY(0)\'">⚠️ ' + escHtml(s.staffName) + ' (' + escHtml(s.shiftType) + ') <span style="font-size:9.5px;color:var(--blue);font-weight:700;margin-left:4px;">Gán nhanh ➔</span></div>';
    }).join('');
    unasWrap.style.display = '';
  } else {
    unasWrap.style.display = 'none';
  }
}

// Collapsible instructions guide toggle
function togglePosGuide() {
  const body = document.getElementById('posGuideBody');
  const icon = document.getElementById('posGuideIcon');
  if (body.style.display === 'none' || !body.style.display) {
    body.style.display = 'flex';
    icon.style.transform = 'rotate(180deg)';
  } else {
    body.style.display = 'none';
    icon.style.transform = 'rotate(0deg)';
  }
}

// Add Options logic in Create/Add Staff Modal
function toggleAddOption(opt) {
  const secAssign = document.getElementById('secOptAssign');
  const secCreate = document.getElementById('secOptCreate');
  const lblAssign = document.getElementById('lblOptAssign');
  const lblCreate = document.getElementById('lblOptCreate');
  
  if (opt === 'assign') {
    secAssign.style.display = 'block';
    secCreate.style.display = 'none';
    lblAssign.style.borderColor = 'var(--blue)';
    lblAssign.style.background = 'rgba(21,88,168,0.04)';
    lblCreate.style.borderColor = 'var(--border)';
    lblCreate.style.background = 'transparent';
  } else {
    secAssign.style.display = 'none';
    secCreate.style.display = 'block';
    lblAssign.style.borderColor = 'var(--border)';
    lblAssign.style.background = 'transparent';
    lblCreate.style.borderColor = 'var(--blue)';
    lblCreate.style.background = 'rgba(21,88,168,0.04)';
  }
}

// Open modal to assign/schedule staff to a specific counter today
function openPosAddModal(stationNum) {
  document.getElementById('posAddStationNum').value = stationNum;
  const stObj = _posStations.find(item => item.id === stationNum);
  const stName = stObj ? stObj.name : 'Quầy ' + stationNum;
  document.getElementById('posAddTitle').textContent = '➕ Phân công nhân viên vào ' + stName;
  
  const select = document.getElementById('posAddScheduleSelect');
  const emptyDiv = document.getElementById('posAddUnassignedEmpty');
  select.innerHTML = '';
  
  const unassigned = _todaySchedules.filter(s => s.posStation === stationNum || (s.posStation === 0));
  const availableUnassigned = unassigned.filter(s => s.posStation === 0);
  
  if (availableUnassigned.length === 0) {
    select.style.display = 'none';
    emptyDiv.style.display = 'block';
    toggleAddOption('create');
    document.querySelector('input[name="addOption"][value="create"]').checked = true;
  } else {
    select.style.display = 'block';
    emptyDiv.style.display = 'none';
    availableUnassigned.forEach(s => {
      const opt = document.createElement('option');
      opt.value = s.scheduleId;
      opt.textContent = s.staffName + ' (' + s.shiftType + ' · ' + s.startHour + ':00 - ' + s.endHour + ':00)';
      select.appendChild(opt);
    });
    toggleAddOption('assign');
    document.querySelector('input[name="addOption"][value="assign"]').checked = true;
  }
  
  document.getElementById('posAddStaffModal').classList.add('open');
}

function closePosAddModal() {
  document.getElementById('posAddStaffModal').classList.remove('open');
}

function submitPosAddForm() {
  const form = document.getElementById('posAddForm');
  const opt = form.querySelector('input[name="addOption"]:checked').value;
  
  if (opt === 'assign') {
    const select = document.getElementById('posAddScheduleSelect');
    if (!select.value) {
      alert('Vui lòng chọn một ca làm việc!');
      return;
    }
    // Vô hiệu hóa dropdown Xếp ca mới để không gửi lên server
    form.querySelector('select[name="accountId"]').disabled = true;
    form.querySelector('select[name="shiftTypeId"]').disabled = true;
  } else {
    form.querySelector('input[name="action"]').value = 'pos-assign';
    // Vô hiệu hóa dropdown Gán ca có sẵn để không gửi lên server
    const select = document.getElementById('posAddScheduleSelect');
    if (select) select.disabled = true;
    
    const acc = form.querySelector('select[name="accountId"]').value;
    const type = form.querySelector('select[name="shiftTypeId"]').value;
    if (!acc || !type) {
      alert('Vui lòng chọn đầy đủ Nhân viên và Loại ca!');
      return;
    }
  }
  form.submit();
}

// Open modal to edit an existing shift schedule details and its POS station today
function openPosEditModal(scheduleId) {
  const s = _todaySchedules.find(item => item.scheduleId === scheduleId);
  if (!s) return;
  
  document.getElementById('posEditScheduleId').value = s.scheduleId;
  document.getElementById('posEditStaffName').value = s.staffName;
  document.getElementById('posEditStationSelect').value = s.posStation;
  document.getElementById('posEditShiftTypeSelect').value = s.shiftTypeId;
  document.getElementById('posEditLateTol').value = s.lateToleranceMinutes || 10;
  document.getElementById('posEditNotes').value = s.notes || '';
  
  document.getElementById('posEditStaffModal').classList.add('open');
}

function closePosEditModal() {
  document.getElementById('posEditStaffModal').classList.remove('open');
}

function submitPosEditForm() {
  document.getElementById('posEditForm').submit();
}

// Open delete confirmation overlay
function handlePosDeleteClick(scheduleId, staffName) {
  document.getElementById('posDeleteStaffName').textContent = ' ' + staffName;
  document.querySelectorAll('.posDeleteScheduleId').forEach(input => {
    input.value = scheduleId;
  });
  
  document.getElementById('posDeleteModal').classList.add('open');
}

function closePosDeleteModal() {
  document.getElementById('posDeleteModal').classList.remove('open');
}

// Quick assign function from unassigned chips
function openQuickAssignModal(scheduleId, staffName, shiftType) {
  openPosEditModal(scheduleId);
}

function refreshPosMap() {
  refreshPosOnlineStatus();
}

function openPosManagerModal() {
  document.getElementById('posManagerModal').classList.add('open');
}

function closePosManagerModal() {
  document.getElementById('posManagerModal').classList.remove('open');
}

function showEditCounterRow(id) {
  document.getElementById('lblStation-' + id).style.display = 'none';
  document.getElementById('editForm-' + id).style.display = 'block';
  document.getElementById('btnEdit-' + id).style.display = 'none';
  document.getElementById('btnSave-' + id).style.display = 'inline-block';
  document.getElementById('btnCancel-' + id).style.display = 'inline-block';
}

function hideEditCounterRow(id) {
  document.getElementById('lblStation-' + id).style.display = 'block';
  document.getElementById('editForm-' + id).style.display = 'none';
  document.getElementById('btnEdit-' + id).style.display = 'inline-block';
  document.getElementById('btnSave-' + id).style.display = 'none';
  document.getElementById('btnCancel-' + id).style.display = 'none';
}

function submitEditCounterRow(id) {
  document.getElementById('editForm-' + id).submit();
}

function escHtml(s) {
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

// Poll online status mỗi 15s khi tab pos-map đang mở
document.addEventListener('DOMContentLoaded', function() {
  // Ghi đè switchTab để start/stop interval
  const origSwitch = window.switchTab;
  window.switchTab = function(tab, btn) {
    origSwitch && origSwitch(tab, btn);
    if (tab === 'pos-map') {
      initPosMap();
      _posMapInterval = setInterval(refreshPosOnlineStatus, 15000);
    } else {
      clearInterval(_posMapInterval);
    }
  };
  // Nếu tab pos-map là active tab khi load
  if ('<%= activeTab %>'.indexOf('pos-map') >= 0) initPosMap();
});
</script>
<%-- Parse diagnostic: shows green/red badge for 6s after page load --%>
<script>
(function(){
  var ok = typeof updateFullPreview === 'function';
  var b = document.createElement('div');
  b.style.cssText = 'position:fixed;bottom:6px;left:50%;transform:translateX(-50%);z-index:99999;padding:4px 12px;border-radius:20px;font-size:11.5px;font-weight:700;font-family:Outfit,sans-serif;';
  b.style.background = ok ? '#10b981' : '#dc2626';
  b.style.color = '#fff';
  b.textContent = ok ? '✓ Main JS loaded OK' : '✗ Main JS FAILED (using safety fns)';
  document.body.appendChild(b);
  setTimeout(function(){b.remove();},6000);
})();
</script>
</body>
</html>

