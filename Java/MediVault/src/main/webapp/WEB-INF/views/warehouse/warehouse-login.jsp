<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%
    String error           = (String)  request.getAttribute("error");
    Boolean lockedForReset = (Boolean) request.getAttribute("lockedForReset");
    String  lockedName     = (String)  request.getAttribute("lockedName");
    boolean showLockBanner = Boolean.TRUE.equals(lockedForReset);
    // Banner sau khi gửi yêu cầu quên mật khẩu thành công (ForgotPasswordServlet redirect về đây)
    boolean showResetSent  = "reset-sent".equals(request.getParameter("success"));
    String  successName    = request.getParameter("name");
    if (successName != null) {
        successName = successName.replace("&", "&amp;").replace("<", "&lt;")
                .replace(">", "&gt;").replace("\"", "&quot;").replace("'", "&#39;");
    }
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>MediCare — Đăng nhập Quản lý kho</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:ital,wght@0,300..800;1,300..700&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  /* Medical Teal — lạnh, điềm tĩnh, khác hẳn Admin (xanh dương) và Staff (tím) */
  --ink:#1C2B29;--deep:#115E59;--main:#0F766E;--accent:#14B8A6;
  --light:#2DD4BF;--soft:#CCFBF1;--surface:#F1F4F3;
  --white:#fff;--muted:#69756F;--border:#E2E7E5;--gold:#FCD34D;--danger:#DC2626;
}
html,body{height:100%;font-family:'Plus Jakarta Sans',system-ui,sans-serif}
body{display:grid;grid-template-columns:56% 44%;min-height:100vh;background:var(--ink);overflow:hidden}

