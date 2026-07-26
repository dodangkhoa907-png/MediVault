<%@ page contentType="text/html;charset=UTF-8" language="java"  pageEncoding="UTF-8" %>
<% String activeNav = "attendance"; %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length()>=2 ? fullName.substring(0,1).toUpperCase()+fullName.substring(1,2).toUpperCase() : fullName.toUpperCase();
%>
<!DOCTYPE html><html lang="vi"><head>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
    
    
    
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Tổng hợp tháng — medicare</title>

<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--ink:#0B1628;--blue:#1558A8;--cyan:#3ABDE0;--surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;--green:#059669;--red:#DC2626;--amber:#F59E0B;--sidebar:232px;--radius:14px}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif;background:var(--surface);color:var(--ink)}body{display:flex}
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06)}
.logo-icon{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:16px}
.logo-text{font-size:16px;font-weight:800;color:#fff}.logo-text span{color:var(--cyan)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:12px 0 4px}.nav-label{font-size:9px;font-weight:750;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:750;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.14);font-weight:750}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--cyan);border-radius:2px}
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06)}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08)}
.user-av{width:34px;height:34px;border-radius:9px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.user-name{font-size:12.5px;font-weight:750;color:#fff;max-width:110px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.user-role{font-size:10px;color:rgba(255,255,255,.35);margin-top:1px}
.logout-btn{margin-left:auto;width:28px;height:28px;border-radius:8px;background:rgba(220,38,38,.12);border:none;display:flex;align-items:center;justify-content:center;color:rgba(220,38,38,.7);font-size:13px;cursor:pointer;text-decoration:none}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Plus Jakarta Sans',sans-serif;font-size:16px;font-weight:750;color:var(--ink)}

    
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.content{padding:22px 26px;flex:1}
.table-card{background:#fff;border:1px solid rgba(213,224,240,.45);border-radius:var(--radius);overflow:hidden;margin-bottom:18px;box-shadow:0 1px 3px rgba(15,38,69,.03),0 4px 12px rgba(15,38,69,.04)}
.table-card-head{padding:14px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
.table-card-head h2{font-size:14px;font-weight:800;color:var(--ink)}
.tc-sub{font-size:12px;color:var(--muted)}
table{width:100%;border-collapse:collapse}
thead th{padding:9px 16px;background:#F8FAFC;font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;border-bottom:1px solid var(--border);white-space:nowrap}
tbody td{padding:11px 16px;font-size:13px;border-bottom:1px solid #F1F5F9;vertical-align:middle}
tbody tr:last-child td{border-bottom:none}tbody tr:hover td{background:#F7FBFF}
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:750}
.badge-pending{background:#FEF3C7;color:#92400E}.badge-approved{background:#ECFDF5;color:#065F46}.badge-rejected{background:#FEF2F2;color:#991B1B}
.badge-annual{background:#EFF6FF;color:#1558A8}.badge-sick{background:#FFF7ED;color:#92400E}.badge-unpaid{background:#F5F3FF;color:#6D28D9}.badge-sudden{background:#FEF2F2;color:#DC2626}
.form-row{display:flex;gap:12px;align-items:flex-end;flex-wrap:wrap;background:var(--white);border:1px solid var(--border);border-radius:var(--radius);padding:16px 20px;margin-bottom:18px}
.fi{display:flex;flex-direction:column;gap:5px}.fi label{font-size:11px;font-weight:750;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.fi input,.fi select,.fi textarea{border:1.5px solid var(--border);border-radius:8px;padding:7px 11px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;color:var(--ink);background:var(--surface);outline:none}
.fi input:focus,.fi select:focus{border-color:var(--blue);background:#fff}
.btn-sm{padding:7px 14px;border-radius:8px;font-family:'Plus Jakarta Sans',sans-serif;font-size:12.5px;font-weight:750;cursor:pointer;border:none;display:inline-flex;align-items:center;gap:5px;text-decoration:none;transition:all .18s}
.btn-approve{background:#ECFDF5;color:#065F46}.btn-approve:hover{background:#A7F3D0}
.btn-reject{background:#FEF2F2;color:#991B1B}.btn-reject:hover{background:#FECACA}
.btn-primary{background:var(--blue);color:#fff}.btn-primary:hover{background:#0D3F85}
.empty-box{padding:40px;text-align:center;color:var(--muted)}
.toast{position:fixed;top:20px;right:24px;padding:12px 20px;border-radius:11px;font-size:13px;font-weight:750;color:#fff;z-index:9999;display:flex;align-items:center;gap:8px;box-shadow:0 4px 20px rgba(0,0,0,.15);animation:slideIn .3s ease}
.toast-ok{background:#059669}.toast-err{background:#DC2626}.toast-info{background:#1558A8}
@keyframes slideIn{from{transform:translateX(60px);opacity:0}to{transform:translateX(0);opacity:1}}
select,option{font-family:inherit;font-size:inherit}
.cdd{position:relative;user-select:none;display:inline-block}
.cdd-btn{display:flex;align-items:center;gap:6px;padding:9px 14px;background:var(--white,#fff);border:1.5px solid var(--border,#D5E0F0);border-radius:10px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;font-weight:750;color:var(--ink,#0B1628);cursor:pointer;transition:all .18s;white-space:nowrap}
.cdd-btn:hover{border-color:var(--cyan,#3ABDE0);background:var(--cyan-soft,#EBF8FD)}
.cdd-btn.open{border-color:var(--cyan,#3ABDE0);box-shadow:0 0 0 3px rgba(58,189,224,.12)}
.cdd-arrow{font-size:9px;color:var(--muted,#7A90B0);transition:transform .2s}
.cdd-btn.open .cdd-arrow{transform:rotate(180deg)}
.cdd-menu{position:absolute;top:calc(100% + 6px);left:0;min-width:100%;background:var(--white,#fff);border:1.5px solid var(--border,#D5E0F0);border-radius:12px;padding:6px;box-shadow:0 12px 36px rgba(15,38,69,.15);z-index:200;opacity:0;transform:translateY(-6px);pointer-events:none;transition:all .18s ease;max-height:260px;overflow-y:auto}
.cdd-menu.show{opacity:1;transform:translateY(0);pointer-events:auto}
.cdd-menu::-webkit-scrollbar{width:4px}
.cdd-menu::-webkit-scrollbar-thumb{background:var(--border,#D5E0F0);border-radius:4px}
.cdd-opt{padding:8px 14px;border-radius:8px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;font-weight:600;color:var(--ink,#0B1628);cursor:pointer;transition:all .12s;white-space:nowrap}
.cdd-opt:hover{background:var(--surface,#F1F5FB);color:var(--blue,#1558A8)}
.cdd-opt.active{background:linear-gradient(135deg,var(--blue,#1558A8),#0D3F85);color:#fff;font-weight:750}
</style>    
<meta name="csrf-token" content="${csrfToken}">
<script src="${pageContext.request.contextPath}/js/csrf.js"></script>
</head><body><%@ include file="/WEB-INF/views/admin/sidebar.jsp" %><div class="main">  <c:if test="${not empty param.msg}">
    <c:choose>
      <c:when test="${param.msg=='approved'}"><div class="toast toast-ok" id="toast">✅ Đã duyệt đơn nghỉ!</div></c:when>
      <c:when test="${param.msg=='rejected'}"><div class="toast toast-info" id="toast">❌ Đã từ chối đơn.</div></c:when>
      <c:when test="${param.msg=='submitted'}"><div class="toast toast-ok" id="toast">✅ Đã gửi đơn xin nghỉ!</div></c:when>
      <c:when test="${param.msg=='generated'}"><div class="toast toast-ok" id="toast">✅ Đã tạo ${param.count} bảng lương!</div></c:when>
      <c:when test="${param.msg=='confirmed'}"><div class="toast toast-ok" id="toast">✅ Đã xác nhận bảng lương!</div></c:when>
      <c:when test="${param.msg=='paid'}"><div class="toast toast-ok" id="toast">💰 Đã đánh dấu đã trả lương!</div></c:when>
      <c:when test="${param.msg=='updated'}"><div class="toast toast-ok" id="toast">✅ Đã cập nhật!</div></c:when>
      <c:when test="${param.msg=='error'}"><div class="toast toast-err" id="toast">❌ Có lỗi xảy ra!</div></c:when>
      <c:when test="${param.msg=='exists'}"><div class="toast toast-err" id="toast">⚠️ Đã có đơn nghỉ ngày này!</div></c:when>
    </c:choose>
  </c:if>
  <header class="topbar"><div style="font-size:15px">📊</div><span class="topbar-title">Tổng hợp điểm danh tháng</span>
    <div class="topbar-right">
      <form method="get" action="${pageContext.request.contextPath}/attendance" style="display:flex;gap:8px;align-items:center">
        <input type="hidden" name="action" value="monthly">
        <input type="hidden" name="month" id="hMonth" value="${month}">
        <div class="cdd" id="cddMonth">
          <div class="cdd-btn" onclick="toggleCdd('cddMonth')" style="padding:6px 10px;height:auto">
            <span class="cdd-label">${month}</span>
            <span class="cdd-arrow">▼</span>
          </div>
          <div class="cdd-menu">
            <c:forEach begin="1" end="12" var="m"><div class="cdd-opt ${m==month?'active':''}" data-val="${m}" onclick="pickCdd('cddMonth','hMonth',this,false)">${m}</div></c:forEach>
          </div>
        </div>
        <input type="number" name="year" value="${year}" min="2020" max="2030" style="padding:6px 10px;border:1.5px solid var(--border);border-radius:8px;font-family:inherit;font-size:13px;width:80px">
        <button type="submit" style="padding:6px 14px;background:var(--blue);color:#fff;border:none;border-radius:8px;font-family:inherit;font-size:13px;font-weight:750;cursor:pointer">Xem</button>
      </form>
    </div>
  </header>
  <div class="content">
    <div class="table-card">
      <div class="table-card-head"><h2>📊 Tổng hợp tháng ${month}/${year}</h2><span class="tc-sub">${fn:length(summary)} nhân viên</span></div>
      <c:choose>
        <c:when test="${empty summary}"><div class="empty-box"><p>Không có dữ liệu.</p></div></c:when>
        <c:otherwise>
          <table>
            <thead><tr><th>Nhân viên</th><th>Ngày đi làm</th><th>Tổng giờ</th><th>Tổng trễ</th><th>Phạt (đã duyệt)</th><th>Bàn giao két</th><th>Chờ xử lý</th><th>Thao tác</th></tr></thead>
            <tbody>
              <c:forEach var="row" items="${summary}">
                <tr>
                  <td><strong>${row.staff.fullName}</strong><br><span style="font-size:11px;color:var(--muted)">${row.staff.roleId==2?'Dược sĩ':'Thủ kho'}</span></td>
                  <td style="font-weight:750;font-size:16px">${row.workedDays} <span style="font-size:11px;font-weight:400;color:var(--muted)">ngày</span></td>
                  <td style="font-weight:750">${row.totalHours}h</td>
                  <td><c:choose><c:when test="${row.totalLate>0}"><span style="color:var(--amber);font-weight:750">${row.totalLate}p</span></c:when><c:otherwise><span style="color:var(--green);font-weight:750">Đúng giờ</span></c:otherwise></c:choose></td>
                  <td style="font-weight:750;color:var(--red)">
                    <c:choose>
                      <c:when test="${row.totalPenalty > 0}"><fmt:formatNumber value="${row.totalPenalty}" type="number" maxFractionDigits="0"/>đ</c:when>
                      <c:otherwise><span style="color:var(--green)">0đ</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td style="font-weight:750;color:var(--ink)">
                    <c:choose>
                      <c:when test="${row.totalHandover > 0}"><fmt:formatNumber value="${row.totalHandover}" type="number" maxFractionDigits="0"/>đ</c:when>
                      <c:otherwise><span style="color:var(--muted)">—</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${row.pendingCount > 0}">
                        <a href="${pageContext.request.contextPath}/attendance?action=list&accountId=${row.staff.accountId}&status=SYSTEM_CLOSED"
                           style="display:inline-flex;align-items:center;gap:4px;padding:3px 8px;border-radius:10px;background:#FEF3C7;color:#92400E;font-size:11.5px;font-weight:750;text-decoration:none">
                          ⚠️ ${row.pendingCount} chờ
                        </a>
                      </c:when>
                      <c:otherwise><span style="color:var(--green);font-size:12px">✅</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <a href="${pageContext.request.contextPath}/attendance?action=list&accountId=${row.staff.accountId}" class="btn-sm btn-primary">📋 Xem</a>
                    <a href="${pageContext.request.contextPath}/payroll?action=generate&month=${month}&year=${year}&accountId=${row.staff.accountId}" style="margin-left:6px" class="btn-sm" style="background:#EFF6FF;color:var(--blue)">💰 Tính lương</a>
                  </td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </c:otherwise>
      </c:choose>
    </div>
  </div>
</div><script>
function toggleCdd(id){var w=document.getElementById(id),m=w.querySelector('.cdd-menu'),b=w.querySelector('.cdd-btn');var open=m.classList.contains('show');document.querySelectorAll('.cdd-menu.show').forEach(function(x){x.classList.remove('show');x.closest('.cdd').querySelector('.cdd-btn').classList.remove('open')});if(!open){m.classList.add('show');b.classList.add('open');var act=m.querySelector('.cdd-opt.active');if(act)act.scrollIntoView({block:'nearest'})}}
function pickCdd(wId,hId,el,autoSubmit){document.getElementById(hId).value=el.dataset.val;var w=document.getElementById(wId);w.querySelector('.cdd-label').textContent=el.textContent;w.querySelectorAll('.cdd-opt').forEach(function(o){o.classList.remove('active')});el.classList.add('active');w.querySelector('.cdd-menu').classList.remove('show');w.querySelector('.cdd-btn').classList.remove('open');if(autoSubmit){var f=w.closest('form');if(f)f.submit()}}
document.addEventListener('click',function(e){if(!e.target.closest('.cdd')){document.querySelectorAll('.cdd-menu.show').forEach(function(m){m.classList.remove('show');m.closest('.cdd').querySelector('.cdd-btn').classList.remove('open')})}});

const t=document.getElementById('toast');
if(t) setTimeout(()=>{t.style.opacity='0';setTimeout(()=>t.remove(),400)},3500);
</script></body></html>