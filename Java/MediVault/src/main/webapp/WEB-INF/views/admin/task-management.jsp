<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<% String activeNav = "task-management"; %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length()>=2 ? fullName.substring(0,1).toUpperCase()+fullName.substring(1,2).toUpperCase() : fullName.toUpperCase();
%>
<!DOCTYPE html><html lang="vi"><head>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Giao task &amp; Tiến độ kho — MediCare</title>

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
.topbar-title{font-size:16px;font-weight:750;color:var(--ink)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.content{padding:22px 26px;flex:1;max-width:1280px}

.toast{position:fixed;top:20px;right:24px;padding:12px 20px;border-radius:11px;font-size:13px;font-weight:750;color:#fff;z-index:9999;display:flex;align-items:center;gap:8px;box-shadow:0 4px 20px rgba(0,0,0,.15);animation:slideIn .3s ease}
.toast-ok{background:#059669}.toast-err{background:#DC2626}
@keyframes slideIn{from{transform:translateX(60px);opacity:0}to{transform:translateX(0);opacity:1}}

/* Watchdog banner — y hệt .alert-card của dashboard.jsp */
.alert-card{background:#FFFBEB;border:1px solid #FDE68A;border-radius:14px;padding:14px 20px;margin-bottom:18px}
.alert-card-top{display:flex;align-items:center;gap:14px}
.alert-icon{font-size:20px}
.alert-text strong{color:#92400E;font-size:13.5px;display:block}
.alert-text p{font-size:12.5px;color:#78350F;margin-top:2px}
.alert-list{margin-top:12px;padding-top:12px;border-top:1px solid #FDE68A;display:flex;flex-direction:column;gap:6px}
.alert-item{display:flex;align-items:center;justify-content:space-between;gap:10px;font-size:12.5px;color:#78350F}
.alert-item b{color:#92400E}

.table-card{background:#fff;border:1px solid rgba(213,224,240,.45);border-radius:var(--radius);overflow:hidden;margin-bottom:18px;box-shadow:0 1px 3px rgba(15,38,69,.03),0 4px 12px rgba(15,38,69,.04)}
.table-card-head{padding:14px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;gap:10px;flex-wrap:wrap}
.table-card-head h2{font-size:14px;font-weight:800;color:var(--ink);display:flex;align-items:center;gap:8px}
.tc-sub{font-size:12px;color:var(--muted)}
.table-card-body{padding:20px}
table{width:100%;border-collapse:collapse}
thead th{padding:9px 16px;background:#F8FAFC;font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;border-bottom:1px solid var(--border);white-space:nowrap}
tbody td{padding:11px 16px;font-size:13px;border-bottom:1px solid #F1F5F9;vertical-align:middle}
tbody tr:last-child td{border-bottom:none}tbody tr:hover td{background:#F7FBFF}
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:750;white-space:nowrap}
.badge-pending{background:#FEF3C7;color:#92400E}.badge-progress{background:#EFF6FF;color:#1558A8}
.badge-ontime{background:#ECFDF5;color:#065F46}.badge-late{background:#FFF7ED;color:#92400E}
.badge-cancelled{background:#F1F5F9;color:#64748B}
.badge-high{background:#FEF2F2;color:#991B1B}.badge-medium{background:#FFF7ED;color:#92400E}.badge-low{background:#EFF6FF;color:#1558A8}
.badge-warn{background:#FEF3C7;color:#92400E}.badge-danger{background:#FEF2F2;color:#991B1B}.badge-ok{background:#ECFDF5;color:#065F46}
.empty-box{padding:36px;text-align:center;color:var(--muted);font-size:13px}

/* Form tạo Task/Dự án */
.type-toggle{display:flex;gap:8px;margin-bottom:16px}
.tt-btn{padding:8px 16px;border:1.5px solid var(--border);border-radius:9px;background:#fff;font-family:inherit;font-size:13px;font-weight:750;color:var(--muted);cursor:pointer}
.tt-btn.active{border-color:var(--blue);background:#EFF6FF;color:var(--blue)}
.form-row{display:flex;gap:12px;align-items:flex-end;flex-wrap:wrap}
.fi{display:flex;flex-direction:column;gap:5px}
.fi.grow{flex:1;min-width:260px}
.fi label{font-size:11px;font-weight:750;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.req{color:var(--red)}
.fi input,.fi select,.fi textarea{border:1.5px solid var(--border);border-radius:8px;padding:9px 12px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;color:var(--ink);background:var(--surface);outline:none;width:100%}
.fi textarea{min-height:60px;resize:vertical}
.fi input:focus,.fi select:focus,.fi textarea:focus{border-color:var(--blue);background:#fff;box-shadow:0 0 0 3px rgba(21,88,168,.1)}
.btn-primary{padding:10px 20px;border-radius:9px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;font-family:inherit;font-size:13.5px;font-weight:750;cursor:pointer}
.btn-primary:hover{filter:brightness(1.06)}
.btn-sm{padding:7px 14px;border-radius:8px;font-family:'Plus Jakarta Sans',sans-serif;font-size:12.5px;font-weight:750;cursor:pointer;border:none;display:inline-flex;align-items:center;gap:5px;text-decoration:none;transition:all .18s}
.btn-ghost{background:none;border:1.5px solid var(--border);color:var(--ink)}
.btn-ghost:hover{background:var(--surface)}
.milestone-rows{display:flex;flex-direction:column;gap:8px;margin:10px 0}
.milestone-input-row{display:flex;gap:8px;align-items:center}
.milestone-input-row input[type=text]{flex:1}
.milestone-input-row input[type=datetime-local]{width:190px}
.ms-remove{background:none;border:none;color:var(--red);cursor:pointer;font-size:16px;flex:none}
.add-milestone{margin-top:4px;padding:7px 12px;border:1.5px dashed var(--border);border-radius:8px;background:none;color:var(--blue);font-family:inherit;font-size:12.5px;font-weight:700;cursor:pointer}

/* Kanban */
.kanban{display:grid;grid-template-columns:repeat(3,1fr);gap:16px}
@media(max-width:1000px){.kanban{grid-template-columns:1fr}}
.kb-col{background:#F8FAFC;border:1px solid var(--border);border-radius:12px;padding:12px;min-height:120px}
.kb-col-head{font-size:11.5px;font-weight:800;text-transform:uppercase;letter-spacing:.5px;color:var(--muted);margin-bottom:10px;display:flex;align-items:center;justify-content:space-between}
.kb-card{background:#fff;border:1px solid var(--border);border-radius:10px;padding:11px 13px;margin-bottom:8px;box-shadow:0 1px 2px rgba(15,38,69,.04)}
.kb-card:last-child{margin-bottom:0}
.kb-title{font-size:13px;font-weight:750;color:var(--ink);margin-bottom:5px}
.kb-meta{font-size:11px;color:var(--muted);display:flex;flex-wrap:wrap;gap:6px;align-items:center}
.kb-progress{height:6px;border-radius:20px;background:var(--border);overflow:hidden;margin-top:8px}
.kb-progress-fill{height:100%;background:linear-gradient(90deg,var(--blue),var(--cyan));border-radius:20px}
.kb-empty{font-size:12px;color:var(--muted);font-style:italic;padding:8px 0}
</style>
</head><body><%@ include file="/WEB-INF/views/admin/sidebar.jsp" %><div class="main">

  <c:if test="${not empty param.msg}">
    <div class="toast ${param.ok == 'true' ? 'toast-ok' : 'toast-err'}" id="toast">
      ${param.ok == 'true' ? '✅' : '⛔'} <c:out value="${param.msg}"/>
    </div>
  </c:if>

  <header class="topbar"><div style="font-size:15px">🎯</div><span class="topbar-title">Giao task &amp; Tiến độ kho</span>
    <div class="topbar-right">
      <div class="sidebar-user" style="background:var(--surface);border-color:var(--border)">
        <div class="user-av" style="color:var(--ink);background:linear-gradient(135deg,var(--cyan),var(--blue))"><%= initials %></div>
        <div><div class="user-name" style="color:var(--ink)"><%= fullName %></div></div>
      </div>
    </div>
  </header>

  <div class="content">

    <!-- ══ Watchdog Widget — mục III.2.B tài liệu ══ -->
    <c:if test="${not empty watchdog}">
      <div class="alert-card">
        <div class="alert-card-top">
          <div class="alert-icon">🚨</div>
          <div class="alert-text">
            <strong>${watchdog.size()} task/dự án sắp hoặc đã quá hạn báo xong</strong>
            <p>Trong 48 giờ tới hoặc đã quá hạn — cần can thiệp/nhắc Thủ kho ngay.</p>
          </div>
        </div>
        <div class="alert-list">
          <c:forEach var="w" items="${watchdog}" end="4">
            <div class="alert-item">
              <span><b>${fn:escapeXml(w.title)}</b> — ${not empty w.assignedToName ? w.assignedToName : 'Chưa giao'}</span>
              <span class="badge ${w.zoneCssClass}">${w.zoneLabel}</span>
            </div>
          </c:forEach>
        </div>
      </div>
    </c:if>

    <!-- ══ Form tạo Task / Dự án — mục III.2.A tài liệu ══ -->
    <div class="table-card">
      <div class="table-card-head"><h2>➕ Giao công việc mới</h2></div>
      <div class="table-card-body">
        <div class="type-toggle">
          <button type="button" class="tt-btn active" id="tabTask" onclick="switchType('task')">⚡ Task ngắn hạn (SOP)</button>
          <button type="button" class="tt-btn" id="tabProject" onclick="switchType('project')">🚀 Dự án dài hạn</button>
        </div>

        <!-- Task ngắn hạn -->
        <form method="post" action="${pageContext.request.contextPath}/task-management" id="formTask">
          <input type="hidden" name="action" value="create-task">
          <div class="form-row" style="margin-bottom:12px">
            <div class="fi grow"><label>Tiêu đề <span class="req">*</span></label>
              <input type="text" name="title" maxlength="255" placeholder="VD: Kiểm tra nhiệt độ tủ lạnh vắc-xin" required></div>
            <div class="fi"><label>Ưu tiên</label>
              <select name="priority"><option value="HIGH">🔴 Cao</option><option value="MEDIUM" selected>🟡 Trung bình</option><option value="LOW">🔵 Thấp</option></select></div>
          </div>
          <div class="form-row" style="margin-bottom:12px">
            <div class="fi grow"><label>Mô tả <span class="req">*</span></label><textarea name="description" maxlength="1000" placeholder="Ghi rõ yêu cầu…" required></textarea></div>
          </div>
          <div class="form-row">
            <div class="fi"><label>Giao cho</label>
              <select name="assignedTo">
                <option value="">— Để chung —</option>
                <c:forEach var="a" items="${warehouseStaff}"><option value="${a.accountId}">${fn:escapeXml(a.fullName)}</option></c:forEach>
              </select></div>
            <div class="fi"><label>Hạn báo xong trước <span class="req">*</span></label>
              <input type="datetime-local" name="dueDate" class="due-input" required></div>
            <button type="submit" class="btn-primary">Giao task</button>
          </div>
        </form>

        <!-- Dự án dài hạn -->
        <form method="post" action="${pageContext.request.contextPath}/task-management" id="formProject" style="display:none">
          <input type="hidden" name="action" value="create-project">
          <div class="form-row" style="margin-bottom:12px">
            <div class="fi grow"><label>Tên Dự án <span class="req">*</span></label>
              <input type="text" name="title" maxlength="255" placeholder="VD: Xử lý 50 Lô cận hạn Q3/2026" required></div>
            <div class="fi"><label>Ưu tiên</label>
              <select name="priority"><option value="HIGH">🔴 Cao</option><option value="MEDIUM" selected>🟡 Trung bình</option><option value="LOW">🔵 Thấp</option></select></div>
          </div>
          <div class="form-row" style="margin-bottom:12px">
            <div class="fi grow"><label>Mô tả <span class="req">*</span></label><textarea name="description" maxlength="1000" placeholder="Bối cảnh, mục tiêu chiến dịch…" required></textarea></div>
          </div>
          <div class="form-row" style="margin-bottom:12px">
            <div class="fi"><label>Giao cho <span class="req">*</span></label>
              <select name="assignedTo" required>
                <option value="">— Chọn Thủ kho —</option>
                <c:forEach var="a" items="${warehouseStaff}"><option value="${a.accountId}">${fn:escapeXml(a.fullName)}</option></c:forEach>
              </select></div>
            <div class="fi"><label>Hạn báo cáo tổng <span class="req">*</span></label>
              <input type="datetime-local" name="dueDate" class="due-input" required></div>
          </div>
          <label style="font-size:11px;font-weight:750;color:var(--muted);text-transform:uppercase;letter-spacing:.5px">Các mốc (milestones)</label>
          <div class="milestone-rows" id="milestoneRows"></div>
          <button type="button" class="add-milestone" onclick="addMilestoneRow()">+ Thêm mốc</button>
          <div style="margin-top:14px"><button type="submit" class="btn-primary">Tạo Dự án</button></div>
        </form>
      </div>
    </div>

    <!-- ══ Kanban — mục III.2.C tài liệu ══ -->
    <div class="table-card">
      <div class="table-card-head"><h2>📋 Bảng tiến độ (Kanban)</h2></div>
      <div class="table-card-body">
        <div class="kanban">

          <div class="kb-col">
            <div class="kb-col-head">📥 To-do</div>
            <c:set var="countTodo" value="0"/>
            <c:forEach var="k" items="${kanban}">
              <c:if test="${k.status == 'PENDING'}">
                <c:set var="countTodo" value="${countTodo + 1}"/>
                <div class="kb-card">
                  <div class="kb-title">${fn:escapeXml(k.title)} <c:if test="${k.isProject}">🚀</c:if></div>
                  <div class="kb-meta">
                    <span class="badge badge-${fn:toLowerCase(k.priority)}">${k.priorityLabel}</span>
                    <c:if test="${not empty k.assignedToName}"><span>${fn:escapeXml(k.assignedToName)}</span></c:if>
                    <c:if test="${not empty k.zoneLabel}"><span class="badge ${k.zoneCssClass}">${k.zoneLabel}</span></c:if>
                  </div>
                  <c:if test="${k.isProject}"><div class="kb-progress"><div class="kb-progress-fill" style="width:${k.progressPercentage}%"></div></div></c:if>
                </div>
              </c:if>
            </c:forEach>
            <c:if test="${countTodo == 0}"><div class="kb-empty">Không có việc nào.</div></c:if>
          </div>

          <div class="kb-col">
            <div class="kb-col-head">🔧 In Progress</div>
            <c:set var="countProg" value="0"/>
            <c:forEach var="k" items="${kanban}">
              <c:if test="${k.status == 'IN_PROGRESS'}">
                <c:set var="countProg" value="${countProg + 1}"/>
                <div class="kb-card">
                  <div class="kb-title">${fn:escapeXml(k.title)} <c:if test="${k.isProject}">🚀</c:if></div>
                  <div class="kb-meta">
                    <span class="badge badge-${fn:toLowerCase(k.priority)}">${k.priorityLabel}</span>
                    <c:if test="${not empty k.assignedToName}"><span>${fn:escapeXml(k.assignedToName)}</span></c:if>
                    <c:if test="${not empty k.zoneLabel}"><span class="badge ${k.zoneCssClass}">${k.zoneLabel}</span></c:if>
                  </div>
                  <c:if test="${k.isProject}"><div class="kb-progress"><div class="kb-progress-fill" style="width:${k.progressPercentage}%"></div></div></c:if>
                </div>
              </c:if>
            </c:forEach>
            <c:if test="${countProg == 0}"><div class="kb-empty">Không có việc nào.</div></c:if>
          </div>

          <div class="kb-col">
            <div class="kb-col-head">✅ Done</div>
            <c:set var="countDone" value="0"/>
            <c:forEach var="k" items="${kanban}">
              <c:if test="${k.status == 'COMPLETED_ON_TIME' || k.status == 'COMPLETED_LATE'}">
                <c:set var="countDone" value="${countDone + 1}"/>
                <div class="kb-card">
                  <div class="kb-title">${fn:escapeXml(k.title)} <c:if test="${k.isProject}">🚀</c:if></div>
                  <div class="kb-meta">
                    <span class="badge badge-${fn:toLowerCase(k.priority)}">${k.priorityLabel}</span>
                    <c:if test="${not empty k.assignedToName}"><span>${fn:escapeXml(k.assignedToName)}</span></c:if>
                    <span class="badge ${k.status == 'COMPLETED_ON_TIME' ? 'badge-ontime' : 'badge-late'}">${k.status == 'COMPLETED_ON_TIME' ? 'Đúng hạn' : 'Trễ hạn'}</span>
                  </div>
                  <c:if test="${k.isProject}"><div class="kb-progress"><div class="kb-progress-fill" style="width:${k.progressPercentage}%"></div></div></c:if>
                </div>
              </c:if>
            </c:forEach>
            <c:if test="${countDone == 0}"><div class="kb-empty">Không có việc nào.</div></c:if>
          </div>

        </div>
      </div>
    </div>

    <!-- ══ KPI Audit Table — mục III.2.D tài liệu ══ -->
    <div class="table-card">
      <div class="table-card-head"><h2>📊 Nhật ký Liêm chính Thời gian (KPI Audit)</h2></div>
      <table>
        <thead><tr><th>Task</th><th>Thủ kho</th><th>Hạn báo xong</th><th>Đã báo xong lúc</th><th>Kết quả</th></tr></thead>
        <tbody>
        <c:choose>
          <c:when test="${empty kpiAudit}"><tr><td colspan="5" class="empty-box">Chưa có task nào hoàn thành.</td></tr></c:when>
          <c:otherwise>
            <c:forEach var="k" items="${kpiAudit}">
              <tr>
                <td>${fn:escapeXml(k.title)} <c:if test="${k.isProject}">🚀</c:if></td>
                <td>${not empty k.assignedToName ? k.assignedToName : '—'}</td>
                <td>${not empty k.dueDate ? k.dueDateDisplay : 'Không hạn'}</td>
                <td>${k.completedAtDisplay}</td>
                <td>
                  <c:choose>
                    <c:when test="${k.status == 'COMPLETED_ON_TIME'}"><span class="badge badge-ontime">✅ PASS</span></c:when>
                    <c:otherwise><span class="badge badge-late">⏰ LATE</span></c:otherwise>
                  </c:choose>
                </td>
              </tr>
            </c:forEach>
          </c:otherwise>
        </c:choose>
        </tbody>
      </table>
    </div>

  </div>
</div>

<script>
function switchType(type){
  document.getElementById('formTask').style.display = type === 'task' ? 'block' : 'none';
  document.getElementById('formProject').style.display = type === 'project' ? 'block' : 'none';
  document.getElementById('tabTask').classList.toggle('active', type === 'task');
  document.getElementById('tabProject').classList.toggle('active', type === 'project');
}
// Chặn chọn ngày/giờ quá khứ ngay từ UI (guard phía client — server vẫn tự kiểm tra
// lại bằng LocalDateTime.now(), không tin riêng client). Định dạng min cần đúng
// "YYYY-MM-DDTHH:MM" mà input datetime-local yêu cầu.
function nowLocalIso(){
  var d = new Date(), pad = function(n){ return String(n).padStart(2,'0'); };
  return d.getFullYear() + '-' + pad(d.getMonth()+1) + '-' + pad(d.getDate())
       + 'T' + pad(d.getHours()) + ':' + pad(d.getMinutes());
}
function applyMinToDateInputs(scope){
  var min = nowLocalIso();
  (scope || document).querySelectorAll('input[type=datetime-local]').forEach(function(el){ el.min = min; });
}

function addMilestoneRow(){
  var wrap = document.getElementById('milestoneRows');
  var row = document.createElement('div');
  row.className = 'milestone-input-row';
  row.innerHTML = '<input type="text" name="milestoneTitle" placeholder="VD: Xử lý xong Lô B-102" maxlength="255">' +
    '<input type="datetime-local" name="milestoneDueDate">' +
    '<button type="button" class="ms-remove" onclick="this.parentElement.remove()">✕</button>';
  wrap.appendChild(row);
  applyMinToDateInputs(row);
}
addMilestoneRow(); // luôn có sẵn 1 dòng mốc trống khi mở form Dự án
applyMinToDateInputs(document);
setTimeout(function(){ var t=document.getElementById('toast'); if(t) t.style.display='none'; }, 3500);
</script>
</body></html>
