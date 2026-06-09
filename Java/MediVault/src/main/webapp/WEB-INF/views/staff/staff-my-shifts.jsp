<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%
    com.medivault.entity.Account acc =
        (com.medivault.entity.Account) session.getAttribute("adminAccount");
    String uid = request.getParameter("uid");

    // Auth: staff phải đăng nhập qua staffAccount_uid
    com.medivault.entity.Account staffAcc = null;
    if (uid != null && !uid.isEmpty() && session != null)
        staffAcc = (com.medivault.entity.Account) session.getAttribute("staffAccount_" + uid);
    if (staffAcc == null) { response.sendRedirect(request.getContextPath() + "/staff-login"); return; }
    if (staffAcc.getRoleId() == 1) { response.sendRedirect(request.getContextPath() + "/dashboard"); return; }

    java.lang.String dn      = staffAcc.getFullName() != null ? staffAcc.getFullName() : staffAcc.getUsername();
    java.lang.String initials = dn.length() >= 2
        ? dn.substring(0,1).toUpperCase() + dn.substring(1,2).toUpperCase()
        : dn.toUpperCase();
    java.lang.String roleName = staffAcc.getRoleId() == 2 ? "Dược sĩ bán hàng" : "Thủ kho";

    com.medivault.entity.Shift currentShift  = (com.medivault.entity.Shift)  request.getAttribute("currentShift");
    @SuppressWarnings("unchecked")
    java.util.List<com.medivault.entity.Shift> allShifts =
        (java.util.List<com.medivault.entity.Shift>) request.getAttribute("allShifts");
    if (allShifts == null) allShifts = new java.util.ArrayList<>();

    java.lang.String msg = request.getParameter("msg");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Ca làm việc của tôi — MediVault</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;
  --sidebar:220px;
}
html,body{height:100%;font-family:'Outfit',sans-serif;background:var(--surface);color:var(--ink)}
body{display:flex}

/* ── SIDEBAR ── */
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);
  display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;
  box-shadow:4px 0 24px rgba(0,0,0,.18)}
.sidebar-logo{height:62px;padding:0 18px;display:flex;align-items:center;gap:10px;
  border-bottom:1px solid rgba(255,255,255,.07);flex-shrink:0}
.logo-icon{width:34px;height:34px;border-radius:9px;
  background:linear-gradient(135deg,var(--cyan),var(--blue));
  display:flex;align-items:center;justify-content:center;font-size:15px;flex-shrink:0}
.logo-text{font-family:'Outfit',sans-serif;font-size:15px;font-weight:800;color:#fff;letter-spacing:-.2px}
.logo-text span{color:var(--cyan)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.28);letter-spacing:1px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:10px 0 2px;flex-shrink:0}
.nav-label{font-size:9px;font-weight:700;letter-spacing:1.8px;text-transform:uppercase;
  color:rgba(255,255,255,.2);padding:0 18px 5px}
.nav-item{display:flex;align-items:center;gap:9px;padding:9px 10px 9px 18px;
  margin:1px 8px;border-radius:9px;font-size:13px;font-weight:500;
  color:rgba(255,255,255,.5);text-decoration:none;transition:all .16s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.15);font-weight:700}
.nav-item.active::before{content:'';position:absolute;left:-8px;top:50%;transform:translateY(-50%);
  width:3px;height:54%;background:var(--cyan);border-radius:2px}
.sidebar-footer{margin-top:auto;padding:12px 14px;border-top:1px solid rgba(255,255,255,.06);flex-shrink:0}
.user-card{display:flex;align-items:center;gap:9px;padding:9px 10px;border-radius:10px;
  background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.07)}
