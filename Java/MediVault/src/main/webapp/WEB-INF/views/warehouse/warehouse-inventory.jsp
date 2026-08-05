<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%--
  warehouse-inventory.jsp — Quản lý tồn kho (Warehouse Console)

  Thiết kế lại 2026-08-02 theo hướng "một bảng dữ liệu là trung tâm":

  • BỎ cột phải chứa 2 bảng "Lô cận hạn" / "Lô đã hết hạn". Chúng ép bảng chính
    xuống 65% bề ngang, mà nội dung thì trùng ý nghĩa với 2 thẻ KPI phía trên.
    Nay 2 tập dữ liệu đó thành 2 lát cắt của CHÍNH bảng trung tâm (segmented
    control) — mở ra là chiếm trọn bề ngang, đủ chỗ cho tên thuốc dài.
  • 4 thẻ KPI = 4 nút lọc. Con số trên thẻ chính là số dòng bảng sẽ hiển thị,
    nên không còn cảnh "thẻ nói 12, bảng hiện 9" (thẻ đếm LÔ, bảng đếm THUỐC).
  • Lọc/tìm/sắp xếp/phân trang chạy hoàn toàn client-side trên tập dữ liệu đã
    render sẵn: gõ tới đâu lọc tới đó, 0 round-trip. Servlet vẫn nhận ?q= như cũ
    (deep-link/không-JS vẫn chạy) nên không đụng gì tới business logic.
  • Cột "Lô gần nhất" + "Hạn dùng" lấy từ nearestBatchNo/nearestExpiry — 2 field
    DAO đã trả về từ trước nhưng giao diện cũ chưa bao giờ hiển thị.

  Yêu cầu từ servlet: staffAcc, staffUid, medicines, medNameMap, catNameMap,
  totalActive, lowStockCount, expiringBatches, expiredBatches, keyword.
--%>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) request.getAttribute("staffAcc");
    String ctx = request.getContextPath();
    if (acc == null) { response.sendRedirect(ctx + "/warehouse-login"); return; }
    String fullName = acc.getFullName() != null && !acc.getFullName().isEmpty() ? acc.getFullName() : acc.getUsername();
    String initials = fullName.substring(0,1).toUpperCase();
    String uid = (String) request.getAttribute("staffUid");
    String activeNav = "inventory";
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
<link rel="stylesheet" href="<%= ctx %>/css/warehouse-portal.css?v=11">
<style>
a{text-decoration:none;color:inherit}

/* ── Bề rộng cột (table-layout:fixed) ─────────────────────────────────────
   Cố định bề rộng để khi lọc/phân trang bảng KHÔNG nhảy cột — mắt đang quét
   dọc một cột không bị mất dấu mỗi lần đổi trang. Kéo mép cột vẫn ghi đè được.

   LƯU Ý: các số dưới đây phải khớp với hằng COLW trong <script> cuối trang.
   `table-layout:fixed` KHÔNG tôn trọng min-width của cột: khi tổng bề rộng chỉ
   định vượt quá bề ngang bảng, cột `width:auto` (tên thuốc) bị bóp về gần 0 chứ
   không đẩy bảng rộng ra. Vì vậy JS tính min-width cho cả BẢNG theo đúng bộ cột
   đang bật — thiếu bước này, ở màn hẹp cột "Thuốc" biến mất trong khi các cột
   phụ vẫn giữ nguyên bề rộng.

   Bộ cột mặc định (ẩn "Mã thuốc" + "Lô gần nhất") vừa khít vùng nội dung ở màn
   1280px — độ phân giải phổ biến nhất của máy quầy. 2 cột đó bật lại được ở
   popover "Cột" và được ghi nhớ cho lần sau. */
.c-check{width:40px}   .c-code{width:96px}   .c-med{width:auto;min-width:240px}
.c-cat{width:120px}    .c-stock{width:118px} .c-batch{width:112px}
.c-exp{width:132px}    .c-status{width:110px} .c-price{width:108px}
.c-act{width:96px}
.c-bnum{width:150px}   .c-bqty{width:110px}
#tblBatch{min-width:760px}

/* Ẩn/hiện cột theo popover "Cột hiển thị" */
.wh-table.h-code  .c-code,  .wh-table.h-cat   .c-cat,
.wh-table.h-batch .c-batch, .wh-table.h-exp   .c-exp,
.wh-table.h-price .c-price{display:none}

/* Bỏ nút ✕ mặc định của input[type=search] — đã có nút xoá riêng, 2 cái chồng nhau */
#q::-webkit-search-decoration,#q::-webkit-search-cancel-button{-webkit-appearance:none;appearance:none}

