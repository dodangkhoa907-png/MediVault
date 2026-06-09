<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%
    // AuthFilter đã đảm bảo staffAccount tồn tại
    // Lấy uid từ param hoặc session attribute
    String _staffUid = request.getParameter("uid");
    if (_staffUid != null && !_staffUid.isEmpty()) {
    } else {
        _staffUid = (String) session.getAttribute("staffUid");
    }
    if (_staffUid == null) _staffUid = "";
    com.medivault.entity.Account acc = (com.medivault.entity.Account) session.getAttribute("staffAccount_" + request.getAttribute("staffUid"));
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/staff-login"); return; }
    if (acc.getRoleId() == 1) { response.sendRedirect(request.getContextPath() + "/dashboard"); return; }

    // Trang này chỉ hiển thị thông tin của chính staff đang login
    // "a" = chính acc (không cần truyền qua request.getAttribute)
    com.medivault.entity.Account a = acc;

    java.lang.String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    java.lang.String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();

    java.lang.String dn = (a.getFullName() != null && !a.getFullName().isEmpty()) ? a.getFullName() : a.getUsername();
    java.lang.String av = dn.length() >= 2
        ? dn.substring(0,1).toUpperCase() + dn.substring(1,2).toUpperCase()
        : dn.toUpperCase();
    java.lang.String roleName  = a.getRoleId()==2 ? "Dược sĩ bán hàng" : "Thủ kho";
    java.lang.String roleColor = a.getRoleId()==2 ? "#114C7D" : "#b8750a";
    java.lang.String roleBg    = a.getRoleId()==2 ? "rgba(70,202,244,.12)" : "rgba(252,218,124,.2)";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta name="ctx" content="${pageContext.request.contextPath}">
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title><%= dn %> — Hồ sơ cá nhân — MediVault</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&family=DM+Serif+Display:ital@0;1&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#12082A;--dp:#1C0F3F;--mid:#2D1B69;--main:#6D28D9;
  --light:#A78BFA;--soft:#F5F3FF;--white:#fff;
  --muted:#7C6FAA;--border:#E2DCF5;--surface:#FAFAFA;
  --green:#059669;--red:#DC2626;--gold:#D97706;--sidebar:228px;
}
html,body{height:100%;font-family:'Outfit',sans-serif}
body{display:flex;background:var(--soft);color:var(--ink)}

