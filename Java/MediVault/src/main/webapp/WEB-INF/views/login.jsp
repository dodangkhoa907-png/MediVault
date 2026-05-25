<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MediVault — Đăng nhập</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/style.css">
</head>
<body>

<div class="login-page">
    <div class="login-box">

        <!-- Logo -->
        <div class="login-logo">
            <div class="logo-big">💊</div>
            <h1>MediVault</h1>
            <p>Hệ thống quản lý nhà thuốc</p>
        </div>

        <!-- Thông báo lỗi -->
        <% if (request.getAttribute("error") != null) { %>
            <div class="alert alert-danger">
                ❌ <%= request.getAttribute("error") %>
            </div>
        <% } %>

        <!-- Form đăng nhập -->
        <form method="post" action="${pageContext.request.contextPath}/login">

            <div class="form-group">
                <label for="username">Tên đăng nhập</label>
                <input type="text" id="username" name="username"
                       class="form-control"
                       placeholder="Nhập tên đăng nhập..."
                       required autofocus>
            </div>

            <div class="form-group">
                <label for="password">Mật khẩu</label>
                <input type="password" id="password" name="password"
                       class="form-control"
                       placeholder="Nhập mật khẩu..."
                       required>
            </div>

            <button type="submit" class="btn btn-primary"
                    style="width:100%; justify-content:center; margin-top:8px;">
                Đăng nhập →
            </button>

        </form>

        <p style="text-align:center; margin-top:20px; font-size:.78rem; color:#94a3b8;">
            MediVault v1.0 · Pharmacy Management System
        </p>
    </div>
</div>

</body>
</html>
