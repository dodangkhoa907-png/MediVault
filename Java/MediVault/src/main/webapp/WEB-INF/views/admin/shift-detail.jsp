<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chi tiết Ca làm việc — MediVault</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/style.css">
    <style>
        .detail-wrap { max-width: 720px; margin: 0 auto; padding: 0 0 40px; }
        .back-btn {
            display: inline-flex; align-items: center; gap: 6px;
            color: #1558A8; font-size: 13px; font-weight: 700;
            text-decoration: none; margin-bottom: 20px;
        }
        .back-btn:hover { text-decoration: underline; }

        .shift-card {
            background: #fff;
            border: 1px solid #E8EDF5;
            border-radius: 16px;
            overflow: hidden;
            margin-bottom: 20px;
        }
        .shift-card-header {
            background: linear-gradient(135deg, #1558A8, #0D3F85);
            color: #fff;
            padding: 22px 26px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 12px;
        }
        .shift-card-header h2 { margin: 0; font-size: 18px; font-weight: 800; }
        .shift-card-header .sub { font-size: 12px; opacity: .75; margin-top: 4px; }

        .badge-open-lg {
            background: rgba(16,185,129,.25);
            color: #6EE7B7;
            border: 1.5px solid rgba(16,185,129,.4);
            border-radius: 20px;
            padding: 5px 14px;
            font-size: 12px;
            font-weight: 800;
            display: flex; align-items: center; gap: 6px;
        }
        .badge-closed-lg {
            background: rgba(255,255,255,.15);
            color: #E2E8F0;
            border: 1.5px solid rgba(255,255,255,.2);
            border-radius: 20px;
            padding: 5px 14px;
            font-size: 12px;
            font-weight: 800;
        }
        .dot-pulse { width: 8px; height: 8px; border-radius: 50%; background: #10B981; animation: pulse 1.5s infinite; }
        @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.3} }

        .info-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 0;
        }
        .info-item {
            padding: 16px 24px;
            border-bottom: 1px solid #F1F5F9;
            border-right: 1px solid #F1F5F9;
        }
        .info-item:nth-child(even) { border-right: none; }
        .info-item:nth-last-child(-n+2) { border-bottom: none; }
        .info-label {
            font-size: 11px; font-weight: 800;
            color: #94A3B8; text-transform: uppercase;
            letter-spacing: .6px; margin-bottom: 6px;
        }
        .info-value {
            font-size: 14px; font-weight: 700; color: #0B1628;
        }
        .info-value.cash {
            font-size: 16px; color: #059669;
        }
        .info-value.duration-display {
            font-size: 16px; color: #1558A8;
        }
        .info-value.muted { color: #94A3B8; font-weight: 400; }

        .staff-block {
            padding: 18px 24px;
            display: flex; align-items: center; gap: 14px;
            border-bottom: 1px solid #F1F5F9;
        }
        .staff-av-lg {
            width: 48px; height: 48px; border-radius: 50%;
            background: linear-gradient(135deg, #1558A8, #4F81D9);
            color: #fff; font-size: 18px; font-weight: 900;
            display: flex; align-items: center; justify-content: center;
        }
        .staff-av-name { font-size: 15px; font-weight: 800; color: #0B1628; }
        .staff-av-role { font-size: 12px; color: #7A90B0; margin-top: 2px; }
        .staff-av-email { font-size: 12px; color: #94A3B8; }

        .notes-block {
            padding: 16px 24px;
            background: #FAFBFD;
        }
        .notes-block .notes-label {
            font-size: 11px; font-weight: 800; color: #94A3B8;
            text-transform: uppercase; letter-spacing: .6px; margin-bottom: 8px;
        }
        .notes-block p { font-size: 13px; color: #475569; margin: 0; line-height: 1.6; }

        /* Actions */
        .action-bar {
            display: flex; gap: 10px; flex-wrap: wrap; margin-top: 20px;
        }
        .btn-action {
            padding: 10px 22px; border-radius: 10px;
            font-size: 13px; font-weight: 700;
            border: none; cursor: pointer; text-decoration: none;
            display: inline-flex; align-items: center; gap: 7px;
        }
        .btn-back    { background: #F1F5F9; color: #475569; }
        .btn-back:hover { background: #E2E8F0; }
        .btn-fc      { background: linear-gradient(135deg, #F59E0B, #D97706); color: #fff; }
        .btn-fc:hover { opacity: .9; }
        .btn-del     { background: linear-gradient(135deg, #EF4444, #DC2626); color: #fff; }
        .btn-del:hover { opacity: .9; }

        @media(max-width:600px) {
            .info-grid { grid-template-columns: 1fr; }
            .info-item { border-right: none !important; }
            .info-item:nth-last-child(-n+2) { border-bottom: 1px solid #F1F5F9; }
            .info-item:last-child { border-bottom: none; }
        }
    </style>
</head>
<body>
<%@ include file="/WEB-INF/views/admin/components/sidebar.jsp" %>

<div class="main-content">
    <div class="detail-wrap">
        <a href="${pageContext.request.contextPath}/shifts" class="back-btn">← Danh sách ca</a>

        <div class="shift-card">
            <%-- Header --%>
            <div class="shift-card-header">
                <div>
                    <h2>Ca làm việc #${shift.shiftId}</h2>
                    <div class="sub">
                        Bắt đầu:
                        <fmt:formatDate value="${shift.startTime}" pattern="HH:mm dd/MM/yyyy" type="both"/>
                    </div>
                </div>
                <c:choose>
                    <c:when test="${empty shift.endTime}">
                        <span class="badge-open-lg">
                            <span class="dot-pulse"></span> Đang mở
                        </span>
                    </c:when>
                    <c:otherwise>
                        <span class="badge-closed-lg">⚫ Đã đóng</span>
                    </c:otherwise>
                </c:choose>
            </div>

            <%-- Staff block --%>
            <c:if test="${not empty staff}">
                <div class="staff-block">
                    <div class="staff-av-lg">
                        ${fn:substring(staff.fullName,0,1)}
                    </div>
                    <div>
                        <div class="staff-av-name">${staff.fullName}</div>
                        <div class="staff-av-role">
                            ${staff.roleId == 2 ? '💊 Dược sĩ bán hàng' : '📦 Thủ kho'}
                        </div>
                        <div class="staff-av-email">${staff.email}</div>
                    </div>
                </div>
            </c:if>

            <%-- Info grid --%>
            <div class="info-grid">
                <div class="info-item">
                    <div class="info-label">Giờ bắt đầu</div>
                    <div class="info-value">
                        <fmt:formatDate value="${shift.startTime}" pattern="HH:mm" type="both"/>
                        <span style="font-size:12px;color:#94A3B8;font-weight:400;margin-left:4px">
                            <fmt:formatDate value="${shift.startTime}" pattern="dd/MM/yyyy" type="date"/>
                        </span>
                    </div>
                </div>
                <div class="info-item">
                    <div class="info-label">Giờ kết thúc</div>
                    <div class="info-value">
                        <c:choose>
                            <c:when test="${not empty shift.endTime}">
                                <fmt:formatDate value="${shift.endTime}" pattern="HH:mm" type="both"/>
                                <span style="font-size:12px;color:#94A3B8;font-weight:400;margin-left:4px">
                                    <fmt:formatDate value="${shift.endTime}" pattern="dd/MM/yyyy" type="date"/>
                                </span>
                            </c:when>
                            <c:otherwise>
                                <span style="color:#059669">Đang làm việc</span>
                            </c:otherwise>
                        </c:choose>
                    </div>
                </div>
                <div class="info-item">
                    <div class="info-label">Thời lượng</div>
                    <div class="info-value duration-display"
                         id="durationDisplay"
                         data-start="${shift.startTime}"
                         data-end="${shift.endTime}">
                        Đang tính...
                    </div>
                </div>
                <div class="info-item">
                    <div class="info-label">Grace Period</div>
                    <div class="info-value">${shift.gracePeriodMinutes} phút</div>
                </div>
                <div class="info-item">
                    <div class="info-label">💰 Tiền đầu ca</div>
                    <div class="info-value cash">
                        <c:if test="${not empty shift.openingCash}">
                            <fmt:formatNumber value="${shift.openingCash}" type="number" maxFractionDigits="0"/>đ
                        </c:if>
                        <c:if test="${empty shift.openingCash}">0đ</c:if>
                    </div>
                </div>
                <div class="info-item">
                    <div class="info-label">💰 Tiền cuối ca</div>
                    <div class="info-value cash">
                        <c:choose>
                            <c:when test="${not empty shift.closingCash}">
                                <fmt:formatNumber value="${shift.closingCash}" type="number" maxFractionDigits="0"/>đ
                            </c:when>
                            <c:otherwise>
                                <span class="muted">Chưa đóng ca</span>
                            </c:otherwise>
                        </c:choose>
                    </div>
                </div>
            </div>

            <%-- Notes --%>
            <c:if test="${not empty shift.notes}">
                <div class="notes-block">
                    <div class="notes-label">📝 Ghi chú</div>
                    <p>${shift.notes}</p>
                </div>
            </c:if>
        </div>

        <%-- Action bar --%>
        <div class="action-bar">
            <a href="${pageContext.request.contextPath}/shifts" class="btn-action btn-back">← Quay lại</a>

            <c:if test="${empty shift.endTime}">
                <a href="${pageContext.request.contextPath}/shifts?action=force-close&id=${shift.shiftId}"
                   class="btn-action btn-fc">🔒 Admin đóng ca này</a>
            </c:if>

            <c:if test="${not empty shift.endTime}">
                <a href="${pageContext.request.contextPath}/shifts?action=delete&id=${shift.shiftId}"
                   class="btn-action btn-del"
                   onclick="return confirm('Xóa ca này vĩnh viễn?\nChỉ xóa được nếu không có hóa đơn liên kết!')">
                    🗑️ Xóa ca
                </a>
            </c:if>
        </div>
    </div>
</div>

<script>
function calcDuration(startStr, endStr) {
    if (!startStr) return '—';
    const start = new Date(startStr.replace('T', ' '));
    const end   = endStr ? new Date(endStr.replace('T', ' ')) : new Date();
    const diff  = Math.floor((end - start) / 60000);
    if (isNaN(diff) || diff < 0) return '—';
    const h = Math.floor(diff / 60);
    const m = diff % 60;
    return h > 0 ? `${h} giờ ${m} phút` : `${m} phút`;
}

const el = document.getElementById('durationDisplay');
if (el) {
    el.textContent = calcDuration(el.dataset.start, el.dataset.end || '');
    // Cập nhật nếu ca đang mở
    if (!el.dataset.end) {
        setInterval(() => {
            el.textContent = calcDuration(el.dataset.start, '');
        }, 30000);
    }
}
</script>
</body>
</html>
