<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) request.getAttribute("staffAcc");
    String ctx = request.getContextPath();
    if (acc == null) { response.sendRedirect(ctx + "/warehouse-login"); return; }
    String fullName = acc.getFullName() != null && !acc.getFullName().isEmpty() ? acc.getFullName() : acc.getUsername();
    String initials = fullName.substring(0,1).toUpperCase();
    String uid = (String) request.getAttribute("staffUid");
    String activeNav = "task";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Nhiệm vụ &amp; SOP — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400..800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= ctx %>/css/staff-portal.css">
<link rel="stylesheet" href="<%= ctx %>/css/warehouse-portal.css?v=5">
<style>
a{text-decoration:none;color:inherit}

.wrap{max-width:1200px;margin:0 auto;padding:28px 28px 60px}
.head{display:flex;align-items:flex-end;justify-content:space-between;flex-wrap:wrap;gap:14px;margin-bottom:22px}
.head h1{font-size:24px;font-weight:800;letter-spacing:-.5px}
.head h1 span{color:var(--main)}
.head p{color:var(--muted);font-size:14px;margin-top:4px}

.banner{border-radius:14px;padding:14px 18px;margin-bottom:20px;font-weight:700;font-size:14px;
  display:flex;align-items:center;gap:10px}
.banner.ok{background:var(--okbg);color:var(--ok);border:1px solid #A7F3D0}
.banner.err{background:var(--dangerbg);color:var(--danger);border:1.5px solid #FCA5B1}

.card{background:#fff;border:1px solid #E4E9E7;border-radius:16px;overflow:hidden;margin-bottom:22px;box-shadow:0 1px 2px rgba(4,47,46,.04),0 12px 30px -18px rgba(4,47,46,.12)}
.card-head{display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;
  padding:16px 20px;border-bottom:1px solid var(--line)}
.card-head h2{font-size:15px;font-weight:800;display:flex;align-items:center;gap:8px}
.card-head h2 small{color:var(--muted);font-weight:600;font-size:12.5px;margin-left:6px}
.card-body{padding:20px}

/* ── Nhiệm vụ hôm nay: danh sách thẻ (không phải bảng) để dễ quét mắt ── */
.task-list{display:flex;flex-direction:column;gap:10px}
.task-row{display:flex;align-items:center;gap:12px;padding:13px 16px;border:1px solid var(--line);
  border-radius:12px;background:var(--surface);flex-wrap:wrap}
.task-row .pr-dot{width:9px;height:9px;border-radius:50%;flex:none}
.pr-dot.HIGH{background:var(--danger)}
.pr-dot.MEDIUM{background:var(--gold)}
.pr-dot.LOW{background:var(--jade)}
.task-row .tinfo{flex:1;min-width:220px}
.task-row .ttitle{font-weight:750;font-size:14px;color:var(--ink)}
.task-row .tdesc{font-size:12.5px;color:var(--muted);margin-top:2px}
.task-row .tmeta{font-size:11.5px;color:var(--muted);margin-top:4px;display:flex;gap:10px;flex-wrap:wrap}
.task-row .tactions{display:flex;gap:8px;flex:none}

.badge{display:inline-block;padding:2px 9px;border-radius:20px;font-size:11.5px;font-weight:700;white-space:nowrap}
.badge.info{background:#DBEAFE;color:#1D4ED8}
.badge.warn{background:var(--goldbg);color:var(--gold)}
.badge.danger{background:var(--dangerbg);color:var(--danger)}
.badge.ok{background:var(--okbg);color:var(--ok)}
.badge.muted{background:#E9E9F5;color:var(--muted)}

.btn{padding:9px 16px;border:none;border-radius:9px;background:linear-gradient(135deg,var(--main),var(--deep));
  color:#fff;font-weight:750;font-size:13px;cursor:pointer;font-family:inherit}
.btn:hover{filter:brightness(1.06)}
.btn.ghost{background:none;border:1.5px solid var(--border);color:var(--ink)}
.btn.ghost:hover{background:var(--surface)}
.btn.sm{padding:7px 12px;font-size:12.5px}

.formrow{display:flex;gap:14px;flex-wrap:wrap;align-items:flex-end}
.field{display:flex;flex-direction:column;gap:6px;min-width:200px}
.field.grow{flex:1;min-width:260px}
.field label{font-size:12px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.04em}
.field select,.field input,.field textarea{padding:11px 14px;border:1.5px solid var(--border);border-radius:10px;
  font-family:inherit;font-size:14px;background:var(--surface);color:var(--ink)}
.field textarea{resize:vertical;min-height:44px}
.field select:focus,.field input:focus,.field textarea:focus{outline:none;border-color:var(--main);background:#fff;
  box-shadow:0 0 0 3px rgba(15,118,110,.12)}

.filterbar{display:flex;gap:10px;flex-wrap:wrap;align-items:center}
.filterbar select{padding:8px 12px;border:1.5px solid var(--border);border-radius:9px;font-family:inherit;
  font-size:13px;background:var(--surface);color:var(--ink)}

.tblwrap{overflow-x:auto}
table{border-collapse:collapse;width:100%;font-size:13.5px;min-width:760px}
th,td{padding:11px 16px;text-align:left;border-bottom:1px solid var(--line);white-space:nowrap}
thead th{font-size:11px;letter-spacing:.06em;text-transform:uppercase;color:var(--muted);font-weight:700;background:var(--surface)}
tbody tr:hover{background:var(--surface)}
.ttl-cell{white-space:normal;max-width:280px;font-weight:700;color:var(--ink)}
.empty{padding:36px;text-align:center;color:var(--muted);font-size:14px}
.type-tag{font-size:11px;font-weight:700;color:var(--muted)}

/* ── Dự án dài hạn (Strategic Projects) — milestone checklist + progress bar ── */
.project-box{border:1px solid var(--line);border-radius:12px;padding:16px;margin-bottom:14px;background:var(--surface)}
.project-box:last-child{margin-bottom:0}
.project-head{display:flex;align-items:center;justify-content:space-between;gap:10px;margin-bottom:8px;flex-wrap:wrap}
.project-title{font-weight:800;font-size:14.5px;color:var(--ink);display:flex;align-items:center;gap:8px}
.project-pct{font-weight:800;font-size:14px;color:var(--main)}
.progress-bar{height:8px;border-radius:20px;background:var(--border);overflow:hidden;margin:8px 0 12px}
.progress-fill{height:100%;background:linear-gradient(90deg,var(--main),var(--deep));border-radius:20px;transition:width .3s}
.milestone-list{display:flex;flex-direction:column;gap:6px}
.milestone-row{display:flex;align-items:center;gap:10px;padding:8px 10px;border-radius:9px;background:#fff;border:1px solid var(--line)}
.milestone-row.done{opacity:.6}
.ms-check{font-size:15px;flex:none}
.ms-title{flex:1;font-size:13px;color:var(--ink)}
.milestone-row.done .ms-title{text-decoration:line-through}
.ms-due{font-size:11.5px;color:var(--muted);flex:none}
</style>
</head>
<body class="wh">
<%@ include file="warehouse-sidebar.jsp" %>
<div class="main">
  <header class="wh-topbar">
    <div class="crumb">Nhiệm vụ &amp; SOP</div>
    <div class="right">
      <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc"><%= initials %></a>
    </div>
  </header>

  <div class="wrap">
    <div class="head">
      <div>
        <h1>Quản lý <span>Nhiệm vụ</span> &amp; SOP</h1>
        <p>Task tự động hệ thống sinh ra (hạn dùng, ROP, lệch ca) và task giao việc thủ công — tất cả ở một nơi.</p>
      </div>
    </div>

    <c:if test="${param.ok == 'true'}">
      <div class="banner ok">✅ <c:out value="${param.msg}"/></div>
    </c:if>
    <c:if test="${param.ok == 'false'}">
      <div class="banner err">⛔ <c:out value="${param.msg}"/></div>
    </c:if>

    <div class="card">
      <div class="card-head"><div class="wh-ic">📋</div><h2>Nhiệm vụ hôm nay <small>(${myTasks.size()} việc cần làm)</small></h2></div>
      <div class="card-body">
        <c:choose>
          <c:when test="${empty myTasks}">
            <div class="empty">Không có nhiệm vụ nào đang chờ — mọi thứ đã ổn! 👍</div>
          </c:when>
          <c:otherwise>
            <div class="task-list">
              <c:forEach var="t" items="${myTasks}">
                <div class="task-row">
                  <span class="pr-dot ${t.priority}" title="Ưu tiên ${t.priorityLabel}"></span>
                  <div class="tinfo">
                    <div class="ttitle">${fn:escapeXml(t.title)}</div>
                    <c:if test="${not empty t.description}"><div class="tdesc">${fn:escapeXml(t.description)}</div></c:if>
                    <div class="tmeta">
                      <c:choose>
                        <c:when test="${t.taskType == 'SYSTEM_AUTO'}"><span class="type-tag">🤖 Hệ thống</span></c:when>
                        <c:otherwise><span class="type-tag">👤 ${t.createdByName}</span></c:otherwise>
                      </c:choose>
                      <c:if test="${empty t.assignedTo}"><span class="badge muted">Chưa ai nhận</span></c:if>
                      <c:if test="${not empty t.dueDate}">
                        <span>⏱ Hạn: ${t.dueDateDisplay}</span>
                        <c:if test="${not empty t.zoneLabel}"><span class="badge ${t.zoneCssClass}">${t.zoneLabel}</span></c:if>
                      </c:if>
                    </div>
                  </div>
                  <div class="tactions">
                    <c:if test="${empty t.assignedTo}">
                      <form method="post" action="<%= ctx %>/warehouse-task" style="display:inline">
                        <input type="hidden" name="uid" value="${staffUid}">
                        <input type="hidden" name="action" value="claim">
                        <input type="hidden" name="taskId" value="${t.taskId}">
                        <button type="submit" class="btn ghost sm">🙋 Nhận việc</button>
                      </form>
                    </c:if>
                    <form method="post" action="<%= ctx %>/warehouse-task" style="display:inline">
                      <input type="hidden" name="uid" value="${staffUid}">
                      <input type="hidden" name="action" value="complete">
                      <input type="hidden" name="taskId" value="${t.taskId}">
                      <button type="submit" class="btn sm">✅ Hoàn thành</button>
                    </form>
                  </div>
                </div>
              </c:forEach>
            </div>
          </c:otherwise>
        </c:choose>
      </div>
    </div>

    <div class="card">
      <div class="card-head"><div class="wh-ic ok">🚀</div><h2>Dự án dài hạn <small>(${myProjects.size()} dự án được Admin giao)</small></h2></div>
      <div class="card-body">
        <c:choose>
          <c:when test="${empty myProjects}">
            <div class="empty">Chưa có dự án dài hạn nào được giao.</div>
          </c:when>
          <c:otherwise>
            <c:forEach var="p" items="${myProjects}">
              <div class="project-box">
                <div class="project-head">
                  <div class="project-title">
                    ${fn:escapeXml(p.title)}
                    <c:if test="${not empty p.zoneLabel}"><span class="badge ${p.zoneCssClass}">${p.zoneLabel}</span></c:if>
                  </div>
                  <div class="project-pct">${p.progressPercentage}%</div>
                </div>
                <c:if test="${not empty p.description}"><div class="tdesc" style="margin-bottom:8px">${fn:escapeXml(p.description)}</div></c:if>
                <div class="progress-bar"><div class="progress-fill" style="width:${p.progressPercentage}%"></div></div>
                <c:if test="${not empty p.dueDate}"><div class="tmeta" style="margin-bottom:10px">⏱ Hạn báo cáo tổng: ${p.dueDateDisplay}</div></c:if>
                <div class="milestone-list">
                  <c:forEach var="m" items="${milestonesByProject[p.taskId]}">
                    <div class="milestone-row ${m.done ? 'done' : ''}">
                      <span class="ms-check">${m.done ? '✅' : '⬜'}</span>
                      <span class="ms-title">${fn:escapeXml(m.title)}</span>
                      <c:if test="${not empty m.dueDate}"><span class="ms-due">Hạn: ${m.dueDateDisplay}</span></c:if>
                      <c:if test="${!m.done}">
                        <form method="post" action="<%= ctx %>/warehouse-task" style="display:inline">
                          <input type="hidden" name="uid" value="${staffUid}">
                          <input type="hidden" name="action" value="complete">
                          <input type="hidden" name="taskId" value="${m.taskId}">
                          <button type="submit" class="btn ghost sm">Đánh dấu xong</button>
                        </form>
                      </c:if>
                    </div>
                  </c:forEach>
                </div>
              </div>
            </c:forEach>
          </c:otherwise>
        </c:choose>
      </div>
    </div>

    <div class="card">
      <div class="card-head"><div class="wh-ic jade">➕</div><h2>Tạo công việc mới <small>(giao cho Thủ kho khác hoặc để chung)</small></h2></div>
      <div class="card-body">
        <form method="post" action="<%= ctx %>/warehouse-task">
          <input type="hidden" name="uid" value="${staffUid}">
          <input type="hidden" name="action" value="create">
          <div class="formrow" style="margin-bottom:14px">
            <div class="field grow">
              <label>Tiêu đề</label>
              <div class="wh-field">
                <span class="wh-field-ic">📝</span>
                <input type="text" name="title" maxlength="255" placeholder="VD: Lau dọn và ghi nhận nhiệt độ tủ lạnh bảo quản vắc-xin" required>
              </div>
            </div>
            <div class="field">
              <label>Độ ưu tiên</label>
              <select name="priority">
                <option value="HIGH">🔴 Cao</option>
                <option value="MEDIUM" selected>🟡 Trung bình</option>
                <option value="LOW">🔵 Thấp</option>
              </select>
            </div>
          </div>
          <div class="formrow" style="margin-bottom:14px">
            <div class="field grow">
              <label>Mô tả chi tiết</label>
              <textarea name="description" maxlength="1000" placeholder="Ghi rõ yêu cầu, vị trí, thời hạn…"></textarea>
            </div>
          </div>
          <div class="formrow">
            <div class="field">
              <label>Giao cho</label>
              <select name="assignedTo">
                <option value="">— Để chung (ai cũng nhận được) —</option>
                <c:forEach var="a" items="${assignees}">
                  <option value="${a.accountId}" ${a.accountId == staffAcc.accountId ? 'selected' : ''}>${a.fullName}<c:if test="${a.accountId == staffAcc.accountId}"> (Tôi)</c:if></option>
                </c:forEach>
              </select>
            </div>
            <div class="field">
              <label>Hạn hoàn thành</label>
              <input type="datetime-local" name="dueDate">
            </div>
            <button type="submit" class="btn">➕ Tạo công việc</button>
          </div>
        </form>
      </div>
    </div>

    <div class="card">
      <div class="card-head">
        <div style="display:flex;align-items:center;gap:8px"><div class="wh-ic">📊</div><h2>Toàn bộ công việc</h2></div>
        <form method="get" action="<%= ctx %>/warehouse-task" class="filterbar">
          <input type="hidden" name="uid" value="${staffUid}">
          <select name="status" onchange="this.form.submit()">
            <option value="">Mọi trạng thái</option>
            <option value="PENDING" ${statusFilter == 'PENDING' ? 'selected' : ''}>Chờ xử lý</option>
            <option value="IN_PROGRESS" ${statusFilter == 'IN_PROGRESS' ? 'selected' : ''}>Đang làm</option>
            <option value="COMPLETED_ON_TIME" ${statusFilter == 'COMPLETED_ON_TIME' ? 'selected' : ''}>Hoàn thành đúng hạn</option>
            <option value="COMPLETED_LATE" ${statusFilter == 'COMPLETED_LATE' ? 'selected' : ''}>Hoàn thành trễ hạn</option>
            <option value="CANCELLED" ${statusFilter == 'CANCELLED' ? 'selected' : ''}>Đã huỷ</option>
          </select>
          <select name="priority" onchange="this.form.submit()">
            <option value="">Mọi độ ưu tiên</option>
            <option value="HIGH" ${priorityFilter == 'HIGH' ? 'selected' : ''}>Cao</option>
            <option value="MEDIUM" ${priorityFilter == 'MEDIUM' ? 'selected' : ''}>Trung bình</option>
            <option value="LOW" ${priorityFilter == 'LOW' ? 'selected' : ''}>Thấp</option>
          </select>
        </form>
      </div>
      <div class="tblwrap">
        <table>
          <thead><tr>
            <th>Công việc</th><th>Loại</th><th>Ưu tiên</th><th>Trạng thái</th>
            <th>Giao cho</th><th>Người tạo</th><th>Hoàn thành lúc</th><th></th>
          </tr></thead>
          <tbody>
          <c:choose>
            <c:when test="${empty board}">
              <tr><td colspan="8" class="empty">Không có công việc nào khớp bộ lọc.</td></tr>
            </c:when>
            <c:otherwise>
              <c:forEach var="t" items="${board}">
                <tr>
                  <td class="ttl-cell">${fn:escapeXml(t.title)}</td>
                  <td class="type-tag">${t.taskType == 'SYSTEM_AUTO' ? '🤖 Tự động' : '👤 Thủ công'}</td>
                  <td>
                    <c:choose>
                      <c:when test="${t.priority == 'HIGH'}"><span class="badge danger">Cao</span></c:when>
                      <c:when test="${t.priority == 'MEDIUM'}"><span class="badge warn">Trung bình</span></c:when>
                      <c:otherwise><span class="badge info">Thấp</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${t.status == 'COMPLETED_ON_TIME'}"><span class="badge ok">Đúng hạn</span></c:when>
                      <c:when test="${t.status == 'COMPLETED_LATE'}"><span class="badge warn">Trễ hạn</span></c:when>
                      <c:when test="${t.status == 'CANCELLED'}"><span class="badge muted">Đã huỷ</span></c:when>
                      <c:when test="${t.status == 'IN_PROGRESS'}"><span class="badge info">Đang làm</span></c:when>
                      <c:otherwise><span class="badge warn">Chờ xử lý</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td>${not empty t.assignedToName ? t.assignedToName : '—'}</td>
                  <td>${not empty t.createdByName ? t.createdByName : 'Hệ thống'}</td>
                  <td>
                    <c:if test="${not empty t.completedAt}">
                      ${t.completedAtDisplay} — ${t.completedByName}
                    </c:if>
                    <c:if test="${empty t.completedAt}">—</c:if>
                  </td>
                  <td>
                    <c:if test="${t.status == 'PENDING' || t.status == 'IN_PROGRESS'}">
                      <form method="post" action="<%= ctx %>/warehouse-task" style="display:inline"
                            onsubmit="return confirm('Huỷ công việc này?');">
                        <input type="hidden" name="uid" value="${staffUid}">
                        <input type="hidden" name="action" value="cancel">
                        <input type="hidden" name="taskId" value="${t.taskId}">
                        <button type="submit" class="btn ghost sm">Huỷ</button>
                      </form>
                    </c:if>
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
</div>
</body>
</html>
