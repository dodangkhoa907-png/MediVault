<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%
    com.medivault.entity.Account acc = (com.medivault.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    if (acc.getRoleId() != 1) { response.sendRedirect(request.getContextPath() + "/dashboard"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
    String msg = request.getParameter("msg");
    java.util.List<com.medivault.entity.Account> deletedList =
        (java.util.List<com.medivault.entity.Account>) request.getAttribute("deletedAccounts");
    if (deletedList == null) deletedList = new java.util.ArrayList<>();
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Thùng rác tài khoản — MediVault</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@700;800;900&family=Plus+Jakarta+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --navy:#101A33;--navy2:#1D2D50;--blue:#114C7D;--sky:#46CAF4;
  --surface:#F0F4F9;--border:#DDE6F0;--muted:#6B82A0;--white:#fff;
  --green:#1a7a4a;--red:#e74c3c;--gold:#b8750a;--sidebar:220px;
}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif}
body{display:flex;background:var(--surface);color:var(--navy)}
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(180deg,var(--navy) 0%,#182845 55%,var(--blue) 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100}
.sidebar-logo{padding:20px 18px 18px;display:flex;align-items:center;gap:10px;border-bottom:1px solid rgba(255,255,255,.07)}
.logo-icon{width:38px;height:38px;background:rgba(70,202,244,.15);border:1.5px solid rgba(70,202,244,.3);border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:18px}
.logo-text{font-family:'Nunito',sans-serif;font-size:17px;font-weight:900;color:#fff;letter-spacing:-.3px;line-height:1.1}
.logo-text span{color:var(--sky)}
.logo-sub{font-size:9.5px;color:rgba(255,255,255,.35);letter-spacing:1px;text-transform:uppercase}
.nav-section{padding:16px 0 8px}
.nav-label{font-size:9px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:rgba(255,255,255,.25);padding:0 18px 8px}
.nav-item{display:flex;align-items:center;gap:10px;padding:10px 18px;margin:1px 8px;border-radius:10px;font-size:13px;font-weight:500;color:rgba(255,255,255,.55);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:#fff;background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(70,202,244,.13);font-weight:600}
.nav-item.active::before{content:'';position:absolute;left:-8px;top:50%;transform:translateY(-50%);width:3px;height:60%;background:var(--sky);border-radius:4px}
.sidebar-footer{margin-top:auto;padding:16px 18px;border-top:1px solid rgba(255,255,255,.07)}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:8px 10px;border-radius:10px;background:rgba(255,255,255,.05)}
.user-av{width:32px;height:32px;background:linear-gradient(135deg,var(--sky),var(--blue));border-radius:8px;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff;flex-shrink:0}
.user-name{font-size:12.5px;font-weight:600;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:110px}
.user-role{font-size:10.5px;color:rgba(255,255,255,.35)}
.logout-btn{margin-left:auto;color:rgba(255,255,255,.3);text-decoration:none;font-size:13px;transition:color .15s}
.logout-btn:hover{color:var(--red)}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0;overflow-x:hidden}
.topbar{height:60px;background:#fff;border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:16px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Nunito',sans-serif;font-size:16px;font-weight:800;color:var(--navy)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:8px}
.topbar-user{display:flex;align-items:center;gap:8px;padding:4px 10px;border:1.5px solid var(--border);border-radius:10px;text-decoration:none;color:inherit}
.topbar-av{width:28px;height:28px;background:linear-gradient(135deg,var(--sky),var(--blue));border-radius:7px;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;color:#fff}
.topbar-name{font-size:13px;font-weight:600;color:var(--navy);max-width:120px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.content{padding:28px;flex:1;min-width:0;overflow-x:auto}
.page-head{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:24px}
.breadcrumb{font-size:11.5px;color:var(--muted);font-weight:500;margin-bottom:4px}
.page-head h1{font-family:'Nunito',sans-serif;font-size:24px;font-weight:900;letter-spacing:-.4px}
.btn-back{display:inline-flex;align-items:center;gap:7px;padding:10px 20px;background:#fff;color:var(--navy);border:1.5px solid var(--border);border-radius:10px;font-size:13.5px;font-weight:600;font-family:inherit;cursor:pointer;text-decoration:none;transition:all .2s}
.btn-back:hover{border-color:var(--blue);color:var(--blue)}
.card{background:#fff;border:1px solid var(--border);border-radius:16px;overflow:hidden}
.card-head{display:flex;align-items:center;justify-content:space-between;padding:18px 22px 14px;border-bottom:1px solid var(--border)}
.card-title{font-family:'Nunito',sans-serif;font-size:16px;font-weight:800;color:var(--navy)}
.card-sub{font-size:12px;color:var(--muted)}
.tbl{width:100%;border-collapse:collapse}
.tbl thead{background:#fff5f5}
.tbl th{padding:11px 16px;text-align:left;font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.6px;border-bottom:1px solid var(--border);white-space:nowrap}
.tbl td{padding:12px 16px;font-size:13.5px;border-bottom:1px solid #f0f4f9;vertical-align:middle}
.tbl tr:last-child td{border-bottom:none}
.tbl tbody tr{transition:background .12s}
.tbl tbody tr:hover{background:#fff8f8}
.cell-user{display:flex;align-items:center;gap:10px}
.av{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,#fca5a5,#dc2626);display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff;flex-shrink:0;opacity:.6}
.cell-name{font-weight:600;color:var(--navy);font-size:13.5px;opacity:.7}
.cell-sub{font-size:11.5px;color:var(--muted)}
.act-group{display:flex;gap:6px}
.act-btn{height:30px;padding:0 12px;border-radius:7px;border:1.5px solid;font-size:12px;font-weight:600;cursor:pointer;text-decoration:none;display:inline-flex;align-items:center;gap:4px;transition:all .15s;font-family:inherit;white-space:nowrap}
.act-restore{border-color:#bbf7d0;color:var(--green);background:#f0fdf4}
.act-restore:hover{background:#dcfce7}
.act-purge{border-color:#fecaca;color:var(--red);background:#fff5f5}
.act-purge:hover{background:#fee2e2}
.empty{text-align:center;padding:60px;color:var(--muted)}
.empty .ei{font-size:40px;margin-bottom:12px}
.days-left{font-size:11px;font-weight:600;padding:2px 8px;border-radius:20px}
.days-ok{background:#fef9c3;color:#854d0e}
.days-ready{background:#fee2e2;color:#991b1b}
.toast{position:fixed;top:20px;right:24px;padding:12px 20px;border-radius:10px;font-size:13.5px;font-weight:600;display:flex;align-items:center;gap:8px;box-shadow:0 8px 32px rgba(0,0,0,.2);z-index:999;animation:toastIn .3s ease}
@keyframes toastIn{from{opacity:0;transform:translateY(-10px)}to{opacity:1;transform:translateY(0)}}
.toast-ok{background:#064e3b;color:#fff}
.toast-warn{background:#7f1d1d;color:#fff}
.info-banner{background:#fff8f0;border:1px solid #fed7aa;border-radius:12px;padding:14px 18px;margin-bottom:20px;font-size:13px;color:#9a3412;display:flex;align-items:center;gap:10px}
</style>
</head>
<body>

<aside class="sidebar">
  <div class="sidebar-logo">
    <div class="logo-icon">💊</div>
    <div>
      <div class="logo-text">Medi<span>Vault</span></div>
      <div class="logo-sub">Admin Console</div>
    </div>
  </div>
  <nav class="nav-section">
    <div class="nav-label">Tổng quan</div>
    <a href="${pageContext.request.contextPath}/dashboard" class="nav-item"><span>🏠</span> Trang chủ</a>
  </nav>
  <nav class="nav-section">
    <div class="nav-label">Quản lý</div>
    <a href="${pageContext.request.contextPath}/accounts" class="nav-item active"><span>👤</span> Tài khoản</a>
    <a href="${pageContext.request.contextPath}/shifts" class="nav-item"><span>🕐</span> Ca làm việc</a>
    <a href="${pageContext.request.contextPath}/medicines" class="nav-item"><span>💊</span> Kho thuốc</a>
    <a href="${pageContext.request.contextPath}/invoices" class="nav-item"><span>🧾</span> Hóa đơn</a>
    <a href="${pageContext.request.contextPath}/customers" class="nav-item"><span>👥</span> Khách hàng</a>
  </nav>
  <nav class="nav-section">
    <div class="nav-label">Phân tích</div>
    <a href="${pageContext.request.contextPath}/reports" class="nav-item"><span>📊</span> Báo cáo</a>
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
        <div class="breadcrumb">MediVault › Quản lý › Tài khoản › Thùng rác</div>
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
            <% int idx = 0; for (com.medivault.entity.Account a : deletedList) { idx++;
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
                  <% if (canPurge) { %>
                  <a href="${pageContext.request.contextPath}/accounts?action=purge&id=<%= a.getAccountId() %>"
                     class="act-btn act-purge"
                     onclick="return confirm('XÓA VĨNH VIỄN @<%= a.getUsername() %>? Không thể hoàn tác!')">
                    🗑️ Xóa vĩnh viễn
                  </a>
                  <% } %>
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
<% } else if ("not-ready".equals(msg)) { %><div class="toast toast-warn">⏱️ Chưa đủ 30 ngày, chưa thể xóa vĩnh viễn!</div>
<% } %>

<script>
const t = document.querySelector('.toast');
if (t) setTimeout(() => { t.style.opacity='0'; t.style.transition='opacity .4s'; setTimeout(()=>t.remove(),400); }, 3000);
</script>
</body>
</html>
