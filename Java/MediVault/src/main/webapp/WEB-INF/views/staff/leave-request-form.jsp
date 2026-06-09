<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%
    String uid = request.getParameter("uid");
    if (uid == null || uid.isEmpty()) { response.sendRedirect(request.getContextPath()+"/staff-login"); return; }
    com.medivault.entity.Account staffAcc = (com.medivault.entity.Account) session.getAttribute("staffAccount_"+uid);
    if (staffAcc == null) { response.sendRedirect(request.getContextPath()+"/staff-login"); return; }
    String sName     = staffAcc.getFullName() != null ? staffAcc.getFullName() : staffAcc.getUsername();
    String sInit     = sName.length()>=2 ? sName.substring(0,1).toUpperCase()+sName.substring(1,2).toUpperCase() : sName.toUpperCase();
    String sRoleName = staffAcc.getRoleId()==2 ? "Dược sĩ bán hàng" : "Thủ kho";
    // Today string
    java.time.LocalDate today = java.time.LocalDate.now();
    String todayStr = today.toString(); // yyyy-MM-dd cho input[type=date]
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="ctx" content="${pageContext.request.contextPath}">
<title>Xin nghỉ phép — MediVault</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#12082A;--dp:#1C0F3F;--main:#6D28D9;--light:#A78BFA;
  --soft:#F5F3FF;--white:#fff;--muted:#7C6FAA;--border:#E2DCF5;
  --green:#059669;--red:#DC2626;--amber:#D97706;
  --sidebar:228px;--radius:14px;
}
html,body{height:100%;font-family:'Outfit',sans-serif;background:var(--soft);color:var(--ink)}
body{display:flex}

/* ── SIDEBAR ── */
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#0E0520 0%,#1C0F3F 45%,#3B1FA0 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 24px rgba(0,0,0,.2)}
.sidebar::after{content:'';position:absolute;top:0;right:0;bottom:0;width:1px;background:linear-gradient(180deg,transparent,rgba(167,139,250,.15) 30%,rgba(167,139,250,.15) 70%,transparent)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-gem{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,var(--light),var(--main));display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;box-shadow:0 4px 16px rgba(109,40,217,.4)}
.logo-name{font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-name span{color:var(--light)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-block{padding:12px 0 4px;flex-shrink:0}
.nav-label{font-size:9px;font-weight:700;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:500;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(167,139,250,.15);font-weight:600}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--light);border-radius:2px}
.nav-icon{width:18px;height:18px;display:flex;align-items:center;justify-content:center;font-size:14px;flex-shrink:0;opacity:.85}
.nav-item.active .nav-icon{opacity:1}
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06);flex-shrink:0}
.user-card{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08)}
.user-av{width:34px;height:34px;flex-shrink:0;border-radius:9px;background:linear-gradient(135deg,var(--light),var(--main));display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:800;color:#fff}
.user-name{font-size:12.5px;font-weight:600;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:108px}
.user-role{font-size:10px;color:rgba(255,255,255,.35);margin-top:1px}
.logout-btn{margin-left:auto;width:28px;height:28px;flex-shrink:0;border-radius:8px;background:rgba(220,38,38,.12);border:none;display:flex;align-items:center;justify-content:center;color:rgba(220,38,38,.7);font-size:13px;cursor:pointer;text-decoration:none;transition:all .18s}
.logout-btn:hover{background:rgba(220,38,38,.2);color:var(--red)}

/* ── MAIN ── */
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-size:16px;font-weight:800;color:var(--ink)}
.topbar-right{margin-left:auto}
.btn-back{display:inline-flex;align-items:center;gap:6px;padding:7px 16px;border:1.5px solid var(--border);border-radius:9px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;color:var(--muted);text-decoration:none;transition:all .18s}
.btn-back:hover{border-color:var(--main);color:var(--main)}

.content{padding:28px 32px;flex:1;max-width:680px}
.page-title{font-size:22px;font-weight:900;color:var(--ink);margin-bottom:6px}
.page-sub{font-size:13.5px;color:var(--muted);margin-bottom:26px}

/* ── FORM CARDS ── */
.card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden;margin-bottom:16px}
.card-head{padding:14px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;gap:9px}
.card-head-icon{width:30px;height:30px;border-radius:8px;background:linear-gradient(135deg,rgba(109,40,217,.1),rgba(167,139,250,.1));display:flex;align-items:center;justify-content:center;font-size:14px}
.card-head h2{font-size:14px;font-weight:800;color:var(--ink)}
.card-body{padding:20px}

