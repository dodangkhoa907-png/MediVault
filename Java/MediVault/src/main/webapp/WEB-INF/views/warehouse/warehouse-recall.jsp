<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%--
  warehouse-recall.jsp — Thu hồi lô khẩn cấp (Warehouse Console)

  Port sang design system `wh-*` (2026-08-02). Ngoài việc đồng bộ hình thức,
  trang này còn xoá khối CSS .topbar/.tb-brand/.tb-back thừa: nó định nghĩa một
  topbar gradient hoàn toàn khác nhưng markup lại dùng .wh-topbar, nên chưa bao
  giờ được áp dụng — chỉ tồn tại để gây nhầm khi sửa.

  Luồng POST giữ nguyên: action=search → hiện foundBatch → action=confirm-recall.
--%>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) request.getAttribute("staffAcc");
    String ctx = request.getContextPath();
    if (acc == null) { response.sendRedirect(ctx + "/warehouse-login"); return; }
    String fullName = acc.getFullName() != null && !acc.getFullName().isEmpty() ? acc.getFullName() : acc.getUsername();
    String initials = fullName.substring(0,1).toUpperCase();
    String uid = (String) request.getAttribute("staffUid");
    String activeNav = "recall";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Thu hồi lô khẩn cấp — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400..800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= ctx %>/css/staff-portal.css">
<link rel="stylesheet" href="<%= ctx %>/css/warehouse-portal.css?v=11">
<style>
a{text-decoration:none;color:inherit}

/* Form tìm lô: 2 ô + 1 nút nằm cùng một hàng, nút thẳng đáy với ô nhập */
.find-row{display:flex;gap:14px;flex-wrap:wrap;align-items:flex-end}
.find-row .wh-fg{flex:1;min-width:210px;margin-bottom:0}
.find-row .wh-btn{height:44px}

