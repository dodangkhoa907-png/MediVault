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
    String activeNav = "inventory";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Nhập kho — MediCare</title>
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
.form-group{margin-bottom:16px}
.form-group label{display:block;font-size:13.5px;font-weight:700;margin-bottom:6px;color:var(--ink)}
.form-group input, .form-group select{width:100%;padding:10px 14px;border:1.5px solid var(--border);border-radius:10px;font-family:inherit;font-size:14px;background:var(--surface);color:var(--ink)}
.form-group input:focus, .form-group select:focus{outline:none;border-color:var(--main);background:#fff;box-shadow:0 0 0 3px rgba(15,118,110,.12)}
.form-row{display:flex;gap:16px}
.form-row .form-group{flex:1}
.btn-submit{padding:12px 24px;border:none;border-radius:10px;background:linear-gradient(135deg,var(--main),var(--deep));color:#fff;font-weight:700;font-size:14px;cursor:pointer;width:100%;margin-top:10px}
.alert{padding:12px;border-radius:8px;margin-bottom:16px;font-size:13.5px;font-weight:600}
.alert-success{background:var(--okbg);color:var(--ok);border:1px solid var(--ok)}
.alert-error{background:var(--dangerbg);color:var(--danger);border:1px solid var(--danger)}
</style>
<meta name="csrf-token" content="${csrfToken}">
<script src="${pageContext.request.contextPath}/js/csrf.js"></script>
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
      <h1>Nhập hàng vào kho</h1>
      <p>Thêm lô hàng mới vào hệ thống</p>
    </div>
    <div class="card">
      <% if ("import-error".equals(request.getParameter("msg"))) { %>
        <div class="alert alert-error">Đã xảy ra lỗi khi nhập kho. Vui lòng thử lại.</div>
      <% } %>
      <form action="<%= ctx %>/warehouse-import?uid=<%= uid %>" method="POST">
        <div class="form-row">
            <div class="form-group">
              <label>Thuốc *</label>
              <select name="medicineId" required>
                <option value="">Chọn thuốc</option>
                <c:forEach var="m" items="${medicines}">
                  <option value="${m.medicineId}">${m.medicineName} (${m.unit})</option>
                </c:forEach>
              </select>
            </div>
            <div class="form-group">
              <label>Nhà cung cấp *</label>
              <select name="supplierId" required>
                <option value="">Chọn nhà cung cấp</option>
                <c:forEach var="s" items="${suppliers}">
                  <option value="${s.supplierId}">${s.supplierName}</option>
                </c:forEach>
              </select>
            </div>
        </div>
        <div class="form-group">
          <label>Đơn đặt hàng (Purchase Order) (Tùy chọn)</label>
          <select name="poId">
            <option value="">-- Không có --</option>
            <c:forEach var="po" items="${pos}">
              <option value="${po.poId}">PO #${po.poId} - ${po.orderDate}</option>
            </c:forEach>
          </select>
        </div>
        <div class="form-row">
            <div class="form-group">
              <label>Số Lô (Batch Number) *</label>
              <input type="text" name="batchNumber" required>
            </div>
            <div class="form-group">
              <label>Số lượng *</label>
              <input type="number" name="quantity" min="1" required>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
              <label>Giá nhập (VND) *</label>
              <input type="number" name="importPrice" step="1000" min="0" required>
            </div>
            <div class="form-group">
              <label>Ngày nhập hàng *</label>
              <input type="date" name="importDate" required>
            </div>
        </div>
        <div class="form-row">
            <div class="form-group">
              <label>Ngày sản xuất *</label>
              <input type="date" name="manufactureDate" required>
            </div>
            <div class="form-group">
              <label>Hạn sử dụng *</label>
              <input type="date" name="expiryDate" required>
            </div>
        </div>
        <button type="submit" class="btn-submit">Nhập Kho</button>
      </form>
    </div>
  </div>
</main>
</body>
</html>
