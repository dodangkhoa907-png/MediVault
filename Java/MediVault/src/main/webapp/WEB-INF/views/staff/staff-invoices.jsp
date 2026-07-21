<%@ page contentType="text/html;charset=UTF-8" language="java"  pageEncoding="UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account staffAcc = (com.medicare.entity.Account) request.getAttribute("staffAcc");
    String uid = (String) request.getAttribute("uid");
    java.lang.String dn      = staffAcc.getFullName() != null ? staffAcc.getFullName() : staffAcc.getUsername();
    java.lang.String initials = dn.length() >= 2
        ? dn.substring(0,1).toUpperCase() + dn.substring(1,2).toUpperCase()
        : dn.toUpperCase();
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Hóa đơn của tôi — MediCare</title>

<link rel="stylesheet" href="${pageContext.request.contextPath}/css/staff-portal.css">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#12082A;--dp:#1C0F3F;--mid:#2D1B69;--main:#6D28D9;
  --light:#A78BFA;--soft:#F5F3FF;--white:#fff;
  --muted:#7C6FAA;--border:#E2DCF5;--surface:#FAFAFA;
  --green:#059669;--red:#DC2626;--gold:#D97706;--blue:#2563EB;
  --sidebar:228px;--radius:14px;
}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif;background:var(--soft);color:var(--ink)}
body{display:flex}
.topbar{height:60px;background:var(--white);border-bottom:1px solid var(--border);
  display:flex;align-items:center;padding:0 26px;gap:12px;position:sticky;top:0;z-index:50}