.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#0E0520 0%,#1C0F3F 45%,#3B1FA0 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 24px rgba(0,0,0,.2)}
.sidebar::after{content:'';position:absolute;top:0;right:0;bottom:0;width:1px;background:linear-gradient(180deg,transparent,rgba(167,139,250,.15) 30%,rgba(167,139,250,.15) 70%,transparent)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-icon{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,var(--light),var(--main));display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;box-shadow:0 4px 16px rgba(109,40,217,.4)}
.logo-text{font-family:'Outfit',sans-serif;font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-text span{color:var(--light)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:12px 0 4px;flex-shrink:0}
.nav-label{font-size:9px;font-weight:700;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:500;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(167,139,250,.15);font-weight:600}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--light);border-radius:2px}
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06);flex-shrink:0}
.user-card{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08)}
.user-av{width:34px;height:34px;flex-shrink:0;border-radius:9px;background:linear-gradient(135deg,var(--light),var(--main));display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:800;color:#fff}
.user-name{font-size:12.5px;font-weight:600;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:108px}
.user-role{font-size:10px;color:rgba(255,255,255,.35);margin-top:1px}
.logout-btn{margin-left:auto;width:28px;height:28px;flex-shrink:0;border-radius:8px;background:rgba(220,38,38,.12);border:none;display:flex;align-items:center;justify-content:center;color:rgba(220,38,38,.7);font-size:13px;cursor:pointer;text-decoration:none;transition:all .18s}
.logout-btn:hover{background:rgba(220,38,38,.2);color:#DC2626}

.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding: 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'DM Serif Display',serif;font-size:16px;color:var(--ink)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px;flex-shrink:0}
.back-btn{display:inline-flex;align-items:center;gap:6px;padding:7px 14px;background:var(--soft);border:1.5px solid var(--border);border-radius:20px;font-size:13px;font-weight:600;color:var(--muted);text-decoration:none;transition:all .18s}
.back-btn:hover{border-color:var(--light);color:var(--main)}

.content{padding:26px 28px;flex:1}
.page-head{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:22px}
.breadcrumb{font-size:11.5px;color:var(--muted);font-weight:500;margin-bottom:4px}
.page-head h1{font-family:'DM Serif Display',serif;font-size:26px;color:var(--ink)}

/* Layout grid */
.detail-grid{display:grid;grid-template-columns:280px 1fr;gap:20px;align-items:start}

/* Profile card */
.profile-card{background:var(--white);border:1px solid var(--border);border-radius:20px;overflow:hidden;position:sticky;top:78px}
.profile-banner{height:80px;background:linear-gradient(135deg,#1C0F3F,#3B1FA0,#6D28D9)}
.profile-body{padding:0 22px 22px;text-align:center}
.profile-av-wrap{position:relative;display:inline-block;margin-top:-28px;margin-bottom:10px}
.profile-av{width:56px;height:56px;border-radius:15px;background:linear-gradient(135deg,var(--light),var(--main));display:flex;align-items:center;justify-content:center;font-family:'DM Serif Display',serif;font-size:22px;color:#fff;border:3px solid var(--white);box-shadow:0 4px 16px rgba(109,40,217,.3);overflow:hidden}
.profile-av-badge{position:absolute;bottom:-3px;right:-3px;width:18px;height:18px;border-radius:50%;background:var(--green);border:2px solid var(--white);display:flex;align-items:center;justify-content:center;font-size:9px;color:#fff;font-weight:800}
.profile-name{font-family:'DM Serif Display',serif;font-size:18px;color:var(--ink);margin-bottom:2px}
.profile-username{font-size:12.5px;color:var(--muted);margin-bottom:8px}
.profile-role{display:inline-flex;align-items:center;gap:5px;padding:4px 12px;border-radius:20px;font-size:12px;font-weight:600;background:rgba(109,40,217,.1);color:var(--main);margin-bottom:6px}
.profile-status{font-size:12px;color:var(--green);font-weight:500}
.profile-divider{height:1px;background:var(--border);margin:14px 0}
.profile-meta{display:flex;flex-direction:column;gap:10px;text-align:left}
.meta-row{display:flex;align-items:flex-start;gap:10px}
.meta-icon{font-size:14px;margin-top:1px;flex-shrink:0;opacity:.7}
.meta-lbl{font-size:10.5px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:var(--muted)}
.meta-val{font-size:13px;font-weight:500;color:var(--ink);margin-top:1px;word-break:break-all}

/* Info columns */
.info-col{display:flex;flex-direction:column;gap:16px}
.info-card{background:var(--white);border:1px solid var(--border);border-radius:18px;overflow:hidden}
.info-card-head{display:flex;align-items:center;gap:10px;padding:16px 20px;border-bottom:1px solid var(--border);background:linear-gradient(135deg,#FAFAFA,var(--soft))}
.info-card-icon{width:32px;height:32px;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:15px;flex-shrink:0}
.ici-purple{background:rgba(109,40,217,.1)}
.ici-green{background:rgba(5,150,105,.1)}
.ici-gold{background:rgba(217,119,6,.1)}
.info-card-title{font-family:'DM Serif Display',serif;font-size:15px;color:var(--ink)}
.info-grid{display:grid;grid-template-columns:1fr 1fr;gap:0}
.info-field{padding:13px 20px;border-bottom:1px solid #F8F7FF}
.info-field:nth-last-child(-n+2){border-bottom:none}
.info-field.full{grid-column:1/-1}
.field-lbl{font-size:10.5px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:4px}
.field-val{font-size:13.5px;font-weight:500;color:var(--ink)}
.field-val.empty{color:var(--muted);font-style:italic;font-weight:400}

/* Badges */
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:600}
.b-blue{background:rgba(21,88,168,.1);color:#1558A8}
.b-gold{background:rgba(217,119,6,.1);color:var(--gold)}
.b-green{background:rgba(5,150,105,.1);color:var(--green)}
.b-gray{background:#F1F5F9;color:#64748B}

@keyframes fadeUp{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)}}
.profile-card{animation:fadeUp .4s ease both}
.info-card:nth-child(1){animation:fadeUp .4s .06s ease both}
.info-card:nth-child(2){animation:fadeUp .4s .12s ease both}
.info-card:nth-child(3){animation:fadeUp .4s .18s ease both}

/* ── PHOTO VIEW SECTION (staff - xem only) ── */
.photo-view-section{margin-top:14px;border-top:1px solid var(--border);padding-top:14px}
.photo-view-label{font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);margin-bottom:10px;text-align:center}
.photo-view-frame{
  width:88px;height:88px;border-radius:50%;overflow:hidden;
  border:3px solid var(--border);margin:0 auto;
  background:linear-gradient(135deg,#F0EBF8,#EDE9FE);
  display:flex;align-items:center;justify-content:center;
  box-shadow:0 3px 14px rgba(109,40,217,.1);
}
.photo-view-frame img{width:100%;height:100%;object-fit:cover}
.photo-view-placeholder{font-size:26px;opacity:.3}
.photo-view-note{text-align:center;font-size:11px;color:var(--muted);margin-top:7px;font-style:italic}
</style>
</head>
<body>
<%@ include file="/WEB-INF/views/loading.jsp" %>

<!-- SIDEBAR -->
<aside class="sidebar">
  <div class="sidebar-logo">
    <div class="logo-icon">💊</div>
    <div>
      <div class="logo-text">Medi<span>Vault</span></div>
      <div class="logo-sub">Staff Portal</div>
    </div>
  </div>
  <nav class="nav-section">
    <div class="nav-label">Tổng quan</div>
    <a href="<%= request.getContextPath() %>/staff-dashboard" class="nav-item"><span>🏠</span> Trang chủ</a>
  </nav>
  <nav class="nav-section">
    <div class="nav-label">Cá nhân</div>
    <a href="<%= request.getContextPath() %>/staff-profile" class="nav-item active"><span>👤</span> Hồ sơ của tôi</a>
    <a href="#" class="nav-item"><span>📅</span> Ca làm việc</a>
    <a href="#" class="nav-item"><span>📈</span> Tiến độ hôm nay</a>
  </nav>
  <nav class="nav-section">
    <div class="nav-label">Bán hàng</div>
    <a href="<%= request.getContextPath() %>/pos" class="nav-item"><span>🛒</span> Bán thuốc (POS)</a>
  </nav>
  <div style="flex:1"></div>
  <div class="sidebar-footer">
    <div class="user-card">
      <div class="user-av"><%= initials %></div>
      <div>
        <div class="user-name"><%= dn %></div>
        <div class="user-role"><%= roleName %></div>
      </div>
      <a href="<%= request.getContextPath() %>/logout?from=staff" class="logout-btn" title="Đăng xuất">⏻</a>
    </div>
  </div>
</aside>

<!-- MAIN -->
<div class="main">
  <header class="topbar">
    <div class="topbar-title">👤 Hồ sơ cá nhân</div>
    <div class="topbar-right">
      <a href="<%= request.getContextPath() %>/staff-dashboard" class="back-btn">← Quay lại Dashboard</a>
    </div>
  </header>

  <div class="content">
    <div class="page-head">
      <div>
        <div class="breadcrumb">MediVault › Hồ sơ cá nhân</div>
        <h1>Thông tin của tôi</h1>
      </div>
    </div>

    <div class="detail-grid">

      <!-- PROFILE CARD -->
      <div class="profile-card">
        <div class="profile-banner"></div>
        <div class="profile-body">
          <div class="profile-av-wrap">
            <div class="profile-av"><%= av %></div>
            <div class="profile-av-badge"><%= a.isActive() ? "✓" : "✗" %></div>
          </div>
          <div class="profile-name"><%= dn %></div>
          <div class="profile-username">@<%= a.getUsername() %></div>
          <div class="profile-role"><%= roleName %></div>
          <div class="profile-status"><%= a.isActive() ? "Đang hoạt động" : "Tài khoản bị khóa" %></div>

          <div class="profile-divider"></div>
          <div class="profile-meta">
            <% if (a.getEmail() != null && !a.getEmail().isEmpty()) { %>
            <div class="meta-row">
              <div class="meta-icon">✉️</div>
              <div><div class="meta-lbl">Email</div><div class="meta-val"><%= a.getEmail() %></div></div>
            </div>
            <% } %>
            <% if (a.getPhone() != null && !a.getPhone().isEmpty()) { %>
            <div class="meta-row">
              <div class="meta-icon">📱</div>
              <div><div class="meta-lbl">Điện thoại</div><div class="meta-val"><%= a.getPhone() %></div></div>
            </div>
            <% } %>
            <% if (a.getPosition() != null && !a.getPosition().isEmpty()) { %>
            <div class="meta-row">
              <div class="meta-icon">🏷️</div>
              <div><div class="meta-lbl">Chức vụ</div><div class="meta-val"><%= a.getPosition() %></div></div>
            </div>
            <% } %>
          </div>

          <!-- ── ẢNH CHÂN DUNG / CCCD (view only) ── -->
          <div class="photo-view-section">
            <div class="photo-view-label">📷 Ảnh chân dung / CCCD</div>
            <div class="photo-view-frame">
              <% if (a.getFaceEnrollmentPath() != null && !a.getFaceEnrollmentPath().isEmpty()) { %>
                <img src="<%= request.getContextPath() %>/<%= a.getFaceEnrollmentPath() %>" alt="<%= dn %>">
              <% } else { %>
                <div class="photo-view-placeholder">👤</div>
              <% } %>
            </div>
            <div class="photo-view-note">
              <% if (a.getFaceEnrollmentPath() != null && !a.getFaceEnrollmentPath().isEmpty()) { %>
                Ảnh đã đăng ký · Liên hệ admin để cập nhật
              <% } else { %>
                Chưa có ảnh · Liên hệ admin để cập nhật
              <% } %>
            </div>
          </div>

        </div>
      </div>

      <!-- INFO COLUMNS -->
      <div class="info-col">

        <!-- Thông tin cơ bản -->
        <div class="info-card">
          <div class="info-card-head">
            <div class="info-card-icon ici-purple">👤</div>
            <div class="info-card-title">Thông tin cơ bản</div>
          </div>
          <div class="info-grid">
            <div class="info-field">
              <div class="field-lbl">Họ và tên</div>
              <div class="field-val"><%= dn %></div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Tên đăng nhập</div>
              <div class="field-val">@<%= a.getUsername() %></div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Email</div>
              <div class="field-val <%= (a.getEmail()==null||a.getEmail().isEmpty())?"empty":"" %>">
                <%= (a.getEmail()!=null&&!a.getEmail().isEmpty()) ? a.getEmail() : "Chưa cập nhật" %>
              </div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Số điện thoại</div>
              <div class="field-val <%= (a.getPhone()==null||a.getPhone().isEmpty())?"empty":"" %>">
                <%= (a.getPhone()!=null&&!a.getPhone().isEmpty()) ? a.getPhone() : "Chưa cập nhật" %>
              </div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Số CCCD / CMND</div>
              <div class="field-val <%= (a.getCitizenId()==null||a.getCitizenId().isEmpty())?"empty":"" %>">
                <%= (a.getCitizenId()!=null&&!a.getCitizenId().isEmpty()) ? a.getCitizenId() : "Chưa cập nhật" %>
              </div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Chức vụ / Bộ phận</div>
              <div class="field-val <%= (a.getPosition()==null||a.getPosition().isEmpty())?"empty":"" %>">
                <%= (a.getPosition()!=null&&!a.getPosition().isEmpty()) ? a.getPosition() : "Chưa cập nhật" %>
              </div>
            </div>
          </div>
        </div>

        <!-- Thông tin chuyên môn -->
        <div class="info-card">
          <div class="info-card-head">
            <div class="info-card-icon ici-green">🎓</div>
            <div class="info-card-title">Thông tin chuyên môn</div>
          </div>
          <div class="info-grid">
            <div class="info-field">
              <div class="field-lbl">Số chứng chỉ hành nghề</div>
              <div class="field-val <%= (a.getProfessionalCertNo()==null||a.getProfessionalCertNo().isEmpty())?"empty":"" %>">
                <%= (a.getProfessionalCertNo()!=null&&!a.getProfessionalCertNo().isEmpty()) ? a.getProfessionalCertNo() : "Chưa cập nhật" %>
              </div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Phân quyền hệ thống</div>
              <div class="field-val">
                <% if (a.getRoleId()==2) { %><span class="badge b-blue">💊 Dược sĩ bán hàng</span>
                <% } else { %><span class="badge b-gold">📦 Thủ kho</span><% } %>
              </div>
            </div>
          </div>
        </div>

        <!-- Trạng thái tài khoản -->
        <div class="info-card">
          <div class="info-card-head">
            <div class="info-card-icon ici-gold">⚙️</div>
            <div class="info-card-title">Trạng thái tài khoản</div>
          </div>
          <div class="info-grid">
            <div class="info-field">
              <div class="field-lbl">Trạng thái</div>
              <div class="field-val">
                <%= a.isActive()
                    ? "<span class='badge b-green'>● Đang hoạt động</span>"
                    : "<span class='badge b-gray'>● Đã khóa</span>" %>
              </div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Account ID</div>
              <div class="field-val">#<%= a.getAccountId() %></div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Ngày tạo tài khoản</div>
              <div class="field-val">
                <%= a.getCreatedAt() != null
                    ? a.getCreatedAt().getDayOfMonth()+"/"+a.getCreatedAt().getMonthValue()+"/"+a.getCreatedAt().getYear()
                    : "—" %>
              </div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Lần đăng nhập cuối</div>
              <div class="field-val">
                <%= a.getLastLoginAt() != null
                    ? a.getLastLoginAt().getDayOfMonth()+"/"+a.getLastLoginAt().getMonthValue()+"/"+a.getLastLoginAt().getYear()
                      +" "+a.getLastLoginAt().getHour()+":"+(a.getLastLoginAt().getMinute()<10?"0":"")+a.getLastLoginAt().getMinute()
                    : "<span class='field-val empty'>Chưa đăng nhập</span>" %>
              </div>
            </div>
          </div>
        </div>

      </div><%-- /info-col --%>
    </div><%-- /detail-grid --%>
  </div>
</div>

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

  window.addEventListener('beforeunload', function() {
      const uid   = sessionStorage.getItem('staffUid');
      const ctx   = document.querySelector('meta[name="ctx"]')?.content || '';
      if (uid) {
          navigator.sendBeacon(ctx + '/logout?from=staff&uid=' + uid);
      }
  });

  const uid   = sessionStorage.getItem('staffUid');
  const token = sessionStorage.getItem('staffToken');
  const tabId = sessionStorage.getItem('tabId');

  if (!uid || !token) return; // chưa có token → không ping (lần đầu chưa login xong)

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
