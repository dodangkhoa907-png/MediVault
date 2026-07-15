<%@ page contentType="text/html;charset=UTF-8"  pageEncoding="UTF-8" %>
<%
    String loginError   = (String) request.getAttribute("loginError");
    String phonePrefill = (String) request.getAttribute("phonePrefill");
    if (phonePrefill == null) phonePrefill = "";
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
:root{--teal:#0d9488;--teal-d:#0f766e;--ink:#0f172a;--muted:#64748b;--border:#e2e8f0}
html,body{min-height:100%;font-family:'Plus Jakarta Sans',sans-serif}
body{background:linear-gradient(160deg,#f0fdfa 0%,#e6fffa 40%,#f8fafc 100%);display:flex;align-items:center;justify-content:center;padding:20px;color:var(--ink)}
.login-card{background:#fff;border-radius:24px;max-width:400px;width:100%;padding:36px 30px;box-shadow:0 4px 8px rgba(13,148,136,.06),0 30px 60px -20px rgba(13,148,136,.3);border:1px solid rgba(226,232,240,.8)}
.logo-row{display:flex;align-items:center;justify-content:center;gap:11px;margin-bottom:8px}
.logo-badge{width:48px;height:48px;border-radius:14px;background:linear-gradient(135deg,var(--teal),#14b8a6);display:flex;align-items:center;justify-content:center;font-size:24px;box-shadow:0 8px 18px -6px rgba(13,148,136,.5)}
.logo-name{font-size:22px;font-weight:800;letter-spacing:-.4px}
.logo-name span{color:var(--teal)}
.logo-sub{text-align:center;font-size:10.5px;font-weight:750;letter-spacing:2px;text-transform:uppercase;color:#94a3b8;margin-bottom:26px}
h1{font-size:19px;font-weight:800;text-align:center;margin-bottom:6px}
.sub{font-size:13px;color:var(--muted);text-align:center;margin-bottom:24px;line-height:1.5}
label{font-size:12.5px;font-weight:750;color:#334155;display:block;margin-bottom:7px}
.phone-wrap{position:relative}
.phone-wrap .ic{position:absolute;left:14px;top:50%;transform:translateY(-50%);font-size:17px}
input[type=tel]{width:100%;border:1.5px solid var(--border);border-radius:14px;padding:14px 14px 14px 44px;font-size:17px;font-weight:750;font-family:inherit;letter-spacing:1px;outline:none;transition:border .18s}
input[type=tel]:focus{border-color:var(--teal);box-shadow:0 0 0 3px rgba(13,148,136,.12)}
.err{background:#fef2f2;border:1px solid #fecaca;color:#b91c1c;font-size:12.5px;border-radius:11px;padding:11px 13px;margin-top:12px;line-height:1.5}
button{width:100%;margin-top:18px;padding:14px;background:linear-gradient(135deg,var(--teal),var(--teal-d));border:none;border-radius:14px;color:#fff;font-size:15px;font-weight:800;cursor:pointer;font-family:inherit;box-shadow:0 10px 22px -8px rgba(13,148,136,.55);transition:transform .15s}
button:hover{transform:translateY(-1px)}
.note{font-size:11.5px;color:#94a3b8;text-align:center;margin-top:18px;line-height:1.6}
</style>
    
</head>
<body>
<div class="login-card">
  <div class="logo-row">
    <div class="logo-badge">💊</div>
    <div class="logo-name">Medi<span>Care</span></div>
  </div>
  <div class="logo-sub">Customer Portal</div>

  <h1>Chào mừng bạn trở lại! 👋</h1>
  <p class="sub">Nhập số điện thoại đã đăng ký tại quầy để xem điểm tích lũy, lịch sử mua hàng và ưu đãi của bạn.</p>

  <form method="post" action="${pageContext.request.contextPath}/portal">
    <input type="hidden" name="action" value="login">
    <label for="phone">Số điện thoại</label>
    <div class="phone-wrap">
      <span class="ic">📱</span>
      <input type="tel" id="phone" name="phone" placeholder="0901 234 567" maxlength="10"
             inputmode="numeric" pattern="0[0-9]{9}" required autofocus
             value="<%= phonePrefill %>"
             oninput="this.value=this.value.replace(/\D/g,'').slice(0,10)">
    </div>
    <% if (loginError != null) { %>
      <div class="err">⚠️ <%= loginError %></div>
    <% } %>
    <button type="submit">Đăng nhập →</button>
  </form>

  <p class="note">Chưa có tài khoản? Chỉ cần mua hàng tại quầy MediCare,<br>dược sĩ sẽ tạo tài khoản cho bạn trong 5 giây!</p>
</div>
</body>
</html>