/* Bảng lịch sử thu hồi */
.h-lot{width:150px} .h-med{width:auto;min-width:180px} .h-why{width:auto;min-width:240px}
.h-who{width:160px} .h-when{width:170px}
#tblHistory{min-width:880px}
.h-why .cell{white-space:normal;line-height:1.5;font-size:13px}
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
      <a href="<%= ctx %>/warehouse-reorder">Gợi ý đặt hàng</a>
      <a class="on" href="<%= ctx %>/warehouse-recall">Thu hồi</a>
    </nav>
    <div class="right">
      <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc của <%= fullName %>"><%= initials %></a>
    </div>
  </header>

  <div class="wh-shell wh-anim">

    <div class="wh-head">
      <div>
        <h1>Thu hồi lô khẩn cấp</h1>
        <p class="sub">Tìm đúng lô theo số lô, kiểm tra vị trí kệ, và ngừng bán ngay khi có công văn thu hồi.</p>
      </div>
    </div>

    <div class="wh-note warn">
      <svg><use href="#ic-siren"/></svg>
      <span>Thu hồi có hiệu lực <b>ngay lập tức</b>: lô bị chặn khỏi mọi quầy POS và không thể bán tiếp.
        Thao tác này <b>không tự hoàn tác</b> được — hãy đối chiếu số lô trên vỏ hộp trước khi xác nhận.</span>
    </div>

    <c:if test="${param.msg == 'recalled'}">
      <div class="wh-note ok" role="status">
        <svg><use href="#ic-check-circle"/></svg>
        <span>Đã thu hồi lô. Lô này ngừng bán ngay lập tức tại tất cả quầy POS.</span>
      </div>
    </c:if>
    <c:if test="${not empty error}">
      <div class="wh-note danger" role="alert">
        <svg><use href="#ic-alert"/></svg>
        <span><c:out value="${error}"/></span>
      </div>
    </c:if>

    <!-- ══ Tìm lô ══ -->
    <div class="wh-card">
      <div class="wh-card-head">
        <div class="wh-ic"><svg><use href="#ic-search"/></svg></div>
        <h2>Tìm lô cần thu hồi</h2>
      </div>
      <div class="wh-card-body">
        <form method="post" action="<%= ctx %>/warehouse-recall">
          <input type="hidden" name="_csrf" value="${csrfToken}">
          <input type="hidden" name="uid" value="${staffUid}">
          <input type="hidden" name="action" value="search">
          <div class="find-row">
            <div class="wh-fg">
              <label for="rcMed">Thuốc</label>
              <select class="wh-in" id="rcMed" name="medicineId" required>
                <option value="">— Chọn thuốc —</option>
                <c:forEach var="m" items="${medicines}">
                  <option value="${m.medicineId}" ${param.medicineId == m.medicineId ? 'selected' : ''}>${m.medicineName}</option>
                </c:forEach>
              </select>
            </div>
            <div class="wh-fg">
              <label for="rcLot">Số lô</label>
              <input class="wh-in" type="text" id="rcLot" name="batchNumber" autocomplete="off"
                     value="${fn:escapeXml(param.batchNumber)}" placeholder="Nhập hoặc quét số lô…" required>
            </div>
            <button type="submit" class="wh-btn wh-btn-primary">
              <svg><use href="#ic-search"/></svg> Tìm lô
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- ══ Lô tìm thấy — xác nhận thu hồi ══ -->
    <c:if test="${not empty foundBatch}">
      <div class="wh-card danger">
        <div class="wh-card-head">
          <div class="wh-ic"><svg><use href="#ic-siren"/></svg></div>
          <h2>Thông tin lô — xác nhận thu hồi</h2>
        </div>
        <div class="wh-card-body">
          <div class="wh-facts">
            <div class="wh-fact"><div class="k">Số lô</div><div class="v mono">${foundBatch.batchNumber}</div></div>
            <div class="wh-fact"><div class="k">Tên thuốc</div><div class="v">${foundMedName}</div></div>
            <div class="wh-fact hot"><div class="k">Hạn dùng</div><div class="v">${foundBatch.expiryDate}</div></div>
            <div class="wh-fact hot"><div class="k">Còn tồn</div><div class="v">${foundBatch.currentQuantity}</div></div>
            <div class="wh-fact"><div class="k">Vị trí kệ</div><div class="v">${foundShelf}</div></div>
            <div class="wh-fact"><div class="k">Trạng thái</div><div class="v">
              <span class="wh-badge ${foundBatch.status == 'ACTIVE' ? 'ok' : 'mute'}">${foundBatch.status}</span>
            </div></div>
          </div>

          <c:choose>
            <c:when test="${foundBatch.status == 'ACTIVE'}">
              <form method="post" action="<%= ctx %>/warehouse-recall" id="recallForm" style="margin-top:22px">
                <input type="hidden" name="_csrf" value="${csrfToken}">
                <input type="hidden" name="uid" value="${staffUid}">
                <input type="hidden" name="action" value="confirm-recall">
                <input type="hidden" name="batchId" value="${foundBatch.batchId}">
                <div class="wh-fg">
                  <label for="reasonInput" style="color:var(--danger)">Lý do thu hồi — bắt buộc</label>
                  <textarea class="wh-in on-danger" name="reason" id="reasonInput" required
                    placeholder="VD: Công văn số …/QLD-CL của Cục Quản lý Dược yêu cầu thu hồi lô do phát hiện lỗi chất lượng…"></textarea>
                </div>
                <button type="submit" class="wh-btn wh-btn-danger wh-btn-lg" id="confirmBtn" disabled>
                  <svg><use href="#ic-siren"/></svg> Xác nhận thu hồi lô ${foundBatch.batchNumber}
                </button>
              </form>
            </c:when>
            <c:otherwise>
              <div class="wh-note info" style="margin:22px 0 0">
                <svg><use href="#ic-info"/></svg>
                <span>Lô này không còn ở trạng thái ACTIVE nên không thu hồi được nữa — có thể đã được xử lý trước đó.</span>
              </div>
            </c:otherwise>
          </c:choose>
        </div>
      </div>
    </c:if>

    <!-- ══ Lịch sử thu hồi ══ -->
    <div class="wh-tablecard">
      <div class="wh-card-head">
        <div class="wh-ic"><svg><use href="#ic-clipboard"/></svg></div>
        <h2>Lịch sử thu hồi <small>30 ngày gần nhất</small></h2>
      </div>
      <div class="wh-tablescroll">
        <c:choose>
          <c:when test="${empty history}">
            <div class="wh-empty good">
              <div class="art">🎉</div>
              <div class="t">Chưa có lô nào bị thu hồi</div>
              <div class="d">Không có lô nào bị thu hồi trong 30 ngày qua.</div>
            </div>
          </c:when>
          <c:otherwise>
            <table class="wh-table" id="tblHistory">
              <thead>
                <tr>
                  <th class="h-lot">Số lô</th>
                  <th class="h-med">Thuốc</th>
                  <th class="h-why">Lý do</th>
                  <th class="h-who">Người thu hồi</th>
                  <th class="h-when">Thời gian</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="h" items="${history}">
                  <tr>
                    <td class="h-lot"><span class="wh-code">${h.batchNumber}</span></td>
                    <td class="h-med"><div class="wh-name" title="${fn:escapeXml(h.medicineName)}">${h.medicineName}</div></td>
                    <td class="h-why"><div class="cell">${fn:escapeXml(h.reason)}</div></td>
                    <td class="h-who">${h.recalledBy}</td>
                    <td class="h-when">${h.createdAt}</td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </c:otherwise>
        </c:choose>
      </div>
    </div>

  </div>
</div>

<script>
(function () {
  'use strict';
  // Nút xác nhận chỉ mở khi đã ghi lý do — chặn thu hồi "lỡ tay" ngay tại UI,
  // trước cả khi servlet validate.
  var reason = document.getElementById('reasonInput');
  var btn = document.getElementById('confirmBtn');
  if (!reason || !btn) return;

  function sync(){ btn.disabled = reason.value.trim().length === 0; }
  reason.addEventListener('input', sync);
  sync();

  document.getElementById('recallForm').addEventListener('submit', function (e) {
    var el = document.querySelector('.wh-fact .v.mono');
    var lot = el ? el.textContent.trim() : '';
    if (!confirm('Xác nhận THU HỒI lô ' + lot + '?\n\nLô sẽ ngừng bán ngay lập tức tại mọi quầy POS.')) {
      e.preventDefault();
      return;
    }
    btn.disabled = true;
    btn.classList.add('is-busy');
  });
})();
</script>
</body>
</html>
