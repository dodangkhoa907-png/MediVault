<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%
    com.medivault.entity.Account acc = (com.medivault.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
    String msg = request.getParameter("msg");
    String activeTab = request.getParameter("tab") != null ? request.getParameter("tab") : "schedule";
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
  --purple:#7C3AED;--pink:#DB2777;
  /* Ca màu sắc */
  --ca-long:#7C3AED;    /* Ca dài/gãy ≥10h — tím */
  --ca-std:#1558A8;     /* Ca tiêu chuẩn 8h — xanh */
  --ca-part:#059669;    /* Part-time ≤6h — xanh lá */
  --ca-open:#D97706;    /* Đang làm — cam */
  --ca-absent:#DC2626;  /* Vắng — đỏ */
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

/* ── MAIN ── */
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0}

/* ── TOPBAR ── */
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

/* ── CONTENT ── */
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
.kpi-sub{font-size:11px;color:var(--muted);margin-top:2px}

/* ── TABS ── */
.tab-bar{display:flex;gap:2px;background:var(--white);border:1px solid var(--border);border-radius:12px;padding:4px;margin-bottom:20px;width:fit-content}
.tab-btn{padding:8px 20px;border-radius:9px;font-size:13px;font-weight:600;cursor:pointer;border:none;background:transparent;color:var(--muted);transition:all .18s;display:flex;align-items:center;gap:6px}
.tab-btn:hover{color:var(--ink);background:var(--surface)}
.tab-btn.active{background:linear-gradient(135deg,var(--blue),var(--cyan));color:#fff;box-shadow:0 3px 10px rgba(21,88,168,.25)}

/* ── TAB CONTENT ── */
.tab-pane{display:none}
.tab-pane.active{display:block}

/* ── SCHEDULE TAB: Timeline ── */
.schedule-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:14px}
.schedule-nav{display:flex;align-items:center;gap:8px}
.nav-arrow{width:32px;height:32px;border-radius:8px;border:1.5px solid var(--border);background:var(--white);cursor:pointer;display:flex;align-items:center;justify-content:center;font-size:14px;color:var(--muted);transition:all .18s;text-decoration:none}
.nav-arrow:hover{border-color:var(--blue);color:var(--blue)}
.nav-period{font-size:14px;font-weight:700;color:var(--ink);padding:0 8px}
.btn-today{padding:6px 14px;border-radius:8px;border:1.5px solid var(--border);background:var(--white);font-size:12.5px;font-weight:600;color:var(--muted);cursor:pointer;transition:all .18s;text-decoration:none}
.btn-today:hover{border-color:var(--blue);color:var(--blue)}

/* View toggle week/month */
.view-toggle{display:flex;gap:2px;background:var(--surface);border-radius:8px;padding:3px}
.vt-btn{padding:5px 14px;border-radius:6px;font-size:12.5px;font-weight:600;cursor:pointer;border:none;background:transparent;color:var(--muted);transition:all .15s}
.vt-btn.active{background:var(--white);color:var(--blue);box-shadow:0 2px 6px rgba(0,0,0,.08)}