.user-av{width:32px;height:32px;flex-shrink:0;border-radius:8px;
  background:linear-gradient(135deg,var(--cyan),var(--blue));
  display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;color:#fff}
.user-name{font-size:12px;font-weight:700;color:#fff;line-height:1.2}
.user-role{font-size:10px;color:rgba(255,255,255,.35)}
.logout-btn{margin-left:auto;font-size:16px;color:rgba(255,255,255,.4);text-decoration:none;
  transition:color .18s;flex-shrink:0;padding:4px}
.logout-btn:hover{color:#FC8181}

/* ── MAIN ── */
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh}
.topbar{height:60px;background:var(--white);border-bottom:1px solid var(--border);
  display:flex;align-items:center;padding:0 26px;gap:12px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Outfit',sans-serif;font-size:16px;font-weight:700;color:var(--ink)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.back-btn{padding:7px 14px;border-radius:8px;background:var(--surface);border:1.5px solid var(--border);
  color:var(--muted);font-size:12.5px;font-weight:600;text-decoration:none;transition:all .18s}
.back-btn:hover{background:var(--border)}
.content{padding:24px 28px;flex:1}
.page-head{margin-bottom:22px}
.breadcrumb{font-size:12px;color:var(--muted);margin-bottom:4px}
.page-head h1{font-family:'Outfit',sans-serif;font-size:24px;font-weight:800;color:var(--ink)}

/* ── TOAST ── */
.toast{position:fixed;top:20px;right:24px;padding:12px 20px;border-radius:11px;
  font-size:13.5px;font-weight:600;display:flex;align-items:center;gap:8px;
  box-shadow:0 8px 32px rgba(0,0,0,.18);z-index:999;transition:opacity .4s}
.toast-ok{background:#D1FAE5;color:#065F46}
.toast-err{background:#FEE2E2;color:#991B1B}
.toast-warn{background:#FEF3C7;color:#92400E}

/* ── CURRENT SHIFT CARD ── */
.current-card{
  border-radius:16px;overflow:hidden;margin-bottom:24px;
  border:2px solid transparent;
}
.current-card.active{
  background:linear-gradient(135deg,#ECFDF5,#F0FFF4);
  border-color:#A7F3D0;
}
.current-card.no-shift{
  background:linear-gradient(135deg,#F8FAFC,#F1F5F9);
  border-color:#E2E8F0;
}
.current-head{
  padding:18px 22px;display:flex;align-items:center;justify-content:space-between;
  border-bottom:1px solid rgba(0,0,0,.06);flex-wrap:wrap;gap:10px;
}
.current-head-left{display:flex;align-items:center;gap:10px}
.current-title{font-size:15px;font-weight:800;color:var(--ink)}
.live-badge{
  display:inline-flex;align-items:center;gap:6px;
  background:#D1FAE5;color:#065F46;border-radius:20px;padding:4px 12px;
  font-size:12px;font-weight:700;
}
.dot-live{width:7px;height:7px;border-radius:50%;background:#10B981;
  animation:pulse 1.5s infinite}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:.35}}
.no-shift-badge{
  display:inline-flex;align-items:center;gap:6px;
  background:#F1F5F9;color:#64748B;border-radius:20px;padding:4px 12px;
  font-size:12px;font-weight:600;
}

.current-body{padding:18px 22px}
.shift-info-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:14px;margin-bottom:18px}
.shift-info-item{background:rgba(255,255,255,.7);border-radius:10px;padding:12px 14px;border:1px solid rgba(0,0,0,.07)}
.shift-info-lbl{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.6px;margin-bottom:4px}
.shift-info-val{font-size:14px;font-weight:700;color:var(--ink)}
.shift-info-val.green{color:var(--green)}
.duration-live{font-size:12px;color:var(--green);margin-top:3px;font-weight:600}

/* Open/Close shift forms */
.shift-action-row{display:flex;gap:12px;flex-wrap:wrap;align-items:flex-end}
.fg{display:flex;flex-direction:column;gap:5px}
.fg label{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.fg input,
.fg textarea{border:1.5px solid var(--border);border-radius:9px;padding:9px 13px;
  font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);outline:none;transition:border .18s}
.fg input:focus,.fg textarea:focus{border-color:var(--blue)}
.fg textarea{resize:vertical;min-height:66px;width:220px}
.btn-open{
  padding:10px 20px;background:linear-gradient(135deg,#1558A8,#0D3F85);
  color:#fff;border:none;border-radius:9px;font-family:'Outfit',sans-serif;
  font-size:13px;font-weight:700;cursor:pointer;transition:all .2s;
  box-shadow:0 4px 12px rgba(21,88,168,.25);white-space:nowrap;align-self:flex-end
}
.btn-open:hover{opacity:.9;transform:translateY(-1px)}
.btn-close{
  padding:10px 20px;background:linear-gradient(135deg,#DC2626,#B91C1C);
  color:#fff;border:none;border-radius:9px;font-family:'Outfit',sans-serif;
  font-size:13px;font-weight:700;cursor:pointer;transition:all .2s;
  box-shadow:0 4px 12px rgba(220,38,38,.25);white-space:nowrap;align-self:flex-end
}
.btn-close:hover{opacity:.9}

/* ── HISTORY TABLE ── */
.section-card{background:var(--white);border:1px solid var(--border);border-radius:14px;overflow:hidden}
.section-head{
  padding:16px 22px;border-bottom:1px solid var(--border);
  display:flex;align-items:center;justify-content:space-between;
}
.section-head h2{font-family:'Outfit',sans-serif;font-size:15px;font-weight:800;color:var(--ink)}
.section-head-sub{font-size:12px;color:var(--muted)}
.table-wrap{overflow-x:auto}
table{width:100%;border-collapse:collapse}
thead th{
  padding:11px 16px;font-size:11.5px;font-weight:700;color:var(--muted);
  text-align:left;text-transform:uppercase;letter-spacing:.6px;
  background:#F8FAFC;border-bottom:1px solid var(--border);white-space:nowrap
}
tbody tr{border-bottom:1px solid #F1F5F9;transition:background .14s}
tbody tr:last-child{border-bottom:none}
tbody tr:hover{background:#F8FAFC}
tbody td{padding:12px 16px;font-size:13px;color:var(--ink)}
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:12px;font-weight:600}
.badge-green{background:#D1FAE5;color:#065F46}
.badge-gray{background:#F1F5F9;color:#475569}
.badge-red{background:#FEE2E2;color:#991B1B}
.money{font-family:'Outfit',sans-serif;font-weight:700;color:var(--ink)}
.empty-state{padding:48px 20px;text-align:center;color:var(--muted)}
.empty-state .empty-icon{font-size:36px;margin-bottom:12px}
.empty-state p{font-size:13.5px}
</style>
</head>
<body>

<!-- SIDEBAR -->
<aside class="sidebar">
  <div class="sidebar-logo">
    <div class="logo-icon">💊</div>
    <div>
      <div class="logo-text">Medi<span>Vault</span></div>
      <div class="logo-sub">Staff Portal</div>
    </div>
  </div>
  <nav class="nav-section">
    <div class="nav-label">Tổng quan</div>
    <a href="<%= request.getContextPath() %>/staff-dashboard?uid=<%= uid %>" class="nav-item">
      <span>🏠</span> Trang chủ
    </a>
  </nav>
  <nav class="nav-section">
    <div class="nav-label">Cá nhân</div>
    <a href="<%= request.getContextPath() %>/staff-profile?uid=<%= uid %>" class="nav-item">
      <span>👤</span> Hồ sơ của tôi
    </a>
    <a href="<%= request.getContextPath() %>/staff-my-shifts?uid=<%= uid %>" class="nav-item active">
      <span>📅</span> Ca làm việc
    </a>
  </nav>
  <% if (staffAcc.getRoleId() == 2) { %>
  <nav class="nav-section">
    <div class="nav-label">Bán hàng</div>
    <a href="<%= request.getContextPath() %>/pos" class="nav-item">
      <span>🛒</span> Bán thuốc (POS)
    </a>
  </nav>
  <% } %>
  <div style="flex:1"></div>
  <div class="sidebar-footer">
    <div class="user-card">
      <div class="user-av"><%= initials %></div>
      <div>
        <div class="user-name"><%= dn %></div>
        <div class="user-role"><%= roleName %></div>
      </div>
      <a href="<%= request.getContextPath() %>/logout?from=staff" class="logout-btn" title="Đăng xuất">⏻</a>
    </div>
  </div>
</aside>

<!-- MAIN -->
<div class="main">
  <header class="topbar">
    <span class="topbar-title">📅 Ca làm việc của tôi</span>
    <div class="topbar-right">
      <a href="<%= request.getContextPath() %>/staff-dashboard?uid=<%= uid %>" class="back-btn">← Dashboard</a>
    </div>
  </header>

  <div class="content">
    <div class="page-head">
      <div class="breadcrumb">MediVault › Ca làm việc</div>
      <h1>Ca làm việc của tôi</h1>
    </div>

    <%-- Toast --%>
    <%
      java.lang.String toastCls = "", toastMsg = "";
      if ("opened".equals(msg))      { toastCls="toast-ok";   toastMsg="✅ Đã mở ca thành công!"; }
      else if ("already-open".equals(msg)) { toastCls="toast-warn"; toastMsg="⚠️ Bạn đang có ca chưa đóng!"; }
      else if ("closed".equals(msg)) { toastCls="toast-ok";   toastMsg="✅ Đã đóng ca thành công!"; }
      else if ("already-closed".equals(msg)) { toastCls="toast-warn"; toastMsg="⚠️ Ca đã được đóng rồi!"; }
      else if ("error".equals(msg))  { toastCls="toast-err";  toastMsg="❌ Có lỗi xảy ra, thử lại!"; }
      if (!toastMsg.isEmpty()) {
    %><div class="toast <%= toastCls %>" id="toast"><%= toastMsg %></div><% } %>

    <%-- ── Ca hiện tại ── --%>
    <div class="current-card <%= currentShift != null ? "active" : "no-shift" %>">
      <div class="current-head">
        <div class="current-head-left">
          <span class="current-title">Ca hiện tại</span>
          <% if (currentShift != null) { %>
          <span class="live-badge"><span class="dot-live"></span>Đang hoạt động</span>
          <% } else { %>
          <span class="no-shift-badge">⏸ Không có ca</span>
          <% } %>
        </div>
        <span style="font-size:12px;color:var(--muted)" id="clockNow"></span>
      </div>

      <div class="current-body">
        <% if (currentShift != null) { %>
        <%
          java.time.LocalDateTime st = currentShift.getStartTime();
          java.time.format.DateTimeFormatter dtf = java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
        %>
        <div class="shift-info-grid">
          <div class="shift-info-item">
            <div class="shift-info-lbl">Mã ca</div>
            <div class="shift-info-val">#<%= currentShift.getShiftId() %></div>
          </div>
          <div class="shift-info-item">
            <div class="shift-info-lbl">Bắt đầu</div>
            <div class="shift-info-val green"><%= st != null ? st.format(dtf) : "—" %></div>
            <div class="duration-live" id="durationLive">Đang tính...</div>
          </div>
          <div class="shift-info-item">
            <div class="shift-info-lbl">Tiền đầu ca</div>
            <div class="shift-info-val"><%= currentShift.getOpeningCash() != null
                ? String.format("%,.0f₫", currentShift.getOpeningCash()) : "0₫" %></div>
          </div>
        </div>

        <%-- Đóng ca --%>
        <form method="post" action="<%= request.getContextPath() %>/staff-shift?uid=<%= uid %>">
          <input type="hidden" name="action" value="close">
          <input type="hidden" name="shiftId" value="<%= currentShift.getShiftId() %>">
          <div class="shift-action-row">
            <div class="fg">
              <label>Tiền cuối ca (₫)</label>
              <input type="number" name="closingCash" min="0" step="1000"
                     placeholder="0" style="width:160px"
                     value="<%= currentShift.getOpeningCash() != null ? currentShift.getOpeningCash().toPlainString() : "0" %>">
            </div>
            <div class="fg">
              <label>Ghi chú</label>
              <textarea name="notes" placeholder="Ghi chú khi đóng ca (tùy chọn)..."></textarea>
            </div>
            <button type="submit" class="btn-close"
                    onclick="return confirm('Xác nhận đóng ca #<%= currentShift.getShiftId() %>?')">
              🔴 Đóng ca
            </button>
          </div>
        </form>

        <% } else { %>

        <%-- Mở ca --%>
        <p style="font-size:13.5px;color:var(--muted);margin-bottom:16px">
          Bạn hiện không có ca nào đang mở. Mở ca để bắt đầu làm việc.
        </p>
        <form method="post" action="<%= request.getContextPath() %>/staff-shift?uid=<%= uid %>">
          <input type="hidden" name="action" value="open">
          <div class="shift-action-row">
            <div class="fg">
              <label>Tiền đầu ca (₫)</label>
              <input type="number" name="openingCash" min="0" step="1000"
                     placeholder="0" style="width:160px">
            </div>
            <button type="submit" class="btn-open">🟢 Mở ca</button>
          </div>
        </form>

        <% } %>
      </div>
    </div>

    <%-- ── Lịch sử ca ── --%>
    <div class="section-card">
      <div class="section-head">
        <h2>📋 Lịch sử ca làm việc</h2>
        <span class="section-head-sub">Tất cả ca của bạn — mới nhất trước</span>
      </div>

      <div class="table-wrap">
        <table>
          <thead>
            <tr>
              <th>Mã ca</th>
              <th>Bắt đầu</th>
              <th>Kết thúc</th>
              <th>Thời lượng</th>
              <th>Tiền đầu ca</th>
              <th>Tiền cuối ca</th>
              <th>Ghi chú</th>
              <th>Trạng thái</th>
            </tr>
          </thead>
          <tbody>
            <% if (allShifts.isEmpty()) { %>
            <tr><td colspan="8">
              <div class="empty-state">
                <div class="empty-icon">📅</div>
                <p>Bạn chưa có ca làm việc nào.</p>
              </div>
            </td></tr>
            <% } else {
               java.time.format.DateTimeFormatter dtfFull = java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");
               for (com.medivault.entity.Shift s : allShifts) {
                   boolean isOpen = (s.getEndTime() == null);
                   java.lang.String dur = "—";
                   if (s.getStartTime() != null && s.getEndTime() != null) {
                       long mins = java.time.Duration.between(s.getStartTime(), s.getEndTime()).toMinutes();
                       dur = (mins / 60) + "g " + (mins % 60) + "p";
                   }
            %>
            <tr>
              <td style="font-weight:700;color:var(--blue)">#<%= s.getShiftId() %></td>
              <td style="color:var(--muted);font-size:12.5px">
                <%= s.getStartTime() != null ? s.getStartTime().format(dtfFull) : "—" %>
              </td>
              <td style="color:var(--muted);font-size:12.5px">
                <%= !isOpen && s.getEndTime() != null ? s.getEndTime().format(dtfFull) : "—" %>
              </td>
              <td><%= dur %></td>
              <td class="money">
                <%= s.getOpeningCash() != null ? String.format("%,.0f₫", s.getOpeningCash()) : "0₫" %>
              </td>
              <td class="money">
                <%= !isOpen && s.getClosingCash() != null
                    ? String.format("%,.0f₫", s.getClosingCash()) : "—" %>
              </td>
              <td style="font-size:12.5px;color:var(--muted)">
                <%= s.getNotes() != null && !s.getNotes().isEmpty() ? s.getNotes() : "—" %>
              </td>
              <td>
                <% if (isOpen) { %>
                  <span class="badge badge-green">🟢 Đang mở</span>
                <% } else { %>
                  <span class="badge badge-gray">✅ Đã đóng</span>
                <% } %>
              </td>
            </tr>
            <% } } %>
          </tbody>
        </table>
      </div>
    </div>
  </div><%-- /content --%>
</div><%-- /main --%>

<script>
// Clock
function updateClock() {
  const now = new Date();
  const p = n => n.toString().padStart(2,'0');
  document.getElementById('clockNow').textContent =
    p(now.getHours()) + ':' + p(now.getMinutes()) + ':' + p(now.getSeconds()) +
    ' — ' + now.toLocaleDateString('vi-VN');
}
setInterval(updateClock, 1000);
updateClock();

// Duration live counter
<% if (currentShift != null && currentShift.getStartTime() != null) { %>
const shiftStartMs = <%= currentShift.getStartTime().atZone(java.time.ZoneId.of("Asia/Ho_Chi_Minh")).toInstant().toEpochMilli() %>;
function updateDuration() {
  const diffMs = Date.now() - shiftStartMs;
  const h = Math.floor(diffMs / 3600000);
  const m = Math.floor((diffMs % 3600000) / 60000);
  const s = Math.floor((diffMs % 60000) / 1000);
  const pad = n => n.toString().padStart(2,'0');
  const el = document.getElementById('durationLive');
  if (el) el.textContent = h + 'g ' + pad(m) + 'p ' + pad(s) + 's';
}
setInterval(updateDuration, 1000);
updateDuration();
<% } %>

// Toast auto-hide
const toast = document.getElementById('toast');
if (toast) setTimeout(() => { toast.style.opacity='0'; setTimeout(()=>toast.remove(),400); }, 3500);
</script>
</body>
</html>
