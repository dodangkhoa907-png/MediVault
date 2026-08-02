<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%--
  warehouse-shelf.jsp — Quản lý kệ (Warehouse Console), CRUD đầy đủ.

  Trước đây chỉ đọc — sửa/thêm/xoá phải qua Admin (/shelves). Nay Thủ kho tự quản lý được
  ngay tại đây, làm chi tiết hơn bản Admin: thêm/sửa qua modal (không văng trang riêng),
  tìm kiếm tức thì trên trình duyệt, và khi xoá bị chặn thì hiện luôn DANH SÁCH thuốc đang
  gán trên kệ đó thay vì chỉ báo chung chung "còn thuốc".

  Yêu cầu từ servlet: staffAcc, staffUid, shelfRows, shelfCount, totalMedicinesOnShelves,
  emptyShelfCount.
--%>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) request.getAttribute("staffAcc");
    String ctx = request.getContextPath();
    if (acc == null) { response.sendRedirect(ctx + "/warehouse-login"); return; }
    String fullName = acc.getFullName() != null && !acc.getFullName().isEmpty() ? acc.getFullName() : acc.getUsername();
    String initials = fullName.substring(0,1).toUpperCase();
    String uid = (String) request.getAttribute("staffUid");
    String activeNav = "shelves";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Quản lý kệ — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400..800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= ctx %>/css/staff-portal.css">
