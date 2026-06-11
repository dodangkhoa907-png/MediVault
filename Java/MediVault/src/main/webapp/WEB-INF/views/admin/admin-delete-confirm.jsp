<%@ page contentType="text/html;charset=UTF-8" %>
<%
    com.medivault.entity.Account admin = (com.medivault.entity.Account) session.getAttribute("adminAccount");
    if (admin == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    com.medivault.entity.Account delTarget = (com.medivault.entity.Account) request.getAttribute("deleteTarget");
    if (delTarget == null) { response.sendRedirect(request.getContextPath() + "/accounts?action=trash"); return; }
    String targetName = delTarget.getFullName() != null ? delTarget.getFullName() : delTarget.getUsername();
    String av = targetName.length() >= 2
        ? targetName.substring(0,1).toUpperCase() + targetName.substring(1,2).toUpperCase()
        : targetName.toUpperCase();
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Xác nhận xóa — MediVault</title>
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
.warn-badge{display:inline-flex;align-items:center;gap:6px;background:#FEF2F2;border:1px solid #FECACA;
  border-radius:20px;padding:5px 14px;margin-bottom:14px;font-size:12px;font-weight:600;color:var(--red);}
h2{font-family:'DM Serif Display',serif;font-size:24px;color:var(--ink);margin-bottom:6px}
.subtitle{font-size:13px;color:var(--muted);margin-bottom:20px;line-height:1.55}
.target-card{background:#FEF2F2;border:1.5px solid #FECACA;border-radius:12px;
  padding:14px 16px;margin-bottom:20px;display:flex;align-items:center;gap:12px;}
.target-av{width:40px;height:40px;border-radius:10px;flex-shrink:0;
  background:linear-gradient(135deg,#EF4444,#DC2626);
  display:flex;align-items:center;justify-content:center;font-size:14px;font-weight:800;color:#fff;}
.target-name{font-size:14px;font-weight:700;color:#991B1B}
.target-user{font-size:12px;color:#B91C1C;margin-top:2px}
.field-label{font-size:12.5px;font-weight:600;color:var(--ink);display:block;margin-bottom:7px}
.field-input{width:100%;padding:12px 16px;background:#fff;border:1.5px solid var(--border);
  border-radius:11px;font-family:'Outfit',sans-serif;font-size:15px;font-weight:700;
  color:var(--ink);outline:none;transition:all .2s;letter-spacing:2px;text-align:center;}
.field-input:focus{border-color:var(--red);box-shadow:0 0 0 3px rgba(220,38,38,.1)}
.hint-text{font-size:12px;margin-top:6px;font-weight:600;min-height:18px;text-align:center}
.btn-row{display:flex;gap:10px;margin-top:20px}
.btn-danger{flex:1;padding:13px;background:linear-gradient(135deg,var(--red),#B91C1C);
  color:#fff;border:none;border-radius:12px;font-family:'Outfit',sans-serif;
  font-size:15px;font-weight:700;cursor:pointer;transition:all .22s;
  box-shadow:0 4px 14px rgba(220,38,38,.3);}
.btn-danger:hover:not(:disabled){transform:translateY(-1px)}
.btn-danger:disabled{opacity:.4;cursor:not-allowed}
.btn-cancel{padding:13px 18px;background:#fff;color:var(--muted);border:1.5px solid var(--border);
  border-radius:12px;font-family:'Outfit',sans-serif;font-size:14px;font-weight:600;
  cursor:pointer;transition:all .2s;text-decoration:none;display:flex;align-items:center;}
.btn-cancel:hover{border-color:var(--red);color:var(--red)}
</style>
</head>
<body>
<%@ include file="/WEB-INF/views/loading.jsp" %>

<div class="card">
  <div class="logo-row">
    <div class="logo-icon">🗑️</div>
    <div class="logo-text">MediVault — Xóa vĩnh viễn</div>
  </div>
  <div class="warn-badge">⚠️ Bước 1 / 2 — Không thể hoàn tác</div>
  <h2>Xác nhận xóa tài khoản</h2>
  <p class="subtitle">Gõ <strong style="color:var(--red)">"delete"</strong> vào ô bên dưới rồi bấm tiếp tục để nhận OTP xác nhận cuối cùng.</p>

  <div class="target-card">
    <div class="target-av"><%= av %></div>
    <div>
      <div class="target-name"><%= targetName %></div>
      <div class="target-user">@<%= delTarget.getUsername() %></div>
    </div>
  </div>

  <form method="get" action="${pageContext.request.contextPath}/accounts" id="confirmForm">
    <input type="hidden" name="action" value="delete-otp-page">
    <input type="hidden" name="id" value="<%= delTarget.getAccountId() %>">
    <label class="field-label">Nhập <strong>"delete"</strong> để tiếp tục</label>
    <input type="text" id="confirmInput" class="field-input"
           placeholder="delete" autocomplete="off" oninput="checkInput(this)">
    <div class="hint-text" id="hintText"></div>
    <div class="btn-row">
      <button type="submit" class="btn-danger" id="submitBtn" disabled>
        Tiếp tục → Gửi OTP
      </button>
      <a href="${pageContext.request.contextPath}/accounts?action=trash" class="btn-cancel">Hủy</a>
    </div>
  </form>
</div>
<script>
function checkInput(inp) {
  const val = inp.value.trim().toLowerCase();
  const btn  = document.getElementById('submitBtn');
  const hint = document.getElementById('hintText');
  if (!val) { hint.textContent=''; inp.style.borderColor=''; btn.disabled=true; return; }
  if (val === 'delete') {
    hint.innerHTML = '<span style="color:#059669">✅ Xác nhận — bấm tiếp tục để nhận OTP</span>';
    inp.style.borderColor = '#059669';
    inp.style.boxShadow   = '0 0 0 3px rgba(5,150,105,.1)';
    btn.disabled = false;
  } else {
    hint.innerHTML = '<span style="color:#DC2626">❌ Phải gõ đúng chữ <strong>"delete"</strong></span>';
    inp.style.borderColor = '#DC2626';
    inp.style.boxShadow   = '0 0 0 3px rgba(220,38,38,.1)';
    btn.disabled = true;
  }
}
let _submitted = false;
document.getElementById('confirmForm').addEventListener('submit', function(e) {
  const val = document.getElementById('confirmInput').value.trim().toLowerCase();
  if (val !== 'delete') { e.preventDefault(); return; }
  if (_submitted) { e.preventDefault(); return; }
  _submitted = true;
  const btn = document.getElementById('submitBtn');
  btn.disabled = true;
  btn.textContent = '⏳ Đang gửi OTP...';
  btn.style.opacity = '0.7';
});
document.getElementById('confirmInput').addEventListener('keydown', function(e) {
  if (e.key === 'Enter') {
    e.preventDefault();
    if (this.value.trim().toLowerCase() === 'delete' && !_submitted) {
      document.getElementById('confirmForm').submit();
    }
  }
});
</script>
</body>
</html>
