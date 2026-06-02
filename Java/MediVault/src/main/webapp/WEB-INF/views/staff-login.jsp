<%@ page contentType="text/html;charset=UTF-8" %>
<%
    // Chỉ redirect nếu đã đăng nhập là NHÂN VIÊN (staffAccount)
    // KHÔNG dùng "account" chung vì admin cũng set key đó → sẽ bị đụng!
    com.medivault.entity.Account acc = (com.medivault.entity.Account) session.getAttribute("staffAccount");
    if (acc != null) { response.sendRedirect(request.getContextPath() + "/dashboard"); return; }
    String error = (String) request.getAttribute("error");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>MediVault — Đăng nhập nhân viên</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@700;800;900&family=Plus+Jakarta+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --purple-deep:#1E1035;--purple-mid:#2D1B69;--purple:#4C1D95;
  --purple-main:#7C3AED;--purple-light:#A78BFA;--purple-soft:#EDE9FE;
  --surface:#F5F3FF;--white:#fff;--muted:#6B7280;
  --sky:#46CAF4;--gold:#FCDA7C;
}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif}
body{display:grid;grid-template-columns:1fr 1fr;min-height:100vh;background:var(--purple-deep);overflow:hidden}

/* ── LEFT PANEL ── */
.left{
  position:relative;display:flex;flex-direction:column;justify-content:center;
  padding:60px 64px;
  background:linear-gradient(145deg,var(--purple-deep) 0%,var(--purple-mid) 50%,var(--purple) 100%);
  overflow:hidden;
}

/* Decorative circles */
.left::before{content:'';position:absolute;top:-120px;right:-80px;width:400px;height:400px;border-radius:50%;background:radial-gradient(circle,rgba(167,139,250,.18) 0%,transparent 70%);pointer-events:none}
.left::after{content:'';position:absolute;bottom:-100px;left:-60px;width:320px;height:320px;border-radius:50%;background:radial-gradient(circle,rgba(124,58,237,.2) 0%,transparent 70%);pointer-events:none}

/* Cross marks */
.cross{position:absolute;color:rgba(167,139,250,.25);font-size:18px;font-weight:300;user-select:none}

