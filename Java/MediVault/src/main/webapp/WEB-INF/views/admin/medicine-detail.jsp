<%@ page contentType="text/html;charset=UTF-8"  pageEncoding="UTF-8" %>
  <% String activeNav="medicines" ; %>
    <%@ taglib prefix="c" uri="jakarta.tags.core" %>
      <%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
        <% com.medicare.entity.Account acc=(com.medicare.entity.Account) session.getAttribute("adminAccount"); if
          (acc==null) { response.sendRedirect(request.getContextPath() + "/login" ); return; } String
          fullName=acc.getFullName() !=null ? acc.getFullName() : acc.getUsername(); String initials=fullName.length()>=
          2
          ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
          : fullName.toUpperCase();
          String msg = request.getParameter("msg");
          %>
          <!DOCTYPE html>
          <html lang="vi">

          <head>
    <link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin><link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
    
    
    
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width,initial-scale=1.0">
            <title>${medicine.medicineName} — Lô hàng — medicare</title>
            
            
            <style>
              *,
              *::before,
              *::after {
                box-sizing: border-box;
                margin: 0;
                padding: 0
              }

              :root {
                --ink: #0B1628;
                --navy: #0F2645;
                --blue: #1558A8;
                --cyan: #3ABDE0;
                --surface: #F1F5FB;
                --white: #fff;
                --muted: #7A90B0;
                --border: #D5E0F0;
                --green: #059669;
                --red: #DC2626;
                --gold: #D97706;
                --sidebar: 232px;
              }

              html,
              body {
                min-height: 100%;
                font-family:'Plus Jakarta Sans',sans-serif;
                background: var(--surface);
                color: var(--ink)
              }

              body {
                display: flex
              }

              .sidebar {
                width: var(--sidebar);
                min-height: 100vh;
                background: linear-gradient(175deg, #071022 0%, #0F2645 45%, #1558A8 100%);
                display: flex;
                flex-direction: column;
                position: fixed;
                left: 0;
                top: 0;
                bottom: 0;
                z-index: 100
              }

              .sidebar-logo {
                height: 66px;
                padding: 0 20px;
                display: flex;
                align-items: center;
                gap: 11px;
                border-bottom: 1px solid rgba(255, 255, 255, .06)
              }

              .logo-icon {
                width: 36px;
                height: 36px;
                background: linear-gradient(135deg, #3ABDE0, #1558A8);
                border-radius: 10px;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 18px
              }

              .logo-text {
                font-size: 16px;
                font-weight: 800;
                color: #fff;
                line-height: 1.1
              }

              .logo-sub {
                font-size: 10px;
                color: rgba(255, 255, 255, .45);
                font-weight:750;
                text-transform: uppercase
              }

              .nav-section {
                padding: 10px 12px 4px
              }

              .nav-label {
                font-size: 9.5px;
                font-weight:750;
                color: rgba(255, 255, 255, .3);
                letter-spacing: 1px;
                text-transform: uppercase;
                padding: 0 8px;
                margin-bottom: 4px
              }

              .nav-item {
                display: flex;
                align-items: center;
                gap: 9px;
                padding: 9px 10px;
                border-radius: 10px;
                color: rgba(255, 255, 255, .6);
                text-decoration: none;
                font-size: 13.5px;
                font-weight:750;
                transition: all .16s;
                margin-bottom: 2px
              }

              .nav-item:hover {
                background: rgba(255, 255, 255, .07);
                color: #fff
              }

              .nav-item.active {
                background: rgba(58, 189, 224, .15);
                color: #fff;
                border: 1px solid rgba(58, 189, 224, .2)
              }

              .sidebar-footer {
                margin-top: auto;
                padding: 14px 16px;
                border-top: 1px solid rgba(255, 255, 255, .06)
              }

              .sidebar-user {
                display: flex;
                align-items: center;
                gap: 10px;
                padding: 10px 12px;
                border-radius: 12px;
                background: rgba(255, 255, 255, .06);
                border: 1px solid rgba(255, 255, 255, .08)
              }

              .user-av {
                width: 34px;
                height: 34px;
                border-radius: 50%;
                background: linear-gradient(135deg, #3ABDE0, #1558A8);
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 13px;
                font-weight: 800;
                color: #fff;
                flex-shrink: 0
              }

              .user-name {
                font-size: 13px;
                font-weight:750;
                color: #fff
              }

              .user-role {
                font-size: 11px;
                color: rgba(255, 255, 255, .4)
              }

              .logout-btn {
                margin-left: auto;
                width: 30px;
                height: 30px;
                border-radius: 8px;
                display: flex;
                align-items: center;
                justify-content: center;
                color: rgba(255, 255, 255, .4);
                text-decoration: none;
                font-size: 16px
              }

              .logout-btn:hover {
                background: rgba(220, 38, 38, .2);
                color: #DC2626
              }

              .main {
                margin-left: var(--sidebar);
                flex: 1;
                display: flex;
                flex-direction: column;
                min-height: 100vh
              }

              .topbar {
                height: 62px;
                background: var(--white);
                border-bottom: 1px solid var(--border);
                display: flex;
                align-items: center;
                padding: 28px;
                gap: 14px;
                position: sticky;
                top: 0;
                z-index: 50
              }

              .btn-back {
                display: inline-flex;
                align-items: center;
                gap: 6px;
                padding: 6px 14px;
                border-radius: 9px;
                border: 1.5px solid var(--border);
                background: var(--white);
                color: var(--ink);
                font-size: 13px;
                font-weight:750;
                text-decoration: none
              }

              .btn-back:hover {
                border-color: var(--blue);
                color: var(--blue)
              }

              .topbar-right {
                margin-left: auto;
                display: flex;
                align-items: center;
                gap: 10px
              }

              .btn-primary {
                height: 36px;
                padding: 0 16px;
                background: var(--blue);
                color: #fff;
                border: none;
                border-radius: 9px;
                font-size: 13px;
                font-weight:750;
                cursor: pointer;
                text-decoration: none;
                display: inline-flex;
                align-items: center;
                gap: 6px
              }

              .content {
                padding: 24px 28px
              }

              .med-info-card {
                background: var(--white);
                border: 1px solid var(--border);
                border-radius: 16px;
                padding: 20px 24px;
                margin-bottom: 20px;
                display: flex;
                align-items: center;
                gap: 20px
              }

              .med-icon {
                width: 56px;
                height: 56px;
                border-radius: 14px;
                background: linear-gradient(135deg, #EFF6FF, #DBEAFE);
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 28px;
                flex-shrink: 0
              }

              .med-title {
                font-family:'Lora',serif;
                font-size: 22px;
                color: var(--ink)
              }

              .med-meta {
                font-size: 13px;
                color: var(--muted);
                margin-top: 4px;
                display: flex;
                gap: 14px;
                flex-wrap: wrap
              }

              .med-meta span {
                display: flex;
                align-items: center;
                gap: 4px
              }

              .med-actions {
                margin-left: auto;
                display: flex;
                gap: 8px
              }

              .badge {
                display: inline-flex;
                align-items: center;
                padding: 3px 9px;
                border-radius: 20px;
                font-size: 11px;
                font-weight:750
              }

              .badge-green {
                background: #D1FAE5;
                color: #065F46
              }

              .badge-blue {
                background: #EFF6FF;
                color: #1D4ED8
              }

              .badge-gold {
                background: #FEF3C7;
                color: #92400E
              }

              .badge-red {
                background: #FEE2E2;
                color: #991B1B
              }

              .badge-gray {
                background: #F1F5F9;
                color: #64748B
              }

              .badge-orange {
                background: #FFF7ED;
                color: #C2410C
              }

              .btn-destroy {
                color: #991B1B;
                border-color: #FCA5A5;
                background: #FFF1F1
              }

              /* Stats */
              .stats-row {
                display: grid;
                grid-template-columns: repeat(4, 1fr);
                gap: 12px;
                margin-bottom: 20px
              }

              .stat-card {
                background: var(--white);
                border: 1px solid var(--border);
                border-radius: 12px;
                padding: 14px 16px
              }

              .stat-val {
                font-size: 24px;
                font-weight: 800;
                color: var(--ink)
              }

              .stat-lbl {
                font-size: 12px;
                color: var(--muted);
                margin-top: 2px
              }

              .stat-card.ok .stat-val {
                color: var(--green)
              }

              .stat-card.warn .stat-val {
                color: var(--gold)
              }

              .stat-card.danger .stat-val {
                color: var(--red)
              }

              /* Table */
              .section-header {
                display: flex;
                align-items: center;
                justify-content: space-between;
                margin-bottom: 12px
              }

              .section-title {
                font-size: 15px;
                font-weight: 800;
                color: var(--navy)
              }

              .table-wrap {
                background: var(--white);
                border: 1px solid var(--border);
                border-radius: 14px;
                overflow: hidden
              }

              table {
                width: 100%;
                border-collapse: collapse
              }

              thead th {
                padding: 10px 14px;
                font-size: 11px;
                font-weight:750;
                text-transform: uppercase;
                letter-spacing: .5px;
                color: var(--muted);
                background: #F8FAFE;
                border-bottom: 1px solid var(--border);
                text-align: left
              }

              tbody td {
                padding: 12px 14px;
                font-size: 13.5px;
                border-bottom: .5px solid #F0F4FB;
                vertical-align: middle
              }

              tbody tr:last-child td {
                border-bottom: none
              }

              tbody tr:hover td {
                background: #FAFBFF
              }

              .qty-bar {
                display: flex;
                align-items: center;
                gap: 8px
              }

              .bar-bg {
                flex: 1;
                height: 6px;
                background: #EEF2FF;
                border-radius: 3px;
                max-width: 80px
              }

              .bar-fill {
                height: 6px;
                border-radius: 3px;
                background: var(--green)
              }

              .bar-fill.low {
                background: var(--gold)
              }

              .bar-fill.out {
                background: var(--red)
              }

              .btn-sm {
                height: 30px;
                padding: 0 10px;
                border-radius: 8px;
                font-size: 12px;
                font-weight:750;
                cursor: pointer;
                border: 1.5px solid;
                font-family: inherit;
                text-decoration: none;
                display: inline-flex;
                align-items: center;
                gap: 4px
              }

              .btn-edit {
                color: #7C3AED;
                border-color: #DDD6FE;
                background: #F5F3FF
              }

              .btn-del {
                color: var(--red);
                border-color: #FECACA;
                background: #FFF5F5
              }

              .empty-row td {
                text-align: center;
                padding: 36px;
                color: var(--muted)
              }

              .toast {
                position: fixed;
                top: 18px;
                right: 24px;
                z-index: 999;
                padding: 12px 20px;
                border-radius: 12px;
                font-size: 13.5px;
                font-weight:750;
                box-shadow: 0 4px 24px rgba(0, 0, 0, .12)
              }

              .toast-ok {
                background: #ECFDF5;
                color: #065F46;
                border: 1px solid #A7F3D0
              }

              .toast-warn {
                background: #FFFBEB;
                color: #92400E;
                border: 1px solid #FDE68A
              }

              .toast-err {
                background: #FFF5F5;
                color: #991B1B;
                border: 1px solid #FECACA
              }

              /* FEFO badge */
              .fefo-badge {
                display: inline-block;
                padding: 2px 7px;
                border-radius: 5px;
                font-size: 10px;
                font-weight: 800;
                background: #ECFDF5;
                color: #065F46;
                border: 1px solid #A7F3D0;
                margin-left: 5px;
                letter-spacing: .4px;
                vertical-align: middle
              }

              /* Expiry color coding */
              .expiry-ok { color: #059669; font-weight:750 }
              .expiry-warn { color: #D97706; font-weight:750 }
              .expiry-err { color: #DC2626; font-weight:750 }

              /* Action buttons */
              .btn-stock { color: #059669; border-color: #A7F3D0; background: #F0FDF4 }
              .btn-void { color: #6B7280; border-color: #E5E7EB; background: #F9FAFB }
              .btn-destroy { color: #DC2626; border-color: #FECACA; background: #FFF5F5 }

              /* Inline add-stock form */
              .add-stock-row { display:none;margin-top:6px }
              .add-stock-form {
                display: inline-flex;
                align-items: center;
                gap: 5px;
                background: #F0FDF4;
                border: 1px solid #A7F3D0;
                border-radius: 8px;
                padding: 5px 9px
              }
              .add-stock-form input[type=number] {
                width: 68px;
                height: 26px;
                padding: 0 7px;
                border: 1px solid #A7F3D0;
                border-radius: 5px;
                font-size: 12.5px;
                font-family: inherit;
                outline: none
              }
              .add-stock-form .btn-confirm {
                height: 26px;
                padding: 0 9px;
                background: #059669;
                color: #fff;
                border: none;
                border-radius: 5px;
                font-size: 12px;
                font-weight:750;
                cursor: pointer;
                font-family: inherit
              }
              .add-stock-form .btn-x {
                height: 26px;
                padding: 0 7px;
                background: transparent;
                color: var(--muted);
                border: 1px solid var(--border);
                border-radius: 5px;
                font-size: 12px;
                cursor: pointer;
                font-family: inherit
              }

              /* Batch sub-info */
              .batch-sub { font-size: 11.5px; color: var(--muted); margin-top: 2px }
            </style>
              
<meta name="csrf-token" content="${csrfToken}">
<script src="${pageContext.request.contextPath}/js/csrf.js"></script>
</head>

          <body>
            <% if ("batch-added".equals(msg)) { %>
              <div class="toast toast-ok">✅ Đã nhập lô hàng mới!</div>
              <% } else if ("batch-updated".equals(msg)) { %>
                <div class="toast toast-ok">✅ Đã cập nhật lô hàng!</div>
                <% } else if ("batch-deleted".equals(msg)) { %>
                  <div class="toast toast-warn">🗑️ Đã hủy lô hàng (CANCELLED).</div>
                  <% } else if ("batch-destroyed".equals(msg)) { %>
                    <div class="toast toast-warn">⚠️ Đã tiêu hủy lô hàng (DESTROYED).</div>
                    <% } else if ("batch-has-stock".equals(msg)) { %>
                      <div class="toast toast-err">⚠️ Không thể hủy — lô này còn hàng! Dùng Tiêu hủy.</div>
                      <% } else if ("batch-has-sales".equals(msg)) { %>
                        <div class="toast toast-err">⚠️ Không thể hủy — lô đã có lịch sử bán hàng!</div>
                        <% } else if ("batch-destroy-fail".equals(msg)) { %>
                          <div class="toast toast-err">❌ Tiêu hủy thất bại — kiểm tra lại trạng thái lô.</div>
                          <% } else if ("stock-added".equals(msg)) { %>
                            <div class="toast toast-ok">✅ Đã bổ sung hàng vào lô!</div>
                            <% } else if ("stock-add-fail".equals(msg)) { %>
                              <div class="toast toast-err">❌ Bổ sung thất bại — lô có thể không còn ACTIVE.</div>
                              <% } else if ("stock-qty-invalid".equals(msg)) { %>
                                <div class="toast toast-warn">⚠️ Số lượng nhập thêm phải lớn hơn 0.</div>
                                <% } %>

                      <%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

                        <div class="main">
                          <div class="topbar">
                            <a href="${pageContext.request.contextPath}/medicines" class="btn-back">← Kho thuốc</a>
                            <div class="topbar-right">
                              <a href="${pageContext.request.contextPath}/medicines?action=new-batch&medicineId=${medicine.medicineId}"
                                class="btn-primary">＋ Nhập lô mới</a>
                            </div>
                          </div>

                          <div class="content">
                            <%-- Medicine info --%>
                              <div class="med-info-card">
                                <div class="med-icon">💊</div>
                                <div>
                                  <div class="med-title">${medicine.medicineName}</div>
                                  <div class="med-meta">
                                    <span>🔖 ${medicine.medicineCode}</span>
                                    <c:if test="${not empty medicine.genericName}"><span>⚗️
                                        ${medicine.genericName}</span></c:if>
                                    <span>📦 ${medicine.unit}</span>
                                    <span>💰
                                      <fmt:formatNumber value="${medicine.sellingPrice}" type="number"
                                        maxFractionDigits="0" />đ
                                    </span>
                                  </div>
                                </div>
                                <div class="med-actions">
                                  <c:choose>
                                    <c:when test="${medicine.prescriptionRequired}">
                                      <span class="badge badge-red">🔴 Kê toa</span>
                                    </c:when>
                                    <c:otherwise>
                                      <span class="badge badge-green">OTC</span>
                                    </c:otherwise>
                                  </c:choose>
                                  <a href="${pageContext.request.contextPath}/medicines?action=edit&id=${medicine.medicineId}"
                                    class="btn-sm btn-edit">✏️ Sửa thông tin</a>
                                </div>
                              </div>

                              <%-- Stats --%>
                                <div class="stats-row">
                                  <div
                                    class="stat-card ${totalStock == 0 ? 'danger' : totalStock <= medicine.minInventory ? 'warn' : 'ok'}">
                                    <div class="stat-val">${totalStock}</div>
                                    <div class="stat-lbl">📦 Tổng tồn kho</div>
                                  </div>
                                  <div class="stat-card">
                                    <div class="stat-val">${fn:length(batches)}</div>
                                    <div class="stat-lbl">📋 Số lô hiện có</div>
                                  </div>
                                  <div class="stat-card">
                                    <div class="stat-val">${medicine.minInventory}</div>
                                    <div class="stat-lbl">⚠️ Tồn kho tối thiểu</div>
                                  </div>
                                  <div class="stat-card">
                                    <div class="stat-val">${medicine.expiryAlertDays}</div>
                                    <div class="stat-lbl">📅 Cảnh báo hết hạn (ngày)</div>
                                  </div>
                                </div>

                                <%-- Batches table --%>
                                  <div class="section-header">
                                    <div class="section-title">📦 Danh sách lô hàng</div>
                                  </div>
                                  <div class="table-wrap">
                                    <table>
                                      <thead>
                                        <tr>
                                          <th>Lô hàng</th>
                                          <th>Ngày hết hạn</th>
                                          <th>Tồn kho</th>
                                          <th>Trạng thái</th>
                                          <th>Thao tác</th>
                                        </tr>
                                      </thead>
                                      <tbody>
                                        <c:choose>
                                          <c:when test="${empty batches}">
                                            <tr class="empty-row">
                                              <td colspan="5">📭 Chưa có lô hàng nào.
                                                <a href="${pageContext.request.contextPath}/medicines?action=new-batch&medicineId=${medicine.medicineId}">
                                                  Nhập lô đầu tiên
                                                </a>
                                              </td>
                                            </tr>
                                          </c:when>
                                          <c:otherwise>
                                            <c:set var="fefoMarked" value="${false}"/>
                                            <c:forEach var="b" items="${batches}" varStatus="st">
                                              <c:set var="isDestroyed" value="${b.status eq 'DESTROYED'}"/>
                                              <c:set var="isExpired"   value="${b.expiryDate.isBefore(today)}"/>
                                              <c:set var="isActive"    value="${b.status eq 'ACTIVE'}"/>
                                              <c:set var="hasSales"    value="${b.currentQuantity lt b.initialQuantity}"/>
                                              <%-- FEFO = lô ACTIVE đầu tiên còn hàng, chưa hết hạn (batches đã sort ExpiryDate ASC) --%>
                                              <c:set var="isFefo" value="${not fefoMarked and isActive and b.currentQuantity gt 0 and not isExpired}"/>
                                              <c:if test="${isFefo}"><c:set var="fefoMarked" value="${true}"/></c:if>
                                              <tr>
                                                <%-- Cột 1: Số lô + phụ (giá nhập, NSX, ngày nhập) --%>
                                                <td>
                                                  <strong style="font-family:monospace;font-size:13.5px">${b.batchNumber}</strong>
                                                  <c:if test="${isFefo}"><span class="fefo-badge">FEFO ▶</span></c:if>
                                                  <div class="batch-sub">
                                                    <fmt:formatNumber value="${b.importPrice}" type="number" maxFractionDigits="0"/>đ/đv
                                                    <c:if test="${b.importDate != null}"> · Nhập ${b.importDate}</c:if>
                                                    <c:if test="${b.manufactureDate != null}"> · NSX ${b.manufactureDate}</c:if>
                                                  </div>
                                                </td>
                                                <%-- Cột 2: HSD với màu sắc --%>
                                                <td>
                                                  <c:choose>
                                                    <c:when test="${isExpired}">
                                                      <span class="expiry-err">${b.expiryDate}</span>
                                                    </c:when>
                                                    <c:when test="${b.expiryDate.isBefore(today90)}">
                                                      <span class="expiry-warn">${b.expiryDate}</span>
                                                    </c:when>
                                                    <c:otherwise>
                                                      <span class="expiry-ok">${b.expiryDate}</span>
                                                    </c:otherwise>
                                                  </c:choose>
                                                </td>
                                                <%-- Cột 3: Tồn kho với progress bar --%>
                                                <td>
                                                  <div class="qty-bar">
                                                    <strong class="${b.currentQuantity == 0 ? 'stock-out' : ''}">${b.currentQuantity}</strong>
                                                    <span style="font-size:11px;color:var(--muted)">/${b.initialQuantity}</span>
                                                    <div class="bar-bg">
                                                      <c:set var="pct" value="${b.initialQuantity > 0 ? b.currentQuantity * 100 / b.initialQuantity : 0}"/>
                                                      <div class="bar-fill ${pct < 20 ? 'low' : ''} ${pct == 0 ? 'out' : ''}" style="width:${pct}%"></div>
                                                    </div>
                                                  </div>
                                                </td>
                                                <%-- Cột 4: Trạng thái --%>
                                                <td>
                                                  <c:choose>
                                                    <c:when test="${isDestroyed}">
                                                      <span class="badge badge-red">Đã tiêu hủy</span>
                                                    </c:when>
                                                    <c:when test="${isExpired and b.currentQuantity > 0}">
                                                      <span class="badge badge-orange">⚠️ Hết hạn</span>
                                                    </c:when>
                                                    <c:when test="${isExpired}">
                                                      <span class="badge badge-gray">Hết hạn</span>
                                                    </c:when>
                                                    <c:when test="${b.currentQuantity == 0}">
                                                      <span class="badge badge-gray">Hết hàng</span>
                                                    </c:when>
                                                    <c:otherwise>
                                                      <span class="badge badge-green">Còn hàng</span>
                                                    </c:otherwise>
                                                  </c:choose>
                                                </td>
                                                <%-- Cột 5: Thao tác --%>
                                                <td>
                                                  <div style="display:flex;gap:5px;flex-wrap:wrap;align-items:center">
                                                    <%-- Sửa thông tin lô --%>
                                                    <c:if test="${not isDestroyed}">
                                                      <a href="${pageContext.request.contextPath}/medicines?action=edit-batch&id=${b.batchId}"
                                                         class="btn-sm btn-edit">✏️ Sửa</a>
                                                    </c:if>
                                                    <%-- Nhập thêm: chỉ cho lô ACTIVE chưa hết hạn --%>
                                                    <c:if test="${isActive and not isExpired}">
                                                      <button type="button" class="btn-sm btn-stock"
                                                              onclick="toggleAddStock(${b.batchId})">＋ Nhập thêm</button>
                                                    </c:if>
                                                    <%-- Tiêu hủy: ACTIVE, đã hết hạn, còn hàng --%>
                                                    <c:if test="${isActive and isExpired and b.currentQuantity > 0}">
                                                      <form method="post" action="${pageContext.request.contextPath}/medicines"
                                                            style="display:inline"
                                                            onsubmit="return confirm('Tiêu hủy lô ${b.batchNumber}?\nSL còn lại (${b.currentQuantity}) sẽ được ghi nhận đã hủy.')">
                                                        <input type="hidden" name="_csrf" value="${csrfToken}">
                                                        <input type="hidden" name="action" value="destroy-batch"/>
                                                        <input type="hidden" name="id" value="${b.batchId}"/>
                                                        <input type="hidden" name="medicineId" value="${medicine.medicineId}"/>
                                                        <button type="submit" class="btn-sm btn-destroy">🔥 Tiêu hủy</button>
                                                      </form>
                                                    </c:if>
                                                    <%-- Void nhập: ACTIVE, chưa bán gì, chưa hết hạn --%>
                                                    <c:if test="${isActive and not hasSales and not isExpired}">
                                                      <form method="post" action="${pageContext.request.contextPath}/medicines"
                                                            style="display:inline"
                                                            onsubmit="return confirm('Void lô ${b.batchNumber}?\nLô sẽ bị đánh dấu CANCELLED vì chưa có bán hàng.')">
                                                        <input type="hidden" name="_csrf" value="${csrfToken}">
                                                        <input type="hidden" name="action" value="delete-batch"/>
                                                        <input type="hidden" name="id" value="${b.batchId}"/>
                                                        <input type="hidden" name="medicineId" value="${medicine.medicineId}"/>
                                                        <button type="submit" class="btn-sm btn-void">✕ Void nhập</button>
                                                      </form>
                                                    </c:if>
                                                    <%-- Hoàn trả: ACTIVE, đã bán một phần, chưa hết hạn --%>
                                                    <c:if test="${isActive and hasSales and b.currentQuantity > 0 and not isExpired}">
                                                      <a href="${pageContext.request.contextPath}/returns?action=new&batchId=${b.batchId}"
                                                         class="btn-sm" style="background:#FFF7ED;color:#C2410C"
                                                         title="Thu hồi / hoàn trả lô này">↩️ Hoàn trả</a>
                                                    </c:if>
                                                  </div>
                                                  <%-- Inline add-stock form (ẩn, toggle bằng JS) --%>
                                                  <c:if test="${isActive and not isExpired}">
                                                  <div id="addstock-${b.batchId}" class="add-stock-row">
                                                    <form method="post" action="${pageContext.request.contextPath}/medicines"
                                                          class="add-stock-form">
                                                      <input type="hidden" name="_csrf" value="${csrfToken}">
                                                      <input type="hidden" name="action" value="add-stock"/>
                                                      <input type="hidden" name="batchId" value="${b.batchId}"/>
                                                      <input type="hidden" name="medicineId" value="${medicine.medicineId}"/>
                                                      <input type="number" name="qty" min="1" required
                                                             placeholder="SL" title="Số lượng nhập thêm"/>
                                                      <button type="submit" class="btn-confirm">✓ Xác nhận</button>
                                                      <button type="button" class="btn-x"
                                                              onclick="toggleAddStock(${b.batchId})">✗</button>
                                                    </form>
                                                  </div>
                                                  </c:if>
                                                </td>
                                              </tr>
                                            </c:forEach>
                                          </c:otherwise>
                                        </c:choose>
                                      </tbody>
                                    </table>
                                  </div>
                          </div>
                        </div>

                        <script>
                          const t = document.querySelector('.toast');
                          if (t) setTimeout(() => { t.style.opacity = '0'; t.style.transition = 'opacity .4s'; setTimeout(() => t.remove(), 400); }, 3000);

                          function toggleAddStock(batchId) {
                            const row = document.getElementById('addstock-' + batchId);
                            if (!row) return;
                            const visible = row.style.display === 'block';
                            // Ẩn tất cả form đang mở
                            document.querySelectorAll('.add-stock-row').forEach(r => r.style.display = 'none');
                            if (!visible) {
                              row.style.display = 'block';
                              const inp = row.querySelector('input[name="qty"]');
                              if (inp) { inp.value = ''; inp.focus(); }
                            }
                          }
                        </script>
          </body>

          </html>
