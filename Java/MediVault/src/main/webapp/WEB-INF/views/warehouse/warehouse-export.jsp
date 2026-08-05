<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%--
  warehouse-export.jsp — Xuất kho (Warehouse Console), FEFO tự động.

  Wizard 5 bước, giống tinh thần warehouse-import.jsp (wh-* design system, .wh-card pane,
  .wh-steps) nhưng KHÔNG dùng lại cùng 1 form đơn-thuốc — Xuất kho xử lý NHIỀU thuốc/phiếu,
  mỗi thuốc có thể lấy từ NHIỀU lô (FEFO tự chia). Toàn bộ phân bổ do server tính
  (FefoAllocatorService qua action=allocate) — trang này chỉ hiển thị lại, không tự tính.
--%>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) request.getAttribute("staffAcc");
    String ctx = request.getContextPath();
    if (acc == null) { response.sendRedirect(ctx + "/warehouse-login"); return; }
    String fullName = acc.getFullName() != null && !acc.getFullName().isEmpty() ? acc.getFullName() : acc.getUsername();
    String initials = fullName.substring(0,1).toUpperCase();
    String uid = (String) request.getAttribute("staffUid");
    String activeNav = "export";
    boolean isManager = acc.isWarehouseManager();
    request.setAttribute("isManager", isManager);
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Xuất kho — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400..800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= ctx %>/css/staff-portal.css">
<link rel="stylesheet" href="<%= ctx %>/css/warehouse-portal.css?v=11">
<style>
/* ── Universal Font Enforcement (Nâng cấp toàn bộ phông chữ sang Plus Jakarta Sans) ── */
*, *::before, *::after, body, input, select, button, textarea, .wh-card, .wh-step, .exp-reason-card, .exp-line-card, .wh-btn, .wh-badge {
  font-family: 'Plus Jakarta Sans', system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif !important;
}

a{text-decoration:none;color:inherit}
.wh-shell{max-width:1180px}
.pane{display:none}
.pane.on{display:block;animation:paneIn 260ms cubic-bezier(.4,0,.2,1)}
@keyframes paneIn{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:none}}
.nav-row{display:flex;align-items:center;gap:10px;margin-top:24px;padding-top:20px;border-top:1px solid var(--line)}
.nav-row .grow{margin-left:auto}
.err{display:none;color:var(--danger);font-size:12.5px;font-weight:700;margin-top:6px}
.err.on{display:block}

