<%@ page contentType="text/html;charset=UTF-8"  pageEncoding="UTF-8" %>
<% String activeNav = "medicines"; %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length() >= 2 ? fullName.substring(0,2).toUpperCase() : fullName.toUpperCase();
    com.medicare.entity.Supplier s = (com.medicare.entity.Supplier) request.getAttribute("supplier");
    boolean isNew = (s == null || s.getSupplierId() == 0);
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
    
    
    
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title><%= isNew ? "Thêm" : "Sửa" %> nhà cung cấp — MediCare</title>

<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{--ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;--surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;--red:#DC2626;--sidebar:232px;}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}
/* Sidebar CSS: dùng bản chuẩn từ sidebar.jsp include bên dưới, không định nghĩa lại ở đây. */
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.btn-back{display:inline-flex;align-items:center;gap:6px;padding:6px 14px;border-radius:9px;border:1.5px solid var(--border);background:var(--white);color:var(--ink);font-size:13px;font-weight:750;text-decoration:none}
.btn-back:hover{border-color:var(--blue);color:var(--blue)}
.topbar-title{font-size:16px;font-weight:750}
.content{max-width:680px;margin:26px auto;padding:0 22px 48px;width:100%}
.page-title{font-size:23px;font-weight:800;margin-bottom:16px}
.error-box{background:#FFF5F5;border:1px solid #FECACA;border-radius:12px;padding:12px 16px;margin-bottom:16px;font-size:13px;color:#991B1B;font-weight:750}
.card{background:var(--white);border:1px solid var(--border);border-radius:16px;padding:24px}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:15px}
.fg{display:flex;flex-direction:column;gap:5px}.fg.full{grid-column:1/-1}
.fl{font-size:12.5px;font-weight:750}.fl span{color:var(--red)}
.fi{height:42px;padding:0 12px;border:1.5px solid var(--border);border-radius:10px;font-size:13.5px;font-family:inherit;outline:none}
.fi:focus{border-color:var(--blue)}
textarea.fi{height:auto;min-height:70px;padding:10px 12px;resize:vertical}
.chk{display:flex;align-items:center;gap:9px;padding:11px 14px;border:1.5px solid var(--border);border-radius:10px;font-size:13.5px;font-weight:750;cursor:pointer}
.chk input{width:17px;height:17px;accent-color:var(--blue)}
.actions{display:flex;gap:10px;margin-top:20px}
.btn-save{flex:1;height:46px;background:linear-gradient(135deg,#1558A8,#0d3d63);color:#fff;border:none;border-radius:11px;font-size:15px;font-weight:800;cursor:pointer;font-family:inherit}
.btn-cancel{height:46px;padding:0 22px;border:1.5px solid var(--border);border-radius:11px;background:#fff;color:var(--muted);font-weight:750;cursor:pointer;font-family:inherit;text-decoration:none;display:inline-flex;align-items:center}
.btn-cancel:hover{border-color:var(--red);color:var(--red)}
</style>
    
</head>
<body>
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>
<div class="main">
  <div class="topbar">
    <a href="${pageContext.request.contextPath}/suppliers" class="btn-back">← Nhà cung cấp</a>
    <span class="topbar-title"><%= isNew ? "Thêm nhà cung cấp" : "Sửa nhà cung cấp" %></span>
  </div>
  <div class="content">
    <div class="page-title"><%= isNew ? "🏭 Thêm nhà cung cấp" : "✏️ Sửa nhà cung cấp" %></div>
    <c:if test="${not empty error}"><div class="error-box">⚠️ ${error}</div></c:if>
    <form method="post" action="${pageContext.request.contextPath}/suppliers">
      <c:if test="${supplier != null && supplier.supplierId != 0}">
        <input type="hidden" name="supplierId" value="${supplier.supplierId}"/>
      </c:if>
      <div class="card">
        <div class="grid">
          <div class="fg full"><label class="fl">Tên nhà cung cấp <span>*</span></label>
            <input class="fi" name="supplierName" required value="${supplier != null ? supplier.supplierName : ''}" placeholder="VD: Công ty Dược ABC"/></div>
          <div class="fg"><label class="fl">Người liên hệ</label>
            <input class="fi" name="contactName" value="${supplier != null ? supplier.contactName : ''}" placeholder="VD: Nguyễn Văn A"/></div>
          <div class="fg"><label class="fl">Số điện thoại</label>
            <input class="fi" name="phone" value="${supplier != null ? supplier.phone : ''}" placeholder="VD: 0901234567"/></div>
          <div class="fg"><label class="fl">Email</label>
            <input class="fi" type="email" name="email" value="${supplier != null ? supplier.email : ''}" placeholder="VD: contact@abc.vn"/></div>
          <div class="fg"><label class="fl">Số giấy phép KD</label>
            <input class="fi" name="licenseNumber" value="${supplier != null ? supplier.licenseNumber : ''}" placeholder="VD: GPKD-12345"/></div>
          <div class="fg full"><label class="fl">Địa chỉ</label>
            <textarea class="fi" name="address" placeholder="Địa chỉ đầy đủ...">${supplier != null ? supplier.address : ''}</textarea></div>
          <c:if test="${supplier != null && supplier.supplierId != 0}">
          <div class="fg full"><label class="chk"><input type="checkbox" name="isActive" ${supplier.active ? 'checked' : ''} value="on"> Đang hợp tác (bỏ tick = ngừng)</label></div>
          </c:if>
        </div>
        <div class="actions">
          <a href="${pageContext.request.contextPath}/suppliers" class="btn-cancel">Hủy</a>
          <button type="submit" class="btn-save"><%= isNew ? "💾 Thêm nhà cung cấp" : "💾 Lưu thay đổi" %></button>
        </div>
      </div>
    </form>
  </div>
</div>
</body>
</html>
