<%@ page contentType="text/html;charset=UTF-8" %>
<% String activeNav = "accounts"; %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    if (acc.getRoleId() != 1) { response.sendRedirect(request.getContextPath() + "/dashboard"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
    String msg = request.getParameter("msg");
    java.util.List<com.medicare.entity.Account> deletedList =
        (java.util.List<com.medicare.entity.Account>) request.getAttribute("deletedAccounts");
    if (deletedList == null) deletedList = new java.util.ArrayList<>();
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Thùng rác tài khoản — medicare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&family=DM+Serif+Display:ital@0;1&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;--cyan-soft:#EBF8FD;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;--sidebar:232px;
}
html,body{height:100%;font-family:'Outfit',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar::after{content:'';position:absolute;top:0;right:0;bottom:0;width:1px;background:linear-gradient(180deg,transparent,rgba(58,189,224,.12) 30%,rgba(58,189,224,.12) 70%,transparent)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-icon{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;box-shadow:0 4px 16px rgba(58,189,224,.35)}
.logo-text{font-family:'Outfit',sans-serif;font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
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
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06);flex-shrink:0}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08)}
.user-av{width:34px;height:34px;flex-shrink:0;border-radius:9px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.user-name{font-size:12.5px;font-weight:600;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:110px}
.user-role{font-size:10px;color:rgba(255,255,255,.35);margin-top:1px}
.logout-btn{margin-left:auto;width:28px;height:28px;flex-shrink:0;border-radius:8px;background:rgba(220,38,38,.12);border:none;display:flex;align-items:center;justify-content:center;color:rgba(220,38,38,.7);font-size:13px;cursor:pointer;text-decoration:none;transition:all .18s}
.logout-btn:hover{background:rgba(220,38,38,.2);color:#DC2626}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0;overflow-x:hidden}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'DM Serif Display',serif;font-size:16px;color:var(--ink)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px;flex-shrink:0}
.topbar-user{display:flex;align-items:center;gap:8px;padding:5px 12px 5px 7px;border:1.5px solid var(--border);border-radius:20px;text-decoration:none;color:inherit;transition:all .18s}
.topbar-user:hover{border-color:var(--cyan);background:var(--cyan-soft)}
.topbar-av{width:28px;height:28px;border-radius:8px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;color:#fff}
.topbar-name{font-size:13px;font-weight:600;color:var(--navy);max-width:110px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.content{padding:26px 28px;flex:1;min-width:0;overflow-x:auto}
.page-head{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:22px}
.breadcrumb{font-size:11.5px;color:var(--muted);font-weight:500;margin-bottom:4px}
.page-head h1{font-family:'DM Serif Display',serif;font-size:26px;color:var(--ink)}
.btn-primary{display:inline-flex;align-items:center;gap:7px;padding:10px 20px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;cursor:pointer;text-decoration:none;transition:all .22s;box-shadow:0 4px 14px rgba(21,88,168,.25)}
.btn-primary:hover{transform:translateY(-1px);box-shadow:0 6px 20px rgba(21,88,168,.35)}
.btn-back{display:inline-flex;align-items:center;gap:7px;padding:9px 18px;background:var(--white);border:1.5px solid var(--border);border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;color:var(--navy);text-decoration:none;transition:all .2s}
.btn-back:hover{border-color:var(--cyan);color:var(--blue)}
.stats-row{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:22px}
.stat-mini{background:var(--white);border:1px solid var(--border);border-radius:14px;padding:16px 18px;display:flex;align-items:center;gap:14px;transition:box-shadow .2s}
.stat-mini:hover{box-shadow:0 4px 16px rgba(21,88,168,.08)}
.stat-mini-icon{width:42px;height:42px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0}
.ic-blue{background:rgba(58,189,224,.12)}.ic-green{background:rgba(5,150,105,.1)}.ic-red{background:rgba(220,38,38,.1)}.ic-gold{background:rgba(217,119,6,.12)}
.stat-mini-val{font-family:'DM Serif Display',serif;font-size:24px;color:var(--ink);line-height:1}
.stat-mini-lbl{font-size:11.5px;color:var(--muted);font-weight:500;margin-top:2px}
.card{background:var(--white);border:1px solid var(--border);border-radius:18px;overflow:hidden}
.card-head{padding:20px 24px 14px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
.card-title{font-family:'DM Serif Display',serif;font-size:18px;color:var(--ink)}
.card-sub{font-size:12.5px;color:var(--muted);margin-top:2px}
.filter-row{display:flex;gap:10px;align-items:center;padding:14px 24px;border-bottom:1px solid var(--border);flex-wrap:wrap}
.filter-search{position:relative;flex:1;min-width:180px}
.filter-search input{width:100%;padding:8px 14px 8px 36px;background:var(--surface);border:1.5px solid var(--border);border-radius:10px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);outline:none;transition:all .18s}
.filter-search input:focus{border-color:var(--cyan);background:#fff}
.filter-search::before{content:'🔍';position:absolute;left:12px;top:50%;transform:translateY(-50%);font-size:12px;pointer-events:none;opacity:.45}
.filter-select{padding:8px 12px;background:var(--surface);border:1.5px solid var(--border);border-radius:10px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);outline:none;cursor:pointer;transition:all .18s}
.filter-select:focus{border-color:var(--cyan)}
.filter-chip{padding:8px 14px;background:var(--surface);border:1.5px solid var(--border);border-radius:10px;font-size:12.5px;font-weight:600;color:var(--navy);cursor:pointer;text-decoration:none;transition:all .18s;white-space:nowrap}
.filter-chip:hover{border-color:var(--cyan);color:var(--blue)}
.tbl-wrap{overflow-x:auto}
.tbl{width:100%;border-collapse:collapse;font-size:13px}
.tbl th{padding:10px 16px;background:var(--surface);border-bottom:1px solid var(--border);font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;white-space:nowrap}
.tbl td{padding:13px 16px;border-bottom:1px solid #F4F7FC;vertical-align:middle}
.tbl tbody tr:hover{background:#FAFCFF}
.tbl tbody tr:last-child td{border-bottom:none}
.cell-user{display:flex;align-items:center;gap:10px}
.av{width:34px;height:34px;border-radius:9px;flex-shrink:0;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.cell-name{font-size:13.5px;font-weight:600;color:var(--ink)}
.cell-sub{font-size:11.5px;color:var(--muted);margin-top:1px}
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:600}
.badge-green{background:rgba(5,150,105,.1);color:var(--green)}
.badge-red{background:rgba(220,38,38,.1);color:var(--red)}
.badge-blue{background:rgba(21,88,168,.1);color:var(--blue)}
.badge-gold{background:rgba(217,119,6,.1);color:var(--gold)}
.act-group{display:flex;gap:6px}
.act-btn{padding:5px 11px;border-radius:7px;font-size:12px;font-weight:600;text-decoration:none;cursor:pointer;border:none;font-family:'Outfit',sans-serif;transition:all .15s}
.act-edit{background:rgba(21,88,168,.08);color:var(--blue)}.act-edit:hover{background:rgba(21,88,168,.16)}
.act-restore{background:rgba(5,150,105,.08);color:var(--green)}.act-restore:hover{background:rgba(5,150,105,.16)}
.act-purge{background:rgba(220,38,38,.08);color:var(--red)}.act-purge:hover{background:rgba(220,38,38,.16)}
.act-force{background:var(--red);color:#fff;font-weight:700}.act-force:hover{background:#B91C1C}
.pagination{display:flex;align-items:center;justify-content:space-between;padding:14px 24px;border-top:1px solid var(--border)}
.pagination-info{font-size:12.5px;color:var(--muted)}
.pagination-btns{display:flex;gap:5px}
.page-btn{width:32px;height:32px;border-radius:8px;display:inline-flex;align-items:center;justify-content:center;font-size:13px;font-weight:600;text-decoration:none;color:var(--navy);background:var(--surface);border:1.5px solid var(--border);transition:all .15s}
.page-btn:hover{border-color:var(--cyan);color:var(--blue)}.page-btn.active{background:var(--blue);border-color:var(--blue);color:#fff}.page-btn.disabled{opacity:.4;pointer-events:none}
.empty{padding:48px 24px;text-align:center;color:var(--muted)}.empty .ei{font-size:36px;margin-bottom:10px}
.toast{position:fixed;top:20px;right:24px;padding:12px 20px;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;display:flex;align-items:center;gap:8px;box-shadow:0 8px 32px rgba(0,0,0,.2);z-index:999;transition:opacity .4s}
.toast-ok{background:#064e3b;color:#fff}.toast-warn{background:#92400E;color:#fff}
.form-section{max-width:820px}
.form-card{background:var(--white);border:1px solid var(--border);border-radius:18px;overflow:hidden;margin-bottom:20px}
.form-card-head{padding:20px 24px 16px;border-bottom:1px solid var(--border);background:linear-gradient(135deg,#FAFBFD,var(--surface));display:flex;align-items:center;gap:14px}
.form-card-head-icon{width:38px;height:38px;border-radius:10px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:17px;flex-shrink:0}
.form-card-head h2{font-family:'DM Serif Display',serif;font-size:17px;color:var(--ink);margin-bottom:2px}
.form-card-head p{font-size:12.5px;color:var(--muted)}
.form-body{padding:22px 24px}
.form-grid{display:grid;grid-template-columns:1fr 1fr;gap:18px}
.field{display:flex;flex-direction:column;gap:6px}.field.span-2{grid-column:span 2}
.field-label{font-size:12.5px;font-weight:700;color:var(--navy);letter-spacing:.3px}
.field-label .req{color:var(--red)}.field-label .hint{font-size:11.5px;font-weight:400;color:var(--muted)}
.field-input{width:100%;padding:11px 14px;background:#fff;border:1.5px solid var(--border);border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;color:var(--ink);outline:none;transition:all .18s}
.field-input:focus{border-color:var(--cyan);box-shadow:0 0 0 3px rgba(58,189,224,.1)}
.field-input:read-only{background:var(--surface);color:var(--muted);cursor:not-allowed}
.field-input::placeholder{color:var(--muted);font-weight:400}
select.field-input{cursor:pointer}
.field-note{font-size:11.5px;color:var(--muted);font-style:italic}
.pw-wrap{position:relative}.pw-wrap .field-input{padding-right:44px}
.pw-toggle{position:absolute;right:13px;top:50%;transform:translateY(-50%);background:none;border:none;cursor:pointer;font-size:16px;opacity:.45;transition:opacity .2s;padding:0}
.pw-toggle:hover{opacity:.8}
.action-row{display:flex;align-items:center;gap:12px;padding:0 24px 22px}
.btn-submit{display:inline-flex;align-items:center;gap:7px;padding:11px 22px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;border-radius:11px;font-family:'Outfit',sans-serif;font-size:14px;font-weight:700;cursor:pointer;transition:all .22s;box-shadow:0 4px 14px rgba(21,88,168,.25)}
.btn-submit:hover{transform:translateY(-1px);box-shadow:0 6px 20px rgba(21,88,168,.35)}.btn-submit:disabled{opacity:.55;cursor:not-allowed;transform:none}
.btn-cancel{padding:11px 20px;background:var(--white);border:1.5px solid var(--border);border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;color:var(--muted);text-decoration:none;transition:all .18s}
.btn-cancel:hover{border-color:var(--border);color:var(--navy)}.action-note{font-size:12px;color:var(--muted);font-style:italic}
.err-list{background:#FEF2F2;border:1px solid #FECACA;border-radius:12px;padding:14px 18px;margin-bottom:18px}
.err-list h3{font-size:13px;font-weight:700;color:#991B1B;margin-bottom:8px}.err-list li{font-size:12.5px;color:#B91C1C;margin-left:16px;margin-bottom:3px}
.email-highlight .field-input{border-color:#059669;background:#F0FDF4}
.detail-section{max-width:900px}
.detail-grid{display:grid;grid-template-columns:1fr 1fr;gap:16px}
.detail-card{background:var(--white);border:1px solid var(--border);border-radius:18px;overflow:hidden}
.detail-card-head{padding:18px 22px 14px;border-bottom:1px solid var(--border);background:linear-gradient(135deg,#FAFBFD,var(--surface))}
.detail-card-title{font-family:'DM Serif Display',serif;font-size:16px;color:var(--ink)}.detail-card-sub{font-size:12px;color:var(--muted);margin-top:2px}
.detail-field{padding:12px 22px;border-bottom:1px solid #F4F7FC;display:flex;flex-direction:column;gap:2px}.detail-field:last-child{border-bottom:none}
.df-label{font-size:10.5px;font-weight:700;text-transform:uppercase;letter-spacing:.6px;color:var(--muted)}
.df-value{font-size:13.5px;font-weight:500;color:var(--ink)}.df-value.empty{color:var(--muted);font-style:italic;font-weight:400}
.detail-actions{display:flex;gap:10px;margin-top:16px;flex-wrap:wrap}
.days-left{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:600}
.days-ok{background:rgba(5,150,105,.1);color:var(--green)}.days-ready{background:rgba(220,38,38,.1);color:var(--red)}
.warn-box{background:#FFFBEB;border:1px solid #FDE68A;border-radius:12px;padding:12px 16px;margin-bottom:20px;font-size:13px;color:#92400E;display:flex;align-items:center;gap:10px}
</style>
</head>
<body>

<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">
  <header class="topbar">
    <span class="topbar-title">🗑️ Thùng rác tài khoản</span>
    <div class="topbar-right">
      <a href="${pageContext.request.contextPath}/accounts" class="topbar-user" style="font-size:13px;font-weight:500;color:var(--muted);text-decoration:none;padding:6px 12px;border:1.5px solid var(--border);border-radius:8px;">← Danh sách</a>
      <div class="topbar-user">
        <div class="topbar-av"><%= initials %></div>
        <span class="topbar-name"><%= fullName %></span>
      </div>
    </div>
  </header>

  <div class="content">
    <div class="page-head">
      <div>
        <div class="breadcrumb">medicare › Quản lý › Tài khoản › Thùng rác</div>
        <h1>🗑️ Thùng rác</h1>
      </div>
      <a href="${pageContext.request.contextPath}/accounts" class="btn-back">← Quay lại danh sách</a>
    </div>

    <div class="info-banner">
      ⚠️ Tài khoản trong thùng rác sẽ bị <strong>xóa vĩnh viễn sau 30 ngày</strong> kể từ ngày xóa. Có thể khôi phục trước khi hết hạn.
    </div>

    <div class="card">
      <div class="card-head">
        <div>
          <div class="card-title">Tài khoản đã xóa</div>
          <div class="card-sub"><%= deletedList.size() %> tài khoản trong thùng rác</div>
        </div>
      </div>

      <div class="tbl-wrap" style="overflow-x:auto">
        <table class="tbl">
          <thead>
            <tr>
              <th>#</th>
              <th>Nhân viên</th>
              <th>Email</th>
              <th>Chức vụ</th>
              <th>Ngày xóa</th>
              <th>Còn lại</th>
              <th>Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <% if (deletedList.isEmpty()) { %>
            <tr><td colspan="7">
              <div class="empty">
                <div class="ei">✅</div>
                <div style="font-weight:600;margin-bottom:6px">Thùng rác trống</div>
                <div style="font-size:13px">Không có tài khoản nào bị xóa</div>
              </div>
            </td></tr>
            <% } else { %>
            <% int idx = 0; for (com.medicare.entity.Account a : deletedList) { idx++;
                String av2 = a.getFullName() != null && a.getFullName().length() >= 2
                    ? a.getFullName().substring(0,1).toUpperCase()+a.getFullName().substring(1,2).toUpperCase()
                    : (a.getUsername() != null ? a.getUsername().substring(0,1).toUpperCase() : "?");
                String roleName = a.getRoleId()==1?"Admin":a.getRoleId()==2?"Dược sĩ":"Thủ kho";
                // Tính số ngày đã xóa
                long daysDeleted = 0;
                boolean canPurge = false;
                String deletedAtStr = "—";
                if (a.getDeletedAt() != null) {
                    daysDeleted = java.time.temporal.ChronoUnit.DAYS.between(
                        a.getDeletedAt().toLocalDate(), java.time.LocalDate.now());
                    canPurge = daysDeleted >= 30;
                    deletedAtStr = a.getDeletedAt().toLocalDate().toString();
                }
                long daysLeft = Math.max(0, 30 - daysDeleted);
            %>
            <tr>
              <td style="color:var(--muted);font-size:12px"><%= idx %></td>
              <td>
                <div class="cell-user">
                  <div class="av"><%= av2 %></div>
                  <div>
                    <div class="cell-name"><%= a.getFullName() != null ? a.getFullName() : "—" %></div>
                    <div class="cell-sub">@<%= a.getUsername() %></div>
                  </div>
                </div>
              </td>
              <td style="color:var(--muted);font-size:13px"><%= a.getEmail() != null ? a.getEmail() : "—" %></td>
              <td><span style="font-size:12px;font-weight:600;color:var(--muted)"><%= roleName %></span></td>
              <td style="font-size:12.5px;color:var(--muted)"><%= deletedAtStr %></td>
              <td>
                <% if (canPurge) { %>
                <span class="days-left days-ready">Có thể xóa vĩnh viễn</span>
                <% } else { %>
                <span class="days-left days-ok"><%= daysLeft %> ngày</span>
                <% } %>
              </td>
              <td onclick="event.stopPropagation()">
                <div class="act-group">
                  <a href="${pageContext.request.contextPath}/accounts?action=restore&id=<%= a.getAccountId() %>"
                     class="act-btn act-restore"
                     onclick="return confirm('Khôi phục tài khoản @<%= a.getUsername() %>?')">
                    ↩️ Khôi phục
                  </a>
                  <%-- Cả 2 trường hợp (đủ/chưa đủ 30 ngày) đều vào cùng 1 flow: nhập "delete" → OTP --%>
                  <a href="${pageContext.request.contextPath}/accounts?action=purge&id=<%= a.getAccountId() %>"
                     class="act-btn act-purge">
                    🗑️ Xóa ngay
                  </a>
                </div>
              </td>
            </tr>
            <% } } %>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</div>

<% if ("restored".equals(msg)) { %><div class="toast toast-ok">↩️ Đã khôi phục tài khoản thành công!</div>
<% } else if ("purged".equals(msg)) { %><div class="toast toast-ok">🗑️ Đã xóa vĩnh viễn!</div>
<% } else if ("force-purged".equals(msg)) { %><div class="toast toast-ok" style="background:#c0392b">⚠️ Đã xóa vĩnh viễn ngay lập tức!</div>
<% } else if ("not-ready".equals(msg)) { %><div class="toast toast-warn">⏱️ Chưa đủ 30 ngày, chưa thể xóa vĩnh viễn!</div>
<% } else if ("not-found".equals(msg)) { %><div class="toast toast-warn">❌ Không tìm thấy tài khoản để xóa!</div>
<% } %>

<script>
const t = document.querySelector('.toast');
if (t) setTimeout(() => { t.style.opacity='0'; t.style.transition='opacity .4s'; setTimeout(()=>t.remove(),400); }, 3000);
</script>
</body>
</html>