/* Logo */
.logo{display:flex;align-items:center;gap:14px;margin-bottom:52px;position:relative;z-index:1}
.logo-box{
  width:56px;height:56px;border-radius:16px;
  background:rgba(167,139,250,.15);
  border:1.5px solid rgba(167,139,250,.35);
  display:flex;align-items:center;justify-content:center;font-size:26px;
}
.logo-name{font-family:'Nunito',sans-serif;font-size:26px;font-weight:900;color:#fff;letter-spacing:-.5px}
.logo-name span{color:var(--purple-light)}
.logo-tag{font-size:10px;color:rgba(255,255,255,.4);letter-spacing:1.5px;text-transform:uppercase;margin-top:1px}

.left-headline{position:relative;z-index:1;margin-bottom:32px}
.left-headline h1{
  font-family:'Nunito',sans-serif;font-size:40px;font-weight:900;
  color:#fff;line-height:1.15;letter-spacing:-.5px;margin-bottom:12px;
}
.left-headline h1 span{color:var(--purple-light)}
.left-headline p{font-size:15px;color:rgba(255,255,255,.6);line-height:1.6;max-width:360px}

.feature-pills{display:flex;flex-wrap:wrap;gap:8px;position:relative;z-index:1}
.pill{
  display:flex;align-items:center;gap:6px;
  padding:7px 14px;border-radius:20px;
  background:rgba(255,255,255,.07);
  border:1px solid rgba(167,139,250,.25);
  font-size:12.5px;font-weight:500;color:rgba(255,255,255,.7);
}
.pill::before{content:'●';font-size:6px;color:var(--purple-light)}

.fpt-badge{
  position:absolute;top:28px;right:28px;
  font-size:11px;font-weight:700;letter-spacing:1.5px;
  color:var(--purple-light);text-transform:uppercase;
}

/* ── RIGHT PANEL ── */
.right{
  background:var(--surface);
  display:flex;flex-direction:column;align-items:center;justify-content:center;
  padding:48px 64px;position:relative;
}

.form-wrap{width:100%;max-width:400px}

.role-tag{
  display:inline-flex;align-items:center;gap:6px;
  padding:4px 12px;border-radius:20px;
  background:rgba(124,58,237,.1);
  font-size:12px;font-weight:700;letter-spacing:.5px;
  color:var(--purple-main);margin-bottom:20px;
}
.role-tag::before{content:'●';font-size:7px}

.form-title{font-family:'Nunito',sans-serif;font-size:38px;font-weight:900;color:var(--purple-deep);letter-spacing:-.8px;line-height:1.1;margin-bottom:8px}
.form-sub{font-size:14px;color:var(--muted);margin-bottom:36px}

/* Error */
.error-box{
  background:#FEF2F2;border:1px solid #FECACA;border-radius:12px;
  padding:12px 16px;margin-bottom:20px;
  display:flex;align-items:center;gap:8px;
  font-size:13.5px;color:#DC2626;font-weight:500;
}

/* Input group */
.input-group{margin-bottom:20px}
.input-label{font-size:13px;font-weight:600;color:var(--purple-deep);margin-bottom:8px;display:block}
.input-wrap{position:relative}
.input-wrap input{
  width:100%;height:52px;
  padding:0 46px 0 46px;
  border:1.5px solid #DDD6FE;border-radius:12px;
  font-size:14px;font-family:inherit;color:var(--purple-deep);
  background:#fff;outline:none;transition:border-color .2s,box-shadow .2s;
}
.input-wrap input:focus{border-color:var(--purple-main);box-shadow:0 0 0 3px rgba(124,58,237,.1)}
.input-wrap input::placeholder{color:#C4B5FD}
.input-icon{
  position:absolute;left:14px;top:50%;transform:translateY(-50%);
  font-size:16px;pointer-events:none;
}
.pw-toggle{
  position:absolute;right:14px;top:50%;transform:translateY(-50%);
  background:none;border:none;cursor:pointer;font-size:16px;color:#C4B5FD;
  padding:0;line-height:1;
}
.pw-toggle:hover{color:var(--purple-main)}

/* Submit */
.submit-btn{
  width:100%;height:52px;
  background:linear-gradient(135deg,var(--purple-main),var(--purple));
  color:#fff;border:none;border-radius:12px;
  font-size:15px;font-weight:700;font-family:inherit;
  cursor:pointer;transition:all .2s;
  display:flex;align-items:center;justify-content:center;gap:8px;
  margin-bottom:20px;
}
.submit-btn:hover{background:linear-gradient(135deg,#6D28D9,#3B0764);transform:translateY(-1px);box-shadow:0 8px 24px rgba(124,58,237,.35)}
.submit-btn:active{transform:translateY(0)}

/* Divider */
.divider{display:flex;align-items:center;gap:12px;margin-bottom:20px;color:var(--muted);font-size:12.5px}
.divider::before,.divider::after{content:'';flex:1;height:1px;background:#DDD6FE}

/* Admin link */


.form-footer{text-align:center;margin-top:20px;font-size:12px;color:var(--muted)}
.form-footer a{color:var(--purple-main);font-weight:600;text-decoration:none}
</style>
</head>
<body>

<!-- ── LEFT ── -->
<div class="left">
  <span class="cross" style="top:14%;left:8%">+</span>
  <span class="cross" style="top:28%;right:15%">+</span>
  <span class="cross" style="bottom:22%;left:18%">+</span>
  <span class="cross" style="bottom:12%;right:10%">+</span>
  <span class="fpt-badge">FPT POLYTECHNIC</span>

  <div class="logo">
    <div class="logo-box">💊</div>
    <div>
      <div class="logo-name">Medi<span>Vault</span></div>
      <div class="logo-tag">Staff Portal</div>
    </div>
  </div>

  <div class="left-headline">
    <h1>Cổng nhân viên<br><span>nhà thuốc</span></h1>
    <p>Truy cập hệ thống bán hàng, quản lý kho và theo dõi ca làm việc của bạn.</p>
  </div>

  <div class="feature-pills">
    <div class="pill">Bán thuốc POS</div>
    <div class="pill">Quản lý kho</div>
    <div class="pill">Ca làm việc</div>
    <div class="pill">Hóa đơn</div>
  </div>
</div>

<!-- ── RIGHT ── -->
<div class="right">
  <div class="form-wrap">
    <div class="role-tag">NHÂN VIÊN</div>
    <h1 class="form-title">Đăng Nhập</h1>
    <p class="form-sub">Truy cập hệ thống nhà thuốc của bạn</p>

    <% if (error != null) { %>
    <div class="error-box">❌ <%= error %></div>
    <% } %>

    <form method="post" action="${pageContext.request.contextPath}/staff-login" autocomplete="off">

      <div class="input-group">
        <label class="input-label">Tên đăng nhập</label>
        <div class="input-wrap">
          <span class="input-icon">👤</span>
          <input type="text" name="username" placeholder="Nhập tên đăng nhập" autocomplete="username" required>
        </div>
      </div>

      <div class="input-group">
        <label class="input-label">Mật khẩu</label>
        <div class="input-wrap">
          <span class="input-icon">🔒</span>
          <input type="password" name="password" id="pwField" placeholder="Nhập mật khẩu" autocomplete="current-password" required>
          <button type="button" class="pw-toggle" onclick="togglePw()" id="pwBtn">👁</button>
        </div>
      </div>

      <button type="submit" class="submit-btn">
        Đăng nhập nhân viên →
      </button>
    </form>

    <div class="form-footer">
      MediVault v1.0 &nbsp;·&nbsp; <a href="#">Quên mật khẩu?</a>
    </div>
  </div>
</div>

<script>
function togglePw() {
    const f = document.getElementById('pwField');
    const b = document.getElementById('pwBtn');
    if (f.type === 'password') { f.type = 'text'; b.textContent = '🙈'; }
    else { f.type = 'password'; b.textContent = '👁'; }
}
</script>
</body>
</html>
