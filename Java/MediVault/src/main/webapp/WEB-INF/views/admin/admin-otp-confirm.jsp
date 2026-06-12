<%@ page contentType="text/html;charset=UTF-8" %>
<%
    com.medicare.entity.Account admin = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (admin == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    com.medicare.entity.Account staffInfo = (com.medicare.entity.Account) request.getAttribute("staffInfo");
    if (staffInfo == null) { response.sendRedirect(request.getContextPath() + "/accounts"); return; }

    String adminName  = admin.getFullName()  != null ? admin.getFullName()  : admin.getUsername();
    String staffName  = staffInfo.getFullName() != null ? staffInfo.getFullName() : staffInfo.getUsername();
    String adminEmail = admin.getEmail() != null ? admin.getEmail() : "";
    // Mask email
    String maskedEmail = adminEmail;
    if (adminEmail.contains("@")) {
        int at = adminEmail.indexOf('@');
        String local = adminEmail.substring(0, at);
        maskedEmail = (local.length() > 3 ? local.substring(0,3) : local) + "****" + adminEmail.substring(at);
    }
    String errMsg = (String) request.getAttribute("error");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Xác nhận OTP — Đặt lại mật khẩu nhân viên</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&family=DM+Serif+Display:ital@0;1&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#EEF3FA;--white:#fff;--muted:#7A90B0;--border:#D0DCF0;
}
html,body{height:100%;font-family:'Outfit',sans-serif}
body{
  min-height:100vh;display:flex;align-items:center;justify-content:center;
  background:linear-gradient(145deg,#071022 0%,#0F2645 50%,#1558A8 100%);
  padding:24px;position:relative;overflow:hidden;
}
body::before{
  content:'';position:absolute;inset:0;
  background:radial-gradient(ellipse 70% 70% at 80% 20%,rgba(58,189,224,.1) 0%,transparent 60%),
             radial-gradient(ellipse 60% 60% at 20% 80%,rgba(109,40,217,.12) 0%,transparent 60%);
  pointer-events:none;
}
.grid-bg{position:absolute;inset:0;opacity:.04;pointer-events:none}
.grid-bg svg{width:100%;height:100%}

.card{
  position:relative;z-index:1;
  width:100%;max-width:440px;
  background:rgba(255,255,255,.97);
  border-radius:22px;padding:38px 36px;
  box-shadow:0 24px 60px rgba(0,0,0,.28);
  animation:fadeUp .4s ease both;
}
@keyframes fadeUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}

.logo-row{display:flex;align-items:center;gap:10px;margin-bottom:28px}
.logo-icon{width:38px;height:38px;border-radius:10px;
  background:linear-gradient(135deg,var(--cyan),var(--blue));
  display:flex;align-items:center;justify-content:center;font-size:18px;
  box-shadow:0 4px 14px rgba(21,88,168,.3)}
.logo-text{font-size:16px;font-weight:800;color:var(--navy)}
.logo-text span{color:var(--cyan)}

.step-badge{
  display:inline-flex;align-items:center;gap:6px;
  background:linear-gradient(135deg,rgba(21,88,168,.08),rgba(58,189,224,.06));
  border:1px solid rgba(21,88,168,.15);
  border-radius:20px;padding:5px 14px;margin-bottom:18px;
  font-size:12px;font-weight:600;color:var(--blue);
}

h2{font-family:'DM Serif Display',serif;font-size:26px;color:var(--ink);margin-bottom:6px}
.subtitle{font-size:13.5px;color:var(--muted);margin-bottom:24px;line-height:1.55}

/* Staff info card */
.staff-card{
  background:linear-gradient(135deg,rgba(21,88,168,.05),rgba(58,189,224,.04));
  border:1px solid rgba(21,88,168,.12);border-radius:12px;
  padding:14px 16px;margin-bottom:22px;
  display:flex;align-items:center;gap:12px;
}
.staff-av{
  width:40px;height:40px;border-radius:10px;flex-shrink:0;
  background:linear-gradient(135deg,var(--cyan),var(--blue));
  display:flex;align-items:center;justify-content:center;
  font-size:14px;font-weight:800;color:#fff;
}
.staff-name{font-size:14px;font-weight:700;color:var(--navy)}
.staff-user{font-size:12px;color:var(--muted);margin-top:2px}

