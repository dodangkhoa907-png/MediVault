<%@ page contentType="text/html;charset=UTF-8" %>
<% String activeNav = "medicines"; %>
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
    String msg = request.getParameter("msg");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Kho thuốc — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;--sidebar:232px;
}
html,body{height:100%;font-family:'Outfit',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}
/* ── SIDEBAR ── */
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-icon{width:36px;height:36px;background:linear-gradient(135deg,#3ABDE0,#1558A8);border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:18px}
.logo-text{font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-sub{font-size:10px;color:rgba(255,255,255,.45);font-weight:500;letter-spacing:.5px;text-transform:uppercase}
.nav-section{padding:10px 12px 4px;flex-shrink:0}
.nav-label{font-size:9.5px;font-weight:700;color:rgba(255,255,255,.3);letter-spacing:1px;text-transform:uppercase;padding:0 8px;margin-bottom:4px}
.nav-item{display:flex;align-items:center;gap:9px;padding:9px 10px;border-radius:10px;color:rgba(255,255,255,.6);text-decoration:none;font-size:13.5px;font-weight:500;transition:all .16s;margin-bottom:2px}
.nav-item:hover{background:rgba(255,255,255,.07);color:#fff}
.nav-item.active{background:rgba(58,189,224,.15);color:#fff;border:1px solid rgba(58,189,224,.2)}
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06);flex-shrink:0}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08)}
.user-av{width:34px;height:34px;border-radius:50%;background:linear-gradient(135deg,#3ABDE0,#1558A8);display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:800;color:#fff;flex-shrink:0}
.user-name{font-size:13px;font-weight:700;color:#fff}
.user-role{font-size:11px;color:rgba(255,255,255,.4)}
.logout-btn{margin-left:auto;width:30px;height:30px;border-radius:8px;display:flex;align-items:center;justify-content:center;color:rgba(255,255,255,.4);text-decoration:none;font-size:16px;transition:all .15s}
.logout-btn:hover{background:rgba(220,38,38,.2);color:#DC2626}
/* ── MAIN ── */
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;overflow-x:hidden}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding: 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:8px;flex-shrink:0}
.topbar-clock{display:flex;align-items:center;gap:5px;padding:6px 13px;background:var(--surface);border:1.5px solid var(--border);border-radius:20px;font-size:13px;font-weight:700;color:var(--navy);font-variant-numeric:tabular-nums}
.clock-sep{animation:blink 1s step-end infinite}
@keyframes blink{0%,100%{opacity:1}50%{opacity:0}}
.clock-date{font-size:11px;font-weight:500;color:var(--muted);border-left:1px solid var(--border);padding-left:8px;margin-left:2px;font-variant-numeric:initial}
.tb-chip{display:inline-flex;align-items:center;gap:5px;padding:5px 11px;border-radius:20px;font-size:12px;font-weight:700;cursor:pointer;border:none;font-family:inherit;transition:all .15s;white-space:nowrap}
.tb-chip:hover{filter:brightness(.94);transform:translateY(-1px)}
.tb-chip-gold{background:#FFFBEB;color:#B45309;border:1.5px solid #FDE68A}
.tb-chip-red{background:#FFF5F5;color:#DC2626;border:1.5px solid #FCA5A5}
.tb-chip-ok{background:#F0FDF4;color:#059669;border:1.5px solid #A7F3D0}
.tb-avatar{width:34px;height:34px;border-radius:50%;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;font-size:12px;font-weight:800;display:flex;align-items:center;justify-content:center;flex-shrink:0;cursor:default;border:2px solid var(--border)}
.topbar-title{font-size:16px;font-weight:700;color:var(--ink)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.btn-primary{height:38px;padding:0 18px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;border-radius:10px;font-size:13.5px;font-weight:700;cursor:pointer;text-decoration:none;display:inline-flex;align-items:center;gap:7px;font-family:inherit;transition:all .15s;box-shadow:0 3px 10px rgba(21,88,168,.25)}
.btn-primary:hover{transform:translateY(-1px);box-shadow:0 5px 15px rgba(21,88,168,.32)}
.btn-secondary{height:38px;padding:0 18px;background:var(--white);color:var(--blue);border:1.5px solid var(--blue);border-radius:10px;font-size:13.5px;font-weight:700;cursor:pointer;font-family:inherit;display:inline-flex;align-items:center;gap:7px;transition:all .15s}
.btn-secondary:hover{background:#EFF6FF}
.content{padding:24px 28px;flex:1}
.page-header{margin-bottom:20px}
.page-title{font-size:26px;font-weight:800;color:var(--ink)}
.page-sub{font-size:13px;color:var(--muted);margin-top:3px}
/* ── UNDERLINE NAV TABS ── */
.u-tabs{display:flex;border-bottom:2px solid var(--border);margin-bottom:20px;gap:0}
.u-tab{padding:10px 22px;font-size:14px;font-weight:600;color:var(--muted);text-decoration:none;border-bottom:3px solid transparent;margin-bottom:-2px;transition:all .18s;white-space:nowrap}
.u-tab:hover{color:var(--blue);background:rgba(21,88,168,.03)}
.u-tab.active{color:var(--blue);border-bottom-color:var(--blue)}
/* ── ALERT TABS ── */
.cat-tab-bar{display:flex;gap:6px;flex-wrap:wrap;margin-bottom:14px;align-items:center}
.cat-tab{height:34px;padding:0 14px;border-radius:20px;font-size:12.5px;font-weight:600;color:var(--muted);border:1.5px solid var(--border);background:var(--white);cursor:pointer;white-space:nowrap;transition:all .14s;display:inline-flex;align-items:center;gap:6px;font-family:inherit}
.cat-tab:hover{border-color:var(--blue);color:var(--blue);background:#EFF6FF}
.cat-tab.active{background:var(--blue);color:#fff;border-color:var(--blue);box-shadow:0 2px 8px rgba(21,88,168,.28)}
.cat-tab.tab-warn.active{background:var(--gold);border-color:var(--gold)}
.cat-tab.tab-expiring.active{background:#7C3AED;border-color:#7C3AED}
.cat-tab.tab-expired.active{background:var(--red);border-color:var(--red)}
.tab-badge{display:inline-flex;align-items:center;justify-content:center;min-width:18px;height:18px;padding:0 5px;border-radius:9px;font-size:10px;font-weight:800;background:rgba(0,0,0,.1)}
.cat-tab.active .tab-badge{background:rgba(255,255,255,.25)}
.tab-sep{width:1px;height:22px;background:var(--border);flex-shrink:0;margin:0 2px}
/* ── STATS ── */
.stats-row{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:22px}
.stat-card{background:var(--white);border:2px solid var(--border);border-radius:14px;padding:16px 18px;cursor:pointer;transition:all .18s;user-select:none}
.stat-card:hover{border-color:var(--blue);box-shadow:0 4px 16px rgba(21,88,168,.12);transform:translateY(-1px)}
.stat-card.sc-active{border-color:var(--blue);box-shadow:0 0 0 3px rgba(21,88,168,.12),0 4px 16px rgba(21,88,168,.12);transform:translateY(-2px)}
.stat-card.warn.sc-active{border-color:var(--gold);box-shadow:0 0 0 3px rgba(217,119,6,.12),0 4px 16px rgba(217,119,6,.12)}
.stat-card.danger.sc-active{border-color:var(--red);box-shadow:0 0 0 3px rgba(220,38,38,.12),0 4px 16px rgba(220,38,38,.12)}
.stat-card.sc-active .stat-lbl::before{content:'▶ ';font-size:10px}
.stat-val{font-size:26px;font-weight:800;color:var(--ink)}
.stat-lbl{font-size:12px;color:var(--muted);margin-top:3px}
.stat-card.warn .stat-val{color:var(--gold)}
.stat-card.danger .stat-val{color:var(--red)}
/* ── ICON ACTION BUTTONS ── */
.action-btns{display:flex;gap:2px;align-items:center}
.btn-icon{width:32px;height:32px;border-radius:8px;border:none;background:transparent;cursor:pointer;font-size:16px;display:inline-flex;align-items:center;justify-content:center;transition:background .12s;flex-shrink:0;text-decoration:none;color:var(--muted)}
.btn-icon:hover{background:var(--surface);color:var(--ink)}
.btn-icon.i-edit:hover{background:#F5F3FF;color:#7C3AED}
.btn-icon.i-hide:hover{background:#FFFBEB;color:var(--gold)}
.btn-icon.i-show:hover{background:#F0FDF4;color:var(--green)}
.btn-icon.i-del:hover{background:#FFF5F5;color:var(--red)}
/* ── PAGINATION ── */
.pager{display:flex;align-items:center;gap:12px;padding:16px 20px 12px;flex-wrap:wrap;border-top:1px solid var(--border)}
.pager-info{font-size:13px;color:var(--muted);flex:1;min-width:160px}
.pager-info strong{color:var(--ink);font-weight:700}
.pager-nav{display:flex;gap:4px;align-items:center}
.pager-btn{min-width:34px;height:34px;padding:0 8px;border-radius:8px;border:1.5px solid var(--border);background:var(--white);color:var(--ink);font-size:13px;font-weight:600;cursor:pointer;font-family:inherit;display:inline-flex;align-items:center;justify-content:center;transition:all .14s;text-decoration:none}
.pager-btn:hover{border-color:var(--blue);color:var(--blue);background:#EFF6FF}
.pager-btn.active{background:var(--blue);border-color:var(--blue);color:#fff;box-shadow:0 2px 8px rgba(21,88,168,.28)}
.pager-btn:disabled,.pager-btn.disabled{opacity:.4;cursor:default;pointer-events:none}
.pager-btn.pager-ellipsis{border:none;background:transparent;cursor:default;color:var(--muted)}
.pager-size{height:34px;padding:0 10px;border:1.5px solid var(--border);border-radius:8px;font-size:12.5px;font-family:inherit;background:var(--white);cursor:pointer;color:var(--ink);outline:none}
/* ── ACTION BAR ── */
.action-bar{display:flex;align-items:center;gap:10px;margin-bottom:16px;flex-wrap:wrap}
.action-bar-left{display:flex;align-items:center;gap:10px;flex:1;flex-wrap:wrap;min-width:0}
.action-bar-right{display:flex;align-items:center;gap:8px;flex-shrink:0}
/* ── TOOLBAR ── (kept for compat) */
.toolbar{display:flex;align-items:center;gap:10px;margin-bottom:16px;flex-wrap:wrap}
.search-wrap{position:relative;flex:1;min-width:220px}
.search-wrap input{width:100%;height:38px;padding:0 12px 0 38px;border:1.5px solid var(--border);border-radius:10px;font-size:13.5px;font-family:inherit;outline:none;transition:.15s;background:var(--white)}
.search-wrap input:focus{border-color:var(--blue)}
.search-icon{position:absolute;left:11px;top:50%;transform:translateY(-50%);font-size:15px;color:var(--muted)}
.filter-select{height:38px;padding:0 10px;border:1.5px solid var(--border);border-radius:10px;font-size:13px;font-family:inherit;background:var(--white);outline:none;cursor:pointer}
.btn-filter{height:38px;padding:0 16px;border:1.5px solid var(--blue);border-radius:10px;background:var(--white);color:var(--blue);font-size:13px;font-weight:600;cursor:pointer;font-family:inherit}
/* ── CUSTOM SELECT ── */
.cs-wrap{position:relative;display:inline-block}
.cs-trigger{height:38px;padding:0 30px 0 12px;border:1.5px solid var(--border);border-radius:10px;font-size:13px;font-family:inherit;background:var(--white);cursor:pointer;display:flex;align-items:center;min-width:190px;user-select:none;transition:border-color .15s;color:var(--ink);white-space:nowrap;gap:7px}
.cs-trigger:hover{border-color:var(--blue)}
.cs-wrap.open .cs-trigger{border-color:var(--blue);box-shadow:0 0 0 3px rgba(21,88,168,.09)}
.cs-label{flex:1;overflow:hidden;text-overflow:ellipsis;font-size:13px}
.cs-arrow{position:absolute;right:10px;top:50%;transform:translateY(-50%);font-size:9px;color:var(--muted);transition:transform .18s;pointer-events:none}
.cs-wrap.open .cs-arrow{transform:translateY(-50%) rotate(180deg);color:var(--blue)}
.cs-panel{position:absolute;top:calc(100% + 6px);left:0;min-width:220px;background:var(--white);border:1.5px solid var(--border);border-radius:12px;box-shadow:0 8px 28px rgba(11,22,40,.14);z-index:400;overflow:hidden;display:none}
.cs-wrap.open .cs-panel{display:block;animation:csIn .13s ease}
@keyframes csIn{from{opacity:0;transform:translateY(-5px)}to{opacity:1;transform:none}}
.cs-opt{padding:9px 14px;font-size:13px;cursor:pointer;display:flex;align-items:center;gap:9px;color:var(--ink);transition:.1s;white-space:nowrap}
.cs-opt:hover{background:#F0F6FF;color:var(--blue)}
.cs-opt.cs-sel{color:var(--blue);font-weight:700;background:#EFF6FF}
.cs-opt.cs-all{border-bottom:1px solid var(--border);font-weight:600;color:var(--ink)}
.cs-opt.cs-all:hover{background:#F8FAFE;color:var(--blue)}
.cs-opt.cs-dot-icon{width:7px;height:7px;border-radius:50%;flex-shrink:0;background:var(--blue);opacity:.6}
/* ── TABLE ── */
.table-wrap{background:var(--white);border:1px solid var(--border);border-radius:16px;overflow:hidden}
table{width:100%;border-collapse:collapse}
thead th{padding:11px 14px;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:var(--muted);background:#F8FAFE;border-bottom:1px solid var(--border);text-align:left;white-space:nowrap}
tbody td{padding:12px 14px;font-size:13.5px;border-bottom:.5px solid #F0F4FB;vertical-align:middle}
tbody tr:last-child td{border-bottom:none}
tbody tr:hover td{background:#FAFBFF}
.med-name{font-weight:700;color:var(--ink)}
.med-code{font-size:11px;color:var(--muted);font-family:monospace;margin-top:1px}
.badge{display:inline-flex;align-items:center;padding:3px 9px;border-radius:20px;font-size:11px;font-weight:700}
.badge-green{background:#D1FAE5;color:#065F46}
.badge-red{background:#FEE2E2;color:#991B1B}
.badge-gold{background:#FEF3C7;color:#92400E}
.badge-gray{background:#F1F5F9;color:#64748B}
.badge-blue{background:#EFF6FF;color:#1D4ED8}
.stock-val{font-weight:800;font-size:14px}
.stock-ok{color:var(--green)}.stock-low{color:var(--gold)}.stock-out{color:var(--red)}
.price-val{font-weight:700;color:var(--blue)}
.action-btns{display:flex;gap:6px;flex-wrap:nowrap}
.btn-sm{height:30px;padding:0 10px;border-radius:8px;font-size:12px;font-weight:600;cursor:pointer;border:1.5px solid;font-family:inherit;white-space:nowrap;text-decoration:none;display:inline-flex;align-items:center;gap:4px;transition:all .12s}
.btn-detail{color:var(--blue);border-color:#BFDBFE;background:#EFF6FF}
.btn-detail:hover{background:#DBEAFE}
.btn-edit{color:#7C3AED;border-color:#DDD6FE;background:#F5F3FF}
.btn-edit:hover{background:#EDE9FE}
.btn-toggle{color:var(--gold);border-color:#FDE68A;background:#FFFBEB}
.btn-toggle:hover{background:#FEF3C7}
.btn-del{color:var(--red);border-color:#FECACA;background:#FFF5F5}
.btn-del:hover{background:#FEE2E2}
.empty-row td{text-align:center;padding:40px;color:var(--muted);font-size:14px}
/* ── MFR MANAGE LIST ── */
.mfr-manage-section{margin-top:18px;border-top:1px solid #E8EEF8;padding-top:14px}
.mfr-manage-title{font-size:11.5px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:10px}
.mfr-list-wrap{max-height:160px;overflow-y:auto;display:flex;flex-direction:column;gap:6px}
.mfr-row{display:flex;align-items:center;justify-content:space-between;padding:8px 12px;background:var(--surface);border-radius:9px;gap:8px}
.mfr-row-name{font-size:13px;font-weight:600;color:var(--navy);flex:1;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.mfr-del-btn{width:28px;height:28px;border-radius:7px;border:1px solid #FCA5A5;background:#FEF2F2;color:#DC2626;cursor:pointer;font-size:13px;display:flex;align-items:center;justify-content:center;flex-shrink:0;transition:all .15s}
.mfr-del-btn:hover{background:#FEE2E2}
/* ── PO MODAL ── */
.po-modal-body{padding:24px}
.po-field{margin-bottom:16px}
.po-label{font-size:12.5px;font-weight:700;color:var(--navy);display:block;margin-bottom:6px}
.po-input,.po-select,.po-textarea{width:100%;padding:10px 14px;border:1.5px solid var(--border);border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;color:var(--ink);outline:none;box-sizing:border-box;transition:border-color .15s}
.po-select{height:44px}
.po-textarea{resize:vertical;min-height:80px}
.po-input:focus,.po-select:focus,.po-textarea:focus{border-color:var(--blue)}
.po-actions{display:flex;gap:10px;margin-top:20px}
.po-btn-save{flex:1;height:44px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;border-radius:11px;font-family:'Outfit',sans-serif;font-size:14px;font-weight:700;cursor:pointer}
.po-btn-save:disabled{opacity:.6;cursor:default}
.po-btn-cancel{height:44px;padding:0 20px;background:#fff;border:1.5px solid var(--border);border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;color:var(--muted);cursor:pointer}
/* ── EXPAND BUTTON ── */
.expand-btn{width:26px;height:26px;border-radius:7px;border:1.5px solid var(--border);background:var(--white);cursor:pointer;font-size:12px;color:var(--muted);display:flex;align-items:center;justify-content:center;transition:all .18s;flex-shrink:0;line-height:1}
.expand-btn:hover{border-color:var(--blue);color:var(--blue);background:#EFF6FF}
.expand-btn.open{transform:rotate(90deg);border-color:var(--blue);color:var(--blue);background:#EFF6FF}
.expand-cell{display:flex;align-items:center;gap:8px;white-space:nowrap}
/* ── BATCH SUB ROW ── */
.batch-expand-row>td{padding:0;border-bottom:.5px solid #E8EEF8}
.batch-sub-wrap{padding:0 16px 16px 60px;background:#F5F8FE}
.batch-sub-header{padding:10px 0 8px;font-size:11px;font-weight:800;color:var(--navy);text-transform:uppercase;letter-spacing:.5px;display:flex;align-items:center;gap:8px}
.batch-sub-header::before{content:'';flex:1;height:1px;background:var(--border)}
.batch-mini-table{width:100%;border-collapse:collapse;background:var(--white);border-radius:10px;overflow:hidden;box-shadow:0 1px 6px rgba(0,0,0,.06);font-size:12.5px}
.batch-mini-table th{padding:8px 12px;font-size:10.5px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.4px;background:#F8FAFE;border-bottom:1px solid var(--border);text-align:left;white-space:nowrap}
.batch-mini-table td{padding:9px 12px;border-bottom:.5px solid #F0F4FB;vertical-align:middle}
.batch-mini-table tbody tr:last-child td{border-bottom:none}
.batch-mini-table tbody tr:hover td{background:#FAFBFF}
.bno{font-family:monospace;font-weight:700;color:var(--navy);font-size:12px}
.exp-red{color:var(--red);font-weight:800}
.exp-gold{color:var(--gold);font-weight:700}
.exp-ok{color:var(--green);font-weight:600}
.bst-active{background:#D1FAE5;color:#065F46}
.bst-destroyed{background:#FEE2E2;color:#991B1B}
.bst-cancelled{background:#F1F5F9;color:#64748B}
.batch-sub-empty{padding:18px 20px;text-align:center;color:var(--muted);font-size:13px}
.batch-sub-loading{padding:18px 20px;text-align:center;color:var(--muted);font-size:12.5px;display:flex;align-items:center;justify-content:center;gap:8px}
.td-med{cursor:default;position:relative}
.td-med:hover .med-name{color:var(--blue)}
.shelf-chip{display:inline-flex;align-items:center;gap:3px;font-size:10.5px;font-weight:700;color:#6D28D9;background:#F5F3FF;border:1px solid #DDD6FE;border-radius:5px;padding:1px 6px;margin-top:3px}
.med-cell-inner{display:flex;align-items:flex-start;gap:10px}
.med-avatar{width:38px;height:38px;border-radius:9px;object-fit:cover;border:1px solid var(--border);flex-shrink:0;margin-top:1px}
.med-avatar-ph{width:38px;height:38px;border-radius:9px;background:linear-gradient(135deg,#EFF6FF,#DBEAFE);display:flex;align-items:center;justify-content:center;font-size:20px;flex-shrink:0;border:1px solid #BFDBFE;margin-top:1px}
/* Image upload in drawer */
.img-upload-wrap{display:flex;align-items:center;gap:12px;padding:10px 12px;background:#FAFBFD;border:1.5px dashed var(--border);border-radius:10px;cursor:pointer;transition:.15s}
.img-upload-wrap:hover{border-color:var(--cyan);background:#F0FBFE}
.img-preview{width:56px;height:56px;border-radius:9px;object-fit:cover;border:1px solid var(--border);flex-shrink:0}
.img-preview-ph{width:56px;height:56px;border-radius:9px;background:linear-gradient(135deg,#EFF6FF,#DBEAFE);display:flex;align-items:center;justify-content:center;font-size:28px;border:1px solid #BFDBFE;flex-shrink:0}
.img-upload-info{flex:1;min-width:0}
.img-upload-label{font-size:13px;font-weight:600;color:var(--navy);margin-bottom:2px}
.img-upload-hint{font-size:11.5px;color:var(--muted)}
/* ── HOVER CARD ── */
.hover-card{position:fixed;z-index:800;background:var(--navy);color:#fff;border-radius:14px;padding:14px 16px;min-width:230px;max-width:270px;box-shadow:0 8px 32px rgba(0,0,0,.32);pointer-events:none;opacity:0;transition:opacity .14s;font-size:12.5px;line-height:1.4}
.hover-card.show{opacity:1}
.hc-name{font-size:13px;font-weight:800;margin-bottom:10px;color:#fff;border-bottom:1px solid rgba(255,255,255,.12);padding-bottom:8px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.hc-row{display:flex;justify-content:space-between;align-items:center;margin-bottom:5px;gap:8px}
.hc-row:last-child{margin-bottom:0}
.hc-label{color:rgba(255,255,255,.55);font-size:11.5px;flex:1}
.hc-val{font-weight:700;color:#fff;text-align:right;font-size:12.5px}
.hc-val.ok{color:#6EE7B7}.hc-val.warn{color:#FCD34D}.hc-val.err{color:#FCA5A5}
.hc-divider{height:1px;background:rgba(255,255,255,.1);margin:8px 0}
/* ── TOAST ── */
.toast{position:fixed;top:72px;right:24px;z-index:999;padding:12px 20px;border-radius:12px;font-size:13.5px;font-weight:600;box-shadow:0 4px 24px rgba(0,0,0,.12);display:flex;align-items:center;gap:10px}
.toast-ok{background:#ECFDF5;color:#065F46;border:1px solid #A7F3D0}
.toast-warn{background:#FFFBEB;color:#92400E;border:1px solid #FDE68A}
.toast-err{background:#FFF5F5;color:#991B1B;border:1px solid #FECACA}
/* ── DRAWER ── */
.dw-overlay{position:fixed;inset:0;background:rgba(11,22,40,.45);z-index:200;display:none;backdrop-filter:blur(2px)}
.dw-overlay.open{display:block;animation:fadeOverlay .22s ease}
@keyframes fadeOverlay{from{opacity:0}to{opacity:1}}
.drawer{position:fixed;top:0;right:0;bottom:0;width:520px;background:var(--white);z-index:201;transform:translateX(100%);transition:transform .3s cubic-bezier(.4,0,.2,1);box-shadow:-10px 0 50px rgba(0,0,0,.16);display:flex;flex-direction:column;overflow:hidden}
.drawer.open{transform:none}
.dw-head{padding:18px 24px;background:linear-gradient(90deg,#0F2645,#1558A8);color:#fff;display:flex;align-items:center;gap:12px;flex-shrink:0}
.dw-head-icon{width:36px;height:36px;border-radius:10px;background:rgba(255,255,255,.15);display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0}
.dw-title{font-size:15px;font-weight:800;flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.dw-sub{font-size:11.5px;opacity:.6;margin-top:1px}
.dw-close{width:32px;height:32px;background:rgba(255,255,255,.12);border:none;color:#fff;border-radius:9px;cursor:pointer;font-size:16px;display:flex;align-items:center;justify-content:center;flex-shrink:0}
.dw-close:hover{background:rgba(255,255,255,.25)}
.dw-body{flex:1;overflow-y:auto;padding:20px 24px;background:#F8FAFC}
.dw-body::-webkit-scrollbar{width:4px}
.dw-body::-webkit-scrollbar-track{background:transparent}
.dw-body::-webkit-scrollbar-thumb{background:#D5E0F0;border-radius:2px}
.dw-foot{padding:14px 24px;background:#FAFBFD;border-top:1px solid var(--border);display:flex;gap:10px;align-items:center;flex-shrink:0}
/* Form inside drawer */
.data-container{background:var(--white);border-radius:16px;border:1px solid var(--border);box-shadow:0 4px 20px rgba(0,0,0,0.03);padding:20px}
.data-container .table-wrap{border:none;border-radius:0}
.dw-section{margin-bottom:18px;background:#fff;padding:20px;border-radius:12px;box-shadow:0 4px 15px rgba(0,0,0,.03)}
.dw-section-title{font-size:12px;font-weight:800;color:var(--navy);text-transform:uppercase;letter-spacing:.5px;margin-bottom:10px;display:flex;align-items:center;gap:7px}
.dw-section-title::after{content:'';flex:1;height:1px;background:var(--border)}
.dw-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px}
.dw-field{display:flex;flex-direction:column;gap:4px}
.dw-field.span-2{grid-column:1/-1}
.dw-label{font-size:12px;font-weight:700;color:var(--navy);display:flex;justify-content:space-between;align-items:center}
.req{color:var(--red)}
.dw-input{height:40px;padding:0 12px;background:#fff;border:1.5px solid var(--border);border-radius:10px;font-family:'Outfit',sans-serif;font-size:13.5px;color:var(--ink);outline:none;transition:border-color .18s;width:100%}
.dw-input:focus{border-color:var(--cyan);box-shadow:0 0 0 3px rgba(58,189,224,.08)}
.dw-input::placeholder{color:#B8CCE0}
select.dw-input{appearance:none;cursor:pointer;background:#fff url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='10' height='6' fill='none'%3E%3Cpath stroke='%237A90B0' stroke-width='1.5' stroke-linecap='round' d='M1 1l4 4 4-4'/%3E%3C/svg%3E") no-repeat right 12px center;padding-right:30px}
textarea.dw-input{height:72px;padding:9px 12px;resize:vertical}
.price-wrap{position:relative}
.price-wrap .dw-input{padding-right:30px}
.price-sfx{position:absolute;right:11px;top:50%;transform:translateY(-50%);font-size:11px;font-weight:700;color:var(--muted);pointer-events:none}
.add-btn-xs{height:22px;padding:0 8px;background:rgba(58,189,224,.1);border:1.5px solid rgba(58,189,224,.3);border-radius:6px;font-size:11px;font-weight:700;color:#1558A8;cursor:pointer;flex-shrink:0}
.checkbox-row-dw{display:flex;align-items:center;gap:9px;padding:10px 12px;background:rgba(245,158,11,.06);border:1.5px solid rgba(245,158,11,.2);border-radius:10px;cursor:pointer;grid-column:1/-1}
.checkbox-row-dw input{width:16px;height:16px;cursor:pointer;accent-color:var(--gold)}
.checkbox-row-dw label{font-size:13px;font-weight:600;color:#92400E;cursor:pointer}
/* Initial stock (Create only) */
.init-stock-dw{background:linear-gradient(135deg,#F0FDF4,#ECFDF5);border:1.5px solid #A7F3D0;border-radius:12px;padding:12px 16px;margin-top:4px;grid-column:1/-1}
.init-stock-toggle-dw{display:flex;align-items:flex-start;gap:9px;cursor:pointer;font-size:13px;font-weight:600;color:#065F46}
.init-stock-toggle-dw input{width:16px;height:16px;accent-color:#059669;cursor:pointer;flex-shrink:0;margin-top:2px}
.init-stock-fields-dw{display:grid;grid-template-columns:1fr 1fr 1fr;gap:10px;margin-top:12px}
/* Drawer save button */
.btn-dw-save{height:40px;padding:0 22px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;border-radius:10px;font-family:'Outfit',sans-serif;font-size:14px;font-weight:700;cursor:pointer;box-shadow:0 3px 10px rgba(21,88,168,.22);transition:.18s}
.btn-dw-save:hover{transform:translateY(-1px)}
.btn-dw-cancel{height:40px;padding:0 16px;background:var(--white);border:1.5px solid var(--border);border-radius:10px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;color:var(--muted);cursor:pointer}
.btn-dw-cancel:hover{border-color:var(--blue);color:var(--navy)}
.dw-foot-hint{margin-left:auto;font-size:11.5px;color:var(--muted)}
/* Loading indicator */
.dw-loading{display:flex;align-items:center;justify-content:center;height:200px;flex-direction:column;gap:12px;color:var(--muted);font-size:13px}
.dw-spinner{width:32px;height:32px;border:3px solid var(--border);border-top-color:var(--blue);border-radius:50%;animation:spin .7s linear infinite}
@keyframes spin{to{transform:rotate(360deg)}}
</style>
</head>
<body>

<%-- Hover card --%>
<div id="hoverCard" class="hover-card">
  <div class="hc-name" id="hc-name"></div>
  <div class="hc-row"><span class="hc-label">Tổng tồn kho</span><span class="hc-val ok" id="hc-stock"></span></div>
  <div class="hc-row"><span class="hc-label">Lô đang hoạt động</span><span class="hc-val" id="hc-batches"></span></div>
  <div class="hc-row" id="hc-shelf-row"><span class="hc-label">📍 Vị trí kệ</span><span class="hc-val" id="hc-shelf" style="color:#C4B5FD"></span></div>
  <div class="hc-divider"></div>
  <div class="hc-row"><span class="hc-label">HSD gần nhất</span><span class="hc-val" id="hc-expiry"></span></div>
  <div class="hc-row"><span class="hc-label">Lô sắp hết hạn ≤90 ngày</span><span class="hc-val warn" id="hc-soon"></span></div>
  <div class="hc-row"><span class="hc-label">Lô đã hết hạn còn tồn</span><span class="hc-val err" id="hc-expired"></span></div>
</div>

<%-- Toast --%>
<% if ("created".equals(msg)) { %><div class="toast toast-ok" id="pageToast">✅ Đã thêm thuốc mới thành công!</div>
<% } else if ("updated".equals(msg)) { %><div class="toast toast-ok" id="pageToast">✅ Đã cập nhật thông tin thuốc!</div>
<% } else if ("deleted".equals(msg)) { %><div class="toast toast-warn" id="pageToast">🗑️ Đã ẩn thuốc khỏi danh sách.</div>
<% } else if ("has-stock".equals(msg)) { %><div class="toast toast-err" id="pageToast">⚠️ Không thể xóa — thuốc còn tồn kho!</div>
<% } else if ("error".equals(msg)) { %><div class="toast toast-err" id="pageToast">❌ Có lỗi xảy ra, thử lại!</div>
<% } %>

<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">
  <div class="topbar">
    <span class="topbar-title">💊 Kho thuốc</span>
    <div class="topbar-right">
      <%-- Alert chips — chỉ hiện khi có vấn đề --%>
      <c:choose>
        <c:when test="${totalExpiredMeds > 0}">
          <button class="tb-chip tb-chip-red" onclick="switchCard('expired')" title="Bấm để lọc thuốc có lô hết hạn">
            ⛔ ${totalExpiredMeds} lô hết hạn
          </button>
        </c:when>
      </c:choose>
      <c:choose>
        <c:when test="${totalExpiringSoon > 0}">
          <button class="tb-chip tb-chip-gold" onclick="switchCard('expiring')" title="Bấm để lọc thuốc sắp hết hạn">
            ⏳ ${totalExpiringSoon} lô cận date
          </button>
        </c:when>
      </c:choose>
      <c:choose>
        <c:when test="${lowStock > 0}">
          <button class="tb-chip tb-chip-gold" onclick="switchCard('low')" title="Bấm để lọc thuốc sắp hết hàng">
            ⚠️ ${lowStock} sắp hết hàng
          </button>
        </c:when>
        <c:otherwise>
          <span class="tb-chip tb-chip-ok" title="Tồn kho ổn định">✅ Tồn kho ổn định</span>
        </c:otherwise>
      </c:choose>
      <%-- Clock --%>
      <div class="topbar-clock">
        <span id="tbH">--</span><span class="clock-sep">:</span><span id="tbM">--</span>
        <span class="clock-date" id="tbDate"></span>
      </div>
      <%-- Avatar --%>
      <div class="tb-avatar" title="<%= fullName %>"><%= initials %></div>
    </div>
  </div>

  <div class="content">
    <div class="page-header" style="display:flex; justify-content:space-between; align-items:flex-end;">
      <div>
        <div class="page-title"><span style="font-size:32px;margin-right:8px">📦</span>Quản lý Tồn Kho & Lô Hàng</div>
        <div class="page-sub">Kiểm soát danh mục thuốc, biến động tồn kho và lô hàng cận date</div>
      </div>
    </div>

    <div class="u-tabs">
      <a href="${pageContext.request.contextPath}/medicines"       class="u-tab active">💊 Thuốc &amp; Lô hàng</a>
      <a href="${pageContext.request.contextPath}/purchase-orders" class="u-tab">📑 Đơn đặt hàng</a>
      <a href="${pageContext.request.contextPath}/categories"      class="u-tab">🏷️ Danh mục</a>
    </div>

    <div class="stats-row">
      <div class="stat-card sc-active" id="scAll" onclick="switchCard('all')">
        <div class="stat-val">${totalActive}</div>
        <div class="stat-lbl">💊 Thuốc đang kinh doanh</div>
      </div>
      <div class="stat-card warn" id="scLow" onclick="switchCard('low')">
        <div class="stat-val">${lowStock}</div>
        <div class="stat-lbl">⚠️ Sắp hết hàng</div>
      </div>
      <div class="stat-card danger" id="scExpiring" onclick="switchCard('expiring')">
        <div class="stat-val">${totalExpiringSoon}</div>
        <div class="stat-lbl">⏳ Thuốc có lô cận HH</div>
      </div>
      <div class="stat-card danger" id="scExpired" onclick="switchCard('expired')">
        <div class="stat-val">${totalExpiredMeds}</div>
        <div class="stat-lbl">⛔ Thuốc có lô đã HH</div>
      </div>
    </div>

    <div class="data-container">
      <form method="get" action="${pageContext.request.contextPath}/medicines">
        <div class="action-bar">
          <div class="action-bar-left">
            <div class="search-wrap">
              <span class="search-icon">🔍</span>
              <input type="text" name="q" placeholder="Tìm theo tên, hoạt chất, barcode, mã thuốc..."
                     value="${keyword}" id="searchInput"/>
            </div>
            <div class="cs-wrap" id="csCatWrap">
              <div class="cs-trigger" onclick="toggleCs()">
                <span class="cs-label" id="csLabel">Tất cả danh mục</span>
                <span class="cs-arrow">▼</span>
              </div>
              <div class="cs-panel" id="csPanel">
                <div class="cs-opt cs-all ${empty catId ? 'cs-sel' : ''}" data-val="" onclick="selectCs(this,'')">
                  Tất cả danh mục
                </div>
                <c:forEach var="cat" items="${categories}">
                  <div class="cs-opt ${catId == cat.categoryId ? 'cs-sel' : ''}"
                       data-val="${cat.categoryId}" onclick="selectCs(this,'${cat.categoryId}')">
                    <span style="width:7px;height:7px;border-radius:50%;background:var(--blue);opacity:.6;flex-shrink:0;display:inline-block"></span>
                    ${cat.categoryName}
                  </div>
                </c:forEach>
              </div>
              <input type="hidden" id="catFilter" name="catId" value="${catId}">
            </div>
            <select class="filter-select" id="statusFilter" name="statusFilter" onchange="filterRows()">
              <option value=""         ${statusFilter == ''         ? 'selected' : ''}>Tất cả trạng thái</option>
              <option value="active"   ${statusFilter == 'active'   ? 'selected' : ''}>Đang kinh doanh</option>
              <option value="inactive" ${statusFilter == 'inactive' ? 'selected' : ''}>Đã ẩn</option>
              <option value="low"      ${statusFilter == 'low'      ? 'selected' : ''}>Sắp hết hàng</option>
              <option value="out"      ${statusFilter == 'out'      ? 'selected' : ''}>Hết hàng</option>
            </select>
            <button type="submit" class="btn-filter">🔍 Tìm</button>
          </div>
          <div class="action-bar-right">
            <button type="button" class="btn-primary" onclick="openPoModal()">📦 Tạo phiếu nhập kho</button>
            <button type="button" class="btn-secondary" onclick="openAddPanel()">＋ Thêm thuốc mới</button>
          </div>
        </div>
      </form>

    <div class="table-wrap">
      <table>
        <thead>
          <tr>
            <th>#</th><th>Thuốc</th><th>Danh mục</th><th>Đơn vị</th>
            <th style="text-align:right">Giá bán</th><th style="text-align:right">Tồn kho</th><th>Loại</th><th>Trạng thái</th><th>Thao tác</th>
          </tr>
        </thead>
        <tbody id="medTable">
          <c:choose>
            <c:when test="${empty medicines}">
              <tr class="empty-row">
                <td colspan="9">
                  <c:choose>
                    <c:when test="${not empty keyword || not empty catId}">
                      🔍 Không tìm thấy kết quả nào phù hợp với bộ lọc hiện tại.
                    </c:when>
                    <c:otherwise>
                      💊 Chưa có thuốc nào.
                      <a href="javascript:void(0)" onclick="openAddPanel()" style="color:var(--blue);font-weight:700">Thêm thuốc đầu tiên</a>
                    </c:otherwise>
                  </c:choose>
                </td>
              </tr>
            </c:when>
            <c:otherwise>
              <c:forEach var="m" items="${medicines}" varStatus="st">
                <c:set var="stock"          value="${stockMap[m.medicineId]}"/>
                <c:set var="activeBatches"  value="${activeBatchCountMap[m.medicineId]}"/>
                <c:set var="soonBatches"    value="${expiringSoonCountMap[m.medicineId]}"/>
                <c:set var="expiredBatches" value="${expiredBatchCountMap[m.medicineId]}"/>
                <c:set var="nearestExp"     value="${nearestExpiryMap[m.medicineId]}"/>
                <c:set var="shelfLabel" value=""/>
                <c:forEach var="sh" items="${shelves}">
                  <c:if test="${sh.shelfId == m.shelfId}"><c:set var="shelfLabel" value="${sh.shelfName}"/></c:if>
                </c:forEach>
                <tr data-name="${fn:toLowerCase(m.medicineName)}"
                    data-shelf="${fn:escapeXml(shelfLabel)}"
                    data-cat="${m.categoryId}"
                    data-status="${m.status ? 'active' : 'inactive'}"
                    data-stock="${stock}"
                    data-min-inv="${m.minInventory}"
                    data-unit="${m.unit}"
                    data-active-batches="${empty activeBatches ? 0 : activeBatches}"
                    data-expiring-soon="${empty soonBatches ? 0 : soonBatches}"
                    data-expired="${empty expiredBatches ? 0 : expiredBatches}"
                    data-nearest-expiry="${nearestExp}"
                    data-med-name="${m.medicineName}"
                    data-med-id="${m.medicineId}"
                    class="med-row">
                  <td style="color:var(--muted);font-size:12px">
                    <div class="expand-cell">
                      <button type="button" class="expand-btn"
                              onclick="toggleExpand(this,${m.medicineId})"
                              title="Xem lô hàng">›</button>
                      <span>${st.index+1}</span>
                    </div>
                  </td>
                  <td class="td-med"
                      onmouseenter="showHoverCard(this.closest('tr'),event)"
                      onmouseleave="hideHoverCard()"
                      onmousemove="moveHoverCard(event)">
                    <div class="med-cell-inner">
                      <c:choose>
                        <c:when test="${not empty m.imageUrl}">
                          <img src="${pageContext.request.contextPath}/${m.imageUrl}" class="med-avatar" alt="${fn:escapeXml(m.medicineName)}">
                        </c:when>
                        <c:otherwise><div class="med-avatar-ph">💊</div></c:otherwise>
                      </c:choose>
                      <div>
                        <div class="med-name">${m.medicineName}</div>
                        <div class="med-code">${m.medicineCode}<c:if test="${not empty m.genericName}"> · ${m.genericName}</c:if></div>
                        <c:if test="${not empty m.packagingSpec}"><div class="med-code" style="color:#059669;margin-top:1px">📦 ${m.packagingSpec}</div></c:if>
                        <c:if test="${not empty shelfLabel}"><span class="shelf-chip">📍 ${shelfLabel}</span></c:if>
                      </div>
                    </div>
                  </td>
                  <td>
                    <c:forEach var="cat" items="${categories}">
                      <c:if test="${cat.categoryId == m.categoryId}">
                        <span class="badge badge-blue">${cat.categoryName}</span>
                      </c:if>
                    </c:forEach>
                  </td>
                  <td>${m.unit}</td>
                  <td class="price-val" style="text-align:right"><fmt:formatNumber value="${m.sellingPrice}" type="number" maxFractionDigits="0"/>đ</td>
                  <td style="text-align:right">
                    <div style="text-align:right">
                      <c:choose>
                        <c:when test="${stock == 0}">
                          <span class="stock-val stock-out">0</span>
                          <span class="badge badge-red" style="margin-left:4px">Hết hàng</span>
                        </c:when>
                        <c:when test="${stock <= m.minInventory}">
                          <span class="stock-val stock-low">${stock}</span>
                          <span class="badge badge-gold" style="margin-left:4px">Sắp hết</span>
                        </c:when>
                        <c:otherwise>
                          <span class="stock-val stock-ok">${stock}</span>
                        </c:otherwise>
                      </c:choose>
                    </div>
                    <c:if test="${not empty soonBatches and soonBatches > 0}">
                      <div class="badge badge-gold" style="margin-top:5px;font-size:10px;padding:2px 6px">
                        ⚠️ ${soonBatches} lô cận date
                      </div>
                    </c:if>
                    <c:if test="${not empty expiredBatches and expiredBatches > 0}">
                      <div class="badge badge-red" style="margin-top:5px;font-size:10px;padding:2px 6px">
                        ⛔ ${expiredBatches} lô hết hạn
                      </div>
                    </c:if>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${m.prescriptionRequired}"><span class="badge badge-red">Kê toa</span></c:when>
                      <c:otherwise><span class="badge badge-green">OTC</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${m.status}"><span class="badge badge-green">Đang bán</span></c:when>
                      <c:otherwise><span class="badge badge-gray">Đã ẩn</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <div class="action-btns">
                      <button class="btn-icon i-edit" title="Sửa thông tin"
                              onclick="openEditPanel(${m.medicineId})">✏️</button>
                      <form method="post" action="${pageContext.request.contextPath}/medicines" style="display:contents">
                        <input type="hidden" name="action" value="toggle-medicine"/>
                        <input type="hidden" name="id" value="${m.medicineId}"/>
                        <button type="submit" class="btn-icon ${m.status ? 'i-hide' : 'i-show'}"
                                title="${m.status ? 'Ẩn thuốc' : 'Hiện thuốc'}">${m.status ? '🙈' : '👁'}</button>
                      </form>
                      <c:if test="${stock == 0}">
                        <form method="post" action="${pageContext.request.contextPath}/medicines" style="display:contents"
                              onsubmit="return confirm('Xóa thuốc ${fn:escapeXml(m.medicineName)}?\nKhông thể hoàn tác!')">
                          <input type="hidden" name="action" value="delete-medicine"/>
                          <input type="hidden" name="id" value="${m.medicineId}"/>
                          <button type="submit" class="btn-icon i-del" title="Xóa (chỉ khi hết hàng)">🗑️</button>
                        </form>
                      </c:if>
                    </div>
                  </td>
                </tr>
              </c:forEach>
            </c:otherwise>
          </c:choose>
        </tbody>
      </table>
    </div><%-- /table-wrap --%>

    <%-- ── PAGINATION ── --%>
    <c:if test="${totalCount > 0}">
    <div class="pager">
      <span class="pager-info">
        Đang xem <strong>${pageFrom}–${pageTo}</strong> trên <strong>${totalCount}</strong> thuốc
      </span>
      <div class="pager-nav">
        <button class="pager-btn${currentPage == 1 ? ' disabled' : ''}"
                onclick="navigatePage(${currentPage - 1})"
                ${currentPage == 1 ? 'disabled' : ''}>‹ Trước</button>
        <c:forEach var="p" begin="1" end="${totalPages}">
          <c:choose>
            <c:when test="${p == currentPage}">
              <button class="pager-btn active" disabled>${p}</button>
            </c:when>
            <c:when test="${p == 1 || p == totalPages || (p >= currentPage-1 && p <= currentPage+1)}">
              <button class="pager-btn" onclick="navigatePage(${p})">${p}</button>
            </c:when>
            <c:when test="${p == currentPage-2 || p == currentPage+2}">
              <span class="pager-btn pager-ellipsis">…</span>
            </c:when>
          </c:choose>
        </c:forEach>
        <button class="pager-btn${currentPage == totalPages ? ' disabled' : ''}"
                onclick="navigatePage(${currentPage + 1})"
                ${currentPage == totalPages ? 'disabled' : ''}>Sau ›</button>
      </div>
      <select class="pager-size" onchange="changePageSize(this.value)" title="Số dòng mỗi trang">
        <option value="10"  ${pageSize == 10  ? 'selected' : ''}>10 / trang</option>
        <option value="20"  ${pageSize == 20  ? 'selected' : ''}>20 / trang</option>
        <option value="50"  ${pageSize == 50  ? 'selected' : ''}>50 / trang</option>
        <option value="100" ${pageSize == 100 ? 'selected' : ''}>100 / trang</option>
      </select>
    </div>
    </c:if>

    </div><%-- /data-container --%>
  </div><%-- /content --%>
</div><%-- /main --%>

<%-- ══ DRAWER OVERLAY ══ --%>
<div class="dw-overlay" id="dwOverlay" onclick="closeDrawer()"></div>

<%-- ══ DRAWER PANEL ══ --%>
<div class="drawer" id="drawer">
  <div class="dw-head">
    <div class="dw-head-icon" id="dwIcon">💊</div>
    <div>
      <div class="dw-title" id="dwTitle">Thêm thuốc mới</div>
      <div class="dw-sub" id="dwSub">Tạo hồ sơ thuốc mới</div>
    </div>
    <button class="dw-close" onclick="closeDrawer()">✕</button>
  </div>

  <div class="dw-body" id="dwBody">
    <div class="dw-loading" id="dwLoading" style="display:none">
      <div class="dw-spinner"></div>
      <span>Đang tải thông tin thuốc...</span>
    </div>

    <form id="dwForm" method="post" action="${pageContext.request.contextPath}/medicines" enctype="multipart/form-data">
      <input type="hidden" name="action" value="save-medicine">
      <input type="hidden" name="medicineId" id="dwMedId">
      <input type="hidden" name="existingImageUrl" id="dwExistingImg">

      <%-- Image upload --%>
      <div class="dw-section">
        <div class="dw-section-title">🖼️ Hình ảnh thuốc</div>
        <label class="img-upload-wrap" for="dwImageFile" onclick="void(0)">
          <div id="dwImgPreview" class="img-preview-ph">💊</div>
          <div class="img-upload-info">
            <div class="img-upload-label">Ảnh đóng gói / vỏ hộp</div>
            <div class="img-upload-hint">JPG, PNG, WebP — tối đa 3MB. Giúp dược sĩ nhận diện nhanh.</div>
            <input type="file" name="imageFile" id="dwImageFile" accept="image/*"
                   style="display:none" onchange="previewDwImage(this)">
            <div id="dwImgFilename" style="font-size:11.5px;color:var(--blue);margin-top:3px"></div>
          </div>
        </label>
      </div>

      <%-- Section 1: Thông tin cơ bản --%>
      <div class="dw-section">
        <div class="dw-section-title">💊 Thông tin cơ bản</div>
        <div class="dw-grid">
          <div class="dw-field span-2">
            <label class="dw-label">Tên thuốc <span class="req">*</span></label>
            <input type="text" name="medicineName" id="dwName" class="dw-input"
                   placeholder="VD: Paracetamol 500mg" required>
          </div>
          <div class="dw-field">
            <label class="dw-label">Tên hoạt chất (generic)</label>
            <input type="text" name="genericName" id="dwGeneric" class="dw-input"
                   placeholder="VD: Acetaminophen">
          </div>
          <div class="dw-field">
            <label class="dw-label">Đơn vị tính <span class="req">*</span></label>
            <input type="text" name="unit" id="dwUnit" class="dw-input"
                   placeholder="VD: Viên, Gói, Chai" required>
          </div>
          <div class="dw-field">
            <label class="dw-label">Quy cách đóng gói</label>
            <input type="text" name="packagingSpec" id="dwPackagingSpec" class="dw-input"
                   placeholder="VD: Hộp 3 vỉ × 10 viên">
          </div>
          <div class="dw-field">
            <label class="dw-label">Danh mục <span class="req">*</span>
              <button type="button" onclick="openCatModal()" class="add-btn-xs">➕ Thêm</button>
            </label>
            <select name="categoryId" id="dwCatId" class="dw-input" required>
              <option value="">-- Chọn danh mục --</option>
              <c:forEach var="cat" items="${categories}">
                <option value="${cat.categoryId}">${cat.categoryName}</option>
              </c:forEach>
            </select>
          </div>
          <div class="dw-field">
            <label class="dw-label">Nhà sản xuất <span class="req">*</span>
              <button type="button" onclick="openMfrModal()" class="add-btn-xs">➕ Thêm</button>
            </label>
            <select name="manufacturerId" id="dwMfrId" class="dw-input" required>
              <option value="">-- Chọn nhà SX --</option>
              <c:forEach var="mfr" items="${manufacturers}">
                <option value="${mfr.manufacturerId}">${mfr.name}</option>
              </c:forEach>
            </select>
          </div>
          <div class="dw-field">
            <label class="dw-label">Mã vạch</label>
            <input type="text" name="barcode" id="dwBarcode" class="dw-input"
                   placeholder="Quét hoặc nhập">
          </div>
          <div class="dw-field">
            <label class="dw-label">Số đăng ký lưu hành</label>
            <input type="text" name="registrationNumber" id="dwRegNo" class="dw-input"
                   placeholder="VD: VD-12345-16">
          </div>
        </div>
      </div>

      <%-- Section 2: Giá & Cấu hình kho --%>
      <div class="dw-section">
        <div class="dw-section-title">💰 Giá &amp; Cấu hình kho</div>
        <div class="dw-grid">
          <div class="dw-field">
            <label class="dw-label">Giá bán (₫) <span class="req">*</span></label>
            <div class="price-wrap">
              <input type="number" name="sellingPrice" id="dwPrice" class="dw-input"
                     placeholder="0" min="0" step="500" required>
              <span class="price-sfx">₫</span>
            </div>
          </div>
          <div class="dw-field">
            <label class="dw-label">Tồn kho tối thiểu (cảnh báo)</label>
            <input type="number" name="minInventory" id="dwMinInv" class="dw-input"
                   value="0" min="0">
          </div>
          <div class="dw-field">
            <label class="dw-label">Cảnh báo HH trước (ngày)</label>
            <input type="number" name="expiryAlertDays" id="dwExpDays" class="dw-input"
                   value="30" min="1">
          </div>
          <div class="dw-field">
            <label class="dw-label">Vị trí kệ</label>
            <select name="shelfId" id="dwShelfId" class="dw-input">
              <option value="">-- Chọn kệ (tùy chọn) --</option>
              <c:forEach var="sh" items="${shelves}">
                <option value="${sh.shelfId}"><c:out value="${empty sh.shelfName ? 'Kệ ' : sh.shelfName}"/><c:if test="${empty sh.shelfName}">${sh.shelfId}</c:if></option>
              </c:forEach>
            </select>
          </div>
        </div>
      </div>

      <%-- Section 3: Tồn kho ban đầu (Create only) --%>
      <div class="dw-section" id="initStockSection">
        <div class="dw-section-title">📦 Tồn kho ban đầu</div>
        <div class="dw-grid">
          <div class="init-stock-dw">
            <div class="init-stock-toggle-dw">
              <input type="checkbox" id="dwHasInitStock" onchange="toggleInitStockDw(this.checked)">
              <label for="dwHasInitStock">Thuốc đã có hàng sẵn trong kho — khai báo số lượng ban đầu để hệ thống tự tạo lô</label>
            </div>
            <div class="init-stock-fields-dw" id="initStockFieldsDw" style="display:none">
              <div class="dw-field">
                <label class="dw-label" style="color:#065F46">Số lượng <span class="req">*</span></label>
                <input type="number" name="initialQuantity" id="dwInitQty" class="dw-input"
                       placeholder="0" min="1">
              </div>
              <div class="dw-field">
                <label class="dw-label" style="color:#065F46">Ngày HH <span class="req">*</span></label>
                <input type="date" name="initialExpiryDate" id="dwInitExpiry" class="dw-input">
              </div>
              <div class="dw-field">
                <label class="dw-label" style="color:#065F46">Giá nhập (₫)</label>
                <div class="price-wrap">
                  <input type="number" name="initialImportPrice" class="dw-input"
                         placeholder="0" min="0" step="500">
                  <span class="price-sfx">₫</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <%-- Section 4: Thông tin y tế --%>
      <div class="dw-section">
        <div class="dw-section-title">🩺 Thông tin y tế</div>
        <div class="dw-grid">
          <div class="checkbox-row-dw">
            <input type="checkbox" id="dwRx" name="isPrescriptionRequired" value="on">
            <label for="dwRx">⚕️ Thuốc kê đơn (Rx) — cần đơn thuốc của bác sĩ khi bán</label>
          </div>
          <div class="dw-field span-2">
            <label class="dw-label">Liều dùng / Hướng dẫn sử dụng</label>
            <textarea name="dosage" id="dwDosage" class="dw-input"
                      placeholder="VD: Người lớn 1-2 viên/lần, 3-4 lần/ngày..."></textarea>
          </div>
          <div class="dw-field span-2">
            <label class="dw-label">Chống chỉ định</label>
            <textarea name="contraindications" id="dwContra" class="dw-input"
                      placeholder="Các trường hợp không nên dùng..."></textarea>
          </div>
          <div class="dw-field span-2">
            <label class="dw-label">Điều kiện bảo quản</label>
            <textarea name="storageConditions" id="dwStorage" class="dw-input"
                      placeholder="VD: Nơi khô ráo, thoáng mát, tránh ánh nắng..."></textarea>
          </div>
        </div>
      </div>

    </form>
  </div><%-- /dw-body --%>

  <div class="dw-foot">
    <button type="submit" form="dwForm" id="dwSaveBtn" class="btn-dw-save">➕ Tạo hồ sơ thuốc</button>
    <button type="button" class="btn-dw-cancel" onclick="closeDrawer()">Hủy</button>
    <span class="dw-foot-hint" id="dwFootHint"></span>
  </div>
</div>

<%-- ══ Modal tạo danh mục inline ══ --%>
<div id="catModal" style="display:none;position:fixed;inset:0;background:rgba(11,22,40,.55);z-index:600;align-items:center;justify-content:center;backdrop-filter:blur(2px)">
  <div style="background:#fff;border-radius:18px;width:400px;max-width:92vw;overflow:hidden;box-shadow:0 20px 60px rgba(0,0,0,.3)">
    <div style="padding:18px 22px;background:linear-gradient(90deg,#0F2645,#1558A8);color:#fff;display:flex;align-items:center;justify-content:space-between">
      <h3 style="font-size:15px;font-weight:700;margin:0">📂 Thêm danh mục thuốc</h3>
      <button onclick="closeCatModal()" style="background:rgba(255,255,255,.15);border:none;color:#fff;width:28px;height:28px;border-radius:8px;cursor:pointer;font-size:14px">✕</button>
    </div>
    <div style="padding:22px">
      <div style="margin-bottom:14px">
        <label style="font-size:12.5px;font-weight:700;color:#0F2645;display:block;margin-bottom:6px">Tên danh mục <span style="color:#DC2626">*</span></label>
        <input id="catNameInput" type="text" placeholder="VD: Kháng sinh, Giảm đau..."
               style="width:100%;height:42px;padding:0 14px;border:1.5px solid #D5E0F0;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;outline:none;box-sizing:border-box"
               onkeydown="if(event.key==='Enter'){event.preventDefault();saveCat()}">
      </div>
      <div style="margin-bottom:18px">
        <label style="font-size:12.5px;font-weight:700;color:#0F2645;display:block;margin-bottom:6px">Mô tả (không bắt buộc)</label>
        <input id="catDescInput" type="text" placeholder="Mô tả ngắn"
               style="width:100%;height:42px;padding:0 14px;border:1.5px solid #D5E0F0;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;outline:none;box-sizing:border-box">
      </div>
      <div id="catErr" style="font-size:12px;color:#DC2626;margin-bottom:10px;display:none"></div>
      <div style="display:flex;gap:10px">
        <button onclick="saveCat()" style="flex:1;height:40px;background:linear-gradient(135deg,#1558A8,#0D3F85);color:#fff;border:none;border-radius:11px;font-family:'Outfit',sans-serif;font-size:14px;font-weight:700;cursor:pointer">➕ Tạo danh mục</button>
        <button onclick="closeCatModal()" style="height:40px;padding:0 18px;background:#fff;border:1.5px solid #D5E0F0;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;color:#7A90B0;cursor:pointer">Hủy</button>
      </div>
    </div>
  </div>
</div>

<%-- ══ Modal tạo nhà sản xuất inline ══ --%>
<div id="mfrModal" style="display:none;position:fixed;inset:0;background:rgba(11,22,40,.55);z-index:600;align-items:center;justify-content:center;backdrop-filter:blur(2px)">
  <div style="background:#fff;border-radius:18px;width:420px;max-width:92vw;overflow:hidden;box-shadow:0 20px 60px rgba(0,0,0,.3)">
    <div style="padding:18px 22px;background:linear-gradient(90deg,#0F2645,#1558A8);color:#fff;display:flex;align-items:center;justify-content:space-between">
      <h3 style="font-size:15px;font-weight:700;margin:0">🏭 Thêm nhà sản xuất</h3>
      <button onclick="closeMfrModal()" style="background:rgba(255,255,255,.15);border:none;color:#fff;width:28px;height:28px;border-radius:8px;cursor:pointer;font-size:14px">✕</button>
    </div>
    <div style="padding:22px">
      <div style="margin-bottom:14px">
        <label style="font-size:12.5px;font-weight:700;color:#0F2645;display:block;margin-bottom:6px">Tên nhà sản xuất <span style="color:#DC2626">*</span></label>
        <input id="mfrNameInput" type="text" placeholder="VD: Sanofi, Pfizer, Imexpharm..."
               style="width:100%;height:42px;padding:0 14px;border:1.5px solid #D5E0F0;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;outline:none;box-sizing:border-box">
      </div>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:18px">
        <div>
          <label style="font-size:12.5px;font-weight:700;color:#0F2645;display:block;margin-bottom:6px">Quốc gia</label>
          <input id="mfrCountryInput" type="text" placeholder="VD: Pháp, Việt Nam"
                 style="width:100%;height:42px;padding:0 14px;border:1.5px solid #D5E0F0;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;outline:none;box-sizing:border-box">
        </div>
        <div>
          <label style="font-size:12.5px;font-weight:700;color:#0F2645;display:block;margin-bottom:6px">Liên hệ</label>
          <input id="mfrContactInput" type="text" placeholder="Website hoặc SĐT"
                 style="width:100%;height:42px;padding:0 14px;border:1.5px solid #D5E0F0;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;outline:none;box-sizing:border-box">
        </div>
      </div>
      <div id="mfrErr" style="font-size:12px;color:#DC2626;margin-bottom:10px;display:none"></div>
      <div style="display:flex;gap:10px">
        <button onclick="saveMfr()" style="flex:1;height:40px;background:linear-gradient(135deg,#1558A8,#0D3F85);color:#fff;border:none;border-radius:11px;font-family:'Outfit',sans-serif;font-size:14px;font-weight:700;cursor:pointer">➕ Tạo nhà sản xuất</button>
        <button onclick="closeMfrModal()" style="height:40px;padding:0 18px;background:#fff;border:1.5px solid #D5E0F0;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;color:#7A90B0;cursor:pointer">Hủy</button>
      </div>
      <%-- Danh sách NSX hiện tại kèm nút xóa --%>
      <div class="mfr-manage-section">
        <div class="mfr-manage-title">Danh sách nhà sản xuất hiện tại</div>
        <div class="mfr-list-wrap" id="mfrManageList">
          <c:forEach var="mfr" items="${manufacturers}">
            <div class="mfr-row" id="mfr-row-${mfr.manufacturerId}">
              <span class="mfr-row-name">${fn:escapeXml(mfr.name)}</span>
              <button type="button" class="mfr-del-btn"
                      onclick="deleteMfr(${mfr.manufacturerId},'${fn:escapeXml(mfr.name)}')"
                      title="Xóa nhà sản xuất này">🗑️</button>
            </div>
          </c:forEach>
          <c:if test="${empty manufacturers}">
            <div style="text-align:center;color:var(--muted);font-size:13px;padding:10px 0">Chưa có nhà sản xuất nào.</div>
          </c:if>
        </div>
      </div>
    </div>
  </div>
</div>

<%-- ──── PURCHASE ORDER MODAL ──── --%>
<div id="poModal" style="display:none;position:fixed;inset:0;background:rgba(11,22,40,.55);z-index:600;align-items:center;justify-content:center;backdrop-filter:blur(3px)">
  <div style="background:#fff;border-radius:18px;width:480px;max-width:94vw;overflow:hidden;box-shadow:0 20px 60px rgba(0,0,0,.3)">
    <div style="padding:18px 24px;background:linear-gradient(90deg,#0F2645,#1558A8);color:#fff;display:flex;align-items:center;justify-content:space-between">
      <div>
        <div style="font-size:15.5px;font-weight:800">📦 Tạo phiếu nhập kho</div>
        <div style="font-size:12px;opacity:.75;margin-top:2px">Chọn nhà cung cấp để tạo đơn đặt hàng mới</div>
      </div>
      <button onclick="closePoModal()" style="background:rgba(255,255,255,.15);border:none;color:#fff;width:30px;height:30px;border-radius:9px;cursor:pointer;font-size:15px;display:flex;align-items:center;justify-content:center">✕</button>
    </div>
    <div class="po-modal-body">
      <div class="po-field">
        <label class="po-label">Nhà cung cấp <span style="color:#DC2626">*</span></label>
        <select id="poSupplier" class="po-select">
          <option value="">-- Chọn nhà cung cấp --</option>
          <c:forEach var="sup" items="${suppliers}">
            <option value="${sup.supplierId}">${fn:escapeXml(sup.supplierName)}</option>
          </c:forEach>
        </select>
        <div style="font-size:11.5px;color:var(--muted);margin-top:5px">Không thấy nhà cung cấp? <a href="${pageContext.request.contextPath}/suppliers" target="_blank" style="color:var(--blue)">Vào mục Nhà cung cấp để thêm trước.</a></div>
      </div>
      <div class="po-field">
        <label class="po-label">Ghi chú</label>
        <textarea id="poNotes" class="po-textarea" placeholder="VD: Đặt hàng định kỳ tháng 7, giao trong 3 ngày..."></textarea>
      </div>
      <div id="poErr" style="font-size:12.5px;color:#DC2626;background:#FEF2F2;border:1px solid #FCA5A5;border-radius:9px;padding:8px 12px;display:none;margin-bottom:12px"></div>
      <div class="po-actions">
        <button id="poBtnSave" class="po-btn-save" onclick="savePoAjax()">📦 Tạo đơn đặt hàng</button>
        <button class="po-btn-cancel" onclick="closePoModal()">Hủy</button>
      </div>
      <div style="margin-top:14px;padding:12px;background:#F0F7FF;border-radius:10px;font-size:12px;color:var(--blue);line-height:1.6">
        💡 Sau khi tạo đơn, vào <strong>Chi tiết đơn</strong> để gắn lô hàng vào đơn này, hoặc vào <strong>Kho thuốc → Lô hàng</strong> để thêm lô mới và chọn đơn tương ứng.
      </div>
    </div>
  </div>
</div>

<script>
const CTX = '${pageContext.request.contextPath}';

// ── TOAST ─────────────────────────────────────────────────────────────────────
const pageToast = document.getElementById('pageToast');
if (pageToast) setTimeout(() => {
  pageToast.style.transition = 'opacity .4s';
  pageToast.style.opacity = '0';
  setTimeout(() => pageToast.remove(), 400);
}, 3500);

function showToast(type, msg) {
  const el = document.createElement('div');
  el.className = 'toast toast-' + type;
  el.textContent = msg;
  document.body.appendChild(el);
  setTimeout(() => { el.style.transition='opacity .4s'; el.style.opacity='0'; setTimeout(()=>el.remove(),400); }, 3500);
}

// ── EXPAND BATCH ROWS ─────────────────────────────────────────────────────────
const _TODAY = new Date().toISOString().split('T')[0];
const _D90   = new Date(Date.now() + 90*24*60*60*1000).toISOString().split('T')[0];

function _expCls(d) {
  if (!d) return '';
  return d < _TODAY ? 'exp-red' : d <= _D90 ? 'exp-gold' : 'exp-ok';
}
function _fmtDate(d) {
  if (!d) return '—';
  const p = d.split('-'); return p.length === 3 ? p[2]+'/'+p[1]+'/'+p[0] : d;
}
function _fmtMoney(n) {
  const v = Math.round(parseFloat(n)||0);
  return v.toLocaleString('vi')+'₫';
}

async function toggleExpand(btn, medicineId) {
  const tr = btn.closest('tr');
  const existRow = document.getElementById('br-' + medicineId);

  if (existRow) {
    const showing = existRow.style.display !== 'none';
    existRow.style.display = showing ? 'none' : '';
    btn.classList.toggle('open', !showing);
    return;
  }

  btn.disabled = true;
  btn.textContent = '⏳';

  try {
    const res  = await fetch(CTX + '/medicines?action=api-batches&medicineId=' + medicineId);
    const list = await res.json();

    const bRow = document.createElement('tr');
    bRow.id        = 'br-' + medicineId;
    bRow.className = 'batch-expand-row';

    let inner = '<div class="batch-sub-wrap">';
    inner += '<div class="batch-sub-header">📦 Lô hàng (' + list.length + ')</div>';

    if (list.length === 0) {
      inner += '<div class="batch-sub-empty">Chưa có lô hàng nào. <a href="' + CTX + '/purchase-orders?action=new" style="color:var(--blue)">Tạo phiếu nhập kho</a> để thêm lô đầu tiên.</div>';
    } else {
      inner += '<table class="batch-mini-table"><thead><tr>'
             + '<th>Số lô</th><th>Ngày nhập</th><th>Ngày SX</th>'
             + '<th>Hạn dùng</th><th>Còn tồn</th><th>Đã xuất</th>'
             + '<th>Giá nhập</th><th>Trạng thái</th><th></th>'
             + '</tr></thead><tbody>';

      for (const b of list) {
        const sold    = (b.initialQty||0) - (b.currentQty||0);
        const stCls   = b.status === 'ACTIVE'    ? 'bst-active'
                      : b.status === 'DESTROYED' ? 'bst-destroyed' : 'bst-cancelled';
        const stLabel = b.status === 'ACTIVE'    ? 'Đang dùng'
                      : b.status === 'DESTROYED' ? 'Tiêu hủy' : 'Đã hủy';
        inner += '<tr>'
               + '<td><span class="bno">' + (b.batchNumber||'—') + '</span></td>'
               + '<td>' + _fmtDate(b.importDate) + '</td>'
               + '<td>' + _fmtDate(b.manufactureDate) + '</td>'
               + '<td class="' + _expCls(b.expiryDate) + '">' + _fmtDate(b.expiryDate) + '</td>'
               + '<td><strong>' + (b.currentQty||0) + '</strong></td>'
               + '<td style="color:var(--muted)">' + sold + '</td>'
               + '<td>' + _fmtMoney(b.importPrice) + '</td>'
               + '<td><span class="badge ' + stCls + '" style="padding:3px 8px;border-radius:20px;font-size:11px;font-weight:700">' + stLabel + '</span></td>'
               + '<td><a href="' + CTX + '/medicines?action=detail&id=' + medicineId + '" class="btn-sm btn-detail" style="font-size:11px;padding:3px 10px">Chi tiết</a></td>'
               + '</tr>';
      }
      inner += '</tbody></table>';
    }
    inner += '</div>';

    bRow.innerHTML = '<td colspan="9">' + inner + '</td>';
    tr.insertAdjacentElement('afterend', bRow);
    btn.classList.add('open');
  } catch(e) {
    console.error(e);
    showToast('err', '❌ Không tải được lô hàng');
  } finally {
    btn.disabled = false;
    btn.textContent = '›';
  }
}

// ── DRAWER ────────────────────────────────────────────────────────────────────
let _drawerMode = 'add'; // 'add' | 'edit'

function openAddPanel() {
  _drawerMode = 'add';
  resetDwForm();
  document.getElementById('dwIcon').textContent = '➕';
  document.getElementById('dwTitle').textContent = 'Thêm thuốc mới';
  document.getElementById('dwSub').textContent = 'Tạo hồ sơ thuốc — tồn kho bắt đầu từ 0';
  document.getElementById('dwSaveBtn').textContent = '➕ Tạo hồ sơ thuốc';
  document.getElementById('dwFootHint').textContent = '';
  document.getElementById('initStockSection').style.display = '';
  openDrawer();
  setTimeout(() => document.getElementById('dwName').focus(), 260);
}

async function openEditPanel(medicineId) {
  _drawerMode = 'edit';
  document.getElementById('dwIcon').textContent = '✏️';
  document.getElementById('dwTitle').textContent = 'Đang tải...';
  document.getElementById('dwSub').textContent = 'Chỉnh sửa thông tin hồ sơ thuốc';
  document.getElementById('dwSaveBtn').textContent = '💾 Lưu thay đổi';
  document.getElementById('dwFootHint').textContent = 'ID: ' + medicineId;
  document.getElementById('initStockSection').style.display = 'none';
  openDrawer();

  const loading = document.getElementById('dwLoading');
  loading.style.display = 'flex';
  document.getElementById('dwForm').style.visibility = 'hidden';

  try {
    const res = await fetch(CTX + '/medicines?action=api-med&id=' + medicineId);
    const data = await res.json();
    if (data.error) { showToast('err', '❌ Lỗi tải thông tin: ' + data.error); closeDrawer(); return; }
    document.getElementById('dwTitle').textContent = '✏️ Sửa — ' + data.medicineName;
    populateDwForm(data);
  } catch(e) {
    showToast('err', '❌ Không tải được dữ liệu thuốc.');
    closeDrawer();
    return;
  } finally {
    loading.style.display = 'none';
    document.getElementById('dwForm').style.visibility = '';
  }
}

function populateDwForm(d) {
  document.getElementById('dwMedId').value          = d.id;
  document.getElementById('dwName').value           = d.medicineName  || '';
  document.getElementById('dwGeneric').value        = d.genericName   || '';
  document.getElementById('dwUnit').value           = d.unit          || '';
  document.getElementById('dwPackagingSpec').value  = d.packagingSpec || '';
  document.getElementById('dwBarcode').value        = d.barcode       || '';
  document.getElementById('dwRegNo').value          = d.registrationNumber || '';
  document.getElementById('dwPrice').value          = d.sellingPrice  || '';
  document.getElementById('dwMinInv').value         = d.minInventory  || 0;
  document.getElementById('dwExpDays').value        = d.expiryAlertDays || 30;
  document.getElementById('dwDosage').value         = d.dosage        || '';
  document.getElementById('dwContra').value         = d.contraindications || '';
  document.getElementById('dwStorage').value        = d.storageConditions || '';
  document.getElementById('dwRx').checked           = d.isPrescriptionRequired === true;
  document.getElementById('dwExistingImg').value    = d.imageUrl || '';
  setSelect('dwCatId',   d.categoryId);
  setSelect('dwMfrId',   d.manufacturerId);
  setSelect('dwShelfId', d.shelfId);
  // Show image preview
  const preview = document.getElementById('dwImgPreview');
  if (d.imageUrl) {
    preview.outerHTML = '<img id="dwImgPreview" class="img-preview" src="' + CTX + '/' + d.imageUrl + '" alt="ảnh thuốc">';
  } else {
    if (preview.tagName === 'IMG') preview.outerHTML = '<div id="dwImgPreview" class="img-preview-ph">💊</div>';
  }
  document.getElementById('dwImgFilename').textContent = '';
}

function setSelect(id, val) {
  const sel = document.getElementById(id);
  if (!sel || !val) return;
  for (let opt of sel.options) {
    if (opt.value == val) { opt.selected = true; break; }
  }
}

function resetDwForm() {
  document.getElementById('dwForm').reset();
  document.getElementById('dwMedId').value = '';
  document.getElementById('dwExistingImg').value = '';
  document.getElementById('initStockFieldsDw').style.display = 'none';
  document.getElementById('dwHasInitStock').checked = false;
  // Reset image preview
  const preview = document.getElementById('dwImgPreview');
  if (preview && preview.tagName === 'IMG')
    preview.outerHTML = '<div id="dwImgPreview" class="img-preview-ph">💊</div>';
  document.getElementById('dwImgFilename').textContent = '';
}

function previewDwImage(input) {
  if (!input.files || !input.files[0]) return;
  const file = input.files[0];
  if (!file.type.startsWith('image/')) { showToast('err', '❌ Chỉ chấp nhận file ảnh (JPG, PNG, WebP)'); input.value=''; return; }
  if (file.size > 3 * 1024 * 1024) { showToast('err', '❌ Ảnh quá lớn — tối đa 3MB'); input.value=''; return; }
  const reader = new FileReader();
  reader.onload = e => {
    const prev = document.getElementById('dwImgPreview');
    if (prev.tagName === 'IMG') { prev.src = e.target.result; }
    else { prev.outerHTML = '<img id="dwImgPreview" class="img-preview" src="' + e.target.result + '" alt="preview">'; }
    document.getElementById('dwImgFilename').textContent = '✅ ' + file.name;
  };
  reader.readAsDataURL(file);
}

function openDrawer() {
  document.getElementById('drawer').classList.add('open');
  document.getElementById('dwOverlay').classList.add('open');
  document.body.style.overflow = 'hidden';
}

function closeDrawer() {
  document.getElementById('drawer').classList.remove('open');
  document.getElementById('dwOverlay').classList.remove('open');
  document.body.style.overflow = '';
}

document.addEventListener('keydown', e => { if (e.key === 'Escape') closeDrawer(); });

// Submit guard — disable button to prevent double-submit
document.getElementById('dwForm').addEventListener('submit', function() {
  const btn = document.getElementById('dwSaveBtn');
  btn.disabled = true;
  btn.textContent = '⏳ Đang lưu...';
});

// ── INITIAL STOCK TOGGLE ──────────────────────────────────────────────────────
function toggleInitStockDw(checked) {
  const fields = document.getElementById('initStockFieldsDw');
  const qtyIn  = document.getElementById('dwInitQty');
  const expIn  = document.getElementById('dwInitExpiry');
  fields.style.display = checked ? 'grid' : 'none';
  if (qtyIn) qtyIn.required = checked;
  if (expIn) expIn.required = checked;
  if (checked && qtyIn) qtyIn.focus();
}

// ── STAT CARD SWITCHING ───────────────────────────────────────────────────────
let activeTabType = 'all';
const _cardIds = { all:'scAll', low:'scLow', expiring:'scExpiring', expired:'scExpired' };
function switchCard(type) {
  activeTabType = type;
  document.querySelectorAll('.stat-card').forEach(c => c.classList.remove('sc-active'));
  const el = document.getElementById(_cardIds[type]);
  if (el) el.classList.add('sc-active');
  filterRows();
}

// ── PAGINATION ────────────────────────────────────────────────────────────────
function navigatePage(page) {
  const u = new URL(window.location.href);
  u.searchParams.set('page', page);
  window.location.href = u.toString();
}
function changePageSize(size) {
  const u = new URL(window.location.href);
  u.searchParams.set('pageSize', size);
  u.searchParams.set('page', '1');
  window.location.href = u.toString();
}

function filterRows() {
  const catFilter    = document.getElementById('catFilter').value;
  const statusFilter = document.getElementById('statusFilter').value;
  let count = 0;
  const allRows = document.querySelectorAll('.med-row');
  allRows.forEach(row => {
    const stock     = parseInt(row.dataset.stock)        || 0;
    const minInv    = parseInt(row.dataset.minInv)       || 0;
    const isActive  = row.dataset.status === 'active';
    const soonCount = parseInt(row.dataset.expiringSoon) || 0;
    const expCount  = parseInt(row.dataset.expired)      || 0;
    const rowCatId  = row.dataset.cat;
    let matchTab = true;
    if      (activeTabType === 'low')      matchTab = minInv > 0 && stock > 0 && stock <= minInv;
    else if (activeTabType === 'out')      matchTab = stock === 0;
    else if (activeTabType === 'expiring') matchTab = soonCount > 0;
    else if (activeTabType === 'expired')  matchTab = expCount  > 0;
    const matchCat    = !catFilter    || rowCatId === catFilter;
    let matchStatus   = true;
    if      (statusFilter === 'active')   matchStatus = isActive;
    else if (statusFilter === 'inactive') matchStatus = !isActive;
    else if (statusFilter === 'low')      matchStatus = minInv > 0 && stock > 0 && stock <= minInv;
    else if (statusFilter === 'out')      matchStatus = stock === 0;
    const show = (matchTab && matchCat && matchStatus);
    row.style.display = show ? '' : 'none';
    if (show) count++;
  });
  
  // Only manage the JS empty-state when there are actual med-rows to filter
  if (allRows.length === 0) return;
  let noRes = document.getElementById('noResultsRow');
  if (!noRes) {
    const tbody = document.getElementById('medTable');
    if (tbody) {
      const tr = document.createElement('tr');
      tr.id = 'noResultsRow';
      tr.className = 'empty-row';
      tr.innerHTML = '<td colspan="9" style="text-align:center;padding:36px;color:var(--muted);font-size:14px">🔍 Không tìm thấy thuốc nào khớp với bộ lọc.<br><span style="font-size:12px;margin-top:6px;display:inline-block">Thử thay đổi bộ lọc hoặc <a href="javascript:void(0)" onclick="resetFilters()" style="color:var(--blue)">đặt lại tất cả</a>.</span></td>';
      tbody.appendChild(tr);
      noRes = tr;
    }
  }
  if (noRes) noRes.style.display = count === 0 ? '' : 'none';
}

function resetFilters() {
  document.getElementById('statusFilter').value = '';
  activeTabType = 'all';
  document.querySelectorAll('.cat-tab').forEach(b => b.classList.remove('active'));
  const firstTab = document.querySelector('.cat-tab');
  if (firstTab) firstTab.classList.add('active');
  filterRows();
}

// ── CUSTOM DROPDOWN ───────────────────────────────────────────────────────────
function toggleCs() { document.getElementById('csCatWrap').classList.toggle('open'); }
function selectCs(opt, val) {
  document.getElementById('catFilter').value = val;
  document.getElementById('csLabel').textContent = opt.textContent.trim();
  document.querySelectorAll('#csPanel .cs-opt').forEach(o => o.classList.remove('cs-sel'));
  opt.classList.add('cs-sel');
  document.getElementById('csCatWrap').classList.remove('open');
  filterRows();
}
document.addEventListener('click', e => {
  const wrap = document.getElementById('csCatWrap');
  if (wrap && !wrap.contains(e.target)) wrap.classList.remove('open');
});
(function initCsLabel() {
  const sel = document.querySelector('#csPanel .cs-opt.cs-sel');
  if (sel) document.getElementById('csLabel').textContent = sel.textContent.trim();
})();

// ── HOVER CARD ────────────────────────────────────────────────────────────────
const hoverCard = document.getElementById('hoverCard');
let hoverTimeout;
function showHoverCard(row, e) {
  clearTimeout(hoverTimeout);
  const stock   = parseInt(row.dataset.stock)         || 0;
  const unit    = row.dataset.unit                    || '';
  const batches = parseInt(row.dataset.activeBatches) || 0;
  const soon    = parseInt(row.dataset.expiringSoon)  || 0;
  const expired = parseInt(row.dataset.expired)       || 0;
  const expiry  = row.dataset.nearestExpiry           || '';
  const name    = row.dataset.medName                 || '';
  const shelf   = row.dataset.shelf                   || '';
  document.getElementById('hc-name').textContent    = name;
  document.getElementById('hc-stock').textContent   = stock + ' ' + unit;
  document.getElementById('hc-batches').textContent = batches + ' lô';
  document.getElementById('hc-expiry').textContent  = expiry  || '—';
  document.getElementById('hc-soon').textContent    = soon    ? soon + ' lô' : '—';
  document.getElementById('hc-expired').textContent = expired ? expired + ' lô' : '—';
  document.getElementById('hc-stock').className   = 'hc-val ' + (stock===0?'err':stock<=parseInt(row.dataset.minInv||0)?'warn':'ok');
  document.getElementById('hc-soon').className    = 'hc-val ' + (soon   >0?'warn':'');
  document.getElementById('hc-expired').className = 'hc-val ' + (expired>0?'err' :'');
  const shelfRow = document.getElementById('hc-shelf-row');
  if (shelf) { document.getElementById('hc-shelf').textContent = shelf; shelfRow.style.display = ''; }
  else { shelfRow.style.display = 'none'; }
  positionCard(e);
  hoverCard.classList.add('show');
}
function hideHoverCard() {
  hoverTimeout = setTimeout(() => hoverCard.classList.remove('show'), 80);
}
function moveHoverCard(e) { if (hoverCard.classList.contains('show')) positionCard(e); }
function positionCard(e) {
  const cw=hoverCard.offsetWidth||250, ch=hoverCard.offsetHeight||160;
  let x=e.clientX+18, y=e.clientY-10;
  if(x+cw>window.innerWidth-10)  x=e.clientX-cw-14;
  if(y+ch>window.innerHeight-10) y=window.innerHeight-ch-10;
  hoverCard.style.left=x+'px'; hoverCard.style.top=y+'px';
}

// ── CATEGORY MODAL ────────────────────────────────────────────────────────────
function openCatModal() {
  document.getElementById('catNameInput').value='';
  document.getElementById('catDescInput').value='';
  document.getElementById('catErr').style.display='none';
  document.getElementById('catModal').style.display='flex';
  setTimeout(()=>document.getElementById('catNameInput').focus(),100);
}
function closeCatModal() { document.getElementById('catModal').style.display='none'; }
document.getElementById('catModal').addEventListener('click', function(e){ if(e.target===this)closeCatModal(); });
function saveCat() {
  const name=document.getElementById('catNameInput').value.trim();
  const desc=document.getElementById('catDescInput').value.trim();
  const err=document.getElementById('catErr');
  if(!name){err.textContent='⚠️ Vui lòng nhập tên danh mục!';err.style.display='block';return;}
  const fd=new FormData(); fd.append('action','create-category-ajax'); fd.append('categoryName',name); fd.append('description',desc);
  fetch(CTX+'/medicines',{method:'POST',body:fd}).then(r=>r.json()).then(data=>{
    if(data.ok){
      const sel=document.getElementById('dwCatId');
      sel.appendChild(new Option(data.name,data.id,true,true));
      closeCatModal(); sel.style.borderColor='#059669'; setTimeout(()=>sel.style.borderColor='',1500);
    }else{err.textContent=data.error||'❌ Lỗi!';err.style.display='block';}
  }).catch(()=>{err.textContent='❌ Lỗi kết nối!';err.style.display='block';});
}

// ── MANUFACTURER MODAL ────────────────────────────────────────────────────────
function openMfrModal() {
  ['mfrNameInput','mfrCountryInput','mfrContactInput'].forEach(id=>document.getElementById(id).value='');
  document.getElementById('mfrErr').style.display='none';
  document.getElementById('mfrModal').style.display='flex';
  setTimeout(()=>document.getElementById('mfrNameInput').focus(),100);
}
function closeMfrModal() { document.getElementById('mfrModal').style.display='none'; }
document.getElementById('mfrModal').addEventListener('click', function(e){ if(e.target===this)closeMfrModal(); });
function saveMfr() {
  const name=document.getElementById('mfrNameInput').value.trim();
  const country=document.getElementById('mfrCountryInput').value.trim();
  const contact=document.getElementById('mfrContactInput').value.trim();
  const err=document.getElementById('mfrErr');
  if(!name){err.textContent='⚠️ Vui lòng nhập tên nhà sản xuất!';err.style.display='block';return;}
  const fd=new FormData(); fd.append('action','create-manufacturer-ajax'); fd.append('name',name); fd.append('country',country); fd.append('contactInfo',contact);
  fetch(CTX+'/medicines',{method:'POST',body:fd}).then(r=>r.json()).then(data=>{
    if(data.ok){
      const sel=document.getElementById('dwMfrId');
      sel.appendChild(new Option(data.name,data.id,true,true));
      // Add to manage list too
      const list=document.getElementById('mfrManageList');
      if(list){
        const row=document.createElement('div'); row.className='mfr-row'; row.id='mfr-row-'+data.id;
        row.innerHTML='<span class="mfr-row-name">'+data.name+'</span><button type="button" class="mfr-del-btn" onclick="deleteMfr('+data.id+',\''+data.name.replace(/'/g,"\\'")+'\')" title="Xóa">🗑️</button>';
        list.appendChild(row);
      }
      closeMfrModal(); sel.style.borderColor='#059669'; setTimeout(()=>sel.style.borderColor='',1500);
    }else{err.textContent=data.error||'❌ Lỗi!';err.style.display='block';}
  }).catch(()=>{err.textContent='❌ Lỗi kết nối!';err.style.display='block';});
}

function deleteMfr(id, name) {
  if(!confirm('Xóa nhà sản xuất "'+name+'"?\n(Không thể xóa nếu còn thuốc đang dùng)')) return;
  const fd=new FormData(); fd.append('action','delete-manufacturer-ajax'); fd.append('id',id);
  fetch(CTX+'/medicines',{method:'POST',body:fd}).then(r=>r.json()).then(data=>{
    if(data.ok){
      const row=document.getElementById('mfr-row-'+id); if(row) row.remove();
      const sel=document.getElementById('dwMfrId');
      const opt=[...sel.options].find(o=>o.value==id); if(opt) opt.remove();
      showToast('ok','✅ Đã xóa nhà sản xuất!');
    } else {
      alert(data.error||'Không thể xóa!');
    }
  }).catch(()=>alert('❌ Lỗi kết nối!'));
}

// ── PURCHASE ORDER MODAL ───────────────────────────────────────────────────────
function openPoModal() { document.getElementById('poModal').style.display='flex'; }
function closePoModal() { document.getElementById('poModal').style.display='none'; }
document.getElementById('poModal').addEventListener('click',function(e){if(e.target===this)closePoModal();});

function savePoAjax() {
  const sup=document.getElementById('poSupplier').value;
  const notes=document.getElementById('poNotes').value;
  const err=document.getElementById('poErr');
  if(!sup){err.textContent='⚠️ Vui lòng chọn nhà cung cấp!';err.style.display='block';return;}
  err.style.display='none';
  const btn=document.getElementById('poBtnSave');
  btn.disabled=true; btn.textContent='⏳ Đang tạo...';
  const fd=new FormData(); fd.append('action','create-po-ajax'); fd.append('supplierId',sup); fd.append('notes',notes);
  fetch(CTX+'/medicines',{method:'POST',body:fd}).then(r=>r.json()).then(data=>{
    if(data.ok){
      closePoModal();
      showToast('ok','✅ Đã tạo đơn đặt hàng #'+data.poId+'!');
      document.getElementById('poSupplier').value='';
      document.getElementById('poNotes').value='';
      setTimeout(()=>window.location.href=CTX+'/purchase-orders?action=detail&id='+data.poId+'&msg=created', 1500);
    } else {
      err.textContent=data.error||'❌ Lỗi!'; err.style.display='block';
    }
  }).catch(()=>{err.textContent='❌ Lỗi kết nối!';err.style.display='block';})
  .finally(()=>{btn.disabled=false;btn.textContent='📦 Tạo đơn đặt hàng';});
}

// ── TOPBAR CLOCK ─────────────────────────────────────────────────────────────
(function tickClock() {
  const now  = new Date();
  const hh   = String(now.getHours()).padStart(2,'0');
  const mm   = String(now.getMinutes()).padStart(2,'0');
  const days = ['CN','T2','T3','T4','T5','T6','T7'];
  const day  = days[now.getDay()];
  const date = day + ' ' + now.getDate() + '/' + (now.getMonth()+1) + '/' + now.getFullYear();
  const h = document.getElementById('tbH');
  const m = document.getElementById('tbM');
  const d = document.getElementById('tbDate');
  if (h) h.textContent = hh;
  if (m) m.textContent = mm;
  if (d) d.textContent = date;
  setTimeout(tickClock, 1000);
})();

// ── INIT ───────────────────────────────────────────────────────────────────────
filterRows();
</script>
</body>
</html>
