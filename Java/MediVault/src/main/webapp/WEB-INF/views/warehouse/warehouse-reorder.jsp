<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%--
  warehouse-reorder.jsp — Gợi ý đặt hàng & Cảnh báo hạn dùng (Warehouse Console)

  Port sang design system `wh-*` (2026-08-02), kèm 1 thay đổi bố cục có chủ đích:

  • BỎ lưới 3 bảng cạnh nhau (Cận hạn nhẹ / Hạn chế xuất / Đã cách ly). Mỗi bảng
    chỉ còn ~1/3 bề ngang nên 4 cột đều phải cuộn ngang trong một khung tí hon —
    thực tế là không đọc được. Ba tầng đó nay là 3 lát cắt của MỘT bảng chiếm
    trọn bề ngang, đúng ngôn ngữ đã dùng ở trang Tồn kho.
  • 4 thẻ KPI = 1 phiếu chờ duyệt + 3 tầng cảnh báo; bấm thẻ là đổi lát cắt.
    Số trên thẻ chính là số dòng bảng sẽ hiện.

  Yêu cầu từ servlet: staffAcc, staffUid, pendingSuggestions,
  tierLight, tierRestricted, tierQuarantined.
--%>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) request.getAttribute("staffAcc");
    String ctx = request.getContextPath();
    if (acc == null) { response.sendRedirect(ctx + "/warehouse-login"); return; }
    String fullName = acc.getFullName() != null && !acc.getFullName().isEmpty() ? acc.getFullName() : acc.getUsername();
    String initials = fullName.substring(0,1).toUpperCase();
    String uid = (String) request.getAttribute("staffUid");
    String activeNav = "reorder";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Gợi ý đặt hàng &amp; Cảnh báo hạn dùng — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400..800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= ctx %>/css/staff-portal.css">
<link rel="stylesheet" href="<%= ctx %>/css/warehouse-portal.css?v=11">
<style>
a{text-decoration:none;color:inherit}

/* Bảng phiếu đề xuất */
.p-med{width:auto;min-width:190px} .p-sup{width:auto;min-width:190px}
.p-qty{width:110px} .p-val{width:150px} .p-date{width:150px} .p-act{width:150px}
#tblPending{min-width:900px}

/* Bảng 3 tầng cảnh báo hạn dùng */
.b-med{width:auto;min-width:200px} .b-lot{width:150px} .b-qty{width:110px}
.b-exp{width:170px} .b-tier{width:150px}
#tblTier{min-width:820px}

.link-go{color:var(--main);font-weight:750;display:inline-flex;align-items:center;gap:5px}
.link-go:hover{text-decoration:underline}
.link-go svg{width:14px;height:14px}

