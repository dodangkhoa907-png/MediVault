<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Quản lý Ca làm việc — MediVault</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/style.css">
    <style>
        /* ── Shift module tokens ── */
        :root {
            --shift-open-bg:    #ECFDF5;
            --shift-open-text:  #065F46;
            --shift-open-dot:   #10B981;
            --shift-closed-bg:  #F1F5F9;
            --shift-closed-text:#475569;
            --shift-closed-dot: #94A3B8;
            --card-radius: 14px;
        }

        /* ── Page header ── */
        .shift-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 12px;
            margin-bottom: 24px;
        }
        .shift-header h1 {
            font-size: 22px;
            font-weight: 800;
            color: #0B1628;
            display: flex;
            align-items: center;
            gap: 10px;
        }

        /* ── Stat cards ── */
        .shift-stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 14px;
            margin-bottom: 24px;
        }
        .stat-card {
            background: #fff;
            border-radius: var(--card-radius);
            padding: 18px 20px;
            border: 1px solid #E8EDF5;
            display: flex;
            align-items: center;
            gap: 14px;
        }
        .stat-icon {
            width: 44px; height: 44px;
            border-radius: 10px;
            display: flex; align-items: center; justify-content: center;
            font-size: 20px;
            flex-shrink: 0;
        }
        .stat-icon.blue   { background: #EFF6FF; }
        .stat-icon.green  { background: #ECFDF5; }
        .stat-icon.amber  { background: #FFFBEB; }
        .stat-label { font-size: 12px; color: #7A90B0; font-weight: 600; text-transform: uppercase; letter-spacing: .5px; }
        .stat-value { font-size: 26px; font-weight: 900; color: #0B1628; line-height: 1.1; }

        /* ── Filter bar ── */
        .filter-bar {
            background: #fff;
            border: 1px solid #E8EDF5;
            border-radius: var(--card-radius);
            padding: 16px 20px;
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            align-items: flex-end;
            margin-bottom: 20px;
        }
        .filter-bar .fg { display: flex; flex-direction: column; gap: 5px; }
        .filter-bar label { font-size: 12px; font-weight: 700; color: #7A90B0; text-transform: uppercase; letter-spacing: .5px; }
        .filter-bar input,
        .filter-bar select {
            border: 1.5px solid #E2E8F0;
            border-radius: 8px;
            padding: 7px 12px;
            font-size: 13px;
            color: #0B1628;
            background: #F8FAFC;
            min-width: 140px;
        }
        .filter-bar input:focus,
        .filter-bar select:focus { outline: none; border-color: #1558A8; background: #fff; }
        .btn-filter {
            background: #1558A8;
            color: #fff;
            border: none;
            border-radius: 8px;
            padding: 8px 18px;
            font-size: 13px;
            font-weight: 700;
            cursor: pointer;
            align-self: flex-end;
        }
        .btn-filter:hover { background: #0D3F85; }
        .btn-reset {
            background: #F1F5F9;
            color: #475569;
            border: none;
            border-radius: 8px;
            padding: 8px 14px;
            font-size: 13px;
            cursor: pointer;
            align-self: flex-end;
        }

        /* ── Open shift quick form ── */
        .open-shift-panel {
            background: linear-gradient(135deg, #EFF6FF, #F0FDF4);
            border: 1.5px solid #BFDBFE;
            border-radius: var(--card-radius);
            padding: 18px 22px;
            margin-bottom: 20px;
        }
        .open-shift-panel h3 {
            font-size: 14px; font-weight: 800; color: #1558A8; margin: 0 0 14px;
            display: flex; align-items: center; gap: 8px;
        }
        .open-shift-form {
            display: flex;
            flex-wrap: wrap;
            gap: 12px;
            align-items: flex-end;
        }
        .open-shift-form .fg { display: flex; flex-direction: column; gap: 5px; }
        .open-shift-form label { font-size: 12px; font-weight: 700; color: #64748B; }
        .open-shift-form select,
        .open-shift-form input {
            border: 1.5px solid #BFDBFE;
            border-radius: 8px;
            padding: 8px 12px;
            font-size: 13px;
            min-width: 160px;
            background: #fff;
        }
        .btn-open-shift {
            background: linear-gradient(135deg, #10B981, #059669);
            color: #fff;
            border: none;
            border-radius: 8px;
            padding: 9px 20px;
            font-size: 13px;
            font-weight: 700;
            cursor: pointer;
            align-self: flex-end;
        }
        .btn-open-shift:hover { background: #047857; }

        /* ── Table ── */
        .shift-table-wrap {
            background: #fff;
            border: 1px solid #E8EDF5;
            border-radius: var(--card-radius);
            overflow: hidden;
        }
        .shift-table-wrap table {
            width: 100%;
            border-collapse: collapse;
        }
        .shift-table-wrap thead th {
            background: #F8FAFC;
            padding: 12px 16px;
            text-align: left;
            font-size: 11px;
            font-weight: 800;
            color: #7A90B0;
            text-transform: uppercase;
            letter-spacing: .6px;
            border-bottom: 1px solid #E8EDF5;
        }
        .shift-table-wrap tbody td {
            padding: 13px 16px;
            font-size: 13px;
            color: #0B1628;
            border-bottom: 1px solid #F1F5F9;
            vertical-align: middle;
        }
        .shift-table-wrap tbody tr:last-child td { border-bottom: none; }
        .shift-table-wrap tbody tr:hover td { background: #F8FAFC; }

        /* ── Status badge ── */
        .badge-status {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 700;
        }
        .badge-open   { background: var(--shift-open-bg);   color: var(--shift-open-text);   }
        .badge-closed { background: var(--shift-closed-bg); color: var(--shift-closed-text); }
        .dot { width: 7px; height: 7px; border-radius: 50%; flex-shrink: 0; }
        .dot-open   { background: var(--shift-open-dot);   animation: pulse 1.5s infinite; }
        .dot-closed { background: var(--shift-closed-dot); }

        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50%       { opacity: .4; }
        }

        /* ── Staff avatar ── */
        .staff-cell { display: flex; align-items: center; gap: 9px; }
        .staff-avatar {
            width: 32px; height: 32px;
            border-radius: 50%;
            background: linear-gradient(135deg, #1558A8, #4F81D9);
            color: #fff;
            display: flex; align-items: center; justify-content: center;
            font-size: 13px; font-weight: 800;
            flex-shrink: 0;
        }
        .staff-name { font-weight: 700; color: #0B1628; font-size: 13px; }
        .staff-role { font-size: 11px; color: #7A90B0; }

        /* ── Duration ── */
        .duration-cell { font-variant-numeric: tabular-nums; }
        .duration-active { color: #059669; font-weight: 700; }

        /* ── Actions ── */
        .actions-cell { display: flex; gap: 6px; flex-wrap: nowrap; }
        .btn-sm {
            padding: 5px 12px;
            border-radius: 7px;
            font-size: 12px;
            font-weight: 700;
            border: none;
            cursor: pointer;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 5px;
            white-space: nowrap;
        }
        .btn-detail  { background: #EFF6FF; color: #1558A8; }
        .btn-detail:hover  { background: #DBEAFE; }
        .btn-force-close   { background: #FEF3C7; color: #92400E; }
        .btn-force-close:hover { background: #FDE68A; }
        .btn-delete  { background: #FEF2F2; color: #991B1B; }
        .btn-delete:hover  { background: #FECACA; }

        /* ── Toast ── */
        .toast {
            position: fixed;
            top: 22px; right: 22px;
            padding: 14px 20px;
            border-radius: 12px;
            font-size: 13px;
            font-weight: 700;
            color: #fff;
            z-index: 9999;
            box-shadow: 0 4px 20px rgba(0,0,0,.15);
            animation: slideIn .3s ease;
        }
        .toast.success { background: #059669; }
        .toast.error   { background: #DC2626; }
        .toast.info    { background: #1558A8; }
        @keyframes slideIn {
            from { transform: translateX(60px); opacity: 0; }
            to   { transform: translateX(0);    opacity: 1; }
        }

        /* ── Empty state ── */
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: #94A3B8;
        }
        .empty-state .empty-icon { font-size: 48px; margin-bottom: 12px; }
        .empty-state p { font-size: 14px; }

        /* ── Cash value ── */
        .cash-val { font-variant-numeric: tabular-nums; }
    </style>
</head>
<body>

<%-- ── Sidebar / Navbar (include theo cấu trúc dự án) ── --%>
<%@ include file="/WEB-INF/views/admin/components/sidebar.jsp" %>

<div class="main-content">

    <%-- ── Toast messages ── --%>
    <c:if test="${not empty param.msg}">
        <c:choose>
            <c:when test="${param.msg == 'opened'}">
                <div class="toast success" id="toast">✅ Mở ca thành công!</div>
            </c:when>
            <c:when test="${param.msg == 'closed'}">
                <div class="toast success" id="toast">✅ Đóng ca thành công!</div>
            </c:when>
            <c:when test="${param.msg == 'force-closed'}">
                <div class="toast info" id="toast">🔒 Admin đã đóng ca.</div>
            </c:when>
            <c:when test="${param.msg == 'deleted'}">
                <div class="toast success" id="toast">🗑️ Xóa ca thành công!</div>
            </c:when>
            <c:when test="${param.msg == 'delete-failed'}">
                <div class="toast error" id="toast">❌ Không thể xóa — ca đã có hóa đơn liên kết!</div>
            </c:when>
            <c:when test="${param.msg == 'already-open'}">
                <div class="toast error" id="toast">⚠️ Nhân viên đang có ca chưa đóng!</div>
            </c:when>
            <c:otherwise>
                <div class="toast error" id="toast">⚠️ Có lỗi xảy ra. Vui lòng thử lại.</div>
            </c:otherwise>
        </c:choose>
    </c:if>

    <%-- ── Header ── --%>
    <div class="shift-header">
        <h1>🕐 Quản lý Ca làm việc</h1>
        <span style="font-size:13px;color:#7A90B0">
            Tổng: <strong style="color:#0B1628">${totalCount}</strong> ca
            &nbsp;|&nbsp;
            Đang mở: <strong style="color:#059669">${openCount}</strong>
        </span>
    </div>

    <%-- ── Stat cards ── --%>
    <div class="shift-stats">
        <div class="stat-card">
            <div class="stat-icon blue">📋</div>
            <div>
                <div class="stat-label">Tổng ca</div>
                <div class="stat-value">${totalCount}</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon green">🟢</div>
            <div>
                <div class="stat-label">Đang mở</div>
                <div class="stat-value" style="color:#059669">${openCount}</div>
            </div>
        </div>
        <div class="stat-card">
            <div class="stat-icon amber">👥</div>
            <div>
                <div class="stat-label">Nhân viên</div>
                <div class="stat-value">${fn:length(allStaff)}</div>
            </div>
        </div>
    </div>

    <%-- ── Open shift panel (admin mở ca cho nhân viên) ── --%>
    <div class="open-shift-panel">
        <h3>➕ Mở ca mới cho nhân viên</h3>
        <form method="post" action="${pageContext.request.contextPath}/shifts"
              class="open-shift-form">
            <input type="hidden" name="action" value="open">
            <div class="fg">
                <label>Nhân viên</label>
                <select name="accountId" required>
                    <option value="">-- Chọn nhân viên --</option>
                    <c:forEach var="staff" items="${allStaff}">
                        <option value="${staff.accountId}">
                            ${staff.fullName}
                            (${staff.roleId == 2 ? 'Dược sĩ' : 'Thủ kho'})
                        </option>
                    </c:forEach>
                </select>
            </div>
            <div class="fg">
                <label>Tiền đầu ca (VNĐ)</label>
                <input type="number" name="openingCash" min="0" step="1000"
                       placeholder="0" value="0">
            </div>
            <button type="submit" class="btn-open-shift">🚀 Mở ca</button>
        </form>
    </div>

    <%-- ── Filter bar ── --%>
    <form method="get" action="${pageContext.request.contextPath}/shifts" class="filter-bar">
        <div class="fg">
            <label>Từ ngày</label>
            <input type="date" name="from" value="${filterFrom}">
        </div>
        <div class="fg">
            <label>Đến ngày</label>
            <input type="date" name="to" value="${filterTo}">
        </div>
        <div class="fg">
            <label>Nhân viên</label>
            <select name="accountId">
                <option value="">-- Tất cả --</option>
                <c:forEach var="staff" items="${allStaff}">
                    <option value="${staff.accountId}"
                        ${filterAcc == staff.accountId ? 'selected' : ''}>
                        ${staff.fullName}
                    </option>
                </c:forEach>
            </select>
        </div>
        <div class="fg">
            <label>Trạng thái</label>
            <select name="status">
                <option value="" ${empty filterStatus ? 'selected' : ''}>-- Tất cả --</option>
                <option value="open"   ${filterStatus == 'open'   ? 'selected' : ''}>🟢 Đang mở</option>
                <option value="closed" ${filterStatus == 'closed' ? 'selected' : ''}>⚫ Đã đóng</option>
            </select>
        </div>
        <button type="submit" class="btn-filter">🔍 Lọc</button>
        <a href="${pageContext.request.contextPath}/shifts" class="btn-reset">↺ Reset</a>
    </form>

    <%-- ── Table ── --%>
    <div class="shift-table-wrap">
        <c:choose>
            <c:when test="${empty shifts}">
                <div class="empty-state">
                    <div class="empty-icon">🕐</div>
                    <p>Không có ca làm việc nào phù hợp.</p>
                </div>
            </c:when>
            <c:otherwise>
                <table>
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Nhân viên</th>
                            <th>Bắt đầu</th>
                            <th>Kết thúc</th>
                            <th>Thời lượng</th>
                            <th>Tiền đầu ca</th>
                            <th>Tiền cuối ca</th>
                            <th>Trạng thái</th>
                            <th>Thao tác</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:forEach var="shift" items="${shifts}" varStatus="loop">
                            <c:set var="staff" value="${accountMap[shift.accountId]}"/>
                            <tr>
                                <td style="color:#94A3B8;font-size:12px">${shift.shiftId}</td>

                                <%-- Staff cell --%>
                                <td>
                                    <div class="staff-cell">
                                        <div class="staff-avatar">
                                            ${not empty staff ? fn:substring(staff.fullName,0,1) : '?'}
                                        </div>
                                        <div>
                                            <div class="staff-name">${not empty staff ? staff.fullName : 'ID '.concat(shift.accountId)}</div>
                                            <div class="staff-role">
                                                ${staff.roleId == 2 ? 'Dược sĩ bán hàng' : 'Thủ kho'}
                                            </div>
                                        </div>
                                    </div>
                                </td>

                                <%-- Start time --%>
                                <td>
                                    <c:if test="${not empty shift.startTime}">
                                        <fmt:formatDate value="${shift.startTime}" pattern="HH:mm" type="both"
                                                        dateStyle="short" timeStyle="short"/>
                                        <span style="display:block;font-size:11px;color:#94A3B8">
                                            <fmt:formatDate value="${shift.startTime}" pattern="dd/MM/yyyy" type="date"/>
                                        </span>
                                    </c:if>
                                </td>

                                <%-- End time --%>
                                <td>
                                    <c:choose>
                                        <c:when test="${not empty shift.endTime}">
                                            <fmt:formatDate value="${shift.endTime}" pattern="HH:mm" type="both"/>
                                            <span style="display:block;font-size:11px;color:#94A3B8">
                                                <fmt:formatDate value="${shift.endTime}" pattern="dd/MM/yyyy" type="date"/>
                                            </span>
                                        </c:when>
                                        <c:otherwise>
                                            <span style="color:#059669;font-size:12px;font-weight:700">Đang làm việc</span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>

                                <%-- Duration (computed in JSP) --%>
                                <td class="duration-cell">
                                    <c:choose>
                                        <c:when test="${not empty shift.endTime}">
                                            <%-- Tính bằng JS để không phức tạp trong JSTL --%>
                                            <span class="duration-text"
                                                  data-start="${shift.startTime}"
                                                  data-end="${shift.endTime}">—</span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="duration-text duration-active"
                                                  data-start="${shift.startTime}"
                                                  data-end="">
                                                Đang chạy
                                            </span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>

                                <%-- Cash --%>
                                <td class="cash-val">
                                    <c:if test="${not empty shift.openingCash}">
                                        <fmt:formatNumber value="${shift.openingCash}" type="number" maxFractionDigits="0"/>đ
                                    </c:if>
                                </td>
                                <td class="cash-val">
                                    <c:if test="${not empty shift.closingCash}">
                                        <fmt:formatNumber value="${shift.closingCash}" type="number" maxFractionDigits="0"/>đ
                                    </c:if>
                                    <c:if test="${empty shift.closingCash && empty shift.endTime}">
                                        <span style="color:#94A3B8;font-size:12px">—</span>
                                    </c:if>
                                </td>

                                <%-- Status badge --%>
                                <td>
                                    <c:choose>
                                        <c:when test="${empty shift.endTime}">
                                            <span class="badge-status badge-open">
                                                <span class="dot dot-open"></span> Đang mở
                                            </span>
                                        </c:when>
                                        <c:otherwise>
                                            <span class="badge-status badge-closed">
                                                <span class="dot dot-closed"></span> Đã đóng
                                            </span>
                                        </c:otherwise>
                                    </c:choose>
                                </td>

                                <%-- Actions --%>
                                <td>
                                    <div class="actions-cell">
                                        <a href="${pageContext.request.contextPath}/shifts?action=detail&id=${shift.shiftId}"
                                           class="btn-sm btn-detail">🔍 Chi tiết</a>

                                        <c:if test="${empty shift.endTime}">
                                            <a href="${pageContext.request.contextPath}/shifts?action=force-close&id=${shift.shiftId}"
                                               class="btn-sm btn-force-close">🔒 Đóng ca</a>
                                        </c:if>

                                        <c:if test="${not empty shift.endTime}">
                                            <a href="${pageContext.request.contextPath}/shifts?action=delete&id=${shift.shiftId}"
                                               class="btn-sm btn-delete"
                                               onclick="return confirm('Xóa ca này? Chỉ xóa được nếu không có hóa đơn liên kết.')">
                                                🗑️
                                            </a>
                                        </c:if>
                                    </div>
                                </td>
                            </tr>
                        </c:forEach>
                    </tbody>
                </table>
            </c:otherwise>
        </c:choose>
    </div>

</div><%-- /main-content --%>

<script>
// ── Auto-dismiss toast ──
const toast = document.getElementById('toast');
if (toast) setTimeout(() => toast.style.opacity = '0', 3500);

// ── Tính duration từ timestamp ──
function calcDuration(startStr, endStr) {
    if (!startStr) return '—';
    const start = new Date(startStr.replace('T', ' '));
    const end   = endStr ? new Date(endStr.replace('T', ' ')) : new Date();
    const diff  = Math.floor((end - start) / 60000); // phút
    if (isNaN(diff) || diff < 0) return '—';
    const h = Math.floor(diff / 60);
    const m = diff % 60;
    return h > 0 ? `${h}g ${m}p` : `${m} phút`;
}

document.querySelectorAll('.duration-text').forEach(el => {
    const start = el.dataset.start;
    const end   = el.dataset.end;
    if (start) {
        el.textContent = calcDuration(start, end || '');
    }
});

// ── Cập nhật duration ca đang mở mỗi phút ──
setInterval(() => {
    document.querySelectorAll('.duration-text.duration-active').forEach(el => {
        const start = el.dataset.start;
        if (start) el.textContent = calcDuration(start, '');
    });
}, 60000);
</script>

</body>
</html>
