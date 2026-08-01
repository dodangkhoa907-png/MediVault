<%@ page contentType="text/html;charset=UTF-8" %>
<% String activeNav = "audit"; %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    int roleId = acc.getRoleId();
    java.lang.String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    java.lang.String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();

    Integer expiryCount     = (Integer) request.getAttribute("expiryCount");
    Integer pendingResetCount = (Integer) request.getAttribute("pendingResetCount");
    if (expiryCount      == null) expiryCount      = 0;
    if (pendingResetCount == null) pendingResetCount = 0;

    @SuppressWarnings("unchecked")
    java.util.List<com.medicare.entity.PasswordResetRequest> pendingResets =
        (java.util.List<com.medicare.entity.PasswordResetRequest>) request.getAttribute("pendingResets");
    @SuppressWarnings("unchecked")
    java.util.Map<Integer, com.medicare.entity.Account> resetAccountMap =
        (java.util.Map<Integer, com.medicare.entity.Account>) request.getAttribute("resetAccountMap");
    if (pendingResets   == null) pendingResets   = new java.util.ArrayList<>();
    if (resetAccountMap == null) resetAccountMap = new java.util.HashMap<>();

    @SuppressWarnings("unchecked")
    java.util.List<com.medicare.entity.AuditLog> auditLogs =
        (java.util.List<com.medicare.entity.AuditLog>) request.getAttribute("auditLogs");
    if (auditLogs == null) auditLogs = new java.util.ArrayList<>();

    Integer currentPage = (Integer) request.getAttribute("currentPage");
    Integer totalPages  = (Integer) request.getAttribute("totalPages");
    java.lang.String searchKeyword = (java.lang.String) request.getAttribute("searchKeyword");
    java.lang.String filterFrom = (java.lang.String) request.getAttribute("filterFrom");
    java.lang.String filterTo   = (java.lang.String) request.getAttribute("filterTo");
    if (currentPage  == null) currentPage  = 1;
    if (totalPages   == null) totalPages   = 1;
    if (searchKeyword == null) searchKeyword = "";
    if (filterFrom == null) filterFrom = "";
    if (filterTo   == null) filterTo   = "";
    java.lang.String pageQS = "&search=" + java.net.URLEncoder.encode(searchKeyword, java.nio.charset.StandardCharsets.UTF_8)
            + "&from=" + java.net.URLEncoder.encode(filterFrom, java.nio.charset.StandardCharsets.UTF_8)
            + "&to="   + java.net.URLEncoder.encode(filterTo, java.nio.charset.StandardCharsets.UTF_8);

    @SuppressWarnings("unchecked")
    java.util.Map<Integer,Integer> auditRoleMap =
        (java.util.Map<Integer,Integer>) request.getAttribute("auditRoleMap");
    if (auditRoleMap == null) auditRoleMap = new java.util.HashMap<>();
    @SuppressWarnings("unchecked")
    java.util.List<com.medicare.entity.Account> auditAccounts =
        (java.util.List<com.medicare.entity.Account>) request.getAttribute("auditAccounts");
    if (auditAccounts == null) auditAccounts = new java.util.ArrayList<>();
%>
<%!
    // Phân loại 1 dòng nhật ký thành nhóm hành động (dựa vào action + module)
    private String auditCat(String action, String entity) {
        String a = (action == null ? "" : action).toLowerCase();
        String e = (entity == null ? "" : entity).toLowerCase();
        if (e.contains("invoice") || a.contains("bán") || a.contains("hóa đơn") || a.contains("pos")) return "pos";
        if (e.contains("shift")   || a.contains("ca ")  || a.contains("lịch")   || a.contains("nghỉ")) return "shift";
        if (e.contains("attendance") || a.contains("điểm danh") || a.contains("check") || a.contains("chấm công")) return "attendance";
        if (e.contains("batch") || e.contains("purchaseorder") || e.contains("medicine") || a.contains("lô") || a.contains("nhập") || a.contains("thuốc")) return "inventory";
        if (e.contains("account") || e.contains("customer") || a.contains("tài khoản") || a.contains("khách") || a.contains("mật khẩu")) return "account";
        if (e.contains("auth") || a.contains("đăng nhập") || a.contains("đăng xuất")) return "auth";
        return "other";
    }
    private String catLabel(String c) {
        switch (c) {
            case "pos": return "🛒 Bán hàng";
            case "shift": return "📅 Ca làm việc";
            case "attendance": return "⏱️ Điểm danh";
            case "inventory": return "📦 Kho / Nhập lô";
            case "account": return "👤 Tài khoản";
            case "auth": return "🔑 Đăng nhập";
            default: return "⚙️ Khác";
        }
    }
    // Diễn giải IP dễ hiểu hơn — thay vì hiện thẳng "0:0:0:0:0:0:0:1" (IPv6 loopback) khó đọc,
    // gắn nhãn rõ đây là máy chủ hay thiết bị mạng nội bộ hay bên ngoài.
    private String ipLabel(String ip) {
        if (ip == null || ip.isEmpty()) return "—";
        String norm = ip.trim();
        if (norm.startsWith("::ffff:")) norm = norm.substring(7); // IPv4-mapped IPv6
        if (norm.equals("127.0.0.1") || norm.equals("::1") || norm.equals("0:0:0:0:0:0:0:1")
                || norm.equals("0:0:0:0:0:0:1")) {
            return "🖥️ Máy chủ (localhost) · " + ip;
        }
        boolean isLan = norm.matches("^192\\.168\\..*")
                || norm.matches("^10\\..*")
                || norm.matches("^172\\.(1[6-9]|2[0-9]|3[0-1])\\..*");
        if (isLan) return "🏠 Mạng nội bộ · " + ip;
        return "🌐 Bên ngoài · " + ip;
    }
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>medicare — Nhật ký hệ thống</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;--cyan-soft:#EBF8FD;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;--sidebar:232px;
}
html,body{height:100%;font-family:'Plus Jakarta Sans',sans-serif}
body{display:flex;background:var(--surface);color:var(--ink)}

