
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
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&family=DM+Serif+Display:ital@0;1&display=swap" rel="stylesheet">
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
.info-card h2{font-family:'DM Serif Display',serif;font-size:18px;font-weight:400;color:#fff;margin-bottom:8px}
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
.form-heading h1{font-family:'DM Serif Display',serif;font-size:26px;color:var(--ink);margin-bottom:4px}
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
.form-card-head h2{font-family:'DM Serif Display',serif;font-size:16px;color:var(--ink);margin-bottom:2px}
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

/* OTP inline box */
#otpBox{
  margin:0 24px 16px;padding:16px 18px;
  background:#F0FDF4;border:1.5px solid #86EFAC;border-radius:12px;
}
#otpBox p:first-child{font-size:13px;font-weight:600;color:#166534;margin-bottom:10px}
.otp-inline-row{display:flex;gap:10px;align-items:center}
#otpInput{
  width:140px;padding:10px 14px;
  border:1.5px solid #86EFAC;border-radius:9px;
  font-family:'DM Serif Display',serif;font-size:22px;
  letter-spacing:6px;text-align:center;outline:none;
  transition:border-color .18s;
}
#otpInput:focus{border-color:#059669;box-shadow:0 0 0 3px rgba(5,150,105,.12)}
.btn-otp-verify{
  padding:10px 16px;background:#059669;color:#fff;
  border:none;border-radius:9px;font-family:'Outfit',sans-serif;
  font-size:13px;font-weight:600;cursor:pointer;transition:background .18s;
}
.btn-otp-verify:hover{background:#047857}
.btn-otp-verify:disabled{opacity:.5;cursor:not-allowed}
.btn-otp-resend{
  padding:10px 13px;background:transparent;color:#059669;
  border:1.5px solid #86EFAC;border-radius:9px;
  font-family:'Outfit',sans-serif;font-size:12px;cursor:pointer;transition:all .18s;
}
.btn-otp-resend:hover{background:#F0FDF4}
#otpMsg{font-size:12px;margin-top:8px;display:none}

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
            <p><%= isNew ? "Tạo tài khoản cho nhân viên mới. Hệ thống sẽ gửi mã OTP xác nhận qua email." : "Cập nhật thông tin tài khoản nhân viên trong hệ thống." %></p>

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
                        <strong>Gửi OTP</strong>
                        <span>Hệ thống tự động gửi mã xác nhận 6 số về email nhân viên</span>
                    </div>
                </div>
                <div class="info-step">
                    <div class="step-num">3</div>
                    <div class="step-text">
                        <strong>Xác nhận & Tạo</strong>
                        <span>Nhập mã OTP để kích hoạt tài khoản</span>
                    </div>
                </div>
            </div>
            <div class="otp-note">
                <div class="otp-note-title">📧 Lưu ý về OTP</div>
                <p>Email nhân viên phải hợp lệ. Mã OTP có hiệu lực trong <strong style="color:var(--cyan)">5 phút</strong>.</p>
            </div>
            <% } %>
        </div>
    </aside>

    <!-- FORM PANEL -->
    <section class="form-panel">

        <div class="form-heading">
            <div class="form-eyebrow"><%= isNew ? "👤 Tạo mới" : "✏️ Chỉnh sửa" %></div>
            <h1><%= isNew ? "Tạo tài khoản nhân viên" : "Cập nhật tài khoản" %></h1>
            <p><%= isNew ? "Điền đầy đủ thông tin bên dưới. OTP sẽ được gửi tới email nhân viên." : "Chỉnh sửa thông tin tài khoản, sau đó lưu lại." %></p>
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
            <input type="hidden" name="action" value="<%= isNew ? "create-otp" : "update" %>">

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
                        <div class="field span-2">
                            <label class="field-label" for="password">
                                Mật khẩu
                                <%= isNew ? "<span class='req'>*</span>" : "<span class='hint'>(để trống nếu không muốn đổi)</span>" %>
                            </label>
                            <% if (isNew) { %>
                            <%-- TẠO MỚI: nhập mật khẩu thực --%>
                            <div class="pw-wrap">
                                <input type="password" id="password" name="password" class="field-input"
                                       placeholder="Ít nhất 6 ký tự, không có khoảng trắng"
                                       required minlength="6" autocomplete="new-password">
                                <button type="button" class="pw-toggle" id="togglePw" title="Hiện/ẩn mật khẩu">👁</button>
                            </div>
                            <% } else { %>
                            <%-- CHỈNH SỬA: nhập từ khóa "update" để xác nhận đổi mật khẩu --%>
                            <input type="text" id="passwordTrigger" name="password" class="field-input"
                                   placeholder='Gõ "update" để đổi mật khẩu qua OTP'
                                   autocomplete="off" style="letter-spacing:.5px"
                                   oninput="checkUpdateTrigger(this)">
                            <div id="updateTriggerHint" style="margin-top:6px;font-size:12px"></div>
                            <span class="field-note" style="color:#1558A8;margin-top:6px;display:block">
                              🔐 Nhập <strong>"update"</strong> rồi bấm "Lưu thay đổi" — OTP sẽ gửi về Gmail của bạn để xác nhận.
                            </span>
                            <% } %>
                        </div>
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
                            <% if (isNew) { %><span class="field-note">📧 OTP 6 số sẽ được gửi tới email này để xác nhận.</span><% } %>
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
                        <div class="field">
                            <label class="field-label" for="position">Chức vụ / Bộ phận</label>
                            <input type="text" id="position" name="position" class="field-input"
                                   value="<%= vPosition %>" placeholder="Dược sĩ bán hàng, Thủ kho…">
                        </div>
                    </div>
                </div>

                <input type="hidden" name="otpVerified" id="otpVerified" value="false">

                <div id="otpBox" style="display:none">
                    <p>📧 Mã OTP đã được gửi về email. Nhập mã để xác nhận thay đổi:</p>
                    <div class="otp-inline-row">
                        <input type="text" id="otpInput" maxlength="6" placeholder="000000">
                        <button type="button" class="btn-otp-verify" id="verifyOtpBtn" onclick="verifyOtp()">✅ Xác nhận</button>
                        <button type="button" class="btn-otp-resend" onclick="resendOtp()">🔄 Gửi lại</button>
                    </div>
                    <p id="otpMsg"></p>
                </div>

                <div class="action-row">
                    <button type="submit" class="btn-submit" id="submitBtn">
                        <%= isNew ? "📧 Tạo & Gửi mã OTP" : "💾 Lưu thay đổi" %>
                    </button>
                    <a href="${pageContext.request.contextPath}/accounts" class="btn-cancel">Hủy</a>
                    <% if (isNew) { %><span class="action-note">🔒 OTP sẽ gửi qua Gmail nhân viên</span><% } %>
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
document.getElementById('togglePw').addEventListener('click', function() {
    const pw = document.getElementById('password');
    const show = pw.type === 'password';
    pw.type = show ? 'text' : 'password';
    this.textContent = show ? '🙈' : '👁';
});

const toast = document.getElementById('toast');
if (toast) setTimeout(() => { toast.style.opacity='0'; setTimeout(()=>toast.remove(),400); }, 3500);

<% if (hasErrors) { %>
const errorText = `<%= errs != null ? String.join("|", errs).toLowerCase() : "" %>`;
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

const emailInput = document.getElementById('email');
if (emailInput) {
    emailInput.addEventListener('blur', function() {
        const val = this.value;
        if (val && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(val)) {
            this.style.borderColor='#ef4444'; this.title='Email không hợp lệ';
        } else { this.style.borderColor=''; this.title=''; }
    });
}

const phoneInput = document.getElementById('phone');
if (phoneInput) phoneInput.addEventListener('input', function() { this.value=this.value.replace(/[^0-9]/g,'').slice(0,10); });

<% if (!isNew) { %>
const origEmail = '<%= vEmail %>'.trim();
const origPhone = '<%= vPhone %>'.trim();
let otpSent = false;
let otpVerifiedOk = false;

function emailOrPhoneChanged() {
    const curEmail = (document.getElementById('email')?.value||'').trim();
    const curPhone = (document.getElementById('phone')?.value||'').trim();
    return curEmail !== origEmail || curPhone !== origPhone;
}

// ── Kiểm tra trigger "update" cho field mật khẩu khi edit ──
function checkUpdateTrigger(inp) {
    const hint = document.getElementById('updateTriggerHint');
    const val  = inp.value.toLowerCase().trim();
    if (!val) {
        hint.textContent = '';
        inp.style.borderColor = '';
        return;
    }
    if (val === 'update') {
        hint.innerHTML = '✅ <span style="color:#059669;font-weight:600">Xác nhận — OTP sẽ gửi về Gmail của bạn khi bấm Lưu.</span>';
        inp.style.borderColor = '#059669';
        inp.style.boxShadow   = '0 0 0 3px rgba(5,150,105,.1)';
    } else {
        hint.innerHTML = '❌ <span style="color:#DC2626;font-weight:600">Phải gõ đúng chữ <strong>"update"</strong> (không phân biệt hoa thường).</span>';
        inp.style.borderColor = '#DC2626';
        inp.style.boxShadow   = '0 0 0 3px rgba(220,38,38,.1)';
    }
}

document.getElementById('mainForm').addEventListener('submit', async function(e) {
    // Kiểm tra trigger field "update" khi edit
    const triggerInp = document.getElementById('passwordTrigger');
    if (triggerInp) {
        const val = triggerInp.value.trim();
        if (val !== '' && val.toLowerCase() !== 'update') {
            e.preventDefault();
            const hint = document.getElementById('updateTriggerHint');
            hint.innerHTML = '❌ <span style="color:#DC2626;font-weight:600">Phải gõ đúng chữ <strong>"update"</strong> để xác nhận đổi mật khẩu!</span>';
            triggerInp.style.borderColor = '#DC2626';
            triggerInp.focus();
            return;
        }
        // Nếu để trống → không đổi mk, xóa giá trị trước khi submit
        if (val === '') {
            triggerInp.value = '';
        }
    }

    if (emailOrPhoneChanged() && !otpVerifiedOk) {
        e.preventDefault();
        if (!otpSent) await sendOtp();
        return;
    }
    const btn = document.getElementById('submitBtn');
    btn.disabled=true; btn.innerHTML='⏳ Đang lưu…';
});

async function sendOtp() {
    const btn = document.getElementById('submitBtn');
    btn.disabled=true; btn.innerHTML='📧 Đang gửi OTP…';
    const formData = new FormData(document.getElementById('mainForm'));
    const params = new URLSearchParams(formData);
    params.set('action','send-otp');
    try {
        const res = await fetch('<%= request.getContextPath() %>/accounts', {
            method:'POST', body:params, headers:{'Content-Type':'application/x-www-form-urlencoded'}
        });
        const data = await res.json();
        if (data.ok) {
            otpSent=true;
            document.getElementById('otpBox').style.display='block';
            btn.disabled=false; btn.innerHTML='💾 Lưu thay đổi';
            showOtpMsg('Mã OTP đã gửi — kiểm tra email!','#166534');
        } else {
            showOtpMsg('Lỗi: '+data.msg,'#dc2626');
            btn.disabled=false; btn.innerHTML='💾 Lưu thay đổi';
        }
    } catch(err) {
        showOtpMsg('Không gửi được OTP!','#dc2626');
        btn.disabled=false; btn.innerHTML='💾 Lưu thay đổi';
    }
}

async function verifyOtp() {
    const code = document.getElementById('otpInput').value.trim();
    if (code.length!==6) { showOtpMsg('Nhập đủ 6 chữ số!','#dc2626'); return; }
    const btn = document.getElementById('verifyOtpBtn');
    btn.disabled=true; btn.innerHTML='⏳';
    try {
        const res = await fetch('<%= request.getContextPath() %>/accounts', {
            method:'POST', headers:{'Content-Type':'application/x-www-form-urlencoded'},
            body:'action=verify-otp&otpCode='+encodeURIComponent(code)+'&accountId=<%= form!=null?form.getAccountId():0 %>'
        });
        const data = await res.json();
        if (data.ok) {
            otpVerifiedOk=true;
            document.getElementById('otpVerified').value='true';
            document.getElementById('otpBox').innerHTML='<p style="color:#166534;font-weight:700">✅ Xác minh thành công!</p>';
            document.getElementById('mainForm').submit();
        } else {
            showOtpMsg('Mã không đúng hoặc đã hết hạn!','#dc2626');
            btn.disabled=false; btn.innerHTML='✅ Xác nhận';
        }
    } catch(err) {
        showOtpMsg('Lỗi xác minh!','#dc2626');
        btn.disabled=false; btn.innerHTML='✅ Xác nhận';
    }
}

async function resendOtp() {
    otpSent=false;
    document.getElementById('otpInput').value='';
    showOtpMsg('','');
    await sendOtp();
}

function showOtpMsg(msg, color) {
    const el = document.getElementById('otpMsg');
    el.textContent=msg; el.style.color=color;
    el.style.display=msg?'block':'none';
}
<% } %>
</script>
</body>
</html>
