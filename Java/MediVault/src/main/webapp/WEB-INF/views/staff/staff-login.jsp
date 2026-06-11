<%@ page contentType="text/html;charset=UTF-8" %>
<%
    com.medivault.entity.Account acc = (com.medivault.entity.Account) session.getAttribute("staffAccount");
    if (acc != null) { response.sendRedirect(request.getContextPath() + "/staff-dashboard"); return; }
    String error           = (String)  request.getAttribute("error");
    // lockedForReset CHỈ được set từ StaffLoginServlet khi đúng tài khoản đó cố đăng nhập
    // KHÔNG đọc từ query param để tránh hiện banner cho tất cả staff-login
    Boolean lockedForReset = (Boolean) request.getAttribute("lockedForReset");
    String  lockedName     = (String)  request.getAttribute("lockedName");
    boolean showLockBanner = Boolean.TRUE.equals(lockedForReset);
    // Thông báo sau khi gửi yêu cầu quên mật khẩu thành công
    String successParam   = request.getParameter("success");
    String successName    = request.getParameter("name");
    boolean showResetSent = "reset-sent".equals(successParam);
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>MediVault — Đăng nhập nhân viên</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#12082A;--dp:#1C0F3F;--mid:#2D1B69;--main:#6D28D9;
  --light:#A78BFA;--soft:#EDE9FE;--surface:#F5F3FF;
  --white:#fff;--muted:#7C6FAA;--border:#D8D0F5;
  --cyan:#5EEAD4;--gold:#FCD34D;
}
html,body{height:100%;font-family:'Outfit',sans-serif}
body{display:grid;grid-template-columns:55% 45%;min-height:100vh;background:var(--ink);overflow:hidden}

