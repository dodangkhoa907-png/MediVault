<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
    
    
    
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>500 � L?i h? th?ng</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Plus Jakarta Sans',sans-serif;background:#F1F5FB;display:flex;align-items:center;justify-content:center;min-height:100vh;color:#0B1628}
.card{background:#fff;border-radius:16px;padding:48px 40px;text-align:center;box-shadow:0 4px 24px rgba(0,0,0,.08);max-width:420px;width:90%}
.code{font-size:80px;font-weight:800;color:#DC2626;line-height:1;margin-bottom:8px}
h1{font-size:22px;font-weight:800;margin-bottom:8px}
p{color:#64748B;font-size:14px;margin-bottom:28px}
a{display:inline-block;padding:12px 28px;background:#1558A8;color:#fff;border-radius:9px;text-decoration:none;font-weight:750;font-size:14px;transition:.15s}
a:hover{background:#0F3D80}
</style>
    
</head>
<body>
<div class="card">
  <div class="code">500</div>
  <h1>L?i h? th?ng</h1>
  <p>Đã xảy ra lỗi trong quá trình xử lý yêu cầu, vui lòng thử lại</p>
  <% if (exception != null && Boolean.parseBoolean(application.getInitParameter("devMode"))) { %>
  <pre style="text-align:left;background:#fee2e2;padding:12px;border-radius:8px;font-size:11px;overflow:auto;margin-bottom:20px;color:#991b1b"><%= exception.getMessage() %></pre>
  <% } %>
  <a href="${pageContext.request.contextPath}/dashboard">Về Dashboard</a>
</div>
</body>
</html>
