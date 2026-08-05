<%@ page contentType="text/html;charset=UTF-8"  pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Customer me = (com.medicare.entity.Customer) request.getAttribute("me");
    com.medicare.entity.LoyaltyCard card = (com.medicare.entity.LoyaltyCard) request.getAttribute("card");
    if (me == null) { response.sendRedirect(request.getContextPath() + "/portal"); return; }

    String dn = me.getCustomerName() != null ? me.getCustomerName() : "Khách hàng";
    String initials = dn.length() >= 2
        ? dn.substring(0,1).toUpperCase() + dn.substring(1,2).toUpperCase() : dn.toUpperCase();

    int avail   = card != null ? card.getAvailablePoints() : 0;
    int total   = card != null ? card.getTotalPoints() : 0;
    String cardCode   = card != null && card.getCardCode() != null ? card.getCardCode() : "CARD—";

    // ── Thống kê "Tháng này" cho khu vực Analytics của Lịch sử mua hàng ──
    @SuppressWarnings("unchecked")
    java.util.List<com.medicare.entity.Invoice> invoiceList =
        (java.util.List<com.medicare.entity.Invoice>) request.getAttribute("invoices");
    java.time.YearMonth curMonth = java.time.YearMonth.now();
    int monthOrders = 0;
    java.math.BigDecimal monthSpend = java.math.BigDecimal.ZERO;
    if (invoiceList != null) {
        for (com.medicare.entity.Invoice iv : invoiceList) {
            if (iv.getCreatedAt() != null && java.time.YearMonth.from(iv.getCreatedAt()).equals(curMonth)) {
                monthOrders++;
                if (iv.getFinalAmount() != null) monthSpend = monthSpend.add(iv.getFinalAmount());
            }
        }
    }
    java.math.BigDecimal monthAvg = monthOrders > 0
        ? monthSpend.divide(java.math.BigDecimal.valueOf(monthOrders), 0, java.math.RoundingMode.HALF_UP)
        : java.math.BigDecimal.ZERO;
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
    
    
    
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title><%= dn %> — MediCare Portal</title>

<script src="https://cdn.jsdelivr.net/npm/qrcodejs@1.0.0/qrcode.min.js"></script>
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--teal:#0d9488;--teal-d:#0f766e;--ink:#0f172a;--muted:#64748b;--border:#e2e8f0;--soft:#f0fdfa;
  --ease-spring:cubic-bezier(.22,1,.36,1);--ease-out:cubic-bezier(.16,1,.3,1)}
html,body{min-height:100%;font-family:'Plus Jakarta Sans',sans-serif}
body{background:#f8fafc;color:var(--ink);padding-bottom:76px}

/* ── MOTION: stagger entrance khi tải trang (topbar/thẻ/section tự khai --stg) ── */
.stg{opacity:0;animation:stgIn .6s var(--ease-out) forwards;animation-delay:calc(var(--stg) * .08s)}
@keyframes stgIn{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)}}
@media(prefers-reduced-motion:reduce){.stg{animation:none;opacity:1}}

