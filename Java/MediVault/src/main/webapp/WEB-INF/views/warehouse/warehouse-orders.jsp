<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%--
  warehouse-orders.jsp — Đơn hàng (Warehouse Console), CHỈ ĐỌC.

  Thủ kho theo dõi trạng thái giao hàng của các PO (Chờ giao / Quá hạn / Đã nhận) và bấm
  thẳng sang Nhập kho khi hàng đã về — không có quyền tạo/duyệt PO (vẫn do Admin qua
  /purchase-orders). Modal "Xem đơn" tái dùng NGUYÊN endpoint action=po-detail đã có sẵn ở
  WarehouseReorderServlet — không thêm API mới, không đụng gì tới Admin.

  Trạng thái DB hiện chỉ có PENDING/COMPLETED (nhận hàng trọn gói 1 lần, chưa hỗ trợ nhận
  từng phần) — "Quá hạn" ở đây là suy ra từ ExpectedDate, không phải 1 status thật riêng.

  Yêu cầu từ servlet: staffAcc, staffUid, poRows, cntPending, cntOverdue, cntCompleted, cntTotal.
--%>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) request.getAttribute("staffAcc");
    String ctx = request.getContextPath();
    if (acc == null) { response.sendRedirect(ctx + "/warehouse-login"); return; }
    String fullName = acc.getFullName() != null && !acc.getFullName().isEmpty() ? acc.getFullName() : acc.getUsername();
    String initials = fullName.substring(0,1).toUpperCase();
    String uid = (String) request.getAttribute("staffUid");
    String activeNav = "orders";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Đơn hàng — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400..800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= ctx %>/css/staff-portal.css">
