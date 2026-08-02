<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%--
  warehouse-stock-movement.jsp — Xuất kho & Điều chỉnh tồn (Warehouse Console)

  Port sang lớp design system `wh-*` (2026-08-02) cho khớp trang Tồn kho:
  topbar + sub-nav thay cho hàng section-tabs emoji, .wh-card/.wh-fg/.wh-note/
  .wh-feed thay cho CSS riêng của trang. Toàn bộ tên field, id, hàm JS và luồng
  POST giữ nguyên — chỉ đổi lớp trình bày.
--%>
<%
    // ── Gate: WarehouseAuth (trong servlet) đã xác thực roleId==3 và đặt sẵn "staffAcc".
    // Trang này trước đây tự đọc ?uid= rồi tra session — nay danh tính đến từ session,
    // không từ URL, nên đọc thẳng attribute như mọi trang Kho khác. ──
    com.medicare.entity.Account acc = (com.medicare.entity.Account) request.getAttribute("staffAcc");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/warehouse-login"); return; }
    String uid = String.valueOf(acc.getAccountId());

    String ctx = request.getContextPath();
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.substring(0,1).toUpperCase();
    String activeNav = "movement";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<meta name="ctx" content="<%= ctx %>">
<title>Xuất kho &amp; Điều chỉnh tồn — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400..800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= ctx %>/css/staff-portal.css">
<link rel="stylesheet" href="<%= ctx %>/css/warehouse-portal.css?v=11">
<style>
a{text-decoration:none;color:inherit}

/* ── Nhắc lô FEFO: chỉ hiện sau khi chọn thuốc ──
   Đặt ngay dưới ô chọn thuốc thay vì chỉ nằm ở panel phải: thao tác kế tiếp là
   gõ số lô, nên số lô cần lấy phải nằm trong cùng tầm mắt với ô nhập. */
.fefo-nudge{display:none;margin:-4px 0 18px}
.fefo-nudge.show{display:flex}
.fefo-nudge .lot{font-family:ui-monospace,"SF Mono",Consolas,monospace;font-weight:800;letter-spacing:-.3px}

.dir-row{display:none;margin:-4px 0 18px}
.dir-row.show{display:flex}

/* Panel lô chỉ định — số lô là thứ duy nhất người dùng phải đọc chính xác,
   nên nó được đặt to nhất trong cả cột phải. */
.lot-big{font-family:ui-monospace,"SF Mono",Consolas,monospace;font-size:24px;font-weight:800;
  color:var(--ink);letter-spacing:-.6px;word-break:break-all;margin-bottom:4px}
.lot-tag{font-size:10.5px;font-weight:800;letter-spacing:.08em;text-transform:uppercase;color:var(--main);
  display:flex;align-items:center;gap:6px;margin-bottom:8px}
.days-chip{display:inline-block;margin-left:8px;padding:2px 9px;border-radius:999px;font-size:11px;font-weight:800}
.days-ok{background:var(--okbg);color:var(--ok)}
.days-warn{background:var(--goldbg);color:var(--gold)}
.days-danger{background:var(--dangerbg);color:var(--danger)}

