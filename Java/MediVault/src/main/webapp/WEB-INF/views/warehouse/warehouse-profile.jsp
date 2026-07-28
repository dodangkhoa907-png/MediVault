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
    String activeNav = "profile";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Hồ sơ cá nhân — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400..800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= ctx %>/css/staff-portal.css">
<link rel="stylesheet" href="<%= ctx %>/css/warehouse-portal.css?v=5">
<style>
a{text-decoration:none;color:inherit}
.wrap{max-width:800px;margin:0 auto;padding:28px 28px 60px}
.head{margin-bottom:22px}
.head h1{font-size:24px;font-weight:800;letter-spacing:-.5px}
.head p{color:var(--muted);font-size:14px;margin-top:4px}
.card{background:#fff;border:1px solid #E4E9E7;border-radius:16px;padding:24px;box-shadow:0 1px 2px rgba(4,47,46,.04),0 12px 30px -18px rgba(4,47,46,.12)}
.profile-photo{width:120px;height:120px;border-radius:50%;object-fit:cover;border:3px solid #E4E9E7;margin-bottom:16px}
.profile-placeholder{width:120px;height:120px;border-radius:50%;background:var(--soft);color:var(--main);display:flex;align-items:center;justify-content:center;font-size:48px;font-weight:800;margin-bottom:16px;border:3px solid #E4E9E7}
.form-group{margin-bottom:16px}
.form-group label{display:block;font-size:13.5px;font-weight:700;margin-bottom:6px;color:var(--ink)}
.form-group input{width:100%;padding:10px 14px;border:1.5px solid var(--border);border-radius:10px;font-family:inherit;font-size:14px;background:var(--surface);color:var(--ink)}
.btn-submit{padding:12px 24px;border:none;border-radius:10px;background:linear-gradient(135deg,var(--main),var(--deep));color:#fff;font-weight:700;font-size:14px;cursor:pointer;margin-top:10px}
.alert{padding:12px;border-radius:8px;margin-bottom:16px;font-size:13.5px;font-weight:600}
.alert-success{background:var(--okbg);color:var(--ok);border:1px solid var(--ok)}
.alert-error{background:var(--dangerbg);color:var(--danger);border:1px solid var(--danger)}
.avatar-section{text-align:center;padding-bottom:24px;border-bottom:1px solid var(--line);margin-bottom:24px}
</style>
</head>
<body>
<%@ include file="warehouse-sidebar.jsp" %>
<main class="main-content">
  <div class="top-nav">
    <div class="nav-left"></div>
    <div class="nav-right">
      <div class="user-profile">
        <div class="avatar"><%= initials %></div>
        <div class="user-info">
          <div class="user-name"><%= fullName %></div>
          <div class="user-role">Quản lý kho</div>
        </div>
      </div>
    </div>
  </div>
  <div class="wrap">
    <div class="head">
      <h1>Hồ sơ cá nhân</h1>
      <p>Cập nhật ảnh đại diện của bạn</p>
    </div>
    <div class="card">
      <% if ("success".equals(request.getParameter("msg"))) { %>
        <div class="alert alert-success">Cập nhật ảnh đại diện thành công!</div>
      <% } else if ("error".equals(request.getParameter("msg"))) { %>
        <div class="alert alert-error">Đã xảy ra lỗi, vui lòng thử lại!</div>
      <% } %>
      
      <div class="avatar-section">
          <c:choose>
              <c:when test="${not empty staffAcc.faceEnrollmentPath}">
                  <img src="<%= ctx %>/${staffAcc.faceEnrollmentPath}" alt="Avatar" class="profile-photo">
              </c:when>
              <c:otherwise>
                  <div class="profile-placeholder"><%= initials %></div>
              </c:otherwise>
          </c:choose>
          
          <form action="<%= ctx %>/warehouse-profile?uid=<%= uid %>" method="POST" enctype="multipart/form-data">
              <div class="form-group" style="text-align:left; max-width: 300px; margin: 0 auto;">
                  <label>Tải lên ảnh mới</label>
                  <input type="file" name="avatar" accept="image/png, image/jpeg" required>
              </div>
              <button type="submit" class="btn-submit">Lưu ảnh đại diện</button>
          </form>
      </div>

      <div style="opacity:0.7; pointer-events:none">
          <h3 style="margin-bottom:16px">Thông tin cơ bản</h3>
          <div class="form-group">
              <label>Họ và tên</label>
              <input type="text" value="<%= acc.getFullName() %>" readonly>
          </div>
          <div class="form-group">
              <label>Tài khoản</label>
              <input type="text" value="<%= acc.getUsername() %>" readonly>
          </div>
          <div class="form-group">
              <label>Email</label>
              <input type="text" value="<%= acc.getEmail() != null ? acc.getEmail() : "" %>" readonly>
          </div>
      </div>
    </div>
  </div>
</main>
</body>
</html>