<link rel="stylesheet" href="<%= ctx %>/css/warehouse-portal.css?v=11">
<style>
a{text-decoration:none;color:inherit}
.sh-name{width:auto;min-width:200px} .sh-type{width:170px} .sh-loc{width:auto;min-width:200px}
.sh-auto{width:120px} .sh-cnt{width:110px} .sh-acts{width:150px}
#tblShelf{min-width:960px}
.sh-tag{display:inline-flex;align-items:center;gap:6px;padding:3px 10px;border-radius:999px;font-size:11.5px;font-weight:750}
.sh-tag.t-retail{background:#EFF6FF;color:#1D4ED8}
.sh-tag.t-storage{background:var(--surface);color:var(--muted)}
.sh-tag.t-machine{background:var(--soft);color:var(--deep)}
.sh-row-acts{display:flex;gap:6px;justify-content:flex-end}
.sh-row-acts .wh-btn-icon{width:32px;height:32px}
.sh-hidden{display:none !important}
#shelfFormModal .wh-modal-box{max-width:480px}
#shelfDetailModal .wh-modal-box{max-width:520px}
.sh-fg{display:flex;flex-direction:column;gap:6px;margin-bottom:14px}
.sh-fg:last-child{margin-bottom:0}
.sh-fg label{font-size:11.5px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.05em}
.sh-fg label span{color:var(--danger)}
.sh-grid2{display:grid;grid-template-columns:1fr 1fr;gap:12px}
.sh-in.bad{border-color:var(--danger) !important;box-shadow:0 0 0 3px rgba(220,38,38,.12)}
.sh-err{font-size:11.5px;color:var(--danger);display:none;margin-top:2px}
.sh-err.on{display:block}
#shelfMachineBox{display:none}
.sh-detail-kv{display:grid;grid-template-columns:1fr 1fr;gap:10px 16px;margin-bottom:16px}
.sh-detail-kv .k{font-size:11px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.05em;margin-bottom:3px}
.sh-detail-kv .v{font-size:13.5px;font-weight:700}
.sh-medlist{border-top:1px solid var(--line);padding-top:12px;margin-top:2px}
.sh-medlist .hd{font-size:11.5px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.05em;margin-bottom:8px}
.sh-medrow{display:flex;justify-content:space-between;gap:10px;padding:7px 0;font-size:13px;border-bottom:1px dashed var(--line)}
.sh-medrow:last-child{border-bottom:none}
.sh-medrow .code{color:var(--muted);font-size:11.5px}
.sh-detail-acts{display:flex;gap:10px;margin-top:18px}
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
    <div class="crumb">Kho hàng</div>
    <div class="right">
      <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc của <%= fullName %>"><%= initials %></a>
    </div>
  </header>

  <div class="wh-shell wh-anim">

    <div class="wh-head">
      <div>
        <h1>Quản lý kệ</h1>
        <p class="sub">Vị trí kệ vật lý và số thuốc đang gán mỗi kệ — thêm/sửa/xoá ngay tại đây.</p>
      </div>
      <div class="wh-head-actions">
        <a class="wh-btn" href="<%= ctx %>/warehouse-inventory">
          <svg><use href="#ic-package"/></svg> Xem tồn kho
        </a>
        <button type="button" class="wh-btn wh-btn-primary" onclick="openShelfForm()">
          <svg><use href="#ic-plus"/></svg> Thêm kệ mới
        </button>
      </div>
    </div>

    <c:if test="${param.msg == 'created'}">
      <div class="wh-note ok" role="status"><svg><use href="#ic-check-circle"/></svg><span>Đã thêm kệ mới.</span></div>
    </c:if>
    <c:if test="${param.msg == 'updated'}">
      <div class="wh-note ok" role="status"><svg><use href="#ic-check-circle"/></svg><span>Đã lưu thay đổi kệ.</span></div>
    </c:if>
    <c:if test="${param.msg == 'deleted'}">
      <div class="wh-note ok" role="status"><svg><use href="#ic-check-circle"/></svg><span>Đã xoá kệ.</span></div>
    </c:if>
    <c:if test="${param.msg == 'name-required'}">
      <div class="wh-note danger" role="alert"><svg><use href="#ic-alert"/></svg><span>Tên kệ không được để trống.</span></div>
    </c:if>
    <c:if test="${param.msg == 'name-dup'}">
      <div class="wh-note danger" role="alert"><svg><use href="#ic-alert"/></svg><span>Đã có kệ khác trùng tên này — đổi tên khác để phân biệt.</span></div>
    </c:if>
    <c:if test="${param.msg == 'has-medicine'}">
      <div class="wh-note danger" role="alert"><svg><use href="#ic-alert"/></svg><span>Không xoá được — kệ này vẫn còn thuốc gán vào. Bấm "Xem chi tiết" trên kệ đó để thấy danh sách cần chuyển đi trước.</span></div>
    </c:if>
    <c:if test="${param.msg == 'error'}">
      <div class="wh-note danger" role="alert"><svg><use href="#ic-alert"/></svg><span>Thao tác thất bại, thử lại sau.</span></div>
    </c:if>

    <!-- ══ KPI tổng quan ══ -->
    <div class="wh-kpis" role="group" aria-label="Tổng quan kệ hàng">
      <div class="wh-kpi k-total">
        <span class="ic"><svg><use href="#ic-package"/></svg></span>
        <span class="body">
          <span class="num">${shelfCount}</span>
          <span class="lbl">Tổng số kệ</span>
          <span class="hint">Đang dùng trong kho</span>
        </span>
      </div>
      <div class="wh-kpi k-low">
        <span class="ic"><svg><use href="#ic-cart"/></svg></span>
        <span class="body">
          <span class="num">${totalMedicinesOnShelves}</span>
          <span class="lbl">Lượt gán thuốc</span>
          <span class="hint">Tổng số thuốc đang có vị trí kệ</span>
        </span>
      </div>
      <div class="wh-kpi k-dead ${emptyShelfCount == 0 ? 'is-zero' : ''}">
        <span class="ic"><svg><use href="#ic-alert"/></svg></span>
        <span class="body">
          <span class="num">${emptyShelfCount}</span>
          <span class="lbl">Kệ đang trống</span>
          <span class="hint">Chưa có thuốc nào gán vào</span>
        </span>
      </div>
    </div>

    <!-- ══ Danh sách kệ ══ -->
    <div class="wh-tablecard wh-sec-gap">
      <div class="wh-card-head">
        <div class="wh-ic"><svg><use href="#ic-package"/></svg></div>
        <h2>Danh sách kệ</h2>
        <div class="wh-search" id="searchBox" style="margin-left:auto">
          <svg class="lead"><use href="#ic-search"/></svg>
          <input type="text" id="shQ" placeholder="Tìm theo tên kệ hoặc vị trí…" autocomplete="off">
          <button type="button" class="clear" id="shQClear" aria-label="Xoá tìm kiếm"><svg><use href="#ic-x"/></svg></button>
        </div>
      </div>
      <div class="wh-tablescroll">
        <c:choose>
          <c:when test="${empty shelfRows}">
            <div class="wh-empty">
              <div class="art"><svg style="width:26px;height:26px"><use href="#ic-package"/></svg></div>
              <div class="t">Chưa có kệ nào được tạo</div>
              <div class="d">Bấm "Thêm kệ mới" ở trên để tạo vị trí kệ đầu tiên.</div>
            </div>
          </c:when>
          <c:otherwise>
            <table class="wh-table" id="tblShelf">
              <thead>
                <tr>
                  <th class="sh-name">Tên kệ</th>
                  <th class="sh-type">Loại</th>
                  <th class="sh-loc">Vị trí / ghi chú</th>
                  <th class="sh-auto">Vận hành</th>
                  <th class="sh-cnt" style="text-align:right">Số thuốc</th>
                  <th class="sh-acts"></th>
                </tr>
              </thead>
              <tbody id="tblShelfBody">
                <c:forEach var="row" items="${shelfRows}">
                  <c:set var="s" value="${row.shelf}"/>
                  <tr data-id="${s.shelfId}"
                      data-name="${fn:toLowerCase(fn:escapeXml(s.shelfName))}"
                      data-loc="${fn:toLowerCase(fn:escapeXml(s.locationNotes))}">
                    <td class="sh-name"><div class="wh-name">${fn:escapeXml(s.shelfName)}</div></td>
                    <td class="sh-type">
                      <c:choose>
                        <c:when test="${s.shelfType == 'RETAIL'}"><span class="sh-tag t-retail">Bán lẻ</span></c:when>
                        <c:when test="${s.shelfType == 'MACHINE'}"><span class="sh-tag t-machine">Máy tự động</span></c:when>
                        <c:otherwise><span class="sh-tag t-storage">Kho lưu trữ</span></c:otherwise>
                      </c:choose>
                    </td>
                    <td class="sh-loc">
                      <c:choose>
                        <c:when test="${not empty s.locationNotes}">${fn:escapeXml(s.locationNotes)}</c:when>
                        <c:otherwise><span style="color:var(--muted)">—</span></c:otherwise>
                      </c:choose>
                    </td>
                    <td class="sh-auto">
                      <c:choose>
                        <c:when test="${s.automated}"><span class="wh-badge ok">Tự động</span></c:when>
                        <c:otherwise><span class="wh-badge mute">Thủ công</span></c:otherwise>
                      </c:choose>
                    </td>
                    <td class="sh-cnt num"><span class="wh-stock">${row.medicineCount}</span></td>
                    <td class="sh-acts">
                      <div class="sh-row-acts">
                        <button type="button" class="wh-btn wh-btn-icon wh-btn-ghost" title="Xem chi tiết" onclick="openShelfDetail(${s.shelfId})">
                          <svg><use href="#ic-eye"/></svg>
                        </button>
                        <button type="button" class="wh-btn wh-btn-icon wh-btn-ghost" title="Sửa" onclick="openShelfForm(${s.shelfId})">
                          <svg><use href="#ic-edit"/></svg>
                        </button>
                      </div>
                    </td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
            <div class="wh-empty sh-hidden" id="shNoMatch">
              <div class="art"><svg style="width:26px;height:26px"><use href="#ic-search"/></svg></div>
              <div class="t">Không tìm thấy kệ nào khớp</div>
              <div class="d">Thử từ khoá khác hoặc xoá ô tìm kiếm.</div>
            </div>
          </c:otherwise>
        </c:choose>
      </div>
    </div>

  </div>
</div>

<!-- ══ Modal Thêm / Sửa kệ ══ -->
<div class="wh-modal" id="shelfFormModal" onclick="if(event.target===this)closeShelfForm()">
  <div class="wh-modal-box" role="dialog" aria-modal="true" aria-labelledby="shFormTitle">
    <div class="wh-modal-head">
      <div class="wh-ic"><svg><use href="#ic-package"/></svg></div>
      <h3 id="shFormTitle">Thêm kệ mới</h3>
      <button type="button" class="wh-btn wh-btn-icon wh-btn-ghost" onclick="closeShelfForm()" aria-label="Đóng">
        <svg><use href="#ic-x"/></svg>
      </button>
    </div>
    <div class="wh-modal-body">
      <form method="post" action="<%= ctx %>/warehouse-shelf" id="shelfForm">
        <input type="hidden" name="_csrf" value="${csrfToken}">
        <input type="hidden" name="action" id="shFormAction" value="create">
        <input type="hidden" name="shelfId" id="shFormId" value="">

        <div class="sh-fg">
          <label for="shFormName">Tên kệ <span>*</span></label>
          <input class="wh-in sh-in" id="shFormName" name="shelfName" required maxlength="100"
                 placeholder="VD: Kệ A1, Quầy thuốc kê toa…">
          <div class="sh-err" id="shErrName"></div>
        </div>

        <div class="sh-fg">
          <label for="shFormType">Loại kệ</label>
          <select class="wh-in sh-in" id="shFormType" name="shelfType" onchange="toggleShelfMachine()">
            <option value="RETAIL">🛒 Quầy bán</option>
            <option value="STORAGE">📦 Kho lưu trữ</option>
            <option value="MACHINE">🤖 Máy bán tự động</option>
          </select>
        </div>

        <div id="shelfMachineBox">
          <div class="sh-grid2">
            <div class="sh-fg">
              <label for="shFormSlot">Mã ngăn máy</label>
              <input class="wh-in sh-in" id="shFormSlot" name="machineSlotCode" maxlength="30" placeholder="VD: A-01">
            </div>
            <div class="sh-fg">
              <label for="shFormMotor">Motor ID</label>
              <input class="wh-in sh-in" id="shFormMotor" name="motorId" maxlength="30" placeholder="VD: M-12">
            </div>
          </div>
        </div>

        <div class="sh-fg">
          <label for="shFormNotes">Ghi chú vị trí</label>
          <textarea class="wh-in sh-in" id="shFormNotes" name="locationNotes" maxlength="255"
                    placeholder="VD: Góc trái phòng, tầng 2, kệ thuốc OTC…"></textarea>
        </div>

        <div class="sh-detail-acts">
          <button type="button" class="wh-btn" style="flex:1" onclick="closeShelfForm()">Huỷ</button>
          <button type="submit" class="wh-btn wh-btn-primary" style="flex:1" id="shFormSubmit">
            <svg><use href="#ic-check"/></svg> Thêm kệ
          </button>
        </div>
      </form>
    </div>
  </div>
</div>

<!-- ══ Modal Xem chi tiết kệ + xoá ══ -->
<div class="wh-modal" id="shelfDetailModal" onclick="if(event.target===this)closeShelfDetail()">
  <div class="wh-modal-box" role="dialog" aria-modal="true" aria-labelledby="shDetailTitle">
    <div class="wh-modal-head">
      <div class="wh-ic"><svg><use href="#ic-package"/></svg></div>
      <h3 id="shDetailTitle">Chi tiết kệ</h3>
      <button type="button" class="wh-btn wh-btn-icon wh-btn-ghost" onclick="closeShelfDetail()" aria-label="Đóng">
        <svg><use href="#ic-x"/></svg>
      </button>
    </div>
    <div class="wh-modal-body" id="shDetailBody">
      <div style="text-align:center;color:var(--muted);padding:20px 0">Đang tải…</div>
    </div>
  </div>
</div>

<!-- ══ Form ẩn dùng để xoá — CSRF do csrf.js tự đính khi submit ══ -->
<form method="post" action="<%= ctx %>/warehouse-shelf" id="shelfDeleteForm" class="sh-hidden">
  <input type="hidden" name="_csrf" value="${csrfToken}">
  <input type="hidden" name="action" value="delete">
  <input type="hidden" name="id" id="shDeleteId" value="">
</form>

<script>
(function () {
  var CTX = '<%= ctx %>';

  /* ── Tìm kiếm tức thì trên trình duyệt ─────────────────────────────────── */
  var qEl = document.getElementById('shQ'), qBox = document.getElementById('searchBox');
  var rows = Array.prototype.slice.call(document.querySelectorAll('#tblShelfBody tr'));
  var noMatch = document.getElementById('shNoMatch');
  function onQuery() {
    var k = qEl.value.trim().toLowerCase();
    qBox.classList.toggle('has-value', !!k);
    var visible = 0;
    rows.forEach(function (r) {
      var hit = !k || r.dataset.name.indexOf(k) !== -1 || r.dataset.loc.indexOf(k) !== -1;
      r.classList.toggle('sh-hidden', !hit);
      if (hit) visible++;
    });
    if (noMatch) noMatch.classList.toggle('sh-hidden', visible !== 0 || rows.length === 0);
    if (window.whFitTables) window.whFitTables();
  }
  if (qEl) {
    var qt;
    qEl.addEventListener('input', function () { clearTimeout(qt); qt = setTimeout(onQuery, 100); });
    document.getElementById('shQClear').addEventListener('click', function () { qEl.value = ''; onQuery(); qEl.focus(); });
  }

  /* ── Modal Thêm/Sửa ─────────────────────────────────────────────────────── */
  var formModal = document.getElementById('shelfFormModal');
  var form = document.getElementById('shelfForm');

  window.toggleShelfMachine = function () {
    var t = document.getElementById('shFormType').value;
    document.getElementById('shelfMachineBox').style.display = (t === 'MACHINE') ? 'block' : 'none';
  };

  function resetForm() {
    form.reset();
    document.getElementById('shFormId').value = '';
    document.getElementById('shFormType').value = 'RETAIL';
    toggleShelfMachine();
    document.getElementById('shFormName').classList.remove('bad');
    document.getElementById('shErrName').classList.remove('on');
  }

  window.openShelfForm = function (id) {
    resetForm();
    if (id) {
      document.getElementById('shFormTitle').textContent = 'Sửa kệ';
      document.getElementById('shFormAction').value = 'update';
      document.getElementById('shFormSubmit').innerHTML = '<svg><use href="#ic-check"/></svg> Lưu thay đổi';
      fetch(CTX + '/warehouse-shelf?action=detail&id=' + id)
        .then(function (r) { return r.json(); })
        .then(function (d) {
          if (!d.ok) { if (window.whToast) window.whToast(d.msg || 'Không tải được dữ liệu kệ.', false); closeShelfForm(); return; }
          document.getElementById('shFormId').value = d.shelf.id;
          document.getElementById('shFormName').value = d.shelf.name || '';
          document.getElementById('shFormType').value = d.shelf.type || 'RETAIL';
          document.getElementById('shFormSlot').value = d.shelf.slotCode || '';
          document.getElementById('shFormMotor').value = d.shelf.motorId || '';
          document.getElementById('shFormNotes').value = d.shelf.notes || '';
          toggleShelfMachine();
        })
        .catch(function () { if (window.whToast) window.whToast('Lỗi kết nối, thử lại.', false); closeShelfForm(); });
    } else {
      document.getElementById('shFormTitle').textContent = 'Thêm kệ mới';
      document.getElementById('shFormAction').value = 'create';
      document.getElementById('shFormSubmit').innerHTML = '<svg><use href="#ic-check"/></svg> Thêm kệ';
    }
    formModal.classList.add('open');
    setTimeout(function () { document.getElementById('shFormName').focus(); }, 60);
  };
  window.closeShelfForm = function () { formModal.classList.remove('open'); };

  form.addEventListener('submit', function (e) {
    var name = document.getElementById('shFormName');
    if (!name.value.trim()) {
      e.preventDefault();
      name.classList.add('bad');
      var err = document.getElementById('shErrName');
      err.textContent = 'Tên kệ không được để trống.';
      err.classList.add('on');
      name.focus();
    }
  });

  /* ── Modal Xem chi tiết + xoá ───────────────────────────────────────────── */
  var detailModal = document.getElementById('shelfDetailModal');
  var detailBody = document.getElementById('shDetailBody');

  function escHtml(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
      return ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' })[c];
    });
  }
  var TYPE_LABEL = { RETAIL: 'Bán lẻ', STORAGE: 'Kho lưu trữ', MACHINE: 'Máy bán tự động' };

  window.openShelfDetail = function (id) {
    detailModal.classList.add('open');
    document.getElementById('shDetailTitle').textContent = 'Đang tải…';
    detailBody.innerHTML = '<div style="text-align:center;color:var(--muted);padding:20px 0">Đang tải…</div>';

    fetch(CTX + '/warehouse-shelf?action=detail&id=' + id)
      .then(function (r) { return r.json(); })
      .then(function (d) {
        if (!d.ok) { detailBody.innerHTML = '<div class="wh-note danger"><svg><use href="#ic-alert"/></svg><span>' + escHtml(d.msg || 'Không tải được dữ liệu.') + '</span></div>'; return; }
        var s = d.shelf, meds = d.medicines || [];
        document.getElementById('shDetailTitle').textContent = s.name;

        var html = '<div class="sh-detail-kv">' +
          '<div><div class="k">Loại kệ</div><div class="v">' + escHtml(TYPE_LABEL[s.type] || s.type) + '</div></div>' +
          '<div><div class="k">Vận hành</div><div class="v">' + (s.automated ? 'Tự động' : 'Thủ công') + '</div></div>';
        if (s.type === 'MACHINE') {
          html += '<div><div class="k">Mã ngăn máy</div><div class="v">' + (s.slotCode ? escHtml(s.slotCode) : '—') + '</div></div>' +
                  '<div><div class="k">Motor ID</div><div class="v">' + (s.motorId ? escHtml(s.motorId) : '—') + '</div></div>';
        }
        html += '<div style="grid-column:1/-1"><div class="k">Ghi chú vị trí</div><div class="v">' + (s.notes ? escHtml(s.notes) : '—') + '</div></div>' +
          '</div>';

        html += '<div class="sh-medlist"><div class="hd">Thuốc đang gán trên kệ này (' + meds.length + ')</div>';
        if (!meds.length) {
          html += '<div style="color:var(--muted);font-size:13px">Kệ đang trống — không có thuốc nào gán vào.</div>';
        } else {
          meds.forEach(function (m) {
            html += '<div class="sh-medrow"><span>' + escHtml(m.name) + ' <span class="code">' + escHtml(m.code) + '</span></span><span>' + escHtml(m.unit) + '</span></div>';
          });
        }
        html += '</div>';

        html += '<div class="sh-detail-acts">' +
          '<button type="button" class="wh-btn" style="flex:1" onclick="closeShelfDetail();openShelfForm(' + s.id + ')"><svg><use href="#ic-edit"/></svg> Sửa kệ</button>';
        if (meds.length === 0) {
          html += '<button type="button" class="wh-btn wh-btn-danger" style="flex:1" onclick="confirmDeleteShelf(' + s.id + ',\'' + escHtml(s.name).replace(/'/g, "\\'") + '\')"><svg><use href="#ic-trash"/></svg> Xoá kệ</button>';
        } else {
          html += '<button type="button" class="wh-btn is-disabled" style="flex:1" disabled title="Còn thuốc gán trên kệ — chuyển hết đi trước khi xoá"><svg><use href="#ic-trash"/></svg> Không thể xoá</button>';
        }
        html += '</div>';

        detailBody.innerHTML = html;
      })
      .catch(function () {
        detailBody.innerHTML = '<div class="wh-note danger"><svg><use href="#ic-alert"/></svg><span>Lỗi kết nối, thử lại.</span></div>';
      });
  };
  window.closeShelfDetail = function () { detailModal.classList.remove('open'); };

  window.confirmDeleteShelf = function (id, name) {
    if (!confirm('Xoá kệ "' + name + '"? Không thể hoàn tác.')) return;
    document.getElementById('shDeleteId').value = id;
    document.getElementById('shelfDeleteForm').submit();
  };

  document.addEventListener('keydown', function (e) {
    if (e.key !== 'Escape') return;
    if (formModal.classList.contains('open')) closeShelfForm();
    else if (detailModal.classList.contains('open')) closeShelfDetail();
  });
})();
</script>
</body>
</html>
