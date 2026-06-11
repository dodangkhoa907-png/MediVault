<%@ page contentType="text/html;charset=UTF-8" %>
<%
    com.medicare.entity.Account admin = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (admin == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    Boolean otpVerified = (Boolean) session.getAttribute("adminResetOtpVerified");
    if (!Boolean.TRUE.equals(otpVerified)) {
        response.sendRedirect(request.getContextPath() + "/accounts");
        return;
    }

    com.medicare.entity.Account staffInfo = (com.medicare.entity.Account) request.getAttribute("staffInfo");
    if (staffInfo == null) { response.sendRedirect(request.getContextPath() + "/accounts"); return; }

    String staffName  = staffInfo.getFullName() != null ? staffInfo.getFullName() : staffInfo.getUsername();
    String staffEmail = staffInfo.getEmail()    != null ? staffInfo.getEmail()    : "—";
    String staffPhone = staffInfo.getPhone()    != null ? staffInfo.getPhone()    : "—";
    String staffPos   = staffInfo.getPosition() != null ? staffInfo.getPosition() : "—";
    String staffCid   = staffInfo.getCitizenId()!= null ? staffInfo.getCitizenId(): "—";
    String roleName   = staffInfo.getRoleId()==1 ? "Admin" : staffInfo.getRoleId()==2 ? "Dược sĩ bán hàng" : "Thủ kho";

    String av = staffName.length() >= 2
        ? staffName.substring(0,1).toUpperCase() + staffName.substring(1,2).toUpperCase()
        : staffName.toUpperCase();

    String errMsg = (String) request.getAttribute("error");

    Boolean isResetFlow = (Boolean) session.getAttribute("adminResetIsResetFlow");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Đặt mật khẩu mới — medicare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&family=DM+Serif+Display:ital@0;1&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;--cyan-soft:#EBF8FD;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;
}
html,body{min-height:100%;font-family:'Outfit',sans-serif;background:var(--surface)}
body{
  min-height:100vh;display:flex;align-items:center;justify-content:center;
  padding:32px 16px;
}

.container{width:100%;max-width:600px;animation:fadeUp .4s ease both}
@keyframes fadeUp{from{opacity:0;transform:translateY(18px)}to{opacity:1;transform:translateY(0)}}

/* Header */
.page-header{
  background:linear-gradient(135deg,var(--navy),var(--blue));
  border-radius:18px 18px 0 0;padding:24px 28px;color:#fff;
}
.page-header-top{display:flex;align-items:center;gap:12px;margin-bottom:4px}
.back-btn{
  background:rgba(255,255,255,.12);border:1px solid rgba(255,255,255,.2);
  border-radius:8px;padding:6px 12px;color:#fff;font-size:12px;font-weight:600;
  text-decoration:none;transition:background .2s;
}
.back-btn:hover{background:rgba(255,255,255,.2)}
.step-badge{
  background:rgba(255,255,255,.15);border:1px solid rgba(255,255,255,.25);
  border-radius:20px;padding:4px 12px;font-size:11.5px;font-weight:600;
}
.page-title{font-family:'DM Serif Display',serif;font-size:24px;margin-top:8px}
.page-sub{font-size:13px;opacity:.7;margin-top:4px}

/* Main card */
.main-card{
  background:#fff;border-radius:0 0 18px 18px;
  box-shadow:0 8px 32px rgba(21,88,168,.1);
  overflow:hidden;
}

/* Staff info section */
.staff-info-section{
  background:linear-gradient(135deg,rgba(21,88,168,.04),rgba(58,189,224,.03));
  border-bottom:1px solid var(--border);padding:20px 28px;
}
.staff-info-title{font-size:11px;font-weight:700;letter-spacing:1.2px;
  text-transform:uppercase;color:var(--muted);margin-bottom:14px}