/* Email hint */
.email-hint{
  background:#F8FAFC;border:1px solid var(--border);border-radius:10px;
  padding:12px 14px;margin-bottom:20px;font-size:13px;
  color:var(--muted);display:flex;align-items:center;gap:8px;
}
.email-hint strong{color:var(--navy)}

/* OTP inputs */
.otp-wrap{display:flex;gap:10px;justify-content:center;margin:20px 0 8px}
.otp-input{
  width:48px;height:54px;border:2px solid var(--border);border-radius:11px;
  font-family:'Outfit',sans-serif;font-size:22px;font-weight:700;color:var(--navy);
  text-align:center;outline:none;transition:all .2s;background:#fff;
}
.otp-input:focus{border-color:var(--blue);box-shadow:0 0 0 3px rgba(21,88,168,.12)}
.otp-input.filled{border-color:var(--cyan);background:rgba(58,189,224,.04)}
.otp-input.error-anim{animation:shake .3s ease}
@keyframes shake{0%,100%{transform:translateX(0)}20%,60%{transform:translateX(-5px)}40%,80%{transform:translateX(5px)}}

.otp-hint{text-align:center;font-size:12px;color:var(--muted);margin-bottom:20px}

.err-box{
  background:#FEF2F2;border:1px solid #FECACA;border-radius:10px;
  padding:10px 14px;margin-bottom:16px;font-size:13px;color:#991B1B;font-weight:500;
  display:flex;align-items:center;gap:8px;
}

.btn{
  width:100%;padding:13px;border-radius:12px;
  font-family:'Outfit',sans-serif;font-size:15px;font-weight:700;
  cursor:pointer;transition:all .22s;border:none;
}
.btn-primary{
  background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;
  box-shadow:0 4px 14px rgba(21,88,168,.25);
}
.btn-primary:hover{transform:translateY(-1px);box-shadow:0 6px 20px rgba(21,88,168,.35)}
.btn-primary:disabled{opacity:.6;cursor:not-allowed;transform:none}

.resend-row{text-align:center;margin-top:14px;font-size:13px;color:var(--muted)}
.resend-btn{
  background:none;border:none;color:var(--blue);font-family:'Outfit',sans-serif;
  font-size:13px;font-weight:600;cursor:pointer;padding:0;margin-left:4px;
}
.resend-btn:disabled{color:var(--muted);cursor:not-allowed}

.back-link{
  display:block;text-align:center;margin-top:16px;
  font-size:12.5px;color:var(--muted);text-decoration:none;
  transition:color .2s;
}
.back-link:hover{color:var(--blue)}

/* Spinner */
.spinner{
  display:inline-block;width:16px;height:16px;border:2.5px solid rgba(255,255,255,.3);
  border-top-color:#fff;border-radius:50%;animation:spin .7s linear infinite;
  vertical-align:middle;margin-right:6px;
}
@keyframes spin{to{transform:rotate(360deg)}}
</style>
</head>
<body>
<%@ include file="/WEB-INF/views/loading.jsp" %>

<div class="grid-bg">
  <svg viewBox="0 0 800 600" preserveAspectRatio="xMidYMid slice">
    <defs><pattern id="g" width="60" height="60" patternUnits="userSpaceOnUse">
      <path d="M60 0H0M0 0V60" stroke="white" stroke-width=".5" fill="none"/>
    </pattern></defs>
    <rect width="800" height="600" fill="url(#g)"/>
  </svg>
</div>