.left{
  position:relative;display:flex;flex-direction:column;justify-content:space-between;
  padding:52px 56px 44px;
  background:linear-gradient(160deg,#0E0520 0%,#1C0F3F 40%,#4C1D95 100%);
  overflow:hidden;
}
.left-mesh{
  position:absolute;inset:0;pointer-events:none;
  background:radial-gradient(ellipse 60% 60% at 75% 15%,rgba(167,139,250,.14) 0%,transparent 70%),
             radial-gradient(ellipse 50% 50% at 25% 85%,rgba(109,40,217,.22) 0%,transparent 70%);
}
.left-grid{position:absolute;inset:0;pointer-events:none;opacity:.05}
.left-grid svg{width:100%;height:100%}

.bubble{
  position:absolute;border-radius:50%;
  background:rgba(167,139,250,.06);border:1px solid rgba(167,139,250,.12);
  animation:pulseBubble 6s ease-in-out infinite;
}
.bubble-1{width:280px;height:280px;top:-80px;right:-60px;animation-delay:0s}
.bubble-2{width:180px;height:180px;bottom:10%;right:5%;animation-delay:2s}
.bubble-3{width:120px;height:120px;bottom:30%;right:30%;animation-delay:4s}
@keyframes pulseBubble{0%,100%{transform:scale(1);opacity:.5}50%{transform:scale(1.05);opacity:.8}}

.pill{
  display:inline-flex;align-items:center;gap:7px;
  border-radius:20px;border:1px solid rgba(167,139,250,.2);
  background:rgba(167,139,250,.07);
  padding:6px 13px;font-size:11.5px;font-weight:500;color:rgba(255,255,255,.55);
}

.brand{}
.brand-badge{
  display:inline-flex;align-items:center;gap:10px;
  background:rgba(167,139,250,.1);border:1px solid rgba(167,139,250,.22);
  border-radius:14px;padding:10px 18px;margin-bottom:36px;
}
.brand-badge-icon{
  width:36px;height:36px;border-radius:9px;
  background:linear-gradient(135deg,var(--light),var(--main));
  display:flex;align-items:center;justify-content:center;font-size:16px;
  box-shadow:0 4px 16px rgba(109,40,217,.35);
}
.brand-name{font-family:'Outfit',sans-serif;font-size:15px;font-weight:800;color:#fff;letter-spacing:-.2px}
.brand-tag{font-size:10px;color:rgba(255,255,255,.4);letter-spacing:1px;text-transform:uppercase}

.left-headline{margin-bottom:auto;position:relative;z-index:2}
.left-headline h1{
  font-family:'Outfit',sans-serif;font-size:50px;font-weight:400;
  color:#fff;line-height:1.12;letter-spacing:-.3px;margin-bottom:16px;
}
.left-headline h1 em{color:var(--light);font-style:italic}
.left-headline p{font-size:14.5px;color:rgba(255,255,255,.48);line-height:1.65;max-width:340px}

.left-footer{position:relative;z-index:2;display:flex;gap:20px;flex-wrap:wrap}
.feat{display:flex;align-items:center;gap:7px;color:rgba(255,255,255,.38);font-size:12px;font-weight:500}
.feat-dot{width:5px;height:5px;border-radius:50%;background:var(--light);opacity:.7}

/* Right panel */
.right{
  display:flex;flex-direction:column;justify-content:center;align-items:center;
  padding:48px 52px;background:var(--surface);position:relative;overflow:hidden;
}
.right::before{
  content:'';position:absolute;top:-80px;right:-80px;
  width:300px;height:300px;border-radius:50%;
  background:radial-gradient(circle,rgba(109,40,217,.07) 0%,transparent 70%);
}
.form-box{width:100%;max-width:380px}

.form-eyebrow{
  display:inline-flex;align-items:center;gap:7px;
  background:#fff;border:1px solid var(--border);
  border-radius:20px;padding:5px 14px;margin-bottom:24px;
  font-size:12px;font-weight:600;color:var(--main);letter-spacing:.3px;
}
.form-eyebrow::before{content:'';width:6px;height:6px;border-radius:50%;background:var(--light)}

.form-title{font-family:'Outfit',sans-serif;font-size:30px;color:var(--ink);margin-bottom:6px}
.form-sub{font-size:14px;color:var(--muted);margin-bottom:32px;line-height:1.5}

.err-box{
  display:flex;align-items:flex-start;gap:10px;padding:12px 16px;
  background:#FEF2F2;border:1px solid #FECACA;border-radius:12px;
  margin-bottom:20px;font-size:13px;color:#991B1B;font-weight:500;
  animation:shake .4s ease;
}
@keyframes shake{0%,100%{transform:translateX(0)}20%,60%{transform:translateX(-4px)}40%,80%{transform:translateX(4px)}}

.field{margin-bottom:18px}
.field-label{font-size:12.5px;font-weight:600;color:var(--dp);letter-spacing:.3px;margin-bottom:7px;display:block}
.field-wrap{position:relative}
.field-icon{position:absolute;left:14px;top:50%;transform:translateY(-50%);font-size:15px;pointer-events:none;opacity:.5}
.field-input{
  width:100%;padding:12px 16px 12px 42px;
  background:#fff;border:1.5px solid var(--border);border-radius:12px;
  font-family:'Outfit',sans-serif;font-size:14px;font-weight:500;color:var(--ink);
  outline:none;transition:all .2s;
}
.field-input:focus{border-color:var(--light);box-shadow:0 0 0 3px rgba(167,139,250,.14)}
.field-input::placeholder{color:var(--muted);font-weight:400}
.pw-toggle{
  position:absolute;right:14px;top:50%;transform:translateY(-50%);
  background:none;border:none;cursor:pointer;font-size:16px;opacity:.45;
  transition:opacity .2s;padding:0;
}
.pw-toggle:hover{opacity:.8}

.btn-submit{
  width:100%;padding:13px;margin-top:8px;
  background:linear-gradient(135deg,var(--main),#5B21B6);
  color:#fff;border:none;border-radius:12px;
  font-family:'Outfit',sans-serif;font-size:15px;font-weight:700;
  cursor:pointer;letter-spacing:.3px;transition:all .22s;
  position:relative;overflow:hidden;
}
.btn-submit::after{content:'';position:absolute;inset:0;background:linear-gradient(135deg,transparent,rgba(255,255,255,.08))}
.btn-submit:hover{transform:translateY(-1px);box-shadow:0 8px 28px rgba(109,40,217,.35)}
.btn-submit:active{transform:translateY(0)}



@keyframes fadeUp{from{opacity:0;transform:translateY(18px)}to{opacity:1;transform:translateY(0)}}
.form-box>*{animation:fadeUp .45s ease both}

/* Lock banner */
.lock-banner{
  background:linear-gradient(135deg,rgba(251,191,36,.12),rgba(245,158,11,.08));
  border:1.5px solid rgba(245,158,11,.35);border-radius:14px;
  padding:16px 18px;margin-bottom:20px;
}
.lock-banner-icon{font-size:22px;margin-bottom:8px}
.lock-banner-title{font-size:14px;font-weight:700;color:#92400E;margin-bottom:5px}
.lock-banner-msg{font-size:13px;color:#78350F;line-height:1.6}
.lock-banner-sub{font-size:11.5px;color:#B45309;margin-top:7px;display:flex;align-items:center;gap:5px}

/* Forgot-password link */
.forgot-link-wrap{text-align:center;margin-top:16px}
.forgot-link{
  font-size:12.5px;font-weight:600;color:var(--muted);
  text-decoration:none;display:inline-flex;align-items:center;gap:5px;
  transition:color .2s;
}
.forgot-link:hover{color:var(--main)}
.form-box>*:nth-child(1){animation-delay:.05s}
.form-box>*:nth-child(2){animation-delay:.1s}
.form-box>*:nth-child(3){animation-delay:.15s}
.form-box>*:nth-child(4){animation-delay:.2s}
.form-box>*:nth-child(5){animation-delay:.3s}
</style>
</head>
<body>

<div class="left">
  <div class="left-mesh"></div>
  <div class="left-grid">
    <svg viewBox="0 0 600 800" preserveAspectRatio="xMidYMid slice">
      <defs><pattern id="g" width="60" height="60" patternUnits="userSpaceOnUse"><path d="M60 0H0M0 0V60" stroke="white" stroke-width=".5" fill="none"/></pattern></defs>
      <rect width="600" height="800" fill="url(#g)"/>
    </svg>
  </div>

  <div class="bubble bubble-1"></div>
  <div class="bubble bubble-2"></div>
  <div class="bubble bubble-3"></div>

  <div class="brand">
    <div class="brand-badge">
      <div class="brand-badge-icon">💊</div>
      <div>
        <div class="brand-name">MediVault</div>
        <div class="brand-tag">Nhân viên</div>
      </div>
    </div>
  </div>

  <div class="left-headline">
    <h1>Không gian<br>làm việc<br><em>của bạn</em></h1>
    <p>Đăng nhập để truy cập ca làm việc, quầy bán hàng và thông tin cá nhân của bạn.</p>
  </div>

  <div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:12px">
    <div class="pill">💊 Bán hàng POS</div>
    <div class="pill">📦 Quản lý kho</div>
    <div class="pill">📅 Ca làm việc</div>
  </div>
  <div class="left-footer">
    <div class="feat"><div class="feat-dot"></div>Bán hàng POS</div>
    <div class="feat"><div class="feat-dot"></div>Theo dõi ca làm</div>
    <div class="feat"><div class="feat-dot"></div>Hồ sơ cá nhân</div>
  </div>
</div>

<div class="right">
  <div class="form-box">
    <div class="form-eyebrow">Nhân viên</div>
    <div class="form-title">Đăng nhập</div>
    <div class="form-sub">Chào mừng! Nhập thông tin tài khoản nhân viên của bạn để bắt đầu ca làm việc.</div>

    <%-- ── Toast: gửi yêu cầu quên mật khẩu thành công ── --%>
    <% if (showResetSent) { %>
    <div style="background:linear-gradient(135deg,#064e3b,#065f46);color:#fff;
                padding:14px 18px;border-radius:12px;margin-bottom:18px;
                border:1px solid rgba(255,255,255,.1)">
      <div style="font-size:15px;font-weight:700;margin-bottom:4px">📬 Yêu cầu đã được gửi!</div>
      <div style="font-size:12.5px;opacity:.9;line-height:1.6">
        <% if (successName != null && !successName.isEmpty()) { %>
        Xin chào <strong><%= successName %></strong> — yêu cầu đặt lại mật khẩu đã được ghi nhận.
        <% } else { %>
        Yêu cầu đặt lại mật khẩu đã được ghi nhận.
        <% } %>
        <br>Admin sẽ xử lý và bạn nhận được email thông báo sớm nhất.
      </div>
    </div>
    <% } %>

    <form method="post" action="${pageContext.request.contextPath}/staff-login" autocomplete="off">
      <div class="field">
        <label class="field-label">Tên đăng nhập</label>
        <div class="field-wrap">
          <span class="field-icon">👤</span>
          <input type="text" name="username" class="field-input" placeholder="Nhập tên đăng nhập" required autofocus>
        </div>
      </div>
      <div class="field">
        <label class="field-label">Mật khẩu</label>
        <div class="field-wrap">
          <span class="field-icon">🔑</span>
          <input type="password" id="pw" name="password" class="field-input" placeholder="Nhập mật khẩu" required>
          <button type="button" class="pw-toggle" id="togglePw">👁</button>
        </div>
      </div>
      <button type="submit" class="btn-submit">Bắt đầu ca làm việc →</button>
    </form>

    <%-- ── Error / Lock banner ── --%>
    <% if (showLockBanner) { %>
    <div class="lock-banner" style="margin-top:16px">
      <div class="lock-banner-icon">🔒</div>
      <div class="lock-banner-title">Tài khoản đang bị tạm khóa</div>
      <div class="lock-banner-msg">
        Tài khoản <% if (lockedName != null && !lockedName.isEmpty()) { %><strong><%= lockedName %></strong><% } else { %><strong>này</strong><% } %>
        hiện không thể đăng nhập. Quản trị viên đang xử lý.
      </div>
      <div class="lock-banner-sub">📬 Bạn sẽ nhận được thông báo qua email khi tài khoản sẵn sàng.</div>
    </div>
    <% } else if (error != null) { %>
    <div class="err-box" style="margin-top:12px">⚠️ <%= error %></div>
    <% } %>

    <%-- ── Link quên mật khẩu — LUÔN HIỆN ── --%>
    <div class="forgot-link-wrap">
      <a href="${pageContext.request.contextPath}/forgot-password" class="forgot-link">
        🔑 Quên mật khẩu?
      </a>
    </div>

  </div>
</div>

<script>
document.getElementById('togglePw').addEventListener('click',function(){
  const pw=document.getElementById('pw');
  const isText=pw.type==='text';
  pw.type=isText?'password':'text';
  this.textContent=isText?'👁':'🙈';
});
</script>
</body>
</html>
