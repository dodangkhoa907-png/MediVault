<%@ page contentType="text/html;charset=UTF-8" %>
<% String activeNav = "audit"; %>
<%@ taglib prefix="c"  uri="jakarta.tags.core" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    java.lang.String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    java.lang.String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();

    Integer expiryCount       = (Integer) request.getAttribute("expiryCount");
    Integer pendingResetCount = (Integer) request.getAttribute("pendingResetCount");
    if (expiryCount       == null) expiryCount       = 0;
    if (pendingResetCount == null) pendingResetCount = 0;

    @SuppressWarnings("unchecked")
    java.util.List<com.medicare.entity.PasswordResetRequest> pendingResets =
        (java.util.List<com.medicare.entity.PasswordResetRequest>) request.getAttribute("pendingResets");
    @SuppressWarnings("unchecked")
    java.util.Map<Integer, com.medicare.entity.Account> resetAccountMap =
        (java.util.Map<Integer, com.medicare.entity.Account>) request.getAttribute("resetAccountMap");
    if (pendingResets   == null) pendingResets   = new java.util.ArrayList<>();
    if (resetAccountMap == null) resetAccountMap = new java.util.HashMap<>();

    // ── Dashboard KPI ──
    Integer kpiTotal    = (Integer) request.getAttribute("kpiTotal");
    Integer kpiToday    = (Integer) request.getAttribute("kpiToday");
    Integer kpiCritical = (Integer) request.getAttribute("kpiCritical");
    Integer kpiWarning  = (Integer) request.getAttribute("kpiWarning");
    Integer kpiUsers    = (Integer) request.getAttribute("kpiUsers");
    if (kpiTotal == null) kpiTotal = 0; if (kpiToday == null) kpiToday = 0;
    if (kpiCritical == null) kpiCritical = 0; if (kpiWarning == null) kpiWarning = 0;
    if (kpiUsers == null) kpiUsers = 0;

    @SuppressWarnings("unchecked")
    java.util.List<com.medicare.entity.AuditLog> recentRows =
        (java.util.List<com.medicare.entity.AuditLog>) request.getAttribute("recentRows");
    if (recentRows == null) recentRows = new java.util.ArrayList<>();

    // ── Explorer ──
    @SuppressWarnings("unchecked")
    java.util.List<com.medicare.entity.AuditLog> explorerRows =
        (java.util.List<com.medicare.entity.AuditLog>) request.getAttribute("explorerRows");
    if (explorerRows == null) explorerRows = new java.util.ArrayList<>();
    Integer explorerTotal = (Integer) request.getAttribute("explorerTotal");
    Integer explorerPage  = (Integer) request.getAttribute("explorerPage");
    Integer explorerPages = (Integer) request.getAttribute("explorerPages");
    if (explorerTotal == null) explorerTotal = 0;
    if (explorerPage  == null) explorerPage  = 1;
    if (explorerPages == null) explorerPages = 1;

    Integer fRole      = (Integer) request.getAttribute("fRole");
    java.lang.String fModule   = (java.lang.String) request.getAttribute("fModule");
    java.lang.String fSeverity = (java.lang.String) request.getAttribute("fSeverity");
    Integer fAccount   = (Integer) request.getAttribute("fAccount");
    java.lang.String fIp       = (java.lang.String) request.getAttribute("fIp");
    java.lang.String searchKeyword = (java.lang.String) request.getAttribute("searchKeyword");
    java.lang.String filterFrom    = (java.lang.String) request.getAttribute("filterFrom");
    java.lang.String filterTo      = (java.lang.String) request.getAttribute("filterTo");
    if (fModule == null) fModule = ""; if (fSeverity == null) fSeverity = ""; if (fIp == null) fIp = "";
    if (searchKeyword == null) searchKeyword = ""; if (filterFrom == null) filterFrom = ""; if (filterTo == null) filterTo = "";

    @SuppressWarnings("unchecked")
    java.util.Map<Integer, Integer> roleCounts = (java.util.Map<Integer, Integer>) request.getAttribute("roleCounts");
    if (roleCounts == null) roleCounts = new java.util.HashMap<>();
    @SuppressWarnings("unchecked")
    java.util.Map<String, Integer> moduleCounts = (java.util.Map<String, Integer>) request.getAttribute("moduleCounts");
    if (moduleCounts == null) moduleCounts = new java.util.HashMap<>();
    @SuppressWarnings("unchecked")
    java.util.LinkedHashMap<String, String> moduleTabs = (java.util.LinkedHashMap<String, String>) request.getAttribute("moduleTabs");
    if (moduleTabs == null) moduleTabs = new java.util.LinkedHashMap<>();

    @SuppressWarnings("unchecked")
    java.util.List<com.medicare.entity.Account> auditAccounts =
        (java.util.List<com.medicare.entity.Account>) request.getAttribute("auditAccounts");
    if (auditAccounts == null) auditAccounts = new java.util.ArrayList<>();

    // ── Quick Analytics / widgets rail ──
    @SuppressWarnings("unchecked")
    java.util.Map<String, Integer> topUsers = (java.util.Map<String, Integer>) request.getAttribute("topUsers");
    @SuppressWarnings("unchecked")
    java.util.Map<String, Integer> topIps   = (java.util.Map<String, Integer>) request.getAttribute("topIps");
    int[] hourlyToday = (int[]) request.getAttribute("hourlyToday");
    if (topUsers == null) topUsers = new java.util.LinkedHashMap<>();
    if (topIps   == null) topIps   = new java.util.LinkedHashMap<>();
    if (hourlyToday == null) hourlyToday = new int[24];

    @SuppressWarnings("unchecked")
    java.util.LinkedHashMap<String, Integer> severityToday =
        (java.util.LinkedHashMap<String, Integer>) request.getAttribute("severityToday");
    if (severityToday == null) severityToday = new java.util.LinkedHashMap<>();

    @SuppressWarnings("unchecked")
    java.util.Map<Integer, Integer> accountRoleMap = (java.util.Map<Integer, Integer>) request.getAttribute("accountRoleMap");
    if (accountRoleMap == null) accountRoleMap = new java.util.HashMap<>();
    Integer currentAdminId = (Integer) request.getAttribute("currentAdminId");
    if (currentAdminId == null) currentAdminId = 0;
