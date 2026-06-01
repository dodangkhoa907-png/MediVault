<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%
    com.medivault.entity.Account acc = (com.medivault.entity.Account) session.getAttribute("account");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    if (acc.getRoleId() != 1) { response.sendRedirect(request.getContextPath() + "/dashboard"); return; }

    com.medivault.entity.Account a = (com.medivault.entity.Account) request.getAttribute("account");
    if (a == null) { response.sendRedirect(request.getContextPath() + "/accounts"); return; }

    java.lang.String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    java.lang.String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();

    java.lang.String dn = (a.getFullName() != null && !a.getFullName().isEmpty()) ? a.getFullName() : a.getUsername();
    java.lang.String av = dn.length() >= 2
        ? dn.substring(0,1).toUpperCase() + dn.substring(1,2).toUpperCase()
        : dn.toUpperCase();
    java.lang.String roleName = a.getRoleId()==1 ? "Admin" : a.getRoleId()==2 ? "Dược sĩ" : "Thủ kho";
    java.lang.String roleColor = a.getRoleId()==1 ? "#e74c3c" : a.getRoleId()==2 ? "#114C7D" : "#b8750a";
    java.lang.String roleBg   = a.getRoleId()==1 ? "rgba(231,76,60,.1)" : a.getRoleId()==2 ? "rgba(70,202,244,.12)" : "rgba(252,218,124,.2)";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title><%= dn %> — Chi tiết nhân viên — MediVault</title>
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

