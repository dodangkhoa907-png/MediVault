<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("staffAccount");
    boolean isLoggedIn = (acc != null && acc.getRoleId() != 1);
    String fullName = isLoggedIn ? (acc.getFullName() != null ? acc.getFullName() : acc.getUsername()) : "Khách";
    String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>medicare POS — Bán hàng</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --blue:#1a56db;--blue2:#1e3a5f;--sky:#3f83f8;
  --surface:#f3f4f6;--white:#fff;--border:#e5e7eb;
  --navy:#111827;--muted:#6b7280;
  --green:#059669;--red:#dc2626;--gold:#d97706;--orange:#f97316;
  --sw:48px;--rw:310px;
}
html,body{height:100%;font-family:'Outfit',sans-serif;overflow:hidden;background:var(--surface);color:var(--navy)}
body{display:flex}

/* SIDEBAR */
.sidebar{width:var(--sw);min-height:100vh;background:var(--blue2);display:flex;flex-direction:column;align-items:center;padding:10px 0;position:fixed;left:0;top:0;bottom:0;z-index:10}
.sb-logo{width:34px;height:34px;background:rgba(255,255,255,.15);border-radius:8px;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:900;color:#fff;margin-bottom:16px;cursor:pointer;letter-spacing:-.5px}
.sb-btn{width:40px;height:40px;border-radius:8px;display:flex;align-items:center;justify-content:center;font-size:18px;color:rgba(255,255,255,.5);cursor:pointer;transition:.15s;text-decoration:none;margin:2px 0;position:relative}
.sb-btn:hover,.sb-btn.active{color:#fff;background:rgba(255,255,255,.15)}
.sb-tip{position:absolute;left:50px;background:rgba(15,23,42,.92);color:#fff;font-size:11px;font-weight:600;padding:4px 9px;border-radius:6px;white-space:nowrap;pointer-events:none;opacity:0;transition:opacity .15s;z-index:100}
.sb-btn:hover .sb-tip{opacity:1}
.sb-bottom{margin-top:auto;display:flex;flex-direction:column;align-items:center;gap:4px}
.sb-av{width:32px;height:32px;background:linear-gradient(135deg,#3f83f8,#1a56db);border-radius:8px;display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;color:#fff;cursor:pointer}

/* CENTER */
.center{margin-left:var(--sw);width:calc(100vw - var(--sw) - var(--rw));height:100vh;display:flex;flex-direction:column;background:var(--surface)}

/* TOPBAR */
.topbar{height:50px;background:#fff;border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 14px;gap:10px;flex-shrink:0}
.search-wrap{flex:1;position:relative}
.search-wrap input{width:100%;height:34px;padding:0 34px 0 12px;border:1.5px solid var(--border);border-radius:8px;font-size:13px;font-family:inherit;outline:none;background:var(--surface);transition:.2s}
.search-wrap input:focus{border-color:var(--sky);background:#fff}
.search-wrap::after{content:'🔍';position:absolute;right:9px;top:50%;transform:translateY(-50%);font-size:12px;pointer-events:none}
.med-count-badge{background:#eff6ff;color:var(--blue);font-size:12px;font-weight:700;padding:4px 10px;border-radius:6px;white-space:nowrap;flex-shrink:0}
.topbar-date{font-size:11.5px;color:var(--muted);white-space:nowrap;flex-shrink:0;display:flex;align-items:center;gap:4px}

/* CATEGORY */
.cat-bar{height:40px;padding:0 12px;display:flex;align-items:center;gap:4px;overflow-x:auto;flex-shrink:0;background:#fff;border-bottom:1px solid var(--border)}
.cat-bar::-webkit-scrollbar{display:none}
.cat-tab{height:27px;padding:0 12px;border-radius:6px;border:none;font-size:12px;font-weight:600;color:var(--muted);background:transparent;cursor:pointer;white-space:nowrap;transition:.15s;flex-shrink:0;font-family:inherit}
.cat-tab:hover{color:var(--blue);background:#eff6ff}
.cat-tab.active{color:var(--blue);background:#eff6ff}

/* MED GRID */
.med-grid{flex:1;overflow-y:auto;padding:10px;display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:7px;align-content:start}
.med-grid::-webkit-scrollbar{width:4px}
.med-grid::-webkit-scrollbar-thumb{background:var(--border);border-radius:4px}

.med-card{background:#fff;border:1.5px solid var(--border);border-radius:10px;padding:10px 11px;cursor:pointer;transition:.18s;display:flex;flex-direction:column;gap:3px}
.med-card:hover{border-color:var(--sky);box-shadow:0 2px 12px rgba(59,130,246,.15);transform:translateY(-1px)}
.med-card.out-of-stock{opacity:.5;cursor:not-allowed}
.med-card.out-of-stock:hover{transform:none;border-color:var(--border);box-shadow:none}

.mc-top{display:flex;align-items:center;justify-content:space-between;gap:4px}
.mc-code{font-size:10px;color:var(--muted);font-weight:600;letter-spacing:.3px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.mc-badge{font-size:9px;font-weight:700;padding:1px 5px;border-radius:4px;flex-shrink:0;white-space:nowrap}
.mb-rx{background:#fee2e2;color:#991b1b}
.mb-otc{background:#d1fae5;color:#065f46}
.mc-name{font-size:12.5px;font-weight:800;color:var(--navy);line-height:1.3;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}
.mc-unit{font-size:10.5px;color:var(--muted)}
.mc-footer{display:flex;align-items:center;justify-content:space-between;margin-top:3px}
.mc-price{font-size:14px;font-weight:900;color:var(--blue);font-family:'Outfit',sans-serif}
.mc-stock{font-size:10px;font-weight:700;padding:2px 7px;border-radius:5px;white-space:nowrap}
.stock-ok{background:#d1fae5;color:#065f46}
.stock-low{background:#fef3c7;color:#92400e}
.stock-out{background:#fee2e2;color:#991b1b}

.empty-state{grid-column:1/-1;text-align:center;padding:60px 20px;color:var(--muted)}
.empty-state .ei{font-size:40px;margin-bottom:10px}

/* RIGHT PANEL */
.invoice-panel{width:var(--rw);height:100vh;background:#fff;border-left:1.5px solid var(--border);display:flex;flex-direction:column;overflow:hidden;flex-shrink:0}

.inv-head{padding:11px 14px;background:linear-gradient(135deg,#1e3a5f,#1a56db);flex-shrink:0}
.inv-head-row{display:flex;align-items:center;justify-content:space-between}
.inv-head h3{font-size:14px;font-weight:900;color:#fff}
.inv-head-sub{font-size:11px;color:rgba(255,255,255,.55);margin-top:1px}
.btn-clear{background:rgba(255,255,255,.12);border:1px solid rgba(255,255,255,.2);color:#fff;padding:4px 9px;border-radius:6px;font-size:11px;font-weight:600;cursor:pointer;font-family:inherit;transition:.15s}
.btn-clear:hover{background:rgba(255,255,255,.25)}

.inv-customer{padding:8px 14px;border-bottom:1px solid var(--border);flex-shrink:0}
.f-label{font-size:10px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:4px}
.cust-wrap{display:flex;gap:5px}
.cust-wrap input{flex:1;height:32px;padding:0 10px;border:1.5px solid var(--border);border-radius:7px;font-size:12px;font-family:inherit;outline:none}
.cust-wrap input:focus{border-color:var(--sky)}
.cust-btn{width:32px;height:32px;background:var(--blue);border:none;border-radius:7px;color:#fff;font-size:12px;cursor:pointer;display:flex;align-items:center;justify-content:center;flex-shrink:0}
.cust-found-row{margin-top:5px;padding:5px 9px;background:#f0fdf4;border:1px solid #bbf7d0;border-radius:7px;display:none;align-items:center;gap:6px;font-size:12px}
.cust-found-name{font-weight:700;color:var(--green);flex:1}
.cust-rm{color:var(--red);cursor:pointer;background:none;border:none;font-size:13px;line-height:1}

.inv-items{flex:1;overflow-y:auto;padding:4px 0;min-height:0}
.inv-items::-webkit-scrollbar{width:3px}
.inv-items::-webkit-scrollbar-thumb{background:var(--border);border-radius:3px}
.inv-empty{text-align:center;padding:24px 12px;color:var(--muted);font-size:12px}
.inv-empty .ei{font-size:26px;margin-bottom:4px}

.inv-item{display:flex;align-items:flex-start;gap:7px;padding:7px 14px;border-bottom:1px solid #f3f4f6;transition:.1s}
.inv-item:hover{background:#fafafa}
.inv-i-info{flex:1;min-width:0}
.inv-i-name{font-size:12px;font-weight:700;color:var(--navy)}
.inv-i-meta{font-size:10px;color:var(--muted);margin-top:1px}
.inv-i-price{font-size:11px;color:var(--blue);font-weight:600}
.qty-ctrl{display:flex;align-items:center;gap:3px;flex-shrink:0}
.qty-btn{width:22px;height:22px;border-radius:5px;border:1.5px solid var(--border);background:#fff;font-size:12px;font-weight:700;cursor:pointer;display:flex;align-items:center;justify-content:center;line-height:1;color:var(--navy);transition:.15s}
.qty-btn:hover{border-color:var(--sky);color:var(--blue)}
.qty-btn.minus:hover{border-color:var(--red);color:var(--red)}
.qty-val{width:22px;text-align:center;font-size:12px;font-weight:700}
.inv-i-sub{font-size:12px;font-weight:800;color:var(--navy);white-space:nowrap;flex-shrink:0}
.inv-i-rm{color:#d1d5db;cursor:pointer;background:none;border:none;font-size:14px;line-height:1;transition:.15s}
.inv-i-rm:hover{color:var(--red)}

/* BOTTOM FORMS */
.inv-forms{padding:8px 14px;border-top:1.5px solid var(--border);background:#f9fafb;flex-shrink:0;display:flex;flex-direction:column;gap:7px}
.form-row{display:flex;align-items:center;justify-content:space-between;gap:8px}
.form-row .f-label{margin-bottom:0;flex-shrink:0}
.f-input{height:30px;padding:0 9px;border:1.5px solid var(--border);border-radius:7px;font-size:12.5px;font-weight:600;font-family:inherit;outline:none;color:var(--navy);background:#fff;transition:.15s}
.f-input:focus{border-color:var(--sky)}
.f-input.discount{width:80px;text-align:right}
.f-input.cash{width:100%;text-align:right}
.f-input.note{width:100%;height:28px;font-weight:400}

.pay-grid{display:grid;grid-template-columns:1fr 1fr;gap:4px}
.pay-btn{height:32px;border-radius:7px;border:1.5px solid var(--border);background:#fff;cursor:pointer;display:flex;align-items:center;justify-content:center;gap:4px;transition:.15s;font-family:inherit}
.pay-btn:hover{border-color:var(--sky)}
.pay-btn.active{border-color:var(--blue);background:#eff6ff}
.pay-btn .pi{font-size:13px}
.pay-btn .pt{font-size:10px;font-weight:700;color:var(--muted)}
.pay-btn.active .pt{color:var(--blue)}
.pay-btn-wide{grid-column:1/-1}

.cash-row{display:none;flex-direction:column;gap:3px}
.cash-row.show{display:flex}
.cash-change{display:flex;align-items:center;justify-content:space-between;padding:5px 9px;border-radius:7px;background:var(--surface);font-size:12px}
.cash-change-lbl{color:var(--muted)}
.cash-change-val{font-weight:800;font-size:13px}
.change-ok{color:var(--green)}.change-err{color:var(--red)}

/* TOTALS */
.inv-totals{padding:7px 14px 4px;border-top:1px solid var(--border);flex-shrink:0}
.total-row{display:flex;justify-content:space-between;align-items:center;font-size:12.5px;color:var(--muted);margin-bottom:3px}
.total-row.grand{font-size:14px;font-weight:800;color:var(--navy);margin-top:5px;padding-top:5px;border-top:1.5px solid var(--border)}
.total-row.grand .tv{font-size:16px;font-weight:900;color:var(--blue)}

.inv-action{padding:8px 14px 12px;flex-shrink:0}
.btn-checkout{width:100%;height:44px;border-radius:10px;border:none;background:linear-gradient(135deg,#f97316,#ea580c);color:#fff;font-size:14px;font-weight:800;cursor:pointer;font-family:'Outfit',sans-serif;display:flex;align-items:center;justify-content:center;gap:8px;transition:.2s;letter-spacing:-.2px}
.btn-checkout:hover:not(:disabled){box-shadow:0 6px 20px rgba(249,115,22,.4);transform:translateY(-1px)}
.btn-checkout:disabled{opacity:.4;cursor:not-allowed;transform:none;box-shadow:none}

/* SUCCESS MODAL */
.success-modal{display:none;position:fixed;inset:0;z-index:500;align-items:center;justify-content:center}
.success-modal.show{display:flex}
.sm-backdrop{position:absolute;inset:0;background:rgba(0,0,0,.5);backdrop-filter:blur(4px)}
.sm-panel{position:relative;width:360px;background:#fff;border-radius:16px;padding:32px 28px;text-align:center;box-shadow:0 20px 60px rgba(0,0,0,.2);animation:popIn .25s cubic-bezier(.34,1.56,.64,1)}
@keyframes popIn{from{opacity:0;transform:scale(.85)}to{opacity:1;transform:scale(1)}}
.sm-icon{font-size:48px;margin-bottom:12px;display:block}
.sm-title{font-size:20px;font-weight:900;color:var(--navy);margin-bottom:4px}
.sm-code{font-size:12px;color:var(--muted);margin-bottom:14px}
.sm-total{font-size:30px;font-weight:900;color:var(--blue);margin-bottom:20px}
.sm-btns{display:flex;gap:8px}
.sm-btn-new{flex:1;height:42px;border-radius:9px;background:linear-gradient(135deg,var(--orange),#ea580c);color:#fff;border:none;font-size:13px;font-weight:800;cursor:pointer;font-family:inherit}
.sm-btn-print{flex:1;height:42px;border-radius:9px;border:1.5px solid var(--border);background:#fff;color:var(--navy);font-size:13px;font-weight:600;cursor:pointer;font-family:inherit}

/* TOAST */
.toast{position:fixed;top:16px;left:50%;transform:translateX(-50%);padding:9px 16px;border-radius:9px;font-size:13px;font-weight:600;box-shadow:0 6px 24px rgba(0,0,0,.2);z-index:600;animation:toastIn .25s ease;white-space:nowrap}
@keyframes toastIn{from{opacity:0;transform:translateX(-50%) translateY(-8px)}to{opacity:1;transform:translateX(-50%) translateY(0)}}
.toast-ok{background:#064e3b;color:#fff}
.toast-err{background:#7f1d1d;color:#fff}

/* CHECKIN PANEL */
.sb-checkin-wrap{position:relative}
</style>
</head>
<body>

<!-- SIDEBAR -->
<aside class="sidebar">
  <a href="<%= ctx %>/pos" class="sb-logo" title="POS">MV</a>
  <a href="<%= ctx %>/pos" class="sb-btn active">🛒<span class="sb-tip">Bán hàng POS</span></a>
  <a href="#" class="sb-btn">🧾<span class="sb-tip">Hóa đơn của tôi</span></a>
  <a href="#" class="sb-btn">📦<span class="sb-tip">Tồn kho</span></a>
  <a href="#" class="sb-btn">👥<span class="sb-tip">Khách hàng</span></a>
  <div class="sb-bottom">
    <div class="sb-checkin-wrap">
      <button class="sb-btn" id="checkinBtn" onclick="toggleCheckinPanel()" style="width:40px;height:40px">
        <span><%= isLoggedIn ? "🟢" : "👤" %></span>
        <span class="sb-tip"><%= isLoggedIn ? "Điểm danh / " + fullName : "Nhân viên đăng nhập" %></span>
      </button>
      <div id="checkinPanel" style="display:none;position:absolute;left:52px;bottom:0;width:220px;
           background:#1e3a5f;border:1px solid rgba(255,255,255,.2);border-radius:12px;
           padding:14px;box-shadow:0 8px 32px rgba(0,0,0,.4);z-index:9999">
        <% if (isLoggedIn) { %>
        <div style="display:flex;align-items:center;gap:8px;margin-bottom:10px">
          <div style="width:32px;height:32px;background:linear-gradient(135deg,#3f83f8,#1a56db);border-radius:8px;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff"><%= initials %></div>
          <div><div style="font-size:12px;font-weight:700;color:#fff"><%= fullName %></div><div style="font-size:10px;color:rgba(255,255,255,.4)">Đã đăng nhập</div></div>
        </div>
        <a href="<%= ctx %>/staff-dashboard" style="display:block;padding:7px 10px;background:rgba(255,255,255,.1);border-radius:7px;color:#93c5fd;font-size:12px;font-weight:600;text-decoration:none;margin-bottom:5px;text-align:center">📅 Xem ca làm việc</a>
        <a href="<%= ctx %>/logout?from=staff" style="display:block;padding:7px 10px;background:rgba(239,68,68,.15);border-radius:7px;color:#fca5a5;font-size:12px;font-weight:600;text-decoration:none;text-align:center">⏻ Kết thúc ca</a>
        <% } else { %>
        <div style="font-size:11px;color:rgba(255,255,255,.5);margin-bottom:10px">Nhân viên đăng nhập để điểm danh ca làm</div>
        <a href="<%= ctx %>/staff-login" style="display:block;padding:9px 10px;background:linear-gradient(135deg,#1a56db,#1e3a5f);border-radius:7px;color:#fff;font-size:12px;font-weight:700;text-decoration:none;text-align:center">👤 Đăng nhập nhân viên</a>
        <div style="font-size:10px;color:rgba(255,255,255,.2);margin-top:7px;text-align:center">POS vẫn hoạt động không cần đăng nhập</div>
        <% } %>
      </div>
    </div>
  </div>
</aside>

<!-- CENTER -->
<div class="center">
  <!-- Topbar -->
  <div class="topbar">
    <div class="search-wrap">
      <input type="text" id="searchInput" placeholder="Tìm thuốc theo tên hoặc mã…" autocomplete="off">
    </div>
    <span class="med-count-badge" id="medCountBadge">0 thuốc</span>
    <span class="topbar-date">🗓 <span id="topDate"></span></span>
  </div>

  <!-- Category tabs -->
  <div class="cat-bar" id="catBar">
    <button class="cat-tab active" data-cat="0" onclick="filterCat(this,0)">Tất cả</button>
    <c:forEach var="cat" items="${categories}">
      <button class="cat-tab" data-cat="${cat.categoryId}"
              onclick="filterCat(this,${cat.categoryId})">${cat.categoryName}</button>
    </c:forEach>
  </div>

  <!-- Medicine grid -->
  <div class="med-grid" id="medGrid">
    <c:forEach var="m" items="${medicines}">
      <c:set var="mStock"  value="${stockMap[m.medicineId]}"/>
      <c:set var="mBatch"  value="${batchNoMap[m.medicineId]}"/>
      <c:set var="mExpiry" value="${expiryMap[m.medicineId]}"/>
      <c:choose>
        <c:when test="${mStock == 0}">
          <c:set var="cardCls" value="med-card out-of-stock"/>
          <c:set var="stkCls"  value="mc-stock stock-out"/>
          <c:set var="stkLbl"  value="Hết hàng"/>
        </c:when>
        <c:when test="${mStock le m.minInventory}">
          <c:set var="cardCls" value="med-card"/>
          <c:set var="stkCls"  value="mc-stock stock-low"/>
          <c:set var="stkLbl"  value="Còn ${mStock}"/>
        </c:when>
        <c:otherwise>
          <c:set var="cardCls" value="med-card"/>
          <c:set var="stkCls"  value="mc-stock stock-ok"/>
          <c:set var="stkLbl"  value="Còn ${mStock}"/>
        </c:otherwise>
      </c:choose>
      <div class="${cardCls}"
           data-id="${m.medicineId}"
           data-name="${m.medicineName}"
           data-price="${m.sellingPrice}"
           data-unit="${m.unit}"
           data-cat="${m.categoryId}"
           data-rx="${m.prescriptionRequired}"
           data-dosage="${m.dosage}"
           data-code="${m.medicineCode}"
           data-stock="${mStock}"
           data-batchno="${mBatch}"
           data-expiry="${mExpiry}"
           data-minstock="${m.minInventory}"
           onclick="addToCart(this)">
        <div class="mc-top">
          <span class="mc-code">${m.medicineCode}</span>
          <c:choose>
            <c:when test="${m.prescriptionRequired}"><span class="mc-badge mb-rx">Rx</span></c:when>
            <c:otherwise><span class="mc-badge mb-otc">OTC</span></c:otherwise>
          </c:choose>
        </div>
        <div class="mc-name">${m.medicineName}</div>
        <div class="mc-unit">${m.unit}</div>
        <div class="mc-footer">
          <span class="mc-price"><fmt:formatNumber value="${m.sellingPrice}" pattern="#,###"/>đ</span>
          <span class="${stkCls}">${stkLbl}</span>
        </div>
      </div>
    </c:forEach>
  </div>
</div>

<!-- RIGHT PANEL -->
<div class="invoice-panel">
  <!-- Header -->
  <div class="inv-head">
    <div class="inv-head-row">
      <div>
        <h3>🧾 Hóa đơn bán hàng</h3>
        <div class="inv-head-sub" id="invSubtitle">0 sản phẩm · 0đ</div>
      </div>
      <button class="btn-clear" onclick="clearCart()">✕ Xóa hết</button>
    </div>
  </div>

  <!-- Customer -->
  <div class="inv-customer">
    <div class="f-label">Khách hàng</div>
    <div class="cust-wrap">
      <input type="text" id="custPhone" placeholder="SĐT khách..." oninput="onCustInput()" autocomplete="off">
      <button class="cust-btn" onclick="searchCustomer()">🔍</button>
    </div>
    <div class="cust-found-row" id="custFound">
      <span>👤</span>
      <span class="cust-found-name" id="custFoundName"></span>
      <span style="font-size:11px;color:var(--muted)" id="custFoundPhone"></span>
      <button class="cust-rm" onclick="removeCustomer()">✕</button>
    </div>
  </div>

  <!-- Items -->
  <div class="inv-items" id="invItems">
    <div class="inv-empty"><div class="ei">🛒</div><p>Giỏ hàng trống<br><small>Bấm vào thẻ thuốc để thêm</small></p></div>
  </div>

  <!-- Bottom forms -->
  <div class="inv-forms">
    <!-- Discount -->
    <div class="form-row">
      <span class="f-label">Giảm giá (₫)</span>
      <input type="number" class="f-input discount" id="discountInput" value="0" min="0" oninput="updateTotal()">
    </div>

    <!-- Payment methods -->
    <div>
      <div class="f-label" style="margin-bottom:5px">Phương thức</div>
      <div class="pay-grid">
        <button class="pay-btn active" data-method="CASH" onclick="selectPay(this)"><span class="pi">💵</span><span class="pt">Tiền mặt</span></button>
        <button class="pay-btn" data-method="CARD" onclick="selectPay(this)"><span class="pi">🏦</span><span class="pt">Thẻ ngân hàng</span></button>
        <button class="pay-btn" data-method="TRANSFER" onclick="selectPay(this)"><span class="pi">🔄</span><span class="pt">Chuyển khoản</span></button>
        <button class="pay-btn" data-method="EWALLET" onclick="selectPay(this)"><span class="pi">📱</span><span class="pt">Ví điện tử</span></button>
        <button class="pay-btn pay-btn-wide" data-method="QR_CODE" onclick="selectPay(this)"><span class="pi">📷</span><span class="pt">QR Code</span></button>
      </div>
    </div>

    <!-- Cash input (only for CASH) -->
    <div class="cash-row show" id="cashRow">
      <div class="f-label">Tiền khách đưa</div>
      <input type="number" class="f-input cash" id="cashInput" placeholder="0" min="0" oninput="calcChange()">
      <div class="cash-change" id="cashChangeRow" style="display:none">
        <span class="cash-change-lbl">Tiền thừa trả khách</span>
        <span class="cash-change-val" id="cashChangeVal">—</span>
      </div>
    </div>

    <!-- Note -->
    <div>
      <div class="f-label">Ghi chú hóa đơn</div>
      <input type="text" class="f-input note" id="noteInput" placeholder="Ghi chú cho hóa đơn...">
    </div>
  </div>

  <!-- Totals -->
  <div class="inv-totals">
    <div class="total-row"><span>Tạm tính</span><span id="sumSub">0đ</span></div>
    <div class="total-row"><span>Giảm giá</span><span id="sumDiscount" style="color:var(--red)">-0đ</span></div>
    <div class="total-row grand"><span>Tổng cộng</span><span class="tv" id="sumTotal">0đ</span></div>
  </div>

  <!-- Checkout button -->
  <div class="inv-action">
    <button class="btn-checkout" id="checkoutBtn" onclick="doCheckout()" disabled>
      🛒 THANH TOÁN
    </button>
  </div>
</div>

<!-- SUCCESS MODAL -->
<div class="success-modal" id="successModal">
  <div class="sm-backdrop" onclick="closeSuccess()"></div>
  <div class="sm-panel">
    <span class="sm-icon">✅</span>
    <div class="sm-title">Thanh toán thành công!</div>
    <div class="sm-code" id="smCode"></div>
    <div class="sm-total" id="smTotal"></div>
    <div class="sm-btns">
      <button class="sm-btn-new" onclick="newInvoice()">＋ Hóa đơn mới</button>
      <button class="sm-btn-print" onclick="printReceipt()">🖨️ In hóa đơn</button>
    </div>
  </div>
</div>

<script>
const ctx = '<%= ctx %>';
let cart = [];
let selectedCustomer = null;
let selectedPayment = 'CASH';
let allMedicines = [];
let currentInvoiceId = 0;

// ── Date display ──
(function() {
  const n = new Date();
  const days = ['CN','T2','T3','T4','T5','T6','T7'];
  document.getElementById('topDate').textContent =
    days[n.getDay()] + ' ' + n.getDate().toString().padStart(2,'0') + '/' +
    (n.getMonth()+1).toString().padStart(2,'0') + '/' + n.getFullYear();
})();

// ── Load medicines from DOM ──
document.querySelectorAll('.med-card').forEach(card => {
  allMedicines.push({
    id:    parseInt(card.dataset.id),
    name:  card.dataset.name,
    price: parseFloat(card.dataset.price),
    unit:  card.dataset.unit,
    catId: parseInt(card.dataset.cat) || 0,
    rx:    card.dataset.rx === 'true',
    stock: parseInt(card.dataset.stock) || 0,
    batchNo: card.dataset.batchno || '',
    expiry:  card.dataset.expiry  || '',
    dosage:  card.dataset.dosage  || '',
    code:    card.dataset.code    || '',
    el:    card
  });
});
document.getElementById('medCountBadge').textContent = allMedicines.length + ' thuốc';

// ── Search ──
let searchTimer;
document.getElementById('searchInput').addEventListener('input', function() {
  clearTimeout(searchTimer);
  const q = this.value.toLowerCase().trim();
  searchTimer = setTimeout(() => {
    allMedicines.forEach(m => {
      const match = !q || m.name.toLowerCase().includes(q) || m.code.toLowerCase().includes(q);
      m.el.style.display = match ? '' : 'none';
    });
    checkEmpty();
  }, 200);
});

// ── Category filter ──
let activeCat = 0;
function filterCat(btn, catId) {
  document.querySelectorAll('.cat-tab').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  activeCat = catId;
  allMedicines.forEach(m => {
    m.el.style.display = (catId === 0 || m.catId === catId) ? '' : 'none';
  });
  checkEmpty();
}

function checkEmpty() {
  const visible = allMedicines.filter(m => m.el.style.display !== 'none');
  const grid = document.getElementById('medGrid');
  let es = grid.querySelector('.empty-state');
  if (visible.length === 0) {
    if (!es) {
      es = document.createElement('div');
      es.className = 'empty-state';
      es.innerHTML = '<div class="ei">🔍</div><p>Không tìm thấy thuốc phù hợp</p>';
      grid.appendChild(es);
    }
  } else if (es) es.remove();
}

// ── Cart ──
function addToCart(card) {
  if (card.classList.contains('out-of-stock')) return;
  const id    = parseInt(card.dataset.id);
  const stock = parseInt(card.dataset.stock) || 0;
  const existing = cart.find(i => i.id === id);
  if (existing) {
    if (stock > 0 && existing.qty >= stock) {
      showToast('⚠️ Không đủ tồn kho! Còn ' + stock + ' ' + card.dataset.unit, 'err');
      return;
    }
    existing.qty++;
  } else {
    if (stock === 0) { showToast('❌ Thuốc này đã hết hàng!', 'err'); return; }
    cart.push({
      id, stock,
      name:    card.dataset.name,
      price:   parseFloat(card.dataset.price),
      unit:    card.dataset.unit,
      batchNo: card.dataset.batchno || '',
      expiry:  card.dataset.expiry  || '',
      dosage:  card.dataset.dosage  || '',
      code:    card.dataset.code    || '',
      rx:      card.dataset.rx === 'true',
      qty: 1
    });
  }
  renderCart();
  card.style.transform = 'scale(.95)';
  setTimeout(() => card.style.transform = '', 130);
}

function changeQty(id, delta) {
  const item = cart.find(i => i.id === id);
  if (!item) return;
  item.qty += delta;
  if (item.qty <= 0) cart = cart.filter(i => i.id !== id);
  renderCart();
}

function removeItem(id) {
  cart = cart.filter(i => i.id !== id);
  renderCart();
}

function clearCart() {
  cart = []; selectedCustomer = null;
  document.getElementById('custPhone').value = '';
  document.getElementById('custFound').style.display = 'none';
  document.getElementById('discountInput').value = '0';
  document.getElementById('cashInput').value = '';
  document.getElementById('noteInput').value = '';
  document.getElementById('cashChangeRow').style.display = 'none';
  renderCart();
}

function fmtMoney(n) { return new Intl.NumberFormat('vi-VN').format(Math.round(n)) + 'đ'; }
function fmtExpiry(d) {
  if (!d) return '';
  const p = d.split('-');
  return p.length === 3 ? p[2]+'/'+p[1]+'/'+p[0] : d;
}

function renderCart() {
  const el = document.getElementById('invItems');
  if (cart.length === 0) {
    el.innerHTML = '<div class="inv-empty"><div class="ei">🛒</div><p>Giỏ hàng trống<br><small>Bấm vào thẻ thuốc để thêm</small></p></div>';
    document.getElementById('checkoutBtn').disabled = true;
  } else {
    el.innerHTML = cart.map(item => {
      const meta = [];
      if (item.batchNo) meta.push('🏷 Lô: ' + item.batchNo);
      if (item.expiry)  meta.push('📅 HSD: ' + fmtExpiry(item.expiry));
      const metaHtml = meta.length ? '<div class="inv-i-meta">' + meta.join(' · ') + '</div>' : '';
      return '<div class="inv-item">'
        + '<div class="inv-i-info">'
          + '<div class="inv-i-name">' + item.name + '</div>'
          + '<div class="inv-i-price">' + fmtMoney(item.price) + ' / ' + item.unit + '</div>'
          + metaHtml
        + '</div>'
        + '<div class="qty-ctrl">'
          + '<button class="qty-btn minus" onclick="changeQty('+item.id+',-1)">−</button>'
          + '<span class="qty-val">'+item.qty+'</span>'
          + '<button class="qty-btn" onclick="changeQty('+item.id+',1)">＋</button>'
        + '</div>'
        + '<div class="inv-i-sub">' + fmtMoney(item.price * item.qty) + '</div>'
        + '<button class="inv-i-rm" onclick="removeItem('+item.id+')" title="Xóa">✕</button>'
      + '</div>';
    }).join('');
    document.getElementById('checkoutBtn').disabled = false;
  }
  updateTotal();
}

function calcTotal() {
  const sub = cart.reduce((s,i) => s + i.price*i.qty, 0);
  const disc = parseFloat(document.getElementById('discountInput').value) || 0;
  return Math.max(0, sub - disc);
}

function updateTotal() {
  const sub  = cart.reduce((s,i) => s + i.price*i.qty, 0);
  const disc = parseFloat(document.getElementById('discountInput').value) || 0;
  const tot  = Math.max(0, sub - disc);
  const qty  = cart.reduce((s,i) => s+i.qty, 0);
  document.getElementById('sumSub').textContent      = fmtMoney(sub);
  document.getElementById('sumDiscount').textContent = '-' + fmtMoney(disc);
  document.getElementById('sumTotal').textContent    = fmtMoney(tot);
  document.getElementById('invSubtitle').textContent = qty + ' sản phẩm · ' + fmtMoney(tot);
  calcChange();
}

// ── Payment ──
function selectPay(btn) {
  document.querySelectorAll('.pay-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  selectedPayment = btn.dataset.method;
  const cashRow = document.getElementById('cashRow');
  if (selectedPayment === 'CASH') cashRow.classList.add('show');
  else { cashRow.classList.remove('show'); document.getElementById('cashChangeRow').style.display='none'; }
}

function calcChange() {
  if (selectedPayment !== 'CASH') return;
  const total    = calcTotal();
  const received = parseFloat(document.getElementById('cashInput').value) || 0;
  const changeRow = document.getElementById('cashChangeRow');
  const valEl     = document.getElementById('cashChangeVal');
  if (received <= 0) { changeRow.style.display='none'; return; }
  changeRow.style.display = 'flex';
  const change = received - total;
  valEl.className = 'cash-change-val ' + (change >= 0 ? 'change-ok' : 'change-err');
  valEl.textContent = change >= 0 ? fmtMoney(change) : '⚠ Thiếu ' + fmtMoney(Math.abs(change));
}

// ── Customer ──
let custTimer;
function onCustInput() { clearTimeout(custTimer); custTimer = setTimeout(searchCustomer, 600); }
function searchCustomer() {
  const phone = document.getElementById('custPhone').value.trim();
  if (phone.length < 9) return;
  fetch(ctx + '/pos?action=find-customer&phone=' + encodeURIComponent(phone))
    .then(r => r.json()).then(data => {
      const row = document.getElementById('custFound');
      if (data.found) {
        selectedCustomer = { id: data.id, name: data.name };
        document.getElementById('custFoundName').textContent  = data.name;
        document.getElementById('custFoundPhone').textContent = data.phone;
        row.style.display = 'flex';
      } else {
        selectedCustomer = null;
        showToast('⚠️ Không tìm thấy khách hàng với SĐT này', 'err');
        row.style.display = 'none';
      }
    }).catch(() => {});
}
function removeCustomer() {
  selectedCustomer = null;
  document.getElementById('custPhone').value = '';
  document.getElementById('custFound').style.display = 'none';
}

// ── Checkout ──
function doCheckout() {
  if (cart.length === 0) return;
  submitSale();
}

function submitSale() {
  const btn = document.getElementById('checkoutBtn');
  btn.disabled = true;
  btn.textContent = '⏳ Đang xử lý…';
  const formData = new FormData();
  formData.append('action', 'complete-sale');
  formData.append('paymentMethod', selectedPayment);
  formData.append('discount', document.getElementById('discountInput').value || '0');
  if (selectedCustomer) formData.append('customerId', selectedCustomer.id);
  cart.forEach(item => { formData.append('medId[]', item.id); formData.append('qty[]', item.qty); });
  fetch(ctx + '/pos', { method: 'POST', body: formData })
    .then(r => r.json()).then(data => {
      if (data.ok) {
        currentInvoiceId = data.invoiceId || 0;
        document.getElementById('smCode').textContent  = (data.invoiceCode || '') + ' · ' + new Date().toLocaleString('vi-VN');
        document.getElementById('smTotal').textContent = fmtMoney(calcTotal());
        document.getElementById('successModal').classList.add('show');
        showToast('✅ Thanh toán thành công!', 'ok');
      } else {
        showToast('❌ ' + (data.msg || 'Lỗi xử lý!'), 'err');
        btn.disabled = false; btn.innerHTML = '🛒 THANH TOÁN';
      }
    }).catch(() => {
      showToast('❌ Lỗi kết nối!', 'err');
      btn.disabled = false; btn.innerHTML = '🛒 THANH TOÁN';
    });
}

function newInvoice() { closeSuccess(); clearCart(); document.getElementById('checkoutBtn').disabled = true; document.getElementById('checkoutBtn').innerHTML = '🛒 THANH TOÁN'; }
function closeSuccess() { document.getElementById('successModal').classList.remove('show'); }
function printReceipt() {
  if (currentInvoiceId > 0) window.open(ctx + '/invoices?action=detail&id=' + currentInvoiceId, '_blank');
  else showToast('⚠️ Không tìm thấy hóa đơn để in!', 'err');
  closeSuccess();
}

function showToast(msg, type) {
  const t = document.createElement('div');
  t.className = 'toast toast-' + type;
  t.textContent = msg;
  document.body.appendChild(t);
  setTimeout(() => { t.style.opacity='0'; t.style.transition='opacity .3s'; setTimeout(()=>t.remove(),300); }, 2500);
}

function toggleCheckinPanel() {
  const p = document.getElementById('checkinPanel');
  p.style.display = p.style.display === 'none' ? 'block' : 'none';
}
document.addEventListener('click', e => {
  const wrap = document.querySelector('.sb-checkin-wrap');
  if (wrap && !wrap.contains(e.target)) {
    const p = document.getElementById('checkinPanel');
    if (p) p.style.display = 'none';
  }
});
</script>
</body>
</html>
