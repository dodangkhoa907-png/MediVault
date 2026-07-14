<%@ page contentType="text/html;charset=UTF-8" %>
<% String activeNav = ""; %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length() >= 2 ? fullName.substring(0,2).toUpperCase() : fullName.toUpperCase();
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Hồ sơ Quản trị viên — MediCare</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;--surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;--green:#059669;--gold:#D97706;--red:#DC2626;--sidebar:232px;}
html,body{height:100%;font-family:'Outfit',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.btn-back{display:inline-flex;align-items:center;gap:6px;padding:6px 14px;border-radius:9px;border:1.5px solid var(--border);background:var(--white);color:var(--ink);font-size:13px;font-weight:600;text-decoration:none}
.btn-back:hover{border-color:var(--blue);color:var(--blue)}
.topbar-title{font-size:16px;font-weight:700}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.content{max-width:920px;margin:26px auto;padding:0 22px 48px;width:100%}
.hero{position:relative;border-radius:20px;overflow:hidden;margin-bottom:18px;padding:28px 30px;color:#fff;
  background:linear-gradient(120deg,#0B1628 0%,#0F2645 40%,#1558A8 115%);box-shadow:0 14px 40px rgba(11,22,40,.30)}
.hero::after{content:"";position:absolute;right:-30px;top:-50px;width:220px;height:220px;background:radial-gradient(circle,rgba(58,189,224,.25),transparent 70%);border-radius:50%}
.hero-row{display:flex;align-items:center;gap:18px;position:relative;z-index:1}
.hero-av{width:80px;height:80px;border-radius:22px;background:rgba(255,255,255,.14);border:2px solid rgba(255,255,255,.35);display:flex;align-items:center;justify-content:center;font-size:30px;font-weight:900;flex-shrink:0}
.hero-name{font-size:26px;font-weight:900;line-height:1.1}
.hero-user{font-size:13.5px;opacity:.85;margin-top:3px}
.hero-badges{display:flex;gap:8px;margin-top:11px;flex-wrap:wrap}
.hb{display:inline-flex;align-items:center;gap:5px;padding:4px 12px;border-radius:20px;font-size:12px;font-weight:800;background:rgba(220,38,38,.9)}
.hb.on{background:rgba(16,185,129,.92)}
.grid2{display:grid;grid-template-columns:1fr 1fr;gap:16px}
@media(max-width:720px){.grid2{grid-template-columns:1fr}}
.card{background:var(--white);border:1px solid var(--border);border-radius:16px;padding:20px 22px;box-shadow:0 4px 16px rgba(15,38,69,.05)}
.card-title{font-size:14px;font-weight:800;color:var(--navy);margin-bottom:14px;padding-bottom:10px;border-bottom:1px dashed var(--border);display:flex;align-items:center;gap:8px}
.row{display:flex;justify-content:space-between;gap:14px;padding:9px 0;border-bottom:1px solid #F4F7FB;font-size:13.5px}
.row:last-child{border-bottom:none}
.row .k{color:var(--muted);font-weight:600}
.row .v{font-weight:700;color:var(--ink);text-align:right;word-break:break-word}
.chip-role{display:inline-flex;align-items:center;gap:5px;padding:2px 10px;border-radius:20px;font-size:11.5px;font-weight:800;background:#FEE2E2;color:#991B1B}
.face-ok{color:var(--green)}.face-no{color:var(--muted)}
.user-av-sm{width:32px;height:32px;border-radius:50%;background:linear-gradient(135deg,#3ABDE0,#1558A8);display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
</style>
</head>
<body>
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>
<div class="main">
  <div class="topbar">
    <a href="${pageContext.request.contextPath}/dashboard" class="btn-back">← Dashboard</a>
    <span class="topbar-title">👑 Hồ sơ Quản trị viên</span>
    <div class="topbar-right"><div class="user-av-sm"><%= initials %></div></div>
  </div>

  <div class="content">
    <div class="hero">
      <div class="hero-row">
        <div class="hero-av">${fn:toUpperCase(fn:substring(admin.fullName,0,1))}</div>
        <div style="flex:1">
          <div class="hero-name">${admin.fullName}</div>
          <div class="hero-user">@${admin.username}</div>
          <div class="hero-badges">
            <span class="hb">👑 Quản trị viên</span>
            <c:choose>
              <c:when test="${admin.active}"><span class="hb on">● Đang hoạt động</span></c:when>
              <c:otherwise><span class="hb">🔒 Đã khóa</span></c:otherwise>
            </c:choose>
          </div>
        </div>
      </div>
    </div>

    <div class="grid2">
      <div class="card">
        <div class="card-title">📇 Thông tin liên hệ</div>
        <div class="row"><span class="k">Email</span><span class="v">${not empty admin.email ? admin.email : '—'}</span></div>
        <div class="row"><span class="k">Số điện thoại</span><span class="v">${not empty admin.phone ? admin.phone : '—'}</span></div>
        <div class="row"><span class="k">CCCD/CMND</span><span class="v">${not empty admin.citizenId ? admin.citizenId : '—'}</span></div>
        <div class="row"><span class="k">Chức vụ</span><span class="v">${not empty admin.position ? admin.position : 'Quản trị viên'}</span></div>
      </div>

      <div class="card">
        <div class="card-title">🔐 Tài khoản &amp; hệ thống</div>
        <div class="row"><span class="k">Account ID</span><span class="v">#${admin.accountId}</span></div>
        <div class="row"><span class="k">Phân quyền</span><span class="v"><span class="chip-role">🛡️ Admin</span></span></div>
        <div class="row"><span class="k">Ngày tạo</span><span class="v">${admin.createdAt != null ? fn:replace(fn:substring(admin.createdAt.toString(),0,16),'T',' ') : '—'}</span></div>
        <div class="row"><span class="k">Đăng nhập cuối</span><span class="v">${admin.lastLoginAt != null ? fn:replace(fn:substring(admin.lastLoginAt.toString(),0,16),'T',' ') : '—'}</span></div>
      </div>

      <div class="card">
        <div class="card-title">🎓 Chứng chỉ hành nghề</div>
        <div class="row"><span class="k">Số chứng chỉ</span><span class="v">${not empty admin.professionalCertNo ? admin.professionalCertNo : '—'}</span></div>
        <div class="row"><span class="k">Hết hạn CC</span><span class="v">${admin.professionalCertExp != null ? admin.professionalCertExp : '—'}</span></div>
      </div>

      <div class="card">
        <div class="card-title">🙂 Khuôn mặt điểm danh</div>
        <div class="row">
          <span class="k">Trạng thái</span>
          <span class="v">
            <c:choose>
              <c:when test="${admin.faceEnrolled}"><span class="face-ok">● Đã đăng ký</span></c:when>
              <c:otherwise><span class="face-no">● Chưa đăng ký</span></c:otherwise>
            </c:choose>
          </span>
        </div>
        <div class="row"><span class="k">Đăng ký lúc</span><span class="v">${admin.faceEnrolledAt != null ? fn:replace(fn:substring(admin.faceEnrolledAt.toString(),0,16),'T',' ') : '—'}</span></div>
      </div>
    </div>
  </div>
</div>
</body>
</html>
