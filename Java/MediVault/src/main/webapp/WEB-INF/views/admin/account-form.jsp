
<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ page import="java.lang.String" %>
<%
    com.medivault.entity.Account acc =
        (com.medivault.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    com.medivault.entity.Account form =
        (com.medivault.entity.Account) request.getAttribute("account");
    boolean isNew = (form == null || form.getAccountId() == 0);

    java.lang.String vUsername  = form != null && form.getUsername()  != null ? form.getUsername()  : "";
    java.lang.String vFullName  = form != null && form.getFullName()  != null ? form.getFullName()  : "";
    java.lang.String vEmail     = form != null && form.getEmail()     != null ? form.getEmail()     : "";
    java.lang.String vPhone     = form != null && form.getPhone()     != null ? form.getPhone()     : "";
    java.lang.String vCitizenId = form != null && form.getCitizenId() != null ? form.getCitizenId(): "";
    java.lang.String vPosition  = form != null && form.getPosition()  != null ? form.getPosition() : "";
    java.lang.String vCertNo    = form != null && form.getProfessionalCertNo() != null ? form.getProfessionalCertNo() : "";
    java.lang.String vCertExp   = form != null && form.getProfessionalCertExp() != null ? form.getProfessionalCertExp().toString() : "";
    java.lang.String vTraining  = form != null && form.getTrainingDate() != null ? form.getTrainingDate().toString() : "";
    int    vRoleId    = form != null ? form.getRoleId() : 2;

    @SuppressWarnings("unchecked")
    java.util.List<String> errs =
        (java.util.List<String>) request.getAttribute("errors");
    boolean hasErrors = (errs != null && !errs.isEmpty());

    java.lang.String successMsg = (java.lang.String) request.getAttribute("success");

    // Kiểm tra pending reset request
    com.medivault.entity.PasswordResetRequest pendingReset = null;
    if (!isNew && form != null && form.getAccountId() > 0) {
        com.medivault.dao.PasswordResetDAO prdao = new com.medivault.dao.PasswordResetDAO();
        pendingReset = prdao.findPendingByAccountId(form.getAccountId());
        if (pendingReset == null) pendingReset = prdao.findConfirmedByAccountId(form.getAccountId());
    }
    boolean hasPendingReset = pendingReset != null;
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%= isNew ? "Tạo tài khoản nhân viên" : "Cập nhật tài khoản" %> — MediVault</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;--cyan-soft:#EBF8FD;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;
}
html,body{min-height:100%;font-family:'Outfit',sans-serif;background:var(--surface);color:var(--ink)}
body{display:flex;flex-direction:column}

