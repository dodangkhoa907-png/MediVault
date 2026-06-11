<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<% String activeNav = "shifts"; %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn"  uri="jakarta.tags.functions" %>
<%
    com.medivault.entity.Account acc = (com.medivault.entity.Account) session.getAttribute("adminAccount");
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
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Chi tiết Ca làm việc — MediVault</title>
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
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">
    <div class="detail-wrap">
        <a href="${pageContext.request.contextPath}/shifts" class="back-btn">← Danh sách ca</a>

        <div class="shift-card">
            <%-- Header --%>
            <div class="shift-card-header">
                <div>
                    <h2>Ca làm việc #${shift.shiftId}</h2>
                    <div class="sub">
                        Bắt đầu:
                        ${fn:substring(shift.startTime.toString(),11,16)} ${fn:substring(shift.startTime.toString(),8,10)}/${fn:substring(shift.startTime.toString(),5,7)}/${fn:substring(shift.startTime.toString(),0,4)}
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
                        ${fn:substring(shift.startTime.toString(),11,16)}<span style="font-size:12px;color:#94A3B8;font-weight:400;margin-left:4px">
                            ${fn:substring(shift.startTime.toString(),8,10)}/${fn:substring(shift.startTime.toString(),5,7)}/${fn:substring(shift.startTime.toString(),0,4)}
                        </span>
                    </div>
                </div>
                <div class="info-item">
                    <div class="info-label">Giờ kết thúc</div>
                    <div class="info-value">
                        <c:choose>
                            <c:when test="${not empty shift.endTime}">
                                ${fn:substring(shift.endTime.toString(),11,16)}<span style="font-size:12px;color:#94A3B8;font-weight:400;margin-left:4px">
                                    ${fn:substring(shift.endTime.toString(),8,10)}/${fn:substring(shift.endTime.toString(),5,7)}/${fn:substring(shift.endTime.toString(),0,4)}
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
    return h > 0 ? '${h} giờ ' + m + ' phút' : '' + m + ' phút';
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
