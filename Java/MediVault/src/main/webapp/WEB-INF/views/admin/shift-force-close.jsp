<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Xác nhận đóng ca — MediVault</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/style.css">
    <style>
        .fc-wrap { max-width: 520px; margin: 60px auto; padding: 0 16px; }

        .fc-card {
            background: #fff;
            border: 1px solid #FED7AA;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 4px 24px rgba(245,158,11,.1);
        }
        .fc-header {
            background: linear-gradient(135deg, #F59E0B, #D97706);
            color: #fff;
            padding: 22px 28px;
        }
        .fc-header h2 { margin: 0; font-size: 18px; font-weight: 800; }
        .fc-header p  { margin: 6px 0 0; opacity: .85; font-size: 13px; }

        .fc-body { padding: 24px 28px; }

        .fc-staff-block {
            background: #FFFBEB;
            border: 1px solid #FDE68A;
            border-radius: 10px;
            padding: 14px 16px;
            display: flex; align-items: center; gap: 12px;
            margin-bottom: 20px;
        }
        .fc-avatar {
            width: 40px; height: 40px; border-radius: 50%;
            background: linear-gradient(135deg, #F59E0B, #D97706);
            color: #fff; font-weight: 900; font-size: 16px;
            display: flex; align-items: center; justify-content: center;
        }
        .fc-staff-name { font-size: 14px; font-weight: 800; color: #78350F; }
        .fc-staff-sub  { font-size: 12px; color: #92400E; margin-top: 2px; }

        .fc-info { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 20px; }
        .fc-info-item { background: #F8FAFC; border-radius: 8px; padding: 10px 14px; }
        .fc-info-label { font-size: 11px; color: #94A3B8; font-weight: 700; text-transform: uppercase; letter-spacing: .5px; }
        .fc-info-val   { font-size: 13px; color: #0B1628; font-weight: 700; margin-top: 4px; }

        .fc-notes label {
            font-size: 12px; font-weight: 800; color: #64748B;
            text-transform: uppercase; letter-spacing: .5px;
            display: block; margin-bottom: 7px;
        }
        .fc-notes textarea {
            width: 100%; border: 1.5px solid #E2E8F0;
            border-radius: 8px; padding: 10px 12px;
            font-size: 13px; color: #0B1628;
            resize: vertical; min-height: 80px;
            box-sizing: border-box;
        }
        .fc-notes textarea:focus { outline: none; border-color: #F59E0B; }

        .fc-actions { display: flex; gap: 10px; margin-top: 20px; }
        .btn-confirm {
            flex: 1;
            background: linear-gradient(135deg, #F59E0B, #D97706);
            color: #fff; border: none; border-radius: 10px;
            padding: 11px; font-size: 14px; font-weight: 800;
            cursor: pointer;
        }
        .btn-confirm:hover { opacity: .9; }
        .btn-cancel {
            background: #F1F5F9; color: #475569;
            border: none; border-radius: 10px;
            padding: 11px 20px; font-size: 14px; font-weight: 700;
            cursor: pointer; text-decoration: none;
            display: flex; align-items: center;
        }
        .btn-cancel:hover { background: #E2E8F0; }

        .warn-box {
            background: #FEF3C7;
            border: 1px solid #FDE68A;
            border-radius: 8px;
            padding: 12px 14px;
            font-size: 12.5px;
            color: #78350F;
            margin-bottom: 20px;
            line-height: 1.6;
        }
    </style>
</head>
<body>
<%@ include file="/WEB-INF/views/admin/components/sidebar.jsp" %>

<div class="main-content">
    <div class="fc-wrap">
        <div class="fc-card">
            <div class="fc-header">
                <h2>🔒 Xác nhận đóng ca</h2>
                <p>Thao tác này sẽ kết thúc ca làm việc ngay lập tức.</p>
            </div>

            <div class="fc-body">
                <%-- Warn --%>
                <div class="warn-box">
                    ⚠️ <strong>Lưu ý:</strong> Đóng ca sẽ ghi nhận thời gian kết thúc ngay lúc này.
                    Hành động này được ghi vào nhật ký hệ thống.
                </div>

                <%-- Staff info --%>
                <c:if test="${not empty staff}">
                    <div class="fc-staff-block">
                        <div class="fc-avatar">${fn:substring(staff.fullName,0,1)}</div>
                        <div>
                            <div class="fc-staff-name">${staff.fullName}</div>
                            <div class="fc-staff-sub">
                                @${staff.username} —
                                ${staff.roleId == 2 ? 'Dược sĩ bán hàng' : 'Thủ kho'}
                            </div>
                        </div>
                    </div>
                </c:if>

                <%-- Shift info --%>
                <div class="fc-info">
                    <div class="fc-info-item">
                        <div class="fc-info-label">Mã ca</div>
                        <div class="fc-info-val">#${shift.shiftId}</div>
                    </div>
                    <div class="fc-info-item">
                        <div class="fc-info-label">Bắt đầu lúc</div>
                        <div class="fc-info-val">
                            <fmt:formatDate value="${shift.startTime}" pattern="HH:mm dd/MM" type="both"/>
                        </div>
                    </div>
                    <div class="fc-info-item">
                        <div class="fc-info-label">Thời lượng</div>
                        <div class="fc-info-val" id="fcDuration"
                             data-start="${shift.startTime}">Đang tính...</div>
                    </div>
                    <div class="fc-info-item">
                        <div class="fc-info-label">Tiền đầu ca</div>
                        <div class="fc-info-val">
                            <fmt:formatNumber value="${shift.openingCash}" type="number" maxFractionDigits="0"/>đ
                        </div>
                    </div>
                </div>

                <%-- Form --%>
                <form method="post" action="${pageContext.request.contextPath}/shifts">
                    <input type="hidden" name="action"  value="force-close">
                    <input type="hidden" name="shiftId" value="${shift.shiftId}">

                    <div class="fc-notes">
                        <label>Ghi chú đóng ca (tùy chọn)</label>
                        <textarea name="notes"
                                  placeholder="Lý do admin đóng ca, ghi chú bàn giao..."></textarea>
                    </div>

                    <div class="fc-actions">
                        <a href="${pageContext.request.contextPath}/shifts" class="btn-cancel">Hủy</a>
                        <button type="submit" class="btn-confirm">🔒 Xác nhận đóng ca</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>

<script>
function calcDuration(startStr) {
    if (!startStr) return '—';
    const start = new Date(startStr.replace('T', ' '));
    const diff = Math.floor((new Date() - start) / 60000);
    if (isNaN(diff) || diff < 0) return '—';
    const h = Math.floor(diff / 60), m = diff % 60;
    return h > 0 ? `${h} giờ ${m} phút` : `${m} phút`;
}
const el = document.getElementById('fcDuration');
if (el && el.dataset.start) {
    el.textContent = calcDuration(el.dataset.start);
    setInterval(() => { el.textContent = calcDuration(el.dataset.start); }, 30000);
}
</script>
</body>
</html>
