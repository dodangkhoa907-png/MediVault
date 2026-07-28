<%@ page contentType="text/html;charset=UTF-8" language="java" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%
    // ── Gate: chỉ Thủ kho (roleId == 3), session "staffAccount_<uid>" ──
    String uid = request.getParameter("uid");
    if (uid == null || uid.isEmpty()) uid = (String) request.getAttribute("uid");
    if (uid == null || uid.isEmpty()) { response.sendRedirect(request.getContextPath() + "/warehouse-login"); return; }

    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("staffAccount_" + uid);
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/warehouse-login"); return; }
    if (acc.getRoleId() != 3) { response.sendRedirect(request.getContextPath() + "/warehouse-login"); return; }

    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
    String activeNav = "movement";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<meta name="ctx" content="${pageContext.request.contextPath}">
<title>Xuất kho &amp; Điều chỉnh tồn — MediCare Kho</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/staff-portal.css">
<link rel="stylesheet" href="${pageContext.request.contextPath}/css/warehouse-portal.css?v=5">
<style>
a{text-decoration:none;color:inherit}

.wrap{max-width:1180px;margin:0 auto}
.page-intro{display:flex;gap:10px;align-items:flex-start;max-width:840px;
  font-size:13.5px;color:var(--muted);line-height:1.55;margin-bottom:22px}
.page-intro .pi-ic{color:var(--main);font-size:16px;flex:none;margin-top:1px}
.page-intro b{color:var(--ink);font-weight:750}

