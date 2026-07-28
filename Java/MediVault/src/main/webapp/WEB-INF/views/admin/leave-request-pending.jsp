<%@ page contentType="text/html;charset=UTF-8" language="java"  pageEncoding="UTF-8" %>
<% String activeNav = "leave"; %>
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
<title>Đơn nghỉ chờ duyệt — medicare</title>

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
  <header class="topbar"><div style="font-size:15px">🏖️</div><span class="topbar-title">Đơn xin nghỉ</span>
    <div class="topbar-right">
      <c:if test="${pendingCount>0}"><span style="background:#FEF3C7;color:#92400E;padding:4px 12px;border-radius:20px;font-size:12.5px;font-weight:750">${pendingCount} chờ duyệt</span></c:if>
      <a href="${pageContext.request.contextPath}/leave-requests?action=list" style="padding:7px 16px;border:1.5px solid var(--border);border-radius:8px;font-family:inherit;font-size:13px;font-weight:750;color:var(--muted);text-decoration:none">Xem tháng →</a>
    </div>
  </header>
  <div style="display:flex;gap:4px;padding:0 26px;background:var(--white);border-bottom:1px solid var(--border)">
    <a href="${pageContext.request.contextPath}/leave-requests?action=pending" style="padding:12px 18px;font-size:13px;font-weight:750;color:var(--blue);text-decoration:none;border-bottom:2.5px solid var(--blue)">⏳ Chờ duyệt (${pendingCount})</a>
    <a href="${pageContext.request.contextPath}/leave-requests?action=list"    style="padding:12px 18px;font-size:13px;font-weight:750;color:var(--muted);text-decoration:none;border-bottom:2.5px solid transparent">📋 Tất cả</a>
  </div>
  <div class="content">
    <div class="table-card">
      <div class="table-card-head"><h2>⏳ Đơn chờ duyệt</h2><span class="tc-sub">${pendingCount} đơn</span></div>
      <c:choose>
        <c:when test="${empty pending}"><div class="empty-box"><div style="font-size:40px;margin-bottom:10px">✅</div><p>Không có đơn nào đang chờ duyệt.</p></div></c:when>
        <c:otherwise>
          <table>
            <thead><tr><th>Nhân viên</th><th>Ngày nghỉ</th><th>Loại</th><th>Lý do</th><th>Gửi lúc</th><th>Thao tác</th></tr></thead>
            <tbody>
              <c:forEach var="lr" items="${pending}">
                <tr <c:if test="${lr.leaveType=='SUDDEN'}">style="background:#fff7ed"</c:if>>
                  <td><strong>${lr.staffName}</strong></td>
                  <td style="font-weight:750">${lr.leaveDate}</td>
                  <td>
                    <span class="badge
                      <c:choose><c:when test="${lr.leaveType=='ANNUAL'}">badge-annual</c:when>
                      <c:when test="${lr.leaveType=='SICK'}">badge-sick</c:when>
                      <c:when test="${lr.leaveType=='UNPAID'}">badge-unpaid</c:when>
                      <c:otherwise>badge-sudden</c:otherwise></c:choose>">
                      <c:if test="${lr.leaveType=='SUDDEN'}">🚨 </c:if>${lr.leaveType=='ANNUAL'?'Phép năm':lr.leaveType=='SICK'?'Ốm':lr.leaveType=='UNPAID'?'Không lương':'Đột xuất'}
                    </span>
                  </td>
                  <td style="max-width:220px;font-size:12px;color:var(--muted)">
                    ${lr.reason}
                    <c:if test="${not empty lr.evidencePath}">
                      <br><a href="${pageContext.request.contextPath}/${lr.evidencePath}" target="_blank"
                             style="color:var(--blue);font-weight:750;font-size:11.5px">📎 Xem ảnh minh chứng</a>
                    </c:if>
                  </td>
                  <td style="font-size:12px;color:var(--muted)">${fn:substring(lr.requestedAt.toString(),0,16)}</td>
                  <td style="white-space:nowrap">
                    <c:choose>
                      <c:when test="${lr.leaveType=='SUDDEN'}">
                        <button type="button" class="btn-sm btn-primary"
                                onclick="openSubstitute(${lr.leaveId}, '${fn:escapeXml(lr.staffName)}', '${lr.leaveDate}')">
                          🔀 Duyệt &amp; tìm người thay
                        </button>
                      </c:when>
                      <c:otherwise>
                        <form method="post" action="${pageContext.request.contextPath}/leave-requests" style="display:inline">
                          <input type="hidden" name="_csrf" value="${csrfToken}">
                          <input type="hidden" name="action" value="approve">
                          <input type="hidden" name="id" value="${lr.leaveId}">
                          <input type="hidden" name="deductAmount" value="0">
                          <button type="submit" class="btn-sm btn-approve">✅ Duyệt</button>
                        </form>
                      </c:otherwise>
                    </c:choose>
                    <form method="post" action="${pageContext.request.contextPath}/leave-requests" style="display:inline;margin-left:4px">
                      <input type="hidden" name="_csrf" value="${csrfToken}">
                      <input type="hidden" name="action" value="reject">
                      <input type="hidden" name="id" value="${lr.leaveId}">
                      <button type="submit" class="btn-sm btn-reject" onclick="return confirm('Từ chối đơn này? Nếu nhân viên vẫn không đi làm sẽ bị tính vắng không phép.')">✕ Từ chối</button>
                    </form>
                  </td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </c:otherwise>
      </c:choose>
    </div>
  </div>
