<%@ page contentType="text/html;charset=UTF-8" %>
<html>
<head><title>MediVault - Đăng nhập</title></head>
<body>
    <h2>MEDIVAULT - ĐĂNG NHẬP</h2>
    <% if (request.getAttribute("error") != null) { %>
        <p style="color:red"><%= request.getAttribute("error") %></p>
    <% } %>
    <form method="post" action="${pageContext.request.contextPath}/login">
        <p>
            <label>Tài khoản:</label><br>
            <input type="text" name="username" required>
        </p>
        <p>
            <label>Mật khẩu:</label><br>
            <input type="password" name="password" required>
        </p>
        <button type="submit">Đăng nhập</button>
    </form>
</body>
</html>