<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%--
  warehouse-import.jsp — Nhập hàng vào kho (Warehouse Console)

  Bản sửa 2026-08-04 sau phản hồi thực tế:

  1. LỖI THẬT (đã sửa ở servlet): không chọn PO thì POID ghi giá trị mặc định 0 của kiểu
     int, mà POID là khoá ngoại tới PurchaseOrders — INSERT luôn vi phạm FK, và code cũ bỏ
     qua giá trị trả về của insert() nên vẫn báo "thành công" dù KHÔNG có gì được ghi vào DB.
     Xem WarehouseImportServlet.doPost() để biết chi tiết cách sửa.
  2. Dropdown <select> gốc của trình duyệt không style được phần danh sách mở ra (thanh xám
     mặc định của Chrome/Edge) — thay bằng combo tự dựng (.wh-combo), giữ <select> ẩn làm
     nguồn sự thật cho name/value/required nên KHÔNG đổi field nào ở form.
  3. Gợi ý giá nhập + số lô lần gần nhất (chỉ hiển thị, không tự điền — vẫn phải gõ tay).
  4. Đơn vị tính hiển thị dạng chip dính liền ô Số lượng + quy cách đóng gói làm rõ nghĩa
     "1 đơn vị" là gì, KHÔNG làm ô chọn giả vì đơn vị là thuộc tính cố định của thuốc (đổi ở
     đây sẽ làm lệch cách tính tồn kho của các lô khác cùng thuốc).
  5. Hạn dùng ≤ ngày sản xuất, hoặc ngày nhập trước ngày sản xuất: chặn cứng (không cho sang
     bước 4), phân biệt với cảnh báo mềm "sắp hết hạn" vẫn cho ghi.
  6. Thêm bảng "Phiếu nhập gần đây" — cùng nguồn dữ liệu PurchaseOrders mà Admin xem ở
     /purchase-orders, để thủ kho tự kiểm chứng lô mình vừa nhập có thật trong DB hay không.
--%>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) request.getAttribute("staffAcc");
    String ctx = request.getContextPath();
    if (acc == null) { response.sendRedirect(ctx + "/warehouse-login"); return; }
    String fullName = acc.getFullName() != null && !acc.getFullName().isEmpty() ? acc.getFullName() : acc.getUsername();
    String initials = fullName.substring(0,1).toUpperCase();
    String uid = (String) request.getAttribute("staffUid");
    String activeNav = "import";
    String msg = request.getParameter("msg");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Nhập kho — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400..800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= ctx %>/css/staff-portal.css">
<link rel="stylesheet" href="<%= ctx %>/css/warehouse-portal.css?v=11">
<style>
a{text-decoration:none;color:inherit}
.wh-shell{max-width:1080px}

.pane{display:none}
.pane.on{display:block;animation:paneIn 260ms cubic-bezier(.4,0,.2,1)}
@keyframes paneIn{from{opacity:0;transform:translateY(10px)}to{opacity:1;transform:none}}

.hint{font-size:12.5px;color:var(--muted);margin-top:6px;line-height:1.5}
.hint b{color:var(--ink);font-weight:750}