/* ── Shimmer skeleton khi tải chi tiết hóa đơn ── */
.skel{border-radius:11px;background:linear-gradient(100deg,#f1f5f9 30%,#f8fafc 50%,#f1f5f9 70%);background-size:220% 100%;animation:shimmer 1.3s ease-in-out infinite}
@keyframes shimmer{0%{background-position:120% 0}100%{background-position:-20% 0}}

/* ── TOPBAR ── */
.topbar{position:sticky;top:0;z-index:50;background:rgba(255,255,255,.94);backdrop-filter:blur(10px);border-bottom:1px solid var(--border);box-shadow:0 1px 6px rgba(15,23,42,.04);padding:12px 18px;display:flex;align-items:center;justify-content:space-between}
.tb-logo{display:flex;align-items:center;gap:9px}
.tb-badge{width:36px;height:36px;border-radius:11px;background:linear-gradient(135deg,var(--teal),#14b8a6);display:flex;align-items:center;justify-content:center;font-size:17px;box-shadow:0 5px 12px -4px rgba(13,148,136,.5)}
.tb-name{font-size:16px;font-weight:800;letter-spacing:-.3px;line-height:1}
.tb-name span{color:var(--teal)}
.tb-sub{font-size:8.5px;font-weight:750;letter-spacing:1.6px;text-transform:uppercase;color:#94a3b8}
.tb-user{display:flex;align-items:center;gap:9px}
.tb-av{width:36px;height:36px;border-radius:11px;background:linear-gradient(135deg,#ccfbf1,#99f6e4);color:var(--teal-d);font-weight:800;font-size:13px;display:flex;align-items:center;justify-content:center;border:1.5px solid #5eead4}
.tb-uname{font-size:13px;font-weight:750;line-height:1.15;max-width:130px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.tb-utier{font-size:10.5px;color:var(--teal-d);font-weight:750}

.wrap{max-width:560px;margin:0 auto;padding:18px 16px}
.tab-page{display:none;animation:fadeUp .28s ease}
.tab-page.active{display:block}
@keyframes fadeUp{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:translateY(0)}}

/* ── THẺ THÀNH VIÊN 3D ── */
.card-stage{perspective:1100px;margin-bottom:18px}
.member-card{
  position:relative;border-radius:22px;padding:22px 22px 20px;color:#fff;overflow:hidden;
  background:linear-gradient(145deg,#134e4a 0%,#0f766e 45%,#0d9488 100%);
  box-shadow:0 4px 10px rgba(13,148,136,.15),0 28px 50px -18px rgba(15,118,110,.55);
  transform-style:preserve-3d;transition:transform .16s cubic-bezier(.2,.7,.3,1);will-change:transform}
.member-card::before{content:'';position:absolute;inset:0;
  background:radial-gradient(160px 110px at var(--mx,75%) var(--my,20%),rgba(255,255,255,.22),transparent 70%);
  opacity:0;transition:opacity .25s;pointer-events:none}
.member-card:hover::before,.member-card.tilting::before{opacity:1}
.mc-shield{position:absolute;right:-18px;bottom:-24px;font-size:120px;opacity:.07;transform:translateZ(5px)}
.mc-row1{display:flex;justify-content:space-between;align-items:flex-start;transform:translateZ(30px)}
.mc-tier-lbl{font-size:10px;font-weight:750;letter-spacing:1.6px;text-transform:uppercase;color:rgba(255,255,255,.55)}
.mc-tier{font-size:21px;font-weight:800;margin-top:2px;letter-spacing:-.3px}
.mc-id{background:rgba(255,255,255,.12);border:1px solid rgba(255,255,255,.14);padding:6px 12px;border-radius:11px;font-size:11px;font-weight:750}
.mc-points-lbl{font-size:10.5px;color:rgba(255,255,255,.55);font-weight:750;margin-top:22px;transform:translateZ(25px)}
.mc-points{display:flex;align-items:baseline;gap:8px;transform:translateZ(35px)}
.mc-points b{font-size:38px;font-weight:800;letter-spacing:-1px}
.mc-points span{font-size:12px;font-weight:750;background:rgba(255,255,255,.14);padding:3px 9px;border-radius:8px}
.mc-progress{margin-top:16px;transform:translateZ(20px)}
.mc-prog-row{display:flex;justify-content:space-between;font-size:11px;color:rgba(255,255,255,.85);margin-bottom:6px}
.mc-bar{height:9px;background:rgba(0,0,0,.22);border-radius:20px;padding:1.5px;border:1px solid rgba(255,255,255,.08)}
.mc-fill{height:100%;border-radius:20px;background:linear-gradient(90deg,#fff,#ccfbf1);width:0;transition:width 1.1s var(--ease-spring) .5s}
.mc-qr-hint{margin-top:14px;display:flex;align-items:center;gap:8px;font-size:11px;color:rgba(255,255,255,.6);transform:translateZ(15px)}
.mc-qr-hint button{background:rgba(255,255,255,.14);border:1px solid rgba(255,255,255,.16);color:#fff;padding:7px 14px;border-radius:10px;font-size:12px;font-weight:750;cursor:pointer;font-family:inherit}

/* ── SECTION CARD ── */
.sec{background:#fff;border:1.5px solid var(--border);border-radius:18px;margin-bottom:16px;overflow:hidden;box-shadow:0 1px 2px rgba(15,23,42,.04),0 10px 24px -18px rgba(15,23,42,.25)}
.sec-head{padding:15px 18px;border-bottom:1.5px solid #f1f5f9;display:flex;align-items:center;justify-content:space-between}
.sec-head h3{font-size:14.5px;font-weight:800}
.sec-body{padding:14px 18px}

/* Offer */
.offer{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:12px;border:1.5px solid var(--border);border-radius:14px;margin-bottom:10px;transition:border .15s,transform .2s var(--ease-spring),box-shadow .2s}
.offer:hover{border-color:#5eead4;transform:translateY(-2px);box-shadow:0 10px 22px -14px rgba(13,148,136,.4)}
.offer:active{transform:translateY(0) scale(.99)}
.offer button{transition:transform .15s var(--ease-spring)}
.offer button:active:not(:disabled){transform:scale(.93)}
.offer-l{display:flex;gap:11px;align-items:center;min-width:0}
.offer-ic{width:42px;height:42px;border-radius:12px;background:linear-gradient(135deg,var(--teal),#14b8a6);color:#fff;display:flex;align-items:center;justify-content:center;font-size:17px;flex-shrink:0;box-shadow:0 6px 12px -5px rgba(13,148,136,.5)}
.offer-name{font-size:13.5px;font-weight:800}
.offer-pts{font-size:11px;font-weight:800;color:var(--teal-d);background:var(--soft);border:1px solid #99f6e4;padding:2px 9px;border-radius:8px;display:inline-block;margin-top:3px}
.offer button{background:var(--teal);color:#fff;border:none;padding:9px 16px;border-radius:10px;font-size:12.5px;font-weight:800;cursor:pointer;font-family:inherit;flex-shrink:0}
.offer button:disabled{background:#cbd5e1;cursor:not-allowed}

/* Invoice row */
.inv-row{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:13px 2px;border-bottom:1px solid #f1f5f9;cursor:pointer;transition:background .15s,transform .12s var(--ease-spring);border-radius:10px}
.inv-row:last-child{border-bottom:none}
.inv-row:hover{background:#f8fafc}
.inv-row:active{transform:scale(.985)}
.inv-row:hover .inv-code{color:var(--teal-d)}
.inv-code{font-size:13.5px;font-weight:800;transition:color .15s}
.inv-date{font-size:11.5px;color:var(--muted);margin-top:2px}
.inv-amt{font-size:14px;font-weight:800;text-align:right}
.inv-status{font-size:10px;font-weight:800;padding:2px 8px;border-radius:8px;display:inline-block;margin-top:3px}
.st-ok{background:#ecfdf5;color:#047857}.st-cancel{background:#fef2f2;color:#b91c1c}

/* Health profile */
.hp-alert{background:#fef2f2;border:1.5px solid #fecaca;border-radius:13px;padding:12px 14px;font-size:12.5px;color:#991b1b;line-height:1.5;margin-bottom:14px}
.fld{margin-bottom:13px}
.fld label{font-size:12px;font-weight:750;color:#334155;display:block;margin-bottom:5px}
.fld input,.fld select,.fld textarea{width:100%;border:1.5px solid var(--border);border-radius:11px;padding:10px 12px;font-size:14px;font-family:inherit;outline:none;transition:border .15s}
.fld input:focus,.fld select:focus,.fld textarea:focus{border-color:var(--teal)}
.fld textarea{resize:vertical;min-height:56px}
.btn-save{width:100%;padding:13px;background:linear-gradient(135deg,var(--teal),var(--teal-d));border:none;border-radius:13px;color:#fff;font-size:14.5px;font-weight:800;cursor:pointer;font-family:inherit;box-shadow:0 8px 18px -8px rgba(13,148,136,.55)}
.btn-logout{width:100%;padding:12px;background:#fef2f2;border:1.5px solid #fecaca;border-radius:13px;color:#b91c1c;font-size:13.5px;font-weight:800;cursor:pointer;font-family:inherit;margin-top:10px}

/* Point history */
.ph-row{display:flex;justify-content:space-between;align-items:center;padding:10px 2px;border-bottom:1px solid #f1f5f9;font-size:12.5px}
.ph-row:last-child{border-bottom:none}
.ph-earn{color:#047857;font-weight:800}.ph-redeem{color:#b91c1c;font-weight:800}

/* ── HISTORY / ACTIVITY CENTER ── */
.hstats{display:grid;grid-template-columns:repeat(2,1fr);gap:10px;margin-bottom:14px}
.hstat{background:#fff;border:1.5px solid var(--border);border-radius:14px;padding:12px 14px}
.hstat-v{font-size:17px;font-weight:800;letter-spacing:-.3px}
.hstat-l{font-size:10.5px;color:var(--muted);font-weight:750;margin-top:2px}

.htoolbar{margin-bottom:14px}
.hsearch{display:flex;align-items:center;gap:8px;background:#fff;border:1.5px solid var(--border);border-radius:13px;padding:10px 14px;margin-bottom:10px}
.hsearch input{border:none;outline:none;flex:1;font-size:14px;font-family:inherit;background:none}
.hchips{display:flex;gap:8px;overflow-x:auto;padding-bottom:2px;margin-bottom:10px;scrollbar-width:none}
.hchips::-webkit-scrollbar{display:none}
.hchip{flex-shrink:0;min-height:36px;padding:7px 14px;border-radius:20px;border:1.5px solid var(--border);background:#fff;font-family:inherit;font-size:12.5px;font-weight:750;color:#475569;cursor:pointer;white-space:nowrap;transition:all .15s}
.hchip:hover{border-color:#5eead4}
.hchip.active{background:var(--teal);border-color:var(--teal);color:#fff}
.hsort{width:100%;min-height:44px;border:1.5px solid var(--border);border-radius:12px;padding:9px 12px;font-family:inherit;font-size:13px;font-weight:750;color:var(--ink);background:#fff}

.hgroup{margin-bottom:6px}
.hgroup-head{display:flex;align-items:baseline;justify-content:space-between;padding:16px 2px 8px;position:sticky;top:56px;background:#f8fafc;z-index:5}
.hgroup-title{font-size:13px;font-weight:800;color:var(--ink);text-transform:uppercase;letter-spacing:.4px}
.hgroup-meta{font-size:11px;color:var(--muted);font-weight:750}

.hcard{background:#fff;border:1.5px solid var(--border);border-radius:16px;padding:14px 16px;margin-bottom:10px;cursor:pointer;box-shadow:0 1px 2px rgba(15,23,42,.03);transition:transform .18s var(--ease-spring),box-shadow .18s,border-color .18s}
.hcard:hover{transform:translateY(-2px);box-shadow:0 14px 28px -16px rgba(15,23,42,.22);border-color:#99f6e4}
.hcard:active{transform:translateY(0) scale(.99)}
.hcard-top{display:flex;align-items:center;justify-content:space-between;gap:8px}
.hcard-code{font-size:14px;font-weight:800}
.hcard-time{font-size:11.5px;color:var(--muted);margin-top:2px}
.hcard-tags{display:flex;flex-wrap:wrap;gap:6px;margin-top:10px}
.htag{font-size:10.5px;font-weight:750;padding:3px 9px;border-radius:8px;background:#f1f5f9;color:#475569}
.htag-rx{background:#eff6ff;color:#1d4ed8}
.htag-discount{background:#fdf4ff;color:#a21caf}
.hcard-bottom{display:flex;align-items:center;justify-content:space-between;margin-top:12px;padding-top:10px;border-top:1px dashed #f1f5f9}
.hcard-amt{font-size:16px;font-weight:800}
.hcard-pts{font-size:11.5px;font-weight:800;color:#047857;background:#ecfdf5;padding:3px 9px;border-radius:8px}

.hbadge{font-size:10px;font-weight:800;padding:3px 9px;border-radius:8px;display:inline-flex;align-items:center;gap:3px;flex-shrink:0}
.hbadge-ok{background:#ecfdf5;color:#047857}
.hbadge-pending{background:#fff7ed;color:#c2410c}
.hbadge-cancel{background:#fef2f2;color:#b91c1c}

@media(min-width:768px){
  .hstats{grid-template-columns:repeat(4,1fr)}
  .htoolbar{display:flex;align-items:center;gap:12px;flex-wrap:wrap}
  .hsearch{margin-bottom:0;flex:1;min-width:200px}
  .hchips{margin-bottom:0;flex:2}
  .hsort{width:auto}
}
@media(min-width:992px){
  .hcards-grid{display:grid;grid-template-columns:repeat(2,1fr);gap:12px}
}
@media(min-width:1400px){
  .hcards-grid{grid-template-columns:repeat(3,1fr)}
}

/* ── BOTTOM NAV ── */
.bottom-nav{position:fixed;left:0;right:0;bottom:0;z-index:60;background:rgba(255,255,255,.96);backdrop-filter:blur(12px);border-top:1.5px solid var(--border);box-shadow:0 -2px 12px rgba(15,23,42,.06);display:flex;justify-content:space-around;padding:8px 6px calc(8px + env(safe-area-inset-bottom))}
.bn-item{flex:1;max-width:120px;min-height:48px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:3px;padding:6px 4px;border-radius:13px;border:none;background:none;cursor:pointer;font-family:inherit;color:#94a3b8;transition:color .18s,background .18s,transform .15s var(--ease-spring)}
.bn-item .bi{font-size:19px;transition:transform .25s var(--ease-spring)}
.bn-item .bl{font-size:10.5px;font-weight:750}
.bn-item:active{transform:scale(.92)}
.bn-item.active{color:var(--teal-d);background:var(--soft)}
.bn-item.active .bi{transform:translateY(-2px) scale(1.12)}

/* Modals */
.pmodal{display:none;position:fixed;inset:0;z-index:100;background:rgba(15,23,42,0);backdrop-filter:blur(0);align-items:center;justify-content:center;padding:18px;transition:background .25s var(--ease-out),backdrop-filter .25s var(--ease-out)}
.pmodal.open{display:flex;background:rgba(15,23,42,.5);backdrop-filter:blur(5px)}
.pm-box{background:#fff;border-radius:20px;max-width:420px;width:100%;max-height:88vh;overflow:auto;box-shadow:0 30px 70px rgba(0,0,0,.35);opacity:0;transform:scale(.92) translateY(14px);animation:modalIn .32s var(--ease-spring) forwards}
@keyframes modalIn{to{opacity:1;transform:scale(1) translateY(0)}}
.pm-head{padding:17px 20px;background:linear-gradient(135deg,#134e4a,#0d9488);color:#fff;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0}
.pm-head h4{font-size:15.5px;font-weight:800}
.pm-x{background:rgba(255,255,255,.16);border:none;color:#fff;width:30px;height:30px;border-radius:9px;font-size:15px;cursor:pointer;transition:transform .15s var(--ease-spring),background .15s}
.pm-x:hover{background:rgba(255,255,255,.28);transform:rotate(90deg)}

/* Chi tiết hóa đơn: Bottom Sheet trên mobile/tablet, Right Drawer trên desktop */
.pmodal-drawer.open{align-items:flex-end;padding:0}
.pmodal-drawer .pm-drawer-box{max-width:100%;width:100%;max-height:92vh;border-radius:22px 22px 0 0;animation:sheetIn .32s var(--ease-spring) forwards}
@keyframes sheetIn{from{opacity:0;transform:translateY(100%)}to{opacity:1;transform:translateY(0)}}
@media(min-width:992px){
  .pmodal-drawer.open{align-items:stretch;justify-content:flex-end;padding:0}
  .pmodal-drawer .pm-drawer-box{max-width:440px;width:100%;height:100%;max-height:100vh;border-radius:0;animation:drawerIn .32s var(--ease-spring) forwards}
  @keyframes drawerIn{from{opacity:0;transform:translateX(100%)}to{opacity:1;transform:translateX(0)}}
}
.toast{position:fixed;top:16px;left:50%;z-index:200;padding:11px 20px;border-radius:12px;color:#fff;font-size:13px;font-weight:750;box-shadow:0 8px 24px rgba(0,0,0,.22);white-space:nowrap;
  transform:translate(-50%,-140%);opacity:0;animation:toastIn .45s var(--ease-spring) forwards}
@keyframes toastIn{to{transform:translate(-50%,0);opacity:1}}
.toast.leaving{animation:toastOut .35s var(--ease-out) forwards}
@keyframes toastOut{to{transform:translate(-50%,-120%);opacity:0}}
.toast.ok{background:#059669}.toast.err{background:#dc2626}

.empty{text-align:center;padding:34px 10px;color:#94a3b8}
.empty .ei{font-size:38px;margin-bottom:8px}
.empty p{font-size:13px}

/* ── ACCESSIBILITY BASE ── */
:focus-visible{outline:2px solid var(--teal-d);outline-offset:2px}
.sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0}

/* ── RESPONSIVE BREAKPOINTS (mobile-first; ≥768px each tier gets its own layout, not just scaling) ── */
/* Tablet 768–991: breathing room, still single column (2-col member-card+purchases would feel cramped here) */
@media(min-width:768px){
  .wrap{max-width:680px;padding:24px 24px 32px}
  .topbar{padding:14px 28px}
}
/* Desktop 992–1199: Trang chủ trở thành dashboard 2 cột — không còn dải trắng 2 bên như trên mobile */
@media(min-width:992px){
  .wrap{max-width:960px}
  #page-home.active{display:grid;grid-template-columns:360px 1fr;grid-template-areas:"card alert" "card purchases";gap:20px;align-items:start}
  #page-home .card-stage{grid-area:card;margin-bottom:0}
  #page-home .hp-alert{grid-area:alert;margin-bottom:0}
  #page-home .sec{grid-area:purchases;margin-bottom:0}
  #page-home:has(.hp-alert) .sec{grid-row:2}
  #page-home:not(:has(.hp-alert)) .sec{grid-area:1/2/3/3}
  .bottom-nav{justify-content:center;gap:8px}
  .bottom-nav .bn-item{min-width:96px;min-height:48px}
}
/* Large desktop 1200–1399: rộng hơn thẻ + gap lớn hơn */
@media(min-width:1200px){
  .wrap{max-width:1040px}
  #page-home{grid-template-columns:400px 1fr;gap:24px}
}
/* XL 1400–1919 */
@media(min-width:1400px){
  .wrap{max-width:1120px}
}
/* Ultra-wide ≥1920: chặn max-width để không kéo dài dòng chữ vô hạn, chỉ tăng khoảng lề */
@media(min-width:1920px){
  .wrap{max-width:1200px;padding-top:32px}
}
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

<h1 class="sr-only">Cổng thông tin khách hàng MediCare — Xin chào <%= dn %></h1>

<header class="topbar stg" style="--stg:0">
  <div class="tb-logo">
    <div class="tb-badge" aria-hidden="true">💊</div>
    <div>
      <div class="tb-name">Medi<span>Care</span></div>
      <div class="tb-sub">Customer Portal</div>
    </div>
  </div>
  <div class="tb-user">
    <div style="text-align:right">
      <div class="tb-uname"><%= dn %></div>
      <div class="tb-utier">Thành viên</div>
    </div>
    <div class="tb-av" aria-hidden="true"><%= initials %></div>
  </div>
</header>

<div class="wrap">

  <%-- ═══════════ TAB 1: TRANG CHỦ ═══════════ --%>
  <section class="tab-page active" id="page-home">

    <%-- Thẻ thành viên 3D (Digital Twin của thẻ NFC) --%>
    <div class="card-stage stg" style="--stg:1">
      <div class="member-card" id="memberCard" role="group" aria-label="Thẻ thành viên, mã <%= cardCode %>">
        <div class="mc-shield" aria-hidden="true">🛡️</div>
        <div class="mc-row1">
          <div>
            <div class="mc-tier-lbl">Thẻ thành viên</div>
            <div class="mc-tier">MediCare Card</div>
          </div>
          <div class="mc-id"><%= cardCode %></div>
        </div>
        <div class="mc-points-lbl">Điểm khả dụng</div>
        <div class="mc-points"><b id="mcPointsVal" data-target="<%= avail %>">0</b><span>điểm</span></div>
        <div style="height: 12px;"></div>
        <div class="mc-qr-hint">
          <button onclick="openQrModal()">📱 Mã QR thay thẻ</button>
          <span>Quên thẻ NFC? Đưa mã QR cho dược sĩ quét</span>
        </div>
      </div>
    </div>

    <%-- Cảnh báo dị ứng nếu chưa khai --%>
    <% if (me.getAllergyHistory() == null || me.getAllergyHistory().trim().isEmpty()) { %>
    <div class="hp-alert stg" style="--stg:2;background:#fffbeb;border-color:#fde68a;color:#92400e">
      💡 <b>Bạn chưa khai báo tiền sử dị ứng thuốc.</b> Hãy cập nhật trong mục
      <a href="#" onclick="switchTab('account');return false" style="color:#b45309;font-weight:800">Tài khoản</a>
      để dược sĩ tư vấn an toàn hơn khi bạn mua thuốc.
    </div>
    <% } %>

    <%-- Hóa đơn gần nhất --%>
    <div class="sec stg" style="--stg:3">
      <div class="sec-head">
        <h3><span aria-hidden="true">🧾</span> Mua hàng gần đây</h3>
        <a href="#" onclick="switchTab('history');return false" style="font-size:12px;font-weight:750;color:var(--teal-d);text-decoration:none">Xem tất cả các hóa đơn →</a>
      </div>
      <div class="sec-body" style="padding-top:6px;padding-bottom:6px">
        <c:choose>
          <c:when test="${empty invoices}">
            <div class="empty"><div class="ei">🛍️</div><p>Chưa có giao dịch nào.<br>Ghé MediCare mua sắm để tích điểm nhé!</p></div>
          </c:when>
          <c:otherwise>
            <c:forEach var="iv" items="${invoices}" varStatus="st">
              <c:if test="${st.index < 3}">
                <div class="inv-row" onclick="openInvDetail(${iv.invoiceId})">
                  <div>
                    <div class="inv-code">${iv.invoiceCode}</div>
                    <div class="inv-date">${fn:substring(iv.createdAt.toString(),0,10)} · ${fn:substring(iv.createdAt.toString(),11,16)}</div>
                  </div>
                  <div style="text-align:right">
                    <div class="inv-amt"><fmt:formatNumber value="${iv.finalAmount}" maxFractionDigits="0"/>đ</div>
                    <span class="inv-status ${iv.status=='COMPLETED'?'st-ok':'st-cancel'}">${iv.status=='COMPLETED'?'Hoàn tất':'Đã hủy'}</span>
                  </div>
                </div>
              </c:if>
            </c:forEach>
          </c:otherwise>
        </c:choose>
      </div>
    </div>
  </section>

  <%-- ═══════════ TAB 2: LỊCH SỬ (Activity Center) ═══════════ --%>
  <section class="tab-page" id="page-history">

    <c:if test="${not empty invoices}">
    <%-- Thanh thống kê nhanh --%>
    <div class="hstats" role="group" aria-label="Thống kê mua hàng tháng này">
      <div class="hstat"><div class="hstat-v"><%= monthOrders %></div><div class="hstat-l">Đơn tháng này</div></div>
      <div class="hstat"><div class="hstat-v"><fmt:formatNumber value="<%= monthSpend %>" maxFractionDigits="0"/>đ</div><div class="hstat-l">Đã chi tháng này</div></div>
      <div class="hstat"><div class="hstat-v"><fmt:formatNumber value="<%= monthAvg %>" maxFractionDigits="0"/>đ</div><div class="hstat-l">TB mỗi đơn</div></div>
      <div class="hstat"><div class="hstat-v"><fmt:formatNumber value="<%= total %>"/></div><div class="hstat-l">Tổng điểm tích lũy</div></div>
    </div>

    <%-- Thanh tìm kiếm / lọc / sắp xếp --%>
    <div class="htoolbar">
      <div class="hsearch">
        <span aria-hidden="true">🔍</span>
        <input type="search" id="hSearch" placeholder="Tìm theo mã hóa đơn…" aria-label="Tìm theo mã hóa đơn" oninput="renderHistory()">
      </div>
      <div class="hchips" role="group" aria-label="Lọc theo thời gian">
        <button type="button" class="hchip active" data-range="all"   onclick="setRange('all',this)">Tất cả</button>
        <button type="button" class="hchip"        data-range="today" onclick="setRange('today',this)">Hôm nay</button>
        <button type="button" class="hchip"        data-range="week"  onclick="setRange('week',this)">Tuần này</button>
        <button type="button" class="hchip"        data-range="month" onclick="setRange('month',this)">Tháng này</button>
        <button type="button" class="hchip"        data-range="rx"    onclick="setRange('rx',this)">💊 Đơn kê toa</button>
        <button type="button" class="hchip"        data-range="high"  onclick="setRange('high',this)">Giá trị cao (≥500K)</button>
      </div>
      <select id="hSort" class="hsort" aria-label="Sắp xếp" onchange="renderHistory()">
        <option value="newest">Mới nhất</option>
        <option value="oldest">Cũ nhất</option>
        <option value="amount_desc">Số tiền cao → thấp</option>
        <option value="amount_asc">Số tiền thấp → cao</option>
      </select>
    </div>
    </c:if>

    <%-- Dữ liệu gốc render sẵn từ server (SSR) — JS sẽ nhóm theo ngày + áp bộ lọc/sắp xếp phía dưới --%>
    <div id="historySource" hidden>
      <c:forEach var="iv" items="${invoices}">
        <div class="hcard-data"
             data-id="${iv.invoiceId}" data-code="${iv.invoiceCode}" data-ts="${iv.createdAt}"
             data-amount="${iv.finalAmount}" data-discount="${iv.discountAmount}"
             data-method="${iv.paymentMethod}" data-rx="${iv.prescriptionId != null ? 1 : 0}"
             data-points="${invoicePoints[iv.invoiceId] != null ? invoicePoints[iv.invoiceId] : 0}"></div>
      </c:forEach>
    </div>

    <div id="historyTimeline"></div>

    <c:if test="${empty invoices}">
      <div class="sec"><div class="sec-body">
        <div class="empty"><div class="ei">🧾</div><p>Chưa có hóa đơn nào.<br>Ghé MediCare mua sắm để bắt đầu hành trình chăm sóc sức khỏe của bạn!</p></div>
      </div></div>
    </c:if>

    <div class="sec">
      <div class="sec-head"><h3>⭐ Lịch sử điểm</h3></div>
      <div class="sec-body" style="padding-top:4px;padding-bottom:4px">
        <c:choose>
          <c:when test="${empty pointHistory}">
            <div class="empty"><div class="ei">⭐</div><p>Chưa có giao dịch điểm.</p></div>
          </c:when>
          <c:otherwise>
            <c:forEach var="ph" items="${pointHistory}">
              <div class="ph-row">
                <div>
                  <div style="font-weight:750">${ph[0]=='EARN'?'Tích điểm':ph[0]=='REDEEM'?'Đổi ưu đãi':ph[0]}</div>
                  <div style="font-size:11px;color:var(--muted)">${ph[3]}<c:if test="${not empty ph[2]}"> · ${ph[2]}</c:if></div>
                </div>
                <span class="${ph[0]=='EARN'?'ph-earn':'ph-redeem'}">${ph[0]=='EARN'?'+':'−'}${ph[1]} đ</span>
              </div>
            </c:forEach>
          </c:otherwise>
        </c:choose>
      </div>
    </div>
  </section>

  <%-- ═══════════ TAB 3: ƯU ĐÃI ═══════════ --%>
  <section class="tab-page" id="page-offers">
    <div class="sec">
      <div class="sec-head">
        <h3>🎁 Đổi điểm lấy ưu đãi</h3>
        <span style="font-size:12px;font-weight:800;color:var(--teal-d)" id="offerBalance"><fmt:formatNumber value="<%= avail %>"/> điểm</span>
      </div>
      <div class="sec-body">
        <div class="offer">
          <div class="offer-l">
            <div class="offer-ic">😷</div>
            <div><div class="offer-name">Hộp khẩu trang y tế</div><span class="offer-pts">100 điểm</span></div>
          </div>
          <button onclick="redeem(100,'Hộp khẩu trang y tế',this)" <%= avail < 100 ? "disabled" : "" %>>Đổi</button>
        </div>
        <div class="offer">
          <div class="offer-l">
            <div class="offer-ic">💰</div>
            <div><div class="offer-name">Giảm 30.000đ hóa đơn sau</div><span class="offer-pts">300 điểm</span></div>
          </div>
          <button onclick="redeem(300,'Giảm 30.000đ hóa đơn tiếp theo',this)" <%= avail < 300 ? "disabled" : "" %>>Đổi</button>
        </div>
        <div class="offer">
          <div class="offer-l">
            <div class="offer-ic">🩺</div>
            <div><div class="offer-name">Voucher đo huyết áp + tư vấn</div><span class="offer-pts">500 điểm</span></div>
          </div>
          <button onclick="redeem(500,'Voucher đo huyết áp + tư vấn sức khỏe',this)" <%= avail < 500 ? "disabled" : "" %>>Đổi</button>
        </div>
        <p style="font-size:11px;color:#94a3b8;margin-top:8px;line-height:1.5">Sau khi đổi, đưa màn hình xác nhận cho dược sĩ tại quầy để nhận ưu đãi.</p>
      </div>
    </div>
  </section>

  <%-- ═══════════ TAB 4: TÀI KHOẢN (hồ sơ sức khỏe) ═══════════ --%>
  <section class="tab-page" id="page-account">
    <% if (me.getAllergyHistory() != null && !me.getAllergyHistory().trim().isEmpty()) { %>
    <div class="hp-alert">🚨 <b>Dị ứng đã khai báo:</b> <%= me.getAllergyHistory() %><br>
      <span style="font-size:11px;color:#b91c1c">Dược sĩ sẽ thấy cảnh báo này khi bạn mua thuốc tại quầy.</span>
    </div>
    <% } %>
    <div class="sec">
      <div class="sec-head"><h3>🏥 Hồ sơ sức khỏe cá nhân</h3></div>
      <div class="sec-body">
        <form method="post" action="${pageContext.request.contextPath}/portal">
          <input type="hidden" name="_csrf" value="${csrfToken}">
          <input type="hidden" name="action" value="update-profile">
          <div class="fld"><label>Họ tên</label>
            <input type="text" value="<%= dn %>" disabled style="background:#f8fafc;color:#94a3b8"></div>
          <div class="fld"><label>Số điện thoại</label>
            <input type="text" value="<%= me.getPhone() != null ? me.getPhone() : "" %>" disabled style="background:#f8fafc;color:#94a3b8"></div>
          <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">
            <div class="fld"><label>Ngày sinh</label>
              <input type="date" name="dob" value="<%= me.getDateOfBirth() != null ? me.getDateOfBirth().toString() : "" %>"></div>
            <div class="fld"><label>Giới tính</label>
              <select name="gender">
                <option value="">— Chọn —</option>
                <option value="M" <%= "M".equals(me.getGender()) ? "selected" : "" %>>Nam</option>
                <option value="F" <%= "F".equals(me.getGender()) ? "selected" : "" %>>Nữ</option>
              </select></div>
          </div>
          <div class="fld"><label>Email</label>
            <input type="email" name="email" placeholder="ban@email.com" value="<%= me.getEmail() != null ? me.getEmail() : "" %>"></div>
          <div class="fld"><label>Địa chỉ</label>
            <input type="text" name="address" placeholder="Số nhà, đường, quận…" value="<%= me.getAddress() != null ? me.getAddress() : "" %>"></div>
          <div class="fld"><label>🚨 Tiền sử dị ứng thuốc (rất quan trọng)</label>
            <textarea name="allergy" placeholder="VD: Dị ứng Penicillin, Paracetamol…"><%= me.getAllergyHistory() != null ? me.getAllergyHistory() : "" %></textarea></div>
          <div class="fld"><label>Bệnh lý nền</label>
            <textarea name="chronic" placeholder="VD: Tiểu đường, huyết áp cao…"><%= me.getChronicDisease() != null ? me.getChronicDisease() : "" %></textarea></div>
          <button type="submit" class="btn-save">💾 Lưu hồ sơ</button>
        </form>
        <form method="post" action="${pageContext.request.contextPath}/portal">
          <input type="hidden" name="_csrf" value="${csrfToken}">
          <input type="hidden" name="action" value="logout">
          <button type="submit" class="btn-logout">⏻ Đăng xuất</button>
        </form>
      </div>
    </div>
  </section>

  <%-- ═══════════ TAB 5: ĐƠN THUỐC ═══════════ --%>
  <section class="tab-page" id="page-prescriptions">
    <div class="sec">
      <div class="sec-head">
        <h3>📋 Danh sách đơn thuốc kê toa</h3>
        <span style="font-size:12px;font-weight:800;color:var(--teal-d)">${prescriptions.size()} đơn</span>
      </div>
      <div class="sec-body" style="padding-top:6px;padding-bottom:6px">
        <c:choose>
          <c:when test="${empty prescriptions}">
            <div class="empty">
              <div class="ei">📋</div>
              <p>Bạn chưa có đơn thuốc nào được ghi nhận.<br>Khi mua thuốc kê đơn tại quầy, dược sĩ sẽ cập nhật đơn vào tài khoản của bạn.</p>
            </div>
          </c:when>
          <c:otherwise>
            <c:forEach var="p" items="${prescriptions}">
              <div class="offer" style="cursor:pointer;flex-direction:column;align-items:stretch" onclick="openPrescDetail(${p.prescriptionId})">
                <div style="display:flex;justify-content:space-between;align-items:start">
                  <div style="display:flex;gap:11px;align-items:center">
                    <div class="offer-ic" style="background:linear-gradient(135deg,#3b82f6,#1d4ed8)">📋</div>
                    <div>
                      <div class="offer-name" style="font-size:14px">Đơn thuốc BS. ${p.doctorName != null ? p.doctorName : 'Chưa rõ'}</div>
                      <div style="font-size:11px;color:var(--muted);margin-top:2px">${p.hospitalName != null ? p.hospitalName : 'MediCare'}</div>
                    </div>
                  </div>
                  <span class="inv-status" style="background:#eff6ff;color:#1d4ed8;margin-top:0">${p.prescriptionDate}</span>
                </div>
                <c:if test="${not empty p.notes}">
                  <div style="font-size:11.5px;color:var(--muted);margin-top:8px;border-top:1px dashed var(--border);padding-top:8px">
                    <b>Dặn dò:</b> ${p.notes}
                  </div>
                </c:if>
              </div>
            </c:forEach>
          </c:otherwise>
        </c:choose>
      </div>
    </div>
  </section>
</div>

<%-- ═══════════ BOTTOM NAV ═══════════ --%>
<nav class="bottom-nav" aria-label="Điều hướng chính">
  <button class="bn-item active" data-tab="home"    onclick="switchTab('home')" aria-current="page"><span class="bi" aria-hidden="true">🏠</span><span class="bl">Trang chủ</span></button>
  <button class="bn-item" data-tab="history" onclick="switchTab('history')"><span class="bi" aria-hidden="true">🧾</span><span class="bl">Lịch sử</span></button>
  <button class="bn-item" data-tab="prescriptions" onclick="switchTab('prescriptions')"><span class="bi" aria-hidden="true">📋</span><span class="bl">Đơn thuốc</span></button>
  <button class="bn-item" data-tab="offers"  onclick="switchTab('offers')"><span class="bi" aria-hidden="true">🎁</span><span class="bl">Ưu đãi</span></button>
  <button class="bn-item" data-tab="account" onclick="switchTab('account')"><span class="bi" aria-hidden="true">👤</span><span class="bl">Tài khoản</span></button>
</nav>

<%-- Modal QR (dùng chung cho QR thay thẻ NFC và QR hóa đơn) --%>
<div class="pmodal" id="qrModal" style="z-index:110" onclick="if(event.target===this)this.classList.remove('open')">
  <div class="pm-box" style="max-width:320px;text-align:center">
    <div class="pm-head"><h4 id="qrModalTitle">📱 Mã thay thẻ NFC</h4><button class="pm-x" aria-label="Đóng" onclick="document.getElementById('qrModal').classList.remove('open')">✕</button></div>
    <div style="padding:24px">
      <div id="qrBox" style="display:flex;justify-content:center;padding:10px;background:#fff"></div>
      <div id="qrCodeLabel" style="font-size:15px;font-weight:800;letter-spacing:2px;margin-top:10px"><%= cardCode %></div>
      <p id="qrCodeHint" style="font-size:12px;color:#64748b;margin-top:8px;line-height:1.5">Đưa mã này cho dược sĩ quét khi bạn quên mang thẻ NFC.</p>
    </div>
  </div>
</div>

<%-- Chi tiết hóa đơn — Bottom Sheet (mobile/tablet) / Right Drawer (desktop ≥992px) --%>
<div class="pmodal pmodal-drawer" id="invModal" onclick="if(event.target===this)closeInvModal()">
  <div class="pm-box pm-drawer-box" role="dialog" aria-modal="true" aria-labelledby="invModalTitle">
    <div class="pm-head"><h4 id="invModalTitle">🧾 Chi tiết hóa đơn</h4><button class="pm-x" aria-label="Đóng chi tiết hóa đơn" onclick="closeInvModal()">✕</button></div>
    <div id="invDetailBody" style="padding:18px 20px">Đang tải…</div>
  </div>
</div>

<%-- Chi tiết đơn thuốc — Bottom Sheet (mobile/tablet) / Right Drawer (desktop ≥992px) --%>
<div class="pmodal pmodal-drawer" id="prescModal" onclick="if(event.target===this)closePrescModal()">
  <div class="pm-box pm-drawer-box" role="dialog" aria-modal="true" aria-labelledby="prescModalTitle">
    <div class="pm-head"><h4 id="prescModalTitle">📋 Chi tiết đơn thuốc</h4><button class="pm-x" aria-label="Đóng chi tiết đơn thuốc" onclick="closePrescModal()">✕</button></div>
    <div id="prescDetailBody" style="padding:18px 20px">Đang tải…</div>
  </div>
</div>

<script>
function toggleCdd(id){var w=document.getElementById(id),m=w.querySelector('.cdd-menu'),b=w.querySelector('.cdd-btn');var open=m.classList.contains('show');document.querySelectorAll('.cdd-menu.show').forEach(function(x){x.classList.remove('show');x.closest('.cdd').querySelector('.cdd-btn').classList.remove('open')});if(!open){m.classList.add('show');b.classList.add('open');var act=m.querySelector('.cdd-opt.active');if(act)act.scrollIntoView({block:'nearest'})}}
function pickCdd(wId,hId,el,autoSubmit){document.getElementById(hId).value=el.dataset.val;var w=document.getElementById(wId);w.querySelector('.cdd-label').textContent=el.textContent;w.querySelectorAll('.cdd-opt').forEach(function(o){o.classList.remove('active')});el.classList.add('active');w.querySelector('.cdd-menu').classList.remove('show');w.querySelector('.cdd-btn').classList.remove('open');if(autoSubmit){var f=w.closest('form');if(f)f.submit()}}
document.addEventListener('click',function(e){if(!e.target.closest('.cdd')){document.querySelectorAll('.cdd-menu.show').forEach(function(m){m.classList.remove('show');m.closest('.cdd').querySelector('.cdd-btn').classList.remove('open')})}});

const CTX = '${pageContext.request.contextPath}';

/* ── Tab switching (bottom nav) ── */
function switchTab(tab) {
  document.querySelectorAll('.tab-page').forEach(p => p.classList.remove('active'));
  document.getElementById('page-' + tab).classList.add('active');
  document.querySelectorAll('.bn-item').forEach(b => {
    const isActive = b.dataset.tab === tab;
    b.classList.toggle('active', isActive);
    if (isActive) b.setAttribute('aria-current', 'page'); else b.removeAttribute('aria-current');
  });
  window.scrollTo({ top: 0, behavior: 'smooth' });
}
if (location.hash === '#account') switchTab('account');

/* ══════════════ LỊCH SỬ MUA HÀNG — Activity Center (nhóm theo ngày + lọc/sắp xếp) ══════════════ */
const PAY_LABEL = { CASH:'💵 Tiền mặt', QR_CODE:'📱 QR', CARD:'💳 Thẻ', TRANSFER:'🏦 Chuyển khoản', EWALLET:'👛 Ví điện tử' };
let hRange = 'all';

function setRange(range, btn) {
  hRange = range;
  document.querySelectorAll('.hchip').forEach(c => c.classList.toggle('active', c === btn));
  renderHistory();
}

function startOfWeek(d) {
  const x = new Date(d); const day = (x.getDay() + 6) % 7; // Thứ 2 = đầu tuần
  x.setHours(0,0,0,0); x.setDate(x.getDate() - day);
  return x;
}
function sameDay(a, b) { return a.getFullYear()===b.getFullYear() && a.getMonth()===b.getMonth() && a.getDate()===b.getDate(); }

function bucketFor(d, now, weekStart) {
  if (sameDay(d, now)) return 'Hôm nay';
  const y = new Date(now); y.setDate(y.getDate()-1);
  if (sameDay(d, y)) return 'Hôm qua';
  if (d >= weekStart) return 'Tuần này';
  if (d.getFullYear()===now.getFullYear() && d.getMonth()===now.getMonth()) return 'Tháng này';
  const months = ['1','2','3','4','5','6','7','8','9','10','11','12'];
  return 'Tháng ' + months[d.getMonth()] + '/' + d.getFullYear();
}

function renderHistory() {
  const src = document.querySelectorAll('#historySource .hcard-data');
  const timeline = document.getElementById('historyTimeline');
  if (!src.length) { timeline.innerHTML = ''; return; }

  const now = new Date();
  const weekStart = startOfWeek(now);
  const q = (document.getElementById('hSearch')?.value || '').trim().toLowerCase();
  const sort = document.getElementById('hSort')?.value || 'newest';

  let rows = Array.from(src).map(el => ({
    id: el.dataset.id, code: el.dataset.code, ts: new Date(el.dataset.ts),
    amount: parseFloat(el.dataset.amount) || 0, discount: parseFloat(el.dataset.discount) || 0,
    method: el.dataset.method, rx: el.dataset.rx === '1', points: parseInt(el.dataset.points) || 0
  }));

  if (q) rows = rows.filter(r => r.code.toLowerCase().includes(q));
  if (hRange === 'today') rows = rows.filter(r => sameDay(r.ts, now));
  else if (hRange === 'week') rows = rows.filter(r => r.ts >= weekStart);
  else if (hRange === 'month') rows = rows.filter(r => r.ts.getFullYear()===now.getFullYear() && r.ts.getMonth()===now.getMonth());
  else if (hRange === 'rx') rows = rows.filter(r => r.rx);
  else if (hRange === 'high') rows = rows.filter(r => r.amount >= 500000);

  if (sort === 'oldest') rows.sort((a,b) => a.ts - b.ts);
  else if (sort === 'amount_desc') rows.sort((a,b) => b.amount - a.amount);
  else if (sort === 'amount_asc') rows.sort((a,b) => a.amount - b.amount);
  else rows.sort((a,b) => b.ts - a.ts); // newest

  if (!rows.length) {
    timeline.innerHTML = '<div class="sec"><div class="sec-body"><div class="empty"><div class="ei">🔍</div><p>Không tìm thấy hóa đơn phù hợp bộ lọc.</p></div></div></div>';
    return;
  }

  const fmtV = n => new Intl.NumberFormat('vi-VN').format(n) + 'đ';
  const groups = [];
  let curGroup = null;
  for (const r of rows) {
    const b = sort === 'newest' || sort === 'oldest' ? bucketFor(r.ts, now, weekStart) : null;
    if (!curGroup || b !== curGroup.label) { curGroup = { label: b, rows: [] }; groups.push(curGroup); }
    curGroup.rows.push(r);
  }

  timeline.innerHTML = groups.map(g => {
    const count = g.rows.length;
    const total = g.rows.reduce((s,r) => s + r.amount, 0);
    const cards = g.rows.map(r => {
      const timeStr = r.ts.toLocaleDateString('vi-VN') + ' · ' + r.ts.toLocaleTimeString('vi-VN', {hour:'2-digit',minute:'2-digit'});
      return '<div class="hcard" tabindex="0" role="button" '
        + 'aria-label="Hóa đơn ' + r.code + ', ' + fmtV(r.amount) + ', ' + timeStr + '" '
        + 'onclick="openInvDetail(' + r.id + ')" onkeydown="if(event.key===\'Enter\'||event.key===\' \'){event.preventDefault();openInvDetail(' + r.id + ')}">'
        + '<div class="hcard-top"><div><div class="hcard-code">' + r.code + '</div><div class="hcard-time">' + timeStr + '</div></div>'
        + '<span class="hbadge hbadge-ok">✓ Hoàn tất</span></div>'
        + '<div class="hcard-tags">'
        + (r.rx ? '<span class="htag htag-rx">💊 Đơn thuốc kê toa</span>' : '')
        + '<span class="htag">' + (PAY_LABEL[r.method] || r.method) + '</span>'
        + (r.discount > 0 ? '<span class="htag htag-discount">🏷 -' + fmtV(r.discount) + '</span>' : '')
        + '</div>'
        + '<div class="hcard-bottom"><div class="hcard-amt">' + fmtV(r.amount) + '</div>'
        + (r.points > 0 ? '<div class="hcard-pts">+' + r.points + ' điểm</div>' : '')
        + '</div></div>';
    }).join('');
    const head = g.label ? ('<div class="hgroup-head"><span class="hgroup-title">' + g.label + '</span>'
      + '<span class="hgroup-meta">' + count + ' đơn · ' + fmtV(total) + '</span></div>') : '';
    return '<div class="hgroup">' + head + '<div class="hcards-grid">' + cards + '</div></div>';
  }).join('');
}
renderHistory();

/* ── Count-up điểm + animate progress bar khi trang vừa tải xong ── */
(function () {
  var reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var elVal = document.getElementById('mcPointsVal');
  var target = parseInt(elVal.dataset.target, 10) || 0;
  if (reduce) {
    elVal.textContent = target.toLocaleString('vi-VN');
  } else {
    var start = null, dur = 1100;
    function step(ts) {
      if (!start) start = ts;
      var p = Math.min(1, (ts - start) / dur);
      var eased = 1 - Math.pow(1 - p, 3); // ease-out cubic
      elVal.textContent = Math.round(target * eased).toLocaleString('vi-VN');
      if (p < 1) requestAnimationFrame(step);
    }
    setTimeout(function () { requestAnimationFrame(step); }, 350);
  }

})();

/* ── 3D tilt thẻ thành viên (chuột + cảm biến gyro trên mobile) ── */
(function(){
  const card = document.getElementById('memberCard');
  const MAX = 10;
  const reduce = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (reduce) return;
  card.addEventListener('mousemove', e => {
    const r = card.getBoundingClientRect();
    const px = (e.clientX - r.left) / r.width, py = (e.clientY - r.top) / r.height;
    card.classList.add('tilting');
    card.style.transform = 'rotateX(' + ((0.5-py)*MAX*2).toFixed(2) + 'deg) rotateY(' + ((px-0.5)*MAX*2).toFixed(2) + 'deg)';
    card.style.setProperty('--mx', (px*100)+'%'); card.style.setProperty('--my', (py*100)+'%');
  });
  card.addEventListener('mouseleave', () => { card.style.transform=''; card.classList.remove('tilting'); });
  // Mobile: nghiêng theo gyro
  if (window.DeviceOrientationEvent) {
    window.addEventListener('deviceorientation', e => {
      if (e.beta === null) return;
      const rx = Math.max(-MAX, Math.min(MAX, (e.beta - 45) / 4));
      const ry = Math.max(-MAX, Math.min(MAX, e.gamma / 4));
      card.style.transform = 'rotateX(' + (-rx).toFixed(1) + 'deg) rotateY(' + ry.toFixed(1) + 'deg)';
    }, true);
  }
})();

/* ── QR code (thẻ NFC hoặc hóa đơn — dùng chung 1 khung QR) ── */
function renderQrBox(text) {
  const box = document.getElementById('qrBox');
  box.innerHTML = '';
  if (typeof QRCode !== 'undefined') {
    new QRCode(box, { text: text, width: 190, height: 190, correctLevel: QRCode.CorrectLevel.M });
  }
}
function openQrModal() {
  document.getElementById('qrModal').classList.add('open');
  document.getElementById('qrModalTitle').textContent = '📱 Mã thay thẻ NFC';
  document.getElementById('qrCodeLabel').textContent = '<%= cardCode %>';
  document.getElementById('qrCodeHint').textContent = 'Đưa mã này cho dược sĩ quét khi bạn quên mang thẻ NFC.';
  renderQrBox('MEDICARE|<%= cardCode %>|<%= me.getPhone() != null ? me.getPhone() : "" %>');
}

/* ── Toast ── */
function toast(msg, type) {
  const t = document.createElement('div');
  t.className = 'toast ' + (type || 'ok');
  t.textContent = msg;
  document.body.appendChild(t);
  setTimeout(() => { t.classList.add('leaving'); setTimeout(() => t.remove(), 350); }, 2800);
}
<% if ("profile-saved".equals(request.getParameter("msg"))) { %>toast('✅ Đã lưu hồ sơ sức khỏe!');<% } %>

/* ── Đổi điểm ── */
async function redeem(points, label, btn) {
  if (!confirm('Đổi ' + points + ' điểm lấy "' + label + '"?')) return;
  btn.disabled = true; btn.textContent = '…';
  try {
    const res = await fetch(CTX + '/portal', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ action: 'redeem', points: points, label: label })
    });
    const d = await res.json();
    if (d.ok) {
      toast('🎉 Đổi thành công! Còn ' + d.remaining + ' điểm');
      setTimeout(() => location.reload(), 1200);
    } else {
      toast(d.reason === 'not_enough_points' ? '⚠️ Không đủ điểm!' : '❌ Lỗi: ' + d.reason, 'err');
      btn.disabled = false; btn.textContent = 'Đổi';
    }
  } catch (e) { toast('❌ Lỗi kết nối', 'err'); btn.disabled = false; btn.textContent = 'Đổi'; }
}

/* ── Chi tiết hóa đơn (Order Journey drawer) ── */
let invModalLastFocus = null;
function closeInvModal() {
  document.getElementById('invModal').classList.remove('open');
  if (invModalLastFocus) { invModalLastFocus.focus(); invModalLastFocus = null; }
}

async function openInvDetail(id) {
  invModalLastFocus = document.activeElement;
  const modal = document.getElementById('invModal');
  const body  = document.getElementById('invDetailBody');
  modal.classList.add('open');
  document.getElementById('invModal').querySelector('.pm-x').focus();
  body.innerHTML =
      '<div class="skel" style="height:16px;width:55%;margin-bottom:8px"></div>'
    + '<div class="skel" style="height:12px;width:35%;margin-bottom:18px"></div>'
    + '<div class="skel" style="height:52px;border-radius:11px;margin-bottom:7px"></div>'
    + '<div class="skel" style="height:52px;border-radius:11px;margin-bottom:7px"></div>'
    + '<div class="skel" style="height:52px;border-radius:11px"></div>';
  try {
    const res = await fetch(CTX + '/portal?action=invoice-detail&id=' + id);
    const d = await res.json();
    if (!d.ok) { body.innerHTML = '<div style="color:#dc2626;text-align:center;padding:16px 0">Không tải được chi tiết.</div>'; return; }
    const fmtV = n => new Intl.NumberFormat('vi-VN').format(n) + 'đ';
    const today = new Date(); today.setHours(0,0,0,0);

    const tags = ''
      + (d.prescription ? '<span class="htag htag-rx">💊 Đơn thuốc kê toa</span>' : '')
      + '<span class="htag">' + (PAY_LABEL[d.method] || d.method) + '</span>'
      + (d.station ? '<span class="htag">🏬 Quầy ' + d.station + '</span>' : '')
      + (d.points > 0 ? '<span class="htag" style="background:#ecfdf5;color:#047857">⭐ +' + d.points + ' điểm</span>' : '');

    const itemsHtml = d.items.map(it => {
      let expTag = '';
      if (it.expiry) {
        const exp = new Date(it.expiry);
        const daysLeft = Math.round((exp - today) / 86400000);
        if (daysLeft < 0) expTag = '<span class="htag htag-discount" style="background:#fef2f2;color:#b91c1c">⚠ Đã hết hạn ' + it.expiry + '</span>';
        else if (daysLeft <= 90) expTag = '<span class="htag" style="background:#fff7ed;color:#c2410c">⏳ Cận hạn: ' + it.expiry + '</span>';
        else expTag = '<span class="htag">HSD: ' + it.expiry + '</span>';
      }
      return '<div style="background:#f8fafc;border-radius:11px;padding:10px 12px;margin-bottom:7px">'
        + '<div style="display:flex;justify-content:space-between;align-items:center">'
        + '<div><div style="font-weight:750;font-size:13px">' + it.name + '</div>'
        + '<div style="font-size:11px;color:#94a3b8">SL: ' + it.qty + ' ' + it.unit + ' × ' + fmtV(it.price)
        + (it.batch ? ' · Lô ' + it.batch : '') + '</div></div>'
        + '<b style="font-size:12.5px">' + fmtV(it.subtotal) + '</b></div>'
        + (expTag ? '<div style="margin-top:6px">' + expTag + '</div>' : '')
        + '</div>';
    }).join('');

    body.innerHTML =
      '<div style="border-bottom:1px solid #f1f5f9;padding-bottom:12px;margin-bottom:12px">'
      + '<b style="font-size:15px">' + d.code + '</b><div style="color:#94a3b8;font-size:11.5px;margin-top:2px">' + d.time + '</div>'
      + '<div class="hcard-tags" style="margin-top:10px">' + tags + '</div></div>'
      + '<div style="font-size:11px;font-weight:800;color:#94a3b8;letter-spacing:.5px;margin-bottom:8px">DANH MỤC THUỐC ĐÃ MUA</div>'
      + itemsHtml
      + (d.discount > 0 ? '<div style="display:flex;justify-content:space-between;font-size:12.5px;color:#94a3b8;margin-top:10px"><span>Giảm giá</span><span>-' + fmtV(d.discount) + '</span></div>' : '')
      + '<div style="display:flex;justify-content:space-between;align-items:center;background:#f0fdfa;border:1px solid #99f6e4;border-radius:13px;padding:12px 14px;margin-top:12px">'
      + '<span style="font-size:12px;font-weight:750;color:#0f766e">Tổng thanh toán</span>'
      + '<b style="font-size:18px">' + fmtV(d.total) + '</b></div>'
      + (d.prescriptionId ? '<button type="button" class="btn-save" style="margin-top:14px;background:linear-gradient(135deg,#3b82f6,#1d4ed8)" onclick="openPrescDetail(' + d.prescriptionId + ')">💊 Xem chi tiết đơn thuốc kê toa</button>' : '')
      + '<button type="button" class="btn-save" style="margin-top:10px;background:linear-gradient(135deg,#134e4a,#0d9488)" onclick="openInvQr(\'' + d.code + '\')">📱 Xem mã QR hóa đơn</button>';
  } catch (e) {
    body.innerHTML = '<div style="color:#dc2626;text-align:center;padding:16px 0">Lỗi kết nối.</div>';
  }
}

function openInvQr(code) {
  document.getElementById('qrModal').classList.add('open');
  document.getElementById('qrModalTitle').textContent = '🧾 Mã QR hóa đơn';
  document.getElementById('qrCodeLabel').textContent = code;
  document.getElementById('qrCodeHint').textContent = 'Đưa mã này cho dược sĩ quét để tra cứu hóa đơn.';
  renderQrBox('MEDICARE|INVOICE|' + code);
}

let prescModalLastFocus = null;
function closePrescModal() {
  document.getElementById('prescModal').classList.remove('open');
  if (prescModalLastFocus) { prescModalLastFocus.focus(); prescModalLastFocus = null; }
}

async function openPrescDetail(id) {
  prescModalLastFocus = document.activeElement;
  const modal = document.getElementById('prescModal');
  const body  = document.getElementById('prescDetailBody');
  modal.classList.add('open');
  modal.querySelector('.pm-x').focus();
  body.innerHTML =
      '<div class="skel" style="height:16px;width:55%;margin-bottom:8px"></div>'
    + '<div class="skel" style="height:12px;width:35%;margin-bottom:18px"></div>'
    + '<div class="skel" style="height:52px;border-radius:11px;margin-bottom:7px"></div>'
    + '<div class="skel" style="height:52px;border-radius:11px;margin-bottom:7px"></div>'
    + '<div class="skel" style="height:52px;border-radius:11px"></div>';
  try {
    const res = await fetch(CTX + '/portal?action=prescription-detail&id=' + id);
    const d = await res.json();
    if (!d.ok) { body.innerHTML = '<div style="color:#dc2626;text-align:center;padding:16px 0">Không tải được chi tiết đơn thuốc.</div>'; return; }
    
    let itemsHtml = d.items.map(it => {
      return '<div style="background:#f8fafc;border-radius:11px;padding:10px 12px;margin-bottom:7px">'
        + '<div style="display:flex;justify-content:space-between;align-items:start">'
        + '<div>'
        + '<div style="font-weight:750;font-size:13px;color:var(--teal-d)">' + it.name + '</div>'
        + '<div style="font-size:11px;color:#64748b;margin-top:3px">'
        + 'Liều dùng: ' + it.dosageQty + ' ' + it.dosageUnit + ' · ' + it.frequency
        + (it.duration ? ' · Dùng trong ' + it.duration + ' ngày' : '')
        + '</div>'
        + (it.instruction ? '<div style="font-size:11px;color:#0f766e;margin-top:3px;font-style:italic">👉 ' + it.instruction + '</div>' : '')
        + '</div>'
        + '<span style="font-size:12px;font-weight:800;color:var(--ink)">SL: ' + it.totalQty + ' ' + it.unit + '</span>'
        + '</div>'
        + '</div>';
    }).join('');

    if (!itemsHtml) {
      itemsHtml = '<div class="empty"><p>Không có chi tiết thuốc trong đơn này.</p></div>';
    }

    let imgHtml = '';
    if (d.imagePath) {
      imgHtml = '<div style="margin-top:14px;border-top:1px solid #f1f5f9;padding-top:12px">'
        + '<div style="font-size:11px;font-weight:800;color:#94a3b8;letter-spacing:.5px;margin-bottom:8px">HÌNH ẢNH ĐƠN THUỐC</div>'
        + '<a href="' + CTX + d.imagePath + '" target="_blank" title="Xem ảnh kích thước đầy đủ">'
        + '<img src="' + CTX + d.imagePath + '" style="width:100%;border-radius:11px;border:1px solid var(--border);box-shadow:0 2px 8px rgba(0,0,0,.05)" alt="Ảnh đơn thuốc"/>'
        + '</a>'
        + '</div>';
    }

    body.innerHTML =
      '<div style="border-bottom:1px solid #f1f5f9;padding-bottom:12px;margin-bottom:12px">'
      + '<b style="font-size:15px">BS. ' + (d.doctor || 'Chưa rõ') + '</b>'
      + '<div style="color:#94a3b8;font-size:11.5px;margin-top:2px">Nơi kê: ' + (d.hospital || 'MediCare') + ' · Ngày: ' + d.date + '</div>'
      + (d.notes ? '<div style="background:#eff6ff;color:#1d4ed8;font-size:11.5px;padding:8px 12px;border-radius:8px;margin-top:8px"><b>Dặn dò:</b> ' + d.notes + '</div>' : '')
      + '</div>'
      + '<div style="font-size:11px;font-weight:800;color:#94a3b8;letter-spacing:.5px;margin-bottom:8px">CHỈ DẪN DÙNG THUỐC</div>'
      + itemsHtml
      + imgHtml;
  } catch (e) {
    body.innerHTML = '<div style="color:#dc2626;text-align:center;padding:16px 0">Lỗi kết nối.</div>';
  }
}

document.addEventListener('keydown', e => {
  if (e.key === 'Escape') {
    if (document.getElementById('invModal').classList.contains('open')) closeInvModal();
    if (document.getElementById('prescModal').classList.contains('open')) closePrescModal();
  }
});
</script>
</body>
</html>
