<%--
  ============================================================
  Ca làm việc section — nhúng vào staff-dashboard.jsp
  Thêm vào StaffDashboardServlet:
    req.setAttribute("currentShift", shiftDAO.findCurrent(staffAcc.getAccountId()));
  ============================================================
--%>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Dashboard Nhân viên — MediVault</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/assets/css/style.css">
    <style>
        /* ── Shift widget ── */
        .shift-widget {
            background: #fff;
            border: 1.5px solid #E8EDF5;
            border-radius: 16px;
            overflow: hidden;
            margin-bottom: 20px;
        }
        .shift-widget-header {
            padding: 16px 20px;
            border-bottom: 1px solid #F1F5F9;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .shift-widget-header h3 {
            margin: 0;
            font-size: 15px;
            font-weight: 800;
            color: #0B1628;
            display: flex;
            align-items: center;
            gap: 8px;
        }

        /* Active shift card */
        .shift-active {
            background: linear-gradient(135deg, #ECFDF5, #F0FFF4);
            border: 1.5px solid #A7F3D0;
            border-radius: 12px;
            margin: 16px;
            padding: 18px 20px;
        }
        .shift-active-top {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 14px;
            flex-wrap: wrap;
            gap: 8px;
        }
        .shift-live-badge {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            background: #D1FAE5;
            color: #065F46;
            border-radius: 20px;
            padding: 4px 12px;
            font-size: 12px;
            font-weight: 800;
        }
        .dot-live {
            width: 8px; height: 8px; border-radius: 50%;
            background: #10B981;
            animation: pulse 1.4s infinite;
        }
        @keyframes pulse { 0%,100%{opacity:1} 50%{opacity:.3} }

        .shift-timer {
            font-size: 28px;
            font-weight: 900;
            color: #059669;
            font-variant-numeric: tabular-nums;
            letter-spacing: -1px;
        }
        .shift-timer-label {
            font-size: 11px;
            color: #6EE7B7;
            font-weight: 700;
            text-transform: uppercase;
            letter-spacing: .5px;
            margin-top: 2px;
        }

        .shift-meta {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
            margin-top: 14px;
        }
        .shift-meta-item {
            background: rgba(255,255,255,.7);
            border-radius: 8px;
            padding: 9px 12px;
        }
        .shift-meta-label {
            font-size: 10px;
            font-weight: 800;
            color: #6EE7B7;
            text-transform: uppercase;
            letter-spacing: .5px;
        }
        .shift-meta-val {
            font-size: 13px;
            font-weight: 700;
            color: #065F46;
            margin-top: 3px;
        }

        /* Close shift form */
        .shift-close-form {
            padding: 16px 20px;
            border-top: 1px solid #D1FAE5;
            background: rgba(236,253,245,.5);
        }
        .shift-close-form h4 {
            font-size: 13px;
            font-weight: 800;
            color: #065F46;
            margin: 0 0 12px;
        }
        .shift-close-row {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            align-items: flex-end;
        }
        .shift-close-row .fg {
            display: flex;
            flex-direction: column;
            gap: 5px;
            flex: 1;
            min-width: 140px;
        }
        .shift-close-row label {
            font-size: 11px;
            font-weight: 700;
            color: #059669;
            text-transform: uppercase;
            letter-spacing: .5px;
        }
        .shift-close-row input,
        .shift-close-row textarea {
            border: 1.5px solid #A7F3D0;
            border-radius: 8px;
            padding: 8px 12px;
            font-size: 13px;
            background: #fff;
        }
        .shift-close-row input:focus,
        .shift-close-row textarea:focus {
            outline: none;
            border-color: #059669;
        }
        .btn-close-shift {
            background: linear-gradient(135deg, #059669, #047857);
            color: #fff;
            border: none;
            border-radius: 8px;
            padding: 9px 20px;
            font-size: 13px;
            font-weight: 800;
            cursor: pointer;
            align-self: flex-end;
            white-space: nowrap;
        }
        .btn-close-shift:hover { opacity: .9; }

        /* No shift state */
        .shift-empty {
            padding: 30px 20px;
            text-align: center;
            color: #94A3B8;
        }
        .shift-empty .icon { font-size: 36px; margin-bottom: 10px; }
        .shift-empty p { font-size: 13px; margin: 0; }

        /* Open shift form */
        .shift-open-form {
            padding: 16px 20px;
            border-top: 1px solid #F1F5F9;
        }
        .shift-open-form h4 {
            font-size: 13px;
            font-weight: 800;
            color: #1558A8;
            margin: 0 0 12px;
        }
        .shift-open-row {
            display: flex;
            gap: 10px;
            align-items: flex-end;
            flex-wrap: wrap;
        }
        .shift-open-row .fg {
            display: flex;
            flex-direction: column;
            gap: 5px;
        }
        .shift-open-row label {
            font-size: 11px;
            font-weight: 700;
            color: #64748B;
            text-transform: uppercase;
            letter-spacing: .5px;
        }
        .shift-open-row input {
            border: 1.5px solid #BFDBFE;
            border-radius: 8px;
            padding: 8px 12px;
            font-size: 13px;
            min-width: 150px;
        }
        .btn-open-shift {
            background: linear-gradient(135deg, #1558A8, #0D3F85);
            color: #fff;
            border: none;
            border-radius: 8px;
            padding: 9px 20px;
            font-size: 13px;
            font-weight: 800;
            cursor: pointer;
        }
        .btn-open-shift:hover { opacity: .9; }

        /* History list */
        .shift-history {
            padding: 0 20px 16px;
        }
        .shift-history-title {
            font-size: 12px;
            font-weight: 800;
            color: #94A3B8;
            text-transform: uppercase;
            letter-spacing: .5px;
            margin: 14px 0 10px;
        }
        .shift-history-item {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 9px 12px;
            background: #F8FAFC;
            border-radius: 8px;
            margin-bottom: 6px;
            font-size: 12px;
        }
        .shift-history-item .hi-date { color: #475569; font-weight: 600; }
        .shift-history-item .hi-dur  { color: #64748B; }
        .shift-history-item .hi-cash { color: #059669; font-weight: 700; }
    </style>
</head>
<body>

<%-- ── Include sidebar/navbar ── --%>
<%@ include file="/WEB-INF/views/staff/components/staff-navbar.jsp" %>

<div class="main-content">

    <%-- ── Ca làm việc widget ── --%>
    <div class="shift-widget">
        <div class="shift-widget-header">
            <h3>🕐 Ca làm việc</h3>
            <c:if test="${not empty currentShift}">
                <span style="font-size:12px;color:#059669;font-weight:700">
                    Ca #${currentShift.shiftId}
                </span>
            </c:if>
        </div>

        <c:choose>
            <%-- ── CA ĐANG MỞ ── --%>
            <c:when test="${not empty currentShift}">
                <div class="shift-active">
                    <div class="shift-active-top">
                        <span class="shift-live-badge">
                            <span class="dot-live"></span> Đang làm việc
                        </span>
                        <div style="text-align:right">
                            <div class="shift-timer" id="shiftTimer">00:00:00</div>
                            <div class="shift-timer-label">Thời gian làm việc</div>
                        </div>
                    </div>

                    <div class="shift-meta">
                        <div class="shift-meta-item">
                            <div class="shift-meta-label">Bắt đầu</div>
                            <div class="shift-meta-val">
                                <fmt:formatDate value="${currentShift.startTime}"
                                               pattern="HH:mm" type="both"/>
                                <span style="font-size:11px;opacity:.7">
                                    <fmt:formatDate value="${currentShift.startTime}"
                                                   pattern=" dd/MM" type="date"/>
                                </span>
                            </div>
                        </div>
                        <div class="shift-meta-item">
                            <div class="shift-meta-label">Tiền đầu ca</div>
                            <div class="shift-meta-val">
                                <c:if test="${not empty currentShift.openingCash}">
                                    <fmt:formatNumber value="${currentShift.openingCash}"
                                                     type="number" maxFractionDigits="0"/>đ
                                </c:if>
                                <c:if test="${empty currentShift.openingCash}">0đ</c:if>
                            </div>
                        </div>
                    </div>
                </div>

                <%-- Đóng ca form --%>
                <div class="shift-close-form">
                    <h4>📤 Kết thúc ca làm việc</h4>
                    <form method="post"
                          action="${pageContext.request.contextPath}/staff-shift">
                        <input type="hidden" name="action"  value="close">
                        <input type="hidden" name="shiftId" value="${currentShift.shiftId}">
                        <input type="hidden" name="uid"     value="${staffUid}">
                        <div class="shift-close-row">
                            <div class="fg">
                                <label>Tiền cuối ca (VNĐ)</label>
                                <input type="number" name="closingCash"
                                       min="0" step="1000" placeholder="0">
                            </div>
                            <div class="fg" style="flex:2">
                                <label>Ghi chú bàn giao</label>
                                <input type="text" name="notes"
                                       placeholder="Ghi chú ca làm việc...">
                            </div>
                            <button type="submit" class="btn-close-shift"
                                    onclick="return confirm('Kết thúc ca làm việc?')">
                                ✅ Kết thúc ca
                            </button>
                        </div>
                    </form>
                </div>
            </c:when>

            <%-- ── CHƯA CÓ CA ── --%>
            <c:otherwise>
                <div class="shift-empty">
                    <div class="icon">🌙</div>
                    <p>Bạn chưa có ca làm việc đang mở.<br>
                       Bắt đầu ca mới để ghi nhận thời gian làm việc.</p>
                </div>

                <div class="shift-open-form">
                    <h4>🚀 Bắt đầu ca mới</h4>
                    <form method="post"
                          action="${pageContext.request.contextPath}/staff-shift">
                        <input type="hidden" name="action" value="open">
                        <input type="hidden" name="uid"    value="${staffUid}">
                        <div class="shift-open-row">
                            <div class="fg">
                                <label>Tiền đầu ca (VNĐ)</label>
                                <input type="number" name="openingCash"
                                       min="0" step="1000" value="0" placeholder="0">
                            </div>
                            <button type="submit" class="btn-open-shift">
                                🟢 Bắt đầu ca
                            </button>
                        </div>
                    </form>
                </div>
            </c:otherwise>
        </c:choose>

        <%-- Lịch sử ca gần nhất --%>
        <c:if test="${not empty recentShifts}">
            <div class="shift-history">
                <div class="shift-history-title">Lịch sử ca gần nhất</div>
                <c:forEach var="s" items="${recentShifts}" end="2">
                    <div class="shift-history-item">
                        <span class="hi-date">
                            <fmt:formatDate value="${s.startTime}" pattern="dd/MM HH:mm" type="both"/>
                            →
                            <c:choose>
                                <c:when test="${not empty s.endTime}">
                                    <fmt:formatDate value="${s.endTime}" pattern="HH:mm" type="both"/>
                                </c:when>
                                <c:otherwise>—</c:otherwise>
                            </c:choose>
                        </span>
                        <span class="hi-cash">
                            <c:if test="${not empty s.closingCash}">
                                <fmt:formatNumber value="${s.closingCash}" type="number" maxFractionDigits="0"/>đ
                            </c:if>
                        </span>
                    </div>
                </c:forEach>
            </div>
        </c:if>
    </div>

    <%-- ── Phần còn lại của dashboard (thống kê, log...) ── --%>
    <%-- ... --%>

</div>

<script>
// ── Đếm giờ ca đang mở ──
<c:if test="${not empty currentShift}">
const shiftStart = new Date("${currentShift.startTime}".replace('T', ' '));
const timerEl    = document.getElementById('shiftTimer');

function updateTimer() {
    if (!timerEl) return;
    const diff = Math.floor((new Date() - shiftStart) / 1000);
    if (diff < 0) { timerEl.textContent = '00:00:00'; return; }
    const h = String(Math.floor(diff / 3600)).padStart(2, '0');
    const m = String(Math.floor((diff % 3600) / 60)).padStart(2, '0');
    const s = String(diff % 60).padStart(2, '0');
    timerEl.textContent = h + ':' + m + ':' + s;
}
updateTimer();
setInterval(updateTimer, 1000);
</c:if>
</script>

</body>
</html>