</div>

<!-- Modal: Điều phối người thay -->
<div id="subOverlay" style="display:none;position:fixed;inset:0;background:rgba(11,22,40,.55);z-index:9700;align-items:center;justify-content:center;padding:20px">
  <div style="background:#fff;border-radius:16px;max-width:520px;width:100%;max-height:92vh;overflow:auto;box-shadow:0 24px 70px rgba(0,0,0,.3)">
    <div style="background:linear-gradient(135deg,#1558A8,#3ABDE0);color:#fff;padding:18px 24px;border-radius:16px 16px 0 0">
      <h3 style="margin:0;font-size:18px;font-weight:800">🔀 Duyệt nghỉ đột xuất &amp; điều phối</h3>
      <p id="subSubtitle" style="margin:4px 0 0;font-size:12.5px;opacity:.9"></p>
    </div>
    <div style="padding:20px 24px">
      <div style="font-size:13px;font-weight:750;margin-bottom:8px">Chọn người làm thay (nhân viên đang nghỉ hôm đó)</div>
      <div id="subList" style="display:flex;flex-direction:column;gap:8px;max-height:280px;overflow:auto">
        <div style="color:#7A90B0;font-size:13px">Đang tải danh sách…</div>
      </div>
      <label style="font-size:13px;font-weight:750;display:block;margin:16px 0 6px">Ghi chú (tùy chọn)</label>
      <textarea id="subNote" rows="2" placeholder="VD: đã gọi điện xác nhận với người thay…"
                style="width:100%;border:1.5px solid var(--border);border-radius:10px;padding:10px 12px;font-family:inherit;font-size:14px;box-sizing:border-box;resize:vertical"></textarea>
      <div style="display:flex;gap:10px;margin-top:18px">
        <button type="button" onclick="closeSubstitute()"
                style="flex:1;background:#f1f5f9;color:#475569;border:none;border-radius:10px;padding:11px;font-weight:750;cursor:pointer;font-family:inherit">Hủy</button>
        <button type="button" id="subApproveBtn" onclick="submitSubstitute()"
                style="flex:2;background:linear-gradient(135deg,#059669,#047857);color:#fff;border:none;border-radius:10px;padding:11px;font-weight:800;cursor:pointer;font-family:inherit">✅ Xác nhận duyệt</button>
      </div>
      <div style="font-size:11.5px;color:#94a3b8;margin-top:10px">Có thể duyệt mà không chọn người thay — khi đó ca sẽ trống, bạn tự sắp xếp sau.</div>
    </div>
  </div>