<div class="card">
  <div class="logo-row">
    <div class="logo-icon">💊</div>
    <div class="logo-text">Medi<span>Vault</span></div>
  </div>

  <div class="step-badge">🔐 Bước 1 / 2 — Xác nhận danh tính Admin</div>
  <h2>Nhập mã OTP</h2>
  <p class="subtitle">Mã OTP đã được gửi về email của bạn để xác nhận đặt lại mật khẩu cho nhân viên.</p>

  <!-- Info nhân viên -->
  <div class="staff-card">
    <%
      String av2 = staffName.length() >= 2
          ? staffName.substring(0,1).toUpperCase() + staffName.substring(1,2).toUpperCase()
          : staffName.toUpperCase();
    %>
    <div class="staff-av"><%= av2 %></div>
    <div>
      <div class="staff-name"><%= staffName %></div>
      <div class="staff-user">@<%= staffInfo.getUsername() %> • Đặt lại mật khẩu</div>
    </div>
  </div>

  <!-- Email hint -->
  <div class="email-hint">
    📧 OTP gửi đến: <strong><%= maskedEmail %></strong>
  </div>

  <% if (errMsg != null) { %>
  <div class="err-box" id="errBox">⚠️ <%= errMsg %></div>
  <% } %>
  <div class="err-box" id="errDynamic" style="display:none"></div>

  <!-- OTP boxes -->
  <div class="otp-wrap" id="otpWrap">
    <input class="otp-input" maxlength="1" type="text" inputmode="numeric" pattern="[0-9]" id="o0">
    <input class="otp-input" maxlength="1" type="text" inputmode="numeric" pattern="[0-9]" id="o1">
    <input class="otp-input" maxlength="1" type="text" inputmode="numeric" pattern="[0-9]" id="o2">
    <input class="otp-input" maxlength="1" type="text" inputmode="numeric" pattern="[0-9]" id="o3">
    <input class="otp-input" maxlength="1" type="text" inputmode="numeric" pattern="[0-9]" id="o4">
    <input class="otp-input" maxlength="1" type="text" inputmode="numeric" pattern="[0-9]" id="o5">
  </div>
  <div class="otp-hint" id="timerLine">⏱ Mã hết hạn sau <span id="countdown">5:00</span></div>

  <button class="btn btn-primary" id="verifyBtn" onclick="verifyOtp()" disabled>
    Xác nhận OTP →
  </button>

  <div class="resend-row">
    Chưa nhận được?
    <button class="resend-btn" id="resendBtn" onclick="resendOtp()">Gửi lại</button>
    <span id="resendCountdown"></span>
  </div>

  <a href="${pageContext.request.contextPath}/accounts" class="back-link">← Quay lại danh sách tài khoản</a>
</div>

<script>
const ctx = '${pageContext.request.contextPath}';
const staffId = <%= staffInfo.getAccountId() %>;
const inputs = Array.from({length:6},(_,i)=>document.getElementById('o'+i));
const verifyBtn  = document.getElementById('verifyBtn');
const errDynamic = document.getElementById('errDynamic');

// ── OTP input navigation ──
inputs.forEach((inp, idx) => {
  inp.addEventListener('input', e => {
    const v = e.target.value.replace(/\D/g,'');
    inp.value = v;
    if (v) inp.classList.add('filled');
    else   inp.classList.remove('filled');
    if (v && idx < 5) inputs[idx+1].focus();
    checkAllFilled();
  });
  inp.addEventListener('keydown', e => {
    if (e.key === 'Backspace' && !inp.value && idx > 0) inputs[idx-1].focus();
  });
  inp.addEventListener('paste', e => {
    e.preventDefault();
    const text = (e.clipboardData||window.clipboardData).getData('text').replace(/\D/g,'');
    text.split('').slice(0,6).forEach((ch,i) => {
      if (inputs[i]) { inputs[i].value = ch; inputs[i].classList.add('filled'); }
    });
    checkAllFilled();
    inputs[Math.min(text.length,5)].focus();
  });
});

function checkAllFilled() {
  const full = inputs.every(i => i.value.length === 1);
  verifyBtn.disabled = !full;
}

