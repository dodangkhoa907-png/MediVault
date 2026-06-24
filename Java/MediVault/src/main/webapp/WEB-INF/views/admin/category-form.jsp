<%@ page contentType="text/html;charset=UTF-8" %>
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
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title><%= isNew ? "Thêm danh mục" : "Sửa danh mục" %> — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--sidebar:232px;
}
html,body{height:100%;font-family:'Outfit',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-icon{width:36px;height:36px;background:linear-gradient(135deg,#3ABDE0,#1558A8);border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:18px}
.logo-text{font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-sub{font-size:10px;color:rgba(255,255,255,.45);font-weight:500;letter-spacing:.5px;text-transform:uppercase}
.nav-section{padding:10px 12px 4px;flex-shrink:0}
.nav-label{font-size:9.5px;font-weight:700;color:rgba(255,255,255,.3);letter-spacing:1px;text-transform:uppercase;padding:0 8px;margin-bottom:4px}
.nav-item{display:flex;align-items:center;gap:9px;padding:9px 10px;border-radius:10px;color:rgba(255,255,255,.6);text-decoration:none;font-size:13.5px;font-weight:500;transition:all .16s;margin-bottom:2px}
.nav-item:hover{background:rgba(255,255,255,.07);color:#fff}
.nav-item.active{background:rgba(58,189,224,.15);color:#fff;border:1px solid rgba(58,189,224,.2)}
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06);flex-shrink:0}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08)}
.user-av{width:34px;height:34px;border-radius:50%;background:linear-gradient(135deg,#3ABDE0,#1558A8);display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:800;color:#fff;flex-shrink:0}
.user-name{font-size:13px;font-weight:700;color:#fff}
.user-role{font-size:11px;color:rgba(255,255,255,.4)}
.logout-btn{margin-left:auto;width:30px;height:30px;border-radius:8px;display:flex;align-items:center;justify-content:center;color:rgba(255,255,255,.4);text-decoration:none;font-size:16px;transition:all .15s}
.logout-btn:hover{background:rgba(220,38,38,.2);color:#DC2626}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Outfit',sans-serif;font-size:16px;color:var(--ink)}
.btn-back{height:36px;padding:0 14px;background:var(--white);border:1.5px solid var(--border);border-radius:9px;font-size:13px;font-weight:600;color:var(--muted);text-decoration:none;display:inline-flex;align-items:center;gap:6px;margin-left:auto;transition:all .15s}
.btn-back:hover{border-color:var(--blue);color:var(--navy)}
.content{padding:32px 28px;flex:1;max-width:600px}
.page-title{font-size:24px;font-weight:800;color:var(--ink);margin-bottom:4px}
.page-sub{font-size:13px;color:var(--muted);margin-bottom:24px}
.err-block{background:#FEF2F2;border:1.5px solid #FECACA;border-left:3px solid var(--red);border-radius:12px;padding:14px 18px;margin-bottom:18px;font-size:13px;color:var(--red);font-weight:600}
.form-card{background:var(--white);border:1px solid var(--border);border-radius:16px;overflow:hidden;box-shadow:0 2px 8px rgba(21,88,168,.04)}
.form-body{padding:24px}
.field{display:flex;flex-direction:column;gap:6px;margin-bottom:18px}
.field:last-child{margin-bottom:0}
.field-label{font-size:12.5px;font-weight:700;color:var(--navy);display:flex;align-items:center;gap:4px}
.req{color:var(--red)}
.field-input{height:42px;padding:0 14px;background:#fff;border:1.5px solid var(--border);border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;color:var(--ink);outline:none;transition:border-color .18s}
.field-input:focus{border-color:var(--cyan);box-shadow:0 0 0 3px rgba(58,189,224,.12)}
textarea.field-input{height:90px;padding:10px 14px;resize:vertical}
.action-row{display:flex;align-items:center;gap:12px;padding:16px 24px;background:linear-gradient(90deg,#FAFBFD,var(--surface));border-top:1px solid var(--border)}
.btn-submit{height:40px;padding:0 22px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;border-radius:11px;font-family:'Outfit',sans-serif;font-size:14px;font-weight:700;cursor:pointer;transition:all .22s;box-shadow:0 4px 14px rgba(21,88,168,.28)}
.btn-submit:hover{transform:translateY(-1px)}
.btn-cancel{height:40px;padding:0 18px;background:var(--white);border:1.5px solid var(--border);border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;color:var(--muted);text-decoration:none;display:inline-flex;align-items:center;transition:all .18s}
.btn-cancel:hover{border-color:var(--blue);color:var(--navy)}
</style>
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
