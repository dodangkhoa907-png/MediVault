<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    String _uid = request.getParameter("uid");
    com.medicare.entity.Account acc = null;
    if (_uid != null && !_uid.isEmpty()) {
        acc = (com.medicare.entity.Account) session.getAttribute("staffAccount_" + _uid);
    }
    if (acc == null) {
        acc = (com.medicare.entity.Account) session.getAttribute("staffAccount");
    }
    boolean isLoggedIn = (acc != null && acc.getRoleId() != 1);
    String fullName = isLoggedIn ? (acc.getFullName() != null ? acc.getFullName() : acc.getUsername()) : "Dược sĩ";
    String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
    String ctx = request.getContextPath();
    // Multi-POS: đọc station từ session (mặc định 1)
    Integer posStation = (Integer) session.getAttribute("posStation");
    if (posStation == null) posStation = 0; // 0 = chưa chọn
    String stationLabel = posStation > 0 ? "Quầy " + posStation : "Chọn quầy";
    // Screen state — set bởi PosServlet qua req.setAttribute("screenState", ...)
    String screenState = (String) request.getAttribute("screenState");
    if (screenState == null) screenState = "IDLE";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
    
    
    
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Medicare POS — Bán hàng</title>

<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --blue:#1a56db;--blue2:#1e3a5f;--sky:#3f83f8;
  --surface:#f3f4f6;--white:#fff;--border:#e5e7eb;
  --navy:#111827;--muted:#6b7280;
  --green:#059669;--red:#dc2626;--gold:#d97706;--orange:#f97316;
  --sw:64px;--rw:420px;
}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif;overflow:hidden;background:var(--surface);color:var(--navy);font-size:14px}
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
  font-size:12px;font-weight:800;color:#fff;letter-spacing:-.5px;flex-shrink:0}
.sb-logo-full{font-size:13.5px;font-weight:800;color:#fff;opacity:0;
  transition:opacity .15s .07s;white-space:nowrap}
.sidebar:hover .sb-logo-full{opacity:1}
/* Nav buttons */
.sb-btn{height:44px;display:flex;align-items:center;gap:11px;padding:0 13px;
  border-radius:9px;color:rgba(255,255,255,.5);cursor:pointer;transition:.15s;
  text-decoration:none;margin:1px 6px;overflow:hidden;background:transparent;
  border:none;font-family:inherit;width:calc(100% - 12px)}