<link rel="stylesheet" href="<%= ctx %>/css/warehouse-portal.css?v=11">
<style>
a{text-decoration:none;color:inherit}
.po-code{width:130px} .po-sup{width:auto;min-width:180px} .po-created{width:130px}
.po-exp{width:130px} .po-status{width:130px} .po-ord{width:90px} .po-rcv{width:90px}
.po-prog{width:140px} .po-act{width:170px}
#tblOrders{min-width:1180px}
.po-filters{display:flex;gap:10px;flex-wrap:wrap;align-items:center;padding:14px 22px;border-bottom:1px solid var(--line)}
.po-filters .wh-in{height:38px;font-size:12.5px}
.po-filters .grp{display:flex;flex-direction:column;gap:3px}
.po-filters .grp label{font-size:10.5px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.05em}
.po-progtext{font-size:11px;color:var(--muted);margin-top:3px;font-variant-numeric:tabular-nums}
.po-row-acts{display:flex;gap:6px;justify-content:flex-end;flex-wrap:wrap}
.po-row-acts .wh-btn{height:30px;padding:0 10px;font-size:11.5px}
.po-kpi-click{cursor:pointer}
.po-kpi-click.is-active{box-shadow:0 0 0 2.5px var(--kpi-c) inset}
@media print {
  body.wh-printing-po .sidebar, body.wh-printing-po .wh-topbar, body.wh-printing-po .wh-head,
  body.wh-printing-po .wh-kpis, body.wh-printing-po .wh-tablecard, body.wh-printing-po .po-filters { display:none !important; }
  body.wh-printing-po #poModal { position:static !important; display:block !important; padding:0; background:none; }
  body.wh-printing-po #poModal .wh-modal-box { max-width:none !important; box-shadow:none !important; }
}
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
    <nav class="tb-nav">
      <a href="<%= ctx %>/warehouse-import">Nhập kho</a>
      <a class="on" href="<%= ctx %>/warehouse-orders">Đơn hàng</a>
      <a href="<%= ctx %>/warehouse-reorder">Gợi ý đặt hàng</a>
    </nav>
    <div class="right">
      <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc của <%= fullName %>"><%= initials %></a>
    </div>
  </header>

  <div class="wh-shell wh-anim">

    <div class="wh-head">
      <div>
        <h1>Đơn hàng</h1>
        <p class="sub">Quản lý các đơn đặt hàng, theo dõi trạng thái giao hàng và chuẩn bị nhập kho.</p>
      </div>
      <div class="wh-head-actions">
        <a class="wh-btn" href="<%= ctx %>/warehouse-import">
          <svg><use href="#ic-truck"/></svg> Nhập kho
        </a>
        <button type="button" class="wh-btn wh-btn-icon" id="btnRefresh" title="Làm mới dữ liệu" aria-label="Làm mới dữ liệu">
          <svg><use href="#ic-refresh"/></svg>
        </button>
      </div>
    </div>

    <!-- ══ KPI tổng quan — bấm thẻ để lọc nhanh theo trạng thái ══ -->
    <div class="wh-kpis" role="group" aria-label="Tổng quan đơn hàng">
      <div class="wh-kpi k-low po-kpi-click" data-bucket="PENDING" onclick="setBucketFilter('PENDING')">
        <span class="ic"><svg><use href="#ic-clock"/></svg></span>
        <span class="body">
          <span class="num">${cntPending}</span>
          <span class="lbl">Chờ giao</span>
          <span class="hint">Đơn PENDING, chưa quá hạn</span>
        </span>
      </div>
      <div class="wh-kpi k-dead po-kpi-click ${cntOverdue == 0 ? 'is-zero' : ''}" data-bucket="OVERDUE" onclick="setBucketFilter('OVERDUE')">
        <span class="ic"><svg><use href="#ic-alert"/></svg></span>
        <span class="body">
          <span class="num">${cntOverdue}</span>
          <span class="lbl">Quá hạn</span>
          <span class="hint">Đã qua ngày giao dự kiến</span>
        </span>
      </div>
      <div class="wh-kpi k-total po-kpi-click" data-bucket="COMPLETED" onclick="setBucketFilter('COMPLETED')">
        <span class="ic"><svg><use href="#ic-check-circle"/></svg></span>
        <span class="body">
          <span class="num">${cntCompleted}</span>
          <span class="lbl">Đã nhận</span>
          <span class="hint">Đã nhập kho xong</span>
        </span>
      </div>
      <div class="wh-kpi k-light po-kpi-click" data-bucket="" onclick="setBucketFilter('')">
        <span class="ic"><svg><use href="#ic-package"/></svg></span>
        <span class="body">
          <span class="num">${cntTotal}</span>
          <span class="lbl">Tổng đơn</span>
          <span class="hint">Tất cả đơn đặt hàng</span>
        </span>
      </div>
    </div>

    <!-- ══ Danh sách đơn hàng ══ -->
    <div class="wh-tablecard wh-sec-gap">
      <div class="wh-card-head">
        <div class="wh-ic"><svg><use href="#ic-package"/></svg></div>
        <h2>Danh sách đơn hàng</h2>
        <div class="wh-search" id="searchBox" style="margin-left:auto">
          <svg class="lead"><use href="#ic-search"/></svg>
          <input type="text" id="poQ" placeholder="Tìm theo mã đơn hoặc nhà cung cấp…" autocomplete="off">
          <button type="button" class="clear" id="poQClear" aria-label="Xoá tìm kiếm"><svg><use href="#ic-x"/></svg></button>
        </div>
      </div>

      <div class="po-filters">
        <div class="grp">
          <label for="poFSupplier">Nhà cung cấp</label>
          <select class="wh-in" id="poFSupplier"><option value="">Tất cả NCC</option></select>
        </div>
        <div class="grp">
          <label for="poFStatus">Trạng thái</label>
          <select class="wh-in" id="poFStatus">
            <option value="">Tất cả trạng thái</option>
            <option value="PENDING">Chờ giao</option>
            <option value="OVERDUE">Quá hạn</option>
            <option value="COMPLETED">Đã nhận</option>
          </select>
        </div>
        <div class="grp">
          <label for="poFFrom">Ngày tạo từ</label>
          <input type="date" class="wh-in" id="poFFrom">
        </div>
        <div class="grp">
          <label for="poFTo">Đến ngày</label>
          <input type="date" class="wh-in" id="poFTo">
        </div>
        <div class="grp" style="justify-content:flex-end">
          <label>&nbsp;</label>
          <button type="button" class="wh-btn wh-btn-ghost" onclick="clearPoFilters()">
            <svg><use href="#ic-x"/></svg> Xoá lọc
          </button>
        </div>
      </div>

      <div class="wh-tablescroll">
        <c:choose>
          <c:when test="${empty poRows}">
            <div class="wh-empty">
              <div class="art"><svg style="width:26px;height:26px"><use href="#ic-package"/></svg></div>
              <div class="t">Chưa có đơn hàng nào</div>
              <div class="d">Đơn đặt hàng do Admin tạo hoặc hệ thống tự đề xuất sẽ xuất hiện ở đây.</div>
            </div>
          </c:when>
          <c:otherwise>
            <table class="wh-table" id="tblOrders">
              <thead>
                <tr>
                  <th class="po-code">Mã đơn</th>
                  <th class="po-sup">Nhà cung cấp</th>
                  <th class="po-created">Ngày tạo</th>
                  <th class="po-exp">Ngày giao dự kiến</th>
                  <th class="po-status">Trạng thái</th>
                  <th class="po-ord" style="text-align:right">SL đặt</th>
                  <th class="po-rcv" style="text-align:right">SL đã nhận</th>
                  <th class="po-prog">Tiến độ</th>
                  <th class="po-act"></th>
                </tr>
              </thead>
              <tbody id="tblOrdersBody">
                <c:forEach var="row" items="${poRows}">
                  <c:set var="po" value="${row.po}"/>
                  <c:choose>
                    <c:when test="${po.status == 'COMPLETED'}"><c:set var="bucket" value="COMPLETED"/></c:when>
                    <c:when test="${row.overdue}"><c:set var="bucket" value="OVERDUE"/></c:when>
                    <c:otherwise><c:set var="bucket" value="PENDING"/></c:otherwise>
                  </c:choose>
                  <tr data-bucket="${bucket}"
                      data-supplier="${fn:toLowerCase(fn:escapeXml(row.supplierName))}"
                      data-code="${fn:toLowerCase(fn:escapeXml(po.poCode))}"
                      data-created="${fn:substring(po.orderDate,0,10)}">
                    <td class="po-code"><span class="wh-code">${fn:escapeXml(po.poCode)}</span></td>
                    <td class="po-sup"><div class="wh-name" title="${fn:escapeXml(row.supplierName)}">${fn:escapeXml(row.supplierName)}</div></td>
                    <td class="po-created">${fn:substring(po.orderDate,8,10)}/${fn:substring(po.orderDate,5,7)}/${fn:substring(po.orderDate,0,4)}</td>
                    <td class="po-exp">
                      <c:choose>
                        <c:when test="${not empty po.expectedDate}">${fn:substring(po.expectedDate,8,10)}/${fn:substring(po.expectedDate,5,7)}/${fn:substring(po.expectedDate,0,4)}</c:when>
                        <c:otherwise><span style="color:var(--muted)">—</span></c:otherwise>
                      </c:choose>
                    </td>
                    <td class="po-status">
                      <c:choose>
                        <c:when test="${bucket == 'COMPLETED'}"><span class="wh-badge ok">Đã nhận</span></c:when>
                        <c:when test="${bucket == 'OVERDUE'}"><span class="wh-badge out">Quá hạn</span></c:when>
                        <c:otherwise><span class="wh-badge low">Chờ giao</span></c:otherwise>
                      </c:choose>
                    </td>
                    <td class="po-ord num">${row.orderedQty}</td>
                    <td class="po-rcv num">${row.receivedQty}</td>
                    <td class="po-prog">
                      <div class="wh-progress"><i style="width:${row.progressPct}%"></i></div>
                      <div class="po-progtext">${row.progressPct}%</div>
                    </td>
                    <td class="po-act">
                      <div class="po-row-acts">
                        <button type="button" class="wh-btn wh-btn-ghost" onclick="return openPoModal(${po.poId})">
                          <svg><use href="#ic-eye"/></svg> Xem
                        </button>
                        <c:if test="${bucket != 'COMPLETED'}">
                          <a class="wh-btn wh-btn-primary" href="<%= ctx %>/warehouse-import">
                            <svg><use href="#ic-truck"/></svg> Nhận hàng
                          </a>
                        </c:if>
                      </div>
                    </td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
            <div class="wh-empty" id="poNoMatch" style="display:none">
              <div class="art"><svg style="width:26px;height:26px"><use href="#ic-search"/></svg></div>
              <div class="t">Không tìm thấy đơn nào khớp</div>
              <div class="d">Thử đổi bộ lọc hoặc xoá từ khoá tìm kiếm.</div>
            </div>
          </c:otherwise>
        </c:choose>
      </div>
    </div>

  </div>