/* SIDEBAR — same as list */
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(180deg,var(--navy) 0%,#182845 55%,var(--blue) 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100}
.sidebar-logo{padding:20px 18px 18px;display:flex;align-items:center;gap:10px;border-bottom:1px solid rgba(255,255,255,.07)}
.logo-icon{width:38px;height:38px;background:rgba(70,202,244,.15);border:1.5px solid rgba(70,202,244,.3);border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:18px}
.logo-text{font-family:'Nunito',sans-serif;font-size:17px;font-weight:900;color:#fff;letter-spacing:-.3px;line-height:1.1}
.logo-text span{color:var(--sky)}.logo-sub{font-size:9.5px;color:rgba(255,255,255,.35);letter-spacing:1px;text-transform:uppercase}
.nav-section{padding:16px 0 8px}.nav-label{font-size:9px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;color:rgba(255,255,255,.25);padding:0 18px 8px}
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

.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh}
.topbar{height:60px;background:#fff;border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:16px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Nunito',sans-serif;font-size:16px;font-weight:800;color:var(--navy)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:8px}
.back-btn{display:inline-flex;align-items:center;gap:6px;height:34px;padding:0 14px;border:1.5px solid var(--border);border-radius:8px;font-size:13px;font-weight:500;color:var(--muted);text-decoration:none;transition:all .15s;background:#fff}
.back-btn:hover{border-color:var(--blue);color:var(--blue);background:#f0f8ff}
.topbar-av{width:28px;height:28px;background:linear-gradient(135deg,var(--sky),var(--blue));border-radius:7px;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;color:#fff}
.topbar-user{display:flex;align-items:center;gap:8px;padding:4px 10px;border:1.5px solid var(--border);border-radius:10px;text-decoration:none;color:inherit}
.topbar-name{font-size:13px;font-weight:600;color:var(--navy)}

.content{padding:28px;flex:1}
.page-head{display:flex;align-items:center;gap:16px;margin-bottom:24px;flex-wrap:wrap}
.breadcrumb{font-size:11.5px;color:var(--muted);font-weight:500;margin-bottom:4px}
.page-head h1{font-family:'Nunito',sans-serif;font-size:22px;font-weight:900;letter-spacing:-.3px}
.head-actions{margin-left:auto;display:flex;gap:8px}
.btn{display:inline-flex;align-items:center;gap:6px;height:36px;padding:0 16px;border-radius:9px;border:1.5px solid;font-size:13px;font-weight:600;font-family:inherit;cursor:pointer;text-decoration:none;transition:all .2s}
.btn-primary{background:var(--blue);border-color:var(--blue);color:#fff}
.btn-primary:hover{background:#0d3d63}
.btn-warn{background:#fff8e6;border-color:#f5dfa8;color:var(--gold)}
.btn-warn:hover{background:#ffefc2}
.btn-danger{background:#fff5f5;border-color:#fcc;color:var(--red)}
.btn-danger:hover{background:#fee2e2}

/* LAYOUT */
.detail-grid{display:grid;grid-template-columns:300px 1fr;gap:20px;align-items:start}

/* PROFILE CARD */
.profile-card{background:#fff;border:1px solid var(--border);border-radius:18px;overflow:hidden;position:sticky;top:80px}
.profile-banner{height:80px;background:linear-gradient(135deg,var(--navy) 0%,var(--blue) 100%)}
.profile-body{padding:0 24px 24px;text-align:center}
.profile-av-wrap{margin-top:-40px;margin-bottom:12px;position:relative;display:inline-block}
.profile-av{width:80px;height:80px;border-radius:20px;border:4px solid #fff;background:linear-gradient(135deg,var(--sky),var(--blue));display:flex;align-items:center;justify-content:center;font-size:28px;font-weight:900;color:#fff;overflow:hidden;box-shadow:0 4px 16px rgba(17,76,125,.25)}
.profile-av img{width:100%;height:100%;object-fit:cover}
.profile-av-badge{position:absolute;bottom:-4px;right:-4px;width:22px;height:22px;background:<%= a.isActive() ? "var(--green)" : "var(--muted)" %>;border-radius:50%;border:3px solid #fff;display:flex;align-items:center;justify-content:center;font-size:9px;color:#fff}
.profile-name{font-family:'Nunito',sans-serif;font-size:18px;font-weight:900;color:var(--navy);margin-bottom:4px}
.profile-username{font-size:13px;color:var(--muted);margin-bottom:10px}
.profile-role{display:inline-flex;align-items:center;gap:4px;padding:4px 12px;border-radius:20px;font-size:12px;font-weight:700;background:<%= roleBg %>;color:<%= roleColor %>;margin-bottom:16px}
.profile-status{display:inline-flex;align-items:center;gap:5px;font-size:12.5px;font-weight:600;color:<%= a.isActive()?"var(--green)":"var(--muted)" %>}
.profile-status::before{content:'●';font-size:8px}
.profile-divider{height:1px;background:var(--border);margin:16px 0}
.profile-meta{text-align:left}
.meta-row{display:flex;align-items:flex-start;gap:10px;margin-bottom:12px;font-size:13px}
.meta-icon{width:28px;height:28px;border-radius:8px;background:var(--surface);display:flex;align-items:center;justify-content:center;font-size:13px;flex-shrink:0}
.meta-lbl{font-size:11px;color:var(--muted);font-weight:500;margin-bottom:1px}
.meta-val{font-weight:600;color:var(--navy);word-break:break-all}

/* ─── ẢNH PLACEHOLDER ─── */
.photo-placeholder{border:2px dashed var(--border);border-radius:14px;padding:20px;text-align:center;margin-top:16px;background:#fafcff;transition:border-color .2s}
.photo-placeholder:hover{border-color:var(--sky)}
.photo-placeholder .pi{font-size:28px;margin-bottom:6px}
.photo-placeholder p{font-size:12px;color:var(--muted);line-height:1.4}
.photo-placeholder span{font-size:11px;color:var(--sky);font-weight:600;cursor:pointer}

/* INFO SECTIONS */
.info-col{display:flex;flex-direction:column;gap:16px}
.info-card{background:#fff;border:1px solid var(--border);border-radius:16px;overflow:hidden}
.info-card-head{display:flex;align-items:center;gap:10px;padding:16px 20px;border-bottom:1px solid var(--border);background:#fafcff}
.info-card-icon{width:32px;height:32px;border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:15px}
.ici-blue{background:rgba(70,202,244,.12)}
.ici-green{background:rgba(26,122,74,.1)}
.ici-gold{background:rgba(252,218,124,.2)}
.ici-red{background:rgba(231,76,60,.1)}
.info-card-title{font-family:'Nunito',sans-serif;font-size:14px;font-weight:800;color:var(--navy)}
.info-grid{display:grid;grid-template-columns:1fr 1fr;gap:0}
.info-field{padding:14px 20px;border-bottom:1px solid #f0f4f9}
.info-field:nth-last-child(-n+2){border-bottom:none}
.info-field.full{grid-column:1/-1}
.field-lbl{font-size:11px;font-weight:600;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:4px}
.field-val{font-size:13.5px;font-weight:500;color:var(--navy)}
.field-val.empty{color:var(--muted);font-style:italic;font-weight:400}

.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:12px;font-weight:600}
.badge::before{content:'●';font-size:7px}
.b-green{background:rgba(26,122,74,.1);color:var(--green)}
.b-gray{background:#f0f4f9;color:var(--muted)}
.b-blue{background:rgba(70,202,244,.12);color:var(--blue)}
.b-red{background:rgba(231,76,60,.1);color:var(--red)}
.b-gold{background:rgba(252,218,124,.2);color:var(--gold)}

/* Activity log placeholder */
.log-row{display:flex;align-items:flex-start;gap:12px;padding:12px 20px;border-bottom:1px solid #f0f4f9}
.log-row:last-child{border-bottom:none}
.log-dot{width:8px;height:8px;border-radius:50%;background:var(--sky);flex-shrink:0;margin-top:5px}
.log-text{font-size:13px;color:var(--navy);font-weight:500}
.log-time{font-size:11.5px;color:var(--muted);margin-top:2px}

@media(max-width:900px){.detail-grid{grid-template-columns:1fr}.profile-card{position:static}}
</style>
</head>
<body>

<aside class="sidebar">
  <div class="sidebar-logo">
    <div class="logo-icon">💊</div>
    <div><div class="logo-text">Medi<span>Vault</span></div><div class="logo-sub">Admin Console</div></div>
  </div>
  <nav class="nav-section">
    <div class="nav-label">Tổng quan</div>
    <a href="${pageContext.request.contextPath}/dashboard" class="nav-item"><span>🏠</span> Trang chủ</a>
  </nav>
  <nav class="nav-section">
    <div class="nav-label">Quản lý</div>
    <a href="${pageContext.request.contextPath}/accounts" class="nav-item active"><span>👤</span> Tài khoản</a>
    <a href="${pageContext.request.contextPath}/shifts"   class="nav-item"><span>🕐</span> Ca làm việc</a>
    <a href="${pageContext.request.contextPath}/medicines" class="nav-item"><span>💊</span> Kho thuốc</a>
    <a href="${pageContext.request.contextPath}/invoices"  class="nav-item"><span>🧾</span> Hóa đơn</a>
    <a href="${pageContext.request.contextPath}/customers" class="nav-item"><span>👥</span> Khách hàng</a>
  </nav>
  <div class="sidebar-footer">
    <div class="sidebar-user">
      <div class="user-av"><%= initials %></div>
      <div><div class="user-name"><%= fullName %></div><div class="user-role">Admin</div></div>
      <a href="${pageContext.request.contextPath}/logout" class="logout-btn" title="Đăng xuất">⏻</a>
    </div>
  </div>
</aside>

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
      <div>
        <div class="breadcrumb">MediVault › Tài khoản › Chi tiết</div>
        <h1><%= dn %></h1>
      </div>
      <div class="head-actions">
        <a href="${pageContext.request.contextPath}/accounts?action=edit&id=${account.accountId}" class="btn btn-primary">✏️ Chỉnh sửa</a>
        <form method="post" action="${pageContext.request.contextPath}/accounts" style="display:inline"
              onsubmit="return confirm('Xác nhận thay đổi trạng thái tài khoản này?')">
          <input type="hidden" name="action" value="toggle">
          <input type="hidden" name="accountId" value="${account.accountId}">
          <button type="submit" class="btn <%= a.isActive() ? "btn-warn" : "btn-primary" %>">
            <%= a.isActive() ? "🔒 Khóa tài khoản" : "🔓 Mở khóa" %>
          </button>
        </form>
      </div>
    </div>

    <div class="detail-grid">

      <%-- ── PROFILE CARD ── --%>
      <div class="profile-card">
        <div class="profile-banner"></div>
        <div class="profile-body">
          <div class="profile-av-wrap">
            <div class="profile-av">
              <c:choose>
                <c:when test="${not empty account.faceEnrollmentPath}">
                  <img src="${pageContext.request.contextPath}/${account.faceEnrollmentPath}" alt="<%= dn %>">
                </c:when>
                <c:otherwise><%= av %></c:otherwise>
              </c:choose>
            </div>
            <div class="profile-av-badge"><%= a.isActive() ? "✓" : "✕" %></div>
          </div>
          <div class="profile-name"><%= dn %></div>
          <div class="profile-username">@${account.username}</div>
          <div class="profile-role"><%= roleName %></div><br>
          <span class="profile-status"><%= a.isActive() ? "Đang hoạt động" : "Đã khóa" %></span>

          <div class="profile-divider"></div>

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
                      ${account.lastLoginAt.dayOfMonth}/${account.lastLoginAt.monthValue}/${account.lastLoginAt.year} ${account.lastLoginAt.hour}:<c:if test="${account.lastLoginAt.minute lt 10}">0</c:if>${account.lastLoginAt.minute}
                    </c:when>
                    <c:otherwise>Chưa đăng nhập</c:otherwise>
                  </c:choose>
                </div>
              </div>
            </div>
          </div>

          <%-- PHOTO UPLOAD PLACEHOLDER --%>
          <div class="photo-placeholder">
            <div class="pi">📷</div>
            <p>Ảnh nhân viên / Dữ liệu khuôn mặt<br>chấm công tự động</p>
            <span>Tính năng sẽ cập nhật sau →</span>
          </div>
        </div>
      </div>

      <%-- ── INFO SECTIONS ── --%>
      <div class="info-col">

        <%-- Thông tin cá nhân --%>
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

        <%-- Thông tin chuyên môn --%>
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
              <div class="field-lbl">Ngày hết hạn chứng chỉ</div>
              <div class="field-val">
                <c:choose>
                  <c:when test="${account.professionalCertExp != null}">
                    ${account.professionalCertExp.dayOfMonth}/${account.professionalCertExp.monthValue}/${account.professionalCertExp.year}
                  </c:when>
                  <c:otherwise><span class="empty">Chưa cập nhật</span></c:otherwise>
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
                  <c:otherwise><span class="empty">Chưa cập nhật</span></c:otherwise>
                </c:choose>
              </div>
            </div>
            <div class="info-field">
              <div class="field-lbl">Phân quyền hệ thống</div>
              <div class="field-val">
                <% if (a.getRoleId()==1) { %><span class="badge b-red">🛡️ Admin</span>
                <% } else if (a.getRoleId()==2) { %><span class="badge b-blue">💊 Dược sĩ bán hàng</span>
                <% } else { %><span class="badge b-gold">📦 Thủ kho</span><% } %>
              </div>
            </div>
          </div>
        </div>

        <%-- Trạng thái tài khoản --%>
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
                    ${account.createdAt.dayOfMonth}/${account.createdAt.monthValue}/${account.createdAt.year} ${account.createdAt.hour}:<c:if test="${account.createdAt.minute lt 10}">0</c:if>${account.createdAt.minute}
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
                    ${account.lastLoginAt.dayOfMonth}/${account.lastLoginAt.monthValue}/${account.lastLoginAt.year} ${account.lastLoginAt.hour}:<c:if test="${account.lastLoginAt.minute lt 10}">0</c:if>${account.lastLoginAt.minute}
                  </c:when>
                  <c:otherwise><span class="empty">Chưa đăng nhập</span></c:otherwise>
                </c:choose>
              </div>
            </div>
            <div class="info-field full">
              <div class="field-lbl">Dữ liệu khuôn mặt (chấm công)</div>
              <div class="field-val">
                <c:choose>
                  <c:when test="${not empty account.faceEnrollmentPath}">
                    <span class="badge b-green">✓ Đã đăng ký</span>
                    <span style="font-size:12px;color:var(--muted);margin-left:8px">${account.faceEnrollmentPath}</span>
                  </c:when>
                  <c:otherwise><span class="badge b-gray">Chưa đăng ký</span></c:otherwise>
                </c:choose>
              </div>
            </div>
          </div>
        </div>

      </div><%-- /info-col --%>
    </div><%-- /detail-grid --%>
  </div>
</div>

</body>
</html>