/* Xem trước thuốc đã chọn */
.prev{display:none;gap:16px;align-items:center;margin-top:18px;padding:16px 18px;border-radius:18px;
  background:linear-gradient(160deg,#F0FDFA,#ECFEFF);border:1px solid #99F6E4}
.prev.on{display:flex;flex-wrap:wrap}
.prev .bd{flex:1;min-width:200px}
.prev .nm{font-size:15px;font-weight:800;color:var(--deep)}
.prev .mt{font-size:12.5px;color:#0F766E;opacity:.85;margin-top:3px}
.prev .st{text-align:right;flex:none}
.prev .st .n{font-size:22px;font-weight:800;color:var(--deep);font-variant-numeric:tabular-nums;line-height:1}
.prev .st .l{font-size:11px;color:#0F766E;opacity:.8;margin-top:4px;font-weight:700}

.nav-row{display:flex;align-items:center;gap:10px;margin-top:24px;padding-top:20px;border-top:1px solid var(--line)}
.nav-row .grow{margin-left:auto}

.err{display:none;color:var(--danger);font-size:12.5px;font-weight:700;margin-top:6px}
.err.on{display:block}
.wh-in.bad{border-color:var(--danger);box-shadow:0 0 0 4px rgba(220,38,38,.12)}

.after{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-top:18px}
@media(max-width:640px){.after{grid-template-columns:1fr}}

/* ── Ô số lượng + chip đơn vị dính liền ─────────────────────────────────────
   Đơn vị là thuộc tính CỐ ĐỊNH của thuốc (khai báo khi tạo thuốc trong Kho
   thuốc), không phải lựa chọn của riêng lần nhập này — trộn lẫn 2 lô cùng
   thuốc nhưng khác đơn vị sẽ làm sai phép cộng tồn kho ở mọi nơi khác trong hệ
   thống (POS, báo cáo, FEFO...). Nên đây là CHIP HIỂN THỊ, không phải <select>
   giả vờ chọn được. */
.qty-row{display:flex;align-items:stretch;gap:0}
.qty-row .wh-in{border-top-right-radius:0;border-bottom-right-radius:0;border-right:none}
.qty-unit{flex:none;display:flex;align-items:center;gap:6px;padding:0 16px;min-width:64px;justify-content:center;
  border:1.5px solid var(--border);border-left:1px solid var(--line);border-top-right-radius:var(--wh-r-ctl);
  border-bottom-right-radius:var(--wh-r-ctl);background:var(--soft);color:var(--deep);font-weight:800;font-size:13.5px;
  white-space:nowrap}
.qty-row:focus-within .qty-unit{border-color:var(--main)}
.packaging-note{display:flex;align-items:flex-start;gap:8px;margin-top:10px;padding:10px 13px;border-radius:12px;
  background:var(--surface);font-size:12px;color:var(--muted);line-height:1.5}
.packaging-note svg{width:14px;height:14px;flex:none;margin-top:1px;opacity:.75}
.packaging-note b{color:var(--ink);font-weight:750}

/* Gợi ý giá / số lô lần nhập gần nhất */
.suggest{display:none;align-items:center;gap:10px;margin-top:8px;padding:9px 13px;border-radius:11px;
  background:#FFFBEB;border:1px solid #FDE68A;font-size:12px;color:#92400E;flex-wrap:wrap}
.suggest.on{display:flex}
.suggest svg{width:14px;height:14px;flex:none}
.suggest b{font-weight:800}
.suggest .fill{margin-left:auto;background:none;border:none;color:#B45309;font-weight:800;font-size:12px;
  cursor:pointer;text-decoration:underline;padding:0;font-family:inherit}

/* ── Combo tự dựng thay cho <select> gốc ─────────────────────────────────────
   <select> gốc vẫn còn trong DOM (visually-hidden) — giữ nguyên vai trò "nguồn
   sự thật" cho name/value/required/validation của form, JS chỉ đồng bộ 1
   chiều: chọn ở combo → set select.value → bắn 'change' để mọi logic đang có
   (xem trước thuốc, gợi ý giá...) chạy y nguyên, không phải viết lại. */
.wh-combo{position:relative}
.wh-combo-src{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;
  clip:rect(0,0,0,0);white-space:nowrap;border:0}
.wh-combo-trigger{width:100%;display:flex;align-items:center;gap:10px;cursor:pointer;text-align:left;
  font-family:inherit;font-size:14.5px}
.wh-combo-trigger .lbl{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;
  color:var(--ink);font-weight:600}
.wh-combo-trigger .lbl.ph{color:#9AA8A3;font-weight:500}
.wh-combo-trigger svg{width:17px;height:17px;flex:none;color:var(--muted);transition:transform 160ms}
.wh-combo.open .wh-combo-trigger svg{transform:rotate(180deg)}
.wh-combo.open .wh-combo-trigger{border-color:var(--main);box-shadow:0 0 0 4px rgba(15,118,110,.13)}
.wh-combo-panel{position:absolute;left:0;right:0;top:calc(100% + 6px);z-index:80;
  background:#fff;border:1px solid var(--wh-line);border-radius:16px;box-shadow:var(--wh-sh-pop);
  max-height:320px;display:flex;flex-direction:column;overflow:hidden}
.wh-combo-search-wrap{padding:8px;border-bottom:1px solid var(--line);flex:none}
.wh-combo-search{width:100%;height:38px;padding:0 12px;border:1.5px solid var(--border);border-radius:10px;
  font-family:inherit;font-size:13.5px;outline:none}
.wh-combo-search:focus{border-color:var(--main)}
.wh-combo-list{overflow-y:auto;padding:6px}
.wh-combo-opt{padding:10px 12px;border-radius:10px;font-size:13.5px;font-weight:600;color:var(--ink);
  cursor:pointer;display:flex;align-items:center;gap:8px;justify-content:space-between}
.wh-combo-opt .om{font-size:11.5px;color:var(--muted);font-weight:600}
.wh-combo-opt.active{background:var(--soft);color:var(--deep)}
.wh-combo-opt[aria-selected="true"]{font-weight:800}
.wh-combo-opt[aria-selected="true"]::after{content:'✓';color:var(--main);font-weight:800}
.wh-combo-empty{padding:20px 14px;text-align:center;font-size:12.5px;color:var(--muted)}

/* Bảng phiếu nhập gần đây */
.imp-med{width:auto;min-width:180px} .imp-sup{width:170px} .imp-by{width:150px}
.imp-when{width:150px} .imp-st{width:120px} .imp-lots{width:90px} .imp-val{width:130px}
#tblRecent{min-width:940px}
</style>
<meta name="csrf-token" content="${csrfToken}">
<script src="<%= ctx %>/js/csrf.js"></script>
<script src="<%= ctx %>/js/warehouse-ui.js" defer></script>
</head>
<body class="wh">
<%@ include file="/WEB-INF/views/icons.jsp" %>
<%@ include file="warehouse-sidebar.jsp" %>

<div class="main">
  <header class="wh-topbar">
    <div class="crumb">Kho hàng</div>
    <nav class="tb-nav">
      <a class="on" href="<%= ctx %>/warehouse-import">Nhập kho</a>
      <a href="<%= ctx %>/warehouse-reorder">Gợi ý đặt hàng</a>
    </nav>
    <div class="right">
      <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc của <%= fullName %>"><%= initials %></a>
    </div>
  </header>

  <div class="wh-shell wh-anim">

    <div class="wh-head">
      <div>
        <h1>Nhập hàng vào kho</h1>
        <p class="sub">Ghi nhận lô mới theo 4 bước. Lô vừa nhập vào ngay hàng chờ xuất theo FEFO.</p>
      </div>
      <div class="wh-head-actions">
        <a class="wh-btn" href="<%= ctx %>/warehouse-inventory">
          <svg><use href="#ic-package"/></svg> Xem tồn kho
        </a>
      </div>
    </div>

    <% if ("import-error".equals(msg)) { %>
      <div class="wh-note danger" role="alert">
        <svg><use href="#ic-alert"/></svg>
        <span>Không nhập được lô. Kiểm tra lại số lô (không trùng), số lượng và các mốc ngày (hạn dùng phải sau ngày sản xuất) rồi thử lại.</span>
      </div>
    <% } else if ("success".equals(msg)) { %>
      <div class="wh-note ok" role="status">
        <svg><use href="#ic-check-circle"/></svg>
        <span>Đã nhập lô vào kho. Tồn kho của thuốc được cộng ngay — xem lại ở bảng "Phiếu nhập gần đây" bên dưới.</span>
      </div>
    <% } %>

    <!-- ══ Chỉ dẫn bước ══ -->
    <nav class="wh-steps" id="steps" aria-label="Các bước nhập kho">
      <button type="button" class="wh-step on"   data-go="1" aria-current="step">
        <span class="dot">1</span><span class="lb">Hàng &amp; nguồn</span><span class="sb">Thuốc, NCC, PO</span>
      </button>
      <button type="button" class="wh-step" data-go="2">
        <span class="dot">2</span><span class="lb">Lô &amp; số lượng</span><span class="sb">Số lô, SL, giá</span>
      </button>
      <button type="button" class="wh-step" data-go="3">
        <span class="dot">3</span><span class="lb">Mốc thời gian</span><span class="sb">NSX, HSD, ngày nhập</span>
      </button>
      <button type="button" class="wh-step" data-go="4">
        <span class="dot">4</span><span class="lb">Xác nhận</span><span class="sb">Kiểm tra &amp; ghi</span>
      </button>
    </nav>

    <form action="<%= ctx %>/warehouse-import" method="POST" id="importForm">
      <input type="hidden" name="_csrf" value="${csrfToken}">

      <!-- ══ BƯỚC 1 ══ -->
      <section class="wh-card pane on" id="p1" aria-labelledby="h1t">
        <div class="wh-card-head">
          <div class="wh-ic info"><svg><use href="#ic-truck"/></svg></div>
          <div class="tt">
            <h2 id="h1t">Hàng &amp; nguồn</h2>
            <div class="desc">Nhìn phiếu giao hàng: hàng gì, của ai, thuộc đơn đặt nào.</div>
          </div>
        </div>
        <div class="wh-card-body">
          <div class="wh-row2">
            <div class="wh-fg">
              <label for="imMed">Thuốc <span aria-hidden="true">*</span></label>
              <select class="wh-in wh-combo-src" id="imMed" name="medicineId" required data-placeholder="— Chọn thuốc —" data-search="Tìm theo tên thuốc…">
                <option value="">— Chọn thuốc —</option>
                <c:forEach var="m" items="${medicines}">
                  <option value="${m.medicineId}"
                          data-name="${fn:escapeXml(m.medicineName)}"
                          data-unit="${fn:escapeXml(m.unit)}"
                          data-stock="${m.totalStock}"
                          data-min="${m.minInventory}"
                          data-generic="${fn:escapeXml(m.genericName)}"
                          data-packaging="${fn:escapeXml(m.packagingSpec)}"
                          data-lastprice="${latestByMedicine[m.medicineId].importPrice}"
                          data-lastbatch="${fn:escapeXml(latestByMedicine[m.medicineId].batchNumber)}"
                          data-lastdate="${latestByMedicine[m.medicineId].importDate}"
                          data-lastsupplierid="${latestByMedicine[m.medicineId].supplierId}"
                          >${m.medicineName} (${m.unit})</option>
                </c:forEach>
              </select>
              <div class="err" id="e-med">Chưa chọn thuốc.</div>
            </div>
            <div class="wh-fg">
              <label for="imSup">Nhà cung cấp <span aria-hidden="true">*</span></label>
              <select class="wh-in wh-combo-src" id="imSup" name="supplierId" required data-placeholder="— Chọn nhà cung cấp —" data-search="Tìm theo tên nhà cung cấp…">
                <option value="">— Chọn nhà cung cấp —</option>
                <c:forEach var="s" items="${suppliers}">
                  <option value="${s.supplierId}" data-name="${fn:escapeXml(s.supplierName)}">${s.supplierName}</option>
                </c:forEach>
              </select>
              <div class="err" id="e-sup">Chưa chọn nhà cung cấp.</div>
            </div>
          </div>

          <div class="wh-fg">
            <label for="imPo">Đơn đặt hàng (PO)</label>
            <select class="wh-in wh-combo-src" id="imPo" name="poId" data-placeholder="— Không gắn với đơn nào —">
              <option value="">— Không gắn với đơn nào —</option>
              <c:forEach var="po" items="${pos}">
                <option value="${po.poId}">PO #${po.poId} — ${po.orderDate}</option>
              </c:forEach>
            </select>
            <div class="hint">Gắn PO để hệ thống đối chiếu số lượng đã đặt với số lượng thực nhận. Không có PO tương ứng thì để trống — hệ thống tự tạo phiếu nhập nhanh cho lần này.</div>
          </div>

          <div class="prev" id="medPrev">
            <span class="wh-ic"><svg><use href="#ic-pill"/></svg></span>
            <div class="bd">
              <div class="nm" id="pvName">—</div>
              <div class="mt" id="pvMeta">—</div>
            </div>
            <div class="st">
              <div class="n" id="pvStock">0</div>
              <div class="l">TỒN HIỆN TẠI</div>
            </div>
          </div>

          <div class="nav-row">
            <span class="grow"></span>
            <button type="button" class="wh-btn wh-btn-primary" data-next="2">
              Tiếp tục <svg><use href="#ic-arrow-right"/></svg>
            </button>
          </div>
        </div>
      </section>

      <!-- ══ BƯỚC 2 ══ -->
      <section class="wh-card pane" id="p2" aria-labelledby="h2t">
        <div class="wh-card-head">
          <div class="wh-ic"><svg><use href="#ic-package"/></svg></div>
          <div class="tt">
            <h2 id="h2t">Lô &amp; số lượng</h2>
            <div class="desc">Nhìn vỏ thùng: số lô in trên bao bì, số lượng thực nhận và giá nhập.</div>
          </div>
        </div>
        <div class="wh-card-body">
          <div class="wh-note info" style="margin-bottom:20px">
            <svg><use href="#ic-info"/></svg>
            <span>Số lô phải khớp <b>đúng chữ in trên vỏ hộp</b> — đây là số hệ thống sẽ bắt quét lại khi xuất kho hoặc thu hồi.</span>
          </div>

          <div class="wh-row2">
            <div class="wh-fg">
              <label for="imLot">Số lô <span aria-hidden="true">*</span></label>
              <input class="wh-in" type="text" id="imLot" name="batchNumber"
                     placeholder="VD: LOT-2026-001" autocomplete="off" required>
              <div class="err" id="e-lot">Chưa nhập số lô.</div>
              <div class="suggest" id="lotSuggest">
                <svg><use href="#ic-history"/></svg>
                <span>Lô gần nhất của thuốc này: <b id="lotSugText">—</b></span>
              </div>
            </div>
            <div class="wh-fg">
              <label for="imQty">Số lượng <span aria-hidden="true">*</span></label>
              <div class="qty-row">
                <input class="wh-in" type="number" id="imQty" name="quantity" min="1" placeholder="0" required>
                <span class="qty-unit" id="qtyUnit">—</span>
              </div>
              <div class="err" id="e-qty">Số lượng phải lớn hơn 0.</div>
              <div class="packaging-note" id="packagingNote" hidden>
                <svg><use href="#ic-info"/></svg>
                <span>Quy cách: <b id="packagingText">—</b>. Đơn vị tính cố định theo khai báo của thuốc — muốn đổi, sửa ở trang Kho thuốc (Admin).</span>
              </div>
            </div>
          </div>

          <div class="wh-fg">
            <label for="imPrice">Giá nhập <span aria-hidden="true">*</span></label>
            <input class="wh-in" type="number" id="imPrice" name="importPrice" step="1000" min="0" placeholder="0" required>
            <div class="hint">Giá cho <b>một đơn vị</b> theo quy cách của thuốc, không phải tổng tiền cả lô.
              <span id="priceLive"></span></div>
            <div class="err" id="e-price">Chưa nhập giá nhập.</div>
            <div class="suggest" id="priceSuggest">
              <svg><use href="#ic-history"/></svg>
              <span>Lần nhập gần nhất: <b id="priceSugText">—</b></span>
              <button type="button" class="fill" id="priceSugFill">Dùng giá này</button>
            </div>
          </div>

          <div class="nav-row">
            <button type="button" class="wh-btn" data-prev="1"><svg><use href="#ic-chevron-left"/></svg> Quay lại</button>
            <span class="grow"></span>
            <button type="button" class="wh-btn wh-btn-primary" data-next="3">
              Tiếp tục <svg><use href="#ic-arrow-right"/></svg>
            </button>
          </div>
        </div>
      </section>

      <!-- ══ BƯỚC 3 ══ -->
      <section class="wh-card pane" id="p3" aria-labelledby="h3t">
        <div class="wh-card-head">
          <div class="wh-ic warn"><svg><use href="#ic-calendar"/></svg></div>
          <div class="tt">
            <h2 id="h3t">Mốc thời gian</h2>
            <div class="desc">Nhìn vỏ hộp: ngày sản xuất và hạn dùng. Hạn dùng quyết định thứ tự xuất FEFO.</div>
          </div>
        </div>
        <div class="wh-card-body">
          <div class="wh-row2">
            <div class="wh-fg">
              <label for="imMfg">Ngày sản xuất <span aria-hidden="true">*</span></label>
              <input class="wh-in" type="date" id="imMfg" name="manufactureDate" required>
              <div class="err" id="e-mfg">Chưa chọn ngày sản xuất.</div>
            </div>
            <div class="wh-fg">
              <label for="imExp">Hạn sử dụng <span aria-hidden="true">*</span></label>
              <input class="wh-in" type="date" id="imExp" name="expiryDate" required>
              <div class="err" id="e-exp">Chưa chọn hạn sử dụng.</div>
            </div>
          </div>
          <div class="wh-fg">
            <label for="imIn">Ngày nhập hàng <span aria-hidden="true">*</span></label>
            <input class="wh-in" type="date" id="imIn" name="importDate" required>
            <div class="hint">Mặc định là hôm nay.</div>
            <div class="err" id="e-imp">Ngày nhập không được trước ngày sản xuất.</div>
          </div>

          <!-- Lỗi dữ liệu bất khả thi (HSD ≤ NSX) — CHẶN CỨNG, không cho sang bước 4 -->
          <div class="wh-note danger" id="dateError" hidden style="margin:20px 0 0">
            <svg><use href="#ic-alert"/></svg>
            <span id="dateErrorMsg"></span>
          </div>
          <!-- Cảnh báo nghiệp vụ (lô sắp/đã hết hạn) — vẫn cho ghi, chỉ nhắc -->
          <div class="wh-note warn" id="dateWarn" hidden style="margin:20px 0 0">
            <svg><use href="#ic-alert"/></svg>
            <span id="dateWarnMsg"></span>
          </div>

          <div class="nav-row">
            <button type="button" class="wh-btn" data-prev="2"><svg><use href="#ic-chevron-left"/></svg> Quay lại</button>
            <span class="grow"></span>
            <button type="button" class="wh-btn wh-btn-primary" data-next="4">
              Xem lại <svg><use href="#ic-arrow-right"/></svg>
            </button>
          </div>
        </div>
      </section>

      <!-- ══ BƯỚC 4 ══ -->
      <section class="wh-card pane" id="p4" aria-labelledby="h4t">
        <div class="wh-card-head">
          <div class="wh-ic ok"><svg><use href="#ic-shield-check"/></svg></div>
          <div class="tt">
            <h2 id="h4t">Xác nhận phiếu nhập</h2>
            <div class="desc">Kiểm tra trước khi ghi vào kho. Sau khi ghi, muốn sửa phải qua Xuất/Điều chỉnh.</div>
          </div>
        </div>
        <div class="wh-card-body">
          <div id="confirmWarn"></div>

          <div class="wh-sum" id="sumRows"></div>

          <div class="after">
            <div class="wh-tile">
              <div class="ic info"><svg><use href="#ic-package"/></svg></div>
              <div class="n" id="afStock">0</div>
              <div class="l">Tồn sau khi nhập</div>
              <div class="s" id="afStockNote">—</div>
            </div>
            <div class="wh-tile">
              <div class="ic warn"><svg><use href="#ic-clock"/></svg></div>
              <div class="n" id="afDays">—</div>
              <div class="l">Số ngày còn hạn</div>
              <div class="s" id="afDaysNote">Tính từ hôm nay tới hạn sử dụng</div>
            </div>
          </div>

          <div class="nav-row">
            <button type="button" class="wh-btn" data-prev="3"><svg><use href="#ic-chevron-left"/></svg> Quay lại</button>
            <span class="grow"></span>
            <button type="submit" class="wh-btn wh-btn-primary wh-btn-lg" id="btnSubmit">
              <svg><use href="#ic-box-in"/></svg> Ghi lô vào kho
            </button>
          </div>
        </div>
      </section>
    </form>

    <!-- ══ Phiếu nhập gần đây — cùng dữ liệu Admin xem ở "Đơn đặt hàng" ══ -->
    <div class="wh-tablecard" style="margin-top:24px">
      <div class="wh-card-head">
        <div class="wh-ic jade"><svg><use href="#ic-clipboard"/></svg></div>
        <div class="tt">
          <h2>Phiếu nhập gần đây</h2>
          <div class="desc">20 phiếu mới nhất — dùng để tự kiểm tra lô vừa nhập đã vào kho thật chưa.</div>
        </div>
      </div>
      <div class="wh-tablescroll">
        <c:choose>
          <c:when test="${empty recentImports}">
            <div class="wh-empty">
              <div class="art"><svg style="width:26px;height:26px"><use href="#ic-clipboard"/></svg></div>
              <div class="t">Chưa có phiếu nhập nào</div>
              <div class="d">Phiếu nhập đầu tiên sẽ hiện ở đây ngay sau khi bạn ghi lô vào kho.</div>
            </div>
          </c:when>
          <c:otherwise>
            <table class="wh-table" id="tblRecent">
              <thead>
                <tr>
                  <th class="imp-med">Mã đơn</th>
                  <th class="imp-sup">Nhà cung cấp</th>
                  <th class="imp-by">Người nhập</th>
                  <th class="imp-when">Ngày nhập</th>
                  <th class="imp-st">Trạng thái</th>
                  <th class="imp-lots" style="text-align:right">Số lô</th>
                  <th class="imp-val" style="text-align:right">Tổng giá trị</th>
                </tr>
              </thead>
              <tbody>
                <c:forEach var="row" items="${recentImports}">
                  <tr>
                    <td class="imp-med"><span class="wh-code">PN${row.po.poId}</span></td>
                    <td class="imp-sup">${fn:escapeXml(row.supplierName)}</td>
                    <td class="imp-by">${fn:escapeXml(row.byName)}</td>
                    <td class="imp-when">${row.whenText}</td>
                    <td class="imp-st">
                      <c:choose>
                        <c:when test="${row.po.status == 'COMPLETED'}"><span class="wh-badge ok">Đã nhập kho</span></c:when>
                        <c:when test="${row.po.status == 'PENDING'}"><span class="wh-badge low">Chờ hàng về</span></c:when>
                        <c:otherwise><span class="wh-badge mute">${row.po.status}</span></c:otherwise>
                      </c:choose>
                    </td>
                    <td class="imp-lots num">${row.batchCount}</td>
                    <td class="imp-val wh-price"><fmt:formatNumber value="${row.po.totalValue}" type="number" maxFractionDigits="0"/>đ</td>
                  </tr>
                </c:forEach>
              </tbody>
            </table>
          </c:otherwise>
        </c:choose>
      </div>
    </div>

  </div>
</div>

<script>
(function () {
  'use strict';
  var $ = function (id) { return document.getElementById(id); };
  var form = $('importForm');
  var step = 1, MAX = 4;
  var reached = 1;

  var F = { med:$('imMed'), sup:$('imSup'), po:$('imPo'), lot:$('imLot'), qty:$('imQty'),
            price:$('imPrice'), mfg:$('imMfg'), exp:$('imExp'), imp:$('imIn') };

  if (!F.imp.value) F.imp.value = new Date().toISOString().slice(0, 10);

  var vnd = function (n) { return (Number(n) || 0).toLocaleString('vi-VN'); };
  var esc = function (s) {
    return String(s == null ? '' : s).replace(/[&<>"']/g, function (c) {
      return ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' })[c];
    });
  };
  function selData(sel, key) {
    var o = sel.options[sel.selectedIndex];
    return o ? (o.dataset[key] || '') : '';
  }
  function daysLeft(iso) {
    if (!iso) return null;
    var d = new Date(iso + 'T00:00:00');
    if (isNaN(d)) return null;
    return Math.round((d - new Date().setHours(0, 0, 0, 0)) / 86400000);
  }

  /* ══ Combo tự dựng thay <select> gốc ═══════════════════════════════════════
     Mỗi select.wh-combo-src được bọc thêm trigger + panel; select gốc VẪN Ở
     TRONG FORM (ẩn nhìn, không ẩn `hidden` — phần tử hidden vẫn được submit
     bình thường) nên name/value/required hoạt động y hệt <select> thường,
     không đổi field nào. Chọn ở panel chỉ làm 1 việc: set select.value rồi
     bắn 'change' — mọi logic đang nghe 'change' (xem trước thuốc, gợi ý giá,
     validate…) chạy nguyên vẹn không cần sửa. */
  function enhanceCombo(select) {
    var wrap = document.createElement('div');
    wrap.className = 'wh-combo';
    select.parentNode.insertBefore(wrap, select);
    wrap.appendChild(select);

    var trigger = document.createElement('button');
    trigger.type = 'button';
    trigger.className = 'wh-combo-trigger wh-in';
    trigger.setAttribute('aria-haspopup', 'listbox');
    trigger.setAttribute('aria-expanded', 'false');
    if (select.id) trigger.setAttribute('aria-labelledby', select.id + '-lbl ' + select.id);
    trigger.innerHTML = '<span class="lbl"></span><svg><use href="#ic-chevron-down"/></svg>';
    wrap.appendChild(trigger);

    var panel = document.createElement('div');
    panel.className = 'wh-combo-panel';
    panel.setAttribute('role', 'listbox');
    panel.hidden = true;
    var searchTerm = select.dataset.search;
    var searchEl = null;
    if (searchTerm) {
      var sw = document.createElement('div');
      sw.className = 'wh-combo-search-wrap';
      searchEl = document.createElement('input');
      searchEl.type = 'search';
      searchEl.className = 'wh-combo-search';
      searchEl.placeholder = searchTerm;
      searchEl.autocomplete = 'off';
      sw.appendChild(searchEl);
      panel.appendChild(sw);
    }
    var list = document.createElement('div');
    list.className = 'wh-combo-list';
    panel.appendChild(list);
    var emptyEl = document.createElement('div');
    emptyEl.className = 'wh-combo-empty';
    emptyEl.textContent = 'Không tìm thấy kết quả.';
    emptyEl.hidden = true;
    panel.appendChild(emptyEl);
    wrap.appendChild(panel);

    var opts = Array.prototype.slice.call(select.options);
    function norm(s) {
      return (s || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd');
    }
    function renderLabel() {
      var o = select.options[select.selectedIndex];
      var ph = select.dataset.placeholder || 'Chọn…';
      var isPh = !select.value;
      trigger.querySelector('.lbl').textContent = isPh ? ph : (o ? o.textContent : ph);
      trigger.querySelector('.lbl').classList.toggle('ph', isPh);
    }
    function renderList(filter) {
      list.innerHTML = '';
      var k = norm(filter);
      var shown = 0;
      opts.forEach(function (o) {
        if (!o.value && k) return;          // ẩn dòng placeholder khi đang lọc
        if (k && norm(o.textContent).indexOf(k) === -1) return;
        shown++;
        var row = document.createElement('div');
        row.className = 'wh-combo-opt';
        row.setAttribute('role', 'option');
        row.dataset.value = o.value;
        row.setAttribute('aria-selected', String(o.value === select.value && o.value !== ''));
        row.textContent = o.textContent;
        row.addEventListener('click', function () { choose(o.value); });
        list.appendChild(row);
      });
      emptyEl.hidden = shown > 0;
    }
    function choose(value) {
      select.value = value;
      select.dispatchEvent(new Event('change', { bubbles: true }));
      renderLabel();
      close();
    }
    function open() {
      if (wrap.classList.contains('open')) return;
      document.querySelectorAll('.wh-combo.open').forEach(function (w) { w.__whComboClose && w.__whComboClose(); });
      wrap.classList.add('open');
      trigger.setAttribute('aria-expanded', 'true');
      panel.hidden = false;
      renderList('');
      if (searchEl) { searchEl.value = ''; searchEl.focus(); }
    }
    function close() {
      wrap.classList.remove('open');
      trigger.setAttribute('aria-expanded', 'false');
      panel.hidden = true;
    }
    wrap.__whComboClose = close;

    trigger.addEventListener('click', function () {
      wrap.classList.contains('open') ? close() : open();
    });
    if (searchEl) searchEl.addEventListener('input', function () { renderList(searchEl.value); });
    document.addEventListener('click', function (e) { if (!wrap.contains(e.target)) close(); });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && wrap.classList.contains('open')) { close(); trigger.focus(); }
    });
    // <select> ẩn vẫn nhận được điều hướng bàn phím gốc (mũi tên khi trigger focus và
    // người dùng gõ phím) — đồng bộ lại nhãn hiển thị mỗi khi giá trị đổi bằng cách nào
    // khác ngoài click chuột (bàn phím, hoặc set từ JS khác như re-select khi validate lỗi).
    select.addEventListener('change', renderLabel);
    renderLabel();
  }
  document.querySelectorAll('select.wh-combo-src').forEach(enhanceCombo);

  /* ── Chuyển bước ─────────────────────────────────────────────────────── */
  function show(n) {
    step = n;
    for (var i = 1; i <= MAX; i++) $('p' + i).classList.toggle('on', i === n);
    document.querySelectorAll('.wh-step').forEach(function (b, i) {
      var idx = i + 1;
      b.classList.toggle('on', idx === n);
      b.classList.toggle('done', idx < n);
      if (idx === n) b.setAttribute('aria-current', 'step'); else b.removeAttribute('aria-current');
    });
    if (n === 4) buildSummary();
    var top = document.querySelector('.wh-steps').getBoundingClientRect().top + window.scrollY - 90;
    window.scrollTo({ top: Math.max(0, top),
      behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth' });
    var first = $('p' + n).querySelector('input.wh-in, .wh-combo-trigger');
    if (first && n > 1) setTimeout(function () { first.focus({ preventScroll: true }); }, 260);
  }

  /* ── Kiểm tra từng bước ──────────────────────────────────────────────── */
  function fail(el, errId) {
    el.classList.add('bad');
    if (errId) $(errId).classList.add('on');
    return false;
  }
  function clear(el, errId) {
    el.classList.remove('bad');
    if (errId) $(errId).classList.remove('on');
  }
  function badgeCombo(select, bad) {
    var trigger = select.closest('.wh-combo').querySelector('.wh-combo-trigger');
    trigger.classList.toggle('bad', bad);
  }
  function validate(n) {
    var ok = true;
    if (n === 1) {
      clear(F.med, 'e-med'); clear(F.sup, 'e-sup'); badgeCombo(F.med, false); badgeCombo(F.sup, false);
      if (!F.med.value) { ok = fail(F.med, 'e-med'); badgeCombo(F.med, true); }
      if (!F.sup.value) { ok = fail(F.sup, 'e-sup'); badgeCombo(F.sup, true); }
    } else if (n === 2) {
      clear(F.lot, 'e-lot'); clear(F.qty, 'e-qty'); clear(F.price, 'e-price');
      if (!F.lot.value.trim()) ok = fail(F.lot, 'e-lot');
      if (!F.qty.value || +F.qty.value < 1) ok = fail(F.qty, 'e-qty');
      if (F.price.value === '' || +F.price.value < 0) ok = fail(F.price, 'e-price');
    } else if (n === 3) {
      clear(F.mfg, 'e-mfg'); clear(F.exp, 'e-exp'); clear(F.imp, 'e-imp');
      if (!F.mfg.value) ok = fail(F.mfg, 'e-mfg');
      if (!F.exp.value) ok = fail(F.exp, 'e-exp');
      // Lỗi dữ liệu bất khả thi — CHẶN CỨNG, khác cảnh báo mềm "sắp hết hạn" ở checkDates().
      if (F.mfg.value && F.exp.value && F.exp.value <= F.mfg.value) {
        ok = fail(F.exp, 'e-exp');
        $('e-exp').textContent = 'Hạn sử dụng phải sau ngày sản xuất — không thể hết hạn trước hoặc cùng ngày sản xuất.';
      }
      if (F.mfg.value && F.imp.value && F.imp.value < F.mfg.value) {
        ok = fail(F.imp, 'e-imp');
      }
    }
    return ok;
  }

  document.querySelectorAll('[data-next]').forEach(function (b) {
    b.addEventListener('click', function () {
      if (!validate(step)) {
        var bad = $('p' + step).querySelector('.wh-in.bad, .wh-combo-trigger.bad');
        if (bad) bad.focus();
        return;
      }
      var n = +b.dataset.next;
      reached = Math.max(reached, n);
      show(n);
    });
  });
  document.querySelectorAll('[data-prev]').forEach(function (b) {
    b.addEventListener('click', function () { show(+b.dataset.prev); });
  });
  document.querySelectorAll('.wh-step').forEach(function (b) {
    b.addEventListener('click', function () {
      var n = +b.dataset.go;
      if (n <= reached || n === step) show(n);
    });
  });

  /* ── Bước 1: xem trước thuốc + gợi ý giá/lô lần gần nhất ────────────────── */
  F.med.addEventListener('change', function () {
    if (!F.med.value) { $('medPrev').classList.remove('on'); resetSuggestions(); return; }
    $('pvName').textContent = selData(F.med, 'name');
    var gen = selData(F.med, 'generic'), unit = selData(F.med, 'unit'), min = selData(F.med, 'min');
    $('pvMeta').textContent = (gen ? gen + ' · ' : '') + 'Đơn vị: ' + (unit || '—') + ' · Ngưỡng tối thiểu: ' + (min || 0);
    $('pvStock').textContent = selData(F.med, 'stock') || '0';
    $('medPrev').classList.add('on');

    // Chip đơn vị + quy cách đóng gói dính ngay ô Số lượng (bước 2)
    $('qtyUnit').textContent = unit || '—';
    var pkg = selData(F.med, 'packaging');
    if (pkg) { $('packagingText').textContent = pkg; $('packagingNote').hidden = false; }
    else { $('packagingNote').hidden = true; }

    updateSuggestions();
  });

  function resetSuggestions() {
    $('lotSuggest').classList.remove('on');
    $('priceSuggest').classList.remove('on');
    $('qtyUnit').textContent = '—';
    $('packagingNote').hidden = true;
  }
  function updateSuggestions() {
    var lastPrice = selData(F.med, 'lastprice'), lastBatch = selData(F.med, 'lastbatch'), lastDate = selData(F.med, 'lastdate');
    if (lastBatch) {
      $('lotSugText').textContent = lastBatch + (lastDate ? ' (' + lastDate + ')' : '');
      $('lotSuggest').classList.add('on');
    } else {
      $('lotSuggest').classList.remove('on');
    }
    if (lastPrice) {
      $('priceSugText').textContent = vnd(lastPrice) + 'đ' + (lastDate ? ' — ' + lastDate : '');
      $('priceSuggest').classList.add('on');
      $('priceSugFill').onclick = function () {
        F.price.value = Math.round(+lastPrice);
        livePrice();
        F.price.focus();
      };
    } else {
      $('priceSuggest').classList.remove('on');
    }
  }

  /* ── Bước 2: tổng tiền hiện ngay khi gõ ──────────────────────────────── */
  function livePrice() {
    var q = +F.qty.value || 0, p = +F.price.value || 0;
    $('priceLive').innerHTML = (q && p)
      ? ' Tổng lô: <b>' + vnd(q * p) + 'đ</b>' : '';
  }
  F.qty.addEventListener('input', livePrice);
  F.price.addEventListener('input', livePrice);

  /* ── Bước 3: chặn cứng dữ liệu bất khả thi + cảnh báo mềm nghiệp vụ ─────── */
  function checkDates() {
    var m = F.mfg.value, e = F.exp.value, i = F.imp.value;
    var hardErr = null, softWarn = [];

    if (m && e && e <= m) hardErr = 'Hạn sử dụng đang trước hoặc trùng ngày sản xuất — dữ liệu này không thể đúng, kiểm tra lại vỏ hộp.';
    else if (m && i && i < m) hardErr = 'Ngày nhập đang trước ngày sản xuất — không thể nhận hàng trước khi hàng được sản xuất.';

    if (!hardErr && e) {
      var n = daysLeft(e);
      if (n !== null) {
        if (n < 0) softWarn.push('Lô này đã quá hạn ' + Math.abs(n) + ' ngày.');
        else if (n <= 90) softWarn.push('Lô chỉ còn ' + n + ' ngày sử dụng — vào diện cảnh báo hạn dùng ngay khi nhập.');
      }
    }

    $('dateError').hidden = !hardErr;
    $('dateErrorMsg').textContent = hardErr || '';
    $('dateWarn').hidden = !!hardErr || softWarn.length === 0;
    $('dateWarnMsg').textContent = softWarn.join(' ');
    return { hardErr: hardErr, softWarn: softWarn };
  }
  [F.mfg, F.exp, F.imp].forEach(function (el) { el.addEventListener('change', checkDates); });

  /* ── Bước 4: tóm tắt + hệ quả ────────────────────────────────────────── */
  function buildSummary() {
    var q = +F.qty.value || 0, p = +F.price.value || 0;
    var unit = selData(F.med, 'unit') || 'đơn vị';
    var stock = +selData(F.med, 'stock') || 0;
    var min = +selData(F.med, 'min') || 0;
    var poTxt = F.po.value ? F.po.options[F.po.selectedIndex].textContent.trim() : 'Không gắn đơn — tự tạo phiếu nhập nhanh';

    $('sumRows').innerHTML =
      row('Thuốc', esc(selData(F.med, 'name'))) +
      row('Nhà cung cấp', esc(selData(F.sup, 'name'))) +
      row('Đơn đặt hàng', esc(poTxt)) +
      row('Số lô', '<span class="wh-code" style="font-size:13.5px">' + esc(F.lot.value) + '</span>') +
      row('Số lượng', vnd(q) + ' ' + esc(unit)) +
      row('Giá nhập / ' + esc(unit), vnd(p) + 'đ') +
      row('Ngày sản xuất', esc(F.mfg.value || '—')) +
      row('Hạn sử dụng', esc(F.exp.value || '—')) +
      row('Ngày nhập', esc(F.imp.value || '—')) +
      '<div class="r total"><span class="k">Tổng giá trị lô</span><span class="v">' + vnd(q * p) + 'đ</span></div>';

    var after = stock + q;
    $('afStock').textContent = vnd(after);
    $('afStockNote').textContent = vnd(stock) + ' → ' + vnd(after) + ' ' + unit +
      (min > 0 ? ' · ngưỡng tối thiểu ' + min : '');

    var n = daysLeft(F.exp.value);
    $('afDays').textContent = n === null ? '—' : (n < 0 ? '-' + Math.abs(n) : n);
    $('afDaysNote').textContent = n === null ? 'Chưa chọn hạn sử dụng'
      : n < 0 ? 'Lô đã quá hạn — không nên nhập'
      : n <= 30 ? 'Sẽ bị cách ly ngay, không bán được'
      : n <= 90 ? 'Sẽ nằm trong diện ưu tiên bán trước'
      : 'Hạn dùng an toàn';

    var d = checkDates();
    var btn = $('btnSubmit');
    if (d.hardErr) {
      $('confirmWarn').innerHTML = '<div class="wh-note danger" style="margin-bottom:20px"><svg><use href="#ic-alert"/></svg><span>' +
        esc(d.hardErr) + ' Quay lại bước "Mốc thời gian" để sửa trước khi ghi.</span></div>';
      btn.disabled = true;
    } else if (d.softWarn.length) {
      $('confirmWarn').innerHTML = '<div class="wh-note warn" style="margin-bottom:20px"><svg><use href="#ic-alert"/></svg><span>' +
        esc(d.softWarn.join(' ')) + ' Vẫn ghi được nếu đúng thực tế hàng nhận.</span></div>';
      btn.disabled = false;
    } else {
      $('confirmWarn').innerHTML = '<div class="wh-note ok" style="margin-bottom:20px"><svg><use href="#ic-shield-check"/></svg>' +
        '<span>Không phát hiện bất thường. Lô sẽ vào hàng chờ xuất theo FEFO đúng thứ tự hạn dùng.</span></div>';
      btn.disabled = false;
    }
  }
  function row(k, v) {
    return '<div class="r"><span class="k">' + k + '</span><span class="v">' + v + '</span></div>';
  }

  /* ── Chặn Enter nhảy submit khi đang ở bước 1–3 ──────────────────────── */
  form.addEventListener('keydown', function (e) {
    if (e.key === 'Enter' && step < MAX && e.target.tagName !== 'TEXTAREA') {
      e.preventDefault();
      var b = $('p' + step).querySelector('[data-next]');
      if (b) b.click();
    }
  });

  form.addEventListener('submit', function (e) {
    for (var i = 1; i <= 3; i++) {
      if (!validate(i)) { e.preventDefault(); show(i); return; }
    }
    if (checkDates().hardErr) { e.preventDefault(); show(3); return; }
    $('btnSubmit').disabled = true;
    $('btnSubmit').classList.add('is-busy');
  });

  checkDates();

  // ── Pre-select thuốc khi đi thẳng từ nút giỏ hàng ở Tồn kho/Cảnh báo hạn dùng
  // (?medicineId=X) — chọn hộ ở Bước 1 rồi bắn 'change' để combo tự render nhãn
  // (enhanceCombo đã gắn ở trên) VÀ tự đổ dữ liệu xem trước (listener F.med bên dưới),
  // không cần viết lại logic populate riêng.
  //
  // Đi kèm tự điền "Nhà cung cấp" theo lần nhập gần nhất của đúng thuốc đó (data-lastsupplierid
  // gắn sẵn trên <option>). CHỈ tự điền Nhà cung cấp — KHÔNG đụng tới Số lô/Giá nhập/Ngày SX-HSD
  // dù đã có sẵn gợi ý (.suggest ở Bước 2): đó là thông tin CỦA LÔ VẬT LÝ đang cầm trên tay, tự
  // điền từ lô CŨ (thậm chí có thể là lô đang hết hạn — chính là lý do bấm giỏ hàng!) vào lô MỚI
  // là sai hoàn toàn, gây nhập nhầm hạn dùng đã qua. Nhà cung cấp thì không có rủi ro đó — sai
  // thì đổi lại combo, không sai dữ liệu tồn kho. ──
  <c:if test="${not empty preSelectMedicineId}">
  F.med.value = '${preSelectMedicineId}';
  F.med.dispatchEvent(new Event('change', { bubbles: true }));
  var _lastSupId = selData(F.med, 'lastsupplierid');
  if (_lastSupId && F.sup.querySelector('option[value="' + _lastSupId + '"]')) {
    F.sup.value = _lastSupId;
    F.sup.dispatchEvent(new Event('change', { bubbles: true }));
  }
  </c:if>
})();
</script>
</body>
</html>