.staff-profile-row{display:flex;align-items:center;gap:14px;margin-bottom:16px}
.staff-av{
  width:48px;height:48px;border-radius:13px;flex-shrink:0;
  background:linear-gradient(135deg,var(--cyan),var(--blue));
  display:flex;align-items:center;justify-content:center;
  font-size:16px;font-weight:800;color:#fff;
  box-shadow:0 4px 14px rgba(21,88,168,.25);
}
.staff-name{font-size:16px;font-weight:700;color:var(--navy)}
.staff-username{font-size:12px;color:var(--muted);margin-top:2px}
.staff-role-badge{
  display:inline-flex;align-items:center;gap:4px;
  padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:600;
  background:rgba(21,88,168,.08);color:var(--blue);margin-top:4px;
}
.info-grid{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.info-item{background:#fff;border:1px solid var(--border);border-radius:10px;padding:10px 14px}
.info-label{font-size:11px;font-weight:600;color:var(--muted);letter-spacing:.5px;text-transform:uppercase;margin-bottom:3px}
.info-value{font-size:13px;font-weight:600;color:var(--ink)}

/* Reset flow banner */
.reset-banner{
  background:linear-gradient(90deg,rgba(245,158,11,.08),rgba(251,191,36,.05));
  border-left:3px solid #F59E0B;
  padding:12px 20px;font-size:13px;color:#78350F;font-weight:500;
  display:flex;align-items:center;gap:8px;
}

/* Form section */
.form-section{padding:24px 28px}
.form-section-title{font-size:13px;font-weight:700;color:var(--navy);
  display:flex;align-items:center;gap:7px;margin-bottom:18px}
.form-section-title::before{content:'';width:4px;height:16px;background:var(--blue);border-radius:2px}

.field{margin-bottom:16px}
.field-label{font-size:12.5px;font-weight:600;color:var(--navy);display:block;margin-bottom:6px}
.field-hint{font-size:11px;color:var(--muted);margin-top:4px}
.pw-wrap{position:relative}
.field-input{
  width:100%;padding:12px 44px 12px 14px;
  background:#fff;border:1.5px solid var(--border);border-radius:11px;
  font-family:'Outfit',sans-serif;font-size:14px;font-weight:500;color:var(--ink);
  outline:none;transition:all .2s;
}
.field-input:focus{border-color:var(--blue);box-shadow:0 0 0 3px rgba(21,88,168,.1)}
.field-input.err{border-color:var(--red);box-shadow:0 0 0 3px rgba(220,38,38,.1)}
.pw-toggle{
  position:absolute;right:12px;top:50%;transform:translateY(-50%);
  background:none;border:none;cursor:pointer;font-size:16px;opacity:.4;transition:opacity .2s;
}
.pw-toggle:hover{opacity:.8}

/* Strength meter */
.strength-meter{margin-top:7px}
.strength-bar{
  height:3px;border-radius:2px;transition:width .3s ease, background .3s ease;
  width:0;
}
.strength-text{font-size:11px;margin-top:4px;font-weight:600}

/* Match indicator */
.match-indicator{font-size:11.5px;margin-top:5px;font-weight:600;
  display:flex;align-items:center;gap:4px}

.err-box{
  background:#FEF2F2;border:1px solid #FECACA;border-radius:10px;
  padding:11px 16px;margin-bottom:16px;font-size:13px;color:#991B1B;
  font-weight:500;display:flex;align-items:center;gap:8px;
}

.action-row{display:flex;gap:10px;margin-top:20px}
.btn-submit{
  flex:1;padding:13px;background:linear-gradient(135deg,var(--blue),#0D3F85);
  color:#fff;border:none;border-radius:11px;font-family:'Outfit',sans-serif;
  font-size:15px;font-weight:700;cursor:pointer;transition:all .22s;
  box-shadow:0 4px 14px rgba(21,88,168,.25);
}
.btn-submit:hover{transform:translateY(-1px);box-shadow:0 6px 20px rgba(21,88,168,.35)}
.btn-submit:disabled{opacity:.6;cursor:not-allowed;transform:none}
.btn-cancel{
  padding:13px 20px;background:#fff;color:var(--muted);border:1.5px solid var(--border);
  border-radius:11px;font-family:'Outfit',sans-serif;font-size:14px;font-weight:600;
  cursor:pointer;transition:all .2s;text-decoration:none;display:flex;align-items:center;
}
.btn-cancel:hover{border-color:var(--blue);color:var(--blue)}
</style>
</head>
<body>
<div class="container">

  <!-- Header -->
  <div class="page-header">
    <div class="page-header-top">
      <a href="${pageContext.request.contextPath}/accounts" class="back-btn">← Quay lại</a>
      <span class="step-badge">✅ Bước 2 / 2 — Đặt mật khẩu mới</span>
    </div>
    <div class="page-title">Đặt mật khẩu mới</div>
    <div class="page-sub">OTP đã xác nhận — Nhập mật khẩu mới cho nhân viên bên dưới</div>
  </div>

  <div class="main-card">

    <!-- Staff info -->
    <div class="staff-info-section">
      <div class="staff-info-title">Thông tin nhân viên</div>
      <div class="staff-profile-row">
        <div class="staff-av"><%= av %></div>
        <div>
          <div class="staff-name"><%= staffName %></div>
          <div class="staff-username">@<%= staffInfo.getUsername() %></div>
          <div class="staff-role-badge">
            <%= staffInfo.getRoleId()==2 ? "💊" : "📦" %> <%= roleName %>
          </div>
        </div>
      </div>
      <div class="info-grid">
        <div class="info-item">
          <div class="info-label">Email</div>
          <div class="info-value"><%= staffEmail %></div>
        </div>
        <div class="info-item">
          <div class="info-label">Số điện thoại</div>
          <div class="info-value"><%= staffPhone %></div>
        </div>
        <div class="info-item">
          <div class="info-label">CCCD / CMND</div>
          <div class="info-value"><%= staffCid %></div>
        </div>
        <div class="info-item">
          <div class="info-label">Chức vụ / Bộ phận</div>
          <div class="info-value"><%= staffPos %></div>
        </div>
      </div>
    </div>

    <% if (Boolean.TRUE.equals(isResetFlow)) { %>
    <div class="reset-banner">
      ⚠️ Tài khoản này đang bị khóa do yêu cầu đặt lại mật khẩu — sẽ tự động <strong>mở khóa</strong> sau khi lưu.
    </div>
    <% } %>

    <!-- Form mật khẩu mới -->
    <div class="form-section">
      <div class="form-section-title">Nhập mật khẩu mới</div>

      <% if (errMsg != null) { %>
      <div class="err-box">⚠️ <%= errMsg %></div>
      <% } %>

      <form method="post" action="${pageContext.request.contextPath}/accounts?action=admin-set-password">
        <input type="hidden" name="staffId" value="<%= staffInfo.getAccountId() %>">

        <div class="field">
          <label class="field-label" for="newPassword">Mật khẩu mới <span style="color:var(--red)">*</span></label>
          <div class="pw-wrap">
            <input type="password" id="newPassword" name="newPassword" class="field-input"
                   placeholder="Ít nhất 6 ký tự" minlength="6" required autocomplete="new-password"
                   oninput="checkStrength(this.value); checkMatch()">
            <button type="button" class="pw-toggle" onclick="togglePw('newPassword',this)">👁</button>
          </div>
          <div class="strength-meter">
            <div class="strength-bar" id="strengthBar"></div>
            <div class="strength-text" id="strengthText"></div>
          </div>
        </div>

        <div class="field">
          <label class="field-label" for="confirmPassword">Xác nhận mật khẩu <span style="color:var(--red)">*</span></label>
          <div class="pw-wrap">
            <input type="password" id="confirmPassword" name="confirmPassword" class="field-input"
                   placeholder="Nhập lại mật khẩu mới" minlength="6" required autocomplete="new-password"
                   oninput="checkMatch()">
            <button type="button" class="pw-toggle" onclick="togglePw('confirmPassword',this)">👁</button>
          </div>
          <div class="match-indicator" id="matchIndicator"></div>
        </div>

        <div class="action-row">
          <button type="submit" class="btn-submit" id="submitBtn" disabled>
            💾 Lưu mật khẩu mới<%= Boolean.TRUE.equals(isResetFlow) ? " & Mở khóa" : "" %>
          </button>
          <a href="${pageContext.request.contextPath}/accounts" class="btn-cancel">Hủy</a>
        </div>
      </form>
    </div>

  </div>
</div>

<script>
function togglePw(id, btn) {
  const inp = document.getElementById(id);
  const show = inp.type === 'password';
  inp.type = show ? 'text' : 'password';
  btn.textContent = show ? '🙈' : '👁';
}

function checkStrength(pw) {
  const bar  = document.getElementById('strengthBar');
  const txt  = document.getElementById('strengthText');
  if (!pw) { bar.style.width='0'; txt.textContent=''; return; }
  let score = 0;
  if (pw.length >= 6)  score++;
  if (pw.length >= 10) score++;
  if (/[A-Z]/.test(pw)) score++;
  if (/[0-9]/.test(pw)) score++;
  if (/[^A-Za-z0-9]/.test(pw)) score++;
  const levels = [
    {w:'20%', bg:'#EF4444', label:'Rất yếu'},
    {w:'40%', bg:'#F97316', label:'Yếu'},
    {w:'60%', bg:'#EAB308', label:'Trung bình'},
    {w:'80%', bg:'#84CC16', label:'Mạnh'},
    {w:'100%',bg:'#22C55E', label:'Rất mạnh'},
  ];
  const l = levels[Math.min(score-1, 4)] || levels[0];
  bar.style.width   = l.w;
  bar.style.background = l.bg;
  txt.textContent   = l.label;
  txt.style.color   = l.bg;
}

function checkMatch() {
  const pw1 = document.getElementById('newPassword').value;
  const pw2 = document.getElementById('confirmPassword').value;
  const ind = document.getElementById('matchIndicator');
  const btn = document.getElementById('submitBtn');
  if (!pw2) { ind.textContent=''; btn.disabled=true; return; }
  if (pw1 === pw2 && pw1.length >= 6) {
    ind.innerHTML = '<span style="color:#059669">✅ Mật khẩu khớp</span>';
    btn.disabled = false;
  } else {
    ind.innerHTML = '<span style="color:#DC2626">❌ Mật khẩu không khớp</span>';
    btn.disabled = true;
  }
}
</script>
</body>
</html>
