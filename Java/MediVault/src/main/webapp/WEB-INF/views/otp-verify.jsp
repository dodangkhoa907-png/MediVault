<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    boolean isNewAccount = (session.getAttribute("pendingNewAccount") != null);
    boolean isLogin      = (session.getAttribute("pendingAccount")    != null);
    if (!isNewAccount && !isLogin) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    java.lang.String context = isNewAccount ? "new-account" : "login";
    java.lang.String targetEmail = "";
    if (isNewAccount) {
        Object pna = session.getAttribute("pendingNewAccount");
        if (pna instanceof com.medivault.entity.Account) targetEmail = ((com.medivault.entity.Account) pna).getEmail();
    } else {
        Object pa = session.getAttribute("pendingAccount");
        if (pa instanceof com.medivault.entity.Account) targetEmail = ((com.medivault.entity.Account) pa).getEmail();
    }
    java.lang.String maskedEmail = targetEmail;
    if (targetEmail != null && targetEmail.contains("@")) {
        int atIdx = targetEmail.indexOf('@');
        java.lang.String local = targetEmail.substring(0, atIdx);
        java.lang.String domain = targetEmail.substring(atIdx);
        maskedEmail = (local.length() > 3 ? local.substring(0,3) : local) + "****" + domain;
    }
    java.lang.String errMsg  = (java.lang.String) request.getAttribute("error");
    java.lang.String infoMsg = (java.lang.String) request.getAttribute("info");
    boolean isStaff = !isNewAccount && isLogin;
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>MediVault — Xác nhận OTP</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&family=DM+Serif+Display:ital@0;1&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#EEF3FA;--white:#fff;--muted:#7A90B0;--border:#D0DCF0;
  --purple:#6D28D9;--purple-light:#A78BFA;
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
  border-radius:24px;
  box-shadow:0 32px 80px rgba(0,0,0,.3),0 0 0 1px rgba(255,255,255,.1);
  overflow:hidden;
  animation:cardIn .5s cubic-bezier(.22,1,.36,1) both;
}
@keyframes cardIn{from{opacity:0;transform:scale(.95) translateY(20px)}to{opacity:1;transform:scale(1) translateY(0)}}