</div>

<!-- ══ Modal "Xem đơn" — tái dùng NGUYÊN endpoint action=po-detail đã có ở
     WarehouseReorderServlet (dùng cho trang Gợi ý đặt hàng), thêm nút "Nhận hàng"/"In phiếu". ══ -->
<div class="wh-modal" id="poModal" onclick="if(event.target===this)closePoModal()">
  <div class="wh-modal-box" role="dialog" aria-modal="true" aria-labelledby="poModalTitle" style="max-width:520px">
    <div class="wh-modal-head">
      <div class="wh-ic"><svg><use href="#ic-trend-up"/></svg></div>
      <h3 id="poModalTitle">Chi tiết đơn hàng</h3>
      <button type="button" class="wh-btn wh-btn-icon wh-btn-ghost" onclick="closePoModal()" aria-label="Đóng">
        <svg><use href="#ic-x"/></svg>
      </button>
    </div>
    <div class="wh-modal-body" id="poModalBody">
      <div style="text-align:center;color:var(--muted);padding:20px 0">Đang tải…</div>
    </div>
  </div>
</div>

<script>
var CTX = '<%= ctx %>';

function openPoModal(poId) {
  var modal = document.getElementById('poModal');
  var body  = document.getElementById('poModalBody');
  modal.classList.add('open');
  body.innerHTML = '<div style="text-align:center;color:var(--muted);padding:20px 0">Đang tải…</div>';
  fetch(CTX + '/warehouse-reorder?action=po-detail&id=' + poId)
    .then(function (r) { return r.json(); })
    .then(function (d) {
      if (!d.ok) { body.innerHTML = '<div style="color:var(--danger);text-align:center;padding:16px 0">Không tải được đơn này.</div>'; return; }
      var fmtV = function (n) { return new Intl.NumberFormat('vi-VN').format(n) + 'đ'; };
      var rows = d.lines.map(function (l) {
        return '<div style="display:flex;justify-content:space-between;align-items:center;background:var(--surface);border-radius:11px;padding:10px 12px;margin-bottom:7px">'
          + '<div><div style="font-weight:750;font-size:13px">' + l.medicineName + '</div>'
          + '<div style="font-size:11px;color:var(--muted)">SL: ' + l.quantity + ' × ' + fmtV(l.importPrice) + '</div></div>'
          + '<b style="font-size:12.5px">' + fmtV(l.quantity * l.importPrice) + '</b></div>';
      }).join('');
      body.innerHTML =
          '<div style="display:flex;justify-content:space-between;font-size:13px;border-bottom:1px solid var(--line);padding-bottom:10px;margin-bottom:12px">'
        + '<div><b style="font-size:15px">PO #' + d.poId + '</b>'
        + '<div style="color:var(--muted);font-size:11.5px;margin-top:2px">' + d.orderDate + ' · ' + d.supplierName + '</div></div>'
        + '<span class="wh-badge ' + (d.status === 'COMPLETED' ? 'ok' : 'low') + '">' + (d.status === 'COMPLETED' ? 'Đã nhận' : 'Chờ giao') + '</span></div>'
        + rows
        + '<div style="display:flex;justify-content:space-between;align-items:center;background:var(--soft);border-radius:13px;padding:12px 14px;margin-top:12px">'
        + '<span style="font-size:12px;font-weight:750;color:var(--deep)">Tổng tiền</span>'
        + '<b style="font-size:18px">' + fmtV(d.totalValue) + '</b></div>'
        + '<div style="display:flex;gap:10px;margin-top:16px">'
        + '<button type="button" class="wh-btn" style="flex:1" onclick="printPo()"><svg><use href="#ic-printer"/></svg> In phiếu</button>'
        + (d.status !== 'COMPLETED'
            ? '<a class="wh-btn wh-btn-primary" style="flex:1" href="' + CTX + '/warehouse-import"><svg><use href="#ic-truck"/></svg> Nhận hàng</a>'
            : '')
        + '</div>';
    })
    .catch(function () { body.innerHTML = '<div style="color:var(--danger);text-align:center;padding:16px 0">Lỗi kết nối.</div>'; });
  return false;
}
function closePoModal() { document.getElementById('poModal').classList.remove('open'); }
function printPo() {
  document.body.classList.add('wh-printing-po');
  window.print();
}
window.addEventListener('afterprint', function () { document.body.classList.remove('wh-printing-po'); });
document.addEventListener('keydown', function (e) {
  if (e.key === 'Escape' && document.getElementById('poModal').classList.contains('open')) closePoModal();
});

