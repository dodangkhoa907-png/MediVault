<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%
    com.medivault.entity.Account acc = (com.medivault.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    if (acc.getRoleId() != 1) { response.sendRedirect(request.getContextPath() + "/dashboard"); return; }

    com.medivault.entity.Account a = (com.medivault.entity.Account) request.getAttribute("account");
    if (a == null) { response.sendRedirect(request.getContextPath() + "/accounts"); return; }

    com.medivault.entity.PasswordResetRequest pendingReset =
        (com.medivault.entity.PasswordResetRequest) request.getAttribute("pendingReset");
    boolean hasPendingReset = pendingReset != null;

    java.lang.String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    java.lang.String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();

    java.lang.String dn = (a.getFullName() != null && !a.getFullName().isEmpty()) ? a.getFullName() : a.getUsername();
    java.lang.String av = dn.length() >= 2
        ? dn.substring(0,1).toUpperCase() + dn.substring(1,2).toUpperCase()
        : dn.toUpperCase();
    java.lang.String roleName = a.getRoleId()==1 ? "Admin" : a.getRoleId()==2 ? "Dược sĩ bán hàng" : "Thủ kho";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title><%= dn %> — Chi tiết — MediVault</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;--cyan-soft:#EBF8FD;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;--sidebar:232px;
}
html,body{height:100%;font-family:'Outfit',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}

