<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<% String activeNav = "shifts"; %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    String uid = request.getParameter("uid");
    if (uid == null || uid.isEmpty()) { response.sendRedirect(request.getContextPath()+"/staff-login"); return; }
    com.medivault.entity.Account staffAcc = (com.medivault.entity.Account) session.getAttribute("staffAccount_"+uid);
    if (staffAcc == null) { response.sendRedirect(request.getContextPath()+"/staff-login"); return; }
    String sName     = staffAcc.getFullName() != null ? staffAcc.getFullName() : staffAcc.getUsername();
    String sInit     = sName.length()>=2 ? sName.substring(0,1).toUpperCase()+sName.substring(1,2).toUpperCase() : sName.toUpperCase();
    String sRoleName = staffAcc.getRoleId()==2 ? "Dược sĩ bán hàng" : "Thủ kho";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<meta name="ctx" content="${pageContext.request.contextPath}">
<title>Đơn nghỉ của tôi — MediVault</title>
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
.topbar-icon{width:34px;height:34px;border-radius:9px;background:linear-gradient(135deg,rgba(109,40,217,.1),rgba(167,139,250,.1));display:flex;align-items:center;justify-content:center;font-size:16px}
.topbar-title{font-size:16px;font-weight:800;color:var(--ink)}
.topbar-right{margin-left:auto}
.btn-new{display:inline-flex;align-items:center;gap:7px;padding:8px 18px;background:var(--main);color:#fff;border:none;border-radius:9px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;cursor:pointer;text-decoration:none;box-shadow:0 3px 10px rgba(109,40,217,.25);transition:all .18s}
.btn-new:hover{background:#5B21B6;transform:translateY(-1px)}
.content{padding:24px 28px;flex:1}

/* ── TOAST ── */
.toast{position:fixed;top:18px;right:22px;padding:11px 18px;border-radius:10px;font-size:13px;font-weight:700;color:#fff;z-index:9999;box-shadow:0 4px 18px rgba(0,0,0,.15);animation:slideIn .3s ease;display:flex;align-items:center;gap:8px}
.toast-ok{background:#059669}.toast-err{background:#DC2626}.toast-warn{background:#D97706}
@keyframes slideIn{from{transform:translateX(60px);opacity:0}to{transform:translateX(0);opacity:1}}

/* ── CARDS ── */
.table-card{background:var(--white);border:1px solid var(--border);border-radius:var(--radius);overflow:hidden}
.table-card-head{padding:14px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
.table-card-head h2{font-size:14px;font-weight:800;color:var(--ink)}
.tc-sub{font-size:12px;color:var(--muted)}

table{width:100%;border-collapse:collapse}
thead th{padding:9px 16px;background:#F8FAFC;font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;border-bottom:1px solid var(--border);white-space:nowrap}
tbody td{padding:12px 16px;font-size:13px;border-bottom:1px solid #F1F5F9;vertical-align:middle}
tbody tr:last-child td{border-bottom:none}
tbody tr:hover td{background:#F8F5FF}

.badge{display:inline-flex;align-items:center;gap:5px;padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:700}
.badge-PENDING{background:#FEF3C7;color:#92400E}
.badge-APPROVED{background:#ECFDF5;color:#065F46}
.badge-REJECTED{background:#FEF2F2;color:#991B1B}
.badge-ANNUAL{background:#EFF6FF;color:#1E40AF}
.badge-SICK{background:#FFF7ED;color:#92400E}
.badge-UNPAID{background:#F5F3FF;color:var(--main)}
.badge-SUDDEN{background:#FEF2F2;color:#DC2626}

.empty-state{padding:60px 20px;text-align:center}
.empty-state .ei{font-size:48px;margin-bottom:14px}
.empty-state p{font-size:14px;color:var(--muted);margin-bottom:16px}

/* Animation */
@keyframes fadeUp{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:translateY(0)}}
.table-card{animation:fadeUp .3s ease both}
</style>
</head>
<body>

<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">
  <%-- Toast --%>
  <c:if test="${not empty param.msg}">
    <c:choose>
      <c:when test="${param.msg=='submitted'}"><div class="toast toast-ok"  id="toast">✅ Đã gửi đơn xin nghỉ!</div></c:when>
      <c:when test="${param.msg=='error'}">    <div class="toast toast-err" id="toast">❌ Có lỗi xảy ra!</div></c:when>
      <c:when test="${param.msg=='exists'}">   <div class="toast toast-warn"id="toast">⚠️ Đã có đơn nghỉ ngày này!</div></c:when>
    </c:choose>
  </c:if>

  <header class="topbar">
    <div class="topbar-icon">🏖️</div>
    <span class="topbar-title">Đơn nghỉ của tôi</span>
    <div class="topbar-right">
      <a href="${pageContext.request.contextPath}/leave-requests?action=new&uid=<%= uid %>" class="btn-new">
        ➕ Xin nghỉ mới
      </a>
    </div>
  </header>

  <div class="content">
    <div class="table-card">
      <div class="table-card-head">
        <h2>📋 Đơn nghỉ tháng ${month}/${year}</h2>
        <span class="tc-sub">${fn:length(leaves)} đơn</span>
      </div>

      <c:choose>
        <c:when test="${empty leaves}">
          <div class="empty-state">
            <div class="ei">🌴</div>
            <p>Bạn chưa có đơn xin nghỉ tháng này.</p>
            <a href="${pageContext.request.contextPath}/leave-requests?action=new&uid=<%= uid %>" class="btn-new">
              ➕ Gửi đơn xin nghỉ
            </a>
          </div>
        </c:when>
        <c:otherwise>
          <table>
            <thead>
              <tr>
                <th>Ngày nghỉ</th>
                <th>Loại</th>
                <th>Lý do</th>
                <th>Trạng thái</th>
                <th>Ghi chú Admin</th>
              </tr>
            </thead>
            <tbody>
              <c:forEach var="lr" items="${leaves}">
                <tr>
                  <td style="font-weight:700">${lr.leaveDate}</td>
                  <td>
                    <span class="badge badge-${lr.leaveType}">
                      <c:choose>
                        <c:when test="${lr.leaveType=='ANNUAL'}">🌴 Phép năm</c:when>
                        <c:when test="${lr.leaveType=='SICK'}">🤒 Nghỉ ốm</c:when>
                        <c:when test="${lr.leaveType=='UNPAID'}">💸 Không lương</c:when>
                        <c:otherwise>⚡ Đột xuất</c:otherwise>
                      </c:choose>
                    </span>
                  </td>
                  <td style="font-size:12.5px;color:var(--muted);max-width:220px">${lr.reason}</td>
                  <td>
                    <span class="badge badge-${lr.status}">
                      <c:choose>
                        <c:when test="${lr.status=='PENDING'}">⏳ Chờ duyệt</c:when>
                        <c:when test="${lr.status=='APPROVED'}">✅ Đã duyệt</c:when>
                        <c:otherwise>❌ Từ chối</c:otherwise>
                      </c:choose>
                    </span>
                  </td>
                  <td style="font-size:12px;color:var(--muted)">${not empty lr.notes ? lr.notes : '—'}</td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </c:otherwise>
      </c:choose>
    </div>
  </div>
</div>

<script>
const t = document.getElementById('toast');
if (t) setTimeout(() => { t.style.opacity = '0'; setTimeout(() => t.remove(), 400); }, 3500);
</script>
</body>
</html>
