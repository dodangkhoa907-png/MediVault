<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("staffAccount");
    boolean isLoggedIn = (acc != null && acc.getRoleId() != 1);
    String fullName = isLoggedIn ? (acc.getFullName() != null ? acc.getFullName() : acc.getUsername()) : "Dược sĩ";
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
<title>Medicare POS — Bán hàng</title>
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --blue:#1a56db;--blue2:#1e3a5f;--sky:#3f83f8;
  --surface:#f3f4f6;--white:#fff;--border:#e5e7eb;
  --navy:#111827;--muted:#6b7280;
  --green:#059669;--red:#dc2626;--gold:#d97706;--orange:#f97316;
  --sw:64px;--rw:420px;
}
html,body{height:100%;font-family:'Outfit',sans-serif;overflow:hidden;background:var(--surface);color:var(--navy);font-size:14px}
body{display:flex}

/* SIDEBAR — hover-expand */
.sidebar{
  width:var(--sw);min-height:100vh;background:var(--blue2);
  display:flex;flex-direction:column;align-items:stretch;
  padding:10px 0;position:fixed;left:0;top:0;bottom:0;
  z-index:100;overflow:hidden;
  transition:width .22s cubic-bezier(.4,0,.2,1);
}
.sidebar:hover{width:214px}
/* Logo */
.sb-logo{height:44px;display:flex;align-items:center;gap:10px;padding:0 13px;
  margin-bottom:14px;cursor:pointer;text-decoration:none;overflow:hidden}
