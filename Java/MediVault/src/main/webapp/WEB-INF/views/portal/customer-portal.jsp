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
    String tier = card != null && card.getTierName() != null ? card.getTierName() : "Đồng";
    String nextTier   = card != null ? card.getNextTierName() : null;
    int nextMin       = card != null ? card.getNextTierMinPoints() : 0;
    int toNext        = nextTier != null ? Math.max(0, nextMin - total) : 0;
    int progressPct   = (nextTier != null && nextMin > 0) ? Math.min(100, total * 100 / nextMin) : 100;
    String cardCode   = card != null && card.getCardCode() != null ? card.getCardCode() : "CARD—";
    String tierIcon   = tier.contains("Kim") ? "💎" : tier.contains("Vàng") ? "👑" : tier.contains("Bạc") ? "🥈" : "🥉";
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
:root{--teal:#0d9488;--teal-d:#0f766e;--ink:#0f172a;--muted:#64748b;--border:#e2e8f0;--soft:#f0fdfa}
html,body{min-height:100%;font-family:'Plus Jakarta Sans',sans-serif}
body{background:#f8fafc;color:var(--ink);padding-bottom:76px}

/* ── TOPBAR ── */
.topbar{position:sticky;top:0;z-index:50;background:rgba(255,255,255,.94);backdrop-filter:blur(10px);border-bottom:1px solid var(--border);padding:12px 18px;display:flex;align-items:center;justify-content:space-between}
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
.mc-fill{height:100%;border-radius:20px;background:linear-gradient(90deg,#fff,#ccfbf1);transition:width 1s ease}
.mc-qr-hint{margin-top:14px;display:flex;align-items:center;gap:8px;font-size:11px;color:rgba(255,255,255,.6);transform:translateZ(15px)}
.mc-qr-hint button{background:rgba(255,255,255,.14);border:1px solid rgba(255,255,255,.16);color:#fff;padding:7px 14px;border-radius:10px;font-size:12px;font-weight:750;cursor:pointer;font-family:inherit}

/* ── SECTION CARD ── */
.sec{background:#fff;border:1.5px solid var(--border);border-radius:18px;margin-bottom:16px;overflow:hidden;box-shadow:0 1px 2px rgba(15,23,42,.04),0 10px 24px -18px rgba(15,23,42,.25)}
.sec-head{padding:15px 18px;border-bottom:1.5px solid #f1f5f9;display:flex;align-items:center;justify-content:space-between}
.sec-head h3{font-size:14.5px;font-weight:800}
.sec-body{padding:14px 18px}

/* Offer */
.offer{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:12px;border:1.5px solid var(--border);border-radius:14px;margin-bottom:10px;transition:border .15s,transform .15s}
.offer:hover{border-color:#5eead4;transform:translateY(-1px)}
.offer-l{display:flex;gap:11px;align-items:center;min-width:0}
.offer-ic{width:42px;height:42px;border-radius:12px;background:linear-gradient(135deg,var(--teal),#14b8a6);color:#fff;display:flex;align-items:center;justify-content:center;font-size:17px;flex-shrink:0;box-shadow:0 6px 12px -5px rgba(13,148,136,.5)}
.offer-name{font-size:13.5px;font-weight:800}
.offer-pts{font-size:11px;font-weight:800;color:var(--teal-d);background:var(--soft);border:1px solid #99f6e4;padding:2px 9px;border-radius:8px;display:inline-block;margin-top:3px}
.offer button{background:var(--teal);color:#fff;border:none;padding:9px 16px;border-radius:10px;font-size:12.5px;font-weight:800;cursor:pointer;font-family:inherit;flex-shrink:0}
.offer button:disabled{background:#cbd5e1;cursor:not-allowed}

/* Invoice row */
.inv-row{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:13px 2px;border-bottom:1px solid #f1f5f9;cursor:pointer}
.inv-row:last-child{border-bottom:none}
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

/* ── BOTTOM NAV ── */
.bottom-nav{position:fixed;left:0;right:0;bottom:0;z-index:60;background:rgba(255,255,255,.96);backdrop-filter:blur(12px);border-top:1.5px solid var(--border);display:flex;justify-content:space-around;padding:8px 6px calc(8px + env(safe-area-inset-bottom))}
.bn-item{flex:1;max-width:120px;display:flex;flex-direction:column;align-items:center;gap:3px;padding:6px 4px;border-radius:13px;border:none;background:none;cursor:pointer;font-family:inherit;color:#94a3b8;transition:all .18s}
.bn-item .bi{font-size:19px;transition:transform .18s}
.bn-item .bl{font-size:10.5px;font-weight:750}
.bn-item.active{color:var(--teal-d);background:var(--soft)}
.bn-item.active .bi{transform:translateY(-2px) scale(1.12)}

/* Modals */
.pmodal{display:none;position:fixed;inset:0;z-index:100;background:rgba(15,23,42,.5);backdrop-filter:blur(5px);align-items:center;justify-content:center;padding:18px}
.pmodal.open{display:flex}
.pm-box{background:#fff;border-radius:20px;max-width:420px;width:100%;max-height:88vh;overflow:auto;box-shadow:0 30px 70px rgba(0,0,0,.35);animation:fadeUp .25s ease}
.pm-head{padding:17px 20px;background:linear-gradient(135deg,#134e4a,#0d9488);color:#fff;display:flex;align-items:center;justify-content:space-between;position:sticky;top:0}
.pm-head h4{font-size:15.5px;font-weight:800}
.pm-x{background:rgba(255,255,255,.16);border:none;color:#fff;width:30px;height:30px;border-radius:9px;font-size:15px;cursor:pointer}
.toast{position:fixed;top:16px;left:50%;transform:translateX(-50%);z-index:200;padding:11px 20px;border-radius:12px;color:#fff;font-size:13px;font-weight:750;box-shadow:0 8px 24px rgba(0,0,0,.22);animation:fadeUp .3s ease;white-space:nowrap}
.toast.ok{background:#059669}.toast.err{background:#dc2626}

.empty{text-align:center;padding:34px 10px;color:#94a3b8}
.empty .ei{font-size:38px;margin-bottom:8px}
.empty p{font-size:13px}
@media(min-width:561px){.wrap{padding-top:24px}}
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

<header class="topbar">
  <div class="tb-logo">
    <div class="tb-badge">💊</div>
    <div>
      <div class="tb-name">Medi<span>Care</span></div>
      <div class="tb-sub">Customer Portal</div>
    </div>
  </div>
  <div class="tb-user">
    <div style="text-align:right">
      <div class="tb-uname"><%= dn %></div>
      <div class="tb-utier"><%= tierIcon %> Thành viên <%= tier %></div>
    </div>
    <div class="tb-av"><%= initials %></div>
  </div>
</header>

<div class="wrap">

  <%-- ═══════════ TAB 1: TRANG CHỦ ═══════════ --%>
  <section class="tab-page active" id="page-home">

    <%-- Thẻ thành viên 3D (Digital Twin của thẻ NFC) --%>
    <div class="card-stage">
      <div class="member-card" id="memberCard">
        <div class="mc-shield">🛡️</div>
        <div class="mc-row1">
          <div>
            <div class="mc-tier-lbl">Hạng thành viên</div>
            <div class="mc-tier"><%= tierIcon %> Hạng <%= tier %></div>
          </div>
          <div class="mc-id"><%= cardCode %></div>
        </div>
        <div class="mc-points-lbl">Điểm khả dụng</div>
        <div class="mc-points"><b><fmt:formatNumber value="<%= avail %>"/></b><span>điểm</span></div>
        <div class="mc-progress">
          <% if (nextTier != null) { %>
          <div class="mc-prog-row">
            <span>Còn <b><fmt:formatNumber value="<%= toNext %>"/> điểm</b> để lên <b><%= nextTier %></b></span>
            <span><%= progressPct %>%</span>
          </div>
          <% } else { %>
          <div class="mc-prog-row"><span>🎉 Bạn đã đạt hạng cao nhất!</span><span>100%</span></div>
          <% } %>
          <div class="mc-bar"><div class="mc-fill" style="width:<%= progressPct %>%"></div></div>
        </div>
        <div class="mc-qr-hint">
          <button onclick="openQrModal()">📱 Mã QR thay thẻ</button>
          <span>Quên thẻ NFC? Đưa mã QR cho dược sĩ quét</span>
        </div>
      </div>
    </div>

    <%-- Cảnh báo dị ứng nếu chưa khai --%>
    <% if (me.getAllergyHistory() == null || me.getAllergyHistory().trim().isEmpty()) { %>
    <div class="hp-alert" style="background:#fffbeb;border-color:#fde68a;color:#92400e">
      💡 <b>Bạn chưa khai báo tiền sử dị ứng thuốc.</b> Hãy cập nhật trong mục
      <a href="#" onclick="switchTab('account');return false" style="color:#b45309;font-weight:800">Tài khoản</a>
      để dược sĩ tư vấn an toàn hơn khi bạn mua thuốc.
    </div>
    <% } %>

    <%-- Hóa đơn gần nhất --%>
    <div class="sec">
      <div class="sec-head">
        <h3>🧾 Mua hàng gần đây</h3>
        <a href="#" onclick="switchTab('history');return false" style="font-size:12px;font-weight:750;color:var(--teal-d);text-decoration:none">Xem tất cả →</a>
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
                    <span class="inv-status ${iv.status=='COMPLETED'?'st-ok':'st-cancel'}">${iv.status=='COMPLETED'?'Hoàn tất':'Hoàn trả'}</span>
                  </div>
                </div>
              </c:if>
            </c:forEach>
          </c:otherwise>
        </c:choose>
      </div>
    </div>
  </section>

  <%-- ═══════════ TAB 2: LỊCH SỬ ═══════════ --%>
  <section class="tab-page" id="page-history">
    <div class="sec">
      <div class="sec-head"><h3>🧾 Lịch sử hóa đơn</h3><span style="font-size:12px;color:var(--muted)">${fn:length(invoices)} đơn</span></div>
      <div class="sec-body" style="padding-top:6px;padding-bottom:6px">
        <c:choose>
          <c:when test="${empty invoices}">
            <div class="empty"><div class="ei">🧾</div><p>Chưa có hóa đơn nào.</p></div>
          </c:when>
          <c:otherwise>
            <c:forEach var="iv" items="${invoices}">
              <div class="inv-row" onclick="openInvDetail(${iv.invoiceId})">
                <div>
                  <div class="inv-code">${iv.invoiceCode}</div>
                  <div class="inv-date">${fn:substring(iv.createdAt.toString(),0,10)} · ${fn:substring(iv.createdAt.toString(),11,16)}</div>
                </div>
                <div style="text-align:right">
                  <div class="inv-amt"><fmt:formatNumber value="${iv.finalAmount}" maxFractionDigits="0"/>đ</div>
                  <span class="inv-status ${iv.status=='COMPLETED'?'st-ok':'st-cancel'}">${iv.status=='COMPLETED'?'Hoàn tất':'Hoàn trả'}</span>
                </div>
              </div>
            </c:forEach>
          </c:otherwise>
        </c:choose>
      </div>
    </div>

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
</div>

<%-- ═══════════ BOTTOM NAV ═══════════ --%>
<nav class="bottom-nav">
  <button class="bn-item active" data-tab="home"    onclick="switchTab('home')"><span class="bi">🏠</span><span class="bl">Trang chủ</span></button>
  <button class="bn-item" data-tab="history" onclick="switchTab('history')"><span class="bi">🧾</span><span class="bl">Lịch sử</span></button>
  <button class="bn-item" data-tab="offers"  onclick="switchTab('offers')"><span class="bi">🎁</span><span class="bl">Ưu đãi</span></button>
  <button class="bn-item" data-tab="account" onclick="switchTab('account')"><span class="bi">👤</span><span class="bl">Tài khoản</span></button>
</nav>

<%-- Modal QR thay thẻ --%>
<div class="pmodal" id="qrModal" onclick="if(event.target===this)this.classList.remove('open')">
  <div class="pm-box" style="max-width:320px;text-align:center">
    <div class="pm-head"><h4>📱 Mã thay thẻ NFC</h4><button class="pm-x" onclick="document.getElementById('qrModal').classList.remove('open')">✕</button></div>
    <div style="padding:24px">
      <div id="qrBox" style="display:flex;justify-content:center;padding:10px;background:#fff"></div>
      <div style="font-size:15px;font-weight:800;letter-spacing:2px;margin-top:10px"><%= cardCode %></div>
      <p style="font-size:12px;color:#64748b;margin-top:8px;line-height:1.5">Đưa mã này cho dược sĩ quét khi bạn quên mang thẻ NFC.</p>
    </div>
  </div>
</div>

<%-- Modal chi tiết hóa đơn --%>
<div class="pmodal" id="invModal" onclick="if(event.target===this)this.classList.remove('open')">
  <div class="pm-box">
    <div class="pm-head"><h4>🧾 Chi tiết hóa đơn</h4><button class="pm-x" onclick="document.getElementById('invModal').classList.remove('open')">✕</button></div>
    <div id="invDetailBody" style="padding:18px 20px">Đang tải…</div>
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
  document.querySelectorAll('.bn-item').forEach(b => b.classList.toggle('active', b.dataset.tab === tab));
  window.scrollTo({ top: 0, behavior: 'smooth' });
}
if (location.hash === '#account') switchTab('account');

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

/* ── QR code (mã thay thẻ NFC) ── */
let qrRendered = false;
function openQrModal() {
  document.getElementById('qrModal').classList.add('open');
  if (!qrRendered && typeof QRCode !== 'undefined') {
    new QRCode(document.getElementById('qrBox'), {
      text: 'MEDICARE|<%= cardCode %>|<%= me.getPhone() != null ? me.getPhone() : "" %>',
      width: 190, height: 190, correctLevel: QRCode.CorrectLevel.M
    });
    qrRendered = true;
  }
}

/* ── Toast ── */
function toast(msg, type) {
  const t = document.createElement('div');
  t.className = 'toast ' + (type || 'ok');
  t.textContent = msg;
  document.body.appendChild(t);
  setTimeout(() => { t.style.opacity = '0'; t.style.transition = 'opacity .4s'; setTimeout(() => t.remove(), 400); }, 2800);
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

/* ── Chi tiết hóa đơn ── */
async function openInvDetail(id) {
  const modal = document.getElementById('invModal');
  const body  = document.getElementById('invDetailBody');
  modal.classList.add('open');
  body.innerHTML = '<div style="text-align:center;color:#94a3b8;padding:20px 0">Đang tải…</div>';
  try {
    const res = await fetch(CTX + '/portal?action=invoice-detail&id=' + id);
    const d = await res.json();
    if (!d.ok) { body.innerHTML = '<div style="color:#dc2626;text-align:center;padding:16px 0">Không tải được chi tiết.</div>'; return; }
    const fmtV = n => new Intl.NumberFormat('vi-VN').format(n) + 'đ';
    const mLbl = { CASH:'💵 Tiền mặt', QR_CODE:'📱 QR', CARD:'💳 Thẻ' };
    body.innerHTML =
      '<div style="display:flex;justify-content:space-between;font-size:13px;border-bottom:1px solid #f1f5f9;padding-bottom:10px;margin-bottom:12px">'
      + '<div><b style="font-size:15px">' + d.code + '</b><div style="color:#94a3b8;font-size:11.5px;margin-top:2px">' + d.time + ' · ' + (mLbl[d.method]||d.method) + '</div></div></div>'
      + '<div style="font-size:11px;font-weight:800;color:#94a3b8;letter-spacing:.5px;margin-bottom:8px">DANH MỤC THUỐC ĐÃ MUA</div>'
      + d.items.map(it =>
          '<div style="display:flex;justify-content:space-between;align-items:center;background:#f8fafc;border-radius:11px;padding:10px 12px;margin-bottom:7px">'
        + '<div><div style="font-weight:750;font-size:13px">' + it.name + '</div>'
        + '<div style="font-size:11px;color:#94a3b8">SL: ' + it.qty + ' ' + it.unit + ' × ' + fmtV(it.price) + '</div></div>'
        + '<b style="font-size:12.5px">' + fmtV(it.subtotal) + '</b></div>').join('')
      + '<div style="display:flex;justify-content:space-between;align-items:center;background:#f0fdfa;border:1px solid #99f6e4;border-radius:13px;padding:12px 14px;margin-top:12px">'
      + '<span style="font-size:12px;font-weight:750;color:#0f766e">Tổng thanh toán</span>'
      + '<b style="font-size:18px">' + fmtV(d.total) + '</b></div>';
  } catch (e) {
    body.innerHTML = '<div style="color:#dc2626;text-align:center;padding:16px 0">Lỗi kết nối.</div>';
  }
}
</script>
</body>
</html>