function getOtp() { return inputs.map(i=>i.value).join(''); }

function showErr(msg) {
  errDynamic.style.display = 'flex';
  errDynamic.innerHTML = '⚠️ ' + msg;
  inputs.forEach(i => i.classList.add('error-anim'));
  setTimeout(() => inputs.forEach(i => i.classList.remove('error-anim')), 400);
}
function clearErr() { errDynamic.style.display = 'none'; }

// ── Verify OTP via AJAX ──
async function verifyOtp() {
  clearErr();
  const otp = getOtp();
  if (otp.length < 6) return;
  verifyBtn.disabled = true;
  verifyBtn.innerHTML = '<span class="spinner"></span>Đang xác nhận...';

  try {
    const r = await fetch(ctx + '/accounts?action=admin-reset-otp', {
      method: 'POST',
      headers: {'Content-Type':'application/x-www-form-urlencoded'},
      body: 'otp=' + encodeURIComponent(otp)
    });
    const data = await r.json();
    if (data.ok) {
      verifyBtn.innerHTML = '✅ Xác nhận thành công!';
      verifyBtn.style.background = 'linear-gradient(135deg,#059669,#047857)';
      // Chuyển sang trang set mật khẩu
      setTimeout(() => { window.location.href = ctx + '/accounts?action=admin-set-password-page'; }, 600);
    } else {
      showErr(data.message || 'Mã OTP không đúng!');
      verifyBtn.disabled = false;
      verifyBtn.innerHTML = 'Xác nhận OTP →';
      inputs.forEach(i => { i.value = ''; i.classList.remove('filled'); });
      inputs[0].focus();
    }
  } catch(e) {
    showErr('Lỗi kết nối, vui lòng thử lại!');
    verifyBtn.disabled = false;
    verifyBtn.innerHTML = 'Xác nhận OTP →';
  }
}

// ── Countdown timer 5 phút ──
let remaining = 300;
const cdEl = document.getElementById('countdown');
const timerInterval = setInterval(() => {
  remaining--;
  if (remaining <= 0) {
    clearInterval(timerInterval);
    cdEl.parentElement.textContent = '❌ Mã đã hết hạn. Vui lòng gửi lại.';
    inputs.forEach(i => i.disabled = true);
    verifyBtn.disabled = true;
    return;
  }
  const m = Math.floor(remaining/60).toString().padStart(1,'0');
  const s = (remaining%60).toString().padStart(2,'0');
  cdEl.textContent = m + ':' + s;
}, 1000);

// ── Gửi lại OTP ──
let resendCooldown = 60;
const resendBtn = document.getElementById('resendBtn');
const resendCd  = document.getElementById('resendCountdown');

async function resendOtp() {
  resendBtn.disabled = true;
  resendCd.textContent = '(' + resendCooldown + 's)';
  const cd = setInterval(() => {
    resendCooldown--;
    resendCd.textContent = '(' + resendCooldown + 's)';
    if (resendCooldown <= 0) { clearInterval(cd); resendBtn.disabled = false; resendCd.textContent = ''; resendCooldown = 60; }
  }, 1000);

  // Re-submit form edit với cùng password tạm (lưu trong session)
  // Thực ra chỉ cần trigger lại việc gửi OTP
  try {
    const r = await fetch(ctx + '/accounts?action=admin-reset-otp-resend', {
      method: 'POST',
      headers: {'Content-Type':'application/x-www-form-urlencoded'},
      body: 'staffId=' + staffId
    });
    if (!r.ok) throw new Error();
    inputs.forEach(i => { i.value=''; i.classList.remove('filled'); i.disabled=false; });
    inputs[0].focus();
    clearErr();
    remaining = 300;
    document.getElementById('timerLine').innerHTML = '⏱ Mã hết hạn sau <span id="countdown">5:00</span>';
  } catch(e) {
    showErr('Không thể gửi lại OTP. Vui lòng thử lại sau.');
  }
}

inputs[0].focus();
</script>
</body>
</html>