/* ── SIDEBAR ── */
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
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Outfit',sans-serif;font-size:16px;color:var(--ink)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px;flex-shrink:0}
.back-btn{display:inline-flex;align-items:center;gap:6px;padding:7px 14px;background:var(--surface);border:1.5px solid var(--border);border-radius:20px;font-size:13px;font-weight:600;color:var(--muted);text-decoration:none;transition:all .18s}
.back-btn:hover{border-color:var(--cyan);color:var(--blue)}
.topbar-user{display:flex;align-items:center;gap:8px;padding:5px 12px 5px 7px;border:1.5px solid var(--border);border-radius:20px;text-decoration:none;color:inherit;transition:all .18s}
.topbar-user:hover{border-color:var(--cyan);background:var(--cyan-soft)}
.topbar-av{width:28px;height:28px;border-radius:8px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;color:#fff}
.topbar-name{font-size:13px;font-weight:600;color:var(--navy);max-width:110px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}

/* ── CONTENT ── */
.content{padding:26px 28px;flex:1}
.page-head{display:flex;align-items:center;justify-content:space-between;margin-bottom:24px}
.page-head-left .breadcrumb{font-size:11.5px;color:var(--muted);font-weight:500;margin-bottom:4px}
.page-head-left h1{font-family:'Outfit',sans-serif;font-size:28px;color:var(--ink)}
.head-actions{display:flex;gap:10px;align-items:center}

/* ── BUTTONS ── */
.btn-primary{display:inline-flex;align-items:center;gap:7px;padding:10px 20px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;cursor:pointer;text-decoration:none;transition:all .22s;box-shadow:0 4px 14px rgba(21,88,168,.22)}
.btn-primary:hover{transform:translateY(-1px);box-shadow:0 6px 20px rgba(21,88,168,.35)}
.btn-warn{display:inline-flex;align-items:center;gap:7px;padding:10px 20px;background:#fff;border:1.5px solid #FECACA;color:var(--red);border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;cursor:pointer;text-decoration:none;transition:all .18s}
.btn-warn:hover{background:#FEF2F2;border-color:var(--red)}

/* ── LAYOUT ── */
.detail-layout{display:grid;grid-template-columns:280px 1fr;gap:20px;align-items:start}

/* ── PROFILE CARD ── */
.profile-card{background:var(--white);border:1px solid var(--border);border-radius:20px;overflow:hidden;position:sticky;top:78px;box-shadow:0 4px 20px rgba(21,88,168,.06)}
.profile-banner{height:88px;background:linear-gradient(135deg,#071022 0%,#0F2645 50%,#1558A8 100%);position:relative}
.profile-banner::after{content:'';position:absolute;inset:0;background:radial-gradient(ellipse at 80% 50%,rgba(58,189,224,.2) 0%,transparent 70%)}
.profile-body{padding:0 22px 22px;text-align:center}

/* Avatar */
.profile-av-wrap{position:relative;display:inline-block;margin-top:-32px;margin-bottom:12px}
.profile-av{
  width:64px;height:64px;border-radius:16px;
  background:linear-gradient(135deg,var(--cyan),var(--blue));
  display:flex;align-items:center;justify-content:center;
  font-family:'Outfit',sans-serif;font-size:24px;color:#fff;
  border:3px solid var(--white);overflow:hidden;
  box-shadow:0 4px 20px rgba(21,88,168,.3);
}
.profile-av img{width:100%;height:100%;object-fit:cover}
.profile-av-status{
  position:absolute;bottom:-3px;right:-3px;
  width:20px;height:20px;border-radius:50%;border:2.5px solid var(--white);
  display:flex;align-items:center;justify-content:center;font-size:9px;font-weight:800;color:#fff;
}
.status-active{background:var(--green)}
.status-locked{background:var(--muted)}

/* Upload photo button */
.photo-upload-btn{
  display:flex;align-items:center;justify-content:center;gap:6px;
  width:100%;padding:8px 12px;margin-top:12px;
  background:var(--surface);border:1.5px dashed var(--border);border-radius:10px;
  font-family:'Outfit',sans-serif;font-size:12.5px;font-weight:600;color:var(--muted);
  cursor:pointer;transition:all .2s;text-decoration:none;
}
.photo-upload-btn:hover{border-color:var(--cyan);color:var(--blue);background:var(--cyan-soft)}
#photoInput{display:none}

.profile-name{font-family:'Outfit',sans-serif;font-size:18px;color:var(--ink);margin-bottom:2px}
.profile-username{font-size:12.5px;color:var(--muted);margin-bottom:8px}
.profile-role-badge{
  display:inline-flex;align-items:center;gap:5px;
  padding:4px 12px;border-radius:20px;font-size:12px;font-weight:600;margin-bottom:4px;
  white-space:nowrap;
}
.role-admin{background:rgba(220,38,38,.1);color:var(--red)}
.role-pharmacist{background:rgba(21,88,168,.1);color:var(--blue)}
.role-warehouse{background:rgba(217,119,6,.1);color:var(--gold)}
.profile-status-text{font-size:12px;font-weight:500}
.status-text-active{color:var(--green)}
.status-text-locked{color:var(--muted)}

.profile-divider{height:1px;background:var(--border);margin:14px 0}

.profile-meta{display:flex;flex-direction:column;gap:10px;text-align:left}
.meta-row{display:flex;align-items:flex-start;gap:10px}
.meta-icon{font-size:13px;flex-shrink:0;margin-top:1px;opacity:.6}
.meta-lbl{font-size:10px;font-weight:700;text-transform:uppercase;letter-spacing:.5px;color:var(--muted)}
.meta-val{font-size:13px;font-weight:500;color:var(--ink);margin-top:1px;word-break:break-all}

/* ── INFO COLUMNS ── */
.info-col{display:flex;flex-direction:column;gap:16px}
.info-card{background:var(--white);border:1px solid var(--border);border-radius:18px;overflow:hidden;box-shadow:0 2px 8px rgba(21,88,168,.04)}
.info-card-head{display:flex;align-items:center;gap:10px;padding:16px 20px;border-bottom:1px solid var(--border);background:linear-gradient(90deg,#FAFBFD,var(--surface))}
.info-card-icon{width:32px;height:32px;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:14px;flex-shrink:0}
.ici-blue{background:rgba(58,189,224,.12)}
.ici-green{background:rgba(5,150,105,.1)}
.ici-gold{background:rgba(217,119,6,.1)}
.info-card-title{font-family:'Outfit',sans-serif;font-size:15px;color:var(--ink)}
.info-grid{display:grid;grid-template-columns:1fr 1fr;gap:0}
.info-field{padding:13px 20px;border-bottom:1px solid #F2F6FC}
.info-field:nth-last-child(-n+2){border-bottom:none}
.info-field.full{grid-column:1/-1}
.field-lbl{font-size:10.5px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:4px}
.field-val{font-size:13.5px;font-weight:500;color:var(--ink)}
.field-val.empty{color:var(--muted);font-style:italic;font-weight:400}

/* ── BADGES ── */
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:600;white-space:nowrap}
.b-green{background:rgba(5,150,105,.1);color:var(--green)}
.b-red{background:rgba(220,38,38,.1);color:var(--red)}
.b-blue{background:rgba(21,88,168,.1);color:var(--blue)}
.b-gold{background:rgba(217,119,6,.1);color:var(--gold)}
.b-gray{background:#F1F5F9;color:#64748B}
.b-amber{background:rgba(245,158,11,.12);color:#B45309;border:1px solid rgba(245,158,11,.25)}

/* Animations */
@keyframes fadeUp{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)}}
.profile-card{animation:fadeUp .4s ease both}
.info-card:nth-child(1){animation:fadeUp .4s .06s ease both}
.info-card:nth-child(2){animation:fadeUp .4s .12s ease both}
.info-card:nth-child(3){animation:fadeUp .4s .18s ease both}

/* Toast */
.toast{position:fixed;top:20px;right:24px;padding:12px 20px;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;display:flex;align-items:center;gap:8px;box-shadow:0 8px 32px rgba(0,0,0,.2);z-index:999;transition:opacity .4s}
.toast-ok{background:#064e3b;color:#fff}
.toast-warn{background:#92400E;color:#fff}

/* ── PHOTO PROFILE SECTION ── */
.photo-section{margin-top:16px;border-top:1px solid var(--border);padding-top:16px}
.photo-section-label{font-size:10.5px;font-weight:700;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);margin-bottom:10px;text-align:center}

.photo-frame-wrap{position:relative;width:100px;height:100px;margin:0 auto 10px;cursor:pointer}
.photo-frame{
  width:100px;height:100px;border-radius:50%;overflow:hidden;
  border:3px solid var(--border);
  background:linear-gradient(135deg,#E8F3FB,var(--surface));
  display:flex;align-items:center;justify-content:center;
  transition:border-color .2s;
  box-shadow:0 3px 16px rgba(21,88,168,.1);
}
.photo-frame img{width:100%;height:100%;object-fit:cover}
.photo-frame-placeholder{font-size:28px;opacity:.35}
.photo-frame:hover{border-color:var(--cyan)}

/* Edit overlay — chỉ admin thấy */
.photo-edit-overlay{
  position:absolute;inset:0;border-radius:50%;
  background:rgba(15,36,69,.55);
  display:flex;flex-direction:column;align-items:center;justify-content:center;
  gap:3px;opacity:0;transition:opacity .2s;cursor:pointer;
}
.photo-frame-wrap:hover .photo-edit-overlay{opacity:1}
.photo-edit-overlay span{font-size:18px}
.photo-edit-overlay small{font-size:10px;font-weight:600;color:#fff;letter-spacing:.3px}

.photo-actions{display:flex;gap:7px;justify-content:center;margin-top:8px}
.photo-btn{
  display:inline-flex;align-items:center;gap:5px;padding:6px 12px;
  border-radius:8px;font-family:'Outfit',sans-serif;font-size:12px;font-weight:600;
  cursor:pointer;border:none;transition:all .18s;text-decoration:none;
}
.photo-btn-upload{background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;box-shadow:0 3px 10px rgba(21,88,168,.25)}
.photo-btn-upload:hover{transform:translateY(-1px);box-shadow:0 5px 14px rgba(21,88,168,.35)}
.photo-btn-remove{background:var(--surface);border:1.5px solid var(--border);color:var(--muted)}
.photo-btn-remove:hover{border-color:var(--red);color:var(--red)}
#photoFileInput{display:none}

/* ── CROP MODAL ── */
.crop-modal-overlay{
  position:fixed;inset:0;background:rgba(0,0,0,.6);backdrop-filter:blur(4px);
  z-index:1000;display:none;align-items:center;justify-content:center;
}
.crop-modal-overlay.open{display:flex}
.crop-modal{
  background:var(--white);border-radius:22px;width:420px;max-width:94vw;
  box-shadow:0 24px 80px rgba(0,0,0,.35);overflow:hidden;
  animation:modalIn .25s cubic-bezier(.22,1,.36,1);
}
@keyframes modalIn{from{opacity:0;transform:scale(.93) translateY(16px)}to{opacity:1;transform:scale(1) translateY(0)}}
.crop-modal-head{
  padding:18px 22px 14px;border-bottom:1px solid var(--border);
  display:flex;align-items:center;justify-content:space-between;
}
.crop-modal-title{font-family:'Outfit',sans-serif;font-size:17px;color:var(--ink)}
.crop-modal-close{width:28px;height:28px;border-radius:7px;border:none;background:var(--surface);cursor:pointer;font-size:14px;color:var(--muted);display:flex;align-items:center;justify-content:center;transition:all .15s}
.crop-modal-close:hover{background:#FEE2E2;color:var(--red)}
.crop-body{padding:20px 22px}

/* Canvas crop area */
.crop-canvas-wrap{
  position:relative;width:100%;height:280px;overflow:hidden;
  background:#1a1a2e;border-radius:12px;cursor:crosshair;user-select:none;
}
#cropCanvas{display:block;width:100%;height:100%}

/* Controls */
.crop-controls{margin-top:14px;display:flex;flex-direction:column;gap:10px}
.crop-ctrl-row{display:flex;align-items:center;gap:10px}
.crop-ctrl-label{font-size:11.5px;font-weight:700;color:var(--muted);width:48px;text-align:right;flex-shrink:0}
.crop-slider{flex:1;height:4px;border-radius:4px;accent-color:var(--cyan);cursor:pointer}
.crop-shape-btns{display:flex;gap:6px}
.crop-shape-btn{
  flex:1;padding:7px;border-radius:8px;border:1.5px solid var(--border);
  background:var(--surface);font-size:11px;font-weight:700;color:var(--muted);
  cursor:pointer;transition:all .15s;text-align:center;
}
.crop-shape-btn.active{border-color:var(--cyan);background:var(--cyan-soft);color:var(--blue)}

/* Preview strip */
.crop-preview-strip{display:flex;align-items:center;gap:12px;padding:12px 14px;background:var(--surface);border-radius:10px}
.crop-preview-label{font-size:11px;font-weight:700;color:var(--muted);flex-shrink:0}
.crop-preview-circle{width:52px;height:52px;border-radius:50%;overflow:hidden;border:2px solid var(--border);flex-shrink:0}
.crop-preview-square{width:52px;height:52px;border-radius:10px;overflow:hidden;border:2px solid var(--border);flex-shrink:0}
.crop-preview-circle img,.crop-preview-square img{width:100%;height:100%;object-fit:cover}

.crop-footer{padding:14px 22px;border-top:1px solid var(--border);display:flex;gap:10px;justify-content:flex-end}
.crop-btn-cancel{padding:10px 18px;background:var(--surface);border:1.5px solid var(--border);border-radius:10px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;color:var(--muted);cursor:pointer;transition:all .18s}
.crop-btn-cancel:hover{border-color:var(--border);color:var(--navy)}
.crop-btn-apply{padding:10px 20px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;border-radius:10px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;transition:all .22s;box-shadow:0 4px 14px rgba(21,88,168,.25)}
.crop-btn-apply:hover{transform:translateY(-1px);box-shadow:0 6px 18px rgba(21,88,168,.35)}

</style>
</head>
<body>

<!-- ── SIDEBAR ── -->
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
    <a href="${pageContext.request.contextPath}/shifts"    class="nav-item"><span>🕐</span> Ca làm việc</a>
    <a href="${pageContext.request.contextPath}/medicines" class="nav-item"><span>💊</span> Kho thuốc</a>
    <a href="${pageContext.request.contextPath}/invoices"  class="nav-item"><span>🧾</span> Hóa đơn</a>
    <a href="${pageContext.request.contextPath}/customers" class="nav-item"><span>👥</span> Khách hàng</a>
    <a href="${pageContext.request.contextPath}/returns" class="nav-item"><span>↩️</span> Trả hàng</a>
  </nav>
  <nav class="nav-section">
    <div class="nav-label">Phân tích</div>
    <a href="${pageContext.request.contextPath}/audit-logs" class="nav-item"><span>📋</span> Nhật ký</a>
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

<!-- ── MAIN ── -->
<div class="main">
  <header class="topbar">
    <span class="topbar-title">👤 Chi tiết nhân viên</span>
    <div class="topbar-right">
      <a href="${pageContext.request.contextPath}/accounts" class="back-btn">← Danh sách</a>
      <div class="topbar-user">
        <div class="topbar-av"><%= initials %></div>
        <span class="topbar-name"><%= fullName %></span>
      </div>
    </div>
  </header>

  <div class="content">
    <div class="page-head">
      <div class="page-head-left">
        <div class="breadcrumb">MediVault › Tài khoản › Chi tiết</div>
        <h1><%= dn %></h1>
      </div>
      <div class="head-actions">
        <a href="${pageContext.request.contextPath}/accounts?action=edit&id=${account.accountId}" class="btn-primary">✏️ Chỉnh sửa</a>
        <form method="get" action="${pageContext.request.contextPath}/accounts" style="display:inline"
              onsubmit="return confirm('Xác nhận thay đổi trạng thái tài khoản này?')">
          <input type="hidden" name="action" value="toggle">
          <input type="hidden" name="id" value="${account.accountId}">
          <button type="submit" class="<%= a.isActive() ? "btn-warn" : "btn-primary" %>">
            <%= a.isActive() ? "🔒 Khóa tài khoản" : "🔓 Mở khóa" %>
          </button>
        </form>
      </div>
    </div>

    <div class="detail-layout">

      <!-- ── PROFILE CARD ── -->
      <div class="profile-card">
        <div class="profile-banner"></div>
        <div class="profile-body">

          <!-- Avatar + upload -->
          <div class="profile-av-wrap">
            <div class="profile-av" id="profileAvEl">
              <c:choose>
                <c:when test="${not empty account.faceEnrollmentPath}">
                  <img src="${pageContext.request.contextPath}/${account.faceEnrollmentPath}" alt="<%= dn %>" id="profileImg">
                </c:when>
                <c:otherwise>
                  <span id="profileInitials"><%= av %></span>
                </c:otherwise>
              </c:choose>
            </div>
            <div class="profile-av-status <%= a.isActive() ? "status-active" : "status-locked" %>">
              <%= a.isActive() ? "✓" : "✕" %>
            </div>
          </div>

          <div class="profile-name"><%= dn %></div>
          <div class="profile-username">@${account.username}</div>
          <div class="profile-role-badge <%= a.getRoleId()==1 ? "role-admin" : a.getRoleId()==2 ? "role-pharmacist" : "role-warehouse" %>">
            <%= a.getRoleId()==1 ? "🛡️" : a.getRoleId()==2 ? "💊" : "📦" %> <%= roleName %>
          </div>
          <br>
          <span class="profile-status-text <%= a.isActive() ? "status-text-active" : "status-text-locked" %>">
            ● <%= a.isActive() ? "Đang hoạt động" : "Đã khóa" %>
          </span>
          <% if (hasPendingReset) { %>
          <br><br>
          <span class="badge b-amber" style="font-size:12px;padding:5px 12px">
            ⏳ Chờ cấp lại mật khẩu
          </span>
          <% } %>

          <!-- ── PHOTO PROFILE SECTION ── -->
          <div class="photo-section">
            <div class="photo-section-label">Ảnh đại diện</div>

            <!-- Khung ảnh profile tròn -->
            <div class="photo-frame-wrap" id="photoFrameWrap" onclick="openCropModal()">
              <div class="photo-frame" id="photoFrame">
                <c:choose>
                  <c:when test="${not empty account.faceEnrollmentPath}">
                    <img src="${pageContext.request.contextPath}/${account.faceEnrollmentPath}" alt="profile" id="profilePhoto">
                  </c:when>
                  <c:otherwise>
                    <div class="photo-frame-placeholder" id="photoPlaceholder">👤</div>
                  </c:otherwise>
                </c:choose>
              </div>
              <!-- Edit overlay — chỉ admin thấy -->
              <div class="photo-edit-overlay" id="photoEditOverlay">
                <span>✏️</span>
                <small>Chỉnh ảnh</small>
              </div>
            </div>

            <!-- Buttons upload/remove — chỉ admin -->
            <div class="photo-actions" id="photoAdminActions">
              <input type="file" id="photoFileInput" accept="image/*" onchange="onFileSelected(event)">
              <label for="photoFileInput" class="photo-btn photo-btn-upload">📷 Chọn ảnh</label>
              <button type="button" class="photo-btn photo-btn-remove" id="photoRemoveBtn" onclick="removePhoto()" style="display:none">🗑️ Xóa</button>
            </div>
            <div id="photoSaveStatus" style="font-size:11.5px;text-align:center;margin-top:6px;min-height:18px;color:var(--muted)"></div>
          </div>

          <div class="profile-divider"></div>

          <!-- Meta info -->
          <div class="profile-meta">
            <c:if test="${not empty account.email}">
            <div class="meta-row">
              <div class="meta-icon">📧</div>
              <div><div class="meta-lbl">Email</div><div class="meta-val">${account.email}</div></div>
            </div>
            </c:if>
            <c:if test="${not empty account.phone}">
            <div class="meta-row">
              <div class="meta-icon">📱</div>
              <div><div class="meta-lbl">Điện thoại</div><div class="meta-val">${account.phone}</div></div>
            </div>
            </c:if>
            <div class="meta-row">
              <div class="meta-icon">🗓️</div>
              <div>
                <div class="meta-lbl">Ngày tạo</div>
                <div class="meta-val">
                  <c:choose>
                    <c:when test="${account.createdAt != null}">
                      ${account.createdAt.dayOfMonth}/${account.createdAt.monthValue}/${account.createdAt.year}
                    </c:when>
                    <c:otherwise>—</c:otherwise>
                  </c:choose>
                </div>
              </div>
            </div>
            <div class="meta-row">
              <div class="meta-icon">⏱️</div>
              <div>
                <div class="meta-lbl">Đăng nhập cuối</div>
                <div class="meta-val">
                  <c:choose>
                    <c:when test="${account.lastLoginAt != null}">
                      ${account.lastLoginAt.dayOfMonth}/${account.lastLoginAt.monthValue}/${account.lastLoginAt.year}
                      ${account.lastLoginAt.hour}:<c:if test="${account.lastLoginAt.minute lt 10}">0</c:if>${account.lastLoginAt.minute}
                    </c:when>
                    <c:otherwise>Chưa đăng nhập</c:otherwise>
                  </c:choose>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- ── INFO COLUMNS ── -->
      <div class="info-col">

        <!-- Thông tin cá nhân -->
        <div class="info-card">
          <div class="info-card-head">
            <div class="info-card-icon ici-blue">👤</div>
            <div class="info-card-title">Thông tin cá nhân</div>
          </div>
          <div class="info-grid">
            <div class="info-field">
              <div class="field-lbl">Họ và tên</div>
              <div class="field-val">${not empty account.fullName ? account.fullName : '—'}</div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Tên đăng nhập</div>
              <div class="field-val">@${account.username}</div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Email</div>
              <div class="field-val ${empty account.email ? 'empty' : ''}">${not empty account.email ? account.email : 'Chưa cập nhật'}</div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Số điện thoại</div>
              <div class="field-val ${empty account.phone ? 'empty' : ''}">${not empty account.phone ? account.phone : 'Chưa cập nhật'}</div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Số CCCD / CMND</div>
              <div class="field-val ${empty account.citizenId ? 'empty' : ''}">${not empty account.citizenId ? account.citizenId : 'Chưa cập nhật'}</div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Chức vụ / Bộ phận</div>
              <div class="field-val ${empty account.position ? 'empty' : ''}">${not empty account.position ? account.position : 'Chưa cập nhật'}</div>
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
              <div class="field-val ${empty account.professionalCertNo ? 'empty' : ''}">${not empty account.professionalCertNo ? account.professionalCertNo : 'Chưa cập nhật'}</div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Phân quyền hệ thống</div>
              <div class="field-val">
                <% if (a.getRoleId()==1) { %><span class="badge b-red">🛡️ Admin</span>
                <% } else if (a.getRoleId()==2) { %><span class="badge b-blue">💊 Dược sĩ bán hàng</span>
                <% } else { %><span class="badge b-gold">📦 Thủ kho</span><% } %>
              </div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Ngày hết hạn chứng chỉ</div>
              <div class="field-val">
                <c:choose>
                  <c:when test="${account.professionalCertExp != null}">
                    ${account.professionalCertExp.dayOfMonth}/${account.professionalCertExp.monthValue}/${account.professionalCertExp.year}
                  </c:when>
                  <c:otherwise><span class="field-val empty">Chưa cập nhật</span></c:otherwise>
                </c:choose>
              </div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Ngày đào tạo</div>
              <div class="field-val">
                <c:choose>
                  <c:when test="${account.trainingDate != null}">
                    ${account.trainingDate.dayOfMonth}/${account.trainingDate.monthValue}/${account.trainingDate.year}
                  </c:when>
                  <c:otherwise><span class="field-val empty">Chưa cập nhật</span></c:otherwise>
                </c:choose>
              </div>
            </div>
          </div>
        </div>

        <!-- Trạng thái hệ thống -->
        <div class="info-card">
          <div class="info-card-head">
            <div class="info-card-icon ici-gold">⚙️</div>
            <div class="info-card-title">Trạng thái hệ thống</div>
          </div>
          <div class="info-grid">
            <div class="info-field">
              <div class="field-lbl">Trạng thái</div>
              <div class="field-val">
                <%= a.isActive()
                    ? "<span class='badge b-green'>● Đang hoạt động</span>"
                    : "<span class='badge b-gray'>● Đã khóa</span>" %>
                <% if (hasPendingReset) { %>
                <span class="badge b-amber" style="margin-left:6px">⏳ Chờ cấp lại mật khẩu</span>
                <% } %>
              </div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Account ID</div>
              <div class="field-val">#${account.accountId}</div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Ngày tạo tài khoản</div>
              <div class="field-val">
                <c:choose>
                  <c:when test="${account.createdAt != null}">
                    ${account.createdAt.dayOfMonth}/${account.createdAt.monthValue}/${account.createdAt.year}
                    ${account.createdAt.hour}:<c:if test="${account.createdAt.minute lt 10}">0</c:if>${account.createdAt.minute}
                  </c:when>
                  <c:otherwise>—</c:otherwise>
                </c:choose>
              </div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Lần đăng nhập cuối</div>
              <div class="field-val">
                <c:choose>
                  <c:when test="${account.lastLoginAt != null}">
                    ${account.lastLoginAt.dayOfMonth}/${account.lastLoginAt.monthValue}/${account.lastLoginAt.year}
                    ${account.lastLoginAt.hour}:<c:if test="${account.lastLoginAt.minute lt 10}">0</c:if>${account.lastLoginAt.minute}
                  </c:when>
                  <c:otherwise><span class="field-val empty">Chưa đăng nhập</span></c:otherwise>
                </c:choose>
              </div>
            </div>
            <div class="info-field full">
              <div class="field-lbl">Ảnh / Dữ liệu khuôn mặt</div>
              <div class="field-val">
                <c:choose>
                  <c:when test="${not empty account.faceEnrollmentPath}">
                    <span class="badge b-green">✓ Đã có ảnh</span>
                    <span style="font-size:12px;color:var(--muted);margin-left:8px">${account.faceEnrollmentPath}</span>
                  </c:when>
                  <c:otherwise><span class="badge b-gray">Chưa có ảnh</span></c:otherwise>
                </c:choose>
              </div>
            </div>
          </div>
        </div>

      </div><!-- /info-col -->
    </div><!-- /detail-layout -->
  </div>
</div>

<script>
/* ════════════════════════════════════════
   PHOTO PROFILE + CROP ENGINE
   ════════════════════════════════════════ */
let cropImg = null;
let cropShape = 'circle';
let dragStart = null, imgOffset = {x:0, y:0}, imgOffsetStart = {x:0, y:0};
let currentPhotoData = null; // base64 kết quả sau crop

// ── Khi chọn file ──
function onFileSelected(event) {
  const file = event.target.files[0];
  if (!file) return;
  if (!file.type.startsWith('image/')) { setSaveStatus('❌ Chỉ chấp nhận file ảnh!','var(--red)'); return; }
  if (file.size > 8 * 1024 * 1024) { setSaveStatus('❌ Ảnh phải nhỏ hơn 8MB!','var(--red)'); return; }
  const reader = new FileReader();
  reader.onload = e => {
    const img = new Image();
    img.onload = () => {
      cropImg = img;
      imgOffset = {x:0, y:0};
      // Auto-fit: tính zoom sao cho ảnh vừa lấp đầy crop circle
      const canvas = document.getElementById('cropCanvas');
      const W = canvas.width, H = canvas.height;
      const cropSize = Math.min(W, H) - 24;
      // scale để ảnh cover vừa khít crop circle (không nhỏ hơn)
      const fitScale = Math.max(cropSize / img.width, cropSize / img.height);
      // Đổi về % cho slider (base scale = max(W,H)/img)
      const baseScale = Math.max(W / img.width, H / img.height);
      const initZoomPct = Math.round((fitScale / baseScale) * 100);
      document.getElementById('zoomSlider').value = Math.min(300, Math.max(50, initZoomPct));
      document.getElementById('rotateSlider').value = 0;
      openCropModal();
      setTimeout(renderCrop, 50);
    };
    img.src = e.target.result;
  };
  reader.readAsDataURL(file);
  // Reset input để có thể chọn lại cùng file
  event.target.value = '';
}

// ── Mở modal ──
function openCropModal() {
  if (!cropImg) return; // chỉ mở khi có ảnh
  document.getElementById('cropModalOverlay').classList.add('open');
  document.body.style.overflow = 'hidden';
  renderCrop();
}
function closeCropModal() {
  document.getElementById('cropModalOverlay').classList.remove('open');
  document.body.style.overflow = '';
}
function closeCropOnOverlay(e) {
  if (e.target === document.getElementById('cropModalOverlay')) closeCropModal();
}

// ── Shape toggle ──
function setShape(s) {
  cropShape = s;
  document.getElementById('shapeCircle').classList.toggle('active', s==='circle');
  document.getElementById('shapeSquare').classList.toggle('active', s==='square');
  renderCrop();
}

// ── Render canvas crop ──
function renderCrop() {
  if (!cropImg) return;
  const canvas = document.getElementById('cropCanvas');
  const ctx = canvas.getContext('2d');
  const W = canvas.width, H = canvas.height;
  const zoom = parseInt(document.getElementById('zoomSlider').value) / 100;
  const rotate = parseInt(document.getElementById('rotateSlider').value);
  document.getElementById('zoomLabel').textContent = Math.round(zoom*100) + '%';
  document.getElementById('rotateLabel').textContent = rotate + '°';

  ctx.clearRect(0, 0, W, H);
  // Background
  ctx.fillStyle = '#1a1a2e';
  ctx.fillRect(0, 0, W, H);

  // Draw image with transform
  ctx.save();
  ctx.translate(W/2 + imgOffset.x, H/2 + imgOffset.y);
  ctx.rotate(rotate * Math.PI / 180);
  const iw = cropImg.width * zoom, ih = cropImg.height * zoom;
  const scale = Math.max(W/cropImg.width, H/cropImg.height) * zoom;
  const sw = cropImg.width * scale, sh = cropImg.height * scale;
  ctx.drawImage(cropImg, -sw/2, -sh/2, sw, sh);
  ctx.restore();

  // Dimming outside crop circle
  const cropSize = Math.min(W, H) - 24;
  ctx.save();
  ctx.fillStyle = 'rgba(0,0,0,.5)';
  ctx.fillRect(0, 0, W, H);
  ctx.globalCompositeOperation = 'destination-out';
  if (cropShape === 'circle') {
    ctx.beginPath();
    ctx.arc(W/2, H/2, cropSize/2, 0, Math.PI*2);
    ctx.fill();
  } else {
    const r = 12;
    const x = W/2-cropSize/2, y = H/2-cropSize/2;
    ctx.beginPath();
    ctx.roundRect(x, y, cropSize, cropSize, r);
    ctx.fill();
  }
  ctx.restore();

  // Border ring
  ctx.save();
  ctx.strokeStyle = 'rgba(58,189,224,.7)';
  ctx.lineWidth = 2;
  if (cropShape === 'circle') {
    ctx.beginPath();
    ctx.arc(W/2, H/2, cropSize/2, 0, Math.PI*2);
    ctx.stroke();
  } else {
    const x = W/2-cropSize/2, y = H/2-cropSize/2;
    ctx.beginPath();
    ctx.roundRect(x, y, cropSize, cropSize, 12);
    ctx.stroke();
  }
  ctx.restore();

  // Update previews
  updatePreviews(W, H, cropSize, zoom, rotate);
}

function updatePreviews(W, H, cropSize, zoom, rotate) {
  if (!cropImg) return;
  const update = (canvasId) => {
    const pc = document.getElementById(canvasId);
    const pctx = pc.getContext('2d');
    const PW = pc.width, PH = pc.height;
    pctx.clearRect(0,0,PW,PH);
    pctx.save();
    if (canvasId === 'previewCircle') {
      pctx.beginPath(); pctx.arc(PW/2,PH/2,PW/2,0,Math.PI*2); pctx.clip();
    } else {
      pctx.beginPath(); pctx.roundRect(0,0,PW,PH,6); pctx.clip();
    }
    pctx.translate(PW/2 + imgOffset.x*(PW/W), PH/2 + imgOffset.y*(PH/H));
    pctx.rotate(rotate * Math.PI / 180);
    const scale = Math.max(W/cropImg.width, H/cropImg.height) * zoom * (PW/cropSize);
    const sw = cropImg.width*scale, sh = cropImg.height*scale;
    pctx.drawImage(cropImg, -sw/2, -sh/2, sw, sh);
    pctx.restore();
  };
  update('previewCircle');
  update('previewSquare');
}

// ── Drag để di chuyển ảnh ──
// Tính scale ratio vì canvas CSS width != canvas logical width
// Tính scale ratio để đổi pixel display → canvas logical pixel
function getCanvasScale() {
  const el = document.getElementById('cropCanvas');
  const rect = el.getBoundingClientRect();
  return {
    sx: el.width  / rect.width,
    sy: el.height / rect.height
  };
}

const cropCanvasEl = document.getElementById('cropCanvas');
cropCanvasEl.style.cursor = 'grab';

cropCanvasEl.addEventListener('mousedown', e => {
  e.preventDefault();
  // Lưu điểm bắt đầu theo client pixel (không scale) để tính delta
  dragStart = {x: e.clientX, y: e.clientY};
  imgOffsetStart = {...imgOffset};
  cropCanvasEl.style.cursor = 'grabbing';
});
document.addEventListener('mousemove', e => {
  if (!dragStart) return;
  const s = getCanvasScale();
  // Delta pixel display * scale → delta canvas logical pixel
  const dx = (e.clientX - dragStart.x) * s.sx;
  const dy = (e.clientY - dragStart.y) * s.sy;
  imgOffset.x = imgOffsetStart.x + dx;
  imgOffset.y = imgOffsetStart.y + dy;
  renderCrop();
});
document.addEventListener('mouseup', () => {
  dragStart = null;
  cropCanvasEl.style.cursor = 'grab';
});

// Touch support
cropCanvasEl.addEventListener('touchstart', e => {
  const t = e.touches[0];
  dragStart = {x: t.clientX, y: t.clientY};
  imgOffsetStart = {...imgOffset};
}, {passive:true});
document.addEventListener('touchmove', e => {
  if (!dragStart) return;
  const t = e.touches[0];
  const s = getCanvasScale();
  const dx = (t.clientX - dragStart.x) * s.sx;
  const dy = (t.clientY - dragStart.y) * s.sy;
  imgOffset.x = imgOffsetStart.x + dx;
  imgOffset.y = imgOffsetStart.y + dy;
  renderCrop();
}, {passive:true});
document.addEventListener('touchend', () => { dragStart = null; });

// ── Lưu ảnh lên server ──
async function savePhotoToServer(base64, accountId) {
    try {
        const res = await fetch('${pageContext.request.contextPath}/accounts', {
            method: 'POST',
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: 'action=upload-photo&id=' + accountId + '&photoData=' + encodeURIComponent(base64)
        });
        const data = await res.json();
        if (data.ok) setSaveStatus('✓ Đã lưu ảnh thành công!', 'var(--green)');
        else setSaveStatus('❌ Lưu thất bại: ' + (data.msg || ''), 'var(--red)');
    } catch(e) {
        setSaveStatus('❌ Lỗi kết nối server', 'var(--red)');
    }
}

// ── Apply crop → xuất ảnh ──
async function applyCrop() {
  const canvas = document.getElementById('cropCanvas');
  const W = canvas.width, H = canvas.height;
  const cropSize = Math.min(W,H) - 24;
  const zoom = parseInt(document.getElementById('zoomSlider').value) / 100;
  const rotate = parseInt(document.getElementById('rotateSlider').value);

  // Tạo output canvas kích thước 256x256
  const outSize = 256;
  const out = document.createElement('canvas');
  out.width = outSize; out.height = outSize;
  const octx = out.getContext('2d');

  if (cropShape === 'circle') {
    octx.beginPath(); octx.arc(outSize/2,outSize/2,outSize/2,0,Math.PI*2); octx.clip();
  } else {
    octx.beginPath(); octx.roundRect(0,0,outSize,outSize,18); octx.clip();
  }
  octx.translate(outSize/2 + imgOffset.x*(outSize/W), outSize/2 + imgOffset.y*(outSize/H));
  octx.rotate(rotate * Math.PI / 180);
  const scale = Math.max(W/cropImg.width, H/cropImg.height) * zoom * (outSize/cropSize);
  const sw = cropImg.width*scale, sh = cropImg.height*scale;
  octx.drawImage(cropImg, -sw/2, -sh/2, sw, sh);

  currentPhotoData = out.toDataURL('image/png', 0.92);

  // Cập nhật ảnh vào khung profile
  const frame = document.getElementById('photoFrame');
  frame.innerHTML = '<img src="' + currentPhotoData + '" alt="profile" style="width:100%;height:100%;object-fit:cover" id="profilePhoto">';
  document.getElementById('photoRemoveBtn').style.display = 'inline-flex';
  setSaveStatus('✓ Ảnh đã cập nhật · Tính năng lưu server sẽ có ở bản tiếp theo', 'var(--green)');

  closeCropModal();
  // Lưu lên server
  await savePhotoToServer(currentPhotoData, ${account.accountId});
}

// ── Xóa ảnh ──
function removePhoto() {
  if (!confirm('Xóa ảnh đại diện hiện tại?')) return;
  currentPhotoData = null;
  const frame = document.getElementById('photoFrame');
  frame.innerHTML = '<div class="photo-frame-placeholder" id="photoPlaceholder">👤</div>';
  document.getElementById('photoRemoveBtn').style.display = 'none';
  setSaveStatus('Đã xóa ảnh', 'var(--muted)');
  setTimeout(() => setSaveStatus('',''), 2500);
}

// ── Status text ──
function setSaveStatus(msg, color) {
  const el = document.getElementById('photoSaveStatus');
  if (el) { el.textContent = msg; el.style.color = color || 'var(--muted)'; }
}

// ESC để đóng modal
document.addEventListener('keydown', e => {
  if (e.key === 'Escape') closeCropModal();
});
</script>

<!-- ── CROP MODAL ── -->
<div class="crop-modal-overlay" id="cropModalOverlay" onclick="closeCropOnOverlay(event)">
  <div class="crop-modal">
    <div class="crop-modal-head">
      <div class="crop-modal-title">✂️ Chỉnh sửa ảnh đại diện</div>
      <button class="crop-modal-close" onclick="closeCropModal()">✕</button>
    </div>
    <div class="crop-body">
      <!-- Canvas crop -->
      <div class="crop-canvas-wrap">
        <canvas id="cropCanvas" width="376" height="280"></canvas>
      </div>
      <!-- Controls -->
      <div class="crop-controls">
        <div class="crop-ctrl-row">
          <span class="crop-ctrl-label">Zoom</span>
          <input type="range" class="crop-slider" id="zoomSlider" min="50" max="300" value="100" oninput="renderCrop()">
          <span style="font-size:11.5px;color:var(--muted);width:34px;text-align:right" id="zoomLabel">100%</span>
        </div>
        <div class="crop-ctrl-row">
          <span class="crop-ctrl-label">Xoay</span>
          <input type="range" class="crop-slider" id="rotateSlider" min="-180" max="180" value="0" oninput="renderCrop()">
          <span style="font-size:11.5px;color:var(--muted);width:34px;text-align:right" id="rotateLabel">0°</span>
        </div>
        <div class="crop-ctrl-row">
          <span class="crop-ctrl-label">Khung</span>
          <div class="crop-shape-btns">
            <button class="crop-shape-btn active" id="shapeCircle" onclick="setShape('circle')">⬤ Tròn</button>
            <button class="crop-shape-btn" id="shapeSquare" onclick="setShape('square')">⬛ Vuông</button>
          </div>
        </div>
      </div>
      <!-- Preview -->
      <div class="crop-preview-strip" style="margin-top:12px">
        <span class="crop-preview-label">Preview</span>
        <div class="crop-preview-circle"><canvas id="previewCircle" width="52" height="52"></canvas></div>
        <div class="crop-preview-square"><canvas id="previewSquare" width="52" height="52"></canvas></div>
        <span style="font-size:11.5px;color:var(--muted)">Kéo ảnh để điều chỉnh vị trí</span>
      </div>
    </div>
    <div class="crop-footer">
      <button class="crop-btn-cancel" onclick="closeCropModal()">Hủy</button>
      <button class="crop-btn-apply" onclick="applyCrop()">✓ Áp dụng ảnh này</button>
    </div>
  </div>
</div>

</body>
</html>