.exp-wrap{display:flex;flex-direction:column;gap:2px}
.exp-d{font-weight:700;font-variant-numeric:tabular-nums;color:#0F172A}
.exp-chip{font-size:11px;font-weight:750;color:var(--muted)}
.exp-chip.t-light{color:#1D4ED8} .exp-chip.t-restricted{color:var(--gold)} .exp-chip.t-quarantined{color:var(--danger)}
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
      <a href="<%= ctx %>/warehouse-inventory">Tồn kho</a>
      <a href="<%= ctx %>/warehouse-stock-movement">Điều chỉnh</a>
      <a class="on" href="<%= ctx %>/warehouse-reorder">Gợi ý đặt hàng</a>
      <a href="<%= ctx %>/warehouse-recall">Thu hồi</a>
    </nav>
    <div class="right">
      <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc của <%= fullName %>"><%= initials %></a>
    </div>
  </header>

  <div class="wh-shell wh-anim">

    <div class="wh-head">
      <div>
        <h1>Gợi ý đặt hàng &amp; Cảnh báo hạn dùng</h1>
        <p class="sub">Hệ thống tính điểm đặt hàng lại (ROP) và tự cách ly lô cận hạn mỗi giờ. Phiếu đề xuất bên dưới chờ Admin duyệt.</p>
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

    <!-- ══ KPI — thẻ đầu là phiếu chờ duyệt, 3 thẻ sau lọc bảng cảnh báo ══ -->
    <div class="wh-kpis" role="group" aria-label="Tổng quan đặt hàng và hạn dùng">
      <a class="wh-kpi k-total" href="#pending">
        <span class="ic"><svg><use href="#ic-trend-up"/></svg></span>
        <span class="body">
          <span class="num">${pendingSuggestions.size()}</span>
          <span class="lbl">Phiếu đề xuất chờ duyệt</span>
          <span class="hint">Tồn đã chạm điểm đặt hàng lại</span>
        </span>
      </a>
      <button type="button" class="wh-kpi k-light" data-tier="light" aria-pressed="true">
        <span class="ic"><svg><use href="#ic-clock"/></svg></span>
        <span class="body">
          <span class="num">${tierLight.size()}</span>
          <span class="lbl">Cận hạn nhẹ</span>
          <span class="hint">Còn 91–180 ngày — theo dõi</span>
        </span>
      </button>
      <button type="button" class="wh-kpi k-low" data-tier="restricted" aria-pressed="false">
        <span class="ic"><svg><use href="#ic-alert"/></svg></span>
        <span class="body">
          <span class="num">${tierRestricted.size()}</span>
          <span class="lbl">Hạn chế xuất số lượng lớn</span>
          <span class="hint">Còn 31–90 ngày — ưu tiên bán</span>
        </span>
      </button>
      <button type="button" class="wh-kpi k-dead" data-tier="quarantined" aria-pressed="false">
        <span class="ic"><svg><use href="#ic-shield-off"/></svg></span>
        <span class="body">
          <span class="num">${tierQuarantined.size()}</span>
          <span class="lbl">Đã cách ly</span>
          <span class="hint">Còn ≤ 30 ngày — ngừng bán</span>
        </span>
      </button>
    </div>

    <!-- ══ Phiếu đề xuất đặt hàng ══ -->
    <div class="wh-tablecard wh-sec-gap" id="pending">
      <div class="wh-card-head">
        <div class="wh-ic"><svg><use href="#ic-trend-up"/></svg></div>
        <h2>Phiếu đề xuất đặt hàng <small>chờ Admin duyệt</small></h2>
      </div>
      <div class="wh-tablescroll">
        <c:choose>
          <c:when test="${empty pendingSuggestions}">
            <div class="wh-empty good">
              <div class="art">🎉</div>
              <div class="t">Không có phiếu nào chờ duyệt</div>
              <div class="d">Mọi mặt hàng đều đang trên điểm đặt hàng lại. Hệ thống sẽ tự tạo phiếu khi tồn chạm ngưỡng.</div>
            </div>
          </c:when>
          <c:otherwise>
            <table class="wh-table" id="tblPending">
              <thead>
                <tr>
                  <th class="p-med">Thuốc</th>
                  <th class="p-sup">Nhà cung cấp</th>
                  <th class="p-qty" style="text-align:right">SL đề xuất</th>
                  <th class="p-val" style="text-align:right">Tổng tiền ước tính</th>
                  <th class="p-date">Ngày đề xuất</th>
                  <th class="p-act">Chi tiết</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="row" items="${pendingSuggestions}">
                  <tr>
                    <td class="p-med"><div class="wh-name" title="${fn:escapeXml(row.medicineName)}">${row.medicineName}</div></td>
                    <td class="p-sup" title="${fn:escapeXml(row.supplierName)}">${row.supplierName}</td>
                    <td class="p-qty num"><span class="wh-stock">${row.quantity}</span></td>
                    <td class="p-val wh-price"><fmt:formatNumber value="${row.totalValue}" type="number" maxFractionDigits="0"/>đ</td>
                    <td class="p-date"><fmt:formatDate value="${row.orderDate}" pattern="dd/MM/yyyy HH:mm"/></td>
                    <td class="p-act">
                      <a class="link-go" href="#" onclick="return openPoModal(${row.poId})">
                        Xem đơn <svg><use href="#ic-arrow-right"/></svg>
                      </a>
                    </td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </c:otherwise>
        </c:choose>
      </div>
    </div>

    <!-- ══ Cảnh báo hạn dùng — 3 tầng gộp vào 1 bảng ══ -->
    <div class="wh-toolbar" id="toolbar">
      <div class="wh-seg" role="group" aria-label="Tầng cảnh báo hạn dùng">
        <button type="button" data-tier="light"       aria-pressed="true">Cận hạn nhẹ <span class="cnt">${tierLight.size()}</span></button>
        <button type="button" data-tier="restricted"  aria-pressed="false" class="s-low">Hạn chế xuất <span class="cnt">${tierRestricted.size()}</span></button>
        <button type="button" data-tier="quarantined" aria-pressed="false" class="s-dead">Đã cách ly <span class="cnt">${tierQuarantined.size()}</span></button>
      </div>
      <div class="wh-toolbar-right">
        <div class="wh-search" id="searchBox">
          <svg class="lead"><use href="#ic-search"/></svg>
          <input type="search" id="q" autocomplete="off" placeholder="Tìm thuốc hoặc số lô…" aria-label="Tìm trong bảng cảnh báo">
          <button type="button" class="clear" id="qClear" aria-label="Xoá từ khoá"><svg><use href="#ic-x"/></svg></button>
        </div>
        <button type="button" class="wh-btn" id="btnExport">
          <svg><use href="#ic-download"/></svg> Xuất Excel
        </button>
      </div>
    </div>

    <div class="wh-tablecard">
      <div class="wh-tablescroll">
        <table class="wh-table" id="tblTier">
          <thead>
            <tr>
              <th class="b-med">Thuốc</th>
              <th class="b-lot">Số lô</th>
              <th class="b-qty" style="text-align:right">Còn tồn</th>
              <th class="b-exp">Hạn dùng</th>
              <th class="b-tier">Xử lý</th>
            </tr>
          </thead>
          <tbody id="bodyTier">
            <c:forEach var="b" items="${tierLight}">
              <tr data-tier="light" data-name="${fn:escapeXml(b.medicineName)}" data-lot="${fn:escapeXml(b.batchNumber)}"
                  data-qty="${b.currentQuantity}" data-exp="${b.expiryDate}">
                <td class="b-med"><div class="wh-name" title="${fn:escapeXml(b.medicineName)}">${b.medicineName}</div></td>
                <td class="b-lot"><span class="wh-code">${b.batchNumber}</span></td>
                <td class="b-qty num"><span class="wh-stock">${b.currentQuantity}</span></td>
                <td class="b-exp">
                  <div class="exp-wrap">
                    <span class="exp-d">${fn:substring(b.expiryDate,8,10)}/${fn:substring(b.expiryDate,5,7)}/${fn:substring(b.expiryDate,0,4)}</span>
                    <span class="exp-chip t-light"></span>
                  </div>
                </td>
                <td class="b-tier"><span class="wh-badge mute">Theo dõi</span></td>
              </tr>
            </c:forEach>
            <c:forEach var="b" items="${tierRestricted}">
              <tr data-tier="restricted" data-name="${fn:escapeXml(b.medicineName)}" data-lot="${fn:escapeXml(b.batchNumber)}"
                  data-qty="${b.currentQuantity}" data-exp="${b.expiryDate}">
                <td class="b-med"><div class="wh-name" title="${fn:escapeXml(b.medicineName)}">${b.medicineName}</div></td>
                <td class="b-lot"><span class="wh-code">${b.batchNumber}</span></td>
                <td class="b-qty num"><span class="wh-stock">${b.currentQuantity}</span></td>
                <td class="b-exp">
                  <div class="exp-wrap">
                    <span class="exp-d">${fn:substring(b.expiryDate,8,10)}/${fn:substring(b.expiryDate,5,7)}/${fn:substring(b.expiryDate,0,4)}</span>
                    <span class="exp-chip t-restricted"></span>
                  </div>
                </td>
                <td class="b-tier"><span class="wh-badge low">Ưu tiên bán</span></td>
              </tr>
            </c:forEach>
            <c:forEach var="b" items="${tierQuarantined}">
              <tr data-tier="quarantined" data-name="${fn:escapeXml(b.medicineName)}" data-lot="${fn:escapeXml(b.batchNumber)}"
                  data-qty="${b.currentQuantity}" data-exp="${b.expiryDate}">
                <td class="b-med"><div class="wh-name" title="${fn:escapeXml(b.medicineName)}">${b.medicineName}</div></td>
                <td class="b-lot"><span class="wh-code">${b.batchNumber}</span></td>
                <td class="b-qty num"><span class="wh-stock is-out">${b.currentQuantity}</span></td>
                <td class="b-exp">
                  <div class="exp-wrap">
                    <span class="exp-d">${fn:substring(b.expiryDate,8,10)}/${fn:substring(b.expiryDate,5,7)}/${fn:substring(b.expiryDate,0,4)}</span>
                    <span class="exp-chip t-quarantined"></span>
                  </div>
                </td>
                <td class="b-tier"><span class="wh-badge out">Ngừng bán</span></td>
              </tr>
            </c:forEach>
          </tbody>
        </table>

        <div class="wh-empty" id="emptyState" hidden>
          <div class="art" id="emptyArt">✅</div>
          <div class="t" id="emptyTitle">Không có lô nào</div>
          <div class="d" id="emptyDesc"></div>
        </div>
      </div>

      <div class="wh-pager" id="pager">
        <div class="info" id="pagerInfo"></div>
      </div>
    </div>

  </div>
</div>

<!-- ══ Modal "Xem đơn" — thay cho việc điều hướng sang /purchase-orders của Admin.
     Thủ kho chỉ xem, không sửa được PO (chỉ Admin duyệt/sửa) nên modal đủ, không cần cả
     trang riêng. Ở nguyên trong Warehouse Console, không đổi hẳn giao diện giữa chừng. ══ -->
<div class="wh-modal" id="poModal" onclick="if(event.target===this)closePoModal()">
  <div class="wh-modal-box" role="dialog" aria-modal="true" aria-labelledby="poModalTitle" style="max-width:520px">
    <div class="wh-modal-head">
      <div class="wh-ic"><svg><use href="#ic-trend-up"/></svg></div>
      <h3 id="poModalTitle">Chi tiết đơn đề xuất</h3>
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
function openPoModal(poId) {
  var modal = document.getElementById('poModal');
  var body  = document.getElementById('poModalBody');
  modal.classList.add('open');
  body.innerHTML = '<div style="text-align:center;color:var(--muted);padding:20px 0">Đang tải…</div>';
  fetch('<%= ctx %>/warehouse-reorder?action=po-detail&id=' + poId)
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
        + '<span class="wh-badge ' + (d.status === 'COMPLETED' ? 'ok' : 'low') + '">' + (d.status === 'COMPLETED' ? 'Đã nhập kho' : 'Chờ hàng về') + '</span></div>'
        + rows
        + '<div style="display:flex;justify-content:space-between;align-items:center;background:var(--soft);border-radius:13px;padding:12px 14px;margin-top:12px">'
        + '<span style="font-size:12px;font-weight:750;color:var(--deep)">Tổng tiền</span>'
        + '<b style="font-size:18px">' + fmtV(d.totalValue) + '</b></div>';
    })
    .catch(function () { body.innerHTML = '<div style="color:var(--danger);text-align:center;padding:16px 0">Lỗi kết nối.</div>'; });
  return false;
}
function closePoModal() { document.getElementById('poModal').classList.remove('open'); }
</script>

