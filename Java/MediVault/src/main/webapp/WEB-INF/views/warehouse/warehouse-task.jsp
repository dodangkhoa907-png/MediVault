<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%--
  warehouse-task.jsp — Nhiệm vụ & SOP (Warehouse Console)

  Thiết kế lại 2026-08-02 (bản độ sâu):
  • Thẻ thống kê ở đầu trang, tính client-side từ chính bảng đã render — không
    thêm truy vấn nào.
  • "Dải hạn 14 ngày" thay cho lịch tháng: lịch tháng cho ~5 nhiệm vụ thì 25 ô
    trống, còn dải 14 ngày trả lời đúng câu hỏi thủ kho hỏi mỗi sáng —
    "tuần này có gì tới hạn".
  • Thẻ nhiệm vụ đọc mức ưu tiên bằng dải màu dọc mép trái thay vì chấm 9px.

  Mọi form POST (claim / complete / create / cancel) và tên field giữ nguyên.
--%>
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
<link rel="stylesheet" href="<%= ctx %>/css/warehouse-portal.css?v=11">
<style>
a{text-decoration:none;color:inherit}
.wh-shell{max-width:1440px}

/* Thẻ nhiệm vụ: dải màu ưu tiên chạy dọc mép trái — đọc được mức khẩn từ xa,
   khác chấm 9px cũ phải nhìn gần mới thấy. */