.alert{border-radius:12px;padding:13px 18px;margin-bottom:18px;font-size:13.5px;font-weight:600;line-height:1.55}
.alert-err{background:#FEF2F2;border:1px solid #FCA5A5;color:#B91C1C}
.alert-ok{background:#ECFDF5;border:1px solid #6EE7B7;color:#047857}

/* ── Bố cục 2 cột: Form thao tác (chính) | Panel lô FEFO + lịch sử (ngữ cảnh) ── */
.sm-grid{display:grid;grid-template-columns:1.5fr 1fr;gap:22px;align-items:start}
@media(max-width:920px){.sm-grid{grid-template-columns:1fr}}
.sm-side{display:flex;flex-direction:column;gap:22px}

.card{background:#fff;border:1px solid #E4E9E7;border-radius:16px;overflow:hidden;
  box-shadow:0 1px 2px rgba(4,47,46,.04),0 12px 30px -18px rgba(4,47,46,.14)}
.card-head{padding:15px 20px;border-bottom:1px solid #EAEFED;display:flex;align-items:center;gap:11px}
.card-head h2{font-size:14.5px;font-weight:800;color:var(--ink)}
.card-head h2 small{color:var(--muted);font-weight:600;font-size:12px;margin-left:5px}
.card-body{padding:22px 20px}

.fg{display:flex;flex-direction:column;gap:7px;margin-bottom:17px}
.fg > label{font-size:11px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.fg input,.fg select,.fg textarea{border:1.5px solid #DCE8E5;border-radius:10px;padding:11px 14px;
  font-family:'Plus Jakarta Sans',sans-serif;font-size:14px;color:var(--ink);background:#fff;
  width:100%;transition:border .16s,box-shadow .16s}
.fg input::placeholder,.fg textarea::placeholder{color:#94A3A0}
.fg input:focus,.fg select:focus,.fg textarea:focus{border-color:var(--main);outline:none;
  box-shadow:0 0 0 3.5px rgba(15,118,110,.12)}
.fg textarea{min-height:84px;resize:vertical}
.row2{display:grid;grid-template-columns:1fr 1fr;gap:14px}
@media(max-width:520px){.row2{grid-template-columns:1fr}}

/* ── FEFO nudge — hộp highlight nhắc lấy đúng lô (💡), chỉ hiện sau khi chọn thuốc ── */
.fefo-nudge{display:none;align-items:center;gap:11px;margin:-2px 0 17px;padding:12px 15px;border-radius:11px;
  background:linear-gradient(100deg,#E6FFFA,#ECFDF9);border:1px solid #99F6E4;border-left:4px solid var(--main);
  font-size:13px;color:var(--deep);line-height:1.45}
.fefo-nudge.show{display:flex}
.fefo-nudge .fn-ic{font-size:18px;flex:none}
.fefo-nudge b{font-weight:800;color:var(--main)}

.direction-row{display:none;gap:10px;margin:-2px 0 17px}
.direction-row.show{display:flex}
.dir-opt{flex:1;display:flex;align-items:center;gap:8px;padding:11px 13px;border:1.5px solid #DCE8E5;
  border-radius:10px;cursor:pointer;font-size:13px;font-weight:700;color:var(--ink);background:#fff}
.dir-opt input{accent-color:var(--main)}
.dir-opt:has(input:checked){border-color:var(--main);background:#E6FFFA}

.btn-submit{width:100%;height:48px;background:linear-gradient(135deg,var(--main),var(--deep));
  color:#fff;border:none;border-radius:12px;font-size:15px;font-weight:800;cursor:pointer;
  font-family:inherit;transition:filter .15s,transform .05s;box-shadow:0 8px 20px -8px rgba(15,118,110,.5)}
.btn-submit:hover{filter:brightness(1.07)}
.btn-submit:active{transform:translateY(1px)}

/* ── Panel lô FEFO (cột phải) — signature: bừng sáng khi chọn thuốc ── */
.batch-empty{padding:34px 22px;text-align:center;color:var(--muted)}
.batch-empty .be-ic{font-size:32px;opacity:.45;margin-bottom:10px}
.batch-empty p{font-size:13px;line-height:1.5}
.batch-info{display:none;padding:20px}
.batch-info.show{display:block}
.bi-tag{font-size:10.5px;font-weight:800;letter-spacing:.6px;text-transform:uppercase;color:var(--main);
  margin-bottom:7px;display:flex;align-items:center;gap:6px}
.bi-batch{font-size:23px;font-weight:800;color:var(--ink);letter-spacing:-.3px;
  font-family:ui-monospace,Consolas,monospace;margin-bottom:17px;word-break:break-all}
.bi-rows{display:flex;flex-direction:column;gap:0}
.bi-row{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:11px 0;border-bottom:1px solid #EAEFED}
.bi-row:last-child{border-bottom:none}
.bi-lbl{font-size:12.5px;color:var(--muted);font-weight:650;display:flex;align-items:center;gap:7px}
.bi-val{font-size:14px;font-weight:800;color:var(--ink)}
.days-badge{display:inline-block;margin-left:7px;padding:1px 8px;border-radius:20px;font-size:11px;font-weight:800}
.days-ok{background:var(--okbg);color:var(--ok)}
.days-warn{background:var(--goldbg);color:var(--gold)}
.days-danger{background:var(--dangerbg);color:var(--danger)}
.fefo-note{margin-top:17px;padding:11px 13px;border-radius:10px;background:#F0FDFA;border:1px solid #99F6E4;
  font-size:12px;color:#0F766E;line-height:1.45;display:flex;gap:8px}
.fefo-note .fnn-ic{flex:none}

/* ── Lịch sử di chuyển kho (mini, gọn trong cột phải) ── */
.mini-list{display:flex;flex-direction:column}
.mini-row{display:flex;align-items:center;gap:11px;padding:11px 18px;border-bottom:1px solid #F2ECE7}
.mini-row:last-child{border-bottom:none}
.mini-ic{width:34px;height:34px;border-radius:9px;flex:none;display:grid;place-items:center;font-size:14px}
.mi-OUT{background:var(--dangerbg)}
.mi-EXPIRED{background:var(--goldbg)}
.mi-ADJUSTMENT{background:#E0F2FE}
.mini-body{flex:1;min-width:0}
.mini-med{font-size:12.5px;font-weight:750;color:var(--ink);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.mini-meta{font-size:11px;color:var(--muted);margin-top:2px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.mini-qty{font-size:13.5px;font-weight:800;flex:none;font-variant-numeric:tabular-nums}
.q-neg{color:var(--danger)}.q-pos{color:var(--ok)}
.mini-empty{padding:28px 20px;text-align:center;color:var(--muted);font-size:12.5px}
</style>
<meta name="csrf-token" content="${csrfToken}">
<script src="${pageContext.request.contextPath}/js/csrf.js"></script>
</head>
<body class="wh">
<%@ include file="warehouse-sidebar.jsp" %>
<div class="main">

<header class="wh-topbar">
  <div class="crumb">📦 Xuất kho &amp; Điều chỉnh tồn</div>
  <div class="right">
    <a href="${pageContext.request.contextPath}/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc"><%= initials %></a>
  </div>
</header>

<div class="wh-content">
 <div class="wrap">

  <p class="page-intro">
    <span class="pi-ic">🔒</span>
    <span>Hệ thống chỉ định lô theo <b>FEFO</b> (hạn dùng gần nhất) — bạn phải quét/nhập <b>đúng số lô đó</b> mới được xác nhận. Sai lô sẽ bị chặn, không trừ kho.</span>
  </p>

  <c:if test="${not empty error}">
    <div class="alert alert-err">⚠️ <c:out value="${error}"/></div>
  </c:if>
  <c:if test="${param.msg == 'success'}">
    <div class="alert alert-ok">✅ Đã ghi nhận thao tác thành công. Tồn kho lô đã được cập nhật.</div>
  </c:if>

  <div class="sm-grid">

    <!-- ══ CỘT 1: Form thao tác ══ -->
    <div class="card">
      <div class="card-head">
        <div class="wh-ic">📤</div>
        <h2>Thao tác xuất kho / điều chỉnh</h2>
      </div>
      <div class="card-body">
        <form method="post" action="${pageContext.request.contextPath}/warehouse-stock-movement" id="mvForm">
          <input type="hidden" name="_csrf" value="${csrfToken}">
          <input type="hidden" name="uid" value="<%= uid %>"/>

          <div class="fg">
            <label>Thuốc</label>
            <div class="wh-field">
              <span class="wh-field-ic">💊</span>
              <select name="medicineId" id="medicineSelect" required onchange="loadSuggestedBatch()">
                <option value="">— Chọn thuốc —</option>
                <c:forEach var="m" items="${medicines}">
                  <option value="${m.medicineId}" ${f_medicineId == m.medicineId ? 'selected' : ''}>
                    ${m.medicineName} (Tồn: ${m.totalStock})
                  </option>
                </c:forEach>
              </select>
            </div>
          </div>

          <!-- FEFO nudge: nhắc lấy đúng lô hệ thống chỉ định -->
          <div class="fefo-nudge" id="fefoNudge">
            <span class="fn-ic">💡</span>
            <span>Hệ thống chỉ định lô <b id="fnBatch">—</b> — hãy quét/nhập <b>đúng lô này</b> (chi tiết ở panel bên phải).</span>
          </div>

          <div class="row2">
            <div class="fg">
              <label style="display:flex; justify-content:space-between; align-items:center;">
                  <span>Số lô (quét hoặc nhập tay)</span>
                  <button type="button" onclick="openBarcodeScan()" style="background:none;border:none;color:var(--main);font-size:12px;cursor:pointer;font-weight:700;">📷 Quét mã vạch</button>
              </label>
              <div class="wh-field">
                <span class="wh-field-ic">🏷️</span>
                <input type="text" name="enteredBatchNumber" id="enteredBatchNumber" placeholder="VD: LOT-2026-001"
                       value="${fn:escapeXml(f_enteredBatchNumber)}" autocomplete="off" required/>
              </div>
            </div>
            <div class="fg">
              <label>Số lượng</label>
              <div class="wh-field">
                <span class="wh-field-ic">🔢</span>
                <input type="number" name="quantity" min="1" value="${fn:escapeXml(f_quantity)}" required/>
              </div>
            </div>
          </div>

          <div class="fg">
            <label>Loại thao tác</label>
            <div class="wh-field">
              <span class="wh-field-ic">🔄</span>
              <select name="movementType" id="movementType" required onchange="toggleDirection()">
                <option value="OUT" ${f_movementType == 'OUT' ? 'selected' : ''}>Xuất kho / Hủy hàng</option>
                <option value="EXPIRED" ${f_movementType == 'EXPIRED' ? 'selected' : ''}>Hủy hết hạn</option>
                <option value="ADJUSTMENT" ${f_movementType == 'ADJUSTMENT' ? 'selected' : ''}>Điều chỉnh sau kiểm kê</option>
              </select>
            </div>
          </div>

          <div class="direction-row" id="directionRow">
            <label class="dir-opt">
              <input type="radio" name="adjustDirection" value="DECREASE"
                     ${f_adjustDirection != 'INCREASE' ? 'checked' : ''}/> Kiểm kê THIẾU (giảm tồn)
            </label>
            <label class="dir-opt">
              <input type="radio" name="adjustDirection" value="INCREASE"
                     ${f_adjustDirection == 'INCREASE' ? 'checked' : ''}/> Kiểm kê THỪA (tăng tồn)
            </label>
          </div>

          <div class="fg">
            <label>Lý do</label>
            <textarea name="reason" placeholder="VD: Hộp bị vỡ, phát hiện khi kiểm kê định kỳ...">${fn:escapeXml(f_reason)}</textarea>
          </div>

          <button type="submit" class="btn-submit">Xác nhận thao tác</button>
        </form>
      </div>
    </div>

    <!-- ══ CỘT 2: Panel lô FEFO + lịch sử ══ -->
    <div class="sm-side">
      <div class="card">
        <div class="card-head">
          <div class="wh-ic ok">🎯</div>
          <h2>Lô hệ thống chỉ định</h2>
        </div>
        <div class="batch-empty" id="batchEmpty">
          <div class="be-ic">📦</div>
          <p>Chọn thuốc để xem lô hệ thống chỉ định theo <b>FEFO</b>.</p>
        </div>
        <div class="batch-info" id="batchInfo">
          <div class="bi-tag">🎯 Lô cần lấy (FEFO)</div>
          <div class="bi-batch" id="biBatch">—</div>
          <div class="bi-rows">
            <div class="bi-row">
              <span class="bi-lbl">📅 Hạn dùng</span>
              <span class="bi-val"><span id="biExpiry">—</span><span id="biDays"></span></span>
            </div>
            <div class="bi-row">
              <span class="bi-lbl">📦 Còn tồn trong lô</span>
              <span class="bi-val" id="biQty">—</span>
            </div>
          </div>
          <div class="fefo-note">
            <span class="fnn-ic">✅</span>
            <span>Đây là lô phải lấy theo nguyên tắc <b>hết hạn trước – xuất trước</b>. Quét đúng số lô này để được xác nhận.</span>
          </div>
        </div>
      </div>

      <div class="card">
        <div class="card-head">
          <div class="wh-ic">🕘</div>
          <h2>Lịch sử gần đây <small>7 ngày</small></h2>
        </div>
        <c:choose>
          <c:when test="${empty movementRows}">
            <div class="mini-empty">Chưa có thao tác nào trong 7 ngày gần đây.</div>
          </c:when>
          <c:otherwise>
            <div class="mini-list">
              <c:forEach var="r" items="${movementRows}" varStatus="st" end="6">
                <div class="mini-row">
                  <div class="mini-ic mi-${r.movementType}">
                    <c:choose>
                      <c:when test="${r.movementType == 'OUT'}">📤</c:when>
                      <c:when test="${r.movementType == 'EXPIRED'}">⏱️</c:when>
                      <c:otherwise>⚖️</c:otherwise>
                    </c:choose>
                  </div>
                  <div class="mini-body">
                    <div class="mini-med">${fn:escapeXml(r.medicineName)}</div>
                    <div class="mini-meta">Lô ${fn:escapeXml(r.batchNumber)} · ${r.createdAt}</div>
                  </div>
                  <div class="mini-qty ${r.quantity < 0 ? 'q-neg' : 'q-pos'}">${r.quantity}</div>
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

<!-- Modal Quét Barcode -->
<div id="barcodeScanModal" style="display:none;position:fixed;inset:0;z-index:9700;background:rgba(11,22,40,.7);align-items:center;justify-content:center;padding:20px" onclick="if(event.target===this)closeBarcodeScan()">
  <div style="background:#fff;border-radius:18px;max-width:420px;width:100%;box-shadow:0 24px 70px rgba(0,0,0,.35);overflow:hidden">
    <div style="padding:16px 20px;background:linear-gradient(135deg,#0f766e,#042f2e);color:#fff;display:flex;align-items:center;justify-content:space-between">
      <h3 style="margin:0;font-size:16px;font-weight:800">📷 Quét mã vạch lô</h3>
      <button type="button" onclick="closeBarcodeScan()" style="background:rgba(255,255,255,.18);border:none;color:#fff;width:30px;height:30px;border-radius:9px;font-size:15px;cursor:pointer">✕</button>
    </div>
    <div style="padding:16px 20px">
      <div id="barcodeReaderBox" style="width:100%;min-height:260px;border-radius:12px;overflow:hidden;background:#0b1628"></div>
      <div id="barcodeScanStatus" style="margin-top:10px;font-size:12.5px;color:#64748b;text-align:center">Đưa mã vạch vào giữa khung hình.</div>
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
  document.getElementById('batchInfo').classList.remove('show');
  document.getElementById('fefoNudge').classList.remove('show');
  var empty = document.getElementById('batchEmpty');
  empty.style.display = 'block';
  empty.querySelector('p').innerHTML = msg || 'Chọn thuốc để xem lô hệ thống chỉ định theo <b>FEFO</b>.';
}

function daysBadge(expiry){
  if(!expiry) return '';
  var d = Math.ceil((new Date(expiry) - new Date()) / 86400000);
  var cls = d <= 30 ? 'days-danger' : (d <= 90 ? 'days-warn' : 'days-ok');
  return '<span class="days-badge ' + cls + '">' + (d >= 0 ? 'còn ' + d + ' ngày' : 'ĐÃ HẾT HẠN') + '</span>';
}

function loadSuggestedBatch(){
  var medId = document.getElementById('medicineSelect').value;
  if(!medId){ resetBatchPanel(); return; }
  resetBatchPanel('Đang tải lô hệ thống chỉ định…');
  var ctx = document.querySelector('meta[name=ctx]').content;
  fetch(ctx + '/warehouse-stock-movement?uid=<%= uid %>&action=suggest-batch&medicineId=' + encodeURIComponent(medId))
    .then(function(r){ return r.json(); })
    .then(function(d){
      if(d.ok){
        document.getElementById('batchEmpty').style.display = 'none';
        document.getElementById('biBatch').textContent = d.batchNumber;
        document.getElementById('biExpiry').textContent = d.expiryDate;
        document.getElementById('biDays').innerHTML = daysBadge(d.expiryDate);
        document.getElementById('biQty').textContent = d.currentQuantity;
        document.getElementById('batchInfo').classList.add('show');
        document.getElementById('fnBatch').textContent = d.batchNumber;
        document.getElementById('fefoNudge').classList.add('show');
      } else {
        resetBatchPanel(d.message || 'Không có lô nào khả dụng cho thuốc này.');
      }
    })
    .catch(function(){ resetBatchPanel('Không tải được gợi ý lô — vẫn có thể nhập tay, hệ thống sẽ kiểm tra khi xác nhận.'); });
}

toggleDirection();
<c:if test="${not empty f_medicineId}">loadSuggestedBatch();</c:if>

let barcodeScanner = null;
function openBarcodeScan() {
  document.getElementById('barcodeScanModal').style.display = 'flex';
  const status = document.getElementById('barcodeScanStatus');
  status.textContent = 'Đưa mã vạch vào giữa khung hình…';
  if (typeof Html5Qrcode === 'undefined') {
    status.textContent = '⚠️ Không tải được thư viện quét mã vạch — kiểm tra kết nối mạng.';
    return;
  }
  barcodeScanner = new Html5Qrcode('barcodeReaderBox');
  const config = {
    fps: 10,
    qrbox: { width: 260, height: 140 },
    formatsToSupport: [
      Html5QrcodeSupportedFormats.EAN_13, Html5QrcodeSupportedFormats.EAN_8,
      Html5QrcodeSupportedFormats.CODE_128, Html5QrcodeSupportedFormats.CODE_39,
      Html5QrcodeSupportedFormats.UPC_A, Html5QrcodeSupportedFormats.UPC_E,
      Html5QrcodeSupportedFormats.QR_CODE
    ]
  };
  barcodeScanner.start(
    { facingMode: 'environment' },
    config,
    (decodedText) => {
      document.getElementById('enteredBatchNumber').value = decodedText;
      closeBarcodeScan();
    },
    () => {} // lỗi giải mã từng khung hình — bỏ qua
  ).catch(err => {
    status.textContent = '⚠️ Không mở được camera: ' + (err.message || err);
  });
}
function closeBarcodeScan() {
  document.getElementById('barcodeScanModal').style.display = 'none';
  if (barcodeScanner) {
    const s = barcodeScanner;
    barcodeScanner = null;
    s.stop().then(() => s.clear()).catch(() => {});
  }
}
</script>

</div>
</body>
</html>
