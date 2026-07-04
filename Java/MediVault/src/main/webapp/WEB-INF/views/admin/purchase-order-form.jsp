<%@ page contentType="text/html;charset=UTF-8" %>
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
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Tạo phiếu nhập kho — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;--sidebar:232px;
}
html,body{height:100%;font-family:'Outfit',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-text{font-size:16px;font-weight:800;color:#fff;line-height:1.1}
.logo-text span{color:var(--cyan)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:12px 0 4px;flex-shrink:0}
.nav-label{font-size:9px;font-weight:700;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:500;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.14);font-weight:600}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--cyan);border-radius:2px}
.nav-badge{margin-left:auto;background:#DC2626;color:#fff;font-size:10px;font-weight:700;padding:1px 7px;border-radius:20px;min-width:20px;text-align:center}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50;flex-shrink:0}
.topbar-title{font-size:16px;font-weight:700}
.btn-back{display:inline-flex;align-items:center;gap:6px;padding:6px 14px;border-radius:9px;border:1.5px solid var(--border);background:var(--white);color:var(--ink);font-size:13px;font-weight:600;text-decoration:none}
.btn-back:hover{border-color:var(--blue);color:var(--blue)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:12px}
.clock{display:inline-flex;align-items:center;gap:6px;padding:6px 13px;border-radius:20px;background:#EFF6FF;color:var(--blue);font-size:12.5px;font-weight:700;white-space:nowrap}
.clock .cl-time{font-variant-numeric:tabular-nums;font-weight:800}
.user-av-sm{width:32px;height:32px;border-radius:50%;background:linear-gradient(135deg,#3ABDE0,#1558A8);display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.content{max-width:1040px;margin:24px auto;padding:0 22px 48px;width:100%}
.page-title{font-size:23px;font-weight:900;margin-bottom:3px}
.page-sub{font-size:13px;color:var(--muted);margin-bottom:18px}
.error-box{background:#FFF5F5;border:1px solid #FECACA;border-radius:12px;padding:14px 18px;margin-bottom:18px}
.error-box ul{margin:0;padding-left:18px}.error-box li{font-size:13px;color:#991B1B;margin:3px 0}
.card{background:var(--white);border:1px solid var(--border);border-radius:16px;padding:20px 22px;margin-bottom:14px}
.card-title{font-size:14px;font-weight:800;color:var(--navy);margin-bottom:14px;display:flex;align-items:center;gap:8px}
.hgrid{display:grid;grid-template-columns:1fr 1fr 1fr;gap:14px}
@media(max-width:760px){.hgrid{grid-template-columns:1fr}}
.fg{display:flex;flex-direction:column;gap:5px}
.fl{font-size:12px;font-weight:700;color:var(--ink)}.fl span{color:var(--red)}
.fi,.fs{height:40px;padding:0 11px;border:1.5px solid var(--border);border-radius:9px;font-size:13.5px;font-family:inherit;color:var(--ink);background:var(--white);outline:none}
.fi:focus,.fs:focus{border-color:var(--blue)}
.ro{background:#F8FAFC;color:var(--muted);cursor:default}
.hint{font-size:11px;color:var(--muted)}
/* Grid */
.line-table{width:100%;border-collapse:collapse}
.line-table th{font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.4px;color:var(--muted);text-align:left;padding:6px 8px;white-space:nowrap}
.line-table td{padding:5px 6px;vertical-align:top}
.line-table .num{text-align:right}
.cell{width:100%;height:38px;padding:0 9px;border:1.5px solid var(--border);border-radius:8px;font-size:13px;font-family:inherit;background:var(--white);outline:none}
.cell:focus{border-color:var(--blue)}
.subtotal{font-weight:800;color:var(--navy);font-size:13.5px;white-space:nowrap;padding-top:9px;display:block;text-align:right}
.btn-del-row{width:34px;height:34px;border:none;background:#FEF2F2;color:var(--red);border-radius:8px;cursor:pointer;font-size:15px}
.btn-del-row:hover{background:#FEE2E2}
.btn-add-row{margin-top:10px;background:#EFF6FF;color:var(--blue);border:1.5px dashed #93C5FD;border-radius:10px;padding:10px 16px;font-size:13px;font-weight:700;cursor:pointer;font-family:inherit}
.btn-add-row:hover{background:#DBEAFE}
.totals{margin-left:auto;max-width:360px}
.trow{display:flex;justify-content:space-between;align-items:center;padding:8px 0;font-size:13.5px}
.trow.grand{border-top:2px solid var(--border);margin-top:6px;padding-top:12px;font-size:17px;font-weight:900;color:var(--blue)}
.trow input{width:150px;height:36px;text-align:right;border:1.5px solid var(--border);border-radius:8px;padding:0 10px;font-family:inherit;font-size:13.5px}
.actions{display:flex;gap:10px;margin-top:18px}
.btn-save{flex:1;height:48px;background:linear-gradient(135deg,#1558A8,#0d3d63);color:#fff;border:none;border-radius:12px;font-size:15px;font-weight:800;cursor:pointer;font-family:inherit}
.btn-save:hover{filter:brightness(1.08)}
.btn-cancel{height:48px;padding:0 24px;border:1.5px solid var(--border);border-radius:12px;background:var(--white);color:var(--muted);font-weight:600;cursor:pointer;font-family:inherit;text-decoration:none;display:inline-flex;align-items:center}
.btn-cancel:hover{border-color:var(--red);color:var(--red)}
</style>
</head>
<body>
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">
<div class="topbar">
  <a href="${pageContext.request.contextPath}/purchase-orders" class="btn-back">← Đơn đặt hàng</a>
  <span class="topbar-title">Tạo phiếu nhập kho</span>
  <div class="topbar-right">
    <span class="clock">🕐 <span id="clkDate"></span> · <span class="cl-time" id="clkTime"></span></span>
    <div class="user-av-sm"><%= initials %></div>
  </div>
</div>

<div class="content">
  <div class="page-title">📋 Tạo phiếu nhập kho</div>
  <div class="page-sub">Nhập nhiều thuốc trong 1 phiếu — mỗi dòng tạo 1 lô hàng (số lô + HSD riêng). Lưu 1 lần, tồn kho tăng ngay.</div>

  <c:if test="${not empty errors}">
    <div class="error-box"><ul><c:forEach var="e" items="${errors}"><li>${e}</li></c:forEach></ul></div>
  </c:if>

  <form method="post" action="${pageContext.request.contextPath}/purchase-orders" onsubmit="return beforeSubmit()">
    <input type="hidden" name="action" value="save"/>

    <div class="card">
      <div class="card-title">🧾 Thông tin phiếu</div>
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
          <select name="supplierId" class="fs" required>
            <option value="">-- Chọn nhà cung cấp --</option>
            <c:forEach var="s" items="${suppliers}">
              <option value="${s.supplierId}">${s.supplierName}</option>
            </c:forEach>
          </select>
        </div>
        <div class="fg">
          <label class="fl">Trạng thái</label>
          <select name="status" class="fs">
            <option value="COMPLETED">✅ Đã nhập kho (hàng đã về)</option>
            <option value="PENDING">⏳ Chờ xử lý (chưa về)</option>
          </select>
        </div>
        <div class="fg">
          <label class="fl">Ghi chú</label>
          <input name="notes" class="fi" placeholder="VD: Đặt định kỳ, giao trong 3 ngày…"/>
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-title">💊 Danh sách thuốc nhập</div>
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
      <div class="card-title">💰 Thanh toán</div>
      <div class="hgrid" style="grid-template-columns:1fr 1fr;align-items:start">
        <div class="fg">
          <label class="fl">Phương thức thanh toán</label>
          <select name="paymentMethod" class="fs">
            <option value="">— Chưa chọn —</option>
            <option value="CASH">💵 Tiền mặt</option>
            <option value="TRANSFER">🏦 Chuyển khoản</option>
            <option value="DEBT">📝 Ghi nợ</option>
          </select>
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
      <a href="${pageContext.request.contextPath}/purchase-orders" class="btn-cancel">Hủy</a>
      <button type="submit" class="btn-save">✅ Hoàn tất nhập kho</button>
    </div>
  </form>
</div><%-- .content --%>
</div><%-- .main --%>

<template id="rowTpl">
  <tr>
    <td>
      <select class="cell" name="lineMedicineId" onchange="recalc()">
        <option value="">-- Chọn thuốc --</option>
        <c:forEach var="m" items="${medicines}">
          <option value="${m.medicineId}">${fn:escapeXml(m.medicineName)} (${m.medicineCode})</option>
        </c:forEach>
      </select>
    </td>
    <td><input class="cell num" type="number" name="lineQty" min="1" placeholder="0" oninput="recalc()"/></td>
    <td><input class="cell num" type="number" name="linePrice" min="0" step="100" placeholder="0" oninput="recalc()"/></td>
    <td><span class="subtotal">0đ</span></td>
    <td><input class="cell" type="text" name="lineBatchNo" placeholder="LOT-…"/></td>
    <td><input class="cell" type="date" name="lineExpiry"/><input type="hidden" name="lineMfDate" value=""/></td>
    <td><button type="button" class="btn-del-row" onclick="delRow(this)">✕</button></td>
  </tr>
</template>

<script>
const fmt = n => new Intl.NumberFormat('vi-VN').format(Math.round(n||0)) + 'đ';

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
  return true;
}
addRow();
</script>
</body>
</html>
