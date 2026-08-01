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
    String activeNav = "import";
    String currentTab = (String) request.getAttribute("currentTab");
    if (currentTab == null || currentTab.isEmpty()) currentTab = "import";
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
.wrap{max-width:1000px;margin:0 auto;padding:24px 28px 60px}
.head{margin-bottom:20px}
.head h1{font-size:24px;font-weight:800;letter-spacing:-.5px}
.head p{color:var(--muted);font-size:14px;margin-top:4px}

.sub-tabs-bar{display:flex;align-items:center;gap:8px;padding:6px;background:#EAF1EF;border-radius:14px;margin-bottom:24px;border:1px solid #D8E5E1;overflow-x:auto}
.tab-link{display:inline-flex;align-items:center;gap:8px;padding:10px 18px;border-radius:10px;font-size:13.5px;font-weight:750;color:var(--muted);transition:.18s;white-space:nowrap;cursor:pointer}
.tab-link:hover{color:var(--ink);background:rgba(255,255,255,.6)}
.tab-link.active{background:#fff;color:var(--main);box-shadow:0 2px 8px rgba(4,47,46,.08);font-weight:800}

.card{background:#fff;border:1px solid #E4E9E7;border-radius:16px;padding:24px;box-shadow:0 1px 2px rgba(4,47,46,.04),0 12px 30px -18px rgba(4,47,46,.12);margin-bottom:22px}
.card-head{display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;padding-bottom:16px;margin-bottom:18px;border-bottom:1px solid var(--line)}
.card-head h2{font-size:15px;font-weight:800}

.form-group{margin-bottom:16px}
.form-group label{display:block;font-size:13.5px;font-weight:700;margin-bottom:6px;color:var(--ink)}
.form-group input, .form-group select{width:100%;padding:10px 14px;border:1.5px solid var(--border);border-radius:10px;font-family:inherit;font-size:14px;background:var(--surface);color:var(--ink)}
.form-group input:focus, .form-group select:focus{outline:none;border-color:var(--main);background:#fff;box-shadow:0 0 0 3px rgba(15,118,110,.12)}
.form-row{display:flex;gap:16px}
.form-row .form-group{flex:1}
.btn-submit{padding:12px 24px;border:none;border-radius:10px;background:linear-gradient(135deg,var(--main),var(--deep));color:#fff;font-weight:700;font-size:14px;cursor:pointer;width:100%;margin-top:10px}
.alert{padding:12px;border-radius:8px;margin-bottom:16px;font-size:13.5px;font-weight:600}
.alert-error{background:var(--dangerbg);color:var(--danger);border:1px solid var(--danger)}

.tblwrap{overflow-x:auto}
table{border-collapse:collapse;width:100%;font-size:13.5px}
th,td{padding:12px 16px;text-align:left;border-bottom:1px solid var(--line)}
thead th{font-size:11px;letter-spacing:.06em;text-transform:uppercase;color:var(--muted);font-weight:700;background:var(--surface)}
tbody tr:hover{background:#F8FAFC}
.mname{font-weight:700;color:#0F172A}
.num-cell{text-align:right;font-variant-numeric:tabular-nums;font-weight:700}
.empty{padding:36px;text-align:center;color:var(--muted);font-size:14px}
</style>
<meta name="csrf-token" content="${csrfToken}">
<script src="${pageContext.request.contextPath}/js/csrf.js"></script>
</head>
<body class="wh">
<%@ include file="warehouse-sidebar.jsp" %>
<div class="main">
  <header class="wh-topbar">
    <div class="crumb">Nhập kho</div>
    <div class="right">
      <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc"><%= initials %></a>
    </div>
  </header>

  <div class="wrap">
    <div class="sub-tabs-bar">
      <a href="<%= ctx %>/warehouse-import?uid=<%= uid %>&tab=import" class="tab-link <%= "import".equals(currentTab) ? "active" : "" %>">
        <span>📥</span> Nhập kho hàng
      </a>
      <a href="<%= ctx %>/warehouse-import?uid=<%= uid %>&tab=reorder" class="tab-link <%= "reorder".equals(currentTab) ? "active" : "" %>">
        <span>📈</span> Gợi ý đặt hàng
      </a>
    </div>

    <c:if test="${currentTab == 'import'}">
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
    </c:if>

    <c:if test="${currentTab == 'reorder'}">
      <div class="head">
        <h1>Gợi ý đặt hàng</h1>
        <p>Danh sách đề xuất đặt hàng ROP cho thủ kho tham khảo khi nhập hàng</p>
      </div>
      <div class="card">
        <div class="card-head">
          <h2>Đề xuất đặt hàng đang chờ <small>(${pendingSuggestions.size()} phiếu)</small></h2>
        </div>
        <div class="tblwrap">
          <table>
            <thead><tr>
              <th>Thuốc</th><th>Nhà cung cấp</th>
              <th style="text-align:right">SL đề xuất</th>
              <th style="text-align:right">Tổng tiền ước tính</th>
              <th>Ngày đề xuất</th><th>Thao tác</th>
            </tr></thead>
            <tbody>
            <c:choose>
              <c:when test="${empty pendingSuggestions}">
                <tr><td colspan="6" class="empty">Không có phiếu đề xuất nào đang chờ. 👍</td></tr>
              </c:when>
              <c:otherwise>
                <c:forEach var="row" items="${pendingSuggestions}">
                  <tr>
                    <td class="mname">${row.medicineName}</td>
                    <td>${row.supplierName}</td>
                    <td class="num-cell">${row.quantity}</td>
                    <td class="num-cell"><fmt:formatNumber value="${row.totalValue}" type="number" maxFractionDigits="0"/>đ</td>
                    <td><fmt:formatDate value="${row.orderDate}" pattern="dd/MM/yyyy HH:mm"/></td>
                    <td><a href="<%= ctx %>/purchase-orders?action=detail&id=${row.poId}" style="color:var(--main);font-weight:700">Xem chi tiết PO →</a></td>
                  </tr>
                </c:forEach>
              </c:otherwise>
            </c:choose>
            </tbody>
          </table>
        </div>
      </div>
    </c:if>
  </div>
</div>
</body>
</html>