.topbar-title{font-size:16px;font-weight:750;color:var(--ink)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.back-btn{padding:7px 14px;border-radius:8px;background:var(--surface);border:1.5px solid var(--border);
  color:var(--muted);font-size:12.5px;font-weight:750;text-decoration:none;transition:all .18s}
.back-btn:hover{background:var(--border)}
.content{padding:24px 28px;flex:1}
.page-head{margin-bottom:22px;display:flex;align-items:flex-end;justify-content:space-between;gap:14px;flex-wrap:wrap}
.breadcrumb{font-size:12px;color:var(--muted);margin-bottom:4px}
.page-head h1{font-size:24px;font-weight:800;color:var(--ink)}

.date-form{display:flex;align-items:center;gap:8px;background:var(--white);border:1.5px solid var(--border);
  border-radius:12px;padding:8px 12px}
.date-form label{font-size:12px;font-weight:750;color:var(--muted)}
.date-form input[type=date]{border:1.5px solid var(--border);border-radius:8px;padding:7px 10px;
  font-family:inherit;font-size:13px;color:var(--ink);outline:none}
.date-form input[type=date]:focus{border-color:var(--main)}
.date-form button{background:var(--main);color:#fff;border:none;border-radius:8px;padding:8px 14px;
  font-size:12.5px;font-weight:750;cursor:pointer;font-family:inherit}
.date-form button:hover{opacity:.9}
.date-form .today-btn{background:var(--surface);color:var(--muted);border:1.5px solid var(--border)}

.summary-row{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:14px;margin-bottom:20px}
.summary-card{background:var(--white);border:1.5px solid var(--border);border-radius:var(--radius);padding:16px 18px}
.summary-lbl{font-size:11px;font-weight:750;color:var(--muted);text-transform:uppercase;letter-spacing:.6px;margin-bottom:6px}
.summary-val{font-size:20px;font-weight:800;color:var(--ink)}
.summary-val.money{color:var(--main)}

.card{background:var(--white);border:1.5px solid var(--border);border-radius:var(--radius);overflow:hidden}
table{width:100%;border-collapse:collapse}
th{font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.4px;color:var(--muted);
  text-align:left;padding:12px 16px;background:var(--surface);border-bottom:1.5px solid var(--border);white-space:nowrap}
td{padding:12px 16px;font-size:13px;color:var(--ink);border-bottom:1px solid var(--border)}
tr:last-child td{border-bottom:none}
.num{text-align:right;font-variant-numeric:tabular-nums}
.badge{display:inline-flex;align-items:center;padding:3px 10px;border-radius:20px;font-size:11px;font-weight:750}
.badge-completed{background:#D1FAE5;color:#065F46}
.badge-pending{background:#FEF3C7;color:#92400E}
.badge-cancelled{background:#FEE2E2;color:#991B1B}
.pay-method{font-size:12px;color:var(--muted)}
.empty-state{padding:60px 20px;text-align:center;color:var(--muted)}
.empty-state .ei{font-size:38px;margin-bottom:10px}
.pagination{display:flex;justify-content:center;align-items:center;gap:8px;padding:16px}
.pagination a,.pagination span{padding:7px 13px;border-radius:8px;font-size:12.5px;font-weight:750;
  text-decoration:none;color:var(--ink);border:1.5px solid var(--border)}
.pagination a:hover{background:var(--surface)}
.pagination .active{background:var(--main);color:#fff;border-color:var(--main)}
</style>
</head>
<body>

<!-- SIDEBAR -->
<aside class="sidebar">
  <div class="sidebar-logo">
    <div style="width:60px;height:60px;border-radius:14px;overflow:hidden;flex-shrink:0;background:#fff;padding:4px;box-sizing:border-box">
      <img src="${pageContext.request.contextPath}/assets/logo.png" alt="MediCare"
           style="width:100%;height:100%;object-fit:cover;object-position:center 15%;display:block;border-radius:8px">
    </div>
    <div>
      <div class="logo-name">Medi<span>Care</span></div>
      <div class="logo-sub">Staff Portal</div>
    </div>
  </div>
  <nav class="nav-block">
    <div class="nav-label">Tổng quan</div>
    <a href="${pageContext.request.contextPath}/staff-dashboard?uid=<%= uid %>" class="nav-item">
      <span class="nav-icon">🏠</span> Trang chủ
    </a>
  </nav>
  <nav class="nav-block">
    <div class="nav-label">Cá nhân</div>
    <a href="${pageContext.request.contextPath}/staff-profile?uid=<%= uid %>" class="nav-item">
      <span class="nav-icon">👤</span> Hồ sơ của tôi
    </a>
    <a href="${pageContext.request.contextPath}/staff-checkin?uid=<%= uid %>" class="nav-item">
      <span class="nav-icon">✅</span> Điểm danh
    </a>
    <a href="${pageContext.request.contextPath}/staff-my-shifts?uid=<%= uid %>" class="nav-item">
      <span class="nav-icon">🕐</span> Ca làm việc
    </a>
    <a href="${pageContext.request.contextPath}/leave-requests?action=my&uid=<%= uid %>" class="nav-item">
      <span class="nav-icon">🏖️</span> Xin nghỉ phép
    </a>
  </nav>
  <nav class="nav-block">
    <div class="nav-label">Bán hàng</div>
    <a href="${pageContext.request.contextPath}/pos?uid=<%= uid %>" class="nav-item">
      <span class="nav-icon">🛒</span> Bán thuốc (POS)
    </a>
    <a href="${pageContext.request.contextPath}/staff-my-invoices?uid=<%= uid %>" class="nav-item active">
      <span class="nav-icon">🧾</span> Hóa đơn của tôi
    </a>
  </nav>
  <div class="sidebar-footer">
    <a href="${pageContext.request.contextPath}/logout?from=staff&uid=<%= uid %>" class="logout-btn-full" title="Đăng xuất">
      <span style="font-size:15px;line-height:1">⏻</span>
      <span>Đăng xuất</span>
    </a>
  </div>
</aside>

<!-- MAIN -->
<div class="main">
  <header class="topbar">
    <span class="topbar-title">🧾 Hóa đơn của tôi</span>
    <div class="topbar-right">
      <a href="${pageContext.request.contextPath}/staff-dashboard?uid=<%= uid %>" class="back-btn">← Dashboard</a>
    </div>
  </header>

  <div class="content">
    <div class="page-head">
      <div>
        <div class="breadcrumb">MediCare › Hóa đơn của tôi</div>
        <h1>Hóa đơn tôi đã bán</h1>
      </div>
      <form class="date-form" method="get" action="${pageContext.request.contextPath}/staff-my-invoices">
        <input type="hidden" name="uid" value="<%= uid %>"/>
        <label>Ngày:</label>
        <input type="date" name="date" value="${filterDate}" onchange="this.form.submit()"/>
        <button type="submit">Xem</button>
        <c:if test="${filterDate ne todayStr}">
          <a class="today-btn" style="text-decoration:none;display:inline-flex;align-items:center;padding:8px 14px;border-radius:8px;font-size:12.5px;font-weight:750"
             href="${pageContext.request.contextPath}/staff-my-invoices?uid=<%= uid %>">Hôm nay</a>
        </c:if>
      </form>
    </div>

    <div class="summary-row">
      <div class="summary-card">
        <div class="summary-lbl">Số hóa đơn</div>
        <div class="summary-val">${totalCount}</div>
      </div>
      <div class="summary-card">
        <div class="summary-lbl">Ngày xem</div>
        <div class="summary-val" style="font-size:15px">
          <fmt:parseDate value="${filterDate}" pattern="yyyy-MM-dd" var="parsedDate"/>
          <fmt:formatDate value="${parsedDate}" pattern="dd/MM/yyyy"/>
        </div>
      </div>
    </div>

    <div class="card">
      <c:choose>
        <c:when test="${empty invoices}">
          <div class="empty-state">
            <div class="ei">🧾</div>
            <p>Chưa có hóa đơn nào bạn bán trong ngày này.</p>
          </div>
        </c:when>
        <c:otherwise>
          <table>
            <thead><tr>
              <th>Mã HĐ</th>
              <th>Thời gian</th>
              <th>Khách hàng</th>
              <th>Phương thức</th>
              <th>Trạng thái</th>
              <th class="num">Thành tiền</th>
            </tr></thead>
            <tbody>
              <c:forEach var="inv" items="${invoices}">
                <tr>
                  <c:set var="cAt" value="${inv.createdAt.toString()}"/>
                  <td><b>${inv.invoiceCode}</b></td>
                  <td>${fn:substring(cAt,11,16)} · ${fn:substring(cAt,8,10)}/${fn:substring(cAt,5,7)}/${fn:substring(cAt,0,4)}</td>
                  <td>
                    <c:choose>
                      <c:when test="${inv.customerId != null && customerMap[inv.customerId] != null}">
                        ${customerMap[inv.customerId].customerName}
                      </c:when>
                      <c:otherwise><span style="color:var(--muted)">Khách lẻ</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td class="pay-method">
                    <c:choose>
                      <c:when test="${inv.paymentMethod == 'CASH'}">💵 Tiền mặt</c:when>
                      <c:when test="${inv.paymentMethod == 'QR_CODE'}">📱 QR VietQR</c:when>
                      <c:when test="${inv.paymentMethod == 'CARD'}">💳 Quẹt thẻ</c:when>
                      <c:otherwise>${inv.paymentMethod}</c:otherwise>
                    </c:choose>
                  </td>
                  <td>
                    <c:choose>
                      <c:when test="${inv.status == 'COMPLETED'}"><span class="badge badge-completed">Hoàn tất</span></c:when>
                      <c:when test="${inv.status == 'PENDING'}"><span class="badge badge-pending">Chờ xử lý</span></c:when>
                      <c:when test="${inv.status == 'CANCELLED'}"><span class="badge badge-cancelled">Đã hủy</span></c:when>
                      <c:otherwise>${inv.status}</c:otherwise>
                    </c:choose>
                  </td>
                  <td class="num"><b><fmt:formatNumber value="${inv.finalAmount}" pattern="#,###"/>đ</b></td>
                </tr>
              </c:forEach>
            </tbody>
          </table>
        </c:otherwise>
      </c:choose>

      <c:if test="${totalPages > 1}">
        <div class="pagination">
          <c:forEach begin="1" end="${totalPages}" var="p">
            <c:choose>
              <c:when test="${p == currentPage}">
                <span class="active">${p}</span>
              </c:when>
              <c:otherwise>
                <a href="${pageContext.request.contextPath}/staff-my-invoices?uid=<%= uid %>&date=${filterDate}&page=${p}">${p}</a>
              </c:otherwise>
            </c:choose>
          </c:forEach>
        </div>
      </c:if>
    </div>
  </div>
</div>

</body>
</html>