/* ── Left branding panel ── */
.left{position:relative;display:flex;flex-direction:column;justify-content:space-between;
  padding:52px 56px 44px;overflow:hidden;
  background:linear-gradient(150deg,#042F2E 0%,#115E59 42%,#14B8A6 116%)}
.mesh{position:absolute;inset:0;pointer-events:none;
  background:radial-gradient(ellipse 55% 55% at 78% 12%,rgba(45,212,191,.20) 0%,transparent 70%),
            radial-gradient(ellipse 50% 50% at 22% 88%,rgba(20,184,166,.24) 0%,transparent 70%)}
.bubble{position:absolute;border-radius:50%;background:rgba(45,212,191,.06);
  border:1px solid rgba(94,234,212,.16);backdrop-filter:blur(6px);animation:float 7s ease-in-out infinite}
.b1{width:300px;height:300px;top:-90px;right:-70px}
.b2{width:170px;height:170px;bottom:12%;right:6%;animation-delay:2.5s}
.b3{width:110px;height:110px;bottom:34%;right:32%;animation-delay:4.5s}
@keyframes float{0%,100%{transform:scale(1);opacity:.5}50%{transform:scale(1.06);opacity:.85}}

.brand-badge{display:inline-flex;align-self:flex-start;align-items:center;gap:10px;position:relative;z-index:2;
  background:rgba(45,212,191,.1);border:1px solid rgba(94,234,212,.25);
  border-radius:14px;padding:10px 18px}
.brand-icon{width:36px;height:36px;border-radius:9px;display:grid;place-items:center;font-size:16px;
  background:linear-gradient(135deg,var(--light),var(--main));box-shadow:0 4px 16px rgba(15,118,110,.3)}
.brand-name{font-size:15px;font-weight:800;color:#fff;letter-spacing:-.2px}
.brand-tag{font-size:10px;color:rgba(255,255,255,.4);letter-spacing:1px;text-transform:uppercase}

.headline{position:relative;z-index:2;margin-bottom:auto;margin-top:auto}
.headline h1{font-size:62px;font-weight:750;color:#fff;line-height:1.2;letter-spacing:-.5px;margin-bottom:16px}
.headline h1 em{color:var(--light);font-style:italic;font-weight:750}
.headline p{font-size:13px;color:rgba(255,255,255,.5);line-height:1.65;max-width:350px}

.feats{position:relative;z-index:2;display:flex;gap:22px;flex-wrap:wrap}
.feat{display:flex;align-items:center;gap:8px;color:rgba(255,255,255,.42);font-size:12px;font-weight:700}
.feat .dot{width:6px;height:6px;border-radius:50%;background:var(--light);opacity:.75}

/* ── Right form panel ── */
.right{background:var(--white);display:flex;align-items:center;justify-content:center;padding:40px}
.form-wrap{width:100%;max-width:380px}
.form-eyebrow{font-size:12px;font-weight:800;letter-spacing:2px;text-transform:uppercase;color:var(--main);margin-bottom:10px}
.form-wrap h2{font-size:28px;font-weight:800;color:var(--ink);letter-spacing:-.5px;margin-bottom:6px}
.form-wrap .sub{font-size:14px;color:var(--muted);margin-bottom:28px}

.field{margin-bottom:18px}
.field label{display:block;font-size:12.5px;font-weight:700;color:var(--deep);margin-bottom:7px}
.input{position:relative}
.input input{width:100%;padding:13px 15px 13px 44px;border:1.5px solid var(--border);border-radius:12px;
  font-family:inherit;font-size:14.5px;color:var(--ink);background:var(--surface);transition:.18s}
.input input:focus{outline:none;border-color:var(--main);background:#fff;box-shadow:0 0 0 4px rgba(15,118,110,.14)}
.input .ic{position:absolute;left:15px;top:50%;transform:translateY(-50%);font-size:16px;opacity:.55}

.btn{width:100%;padding:14px;border:none;border-radius:12px;cursor:pointer;
  font-family:inherit;font-size:15px;font-weight:800;color:#fff;letter-spacing:.2px;
  background:linear-gradient(135deg,var(--main),var(--deep));
  box-shadow:0 8px 22px -8px rgba(15,118,110,.45);transition:.18s;margin-top:6px}
.btn:hover{transform:translateY(-1px);box-shadow:0 12px 28px -8px rgba(15,118,110,.6)}
.btn:active{transform:translateY(0)}

.alert{display:flex;gap:10px;align-items:flex-start;padding:13px 15px;border-radius:11px;margin-bottom:20px;font-size:13.5px;line-height:1.5}
.alert.err{background:#FFF1F2;border:1px solid #FECDD3;color:#B91C1C}
.alert.warn{background:#FFFBEB;border:1px solid #FDE68A;color:#92400E}
.alert.ok{background:#ECFDF5;border:1px solid #A7F3D0;color:#065F46}
.alert .ai{flex:none;font-size:15px}

.foot{margin-top:26px;padding-top:20px;border-top:1px solid var(--border);
  display:flex;justify-content:space-between;align-items:center;font-size:12.5px}
.foot a{color:var(--main);font-weight:700;text-decoration:none}
.foot a:hover{text-decoration:underline}
.foot .other{color:var(--muted)}

@media(max-width:860px){
  body{grid-template-columns:1fr}
  .left{display:none}
  .right{padding:28px 20px}
}
</style>
</head>
<body>
  <div class="left">
    <div class="mesh"></div>
    <div class="bubble b1"></div><div class="bubble b2"></div><div class="bubble b3"></div>
    <div class="brand-badge">
      <div class="brand-icon">📦</div>
      <div>
        <div class="brand-name">MediCare</div>
        <div class="brand-tag">Warehouse Console</div>
      </div>
    </div>
    <div class="headline">
      <h1>Trung tâm <em>quản lý kho</em><br>trong tầm tay bạn.</h1>
      <p>Nhập kho bằng mã vạch, kiểm soát tồn kho &amp; hạn dùng, và bán hàng — tất cả trong một không gian làm việc dành riêng cho quản lý kho.</p>
    </div>
    <div class="feats">
      <div class="feat"><span class="dot"></span> Nhập kho quét barcode</div>
      <div class="feat"><span class="dot"></span> Bán hàng POS</div>
      <div class="feat"><span class="dot"></span> Cảnh báo cận hạn</div>
    </div>
  </div>

  <div class="right">
    <div class="form-wrap">
      <div class="form-eyebrow">Quản lý kho</div>
      <h2>Đăng nhập</h2>
      <p class="sub">Chào mừng trở lại. Vui lòng đăng nhập để tiếp tục.</p>

      <% if (showResetSent) { %>
        <div class="alert ok">
          <span class="ai">📬</span>
          <span>Đã gửi yêu cầu đặt lại mật khẩu cho <b><%= successName != null ? successName : "" %></b> tới quản trị viên. Tài khoản tạm khóa cho tới khi có mật khẩu mới.</span>
        </div>
      <% } else if (showLockBanner) { %>
        <div class="alert warn">
          <span class="ai">⚠️</span>
          <span>Tài khoản <b><%= lockedName != null ? lockedName : "" %></b> đang chờ duyệt cấp lại mật khẩu. Vui lòng liên hệ quản trị viên.</span>
        </div>
      <% } else if (error != null) { %>
        <div class="alert err"><span class="ai">⛔</span><span><%= error %></span></div>
      <% } %>

      <form method="post" action="<%= ctx %>/warehouse-login" autocomplete="off">
        <div class="field">
          <label for="username">Tên đăng nhập</label>
          <div class="input">
            <span class="ic">👤</span>
            <input type="text" id="username" name="username" placeholder="vd: manager" required autofocus>
          </div>
        </div>
        <div class="field">
          <label for="password">Mật khẩu</label>
          <div class="input">
            <span class="ic">🔒</span>
            <input type="password" id="password" name="password" placeholder="••••••••" required>
          </div>
        </div>
        <button type="submit" class="btn">Đăng nhập →</button>
      </form>

      <div class="foot">
        <a href="<%= ctx %>/warehouse-forgot-password">Quên mật khẩu?</a>
        <span class="other">Nhân viên bán? <a href="<%= ctx %>/staff-login">Vào đây</a></span>
      </div>
    </div>
  </div>
</body>
</html>
