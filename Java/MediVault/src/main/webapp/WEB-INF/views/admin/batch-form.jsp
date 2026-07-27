<%@ page contentType="text/html;charset=UTF-8"  pageEncoding="UTF-8" %>
<% String activeNav = "medicines"; %>
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
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
    
    
    
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title><%= isNew ? "Nhập lô mới" : "Sửa lô hàng" %> — MediCare</title>


<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;--sidebar:232px;
}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}

/* ── Sidebar (dùng chung admin) ── */
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-text{font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-text span{color:var(--cyan)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:12px 0 4px;flex-shrink:0}
.nav-label{font-size:9px;font-weight:750;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:750;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.14);font-weight:750}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--cyan);border-radius:2px}
.nav-badge{margin-left:auto;background:#DC2626;color:#fff;font-size:10px;font-weight:750;padding:1px 7px;border-radius:20px;min-width:20px;text-align:center}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0}

.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50;flex-shrink:0}
.topbar-title{font-size:16px;font-weight:750;color:var(--ink)}
.btn-back{display:inline-flex;align-items:center;gap:6px;padding:6px 14px;border-radius:9px;border:1.5px solid var(--border);background:var(--white);color:var(--ink);font-size:13px;font-weight:750;text-decoration:none}
.btn-back:hover{border-color:var(--blue);color:var(--blue)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:12px}
.clock{display:inline-flex;align-items:center;gap:8px;padding:6px 13px;border-radius:20px;background:#EFF6FF;color:var(--blue);font-size:12.5px;font-weight:750;white-space:nowrap}
.clock .cl-time{font-variant-numeric:tabular-nums;font-weight:800}
.user-av-sm{width:32px;height:32px;border-radius:50%;background:linear-gradient(135deg,#3ABDE0,#1558A8);display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}

.content{max-width:720px;margin:26px auto;padding:0 22px 48px}
.page-title{font-size:23px;font-weight:800;margin-bottom:4px}
.page-sub{font-size:13px;color:var(--muted);margin-bottom:18px}
.med-chip{display:flex;align-items:center;gap:12px;padding:13px 16px;background:linear-gradient(120deg,#0F2645,#1558A8);border-radius:14px;margin-bottom:18px;color:#fff}
.med-chip-ico{width:40px;height:40px;border-radius:11px;background:rgba(255,255,255,.15);display:flex;align-items:center;justify-content:center;font-size:20px;flex-shrink:0}
.med-chip-name{font-size:15.5px;font-weight:800}
.med-chip-code{font-size:12px;opacity:.85;font-family:monospace;margin-top:1px}
.error-box{background:#FFF5F5;border:1px solid #FECACA;border-radius:12px;padding:14px 18px;margin-bottom:18px}
.error-box ul{margin:0;padding-left:18px}
.error-box li{font-size:13px;color:#991B1B;margin:3px 0}
.card{background:var(--white);border:1px solid var(--border);border-radius:16px;padding:22px 24px;margin-bottom:14px}
.card-title{font-size:14px;font-weight:800;color:var(--navy);margin-bottom:5px;display:flex;align-items:center;gap:8px}
.card-desc{font-size:12px;color:var(--muted);margin-bottom:16px;padding-bottom:12px;border-bottom:1px dashed var(--border)}
.form-grid{display:grid;grid-template-columns:1fr 1fr;gap:14px}
.form-full{grid-column:1/-1}
.form-group{display:flex;flex-direction:column;gap:5px}
.form-label{font-size:12.5px;font-weight:750;color:var(--ink)}
.form-label span{color:var(--red)}
.form-input,.form-select{height:42px;padding:0 12px;border:1.5px solid var(--border);border-radius:10px;font-size:13.5px;font-family:inherit;color:var(--ink);background:var(--white);outline:none;transition:.15s}
.form-input:focus,.form-select:focus{border-color:var(--blue);box-shadow:0 0 0 3px rgba(21,88,168,.08)}
.form-hint{font-size:11px;color:var(--muted)}
.alert-box{background:#FFFBEB;border:1px solid #FDE68A;border-radius:10px;padding:12px 14px;font-size:13px;color:#92400E;margin-bottom:14px}
.form-actions{display:flex;gap:10px;margin-top:20px}
.btn-save{flex:1;height:46px;background:linear-gradient(135deg,#1558A8,#0d3d63);color:#fff;border:none;border-radius:11px;font-size:15px;font-weight:800;cursor:pointer;font-family:inherit}
.btn-save:hover{filter:brightness(1.08)}
.btn-cancel{height:46px;padding:0 22px;border:1.5px solid var(--border);border-radius:11px;background:var(--white);color:var(--muted);font-size:14px;font-weight:750;cursor:pointer;font-family:inherit;text-decoration:none;display:inline-flex;align-items:center}
.btn-cancel:hover{border-color:var(--red);color:var(--red)}
.po-toggle{display:flex;gap:10px;margin-bottom:16px}
.po-toggle-opt{flex:1;display:flex;align-items:center;gap:8px;padding:11px 14px;border:1.5px solid var(--border);border-radius:10px;font-size:13px;font-weight:750;color:var(--ink);cursor:pointer;transition:.15s}
.po-toggle-opt:has(input:checked){border-color:var(--blue);background:#EFF6FF;color:var(--blue)}
.po-toggle-opt input{accent-color:var(--blue)}
.po-toggle-opt input:disabled{cursor:not-allowed}
.po-toggle-opt:has(input:disabled){opacity:.45;cursor:not-allowed}
.hsd-live{margin-top:6px;padding:8px 12px;border-radius:8px;font-size:12.5px;font-weight:750;display:none}
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
    
<meta name="csrf-token" content="${csrfToken}">
<script src="${pageContext.request.contextPath}/js/csrf.js"></script>
</head>
<body>
<%@ include file="/WEB-INF/views/loading.jsp" %>
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">
<div class="topbar">
  <a href="${pageContext.request.contextPath}/medicines?action=detail&id=${medicine.medicineId}" class="btn-back">← ${medicine.medicineName}</a>
  <span class="topbar-title"><%= isNew ? "Nhập lô mới" : "Sửa lô hàng" %></span>
  <div class="topbar-right">
    <span class="clock">🕐 <span id="clkDate"></span> · <span class="cl-time" id="clkTime"></span></span>
    <div class="user-av-sm"><%= initials %></div>
  </div>
</div>

<div class="content">
  <div class="page-title"><%= isNew ? "📦 Nhập lô hàng mới" : "✏️ Sửa thông tin lô" %></div>
  <div class="page-sub"><%= isNew ? "Nhập hàng vật lý vào kho — mỗi lô có số lô, hạn dùng và số lượng riêng." : "Chỉ sửa được số lô, ngày tháng và giá nhập." %></div>

  <div class="med-chip">
    <div class="med-chip-ico">💊</div>
    <div>
      <div class="med-chip-name">${medicine.medicineName}</div>
      <div class="med-chip-code">${medicine.medicineCode} · ${medicine.unit}</div>
    </div>
  </div>

  <c:if test="${not empty errors}">
    <div class="error-box"><ul><c:forEach var="e" items="${errors}"><li>${e}</li></c:forEach></ul></div>
  </c:if>
  <c:if test="${not empty expiryWarning}">
    <div class="alert-box">⚠️ HSD dưới ngưỡng cảnh báo. Nhấn <strong>Xác nhận nhập kho</strong> lần nữa để xác nhận nhập lô này.</div>
  </c:if>

  <c:if test="${not isNew}">
    <div class="alert-box">⚠️ Chỉ được sửa số lô, ngày tháng và giá nhập. Số lượng không thể thay đổi sau khi nhập kho.</div>
  </c:if>

  <form method="post" action="${pageContext.request.contextPath}/medicines">
    <input type="hidden" name="_csrf" value="${csrfToken}">
    <input type="hidden" name="action" value="save-batch"/>
    <input type="hidden" name="medicineId" value="${medicine.medicineId}"/>
    <c:if test="${batch != null && batch.batchId != 0}">
      <input type="hidden" name="batchId" value="${batch.batchId}"/>
    </c:if>
    <input type="hidden" name="forceShortExpiry" id="forceShortExpiry" value="false"/>

    <%-- ① NGUỒN NHẬP — nhà cung cấp / đơn đặt hàng (đặt đầu cho rõ "hàng ở đâu ra") --%>
    <c:if test="${isNew}">
    <div class="card">
      <div class="card-title">🏭 Nguồn nhập — hàng này lấy từ đâu?</div>
      <div class="card-desc">Mỗi lô phải gắn với 1 <b>nhà cung cấp</b> và 1 <b>đơn đặt hàng</b> (để truy vết nguồn gốc & giá vốn).</div>
      <div class="po-toggle">
        <label class="po-toggle-opt">
          <input type="radio" name="poMode" value="existing" onchange="togglePoMode()" ${empty recentPOs ? 'disabled' : ''}>
          <span>📑 Gắn vào đơn đã có</span>
        </label>
        <label class="po-toggle-opt">
          <input type="radio" name="poMode" value="new" checked onchange="togglePoMode()">
          <span>➕ Tạo đơn nhập mới</span>
        </label>
      </div>

      <div id="poExistingBlock" class="form-group" style="display:none">
        <label class="form-label">Đơn đặt hàng <span>*</span></label>
        <input type="hidden" name="poId" id="hPoId" value="">
        <div class="cdd" id="cddPoId">
          <div class="cdd-btn" onclick="toggleCdd('cddPoId')">
            <span class="cdd-label">-- Chọn đơn --</span>
            <span class="cdd-arrow">▼</span>
          </div>
          <div class="cdd-menu">
            <div class="cdd-opt active" data-val="" onclick="pickCdd('cddPoId','hPoId',this,false)">-- Chọn đơn --</div>
            <c:forEach var="p" items="${recentPOs}">
              <div class="cdd-opt" data-val="${p.poId}" onclick="pickCdd('cddPoId','hPoId',this,false)">${p.poCode} · ${poSupplierMap[p.supplierId] != null ? poSupplierMap[p.supplierId].supplierName : ''} · ${fn:substring(p.orderDate.toString(),0,10)}</div>
            </c:forEach>
          </div>
        </div>
        <span class="form-hint">Chỉ hiện 15 đơn gần nhất. Xem tất cả ở tab <b>Đơn đặt hàng</b>.</span>
      </div>

      <div id="poNewBlock">
        <div class="form-group">
          <label class="form-label">Nhà cung cấp <span>*</span></label>
          <input type="hidden" name="newPoSupplierId" id="hNewPoSupplierId" value="">
          <div class="cdd" id="cddNewPoSupplierId">
            <div class="cdd-btn" onclick="toggleCdd('cddNewPoSupplierId')">
              <span class="cdd-label">-- Chọn nhà cung cấp --</span>
              <span class="cdd-arrow">▼</span>
            </div>
            <div class="cdd-menu">
              <div class="cdd-opt active" data-val="" onclick="pickCdd('cddNewPoSupplierId','hNewPoSupplierId',this,false)">-- Chọn nhà cung cấp --</div>
              <c:forEach var="s" items="${suppliers}">
                <div class="cdd-opt" data-val="${s.supplierId}" onclick="pickCdd('cddNewPoSupplierId','hNewPoSupplierId',this,false)">${s.supplierName}</div>
              </c:forEach>
            </div>
          </div>
          <span class="form-hint">Nơi bạn mua/lấy lô hàng này về.</span>
        </div>
        <div class="form-group">
          <label class="form-label">Ghi chú đơn (tùy chọn)</label>
          <input type="text" name="newPoNotes" class="form-input" placeholder="VD: Đặt hàng định kỳ tháng này">
        </div>
        <span class="form-hint">Hệ thống tự tạo 1 đơn nhập mới và gắn lô này vào.</span>
      </div>
    </div>
    </c:if>

    <%-- ② THÔNG TIN LÔ — số lô + các mốc ngày --%>
    <div class="card">
      <div class="card-title">📋 Thông tin lô &amp; ngày tháng</div>
      <div class="card-desc">Ngày nhập &amp; ngày SX mặc định là <b>hôm nay</b> — sửa lại nếu nhập bù cho hôm trước.</div>
      <div class="form-grid">
        <div class="form-group form-full">
          <label class="form-label">Số lô <span>*</span></label>
          <input type="text" name="batchNumber" class="form-input" placeholder="VD: LOT-2026-001"
                 value="${batch != null ? batch.batchNumber : ''}" required/>
        </div>

        <c:if test="${isNew}">
        <div class="form-group">
          <label class="form-label">Ngày nhập kho <span>*</span></label>
          <input type="date" name="importDate" id="importDateInp" class="form-input" required/>
          <span class="form-hint">Mặc định hôm nay. Không nhận ngày ở tương lai.</span>
        </div>
        </c:if>
        <c:if test="${not isNew}">
        <div class="form-group">
          <label class="form-label">Ngày nhập kho</label>
          <input type="text" class="form-input" value="${batch.importDate}" disabled style="background:#F8FAFC;color:var(--muted);cursor:default"/>
          <span class="form-hint">Ghi nhận tự động khi tạo lô, không đổi được.</span>
        </div>
        </c:if>

        <div class="form-group">
          <label class="form-label">Ngày sản xuất</label>
          <input type="date" name="manufactureDate" id="mfDateInp" class="form-input"
                 value="${batch != null && batch.manufactureDate != null ? batch.manufactureDate : ''}"/>
        </div>

        <div class="form-group form-full">
          <label class="form-label">Ngày hết hạn (HSD) <span>*</span></label>
          <input type="date" name="expiryDate" id="expiryDateInp" class="form-input"
                 value="${batch != null ? batch.expiryDate : ''}" required oninput="checkHsd(this)"/>
          <div id="hsdWarn" class="hsd-live"></div>
        </div>
      </div>
    </div>

    <%-- ③ SỐ LƯỢNG & GIÁ --%>
    <c:if test="${isNew}">
    <div class="card">
      <div class="card-title">📊 Số lượng &amp; giá nhập</div>
      <div class="card-desc">Nhập theo <b>quy cách đóng gói</b> (hộp/vỉ/chai…) — hệ thống tự quy ra <b>${medicine.unit}</b> và giá vốn / ${medicine.unit}.</div>

      <%-- Ẩn: giá trị quy về đơn vị bán (gửi lên server) --%>
      <input type="hidden" name="initialQuantity" id="hidQty" value=""/>
      <input type="hidden" name="importPrice"     id="hidPrice" value=""/>

      <div class="form-grid">
        <div class="form-group">
          <label class="form-label">Đơn vị nhập <span>*</span></label>
          <select id="packUnit" class="form-input" onchange="onPackUnitChange();computePack()">
            <option value="${medicine.unit}" data-base="1">${medicine.unit} (đơn vị bán)</option>
            <option value="Vỉ">Vỉ</option>
            <option value="Hộp">Hộp</option>
            <option value="Chai">Chai</option>
            <option value="Lọ">Lọ</option>
            <option value="Ống">Ống</option>
            <option value="Tuýp">Tuýp</option>
            <option value="Gói">Gói</option>
            <option value="Thùng">Thùng</option>
          </select>
        </div>
        <div class="form-group">
          <label class="form-label">Quy cách <span>*</span></label>
          <div style="display:flex;align-items:center;gap:8px">
            <span style="font-size:13px;color:var(--muted);white-space:nowrap">1 <b id="packUnitLbl2">${medicine.unit}</b> =</span>
            <input type="number" id="packFactor" class="form-input" value="1" min="1" step="1" oninput="computePack()" style="max-width:110px" disabled/>
            <span style="font-size:13px;color:var(--muted);white-space:nowrap">${medicine.unit}</span>
          </div>
          <span class="form-hint">VD: 1 Hộp = 10 Vỉ, 1 Vỉ = 10 Viên → 1 Hộp = 100 Viên.</span>
        </div>
        <div class="form-group">
          <label class="form-label">Số lượng nhập <span>*</span></label>
          <input type="number" id="packQty" class="form-input" placeholder="0" min="1" step="1" required oninput="computePack()"/>
          <span class="form-hint">Số <b id="packUnitLbl3">${medicine.unit}</b> nhập vào — không đổi sau khi lưu.</span>
        </div>
        <div class="form-group">
          <label class="form-label">Giá nhập / <span id="packUnitLbl4">${medicine.unit}</span> (₫) <span>*</span></label>
          <input type="number" id="packPrice" class="form-input" placeholder="0" min="0" step="100" required oninput="computePack()"/>
          <span class="form-hint">Giá vốn cho <b>1 <span id="packUnitLbl5">${medicine.unit}</span></b>.</span>
        </div>
        <div class="form-group form-full">
          <div id="packSummary" style="display:none;background:#EFF6FF;border:1.5px solid #BFDBFE;border-radius:11px;padding:12px 15px;font-size:13.5px;color:#1558A8;font-weight:750"></div>
        </div>
      </div>
    </div>
    </c:if>

    <c:if test="${not isNew}">
    <div class="card">
      <div class="card-title">📊 Giá nhập</div>
      <div class="form-group" style="max-width:260px">
        <label class="form-label">Giá nhập / đơn vị (₫) <span>*</span></label>
        <input type="number" name="importPrice" class="form-input" placeholder="0" min="0" step="100"
               value="${batch != null ? batch.importPrice : ''}" required/>
      </div>
    </div>
    <div class="card" style="border-color:#E5E7EB;background:#FAFBFD">
      <div class="card-title" style="color:var(--muted)">📦 Tồn kho (chỉ đọc)</div>
      <div class="form-grid">
        <div class="form-group">
          <label class="form-label">Số lượng nhập ban đầu</label>
          <input type="text" class="form-input" value="${batch.initialQuantity} ${medicine.unit}" disabled style="background:#F8FAFC;color:var(--muted);cursor:default"/>
        </div>
        <div class="form-group">
          <label class="form-label">Tồn kho hiện tại</label>
          <input type="text" class="form-input" value="${batch.currentQuantity} ${medicine.unit}" disabled style="background:#F8FAFC;color:var(--muted);cursor:default"/>
        </div>
      </div>
      <div class="form-hint" style="margin-top:8px">💡 Nhập thêm hàng vào lô này bằng nút <b>＋ Nhập thêm</b> ở trang danh sách lô.</div>
    </div>
    </c:if>

    <div class="form-actions">
      <a href="${pageContext.request.contextPath}/medicines?action=detail&id=${medicine.medicineId}" class="btn-cancel">Hủy</a>
      <button type="submit" class="btn-save"><%= isNew ? "📦 Xác nhận nhập kho" : "💾 Lưu thay đổi" %></button>
    </div>
  </form>
</div><%-- .content --%>
</div><%-- .main --%>

<script>
function toggleCdd(id){var w=document.getElementById(id),m=w.querySelector('.cdd-menu'),b=w.querySelector('.cdd-btn');var open=m.classList.contains('show');document.querySelectorAll('.cdd-menu.show').forEach(function(x){x.classList.remove('show');x.closest('.cdd').querySelector('.cdd-btn').classList.remove('open')});if(!open){m.classList.add('show');b.classList.add('open');var act=m.querySelector('.cdd-opt.active');if(act)act.scrollIntoView({block:'nearest'})}}
function pickCdd(wId,hId,el,autoSubmit){document.getElementById(hId).value=el.dataset.val;var w=document.getElementById(wId);w.querySelector('.cdd-label').textContent=el.textContent;w.querySelectorAll('.cdd-opt').forEach(function(o){o.classList.remove('active')});el.classList.add('active');w.querySelector('.cdd-menu').classList.remove('show');w.querySelector('.cdd-btn').classList.remove('open');if(autoSubmit){var f=w.closest('form');if(f)f.submit()}}
document.addEventListener('click',function(e){if(!e.target.closest('.cdd')){document.querySelectorAll('.cdd-menu.show').forEach(function(m){m.classList.remove('show');m.closest('.cdd').querySelector('.cdd-btn').classList.remove('open')})}});

const IS_NEW_BATCH = <%= isNew %>;
const EXPIRY_ALERT_DAYS = ${medicine.expiryAlertDays > 0 ? medicine.expiryAlertDays : 90};

// ── Đồng hồ realtime trên topbar ──
function tickClock() {
  const n = new Date();
  const days = ['CN','T2','T3','T4','T5','T6','T7'];
  const p = x => String(x).padStart(2,'0');
  const d = document.getElementById('clkDate');
  const t = document.getElementById('clkTime');
  if (d) d.textContent = days[n.getDay()] + ' ' + p(n.getDate()) + '/' + p(n.getMonth()+1) + '/' + n.getFullYear();
  if (t) t.textContent = p(n.getHours()) + ':' + p(n.getMinutes()) + ':' + p(n.getSeconds());
}
tickClock(); setInterval(tickClock, 1000);

// ── Auto-fill ngày mặc định = hôm nay (chỉ khi nhập lô mới, ô đang trống) ──
function todayISO() {
  const n = new Date();
  const p = x => String(x).padStart(2,'0');
  return n.getFullYear() + '-' + p(n.getMonth()+1) + '-' + p(n.getDate());
}
document.addEventListener('DOMContentLoaded', function() {
  if (IS_NEW_BATCH) {
    const imp = document.getElementById('importDateInp');
    const mf  = document.getElementById('mfDateInp');
    if (imp && !imp.value) { imp.value = todayISO(); imp.max = todayISO(); }
    if (mf && !mf.value)   { mf.value = todayISO(); mf.max = todayISO(); }
  }
  const inp = document.getElementById('expiryDateInp');
  if (inp && inp.value) checkHsd(inp);
  togglePoMode();
  if (document.getElementById('packUnit')) { onPackUnitChange(); computePack(); }
});

// ── QUY CÁCH ĐÓNG GÓI → quy đổi ra đơn vị bán + giá vốn/đơn vị ──
const BASE_UNIT = '${medicine.unit}';
function onPackUnitChange() {
  const sel = document.getElementById('packUnit');
  const isBase = sel.selectedOptions[0].getAttribute('data-base') === '1';
  const factor = document.getElementById('packFactor');
  factor.disabled = isBase;
  if (isBase) factor.value = 1;
  const u = sel.value;
  document.getElementById('packUnitLbl2').textContent = u;   // "1 [u] ="
  document.getElementById('packUnitLbl3').textContent = u;   // "Số [u] nhập"
  document.getElementById('packUnitLbl4').textContent = u;   // "Giá / [u]"
  document.getElementById('packUnitLbl5').textContent = u;
}
function computePack() {
  const qty    = parseFloat(document.getElementById('packQty').value)   || 0;
  const factor = Math.max(1, parseInt(document.getElementById('packFactor').value) || 1);
  const price  = parseFloat(document.getElementById('packPrice').value) || 0;
  const baseQty   = Math.round(qty * factor);
  const unitPrice = factor > 0 ? Math.round(price / factor) : 0;
  document.getElementById('hidQty').value   = baseQty > 0 ? baseQty : '';
  document.getElementById('hidPrice').value = price > 0 ? unitPrice : '';
  const box = document.getElementById('packSummary');
  const u   = document.getElementById('packUnit').value;
  const fmt = n => new Intl.NumberFormat('vi-VN').format(Math.round(n||0));
  if (baseQty > 0 || price > 0) {
    box.style.display = 'block';
    box.innerHTML = '📦 Nhập <b>' + fmt(qty) + ' ' + u + '</b>'
      + (factor > 1 ? ' × ' + fmt(factor) + ' ' + BASE_UNIT + '/' + u : '')
      + ' = <b style="color:#0F2645">' + fmt(baseQty) + ' ' + BASE_UNIT + '</b>'
      + ' · Giá vốn: <b style="color:#0F2645">' + fmt(unitPrice) + 'đ/' + BASE_UNIT + '</b>'
      + ' · Tổng tiền: <b style="color:#059669">' + fmt(qty * price) + 'đ</b>';
  } else { box.style.display = 'none'; }
}

// ── Kiểm tra HSD (còn bao nhiêu ngày, cảnh báo theo expiryAlertDays khi nhập) ──
function checkHsd(inp) {
  const warn = document.getElementById('hsdWarn');
  if (!inp.value) { warn.style.display = 'none'; inp.setCustomValidity(''); return; }
  const today = new Date(); today.setHours(0,0,0,0);
  const hsd = new Date(inp.value);
  const diffDays = Math.round((hsd - today) / 86400000);
  const base = 'display:block;margin-top:6px;padding:8px 12px;border-radius:8px;font-size:12.5px;font-weight:750;';
  if (diffDays < 0) {
    warn.style.cssText = base + 'background:#FEE2E2;color:#991B1B;border:1px solid #FECACA';
    warn.textContent = IS_NEW_BATCH ? '❌ HSD đã qua! Không thể nhập lô hết hạn.' : '⚠️ Lô này đã hết hạn.';
    inp.setCustomValidity(IS_NEW_BATCH ? 'Ngày hết hạn đã qua' : '');
  } else if (diffDays <= EXPIRY_ALERT_DAYS) {
    warn.style.cssText = base + 'background:#FFFBEB;color:#92400E;border:1px solid #FDE68A';
    warn.textContent = '⚠️ HSD chỉ còn ' + diffDays + ' ngày — dưới ngưỡng cảnh báo ' + EXPIRY_ALERT_DAYS + ' ngày. Sẽ cần xác nhận khi nhập.';
    inp.setCustomValidity('');
  } else {
    warn.style.cssText = base + 'background:#F0FDF4;color:#166534;border:1px solid #BBF7D0';
    warn.textContent = '✓ HSD còn ' + diffDays + ' ngày (~' + Math.round(diffDays/30) + ' tháng).';
    inp.setCustomValidity('');
  }
}

// ── Xác nhận khi HSD dưới ngưỡng cảnh báo ──
document.querySelector('form[action*="medicines"]').addEventListener('submit', function(e) {
  if (!IS_NEW_BATCH) return;
  const forceField = document.getElementById('forceShortExpiry');
  if (forceField.value === 'true') return;
  const inp = document.getElementById('expiryDateInp');
  if (!inp || !inp.value) return;
  const today = new Date(); today.setHours(0,0,0,0);
  const hsd = new Date(inp.value);
  const diffDays = Math.round((hsd - today) / 86400000);
  if (diffDays > 0 && diffDays <= EXPIRY_ALERT_DAYS) {
    e.preventDefault();
    if (confirm('⚠️ HSD chỉ còn ' + diffDays + ' ngày, dưới ngưỡng cảnh báo '
        + EXPIRY_ALERT_DAYS + ' ngày đã cấu hình cho thuốc này.\n\n'
        + 'Bạn có chắc chắn muốn nhập lô này không?')) {
      forceField.value = 'true';
      e.target.submit();
    }
  }
});

// ── Chọn đơn có sẵn / tạo đơn mới ──
function togglePoMode() {
  const existingBlock = document.getElementById('poExistingBlock');
  if (!existingBlock) return; // chế độ sửa lô
  const mode = document.querySelector('input[name="poMode"]:checked');
  const isExisting = mode && mode.value === 'existing';
  existingBlock.style.display = isExisting ? 'flex' : 'none';
  document.getElementById('poNewBlock').style.display = isExisting ? 'none' : 'block';
  const poSel = document.querySelector('select[name="poId"]');
  const supSel = document.querySelector('select[name="newPoSupplierId"]');
  if (poSel)  poSel.required  = isExisting;
  if (supSel) supSel.required = !isExisting;
}
</script>
</body>
</html>
