<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<% String activeNav = "task-management"; %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length()>=2 ? fullName.substring(0,1).toUpperCase()+fullName.substring(1,2).toUpperCase() : fullName.toUpperCase();
    java.time.LocalDate today = java.time.LocalDate.now();
    String[] vnDow = {"Thứ Hai","Thứ Ba","Thứ Tư","Thứ Năm","Thứ Sáu","Thứ Bảy","Chủ Nhật"};
    String todayDisplay = vnDow[today.getDayOfWeek().getValue()-1] + ", " + today.format(java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy"));
%>
<!DOCTYPE html><html lang="vi"><head>
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Lora:wght@600;700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Task Management — MediCare</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;--surface:#F1F5FB;--white:#fff;--muted:#7A90B0;
  --border:#D5E0F0;--green:#059669;--red:#DC2626;--amber:#F59E0B;--sidebar:232px;--radius:16px}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif;background:var(--surface);color:var(--ink)}
body{display:flex}
a{text-decoration:none;color:inherit}
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06)}
.logo-icon{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:16px}
.logo-text{font-size:16px;font-weight:800;color:#fff}.logo-text span{color:var(--cyan)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:12px 0 4px}.nav-label{font-size:9px;font-weight:750;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:750;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.14);font-weight:750}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--cyan);border-radius:2px}
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06)}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08)}
.user-av{width:34px;height:34px;border-radius:9px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.user-name{font-size:12.5px;font-weight:750;color:#fff;max-width:110px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.user-role{font-size:10px;color:rgba(255,255,255,.35);margin-top:1px}
.logout-btn{margin-left:auto;width:28px;height:28px;border-radius:8px;background:rgba(220,38,38,.12);border:none;display:flex;align-items:center;justify-content:center;color:rgba(220,38,38,.7);font-size:13px;cursor:pointer;text-decoration:none}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:150}
.topbar-title{font-size:16px;font-weight:750;color:var(--ink)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.content{padding:22px 26px 40px;flex:1;min-width:0}

.toast{position:fixed;top:20px;right:24px;padding:12px 20px;border-radius:11px;font-size:13px;font-weight:750;color:#fff;z-index:9999;display:flex;align-items:center;gap:8px;box-shadow:0 4px 20px rgba(0,0,0,.15);animation:slideIn .3s ease}
.toast-ok{background:#059669}.toast-err{background:#7f1d1d}
@keyframes slideIn{from{transform:translateX(60px);opacity:0}to{transform:translateX(0);opacity:1}}
.toast-mini{position:fixed;left:50%;bottom:26px;transform:translateX(-50%);background:var(--navy);color:#fff;padding:10px 18px;
  border-radius:12px;font-size:12.5px;font-weight:700;z-index:9998;box-shadow:0 8px 24px rgba(0,0,0,.2);opacity:0;transition:opacity .25s}
.toast-mini.show{opacity:1}

/* ══ HEADER ══ */
.tm-header{display:flex;align-items:flex-start;justify-content:space-between;gap:16px;flex-wrap:wrap;margin-bottom:18px}
.tm-header h1{font-family:'Lora',serif;font-size:25px;font-weight:700;color:var(--ink)}
.tm-header p{font-size:12.5px;color:var(--muted);margin-top:4px;max-width:560px;line-height:1.5}
.tm-actions{display:flex;align-items:center;gap:10px;flex-wrap:wrap}
.tm-search{position:relative}
.tm-search input{width:220px;height:38px;padding:0 12px 0 34px;border:1.5px solid var(--border);border-radius:10px;
  font-family:inherit;font-size:13px;background:#fff;outline:none}
.tm-search input:focus{border-color:var(--blue)}
.tm-search::before{content:'🔍';position:absolute;left:11px;top:50%;transform:translateY(-50%);font-size:12px;opacity:.6}
.tm-btn{height:38px;padding:0 14px;border-radius:10px;border:1.5px solid var(--border);background:#fff;color:var(--navy);
  font-family:inherit;font-size:12.5px;font-weight:750;cursor:pointer;display:inline-flex;align-items:center;gap:6px;transition:all .15s}
.tm-btn:hover{border-color:var(--blue);color:var(--blue)}
.tm-btn.active{background:#EFF6FF;border-color:var(--blue);color:var(--blue)}
.tm-date-chip{height:38px;padding:0 14px;border-radius:10px;background:var(--surface);border:1.5px solid var(--border);
  display:flex;align-items:center;font-size:12.5px;font-weight:750;color:var(--navy)}
.btn-primary{height:38px;padding:0 18px;border-radius:10px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;
  font-family:inherit;font-size:13px;font-weight:750;cursor:pointer;display:inline-flex;align-items:center;gap:6px}
.btn-primary:hover{filter:brightness(1.06)}

.tm-filter-panel{display:none;gap:12px;flex-wrap:wrap;align-items:flex-end;background:#fff;border:1px solid var(--border);
  border-radius:12px;padding:14px 16px;margin-bottom:16px}
.tm-filter-panel.show{display:flex}
.tm-filter-panel .fi{display:flex;flex-direction:column;gap:4px}
.tm-filter-panel label{font-size:10.5px;font-weight:750;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.tm-filter-panel select{height:34px;padding:0 10px;border:1.5px solid var(--border);border-radius:8px;font-family:inherit;font-size:12.5px;background:var(--surface)}

/* ══ SUMMARY CARDS ══ */
.tm-summary-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(150px,1fr));gap:12px;margin-bottom:20px}
.tm-card{background:#fff;border:1px solid rgba(213,224,240,.5);border-radius:var(--radius);padding:15px 16px;
  box-shadow:0 1px 3px rgba(15,38,69,.03),0 4px 12px rgba(15,38,69,.04);transition:transform .18s,box-shadow .18s;position:relative;overflow:hidden}
.tm-card:hover{transform:translateY(-2px);box-shadow:0 8px 22px rgba(15,38,69,.09)}
.tm-card .ic{width:30px;height:30px;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:14px;margin-bottom:8px}
.tm-card .n{font-family:'Lora',serif;font-size:23px;font-weight:700;color:var(--ink);font-variant-numeric:tabular-nums}
.tm-card .l{font-size:11px;color:var(--muted);font-weight:650;margin-top:2px}
.tm-card.c-blue .ic{background:#EFF6FF;color:var(--blue)}
.tm-card.c-cyan .ic{background:#ECFEFF;color:#0891B2}
.tm-card.c-amber .ic{background:#FFFBEB;color:#B45309}
.tm-card.c-red .ic,.tm-card.c-red .n{color:var(--red)}.tm-card.c-red .ic{background:#FEF2F2}
.tm-card.c-green .ic,.tm-card.c-green .n{color:var(--green)}.tm-card.c-green .ic{background:#ECFDF5}
.tm-card.c-purple .ic{background:#F5F3FF;color:#7C3AED}

/* ══ MAIN GRID (Kanban + Right Sidebar) ══ */
.tm-main-grid{display:grid;grid-template-columns:1fr 300px;gap:18px;align-items:start}
@media(max-width:1180px){.tm-main-grid{grid-template-columns:1fr}}

.tm-kanban-wrap{background:#fff;border:1px solid rgba(213,224,240,.5);border-radius:var(--radius);
  box-shadow:0 1px 3px rgba(15,38,69,.03),0 4px 12px rgba(15,38,69,.04);overflow:hidden}
.tm-kanban-head{padding:14px 18px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
.tm-kanban-head h2{font-size:14px;font-weight:800;color:var(--ink)}
.tm-kanban-scroll{display:flex;gap:14px;overflow-x:auto;padding:16px;scroll-behavior:smooth}
.kb-col{flex:0 0 250px;background:#F8FAFC;border:1px solid var(--border);border-radius:12px;padding:10px;display:flex;flex-direction:column;
  max-height:640px;transition:background .15s}
.kb-col.drag-over{background:#EFF6FF;border-color:var(--blue)}
.kb-col-head{display:flex;align-items:center;gap:6px;padding:4px 4px 10px;flex:none}
.kb-col-dot{width:8px;height:8px;border-radius:50%;flex:none}
.kb-col-name{font-size:11.5px;font-weight:800;text-transform:uppercase;letter-spacing:.4px;color:var(--navy)}
.kb-col-count{margin-left:auto;font-size:10.5px;font-weight:750;color:var(--muted);background:#fff;border:1px solid var(--border);
  padding:1px 8px;border-radius:20px}
.kb-col-body{overflow-y:auto;flex:1;padding-right:2px;min-height:60px}
.kb-empty{font-size:11.5px;color:var(--muted);font-style:italic;padding:14px 6px;text-align:center}

.kb-card{background:#fff;border:1px solid var(--border);border-left:3.5px solid var(--border);border-radius:11px;padding:11px 12px;
  margin-bottom:8px;box-shadow:0 1px 2px rgba(15,38,69,.04);cursor:grab;transition:transform .15s,box-shadow .15s;position:relative}
.kb-card:hover{transform:translateY(-2px);box-shadow:0 6px 18px rgba(15,38,69,.12)}
.kb-card.dragging{opacity:.35}
.kb-card.p-high{border-left-color:#EA580C}
.kb-card.p-critical{border-left-color:var(--red)}
.kb-card.p-medium{border-left-color:var(--blue)}
.kb-card.p-low{border-left-color:#94A3B8}
.kb-card.st-done{border-left-color:var(--green)}
.kb-title{font-size:12.5px;font-weight:750;color:var(--ink);line-height:1.4;margin-bottom:6px}
.kb-badges{display:flex;flex-wrap:wrap;gap:4px;margin-bottom:7px}
.mini-badge{font-size:9.5px;font-weight:800;padding:2px 7px;border-radius:20px;white-space:nowrap;letter-spacing:.2px}
.mb-high{background:#FFF7ED;color:#C2410C}.mb-medium{background:#EFF6FF;color:#1558A8}.mb-low{background:#F1F5F9;color:#64748B}
.mb-module{background:#F5F3FF;color:#7C3AED}
.mb-zone-overdue{background:#FEF2F2;color:#991B1B}.mb-zone-critical{background:#FFF7ED;color:#C2410C}.mb-zone-warning{background:#FFFBEB;color:#92400E}
.mb-zone-safe{background:#ECFDF5;color:#065F46}
.mb-ontime{background:#ECFDF5;color:#065F46}.mb-late{background:#FFF7ED;color:#92400E}
.kb-meta-row{display:flex;align-items:center;justify-content:space-between;gap:6px;margin-top:6px}
.kb-avatar{width:22px;height:22px;border-radius:7px;background:linear-gradient(135deg,var(--cyan),var(--blue));color:#fff;
  font-size:9.5px;font-weight:800;display:flex;align-items:center;justify-content:center;flex:none}
.kb-avatar.unassigned{background:#E2E8F0;color:#64748B}
.kb-due{font-size:10.5px;color:var(--muted);font-weight:650}
.kb-progress{height:5px;border-radius:20px;background:var(--border);overflow:hidden;margin-top:8px}
.kb-progress-fill{height:100%;background:linear-gradient(90deg,var(--blue),var(--cyan));border-radius:20px;transition:width .4s ease}
.kb-icons-row{display:flex;gap:8px;margin-top:7px;font-size:10.5px;color:var(--muted);align-items:center}
.kb-icons-row span{display:flex;align-items:center;gap:2px}

/* ══ RIGHT SIDEBAR ══ */
.tm-sidebar{display:flex;flex-direction:column;gap:14px}
.tm-side-card{background:#fff;border:1px solid rgba(213,224,240,.5);border-radius:var(--radius);padding:14px 16px;
  box-shadow:0 1px 3px rgba(15,38,69,.03),0 4px 12px rgba(15,38,69,.04)}
.tm-side-card h3{font-size:12px;font-weight:800;color:var(--navy);margin-bottom:10px;display:flex;align-items:center;gap:6px}
.tm-side-row{display:flex;align-items:center;gap:8px;padding:6px 0;border-bottom:1px solid #F4F7FC;font-size:11.5px}
.tm-side-row:last-child{border-bottom:none}
.tm-side-row .nm{flex:1;color:var(--ink);font-weight:650;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.tm-side-row .sub{color:var(--muted);font-size:10.5px}
.tm-side-empty{font-size:11.5px;color:var(--muted);padding:6px 0}

/* ══ ANALYTICS ══ */
.tm-section-title{font-size:14px;font-weight:800;color:var(--ink);margin:24px 0 12px;display:flex;align-items:center;gap:8px}
.tm-analytics-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:14px}
.tm-chart-card{background:#fff;border:1px solid rgba(213,224,240,.5);border-radius:var(--radius);padding:16px;
  box-shadow:0 1px 3px rgba(15,38,69,.03),0 4px 12px rgba(15,38,69,.04)}
.tm-chart-card h4{font-size:12px;font-weight:800;color:var(--navy);margin-bottom:10px}
.tm-chart-card canvas{max-height:220px}
.tm-stat-callout{display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:220px}
.tm-stat-callout .big{font-family:'Lora',serif;font-size:38px;font-weight:700;color:var(--blue)}
.tm-stat-callout .sub{font-size:12px;color:var(--muted);margin-top:6px;text-align:center}

.table-card{background:#fff;border:1px solid rgba(213,224,240,.45);border-radius:var(--radius);overflow:hidden;margin-top:18px;box-shadow:0 1px 3px rgba(15,38,69,.03),0 4px 12px rgba(15,38,69,.04)}
.table-card-head{padding:14px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;gap:10px;flex-wrap:wrap}
.table-card-head h2{font-size:14px;font-weight:800;color:var(--ink);display:flex;align-items:center;gap:8px}
table{width:100%;border-collapse:collapse}
thead th{padding:9px 16px;background:#F8FAFC;font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;border-bottom:1px solid var(--border);white-space:nowrap}
tbody td{padding:11px 16px;font-size:13px;border-bottom:1px solid #F1F5F9;vertical-align:middle}
tbody tr:last-child td{border-bottom:none}tbody tr:hover td{background:#F7FBFF}
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:750;white-space:nowrap}
.badge-ontime{background:#ECFDF5;color:#065F46}.badge-late{background:#FFF7ED;color:#92400E}
.empty-box{padding:36px;text-align:center;color:var(--muted);font-size:13px}

/* Watchdog banner */
.alert-card{background:#FFFBEB;border:1px solid #FDE68A;border-radius:14px;padding:14px 20px;margin-bottom:18px}
.alert-card-top{display:flex;align-items:center;gap:14px}
.alert-icon{font-size:20px}
.alert-text strong{color:#92400E;font-size:13.5px;display:block}
.alert-text p{font-size:12.5px;color:#78350F;margin-top:2px}
.alert-list{margin-top:12px;padding-top:12px;border-top:1px solid #FDE68A;display:flex;flex-direction:column;gap:6px}
.alert-item{display:flex;align-items:center;justify-content:space-between;gap:10px;font-size:12.5px;color:#78350F}
.alert-item b{color:#92400E}

/* ══ DRAWER (New Task) ══ */
.tm-drawer-backdrop{position:fixed;inset:0;background:rgba(11,22,40,.42);z-index:400;opacity:0;visibility:hidden;transition:opacity .2s}
.tm-drawer-backdrop.open{opacity:1;visibility:visible}
.tm-drawer{position:fixed;top:0;right:0;bottom:0;width:min(480px,94vw);background:#fff;z-index:401;
  box-shadow:-14px 0 40px rgba(15,38,69,.18);transform:translateX(100%);transition:transform .26s cubic-bezier(.2,.8,.2,1);
  display:flex;flex-direction:column;overflow-y:auto}
.tm-drawer.open{transform:translateX(0)}
.tm-drawer-head{background:linear-gradient(135deg,var(--navy),var(--blue));padding:20px;color:#fff;position:sticky;top:0;z-index:2}
.tm-drawer-head-top{display:flex;align-items:center;justify-content:space-between}
.tm-drawer-head h3{font-size:16px;font-weight:800}
.tm-drawer-close{width:30px;height:30px;border-radius:9px;background:rgba(255,255,255,.14);border:none;color:#fff;font-size:14px;cursor:pointer}
.tm-drawer-close:hover{background:rgba(255,255,255,.24)}
.tm-drawer-body{padding:20px}
.type-toggle{display:flex;gap:8px;margin-bottom:18px}
.tt-btn{padding:8px 16px;border:1.5px solid var(--border);border-radius:9px;background:#fff;font-family:inherit;font-size:12.5px;font-weight:750;color:var(--muted);cursor:pointer;flex:1}
.tt-btn.active{border-color:var(--blue);background:#EFF6FF;color:var(--blue)}
.dsec{margin-bottom:18px}
.dsec-title{font-size:10.5px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.6px;margin-bottom:10px}
.fi{display:flex;flex-direction:column;gap:5px;margin-bottom:12px}
.fi label{font-size:11px;font-weight:750;color:var(--navy)}
.req{color:var(--red)}
.fi input,.fi select,.fi textarea{border:1.5px solid var(--border);border-radius:9px;padding:9px 12px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;color:var(--ink);background:var(--surface);outline:none;width:100%}
.fi textarea{min-height:70px;resize:vertical}
.fi input:focus,.fi select:focus,.fi textarea:focus{border-color:var(--blue);background:#fff;box-shadow:0 0 0 3px rgba(21,88,168,.1)}
.fi-row2{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.milestone-rows{display:flex;flex-direction:column;gap:8px;margin:10px 0}
.milestone-input-row{display:flex;gap:8px;align-items:center}
.milestone-input-row input[type=text]{flex:1}
.milestone-input-row input[type=datetime-local]{width:170px}
.ms-remove{background:none;border:none;color:var(--red);cursor:pointer;font-size:16px;flex:none}
.add-milestone{margin-top:4px;padding:7px 12px;border:1.5px dashed var(--border);border-radius:8px;background:none;color:var(--blue);font-family:inherit;font-size:12.5px;font-weight:700;cursor:pointer;width:100%}
details.adv{border:1px dashed var(--border);border-radius:10px;padding:10px 12px;margin-top:6px}
details.adv summary{font-size:11.5px;font-weight:750;color:var(--muted);cursor:pointer}
details.adv .fi{margin-top:10px}
.drawer-submit{width:100%;margin-top:6px}

/* ══ TASK DETAIL PANEL ══ */
.tm-detail-backdrop{position:fixed;inset:0;background:rgba(11,22,40,.42);z-index:400;opacity:0;visibility:hidden;transition:opacity .2s}
.tm-detail-backdrop.open{opacity:1;visibility:visible}
.tm-detail-panel{position:fixed;top:0;right:0;bottom:0;width:min(650px,96vw);background:#fff;z-index:401;
  box-shadow:-14px 0 40px rgba(15,38,69,.18);transform:translateX(100%);transition:transform .26s cubic-bezier(.2,.8,.2,1);
  display:flex;flex-direction:column;overflow-y:auto}
.tm-detail-panel.open{transform:translateX(0)}
.dp-head{background:linear-gradient(135deg,var(--navy),var(--blue));padding:22px;color:#fff;position:sticky;top:0;z-index:2}
.dp-head-top{display:flex;align-items:center;justify-content:space-between;margin-bottom:10px}
.dp-close{width:30px;height:30px;border-radius:9px;background:rgba(255,255,255,.14);border:none;color:#fff;font-size:14px;cursor:pointer}
.dp-close:hover{background:rgba(255,255,255,.24)}
.dp-title{font-size:18px;font-weight:800;line-height:1.35}
.dp-badges{display:flex;gap:6px;margin-top:10px;flex-wrap:wrap}
.dp-badge{font-size:10.5px;font-weight:800;padding:3px 10px;border-radius:20px;background:rgba(255,255,255,.16);color:#fff}
.dp-body{padding:22px;flex:1}
.dp-sec{margin-bottom:24px}
.dp-sec-title{font-size:11px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.6px;margin-bottom:12px;display:flex;align-items:center;gap:6px}
.dp-kv-card{background:var(--surface);border:1px solid var(--border);border-radius:14px;overflow:hidden}
.dp-kv-row{display:flex;justify-content:space-between;gap:14px;padding:10px 14px;border-bottom:1px solid rgba(213,224,240,.6)}
.dp-kv-row:last-child{border-bottom:none}
.dp-kv-k{font-size:12px;color:var(--muted);font-weight:650}
.dp-kv-v{font-size:12.5px;color:var(--ink);font-weight:750;text-align:right}
.dp-desc{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:12px 14px;font-size:12.5px;color:var(--ink);line-height:1.65;white-space:pre-wrap}
.dp-status-row{display:flex;gap:8px;flex-wrap:wrap}
.dp-status-btn{padding:7px 13px;border-radius:9px;border:1.5px solid var(--border);background:#fff;font-size:11.5px;font-weight:750;
  color:var(--navy);cursor:pointer;font-family:inherit}
.dp-status-btn:hover{border-color:var(--blue);color:var(--blue)}
.dp-status-btn.current{background:var(--navy);border-color:var(--navy);color:#fff}

.dp-checklist-item{display:flex;align-items:center;gap:10px;padding:8px 4px;border-bottom:1px solid #F4F7FC}
.dp-checklist-item:last-child{border-bottom:none}
.dp-checklist-item input[type=checkbox]{width:17px;height:17px;accent-color:var(--green);flex:none;cursor:pointer}
.dp-checklist-item span{flex:1;font-size:12.5px;color:var(--ink)}
.dp-checklist-item.done span{text-decoration:line-through;color:var(--muted)}
.dp-checklist-item .rm{background:none;border:none;color:var(--red);opacity:0;cursor:pointer;font-size:13px;transition:opacity .15s}
.dp-checklist-item:hover .rm{opacity:1}
.dp-checklist-progress{display:flex;align-items:center;gap:10px;margin-bottom:10px}
.dp-checklist-progress .kb-progress{flex:1;margin:0}
.dp-checklist-progress .pct{font-size:11.5px;font-weight:800;color:var(--navy)}
.dp-add-row{display:flex;gap:8px;margin-top:10px}
.dp-add-row input{flex:1;height:36px;padding:0 11px;border:1.5px solid var(--border);border-radius:9px;font-family:inherit;font-size:12.5px;outline:none}
.dp-add-row input:focus{border-color:var(--blue)}
.dp-add-row button{height:36px;padding:0 14px;border-radius:9px;border:none;background:var(--blue);color:#fff;font-size:12px;font-weight:750;cursor:pointer;font-family:inherit}

.dp-timeline{position:relative;padding-left:22px}
.dp-timeline::before{content:'';position:absolute;left:5px;top:6px;bottom:6px;width:2px;background:var(--border)}
.dp-tl-node{position:relative;padding-bottom:18px}
.dp-tl-node:last-child{padding-bottom:0}
.dp-tl-dot{position:absolute;left:-22px;top:2px;width:12px;height:12px;border-radius:50%;background:var(--blue);border:2px solid #fff;box-shadow:0 0 0 2px var(--blue)}
.dp-tl-dot.done{background:var(--green);box-shadow:0 0 0 2px var(--green)}
.dp-tl-title{font-size:12.5px;font-weight:750;color:var(--ink)}
.dp-tl-time{font-size:11px;color:var(--muted);margin-top:1px}

.dp-comment{display:flex;gap:10px;padding:10px 0;border-bottom:1px solid #F4F7FC}
.dp-comment:last-child{border-bottom:none}
.dp-comment .av{width:30px;height:30px;border-radius:9px;background:linear-gradient(135deg,var(--cyan),var(--blue));color:#fff;
  font-size:11px;font-weight:800;display:flex;align-items:center;justify-content:center;flex:none}
.dp-comment .bd{flex:1}
.dp-comment .nm{font-size:12px;font-weight:750;color:var(--ink)}
.dp-comment .tm{font-size:10.5px;color:var(--muted);margin-left:6px;font-weight:600}
.dp-comment .bx{font-size:12.5px;color:var(--ink);margin-top:3px;line-height:1.5;white-space:pre-wrap}
.dp-comment-box{display:flex;gap:8px;margin-top:12px}
.dp-comment-box textarea{flex:1;min-height:56px;border:1.5px solid var(--border);border-radius:10px;padding:9px 11px;font-family:inherit;font-size:12.5px;resize:vertical;outline:none}
.dp-comment-box textarea:focus{border-color:var(--blue)}
.dp-comment-box button{align-self:flex-end;height:36px;padding:0 14px;border-radius:9px;border:none;background:var(--blue);color:#fff;font-size:12px;font-weight:750;cursor:pointer;font-family:inherit}
.dp-unavail{background:#F8FAFC;border:1px dashed var(--border);border-radius:12px;padding:12px 14px;font-size:11.5px;color:var(--muted);line-height:1.6}
.dp-empty{font-size:12px;color:var(--muted);padding:6px 0}
.dp-loading{padding:40px;text-align:center;color:var(--muted);font-size:13px}

@media(max-width:900px){
  .tm-drawer,.tm-detail-panel{width:100vw}
  .tm-summary-grid{grid-template-columns:repeat(2,1fr)}
}
</style>
<meta name="csrf-token" content="${csrfToken}">
<script src="${pageContext.request.contextPath}/js/csrf.js"></script>
</head><body><%@ include file="/WEB-INF/views/admin/sidebar.jsp" %><div class="main">

  <c:if test="${not empty param.msg}">
    <div class="toast ${param.ok == 'true' ? 'toast-ok' : 'toast-err'}" id="toast">
      ${param.ok == 'true' ? '✅' : '⛔'} <c:out value="${param.msg}"/>
    </div>
  </c:if>

  <header class="topbar"><div style="font-size:15px">🎯</div><span class="topbar-title">Task Management</span>
    <div class="topbar-right">
      <div class="sidebar-user" style="background:var(--surface);border-color:var(--border)">
        <div class="user-av" style="color:var(--ink);background:linear-gradient(135deg,var(--cyan),var(--blue))"><%= initials %></div>
        <div><div class="user-name" style="color:var(--ink)"><%= fullName %></div></div>
      </div>
    </div>
  </header>

  <div class="content">

    <div class="tm-header">
      <div>
        <h1>Task Management</h1>
        <p>Quản lý SOP ngắn hạn, Dự án dài hạn, vận hành kho và cộng tác nội bộ — mọi trạng thái, ai đang làm gì, việc nào trễ hạn, đều thấy ngay không cần đọc form dài.</p>
      </div>
      <div class="tm-actions">
        <div class="tm-search"><input type="text" id="tmSearch" placeholder="Tìm task…" oninput="renderKanban()"></div>
        <button type="button" class="tm-btn" id="tmFilterBtn" onclick="toggleFilterPanel()">🔍 Lọc</button>
        <div class="tm-date-chip">📅 <%= todayDisplay %></div>
        <button type="button" class="btn-primary" onclick="openDrawer()">➕ New Task</button>
      </div>
    </div>

    <div class="tm-filter-panel" id="tmFilterPanel">
      <div class="fi"><label>Ưu tiên</label>
        <select id="fPriority" onchange="renderKanban()">
          <option value="">Tất cả</option><option value="HIGH">🔴 Cao</option><option value="MEDIUM">🟡 Trung bình</option><option value="LOW">🔵 Thấp</option>
        </select></div>
      <div class="fi"><label>Người phụ trách</label>
        <select id="fAssignee" onchange="renderKanban()">
          <option value="">Tất cả</option>
          <c:forEach var="a" items="${warehouseStaff}"><option value="${fn:escapeXml(a.fullName)}">${fn:escapeXml(a.fullName)}</option></c:forEach>
          <option value="__unassigned__">Chưa gán</option>
        </select></div>
      <div class="fi"><label>Module</label>
        <select id="fModule" onchange="renderKanban()">
          <option value="">Tất cả</option>
          <c:forEach var="e" items="${statByModule}"><option value="${fn:escapeXml(e.key)}">${fn:escapeXml(e.key)}</option></c:forEach>
        </select></div>
      <button type="button" class="tm-btn" onclick="clearFilters()">✕ Xoá lọc</button>
    </div>

    <!-- ══ SUMMARY CARDS ══ -->
    <div class="tm-summary-grid">
      <div class="tm-card c-blue"><div class="ic">📋</div><div class="n" data-count="${totalTasks}">0</div><div class="l">Tổng số task</div></div>
      <div class="tm-card c-cyan"><div class="ic">📅</div><div class="n" data-count="${todayTasksCount}">0</div><div class="l">Task hôm nay</div></div>
      <div class="tm-card c-blue"><div class="ic">🔧</div><div class="n" data-count="${inProgressCount}">0</div><div class="l">Đang làm</div></div>
      <div class="tm-card c-red"><div class="ic">⏰</div><div class="n" data-count="${overdueCount}">0</div><div class="l">Quá hạn</div></div>
      <div class="tm-card c-green"><div class="ic">✅</div><div class="n" data-count="${completedCount}">0</div><div class="l">Đã hoàn thành</div></div>
      <div class="tm-card c-purple"><div class="ic">⏱️</div><div class="n"><fmt:formatNumber value="${avgCompletionHours}" maxFractionDigits="1"/>h</div><div class="l">TG hoàn thành TB</div></div>
      <div class="tm-card c-cyan"><div class="ic">📦</div><div class="n" data-count="${warehouseRelatedCount}">0</div><div class="l">Liên quan kho</div></div>
      <div class="tm-card c-amber"><div class="ic">🔴</div><div class="n" data-count="${highPriorityCount}">0</div><div class="l">Ưu tiên cao</div></div>
    </div>

    <!-- ══ WATCHDOG ══ -->
    <c:if test="${not empty watchdog}">
      <div class="alert-card">
        <div class="alert-card-top">
          <div class="alert-icon">🚨</div>
          <div class="alert-text">
            <strong>${watchdog.size()} task/dự án sắp hoặc đã quá hạn báo xong</strong>
            <p>Trong 48 giờ tới hoặc đã quá hạn — cần can thiệp/nhắc Thủ kho ngay.</p>
          </div>
        </div>
        <div class="alert-list">
          <c:forEach var="w" items="${watchdog}" end="4">
            <div class="alert-item">
              <span><b>${fn:escapeXml(w.title)}</b> — ${not empty w.assignedToName ? w.assignedToName : 'Chưa giao'}</span>
              <span class="badge ${w.zoneCssClass}">${w.zoneLabel}</span>
            </div>
          </c:forEach>
        </div>
      </div>
    </c:if>

    <!-- ══ MAIN GRID: KANBAN + RIGHT SIDEBAR ══ -->
    <div class="tm-main-grid">
      <div class="tm-kanban-wrap">
        <div class="tm-kanban-head">
          <h2>📋 Bảng tiến độ (Kanban)</h2>
          <span class="tc-sub" style="font-size:11px;color:var(--muted)">Kéo-thả để đổi trạng thái — trừ cột Hoàn thành (Thủ kho tự báo xong)</span>
        </div>
        <div class="tm-kanban-scroll" id="kanbanScroll"></div>
      </div>

      <aside class="tm-sidebar">
        <div class="tm-side-card">
          <h3>📅 Lịch hôm nay</h3>
          <div id="sideToday"></div>
        </div>
        <div class="tm-side-card">
          <h3>⏰ Sắp tới hạn</h3>
          <div id="sideDeadlines"></div>
        </div>
        <div class="tm-side-card">
          <h3>✅ Vừa hoàn thành</h3>
          <c:choose>
            <c:when test="${empty kpiAudit}"><div class="tm-side-empty">Chưa có task nào hoàn thành.</div></c:when>
            <c:otherwise>
              <c:forEach var="k" items="${kpiAudit}" end="4">
                <div class="tm-side-row"><span>${k.status == 'COMPLETED_ON_TIME' ? '🟢' : '🟠'}</span>
                  <span class="nm">${fn:escapeXml(k.title)}</span><span class="sub">${k.completedAtDisplay}</span></div>
              </c:forEach>
            </c:otherwise>
          </c:choose>
        </div>
        <div class="tm-side-card">
          <h3>🏆 Nhân viên tích cực nhất</h3>
          <c:choose>
            <c:when test="${empty statByAssignee}"><div class="tm-side-empty">Chưa có dữ liệu.</div></c:when>
            <c:otherwise>
              <c:forEach var="e" items="${statByAssignee}" end="4">
                <div class="tm-side-row"><span class="nm">${fn:escapeXml(e.key)}</span><span class="sub">${e.value} task</span></div>
              </c:forEach>
            </c:otherwise>
          </c:choose>
        </div>
      </aside>
    </div>

    <!-- ══ BOTTOM ANALYTICS ══ -->
    <div class="tm-section-title">📊 Phân tích</div>
    <div class="tm-analytics-grid">
      <div class="tm-chart-card"><h4>Tỷ lệ hoàn thành</h4><canvas id="chartCompletion"></canvas></div>
      <div class="tm-chart-card"><h4>Task theo nhân viên</h4><canvas id="chartByEmployee"></canvas></div>
      <div class="tm-chart-card"><h4>Task theo module</h4><canvas id="chartByModule"></canvas></div>
      <div class="tm-chart-card"><h4>Task theo ưu tiên</h4><canvas id="chartByPriority"></canvas></div>
      <div class="tm-chart-card"><h4>Thời gian hoàn thành trung bình</h4>
        <div class="tm-stat-callout"><div class="big"><fmt:formatNumber value="${avgCompletionHours}" maxFractionDigits="1"/>h</div>
          <div class="sub">Tính từ lúc giao task tới lúc Thủ kho báo xong (mọi task đã hoàn thành)</div></div></div>
      <div class="tm-chart-card"><h4>Đang quá hạn</h4>
        <div class="tm-stat-callout"><div class="big" style="color:var(--red)">${overdueCount}</div>
          <div class="sub">Task/dự án chưa xong nhưng đã trễ hạn báo cáo</div></div></div>
    </div>

    <!-- ══ KPI AUDIT TABLE ══ -->
    <div class="table-card">
      <div class="table-card-head"><h2>📜 Nhật ký Liêm chính Thời gian (KPI Audit)</h2></div>
      <table>
        <thead><tr><th>Task</th><th>Thủ kho</th><th>Hạn báo xong</th><th>Đã báo xong lúc</th><th>Kết quả</th></tr></thead>
        <tbody>
        <c:choose>
          <c:when test="${empty kpiAudit}"><tr><td colspan="5" class="empty-box">Chưa có task nào hoàn thành.</td></tr></c:when>
          <c:otherwise>
            <c:forEach var="k" items="${kpiAudit}">
              <tr>
                <td>${fn:escapeXml(k.title)} <c:if test="${k.isProject}">🚀</c:if></td>
                <td>${not empty k.assignedToName ? k.assignedToName : '—'}</td>
                <td>${not empty k.dueDate ? k.dueDateDisplay : 'Không hạn'}</td>
                <td>${k.completedAtDisplay}</td>
                <td>
                  <c:choose>
                    <c:when test="${k.status == 'COMPLETED_ON_TIME'}"><span class="badge badge-ontime">✅ PASS</span></c:when>
                    <c:otherwise><span class="badge badge-late">⏰ LATE</span></c:otherwise>
                  </c:choose>
                </td>
              </tr>
            </c:forEach>
          </c:otherwise>
        </c:choose>
        </tbody>
      </table>
    </div>

  </div>
</div>

<!-- ══ DRAWER: New Task ══ -->
<div class="tm-drawer-backdrop" id="drawerBackdrop" onclick="closeDrawer()"></div>
<aside class="tm-drawer" id="taskDrawer">
  <div class="tm-drawer-head">
    <div class="tm-drawer-head-top">
      <h3>➕ Công việc mới</h3>
      <button type="button" class="tm-drawer-close" onclick="closeDrawer()">✕</button>
    </div>
  </div>
  <div class="tm-drawer-body">
    <div class="type-toggle">
      <button type="button" class="tt-btn active" id="tabTask" onclick="switchType('task')">⚡ Task ngắn hạn (SOP)</button>
      <button type="button" class="tt-btn" id="tabProject" onclick="switchType('project')">🚀 Dự án dài hạn</button>
    </div>

    <form method="post" action="${pageContext.request.contextPath}/task-management" id="formTask">
      <input type="hidden" name="_csrf" value="${csrfToken}">
      <input type="hidden" name="action" value="create-task">
      <div class="dsec">
        <div class="dsec-title">Thông tin cơ bản</div>
        <div class="fi"><label>Tiêu đề <span class="req">*</span></label>
          <input type="text" name="title" maxlength="255" placeholder="VD: Kiểm tra nhiệt độ tủ lạnh vắc-xin" required></div>
        <div class="fi"><label>Mô tả <span class="req">*</span></label>
          <textarea name="description" maxlength="1000" placeholder="Ghi rõ yêu cầu…" required></textarea></div>
        <div class="fi-row2">
          <div class="fi"><label>Ưu tiên</label>
            <select name="priority"><option value="HIGH">🔴 Cao</option><option value="MEDIUM" selected>🟡 Trung bình</option><option value="LOW">🔵 Thấp</option></select></div>
          <div class="fi"><label>Giao cho</label>
            <select name="assignedTo">
              <option value="">— Để chung —</option>
              <c:forEach var="a" items="${warehouseStaff}"><option value="${a.accountId}">${fn:escapeXml(a.fullName)}</option></c:forEach>
            </select></div>
        </div>
        <div class="fi-row2">
          <div class="fi"><label>Hạn báo xong trước <span class="req">*</span></label>
            <input type="datetime-local" name="dueDate" class="due-input" required></div>
          <div class="fi"><label>Số giờ dự kiến</label>
            <input type="number" name="estimatedHours" min="0" step="0.5" placeholder="VD: 2"></div>
        </div>
      </div>
      <details class="adv">
        <summary>Liên kết tới bản ghi Kho (tuỳ chọn, nâng cao)</summary>
        <div class="fi"><label>Loại bản ghi (RefTable)</label>
          <select name="refTable">
            <option value="">— Không liên kết —</option>
            <option value="Batches">Lô hàng (Batches)</option>
            <option value="PurchaseOrders">Đơn nhập hàng (PurchaseOrders)</option>
            <option value="Medicines">Thuốc (Medicines)</option>
            <option value="Shifts">Ca làm việc (Shifts)</option>
          </select></div>
        <div class="fi"><label>ID bản ghi (RefID)</label>
          <input type="number" name="refId" min="1" placeholder="VD: 1234 — cần biết đúng ID"></div>
      </details>
      <button type="submit" class="btn-primary drawer-submit">Giao task</button>
    </form>

    <form method="post" action="${pageContext.request.contextPath}/task-management" id="formProject" style="display:none">
      <input type="hidden" name="_csrf" value="${csrfToken}">
      <input type="hidden" name="action" value="create-project">
      <div class="dsec">
        <div class="dsec-title">Thông tin Dự án</div>
        <div class="fi"><label>Tên Dự án <span class="req">*</span></label>
          <input type="text" name="title" maxlength="255" placeholder="VD: Xử lý 50 Lô cận hạn Q3/2026" required></div>
        <div class="fi"><label>Mô tả <span class="req">*</span></label>
          <textarea name="description" maxlength="1000" placeholder="Bối cảnh, mục tiêu chiến dịch…" required></textarea></div>
        <div class="fi-row2">
          <div class="fi"><label>Ưu tiên</label>
            <select name="priority"><option value="HIGH">🔴 Cao</option><option value="MEDIUM" selected>🟡 Trung bình</option><option value="LOW">🔵 Thấp</option></select></div>
          <div class="fi"><label>Giao cho <span class="req">*</span></label>
            <select name="assignedTo" required>
              <option value="">— Chọn Thủ kho —</option>
              <c:forEach var="a" items="${warehouseStaff}"><option value="${a.accountId}">${fn:escapeXml(a.fullName)}</option></c:forEach>
            </select></div>
        </div>
        <div class="fi"><label>Hạn báo cáo tổng <span class="req">*</span></label>
          <input type="datetime-local" name="dueDate" class="due-input" required></div>
      </div>
      <div class="dsec">
        <div class="dsec-title">Các mốc (milestones)</div>
        <div class="milestone-rows" id="milestoneRows"></div>
        <button type="button" class="add-milestone" onclick="addMilestoneRow()">+ Thêm mốc</button>
      </div>
      <button type="submit" class="btn-primary drawer-submit">Tạo Dự án</button>
    </form>
  </div>
</aside>

<!-- ══ TASK DETAIL PANEL ══ -->
<div class="tm-detail-backdrop" id="detailBackdrop" onclick="closeDetail()"></div>
<aside class="tm-detail-panel" id="taskDetailPanel">
  <div class="dp-head">
    <div class="dp-head-top">
      <span style="font-size:11px;font-weight:750;color:rgba(255,255,255,.6);text-transform:uppercase;letter-spacing:.5px">Chi tiết công việc</span>
      <button type="button" class="dp-close" onclick="closeDetail()">✕</button>
    </div>
    <div class="dp-title" id="dpTitle">—</div>
    <div class="dp-badges" id="dpBadges"></div>
  </div>
  <div class="dp-body" id="dpBody"><div class="dp-loading">Đang tải…</div></div>
</aside>

<script>
const CTX = '${pageContext.request.contextPath}';
const KANBAN_TASKS = ${kanbanTasksJson};
const COLUMNS = [
  {key:'todo',       name:'To Do',        dot:'#94A3B8', drop:true},
  {key:'assigned',   name:'Assigned',     dot:'#3ABDE0', drop:false},
  {key:'in_progress',name:'In Progress',  dot:'#1558A8', drop:true},
  {key:'review',     name:'Review',       dot:'#7C3AED', drop:true},
  {key:'blocked',    name:'Blocked',      dot:'#DC2626', drop:true},
  {key:'done',       name:'Done',         dot:'#059669', drop:false},
  {key:'cancelled',  name:'Cancelled',    dot:'#64748B', drop:true}
];
function esc(s){ return String(s==null?'':s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }

/* ══ Kanban render + kéo-thả (HTML5 native DnD, không thêm thư viện) ══ */
function passesFilter(t){
  var q = document.getElementById('tmSearch').value.trim().toLowerCase();
  if (q && !(t.title||'').toLowerCase().includes(q)) return false;
  var p = document.getElementById('fPriority').value;
  if (p && t.priority !== p) return false;
  var a = document.getElementById('fAssignee').value;
  if (a === '__unassigned__' && t.assignedToName) return false;
  if (a && a !== '__unassigned__' && t.assignedToName !== a) return false;
  var m = document.getElementById('fModule').value;
  if (m && t.module !== m) return false;
  return true;
}
function renderKanban(){
  var scroll = document.getElementById('kanbanScroll');
  scroll.innerHTML = '';
  var visible = KANBAN_TASKS.filter(passesFilter);
  COLUMNS.forEach(function(col){
    var items = visible.filter(function(t){ return t.column === col.key; });
    var colEl = document.createElement('div');
    colEl.className = 'kb-col';
    colEl.dataset.col = col.key;
    colEl.innerHTML = '<div class="kb-col-head"><span class="kb-col-dot" style="background:'+col.dot+'"></span>'
      + '<span class="kb-col-name">'+col.name+'</span><span class="kb-col-count">'+items.length+'</span></div>'
      + '<div class="kb-col-body"></div>';
    var body = colEl.querySelector('.kb-col-body');
    if (!items.length) body.innerHTML = '<div class="kb-empty">Không có việc nào.</div>';
    items.forEach(function(t){ body.appendChild(buildCard(t)); });
    if (col.drop) {
      colEl.addEventListener('dragover', function(e){ e.preventDefault(); colEl.classList.add('drag-over'); });
      colEl.addEventListener('dragleave', function(){ colEl.classList.remove('drag-over'); });
      colEl.addEventListener('drop', function(e){
        e.preventDefault(); colEl.classList.remove('drag-over');
        var taskId = e.dataTransfer.getData('text/plain');
        onCardDropped(parseInt(taskId), col.key);
      });
    }
    scroll.appendChild(colEl);
  });
  renderSidebarWidgets(visible);
}
function priorityClass(t){
  if (t.column === 'done') return 'st-done';
  return t.priority === 'HIGH' ? 'p-high' : (t.priority === 'LOW' ? 'p-low' : 'p-medium');
}
function buildCard(t){
  var card = document.createElement('div');
  card.className = 'kb-card ' + priorityClass(t);
  var draggable = ['todo','in_progress','review','blocked'].indexOf(t.column) !== -1;
  card.draggable = draggable;
  if (draggable) {
    card.addEventListener('dragstart', function(e){ e.dataTransfer.setData('text/plain', t.id); card.classList.add('dragging'); });
    card.addEventListener('dragend', function(){ card.classList.remove('dragging'); });
  }
  card.addEventListener('click', function(){ openDetail(t.id); });
  var badges = '<span class="mini-badge mb-'+t.priority.toLowerCase()+'">'+t.priorityLabel+'</span>';
  if (t.module && t.module !== 'Chung') badges += '<span class="mini-badge mb-module">'+esc(t.module)+'</span>';
  if (t.column === 'done') {
    badges += '<span class="mini-badge '+(t.status==='COMPLETED_ON_TIME'?'mb-ontime':'mb-late')+'">'+(t.status==='COMPLETED_ON_TIME'?'Đúng hạn':'Trễ hạn')+'</span>';
  } else if (t.zone) {
    var zc = {OVERDUE:'mb-zone-overdue',CRITICAL:'mb-zone-critical',WARNING:'mb-zone-warning',SAFE:'mb-zone-safe'}[t.zone] || '';
    var zl = {OVERDUE:'Quá hạn',CRITICAL:'Sắp hết hạn',WARNING:'Cảnh báo',SAFE:'Còn HAN'}[t.zone] || t.zone;
    if (zc) badges += '<span class="mini-badge '+zc+'">'+zl+'</span>';
  }
  var initials = t.assignedToName ? t.assignedToName.trim().substring(0,2).toUpperCase() : '?';
  var avatar = '<div class="kb-avatar'+(t.assignedToName?'':' unassigned')+'" title="'+esc(t.assignedToName||'Chưa gán')+'">'+initials+'</div>';
  var due = t.dueDate ? ('⏰ '+t.dueDate) : '';
  var icons = '';
  if (t.estimatedHours) icons += '<span>⏱️ '+t.estimatedHours+'h</span>';
  if (t.isProject) icons += '<span>🚀 '+t.progressPercentage+'%</span>';
  card.innerHTML = '<div class="kb-title">'+esc(t.title)+'</div>'
    + '<div class="kb-badges">'+badges+'</div>'
    + '<div class="kb-meta-row">'+avatar+'<span class="kb-due">'+due+'</span></div>'
    + (icons ? '<div class="kb-icons-row">'+icons+'</div>' : '')
    + (t.isProject ? '<div class="kb-progress"><div class="kb-progress-fill" style="width:'+t.progressPercentage+'%"></div></div>' : '');
  return card;
}
function onCardDropped(taskId, newColumn){
  var t = KANBAN_TASKS.find(function(x){ return x.id === taskId; });
  if (!t) return;
  if (newColumn === t.column) return;
  var statusMap = {todo:'PENDING', in_progress:'IN_PROGRESS', review:'REVIEW', blocked:'BLOCKED', cancelled:'CANCELLED'};
  var newStatus = statusMap[newColumn];
  if (!newStatus) { showMiniToast('Không thể kéo trực tiếp vào cột này.'); return; }
  var fd = new URLSearchParams();
  fd.set('action','move-status'); fd.set('taskId', taskId); fd.set('status', newStatus);
  fetch(CTX + '/task-management', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:fd.toString()})
    .then(function(r){ return r.json(); })
    .then(function(data){
      if (data.ok) {
        t.status = newStatus; t.column = newColumn; t.statusLabel = newStatus;
        renderKanban();
        showMiniToast('✓ Đã chuyển "'+t.title+'" sang '+COLUMNS.find(function(c){return c.key===newColumn;}).name);
      } else {
        showMiniToast('⚠️ Không thể đổi trạng thái (task đã hoàn thành/huỷ trước đó).');
      }
    })
    .catch(function(){ showMiniToast('⚠️ Mất kết nối.'); });
}
function showMiniToast(text){
  var el = document.getElementById('miniToast');
  if (!el) { el = document.createElement('div'); el.id = 'miniToast'; el.className = 'toast-mini'; document.body.appendChild(el); }
  el.textContent = text; el.classList.add('show');
  clearTimeout(window.__miniToastT);
  window.__miniToastT = setTimeout(function(){ el.classList.remove('show'); }, 2600);
}

/* ══ Filters ══ */
function toggleFilterPanel(){
  var p = document.getElementById('tmFilterPanel');
  p.classList.toggle('show');
  document.getElementById('tmFilterBtn').classList.toggle('active', p.classList.contains('show'));
}
function clearFilters(){
  document.getElementById('fPriority').value = '';
  document.getElementById('fAssignee').value = '';
  document.getElementById('fModule').value = '';
  document.getElementById('tmSearch').value = '';
  renderKanban();
}

/* ══ Right Sidebar widgets (tính từ dữ liệu đã tải, không gọi thêm API) ══ */
function renderSidebarWidgets(visible){
  var todayBox = document.getElementById('sideToday');
  var todayStr = new Date().toISOString().slice(0,10);
  var todayTasks = KANBAN_TASKS.filter(function(t){ return t.dueDate && t.dueDate.indexOf(todayStr.split('-').reverse().join('/')) === 0; });
  todayBox.innerHTML = todayTasks.length ? todayTasks.slice(0,5).map(function(t){
    return '<div class="tm-side-row"><span>🔹</span><span class="nm">'+esc(t.title)+'</span><span class="sub">'+esc(t.assignedToName||'Chung')+'</span></div>';
  }).join('') : '<div class="tm-side-empty">Không có task đến hạn hôm nay.</div>';

  var dlBox = document.getElementById('sideDeadlines');
  var upcoming = KANBAN_TASKS.filter(function(t){ return t.zone === 'CRITICAL' || t.zone === 'OVERDUE'; }).slice(0,5);
  dlBox.innerHTML = upcoming.length ? upcoming.map(function(t){
    return '<div class="tm-side-row"><span>'+(t.zone==='OVERDUE'?'🔴':'🟠')+'</span><span class="nm">'+esc(t.title)+'</span><span class="sub">'+esc(t.dueDate||'')+'</span></div>';
  }).join('') : '<div class="tm-side-empty">Không có hạn nào sắp tới.</div>';
}

/* ══ Animated counters ══ */
function animateCounters(){
  document.querySelectorAll('.tm-card .n[data-count]').forEach(function(el){
    var target = parseInt(el.dataset.count, 10) || 0;
    var cur = 0, step = Math.max(1, Math.ceil(target/24));
    var timer = setInterval(function(){
      cur += step;
      if (cur >= target) { cur = target; clearInterval(timer); }
      el.textContent = cur;
    }, 18);
  });
}

/* ══ Drawer (New Task) ══ */
function openDrawer(){ document.getElementById('drawerBackdrop').classList.add('open'); document.getElementById('taskDrawer').classList.add('open'); }
function closeDrawer(){ document.getElementById('drawerBackdrop').classList.remove('open'); document.getElementById('taskDrawer').classList.remove('open'); }
function switchType(type){
  document.getElementById('formTask').style.display = type === 'task' ? 'block' : 'none';
  document.getElementById('formProject').style.display = type === 'project' ? 'block' : 'none';
  document.getElementById('tabTask').classList.toggle('active', type === 'task');
  document.getElementById('tabProject').classList.toggle('active', type === 'project');
}
function nowLocalIso(){
  var d = new Date(), pad = function(n){ return String(n).padStart(2,'0'); };
  return d.getFullYear() + '-' + pad(d.getMonth()+1) + '-' + pad(d.getDate()) + 'T' + pad(d.getHours()) + ':' + pad(d.getMinutes());
}
function applyMinToDateInputs(scope){
  var min = nowLocalIso();
  (scope || document).querySelectorAll('input[type=datetime-local]').forEach(function(el){ el.min = min; });
}
function addMilestoneRow(){
  var wrap = document.getElementById('milestoneRows');
  var row = document.createElement('div');
  row.className = 'milestone-input-row';
  row.innerHTML = '<input type="text" name="milestoneTitle" placeholder="VD: Xử lý xong Lô B-102" maxlength="255">' +
    '<input type="datetime-local" name="milestoneDueDate">' +
    '<button type="button" class="ms-remove" onclick="this.parentElement.remove()">✕</button>';
  wrap.appendChild(row);
  applyMinToDateInputs(row);
}

/* ══ Task Detail Panel ══ */
let _dpCurrentId = null;
function openDetail(taskId){
  _dpCurrentId = taskId;
  document.getElementById('detailBackdrop').classList.add('open');
  document.getElementById('taskDetailPanel').classList.add('open');
  document.getElementById('dpBody').innerHTML = '<div class="dp-loading">Đang tải…</div>';
  fetch(CTX + '/task-management?action=task-detail&id=' + taskId)
    .then(function(r){ return r.json(); })
    .then(function(data){ if (data.ok) renderDetail(data); else document.getElementById('dpBody').innerHTML = '<div class="dp-empty">Không tải được.</div>'; })
    .catch(function(){ document.getElementById('dpBody').innerHTML = '<div class="dp-empty">Lỗi kết nối.</div>'; });
}
function closeDetail(){ document.getElementById('detailBackdrop').classList.remove('open'); document.getElementById('taskDetailPanel').classList.remove('open'); }

const STATUS_OPTIONS = [
  {v:'PENDING', l:'To Do'}, {v:'IN_PROGRESS', l:'In Progress'}, {v:'REVIEW', l:'Review'},
  {v:'BLOCKED', l:'Blocked'}, {v:'CANCELLED', l:'Cancelled'}
];
function renderDetail(data){
  var t = data.task;
  document.getElementById('dpTitle').textContent = t.title;
  document.getElementById('dpBadges').innerHTML =
    '<span class="dp-badge">'+t.priorityLabel+'</span><span class="dp-badge">'+t.statusLabel+'</span>'
    + (t.isProject ? '<span class="dp-badge">🚀 Dự án — '+t.progressPercentage+'%</span>' : '');

  var doneItems = data.checklist.filter(function(c){ return c.done; }).length;
  var totalItems = data.checklist.length;
  var pct = totalItems ? Math.round(100*doneItems/totalItems) : 0;

  var html = '';
  html += '<div class="dp-sec"><div class="dp-sec-title">Mô tả</div><div class="dp-desc">'+esc(t.description||'—')+'</div></div>';

  html += '<div class="dp-sec"><div class="dp-sec-title">Đổi trạng thái</div><div class="dp-status-row">';
  STATUS_OPTIONS.forEach(function(s){
    var isDoneCol = (t.status === 'COMPLETED_ON_TIME' || t.status === 'COMPLETED_LATE');
    html += '<button type="button" class="dp-status-btn'+(t.status===s.v?' current':'')+'" '
      + (isDoneCol ? 'disabled title="Đã hoàn thành, không đổi được nữa"' : 'onclick="dpMoveStatus('+t.id+',\''+s.v+'\')"') + '>'+s.l+'</button>';
  });
  if (t.status === 'COMPLETED_ON_TIME' || t.status === 'COMPLETED_LATE') {
    html += '<span class="dp-badge" style="background:#ECFDF5;color:#065F46">✅ Đã hoàn thành — chỉ Thủ kho được báo xong, Admin không đổi lại</span>';
  }
  html += '</div></div>';

  html += '<div class="dp-sec"><div class="dp-sec-title">Tổng quan</div><div class="dp-kv-card">'
    + kv('Người phụ trách', t.assignedToName || 'Chưa gán')
    + kv('Người giao', t.createdByName || '—')
    + kv('Hạn báo xong', t.dueDate || 'Không có hạn')
    + kv('Ngày tạo', t.createdAt)
    + (t.completedAt ? kv('Hoàn thành lúc', t.completedAt + (t.completedByName ? (' — '+t.completedByName) : '')) : '')
    + (t.estimatedHours ? kv('Số giờ dự kiến', t.estimatedHours + ' giờ') : '')
    + '</div></div>';

  html += '<div class="dp-sec"><div class="dp-sec-title">✅ Checklist</div>';
  if (totalItems) {
    html += '<div class="dp-checklist-progress"><div class="kb-progress"><div class="kb-progress-fill" style="width:'+pct+'%"></div></div><span class="pct">'+doneItems+'/'+totalItems+'</span></div>';
  }
  html += '<div id="dpChecklistList">' + (data.checklist.length ? data.checklist.map(checklistRow).join('') : '<div class="dp-empty">Chưa có mục nào.</div>') + '</div>';
  html += '<div class="dp-add-row"><input type="text" id="dpNewChecklist" placeholder="Thêm mục checklist…" onkeydown="if(event.key===\'Enter\')dpAddChecklist('+t.id+')">'
    + '<button type="button" onclick="dpAddChecklist('+t.id+')">Thêm</button></div></div>';

  html += '<div class="dp-sec"><div class="dp-sec-title">📦 Thông tin Kho</div>';
  if (data.ref.found) {
    html += '<div class="dp-kv-card">' + data.ref.rows.map(function(r){ return kv(r[0], r[1]); }).join('') + '</div>';
  } else {
    html += '<div class="dp-unavail">Task này không liên kết tới bản ghi kho nào (RefTable/RefID trống hoặc không tra được).</div>';
  }
  html += '</div>';

  if (data.milestones && data.milestones.length) {
    html += '<div class="dp-sec"><div class="dp-sec-title">🚀 Các mốc (Milestones)</div>';
    html += data.milestones.map(function(m){
      return '<div class="dp-kv-row"><span class="dp-kv-k">'+esc(m.title)+'</span><span class="dp-kv-v">'+m.statusLabel+'</span></div>';
    }).join('');
    html += '</div>';
  }

  html += '<div class="dp-sec"><div class="dp-sec-title">🕒 Dòng thời gian hoạt động</div><div class="dp-timeline">'
    + tlNode('Task được tạo', t.createdAt, false)
    + (t.assignedToName ? tlNode('Gán cho ' + esc(t.assignedToName), '', false) : '')
    + (t.completedAt ? tlNode((t.status==='COMPLETED_ON_TIME'?'Hoàn thành đúng hạn':'Hoàn thành trễ hạn') + (t.completedByName?(' — '+esc(t.completedByName)):''), t.completedAt, true) : '')
    + '</div></div>';

  html += '<div class="dp-sec"><div class="dp-sec-title">💬 Thảo luận</div><div id="dpComments">'
    + (data.comments.length ? data.comments.map(commentRow).join('') : '<div class="dp-empty">Chưa có bình luận nào.</div>') + '</div>'
    + '<div class="dp-comment-box"><textarea id="dpNewComment" placeholder="Viết bình luận…"></textarea><button type="button" onclick="dpAddComment('+t.id+')">Gửi</button></div></div>';

  document.getElementById('dpBody').innerHTML = html;
}
function kv(k,v){ return '<div class="dp-kv-row"><span class="dp-kv-k">'+esc(k)+'</span><span class="dp-kv-v">'+esc(v)+'</span></div>'; }
function tlNode(title, time, done){
  return '<div class="dp-tl-node"><div class="dp-tl-dot'+(done?' done':'')+'"></div><div class="dp-tl-title">'+title+'</div>'
    + (time ? '<div class="dp-tl-time">'+esc(time)+'</div>' : '') + '</div>';
}
function checklistRow(c){
  return '<div class="dp-checklist-item'+(c.done?' done':'')+'" id="ci-'+c.id+'">'
    + '<input type="checkbox" '+(c.done?'checked':'')+' onchange="dpToggleChecklist('+c.id+',this.checked)">'
    + '<span>'+esc(c.text)+'</span><button type="button" class="rm" onclick="dpDeleteChecklist('+c.id+')">✕</button></div>';
}
function commentRow(c){
  var ini = (c.name||'?').trim().substring(0,2).toUpperCase();
  return '<div class="dp-comment"><div class="av">'+ini+'</div><div class="bd">'
    + '<span class="nm">'+esc(c.name||'Ẩn danh')+'</span><span class="tm">'+esc(c.time)+'</span>'
    + '<div class="bx">'+esc(c.body)+'</div></div></div>';
}
function dpMoveStatus(taskId, status){
  var fd = new URLSearchParams(); fd.set('action','move-status'); fd.set('taskId', taskId); fd.set('status', status);
  fetch(CTX + '/task-management', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:fd.toString()})
    .then(function(r){ return r.json(); })
    .then(function(data){
      if (data.ok) {
        var t = KANBAN_TASKS.find(function(x){ return x.id === taskId; });
        if (t) { t.status = status; t.column = {PENDING:'todo',IN_PROGRESS:'in_progress',REVIEW:'review',BLOCKED:'blocked',CANCELLED:'cancelled'}[status] || t.column; }
        renderKanban(); openDetail(taskId);
        showMiniToast('✓ Đã đổi trạng thái');
      } else showMiniToast('⚠️ Không đổi được trạng thái.');
    });
}
function dpAddChecklist(taskId){
  var input = document.getElementById('dpNewChecklist');
  var text = input.value.trim();
  if (!text) return;
  var fd = new URLSearchParams(); fd.set('action','checklist-add'); fd.set('taskId', taskId); fd.set('text', text);
  fetch(CTX + '/task-management', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:fd.toString()})
    .then(function(r){ return r.json(); })
    .then(function(data){ if (data.ok) { input.value=''; openDetail(taskId); } else showMiniToast('⚠️ Không thêm được.'); });
}
function dpToggleChecklist(itemId, done){
  var fd = new URLSearchParams(); fd.set('action','checklist-toggle'); fd.set('itemId', itemId); fd.set('done', done);
  fetch(CTX + '/task-management', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:fd.toString()})
    .then(function(r){ return r.json(); })
    .then(function(data){ if (data.ok) { document.getElementById('ci-'+itemId).classList.toggle('done', done); } });
}
function dpDeleteChecklist(itemId){
  var fd = new URLSearchParams(); fd.set('action','checklist-delete'); fd.set('itemId', itemId);
  fetch(CTX + '/task-management', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:fd.toString()})
    .then(function(r){ return r.json(); })
    .then(function(data){ if (data.ok && _dpCurrentId) openDetail(_dpCurrentId); });
}
function dpAddComment(taskId){
  var ta = document.getElementById('dpNewComment');
  var body = ta.value.trim();
  if (!body) return;
  var fd = new URLSearchParams(); fd.set('action','comment-add'); fd.set('taskId', taskId); fd.set('body', body);
  fetch(CTX + '/task-management', {method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'}, body:fd.toString()})
    .then(function(r){ return r.json(); })
    .then(function(data){ if (data.ok) { ta.value=''; openDetail(taskId); } else showMiniToast('⚠️ Không gửi được.'); });
}
document.addEventListener('keydown', function(e){
  if (e.key === 'Escape') { closeDrawer(); closeDetail(); }
  if (e.key === 'n' && !e.ctrlKey && !e.metaKey && document.activeElement.tagName !== 'INPUT' && document.activeElement.tagName !== 'TEXTAREA') openDrawer();
});

/* ══ Charts (Chart.js — cùng version report-list.jsp đang dùng) ══ */
function initCharts(){
  var statusMap = ${statByStatusJson};
  var doneCount = (statusMap.COMPLETED_ON_TIME||0) + (statusMap.COMPLETED_LATE||0);
  var openCount = (statusMap.PENDING||0)+(statusMap.IN_PROGRESS||0)+(statusMap.REVIEW||0)+(statusMap.BLOCKED||0);
  new Chart(document.getElementById('chartCompletion'), { type:'doughnut',
    data:{ labels:['Hoàn thành','Đang mở','Đã huỷ'], datasets:[{ data:[doneCount, openCount, statusMap.CANCELLED||0], backgroundColor:['#059669','#1558A8','#94A3B8'] }] },
    options:{ plugins:{legend:{position:'bottom',labels:{boxWidth:10,font:{size:11}}}} } });

  var byEmp = ${statByAssigneeJson};
  new Chart(document.getElementById('chartByEmployee'), { type:'bar',
    data:{ labels:Object.keys(byEmp), datasets:[{ data:Object.values(byEmp), backgroundColor:'#1558A8', borderRadius:6 }] },
    options:{ plugins:{legend:{display:false}}, scales:{y:{beginAtZero:true,ticks:{precision:0}}} } });

  var byMod = ${statByModuleJson};
  new Chart(document.getElementById('chartByModule'), { type:'bar',
    data:{ labels:Object.keys(byMod), datasets:[{ data:Object.values(byMod), backgroundColor:'#3ABDE0', borderRadius:6 }] },
    options:{ indexAxis:'y', plugins:{legend:{display:false}}, scales:{x:{beginAtZero:true,ticks:{precision:0}}} } });

  var byPri = ${statByPriorityJson};
  new Chart(document.getElementById('chartByPriority'), { type:'pie',
    data:{ labels:Object.keys(byPri), datasets:[{ data:Object.values(byPri), backgroundColor:['#DC2626','#1558A8','#94A3B8'] }] },
    options:{ plugins:{legend:{position:'bottom',labels:{boxWidth:10,font:{size:11}}}} } });
}

renderKanban();
animateCounters();
initCharts();
setTimeout(function(){ var t=document.getElementById('toast'); if(t) t.style.display='none'; }, 3500);
switchType('task');
addMilestoneRow();
applyMinToDateInputs(document);
</script>
</body></html>