.sb-logo-icon{width:38px;height:38px;min-width:38px;background:rgba(255,255,255,.15);
  border-radius:9px;display:flex;align-items:center;justify-content:center;
  font-size:12px;font-weight:900;color:#fff;letter-spacing:-.5px;flex-shrink:0}
.sb-logo-full{font-size:13.5px;font-weight:900;color:#fff;opacity:0;
  transition:opacity .15s .07s;white-space:nowrap}
.sidebar:hover .sb-logo-full{opacity:1}
/* Nav buttons */
.sb-btn{height:44px;display:flex;align-items:center;gap:11px;padding:0 13px;
  border-radius:9px;color:rgba(255,255,255,.5);cursor:pointer;transition:.15s;
  text-decoration:none;margin:1px 6px;overflow:hidden;background:transparent;
  border:none;font-family:inherit;width:calc(100% - 12px)}
.sb-btn:hover,.sb-btn.active{color:#fff;background:rgba(255,255,255,.15)}
.sb-icon{font-size:18px;min-width:28px;text-align:center;flex-shrink:0;line-height:1}
.sb-label{font-size:12.5px;font-weight:600;color:rgba(255,255,255,.75);
  white-space:nowrap;opacity:0;transition:opacity .14s .06s}
.sb-btn:hover .sb-label,.sb-btn.active .sb-label{color:#fff}
.sidebar:hover .sb-label{opacity:1}
/* Tooltip (only when collapsed) */
.sb-tip{position:absolute;left:62px;background:rgba(15,23,42,.92);color:#fff;
  font-size:11px;font-weight:600;padding:4px 10px;border-radius:6px;
  white-space:nowrap;pointer-events:none;opacity:0;transition:opacity .15s;z-index:200}
.sb-btn:hover .sb-tip{opacity:1}
.sidebar:hover .sb-tip{opacity:0!important;pointer-events:none}
/* Divider */
.sb-divider{height:1px;background:rgba(255,255,255,.08);margin:7px 14px}
/* Bottom */
.sb-bottom{margin-top:auto;display:flex;flex-direction:column;gap:2px;padding-bottom:8px}

/* CENTER */
.center{margin-left:var(--sw);width:calc(100vw - var(--sw) - var(--rw));height:100vh;display:flex;flex-direction:column;background:var(--surface)}

/* TOPBAR */
.topbar{height:54px;background:#fff;border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 16px;gap:10px;flex-shrink:0}
.search-wrap{flex:1;position:relative}
.search-wrap input{width:100%;height:38px;padding:0 38px 0 14px;border:1.5px solid var(--border);border-radius:9px;font-size:14px;font-family:inherit;outline:none;background:var(--surface);transition:.2s}
.search-wrap input:focus{border-color:var(--sky);background:#fff}
.search-wrap::after{content:'🔍';position:absolute;right:10px;top:50%;transform:translateY(-50%);font-size:13px;pointer-events:none}
.med-count-badge{background:#eff6ff;color:var(--blue);font-size:13px;font-weight:700;padding:5px 12px;border-radius:7px;white-space:nowrap;flex-shrink:0}
.topbar-date{font-size:12.5px;color:var(--muted);white-space:nowrap;flex-shrink:0;display:flex;align-items:center;gap:4px}

/* CATEGORY */
.cat-bar{height:44px;padding:0 14px;display:flex;align-items:center;gap:5px;overflow-x:auto;flex-shrink:0;background:#fff;border-bottom:1px solid var(--border)}
.cat-bar::-webkit-scrollbar{display:none}
.cat-tab{height:30px;padding:0 14px;border-radius:7px;border:none;font-size:13px;font-weight:600;color:var(--muted);background:transparent;cursor:pointer;white-space:nowrap;transition:.15s;flex-shrink:0;font-family:inherit}
.cat-tab:hover{color:var(--blue);background:#eff6ff}
.cat-tab.active{color:var(--blue);background:#eff6ff}

/* MED GRID */
.med-grid{flex:1;overflow-y:auto;padding:12px;display:grid;grid-template-columns:repeat(auto-fill,minmax(175px,1fr));gap:9px;align-content:start}
.med-grid::-webkit-scrollbar{width:4px}
.med-grid::-webkit-scrollbar-thumb{background:var(--border);border-radius:4px}

.med-card{background:#fff;border:1.5px solid var(--border);border-radius:12px;padding:12px 13px;cursor:pointer;transition:.18s;display:flex;flex-direction:column;gap:4px;position:relative}
.med-card:hover{border-color:var(--sky);box-shadow:0 3px 14px rgba(59,130,246,.16);transform:translateY(-1px)}
.med-card.out-of-stock{opacity:.5;cursor:not-allowed}
.med-card.out-of-stock:hover{transform:none;border-color:var(--border);box-shadow:none}
.mc-top{display:flex;align-items:center;justify-content:space-between;gap:4px}
.mc-code{font-size:10.5px;color:var(--muted);font-weight:600;letter-spacing:.3px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.mc-badge{font-size:9.5px;font-weight:700;padding:1px 6px;border-radius:4px;flex-shrink:0;white-space:nowrap}
.mb-rx{background:#fee2e2;color:#991b1b}
.mb-otc{background:#d1fae5;color:#065f46}
.mc-name{font-size:13.5px;font-weight:800;color:var(--navy);line-height:1.3;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden}
.mc-unit{font-size:11px;color:var(--muted)}
.mc-footer{display:flex;align-items:center;justify-content:space-between;margin-top:4px}
.mc-price{font-size:15px;font-weight:900;color:var(--blue)}
.mc-stock{font-size:10.5px;font-weight:700;padding:2px 8px;border-radius:5px;white-space:nowrap}
.stock-ok{background:#d1fae5;color:#065f46}
.stock-low{background:#fef3c7;color:#92400e}
.stock-out{background:#fee2e2;color:#991b1b}
.empty-state{grid-column:1/-1;text-align:center;padding:60px 20px;color:var(--muted)}
.empty-state .ei{font-size:44px;margin-bottom:12px}

/* RIGHT PANEL */
.invoice-panel{width:var(--rw);height:100vh;background:#fff;border-left:2px solid var(--border);display:flex;flex-direction:column;overflow:hidden;flex-shrink:0}

/* Header */
.inv-head{padding:13px 16px;background:linear-gradient(135deg,#1e3a5f,#1a56db);flex-shrink:0}
.inv-head-row{display:flex;align-items:center;justify-content:space-between}
.inv-head h3{font-size:15px;font-weight:900;color:#fff}
.inv-head-sub{font-size:12px;color:rgba(255,255,255,.6);margin-top:2px}
.btn-clear{background:rgba(255,255,255,.12);border:1px solid rgba(255,255,255,.25);color:#fff;padding:5px 11px;border-radius:7px;font-size:12px;font-weight:600;cursor:pointer;font-family:inherit;transition:.15s}
.btn-clear:hover{background:rgba(255,255,255,.28)}

/* Customer */
.inv-customer{padding:9px 16px;border-bottom:1px solid var(--border);flex-shrink:0}
.f-label{font-size:11px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:5px}
.cust-wrap{display:flex;gap:6px}
.cust-wrap input{flex:1;height:34px;padding:0 11px;border:1.5px solid var(--border);border-radius:8px;font-size:13px;font-family:inherit;outline:none}
.cust-wrap input:focus{border-color:var(--sky)}
.cust-btn{width:34px;height:34px;background:var(--blue);border:none;border-radius:8px;color:#fff;font-size:13px;cursor:pointer;display:flex;align-items:center;justify-content:center;flex-shrink:0}
.cust-found-row{margin-top:6px;padding:6px 10px;background:#f0fdf4;border:1px solid #bbf7d0;border-radius:8px;display:none;align-items:center;gap:7px;font-size:13px}
.cust-found-name{font-weight:700;color:var(--green);flex:1}
.cust-rm{color:var(--red);cursor:pointer;background:none;border:none;font-size:14px;line-height:1}

/* Items */
.inv-items{flex:1;overflow-y:auto;padding:4px 0;min-height:0}
.inv-items::-webkit-scrollbar{width:3px}
.inv-items::-webkit-scrollbar-thumb{background:var(--border);border-radius:3px}
.inv-empty{text-align:center;padding:28px 14px;color:var(--muted);font-size:13px}
.inv-empty .ei{font-size:30px;margin-bottom:6px}
.inv-item{display:flex;align-items:flex-start;gap:8px;padding:8px 16px;border-bottom:1px solid #f3f4f6;transition:.1s}
.inv-item:hover{background:#fafafa}
.inv-i-info{flex:1;min-width:0}
.inv-i-name{font-size:13px;font-weight:700;color:var(--navy)}
.inv-i-meta{font-size:10.5px;color:var(--muted);margin-top:2px}
.inv-i-price{font-size:12px;color:var(--blue);font-weight:600}
.qty-ctrl{display:flex;align-items:center;gap:4px;flex-shrink:0}
.qty-btn{width:25px;height:25px;border-radius:6px;border:1.5px solid var(--border);background:#fff;font-size:13px;font-weight:700;cursor:pointer;display:flex;align-items:center;justify-content:center;line-height:1;color:var(--navy);transition:.15s}
.qty-btn:hover{border-color:var(--sky);color:var(--blue)}
.qty-btn.minus:hover{border-color:var(--red);color:var(--red)}
.qty-val{width:26px;text-align:center;font-size:13px;font-weight:700}
.inv-i-sub{font-size:13px;font-weight:800;color:var(--navy);white-space:nowrap;flex-shrink:0}
.inv-i-rm{color:#d1d5db;cursor:pointer;background:none;border:none;font-size:15px;line-height:1;transition:.15s;flex-shrink:0}
.inv-i-rm:hover{color:var(--red)}

/* BOTTOM FORMS */
.inv-forms{padding:7px 14px;border-top:2px solid var(--border);background:#f9fafb;flex-shrink:0;display:flex;flex-direction:column;gap:6px}
.form-row{display:flex;align-items:center;justify-content:space-between;gap:8px}
.form-row .f-label{margin-bottom:0;flex-shrink:0}
.f-input{height:32px;padding:0 10px;border:1.5px solid var(--border);border-radius:8px;font-size:13px;font-weight:600;font-family:inherit;outline:none;color:var(--navy);background:#fff;transition:.15s}
.f-input:focus{border-color:var(--sky)}
.f-input.discount{width:90px;text-align:right}
.f-input.note{width:100%;height:30px;font-weight:400}

/* Payment tabs — compact horizontal */
.pay-tabs{display:flex;gap:4px;overflow-x:auto;padding-bottom:2px}
.pay-tabs::-webkit-scrollbar{display:none}
.pay-tab{flex-shrink:0;height:30px;padding:0 10px;border-radius:7px;border:1.5px solid var(--border);background:#fff;cursor:pointer;display:flex;align-items:center;gap:4px;font-family:inherit;white-space:nowrap;transition:.15s}
.pay-tab:hover{border-color:var(--sky)}
.pay-tab.active{border-color:var(--blue);background:#eff6ff}
.pay-tab .pi{font-size:12px}
.pay-tab .pt{font-size:11px;font-weight:700;color:var(--muted)}
.pay-tab.active .pt{color:var(--blue)}

/* Medicine info button */
.mc-info-btn{position:absolute;top:7px;right:7px;width:20px;height:20px;border-radius:50%;background:rgba(59,130,246,.12);border:none;cursor:pointer;display:flex;align-items:center;justify-content:center;font-size:10px;font-weight:900;color:var(--blue);transition:.15s;z-index:2;line-height:1;font-style:italic}
.mc-info-btn:hover{background:var(--blue);color:#fff}

/* Medicine info modal */
.info-modal{display:none;position:fixed;inset:0;z-index:400;align-items:center;justify-content:center}
.info-modal.show{display:flex}
.im-backdrop{position:absolute;inset:0;background:rgba(0,0,0,.45);backdrop-filter:blur(2px)}
.im-panel{position:relative;width:340px;background:#fff;border-radius:16px;padding:20px 20px 16px;box-shadow:0 16px 48px rgba(0,0,0,.22);animation:popIn .2s cubic-bezier(.34,1.56,.64,1)}
.im-close{position:absolute;top:12px;right:14px;background:none;border:none;font-size:18px;cursor:pointer;color:var(--muted);line-height:1}
.im-rx{display:inline-block;font-size:11px;font-weight:700;padding:2px 8px;border-radius:5px;margin-bottom:6px}
.im-name{font-size:16px;font-weight:900;color:var(--navy);margin-bottom:2px}
.im-code{font-size:11px;color:var(--muted);margin-bottom:10px}
.im-rows{display:flex;flex-direction:column;gap:5px;margin-bottom:12px}
.im-row{display:flex;justify-content:space-between;align-items:center;font-size:13px;padding:4px 0;border-bottom:1px dashed #f3f4f6}
.im-row .ik{color:var(--muted);font-size:12px}
.im-row .iv{font-weight:700;color:var(--navy)}
.im-price-row{background:#eff6ff;border-radius:9px;padding:9px 12px;display:flex;justify-content:space-between;align-items:center}
.im-price-lbl{font-size:12px;color:var(--blue);font-weight:600}
.im-price-val{font-size:18px;font-weight:900;color:var(--blue)}
.im-add-btn{width:100%;height:40px;margin-top:10px;border-radius:10px;border:none;background:linear-gradient(135deg,#1a56db,#1e3a5f);color:#fff;font-size:13px;font-weight:800;cursor:pointer;font-family:inherit;transition:.15s}
.im-add-btn:hover{box-shadow:0 4px 14px rgba(26,86,219,.35)}
.im-add-btn:disabled{opacity:.45;cursor:not-allowed;box-shadow:none}

/* Cash section */
.cash-section{display:none;flex-direction:column;gap:7px;background:#fff;border:1.5px solid var(--border);border-radius:10px;padding:10px 12px}
.cash-section.show{display:flex}
.cash-total-bar{display:flex;align-items:center;justify-content:space-between;padding:8px 0;border-bottom:1px dashed var(--border)}
.cash-total-lbl{font-size:12px;color:var(--muted);font-weight:600}
.cash-total-val{font-size:20px;font-weight:900;color:var(--blue)}
.cash-quick{display:flex;gap:5px;flex-wrap:wrap}
.cash-q-btn{padding:4px 10px;background:#eff6ff;color:var(--blue);border:none;border-radius:6px;font-size:12px;font-weight:700;cursor:pointer;font-family:inherit;transition:.15s}
.cash-q-btn:hover{background:#dbeafe}
.cash-input-row{display:flex;align-items:center;gap:8px}
.cash-input-lbl{font-size:12px;font-weight:700;color:var(--muted);white-space:nowrap}
.f-input.cash{flex:1;text-align:right;font-size:14px}
.cash-change-row{display:flex;align-items:center;justify-content:space-between;padding:7px 10px;border-radius:8px;font-size:13px}
.cash-change-ok{background:#f0fdf4;border:1px solid #bbf7d0}
.cash-change-err{background:#fef2f2;border:1px solid #fecaca}
.cash-change-lbl{color:var(--muted);font-weight:600}
.cash-change-val{font-weight:900;font-size:15px}
.change-ok{color:var(--green)}
.change-err{color:var(--red)}

/* TOTALS */
.inv-totals{padding:8px 16px 5px;border-top:1px solid var(--border);flex-shrink:0}
.total-row{display:flex;justify-content:space-between;align-items:center;font-size:13px;color:var(--muted);margin-bottom:4px}
.total-row.grand{font-size:15px;font-weight:800;color:var(--navy);margin-top:6px;padding-top:6px;border-top:2px solid var(--border)}
.total-row.grand .tv{font-size:18px;font-weight:900;color:var(--blue)}

/* Checkout button */
.inv-action{padding:9px 16px 13px;flex-shrink:0}
.btn-checkout{width:100%;height:48px;border-radius:12px;border:none;background:linear-gradient(135deg,#f97316,#ea580c);color:#fff;font-size:15px;font-weight:800;cursor:pointer;font-family:'Outfit',sans-serif;display:flex;align-items:center;justify-content:center;gap:9px;transition:.2s;letter-spacing:-.2px}
.btn-checkout:hover:not(:disabled){box-shadow:0 6px 20px rgba(249,115,22,.4);transform:translateY(-1px)}
.btn-checkout:disabled{opacity:.4;cursor:not-allowed;transform:none;box-shadow:none}

/* SUCCESS MODAL */
.success-modal{display:none;position:fixed;inset:0;z-index:500;align-items:center;justify-content:center}
.success-modal.show{display:flex}
.sm-backdrop{position:absolute;inset:0;background:rgba(0,0,0,.5);backdrop-filter:blur(4px)}
.sm-panel{position:relative;width:380px;background:#fff;border-radius:18px;padding:28px 26px 24px;text-align:center;box-shadow:0 24px 64px rgba(0,0,0,.22);animation:popIn .28s cubic-bezier(.34,1.56,.64,1)}
@keyframes popIn{from{opacity:0;transform:scale(.85)}to{opacity:1;transform:scale(1)}}
.sm-icon{font-size:52px;margin-bottom:10px;display:block}
.sm-title{font-size:21px;font-weight:900;color:var(--navy);margin-bottom:4px}
.sm-code{font-size:12px;color:var(--muted);margin-bottom:5px}
.sm-change{font-size:14px;font-weight:700;color:var(--green);margin-bottom:12px;min-height:20px}
.sm-total{font-size:32px;font-weight:900;color:var(--blue);margin-bottom:18px}
.sm-btns{display:flex;gap:8px}
.sm-btn-new{flex:1;height:44px;border-radius:10px;background:linear-gradient(135deg,var(--orange),#ea580c);color:#fff;border:none;font-size:13px;font-weight:800;cursor:pointer;font-family:inherit}
.sm-btn-print{flex:1;height:44px;border-radius:10px;border:2px solid var(--border);background:#fff;color:var(--navy);font-size:13px;font-weight:700;cursor:pointer;font-family:inherit;display:flex;align-items:center;justify-content:center;gap:6px}
.sm-btn-print:hover{border-color:var(--blue);color:var(--blue)}

/* TOAST */
.toast{position:fixed;top:16px;left:50%;transform:translateX(-50%);padding:10px 18px;border-radius:10px;font-size:14px;font-weight:600;box-shadow:0 6px 24px rgba(0,0,0,.2);z-index:600;animation:toastIn .25s ease;white-space:nowrap}
@keyframes toastIn{from{opacity:0;transform:translateX(-50%) translateY(-8px)}to{opacity:1;transform:translateX(-50%) translateY(0)}}
.toast-ok{background:#064e3b;color:#fff}
.toast-err{background:#7f1d1d;color:#fff}

/* CHECKIN */
.sb-checkin-wrap{position:relative}

/* PRINT STYLES */
@media print {
  body > *:not(#printFrame) { display:none!important; }
}
</style>
</head>
<body>

<!-- SIDEBAR -->
<aside class="sidebar" id="mainSidebar">
  <a href="<%= ctx %>/pos" class="sb-logo">
    <span class="sb-logo-icon">MV</span>
    <span class="sb-logo-full">Medicare POS</span>
  </a>

  <a href="<%= ctx %>/pos" class="sb-btn active">
    <span class="sb-icon">🛒</span>
    <span class="sb-label">Bán hàng POS</span>
    <span class="sb-tip">Bán hàng POS</span>
  </a>
  <a href="#" class="sb-btn">
    <span class="sb-icon">🧾</span>
    <span class="sb-label">Hóa đơn của tôi</span>
    <span class="sb-tip">Hóa đơn của tôi</span>
  </a>

  <div class="sb-divider"></div>

  <a href="#" class="sb-btn">
    <span class="sb-icon">📦</span>
    <span class="sb-label">Tồn kho</span>
    <span class="sb-tip">Tồn kho</span>
  </a>
  <a href="#" class="sb-btn">
    <span class="sb-icon">👥</span>
    <span class="sb-label">Khách hàng</span>
    <span class="sb-tip">Khách hàng</span>
  </a>
  <a href="#" class="sb-btn">
    <span class="sb-icon">📊</span>
    <span class="sb-label">Báo cáo</span>
    <span class="sb-tip">Báo cáo</span>
  </a>

  <div class="sb-bottom">
    <div class="sb-divider" style="margin-bottom:6px"></div>
    <div class="sb-checkin-wrap">
      <button class="sb-btn" id="checkinBtn" onclick="toggleCheckinPanel()">
        <span class="sb-icon"><%= isLoggedIn ? "🟢" : "👤" %></span>
        <span class="sb-label"><%= isLoggedIn ? fullName : "Đăng nhập" %></span>
        <span class="sb-tip"><%= isLoggedIn ? "Ca làm / " + fullName : "Đăng nhập nhân viên" %></span>
      </button>
      <div id="checkinPanel" style="display:none;position:absolute;left:68px;bottom:0;width:230px;
           background:#1e3a5f;border:1px solid rgba(255,255,255,.2);border-radius:13px;
           padding:15px;box-shadow:0 8px 32px rgba(0,0,0,.4);z-index:9999">
        <% if (isLoggedIn) { %>
        <div style="display:flex;align-items:center;gap:9px;margin-bottom:11px">
          <div style="width:34px;height:34px;background:linear-gradient(135deg,#3f83f8,#1a56db);border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:800;color:#fff"><%= initials %></div>
          <div><div style="font-size:13px;font-weight:700;color:#fff"><%= fullName %></div><div style="font-size:10.5px;color:rgba(255,255,255,.45)">Đã đăng nhập</div></div>
        </div>
        <a href="<%= ctx %>/staff-dashboard" style="display:block;padding:8px 11px;background:rgba(255,255,255,.1);border-radius:8px;color:#93c5fd;font-size:12.5px;font-weight:600;text-decoration:none;margin-bottom:5px;text-align:center">📅 Xem ca làm việc</a>
        <a href="<%= ctx %>/logout?from=staff" style="display:block;padding:8px 11px;background:rgba(239,68,68,.15);border-radius:8px;color:#fca5a5;font-size:12.5px;font-weight:600;text-decoration:none;text-align:center">⏻ Kết thúc ca</a>
        <% } else { %>
        <div style="font-size:12px;color:rgba(255,255,255,.5);margin-bottom:11px">Đăng nhập để điểm danh và ghi nhận doanh thu theo nhân viên</div>
        <a href="<%= ctx %>/staff-login" style="display:block;padding:10px 11px;background:linear-gradient(135deg,#1a56db,#1e3a5f);border-radius:8px;color:#fff;font-size:13px;font-weight:700;text-decoration:none;text-align:center">👤 Đăng nhập nhân viên</a>
        <div style="font-size:10.5px;color:rgba(255,255,255,.25);margin-top:8px;text-align:center">POS vẫn hoạt động không cần đăng nhập</div>
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
    <span class="topbar-date">📅 <span id="topDate"></span></span>
  </div>

  <!-- Category tabs -->
  <div class="cat-bar" id="catBar">
    <button class="cat-tab active" data-cat="0" onclick="filterCat(this,0)">Tất cả</button>
    <c:forEach var="cat" items="${categories}">
      <button class="cat-tab" data-cat="${cat.categoryId}"
              onclick="filterCat(this,${cat.categoryId})"><c:out value="${cat.categoryName}"/></button>
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
           data-name="<c:out value='${m.medicineName}' />"
           data-price="${m.sellingPrice}"
           data-unit="<c:out value='${m.unit}' />"
           data-cat="${m.categoryId}"
           data-rx="${m.prescriptionRequired}"
           data-dosage="<c:out value='${m.dosage}' />"
           data-code="<c:out value='${m.medicineCode}' />"
           data-stock="${mStock}"
           data-batchno="<c:out value='${mBatch}' />"
           data-expiry="${mExpiry}"
           data-minstock="${m.minInventory}"
           onclick="addToCart(this)">
        <button class="mc-info-btn" onclick="event.stopPropagation();showMedInfo(${m.medicineId})" title="Xem thông tin thuốc"><i>i</i></button>
        <div class="mc-top">
          <span class="mc-code"><c:out value="${m.medicineCode}" /></span>
          <c:choose>
            <c:when test="${m.prescriptionRequired}"><span class="mc-badge mb-rx">Rx</span></c:when>
            <c:otherwise><span class="mc-badge mb-otc">OTC</span></c:otherwise>
          </c:choose>
        </div>
        <div class="mc-name"><c:out value="${m.medicineName}" /></div>
        <div class="mc-unit"><c:out value="${m.unit}" /></div>
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
      <input type="text" id="custPhone" placeholder="Nhập SĐT để tìm khách…" oninput="onCustInput()" autocomplete="off">
      <button class="cust-btn" onclick="searchCustomer()">🔍</button>
    </div>
    <div class="cust-found-row" id="custFound">
      <span>👤</span>
      <span class="cust-found-name" id="custFoundName"></span>
      <span style="font-size:12px;color:var(--muted)" id="custFoundPhone"></span>
      <button class="cust-rm" onclick="removeCustomer()">✕</button>
    </div>
  </div>

  <!-- Items -->
  <div class="inv-items" id="invItems">
    <div class="inv-empty"><div class="ei">🛒</div><p>Giỏ hàng trống<br><small>Bấm vào thẻ thuốc để thêm</small></p></div>
  </div>

  <!-- Bottom forms -->
  <div class="inv-forms">
    <!-- Payment methods — compact tabs -->
    <div>
      <div class="f-label" style="margin-bottom:4px">Phương thức thanh toán</div>
      <div class="pay-tabs">
        <button class="pay-tab active" data-method="CASH" onclick="selectPay(this)"><span class="pi">💵</span><span class="pt">Tiền mặt</span></button>
        <button class="pay-tab" data-method="CARD" onclick="selectPay(this)"><span class="pi">🏦</span><span class="pt">Thẻ</span></button>
        <button class="pay-tab" data-method="TRANSFER" onclick="selectPay(this)"><span class="pi">🔄</span><span class="pt">Chuyển khoản</span></button>
        <button class="pay-tab" data-method="EWALLET" onclick="selectPay(this)"><span class="pi">📱</span><span class="pt">Ví điện tử</span></button>
        <button class="pay-tab" data-method="QR_CODE" onclick="selectPay(this)"><span class="pi">📷</span><span class="pt">QR</span></button>
      </div>
    </div>

    <!-- Cash section (only for CASH) -->
    <div class="cash-section show" id="cashSection">
      <div class="cash-quick" id="cashQuickBtns"></div>
      <div class="cash-input-row">
        <span class="cash-input-lbl">Tiền khách đưa</span>
        <input type="number" class="f-input cash" id="cashInput" placeholder="Nhập số tiền…" min="0" oninput="calcChange()">
      </div>
      <div class="cash-change-row cash-change-ok" id="cashChangeRow" style="display:none">
        <span class="cash-change-lbl" id="cashChangeLbl">Tiền thừa trả khách</span>
        <span class="cash-change-val" id="cashChangeVal">—</span>
      </div>
    </div>
  </div>

  <!-- Totals -->
  <div class="inv-totals">
    <div class="total-row"><span>Tạm tính</span><span id="sumSub">0đ</span></div>
    <div class="total-row">
      <span>Giảm giá (₫)</span>
      <input type="number" class="f-input discount" id="discountInput" value="0" min="0" oninput="updateTotal()" style="width:80px;height:26px;font-size:12px;padding:0 7px">
    </div>
    <div class="total-row" id="cashNeedRow" style="display:none">
      <span style="font-size:12px;color:var(--muted)">Cần thanh toán</span>
      <span id="cashNeedVal" style="font-size:13px;font-weight:800;color:var(--blue)">0đ</span>
    </div>
    <div class="total-row grand"><span>TỔNG CỘNG</span><span class="tv" id="sumTotal">0đ</span></div>
  </div>

  <!-- Checkout button -->
  <div class="inv-action">
    <button class="btn-checkout" id="checkoutBtn" onclick="doCheckout()" disabled>
      🛒 THANH TOÁN
    </button>
  </div>
</div>

<!-- MEDICINE INFO MODAL -->
<div class="info-modal" id="infoModal">
  <div class="im-backdrop" onclick="closeInfoModal()"></div>
  <div class="im-panel">
    <button class="im-close" onclick="closeInfoModal()">✕</button>
    <span class="im-rx" id="imRx"></span>
    <div class="im-name" id="imName"></div>
    <div class="im-code" id="imCode"></div>
    <div class="im-rows" id="imRows"></div>
    <div class="im-price-row">
      <span class="im-price-lbl">Đơn giá bán</span>
      <span class="im-price-val" id="imPrice"></span>
    </div>
    <button class="im-add-btn" id="imAddBtn" onclick="addFromInfo()">＋ Thêm vào giỏ hàng</button>
  </div>
</div>

<!-- SUCCESS MODAL -->
<div class="success-modal" id="successModal">
  <div class="sm-backdrop" onclick="newInvoice()"></div>
  <div class="sm-panel">
    <span class="sm-icon">✅</span>
    <div class="sm-title">Thanh toán thành công!</div>
    <div class="sm-code" id="smCode"></div>
    <div class="sm-change" id="smChange"></div>
    <div class="sm-total" id="smTotal"></div>
    <div class="sm-btns">
      <button class="sm-btn-new" onclick="newInvoice()">＋ Hóa đơn mới</button>
      <button class="sm-btn-print" onclick="printReceipt()">🖨 In hóa đơn</button>
    </div>
  </div>
</div>

<script>
const ctx = '<%= ctx %>';
const sellerName = '<%= fullName %>';
let cart = [];
let selectedCustomer = null;
let selectedPayment = 'CASH';
let allMedicines = [];
let currentInvoice = null; // {id, code, total, discount, cashReceived, change}

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
      const show = !q || m.name.toLowerCase().includes(q) || m.code.toLowerCase().includes(q);
      m.el.style.display = (show && (activeCat === 0 || m.catId === activeCat)) ? '' : 'none';
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
  const q = document.getElementById('searchInput').value.toLowerCase().trim();
  allMedicines.forEach(m => {
    const matchCat  = catId === 0 || m.catId === catId;
    const matchName = !q || m.name.toLowerCase().includes(q) || m.code.toLowerCase().includes(q);
    m.el.style.display = (matchCat && matchName) ? '' : 'none';
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
  document.getElementById('cashChangeRow').style.display = 'none';
  renderCart();
}

function fmtMoney(n) { return new Intl.NumberFormat('vi-VN').format(Math.round(n)) + 'đ'; }
function fmtDate(d) {
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
      if (item.expiry)  meta.push('📅 HSD: ' + fmtDate(item.expiry));
      const metaHtml = meta.length ? '<div class="inv-i-meta">' + meta.join(' · ') + '</div>' : '';
      return '<div class="inv-item">'
        + '<div class="inv-i-info">'
          + '<div class="inv-i-name">' + escHtml(item.name) + '</div>'
          + '<div class="inv-i-price">' + fmtMoney(item.price) + ' / ' + escHtml(item.unit) + '</div>'
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
    // không set disabled=false ở đây — updateCheckoutBtnState() qua updateTotal→calcChange sẽ xử lý
  }
  updateTotal();
}

function escHtml(s) {
  return (s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
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
  document.getElementById('sumSub').textContent   = fmtMoney(sub);
  document.getElementById('sumTotal').textContent = fmtMoney(tot);
  document.getElementById('invSubtitle').textContent = qty + ' sản phẩm · ' + fmtMoney(tot);
  const needEl = document.getElementById('cashNeedVal');
  if (needEl) needEl.textContent = fmtMoney(tot);
  updateQuickButtons(tot);
  calcChange();
}

function updateQuickButtons(total) {
  const wrap = document.getElementById('cashQuickBtns');
  if (!wrap) return;
  const amounts = buildQuickAmounts(total);
  wrap.innerHTML = amounts.map(a =>
    '<button class="cash-q-btn" onclick="setCash('+a+')">' + fmtMoney(a) + '</button>'
  ).join('');
}

function buildQuickAmounts(total) {
  const result = [];
  // Exact amount
  if (total > 0) result.push(total);
  // Round up to next 10K, 20K, 50K, 100K
  const rounds = [10000, 20000, 50000, 100000, 200000, 500000];
  for (const r of rounds) {
    const rounded = Math.ceil(total / r) * r;
    if (rounded > total && !result.includes(rounded) && result.length < 5) result.push(rounded);
    if (result.length >= 5) break;
  }
  return result.slice(0, 4);
}

function setCash(amount) {
  document.getElementById('cashInput').value = amount;
  calcChange();
}

// ── Payment ──
function selectPay(btn) {
  document.querySelectorAll('.pay-tab').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  selectedPayment = btn.dataset.method;
  const cashSec = document.getElementById('cashSection');
  const needRow = document.getElementById('cashNeedRow');
  if (selectedPayment === 'CASH') {
    cashSec.classList.add('show');
    if (needRow) needRow.style.display = 'none';
  } else {
    cashSec.classList.remove('show');
    document.getElementById('cashChangeRow').style.display = 'none';
    if (needRow) needRow.style.display = 'flex';
  }
  updateCheckoutBtnState();
}

function calcChange() {
  updateCheckoutBtnState();
  if (selectedPayment !== 'CASH') return;
  const total    = calcTotal();
  const received = parseFloat(document.getElementById('cashInput').value) || 0;
  const changeRow = document.getElementById('cashChangeRow');
  const valEl     = document.getElementById('cashChangeVal');
  const lblEl     = document.getElementById('cashChangeLbl');
  if (received <= 0) { changeRow.style.display='none'; return; }
  changeRow.style.display = 'flex';
  const change = received - total;
  if (change >= 0) {
    changeRow.className = 'cash-change-row cash-change-ok';
    lblEl.textContent = 'Tiền thừa trả khách';
    valEl.className   = 'cash-change-val change-ok';
    valEl.textContent = fmtMoney(change);
  } else {
    changeRow.className = 'cash-change-row cash-change-err';
    lblEl.textContent = 'Thiếu';
    valEl.className   = 'cash-change-val change-err';
    valEl.textContent = '⚠ ' + fmtMoney(Math.abs(change));
  }
}

// Cập nhật trạng thái nút Thanh Toán:
// — Disabled khi giỏ trống
// — Disabled khi CASH nhưng chưa nhập tiền hoặc chưa đủ
function updateCheckoutBtnState() {
  const btn = document.getElementById('checkoutBtn');
  if (!btn) return;
  if (cart.length === 0) { btn.disabled = true; return; }
  if (selectedPayment === 'CASH') {
    const total = calcTotal();
    const cash  = parseFloat(document.getElementById('cashInput').value) || 0;
    btn.disabled = (cash <= 0 || cash < total);
  } else {
    btn.disabled = false;
  }
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
        selectedCustomer = { id: data.id, name: data.name, phone: data.phone };
        document.getElementById('custFoundName').textContent  = data.name;
        document.getElementById('custFoundPhone').textContent = data.phone;
        row.style.display = 'flex';
      } else {
        selectedCustomer = null;
        showToast('⚠️ Không tìm thấy khách hàng', 'err');
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
  const total = calcTotal();
  if (selectedPayment === 'CASH') {
    const cashEl = document.getElementById('cashInput');
    const received = parseFloat(cashEl.value) || 0;
    if (received <= 0) {
      showToast('⚠️ Vui lòng nhập số tiền khách đưa!', 'err');
      cashEl.focus();
      return;
    }
    if (received < total) {
      showToast('⚠️ Tiền khách đưa (' + fmtMoney(received) + ') chưa đủ — thiếu ' + fmtMoney(total - received) + '!', 'err');
      cashEl.focus();
      return;
    }
  }
  submitSale();
}

function submitSale() {
  const btn = document.getElementById('checkoutBtn');
  btn.disabled = true;
  btn.innerHTML = '⏳ Đang xử lý…';
  const fd = new URLSearchParams();
  fd.append('action', 'complete-sale');
  fd.append('paymentMethod', selectedPayment);
  fd.append('discount', document.getElementById('discountInput').value || '0');
  if (selectedCustomer) fd.append('customerId', selectedCustomer.id);
  cart.forEach(item => { fd.append('medId[]', item.id); fd.append('qty[]', item.qty); });
  fd.append('_csrf', '${csrfToken}');
  fetch(ctx + '/pos', {
    method: 'POST',
    body: fd,
    headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest' }
  })
    .then(r => {
      if (!r.ok && r.status !== 200) throw new Error('HTTP ' + r.status);
      return r.json();
    })
    .then(data => {
      if (data.ok) {
        const total    = calcTotal();
        const disc     = parseFloat(document.getElementById('discountInput').value) || 0;
        const received = selectedPayment === 'CASH' ? (parseFloat(document.getElementById('cashInput').value) || 0) : 0;
        const change   = received > 0 ? Math.max(0, received - total) : 0;
        const now      = new Date();

        // Snapshot cart và customer trước khi xóa
        currentInvoice = {
          id:           data.invoiceId || 0,
          code:         data.invoiceCode || '',
          total:        total,
          subtotal:     cart.reduce((s,i) => s + i.price*i.qty, 0),
          discount:     disc,
          cashReceived: received,
          change:       change,
          date:         now,
          items:        JSON.parse(JSON.stringify(cart)),
          customer:     selectedCustomer ? {...selectedCustomer} : null
        };

        // Trừ tồn kho trực tiếp trên card — không cần reload trang
        cart.forEach(item => {
          const med = allMedicines.find(m => m.id === item.id);
          if (!med) return;
          med.stock = Math.max(0, med.stock - item.qty);
          const card = med.el;
          card.dataset.stock = med.stock;
          const stockEl = card.querySelector('.mc-stock');
          if (stockEl) {
            if (med.stock === 0) {
              stockEl.className = 'mc-stock stock-out';
              stockEl.textContent = 'Hết hàng';
              card.classList.add('out-of-stock');
            } else {
              const minStock = parseInt(card.dataset.minstock) || 0;
              stockEl.className = 'mc-stock ' + (med.stock <= minStock ? 'stock-low' : 'stock-ok');
              stockEl.textContent = 'Còn ' + med.stock;
            }
          }
        });

        // Xóa giỏ hàng ngay sau thanh toán thành công
        clearCart();

        // Hiển thị modal thành công
        document.getElementById('smCode').textContent  = (data.invoiceCode || '') + ' · ' + formatDateTime(now);
        document.getElementById('smTotal').textContent = fmtMoney(total);
        document.getElementById('smChange').textContent = (received > 0 && selectedPayment === 'CASH')
          ? 'Tiền thừa: ' + fmtMoney(change) : '';
        document.getElementById('successModal').classList.add('show');
        showToast('✅ Thanh toán thành công!', 'ok');
      } else {
        showToast('❌ ' + (data.msg || 'Lỗi xử lý!'), 'err');
        btn.disabled = false; btn.innerHTML = '🛒 THANH TOÁN';
      }
    })
    .catch(err => {
      showToast('❌ Lỗi kết nối!', 'err');
      btn.disabled = false; btn.innerHTML = '🛒 THANH TOÁN';
      console.error(err);
    });
}

function formatDateTime(d) {
  const h = d.getHours().toString().padStart(2,'0');
  const m = d.getMinutes().toString().padStart(2,'0');
  const dd = d.getDate().toString().padStart(2,'0');
  const mm = (d.getMonth()+1).toString().padStart(2,'0');
  return h + ':' + m + ' · ' + dd + '/' + mm + '/' + d.getFullYear();
}

function newInvoice() {
  closeSuccess();
  // Cart đã được xóa ngay khi thanh toán thành công — chỉ focus lại ô tìm kiếm
  document.getElementById('searchInput').focus();
}

function closeSuccess() {
  document.getElementById('successModal').classList.remove('show');
  const btn = document.getElementById('checkoutBtn');
  if (cart.length > 0) {
    btn.disabled = false;
    btn.innerHTML = '🛒 THANH TOÁN';
  }
}

// ── Medicine Info Modal ──
let infoMedId = null;
function showMedInfo(medId) {
  const m = allMedicines.find(x => x.id === medId);
  if (!m) return;
  infoMedId = medId;
  const el = (id) => document.getElementById(id);
  const rx = m.rx;
  el('imRx').textContent = rx ? 'Kê đơn (Rx)' : 'Không kê đơn (OTC)';
  el('imRx').style.cssText = rx
    ? 'background:#fee2e2;color:#991b1b'
    : 'background:#d1fae5;color:#065f46';
  el('imName').textContent = m.name;
  el('imCode').textContent = 'Mã: ' + m.code;
  el('imPrice').textContent = fmtMoney(m.price);
  const rows = [];
  rows.push(['Đơn vị', m.unit]);
  if (m.dosage) rows.push(['Liều dùng', m.dosage]);
  if (m.batchNo) rows.push(['Số lô', m.batchNo]);
  if (m.expiry)  rows.push(['Hạn sử dụng', fmtDate(m.expiry)]);
  rows.push(['Tồn kho', m.stock <= 0 ? '<span style="color:#dc2626;font-weight:700">Hết hàng</span>'
           : '<span style="color:#059669;font-weight:700">Còn ' + m.stock + ' ' + m.unit + '</span>']);
  el('imRows').innerHTML = rows.map(r =>
    '<div class="im-row"><span class="ik">' + r[0] + '</span><span class="iv">' + r[1] + '</span></div>'
  ).join('');
  const addBtn = el('imAddBtn');
  addBtn.disabled = m.stock <= 0;
  addBtn.textContent = m.stock <= 0 ? 'Hết hàng' : '＋ Thêm vào giỏ hàng';
  document.getElementById('infoModal').classList.add('show');
}
function closeInfoModal() { document.getElementById('infoModal').classList.remove('show'); infoMedId = null; }
function addFromInfo() {
  if (!infoMedId) return;
  const m = allMedicines.find(x => x.id === infoMedId);
  if (m) addToCart(m.el);
  closeInfoModal();
}

// ── Receipt printing ──
function printReceipt() {
  if (!currentInvoice) { showToast('⚠️ Không có dữ liệu hóa đơn để in!', 'err'); return; }
  const inv = currentInvoice;
  const d   = inv.date;
  const dateStr = d.getDate().toString().padStart(2,'0') + '/' +
                  (d.getMonth()+1).toString().padStart(2,'0') + '/' + d.getFullYear();

  let itemRows = '';
  inv.items.forEach((item, idx) => {
    itemRows += '<tr>'
      + '<td style="text-align:center;padding:4px 6px">' + (idx+1) + '</td>'
      + '<td style="padding:4px 6px">' + escHtml(item.name) + '</td>'
      + '<td style="text-align:center;padding:4px 6px">' + escHtml(item.unit) + '</td>'
      + '<td style="text-align:center;padding:4px 6px">' + item.qty + '</td>'
      + '<td style="text-align:right;padding:4px 6px">' + fmt(item.price) + '</td>'
      + '<td style="text-align:right;padding:4px 6px;font-weight:700">' + fmt(item.price * item.qty) + '</td>'
      + '</tr>';
  });

  var html = '<!DOCTYPE html>'
    + '<html lang="vi"><head>'
    + '<meta charset="UTF-8">'
    + '<title>Hóa đơn ' + escHtml(inv.code) + '</title>'
    + '<style>'
    + '* { margin:0; padding:0; box-sizing:border-box; }'
    + 'body { font-family: "Courier New", monospace; font-size: 12px; color: #000; padding: 8px; max-width: 320px; margin: 0 auto; }'
    + '.center { text-align: center; }'
    + '.bold { font-weight: bold; }'
    + '.title { font-size: 15px; font-weight: 900; margin: 4px 0; }'
    + '.divider { border-top: 1px dashed #000; margin: 7px 0; }'
    + '.divider2 { border-top: 2px solid #000; margin: 7px 0; }'
    + 'table { width: 100%; border-collapse: collapse; font-size: 11px; }'
    + 'th { background: #eee; padding: 4px 6px; font-weight: 700; border-bottom: 1px solid #000; }'
    + 'td { vertical-align: top; }'
    + '.totals { margin-top: 6px; }'
    + '.totals-row { display: flex; justify-content: space-between; padding: 2px 0; font-size: 12px; }'
    + '.totals-row.grand { font-size: 14px; font-weight: 900; border-top: 2px solid #000; padding-top: 5px; margin-top: 3px; }'
    + '.footer { text-align: center; margin-top: 10px; font-style: italic; font-size: 11.5px; }'
    + '.kv { display: flex; justify-content: space-between; font-size: 11.5px; padding: 2px 0; }'
    + '@media print { body { padding: 0; } button { display: none; } }'
    + '</style>'
    + '</head><body>'
    + '<div class="center">'
    + '<div class="bold" style="font-size:14px">NHÀ THUỐC Medicare</div>'
    + '<div>Địa chỉ: 123 Đường Ba Cu, P.4, TP. Vũng Tàu</div>'
    + '<div>Điện thoại: 0901.234.567</div>'
    + '</div>'
    + '<div class="divider2"></div>'
    + '<div class="center"><div class="title">HÓA ĐƠN BÁN LẾ</div></div>'
    + '<div class="divider"></div>'
    + '<div class="kv"><span class="bold">Số HĐ:</span><span>#' + escHtml(inv.code) + '</span></div>'
    + '<div class="kv"><span class="bold">Ngày lập:</span><span>' + dateStr + '</span></div>'
    + '<div class="kv"><span class="bold">Khách hàng:</span><span>' + (inv.customer ? escHtml(inv.customer.name) : 'Khách lẻ') + '</span></div>'
    + (inv.customer ? '<div class="kv"><span class="bold">SĐT:</span><span>' + escHtml(inv.customer.phone) + '</span></div>' : '')
    + '<div class="kv"><span class="bold">Dược sĩ bán:</span><span>' + escHtml(sellerName) + '</span></div>'
    + '<div class="divider"></div>'
    + '<table><thead><tr>'
    + '<th style="text-align:center;width:24px">STT</th>'
    + '<th>Tên Thuốc / Vật Tư</th>'
    + '<th style="text-align:center;width:30px">ĐVT</th>'
    + '<th style="text-align:center;width:24px">SL</th>'
    + '<th style="text-align:right;width:60px">Đơn Giá</th>'
    + '<th style="text-align:right;width:66px">Thành Tiền</th>'
    + '</tr></thead><tbody>' + itemRows + '</tbody></table>'
    + '<div class="divider"></div>'
    + '<div class="totals">'
    + '<div class="totals-row"><span>Tổng tiền hàng:</span><span>' + fmt(inv.subtotal) + '</span></div>'
    + '<div class="totals-row"><span>Giảm giá:</span><span>-' + fmt(inv.discount) + '</span></div>'
    + '<div class="totals-row grand"><span>TỔNG THANH TOÁN:</span><span>' + fmt(inv.total) + '</span></div>'
    + '</div>'
    + (inv.cashReceived > 0
        ? '<div class="divider"></div>'
          + '<div class="totals-row"><span>Tiền khách đưa:</span><span>' + fmt(inv.cashReceived) + '</span></div>'
          + '<div class="totals-row"><span>Tiền thối:</span><span>' + fmt(inv.change) + '</span></div>'
        : '')
    + '<div class="divider"></div>'
    + '<div class="footer">'
    + '<div>-- Chúc quý khách sức khỏe và một ngày tốt lành --</div>'
    + '<div style="margin-top:4px;font-size:10px;color:#555">Hẹn gặp lại quý khách!</div>'
    + '</div>'
    + '<div style="height:16px"></div>'
    + '<div class="center" style="margin-top:8px">'
    + '<button onclick="window.print()" style="padding:8px 20px;background:#1a56db;color:#fff;border:none;border-radius:6px;cursor:pointer;font-size:13px;font-weight:700;font-family:sans-serif">🖶 In hóa đơn</button>'
    + '<button onclick="window.close()" style="padding:8px 16px;background:#e5e7eb;color:#111;border:none;border-radius:6px;cursor:pointer;font-size:13px;margin-left:6px;font-family:sans-serif">✕ Đóng</button>'
    + '</div>'
    + '</body></html>';

  const win = window.open('', '_blank', 'width=380,height=600,toolbar=0,menubar=0,scrollbars=1');
  if (win) {
    win.document.write(html);
    win.document.close();
  } else {
    showToast('⚠️ Trình duyệt chặn popup — vui lòng cho phép!', 'err');
  }
  closeSuccess();
}

function fmt(n) { return new Intl.NumberFormat('vi-VN').format(Math.round(n||0)) + 'đ'; }

function showToast(msg, type) {
  const t = document.createElement('div');
  t.className = 'toast toast-' + type;
  t.textContent = msg;
  document.body.appendChild(t);
  setTimeout(() => { t.style.opacity='0'; t.style.transition='opacity .3s'; setTimeout(()=>t.remove(),300); }, 2800);
}

function toggleCheckinPanel() {
  const p   = document.getElementById('checkinPanel');
  const sb  = document.getElementById('mainSidebar');
  const expanded = sb && sb.matches(':hover');
  p.style.left = expanded ? '218px' : '68px';
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