.sb-btn:hover,.sb-btn.active{color:#fff;background:rgba(255,255,255,.15)}
.sb-icon{font-size:18px;min-width:28px;text-align:center;flex-shrink:0;line-height:1}
.sb-label{font-size:12.5px;font-weight:750;color:rgba(255,255,255,.75);
  white-space:nowrap;opacity:0;transition:opacity .14s .06s}
.sb-btn:hover .sb-label,.sb-btn.active .sb-label{color:#fff}
.sidebar:hover .sb-label{opacity:1}
/* Tooltip (only when collapsed) */
.sb-tip{position:absolute;left:62px;background:rgba(15,23,42,.92);color:#fff;
  font-size:11px;font-weight:750;padding:4px 10px;border-radius:6px;
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
.med-count-badge{background:#eff6ff;color:var(--blue);font-size:13px;font-weight:750;padding:5px 12px;border-radius:7px;white-space:nowrap;flex-shrink:0}
.topbar-date{font-size:12.5px;color:var(--muted);white-space:nowrap;flex-shrink:0;display:flex;align-items:center;gap:4px}

/* CATEGORY — pill style */
.cat-bar{height:46px;padding:0 14px;display:flex;align-items:center;gap:6px;overflow-x:auto;flex-shrink:0;background:#fff;border-bottom:1px solid var(--border)}
.cat-bar::-webkit-scrollbar{display:none}
.cat-tab{height:30px;padding:0 15px;border-radius:100px;border:1.5px solid transparent;font-size:12.5px;font-weight:750;color:#64748b;background:#f1f5f9;cursor:pointer;white-space:nowrap;transition:.18s;flex-shrink:0;font-family:inherit;letter-spacing:.1px}
.cat-tab:hover{color:var(--blue);background:#dbeafe;border-color:#bfdbfe}
.cat-tab.active{color:#fff;background:var(--blue);border-color:var(--blue);box-shadow:0 2px 8px rgba(37,99,235,.35)}

/* MED GRID */
.med-grid{flex:1;overflow-y:auto;padding:14px 16px;display:grid;grid-template-columns:repeat(auto-fill,minmax(152px,1fr));gap:10px;align-content:start}
.med-grid::-webkit-scrollbar{width:4px}
.med-grid::-webkit-scrollbar-thumb{background:var(--border);border-radius:4px}

/* Med Card — centered product card layout */
.med-card{background:#fff;border:1.5px solid var(--border);border-radius:14px;padding:10px 12px 12px;cursor:pointer;transition:.2s;display:flex;flex-direction:column;align-items:center;position:relative;min-height:148px;text-align:center}
.med-card:hover{border-color:#93c5fd;box-shadow:0 6px 20px rgba(59,130,246,.15);transform:translateY(-2px)}
.med-card.out-of-stock{opacity:.42;cursor:not-allowed}
.med-card.out-of-stock:hover{transform:none;border-color:var(--border);box-shadow:none}
/* Top row: stock left, badge right */
.mc-top{width:100%;display:flex;align-items:center;justify-content:space-between;margin-bottom:8px;gap:3px}
.mc-stock{font-size:10px;font-weight:750;padding:2px 7px;border-radius:20px;white-space:nowrap}
.stock-ok{background:#d1fae5;color:#065f46}
.stock-low{background:#fef3c7;color:#92400e}
.stock-out{background:#fee2e2;color:#991b1b}
.mc-badge{font-size:10px;font-weight:750;padding:2px 7px;border-radius:20px;white-space:nowrap;flex-shrink:0}
.mb-rx{background:#fee2e2;color:#991b1b}
.mb-otc{background:#d1fae5;color:#065f46}
/* Center: icon */
.mc-icon{font-size:28px;line-height:1;margin-bottom:7px}
/* Name */
.mc-name{font-size:14px;font-weight:800;color:#0f172a;line-height:1.3;display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden;width:100%;margin-bottom:3px}
/* Unit */
.mc-unit{font-size:11px;color:#94a3b8;width:100%;margin-bottom:auto}
/* Price — bottom, separated */
.mc-price-row{width:100%;margin-top:9px;padding-top:8px;border-top:1px solid #f1f5f9;text-align:center}
.mc-price{font-size:17px;font-weight:800;color:var(--blue);letter-spacing:-.4px}
.empty-state{grid-column:1/-1;text-align:center;padding:60px 20px;color:var(--muted)}
.empty-state .ei{font-size:44px;margin-bottom:12px}

/* RIGHT PANEL */
.invoice-panel{width:var(--rw);height:100vh;background:#fff;border-left:2px solid var(--border);display:flex;flex-direction:column;overflow:hidden;flex-shrink:0}

/* Header */
.inv-head{padding:13px 16px;background:linear-gradient(135deg,#1e3a5f,#1a56db);flex-shrink:0}
.inv-head-row{display:flex;align-items:center;justify-content:space-between}
.inv-head h3{font-size:15px;font-weight:800;color:#fff}
.inv-head-sub{font-size:12px;color:rgba(255,255,255,.6);margin-top:2px}
.btn-clear{background:rgba(255,255,255,.12);border:1px solid rgba(255,255,255,.25);color:#fff;padding:5px 11px;border-radius:7px;font-size:12px;font-weight:750;cursor:pointer;font-family:inherit;transition:.15s}
.btn-clear:hover{background:rgba(255,255,255,.28)}

/* Customer */
.inv-customer{padding:9px 16px;border-bottom:1px solid var(--border);flex-shrink:0}
.f-label{font-size:11px;font-weight:750;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:5px}
.cust-wrap{display:flex;gap:6px}
.cust-wrap input{flex:1;height:34px;padding:0 11px;border:1.5px solid var(--border);border-radius:8px;font-size:13px;font-family:inherit;outline:none}
.cust-wrap input:focus{border-color:var(--sky)}
.cust-btn{width:34px;height:34px;background:var(--blue);border:none;border-radius:8px;color:#fff;font-size:13px;cursor:pointer;display:flex;align-items:center;justify-content:center;flex-shrink:0}
.cust-btn-add{background:linear-gradient(135deg,#0d9488,#0f766e);font-size:20px;font-weight:750;line-height:1}
.cust-btn-add:hover{filter:brightness(1.08)}
.cust-found-row{margin-top:6px;padding:6px 10px;background:#f0fdf4;border:1px solid #bbf7d0;border-radius:8px;display:none;align-items:center;gap:7px;font-size:13px}
.cust-found-name{font-weight:750;color:var(--green);flex:1}
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
.inv-i-name{font-size:13px;font-weight:750;color:var(--navy)}
.inv-i-meta{font-size:10.5px;color:var(--muted);margin-top:2px}
.inv-i-price{font-size:12px;color:var(--blue);font-weight:750}
.qty-ctrl{display:flex;align-items:center;gap:4px;flex-shrink:0}
.qty-btn{width:25px;height:25px;border-radius:6px;border:1.5px solid var(--border);background:#fff;font-size:13px;font-weight:750;cursor:pointer;display:flex;align-items:center;justify-content:center;line-height:1;color:var(--navy);transition:.15s}
.qty-btn:hover{border-color:var(--sky);color:var(--blue)}
.qty-btn.minus:hover{border-color:var(--red);color:var(--red)}
.qty-val{width:38px;height:25px;text-align:center;font-size:13px;font-weight:750;border:1.5px solid var(--border);border-radius:6px;outline:none;font-family:inherit;color:var(--navy);background:#fff;padding:0}
.qty-val:focus{border-color:var(--sky)}
.qty-val::-webkit-inner-spin-button,.qty-val::-webkit-outer-spin-button{-webkit-appearance:none}
.inv-i-sub{font-size:13px;font-weight:800;color:var(--navy);white-space:nowrap;flex-shrink:0}
.inv-i-rm{color:#d1d5db;cursor:pointer;background:none;border:none;font-size:15px;line-height:1;transition:.15s;flex-shrink:0}
.inv-i-rm:hover{color:var(--red)}

/* BOTTOM FORMS */
.inv-forms{padding:7px 14px;border-top:2px solid var(--border);background:#f9fafb;flex-shrink:0;display:flex;flex-direction:column;gap:6px}
.form-row{display:flex;align-items:center;justify-content:space-between;gap:8px}
.form-row .f-label{margin-bottom:0;flex-shrink:0}
.f-input{height:32px;padding:0 10px;border:1.5px solid var(--border);border-radius:8px;font-size:13px;font-weight:750;font-family:inherit;outline:none;color:var(--navy);background:#fff;transition:.15s}
.f-input:focus{border-color:var(--sky)}
.f-input.discount{width:90px;text-align:right}
.f-input.note{width:100%;height:30px;font-weight:400}

/* Payment method — 3 big cards */
.pay-methods{display:grid;grid-template-columns:repeat(3,1fr);gap:7px}
.pay-method-card{border:2px solid var(--border);background:#f8fafc;border-radius:13px;padding:12px 6px 10px;cursor:pointer;transition:.2s;display:flex;flex-direction:column;align-items:center;gap:4px;font-family:inherit}
.pay-method-card:hover{border-color:#93c5fd;background:#eff6ff}
.pay-method-card.active{border-color:var(--blue);background:#eff6ff;box-shadow:0 0 0 3px rgba(37,99,235,.12)}
.pmc-icon{font-size:22px;line-height:1}
.pmc-label{font-size:11.5px;font-weight:750;color:#64748b;text-align:center;letter-spacing:.1px}
.pay-method-card.active .pmc-label{color:var(--blue)}
/* QR / Card detail panels (same weight as cash section) */
.pay-detail-section{display:none;background:#f8fafc;border:1.5px solid var(--border);border-radius:13px;padding:14px 15px;margin-top:7px}
.pay-detail-section.show{display:block}
.pdi-row{display:flex;align-items:center;gap:12px}
.pdi-icon{font-size:30px;flex-shrink:0;line-height:1}
.pdi-body{flex:1;min-width:0}
.pdi-title{font-size:13px;font-weight:800;color:#0f172a;margin-bottom:4px}
.pdi-sub{font-size:11.5px;color:#64748b;line-height:1.5}
.pdi-amount{font-size:20px;font-weight:800;color:var(--blue);white-space:nowrap;flex-shrink:0}

/* Medicine info button — bottom-right of card */
.mc-info-btn{position:absolute;bottom:8px;right:8px;width:20px;height:20px;border-radius:50%;background:none;border:1.5px solid #D1D5DB;cursor:pointer;display:flex;align-items:center;justify-content:center;color:#9CA3AF;transition:.18s;z-index:2;padding:0;line-height:1}
.mc-info-btn:hover{background:#0D9488;border-color:#0D9488;color:#fff;box-shadow:0 2px 8px rgba(13,148,136,.3)}

/* Med info drawer */
.med-drawer-bd{position:fixed;inset:0;background:rgba(0,0,0,.28);backdrop-filter:blur(1.5px);z-index:440;opacity:0;pointer-events:none;transition:opacity .28s}
.med-drawer-bd.show{opacity:1;pointer-events:auto}
.med-drawer{position:fixed;top:0;right:0;bottom:0;width:380px;max-width:92vw;background:#fff;z-index:441;box-shadow:-10px 0 50px rgba(0,0,0,.2);transform:translateX(100%);transition:transform .3s cubic-bezier(.4,0,.2,1);display:flex;flex-direction:column;overflow:hidden}
.med-drawer.show{transform:translateX(0)}
/* Drawer header */
.mdd-head{padding:18px 20px 14px;border-bottom:1.5px solid #F1F5F9;flex-shrink:0;background:linear-gradient(135deg,#F8FAFC,#EFF6FF)}
.mdd-rx{display:inline-flex;align-items:center;gap:5px;font-size:10.5px;font-weight:750;padding:2px 10px;border-radius:20px;margin-bottom:8px}
.mdd-name{font-size:17px;font-weight:800;color:#0F172A;line-height:1.25;margin-bottom:3px}
.mdd-code{font-size:11.5px;color:#94A3B8}
.mdd-close{position:absolute;top:14px;right:14px;width:32px;height:32px;border-radius:9px;background:#F1F5F9;border:none;font-size:16px;cursor:pointer;color:#64748B;display:flex;align-items:center;justify-content:center;transition:.15s;line-height:1}
.mdd-close:hover{background:#E2E8F0;color:#0F172A}
/* Drawer body */
.mdd-body{flex:1;overflow-y:auto;padding:16px 20px}
.mdd-body::-webkit-scrollbar{width:3px}
.mdd-body::-webkit-scrollbar-thumb{background:#E2E8F0;border-radius:3px}
.mdd-section{margin-bottom:14px}
.mdd-sec-title{font-size:10px;font-weight:800;color:#94A3B8;text-transform:uppercase;letter-spacing:.8px;margin-bottom:8px;display:flex;align-items:center;gap:6px}
.mdd-sec-title::after{content:'';flex:1;height:1px;background:#F1F5F9}
.mdd-text{font-size:13px;color:#334155;line-height:1.6;background:#F8FAFC;border-radius:8px;padding:9px 12px;border-left:3px solid #E2E8F0}
.mdd-warn .mdd-text{background:#FFF7ED;border-left-color:#FB923C;color:#9A3412}
.mdd-contra .mdd-text{background:#FEF2F2;border-left-color:#F87171;color:#991B1B}
.mdd-rows{display:grid;grid-template-columns:1fr 1fr;gap:6px}
.mdd-row{background:#F8FAFC;border-radius:8px;padding:8px 10px}
.mdd-row .dk{font-size:10.5px;color:#94A3B8;font-weight:750;margin-bottom:2px}
.mdd-row .dv{font-size:12.5px;font-weight:750;color:#0F172A}
.mdd-row.full{grid-column:1/-1}
/* Price + stock bar */
.mdd-price-bar{display:flex;align-items:center;justify-content:space-between;background:#EFF6FF;border-radius:10px;padding:10px 14px;margin-bottom:14px}
.mdd-price-lbl{font-size:11.5px;color:var(--blue);font-weight:750}
.mdd-price-val{font-size:20px;font-weight:800;color:var(--blue)}
/* Footer */
.mdd-foot{padding:12px 20px;border-top:1.5px solid #F1F5F9;flex-shrink:0;display:flex;gap:8px}
.mdd-add-btn{flex:1;height:42px;border-radius:10px;border:none;background:linear-gradient(135deg,#1a56db,#1e3a5f);color:#fff;font-size:13.5px;font-weight:800;cursor:pointer;font-family:inherit;transition:.15s}
.mdd-add-btn:hover{box-shadow:0 4px 14px rgba(26,86,219,.35)}
.mdd-add-btn:disabled{opacity:.45;cursor:not-allowed;box-shadow:none}
.mdd-close-btn{height:42px;padding:0 16px;border-radius:10px;border:1.5px solid #E2E8F0;background:#fff;color:#64748B;font-size:13px;font-weight:750;cursor:pointer;font-family:inherit;transition:.15s;white-space:nowrap}
.mdd-close-btn:hover{background:#F1F5F9}

/* Cash section */
.cash-section{display:none;flex-direction:column;gap:7px;background:#fff;border:1.5px solid var(--border);border-radius:10px;padding:10px 12px}
.cash-section.show{display:flex}
.cash-total-bar{display:flex;align-items:center;justify-content:space-between;padding:8px 0;border-bottom:1px dashed var(--border)}
.cash-total-lbl{font-size:12px;color:var(--muted);font-weight:750}
.cash-total-val{font-size:20px;font-weight:800;color:var(--blue)}
.cash-quick{display:flex;gap:5px;flex-wrap:wrap}
.cash-q-btn{padding:4px 10px;background:#eff6ff;color:var(--blue);border:none;border-radius:6px;font-size:12px;font-weight:750;cursor:pointer;font-family:inherit;transition:.15s}
.cash-q-btn:hover{background:#dbeafe}
.cash-input-row{display:flex;align-items:center;gap:8px}
.cash-input-lbl{font-size:12px;font-weight:750;color:var(--muted);white-space:nowrap}
.f-input.cash{flex:1;text-align:right;font-size:14px}
.cash-change-row{display:flex;align-items:center;justify-content:space-between;padding:7px 10px;border-radius:8px;font-size:13px}
.cash-change-ok{background:#f0fdf4;border:1px solid #bbf7d0}
.cash-change-err{background:#fef2f2;border:1px solid #fecaca}
.cash-change-lbl{color:var(--muted);font-weight:750}
.cash-change-val{font-weight:800;font-size:15px}
.change-ok{color:var(--green)}
.change-err{color:var(--red)}

/* TOTALS */
.inv-totals{padding:8px 16px 5px;border-top:1px solid var(--border);flex-shrink:0}
.total-row{display:flex;justify-content:space-between;align-items:center;font-size:13px;color:var(--muted);margin-bottom:4px}
.total-row.grand{font-size:15px;font-weight:800;color:var(--navy);margin-top:6px;padding-top:6px;border-top:2px solid var(--border)}
.total-row.grand .tv{font-size:18px;font-weight:800;color:var(--blue)}

/* Checkout button */
.inv-action{padding:9px 16px 13px;flex-shrink:0}
.btn-checkout{width:100%;height:50px;border-radius:12px;border:none;background:linear-gradient(135deg,#059669,#047857);color:#fff;font-size:15px;font-weight:800;cursor:pointer;font-family:'Plus Jakarta Sans',sans-serif;display:flex;align-items:center;justify-content:center;gap:9px;transition:.2s;letter-spacing:-.2px}
.btn-checkout:hover:not(:disabled){box-shadow:0 6px 22px rgba(5,150,105,.45);transform:translateY(-1px)}
.btn-checkout:disabled{opacity:.4;cursor:not-allowed;transform:none;box-shadow:none}

/* SUCCESS MODAL */
.success-modal{display:none;position:fixed;inset:0;z-index:500;align-items:center;justify-content:center}
.success-modal.show{display:flex}
.sm-backdrop{position:absolute;inset:0;background:rgba(0,0,0,.5);backdrop-filter:blur(4px)}
.sm-panel{position:relative;width:380px;background:#fff;border-radius:18px;padding:28px 26px 24px;text-align:center;box-shadow:0 24px 64px rgba(0,0,0,.22);animation:popIn .28s cubic-bezier(.34,1.56,.64,1)}
@keyframes popIn{from{opacity:0;transform:scale(.85)}to{opacity:1;transform:scale(1)}}
.sm-icon{font-size:52px;margin-bottom:10px;display:block}
.sm-title{font-size:21px;font-weight:800;color:var(--navy);margin-bottom:4px}
.sm-code{font-size:12px;color:var(--muted);margin-bottom:5px}
.sm-change{font-size:14px;font-weight:750;color:var(--green);margin-bottom:12px;min-height:20px}
.sm-total{font-size:32px;font-weight:800;color:var(--blue);margin-bottom:18px}
.sm-btns{display:flex;gap:8px}
.sm-btn-new{flex:1;height:44px;border-radius:10px;background:linear-gradient(135deg,var(--orange),#ea580c);color:#fff;border:none;font-size:13px;font-weight:800;cursor:pointer;font-family:inherit}
.sm-btn-print{flex:1;height:44px;border-radius:10px;border:2px solid var(--border);background:#fff;color:var(--navy);font-size:13px;font-weight:750;cursor:pointer;font-family:inherit;display:flex;align-items:center;justify-content:center;gap:6px}
.sm-btn-print:hover{border-color:var(--blue);color:var(--blue)}

/* TOAST */
.toast{position:fixed;top:16px;left:50%;transform:translateX(-50%);padding:10px 18px;border-radius:10px;font-size:14px;font-weight:750;box-shadow:0 6px 24px rgba(0,0,0,.2);z-index:600;animation:toastIn .25s ease;white-space:nowrap}
@keyframes toastIn{from{opacity:0;transform:translateX(-50%) translateY(-8px)}to{opacity:1;transform:translateX(-50%) translateY(0)}}
.toast-ok{background:#064e3b;color:#fff}
.toast-err{background:#7f1d1d;color:#fff}

/* CHECKIN */
.sb-checkin-wrap{position:relative}

/* STATION BADGE */
.station-badge{display:flex;align-items:center;gap:6px;background:#eff6ff;border:1.5px solid #bfdbfe;border-radius:9px;padding:4px 12px;cursor:pointer;transition:.15s;flex-shrink:0}
.station-badge:hover{background:#dbeafe;border-color:var(--sky)}
.station-dot{width:8px;height:8px;border-radius:50%;background:var(--blue);animation:pulse 2s infinite}
@keyframes pulse{0%,100%{opacity:1;transform:scale(1)}50%{opacity:.6;transform:scale(.85)}}
.station-label{font-size:12px;font-weight:750;color:var(--blue);white-space:nowrap}
.station-staff{font-size:10.5px;color:var(--muted);font-weight:750}

/* STATION SELECTOR MODAL */
.station-modal{display:none;position:fixed;inset:0;z-index:9500;align-items:center;justify-content:center}
.station-modal.show{display:flex}
.stm-backdrop{position:absolute;inset:0;background:rgba(0,0,0,.6);backdrop-filter:blur(4px)}
.stm-panel{position:relative;width:420px;background:#fff;border-radius:20px;padding:28px 26px 24px;box-shadow:0 24px 64px rgba(0,0,0,.28);animation:popIn .25s cubic-bezier(.34,1.56,.64,1)}
.stm-title{font-size:18px;font-weight:800;color:var(--navy);margin-bottom:4px}
.stm-sub{font-size:13px;color:var(--muted);margin-bottom:18px}
.station-grid{display:grid;grid-template-columns:1fr 1fr;gap:10px;margin-bottom:18px}
.station-opt{border:2px solid var(--border);border-radius:12px;padding:16px 14px;cursor:pointer;transition:.15s;display:flex;flex-direction:column;gap:4px;background:#fff}
.station-opt:hover{border-color:var(--sky);background:#eff6ff}
.station-opt.selected{border-color:var(--blue);background:#eff6ff}
.so-num{font-size:22px;font-weight:800;color:var(--blue)}
.so-label{font-size:12px;font-weight:750;color:var(--muted)}
.btn-confirm-station{width:100%;height:44px;border-radius:11px;border:none;background:linear-gradient(135deg,#059669,#047857);color:#fff;font-size:14px;font-weight:800;cursor:pointer;font-family:inherit}

/* FACE CHECK-IN MODAL */
.face-modal{display:none;position:fixed;inset:0;z-index:9500;align-items:center;justify-content:center}
.face-modal.show{display:flex}
.fm-backdrop{position:absolute;inset:0;background:rgba(0,0,0,.7);backdrop-filter:blur(6px)}
.fm-panel{position:relative;width:460px;background:#0f172a;border-radius:20px;padding:22px 22px 20px;box-shadow:0 24px 64px rgba(0,0,0,.5);animation:popIn .25s cubic-bezier(.34,1.56,.64,1)}
.fm-close{position:absolute;top:14px;right:16px;background:rgba(255,255,255,.08);border:none;color:rgba(255,255,255,.6);width:28px;height:28px;border-radius:7px;cursor:pointer;font-size:14px;display:flex;align-items:center;justify-content:center}
.fm-title{font-size:16px;font-weight:800;color:#f1f5f9;margin-bottom:2px}
.fm-sub{font-size:12px;color:#64748b;margin-bottom:14px}
.face-video-wrap{position:relative;width:100%;aspect-ratio:4/3;background:#020617;border-radius:12px;overflow:hidden;margin-bottom:12px}
#faceVideo{width:100%;height:100%;object-fit:cover;transform:scaleX(-1)}
#faceCanvas{position:absolute;inset:0;width:100%;height:100%;transform:scaleX(-1)}
.face-overlay{position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;pointer-events:none}
.face-ring{width:220px;height:220px;border:3px solid rgba(255,255,255,.3);border-radius:50%;box-shadow:0 0 0 2000px rgba(0,0,0,.3)}
.face-ring.scanning{border-color:#3b82f6;animation:ringPulse 1.2s ease-in-out infinite}
.face-ring.matched{border-color:#10b981}
@keyframes ringPulse{0%,100%{box-shadow:0 0 0 2000px rgba(0,0,0,.3),0 0 0 0 rgba(59,130,246,.4)}50%{box-shadow:0 0 0 2000px rgba(0,0,0,.3),0 0 0 12px rgba(59,130,246,0)}}
.fm-status{font-size:13px;font-weight:750;color:#94a3b8;text-align:center;min-height:20px;margin-bottom:10px}
.fm-status.ok{color:#4ade80}
.fm-status.err{color:#f87171}
.fm-actions{display:flex;gap:8px}
.fm-btn-cancel{flex:1;height:38px;border-radius:9px;border:1px solid rgba(255,255,255,.12);background:transparent;color:rgba(255,255,255,.5);font-size:13px;cursor:pointer;font-family:inherit}
.fm-btn-checkin{flex:2;height:38px;border-radius:9px;border:none;background:linear-gradient(135deg,#059669,#047857);color:#fff;font-size:13px;font-weight:750;cursor:pointer;font-family:inherit;display:none}
.fm-no-face{font-size:12px;color:#f87171;text-align:center;margin-bottom:8px;display:none}
.fm-enrolled-count{font-size:11px;color:#475569;text-align:center;margin-bottom:8px}
.fm-loader{display:flex;align-items:center;justify-content:center;gap:8px;color:#64748b;font-size:12px;padding:20px}
.fm-spinner{width:20px;height:20px;border:2px solid rgba(255,255,255,.1);border-top-color:#3b82f6;border-radius:50%;animation:spin .7s linear infinite}
@keyframes spin{to{transform:rotate(360deg)}}

/* PRINT STYLES */
@media print {
  body > *:not(#printFrame) { display:none!important; }
}

/* Staff action menu in topbar */
.staff-action-wrap{position:relative}
.staff-action-btn{display:flex;align-items:center;gap:6px;background:rgba(255,255,255,.15);border:1px solid rgba(255,255,255,.25);border-radius:9px;padding:6px 12px;color:#fff;font-size:13px;font-weight:750;cursor:pointer;font-family:inherit;transition:.15s}
.staff-action-btn:hover{background:rgba(255,255,255,.22)}
.sa-arrow{font-size:11px;opacity:.7;transition:transform .2s}
.staff-action-wrap.open .sa-arrow{transform:rotate(180deg)}
.staff-action-menu{display:none;position:absolute;top:calc(100% + 8px);right:0;min-width:186px;background:#fff;border:1px solid #e5e7eb;border-radius:13px;box-shadow:0 8px 32px rgba(0,0,0,.18);z-index:600;overflow:hidden}
.staff-action-menu.open{display:block}
.staff-action-menu button{display:block;width:100%;padding:10px 16px;background:none;border:none;text-align:left;cursor:pointer;font-family:inherit;font-size:13.5px;color:#374151;font-weight:750;transition:.1s}
.staff-action-menu button:hover{background:#f3f4f6}
.sam-divider{height:1px;background:#e5e7eb;margin:2px 0}
.staff-action-menu button.sam-danger{color:#dc2626}
.staff-action-menu button.sam-danger:hover{background:#fef2f2}

/* QR PAYMENT MODAL */
.qr-modal{display:none;position:fixed;inset:0;z-index:9600;align-items:center;justify-content:center}
.qr-modal.show{display:flex}
.qr-backdrop{position:absolute;inset:0;background:rgba(15,23,42,.65);backdrop-filter:blur(5px)}
.qrm-panel{position:relative;background:#fff;border-radius:22px;padding:26px 28px 22px;width:380px;max-width:calc(100vw - 32px);box-shadow:0 24px 64px rgba(0,0,0,.3);display:flex;flex-direction:column;align-items:center;gap:12px;animation:qrmPop .22s cubic-bezier(.34,1.56,.64,1)}
@keyframes qrmPop{from{transform:scale(.88) translateY(16px);opacity:0}to{transform:scale(1) translateY(0);opacity:1}}

.qrm-header{display:flex;align-items:center;gap:8px;width:100%}
.qrm-logo-icon{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,#0ea5e9,#2563eb);display:flex;align-items:center;justify-content:center;font-size:18px}
.qrm-logo-txt{font-size:16px;font-weight:800;color:#0f172a;letter-spacing:-.3px}
.qrm-logo-sub{font-size:11px;color:#94a3b8;font-weight:750}
.qrm-logo-info{display:flex;flex-direction:column;gap:1px}

.qrm-amount{font-size:34px;font-weight:800;color:#1d4ed8;letter-spacing:-1px;line-height:1}
.qrm-amount-label{font-size:11.5px;color:#94a3b8;font-weight:750;margin-top:-6px}

.qrm-qr-box{background:#f8fafc;border:2.5px solid #e2e8f0;border-radius:16px;padding:14px;position:relative}
.qrm-qr-box canvas,.qrm-qr-box img{display:block;border-radius:8px}
.qrm-qr-center{position:absolute;top:50%;left:50%;transform:translate(-50%,-50%);width:40px;height:40px;background:#fff;border-radius:8px;display:flex;align-items:center;justify-content:center;font-size:22px;box-shadow:0 0 0 3px #f8fafc}

.qrm-banks{display:flex;gap:5px;flex-wrap:wrap;justify-content:center}
.qrm-bank{background:#f1f5f9;border-radius:6px;padding:3px 9px;font-size:10.5px;font-weight:750;color:#475569}

.qrm-status-row{display:flex;align-items:center;gap:8px}
.qrm-dot{width:9px;height:9px;border-radius:50%;background:#10b981;flex-shrink:0;box-shadow:0 0 0 0 rgba(16,185,129,.4);animation:qrmDot 1.4s ease infinite}
@keyframes qrmDot{0%{box-shadow:0 0 0 0 rgba(16,185,129,.5)}70%{box-shadow:0 0 0 9px rgba(16,185,129,0)}100%{box-shadow:0 0 0 0 rgba(16,185,129,0)}}
.qrm-dot.paid{background:#2563eb;animation:none;box-shadow:none}
.qrm-dot.expired{background:#ef4444;animation:none;box-shadow:none}
.qrm-status-txt{font-size:13px;font-weight:750;color:#334155}
.qrm-timer{font-size:12px;color:#94a3b8}
.qrm-timer b{color:#f59e0b}
.qrm-divider{width:100%;height:1px;background:#f1f5f9}

.qrm-success-box{display:none;flex-direction:column;align-items:center;gap:6px;padding:8px 0}
.qrm-success-box.show{display:flex}
.qrm-success-icon{font-size:52px;animation:qrmBounce .35s cubic-bezier(.34,1.56,.64,1)}
@keyframes qrmBounce{from{transform:scale(.4)}to{transform:scale(1)}}
.qrm-success-txt{font-size:17px;font-weight:800;color:#059669}

.qrm-checkout-link{font-size:11px;color:#94a3b8;text-decoration:none;display:flex;align-items:center;gap:4px}
.qrm-checkout-link:hover{color:#3b82f6}
.qrm-cancel-btn{width:100%;padding:12px;border:none;border-radius:11px;background:#f1f5f9;color:#64748b;font-size:13.5px;font-weight:750;cursor:pointer;font-family:inherit;transition:.15s;letter-spacing:.1px}
.qrm-cancel-btn:hover{background:#e2e8f0;color:#334155}

/* ── END SHIFT REPORT MODAL ─────────────────────────────────────── */
.esr-bd{position:fixed;inset:0;background:rgba(15,23,42,.6);backdrop-filter:blur(4px);z-index:10000;display:flex;align-items:center;justify-content:center;opacity:0;pointer-events:none;transition:.22s}
.esr-bd.show{opacity:1;pointer-events:all}
.esr-box{background:#fff;border-radius:20px;width:860px;max-width:96vw;max-height:92vh;overflow:hidden;display:flex;flex-direction:column;box-shadow:0 20px 60px rgba(15,23,42,.28);transform:translateY(22px);transition:.22s}
.esr-bd.show .esr-box{transform:translateY(0)}
.esr-head{background:linear-gradient(135deg,#1e3a5f,#1a56db);padding:17px 22px;display:flex;align-items:center;justify-content:space-between;flex-shrink:0}
.esr-head-title{color:#fff;font-size:15.5px;font-weight:800;display:flex;align-items:center;gap:7px}
.esr-head-meta{font-size:11.5px;color:rgba(255,255,255,.55);margin-top:3px}
.esr-hclose{background:rgba(255,255,255,.1);border:none;color:rgba(255,255,255,.7);width:30px;height:30px;border-radius:8px;cursor:pointer;font-size:15px;display:flex;align-items:center;justify-content:center;flex-shrink:0;transition:.15s}
.esr-hclose:hover{background:rgba(255,255,255,.22);color:#fff}
.esr-body{display:grid;grid-template-columns:1fr 1fr;overflow:auto;flex:1}
.esr-left{padding:20px 20px;border-right:1.5px solid #F1F5F9}
.esr-right{padding:20px 20px;background:#F8FAFF}
.esr-sec-title{font-size:11px;font-weight:800;color:#64748B;text-transform:uppercase;letter-spacing:.8px;margin-bottom:11px}
.esr-grand{background:linear-gradient(135deg,#0F172A,#1e3a5f);border-radius:12px;padding:12px 15px;margin-bottom:12px;display:flex;align-items:center;justify-content:space-between}
.esr-grand-lbl{color:rgba(255,255,255,.6);font-size:11px;font-weight:750;margin-bottom:3px}
.esr-grand-val{color:#fff;font-size:21px;font-weight:800;letter-spacing:-.4px}
.esr-inv-chip{display:inline-flex;align-items:center;background:rgba(255,255,255,.12);border-radius:8px;padding:5px 10px;font-size:11.5px;font-weight:750;color:rgba(255,255,255,.8);white-space:nowrap}
.esr-prows{display:flex;flex-direction:column;gap:7px;margin-bottom:13px}
.esr-prow{display:flex;align-items:center;padding:9px 12px;background:#fff;border:1.5px solid #E2E8F0;border-radius:9px}
.esr-prow-icon{font-size:15px;width:20px;text-align:center;flex-shrink:0}
.esr-prow-lbl{font-size:12.5px;color:#334155;flex:1;margin-left:8px}
.esr-prow-val{font-size:13px;font-weight:800;color:#0F172A}
.esr-prow-val.zero{color:#CBD5E1;font-weight:750}
.esr-note{font-size:11.5px;color:#94A3B8;line-height:1.5;padding:9px 11px;background:#F8FAFC;border-radius:9px;border:1px dashed #E2E8F0}
.esr-crows{display:flex;flex-direction:column;gap:0;margin-bottom:11px}
.esr-crow{display:flex;align-items:center;justify-content:space-between;padding:7px 0;font-size:13px;border-bottom:1px solid #F1F5F9}
.esr-crow:last-child{border-bottom:none}
.esr-crow-lbl{color:#64748B;font-weight:750}
.esr-crow-val{font-weight:750;color:#0F172A}
.esr-expected-box{background:#F0FDF4;border:2px solid #BBF7D0;border-radius:12px;padding:12px 15px;margin-bottom:14px;display:flex;align-items:center;justify-content:space-between}
.esr-exp-lbl{font-size:11.5px;font-weight:750;color:#15803D}
.esr-exp-val{font-size:20px;font-weight:800;color:#15803D}
.esr-inp-wrap{margin-bottom:11px}
.esr-inp-lbl{font-size:12px;font-weight:750;color:#374151;margin-bottom:5px}
.esr-inp{width:100%;height:50px;border:2px solid #E2E8F0;border-radius:11px;font-size:19px;font-weight:800;text-align:right;padding:0 14px;color:#0F172A;font-family:inherit;box-sizing:border-box;transition:.15s}
.esr-inp:focus{outline:none;border-color:#2563EB;box-shadow:0 0 0 3px rgba(37,99,235,.12)}
.esr-vbox{border-radius:11px;padding:10px 14px;display:flex;align-items:center;justify-content:space-between;transition:.2s;min-height:42px}
.esr-vbox.empty{background:#F8FAFC;border:1.5px dashed #E2E8F0}
.esr-vbox.zero{background:#F0FDF4;border:1.5px solid #BBF7D0}
.esr-vbox.minus{background:#FEF2F2;border:1.5px solid #FECACA}
.esr-vbox.plus{background:#FFFBEB;border:1.5px solid #FDE68A}
.esr-vlbl{font-size:12.5px;font-weight:750}
.esr-vlbl.empty{color:#94A3B8}.esr-vlbl.zero{color:#16A34A}.esr-vlbl.minus{color:#DC2626}.esr-vlbl.plus{color:#D97706}
.esr-vval{font-size:15px;font-weight:800}
.esr-vval.empty{color:#CBD5E1}.esr-vval.zero{color:#16A34A}.esr-vval.minus{color:#DC2626}.esr-vval.plus{color:#D97706}
.esr-foot{padding:14px 22px;border-top:1.5px solid #F1F5F9;display:flex;align-items:center;justify-content:flex-end;gap:9px;flex-shrink:0}
.esr-cancel{height:42px;padding:0 18px;border-radius:10px;border:1.5px solid #E2E8F0;background:#fff;color:#64748B;font-size:13px;font-weight:750;cursor:pointer;font-family:inherit;transition:.15s}
.esr-cancel:hover{background:#F1F5F9}
.esr-confirm{height:42px;padding:0 22px;border-radius:10px;border:none;background:linear-gradient(135deg,#DC2626,#B91C1C);color:#fff;font-size:13px;font-weight:800;cursor:pointer;font-family:inherit;transition:.15s;display:flex;align-items:center;gap:7px}
.esr-confirm:hover:not(:disabled){background:linear-gradient(135deg,#B91C1C,#991B1B)}
.esr-confirm:disabled{background:#CBD5E1;cursor:not-allowed}
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
  <a href="#" class="sb-btn" onclick="event.preventDefault(); openMyInvModal();">
    <span class="sb-icon">🧾</span>
    <span class="sb-label">Xem hóa đơn</span>
    <span class="sb-tip">Xem hóa đơn</span>
  </a>

  <div class="sb-divider"></div>

  <a href="#" class="sb-btn">
    <span class="sb-icon">📦</span>
    <span class="sb-label">Tồn kho</span>
    <span class="sb-tip">Tồn kho</span>
  </a>
  <a href="#" class="sb-btn" onclick="event.preventDefault();openCustMgmt()">
    <span class="sb-icon">👥</span>
    <span class="sb-label">Khách hàng</span>
    <span class="sb-tip">Khách hàng</span>
  </a>
  <div class="sb-bottom">
    <div class="sb-divider" style="margin-bottom:6px"></div>
    <div class="sb-checkin-wrap">
<% String checkinAction = isLoggedIn ? "toggleCheckinPanel()" : "openFaceModal()"; %>
      <button class="sb-btn" id="checkinBtn" onclick="<%= checkinAction %>">
        <span class="sb-icon"><%= isLoggedIn ? "🟢" : "👤" %></span>
        <span class="sb-label"><%= isLoggedIn ? fullName : "Điểm danh" %></span>
        <span class="sb-tip"><%= isLoggedIn ? "Ca làm / " + fullName : "Điểm danh nhân viên" %></span>
      </button>
      <div id="checkinPanel" style="display:none;position:absolute;left:68px;bottom:0;width:230px;
           background:#1e3a5f;border:1px solid rgba(255,255,255,.2);border-radius:13px;
           padding:15px;box-shadow:0 8px 32px rgba(0,0,0,.4);z-index:9999">
        <% if (isLoggedIn) { %>
        <div style="display:flex;align-items:center;gap:9px;margin-bottom:11px">
          <div style="width:34px;height:34px;background:linear-gradient(135deg,#3f83f8,#1a56db);border-radius:9px;display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:800;color:#fff"><%= initials %></div>
          <div><div style="font-size:13px;font-weight:750;color:#fff"><%= fullName %></div><div style="font-size:10.5px;color:rgba(255,255,255,.45)">Đang ca làm việc</div></div>
        </div>
        <a href="<%= ctx %>/staff-dashboard" style="display:block;padding:8px 11px;background:rgba(255,255,255,.1);border-radius:8px;color:#93c5fd;font-size:12.5px;font-weight:750;text-decoration:none;margin-bottom:5px;text-align:center">📅 Xem lịch ca</a>
        <button onclick="openMyInvModal();toggleCheckinPanel();" style="display:block;width:100%;padding:8px 11px;background:rgba(255,255,255,.1);border-radius:8px;color:#a5f3fc;font-size:12.5px;font-weight:750;text-align:center;border:none;cursor:pointer;font-family:inherit;margin-bottom:5px">🧾 Hóa đơn của tôi</button>
        <button onclick="openOpenCashModal();toggleCheckinPanel();" style="display:block;width:100%;padding:8px 11px;background:rgba(255,255,255,.1);border-radius:8px;color:#86efac;font-size:12.5px;font-weight:750;text-align:center;border:none;cursor:pointer;font-family:inherit;margin-bottom:5px">💵 Khai báo tiền đầu ca (tùy chọn)</button>
        <button onclick="openEndShiftModal();toggleCheckinPanel();" style="display:block;width:100%;padding:8px 11px;background:rgba(239,68,68,.15);border-radius:8px;color:#fca5a5;font-size:12.5px;font-weight:750;text-align:center;border:none;cursor:pointer;font-family:inherit">⏻ Kết thúc ca</button>
        <% } else { %>
        <div style="font-size:11.5px;color:rgba(255,255,255,.5);margin-bottom:11px">Điểm danh để ghi nhận doanh số theo nhân viên</div>
        <!-- Nút điểm danh khuôn mặt -->
        <button onclick="openFaceModal();toggleCheckinPanel();" style="width:100%;padding:10px;background:linear-gradient(135deg,#059669,#047857);border:none;border-radius:8px;color:#fff;font-size:13px;font-weight:750;cursor:pointer;font-family:inherit;margin-bottom:6px;display:flex;align-items:center;justify-content:center;gap:6px">
          📷 Điểm danh khuôn mặt
        </button>
        <div style="font-size:10.5px;color:rgba(255,255,255,.25);margin-top:6px;text-align:center">POS hoạt động bình thường khi chưa đăng nhập</div>
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
      <input type="text" id="searchInput" placeholder="Tìm thuốc theo tên hoặc mã vạch…" autocomplete="off">
    </div>
    <!-- Station badge -->
    <div class="station-badge" onclick="openStationModal()" id="stationBadge" title="Chọn quầy POS">
      <span class="station-dot"></span>
      <div>
        <div class="station-label" id="stationLabel"><%= stationLabel %></div>
        <div class="station-staff" id="stationStaff"><%= isLoggedIn ? fullName : "Chưa điểm danh" %></div>
      </div>
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

  <%-- Banner nhắc điểm danh — POS KHÔNG khóa, bán hàng bình thường --%>
  <% if (!isLoggedIn) { %>
  <div id="checkinBanner" style="padding:10px 16px;background:linear-gradient(90deg,#fffbeb,#fef3c7);border-bottom:2px solid #f59e0b;display:flex;align-items:center;gap:12px;flex-shrink:0">
    <span style="font-size:20px;flex-shrink:0">⏰</span>
    <div style="flex:1;min-width:0">
      <div style="font-size:13px;font-weight:750;color:#92400e">Chưa điểm danh ca làm</div>
      <div style="font-size:11.5px;color:#b45309;margin-top:1px">Vui lòng điểm danh để ghi nhận doanh số theo nhân viên</div>
    </div>
    <button onclick="openFaceModal()" style="padding:8px 18px;background:#f59e0b;border:none;border-radius:9px;color:#fff;font-size:13px;font-weight:750;cursor:pointer;font-family:inherit;white-space:nowrap;flex-shrink:0;display:flex;align-items:center;gap:6px">
      📷 Điểm danh ngay
    </button>
  </div>
  <% } %>

  <%-- Modal: Khai báo tiền đầu ca (mở ca) --%>
  <div id="openCashModal" style="display:none;position:fixed;inset:0;z-index:9600;background:rgba(11,22,40,.55);align-items:center;justify-content:center;padding:20px">
    <div style="background:#fff;border-radius:18px;max-width:400px;width:100%;padding:28px;box-shadow:0 24px 70px rgba(0,0,0,.35)">
      <div style="display:flex;align-items:center;gap:10px;margin-bottom:6px">
        <span style="font-size:26px">💵</span>
        <h3 style="margin:0;font-size:18px;font-weight:800;color:#0f172a">Khai báo tiền đầu ca</h3>
      </div>
      <p style="font-size:12.5px;color:#64748b;margin:0 0 16px;line-height:1.5">Đếm tiền mặt hiện có trong két và nhập số tiền để mở ca. Số này dùng đối soát khi kết ca.</p>
      <label style="font-size:12.5px;font-weight:750;color:#334155;display:block;margin-bottom:6px">Tiền mặt trong két (đ) <span style="color:#dc2626">*</span></label>
      <input type="number" id="openCashInput" min="0" step="1000" placeholder="VD: 500000"
             style="width:100%;border:1.5px solid #e2e8f0;border-radius:11px;padding:12px 14px;font-size:17px;font-weight:750;font-family:inherit;box-sizing:border-box"
             onkeydown="if(event.key==='Enter')confirmOpenShift()">
      <div id="openCashErr" style="color:#dc2626;font-size:12px;margin-top:6px;display:none"></div>
      <button type="button" id="openShiftBtn" onclick="confirmOpenShift()"
              style="width:100%;margin-top:16px;padding:13px;background:linear-gradient(135deg,#059669,#047857);border:none;border-radius:12px;color:#fff;font-size:15px;font-weight:800;cursor:pointer;font-family:inherit">✓ Mở ca &amp; bắt đầu bán hàng</button>
    </div>
  </div>

  <%-- Modal: Hóa đơn của tôi (bill trong ca hôm nay của chính nhân viên) --%>
  <div id="myInvModal" style="display:none;position:fixed;inset:0;z-index:9600;background:rgba(11,22,40,.55);align-items:center;justify-content:center;padding:20px" onclick="if(event.target===this)closeMyInvModal()">
    <div style="background:#fff;border-radius:18px;max-width:520px;width:100%;max-height:86vh;display:flex;flex-direction:column;box-shadow:0 24px 70px rgba(0,0,0,.35);overflow:hidden">
      <div style="padding:18px 22px;background:linear-gradient(135deg,#1558A8,#3ABDE0);color:#fff;display:flex;align-items:center;justify-content:space-between">
        <div>
          <h3 style="margin:0;font-size:17px;font-weight:800">🧾 Hóa đơn của tôi — hôm nay</h3>
          <div id="myInvSummary" style="font-size:12px;opacity:.85;margin-top:3px">Đang tải…</div>
        </div>
        <button onclick="closeMyInvModal()" style="background:rgba(255,255,255,.18);border:none;color:#fff;width:32px;height:32px;border-radius:9px;font-size:16px;cursor:pointer">✕</button>
      </div>
      <div id="myInvList" style="flex:1;overflow-y:auto;padding:14px 18px">
        <div style="color:#94a3b8;font-size:13px;text-align:center;padding:26px 0">Đang tải…</div>
      </div>
    </div>
  </div>

  <%-- Modal: TẠO NHANH khách hàng (2 trường, <5 giây) --%>
  <div id="quickCreateModal" style="display:none;position:fixed;inset:0;z-index:9650;background:rgba(11,22,40,.55);align-items:center;justify-content:center;padding:20px" onclick="if(event.target===this)closeQuickCreate()">
    <div style="background:#fff;border-radius:18px;max-width:380px;width:100%;padding:26px;box-shadow:0 24px 70px rgba(0,0,0,.35)">
      <div style="display:flex;align-items:center;gap:10px;margin-bottom:4px">
        <span style="font-size:24px">⚡</span>
        <h3 style="margin:0;font-size:17px;font-weight:800;color:#0f172a">Tạo nhanh khách hàng</h3>
      </div>
      <p style="font-size:12px;color:#64748b;margin:0 0 14px">Chỉ cần SĐT + Tên. Khách tự bổ sung hồ sơ tại Cổng khách hàng sau.</p>
      <label style="font-size:12px;font-weight:750;color:#334155;display:block;margin-bottom:5px">Số điện thoại <span style="color:#dc2626">*</span></label>
      <input type="tel" id="qcPhone" maxlength="10" inputmode="numeric" placeholder="0901234567"
             oninput="this.value=this.value.replace(/\D/g,'').slice(0,10)"
             style="width:100%;border:1.5px solid #e2e8f0;border-radius:10px;padding:11px 13px;font-size:16px;font-weight:750;font-family:inherit;letter-spacing:1px;box-sizing:border-box">
      <label style="font-size:12px;font-weight:750;color:#334155;display:block;margin:12px 0 5px">Họ tên khách <span style="color:#dc2626">*</span></label>
      <input type="text" id="qcName" placeholder="VD: Đào Trần Thanh Trúc"
             onkeydown="if(event.key==='Enter')submitQuickCreate()"
             style="width:100%;border:1.5px solid #e2e8f0;border-radius:10px;padding:11px 13px;font-size:14.5px;font-family:inherit;box-sizing:border-box">
      <div style="display:flex;gap:10px;margin-top:12px">
        <label style="flex:1;display:flex;align-items:center;gap:7px;border:1.5px solid #e2e8f0;border-radius:10px;padding:9px 12px;font-size:13px;font-weight:750;cursor:pointer">
          <input type="radio" name="qcGender" value="M" style="accent-color:#0d9488"> 👨 Nam</label>
        <label style="flex:1;display:flex;align-items:center;gap:7px;border:1.5px solid #e2e8f0;border-radius:10px;padding:9px 12px;font-size:13px;font-weight:750;cursor:pointer">
          <input type="radio" name="qcGender" value="F" style="accent-color:#0d9488"> 👩 Nữ</label>
      </div>
      <div id="qcErr" style="display:none;color:#dc2626;font-size:12px;margin-top:8px"></div>
      <div style="display:flex;gap:10px;margin-top:16px">
        <button onclick="closeQuickCreate()" style="flex:1;background:#f1f5f9;color:#475569;border:none;border-radius:11px;padding:12px;font-weight:750;cursor:pointer;font-family:inherit">Hủy</button>
        <button id="qcSaveBtn" onclick="submitQuickCreate()" style="flex:2;background:linear-gradient(135deg,#0d9488,#0f766e);color:#fff;border:none;border-radius:11px;padding:12px;font-weight:800;font-size:14px;cursor:pointer;font-family:inherit">💾 Lưu &amp; Chọn</button>
      </div>
    </div>
  </div>

  <%-- Modal: THẺ NFC — chạm thẻ / nhập UID, liên kết thẻ trắng --%>
  <div id="nfcModal" style="display:none;position:fixed;inset:0;z-index:9650;background:rgba(11,22,40,.55);align-items:center;justify-content:center;padding:20px" onclick="if(event.target===this)closeNfcModal()">
    <div style="background:#fff;border-radius:18px;max-width:380px;width:100%;padding:26px;box-shadow:0 24px 70px rgba(0,0,0,.35);text-align:center">
      <div style="width:64px;height:64px;border-radius:18px;background:linear-gradient(135deg,#ccfbf1,#99f6e4);display:flex;align-items:center;justify-content:center;font-size:30px;margin:0 auto 12px">📶</div>
      <h3 style="margin:0 0 6px;font-size:17px;font-weight:800;color:#0f172a">Thẻ thành viên NFC</h3>
      <p id="nfcStatus" style="font-size:12.5px;color:#64748b;margin:0 0 14px;line-height:1.5">Chạm thẻ vào đầu đọc hoặc nhập mã thẻ…</p>
      <input type="text" id="nfcUidInput" placeholder="UID thẻ (tự nhận khi chạm)"
             onkeydown="if(event.key==='Enter')nfcLookup()"
             style="width:100%;border:1.5px solid #e2e8f0;border-radius:11px;padding:12px 13px;font-size:15px;font-weight:750;font-family:inherit;letter-spacing:1px;text-align:center;box-sizing:border-box">
      <button onclick="nfcLookup()" style="width:100%;margin-top:10px;background:linear-gradient(135deg,#1558A8,#3ABDE0);color:#fff;border:none;border-radius:11px;padding:12px;font-weight:800;font-size:14px;cursor:pointer;font-family:inherit">🔍 Tra thẻ</button>
      <div id="nfcStep2" style="display:none;margin-top:14px;padding-top:14px;border-top:1px dashed #e2e8f0">
        <input type="tel" id="nfcPhoneInput" maxlength="10" inputmode="numeric" placeholder="SĐT khách để liên kết thẻ"
               oninput="this.value=this.value.replace(/\D/g,'').slice(0,10)"
               onkeydown="if(event.key==='Enter')nfcLinkSubmit()"
               style="width:100%;border:1.5px solid #e2e8f0;border-radius:11px;padding:12px 13px;font-size:15px;font-weight:750;font-family:inherit;letter-spacing:1px;text-align:center;box-sizing:border-box">
        <button onclick="nfcLinkSubmit()" style="width:100%;margin-top:10px;background:linear-gradient(135deg,#0d9488,#0f766e);color:#fff;border:none;border-radius:11px;padding:12px;font-weight:800;font-size:14px;cursor:pointer;font-family:inherit">🔗 Liên kết thẻ</button>
      </div>
    </div>
  </div>

  <%-- Modal: QUẢN LÝ KHÁCH HÀNG — tìm / chọn / tạo mới ngay trong POS --%>
  <div id="custMgmtModal" style="display:none;position:fixed;inset:0;z-index:9650;background:rgba(11,22,40,.55);align-items:center;justify-content:center;padding:20px" onclick="if(event.target===this)closeCustMgmt()">
    <div style="background:#fff;border-radius:18px;max-width:560px;width:100%;max-height:82vh;display:flex;flex-direction:column;padding:22px;box-shadow:0 24px 70px rgba(0,0,0,.35)">
      <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:14px">
        <h3 style="margin:0;font-size:17px;font-weight:800;color:#0f172a">👥 Khách hàng</h3>
        <button onclick="closeCustMgmt()" style="background:#f1f5f9;border:none;border-radius:9px;width:32px;height:32px;cursor:pointer;font-size:15px;color:#475569">✕</button>
      </div>
      <div style="display:flex;gap:10px;margin-bottom:12px">
        <input type="text" id="cmSearch" placeholder="Tìm theo tên hoặc SĐT…" oninput="custMgmtSearch()"
               style="flex:1;border:1.5px solid #e2e8f0;border-radius:11px;padding:11px 13px;font-size:14px;font-family:inherit;box-sizing:border-box">
        <button onclick="closeCustMgmt();openQuickCreate()" style="flex-shrink:0;background:linear-gradient(135deg,#0d9488,#0f766e);color:#fff;border:none;border-radius:11px;padding:0 16px;font-weight:800;font-size:13.5px;cursor:pointer;font-family:inherit">＋ Thêm mới</button>
      </div>
      <div id="cmList" style="overflow-y:auto;flex:1;min-height:120px"></div>
    </div>
  </div>

  <%-- Modal: XEM CHI TIẾT khách hàng trong POS --%>
  <div id="custDetailModal" style="display:none;position:fixed;inset:0;z-index:9660;background:rgba(11,22,40,.6);align-items:center;justify-content:center;padding:20px" onclick="if(event.target===this)closeCustDetail()">
    <div style="background:#fff;border-radius:18px;max-width:600px;width:100%;max-height:88vh;display:flex;flex-direction:column;box-shadow:0 24px 70px rgba(0,0,0,.4)">
      <div style="display:flex;align-items:center;justify-content:space-between;padding:16px 20px;border-bottom:1px solid #eef2f7">
        <h3 style="margin:0;font-size:15px;font-weight:800;color:#0f172a">👤 Hồ sơ khách hàng</h3>
        <button onclick="closeCustDetail()" style="background:#f1f5f9;border:none;border-radius:9px;width:32px;height:32px;cursor:pointer;font-size:15px;color:#475569">✕</button>
      </div>
      <div id="cdBody" style="padding:20px;overflow-y:auto;flex:1"></div>
      <div style="padding:14px 20px;border-top:1px solid #eef2f7;display:flex;gap:10px">
        <button onclick="closeCustDetail()" style="flex:1;background:#f1f5f9;color:#475569;border:none;border-radius:11px;padding:12px;font-weight:750;cursor:pointer;font-family:inherit">Đóng</button>
        <button onclick="cdPickAndClose()" style="flex:2;background:linear-gradient(135deg,#0d9488,#0f766e);color:#fff;border:none;border-radius:11px;padding:12px;font-weight:800;cursor:pointer;font-family:inherit">✓ Chọn khách này vào hóa đơn</button>
      </div>
    </div>
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
           data-generic="<c:out value='${m.genericName}' />"
           data-contra="<c:out value='${m.contraindications}' />"
           data-warning="<c:out value='${m.dosageWarning}' />"
           data-storage="<c:out value='${m.storageConditions}' />"
           onclick="addToCart(this)">
        <%-- Top row: stock badge left, Rx/OTC right --%>
        <div class="mc-top">
          <span class="${stkCls} mc-stock">${stkLbl}</span>
          <c:choose>
            <c:when test="${m.prescriptionRequired}"><span class="mc-badge mb-rx">Rx</span></c:when>
            <c:otherwise><span class="mc-badge mb-otc">OTC</span></c:otherwise>
          </c:choose>
        </div>
        <%-- Center: medicine type icon --%>
        <c:choose>
          <c:when test="${fn:contains(m.unit,'Siro') or fn:contains(m.unit,'siro') or fn:contains(m.unit,'Chai') or fn:contains(m.unit,'chai') or fn:contains(m.unit,'ml') or fn:contains(m.unit,'Dung') or fn:contains(m.unit,'dịch')}"><span class="mc-icon">🍶</span></c:when>
          <c:when test="${fn:contains(m.unit,'Ống') or fn:contains(m.unit,'ống') or fn:contains(m.unit,'Amp')}"><span class="mc-icon">💉</span></c:when>
          <c:when test="${fn:contains(m.unit,'Gói') or fn:contains(m.unit,'gói') or fn:contains(m.unit,'Túi')}"><span class="mc-icon">📦</span></c:when>
          <c:when test="${fn:contains(m.unit,'Tuýp') or fn:contains(m.unit,'tuýp') or fn:contains(m.unit,'Kem') or fn:contains(m.unit,'kem') or fn:contains(m.unit,'Gel') or fn:contains(m.unit,'gel')}"><span class="mc-icon">🧴</span></c:when>
          <c:otherwise><span class="mc-icon">💊</span></c:otherwise>
        </c:choose>
        <%-- Name & unit --%>
        <div class="mc-name"><c:out value="${m.medicineName}" /></div>
        <div class="mc-unit"><c:out value="${m.unit}" /></div>
        <%-- Price bottom --%>
        <div class="mc-price-row">
          <span class="mc-price"><fmt:formatNumber value="${m.sellingPrice}" pattern="#,###"/>đ</span>
        </div>
        <%-- Info button — bottom right corner --%>
        <button class="mc-info-btn" onclick="event.stopPropagation();showMedInfo(${m.medicineId})" title="Xem thông tin thuốc">
          <svg width="11" height="11" viewBox="0 0 11 11" fill="none" xmlns="http://www.w3.org/2000/svg">
            <circle cx="5.5" cy="5.5" r="5" stroke="currentColor" stroke-width="1.2"/>
            <rect x="4.9" y="4.7" width="1.2" height="3.4" rx="0.4" fill="currentColor"/>
            <circle cx="5.5" cy="2.9" r="0.65" fill="currentColor"/>
          </svg>
        </button>
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
      <input type="text" id="custPhone" placeholder="Gõ SĐT (tự tìm khi đủ 10 số)…" oninput="onCustInput()" autocomplete="off" inputmode="numeric">
      <button class="cust-btn" onclick="searchCustomer()" title="Tìm khách theo SĐT">🔍</button>
      <button class="cust-btn cust-btn-add" onclick="openQuickCreate()" title="Thêm khách hàng mới">＋</button>
    </div>
    <%-- Không tìm thấy → nút tạo nhanh 1 chạm --%>
    <button id="custCreateRow" style="display:none;width:100%;margin-top:7px;padding:9px 12px;background:linear-gradient(135deg,#0d9488,#0f766e);border:none;border-radius:9px;color:#fff;font-size:12.5px;font-weight:800;cursor:pointer;font-family:inherit;text-align:left"
            onclick="openQuickCreate()">
      ＋ Tạo mới khách hàng: <span id="custCreatePhone"></span>
    </button>
    <div class="cust-found-row" id="custFound">
      <span>👤</span>
      <span class="cust-found-name" id="custFoundName"></span>
      <span style="font-size:12px;color:var(--muted)" id="custFoundPhone"></span>
      <span id="custTierBadge" style="display:none;font-size:10.5px;font-weight:800;background:#f0fdfa;color:#0f766e;border:1px solid #99f6e4;padding:1px 8px;border-radius:10px"></span>
      <button class="cust-rm" onclick="removeCustomer()">✕</button>
    </div>
    <%-- CẢNH BÁO ĐỎ dị ứng thuốc — hiện khi khách có tiền sử dị ứng --%>
    <div id="custAllergyRow" style="display:none;margin-top:7px;background:#fef2f2;border:1.5px solid #fca5a5;border-radius:9px;padding:8px 11px;font-size:12px;color:#991b1b;line-height:1.45">
      🚨 <b>DỊ ỨNG:</b> <span id="custAllergyText"></span>
    </div>
  </div>

  <!-- Items -->
  <div class="inv-items" id="invItems">
    <div class="inv-empty"><div class="ei">🛒</div><p>Giỏ hàng trống<br><small>Bấm vào thẻ thuốc để thêm</small></p></div>
  </div>

  <!-- Bottom forms -->
  <div class="inv-forms">
    <!-- Payment methods — 3 big cards -->
    <div>
      <div class="f-label" style="margin-bottom:7px">Phương thức thanh toán</div>
      <div class="pay-methods">
        <button class="pay-method-card active" data-method="CASH" onclick="selectPay(this)">
          <span class="pmc-icon">💵</span><span class="pmc-label">Tiền mặt</span>
        </button>
        <button class="pay-method-card" data-method="QR_CODE" onclick="selectPay(this)">
          <span class="pmc-icon">📱</span><span class="pmc-label">QR VietQR</span>
        </button>
        <button class="pay-method-card" data-method="CARD" onclick="selectPay(this)">
          <span class="pmc-icon">💳</span><span class="pmc-label">Quẹt thẻ</span>
        </button>
      </div>
      <!-- QR detail panel -->
      <div class="pay-detail-section" id="qrSection">
        <div class="pdi-row">
          <span class="pdi-icon">📱</span>
          <div class="pdi-body">
            <div class="pdi-title">Thanh toán QR VietQR</div>
            <div class="pdi-sub">Nhấn <b>Thanh toán</b> để tạo mã QR — khách quét và chuyển khoản tự động</div>
          </div>
          <span class="pdi-amount" id="qrAmount">0đ</span>
        </div>
      </div>
      <!-- Card detail panel -->
      <div class="pay-detail-section" id="cardSection">
        <div class="pdi-row">
          <span class="pdi-icon">💳</span>
          <div class="pdi-body">
            <div class="pdi-title">Thanh toán quẹt thẻ</div>
            <div class="pdi-sub">Cà thẻ trên máy POS vật lý, nhấn <b>Thanh toán</b> sau khi hoàn tất</div>
          </div>
          <span class="pdi-amount" id="cardAmount">0đ</span>
        </div>
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

<!-- STATION SELECTOR MODAL -->
<div class="station-modal" id="stationModal">
  <div class="stm-backdrop" onclick="closeStationModal()"></div>
  <div class="stm-panel">
    <div class="stm-title">🖥️ Chọn quầy POS</div>
    <div class="stm-sub">Mỗi máy tính = 1 quầy. Chọn quầy tương ứng với máy này.</div>
    <div class="station-grid" id="stationGrid">
      <!-- rendered by JS -->
    </div>
    <button class="btn-confirm-station" onclick="confirmStation()">✓ Xác nhận quầy</button>
  </div>
</div>

<!-- FACE CHECK-IN MODAL -->
<div class="face-modal" id="faceModal">
  <div class="fm-backdrop" onclick="closeFaceModal()"></div>
  <div class="fm-panel">
    <button class="fm-close" onclick="closeFaceModal()">✕</button>
    <div class="fm-title">📷 Điểm danh qua khuôn mặt</div>
    <div class="fm-sub">Nhìn thẳng vào camera — hệ thống tự nhận dạng</div>
    <div id="fmLoading" class="fm-loader"><div class="fm-spinner"></div>Đang tải mô hình nhận dạng…</div>
    <div id="fmCameraWrap" style="display:none">
      <div class="face-video-wrap">
        <video id="faceVideo" autoplay muted playsinline></video>
        <canvas id="faceCanvas"></canvas>
        <div class="face-overlay">
          <div class="face-ring" id="faceRing"></div>
        </div>
      </div>
      <div class="fm-enrolled-count" id="fmEnrolledCount"></div>
      <div class="fm-no-face" id="fmNoFace">⚠ Không phát hiện khuôn mặt — hãy nhìn thẳng vào camera</div>
      <div class="fm-status" id="fmStatus">Đang quét…</div>
      <div class="fm-actions">
        <button class="fm-btn-cancel" onclick="closeFaceModal()">Hủy</button>
        <button class="fm-btn-checkin" id="fmCheckinBtn" onclick="confirmFaceCheckin()">✓ Xác nhận điểm danh</button>
      </div>
    </div>
  </div>
</div>

<!-- MEDICINE INFO DRAWER -->
<div class="med-drawer-bd" id="medDrawerBd" onclick="closeInfoDrawer()"></div>
<div class="med-drawer" id="medDrawer">
  <div class="mdd-head">
    <button class="mdd-close" onclick="closeInfoDrawer()">✕</button>
    <span class="mdd-rx" id="mddRx"></span>
    <div class="mdd-name" id="mddName"></div>
    <div class="mdd-code" id="mddCode"></div>
  </div>
  <div class="mdd-body" id="mddBody">
    <!-- populated by JS -->
  </div>
  <div class="mdd-foot">
    <button class="mdd-close-btn" onclick="closeInfoDrawer()">✕ Đóng</button>
    <button class="mdd-add-btn" id="mddAddBtn" onclick="addFromDrawer()">＋ Thêm vào giỏ hàng</button>
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

<!-- QR PAYMENT MODAL -->
<div class="qr-modal" id="qrPayModal">
  <div class="qr-backdrop"></div>
  <div class="qrm-panel">
    <div class="qrm-header">
      <div class="qrm-logo-icon">📱</div>
      <div class="qrm-logo-info">
        <div class="qrm-logo-txt">VietQR Payment</div>
        <div class="qrm-logo-sub">Quét bằng ứng dụng ngân hàng bất kỳ</div>
      </div>
    </div>
    <div class="qrm-amount" id="qrmAmount">0đ</div>
    <div class="qrm-amount-label">Tổng tiền thanh toán</div>

    <!-- QR code box (ẩn khi đã thanh toán) -->
    <div class="qrm-qr-box" id="qrmQrBox">
      <div id="qrmQrCode"></div>
      <div class="qrm-qr-center">💊</div>
    </div>

    <!-- Success box (hiện khi đã thanh toán) -->
    <div class="qrm-success-box" id="qrmSuccessBox">
      <div class="qrm-success-icon">✅</div>
      <div class="qrm-success-txt">Thanh toán thành công!</div>
    </div>

    <div class="qrm-banks">
      <span class="qrm-bank">VCB</span><span class="qrm-bank">TCB</span>
      <span class="qrm-bank">VietinBank</span><span class="qrm-bank">MBBank</span>
      <span class="qrm-bank">BIDV</span><span class="qrm-bank">TPBank</span>
      <span class="qrm-bank">Momo</span><span class="qrm-bank">ZaloPay</span>
    </div>

    <div class="qrm-divider"></div>

    <div class="qrm-status-row">
      <span class="qrm-dot" id="qrmDot"></span>
      <span class="qrm-status-txt" id="qrmStatusTxt">Đang chờ thanh toán...</span>
    </div>
    <div class="qrm-timer" id="qrmTimerRow">Hết hạn sau: <b id="qrmCountdown">05:00</b></div>
    <a id="qrmCheckoutLink" href="#" target="_blank" class="qrm-checkout-link">
      🔗 Mở trang thanh toán trên điện thoại
    </a>
    <button class="qrm-cancel-btn" id="qrmCancelBtn" onclick="cancelQrPay()">❌ Hủy thanh toán</button>
  </div>
</div>

<!-- END SHIFT REPORT MODAL -->
<div class="esr-bd" id="esrModal">
  <div class="esr-box">
    <div class="esr-head">
      <div>
        <div class="esr-head-title">⏻ Báo cáo &amp; Đóng ca</div>
        <div class="esr-head-meta" id="esrHeadMeta">Đang tải dữ liệu...</div>
      </div>
      <button class="esr-hclose" onclick="closeEndShiftModal()">✕</button>
    </div>
    <div class="esr-body">
      <!-- LEFT: System Summary (read-only) -->
      <div class="esr-left">
        <div class="esr-sec-title">📊 Báo cáo tổng thu — Hệ thống</div>
        <div class="esr-grand">
          <div>
            <div class="esr-grand-lbl">TỔNG DOANH THU TRONG CA</div>
            <div class="esr-grand-val" id="esrGrandTotal">—</div>
          </div>
          <div class="esr-inv-chip" id="esrInvChip">0 hóa đơn</div>
        </div>
        <div class="esr-prows">
          <div class="esr-prow">
            <span class="esr-prow-icon">💵</span>
            <span class="esr-prow-lbl">Thu tiền mặt</span>
            <span class="esr-prow-val" id="esrCashTotal">—</span>
          </div>
          <div class="esr-prow">
            <span class="esr-prow-icon">📱</span>
            <span class="esr-prow-lbl">Thu QR / Chuyển khoản</span>
            <span class="esr-prow-val" id="esrQrTotal">—</span>
          </div>
          <div class="esr-prow">
            <span class="esr-prow-icon">💳</span>
            <span class="esr-prow-lbl">Thu quẹt thẻ</span>
            <span class="esr-prow-val" id="esrCardTotal">—</span>
          </div>
        </div>
        <div class="esr-note">💡 QR và Thẻ không ảnh hưởng đến két tiền mặt tại quầy. Chỉ tính vào doanh số nhân viên.</div>
      </div>
      <!-- RIGHT: Cash Reconciliation -->
      <div class="esr-right">
        <div class="esr-sec-title">🪙 Đối soát két tiền tại quầy</div>
        <div class="esr-crows">
          <div class="esr-crow">
            <span class="esr-crow-lbl">💵 Tiền đầu ca (mở két)</span>
            <span class="esr-crow-val" id="esrOpening">—</span>
          </div>
          <div class="esr-crow">
            <span class="esr-crow-lbl">➕ Tiền mặt thu trong ca</span>
            <span class="esr-crow-val" id="esrCashSold">—</span>
          </div>
        </div>
        <div class="esr-expected-box">
          <span class="esr-exp-lbl">🟢 Két phải có</span>
          <span class="esr-exp-val" id="esrExpected">—</span>
        </div>
        <div class="esr-inp-wrap">
          <div class="esr-inp-lbl">🔢 Nhập số tiền bạn đếm được trong két:</div>
          <input type="number" class="esr-inp" id="esrActualInput"
                 placeholder="0" min="0" oninput="calcCashVariance()"
                 autocomplete="off">
        </div>
        <div class="esr-vbox empty" id="esrVbox">
          <span class="esr-vlbl empty" id="esrVlbl">Nhập số tiền để kiểm tra</span>
          <span class="esr-vval empty" id="esrVval">—</span>
        </div>
      </div>
    </div>
    <div class="esr-foot">
      <button class="esr-cancel" onclick="closeEndShiftModal()">✕ Hủy</button>
      <button class="esr-confirm" id="esrConfirmBtn" onclick="confirmEndShift()">⏻ Xác nhận &amp; Đóng ca</button>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/qrcodejs@1.0.0/qrcode.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/@vladmandic/face-api@1.7.13/dist/face-api.js"></script>
<script>
const ctx = '<%= ctx %>';
const getUid = () => {
  const urlParams = new URLSearchParams(window.location.search);
  return urlParams.get('uid') || '';
};
const screenState = '${screenState}';
const sellerName = '<%= fullName %>';
let cart = [];
let selectedCustomer = null;
let selectedPayment = 'CASH';
let allMedicines = [];

// ── Multi-POS state ──
let currentStation = <%= posStation %>;  // 0 = belum pilih
let nfcBridge = null;                    // EventSource cầu nối NFC (khai báo sớm, tránh TDZ)
let currentStaffId = null;
let currentStaffName = '<%= fullName %>';
let currentInvoice = null; // {id, code, total, discount, cashReceived, change}

// ── Date display ──
(function() {
  const n = new Date();
  const days = ['CN','T2','T3','T4','T5','T6','T7'];
  document.getElementById('topDate').textContent =
    days[n.getDay()] + ' ' + n.getDate().toString().padStart(2,'0') + '/' +
    (n.getMonth()+1).toString().padStart(2,'0') + '/' + n.getFullYear();
})();

// ── Nối kênh nghe thẻ NFC nếu quầy đã được chọn từ trước (session giữ lại) ──
if (typeof initNfcBridge === 'function') initNfcBridge();

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
    generic:  card.dataset.generic  || '',
    contra:   card.dataset.contra   || '',
    warning:  card.dataset.warning  || '',
    storage:  card.dataset.storage  || '',
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

// ── Card qty helpers removed — thẻ thuốc bây giờ chỉ click = +1 vào giỏ ──

// ── Cart ──
function addToCart(card) {
  if (card.classList.contains('out-of-stock')) return;
  const id    = parseInt(card.dataset.id);
  const stock = parseInt(card.dataset.stock) || 0;

  const existing   = cart.find(i => i.id === id);
  const inCartQty  = existing ? existing.qty : 0;

  if (stock > 0 && inCartQty >= stock) {
    showToast('⚠️ Đã đạt tối đa tồn kho (' + stock + ' ' + (card.dataset.unit||'') + ')', 'err');
    return;
  }

  if (existing) {
    existing.qty += 1;
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
  const newQty = item.qty + delta;
  if (newQty <= 0) { cart = cart.filter(i => i.id !== id); renderCart(); return; }
  if (item.stock > 0 && newQty > item.stock) {
    showToast('⚠️ Chỉ còn ' + item.stock + ' ' + item.unit + ' trong kho', 'err'); return;
  }
  item.qty = newQty;
  renderCart();
}

function setCartQty(id, inp) {
  const item = cart.find(i => i.id === id);
  if (!item) return;
  let v = parseInt(inp.value) || 1;
  if (v < 1) v = 1;
  if (item.stock > 0 && v > item.stock) {
    showToast('⚠️ Chỉ còn ' + item.stock + ' ' + item.unit + ' trong kho', 'err');
    v = item.stock;
  }
  item.qty = v;
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
      // Tồn kho còn lại (để dược sĩ biết còn bao nhiêu mà bán) — đỏ nếu vượt tồn
      const remain = item.stock - item.qty;
      const stockColor = item.qty >= item.stock ? '#DC2626' : (remain <= 5 ? '#D97706' : '#059669');
      meta.push('<span style="color:' + stockColor + ';font-weight:800">📦 Kho còn: ' + item.stock + ' ' + escHtml(item.unit)
                + (item.qty > 0 ? ' (sau bán: ' + (remain < 0 ? 0 : remain) + ')' : '') + '</span>');
      const metaHtml = meta.length ? '<div class="inv-i-meta">' + meta.join(' · ') + '</div>' : '';
      const rxBadge = item.rx ? '<span class="mc-badge mb-rx" style="font-size:9px;padding:1px 4px;margin-right:6px;border-radius:3px;">Rx</span>' : '<span class="mc-badge mb-otc" style="font-size:9px;padding:1px 4px;margin-right:6px;border-radius:3px;">OTC</span>';
      return '<div class="inv-item">'
        + '<div class="inv-i-info">'
          + '<div class="inv-i-name" style="display:flex;align-items:center;">' + rxBadge + escHtml(item.name) + '</div>'
          + '<div class="inv-i-price" style="margin-top:3px;color:#475569;">M\u00E3: <span style="font-weight:750;color:#0F172A;">' + escHtml(item.code) + '</span> \u00B7 ' + fmtMoney(item.price) + ' / ' + escHtml(item.unit) + '</div>'
          + metaHtml
        + '</div>'
        + '<div class="qty-ctrl">'
          + '<button class="qty-btn minus" onclick="changeQty('+item.id+',-1)">−</button>'
          + '<input type="number" class="qty-val" value="'+item.qty+'" min="1" max="'+item.stock+'"'
          + ' onchange="setCartQty('+item.id+',this)" onfocus="this.select()">'
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
  syncPayPanelAmounts();
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
  document.querySelectorAll('.pay-method-card').forEach(b => b.classList.remove('active'));
  btn.classList.add('active');
  selectedPayment = btn.dataset.method;

  const cashSec   = document.getElementById('cashSection');
  const qrSec     = document.getElementById('qrSection');
  const cardSec   = document.getElementById('cardSection');
  const needRow   = document.getElementById('cashNeedRow');
  const changeRow = document.getElementById('cashChangeRow');

  cashSec.classList.remove('show');
  qrSec.classList.remove('show');
  cardSec.classList.remove('show');
  if (changeRow) changeRow.style.display = 'none';

  if (selectedPayment === 'CASH') {
    cashSec.classList.add('show');
    if (needRow) needRow.style.display = 'none';
  } else if (selectedPayment === 'QR_CODE') {
    qrSec.classList.add('show');
    if (needRow) needRow.style.display = 'flex';
    syncPayPanelAmounts();
  } else {
    cardSec.classList.add('show');
    if (needRow) needRow.style.display = 'flex';
    syncPayPanelAmounts();
  }
  updateCheckoutBtnState();
}

function syncPayPanelAmounts() {
  const tot = calcTotal();
  const fmt = fmtMoney(tot);
  const qrEl = document.getElementById('qrAmount');
  const cdEl = document.getElementById('cardAmount');
  if (qrEl) qrEl.textContent = fmt;
  if (cdEl) cdEl.textContent = fmt;
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
  if (cart.length === 0) {
    btn.disabled = true;
    btn.textContent = '\uD83D\uDED2 THANH TO\u00C1N';
    return;
  }
  if (selectedPayment === 'CASH') {
    const total = calcTotal();
    const cash  = parseFloat(document.getElementById('cashInput').value) || 0;
    if (cash <= 0) {
      btn.disabled = true;
      btn.textContent = '\u23F3 Nh\u1EADp ti\u1EC1n kh\u00E1ch \u0111\u01B0a\u2026';
    } else if (cash < total) {
      btn.disabled = true;
      btn.textContent = '\u26A0\uFE0F Ch\u01B0a \u0111\u1EE7 ti\u1EC1n';
    } else {
      btn.disabled = false;
      btn.textContent = '\u2713  F9 \u2014 THANH TO\u00C1N';
    }
  } else if (selectedPayment === 'QR_CODE') {
    btn.disabled = false;
    btn.textContent = '\uD83D\uDCF1 T\u1EA1o m\u00E3 QR thanh to\u00E1n';
  } else {
    btn.disabled = false;
    btn.textContent = '\uD83D\uDCB3 X\u00E1c nh\u1EADn thanh to\u00E1n';
  }
}

// ── Customer: auto-search khi đủ 10 số + tạo nhanh + NFC ──
let custTimer;
function onCustInput() {
  clearTimeout(custTimer);
  const digits = document.getElementById('custPhone').value.replace(/\D/g, '');
  document.getElementById('custCreateRow').style.display = 'none';
  if (digits.length === 10) { searchCustomer(); return; }  // đủ 10 số → tìm NGAY, không cần Enter
  custTimer = setTimeout(searchCustomer, 600);
}

/** Hiển thị khách đã chọn: tên + SĐT + hạng/điểm + CẢNH BÁO ĐỎ dị ứng. */
function applyCustomer(data) {
  selectedCustomer = { id: data.id, name: data.name, phone: data.phone };
  document.getElementById('custFoundName').textContent  = data.name;
  document.getElementById('custFoundPhone').textContent = data.phone;
  const badge = document.getElementById('custTierBadge');
  if (data.tier) {
    badge.textContent = data.tier + ' · ' + (data.points || 0) + 'đ';
    badge.style.display = 'inline-block';
  } else badge.style.display = 'none';
  document.getElementById('custFound').style.display = 'flex';
  document.getElementById('custCreateRow').style.display = 'none';
  // Cảnh báo dị ứng — chốt an toàn ngành dược
  const aRow = document.getElementById('custAllergyRow');
  if (data.allergy && data.allergy.trim()) {
    document.getElementById('custAllergyText').textContent = data.allergy;
    aRow.style.display = 'block';
  } else aRow.style.display = 'none';
}

function searchCustomer() {
  const phone = document.getElementById('custPhone').value.trim();
  if (phone.length < 9) return;
  fetch(ctx + '/pos?action=find-customer&phone=' + encodeURIComponent(phone))
    .then(r => r.json()).then(data => {
      if (data.found) {
        applyCustomer(data);
        showToast('✓ ' + data.name + (data.points ? ' · ' + data.points + ' điểm' : ''), 'ok');
      } else {
        selectedCustomer = null;
        document.getElementById('custFound').style.display = 'none';
        document.getElementById('custAllergyRow').style.display = 'none';
        // Chưa có tài khoản → hiện nút tạo nhanh 1 chạm
        if (/^0\d{9}$/.test(phone)) {
          document.getElementById('custCreatePhone').textContent = phone;
          document.getElementById('custCreateRow').style.display = 'block';
        } else {
          showToast('⚠️ Không tìm thấy khách hàng', 'err');
        }
      }
    }).catch(() => { showToast('Lỗi kết nối khi tìm khách hàng', 'err'); });
}

function removeCustomer() {
  selectedCustomer = null;
  document.getElementById('custPhone').value = '';
  document.getElementById('custFound').style.display = 'none';
  document.getElementById('custAllergyRow').style.display = 'none';
  document.getElementById('custCreateRow').style.display = 'none';
}

// ── Panel QUẢN LÝ KHÁCH HÀNG trong POS (tìm / chọn / tạo mới) ──
let _cmTimer = null;
function openCustMgmt() {
  document.getElementById('cmSearch').value = '';
  document.getElementById('custMgmtModal').style.display = 'flex';
  custMgmtSearch();
  setTimeout(() => document.getElementById('cmSearch').focus(), 100);
}
function closeCustMgmt() { document.getElementById('custMgmtModal').style.display = 'none'; }

function custMgmtSearch() {
  clearTimeout(_cmTimer);
  _cmTimer = setTimeout(async () => {
    const q = document.getElementById('cmSearch').value.trim();
    const box = document.getElementById('cmList');
    box.innerHTML = '<div style="text-align:center;color:#94a3b8;padding:24px;font-size:13px">⏳ Đang tải…</div>';
    try {
      const res = await fetch(ctx + '/pos?action=search-customers&q=' + encodeURIComponent(q));
      const list = await res.json();
      if (!list.length) {
        box.innerHTML = '<div style="text-align:center;color:#94a3b8;padding:24px;font-size:13px">Không có khách hàng nào.'
          + (q ? ' Thử bấm <b>＋ Thêm mới</b>.' : '') + '</div>';
        return;
      }
      box.innerHTML = list.map(c =>
        '<div style="display:flex;align-items:center;gap:10px;padding:10px 12px;border:1px solid #eef2f7;border-radius:11px;margin-bottom:7px;transition:.12s" '
        + 'onmouseover="this.style.background=\'#f8fafc\'" onmouseout="this.style.background=\'\'">'
        + '<span style="font-size:18px">' + (c.hasNfc ? '📶' : '👤') + '</span>'
        + '<div onclick="posCustomerDetail(' + c.id + ')" style="flex:1;min-width:0;cursor:pointer">'
        + '<div style="font-weight:750;font-size:13.5px;color:#0f172a;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">' + escHtml(c.name) + '</div>'
        + '<div style="font-size:12px;color:#64748b">' + escHtml(c.phone || '—') + '</div>'
        + '</div>'
        + '<button onclick="posCustomerDetail(' + c.id + ')" style="flex-shrink:0;background:#eff6ff;color:#1558a8;border:none;border-radius:8px;padding:6px 10px;font-size:12px;font-weight:750;cursor:pointer;font-family:inherit">👁 Xem</button>'
        + '<button onclick="pickCustomer(\'' + c.phone + '\')" style="flex-shrink:0;background:linear-gradient(135deg,#0d9488,#0f766e);color:#fff;border:none;border-radius:8px;padding:6px 11px;font-size:12px;font-weight:750;cursor:pointer;font-family:inherit">Chọn →</button>'
        + '</div>'
      ).join('');
    } catch (e) {
      box.innerHTML = '<div style="text-align:center;color:#dc2626;padding:24px;font-size:13px">❌ Lỗi tải danh sách</div>';
    }
  }, 250);
}

/** Chọn khách từ panel → tái dùng find-customer để lấy đủ điểm/dị ứng rồi áp vào hóa đơn. */
function pickCustomer(phone) {
  if (!phone) return;
  document.getElementById('custPhone').value = phone;
  closeCustMgmt();
  searchCustomer();
}

// ── Trang XEM CHI TIẾT khách hàng trong POS ──
async function posCustomerDetail(id) {
  const modal = document.getElementById('custDetailModal');
  const body  = document.getElementById('cdBody');
  modal.style.display = 'flex';
  body.innerHTML = '<div style="text-align:center;color:#94a3b8;padding:40px;font-size:13px">⏳ Đang tải hồ sơ…</div>';
  try {
    const res = await fetch(ctx + '/pos?action=pos-customer-detail&id=' + id);
    const d = await res.json();
    if (!d.ok) { body.innerHTML = '<div style="text-align:center;color:#dc2626;padding:40px">Không tìm thấy khách hàng.</div>'; return; }
    window._cdPhone = d.phone;

    const gender = d.gender === 'M' ? 'Nam' : d.gender === 'F' ? 'Nữ' : '—';
    const money  = n => new Intl.NumberFormat('vi-VN').format(Math.round(n || 0)) + 'đ';
    const stBadge = s => s === 'COMPLETED' ? '<span style="color:#059669;font-weight:750">✅ Hoàn tất</span>'
                        : s === 'CANCELLED' ? '<span style="color:#dc2626;font-weight:750">❌ Đã hủy</span>'
                        : '<span style="color:#d97706;font-weight:750">⏳ Xử lý</span>';

    let invRows = d.invoices.length
      ? d.invoices.map(iv =>
          '<tr style="border-bottom:1px solid #f1f5f9">'
          + '<td style="padding:8px 6px;font-family:monospace;color:#1558a8;font-weight:750">' + escHtml(iv.code) + '</td>'
          + '<td style="padding:8px 6px;color:#64748b;font-size:12px">' + escHtml(iv.time) + '</td>'
          + '<td style="padding:8px 6px;text-align:right;font-weight:800">' + money(iv.amount) + '</td>'
          + '<td style="padding:8px 6px;text-align:right">' + stBadge(iv.status) + '</td>'
          + '</tr>').join('')
      : '<tr><td colspan="4" style="text-align:center;color:#94a3b8;padding:22px">🛒 Chưa có hóa đơn nào.</td></tr>';

    const medBox = (label, val, warn) => val
      ? '<div style="margin-top:8px"><div style="font-size:10.5px;font-weight:750;text-transform:uppercase;color:#7a90b0;margin-bottom:3px">' + label + '</div>'
        + '<div style="padding:9px 11px;border-radius:9px;font-size:12.5px;font-weight:750;background:#fef2f2;border:1px solid #fca5a5;color:#991b1b">' + escHtml(val) + '</div></div>'
      : '';

    body.innerHTML =
      '<div style="display:flex;align-items:center;gap:14px;margin-bottom:16px">'
      + '<div style="width:58px;height:58px;border-radius:16px;background:linear-gradient(135deg,#3abde0,#1558a8);display:flex;align-items:center;justify-content:center;font-size:24px;font-weight:800;color:#fff;flex-shrink:0">' + escHtml((d.name||'?').charAt(0).toUpperCase()) + '</div>'
      + '<div style="flex:1;min-width:0">'
      + '<div style="font-size:19px;font-weight:800;color:#0f172a">' + escHtml(d.name) + '</div>'
      + '<div style="font-size:13px;color:#64748b">📱 ' + escHtml(d.phone || '—')
      + (d.tier ? ' · <span style="color:#d97706;font-weight:750">🏅 ' + escHtml(d.tier) + '</span>' : '')
      + (d.hasNfc ? ' · <span style="color:#0d9488;font-weight:750">📶 có thẻ NFC</span>' : '') + '</div>'
      + '</div></div>'
      // KPI
      + '<div style="display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin-bottom:16px">'
      + '<div style="background:#f5f3ff;border-radius:12px;padding:12px;text-align:center"><div style="font-size:20px;font-weight:800;color:#7c3aed">' + d.points + '</div><div style="font-size:10.5px;color:#7a90b0;font-weight:750;text-transform:uppercase">Điểm</div></div>'
      + '<div style="background:#eff6ff;border-radius:12px;padding:12px;text-align:center"><div style="font-size:20px;font-weight:800;color:#1558a8">' + d.invoiceCount + '</div><div style="font-size:10.5px;color:#7a90b0;font-weight:750;text-transform:uppercase">Hóa đơn</div></div>'
      + '<div style="background:#ecfdf5;border-radius:12px;padding:12px;text-align:center"><div style="font-size:16px;font-weight:800;color:#059669">' + money(d.totalSpent) + '</div><div style="font-size:10.5px;color:#7a90b0;font-weight:750;text-transform:uppercase">Đã chi</div></div>'
      + '</div>'
      // Info
      + '<div style="display:grid;grid-template-columns:1fr 1fr;gap:10px;font-size:13px;margin-bottom:6px">'
      + '<div><span style="color:#7a90b0;font-size:11px;font-weight:750;text-transform:uppercase">Giới tính</span><div style="font-weight:750">' + gender + '</div></div>'
      + '<div><span style="color:#7a90b0;font-size:11px;font-weight:750;text-transform:uppercase">Ngày sinh</span><div style="font-weight:750">' + (d.dob || '—') + '</div></div>'
      + '<div><span style="color:#7a90b0;font-size:11px;font-weight:750;text-transform:uppercase">Email</span><div style="font-weight:750;word-break:break-all">' + (escHtml(d.email) || '—') + '</div></div>'
      + '<div><span style="color:#7a90b0;font-size:11px;font-weight:750;text-transform:uppercase">Địa chỉ</span><div style="font-weight:750">' + (escHtml(d.address) || '—') + '</div></div>'
      + '</div>'
      + medBox('⚠️ Dị ứng', d.allergy, true)
      + medBox('⚠️ Bệnh mạn tính', d.chronic, true)
      // History
      + '<div style="margin-top:16px"><div style="font-size:13px;font-weight:800;color:#0f172a;margin-bottom:6px">📋 Lịch sử mua gần đây</div>'
      + '<table style="width:100%;border-collapse:collapse;font-size:12.5px">' + invRows + '</table></div>';
  } catch (e) {
    body.innerHTML = '<div style="text-align:center;color:#dc2626;padding:40px">❌ Lỗi tải hồ sơ</div>';
  }
}
function closeCustDetail() { document.getElementById('custDetailModal').style.display = 'none'; }
function cdPickAndClose() {
  if (window._cdPhone) { document.getElementById('custPhone').value = window._cdPhone; closeCustDetail(); closeCustMgmt(); searchCustomer(); }
}

// ── Tạo nhanh khách hàng (form 2 trường, <5 giây) ──
let _qcLinkNfcUid = null;   // nếu set: sau khi tạo xong tự liên kết thẻ NFC này
function openQuickCreate(nfcUid) {
  _qcLinkNfcUid = nfcUid || null;
  const phone = document.getElementById('custPhone').value.replace(/\D/g, '');
  document.getElementById('qcPhone').value = /^0\d{9}$/.test(phone) ? phone : '';
  document.getElementById('qcName').value = '';
  document.getElementById('qcErr').style.display = 'none';
  document.querySelectorAll('input[name=qcGender]').forEach(r => r.checked = false);
  document.getElementById('quickCreateModal').style.display = 'flex';
  setTimeout(() => document.getElementById(
      document.getElementById('qcPhone').value ? 'qcName' : 'qcPhone').focus(), 100);
}
function closeQuickCreate() { document.getElementById('quickCreateModal').style.display = 'none'; }

async function submitQuickCreate() {
  const phone = document.getElementById('qcPhone').value.replace(/\D/g, '');
  const name  = document.getElementById('qcName').value.trim();
  const gEl   = document.querySelector('input[name=qcGender]:checked');
  const err   = document.getElementById('qcErr');
  if (!/^0\d{9}$/.test(phone)) { err.textContent = 'SĐT phải đủ 10 số, bắt đầu bằng 0.'; err.style.display = 'block'; return; }
  if (name.length < 2) { err.textContent = 'Vui lòng nhập tên khách.'; err.style.display = 'block'; return; }
  err.style.display = 'none';
  const btn = document.getElementById('qcSaveBtn');
  btn.disabled = true; btn.textContent = '⏳ Đang lưu…';
  try {
    const res = await fetch(ctx + '/pos', {
      method: 'POST',
      body: new URLSearchParams({ action: 'quick-create-customer', phone: phone, name: name, gender: gEl ? gEl.value : '' }),
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    });
    const d = await res.json();
    if (d.ok) {
      applyCustomer(d);
      document.getElementById('custPhone').value = phone;
      closeQuickCreate();
      showToast('✅ Đã tạo khách: ' + d.name, 'ok');
      // Nếu flow đến từ thẻ NFC trắng → liên kết luôn
      if (_qcLinkNfcUid) { await doLinkNfc(_qcLinkNfcUid, phone); _qcLinkNfcUid = null; }
    } else {
      const map = { phone_exists: 'SĐT này đã có tài khoản — bấm 🔍 để chọn.', invalid_phone: 'SĐT không hợp lệ.', invalid_name: 'Tên không hợp lệ.' };
      err.textContent = map[d.reason] || ('Lỗi: ' + d.reason);
      err.style.display = 'block';
    }
  } catch (e) { err.textContent = 'Lỗi kết nối: ' + e.message; err.style.display = 'block'; }
  btn.disabled = false; btn.textContent = '💾 Lưu & Chọn';
}

// ── NFC: chạm thẻ (đầu đọc = bàn phím) hoặc nhập UID tay ──
function openNfcModal() {
  document.getElementById('nfcUidInput').value = '';
  document.getElementById('nfcStep2').style.display = 'none';
  document.getElementById('nfcStatus').textContent = 'Chạm thẻ vào đầu đọc hoặc nhập mã thẻ…';
  document.getElementById('nfcModal').style.display = 'flex';
  setTimeout(() => document.getElementById('nfcUidInput').focus(), 100);
}
function closeNfcModal() { document.getElementById('nfcModal').style.display = 'none'; }

async function nfcLookup() {
  const uid = document.getElementById('nfcUidInput').value.trim();
  if (!uid) return;
  const st = document.getElementById('nfcStatus');
  st.textContent = '⏳ Đang tra thẻ…';
  try {
    const res = await fetch(ctx + '/pos?action=nfc-lookup&uid=' + encodeURIComponent(uid));
    const d = await res.json();
    if (d.found) {
      applyCustomer(d);
      closeNfcModal();
      showToast('✓ Thẻ của ' + d.name + (d.points ? ' · ' + d.points + ' điểm' : ''), 'ok');
    } else {
      // Thẻ trắng → bước 2: nhập SĐT để liên kết
      st.textContent = '🆕 Thẻ chưa định danh — nhập SĐT khách để liên kết:';
      document.getElementById('nfcStep2').style.display = 'block';
      setTimeout(() => document.getElementById('nfcPhoneInput').focus(), 80);
    }
  } catch (e) { st.textContent = '❌ Lỗi kết nối.'; }
}

async function doLinkNfc(uid, phone) {
  try {
    const res = await fetch(ctx + '/pos', {
      method: 'POST',
      body: new URLSearchParams({ action: 'link-nfc', uid: uid, phone: phone }),
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    });
    const d = await res.json();
    if (d.ok) {
      applyCustomer(d);
      closeNfcModal();
      showToast('🔗 Đã liên kết thẻ cho ' + d.name, 'ok');
      return true;
    }
    if (d.reason === 'phone_not_found') {
      // SĐT chưa có tài khoản → mở form tạo nhanh, tạo xong tự link lại
      closeNfcModal();
      document.getElementById('custPhone').value = phone;
      openQuickCreate(uid);
      return false;
    }
    showToast(d.reason === 'uid_taken' ? '⚠️ Thẻ đã gán cho: ' + (d.name || 'khách khác') : '❌ Lỗi: ' + d.reason, 'err');
  } catch (e) { showToast('❌ Lỗi kết nối', 'err'); }
  return false;
}

function nfcLinkSubmit() {
  const uid   = document.getElementById('nfcUidInput').value.trim();
  const phone = document.getElementById('nfcPhoneInput').value.replace(/\D/g, '');
  if (!/^0\d{9}$/.test(phone)) { showToast('⚠️ SĐT phải đủ 10 số', 'err'); return; }
  doLinkNfc(uid, phone);
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
  if (selectedPayment === 'QR_CODE') {
    openQrModal(total);
    return;
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
  if (currentStaffId)   fd.append('uid', currentStaffId);
  if (currentStation > 0) fd.append('posStation', currentStation);
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
        showToast('✅ Thanh toán thành công!'
          + (data.earnedPoints > 0 ? ' Khách +' + data.earnedPoints + ' điểm ⭐' : ''), 'ok');
        
        // Tự động xuất hiện/in hóa đơn ngay sau khi thanh toán thành công
        setTimeout(() => {
          printReceipt();
        }, 300);
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

// ── Medicine Info Drawer ──
let infoMedId = null;
function showMedInfo(medId) {
  const m = allMedicines.find(x => x.id === medId);
  if (!m) return;
  infoMedId = medId;
  const g = (id) => document.getElementById(id);
  const rx = m.rx;
  g('mddRx').textContent = rx ? '⚕ Kê đơn (Rx)' : '✓ Không kê đơn (OTC)';
  g('mddRx').style.cssText = rx
    ? 'background:#FEE2E2;color:#991B1B'
    : 'background:#D1FAE5;color:#065F46';
  g('mddName').textContent = m.name;
  g('mddCode').textContent = 'Mã: ' + m.code + ' · ' + m.unit;
  // Build body
  const esc = s => s.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
  let html = '';
  // Price + stock
  const stockHtml = m.stock <= 0
    ? '<span style="color:#DC2626;font-weight:800">Hết hàng</span>'
    : '<span style="color:#059669;font-weight:800">Còn ' + m.stock + ' ' + esc(m.unit) + '</span>';
  html += '<div class="mdd-price-bar"><span class="mdd-price-lbl">Đơn giá bán</span><span class="mdd-price-val">' + fmtMoney(m.price) + '</span></div>';
  // Quick info grid
  const qRows = [];
  if (m.batchNo) qRows.push({k:'Số lô', v:esc(m.batchNo)});
  if (m.expiry)  qRows.push({k:'Hạn dùng', v:fmtDate(m.expiry)});
  qRows.push({k:'Tồn kho', v:stockHtml});
  if (m.storage) qRows.push({k:'Bảo quản', v:esc(m.storage), full:true});
  html += '<div class="mdd-section"><div class="mdd-sec-title">Thông tin cơ bản</div>';
  html += '<div class="mdd-rows">';
  qRows.forEach(r => {
    html += '<div class="mdd-row' + (r.full ? ' full' : '') + '"><div class="dk">' + r.k + '</div><div class="dv">' + r.v + '</div></div>';
  });
  html += '</div></div>';
  // Hoạt chất (generic name = thành phần chính)
  if (m.generic) {
    html += '<div class="mdd-section"><div class="mdd-sec-title">Thành phần / Hoạt chất</div><div class="mdd-text">' + esc(m.generic) + '</div></div>';
  }
  // Liều dùng
  if (m.dosage) {
    html += '<div class="mdd-section"><div class="mdd-sec-title">Liều dùng</div><div class="mdd-text">' + esc(m.dosage) + '</div></div>';
  }
  // Cảnh báo liều
  if (m.warning) {
    html += '<div class="mdd-section mdd-warn"><div class="mdd-sec-title">⚠ Cảnh báo</div><div class="mdd-text">' + esc(m.warning) + '</div></div>';
  }
  // Chống chỉ định
  if (m.contra) {
    html += '<div class="mdd-section mdd-contra"><div class="mdd-sec-title">🚫 Chống chỉ định</div><div class="mdd-text">' + esc(m.contra) + '</div></div>';
  }
  if (!m.generic && !m.dosage && !m.warning && !m.contra) {
    html += '<div style="color:#94A3B8;font-size:13px;text-align:center;padding:20px 0">Chưa có thông tin chi tiết</div>';
  }
  g('mddBody').innerHTML = html;
  const addBtn = g('mddAddBtn');
  addBtn.disabled = m.stock <= 0;
  addBtn.textContent = m.stock <= 0 ? 'Hết hàng' : '＋ Thêm vào giỏ hàng';
  document.getElementById('medDrawer').classList.add('show');
  document.getElementById('medDrawerBd').classList.add('show');
}
function closeInfoDrawer() {
  document.getElementById('medDrawer').classList.remove('show');
  document.getElementById('medDrawerBd').classList.remove('show');
  infoMedId = null;
}
function addFromDrawer() {
  if (!infoMedId) return;
  const m = allMedicines.find(x => x.id === infoMedId);
  if (m) addToCart(m.el);
  closeInfoDrawer();
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
      + '<td style="text-align:right;padding:4px 6px;font-weight:750">' + fmt(item.price * item.qty) + '</td>'
      + '</tr>';
  });

  var html = '<!DOCTYPE html>'
    + '<html lang="vi"><head>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
    
    
    '
    + '<meta charset="UTF-8">'
    + '<title>Hóa đơn ' + escHtml(inv.code) + '</title>'
    + '<style>'
    + '* { margin:0; padding:0; box-sizing:border-box; }'
    + 'body { font-family: "Courier New", monospace; font-size: 12px; color: #000; padding: 8px; max-width: 320px; margin: 0 auto; }'
    + '.center { text-align: center; }'
    + '.bold { font-weight: bold; }'
    + '.title { font-size: 15px; font-weight:800; margin: 4px 0; }'
    + '.divider { border-top: 1px dashed #000; margin: 7px 0; }'
    + '.divider2 { border-top: 2px solid #000; margin: 7px 0; }'
    + 'table { width: 100%; border-collapse: collapse; font-size: 11px; }'
    + 'th { background: #eee; padding: 4px 6px; font-weight:750; border-bottom: 1px solid #000; }'
    + 'td { vertical-align: top; }'
    + '.totals { margin-top: 6px; }'
    + '.totals-row { display: flex; justify-content: space-between; padding: 2px 0; font-size: 12px; }'
    + '.totals-row.grand { font-size: 14px; font-weight:800; border-top: 2px solid #000; padding-top: 5px; margin-top: 3px; }'
    + '.footer { text-align: center; margin-top: 10px; font-style: italic; font-size: 11.5px; }'
    + '.kv { display: flex; justify-content: space-between; font-size: 11.5px; padding: 2px 0; }'
    + '@media print { body { padding: 0; } button { display: none; } }'
    + '</style>'
    + '    
</head><body>'
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
    + '<button onclick="window.print()" style="padding:8px 20px;background:#1a56db;color:#fff;border:none;border-radius:6px;cursor:pointer;font-size:13px;font-weight:750;font-family:'Plus Jakarta Sans',sans-serif">🖶 In hóa đơn</button>'
    + '<button onclick="window.close()" style="padding:8px 16px;background:#e5e7eb;color:#111;border:none;border-radius:6px;cursor:pointer;font-size:13px;margin-left:6px;font-family:'Plus Jakarta Sans',sans-serif">✕ Đóng</button>'
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

// ── Keyboard shortcuts ────────────────────────────────────────────────────────
document.addEventListener('keydown', e => {
  // F9 → Thanh toán
  if (e.key === 'F9') {
    e.preventDefault();
    const btn = document.getElementById('checkoutBtn');
    if (btn && !btn.disabled) doCheckout();
    return;
  }
  // Enter khi cashInput được focus
  if (e.key === 'Enter' && e.target.id === 'cashInput') {
    e.preventDefault();
    const btn = document.getElementById('checkoutBtn');
    if (btn && !btn.disabled) doCheckout();
    return;
  }
  // Escape → đóng modal
  if (e.key === 'Escape') {
    closeStationModal();
    closeFaceModal();
    closeInfoDrawer();
    closeEndShiftModal();
  }
});

// Show station modal on load if station not set yet
document.addEventListener('DOMContentLoaded', () => {
  if (currentStation === 0) {
    setTimeout(() => openStationModal(), 600);
  }
  updateStationUI();

  const urlParams = new URLSearchParams(window.location.search);
  if (urlParams.get('view') === 'invoices') {
    setTimeout(() => openMyInvModal(), 800);
  }
});

// ── MULTI-POS STATION ─────────────────────────────────────────────────────────
// Danh sách quầy ĐỘNG từ DB (bảng PosStations, admin CRUD ở shift-list.jsp).
// Fallback Quầy 1-5 nếu DB chưa có quầy nào (tương thích dữ liệu cũ).
const POS_STATIONS = [
  <c:forEach var="pst" items="${posStations}" varStatus="pstS">
  { id: ${pst.posStationId}, name: '${fn:replace(pst.stationName, "'", "\\'")}' }<c:if test="${!pstS.last}">,</c:if>
  </c:forEach>
];
if (POS_STATIONS.length === 0) {
  for (let i = 1; i <= 5; i++) POS_STATIONS.push({ id: i, name: 'Quầy ' + i });
}
// Tên hiển thị của quầy theo ID (dùng TÊN trong DB, không phải ID) — tránh lệch
// số như "Quầy 12" khi ID không liền mạch.
function stationLabelFor(id) {
  const st = POS_STATIONS.find(s => s.id === id);
  if (st && st.name) return st.name;
  return id > 0 ? 'Quầy ' + id : 'Chọn quầy';
}
// Sửa nhãn quầy render sẵn từ server (dùng ID) về đúng TÊN quầy khi đã chọn.
if (typeof updateStationUI === 'function') updateStationUI();

function openStationModal() {
  const grid = document.getElementById('stationGrid');
  grid.innerHTML = '';
  POS_STATIONS.forEach(st => {
    const opt = document.createElement('div');
    opt.className = 'station-opt' + (currentStation === st.id ? ' selected' : '');
    opt.dataset.station = st.id;
    // Nhãn lớn lấy SỐ QUẦY từ tên (VD "Quầy 3" → "Q3"), khớp với admin —
    // KHÔNG dùng st.id vì id trong DB có thể không liền mạch (2,3,4,5,12…).
    const soNum = (String(st.name).match(/\d+/) || [st.id])[0];
    opt.innerHTML = '<div class="so-num">Q' + soNum + '</div><div class="so-label">' + st.name + '</div>';
    opt.onclick = function() {
      document.querySelectorAll('.station-opt').forEach(o => o.classList.remove('selected'));
      this.classList.add('selected');
    };
    grid.appendChild(opt);
  });
  document.getElementById('stationModal').classList.add('show');
}

function closeStationModal() {
  document.getElementById('stationModal').classList.remove('show');
}

function confirmStation() {
  const sel = document.querySelector('.station-opt.selected');
  if (!sel) { showToast('⚠️ Vui lòng chọn một quầy!', 'err'); return; }
  const station = parseInt(sel.dataset.station);
  currentStation = station;

  fetch(ctx + '/pos', {
    method: 'POST',
    body: new URLSearchParams({ action: 'set-station', station }),
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
  }).catch(() => {});

  updateStationUI();
  closeStationModal();
  initNfcBridge();  // đổi quầy → nối lại kênh nghe thẻ NFC cho đúng quầy
  showToast('✓ Đã chuyển sang ' + stationLabelFor(station), 'ok');
}

// ── CẦU NỐI NFC REALTIME (điện thoại quét thẻ → tự nhảy vào màn POS) ──────────
// Điện thoại (app NFC Tools) POST UID về /pos/nfc-scan?station=N; server đẩy SSE
// về đây. Ta chỉ nhận UID rồi tái dùng logic tra thẻ sẵn có.
// (biến nfcBridge đã khai báo ở khối Multi-POS state phía trên để tránh lỗi TDZ)
function initNfcBridge() {
  if (nfcBridge) { try { nfcBridge.close(); } catch (_) {} nfcBridge = null; }
  if (!currentStation || currentStation <= 0) return; // chưa chọn quầy thì chưa nghe
  try {
    nfcBridge = new EventSource(ctx + '/pos/nfc-stream?station=' + currentStation);
    nfcBridge.addEventListener('nfc', ev => {
      try { const d = JSON.parse(ev.data); if (d && d.uid) onNfcScanned(d.uid); } catch (_) {}
    });
    // EventSource tự động reconnect khi rớt mạng — không cần xử lý thêm.
    nfcBridge.onerror = () => {};
  } catch (e) {}
}

/** Nhận UID từ điện thoại: tra thẻ, thấy khách thì fill; thẻ trắng thì mở liên kết. */
async function onNfcScanned(uid) {
  uid = (uid || '').trim().toUpperCase();
  if (!uid) return;
  try {
    const res = await fetch(ctx + '/pos?action=nfc-lookup&uid=' + encodeURIComponent(uid));
    const d = await res.json();
    if (d.found) {
      applyCustomer(d);
      showToast('📶 Thẻ của ' + d.name + (d.points ? ' · ' + d.points + ' điểm' : ''), 'ok');
    } else {
      // Thẻ chưa định danh → mở modal, sang thẳng bước nhập SĐT liên kết
      openNfcModal();
      document.getElementById('nfcUidInput').value = uid;
      document.getElementById('nfcStatus').textContent = '🆕 Thẻ mới vừa quét — nhập SĐT khách để liên kết:';
      document.getElementById('nfcStep2').style.display = 'block';
      setTimeout(() => document.getElementById('nfcPhoneInput').focus(), 120);
    }
  } catch (e) { showToast('❌ Lỗi tra thẻ NFC', 'err'); }
}

function updateStationUI() {
  const lbl = document.getElementById('stationLabel');
  if (lbl) lbl.textContent = currentStation > 0 ? stationLabelFor(currentStation) : 'Chọn quầy';
}

// ── FACE RECOGNITION CHECK-IN ─────────────────────────────────────────────────
const FACE_MODEL_URL = ctx + '/models';  // local — same as staff-checkin.jsp
const FACE_THRESHOLD  = 0.45;   // chặt hơn chuẩn 0.6 — chống nhận nhầm người
const FACE_MARGIN     = 0.08;   // người gần nhì phải xa hơn ít nhất chừng này
const FACE_STABLE_FRAMES = 3;   // cần 3 khung liên tiếp khớp cùng một người

let faceModelsLoaded  = false;
let faceDescriptors   = [];
let faceVideoStream   = null;
let faceDetectLoopId  = null;
let faceMatchedId     = null;
let faceMatchedName   = null;
let faceMatchedDescriptor = null;
let faceStreakId      = null;
let faceStreakCount   = 0;
let faceStreakSamples = [];

async function loadFaceModels() {
  if (faceModelsLoaded) return;
  const nets = faceapi.nets;
  await nets.tinyFaceDetector.loadFromUri(FACE_MODEL_URL);
  await nets.faceLandmark68Net.loadFromUri(FACE_MODEL_URL);   // full model, not TinyNet
  await nets.faceRecognitionNet.loadFromUri(FACE_MODEL_URL);
  faceModelsLoaded = true;
}

async function loadFaceDescriptors() {
  try {
    const res  = await fetch(ctx + '/pos?action=face-descriptors&uid=' + encodeURIComponent(getUid()));
    const data = await res.json();
    faceDescriptors = data
      .filter(d => d.descriptor)
      .map(d => ({
        accountId:  d.accountId,
        name:       d.name,
        descriptor: new Float32Array(JSON.parse(d.descriptor))
      }));
    const el = document.getElementById('fmEnrolledCount');
    if (el) el.textContent = faceDescriptors.length > 0
      ? faceDescriptors.length + ' nhân viên đã đăng ký khuôn mặt'
      : '⚠ Chưa có nhân viên nào đăng ký khuôn mặt';
  } catch(e) {
    faceDescriptors = [];
  }
}

async function openFaceModal() {
  document.getElementById('faceModal').classList.add('show');
  document.getElementById('fmLoading').style.display = 'flex';
  document.getElementById('fmCameraWrap').style.display = 'none';
  faceMatchedId   = null;
  faceMatchedName = null;

  try {
    await loadFaceModels();
    await loadFaceDescriptors();
  } catch(e) {
    setFmStatus('❌ Lỗi tải mô hình: ' + e.message, 'err');
    document.getElementById('fmLoading').style.display = 'none';
    document.getElementById('fmCameraWrap').style.display = 'block';
    return;
  }

  document.getElementById('fmLoading').style.display = 'none';
  document.getElementById('fmCameraWrap').style.display = 'block';

  try {
    faceVideoStream = await navigator.mediaDevices.getUserMedia({
      video: { width: 640, height: 480, facingMode: 'user' }
    });
    const video = document.getElementById('faceVideo');
    video.srcObject = faceVideoStream;
    await video.play();
    startFaceDetection();
  } catch(e) {
    setFmStatus('❌ Không truy cập được camera: ' + e.message, 'err');
  }
}

function closeFaceModal() {
  stopFaceDetection();
  if (faceVideoStream) {
    faceVideoStream.getTracks().forEach(t => t.stop());
    faceVideoStream = null;
  }
  document.getElementById('faceModal').classList.remove('show');
  faceMatchedId   = null;
  faceMatchedName = null;
  document.getElementById('fmCheckinBtn').style.display = 'none';
  if (document.getElementById('fmNoFace')) document.getElementById('fmNoFace').style.display = 'none';
  setFmStatus('Đang quét…');
  document.getElementById('faceRing').className = 'face-ring';
  // clear canvas
  const cv = document.getElementById('faceCanvas');
  if (cv) cv.getContext('2d').clearRect(0,0,cv.width,cv.height);
}

function startFaceDetection() {
  const video  = document.getElementById('faceVideo');
  const canvas = document.getElementById('faceCanvas');
  let busy = false;

  async function loop() {
    if (!faceVideoStream) return;
    if (busy) { faceDetectLoopId = requestAnimationFrame(loop); return; }

    if (video.videoWidth > 0) {
      canvas.width  = video.videoWidth;
      canvas.height = video.videoHeight;

      busy = true;
      const detection = await faceapi
        .detectSingleFace(video, new faceapi.TinyFaceDetectorOptions({ inputSize: 320, scoreThreshold: 0.5 }))
        .withFaceLandmarks()        // full faceLandmark68Net (no arg = false = full)
        .withFaceDescriptor();
      busy = false;

      const ctx2 = canvas.getContext('2d');
      ctx2.clearRect(0, 0, canvas.width, canvas.height);
      const noFaceEl = document.getElementById('fmNoFace');
      const ring     = document.getElementById('faceRing');

      if (!detection) {
        noFaceEl.style.display = 'block';
        ring.className = 'face-ring';
        faceStreakId = null; faceStreakCount = 0; faceStreakSamples = [];
        faceDetectLoopId = requestAnimationFrame(loop);
        return;
      }
      noFaceEl.style.display = 'none';
      ring.className = 'face-ring scanning';
      faceapi.draw.drawDetections(canvas, [detection.detection]);

      if (faceDescriptors.length === 0) {
        setFmStatus('⚠ Chưa có nhân viên nào đăng ký khuôn mặt', 'err');
        faceDetectLoopId = requestAnimationFrame(loop);
        return;
      }

      let bestDist = Infinity, bestMatch = null, secondDist = Infinity;
      for (const ref of faceDescriptors) {
        const dist = faceapi.euclideanDistance(detection.descriptor, ref.descriptor);
        if (dist < bestDist) { secondDist = bestDist; bestDist = dist; bestMatch = ref; }
        else if (dist < secondDist) { secondDist = dist; }
      }

      const clearMatch = bestMatch
        && bestDist <= FACE_THRESHOLD
        && (secondDist - bestDist >= FACE_MARGIN || secondDist > FACE_THRESHOLD);

      if (clearMatch) {
        if (faceStreakId === bestMatch.accountId) { faceStreakCount++; }
        else { faceStreakId = bestMatch.accountId; faceStreakCount = 1; faceStreakSamples = []; }
        faceStreakSamples.push(Array.from(detection.descriptor));

        if (faceStreakCount >= FACE_STABLE_FRAMES) {
          ring.className = 'face-ring matched';
          faceMatchedId   = bestMatch.accountId;
          faceMatchedName = bestMatch.name;
          const dim = faceStreakSamples[0].length;
          const avg = new Array(dim).fill(0);
          for (const s of faceStreakSamples) for (let i = 0; i < dim; i++) avg[i] += s[i];
          for (let i = 0; i < dim; i++) avg[i] /= faceStreakSamples.length;
          faceMatchedDescriptor = avg;
          setFmStatus('✓ Nhận ra: ' + bestMatch.name, 'ok');
          document.getElementById('fmCheckinBtn').style.display = 'flex';
          return; // dừng loop sau khi nhận ra
        }
        ring.className = 'face-ring scanning';
        setFmStatus('Đang xác nhận ' + bestMatch.name + '… (' + faceStreakCount + '/' + FACE_STABLE_FRAMES + ')');
      } else {
        faceStreakId = null; faceStreakCount = 0; faceStreakSamples = [];
        faceMatchedId = null; faceMatchedName = null; faceMatchedDescriptor = null;
        if (bestMatch && bestDist <= FACE_THRESHOLD) {
          setFmStatus('⚠ Khuôn mặt chưa đủ rõ để phân biệt — nhìn thẳng camera', 'err');
        } else {
          setFmStatus('Đang quét… (' + (bestDist === Infinity ? '—' : bestDist.toFixed(2)) + ')');
        }
        document.getElementById('fmCheckinBtn').style.display = 'none';
      }
    }
    faceDetectLoopId = requestAnimationFrame(loop);
  }
  loop();
}

function stopFaceDetection() {
  if (faceDetectLoopId) {
    cancelAnimationFrame(faceDetectLoopId);
    faceDetectLoopId = null;
  }
}

function setFmStatus(msg, type) {
  const el = document.getElementById('fmStatus');
  if (!el) return;
  el.textContent = msg;
  el.className   = 'fm-status' + (type ? ' ' + type : '');
}

async function confirmFaceCheckin() {
  if (!faceMatchedId) { showToast('⚠️ Chưa nhận dạng được khuôn mặt!', 'err'); return; }
  const btn = document.getElementById('fmCheckinBtn');
  btn.disabled = true;
  btn.textContent = '⏳ Đang điểm danh…';

  try {
    const res  = await fetch(ctx + '/pos', {
      method: 'POST',
      body: new URLSearchParams({
        action:    'pos-face-checkin',
        accountId: faceMatchedId,
        descriptor: JSON.stringify(faceMatchedDescriptor || []),
        station:   currentStation > 0 ? currentStation : 1
      }),
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    });
    const data = await res.json();
    if (data.ok) {
      currentStaffId   = data.staffId;
      currentStaffName = data.name;
      // Cập nhật UI sidebar
      const staffEl = document.getElementById('stationStaff');
      if (staffEl) staffEl.textContent = data.name;
      const checkinIcon = document.getElementById('checkinBtn');
      if (checkinIcon) {
        const iconEl = checkinIcon.querySelector('.sb-icon');
        if (iconEl) iconEl.textContent = '🟢';
        const lblEl = checkinIcon.querySelector('.sb-label');
        if (lblEl) lblEl.textContent = data.name;
      }
      // Ẩn banner điểm danh (nếu còn)
      const banner = document.getElementById('checkinBanner');
      if (banner) banner.remove();
      // Sidebar button: đổi sang toggle panel (đã logged in)
      const cbtn = document.getElementById('checkinBtn');
      if (cbtn) cbtn.setAttribute('onclick', 'toggleCheckinPanel()');
      closeFaceModal();
      const msg = data.status === 'checked-in'   ? '✅ Điểm danh thành công!' :
                  data.status === 'already-in' || data.status === 'already-active'
                                                 ? '✓ Đang trong ca làm việc' :
                                                   '✓ Đăng nhập thành công';
      showToast(msg + ' — ' + data.name, 'ok');
    } else if (data.reason === 'wrong-station') {
      showToast('⚠️ Ca của ' + (data.name || '') + ' được xếp ở ' + stationLabelFor(data.correctStation), 'err');
      btn.disabled    = false;
      btn.textContent = '✓ Xác nhận điểm danh';
    } else {
      const reasonMap = {
        'no_match':        '⚠️ Server không xác nhận được khuôn mặt. Vui lòng quét lại.',
        'reenroll_pending':'⏳ Nhân viên đang có yêu cầu đổi khuôn mặt chờ duyệt — chưa thể điểm danh.',
        'impersonation':   '🚫 Khuôn mặt không phải của nhân viên này!',
        'ambiguous':       '⚠️ Khuôn mặt quá giống người khác — nhìn thẳng camera và thử lại.',
        'no_face_enrolled':'❌ Nhân viên chưa đăng ký khuôn mặt.',
        'missing_descriptor':'⚠️ Thiếu dữ liệu khuôn mặt. Vui lòng quét lại.',
        'invalid_descriptor':'❌ Dữ liệu khuôn mặt lỗi. Vui lòng quét lại.'
      };
      showToast(reasonMap[data.reason] || ('❌ ' + (data.reason || 'Điểm danh thất bại')), 'err');
      faceStreakId = null; faceStreakCount = 0; faceStreakSamples = [];
      faceMatchedId = null; faceMatchedDescriptor = null;
      document.getElementById('fmCheckinBtn').style.display = 'none';
      btn.disabled    = false;
      btn.textContent = '✓ Xác nhận điểm danh';
      startFaceDetection();
    }
  } catch(e) {
    showToast('❌ Lỗi kết nối', 'err');
    btn.disabled    = false;
    btn.textContent = '✓ Xác nhận điểm danh';
  }
}

// ── SHIFT-LOCK: mở/đóng khóa màn hình + mở ca (khai báo tiền đầu ca) ─────────
function hideShiftLock() {
  const ov = document.getElementById('shiftLockOverlay');
  if (ov) ov.remove();
}
function showShiftLock() {
  // Ca bị mất (session hết hạn / chưa mở) — reload để server render lại overlay đúng trạng thái
  window.location.reload();
}
function openOpenCashModal() {
  const m = document.getElementById('openCashModal');
  m.style.display = 'flex';
  const inp = document.getElementById('openCashInput');
  inp.value = '';
  document.getElementById('openCashErr').style.display = 'none';
  setTimeout(() => inp.focus(), 120);
}
async function confirmOpenShift() {
  const inp = document.getElementById('openCashInput');
  const err = document.getElementById('openCashErr');
  const val = parseFloat(inp.value);
  if (isNaN(val) || val < 0) {
    err.textContent = 'Vui lòng nhập số tiền hợp lệ (≥ 0).';
    err.style.display = 'block';
    inp.focus();
    return;
  }
  const btn = document.getElementById('openShiftBtn');
  btn.disabled = true; btn.textContent = '⏳ Đang mở ca…';
  try {
    const res = await fetch(ctx + '/pos', {
      method: 'POST',
      body: new URLSearchParams({ action: 'open-shift', openingCash: val }),
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    });
    const data = await res.json();
    if (data.ok) {
      document.getElementById('openCashModal').style.display = 'none';
      hideShiftLock();
      showToast('🔓 Đã mở ca — tiền đầu ca ' + fmtMoney(val), 'ok');
    } else {
      err.textContent = data.reason === 'not_logged_in'
        ? 'Chưa điểm danh — hãy điểm danh khuôn mặt trước.'
        : ('Lỗi: ' + (data.reason || 'không mở được ca'));
      err.style.display = 'block';
      btn.disabled = false; btn.textContent = '✓ Mở ca & bắt đầu bán hàng';
    }
  } catch (e) {
    err.textContent = 'Lỗi kết nối: ' + e.message;
    err.style.display = 'block';
    btn.disabled = false; btn.textContent = '✓ Mở ca & bắt đầu bán hàng';
  }
}

// ── HÓA ĐƠN CỦA TÔI (bill trong ca hôm nay của chính nhân viên) ──────────────
function closeMyInvModal() { document.getElementById('myInvModal').style.display = 'none'; }
async function openMyInvModal() {
  const modal = document.getElementById('myInvModal');
  const list  = document.getElementById('myInvList');
  const sum   = document.getElementById('myInvSummary');
  modal.style.display = 'flex';
  list.innerHTML = '<div style="color:#94a3b8;font-size:13px;text-align:center;padding:26px 0">Đang tải…</div>';
  sum.textContent = 'Đang tải…';
  try {
    const res = await fetch(ctx + '/pos?action=my-invoices&uid=' + encodeURIComponent(getUid()));
    const data = await res.json();
    if (!data.ok) {
      list.innerHTML = '<div style="color:#dc2626;font-size:13px;text-align:center;padding:26px 0">'
        + (data.reason === 'not_logged_in' ? 'Chưa điểm danh ca làm.' : 'Lỗi tải dữ liệu.') + '</div>';
      sum.textContent = '';
      return;
    }
    sum.textContent = data.count + ' hóa đơn · Doanh thu: ' + fmtMoney(parseFloat(data.totalRevenue) || 0);
    if (!data.invoices.length) {
      list.innerHTML = '<div style="text-align:center;padding:32px 0;color:#94a3b8"><div style="font-size:34px;margin-bottom:8px">🧾</div><div style="font-size:13px">Chưa có hóa đơn nào trong ca hôm nay.</div></div>';
      return;
    }
    const mLabel = { 'CASH': '💵 Tiền mặt', 'QR_CODE': '📱 QR', 'CARD': '💳 Thẻ' };
    list.innerHTML = data.invoices.map(iv => {
      const refunded = iv.status !== 'COMPLETED';
      return '<div style="display:flex;justify-content:space-between;align-items:center;padding:11px 4px;border-bottom:1px solid #f1f5f9">'
        + '<div><div style="font-weight:750;font-size:13.5px;color:#0f172a">' + iv.code + '</div>'
        + '<div style="font-size:11.5px;color:#94a3b8;margin-top:2px">' + iv.time + ' · ' + (mLabel[iv.method] || iv.method) + '</div></div>'
        + '<div style="text-align:right"><div style="font-weight:800;font-size:14px;color:' + (refunded ? '#dc2626' : '#059669') + '">'
        + fmtMoney(parseFloat(iv.amount) || 0) + '</div>'
        + (refunded ? '<div style="font-size:10.5px;color:#dc2626;font-weight:750">Hoàn trả</div>' : '')
        + '</div></div>';
    }).join('');
  } catch (e) {
    list.innerHTML = '<div style="color:#dc2626;font-size:13px;text-align:center;padding:26px 0">Lỗi kết nối.</div>';
    sum.textContent = '';
  }
}

// Init: show station modal on load if not set
(function() {
  updateStationUI();
  if (currentStation === 0) {
    setTimeout(openStationModal, 800);
  }
})();

function printXReport() {
  showToast('🖨 Tính năng in báo cáo đang phát triển…', 'ok');
}

function toggleStaffMenu() {
  const wrap = document.getElementById('staffActionWrap');
  const menu = document.getElementById('staffActionMenu');
  if (!menu) return;
  const open = menu.classList.toggle('open');
  if (wrap) wrap.classList.toggle('open', open);
}

document.addEventListener('click', e => {
  const wrap = document.getElementById('staffActionWrap');
  if (wrap && !wrap.contains(e.target)) {
    document.getElementById('staffActionMenu')?.classList.remove('open');
    wrap.classList.remove('open');
  }
});

// ── PayOS QR Payment ──────────────────────────────────────────────────────────
let _qrOrderCode    = null;
let _qrPollIv       = null;
let _qrCountdownIv  = null;
let _qrQrInstance   = null;

async function openQrModal(total) {
  const btn = document.getElementById('checkoutBtn');
  btn.disabled = true;
  btn.innerHTML = '⏳ Tạo mã QR…';

  try {
    const res  = await fetch(ctx + '/pos', {
      method: 'POST',
      body: new URLSearchParams({ action: 'create-qr', amount: total }),
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    });
    const data = await res.json();

    if (!data.ok) {
      showToast('❌ ' + (data.msg || 'Không tạo được mã QR'), 'err');
      btn.disabled = false; btn.innerHTML = '🛒 THANH TOÁN';
      return;
    }

    _qrOrderCode = data.orderCode;

    // Reset modal state
    document.getElementById('qrmSuccessBox').classList.remove('show');
    document.getElementById('qrmQrBox').style.display = '';
    document.getElementById('qrmDot').className = 'qrm-dot';
    document.getElementById('qrmStatusTxt').textContent = 'Đang chờ thanh toán...';
    document.getElementById('qrmTimerRow').style.display = '';
    document.getElementById('qrmCancelBtn').style.display = '';
    document.getElementById('qrmAmount').textContent = fmtMoney(total);

    // Checkout link fallback
    const linkEl = document.getElementById('qrmCheckoutLink');
    linkEl.href = data.checkoutUrl || '#';

    // Render QR code
    const qrEl = document.getElementById('qrmQrCode');
    qrEl.innerHTML = '';
    if (typeof QRCode !== 'undefined') {
      _qrQrInstance = new QRCode(qrEl, {
        text: data.qrCode,
        width: 220, height: 220,
        colorDark: '#0f172a',
        colorLight: '#ffffff',
        correctLevel: QRCode.CorrectLevel.M
      });
    } else {
      // Fallback: show checkout link prominently
      qrEl.innerHTML = '<div style="padding:20px;text-align:center;font-size:12px;color:#64748b">Không load được QRCode.js<br><a href="' + (data.checkoutUrl||'#') + '" target="_blank" style="color:#2563eb">Mở link thanh toán</a></div>';
    }

    // Show modal
    document.getElementById('qrPayModal').classList.add('show');

    // Countdown 5 phút
    startQrCountdown(<%=com.medicare.config.PayOSConfig.EXPIRE_SECS%>);

    // Poll mỗi 2.5 giây
    _qrPollIv = setInterval(() => pollQrStatus(_qrOrderCode, total), 2500);

  } catch (e) {
    console.error(e);
    showToast('❌ Lỗi kết nối PayOS — kiểm tra cấu hình', 'err');
    btn.disabled = false; btn.innerHTML = '🛒 THANH TOÁN';
  }
}

async function pollQrStatus(orderCode, total) {
  try {
    const res  = await fetch(ctx + '/pos', {
      method: 'POST',
      body: new URLSearchParams({ action: 'check-qr-status', orderCode }),
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    });
    const data = await res.json();

    if (data.status === 'PAID') {
      // Stop polling & countdown
      clearInterval(_qrPollIv);     _qrPollIv = null;
      clearInterval(_qrCountdownIv);_qrCountdownIv = null;

      // Show success animation
      document.getElementById('qrmQrBox').style.display = 'none';
      document.getElementById('qrmTimerRow').style.display = 'none';
      document.getElementById('qrmCancelBtn').style.display = 'none';
      document.getElementById('qrmDot').className = 'qrm-dot paid';
      document.getElementById('qrmStatusTxt').textContent = 'Đã nhận thanh toán!';
      document.getElementById('qrmSuccessBox').classList.add('show');

      // Sau 1.5s đóng modal và complete sale
      setTimeout(() => {
        document.getElementById('qrPayModal').classList.remove('show');
        _qrOrderCode = null;
        submitSale();
      }, 1500);

    } else if (data.status === 'CANCELLED' || data.status === 'EXPIRED') {
      clearInterval(_qrPollIv);     _qrPollIv = null;
      clearInterval(_qrCountdownIv);_qrCountdownIv = null;
      document.getElementById('qrPayModal').classList.remove('show');
      _qrOrderCode = null;
      const btn = document.getElementById('checkoutBtn');
      btn.disabled = false; btn.innerHTML = '🛒 THANH TOÁN';
      showToast('❌ Mã QR đã ' + (data.status === 'CANCELLED' ? 'bị hủy' : 'hết hạn') + ' — vui lòng thử lại', 'err');
    }
  } catch (e) { /* network hiccup — retry next tick */ }
}

function startQrCountdown(secs) {
  const el = document.getElementById('qrmCountdown');
  let s = secs;
  function tick() {
    if (s < 0) { clearInterval(_qrCountdownIv); _qrCountdownIv = null; return; }
    const m = Math.floor(s / 60), sec = s % 60;
    el.textContent = m + ':' + sec.toString().padStart(2, '0');
    s--;
  }
  tick();
  _qrCountdownIv = setInterval(tick, 1000);
}

async function cancelQrPay() {
  if (_qrPollIv)     { clearInterval(_qrPollIv);     _qrPollIv = null; }
  if (_qrCountdownIv){ clearInterval(_qrCountdownIv);_qrCountdownIv = null; }
  if (_qrOrderCode) {
    // fire-and-forget cancel
    fetch(ctx + '/pos', {
      method: 'POST',
      body: new URLSearchParams({ action: 'cancel-qr', orderCode: _qrOrderCode }),
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    }).catch(() => {});
    _qrOrderCode = null;
  }
  document.getElementById('qrPayModal').classList.remove('show');
  const btn = document.getElementById('checkoutBtn');
  btn.disabled = false; btn.innerHTML = '🛒 THANH TOÁN';
}

// ── END SHIFT REPORT ─────────────────────────────────────────────────────────
var _esrExpected = 0;

async function openEndShiftModal() {
  var modal = document.getElementById('esrModal');
  modal.classList.add('show');
  document.getElementById('esrActualInput').value = '';
  document.getElementById('esrHeadMeta').textContent = 'Đang tải...';
  ['esrGrandTotal','esrCashTotal','esrQrTotal','esrCardTotal','esrOpening','esrCashSold','esrExpected']
    .forEach(function(id) { document.getElementById(id).textContent = '—'; });
  document.getElementById('esrConfirmBtn').disabled = false;
  document.getElementById('esrConfirmBtn').textContent = '⏻ Xác nhận & Đóng ca';
  _esrExpected = 0;
  calcCashVariance();

  try {
    var res = await fetch(ctx + '/pos?action=shift-summary&uid=' + encodeURIComponent(getUid()));
    var d = await res.json();
    if (!d.ok) {
      document.getElementById('esrHeadMeta').textContent = 'Chưa điểm danh — không có dữ liệu ca';
      return;
    }
    var cashV  = parseFloat(d.cashTotal)  || 0;
    var qrV    = parseFloat(d.qrTotal)    || 0;
    var cardV  = parseFloat(d.cardTotal)  || 0;
    var grand  = cashV + qrV + cardV;
    var stLbl  = d.posStation > 0 ? ' · ' + stationLabelFor(d.posStation) : '';
    var timeLbl = d.checkInTime ? ' · Vào ca: ' + d.checkInTime : '';
    document.getElementById('esrHeadMeta').textContent = d.staffName + timeLbl + stLbl;
    document.getElementById('esrGrandTotal').textContent = fmtMoney(grand);
    document.getElementById('esrInvChip').textContent    = d.invoiceCount + ' hóa đơn';
    document.getElementById('esrCashTotal').textContent  = fmtMoney(cashV);
    document.getElementById('esrQrTotal').textContent    = fmtMoney(qrV);
    document.getElementById('esrCardTotal').textContent  = fmtMoney(cardV);
    document.getElementById('esrCashTotal').className    = 'esr-prow-val' + (cashV === 0 ? ' zero' : '');
    document.getElementById('esrQrTotal').className      = 'esr-prow-val' + (qrV   === 0 ? ' zero' : '');
    document.getElementById('esrCardTotal').className    = 'esr-prow-val' + (cardV === 0 ? ' zero' : '');
    document.getElementById('esrOpening').textContent  = fmtMoney(parseFloat(d.openingCash) || 0);
    document.getElementById('esrCashSold').textContent = fmtMoney(cashV);
    _esrExpected = parseFloat(d.expectedCash) || 0;
    document.getElementById('esrExpected').textContent = fmtMoney(_esrExpected);
  } catch(e) {
    document.getElementById('esrHeadMeta').textContent = 'Lỗi kết nối server';
  }
}

function closeEndShiftModal() {
  document.getElementById('esrModal').classList.remove('show');
}

function calcCashVariance() {
  var raw   = document.getElementById('esrActualInput').value.trim();
  var box   = document.getElementById('esrVbox');
  var lbl   = document.getElementById('esrVlbl');
  var val   = document.getElementById('esrVval');

  if (raw === '' || isNaN(parseFloat(raw))) {
    box.className = 'esr-vbox empty';
    lbl.className = 'esr-vlbl empty'; lbl.textContent = 'Nhập số tiền để kiểm tra';
    val.className = 'esr-vval empty'; val.textContent = '—';
    return;
  }
  var actual   = parseFloat(raw);
  var variance = actual - _esrExpected;
  if (variance === 0) {
    box.className = 'esr-vbox zero';
    lbl.className = 'esr-vlbl zero'; lbl.textContent = '✓ Cân két — Khớp chính xác';
    val.className = 'esr-vval zero'; val.textContent = '0đ';
  } else if (variance < 0) {
    box.className = 'esr-vbox minus';
    lbl.className = 'esr-vlbl minus'; lbl.textContent = '⚠ Thiếu tiền — Nhân viên cần bù lại';
    val.className = 'esr-vval minus'; val.textContent = fmtMoney(variance);
  } else {
    box.className = 'esr-vbox plus';
    lbl.className = 'esr-vlbl plus'; lbl.textContent = '⚠ Dư tiền — Thu về công ty';
    val.className = 'esr-vval plus'; val.textContent = '+' + fmtMoney(variance);
  }
}

async function confirmEndShift() {
  var raw = document.getElementById('esrActualInput').value.trim();
  var closingCash = (raw !== '' && !isNaN(parseFloat(raw))) ? parseFloat(raw) : 0;
  var btn = document.getElementById('esrConfirmBtn');
  btn.disabled = true;
  btn.textContent = '⏳ Đang đóng ca...';
  try {
    var res = await fetch(ctx + '/pos', {
      method: 'POST',
      body: new URLSearchParams({ action: 'pos-end-shift', closingCash: closingCash }),
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    });
    var d = await res.json();
    if (d.ok) {
      closeEndShiftModal();
      showToast('✓ Đóng ca thành công — ' + (d.staffName || ''), 'ok');
      setTimeout(function() { location.reload(); }, 1600);
    } else {
      showToast('❌ ' + (d.reason || d.msg || 'Lỗi đóng ca'), 'err');
      btn.disabled = false;
      btn.textContent = '⏻ Xác nhận & Đóng ca';
    }
  } catch(e) {
    showToast('❌ Lỗi kết nối', 'err');
    btn.disabled = false;
    btn.textContent = '⏻ Xác nhận & Đóng ca';
  }
}
</script>
</body>
</html>