/* Date picker */
.fg{display:flex;flex-direction:column;gap:6px}
.fg label{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.fg input,.fg textarea{border:1.5px solid var(--border);border-radius:9px;padding:10px 14px;font-family:'Outfit',sans-serif;font-size:14px;color:var(--ink);background:#FAFAFA;outline:none;transition:border .18s,background .18s;width:100%}
.fg input:focus,.fg textarea:focus{border-color:var(--main);background:#fff;box-shadow:0 0 0 3px rgba(109,40,217,.08)}

/* Leave type cards */
.type-grid{display:grid;grid-template-columns:1fr 1fr;gap:10px}
.type-card{border:2px solid var(--border);border-radius:12px;padding:14px 16px;cursor:pointer;transition:all .2s;position:relative;background:var(--white)}
.type-card:has(input:checked){border-color:var(--main);background:linear-gradient(135deg,rgba(109,40,217,.04),rgba(167,139,250,.04));box-shadow:0 0 0 4px rgba(109,40,217,.06)}
.type-card input{position:absolute;opacity:0;width:0;height:0}
.type-icon{font-size:22px;margin-bottom:8px}
.type-name{font-size:14px;font-weight:800;color:var(--ink)}
.type-desc{font-size:11.5px;color:var(--muted);margin-top:3px}
.type-card:has(input:checked) .type-name{color:var(--main)}

/* Warning box */
.warn-box{background:#FFFBEB;border:1px solid #FDE68A;border-radius:10px;padding:12px 16px;font-size:13px;color:#92400E;margin-bottom:16px;display:flex;align-items:flex-start;gap:8px}

/* Submit */
.btn-submit{width:100%;padding:13px 0;background:linear-gradient(135deg,var(--main),#5B21B6);color:#fff;border:none;border-radius:10px;font-family:'Outfit',sans-serif;font-size:15px;font-weight:800;cursor:pointer;box-shadow:0 4px 14px rgba(109,40,217,.3);transition:all .2s}
.btn-submit:hover{transform:translateY(-1px);box-shadow:0 6px 18px rgba(109,40,217,.35)}
.btn-submit:active{transform:translateY(0)}

/* Toast */
.toast{position:fixed;top:18px;right:22px;padding:11px 18px;border-radius:10px;font-size:13px;font-weight:700;color:#fff;z-index:9999;box-shadow:0 4px 18px rgba(0,0,0,.15);animation:slideIn .3s ease;display:flex;align-items:center;gap:8px}
.toast-err{background:var(--red)}.toast-warn{background:var(--amber)}
@keyframes slideIn{from{transform:translateX(60px);opacity:0}to{transform:translateX(0);opacity:1}}

/* Animation */
@keyframes fadeUp{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}
.card:nth-child(1){animation:fadeUp .25s .05s ease both}
.card:nth-child(2){animation:fadeUp .25s .1s ease both}
.card:nth-child(3){animation:fadeUp .25s .15s ease both}
</style>
</head>
<body>

<aside class="sidebar">
  <div class="sidebar-logo">
    <div class="logo-gem">💊</div>
    <div>
      <div class="logo-name">Medi<span>Vault</span></div>
      <div class="logo-sub">Staff Portal</div>
    </div>
  </div>

  <nav class="nav-block">
    <div class="nav-label">Tổng quan</div>
    <a href="${pageContext.request.contextPath}/staff-dashboard?uid=<%= uid %>" class="nav-item">
      <span class="nav-icon">🏠</span> Trang chủ
    </a>
  </nav>

  <nav class="nav-block">
    <div class="nav-label">Cá nhân</div>
    <a href="${pageContext.request.contextPath}/staff-profile?uid=<%= uid %>"   class="nav-item">
      <span class="nav-icon">👤</span> Hồ sơ của tôi
    </a>
    <a href="${pageContext.request.contextPath}/staff-checkin?uid=<%= uid %>"   class="nav-item">
      <span class="nav-icon">✅</span> Điểm danh
    </a>
    <a href="${pageContext.request.contextPath}/staff-my-shifts?uid=<%= uid %>" class="nav-item">
      <span class="nav-icon">🕐</span> Ca làm việc
    </a>
    <a href="${pageContext.request.contextPath}/leave-requests?action=my&uid=<%= uid %>" class="nav-item active">
      <span class="nav-icon">🏖️</span> Xin nghỉ phép
    </a>
  </nav>

  <nav class="nav-block">
    <div class="nav-label">Bán hàng</div>
    <a href="${pageContext.request.contextPath}/pos?uid=<%= uid %>" class="nav-item">
      <span class="nav-icon">🛒</span> Bán thuốc (POS)
    </a>
  </nav>

  <div class="sidebar-footer">
    <div class="user-card">
      <div class="user-av"><%= sInit %></div>
      <div style="min-width:0">
        <div class="user-name"><%= sName %></div>
        <div class="user-role"><%= sRoleName %></div>
      </div>
      <a href="${pageContext.request.contextPath}/logout?from=staff&uid=<%= uid %>" class="logout-btn" title="Đăng xuất">⏻</a>
    </div>
  </div>
</aside>

<div class="main">
  <c:if test="${not empty param.msg}">
    <c:choose>
      <c:when test="${param.msg=='invalid'}"><div class="toast toast-err"  id="toast">❌ Vui lòng điền đầy đủ!</div></c:when>
      <c:when test="${param.msg=='exists'}"> <div class="toast toast-warn" id="toast">⚠️ Đã có đơn nghỉ ngày này!</div></c:when>
      <c:when test="${param.msg=='error'}">  <div class="toast toast-err"  id="toast">❌ Có lỗi xảy ra!</div></c:when>
    </c:choose>
  </c:if>

  <header class="topbar">
    <div style="font-size:16px">🏖️</div>
    <span class="topbar-title">Xin nghỉ phép</span>
    <div class="topbar-right">
      <a href="${pageContext.request.contextPath}/leave-requests?action=my&uid=<%= uid %>" class="btn-back">
        ← Đơn của tôi
      </a>
    </div>
  </header>

  <div class="content">
    <div class="page-title">Gửi đơn xin nghỉ</div>
    <div class="page-sub">Đơn sẽ được gửi Admin duyệt. Nghỉ đột xuất cần báo sớm nhất có thể.</div>

    <form method="post" action="${pageContext.request.contextPath}/leave-requests">
      <input type="hidden" name="action" value="submit">
      <input type="hidden" name="uid"    value="<%= uid %>">

      <%-- Ngày xin nghỉ --%>
      <div class="card">
        <div class="card-head">
          <div class="card-head-icon">📆</div>
          <h2>Ngày xin nghỉ</h2>
        </div>
        <div class="card-body">
          <div class="fg">
            <label>Chọn ngày</label>
            <input type="date" name="leaveDate"
                   value="<%= todayStr %>"
                   min="<%= todayStr %>"
                   required>
          </div>
        </div>
      </div>

      <%-- Loại nghỉ --%>
      <div class="card">
        <div class="card-head">
          <div class="card-head-icon">📋</div>
          <h2>Loại nghỉ</h2>
        </div>
        <div class="card-body">
          <div class="type-grid">
            <label class="type-card">
              <input type="radio" name="leaveType" value="ANNUAL" required>
              <div class="type-icon">🌴</div>
              <div class="type-name">Phép năm</div>
              <div class="type-desc">Nghỉ có lương</div>
            </label>
            <label class="type-card">
              <input type="radio" name="leaveType" value="SICK">
              <div class="type-icon">🤒</div>
              <div class="type-name">Nghỉ ốm</div>
              <div class="type-desc">Có giấy tờ y tế</div>
            </label>
            <label class="type-card">
              <input type="radio" name="leaveType" value="UNPAID">
              <div class="type-icon">💸</div>
              <div class="type-name">Không lương</div>
              <div class="type-desc">Nghỉ không hưởng lương</div>
            </label>
            <label class="type-card">
              <input type="radio" name="leaveType" value="SUDDEN">
              <div class="type-icon">⚡</div>
              <div class="type-name">Đột xuất</div>
              <div class="type-desc">Lý do khẩn cấp</div>
            </label>
          </div>
        </div>
      </div>

      <%-- Lý do --%>
      <div class="card">
        <div class="card-head">
          <div class="card-head-icon">✏️</div>
          <h2>Lý do xin nghỉ</h2>
        </div>
        <div class="card-body">
          <div class="warn-box">
            ⚠️ Nghỉ đột xuất có thể bị trừ lương nếu không có lý do chính đáng. Admin sẽ xem xét từng trường hợp cụ thể.
          </div>
          <div class="fg">
            <label>Mô tả lý do</label>
            <textarea name="reason" rows="4"
                      placeholder="Mô tả lý do xin nghỉ..."
                      required></textarea>
          </div>
        </div>
      </div>

      <button type="submit" class="btn-submit">📤 Gửi đơn xin nghỉ</button>
    </form>
  </div>
</div>

<script>
const t = document.getElementById('toast');
if (t) setTimeout(() => { t.style.opacity = '0'; setTimeout(() => t.remove(), 400); }, 3500);
</script>
</body>
</html>
