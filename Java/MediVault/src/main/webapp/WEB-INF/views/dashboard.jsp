<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>
<%
    com.medivault.entity.Account acc = (com.medivault.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    int roleId = acc.getRoleId();
    java.lang.String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    java.lang.String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();

    // Stats từ DashboardServlet (fallback về 0 nếu chưa có)
    Long todayRevenue  = (Long)   request.getAttribute("todayRevenue");
    Integer todayInvoice = (Integer) request.getAttribute("todayInvoices");
    Integer expiryCount  = (Integer) request.getAttribute("expiryCount");
    Long activeAccountsLong = (Long) request.getAttribute("activeAccounts");
    int activeAccounts = activeAccountsLong != null ? activeAccountsLong.intValue() : 0;
    if (todayRevenue   == null) todayRevenue   = 0L;
    if (todayInvoice   == null) todayInvoice   = 0;
    if (expiryCount    == null) expiryCount    = 0;

    // Trang hiện tại
    java.lang.String currentPage = request.getParameter("view");
    if (currentPage == null) currentPage = "dashboard";
%>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MediVault — Dashboard</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@700;800;900&family=Plus+Jakarta+Sans:ital,wght@0,300;0,400;0,500;0,600;1,300&display=swap" rel="stylesheet">
    <style>
        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        :root {
            --navy-deep:  #101A33;
            --navy-mid:   #1D2D50;
            --blue-main:  #114C7D;
            --cyan-light: #5EC3E4;
            --sky-blue:   #46CAF4;
            --surface:    #F0F4F9;
            --gold:       #FCDA7C;
            --white:      #FFFFFF;
            --border:     #DDE6F0;
            --text-muted: #6B82A0;
            --sidebar-w:  220px;
        }

        html, body { height: 100%; font-family: 'Plus Jakarta Sans', sans-serif; }
        body { display: flex; background: var(--surface); color: var(--navy-deep); overflow-x: hidden; }

        /* ──────────────── SIDEBAR ──────────────── */
        .sidebar {
            width: var(--sidebar-w);
            min-height: 100vh;
            background: linear-gradient(180deg, var(--navy-deep) 0%, #182845 55%, var(--blue-main) 100%);
            display: flex;
            flex-direction: column;
            position: fixed;
            left: 0; top: 0; bottom: 0;
            z-index: 100;
            border-right: .5px solid rgba(255,255,255,.05);
        }

        .sidebar-logo {
            padding: 0 18px;
            height: 60px;
            display: flex;
            align-items: center;
            gap: 10px;
            border-bottom: 1px solid rgba(255,255,255,.07);
        }

        .logo-icon {
            width: 38px; height: 38px;
            background: rgba(70,202,244,.15);
            border: 1.5px solid rgba(70,202,244,.3);
            border-radius: 10px;
            display: flex; align-items: center; justify-content: center;
            font-size: 18px;
        }

        .logo-text {
            font-family: 'Nunito', sans-serif;
            font-size: 17px;
            font-weight: 900;
            color: #fff;
            letter-spacing: -.3px;
            line-height: 1.1;
        }
        .logo-text span { color: var(--sky-blue); }
        .logo-sub {
            font-size: 9.5px;
            font-weight: 400;
            color: rgba(255,255,255,.35);
            letter-spacing: 1px;
            text-transform: uppercase;
        }

        /* Active nav marker */
        .nav-section { padding: 16px 0 8px; }
        .nav-label {
            font-size: 9px;
            font-weight: 700;
            letter-spacing: 1.5px;
            text-transform: uppercase;
            color: rgba(255,255,255,.25);
            padding: 0 18px 8px;
        }

        .nav-item {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 10px 18px;
            margin: 1px 8px;
            border-radius: 10px;
            font-size: 13px;
            font-weight: 500;
            color: rgba(255,255,255,.55);
            text-decoration: none;
            transition: all .18s;
            position: relative;
            cursor: pointer;
        }
        .nav-item:hover { color: #fff; background: rgba(255,255,255,.06); }
        .nav-item.active {
            color: #fff;
            background: rgba(70,202,244,.13);
            font-weight: 600;
        }
        .nav-item.active::before {
            content: '';
            position: absolute;
            left: -8px; top: 50%; transform: translateY(-50%);
            width: 3px; height: 60%;
            background: var(--sky-blue);
            border-radius: 4px;
        }
        .nav-icon {
            width: 18px; height: 18px;
            opacity: .7;
            flex-shrink: 0;
            display: flex; align-items: center; justify-content: center;
            font-size: 14px;
        }
        .nav-item.active .nav-icon { opacity: 1; }

        /* Badge */
        .nav-badge {
            margin-left: auto;
            background: #e74c3c;
            color: #fff;
            font-size: 10px;
            font-weight: 700;
            padding: 1px 6px;
            border-radius: 10px;
            min-width: 18px;
            text-align: center;
        }

        /* Sidebar bottom user */
        .sidebar-footer {
            margin-top: auto;
            padding: 16px 18px;
            border-top: 1px solid rgba(255,255,255,.07);
        }
        .sidebar-user {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 8px 10px;
            border-radius: 10px;
            background: rgba(255,255,255,.05);
        }
        .user-avatar-sm {
            width: 32px; height: 32px;
            background: linear-gradient(135deg, var(--sky-blue), var(--blue-main));
            border-radius: 8px;
            display: flex; align-items: center; justify-content: center;
            font-size: 12px;
            font-weight: 800;
            color: #fff;
            flex-shrink: 0;
        }
        .user-info-sm .name {
            font-size: 12.5px;
            font-weight: 600;
            color: #fff;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            max-width: 110px;
        }
        .user-info-sm .role {
            font-size: 10.5px;
            color: rgba(255,255,255,.35);
        }
        .logout-btn {
            margin-left: auto;
            color: rgba(255,255,255,.3);
            text-decoration: none;
            font-size: 13px;
            transition: color .15s;
        }
        .logout-btn:hover { color: #e74c3c; }

        /* ──────────────── MAIN ──────────────── */
        .main {
            margin-left: var(--sidebar-w);
            flex: 1;
            display: flex;
            flex-direction: column;
            min-height: 100vh;
            min-width: 0;
        }

        /* ── TOPBAR ── */
        .topbar {
            height: 64px;
            background: #fff;
            border-bottom: 1px solid var(--border);
            display: flex;
            align-items: center;
            padding: 28px;
            gap: 14px;
            position: sticky; top: 0; z-index: 50;
            box-shadow: 0 1px 6px rgba(0,0,0,.04);
        }
        .topbar-title {
            font-family: 'Nunito', sans-serif;
            font-size: 16px; font-weight: 800;
            color: var(--navy-deep);
            flex-shrink: 0;
        }

        .topbar-search {
            flex: 1;
            max-width: 300px;
            min-width: 120px;
            position: relative;
        }
        .topbar-search input {
            width: 100%;
            height: 36px;
            padding: 0 36px 0 14px;
            border: 1.5px solid var(--border);
            border-radius: 10px;
            font-size: 13px;
            font-family: inherit;
            color: var(--navy-deep);
            background: var(--surface);
            outline: none;
            transition: border-color .2s;
        }
        .topbar-search input:focus { border-color: var(--sky-blue); }
        .topbar-search::after {
            content: '🔍';
            position: absolute;
            right: 10px; top: 50%; transform: translateY(-50%);
            font-size: 12px;
            pointer-events: none;
        }

        .topbar-right {
            margin-left: auto;
            display: flex;
            align-items: center;
            gap: 10px;
            flex-shrink: 0;
        }

        .topbar-time {
            font-size: 12px;
            color: var(--text-muted);
            font-weight: 500;
        }

        .topbar-clock {
            display: flex; align-items: center; gap: 5px;
            padding: 5px 11px;
            background: var(--surface);
            border: 1.5px solid var(--border);
            border-radius: 12px;
            font-size: 13px; font-weight: 700; font-style: italic;
            color: var(--navy-deep); white-space: nowrap;
        }
        .clock-sep { animation: blink 1s step-end infinite; font-style: normal; }
        @keyframes blink { 0%,100%{opacity:1} 50%{opacity:0} }
        .clock-date {
            font-size: 11px; font-weight: 500; font-style: normal;
            color: var(--text-muted);
            border-left: 1px solid var(--border);
            padding-left: 8px; margin-left: 2px;
        }
        .notif-wrap { position: relative; }
        .notif-dropdown {
            display: none; position: absolute;
            top: calc(100% + 10px); right: 0;
            width: 320px; background: #fff;
            border: 1px solid var(--border); border-radius: 14px;
            box-shadow: 0 12px 40px rgba(0,0,0,.12); z-index: 300; overflow: hidden;
        }
        .notif-dropdown.open { display: block; animation: dropIn .2s ease; }
        @keyframes dropIn { from{opacity:0;transform:translateY(-8px)} to{opacity:1;transform:translateY(0)} }
        .notif-head { display: flex; align-items: center; justify-content: space-between; padding: 13px 16px 10px; border-bottom: 1px solid var(--border); }
        .notif-head-title { font-family: Nunito,sans-serif; font-size: 14px; font-weight: 800; color: var(--navy-deep); }
        .notif-clear { font-size: 11.5px; color: var(--sky-blue); cursor: pointer; font-weight: 600; background: none; border: none; font-family: inherit; }
        .notif-list { max-height: 300px; overflow-y: auto; }
        .notif-item { display: flex; align-items: flex-start; gap: 10px; padding: 11px 16px; border-bottom: 1px solid #f0f4f9; }
        .notif-item:last-child { border-bottom: none; }
        .notif-item:hover { background: #f8fbff; }
        .notif-dot { width: 8px; height: 8px; border-radius: 50%; background: var(--sky-blue); flex-shrink: 0; margin-top: 5px; }
        .notif-dot.old { background: var(--border); }
        .notif-text { font-size: 12.5px; color: var(--navy-deep); font-weight: 500; line-height: 1.4; }
        .notif-time { font-size: 11px; color: var(--text-muted); margin-top: 2px; }
        .topbar-icon-btn {
            width: 36px; height: 36px;
            border: 1.5px solid var(--border);
            border-radius: 10px;
            background: #fff;
            display: flex; align-items: center; justify-content: center;
            cursor: pointer;
            font-size: 14px;
            position: relative;
            text-decoration: none;
            color: inherit;
            transition: background .15s;
        }
        .topbar-icon-btn:hover { background: var(--surface); }
        .topbar-notif-badge {
            position: absolute;
            top: -3px; right: -3px;
            width: 14px; height: 14px;
            background: #e74c3c;
            border-radius: 50%;
            border: 2px solid #fff;
            font-size: 8px;
            color: #fff;
            display: flex; align-items: center; justify-content: center;
            font-weight: 700;
        }

        .topbar-user {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 4px 10px;
            border: 1.5px solid var(--border);
            border-radius: 10px;
            cursor: pointer;
            text-decoration: none;
            color: inherit;
            transition: background .15s;
        }
        .topbar-user:hover { background: var(--surface); }
        .topbar-user-avatar {
            width: 28px; height: 28px;
            background: linear-gradient(135deg, var(--sky-blue), var(--blue-main));
            border-radius: 7px;
            display: flex; align-items: center; justify-content: center;
            font-size: 11px;
            font-weight: 800;
            color: #fff;
        }
        .topbar-user-name {
            font-size: 13px;
            font-weight: 600;
            color: var(--navy-deep);
            max-width: 120px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        /* ── PAGE CONTENT ── */
        .content {
            padding: 28px;
            flex: 1;
        }

        /* Page heading */
        .page-head {
            display: flex;
            align-items: flex-end;
            justify-content: space-between;
            margin-bottom: 24px;
        }
        .page-head-left .breadcrumb {
            font-size: 11.5px;
            color: var(--text-muted);
            font-weight: 500;
            margin-bottom: 4px;
        }
        .page-head-left h1 {
            font-family: 'Nunito', sans-serif;
            font-size: 24px;
            font-weight: 900;
            color: var(--navy-deep);
            letter-spacing: -.4px;
        }
        .btn-primary {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            padding: 10px 20px;
            background: var(--blue-main);
            color: #fff;
            border: none;
            border-radius: 10px;
            font-size: 13.5px;
            font-weight: 600;
            font-family: inherit;
            cursor: pointer;
            text-decoration: none;
            transition: background .2s, transform .1s;
        }
        .btn-primary:hover { background: #0d3d63; }
        .btn-primary:active { transform: scale(.97); }

        /* ── STAT CARDS ── */
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 16px;
            margin-bottom: 24px;
        }

        .stat-card {
            background: #fff;
            border: 1px solid var(--border);
            border-radius: 16px;
            padding: 20px 22px;
            display: flex;
            flex-direction: column;
            gap: 12px;
            transition: box-shadow .2s, transform .2s;
        }
        .stat-card:hover {
            box-shadow: 0 8px 28px rgba(0,0,0,.07);
            transform: translateY(-2px);
        }

        .stat-card-top {
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .stat-label {
            font-size: 12px;
            font-weight: 600;
            color: var(--text-muted);
            text-transform: uppercase;
            letter-spacing: .5px;
        }
        .stat-icon {
            width: 38px; height: 38px;
            border-radius: 10px;
            display: flex; align-items: center; justify-content: center;
            font-size: 17px;
        }
        .stat-icon.blue   { background: rgba(70,202,244,.12); }
        .stat-icon.green  { background: rgba(26,122,74,.1);   }
        .stat-icon.red    { background: rgba(231,76,60,.1);   }
        .stat-icon.gold   { background: rgba(252,218,124,.2); }

        .stat-value {
            font-family: 'Nunito', sans-serif;
            font-size: 26px;
            font-weight: 900;
            color: var(--navy-deep);
            letter-spacing: -.5px;
            line-height: 1;
        }
        .stat-diff {
            font-size: 11.5px;
            font-weight: 500;
            color: var(--text-muted);
            display: flex;
            align-items: center;
            gap: 4px;
        }
        .stat-diff .up   { color: #1a7a4a; }
        .stat-diff .down { color: #e74c3c; }

        /* ── TABLE CARD ── */
        .table-card {
            background: #fff;
            border: 1px solid var(--border);
            border-radius: 16px;
            overflow: hidden;
        }

        .table-card-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 18px 22px 14px;
            border-bottom: 1px solid var(--border);
        }

        .table-card-title {
            font-family: 'Nunito', sans-serif;
            font-size: 16px;
            font-weight: 800;
            color: var(--navy-deep);
        }
        .table-card-subtitle {
            font-size: 12px;
            color: var(--text-muted);
            font-weight: 400;
        }

        .filter-row {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 14px 22px;
            border-bottom: 1px solid var(--border);
            background: #fafcff;
            flex-wrap: wrap;
        }

        .filter-search {
            flex: 1;
            min-width: 200px;
            max-width: 300px;
            position: relative;
        }
        .filter-search input {
            width: 100%;
            height: 34px;
            padding: 0 12px 0 32px;
            border: 1.5px solid var(--border);
            border-radius: 8px;
            font-size: 13px;
            font-family: inherit;
            outline: none;
            transition: border-color .2s;
        }
        .filter-search input:focus { border-color: var(--sky-blue); }
        .filter-search::before {
            content: '🔍';
            position: absolute;
            left: 10px; top: 50%; transform: translateY(-50%);
            font-size: 11px;
        }

        .filter-select {
            height: 34px;
            padding: 0 28px 0 10px;
            border: 1.5px solid var(--border);
            border-radius: 8px;
            font-size: 13px;
            font-family: inherit;
            color: var(--navy-deep);
            background: #fff url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='10' height='6' fill='none'%3E%3Cpath stroke='%236B82A0' stroke-width='1.5' stroke-linecap='round' d='M1 1l4 4 4-4'/%3E%3C/svg%3E") no-repeat right 8px center;
            appearance: none;
            cursor: pointer;
            outline: none;
        }
        .filter-select:focus { border-color: var(--sky-blue); }

        .filter-chip {
            height: 34px;
            padding: 0 14px;
            border: 1.5px solid var(--border);
            border-radius: 8px;
            font-size: 12.5px;
            font-weight: 500;
            color: var(--text-muted);
            background: #fff;
            cursor: pointer;
            transition: all .15s;
            white-space: nowrap;
        }
        .filter-chip:hover, .filter-chip.active {
            background: var(--blue-main);
            border-color: var(--blue-main);
            color: #fff;
        }
        .filter-chip.active-green {
            background: #1a7a4a;
            border-color: #1a7a4a;
            color: #fff;
        }

        /* Table */
        .data-table {
            width: 100%;
            border-collapse: collapse;
        }
        .data-table thead {
            background: #f8fbff;
        }
        .data-table th {
            padding: 11px 16px;
            text-align: left;
            font-size: 11.5px;
            font-weight: 700;
            color: var(--text-muted);
            text-transform: uppercase;
            letter-spacing: .6px;
            border-bottom: 1px solid var(--border);
            white-space: nowrap;
        }
        .data-table td {
            padding: 13px 16px;
            font-size: 13.5px;
            border-bottom: 1px solid #f0f4f9;
            vertical-align: middle;
        }
        .data-table tr:last-child td { border-bottom: none; }
        .data-table tbody tr { transition: background .12s; }
        .data-table tbody tr:hover { background: #f8fbff; }

        /* Cell components */
        .cell-user {
            display: flex;
            align-items: center;
            gap: 10px;
        }
        .cell-avatar {
            width: 32px; height: 32px;
            border-radius: 9px;
            background: linear-gradient(135deg, var(--sky-blue), var(--blue-main));
            display: flex; align-items: center; justify-content: center;
            font-size: 11.5px;
            font-weight: 800;
            color: #fff;
            flex-shrink: 0;
        }
        .cell-user-name {
            font-weight: 600;
            color: var(--navy-deep);
            font-size: 13px;
        }
        .cell-user-sub {
            font-size: 11.5px;
            color: var(--text-muted);
        }

        .badge {
            display: inline-flex;
            align-items: center;
            gap: 4px;
            padding: 3px 9px;
            border-radius: 20px;
            font-size: 11.5px;
            font-weight: 600;
            white-space: nowrap;
        }
        .badge-blue  { background: rgba(70,202,244,.12); color: var(--blue-main); }
        .badge-green { background: rgba(26,122,74,.1);  color: #1a7a4a; }
        .badge-red   { background: rgba(231,76,60,.1);  color: #c0392b; }
        .badge-gold  { background: rgba(252,218,124,.2); color: #b8750a; }

        .badge::before { content: '●'; font-size: 7px; }

        .action-group {
            display: flex;
            gap: 6px;
        }
        .action-btn {
            height: 30px;
            padding: 0 12px;
            border-radius: 7px;
            border: 1.5px solid;
            font-size: 12px;
            font-weight: 600;
            cursor: pointer;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 4px;
            transition: all .15s;
            font-family: inherit;
        }
        .action-btn-edit {
            border-color: var(--border);
            color: var(--navy-deep);
            background: #fff;
        }
        .action-btn-edit:hover { border-color: var(--blue-main); color: var(--blue-main); }
        .action-btn-toggle-off {
            border-color: #f5dfa8;
            color: #b8750a;
            background: #fff8e6;
        }
        .action-btn-toggle-off:hover { background: #ffefc2; }
        .action-btn-toggle-on {
            border-color: #c0d9f0;
            color: var(--blue-main);
            background: #e8f2fc;
        }
        .action-btn-toggle-on:hover { background: #d1e8f8; }

        /* Empty state */
        .empty-state {
            text-align: center;
            padding: 60px 20px;
            color: var(--text-muted);
        }
        .empty-state .icon { font-size: 40px; margin-bottom: 12px; }
        .empty-state p { font-size: 14px; }

        /* Pagination */
        .pagination {
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 14px 22px;
            border-top: 1px solid var(--border);
            background: #fafcff;
        }
        .pagination-info {
            font-size: 12.5px;
            color: var(--text-muted);
        }
        .pagination-btns {
            display: flex;
            gap: 4px;
        }
        .page-btn {
            min-width: 32px; height: 32px;
            padding: 0 8px;
            border: 1.5px solid var(--border);
            border-radius: 8px;
            font-size: 13px;
            font-weight: 500;
            color: var(--navy-deep);
            background: #fff;
            cursor: pointer;
            display: flex; align-items: center; justify-content: center;
            text-decoration: none;
            transition: all .15s;
        }
        .page-btn:hover { border-color: var(--blue-main); color: var(--blue-main); }
        .page-btn.active {
            background: var(--blue-main);
            border-color: var(--blue-main);
            color: #fff;
        }
        .page-btn:disabled, .page-btn.disabled {
            opacity: .4;
            cursor: default;
        }

        /* Scroll for table */
        .table-wrap { overflow-x: auto; }

        /* Expiry alert card (khuyến nghị) */
        .alert-card {
            background: #fff8e6;
            border: 1px solid #f5dfa8;
            border-radius: 14px;
            padding: 16px 20px;
            display: flex;
            align-items: center;
            gap: 14px;
            margin-bottom: 24px;
        }
        .alert-icon { font-size: 22px; }
        .alert-text strong { color: #b8750a; font-size: 13.5px; }
        .alert-text p { font-size: 12.5px; color: #8a6a2a; margin-top: 2px; }
        .alert-link {
            margin-left: auto;
            padding: 7px 16px;
            background: #b8750a;
            color: #fff;
            border-radius: 8px;
            font-size: 12.5px;
            font-weight: 600;
            text-decoration: none;
            white-space: nowrap;
        }
    </style>
</head>
<body>

<!-- ───────── SIDEBAR ───────── -->
<aside class="sidebar">
    <div class="sidebar-logo">
        <div class="logo-icon">💊</div>
        <div>
            <div class="logo-text">Medi<span>Vault</span></div>
            <div class="logo-sub">Admin Console</div>
        </div>
    </div>

    <nav class="nav-section">
        <div class="nav-label">Tổng quan</div>
        <a href="${pageContext.request.contextPath}/dashboard" class="nav-item active">
            <span class="nav-icon">🏠</span> Trang chủ
        </a>
    </nav>

    <nav class="nav-section">
        <div class="nav-label">Quản lý</div>
        <a href="${pageContext.request.contextPath}/accounts" class="nav-item">
            <span class="nav-icon">👤</span> Tài khoản
        </a>
        <a href="${pageContext.request.contextPath}/shifts" class="nav-item">
            <span class="nav-icon">🕐</span> Ca làm việc
        </a>
        <a href="${pageContext.request.contextPath}/medicines" class="nav-item">
            <span class="nav-icon">💊</span> Kho thuốc
            <% if (expiryCount > 0) { %>
            <span class="nav-badge"><%= expiryCount %></span>
            <% } %>
        </a>
        <a href="${pageContext.request.contextPath}/invoices" class="nav-item">
            <span class="nav-icon">🧾</span> Hóa đơn
        </a>
        <a href="${pageContext.request.contextPath}/customers" class="nav-item">
            <span class="nav-icon">👥</span> Khách hàng
        </a>
        <a href="${pageContext.request.contextPath}/returns" class="nav-item">
            <span class="nav-icon">↩️</span> Trả hàng
        </a>
    </nav>

    <nav class="nav-section">
        <div class="nav-label">Phân tích</div>
        <a href="${pageContext.request.contextPath}/reports" class="nav-item">
            <span class="nav-icon">📊</span> Báo cáo
        </a>
    </nav>

    <div class="sidebar-footer">
        <div class="sidebar-user">
            <div class="user-avatar-sm"><%= initials %></div>
            <div class="user-info-sm">
                <div class="name"><%= fullName %></div>
                <div class="role">
                    <% if (roleId == 1) { %>Admin<% } else if (roleId == 2) { %>Dược sĩ<% } else { %>Thủ kho<% } %>
                </div>
            </div>
            <a href="${pageContext.request.contextPath}/logout" class="logout-btn" title="Đăng xuất">⏻</a>
        </div>
    </div>
</aside>

<!-- ───────── MAIN ───────── -->
<div class="main">

    <!-- TOPBAR -->
    <header class="topbar">
        <span class="topbar-title">🏠 Dashboard</span>
        <div class="topbar-search">
            <input type="text" id="globalSearch" placeholder="Tìm kiếm…">
        </div>
        <div class="topbar-right">
            <div class="topbar-clock">
                <span id="clockH">00</span><span class="clock-sep">:</span><span id="clockM">00</span>
                <span class="clock-date" id="clockDate"></span>
            </div>
            <div class="notif-wrap">
                <button class="topbar-icon-btn" onclick="toggleNotif()" title="Thông báo">
                    🔔
                    <% if (expiryCount > 0) { %>
                    <span class="topbar-notif-badge"><%= expiryCount > 9 ? "9+" : expiryCount %></span>
                    <% } %>
                </button>
                <div class="notif-dropdown" id="notifDropdown">
                    <div class="notif-head">
                        <span class="notif-head-title">🔔 Thông báo</span>
                        <button class="notif-clear" onclick="closeNotif()">Đóng ✕</button>
                    </div>
                    <div class="notif-list">
                        <% if (expiryCount > 0) { %>
                        <div class="notif-item"><div class="notif-dot"></div><div><div class="notif-text">⚠️ Có <%= expiryCount %> mặt hàng sắp hết hạn</div><div class="notif-time">Hôm nay</div></div></div>
                        <% } else { %>
                        <div class="notif-item"><div class="notif-dot old"></div><div><div class="notif-text">✅ Không có thuốc nào sắp hết hạn</div><div class="notif-time">Hôm nay</div></div></div>
                        <% } %>
                        <div class="notif-item"><div class="notif-dot old"></div><div><div class="notif-text">👤 Admin <%= fullName %> đăng nhập</div><div class="notif-time" id="loginTime"></div></div></div>
                    </div>
                </div>
            </div>
            <a href="<%= request.getContextPath() %>/accounts?action=view&id=<%= acc.getAccountId() %>" class="topbar-user" title="Xem hồ sơ của tôi">
                <div class="topbar-user-avatar"><%= initials %></div>
                <span class="topbar-user-name"><%= fullName %></span>
            </a>
        </div>
    </header>

    <!-- CONTENT -->
    <div class="content">

        <!-- Page heading -->
        <div class="page-head">
            <div class="page-head-left">
                <div class="breadcrumb">MediVault › Trang chủ</div>
                <h1>Dashboard</h1>
            </div>
            <a href="${pageContext.request.contextPath}/accounts?action=new" class="btn-primary">
                ＋ Tạo tài khoản mới
            </a>
        </div>

        <!-- Alert nếu có thuốc sắp hết hạn -->
        <% if (expiryCount > 0) { %>
        <div class="alert-card">
            <div class="alert-icon">⚠️</div>
            <div class="alert-text">
                <strong><%= expiryCount %> mặt hàng sắp hết hạn</strong>
                <p>Kiểm tra và xử lý trước khi hết hạn sử dụng để tránh thiệt hại.</p>
            </div>
            <a href="${pageContext.request.contextPath}/medicines?filter=expiry" class="alert-link">Xem ngay →</a>
        </div>
        <% } %>

        <!-- STAT CARDS -->
        <div class="stats-grid">
            <div class="stat-card">
                <div class="stat-card-top">
                    <span class="stat-label">Doanh thu hôm nay</span>
                    <div class="stat-icon gold">💰</div>
                </div>
                <div class="stat-value">
                    <% java.text.NumberFormat nf = java.text.NumberFormat.getInstance(new java.util.Locale("vi","VN"));
                       out.print(nf.format(todayRevenue)); %>đ
                </div>
                <div class="stat-diff"><span>Từ hóa đơn đã thanh toán</span></div>
            </div>
            <div class="stat-card">
                <div class="stat-card-top">
                    <span class="stat-label">Hóa đơn hôm nay</span>
                    <div class="stat-icon green">🧾</div>
                </div>
                <div class="stat-value"><%= todayInvoice %></div>
                <div class="stat-diff"><span>Tổng số hóa đơn trong ngày</span></div>
            </div>
            <div class="stat-card">
                <div class="stat-card-top">
                    <span class="stat-label">Thuốc sắp hết hạn</span>
                    <div class="stat-icon red">⏰</div>
                </div>
                <div class="stat-value"><%= expiryCount %></div>
                <div class="stat-diff">
                    <% if (expiryCount > 0) { %><span class="down">▲ Cần xử lý</span><% } else { %><span class="up">✓ Không có</span><% } %>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-card-top">
                    <span class="stat-label">Nhân viên hoạt động</span>
                    <div class="stat-icon blue">👤</div>
                </div>
                <div class="stat-value"><%= activeAccounts %></div>
                <div class="stat-diff"><span>Tài khoản đang kích hoạt</span></div>
            </div>
        </div>

        <!-- TABLE CARD -->
        <div class="table-card">
            <div class="table-card-header">
                <div>
                    <div class="table-card-title">Danh sách tài khoản nhân viên</div>
                    <div class="table-card-subtitle">Quản lý và phân quyền tài khoản hệ thống</div>
                </div>
            </div>

            <!-- Filter row -->
            <form method="get" action="${pageContext.request.contextPath}/dashboard" id="filterForm" onsubmit="return false">
                <div class="filter-row">
                    <div class="filter-search">
                        <input type="text" name="q" placeholder="Tìm theo tên, email…"
                               value="${param.q}">
                    </div>
                    <select name="role" class="filter-select" onchange="filterTable()">
                        <option value="">Tất cả chức vụ</option>
                        <option value="1" ${param.role == '1' ? 'selected' : ''}>🛡️ Admin</option>
                        <option value="2" ${param.role == '2' ? 'selected' : ''}>💊 Dược sĩ</option>
                        <option value="3" ${param.role == '3' ? 'selected' : ''}>📦 Thủ kho</option>
                    </select>
                    <select name="status" class="filter-select" onchange="filterTable()">
                        <option value="">Tất cả trạng thái</option>
                        <option value="1" ${param.status == '1' ? 'selected' : ''}>Đang hoạt động</option>
                        <option value="0" ${param.status == '0' ? 'selected' : ''}>Đã khóa</option>
                    </select>
                    <button type="button" class="filter-chip" onclick="filterTable()">🔍 Lọc</button>
                    <a href="${pageContext.request.contextPath}/dashboard" class="filter-chip">✕ Xóa lọc</a>
                </div>
            </form>

            <div class="table-wrap">
                <table class="data-table">
                    <thead>
                        <tr>
                            <th style="width:44px">#</th>
                            <th>Nhân viên</th>
                            <th>Email</th>
                            <th>Số điện thoại</th>
                            <th>Chức vụ</th>
                            <th>Trạng thái</th>
                            <th style="width:160px">Thao tác</th>
                        </tr>
                    </thead>
                    <tbody>
                        <c:choose>
                            <c:when test="${empty accounts}">
                                <tr>
                                    <td colspan="7">
                                        <div class="empty-state">
                                            <div class="icon">👤</div>
                                            <p>Không tìm thấy tài khoản nào.</p>
                                        </div>
                                    </td>
                                </tr>
                            </c:when>
                            <c:otherwise>
                                <c:forEach var="a" items="${accounts}" varStatus="st">
                                    <tr>
                                        <td style="color:var(--text-muted); font-size:12px;">${st.count}</td>
                                        <td>
                                            <div class="cell-user">
                                                <c:set var="displayName" value="${not empty a.fullName ? a.fullName : a.username}"/>
                                                <div class="cell-avatar">
                                                    ${fn:toUpperCase(fn:substring(displayName, 0, 1))}${fn:toUpperCase(fn:substring(displayName, 1, 2))}
                                                </div>
                                                <div>
                                                    <div class="cell-user-name">${a.fullName != null ? a.fullName : '—'}</div>
                                                    <div class="cell-user-sub">@${a.username}</div>
                                                </div>
                                            </div>
                                        </td>
                                        <td style="color:var(--text-muted); font-size:13px;">
                                            ${a.email != null ? a.email : '—'}
                                        </td>
                                        <td style="color:var(--text-muted); font-size:13px;">
                                            ${a.phone != null ? a.phone : '—'}
                                        </td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${a.roleId == 1}">
                                                    <span class="badge badge-red">Admin</span>
                                                </c:when>
                                                <c:when test="${a.roleId == 2}">
                                                    <span class="badge badge-blue">Dược sĩ</span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="badge badge-gold">Thủ kho</span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td>
                                            <c:choose>
                                                <c:when test="${a.active}">
                                                    <span class="badge badge-green">Hoạt động</span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span class="badge badge-red">Đã khóa</span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td>
                                            <div class="action-group">
                                                <a href="${pageContext.request.contextPath}/accounts?action=edit&id=${a.accountId}"
                                                   class="action-btn action-btn-edit">✏️ Sửa</a>
                                                <form method="post" action="${pageContext.request.contextPath}/accounts"
                                                      style="display:inline"
                                                      onsubmit="return confirm('Xác nhận thay đổi trạng thái tài khoản này?')">
                                                    <input type="hidden" name="action" value="toggle">
                                                    <input type="hidden" name="accountId" value="${a.accountId}">
                                                    <button type="submit"
                                                        class="action-btn ${a.active ? 'action-btn-toggle-off' : 'action-btn-toggle-on'}"
                                                        ${a.active ? '🔒 Khóa' : '🔓 Mở'}
                                                    </button>
                                                </form>
                                            </div>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </c:otherwise>
                        </c:choose>
                    </tbody>
                </table>
            </div>

            <!-- Pagination -->
            <% Integer curPage = (Integer) request.getAttribute("currentPage");
               Integer totPages = (Integer) request.getAttribute("totalPages");
               Integer totRecords = (Integer) request.getAttribute("totalRecords");
               if (curPage == null) curPage = 1;
               if (totPages == null) totPages = 1;
               if (totRecords == null) totRecords = 0;
            %>
            <div class="pagination">
                <div class="pagination-info">
                    Hiển thị trang <%= curPage %> / <%= totPages %>
                    &nbsp;·&nbsp; Tổng <%= totRecords %> tài khoản
                </div>
                <div class="pagination-btns">
                    <% if (curPage > 1) { %>
                    <a href="?page=<%= curPage - 1 %>&q=${param.q}&role=${param.role}&status=${param.status}"
                       class="page-btn">‹</a>
                    <% } else { %>
                    <span class="page-btn disabled">‹</span>
                    <% } %>

                    <% for (int p = Math.max(1, curPage - 2); p <= Math.min(totPages, curPage + 2); p++) { %>
                    <a href="?page=<%= p %>&q=${param.q}&role=${param.role}&status=${param.status}"
                       class="page-btn <%= p == curPage ? "active" : "" %>"><%= p %></a>
                    <% } %>

                    <% if (curPage < totPages) { %>
                    <a href="?page=<%= curPage + 1 %>&q=${param.q}&role=${param.role}&status=${param.status}"
                       class="page-btn">›</a>
                    <% } else { %>
                    <span class="page-btn disabled">›</span>
                    <% } %>
                </div>
            </div>
        </div>

    </div><!-- /content -->
</div><!-- /main -->

<!-- Toast thông báo -->
<% java.lang.String msg = request.getParameter("msg"); %>
<% if ("created".equals(msg)) { %>
<div id="toast" style="position:fixed;top:20px;right:24px;background:#064e3b;color:#fff;padding:12px 20px;border-radius:10px;font-size:13.5px;font-weight:600;display:flex;align-items:center;gap:8px;box-shadow:0 8px 32px rgba(0,0,0,.2);z-index:999;">
    ✅ Tài khoản mới đã được tạo thành công!
</div>
<% } else if ("locked".equals(msg)) { %>
<div id="toast" style="position:fixed;top:20px;right:24px;background:#7f1d1d;color:#fff;padding:12px 20px;border-radius:10px;font-size:13.5px;font-weight:600;display:flex;align-items:center;gap:8px;box-shadow:0 8px 32px rgba(0,0,0,.2);z-index:999;">
    🔒 Đã khóa tài khoản.
</div>
<% } else if ("unlocked".equals(msg)) { %>
<div id="toast" style="position:fixed;top:20px;right:24px;background:#064e3b;color:#fff;padding:12px 20px;border-radius:10px;font-size:13.5px;font-weight:600;display:flex;align-items:center;gap:8px;box-shadow:0 8px 32px rgba(0,0,0,.2);z-index:999;">
    🔓 Đã mở khóa tài khoản.
</div>
<% } %>

<script>
    function updateClock() {
        const now = new Date();
        const h = now.getHours().toString().padStart(2,'0');
        const m = now.getMinutes().toString().padStart(2,'0');
        const days = ['CN','T2','T3','T4','T5','T6','T7'];
        const d = now.getDate().toString().padStart(2,'0');
        const mo = (now.getMonth()+1).toString().padStart(2,'0');
        if(document.getElementById('clockH')) document.getElementById('clockH').textContent = h;
        if(document.getElementById('clockM')) document.getElementById('clockM').textContent = m;
        if(document.getElementById('clockDate')) document.getElementById('clockDate').textContent = days[now.getDay()] + ', ' + d + '/' + mo;
        if(document.getElementById('loginTime')) document.getElementById('loginTime').textContent = h + ':' + m + ' hôm nay';
    }
    updateClock(); setInterval(updateClock, 1000);
    function toggleNotif() { document.getElementById('notifDropdown').classList.toggle('open'); }
    function closeNotif() { document.getElementById('notifDropdown').classList.remove('open'); }
    document.addEventListener('click', function(e) { const w = document.querySelector('.notif-wrap'); if(w && !w.contains(e.target)) closeNotif(); });

    // Auto-hide toast
    const toast = document.getElementById('toast');
    if (toast) setTimeout(() => { toast.style.opacity = '0'; setTimeout(() => toast.remove(), 400); }, 3000);

    // Realtime search with debounce
    let searchTimer;
    document.getElementById('globalSearch').addEventListener('input', function() {
        clearTimeout(searchTimer);
        const q = this.value;
        searchTimer = setTimeout(() => {
            if (q.length > 1) {
                document.querySelector('[name="q"]').value = q;
                document.getElementById('filterForm').submit();
            }
        }, 600);
    });
</script>

<script>
function filterTable() {
  const q      = (document.querySelector('#filterForm [name="q"]')?.value || '').toLowerCase();
  const role   = document.querySelector('#filterForm [name="role"]')?.value || '';
  const status = document.querySelector('#filterForm [name="status"]')?.value || '';
  document.querySelectorAll('tbody tr[data-name]').forEach(row => {
    const show = (!q      || (row.dataset.name  || '').toLowerCase().includes(q))
              && (!role   || row.dataset.role   === role)
              && (!status || row.dataset.status === status);
    row.style.display = show ? '' : 'none';
  });
}
document.querySelector('#filterForm [name="q"]')
  ?.addEventListener('input', filterTable);
</script>

</body>
</html>
