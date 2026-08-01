<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) request.getAttribute("staffAcc");
    String ctx = request.getContextPath();
    if (acc == null) { response.sendRedirect(ctx + "/warehouse-login"); return; }
    String fullName = acc.getFullName() != null && !acc.getFullName().isEmpty() ? acc.getFullName() : acc.getUsername();
    String initials = fullName.substring(0,1).toUpperCase();
    String uid = (String) request.getAttribute("staffUid");
    String currentTab = (String) request.getAttribute("currentTab");
    if (currentTab == null || currentTab.isEmpty()) currentTab = "inventory";
    String activeNav = currentTab;
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Quản lý tồn kho — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400..800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= ctx %>/css/staff-portal.css">
<link rel="stylesheet" href="<%= ctx %>/css/warehouse-portal.css?v=5">
<style>
a{text-decoration:none;color:inherit}

.wrap{max-width:1200px;margin:0 auto;padding:20px 28px 60px}
.head{display:flex;align-items:flex-end;justify-content:space-between;flex-wrap:wrap;gap:14px;margin-bottom:18px}
.head h1{font-size:24px;font-weight:800;letter-spacing:-.5px}
.head h1 span{color:var(--main)}
.head p{color:var(--muted);font-size:14px;margin-top:4px}

/* ── Sub-Tab Navigation Bar ── */
.sub-tabs-bar{display:flex;align-items:center;gap:8px;padding:6px;background:#EAF1EF;border-radius:14px;margin-bottom:24px;border:1px solid #D8E5E1;overflow-x:auto}
.tab-link{display:inline-flex;align-items:center;gap:8px;padding:10px 18px;border-radius:10px;font-size:13.5px;font-weight:750;color:var(--muted);transition:.18s;white-space:nowrap;cursor:pointer}
.tab-link:hover{color:var(--ink);background:rgba(255,255,255,.6)}
.tab-link.active{background:#fff;color:var(--main);box-shadow:0 2px 8px rgba(4,47,46,.08);font-weight:800}
.tab-link .badge-num{display:inline-block;padding:2px 7px;border-radius:12px;font-size:11px;font-weight:800;background:var(--goldbg);color:var(--gold)}

.stats{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:22px}
.stat{background:#fff;border:1px solid #E4E9E7;border-radius:14px;padding:16px 18px;box-shadow:0 1px 2px rgba(4,47,46,.04),0 8px 22px -14px rgba(4,47,46,.10);display:flex;align-items:center;gap:14px}
.stat .ic{width:44px;height:44px;border-radius:12px;display:grid;place-items:center;font-size:20px;flex:none}
.stat .num{font-size:24px;font-weight:800;letter-spacing:-.5px;line-height:1}
.stat .lbl{font-size:12.5px;color:var(--muted);font-weight:600;margin-top:3px}
.stat.a .ic{background:var(--soft);color:var(--main)}
.stat.b .ic{background:var(--goldbg);color:var(--gold)} .stat.b .num{color:var(--gold)}
.stat.c .ic{background:var(--goldbg);color:var(--gold)}
.stat.d .ic{background:var(--dangerbg);color:var(--danger)} .stat.d .num{color:var(--danger)}

.card{background:#fff;border:1px solid #E4E9E7;border-radius:16px;overflow:hidden;margin-bottom:22px;box-shadow:0 1px 2px rgba(4,47,46,.04),0 12px 30px -18px rgba(4,47,46,.12)}
.card-head{display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;padding:16px 20px;border-bottom:1px solid var(--line)}
.card-head h2{font-size:15px;font-weight:800;display:flex;align-items:center;gap:8px}
.card-head h2 small{color:var(--muted);font-weight:600;font-size:12.5px;margin-left:6px}

.search{display:flex;gap:8px}
.search input{width:280px;max-width:52vw;padding:10px 14px;border:1.5px solid var(--border);border-radius:10px;font-family:inherit;font-size:14px;background:var(--surface);color:var(--ink)}
.search input:focus{outline:none;border-color:var(--main);background:#fff;box-shadow:0 0 0 3px rgba(15,118,110,.12)}
.search button{padding:10px 16px;border:none;border-radius:10px;background:linear-gradient(135deg,var(--main),var(--deep));color:#fff;font-weight:700;font-size:13.5px;cursor:pointer;font-family:inherit}
.search a.clear{padding:10px 14px;border:1.5px solid var(--border);border-radius:10px;color:var(--muted);font-weight:700;font-size:13.5px}

.tblwrap{overflow-x:auto}
table{border-collapse:collapse;width:100%;font-size:13.5px}
th,td{padding:13px 16px;text-align:left;border-bottom:1px solid var(--line)}
thead th{font-size:11px;letter-spacing:.06em;text-transform:uppercase;color:var(--muted);font-weight:700;background:var(--surface)}
tbody tr:nth-child(even){background:#F8FAFC}
tbody tr:hover{background:#E6FFFA}
.code{font-family:ui-monospace,Consolas,monospace;font-size:12px;color:#4B5A56}
.mname{font-weight:700;color:#0F172A;line-height:1.35}
.gen{font-size:12px;color:var(--muted);margin-top:3px}
.num-cell{text-align:right;font-variant-numeric:tabular-nums;font-weight:700}
.price-cell{text-align:right;font-variant-numeric:tabular-nums;font-weight:800;color:#0F172A}
.badge{display:inline-block;padding:2px 9px;border-radius:20px;font-size:11.5px;font-weight:700}
.badge.ok{background:var(--okbg);color:var(--ok)}
.badge.low{background:var(--goldbg);color:var(--gold)}
.badge.out{background:var(--dangerbg);color:var(--danger)}
.badge.info{background:#DBEAFE;color:#1D4ED8}
.badge.warn{background:var(--goldbg);color:var(--gold)}
.badge.danger{background:var(--dangerbg);color:var(--danger)}
.empty{padding:36px;text-align:center;color:var(--muted);font-size:14px}
.act-cell{white-space:nowrap;text-align:right}
.act-btn{display:inline-flex;align-items:center;justify-content:center;width:30px;height:30px;border-radius:8px;font-size:14.5px;margin-left:4px;background:var(--surface);border:1px solid var(--border);transition:.15s}
.act-btn:hover{background:var(--soft);border-color:var(--main);transform:translateY(-1px)}

.split{display:grid;grid-template-columns:1.7fr 1fr;gap:20px;align-items:start}
.side-stack{display:flex;flex-direction:column;gap:20px}
.warn-head{background:linear-gradient(90deg,#FEF3C7,transparent)}
.dead-head{background:linear-gradient(90deg,var(--dangerbg),transparent)}
.reorder-head{background:linear-gradient(90deg,var(--soft),transparent)}
.light-head{background:linear-gradient(90deg,#DBEAFE,transparent)}
.restrict-head{background:linear-gradient(90deg,#FEF3C7,transparent)}
.quar-head{background:linear-gradient(90deg,var(--dangerbg),transparent)}
.exp-date{font-weight:700}
.exp-soon{color:var(--gold)} .exp-dead{color:var(--danger)}
.grid3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:22px}

/* ── UI Gợi ý đặt hàng phóng to (Hình 3) ── */
.reorder-view .head h1{font-size:28px;font-weight:850;letter-spacing:-.6px}
.reorder-view .head p{font-size:15px;line-height:1.6}
.reorder-view .card{border-radius:18px;box-shadow:0 12px 32px -14px rgba(4,47,46,.14)}
.reorder-view .card-head{padding:20px 26px;border-bottom:1px solid #E2E8F0}
.reorder-view .card-head h2{font-size:18px;font-weight:850;letter-spacing:-.3px}
.reorder-view .card-head h2 small{font-size:14px;font-weight:700;margin-left:8px}
.reorder-view .card-head .wh-ic{width:40px;height:40px;font-size:22px;border-radius:12px}

.reorder-table table{font-size:15px}
.reorder-table th{font-size:12.5px;padding:15px 22px;letter-spacing:.06em;background:#F1F5F9;color:#475569}
.reorder-table td{padding:18px 22px;font-size:15px;border-bottom:1px solid #EDF2F7}
.reorder-table .mname{font-size:16px;font-weight:800;color:#0F172A}
.reorder-table .num-cell{font-size:16.5px;font-weight:800}
.reorder-table .detail-btn{display:inline-flex;align-items:center;gap:6px;padding:8px 16px;border-radius:10px;background:#F0FDFA;color:#0F766E;font-weight:800;font-size:14px;border:1px solid #99F6E4;transition:.15s}
.reorder-table .detail-btn:hover{background:#0F766E;color:#fff;border-color:#0F766E;transform:translateY(-1px)}

.reorder-grid3{display:flex;flex-direction:column;gap:24px}
.reorder-grid3 .card{border-radius:18px;box-shadow:0 10px 28px -12px rgba(4,47,46,.12)}
.reorder-grid3 .card-head{padding:20px 24px}
.reorder-grid3 .card-head h2{font-size:17.5px;font-weight:850}
.reorder-grid3 .card-head h2 small{font-size:14px;font-weight:700}
.reorder-grid3 table{font-size:15px}
.reorder-grid3 th{font-size:12.5px;padding:14px 22px;background:#F8FAFC}
.reorder-grid3 td{padding:16px 22px}
.reorder-grid3 .mname{font-size:16px;font-weight:800;color:#0F172A}
.reorder-grid3 .num-cell{font-size:16.5px;font-weight:800}
.reorder-grid3 .badge{font-size:13px;padding:5px 14px;border-radius:20px;font-weight:800}

/* ── Stock Movement & Recall Elements ── */
.sm-grid{display:grid;grid-template-columns:1.5fr 1fr;gap:22px;align-items:start}
.sm-side{display:flex;flex-direction:column;gap:22px}
.card-body{padding:22px 20px}
.fg{display:flex;flex-direction:column;gap:7px;margin-bottom:17px}
.fg > label{font-size:11px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.fg input,.fg select,.fg textarea{border:1.5px solid #DCE8E5;border-radius:10px;padding:11px 14px;font-family:inherit;font-size:14px;color:var(--ink);background:#fff;width:100%;transition:border .16s,box-shadow .16s}
.fg input:focus,.fg select:focus,.fg textarea:focus{border-color:var(--main);outline:none;box-shadow:0 0 0 3.5px rgba(15,118,110,.12)}
.fg textarea{min-height:84px;resize:vertical}
.row2{display:grid;grid-template-columns:1fr 1fr;gap:14px}
.fefo-nudge{display:none;align-items:center;gap:11px;margin:-2px 0 17px;padding:12px 15px;border-radius:11px;background:linear-gradient(100deg,#E6FFFA,#ECFDF9);border:1px solid #99F6E4;border-left:4px solid var(--main);font-size:13px;color:var(--deep);line-height:1.45}
.fefo-nudge.show{display:flex}
.fefo-nudge b{font-weight:800;color:var(--main)}
.direction-row{display:none;gap:10px;margin:-2px 0 17px}
.direction-row.show{display:flex}
.dir-opt{flex:1;display:flex;align-items:center;gap:8px;padding:11px 13px;border:1.5px solid #DCE8E5;border-radius:10px;cursor:pointer;font-size:13px;font-weight:700;color:var(--ink);background:#fff}
.dir-opt input{accent-color:var(--main)}
.dir-opt:has(input:checked){border-color:var(--main);background:#E6FFFA}
.btn-submit{width:100%;height:48px;background:linear-gradient(135deg,var(--main),var(--deep));color:#fff;border:none;border-radius:12px;font-size:15px;font-weight:800;cursor:pointer;font-family:inherit;transition:filter .15s,transform .05s;box-shadow:0 8px 20px -8px rgba(15,118,110,.5)}
.btn-submit:hover{filter:brightness(1.07)}

.batch-empty{padding:34px 22px;text-align:center;color:var(--muted)}
.batch-info{display:none;padding:20px}
.batch-info.show{display:block}
.bi-tag{font-size:10.5px;font-weight:800;letter-spacing:.6px;text-transform:uppercase;color:var(--main);margin-bottom:7px}
.bi-batch{font-size:23px;font-weight:800;color:var(--ink);letter-spacing:-.3px;font-family:ui-monospace,Consolas,monospace;margin-bottom:17px;word-break:break-all}
.bi-rows{display:flex;flex-direction:column;gap:0}
.bi-row{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:11px 0;border-bottom:1px solid #EAEFED}
.bi-row:last-child{border-bottom:none}
.bi-lbl{font-size:12.5px;color:var(--muted);font-weight:650}
.bi-val{font-size:14px;font-weight:800;color:var(--ink)}

.mini-list{display:flex;flex-direction:column}
.mini-row{display:flex;align-items:center;gap:11px;padding:11px 18px;border-bottom:1px solid #F2ECE7}
.mini-row:last-child{border-bottom:none}
.mini-ic{width:34px;height:34px;border-radius:9px;flex:none;display:grid;place-items:center;font-size:14px}
.mi-OUT{background:var(--dangerbg)} .mi-EXPIRED{background:var(--goldbg)} .mi-ADJUSTMENT{background:#E0F2FE}
.mini-body{flex:1;min-width:0}
.mini-med{font-size:12.5px;font-weight:750;color:var(--ink);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.mini-meta{font-size:11px;color:var(--muted);margin-top:2px}
.mini-qty{font-size:13.5px;font-weight:800;flex:none;font-variant-numeric:tabular-nums}
.q-neg{color:var(--danger)}.q-pos{color:var(--ok)}

/* ── Recall specific ── */
.recall-card{border:2px solid var(--danger);background:linear-gradient(180deg,var(--dangerbg) 0%,#fff 22%)}
.recall-card .card-head{background:var(--danger);color:#fff;border-bottom:none}
.recall-card .card-head h2{color:#fff}
.info-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:14px;margin-bottom:18px}
.info-item{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:12px 14px}
.info-item .lbl{font-size:11px;color:var(--muted);font-weight:700;text-transform:uppercase;letter-spacing:.04em}
.info-item .val{font-size:16px;font-weight:800;margin-top:4px}
.info-item.warn .val{color:var(--danger)}
.info-item .val.shelf{color:var(--jade)}
.btn-danger-big{padding:15px 26px;font-size:15.5px;background:linear-gradient(135deg,#F87171,#DC2626);color:#fff;border:none;border-radius:12px;font-weight:800;cursor:pointer;box-shadow:0 10px 26px -10px rgba(220,38,38,.5)}
.btn-danger-big:disabled{opacity:.45;cursor:not-allowed;box-shadow:none}

.alert-msg{border-radius:12px;padding:13px 18px;margin-bottom:18px;font-size:13.5px;font-weight:600}
.alert-ok{background:#ECFDF5;border:1px solid #6EE7B7;color:#047857}
.alert-err{background:#FEF2F2;border:1px solid #FCA5A5;color:#B91C1C}

@media(max-width:1000px){.split,.sm-grid,.grid3{grid-template-columns:1fr}}
@media(max-width:900px){.stats{grid-template-columns:repeat(2,1fr)}}

/* Modal styling */
.dm-backdrop{display:none;position:fixed;inset:0;z-index:9000;background:rgba(11,22,40,.55);align-items:flex-start;justify-content:center;padding:40px 20px;overflow-y:auto}
.dm-backdrop.show{display:flex}
.dm-box{background:#fff;border-radius:18px;max-width:720px;width:100%;box-shadow:0 24px 70px rgba(0,0,0,.3);overflow:hidden}
.dm-head{padding:18px 24px;background:linear-gradient(135deg,var(--deep),var(--main));color:#fff;display:flex;align-items:center;justify-content:space-between;gap:12px}
.dm-head h3{font-size:16.5px;font-weight:800;margin:0}
.dm-head .sub{font-size:12px;color:rgba(255,255,255,.7);margin-top:2px}
.dm-close{background:rgba(255,255,255,.16);border:none;color:#fff;width:30px;height:30px;border-radius:9px;font-size:15px;cursor:pointer;flex:none}
.dm-body{padding:22px 24px;max-height:70vh;overflow-y:auto}
.dm-loading{padding:40px;text-align:center;color:var(--muted)}
.dm-grid{display:grid;grid-template-columns:1fr 1fr;gap:14px 20px;margin-bottom:18px}
.dm-field{display:flex;flex-direction:column;gap:3px}
.dm-field .k{font-size:10.5px;font-weight:750;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}
.dm-field .v{font-size:13.5px;font-weight:650;color:#0F172A}
.dm-field .v.empty{color:var(--muted);font-weight:500;font-style:italic}
.dm-field.full{grid-column:1/-1}
.dm-sec-title{font-size:12px;font-weight:800;color:var(--main);text-transform:uppercase;letter-spacing:.5px;margin:18px 0 10px;padding-top:14px;border-top:1px solid var(--line)}
.dm-batches table{font-size:12.5px}
.dm-batches th,.dm-batches td{padding:8px 12px}
.dm-batch-status{font-size:10.5px;font-weight:750;padding:2px 8px;border-radius:14px}
.dm-batch-status.ACTIVE{background:var(--okbg);color:var(--ok)}
.dm-batch-status.RECALLED{background:var(--dangerbg);color:var(--danger)}
.dm-batch-status.CANCELLED,.dm-batch-status.EXPIRED{background:#F1F5F4;color:var(--muted)}
</style>
<meta name="csrf-token" content="${csrfToken}">
<script src="${pageContext.request.contextPath}/js/csrf.js"></script>
</head>
<body class="wh">
<%@ include file="warehouse-sidebar.jsp" %>
<div class="main">
  <header class="wh-topbar">
    <div class="crumb">
      <c:choose>
        <c:when test="${currentTab == 'movement'}">Xuất kho &amp; Điều chỉnh tồn</c:when>
        <c:otherwise>
          Quản lý tồn kho
          <c:if test="${currentTab == 'reorder'}"> &nbsp;/&nbsp; Gợi ý đặt hàng</c:if>
          <c:if test="${currentTab == 'recall'}"> &nbsp;/&nbsp; Thu hồi khẩn cấp</c:if>
        </c:otherwise>
      </c:choose>
    </div>
    <div class="right">
      <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc"><%= initials %></a>
    </div>
  </header>

  <div class="wrap">
    <!-- ══ SUB-TAB BAR (Chỉ hiện ở Quản lý tồn kho, ẩn ở trang Xuất kho & Điều chỉnh) ══ -->
    <c:if test="${currentTab != 'movement'}">
      <div class="sub-tabs-bar">
        <a href="<%= ctx %>/warehouse-inventory?uid=<%= uid %>&tab=inventory" class="tab-link <%= "inventory".equals(currentTab) ? "active" : "" %>">
          <span>💊</span> Danh mục tồn kho
        </a>
        <a href="<%= ctx %>/warehouse-inventory?uid=<%= uid %>&tab=reorder" class="tab-link <%= "reorder".equals(currentTab) ? "active" : "" %>">
          <span>📈</span> Gợi ý đặt hàng
          <c:if test="${not empty pendingSuggestions && pendingSuggestions.size() > 0}">
            <span class="badge-num">${pendingSuggestions.size()}</span>
          </c:if>
        </a>
        <a href="<%= ctx %>/warehouse-inventory?uid=<%= uid %>&tab=recall" class="tab-link <%= "recall".equals(currentTab) ? "active" : "" %>">
          <span>🚨</span> Thu hồi khẩn cấp
        </a>
      </div>
    </c:if>

    <c:if test="${param.msg == 'success'}">
      <div class="alert-msg alert-ok">✅ Đã ghi nhận thao tác thành công. Tồn kho lô đã được cập nhật.</div>
    </c:if>
    <c:if test="${param.msg == 'recalled'}">
      <div class="alert-msg alert-ok">✅ Đã thu hồi lô thành công — lô này đã ngừng bán ngay lập tức tại POS.</div>
    </c:if>
    <c:if test="${not empty error}">
      <div class="alert-msg alert-err">⛔ <c:out value="${error}"/></div>
    </c:if>

    <!-- ════ TAB 1: DANH MỤC TỒN KHO ════ -->
    <c:if test="${currentTab == 'inventory'}">
      <div class="head">
        <div>
          <h1>Quản lý <span>tồn kho</span></h1>
          <p>Danh mục thuốc, tồn kho thực tế theo lô, và cảnh báo hạn dùng.</p>
        </div>
      </div>

      <div class="stats">
        <div class="stat a"><div class="ic">💊</div><div><div class="num">${totalActive}</div><div class="lbl">Thuốc đang kinh doanh</div></div></div>
        <div class="stat b"><div class="ic">📉</div><div><div class="num">${lowStockCount}</div><div class="lbl">Sắp hết hàng</div></div></div>
        <div class="stat c"><div class="ic">⏳</div><div><div class="num">${expiringBatches.size()}</div><div class="lbl">Lô cận hạn (≤30 ngày)</div></div></div>
        <div class="stat d"><div class="ic">⛔</div><div><div class="num">${expiredBatches.size()}</div><div class="lbl">Lô đã hết hạn</div></div></div>
      </div>

      <div class="split">
        <div class="card">
          <div class="card-head">
            <div style="display:flex;align-items:center;gap:12px">
              <div class="wh-ic">💊</div>
              <h2>Danh mục thuốc <small>(${medicines.size()} mục)</small></h2>
            </div>
            <form class="search" method="get" action="<%= ctx %>/warehouse-inventory">
              <input type="hidden" name="uid" value="${staffUid}">
              <input type="hidden" name="tab" value="inventory">
              <div class="wh-field">
                <span class="wh-field-ic">🔍</span>
                <input type="text" name="q" value="${fn:escapeXml(keyword)}" placeholder="Tìm tên, hoạt chất, barcode, mã thuốc…">
              </div>
              <button type="submit">🔍 Tìm</button>
              <c:if test="${not empty keyword}"><a class="clear" href="<%= ctx %>/warehouse-inventory?uid=${staffUid}&tab=inventory">✕</a></c:if>
            </form>
          </div>
          <div class="tblwrap">
            <table>
              <thead><tr>
                <th>Mã</th><th>Thuốc</th>
                <th style="text-align:right">Tồn kho</th><th>Trạng thái</th>
                <th style="text-align:right">Giá bán</th>
                <th style="text-align:right">Thao tác</th>
              </tr></thead>
              <tbody>
              <c:choose>
                <c:when test="${empty medicines}">
                  <tr><td colspan="6" class="empty">Không có thuốc nào khớp tìm kiếm.</td></tr>
                </c:when>
                <c:otherwise>
                  <c:forEach var="m" items="${medicines}">
                    <tr>
                      <td class="code">${m.medicineCode}</td>
                      <td>
                        <div class="mname">${m.medicineName}</div>
                        <c:if test="${not empty m.genericName}"><div class="gen">${m.genericName}</div></c:if>
                      </td>
                      <td class="num-cell">${m.totalStock} / <span style="color:var(--muted);font-weight:600">${m.minInventory}</span></td>
                      <td>
                        <c:choose>
                          <c:when test="${m.totalStock == 0}"><span class="badge out">Hết hàng</span></c:when>
                          <c:when test="${m.minInventory > 0 && m.totalStock <= m.minInventory}"><span class="badge low">Sắp hết</span></c:when>
                          <c:otherwise><span class="badge ok">Đủ hàng</span></c:otherwise>
                        </c:choose>
                      </td>
                      <td class="price-cell"><fmt:formatNumber value="${m.sellingPrice}" type="number" maxFractionDigits="0"/>đ</td>
                      <td class="act-cell">
                        <button type="button" class="act-btn" onclick="openDetail(${m.medicineId})" title="Xem toàn bộ thông tin sản phẩm">👁️</button>
                        <a class="act-btn" href="<%= ctx %>/warehouse-inventory?uid=${staffUid}&tab=movement&medicineId=${m.medicineId}" title="Xuất / Điều chỉnh tồn">📤</a>
                      </td>
                    </tr>
                  </c:forEach>
                </c:otherwise>
              </c:choose>
              </tbody>
            </table>
          </div>
        </div>

        <div class="side-stack">
          <div class="card panel">
            <div class="card-head warn-head"><div class="wh-ic warn">⏳</div><h2>Lô cận hạn <small>≤ 30 ngày</small></h2></div>
            <div class="tblwrap">
              <table style="min-width:auto">
                <thead><tr><th>Số lô</th><th>Thuốc</th><th style="text-align:right">Tồn</th><th>Hạn</th></tr></thead>
                <tbody>
                  <c:choose>
                    <c:when test="${empty expiringBatches}"><tr><td colspan="4" class="empty">Không có lô nào cận hạn. 👍</td></tr></c:when>
                    <c:otherwise>
                      <c:forEach var="b" items="${expiringBatches}">
                        <tr>
                          <td class="code">${b.batchNumber}</td>
                          <td class="mname">${medNameMap[b.medicineId]}</td>
                          <td class="num-cell">${b.currentQuantity}</td>
                          <td class="exp-date exp-soon">${b.expiryDate}</td>
                        </tr>
                      </c:forEach>
                    </c:otherwise>
                  </c:choose>
                </tbody>
              </table>
            </div>
          </div>

          <div class="card panel">
            <div class="card-head dead-head"><div class="wh-ic danger">⛔</div><h2>Lô đã hết hạn</h2></div>
            <div class="tblwrap">
              <table style="min-width:auto">
                <thead><tr><th>Số lô</th><th>Thuốc</th><th style="text-align:right">Tồn</th><th>Hạn</th></tr></thead>
                <tbody>
                  <c:choose>
                    <c:when test="${empty expiredBatches}"><tr><td colspan="4" class="empty">Không có lô hết hạn tồn kho. 👍</td></tr></c:when>
                    <c:otherwise>
                      <c:forEach var="b" items="${expiredBatches}">
                        <tr>
                          <td class="code">${b.batchNumber}</td>
                          <td class="mname">${medNameMap[b.medicineId]}</td>
                          <td class="num-cell">${b.currentQuantity}</td>
                          <td class="exp-date exp-dead">${b.expiryDate}</td>
                        </tr>
                      </c:forEach>
                    </c:otherwise>
                  </c:choose>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </c:if>

    <!-- ════ TAB 2: GỢI Ý ĐẶT HÀNG ════ -->
    <c:if test="${currentTab == 'reorder'}">
      <div class="reorder-view">
        <div class="head">
          <div>
            <h1>Gợi ý <span>đặt hàng</span> &amp; Cảnh báo hạn dùng</h1>
            <p>Hệ thống tự tính điểm đặt hàng lại (ROP) và tự cách ly lô cận hạn mỗi giờ — Admin duyệt phiếu đề xuất bên dưới.</p>
          </div>
        </div>

        <div class="card">
          <div class="card-head reorder-head">
            <div class="wh-ic">📈</div>
            <h2>Gợi ý đặt hàng <small>(PO chờ duyệt — ${pendingSuggestions.size()} phiếu)</small></h2>
          </div>
          <div class="tblwrap reorder-table">
            <table>
              <thead><tr>
                <th>Thuốc</th><th>Nhà cung cấp</th>
                <th style="text-align:right">SL đề xuất</th>
                <th style="text-align:right">Tổng tiền ước tính</th>
                <th>Ngày đề xuất</th><th>Chi tiết</th>
              </tr></thead>
              <tbody>
              <c:choose>
                <c:when test="${empty pendingSuggestions}">
                  <tr><td colspan="6" class="empty">Không có phiếu đề xuất nào đang chờ — tồn kho hiện đủ so với ROP. 👍</td></tr>
                </c:when>
                <c:otherwise>
                  <c:forEach var="row" items="${pendingSuggestions}">
                    <tr>
                      <td class="mname">${row.medicineName}</td>
                      <td>${row.supplierName}</td>
                      <td class="num-cell">${row.quantity}</td>
                      <td class="num-cell"><fmt:formatNumber value="${row.totalValue}" type="number" maxFractionDigits="0"/>đ</td>
                      <td><fmt:formatDate value="${row.orderDate}" pattern="dd/MM/yyyy HH:mm"/></td>
                      <td><a class="detail-btn" href="<%= ctx %>/purchase-orders?action=detail&id=${row.poId}">Xem chi tiết đơn →</a></td>
                    </tr>
                  </c:forEach>
                </c:otherwise>
              </c:choose>
              </tbody>
            </table>
          </div>
        </div>

        <div class="reorder-grid3">
          <div class="card">
            <div class="card-head light-head"><div class="wh-ic jade">🕐</div><h2>Cận hạn nhẹ <small>91–180 ngày</small></h2></div>
            <div class="tblwrap">
              <table style="min-width:auto">
                <thead><tr><th>Thuốc</th><th>Số lô</th><th style="text-align:right">Còn tồn</th><th>HSD</th></tr></thead>
                <tbody>
                  <c:choose>
                    <c:when test="${empty tierLight}"><tr><td colspan="4" class="empty">Không có lô nào.</td></tr></c:when>
                    <c:otherwise>
                      <c:forEach var="b" items="${tierLight}">
                        <tr>
                          <td class="mname">${b.medicineName}</td>
                          <td class="code">${b.batchNumber}</td>
                          <td class="num-cell">${b.currentQuantity}</td>
                          <td class="exp-date"><span class="badge info"><fmt:formatDate value="${b.expiryDate}" pattern="dd/MM/yyyy"/></span></td>
                        </tr>
                      </c:forEach>
                    </c:otherwise>
                  </c:choose>
                </tbody>
              </table>
            </div>
          </div>

          <div class="card">
            <div class="card-head restrict-head"><div class="wh-ic warn">⚠️</div><h2>Hạn chế xuất SL lớn <small>31–90 ngày</small></h2></div>
            <div class="tblwrap">
              <table style="min-width:auto">
                <thead><tr><th>Thuốc</th><th>Số lô</th><th style="text-align:right">Còn tồn</th><th>HSD</th></tr></thead>
                <tbody>
                  <c:choose>
                    <c:when test="${empty tierRestricted}"><tr><td colspan="4" class="empty">Không có lô nào.</td></tr></c:when>
                    <c:otherwise>
                      <c:forEach var="b" items="${tierRestricted}">
                        <tr>
                          <td class="mname">${b.medicineName}</td>
                          <td class="code">${b.batchNumber}</td>
                          <td class="num-cell">${b.currentQuantity}</td>
                          <td class="exp-date"><span class="badge warn"><fmt:formatDate value="${b.expiryDate}" pattern="dd/MM/yyyy"/></span></td>
                        </tr>
                      </c:forEach>
                    </c:otherwise>
                  </c:choose>
                </tbody>
              </table>
            </div>
          </div>

          <div class="card">
            <div class="card-head quar-head"><div class="wh-ic danger">⛔</div><h2>Đã cách ly <small>≤ 30 ngày</small></h2></div>
            <div class="tblwrap">
              <table style="min-width:auto">
                <thead><tr><th>Thuốc</th><th>Số lô</th><th style="text-align:right">Còn tồn</th><th>HSD</th></tr></thead>
                <tbody>
                  <c:choose>
                    <c:when test="${empty tierQuarantined}"><tr><td colspan="4" class="empty">Không có lô nào bị cách ly.</td></tr></c:when>
                    <c:otherwise>
                      <c:forEach var="b" items="${tierQuarantined}">
                        <tr>
                          <td class="mname">${b.medicineName}</td>
                          <td class="code">${b.batchNumber}</td>
                          <td class="num-cell">${b.currentQuantity}</td>
                          <td class="exp-date"><span class="badge danger"><fmt:formatDate value="${b.expiryDate}" pattern="dd/MM/yyyy"/></span></td>
                        </tr>
                      </c:forEach>
                    </c:otherwise>
                  </c:choose>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </c:if>

    <!-- ════ TAB 3: DỒN CHUNG ĐIỀU CHỈNH (XUẤT KHO & ĐIỀU CHỈNH) ════ -->
    <c:if test="${currentTab == 'movement'}">
      <div class="head">
        <div>
          <h1>Xuất kho &amp; <span>Điều chỉnh tồn</span></h1>
          <p>Hệ thống chỉ định lô theo FEFO (hạn dùng gần nhất) — quét/nhập đúng số lô để xác nhận.</p>
        </div>
      </div>

      <div class="sm-grid">
        <div class="card">
          <div class="card-head">
            <div class="wh-ic">📤</div>
            <h2>Thao tác xuất kho / điều chỉnh</h2>
          </div>
          <div class="card-body">
            <form method="post" action="<%= ctx %>/warehouse-stock-movement" id="mvForm">
              <input type="hidden" name="_csrf" value="${csrfToken}">
              <input type="hidden" name="uid" value="${staffUid}"/>

              <div class="fg">
                <label>Thuốc</label>
                <div class="wh-field">
                  <span class="wh-field-ic">💊</span>
                  <select name="medicineId" id="medicineSelect" required onchange="loadSuggestedBatch()">
                    <option value="">— Chọn thuốc —</option>
                    <c:forEach var="m" items="${allMedicines}">
                      <option value="${m.medicineId}" ${param.medicineId == m.medicineId ? 'selected' : ''}>
                        ${m.medicineName} (Tồn: ${m.totalStock})
                      </option>
                    </c:forEach>
                  </select>
                </div>
              </div>

              <div class="fefo-nudge" id="fefoNudge">
                <span class="fn-ic">💡</span>
                <span>Hệ thống chỉ định lô <b id="fnBatch">—</b> — hãy quét/nhập <b>đúng lô này</b>.</span>
              </div>

              <div class="row2">
                <div class="fg">
                  <label style="display:flex; justify-content:space-between; align-items:center;">
                      <span>Số lô (quét hoặc nhập tay)</span>
                      <button type="button" onclick="openBarcodeScan()" style="background:none;border:none;color:var(--main);font-size:12px;cursor:pointer;font-weight:700;">📷 Quét mã vạch</button>
                  </label>
                  <div class="wh-field">
                    <span class="wh-field-ic">🏷️</span>
                    <input type="text" name="enteredBatchNumber" id="enteredBatchNumber" placeholder="VD: LOT-2026-001" autocomplete="off" required/>
                  </div>
                </div>
                <div class="fg">
                  <label>Số lượng</label>
                  <div class="wh-field">
                    <span class="wh-field-ic">🔢</span>
                    <input type="number" name="quantity" min="1" required/>
                  </div>
                </div>
              </div>

              <div class="fg">
                <label>Loại thao tác</label>
                <div class="wh-field">
                  <span class="wh-field-ic">🔄</span>
                  <select name="movementType" id="movementType" required onchange="toggleDirection()">
                    <option value="OUT">Xuất kho / Hủy hàng</option>
                    <option value="EXPIRED">Hủy hết hạn</option>
                    <option value="ADJUSTMENT">Điều chỉnh sau kiểm kê</option>
                  </select>
                </div>
              </div>

              <div class="direction-row" id="directionRow">
                <label class="dir-opt">
                  <input type="radio" name="adjustDirection" value="DECREASE" checked/> Kiểm kê THIẾU (giảm tồn)
                </label>
                <label class="dir-opt">
                  <input type="radio" name="adjustDirection" value="INCREASE"/> Kiểm kê THỪA (tăng tồn)
                </label>
              </div>

              <div class="fg">
                <label>Lý do</label>
                <textarea name="reason" placeholder="VD: Hộp bị vỡ, phát hiện khi kiểm kê định kỳ..." required></textarea>
              </div>

              <button type="submit" class="btn-submit">Xác nhận thao tác</button>
            </form>
          </div>
        </div>

        <div class="sm-side">
          <div class="card">
            <div class="card-head">
              <div class="wh-ic ok">🎯</div>
              <h2>Lô hệ thống chỉ định</h2>
            </div>
            <div class="batch-empty" id="batchEmpty">
              <div class="be-ic" style="font-size:32px;opacity:.45;margin-bottom:10px">📦</div>
              <p>Chọn thuốc để xem lô hệ thống chỉ định theo <b>FEFO</b>.</p>
            </div>
            <div class="batch-info" id="batchInfo">
              <div class="bi-tag">🎯 Lô cần lấy (FEFO)</div>
              <div class="bi-batch" id="biBatch">—</div>
              <div class="bi-rows">
                <div class="bi-row">
                  <span class="bi-lbl">📅 Hạn dùng</span>
                  <span class="bi-val"><span id="biExpiry">—</span><span id="biDays"></span></span>
                </div>
                <div class="bi-row">
                  <span class="bi-lbl">📦 Còn tồn trong lô</span>
                  <span class="bi-val" id="biQty">—</span>
                </div>
              </div>
            </div>
          </div>

          <div class="card">
            <div class="card-head">
              <div class="wh-ic">🕘</div>
              <h2>Lịch sử gần đây <small>7 ngày</small></h2>
            </div>
            <c:choose>
              <c:when test="${empty movementRows}">
                <div class="empty">Chưa có thao tác nào trong 7 ngày gần đây.</div>
              </c:when>
              <c:otherwise>
                <div class="mini-list">
                  <c:forEach var="r" items="${movementRows}" end="6">
                    <div class="mini-row">
                      <div class="mini-ic mi-${r.movementType}">
                        <c:choose>
                          <c:when test="${r.movementType == 'OUT'}">📤</c:when>
                          <c:when test="${r.movementType == 'EXPIRED'}">⏱️</c:when>
                          <c:otherwise>⚖️</c:otherwise>
                        </c:choose>
                      </div>
                      <div class="mini-body">
                        <div class="mini-med">${fn:escapeXml(r.medicineName)}</div>
                        <div class="mini-meta">Lô ${fn:escapeXml(r.batchNumber)} · ${r.createdAt}</div>
                      </div>
                      <div class="mini-qty ${r.quantity < 0 ? 'q-neg' : 'q-pos'}">${r.quantity}</div>
                    </div>
                  </c:forEach>
                </div>
              </c:otherwise>
            </c:choose>
          </div>
        </div>
      </div>
    </c:if>

    <!-- ════ TAB 4: THU HỒI KHẨN CẤP ════ -->
    <c:if test="${currentTab == 'recall'}">
      <div class="head">
        <div>
          <h1>Thu hồi <span>lô khẩn cấp</span></h1>
          <p>Tìm đúng lô theo số lô, kiểm tra vị trí kệ, và ngừng bán ngay lập tức khi có công văn thu hồi.</p>
        </div>
      </div>

      <div class="card">
        <div class="card-head"><div class="wh-ic">🔎</div><h2>Tìm lô cần thu hồi</h2></div>
        <div class="card-body">
          <form method="post" action="<%= ctx %>/warehouse-inventory">
            <input type="hidden" name="_csrf" value="${csrfToken}">
            <input type="hidden" name="uid" value="${staffUid}">
            <input type="hidden" name="tab" value="recall">
            <input type="hidden" name="action" value="recall-search">
            <div style="display:flex;gap:14px;flex-wrap:wrap;align-items:flex-end">
              <div style="flex:1;min-width:200px">
                <label style="font-size:12px;font-weight:800;color:var(--muted);text-transform:uppercase;margin-bottom:6px;display:block">Thuốc</label>
                <select name="medicineId" required style="width:100%;padding:11px;border:1.5px solid var(--border);border-radius:10px;font-family:inherit">
                  <option value="">— Chọn thuốc —</option>
                  <c:forEach var="m" items="${allMedicines}">
                    <option value="${m.medicineId}" ${param.medicineId == m.medicineId ? 'selected' : ''}>${m.medicineName}</option>
                  </c:forEach>
                </select>
              </div>
              <div style="flex:1;min-width:200px">
                <label style="font-size:12px;font-weight:800;color:var(--muted);text-transform:uppercase;margin-bottom:6px;display:block">Số lô</label>
                <input type="text" name="batchNumber" value="${fn:escapeXml(param.batchNumber)}" placeholder="Nhập số lô cần thu hồi…" required style="width:100%;padding:11px;border:1.5px solid var(--border);border-radius:10px;font-family:inherit">
              </div>
              <button type="submit" class="search button" style="padding:12px 24px;border:none;border-radius:10px;background:linear-gradient(135deg,var(--main),var(--deep));color:#fff;font-weight:800;cursor:pointer">🔍 Tìm lô</button>
            </div>
          </form>
        </div>
      </div>

      <c:if test="${not empty foundBatch}">
        <div class="card recall-card">
          <div class="card-head"><div class="wh-ic danger" style="background:rgba(255,255,255,.2);color:#fff">🚨</div><h2>Thông tin lô — xác nhận thu hồi</h2></div>
          <div class="card-body">
            <div class="info-grid">
              <div class="info-item"><div class="lbl">Số lô</div><div class="val">${foundBatch.batchNumber}</div></div>
              <div class="info-item"><div class="lbl">Tên thuốc</div><div class="val">${foundMedName}</div></div>
              <div class="info-item warn"><div class="lbl">Hạn dùng</div><div class="val">${foundBatch.expiryDate}</div></div>
              <div class="info-item warn"><div class="lbl">Còn tồn</div><div class="val">${foundBatch.currentQuantity}</div></div>
              <div class="info-item"><div class="lbl">Vị trí kệ</div><div class="val shelf">📍 ${foundShelf}</div></div>
              <div class="info-item"><div class="lbl">Trạng thái hiện tại</div><div class="val">${foundBatch.status}</div></div>
            </div>

            <c:if test="${foundBatch.status == 'ACTIVE'}">
              <form method="post" action="<%= ctx %>/warehouse-recall" id="recallForm">
                <input type="hidden" name="_csrf" value="${csrfToken}">
                <input type="hidden" name="uid" value="${staffUid}">
                <input type="hidden" name="action" value="confirm-recall">
                <input type="hidden" name="batchId" value="${foundBatch.batchId}">
                <div style="margin-bottom:16px">
                  <label style="font-size:12.5px;font-weight:800;color:var(--danger);display:block;margin-bottom:6px">Lý do thu hồi (bắt buộc)</label>
                  <textarea name="reason" id="reasonInput" placeholder="VD: Công văn số .../QLD-CL của Cục Quản lý Dược yêu cầu thu hồi lô do phát hiện lỗi chất lượng…" oninput="document.getElementById('confirmBtn').disabled = this.value.trim().length === 0;" required style="width:100%;min-height:80px;padding:12px;border:1.5px solid var(--border);border-radius:10px;font-family:inherit"></textarea>
                </div>
                <button type="submit" class="btn-danger-big" id="confirmBtn" disabled onclick="return confirm('XÁC NHẬN THU HỒI lô ${foundBatch.batchNumber}? Lô sẽ ngừng bán ngay lập tức.');">
                  🚨 Xác nhận Thu hồi
                </button>
              </form>
            </c:if>
          </div>
        </div>
      </c:if>

      <div class="card">
        <div class="card-head"><div class="wh-ic">📋</div><h2>Lịch sử thu hồi <small>(30 ngày gần nhất)</small></h2></div>
        <div class="tblwrap">
          <table>
            <thead><tr>
              <th>Số lô</th><th>Thuốc</th><th>Lý do</th><th>Người thu hồi</th><th>Thời gian</th>
            </tr></thead>
            <tbody>
            <c:choose>
              <c:when test="${empty history}">
                <tr><td colspan="5" class="empty">Chưa có lô nào bị thu hồi trong 30 ngày qua.</td></tr>
              </c:when>
              <c:otherwise>
                <c:forEach var="h" items="${history}">
                  <tr>
                    <td class="code">${h.batchNumber}</td>
                    <td>${h.medicineName}</td>
                    <td style="white-space:normal;max-width:280px">${fn:escapeXml(h.reason)}</td>
                    <td>${h.recalledBy}</td>
                    <td>${h.createdAt}</td>
                  </tr>
                </c:forEach>
              </c:otherwise>
            </c:choose>
            </tbody>
          </table>
        </div>
      </div>
    </c:if>

  </div>
</div>

<!-- Modal Chi tiết sản phẩm -->
<div class="dm-backdrop" id="dmBackdrop" onclick="if(event.target===this)closeDetail()">
  <div class="dm-box">
    <div class="dm-head">
      <div>
        <h3 id="dmTitle">Chi tiết sản phẩm</h3>
        <div class="sub" id="dmSub"></div>
      </div>
      <button type="button" class="dm-close" onclick="closeDetail()">✕</button>
    </div>
    <div class="dm-body" id="dmBody">
      <div class="dm-loading">Đang tải…</div>
    </div>
  </div>
</div>

<!-- Modal Quét Barcode -->
<div id="barcodeScanModal" style="display:none;position:fixed;inset:0;z-index:9700;background:rgba(11,22,40,.7);align-items:center;justify-content:center;padding:20px" onclick="if(event.target===this)closeBarcodeScan()">
  <div style="background:#fff;border-radius:18px;max-width:420px;width:100%;box-shadow:0 24px 70px rgba(0,0,0,.35);overflow:hidden">
    <div style="padding:16px 20px;background:linear-gradient(135deg,#0f766e,#042f2e);color:#fff;display:flex;align-items:center;justify-content:space-between">
      <h3 style="margin:0;font-size:16px;font-weight:800">📷 Quét mã vạch lô</h3>
      <button type="button" onclick="closeBarcodeScan()" style="background:rgba(255,255,255,.18);border:none;color:#fff;width:30px;height:30px;border-radius:99px;font-size:15px;cursor:pointer">✕</button>
    </div>
    <div style="padding:16px 20px">
      <div id="barcodeReaderBox" style="width:100%;min-height:260px;border-radius:12px;overflow:hidden;background:#0b1628"></div>
      <div id="barcodeScanStatus" style="margin-top:10px;font-size:12.5px;color:#64748b;text-align:center">Đưa mã vạch vào giữa khung hình.</div>
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/html5-qrcode@2.3.8/html5-qrcode.min.js" defer></script>
<script>
const _dmCtx = '<%= ctx %>';
const _dmUid = '${staffUid}';

function _dmEsc(s){ return (s==null?'':String(s)).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
function _dmField(label, value, full){
  const empty = value===null || value===undefined || value==='';
  return '<div class="dm-field'+(full?' full':'')+'"><span class="k">'+_dmEsc(label)+'</span>'
       + '<span class="v'+(empty?' empty':'')+'">'+(empty?'Chưa có dữ liệu':_dmEsc(value))+'</span></div>';
}
function openDetail(medicineId){
  document.getElementById('dmBackdrop').classList.add('show');
  document.getElementById('dmTitle').textContent = 'Chi tiết sản phẩm';
  document.getElementById('dmSub').textContent = '';
  document.getElementById('dmBody').innerHTML = '<div class="dm-loading">Đang tải…</div>';
  fetch(_dmCtx + '/warehouse-inventory?action=detail&id=' + medicineId + '&uid=' + encodeURIComponent(_dmUid))
    .then(r => r.json())
    .then(data => {
      if (data.error) { document.getElementById('dmBody').innerHTML = '<div class="dm-loading">Không tải được dữ liệu.</div>'; return; }
      const m = data.medicine, batches = data.batches || [];
      document.getElementById('dmTitle').textContent = m.medicineName;
      document.getElementById('dmSub').textContent = m.medicineCode + (m.genericName ? ' · ' + m.genericName : '');

      let html = '<div class="dm-grid">'
        + _dmField('Danh mục', m.categoryName)
        + _dmField('Nhà sản xuất', m.manufacturerName)
        + _dmField('Vị trí kệ', m.shelfName)
        + _dmField('Đơn vị', m.unit)
        + _dmField('Barcode', m.barcode)
        + _dmField('Số đăng ký', m.registrationNumber)
        + _dmField('Giá bán', Number(m.sellingPrice).toLocaleString('vi-VN') + 'đ')
        + _dmField('Tồn kho / Ngưỡng tối thiểu', m.totalStock + ' / ' + m.minInventory)
        + _dmField('Kê đơn (Rx)', m.isPrescriptionRequired ? 'Có — cần đơn thuốc' : 'Không')
        + _dmField('Quy cách đóng gói', m.packagingSpec)
        + _dmField('Liều dùng', m.dosage, true)
        + (m.dosageWarning ? _dmField('Cảnh báo liều dùng', m.dosageWarning) : '')
        + _dmField('Chống chỉ định', m.contraindications)
        + _dmField('Điều kiện bảo quản', m.storageConditions)
        + '</div>';

      html += '<div class="dm-sec-title">📦 Tất cả lô hàng (' + batches.length + ')</div>';
      if (batches.length === 0) {
        html += '<div class="empty">Chưa có lô nào cho thuốc này.</div>';
      } else {
        html += '<div class="dm-batches tblwrap"><table><thead><tr>'
          + '<th>Số lô</th><th>NSX</th><th>HSD</th><th style="text-align:right">Tồn / Nhập ban đầu</th><th>Trạng thái</th>'
          + '</tr></thead><tbody>';
        batches.forEach(b => {
          html += '<tr><td class="code">' + _dmEsc(b.batchNumber) + '</td>'
            + '<td>' + _dmEsc(b.importDate || '—') + '</td>'
            + '<td>' + _dmEsc(b.expiryDate || '—') + '</td>'
            + '<td class="num-cell">' + b.currentQuantity + ' / ' + b.initialQuantity + '</td>'
            + '<td><span class="dm-batch-status ' + _dmEsc(b.status) + '">' + _dmEsc(b.status) + '</span></td></tr>';
        });
        html += '</tbody></table></div>';
      }
      document.getElementById('dmBody').innerHTML = html;
    })
    .catch(() => { document.getElementById('dmBody').innerHTML = '<div class="dm-loading">Lỗi kết nối, thử lại sau.</div>'; });
}
function closeDetail(){ document.getElementById('dmBackdrop').classList.remove('show'); }
document.addEventListener('keydown', e => { if (e.key === 'Escape') closeDetail(); });

/* Movement script */
function toggleDirection(){
  var elem = document.getElementById('movementType');
  if(!elem) return;
  var mt = elem.value;
  var dRow = document.getElementById('directionRow');
  if(dRow) dRow.classList.toggle('show', mt === 'ADJUSTMENT');
}
function resetBatchPanel(msg){
  var bi = document.getElementById('batchInfo');
  var fn = document.getElementById('fefoNudge');
  if(bi) bi.classList.remove('show');
  if(fn) fn.classList.remove('show');
  var empty = document.getElementById('batchEmpty');
  if(empty){
    empty.style.display = 'block';
    empty.querySelector('p').innerHTML = msg || 'Chọn thuốc để xem lô hệ thống chỉ định theo <b>FEFO</b>.';
  }
}
function loadSuggestedBatch(){
  var mSel = document.getElementById('medicineSelect');
  if(!mSel) return;
  var medId = mSel.value;
  if(!medId){ resetBatchPanel(); return; }
  resetBatchPanel('Đang tải lô hệ thống chỉ định…');
  fetch(_dmCtx + '/warehouse-inventory?action=suggest-batch&medicineId=' + encodeURIComponent(medId))
    .then(function(r){ return r.json(); })
    .then(function(d){
      if(d.ok){
        var empty = document.getElementById('batchEmpty');
        if(empty) empty.style.display = 'none';
        document.getElementById('biBatch').textContent = d.batchNumber;
        document.getElementById('biExpiry').textContent = d.expiryDate;
        document.getElementById('biQty').textContent = d.currentQuantity;
        document.getElementById('batchInfo').classList.add('show');
        document.getElementById('fnBatch').textContent = d.batchNumber;
        document.getElementById('fefoNudge').classList.add('show');
      } else {
        resetBatchPanel(d.message || 'Không có lô nào khả dụng cho thuốc này.');
      }
    })
    .catch(function(){ resetBatchPanel('Không tải được gợi ý lô.'); });
}

let barcodeScanner = null;
function openBarcodeScan() {
  document.getElementById('barcodeScanModal').style.display = 'flex';
  const status = document.getElementById('barcodeScanStatus');
  status.textContent = 'Đưa mã vạch vào giữa khung hình…';
  if (typeof Html5Qrcode === 'undefined') {
    status.textContent = '⚠️ Không tải được thư viện quét mã vạch.';
    return;
  }
  barcodeScanner = new Html5Qrcode('barcodeReaderBox');
  const config = { fps: 10, qrbox: { width: 260, height: 140 } };
  barcodeScanner.start(
    { facingMode: 'environment' }, config,
    (decodedText) => {
      document.getElementById('enteredBatchNumber').value = decodedText;
      closeBarcodeScan();
    }, () => {}
  ).catch(err => { status.textContent = '⚠️ Không mở được camera: ' + (err.message || err); });
}
function closeBarcodeScan() {
  document.getElementById('barcodeScanModal').style.display = 'none';
  if (barcodeScanner) {
    const s = barcodeScanner; barcodeScanner = null;
    s.stop().then(() => s.clear()).catch(() => {});
  }
}
toggleDirection();
</script>
</body>
</html>
