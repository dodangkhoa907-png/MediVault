<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%
    // POS PUBLIC — không cần login để bán hàng
    // Nếu staff đã login → hiển thị thông tin, nút điểm danh
    com.medivault.entity.Account acc = (com.medivault.entity.Account) session.getAttribute("staffAccount");
    boolean isLoggedIn = (acc != null && acc.getRoleId() != 1);
    String fullName  = isLoggedIn ? (acc.getFullName() != null ? acc.getFullName() : acc.getUsername()) : "Khách";
    String initials  = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>MediVault POS — Bán hàng</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@600;700;800;900&family=Plus+Jakarta+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --navy:#101A33;--blue:#114C7D;--sky:#46CAF4;--sky2:#2EA8D6;
  --purple:#7C3AED;--purple-l:#A78BFA;
  --surface:#F0F4F9;--white:#fff;--border:#DDE6F0;
  --muted:#6B82A0;--green:#059669;--red:#DC2626;--gold:#D97706;
  --left:64px;  /* mini sidebar */
  --mid:calc(100vw - 64px - 420px);
  --right:420px;
}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif;overflow:hidden}
body{display:flex;background:var(--surface);color:var(--navy)}

/* ── MINI SIDEBAR ── */
.msidebar{
  width:var(--left);min-height:100vh;
  background:linear-gradient(180deg,#1E1035,#2D1B69,#4C1D95);
  display:flex;flex-direction:column;align-items:center;
  padding:12px 0;position:fixed;left:0;top:0;bottom:0;z-index:10;
}
.ms-logo{width:40px;height:40px;background:rgba(167,139,250,.2);border:1.5px solid rgba(167,139,250,.4);border-radius:11px;display:flex;align-items:center;justify-content:center;font-size:18px;margin-bottom:16px;cursor:pointer}
.ms-btn{width:44px;height:44px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:18px;color:rgba(255,255,255,.5);cursor:pointer;transition:all .15s;text-decoration:none;margin:3px 0;position:relative}
.ms-btn:hover,.ms-btn.active{color:#fff;background:rgba(167,139,250,.2)}
.ms-btn.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:60%;background:var(--purple-l);border-radius:4px}
.ms-tooltip{position:absolute;left:56px;background:rgba(30,16,53,.95);color:#fff;font-size:12px;font-weight:600;padding:5px 10px;border-radius:8px;white-space:nowrap;pointer-events:none;opacity:0;transition:opacity .15s;z-index:100}
.ms-btn:hover .ms-tooltip{opacity:1}
.ms-sep{width:28px;height:1px;background:rgba(255,255,255,.1);margin:8px 0}
.ms-av{width:36px;height:36px;background:linear-gradient(135deg,var(--purple-l),var(--purple));border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:800;color:#fff;margin-top:auto;cursor:pointer}

/* ── CENTER: MEDICINE GRID ── */
.center{
  margin-left:var(--left);width:var(--mid);
  height:100vh;display:flex;flex-direction:column;
  background:var(--surface);
}

/* Topbar */
.pos-topbar{
  height:56px;background:#fff;border-bottom:1px solid var(--border);
  display:flex;align-items:center;padding: 20px;gap:12px;flex-shrink:0;
}
.pos-title{font-family:'Nunito',sans-serif;font-size:15px;font-weight:800;color:var(--navy);flex-shrink:0}
.search-wrap{flex:1;max-width:340px;position:relative}
.search-wrap input{
  width:100%;height:36px;padding:0 36px 0 14px;
  border:1.5px solid var(--border);border-radius:10px;
  font-size:13px;font-family:inherit;outline:none;background:var(--surface);
  transition:border-color .2s;
}
.search-wrap input:focus{border-color:var(--sky);background:#fff}
.search-wrap::after{content:'🔍';position:absolute;right:10px;top:50%;transform:translateY(-50%);font-size:11px;pointer-events:none}
.scan-btn{height:36px;padding:0 12px;border:1.5px solid var(--border);border-radius:10px;background:#fff;font-size:13px;font-weight:600;cursor:pointer;display:flex;align-items:center;gap:5px;color:var(--muted);transition:all .15s;flex-shrink:0}
.scan-btn:hover{border-color:var(--sky);color:var(--blue)}
.pos-clock{font-size:12px;font-weight:700;font-style:italic;color:var(--muted);margin-left:auto;flex-shrink:0}
.clock-sep{animation:blink 1s step-end infinite;font-style:normal}
@keyframes blink{0%,100%{opacity:1}50%{opacity:0}}

/* Category tabs */
.cat-bar{
  height:44px;padding:0 16px;
  display:flex;align-items:center;gap:6px;overflow-x:auto;flex-shrink:0;
  background:#fff;border-bottom:1px solid var(--border);
}
.cat-bar::-webkit-scrollbar{display:none}
.cat-tab{height:28px;padding:0 12px;border-radius:7px;border:1.5px solid var(--border);font-size:12px;font-weight:600;color:var(--muted);background:#fff;cursor:pointer;white-space:nowrap;transition:all .15s;flex-shrink:0}
.cat-tab:hover{border-color:var(--sky);color:var(--blue)}
.cat-tab.active{background:var(--blue);border-color:var(--blue);color:#fff}

/* Medicine grid */
.med-grid{
  flex:1;overflow-y:auto;padding:16px;
  display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));
  gap:12px;align-content:start;
}
.med-grid::-webkit-scrollbar{width:4px}
.med-grid::-webkit-scrollbar-thumb{background:var(--border);border-radius:4px}

.med-card{
  background:#fff;border:1.5px solid var(--border);border-radius:14px;
  padding:14px;cursor:pointer;transition:all .2s;position:relative;
  display:flex;flex-direction:column;gap:8px;
}
.med-card:hover{border-color:var(--sky);box-shadow:0 4px 16px rgba(70,202,244,.15);transform:translateY(-2px)}
.med-card.out-of-stock{opacity:.55;cursor:not-allowed}
.med-card.out-of-stock:hover{transform:none;border-color:var(--border)}

.med-card-top{display:flex;align-items:flex-start;justify-content:space-between;gap:6px}
.med-icon{width:40px;height:40px;border-radius:10px;background:linear-gradient(135deg,#EFF6FF,#DBEAFE);display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0}
.med-badges{display:flex;flex-direction:column;gap:3px;align-items:flex-end}
.med-badge{font-size:9.5px;font-weight:700;padding:2px 7px;border-radius:5px;white-space:nowrap}
.mb-rx{background:rgba(220,38,38,.1);color:var(--red)}
.mb-otc{background:rgba(5,150,105,.1);color:var(--green)}
.mb-box{background:rgba(17,76,125,.1);color:var(--blue)}
.mb-warn{background:rgba(217,119,6,.12);color:var(--gold)}

.med-name{font-family:'Nunito',sans-serif;font-size:13px;font-weight:800;color:var(--navy);line-height:1.3}
.med-code{font-size:10.5px;color:var(--muted)}

.med-batch{font-size:10.5px;color:var(--muted);background:var(--surface);padding:4px 8px;border-radius:6px}
.med-batch span{color:var(--navy);font-weight:600}

.med-footer{display:flex;align-items:center;justify-content:space-between;margin-top:2px}
.med-price{font-family:'Nunito',sans-serif;font-size:15px;font-weight:900;color:var(--blue)}
.med-stock{font-size:11px;font-weight:600;padding:2px 8px;border-radius:6px}
.stock-ok{background:rgba(5,150,105,.1);color:var(--green)}
.stock-low{background:rgba(217,119,6,.1);color:var(--gold)}
.stock-out{background:rgba(220,38,38,.1);color:var(--red)}

.med-expiry-warn{
  position:absolute;top:10px;left:10px;
  background:rgba(217,119,6,.9);color:#fff;
  font-size:9px;font-weight:700;padding:2px 6px;border-radius:4px;
}

.empty-state{grid-column:1/-1;text-align:center;padding:60px 20px;color:var(--muted)}
.empty-state .ei{font-size:40px;margin-bottom:10px}

/* ── RIGHT: INVOICE PANEL ── */
.invoice-panel{
  width:var(--right);min-height:100vh;
  background:#fff;border-left:1.5px solid var(--border);
  display:flex;flex-direction:column;flex-shrink:0;
}

/* Invoice header */
.inv-head{
  padding:14px 18px;border-bottom:1px solid var(--border);
  background:linear-gradient(135deg,#101A33,#114C7D);
  display:flex;align-items:center;justify-content:space-between;
}
.inv-head-left h3{font-family:'Nunito',sans-serif;font-size:15px;font-weight:900;color:#fff}
.inv-code{font-size:11px;color:rgba(255,255,255,.5);margin-top:1px}
.inv-clear{background:rgba(255,255,255,.15);border:1px solid rgba(255,255,255,.2);color:#fff;padding:5px 10px;border-radius:7px;font-size:11.5px;font-weight:600;cursor:pointer;font-family:inherit;transition:background .15s}
.inv-clear:hover{background:rgba(255,255,255,.25)}

/* Customer section */
.inv-customer{padding:12px 18px;border-bottom:1px solid var(--border);background:#FAFCFF}
.cust-search-wrap{position:relative}
.cust-search-wrap input{
  width:100%;height:34px;padding:0 36px 0 12px;
  border:1.5px solid var(--border);border-radius:9px;
  font-size:13px;font-family:inherit;outline:none;
  transition:border-color .2s;background:#fff;
}
.cust-search-wrap input:focus{border-color:var(--sky)}
.cust-search-btn{position:absolute;right:6px;top:50%;transform:translateY(-50%);width:24px;height:24px;background:var(--blue);border:none;border-radius:6px;color:#fff;font-size:11px;cursor:pointer;display:flex;align-items:center;justify-content:center}
.cust-found{margin-top:7px;padding:7px 10px;background:rgba(5,150,105,.08);border:1px solid rgba(5,150,105,.2);border-radius:8px;display:flex;align-items:center;gap:8px;font-size:12.5px}
.cust-found-name{font-weight:700;color:var(--green)}
.cust-found-rm{margin-left:auto;color:var(--red);cursor:pointer;font-size:14px;background:none;border:none;line-height:1}

/* Items list */
.inv-items{flex:1;overflow-y:auto;padding:10px 0}
.inv-items::-webkit-scrollbar{width:3px}
.inv-items::-webkit-scrollbar-thumb{background:var(--border);border-radius:3px}

.inv-empty{text-align:center;padding:40px 16px;color:var(--muted);font-size:13px}
.inv-empty .ei{font-size:32px;margin-bottom:8px}

.inv-item{
  display:flex;align-items:center;gap:10px;
  padding:10px 18px;border-bottom:1px solid #F8FAFB;
  transition:background .12s;
}
.inv-item:hover{background:#FAFCFF}
.inv-item-info{flex:1;min-width:0}
.inv-item-name{font-size:12.5px;font-weight:700;color:var(--navy);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.inv-item-batch{font-size:10.5px;color:var(--muted)}
.inv-item-price{font-size:12px;font-weight:600;color:var(--blue);white-space:nowrap}

.qty-ctrl{display:flex;align-items:center;gap:4px}
.qty-btn{width:24px;height:24px;border-radius:6px;border:1.5px solid var(--border);background:#fff;font-size:14px;font-weight:700;cursor:pointer;display:flex;align-items:center;justify-content:center;transition:all .15s;line-height:1;color:var(--navy)}
.qty-btn:hover{border-color:var(--sky);color:var(--blue)}
.qty-btn.minus:hover{border-color:var(--red);color:var(--red)}
.qty-val{width:28px;text-align:center;font-size:13px;font-weight:700;color:var(--navy)}
.inv-item-rm{color:rgba(220,38,38,.5);cursor:pointer;font-size:14px;background:none;border:none;transition:color .15s;padding:2px;line-height:1}
.inv-item-rm:hover{color:var(--red)}

/* Subtotal per item */
.inv-item-sub{font-family:'Nunito',sans-serif;font-size:13px;font-weight:800;color:var(--navy);white-space:nowrap;min-width:70px;text-align:right}

/* Summary */
.inv-summary{padding:12px 18px;border-top:1.5px solid var(--border);background:#FAFCFF}
.sum-row{display:flex;justify-content:space-between;align-items:center;font-size:13px;margin-bottom:6px;color:var(--muted)}
.sum-row.total{color:var(--navy);font-size:15px;font-weight:800;margin-top:8px;padding-top:8px;border-top:1.5px solid var(--border)}
.sum-row.total .sum-val{font-family:'Nunito',sans-serif;font-size:18px;font-weight:900;color:var(--blue)}
.discount-input{width:100px;height:28px;padding:0 8px;border:1.5px solid var(--border);border-radius:8px;font-size:13px;font-family:inherit;outline:none;text-align:right}
.discount-input:focus{border-color:var(--sky)}

/* Payment methods */
.inv-payment{padding:12px 18px;border-top:1px solid var(--border)}
.pay-label{font-size:11.5px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:8px}
.pay-methods{display:grid;grid-template-columns:repeat(5,1fr);gap:6px}
.pay-btn{
  height:44px;border-radius:10px;border:1.5px solid var(--border);
  background:#fff;cursor:pointer;display:flex;flex-direction:column;
  align-items:center;justify-content:center;gap:2px;
  transition:all .15s;font-family:inherit;
}
.pay-btn:hover{border-color:var(--sky)}
.pay-btn.active{border-color:var(--blue);background:rgba(17,76,125,.06)}
.pay-btn .pi{font-size:16px}
.pay-btn .pt{font-size:9px;font-weight:700;color:var(--muted)}
.pay-btn.active .pt{color:var(--blue)}

/* Action buttons */
.inv-actions{padding:12px 18px;border-top:1px solid var(--border);display:flex;gap:8px}
.btn-print{
  flex:1;height:44px;border-radius:10px;border:1.5px solid var(--border);
  background:#fff;font-size:13px;font-weight:700;color:var(--muted);
  cursor:pointer;font-family:inherit;display:flex;align-items:center;justify-content:center;gap:6px;
  transition:all .15s;
}
.btn-print:hover{border-color:var(--sky);color:var(--blue)}
.btn-checkout{
  flex:2;height:44px;border-radius:10px;border:none;
  background:linear-gradient(135deg,var(--blue),#0d3d63);
  color:#fff;font-size:14px;font-weight:800;
  cursor:pointer;font-family:'Nunito',sans-serif;
  display:flex;align-items:center;justify-content:center;gap:8px;
  transition:all .2s;letter-spacing:-.2px;
}
.btn-checkout:hover{background:linear-gradient(135deg,#0d3d63,#091f33);box-shadow:0 6px 20px rgba(17,76,125,.4)}
.btn-checkout:disabled{opacity:.5;cursor:not-allowed;box-shadow:none}

/* ── SUCCESS MODAL ── */
.success-modal{
  display:none;position:fixed;inset:0;z-index:500;
  align-items:center;justify-content:center;
}
.success-modal.show{display:flex}
.sm-backdrop{position:absolute;inset:0;background:rgba(16,26,51,.6);backdrop-filter:blur(6px)}
.sm-panel{
  position:relative;width:380px;background:#fff;border-radius:20px;
  padding:36px 32px;text-align:center;
  box-shadow:0 24px 80px rgba(0,0,0,.2);
  animation:popIn .3s cubic-bezier(.34,1.56,.64,1);
}
@keyframes popIn{from{opacity:0;transform:scale(.85)}to{opacity:1;transform:scale(1)}}
.sm-icon{font-size:52px;margin-bottom:16px;display:block}
.sm-title{font-family:'Nunito',sans-serif;font-size:22px;font-weight:900;color:var(--navy);margin-bottom:6px}
.sm-code{font-size:13px;color:var(--muted);margin-bottom:20px}
.sm-total{font-family:'Nunito',sans-serif;font-size:32px;font-weight:900;color:var(--blue);margin-bottom:24px}
.sm-btns{display:flex;gap:10px}
.sm-btn-new{flex:1;height:44px;border-radius:10px;background:linear-gradient(135deg,var(--blue),#0d3d63);color:#fff;border:none;font-size:14px;font-weight:800;cursor:pointer;font-family:'Nunito',sans-serif;transition:all .2s}
.sm-btn-new:hover{box-shadow:0 6px 20px rgba(17,76,125,.4)}
.sm-btn-print{flex:1;height:44px;border-radius:10px;border:1.5px solid var(--border);background:#fff;color:var(--navy);font-size:14px;font-weight:600;cursor:pointer;font-family:inherit;transition:all .15s}
.sm-btn-print:hover{border-color:var(--blue);color:var(--blue)}

/* Toast */
.toast{position:fixed;top:18px;left:50%;transform:translateX(-50%);padding:10px 18px;border-radius:10px;font-size:13px;font-weight:600;box-shadow:0 8px 32px rgba(0,0,0,.2);z-index:600;animation:toastIn .3s ease;white-space:nowrap}
@keyframes toastIn{from{opacity:0;transform:translateX(-50%) translateY(-10px)}to{opacity:1;transform:translateX(-50%) translateY(0)}}
.toast-ok{background:#064e3b;color:#fff}
.toast-err{background:#7f1d1d;color:#fff}
</style>
</head>
<body>

<!-- ── MINI SIDEBAR ── -->
<aside class="msidebar">
  <a href="<%= ctx %>/pos" class="ms-logo" title="POS">💊</a>

  <a href="<%= ctx %>/dashboard" class="ms-btn" title="">
    <span>🏠</span>
    <span class="ms-tooltip">Dashboard</span>
  </a>
  <a href="<%= ctx %>/pos" class="ms-btn active" title="">
    <span>🛒</span>
    <span class="ms-tooltip">Bán hàng POS</span>
  </a>
  <a href="#" class="ms-btn" title="">
    <span>🧾</span>
    <span class="ms-tooltip">Hóa đơn của tôi</span>
  </a>
  <a href="#" class="ms-btn" title="">
    <span>👥</span>
    <span class="ms-tooltip">Khách hàng</span>
  </a>
  <div class="ms-sep"></div>
  <!-- Nút điểm danh / đăng nhập staff — hover hiện panel -->
  <div class="ms-checkin-wrap" style="margin-top:auto;position:relative">
    <button class="ms-btn" id="checkinBtn" title="" onclick="toggleCheckinPanel()" style="width:44px;height:44px">
      <span><%= isLoggedIn ? "🟢" : "👤" %></span>
      <span class="ms-tooltip"><%= isLoggedIn ? "Điểm danh / " + fullName : "Nhân viên đăng nhập" %></span>
    </button>
    <!-- Panel hiện khi hover/click -->
    <div id="checkinPanel" style="display:none;position:absolute;left:54px;bottom:0;width:220px;
         background:#1e1035;border:1px solid rgba(167,139,250,.3);border-radius:14px;
         padding:16px;box-shadow:0 8px 32px rgba(0,0,0,.4);z-index:9999">
      <% if (isLoggedIn) { %>
      <div style="display:flex;align-items:center;gap:10px;margin-bottom:12px">
        <div style="width:36px;height:36px;background:linear-gradient(135deg,#a78bfa,#7c3aed);
             border-radius:10px;display:flex;align-items:center;justify-content:center;
             font-size:13px;font-weight:800;color:#fff"><%= initials %></div>
        <div>
          <div style="font-size:13px;font-weight:700;color:#fff"><%= fullName %></div>
          <div style="font-size:11px;color:rgba(255,255,255,.4)">Đã đăng nhập</div>
        </div>
      </div>
      <a href="<%= ctx %>/staff-dashboard" style="display:block;padding:8px 12px;
         background:rgba(167,139,250,.15);border-radius:8px;color:#a78bfa;
         font-size:12px;font-weight:600;text-decoration:none;margin-bottom:6px;text-align:center">
        📅 Xem ca làm việc
      </a>
      <a href="<%= ctx %>/logout?from=staff" style="display:block;padding:8px 12px;
         background:rgba(239,68,68,.1);border-radius:8px;color:#f87171;
         font-size:12px;font-weight:600;text-decoration:none;text-align:center">
        ⏻ Kết thúc ca
      </a>
      <% } else { %>
      <div style="font-size:12px;color:rgba(255,255,255,.5);margin-bottom:10px">
        Nhân viên đăng nhập để điểm danh ca làm
      </div>
      <a href="<%= ctx %>/staff-login" style="display:block;padding:10px 12px;
         background:linear-gradient(135deg,#7c3aed,#5b21b6);border-radius:8px;color:#fff;
         font-size:13px;font-weight:700;text-decoration:none;text-align:center">
        👤 Đăng nhập nhân viên
      </a>
      <div style="font-size:10px;color:rgba(255,255,255,.25);margin-top:8px;text-align:center">
        POS vẫn hoạt động không cần đăng nhập
      </div>
      <% } %>
    </div>
  </div>
</aside>

<!-- ── CENTER: MEDICINE GRID ── -->
<div class="center">
  <!-- Topbar -->
  <div class="pos-topbar">
    <span class="pos-title">🛒 Bán hàng</span>
    <div class="search-wrap">
      <input type="text" id="searchInput" placeholder="Tìm thuốc theo tên, mã, barcode…" autocomplete="off">
    </div>
    <button class="scan-btn" onclick="focusSearch()" title="Quét barcode">
      📷 Quét
    </button>
    <div class="pos-clock">
      <span id="ch">00</span><span class="clock-sep">:</span><span id="cm">00</span>
      &nbsp;<span id="cd" style="font-style:normal;font-weight:500"></span>
    </div>
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
    <%-- Render từ server-side (nhanh hơn load JS) --%>
    <c:forEach var="m" items="${medicines}">
      <div class="med-card"
           data-id="${m.medicineId}"
           data-name="${m.medicineName}"
           data-price="${m.sellingPrice}"
           data-unit="${m.unit}"
           data-cat="${m.categoryId}"
           data-rx="${m.prescriptionRequired}"
           onclick="addToCart(this)">
        <div class="med-card-top">
          <div class="med-icon">💊</div>
          <div class="med-badges">
            <c:choose>
              <c:when test="${m.prescriptionRequired}">
                <span class="med-badge mb-rx">Kê toa</span>
              </c:when>
              <c:otherwise>
                <span class="med-badge mb-otc">OTC</span>
              </c:otherwise>
            </c:choose>
          </div>
        </div>
        <div class="med-name">${m.medicineName}</div>
        <div class="med-code">${m.medicineCode}</div>
        <div class="med-footer">
          <span class="med-price">
            <fmt:formatNumber value="${m.sellingPrice}" pattern="#,###"/>đ
          </span>
          <span class="med-stock stock-ok">${m.unit}</span>
        </div>
      </div>
    </c:forEach>
  </div>
</div>

<!-- ── RIGHT: INVOICE PANEL ── -->
<div class="invoice-panel">
  <!-- Header -->
  <div class="inv-head">
    <div class="inv-head-left">
      <h3>🧾 Hóa đơn bán hàng</h3>
      <div class="inv-code" id="invCodeDisplay">HD-TEMP · Chưa lưu</div>
    </div>
    <button class="inv-clear" onclick="clearCart()">✕ Xóa hết</button>
  </div>

  <!-- Customer -->
  <div class="inv-customer">
    <div class="cust-search-wrap">
      <input type="text" id="custPhone" placeholder="📱 Nhập SĐT để tìm khách hàng…"
             oninput="onCustInput()" autocomplete="off">
      <button class="cust-search-btn" onclick="searchCustomer()">🔍</button>
    </div>
    <div id="custFound" style="display:none"></div>
  </div>

  <!-- Items -->
  <div class="inv-items" id="invItems">
    <div class="inv-empty">
      <div class="ei">🛒</div>
      <p>Chưa có sản phẩm nào<br><small>Bấm vào thẻ thuốc để thêm</small></p>
    </div>
  </div>

  <!-- Summary -->
  <div class="inv-summary">
    <div class="sum-row">
      <span>Số lượng sản phẩm</span>
      <span id="sumQty">0</span>
    </div>
    <div class="sum-row">
      <span>Tạm tính</span>
      <span id="sumSub">0đ</span>
    </div>
    <div class="sum-row">
      <span>Giảm giá (đ)</span>
      <input type="number" class="discount-input" id="discountInput"
             value="0" min="0" oninput="updateTotal()">
    </div>
    <div class="sum-row total">
      <span>TỔNG THANH TOÁN</span>
      <span class="sum-val" id="sumTotal">0đ</span>
    </div>
  </div>

  <!-- Payment methods -->
  <div class="inv-payment">
    <div class="pay-label">Phương thức thanh toán</div>
    <div class="pay-methods">
      <button class="pay-btn active" data-method="CASH" onclick="selectPay(this)">
        <span class="pi">💵</span><span class="pt">Tiền mặt</span>
      </button>
      <button class="pay-btn" data-method="CARD" onclick="selectPay(this)">
        <span class="pi">💳</span><span class="pt">Thẻ</span>
      </button>
      <button class="pay-btn" data-method="TRANSFER" onclick="selectPay(this)">
        <span class="pi">🏦</span><span class="pt">Chuyển khoản</span>
      </button>
      <button class="pay-btn" data-method="EWALLET" onclick="selectPay(this)">
        <span class="pi">📲</span><span class="pt">Ví điện tử</span>
      </button>
      <button class="pay-btn" data-method="QR_CODE" onclick="selectPay(this)">
        <span class="pi">📷</span><span class="pt">QR Code</span>
      </button>
    </div>
  </div>

  <!-- Actions -->
  <div class="inv-actions">
    <button class="btn-print" onclick="printTemp()">🖨️ In tạm</button>
    <button class="btn-checkout" id="checkoutBtn" onclick="doCheckout()" disabled>
      ✓ Thanh toán
    </button>
  </div>
</div>

<!-- ── SUCCESS MODAL ── -->
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

// ── Clock ──
function updateClock() {
  const n = new Date();
  const h = n.getHours().toString().padStart(2,'0');
  const m = n.getMinutes().toString().padStart(2,'0');
  const days = ['CN','T2','T3','T4','T5','T6','T7'];
  document.getElementById('ch').textContent = h;
  document.getElementById('cm').textContent = m;
  document.getElementById('cd').textContent = days[n.getDay()]+' '+
    n.getDate().toString().padStart(2,'0')+'/'+(n.getMonth()+1).toString().padStart(2,'0');
}
updateClock(); setInterval(updateClock, 1000);

// ── Load medicine data from DOM ──
document.querySelectorAll('.med-card').forEach(card => {
  allMedicines.push({
    id:    parseInt(card.dataset.id),
    name:  card.dataset.name,
    price: parseFloat(card.dataset.price),
    unit:  card.dataset.unit,
    catId: parseInt(card.dataset.cat),
    rx:    card.dataset.rx === 'true',
    el:    card
  });
});

// ── Search ──
let searchTimer;
document.getElementById('searchInput').addEventListener('input', function() {
  clearTimeout(searchTimer);
  const q = this.value.toLowerCase().trim();
  searchTimer = setTimeout(() => {
    allMedicines.forEach(m => {
      const match = !q || m.name.toLowerCase().includes(q) ||
                    m.el.querySelector('.med-code').textContent.toLowerCase().includes(q);
      m.el.style.display = match ? '' : 'none';
    });
    checkEmpty();
  }, 200);
});

function focusSearch() { document.getElementById('searchInput').focus(); }

// ── Category filter ──
let activeCat = 0;
function filterCat(btn, catId) {
  document.querySelectorAll('.cat-tab').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  activeCat = catId;
  allMedicines.forEach(m => {
    const match = catId === 0 || m.catId === catId;
    m.el.style.display = match ? '' : 'none';
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
  const name  = card.dataset.name;
  const price = parseFloat(card.dataset.price);
  const unit  = card.dataset.unit;

  const existing = cart.find(i => i.id === id);
  if (existing) {
    existing.qty++;
  } else {
    cart.push({ id, name, price, unit, qty: 1, batchNo: '' });
  }
  renderCart();
  card.style.transform = 'scale(.96)';
  setTimeout(() => card.style.transform = '', 150);
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
  cart = [];
  selectedCustomer = null;
  document.getElementById('custPhone').value = '';
  document.getElementById('custFound').style.display = 'none';
  document.getElementById('discountInput').value = '0';
  renderCart();
}

function renderCart() {
  const el = document.getElementById('invItems');
  if (cart.length === 0) {
    el.innerHTML = '<div class="inv-empty"><div class="ei">🛒</div><p>Chưa có sản phẩm nào<br><small>Bấm vào thẻ thuốc để thêm</small></p></div>';
    document.getElementById('checkoutBtn').disabled = true;
  } else {
    el.innerHTML = cart.map(function(item) {
    return '<div class="inv-item">'
      + '<div class="inv-item-info">'
        + '<div class="inv-item-name">' + item.name + '</div>'
        + '<div class="inv-item-price">' + fmtMoney(item.price) + ' / ' + item.unit + '</div>'
      + '</div>'
      + '<div class="qty-ctrl">'
        + '<button class="qty-btn minus" onclick="changeQty(' + item.id + ',-1)">−</button>'
        + '<span class="qty-val">' + item.qty + '</span>'
        + '<button class="qty-btn" onclick="changeQty(' + item.id + ',1)">＋</button>'
      + '</div>'
      + '<div class="inv-item-sub">' + fmtMoney(item.price * item.qty) + '</div>'
      + '<button class="inv-item-rm" onclick="removeItem(' + item.id + ')" title="Xóa">✕</button>'
    + '</div>';
  }).join('');
    document.getElementById('checkoutBtn').disabled = false;
  }
  updateTotal();
}

function updateTotal() {
  const sub      = cart.reduce((s,i) => s + i.price * i.qty, 0);
  const discount = parseFloat(document.getElementById('discountInput').value) || 0;
  const total    = Math.max(0, sub - discount);
  const qty      = cart.reduce((s,i) => s + i.qty, 0);
  document.getElementById('sumQty').textContent  = qty + ' SP';
  document.getElementById('sumSub').textContent  = fmtMoney(sub);
  document.getElementById('sumTotal').textContent = fmtMoney(total);
}

function fmtMoney(n) {
  return new Intl.NumberFormat('vi-VN').format(Math.round(n)) + 'đ';
}

// ── Payment ──
function selectPay(btn) {
  document.querySelectorAll('.pay-btn').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  selectedPayment = btn.dataset.method;
}

// ── Customer ──
let custTimer;
function onCustInput() {
  clearTimeout(custTimer);
  custTimer = setTimeout(searchCustomer, 600);
}

function searchCustomer() {
  const phone = document.getElementById('custPhone').value.trim();
  if (phone.length < 9) return;
  fetch(ctx + '/pos?action=find-customer&phone=' + encodeURIComponent(phone))
    .then(r => r.json())
    .then(data => {
      const el = document.getElementById('custFound');
      if (data.found) {
        selectedCustomer = { id: data.id, name: data.name };
        el.innerHTML = `<div class="cust-found">
          <span>👤</span>
          <span class="cust-found-name">${data.name}</span>
          <span style="color:var(--muted);font-size:11px">${data.phone}</span>
          <button class="cust-found-rm" onclick="removeCustomer()">✕</button>
        </div>`;
        el.style.display = 'block';
      } else {
        selectedCustomer = null;
        el.innerHTML = `<div style="margin-top:6px;font-size:12px;color:var(--muted)">⚠️ Không tìm thấy khách hàng với SĐT này</div>`;
        el.style.display = 'block';
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
  const btn = document.getElementById('checkoutBtn');
  btn.disabled = true;
  btn.textContent = '⏳ Đang xử lý…';

  const formData = new FormData();
  formData.append('action', 'complete-sale');
  formData.append('paymentMethod', selectedPayment);
  formData.append('discount', document.getElementById('discountInput').value || '0');
  if (selectedCustomer) formData.append('customerId', selectedCustomer.id);
  cart.forEach(item => {
    formData.append('medId[]', item.id);
    formData.append('qty[]', item.qty);
  });

  fetch(ctx + '/pos', { method: 'POST', body: formData })
    .then(r => r.json())
    .then(data => {
      if (data.ok) {
        const total = parseFloat(document.getElementById('discountInput').value||0);
        const sub   = cart.reduce((s,i) => s + i.price * i.qty, 0);
        document.getElementById('smCode').textContent  = data.invoiceCode + ' · ' + new Date().toLocaleString('vi-VN');
        document.getElementById('smTotal').textContent = fmtMoney(sub - total);
        document.getElementById('successModal').classList.add('show');
        showToast('✅ Thanh toán thành công!', 'ok');
      } else {
        showToast('❌ ' + (data.msg || 'Lỗi xử lý!'), 'err');
        btn.disabled = false;
        btn.textContent = '✓ Thanh toán';
      }
    }).catch(err => {
      showToast('❌ Lỗi kết nối!', 'err');
      btn.disabled = false;
      btn.textContent = '✓ Thanh toán';
    });
}

function newInvoice() {
  closeSuccess();
  clearCart();
  const btn = document.getElementById('checkoutBtn');
  btn.disabled = true;
  btn.innerHTML = '✓ Thanh toán';
}

function closeSuccess() {
  document.getElementById('successModal').classList.remove('show');
}

function printTemp() {
  if (cart.length === 0) { showToast('⚠️ Giỏ hàng trống!', 'err'); return; }
  showToast('🖨️ Đang in tạm…', 'ok');
}

function printReceipt() {
  closeSuccess();
  showToast('🖨️ Đang in hóa đơn…', 'ok');
}

function showToast(msg, type) {
  const t = document.createElement('div');
  t.className = 'toast toast-' + type;
  t.textContent = msg;
  document.body.appendChild(t);
  setTimeout(() => { t.style.opacity='0'; t.style.transition='opacity .3s'; setTimeout(()=>t.remove(),300); }, 2500);
}

// Checkin panel toggle
function toggleCheckinPanel() {
  const panel = document.getElementById('checkinPanel');
  panel.style.display = panel.style.display === 'none' ? 'block' : 'none';
}
document.addEventListener('click', function(e) {
  const wrap = document.querySelector('.ms-checkin-wrap');
  if (wrap && !wrap.contains(e.target)) {
    const panel = document.getElementById('checkinPanel');
    if (panel) panel.style.display = 'none';
  }
});
</script>
</body>
</html>