%>
<%!
    private String sevOf(String action) {
        String a = action == null ? "" : action;
        if (a.contains("Xóa") || a.contains("Khóa"))            return "critical";
        if (a.contains("Cập nhật") || a.contains("Sửa") || a.contains("Đặt lại")) return "warning";
        if (a.contains("Đăng nhập") || a.contains("Đăng xuất")) return "info";
        if (a.contains("Tạo") || a.contains("Khôi phục"))       return "success";
        return "neutral";
    }
    private String ipLabel(String ip) {
        if (ip == null || ip.isEmpty()) return "—";
        String norm = ip.trim();
        if (norm.startsWith("::ffff:")) norm = norm.substring(7);
        if (norm.equals("127.0.0.1") || norm.equals("::1") || norm.equals("0:0:0:0:0:0:0:1") || norm.equals("0:0:0:0:0:0:1"))
            return "🖥️ Máy chủ · " + ip;
        boolean isLan = norm.matches("^192\\.168\\..*") || norm.matches("^10\\..*") || norm.matches("^172\\.(1[6-9]|2[0-9]|3[0-1])\\..*");
        return isLan ? ("🏠 Nội bộ · " + ip) : ("🌐 Ngoài · " + ip);
    }
    private String jsStr(String s) {
        if (s == null) return "null";
        StringBuilder sb = new StringBuilder("\"");
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '"':  sb.append("\\\""); break;
                case '\\': sb.append("\\\\"); break;
                case '\n': sb.append("\\n");  break;
                case '\r': sb.append("\\r");  break;
                case '\t': sb.append("\\t");  break;
                case '<':  sb.append("\\u003C"); break;
                default: if (c < 0x20) sb.append(String.format("\\u%04x", (int) c)); else sb.append(c);
            }
        }
        return sb.append('"').toString();
    }
    /** Ghép query string giữ nguyên MỌI bộ lọc đang áp dụng — dùng cho tab Vai trò/Module, chip
     *  Bộ lọc nhanh và phân trang, để đổi 1 chiều lọc không làm mất các chiều lọc khác đang chọn. */
    private String explorerQS(java.lang.String search, java.lang.String from, java.lang.String to,
            Integer role, java.lang.String module, java.lang.String severity, Integer account,
            java.lang.String ip, int page) {
        StringBuilder sb = new StringBuilder();
        if (search != null && !search.isEmpty()) sb.append("&search=").append(java.net.URLEncoder.encode(search, java.nio.charset.StandardCharsets.UTF_8));
        if (from   != null && !from.isEmpty())   sb.append("&from=").append(from);
        if (to     != null && !to.isEmpty())     sb.append("&to=").append(to);
        if (role   != null)                      sb.append("&role=").append(role);
        if (module != null && !module.isEmpty()) sb.append("&module=").append(module);
        if (severity != null && !severity.isEmpty()) sb.append("&severity=").append(severity);
        if (account != null)                     sb.append("&account=").append(account);
        if (ip     != null && !ip.isEmpty())     sb.append("&ip=").append(java.net.URLEncoder.encode(ip, java.nio.charset.StandardCharsets.UTF_8));
        if (page   > 1)                          sb.append("&page=").append(page);
        return sb.toString();
    }
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>medicare — Audit Center</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Lora:ital,wght@0,400..700;1,400..700&family=Plus+Jakarta+Sans:ital,wght@0,200..800;1,200..800&display=swap" rel="stylesheet">
<style>
*,*::before,*::after{box-sizing:border-box;margin:0;padding:0}
:root{
  --ink:#0B1628;--navy:#0F2645;--blue:#1558A8;--cyan:#3ABDE0;--cyan-soft:#EBF8FD;
  --surface:#F1F5FB;--white:#fff;--muted:#7A90B0;--border:#D5E0F0;
  --green:#059669;--red:#DC2626;--gold:#D97706;--sidebar:232px;
  --sev-critical-bg:#FEF2F2;--sev-critical-c:#DC2626;
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
.topbar{height:58px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 26px;gap:14px;position:sticky;top:0;z-index:150}
.topbar-title{font-family:'Plus Jakarta Sans',sans-serif;font-size:15px;font-weight:750;color:var(--ink)}
.topbar-right{margin-left:auto;display:flex;align-items:center;gap:10px;flex-shrink:0}
.topbar-clock{display:flex;align-items:center;gap:5px;padding:5px 12px;background:var(--surface);border:1.5px solid var(--border);border-radius:20px;font-size:12.5px;font-weight:750;color:var(--navy);font-variant-numeric:tabular-nums}
.clock-sep{animation:blink 1s step-end infinite}
@keyframes blink{0%,100%{opacity:1}50%{opacity:0}}
.clock-date{font-size:11px;font-weight:750;color:var(--muted);border-left:1px solid var(--border);padding-left:8px;margin-left:2px}
.notif-wrap{position:relative}
.topbar-icon-btn{width:32px;height:32px;border-radius:9px;background:var(--surface);border:1.5px solid var(--border);cursor:pointer;font-size:14px;display:flex;align-items:center;justify-content:center;position:relative;transition:all .18s}
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
.topbar-user-avatar{width:26px;height:26px;border-radius:8px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:11px;font-weight:800;color:#fff}
.topbar-user-name{font-size:12.5px;font-weight:750;color:var(--navy);max-width:110px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}

/* CONTENT */
.content{padding:20px 26px 28px;flex:1;min-width:0}

/* ══ Investigation Center header ══ */
.ic-header{display:flex;align-items:flex-end;justify-content:space-between;gap:16px;margin-bottom:16px;flex-wrap:wrap}
.breadcrumb{font-size:11px;color:var(--muted);font-weight:750;margin-bottom:3px}
.ic-header h1{font-family:'Lora',serif;font-size:24px;font-weight:750;color:var(--ink)}
.ic-header p{font-size:12px;color:var(--muted);margin-top:3px}
.ic-actions{display:flex;align-items:center;gap:8px;flex-wrap:wrap}
.ic-btn{height:36px;padding:0 13px;border-radius:10px;border:1.5px solid var(--border);background:#fff;color:var(--navy);
  font-size:12px;font-weight:750;cursor:pointer;font-family:inherit;text-decoration:none;display:inline-flex;align-items:center;gap:6px;transition:all .15s}
.ic-btn:hover{border-color:var(--cyan);color:var(--blue)}
.ic-btn.primary{background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border-color:transparent}
.ic-btn.primary:hover{filter:brightness(1.08);color:#fff}
.ic-live-btn{height:36px;padding:0 13px 0 11px;border-radius:10px;border:1.5px solid var(--border);background:#fff;color:var(--muted);
  font-size:12px;font-weight:750;cursor:pointer;font-family:inherit;display:inline-flex;align-items:center;gap:7px;transition:all .15s}
.ic-live-btn .dot{width:8px;height:8px;border-radius:50%;background:var(--muted);flex-shrink:0}
.ic-live-btn.on{border-color:var(--green);color:var(--green);background:#F0FDF4}
.ic-live-btn.on .dot{background:var(--green);animation:livepulse 1.4s ease-in-out infinite}
@keyframes livepulse{0%,100%{box-shadow:0 0 0 0 rgba(5,150,105,.5)}50%{box-shadow:0 0 0 5px rgba(5,150,105,0)}}
.ic-new-badge{margin-left:2px;background:var(--green);color:#fff;font-size:10px;font-weight:800;padding:1px 6px;border-radius:20px;cursor:pointer;display:none}
.ic-export-wrap{position:relative}
.ic-export-menu{position:absolute;top:calc(100% + 6px);right:0;width:190px;background:#fff;border:1px solid var(--border);border-radius:12px;
  box-shadow:0 12px 32px rgba(15,38,69,.14);opacity:0;visibility:hidden;transform:translateY(-6px);transition:all .16s;z-index:180;overflow:hidden}
.ic-export-menu.open{opacity:1;visibility:visible;transform:translateY(0)}
.ic-export-menu a{display:flex;align-items:center;gap:8px;padding:10px 14px;font-size:12.5px;font-weight:700;color:var(--ink);text-decoration:none;transition:background .13s}
.ic-export-menu a:hover{background:var(--surface)}
.ic-export-menu .hint{padding:8px 14px 10px;font-size:10.5px;color:var(--muted);border-top:1px solid var(--border);line-height:1.5}

/* ══ Row 1 — KPI strip (fixed 90px cards) ══ */
.kpi-strip{display:grid;grid-template-columns:repeat(5,1fr);gap:12px;margin-bottom:16px}
@media(max-width:1200px){.kpi-strip{grid-template-columns:repeat(3,1fr)}}
.kpi-card{height:90px;background:#fff;border:1px solid rgba(213,224,240,.5);border-radius:16px;padding:14px 16px;
  box-shadow:0 1px 3px rgba(15,38,69,.03),0 4px 12px rgba(15,38,69,.04);transition:all .18s;display:flex;flex-direction:column;justify-content:center}
.kpi-card:hover{transform:translateY(-2px);box-shadow:0 8px 22px rgba(15,38,69,.09)}
.kpi-num{font-family:'Lora',serif;font-size:24px;font-weight:750;color:var(--ink);font-variant-numeric:tabular-nums;line-height:1.1}
.kpi-lbl{font-size:11px;color:var(--muted);font-weight:650;margin-top:4px}
.kpi-card.k-critical .kpi-num{color:var(--red)}
.kpi-card.k-warning  .kpi-num{color:var(--gold)}
.kpi-card.k-users    .kpi-num{color:var(--green)}

/* ══ Row 2 — Timeline (65%) + widget rail (35%) ══ */
.ic-row2{display:grid;grid-template-columns:65fr 35fr;gap:14px;margin-bottom:20px;align-items:stretch}
@media(max-width:1100px){.ic-row2{grid-template-columns:1fr}}
.ic-row2-h{height:452px}
.ic-card{background:#fff;border:1px solid rgba(213,224,240,.5);border-radius:16px;overflow:hidden;
  box-shadow:0 1px 3px rgba(15,38,69,.03),0 4px 12px rgba(15,38,69,.04);display:flex;flex-direction:column}
.ic-card-head{display:flex;align-items:center;gap:8px;padding:13px 18px;border-bottom:1px solid var(--border);flex-shrink:0}
.ic-card-head h3{font-size:13px;font-weight:800;color:var(--navy)}
.ic-card-head .cnt{font-size:10.5px;font-weight:750;color:var(--muted);background:var(--surface);padding:2px 8px;border-radius:20px}
.ic-card-head .jump{margin-left:auto;font-size:11.5px;font-weight:750;color:var(--blue);text-decoration:none;background:none;border:none;cursor:pointer;font-family:inherit}
.ic-card-head .jump:hover{text-decoration:underline}
.ic-scroll{flex:1;overflow-y:auto;min-height:0}

/* Timeline rows (dot style) — Recent Activity */
.ac-row{display:flex;align-items:center;gap:12px;padding:11px 18px;border-bottom:1px solid #F4F7FC;transition:background .14s}
.ac-row:hover{background:#FAFCFF}
.ac-row:last-child{border-bottom:none}
.ac-row-icon{width:28px;height:28px;border-radius:9px;flex-shrink:0;display:flex;align-items:center;justify-content:center;font-size:12px}
.ac-row-icon.s-critical{background:var(--sev-critical-bg);color:var(--sev-critical-c)}
.ac-row-icon.s-warning{background:#FFFBEB;color:#B45309}
.ac-row-icon.s-info{background:#EFF6FF;color:#1D4ED8}
.ac-row-icon.s-success{background:#F0FDF4;color:#047857}
.ac-row-icon.s-neutral{background:var(--surface);color:var(--muted)}
.ac-row-main{flex:1;min-width:0}
.ac-row-top{display:flex;align-items:center;gap:8px;flex-wrap:wrap}
.ac-row-title{font-size:12.5px;font-weight:750;color:var(--ink)}
.ac-row-mod{font-size:9.5px;font-weight:750;padding:2px 7px;border-radius:20px;background:var(--surface);color:var(--muted)}
.ac-row-meta{font-size:11px;color:var(--muted);margin-top:1px}
.ac-row-meta b{color:var(--navy);font-weight:750}
.ac-row-time{flex-shrink:0;font-size:10.5px;color:var(--muted);white-space:nowrap}
.ac-row-btn{flex-shrink:0;height:26px;padding:0 10px;border-radius:8px;border:1.5px solid var(--border);background:#fff;
  color:var(--muted);font-size:10.5px;font-weight:750;cursor:pointer;font-family:inherit;transition:all .15s}
.ac-row-btn:hover{border-color:var(--cyan);color:var(--blue)}
.ac-row.new-flash{animation:newflash 1.8s ease}
@keyframes newflash{0%{background:#EBF8FD}100%{background:transparent}}
.ac-empty{padding:36px 24px;text-align:center;color:var(--muted)}
.ac-empty .icon{font-size:30px;margin-bottom:8px}

/* Rail widgets */
.ic-rail{display:flex;flex-direction:column;gap:10px;overflow-y:auto}
.ic-widget{background:#fff;border:1px solid rgba(213,224,240,.5);border-radius:16px;padding:14px 16px;flex-shrink:0;
  box-shadow:0 1px 3px rgba(15,38,69,.03),0 4px 12px rgba(15,38,69,.04)}
.ic-widget-title{font-size:10.5px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:9px;display:flex;align-items:center;gap:6px}
.sev-bar-row{display:flex;align-items:center;gap:8px;padding:3px 0}
.sev-bar-row .lbl{width:64px;font-size:11px;font-weight:700;color:var(--ink);flex-shrink:0}
.sev-bar-track{flex:1;height:6px;background:var(--surface);border-radius:4px;overflow:hidden}
.sev-bar-fill{display:block;height:100%;border-radius:4px}
.sev-bar-row .val{width:22px;text-align:right;font-size:11px;font-weight:750;color:var(--navy);flex-shrink:0}
.stat-row{display:flex;align-items:center;gap:8px;padding:4px 0}
.stat-row .rank{width:14px;font-size:10.5px;font-weight:800;color:var(--muted);flex-shrink:0}
.stat-row .name{flex:1;font-size:11.5px;font-weight:650;color:var(--ink);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.stat-bar{flex:1;height:5px;background:var(--surface);border-radius:4px;overflow:hidden;margin:0 6px}
.stat-bar i{display:block;height:100%;background:linear-gradient(90deg,var(--blue),var(--cyan));border-radius:4px}
.stat-row .val{font-size:11px;font-weight:750;color:var(--navy);min-width:18px;text-align:right;flex-shrink:0}
.stat-hours{display:flex;align-items:flex-end;gap:2px;height:48px}
.stat-hbar-wrap{flex:1;display:flex;flex-direction:column;align-items:center;justify-content:flex-end;height:100%}
.stat-hbar{width:100%;background:linear-gradient(180deg,var(--cyan),var(--blue));border-radius:2px 2px 0 0;min-height:2px}
.stat-empty{font-size:11px;color:var(--muted);padding:4px 0}

/* ══ Explorer ══ */
.explorer-wrap{background:#fff;border:1px solid rgba(213,224,240,.5);border-radius:16px;overflow:hidden;
  box-shadow:0 1px 3px rgba(15,38,69,.03),0 4px 12px rgba(15,38,69,.04)}
.section-title{display:flex;align-items:center;gap:8px;font-size:14px;font-weight:800;color:var(--navy);margin:0 0 12px}
.section-title .cnt{font-size:11px;font-weight:750;color:var(--muted);background:var(--surface);padding:2px 9px;border-radius:20px}
.tab-row{display:flex;gap:6px;flex-wrap:wrap;padding:14px 18px;border-bottom:1px solid var(--border)}
.tab-row.sub{padding-top:0;border-top:1px dashed var(--border);padding-top:12px}
.etab{display:inline-flex;align-items:center;gap:6px;padding:7px 13px;border-radius:20px;border:1.5px solid var(--border);
  background:#fff;color:var(--navy);font-size:12px;font-weight:750;text-decoration:none;transition:all .15s;white-space:nowrap}
.etab:hover{border-color:var(--cyan);color:var(--blue)}
.etab.active{background:linear-gradient(135deg,var(--blue),var(--cyan));color:#fff;border-color:transparent;box-shadow:0 3px 10px rgba(21,88,168,.22)}
.etab .n{opacity:.75;font-weight:700}

/* Saved filter chips */
.chip-row{display:flex;gap:6px;flex-wrap:wrap;padding:10px 18px;border-bottom:1px solid var(--border);align-items:center}
.chip-row .chip-lbl{font-size:10.5px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-right:2px}
.chip{display:inline-flex;align-items:center;gap:5px;padding:6px 12px;border-radius:20px;border:1.5px dashed var(--border);
  background:var(--surface);color:var(--navy);font-size:11.5px;font-weight:700;text-decoration:none;transition:all .15s}
.chip:hover{border-color:var(--cyan);border-style:solid;color:var(--blue);background:var(--cyan-soft)}

/* Sticky filter bar */
.explorer-filters{position:sticky;top:58px;z-index:60;background:#fff;padding:12px 18px;border-bottom:1px solid var(--border);
  display:flex;gap:9px;align-items:center;flex-wrap:wrap}
.explorer-filters input[type=text],.explorer-filters input[type=date],.explorer-filters select{
  height:34px;padding:0 11px;background:var(--surface);border:1.5px solid var(--border);border-radius:9px;
  font-family:'Plus Jakarta Sans',sans-serif;font-size:12px;color:var(--ink);outline:none;transition:all .15s}
.explorer-filters input:focus,.explorer-filters select:focus{border-color:var(--cyan);background:#fff}
.ef-search{flex:1;min-width:190px;position:relative}
.ef-search input{width:100%;padding-left:30px}
.ef-search::before{content:'🔍';position:absolute;left:9px;top:50%;transform:translateY(-50%);font-size:10.5px;opacity:.5;pointer-events:none}
.ef-view-toggle{display:flex;border:1.5px solid var(--border);border-radius:9px;overflow:hidden}
.ef-view-btn{height:34px;padding:0 11px;background:#fff;border:none;color:var(--muted);font-size:11.5px;font-weight:750;cursor:pointer;font-family:inherit}
.ef-view-btn.active{background:var(--navy);color:#fff}
.ef-btn{height:34px;padding:0 12px;border-radius:9px;border:1.5px solid var(--border);background:#fff;color:var(--navy);
  font-size:11.5px;font-weight:750;cursor:pointer;font-family:inherit;text-decoration:none;display:inline-flex;align-items:center;gap:5px}
.ef-btn:hover{border-color:var(--cyan);color:var(--blue)}
.ef-btn.primary{background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border-color:transparent}
.explorer-count{padding:8px 18px;font-size:11px;color:var(--muted);border-bottom:1px solid var(--border)}

/* Rich table */
.data-table{width:100%;border-collapse:collapse;font-size:12.5px}
.data-table th{padding:9px 14px;background:var(--surface);border-bottom:1px solid var(--border);font-size:10px;font-weight:750;text-transform:uppercase;letter-spacing:.5px;color:var(--muted);text-align:left;white-space:nowrap}
.data-table td{padding:10px 14px;border-bottom:1px solid #F4F7FC;vertical-align:middle}
.data-table tbody tr{cursor:pointer;transition:background .13s}
.data-table tbody tr:hover{background:#FAFCFF}
.dt-user{display:flex;align-items:center;gap:7px}
.dt-user-av{width:22px;height:22px;border-radius:7px;background:linear-gradient(135deg,var(--cyan),var(--blue));color:#fff;font-size:9px;font-weight:800;display:flex;align-items:center;justify-content:center;flex-shrink:0}
.dt-target{color:var(--muted);font-size:11.5px}
.role-badge{font-size:10.5px;font-weight:750;padding:2px 8px;border-radius:20px;background:var(--surface);color:var(--navy)}
.role-badge.r1{background:#EEF2FF;color:#4338CA}
.role-badge.r2{background:#ECFDF5;color:#047857}
.role-badge.r3{background:#FFF7ED;color:#C2410C}
.role-badge.r0{background:var(--surface);color:var(--muted)}
.badge{display:inline-flex;align-items:center;gap:4px;padding:3px 10px;border-radius:20px;font-size:11px;font-weight:750}
.badge.s-critical{background:var(--sev-critical-bg);color:var(--sev-critical-c)}
.badge.s-warning{background:#FFFBEB;color:#B45309}
.badge.s-info{background:#EFF6FF;color:#1D4ED8}
.badge.s-success{background:#F0FDF4;color:#047857}
.badge.s-neutral{background:var(--surface);color:var(--muted)}

/* Timeline view */
.tl-group{border-bottom:1px solid var(--border)}
.tl-group:last-child{border-bottom:none}
.tl-group-head{display:flex;align-items:center;gap:8px;padding:11px 18px;background:var(--surface);cursor:pointer;user-select:none}
.tl-group-head:hover{background:#EAF0F9}
.tl-group-head .arrow{font-size:10px;color:var(--muted);transition:transform .18s}
.tl-group.collapsed .arrow{transform:rotate(-90deg)}
.tl-group-title{font-size:12px;font-weight:800;color:var(--navy)}
.tl-group-count{font-size:11px;color:var(--muted);font-weight:650}
.tl-group-body{max-height:2000px;overflow:hidden;transition:max-height .22s ease}
.tl-group.collapsed .tl-group-body{max-height:0}

.pagination{display:flex;align-items:center;justify-content:space-between;padding:14px 18px}
.pagination-info{font-size:12px;color:var(--muted)}
.pagination-btns{display:flex;gap:5px}
.page-btn{min-width:32px;height:32px;padding:0 6px;border-radius:8px;display:inline-flex;align-items:center;justify-content:center;font-size:12.5px;font-weight:750;text-decoration:none;color:var(--navy);background:var(--surface);border:1.5px solid var(--border);transition:all .15s}
.page-btn:hover{border-color:var(--cyan);color:var(--blue)}
.page-btn.active{background:var(--blue);border-color:var(--blue);color:#fff}
.page-btn.disabled{opacity:.4;pointer-events:none}

/* ══ Detail Drawer (500px) ══ */
.drawer-backdrop{position:fixed;inset:0;background:rgba(11,22,40,.42);z-index:300;opacity:0;visibility:hidden;transition:opacity .2s}
.drawer-backdrop.open{opacity:1;visibility:visible}
.log-drawer{position:fixed;top:0;right:0;bottom:0;width:min(500px,92vw);background:#fff;z-index:301;
  box-shadow:-12px 0 40px rgba(15,38,69,.18);transform:translateX(100%);transition:transform .24s cubic-bezier(.2,.8,.2,1);
  display:flex;flex-direction:column;overflow-y:auto}
.log-drawer.open{transform:translateX(0)}
.dl-head{background:linear-gradient(135deg,var(--navy),var(--blue));padding:20px;color:#fff;position:sticky;top:0;z-index:2}
.dl-head-top{display:flex;align-items:center;justify-content:space-between;margin-bottom:14px}
.dl-nav{display:flex;gap:6px}
.dl-nav button{width:28px;height:28px;border-radius:8px;background:rgba(255,255,255,.14);border:none;color:#fff;font-size:12px;cursor:pointer}
.dl-nav button:hover{background:rgba(255,255,255,.24)}
.dl-nav button:disabled{opacity:.3;cursor:default}
.dl-close{width:30px;height:30px;border-radius:9px;background:rgba(255,255,255,.14);border:none;color:#fff;font-size:13px;cursor:pointer}
.dl-close:hover{background:rgba(255,255,255,.24)}
.dl-user{display:flex;align-items:center;gap:12px}
.dl-avatar{width:44px;height:44px;border-radius:12px;background:rgba(255,255,255,.16);display:flex;align-items:center;justify-content:center;font-size:15px;font-weight:800;flex-shrink:0}
.dl-uname{font-size:15px;font-weight:800}
.dl-urole{font-size:11.5px;color:rgba(255,255,255,.7);margin-top:2px}
.dl-toolbar{display:flex;gap:8px;margin-top:14px}
.dl-toolbar button{flex:1;height:32px;border-radius:9px;background:rgba(255,255,255,.14);border:none;color:#fff;font-size:11.5px;font-weight:750;cursor:pointer;font-family:inherit;display:flex;align-items:center;justify-content:center;gap:6px;transition:background .15s}
.dl-toolbar button:hover{background:rgba(255,255,255,.24)}
.dl-body{padding:18px 20px}
.dl-sec{margin-bottom:20px}
.dl-sec:last-child{margin-bottom:0}
.dl-sec-title{font-size:11px;font-weight:800;color:var(--muted);text-transform:uppercase;letter-spacing:.5px;margin-bottom:10px}
.dl-kv-card{background:var(--surface);border:1px solid var(--border);border-radius:14px;overflow:hidden}
.dl-kv-row{display:flex;justify-content:space-between;gap:14px;padding:10px 14px;border-bottom:1px solid rgba(213,224,240,.6)}
.dl-kv-row:last-child{border-bottom:none}
.dl-kv-k{font-size:12px;color:var(--muted);font-weight:650;flex-shrink:0}
.dl-kv-v{font-size:12.5px;color:var(--ink);font-weight:750;text-align:right}
.dl-desc-box{background:var(--surface);border:1px solid var(--border);border-radius:12px;padding:12px 14px;font-size:12.5px;color:var(--ink);line-height:1.6}
.dl-unavail{background:#F8FAFC;border:1px dashed var(--border);border-radius:12px;padding:12px 14px;font-size:11.5px;color:var(--muted);line-height:1.6}
.dl-related-item{display:flex;align-items:center;gap:10px;padding:9px 0;border-bottom:1px solid #F4F7FC;cursor:pointer}
.dl-related-item:last-child{border-bottom:none}
.dl-related-item:hover .dl-related-title{color:var(--blue)}
.dl-related-title{font-size:12.5px;font-weight:700;color:var(--ink);transition:color .14s}
.dl-related-time{font-size:11px;color:var(--muted);margin-top:1px}

/* ══ Advanced Search modal ══ */
.modal-backdrop{position:fixed;inset:0;background:rgba(11,22,40,.42);z-index:320;opacity:0;visibility:hidden;transition:opacity .2s;display:flex;align-items:flex-start;justify-content:center;padding:8vh 20px}
.modal-backdrop.open{opacity:1;visibility:visible}
.adv-modal{background:#fff;border-radius:18px;width:min(620px,94vw);box-shadow:0 24px 64px rgba(15,38,69,.24);
  transform:translateY(-16px);transition:transform .2s;max-height:82vh;overflow-y:auto}
.modal-backdrop.open .adv-modal{transform:translateY(0)}
.adv-head{display:flex;align-items:center;justify-content:space-between;padding:18px 22px;border-bottom:1px solid var(--border)}
.adv-head h3{font-family:'Lora',serif;font-size:17px;font-weight:750;color:var(--ink)}
.adv-head p{font-size:11.5px;color:var(--muted);margin-top:2px}
.adv-close{width:30px;height:30px;border-radius:9px;background:var(--surface);border:none;color:var(--muted);font-size:13px;cursor:pointer;flex-shrink:0}
.adv-close:hover{background:var(--border)}
.adv-body{padding:18px 22px}
.adv-grid{display:grid;grid-template-columns:1fr 1fr;gap:12px}
.adv-field{display:flex;flex-direction:column;gap:5px}
.adv-field.full{grid-column:1/-1}
.adv-field label{font-size:11px;font-weight:750;color:var(--navy)}
.adv-field input,.adv-field select{height:38px;padding:0 12px;background:var(--surface);border:1.5px solid var(--border);border-radius:9px;font-family:inherit;font-size:12.5px;color:var(--ink);outline:none}
.adv-field input:focus,.adv-field select:focus{border-color:var(--cyan);background:#fff}
.adv-note{background:var(--cyan-soft);border:1px dashed var(--cyan);border-radius:12px;padding:11px 14px;font-size:11.5px;color:var(--navy);line-height:1.6;margin-top:14px}
.adv-foot{display:flex;justify-content:flex-end;gap:8px;padding:16px 22px;border-top:1px solid var(--border)}

@media(max-width:900px){
  .log-drawer{width:100vw}
  .explorer-filters{position:static}
  .kpi-strip{grid-template-columns:repeat(2,1fr)}
  .ic-row2-h{height:auto}
  .ic-scroll{max-height:400px}
}
</style>
<meta name="csrf-token" content="${csrfToken}">
<script src="${pageContext.request.contextPath}/js/csrf.js"></script>
</head>
<body>

<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">
  <header class="topbar">
    <span class="topbar-title">🛡️ Audit Center</span>
    <div class="topbar-right">
      <div class="topbar-clock">
        <span id="clockH">00</span><span class="clock-sep">:</span><span id="clockM">00</span>
        <span class="clock-date" id="clockDate"></span>
      </div>
      <div class="notif-wrap">
        <button class="topbar-icon-btn" onclick="toggleNotif()" title="Thông báo">
          🔔
          <% int totalNotif = expiryCount + pendingResetCount; %>
          <% if (totalNotif > 0) { %><span class="topbar-notif-badge"><%= totalNotif > 9 ? "9+" : totalNotif %></span><% } %>
        </button>
        <div class="notif-dropdown" id="notifDropdown">
          <div class="notif-head"><span class="notif-head-title">🔔 Thông báo</span><button class="notif-clear" onclick="closeNotif()">Đóng ✕</button></div>
          <div class="notif-list">
            <% for (com.medicare.entity.PasswordResetRequest pr : pendingResets) {
                   com.medicare.entity.Account staffPr = resetAccountMap.get(pr.getAccountId());
                   java.lang.String staffPrName = staffPr != null ? staffPr.getFullName() : ("ID " + pr.getAccountId());
                   java.lang.String staffPrUser = staffPr != null ? staffPr.getUsername() : "";
            %>
            <a href="<%= request.getContextPath() %>/accounts?action=edit&id=<%= pr.getAccountId() %>" class="notif-item" style="text-decoration:none;display:flex;background:rgba(245,158,11,.06);border-left:3px solid #F59E0B">
              <div class="notif-dot" style="background:#D97706"></div>
              <div style="flex:1"><div class="notif-text">🔐 <strong><%= staffPrName %></strong> yêu cầu đổi mật khẩu</div><div class="notif-time">@<%= staffPrUser %> · Bấm để đặt mật khẩu mới</div></div>
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

  <div class="content">

    <%-- ══════════════════ HEADER — title + top-right actions ══════════════════ --%>
    <div class="ic-header">
      <div>
        <div class="breadcrumb">medicare › Phân tích › Audit Center</div>
        <h1>Audit Center</h1>
        <p>Hoạt động hệ thống, sự kiện bảo mật, nhật ký nghiệp vụ và thao tác người dùng.</p>
      </div>
      <div class="ic-actions">
        <button type="button" class="ic-live-btn" id="liveBtn" onclick="toggleLive()"><span class="dot"></span>Trực tiếp
          <span class="ic-new-badge" id="liveNewBadge" onclick="event.stopPropagation();location.reload()">+0</span>
        </button>
        <div class="ic-export-wrap">
          <button type="button" class="ic-btn" onclick="toggleExportMenu()">⬇️ Xuất dữ liệu</button>
          <div class="ic-export-menu" id="exportMenu">
            <a href="${pageContext.request.contextPath}/audit-logs?action=export<%= explorerQS(searchKeyword, filterFrom, filterTo, fRole, fModule, fSeverity, fAccount, fIp, 1) %>">📄 CSV</a>
            <a href="${pageContext.request.contextPath}/audit-logs?action=export&format=json<%= explorerQS(searchKeyword, filterFrom, filterTo, fRole, fModule, fSeverity, fAccount, fIp, 1) %>">🧾 JSON</a>
            <a href="${pageContext.request.contextPath}/audit-logs?action=export&format=xls<%= explorerQS(searchKeyword, filterFrom, filterTo, fRole, fModule, fSeverity, fAccount, fIp, 1) %>">📊 Excel</a>
            <a href="javascript:void(0)" onclick="printPdf()">🖨️ PDF (in trang)</a>
            <div class="hint">Xuất theo đúng bộ lọc đang áp dụng, tối đa 5.000 dòng/lượt.</div>
          </div>
        </div>
        <button type="button" class="ic-btn" onclick="setExplorerView('timeline');document.getElementById('explorerAnchor').scrollIntoView({behavior:'smooth'})">🕒 Dòng thời gian</button>
        <button type="button" class="ic-btn primary" onclick="openAdvSearch()">🔎 Tìm kiếm nâng cao</button>
      </div>
    </div>

    <%-- ══════════════════ ROW 1 — KPI strip (90px) ══════════════════ --%>
    <div class="kpi-strip">
      <div class="kpi-card"><div class="kpi-num" id="kpiTotalNum"><%= kpiTotal %></div><div class="kpi-lbl">Tổng số sự kiện</div></div>
      <div class="kpi-card k-critical"><div class="kpi-num"><%= kpiCritical %></div><div class="kpi-lbl">Nghiêm trọng hôm nay</div></div>
      <div class="kpi-card k-warning"><div class="kpi-num"><%= kpiWarning %></div><div class="kpi-lbl">Cảnh báo hôm nay</div></div>
      <div class="kpi-card"><div class="kpi-num"><%= kpiToday %></div><div class="kpi-lbl">Hoạt động hôm nay</div></div>
      <div class="kpi-card k-users"><div class="kpi-num"><%= kpiUsers %></div><div class="kpi-lbl">Người dùng hoạt động hôm nay</div></div>
    </div>

    <%-- ══════════════════ ROW 2 — Timeline 65% + widget rail 35% ══════════════════ --%>
    <div class="ic-row2">
      <div class="ic-card ic-row2-h">
        <div class="ic-card-head"><h3>🕒 Hoạt động gần đây</h3><span class="cnt">20 mới nhất</span>
          <button type="button" class="jump" onclick="document.getElementById('explorerAnchor').scrollIntoView({behavior:'smooth'})">Mở Audit Explorer →</button>
        </div>
        <div class="ic-scroll" id="recentFeed"></div>
      </div>
      <div class="ic-rail ic-row2-h">
        <div class="ic-widget">
          <div class="ic-widget-title">🛡️ Tổng quan bảo mật (hôm nay)</div>
          <c:set var="sevMax" value="1"/>
          <c:forEach var="e" items="${severityToday}"><c:if test="${e.value > sevMax}"><c:set var="sevMax" value="${e.value}"/></c:if></c:forEach>
          <c:forEach var="e" items="${severityToday}">
            <c:set var="sevColor" value="#7A90B0"/>
            <c:if test="${e.key == 'critical'}"><c:set var="sevColor" value="#DC2626"/></c:if>
            <c:if test="${e.key == 'warning'}"><c:set var="sevColor" value="#D97706"/></c:if>
            <c:if test="${e.key == 'info'}"><c:set var="sevColor" value="#1558A8"/></c:if>
            <c:if test="${e.key == 'success'}"><c:set var="sevColor" value="#059669"/></c:if>
            <c:set var="sevLbl" value="Khác"/>
            <c:if test="${e.key == 'critical'}"><c:set var="sevLbl" value="Nghiêm trọng"/></c:if>
            <c:if test="${e.key == 'warning'}"><c:set var="sevLbl" value="Cảnh báo"/></c:if>
            <c:if test="${e.key == 'info'}"><c:set var="sevLbl" value="Thông tin"/></c:if>
            <c:if test="${e.key == 'success'}"><c:set var="sevLbl" value="Thành công"/></c:if>
            <div class="sev-bar-row"><span class="lbl">${sevLbl}</span>
              <div class="sev-bar-track"><span class="sev-bar-fill" style="width:${sevMax>0 ? (e.value*100/sevMax) : 0}%;background:${sevColor}"></span></div>
              <span class="val">${e.value}</span></div>
          </c:forEach>
        </div>
        <div class="ic-widget">
          <div class="ic-widget-title">🗂️ Phân bố theo module</div>
          <c:set var="maxM" value="1"/>
          <c:forEach var="e" items="${moduleCounts}"><c:if test="${e.value > maxM}"><c:set var="maxM" value="${e.value}"/></c:if></c:forEach>
          <c:set var="anyMod" value="false"/>
          <c:forEach var="e" items="${moduleCounts}">
            <c:if test="${e.value > 0}">
              <c:set var="anyMod" value="true"/>
              <div class="stat-row"><span class="name">${moduleTabs[e.key]}</span>
                <div class="stat-bar"><i style="width:${maxM>0 ? (e.value*100/maxM) : 0}%"></i></div><span class="val">${e.value}</span></div>
            </c:if>
          </c:forEach>
          <c:if test="${!anyMod}"><div class="stat-empty">Chưa có dữ liệu.</div></c:if>
        </div>
        <div class="ic-widget">
          <div class="ic-widget-title">🏆 Người dùng hoạt động nhiều nhất</div>
          <c:choose>
            <c:when test="${empty topUsers}"><div class="stat-empty">Chưa có dữ liệu.</div></c:when>
            <c:otherwise>
              <c:set var="maxU" value="0"/>
              <c:forEach var="e" items="${topUsers}"><c:if test="${e.value > maxU}"><c:set var="maxU" value="${e.value}"/></c:if></c:forEach>
              <c:forEach var="e" items="${topUsers}" varStatus="st">
                <div class="stat-row"><span class="rank">#${st.index+1}</span><span class="name">${fn:escapeXml(e.key)}</span>
                  <div class="stat-bar"><i style="width:${maxU>0 ? (e.value*100/maxU) : 0}%"></i></div><span class="val">${e.value}</span></div>
              </c:forEach>
            </c:otherwise>
          </c:choose>
        </div>
        <div class="ic-widget">
          <div class="ic-widget-title">🌐 IP xuất hiện nhiều nhất</div>
          <c:choose>
            <c:when test="${empty topIps}"><div class="stat-empty">Chưa có dữ liệu.</div></c:when>
            <c:otherwise>
              <c:set var="maxIp" value="0"/>
              <c:forEach var="e" items="${topIps}"><c:if test="${e.value > maxIp}"><c:set var="maxIp" value="${e.value}"/></c:if></c:forEach>
              <c:forEach var="e" items="${topIps}" varStatus="st">
                <div class="stat-row"><span class="rank">#${st.index+1}</span><span class="name">${fn:escapeXml(e.key)}</span>
                  <div class="stat-bar"><i style="width:${maxIp>0 ? (e.value*100/maxIp) : 0}%"></i></div><span class="val">${e.value}</span></div>
              </c:forEach>
            </c:otherwise>
          </c:choose>
        </div>
        <div class="ic-widget">
          <div class="ic-widget-title">⏰ Hoạt động theo giờ (hôm nay)</div>
          <div class="stat-hours">
            <c:set var="maxH" value="1"/>
            <c:forEach var="h" items="${hourlyToday}"><c:if test="${h > maxH}"><c:set var="maxH" value="${h}"/></c:if></c:forEach>
            <c:forEach var="h" items="${hourlyToday}" varStatus="st">
              <div class="stat-hbar-wrap" title="${st.index}h: ${h}"><div class="stat-hbar" style="height:${h>0 ? (h*40/maxH)+3 : 2}px"></div></div>
            </c:forEach>
          </div>
        </div>
      </div>
    </div>

    <%-- ══════════════════ AUDIT EXPLORER ══════════════════ --%>
    <div class="section-title" id="explorerAnchor">🔍 Audit Explorer <span class="cnt"><%= explorerTotal %> bản ghi</span></div>
    <div class="explorer-wrap">

      <%-- Role tabs --%>
      <div class="tab-row" id="roleTabs">
        <a class="etab <%= fRole == null ? "active" : "" %>" href="?<%= explorerQS(searchKeyword, filterFrom, filterTo, null, fModule, fSeverity, fAccount, fIp, 1).replaceFirst("&","") %>">Tất cả <span class="n"><%= explorerTotal %></span></a>
        <a class="etab <%= fRole != null && fRole == 1 ? "active" : "" %>" href="?<%= explorerQS(searchKeyword, filterFrom, filterTo, 1, fModule, fSeverity, fAccount, fIp, 1).replaceFirst("&","") %>">🛡️ Quản trị viên <span class="n"><%= roleCounts.getOrDefault(1,0) %></span></a>
        <a class="etab <%= fRole != null && fRole == 2 ? "active" : "" %>" href="?<%= explorerQS(searchKeyword, filterFrom, filterTo, 2, fModule, fSeverity, fAccount, fIp, 1).replaceFirst("&","") %>">💊 Dược sĩ <span class="n"><%= roleCounts.getOrDefault(2,0) %></span></a>
        <a class="etab <%= fRole != null && fRole == 3 ? "active" : "" %>" href="?<%= explorerQS(searchKeyword, filterFrom, filterTo, 3, fModule, fSeverity, fAccount, fIp, 1).replaceFirst("&","") %>">📦 Thủ kho <span class="n"><%= roleCounts.getOrDefault(3,0) %></span></a>
        <a class="etab <%= fRole != null && fRole == 0 ? "active" : "" %>" href="?<%= explorerQS(searchKeyword, filterFrom, filterTo, 0, fModule, fSeverity, fAccount, fIp, 1).replaceFirst("&","") %>">⚙️ Hệ thống <span class="n"><%= roleCounts.getOrDefault(0,0) %></span></a>
      </div>

      <%-- Module tabs --%>
      <div class="tab-row sub">
        <a class="etab <%= fModule.isEmpty() ? "active" : "" %>" href="?<%= explorerQS(searchKeyword, filterFrom, filterTo, fRole, "", fSeverity, fAccount, fIp, 1).replaceFirst("&","") %>">Mọi module</a>
        <% for (java.util.Map.Entry<String,String> mt : moduleTabs.entrySet()) { %>
        <a class="etab <%= mt.getKey().equals(fModule) ? "active" : "" %>" href="?<%= explorerQS(searchKeyword, filterFrom, filterTo, fRole, mt.getKey(), fSeverity, fAccount, fIp, 1).replaceFirst("&","") %>">
          <%= mt.getValue() %> <span class="n"><%= moduleCounts.getOrDefault(mt.getKey(),0) %></span>
        </a>
        <% } %>
      </div>

      <%-- Saved filter chips — kết hợp bộ lọc thật có sẵn, không bịa field mới --%>
      <div class="chip-row">
        <span class="chip-lbl">Bộ lọc nhanh</span>
        <% java.time.LocalDate todayD = java.time.LocalDate.now();
           java.lang.String todayStr = todayD.toString();
           java.lang.String weekAgoStr = todayD.minusDays(6).toString(); %>
        <a class="chip" href="?<%= explorerQS(searchKeyword, todayStr, todayStr, fRole, fModule, fSeverity, fAccount, fIp, 1).replaceFirst("&","") %>">📅 Hôm nay</a>
        <a class="chip" href="?<%= explorerQS(searchKeyword, weekAgoStr, todayStr, fRole, fModule, fSeverity, fAccount, fIp, 1).replaceFirst("&","") %>">🗓️ 7 ngày qua</a>
        <a class="chip" href="?<%= explorerQS(searchKeyword, filterFrom, filterTo, fRole, fModule, "critical", fAccount, fIp, 1).replaceFirst("&","") %>">🔴 Nghiêm trọng</a>
        <a class="chip" href="?<%= explorerQS(searchKeyword, filterFrom, filterTo, fRole, fModule, "warning", fAccount, fIp, 1).replaceFirst("&","") %>">🟠 Cảnh báo</a>
        <a class="chip" href="?<%= explorerQS(searchKeyword, filterFrom, filterTo, fRole, fModule, fSeverity, currentAdminId, fIp, 1).replaceFirst("&","") %>">🙋 Hoạt động của tôi</a>
      </div>

      <%-- Filter bar (sticky) --%>
      <form method="get" action="${pageContext.request.contextPath}/audit-logs" class="explorer-filters" id="explorerFilterForm">
        <input type="hidden" name="role" value="<%= fRole != null ? fRole : "" %>">
        <input type="hidden" name="module" value="<%= fModule %>">
        <div class="ef-search"><input type="text" name="search" placeholder="Tìm hành động, người dùng, IP, mô tả…" value="<%= searchKeyword %>"></div>
        <input type="date" name="from" value="<%= filterFrom %>" title="Từ ngày">
        <input type="date" name="to" value="<%= filterTo %>" title="Đến ngày">
        <select name="severity" title="Mức độ">
          <option value="">Mọi mức độ</option>
          <option value="critical" <%= "critical".equals(fSeverity)?"selected":"" %>>🔴 Nghiêm trọng</option>
          <option value="warning"  <%= "warning".equals(fSeverity)?"selected":"" %>>🟠 Cảnh báo</option>
          <option value="info"     <%= "info".equals(fSeverity)?"selected":"" %>>🔵 Thông tin</option>
          <option value="success"  <%= "success".equals(fSeverity)?"selected":"" %>>🟢 Thành công</option>
          <option value="neutral"  <%= "neutral".equals(fSeverity)?"selected":"" %>>⚪ Khác</option>
        </select>
        <select name="account" title="Nhân viên">
          <option value="">Mọi nhân viên</option>
          <% for (com.medicare.entity.Account a : auditAccounts) { %>
          <option value="<%= a.getAccountId() %>" <%= fAccount != null && fAccount == a.getAccountId() ? "selected" : "" %>><%= a.getFullName() != null ? a.getFullName() : a.getUsername() %></option>
          <% } %>
        </select>
        <input type="text" name="ip" placeholder="Địa chỉ IP…" value="<%= fIp %>" style="width:120px">
        <button type="submit" class="ef-btn primary">🔍 Lọc</button>
        <% if (!searchKeyword.isEmpty() || !filterFrom.isEmpty() || !filterTo.isEmpty() || !fSeverity.isEmpty() || fAccount != null || !fIp.isEmpty()) { %>
        <a class="ef-btn" href="?<%= explorerQS(null,null,null,fRole,fModule,null,null,null,1).replaceFirst("&","") %>">✕ Xóa lọc</a>
        <% } %>
        <div class="ef-view-toggle">
          <button type="button" class="ef-view-btn active" id="btnTableView" onclick="setExplorerView('table')">📋 Bảng</button>
          <button type="button" class="ef-view-btn" id="btnTimelineView" onclick="setExplorerView('timeline')">🕒 Dòng thời gian</button>
        </div>
      </form>

      <div class="explorer-count">
        Trang <%= explorerPage %>/<%= explorerPages %> — hiện <%= explorerRows.size() %> / <%= explorerTotal %> bản ghi khớp bộ lọc
        <span style="opacity:.7"> · Trình duyệt/Thiết bị/Trạng thái HTTP chưa được ghi log nên không lọc được theo các trường này.</span>
      </div>

      <div id="explorerTableView"><div class="table-wrap" style="overflow-x:auto"><table class="data-table" id="explorerTable">
        <thead><tr><th>Mức độ</th><th>Sự kiện</th><th>Người dùng</th><th>Vai trò</th><th>Module</th><th>Đối tượng</th><th>IP</th><th>Thời gian</th><th></th></tr></thead>
        <tbody id="explorerTbody"></tbody>
      </table></div></div>
      <div id="explorerTimelineView" style="display:none"></div>

      <c:if test="${empty explorerRows}">
        <div class="ac-empty"><div class="icon">🔍</div><p>Không có nhật ký nào khớp bộ lọc hiện tại.</p></div>
      </c:if>

      <c:if test="${not empty explorerRows}">
      <div class="pagination">
        <div class="pagination-info">Trang <%= explorerPage %> / <%= explorerPages %> (<%= explorerTotal %> bản ghi, 30/trang)</div>
        <div class="pagination-btns">
          <a class="page-btn <%= explorerPage <= 1 ? "disabled" : "" %>" href="?<%= explorerQS(searchKeyword,filterFrom,filterTo,fRole,fModule,fSeverity,fAccount,fIp,explorerPage-1).replaceFirst("&","") %>">‹</a>
          <% int ps=Math.max(1,explorerPage-2), pe=Math.min(explorerPages,explorerPage+2);
             for (int p=ps;p<=pe;p++) { %>
          <a class="page-btn <%= p==explorerPage?"active":"" %>" href="?<%= explorerQS(searchKeyword,filterFrom,filterTo,fRole,fModule,fSeverity,fAccount,fIp,p).replaceFirst("&","") %>"><%= p %></a>
          <% } %>
          <a class="page-btn <%= explorerPage >= explorerPages ? "disabled" : "" %>" href="?<%= explorerQS(searchKeyword,filterFrom,filterTo,fRole,fModule,fSeverity,fAccount,fIp,explorerPage+1).replaceFirst("&","") %>">›</a>
        </div>
      </div>
      </c:if>
    </div>

  </div>
</div>

<%-- ══════════════════ Detail Drawer (500px) ══════════════════ --%>
<div class="drawer-backdrop" id="logDrawerBackdrop" onclick="closeLogDrawer()"></div>
<aside class="log-drawer" id="logDrawer">
  <div class="dl-head">
    <div class="dl-head-top">
      <span style="font-size:11px;font-weight:750;color:rgba(255,255,255,.6);text-transform:uppercase;letter-spacing:.5px">Chi tiết sự kiện</span>
      <div class="dl-nav">
        <button type="button" id="dlPrevBtn" onclick="navLogDrawer('prev')" title="Sự kiện trước">‹</button>
        <button type="button" id="dlNextBtn" onclick="navLogDrawer('next')" title="Sự kiện sau">›</button>
        <button type="button" class="dl-close" onclick="closeLogDrawer()" title="Đóng" aria-label="Đóng">✕</button>
      </div>
    </div>
    <div class="dl-user">
      <div class="dl-avatar" id="dlAvatar">?</div>
      <div><div class="dl-uname" id="dlUname">—</div><div class="dl-urole" id="dlUrole">—</div></div>
    </div>
    <div class="dl-toolbar">
      <button type="button" onclick="copyLogJson()">📋 Copy JSON</button>
      <button type="button" onclick="downloadLogJson()">⬇️ Download</button>
    </div>
  </div>
  <div class="dl-body">
    <div class="dl-sec"><div class="dl-sec-title">Mô tả hành động</div><div class="dl-desc-box" id="dlDesc">—</div></div>
    <div class="dl-sec"><div class="dl-sec-title">Thông tin sự kiện</div>
      <div class="dl-kv-card">
        <div class="dl-kv-row"><span class="dl-kv-k">Mã nhật ký</span><span class="dl-kv-v" id="dlId">—</span></div>
        <div class="dl-kv-row"><span class="dl-kv-k">Mức độ</span><span class="dl-kv-v" id="dlSev">—</span></div>
        <div class="dl-kv-row"><span class="dl-kv-k">Vai trò / Phòng ban</span><span class="dl-kv-v" id="dlRole">—</span></div>
        <div class="dl-kv-row"><span class="dl-kv-k">Module</span><span class="dl-kv-v" id="dlModule">—</span></div>
        <div class="dl-kv-row"><span class="dl-kv-k">Đối tượng (Entity ID)</span><span class="dl-kv-v" id="dlEntity">—</span></div>
        <div class="dl-kv-row"><span class="dl-kv-k">Địa chỉ IP</span><span class="dl-kv-v" id="dlIp">—</span></div>
        <div class="dl-kv-row"><span class="dl-kv-k">Thời gian</span><span class="dl-kv-v" id="dlTime">—</span></div>
      </div>
    </div>
    <div class="dl-sec"><div class="dl-sec-title">Old Value / New Value</div>
      <div class="dl-unavail">Bảng AuditLog hiện chỉ có 1 trường Description tự do, chưa lưu snapshot trước/sau mỗi thao tác — cần bổ sung tầng ghi log có cấu trúc ở backend nếu muốn hiện đầy đủ như CloudTrail/GitHub Audit Log.</div>
    </div>
    <div class="dl-sec"><div class="dl-sec-title">Trình duyệt / Thiết bị / Request</div>
      <div class="dl-unavail">Hệ thống chưa ghi lại Browser, OS, Device, Request URL, HTTP Method, Session ID hay thời gian thực thi cho mỗi thao tác — chỉ có IP và thời gian.</div>
    </div>
    <div class="dl-sec"><div class="dl-sec-title">Nhật ký liên quan — cùng người dùng</div><div id="dlRelated"></div></div>
  </div>
</aside>

<%-- ══════════════════ Advanced Search modal ══════════════════ --%>
<div class="modal-backdrop" id="advBackdrop" onclick="if(event.target===this)closeAdvSearch()">
  <div class="adv-modal">
    <div class="adv-head">
      <div><h3>🔎 Tìm kiếm nâng cao</h3><p>Kết hợp nhiều điều kiện cùng lúc — mọi điều kiện được nối bằng AND.</p></div>
      <button type="button" class="adv-close" onclick="closeAdvSearch()">✕</button>
    </div>
    <form method="get" action="${pageContext.request.contextPath}/audit-logs" class="adv-body" id="advSearchForm">
      <input type="hidden" name="role" value="<%= fRole != null ? fRole : "" %>">
      <input type="hidden" name="module" value="<%= fModule %>">
      <div class="adv-grid">
        <div class="adv-field full"><label>Từ khóa (khớp chứa — contains)</label>
          <input type="text" name="search" id="advSearch" placeholder="Hành động, người dùng, IP, mô tả…" value="<%= searchKeyword %>"></div>
        <div class="adv-field"><label>Từ ngày</label><input type="date" name="from" id="advFrom" value="<%= filterFrom %>"></div>
        <div class="adv-field"><label>Đến ngày</label><input type="date" name="to" id="advTo" value="<%= filterTo %>"></div>
        <div class="adv-field"><label>Mức độ</label>
          <select name="severity" id="advSeverity">
            <option value="">Mọi mức độ</option>
            <option value="critical" <%= "critical".equals(fSeverity)?"selected":"" %>>🔴 Nghiêm trọng</option>
            <option value="warning"  <%= "warning".equals(fSeverity)?"selected":"" %>>🟠 Cảnh báo</option>
            <option value="info"     <%= "info".equals(fSeverity)?"selected":"" %>>🔵 Thông tin</option>
            <option value="success"  <%= "success".equals(fSeverity)?"selected":"" %>>🟢 Thành công</option>
            <option value="neutral"  <%= "neutral".equals(fSeverity)?"selected":"" %>>⚪ Khác</option>
          </select>
        </div>
        <div class="adv-field"><label>Nhân viên</label>
          <select name="account" id="advAccount">
            <option value="">Mọi nhân viên</option>
            <% for (com.medicare.entity.Account a : auditAccounts) { %>
            <option value="<%= a.getAccountId() %>" <%= fAccount != null && fAccount == a.getAccountId() ? "selected" : "" %>><%= a.getFullName() != null ? a.getFullName() : a.getUsername() %></option>
            <% } %>
          </select>
        </div>
        <div class="adv-field"><label>Địa chỉ IP</label><input type="text" name="ip" id="advIp" placeholder="VD: 192.168.1.3" value="<%= fIp %>"></div>
      </div>
      <div class="adv-note">Tìm kiếm nâng cao hiện hỗ trợ khớp <b>chứa (contains)</b> trên Hành động/Module/Mô tả/Người dùng, kết hợp <b>AND</b> với Mức độ, Nhân viên, IP và khoảng ngày. Hệ thống chưa hỗ trợ equals/startsWith/endsWith/OR/NOT vì tầng lọc hiện dùng SQL LIKE trên các cột thật — muốn có toán tử đầy đủ cần một tầng query-builder riêng ở backend.</div>
    </form>
    <div class="adv-foot">
      <button type="button" class="ic-btn" onclick="closeAdvSearch()">Hủy</button>
      <button type="submit" form="advSearchForm" class="ic-btn primary">🔍 Áp dụng tìm kiếm</button>
    </div>
  </div>
</div>

<script>
const CTX = '<%= request.getContextPath() %>';
const REP_ROLE_LABEL = { 1:'Quản trị viên', 2:'Dược sĩ', 3:'Thủ kho', 0:'Hệ thống' };
const SEV_ICON = { critical:'🔴', warning:'🟠', info:'🔵', success:'🟢', neutral:'⚪' };
const SEV_LABEL = { critical:'Nghiêm trọng', warning:'Cảnh báo', info:'Thông tin', success:'Thành công', neutral:'Khác' };
const ACCOUNT_ROLE_MAP = {
<%
  boolean rmf = true;
  for (java.util.Map.Entry<Integer,Integer> e : accountRoleMap.entrySet()) {
    if (!rmf) out.print(","); rmf = false;
    out.print(e.getKey() + ":" + e.getValue());
  }
%>
};

function esc(s) { return String(s == null ? '' : s).replace(/[&<>"']/g, c => ({ '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;' }[c])); }
function roleOf(accountId) { return accountId != null && ACCOUNT_ROLE_MAP.hasOwnProperty(accountId) ? ACCOUNT_ROLE_MAP[accountId] : null; }
function roleClass(r) { return 'role-badge r' + (r == null ? '0' : r); }
function roleLabel(r) { return r == null ? '—' : (REP_ROLE_LABEL[r] || '—'); }

// ══ Recent Activity (Row 2 trái) — 20 dòng, dạng dòng thời gian ══
const RECENT_ROWS = [
<%
  java.time.format.DateTimeFormatter dtf = java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm:ss");
  boolean rf = true;
  for (com.medicare.entity.AuditLog log : recentRows) {
    if (!rf) out.print(",\n"); rf = false;
    String act = log.getAction() != null ? log.getAction() : "";
%>{"id":<%= log.getLogId() %>,"action":<%= jsStr(act) %>,"entityType":<%= jsStr(log.getEntityType()) %>,"entityId":<%= log.getEntityId() != null ? log.getEntityId() : "null" %>,"accountId":<%= log.getAccountId() != null ? log.getAccountId() : "null" %>,"username":<%= jsStr(log.getUsername()) %>,"ip":<%= jsStr(ipLabel(log.getIpAddress())) %>,"sev":<%= jsStr(sevOf(act)) %>,"time":<%= jsStr(log.getCreatedAt() != null ? log.getCreatedAt().format(dtf) : "") %>,"iso":<%= jsStr(log.getCreatedAt() != null ? log.getCreatedAt().toString() : null) %>}<%
  }
%>
];

function renderRecentFeed() {
  const box = document.getElementById('recentFeed');
  if (!RECENT_ROWS.length) { box.innerHTML = '<div class="ac-empty"><div class="icon">📋</div><p>Chưa có nhật ký nào.</p></div>'; return; }
  box.innerHTML = RECENT_ROWS.map(l => acRowHtml(l)).join('');
}
function acRowHtml(l, flash) {
  return '<div class="ac-row' + (flash ? ' new-flash' : '') + '" data-id="' + l.id + '">'
    + '<div class="ac-row-icon s-' + (l.sev||'neutral') + '">' + (SEV_ICON[l.sev]||'•') + '</div>'
    + '<div class="ac-row-main"><div class="ac-row-top"><span class="ac-row-title">' + esc(l.action) + '</span>'
    +   '<span class="ac-row-mod">' + esc(l.entityType||'Khác') + '</span></div>'
    +   '<div class="ac-row-meta"><b>@' + esc(l.username) + '</b></div></div>'
    + '<div class="ac-row-time">' + esc(l.time) + '</div>'
    + '<button type="button" class="ac-row-btn" onclick="openLogDrawer(' + l.id + ')">Xem</button>'
  + '</div>';
}
renderRecentFeed();

// ══ Explorer — trang hiện tại (≤30 dòng), JS render Table/Timeline ══
const EXPLORER_ROWS = [
<%
  boolean ef = true;
  for (com.medicare.entity.AuditLog log : explorerRows) {
    if (!ef) out.print(",\n"); ef = false;
    String act = log.getAction() != null ? log.getAction() : "";
%>{"id":<%= log.getLogId() %>,"action":<%= jsStr(act) %>,"entityType":<%= jsStr(log.getEntityType()) %>,"entityId":<%= log.getEntityId() != null ? log.getEntityId() : "null" %>,"accountId":<%= log.getAccountId() != null ? log.getAccountId() : "null" %>,"description":<%= jsStr(log.getDescription()) %>,"ip":<%= jsStr(ipLabel(log.getIpAddress())) %>,"username":<%= jsStr(log.getUsername()) %>,"sev":<%= jsStr(sevOf(act)) %>,"time":<%= jsStr(log.getCreatedAt() != null ? log.getCreatedAt().format(dtf) : "") %>,"iso":<%= jsStr(log.getCreatedAt() != null ? log.getCreatedAt().toString() : null) %>}<%
  }
%>
];

function dayBucket(iso) {
  if (!iso) return 'older';
  const d = new Date(iso); d.setHours(0,0,0,0);
  const today = new Date(); today.setHours(0,0,0,0);
  const diff = Math.round((today - d) / 86400000);
  if (diff <= 0) return 'today';
  if (diff === 1) return 'yesterday';
  if (diff <= 7) return 'week';
  return 'older';
}
const BUCKET_LABEL = { today:'Hôm nay', yesterday:'Hôm qua', week:'7 ngày qua', older:'Cũ hơn' };

function targetLabel(l) { return l.entityType ? (esc(l.entityType) + (l.entityId != null ? (' #' + l.entityId) : '')) : '—'; }

function renderExplorerTable() {
  const tbody = document.getElementById('explorerTbody');
  tbody.innerHTML = EXPLORER_ROWS.map(l => {
    const r = roleOf(l.accountId);
    return '<tr onclick="openLogDrawer(' + l.id + ')">'
      + '<td><span class="badge s-' + (l.sev||'neutral') + '">' + (SEV_ICON[l.sev]||'•') + ' ' + (SEV_LABEL[l.sev]||'Khác') + '</span></td>'
      + '<td><b>' + esc(l.action) + '</b></td>'
      + '<td><div class="dt-user"><div class="dt-user-av">' + esc((l.username||'?').substring(0,2).toUpperCase()) + '</div>@' + esc(l.username) + '</div></td>'
      + '<td><span class="' + roleClass(r) + '">' + roleLabel(r) + '</span></td>'
      + '<td>' + esc(l.entityType||'—') + '</td>'
      + '<td class="dt-target">' + targetLabel(l) + '</td>'
      + '<td class="dt-target">' + esc(l.ip||'—') + '</td>'
      + '<td>' + esc(l.time) + '</td>'
      + '<td><button type="button" class="ac-row-btn" onclick="event.stopPropagation();openLogDrawer(' + l.id + ')">Xem</button></td>'
    + '</tr>';
  }).join('');
}

const TL_COLLAPSE_KEY = 'auditTimelineCollapse';
function getTlCollapseState() { try { return JSON.parse(localStorage.getItem(TL_COLLAPSE_KEY) || '{}'); } catch(e) { return {}; } }
function setTlCollapseState(s) { try { localStorage.setItem(TL_COLLAPSE_KEY, JSON.stringify(s)); } catch(e) {} }

function renderExplorerTimeline() {
  const box = document.getElementById('explorerTimelineView');
  if (!EXPLORER_ROWS.length) { box.innerHTML = ''; return; }
  const groups = {};
  const order = [];
  EXPLORER_ROWS.forEach(l => {
    const b = dayBucket(l.iso);
    if (!groups[b]) { groups[b] = []; order.push(b); }
    groups[b].push(l);
  });
  const collapseState = getTlCollapseState();
  box.innerHTML = order.map(b => {
    const collapsed = !!collapseState[b];
    const rows = groups[b].map(l =>
      '<div class="ac-row" onclick="openLogDrawer(' + l.id + ')" style="cursor:pointer">'
        + '<div class="ac-row-icon s-' + (l.sev||'neutral') + '">' + (SEV_ICON[l.sev]||'•') + '</div>'
        + '<div class="ac-row-main"><div class="ac-row-top"><span class="ac-row-title">' + esc(l.action) + '</span>'
        +   '<span class="ac-row-mod">' + esc(l.entityType||'Khác') + '</span></div>'
        +   '<div class="ac-row-meta"><b>@' + esc(l.username) + '</b> · ' + esc(l.ip||'—') + '</div></div>'
        + '<div class="ac-row-time">' + esc(l.time) + '</div>'
      + '</div>'
    ).join('');
    return '<div class="tl-group' + (collapsed ? ' collapsed' : '') + '" data-bucket="' + b + '">'
      + '<div class="tl-group-head" onclick="toggleTlGroup(this)">'
        + '<span class="arrow">▼</span><span class="tl-group-title">' + BUCKET_LABEL[b] + '</span>'
        + '<span class="tl-group-count">(' + groups[b].length + ')</span>'
      + '</div>'
      + '<div class="tl-group-body">' + rows + '</div>'
    + '</div>';
  }).join('');
}
function toggleTlGroup(headEl) {
  const g = headEl.closest('.tl-group');
  g.classList.toggle('collapsed');
  const s = getTlCollapseState();
  s[g.dataset.bucket] = g.classList.contains('collapsed');
  setTlCollapseState(s);
}
function setExplorerView(mode) {
  document.getElementById('btnTableView').classList.toggle('active', mode === 'table');
  document.getElementById('btnTimelineView').classList.toggle('active', mode === 'timeline');
  document.getElementById('explorerTableView').style.display = mode === 'table' ? '' : 'none';
  document.getElementById('explorerTimelineView').style.display = mode === 'timeline' ? '' : 'none';
  try { localStorage.setItem('auditExplorerView', mode); } catch(e) {}
}
renderExplorerTable();
renderExplorerTimeline();
try {
  const savedView = localStorage.getItem('auditExplorerView');
  if (savedView === 'timeline') setExplorerView('timeline');
} catch(e) {}

// ══ Detail Drawer ══
let _dlCurrentId = null;
let _dlCurrentData = null;
function openLogDrawer(id) {
  _dlCurrentId = id;
  document.getElementById('logDrawer').classList.add('open');
  document.getElementById('logDrawerBackdrop').classList.add('open');
  document.getElementById('dlDesc').textContent = 'Đang tải…';
  fetch(CTX + '/audit-logs?action=detail&id=' + id)
    .then(r => r.json())
    .then(data => {
      if (!data.ok) { document.getElementById('dlDesc').textContent = 'Không tải được sự kiện này.'; return; }
      _dlCurrentData = data;
      const l = data.log;
      document.getElementById('dlAvatar').textContent = (l.username || '?').substring(0,2).toUpperCase();
      document.getElementById('dlUname').textContent = '@' + (l.username || 'Hệ thống');
      document.getElementById('dlUrole').textContent = (REP_ROLE_LABEL[l.role] || 'Hệ thống') + ' · IP ' + (l.ip || '—');
      document.getElementById('dlDesc').textContent = l.description || l.action || '—';
      document.getElementById('dlId').textContent = '#' + l.id;
      document.getElementById('dlSev').textContent = (SEV_ICON[l.sev]||'') + ' ' + (SEV_LABEL[l.sev]||'Khác');
      document.getElementById('dlRole').textContent = REP_ROLE_LABEL[l.role] || 'Hệ thống';
      document.getElementById('dlModule').textContent = l.entityType || '—';
      document.getElementById('dlEntity').textContent = l.entityId != null ? ('#' + l.entityId) : '—';
      document.getElementById('dlIp').textContent = l.ip || '—';
      document.getElementById('dlTime').textContent = l.time || '—';

      document.getElementById('dlPrevBtn').disabled = !data.prev;
      document.getElementById('dlNextBtn').disabled = !data.next;
      document.getElementById('dlPrevBtn').dataset.id = data.prev ? data.prev.id : '';
      document.getElementById('dlNextBtn').dataset.id = data.next ? data.next.id : '';

      const relBox = document.getElementById('dlRelated');
      relBox.innerHTML = !data.related.length
        ? '<div class="dl-unavail">Không có nhật ký nào khác của người này.</div>'
        : data.related.map(r =>
            '<div class="dl-related-item" onclick="openLogDrawer(' + r.id + ')">'
            + '<div class="ac-row-icon s-' + (r.sev||'neutral') + '" style="width:28px;height:28px;font-size:12px">' + (SEV_ICON[r.sev]||'•') + '</div>'
            + '<div><div class="dl-related-title">' + esc(r.action) + '</div><div class="dl-related-time">' + esc(r.time) + '</div></div>'
            + '</div>'
          ).join('');
    })
    .catch(() => { document.getElementById('dlDesc').textContent = 'Lỗi kết nối.'; });
}
function navLogDrawer(dir) {
  const btn = document.getElementById(dir === 'prev' ? 'dlPrevBtn' : 'dlNextBtn');
  const id = btn.dataset.id;
  if (id) openLogDrawer(parseInt(id));
}
function closeLogDrawer() {
  document.getElementById('logDrawer').classList.remove('open');
  document.getElementById('logDrawerBackdrop').classList.remove('open');
}
function copyLogJson() {
  if (!_dlCurrentData) return;
  navigator.clipboard.writeText(JSON.stringify(_dlCurrentData.log, null, 2)).catch(() => {});
}
function downloadLogJson() {
  if (!_dlCurrentData) return;
  const blob = new Blob([JSON.stringify(_dlCurrentData.log, null, 2)], { type: 'application/json' });
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = 'audit-log-' + _dlCurrentData.log.id + '.json';
  a.click();
  URL.revokeObjectURL(a.href);
}
document.addEventListener('keydown', e => { if (e.key === 'Escape') { closeLogDrawer(); closeAdvSearch(); } });

// ══ Advanced Search modal ══
function openAdvSearch() { document.getElementById('advBackdrop').classList.add('open'); }
function closeAdvSearch() { document.getElementById('advBackdrop').classList.remove('open'); }

// ══ Export dropdown ══
function toggleExportMenu() { document.getElementById('exportMenu').classList.toggle('open'); }
document.addEventListener('click', e => {
  const wrap = document.querySelector('.ic-export-wrap');
  if (wrap && !wrap.contains(e.target)) document.getElementById('exportMenu').classList.remove('open');
});
function printPdf() { document.getElementById('exportMenu').classList.remove('open'); window.print(); }

// ══ Live Mode (polling action=poll) ══
let liveOn = false, liveTimer = null, lastSeenId = 0, newSinceReload = 0;
RECENT_ROWS.forEach(l => { if (l.id > lastSeenId) lastSeenId = l.id; });
function toggleLive() {
  liveOn = !liveOn;
  const btn = document.getElementById('liveBtn');
  btn.classList.toggle('on', liveOn);
  if (liveOn) { pollLive(); liveTimer = setInterval(pollLive, 8000); }
  else { clearInterval(liveTimer); liveTimer = null; }
}
function pollLive() {
  if (!lastSeenId) return;
  fetch(CTX + '/audit-logs?action=poll&sinceId=' + lastSeenId)
    .then(r => r.json())
    .then(data => {
      if (!data.ok || !data.rows.length) return;
      data.rows.forEach(row => {
        const l = { id: row.id, action: row.action, entityType: row.entityType, entityId: row.entityId,
          accountId: row.accountId, username: row.username, sev: row.sev, time: row.time };
        if (l.id > lastSeenId) lastSeenId = l.id;
      });
      const box = document.getElementById('recentFeed');
      box.insertAdjacentHTML('afterbegin', data.rows.map(row => acRowHtml({
        id: row.id, action: row.action, entityType: row.entityType, username: row.username, sev: row.sev, time: row.time
      }, true)).join(''));
      while (box.children.length > 20) box.removeChild(box.lastChild);
      newSinceReload += data.rows.length;
      const badge = document.getElementById('liveNewBadge');
      badge.textContent = '+' + newSinceReload;
      badge.style.display = 'inline-flex';
    })
    .catch(() => {});
}

// ══ Clock + notif dropdown ══
function updateClock() {
  const now = new Date();
  document.getElementById('clockH').textContent = String(now.getHours()).padStart(2,'0');
  document.getElementById('clockM').textContent = String(now.getMinutes()).padStart(2,'0');
  const days = ['CN','T2','T3','T4','T5','T6','T7'];
  document.getElementById('clockDate').textContent = days[now.getDay()] + ', ' + String(now.getDate()).padStart(2,'0') + '/' + String(now.getMonth()+1).padStart(2,'0');
}
updateClock(); setInterval(updateClock, 1000);
function toggleNotif() { document.getElementById('notifDropdown').classList.toggle('open'); }
function closeNotif()  { document.getElementById('notifDropdown').classList.remove('open'); }
document.addEventListener('click', e => {
  const wrap = document.querySelector('.notif-wrap');
  if (wrap && !wrap.contains(e.target)) closeNotif();
});

// Đổi select trong bộ lọc → submit ngay
document.querySelectorAll('#explorerFilterForm select').forEach(s => s.addEventListener('change', () => document.getElementById('explorerFilterForm').submit()));
</script>
</body>
</html>
