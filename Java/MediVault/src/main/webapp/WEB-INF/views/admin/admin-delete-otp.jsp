<%@ page contentType="text/html;charset=UTF-8" %>
<%
    com.medicare.entity.Account admin = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (admin == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    com.medicare.entity.Account delTarget = (com.medicare.entity.Account) request.getAttribute("deleteTarget");
    if (delTarget == null) { response.sendRedirect(request.getContextPath() + "/accounts?action=trash"); return; }

    String targetName = delTarget.getFullName() != null ? delTarget.getFullName() : delTarget.getUsername();
    String av = targetName.length() >= 2
        ? targetName.substring(0,1).toUpperCase() + targetName.substring(1,2).toUpperCase()
        : targetName.toUpperCase();
    String adminEmail = admin.getEmail() != null ? admin.getEmail() : "";
    String maskedEmail = adminEmail;
    if (adminEmail.contains("@")) {
        int at = adminEmail.indexOf('@');
        String local = adminEmail.substring(0, at);
        maskedEmail = (local.length() > 3 ? local.substring(0,3) : local) + "****" + adminEmail.substring(at);
    }
    String deleteError = (String) request.getAttribute("deleteError");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>OTP Xóa tài khoản — medicare</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800;900&family=DM+Serif+Display@400;400i&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--red:#DC2626;--ink:#0B1628;--muted:#7A90B0;--border:#D5E0F0}
body{min-height:100vh;display:flex;align-items:center;justify-content:center;
  background:linear-gradient(145deg,#1a0505 0%,#3B0A0A 50%,#7F1D1D 100%);
  padding:24px;font-family:'Outfit',sans-serif;}
.card{width:100%;max-width:420px;background:#fff;border-radius:22px;padding:36px;
  box-shadow:0 24px 60px rgba(0,0,0,.35);animation:fadeUp .4s ease both;}
@keyframes fadeUp{from{opacity:0;transform:translateY(18px)}to{opacity:1;transform:translateY(0)}}
.logo-row{display:flex;align-items:center;gap:10px;margin-bottom:24px}
.logo-icon{width:36px;height:36px;border-radius:9px;background:linear-gradient(135deg,#EF4444,#DC2626);
  display:flex;align-items:center;justify-content:center;font-size:16px;}
.logo-text{font-size:15px;font-weight:800;color:var(--ink)}
.step-badge{display:inline-flex;align-items:center;gap:6px;background:#FEF2F2;border:1px solid #FECACA;
  border-radius:20px;padding:5px 14px;margin-bottom:14px;font-size:12px;font-weight:600;color:var(--red);}
h2{font-family:'DM Serif Display',serif;font-size:24px;color:var(--ink);margin-bottom:6px}
.subtitle{font-size:13px;color:var(--muted);margin-bottom:18px;line-height:1.55}
.target-card{background:#FEF2F2;border:1.5px solid #FECACA;border-radius:12px;
  padding:12px 14px;margin-bottom:14px;display:flex;align-items:center;gap:10px;}
.target-av{width:36px;height:36px;border-radius:9px;flex-shrink:0;
  background:linear-gradient(135deg,#EF4444,#DC2626);
  display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:800;color:#fff;}
.target-name{font-size:13px;font-weight:700;color:#991B1B}
.target-user{font-size:11px;color:#B91C1C;margin-top:1px}
.email-hint{background:#F8FAFC;border:1px solid var(--border);border-radius:10px;
  padding:10px 14px;margin-bottom:16px;font-size:12.5px;color:var(--muted);display:flex;align-items:center;gap:8px;}
.err-box{background:#FEF2F2;border:1px solid #FECACA;border-radius:10px;
  padding:10px 14px;margin-bottom:12px;font-size:13px;color:#991B1B;font-weight:500;}
.otp-wrap{display:flex;gap:8px;justify-content:center;margin:16px 0 6px}
.otp-input{width:46px;height:52px;border:2px solid var(--border);border-radius:11px;
  font-family:'Outfit',sans-serif;font-size:22px;font-weight:700;color:var(--ink);
  text-align:center;outline:none;transition:all .2s;}
.otp-input:focus{border-color:var(--red);box-shadow:0 0 0 3px rgba(220,38,38,.12)}
.otp-input.filled{border-color:#FCA5A5;background:#FFF5F5}
.otp-input.err-anim{animation:shake .3s ease}
@keyframes shake{0%,100%{transform:translateX(0)}25%,75%{transform:translateX(-4px)}50%{transform:translateX(4px)}}
.otp-hint{text-align:center;font-size:12px;color:var(--muted);margin-bottom:16px}
.btn-row{display:flex;gap:10px;margin-top:14px}
.btn-danger{flex:1;padding:13px;background:linear-gradient(135deg,var(--red),#B91C1C);
  color:#fff;border:none;border-radius:12px;font-family:'Outfit',sans-serif;
  font-size:15px;font-weight:700;cursor:pointer;transition:all .22s;}
.btn-danger:disabled{opacity:.4;cursor:not-allowed}
.btn-cancel{padding:13px 16px;background:#fff;color:var(--muted);border:1.5px solid var(--border);
  border-radius:12px;font-family:'Outfit',sans-serif;font-size:14px;font-weight:600;
  cursor:pointer;text-decoration:none;display:flex;align-items:center;transition:all .2s;}
.btn-cancel:hover{border-color:var(--red);color:var(--red)}
.resend-row{text-align:center;margin-top:12px;font-size:12.5px;color:var(--muted)}
.resend-btn{background:none;border:none;color:var(--red);font-family:'Outfit',sans-serif;
  font-size:12.5px;font-weight:600;cursor:pointer;padding:0;}
.resend-btn:disabled{color:var(--muted);cursor:not-allowed}
.spinner{display:inline-block;width:14px;height:14px;border:2px solid rgba(255,255,255,.3);
  border-top-color:#fff;border-radius:50%;animation:spin .7s linear infinite;vertical-align:middle;margin-right:5px}
@keyframes spin{to{transform:rotate(360deg)}}
</style>
</head>
<body>
<div class="card">
  <div class="logo-row">
    <div class="logo-icon">🗑️</div>
    <div class="logo-text">medicare — Xóa vĩnh viễn</div>
  </div>
  <div class="step-badge">⚠️ Bước 2 / 2 — Xác nhận OTP cuối cùng</div>
  <h2>Nhập mã OTP</h2>
  <p class="subtitle">Mã xác nhận đã gửi về Gmail của bạn. Nhập đúng để xóa vĩnh viễn tài khoản.</p>

  <div class="target-card">
    <div class="target-av"><%= av %></div>
    <div>
      <div class="target-name"><%= targetName %></div>
      <div class="target-user">@<%= delTarget.getUsername() %></div>
    </div>
  </div>

  <div class="email-hint">📧 OTP gửi đến: <strong><%= maskedEmail %></strong></div>

  <% if (deleteError != null) { %><div class="err-box">⚠️ <%= deleteError %></div><% } %>
  <div class="err-box" id="errDyn" style="display:none"></div>

  <div class="otp-wrap">
    <input class="otp-input" maxlength="1" type="text" inputmode="numeric" id="o0">
    <input class="otp-input" maxlength="1" type="text" inputmode="numeric" id="o1">
    <input class="otp-input" maxlength="1" type="text" inputmode="numeric" id="o2">
    <input class="otp-input" maxlength="1" type="text" inputmode="numeric" id="o3">
    <input class="otp-input" maxlength="1" type="text" inputmode="numeric" id="o4">
    <input class="otp-input" maxlength="1" type="text" inputmode="numeric" id="o5">
  </div>
  <div class="otp-hint">⏱ Mã hết hạn sau <span id="cd">5:00</span></div>

  <div class="btn-row">
    <button class="btn-danger" id="verifyBtn" onclick="doVerify()" disabled>🗑️ Xóa vĩnh viễn</button>
    <a href="${pageContext.request.contextPath}/accounts?action=trash" class="btn-cancel">Hủy</a>
  </div>
  <div class="resend-row">
    Chưa nhận được?
    <button class="resend-btn" id="resendBtn" onclick="doResend()">Gửi lại</button>
    <span id="resendCd"></span>
  </div>
</div>

<script>
const ctx = '${pageContext.request.contextPath}';
const inputs = Array.from({length:6},(_,i)=>document.getElementById('o'+i));
const btn = document.getElementById('verifyBtn');
const errDyn = document.getElementById('errDyn');

inputs.forEach((inp,idx)=>{
  inp.addEventListener('input',e=>{
    inp.value=e.target.value.replace(/\D/g,'');
    inp.value?inp.classList.add('filled'):inp.classList.remove('filled');
    if(inp.value&&idx<5)inputs[idx+1].focus();
    btn.disabled=!inputs.every(i=>i.value.length===1);
  });
  inp.addEventListener('keydown',e=>{if(e.key==='Backspace'&&!inp.value&&idx>0)inputs[idx-1].focus();});
  inp.addEventListener('paste',e=>{
    e.preventDefault();
    const t=(e.clipboardData||window.clipboardData).getData('text').replace(/\D/g,'');
    t.split('').slice(0,6).forEach((ch,i)=>{if(inputs[i]){inputs[i].value=ch;inputs[i].classList.add('filled');}});
    btn.disabled=!inputs.every(i=>i.value.length===1);
    inputs[Math.min(t.length,5)].focus();
  });
});

function showErr(msg){errDyn.style.display='block';errDyn.textContent=msg;
  inputs.forEach(i=>i.classList.add('err-anim'));setTimeout(()=>inputs.forEach(i=>i.classList.remove('err-anim')),400);}

function doVerify(){
  btn.disabled=true;btn.innerHTML='<span class="spinner"></span>Đang xác nhận...';
  errDyn.style.display='none';
  const form=document.createElement('form');form.method='POST';
  form.action=ctx+'/accounts?action=delete-otp&id=<%= delTarget.getAccountId() %>';
  const inp=document.createElement('input');inp.type='hidden';inp.name='otp';
  inp.value=inputs.map(i=>i.value).join('');
  form.appendChild(inp);document.body.appendChild(form);form.submit();
}

// Countdown 5 phút
let rem=300;
const cdEl=document.getElementById('cd');
const timer=setInterval(()=>{
  rem--;
  if(rem<=0){clearInterval(timer);cdEl.parentElement.textContent='❌ Mã hết hạn — gửi lại.';
    inputs.forEach(i=>i.disabled=true);btn.disabled=true;return;}
  cdEl.textContent=Math.floor(rem/60)+':'+(rem%60<10?'0':'')+(rem%60);
},1000);

// Gửi lại
let cool=60;
async function doResend(){
  const rb=document.getElementById('resendBtn');
  const rc=document.getElementById('resendCd');
  rb.disabled=true;
  const iv=setInterval(()=>{cool--;rc.textContent='('+cool+'s)';
    if(cool<=0){clearInterval(iv);rb.disabled=false;rc.textContent='';cool=60;}},1000);
  try{
    await fetch(ctx+'/accounts?action=delete-otp-resend&id=<%= delTarget.getAccountId() %>',{method:'POST'});
    inputs.forEach(i=>{i.value='';i.classList.remove('filled');i.disabled=false;});
    inputs[0].focus();errDyn.style.display='none';rem=300;
  }catch(e){showErr('Không thể gửi lại OTP.');}
}
inputs[0].focus();
</script>
</body>
</html>