.card-header{
  padding:32px 36px 24px;
  background:linear-gradient(135deg,#f8faff,#eef3fa);
  border-bottom:1px solid var(--border);
  text-align:center;
}
.otp-icon{
  width:64px;height:64px;border-radius:18px;
  background:linear-gradient(135deg,var(--cyan),var(--blue));
  display:flex;align-items:center;justify-content:center;
  font-size:28px;margin:0 auto 16px;
  box-shadow:0 8px 24px rgba(58,189,224,.3);
  animation:iconPulse 2s ease-in-out infinite;
}
@keyframes iconPulse{0%,100%{box-shadow:0 8px 24px rgba(58,189,224,.3)}50%{box-shadow:0 8px 32px rgba(58,189,224,.5)}}
.card-title{font-family:'DM Serif Display',serif;font-size:26px;color:var(--ink);margin-bottom:6px}
.card-sub{font-size:13.5px;color:var(--muted);line-height:1.5}
.card-email{font-weight:700;color:var(--blue)}

.card-body{padding:28px 36px 32px}

.msg-box{
  display:flex;align-items:flex-start;gap:10px;padding:11px 15px;
  border-radius:10px;margin-bottom:20px;font-size:13px;font-weight:500;
}
.msg-err{background:#FEF2F2;border:1px solid #FECACA;color:#991B1B;animation:shake .4s ease}
.msg-ok{background:#F0FDF4;border:1px solid #BBF7D0;color:#166534}
@keyframes shake{0%,100%{transform:translateX(0)}20%,60%{transform:translateX(-4px)}40%,80%{transform:translateX(4px)}}

/* OTP boxes */
.otp-label{font-size:12.5px;font-weight:700;color:var(--navy);letter-spacing:.4px;margin-bottom:12px;display:block;text-align:center}
.otp-boxes{display:flex;gap:10px;justify-content:center;margin-bottom:24px}
.otp-box{
  width:52px;height:60px;border-radius:12px;
  border:2px solid var(--border);background:#fff;
  font-family:'DM Serif Display',serif;font-size:28px;font-weight:400;
  color:var(--ink);text-align:center;outline:none;
  transition:all .18s;cursor:text;
}
.otp-box:focus{border-color:var(--cyan);box-shadow:0 0 0 3px rgba(58,189,224,.15);transform:translateY(-2px)}
.otp-box.filled{border-color:var(--blue);background:#F0F8FF;color:var(--blue)}

/* Timer */
.timer-wrap{display:flex;align-items:center;justify-content:center;gap:8px;margin-bottom:20px}
.timer-ring{width:36px;height:36px}
.timer-ring circle{
  fill:none;stroke-width:3;stroke-linecap:round;
  transition:stroke-dashoffset .5s linear;
}
.ring-bg{stroke:#EEF3FA}
.ring-progress{stroke:var(--cyan);stroke-dasharray:94.2;transform:rotate(-90deg);transform-origin:center}
.timer-text{font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;color:var(--muted)}
.timer-num{color:var(--ink)}
.timer-expired{color:var(--muted);font-style:italic}

/* Submit btn */
.btn-verify{
  width:100%;padding:13px;margin-bottom:16px;
  background:linear-gradient(135deg,var(--blue),#0D3F85);
  color:#fff;border:none;border-radius:12px;
  font-family:'Outfit',sans-serif;font-size:15px;font-weight:700;
  cursor:pointer;transition:all .22s;letter-spacing:.3px;
}
.btn-verify:hover:not(:disabled){transform:translateY(-1px);box-shadow:0 8px 28px rgba(21,88,168,.3)}
.btn-verify:disabled{opacity:.5;cursor:not-allowed;transform:none}

.actions{display:flex;gap:10px}
.btn-resend,.btn-back{
  flex:1;padding:10px;border-radius:10px;
  font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;
  cursor:pointer;text-align:center;text-decoration:none;
  transition:all .18s;display:inline-flex;align-items:center;justify-content:center;gap:6px;
}
.btn-resend{
  background:#fff;border:1.5px solid var(--border);color:var(--navy);
}
.btn-resend:hover:not(:disabled){border-color:var(--cyan);color:var(--blue)}
.btn-resend:disabled{opacity:.45;cursor:not-allowed}
.btn-back{background:var(--surface);border:1.5px solid var(--border);color:var(--muted)}
.btn-back:hover{color:var(--navy)}
</style>
</head>
<body>
<%@ include file="/WEB-INF/views/loading.jsp" %>

<div class="grid-bg">
  <svg viewBox="0 0 1000 700" preserveAspectRatio="xMidYMid slice">
    <defs><pattern id="g" width="60" height="60" patternUnits="userSpaceOnUse"><path d="M60 0H0M0 0V60" stroke="white" stroke-width=".5" fill="none"/></pattern></defs>
    <rect width="1000" height="700" fill="url(#g)"/>
  </svg>
</div>

<div class="card">
  <div class="card-header">
    <div class="otp-icon">📩</div>
    <div class="card-title">Xác nhận OTP</div>
    <div class="card-sub">
      Mã xác nhận đã gửi đến<br>
      <span class="card-email"><%= maskedEmail %></span>
    </div>
  </div>

  <div class="card-body">
    <% if (errMsg != null) { %>
    <div class="msg-box msg-err">⚠️ <%= errMsg %></div>
    <% } %>
    <% if (infoMsg != null) { %>
    <div class="msg-box msg-ok">✅ <%= infoMsg %></div>
    <% } %>

    <form method="post" action="${pageContext.request.contextPath}/otp-verify" id="otpForm">
      <input type="hidden" name="context" value="<%= context %>">
      <input type="hidden" name="otpCode" id="otpCode">

      <label class="otp-label">Nhập mã 6 chữ số</label>
      <div class="otp-boxes">
        <input class="otp-box" maxlength="1" inputmode="numeric" pattern="[0-9]" data-idx="0">
        <input class="otp-box" maxlength="1" inputmode="numeric" pattern="[0-9]" data-idx="1">
        <input class="otp-box" maxlength="1" inputmode="numeric" pattern="[0-9]" data-idx="2">
        <input class="otp-box" maxlength="1" inputmode="numeric" pattern="[0-9]" data-idx="3">
        <input class="otp-box" maxlength="1" inputmode="numeric" pattern="[0-9]" data-idx="4">
        <input class="otp-box" maxlength="1" inputmode="numeric" pattern="[0-9]" data-idx="5">
      </div>

      <!-- Timer -->
      <div class="timer-wrap">
        <svg class="timer-ring" viewBox="0 0 36 36">
          <circle class="ring-bg" cx="18" cy="18" r="15"/>
          <circle class="ring-progress" id="ringEl" cx="18" cy="18" r="15"/>
        </svg>
        <span class="timer-text">Hết hạn sau <span class="timer-num" id="timerDisplay">05:00</span></span>
      </div>

      <button type="submit" class="btn-verify" id="btnVerify">Xác nhận →</button>

      <div class="actions">
        <form method="post" action="${pageContext.request.contextPath}/otp-verify" style="flex:1">
          <input type="hidden" name="context" value="<%= context %>">
          <input type="hidden" name="resend" value="1">
          <button type="submit" class="btn-resend" id="btnResend" disabled>↻ Gửi lại mã</button>
        </form>
        <a href="${pageContext.request.contextPath}/<%= isNewAccount ? "accounts?action=new" : (isStaff ? "staff-login" : "login") %>" class="btn-back">← Quay lại</a>
      </div>
    </form>
  </div>
</div>

<script>
const boxes = document.querySelectorAll('.otp-box');
const otpHid = document.getElementById('otpCode');
const btnVerify = document.getElementById('btnVerify');
const btnResend = document.getElementById('btnResend');

boxes.forEach((box, i) => {
  box.addEventListener('input', e => {
    const v = e.target.value.replace(/\D/g,'');
    e.target.value = v;
    e.target.classList.toggle('filled', v !== '');
    if (v && i < 5) boxes[i+1].focus();
    updateHidden();
  });
  box.addEventListener('keydown', e => {
    if (e.key === 'Backspace' && !e.target.value && i > 0) { boxes[i-1].focus(); boxes[i-1].value=''; boxes[i-1].classList.remove('filled'); updateHidden(); }
  });
  box.addEventListener('paste', e => {
    e.preventDefault();
    const d = (e.clipboardData||window.clipboardData).getData('text').replace(/\D/g,'').slice(0,6);
    d.split('').forEach((c,j)=>{ if(boxes[j]){ boxes[j].value=c; boxes[j].classList.add('filled'); } });
    updateHidden();
    if(boxes[Math.min(d.length,5)]) boxes[Math.min(d.length,5)].focus();
  });
});

function updateHidden(){
  const val = Array.from(boxes).map(b=>b.value).join('');
  otpHid.value = val;
  btnVerify.disabled = val.length < 6;
}

document.getElementById('otpForm').addEventListener('submit', e => {
  const val = Array.from(boxes).map(b=>b.value).join('');
  if (val.length < 6) { e.preventDefault(); }
  otpHid.value = val;
});
updateHidden();
boxes[0].focus();

// Timer
const TOTAL = 300;
let remaining = TOTAL;
const ring = document.getElementById('ringEl');
const display = document.getElementById('timerDisplay');
const circumference = 94.2;

function tick() {
  remaining--;
  const m = Math.floor(remaining/60).toString().padStart(2,'0');
  const s = (remaining%60).toString().padStart(2,'0');
  display.textContent = m+':'+s;
  ring.style.strokeDashoffset = circumference * (1 - remaining/TOTAL);
  if (remaining <= 60) { ring.style.stroke='#F59E0B'; display.parentElement.style.color='#92400E'; }
  if (remaining <= 0) {
    clearInterval(timer);
    display.textContent = 'Hết hạn';
    display.parentElement.classList.add('timer-expired');
    btnVerify.disabled = true;
    btnResend.disabled = false;
  } else {
    if (remaining <= 30) btnResend.disabled = false;
  }
}
ring.style.strokeDashoffset = 0;
const timer = setInterval(tick, 1000);
</script>
</body>
</html>