#barcodeReaderBox{width:100%;min-height:250px;border-radius:14px;overflow:hidden;background:#06201E}
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
      <a class="on" href="<%= ctx %>/warehouse-stock-movement">Điều chỉnh</a>
      <a href="<%= ctx %>/warehouse-reorder">Gợi ý đặt hàng</a>
      <a href="<%= ctx %>/warehouse-recall">Thu hồi</a>
    </nav>
    <div class="right">
      <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc của <%= fullName %>"><%= initials %></a>
    </div>
  </header>

  <div class="wh-shell wh-anim">

    <div class="wh-head">
      <div>
        <h1>Xuất kho &amp; Điều chỉnh tồn</h1>
        <p class="sub">Ghi nhận xuất kho, huỷ hàng hết hạn và điều chỉnh sau kiểm kê — theo đúng lô hệ thống chỉ định.</p>
      </div>
      <div class="wh-head-actions">
        <a class="wh-btn" href="<%= ctx %>/warehouse-inventory">
          <svg><use href="#ic-package"/></svg> Xem tồn kho
        </a>
      </div>
    </div>

    <div class="wh-note info">
      <svg><use href="#ic-lock"/></svg>
      <span>Hệ thống chỉ định lô theo <b>FEFO</b> (hạn dùng gần nhất xuất trước). Bạn phải quét hoặc nhập
        <b>đúng số lô đó</b> mới xác nhận được — nhập sai lô sẽ bị chặn và không trừ kho.</span>
    </div>

    <c:if test="${not empty error}">
      <div class="wh-note danger" role="alert">
        <svg><use href="#ic-alert"/></svg>
        <span><c:out value="${error}"/></span>
      </div>
    </c:if>
    <c:if test="${param.msg == 'success'}">
      <div class="wh-note ok" role="status">
        <svg><use href="#ic-check-circle"/></svg>
        <span>Đã ghi nhận thao tác. Tồn kho của lô được cập nhật ngay.</span>
      </div>
    </c:if>

    <div class="wh-split">

      <!-- ══ Cột trái: form thao tác ══ -->
      <div class="wh-card">
        <div class="wh-card-head">
          <div class="wh-ic"><svg><use href="#ic-out"/></svg></div>
          <h2>Thao tác xuất kho / điều chỉnh</h2>
        </div>
        <div class="wh-card-body">
          <form method="post" action="<%= ctx %>/warehouse-stock-movement" id="mvForm">
            <input type="hidden" name="_csrf" value="${csrfToken}">
            <input type="hidden" name="uid" value="<%= uid %>"/>

            <div class="wh-fg">
              <label for="medicineSelect">Thuốc</label>
              <select class="wh-in" name="medicineId" id="medicineSelect" required onchange="loadSuggestedBatch()">
                <option value="">— Chọn thuốc —</option>
                <c:forEach var="m" items="${medicines}">
                  <option value="${m.medicineId}" ${f_medicineId == m.medicineId ? 'selected' : ''}>
                    ${m.medicineName} (Tồn: ${m.totalStock})
                  </option>
                </c:forEach>
              </select>
            </div>

            <div class="wh-note info fefo-nudge" id="fefoNudge">
              <svg><use href="#ic-target"/></svg>
              <span>Lấy đúng lô <b class="lot" id="fnBatch">—</b> — chi tiết hạn dùng và tồn ở panel bên phải.</span>
            </div>

            <div class="wh-row2">
              <div class="wh-fg">
                <label for="enteredBatchNumber">
                  <span>Số lô</span>
                  <button type="button" class="wh-linkbtn" onclick="openBarcodeScan()">
                    <svg><use href="#ic-scan"/></svg> Quét mã vạch
                  </button>
                </label>
                <input class="wh-in" type="text" name="enteredBatchNumber" id="enteredBatchNumber"
                       placeholder="VD: LOT-2026-001" value="${fn:escapeXml(f_enteredBatchNumber)}"
                       autocomplete="off" required/>
              </div>
              <div class="wh-fg">
                <label for="mvQty">Số lượng</label>
                <input class="wh-in" type="number" id="mvQty" name="quantity" min="1"
                       placeholder="0" value="${fn:escapeXml(f_quantity)}" required/>
              </div>
            </div>

            <div class="wh-fg">
              <label for="movementType">Loại thao tác</label>
              <select class="wh-in" name="movementType" id="movementType" required onchange="toggleDirection()">
                <option value="OUT" ${f_movementType == 'OUT' ? 'selected' : ''}>Xuất kho / Huỷ hàng</option>
                <option value="EXPIRED" ${f_movementType == 'EXPIRED' ? 'selected' : ''}>Huỷ hết hạn</option>
                <option value="ADJUSTMENT" ${f_movementType == 'ADJUSTMENT' ? 'selected' : ''}>Điều chỉnh sau kiểm kê</option>
              </select>
            </div>

            <div class="wh-choice dir-row" id="directionRow">
              <label>
                <input type="radio" name="adjustDirection" value="DECREASE"
                       ${f_adjustDirection != 'INCREASE' ? 'checked' : ''}/> Kiểm kê thiếu — giảm tồn
              </label>
              <label>
                <input type="radio" name="adjustDirection" value="INCREASE"
                       ${f_adjustDirection == 'INCREASE' ? 'checked' : ''}/> Kiểm kê thừa — tăng tồn
              </label>
            </div>

            <div class="wh-fg">
              <label for="mvReason">Lý do</label>
              <textarea class="wh-in" id="mvReason" name="reason"
                placeholder="VD: Hộp bị vỡ, phát hiện khi kiểm kê định kỳ…">${fn:escapeXml(f_reason)}</textarea>
            </div>

            <button type="submit" class="wh-btn wh-btn-primary wh-btn-lg" style="width:100%;justify-content:center">
              <svg><use href="#ic-check"/></svg> Xác nhận thao tác
            </button>
          </form>
        </div>
      </div>

      <!-- ══ Cột phải: lô chỉ định + lịch sử ══ -->
      <div class="wh-stack">

        <div class="wh-card">
          <div class="wh-card-head">
            <div class="wh-ic ok"><svg><use href="#ic-target"/></svg></div>
            <h2>Lô hệ thống chỉ định</h2>
          </div>

          <div class="wh-empty" id="batchEmpty">
            <div class="art"><svg style="width:26px;height:26px"><use href="#ic-package"/></svg></div>
            <div class="t">Chưa chọn thuốc</div>
            <div class="d" id="batchEmptyMsg">Chọn thuốc ở cột bên trái để xem lô phải lấy theo FEFO.</div>
          </div>

          <div class="wh-card-body" id="batchInfo" hidden>
            <div class="lot-tag"><svg style="width:13px;height:13px"><use href="#ic-target"/></svg> Lô cần lấy</div>
            <div class="lot-big" id="biBatch">—</div>
            <div class="wh-rows" style="margin-top:14px">
              <div class="r">
                <span class="k"><svg><use href="#ic-calendar"/></svg> Hạn dùng</span>
                <span class="v"><span id="biExpiry">—</span><span id="biDays"></span></span>
              </div>
              <div class="r">
                <span class="k"><svg><use href="#ic-package"/></svg> Còn tồn trong lô</span>
                <span class="v" id="biQty">—</span>
              </div>
            </div>
            <div class="wh-note ok" style="margin:16px 0 0;font-size:12.5px">
              <svg><use href="#ic-shield-check"/></svg>
              <span>Quét đúng số lô này để được xác nhận. Đây là lô hết hạn sớm nhất còn bán được.</span>
            </div>
          </div>
        </div>

        <div class="wh-card">
          <div class="wh-card-head">
            <div class="wh-ic"><svg><use href="#ic-history"/></svg></div>
            <h2>Lịch sử gần đây <small>7 ngày</small></h2>
          </div>
          <c:choose>
            <c:when test="${empty movementRows}">
              <div class="wh-empty">
                <div class="art"><svg style="width:26px;height:26px"><use href="#ic-history"/></svg></div>
                <div class="t">Chưa có thao tác nào</div>
                <div class="d">Không có lượt xuất kho hay điều chỉnh nào trong 7 ngày qua.</div>
              </div>
            </c:when>
            <c:otherwise>
              <div class="wh-feed">
                <c:forEach var="r" items="${movementRows}" end="6">
                  <div class="it">
                    <div class="ic <c:choose><c:when test="${r.movementType == 'OUT'}">out</c:when><c:when test="${r.movementType == 'EXPIRED'}">exp</c:when><c:otherwise>adj</c:otherwise></c:choose>">
                      <svg><use href="#<c:choose><c:when test="${r.movementType == 'OUT'}">ic-out</c:when><c:when test="${r.movementType == 'EXPIRED'}">ic-clock-alert</c:when><c:otherwise>ic-scale</c:otherwise></c:choose>"/></svg>
                    </div>
                    <div class="bd">
                      <div class="t1">${fn:escapeXml(r.medicineName)}</div>
                      <div class="t2">Lô ${fn:escapeXml(r.batchNumber)} · ${r.createdAt}</div>
                    </div>
                    <div class="qty ${r.quantity < 0 ? 'neg' : 'pos'}">${r.quantity}</div>
                  </div>
                </c:forEach>
              </div>
            </c:otherwise>
          </c:choose>
        </div>

      </div>
    </div>
  </div>