/* SIDEBAR */
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-icon{width:36px;height:36px;border-radius:10px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:16px;flex-shrink:0;box-shadow:0 4px 16px rgba(58,189,224,.35)}
.logo-text{font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-text span{color:var(--cyan)}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:12px 0 4px;flex-shrink:0}
.nav-label{font-size:9px;font-weight:750;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:750;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.14);font-weight:750}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:var(--cyan);border-radius:2px}
.nav-icon{width:18px;text-align:center;font-size:14px;flex-shrink:0;opacity:.8}
.nav-item.active .nav-icon{opacity:1}
.nav-badge{margin-left:auto;background:#DC2626;color:#fff;font-size:10px;font-weight:750;padding:1px 7px;border-radius:20px;min-width:20px;text-align:center}
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06);flex-shrink:0}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08)}
.user-avatar-sm{width:34px;height:34px;flex-shrink:0;border-radius:9px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;color:#fff}
.user-info-sm .name{font-size:12.5px;font-weight:750;color:#fff;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:110px}
.user-info-sm .role{font-size:10px;color:rgba(255,255,255,.35);margin-top:1px}
.logout-btn{margin-left:auto;width:28px;height:28px;flex-shrink:0;border-radius:8px;background:rgba(220,38,38,.12);border:none;display:flex;align-items:center;justify-content:center;color:rgba(220,38,38,.7);font-size:13px;cursor:pointer;text-decoration:none;transition:all .18s}
.logout-btn:hover{background:rgba(220,38,38,.2);color:#DC2626}

/* MAIN */
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0}

/* TOPBAR */
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Plus Jakarta Sans',sans-serif;font-size:16px;font-weight:750;color:var(--ink)}

    
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px;flex-shrink:0}
.topbar-clock{display:flex;align-items:center;gap:5px;padding:6px 13px;background:var(--surface);border:1.5px solid var(--border);border-radius:20px;font-size:13px;font-weight:750;color:var(--navy);font-variant-numeric:tabular-nums}
.clock-sep{animation:blink 1s step-end infinite}
@keyframes blink{0%,100%{opacity:1}50%{opacity:0}}
.clock-date{font-size:11px;font-weight:750;color:var(--muted);border-left:1px solid var(--border);padding-left:8px;margin-left:2px}
.notif-wrap{position:relative}
.topbar-icon-btn{width:34px;height:34px;border-radius:9px;background:var(--surface);border:1.5px solid var(--border);cursor:pointer;font-size:15px;display:flex;align-items:center;justify-content:center;position:relative;transition:all .18s}
.topbar-icon-btn:hover{border-color:var(--cyan);background:var(--cyan-soft)}
.topbar-notif-badge{position:absolute;top:-4px;right:-4px;background:#DC2626;color:#fff;font-size:9px;font-weight:800;padding:1px 4px;border-radius:10px;min-width:16px;text-align:center}
.notif-dropdown{position:absolute;top:calc(100% + 8px);right:0;width:300px;background:#fff;border:1px solid var(--border);border-radius:16px;box-shadow:0 12px 40px rgba(0,0,0,.12);opacity:0;visibility:hidden;transform:translateY(-8px);transition:all .2s;z-index:200;overflow:hidden}
.notif-dropdown.open{opacity:1;visibility:visible;transform:translateY(0)}
.notif-head{display:flex;align-items:center;justify-content:space-between;padding:14px 16px;border-bottom:1px solid var(--border)}
.notif-head-title{font-size:13px;font-weight:750;color:var(--ink)}
.notif-clear{background:none;border:none;cursor:pointer;font-size:12px;color:var(--muted);padding:0}
.notif-item{display:flex;align-items:flex-start;gap:10px;padding:12px 16px;border-bottom:1px solid #F8FAFC;transition:background .15s}
.notif-item:hover{background:var(--surface)}
.notif-dot{width:8px;height:8px;border-radius:50%;background:#DC2626;margin-top:4px;flex-shrink:0}
.notif-dot.old{background:var(--muted);opacity:.4}
.notif-text{font-size:12.5px;color:var(--ink);font-weight:750}
.notif-time{font-size:11px;color:var(--muted);margin-top:2px}
.topbar-user{display:flex;align-items:center;gap:8px;padding:5px 12px 5px 7px;border:1.5px solid var(--border);border-radius:20px;text-decoration:none;color:inherit;transition:all .18s}
.topbar-user:hover{border-color:var(--cyan);background:var(--cyan-soft)}
.topbar-user-avatar{width:28px;height:28px;border-radius:8px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;color:#fff}
.topbar-user-name{font-size:13px;font-weight:750;color:var(--navy);max-width:110px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}

/* CONTENT */
.content{padding:26px 28px;flex:1;min-width:0}
.page-head{display:flex;align-items:flex-end;justify-content:space-between;margin-bottom:22px}
.page-head-left .breadcrumb{font-size:11.5px;color:var(--muted);font-weight:750;margin-bottom:4px}
.page-head-left h1{font-family:'Plus Jakarta Sans',sans-serif;font-size:28px;color:var(--ink)}

/* Table card */
.table-card{background:#fff;border:1px solid rgba(213,224,240,.45);border-radius:16px;overflow:hidden;box-shadow:0 1px 3px rgba(15,38,69,.03),0 4px 12px rgba(15,38,69,.04)}
.table-card-header{padding:20px 24px 14px;border-bottom:1px solid rgba(213,224,240,.4);display:flex;align-items:center;justify-content:space-between}
.table-card-title{font-family:'Plus Jakarta Sans',sans-serif;font-size:18px;color:var(--ink)}
.table-card-subtitle{font-size:12.5px;color:var(--muted);margin-top:2px}

/* Filter */
.filter-row{display:flex;gap:10px;align-items:center;padding:14px 24px;border-bottom:1px solid var(--border);flex-wrap:wrap}
.filter-search{position:relative;flex:1;min-width:220px}
.filter-search input{width:100%;padding:8px 14px 8px 36px;background:var(--surface);border:1.5px solid var(--border);border-radius:10px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;color:var(--ink);outline:none;transition:all .18s}
.filter-search input:focus{border-color:var(--cyan);background:#fff}
.filter-search::before{content:'🔍';position:absolute;left:12px;top:50%;transform:translateY(-50%);font-size:12px;pointer-events:none;opacity:.45}
.filter-chip{padding:8px 14px;background:var(--surface);border:1.5px solid var(--border);border-radius:10px;font-size:12.5px;font-weight:750;color:var(--navy);cursor:pointer;text-decoration:none;transition:all .18s;white-space:nowrap}
.filter-chip:hover{border-color:var(--cyan);color:var(--blue)}
.btn-primary{display:inline-flex;align-items:center;gap:7px;padding:9px 18px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;border-radius:10px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;font-weight:750;cursor:pointer;text-decoration:none;transition:all .2s}
.btn-primary:hover{transform:translateY(-1px)}

/* Table */
.table-wrap{overflow-x:auto}
.data-table{width:100%;border-collapse:collapse;font-size:13px}
.data-table th{padding:10px 16px;background:var(--surface);border-bottom:1px solid var(--border);font-size:11px;font-weight:750;text-transform:uppercase;letter-spacing:.6px;color:var(--muted);text-align:left;white-space:nowrap}
.data-table td{padding:13px 16px;border-bottom:1px solid #F4F7FC;vertical-align:middle}
.data-table tbody tr:hover{background:#FAFCFF}
.data-table tbody tr:last-child td{border-bottom:none}

/* Badge */
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11.5px;font-weight:750}
.badge-green{background:rgba(5,150,105,.1);color:var(--green)}
.badge-red{background:rgba(220,38,38,.1);color:var(--red)}
.badge-blue{background:rgba(21,88,168,.1);color:var(--blue)}
.badge-gold{background:rgba(217,119,6,.1);color:var(--gold)}
.badge-gray{background:rgba(122,144,176,.1);color:var(--muted)}

/* Empty */
.empty-state{padding:48px 24px;text-align:center;color:var(--muted)}
.empty-state .icon{font-size:36px;margin-bottom:10px}
.empty-state p{font-size:13.5px}

/* Pagination */
.pagination{display:flex;align-items:center;justify-content:space-between;padding:14px 24px;border-top:1px solid var(--border)}
.pagination-info{font-size:12.5px;color:var(--muted)}
.pagination-btns{display:flex;gap:5px}
.page-btn{width:32px;height:32px;border-radius:8px;display:inline-flex;align-items:center;justify-content:center;font-size:13px;font-weight:750;text-decoration:none;color:var(--navy);background:var(--surface);border:1.5px solid var(--border);transition:all .15s}
.page-btn:hover{border-color:var(--cyan);color:var(--blue)}
.page-btn.active{background:var(--blue);border-color:var(--blue);color:#fff}
.page-btn.disabled{opacity:.4;pointer-events:none}

/* Log-specific */
.log-action{font-size:13px;font-weight:750;color:var(--ink)}
.log-desc{font-size:12px;color:var(--muted);margin-top:2px;max-width:320px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.log-time{font-size:12px;color:var(--muted);white-space:nowrap}
.log-ip{font-size:11.5px;color:var(--muted);font-family:monospace}
.log-id{font-size:11px;color:var(--muted);opacity:.6}
select,option{font-family:inherit;font-size:inherit}
.cdd{position:relative;user-select:none;display:inline-block}
.cdd-btn{display:flex;align-items:center;gap:6px;padding:9px 14px;background:var(--white,#fff);border:1.5px solid var(--border,#D5E0F0);border-radius:10px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;font-weight:750;color:var(--ink,#0B1628);cursor:pointer;transition:all .18s;white-space:nowrap}
.cdd-btn:hover{border-color:var(--cyan,#3ABDE0);background:var(--cyan-soft,#EBF8FD)}
.cdd-btn.open{border-color:var(--cyan,#3ABDE0);box-shadow:0 0 0 3px rgba(58,189,224,.12)}
.cdd-arrow{font-size:9px;color:var(--muted,#7A90B0);transition:transform .2s}
.cdd-btn.open .cdd-arrow{transform:rotate(180deg)}
.cdd-menu{position:absolute;top:calc(100% + 6px);left:0;min-width:100%;background:var(--white,#fff);border:1.5px solid var(--border,#D5E0F0);border-radius:12px;padding:6px;box-shadow:0 12px 36px rgba(15,38,69,.15);z-index:200;opacity:0;transform:translateY(-6px);pointer-events:none;transition:all .18s ease;max-height:260px;overflow-y:auto}
.cdd-menu.show{opacity:1;transform:translateY(0);pointer-events:auto}
.cdd-menu::-webkit-scrollbar{width:4px}
.cdd-menu::-webkit-scrollbar-thumb{background:var(--border,#D5E0F0);border-radius:4px}
.cdd-opt{padding:8px 14px;border-radius:8px;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;font-weight:600;color:var(--ink,#0B1628);cursor:pointer;transition:all .12s;white-space:nowrap}
.cdd-opt:hover{background:var(--surface,#F1F5FB);color:var(--blue,#1558A8)}
.cdd-opt.active{background:linear-gradient(135deg,var(--blue,#1558A8),#0D3F85);color:#fff;font-weight:750}
</style>
    <!-- Premium Lora & Plus Jakarta Sans Hybrid Typography by Senior UI/UX Dev -->
    <style>
        /* Body, table cells, inputs, buttons, chips, sidebar, clocks use Plus Jakarta Sans for high legibility */
        html, body, select, input, button, textarea, .nav-item, .notif-tab, .btn-primary, 
        .topbar-user-name, .user-info-sm, .logout-btn-full, .topbar-clock, 
        .table, th, td, .form-control, .card, .btn, .log-desc, .log-action, .log-time, .log-ip, .log-id, .badge, .empty-state p {
            font-family:'Plus Jakarta Sans',sans-serif"Segoe UI", Roboto, Helvetica, Arial, sans-serif !important;
        }
        /* Classic editorial Lora serif font for headings, brand logo, and titles (100% Vietnamese support) */
        h1, h2, h3, h4, h5, h6, .logo-text, .page-title, .section-title, .card-title, .table-card-title, .page-head-left h1, .topbar-title, .notif-head-title, .alert-text strong {
            font-family:'Lora',serif"Times New Roman", serif !important;
            font-weight:750 !important;
        }
        h1, .page-head-left h1 {
            letter-spacing: -0.01em !important;
            font-weight:750 !important;
        }
        .logo-text span {
            font-family:'Lora',serif !important;
            font-style: italic !important;
            font-weight:750 !important;
        }
        /* Aesthetic updates for soft inputs & buttons */
        input:focus, select:focus, textarea:focus {
            border-color: #3ABDE0 !important;
            box-shadow: 0 0 0 3px rgba(58, 189, 224, 0.15) !important;
        }
        .btn-primary, .logout-btn-full {
            transition: all 0.2s ease-in-out !important;
        }
        .btn-primary:hover {
            transform: translateY(-1px) !important;
            box-shadow: 0 6px 20px rgba(21, 88, 168, 0.3) !important;
        }
    </style>
<meta name="csrf-token" content="${csrfToken}">
<script src="${pageContext.request.contextPath}/js/csrf.js"></script>
</head>
<body>
<%@ include file="/WEB-INF/views/loading.jsp" %>

<!-- SIDEBAR -->
<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<!-- MAIN -->
<div class="main">
    <!-- TOPBAR -->
    <header class="topbar">
        <span class="topbar-title">📋 Nhật ký hệ thống</span>
        <div class="topbar-right">
            <div class="topbar-clock">
                <span id="clockH">00</span><span class="clock-sep">:</span><span id="clockM">00</span>
                <span class="clock-date" id="clockDate"></span>
            </div>
            <div class="notif-wrap">
                <button class="topbar-icon-btn" onclick="toggleNotif()" title="Thông báo">
                    🔔
                    <% int totalNotif = expiryCount + pendingResetCount; %>
                    <% if (totalNotif > 0) { %>
                    <span class="topbar-notif-badge"><%= totalNotif > 9 ? "9+" : totalNotif %></span>
                    <% } %>
                </button>
                <div class="notif-dropdown" id="notifDropdown">
                    <div class="notif-head">
                        <span class="notif-head-title">🔔 Thông báo</span>
                        <button class="notif-clear" onclick="closeNotif()">Đóng ✕</button>
                    </div>
                    <div class="notif-list">
                        <% for (com.medicare.entity.PasswordResetRequest pr : pendingResets) {
                               com.medicare.entity.Account staffPr = resetAccountMap.get(pr.getAccountId());
                               java.lang.String staffPrName = staffPr != null ? staffPr.getFullName() : ("ID " + pr.getAccountId());
                               java.lang.String staffPrUser = staffPr != null ? staffPr.getUsername() : "";
                        %>
                        <a href="<%= request.getContextPath() %>/accounts?action=edit&id=<%= pr.getAccountId() %>"
                           class="notif-item" style="text-decoration:none;display:flex;background:rgba(245,158,11,.06);border-left:3px solid #F59E0B">
                            <div class="notif-dot" style="background:#D97706"></div>
                            <div style="flex:1">
                                <div class="notif-text">🔐 <strong><%= staffPrName %></strong> yêu cầu đổi mật khẩu</div>
                                <div class="notif-time">@<%= staffPrUser %> · Bấm để đặt mật khẩu mới</div>
                            </div>
                        </a>
                        <% } %>
                        <% if (expiryCount > 0) { %>
                        <div class="notif-item"><div class="notif-dot"></div><div><div class="notif-text">⚠️ Có <%= expiryCount %> mặt hàng sắp hết hạn</div><div class="notif-time">Hôm nay</div></div></div>
                        <% } else { %>
                        <div class="notif-item"><div class="notif-dot old"></div><div><div class="notif-text">✅ Không có thuốc nào sắp hết hạn</div><div class="notif-time">Hôm nay</div></div></div>
                        <% } %>
                    </div>
                </div>
            </div>
            <a href="<%= request.getContextPath() %>/admin-profile" class="topbar-user">
                <div class="topbar-user-avatar"><%= initials %></div>
                <span class="topbar-user-name"><%= fullName %></span>
            </a>
        </div>
    </header>

    <!-- CONTENT -->
    <div class="content">
        <div class="page-head">
            <div class="page-head-left">
                <div class="breadcrumb">medicare › Phân tích › Nhật ký</div>
                <h1>Nhật ký hệ thống</h1>
            </div>
        </div>

        <div class="table-card">
            <div class="table-card-header">
                <div>
                    <div class="table-card-title">🕒 Toàn hệ thống — Dòng thời gian chung</div>
                    <div class="table-card-subtitle">Mọi vai trò, mới nhất lên đầu — soi sự cố liên hoàn giữa các phòng ban</div>
                </div>
            </div>

            <!-- Filter / Search -->
            <form method="get" action="${pageContext.request.contextPath}/audit-logs" class="filter-row" id="filterForm">
                <div class="filter-search">
                    <input type="text" name="search" id="searchInput"
                           placeholder="Tìm theo hành động, module, mô tả, username…"
                           value="<%= searchKeyword %>">
                </div>
                <div style="display:flex;align-items:center;gap:6px">
                    <span style="font-size:11.5px;font-weight:750;color:var(--muted)">Từ</span>
                    <input type="date" name="from" value="<%= filterFrom %>" style="padding:8px 10px;background:var(--surface);border:1.5px solid var(--border);border-radius:10px;font-family:'Plus Jakarta Sans',sans-serif;font-size:12.5px;color:var(--ink)">
                    <span style="font-size:11.5px;font-weight:750;color:var(--muted)">Đến</span>
                    <input type="date" name="to" value="<%= filterTo %>" style="padding:8px 10px;background:var(--surface);border:1.5px solid var(--border);border-radius:10px;font-family:'Plus Jakarta Sans',sans-serif;font-size:12.5px;color:var(--ink)">
                </div>
                <button type="submit" class="btn-primary">🔍 Lọc</button>
                <% if (!searchKeyword.isEmpty() || !filterFrom.isEmpty() || !filterTo.isEmpty()) { %>
                <a href="${pageContext.request.contextPath}/audit-logs" class="filter-chip">✕ Xóa lọc</a>
                <% } %>
            </form>

            <!-- ── BỘ LỌC PHÂN CẤP: Role → Nhân viên → Loại hành động ── -->
            <div style="background:#fff;border:1px solid var(--border);border-radius:14px;padding:14px 16px;margin-bottom:16px;display:flex;flex-direction:column;gap:12px">
              <div style="display:flex;align-items:center;gap:10px;flex-wrap:wrap">
                <span style="font-size:11px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.5px">Vai trò</span>
                <div id="afRoleTabs" style="display:flex;gap:6px;flex-wrap:wrap">
                  <button type="button" class="af-tab active" data-role="" onclick="afRole(this,'')">Tất cả</button>
                  <button type="button" class="af-tab" data-role="1" onclick="afRole(this,'1')">🛡️ Admin</button>
                  <button type="button" class="af-tab" data-role="2" onclick="afRole(this,'2')">💊 Dược sĩ</button>
                  <button type="button" class="af-tab" data-role="3" onclick="afRole(this,'3')">📦 Thủ kho</button>
                </div>
                <span style="font-size:11px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-left:8px">Nhân viên</span>
                <input type="hidden" id="hAfStaff" value="">
                <div class="cdd" id="cddAfStaff" style="min-width:180px">
                  <div class="cdd-btn" onclick="toggleCdd('cddAfStaff')" style="height:34px;box-sizing:border-box">
                    <span class="cdd-label">— Tất cả người —</span>
                    <span class="cdd-arrow">▼</span>
                  </div>
                  <div class="cdd-menu">
                    <div class="cdd-opt active" data-val="" onclick="pickCdd('cddAfStaff','hAfStaff',this,false);afApply()">— Tất cả người —</div>
                    <% for (com.medicare.entity.Account a : auditAccounts) {
                         String nm = a.getFullName() != null ? a.getFullName() : a.getUsername(); %>
                    <div class="cdd-opt" data-val="<%= a.getAccountId() %>" data-role="<%= a.getRoleId() %>" onclick="pickCdd('cddAfStaff','hAfStaff',this,false);afApply()"><%= nm %> (@<%= a.getUsername() %>)</div>
                    <% } %>
                  </div>
                </div>
              </div>
              <div style="display:flex;align-items:center;gap:6px;flex-wrap:wrap">
                <span style="font-size:11px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-right:4px">Loại</span>
                <% String[][] cats = {{"","Tất cả loại"},{"pos","🛒 Bán hàng"},{"shift","📅 Ca làm việc"},{"attendance","⏱️ Điểm danh"},{"inventory","📦 Kho / Nhập lô"},{"account","👤 Tài khoản"},{"auth","🔑 Đăng nhập"},{"other","⚙️ Khác"}};
                   for (int i=0;i<cats.length;i++) { %>
                <button type="button" class="af-cat <%= i==0?"active":"" %>" data-cat="<%= cats[i][0] %>" onclick="afCat(this,'<%= cats[i][0] %>')"><%= cats[i][1] %></button>
                <% } %>
              </div>
              <div style="font-size:12px;color:var(--muted)">Đang hiện <b id="afCount">0</b> nhật ký (trong <%= auditLogs.size() %> gần nhất).</div>
            </div>
            <style>
              .af-tab,.af-cat{border:1.5px solid var(--border);background:#fff;border-radius:20px;padding:6px 13px;font-size:12.5px;font-weight:750;color:var(--muted);cursor:pointer;font-family:inherit;transition:.14s}
              .af-tab:hover,.af-cat:hover{border-color:var(--cyan);color:var(--ink)}
              .af-tab.active{background:linear-gradient(135deg,var(--blue),var(--cyan));color:#fff;border-color:transparent}
              .af-cat.active{background:var(--navy);color:#fff;border-color:transparent}
              .rolechip{display:inline-block;font-size:10px;font-weight:800;padding:1px 7px;border-radius:20px;margin-left:6px}
              .rc1{background:#FEE2E2;color:#991B1B}.rc2{background:#EFF6FF;color:#1558A8}.rc3{background:#FFFBEB;color:#92400E}.rc0{background:#F1F5F9;color:#64748B}
            </style>

            <style>
              /* Tầng 2 — role summary cards */
              .role-card{background:var(--surface);border:1.5px solid var(--border);border-radius:14px;padding:16px;cursor:pointer;transition:all .18s}
              .role-card:hover{border-color:var(--cyan);background:#fff;transform:translateY(-2px);box-shadow:0 8px 24px rgba(15,38,69,.08)}
              .role-card-icon{width:38px;height:38px;border-radius:11px;display:flex;align-items:center;justify-content:center;font-size:17px;margin-bottom:10px}
              .rc-bg2{background:#EFF6FF}.rc-bg3{background:#FFFBEB}.rc-bg0{background:#F1F5F9}
              .role-card-name{font-size:13.5px;font-weight:750;color:var(--ink)}
              .role-card-count{font-family:'Lora',serif;font-size:26px;font-weight:750;color:var(--navy);margin-top:6px}
              .role-card-sub{font-size:11px;color:var(--muted);margin-top:2px}

              /* Drawer trượt từ phải */
              .drawer-backdrop{position:fixed;inset:0;background:rgba(11,22,40,.4);z-index:300;opacity:0;visibility:hidden;transition:opacity .22s}
              .drawer-backdrop.open{opacity:1;visibility:visible}
              .role-drawer{position:fixed;top:0;right:0;bottom:0;width:min(720px,92vw);background:#fff;z-index:301;box-shadow:-12px 0 40px rgba(15,38,69,.18);transform:translateX(100%);transition:transform .26s cubic-bezier(.2,.8,.2,1);display:flex;flex-direction:column;overflow-y:auto}
              .role-drawer.open{transform:translateX(0)}
              .role-drawer-head{padding:20px 20px 14px;border-bottom:1px solid var(--border);display:flex;align-items:center;justify-content:space-between;position:sticky;top:0;background:#fff;z-index:2}
            </style>

            <!-- Table -->
            <div class="table-wrap">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th>#</th>
                            <th>Người thực hiện</th>
                            <th>Hành động</th>
                            <th>Module</th>
                            <th>Mô tả</th>
                            <th>IP</th>
                            <th>Thời gian</th>
                        </tr>
                    </thead>
                    <tbody>
                    <% if (auditLogs.isEmpty()) { %>
                        <tr>
                            <td colspan="7">
                                <div class="empty-state">
                                    <div class="icon">📋</div>
                                    <p>Chưa có nhật ký nào<% if (!searchKeyword.isEmpty()) { %> khớp với "<%= searchKeyword %>"<% } %>.</p>
                                </div>
                            </td>
                        </tr>
                    <% } else {
                           java.time.format.DateTimeFormatter dtf = java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss");
                           for (com.medicare.entity.AuditLog log : auditLogs) {
                               java.lang.String actionBadge = "badge-gray";
                               java.lang.String act = log.getAction() != null ? log.getAction() : "";
                               if (act.contains("Tạo") || act.contains("Khôi phục"))         actionBadge = "badge-green";
                               else if (act.contains("Xóa") || act.contains("Khóa"))          actionBadge = "badge-red";
                               else if (act.contains("Đăng nhập") || act.contains("Đăng xuất")) actionBadge = "badge-blue";
                               else if (act.contains("Cập nhật") || act.contains("Sửa") || act.contains("Đặt lại")) actionBadge = "badge-gold";
                               String _cat = auditCat(act, log.getEntityType());
                               int _role = log.getAccountId() != null ? auditRoleMap.getOrDefault(log.getAccountId(), 0) : 0;
                               String _rlabel = _role==1?"Admin":_role==2?"Dược sĩ":_role==3?"Thủ kho":"Hệ thống";
                    %>
                        <tr data-role="<%= _role %>" data-acct="<%= log.getAccountId() != null ? log.getAccountId() : 0 %>" data-cat="<%= _cat %>">
                            <td class="log-id">#<%= log.getLogId() %></td>
                            <td>
                                <% java.lang.String uname = log.getUsername() != null ? log.getUsername() : "Hệ thống"; %>
                                <span style="font-weight:750;color:var(--ink)">@<%= uname %></span>
                                <span class="rolechip rc<%= _role %>"><%= _rlabel %></span>
                            </td>
                            <td>
                                <span class="badge <%= actionBadge %>"><%= act %></span>
                                <div style="font-size:10.5px;color:var(--muted);font-weight:750;margin-top:3px"><%= catLabel(_cat) %></div>
                            </td>
                            <td><span style="font-size:12.5px;color:var(--navy);font-weight:750"><%= log.getEntityType() != null ? log.getEntityType() : "—" %></span></td>
                            <td>
                                <div class="log-desc" title="<%= log.getDescription() != null ? log.getDescription() : "" %>">
                                    <%= log.getDescription() != null ? log.getDescription() : "—" %>
                                </div>
                            </td>
                            <td class="log-ip"><%= ipLabel(log.getIpAddress()) %></td>
                            <td class="log-time">
                                <%= log.getCreatedAt() != null ? log.getCreatedAt().format(dtf) : "—" %>
                            </td>
                        </tr>
                    <% }} %>
                    </tbody>
                </table>
            </div>

            <!-- Pagination -->
            <div class="pagination">
                <div class="pagination-info">
                    Trang <%= currentPage %> / <%= totalPages %>
                </div>
                <div class="pagination-btns">
                    <a href="${pageContext.request.contextPath}/audit-logs?page=<%= currentPage - 1 %><%= pageQS %>"
                       class="page-btn <%= currentPage <= 1 ? "disabled" : "" %>">‹</a>
                    <%
                       int start = Math.max(1, currentPage - 2);
                       int end   = Math.min(totalPages, currentPage + 2);
                       for (int p = start; p <= end; p++) {
                    %>
                    <a href="${pageContext.request.contextPath}/audit-logs?page=<%= p %><%= pageQS %>"
                       class="page-btn <%= p == currentPage ? "active" : "" %>"><%= p %></a>
                    <% } %>
                    <a href="${pageContext.request.contextPath}/audit-logs?page=<%= currentPage + 1 %><%= pageQS %>"
                       class="page-btn <%= currentPage >= totalPages ? "disabled" : "" %>">›</a>
                </div>
            </div>
        </div>

        <!-- ══ TẦNG 2 — Tổng quan theo phòng ban (quick filter / deep-dive) ══ -->
        <div class="table-card" style="margin-top:20px">
            <div class="table-card-header">
                <div>
                    <div class="table-card-title">🗂️ Theo phòng ban</div>
                    <div class="table-card-subtitle">Bấm 1 thẻ để xem chi tiết nhật ký riêng của phòng ban đó, có filter loại hành động</div>
                </div>
            </div>
            <div style="padding:20px 24px;display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:14px">
                <div class="role-card" onclick="openRoleDrawer('2','💊 Dược sĩ / Staff POS')">
                    <div class="role-card-icon rc-bg2">💊</div>
                    <div class="role-card-name">Dược sĩ / Staff POS</div>
                    <div class="role-card-count" id="cardCount2">0</div>
                    <div class="role-card-sub">hành động · trong <%= auditLogs.size() %> gần nhất</div>
                </div>
                <div class="role-card" onclick="openRoleDrawer('3','📦 Thủ kho / Inventory')">
                    <div class="role-card-icon rc-bg3">📦</div>
                    <div class="role-card-name">Thủ kho / Inventory</div>
                    <div class="role-card-count" id="cardCount3">0</div>
                    <div class="role-card-sub">hành động · trong <%= auditLogs.size() %> gần nhất</div>
                </div>
                <div class="role-card" onclick="openRoleDrawer('0','⚙️ Hệ thống / Tự động')">
                    <div class="role-card-icon rc-bg0">⚙️</div>
                    <div class="role-card-name">Hệ thống / Tự động</div>
                    <div class="role-card-count" id="cardCount0">0</div>
                    <div class="role-card-sub">hành động · trong <%= auditLogs.size() %> gần nhất</div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- ══ DRAWER chi tiết theo phòng ban (trượt từ phải) ══ -->
<div class="drawer-backdrop" id="roleDrawerBackdrop" onclick="closeRoleDrawer()"></div>
<aside class="role-drawer" id="roleDrawer">
    <div class="role-drawer-head">
        <div id="drawerTitle" style="font-family:'Lora',serif;font-weight:750;font-size:17px">—</div>
        <button type="button" class="topbar-icon-btn" onclick="closeRoleDrawer()" title="Đóng" aria-label="Đóng">✕</button>
    </div>
    <div id="drawerCats" style="padding:14px 20px 0;display:flex;gap:6px;flex-wrap:wrap">
        <% String[][] dcats = {{"","Tất cả loại"},{"pos","🛒 Bán hàng"},{"shift","📅 Ca làm việc"},{"attendance","⏱️ Điểm danh"},{"inventory","📦 Kho / Nhập lô"},{"account","👤 Tài khoản"},{"auth","🔑 Đăng nhập"},{"other","⚙️ Khác"}};
           for (int i=0;i<dcats.length;i++) { %>
        <button type="button" class="af-cat <%= i==0?"active":"" %>" data-cat="<%= dcats[i][0] %>" onclick="drawerCat(this,'<%= dcats[i][0] %>')"><%= dcats[i][1] %></button>
        <% } %>
    </div>
    <div style="padding:10px 20px;font-size:12px;color:var(--muted)">Đang hiện <b id="drawerCount">0</b> nhật ký.</div>
    <div class="table-wrap" style="padding:0 20px 20px">
        <table class="data-table">
            <thead>
                <tr><th>#</th><th>Người thực hiện</th><th>Hành động</th><th>Module</th><th>Mô tả</th><th>IP</th><th>Thời gian</th></tr>
            </thead>
            <tbody id="drawerTbody"></tbody>
        </table>
    </div>
</aside>

<script>
function toggleCdd(id){var w=document.getElementById(id),m=w.querySelector('.cdd-menu'),b=w.querySelector('.cdd-btn');var open=m.classList.contains('show');document.querySelectorAll('.cdd-menu.show').forEach(function(x){x.classList.remove('show');x.closest('.cdd').querySelector('.cdd-btn').classList.remove('open')});if(!open){m.classList.add('show');b.classList.add('open');var act=m.querySelector('.cdd-opt.active');if(act)act.scrollIntoView({block:'nearest'})}}
function pickCdd(wId,hId,el,autoSubmit){document.getElementById(hId).value=el.dataset.val;var w=document.getElementById(wId);w.querySelector('.cdd-label').textContent=el.textContent;w.querySelectorAll('.cdd-opt').forEach(function(o){o.classList.remove('active')});el.classList.add('active');w.querySelector('.cdd-menu').classList.remove('show');w.querySelector('.cdd-btn').classList.remove('open');if(autoSubmit){var f=w.closest('form');if(f)f.submit()}}
document.addEventListener('click',function(e){if(!e.target.closest('.cdd')){document.querySelectorAll('.cdd-menu.show').forEach(function(m){m.classList.remove('show');m.closest('.cdd').querySelector('.cdd-btn').classList.remove('open')})}});

// Clock
function updateClock() {
    const now = new Date();
    document.getElementById('clockH').textContent = String(now.getHours()).padStart(2,'0');
    document.getElementById('clockM').textContent = String(now.getMinutes()).padStart(2,'0');
    const days = ['CN','T2','T3','T4','T5','T6','T7'];
    document.getElementById('clockDate').textContent =
        days[now.getDay()] + ', ' + String(now.getDate()).padStart(2,'0') + '/' + String(now.getMonth()+1).padStart(2,'0');
}
updateClock(); setInterval(updateClock, 1000);

// Notif dropdown
function toggleNotif() { document.getElementById('notifDropdown').classList.toggle('open'); }
function closeNotif()  { document.getElementById('notifDropdown').classList.remove('open'); }
document.addEventListener('click', e => {
    const wrap = document.querySelector('.notif-wrap');
    if (wrap && !wrap.contains(e.target)) closeNotif();
});

// Search on Enter
document.getElementById('searchInput').addEventListener('keydown', e => {
    if (e.key === 'Enter') document.getElementById('filterForm').submit();
});

// ── BỘ LỌC PHÂN CẤP nhật ký: Role → Nhân viên → Loại ──
const afState = { role:'', cat:'' };
function afRole(btn, role) {
    document.querySelectorAll('#afRoleTabs .af-tab').forEach(t => t.classList.remove('active'));
    btn.classList.add('active');
    afState.role = role;
    // Lọc dropdown nhân viên theo role đang chọn
    const wrap = document.getElementById('cddAfStaff');
    document.getElementById('hAfStaff').value = '';
    wrap.querySelectorAll('.cdd-opt').forEach(o => o.classList.remove('active'));
    const firstOpt = wrap.querySelector('.cdd-opt[data-val=""]');
    if (firstOpt) { firstOpt.classList.add('active'); wrap.querySelector('.cdd-label').textContent = firstOpt.textContent; }
    wrap.querySelectorAll('.cdd-opt').forEach(o => {
        if (!o.dataset.val) return; // giữ "Tất cả người"
        o.style.display = (role !== '' && o.dataset.role !== role) ? 'none' : '';
    });
    afApply();
}
function afCat(btn, cat) {
    document.querySelectorAll('.af-cat').forEach(c => c.classList.remove('active'));
    btn.classList.add('active');
    afState.cat = cat;
    afApply();
}
function afApply() {
    const acct = document.getElementById('hAfStaff').value || '';
    let shown = 0;
    document.querySelectorAll('.data-table tbody tr[data-role]').forEach(row => {
        const okRole = !afState.role || row.dataset.role === afState.role;
        const okAcct = !acct        || row.dataset.acct === acct;
        const okCat  = !afState.cat || row.dataset.cat  === afState.cat;
        const show = okRole && okAcct && okCat;
        row.style.display = show ? '' : 'none';
        if (show) shown++;
    });
    const cnt = document.getElementById('afCount');
    if (cnt) cnt.textContent = shown;
    // dòng "không có" khi rỗng
    const tbody = document.querySelector('.data-table tbody');
    let none = document.getElementById('afNoRow');
    if (shown === 0 && tbody && !none) {
        none = document.createElement('tr'); none.id = 'afNoRow';
        none.innerHTML = '<td colspan="7"><div class="empty-state"><div class="icon">🔍</div><p>Không có nhật ký khớp bộ lọc.</p></div></td>';
        tbody.appendChild(none);
    } else if (shown > 0 && none) { none.remove(); }
}
afApply(); // đếm ban đầu

// ── TẦNG 2: đếm số dòng theo role (trong dữ liệu đã tải) cho từng thẻ ──
function countRole(role) {
    return document.querySelectorAll('.data-table tbody tr[data-role="' + role + '"]').length;
}
['2','3','0'].forEach(function (r) {
    var el = document.getElementById('cardCount' + r);
    if (el) el.textContent = countRole(r);
});

// ── DRAWER chi tiết theo phòng ban ──
function openRoleDrawer(role, label) {
    document.getElementById('drawerTitle').textContent = label;
    var tbody = document.getElementById('drawerTbody');
    tbody.innerHTML = '';
    var count = 0;
    document.querySelectorAll('.data-table tbody tr[data-role]').forEach(function (row) {
        if (row.dataset.role === String(role)) {
            tbody.appendChild(row.cloneNode(true));
            count++;
        }
    });
    if (count === 0) {
        tbody.innerHTML = '<tr><td colspan="7"><div class="empty-state"><div class="icon">📋</div><p>Chưa có nhật ký nào.</p></div></td></tr>';
    }
    document.getElementById('drawerCount').textContent = count;
    document.querySelectorAll('#drawerCats .af-cat').forEach(function (b, i) { b.classList.toggle('active', i === 0); });
    document.getElementById('roleDrawer').classList.add('open');
    document.getElementById('roleDrawerBackdrop').classList.add('open');
}
function closeRoleDrawer() {
    document.getElementById('roleDrawer').classList.remove('open');
    document.getElementById('roleDrawerBackdrop').classList.remove('open');
}
function drawerCat(btn, cat) {
    document.querySelectorAll('#drawerCats .af-cat').forEach(function (c) { c.classList.remove('active'); });
    btn.classList.add('active');
    var shown = 0;
    document.querySelectorAll('#drawerTbody tr[data-role]').forEach(function (row) {
        var show = !cat || row.dataset.cat === cat;
        row.style.display = show ? '' : 'none';
        if (show) shown++;
    });
    document.getElementById('drawerCount').textContent = shown;
}
document.addEventListener('keydown', function (e) {
    if (e.key === 'Escape') closeRoleDrawer();
});
</script>
</body>
</html>
