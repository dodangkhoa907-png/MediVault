<%@ page contentType="text/html;charset=UTF-8"  pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
    com.medicare.entity.Customer customer = (com.medicare.entity.Customer) request.getAttribute("customer");
    boolean isNew = customer == null || customer.getCustomerId() == 0;
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
    
    
    
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title><%= isNew ? "Thêm khách hàng" : "Sửa khách hàng" %> — MediCare</title>


<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;--red:#DC2626;
}
html,body{min-height:100%;font-family:'Plus Jakarta Sans',sans-serif;background:var(--surface);color:var(--ink)}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Plus Jakarta Sans',sans-serif;font-size:16px;font-weight:750;color:var(--ink)}
.btn-back{display:inline-flex;align-items:center;gap:6px;padding:6px 14px;border-radius:9px;border:1.5px solid var(--border);background:var(--white);color:var(--ink);font-size:13px;font-weight:750;text-decoration:none}
.btn-back:hover{border-color:var(--blue);color:var(--blue)}

    
.topbar-right{margin-left:auto}
.user-av-sm{width:32px;height:32px;border-radius:50%;background:linear-gradient(135deg,#3ABDE0,#1558A8);display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.content{max-width:680px;margin:28px auto;padding:0 20px 40px}
.page-title{font-size:24px;font-weight:800;margin-bottom:4px}
.page-sub{font-size:13px;color:var(--muted);margin-bottom:20px}
.error-box{background:#FFF5F5;border:1px solid #FECACA;border-radius:12px;padding:14px 18px;margin-bottom:18px}
.error-box ul{margin:0;padding-left:18px}
.error-box li{font-size:13px;color:#991B1B;margin:3px 0}
.card{background:var(--white);border:1px solid var(--border);border-radius:16px;padding:24px;margin-bottom:16px}
.card-title{font-size:13px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.4px;margin-bottom:14px}
.form-row{display:grid;grid-template-columns:1fr 1fr;gap:14px}
.form-group{display:flex;flex-direction:column;gap:5px;margin-bottom:14px}
.form-label{font-size:12.5px;font-weight:750;color:var(--ink)}
.form-label span{color:var(--red)}
.form-input,.form-select,textarea{padding:10px 12px;border:1.5px solid var(--border);border-radius:10px;font-size:13.5px;font-family:inherit;color:var(--ink);background:var(--white);outline:none;width:100%}
.form-input:focus,.form-select:focus,textarea:focus{border-color:var(--blue)}
.form-actions{display:flex;gap:10px;margin-top:6px}
.btn-save{flex:1;height:44px;background:var(--blue);color:#fff;border:none;border-radius:11px;font-size:15px;font-weight:800;cursor:pointer;font-family:inherit}
.btn-save:hover{background:#0d3d63}
.btn-cancel{height:44px;padding:0 22px;border:1.5px solid var(--border);border-radius:11px;background:var(--white);color:var(--muted);font-size:14px;font-weight:750;cursor:pointer;font-family:inherit;text-decoration:none;display:inline-flex;align-items:center}
.btn-cancel:hover{border-color:var(--red);color:var(--red)}
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
<div class="topbar">
  <a href="${pageContext.request.contextPath}/customers" class="btn-back">← Khách hàng</a>
  <span class="topbar-title"><%= isNew ? "Thêm khách hàng" : "Sửa khách hàng" %></span>
  <div class="topbar-right"><div class="user-av-sm"><%= initials %></div></div>
</div>

<div class="content">
  <div class="page-title"><%= isNew ? "👥 Thêm khách hàng mới" : "✏️ Sửa thông tin khách hàng" %></div>
  <div class="page-sub">Số điện thoại không bắt buộc, nhưng nếu nhập thì phải là duy nhất trong hệ thống.</div>

  <c:if test="${not empty errors}">
    <div class="error-box"><ul><c:forEach var="e" items="${errors}"><li>${e}</li></c:forEach></ul></div>
  </c:if>

  <form method="post" action="${pageContext.request.contextPath}/customers">
    <input type="hidden" name="action" value="save"/>
    <% if (!isNew) { %><input type="hidden" name="customerId" value="<%= customer.getCustomerId() %>"/><% } %>

    <div class="card">
      <div class="card-title">Thông tin cơ bản</div>
      <div class="form-group">
        <label class="form-label">Họ và tên <span>*</span></label>
        <input type="text" name="customerName" class="form-input" value="${customer.customerName}" required>
      </div>
      <div class="form-row">
        <div class="form-group">
          <label class="form-label">Số điện thoại</label>
          <input type="text" name="phone" class="form-input" value="${customer.phone}" placeholder="09xxxxxxxx">
        </div>
        <div class="form-group">
          <label class="form-label">Email</label>
          <input type="email" name="email" class="form-input" value="${customer.email}">
        </div>
      </div>
      <div class="form-row">
        <div class="form-group">
          <label class="form-label">Ngày sinh</label>
          <input type="date" name="dateOfBirth" class="form-input" value="${customer.dateOfBirth}">
        </div>
        <div class="form-group">
          <label class="form-label">Giới tính</label>
          <input type="hidden" name="gender" id="hGender" value="${customer.gender}">
          <div class="cdd" id="cddGender">
            <div class="cdd-btn" onclick="toggleCdd('cddGender')">
              <span class="cdd-label">
                <c:choose>
                  <c:when test="${customer.gender == 'M'}">Nam</c:when>
                  <c:when test="${customer.gender == 'F'}">Nữ</c:when>
                  <c:when test="${customer.gender == 'OTHER'}">Khác</c:when>
                  <c:otherwise>-- Không rõ --</c:otherwise>
                </c:choose>
              </span>
              <span class="cdd-arrow">▼</span>
            </div>
            <div class="cdd-menu">
              <div class="cdd-opt ${empty customer.gender ? 'active' : ''}" data-val="" onclick="pickCdd('cddGender','hGender',this,false)">-- Không rõ --</div>
              <div class="cdd-opt ${customer.gender == 'M' ? 'active' : ''}" data-val="M" onclick="pickCdd('cddGender','hGender',this,false)">Nam</div>
              <div class="cdd-opt ${customer.gender == 'F' ? 'active' : ''}" data-val="F" onclick="pickCdd('cddGender','hGender',this,false)">Nữ</div>
              <div class="cdd-opt ${customer.gender == 'OTHER' ? 'active' : ''}" data-val="OTHER" onclick="pickCdd('cddGender','hGender',this,false)">Khác</div>
            </div>
          </div>
        </div>
      </div>
      <div class="form-group">
        <label class="form-label">Địa chỉ</label>
        <input type="text" name="address" class="form-input" value="${customer.address}">
      </div>
      <div class="form-row">
        <div class="form-group">
          <label class="form-label">CCCD/CMND</label>
          <input type="text" name="nationalId" class="form-input" value="${customer.nationalId}">
        </div>
        <div class="form-group">
          <label class="form-label">Nghề nghiệp</label>
          <input type="text" name="occupation" class="form-input" value="${customer.occupation}">
        </div>
      </div>
    </div>

    <div class="card">
      <div class="card-title">Thông tin y tế (không bắt buộc)</div>
      <div class="form-group">
        <label class="form-label">Tiền sử dị ứng</label>
        <textarea name="allergyHistory" rows="2" placeholder="VD: Dị ứng Penicillin...">${customer.allergyHistory}</textarea>
      </div>
      <div class="form-group">
        <label class="form-label">Bệnh mạn tính</label>
        <textarea name="chronicDisease" rows="2" placeholder="VD: Tiểu đường, cao huyết áp...">${customer.chronicDisease}</textarea>
      </div>
    </div>

    <div class="form-actions">
      <a href="${pageContext.request.contextPath}/customers" class="btn-cancel">Hủy</a>
      <button type="submit" class="btn-save"><%= isNew ? "👥 Thêm khách hàng" : "💾 Lưu thay đổi" %></button>
    </div>
  </form>
</div>
<script>
function toggleCdd(id){var w=document.getElementById(id),m=w.querySelector('.cdd-menu'),b=w.querySelector('.cdd-btn');var open=m.classList.contains('show');document.querySelectorAll('.cdd-menu.show').forEach(function(x){x.classList.remove('show');x.closest('.cdd').querySelector('.cdd-btn').classList.remove('open')});if(!open){m.classList.add('show');b.classList.add('open');var act=m.querySelector('.cdd-opt.active');if(act)act.scrollIntoView({block:'nearest'})}}
function pickCdd(wId,hId,el,autoSubmit){document.getElementById(hId).value=el.dataset.val;var w=document.getElementById(wId);w.querySelector('.cdd-label').textContent=el.textContent;w.querySelectorAll('.cdd-opt').forEach(function(o){o.classList.remove('active')});el.classList.add('active');w.querySelector('.cdd-menu').classList.remove('show');w.querySelector('.cdd-btn').classList.remove('open');if(autoSubmit){var f=w.closest('form');if(f)f.submit()}}
document.addEventListener('click',function(e){if(!e.target.closest('.cdd')){document.querySelectorAll('.cdd-menu.show').forEach(function(m){m.classList.remove('show');m.closest('.cdd').querySelector('.cdd-btn').classList.remove('open')})}});
</script>
</body>
</html>
