<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>medicare — Đăng nhập</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#EEF3FA;--white:#fff;--muted:#7A90B0;--border:#D0DCF0;
  --gold:#F5C842;--red:#E03B3B;
}
html,body{height:100%;font-family:'Outfit',sans-serif}
body{display:grid;grid-template-columns:55% 45%;min-height:100vh;background:var(--ink);overflow:hidden}

/* ── LEFT ── */
.left{
  position:relative;display:flex;flex-direction:column;justify-content:space-between;
  padding:52px 56px 44px;
  background:linear-gradient(160deg,#071022 0%,#0F2645 40%,#1558A8 100%);
  overflow:hidden;
}
.left-mesh{
  position:absolute;inset:0;pointer-events:none;
  background:radial-gradient(ellipse 60% 60% at 80% 20%,rgba(58,189,224,.12) 0%,transparent 70%),
             radial-gradient(ellipse 50% 50% at 20% 80%,rgba(21,88,168,.2) 0%,transparent 70%);
}
/* Animated grid lines */
.left-grid{position:absolute;inset:0;pointer-events:none;opacity:.06}
.left-grid svg{width:100%;height:100%}

/* Floating pills */
.pill{
  display:inline-flex;align-items:center;gap:7px;
  border-radius:20px;border:1px solid rgba(58,189,224,.2);
  background:rgba(58,189,224,.06);
  padding:6px 13px;font-size:11.5px;font-weight:500;color:rgba(255,255,255,.55);
}
.pill-icon{font-size:13px}

.brand{position:relative;z-index:2}
.brand-badge{
  display:inline-flex;align-items:center;gap:10px;
  background:rgba(58,189,224,.1);border:1px solid rgba(58,189,224,.25);
  border-radius:14px;padding:10px 18px;margin-bottom:36px;
}
.brand-badge-icon{
  width:36px;height:36px;border-radius:9px;
  background:linear-gradient(135deg,var(--cyan),var(--blue));
  display:flex;align-items:center;justify-content:center;font-size:16px;
  box-shadow:0 4px 16px rgba(58,189,224,.3);
}
.brand-name{font-family:'Outfit',sans-serif;font-size:15px;font-weight:800;color:#fff;letter-spacing:-.2px}
.brand-tag{font-size:10px;color:rgba(255,255,255,.4);letter-spacing:1px;text-transform:uppercase}

.left-headline{position:relative;z-index:2;margin-bottom:auto}
.left-headline h1{
  font-family:'Outfit',sans-serif;font-size:52px;font-weight:400;
  color:#fff;line-height:1.1;letter-spacing:-.5px;margin-bottom:16px;
}
.left-headline h1 em{color:var(--cyan);font-style:italic}
.left-headline p{font-size:15px;color:rgba(255,255,255,.5);line-height:1.6;max-width:360px}

.left-footer{position:relative;z-index:2;display:flex;gap:24px}
.feat{display:flex;align-items:center;gap:8px;color:rgba(255,255,255,.4);font-size:12.5px;font-weight:500}
.feat-dot{width:6px;height:6px;border-radius:50%;background:var(--cyan);opacity:.6}

/* ── RIGHT ── */
.right{
  display:flex;flex-direction:column;justify-content:center;align-items:center;
  padding:48px 52px;background:var(--surface);position:relative;overflow:hidden;
}
.right::before{
  content:'';position:absolute;top:-100px;right:-100px;
  width:350px;height:350px;border-radius:50%;
  background:radial-gradient(circle,rgba(21,88,168,.07) 0%,transparent 70%);
  pointer-events:none;
}
.form-box{width:100%;max-width:380px}
.form-eyebrow{
  display:inline-flex;align-items:center;gap:7px;
  background:#fff;border:1px solid var(--border);
  border-radius:20px;padding:5px 14px;margin-bottom:24px;
  font-size:12px;font-weight:600;color:var(--blue);letter-spacing:.3px;
}
.form-eyebrow::before{content:'';width:6px;height:6px;border-radius:50%;background:var(--cyan)}
.form-title{font-family:'Outfit',sans-serif;font-size:30px;color:var(--ink);margin-bottom:6px}
.form-sub{font-size:14px;color:var(--muted);margin-bottom:32px;line-height:1.5}

/* Error */
.err-box{
  display:flex;align-items:flex-start;gap:10px;padding:12px 16px;
  background:#FEF2F2;border:1px solid #FECACA;border-radius:12px;
  margin-bottom:20px;font-size:13px;color:#991B1B;font-weight:500;
  animation:shake .4s ease;
}
.err-icon{font-size:15px;flex-shrink:0;margin-top:1px}
@keyframes shake{0%,100%{transform:translateX(0)}20%,60%{transform:translateX(-4px)}40%,80%{transform:translateX(4px)}}

/* Fields */
.field{margin-bottom:18px}
.field-label{font-size:12.5px;font-weight:600;color:var(--navy);letter-spacing:.3px;margin-bottom:7px;display:block}
.field-wrap{position:relative}
.field-icon{position:absolute;left:14px;top:50%;transform:translateY(-50%);font-size:15px;pointer-events:none;opacity:.5}
.field-input{
  width:100%;padding:12px 16px 12px 42px;
  background:#fff;border:1.5px solid var(--border);border-radius:12px;
  font-family:'Outfit',sans-serif;font-size:14px;font-weight:500;color:var(--ink);
  outline:none;transition:all .2s;
}
.field-input:focus{border-color:var(--cyan);box-shadow:0 0 0 3px rgba(58,189,224,.12)}
.field-input::placeholder{color:var(--muted);font-weight:400}
.pw-toggle{
  position:absolute;right:14px;top:50%;transform:translateY(-50%);
  background:none;border:none;cursor:pointer;font-size:16px;opacity:.45;
  transition:opacity .2s;padding:0;
}
.pw-toggle:hover{opacity:.8}

/* Submit */
.btn-submit{
  width:100%;padding:13px;margin-top:8px;
  background:linear-gradient(135deg,var(--blue),#0D3F85);
  color:#fff;border:none;border-radius:12px;
  font-family:'Outfit',sans-serif;font-size:15px;font-weight:700;
  cursor:pointer;letter-spacing:.3px;
  transition:all .22s;position:relative;overflow:hidden;
}
.btn-submit::after{
  content:'';position:absolute;inset:0;
  background:linear-gradient(135deg,transparent,rgba(255,255,255,.08));
}
.btn-submit:hover{transform:translateY(-1px);box-shadow:0 8px 28px rgba(21,88,168,.35)}
.btn-submit:active{transform:translateY(0)}

/* Staff link */


/* Entrance animations */
@keyframes fadeUp{from{opacity:0;transform:translateY(20px)}to{opacity:1;transform:translateY(0)}}
.form-box{animation:fadeUp .5s ease both}
.form-eyebrow{animation:fadeUp .5s .05s ease both}
.form-title{animation:fadeUp .5s .1s ease both}
.form-sub{animation:fadeUp .5s .15s ease both}
.field:nth-child(1){animation:fadeUp .5s .2s ease both}
.field:nth-child(2){animation:fadeUp .5s .25s ease both}
.btn-submit{animation:fadeUp .5s .3s ease both}
</style>
</head>
<body>
<%@ include file="/WEB-INF/views/loading.jsp" %>

<div class="left">
  <div class="left-mesh"></div>
  <div class="left-grid">
    <svg viewBox="0 0 600 800" preserveAspectRatio="xMidYMid slice">
      <defs><pattern id="g" width="60" height="60" patternUnits="userSpaceOnUse"><path d="M60 0H0M0 0V60" stroke="white" stroke-width=".5" fill="none"/></pattern></defs>
      <rect width="600" height="800" fill="url(#g)"/>
    </svg>
  </div>

  <div class="brand">
    <div class="brand-badge">
      <div class="brand-badge-icon">🏥</div>
      <div>
        <div class="brand-name">medicare</div>
        <div class="brand-tag">Admin Console</div>
      </div>
    </div>
  </div>

  <div class="left-headline">
    <h1>Quản trị<br>nhà thuốc<br><em>thông minh</em></h1>
    <p>Hệ thống quản lý dược phẩm tích hợp — kiểm soát tồn kho, bán hàng và nhân sự trong một nền tảng.</p>
  </div>

  <div style="display:flex;gap:8px;flex-wrap:wrap;margin-bottom:12px">
    <div class="pill"><span class="pill-icon">💊</span> Dược phẩm</div>
    <div class="pill"><span class="pill-icon">🔒</span> Bảo mật OTP</div>
    <div class="pill"><span class="pill-icon">📊</span> Báo cáo</div>
  </div>
  <div class="left-footer">
    <div class="feat"><div class="feat-dot"></div>Quản lý kho thời gian thực</div>
    <div class="feat"><div class="feat-dot"></div>Phân quyền đa cấp</div>
    <div class="feat"><div class="feat-dot"></div>Bảo mật OTP</div>
  </div>
</div>

<div class="right">
  <div class="form-box">
    <div class="form-eyebrow">Quản trị viên</div>
    <div class="form-title">Đăng nhập</div>
    <div class="form-sub">Chào mừng trở lại! Nhập thông tin tài khoản Admin để tiếp tục.</div>

    <% if (request.getAttribute("error") != null) { %>
    <div class="err-box">
      <span class="err-icon">⚠️</span>
      <span><%= request.getAttribute("error") %></span>
    </div>
    <% } %>

    <form method="post" action="${pageContext.request.contextPath}/login" autocomplete="off">
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
      <div style="display:flex;align-items:center;gap:8px;margin-bottom:16px">
        <input type="checkbox" id="rememberMe" name="rememberMe" value="true"
               style="width:16px;height:16px;accent-color:#1558A8;cursor:pointer">
        <label for="rememberMe" style="font-size:13px;color:#7A90B0;cursor:pointer;user-select:none">Ghi nhớ đăng nhập (7 ngày)</label>
      </div>
      <button type="submit" class="btn-submit">Đăng nhập →</button>
    </form>


  </div>
</div>

<script>
document.getElementById('togglePw').addEventListener('click', function(){
  const pw = document.getElementById('pw');
  const isText = pw.type === 'text';
  pw.type = isText ? 'password' : 'text';
  this.textContent = isText ? '👁' : '🙈';
});
</script>
</body>
</html>
