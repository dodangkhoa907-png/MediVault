<%@ page contentType="text/html;charset=UTF-8"  pageEncoding="UTF-8" %>
<% String activeNav = "purchase-orders"; %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
    boolean embed = "1".equals(request.getParameter("embed")); // nhúng trong iframe modal → ẩn sidebar/topbar
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
    
    
    
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Tạo phiếu nhập kho — MediCare</title>


<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;--sidebar:232px;
  --card-shadow:0 2px 12px rgba(15,38,69,.06),0 0 0 1px rgba(213,224,240,.5);
  --card-hover:0 6px 24px rgba(15,38,69,.09),0 0 0 1px rgba(213,224,240,.6);
  --input-focus:0 0 0 3px rgba(21,88,168,.1);
  --radius-lg:18px;--radius-md:12px;--radius-sm:10px;
}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-text{font-size:16px;font-weight:800;color:#fff;line-height:1.1}
.logo-text span{color:var(--cyan)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:12px 0 4px;flex-shrink:0}
.nav-label{font-size:9px;font-weight:750;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:750;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.14);font-weight:750}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--cyan);border-radius:2px}
.nav-badge{margin-left:auto;background:#DC2626;color:#fff;font-size:10px;font-weight:750;padding:1px 7px;border-radius:20px;min-width:20px;text-align:center}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50;flex-shrink:0}
.topbar-title{font-size:16px;font-weight:750}
.btn-back{display:inline-flex;align-items:center;gap:6px;padding:6px 14px;border-radius:9px;border:1.5px solid var(--border);background:var(--white);color:var(--ink);font-size:13px;font-weight:750;text-decoration:none;transition:all .18s}
.btn-back:hover{border-color:var(--blue);color:var(--blue)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:12px}
.clock{display:inline-flex;align-items:center;gap:6px;padding:6px 13px;border-radius:20px;background:#EFF6FF;color:var(--blue);font-size:12.5px;font-weight:750;white-space:nowrap}
.clock .cl-time{font-variant-numeric:tabular-nums;font-weight:800}
.user-av-sm{width:32px;height:32px;border-radius:50%;background:linear-gradient(135deg,#3ABDE0,#1558A8);display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}

/* ── Content area ── */
.content{max-width:1060px;margin:28px auto;padding:0 24px 56px;width:100%}
.page-header{margin-bottom:24px}
.page-title{font-size:24px;font-weight:800;margin-bottom:4px;letter-spacing:-.3px}
.page-sub{font-size:13.5px;color:var(--muted);line-height:1.5}

/* ── Error box ── */
.error-box{background:linear-gradient(135deg,#FFF5F5,#FEF2F2);border:1px solid #FECACA;border-radius:var(--radius-md);padding:16px 20px;margin-bottom:20px;box-shadow:0 2px 8px rgba(220,38,38,.06)}
.error-box ul{margin:0;padding-left:18px}.error-box li{font-size:13px;color:#991B1B;margin:4px 0;line-height:1.45}

/* ── Cards ── */
.card{background:var(--white);border:none;border-radius:var(--radius-lg);padding:24px 26px;margin-bottom:16px;box-shadow:var(--card-shadow);transition:box-shadow .25s ease}
.card:hover{box-shadow:var(--card-hover)}
.card-title{font-size:15px;font-weight:800;color:var(--navy);margin-bottom:18px;display:flex;align-items:center;gap:9px;padding-bottom:14px;border-bottom:1.5px solid #EDF2FA;letter-spacing:-.2px}

/* ── Form grid ── */
.hgrid{display:grid;grid-template-columns:1fr 1fr 1fr;gap:16px}
@media(max-width:760px){.hgrid{grid-template-columns:1fr}}
.fg{display:flex;flex-direction:column;gap:6px}
.fl{font-size:12px;font-weight:700;color:var(--muted);text-transform:uppercase;letter-spacing:.5px}.fl span{color:var(--red)}
.fi,.fs{height:42px;padding:0 13px;border:1.5px solid var(--border);border-radius:var(--radius-sm);font-size:13.5px;font-family:inherit;color:var(--ink);background:var(--white);outline:none;transition:border-color .18s,box-shadow .18s}
.fi:focus,.fs:focus{border-color:var(--blue);box-shadow:var(--input-focus)}
.ro{background:#F8FAFC;color:var(--muted);cursor:default;border-style:dashed}
.hint{font-size:11px;color:var(--muted);opacity:.8}

/* ── Line table ── */
.line-table{width:100%;border-collapse:separate;border-spacing:0 6px}
.line-table th{font-size:10px;font-weight:800;text-transform:uppercase;letter-spacing:.8px;color:var(--muted);text-align:left;padding:0 8px 8px;white-space:nowrap}
.line-table td{padding:4px 6px;vertical-align:top}
.line-table tr td:first-child{border-radius:var(--radius-sm) 0 0 var(--radius-sm)}
.line-table tr td:last-child{border-radius:0 var(--radius-sm) var(--radius-sm) 0}
.line-table .num{text-align:right}
.cell{width:100%;height:40px;padding:0 11px;border:1.5px solid var(--border);border-radius:var(--radius-sm);font-size:13px;font-family:inherit;background:var(--white);outline:none;transition:border-color .18s,box-shadow .18s}
.cell:focus{border-color:var(--blue);box-shadow:var(--input-focus)}
.subtotal{font-weight:800;color:var(--navy);font-size:14px;white-space:nowrap;padding-top:10px;display:block;text-align:right;font-variant-numeric:tabular-nums}

/* ── HSD / batch warnings ── */
.hsd-check{font-size:11px;font-weight:600;margin-top:5px;line-height:1.4;display:none;padding:5px 8px;border-radius:6px}
.hsd-check.warn{display:block;color:#92400E;background:#FFFBEB}
.hsd-check.ok{display:block;color:#166534;background:#F0FDF4}
.hsd-check.block{display:block;color:#991B1B;background:#FFF5F5}
.batch-check{font-size:11px;font-weight:600;margin-top:5px;line-height:1.4;display:none;color:#991B1B;padding:5px 8px;border-radius:6px;background:#FFF5F5}
.batch-check.show{display:block}
.cell.field-error{border-color:#DC2626!important;box-shadow:0 0 0 3px rgba(220,38,38,.1)}

/* ── Row controls ── */
.btn-del-row{width:36px;height:36px;border:none;background:transparent;color:var(--muted);border-radius:var(--radius-sm);cursor:pointer;font-size:15px;transition:all .18s}
.btn-del-row:hover{background:#FEF2F2;color:var(--red)}
.btn-add-row{margin-top:12px;background:transparent;color:var(--blue);border:1.5px dashed #93C5FD;border-radius:var(--radius-sm);padding:11px 18px;font-size:13px;font-weight:700;cursor:pointer;font-family:inherit;transition:all .18s}
.btn-add-row:hover{background:#EFF6FF;border-color:var(--blue)}

/* ── Totals ── */
.totals{margin-left:auto;max-width:360px;background:#F8FAFC;border-radius:var(--radius-md);padding:16px 20px}
.trow{display:flex;justify-content:space-between;align-items:center;padding:9px 0;font-size:13.5px}
.trow.grand{border-top:2px solid var(--border);margin-top:8px;padding-top:14px;font-size:18px;font-weight:800;color:var(--blue)}
.trow input{width:140px;height:38px;text-align:right;border:1.5px solid var(--border);border-radius:var(--radius-sm);padding:0 12px;font-family:inherit;font-size:13.5px;outline:none;transition:border-color .18s,box-shadow .18s}
.trow input:focus{border-color:var(--blue);box-shadow:var(--input-focus)}

/* ── Actions ── */
.actions{display:flex;gap:12px;margin-top:22px}
.btn-save{flex:1;height:52px;background:linear-gradient(135deg,#1558A8 0%,#0d3d63 100%);color:#fff;border:none;border-radius:var(--radius-md);font-size:15.5px;font-weight:800;cursor:pointer;font-family:inherit;letter-spacing:-.2px;transition:all .2s;box-shadow:0 4px 16px rgba(21,88,168,.25)}
.btn-save:hover{filter:brightness(1.08);box-shadow:0 6px 24px rgba(21,88,168,.32);transform:translateY(-1px)}
.btn-save:active{transform:translateY(0)}
.btn-cancel{height:52px;padding:0 28px;border:1.5px solid var(--border);border-radius:var(--radius-md);background:var(--white);color:var(--muted);font-weight:700;cursor:pointer;font-family:inherit;text-decoration:none;display:inline-flex;align-items:center;transition:all .18s}
.btn-cancel:hover{border-color:var(--red);color:var(--red);background:#FFF5F5}

<%-- Chế độ nhúng (iframe modal): ẩn sidebar, bỏ lề trái, gọn lại --%>
<% if (embed) { %>
body{background:#F1F5FB}
.main{margin-left:0}
.content{max-width:100%;margin:0 auto;padding:16px 20px 30px}
<% } %>

/* ── Select & dropdown ── */
select,option{font-family:inherit;font-size:inherit}
.cdd{position:relative;user-select:none;display:inline-block}
.cdd-btn{display:flex;align-items:center;gap:6px;padding:10px 14px;background:var(--white);border:1.5px solid var(--border);border-radius:var(--radius-sm);font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;font-weight:700;color:var(--ink);cursor:pointer;transition:all .18s;white-space:nowrap}
.cdd-btn:hover{border-color:var(--cyan);background:#F0FAFD}
.cdd-btn.open{border-color:var(--cyan);box-shadow:0 0 0 3px rgba(58,189,224,.12)}
.cdd-arrow{font-size:9px;color:var(--muted);transition:transform .2s}
.cdd-btn.open .cdd-arrow{transform:rotate(180deg)}
.cdd-menu{position:absolute;top:calc(100% + 6px);left:0;min-width:100%;background:var(--white);border:1.5px solid var(--border);border-radius:var(--radius-md);padding:6px;box-shadow:0 12px 40px rgba(15,38,69,.14);z-index:200;opacity:0;transform:translateY(-6px);pointer-events:none;transition:all .18s ease;max-height:260px;overflow-y:auto}
.cdd-menu.show{opacity:1;transform:translateY(0);pointer-events:auto}
.cdd-menu::-webkit-scrollbar{width:4px}
.cdd-menu::-webkit-scrollbar-thumb{background:var(--border);border-radius:4px}
.cdd-opt{padding:9px 14px;border-radius:8px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;font-weight:600;color:var(--ink);cursor:pointer;transition:all .12s;white-space:nowrap}
.cdd-opt:hover{background:var(--surface);color:var(--blue)}
.cdd-opt.active{background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;font-weight:700}
</style>
    
</head>
<body>
<% if (!embed) { %>
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>
<% } %>

<div class="main">
<% if (!embed) { %>
<div class="topbar">
  <a href="${pageContext.request.contextPath}/purchase-orders" class="btn-back">← Đơn đặt hàng</a>
  <span class="topbar-title">Tạo phiếu nhập kho</span>
  <div class="topbar-right">
    <span class="clock">🕐 <span id="clkDate"></span> · <span class="cl-time" id="clkTime"></span></span>
    <div class="user-av-sm"><%= initials %></div>
  </div>
</div>
<% } %>

<div class="content">
  <div class="page-header">
    <div class="page-title">Tạo phiếu nhập kho</div>
    <div class="page-sub">Nhập nhiều thuốc trong 1 phiếu — mỗi dòng tạo 1 lô hàng (số lô + HSD riêng). Lưu 1 lần, tồn kho tăng ngay.</div>
  </div>

  <c:if test="${not empty errors}">
    <div class="error-box"><ul><c:forEach var="e" items="${errors}"><li>${e}</li></c:forEach></ul></div>
  </c:if>

  <form method="post" action="${pageContext.request.contextPath}/purchase-orders" onsubmit="return beforeSubmit()">
    <input type="hidden" name="action" value="save"/>
    <input type="hidden" name="embed" value="${param.embed}"/>

    <div class="card">
      <div class="card-title">Thông tin phiếu</div>
      <div class="hgrid">
        <div class="fg">
          <label class="fl">Mã phiếu</label>
          <input class="fi ro" value="Tự động (PN……)" disabled/>
          <span class="hint">Hệ thống tự sinh sau khi lưu.</span>
        </div>
        <div class="fg">
          <label class="fl">Ngày lập</label>
          <input class="fi ro" id="orderDateBox" disabled/>
        </div>
        <div class="fg">
          <label class="fl">Người lập</label>
          <input class="fi ro" value="<%= fullName %>" disabled/>
        </div>
        <div class="fg">
          <label class="fl">Nhà cung cấp <span>*</span></label>
          <input type="hidden" name="supplierId" id="hSupplierId" value="">
          <div class="cdd" id="cddSupplierId">
            <div class="cdd-btn" onclick="toggleCdd('cddSupplierId')">
              <span class="cdd-label">-- Chọn nhà cung cấp --</span>
              <span class="cdd-arrow">▼</span>
            </div>
            <div class="cdd-menu">
              <div class="cdd-opt active" data-val="" onclick="pickCdd('cddSupplierId','hSupplierId',this,false)">-- Chọn nhà cung cấp --</div>
              <c:forEach var="s" items="${suppliers}">
                <div class="cdd-opt" data-val="${s.supplierId}" onclick="pickCdd('cddSupplierId','hSupplierId',this,false)">${s.supplierName}</div>
              </c:forEach>
            </div>
          </div>
        </div>
        <div class="fg">
          <label class="fl">Trạng thái</label>
          <input type="hidden" name="status" id="hStatus" value="COMPLETED">
          <div class="cdd" id="cddStatus">
            <div class="cdd-btn" onclick="toggleCdd('cddStatus')">
              <span class="cdd-label">✅ Hàng đã về — nhập kho ngay</span>
              <span class="cdd-arrow">▼</span>
            </div>
            <div class="cdd-menu">
              <div class="cdd-opt active" data-val="COMPLETED" onclick="pickCdd('cddStatus','hStatus',this,false)">✅ Hàng đã về — nhập kho ngay</div>
              <div class="cdd-opt" data-val="PENDING" onclick="pickCdd('cddStatus','hStatus',this,false)">⏳ Đặt trước — hàng CHƯA về (kho chưa tăng, xác nhận sau)</div>
            </div>
          </div>
        </div>
        <div class="fg">
          <label class="fl">Ghi chú</label>
          <input name="notes" class="fi" placeholder="VD: Đặt định kỳ, giao trong 3 ngày…"/>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-title">Danh sách thuốc nhập</div>
      <div style="overflow-x:auto">
        <table class="line-table">
          <thead><tr>
            <th style="min-width:220px">Thuốc <span style="color:var(--red)">*</span></th>
            <th style="width:90px">SL <span style="color:var(--red)">*</span></th>
            <th style="width:130px">Giá nhập <span style="color:var(--red)">*</span></th>
            <th style="width:120px" class="num">Thành tiền</th>
            <th style="width:150px">Số lô <span style="color:var(--red)">*</span></th>
            <th style="width:150px">HSD <span style="color:var(--red)">*</span></th>
            <th style="width:44px"></th>
          </tr></thead>
          <tbody id="lineBody"></tbody>
        </table>
      </div>
      <button type="button" class="btn-add-row" onclick="addRow()">＋ Thêm dòng thuốc</button>
    </div>

    <div class="card">
      <div class="card-title">Thanh toán</div>
      <div class="hgrid" style="grid-template-columns:1fr 1fr;align-items:start">
        <div class="fg">
          <label class="fl">Phương thức thanh toán</label>
          <input type="hidden" name="paymentMethod" id="hPaymentMethod" value="">
          <div class="cdd" id="cddPaymentMethod">
            <div class="cdd-btn" onclick="toggleCdd('cddPaymentMethod')">
              <span class="cdd-label">— Chưa chọn —</span>
              <span class="cdd-arrow">▼</span>
            </div>
            <div class="cdd-menu">
              <div class="cdd-opt active" data-val="" onclick="pickCdd('cddPaymentMethod','hPaymentMethod',this,false)">— Chưa chọn —</div>
              <div class="cdd-opt" data-val="CASH" onclick="pickCdd('cddPaymentMethod','hPaymentMethod',this,false)">💵 Tiền mặt</div>
              <div class="cdd-opt" data-val="TRANSFER" onclick="pickCdd('cddPaymentMethod','hPaymentMethod',this,false)">🏦 Chuyển khoản</div>
              <div class="cdd-opt" data-val="DEBT" onclick="pickCdd('cddPaymentMethod','hPaymentMethod',this,false)">📝 Ghi nợ</div>
            </div>
          </div>
        </div>
        <div class="totals">
          <div class="trow"><span style="color:var(--muted)">Tổng tiền hàng</span><b id="totGoods">0đ</b></div>
          <div class="trow"><span style="color:var(--muted)">Chiết khấu (₫)</span>
            <input type="number" name="discountAmount" id="discountInp" min="0" step="1000" value="0" oninput="recalc()"/>
          </div>
          <div class="trow grand"><span>Phải trả</span><span id="payable">0đ</span></div>
        </div>
      </div>
    </div>

    <div class="actions">
      <c:choose>
        <c:when test="${param.embed == '1'}">
          <button type="button" class="btn-cancel" onclick="if(window.parent&&window.parent.closePoModal)window.parent.closePoModal();else history.back()">Hủy</button>
        </c:when>
        <c:otherwise>
          <a href="${pageContext.request.contextPath}/purchase-orders" class="btn-cancel">Hủy</a>
        </c:otherwise>
      </c:choose>
      <button type="submit" class="btn-save">Hoàn tất nhập kho</button>
    </div>
  </form>
</div><%-- .content --%>
</div><%-- .main --%>

<template id="rowTpl">
  <tr>
    <td>
      <%-- NOTE: kept as a native <select> — this is a per-row <template> cloned dynamically
           by addRow(); recalc()/delRow()/PRESELECT_MED logic below reads/writes tr.querySelector('select').value
           directly and relies on each cloned row getting a fresh, independent <select>. Converting
           to .cdd would require unique per-row IDs generated at clone time, so left native. --%>
      <select class="cell" name="lineMedicineId" onchange="recalc();checkLineExpiryForRow(this.closest('tr'));checkBatchDuplicateForRow(this.closest('tr'))">
        <option value="">-- Chọn thuốc --</option>
        <c:forEach var="m" items="${medicines}">
          <option value="${m.medicineId}">${fn:escapeXml(m.medicineName)} (${m.medicineCode})</option>
        </c:forEach>
      </select>
    </td>
    <td><input class="cell num" type="number" name="lineQty" min="1" placeholder="0" oninput="recalc()"/></td>
    <td><input class="cell num" type="number" name="linePrice" min="0" step="100" placeholder="0" oninput="recalc()"/></td>
    <td><span class="subtotal">0đ</span></td>
    <td>
      <input class="cell" type="text" name="lineBatchNo" placeholder="LOT-…" onblur="checkBatchDuplicateForRow(this.closest('tr'))"/>
      <span class="batch-check"></span>
    </td>
    <td>
      <input class="cell" type="date" name="lineExpiry" onchange="checkLineExpiry(this)"/>
      <input type="hidden" name="lineMfDate" value=""/>
      <span class="hsd-check"></span>
    </td>
    <td><button type="button" class="btn-del-row" onclick="delRow(this)">✕</button></td>
  </tr>
</template>

<script>
function toggleCdd(id){var w=document.getElementById(id),m=w.querySelector('.cdd-menu'),b=w.querySelector('.cdd-btn');var open=m.classList.contains('show');document.querySelectorAll('.cdd-menu.show').forEach(function(x){x.classList.remove('show');x.closest('.cdd').querySelector('.cdd-btn').classList.remove('open')});if(!open){m.classList.add('show');b.classList.add('open');var act=m.querySelector('.cdd-opt.active');if(act)act.scrollIntoView({block:'nearest'})}}
function pickCdd(wId,hId,el,autoSubmit){document.getElementById(hId).value=el.dataset.val;var w=document.getElementById(wId);w.querySelector('.cdd-label').textContent=el.textContent;w.querySelectorAll('.cdd-opt').forEach(function(o){o.classList.remove('active')});el.classList.add('active');w.querySelector('.cdd-menu').classList.remove('show');w.querySelector('.cdd-btn').classList.remove('open');if(autoSubmit){var f=w.closest('form');if(f)f.submit()}}
document.addEventListener('click',function(e){if(!e.target.closest('.cdd')){document.querySelectorAll('.cdd-menu.show').forEach(function(m){m.classList.remove('show');m.closest('.cdd').querySelector('.cdd-btn').classList.remove('open')})}});

const CTX = '${pageContext.request.contextPath}';
const fmt = n => new Intl.NumberFormat('vi-VN').format(Math.round(n||0)) + 'đ';

// ── Hạn dùng chuẩn (tháng) — CẤU HÌNH TAY, chỉ dùng khi thuốc chưa có lô nào trong kho ──
// medicineId -> số tháng, chỉ có mặt nếu thuốc đã cấu hình shelfLifeMonths (khác null).
const SHELF_LIFE_MONTHS = {
<c:forEach var="m" items="${medicines}" varStatus="st">
  <c:if test="${m.shelfLifeMonths != null}">${m.medicineId}: ${m.shelfLifeMonths}<c:if test="${!st.last}">,</c:if></c:if>
</c:forEach>
};

// ── Hạn dùng THỰC TẾ (ngày) — tính từ trung bình (ExpiryDate - ImportDate) của các lô ĐÃ
// TỪNG nhập cho thuốc đó trong bảng Batches. Nguồn dữ liệu THẬT, ưu tiên hơn hẳn số tháng
// gõ tay ở trên — chỉ fallback về SHELF_LIFE_MONTHS khi thuốc chưa có lô nào (map rỗng).
const AVG_SHELF_LIFE_DAYS = {
<c:forEach var="entry" items="${avgShelfLifeDays}" varStatus="st">${entry.key}: ${entry.value}<c:if test="${!st.last}">,</c:if></c:forEach>
};

const fmtD = d => String(d.getDate()).padStart(2,'0') + '/' + String(d.getMonth()+1).padStart(2,'0') + '/' + d.getFullYear();

// Ngưỡng CỨNG — mirror đúng trigger DB trg_Batches_BlockShortExpiry (HSD < 2 tháng thì
// KHÔNG BAO GIỜ nhập kho được, dù COMPLETED hay PENDING). Sửa số này thì sửa luôn "2" bên
// trigger SQL cho khớp. Báo NGAY ở đây để khỏi phải đợi bấm Lưu / Xác nhận Hàng Đã Tới mới biết.
const HARD_MIN_MONTHS = 2;

// So sánh HSD người dùng nhập với "ngày nhập (hôm nay) + hạn dùng chuẩn" của thuốc đã chọn.
// 2 mức: CỨNG (đỏ, chặn lưu — trùng luật trigger DB) và MỀM (vàng, chỉ cảnh báo lệch so với
// hạn dùng chuẩn cấu hình riêng cho thuốc — có thể do hàng đã nằm kho NCC một thời gian).
function checkLineExpiryForRow(tr) {
  if (!tr) return;
  const medSel   = tr.querySelector('[name=lineMedicineId]');
  const expInp   = tr.querySelector('[name=lineExpiry]');
  const warnEl   = tr.querySelector('.hsd-check');
  if (!medSel || !expInp || !warnEl) return;

  if (!expInp.value) { warnEl.className = 'hsd-check'; warnEl.textContent = ''; expInp.classList.remove('field-error'); return; }

  const today = new Date(); today.setHours(0,0,0,0);
  const entered = new Date(expInp.value + 'T00:00:00');

  // ── Tính mốc tham chiếu TRƯỚC (dùng chung cho cả cảnh báo cứng lẫn mềm bên dưới) —
  // ƯU TIÊN số ngày THỰC TẾ tính từ lịch sử lô đã nhập (AVG_SHELF_LIFE_DAYS); chỉ fallback
  // sang số tháng cấu hình tay (SHELF_LIFE_MONTHS) khi thuốc CHƯA có lô nào trong kho. ──
  const avgDays = AVG_SHELF_LIFE_DAYS[medSel.value];
  const months  = SHELF_LIFE_MONTHS[medSel.value];
  let expectedDays = null, refLabel = null;
  if (avgDays != null) {
    expectedDays = avgDays;
    refLabel = '~' + Math.round(avgDays/30) + ' tháng, tính từ lô cũ trong kho';
  } else if (months != null) {
    // Neo bằng Date.setMonth() thật (không hardcode số ngày) để tự đúng với tháng 28-31 ngày,
    // rồi quy ra số ngày để dùng chung 1 công thức so sánh với nhánh avgDays ở trên.
    const tmp = new Date(today); tmp.setMonth(tmp.getMonth() + months);
    expectedDays = Math.round((tmp - today) / 86400000);
    refLabel = months + ' tháng, cấu hình tay (thuốc chưa có lô nào trong kho)';
  }
  const expected = expectedDays != null ? new Date(today.getTime() + expectedDays * 86400000) : null;

  // ── Mức CỨNG — áp dụng cho MỌI thuốc, không cần có mốc tham chiếu ──
  const hardFloor = new Date(today);
  hardFloor.setMonth(hardFloor.getMonth() + HARD_MIN_MONTHS);
  if (entered < hardFloor) {
    warnEl.className = 'hsd-check block';
    warnEl.textContent = '⛔ HSD dưới ' + HARD_MIN_MONTHS + ' tháng — hệ thống sẽ TỪ CHỐI nhập kho lô này.'
        + (expected != null
            ? ' Theo lịch sử (' + refLabel + '), thuốc này thường có HSD khoảng ' + fmtD(expected) + ' — kiểm tra lại bao bì hoặc đổi lô khác.'
            : ' Đổi HSD hoặc dùng lô khác.');
    expInp.classList.add('field-error');
    return;
  }
  expInp.classList.remove('field-error');

  // ── Mức MỀM — chỉ cảnh báo nếu có mốc tham chiếu (avgDays hoặc months) ──
  if (expectedDays == null) { warnEl.className = 'hsd-check'; warnEl.textContent = ''; return; }

  const diffDays = Math.round((entered - expected) / 86400000);
  const TOLERANCE_DAYS = 15; // sai lệch cho phép — hàng có thể đã nằm kho NCC vài ngày trước khi giao

  if (Math.abs(diffDays) > TOLERANCE_DAYS) {
    warnEl.className = 'hsd-check warn';
    warnEl.textContent = '⚠️ Lệch so với hạn dùng (' + refLabel + ') — dự kiến khoảng ' + fmtD(expected)
        + (diffDays < 0 ? ', bạn nhập sớm hơn ' + Math.abs(diffDays) + ' ngày' : ', bạn nhập trễ hơn ' + diffDays + ' ngày')
        + '. Kiểm tra lại HSD trên bao bì!';
  } else {
    warnEl.className = 'hsd-check ok';
    warnEl.textContent = '✓ Khớp hạn dùng (' + refLabel + ', dự kiến ~' + fmtD(expected) + ')';
  }
}
function checkLineExpiry(inp) {
  checkLineExpiryForRow(inp.closest('tr'));
}

// ── Check trùng số lô qua AJAX — báo NGAY khi rời khỏi ô "Số lô", thay vì đợi tới lúc
// lưu phiếu / xác nhận nhận hàng mới bị DB (UQ_Batch) từ chối bằng exception khó hiểu.
// Seq đếm RIÊNG theo từng dòng (lưu trên chính <tr> qua dataset) — nếu dùng 1 biến đếm
// dùng chung cho mọi dòng, sửa dòng B trong lúc dòng A đang chờ response sẽ khiến kết quả
// hợp lệ của dòng A bị coi là "cũ" và bị vứt bỏ oan, dù A với B là 2 lần gọi độc lập. ──
async function checkBatchDuplicateForRow(tr) {
  if (!tr) return;
  const medSel  = tr.querySelector('[name=lineMedicineId]');
  const batchInp = tr.querySelector('[name=lineBatchNo]');
  const errEl   = tr.querySelector('.batch-check');
  if (!medSel || !batchInp || !errEl) return;

  const medId = medSel.value;
  const batchNo = batchInp.value.trim();
  if (!medId || !batchNo) { errEl.classList.remove('show'); errEl.textContent = ''; batchInp.classList.remove('field-error'); return; }

  const seq = (parseInt(tr.dataset.batchCheckSeq) || 0) + 1;
  tr.dataset.batchCheckSeq = seq;
  try {
    const res = await fetch(CTX + '/purchase-orders?action=check-batch'
        + '&medicineId=' + encodeURIComponent(medId) + '&batchNo=' + encodeURIComponent(batchNo));
    const data = await res.json();
    if (!tr.isConnected) return;                                // dòng đã bị xoá khỏi DOM
    if (parseInt(tr.dataset.batchCheckSeq) !== seq) return;      // đã có lần gọi mới hơn cho ĐÚNG dòng này
    if (data.duplicate) {
      errEl.classList.add('show');
      errEl.textContent = '⛔ Số lô này đã tồn tại trong kho cho thuốc đã chọn — dùng số lô khác.';
      batchInp.classList.add('field-error');
    } else {
      errEl.classList.remove('show');
      errEl.textContent = '';
      batchInp.classList.remove('field-error');
    }
  } catch (e) { /* lỗi mạng — không chặn, server vẫn sẽ validate lại lúc submit */ }
}

function tickClock(){
  const n=new Date(), days=['CN','T2','T3','T4','T5','T6','T7'], p=x=>String(x).padStart(2,'0');
  const dateStr = days[n.getDay()]+' '+p(n.getDate())+'/'+p(n.getMonth()+1)+'/'+n.getFullYear();
  const d=document.getElementById('clkDate'), t=document.getElementById('clkTime'), o=document.getElementById('orderDateBox');
  if(d) d.textContent=dateStr;
  if(t) t.textContent=p(n.getHours())+':'+p(n.getMinutes())+':'+p(n.getSeconds());
  if(o) o.value=dateStr;
}
tickClock(); setInterval(tickClock,1000);

function addRow(){
  const tpl=document.getElementById('rowTpl');
  document.getElementById('lineBody').appendChild(tpl.content.cloneNode(true));
  recalc();
}
function delRow(btn){
  const rows=document.querySelectorAll('#lineBody tr');
  if(rows.length<=1){
    const tr=btn.closest('tr');
    tr.querySelectorAll('input').forEach(i=>i.value='');
    tr.querySelector('select').value='';
    const warnEl=tr.querySelector('.hsd-check');
    if(warnEl){ warnEl.className='hsd-check'; warnEl.textContent=''; }
    const batchErrEl=tr.querySelector('.batch-check');
    if(batchErrEl){ batchErrEl.className='batch-check'; batchErrEl.textContent=''; }
    tr.querySelectorAll('.cell').forEach(c=>c.classList.remove('field-error'));
  } else {
    btn.closest('tr').remove();
  }
  recalc();
}
function recalc(){
  let total=0;
  document.querySelectorAll('#lineBody tr').forEach(tr=>{
    const qty=parseFloat(tr.querySelector('[name=lineQty]').value)||0;
    const price=parseFloat(tr.querySelector('[name=linePrice]').value)||0;
    const sub=qty*price;
    tr.querySelector('.subtotal').textContent=fmt(sub);
    total+=sub;
  });
  document.getElementById('totGoods').textContent=fmt(total);
  const disc=parseFloat(document.getElementById('discountInp').value)||0;
  document.getElementById('payable').textContent=fmt(Math.max(0,total-disc));
}
function beforeSubmit(){
  let ok=false;
  document.querySelectorAll('#lineBody [name=lineMedicineId]').forEach(s=>{ if(s.value) ok=true; });
  if(!ok){ alert('⚠️ Vui lòng thêm ít nhất 1 thuốc vào phiếu nhập!'); return false; }

  // CHẶN HẲN — trùng luật cứng của trigger DB / UNIQUE KEY, chắc chắn sẽ bị từ chối nếu cho lưu.
  const blockRows = document.querySelectorAll('#lineBody .hsd-check.block');
  if (blockRows.length > 0) {
    alert('⛔ Có ' + blockRows.length + ' dòng HSD dưới ' + HARD_MIN_MONTHS + ' tháng — không thể lưu.\n\nSửa lại HSD trước khi tiếp tục.');
    return false;
  }
  const dupRows = document.querySelectorAll('#lineBody .batch-check.show');
  if (dupRows.length > 0) {
    alert('⛔ Có ' + dupRows.length + ' dòng số lô đã tồn tại trong kho — không thể lưu.\n\nĐổi số lô trước khi tiếp tục.');
    return false;
  }

  // CHỈ CẢNH BÁO — lệch so với hạn dùng chuẩn cấu hình riêng, admin có thể chủ động bỏ qua.
  const warnRows = document.querySelectorAll('#lineBody .hsd-check.warn');
  if (warnRows.length > 0) {
    return confirm('⚠️ Có ' + warnRows.length + ' dòng HSD lệch nhiều so với hạn dùng chuẩn của thuốc.\n\n'
        + 'Kiểm tra lại HSD trên bao bì thực tế trước khi tiếp tục. Vẫn lưu phiếu này?');
  }
  return true;
}
addRow();
// Nhảy từ màn "thuốc đã tồn tại" → tự chọn sẵn thuốc đó vào dòng đầu
const PRESELECT_MED = ${preselectMedicineId != null ? preselectMedicineId : 0};
if (PRESELECT_MED > 0) {
  const sel = document.querySelector('#lineBody [name=lineMedicineId]');
  if (sel) { sel.value = String(PRESELECT_MED); recalc(); }
}
</script>
</body>
</html>
