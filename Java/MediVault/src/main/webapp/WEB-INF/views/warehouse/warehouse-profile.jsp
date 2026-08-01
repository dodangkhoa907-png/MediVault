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
<title>Hồ sơ cá nhân — MediCare Console</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400..800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= ctx %>/css/staff-portal.css">
<link rel="stylesheet" href="<%= ctx %>/css/warehouse-portal.css?v=5">
<style>
a{text-decoration:none;color:inherit}
.wrap{max-width:1100px;margin:0 auto;padding:24px 28px 60px}

/* Banner profile cao cấp */
.profile-banner{background:linear-gradient(135deg,#0F766E 0%,#115E59 50%,#042F2E 100%);color:#fff;border-radius:20px;padding:28px 32px;margin-bottom:24px;box-shadow:0 12px 32px -12px rgba(15,118,110,.4);display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:20px;position:relative;overflow:hidden}
.profile-banner::after{content:'👤';position:absolute;right:-10px;bottom:-20px;font-size:140px;opacity:.08;pointer-events:none}
.pb-info h1{font-size:26px;font-weight:800;letter-spacing:-.5px;margin:0 0 6px}
.pb-info p{font-size:14px;color:rgba(255,255,255,.8);margin:0}
.pb-badges{display:flex;align-items:center;gap:10px;margin-top:12px}
.pb-badge{display:inline-flex;align-items:center;gap:6px;padding:4px 12px;border-radius:20px;font-size:12px;font-weight:750;background:rgba(255,255,255,.16);border:1px solid rgba(255,255,255,.25)}

/* Layout 2 cột */
.prof-grid{display:grid;grid-template-columns:320px 1fr;gap:24px;align-items:start}
@media(max-width:900px){.prof-grid{grid-template-columns:1fr}}

.card{background:#fff;border:1px solid #E4E9E7;border-radius:18px;overflow:hidden;box-shadow:0 1px 2px rgba(4,47,46,.04),0 12px 30px -18px rgba(4,47,46,.12);margin-bottom:24px}
.card-head{padding:18px 24px;border-bottom:1px solid #EAEFED;display:flex;align-items:center;gap:10px;background:#FAFCFC}
.card-head h2{font-size:15.5px;font-weight:800;color:var(--ink);margin:0}
.card-body{padding:24px}

/* Avatar Card */
.avatar-box{display:flex;flex-direction:column;align-items:center;text-align:center}
.profile-photo{width:130px;height:130px;border-radius:50%;object-fit:cover;border:4px solid #99F6E4;box-shadow:0 8px 24px -6px rgba(15,118,110,.3);margin-bottom:16px}
.profile-placeholder{width:130px;height:130px;border-radius:50%;background:linear-gradient(135deg,#CCFBF1,#99F6E4);color:#0F766E;display:flex;align-items:center;justify-content:center;font-size:52px;font-weight:800;margin-bottom:16px;border:4px solid #99F6E4;box-shadow:0 8px 24px -6px rgba(15,118,110,.3)}

.upload-area{width:100%;margin-top:12px}
.file-drop{border:2px dashed #CBD5E1;border-radius:12px;padding:16px;background:var(--surface);text-align:center;transition:.2s;cursor:pointer;position:relative}
.file-drop:hover{border-color:var(--main);background:#F0FDFA}
.file-drop input[type=file]{position:absolute;inset:0;opacity:0;cursor:pointer;width:100%;height:100%}
.fd-ic{font-size:24px;color:var(--main);margin-bottom:4px}
.fd-lbl{font-size:12.5px;font-weight:700;color:var(--ink)}
.fd-sub{font-size:11px;color:var(--muted);margin-top:2px}

.btn-upload{width:100%;padding:12px 20px;border:none;border-radius:12px;background:linear-gradient(135deg,var(--main),var(--deep));color:#fff;font-weight:800;font-size:14px;cursor:pointer;margin-top:14px;box-shadow:0 6px 18px -4px rgba(15,118,110,.4);transition:.15s}
.btn-upload:hover{filter:brightness(1.08);transform:translateY(-1px)}

/* Info Form Groups */
.info-section-title{font-size:12px;font-weight:800;color:var(--main);text-transform:uppercase;letter-spacing:.6px;margin:0 0 16px;display:flex;align-items:center;gap:8px}
.form-grid{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin-bottom:20px}
@media(max-width:600px){.form-grid{grid-template-columns:1fr}}

.fg{display:flex;flex-direction:column;gap:6px}
.fg.full{grid-column:1/-1}
.fg label{font-size:11.5px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.4px}
.fg-field{position:relative;display:flex;align-items:center}
.fg-ic{position:absolute;left:14px;font-size:15px;color:var(--main)}
.fg-field input{width:100%;padding:11px 14px 11px 40px;border:1.5px solid #E2E8F0;border-radius:11px;font-family:inherit;font-size:14px;font-weight:650;color:#0F172A;background:#F8FAFC}
.fg-field input:focus{outline:none;border-color:var(--main);background:#fff;box-shadow:0 0 0 3px rgba(15,118,110,.12)}

.alert{padding:13px 18px;border-radius:12px;margin-bottom:20px;font-size:13.5px;font-weight:700;display:flex;align-items:center;gap:10px}
.alert-success{background:#ECFDF5;color:#047857;border:1px solid #6EE7B7}
.alert-error{background:#FEF2F2;color:#B91C1C;border:1px solid #FCA5A5}
</style>
<meta name="csrf-token" content="${csrfToken}">
<script src="${pageContext.request.contextPath}/js/csrf.js"></script>
</head>
<body class="wh">
<%@ include file="warehouse-sidebar.jsp" %>
<div class="main">
  <header class="wh-topbar">
    <div class="crumb">Hồ sơ cá nhân</div>
    <div class="right">
      <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc"><%= initials %></a>
    </div>
  </header>

  <div class="wrap">
    <!-- Banner cá nhân -->
    <div class="profile-banner">
      <div class="pb-info">
        <h1>Chào mừng, <%= fullName %>!</h1>
        <p>Tài khoản Quản lý kho &amp; Kiểm soát vận hành kho MediCare Console</p>
        <div class="pb-badges">
          <span class="pb-badge">🏷️ Vai trò: Thủ kho</span>
          <span class="pb-badge">🟢 Trạng thái: Đang hoạt động</span>
          <span class="pb-badge">🔒 Bảo mật: Đã xác thực</span>
        </div>
      </div>
    </div>

    <% if ("success".equals(request.getParameter("msg"))) { %>
      <div class="alert alert-success">✅ Cập nhật ảnh đại diện thành công!</div>
    <% } else if ("error".equals(request.getParameter("msg"))) { %>
      <div class="alert alert-error">⚠️ Đã xảy ra lỗi khi tải ảnh lên. Vui lòng thử lại!</div>
    <% } %>

    <div class="prof-grid">
      <!-- Cột trái: Ảnh đại diện & Cập nhật -->
      <div class="card">
        <div class="card-head">
          <h2>🖼️ Ảnh đại diện</h2>
        </div>
        <div class="card-body">
          <div class="avatar-box">
            <c:choose>
                <c:when test="${not empty staffAcc.faceEnrollmentPath}">
                    <img src="<%= ctx %>/${staffAcc.faceEnrollmentPath}" alt="Avatar" class="profile-photo">
                </c:when>
                <c:otherwise>
                    <div class="profile-placeholder"><%= initials %></div>
                </c:otherwise>
            </c:choose>
            <div style="font-weight:800;font-size:16px;color:var(--ink);margin-bottom:2px"><%= fullName %></div>
            <div style="font-size:12.5px;color:var(--muted);font-weight:600">Mã nhân sự: #<%= uid %></div>
          </div>

          <form action="<%= ctx %>/warehouse-profile?uid=<%= uid %>" method="POST" enctype="multipart/form-data" class="upload-area">
            <div class="file-drop" id="fileDrop">
              <div class="fd-ic">📷</div>
              <div class="fd-lbl" id="fdText">Kéo thả hoặc Chọn ảnh mới</div>
              <div class="fd-sub">Hỗ trợ định dạng PNG, JPG, JPEG</div>
              <input type="file" name="avatar" id="avatarInput" accept="image/png, image/jpeg" required onchange="updateFileName(this)">
            </div>
            <button type="submit" class="btn-upload">💾 Lưu ảnh đại diện</button>
          </form>
        </div>
      </div>

      <!-- Cột phải: Thông tin chi tiết & Phân quyền -->
      <div class="card">
        <div class="card-head">
          <h2>📋 Thông tin tài khoản &amp; Phân quyền</h2>
        </div>
        <div class="card-body">
          <div class="info-section-title">👤 Thông tin cơ bản</div>
          <div class="form-grid">
            <div class="fg">
              <label>Họ và tên</label>
              <div class="fg-field">
                <span class="fg-ic">👤</span>
                <input type="text" value="<%= fullName %>" readonly>
              </div>
            </div>
            <div class="fg">
              <label>Tài khoản đăng nhập</label>
              <div class="fg-field">
                <span class="fg-ic">🆔</span>
                <input type="text" value="<%= acc.getUsername() %>" readonly>
              </div>
            </div>
            <div class="fg full">
              <label>Email liên hệ</label>
              <div class="fg-field">
                <span class="fg-ic">✉️</span>
                <input type="text" value="<%= acc.getEmail() != null ? acc.getEmail() : "Chưa cập nhật email" %>" readonly>
              </div>
            </div>
          </div>

          <div class="info-section-title" style="padding-top:16px;border-top:1px solid #EAEFED;margin-top:20px">🛡️ Phân quyền kho &amp; Phạm vi vận hành</div>
          <div class="form-grid">
            <div class="fg">
              <label>Chức vụ công tác</label>
              <div class="fg-field">
                <span class="fg-ic">📦</span>
                <input type="text" value="Thủ kho / Quản lý kho" readonly>
              </div>
            </div>
            <div class="fg">
              <label>Quyền hệ thống</label>
              <div class="fg-field">
                <span class="fg-ic">🔑</span>
                <input type="text" value="Role #3 (Warehouse Console)" readonly>
              </div>
            </div>
            <div class="fg full">
              <label>Chức năng được phép thao tác</label>
              <div class="fg-field">
                <span class="fg-ic">✅</span>
                <input type="text" value="Quản lý tồn kho, Nhập kho, Xuất kho & Điều chỉnh (FEFO), Thu hồi khẩn cấp, Nhiệm vụ & SOP" readonly>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>

<script>
function updateFileName(input) {
  if (input.files && input.files[0]) {
    document.getElementById('fdText').textContent = '📄 ' + input.files[0].name;
  }
}
</script>
</body>
</html>
