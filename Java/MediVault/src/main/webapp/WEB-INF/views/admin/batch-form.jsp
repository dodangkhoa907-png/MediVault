<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
    com.medicare.entity.Batches b = (com.medicare.entity.Batches) request.getAttribute("batch");
    boolean isNew = (b == null || b.getBatchId() == 0);
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title><%= isNew ? "Nhập lô mới" : "Sửa lô hàng" %> — medicare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&family=DM+Serif+Display:ital@0;1&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;
}
html,body{min-height:100%;font-family:'Outfit',sans-serif;background:var(--surface);color:var(--ink)}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Outfit',sans-serif;font-size:16px;font-weight:700;color:var(--ink)}
.btn-back{display:inline-flex;align-items:center;gap:6px;padding:6px 14px;border-radius:9px;border:1.5px solid var(--border);background:var(--white);color:var(--ink);font-size:13px;font-weight:600;text-decoration:none}
.btn-back:hover{border-color:var(--blue);color:var(--blue)}

    
.topbar-right{margin-left:auto}
.user-av-sm{width:32px;height:32px;border-radius:50%;background:linear-gradient(135deg,#3ABDE0,#1558A8);display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.content{max-width:640px;margin:28px auto;padding:0 20px 40px}
.page-title{font-family:'DM Serif Display',serif;font-size:24px;margin-bottom:4px}
.page-sub{font-size:13px;color:var(--muted);margin-bottom:20px}
.med-chip{display:inline-flex;align-items:center;gap:7px;padding:8px 14px;background:var(--white);border:1.5px solid var(--border);border-radius:10px;margin-bottom:20px}
.med-chip-name{font-size:14px;font-weight:700;color:var(--navy)}
.med-chip-code{font-size:12px;color:var(--muted);font-family:monospace}
.error-box{background:#FFF5F5;border:1px solid #FECACA;border-radius:12px;padding:14px 18px;margin-bottom:18px}
.error-box ul{margin:0;padding-left:18px}
.error-box li{font-size:13px;color:#991B1B;margin:3px 0}
.card{background:var(--white);border:1px solid var(--border);border-radius:16px;padding:24px;margin-bottom:14px}
.card-title{font-size:14px;font-weight:800;color:var(--navy);margin-bottom:16px;padding-bottom:10px;border-bottom:1px solid var(--border)}
.form-grid{display:grid;grid-template-columns:1fr 1fr;gap:14px}
.form-full{grid-column:1/-1}
.form-group{display:flex;flex-direction:column;gap:5px}
.form-label{font-size:12.5px;font-weight:700;color:var(--ink)}
.form-label span{color:var(--red)}
.form-input,.form-select{height:40px;padding:0 12px;border:1.5px solid var(--border);border-radius:10px;font-size:13.5px;font-family:inherit;color:var(--ink);background:var(--white);outline:none;transition:.15s}
.form-input:focus,.form-select:focus{border-color:var(--blue)}
.form-hint{font-size:11px;color:var(--muted)}
.alert-box{background:#FFFBEB;border:1px solid #FDE68A;border-radius:10px;padding:12px 14px;font-size:13px;color:#92400E;margin-bottom:14px}
.form-actions{display:flex;gap:10px;margin-top:20px}
.btn-save{flex:1;height:44px;background:var(--blue);color:#fff;border:none;border-radius:11px;font-size:15px;font-weight:800;cursor:pointer;font-family:inherit}
.btn-save:hover{background:#0d3d63}
.btn-cancel{height:44px;padding:0 22px;border:1.5px solid var(--border);border-radius:11px;background:var(--white);color:var(--muted);font-size:14px;font-weight:600;cursor:pointer;font-family:inherit;text-decoration:none;display:inline-flex;align-items:center}
.btn-cancel:hover{border-color:var(--red);color:var(--red)}
.po-toggle{display:flex;gap:10px;margin-bottom:16px}
.po-toggle-opt{flex:1;display:flex;align-items:center;gap:8px;padding:10px 14px;border:1.5px solid var(--border);border-radius:10px;font-size:13px;font-weight:600;color:var(--ink);cursor:pointer;transition:.15s}
.po-toggle-opt:has(input:checked){border-color:var(--blue);background:#EFF6FF;color:var(--blue)}
.po-toggle-opt input{accent-color:var(--blue)}
.po-toggle-opt input:disabled{cursor:not-allowed}
.po-toggle-opt:has(input:disabled){opacity:.45;cursor:not-allowed}
</style>
</head>
<body>
<%@ include file="/WEB-INF/views/loading.jsp" %>

<div class="topbar">
  <a href="${pageContext.request.contextPath}/medicines?action=detail&id=${medicine.medicineId}" class="btn-back">
    ← ${medicine.medicineName}
  </a>
  <span class="topbar-title"><%= isNew ? "Nhập lô mới" : "Sửa lô hàng" %></span>
  <div class="topbar-right">
    <div class="user-av-sm"><%= initials %></div>
  </div>
</div>

<div class="content">
  <div class="page-title"><%= isNew ? "📦 Nhập lô hàng mới" : "✏️ Sửa thông tin lô" %></div>
  <div class="med-chip">
    <span>💊</span>
    <div>
      <div class="med-chip-name">${medicine.medicineName}</div>
      <div class="med-chip-code">${medicine.medicineCode} · ${medicine.unit}</div>
    </div>
  </div>

  <c:if test="${not empty errors}">
    <div class="error-box">
      <ul><c:forEach var="e" items="${errors}"><li>${e}</li></c:forEach></ul>
    </div>
  </c:if>

  <c:if test="${not isNew}">
    <div class="alert-box">
      ⚠️ Lưu ý: Chỉ được sửa số lô, ngày tháng và giá nhập. Số lượng không thể thay đổi sau khi nhập kho.
    </div>
  </c:if>

  <form method="post" action="${pageContext.request.contextPath}/medicines">
    <input type="hidden" name="action" value="save-batch"/>
    <input type="hidden" name="medicineId" value="${medicine.medicineId}"/>
    <c:if test="${batch != null && batch.batchId != 0}">
      <input type="hidden" name="batchId" value="${batch.batchId}"/>
    </c:if>

    <div class="card">
      <div class="card-title">📋 Thông tin lô</div>
      <div class="form-grid">
        <div class="form-group form-full">
          <label class="form-label">Số lô <span>*</span></label>
          <input type="text" name="batchNumber" class="form-input"
                 placeholder="VD: LOT-2026-001"
                 value="${batch != null ? batch.batchNumber : ''}" required/>
        </div>
        <div class="form-group">
          <label class="form-label">Ngày sản xuất</label>
          <input type="date" name="manufactureDate" class="form-input"
                 value="${batch != null && batch.manufactureDate != null ? batch.manufactureDate : ''}"/>
        </div>
        <div class="form-group">
          <label class="form-label">Ngày hết hạn <span>*</span></label>
          <input type="date" name="expiryDate" id="expiryDateInp" class="form-input"
                 value="${batch != null ? batch.expiryDate : ''}" required
                 oninput="checkHsd(this)"/>
          <div id="hsdWarn" style="display:none;margin-top:6px;padding:8px 12px;border-radius:8px;font-size:12.5px;font-weight:600"></div>
        </div>
        <div class="form-group">
          <label class="form-label">Giá nhập (₫) <span>*</span></label>
          <input type="number" name="importPrice" class="form-input"
                 placeholder="0" min="0" step="100"
                 value="${batch != null ? batch.importPrice : ''}" required/>
        </div>
        <c:if test="${not isNew}">
        <div class="form-group">
          <label class="form-label">Ngày nhập kho</label>
          <input type="text" class="form-input" value="${batch.importDate}" disabled
                 style="background:#F8FAFC;color:var(--muted);cursor:default"/>
          <span class="form-hint">Ngày nhập được ghi nhận tự động khi tạo lô, không thể thay đổi</span>
        </div>
        </c:if>
      </div>
    </div>

    <c:if test="${isNew}">
    <div class="card">
      <div class="card-title">📑 Thuộc đơn đặt hàng nào?</div>
      <div class="po-toggle">
        <label class="po-toggle-opt">
          <input type="radio" name="poMode" value="existing" onchange="togglePoMode()" ${empty recentPOs ? 'disabled' : ''}>
          <span>Chọn đơn có sẵn</span>
        </label>
        <label class="po-toggle-opt">
          <input type="radio" name="poMode" value="new" checked onchange="togglePoMode()">
          <span>Tạo đơn mới</span>
        </label>
      </div>

      <div id="poExistingBlock" class="form-group" style="display:none">
        <label class="form-label">Đơn đặt hàng <span>*</span></label>
        <select name="poId" class="form-select">
          <option value="">-- Chọn đơn --</option>
          <c:forEach var="p" items="${recentPOs}">
            <option value="${p.poId}">${p.poCode} · ${poSupplierMap[p.supplierId] != null ? poSupplierMap[p.supplierId].supplierName : ''} · ${fn:substring(p.orderDate.toString(),0,10)}</option>
          </c:forEach>
        </select>
        <span class="form-hint">Chỉ hiện 15 đơn gần nhất. Vào "Đơn đặt hàng" ở sidebar để xem tất cả.</span>
      </div>

      <div id="poNewBlock">
        <div class="form-group">
          <label class="form-label">Nhà cung cấp <span>*</span></label>
          <select name="newPoSupplierId" class="form-select">
            <option value="">-- Chọn nhà cung cấp --</option>
            <c:forEach var="s" items="${suppliers}">
              <option value="${s.supplierId}">${s.supplierName}</option>
            </c:forEach>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">Ghi chú đơn (không bắt buộc)</label>
          <input type="text" name="newPoNotes" class="form-input" placeholder="VD: Đặt hàng định kỳ tháng 6">
        </div>
        <span class="form-hint">Hệ thống sẽ tự tạo 1 đơn đặt hàng mới và gắn lô này vào đó.</span>
      </div>
    </div>
    </c:if>

    <c:if test="${isNew}">
      <div class="card">
        <div class="card-title">📊 Số lượng nhập</div>
        <div class="form-group">
          <label class="form-label">Số lượng nhập kho <span>*</span></label>
          <input type="number" name="initialQuantity" class="form-input"
                 placeholder="0" min="1" required style="max-width:200px"/>
          <span class="form-hint">Đơn vị: ${medicine.unit} — Không thể thay đổi sau khi lưu</span>
        </div>
      </div>
    </c:if>

    <c:if test="${not isNew}">
    <div class="card" style="border-color:#E5E7EB;background:#FAFBFD">
      <div class="card-title" style="color:var(--muted)">📊 Thông tin tồn kho (chỉ đọc)</div>
      <div class="form-grid">
        <div class="form-group">
          <label class="form-label">Số lượng nhập ban đầu</label>
          <input type="text" class="form-input" value="${batch.initialQuantity} ${medicine.unit}" disabled
                 style="background:#F8FAFC;color:var(--muted);cursor:default"/>
        </div>
        <div class="form-group">
          <label class="form-label">Tồn kho hiện tại</label>
          <input type="text" class="form-input" value="${batch.currentQuantity} ${medicine.unit}" disabled
                 style="background:#F8FAFC;color:var(--muted);cursor:default"/>
        </div>
      </div>
      <div class="form-hint" style="margin-top:8px">💡 Để nhập thêm hàng vào lô này, dùng nút <strong>＋ Nhập thêm</strong> trên trang danh sách lô.</div>
    </div>
    </c:if>

    <div class="form-actions">
      <a href="${pageContext.request.contextPath}/medicines?action=detail&id=${medicine.medicineId}"
         class="btn-cancel">Hủy</a>
      <button type="submit" class="btn-save">
        <%= isNew ? "📦 Xác nhận nhập kho" : "💾 Lưu thay đổi" %>
      </button>
    </div>
  </form>
</div>
<script>
// Bug 1 fix: chỉ block form submission khi isNew (nhập lô mới)
const IS_NEW_BATCH = <%= isNew %>;

function checkHsd(inp) {
  const warn = document.getElementById('hsdWarn');
  if (!inp.value) { warn.style.display = 'none'; inp.setCustomValidity(''); return; }
  const today = new Date(); today.setHours(0,0,0,0);
  const hsd = new Date(inp.value);
  const diffDays = Math.round((hsd - today) / 86400000);
  if (diffDays < 0) {
    warn.style.cssText = 'display:block;margin-top:6px;padding:8px 12px;border-radius:8px;font-size:12.5px;font-weight:600;background:#FEE2E2;color:#991B1B;border:1px solid #FECACA';
    warn.textContent = IS_NEW_BATCH ? '❌ Ngày hết hạn đã qua! Không thể nhập lô hết hạn.' : '⚠️ Ngày hết hạn đã qua — lô này đã hết hạn.';
    inp.setCustomValidity(IS_NEW_BATCH ? 'Ngày hết hạn đã qua' : '');
  } else if (diffDays < 90) {
    warn.style.cssText = 'display:block;margin-top:6px;padding:8px 12px;border-radius:8px;font-size:12.5px;font-weight:600;background:#FFFBEB;color:#92400E;border:1px solid #FDE68A';
    warn.textContent = '⚠️ HSD chỉ còn ' + diffDays + ' ngày' + (IS_NEW_BATCH ? ' — GPP yêu cầu ≥ 90 ngày khi nhập kho!' : '');
    inp.setCustomValidity(IS_NEW_BATCH ? 'HSD phải còn ít nhất 90 ngày' : '');
  } else {
    warn.style.display = 'none';
    inp.setCustomValidity('');
  }
}
document.addEventListener('DOMContentLoaded', function() {
  const inp = document.getElementById('expiryDateInp');
  if (inp && inp.value) checkHsd(inp);
});

function togglePoMode() {
  const existingBlock = document.getElementById('poExistingBlock');
  if (!existingBlock) return; // chế độ sửa lô — không có thẻ chọn đơn đặt hàng
  const mode = document.querySelector('input[name="poMode"]:checked');
  const isExisting = mode && mode.value === 'existing';
  existingBlock.style.display = isExisting ? 'flex' : 'none';
  document.getElementById('poNewBlock').style.display = isExisting ? 'none' : 'block';
  document.querySelector('select[name="poId"]').required = isExisting;
  document.querySelector('select[name="newPoSupplierId"]').required = !isExisting;
}
togglePoMode();
</script>
</body>
</html>