</div>

<!-- ══ Modal quét mã vạch ══ -->
<div class="wh-modal" id="barcodeScanModal" onclick="if(event.target===this)closeBarcodeScan()">
  <div class="wh-modal-box" role="dialog" aria-modal="true" aria-labelledby="bcTitle">
    <div class="wh-modal-head">
      <div class="wh-ic"><svg><use href="#ic-scan"/></svg></div>
      <h3 id="bcTitle">Quét mã vạch lô</h3>
      <button type="button" class="wh-btn wh-btn-icon wh-btn-ghost" onclick="closeBarcodeScan()" aria-label="Đóng">
        <svg><use href="#ic-x"/></svg>
      </button>
    </div>
    <div class="wh-modal-body">
      <div id="barcodeReaderBox"></div>
      <div id="barcodeScanStatus" style="margin-top:12px;font-size:12.5px;color:var(--muted);text-align:center">
        Đưa mã vạch vào giữa khung hình.
      </div>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/html5-qrcode@2.3.8/html5-qrcode.min.js" defer></script>
<script>
function toggleDirection(){
  var mt = document.getElementById('movementType').value;
  document.getElementById('directionRow').classList.toggle('show', mt === 'ADJUSTMENT');
}

function resetBatchPanel(msg){
  document.getElementById('batchInfo').hidden = true;
  document.getElementById('fefoNudge').classList.remove('show');
  var empty = document.getElementById('batchEmpty');
  empty.hidden = false;
  document.getElementById('batchEmptyMsg').textContent =
    msg || 'Chọn thuốc ở cột bên trái để xem lô phải lấy theo FEFO.';
}