(function () {
  'use strict';

  var rows = Array.prototype.slice.call(document.querySelectorAll('#tblOrdersBody tr'));
  var noMatch = document.getElementById('poNoMatch');
  var qEl = document.getElementById('poQ'), qBox = document.getElementById('searchBox');
  var fSupplier = document.getElementById('poFSupplier'), fStatus = document.getElementById('poFStatus');
  var fFrom = document.getElementById('poFFrom'), fTo = document.getElementById('poFTo');

  // Đổ danh sách NCC duy nhất từ chính các dòng đã render — không round-trip thêm.
  var suppliers = [];
  rows.forEach(function (r) {
    var name = r.cells[1].textContent.trim();
    if (name && suppliers.indexOf(name) === -1) suppliers.push(name);
  });
  suppliers.sort(function (a, b) { return a.localeCompare(b, 'vi'); });
  suppliers.forEach(function (name) {
    var opt = document.createElement('option');
    opt.value = name.toLowerCase();
    opt.textContent = name;
    fSupplier.appendChild(opt);
  });

  function applyFilters() {
    var k = qEl.value.trim().toLowerCase();
    var sup = fSupplier.value, st = fStatus.value, from = fFrom.value, to = fTo.value;
    qBox.classList.toggle('has-value', !!k);
    var visible = 0;
    rows.forEach(function (r) {
      var hit = true;
      if (k && r.dataset.code.indexOf(k) === -1 && r.dataset.supplier.indexOf(k) === -1) hit = false;
      if (sup && r.dataset.supplier !== sup) hit = false;
      if (st && r.dataset.bucket !== st) hit = false;
      if (from && r.dataset.created < from) hit = false;
      if (to && r.dataset.created > to) hit = false;
      r.hidden = !hit;
      if (hit) visible++;
    });
    if (noMatch) noMatch.style.display = (visible === 0 && rows.length > 0) ? '' : 'none';
    document.querySelectorAll('.po-kpi-click').forEach(function (k2) {
      k2.classList.toggle('is-active', k2.dataset.bucket === st);
    });
    if (window.whFitTables) window.whFitTables();
  }

  window.setBucketFilter = function (bucket) {
    fStatus.value = bucket;
    applyFilters();
  };
  window.clearPoFilters = function () {
    qEl.value = ''; fSupplier.value = ''; fStatus.value = ''; fFrom.value = ''; fTo.value = '';
    applyFilters();
  };

  var qt;
  qEl.addEventListener('input', function () { clearTimeout(qt); qt = setTimeout(applyFilters, 100); });
  document.getElementById('poQClear').addEventListener('click', function () { qEl.value = ''; applyFilters(); qEl.focus(); });
  [fSupplier, fStatus, fFrom, fTo].forEach(function (el) { el.addEventListener('change', applyFilters); });

  var btnRefresh = document.getElementById('btnRefresh');
  btnRefresh.addEventListener('click', function () {
    btnRefresh.classList.add('is-busy'); btnRefresh.disabled = true;
    location.reload();
  });
})();
</script>
</body>
</html>