</div>

<script>
const t=document.getElementById('toast');
if(t) setTimeout(()=>{t.style.opacity='0';setTimeout(()=>t.remove(),400)},3500);

const SUB_CTX = '${pageContext.request.contextPath}';
let _subLeaveId = 0, _subSelected = 0;

function openSubstitute(leaveId, staffName, date){
  _subLeaveId = leaveId; _subSelected = 0;
  document.getElementById('subSubtitle').textContent = staffName + ' · nghỉ ngày ' + date;
  document.getElementById('subNote').value = '';
  document.getElementById('subApproveBtn').textContent = '✅ Xác nhận duyệt';
  const list = document.getElementById('subList');
  list.innerHTML = '<div style="color:#7A90B0;font-size:13px">Đang tải danh sách…</div>';
  document.getElementById('subOverlay').style.display = 'flex';

  fetch(SUB_CTX + '/leave-requests?action=substitutes&id=' + leaveId)
    .then(r => r.json())
    .then(data => {
      if (!data.ok){ list.innerHTML = '<div style="color:#DC2626;font-size:13px">Lỗi tải danh sách.</div>'; return; }
      if (!data.substitutes.length){
        list.innerHTML = '<div style="background:#fff7ed;border:1px solid #fed7aa;border-radius:10px;padding:12px;font-size:13px;color:#9a3412">Không có nhân viên nào rảnh hôm đó. Bạn vẫn có thể duyệt (ca để trống).</div>';
        return;
      }
      list.innerHTML = '';
      data.substitutes.forEach(s => {
        const div = document.createElement('div');
        div.style.cssText = 'border:1.5px solid var(--border);border-radius:10px;padding:11px 14px;cursor:pointer;display:flex;justify-content:space-between;align-items:center;transition:.15s';
        div.dataset.id = s.accountId;
        div.innerHTML = '<div><div style="font-weight:750;color:#0B1628">' + s.name +
          '</div><div style="font-size:12px;color:#7A90B0">' + s.role +
          (s.phone ? ' · ' + s.phone : '') + '</div></div>' +
          '<div class="sub-check" style="font-size:18px;color:#059669;visibility:hidden">✓</div>';
        div.onclick = () => {
          document.querySelectorAll('#subList > div').forEach(d => {
            d.style.borderColor = 'var(--border)'; d.style.background = '#fff';
            const c = d.querySelector('.sub-check'); if (c) c.style.visibility = 'hidden';
          });
          div.style.borderColor = '#059669'; div.style.background = '#ECFDF5';
          const c = div.querySelector('.sub-check'); if (c) c.style.visibility = 'visible';
          _subSelected = s.accountId;
          document.getElementById('subApproveBtn').textContent = '✅ Duyệt & gán ' + s.name;
        };
        list.appendChild(div);
      });
    })
    .catch(() => { list.innerHTML = '<div style="color:#DC2626;font-size:13px">Lỗi kết nối.</div>'; });
}

function closeSubstitute(){ document.getElementById('subOverlay').style.display = 'none'; }
document.getElementById('subOverlay').addEventListener('click', e => {
  if (e.target.id === 'subOverlay') closeSubstitute();
});

function submitSubstitute(){
  const btn = document.getElementById('subApproveBtn');
  btn.disabled = true; btn.textContent = '⏳ Đang xử lý…';
  const f = document.createElement('form');
  f.method = 'POST'; f.action = SUB_CTX + '/leave-requests';
  const fields = { action:'approve-sudden', id:_subLeaveId, substituteId:_subSelected, notes:document.getElementById('subNote').value };
  Object.keys(fields).forEach(k => {
    const i = document.createElement('input'); i.type='hidden'; i.name=k; i.value=fields[k]; f.appendChild(i);
  });
  document.body.appendChild(f); f.submit();
}
</script></body></html>