function daysChip(expiry){
  if (!expiry) return '';
  var d = Math.ceil((new Date(expiry) - new Date()) / 86400000);
  var cls = d <= 30 ? 'days-danger' : (d <= 90 ? 'days-warn' : 'days-ok');
  return '<span class="days-chip ' + cls + '">' + (d >= 0 ? 'còn ' + d + ' ngày' : 'đã hết hạn') + '</span>';
}

function loadSuggestedBatch(){
  var medId = document.getElementById('medicineSelect').value;
  if (!medId) { resetBatchPanel(); return; }
  resetBatchPanel('Đang tải lô hệ thống chỉ định…');
  var ctx = document.querySelector('meta[name=ctx]').content;
  fetch(ctx + '/warehouse-stock-movement?action=suggest-batch&medicineId=' + encodeURIComponent(medId))
    .then(function(r){ return r.json(); })
    .then(function(d){
      if (d.ok) {
        document.getElementById('batchEmpty').hidden = true;
        document.getElementById('biBatch').textContent = d.batchNumber;
        document.getElementById('biExpiry').textContent = d.expiryDate;
        document.getElementById('biDays').innerHTML = daysChip(d.expiryDate);
        document.getElementById('biQty').textContent = d.currentQuantity;
        document.getElementById('batchInfo').hidden = false;
        document.getElementById('fnBatch').textContent = d.batchNumber;
        document.getElementById('fefoNudge').classList.add('show');
      } else {
        resetBatchPanel(d.message || 'Không có lô nào khả dụng cho thuốc này.');
      }
    })
    .catch(function(){
      resetBatchPanel('Không tải được gợi ý lô. Bạn vẫn nhập tay được — hệ thống sẽ kiểm tra khi xác nhận.');
    });
}

toggleDirection();
<c:if test="${not empty f_medicineId}">loadSuggestedBatch();</c:if>

var barcodeScanner = null;
function openBarcodeScan(){
  var modal = document.getElementById('barcodeScanModal');
  modal.classList.add('open');
  var status = document.getElementById('barcodeScanStatus');
  status.textContent = 'Đưa mã vạch vào giữa khung hình…';
  if (typeof Html5Qrcode === 'undefined') {
    status.textContent = 'Không tải được thư viện quét mã vạch. Kiểm tra kết nối mạng rồi thử lại.';
    return;
  }
  barcodeScanner = new Html5Qrcode('barcodeReaderBox');
  barcodeScanner.start(
    { facingMode: 'environment' },
    { fps: 10, qrbox: { width: 260, height: 140 },
      formatsToSupport: [
        Html5QrcodeSupportedFormats.EAN_13, Html5QrcodeSupportedFormats.EAN_8,
        Html5QrcodeSupportedFormats.CODE_128, Html5QrcodeSupportedFormats.CODE_39,
        Html5QrcodeSupportedFormats.UPC_A, Html5QrcodeSupportedFormats.UPC_E,
        Html5QrcodeSupportedFormats.QR_CODE
      ] },
    function(decodedText){
      document.getElementById('enteredBatchNumber').value = decodedText;
      closeBarcodeScan();
    },
    function(){}   // lỗi giải mã từng khung hình — bỏ qua
  ).catch(function(err){
    status.textContent = 'Không mở được camera: ' + (err.message || err);
  });
}
function closeBarcodeScan(){
  document.getElementById('barcodeScanModal').classList.remove('open');
  if (barcodeScanner) {
    var s = barcodeScanner;
    barcodeScanner = null;
    s.stop().then(function(){ s.clear(); }).catch(function(){});
  }
}
document.addEventListener('keydown', function(e){
  if (e.key === 'Escape' && document.getElementById('barcodeScanModal').classList.contains('open')) closeBarcodeScan();
});
</script>
</body>
</html>
