<%@ page contentType="text/html;charset=UTF-8"  pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
    
    
    
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Tạo phiếu trả/hủy hàng — MediCare</title>


<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;--red:#DC2626;--gold:#D97706;--green:#059669;
}
html,body{min-height:100%;font-family:'Plus Jakarta Sans',sans-serif;background:var(--surface);color:var(--ink)}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Plus Jakarta Sans',sans-serif;font-size:16px;font-weight:750;color:var(--ink)}
.btn-back{display:inline-flex;align-items:center;gap:6px;padding:6px 14px;border-radius:9px;border:1.5px solid var(--border);background:var(--white);color:var(--ink);font-size:13px;font-weight:750;text-decoration:none}
.btn-back:hover{border-color:var(--blue);color:var(--blue)}

    
.topbar-right{margin-left:auto}
.user-av-sm{width:32px;height:32px;border-radius:50%;background:linear-gradient(135deg,#3ABDE0,#1558A8);display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.content{max-width:640px;margin:28px auto;padding:0 20px 40px}
.page-title{font-size:24px;font-weight:800;margin-bottom:4px}
.page-sub{font-size:13px;color:var(--muted);margin-bottom:20px}
.error-box{background:#FFF5F5;border:1px solid #FECACA;border-radius:12px;padding:14px 18px;margin-bottom:18px}
.error-box ul{margin:0;padding-left:18px}
.error-box li{font-size:13px;color:#991B1B;margin:3px 0}
.card{background:var(--white);border:1px solid var(--border);border-radius:16px;padding:24px;margin-bottom:16px}
.card-title{font-size:13px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.4px;margin-bottom:14px}
.form-group{display:flex;flex-direction:column;gap:5px;margin-bottom:14px}
.form-label{font-size:12.5px;font-weight:750;color:var(--ink)}
.form-label span{color:var(--red)}
.form-input,.form-select,textarea{padding:10px 12px;border:1.5px solid var(--border);border-radius:10px;font-size:13.5px;font-family:inherit;color:var(--ink);background:var(--white);outline:none;width:100%}
.form-input:focus,.form-select:focus,textarea:focus{border-color:var(--blue)}
.form-hint{font-size:11px;color:var(--muted)}
.form-actions{display:flex;gap:10px;margin-top:6px}
.btn-save{flex:1;height:44px;background:#C2410C;color:#fff;border:none;border-radius:11px;font-size:15px;font-weight:800;cursor:pointer;font-family:inherit}
.btn-save:hover{background:#9A3412}
.btn-cancel{height:44px;padding:0 22px;border:1.5px solid var(--border);border-radius:11px;background:var(--white);color:var(--muted);font-size:14px;font-weight:750;cursor:pointer;font-family:inherit;text-decoration:none;display:inline-flex;align-items:center}
.btn-cancel:hover{border-color:var(--red);color:var(--red)}
.info-row{display:flex;justify-content:space-between;padding:6px 0;font-size:13px}
.info-row .lbl{color:var(--muted)}
.info-row .val{font-weight:750}
.checkbox-row{display:flex;align-items:flex-start;gap:10px;background:var(--surface);border-radius:10px;padding:12px 14px;margin-bottom:14px}
.checkbox-row input{margin-top:2px;accent-color:var(--blue)}
.checkbox-row label{font-size:13px;font-weight:750;cursor:pointer}
.checkbox-row .sub{font-size:11.5px;color:var(--muted);font-weight:400;margin-top:2px}
.choose-grid{display:flex;gap:14px;margin-bottom:16px}
.choose-card{flex:1;background:var(--white);border:1.5px solid var(--border);border-radius:14px;padding:18px}
.choose-card h3{font-size:14px;margin-bottom:10px}
.search-row{display:flex;gap:8px}
.search-row input{flex:1}
.btn-mini{padding:0 16px;background:var(--blue);color:#fff;border:none;border-radius:9px;font-weight:750;font-size:13px;cursor:pointer;font-family:inherit}
.batch-pick{display:block;padding:9px 12px;border:1px solid var(--border);border-radius:9px;margin-top:8px;text-decoration:none;color:var(--ink);font-size:12.5px;transition:all .15s}
.batch-pick:hover{border-color:var(--gold);background:#FFFBEB}
.batch-pick .exp{color:var(--red);font-weight:750;float:right}
.empty-note{font-size:12.5px;color:var(--muted);padding:8px 0}
select,option{font-family:inherit;font-size:inherit}
.cdd{position:relative;user-select:none;display:inline-block}
.cdd-btn{display:flex;align-items:center;gap:6px;padding:9px 14px;background:var(--white,#fff);border:1.5px solid var(--border,#D5E0F0);border-radius:10px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;font-weight:750;color:var(--ink,#0B1628);cursor:pointer;transition:all .18s;white-space:nowrap}
.cdd-btn:hover{border-color:var(--cyan,#3ABDE0);background:var(--cyan-soft,#EBF8FD)}
.cdd-btn.open{border-color:var(--cyan,#3ABDE0);box-shadow:0 0 0 3px rgba(58,189,224,.12)}
.cdd-arrow{font-size:9px;color:var(--muted,#7A90B0);transition:transform .2s}
.cdd-btn.open .cdd-arrow{transform:rotate(180deg)}
.cdd-menu{position:absolute;top:calc(100% + 6px);left:0;min-width:100%;background:var(--white,#fff);border:1.5px solid var(--border,#D5E0F0);border-radius:12px;padding:6px;box-shadow:0 12px 36px rgba(15,38,69,.15);z-index:200;opacity:0;transform:translateY(-6px);pointer-events:none;transition:all .18s ease;max-height:260px;overflow-y:auto}
.cdd-menu.show{opacity:1;transform:translateY(0);pointer-events:auto}
.cdd-menu::-webkit-scrollbar{width:4px}
.cdd-menu::-webkit-scrollbar-thumb{background:var(--border,#D5E0F0);border-radius:4px}
.cdd-opt{padding:8px 14px;border-radius:8px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;font-weight:600;color:var(--ink,#0B1628);cursor:pointer;transition:all .12s;white-space:nowrap}
.cdd-opt:hover{background:var(--surface,#F1F5FB);color:var(--blue,#1558A8)}
.cdd-opt.active{background:linear-gradient(135deg,var(--blue,#1558A8),#0D3F85);color:#fff;font-weight:750}
</style>
    
</head>
<body>
<div class="topbar">
  <a href="${pageContext.request.contextPath}/returns" class="btn-back">← Trả hàng</a>
  <span class="topbar-title">↩️ Tạo phiếu</span>
  <div class="topbar-right"><div class="user-av-sm"><%= initials %></div></div>
</div>

<div class="content">

  <c:if test="${not empty errors}">
    <div class="error-box"><ul><c:forEach var="e" items="${errors}"><li>${e}</li></c:forEach></ul></div>
  </c:if>

  <%-- ════════════════ MODE: CHOOSE ════════════════ --%>
  <c:if test="${mode == 'CHOOSE'}">
    <div class="page-title">↩️ Tạo phiếu trả / hủy hàng</div>
    <div class="page-sub">Chọn 1 trong 2 luồng dưới đây tùy theo tình huống thực tế.</div>

    <c:if test="${not empty searchError}">
      <div class="error-box"><ul><li>${searchError}</li></ul></div>
    </c:if>

    <div class="choose-grid">
      <div class="choose-card">
        <h3>🧾 Khách trả hàng</h3>
        <p class="form-hint" style="margin-bottom:10px">Nhập mã hóa đơn đã bán để chọn dòng hàng cần trả.</p>
        <form method="get" action="${pageContext.request.contextPath}/returns" class="search-row">
          <input type="hidden" name="action" value="new"/>
          <input type="text" name="invoiceCode" class="form-input" placeholder="VD: HD000123" required>
          <button type="submit" class="btn-mini">Tìm</button>
        </form>
      </div>
      <div class="choose-card">
        <h3>🗑️ Hủy hết hạn / Thu hồi</h3>
        <p class="form-hint">Chọn 1 lô bên dưới (đã hết hạn hoặc sắp hết hạn):</p>
        <c:if test="${empty expiringBatches}">
          <div class="empty-note">Hiện không có lô nào hết hạn hoặc sắp hết hạn.</div>
        </c:if>
        <c:forEach var="b" items="${expiringBatches}" varStatus="st">
          <c:if test="${st.index < 8}">
            <a href="${pageContext.request.contextPath}/returns?action=new&batchId=${b.batchId}" class="batch-pick">
              <strong>${medMapChoose[b.medicineId] != null ? medMapChoose[b.medicineId].medicineName : 'Thuốc #' += b.medicineId}</strong>
              <span class="exp">HSD ${b.expiryDate}</span><br>
              <span style="color:var(--muted)">Lô ${b.batchNumber} · Còn ${b.currentQuantity}</span>
            </a>
          </c:if>
        </c:forEach>
      </div>
    </div>
  </c:if>

  <%-- ════════════════ MODE: CUSTOMER_RETURN ════════════════ --%>
  <c:if test="${mode == 'CUSTOMER_RETURN'}">
    <div class="page-title">🧾 Khách trả hàng</div>
    <div class="page-sub">Hóa đơn <strong>${invoice.invoiceCode}</strong> — chọn dòng hàng khách muốn trả.</div>

    <form method="post" action="${pageContext.request.contextPath}/returns" id="returnForm">
      <input type="hidden" name="action" value="save"/>
      <input type="hidden" name="returnType" value="CUSTOMER_RETURN"/>
      <input type="hidden" name="invoiceId" value="${invoice.invoiceId}"/>

      <div class="card">
        <div class="card-title">Chọn dòng hàng</div>
        <div class="form-group">
          <label class="form-label">Sản phẩm <span>*</span></label>
          <select name="batchId" id="batchSelect" class="form-select" onchange="updateMaxQty()" required>
            <option value="">-- Chọn sản phẩm đã bán --</option>
            <c:forEach var="d" items="${details}">
              <c:set var="remain" value="${returnableMap[d.batchId]}"/>
              <option value="${d.batchId}" data-max="${remain}"
                ${preservedBatchId == d.batchId ? 'selected' : ''}
                ${remain == 0 ? 'disabled' : ''}>
                ${d.medicineName} — Lô ${d.batchNumber} (còn được trả: ${remain}/${d.quantity})
              </option>
            </c:forEach>
          </select>
          <span class="form-hint" id="maxHint"></span>
        </div>
        <div class="form-group">
          <label class="form-label">Số lượng trả <span>*</span></label>
          <input type="number" name="quantity" id="qtyInput" class="form-input" min="1"
                 value="${not empty preservedQty ? preservedQty : ''}" required>
        </div>
        <div class="checkbox-row">
          <input type="checkbox" name="restoreStock" id="restoreStock">
          <label for="restoreStock">Hàng còn nguyên, có thể bán lại
            <div class="sub">Tích nếu thuốc chưa mở/còn hạn, sẽ cộng lại vào tồn kho. Bỏ trống nếu hàng hỏng/không bán lại được.</div>
          </label>
        </div>
        <div class="form-group">
          <label class="form-label">Lý do trả hàng <span>*</span></label>
          <textarea name="reason" rows="2" placeholder="VD: Khách đổi ý, bác sĩ đổi đơn thuốc..." required>${preservedReason}</textarea>
        </div>
      </div>

      <div class="form-actions">
        <a href="${pageContext.request.contextPath}/returns" class="btn-cancel">Hủy</a>
        <button type="submit" class="btn-save">↩️ Xác nhận trả hàng</button>
      </div>
    </form>
  </c:if>

  <%-- ════════════════ MODE: WRITE_OFF ════════════════ --%>
  <c:if test="${mode == 'WRITE_OFF'}">
    <div class="page-title">🗑️ Hủy hàng hết hạn / Thu hồi</div>
    <div class="page-sub">${medicine != null ? medicine.medicineName : ''} — Lô ${batch.batchNumber}</div>

    <div class="card">
      <div class="info-row"><span class="lbl">Hạn sử dụng</span><span class="val" style="color:var(--red)">${batch.expiryDate}</span></div>
      <div class="info-row"><span class="lbl">Tồn kho hiện tại</span><span class="val">${batch.currentQuantity}</span></div>
    </div>

    <form method="post" action="${pageContext.request.contextPath}/returns">
      <input type="hidden" name="action" value="save"/>
      <input type="hidden" name="batchId" value="${batch.batchId}"/>

      <div class="card">
        <div class="card-title">Thông tin hủy</div>
        <div class="form-group">
          <label class="form-label">Loại <span>*</span></label>
          <input type="hidden" name="returnType" id="hReturnType" value="EXPIRED_DESTROY">
          <div class="cdd" id="cddReturnType">
            <div class="cdd-btn" onclick="toggleCdd('cddReturnType')">
              <span class="cdd-label">🗑️ Hết hạn — tiêu hủy</span>
              <span class="cdd-arrow">▼</span>
            </div>
            <div class="cdd-menu">
              <div class="cdd-opt active" data-val="EXPIRED_DESTROY" onclick="pickCdd('cddReturnType','hReturnType',this,false)">🗑️ Hết hạn — tiêu hủy</div>
              <div class="cdd-opt" data-val="RECALL" onclick="pickCdd('cddReturnType','hReturnType',this,false)">⚠️ Thu hồi theo yêu cầu NSX/cơ quan y tế</div>
            </div>
          </div>
        </div>
        <div class="form-group">
          <label class="form-label">Số lượng hủy <span>*</span></label>
          <input type="number" name="quantity" class="form-input" min="1" max="${batch.currentQuantity}"
                 value="${not empty preservedQty ? preservedQty : batch.currentQuantity}" required>
          <span class="form-hint">Tối đa ${batch.currentQuantity} (toàn bộ tồn kho lô này)</span>
        </div>
        <div class="form-group">
          <label class="form-label">Lý do <span>*</span></label>
          <textarea name="reason" rows="2" placeholder="VD: Hết hạn sử dụng, thu hồi theo công văn số..." required>${preservedReason}</textarea>
        </div>
      </div>

      <div class="form-actions">
        <a href="${pageContext.request.contextPath}/returns" class="btn-cancel">Hủy</a>
        <button type="submit" class="btn-save">🗑️ Xác nhận hủy hàng</button>
      </div>
    </form>
  </c:if>

</div>

<script>
function toggleCdd(id){var w=document.getElementById(id),m=w.querySelector('.cdd-menu'),b=w.querySelector('.cdd-btn');var open=m.classList.contains('show');document.querySelectorAll('.cdd-menu.show').forEach(function(x){x.classList.remove('show');x.closest('.cdd').querySelector('.cdd-btn').classList.remove('open')});if(!open){m.classList.add('show');b.classList.add('open');var act=m.querySelector('.cdd-opt.active');if(act)act.scrollIntoView({block:'nearest'})}}
function pickCdd(wId,hId,el,autoSubmit){document.getElementById(hId).value=el.dataset.val;var w=document.getElementById(wId);w.querySelector('.cdd-label').textContent=el.textContent;w.querySelectorAll('.cdd-opt').forEach(function(o){o.classList.remove('active')});el.classList.add('active');w.querySelector('.cdd-menu').classList.remove('show');w.querySelector('.cdd-btn').classList.remove('open');if(autoSubmit){var f=w.closest('form');if(f)f.submit()}}
document.addEventListener('click',function(e){if(!e.target.closest('.cdd')){document.querySelectorAll('.cdd-menu.show').forEach(function(m){m.classList.remove('show');m.closest('.cdd').querySelector('.cdd-btn').classList.remove('open')})}});

function updateMaxQty() {
  const sel = document.getElementById('batchSelect');
  const opt = sel.options[sel.selectedIndex];
  const qtyInput = document.getElementById('qtyInput');
  const hint = document.getElementById('maxHint');
  if (opt && opt.dataset.max) {
    qtyInput.max = opt.dataset.max;
    hint.textContent = 'Tối đa ' + opt.dataset.max + ' (số lượng còn được trả của dòng này)';
  } else {
    qtyInput.removeAttribute('max');
    hint.textContent = '';
  }
}
if (document.getElementById('batchSelect')) updateMaxQty();
</script>
</body>
</html>

