<%@ page contentType="text/html;charset=UTF-8"  pageEncoding="UTF-8" %>
<% String activeNav = "medicines"; %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length() >= 2 ? fullName.substring(0,2).toUpperCase() : fullName.toUpperCase();
    com.medicare.entity.Shelf sh = (com.medicare.entity.Shelf) request.getAttribute("shelf");
    boolean isNew = (sh == null || sh.getShelfId() == 0);
    String type = sh != null && sh.getShelfType() != null ? sh.getShelfType() : "RETAIL";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
    
    
    
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title><%= isNew ? "Thêm" : "Sửa" %> kệ — MediCare</title>

<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;--surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;--red:#DC2626;--sidebar:232px;}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}
/* Sidebar CSS: dùng bản chuẩn từ sidebar.jsp include bên dưới, không định nghĩa lại ở đây. */
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.btn-back{display:inline-flex;align-items:center;gap:6px;padding:6px 14px;border-radius:9px;border:1.5px solid var(--border);background:var(--white);color:var(--ink);font-size:13px;font-weight:750;text-decoration:none}
.btn-back:hover{border-color:var(--blue);color:var(--blue)}.topbar-title{font-size:16px;font-weight:750}
.content{max-width:640px;margin:26px auto;padding:0 22px 48px;width:100%}
.page-title{font-size:23px;font-weight:800;margin-bottom:16px}
.error-box{background:#FFF5F5;border:1px solid #FECACA;border-radius:12px;padding:12px 16px;margin-bottom:16px;font-size:13px;color:#991B1B;font-weight:750}
.card{background:var(--white);border:1px solid var(--border);border-radius:16px;padding:24px}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:15px}
.fg{display:flex;flex-direction:column;gap:5px}.fg.full{grid-column:1/-1}
.fl{font-size:12.5px;font-weight:750}.fl span{color:var(--red)}
.fi,.fs{height:42px;padding:0 12px;border:1.5px solid var(--border);border-radius:10px;font-size:13.5px;font-family:inherit;outline:none;background:#fff}
.fi:focus,.fs:focus{border-color:var(--blue)}
textarea.fi{height:auto;min-height:64px;padding:10px 12px;resize:vertical}
.chk{display:flex;align-items:center;gap:9px;padding:11px 14px;border:1.5px solid var(--border);border-radius:10px;font-size:13.5px;font-weight:750;cursor:pointer}
.chk input{width:17px;height:17px;accent-color:var(--blue)}
.hint{font-size:11px;color:var(--muted)}
.actions{display:flex;gap:10px;margin-top:20px}
.btn-save{flex:1;height:46px;background:linear-gradient(135deg,#1558A8,#0d3d63);color:#fff;border:none;border-radius:11px;font-size:15px;font-weight:800;cursor:pointer;font-family:inherit}
.btn-cancel{height:46px;padding:0 22px;border:1.5px solid var(--border);border-radius:11px;background:#fff;color:var(--muted);font-weight:750;cursor:pointer;font-family:inherit;text-decoration:none;display:inline-flex;align-items:center}
.btn-cancel:hover{border-color:var(--red);color:var(--red)}
#machineBox{display:none}
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
    
</head>
<body>
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>
<div class="main">
  <div class="topbar">
    <a href="${pageContext.request.contextPath}/shelves" class="btn-back">← Vị trí kệ</a>
    <span class="topbar-title"><%= isNew ? "Thêm kệ" : "Sửa kệ" %></span>
  </div>
  <div class="content">
    <div class="page-title"><%= isNew ? "📍 Thêm vị trí kệ" : "✏️ Sửa vị trí kệ" %></div>
    <c:if test="${not empty error}"><div class="error-box">⚠️ ${error}</div></c:if>
    <form method="post" action="${pageContext.request.contextPath}/shelves">
      <c:if test="${shelf != null && shelf.shelfId != 0}">
        <input type="hidden" name="shelfId" value="${shelf.shelfId}"/>
      </c:if>
      <div class="card">
        <div class="grid">
          <div class="fg full"><label class="fl">Tên kệ <span>*</span></label>
            <input class="fi" name="shelfName" required value="${shelf != null ? shelf.shelfName : ''}" placeholder="VD: Kệ A1, Quầy thuốc kê toa..."/></div>
          <div class="fg"><label class="fl">Loại kệ</label>
            <select class="fs" name="shelfType" id="shelfType" onchange="toggleMachine()">
              <option value="RETAIL"  <%= "RETAIL".equals(type)  ? "selected" : "" %>>🛒 Quầy bán</option>
              <option value="STORAGE" <%= "STORAGE".equals(type) ? "selected" : "" %>>📦 Kho lưu trữ</option>
              <option value="MACHINE" <%= "MACHINE".equals(type) ? "selected" : "" %>>🤖 Máy bán tự động</option>
            </select></div>
          <div class="fg full" id="machineBox">
            <div class="grid">
              <div class="fg"><label class="fl">Mã ngăn máy</label>
                <input class="fi" name="machineSlotCode" value="${shelf != null ? shelf.machineSlotCode : ''}" placeholder="VD: A-01"/></div>
              <div class="fg"><label class="fl">Motor ID</label>
                <input class="fi" name="motorId" value="${shelf != null ? shelf.motorId : ''}" placeholder="VD: M-12"/></div>
            </div>
            <span class="hint">Chỉ dùng cho kệ máy bán tự động (vending).</span>
          </div>
          <div class="fg full"><label class="fl">Ghi chú vị trí</label>
            <textarea class="fi" name="locationNotes" placeholder="VD: Góc trái phòng, tầng 2...">${shelf != null ? shelf.locationNotes : ''}</textarea></div>
        </div>
        <div class="actions">
          <a href="${pageContext.request.contextPath}/shelves" class="btn-cancel">Hủy</a>
          <button type="submit" class="btn-save"><%= isNew ? "💾 Thêm kệ" : "💾 Lưu thay đổi" %></button>
        </div>
      </div>
    </form>
  </div>
</div>
<script>
function toggleCdd(id){var w=document.getElementById(id),m=w.querySelector('.cdd-menu'),b=w.querySelector('.cdd-btn');var open=m.classList.contains('show');document.querySelectorAll('.cdd-menu.show').forEach(function(x){x.classList.remove('show');x.closest('.cdd').querySelector('.cdd-btn').classList.remove('open')});if(!open){m.classList.add('show');b.classList.add('open');var act=m.querySelector('.cdd-opt.active');if(act)act.scrollIntoView({block:'nearest'})}}
function pickCdd(wId,hId,el,autoSubmit){document.getElementById(hId).value=el.dataset.val;var w=document.getElementById(wId);w.querySelector('.cdd-label').textContent=el.textContent;w.querySelectorAll('.cdd-opt').forEach(function(o){o.classList.remove('active')});el.classList.add('active');w.querySelector('.cdd-menu').classList.remove('show');w.querySelector('.cdd-btn').classList.remove('open');if(autoSubmit){var f=w.closest('form');if(f)f.submit()}}
document.addEventListener('click',function(e){if(!e.target.closest('.cdd')){document.querySelectorAll('.cdd-menu.show').forEach(function(m){m.classList.remove('show');m.closest('.cdd').querySelector('.cdd-btn').classList.remove('open')})}});

function toggleMachine(){
  const t = document.getElementById('shelfType').value;
  document.getElementById('machineBox').style.display = (t === 'MACHINE') ? 'block' : 'none';
}
toggleMachine();
</script>
</body>
</html>
