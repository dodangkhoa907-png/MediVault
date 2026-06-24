<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bán hàng — MediCare</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.0/css/all.min.css"/>
    <style>
        /* ══════════════════════════════════════════════════
           DESIGN TOKENS — khớp với palette toàn app
        ══════════════════════════════════════════════════ */
        :root {
            --navy-900: #0F172A;
            --navy-800: #1E293B;
            --navy-700: #334155;
            --primary:  #1558A8;
            --primary-light: #3B82F6;
            --primary-50: #EFF6FF;
            --accent-orange: #F59E0B;
            --accent-green:  #059669;
            --accent-red:    #DC2626;
            --bg-page:  #F1F5F9;
            --bg-card:  #FFFFFF;
            --border:   #E2E8F0;
            --text-main:#0F172A;
            --text-muted:#64748B;
            --radius-sm: 8px;
            --radius-md: 12px;
            --radius-lg: 16px;
            --shadow-sm: 0 1px 3px rgba(0,0,0,.08), 0 1px 2px rgba(0,0,0,.06);
            --shadow-md: 0 4px 16px rgba(0,0,0,.10);
            --sidebar-w: 240px;
            --header-h:  60px;
        }

        *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

        body {
            font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, sans-serif;
            background: var(--bg-page);
            color: var(--text-main);
            min-height: 100vh;
            display: flex;
        }

        /* ══ SIDEBAR (khớp thiết kế toàn app) ═══════════ */
        .sidebar {
            width: var(--sidebar-w);
            background: linear-gradient(180deg, var(--navy-900) 0%, var(--navy-800) 100%);
            display: flex;
            flex-direction: column;
            position: fixed;
            top: 0; left: 0;
            height: 100vh;
            z-index: 100;
            box-shadow: 2px 0 12px rgba(0,0,0,.25);
        }

        .sidebar-brand {
            padding: 18px 20px;
            display: flex; align-items: center; gap: 12px;
            border-bottom: 1px solid rgba(255,255,255,.08);
        }

        .sidebar-brand .logo {
            width: 38px; height: 38px;
            background: linear-gradient(135deg, var(--primary), var(--primary-light));
            border-radius: 10px;
            display: flex; align-items: center; justify-content: center;
            font-size: 18px;
        }

        .sidebar-brand h1 { font-size: 15px; font-weight: 700; color: #fff; line-height: 1.2; }
        .sidebar-brand span { font-size: 9px; color: rgba(255,255,255,.4); text-transform: uppercase; letter-spacing: 1.5px; }

        .sidebar-nav { flex: 1; padding: 12px 0; overflow-y: auto; }
        .nav-section-label {
            padding: 14px 20px 6px;
            font-size: 10px; font-weight: 600;
            color: rgba(255,255,255,.35);
            text-transform: uppercase; letter-spacing: 1.2px;
        }

        .nav-item {
            display: flex; align-items: center; gap: 10px;
            padding: 10px 20px;
            color: rgba(255,255,255,.65);
            text-decoration: none; font-size: 13.5px; font-weight: 500;
            transition: all .18s;
            border-left: 3px solid transparent;
        }
        .nav-item:hover { background: rgba(255,255,255,.07); color: #fff; }
        .nav-item.active {
            background: rgba(21,88,168,.35);
            color: #fff;
            border-left-color: var(--primary-light);
        }
        .nav-item i { width: 18px; text-align: center; font-size: 13px; }

        .sidebar-footer {
            padding: 14px 20px;
            border-top: 1px solid rgba(255,255,255,.08);
        }
        .btn-logout {
            display: flex; align-items: center; gap: 8px;
            padding: 9px 14px; border-radius: var(--radius-sm);
            background: rgba(220,38,38,.15);
            color: #FCA5A5; font-size: 13px; font-weight: 500;
            border: none; cursor: pointer; width: 100%;
            transition: all .18s;
        }
        .btn-logout:hover { background: rgba(220,38,38,.28); color: #fff; }

        /* ══ MAIN WRAPPER ════════════════════════════════ */
        .main-wrapper {
            margin-left: var(--sidebar-w);
            flex: 1;
            display: flex;
            flex-direction: column;
            min-height: 100vh;
        }

        /* ══ TOP BAR ═════════════════════════════════════ */
        .topbar {
            height: var(--header-h);
            background: var(--bg-card);
            border-bottom: 1px solid var(--border);
            display: flex; align-items: center;
            padding: 0 24px;
            gap: 12px;
            position: sticky; top: 0; z-index: 50;
            box-shadow: var(--shadow-sm);
        }
        .topbar-title {
            font-size: 17px; font-weight: 700; color: var(--text-main);
            display: flex; align-items: center; gap: 8px;
        }
        .topbar-title .icon-badge {
            width: 32px; height: 32px;
            background: linear-gradient(135deg, var(--primary), var(--primary-light));
            border-radius: 8px;
            display: flex; align-items: center; justify-content: center;
            color: #fff; font-size: 14px;
        }
        .topbar-spacer { flex: 1; }
        .topbar-info {
            display: flex; align-items: center; gap: 6px;
            font-size: 12.5px; color: var(--text-muted);
            background: var(--bg-page);
            padding: 6px 12px; border-radius: 20px;
        }
        .topbar-info .dot {
            width: 7px; height: 7px; border-radius: 50%;
            background: var(--accent-green);
            animation: pulse-dot 2s ease-in-out infinite;
        }
        @keyframes pulse-dot {
            0%,100% { opacity: 1; } 50% { opacity: .4; }
        }
        .topbar-avatar {
            width: 34px; height: 34px; border-radius: 50%;
            background: linear-gradient(135deg, var(--primary), var(--primary-light));
            display: flex; align-items: center; justify-content: center;
            color: #fff; font-size: 13px; font-weight: 600;
            cursor: pointer;
        }

        /* ══ POS LAYOUT — 2 CỘT CHÍNH ═══════════════════ */
        .pos-layout {
            display: grid;
            grid-template-columns: 1fr 380px;
            gap: 0;
            flex: 1;
            height: calc(100vh - var(--header-h));
            overflow: hidden;
        }

        /* ── LEFT: Chọn thuốc ──────────────────────────── */
        .pos-left {
            background: var(--bg-page);
            display: flex;
            flex-direction: column;
            overflow: hidden;
            border-right: 1px solid var(--border);
        }

        /* Search bar */
        .search-bar-wrap {
            padding: 16px 20px 12px;
            background: var(--bg-card);
            border-bottom: 1px solid var(--border);
        }
        .search-input-group {
            display: flex; gap: 8px; align-items: center;
        }
        .search-box {
            flex: 1;
            display: flex; align-items: center;
            background: var(--bg-page);
            border: 1.5px solid var(--border);
            border-radius: var(--radius-md);
            padding: 0 14px;
            gap: 8px;
            transition: border-color .18s, box-shadow .18s;
        }
        .search-box:focus-within {
            border-color: var(--primary-light);
            box-shadow: 0 0 0 3px rgba(59,130,246,.15);
            background: #fff;
        }
        .search-box i { color: var(--text-muted); font-size: 13px; }
        .search-box input {
            flex: 1; border: none; background: transparent;
            padding: 10px 0; font-size: 13.5px; color: var(--text-main);
            outline: none;
        }
        .search-box input::placeholder { color: var(--text-muted); }
        .btn-scan {
            padding: 10px 14px; border-radius: var(--radius-sm);
            border: 1.5px solid var(--border);
            background: var(--bg-card);
            color: var(--text-muted); font-size: 13px;
            cursor: pointer; display: flex; align-items: center; gap: 6px;
            transition: all .18s; white-space: nowrap;
        }
        .btn-scan:hover { border-color: var(--primary-light); color: var(--primary); }

        /* Category tabs */
        .category-tabs {
            display: flex; gap: 6px;
            padding: 10px 20px;
            background: var(--bg-card);
            border-bottom: 1px solid var(--border);
            overflow-x: auto;
            scrollbar-width: none;
        }
        .category-tabs::-webkit-scrollbar { display: none; }

        .cat-tab {
            padding: 6px 16px;
            border-radius: 20px;
            border: 1.5px solid var(--border);
            background: var(--bg-page);
            color: var(--text-muted);
            font-size: 12.5px; font-weight: 500;
            cursor: pointer; white-space: nowrap;
            transition: all .18s;
        }
        .cat-tab:hover { border-color: var(--primary-light); color: var(--primary); }
        .cat-tab.active {
            background: var(--primary);
            border-color: var(--primary);
            color: #fff; font-weight: 600;
        }

        /* Medicine grid */
        .medicine-grid-wrap {
            flex: 1;
            overflow-y: auto;
            padding: 16px 20px;
        }

        .medicine-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(160px, 1fr));
            gap: 12px;
        }

        .med-card {
            background: var(--bg-card);
            border-radius: var(--radius-md);
            padding: 14px 12px;
            cursor: pointer;
            border: 2px solid transparent;
            box-shadow: var(--shadow-sm);
            transition: all .18s;
            position: relative;
            user-select: none;
        }
        .med-card:hover {
            border-color: var(--primary-light);
            box-shadow: var(--shadow-md);
            transform: translateY(-1px);
        }
        .med-card.out-of-stock {
            opacity: .55;
            cursor: not-allowed;
        }
        .med-card.out-of-stock:hover { transform: none; border-color: transparent; }

        .med-card-icon {
            width: 40px; height: 40px;
            background: var(--primary-50);
            border-radius: 10px;
            display: flex; align-items: center; justify-content: center;
            font-size: 20px; margin-bottom: 10px;
        }
        .med-card-name {
            font-size: 13px; font-weight: 600;
            color: var(--text-main); line-height: 1.35;
            margin-bottom: 4px;
            display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical;
            overflow: hidden;
        }
        .med-card-unit {
            font-size: 11px; color: var(--text-muted); margin-bottom: 8px;
        }
        .med-card-footer {
            display: flex; align-items: center; justify-content: space-between;
        }
        .med-card-price {
            font-size: 13px; font-weight: 700; color: var(--primary);
        }
        .med-card-stock {
            font-size: 11px; color: var(--text-muted);
            background: var(--bg-page);
            padding: 2px 7px; border-radius: 10px;
        }
        .med-card-stock.low { background: #FEF3C7; color: #92400E; }
        .med-card-stock.out { background: #FEE2E2; color: #991B1B; }

        .med-card-rx-badge {
            position: absolute; top: 8px; right: 8px;
            background: #FEF3C7; color: #92400E;
            font-size: 9px; font-weight: 700;
            padding: 2px 5px; border-radius: 4px;
            letter-spacing: .5px;
        }

        /* Add ripple on click */
        .med-card.adding {
            border-color: var(--accent-green);
            animation: card-add .3s ease;
        }
        @keyframes card-add {
            0% { transform: scale(1); }
            50% { transform: scale(.95); }
            100% { transform: scale(1); }
        }

        /* Empty state */
        .empty-grid {
            grid-column: 1 / -1;
            text-align: center; padding: 60px 20px;
            color: var(--text-muted);
        }
        .empty-grid .empty-icon { font-size: 48px; margin-bottom: 12px; opacity: .4; }
        .empty-grid p { font-size: 14px; }

        /* ── RIGHT: Giỏ hàng / Bill ────────────────────── */
        .pos-right {
            background: var(--bg-card);
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }

        /* Bill header */
        .bill-header {
            padding: 16px 20px;
            border-bottom: 1px solid var(--border);
            background: var(--bg-card);
        }
        .bill-header-top {
            display: flex; align-items: center; justify-content: space-between;
            margin-bottom: 12px;
        }
        .bill-title {
            font-size: 15px; font-weight: 700; color: var(--text-main);
            display: flex; align-items: center; gap: 7px;
        }
        .bill-count {
            background: var(--primary);
            color: #fff; font-size: 11px; font-weight: 700;
            padding: 2px 7px; border-radius: 10px;
        }
        .btn-clear {
            font-size: 12px; color: var(--accent-red);
            background: #FEE2E2; border: none;
            padding: 5px 10px; border-radius: var(--radius-sm);
            cursor: pointer; display: flex; align-items: center; gap: 4px;
            transition: all .18s;
        }
        .btn-clear:hover { background: var(--accent-red); color: #fff; }

        /* Customer selector */
        .customer-row {
            display: flex; align-items: center; gap: 8px;
        }
        .customer-search-box {
            flex: 1;
            display: flex; align-items: center; gap: 7px;
            border: 1.5px solid var(--border); border-radius: var(--radius-sm);
            padding: 7px 10px; background: var(--bg-page);
            transition: border-color .18s;
        }
        .customer-search-box:focus-within {
            border-color: var(--primary-light);
            background: #fff;
        }
        .customer-search-box i { color: var(--text-muted); font-size: 12px; }
        .customer-search-box input {
            flex: 1; border: none; background: transparent;
            font-size: 12.5px; outline: none; color: var(--text-main);
        }
        .customer-search-box input::placeholder { color: var(--text-muted); }
        .btn-add-customer {
            padding: 8px 10px; border-radius: var(--radius-sm);
            border: 1.5px dashed var(--border);
            background: transparent; color: var(--text-muted);
            font-size: 12px; cursor: pointer; white-space: nowrap;
            transition: all .18s;
        }
        .btn-add-customer:hover { border-color: var(--primary); color: var(--primary); }

        /* Customer chip when found */
        .customer-chip {
            display: flex; align-items: center; gap: 8px;
            background: var(--primary-50); border: 1.5px solid #BFDBFE;
            border-radius: var(--radius-sm); padding: 7px 10px;
            flex: 1;
        }
        .customer-chip .avatar {
            width: 24px; height: 24px; border-radius: 50%;
            background: var(--primary); color: #fff;
            font-size: 11px; font-weight: 700;
            display: flex; align-items: center; justify-content: center;
        }
        .customer-chip .name { font-size: 12.5px; font-weight: 600; color: var(--primary); }
        .customer-chip .phone { font-size: 11px; color: var(--text-muted); }
        .customer-chip .btn-remove-cust {
            margin-left: auto; background: none; border: none;
            color: var(--text-muted); cursor: pointer; font-size: 12px;
        }

        /* Bill items */
        .bill-items {
            flex: 1; overflow-y: auto;
            padding: 12px 16px;
        }

        .bill-empty {
            display: flex; flex-direction: column; align-items: center;
            justify-content: center; height: 100%;
            color: var(--text-muted); text-align: center;
            gap: 10px;
        }
        .bill-empty .empty-icon { font-size: 44px; opacity: .3; }
        .bill-empty p { font-size: 13px; }

        .bill-item {
            display: flex; align-items: center; gap: 10px;
            padding: 10px 0;
            border-bottom: 1px solid var(--border);
            animation: slide-in .2s ease;
        }
        @keyframes slide-in {
            from { opacity: 0; transform: translateX(10px); }
            to { opacity: 1; transform: translateX(0); }
        }

        .bill-item-icon {
            width: 36px; height: 36px; flex-shrink: 0;
            background: var(--primary-50); border-radius: 8px;
            display: flex; align-items: center; justify-content: center;
            font-size: 16px;
        }
        .bill-item-info { flex: 1; min-width: 0; }
        .bill-item-name {
            font-size: 12.5px; font-weight: 600; color: var(--text-main);
            white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
        }
        .bill-item-unit { font-size: 11px; color: var(--text-muted); }
        .bill-item-price { font-size: 12px; font-weight: 700; color: var(--primary); }

        .qty-control {
            display: flex; align-items: center; gap: 4px;
        }
        .qty-btn {
            width: 26px; height: 26px; border-radius: 6px;
            border: 1.5px solid var(--border);
            background: var(--bg-page); color: var(--text-main);
            font-size: 14px; font-weight: 700;
            cursor: pointer; display: flex; align-items: center; justify-content: center;
            transition: all .15s;
        }
        .qty-btn:hover { border-color: var(--primary); color: var(--primary); background: var(--primary-50); }
        .qty-btn.remove:hover { border-color: var(--accent-red); color: var(--accent-red); background: #FEE2E2; }
        .qty-value {
            width: 32px; text-align: center;
            font-size: 13px; font-weight: 700; color: var(--text-main);
            border: none; background: transparent; outline: none;
        }

        .bill-item-subtotal {
            min-width: 64px; text-align: right;
            font-size: 13px; font-weight: 700; color: var(--text-main);
        }
        .btn-remove-item {
            padding: 4px 6px; border-radius: 5px;
            border: none; background: none;
            color: #CBD5E1; cursor: pointer; font-size: 13px;
            transition: all .15s;
        }
        .btn-remove-item:hover { color: var(--accent-red); background: #FEE2E2; }

        /* Bill footer — tổng + thanh toán */
        .bill-footer {
            border-top: 1px solid var(--border);
            padding: 14px 16px;
            background: var(--bg-card);
        }

        .bill-summary {
            margin-bottom: 14px;
        }
        .summary-row {
            display: flex; justify-content: space-between; align-items: center;
            padding: 4px 0; font-size: 13px;
        }
        .summary-row .label { color: var(--text-muted); }
        .summary-row .value { font-weight: 500; }
        .summary-row.discount .value { color: var(--accent-orange); }
        .summary-row.total {
            margin-top: 8px; padding-top: 10px;
            border-top: 2px dashed var(--border);
        }
        .summary-row.total .label { font-size: 14px; font-weight: 700; color: var(--text-main); }
        .summary-row.total .value { font-size: 18px; font-weight: 800; color: var(--primary); }

        /* Discount input */
        .discount-row {
            display: flex; align-items: center; gap: 8px;
            padding: 6px 0;
        }
        .discount-row .label { color: var(--text-muted); font-size: 13px; flex: 1; }
        .discount-input {
            width: 100px; padding: 5px 8px;
            border: 1.5px solid var(--border); border-radius: var(--radius-sm);
            font-size: 13px; text-align: right; outline: none;
            transition: border-color .18s;
        }
        .discount-input:focus { border-color: var(--primary-light); }

        /* Payment method */
        .payment-methods {
            display: grid; grid-template-columns: repeat(3, 1fr);
            gap: 6px; margin-bottom: 12px;
        }
        .pay-method {
            padding: 8px 4px;
            border: 1.5px solid var(--border); border-radius: var(--radius-sm);
            background: var(--bg-page); cursor: pointer;
            display: flex; flex-direction: column; align-items: center; gap: 3px;
            font-size: 11px; font-weight: 500; color: var(--text-muted);
            transition: all .18s;
        }
        .pay-method i { font-size: 15px; }
        .pay-method:hover { border-color: var(--primary-light); color: var(--primary); }
        .pay-method.selected {
            border-color: var(--primary);
            background: var(--primary-50);
            color: var(--primary); font-weight: 600;
        }

        /* Bill button */
        .btn-bill {
            width: 100%;
            padding: 14px;
            border-radius: var(--radius-md);
            border: none;
            background: linear-gradient(135deg, var(--primary) 0%, var(--primary-light) 100%);
            color: #fff;
            font-size: 15px; font-weight: 700;
            cursor: pointer;
            display: flex; align-items: center; justify-content: center; gap: 8px;
            transition: all .2s;
            box-shadow: 0 4px 12px rgba(21,88,168,.35);
        }
        .btn-bill:hover:not(:disabled) {
            transform: translateY(-1px);
            box-shadow: 0 6px 18px rgba(21,88,168,.45);
        }
        .btn-bill:disabled {
            opacity: .45; cursor: not-allowed; transform: none;
            box-shadow: none;
        }
        .btn-bill.loading { pointer-events: none; }
        .btn-bill .spinner {
            display: none;
            width: 16px; height: 16px;
            border: 2px solid rgba(255,255,255,.4);
            border-top-color: #fff;
            border-radius: 50%;
            animation: spin .7s linear infinite;
        }
        @keyframes spin { to { transform: rotate(360deg); } }

        /* ══ TOAST ════════════════════════════════════════ */
        .toast-container {
            position: fixed; top: 72px; right: 24px;
            z-index: 9999;
            display: flex; flex-direction: column; gap: 8px;
        }
        .toast {
            padding: 12px 18px; border-radius: var(--radius-md);
            font-size: 13.5px; font-weight: 500;
            display: flex; align-items: center; gap: 10px;
            box-shadow: var(--shadow-md);
            min-width: 280px;
            animation: toast-in .25s ease;
        }
        @keyframes toast-in {
            from { opacity: 0; transform: translateX(20px); }
            to { opacity: 1; transform: translateX(0); }
        }
        .toast.success { background: #ECFDF5; border: 1px solid #A7F3D0; color: #065F46; }
        .toast.error   { background: #FEF2F2; border: 1px solid #FECACA; color: #991B1B; }
        .toast.info    { background: var(--primary-50); border: 1px solid #BFDBFE; color: var(--primary); }

        /* ══ SUCCESS MODAL ════════════════════════════════ */
        .modal-overlay {
            display: none;
            position: fixed; inset: 0;
            background: rgba(0,0,0,.5);
            backdrop-filter: blur(4px);
            z-index: 1000;
            align-items: center; justify-content: center;
        }
        .modal-overlay.show { display: flex; }
        .modal-box {
            background: var(--bg-card);
            border-radius: var(--radius-lg);
            padding: 36px 32px;
            max-width: 420px; width: 92%;
            text-align: center;
            animation: modal-in .25s ease;
            box-shadow: 0 24px 60px rgba(0,0,0,.2);
        }
        @keyframes modal-in {
            from { opacity: 0; transform: scale(.92); }
            to { opacity: 1; transform: scale(1); }
        }
        .modal-success-icon {
            width: 72px; height: 72px; border-radius: 50%;
            background: linear-gradient(135deg, var(--accent-green), #34D399);
            margin: 0 auto 16px;
            display: flex; align-items: center; justify-content: center;
            font-size: 32px;
        }
        .modal-box h2 { font-size: 20px; font-weight: 800; margin-bottom: 6px; }
        .modal-box .invoice-code {
            font-size: 15px; font-weight: 700; color: var(--primary);
            background: var(--primary-50); padding: 8px 18px; border-radius: 20px;
            display: inline-block; margin: 10px 0;
        }
        .modal-box .total-big {
            font-size: 28px; font-weight: 800; color: var(--text-main);
            margin: 8px 0 20px;
        }
        .modal-actions { display: flex; gap: 10px; }
        .modal-btn {
            flex: 1; padding: 11px;
            border-radius: var(--radius-sm); border: none;
            font-size: 14px; font-weight: 600; cursor: pointer;
            transition: all .18s;
        }
        .modal-btn.primary { background: var(--primary); color: #fff; }
        .modal-btn.primary:hover { background: var(--navy-800); }
        .modal-btn.secondary { background: var(--bg-page); color: var(--text-muted); border: 1.5px solid var(--border); }
        .modal-btn.secondary:hover { border-color: var(--primary); color: var(--primary); }

        /* ══ SCROLLBAR ════════════════════════════════════ */
        .bill-items::-webkit-scrollbar,
        .medicine-grid-wrap::-webkit-scrollbar { width: 4px; }
        .bill-items::-webkit-scrollbar-track,
        .medicine-grid-wrap::-webkit-scrollbar-track { background: transparent; }
        .bill-items::-webkit-scrollbar-thumb,
        .medicine-grid-wrap::-webkit-scrollbar-thumb {
            background: var(--border); border-radius: 4px;
        }

        /* ══ RESPONSIVE ═══════════════════════════════════ */
        @media (max-width: 900px) {
            .pos-layout { grid-template-columns: 1fr; }
            .pos-right { display: none; }
        }
    </style>
</head>
<body>

<!-- ════════════════════════════════════════
     SIDEBAR
════════════════════════════════════════ -->
<aside class="sidebar">
    <div class="sidebar-brand">
        <div class="logo">💊</div>
        <div>
            <h1>MediCare</h1>
            <span>Admin Console</span>
        </div>
    </div>

    <nav class="sidebar-nav">
        <div class="nav-section-label">Tổng quan</div>
        <a href="${pageContext.request.contextPath}/dashboard" class="nav-item">
            <i class="fas fa-th-large"></i> Trang chủ
        </a>

        <div class="nav-section-label">Phân tích</div>
        <a href="${pageContext.request.contextPath}/reports" class="nav-item">
            <i class="fas fa-chart-bar"></i> Báo cáo
        </a>
        <a href="${pageContext.request.contextPath}/audit-logs" class="nav-item">
            <i class="fas fa-file-alt"></i> Nhật ký
        </a>

        <div class="nav-section-label">Quản lý</div>
        <a href="${pageContext.request.contextPath}/medicines" class="nav-item">
            <i class="fas fa-pills"></i> Kho hàng
        </a>
        <a href="${pageContext.request.contextPath}/pos" class="nav-item active">
            <i class="fas fa-cash-register"></i> Bán hàng
        </a>
        <a href="${pageContext.request.contextPath}/invoices" class="nav-item">
            <i class="fas fa-receipt"></i> Hóa đơn
        </a>
        <a href="${pageContext.request.contextPath}/accounts" class="nav-item">
            <i class="fas fa-users"></i> Nhân viên &amp; Khách hàng
        </a>

        <div class="nav-section-label">Nhân sự</div>
        <a href="${pageContext.request.contextPath}/shifts" class="nav-item">
            <i class="fas fa-calendar-alt"></i> Ca &amp; Lịch làm việc
        </a>
        <a href="${pageContext.request.contextPath}/attendance" class="nav-item">
            <i class="fas fa-check-double"></i> Điểm danh
        </a>
        <a href="${pageContext.request.contextPath}/payroll" class="nav-item">
            <i class="fas fa-money-bill-wave"></i> Bảng lương
        </a>
    </nav>

    <div class="sidebar-footer">
        <form action="${pageContext.request.contextPath}/logout" method="post">
            <button type="submit" class="btn-logout">
                <i class="fas fa-power-off"></i> Đăng xuất
            </button>
        </form>
    </div>
</aside>

<!-- ════════════════════════════════════════
     MAIN
════════════════════════════════════════ -->
<div class="main-wrapper">

    <!-- Topbar -->
    <header class="topbar">
        <div class="topbar-title">
            <div class="icon-badge"><i class="fas fa-cash-register"></i></div>
            Bán hàng — POS
        </div>
        <div class="topbar-spacer"></div>
        <div class="topbar-info">
            <span class="dot"></span>
            <span id="clock-display">--:--:--</span>
        </div>
        <div class="topbar-avatar" title="${sessionScope.adminAccount.fullName}">
            <c:choose>
                <c:when test="${not empty sessionScope.adminAccount.fullName}">
                    ${fn:substring(sessionScope.adminAccount.fullName, 0, 1)}
                </c:when>
                <c:otherwise>A</c:otherwise>
            </c:choose>
        </div>
    </header>

    <!-- POS 2-column layout -->
    <div class="pos-layout">

        <!-- ════ LEFT: CHỌN THUỐC ════ -->
        <section class="pos-left">
            <!-- Search -->
            <div class="search-bar-wrap">
                <div class="search-input-group">
                    <div class="search-box">
                        <i class="fas fa-search"></i>
                        <input type="text" id="searchInput"
                               placeholder="Tìm theo tên, hoạt chất, barcode, mã thuốc..."
                               autocomplete="off">
                    </div>
                    <button class="btn-scan" onclick="focusScan()" title="Quét barcode">
                        <i class="fas fa-barcode"></i> Quét
                    </button>
                </div>
            </div>

            <!-- Category tabs -->
            <div class="category-tabs" id="categoryTabs">
                <button class="cat-tab active" data-cat="all">🏷️ Tất cả</button>
                <c:forEach var="cat" items="${categories}">
                    <button class="cat-tab" data-cat="${cat.categoryId}">${cat.categoryName}</button>
                </c:forEach>
            </div>

            <!-- Medicine grid -->
            <div class="medicine-grid-wrap">
                <div class="medicine-grid" id="medicineGrid">
                    <!-- Populated by JS -->
                    <div class="empty-grid">
                        <div class="empty-icon">⏳</div>
                        <p>Đang tải danh sách thuốc...</p>
                    </div>
                </div>
            </div>
        </section>

        <!-- ════ RIGHT: BILL / GIỎ HÀNG ════ -->
        <section class="pos-right">

            <!-- Bill header -->
            <div class="bill-header">
                <div class="bill-header-top">
                    <div class="bill-title">
                        <i class="fas fa-receipt" style="color:var(--primary)"></i>
                        Đơn hàng
                        <span class="bill-count" id="billCount">0</span>
                    </div>
                    <button class="btn-clear" onclick="clearBill()" title="Xóa đơn">
                        <i class="fas fa-trash-alt"></i> Xóa đơn
                    </button>
                </div>

                <!-- Customer -->
                <div class="customer-row" id="customerRow">
                    <div class="customer-search-box">
                        <i class="fas fa-user"></i>
                        <input type="text" id="customerPhone"
                               placeholder="SĐT khách hàng..."
                               maxlength="11"
                               oninput="handleCustomerInput(this.value)">
                    </div>
                    <button class="btn-add-customer" onclick="showAddCustomer()" title="Thêm khách mới">
                        <i class="fas fa-user-plus"></i>
                    </button>
                </div>
                <div id="customerChip" style="display:none"></div>
            </div>

            <!-- Bill items -->
            <div class="bill-items" id="billItems">
                <div class="bill-empty" id="billEmpty">
                    <div class="empty-icon">🛒</div>
                    <p>Chọn thuốc từ danh sách<br>để thêm vào đơn hàng</p>
                </div>
            </div>

            <!-- Bill footer -->
            <div class="bill-footer">
                <div class="bill-summary">
                    <div class="summary-row">
                        <span class="label">Số lượng SP</span>
                        <span class="value" id="summaryQty">0 sản phẩm</span>
                    </div>
                    <div class="summary-row">
                        <span class="label">Tạm tính</span>
                        <span class="value" id="summarySubtotal">0 ₫</span>
                    </div>
                    <div class="discount-row">
                        <span class="label">Giảm giá</span>
                        <input type="number" class="discount-input" id="discountInput"
                               min="0" value="0" placeholder="0"
                               oninput="recalcTotal()">
                    </div>
                    <div class="summary-row total">
                        <span class="label">Tổng thanh toán</span>
                        <span class="value" id="summaryTotal">0 ₫</span>
                    </div>
                </div>

                <!-- Payment method -->
                <div class="payment-methods" id="paymentMethods">
                    <button class="pay-method selected" data-method="CASH">
                        <i class="fas fa-money-bill-wave"></i>
                        Tiền mặt
                    </button>
                    <button class="pay-method" data-method="CARD">
                        <i class="fas fa-credit-card"></i>
                        Thẻ
                    </button>
                    <button class="pay-method" data-method="TRANSFER">
                        <i class="fas fa-mobile-alt"></i>
                        Chuyển khoản
                    </button>
                </div>

                <!-- BILL BUTTON -->
                <button class="btn-bill" id="btnBill" onclick="submitBill()" disabled>
                    <div class="spinner" id="billSpinner"></div>
                    <i class="fas fa-check-circle" id="billIcon"></i>
                    <span id="btnBillText">Bấm Bill</span>
                </button>
            </div>
        </section>

    </div><!-- end pos-layout -->
</div><!-- end main-wrapper -->

<!-- ════ SUCCESS MODAL ════ -->
<div class="modal-overlay" id="successModal">
    <div class="modal-box">
        <div class="modal-success-icon">✅</div>
        <h2>Thanh toán thành công!</h2>
        <div class="invoice-code" id="modalInvoiceCode">HD000001</div>
        <div class="total-big" id="modalTotal">0 ₫</div>
        <div class="modal-actions">
            <button class="modal-btn secondary" onclick="printInvoice()">
                <i class="fas fa-print"></i> In hóa đơn
            </button>
            <button class="modal-btn primary" onclick="closeModal()">
                <i class="fas fa-plus"></i> Đơn mới
            </button>
        </div>
    </div>
</div>

<!-- ════ TOAST CONTAINER ════ -->
<div class="toast-container" id="toastContainer"></div>

<!-- ════════════════════════════════════════
     JAVASCRIPT
════════════════════════════════════════ -->
<script>
    /* ── State ── */
    let allMedicines  = [];
    let cart          = [];           // {med, qty}
    let selectedCat   = 'all';
    let selectedPay   = 'CASH';
    let customerId    = null;
    let customerData  = null;
    let searchTimer   = null;

    const CTX = '${pageContext.request.contextPath}';

    /* ── Clock ── */
    (function clock() {
        const el = document.getElementById('clock-display');
        function tick() {
            const now = new Date();
            el.textContent = now.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
        }
        tick();
        setInterval(tick, 1000);
    })();

    /* ── Load medicines ── */
    async function loadMedicines() {
        try {
            const res = await fetch(CTX + '/pos?action=search&q=');
            if (!res.ok) throw new Error('Network error');
            allMedicines = await res.json();
            renderGrid(allMedicines);
        } catch (e) {
            console.error(e);
            showToast('Không thể tải danh sách thuốc. Tải lại trang?', 'error');
        }
    }

    /* ── Render medicine grid ── */
    function renderGrid(meds) {
        const grid = document.getElementById('medicineGrid');
        if (!meds || meds.length === 0) {
            grid.innerHTML = `
                <div class="empty-grid">
                    <div class="empty-icon">💊</div>
                    <p>Không tìm thấy thuốc phù hợp</p>
                </div>`;
            return;
        }

        const icons = ['💊', '💉', '🩺', '🧴', '🩹', '🔬', '🌡️', '🫁'];
        grid.innerHTML = meds.map(m => {
            const icon  = icons[m.id % icons.length] || '💊';
            const stock = m.stock;
            const stockCls = stock <= 0 ? 'out' : stock <= 5 ? 'low' : '';
            const stockLbl = stock <= 0 ? 'Hết hàng' : stock + ' ' + (m.unit || 'SP');
            const outCls   = stock <= 0 ? 'out-of-stock' : '';
            const rxBadge  = m.rx ? '<span class="med-card-rx-badge">Rx</span>' : '';

            return `
            <div class="med-card ${outCls}"
                 data-id="${m.id}"
                 data-cat="${m.catId}"
                 onclick="addToCart(${m.id})"
                 title="${m.name}">
                ${rxBadge}
                <div class="med-card-icon">${icon}</div>
                <div class="med-card-name">${m.name}</div>
                <div class="med-card-unit">${m.unit || ''}</div>
                <div class="med-card-footer">
                    <span class="med-card-price">${fmtCurrency(m.price)}</span>
                    <span class="med-card-stock ${stockCls}">${stockLbl}</span>
                </div>
            </div>`;
        }).join('');
    }

    /* ── Category filter ── */
    document.getElementById('categoryTabs').addEventListener('click', e => {
        const tab = e.target.closest('.cat-tab');
        if (!tab) return;
        document.querySelectorAll('.cat-tab').forEach(t => t.classList.remove('active'));
        tab.classList.add('active');
        selectedCat = tab.dataset.cat;
        filterAndSearch();
    });

    /* ── Search ── */
    document.getElementById('searchInput').addEventListener('input', e => {
        clearTimeout(searchTimer);
        const q = e.target.value.trim();
        if (q.length === 0) { filterAndSearch(); return; }
        searchTimer = setTimeout(() => {
            /* Local filter first for UX speed */
            filterAndSearch(q);
            /* Then fetch from server for accuracy */
            if (q.length >= 2) fetchSearch(q);
        }, 250);
    });

    async function fetchSearch(q) {
        try {
            const res = await fetch(CTX + '/pos?action=search&q=' + encodeURIComponent(q));
            const data = await res.json();
            allMedicines = data;
            filterAndSearch(q);
        } catch (e) {}
    }

    function filterAndSearch(q = document.getElementById('searchInput').value.trim()) {
        let meds = allMedicines;
        if (selectedCat !== 'all') {
            meds = meds.filter(m => String(m.catId) === selectedCat);
        }
        if (q) {
            const lq = q.toLowerCase();
            meds = meds.filter(m =>
                (m.name  || '').toLowerCase().includes(lq) ||
                (m.code  || '').toLowerCase().includes(lq) ||
                (m.batchNo || '').toLowerCase().includes(lq)
            );
        }
        renderGrid(meds);
    }

    /* ── Add to cart ── */
    function addToCart(medId) {
        const med = allMedicines.find(m => m.id === medId);
        if (!med) return;
        if (med.stock <= 0) { showToast('Thuốc này đã hết hàng!', 'error'); return; }

        const existing = cart.find(c => c.med.id === medId);
        if (existing) {
            if (existing.qty >= med.stock) {
                showToast(`Tồn kho chỉ còn ${med.stock} ${med.unit || 'SP'}`, 'error');
                return;
            }
            existing.qty++;
        } else {
            cart.push({ med, qty: 1 });
        }

        /* Card animation */
        const card = document.querySelector(`.med-card[data-id="${medId}"]`);
        if (card) {
            card.classList.add('adding');
            setTimeout(() => card.classList.remove('adding'), 300);
        }

        renderBill();
        showToast(`Đã thêm ${med.name}`, 'success');
    }

    /* ── Update qty ── */
    function updateQty(medId, delta) {
        const idx = cart.findIndex(c => c.med.id === medId);
        if (idx < 0) return;
        const item = cart[idx];
        const newQty = item.qty + delta;
        if (newQty <= 0) {
            cart.splice(idx, 1);
        } else {
            if (newQty > item.med.stock) {
                showToast(`Tồn kho chỉ còn ${item.med.stock} ${item.med.unit || 'SP'}`, 'error');
                return;
            }
            item.qty = newQty;
        }
        renderBill();
    }

    function removeItem(medId) {
        cart = cart.filter(c => c.med.id !== medId);
        renderBill();
    }

    function clearBill() {
        if (cart.length === 0) return;
        if (!confirm('Xóa toàn bộ đơn hàng hiện tại?')) return;
        cart = [];
        customerId = null;
        customerData = null;
        document.getElementById('customerPhone').value = '';
        document.getElementById('customerChip').style.display = 'none';
        document.getElementById('customerRow').style.display = 'flex';
        renderBill();
    }

    /* ── Render bill ── */
    function renderBill() {
        const billItems  = document.getElementById('billItems');
        const billEmpty  = document.getElementById('billEmpty');
        const billCount  = document.getElementById('billCount');
        const btnBill    = document.getElementById('btnBill');

        if (cart.length === 0) {
            billCount.textContent = '0';
            billItems.innerHTML = '';
            billItems.appendChild(billEmpty);
            billEmpty.style.display = 'flex';
            btnBill.disabled = true;
            updateSummary(0, 0);
            return;
        }

        billEmpty.style.display = 'none';
        billCount.textContent = cart.length;
        btnBill.disabled = false;

        const icons = ['💊', '💉', '🧴', '🩹', '🔬', '🌡️', '🩺', '🫁'];

        billItems.innerHTML = cart.map(item => {
            const m       = item.med;
            const icon    = icons[m.id % icons.length] || '💊';
            const sub     = m.price * item.qty;
            return `
            <div class="bill-item" data-id="${m.id}">
                <div class="bill-item-icon">${icon}</div>
                <div class="bill-item-info">
                    <div class="bill-item-name">${m.name}</div>
                    <div class="bill-item-unit">${m.unit || ''} · ${fmtCurrency(m.price)}</div>
                </div>
                <div class="qty-control">
                    <button class="qty-btn remove"
                            onclick="updateQty(${m.id}, -1)"
                            title="${item.qty === 1 ? 'Xóa' : 'Giảm'}">
                        ${item.qty === 1 ? '<i class="fas fa-trash-alt" style="font-size:11px"></i>' : '−'}
                    </button>
                    <input class="qty-value" type="number" value="${item.qty}" min="1"
                           onchange="setQty(${m.id}, this.value)"
                           onblur="if(!this.value||+this.value<1)this.value=1">
                    <button class="qty-btn" onclick="updateQty(${m.id}, 1)">＋</button>
                </div>
                <div class="bill-item-subtotal">${fmtCurrency(sub)}</div>
                <button class="btn-remove-item" onclick="removeItem(${m.id})" title="Xóa">
                    <i class="fas fa-times"></i>
                </button>
            </div>`;
        }).join('');

        const grossTotal = cart.reduce((s, c) => s + c.med.price * c.qty, 0);
        const totalQty   = cart.reduce((s, c) => s + c.qty, 0);
        updateSummary(grossTotal, totalQty);
    }

    function setQty(medId, val) {
        const idx = cart.findIndex(c => c.med.id === medId);
        if (idx < 0) return;
        const q = parseInt(val);
        if (isNaN(q) || q < 1) { renderBill(); return; }
        const maxStock = cart[idx].med.stock;
        cart[idx].qty = Math.min(q, maxStock);
        renderBill();
    }

    /* ── Summary ── */
    function updateSummary(gross, totalQty) {
        const disc  = Math.max(0, parseInt(document.getElementById('discountInput').value) || 0);
        const total = Math.max(0, gross - disc);
        document.getElementById('summaryQty').textContent      = totalQty + ' sản phẩm';
        document.getElementById('summarySubtotal').textContent = fmtCurrency(gross);
        document.getElementById('summaryTotal').textContent    = fmtCurrency(total);
    }

    function recalcTotal() {
        const gross    = cart.reduce((s, c) => s + c.med.price * c.qty, 0);
        const totalQty = cart.reduce((s, c) => s + c.qty, 0);
        updateSummary(gross, totalQty);
    }

    /* ── Payment method ── */
    document.getElementById('paymentMethods').addEventListener('click', e => {
        const btn = e.target.closest('.pay-method');
        if (!btn) return;
        document.querySelectorAll('.pay-method').forEach(b => b.classList.remove('selected'));
        btn.classList.add('selected');
        selectedPay = btn.dataset.method;
    });

    /* ── Customer lookup ── */
    let custTimer = null;
    function handleCustomerInput(phone) {
        clearTimeout(custTimer);
        const clean = phone.replace(/\D/g, '');
        if (clean.length < 10) return;
        custTimer = setTimeout(() => findCustomer(clean), 500);
    }

    async function findCustomer(phone) {
        try {
            const res  = await fetch(CTX + '/pos?action=find-customer&phone=' + encodeURIComponent(phone));
            const data = await res.json();
            if (data.found) {
                customerId   = data.id;
                customerData = data;
                showCustomerChip(data);
            }
        } catch (e) {}
    }

    function showCustomerChip(c) {
        const initial = (c.name || 'K').charAt(0).toUpperCase();
        document.getElementById('customerChip').style.display = 'flex';
        document.getElementById('customerRow').style.display  = 'none';
        document.getElementById('customerChip').innerHTML = `
            <div class="customer-chip">
                <div class="avatar">${initial}</div>
                <div>
                    <div class="name">${c.name}</div>
                    <div class="phone">${c.phone}</div>
                </div>
                <button class="btn-remove-cust" onclick="removeCustomer()" title="Xóa khách">
                    <i class="fas fa-times"></i>
                </button>
            </div>`;
        showToast(`Khách: ${c.name}`, 'info');
    }

    function removeCustomer() {
        customerId   = null;
        customerData = null;
        document.getElementById('customerChip').style.display = 'none';
        document.getElementById('customerRow').style.display  = 'flex';
        document.getElementById('customerPhone').value        = '';
    }

    function showAddCustomer() {
        showToast('Tính năng thêm khách hàng nhanh đang phát triển.', 'info');
    }

    /* ── Submit bill ── */
    async function submitBill() {
        if (cart.length === 0) return;
        const btn     = document.getElementById('btnBill');
        const spinner = document.getElementById('billSpinner');
        const icon    = document.getElementById('billIcon');
        const text    = document.getElementById('btnBillText');

        btn.disabled = true;
        btn.classList.add('loading');
        spinner.style.display = 'block';
        icon.style.display    = 'none';
        text.textContent      = 'Đang xử lý...';

        const discount = Math.max(0, parseInt(document.getElementById('discountInput').value) || 0);

        const params = new URLSearchParams();
        params.append('action',        'complete-sale');
        params.append('paymentMethod', selectedPay);
        params.append('discount',      discount);
        if (customerId) params.append('customerId', customerId);

        cart.forEach(item => {
            params.append('medId[]', item.med.id);
            params.append('qty[]',   item.qty);
        });

        try {
            const res  = await fetch(CTX + '/pos', { method: 'POST', body: params });
            const data = await res.json();

            if (data.ok) {
                const gross = cart.reduce((s, c) => s + c.med.price * c.qty, 0);
                showSuccessModal(data.invoiceCode, Math.max(0, gross - discount));
                cart = [];
                customerId   = null;
                customerData = null;
                document.getElementById('discountInput').value = 0;
                document.getElementById('customerPhone').value = '';
                document.getElementById('customerChip').style.display = 'none';
                document.getElementById('customerRow').style.display  = 'flex';
                renderBill();
                loadMedicines(); // refresh tồn kho
            } else {
                showToast(data.msg || 'Thanh toán thất bại!', 'error');
            }
        } catch (e) {
            showToast('Lỗi kết nối. Vui lòng thử lại!', 'error');
        } finally {
            btn.disabled = false;
            btn.classList.remove('loading');
            spinner.style.display = 'none';
            icon.style.display    = 'inline';
            text.textContent      = 'Bấm Bill';
            if (cart.length > 0) btn.disabled = false;
        }
    }

    /* ── Modal ── */
    function showSuccessModal(invoiceCode, total) {
        document.getElementById('modalInvoiceCode').textContent = invoiceCode || 'HD??????';
        document.getElementById('modalTotal').textContent = fmtCurrency(total);
        document.getElementById('successModal').classList.add('show');
    }

    function closeModal() {
        document.getElementById('successModal').classList.remove('show');
    }

    function printInvoice() {
        showToast('Chức năng in hóa đơn đang phát triển.', 'info');
        closeModal();
    }

    /* ── Toast ── */
    function showToast(msg, type = 'info') {
        const container = document.getElementById('toastContainer');
        const icons = { success: '✅', error: '❌', info: 'ℹ️' };
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.innerHTML = `<span>${icons[type]}</span><span>${msg}</span>`;
        container.appendChild(toast);
        setTimeout(() => toast.remove(), 2800);
    }

    /* ── Scan ── */
    function focusScan() {
        document.getElementById('searchInput').focus();
        showToast('Quét barcode hoặc nhập mã thuốc vào ô tìm kiếm.', 'info');
    }

    /* ── Format currency ── */
    function fmtCurrency(n) {
        if (!n && n !== 0) return '—';
        return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(n);
    }

    /* ── Keyboard shortcuts ── */
    document.addEventListener('keydown', e => {
        if (e.key === 'F2') {
            e.preventDefault();
            document.getElementById('searchInput').focus();
        }
        if (e.key === 'F8' && cart.length > 0) {
            e.preventDefault();
            submitBill();
        }
        if (e.key === 'Escape') {
            document.getElementById('successModal').classList.remove('show');
        }a
    });

    /* ── Init ── */
    loadMedicines();
</script>
</body>
</html>
