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
<title>Quản lý tồn kho — MediCare</title>
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

.stats{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:22px}
.stat{background:#fff;
  border:1px solid #E7E8F1;border-radius:14px;padding:16px 18px;
  box-shadow:0 1px 2px rgba(30,27,75,.04),0 8px 22px -14px rgba(30,27,75,.10);
  display:flex;align-items:center;gap:14px}
.stat .ic{width:44px;height:44px;border-radius:12px;display:grid;place-items:center;font-size:20px;flex:none}
.stat .num{font-size:24px;font-weight:800;letter-spacing:-.5px;line-height:1}
.stat .lbl{font-size:12.5px;color:var(--muted);font-weight:600;margin-top:3px}
.stat.a .ic{background:var(--soft);color:var(--main)}
.stat.b .ic{background:var(--goldbg);color:var(--gold)} .stat.b .num{color:var(--gold)}
.stat.c .ic{background:var(--goldbg);color:var(--gold)}
.stat.d .ic{background:var(--dangerbg);color:var(--danger)} .stat.d .num{color:var(--danger)}

.card{background:#fff;border:1px solid #E7E8F1;border-radius:16px;overflow:hidden;margin-bottom:22px;box-shadow:0 1px 2px rgba(30,27,75,.04),0 12px 30px -18px rgba(30,27,75,.12)}
.card-head{display:flex;align-items:center;justify-content:space-between;flex-wrap:wrap;gap:12px;
  padding:16px 20px;border-bottom:1px solid var(--line)}
.card-head h2{font-size:15px;font-weight:800}
.card-head h2 small{color:var(--muted);font-weight:600;font-size:12.5px;margin-left:6px}

.search{display:flex;gap:8px}
.search input{width:280px;max-width:52vw;padding:10px 14px;border:1.5px solid var(--border);border-radius:10px;
  font-family:inherit;font-size:14px;background:var(--surface);color:var(--ink)}
.search input:focus{outline:none;border-color:var(--main);background:#fff;box-shadow:0 0 0 3px rgba(67,56,202,.12)}
.search button{padding:10px 16px;border:none;border-radius:10px;background:linear-gradient(135deg,var(--main),var(--deep));
  color:#fff;font-weight:700;font-size:13.5px;cursor:pointer;font-family:inherit}
.search a.clear{padding:10px 14px;border:1.5px solid var(--border);border-radius:10px;color:var(--muted);font-weight:700;font-size:13.5px}

.tblwrap{overflow-x:auto}
table{border-collapse:collapse;width:100%;font-size:13.5px;min-width:760px}
th,td{padding:11px 16px;text-align:left;border-bottom:1px solid var(--line);white-space:nowrap}
thead th{font-size:11px;letter-spacing:.06em;text-transform:uppercase;color:var(--muted);font-weight:700;background:var(--surface)}
tbody tr:hover{background:var(--surface)}
.code{font-family:ui-monospace,Consolas,monospace;font-size:12px;color:var(--muted)}
.mname{font-weight:700;color:var(--ink)}
.gen{font-size:12px;color:var(--muted)}
.num-cell{text-align:right;font-variant-numeric:tabular-nums;font-weight:700}
.badge{display:inline-block;padding:2px 9px;border-radius:20px;font-size:11.5px;font-weight:700}
.badge.ok{background:var(--okbg);color:var(--ok)}
.badge.low{background:var(--goldbg);color:var(--gold)}
.badge.out{background:var(--dangerbg);color:var(--danger)}
.empty{padding:36px;text-align:center;color:var(--muted);font-size:14px}

.grid2{display:grid;grid-template-columns:1fr 1fr;gap:22px}
.panel h2 .ic{margin-right:6px}
.warn-head{background:linear-gradient(90deg,#FEF3C7,transparent)}
.dead-head{background:linear-gradient(90deg,var(--dangerbg),transparent)}
.exp-date{font-weight:700}
.exp-soon{color:var(--gold)} .exp-dead{color:var(--danger)}

@media(max-width:900px){.stats{grid-template-columns:repeat(2,1fr)}.grid2{grid-template-columns:1fr}}
</style>
</head>
<body class="wh">
<%@ include file="warehouse-sidebar.jsp" %>
<div class="main">
  <header class="wh-topbar">
    <div class="crumb">Quản lý tồn kho</div>
    <div class="right">
      <a href="<%= ctx %>/staff-checkin?uid=<%= uid %>" class="wh-av" title="Ca làm việc"><%= initials %></a>
    </div>
  </header>

  <div class="wrap">
    <div class="head">
      <div>
        <h1>Quản lý <span>tồn kho</span></h1>
        <p>Danh mục thuốc, tồn kho thực tế theo lô, và cảnh báo hạn dùng.</p>
      </div>
    </div>

    <div class="stats">
      <div class="stat a"><div class="ic">💊</div><div><div class="num">${totalActive}</div><div class="lbl">Thuốc đang kinh doanh</div></div></div>
      <div class="stat b"><div class="ic">📉</div><div><div class="num">${lowStockCount}</div><div class="lbl">Sắp hết hàng</div></div></div>
      <div class="stat c"><div class="ic">⏳</div><div><div class="num">${expiringBatches.size()}</div><div class="lbl">Lô cận hạn (≤30 ngày)</div></div></div>
      <div class="stat d"><div class="ic">⛔</div><div><div class="num">${expiredBatches.size()}</div><div class="lbl">Lô đã hết hạn</div></div></div>
    </div>

    <div class="card">
      <div class="card-head">
        <div style="display:flex;align-items:center;gap:12px">
          <div class="wh-ic">💊</div>
          <h2>Danh mục thuốc <small>(${medicines.size()} mục)</small></h2>
        </div>
        <form class="search" method="get" action="<%= ctx %>/warehouse-inventory">
          <input type="hidden" name="uid" value="${staffUid}">
          <div class="wh-field">
            <span class="wh-field-ic">🔍</span>
            <input type="text" name="q" value="${fn:escapeXml(keyword)}" placeholder="Tìm tên, hoạt chất, barcode, mã thuốc…">
          </div>
          <button type="submit">🔍 Tìm</button>
          <c:if test="${not empty keyword}"><a class="clear" href="<%= ctx %>/warehouse-inventory?uid=${staffUid}">✕</a></c:if>
        </form>
      </div>
      <div class="tblwrap">
        <table>
          <thead><tr>
            <th>Mã</th><th>Thuốc</th><th>Barcode</th><th>ĐVT</th>
            <th style="text-align:right">Tồn kho</th><th>Trạng thái</th>
            <th style="text-align:right">Giá bán</th><th>HSD gần nhất</th>
          </tr></thead>
          <tbody>
          <c:choose>
            <c:when test="${empty medicines}">
              <tr><td colspan="8" class="empty">Không có thuốc nào khớp tìm kiếm.</td></tr>
            </c:when>
            <c:otherwise>
              <c:forEach var="m" items="${medicines}">
                <tr>
                  <td class="code">${m.medicineCode}</td>
                  <td>
                    <div class="mname">${m.medicineName}</div>
                    <c:if test="${not empty m.genericName}"><div class="gen">${m.genericName}</div></c:if>
                  </td>
                  <td class="code">${empty m.barcode ? '—' : m.barcode}</td>
                  <td>${m.unit}</td>
                  <td class="num-cell">${m.totalStock} / <span style="color:var(--muted);font-weight:600">${m.minInventory}</span></td>
                  <td>
                    <c:choose>
                      <c:when test="${m.totalStock == 0}"><span class="badge out">Hết hàng</span></c:when>
                      <c:when test="${m.minInventory > 0 && m.totalStock <= m.minInventory}"><span class="badge low">Sắp hết</span></c:when>
                      <c:otherwise><span class="badge ok">Đủ hàng</span></c:otherwise>
                    </c:choose>
                  </td>
                  <td class="num-cell"><fmt:formatNumber value="${m.sellingPrice}" type="number" maxFractionDigits="0"/>đ</td>
                  <td>${empty m.nearestExpiry ? '—' : m.nearestExpiry}</td>
                </tr>
              </c:forEach>
            </c:otherwise>
          </c:choose>
          </tbody>
        </table>
      </div>
    </div>

    <div class="grid2">
      <div class="card panel">
        <div class="card-head warn-head"><div class="wh-ic warn">⏳</div><h2>Lô cận hạn dùng <small>≤ 30 ngày</small></h2></div>
        <div class="tblwrap">
          <table style="min-width:auto">
            <thead><tr><th>Số lô</th><th>Thuốc</th><th style="text-align:right">Còn tồn</th><th>Hạn dùng</th></tr></thead>
            <tbody>
              <c:choose>
                <c:when test="${empty expiringBatches}"><tr><td colspan="4" class="empty">Không có lô nào cận hạn. 👍</td></tr></c:when>
                <c:otherwise>
                  <c:forEach var="b" items="${expiringBatches}">
                    <tr>
                      <td class="code">${b.batchNumber}</td>
                      <td class="mname">${medNameMap[b.medicineId]}</td>
                      <td class="num-cell">${b.currentQuantity}</td>
                      <td class="exp-date exp-soon">${b.expiryDate}</td>
                    </tr>
                  </c:forEach>
                </c:otherwise>
              </c:choose>
            </tbody>
          </table>
        </div>
      </div>

      <div class="card panel">
        <div class="card-head dead-head"><div class="wh-ic danger">⛔</div><h2>Lô đã hết hạn</h2></div>
        <div class="tblwrap">
          <table style="min-width:auto">
            <thead><tr><th>Số lô</th><th>Thuốc</th><th style="text-align:right">Còn tồn</th><th>Hạn dùng</th></tr></thead>
            <tbody>
              <c:choose>
                <c:when test="${empty expiredBatches}"><tr><td colspan="4" class="empty">Không có lô hết hạn tồn kho. 👍</td></tr></c:when>
                <c:otherwise>
                  <c:forEach var="b" items="${expiredBatches}">
                    <tr>
                      <td class="code">${b.batchNumber}</td>
                      <td class="mname">${medNameMap[b.medicineId]}</td>
                      <td class="num-cell">${b.currentQuantity}</td>
                      <td class="exp-date exp-dead">${b.expiryDate}</td>
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
