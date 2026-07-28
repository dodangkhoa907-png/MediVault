<%@ page contentType="text/html;charset=UTF-8"  pageEncoding="UTF-8" %>
<% String activeNav = "medicines"; %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();

    com.medicare.entity.Category cat = (com.medicare.entity.Category) request.getAttribute("category");
    boolean isNew = (cat == null || cat.getCategoryId() == 0);
    String vName = cat != null && cat.getCategoryName() != null ? cat.getCategoryName() : "";
    String vDesc = cat != null && cat.getDescription() != null ? cat.getDescription() : "";
    String error = (String) request.getAttribute("error");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
    
    
    
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title><%= isNew ? "Thêm danh mục" : "Sửa danh mục" %> — MediCare</title>


<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--sidebar:232px;
}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}
/* Sidebar CSS: dùng bản chuẩn từ sidebar.jsp include bên dưới, không định nghĩa lại ở đây. */
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Plus Jakarta Sans',sans-serif;font-size:16px;font-weight:750;color:var(--ink)}

    
.btn-back{height:36px;padding:0 14px;background:var(--white);border:1.5px solid var(--border);border-radius:9px;font-size:13px;font-weight:750;color:var(--muted);text-decoration:none;display:inline-flex;align-items:center;gap:6px;margin-left:auto;transition:all .15s}
.btn-back:hover{border-color:var(--blue);color:var(--navy)}
.content{padding:32px 28px;flex:1;max-width:600px}
.page-title{font-size:24px;font-weight:800;color:var(--ink);margin-bottom:4px}
.page-sub{font-size:13px;color:var(--muted);margin-bottom:24px}
.err-block{background:#FEF2F2;border:1.5px solid #FECACA;border-left:3px solid var(--red);border-radius:12px;padding:14px 18px;margin-bottom:18px;font-size:13px;color:var(--red);font-weight:750}
.form-card{background:var(--white);border:1px solid var(--border);border-radius:16px;overflow:hidden;box-shadow:0 2px 8px rgba(21,88,168,.04)}
.form-body{padding:24px}
.field{display:flex;flex-direction:column;gap:6px;margin-bottom:18px}
.field:last-child{margin-bottom:0}
.field-label{font-size:12.5px;font-weight:750;color:var(--navy);display:flex;align-items:center;gap:4px}
.req{color:var(--red)}
.field-input{height:42px;padding:0 14px;background:#fff;border:1.5px solid var(--border);border-radius:11px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13.5px;color:var(--ink);outline:none;transition:border-color .18s}
.field-input:focus{border-color:var(--cyan);box-shadow:0 0 0 3px rgba(58,189,224,.12)}
textarea.field-input{height:90px;padding:10px 14px;resize:vertical}
.action-row{display:flex;align-items:center;gap:12px;padding:16px 24px;background:linear-gradient(90deg,#FAFBFD,var(--surface));border-top:1px solid var(--border)}
.btn-submit{height:40px;padding:0 22px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;border-radius:11px;font-family:'Plus Jakarta Sans',sans-serif;font-size:14px;font-weight:750;cursor:pointer;transition:all .22s;box-shadow:0 4px 14px rgba(21,88,168,.28)}
.btn-submit:hover{transform:translateY(-1px)}
.btn-cancel{height:40px;padding:0 18px;background:var(--white);border:1.5px solid var(--border);border-radius:11px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13.5px;font-weight:750;color:var(--muted);text-decoration:none;display:inline-flex;align-items:center;transition:all .18s}
.btn-cancel:hover{border-color:var(--blue);color:var(--navy)}
</style>
    
<meta name="csrf-token" content="${csrfToken}">
<script src="${pageContext.request.contextPath}/js/csrf.js"></script>
</head>
<body>

<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">
  <div class="topbar">
    <span class="topbar-title"><%= isNew ? "➕ Thêm danh mục" : "✏️ Sửa danh mục" %></span>
    <a href="${pageContext.request.contextPath}/categories" class="btn-back">← Danh sách</a>
  </div>

  <div class="content">
    <div class="page-title"><%= isNew ? "Thêm danh mục mới" : "Sửa danh mục" %></div>
    <div class="page-sub">Phân loại giúp tìm kiếm thuốc nhanh hơn trong kho và POS.</div>

    <% if (error != null) { %><div class="err-block">⚠️ <%= error %></div><% } %>

    <div class="form-card">
      <form method="post" action="${pageContext.request.contextPath}/categories">
        <input type="hidden" name="_csrf" value="${csrfToken}">
        <% if (!isNew) { %>
        <input type="hidden" name="categoryId" value="<%= cat.getCategoryId() %>">
        <% } %>
        <div class="form-body">
          <div class="field">
            <label class="field-label" for="categoryName">Tên danh mục <span class="req">*</span></label>
            <input type="text" id="categoryName" name="categoryName" class="field-input"
                   value="<%= vName %>" placeholder="VD: Kháng sinh, Vitamin, Giảm đau..." required>
          </div>
          <div class="field">
            <label class="field-label" for="description">Mô tả</label>
            <textarea id="description" name="description" class="field-input"
                      placeholder="Mô tả ngắn về danh mục này (không bắt buộc)..."><%= vDesc %></textarea>
          </div>
        </div>
        <div class="action-row">
          <button type="submit" class="btn-submit"><%= isNew ? "➕ Thêm danh mục" : "💾 Lưu thay đổi" %></button>
          <a href="${pageContext.request.contextPath}/categories" class="btn-cancel">Hủy</a>
        </div>
      </form>
    </div>
  </div>
</div>
</body>
</html>
