<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<% String activeNav = "shifts"; %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();
    String msg = request.getParameter("msg");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <title>Xác nhận đóng ca — medicare</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">
    <style>

*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;--cyan-soft:#EBF8FD;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;--sidebar:232px;
}
html,body{height:100%;font-family:'Outfit',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar::after{content:'';position:absolute;top:0;right:0;bottom:0;width:1px;background:linear-gradient(180deg,transparent,rgba(58,189,224,.12) 30%,rgba(58,189,224,.12) 70%,transparent)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-icon{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;box-shadow:0 4px 16px rgba(58,189,224,.35)}
.logo-text{font-family:'Outfit',sans-serif;font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-text span{color:var(--cyan)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:12px 0 4px;flex-shrink:0}
.nav-label{font-size:9px;font-weight:700;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:500;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.14);font-weight:600}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--cyan);border-radius:2px}
.nav-icon{width:18px;text-align:center;font-size:14px;flex-shrink:0;opacity:.8}
.nav-item.active .nav-icon{opacity:1}
.nav-badge{margin-left:auto;background:#DC2626;color:#fff;font-size:10px;font-weight:700;padding:1px 7px;border-radius:20px;min-width:20px;text-align:center}
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06);flex-shrink:0}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08)}
.user-av{width:34px;height:34px;flex-shrink:0;border-radius:9px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.user-name{font-size:12.5px;font-weight:600;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:110px}
.user-role{font-size:10px;color:rgba(255,255,255,.35);margin-top:1px}
.logout-btn{margin-left:auto;width:28px;height:28px;flex-shrink:0;border-radius:8px;background:rgba(220,38,38,.12);border:none;display:flex;align-items:center;justify-content:center;color:rgba(220,38,38,.7);font-size:13px;cursor:pointer;text-decoration:none;transition:all .18s}
.logout-btn:hover{background:rgba(220,38,38,.2);color:#DC2626}
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0;overflow-x:hidden}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Outfit',sans-serif;font-size:16px;color:var(--ink)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px;flex-shrink:0}
.topbar-user{display:flex;align-items:center;gap:8px;padding:5px 12px 5px 7px;border:1.5px solid var(--border);border-radius:20px;text-decoration:none;color:inherit;transition:all .18s}
.topbar-user:hover{border-color:var(--cyan);background:var(--cyan-soft)}
.topbar-av{width:28px;height:28px;border-radius:8px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;color:#fff}
.topbar-name{font-size:13px;font-weight:600;color:var(--navy);max-width:110px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.content{padding:26px 28px;flex:1;min-width:0;overflow-x:auto}
.page-head{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:22px}
.breadcrumb{font-size:11.5px;color:var(--muted);font-weight:500;margin-bottom:4px}
.page-head h1{font-family:'Outfit',sans-serif;font-size:26px;color:var(--ink)}
.btn-primary{display:inline-flex;align-items:center;gap:7px;padding:10px 20px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;cursor:pointer;text-decoration:none;transition:all .22s;box-shadow:0 4px 14px rgba(21,88,168,.25)}
.btn-primary:hover{transform:translateY(-1px);box-shadow:0 6px 20px rgba(21,88,168,.35)}
.btn-trash{display:inline-flex;align-items:center;gap:6px;padding:9px 16px;background:#FEF2F2;border:1.5px solid #FECACA;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;color:var(--red);text-decoration:none;transition:all .18s}
.btn-trash:hover{background:#FEE2E2;border-color:#FCA5A5}
.stats-row{display:grid;grid-template-columns:repeat(4,1fr);gap:14px;margin-bottom:22px}
.stat-mini{background:var(--white);border:1px solid var(--border);border-radius:14px;padding:16px 18px;display:flex;align-items:center;gap:14px;transition:box-shadow .2s,transform .18s}
.stat-mini:hover{box-shadow:0 4px 16px rgba(21,88,168,.08);transform:translateY(-1px)}
.stat-mini-icon{width:42px;height:42px;border-radius:12px;display:flex;align-items:center;justify-content:center;font-size:18px;flex-shrink:0}
.ic-blue{background:rgba(58,189,224,.12)}.ic-green{background:rgba(5,150,105,.1)}.ic-red{background:rgba(220,38,38,.1)}.ic-gold{background:rgba(217,119,6,.12)}
.stat-mini-val{font-family:'Outfit',sans-serif;font-size:24px;color:var(--ink);line-height:1}
.stat-mini-lbl{font-size:11.5px;color:var(--muted);font-weight:500;margin-top:2px}
.card{background:var(--white);border:1px solid var(--border);border-radius:18px;overflow:hidden}
.card-head{padding:20px 24px 14px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between}
.card-title{font-family:'Outfit',sans-serif;font-size:18px;color:var(--ink)}
.card-sub{font-size:12.5px;color:var(--muted);margin-top:2px}
/* Filter */
.filter-bar{display:flex;gap:10px;align-items:center;padding:13px 22px;border-bottom:1px solid var(--border);background:var(--surface);flex-wrap:wrap}
.fsearch{flex:1;min-width:200px;max-width:300px;position:relative}
.fsearch input{width:100%;height:36px;padding:0 13px 0 36px;background:#fff;border:1.5px solid var(--border);border-radius:10px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);outline:none;transition:all .18s}
.fsearch input:focus{border-color:var(--cyan);box-shadow:0 0 0 3px rgba(58,189,224,.1)}
.fsearch::before{content:'🔍';position:absolute;left:12px;top:50%;transform:translateY(-50%);font-size:12px;pointer-events:none;opacity:.45}
.fselect{height:36px;padding:0 12px;background:#fff;border:1.5px solid var(--border);border-radius:10px;font-family:'Outfit',sans-serif;font-size:13px;color:var(--ink);outline:none;cursor:pointer;transition:all .18s}
.fselect:focus{border-color:var(--cyan)}
.fchip{height:36px;padding:0 14px;background:#fff;border:1.5px solid var(--border);border-radius:10px;font-family:'Outfit',sans-serif;font-size:12.5px;font-weight:600;color:var(--navy);cursor:pointer;transition:all .18s;white-space:nowrap}
.fchip:hover{border-color:var(--cyan);color:var(--blue)}
.fchip.clear{color:var(--muted)}.fchip.clear:hover{border-color:var(--red);color:var(--red)}
/* Table */
.tbl-wrap{overflow-x:auto}
.tbl{width:100%;border-collapse:collapse;font-size:13px}
.tbl th{padding:10px 16px;background:var(--surface);border-bottom:1px solid var(--border);font-size:10.5px;font-weight:700;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;white-space:nowrap}
.tbl td{padding:12px 16px;border-bottom:1px solid #F4F7FC;vertical-align:middle}
.tbl tbody tr{cursor:pointer;transition:background .12s}
.tbl tbody tr:hover{background:#F7FBFF}
.tbl tbody tr:last-child td{border-bottom:none}
.cell-user{display:flex;align-items:center;gap:10px}
.av{width:34px;height:34px;border-radius:9px;flex-shrink:0;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff;overflow:hidden}
.cell-name{font-size:13.5px;font-weight:600;color:var(--ink)}
.cell-sub{font-size:11.5px;color:var(--muted);margin-top:1px}
/* Badges */
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:600;white-space:nowrap}
.b-green{background:rgba(5,150,105,.1);color:var(--green)}
.b-red{background:rgba(220,38,38,.1);color:var(--red)}
.b-blue{background:rgba(21,88,168,.1);color:var(--blue)}
.b-gold{background:rgba(217,119,6,.1);color:var(--gold)}
.b-gray{background:#F1F5F9;color:#64748B}
/* Row actions */
.act-group{display:flex;gap:6px}
.act-btn{padding:5px 10px;border-radius:7px;font-size:12px;font-weight:600;text-decoration:none;cursor:pointer;border:none;font-family:'Outfit',sans-serif;transition:all .15s;white-space:nowrap}
.act-view{background:rgba(21,88,168,.08);color:var(--blue)}.act-view:hover{background:rgba(21,88,168,.16)}
.act-del{background:rgba(220,38,38,.08);color:var(--red)}.act-del:hover{background:rgba(220,38,38,.16)}
/* Pagination */
.pagination{display:flex;align-items:center;justify-content:space-between;padding:14px 24px;border-top:1px solid var(--border)}
.pg-info{font-size:12.5px;color:var(--muted)}
.pg-btns{display:flex;gap:5px}
.pg-btn{width:32px;height:32px;border-radius:8px;display:inline-flex;align-items:center;justify-content:center;font-size:13px;font-weight:600;text-decoration:none;color:var(--navy);background:var(--surface);border:1.5px solid var(--border);transition:all .15s}
.pg-btn:hover{border-color:var(--cyan);color:var(--blue)}.pg-btn.on{background:var(--blue);border-color:var(--blue);color:#fff}.pg-btn.off{opacity:.4;pointer-events:none}
/* Empty */
.empty{padding:48px 24px;text-align:center;color:var(--muted)}.empty .ei{font-size:36px;margin-bottom:10px}
/* Toast */
.toast{position:fixed;top:20px;right:24px;padding:12px 20px;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;display:flex;align-items:center;gap:8px;box-shadow:0 8px 32px rgba(0,0,0,.2);z-index:999;transition:opacity .4s}
.toast-ok{background:#064e3b;color:#fff}.toast-warn{background:#92400E;color:#fff}
@keyframes fadeUp{from{opacity:0;transform:translateY(14px)}to{opacity:1;transform:translateY(0)}}
.stat-mini:nth-child(1){animation:fadeUp .3s .05s ease both}.stat-mini:nth-child(2){animation:fadeUp .3s .1s ease both}.stat-mini:nth-child(3){animation:fadeUp .3s .15s ease both}.stat-mini:nth-child(4){animation:fadeUp .3s .2s ease both}
.card{animation:fadeUp .35s .1s ease both}

/* ── Shift-specific styles ── */

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
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">
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
                            ${fn:substring(shift.startTime.toString(),11,16)} ${fn:substring(shift.startTime.toString(),8,10)}/${fn:substring(shift.startTime.toString(),5,7)}
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
    const start = new Date(startStr.replace(' ','T')+'Z');
    const diff = Math.floor((new Date() - start) / 60000);
    if (isNaN(diff) || diff < 0) return '—';
    const h = Math.floor(diff / 60), m = diff % 60;
    return h > 0 ? `${h} giờ ${m} phút` : `${m} phút`;
}
const el = document.getElementById('fcDuration');
if (el && el.dataset.start) {
    el.textContent = calcDuration(el.dataset.start);
    setInterval(() => { el.textContent = calcDuration(el.dataset.start); }, 30000);
}++++++
</script>
</body>
</html>