/* ── WEEK VIEW ── */
.week-grid{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}
.week-header{display:grid;grid-template-columns:64px repeat(7,1fr);border-bottom:1px solid var(--border)}
.week-hcol{padding:10px 8px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:var(--muted);text-align:center;border-right:1px solid var(--border)}
.week-hcol:last-child{border-right:none}
.week-hcol.today-col{background:linear-gradient(135deg,rgba(21,88,168,.06),rgba(58,189,224,.06))}
.week-hcol .day-num{font-size:18px;font-weight:900;color:var(--ink);display:block;line-height:1;margin-top:3px}
.week-hcol.today-col .day-num{color:var(--blue)}
.week-body{display:grid;grid-template-columns:64px repeat(7,1fr)}
.time-col{border-right:1px solid var(--border)}
.time-slot{height:52px;border-bottom:1px solid #F1F5F9;display:flex;align-items:flex-start;padding:4px 8px;font-size:10px;font-weight:600;color:var(--muted)}
.day-col{border-right:1px solid var(--border);position:relative;min-height:624px}
.day-col:last-child{border-right:none}
.day-col.today-col{background:rgba(21,88,168,.02)}

/* Shift block */
.shift-block{
  position:absolute;left:4px;right:4px;
  border-radius:8px;padding:5px 8px;
  font-size:11px;font-weight:700;
  cursor:pointer;transition:all .18s;
  overflow:hidden;border:1.5px solid transparent;
}
.shift-block:hover{opacity:.85;transform:scaleY(1.01)}
.shift-block.ca-long{background:linear-gradient(135deg,rgba(124,58,237,.15),rgba(124,58,237,.08));border-color:rgba(124,58,237,.3);color:#5B21B6}
.shift-block.ca-std{background:linear-gradient(135deg,rgba(21,88,168,.15),rgba(58,189,224,.08));border-color:rgba(21,88,168,.25);color:#1558A8}
.shift-block.ca-part{background:linear-gradient(135deg,rgba(5,150,105,.15),rgba(16,185,129,.08));border-color:rgba(5,150,105,.25);color:#065F46}
.shift-block.ca-open{background:linear-gradient(135deg,rgba(217,119,6,.18),rgba(245,158,11,.08));border-color:rgba(217,119,6,.3);color:#92400E;animation:pulse-border 2s infinite}
.shift-block.ca-absent{background:rgba(220,38,38,.08);border-color:rgba(220,38,38,.2);color:#991B1B}
.shift-block.ca-leave{background:rgba(99,102,241,.08);border-color:rgba(99,102,241,.2);color:#3730A3}

@keyframes pulse-border{
  0%,100%{border-color:rgba(217,119,6,.3)}
  50%{border-color:rgba(217,119,6,.7)}
}

.sb-name{font-size:10.5px;font-weight:800;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.sb-time{font-size:9.5px;font-weight:500;opacity:.8;margin-top:1px}
.sb-cash{font-size:9.5px;margin-top:2px;opacity:.7}

/* Add shift button on day */
.add-shift-btn{
  position:absolute;bottom:6px;left:50%;transform:translateX(-50%);
  width:24px;height:24px;border-radius:50%;
  background:var(--blue);color:#fff;
  border:none;font-size:14px;cursor:pointer;
  display:flex;align-items:center;justify-content:center;
  opacity:0;transition:opacity .18s;
  text-decoration:none;box-shadow:0 2px 8px rgba(21,88,168,.3)
}
.day-col:hover .add-shift-btn{opacity:1}

/* Legend */
.legend{display:flex;gap:14px;align-items:center;flex-wrap:wrap}
.leg-item{display:flex;align-items:center;gap:5px;font-size:11.5px;font-weight:600;color:var(--muted)}
.leg-dot{width:10px;height:10px;border-radius:3px;flex-shrink:0}

/* ── MONTH VIEW ── */
.month-grid{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}
.month-weekdays{display:grid;grid-template-columns:repeat(7,1fr);border-bottom:1px solid var(--border)}
.mw-head{padding:10px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:var(--muted);text-align:center;border-right:1px solid var(--border)}
.mw-head:last-child{border-right:none}
.month-body{display:grid;grid-template-columns:repeat(7,1fr)}
.month-cell{min-height:90px;border-right:1px solid var(--border);border-bottom:1px solid var(--border);padding:6px;cursor:pointer;transition:background .12s;position:relative}
.month-cell:hover{background:#F7FBFF}
.month-cell:nth-child(7n){border-right:none}
.month-cell.other-month{background:#FAFBFC}
.month-cell.today-cell{background:linear-gradient(135deg,rgba(21,88,168,.04),rgba(58,189,224,.04))}
.mc-day{font-size:12px;font-weight:700;color:var(--muted);margin-bottom:4px}
.mc-day.today-num{width:22px;height:22px;background:var(--blue);color:#fff;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:11px}
.mc-shift{font-size:10px;font-weight:700;border-radius:4px;padding:2px 5px;margin-bottom:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;cursor:pointer}
.mc-shift.ca-long{background:rgba(124,58,237,.12);color:#5B21B6}
.mc-shift.ca-std{background:rgba(21,88,168,.12);color:#1558A8}
.mc-shift.ca-part{background:rgba(5,150,105,.12);color:#065F46}
.mc-shift.ca-open{background:rgba(217,119,6,.12);color:#92400E}
.mc-shift.ca-absent{background:rgba(220,38,38,.08);color:#991B1B}
.mc-more{font-size:10px;color:var(--muted);font-weight:600;padding:1px 4px}
.mc-add{position:absolute;top:5px;right:5px;width:18px;height:18px;border-radius:4px;background:var(--blue);color:#fff;font-size:12px;display:flex;align-items:center;justify-content:center;opacity:0;transition:opacity .15s;text-decoration:none}
.month-cell:hover .mc-add{opacity:1}

/* ── SHIFTS LIST TAB ── */
.list-layout{display:grid;grid-template-columns:1fr 1.5fr;gap:14px;margin-bottom:20px;align-items:start}
.open-panel{background:var(--white);border:1.5px solid #BFDBFE;border-radius:var(--radius);overflow:hidden}
.open-panel-head{background:linear-gradient(135deg,#EFF6FF,#F0FDF4);padding:12px 18px;display:flex;align-items:center;gap:8px;border-bottom:1px solid #DBEAFE}
.open-panel-head h3{font-size:13px;font-weight:800;color:#1558A8}
.open-panel-body{padding:14px 18px}
.fg{display:flex;flex-direction:column;gap:4px;margin-bottom:10px}
.fg label{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.fg select,.fg input[type=number]{border:1.5px solid var(--border);border-radius:8px;padding:8px 11px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);background:var(--surface);outline:none;transition:border .18s;width:100%}
.fg select:focus,.fg input:focus{border-color:var(--blue);background:#fff}
.btn-open{display:inline-flex;align-items:center;justify-content:center;gap:7px;padding:9px 0;background:linear-gradient(135deg,#10B981,#059669);color:#fff;border:none;border-radius:9px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;width:100%;box-shadow:0 3px 10px rgba(5,150,105,.25);transition:all .18s}
.btn-open:hover{opacity:.9;transform:translateY(-1px)}

.filter-panel{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}
.filter-panel-head{padding:12px 18px;border-bottom:1px solid var(--border);display:flex;align-items:center;gap:8px}
.filter-panel-head h3{font-size:13px;font-weight:800;color:var(--ink)}
.filter-body{padding:14px 18px}
.filter-grid{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.fi{display:flex;flex-direction:column;gap:4px}
.fi label{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.fi input,.fi select{border:1.5px solid var(--border);border-radius:8px;padding:7px 10px;font-family:'Outfit',sans-serif;font-size:12.5px;color:var(--ink);background:var(--surface);outline:none;transition:border .18s}
.fi input:focus,.fi select:focus{border-color:var(--blue);background:#fff}
.filter-actions{display:flex;gap:8px;margin-top:12px}
.btn-filter{flex:1;padding:8px 0;background:var(--blue);color:#fff;border:none;border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;transition:background .18s}
.btn-filter:hover{background:#0D3F85}
.btn-reset{padding:8px 14px;background:var(--surface);color:var(--muted);border:1.5px solid var(--border);border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;cursor:pointer;text-decoration:none;display:inline-flex;align-items:center;transition:all .18s}
.btn-reset:hover{border-color:var(--red);color:var(--red)}

/* Table */
.table-card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}
.table-card-head{padding:14px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
.table-card-head h2{font-size:14px;font-weight:800;color:var(--ink)}
.table-card-sub{font-size:12px;color:var(--muted)}
.tbl-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse}
thead th{padding:10px 16px;background:#F8FAFC;font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;white-space:nowrap;border-bottom:1px solid var(--border)}
tbody td{padding:12px 16px;font-size:13px;color:var(--ink);border-bottom:1px solid #F1F5F9;vertical-align:middle}
tbody tr:last-child td{border-bottom:none}
tbody tr:hover td{background:#F7FBFF}
.staff-cell{display:flex;align-items:center;gap:9px}
.staff-av{width:30px;height:30px;border-radius:8px;flex-shrink:0;background:linear-gradient(135deg,#1558A8,#4F81D9);color:#fff;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800}
.staff-name{font-weight:700;color:var(--ink);font-size:13px}
.staff-role{font-size:11px;color:var(--muted)}
.time-main{font-size:13px;font-weight:600;color:var(--ink)}
.time-date{font-size:11px;color:var(--muted);margin-top:1px}
.dur-active{color:var(--green);font-weight:700;font-size:12.5px;display:flex;align-items:center;gap:4px}
.cash-val{font-size:12.5px;font-weight:700;color:var(--ink)}
.cash-empty{color:var(--muted)}

/* Status badges */
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 9px;border-radius:20px;font-size:11.5px;font-weight:700;white-space:nowrap}
.badge-open{background:#ECFDF5;color:var(--green)}
.badge-closed{background:#F1F5F9;color:#64748B}
.badge-force{background:#FFF7ED;color:var(--gold)}
.badge-absent{background:#FEF2F2;color:var(--red)}
.badge-late{background:#FFFBEB;color:var(--amber)}

/* Action buttons */
.btn-detail{display:inline-flex;align-items:center;gap:5px;padding:5px 11px;background:#EFF6FF;color:var(--blue);border:1.5px solid #BFDBFE;border-radius:7px;font-size:12px;font-weight:700;text-decoration:none;transition:all .18s;cursor:pointer}
.btn-detail:hover{background:#DBEAFE}
.btn-close-shift{display:inline-flex;align-items:center;gap:5px;padding:5px 11px;background:#FFFBEB;color:var(--gold);border:1.5px solid #FDE68A;border-radius:7px;font-size:12px;font-weight:700;text-decoration:none;transition:all .18s;cursor:pointer}
.btn-close-shift:hover{background:#FEF3C7}
.btn-del{width:28px;height:28px;display:inline-flex;align-items:center;justify-content:center;border-radius:7px;background:#FEF2F2;border:1.5px solid #FECACA;color:var(--red);font-size:13px;cursor:pointer;text-decoration:none;transition:all .18s}
.btn-del:hover{background:#FEE2E2}

/* ── SHIFT TYPES TAB ── */
.types-header{display:flex;align-items:center;justify-content:space-between;margin-bottom:16px}
.types-header h2{font-size:16px;font-weight:800;color:var(--ink)}
.btn-add-type{display:inline-flex;align-items:center;gap:7px;padding:8px 18px;background:linear-gradient(135deg,var(--blue),var(--cyan));color:#fff;border:none;border-radius:9px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;text-decoration:none;box-shadow:0 3px 10px rgba(21,88,168,.2);transition:all .18s}
.btn-add-type:hover{opacity:.9;transform:translateY(-1px)}

.types-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:14px}
.type-card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden;transition:box-shadow .2s,transform .18s}
.type-card:hover{box-shadow:0 6px 24px rgba(21,88,168,.1);transform:translateY(-2px)}
.type-card-head{padding:14px 18px;display:flex;align-items:center;gap:12px;border-bottom:1px solid var(--border)}
.type-dot{width:12px;height:12px;border-radius:3px;flex-shrink:0}
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

/* ── MODAL ── */
.modal-overlay{position:fixed;inset:0;background:rgba(11,22,40,.5);z-index:200;display:flex;align-items:center;justify-content:center;opacity:0;pointer-events:none;transition:opacity .2s}
.modal-overlay.open{opacity:1;pointer-events:auto}
.modal{background:var(--white);border-radius:16px;width:480px;max-width:92vw;box-shadow:0 24px 80px rgba(0,0,0,.2);transform:translateY(20px);transition:transform .22s}
.modal-overlay.open .modal{transform:translateY(0)}
.modal-head{padding:18px 22px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
.modal-title{font-size:15px;font-weight:800;color:var(--ink)}
.modal-close{width:28px;height:28px;border-radius:7px;border:none;background:var(--surface);color:var(--muted);font-size:14px;cursor:pointer;display:flex;align-items:center;justify-content:center;transition:all .15s}
.modal-close:hover{background:#FEE2E2;color:var(--red)}
.modal-body{padding:22px}
.mfg{display:flex;flex-direction:column;gap:5px;margin-bottom:14px}
.mfg label{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.mfg input,.mfg select{border:1.5px solid var(--border);border-radius:9px;padding:9px 12px;font-family:'Outfit',sans-serif;font-size:13.5px;color:var(--ink);background:var(--surface);outline:none;transition:border .18s;width:100%}
.mfg input:focus,.mfg select:focus{border-color:var(--blue);background:#fff}
.mfg-row{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.modal-foot{padding:14px 22px;border-top:1px solid var(--border);display:flex;justify-content:flex-end;gap:8px}
.btn-cancel{padding:8px 18px;background:var(--surface);color:var(--muted);border:1.5px solid var(--border);border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;cursor:pointer;transition:all .18s}
.btn-cancel:hover{border-color:var(--muted)}
.btn-save{padding:8px 22px;background:linear-gradient(135deg,var(--blue),var(--cyan));color:#fff;border:none;border-radius:8px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;box-shadow:0 3px 10px rgba(21,88,168,.2);transition:all .18s}
.btn-save:hover{opacity:.9}
.field-hint{font-size:11px;color:var(--muted);margin-top:3px}
.field-err{font-size:11px;color:var(--red);margin-top:3px;display:none}

/* Toast */
.toast{position:fixed;top:18px;right:22px;padding:11px 18px;border-radius:10px;font-size:13px;font-weight:700;color:#fff;z-index:9999;display:flex;align-items:center;gap:8px;box-shadow:0 4px 18px rgba(0,0,0,.15);animation:slideIn .3s ease}
.toast-ok{background:var(--green)}.toast-err{background:var(--red)}.toast-warn{background:var(--gold)}.toast-info{background:var(--blue)}
@keyframes slideIn{from{transform:translateX(120%);opacity:0}to{transform:translateX(0);opacity:1}}

/* ── WEEK BODY SIMPLE ────────────────────────── */
.week-body-simple{display:grid;grid-template-columns:repeat(7,1fr);gap:0}
.day-col-simple{border-right:1px solid var(--border);padding:6px;min-height:200px;position:relative;display:flex;flex-direction:column;gap:4px}
.day-col-simple:last-child{border-right:none}
.day-col-simple.today-col{background:rgba(21,88,168,.02)}

/* Empty state */
.empty-state{text-align:center;padding:48px 20px;color:var(--muted)}
.empty-state .es-icon{font-size:40px;margin-bottom:12px;display:block}
.empty-state h3{font-size:15px;font-weight:700;color:var(--ink);margin-bottom:6px}
.empty-state p{font-size:13px}
</style>
</head>
<body>

<%-- ── SIDEBAR ── --%>
<aside class="sidebar">
  <div class="sidebar-logo">
    <div class="logo-icon">💊</div>
    <div>
      <div class="logo-text">Medi<span>Vault</span></div>
      <div class="logo-sub">Admin Console</div>
    </div>
  </div>
  <nav>
    <div class="nav-section">
      <div class="nav-label">Tổng quan</div>
      <a href="${pageContext.request.contextPath}/dashboard" class="nav-item">🏠 Trang chủ</a>
    </div>
    <div class="nav-section">
      <div class="nav-label">Quản lý</div>
      <a href="${pageContext.request.contextPath}/accounts" class="nav-item">👥 Tài khoản</a>
      <a href="${pageContext.request.contextPath}/shifts" class="nav-item active">🕐 Ca làm việc</a>
      <a href="${pageContext.request.contextPath}/medicines" class="nav-item">💊 Kho thuốc</a>
      <a href="${pageContext.request.contextPath}/invoices" class="nav-item">🧾 Hóa đơn</a>
      <a href="${pageContext.request.contextPath}/customers" class="nav-item">🛒 Khách hàng</a>
    </div>
    <div class="nav-section">
      <div class="nav-label">Phân tích</div>
      <a href="${pageContext.request.contextPath}/audit-logs" class="nav-item">📋 Nhật ký</a>
    </div>
  </nav>
  <div class="sidebar-footer">
    <div class="sidebar-user">
      <div class="user-av"><%= initials %></div>
      <div>
        <div class="user-name"><%= fullName %></div>
        <div class="user-role">Admin</div>
      </div>
      <a href="${pageContext.request.contextPath}/logout" class="logout-btn" title="Đăng xuất">⏻</a>
    </div>
  </div>
</aside>

<%-- ── MAIN ── --%>
<div class="main">

  <%-- Toast --%>
  <c:if test="${not empty param.msg}">
    <c:choose>
      <c:when test="${param.msg == 'opened'}">       <div class="toast toast-ok"   id="toast">✅ Mở ca thành công!</div></c:when>
      <c:when test="${param.msg == 'closed'}">       <div class="toast toast-ok"   id="toast">✅ Đóng ca thành công!</div></c:when>
      <c:when test="${param.msg == 'force-closed'}"> <div class="toast toast-info" id="toast">🔒 Admin đã đóng ca.</div></c:when>
      <c:when test="${param.msg == 'deleted'}">      <div class="toast toast-ok"   id="toast">🗑️ Xóa ca thành công!</div></c:when>
      <c:when test="${param.msg == 'delete-failed'}"><div class="toast toast-err"  id="toast">❌ Không thể xóa — ca đã có hóa đơn liên kết!</div></c:when>
      <c:when test="${param.msg == 'already-open'}"> <div class="toast toast-warn" id="toast">⚠️ Nhân viên đang có ca chưa đóng!</div></c:when>
      <c:when test="${param.msg == 'type-saved'}">   <div class="toast toast-ok"   id="toast">✅ Lưu loại ca thành công!</div></c:when>
      <c:when test="${param.msg == 'type-deleted'}"> <div class="toast toast-ok"   id="toast">🗑️ Xóa loại ca thành công!</div></c:when>
      <c:when test="${param.msg == 'type-err'}">     <div class="toast toast-err"  id="toast">❌ Lỗi khi lưu loại ca!</div></c:when>
      <c:otherwise>                                  <div class="toast toast-err"  id="toast">⚠️ Có lỗi xảy ra.</div></c:otherwise>
    </c:choose>
  </c:if>

  <%-- Topbar --%>
  <header class="topbar">
    <div class="topbar-left">
      <div class="topbar-icon">🕐</div>
      <div>
        <div class="topbar-title">Ca làm việc</div>
      </div>
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
        <div>
          <div class="kpi-num">${totalCount}</div>
          <div class="kpi-lbl">Tổng ca</div>
        </div>
      </div>
      <div class="kpi">
        <div class="kpi-icon kpi-green">🟢</div>
        <div>
          <div class="kpi-num" style="color:var(--green)">${openCount}</div>
          <div class="kpi-lbl">Đang mở</div>
          <div class="kpi-sub">Hôm nay</div>
        </div>
      </div>
      <div class="kpi">
        <div class="kpi-icon kpi-amber">⚠️</div>
        <div>
          <div class="kpi-num" style="color:var(--gold)">${forceClosedCount}</div>
          <div class="kpi-lbl">Đóng muộn</div>
        </div>
      </div>
      <div class="kpi">
        <div class="kpi-icon kpi-purple">👥</div>
        <div>
          <div class="kpi-num" style="color:var(--purple)">${fn:length(allStaff)}</div>
          <div class="kpi-lbl">Nhân viên</div>
        </div>
      </div>
    </div>

    <%-- Tab bar --%>
    <div class="tab-bar">
      <button class="tab-btn <%= "schedule".equals(activeTab) ? "active" : "" %>"
              onclick="switchTab('schedule')">📅 Lịch ca</button>
      <button class="tab-btn <%= "list".equals(activeTab) ? "active" : "" %>"
              onclick="switchTab('list')">📋 Danh sách ca</button>
      <button class="tab-btn <%= "types".equals(activeTab) ? "active" : "" %>"
              onclick="switchTab('types')">⚙️ Loại ca</button>
    </div>

    <%-- ═══════════════════════════════════════════════ --%>
    <%-- TAB 1: LỊCH CA (Timeline tuần/tháng)          --%>
    <%-- ═══════════════════════════════════════════════ --%>
    <div id="tab-schedule" class="tab-pane <%= "schedule".equals(activeTab) ? "active" : "" %>">

      <div class="schedule-header">
        <div class="schedule-nav">
          <a href="${pageContext.request.contextPath}/shifts?tab=schedule&w=-1" class="nav-arrow">‹</a>
          <span class="nav-period" id="periodLabel">Tuần này</span>
          <a href="${pageContext.request.contextPath}/shifts?tab=schedule&w=1"  class="nav-arrow">›</a>
          <a href="${pageContext.request.contextPath}/shifts?tab=schedule" class="btn-today">Hôm nay</a>
        </div>
        <div style="display:flex;align-items:center;gap:12px">
          <!-- Legend -->
          <div class="legend">
            <div class="leg-item"><div class="leg-dot" style="background:var(--ca-long)"></div>Ca dài ≥10h</div>
            <div class="leg-item"><div class="leg-dot" style="background:var(--ca-std)"></div>Ca 8h</div>
            <div class="leg-item"><div class="leg-dot" style="background:var(--ca-part)"></div>Part-time</div>
            <div class="leg-item"><div class="leg-dot" style="background:var(--ca-open)"></div>Đang làm</div>
            <div class="leg-item"><div class="leg-dot" style="background:var(--ca-absent)"></div>Vắng</div>
          </div>
          <!-- View toggle -->
          <div class="view-toggle">
            <button class="vt-btn active" id="btnWeek" onclick="setView('week')">Tuần</button>
            <button class="vt-btn" id="btnMonth" onclick="setView('month')">Tháng</button>
          </div>
        </div>
      </div>

      <%-- WEEK VIEW --%>
      <div id="viewWeek">
        <div class="week-grid">
          <%-- Header: giờ + 7 ngày --%>
          <div class="week-header">
            <div class="week-hcol" style="font-size:10px">GIỜ</div>
            <c:forEach var="day" items="${weekDays}" varStatus="st">
              <div class="week-hcol ${day.equals(today) ? 'today-col' : ''}">
                <span style="font-size:10px">${weekDayNames[st.index]}</span>
                <span class="day-num">${day.dayOfMonth}</span>
                <span style="font-size:9px;color:var(--muted)">${day.monthValue}/${day.year}</span>
              </div>
            </c:forEach>
          </div>

          <%-- Body: 7 cột ngày — dạng card đơn giản --%>
          <div class="week-body-simple">
            <c:forEach var="day" items="${weekDays}" varStatus="dst">
              <div class="day-col-simple ${day.equals(today) ? 'today-col' : ''}">
                <%-- Shift cards cho ngày này --%>
                <c:set var="hasSched" value="false"/>
                <c:forEach var="sch" items="${schedules}">
                  <c:if test="${sch.workDate.equals(day)}">
                    <c:set var="hasSched" value="true"/>
                    <c:set var="caClass" value="ca-std"/>
                    <c:if test="${sch.status == 'ABSENT'}"><c:set var="caClass" value="ca-absent"/></c:if>
                    <c:if test="${sch.status == 'ON_LEAVE'}"><c:set var="caClass" value="ca-leave"/></c:if>
                    <div class="shift-block ${caClass}"
                         onclick="location.href='${pageContext.request.contextPath}/shift-schedules?action=detail&id=${sch.scheduleId}'"
                         title="${sch.staffName}">
                      <div class="sb-name">${sch.staffName}</div>
                      <div class="sb-time">
                        <c:if test="${not empty sch.plannedStart}">${fn:substring(sch.plannedStart.toString(),11,16)}</c:if>
                        <c:if test="${not empty sch.plannedEnd}">–${fn:substring(sch.plannedEnd.toString(),11,16)}</c:if>
                      </div>
                      <c:if test="${not empty sch.openingCash and sch.openingCash > 0}">
                        <div class="sb-cash">💰<fmt:formatNumber value="${sch.openingCash}" type="number" maxFractionDigits="0"/>đ</div>
                      </c:if>
                    </div>
                  </c:if>
                </c:forEach>
                <c:if test="${hasSched == 'false'}">
                  <div style="padding:8px;text-align:center;font-size:11px;color:var(--muted)">Chưa có ca</div>
                </c:if>
                <a href="${pageContext.request.contextPath}/shift-schedules?action=new&date=${day}"
                   class="add-shift-btn" title="Xếp ca">+</a>
              </div>
            </c:forEach>
          </div>
        </div>
      </div>

      <%-- MONTH VIEW --%>
      <div id="viewMonth" style="display:none">
        <div class="month-grid">
          <div class="month-weekdays">
            <div class="mw-head">T2</div><div class="mw-head">T3</div><div class="mw-head">T4</div>
            <div class="mw-head">T5</div><div class="mw-head">T6</div>
            <div class="mw-head" style="color:var(--amber)">T7</div>
            <div class="mw-head" style="color:var(--red)">CN</div>
          </div>
          <div class="month-body" id="monthBody">
            <%-- Month view hiển thị danh sách ca theo ngày --%>
            <c:forEach var="sch" items="${schedules}">
              <div class="mc-shift ca-std"
                   onclick="location.href='${pageContext.request.contextPath}/shift-schedules?action=detail&id=${sch.scheduleId}'"
                   title="${sch.staffName} — ${sch.workDate}">
                ${sch.staffName} (${fn:substring(sch.workDate.toString(),8,10)}/${fn:substring(sch.workDate.toString(),5,7)})
              </div>
            </c:forEach>
            <c:if test="${empty schedules}">
              <div style="padding:20px;text-align:center;color:var(--muted);font-size:13px">
                Chưa có lịch ca nào trong tuần này
              </div>
            </c:if>
          </div>
        </div>
      </div>

    </div><%-- end tab-schedule --%>

    <%-- ═══════════════════════════════════════════════ --%>
    <%-- TAB 2: DANH SÁCH CA (form mở + bảng)          --%>
    <%-- ═══════════════════════════════════════════════ --%>
    <div id="tab-list" class="tab-pane <%= "list".equals(activeTab) ? "active" : "" %>">

      <div class="list-layout">
        <%-- Form mở ca tự do (admin) --%>
        <div class="open-panel">
          <div class="open-panel-head">
            <span>➕</span>
            <h3>Mở ca mới cho nhân viên</h3>
          </div>
          <div class="open-panel-body">
            <form method="post" action="${pageContext.request.contextPath}/shifts">
              <input type="hidden" name="action" value="open">
              <div class="fg">
                <label>Nhân viên</label>
                <select name="accountId" required>
                  <option value="">-- Chọn nhân viên --</option>
                  <c:forEach var="staff" items="${allStaff}">
                    <option value="${staff.accountId}">${staff.fullName}</option>
                  </c:forEach>
                </select>
              </div>
              <div class="fg">
                <label>Tiền đầu ca (VNĐ)</label>
                <input type="number" name="openingCash" min="50000" step="1000"
                       placeholder="Tối thiểu 50,000đ" value="50000"
                       oninput="validateCash(this)">
                <span class="field-err" id="cashErr">⚠️ Tối thiểu 50,000đ</span>
              </div>
              <button type="submit" class="btn-open">🚀 Mở ca</button>
            </form>
          </div>
        </div>

        <%-- Filter --%>
        <div class="filter-panel">
          <div class="filter-panel-head"><span>🔍</span><h3>Lọc danh sách</h3></div>
          <div class="filter-body">
            <form method="get" action="${pageContext.request.contextPath}/shifts">
              <input type="hidden" name="tab" value="list">
              <div class="filter-grid">
                <div class="fi"><label>Từ ngày</label><input type="date" name="from" value="${filterFrom}"></div>
                <div class="fi"><label>Đến ngày</label><input type="date" name="to"   value="${filterTo}"></div>
                <div class="fi">
                  <label>Nhân viên</label>
                  <select name="accountId">
                    <option value="">-- Tất cả --</option>
                    <c:forEach var="s" items="${allStaff}">
                      <option value="${s.accountId}" ${filterAcc == s.accountId ? 'selected' : ''}>${s.fullName}</option>
                    </c:forEach>
                  </select>
                </div>
                <div class="fi">
                  <label>Trạng thái</label>
                  <select name="status">
                    <option value="" ${empty filterStatus ? 'selected' : ''}>-- Tất cả --</option>
                    <option value="open"        ${'open'        == filterStatus ? 'selected' : ''}>Đang mở</option>
                    <option value="closed"      ${'closed'      == filterStatus ? 'selected' : ''}>Đã đóng</option>
                    <option value="force-closed" ${'force-closed' == filterStatus ? 'selected' : ''}>Đóng muộn</option>
                  </select>
                </div>
              </div>
              <div class="filter-actions">
                <button type="submit" class="btn-filter">🔍 Lọc</button>
                <a href="${pageContext.request.contextPath}/shifts?tab=list" class="btn-reset">↺ Reset</a>
              </div>
            </form>
          </div>
        </div>
      </div>

      <%-- Bảng danh sách ca --%>
      <div class="table-card">
        <div class="table-card-head">
          <h2>📋 Danh sách ca làm việc</h2>
          <span class="table-card-sub">${totalCount} ca — mới nhất trước</span>
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
            <tbody>
              <c:if test="${empty shifts}">
                <tr><td colspan="9">
                  <div class="empty-state">
                    <span class="es-icon">🕐</span>
                    <h3>Chưa có ca nào</h3>
                    <p>Mở ca mới hoặc điều chỉnh bộ lọc</p>
                  </div>
                </td></tr>
              </c:if>
              <c:forEach var="s" items="${shifts}">
                <c:set var="staff" value="${accountMap[s.accountId]}"/>
                <c:set var="ini"   value="${not empty staff ? fn:substring(staff.fullName,0,1) : '?'}"/>
                <tr onclick="location.href='${pageContext.request.contextPath}/shifts?action=detail&id=${s.shiftId}'" style="cursor:pointer">
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
                    <div class="time-main">
                      <c:if test="${not empty s.startTime}">${fn:substring(s.startTime.toString(),11,16)}</c:if>
                    </div>
                    <div class="time-date">
                      <c:if test="${not empty s.startTime}">${fn:substring(s.startTime.toString(),0,10)}</c:if>
                    </div>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${not empty s.endTime}">
                        <div class="time-main">${fn:substring(s.endTime.toString(),11,16)}</div>
                        <div class="time-date">${fn:substring(s.endTime.toString(),0,10)}</div>
                      </c:when>
                      <c:otherwise>
                        <span class="dur-active">⏱️ Đang làm</span>
                      </c:otherwise>
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
                      <c:when test="${s.open}">        <span class="badge badge-open">🟢 Đang mở</span></c:when>
                      <c:when test="${s.closed}">      <span class="badge badge-closed">✔ Đã đóng</span></c:when>
                      <c:when test="${s.forceClose}">  <span class="badge badge-force">🔒 Đóng muộn</span></c:when>
                      <c:otherwise>                   <span class="badge badge-closed">• ${s.status}</span></c:otherwise>
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

    <%-- ═══════════════════════════════════════════════ --%>
    <%-- TAB 3: LOẠI CA (ShiftType CRUD)               --%>
    <%-- ═══════════════════════════════════════════════ --%>
    <div id="tab-types" class="tab-pane <%= "types".equals(activeTab) ? "active" : "" %>">

      <div class="types-header">
        <div>
          <h2>⚙️ Loại ca làm việc</h2>
          <p style="font-size:12.5px;color:var(--muted);margin-top:4px">
            Quản lý các ca mẫu — Ca sáng, Ca chiều, Ca part-time...
          </p>
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
              <span class="type-badge ${st.active ? 'type-active' : 'type-inactive'}">
                ${st.active ? '✅ Đang dùng' : '⏸ Tạm dừng'}
              </span>
            </div>
            <div class="type-card-body">
              <div class="type-row">
                <span class="type-lbl">🕐 Giờ làm</span>
                <span class="type-val">${st.startHour}:00 – ${st.endHour}:00</span>
              </div>
              <div class="type-row">
                <span class="type-lbl">💰 Lương giờ</span>
                <span class="type-val" style="color:var(--green)">
                  <fmt:formatNumber value="${st.hourlyRate}" type="number" maxFractionDigits="0"/>đ/h
                </span>
              </div>
              <c:if test="${st.allowanceAmount > 0}">
                <div class="type-row">
                  <span class="type-lbl">🎁 Phụ cấp</span>
                  <span class="type-val"><fmt:formatNumber value="${st.allowanceAmount}" type="number" maxFractionDigits="0"/>đ</span>
                </div>
              </c:if>
            </div>
            <div class="type-card-foot">
              <button class="btn-edit-type"
                      onclick="editType(${st.shiftTypeId},'${st.name}',${st.startHour},${st.startMinute},${st.endHour},${st.endMinute},${st.hourlyRate},${st.allowanceAmount})">
                ✏️ Sửa
              </button>
              <button class="btn-toggle-type"
                      onclick="toggleType(${st.shiftTypeId},${st.active})">
                ${st.active ? '⏸ Tạm dừng' : '▶️ Kích hoạt'}
              </button>
              <c:if test="${!st.active}">
                <button class="btn-del-type"
                        onclick="deleteType(${st.shiftTypeId},'${st.name}')">
                  🗑
                </button>
              </c:if>
            </div>
          </div>
        </c:forEach>
      </div>
    </div><%-- end tab-types --%>

  </div><%-- end content --%>
</div><%-- end main --%>

<%-- ── MODAL: Thêm/Sửa loại ca ── --%>
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
          <input type="text" name="name" id="typeName" placeholder="Ví dụ: Ca sáng Long Châu" required>
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
        <div id="durPreview" style="font-size:12px;color:var(--muted);margin:-8px 0 14px;padding:6px 10px;background:var(--surface);border-radius:7px"></div>

        <div class="mfg">
          <label>Lương theo giờ (VNĐ) *</label>
          <input type="number" name="hourlyRate" id="typeRate" min="50000" step="1000"
                 placeholder="Tối thiểu 50,000đ" required value="60000"
                 oninput="validateRate(this)">
          <span class="field-err" id="rateErr">⚠️ Tối thiểu 50,000đ/giờ</span>
          <span class="field-hint">Tổng lương ca sẽ được tính tự động</span>
        </div>

        <div class="mfg">
          <label>Phụ cấp ca (VNĐ)</label>
          <input type="number" name="allowanceAmount" id="typeAllowance" min="0" step="1000" value="0" placeholder="0">
          <span class="field-hint">Thêm vào ngoài lương giờ (không bắt buộc)</span>
        </div>
      </form>
    </div>
    <div class="modal-foot">
      <button class="btn-cancel" onclick="closeTypeModal()">Hủy</button>
      <button class="btn-save" onclick="submitTypeForm()">💾 Lưu loại ca</button>
    </div>
  </div>
</div>

<script>
// ── Tab switching ─────────────────────────────────────────────
function switchTab(tab) {
  document.querySelectorAll('.tab-pane').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
  document.getElementById('tab-' + tab).classList.add('active');
  event.currentTarget.classList.add('active');
}

// ── Week/Month view toggle ────────────────────────────────────
function setView(v) {
  document.getElementById('viewWeek').style.display  = v === 'week'  ? '' : 'none';
  document.getElementById('viewMonth').style.display = v === 'month' ? '' : 'none';
  document.getElementById('btnWeek').classList.toggle('active', v==='week');
  document.getElementById('btnMonth').classList.toggle('active', v==='month');
}

// ── Duration preview in modal ─────────────────────────────────
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
  p.innerHTML = `${caType} &nbsp;|&nbsp; ⏱ ${dur.toFixed(1)} tiếng &nbsp;|&nbsp; 💰 Tổng lương: <strong>${total.toLocaleString('vi')}đ</strong>`;
}
document.getElementById('typeStartTime').addEventListener('input', updateDurPreview);
document.getElementById('typeEndTime').addEventListener('input', updateDurPreview);
document.getElementById('typeRate').addEventListener('input', updateDurPreview);

// ── Validate ─────────────────────────────────────────────────
function validateRate(el) {
  const err = document.getElementById('rateErr');
  if (parseInt(el.value) < 50000) { err.style.display='block'; el.style.borderColor='var(--red)'; }
  else { err.style.display='none'; el.style.borderColor=''; }
  updateDurPreview();
}
function validateCash(el) {
  const err = document.getElementById('cashErr');
  if (parseInt(el.value) < 50000) { err.style.display='block'; el.style.borderColor='var(--red)'; }
  else { err.style.display='none'; el.style.borderColor=''; }
}

// ── Modal ─────────────────────────────────────────────────────
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
function closeTypeModal() {
  document.getElementById('typeModal').classList.remove('open');
}
document.getElementById('typeModal').addEventListener('click', function(e) {
  if (e.target === this) closeTypeModal();
});
function submitTypeForm() {
  const rate = parseInt(document.getElementById('typeRate').value);
  if (rate < 50000) { validateRate(document.getElementById('typeRate')); return; }
  document.getElementById('typeForm').submit();
}
function toggleType(id, active) {
  if (confirm(active ? 'Tạm dừng loại ca này?' : 'Kích hoạt lại loại ca này?')) {
    const f = document.createElement('form');
    f.method = 'post';
    f.action = '${pageContext.request.contextPath}/shift-types';
    f.innerHTML = '<input name="action" value="toggle"><input name="shiftTypeId" value="'+id+'">';
    document.body.appendChild(f); f.submit();
  }
}
function deleteType(id, name) {
  if (confirm('Xóa loại ca "'+name+'"?\nChỉ xóa được khi không còn lịch ca nào dùng loại này.')) {
    location.href = '${pageContext.request.contextPath}/shift-types?action=delete&id=' + id;
  }
}

// ── Toast auto-hide ───────────────────────────────────────────
const toast = document.getElementById('toast');
if (toast) setTimeout(() => { toast.style.opacity='0'; toast.style.transition='opacity .5s'; setTimeout(()=>toast.remove(),500); }, 3500);

// ── Period label ──────────────────────────────────────────────
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
</script>
</body>
</html>