.wh-task{position:relative;padding-left:22px;border-radius:18px}
.wh-task::before{content:'';position:absolute;left:0;top:0;bottom:0;width:5px;border-radius:18px 0 0 18px}
.wh-task.pr-HIGH::before  {background:linear-gradient(180deg,#F87171,#DC2626)}
.wh-task.pr-MEDIUM::before{background:linear-gradient(180deg,#FBBF24,#D97706)}
.wh-task.pr-LOW::before   {background:linear-gradient(180deg,#94A3B8,#64748B)}
.wh-task .dot{display:none}

/* Dải hạn 14 ngày */
.dl{display:grid;grid-template-columns:repeat(14,1fr);gap:6px;padding:20px 22px 22px}
.dl-d{border-radius:12px;padding:9px 4px 10px;text-align:center;border:1px solid var(--wh-line);
  background:var(--wh-surf);box-shadow:var(--wh-sh-sm);min-height:76px;
  display:flex;flex-direction:column;align-items:center;gap:5px}
.dl-d .dw{font-size:9.5px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.04em}
.dl-d .dn{font-size:15px;font-weight:800;color:var(--ink);font-variant-numeric:tabular-nums;line-height:1}
.dl-d.today{border-color:var(--main);box-shadow:0 0 0 3px rgba(15,118,110,.13),var(--wh-sh-sm)}
.dl-d.today .dn{color:var(--deep)}
.dl-d .pips{display:flex;gap:3px;flex-wrap:wrap;justify-content:center;margin-top:auto}
.dl-d .pip{width:7px;height:7px;border-radius:50%;display:block}
.dl-d.has{background:linear-gradient(180deg,#FFFBEB,#FEF9EC)}
.dl-d.hot{background:linear-gradient(180deg,#FEF2F2,#FEF5F5);border-color:#FCA5A5}
@media(max-width:900px){.dl{grid-template-columns:repeat(7,1fr)}}

/* Dự án dài hạn */
.proj{border:1px solid var(--wh-line);border-radius:18px;padding:18px;background:var(--wh-surf);box-shadow:var(--wh-sh-sm)}
.proj + .proj{margin-top:14px}
.proj-head{display:flex;align-items:center;justify-content:space-between;gap:12px;flex-wrap:wrap;margin-bottom:9px}
.proj-title{font-weight:800;font-size:15px;color:var(--ink);display:flex;align-items:center;gap:9px;flex-wrap:wrap}
.proj-pct{font-weight:800;font-size:17px;color:var(--deep);font-variant-numeric:tabular-nums;flex:none;letter-spacing:-.4px}
.proj-desc{font-size:12.5px;color:var(--muted);line-height:1.55;margin-bottom:12px}
.proj-due{font-size:11.5px;color:var(--muted);margin:11px 0;display:flex;align-items:center;gap:6px}
.proj-due svg{width:13px;height:13px;opacity:.75}

/* Bảng toàn bộ công việc */
.t-title{width:auto;min-width:250px} .t-type{width:120px} .t-pri{width:120px}
.t-status{width:140px} .t-asg{width:150px} .t-by{width:150px} .t-done{width:210px} .t-act{width:90px}
#tblBoard{min-width:1120px}
.t-title .cell{white-space:normal;line-height:1.45;font-weight:700;color:var(--ink)}
.type-tag{display:inline-flex;align-items:center;gap:6px;font-size:12px;color:var(--muted);font-weight:650}
.type-tag svg{width:14px;height:14px;opacity:.8}
</style>
<meta name="csrf-token" content="${csrfToken}">
<script src="<%= ctx %>/js/csrf.js"></script>
<script src="<%= ctx %>/js/warehouse-ui.js" defer></script>
</head>
<body class="wh">
<%@ include file="/WEB-INF/views/icons.jsp" %>
<%@ include file="warehouse-sidebar.jsp" %>

<div class="main">
  <header class="wh-topbar">
    <div class="crumb">Công việc</div>
    <div class="right">
      <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc của <%= fullName %>"><%= initials %></a>
    </div>
  </header>

  <div class="wh-shell wh-anim">

    <div class="wh-head">
      <div>
        <h1>Nhiệm vụ &amp; SOP</h1>
        <p class="sub">Task hệ thống tự sinh (hạn dùng, ROP, lệch ca) và task giao việc thủ công — tất cả ở một nơi.</p>
      </div>
    </div>

    <c:if test="${param.ok == 'true'}">
      <div class="wh-note ok" role="status"><svg><use href="#ic-check-circle"/></svg><span><c:out value="${param.msg}"/></span></div>
    </c:if>
    <c:if test="${param.ok == 'false'}">
      <div class="wh-note danger" role="alert"><svg><use href="#ic-alert"/></svg><span><c:out value="${param.msg}"/></span></div>
    </c:if>

    <!-- ══ Thống kê — tính từ chính bảng bên dưới ══ -->
    <div class="wh-tiles" style="margin-bottom:24px">
      <div class="wh-tile">
        <div class="ic warn"><svg><use href="#ic-clipboard"/></svg></div>
        <div class="n" id="stOpen">0</div>
        <div class="l">Đang chờ xử lý</div>
        <div class="s">Gồm cả việc chưa ai nhận</div>
      </div>
      <div class="wh-tile">
        <div class="ic ok"><svg><use href="#ic-check-circle"/></svg></div>
        <div class="n" id="stDone">0</div>
        <div class="l">Đã hoàn thành</div>
        <div class="s" id="stDoneSub">—</div>
      </div>
      <div class="wh-tile">
        <div class="ic violet"><svg><use href="#ic-target"/></svg></div>
        <div class="n" id="stRate">—</div>
        <div class="l">Tỷ lệ đúng hạn</div>
        <div class="s">Trên tổng việc đã xong</div>
      </div>
      <div class="wh-tile">
        <div class="ic info"><svg><use href="#ic-bot"/></svg></div>
        <div class="n" id="stAuto">0</div>
        <div class="l">Do hệ thống tự sinh</div>
        <div class="s">Cảnh báo hạn dùng, ROP, lệch ca</div>
      </div>
    </div>

    <!-- ══ Lưới lệch 7/5 ══ -->
    <div class="wh-g12" style="margin-bottom:24px">

      <div class="c7">
        <div class="wh-card" style="margin-bottom:0">
          <div class="wh-card-head">
            <div class="wh-ic"><svg><use href="#ic-clipboard"/></svg></div>
            <div class="tt">
              <h2>Nhiệm vụ hôm nay <small>${myTasks.size()} việc</small></h2>
              <div class="desc">Việc đang chờ bạn hoặc chưa ai nhận.</div>
            </div>
          </div>
          <c:choose>
            <c:when test="${empty myTasks}">
              <div class="wh-empty good">
                <div class="art">🎉</div>
                <div class="t">Không còn nhiệm vụ nào chờ</div>
                <div class="d">Mọi việc trong ca đã xong. Task mới sẽ tự xuất hiện khi hệ thống phát hiện lô cận hạn hoặc tồn chạm ROP.</div>
              </div>
            </c:when>
            <c:otherwise>
              <div class="wh-card-body">
                <c:forEach var="t" items="${myTasks}">
                  <div class="wh-task pr-${t.priority}">
                    <div class="bd">
                      <div class="t1">${fn:escapeXml(t.title)}</div>
                      <c:if test="${not empty t.description}"><div class="t2">${fn:escapeXml(t.description)}</div></c:if>
                      <div class="meta">
                        <c:choose>
                          <c:when test="${t.taskType == 'SYSTEM_AUTO'}">
                            <span class="m"><svg><use href="#ic-bot"/></svg> Hệ thống</span>
                          </c:when>
                          <c:otherwise>
                            <span class="m"><svg><use href="#ic-user"/></svg> ${t.createdByName}</span>
                          </c:otherwise>
                        </c:choose>
                        <c:if test="${empty t.assignedTo}"><span class="wh-badge mute">Chưa ai nhận</span></c:if>
                        <c:if test="${not empty t.dueDate}">
                          <span class="m"><svg><use href="#ic-clock"/></svg> Hạn: ${t.dueDateDisplay}</span>
                          <c:if test="${not empty t.zoneLabel}"><span class="wh-badge ${t.zoneCssClass}">${t.zoneLabel}</span></c:if>
                        </c:if>
                      </div>
                    </div>
                    <div class="acts">
                      <c:if test="${empty t.assignedTo}">
                        <form method="post" action="<%= ctx %>/warehouse-task">
                          <input type="hidden" name="_csrf" value="${csrfToken}">
                          <input type="hidden" name="uid" value="${staffUid}">
                          <input type="hidden" name="action" value="claim">
                          <input type="hidden" name="taskId" value="${t.taskId}">
                          <button type="submit" class="wh-btn"><svg><use href="#ic-hand"/></svg> Nhận việc</button>
                        </form>
                      </c:if>
                      <form method="post" action="<%= ctx %>/warehouse-task">
                        <input type="hidden" name="_csrf" value="${csrfToken}">
                        <input type="hidden" name="uid" value="${staffUid}">
                        <input type="hidden" name="action" value="complete">
                        <input type="hidden" name="taskId" value="${t.taskId}">
                        <button type="submit" class="wh-btn wh-btn-primary"><svg><use href="#ic-check"/></svg> Hoàn thành</button>
                      </form>
                    </div>
                  </div>
                </c:forEach>
              </div>
            </c:otherwise>
          </c:choose>
        </div>
      </div>

      <div class="c5">
        <div class="wh-card" style="margin-bottom:24px">
          <div class="wh-card-head">
            <div class="wh-ic violet"><svg><use href="#ic-calendar"/></svg></div>
            <div class="tt">
              <h2>Hạn trong 14 ngày tới</h2>
              <div class="desc">Mỗi chấm là một việc đến hạn trong ngày đó.</div>
            </div>
          </div>
          <div class="dl" id="deadlineStrip"></div>
        </div>

        <div class="wh-card" style="margin-bottom:0">
          <div class="wh-card-head">
            <div class="wh-ic ok"><svg><use href="#ic-rocket"/></svg></div>
            <div class="tt">
              <h2>Dự án dài hạn <small>${myProjects.size()}</small></h2>
              <div class="desc">Việc nhiều mốc do Admin giao.</div>
            </div>
          </div>
          <c:choose>
            <c:when test="${empty myProjects}">
              <div class="wh-empty">
                <div class="art"><svg style="width:26px;height:26px"><use href="#ic-rocket"/></svg></div>
                <div class="t">Chưa có dự án nào</div>
                <div class="d">Dự án dài hạn có nhiều mốc và tiến độ theo dõi riêng.</div>
              </div>
            </c:when>
            <c:otherwise>
              <div class="wh-card-body">
                <c:forEach var="p" items="${myProjects}">
                  <div class="proj">
                    <div class="proj-head">
                      <div class="proj-title">
                        ${fn:escapeXml(p.title)}
                        <c:if test="${not empty p.zoneLabel}"><span class="wh-badge ${p.zoneCssClass}">${p.zoneLabel}</span></c:if>
                      </div>
                      <div class="proj-pct">${p.progressPercentage}%</div>
                    </div>
                    <c:if test="${not empty p.description}"><div class="proj-desc">${fn:escapeXml(p.description)}</div></c:if>
                    <div class="wh-progress"><i style="--pct: ${p.progressPercentage}%; width: var(--pct);"></i></div>
                    <c:if test="${not empty p.dueDate}">
                      <div class="proj-due"><svg><use href="#ic-clock"/></svg> Hạn báo cáo tổng: ${p.dueDateDisplay}</div>
                    </c:if>
                    <div style="margin-top:12px">
                      <c:forEach var="m" items="${milestonesByProject[p.taskId]}">
                        <div class="wh-ms ${m.done ? 'done' : ''}">
                          <svg><use href="#${m.done ? 'ic-square-check' : 'ic-square'}"/></svg>
                          <span class="t">${fn:escapeXml(m.title)}</span>
                          <c:if test="${not empty m.dueDate}"><span class="due">Hạn: ${m.dueDateDisplay}</span></c:if>
                          <c:if test="${!m.done}">
                            <form method="post" action="<%= ctx %>/warehouse-task">
                              <input type="hidden" name="_csrf" value="${csrfToken}">
                              <input type="hidden" name="uid" value="${staffUid}">
                              <input type="hidden" name="action" value="complete">
                              <input type="hidden" name="taskId" value="${m.taskId}">
                              <button type="submit" class="wh-btn" style="height:32px;padding:0 12px;font-size:12.5px">Đánh dấu xong</button>
                            </form>
                          </c:if>
                        </div>
                      </c:forEach>
                    </div>
                  </div>
                </c:forEach>
              </div>
            </c:otherwise>
          </c:choose>
        </div>
      </div>
    </div>

    <!-- ══ Bảng kanban — kéo thẻ để đổi trạng thái ══ -->
    <div class="wh-card">
      <div class="wh-card-head">
        <div class="wh-ic violet"><svg><use href="#ic-columns"/></svg></div>
        <div class="tt">
          <h2>Bảng công việc</h2>
          <div class="desc">Kéo thẻ sang cột khác để đổi trạng thái. Chỉ thả được vào cột hợp lệ.</div>
        </div>
        <div class="sp">
          <span class="wh-badge mute" id="kbHint">Kéo bằng chuột, hoặc dùng nút trên thẻ</span>
        </div>
      </div>
      <div class="wh-card-body">
        <div class="wh-kanban" id="kanban">
          <div class="kb-col" data-st="PENDING">
            <div class="kb-col-head"><span class="dot"></span><span class="t">Chờ xử lý</span><span class="n">0</span></div>
            <div class="kb-body"></div>
          </div>
          <div class="kb-col" data-st="IN_PROGRESS">
            <div class="kb-col-head"><span class="dot"></span><span class="t">Đang làm</span><span class="n">0</span></div>
            <div class="kb-body"></div>
          </div>
          <div class="kb-col" data-st="DONE">
            <div class="kb-col-head"><span class="dot"></span><span class="t">Hoàn thành</span><span class="n">0</span></div>
            <div class="kb-body"></div>
          </div>
          <div class="kb-col" data-st="CANCELLED">
            <div class="kb-col-head"><span class="dot"></span><span class="t">Đã huỷ</span><span class="n">0</span></div>
            <div class="kb-body"></div>
          </div>
        </div>
      </div>
    </div>

    <!-- ══ Tạo công việc mới ══ -->
    <div class="wh-card">
      <div class="wh-card-head">
        <div class="wh-ic violet"><svg><use href="#ic-plus"/></svg></div>
        <div class="tt">
          <h2>Tạo công việc mới</h2>
          <div class="desc">Giao cho Thủ kho khác, hoặc để chung cho ai rảnh thì nhận.</div>
        </div>
      </div>
      <div class="wh-card-body">
        <form method="post" action="<%= ctx %>/warehouse-task">
          <input type="hidden" name="_csrf" value="${csrfToken}">
          <input type="hidden" name="uid" value="${staffUid}">
          <input type="hidden" name="action" value="create">

          <div class="wh-fg">
            <label for="tkTitle">Tiêu đề</label>
            <input class="wh-in" type="text" id="tkTitle" name="title" maxlength="255" required
                   placeholder="VD: Lau dọn và ghi nhận nhiệt độ tủ lạnh bảo quản vắc-xin">
          </div>
          <div class="wh-fg">
            <label for="tkDesc">Mô tả chi tiết</label>
            <textarea class="wh-in" id="tkDesc" name="description" maxlength="1000"
                      placeholder="Ghi rõ yêu cầu, vị trí, thời hạn…"></textarea>
          </div>
          <div class="wh-row2">
            <div class="wh-fg">
              <label for="tkPri">Độ ưu tiên</label>
              <select class="wh-in" id="tkPri" name="priority">
                <option value="HIGH">Cao</option>
                <option value="MEDIUM" selected>Trung bình</option>
                <option value="LOW">Thấp</option>
              </select>
            </div>
            <div class="wh-fg">
              <label for="tkAsg">Giao cho</label>
              <select class="wh-in" id="tkAsg" name="assignedTo">
                <option value="">— Để chung, ai cũng nhận được —</option>
                <c:forEach var="a" items="${assignees}">
                  <option value="${a.accountId}" ${a.accountId == staffAcc.accountId ? 'selected' : ''}>${a.fullName}<c:if test="${a.accountId == staffAcc.accountId}"> (Tôi)</c:if></option>
                </c:forEach>
              </select>
            </div>
          </div>
          <div class="wh-fg">
            <label for="tkDue">Hạn hoàn thành</label>
            <input class="wh-in" type="datetime-local" id="tkDue" name="dueDate">
          </div>
          <button type="submit" class="wh-btn wh-btn-primary">
            <svg><use href="#ic-plus"/></svg> Tạo công việc
          </button>
        </form>
      </div>
    </div>

    <!-- ══ Toàn bộ công việc ══ -->
    <div class="wh-toolbar" id="toolbar">
      <div style="display:flex;align-items:center;gap:14px">
        <div class="wh-ic sm info"><svg><use href="#ic-bar-chart"/></svg></div>
        <h2 style="font-size:15px;font-weight:800">Toàn bộ công việc</h2>
      </div>
      <form method="get" action="<%= ctx %>/warehouse-task" class="wh-toolbar-right" id="filterForm">
        <input type="hidden" name="uid" value="${staffUid}">
        <div class="wh-search" id="searchBox">
          <svg class="lead"><use href="#ic-search"/></svg>
          <input type="search" id="q" autocomplete="off" placeholder="Tìm theo tiêu đề công việc…" aria-label="Tìm trong bảng công việc">
          <button type="button" class="clear" id="qClear" aria-label="Xoá từ khoá"><svg><use href="#ic-x"/></svg></button>
        </div>
        <select class="wh-select" name="status" aria-label="Lọc theo trạng thái" onchange="this.form.submit()">
          <option value="">Mọi trạng thái</option>
          <option value="PENDING" ${statusFilter == 'PENDING' ? 'selected' : ''}>Chờ xử lý</option>
          <option value="IN_PROGRESS" ${statusFilter == 'IN_PROGRESS' ? 'selected' : ''}>Đang làm</option>
          <option value="COMPLETED_ON_TIME" ${statusFilter == 'COMPLETED_ON_TIME' ? 'selected' : ''}>Hoàn thành đúng hạn</option>
          <option value="COMPLETED_LATE" ${statusFilter == 'COMPLETED_LATE' ? 'selected' : ''}>Hoàn thành trễ hạn</option>
          <option value="CANCELLED" ${statusFilter == 'CANCELLED' ? 'selected' : ''}>Đã huỷ</option>
        </select>
        <select class="wh-select" name="priority" aria-label="Lọc theo độ ưu tiên" onchange="this.form.submit()">
          <option value="">Mọi độ ưu tiên</option>
          <option value="HIGH" ${priorityFilter == 'HIGH' ? 'selected' : ''}>Cao</option>
          <option value="MEDIUM" ${priorityFilter == 'MEDIUM' ? 'selected' : ''}>Trung bình</option>
          <option value="LOW" ${priorityFilter == 'LOW' ? 'selected' : ''}>Thấp</option>
        </select>
      </form>
    </div>

    <div class="wh-tablecard">
      <div class="wh-tablescroll">
        <c:choose>
          <c:when test="${empty board}">
            <div class="wh-empty">
              <div class="art">🔍</div>
              <div class="t">Không có công việc nào khớp bộ lọc</div>
              <div class="d">Thử bỏ bớt điều kiện lọc ở thanh phía trên.</div>
            </div>
          </c:when>
          <c:otherwise>
            <table class="wh-table" id="tblBoard">
              <thead>
                <tr>
                  <th class="t-title">Công việc</th>
                  <th class="t-type">Loại</th>
                  <th class="t-pri">Ưu tiên</th>
                  <th class="t-status">Trạng thái</th>
                  <th class="t-asg">Giao cho</th>
                  <th class="t-by">Người tạo</th>
                  <th class="t-done">Hoàn thành lúc</th>
                  <th class="t-act"></th>
                </tr>
              </thead>
              <tbody id="bodyBoard">
                <c:forEach var="t" items="${board}">
                  <tr data-title="${fn:escapeXml(t.title)}" data-status="${t.status}"
                      data-type="${t.taskType}" data-due="${t.dueDate}"
                      data-id="${t.taskId}" data-pri="${t.priority}"
                      data-asg="${fn:escapeXml(t.assignedToName)}"
                      data-duedisp="${fn:escapeXml(t.dueDateDisplay)}">
                    <td class="t-title"><div class="cell">${fn:escapeXml(t.title)}</div></td>
                    <td class="t-type">
                      <c:choose>
                        <c:when test="${t.taskType == 'SYSTEM_AUTO'}">
                          <span class="type-tag"><svg><use href="#ic-bot"/></svg> Tự động</span>
                        </c:when>
                        <c:otherwise>
                          <span class="type-tag"><svg><use href="#ic-user"/></svg> Thủ công</span>
                        </c:otherwise>
                      </c:choose>
                    </td>
                    <td class="t-pri">
                      <c:choose>
                        <c:when test="${t.priority == 'HIGH'}"><span class="wh-badge out">Cao</span></c:when>
                        <c:when test="${t.priority == 'MEDIUM'}"><span class="wh-badge low">Trung bình</span></c:when>
                        <c:otherwise><span class="wh-badge mute">Thấp</span></c:otherwise>
                      </c:choose>
                    </td>
                    <td class="t-status">
                      <c:choose>
                        <c:when test="${t.status == 'COMPLETED_ON_TIME'}"><span class="wh-badge ok">Đúng hạn</span></c:when>
                        <c:when test="${t.status == 'COMPLETED_LATE'}"><span class="wh-badge low">Trễ hạn</span></c:when>
                        <c:when test="${t.status == 'CANCELLED'}"><span class="wh-badge mute">Đã huỷ</span></c:when>
                        <c:when test="${t.status == 'IN_PROGRESS'}"><span class="wh-badge soon">Đang làm</span></c:when>
                        <c:otherwise><span class="wh-badge low">Chờ xử lý</span></c:otherwise>
                      </c:choose>
                    </td>
                    <td class="t-asg">${not empty t.assignedToName ? t.assignedToName : '—'}</td>
                    <td class="t-by">${not empty t.createdByName ? t.createdByName : 'Hệ thống'}</td>
                    <td class="t-done">
                      <c:choose>
                        <c:when test="${not empty t.completedAt}">${t.completedAtDisplay} — ${t.completedByName}</c:when>
                        <c:otherwise>—</c:otherwise>
                      </c:choose>
                    </td>
                    <td class="t-act">
                      <c:if test="${t.status == 'PENDING' || t.status == 'IN_PROGRESS'}">
                        <form method="post" action="<%= ctx %>/warehouse-task"
                              onsubmit="return confirm('Huỷ công việc này?');">
                          <input type="hidden" name="_csrf" value="${csrfToken}">
                          <input type="hidden" name="uid" value="${staffUid}">
                          <input type="hidden" name="action" value="cancel">
                          <input type="hidden" name="taskId" value="${t.taskId}">
                          <button type="submit" class="wh-btn wh-btn-ghost" style="height:32px;padding:0 12px;font-size:12.5px">Huỷ</button>
                        </form>
                      </c:if>
                    </td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>

            <div class="wh-empty" id="searchEmpty" hidden>
              <div class="art">🔍</div>
              <div class="t">Không tìm thấy công việc nào</div>
              <div class="d">Không có tiêu đề nào khớp từ khoá đang tìm.</div>
            </div>
          </c:otherwise>
        </c:choose>
      </div>
    </div>

  </div>
</div>

<script>
(function () {
  'use strict';
  var $ = function (id) { return document.getElementById(id); };
  var body = $('bodyBoard');
  var rows = body ? Array.prototype.slice.call(body.rows) : [];

  /* ── Thống kê: đọc từ chính bảng đã render, không thêm truy vấn ────────── */
  var open = 0, onTime = 0, late = 0, auto = 0;
  rows.forEach(function (r) {
    var s = r.dataset.status;
    if (s === 'PENDING' || s === 'IN_PROGRESS') open++;
    else if (s === 'COMPLETED_ON_TIME') onTime++;
    else if (s === 'COMPLETED_LATE') late++;
    if (r.dataset.type === 'SYSTEM_AUTO') auto++;
  });
  var done = onTime + late;
  $('stOpen').textContent = open;
  $('stDone').textContent = done;
  $('stAuto').textContent = auto;
  $('stDoneSub').textContent = done ? (onTime + ' đúng hạn · ' + late + ' trễ hạn') : 'Chưa có việc nào xong';
  $('stRate').textContent = done ? Math.round(onTime * 100 / done) + '%' : '—';

  /* ── Dải hạn 14 ngày ──────────────────────────────────────────────────
     Gom việc CHƯA xong theo ngày đến hạn. Việc đã quá hạn dồn vào ô hôm nay —
     đó là ngày phải xử lý chúng, không phải ngày đã trôi qua. */
  var strip = $('deadlineStrip');
  if (strip) {
    var DW = ['CN','T2','T3','T4','T5','T6','T7'];
    var today = new Date(); today.setHours(0, 0, 0, 0);
    var buckets = {};
    rows.forEach(function (r) {
      var s = r.dataset.status;
      if (s !== 'PENDING' && s !== 'IN_PROGRESS') return;
      var raw = (r.dataset.due || '').trim();
      if (!raw) return;
      var d = new Date(raw.replace(' ', 'T'));
      if (isNaN(d)) return;
      d.setHours(0, 0, 0, 0);
      var idx = Math.round((d - today) / 86400000);
      if (idx < 0) idx = 0;
      if (idx > 13) return;
      (buckets[idx] = buckets[idx] || []).push(r.dataset.title);
    });

    var html = '';
    for (var i = 0; i < 14; i++) {
      var dd = new Date(today.getTime() + i * 86400000);
      var list = buckets[i] || [];
      var cls = 'dl-d' + (i === 0 ? ' today' : '') + (list.length ? (i <= 2 ? ' hot' : ' has') : '');
      var color = i <= 2 ? '#DC2626' : '#F59E0B';
      var pips = list.slice(0, 4).map(function () {
        return '<span class="pip" style="background:' + color + '"></span>';
      }).join('');
      var tip = list.length ? ' title="' + list.join(' · ').replace(/"/g, '&quot;') + '"' : '';
      html += '<div class="' + cls + '"' + tip + '>' +
        '<span class="dw">' + DW[dd.getDay()] + '</span>' +
        '<span class="dn">' + dd.getDate() + '</span>' +
        '<span class="pips">' + pips + '</span></div>';
    }
    strip.innerHTML = html;
  }

  /* ══ Bảng kanban kéo-thả ═══════════════════════════════════════════════
     Đường đi hợp lệ CHỈ gồm 3 hành động đã có sẵn ở servlet. Không có
     "mở lại việc đã đóng" hay "trả lại việc đã nhận" vì DAO không có hàm nào
     làm việc đó — thà không cho kéo còn hơn dựng một nút gọi API không tồn tại. */
  var MOVES = {
    'PENDING':     { 'IN_PROGRESS':'claim', 'DONE':'complete', 'CANCELLED':'cancel' },
    'IN_PROGRESS': { 'DONE':'complete', 'CANCELLED':'cancel' },
    'DONE':        {},
    'CANCELLED':   {}
  };
  var kanban = $('kanban');
  if (kanban) {
    var CTX = '<%= ctx %>', UID = '${staffUid}', CSRF = '${csrfToken}';

    function colOf(st){ return (st === 'COMPLETED_ON_TIME' || st === 'COMPLETED_LATE') ? 'DONE' : st; }

    function card(r) {
      var el = document.createElement('div');
      var st = colOf(r.dataset.status);
      el.className = 'kb-card pr-' + (r.dataset.pri || 'LOW');
      el.dataset.id = r.dataset.id;
      el.dataset.st = st;
      var open = st === 'PENDING' || st === 'IN_PROGRESS';
      if (open) el.draggable = true;

      var meta = '';
      if (r.dataset.type === 'SYSTEM_AUTO') meta += '<span><svg><use href="#ic-bot"/></svg> Hệ thống</span>';
      if (r.dataset.asg) meta += '<span><svg><use href="#ic-user"/></svg> ' + escHtml(r.dataset.asg) + '</span>';
      else if (open) meta += '<span class="wh-badge mute" style="font-size:10px;padding:2px 7px">Chưa ai nhận</span>';
      if (r.dataset.duedisp) meta += '<span><svg><use href="#ic-clock"/></svg> ' + escHtml(r.dataset.duedisp) + '</span>';

      el.innerHTML = '<div class="t">' + escHtml(r.dataset.title) + '</div>' +
                     (meta ? '<div class="m">' + meta + '</div>' : '');
      return el;
    }
    function escHtml(s){
      return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
        return ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' })[c];
      });
    }

    function fill() {
      kanban.querySelectorAll('.kb-body').forEach(function (b) { b.innerHTML = ''; });
      rows.forEach(function (r) {
        var col = kanban.querySelector('.kb-col[data-st="' + colOf(r.dataset.status) + '"] .kb-body');
        if (col) col.appendChild(card(r));
      });
      kanban.querySelectorAll('.kb-col').forEach(function (c) {
        var n = c.querySelectorAll('.kb-card').length;
        c.querySelector('.kb-col-head .n').textContent = n;
        if (!n) c.querySelector('.kb-body').innerHTML =
          '<div class="empty">Không có việc nào</div>';
      });
    }
    fill();

    var dragEl = null;
    kanban.addEventListener('dragstart', function (e) {
      var c = e.target.closest('.kb-card');
      if (!c || !c.draggable) return;
      dragEl = c;
      c.classList.add('drag');
      kanban.classList.add('dragging');
      var allowed = MOVES[c.dataset.st] || {};
      kanban.querySelectorAll('.kb-col').forEach(function (col) {
        col.classList.toggle('can', !!allowed[col.dataset.st]);
      });
      e.dataTransfer.effectAllowed = 'move';
      try { e.dataTransfer.setData('text/plain', c.dataset.id); } catch (_) {}
    });
    kanban.addEventListener('dragend', function () {
      if (dragEl) dragEl.classList.remove('drag');
      dragEl = null;
      kanban.classList.remove('dragging');
      kanban.querySelectorAll('.kb-col').forEach(function (c) { c.classList.remove('can', 'over'); });
    });
    kanban.addEventListener('dragover', function (e) {
      var col = e.target.closest('.kb-col');
      if (!col || !dragEl || !col.classList.contains('can')) return;
      e.preventDefault();
      e.dataTransfer.dropEffect = 'move';
      col.classList.add('over');
    });
    kanban.addEventListener('dragleave', function (e) {
      var col = e.target.closest('.kb-col');
      if (col) col.classList.remove('over');
    });
    kanban.addEventListener('drop', function (e) {
      var col = e.target.closest('.kb-col');
      if (!col || !dragEl || !col.classList.contains('can')) return;
      e.preventDefault();
      var action = (MOVES[dragEl.dataset.st] || {})[col.dataset.st];
      if (action) move(dragEl, col, action);
    });

    /* Cập nhật lạc quan: thẻ nhảy cột ngay, nếu server từ chối thì trả về chỗ cũ
       kèm lý do — không bắt người dùng ngồi chờ round-trip mới thấy phản hồi. */
    function move(cardEl, col, action) {
      var from = cardEl.parentNode;
      var id = cardEl.dataset.id;
      if (!id) {   // không có id thì đừng gửi request rác lên server
        if (window.whToast) window.whToast('Thẻ thiếu mã công việc — tải lại trang rồi thử lại.', false);
        return;
      }
      cardEl.classList.add('busy');
      cardEl.draggable = false;
      col.querySelector('.kb-body').appendChild(cardEl);
      recount();

      var body = new URLSearchParams();
      body.set('uid', UID); body.set('action', action);
      body.set('taskId', id); body.set('ajax', '1'); body.set('_csrf', CSRF);

      fetch(CTX + '/warehouse-task', {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8' },
        body: body.toString()
      })
        .then(function (r) { return r.json(); })
        .then(function (d) {
          cardEl.classList.remove('busy');
          if (!d.ok) { revert(); if (window.whToast) window.whToast(d.msg, false); return; }
          cardEl.dataset.st = col.dataset.st;
          if (col.dataset.st === 'IN_PROGRESS') cardEl.draggable = true;
          // Đồng bộ lại hàng trong bảng bên dưới để bộ lọc/thống kê không lệch
          var row = rows.filter(function (r) { return r.dataset.id === id; })[0];
          if (row) row.dataset.status = col.dataset.st === 'DONE' ? 'COMPLETED_ON_TIME' : col.dataset.st;
          if (window.whToast) window.whToast(d.msg, true);
          $('kbHint').textContent = 'Tải lại trang để xem bảng bên dưới cập nhật đầy đủ';
        })
        .catch(function () {
          cardEl.classList.remove('busy');
          revert();
          if (window.whToast) window.whToast('Mất kết nối — chưa đổi được trạng thái.', false);
        });

      function revert() {
        from.appendChild(cardEl);
        cardEl.draggable = true;
        recount();
      }
    }
    function recount() {
      kanban.querySelectorAll('.kb-col').forEach(function (c) {
        var n = c.querySelectorAll('.kb-card').length;
        c.querySelector('.kb-col-head .n').textContent = n;
        var empty = c.querySelector('.kb-body .empty');
        if (n && empty) empty.remove();
        if (!n && !empty) c.querySelector('.kb-body').innerHTML = '<div class="empty">Không có việc nào</div>';
      });
    }
  }

  /* ── Tìm kiếm tức thì trên tiêu đề ────────────────────────────────────── */
  var qEl = $('q'), qBox = $('searchBox');
  if (!qEl || !body) return;
  function norm(s){
    return (s || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd');
  }
  function render(){
    var k = norm(qEl.value).trim(), shown = 0;
    rows.forEach(function (tr) {
      var hit = !k || k.split(/\s+/).every(function (w) { return norm(tr.dataset.title).indexOf(w) > -1; });
      tr.hidden = !hit;
      if (hit) shown++;
    });
    $('tblBoard').hidden = shown === 0;
    $('searchEmpty').hidden = shown !== 0;
    qBox.classList.toggle('has-value', qEl.value.length > 0);
    if (window.whFitTables) window.whFitTables();
  }
  var t;
  qEl.addEventListener('input', function () { clearTimeout(t); t = setTimeout(render, 120); });
  qEl.addEventListener('search', render);
  qEl.addEventListener('keydown', function (e) { if (e.key === 'Enter') e.preventDefault(); });
  $('qClear').addEventListener('click', function () { qEl.value = ''; render(); qEl.focus(); });

  document.addEventListener('keydown', function (e) {
    if (e.key === '/' && !/^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement.tagName)) {
      e.preventDefault(); qEl.focus(); qEl.select();
    }
    if (e.key === 'Escape' && document.activeElement === qEl && qEl.value) { qEl.value = ''; render(); }
  });
})();
</script>
</body>
</html>
