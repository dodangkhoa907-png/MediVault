<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) request.getAttribute("staffAcc");
    String ctx = request.getContextPath();
    if (acc == null) { response.sendRedirect(ctx + "/warehouse-login"); return; }
    String fullName = acc.getFullName() != null && !acc.getFullName().isEmpty() ? acc.getFullName() : acc.getUsername();
    String initials = fullName.substring(0,1).toUpperCase();
    String uid = (String) request.getAttribute("staffUid");
    String activeNav = "reorder";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Gợi ý đặt hàng &amp; Cảnh báo hạn dùng — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400..800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="<%= ctx %>/css/staff-portal.css">
<link rel="stylesheet" href="<%= ctx %>/css/warehouse-portal.css?v=3">
<style>
a{text-decoration:none;color:inherit}

.wrap{max-width:1200px;margin:0 auto;padding:28px 28px 60px}
.head{display:flex;align-items:flex-end;justify-content:space-between;flex-wrap:wrap;gap:14px;margin-bottom:22px}
.head h1{font-size:24px;font-weight:800;letter-spacing:-.5px}
.head h1 span{color:var(--main)}
.head p{color:var(--muted);font-size:14px;margin-top:4px}

.card{background:#fff;border:1px solid #E7E8F1;border-radius:16px;overflow:hidden;margin-bottom:22px;box-shadow:0 1px 2px rgba(30,27,75,.04),0 12px 30px -18px rgba(30,27,75,.12)}
.card-head{display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;
  padding:16px 20px;border-bottom:1px solid var(--line)}
.card-head h2{font-size:15px;font-weight:800}
.card-head h2 small{color:var(--muted);font-weight:600;font-size:12.5px;margin-left:6px}
.card-head h2 .ic{margin-right:6px}
.reorder-head{background:linear-gradient(90deg,var(--soft),transparent)}
.light-head{background:linear-gradient(90deg,#DBEAFE,transparent)}
.restrict-head{background:linear-gradient(90deg,#FEF3C7,transparent)}
.quar-head{background:linear-gradient(90deg,var(--dangerbg),transparent)}

.tblwrap{overflow-x:auto}
table{border-collapse:collapse;width:100%;font-size:13.5px;min-width:640px}
th,td{padding:11px 16px;text-align:left;border-bottom:1px solid var(--line);white-space:nowrap}
thead th{font-size:11px;letter-spacing:.06em;text-transform:uppercase;color:var(--muted);font-weight:700;background:var(--surface)}
tbody tr:hover{background:var(--surface)}
.mname{font-weight:700;color:var(--ink)}
.num-cell{text-align:right;font-variant-numeric:tabular-nums;font-weight:700}
.empty{padding:36px;text-align:center;color:var(--muted);font-size:14px}
.detail-link{color:var(--main);font-weight:700}
.detail-link:hover{text-decoration:underline}

.badge{display:inline-block;padding:2px 9px;border-radius:20px;font-size:11.5px;font-weight:700}
.badge.info{background:#DBEAFE;color:#1D4ED8}
.badge.warn{background:var(--goldbg);color:var(--gold)}
.badge.danger{background:var(--dangerbg);color:var(--danger)}

.grid3{display:grid;grid-template-columns:1fr 1fr 1fr;gap:22px}
.exp-date{font-weight:700}

.back-row{margin-bottom:18px}
.back-row a{display:inline-flex;align-items:center;gap:6px;color:var(--main);font-weight:700;font-size:13.5px}

@media(max-width:1100px){.grid3{grid-template-columns:1fr}}
</style>
</head>
<body class="wh">
<%@ include file="warehouse-sidebar.jsp" %>
<div class="main">
  <header class="wh-topbar">
    <div class="crumb">Gợi ý đặt hàng &amp; Cảnh báo hạn dùng</div>
    <div class="right">
      <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc"><%= initials %></a>
    </div>
  </header>

  <div class="wrap">
    <div class="head">
      <div>
        <h1>Gợi ý <span>đặt hàng</span> &amp; Cảnh báo hạn dùng</h1>
        <p>Hệ thống tự tính điểm đặt hàng lại (ROP) và tự cách ly lô cận hạn mỗi giờ — Admin duyệt phiếu đề xuất bên dưới.</p>
      </div>
    </div>

    <div class="card">
      <div class="card-head reorder-head">
        <div class="wh-ic">📈</div>
        <h2>Gợi ý đặt hàng <small>(PO chờ duyệt — ${pendingSuggestions.size()} phiếu)</small></h2>
      </div>
      <div class="tblwrap">
        <table>
          <thead><tr>
            <th>Thuốc</th><th>Nhà cung cấp</th>
            <th style="text-align:right">SL đề xuất</th>
            <th style="text-align:right">Tổng tiền ước tính</th>
            <th>Ngày đề xuất</th><th>Chi tiết</th>
          </tr></thead>
          <tbody>
          <c:choose>
            <c:when test="${empty pendingSuggestions}">
              <tr><td colspan="6" class="empty">Không có phiếu đề xuất nào đang chờ — tồn kho hiện đủ so với ROP. 👍</td></tr>
            </c:when>
            <c:otherwise>
              <c:forEach var="row" items="${pendingSuggestions}">
                <tr>
                  <td class="mname">${row.medicineName}</td>
                  <td>${row.supplierName}</td>
                  <td class="num-cell">${row.quantity}</td>
                  <td class="num-cell"><fmt:formatNumber value="${row.totalValue}" type="number" maxFractionDigits="0"/>đ</td>
                  <td><fmt:formatDate value="${row.orderDate}" pattern="dd/MM/yyyy HH:mm"/></td>
                  <td><a class="detail-link" href="<%= ctx %>/purchase-orders?action=detail&id=${row.poId}">Xem chi tiết đơn →</a></td>
                </tr>
              </c:forEach>
            </c:otherwise>
          </c:choose>
          </tbody>
        </table>
      </div>
    </div>

    <div class="grid3">
      <div class="card">
        <div class="card-head light-head"><div class="wh-ic jade">🕐</div><h2>Cận hạn nhẹ <small>91–180 ngày</small></h2></div>
        <div class="tblwrap">
          <table style="min-width:auto">
            <thead><tr><th>Thuốc</th><th>Số lô</th><th style="text-align:right">Còn tồn</th><th>HSD</th></tr></thead>
            <tbody>
              <c:choose>
                <c:when test="${empty tierLight}"><tr><td colspan="4" class="empty">Không có lô nào.</td></tr></c:when>
                <c:otherwise>
                  <c:forEach var="b" items="${tierLight}">
                    <tr>
                      <td class="mname">${b.medicineName}</td>
                      <td>${b.batchNumber}</td>
                      <td class="num-cell">${b.currentQuantity}</td>
                      <td class="exp-date"><span class="badge info"><fmt:formatDate value="${b.expiryDate}" pattern="dd/MM/yyyy"/></span></td>
                    </tr>
                  </c:forEach>
                </c:otherwise>
              </c:choose>
            </tbody>
          </table>
        </div>
      </div>

      <div class="card">
        <div class="card-head restrict-head"><div class="wh-ic warn">⚠️</div><h2>Hạn chế xuất SL lớn <small>31–90 ngày</small></h2></div>
        <div class="tblwrap">
          <table style="min-width:auto">
            <thead><tr><th>Thuốc</th><th>Số lô</th><th style="text-align:right">Còn tồn</th><th>HSD</th></tr></thead>
            <tbody>
              <c:choose>
                <c:when test="${empty tierRestricted}"><tr><td colspan="4" class="empty">Không có lô nào.</td></tr></c:when>
                <c:otherwise>
                  <c:forEach var="b" items="${tierRestricted}">
                    <tr>
                      <td class="mname">${b.medicineName}</td>
                      <td>${b.batchNumber}</td>
                      <td class="num-cell">${b.currentQuantity}</td>
                      <td class="exp-date"><span class="badge warn"><fmt:formatDate value="${b.expiryDate}" pattern="dd/MM/yyyy"/></span></td>
                    </tr>
                  </c:forEach>
                </c:otherwise>
              </c:choose>
            </tbody>
          </table>
        </div>
      </div>

      <div class="card">
        <div class="card-head quar-head"><div class="wh-ic danger">⛔</div><h2>Đã cách ly <small>≤ 30 ngày</small></h2></div>
        <div class="tblwrap">
          <table style="min-width:auto">
            <thead><tr><th>Thuốc</th><th>Số lô</th><th style="text-align:right">Còn tồn</th><th>HSD</th></tr></thead>
            <tbody>
              <c:choose>
                <c:when test="${empty tierQuarantined}"><tr><td colspan="4" class="empty">Không có lô nào bị cách ly.</td></tr></c:when>
                <c:otherwise>
                  <c:forEach var="b" items="${tierQuarantined}">
                    <tr>
                      <td class="mname">${b.medicineName}</td>
                      <td>${b.batchNumber}</td>
                      <td class="num-cell">${b.currentQuantity}</td>
                      <td class="exp-date"><span class="badge danger"><fmt:formatDate value="${b.expiryDate}" pattern="dd/MM/yyyy"/></span></td>
                    </tr>
                  </c:forEach>
                </c:otherwise>
              </c:choose>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</div>
</body>
</html>
