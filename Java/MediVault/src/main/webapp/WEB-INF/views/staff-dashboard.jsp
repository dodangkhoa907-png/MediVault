<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    com.medivault.entity.Account acc = (com.medivault.entity.Account) session.getAttribute("staffAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/staff-login"); return; }
    if (acc.getRoleId() == 1) { response.sendRedirect(request.getContextPath() + "/dashboard"); return; }

    java.lang.String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    java.lang.String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
    java.lang.String roleName = acc.getRoleId() == 2 ? "Dược sĩ bán hàng" : "Thủ kho";
    java.lang.String roleIcon = acc.getRoleId() == 2 ? "💊" : "📦";

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
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>MediVault — <%= roleName %></title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@700;800;900&family=Plus+Jakarta+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --navy:#101A33;--blue:#114C7D;--sky:#46CAF4;
  --purple:#7C3AED;--purple-light:#A78BFA;--purple-soft:#EDE9FE;
  --surface:#F5F3FF;--border:#DDD6FE;--muted:#6B7280;--white:#fff;
  --green:#059669;--red:#DC2626;--gold:#D97706;
  --sidebar:220px;
}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif}
body{display:flex;background:var(--surface);color:var(--navy)}

/* ── SIDEBAR ── */
.sidebar{
  width:var(--sidebar);min-height:100vh;
  background:linear-gradient(180deg,#1E1035 0%,#2D1B69 50%,#4C1D95 100%);
  display:flex;flex-direction:column;
  position:fixed;left:0;top:0;bottom:0;z-index:100;
}
.sidebar-logo{
  height:60px;padding:0 18px;
  display:flex;align-items:center;gap:10px;
  border-bottom:1px solid rgba(255,255,255,.08);
}
.logo-icon{
  width:36px;height:36px;
  background:rgba(167,139,250,.2);
  border:1.5px solid rgba(167,139,250,.4);
  border-radius:10px;
  display:flex;align-items:center;justify-content:center;font-size:16px;
}
.logo-text{font-family:'Nunito',sans-serif;font-size:16px;font-weight:900;color:#fff;letter-spacing:-.3px;line-height:1.1}
.logo-text span{color:var(--purple-light)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.35);letter-spacing:1px;text-transform:uppercase}

.nav-section{padding:14px 0 6px}
.nav-label{font-size:9px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:rgba(255,255,255,.25);padding:0 18px 8px}
.nav-item{
  display:flex;align-items:center;gap:10px;
  padding:9px 18px;margin:1px 8px;border-radius:10px;
  font-size:13px;font-weight:500;color:rgba(255,255,255,.55);
  text-decoration:none;transition:all .18s;position:relative;
}
.nav-item:hover{color:#fff;background:rgba(255,255,255,.07)}
.nav-item.active{color:#fff;background:rgba(167,139,250,.18);font-weight:600}
.nav-item.active::before{
  content:'';position:absolute;left:-8px;top:50%;transform:translateY(-50%);
  width:3px;height:60%;background:var(--purple-light);border-radius:4px;
}
.nav-badge{
  margin-left:auto;background:#DC2626;color:#fff;
  font-size:10px;font-weight:700;padding:1px 6px;border-radius:10px;min-width:18px;text-align:center;
}

.sidebar-footer{margin-top:auto;padding:16px 18px;border-top:1px solid rgba(255,255,255,.07)}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:8px 10px;border-radius:10px;background:rgba(255,255,255,.06)}
.user-av{
  width:32px;height:32px;
  background:linear-gradient(135deg,var(--purple-light),var(--purple));
  border-radius:8px;display:flex;align-items:center;justify-content:center;
  font-size:12px;font-weight:800;color:#fff;flex-shrink:0;
}
.user-name{font-size:12px;font-weight:600;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:110px}
.user-role{font-size:10px;color:rgba(255,255,255,.4)}
.logout-btn{margin-left:auto;color:rgba(255,255,255,.3);text-decoration:none;font-size:14px;transition:color .15s}
.logout-btn:hover{color:#DC2626}

/* ── MAIN ── */
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0}

/* ── TOPBAR ── */
.topbar{
  height:60px;background:#fff;
  border-bottom:1px solid #EDE9FE;
  display:flex;align-items:center;padding: 28px;gap:16px;
  position:sticky;top:0;z-index:50;
}
.topbar-title{font-family:'Nunito',sans-serif;font-size:16px;font-weight:800;color:var(--navy)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px;flex-shrink:0}
.topbar-clock{
  display:flex;align-items:center;gap:5px;padding:5px 11px;
  background:var(--purple-soft);border:1.5px solid var(--border);border-radius:12px;
  font-size:13px;font-weight:700;font-style:italic;color:var(--purple);
}
.clock-sep{animation:blink 1s step-end infinite;font-style:normal}
@keyframes blink{0%,100%{opacity:1}50%{opacity:0}}
.clock-date{font-size:11px;font-weight:500;font-style:normal;color:var(--muted);border-left:1px solid var(--border);padding-left:8px;margin-left:2px}
.topbar-user{display:flex;align-items:center;gap:8px;padding:4px 10px;border:1.5px solid var(--border);border-radius:10px;text-decoration:none;color:inherit;transition:background .15s}
.topbar-user:hover{background:var(--purple-soft)}
.topbar-user-av{width:28px;height:28px;background:linear-gradient(135deg,var(--purple-light),var(--purple));border-radius:7px;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;color:#fff}
.topbar-user-name{font-size:13px;font-weight:600;color:var(--navy);max-width:120px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}

/* ── CONTENT ── */
.content{padding:28px;flex:1}
.page-head{margin-bottom:24px}
.breadcrumb{font-size:11.5px;color:var(--muted);margin-bottom:4px}
.page-head h1{font-family:'Nunito',sans-serif;font-size:24px;font-weight:900;letter-spacing:-.4px}
.page-head-sub{font-size:13px;color:var(--muted);margin-top:4px}

/* ── WELCOME BANNER ── */
.welcome-banner{
  background:linear-gradient(135deg,#1E1035 0%,#4C1D95 60%,#6D28D9 100%);
  border-radius:18px;padding:28px 32px;
  display:flex;align-items:center;gap:20px;
  margin-bottom:24px;color:#fff;
  position:relative;overflow:hidden;
}
.welcome-banner::before{
  content:'';position:absolute;top:-40px;right:-40px;
  width:200px;height:200px;
  background:rgba(167,139,250,.15);border-radius:50%;
}
.welcome-banner::after{
  content:'';position:absolute;bottom:-60px;right:80px;
  width:160px;height:160px;
  background:rgba(139,92,246,.1);border-radius:50%;
}
.welcome-av{
  width:56px;height:56px;
  background:rgba(255,255,255,.15);
  border:2px solid rgba(255,255,255,.3);
  border-radius:16px;display:flex;align-items:center;justify-content:center;
  font-size:22px;font-weight:800;flex-shrink:0;
}
.welcome-text h2{font-family:'Nunito',sans-serif;font-size:20px;font-weight:900;margin-bottom:4px}
.welcome-text p{font-size:13px;color:rgba(255,255,255,.7)}
.welcome-badge{
  margin-left:auto;
  background:rgba(255,255,255,.15);
  border:1px solid rgba(255,255,255,.2);
  border-radius:10px;padding:8px 14px;
  font-size:12px;font-weight:600;color:#fff;
  text-align:center;flex-shrink:0;
}
.welcome-badge .wb-icon{font-size:20px;display:block;margin-bottom:4px}

/* ── STAT CARDS ── */
.stats-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:16px;margin-bottom:24px}
.stat-card{
  background:#fff;border:1px solid var(--border);border-radius:16px;
  padding:20px 22px;display:flex;flex-direction:column;gap:10px;
  transition:box-shadow .2s,transform .2s;
}
.stat-card:hover{box-shadow:0 6px 24px rgba(124,58,237,.1);transform:translateY(-2px)}
.stat-top{display:flex;align-items:center;justify-content:space-between}
.stat-label{font-size:11.5px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.stat-icon{width:38px;height:38px;border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:17px}
.ic-purple{background:rgba(124,58,237,.1)}
.ic-green{background:rgba(5,150,105,.1)}
.ic-red{background:rgba(220,38,38,.1)}
.stat-value{font-family:'Nunito',sans-serif;font-size:28px;font-weight:900;color:var(--navy);letter-spacing:-.5px;line-height:1}
.stat-diff{font-size:12px;color:var(--muted)}

/* ── ACTION CARDS ── */
.actions-grid{display:grid;grid-template-columns:repeat(2,1fr);gap:16px;margin-bottom:24px}
.action-card{
  background:#fff;border:1px solid var(--border);border-radius:16px;
  padding:22px 24px;display:flex;align-items:center;gap:16px;
  text-decoration:none;color:inherit;
  transition:all .2s;cursor:pointer;
}
.action-card:hover{border-color:var(--purple-light);box-shadow:0 6px 24px rgba(124,58,237,.1);transform:translateY(-2px)}
.action-icon{
  width:52px;height:52px;border-radius:14px;
  display:flex;align-items:center;justify-content:center;font-size:22px;flex-shrink:0;
}
.ac-purple{background:linear-gradient(135deg,var(--purple-soft),#DDD6FE)}
.ac-green{background:linear-gradient(135deg,#DCFCE7,#BBF7D0)}
.ac-blue{background:linear-gradient(135deg,#DBEAFE,#BFDBFE)}
.ac-gold{background:linear-gradient(135deg,#FEF3C7,#FDE68A)}
.action-text h3{font-family:'Nunito',sans-serif;font-size:15px;font-weight:800;color:var(--navy);margin-bottom:3px}
.action-text p{font-size:12px;color:var(--muted)}
.action-arrow{margin-left:auto;font-size:18px;color:var(--purple-light);flex-shrink:0}

/* ── INFO CARD ── */
.info-row{display:grid;grid-template-columns:1fr 1fr;gap:16px}
.info-card{background:#fff;border:1px solid var(--border);border-radius:16px;overflow:hidden}
.info-card-head{padding:16px 20px 12px;border-bottom:1px solid #F3F4F6;background:#FAFAFA}
.info-card-title{font-family:'Nunito',sans-serif;font-size:14px;font-weight:800;color:var(--navy)}
.info-card-sub{font-size:12px;color:var(--muted);margin-top:2px}
.info-field{padding:12px 20px;border-bottom:1px solid #F9FAFB}
.info-field:last-child{border-bottom:none}
.field-lbl{font-size:11px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:3px}
.field-val{font-size:13.5px;font-weight:500;color:var(--navy)}
.field-val.empty{color:var(--muted);font-style:italic;font-weight:400}

.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:12px;font-weight:600}
.badge::before{content:'●';font-size:7px}
.b-purple{background:rgba(124,58,237,.1);color:var(--purple)}
.b-green{background:rgba(5,150,105,.1);color:var(--green)}
.b-blue{background:rgba(59,130,246,.1);color:#2563EB}

/* TOAST */
.toast{position:fixed;top:20px;right:24px;padding:12px 20px;border-radius:10px;font-size:13.5px;font-weight:600;display:flex;align-items:center;gap:8px;box-shadow:0 8px 32px rgba(0,0,0,.2);z-index:999;background:#1E1035;color:#fff}
</style>
</head>
<body>

<!-- ── SIDEBAR ── -->
<aside class="sidebar">
  <div class="sidebar-logo">
    <div class="logo-icon">💊</div>
    <div>
      <div class="logo-text">Medi<span>Vault</span></div>
      <div class="logo-sub"><%= roleName %></div>
    </div>
  </div>

  <nav class="nav-section">
    <div class="nav-label">Tổng quan</div>
    <a href="${pageContext.request.contextPath}/staff-dashboard" class="nav-item active">
      <span><%= roleIcon %></span> Trang chủ
    </a>
  </nav>

  <% if (acc.getRoleId() == 2) { %>
  <nav class="nav-section">
    <div class="nav-label">Bán hàng</div>
    <a href="${pageContext.request.contextPath}/pos" class="nav-item"><span>🛒</span> Bán thuốc (POS)</a>
    <a href="#" class="nav-item"><span>🧾</span> Hóa đơn của tôi</a>
    <a href="#" class="nav-item"><span>👥</span> Khách hàng</a>
  </nav>
  <% } else { %>
  <nav class="nav-section">
    <div class="nav-label">Kho hàng</div>
    <a href="#" class="nav-item"><span>📦</span> Quản lý kho</a>
    <a href="#" class="nav-item"><span>⚠️</span> Hàng sắp hết
      <% if (lowStock > 0) { %><span class="nav-badge"><%= lowStock %></span><% } %>
    </a>
    <a href="#" class="nav-item"><span>⏰</span> Sắp hết hạn
      <% if (expiryCount > 0) { %><span class="nav-badge"><%= expiryCount %></span><% } %>
    </a>
  </nav>
  <% } %>

  <nav class="nav-section">
    <div class="nav-label">Cá nhân</div>
    <a href="#" class="nav-item"><span>📅</span> Ca làm việc</a>
    <a href="${pageContext.request.contextPath}/staff-profile" class="nav-item">
      <span>👤</span> Hồ sơ của tôi
    </a>
  </nav>

  <div class="sidebar-footer">
    <div class="sidebar-user">
      <div class="user-av"><%= initials %></div>
      <div>
        <div class="user-name"><%= fullName %></div>
        <div class="user-role"><%= roleName %></div>
      </div>
      <a href="${pageContext.request.contextPath}/logout?from=staff" class="logout-btn" title="Đăng xuất">⏻</a>
    </div>
  </div>
</aside>

<!-- ── MAIN ── -->
<div class="main">
  <header class="topbar">
    <span class="topbar-title"><%= roleIcon %> <%= roleName %></span>
    <div class="topbar-right">
      <div class="topbar-clock">
        <span id="clockH">00</span><span class="clock-sep">:</span><span id="clockM">00</span>
        <span class="clock-date" id="clockDate"></span>
      </div>
      <a href="${pageContext.request.contextPath}/staff-profile" class="topbar-user">
        <div class="topbar-user-av"><%= initials %></div>
        <span class="topbar-user-name"><%= fullName %></span>
      </a>
    </div>
  </header>

  <div class="content">

    <!-- Welcome banner -->
    <div class="welcome-banner">
      <div class="welcome-av"><%= initials %></div>
      <div class="welcome-text">
        <h2>Chào <%= fullName %>! 👋</h2>
        <p>Chúc bạn làm việc hiệu quả hôm nay · <span id="welcomeDate"></span></p>
      </div>
      <div style="display:flex;flex-direction:column;gap:8px;flex-shrink:0">
        <a href="${pageContext.request.contextPath}/pos"
           style="display:inline-flex;align-items:center;gap:8px;padding:10px 18px;background:rgba(255,255,255,.15);border:1.5px solid rgba(255,255,255,.25);border-radius:12px;color:#fff;text-decoration:none;font-weight:800;font-size:14px;font-family:Nunito,sans-serif;transition:all .2s"
           onmouseover="this.style.background='rgba(255,255,255,.25)'"
           onmouseout="this.style.background='rgba(255,255,255,.15)'">
          🛒 Mở POS ngay →
        </a>
        <div class="welcome-badge">
          <span class="wb-icon"><%= roleIcon %></span>
          <%= roleName %>
        </div>
      </div>
    </div>

    <!-- Stats -->
    <div class="stats-grid">
      <div class="stat-card">
        <div class="stat-top">
          <span class="stat-label">Tổng thuốc trong kho</span>
          <div class="stat-icon ic-purple">💊</div>
        </div>
        <div class="stat-value"><%= totalMeds %></div>
        <div class="stat-diff">Mặt hàng đang kinh doanh</div>
      </div>
      <div class="stat-card">
        <div class="stat-top">
          <span class="stat-label">Sắp hết hạn</span>
          <div class="stat-icon ic-red">⏰</div>
        </div>
        <div class="stat-value"><%= expiryCount %></div>
        <div class="stat-diff"><%= expiryCount > 0 ? "⚠️ Cần xử lý sớm" : "✅ Không có" %></div>
      </div>
      <div class="stat-card">
        <div class="stat-top">
          <span class="stat-label">Tồn kho thấp</span>
          <div class="stat-icon ic-green">📦</div>
        </div>
        <div class="stat-value"><%= lowStock %></div>
        <div class="stat-diff"><%= lowStock > 0 ? "⚠️ Cần nhập thêm" : "✅ Đủ hàng" %></div>
      </div>
    </div>

    <!-- Quick actions -->
    <div class="actions-grid">
      <% if (acc.getRoleId() == 2) { %>
      <a href="${pageContext.request.contextPath}/pos" class="action-card" style="border-color:var(--purple-light);background:linear-gradient(135deg,#FAF5FF,#EDE9FE)">
        <div class="action-icon ac-purple">🛒</div>
        <div class="action-text">
          <h3>Bán thuốc (POS)</h3>
          <p>Mở giao diện bán hàng ngay</p>
        </div>
        <span class="action-arrow" style="color:var(--purple);font-size:20px">→</span>
      </a>
      <a href="#" class="action-card">
        <div class="action-icon ac-green">🧾</div>
        <div class="action-text">
          <h3>Hóa đơn hôm nay</h3>
          <p>Xem danh sách hóa đơn đã tạo</p>
        </div>
        <span class="action-arrow">→</span>
      </a>
      <a href="#" class="action-card">
        <div class="action-icon ac-blue">👥</div>
        <div class="action-text">
          <h3>Tra cứu khách hàng</h3>
          <p>Tìm kiếm thông tin khách hàng</p>
        </div>
        <span class="action-arrow">→</span>
      </a>
      <% } else { %>
      <a href="#" class="action-card">
        <div class="action-icon ac-purple">📦</div>
        <div class="action-text">
          <h3>Kiểm tra kho</h3>
          <p>Xem tồn kho và nhập hàng</p>
        </div>
        <span class="action-arrow">→</span>
      </a>
      <a href="#" class="action-card">
        <div class="action-icon ac-red" style="background:linear-gradient(135deg,#FEE2E2,#FECACA)">⚠️</div>
        <div class="action-text">
          <h3>Hàng sắp hết / hết hạn</h3>
          <p>Kiểm tra và xử lý hàng tồn</p>
        </div>
        <span class="action-arrow">→</span>
      </a>
      <a href="#" class="action-card">
        <div class="action-icon ac-blue">📋</div>
        <div class="action-text">
          <h3>Phiếu nhập kho</h3>
          <p>Tạo và quản lý phiếu nhập hàng</p>
        </div>
        <span class="action-arrow">→</span>
      </a>
      <% } %>
      <a href="#" class="action-card">
        <div class="action-icon ac-gold">📅</div>
        <div class="action-text">
          <h3>Ca làm việc của tôi</h3>
          <p>Xem lịch ca và chấm công</p>
        </div>
        <span class="action-arrow">→</span>
      </a>
    </div>

    <!-- Profile info -->
    <div class="info-row">
      <div class="info-card">
        <div class="info-card-head">
          <div class="info-card-title">👤 Thông tin cá nhân</div>
          <div class="info-card-sub">Hồ sơ của bạn</div>
        </div>
        <div class="info-field">
          <div class="field-lbl">Họ và tên</div>
          <div class="field-val"><%= fullName %></div>
        </div>
        <div class="info-field">
          <div class="field-lbl">Tên đăng nhập</div>
          <div class="field-val">@<%= acc.getUsername() %></div>
        </div>
        <div class="info-field">
          <div class="field-lbl">Email</div>
          <div class="field-val <%= acc.getEmail()==null?"empty":"" %>">
            <%= acc.getEmail()!=null ? acc.getEmail() : "Chưa cập nhật" %>
          </div>
        </div>
        <div class="info-field">
          <div class="field-lbl">Số điện thoại</div>
          <div class="field-val <%= acc.getPhone()==null?"empty":"" %>">
            <%= acc.getPhone()!=null ? acc.getPhone() : "Chưa cập nhật" %>
          </div>
        </div>
      </div>

      <div class="info-card">
        <div class="info-card-head">
          <div class="info-card-title">🎓 Thông tin công việc</div>
          <div class="info-card-sub">Phân quyền và chuyên môn</div>
        </div>
        <div class="info-field">
          <div class="field-lbl">Chức vụ</div>
          <div class="field-val">
            <span class="badge b-purple"><%= roleName %></span>
          </div>
        </div>
        <div class="info-field">
          <div class="field-lbl">Bộ phận / Vị trí</div>
          <div class="field-val <%= acc.getPosition()==null?"empty":"" %>">
            <%= acc.getPosition()!=null ? acc.getPosition() : "Chưa cập nhật" %>
          </div>
        </div>
        <div class="info-field">
          <div class="field-lbl">Số CCCD</div>
          <div class="field-val <%= acc.getCitizenId()==null?"empty":"" %>">
            <%= acc.getCitizenId()!=null ? acc.getCitizenId() : "Chưa cập nhật" %>
          </div>
        </div>
        <div class="info-field">
          <div class="field-lbl">Trạng thái</div>
          <div class="field-val">
            <span class="badge b-green">● Đang hoạt động</span>
          </div>
        </div>
      </div>
    </div>

  </div>
</div>

<script>
function updateClock() {
    const now = new Date();
    const h = now.getHours().toString().padStart(2,'0');
    const m = now.getMinutes().toString().padStart(2,'0');
    const days = ['CN','T2','T3','T4','T5','T6','T7'];
    const d = now.getDate().toString().padStart(2,'0');
    const mo = (now.getMonth()+1).toString().padStart(2,'0');
    document.getElementById('clockH').textContent = h;
    document.getElementById('clockM').textContent = m;
    document.getElementById('clockDate').textContent = days[now.getDay()] + ', ' + d + '/' + mo;
    if(document.getElementById('welcomeDate'))
        document.getElementById('welcomeDate').textContent =
            days[now.getDay()] + ' ' + d + '/' + mo + '/' + now.getFullYear();
}
updateClock(); setInterval(updateClock, 1000);
</script>
</body>
</html>