/* ── Bước 1: thẻ lý do xuất kho ─────────────────────────────────────────── */
.exp-reason-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:16px}
.exp-reason-card{position:relative;text-align:left;cursor:pointer;border:1px solid var(--border,#E2E7E5);
  border-radius:var(--wh-r-card,18px);padding:20px;background:var(--white,#fff);transition:all var(--wh-t,180ms cubic-bezier(.4,0,.2,1));
  display:flex;flex-direction:column;gap:12px;outline:none;box-shadow:var(--wh-sh-sm,0 1px 3px rgba(0,0,0,0.03))}
.exp-reason-card:hover{border-color:#CBD5D1;transform:translateY(-2px);box-shadow:var(--wh-sh-md,0 4px 12px rgba(0,0,0,0.06))}
.exp-reason-card.picked{border-color:var(--main,#0F766E);background:#F0FDFA;box-shadow:0 0 0 3px rgba(15,118,110,.14),var(--wh-sh-md)}
.exp-reason-card .reason-top{display:flex;align-items:center;justify-content:space-between;gap:10px}
.exp-reason-card .nm{font-size:15px;font-weight:800;color:var(--ink);line-height:1.3;letter-spacing:-.2px}
.exp-reason-card .ds{font-size:13px;color:var(--muted);line-height:1.5;flex:1}
.exp-reason-card .code-tag{font-size:11.5px;font-weight:700;font-family:ui-monospace,"SF Mono",Consolas,monospace;color:var(--muted);letter-spacing:-.2px;margin-top:auto}

/* ── Bước 2: Tìm kiếm gợi ý thông minh (Smart Auto-Suggest & Autocomplete) ── */
.exp-search-wrap{position:relative}
.exp-search-wrap .wh-field{position:relative;display:flex;align-items:center}
.exp-search-wrap .wh-field svg.wh-field-ic{position:absolute;left:14px;top:50%;transform:translateY(-50%);width:18px;height:18px;color:var(--muted);pointer-events:none}
.exp-search-wrap input.wh-in{padding-left:42px;padding-right:38px;height:46px;font-size:14px;border-radius:12px;border:1.5px solid var(--border);transition:all .2s}
.exp-search-wrap input.wh-in:focus{border-color:var(--main);box-shadow:0 0 0 3px rgba(15,118,110,.14)}
.exp-clear-btn{position:absolute;right:12px;top:50%;transform:translateY(-50%);width:24px;height:24px;border-radius:50%;background:var(--surface);border:none;color:var(--muted);display:none;align-items:center;justify-content:center;cursor:pointer;padding:0}
.exp-clear-btn svg{width:14px;height:14px}
.exp-clear-btn:hover{background:#E2E8F0;color:var(--ink)}

.exp-search-filters{display:flex;align-items:center;gap:6px;margin-top:8px;flex-wrap:wrap}
.exp-filter-chip{padding:4px 10px;border-radius:20px;border:1px solid var(--border);background:var(--white);font-size:12px;font-weight:700;color:var(--muted);cursor:pointer;transition:all .15s}
.exp-filter-chip:hover{border-color:#CBD5D1;color:var(--ink);background:var(--surface)}
.exp-filter-chip.active{border-color:var(--main);background:#F0FDFA;color:var(--main);font-weight:800}

/* Bảng gợi ý nổi (Autocomplete Dropdown Box) */
.exp-search-results{display:none;position:absolute;top:calc(100% + 6px);left:0;right:0;z-index:100;
  background:#fff;border:1px solid var(--border);border-radius:16px;
  box-shadow:0 12px 36px rgba(15,23,42,.15);max-height:420px;overflow-y:auto;
  animation:suggestIn 180ms cubic-bezier(.4,0,.2,1)}
@keyframes suggestIn{from{opacity:0;transform:translateY(-6px)}to{opacity:1;transform:none}}
.exp-search-results.on{display:block}

.exp-sr-head{padding:10px 16px;background:var(--surface);border-bottom:1px solid var(--line);font-size:12px;font-weight:800;color:var(--deep);display:flex;align-items:center;justify-content:space-between}
.exp-sr-item{padding:12px 16px;border-bottom:1px solid var(--line);cursor:pointer;transition:all .15s;display:flex;align-items:center;justify-content:space-between;gap:12px}
.exp-sr-item:last-child{border-bottom:none}
.exp-sr-item:hover,.exp-sr-item.focused{background:#F0FDFA}
.exp-sr-item .sr-left{flex:1;min-width:0}
.exp-sr-item .nm{font-size:14.5px;font-weight:800;color:var(--ink);display:flex;align-items:center;gap:8px;line-height:1.3}
.exp-sr-item .nm mark{background:#FEF08A;color:#854D0E;padding:0 2px;border-radius:3px}
.exp-sr-item .sr-details{display:flex;gap:8px;flex-wrap:wrap;margin-top:5px}
.exp-sr-item .sr-tag{font-size:11.5px;color:var(--muted);background:var(--surface);padding:2px 7px;border-radius:6px}
.exp-sr-item .sr-add-btn{padding:6px 12px;border-radius:8px;background:var(--soft);color:var(--deep);font-size:12px;font-weight:800;border:none;cursor:pointer;transition:all .15s;white-space:nowrap;flex:none}
.exp-sr-item:hover .sr-add-btn,.exp-sr-item.focused .sr-add-btn{background:var(--main);color:#fff}
.exp-sr-foot{padding:8px 16px;background:var(--surface);border-top:1px solid var(--line);font-size:11px;font-weight:700;color:var(--muted);text-align:right}
.exp-sr-empty{padding:24px;text-align:center;color:var(--muted);font-size:13px;font-weight:600}

.exp-chips{display:flex;flex-wrap:wrap;gap:8px;margin-top:10px}
.exp-chip{padding:7px 13px;border-radius:20px;border:1.5px solid var(--border);background:#fff;font-size:12.5px;
  font-weight:700;color:var(--deep);cursor:pointer;display:inline-flex;align-items:center;gap:6px;transition:all .12s}
.exp-chip:hover{border-color:var(--main);color:var(--main);background:#F0FDFA}
.exp-chip .stk{font-size:11px;font-weight:800;padding:2px 6px;border-radius:10px;background:var(--wh-surf);color:var(--muted)}

.exp-lines{margin-top:18px}
.exp-line-card{padding:16px;border:1.5px solid var(--line);border-radius:16px;margin-bottom:12px;background:var(--wh-surf);transition:all .15s;box-shadow:0 1px 3px rgba(0,0,0,0.02)}
.exp-line-card:hover{border-color:#CBD5D1;box-shadow:0 3px 8px rgba(0,0,0,0.04)}
.exp-line-card.has-warn{border-color:#FCA5A5;background:#FEF2F2}
.exp-line-head{display:flex;align-items:flex-start;justify-content:space-between;gap:12px;flex-wrap:wrap}
.exp-line-title{font-size:15px;font-weight:800;color:var(--ink);display:flex;align-items:center;gap:8px}
.exp-line-badges{display:flex;align-items:center;gap:6px;flex-wrap:wrap}
.exp-line-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:8px 16px;margin-top:12px;padding:10px 14px;background:#fff;border:1px solid var(--line);border-radius:12px;font-size:12.5px;color:var(--muted)}
.exp-line-grid div b{color:var(--ink);font-weight:700}
.exp-line-qtyrow{display:flex;align-items:center;justify-content:space-between;gap:12px;margin-top:12px;padding-top:12px;border-top:1px dashed var(--line);flex-wrap:wrap}
.exp-qty-presets{display:flex;align-items:center;gap:6px}
.exp-qty-btn{height:32px;padding:0 10px;border-radius:8px;border:1px solid var(--border);background:#fff;font-size:12px;font-weight:700;color:var(--deep);cursor:pointer;font-family:inherit;transition:all .12s}
.exp-qty-btn:hover{border-color:var(--main);color:var(--main);background:#F0FDFA}
.exp-qty-btn.max-btn{border-color:#0D9488;color:#0D9488;background:#CCFBF1}
.exp-qty-btn.max-btn:hover{background:#99F6E4}
.exp-line-inputwrap{display:flex;align-items:center;gap:8px}
.exp-line-card .qty{width:110px;height:40px;border:1.5px solid var(--border);border-radius:10px;text-align:center;font-weight:800;font-size:15px;font-family:inherit;outline:none}
.exp-line-card .qty:focus{border-color:var(--main);box-shadow:0 0 0 3px rgba(15,118,110,.12)}
.exp-line-card .unit-label{font-size:13px;font-weight:700;color:var(--ink)}
.exp-line-card .rm{background:none;border:none;color:var(--danger);cursor:pointer;padding:8px;border-radius:8px;display:flex;align-items:center;justify-content:center;transition:background .12s}
.exp-line-card .rm:hover{background:#FEE2E2}
.exp-line-card .rm svg{width:18px;height:18px}
.exp-empty-lines{padding:26px;text-align:center;color:var(--muted);font-size:13px;border:1.5px dashed var(--border);border-radius:14px}

/* ── Bước 3: khối phân bổ FEFO ─────────────────────────────────────────── */
.exp-alloc-block{border:1px solid var(--line);border-radius:16px;margin-bottom:14px;overflow:hidden;background:#fff;box-shadow:0 1px 3px rgba(0,0,0,0.03)}
.exp-alloc-head{display:flex;align-items:center;gap:10px;padding:14px 16px;background:var(--wh-surf);flex-wrap:wrap;border-bottom:1px solid var(--line)}
.exp-alloc-head .nm{font-size:14.5px;font-weight:800;color:var(--ink)}
.exp-alloc-head .mt{font-size:12.5px;color:var(--muted)}
.exp-alloc-head .grow{margin-left:auto}
.exp-alloc-body{padding:14px 16px 16px}
.exp-override-box{margin-top:12px;padding:12px 14px;border-radius:12px;background:#FFFBEB;border:1px solid #FDE68A}
.exp-override-box select,.exp-override-box textarea{width:100%;margin-top:6px;padding:8px 10px;border:1.5px solid var(--border);
  border-radius:10px;font-family:inherit;font-size:13px}
.exp-shortfall{margin-top:10px}
.exp-shortfall .grid{display:grid;grid-template-columns:repeat(3,1fr);gap:10px;margin:10px 0}
.exp-shortfall .cell{text-align:center;padding:10px;border-radius:10px;background:#fff}
.exp-shortfall .cell .n{font-size:18px;font-weight:800}
.exp-shortfall .cell .l{font-size:11px;color:var(--muted)}

/* ── Sửa lỗi hiển thị Bảng Phân bổ FEFO & Xem lại (Bù trừ offset sticky header) ── */
.exp-alloc-block table.wh-table, #p3 table.wh-table, #p4 table.wh-table, #reviewTable, #detailDrawer table.wh-table {
  table-layout: auto !important;
  width: 100% !important;
}
.exp-alloc-block table.wh-table thead th, #p3 table.wh-table thead th, #p4 table.wh-table thead th, #reviewTable thead th, #detailDrawer table.wh-table thead th {
  position: static !important;
  top: auto !important;
  z-index: 1 !important;
  background: var(--surface, #F1F4F3) !important;
  padding: 10px 14px !important;
  font-size: 11.5px !important;
  font-weight: 800 !important;
  letter-spacing: .03em !important;
}
.exp-alloc-block table.wh-table td, #p3 table.wh-table td, #p4 table.wh-table td, #reviewTable td, #detailDrawer table.wh-table td {
  padding: 12px 14px !important;
  font-size: 13px !important;
  vertical-align: middle !important;
}
.exp-alloc-block .wh-tablecard, #p3 .wh-tablecard, #p4 .wh-tablecard, #detailDrawer .wh-tablecard {
  overflow: visible !important;
  border-radius: 14px !important;
  margin-top: 10px !important;
  box-shadow: 0 1px 3px rgba(0,0,0,0.03) !important;
}

/* ── Bước 4: review ─────────────────────────────────────────────────────── */
.exp-review-warn{margin-top:10px}

/* ── Bước 5 ─────────────────────────────────────────────────────────────── */
.exp-done{text-align:center;padding:40px 20px}
.exp-done .ic{width:72px;height:72px;border-radius:50%;background:linear-gradient(160deg,#D1FAE5,#A7F3D0);
  display:flex;align-items:center;justify-content:center;margin:0 auto 18px;color:#047857}
.exp-done .ic svg{width:36px;height:36px}
.exp-done .code{font-family:'Courier New',monospace;font-size:26px;font-weight:800;color:var(--deep);margin:6px 0 18px}
.exp-done .acts{display:flex;gap:10px;justify-content:center;flex-wrap:wrap}

/* ── Modal quét mã vạch ───────────────────────────────────────────────── */
.wh-modal svg, #bcModal svg, #helpModal svg, #bcUnknownModal svg {
  width: 20px !important;
  height: 20px !important;
  flex: none !important;
}
.wh-modal-head svg {
  width: 22px !important;
  height: 22px !important;
  color: var(--main) !important;
}
.bc-manual-row{display:flex;gap:8px;margin-top:12px}
.bc-manual-row input{flex:1;height:38px;padding:0 12px;border:1.5px solid var(--border);border-radius:10px;
  font-family:inherit;font-size:13.5px;outline:none}
.bc-manual-row input:focus{border-color:var(--main)}
.bc-tool-btn{display:inline-flex;align-items:center;gap:6px;height:34px;padding:0 12px;border-radius:10px;
  border:1.5px solid var(--border);background:#fff;color:var(--deep);font-size:12.5px;font-weight:700;
  cursor:pointer;font-family:inherit}
.bc-tool-btn:hover{border-color:var(--main);color:var(--main)}
.bc-tool-btn svg{width:18px !important;height:18px !important;flex:none !important}
#expBcReaderBox{margin-top:12px;border-radius:14px;overflow:hidden;display:none}
#expBcReaderBox.on{display:block}
.bc-wiz-err{display:none;color:var(--danger);font-size:12px;font-weight:700;margin-top:8px}
.bc-wiz-err.on{display:block}

/* ── Drawer list rows ─────────────────────────────────────────────────── */
.exp-drawer-row{padding:12px 14px;border:1px solid var(--line);border-radius:12px;margin-bottom:8px;cursor:pointer}
.exp-drawer-row:hover{border-color:var(--main)}
.exp-drawer-row .top{display:flex;justify-content:space-between;gap:8px;align-items:center}
.exp-drawer-row .code{font-weight:800;font-family:'Courier New',monospace}
.exp-drawer-row .mt{font-size:12px;color:var(--muted);margin-top:4px}
.exp-filter-row{display:flex;gap:8px;margin-bottom:14px;flex-wrap:wrap}
.exp-filter-row select,.exp-filter-row input{height:36px;padding:0 10px;border:1.5px solid var(--border);border-radius:10px;font-family:inherit;font-size:12.5px}

/* ── Layout Thông tin Xác nhận dạng Thẻ/Cột To (Rõ Ràng, In Đậm, Dễ Đọc) ── */
.exp-review-list { display: flex; flex-direction: column; gap: 16px; margin-top: 16px; }
.exp-review-card {
  background: #FFFFFF;
  border: 1.5px solid #CBD5E1;
  border-radius: 16px;
  padding: 20px;
  box-shadow: 0 4px 16px rgba(15, 23, 42, 0.05);
  transition: all 0.2s ease;
}
.exp-review-card:hover {
  border-color: #0F766E;
  box-shadow: 0 6px 20px rgba(15, 118, 110, 0.08);
}
.exp-review-card-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
  padding-bottom: 14px;
  border-bottom: 2px dashed #E2E8F0;
  margin-bottom: 16px;
}
.exp-review-med-name {
  font-size: 19px;
  font-weight: 800;
  color: #0F172A;
  line-height: 1.3;
}
.exp-review-med-sub {
  font-size: 13.5px;
  font-weight: 700;
  color: #475569;
  margin-top: 4px;
}
.exp-review-card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 14px;
}
.exp-review-item {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding: 14px 16px;
  background: #F8FAFC;
  border-radius: 12px;
  border: 1.5px solid #E2E8F0;
}
.exp-review-item.full-width {
  grid-column: 1 / -1;
  background: #FFFBEB;
  border-color: #FDE68A;
}
.exp-review-lbl {
  font-size: 11.5px;
  font-weight: 800;
  letter-spacing: 0.6px;
  color: #64748B;
  text-transform: uppercase;
}
.exp-review-item.full-width .exp-review-lbl {
  color: #92400E;
}
.exp-review-val {
  font-size: 16px;
  font-weight: 800;
  color: #0F172A;
  line-height: 1.4;
}
.exp-review-val.highlight-qty {
  font-size: 20px;
  font-weight: 800;
  color: #059669;
}
.exp-review-val.highlight-stock {
  font-size: 17px;
  font-weight: 800;
  color: #2563EB;
}
.exp-review-val.highlight-lot {
  font-size: 16.5px;
  font-weight: 800;
  color: #B45309;
}

/* ── Layout Thẻ Phân Bổ Lô Cột To (Step 3: FEFO Alloc - In Đậm, Rõ Ràng, Dễ Đọc) ── */
.exp-alloc-block {
  border: 1.5px solid #CBD5E1;
  border-radius: 18px;
  margin-bottom: 20px;
  overflow: hidden;
  background: #FFFFFF;
  box-shadow: 0 4px 16px rgba(15, 23, 42, 0.04);
}
.exp-alloc-head {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px 20px;
  background: #F8FAFC;
  border-bottom: 2px solid #E2E8F0;
  flex-wrap: wrap;
}
.exp-alloc-head .nm {
  font-size: 18px;
  font-weight: 800;
  color: #0F172A;
}
.exp-alloc-head .mt {
  font-size: 14px;
  font-weight: 700;
  color: #475569;
}
.exp-alloc-head .mt b {
  color: #0F766E;
  font-weight: 800;
}

.exp-lot-cards-wrap {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 14px;
}
.exp-lot-card {
  background: #FFFFFF;
  border: 1.5px solid #CBD5E1;
  border-radius: 14px;
  padding: 16px 20px;
  box-shadow: 0 2px 8px rgba(15, 23, 42, 0.03);
  transition: all 0.2s ease;
}
.exp-lot-card.dim {
  opacity: 0.45;
  background: #F8FAFC;
}
.exp-lot-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 12px;
  align-items: center;
}
.exp-lot-item {
  display: flex;
  flex-direction: column;
  gap: 5px;
  padding: 12px 14px;
  background: #F8FAFC;
  border-radius: 10px;
  border: 1.5px solid #E2E8F0;
}
.exp-lot-item.highlight-take-box {
  background: #ECFDF5;
  border-color: #A7F3D0;
}
.exp-lot-lbl {
  font-size: 11.5px;
  font-weight: 800;
  letter-spacing: 0.6px;
  color: #64748B;
  text-transform: uppercase;
}
.exp-lot-item.highlight-take-box .exp-lot-lbl {
  color: #065F46;
}
.exp-lot-val {
  font-size: 16px;
  font-weight: 800;
  color: #0F172A;
}
.exp-lot-val.code {
  font-family: ui-monospace, 'SF Mono', Consolas, monospace;
  font-size: 16.5px;
  color: #0F172A;
}
.exp-lot-val.highlight-exp {
  color: #B45309;
}
.exp-lot-val.highlight-stock {
  color: #2563EB;
}
.exp-lot-val.highlight-qty {
  font-size: 20px;
  color: #059669;
}
.exp-lot-shelf-bar {
  margin-top: 14px;
  padding: 14px 18px;
  background: #F1F5F9;
  border: 1.5px solid #E2E8F0;
  border-radius: 12px;
  font-size: 14px;
  font-weight: 600;
  color: #334155;
  line-height: 1.6;
}
.exp-lot-shelf-bar b {
  color: #0F172A;
  font-weight: 800;
}
</style>
<meta name="csrf-token" content="${csrfToken}">
<script src="<%= ctx %>/js/csrf.js"></script>
<script src="<%= ctx %>/js/warehouse-ui.js" defer></script>
<script src="https://cdn.jsdelivr.net/npm/html5-qrcode@2.3.8/html5-qrcode.min.js" defer></script>
</head>
<body class="wh">
<%@ include file="/WEB-INF/views/icons.jsp" %>
<%@ include file="warehouse-sidebar.jsp" %>

<div class="main">
  <header class="wh-topbar">
    <div class="crumb">Kho hàng</div>
    <nav class="tb-nav">
      <a href="<%= ctx %>/warehouse-import">Nhập kho</a>
      <a class="on" href="<%= ctx %>/warehouse-export">Xuất kho</a>
      <a href="<%= ctx %>/warehouse-orders">Đơn hàng</a>
      <a href="<%= ctx %>/warehouse-reorder">Gợi ý đặt hàng</a>
    </nav>
    <div class="right">
      <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc của <%= fullName %>"><%= initials %></a>
    </div>
  </header>

  <div class="wh-shell wh-anim">

    <div class="wh-head">
      <div>
        <h1>Xuất kho</h1>
        <p class="sub">Xuất thuốc khỏi kho theo phân bổ FEFO tự động (First Expired, First Out).</p>
      </div>
      <div class="wh-head-actions">
        <button type="button" class="wh-btn" onclick="openExportsDrawer('history')">
          <svg><use href="#ic-history"/></svg> Lịch sử
        </button>
        <button type="button" class="wh-btn" onclick="openExportsDrawer('list')">
          <svg><use href="#ic-clipboard"/></svg> Danh sách phiếu
        </button>
        <a class="wh-btn" href="<%= ctx %>/warehouse-inventory">
          <svg><use href="#ic-package"/></svg> Tồn kho
        </a>
        <button type="button" class="wh-btn wh-btn-icon" onclick="openHelpModal()" title="Trợ giúp">
          <svg><use href="#ic-info"/></svg>
        </button>
      </div>
    </div>

    <div class="wh-kpis">
      <div class="wh-kpi k-light <%= ((Integer) request.getAttribute("kpiPending")) == 0 ? "is-zero" : "" %>">
        <span class="ic"><svg><use href="#ic-clock"/></svg></span>
        <span class="body">
          <span class="num">${kpiPending}</span>
          <span class="lbl">Phiếu chờ xử lý</span>
        </span>
      </div>
      <div class="wh-kpi k-total">
        <span class="ic"><svg><use href="#ic-check-circle"/></svg></span>
        <span class="body">
          <span class="num">${kpiCompletedToday}</span>
          <span class="lbl">Hoàn tất hôm nay</span>
        </span>
      </div>
      <div class="wh-kpi k-soon">
        <span class="ic"><svg><use href="#ic-pill"/></svg></span>
        <span class="body">
          <span class="num">${kpiMedicinesToday}</span>
          <span class="lbl">Thuốc đã xuất hôm nay</span>
        </span>
      </div>
      <div class="wh-kpi k-low <%= ((Integer) request.getAttribute("kpiNearExpiryToday")) == 0 ? "is-zero" : "" %>">
        <span class="ic"><svg><use href="#ic-clock-alert"/></svg></span>
        <span class="body">
          <span class="num">${kpiNearExpiryToday}</span>
          <span class="lbl">Lô cận hạn đã chọn</span>
        </span>
      </div>
    </div>

    <nav class="wh-steps" id="steps" aria-label="Các bước xuất kho">
      <button type="button" class="wh-step on" data-go="1" aria-current="step">
        <span class="dot">1</span><span class="lb">Loại xuất</span><span class="sb">Chọn lý do</span>
      </button>
      <button type="button" class="wh-step" data-go="2">
        <span class="dot">2</span><span class="lb">Chọn thuốc</span><span class="sb">Tìm / quét / SL</span>
      </button>
      <button type="button" class="wh-step" data-go="3">
        <span class="dot">3</span><span class="lb">Phân bổ FEFO</span><span class="sb">Hệ thống tự chọn lô</span>
      </button>
      <button type="button" class="wh-step" data-go="4">
        <span class="dot">4</span><span class="lb">Xem lại</span><span class="sb">Kiểm tra tổng thể</span>
      </button>
      <button type="button" class="wh-step" data-go="5">
        <span class="dot">5</span><span class="lb">Hoàn tất</span><span class="sb">Xác nhận &amp; in phiếu</span>
      </button>
    </nav>

    <!-- ══ BƯỚC 1 — Loại xuất kho ══ -->
    <section class="wh-card pane on" id="p1">
      <div class="wh-card-head">
        <div class="wh-ic info"><svg><use href="#ic-out"/></svg></div>
        <div class="tt">
          <h2>Chọn loại xuất kho</h2>
          <div class="desc">Mỗi loại có luồng xử lý riêng — chọn đúng lý do trước khi chọn thuốc.</div>
        </div>
      </div>
      <div class="wh-card-body">
        <div class="exp-reason-grid" id="reasonGrid">
          <c:forEach var="r" items="${reasons}">
            <button type="button" class="exp-reason-card" data-id="${r.reasonId}"
                    data-code="${r.reasonCode}" data-name="${fn:escapeXml(r.reasonName)}"
                    data-requires-receiver="${r.requiresReceiver}" onclick="pickReason(this)">
              <div class="reason-top">
                <c:choose>
                  <c:when test="${r.reasonCode == 'RETAIL_SALE'}"><span class="wh-ic"><svg><use href="#ic-cart"/></svg></span></c:when>
                  <c:when test="${r.reasonCode == 'CUSTOMER_ORDER'}"><span class="wh-ic info"><svg><use href="#ic-user"/></svg></span></c:when>
                  <c:when test="${r.reasonCode == 'TRANSFER'}"><span class="wh-ic violet"><svg><use href="#ic-out"/></svg></span></c:when>
                  <c:when test="${r.reasonCode == 'RETURN_SUPPLIER'}"><span class="wh-ic warn"><svg><use href="#ic-history"/></svg></span></c:when>
                  <c:when test="${r.reasonCode == 'EXPIRED_DISPOSAL'}"><span class="wh-ic danger"><svg><use href="#ic-trash"/></svg></span></c:when>
                  <c:when test="${r.reasonCode == 'INTERNAL_USAGE'}"><span class="wh-ic ok"><svg><use href="#ic-package"/></svg></span></c:when>
                  <c:when test="${r.reasonCode == 'ADJUSTMENT'}"><span class="wh-ic jade"><svg><use href="#ic-clipboard"/></svg></span></c:when>
                  <c:otherwise><span class="wh-ic"><svg><use href="#ic-out"/></svg></span></c:otherwise>
                </c:choose>
                <c:choose>
                  <c:when test="${r.requiresReceiver}"><span class="wh-badge low">Cần người/nơi nhận</span></c:when>
                  <c:otherwise><span class="wh-badge mute">Không cần người nhận</span></c:otherwise>
                </c:choose>
              </div>
              <div class="nm">${r.reasonName}</div>
              <div class="ds">${r.description}</div>
              <div class="code-tag">Mã: ${r.reasonCode}</div>
            </button>
          </c:forEach>
        </div>
        <div class="err" id="e-reason">Vui lòng chọn loại xuất kho.</div>
        <div class="nav-row">
          <span class="grow"></span>
          <button type="button" class="wh-btn wh-btn-primary" data-next="2">
            Tiếp tục <svg><use href="#ic-arrow-right"/></svg>
          </button>
        </div>
      </div>
    </section>

    <!-- ══ BƯỚC 2 — Chọn thuốc ══ -->
    <section class="wh-card pane" id="p2">
      <div class="wh-card-head">
        <div class="wh-ic"><svg><use href="#ic-pill"/></svg></div>
        <div class="tt">
          <h2>Chọn thuốc cần xuất</h2>
          <div class="desc">Tìm theo tên/mã/mã vạch, quét mã vạch, hoặc chọn nhanh từ danh sách gần đây. Chỉ nhập số lượng — hệ thống tự chọn lô ở bước sau.</div>
        </div>
      </div>
      <div class="wh-card-body">
        <div class="wh-row2">
          <div class="wh-fg exp-search-wrap">
            <label for="expSearch">TÌM THUỐC (GỢI Ý THÔNG MINH)</label>
            <div class="wh-field">
              <svg class="wh-field-ic"><use href="#ic-search"/></svg>
              <input class="wh-in" type="text" id="expSearch" placeholder="Gõ tên thuốc, hoạt chất, mã vạch hoặc mã SP..." autocomplete="off">
              <button type="button" class="exp-clear-btn" id="btnClearSearch" onclick="clearSearch()" title="Xoá tìm kiếm">
                <svg><use href="#ic-x"/></svg>
              </button>
            </div>
            <div class="exp-search-filters" id="searchFilters">
              <button type="button" class="exp-filter-chip active" onclick="setSearchFilter('ALL')">Tất cả</button>
              <button type="button" class="exp-filter-chip" onclick="setSearchFilter('STOCK')">Còn tồn kho</button>
              <button type="button" class="exp-filter-chip" onclick="setSearchFilter('RX')">Kê đơn (Rx)</button>
              <button type="button" class="exp-filter-chip" onclick="setSearchFilter('NEAR_EXPIRY')">Cận hạn</button>
            </div>
            <div class="exp-search-results" id="expSearchResults"></div>
          </div>
          <div class="wh-fg">
            <label>&nbsp;</label>
            <button type="button" class="wh-btn wh-btn-lg" style="width:100%" onclick="openBarcodeModal()">
              <svg><use href="#ic-scan"/></svg> Quét mã vạch
            </button>
          </div>
        </div>

        <div id="recentWrap">
          <div class="hint" style="margin-top:14px;font-weight:700;color:var(--ink)">Xuất gần đây</div>
          <div class="exp-chips" id="recentChips"></div>
        </div>

        <div class="exp-lines" id="linesWrap">
          <div class="exp-empty-lines" id="linesEmpty">Chưa chọn thuốc nào — tìm hoặc quét mã vạch ở trên.</div>
          <div id="linesTable"></div>
        </div>
        <div class="err" id="e-lines">Vui lòng chọn ít nhất 1 thuốc với số lượng &gt; 0.</div>

        <div class="nav-row">
          <button type="button" class="wh-btn" data-prev="1"><svg><use href="#ic-chevron-left"/></svg> Quay lại</button>
          <span class="grow"></span>
          <button type="button" class="wh-btn wh-btn-primary" data-next="3">
            Tiếp tục <svg><use href="#ic-arrow-right"/></svg>
          </button>
        </div>
      </div>
    </section>

    <!-- ══ BƯỚC 3 — Phân bổ FEFO ══ -->
    <section class="wh-card pane" id="p3">
      <div class="wh-card-head">
        <div class="wh-ic"><svg><use href="#ic-target"/></svg></div>
        <div class="tt">
          <h2>Phân bổ FEFO (tự động)</h2>
          <div class="desc">Hệ thống ưu tiên lô hết hạn gần nhất trước. <c:if test="${isManager}">Bạn là Quản lý kho nên có thể ghi đè lô do hệ thống chọn.</c:if></div>
        </div>
      </div>
      <div class="wh-card-body">
        <div id="allocBlocks"></div>
        <div class="err" id="e-alloc">Còn thuốc thiếu tồn kho hoặc chưa ghi đủ lý do ghi đè — xử lý trước khi tiếp tục.</div>
        <div class="nav-row">
          <button type="button" class="wh-btn" data-prev="2"><svg><use href="#ic-chevron-left"/></svg> Quay lại</button>
          <span class="grow"></span>
          <button type="button" class="wh-btn wh-btn-primary" data-next="4">
            Tiếp tục <svg><use href="#ic-arrow-right"/></svg>
          </button>
        </div>
      </div>
    </section>

    <!-- ══ BƯỚC 4 — Xem lại ══ -->
    <section class="wh-card pane" id="p4">
      <div class="wh-card-head">
        <div class="wh-ic"><svg><use href="#ic-clipboard"/></svg></div>
        <div class="tt">
          <h2>Xem lại phiếu xuất kho</h2>
          <div class="desc">Kiểm tra kỹ trước khi xác nhận — sau khi xác nhận, tồn kho bị trừ ngay.</div>
        </div>
      </div>
      <div class="wh-card-body">
        <div class="wh-row2">
          <div class="wh-fg" id="receiverField" style="display:none">
            <label for="expReceiver">Người / Nơi nhận <span aria-hidden="true">*</span></label>
            <input class="wh-in" type="text" id="expReceiver" placeholder="VD: Khách hàng Nguyễn Văn A / Kho chi nhánh 2 / NCC ABC">
            <div class="err" id="e-receiver">Bắt buộc nhập với loại xuất kho này.</div>
          </div>
          <div class="wh-fg">
            <label for="expNotes">Ghi chú</label>
            <input class="wh-in" type="text" id="expNotes" placeholder="Không bắt buộc">
          </div>
        </div>

        <div id="overrideReasonWrap" style="display:none" class="wh-fg">
          <label for="expOverrideReason">Lý do ghi đè FEFO <span aria-hidden="true">*</span></label>
          <input class="wh-in" type="text" id="expOverrideReason" placeholder="VD: Ưu tiên giữ lô cận hạn cho lô hàng khác">
          <div class="err" id="e-override-reason">Bắt buộc khi có dòng ghi đè FEFO.</div>
        </div>

        <!-- Thẻ thông tin xác nhận dạng Cột To, In Đậm, Rõ Ràng -->
        <div class="exp-review-list" id="reviewCards"></div>

        <div class="wh-note danger exp-review-warn" id="reviewErrors" style="display:none"></div>

        <div class="nav-row">
          <button type="button" class="wh-btn" data-prev="3"><svg><use href="#ic-chevron-left"/></svg> Quay lại</button>
          <span class="grow"></span>
          <button type="button" class="wh-btn wh-btn-primary wh-btn-lg" id="btnConfirm" onclick="submitExport()">
            <svg><use href="#ic-check"/></svg> Xác nhận xuất kho
          </button>
        </div>
      </div>
    </section>

    <!-- ══ BƯỚC 5 — Hoàn tất ══ -->
    <section class="wh-card pane" id="p5">
      <div class="wh-card-body">
        <div class="exp-done">
          <div class="ic"><svg><use href="#ic-check-circle"/></svg></div>
          <div style="font-size:15px;font-weight:700;color:var(--muted)">Đã xuất kho thành công</div>
          <div class="code" id="doneCode">—</div>
          <div class="acts">
            <button type="button" class="wh-btn wh-btn-lg" id="btnPrint" onclick="printDone()">
              <svg><use href="#ic-printer"/></svg> In phiếu xuất kho
            </button>
            <button type="button" class="wh-btn wh-btn-primary wh-btn-lg" onclick="resetWizard()">
              <svg><use href="#ic-plus"/></svg> Tạo phiếu xuất mới
            </button>
          </div>
        </div>
      </div>
    </section>

  </div>
</div>

<!-- ══ Modal quét mã vạch ══ -->
<div class="wh-modal" id="bcModal">
  <div class="wh-modal-box" style="max-width:480px">
    <div class="wh-modal-head">
      <svg><use href="#ic-scan"/></svg><h3>Quét mã vạch</h3>
      <button type="button" class="wh-btn wh-btn-icon" onclick="closeModal('bcModal')"><svg><use href="#ic-x"/></svg></button>
    </div>
    <div class="wh-modal-body">
      <div class="bc-manual-row">
        <input type="text" id="bcManualInput" placeholder="Quét (USB/bàn phím) hoặc gõ mã rồi Enter" autocomplete="off">
      </div>
      <div style="margin-top:10px">
        <button type="button" class="bc-tool-btn" id="bcCameraToggle" onclick="toggleCamera()">
          <svg><use href="#ic-eye"/></svg> Bật camera
        </button>
      </div>
      <div id="expBcReaderBox"></div>
      <div class="bc-wiz-err" id="bcErr"></div>
    </div>
  </div>
</div>

<!-- ══ Modal "mã vạch chưa rõ" ══ -->
<div class="wh-modal" id="bcUnknownModal">
  <div class="wh-modal-box" style="max-width:520px">
    <div class="wh-modal-head">
      <svg><use href="#ic-alert"/></svg><h3>Mã vạch chưa gắn với thuốc nào</h3>
      <button type="button" class="wh-btn wh-btn-icon" onclick="closeModal('bcUnknownModal')"><svg><use href="#ic-x"/></svg></button>
    </div>
    <div class="wh-modal-body">
      <div class="wh-note warn"><svg><use href="#ic-alert"/></svg><span>Mã: <b id="bcUnknownCode">—</b></span></div>

      <div style="margin-top:14px">
        <div class="hint" style="font-weight:700;color:var(--ink)">Gán vào thuốc đã có</div>
        <div class="exp-search-wrap" style="margin-top:6px">
          <input class="wh-in" type="text" id="bcBindSearch" placeholder="Tìm thuốc để gán mã vạch này…" autocomplete="off">
          <div class="exp-search-results" id="bcBindResults"></div>
        </div>
      </div>

      <div style="margin:18px 0;border-top:1px solid var(--line)"></div>

      <div>
        <div class="hint" style="font-weight:700;color:var(--ink)">Hoặc tạo thuốc mới</div>
        <div class="wh-row2" style="margin-top:8px">
          <div class="wh-fg"><label>Tên thuốc *</label><input class="wh-in" id="bcNewName"></div>
          <div class="wh-fg"><label>Đơn vị *</label><input class="wh-in" id="bcNewUnit" placeholder="Hộp / Vỉ / Chai…"></div>
          <div class="wh-fg"><label>Danh mục *</label>
            <select class="wh-in" id="bcNewCategory">
              <option value="">— Chọn —</option>
              <c:forEach var="cate" items="${bcCategories}"><option value="${cate.categoryId}">${cate.categoryName}</option></c:forEach>
            </select>
          </div>
          <div class="wh-fg"><label>Nhà sản xuất *</label>
            <select class="wh-in" id="bcNewManufacturer">
              <option value="">— Chọn —</option>
              <c:forEach var="mf" items="${bcManufacturers}"><option value="${mf.manufacturerId}">${mf.name}</option></c:forEach>
            </select>
          </div>
        </div>
        <button type="button" class="wh-btn wh-btn-primary" style="margin-top:10px" onclick="quickCreateFromUnknown()">
          <svg><use href="#ic-plus"/></svg> Tạo thuốc mới với mã vạch này
        </button>
      </div>
      <div class="bc-wiz-err" id="bcUnknownErr"></div>
    </div>
  </div>
</div>

<!-- ══ Drawer Lịch sử / Danh sách phiếu ══ -->
<div class="wh-drawer" id="listDrawer">
  <div class="wh-drawer-head">
    <div>
      <h3 id="listDrawerTitle">Lịch sử xuất kho</h3>
      <div class="sub">Bấm vào 1 phiếu để xem chi tiết</div>
    </div>
    <button type="button" class="wh-btn wh-btn-icon" onclick="closeDrawer('listDrawer')"><svg><use href="#ic-x"/></svg></button>
  </div>
  <div class="wh-drawer-body">
    <div class="exp-filter-row">
      <select id="listFilterStatus" onchange="reloadExportsList()">
        <option value="">Mọi trạng thái</option>
        <option value="PENDING">Chờ xử lý</option>
        <option value="CONFIRMED">Đã xác nhận</option>
        <option value="CANCELLED">Đã huỷ</option>
        <option value="REVERSED">Đã hoàn trả</option>
      </select>
      <input type="text" id="listFilterKw" placeholder="Tìm mã phiếu / người nhận…" oninput="reloadExportsListDebounced()">
    </div>
    <div id="listDrawerBody"></div>
  </div>
</div>

<!-- ══ Drawer chi tiết 1 phiếu ══ -->
<div class="wh-drawer" id="detailDrawer">
  <div class="wh-drawer-head">
    <div><h3 id="detailCode">—</h3><div class="sub" id="detailSub">—</div></div>
    <button type="button" class="wh-btn wh-btn-icon" onclick="closeDrawer('detailDrawer')"><svg><use href="#ic-x"/></svg></button>
  </div>
  <div class="wh-drawer-body" id="detailBody"></div>
  <div class="wh-drawer-foot" id="detailFoot"></div>
</div>

<!-- ══ Modal trợ giúp ══ -->
<div class="wh-modal" id="helpModal">
  <div class="wh-modal-box" style="max-width:520px">
    <div class="wh-modal-head">
      <svg><use href="#ic-info"/></svg><h3>Hướng dẫn xuất kho</h3>
      <button type="button" class="wh-btn wh-btn-icon" onclick="closeModal('helpModal')"><svg><use href="#ic-x"/></svg></button>
    </div>
    <div class="wh-modal-body">
      <p style="font-size:13px;line-height:1.7;color:var(--ink)">
        <b>1. Chọn loại xuất kho</b> — mỗi loại có yêu cầu khác nhau (VD: Chuyển kho/Trả NCC bắt buộc nhập Người/Nơi nhận).<br>
        <b>2. Chọn thuốc</b> — tìm, quét mã vạch, hoặc chọn từ danh sách gần đây; chỉ nhập số lượng cần xuất.<br>
        <b>3. Phân bổ FEFO</b> — hệ thống tự chọn lô hết hạn gần nhất trước. Bạn <u>không</u> tự chọn lô, trừ khi là Quản lý kho ghi đè có lý do.<br>
        <b>4. Xem lại</b> — kiểm tra toàn bộ trước khi ghi vào hệ thống.<br>
        <b>5. Hoàn tất</b> — tồn kho đã bị trừ, in phiếu xuất kho nếu cần.<br><br>
        Phiếu đã xác nhận không xoá được — chỉ có thể <b>Hoàn trả</b> (trả lại đúng lô đã xuất) từ khung Lịch sử.
      </p>
    </div>
  </div>
</div>

<script>
(function () {
  var ctx = "<%= ctx %>";
  var isManager = "<%= isManager %>" === "true";

  // ── State ──────────────────────────────────────────────────────────────
  var selectedReason = null;   // {id, code, name, requiresReceiver}
  var lines = [];              // [{medicineId, name, unit, barcode, qty, allocation:null, overridden:false, overrideBatchId:null}]
  var currentStep = 1;
  var recentMedicines = [];
  var pendingUnknownBarcode = null;
  var html5Qr = null;

  // ── Step navigation ───────────────────────────────────────────────────
  function goStep(n) {
    document.querySelectorAll('.pane').forEach(function (p) { p.classList.remove('on'); });
    document.getElementById('p' + n).classList.add('on');
    document.querySelectorAll('.wh-step').forEach(function (s) {
      var sn = parseInt(s.getAttribute('data-go'), 10);
      s.classList.toggle('on', sn === n);
      s.classList.toggle('done', sn < n);
    });
    currentStep = n;
    if (n === 3) renderAllocationStep();
    if (n === 4) renderReviewStep();
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function validateStep(n) {
    if (n === 1) {
      if (!selectedReason) { document.getElementById('e-reason').classList.add('on'); return false; }
      document.getElementById('e-reason').classList.remove('on');
      return true;
    }
    if (n === 2) {
      var ok = lines.length > 0 && lines.every(function (l) { return l.qty > 0; });
      document.getElementById('e-lines').classList.toggle('on', !ok);
      return ok;
    }
    if (n === 3) {
      var bad = lines.some(function (l) {
        if (!l.allocation) return true;
        if (l.overridden) return !l.overrideBatchId;
        return l.allocation.shortfall > 0;
      });
      document.getElementById('e-alloc').classList.toggle('on', bad);
      return !bad;
    }
    return true;
  }

  document.addEventListener('click', function (e) {
    var next = e.target.closest('[data-next]');
    if (next) { var n = parseInt(next.getAttribute('data-next'), 10); if (validateStep(n - 1)) goStep(n); return; }
    var prev = e.target.closest('[data-prev]');
    if (prev) { goStep(parseInt(prev.getAttribute('data-prev'), 10)); return; }
  });

  // ── Bước 1 — chọn lý do ──────────────────────────────────────────────
  window.pickReason = function (btn) {
    document.querySelectorAll('.exp-reason-card').forEach(function (c) { c.classList.remove('picked'); });
    btn.classList.add('picked');
    selectedReason = {
      id: parseInt(btn.getAttribute('data-id'), 10),
      code: btn.getAttribute('data-code'),
      name: btn.getAttribute('data-name'),
      requiresReceiver: btn.getAttribute('data-requires-receiver') === 'true'
    };
    document.getElementById('e-reason').classList.remove('on');
  };

  // ── Bước 2 — tìm / quét / chọn thuốc ─────────────────────────────────
  function addLine(med) {
    var existing = lines.find(function (l) { return l.medicineId === med.id; });
    if (existing) { renderLines(); focusQty(med.id); return; }
    lines.push({
      medicineId: med.id,
      name: med.name,
      genericName: med.genericName || '',
      code: med.code || '',
      barcode: med.barcode || '',
      unit: med.unit || '',
      price: med.price || 0,
      totalStock: med.totalStock != null ? med.totalStock : 0,
      nearestBatchNo: med.nearestBatchNo || '',
      nearestExpiry: med.nearestExpiry || '',
      shelfId: med.shelfId,
      shelfName: med.shelfName || '',
      categoryName: med.categoryName || '',
      manufacturerName: med.manufacturerName || '',
      rx: med.rx || false,
      storageConditions: med.storageConditions || '',
      qty: 1,
      allocation: null,
      overridden: false,
      overrideBatchId: null
    });
    renderLines();
    focusQty(med.id);
  }

  function focusQty(medicineId) {
    setTimeout(function () {
      var el = document.querySelector('.exp-line-card[data-mid="' + medicineId + '"] .qty');
      if (el) { el.focus(); el.select(); }
    }, 30);
  }

  function renderLines() {
    var wrap = document.getElementById('linesTable');
    var empty = document.getElementById('linesEmpty');
    empty.style.display = lines.length === 0 ? 'block' : 'none';
    wrap.innerHTML = lines.map(function (l) {
      var isStockWarn = l.totalStock <= 0 || l.qty > l.totalStock;
      var stockBadge = l.totalStock > 0
        ? '<span class="wh-badge ok">Tồn kho khả dụng: <b>' + l.totalStock + ' ' + escapeHtml(l.unit) + '</b></span>'
        : '<span class="wh-badge out">HẾT HÀNG TRONG KHO</span>';
      var rxBadge = l.rx ? '<span class="wh-badge low">Kê đơn (Rx)</span>' : '';
      var warnNotice = (l.qty > l.totalStock && l.totalStock > 0)
        ? '<span class="wh-badge out" style="margin-left:6px">Vượt quá tồn kho (Tồn: ' + l.totalStock + ')</span>' : '';

      return '<div class="exp-line-card' + (isStockWarn ? ' has-warn' : '') + '" data-mid="' + l.medicineId + '">' +
        '<div class="exp-line-head">' +
          '<div class="exp-line-title">' + escapeHtml(l.name) + rxBadge + warnNotice + '</div>' +
          '<div class="exp-line-badges">' + stockBadge + '</div>' +
        '</div>' +
        '<div class="exp-line-grid">' +
          '<div><b>Hoạt chất:</b> ' + escapeHtml(l.genericName || '—') + '</div>' +
          '<div><b>Mã vạch / SP:</b> ' + escapeHtml(l.barcode || l.code || '—') + '</div>' +
          '<div><b>Vị trí kệ:</b> ' + escapeHtml(l.shelfName || (l.shelfId ? ('Kệ #' + l.shelfId) : 'Chưa xếp kệ')) + '</div>' +
          '<div><b>Lô cận hạn nhất:</b> ' + escapeHtml(l.nearestExpiry ? (l.nearestExpiry + (l.nearestBatchNo ? ' (' + l.nearestBatchNo + ')' : '')) : '—') + '</div>' +
          '<div><b>Bảo quản:</b> ' + escapeHtml(l.storageConditions || 'Thường') + '</div>' +
          '<div><b>Giá bán:</b> ' + (l.price ? (Number(l.price).toLocaleString('vi-VN') + ' đ / ' + escapeHtml(l.unit)) : '—') + '</div>' +
        '</div>' +
        '<div class="exp-line-qtyrow">' +
          '<div class="exp-qty-presets">' +
            '<span style="font-size:12px;font-weight:700;color:var(--muted)">Nhập nhanh:</span>' +
            '<button type="button" class="exp-qty-btn" onclick="addQty(' + l.medicineId + ', 1)">+1</button>' +
            '<button type="button" class="exp-qty-btn" onclick="addQty(' + l.medicineId + ', 5)">+5</button>' +
            '<button type="button" class="exp-qty-btn" onclick="addQty(' + l.medicineId + ', 10)">+10</button>' +
            (l.totalStock > 0 ? '<button type="button" class="exp-qty-btn max-btn" onclick="setMaxQty(' + l.medicineId + ')">Xuất tất cả (' + l.totalStock + ')</button>' : '') +
          '</div>' +
          '<div class="exp-line-inputwrap">' +
            '<span style="font-size:12px;font-weight:700;color:var(--ink)">SL xuất:</span>' +
            '<input type="number" class="qty" min="1" max="' + (l.totalStock > 0 ? l.totalStock : '') + '" value="' + l.qty + '" onchange="updateQty(' + l.medicineId + ', this.value)" oninput="updateQty(' + l.medicineId + ', this.value)">' +
            '<span class="unit-label">' + escapeHtml(l.unit || '') + '</span>' +
            '<button type="button" class="rm" onclick="removeLine(' + l.medicineId + ')" title="Xoá thuốc này"><svg><use href="#ic-trash"/></svg></button>' +
          '</div>' +
        '</div>' +
        '</div>';
    }).join('');
  }

  window.addQty = function (medicineId, delta) {
    var l = lines.find(function (x) { return x.medicineId === medicineId; });
    if (!l) return;
    l.qty = Math.max(1, (l.qty || 0) + delta);
    l.allocation = null; l.overridden = false; l.overrideBatchId = null;
    renderLines();
  };
  window.setMaxQty = function (medicineId) {
    var l = lines.find(function (x) { return x.medicineId === medicineId; });
    if (!l) return;
    if (l.totalStock > 0) {
      l.qty = l.totalStock;
      l.allocation = null; l.overridden = false; l.overrideBatchId = null;
      renderLines();
    }
  };

  window.updateQty = function (medicineId, val) {
    var l = lines.find(function (x) { return x.medicineId === medicineId; });
    if (!l) return;
    l.qty = Math.max(1, parseInt(val, 10) || 1);
    l.allocation = null; l.overridden = false; l.overrideBatchId = null;
  };
  window.removeLine = function (medicineId) {
    lines = lines.filter(function (l) { return l.medicineId !== medicineId; });
    renderLines();
  };

  // ── Tìm kiếm gợi ý thông minh (Smart Auto-Suggest & Autocomplete) ──────
  var searchTimer = null;
  var currentSearchFilter = 'ALL';
  var searchFocusIndex = -1;
  var expSearchInput = document.getElementById('expSearch');
  var expClearBtn = document.getElementById('btnClearSearch');

  window.setSearchFilter = function (filter) {
    currentSearchFilter = filter;
    document.querySelectorAll('.exp-filter-chip').forEach(function (c) {
      c.classList.toggle('active', c.getAttribute('onclick').indexOf("'" + filter + "'") !== -1);
    });
    triggerSearch();
  };

  expSearchInput.addEventListener('focus', function () {
    triggerSearch();
  });

  expSearchInput.addEventListener('input', function () {
    expClearBtn.style.display = this.value.length > 0 ? 'flex' : 'none';
    triggerSearch();
  });

  expSearchInput.addEventListener('keydown', function (e) {
    var box = document.getElementById('expSearchResults');
    var items = box.querySelectorAll('.exp-sr-item');
    if (!box.classList.contains('on') || items.length === 0) return;

    if (e.key === 'ArrowDown') {
      e.preventDefault();
      searchFocusIndex = (searchFocusIndex + 1) % items.length;
      updateFocusedSearchItem(items);
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      searchFocusIndex = (searchFocusIndex - 1 + items.length) % items.length;
      updateFocusedSearchItem(items);
    } else if (e.key === 'Enter') {
      e.preventDefault();
      if (searchFocusIndex >= 0 && items[searchFocusIndex]) {
        items[searchFocusIndex].click();
      }
    } else if (e.key === 'Escape') {
      box.classList.remove('on');
    }
  });

  function updateFocusedSearchItem(items) {
    items.forEach(function (el, idx) {
      el.classList.toggle('focused', idx === searchFocusIndex);
      if (idx === searchFocusIndex) el.scrollIntoView({ block: 'nearest' });
    });
  }

  window.clearSearch = function () {
    expSearchInput.value = '';
    expClearBtn.style.display = 'none';
    expSearchInput.focus();
    triggerSearch();
  };

  function triggerSearch() {
    clearTimeout(searchTimer);
    var kw = expSearchInput.value.trim();
    var box = document.getElementById('expSearchResults');

    searchTimer = setTimeout(function () {
      var url = ctx + '/warehouse-export?action=search-medicine&kw=' + encodeURIComponent(kw);
      fetch(url)
        .then(function (r) { return r.json(); })
        .then(function (data) {
          var meds = data.medicines || [];
          searchFocusIndex = -1;

          if (currentSearchFilter === 'STOCK') {
            meds = meds.filter(function (m) { return (m.totalStock || 0) > 0; });
          } else if (currentSearchFilter === 'RX') {
            meds = meds.filter(function (m) { return m.rx; });
          } else if (currentSearchFilter === 'NEAR_EXPIRY') {
            meds = meds.filter(function (m) { return m.nearestExpiry != null && m.nearestExpiry !== ''; });
          }

          if (meds.length === 0) {
            box.innerHTML = '<div class="exp-sr-empty">Không tìm thấy thuốc nào phù hợp.</div>';
          } else {
            var headTitle = kw.length > 0
              ? ('Gợi ý cho từ khoá "' + escapeHtml(kw) + '" (' + meds.length + ')')
              : ('Gợi ý thuốc phổ biến (' + meds.length + ')');

            var itemsHtml = meds.map(function (m) {
              var stockBadge = (m.totalStock != null)
                ? (m.totalStock > 0
                    ? '<span class="wh-badge ok">Tồn: ' + m.totalStock + ' ' + escapeHtml(m.unit || '') + '</span>'
                    : '<span class="wh-badge out">HẾT HÀNG</span>')
                : '';
              var rxBadge = m.rx ? '<span class="wh-badge low">Rx</span>' : '';
              var highlightedName = highlightKeyword(escapeHtml(m.name), kw);

              return '<div class="exp-sr-item" onclick=\'pickSearchResult(' + JSON.stringify(m).replace(/'/g, "&#39;") + ')\'>' +
                '<div class="sr-left">' +
                  '<div class="nm"><span>' + highlightedName + '</span>' + rxBadge + stockBadge + '</div>' +
                  '<div class="sr-details">' +
                    (m.genericName ? '<span class="sr-tag">Hoạt chất: ' + escapeHtml(m.genericName) + '</span>' : '') +
                    '<span class="sr-tag">Mã: ' + escapeHtml(m.barcode || m.code || '—') + '</span>' +
                    '<span class="sr-tag">Kệ: ' + escapeHtml(m.shelfName || (m.shelfId ? ('Kệ #' + m.shelfId) : 'Chưa gán')) + '</span>' +
                    (m.nearestExpiry ? '<span class="sr-tag">HSD gần nhất: ' + escapeHtml(m.nearestExpiry) + '</span>' : '') +
                  '</div>' +
                '</div>' +
                '<button type="button" class="sr-add-btn">+ Thêm xuất</button>' +
              '</div>';
            }).join('');

            box.innerHTML = '<div class="exp-sr-head"><span>' + headTitle + '</span><span class="wh-badge mute">Ấn [Enter] để chọn nhanh</span></div>' +
              itemsHtml +
              '<div class="exp-sr-foot">[↑↓] Di chuyển · [Enter] Chọn thuốc · [Esc] Đóng gợi ý</div>';
          }
          box.classList.add('on');
        });
    }, kw.length === 0 ? 0 : 150);
  }

  function highlightKeyword(text, kw) {
    if (!kw) return text;
    var re = new RegExp('(' + escapeRegExp(kw) + ')', 'gi');
    return text.replace(re, '<mark>$1</mark>');
  }
  function escapeRegExp(string) {
    return string.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
  }
  function escapeHtml(s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }

  window.pickSearchResult = function (m) {
    addLine(m);
    document.getElementById('expSearchResults').classList.remove('on');
    expSearchInput.value = '';
    if (expClearBtn) expClearBtn.style.display = 'none';
  };
  document.addEventListener('click', function (e) {
    if (!e.target.closest('.exp-search-wrap')) document.getElementById('expSearchResults').classList.remove('on');
  });

  function loadRecent() {
    fetch(ctx + '/warehouse-export?action=recent-medicines')
      .then(function (r) { return r.json(); })
      .then(function (data) {
        recentMedicines = data.medicines || [];
        var box = document.getElementById('recentChips');
        document.getElementById('recentWrap').style.display = recentMedicines.length ? 'block' : 'none';
        box.innerHTML = recentMedicines.map(function (m) {
          var stk = (m.totalStock != null) ? ('Tồn: ' + m.totalStock + ' ' + (m.unit || '')) : '';
          return '<button type="button" class="exp-chip" onclick=\'pickSearchResult(' + JSON.stringify(m).replace(/'/g, "&#39;") + ')\'>' +
            '<span>' + escapeHtml(m.name) + '</span>' +
            (stk ? '<span class="stk">' + escapeHtml(stk) + '</span>' : '') +
          '</button>';
        }).join('');
      });
  }

  // ── Quét mã vạch ─────────────────────────────────────────────────────
  window.openBarcodeModal = function () {
    openModal('bcModal');
    var input = document.getElementById('bcManualInput');
    input.value = '';
    document.getElementById('bcErr').classList.remove('on');
    setTimeout(function () { input.focus(); }, 60);
  };
  document.getElementById('bcManualInput').addEventListener('keydown', function (e) {
    if (e.key === 'Enter' && this.value.trim()) { handleScanned(this.value.trim(), 'manual'); this.value = ''; }
  });

  window.toggleCamera = function () {
    var box = document.getElementById('expBcReaderBox');
    if (html5Qr) {
      html5Qr.stop().then(function () { html5Qr = null; box.classList.remove('on'); box.innerHTML = ''; });
      return;
    }
    if (typeof Html5Qrcode === 'undefined') { document.getElementById('bcErr').textContent = 'Thư viện camera chưa sẵn sàng, thử lại sau giây lát.'; document.getElementById('bcErr').classList.add('on'); return; }
    box.classList.add('on');
    box.innerHTML = '<div id="expBcReader" style="width:100%"></div>';
    html5Qr = new Html5Qrcode('expBcReader');
    html5Qr.start({ facingMode: 'environment' }, { fps: 10, qrbox: 220 }, function (code) {
      handleScanned(code, 'camera');
    }, function () {}).catch(function (err) {
      document.getElementById('bcErr').textContent = 'Không mở được camera: ' + err;
      document.getElementById('bcErr').classList.add('on');
    });
  };

  function handleScanned(code, source) {
    fetch(ctx + '/warehouse-export?action=lookup-barcode&barcode=' + encodeURIComponent(code) + '&source=' + source)
      .then(function (r) { return r.json(); })
      .then(function (data) {
        if (data.found) {
          addLine(data.medicine);
          closeModal('bcModal');
          if (window.whToast) whToast('Đã thêm: ' + data.medicine.name, true);
        } else {
          closeModal('bcModal');
          pendingUnknownBarcode = code;
          document.getElementById('bcUnknownCode').textContent = code;
          document.getElementById('bcUnknownErr').classList.remove('on');
          openModal('bcUnknownModal');
        }
      });
  }

  var bindTimer = null;
  document.getElementById('bcBindSearch').addEventListener('input', function () {
    var kw = this.value.trim();
    var box = document.getElementById('bcBindResults');
    clearTimeout(bindTimer);
    if (kw.length < 2) { box.classList.remove('on'); return; }
    bindTimer = setTimeout(function () {
      fetch(ctx + '/warehouse-export?action=search-medicine&kw=' + encodeURIComponent(kw))
        .then(function (r) { return r.json(); })
        .then(function (data) {
          var meds = data.medicines || [];
          box.innerHTML = meds.length === 0 ? '<div class="exp-sr-empty">Không tìm thấy.</div>' : meds.map(function (m) {
            return '<div class="exp-sr-item" onclick="bindUnknownTo(' + m.id + ')">' +
              '<span class="nm">' + escapeHtml(m.name) + '</span></div>';
          }).join('');
          box.classList.add('on');
        });
    }, 250);
  });

  window.bindUnknownTo = function (medicineId) {
    var form = new URLSearchParams();
    form.set('medicineId', medicineId);
    form.set('barcode', pendingUnknownBarcode);
    form.set('source', 'manual');
    fetch(ctx + '/warehouse-export?action=bind-barcode', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: form })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        if (data.ok) { addLine(data.medicine); closeModal('bcUnknownModal'); if (window.whToast) whToast('Đã gán mã vạch', true); }
        else { showUnknownErr('Không gán được — mã vạch có thể đã thuộc thuốc khác.'); }
      });
  };

  window.quickCreateFromUnknown = function () {
    var name = document.getElementById('bcNewName').value.trim();
    var unit = document.getElementById('bcNewUnit').value.trim();
    var categoryId = document.getElementById('bcNewCategory').value;
    var manufacturerId = document.getElementById('bcNewManufacturer').value;
    if (!name || !unit || !categoryId || !manufacturerId) { showUnknownErr('Điền đủ Tên / Đơn vị / Danh mục / Nhà sản xuất.'); return; }
    var form = new URLSearchParams();
    form.set('name', name); form.set('unit', unit); form.set('categoryId', categoryId);
    form.set('manufacturerId', manufacturerId); form.set('barcode', pendingUnknownBarcode);
    form.set('sellingPrice', '0'); form.set('source', 'manual');
    fetch(ctx + '/warehouse-export?action=quick-create-medicine', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: form })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        if (data.ok) { addLine(data.medicine); closeModal('bcUnknownModal'); if (window.whToast) whToast('Đã tạo thuốc mới', true); }
        else { showUnknownErr('Không tạo được thuốc (mã vạch có thể đã tồn tại).'); }
      });
  };
  function showUnknownErr(msg) { var e = document.getElementById('bcUnknownErr'); e.textContent = msg; e.classList.add('on'); }

  // ── Bước 3 — phân bổ FEFO ────────────────────────────────────────────
  function renderAllocationStep() {
    var box = document.getElementById('allocBlocks');
    box.innerHTML = lines.map(function (l) {
      return '<div class="exp-alloc-block" data-mid="' + l.medicineId + '"><div class="exp-alloc-head">' +
        '<span class="nm">' + escapeHtml(l.name) + '</span><span class="mt">Yêu cầu: ' + l.qty + ' ' + escapeHtml(l.unit || '') + '</span>' +
        '<span class="grow"></span><span class="wh-badge mute">Đang tải…</span></div><div class="exp-alloc-body"></div></div>';
    }).join('');
    lines.forEach(loadAllocationFor);
  }

  function loadAllocationFor(l) {
    fetch(ctx + '/warehouse-export?action=allocate&medicineId=' + l.medicineId + '&qty=' + l.qty)
      .then(function (r) { return r.json(); })
      .then(function (data) {
        l.allocation = data;
        renderAllocationBlock(l);
      });
  }

  function renderAllocationBlock(l) {
    var block = document.querySelector('.exp-alloc-block[data-mid="' + l.medicineId + '"]');
    if (!block) return;
    var a = l.allocation;
    var head = block.querySelector('.exp-alloc-head');
    var badge = head.querySelector('.wh-badge');
    var body = block.querySelector('.exp-alloc-body');

    head.innerHTML = '<span class="nm">' + escapeHtml(l.name) + '</span>' +
      (l.genericName ? '<span style="font-size:12px;color:var(--muted)"> (' + escapeHtml(l.genericName) + ')</span>' : '') +
      '<span class="mt"> · Yêu cầu xuất: <b>' + l.qty + ' ' + escapeHtml(l.unit || '') + '</b> (Tồn kho khả dụng: ' + l.totalStock + ' ' + escapeHtml(l.unit || '') + ')</span>' +
      '<span class="grow"></span><span class="wh-badge mute">' + (badge ? badge.textContent : 'Đang tải…') + '</span>';
    badge = head.querySelector('.wh-badge');

    if (a.shortfall > 0 && !l.overridden) {
      badge.className = 'wh-badge out'; badge.textContent = 'THIẾU ' + a.shortfall + ' ' + escapeHtml(l.unit || '');
      body.innerHTML = '<div class="wh-note danger exp-shortfall"><svg><use href="#ic-alert"/></svg><div>' +
        '<b>Không đủ tồn kho khả dụng để xuất.</b>' +
        '<div class="grid"><div class="cell"><div class="n">' + l.qty + '</div><div class="l">Yêu cầu</div></div>' +
        '<div class="cell"><div class="n">' + (l.qty - a.shortfall) + '</div><div class="l">Còn khả dụng</div></div>' +
        '<div class="cell"><div class="n">' + a.shortfall + '</div><div class="l">Thiếu</div></div></div>' +
        '<button type="button" class="wh-btn wh-btn-primary" onclick="createPurchaseSuggestion(' + l.medicineId + ', ' + a.shortfall + ')">' +
        '<svg><use href="#ic-cart"/></svg> Tạo đề xuất mua hàng</button></div></div>' + lotTableHtml(a.lots, l);
    } else {
      badge.className = 'wh-badge ok'; badge.textContent = l.overridden ? 'GHI ĐÈ FEFO' : 'AUTO FEFO OK';
      body.innerHTML = lotTableHtml(a.lots, l) + overrideBoxHtml(l, a);
    }
  }

  function lotTableHtml(lots, l) {
    if (!lots || lots.length === 0) return '<div class="wh-note warn" style="margin-top:12px"><svg><use href="#ic-alert"/></svg><span>Không có lô nào còn tồn kho.</span></div>';

    var cards = lots.map(function (lot) {
      var picked = l.overridden ? (l.overrideBatchId === lot.batchId) : true;
      var qtyTaken = l.overridden ? (picked ? l.qty : 0) : lot.allocatedQuantity;

      return '<div class="exp-lot-card' + (l.overridden && !picked ? ' dim' : '') + '">' +
        '<div class="exp-lot-grid">' +
          '<div class="exp-lot-item">' +
            '<span class="exp-lot-lbl">SỐ LÔ</span>' +
            '<span class="exp-lot-val code">' + escapeHtml(lot.batchNumber) + '</span>' +
          '</div>' +
          '<div class="exp-lot-item">' +
            '<span class="exp-lot-lbl">HẠN SỬ DỤNG (HSD)</span>' +
            '<span class="exp-lot-val highlight-exp">' + escapeHtml(lot.expiryDate) + '</span>' +
          '</div>' +
          '<div class="exp-lot-item">' +
            '<span class="exp-lot-lbl">TỒN KHẢ DỤNG</span>' +
            '<span class="exp-lot-val highlight-stock">' + lot.availableQuantity + '</span>' +
          '</div>' +
          '<div class="exp-lot-item highlight-take-box">' +
            '<span class="exp-lot-lbl">ĐƯỢC LẤY</span>' +
            '<span class="exp-lot-val highlight-qty">' + qtyTaken + '</span>' +
          '</div>' +
        '</div>' +
      '</div>';
    }).join('');

    var shelfInfo = escapeHtml(l.shelfName || (l.allocation && l.allocation.shelfName) || 'Chưa xếp kệ');
    var storageInfo = (l.storageConditions || (l.allocation && l.allocation.storageConditions))
      ? escapeHtml(l.storageConditions || l.allocation.storageConditions) : '';

    return '<div class="exp-lot-cards-wrap">' + cards + '</div>' +
      '<div class="exp-lot-shelf-bar">' +
        '📍 Vị trí kệ: <b>' + shelfInfo + '</b>' +
        (storageInfo ? ' · ❄️ Bảo quản: <b>' + storageInfo + '</b>' : '') +
      '</div>';
  }

  function overrideBoxHtml(l, a) {
    if (!isManager) return '';
    var options = (a.lots || []).map(function (lot) {
      return '<option value="' + lot.batchId + '"' + (l.overrideBatchId === lot.batchId ? ' selected' : '') + '>' +
        escapeHtml(lot.batchNumber) + ' — HSD ' + escapeHtml(lot.expiryDate) + ' (còn ' + lot.availableQuantity + ')</option>';
    }).join('');
    return '<div class="exp-override-box">' +
      '<label style="display:flex;align-items:center;gap:8px;font-weight:700;font-size:13px;cursor:pointer">' +
      '<input type="checkbox" ' + (l.overridden ? 'checked' : '') + ' onchange="toggleOverride(' + l.medicineId + ', this.checked)"> ' +
      'Ghi đè — tự chọn lô khác (chỉ Quản lý kho)</label>' +
      (l.overridden ? '<select onchange="setOverrideBatch(' + l.medicineId + ', this.value)"><option value="">— Chọn lô —</option>' + options + '</select>' : '') +
      '</div>';
  }

  window.toggleOverride = function (medicineId, checked) {
    var l = lines.find(function (x) { return x.medicineId === medicineId; });
    l.overridden = checked;
    l.overrideBatchId = null;
    renderAllocationBlock(l);
  };
  window.setOverrideBatch = function (medicineId, batchId) {
    var l = lines.find(function (x) { return x.medicineId === medicineId; });
    l.overrideBatchId = batchId ? parseInt(batchId, 10) : null;
    renderAllocationBlock(l);
  };

  window.createPurchaseSuggestion = function (medicineId, missingQty) {
    var form = new URLSearchParams();
    form.set('medicineId', medicineId); form.set('missingQty', missingQty);
    fetch(ctx + '/warehouse-export?action=purchase-suggestion', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: form })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        if (window.whToast) whToast(data.ok ? 'Đã tạo đề xuất mua hàng (PENDING).' : (data.message || 'Không tạo được đề xuất — thuốc chưa từng nhập kho.'), data.ok);
      });
  };

  // ── Bước 4 — review ──────────────────────────────────────────────────
  function renderReviewStep() {
    document.getElementById('receiverField').style.display = selectedReason && selectedReason.requiresReceiver ? 'block' : 'none';
    var anyOverride = lines.some(function (l) { return l.overridden; });
    document.getElementById('overrideReasonWrap').style.display = anyOverride ? 'block' : 'none';

    var box = document.getElementById('reviewCards');
    if (!box) return;
    box.innerHTML = lines.map(function (l) {
      var a = l.allocation;
      var lotsText = l.overridden
        ? (a.lots.find(function (x) { return x.batchId === l.overrideBatchId; }) ?
            (function (lot) { return '<b>' + escapeHtml(lot.batchNumber) + '</b> (HSD ' + lot.expiryDate + ')'; })(a.lots.find(function (x) { return x.batchId === l.overrideBatchId; }))
            : '<span style="color:var(--danger)">Chưa chọn lô ghi đè</span>')
        : (a.lots || []).map(function (lot) { return '<b>' + escapeHtml(lot.batchNumber) + '</b> ×' + lot.allocatedQuantity + ' (HSD ' + lot.expiryDate + ')'; }).join(', ');

      return '<div class="exp-review-card">' +
        '<div class="exp-review-card-head">' +
          '<div class="exp-review-med-info">' +
            '<div class="exp-review-med-name">' + escapeHtml(l.name) + '</div>' +
            (l.genericName ? '<div class="exp-review-med-sub">Hoạt chất: <b>' + escapeHtml(l.genericName) + '</b></div>' : '') +
          '</div>' +
          '<button type="button" class="wh-btn" onclick="goStepFromReview(2)" title="Chỉnh sửa dòng này" style="border-radius:10px;font-weight:700">' +
            '<svg><use href="#ic-edit"/></svg> Chỉnh sửa' +
          '</button>' +
        '</div>' +
        '<div class="exp-review-card-grid">' +
          '<div class="exp-review-item">' +
            '<span class="exp-review-lbl">MÃ VẠCH / SP</span>' +
            '<span class="exp-review-val" style="font-family:monospace">' + escapeHtml(l.barcode || l.code || '—') + '</span>' +
          '</div>' +
          '<div class="exp-review-item">' +
            '<span class="exp-review-lbl">VỊ TRÍ KỆ</span>' +
            '<span class="exp-review-val">' + escapeHtml(l.shelfName || (l.shelfId ? ('Kệ #' + l.shelfId) : '—')) + '</span>' +
          '</div>' +
          '<div class="exp-review-item">' +
            '<span class="exp-review-lbl">TỒN KHẢ DỤNG</span>' +
            '<span class="exp-review-val highlight-stock">' + l.totalStock + ' ' + escapeHtml(l.unit || '') + '</span>' +
          '</div>' +
          '<div class="exp-review-item">' +
            '<span class="exp-review-lbl">SL XUẤT</span>' +
            '<span class="exp-review-val highlight-qty">' + l.qty + ' ' + escapeHtml(l.unit || '') + '</span>' +
          '</div>' +
          '<div class="exp-review-item full-width">' +
            '<span class="exp-review-lbl">LÔ &amp; HSD ĐÃ CHỌN</span>' +
            '<span class="exp-review-val highlight-lot">' + lotsText + (l.overridden ? ' <span class="wh-badge low" style="margin-left:8px;font-size:12px">Ghi đè FEFO</span>' : '') + '</span>' +
          '</div>' +
        '</div>' +
      '</div>';
    }).join('');
    document.getElementById('reviewErrors').style.display = 'none';
  }
  window.goStepFromReview = function (n) { goStep(n); };

  // ── Bước 5 — xác nhận ────────────────────────────────────────────────
  var lastExportId = null, lastExportCode = null;

  window.submitExport = function () {
    var receiver = document.getElementById('expReceiver').value.trim();
    var notes = document.getElementById('expNotes').value.trim();
    var overrideReason = document.getElementById('expOverrideReason').value.trim();
    var errs = [];
    if (selectedReason.requiresReceiver && !receiver) errs.push('Vui lòng nhập Người/Nơi nhận.');
    var anyOverride = lines.some(function (l) { return l.overridden; });
    if (anyOverride && !overrideReason) errs.push('Vui lòng nhập lý do ghi đè FEFO.');
    if (anyOverride && lines.some(function (l) { return l.overridden && !l.overrideBatchId; })) errs.push('Còn dòng ghi đè chưa chọn lô.');
    if (errs.length) { showReviewErrors(errs); return; }

    var form = new URLSearchParams();
    form.set('reasonId', selectedReason.id);
    form.set('receiver', receiver);
    form.set('notes', notes);
    form.set('overrideReason', overrideReason);
    lines.forEach(function (l) {
      form.append('medicineId', l.medicineId);
      form.append('requestedQty', l.qty);
      form.append('overridden', l.overridden ? '1' : '0');
      form.append('overrideBatchId', l.overridden && l.overrideBatchId ? l.overrideBatchId : '');
    });

    var btn = document.getElementById('btnConfirm');
    btn.disabled = true; btn.classList.add('is-busy');
    fetch(ctx + '/warehouse-export?action=confirm', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: form })
      .then(function (r) { return r.json(); })
      .then(function (data) {
        btn.disabled = false; btn.classList.remove('is-busy');
        if (!data.ok) { showReviewErrors(data.errors || ['Không xác nhận được — thử lại.']); return; }
        lastExportId = data.exportId; lastExportCode = data.exportCode;
        document.getElementById('doneCode').textContent = data.exportCode;
        goStep(5);
      })
      .catch(function () { btn.disabled = false; btn.classList.remove('is-busy'); showReviewErrors(['Lỗi kết nối — thử lại.']); });
  };

  function showReviewErrors(errs) {
    var box = document.getElementById('reviewErrors');
    box.innerHTML = '<svg><use href="#ic-alert"/></svg><div>' + errs.map(escapeHtml).join('<br>') + '</div>';
    box.style.display = 'flex';
  }

  window.printDone = function () { if (lastExportId) window.open(ctx + '/warehouse-export?action=print&exportId=' + lastExportId, '_blank'); };

  window.resetWizard = function () {
    selectedReason = null; lines = []; lastExportId = null; lastExportCode = null;
    document.querySelectorAll('.exp-reason-card').forEach(function (c) { c.classList.remove('picked'); });
    document.getElementById('expReceiver').value = ''; document.getElementById('expNotes').value = ''; document.getElementById('expOverrideReason').value = '';
    renderLines();
    loadRecent();
    goStep(1);
  };

  // ── Drawer Lịch sử / Danh sách phiếu ─────────────────────────────────
  window.openExportsDrawer = function (mode) {
    document.getElementById('listDrawerTitle').textContent = mode === 'history' ? 'Lịch sử xuất kho' : 'Danh sách phiếu xuất kho';
    document.getElementById('listFilterStatus').value = '';
    document.getElementById('listFilterKw').value = '';
    openDrawer('listDrawer');
    reloadExportsList();
  };
  var listDebTimer = null;
  window.reloadExportsListDebounced = function () { clearTimeout(listDebTimer); listDebTimer = setTimeout(reloadExportsList, 300); };
  window.reloadExportsList = function () {
    var status = document.getElementById('listFilterStatus').value;
    var kw = document.getElementById('listFilterKw').value.trim();
    var url = ctx + '/warehouse-export?action=list&status=' + encodeURIComponent(status) + '&kw=' + encodeURIComponent(kw);
    fetch(url).then(function (r) { return r.json(); }).then(function (data) {
      var box = document.getElementById('listDrawerBody');
      var list = data.exports || [];
      box.innerHTML = list.length === 0 ? '<div class="wh-empty">Không có phiếu nào.</div>' : list.map(function (e) {
        return '<div class="exp-drawer-row" onclick="openDetailDrawer(' + e.exportId + ')"><div class="top">' +
          '<span class="code">' + escapeHtml(e.exportCode) + '</span>' + statusBadge(e.status) + '</div>' +
          '<div class="mt">' + escapeHtml(e.reasonName) + ' · ' + escapeHtml(e.createdByName || '') + ' · ' + escapeHtml(e.createdAt || '') + '</div></div>';
      }).join('');
    });
  };

  function statusBadge(status) {
    var map = { PENDING: ['low','Chờ xử lý'], CONFIRMED: ['ok','Đã xác nhận'], CANCELLED: ['mute','Đã huỷ'], REVERSED: ['out','Đã hoàn trả'] };
    var m = map[status] || ['mute', status];
    return '<span class="wh-badge ' + m[0] + '">' + m[1] + '</span>';
  }

  window.openDetailDrawer = function (exportId) {
    openDrawer('detailDrawer');
    document.getElementById('detailCode').textContent = 'Đang tải…';
    document.getElementById('detailBody').innerHTML = '';
    document.getElementById('detailFoot').innerHTML = '';
    fetch(ctx + '/warehouse-export?action=detail&exportId=' + exportId).then(function (r) { return r.json(); }).then(function (data) {
      if (!data.ok) { document.getElementById('detailCode').textContent = 'Không tìm thấy'; return; }
      var e = data.export;
      document.getElementById('detailCode').textContent = e.exportCode;
      document.getElementById('detailSub').textContent = e.reasonName + ' · ' + (e.createdAt || '');

      var rows = data.details.map(function (d) {
        return '<tr>' +
          '<td><b>' + escapeHtml(d.medicineName) + '</b>' + (d.medicineCode ? ' (' + escapeHtml(d.medicineCode) + ')' : '') + '</td>' +
          '<td>' + escapeHtml(d.barcode || '—') + '</td>' +
          '<td>' + escapeHtml(d.batchNumber) + '</td>' +
          '<td>' + escapeHtml(d.expiryDate) + '</td>' +
          '<td class="num"><b>' + d.allocatedQuantity + '</b></td>' +
        '</tr>';
      }).join('');
      var hist = data.history.map(function (h) {
        return '<div class="mt">' + statusBadge(h.status) + ' ' + escapeHtml(h.accountName || '') + ' — ' + escapeHtml(h.createdAt || '') +
          (h.notes ? ' (' + escapeHtml(h.notes) + ')' : '') + '</div>';
      }).join('');

      document.getElementById('detailBody').innerHTML =
        '<div>' + statusBadge(e.status) + (e.receiver ? ' · Nhận: ' + escapeHtml(e.receiver) : '') + '</div>' +
        '<div class="wh-tablecard" style="margin-top:12px"><div class="wh-tablescroll"><table class="wh-table">' +
        '<thead><tr><th>Thuốc</th><th>Mã vạch</th><th>Lô xuất</th><th>HSD</th><th>SL</th></tr></thead><tbody>' + rows + '</tbody></table></div></div>' +
        '<div style="margin-top:16px"><div class="hint" style="font-weight:700;color:var(--ink)">Lịch sử</div>' + hist + '</div>';

      var foot = '<a class="wh-btn" href="' + ctx + '/warehouse-export?action=print&exportId=' + e.exportId + '" target="_blank"><svg><use href="#ic-printer"/></svg> In</a>';
      if (e.status === 'CONFIRMED') {
        foot += '<button type="button" class="wh-btn wh-btn-danger" onclick="reverseExport(' + e.exportId + ')"><svg><use href="#ic-corner-up-left"/></svg> Hoàn trả</button>';
      } else if (e.status === 'PENDING') {
        foot += '<button type="button" class="wh-btn wh-btn-danger" onclick="cancelExport(' + e.exportId + ')"><svg><use href="#ic-x"/></svg> Huỷ phiếu</button>';
      }
      document.getElementById('detailFoot').innerHTML = foot;
    });
  };

  window.reverseExport = function (exportId) {
    var reason = prompt('Lý do hoàn trả phiếu xuất kho:');
    if (!reason || !reason.trim()) return;
    var form = new URLSearchParams(); form.set('exportId', exportId); form.set('reason', reason.trim());
    fetch(ctx + '/warehouse-export?action=reverse', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: form })
      .then(function (r) { return r.json(); }).then(function (data) {
        if (window.whToast) whToast(data.ok ? 'Đã hoàn trả phiếu xuất kho.' : (data.reason || 'Không hoàn trả được.'), data.ok);
        if (data.ok) { openDetailDrawer(exportId); reloadExportsList(); location.reload(); }
      });
  };
  window.cancelExport = function (exportId) {
    var reason = prompt('Lý do huỷ phiếu:');
    if (!reason || !reason.trim()) return;
    var form = new URLSearchParams(); form.set('exportId', exportId); form.set('reason', reason.trim());
    fetch(ctx + '/warehouse-export?action=cancel', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: form })
      .then(function (r) { return r.json(); }).then(function (data) {
        if (window.whToast) whToast(data.ok ? 'Đã huỷ phiếu.' : (data.reason || 'Không huỷ được.'), data.ok);
        if (data.ok) { closeDrawer('detailDrawer'); reloadExportsList(); }
      });
  };

  // ── Modal / Drawer helpers ───────────────────────────────────────────
  window.openModal = function (id) { document.getElementById(id).classList.add('open'); };
  window.closeModal = function (id) { document.getElementById(id).classList.remove('open'); };
  window.openDrawer = function (id) { document.getElementById(id).classList.add('open'); };
  window.closeDrawer = function (id) { document.getElementById(id).classList.remove('open'); };
  window.openHelpModal = function () { openModal('helpModal'); };
  document.querySelectorAll('.wh-modal').forEach(function (m) {
    m.addEventListener('click', function (e) { if (e.target === m) m.classList.remove('open'); });
  });

  function ensureReasonsRendered() {
    var grid = document.getElementById('reasonGrid');
    if (grid && grid.children.length === 0) {
      var defaultReasons = [
        { id: 1, code: 'RETAIL_SALE', name: 'Bán lẻ (POS)', desc: 'Xuất thuốc phục vụ bán hàng trực tiếp tại quầy POS', reqRec: false, icClass: 'wh-ic', ic: '#ic-cart' },
        { id: 2, code: 'CUSTOMER_ORDER', name: 'Đơn hàng khách (Portal)', desc: 'Xuất thuốc cho đơn hàng đặt qua Cổng khách hàng', reqRec: true, icClass: 'wh-ic info', ic: '#ic-user' },
        { id: 3, code: 'TRANSFER', name: 'Chuyển kho / Điều chuyển', desc: 'Xuất chuyển thuốc sang kho chi nhánh, tủ trực hoặc khoa phòng khác', reqRec: true, icClass: 'wh-ic violet', ic: '#ic-out' },
        { id: 4, code: 'RETURN_SUPPLIER', name: 'Trả nhà cung cấp', desc: 'Xuất trả lại thuốc kém chất lượng, lỗi sản xuất hoặc cận hạn cho NCC', reqRec: true, icClass: 'wh-ic warn', ic: '#ic-history' },
        { id: 5, code: 'EXPIRED_DISPOSAL', name: 'Tiêu huỷ hết hạn', desc: 'Xuất tiêu huỷ thuốc quá hạn sử dụng, biến chất hoặc nứt vỡ', reqRec: false, icClass: 'wh-ic danger', ic: '#ic-trash' },
        { id: 6, code: 'INTERNAL_USAGE', name: 'Sử dụng nội bộ', desc: 'Xuất dùng cho đào tạo, kiểm nghiệm, mẫu thử hoặc nghiên cứu nội bộ', reqRec: false, icClass: 'wh-ic ok', ic: '#ic-package' },
        { id: 7, code: 'ADJUSTMENT', name: 'Điều chỉnh tồn kho', desc: 'Xuất cân bằng số lượng sau kỳ kiểm kê kho phát hiện chênh lệch', reqRec: false, icClass: 'wh-ic jade', ic: '#ic-clipboard' }
      ];
      grid.innerHTML = defaultReasons.map(function(r) {
        var badge = r.reqRec
          ? '<span class="wh-badge low">Cần người/nơi nhận</span>'
          : '<span class="wh-badge mute">Không cần người nhận</span>';
        return '<button type="button" class="exp-reason-card" data-id="' + r.id + '" ' +
          'data-code="' + r.code + '" data-name="' + escapeHtml(r.name) + '" ' +
          'data-requires-receiver="' + r.reqRec + '" onclick="pickReason(this)">' +
          '<div class="reason-top"><span class="' + r.icClass + '"><svg><use href="' + r.ic + '"/></svg></span>' + badge + '</div>' +
          '<div class="nm">' + escapeHtml(r.name) + '</div>' +
          '<div class="ds">' + escapeHtml(r.desc) + '</div>' +
          '<div class="code-tag">Mã: ' + r.code + '</div>' +
          '</button>';
      }).join('');
    }
  }

  ensureReasonsRendered();
  loadRecent();
})();
</script>
</body>
</html>