/* ── TOPBAR ── */
.topbar{
  height:60px;background:linear-gradient(90deg,#071022,#0F2645);
  display:flex;align-items:center;padding:0 28px;gap:14px;
  flex-shrink:0;box-shadow:0 2px 16px rgba(0,0,0,.2);
}
.topbar-logo{
  display:flex;align-items:center;gap:9px;text-decoration:none;
}
.logo-gem{
  width:32px;height:32px;border-radius:9px;
  background:linear-gradient(135deg,var(--cyan),var(--blue));
  display:flex;align-items:center;justify-content:center;font-size:14px;
  box-shadow:0 3px 10px rgba(58,189,224,.35);
}
.logo-wordmark{font-family:'Outfit',sans-serif;font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px}
.logo-wordmark span{color:var(--cyan)}
.topbar-sep{width:1px;height:16px;background:rgba(255,255,255,.15)}
.topbar-section{font-size:13px;font-weight:500;color:rgba(255,255,255,.5)}
.btn-back{
  margin-left:auto;display:inline-flex;align-items:center;gap:6px;
  padding:7px 14px;background:rgba(255,255,255,.08);border:1px solid rgba(255,255,255,.14);
  border-radius:8px;font-family:'Outfit',sans-serif;font-size:12.5px;font-weight:500;
  color:rgba(255,255,255,.75);text-decoration:none;transition:all .18s;
}
.btn-back:hover{background:rgba(255,255,255,.14);color:#fff}

/* ── LAYOUT ── */
.page-wrap{
  flex:1;display:flex;gap:24px;
  padding:32px 28px;max-width:1080px;width:100%;margin:0 auto;
}

/* ── INFO PANEL (left) ── */
.info-panel{width:268px;flex-shrink:0}
.info-card{
  background:linear-gradient(155deg,#0F2645 0%,#1558A8 100%);
  border-radius:20px;padding:26px 22px;color:#fff;
  position:sticky;top:24px;
  box-shadow:0 8px 32px rgba(21,88,168,.25);
}
.info-icon{
  width:50px;height:50px;background:rgba(58,189,224,.18);
  border:1.5px solid rgba(58,189,224,.35);border-radius:14px;
  display:flex;align-items:center;justify-content:center;font-size:22px;margin-bottom:16px;
}
.info-card h2{font-family:'Outfit',sans-serif;font-size:18px;font-weight:400;color:#fff;margin-bottom:8px}
.info-card>p{font-size:12.5px;line-height:1.65;color:rgba(255,255,255,.55)}

.info-steps{margin-top:22px;display:flex;flex-direction:column;gap:12px}
.info-step{display:flex;align-items:flex-start;gap:11px}
.step-num{
  width:22px;height:22px;border-radius:6px;flex-shrink:0;
  background:rgba(58,189,224,.18);border:1px solid rgba(58,189,224,.3);
  display:flex;align-items:center;justify-content:center;
  font-size:11px;font-weight:700;color:var(--cyan);
}
.step-text strong{display:block;font-size:12.5px;font-weight:600;color:#fff;margin-bottom:1px}
.step-text span{font-size:11.5px;color:rgba(255,255,255,.42);line-height:1.4}

.otp-note{
  margin-top:20px;padding:13px 15px;
  background:rgba(58,189,224,.1);border:1px solid rgba(58,189,224,.2);border-radius:11px;
}
.otp-note-title{font-size:11.5px;font-weight:700;color:var(--cyan);margin-bottom:5px;display:flex;align-items:center;gap:5px}
.otp-note p{font-size:11px;color:rgba(255,255,255,.45);line-height:1.5}

/* ── FORM PANEL (right) ── */
.form-panel{flex:1;min-width:0}

.form-heading{margin-bottom:20px}
.form-eyebrow{
  display:inline-flex;align-items:center;gap:5px;
  padding:3px 11px;background:rgba(21,88,168,.1);border:1px solid rgba(21,88,168,.15);
  border-radius:20px;font-size:11px;font-weight:700;letter-spacing:.8px;
  text-transform:uppercase;color:var(--blue);margin-bottom:10px;
}
.form-heading h1{font-family:'Outfit',sans-serif;font-size:26px;color:var(--ink);margin-bottom:4px}
.form-heading p{font-size:13px;color:var(--muted)}

/* Error block */
.pending-reset-banner{
  background:linear-gradient(90deg,rgba(245,158,11,.1),rgba(251,191,36,.06));
  border:1.5px solid rgba(245,158,11,.3);border-radius:14px;
  padding:14px 18px;margin-bottom:20px;
  display:flex;align-items:flex-start;gap:12px;
}
.pending-reset-banner-icon{font-size:20px;flex-shrink:0;margin-top:2px}
.pending-reset-banner-title{font-size:13.5px;font-weight:700;color:#92400E;margin-bottom:4px}
.pending-reset-banner-msg{font-size:12.5px;color:#78350F;line-height:1.5}
.pending-reset-banner-action{
  margin-top:10px;font-size:12px;font-weight:600;color:#B45309;
  background:rgba(245,158,11,.12);border:1px solid rgba(245,158,11,.2);
  border-radius:7px;padding:5px 12px;display:inline-block;
}
.err-block{
  background:#FEF2F2;border:1.5px solid #FECACA;border-left:3px solid var(--red);
  border-radius:12px;padding:14px 18px;margin-bottom:18px;
  animation:fadeDown .3s ease;
}
@keyframes fadeDown{from{opacity:0;transform:translateY(-6px)}to{opacity:1;transform:translateY(0)}}
.err-block-title{font-size:13px;font-weight:700;color:#991B1B;margin-bottom:7px;display:flex;align-items:center;gap:6px}
.err-block ul{list-style:none}
.err-block li{font-size:12.5px;color:var(--red);padding:2px 0;display:flex;align-items:flex-start;gap:5px}
.err-block li::before{content:'›';font-weight:800}

/* Form card */
.form-card{
  background:var(--white);border:1px solid var(--border);border-radius:18px;
  overflow:hidden;margin-bottom:16px;
  box-shadow:0 2px 8px rgba(21,88,168,.04);
}
.form-card-head{
  padding:18px 24px 15px;
  background:linear-gradient(90deg,#F5F8FD,var(--surface));
  border-bottom:1px solid var(--border);
  display:flex;align-items:center;gap:13px;
}
.form-card-head-icon{
  width:36px;height:36px;border-radius:10px;
  background:linear-gradient(135deg,var(--cyan),var(--blue));
  display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;
  box-shadow:0 3px 10px rgba(58,189,224,.25);
}
.form-card-head h2{font-family:'Outfit',sans-serif;font-size:16px;color:var(--ink);margin-bottom:2px}
.form-card-head p{font-size:12px;color:var(--muted)}

.form-body{padding:22px 24px}
.form-grid{display:grid;grid-template-columns:1fr 1fr;gap:16px}
.span-2{grid-column:1/-1}

.field{display:flex;flex-direction:column;gap:6px}
.field-label{
  font-size:12.5px;font-weight:700;color:var(--navy);letter-spacing:.2px;
  display:flex;align-items:center;gap:4px;
}
.req{color:var(--red);font-size:13px}
.hint{font-size:11px;font-weight:400;color:var(--muted)}

.field-input{
  height:42px;padding:0 14px;
  background:#fff;border:1.5px solid var(--border);border-radius:11px;
  font-family:'Outfit',sans-serif;font-size:13.5px;color:var(--ink);
  outline:none;transition:border-color .18s,box-shadow .18s;
}
.field-input:focus{border-color:var(--cyan);box-shadow:0 0 0 3px rgba(58,189,224,.12)}
.field-input::placeholder{color:#B8CCE0;font-weight:400}
.field-input[readonly]{background:var(--surface);color:var(--muted);cursor:not-allowed}

select.field-input{
  appearance:none;cursor:pointer;
  background:#fff url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='10' height='6' fill='none'%3E%3Cpath stroke='%237A90B0' stroke-width='1.5' stroke-linecap='round' d='M1 1l4 4 4-4'/%3E%3C/svg%3E") no-repeat right 13px center;
  padding-right:32px;
}

.pw-wrap{position:relative}
.pw-wrap .field-input{padding-right:44px;width:100%}
.pw-toggle{
  position:absolute;right:13px;top:50%;transform:translateY(-50%);
  background:none;border:none;cursor:pointer;font-size:15px;
  color:var(--muted);padding:0;transition:color .15s;
}
.pw-toggle:hover{color:var(--navy)}

.field-note{font-size:11.5px;color:var(--muted);display:flex;align-items:center;gap:4px}

/* Email OTP highlight */
.email-highlight .field-label::after{
  content:'· OTP sẽ gửi về đây';
  font-size:10.5px;font-weight:500;color:var(--cyan);
  background:rgba(58,189,224,.1);padding:2px 8px;border-radius:10px;margin-left:6px;
}
.email-highlight .field-input{border-color:rgba(58,189,224,.4)}
.email-highlight .field-input:focus{border-color:var(--cyan)}


/* ── Đổi MK toggle button ── */
.btn-change-pw-toggle{
  display:inline-flex;align-items:center;gap:7px;
  padding:9px 16px;border:1.5px solid #BFDBFE;border-radius:9px;
  background:#EFF6FF;color:#1558A8;font-family:'Outfit',sans-serif;
  font-size:13px;font-weight:600;cursor:pointer;transition:all .18s;
}
.btn-change-pw-toggle:hover{background:#DBEAFE;border-color:#93C5FD}
.btn-change-pw-toggle.active{background:#1558A8;color:#fff;border-color:#1558A8}
/* Action row */
.action-row{
  display:flex;align-items:center;gap:12px;
  padding:16px 24px;
  background:linear-gradient(90deg,#FAFBFD,var(--surface));
  border-top:1px solid var(--border);
}
.btn-submit{
  display:inline-flex;align-items:center;gap:8px;padding:11px 22px;
  background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;
  border:none;border-radius:11px;font-family:'Outfit',sans-serif;
  font-size:14px;font-weight:700;cursor:pointer;
  transition:all .22s;box-shadow:0 4px 14px rgba(21,88,168,.28);
}
.btn-submit:hover{transform:translateY(-1px);box-shadow:0 6px 20px rgba(21,88,168,.38)}
.btn-submit:active{transform:translateY(0)}
.btn-submit:disabled{opacity:.5;cursor:not-allowed;transform:none}
.btn-cancel{
  display:inline-flex;align-items:center;gap:6px;padding:11px 18px;
  background:var(--white);border:1.5px solid var(--border);border-radius:11px;
  font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;
  color:var(--muted);text-decoration:none;transition:all .18s;
}
.btn-cancel:hover{border-color:var(--blue);color:var(--navy)}
.action-note{margin-left:auto;font-size:12px;color:var(--muted);display:flex;align-items:center;gap:5px}

/* Toast */
#toast{
  position:fixed;top:20px;right:24px;padding:12px 20px;
  background:#064e3b;color:#fff;border-radius:11px;
  font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;
  display:flex;align-items:center;gap:8px;
  box-shadow:0 8px 32px rgba(0,0,0,.2);z-index:999;
  animation:slideIn .3s ease;transition:opacity .4s;
}
@keyframes slideIn{from{opacity:0;transform:translateX(16px)}to{opacity:1;transform:translateX(0)}}

@media(max-width:768px){
  .page-wrap{flex-direction:column;padding:20px 16px}
  .info-panel{width:100%}
  .info-card{position:static}
  .form-grid{grid-template-columns:1fr}
  .span-2{grid-column:1}
}
</style>
</head>
<body>

<!-- TOPBAR -->
<header class="topbar">
    <a href="${pageContext.request.contextPath}/dashboard" class="topbar-logo">
        <div class="logo-gem">💊</div>
        <div class="logo-wordmark">Medi<span>Vault</span></div>
    </a>
    <div class="topbar-sep"></div>
    <span class="topbar-section">Quản lý tài khoản nhân viên</span>
    <a href="${pageContext.request.contextPath}/accounts" class="btn-back">← Quay lại danh sách</a>
</header>

<!-- CONTENT -->
<div class="page-wrap">

    <!-- LEFT INFO PANEL -->
    <aside class="info-panel">
        <div class="info-card">
            <div class="info-icon"><%= isNew ? "➕" : "✏️" %></div>
            <h2><%= isNew ? "Thêm nhân viên mới" : "Chỉnh sửa tài khoản" %></h2>
            <p><%= isNew ? "Tạo tài khoản cho nhân viên mới. Admin tự cấp username và mật khẩu." : "Cập nhật thông tin tài khoản nhân viên trong hệ thống." %></p>

            <% if (isNew) { %>
            <div class="info-steps">
                <div class="info-step">
                    <div class="step-num">1</div>
                    <div class="step-text">
                        <strong>Điền thông tin</strong>
                        <span>Nhập thông tin tài khoản và cá nhân đầy đủ</span>
                    </div>
                </div>
                <div class="info-step">
                    <div class="step-num">2</div>
                    <div class="step-text">
                        <strong>Đặt mật khẩu & Tạo</strong>
                        <span>Admin cấp mật khẩu ban đầu, nhân viên đổi sau khi đăng nhập</span>
                    </div>
                </div>
            </div>
            <div class="otp-note">
                <div class="otp-note-title">🔐 Lưu ý bảo mật</div>
                <p>Mật khẩu ít nhất 6 ký tự. Khuyến nghị nhân viên <strong style="color:var(--cyan)">đổi mật khẩu</strong> ngay sau lần đăng nhập đầu tiên.</p>
            </div>
            <% } %>
        </div>
    </aside>

    <!-- FORM PANEL -->
    <section class="form-panel">

        <div class="form-heading">
            <div class="form-eyebrow"><%= isNew ? "👤 Tạo mới" : "✏️ Chỉnh sửa" %></div>
            <h1><%= isNew ? "Tạo tài khoản nhân viên" : "Cập nhật tài khoản" %></h1>
            <p><%= isNew ? "Điền đầy đủ thông tin bên dưới. Admin tự cấp mật khẩu ban đầu cho nhân viên." : "Chỉnh sửa thông tin tài khoản, sau đó lưu lại." %></p>
        </div>

        <% if (hasPendingReset) { %>
        <div class="pending-reset-banner">
          <div class="pending-reset-banner-icon">🔐</div>
          <div>
            <div class="pending-reset-banner-title">Nhân viên này đang yêu cầu đặt lại mật khẩu</div>
            <div class="pending-reset-banner-msg">
              Điền mật khẩu mới vào ô phía dưới và bấm "Lưu thay đổi" —
              hệ thống sẽ gửi OTP về Gmail của bạn để xác nhận.
            </div>
            <span class="pending-reset-banner-action">⏳ Trạng thái: <%= pendingReset.getStatus() %></span>
          </div>
        </div>
        <% } %>

        <% if (hasErrors) { %>
        <div class="err-block">
            <div class="err-block-title">⚠️ Vui lòng kiểm tra lại thông tin</div>
            <ul>
                <% for (String err : errs) { %>
                <li><%= err %></li>
                <% } %>
            </ul>
            <% if (isNew) { %>
            <div style="font-size:12px;color:#92400E;margin-top:8px;padding-top:8px;border-top:1px solid #FECACA">
                💡 Thông tin đã được giữ lại — chỉ cần nhập lại <strong>mật khẩu</strong> và bấm gửi lại.
            </div>
            <% } %>
        </div>
        <% } %>

        <form method="post" action="${pageContext.request.contextPath}/accounts" novalidate id="mainForm">
            <c:if test="${not empty account and account.accountId > 0}">
                <input type="hidden" name="accountId" value="${account.accountId}">
            </c:if>
            <input type="hidden" name="action" value="<%= isNew ? "create" : "update" %>">

            <!-- Card 1: Thông tin đăng nhập -->
            <div class="form-card">
                <div class="form-card-head">
                    <div class="form-card-head-icon">🔑</div>
                    <div>
                        <h2>Thông tin đăng nhập</h2>
                        <p>Username, mật khẩu và phân quyền hệ thống</p>
                    </div>
                </div>
                <div class="form-body">
                    <div class="form-grid">
                        <div class="field">
                            <label class="field-label" for="username">Tên đăng nhập <span class="req">*</span></label>
                            <input type="text" id="username" name="username" class="field-input"
                                   value="<%= vUsername %>" placeholder="vd: nhanvien01"
                                   <%= isNew ? "required" : "readonly" %> autocomplete="username">
                            <% if (!isNew) { %><span class="field-note">ℹ️ Username không thể thay đổi sau khi tạo.</span><% } %>
                        </div>
                        <div class="field">
                            <label class="field-label" for="roleId">Phân quyền <span class="req">*</span></label>
                            <select id="roleId" name="roleId" class="field-input" required>
                                <option value="2" <%= vRoleId == 2 ? "selected" : "" %>>💊 Dược sĩ bán hàng</option>
                                <option value="3" <%= vRoleId == 3 ? "selected" : "" %>>📦 Thủ kho</option>
                            </select>
                        </div>
                        <% if (isNew) { %>
                        <%-- TẠO MỚI: nhập MK bình thường --%>
                        <div class="field span-2">
                            <label class="field-label" for="password">Mật khẩu <span class="req">*</span></label>
                            <div class="pw-wrap">
                                <input type="password" id="password" name="password" class="field-input"
                                       placeholder="Ít nhất 6 ký tự" required minlength="6" autocomplete="new-password">
                                <button type="button" class="pw-toggle" id="togglePw" title="Hiện/ẩn">👁</button>
                            </div>
                        </div>
                        <% } else { %>
                        <%-- CHỈNH SỬA: section đổi MK riêng, ẩn mặc định --%>
                        <input type="hidden" name="password" id="passwordHidden" value="">
                        <input type="hidden" name="confirmWord" id="confirmWordHidden" value="">
                        <div class="field span-2">
                            <label class="field-label">Đổi mật khẩu
                                <span class="hint" style="font-weight:400">(để trống = không đổi)</span>
                            </label>
                            <button type="button" class="btn-change-pw-toggle" id="toggleChangePwBtn"
                                    onclick="toggleChangePwSection()">
                                🔐 Mở rộng để đổi mật khẩu
                            </button>
                            <div id="changePwSection" style="display:none;margin-top:12px">
                                <div style="background:#EFF6FF;border:1.5px solid #BFDBFE;border-radius:12px;padding:16px 18px">
                                    <div style="display:flex;flex-direction:column;gap:10px">
                                        <div class="fg-inline">
                                            <label style="font-size:11px;font-weight:700;color:#64748B;text-transform:uppercase;letter-spacing:.5px;margin-bottom:4px;display:block">
                                                Mật khẩu mới <span style="color:#DC2626">*</span>
                                            </label>
                                            <div class="pw-wrap">
                                                <input type="password" id="newPasswordInput" class="field-input"
                                                       placeholder="Ít nhất 6 ký tự" minlength="6" autocomplete="new-password"
                                                       oninput="syncPwFields()">
                                                <button type="button" class="pw-toggle" id="togglePw" title="Hiện/ẩn">👁</button>
                                            </div>
                                        </div>
                                        <div class="fg-inline">
                                            <label style="font-size:11px;font-weight:700;color:#64748B;text-transform:uppercase;letter-spacing:.5px;margin-bottom:4px;display:block">
                                                Xác nhận đổi — gõ chữ <strong style="color:#1558A8;font-family:monospace">update</strong>
                                            </label>
                                            <input type="text" id="confirmWordInput" class="field-input"
                                                   placeholder='Gõ "update" để xác nhận đổi mật khẩu'
                                                   autocomplete="off" oninput="syncPwFields(); checkConfirmWord(this)">
                                            <div id="confirmWordHint" style="font-size:12px;margin-top:5px"></div>
                                        </div>
                                    </div>
                                    <p style="font-size:12px;color:#7A90B0;margin-top:12px">
                                        🔒 Sau khi bấm <strong>Lưu thay đổi</strong>, OTP sẽ gửi về <strong>Gmail admin</strong> để xác nhận.
                                    </p>
                                </div>
                            </div>
                        </div>
                        <% } %>
                    </div>
                </div>
            </div>

            <!-- Card 2: Thông tin cá nhân -->
            <div class="form-card">
                <div class="form-card-head">
                    <div class="form-card-head-icon">👤</div>
                    <div>
                        <h2>Thông tin cá nhân</h2>
                        <p>Họ tên, email, số điện thoại và CCCD</p>
                    </div>
                </div>
                <div class="form-body">
                    <div class="form-grid">
                        <div class="field span-2">
                            <label class="field-label" for="fullName">Họ và tên đầy đủ <span class="req">*</span></label>
                            <input type="text" id="fullName" name="fullName" class="field-input"
                                   value="<%= vFullName %>" placeholder="Nguyễn Văn A" required>
                        </div>
                        <div class="field <%= isNew ? "email-highlight" : "" %>">
                            <label class="field-label" for="email">Email <%= isNew ? "<span class='req'>*</span>" : "" %></label>
                            <input type="email" id="email" name="email" class="field-input"
                                   value="<%= vEmail %>" placeholder="example@gmail.com"
                                   <%= isNew ? "required" : "" %>>
                            <% if (isNew) { %><span class="field-note">📧 Email liên lạc của nhân viên (dùng để nhận thông báo hệ thống).</span><% } %>
                        </div>
                        <div class="field">
                            <label class="field-label" for="phone">Số điện thoại</label>
                            <input type="tel" id="phone" name="phone" class="field-input"
                                   value="<%= vPhone %>" placeholder="0901234567" pattern="0[0-9]{9}">
                        </div>
                        <div class="field">
                            <label class="field-label" for="citizenId">CMND / CCCD</label>
                            <input type="text" id="citizenId" name="citizenId" class="field-input"
                                   value="<%= vCitizenId %>" placeholder="9 hoặc 12 chữ số"
                                   maxlength="12" pattern="[0-9]{9}|[0-9]{12}">
                        </div>
                        <%-- Ô Chức vụ/Bộ phận đã bỏ: phân quyền đã xác định qua roleId --%>
                        <input type="hidden" name="position" value="<%= vPosition %>">
                    </div>
                </div>

                <div class="action-row">
                    <% if (isNew) { %>
                    <%-- Khi tạo mới: 2 nút --%>
                    <button type="submit" name="redirect" value="schedule" class="btn-submit" id="submitBtn">
                        📅 Lưu &amp; Xếp lịch ngay
                    </button>
                    <button type="submit" name="redirect" value="more"
                            class="btn-submit" id="submitBtnMore"
                            style="background:var(--surface);color:var(--blue);border:2px solid var(--blue);margin-left:10px">
                        ➕ Lưu &amp; Thêm tiếp
                    </button>
                    <% } else { %>
                    <%-- Khi chỉnh sửa: 1 nút bình thường --%>
                    <button type="submit" class="btn-submit" id="submitBtn">
                        💾 Lưu thay đổi
                    </button>
                    <% } %>
                    <a href="${pageContext.request.contextPath}/accounts" class="btn-cancel">Hủy</a>
                </div>
            </div>

        </form>
    </section>
</div>

<% java.lang.String msg = request.getParameter("msg"); %>
<% if ("updated".equals(msg)) { %>
<div id="toast">✅ Đã cập nhật tài khoản thành công!</div>
<% } %>

<script>
// ── Toggle show/hide password (tạo mới) ──
const togglePwBtn = document.getElementById('togglePw');
if (togglePwBtn) togglePwBtn.addEventListener('click', function() {
    const target = document.getElementById('newPasswordInput') || document.getElementById('password');
    if (!target) return;
    const show = target.type === 'password';
    target.type = show ? 'text' : 'password';
    this.textContent = show ? '🙈' : '👁';
});

// ── Toast auto-hide ──
const toast = document.getElementById('toast');
if (toast) setTimeout(() => { toast.style.opacity='0'; setTimeout(()=>toast.remove(),400); }, 3500);

// ── Highlight lỗi ──
<% if (hasErrors) { %>
const errorText = `<%= errs != null ? java.lang.String.join("|", errs).toLowerCase() : "" %>`;
const fieldMap = {
    username: ['tên đăng nhập','username'], email: ['email'],
    phone: ['điện thoại','phone'], citizenId: ['cmnd','cccd'],
    fullName: ['họ tên','họ và tên'], password: ['mật khẩu']
};
Object.entries(fieldMap).forEach(([id, kws]) => {
    if (kws.some(kw => errorText.includes(kw))) {
        const el = document.getElementById(id);
        if (el) { el.style.borderColor='#ef4444'; el.style.boxShadow='0 0 0 3px rgba(239,68,68,.12)'; el.focus(); }
    }
});
<% } %>

// ── Validate email format ──
const emailInput = document.getElementById('email');
if (emailInput) {
    emailInput.addEventListener('blur', function() {
        const val = this.value;
        if (val && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(val)) {
            this.style.borderColor='#ef4444'; this.title='Email không hợp lệ';
        } else { this.style.borderColor=''; this.title=''; }
    });
}

// ── Chỉ cho nhập số điện thoại ──
const phoneInput = document.getElementById('phone');
if (phoneInput) phoneInput.addEventListener('input', function() {
    this.value = this.value.replace(/[^0-9]/g,'').slice(0,10);
});

<% if (!isNew) { %>
// ── Toggle section đổi MK ──
function toggleChangePwSection() {
    const sec = document.getElementById('changePwSection');
    const btn = document.getElementById('toggleChangePwBtn');
    const isOpen = sec.style.display !== 'none';
    sec.style.display = isOpen ? 'none' : 'block';
    btn.classList.toggle('active', !isOpen);
    btn.textContent = isOpen ? '🔐 Mở rộng để đổi mật khẩu' : '✖ Đóng';
    if (isOpen) {
        // Reset khi đóng
        document.getElementById('newPasswordInput').value = '';
        document.getElementById('confirmWordInput').value = '';
        document.getElementById('passwordHidden').value = '';
        document.getElementById('confirmWordHidden').value = '';
        document.getElementById('confirmWordHint').textContent = '';
    }
}

// ── Sync giá trị vào hidden fields ──
function syncPwFields() {
    const pw  = document.getElementById('newPasswordInput').value;
    const cw  = document.getElementById('confirmWordInput').value.trim().toLowerCase();
    document.getElementById('passwordHidden').value    = pw;
    document.getElementById('confirmWordHidden').value = cw;
}

// ── Check confirmWord feedback ──
function checkConfirmWord(inp) {
    const hint = document.getElementById('confirmWordHint');
    const val  = inp.value.trim().toLowerCase();
    if (!val) { hint.textContent = ''; inp.style.borderColor = ''; return; }
    if (val === 'update') {
        hint.innerHTML = '✅ <span style="color:#059669;font-weight:600">Xác nhận — OTP sẽ gửi về Gmail admin khi bấm Lưu.</span>';
        inp.style.borderColor = '#059669';
    } else {
        hint.innerHTML = '❌ <span style="color:#DC2626;font-weight:600">Phải gõ đúng chữ <code>update</code> (viết thường).</span>';
        inp.style.borderColor = '#DC2626';
    }
}

// ── Submit handler ──
document.getElementById('mainForm').addEventListener('submit', function(e) {
    const changePwOpen = document.getElementById('changePwSection').style.display !== 'none';

    if (changePwOpen) {
        // Đang muốn đổi MK
        const pw = document.getElementById('newPasswordInput').value;
        const cw = document.getElementById('confirmWordInput').value.trim().toLowerCase();

        if (!pw || pw.length < 6) {
            e.preventDefault();
            alert('Mật khẩu mới phải có ít nhất 6 ký tự!');
            document.getElementById('newPasswordInput').focus();
            return;
        }
        if (cw !== 'update') {
            e.preventDefault();
            document.getElementById('confirmWordHint').innerHTML =
                '❌ <span style="color:#DC2626;font-weight:600">Phải gõ đúng chữ <code>update</code> để xác nhận!</span>';
            document.getElementById('confirmWordInput').focus();
            return;
        }
        syncPwFields();
        // Tiếp tục submit — Servlet sẽ xử lý OTP
    } else {
        // Chỉ sửa thông tin thường — confirm popup
        if (!confirm('Xác nhận lưu thay đổi thông tin tài khoản?')) {
            e.preventDefault();
            return;
        }
        // Đảm bảo password và confirmWord trống
        document.getElementById('passwordHidden').value    = '';
        document.getElementById('confirmWordHidden').value = '';
    }

    const btn = document.getElementById('submitBtn');
    if (btn) { btn.disabled = true; btn.innerHTML = '⏳ Đang lưu…'; }
});
<% } else { %>
// ── Tạo mới: disable double-submit ──
document.getElementById('mainForm').addEventListener('submit', function() {
    const btn = document.getElementById('submitBtn');
    if (btn) { btn.disabled = true; btn.innerHTML = '⏳ Đang tạo…'; }
});
<% } %>
</script>
</body>
</html>
