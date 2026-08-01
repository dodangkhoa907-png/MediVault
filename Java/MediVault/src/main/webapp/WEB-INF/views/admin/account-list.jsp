<%@ page contentType="text/html;charset=UTF-8"  pageEncoding="UTF-8" %>
<% String activeNav = "accounts"; %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    if (acc.getRoleId() != 1) { response.sendRedirect(request.getContextPath() + "/dashboard"); return; }
    java.lang.String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    java.lang.String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
    java.lang.String msg = request.getParameter("msg");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
    
    
    
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Quản lý tài khoản — medicare</title>


<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;--cyan-soft:#EBF8FD;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;--sidebar:232px;
}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar::after{content:'';position:absolute;top:0;right:0;bottom:0;width:1px;background:linear-gradient(180deg,transparent,rgba(58,189,224,.12) 30%,rgba(58,189,224,.12) 70%,transparent)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-icon{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;box-shadow:0 4px 16px rgba(58,189,224,.35)}
.logo-text{font-family:'Lora',serif;font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-text span{color:var(--cyan)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:12px 0 4px;flex-shrink:0}
.nav-label{font-size:9px;font-weight:750;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:750;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.14);font-weight:750}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--cyan);border-radius:2px}
.nav-icon{width:18px;text-align:center;font-size:14px;flex-shrink:0;opacity:.8}
.nav-item.active .nav-icon{opacity:1}
.nav-badge{margin-left:auto;background:#DC2626;color:#fff;font-size:10px;font-weight:750;padding:1px 7px;border-radius:20px;min-width:20px;text-align:center}
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06);flex-shrink:0}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08)}
.user-av{width:34px;height:34px;flex-shrink:0;border-radius:9px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.user-name{font-size:12.5px;font-weight:750;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:110px}
.user-role{font-size:10px;color:rgba(255,255,255,.35);margin-top:1px}
.logout-btn{margin-left:auto;width:28px;height:28px;flex-shrink:0;border-radius:8px;background:rgba(220,38,38,.12);border:none;display:flex;align-items:center;justify-content:center;color:rgba(220,38,38,.7);font-size:13px;cursor:pointer;text-decoration:none;transition:all .18s}
.logout-btn:hover{background:rgba(220,38,38,.2);color:#DC2626}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0;overflow-x:hidden}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Plus Jakarta Sans',sans-serif;font-size:16px;font-weight:750;color:var(--ink)}

    
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px;flex-shrink:0}
.topbar-user{display:flex;align-items:center;gap:8px;padding:5px 12px 5px 7px;border:1.5px solid var(--border);border-radius:20px;text-decoration:none;color:inherit;transition:all .18s}
.topbar-user:hover{border-color:var(--cyan);background:var(--cyan-soft)}
.topbar-av{width:28px;height:28px;border-radius:8px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;color:#fff}
.topbar-name{font-size:13px;font-weight:750;color:var(--navy);max-width:110px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.content{padding:26px 28px;flex:1;min-width:0;overflow-x:auto}
.page-head{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:22px}
.breadcrumb{font-size:11.5px;color:var(--muted);font-weight:750;margin-bottom:4px}
.page-head h1{font-family:'Plus Jakarta Sans',sans-serif;font-size:26px;color:var(--ink)}
.section-tabs{display:flex;gap:6px;background:var(--white);border:1px solid var(--border);border-radius:12px;padding:4px;width:fit-content;margin-bottom:18px}
.section-tab{padding:8px 18px;border-radius:9px;font-size:13px;font-weight:750;color:var(--muted);text-decoration:none;transition:all .15s;display:inline-flex;align-items:center;gap:6px}
.section-tab:hover{background:var(--surface);color:var(--ink)}
.section-tab.active{background:linear-gradient(135deg,var(--blue),var(--cyan));color:#fff;box-shadow:0 3px 10px rgba(21,88,168,.25)}
.section-tab.disabled{cursor:not-allowed;opacity:.55;pointer-events:none}
.btn-primary{display:inline-flex;align-items:center;gap:7px;padding:10px 20px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;border-radius:11px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13.5px;font-weight:750;cursor:pointer;text-decoration:none;transition:all .22s;box-shadow:0 4px 14px rgba(21,88,168,.25)}
.btn-primary:hover{transform:translateY(-1px);box-shadow:0 6px 20px rgba(21,88,168,.35)}
.btn-trash{display:inline-flex;align-items:center;gap:6px;padding:9px 16px;background:#FEF2F2;border:1.5px solid #FECACA;border-radius:11px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;font-weight:750;color:var(--red);text-decoration:none;transition:all .18s}
.btn-trash:hover{background:#FEE2E2;border-color:#FCA5A5}
.stats-row{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:22px}
.stat-mini{background:#fff;border:1px solid rgba(213,224,240,.45);border-radius:14px;padding:16px 18px;display:flex;align-items:center;gap:14px;transition:box-shadow .25s,transform .25s;
  box-shadow:0 1px 3px rgba(15,38,69,.03),0 4px 12px rgba(15,38,69,.04)}
.stat-mini:hover{box-shadow:0 4px 14px rgba(21,88,168,.08);transform:translateY(-2px)}
.stat-mini-icon{width:42px;height:42px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0}
.ic-blue{background:rgba(58,189,224,.12)}.ic-green{background:rgba(5,150,105,.1)}.ic-red{background:rgba(220,38,38,.1)}.ic-gold{background:rgba(217,119,6,.12)}
.stat-mini-val{font-family:'Plus Jakarta Sans',sans-serif;font-size:24px;color:var(--ink);line-height:1}
.stat-mini-lbl{font-size:11.5px;color:var(--muted);font-weight:750;margin-top:2px}
.card{background:#fff;border:1px solid rgba(213,224,240,.45);border-radius:16px;overflow:hidden;
  box-shadow:0 1px 3px rgba(15,38,69,.03),0 4px 12px rgba(15,38,69,.04)}
.card-head{padding:20px 24px 14px;border-bottom:1px solid rgba(213,224,240,.4);display:flex;align-items:center;justify-content:space-between}
.card-title{font-family:'Plus Jakarta Sans',sans-serif;font-size:17px;font-weight:700;color:var(--ink)}
.card-sub{font-size:12.5px;color:var(--muted);margin-top:2px}
/* Filter */
.filter-bar{display:flex;gap:10px;align-items:center;padding:13px 22px;border-bottom:1px solid var(--border);background:var(--surface);flex-wrap:wrap}
.fsearch{flex:1;min-width:200px;max-width:300px;position:relative}
.fsearch input{width:100%;height:36px;padding:0 13px 0 36px;background:#fff;border:1.5px solid var(--border);border-radius:10px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;color:var(--ink);outline:none;transition:all .18s}
.fsearch input:focus{border-color:var(--cyan);box-shadow:0 0 0 3px rgba(58,189,224,.1)}
.fsearch::before{content:'🔍';position:absolute;left:12px;top:50%;transform:translateY(-50%);font-size:12px;pointer-events:none;opacity:.45}
.fselect{height:38px;padding:0 12px;background:#fff;border:1.5px solid var(--border);border-radius:10px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;color:var(--ink);outline:none;cursor:pointer;transition:all .18s}
.fselect:focus{border-color:var(--cyan)}
.fchip{height:36px;padding:0 14px;background:#fff;border:1.5px solid var(--border);border-radius:10px;font-family:'Plus Jakarta Sans',sans-serif;font-size:12.5px;font-weight:750;color:var(--navy);cursor:pointer;transition:all .18s;white-space:nowrap}
.fchip:hover{border-color:var(--cyan);color:var(--blue)}
.fchip.clear{color:var(--muted)}.fchip.clear:hover{border-color:var(--red);color:var(--red)}
/* Table */
.tbl-wrap{overflow-x:auto}
.tbl{width:100%;border-collapse:collapse;font-size:13px}
.tbl th{padding:10px 16px;background:var(--surface);border-bottom:1px solid var(--border);font-size:10.5px;font-weight:750;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;white-space:nowrap}
.tbl td{padding:12px 16px;border-bottom:1px solid #F4F7FC;vertical-align:middle}
.tbl tbody tr{cursor:pointer;transition:background .12s}
.tbl tbody tr:hover{background:#F7FBFF}
.tbl tbody tr:last-child td{border-bottom:none}
.cell-user{display:flex;align-items:center;gap:10px}
.av{width:34px;height:34px;border-radius:9px;flex-shrink:0;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff;overflow:hidden}
.cell-name{font-size:13.5px;font-weight:750;color:var(--ink)}
.cell-sub{font-size:11.5px;color:var(--muted);margin-top:1px}
/* Badges */
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:750;white-space:nowrap}
.b-green{background:rgba(5,150,105,.1);color:var(--green)}
.b-red{background:rgba(220,38,38,.1);color:var(--red)}
.b-blue{background:rgba(21,88,168,.1);color:var(--blue)}
.b-gold{background:rgba(217,119,6,.1);color:var(--gold)}
.b-gray{background:#F1F5F9;color:#64748B}
/* Row actions */
.act-group{display:flex;gap:6px}
.act-btn{padding:5px 10px;border-radius:7px;font-size:12px;font-weight:750;text-decoration:none;cursor:pointer;border:none;font-family:'Plus Jakarta Sans',sans-serif;transition:all .15s;white-space:nowrap}
.act-view{background:rgba(21,88,168,.08);color:var(--blue)}.act-view:hover{background:rgba(21,88,168,.16)}
.act-del{background:rgba(220,38,38,.08);color:var(--red)}.act-del:hover{background:rgba(220,38,38,.16)}
/* Pagination */
.pagination{display:flex;align-items:center;justify-content:space-between;padding:14px 24px;border-top:1px solid var(--border)}
.pg-info{font-size:12.5px;color:var(--muted)}
.pg-btns{display:flex;gap:5px}
.pg-btn{width:32px;height:32px;border-radius:8px;display:inline-flex;align-items:center;justify-content:center;font-size:13px;font-weight:750;text-decoration:none;color:var(--navy);background:var(--surface);border:1.5px solid var(--border);transition:all .15s}
.pg-btn:hover{border-color:var(--cyan);color:var(--blue)}.pg-btn.on{background:var(--blue);border-color:var(--blue);color:#fff}.pg-btn.off{opacity:.4;pointer-events:none}
/* Empty */
.empty{padding:48px 24px;text-align:center;color:var(--muted)}.empty .ei{font-size:36px;margin-bottom:10px}
/* Toast */
.toast{position:fixed;top:20px;right:24px;padding:12px 20px;border-radius:11px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13.5px;font-weight:750;display:flex;align-items:center;gap:8px;box-shadow:0 8px 32px rgba(0,0,0,.2);z-index:999;transition:opacity .4s}
.toast-ok{background:#064e3b;color:#fff}.toast-warn{background:#92400E;color:#fff}
@keyframes fadeUp{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)}}
.stat-mini:nth-child(1){animation:fadeUp .3s .05s ease both}.stat-mini:nth-child(2){animation:fadeUp .3s .1s ease both}.stat-mini:nth-child(3){animation:fadeUp .3s .15s ease both}.stat-mini:nth-child(4){animation:fadeUp .3s .2s ease both}
.card{animation:fadeUp .35s .1s ease both}
select,option{font-family:inherit;font-size:inherit}
.cdd{position:relative;user-select:none;display:inline-block}
.cdd-btn{display:flex;align-items:center;gap:6px;padding:9px 14px;background:var(--white,#fff);border:1.5px solid var(--border,#D5E0F0);border-radius:10px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;font-weight:750;color:var(--ink,#0B1628);cursor:pointer;transition:all .18s;white-space:nowrap}
.cdd-btn:hover{border-color:var(--cyan,#3ABDE0);background:var(--cyan-soft,#EBF8FD)}
.cdd-btn.open{border-color:var(--cyan,#3ABDE0);box-shadow:0 0 0 3px rgba(58,189,224,.12)}
.cdd-arrow{font-size:9px;color:var(--muted,#7A90B0);transition:transform .2s}
.cdd-btn.open .cdd-arrow{transform:rotate(180deg)}
.cdd-menu{position:absolute;top:calc(100% + 6px);left:0;min-width:100%;background:var(--white,#fff);border:1.5px solid var(--border,#D5E0F0);border-radius:12px;padding:6px;box-shadow:0 12px 36px rgba(15,38,69,.15);z-index:200;opacity:0;transform:translateY(-6px);pointer-events:none;transition:all .18s ease;max-height:260px;overflow-y:auto}
.cdd-menu.show{opacity:1;transform:translateY(0);pointer-events:auto}
.cdd-menu::-webkit-scrollbar{width:4px}
.cdd-menu::-webkit-scrollbar-thumb{background:var(--border,#D5E0F0);border-radius:4px}
.cdd-opt{padding:8px 14px;border-radius:8px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;font-weight:600;color:var(--ink,#0B1628);cursor:pointer;transition:all .12s;white-space:nowrap}
.cdd-opt:hover{background:var(--surface,#F1F5FB);color:var(--blue,#1558A8)}
.cdd-opt.active{background:linear-gradient(135deg,var(--blue,#1558A8),#0D3F85);color:#fff;font-weight:750}
</style>
    
<meta name="csrf-token" content="${csrfToken}">
<script src="${pageContext.request.contextPath}/js/csrf.js"></script>
</head>
<body>
<%@ include file="/WEB-INF/views/loading.jsp" %>

<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">
  <header class="topbar">
    <span class="topbar-title">👤 Quản lý tài khoản</span>
    <div class="topbar-right">
      <a href="${pageContext.request.contextPath}/admin-profile" class="topbar-user" style="font-size:13px;font-weight:750;color:var(--muted);text-decoration:none;padding:6px 12px;border:1.5px solid var(--border);border-radius:8px;">← Dashboard</a>
      <div class="topbar-user">
        <div class="topbar-av"><%= initials %></div>
        <span class="topbar-name"><%= fullName %></span>
      </div>
    </div>
  </header>

  <div class="content">
    <div class="page-head">
      <div>
        <div class="breadcrumb">medicare › Quản lý › Tài khoản</div>
        <h1>Tài khoản nhân viên</h1>
      </div>
      <div style="display:flex;gap:10px;align-items:center">
      <a href="${pageContext.request.contextPath}/accounts?action=trash" class="btn-secondary" style="background:#fef2f2;color:#dc2626;border:1px solid #fecaca;padding:9px 16px;border-radius:8px;font-size:13px;font-weight:750;text-decoration:none">🗑️ Thùng rác</a>
      <a href="${pageContext.request.contextPath}/accounts?action=new" class="btn-primary">＋ Tạo tài khoản</a>
    </div>
    </div>

    <div class="section-tabs">
      <a href="${pageContext.request.contextPath}/accounts" class="section-tab active">👤 Quản lý nhân viên</a>
      <a href="${pageContext.request.contextPath}/customers" class="section-tab">👥 Khách hàng</a>
    </div>

    <%-- YÊU CẦU ĐĂNG KÝ LẠI KHUÔN MẶT --%>
    <%
      java.util.List<com.medicare.entity.Account> pendingRe =
          (java.util.List<com.medicare.entity.Account>) request.getAttribute("pendingReenroll");
      if (pendingRe != null && !pendingRe.isEmpty()) {
    %>
    <div style="background:#fffbeb;border:1.5px solid #fde68a;border-radius:14px;padding:18px 20px;margin-bottom:22px">
      <div style="display:flex;align-items:center;gap:8px;margin-bottom:12px">
        <span style="font-size:20px">🔄</span>
        <b style="font-size:15px;color:#b45309">Yêu cầu đăng ký lại khuôn mặt (<%= pendingRe.size() %>)</b>
      </div>
      <div style="display:flex;flex-direction:column;gap:10px">
        <% for (com.medicare.entity.Account rq : pendingRe) {
             String rn = rq.getFullName()!=null? rq.getFullName() : rq.getUsername();
             String rreason = rq.getFaceReenrollReason()!=null? rq.getFaceReenrollReason() : "(không nêu)";
        %>
        <div style="background:#fff;border:1px solid #fde68a;border-radius:10px;padding:12px 14px;display:flex;justify-content:space-between;align-items:center;gap:14px;flex-wrap:wrap">
          <div style="min-width:220px;flex:1">
            <div style="font-weight:750;color:#0f172a"><%= rn %> <span style="font-weight:400;color:#94a3b8;font-size:12px">@<%= rq.getUsername() %> · ID <%= rq.getAccountId() %></span></div>
            <div style="font-size:13px;color:#78716c;margin-top:3px"><b>Lý do:</b> <%= rreason %></div>
            <% if (rq.getFaceReenrollRequestedAt()!=null) { %>
            <div style="font-size:11.5px;color:#a8a29e;margin-top:2px">Gửi lúc: <%= rq.getFaceReenrollRequestedAt().getDayOfMonth()+"/"+rq.getFaceReenrollRequestedAt().getMonthValue()+"/"+rq.getFaceReenrollRequestedAt().getYear()+" "+String.format("%02d:%02d", rq.getFaceReenrollRequestedAt().getHour(), rq.getFaceReenrollRequestedAt().getMinute()) %></div>
            <% } %>
          </div>
          <div style="display:flex;gap:8px">
            <button type="button" onclick="reenrollDecision(<%= rq.getAccountId() %>,'approve','<%= rn.replace("'","\\'") %>')"
                    style="background:linear-gradient(135deg,#059669,#047857);color:#fff;border:none;border-radius:8px;padding:9px 16px;font-weight:750;font-size:13px;cursor:pointer;font-family:inherit">✅ Duyệt</button>
            <button type="button" onclick="reenrollDecision(<%= rq.getAccountId() %>,'reject','<%= rn.replace("'","\\'") %>')"
                    style="background:#fef2f2;color:#dc2626;border:1px solid #fecaca;border-radius:8px;padding:9px 16px;font-weight:750;font-size:13px;cursor:pointer;font-family:inherit">✕ Từ chối</button>
          </div>
        </div>
        <% } %>
      </div>
    </div>
    <% } %>

    <%-- STATS --%>
    <%
      java.util.List<com.medicare.entity.Account> allList =
          (java.util.List<com.medicare.entity.Account>) request.getAttribute("accounts");
      if (allList == null) allList = new java.util.ArrayList<>();
      long cntAll    = allList.size();
      long cntActive = allList.stream().filter(com.medicare.entity.Account::isActive).count();
      long cntLocked = cntAll - cntActive;
      long cntAdmin  = allList.stream().filter(a -> a.getRoleId() == 1).count();
    %>
    <div class="stats-row">
      <div class="stat-mini">
        <div class="stat-mini-icon ic-blue">👥</div>
        <div><div class="stat-mini-val"><%= cntAll %></div><div class="stat-mini-lbl">Tổng tài khoản</div></div>
      </div>
      <div class="stat-mini">
        <div class="stat-mini-icon ic-green">✅</div>
        <div><div class="stat-mini-val"><%= cntActive %></div><div class="stat-mini-lbl">Đang hoạt động</div></div>
      </div>
      <div class="stat-mini">
        <div class="stat-mini-icon ic-red">🔒</div>
        <div><div class="stat-mini-val"><%= cntLocked %></div><div class="stat-mini-lbl">Đã khóa</div></div>
      </div>
      <div class="stat-mini">
        <div class="stat-mini-icon ic-gold">🛡️</div>
        <div><div class="stat-mini-val"><%= cntAdmin %></div><div class="stat-mini-lbl">Quản trị viên</div></div>
      </div>
    </div>

    <%-- TABLE --%>
    <div class="card">
      <div class="card-head">
        <div>
          <div class="card-title">Danh sách tài khoản</div>
          <div class="card-sub">Nhấn vào hàng để xem chi tiết nhân viên</div>
        </div>
      </div>

      <div class="filter-bar">
          <div class="fsearch">
            <input type="text" id="searchInput" placeholder="Tìm tên, email, CCCD…" autocomplete="off">
          </div>
          <input type="hidden" id="roleFilter" value="">
          <div class="cdd" id="cddRoleFilter">
            <div class="cdd-btn" onclick="toggleCdd('cddRoleFilter')">
              <span class="cdd-label">Tất cả chức vụ</span>
              <span class="cdd-arrow">▼</span>
            </div>
            <div class="cdd-menu">
              <div class="cdd-opt active" data-val="" onclick="pickCdd('cddRoleFilter','roleFilter',this,false);applyFilter()">Tất cả chức vụ</div>
              <div class="cdd-opt" data-val="2" onclick="pickCdd('cddRoleFilter','roleFilter',this,false);applyFilter()">💊 Dược sĩ</div>
              <div class="cdd-opt" data-val="3" onclick="pickCdd('cddRoleFilter','roleFilter',this,false);applyFilter()">📦 Thủ kho</div>
            </div>
          </div>
          <input type="hidden" id="statusFilter" value="">
          <div class="cdd" id="cddStatusFilter">
            <div class="cdd-btn" onclick="toggleCdd('cddStatusFilter')">
              <span class="cdd-label">Tất cả trạng thái</span>
              <span class="cdd-arrow">▼</span>
            </div>
            <div class="cdd-menu">
              <div class="cdd-opt active" data-val="" onclick="pickCdd('cddStatusFilter','statusFilter',this,false);applyFilter()">Tất cả trạng thái</div>
              <div class="cdd-opt" data-val="1" onclick="pickCdd('cddStatusFilter','statusFilter',this,false);applyFilter()">🟢 Đang online</div>
              <div class="cdd-opt" data-val="active" onclick="pickCdd('cddStatusFilter','statusFilter',this,false);applyFilter()">✅ Hoạt động</div>
              <div class="cdd-opt" data-val="0" onclick="pickCdd('cddStatusFilter','statusFilter',this,false);applyFilter()">🔒 Đã khóa</div>
            </div>
          </div>
          <button type="button" class="fchip clear" onclick="clearFilter()">✕ Xóa lọc</button>
        </div>

      <div class="tbl-wrap">
        <table class="tbl">
          <thead>
            <tr>
              <th style="width:44px">#</th>
              <th>Nhân viên</th>
              <th>Email</th>
              <th>Điện thoại</th>
              <th>CCCD</th>
              <th style="min-width:95px">Chức vụ</th>
              <th>Trạng thái</th>
              <th>Đăng nhập cuối</th>
              <th style="width:180px">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <c:choose>
              <c:when test="${empty accounts}">
                <tr><td colspan="9">
                  <div class="empty"><div class="ei">👤</div><p>Không tìm thấy tài khoản nào.</p></div>
                </td></tr>
              </c:when>
              <c:otherwise>
                <c:forEach var="a" items="${accounts}" varStatus="st">
                  <tr onclick="location.href='${pageContext.request.contextPath}/accounts?action=view&id=${a.accountId}'"
                      data-name="${fn:toLowerCase(not empty a.fullName ? a.fullName : a.username)} @${fn:toLowerCase(a.username)} ${not empty a.email ? fn:toLowerCase(a.email) : ''} ${not empty a.citizenId ? a.citizenId : ''}"
                      data-role="${a.roleId}"
                      data-status="${a.active ? '1' : '0'}" data-acc-id="${a.accountId}">
                    <td style="color:var(--muted);font-size:12px">${st.count}</td>
                    <td>
                      <div class="cell-user">
                        <c:set var="dn" value="${not empty a.fullName ? a.fullName : a.username}"/>
                        <div class="av">
                          ${fn:toUpperCase(fn:substring(dn,0,1))}${fn:toUpperCase(fn:substring(dn,1,2))}
                        </div>
                        <div>
                          <div class="cell-name">${not empty a.fullName ? a.fullName : '—'}</div>
                          <div class="cell-sub">@${a.username}</div>
                        </div>
                      </div>
                    </td>
                    <td style="color:var(--muted);font-size:13px">${not empty a.email ? a.email : '—'}</td>
                    <td style="color:var(--muted);font-size:13px">${not empty a.phone ? a.phone : '—'}</td>
                    <td style="color:var(--muted);font-size:13px">${not empty a.citizenId ? a.citizenId : '—'}</td>
                    <td>
                      <c:choose>
                        <c:when test="${a.roleId==1}"><span class="badge b-red">Admin</span></c:when>
                        <c:when test="${a.roleId==2}"><span class="badge b-blue">Dược sĩ</span></c:when>
                        <c:otherwise><span class="badge b-gold">Thủ kho</span></c:otherwise>
                      </c:choose>
                    </td>
                    <td class="status-badge-cell">
                      <c:choose>
                          <c:when test="${!a.active}">
                            <span class="badge b-red">🔒 Đã khóa</span>
                          </c:when>
                          <c:when test="${onlineStaff != null && onlineStaff.contains(a.accountId.toString())}">
                            <span class="badge b-green">🟢 Đang online</span>
                          </c:when>
                          <c:otherwise>
                            <span class="badge" style="background:#F1F5F9;color:#64748B">⚫ Offline</span>
                          </c:otherwise>
                        </c:choose>
                    </td>
                    <td style="color:var(--muted);font-size:12px">
                      <c:choose>
                        <c:when test="${a.lastLoginAt != null}">
                          ${a.lastLoginAt.dayOfMonth}/${a.lastLoginAt.monthValue}/${a.lastLoginAt.year} ${a.lastLoginAt.hour}:<c:if test="${a.lastLoginAt.minute lt 10}">0</c:if>${a.lastLoginAt.minute}
                        </c:when>
                        <c:otherwise>Chưa đăng nhập</c:otherwise>
                      </c:choose>
                    </td>
                    <td onclick="event.stopPropagation()">
                      <div class="act-group">
                        <a href="${pageContext.request.contextPath}/accounts?action=view&id=${a.accountId}" class="act-btn act-view">👁 Xem</a>
                        <c:if test="${a.roleId != 1}">
                          <button onclick="openFaceEnroll(${a.accountId},'${fn:escapeXml(not empty a.fullName ? a.fullName : a.username)}',${a.faceEnrolled})"
                                  class="act-btn"
                                  style="background:${a.faceEnrolled ? '#d1fae5' : '#eff6ff'};color:${a.faceEnrolled ? '#065f46' : '#1558A8'};border:1px solid ${a.faceEnrolled ? '#6ee7b7' : '#bfdbfe'}"
                                  title="${a.faceEnrolled ? 'Đã đăng ký khuôn mặt — bấm để cập nhật' : 'Chưa đăng ký khuôn mặt'}">
                            ${a.faceEnrolled ? '📷✓' : '📷'}
                          </button>
                        </c:if>
                        <form method="post" action="${pageContext.request.contextPath}/accounts" style="display:inline"
                              onsubmit="return confirm('Chuyển tài khoản @${a.username} vào thùng rác?')">
                          <input type="hidden" name="action" value="delete">
                          <input type="hidden" name="id" value="${a.accountId}">
                          <button type="submit" class="act-btn" style="background:#fef2f2;color:#dc2626;border:1px solid #fecaca;cursor:pointer">🗑️</button>
                        </form>
                      </div>
                    </td>
                  </tr>
                </c:forEach>
              </c:otherwise>
            </c:choose>
          </tbody>
        </table>
      </div>

      <%
        Integer curPage   = (Integer) request.getAttribute("currentPage");
        Integer totPages  = (Integer) request.getAttribute("totalPages");
        Integer totRecs   = (Integer) request.getAttribute("totalRecords");
        if (curPage  == null) curPage  = 1;
        if (totPages == null) totPages = 1;
        if (totRecs  == null) totRecs  = allList.size();
      %>
      <div class="pagination">
        <div class="pg-info">Trang <%= curPage %> / <%= totPages %> &nbsp;·&nbsp; Tổng <%= totRecs %> tài khoản</div>
        <div class="pg-btns">
          <% if (curPage > 1) { %>
          <a href="?page=<%= curPage-1 %>&q=${param.q}&role=${param.role}&status=${param.status}" class="pg-btn">‹</a>
          <% } else { %><span class="pg-btn off">‹</span><% } %>
          <% for (int p = Math.max(1,curPage-2); p <= Math.min(totPages,curPage+2); p++) { %>
          <a href="?page=<%= p %>&q=${param.q}&role=${param.role}&status=${param.status}"
             class="pg-btn <%= p==curPage?"on":"" %>"><%= p %></a>
          <% } %>
          <% if (curPage < totPages) { %>
          <a href="?page=<%= curPage+1 %>&q=${param.q}&role=${param.role}&status=${param.status}" class="pg-btn">›</a>
          <% } else { %><span class="pg-btn off">›</span><% } %>
        </div>
      </div>
    </div>
  </div>
</div>

<% if ("protected-admin".equals(msg)) { %><div class="toast toast-warn">🛡️ Tài khoản Admin gốc được bảo vệ — không thể khóa hoặc xóa!</div>
<% } else if ("created".equals(msg)) { %><div class="toast toast-ok">✅ Tạo tài khoản thành công!</div>
<% } else if ("updated".equals(msg)) { %><div class="toast toast-ok">✅ Cập nhật thành công!</div>
<% } else if ("locked".equals(msg)) { %><div class="toast toast-warn">🔒 Đã khóa tài khoản.</div>
<% } else if ("unlocked".equals(msg)) {
     String unlockedNameParam = request.getParameter("name");
%><div class="toast toast-ok" style="flex-direction:column;align-items:flex-start;gap:3px">
  <div>🔓 Đã mở khóa tài khoản thành công!</div>
  <% if (unlockedNameParam != null && !unlockedNameParam.isEmpty()) { %>
  <div style="font-size:12px;opacity:.8">📧 Đã gửi email thông báo đến <strong><%= unlockedNameParam %></strong></div>
  <% } %>
</div>
<% } else if ("deleted".equals(msg)) { %><div class="toast toast-warn">🗑️ Đã chuyển vào thùng rác.</div>
<% } else if ("nochange".equals(msg)) { %><div class="toast toast-warn">ℹ️ Không có thay đổi nào được ghi nhận.</div>
<% } else if ("last-admin".equals(msg)) { %><div class="toast toast-warn">⚠️ Không thể thực hiện — đây là Admin duy nhất!</div>
<% } else if ("in-reset".equals(msg)) { %><div class="toast toast-warn">🔒 Không thể mở khóa — tài khoản đang chờ đặt lại mật khẩu!</div>
<% } else if ("otp-expired".equals(msg)) { %><div class="toast toast-warn">⏱️ Mã OTP đã hết hạn.</div>
<% } %>

<script>
function toggleCdd(id){var w=document.getElementById(id),m=w.querySelector('.cdd-menu'),b=w.querySelector('.cdd-btn');var open=m.classList.contains('show');document.querySelectorAll('.cdd-menu.show').forEach(function(x){x.classList.remove('show');x.closest('.cdd').querySelector('.cdd-btn').classList.remove('open')});if(!open){m.classList.add('show');b.classList.add('open');var act=m.querySelector('.cdd-opt.active');if(act)act.scrollIntoView({block:'nearest'})}}
function pickCdd(wId,hId,el,autoSubmit){document.getElementById(hId).value=el.dataset.val;var w=document.getElementById(wId);w.querySelector('.cdd-label').textContent=el.textContent;w.querySelectorAll('.cdd-opt').forEach(function(o){o.classList.remove('active')});el.classList.add('active');w.querySelector('.cdd-menu').classList.remove('show');w.querySelector('.cdd-btn').classList.remove('open');if(autoSubmit){var f=w.closest('form');if(f)f.submit()}}
document.addEventListener('click',function(e){if(!e.target.closest('.cdd')){document.querySelectorAll('.cdd-menu.show').forEach(function(m){m.classList.remove('show');m.closest('.cdd').querySelector('.cdd-btn').classList.remove('open')})}});

const t = document.querySelector('.toast');
if (t) setTimeout(() => { t.style.opacity='0'; t.style.transition='opacity .4s'; setTimeout(()=>t.remove(),400); }, 3000);

// ── DUYỆT / TỪ CHỐI yêu cầu đăng ký lại khuôn mặt ──
async function reenrollDecision(accountId, action, name) {
  let note = '';
  if (action === 'approve') {
    if (!confirm('Duyệt yêu cầu đổi khuôn mặt của "' + name + '"?\n\nKhuôn mặt cũ sẽ bị XÓA và nhân viên phải đăng ký lại từ đầu. Hệ thống sẽ gửi email thông báo.')) return;
  } else {
    note = prompt('Từ chối yêu cầu của "' + name + '".\nNhập lý do (gửi kèm email cho nhân viên):', '');
    if (note === null) return; // hủy
  }
  try {
    const res = await fetch('${pageContext.request.contextPath}/face-reenroll', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ action: action, accountId: accountId, note: note })
    });
    const data = await res.json();
    if (data.ok) {
      alert(action === 'approve'
        ? '✅ Đã duyệt. Đã xóa khuôn mặt cũ và gửi email cho nhân viên đăng ký lại.'
        : '✕ Đã từ chối và gửi email thông báo cho nhân viên.');
      window.location.reload();
    } else {
      const map = { 'no_pending_request':'Yêu cầu không còn tồn tại (có thể đã xử lý).', 'unauthorized':'Phiên đăng nhập hết hạn.', 'account_not_found':'Không tìm thấy tài khoản.' };
      alert('❌ ' + (map[data.reason] || ('Lỗi: ' + data.reason)));
    }
  } catch (e) {
    alert('❌ Lỗi kết nối: ' + e.message);
  }
}

// ── REALTIME FILTER ──────────────────────────────────────────
function applyFilter() {
    const q      = (document.getElementById('searchInput').value || '').toLowerCase().trim();
    const role   = document.getElementById('roleFilter').value;
    const status = document.getElementById('statusFilter').value;
    let visible  = 0;

    document.querySelectorAll('tbody tr[data-name]').forEach(row => {
        const name   = (row.dataset.name   || '').toLowerCase();
        const rId    = row.dataset.role    || '';
        const isAct  = row.dataset.status  || '';
        // online: check badge text
        const badge  = row.querySelector('td:nth-child(8) .badge');
        const isOnline = badge && badge.textContent.includes('online');

        const matchQ = !q || name.includes(q);
        const matchRole = !role || rId === role;
        let matchStatus = true;
        if (status === '1')      matchStatus = isOnline;
        else if (status === 'active') matchStatus = isAct === '1';
        else if (status === '0') matchStatus = isAct === '0';

        const show = matchQ && matchRole && matchStatus;
        row.style.display = show ? '' : 'none';
        if (show) visible++;
    });

    // Cập nhật empty state
    const empty = document.getElementById('emptyRow');
    const emptyMsg = document.getElementById('noResultMsg');
    if (empty) empty.style.display = visible === 0 ? '' : 'none';
    if (emptyMsg) emptyMsg.style.display = visible === 0 ? '' : 'none';
}

function resetCddFilter(wId, hId) {
    var w = document.getElementById(wId);
    document.getElementById(hId).value = '';
    var first = w.querySelector('.cdd-opt[data-val=""]');
    w.querySelectorAll('.cdd-opt').forEach(function(o){ o.classList.remove('active'); });
    if (first) { first.classList.add('active'); w.querySelector('.cdd-label').textContent = first.textContent; }
}

function clearFilter() {
    document.getElementById('searchInput').value = '';
    resetCddFilter('cddRoleFilter', 'roleFilter');
    resetCddFilter('cddStatusFilter', 'statusFilter');
    applyFilter();
}

// Realtime: gõ là lọc ngay
document.addEventListener('DOMContentLoaded', function() {
  const si = document.getElementById('searchInput');
  if (si) si.addEventListener('input', applyFilter);
});
document.getElementById('searchInput').addEventListener('input', applyFilter);
document.getElementById('roleFilter').addEventListener('change', applyFilter);
document.getElementById('statusFilter').addEventListener('change', applyFilter);

// Enter trong search box cũng lọc
document.getElementById('searchInput').addEventListener('keydown', e => {
    if (e.key === 'Enter') { e.preventDefault(); applyFilter(); }
});
</script>
<script>
// Polling online status mỗi 15s — không reload trang
async function refreshOnlineStatus() {
  if (document.hidden) return; // tab ở nền — khỏi bắn request, đỡ tốn 1/6 connection-per-origin
  try {
    const res = await fetch('${pageContext.request.contextPath}/accounts?action=online-status', {
      headers: {'X-Requested-With': 'XMLHttpRequest'}
    });
    // 401 = session hết hạn sau restart → redirect về login
    if (res.status === 401) {
      window.location.href = '${pageContext.request.contextPath}/login';
      return;
    }
    if (!res.ok) return;
    const data = await res.json();
    if (!data.onlineIds) return;
    document.querySelectorAll('tbody tr[data-status]').forEach(row => {
      const accId = row.dataset.accId;
      if (!accId) return;
      const td = row.querySelector('.status-badge-cell');
      if (!td) return;
      const isActive = row.dataset.status === '1';
      const isOnline = data.onlineIds.includes(accId);
      if (!isActive) {
        td.innerHTML = '<span class="badge b-red">🔒 Đã khóa</span>';
      } else if (isOnline) {
        td.innerHTML = '<span class="badge b-green" style="background:rgba(5,150,105,.1);color:#059669">🟢 Đang online</span>';
      } else {
        td.innerHTML = '<span class="badge" style="background:#F1F5F9;color:#64748B">⚫ Offline</span>';
      }
    });
  } catch(e) {}
}
refreshOnlineStatus();
setInterval(refreshOnlineStatus, 15000);
document.addEventListener('visibilitychange', () => { if (!document.hidden) refreshOnlineStatus(); });
</script>

<!-- ═══════════════ FACE ENROLLMENT MODAL (Admin) ═══════════════ -->
<style>
.face-enroll-modal{display:none;position:fixed;inset:0;z-index:900;align-items:center;justify-content:center}
.face-enroll-modal.show{display:flex}
.fem-backdrop{position:absolute;inset:0;background:rgba(0,0,0,.65);backdrop-filter:blur(5px)}
.fem-panel{position:relative;width:480px;background:#0f172a;border-radius:20px;padding:22px 24px 20px;box-shadow:0 24px 72px rgba(0,0,0,.6);animation:femIn .25s cubic-bezier(.34,1.56,.64,1)}
@keyframes femIn{from{opacity:0;transform:scale(.85)}to{opacity:1;transform:scale(1)}}
.fem-close{position:absolute;top:14px;right:16px;background:rgba(255,255,255,.08);border:none;color:rgba(255,255,255,.5);width:28px;height:28px;border-radius:7px;cursor:pointer;font-size:14px}
.fem-title{font-size:16px;font-weight:800;color:#f1f5f9;margin-bottom:2px}
.fem-name{font-size:13px;color:#3abde0;font-weight:750;margin-bottom:14px}
.fem-video-wrap{position:relative;width:100%;aspect-ratio:4/3;background:#020617;border-radius:12px;overflow:hidden;margin-bottom:10px}
#femVideo{width:100%;height:100%;object-fit:cover;transform:scaleX(-1)}
#femCanvas{position:absolute;inset:0;width:100%;height:100%;transform:scaleX(-1)}
.fem-overlay{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;pointer-events:none}
.fem-ring{width:170px;height:170px;border:3px solid rgba(255,255,255,.25);border-radius:50%;transition:.3s}
.fem-ring.scanning{border-color:#3b82f6;box-shadow:0 0 0 8px rgba(59,130,246,.15)}
.fem-ring.ready{border-color:#10b981;box-shadow:0 0 0 8px rgba(16,185,129,.15)}
.fem-status{font-size:13px;color:#94a3b8;text-align:center;min-height:20px;margin-bottom:10px;font-weight:750}
.fem-status.ok{color:#4ade80}
.fem-status.err{color:#f87171}
.fem-actions{display:flex;gap:8px}
.fem-btn-cancel{flex:1;height:38px;border-radius:9px;border:1px solid rgba(255,255,255,.1);background:transparent;color:rgba(255,255,255,.45);font-size:13px;cursor:pointer;font-family:inherit;transition:.15s}
.fem-btn-cancel:hover{border-color:rgba(255,255,255,.3);color:rgba(255,255,255,.7)}
.fem-btn-save{flex:2;height:38px;border-radius:9px;border:none;background:linear-gradient(135deg,#059669,#047857);color:#fff;font-size:13px;font-weight:750;cursor:pointer;font-family:inherit;transition:.2s}
.fem-btn-save:disabled{opacity:.4;cursor:not-allowed}
.fem-loader{display:flex;align-items:center;justify-content:center;gap:8px;color:#64748b;font-size:12px;padding:16px}
.fem-spinner{width:18px;height:18px;border:2px solid rgba(255,255,255,.1);border-top-color:#3abde0;border-radius:50%;animation:femSpin .7s linear infinite}
@keyframes femSpin{to{transform:rotate(360deg)}}
.fem-hint{font-size:11px;color:#475569;text-align:center;margin-bottom:8px;line-height:1.4}
.fem-capture-count{font-size:11.5px;color:#64748b;text-align:center;margin-bottom:6px}
</style>

<div class="face-enroll-modal" id="faceEnrollModal">
  <div class="fem-backdrop" onclick="closeFaceEnroll()"></div>
  <div class="fem-panel">
    <button class="fem-close" onclick="closeFaceEnroll()">✕</button>
    <div class="fem-title">📷 Đăng ký khuôn mặt nhân viên</div>
    <div class="fem-name" id="femStaffName">—</div>
    <div id="femLoading" class="fem-loader"><div class="fem-spinner"></div>Đang tải mô hình nhận dạng…</div>
    <div id="femCamWrap" style="display:none">
      <div class="fem-hint">Nhìn thẳng vào camera, giữ ổn định — hệ thống sẽ chụp 5 góc khác nhau để tăng độ chính xác</div>
      <div class="fem-video-wrap">
        <video id="femVideo" autoplay muted playsinline></video>
        <canvas id="femCanvas"></canvas>
        <div class="fem-overlay"><div class="fem-ring" id="femRing"></div></div>
      </div>
      <div class="fem-capture-count" id="femCaptureCount"></div>
      <div class="fem-status" id="femStatus">Đang khởi động camera…</div>
      <div class="fem-actions">
        <button class="fem-btn-cancel" onclick="closeFaceEnroll()">Hủy</button>
        <button class="fem-btn-save" id="femSaveBtn" onclick="saveFaceDescriptor()" disabled>💾 Lưu khuôn mặt</button>
      </div>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/@vladmandic/face-api@1.7.13/dist/face-api.js"></script>
<script>
const _ctx = '${pageContext.request.contextPath}';
const FEM_MODEL_URL = 'https://cdn.jsdelivr.net/npm/@vladmandic/face-api@1.7.13/model/';
let femModelsLoaded = false;
let femVideoStream  = null;
let femDetectTimer  = null;
let femAccountId    = null;
let femDescriptors  = [];  // Accumulated descriptors from multiple captures
const FEM_CAPTURE_TARGET = 5; // Capture 5 frames and average

async function loadFemModels() {
  if (femModelsLoaded) return;
  await faceapi.nets.tinyFaceDetector.loadFromUri(FEM_MODEL_URL);
  await faceapi.nets.faceLandmark68TinyNet.loadFromUri(FEM_MODEL_URL);
  await faceapi.nets.faceRecognitionNet.loadFromUri(FEM_MODEL_URL);
  femModelsLoaded = true;
}

async function openFaceEnroll(accountId, name, hasExisting) {
  femAccountId   = accountId;
  femDescriptors = [];
  document.getElementById('faceEnrollModal').classList.add('show');
  document.getElementById('femStaffName').textContent = name + (hasExisting ? ' (đang cập nhật)' : '');
  document.getElementById('femLoading').style.display = 'flex';
  document.getElementById('femCamWrap').style.display = 'none';
  document.getElementById('femSaveBtn').disabled = true;
  setFemStatus('Đang tải mô hình AI…');

  try {
    await loadFemModels();
  } catch(e) {
    setFemStatus('❌ Không tải được mô hình: ' + e.message, 'err');
    document.getElementById('femLoading').style.display = 'none';
    document.getElementById('femCamWrap').style.display = 'block';
    return;
  }

  document.getElementById('femLoading').style.display = 'none';
  document.getElementById('femCamWrap').style.display = 'block';

  try {
    femVideoStream = await navigator.mediaDevices.getUserMedia({
      video: { width: 640, height: 480, facingMode: 'user' }
    });
    document.getElementById('femVideo').srcObject = femVideoStream;
    await document.getElementById('femVideo').play();
    startFemDetection();
  } catch(e) {
    setFemStatus('❌ Không truy cập được camera: ' + e.message, 'err');
  }
}

function closeFaceEnroll() {
  stopFemDetection();
  if (femVideoStream) { femVideoStream.getTracks().forEach(t => t.stop()); femVideoStream = null; }
  document.getElementById('faceEnrollModal').classList.remove('show');
  femDescriptors = [];
}

function startFemDetection() {
  const video = document.getElementById('femVideo');
  const ring  = document.getElementById('femRing');
  setFemStatus('Đang quét khuôn mặt…');
  updateCaptureCount();

  femDetectTimer = setInterval(async () => {
    if (video.readyState < 2 || femDescriptors.length >= FEM_CAPTURE_TARGET) return;
    const det = await faceapi
      .detectSingleFace(video, new faceapi.TinyFaceDetectorOptions({ inputSize: 224 }))
      .withFaceLandmarks(true)
      .withFaceDescriptor();

    if (!det) {
      ring.className = 'fem-ring';
      setFemStatus('Không phát hiện khuôn mặt — hãy nhìn thẳng vào camera');
      return;
    }

    ring.className = 'fem-ring scanning';
    femDescriptors.push(Array.from(det.descriptor));
    updateCaptureCount();

    if (femDescriptors.length >= FEM_CAPTURE_TARGET) {
      stopFemDetection();
      ring.className = 'fem-ring ready';
      setFemStatus('✓ Đã thu thập đủ dữ liệu — nhấn Lưu để hoàn tất', 'ok');
      document.getElementById('femSaveBtn').disabled = false;
    } else {
      setFemStatus('Đang thu thập… (' + femDescriptors.length + '/' + FEM_CAPTURE_TARGET + ')');
    }
  }, 600);
}

function stopFemDetection() {
  if (femDetectTimer) { clearInterval(femDetectTimer); femDetectTimer = null; }
}

function updateCaptureCount() {
  const el = document.getElementById('femCaptureCount');
  if (el) {
    el.textContent = femDescriptors.length >= FEM_CAPTURE_TARGET
      ? '✓ Đã thu thập ' + FEM_CAPTURE_TARGET + ' mẫu'
      : 'Mẫu: ' + femDescriptors.length + ' / ' + FEM_CAPTURE_TARGET;
  }
}

// Tính trung bình descriptor từ nhiều mẫu để tăng độ chính xác
function averageDescriptors(descs) {
  const len = descs[0].length;
  const avg = new Array(len).fill(0);
  for (const d of descs) { for (let i = 0; i < len; i++) avg[i] += d[i]; }
  return avg.map(v => v / descs.length);
}

async function saveFaceDescriptor() {
  if (!femAccountId || femDescriptors.length < FEM_CAPTURE_TARGET) return;
  const btn = document.getElementById('femSaveBtn');
  btn.disabled = true;
  btn.textContent = '⏳ Đang lưu…';

  const avgDescriptor = averageDescriptors(femDescriptors);
  const descriptorJson = '[' + avgDescriptor.map(v => v.toFixed(6)).join(',') + ']';

  try {
    const res = await fetch(_ctx + '/accounts', {
      method: 'POST',
      body: new URLSearchParams({
        action:     'save-face',
        accountId:  femAccountId,
        descriptor: descriptorJson
      }),
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    });
    const data = await res.json();
    if (data.ok) {
      closeFaceEnroll();
      // Cập nhật icon trong bảng
      const btn2 = document.querySelector('button[onclick*="openFaceEnroll(' + femAccountId + ',"]');
      if (btn2) {
        btn2.style.background = '#d1fae5';
        btn2.style.color = '#065f46';
        btn2.textContent = '📷✓';
      }
      showAdminToast('✅ Đã lưu khuôn mặt cho nhân viên!');
    } else {
      setFemStatus('❌ ' + (data.reason || 'Lỗi lưu dữ liệu'), 'err');
      btn.disabled = false;
      btn.textContent = '💾 Lưu khuôn mặt';
    }
  } catch(e) {
    setFemStatus('❌ Lỗi kết nối', 'err');
    btn.disabled = false;
    btn.textContent = '💾 Lưu khuôn mặt';
  }
}

function setFemStatus(msg, type) {
  const el = document.getElementById('femStatus');
  if (!el) return;
  el.textContent = msg;
  el.className   = 'fem-status' + (type ? ' ' + type : '');
}

function showAdminToast(msg) {
  const t = document.createElement('div');
  t.className = 'toast toast-ok';
  t.textContent = msg;
  t.style.cssText = 'position:fixed;bottom:24px;right:24px;top:auto;left:auto;transform:none;z-index:9999;padding:12px 18px;border-radius:10px;background:#064e3b;color:#fff;font-size:14px;font-weight:750;box-shadow:0 6px 24px rgba(0,0,0,.2)';
  document.body.appendChild(t);
  setTimeout(() => { t.style.opacity='0'; t.style.transition='opacity .3s'; setTimeout(()=>t.remove(),300); }, 3500);
}
</script>
</body>
</html>