<script>
(function () {
  'use strict';
  var rows = Array.prototype.slice.call(document.getElementById('bodyTier').rows);
  var body = document.getElementById('bodyTier');
  var tier = 'light', q = '';

  var MS = 86400000, today = new Date(); today.setHours(0,0,0,0);
  rows.forEach(function (tr) {
    var chip = tr.querySelector('.exp-chip');
    if (!chip || !tr.dataset.exp) return;
    var d = new Date(tr.dataset.exp + 'T00:00:00');
    if (isNaN(d)) return;
    var n = Math.round((d - today) / MS);
    chip.textContent = n < 0 ? 'Quá hạn ' + Math.abs(n) + ' ngày' : (n === 0 ? 'Hết hạn hôm nay' : 'Còn ' + n + ' ngày');
  });

  function norm(s){
    return (s || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd');
  }

  var EMPTIES = {
    light:       { art:'✅', good:true, t:'Không có lô nào cận hạn nhẹ',
                   d:'Không lô nào rơi vào khoảng 91–180 ngày trước hạn.' },
    restricted:  { art:'✅', good:true, t:'Không có lô nào cần hạn chế xuất',
                   d:'Không lô nào rơi vào khoảng 31–90 ngày trước hạn.' },
    quarantined: { art:'🎉', good:true, t:'Không có lô nào bị cách ly',
                   d:'Không lô nào còn dưới 30 ngày sử dụng. Kho đang khoẻ.' },
    search:      { art:'🔍', good:false, t:'Không tìm thấy kết quả nào',
                   d:'Không có lô nào khớp từ khoá trong tầng cảnh báo này.' }
  };

  function visible(){
    var k = norm(q).trim();
    return rows.filter(function (tr) {
      if (tr.dataset.tier !== tier) return false;
      if (!k) return true;
      var hay = norm(tr.dataset.name) + ' ' + norm(tr.dataset.lot);
      return k.split(/\s+/).every(function (w) { return hay.indexOf(w) > -1; });
    });
  }

  function render(){
    var list = visible();
    body.replaceChildren.apply(body, list);
    document.getElementById('tblTier').hidden = list.length === 0;

    var es = document.getElementById('emptyState');
    if (list.length === 0) {
      var cfg = q ? EMPTIES.search : EMPTIES[tier];
      document.getElementById('emptyArt').textContent   = cfg.art;
      document.getElementById('emptyTitle').textContent = cfg.t;
      document.getElementById('emptyDesc').textContent  = cfg.d;
      es.className = 'wh-empty' + (cfg.good ? ' good' : '');
      es.hidden = false;
    } else {
      es.hidden = true;
    }

    document.getElementById('pager').style.display = list.length === 0 ? 'none' : '';
    document.getElementById('pagerInfo').innerHTML = 'Hiển thị <b>' + list.length + '</b> lô trong tầng cảnh báo này';

    if (window.whFitTables) window.whFitTables();   // bảng vừa đổi nội dung
  }

  function setTier(t){
    tier = t;
    document.querySelectorAll('.wh-seg button, .wh-kpi[data-tier]').forEach(function (b) {
      b.setAttribute('aria-pressed', String(b.dataset.tier === t));
      if (b.classList.contains('wh-kpi')) b.classList.toggle('is-active', b.dataset.tier === t);
    });
    render();
  }
  document.querySelectorAll('.wh-seg button, .wh-kpi[data-tier]').forEach(function (b) {
    b.addEventListener('click', function () {
      setTier(b.dataset.tier);
      document.getElementById('toolbar').scrollIntoView({
        block:'start', behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth'
      });
    });
  });

  var qEl = document.getElementById('q'), qBox = document.getElementById('searchBox');
  function onQuery(){
    q = qEl.value;
    qBox.classList.toggle('has-value', q.length > 0);
    render();
  }
  var t;
  qEl.addEventListener('input', function () { clearTimeout(t); t = setTimeout(onQuery, 120); });
  qEl.addEventListener('search', onQuery);
  document.getElementById('qClear').addEventListener('click', function () { qEl.value = ''; onQuery(); qEl.focus(); });

  // Xuất CSV đúng tầng đang xem (BOM để Excel đọc tiếng Việt)
  function csvCell(v){ return '"' + String(v == null ? '' : v).replace(/"/g, '""') + '"'; }
  document.getElementById('btnExport').addEventListener('click', function () {
    var list = visible();
    if (!list.length) return;
    var lines = [['Thuốc','Số lô','Còn tồn','Hạn dùng'].map(csvCell).join(',')];
    list.forEach(function (tr) {
      lines.push([tr.dataset.name, tr.dataset.lot, tr.dataset.qty, tr.dataset.exp].map(csvCell).join(','));
    });
    var blob = new Blob(['\ufeff' + lines.join('\r\n')], { type:'text/csv;charset=utf-8;' });
    var a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = 'canh-bao-han-dung-' + tier + '-' + new Date().toISOString().slice(0, 10) + '.csv';
    a.click();
    setTimeout(function () { URL.revokeObjectURL(a.href); }, 1000);
  });

  var btnRefresh = document.getElementById('btnRefresh');
  btnRefresh.addEventListener('click', function () {
    btnRefresh.classList.add('is-busy'); btnRefresh.disabled = true; location.reload();
  });

  document.addEventListener('keydown', function (e) {
    if (e.key === '/' && !/^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement.tagName)) {
      e.preventDefault(); qEl.focus(); qEl.select();
    }
    if (e.key === 'Escape' && document.activeElement === qEl && qEl.value) { qEl.value = ''; onQuery(); }
  });

  // Bảng cảnh báo mở sẵn ở tầng khẩn nhất đang có dữ liệu — thứ cần xử lý trước
  // luôn nằm ngay trước mắt, không phải bấm mới thấy.
  var boot = ['quarantined','restricted','light'].find(function (t2) {
    return rows.some(function (r) { return r.dataset.tier === t2; });
  }) || 'light';
  setTier(boot);
})();
</script>
</body>
</html>
