<%@ page contentType="text/html;charset=UTF-8"  pageEncoding="UTF-8" %>
<%
    String loginError   = (String) request.getAttribute("loginError");
    String emailPrefill = (String) request.getAttribute("emailPrefill");
    if (emailPrefill == null) emailPrefill = "";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
    
    
    
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>MediCare — Cổng khách hàng</title>

<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--teal:#0d9488;--teal-d:#0f766e;--ink:#0f172a;--muted:#64748b;--border:#e2e8f0;
  --ease-spring:cubic-bezier(.22,1,.36,1);--ease-out:cubic-bezier(.16,1,.3,1)}
html,body{min-height:100%;font-family:'Plus Jakarta Sans',sans-serif}
body{
  position:relative;overflow:hidden;min-height:100vh;
  background:linear-gradient(160deg,#f0fdfa 0%,#e6fffa 40%,#f8fafc 100%);
  display:flex;align-items:center;justify-content:center;padding:20px;color:var(--ink)
}

/* ── Nền chuyển động: 2 quầng sáng teal trôi chậm, tạo chiều sâu mà không gây rối mắt ── */
.aurora{position:absolute;border-radius:50%;filter:blur(60px);pointer-events:none;opacity:.5;z-index:0}
.aurora.a1{width:420px;height:420px;background:radial-gradient(circle,#5eead4,transparent 70%);top:-160px;left:-140px;animation:drift1 16s var(--ease-spring) infinite alternate}
.aurora.a2{width:360px;height:360px;background:radial-gradient(circle,#99f6e4,transparent 70%);bottom:-150px;right:-120px;animation:drift2 19s var(--ease-spring) infinite alternate}
@keyframes drift1{from{transform:translate(0,0) scale(1)}to{transform:translate(50px,40px) scale(1.15)}}
@keyframes drift2{from{transform:translate(0,0) scale(1)}to{transform:translate(-40px,-30px) scale(1.1)}}
@media(prefers-reduced-motion:reduce){.aurora{animation:none}}

.login-card{
  position:relative;z-index:1;background:#fff;border-radius:24px;max-width:400px;width:100%;padding:36px 30px;
  box-shadow:0 4px 8px rgba(13,148,136,.06),0 30px 60px -20px rgba(13,148,136,.3);border:1px solid rgba(226,232,240,.8);
  opacity:0;animation:cardIn .7s var(--ease-out) .05s forwards
}
@keyframes cardIn{from{opacity:0;transform:translateY(22px) scale(.97)}to{opacity:1;transform:translateY(0) scale(1)}}

/* ── Stagger từng phần tử con — mỗi phần tử tự khai --stg (thứ tự) ── */
.stg{opacity:0;animation:stgIn .6s var(--ease-out) forwards;animation-delay:calc(.18s + var(--stg) * .07s)}
@keyframes stgIn{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}
@media(prefers-reduced-motion:reduce){.login-card,.stg{animation:none;opacity:1}}

.logo-row{display:flex;align-items:center;justify-content:center;gap:11px;margin-bottom:8px}
.logo-badge{width:48px;height:48px;border-radius:14px;background:linear-gradient(135deg,var(--teal),#14b8a6);display:flex;align-items:center;justify-content:center;font-size:24px;box-shadow:0 8px 18px -6px rgba(13,148,136,.5);animation:badgePulse 3.2s ease-in-out 1s infinite}
@keyframes badgePulse{0%,100%{box-shadow:0 8px 18px -6px rgba(13,148,136,.5)}50%{box-shadow:0 10px 26px -4px rgba(13,148,136,.7)}}
@media(prefers-reduced-motion:reduce){.logo-badge{animation:none}}
.logo-name{font-size:22px;font-weight:800;letter-spacing:-.4px}
.logo-name span{color:var(--teal)}
.logo-sub{text-align:center;font-size:10.5px;font-weight:750;letter-spacing:2px;text-transform:uppercase;color:#94a3b8;margin-bottom:26px}
h1{font-size:19px;font-weight:800;text-align:center;margin-bottom:6px}
.sub{font-size:13px;color:var(--muted);text-align:center;margin-bottom:24px;line-height:1.5}
label{font-size:12.5px;font-weight:750;color:#334155;display:block;margin-bottom:7px}
.phone-wrap{position:relative}
.phone-wrap .ic{position:absolute;left:14px;top:50%;transform:translateY(-50%);font-size:17px;transition:transform .2s var(--ease-spring)}
input[type=email]{width:100%;border:1.5px solid var(--border);border-radius:14px;padding:14px 14px 14px 44px;font-size:17px;font-weight:750;font-family:inherit;letter-spacing:.2px;outline:none;transition:border .18s,box-shadow .18s,transform .18s var(--ease-spring)}
input[type=email]:focus{border-color:var(--teal);box-shadow:0 0 0 3px rgba(13,148,136,.12)}
input[type=email]:focus + .ic,.phone-wrap:focus-within .ic{transform:translateY(-50%) scale(1.12)}
.err{background:#fef2f2;border:1px solid #fecaca;color:#b91c1c;font-size:12.5px;border-radius:11px;padding:11px 13px;margin-top:12px;line-height:1.5;animation:shake .45s var(--ease-out)}
@keyframes shake{10%,90%{transform:translateX(-1px)}20%,80%{transform:translateX(2px)}30%,50%,70%{transform:translateX(-4px)}40%,60%{transform:translateX(4px)}}
button{width:100%;margin-top:18px;padding:14px;background:linear-gradient(135deg,var(--teal),var(--teal-d));border:none;border-radius:14px;color:#fff;font-size:15px;font-weight:800;cursor:pointer;font-family:inherit;box-shadow:0 10px 22px -8px rgba(13,148,136,.55);transition:transform .18s var(--ease-spring),box-shadow .18s;position:relative;overflow:hidden;display:flex;align-items:center;justify-content:center;gap:8px}
button:hover{transform:translateY(-2px);box-shadow:0 14px 28px -8px rgba(13,148,136,.65)}
button:active{transform:translateY(0) scale(.98)}
button:disabled{cursor:default;opacity:.85}
.spinner{width:16px;height:16px;border-radius:50%;border:2.5px solid rgba(255,255,255,.4);border-top-color:#fff;animation:spin .7s linear infinite;display:none}
button.loading .spinner{display:inline-block}
button.loading .btn-label{opacity:.85}
@keyframes spin{to{transform:rotate(360deg)}}
.note{font-size:11.5px;color:#94a3b8;text-align:center;margin-top:18px;line-height:1.6}
</style>
    
<meta name="csrf-token" content="${csrfToken}">
<script src="${pageContext.request.contextPath}/js/csrf.js"></script>
</head>
<body>
<div class="aurora a1"></div>
<div class="aurora a2"></div>
<div class="login-card">
  <div class="logo-row stg" style="--stg:0">
    <div class="logo-badge">💊</div>
    <div class="logo-name">Medi<span>Care</span></div>
  </div>
  <div class="logo-sub stg" style="--stg:1">Customer Portal</div>

  <h1 class="stg" style="--stg:2">Chào mừng bạn trở lại! 👋</h1>
  <p class="sub stg" style="--stg:3">Nhập Email đã đăng ký tại quầy — hệ thống sẽ gửi mã OTP vào Gmail để xác minh trước khi vào portal.</p>

  <form method="post" action="${pageContext.request.contextPath}/portal" id="loginForm">
    <input type="hidden" name="_csrf" value="${csrfToken}">
    <input type="hidden" name="action" value="request-otp">
    <div class="stg" style="--stg:4">
      <label for="email">Email</label>
      <div class="phone-wrap">
        <span class="ic">📧</span>
        <input type="email" id="email" name="email" placeholder="ban@gmail.com"
               required autofocus
               value="<%= emailPrefill %>">
      </div>
    </div>
    <% if (loginError != null) { %>
      <div class="err">⚠️ <%= loginError %></div>
    <% } %>
    <button type="submit" class="stg" style="--stg:5" id="loginBtn">
      <span class="spinner"></span><span class="btn-label">Gửi mã OTP →</span>
    </button>
  </form>

  <p class="note stg" style="--stg:6">Chưa có tài khoản? Chỉ cần mua hàng tại quầy MediCare,<br>dược sĩ sẽ tạo tài khoản và ghi nhận Email của bạn<br>để có thể đăng nhập Portal bằng OTP.</p>
</div>
<script>
document.getElementById('loginForm').addEventListener('submit', function () {
  var btn = document.getElementById('loginBtn');
  btn.classList.add('loading');
  btn.disabled = true;
});
</script>
</body>
</html>
