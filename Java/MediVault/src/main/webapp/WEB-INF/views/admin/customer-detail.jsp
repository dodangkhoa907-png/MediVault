<%@ page contentType="text/html;charset=UTF-8" %>
<% String activeNav = "customers"; %>
<%@ taglib prefix="c"   uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>${customer.customerName} — MediCare</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;--sidebar:232px;
}
html,body{height:100%;font-family:'Outfit',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}

/* ── Sidebar (dùng chung với các trang admin) ── */
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-text{font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-text span{color:var(--cyan)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:12px 0 4px;flex-shrink:0}
.nav-label{font-size:9px;font-weight:700;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:500;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.14);font-weight:600}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--cyan);border-radius:2px}
.nav-badge{margin-left:auto;background:#DC2626;color:#fff;font-size:10px;font-weight:700;padding:1px 7px;border-radius:20px;min-width:20px;text-align:center}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50;flex-shrink:0}
.topbar-title{font-size:16px;font-weight:700;color:var(--ink)}
.btn-back{display:inline-flex;align-items:center;gap:6px;padding:6px 14px;border-radius:9px;border:1.5px solid var(--border);background:var(--white);color:var(--ink);font-size:13px;font-weight:600;text-decoration:none}
.btn-back:hover{border-color:var(--blue);color:var(--blue)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px}
.btn-edit{display:inline-flex;align-items:center;gap:6px;padding:8px 16px;border-radius:9px;background:var(--blue);color:#fff;font-size:13px;font-weight:700;text-decoration:none}
.btn-edit:hover{background:#0E4890}
.user-av-sm{width:32px;height:32px;border-radius:50%;background:linear-gradient(135deg,#3ABDE0,#1558A8);display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.content{max-width:960px;margin:26px auto;padding:0 20px 48px}

/* HERO */
.hero{position:relative;border-radius:20px;overflow:hidden;margin-bottom:18px;
  background:linear-gradient(120deg,#0F2645 0%,#1558A8 55%,#3ABDE0 130%);
  padding:26px 28px;color:#fff;box-shadow:0 14px 40px rgba(21,88,168,.28)}
.hero::after{content:"";position:absolute;right:-40px;top:-60px;width:220px;height:220px;
  background:radial-gradient(circle,rgba(255,255,255,.16),transparent 70%);border-radius:50%}
.hero-row{display:flex;align-items:center;gap:18px;position:relative;z-index:1}
.hero-av{width:74px;height:74px;border-radius:20px;background:rgba(255,255,255,.16);
  border:2px solid rgba(255,255,255,.35);display:flex;align-items:center;justify-content:center;
  font-size:30px;font-weight:900;flex-shrink:0;backdrop-filter:blur(4px)}
.hero-name{font-size:25px;font-weight:900;line-height:1.1}
.hero-sub{font-size:13px;opacity:.9;margin-top:5px;display:flex;align-items:center;gap:8px;flex-wrap:wrap}
.hero-badges{display:flex;gap:8px;margin-top:10px;flex-wrap:wrap}
.hb{display:inline-flex;align-items:center;gap:5px;padding:4px 11px;border-radius:20px;font-size:12px;font-weight:700;
  background:rgba(255,255,255,.18);border:1px solid rgba(255,255,255,.3)}
.hb.gold{background:rgba(217,119,6,.9);border-color:transparent}
.hb.nfc{background:rgba(16,185,129,.92);border-color:transparent}
.hb.nonfc{background:rgba(255,255,255,.12)}

/* KPI */
.kpi-strip{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-bottom:18px}
.kpi{background:var(--white);border:1px solid var(--border);border-radius:14px;padding:15px 16px;display:flex;align-items:center;gap:12px;transition:.15s}
.kpi:hover{transform:translateY(-2px);box-shadow:0 8px 22px rgba(15,38,69,.08)}
.kpi-icon{width:42px;height:42px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:19px;flex-shrink:0}
.kpi-blue{background:#EFF6FF}.kpi-green{background:#ECFDF5}.kpi-amber{background:#FFFBEB}.kpi-purple{background:#F5F3FF}
.kpi-num{font-size:20px;font-weight:900;line-height:1.1}
.kpi-lbl{font-size:10.5px;color:var(--muted);font-weight:700;text-transform:uppercase;letter-spacing:.4px;margin-top:2px}

.grid-2{display:grid;grid-template-columns:1.15fr .85fr;gap:18px;margin-bottom:18px}
@media(max-width:820px){.grid-2{grid-template-columns:1fr}.kpi-strip{grid-template-columns:repeat(2,1fr)}}
.card{background:var(--white);border:1px solid var(--border);border-radius:16px;overflow:hidden}
.card-head{padding:15px 20px;border-bottom:1px solid var(--border);display:flex;align-items:center;gap:8px}
.card-head h2{font-size:14.5px;font-weight:800}
.card-body{padding:18px 20px}

.info-grid{display:grid;grid-template-columns:1fr 1fr;gap:15px}
.info-item .lbl{font-size:10.5px;font-weight:700;text-transform:uppercase;letter-spacing:.4px;color:var(--muted);margin-bottom:4px}
.info-item .val{font-size:13.5px;font-weight:700;color:var(--ink);word-break:break-word}
.info-item.full{grid-column:1/-1}
.med-box{margin-top:4px;padding:11px 13px;border-radius:11px;font-size:13px;font-weight:600;line-height:1.5}
.med-warn{background:#FEF2F2;border:1px solid #FCA5A5;color:#991B1B}
.med-ok{background:#F0FDF4;border:1px solid #BBF7D0;color:#166534}

/* Loyalty */
.loy-points{text-align:center;padding:6px 0 14px}
.loy-num{font-size:40px;font-weight:900;background:linear-gradient(135deg,#1558A8,#3ABDE0);-webkit-background-clip:text;background-clip:text;-webkit-text-fill-color:transparent;line-height:1}
.loy-lbl{font-size:11px;color:var(--muted);font-weight:700;text-transform:uppercase;letter-spacing:.5px}
.loy-tier-row{display:flex;justify-content:space-between;font-size:12px;font-weight:700;color:var(--muted);margin-bottom:6px}
.loy-bar{height:9px;border-radius:20px;background:#EEF2F7;overflow:hidden}
.loy-bar>span{display:block;height:100%;border-radius:20px;background:linear-gradient(90deg,#1558A8,#3ABDE0)}
.loy-hist{margin-top:16px;max-height:180px;overflow-y:auto}
.loy-hist-item{display:flex;justify-content:space-between;align-items:center;padding:8px 0;border-bottom:1px dashed #EEF2F7;font-size:12.5px}
.loy-hist-item:last-child{border-bottom:none}
.loy-pts{font-weight:800}
.loy-pos{color:var(--green)}.loy-neg{color:var(--red)}

table{width:100%;border-collapse:collapse}
thead th{padding:10px 16px;background:#F8FAFC;font-size:10.5px;font-weight:800;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;white-space:nowrap;border-bottom:1px solid var(--border)}
tbody td{padding:12px 16px;font-size:13px;color:var(--ink);border-bottom:1px solid #F1F5F9}
tbody tr:last-child td{border-bottom:none}
tbody tr{cursor:pointer}
tbody tr:hover td{background:#F7FBFF}
.inv-code{font-family:monospace;font-weight:700;color:var(--blue)}
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:700}
.badge-completed{background:#ECFDF5;color:var(--green)}
.badge-cancelled{background:#FEF2F2;color:var(--red)}
.badge-pending{background:#FFFBEB;color:var(--gold)}
.empty-row{text-align:center;padding:44px;color:var(--muted)}
</style>
</head>
<body>
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">
<div class="topbar">
  <a href="${pageContext.request.contextPath}/customers" class="btn-back">← Khách hàng</a>
  <span class="topbar-title">Hồ sơ khách hàng</span>
  <div class="topbar-right">
    <a href="${pageContext.request.contextPath}/customers?action=edit&id=${customer.customerId}" class="btn-edit">✏️ Sửa hồ sơ</a>
    <div class="user-av-sm"><%= initials %></div>
  </div>
</div>

<div class="content">

  <%-- HERO --%>
  <div class="hero">
    <div class="hero-row">
      <div class="hero-av">${fn:toUpperCase(fn:substring(customer.customerName,0,1))}</div>
      <div style="flex:1">
        <div class="hero-name">${customer.customerName}</div>
        <div class="hero-sub">
          <span>📱 ${not empty customer.phone ? customer.phone : 'Chưa có SĐT'}</span>
          <span>·</span>
          <span>Khách từ ${customer.createdAt != null ? fn:substring(customer.createdAt.toString(),0,10) : '—'}</span>
        </div>
        <div class="hero-badges">
          <c:if test="${card != null and not empty card.tierName}">
            <span class="hb gold">🏅 Hạng ${card.tierName}</span>
          </c:if>
          <c:choose>
            <c:when test="${not empty customer.nfcCardUid}">
              <span class="hb nfc">📶 Đã gắn thẻ NFC</span>
            </c:when>
            <c:otherwise>
              <span class="hb nonfc">📴 Chưa có thẻ NFC</span>
            </c:otherwise>
          </c:choose>
          <c:if test="${not empty customer.chronicDisease or not empty customer.allergyHistory}">
            <span class="hb" style="background:rgba(220,38,38,.9);border-color:transparent">⚠️ Có cảnh báo y tế</span>
          </c:if>
        </div>
      </div>
    </div>
  </div>

  <%-- KPI --%>
  <div class="kpi-strip">
    <div class="kpi">
      <div class="kpi-icon kpi-blue">🧾</div>
      <div><div class="kpi-num">${fn:length(invoices)}</div><div class="kpi-lbl">Hóa đơn</div></div>
    </div>
    <div class="kpi">
      <div class="kpi-icon kpi-green">💰</div>
      <div><div class="kpi-num"><fmt:formatNumber value="${totalSpent}" type="number" maxFractionDigits="0"/>đ</div><div class="kpi-lbl">Tổng chi tiêu</div></div>
    </div>
    <div class="kpi">
      <div class="kpi-icon kpi-purple">⭐</div>
      <div><div class="kpi-num">${card != null ? card.availablePoints : 0}</div><div class="kpi-lbl">Điểm khả dụng</div></div>
    </div>
    <div class="kpi">
      <div class="kpi-icon kpi-amber">🎂</div>
      <div><div class="kpi-num" style="font-size:15px">${customer.dateOfBirth != null ? customer.dateOfBirth : '—'}</div><div class="kpi-lbl">Ngày sinh</div></div>
    </div>
  </div>

  <div class="grid-2">
    <%-- THÔNG TIN --%>
    <div class="card">
      <div class="card-head">📇 <h2>Thông tin liên hệ &amp; cá nhân</h2></div>
      <div class="card-body">
        <div class="info-grid">
          <div class="info-item"><div class="lbl">Email</div><div class="val">${not empty customer.email ? customer.email : '—'}</div></div>
          <div class="info-item"><div class="lbl">Giới tính</div><div class="val">
            <c:choose>
              <c:when test="${customer.gender == 'M'}">Nam</c:when>
              <c:when test="${customer.gender == 'F'}">Nữ</c:when>
              <c:otherwise>—</c:otherwise>
            </c:choose>
          </div></div>
          <div class="info-item"><div class="lbl">Nghề nghiệp</div><div class="val">${not empty customer.occupation ? customer.occupation : '—'}</div></div>
          <div class="info-item"><div class="lbl">CCCD/CMND</div><div class="val">${not empty customer.nationalId ? customer.nationalId : '—'}</div></div>
          <div class="info-item full"><div class="lbl">Địa chỉ</div><div class="val">${not empty customer.address ? customer.address : '—'}</div></div>
          <div class="info-item full"><div class="lbl">Mã thẻ NFC</div><div class="val" style="font-family:monospace">${not empty customer.nfcCardUid ? customer.nfcCardUid : '— chưa liên kết —'}</div></div>

          <div class="info-item full">
            <div class="lbl">⚠️ Tiền sử dị ứng</div>
            <c:choose>
              <c:when test="${not empty customer.allergyHistory}">
                <div class="med-box med-warn">${customer.allergyHistory}</div>
              </c:when>
              <c:otherwise><div class="med-box med-ok">Không ghi nhận dị ứng.</div></c:otherwise>
            </c:choose>
          </div>
          <div class="info-item full">
            <div class="lbl">⚠️ Bệnh mạn tính</div>
            <c:choose>
              <c:when test="${not empty customer.chronicDisease}">
                <div class="med-box med-warn">${customer.chronicDisease}</div>
              </c:when>
              <c:otherwise><div class="med-box med-ok">Không ghi nhận bệnh mạn tính.</div></c:otherwise>
            </c:choose>
          </div>
        </div>
      </div>
    </div>

    <%-- THẺ TÍCH ĐIỂM --%>
    <div class="card">
      <div class="card-head">⭐ <h2>Thẻ tích điểm</h2></div>
      <div class="card-body">
        <div class="loy-points">
          <div class="loy-num">${card != null ? card.availablePoints : 0}</div>
          <div class="loy-lbl">điểm khả dụng</div>
        </div>
        <c:if test="${card != null and not empty card.nextTierName and card.nextTierMinPoints > 0}">
          <c:set var="pct" value="${card.totalPoints * 100 / card.nextTierMinPoints}"/>
          <div class="loy-tier-row">
            <span>${not empty card.tierName ? card.tierName : 'Thành viên'}</span>
            <span>→ ${card.nextTierName}</span>
          </div>
          <div class="loy-bar"><span style="width:${pct > 100 ? 100 : pct}%"></span></div>
          <div style="font-size:11.5px;color:var(--muted);margin-top:6px;text-align:center">
            ${card.totalPoints} / ${card.nextTierMinPoints} điểm tích lũy
          </div>
        </c:if>

        <div class="loy-hist">
          <c:choose>
            <c:when test="${empty pointHistory}">
              <div style="text-align:center;color:var(--muted);font-size:12.5px;padding:16px 0">Chưa có giao dịch điểm.</div>
            </c:when>
            <c:otherwise>
              <c:forEach var="h" items="${pointHistory}">
                <div class="loy-hist-item">
                  <div style="min-width:0">
                    <div style="font-weight:600;color:var(--ink);white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:160px">${h[2]}</div>
                    <div style="font-size:11px;color:var(--muted)">${h[3]}</div>
                  </div>
                  <div class="loy-pts ${h[0] == 'EARN' ? 'loy-pos' : 'loy-neg'}">${h[0] == 'EARN' ? '+' : '−'}${fn:replace(h[1],'-','')}</div>
                </div>
              </c:forEach>
            </c:otherwise>
          </c:choose>
        </div>
      </div>
    </div>
  </div>

  <%-- LỊCH SỬ MUA HÀNG --%>
  <div class="card">
    <div class="card-head">📋 <h2>Lịch sử mua hàng</h2></div>
    <div style="overflow-x:auto">
      <table>
        <thead><tr><th>Mã HĐ</th><th>Thời gian</th><th>Thanh toán</th><th>Thành tiền</th><th>Trạng thái</th></tr></thead>
        <tbody>
          <c:if test="${empty invoices}">
            <tr><td colspan="5" class="empty-row">🛒 Khách hàng chưa có hóa đơn nào.</td></tr>
          </c:if>
          <c:forEach var="inv" items="${invoices}">
            <tr onclick="location.href='${pageContext.request.contextPath}/invoices?action=detail&id=${inv.invoiceId}'">
              <td><span class="inv-code">${inv.invoiceCode}</span></td>
              <td style="color:var(--muted);font-size:12.5px">${fn:substring(inv.createdAt.toString(),0,16)}</td>
              <td>${inv.paymentMethod}</td>
              <td style="font-weight:800"><fmt:formatNumber value="${inv.finalAmount}" type="number" maxFractionDigits="0"/>đ</td>
              <td>
                <c:choose>
                  <c:when test="${inv.status == 'COMPLETED'}"><span class="badge badge-completed">✅ Hoàn tất</span></c:when>
                  <c:when test="${inv.status == 'CANCELLED'}"><span class="badge badge-cancelled">❌ Đã hủy</span></c:when>
                  <c:otherwise><span class="badge badge-pending">⏳ Đang xử lý</span></c:otherwise>
                </c:choose>
              </td>
            </tr>
          </c:forEach>
        </tbody>
      </table>
    </div>
  </div>
</div><%-- .content --%>
</div><%-- .main --%>
</body>
</html>