/* Chip "còn N ngày" cạnh hạn dùng — mức độ khẩn đọc được mà không cần nhẩm lịch */
.exp-wrap{display:flex;flex-direction:column;gap:3px}
.exp-d{font-weight:700;font-variant-numeric:tabular-nums;color:#0F172A}
.exp-chip{font-size:11px;font-weight:750;color:var(--muted)}
.exp-chip.warn{color:var(--gold)} .exp-chip.crit{color:#6D28D9} .exp-chip.dead{color:var(--danger)}
.exp-none{color:#9AA8A3;font-style:italic;font-weight:500}

/* Rx: thuốc kê đơn — nhãn nhỏ cạnh tên, thủ kho cần biết khi soạn hàng */
.rx{display:inline-block;margin-left:6px;padding:1px 5px;border-radius:5px;background:#EEF2FF;color:#4338CA;
    font-size:9.5px;font-weight:800;letter-spacing:.04em;vertical-align:middle}

/* ── Custom Select Dropdown UI (Đồng bộ style với ứng dụng) ────────── */
.wh-custom-select{position:relative;display:inline-block}
.wh-cselect-btn{height:40px;padding:0 14px;border:1px solid var(--border,#CBD5E1);border-radius:var(--wh-r-ctl,12px);
  font-family:inherit;font-size:13px;font-weight:650;color:var(--ink,#1E293B);background:var(--white,#FFFFFF);
  cursor:pointer;outline:none;display:inline-flex;align-items:center;justify-content:space-between;gap:10px;
  transition:all .15s ease;user-select:none}
.wh-cselect-btn:hover{border-color:#94A3B8;background:#F8FAFC}
.wh-cselect-btn.open{border-color:var(--main,#0D9488);box-shadow:0 0 0 3px rgba(13,148,136,.15);background:#FFFFFF}
.wh-cselect-btn .caret{width:14px;height:14px;stroke:#64748B;transition:transform .15s ease;flex-shrink:0}
.wh-cselect-btn.open .caret{transform:rotate(180deg)}

.wh-cselect-menu{position:absolute;right:0;top:calc(100% + 6px);z-index:70;min-width:230px;padding:6px;
  background:#FFFFFF;border:1px solid var(--border,#E2E8F0);border-radius:14px;
  box-shadow:0 10px 25px -5px rgba(15,23,42,0.12), 0 8px 10px -6px rgba(15,23,42,0.04);
  display:none;flex-direction:column;gap:2px}
.wh-cselect-menu.open{display:flex;animation:wh-pop-in 140ms cubic-bezier(.4,0,.2,1)}

.wh-custom-select.wh-dropup .wh-cselect-menu{top:auto;bottom:calc(100% + 6px)}
.wh-custom-select.wh-dropup .wh-cselect-menu.open{animation:wh-pop-up-in 140ms cubic-bezier(.4,0,.2,1)}
@keyframes wh-pop-up-in{from{opacity:0;transform:translateY(6px) scale(.98)}to{opacity:1;transform:none}}

.wh-cselect-opt{display:flex;align-items:center;justify-content:space-between;padding:9px 12px;border-radius:8px;
  font-size:13px;font-weight:600;color:#334155;cursor:pointer;transition:all .12s ease}
.wh-cselect-opt:hover{background:#F1F5F9;color:#0F172A}
.wh-cselect-opt.is-selected{background:#E6F4F1;color:var(--main,#0F766E);font-weight:750}
.wh-cselect-opt.is-selected::after{content:"✓";font-weight:800;font-size:13px;margin-left:8px;color:var(--main,#0F766E)}</style>
<meta name="csrf-token" content="${csrfToken}">
<script src="<%= ctx %>/js/csrf.js"></script>
</head>
<body class="wh">
<%@ include file="/WEB-INF/views/icons.jsp" %>
<%@ include file="warehouse-sidebar.jsp" %>

<div class="main">
  <header class="wh-topbar">
    <div class="crumb">Kho hàng</div>
    <%-- Điều hướng giữa 4 trang con của nhóm "Quản lý tồn kho" nằm ở topbar, tách bạch
         với bộ lọc trong toolbar bên dưới — 2 hàng tab chồng nhau là nguyên nhân chính
         khiến người dùng không biết mình đang "đổi trang" hay "đổi bộ lọc". --%>
    <nav class="tb-nav">
      <a class="on" href="<%= ctx %>/warehouse-inventory">Tồn kho</a>
      <a href="<%= ctx %>/warehouse-stock-movement">Điều chỉnh</a>
      <a href="<%= ctx %>/warehouse-reorder">Gợi ý đặt hàng</a>
      <a href="<%= ctx %>/warehouse-recall">Thu hồi</a>
    </nav>
    <div class="right">
      <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc của <%= fullName %>"><%= initials %></a>
    </div>
  </header>

  <div class="wh-shell wh-anim">

    <!-- ══ 1 · Header trang ══════════════════════════════════════════════ -->
    <div class="wh-head">
      <div>
        <h1>Quản lý tồn kho</h1>
        <p class="sub">Danh mục thuốc, tồn kho thực tế theo lô, ngưỡng tối thiểu và cảnh báo hạn dùng.</p>
      </div>
      <div class="wh-head-actions">
        <a class="wh-btn wh-btn-primary" href="<%= ctx %>/warehouse-import">
          <svg><use href="#ic-plus"/></svg> Nhập kho
        </a>
        <button type="button" class="wh-btn" id="btnExport">
          <svg><use href="#ic-download"/></svg> Xuất Excel
        </button>
        <button type="button" class="wh-btn wh-btn-icon" id="btnRefresh" title="Làm mới dữ liệu" aria-label="Làm mới dữ liệu">
          <svg><use href="#ic-refresh"/></svg>
        </button>
      </div>
    </div>

    <!-- ══ 2 · KPI — đồng thời là 4 nút lọc của bảng bên dưới ═════════════ -->
    <div class="wh-kpis" role="group" aria-label="Lọc nhanh theo tình trạng kho">
      <button type="button" class="wh-kpi k-total is-active" data-view="all" aria-pressed="true">
        <span class="ic"><svg><use href="#ic-pill"/></svg></span>
        <span class="body">
          <span class="num">${totalActive}</span>
          <span class="lbl">Thuốc đang kinh doanh</span>
          <span class="hint">Toàn bộ danh mục còn hoạt động</span>
        </span>
      </button>
      <button type="button" class="wh-kpi k-low ${lowStockCount == 0 ? 'is-zero' : ''}" data-view="low" aria-pressed="false">
        <span class="ic"><svg><use href="#ic-trend-down"/></svg></span>
        <span class="body">
          <span class="num">${lowStockCount}</span>
          <span class="lbl">Sắp hết hàng</span>
          <span class="hint">Tồn đã chạm ngưỡng tối thiểu</span>
        </span>
      </button>
      <button type="button" class="wh-kpi k-soon ${expiringBatches.size() == 0 ? 'is-zero' : ''}" data-view="soon" aria-pressed="false">
        <span class="ic"><svg><use href="#ic-clock-alert"/></svg></span>
        <span class="body">
          <span class="num">${expiringBatches.size()}</span>
          <span class="lbl">Lô cận hạn</span>
          <span class="hint">Hết hạn trong vòng 30 ngày</span>
        </span>
      </button>
      <button type="button" class="wh-kpi k-dead ${expiredBatches.size() == 0 ? 'is-zero' : ''}" data-view="dead" aria-pressed="false">
        <span class="ic"><svg><use href="#ic-ban"/></svg></span>
        <span class="body">
          <span class="num">${expiredBatches.size()}</span>
          <span class="lbl">Lô đã hết hạn</span>
          <span class="hint">Cần xuất huỷ khỏi kho</span>
        </span>
      </button>
    </div>

    <!-- ══ 3 · Toolbar dính ══════════════════════════════════════════════ -->
    <div class="wh-toolbar" id="toolbar">
      <%-- Nhóm nút bật/tắt (aria-pressed) chứ không phải role="tablist": các lát cắt
           này đổ về CÙNG một vùng bảng, không có nhiều tabpanel để chuyển qua lại. --%>
      <div class="wh-seg" role="group" aria-label="Lát cắt dữ liệu">
        <button type="button" data-view="all"  aria-pressed="true">Tất cả <span class="cnt" id="cAll">0</span></button>
        <button type="button" data-view="low"  aria-pressed="false" class="s-low">Sắp hết <span class="cnt" id="cLow">0</span></button>
        <button type="button" data-view="out"  aria-pressed="false" class="s-out">Hết hàng <span class="cnt" id="cOut">0</span></button>
        <button type="button" data-view="soon" aria-pressed="false" class="s-soon" title="Các lô hết hạn trong 30 ngày tới">Cận hạn <span class="cnt">${expiringBatches.size()}</span></button>
        <button type="button" data-view="dead" aria-pressed="false" class="s-dead" title="Các lô đã quá hạn còn tồn trong kho">Quá hạn <span class="cnt">${expiredBatches.size()}</span></button>
      </div>

      <div class="wh-toolbar-right">
        <div class="wh-search" id="searchBox">
          <svg class="lead"><use href="#ic-search"/></svg>
          <input type="search" id="q" value="${fn:escapeXml(keyword)}" autocomplete="off"
                 placeholder="Tìm thuốc, mã, hoạt chất, barcode…" aria-label="Tìm trong bảng">
          <button type="button" class="clear" id="qClear" aria-label="Xoá từ khoá"><svg><use href="#ic-x"/></svg></button>
        </div>

        <div class="wh-custom-select" id="sortSelectWrap">
          <button type="button" class="wh-cselect-btn" id="btnSort" aria-expanded="false" aria-haspopup="true" aria-label="Sắp xếp danh sách">
            <span class="lbl" id="sortLabel">Hạn dùng gần nhất → xa nhất</span>
            <svg class="caret"><use href="#ic-chevron-down"/></svg>
          </button>
          <div class="wh-cselect-menu" id="popSort" role="menu">
            <div class="wh-cselect-opt is-selected" data-value="exp:asc">Hạn dùng gần nhất → xa nhất</div>
            <div class="wh-cselect-opt" data-value="exp:desc">Hạn dùng xa nhất → gần nhất</div>
            <div class="wh-cselect-opt" data-value="batch:asc">Lô gần nhất (A → Z)</div>
            <div class="wh-cselect-opt" data-value="batch:desc">Lô gần nhất (Z → A)</div>
            <div class="wh-cselect-opt" data-value="name:asc">Tên thuốc A → Z</div>
            <div class="wh-cselect-opt" data-value="name:desc">Tên thuốc Z → A</div>
            <div class="wh-cselect-opt" data-value="stock:asc">Tồn kho thấp → cao</div>
            <div class="wh-cselect-opt" data-value="stock:desc">Tồn kho cao → thấp</div>
            <div class="wh-cselect-opt" data-value="price:asc">Giá bán thấp → cao</div>
            <div class="wh-cselect-opt" data-value="price:desc">Giá bán cao → thấp</div>
          </div>
        </div>

        <div class="wh-pop-wrap">
          <button type="button" class="wh-btn" id="btnCols" aria-expanded="false" aria-haspopup="true">
            <svg><use href="#ic-columns"/></svg> Cột
          </button>
          <div class="wh-pop" id="popCols" role="menu">
            <div class="ttl">Cột hiển thị</div>
            <label><input type="checkbox" data-col="code"  checked> Mã thuốc</label>
            <label><input type="checkbox" data-col="cat"   checked> Danh mục</label>
            <label><input type="checkbox" data-col="batch" checked> Lô gần nhất</label>
            <label><input type="checkbox" data-col="exp"   checked> Hạn dùng</label>
            <label><input type="checkbox" data-col="price" checked> Giá bán</label>
          </div>
        </div>
      </div>
    </div>

    <!-- ══ 4 · Bảng dữ liệu ══════════════════════════════════════════════ -->
    <div class="wh-tablecard">
      <%-- data-fit="manual": trang này tự tính min-width bảng theo bộ cột đang bật
           (xem hằng COLW ở cuối trang), nên warehouse-ui.js không đụng vào. --%>
      <div class="wh-tablescroll" data-fit="manual">

        <!-- ── 4a · Bảng THUỐC (lát cắt: Tất cả / Sắp hết / Hết hàng) ── -->
        <table class="wh-table" id="tblMed">
          <thead>
            <tr>
              <th class="c-check"><input type="checkbox" id="checkAll" aria-label="Chọn tất cả dòng đang hiển thị"></th>
              <th class="c-code sortable"  data-key="code"  aria-sort="none"><span class="th-in">Mã <svg class="caret"><use href="#ic-chevron-down"/></svg></span></th>
              <th class="c-med sortable"   data-key="name"  aria-sort="none"><span class="th-in">Thuốc <svg class="caret"><use href="#ic-chevron-down"/></svg></span></th>
              <th class="c-cat">Danh mục</th>
              <th class="c-stock sortable" data-key="stock" aria-sort="none" style="text-align:right"><span class="th-in">Tồn / Tối thiểu <svg class="caret"><use href="#ic-chevron-down"/></svg></span></th>
              <th class="c-batch sortable" data-key="batch" aria-sort="none"><span class="th-in">Lô gần nhất <svg class="caret"><use href="#ic-chevron-down"/></svg></span></th>
              <th class="c-exp sortable"   data-key="exp"   aria-sort="ascending"><span class="th-in">Hạn dùng <svg class="caret"><use href="#ic-chevron-down"/></svg></span></th>
              <th class="c-status">Trạng thái</th>
              <th class="c-price sortable" data-key="price" aria-sort="none" style="text-align:right"><span class="th-in">Giá bán <svg class="caret"><use href="#ic-chevron-down"/></svg></span></th>
              <th class="c-act" style="text-align:right">Thao tác</th>
            </tr>
          </thead>
          <tbody id="bodyMed">
            <c:forEach var="m" items="${medicines}">
              <c:set var="st" value="${m.totalStock == 0 ? 'out' : (m.minInventory > 0 && m.totalStock <= m.minInventory ? 'low' : 'ok')}"/>
              <tr data-id="${m.medicineId}"
                  data-name="${fn:escapeXml(m.medicineName)}"
                  data-code="${fn:escapeXml(m.medicineCode)}"
                  data-generic="${fn:escapeXml(m.genericName)}"
                  data-barcode="${fn:escapeXml(m.barcode)}"
                  data-cat="${fn:escapeXml(catNameMap[m.categoryId])}"
                  data-stock="${m.totalStock}" data-min="${m.minInventory}"
                  data-price="${m.sellingPrice}" data-exp="${m.nearestExpiry}"
                  data-batch="${fn:escapeXml(m.nearestBatchNo)}"
                  data-unit="${fn:escapeXml(m.unit)}" data-status="${st}">
                <td class="c-check"><input type="checkbox" class="rowck" aria-label="Chọn ${fn:escapeXml(m.medicineName)}"></td>
                <td class="c-code"><span class="wh-code">${m.medicineCode}</span></td>
                <td class="c-med">
                  <div class="wh-name" title="${fn:escapeXml(m.medicineName)}">${m.medicineName}<c:if test="${m.prescriptionRequired}"><span class="rx">Rx</span></c:if></div>
                  <c:if test="${not empty m.genericName}"><div class="wh-sub" title="${fn:escapeXml(m.genericName)}">${m.genericName}</div></c:if>
                </td>
                <td class="c-cat"><c:choose>
                    <c:when test="${not empty catNameMap[m.categoryId]}">${catNameMap[m.categoryId]}</c:when>
                    <c:otherwise><span class="exp-none">—</span></c:otherwise>
                  </c:choose></td>
                <td class="c-stock num">
                  <div><span class="wh-stock ${st == 'low' ? 'is-low' : (st == 'out' ? 'is-out' : '')}">${m.totalStock}</span>
                       <span class="wh-min">/ ${m.minInventory}</span></div>
                  <div class="wh-bar ${st == 'low' ? 'is-low' : (st == 'out' ? 'is-out' : '')}"><i data-fill></i></div>
                </td>
                <td class="c-batch"><c:choose>
                    <c:when test="${not empty m.nearestBatchNo}"><span class="wh-code">${m.nearestBatchNo}</span></c:when>
                    <c:otherwise><span class="exp-none">Chưa có lô</span></c:otherwise>
                  </c:choose></td>
                <td class="c-exp"><c:choose>
                    <c:when test="${not empty m.nearestExpiry}">
                      <div class="exp-wrap"><span class="exp-d">${m.nearestExpiry}</span><span class="exp-chip"></span></div>
                    </c:when>
                    <c:otherwise><span class="exp-none">—</span></c:otherwise>
                  </c:choose></td>
                <td class="c-status">
                  <c:choose>
                    <c:when test="${st == 'out'}"><span class="wh-badge out">Hết hàng</span></c:when>
                    <c:when test="${st == 'low'}"><span class="wh-badge low">Sắp hết</span></c:when>
                    <c:otherwise><span class="wh-badge ok">Đủ hàng</span></c:otherwise>
                  </c:choose>
                </td>
                <td class="c-price wh-price"><fmt:formatNumber value="${m.sellingPrice}" type="number" maxFractionDigits="0"/>đ</td>
                <td class="c-act">
                  <div class="wh-acts">
                    <button type="button" class="wh-act" onclick="openDetail(${m.medicineId})" title="Xem chi tiết &amp; toàn bộ lô" aria-label="Xem chi tiết ${fn:escapeXml(m.medicineName)}"><svg><use href="#ic-eye"/></svg></button>
                    <a class="wh-act" href="<%= ctx %>/warehouse-stock-movement?medicineId=${m.medicineId}" title="Điều chỉnh / xuất kho" aria-label="Điều chỉnh kho"><svg><use href="#ic-history"/></svg></a>
                    <a class="wh-act" href="<%= ctx %>/warehouse-import?medicineId=${m.medicineId}" title="Nhập thêm hàng" aria-label="Nhập thêm ${fn:escapeXml(m.medicineName)}"><svg><use href="#ic-cart"/></svg></a>
                  </div>
                </td>
              </tr>
            </c:forEach>
          </tbody>
        </table>

        <!-- ── 4b · Bảng LÔ (lát cắt: Lô cận hạn / Lô hết hạn) ──
             Cận hạn & hết hạn là sự kiện ở cấp LÔ, không phải cấp thuốc: một thuốc có thể
             vừa còn lô tốt vừa có lô sắp hỏng. Ép chúng vào bảng thuốc sẽ phải chọn "đại
             diện" 1 lô và giấu phần còn lại — nên 2 lát cắt này đổi luôn bộ cột. -->
        <table class="wh-table" id="tblBatch" hidden>
          <thead>
            <tr>
              <th class="c-bnum">Số lô</th>
              <th class="c-med">Thuốc</th>
              <th class="c-bqty num" style="text-align:right">Tồn của lô</th>
              <th class="c-exp">Hạn dùng</th>
              <th class="c-status">Trạng thái</th>
              <th class="c-act" style="text-align:right">Thao tác</th>
            </tr>
          </thead>
          <tbody id="bodyBatch">
            <c:forEach var="b" items="${expiringBatches}">
              <tr data-kind="soon" data-name="${fn:escapeXml(medNameMap[b.medicineId])}"
                  data-code="${fn:escapeXml(b.batchNumber)}" data-generic="" data-barcode=""
                  data-stock="${b.currentQuantity}" data-exp="${b.expiryDate}" data-id="${b.medicineId}">
                <td class="c-bnum"><span class="wh-code">${b.batchNumber}</span></td>
                <td class="c-med"><div class="wh-name">${medNameMap[b.medicineId]}</div></td>
                <td class="c-bqty num"><span class="wh-stock">${b.currentQuantity}</span></td>
                <td class="c-exp"><div class="exp-wrap"><span class="exp-d">${b.expiryDate}</span><span class="exp-chip"></span></div></td>
                <td class="c-status"><span class="wh-badge soon">Cận hạn</span></td>
                <td class="c-act">
                  <div class="wh-acts">
                    <button type="button" class="wh-act" onclick="openDetail(${b.medicineId})" title="Xem chi tiết thuốc" aria-label="Xem chi tiết ${fn:escapeXml(medNameMap[b.medicineId])}"><svg><use href="#ic-eye"/></svg></button>
                    <a class="wh-act a-warn" href="<%= ctx %>/warehouse-stock-movement?medicineId=${b.medicineId}" title="Xuất bán ưu tiên / điều chỉnh" aria-label="Ưu tiên xuất lô ${fn:escapeXml(b.batchNumber)}"><svg><use href="#ic-arrow-right"/></svg></a>
                    <a class="wh-act" href="<%= ctx %>/warehouse-import?medicineId=${b.medicineId}" title="Nhập thêm hàng" aria-label="Nhập thêm ${fn:escapeXml(medNameMap[b.medicineId])}"><svg><use href="#ic-cart"/></svg></a>
                  </div>
                </td>
              </tr>
            </c:forEach>
            <c:forEach var="b" items="${expiredBatches}">
              <tr data-kind="dead" data-name="${fn:escapeXml(medNameMap[b.medicineId])}"
                  data-code="${fn:escapeXml(b.batchNumber)}" data-generic="" data-barcode=""
                  data-stock="${b.currentQuantity}" data-exp="${b.expiryDate}" data-id="${b.medicineId}">
                <td class="c-bnum"><span class="wh-code">${b.batchNumber}</span></td>
                <td class="c-med"><div class="wh-name">${medNameMap[b.medicineId]}</div></td>
                <td class="c-bqty num"><span class="wh-stock is-out">${b.currentQuantity}</span></td>
                <td class="c-exp"><div class="exp-wrap"><span class="exp-d">${b.expiryDate}</span><span class="exp-chip"></span></div></td>
                <td class="c-status"><span class="wh-badge dead">Hết hạn</span></td>
                <td class="c-act">
                  <div class="wh-acts">
                    <button type="button" class="wh-act" onclick="openDetail(${b.medicineId})" title="Xem chi tiết thuốc" aria-label="Xem chi tiết ${fn:escapeXml(medNameMap[b.medicineId])}"><svg><use href="#ic-eye"/></svg></button>
                    <a class="wh-act a-danger" href="<%= ctx %>/warehouse-stock-movement?medicineId=${b.medicineId}" title="Xuất huỷ khỏi kho" aria-label="Xuất huỷ lô ${fn:escapeXml(b.batchNumber)}"><svg><use href="#ic-ban"/></svg></a>
                    <a class="wh-act" href="<%= ctx %>/warehouse-import?medicineId=${b.medicineId}" title="Nhập thêm hàng bù lại" aria-label="Nhập thêm bù lại ${fn:escapeXml(medNameMap[b.medicineId])}"><svg><use href="#ic-cart"/></svg></a>
                  </div>
                </td>
              </tr>
            </c:forEach>
          </tbody>
        </table>

        <!-- ── Trạng thái rỗng: thấp, có ngữ cảnh, luôn kèm bước tiếp theo ── -->
        <div class="wh-empty" id="emptyState" hidden>
          <div class="art" id="emptyArt">🔍</div>
          <div class="t" id="emptyTitle">Không tìm thấy kết quả</div>
          <div class="d" id="emptyDesc">Thử bỏ bớt từ khoá hoặc chuyển sang lát cắt khác.</div>
          <button type="button" class="wh-btn" id="emptyReset">Xoá bộ lọc</button>
        </div>
      </div>

      <div class="wh-pager" id="pager">
        <div class="info" id="pagerInfo"></div>
        <div class="nav" id="pagerNav"></div>
        <div class="wh-custom-select wh-dropup" id="pageSizeSelectWrap">
          <button type="button" class="wh-cselect-btn" id="btnPageSize" aria-expanded="false" aria-haspopup="true" aria-label="Số dòng mỗi trang">
            <span class="lbl" id="pageSizeLabel">25 dòng</span>
            <svg class="caret"><use href="#ic-chevron-down"/></svg>
          </button>
          <div class="wh-cselect-menu" id="popPageSize" role="menu">
            <div class="wh-cselect-opt" data-value="15">15 dòng</div>
            <div class="wh-cselect-opt is-selected" data-value="25">25 dòng</div>
            <div class="wh-cselect-opt" data-value="50">50 dòng</div>
            <div class="wh-cselect-opt" data-value="100">100 dòng</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Thanh hành động hàng loạt — chỉ hiện khi có dòng được chọn -->
    <div class="wh-selbar" id="selBar" role="status">
      <span class="n">Đã chọn <b id="selCount">0</b> thuốc</span>
      <span class="sp">
        <button type="button" class="wh-btn" id="btnExportSel"><svg><use href="#ic-download"/></svg> Xuất danh sách</button>
        <button type="button" class="wh-btn" id="btnClearSel"><svg><use href="#ic-x"/></svg> Bỏ chọn</button>
      </span>
    </div>

  </div>
</div>

<!-- ══ Drawer chi tiết sản phẩm — trượt từ phải, giữ nguyên ngữ cảnh bảng ══ -->
<div class="wh-scrim" id="scrim"></div>
<aside class="wh-drawer" id="drawer" role="dialog" aria-modal="true" aria-labelledby="dwTitle" aria-hidden="true">
  <div class="wh-drawer-head">
    <div style="min-width:0">
      <h3 id="dwTitle">Chi tiết sản phẩm</h3>
      <div class="sub" id="dwSub">Đang tải…</div>
    </div>
    <button type="button" class="wh-btn wh-btn-icon wh-btn-ghost" id="dwClose" aria-label="Đóng"><svg><use href="#ic-x"/></svg></button>
  </div>
  <div class="wh-drawer-body" id="dwBody"></div>
  <div class="wh-drawer-foot">
    <a class="wh-btn wh-btn-primary" id="dwMove" href="#"><svg><use href="#ic-history"/></svg> Điều chỉnh kho</a>
    <a class="wh-btn" id="dwOrder" href="#"><svg><use href="#ic-cart"/></svg> Nhập thêm hàng</a>
  </div>
</aside>

<script>
(function () {
  'use strict';
  var CTX = '<%= ctx %>';
  var UID = '<%= uid == null ? "" : uid %>';

  var tblMed   = document.getElementById('tblMed');
  var tblBatch = document.getElementById('tblBatch');
  var medRows   = Array.prototype.slice.call(document.getElementById('bodyMed').rows);
  var batchRows = Array.prototype.slice.call(document.getElementById('bodyBatch').rows);
  var bodyMed   = document.getElementById('bodyMed');
  var bodyBatch = document.getElementById('bodyBatch');

  var state = { view:'all', q:'', sortKey:'exp', sortDir:'asc', page:1, size:25 };
  var selected = new Set();

  /* ── Hạn dùng: tính "còn N ngày" một lần lúc tải, cho cả 2 bảng ─────────── */
  var MS = 86400000;
  var today = new Date(); today.setHours(0,0,0,0);
  function daysTo(iso){
    if (!iso) return null;
    var d = new Date(iso + 'T00:00:00');
    if (isNaN(d)) return null;
    return Math.round((d - today) / MS);
  }
  function paintExpiry(rows){
    rows.forEach(function(tr){
      var chip = tr.querySelector('.exp-chip');
      if (!chip) return;
      var n = daysTo(tr.dataset.exp);
      if (n === null) { chip.textContent = ''; return; }
      if (n < 0)       { chip.textContent = 'Quá hạn ' + Math.abs(n) + ' ngày'; chip.className = 'exp-chip dead'; }
      else if (n === 0){ chip.textContent = 'Hết hạn hôm nay';                  chip.className = 'exp-chip dead'; }
      else if (n <= 30){ chip.textContent = 'Còn ' + n + ' ngày';               chip.className = 'exp-chip crit'; }
      else if (n <= 90){ chip.textContent = 'Còn ' + n + ' ngày';               chip.className = 'exp-chip warn'; }
      else             { chip.textContent = 'Còn ' + n + ' ngày';               chip.className = 'exp-chip'; }
    });
  }
  paintExpiry(medRows); paintExpiry(batchRows);

  /* Thanh tồn kho: tỉ lệ tồn / (ngưỡng × 2) — ngưỡng nằm đúng giữa thanh, nên
     "quá nửa thanh" = an toàn, "dưới nửa" = cần để mắt. Không có ngưỡng thì đầy. */
  medRows.forEach(function(tr){
    var fill = tr.querySelector('[data-fill]');
    if (!fill) return;
    var stock = +tr.dataset.stock, min = +tr.dataset.min;
    var pct = min > 0 ? Math.min(100, Math.round(stock / (min * 2) * 100)) : (stock > 0 ? 100 : 0);
    fill.style.width = pct + '%';
  });

  /* ── Đếm lại từ chính dữ liệu đã render ────────────────────────────────
     Servlet vẫn lọc sẵn khi có ?q= (deep-link cũ), nên nếu lấy số từ
     ${totalActive}/${lowStockCount} thì thẻ KPI sẽ đếm toàn kho trong khi bảng
     chỉ hiển thị tập con — đúng cái lệch số mà bản thiết kế này muốn xoá bỏ.
     Đếm tại chỗ ⇒ thẻ, chip và bảng luôn nói cùng một con số. */
  var nLow = medRows.filter(function(r){ return r.dataset.status === 'low'; }).length;
  var nOut = medRows.filter(function(r){ return r.dataset.status === 'out'; }).length;
  document.getElementById('cAll').textContent = medRows.length;
  document.getElementById('cLow').textContent = nLow;
  document.getElementById('cOut').textContent = nOut;
  (function syncKpis(){
    var vals = { all: medRows.length, low: nLow,
                 soon: batchRows.filter(function(r){ return r.dataset.kind === 'soon'; }).length,
                 dead: batchRows.filter(function(r){ return r.dataset.kind === 'dead'; }).length };
    document.querySelectorAll('.wh-kpi').forEach(function(k){
      var v = vals[k.dataset.view];
      k.querySelector('.num').textContent = v;
      k.classList.toggle('is-zero', v === 0 && k.dataset.view !== 'all');
    });
  })();

  /* ── Lọc + sắp xếp + phân trang ────────────────────────────────────────── */
  function isBatchView(){ return state.view === 'soon' || state.view === 'dead'; }

  // Bỏ dấu tiếng Việt trước khi so khớp: gõ "paracetamol 500" hay "kháng sinh"
  // không dấu đều ra kết quả — thủ kho gõ nhanh hiếm khi bỏ dấu đầy đủ.
  function norm(s){
    return (s || '').toLowerCase()
      .normalize('NFD').replace(/[\u0300-\u036f]/g, '')
      .replace(/đ/g, 'd');
  }
  function matches(tr, q){
    if (!q) return true;
    var hay = norm(tr.dataset.name) + ' ' + norm(tr.dataset.code) + ' ' +
              norm(tr.dataset.generic) + ' ' + norm(tr.dataset.barcode) + ' ' + norm(tr.dataset.cat);
    return q.split(/\s+/).every(function(w){ return hay.indexOf(w) > -1; });
  }
  function filtered(){
    var q = norm(state.q).trim();
    var src, base;
    if (isBatchView()) {
      base = batchRows.filter(function(r){ return r.dataset.kind === state.view; });
    } else if (state.view === 'low') {
      base = medRows.filter(function(r){ return r.dataset.status === 'low'; });
    } else if (state.view === 'out') {
      base = medRows.filter(function(r){ return r.dataset.status === 'out'; });
    } else {
      base = medRows;
    }
    src = base.filter(function(r){ return matches(r, q); });

    var k = state.sortKey, dir = state.sortDir === 'desc' ? -1 : 1;
    src.sort(function(a, b){
      var num = (k === 'stock' || k === 'price');
      var va, vb;
      if (num)            { va = +a.dataset[k] || 0;  vb = +b.dataset[k] || 0; }
      else if (k === 'exp'){ va = a.dataset.exp || '9999-12-31'; vb = b.dataset.exp || '9999-12-31'; }
      else if (k === 'batch'){ va = norm(a.dataset.batch || 'zzzz'); vb = norm(b.dataset.batch || 'zzzz'); }
      else                { va = norm(a.dataset[k]); vb = norm(b.dataset[k]); }

      if (va < vb) return -1 * dir;
      if (va > vb) return  1 * dir;

      // Tie-breakers cho Hạn dùng: ưu tiên trạng thái cảnh báo khẩn hơn rồi đến Tên A-Z
      if (k === 'exp') {
        var rankMap = { dead: 1, out: 1, soon: 2, low: 2, ok: 3 };
        var stA = rankMap[a.dataset.kind || a.dataset.status] || 3;
        var stB = rankMap[b.dataset.kind || b.dataset.status] || 3;
        if (stA !== stB) return (stA - stB) * dir;
      }

      // Tie-breaker: tên thuốc A-Z
      if (k !== 'name') {
        var na = norm(a.dataset.name), nb = norm(b.dataset.name);
        if (na < nb) return -1;
        if (na > nb) return 1;
      }
      return 0;
    });
    return src;
  }

  var EMPTIES = {
    search: { art:'🔍', good:false, t:'Không tìm thấy kết quả nào',
              d:'Không có mục nào khớp từ khoá đang tìm. Thử rút ngắn từ khoá hoặc đổi lát cắt.' },
    all:    { art:'📦', good:false, t:'Kho chưa có thuốc nào',
              d:'Danh mục thuốc đang trống. Tạo phiếu nhập kho để bắt đầu theo dõi tồn.' },
    low:    { art:'✅', good:true,  t:'Không có thuốc nào sắp hết 🎉',
              d:'Mọi mặt hàng đều đang trên ngưỡng tồn tối thiểu.' },
    out:    { art:'✅', good:true,  t:'Không có mặt hàng nào hết hàng 🎉',
              d:'Toàn bộ danh mục đều còn hàng bán được.' },
    soon:   { art:'✅', good:true,  t:'Không có lô nào cận hạn 🎉',
              d:'Không lô nào hết hạn trong 30 ngày tới. Kho đang khoẻ.' },
    dead:   { art:'✅', good:true,  t:'Không có lô hết hạn tồn đọng 🎉',
              d:'Không còn lô quá hạn nào nằm trong kho.' }
  };

  function render(){
    var rows = filtered();
    var total = rows.length;
    var pages = Math.max(1, Math.ceil(total / state.size));
    if (state.page > pages) state.page = pages;
    var start = (state.page - 1) * state.size;
    var pageRows = rows.slice(start, start + state.size);

    var batch = isBatchView();
    tblMed.hidden   = batch || total === 0;
    tblBatch.hidden = !batch || total === 0;
    (batch ? bodyBatch : bodyMed).replaceChildren.apply(batch ? bodyBatch : bodyMed, pageRows);

    // Trạng thái rỗng
    var es = document.getElementById('emptyState');
    if (total === 0) {
      var cfg = state.q ? EMPTIES.search : EMPTIES[state.view];
      document.getElementById('emptyArt').textContent   = cfg.art;
      document.getElementById('emptyTitle').textContent = cfg.t;
      document.getElementById('emptyDesc').textContent  = cfg.d;
      es.className = 'wh-empty' + (cfg.good ? ' good' : '');
      document.getElementById('emptyReset').hidden = !state.q && state.view === 'all';
      es.hidden = false;
    } else {
      es.hidden = true;
    }

    // Phân trang
    document.getElementById('pager').style.display = total === 0 ? 'none' : '';
    document.getElementById('pagerInfo').innerHTML = total === 0 ? '' :
      'Hiển thị <b>' + (start + 1) + '–' + Math.min(start + state.size, total) + '</b> trong <b>' + total + '</b> mục';
    renderPager(pages);

    fitTable();   // bảng thuốc và bảng lô có bề rộng tối thiểu khác nhau
    syncChecks();
  }

  function renderPager(pages){
    var nav = document.getElementById('pagerNav');
    nav.innerHTML = '';
    if (pages <= 1) return;
    function btn(label, page, opts){
      opts = opts || {};
      var b = document.createElement('button');
      b.type = 'button'; b.className = 'wh-pg' + (opts.gap ? ' gap' : '');
      if (opts.icon) b.innerHTML = '<svg><use href="#' + opts.icon + '"/></svg>';
      else b.textContent = label;
      if (opts.gap) { b.disabled = true; nav.appendChild(b); return; }
      if (opts.disabled) b.disabled = true;
      if (page === state.page) b.setAttribute('aria-current', 'page');
      if (opts.aria) b.setAttribute('aria-label', opts.aria);
      b.addEventListener('click', function(){ state.page = page; render(); scrollTop(); });
      nav.appendChild(b);
    }
    btn('', state.page - 1, { icon:'ic-chevron-left', disabled: state.page === 1, aria:'Trang trước' });
    var list = [];
    for (var i = 1; i <= pages; i++) {
      if (i === 1 || i === pages || Math.abs(i - state.page) <= 1) list.push(i);
      else if (list[list.length - 1] !== '…') list.push('…');
    }
    list.forEach(function(i){ i === '…' ? btn('…', 0, { gap:true }) : btn(String(i), i); });
    btn('', state.page + 1, { icon:'ic-chevron-right', disabled: state.page === pages, aria:'Trang sau' });
  }

  // Đổi trang → kéo đầu bảng về ngay dưới toolbar dính, không nhảy hẳn lên đỉnh
  // trang: người dùng đang ở "chế độ quét bảng", đưa họ về đọc lại tiêu đề trang
  // là mất nhịp.
  function scrollTop(){
    var card = document.querySelector('.wh-tablecard');
    var top = card.getBoundingClientRect().top + window.scrollY
            - 66 - (parseInt(getComputedStyle(document.documentElement).getPropertyValue('--wh-toolbar-h'), 10) || 0) - 24;
    window.scrollTo({ top: Math.max(0, top),
      behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth' });
  }

  /* ── Đổi lát cắt (KPI card + segmented control dùng chung 1 hàm) ────────── */
  function setView(v){
    state.view = v; state.page = 1;
    // Đổi lát cắt = đổi tập dòng ⇒ bỏ lựa chọn cũ, tránh cảnh "xuất 12 dòng đã
    // chọn" mà 7 dòng trong đó người dùng không còn nhìn thấy ở lát cắt hiện tại.
    selected.clear();
    document.querySelectorAll('.wh-seg button, .wh-kpi').forEach(function(b){
      var on = b.dataset.view === v;
      b.setAttribute('aria-pressed', String(on));
      if (b.classList.contains('wh-kpi')) b.classList.toggle('is-active', on);
    });
    // Lát cắt lô luôn sắp theo hạn gần nhất — thứ tự duy nhất có nghĩa ở đây.
    if (isBatchView() && state.sortKey !== 'exp') { state.sortKey = 'exp'; state.sortDir = 'asc'; syncSortUI(); }
    render();
  }
  document.querySelectorAll('.wh-seg button, .wh-kpi').forEach(function(b){
    b.addEventListener('click', function(){ setView(b.dataset.view); });
  });

  /* ── Tìm kiếm tức thời ─────────────────────────────────────────────────── */
  var qEl = document.getElementById('q'), qBox = document.getElementById('searchBox');
  function onQuery(){
    state.q = qEl.value; state.page = 1;
    qBox.classList.toggle('has-value', qEl.value.length > 0);
    render();
  }
  var qt;
  qEl.addEventListener('input', function(){ clearTimeout(qt); qt = setTimeout(onQuery, 120); });
  qEl.addEventListener('search', onQuery);
  document.getElementById('qClear').addEventListener('click', function(){ qEl.value = ''; onQuery(); qEl.focus(); });
  if (qEl.value) qBox.classList.add('has-value');
  document.getElementById('emptyReset').addEventListener('click', function(){
    qEl.value = ''; state.q = ''; qBox.classList.remove('has-value'); setView('all');
  });

  /* ── Sắp xếp UI tùy chỉnh ─────────────────────────────────────────── */
  var btnSort = document.getElementById('btnSort'), popSort = document.getElementById('popSort');
  var sortLabel = document.getElementById('sortLabel');
  function syncSortUI(){
    var val = state.sortKey + ':' + state.sortDir;
    if (popSort) {
      popSort.querySelectorAll('.wh-cselect-opt').forEach(function(opt){
        var sel = opt.dataset.value === val;
        opt.classList.toggle('is-selected', sel);
        if (sel && sortLabel) sortLabel.textContent = opt.textContent.replace('✓', '').trim();
      });
    }
    document.querySelectorAll('#tblMed th.sortable').forEach(function(th){
      var isCurrent = th.dataset.key === state.sortKey;
      th.setAttribute('aria-sort', isCurrent
        ? (state.sortDir === 'asc' ? 'ascending' : 'descending') : 'none');
    });
  }
  if (btnSort && popSort) {
    btnSort.addEventListener('click', function(e){
      e.stopPropagation();
      closeOtherPopups(popSort);
      var open = popSort.classList.toggle('open');
      btnSort.classList.toggle('open', open);
      btnSort.setAttribute('aria-expanded', String(open));
    });
    popSort.addEventListener('click', function(e){
      var opt = e.target.closest('.wh-cselect-opt');
      if (!opt) return;
      var p = opt.dataset.value.split(':');
      state.sortKey = p[0]; state.sortDir = p[1]; state.page = 1;
      popSort.classList.remove('open'); btnSort.classList.remove('open');
      btnSort.setAttribute('aria-expanded', 'false');
      syncSortUI(); render();
    });
  }
  document.querySelectorAll('#tblMed th.sortable').forEach(function(th){
    th.addEventListener('click', function(e){
      if (e.target.classList.contains('grip')) return;
      var k = th.dataset.key;
      if (state.sortKey === k) {
        state.sortDir = state.sortDir === 'asc' ? 'desc' : 'asc';
      } else {
        state.sortKey = k;
        state.sortDir = 'asc';
      }
      state.page = 1; syncSortUI(); render();
    });
  });

  /* ── Số dòng mỗi trang UI tùy chỉnh ───────────────────────────────────── */
  var btnPageSize = document.getElementById('btnPageSize'), popPageSize = document.getElementById('popPageSize');
  var pageSizeLabel = document.getElementById('pageSizeLabel');
  function syncPageSizeUI(){
    if (!popPageSize) return;
    popPageSize.querySelectorAll('.wh-cselect-opt').forEach(function(opt){
      var sel = +opt.dataset.value === state.size;
      opt.classList.toggle('is-selected', sel);
      if (sel && pageSizeLabel) pageSizeLabel.textContent = opt.textContent.replace('✓', '').trim();
    });
  }
  if (btnPageSize && popPageSize) {
    btnPageSize.addEventListener('click', function(e){
      e.stopPropagation();
      closeOtherPopups(popPageSize);
      var open = popPageSize.classList.toggle('open');
      btnPageSize.classList.toggle('open', open);
      btnPageSize.setAttribute('aria-expanded', String(open));
    });
    popPageSize.addEventListener('click', function(e){
      var opt = e.target.closest('.wh-cselect-opt');
      if (!opt) return;
      state.size = +opt.dataset.value; state.page = 1;
      popPageSize.classList.remove('open'); btnPageSize.classList.remove('open');
      btnPageSize.setAttribute('aria-expanded', 'false');
      syncPageSizeUI(); render();
    });
  }

  function closeOtherPopups(activePop){
    [popSort, popPageSize, popCols].forEach(function(p){
      if (p && p !== activePop) {
        p.classList.remove('open');
        var btn = p.parentElement ? p.parentElement.querySelector('button') : null;
        if (btn) { btn.classList.remove('open'); btn.setAttribute('aria-expanded', 'false'); }
      }
    });
  }

  /* ── Kéo giãn bề rộng cột ──────────────────────────────────────────────── */
  document.querySelectorAll('#tblMed thead th').forEach(function(th, i, all){
    if (i === 0 || i === all.length - 1) return;
    var grip = document.createElement('span');
    grip.className = 'grip'; grip.setAttribute('aria-hidden', 'true');
    th.appendChild(grip);
    grip.addEventListener('mousedown', function(e){
      e.preventDefault(); e.stopPropagation();
      var x0 = e.pageX, w0 = th.offsetWidth;
      grip.classList.add('dragging');
      document.body.style.cursor = 'col-resize';
      function mv(ev){ th.style.width = Math.max(70, w0 + ev.pageX - x0) + 'px'; }
      function up(){
        grip.classList.remove('dragging'); document.body.style.cursor = '';
        document.removeEventListener('mousemove', mv); document.removeEventListener('mouseup', up);
      }
      document.addEventListener('mousemove', mv); document.addEventListener('mouseup', up);
    });
  });

  /* ── Ẩn/hiện cột (nhớ lựa chọn giữa các phiên) ──────────────────────────── */
  var COLKEY = 'wh.inv.cols';
  var COL_ALL = ['code','cat','batch','exp','price'];
  var saved = null;
  try { saved = JSON.parse(localStorage.getItem(COLKEY)); } catch (e) { saved = null; }
  // Mặc định ẩn Mã thuốc + Lô gần nhất để bộ cột vừa màn 1280px (xem ghi chú CSS).
  var hiddenCols = new Set(Array.isArray(saved) ? saved : ['code','batch']);
  // Phải khớp với bề rộng cột khai báo trong <style> ở đầu trang.
  var COLW = { check:40, code:96, med:240, cat:120, stock:118, batch:112, exp:132, status:110, price:108, act:96 };
  function applyCols(){
    document.querySelectorAll('.wh-pop input[data-col]').forEach(function(cb){
      cb.checked = !hiddenCols.has(cb.dataset.col);
    });
    COL_ALL.forEach(function(k){ tblMed.classList.toggle('h-' + k, hiddenCols.has(k)); });
    // Bề rộng tối thiểu của bảng = tổng các cột đang bật. Vượt quá khung thì trang
    // cuộn ngang (không bọc overflow ở tổ tiên — sẽ giết sticky header), còn dư
    // thì phần thừa dồn vào cột "Thuốc" vì đó là cột duy nhất để width:auto.
    var w = COLW.check + COLW.med + COLW.stock + COLW.status + COLW.act;
    COL_ALL.forEach(function(k){ if (!hiddenCols.has(k)) w += COLW[k]; });
    tblMed.style.minWidth = w + 'px';
    fitTable();
    try { localStorage.setItem(COLKEY, JSON.stringify(Array.from(hiddenCols))); } catch (e) {}
  }

  /* Bật cuộn ngang CHỈ khi bảng thật sự không vừa khung. Nếu bật sẵn `overflow-x`
     thì khung bảng trở thành scrollport và sticky header chết ngay cả lúc bảng
     đang vừa vặn — mà đó là 90% thời gian sử dụng. */
  var pane = document.querySelector('.wh-tablescroll');
  function fitTable(){
    var need = Math.max(parseInt(tblMed.style.minWidth, 10) || 0, isBatchView() ? 760 : 0);
    pane.classList.toggle('needs-x', need > pane.clientWidth);
  }
  if (window.ResizeObserver) new ResizeObserver(fitTable).observe(pane);
  else window.addEventListener('resize', fitTable);

  /* Header bảng dính ngay dưới toolbar → cần biết toolbar cao bao nhiêu (nó co
     giãn/xuống dòng theo bề ngang, không thể hard-code). */
  var toolbar = document.getElementById('toolbar');
  function measureToolbar(){
    document.documentElement.style.setProperty('--wh-toolbar-h', toolbar.offsetHeight + 'px');
  }
  measureToolbar();
  if (window.ResizeObserver) new ResizeObserver(measureToolbar).observe(toolbar);
  else window.addEventListener('resize', measureToolbar);

  // Đổ bóng đậm hơn khi toolbar đã dính vào topbar — tín hiệu nhỏ cho biết
  // "còn nội dung phía trên", tránh cảm giác thanh này vốn nằm sẵn ở đó.
  // Đã dính ⇔ top của nó đúng bằng mốc sticky (66px), nên chỉ cần so 1 phép tính.
  var stuckTick = false;
  function onScroll(){
    if (stuckTick) return;
    stuckTick = true;
    requestAnimationFrame(function(){
      toolbar.classList.toggle('is-stuck', toolbar.getBoundingClientRect().top <= 67);
      stuckTick = false;
    });
  }
  window.addEventListener('scroll', onScroll, { passive:true });
  onScroll();
  document.querySelectorAll('.wh-pop input[data-col]').forEach(function(cb){
    cb.addEventListener('change', function(){
      cb.checked ? hiddenCols.delete(cb.dataset.col) : hiddenCols.add(cb.dataset.col);
      applyCols();
    });
  });
  applyCols();

  var btnCols = document.getElementById('btnCols'), popCols = document.getElementById('popCols');
  btnCols.addEventListener('click', function(e){
    e.stopPropagation();
    var open = popCols.classList.toggle('open');
    btnCols.setAttribute('aria-expanded', String(open));
  });
  document.addEventListener('click', function(e){
    if (!popCols.contains(e.target)) { popCols.classList.remove('open'); btnCols.setAttribute('aria-expanded', 'false'); }
  });

  /* ── Chọn dòng + hành động hàng loạt ───────────────────────────────────── */
  var selBar = document.getElementById('selBar');
  function syncChecks(){
    document.querySelectorAll('#bodyMed tr').forEach(function(tr){
      var ck = tr.querySelector('.rowck');
      if (!ck) return;
      ck.checked = selected.has(tr.dataset.id);
      tr.classList.toggle('is-picked', ck.checked);
    });
    var visible = Array.prototype.slice.call(document.querySelectorAll('#bodyMed tr'));
    var all = document.getElementById('checkAll');
    all.checked = visible.length > 0 && visible.every(function(tr){ return selected.has(tr.dataset.id); });
    all.indeterminate = !all.checked && visible.some(function(tr){ return selected.has(tr.dataset.id); });
    document.getElementById('selCount').textContent = selected.size;
    selBar.classList.toggle('show', selected.size > 0);
  }
  bodyMed.addEventListener('change', function(e){
    if (!e.target.classList.contains('rowck')) return;
    var tr = e.target.closest('tr');
    e.target.checked ? selected.add(tr.dataset.id) : selected.delete(tr.dataset.id);
    syncChecks();
  });
  document.getElementById('checkAll').addEventListener('change', function(e){
    document.querySelectorAll('#bodyMed tr').forEach(function(tr){
      e.target.checked ? selected.add(tr.dataset.id) : selected.delete(tr.dataset.id);
    });
    syncChecks();
  });
  document.getElementById('btnClearSel').addEventListener('click', function(){ selected.clear(); syncChecks(); });

  /* ── Xuất CSV (mở được bằng Excel, có BOM cho tiếng Việt) ───────────────── */
  function csvCell(v){ return '"' + String(v == null ? '' : v).replace(/"/g, '""') + '"'; }
  function exportRows(rows, name){
    if (!rows.length) return;
    var head = isBatchView()
      ? ['Số lô','Thuốc','Tồn của lô','Hạn dùng']
      : ['Mã thuốc','Tên thuốc','Hoạt chất','Danh mục','Tồn kho','Tối thiểu','Đơn vị','Lô gần nhất','Hạn dùng','Giá bán'];
    var lines = [head.map(csvCell).join(',')];
    rows.forEach(function(tr){
      var d = tr.dataset;
      lines.push((isBatchView()
        ? [d.code, d.name, d.stock, d.exp]
        : [d.code, d.name, d.generic, d.cat, d.stock, d.min, d.unit,
           (tr.querySelector('.c-batch .wh-code') || {}).textContent || '', d.exp, d.price]
      ).map(csvCell).join(','));
    });
    var blob = new Blob(['\ufeff' + lines.join('\r\n')], { type:'text/csv;charset=utf-8;' });
    var a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = name + '-' + new Date().toISOString().slice(0, 10) + '.csv';
    a.click();
    setTimeout(function(){ URL.revokeObjectURL(a.href); }, 1000);
  }
  document.getElementById('btnExport').addEventListener('click', function(){
    exportRows(filtered(), 'ton-kho-' + state.view);
  });
  document.getElementById('btnExportSel').addEventListener('click', function(){
    exportRows(medRows.filter(function(tr){ return selected.has(tr.dataset.id); }), 'ton-kho-da-chon');
  });

  /* ── Làm mới ───────────────────────────────────────────────────────────── */
  var btnRefresh = document.getElementById('btnRefresh');
  btnRefresh.addEventListener('click', function(){
    btnRefresh.classList.add('is-busy'); btnRefresh.disabled = true;
    location.reload();
  });

  /* ── Phím tắt: "/" nhảy vào ô tìm, Esc thoát ───────────────────────────── */
  document.addEventListener('keydown', function(e){
    if (e.key === '/' && !/^(INPUT|TEXTAREA|SELECT)$/.test(document.activeElement.tagName)) {
      e.preventDefault(); qEl.focus(); qEl.select();
    }
    if (e.key === 'Escape') {
      if (document.getElementById('drawer').classList.contains('open')) closeDetail();
      else if (popCols.classList.contains('open')) { popCols.classList.remove('open'); btnCols.setAttribute('aria-expanded','false'); }
      else if (popSort && popSort.classList.contains('open')) { popSort.classList.remove('open'); btnSort.classList.remove('open'); btnSort.setAttribute('aria-expanded','false'); }
      else if (popPageSize && popPageSize.classList.contains('open')) { popPageSize.classList.remove('open'); btnPageSize.classList.remove('open'); btnPageSize.setAttribute('aria-expanded','false'); }
      else if (document.activeElement === qEl && qEl.value) { qEl.value = ''; onQuery(); }
    }
  });

  /* ══ Drawer chi tiết ═════════════════════════════════════════════════════ */
  var drawer = document.getElementById('drawer'), scrim = document.getElementById('scrim');
  var lastFocus = null;

  function esc(s){
    return (s == null ? '' : String(s)).replace(/[&<>"']/g, function(c){
      return ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' })[c];
    });
  }
  function field(label, value, full){
    var blank = value === null || value === undefined || value === '';
    return '<div class="f' + (full ? ' full' : '') + '"><div class="k">' + esc(label) + '</div>' +
           '<div class="v' + (blank ? ' none' : '') + '">' + (blank ? 'Chưa có dữ liệu' : esc(value)) + '</div></div>';
  }
  function skeleton(){
    var h = '';
    for (var i = 0; i < 8; i++) h += '<div class="wh-sk" style="width:' + (55 + (i % 4) * 12) + '%"></div>';
    return h;
  }

  window.openDetail = function(id){
    lastFocus = document.activeElement;
    drawer.classList.add('open'); scrim.classList.add('open');
    drawer.setAttribute('aria-hidden', 'false');
    document.body.style.overflow = 'hidden';
    document.getElementById('dwTitle').textContent = 'Đang tải…';
    document.getElementById('dwSub').textContent = '';
    document.getElementById('dwBody').innerHTML = skeleton();
    document.getElementById('dwMove').href  = CTX + '/warehouse-stock-movement?medicineId=' + id;
    document.getElementById('dwOrder').href = CTX + '/warehouse-import?medicineId=' + id;
    document.getElementById('dwClose').focus();

    fetch(CTX + '/warehouse-inventory?action=detail&id=' + id + '')
      .then(function(r){ return r.json(); })
      .then(function(data){
        if (data.error) throw new Error(data.error);
        var m = data.medicine, batches = data.batches || [];
        document.getElementById('dwTitle').textContent = m.medicineName;
        document.getElementById('dwSub').textContent = m.medicineCode + (m.genericName ? ' · ' + m.genericName : '');

        var stockClass = m.totalStock === 0 ? 'out' : (m.minInventory > 0 && m.totalStock <= m.minInventory ? 'low' : 'ok');
        var stockText  = m.totalStock === 0 ? 'Hết hàng' : (stockClass === 'low' ? 'Sắp hết' : 'Đủ hàng');

        var html =
          '<div class="wh-sec"><svg style="width:14px;height:14px"><use href="#ic-package"/></svg> Tình trạng kho</div>' +
          '<div class="wh-kv">' +
            '<div class="f"><div class="k">Tồn kho / Tối thiểu</div><div class="v" style="font-size:20px;font-weight:800">' +
              m.totalStock + ' <span style="color:var(--muted);font-weight:650;font-size:14px">/ ' + m.minInventory + '</span></div></div>' +
            '<div class="f"><div class="k">Trạng thái</div><div class="v"><span class="wh-badge ' + stockClass + '">' + stockText + '</span>' +
              (m.isPrescriptionRequired ? ' <span class="rx">Rx</span>' : '') + '</div></div>' +
            field('Giá bán', Number(m.sellingPrice).toLocaleString('vi-VN') + 'đ') +
            field('Đơn vị', m.unit) +
            field('Vị trí kệ', m.shelfName) +
            field('Điều kiện bảo quản', m.storageConditions) +
          '</div>' +

          '<div class="wh-sec"><svg style="width:14px;height:14px"><use href="#ic-tag"/></svg> Thông tin sản phẩm</div>' +
          '<div class="wh-kv">' +
            field('Danh mục', m.categoryName) +
            field('Nhà sản xuất', m.manufacturerName) +
            field('Barcode', m.barcode) +
            field('Số đăng ký', m.registrationNumber) +
            field('Quy cách đóng gói', m.packagingSpec, true) +
            field('Liều dùng', m.dosage, true) +
            (m.dosageWarning ? field('Cảnh báo liều dùng', m.dosageWarning, true) : '') +
            field('Chống chỉ định', m.contraindications, true) +
          '</div>' +

          '<div class="wh-sec"><svg style="width:14px;height:14px"><use href="#ic-package"/></svg> Tất cả lô hàng (' + batches.length + ')</div>';

        if (!batches.length) {
          html += '<div class="wh-empty"><div class="art">📦</div><div class="t">Chưa có lô nào</div>' +
                  '<div class="d">Thuốc này chưa từng được nhập lô nào vào kho.</div></div>';
        } else {
          html += '<table class="wh-table"><thead><tr><th>Số lô</th><th>Nhập</th><th>HSD</th>' +
                  '<th style="text-align:right">Tồn / Nhập</th><th>Trạng thái</th></tr></thead><tbody>';
          batches.forEach(function(b){
            var n = daysTo(b.expiryDate), cls = 'mute', lbl = b.status;
            if (b.status === 'ACTIVE') {
              if (n !== null && n < 0)       { cls = 'dead'; lbl = 'Hết hạn'; }
              else if (n !== null && n <= 30){ cls = 'soon'; lbl = 'Cận hạn'; }
              else                           { cls = 'ok';   lbl = 'Còn hạn'; }
            } else if (b.status === 'RECALLED') { cls = 'out'; lbl = 'Thu hồi'; }
            html += '<tr><td><span class="wh-code">' + esc(b.batchNumber) + '</span></td>' +
                    '<td>' + esc(b.importDate || '—') + '</td>' +
                    '<td>' + esc(b.expiryDate || '—') + '</td>' +
                    '<td class="num">' + b.currentQuantity + ' <span style="color:var(--muted)">/ ' + b.initialQuantity + '</span></td>' +
                    '<td><span class="wh-badge ' + cls + '">' + esc(lbl) + '</span></td></tr>';
          });
          html += '</tbody></table>';
        }
        document.getElementById('dwBody').innerHTML = html;
      })
      .catch(function(){
        document.getElementById('dwTitle').textContent = 'Không tải được dữ liệu';
        document.getElementById('dwBody').innerHTML =
          '<div class="wh-empty"><div class="art">⚠️</div><div class="t">Lỗi kết nối</div>' +
          '<div class="d">Không lấy được chi tiết sản phẩm. Kiểm tra kết nối rồi thử lại.</div></div>';
      });
  };

  window.closeDetail = function(){
    drawer.classList.remove('open'); scrim.classList.remove('open');
    drawer.setAttribute('aria-hidden', 'true');
    document.body.style.overflow = '';
    if (lastFocus) lastFocus.focus();
  };
  document.getElementById('dwClose').addEventListener('click', closeDetail);
  scrim.addEventListener('click', closeDetail);
  // Giữ tiêu điểm bàn phím bên trong drawer khi đang mở
  drawer.addEventListener('keydown', function(e){
    if (e.key !== 'Tab') return;
    var f = drawer.querySelectorAll('a[href],button:not([disabled]),input,select,textarea,[tabindex]:not([tabindex="-1"])');
    if (!f.length) return;
    var first = f[0], last = f[f.length - 1];
    if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
    else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
  });

  syncSortUI();
  syncPageSizeUI();
  render();
})();
</script>
</body>
</html>
