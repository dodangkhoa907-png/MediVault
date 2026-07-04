<%@ page contentType="text/html;charset=UTF-8" %>
<% String activeNav = "medicines"; %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%
    com.medicare.entity.Account acc = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (acc == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    String fullName = acc.getFullName() != null ? acc.getFullName() : acc.getUsername();
    String initials = fullName.length() >= 2
        ? fullName.substring(0,1).toUpperCase() + fullName.substring(1,2).toUpperCase()
        : fullName.toUpperCase();

    com.medicare.entity.Medicines m = (com.medicare.entity.Medicines) request.getAttribute("medicine");
    boolean isNew = (m == null || m.getMedicineId() == 0);
    boolean editNotFound = Boolean.TRUE.equals(request.getAttribute("editNotFound"));

    String vName    = m != null && m.getMedicineName()      != null ? m.getMedicineName()      : "";
    String vGeneric = m != null && m.getGenericName()       != null ? m.getGenericName()       : "";
    String vBarcode = m != null && m.getBarcode()           != null ? m.getBarcode()           : "";
    String vRegNo   = m != null && m.getRegistrationNumber()!= null ? m.getRegistrationNumber(): "";
    String vUnit    = m != null && m.getUnit()              != null ? m.getUnit()              : "";
    String vDosage  = m != null && m.getDosage()            != null ? m.getDosage()            : "";
    String vContra  = m != null && m.getContraindications() != null ? m.getContraindications() : "";
    String vStorage = m != null && m.getStorageConditions() != null ? m.getStorageConditions() : "";
    String vPrice   = m != null && m.getSellingPrice()      != null ? m.getSellingPrice().toPlainString() : "";
    int    vCatId   = m != null && m.getCategoryId()        != null ? m.getCategoryId()        : 0;
    int    vMfrId   = m != null && m.getManufacturerId()    != null ? m.getManufacturerId()    : 0;
    int    vShelfId = m != null && m.getShelfId()           != null ? m.getShelfId()           : 0;
    int    vMinInv  = m != null ? m.getMinInventory()    : 0;
    int    vExpDays = m != null ? m.getExpiryAlertDays() : 30;
    boolean vRx     = m != null && m.isPrescriptionRequired();

    @SuppressWarnings("unchecked")
    java.util.List<String> errs = (java.util.List<String>) request.getAttribute("errors");
    boolean hasErrors = errs != null && !errs.isEmpty();

    @SuppressWarnings("unchecked")
    java.util.List<com.medicare.entity.Category>     cats    = (java.util.List<com.medicare.entity.Category>)     request.getAttribute("categories");
    @SuppressWarnings("unchecked")
    java.util.List<com.medicare.entity.Manufacturer> mfrs    = (java.util.List<com.medicare.entity.Manufacturer>) request.getAttribute("manufacturers");
    @SuppressWarnings("unchecked")
    java.util.List<com.medicare.entity.Shelf>        shelves = (java.util.List<com.medicare.entity.Shelf>)        request.getAttribute("shelves");
    @SuppressWarnings("unchecked")
    java.util.List<com.medicare.entity.Batches>      batches = (java.util.List<com.medicare.entity.Batches>)      request.getAttribute("batches");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title><%= isNew ? "Thêm thuốc mới" : "Sửa — " + vName %> — MediCare</title>
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
/* ── SIDEBAR ── */
.sidebar{width:var(--sidebar);min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18)}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-icon{width:36px;height:36px;background:linear-gradient(135deg,#3ABDE0,#1558A8);border-radius:10px;display:flex;align-items:center;justify-content:center;font-size:18px}
.logo-text{font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-sub{font-size:10px;color:rgba(255,255,255,.45);font-weight:500;letter-spacing:.5px;text-transform:uppercase}
.nav-section{padding:10px 12px 4px;flex-shrink:0}
.nav-label{font-size:9.5px;font-weight:700;color:rgba(255,255,255,.3);letter-spacing:1px;text-transform:uppercase;padding:0 8px;margin-bottom:4px}
.nav-item{display:flex;align-items:center;gap:9px;padding:9px 10px;border-radius:10px;color:rgba(255,255,255,.6);text-decoration:none;font-size:13.5px;font-weight:500;transition:all .16s;margin-bottom:2px}
.nav-item:hover{background:rgba(255,255,255,.07);color:#fff}
.nav-item.active{background:rgba(58,189,224,.15);color:#fff;border:1px solid rgba(58,189,224,.2)}
.sidebar-footer{margin-top:auto;padding:14px 16px;border-top:1px solid rgba(255,255,255,.06);flex-shrink:0}
.sidebar-user{display:flex;align-items:center;gap:10px;padding:10px 12px;border-radius:12px;background:rgba(255,255,255,.06);border:1px solid rgba(255,255,255,.08)}
.user-av{width:34px;height:34px;border-radius:50%;background:linear-gradient(135deg,#3ABDE0,#1558A8);display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:800;color:#fff;flex-shrink:0}
.user-name{font-size:13px;font-weight:700;color:#fff}
.user-role{font-size:11px;color:rgba(255,255,255,.4)}
.logout-btn{margin-left:auto;width:30px;height:30px;border-radius:8px;display:flex;align-items:center;justify-content:center;color:rgba(255,255,255,.4);text-decoration:none;font-size:16px;transition:all .15s}
.logout-btn:hover{background:rgba(220,38,38,.2);color:#DC2626}
/* ── MAIN LAYOUT ── */
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding: 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-size:16px;font-weight:700;color:var(--ink);white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.topbar-right{margin-left:auto;display:flex;gap:8px;flex-shrink:0}
.btn-back{height:36px;padding:0 14px;background:var(--white);border:1.5px solid var(--border);border-radius:9px;font-size:13px;font-weight:600;color:var(--muted);text-decoration:none;display:inline-flex;align-items:center;gap:6px;transition:all .15s}
.btn-back:hover{border-color:var(--blue);color:var(--navy)}
.content{padding:24px 28px;flex:1}
/* ── SECTION TABS ── */
.section-tabs{display:flex;gap:6px;background:var(--white);border:1px solid var(--border);border-radius:12px;padding:4px;width:fit-content;margin-bottom:22px}
.section-tab{padding:7px 16px;border-radius:8px;font-size:13px;font-weight:600;color:var(--muted);text-decoration:none;transition:all .15s;white-space:nowrap}
.section-tab:hover{background:var(--surface);color:var(--ink)}
.section-tab.active{background:linear-gradient(135deg,var(--blue),var(--cyan));color:#fff;box-shadow:0 2px 8px rgba(21,88,168,.22)}
/* ── PAGE HEADER ── */
.page-title{font-size:22px;font-weight:800;color:var(--ink);margin-bottom:3px}
.page-sub{font-size:13px;color:var(--muted);margin-bottom:20px}
/* ── TWO-COLUMN EDIT LAYOUT ── */
.page-grid{display:grid;grid-template-columns:1fr 360px;gap:22px;align-items:start}
.inv-panel{position:sticky;top:76px}
/* ── ERROR BLOCK ── */
.err-block{background:#FEF2F2;border:1.5px solid #FECACA;border-left:3px solid var(--red);border-radius:12px;padding:14px 18px;margin-bottom:18px}
.err-title{font-size:13px;font-weight:700;color:#991B1B;margin-bottom:7px}
.err-block li{font-size:12.5px;color:var(--red);margin-left:16px;padding:2px 0}
/* ── HINT BANNER ── */
.add-hint{background:linear-gradient(90deg,#EFF6FF,#F0FDFA);border:1.5px solid #BFDBFE;border-radius:12px;padding:12px 16px;margin-bottom:18px;display:flex;align-items:flex-start;gap:10px;font-size:13px;color:#1558A8}
.add-hint strong{font-weight:700}
/* ── FORM CARDS ── */
.form-card{background:var(--white);border:1px solid var(--border);border-radius:16px;overflow:hidden;box-shadow:0 2px 8px rgba(21,88,168,.04);margin-bottom:16px}
.form-card-head{padding:15px 20px;background:linear-gradient(90deg,#F5F8FD,var(--surface));border-bottom:1px solid var(--border);display:flex;align-items:center;gap:11px}
.form-card-icon{width:32px;height:32px;border-radius:9px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:14px;flex-shrink:0}
.form-card-head h2{font-size:14.5px;font-weight:700;color:var(--ink);margin:0}
.form-card-head p{font-size:11.5px;color:var(--muted);margin:2px 0 0}
.form-body{padding:20px;display:grid;grid-template-columns:1fr 1fr;gap:14px}
.span-2{grid-column:1/-1}
.field{display:flex;flex-direction:column;gap:5px}
.field-label{font-size:12px;font-weight:700;color:var(--navy);display:flex;justify-content:space-between;align-items:center}
.req{color:var(--red)}
.field-input{height:42px;padding:0 13px;background:#fff;border:1.5px solid var(--border);border-radius:10px;font-family:'Outfit',sans-serif;font-size:13.5px;color:var(--ink);outline:none;transition:border-color .18s}
.field-input:focus{border-color:var(--cyan);box-shadow:0 0 0 3px rgba(58,189,224,.1)}
.field-input::placeholder{color:#B8CCE0}
select.field-input{appearance:none;cursor:pointer;background:#fff url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='10' height='6' fill='none'%3E%3Cpath stroke='%237A90B0' stroke-width='1.5' stroke-linecap='round' d='M1 1l4 4 4-4'/%3E%3C/svg%3E") no-repeat right 12px center;padding-right:30px}
textarea.field-input{height:80px;padding:10px 13px;resize:vertical}
.field-hint{font-size:11px;color:var(--muted)}
.checkbox-row{display:flex;align-items:center;gap:14px;padding:12px 16px 12px 18px;background:rgba(245,158,11,.06);border:1.5px solid rgba(245,158,11,.25);border-radius:10px;cursor:pointer}
.checkbox-row input[type=checkbox]{width:18px;height:18px;cursor:pointer;accent-color:var(--gold);flex-shrink:0;margin:0}
.checkbox-row label{font-size:13px;font-weight:600;color:#92400E;cursor:pointer;line-height:1.4}
.price-wrap{position:relative}
.price-wrap .field-input{padding-right:36px}
.price-suffix{position:absolute;right:12px;top:50%;transform:translateY(-50%);font-size:11.5px;font-weight:700;color:var(--muted)}
.add-btn-small{height:26px;padding:0 10px;background:rgba(58,189,224,.1);border:1.5px solid rgba(58,189,224,.35);border-radius:7px;font-size:11.5px;font-weight:700;color:#1558A8;cursor:pointer}
/* ── ACTION ROW ── */
.action-row{display:flex;align-items:center;gap:10px;padding:14px 20px;background:linear-gradient(90deg,#FAFBFD,var(--surface));border:1px solid var(--border);border-radius:14px;margin-top:4px}
.btn-submit{height:40px;padding:0 22px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;border-radius:10px;font-family:'Outfit',sans-serif;font-size:14px;font-weight:700;cursor:pointer;box-shadow:0 4px 12px rgba(21,88,168,.25);transition:all .2s}
.btn-submit:hover{transform:translateY(-1px)}
.btn-cancel{height:40px;padding:0 16px;background:var(--white);border:1.5px solid var(--border);border-radius:10px;font-family:'Outfit',sans-serif;font-size:13px;font-weight:600;color:var(--muted);text-decoration:none;display:inline-flex;align-items:center;transition:all .18s}
.btn-cancel:hover{border-color:var(--blue);color:var(--navy)}
/* ── INIT STOCK CARD (Create mode) ── */
.init-stock-card{background:linear-gradient(135deg,#F0FDF4,#ECFDF5);border:1.5px solid #A7F3D0;border-radius:16px;overflow:hidden;margin-bottom:16px}
.init-stock-head{padding:13px 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid #A7F3D0}
.init-stock-icon{width:32px;height:32px;border-radius:9px;background:linear-gradient(135deg,#059669,#065F46);display:flex;align-items:center;justify-content:center;font-size:14px;flex-shrink:0}
.init-stock-body{padding:18px 20px;display:grid;grid-template-columns:1fr 1fr;gap:14px}
.qty-toggle{display:flex;align-items:center;gap:8px;padding:10px 13px;background:#fff;border:1.5px solid #A7F3D0;border-radius:10px;cursor:pointer;grid-column:1/-1}
.qty-toggle input[type=checkbox]{width:17px;height:17px;accent-color:#059669;cursor:pointer;flex-shrink:0}
.qty-toggle label{font-size:13px;font-weight:600;color:#065F46;cursor:pointer;line-height:1.3}
.qty-fields{grid-column:1/-1;display:grid;grid-template-columns:1fr 1fr 1fr;gap:12px}
/* ── INVENTORY PANEL (Edit right column) ── */
.stock-card{background:linear-gradient(135deg,#0F2645 0%,#1558A8 100%);border-radius:14px;padding:18px 22px;color:#fff;margin-bottom:14px}
.stock-num{font-size:44px;font-weight:800;letter-spacing:-2px;line-height:1}
.stock-unit-lbl{font-size:14px;font-weight:600;opacity:.7;margin-left:5px}
.stock-sub{font-size:11px;color:rgba(255,255,255,.5);text-transform:uppercase;letter-spacing:.5px;margin-top:5px}
.inv-actions{display:flex;flex-direction:column;gap:8px;margin-bottom:14px}
.btn-add-batch{height:42px;background:linear-gradient(135deg,#059669,#047857);color:#fff;border:none;border-radius:11px;font-family:'Outfit',sans-serif;font-size:14px;font-weight:700;cursor:pointer;width:100%;display:flex;align-items:center;justify-content:center;gap:8px;transition:all .18s;box-shadow:0 3px 10px rgba(5,150,105,.25)}
.btn-add-batch:hover{transform:translateY(-1px);box-shadow:0 5px 15px rgba(5,150,105,.3)}
.btn-detail-link{height:38px;background:var(--white);border:1.5px solid var(--border);border-radius:10px;font-size:13px;font-weight:600;color:var(--muted);text-decoration:none;display:flex;align-items:center;justify-content:center;gap:6px;transition:all .15s}
.btn-detail-link:hover{border-color:var(--blue);color:var(--blue)}
.batch-panel{background:var(--white);border:1px solid var(--border);border-radius:14px;overflow:hidden}
.batch-panel-head{padding:11px 16px;background:var(--surface);border-bottom:1px solid var(--border);font-size:12px;font-weight:700;color:var(--navy);text-transform:uppercase;letter-spacing:.5px}
.batch-row{padding:11px 16px;border-bottom:.5px solid #F0F4FB;display:flex;align-items:center;gap:10px}
.batch-row:last-child{border-bottom:none}
.batch-row:hover{background:#FAFBFF}
.bno{font-family:monospace;font-size:12px;font-weight:700;color:var(--navy);flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
.bqty{font-size:15px;font-weight:800;color:var(--ink);flex-shrink:0}
.bhsd{font-size:11.5px;flex-shrink:0}
.bhsd.ok{color:var(--green);font-weight:700}
.bhsd.warn{color:var(--gold);font-weight:700}
.bhsd.err{color:var(--red);font-weight:700}
.empty-batch{padding:28px;text-align:center;color:var(--muted);font-size:13px}
/* ── BATCH ADD MODAL ── */
.modal-overlay{position:fixed;inset:0;background:rgba(11,22,40,.6);z-index:500;display:none;align-items:center;justify-content:center;backdrop-filter:blur(3px);animation:fadeIn .18s ease}
.modal-overlay.open{display:flex}
@keyframes fadeIn{from{opacity:0}to{opacity:1}}
.batch-modal{background:#fff;border-radius:20px;width:560px;max-width:95vw;max-height:90vh;overflow-y:auto;box-shadow:0 24px 80px rgba(0,0,0,.3);animation:slideUp .22s ease}
@keyframes slideUp{from{transform:translateY(20px);opacity:0}to{transform:translateY(0);opacity:1}}
.bm-head{padding:18px 24px;background:linear-gradient(90deg,#0F2645,#1558A8);color:#fff;display:flex;align-items:center;justify-content:space-between;border-radius:20px 20px 0 0;flex-shrink:0}
.bm-title{font-size:15px;font-weight:700}
.bm-sub{font-size:11.5px;opacity:.6;margin-top:2px}
.bm-close{width:30px;height:30px;background:rgba(255,255,255,.15);border:none;color:#fff;border-radius:8px;cursor:pointer;font-size:16px;display:flex;align-items:center;justify-content:center}
.bm-close:hover{background:rgba(255,255,255,.25)}
.bm-body{padding:22px 24px;display:grid;grid-template-columns:1fr 1fr;gap:14px}
.bm-actions{padding:14px 24px 20px;display:flex;gap:10px;align-items:center;border-top:1px solid var(--border)}
/* ── TOAST NOTIFICATION ── */
.toast{position:fixed;top:76px;right:24px;z-index:900;min-width:280px;max-width:400px;padding:13px 18px;border-radius:12px;font-size:13.5px;font-weight:600;display:flex;align-items:flex-start;gap:10px;box-shadow:0 8px 30px rgba(0,0,0,.18);animation:toastIn .28s ease;pointer-events:none}
@keyframes toastIn{from{transform:translateY(-12px);opacity:0}to{transform:translateY(0);opacity:1}}
.toast-ok{background:#F0FDF4;border:1.5px solid #A7F3D0;color:#065F46}
.toast-err{background:#FEF2F2;border:1.5px solid #FECACA;color:#991B1B}
.toast-warn{background:#FFFBEB;border:1.5px solid #FDE68A;color:#92400E}
.toast-icon{font-size:16px;flex-shrink:0;margin-top:1px}
.inline-err{font-size:11.5px;color:var(--red);font-weight:600;margin-top:4px;display:block}
.inline-warn{font-size:11.5px;color:var(--gold);font-weight:600;margin-top:4px;display:block}
/* ── NOT FOUND STATE ── */
.not-found-wrap{display:flex;align-items:center;justify-content:center;min-height:60vh}
.not-found-card{background:var(--white);border:1px solid var(--border);border-radius:20px;padding:48px 40px;text-align:center;max-width:480px;box-shadow:0 4px 20px rgba(21,88,168,.06)}
.nf-icon{font-size:52px;margin-bottom:18px}
.nf-title{font-size:20px;font-weight:800;color:var(--ink);margin-bottom:8px}
.nf-sub{font-size:13.5px;color:var(--muted);line-height:1.6;margin-bottom:24px}
.nf-actions{display:flex;gap:10px;justify-content:center;flex-wrap:wrap}
.nf-btn-primary{height:44px;padding:0 24px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;border-radius:11px;font-family:'Outfit',sans-serif;font-size:14px;font-weight:700;cursor:pointer;text-decoration:none;display:inline-flex;align-items:center;gap:8px}
.nf-btn-sec{height:44px;padding:0 20px;background:var(--white);border:1.5px solid var(--border);border-radius:11px;font-size:13.5px;font-weight:600;color:var(--muted);text-decoration:none;display:inline-flex;align-items:center;gap:8px;transition:.15s}
.nf-btn-sec:hover{border-color:var(--blue);color:var(--navy)}
</style>
</head>
<body>

<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">
  <div class="topbar">
    <span class="topbar-title">
      <%= isNew ? "➕ Thêm thuốc mới" : (editNotFound ? "⚠️ Không tìm thấy thuốc" : "✏️ Sửa — " + vName) %>
    </span>
    <div class="topbar-right">
      <% if (!isNew && !editNotFound) { %>
      <a href="${pageContext.request.contextPath}/medicines?action=detail&id=<%= m.getMedicineId() %>"
         class="btn-back">📋 Chi tiết lô đầy đủ</a>
      <% } %>
      <a href="${pageContext.request.contextPath}/medicines" class="btn-back">← Kho thuốc</a>
    </div>
  </div>

  <div class="content">

    <%-- Toast notification (populated by JS from URL params) --%>
    <div id="toastBox"></div>

    <%-- Section tabs (navigate between medicine-related pages) --%>
    <div class="section-tabs">
      <a href="${pageContext.request.contextPath}/medicines"            class="section-tab active">💊 Thuốc &amp; Lô hàng</a>
      <a href="${pageContext.request.contextPath}/purchase-orders"      class="section-tab">📑 Đơn đặt hàng</a>
      <a href="${pageContext.request.contextPath}/categories"           class="section-tab">🏷️ Danh mục</a>
    </div>

    <%-- ══ NOT FOUND STATE ══ --%>
    <% if (editNotFound) { %>
    <div class="not-found-wrap">
      <div class="not-found-card">
        <div class="nf-icon">🔍</div>
        <div class="nf-title">Không tìm thấy thuốc</div>
        <div class="nf-sub">
          Thuốc bạn đang tìm không tồn tại trong hệ thống hoặc đã bị xóa.<br>
          Bạn có đang muốn <strong>thêm một thuốc mới</strong> không?
        </div>
        <div class="nf-actions">
          <a href="${pageContext.request.contextPath}/medicines?action=new" class="nf-btn-primary">
            ➕ Thêm thuốc mới →
          </a>
          <a href="${pageContext.request.contextPath}/medicines" class="nf-btn-sec">
            ← Quay lại danh sách
          </a>
        </div>
      </div>
    </div>
    <% } else { %>

    <%-- Page header --%>
    <div class="page-title"><%= isNew ? "Thêm thuốc mới" : "Sửa thông tin thuốc" %></div>
    <div class="page-sub"><%= isNew
        ? "Tạo hồ sơ thuốc — tồn kho bắt đầu từ 0, tăng khi nhập lô."
        : "Chỉnh sửa thông tin hồ sơ và quản lý tồn kho theo lô ngay trên trang này." %></div>

    <%-- Error block --%>
    <% if (hasErrors) { %>
    <div class="err-block">
      <div class="err-title">⚠️ Vui lòng kiểm tra lại:</div>
      <ul><% for (String e : errs) { %><li><%= e %></li><% } %></ul>
    </div>
    <% } %>

    <%-- BẮT TRÙNG: thuốc đã tồn tại → gợi ý nhập lô mới thay vì tạo trùng --%>
    <% com.medicare.entity.Medicines dupMed =
           (com.medicare.entity.Medicines) request.getAttribute("dupMedicine");
       if (dupMed != null) { %>
    <div style="background:#fef2f2;border:2px solid #fca5a5;border-radius:14px;padding:16px 20px;margin-bottom:18px;display:flex;align-items:center;gap:14px;flex-wrap:wrap">
      <span style="font-size:26px">🚫</span>
      <div style="flex:1;min-width:220px">
        <div style="font-weight:800;color:#991b1b;font-size:14px">Thuốc này đã có trong hệ thống!</div>
        <div style="font-size:12.5px;color:#b91c1c;margin-top:3px">
          <b><%= dupMed.getMedicineName() %></b> (<%= dupMed.getMedicineCode() %>)
          — không tạo trùng. Bạn có muốn <b>nhập thêm lô mới</b> cho thuốc này không?
        </div>
      </div>
      <a href="${pageContext.request.contextPath}/medicines?action=detail&id=<%= dupMed.getMedicineId() %>"
         style="background:linear-gradient(135deg,#059669,#047857);color:#fff;text-decoration:none;padding:11px 20px;border-radius:11px;font-weight:800;font-size:13.5px;white-space:nowrap">
        📦 Nhập lô mới cho thuốc này →
      </a>
    </div>
    <% } %>

    <%-- ══ EDIT MODE: Two-column layout ══ --%>
    <% if (!isNew) { %>
    <div class="page-grid">

      <%-- LEFT: Form column --%>
      <div class="form-col">
        <form method="post" action="${pageContext.request.contextPath}/medicines">
          <input type="hidden" name="action" value="save-medicine">
          <input type="hidden" name="medicineId" value="<%= m.getMedicineId() %>">

          <%-- Thông tin cơ bản --%>
          <div class="form-card">
            <div class="form-card-head">
              <div class="form-card-icon">💊</div>
              <div><h2>Thông tin cơ bản</h2><p>Tên, phân loại và đơn vị tính</p></div>
            </div>
            <div class="form-body">
              <div class="field span-2">
                <label class="field-label">Tên thuốc <span class="req">*</span></label>
                <input type="text" name="medicineName" class="field-input" value="<%= vName %>" required>
              </div>
              <div class="field">
                <label class="field-label">Tên hoạt chất (generic)</label>
                <input type="text" name="genericName" class="field-input" value="<%= vGeneric %>" placeholder="VD: Acetaminophen">
              </div>
              <div class="field">
                <label class="field-label">Đơn vị tính <span class="req">*</span></label>
                <input type="text" name="unit" class="field-input" value="<%= vUnit %>" required>
              </div>
              <div class="field">
                <label class="field-label">Danh mục <span class="req">*</span>
                  <button type="button" onclick="openCatModal()" class="add-btn-small">➕ Thêm</button>
                </label>
                <select name="categoryId" id="categoryId" class="field-input" required>
                  <option value="">-- Chọn danh mục --</option>
                  <% if (cats != null) for (com.medicare.entity.Category c : cats) { %>
                  <option value="<%= c.getCategoryId() %>" <%= c.getCategoryId() == vCatId ? "selected" : "" %>><%= c.getCategoryName() %></option>
                  <% } %>
                </select>
              </div>
              <div class="field">
                <label class="field-label">Nhà sản xuất <span class="req">*</span>
                  <button type="button" onclick="openMfrModal()" class="add-btn-small">➕ Thêm</button>
                </label>
                <select name="manufacturerId" id="manufacturerId" class="field-input" required>
                  <option value="">-- Chọn nhà sản xuất --</option>
                  <% if (mfrs != null) for (com.medicare.entity.Manufacturer mf : mfrs) { %>
                  <option value="<%= mf.getManufacturerId() %>" <%= mf.getManufacturerId() == vMfrId ? "selected" : "" %>><%= mf.getName() %></option>
                  <% } %>
                </select>
              </div>
              <div class="field">
                <label class="field-label">Mã vạch (barcode)</label>
                <input type="text" name="barcode" class="field-input" value="<%= vBarcode %>" placeholder="Quét hoặc nhập">
              </div>
              <div class="field">
                <label class="field-label">Số đăng ký lưu hành</label>
                <input type="text" name="registrationNumber" class="field-input" value="<%= vRegNo %>" placeholder="VD: VD-12345-16">
              </div>
            </div>
          </div>

          <%-- Giá & Cấu hình kho --%>
          <div class="form-card">
            <div class="form-card-head">
              <div class="form-card-icon">💰</div>
              <div><h2>Giá bán &amp; Cấu hình kho</h2><p>Giá, ngưỡng cảnh báo, vị trí kệ</p></div>
            </div>
            <div class="form-body">
              <div class="field">
                <label class="field-label">Giá bán (VNĐ) <span class="req">*</span></label>
                <div class="price-wrap">
                  <input type="number" name="sellingPrice" class="field-input" value="<%= vPrice %>" min="0" step="500" required>
                  <span class="price-suffix">₫</span>
                </div>
              </div>
              <div class="field">
                <label class="field-label">Tồn kho tối thiểu (cảnh báo)</label>
                <input type="number" name="minInventory" class="field-input" value="<%= vMinInv %>" min="0">
                <span class="field-hint">Hệ thống báo đỏ khi xuống dưới mức này</span>
              </div>
              <div class="field">
                <label class="field-label">Cảnh báo HH trước (ngày)</label>
                <input type="number" name="expiryAlertDays" class="field-input" value="<%= vExpDays %>" min="1">
              </div>
              <div class="field">
                <label class="field-label">Vị trí kệ
                  <button type="button" onclick="openShelfMgr()" style="margin-left:6px;background:#EFF6FF;border:1px solid #BFDBFE;color:#1558A8;border-radius:7px;padding:2px 9px;font-size:11px;font-weight:700;cursor:pointer;font-family:inherit">🗂️ Quản lý kệ</button>
                </label>
                <select name="shelfId" class="field-input shelf-select">
                  <option value="">-- Chọn kệ (tùy chọn) --</option>
                  <% if (shelves != null) for (com.medicare.entity.Shelf sh : shelves) { %>
                  <option value="<%= sh.getShelfId() %>" <%= sh.getShelfId() == vShelfId ? "selected" : "" %>><%= sh.getShelfName() != null ? sh.getShelfName() : "Kệ " + sh.getShelfId() %></option>
                  <% } %>
                </select>
              </div>
            </div>
          </div>

          <%-- Thông tin y tế --%>
          <div class="form-card">
            <div class="form-card-head">
              <div class="form-card-icon">🩺</div>
              <div><h2>Thông tin y tế</h2><p>Loại thuốc, liều dùng, bảo quản</p></div>
            </div>
            <div class="form-body">
              <div class="field span-2">
                <div class="checkbox-row">
                  <input type="checkbox" id="rxCheck" name="isPrescriptionRequired" value="on" <%= vRx ? "checked" : "" %>>
                  <label for="rxCheck">⚕️ Thuốc kê đơn (Rx) — cần đơn thuốc của bác sĩ khi bán</label>
                </div>
              </div>
              <div class="field span-2">
                <label class="field-label">Liều dùng / Hướng dẫn sử dụng</label>
                <textarea name="dosage" class="field-input" placeholder="VD: Người lớn 1-2 viên/lần..."><%= vDosage %></textarea>
              </div>
              <div class="field span-2">
                <label class="field-label">Chống chỉ định</label>
                <textarea name="contraindications" class="field-input" placeholder="Các trường hợp không nên dùng..."><%= vContra %></textarea>
              </div>
              <div class="field span-2">
                <label class="field-label">Điều kiện bảo quản</label>
                <textarea name="storageConditions" class="field-input" placeholder="VD: Nơi khô ráo, tránh ánh nắng..."><%= vStorage %></textarea>
              </div>
            </div>
          </div>

          <div class="action-row">
            <button type="submit" class="btn-submit">💾 Lưu thay đổi</button>
            <a href="${pageContext.request.contextPath}/medicines" class="btn-cancel">Hủy</a>
          </div>
        </form>
      </div><%-- /form-col --%>

      <%-- RIGHT: Inventory panel (sticky) --%>
      <div class="inv-panel">

        <%-- Stock summary card --%>
        <div class="stock-card">
          <div>
            <span class="stock-num">${totalStock}</span>
            <span class="stock-unit-lbl"><%= vUnit %></span>
          </div>
          <div class="stock-sub">Tổng tồn kho hiện tại</div>
          <div style="margin-top:12px;display:flex;flex-wrap:wrap;gap:8px">
            <span style="font-size:11px;padding:3px 9px;border-radius:20px;background:rgba(255,255,255,.12);color:rgba(255,255,255,.75)">
              💊 <%= vName %>
            </span>
          </div>
        </div>

        <%-- Action buttons --%>
        <div class="inv-actions">
          <button class="btn-add-batch" onclick="openBatchModal()">
            📥 Nhập lô mới
          </button>
          <a href="${pageContext.request.contextPath}/medicines?action=detail&id=<%= m.getMedicineId() %>"
             class="btn-detail-link">📋 Xem lịch sử lô đầy đủ</a>
        </div>

        <%-- Batch list --%>
        <div class="batch-panel">
          <div class="batch-panel-head">Lô đang hoạt động</div>
          <c:choose>
            <c:when test="${empty batches}">
              <div class="empty-batch">
                📦 Chưa có lô nào<br>
                <span style="font-size:12px">Nhấn <strong>Nhập lô mới</strong> để bắt đầu</span>
              </div>
            </c:when>
            <c:otherwise>
              <c:forEach var="b" items="${batches}">
                <c:set var="isExp"  value="${b.expiryDate.isBefore(today)}" />
                <c:set var="isSoon" value="${!isExp and b.expiryDate.isBefore(today90)}" />
                <div class="batch-row">
                  <div style="flex:1;min-width:0">
                    <div class="bno">${b.batchNumber}</div>
                    <div class="bhsd ${isExp ? 'err' : isSoon ? 'warn' : 'ok'}">
                      HH: ${b.expiryDate}
                      <c:if test="${isExp}"> ⛔</c:if>
                      <c:if test="${isSoon and !isExp}"> ⏳</c:if>
                    </div>
                  </div>
                  <span class="bqty">${b.currentQuantity}</span>
                  <span style="font-size:11px;color:var(--muted);margin-left:2px"><%= vUnit %></span>
                </div>
              </c:forEach>
            </c:otherwise>
          </c:choose>
        </div>

        <div style="margin-top:10px;font-size:11.5px;color:var(--muted);line-height:1.5;padding:0 2px">
          ℹ️ Tồn kho chỉ thay đổi qua: <strong>Nhập lô</strong> · <strong>Hóa đơn bán</strong> · <strong>Tiêu hủy lô</strong>
        </div>
      </div><%-- /inv-panel --%>

    </div><%-- /page-grid --%>

    <%-- ══ CREATE MODE: Single-column form ══ --%>
    <% } else { %>

    <div class="add-hint">
      <span style="font-size:18px;flex-shrink:0">💡</span>
      <div><strong>Tạo hồ sơ thuốc:</strong> Bước này chỉ đăng ký thuốc (tồn kho = 0). Sau khi lưu, hãy vào <strong>Nhập lô</strong> để nhập hàng vật lý vào kho — hoặc nhập số lượng thêm vào ngay bên dưới nếu đã có hàng sẵn.</div>
    </div>

    <form method="post" action="${pageContext.request.contextPath}/medicines" style="max-width:860px;margin:0 auto">
      <input type="hidden" name="action" value="save-medicine">

      <%-- Thông tin cơ bản --%>
      <div class="form-card">
        <div class="form-card-head">
          <div class="form-card-icon">💊</div>
          <div><h2>Thông tin cơ bản</h2><p>Tên, phân loại và đơn vị tính</p></div>
        </div>
        <div class="form-body">
          <div class="field span-2">
            <label class="field-label">Tên thuốc <span class="req">*</span></label>
            <input type="text" name="medicineName" class="field-input" placeholder="VD: Paracetamol 500mg" required>
          </div>
          <div class="field">
            <label class="field-label">Tên hoạt chất (generic)</label>
            <input type="text" name="genericName" class="field-input" placeholder="VD: Acetaminophen">
          </div>
          <div class="field">
            <label class="field-label">Đơn vị tính <span class="req">*</span></label>
            <input type="text" name="unit" class="field-input" placeholder="VD: Viên, Gói, Chai" required>
          </div>
          <div class="field">
            <label class="field-label">Danh mục <span class="req">*</span>
              <button type="button" onclick="openCatModal()" class="add-btn-small">➕ Thêm</button>
            </label>
            <select name="categoryId" id="categoryId" class="field-input" required>
              <option value="">-- Chọn danh mục --</option>
              <% if (cats != null) for (com.medicare.entity.Category c : cats) { %>
              <option value="<%= c.getCategoryId() %>"><%= c.getCategoryName() %></option>
              <% } %>
            </select>
          </div>
          <div class="field">
            <label class="field-label">Nhà sản xuất <span class="req">*</span>
              <button type="button" onclick="openMfrModal()" class="add-btn-small">➕ Thêm</button>
            </label>
            <select name="manufacturerId" id="manufacturerId" class="field-input" required>
              <option value="">-- Chọn nhà sản xuất --</option>
              <% if (mfrs != null) for (com.medicare.entity.Manufacturer mf : mfrs) { %>
              <option value="<%= mf.getManufacturerId() %>"><%= mf.getName() %></option>
              <% } %>
            </select>
          </div>
          <div class="field">
            <label class="field-label">Mã vạch (barcode)</label>
            <input type="text" name="barcode" class="field-input" placeholder="Quét hoặc nhập mã vạch">
          </div>
          <div class="field">
            <label class="field-label">Số đăng ký lưu hành</label>
            <input type="text" name="registrationNumber" class="field-input" placeholder="VD: VD-12345-16">
          </div>
        </div>
      </div>

      <%-- Giá & Cấu hình kho --%>
      <div class="form-card">
        <div class="form-card-head">
          <div class="form-card-icon">💰</div>
          <div><h2>Giá bán &amp; Cấu hình kho</h2><p>Giá bán, ngưỡng cảnh báo và vị trí kệ</p></div>
        </div>
        <div class="form-body">
          <div class="field">
            <label class="field-label">Giá bán (VNĐ) <span class="req">*</span></label>
            <div class="price-wrap">
              <input type="number" name="sellingPrice" class="field-input" placeholder="0" min="0" step="500" required>
              <span class="price-suffix">₫</span>
            </div>
          </div>
          <div class="field">
            <label class="field-label">Tồn kho tối thiểu (cảnh báo)</label>
            <input type="number" name="minInventory" class="field-input" value="<%= vMinInv %>" min="0">
            <span class="field-hint">Hệ thống báo đỏ khi xuống dưới mức này</span>
          </div>
          <div class="field">
            <label class="field-label">Cảnh báo HH trước (ngày)</label>
            <input type="number" name="expiryAlertDays" class="field-input" value="<%= vExpDays %>" min="1">
          </div>
          <div class="field">
            <label class="field-label">Vị trí kệ
              <button type="button" onclick="openShelfMgr()" style="margin-left:6px;background:#EFF6FF;border:1px solid #BFDBFE;color:#1558A8;border-radius:7px;padding:2px 9px;font-size:11px;font-weight:700;cursor:pointer;font-family:inherit">🗂️ Quản lý kệ</button>
            </label>
            <select name="shelfId" class="field-input shelf-select">
              <option value="">-- Chọn kệ (tùy chọn) --</option>
              <% if (shelves != null) for (com.medicare.entity.Shelf sh : shelves) { %>
              <option value="<%= sh.getShelfId() %>"><%= sh.getShelfName() != null ? sh.getShelfName() : "Kệ " + sh.getShelfId() %></option>
              <% } %>
            </select>
          </div>

          <%-- Thêm lô đầu — nhập số lượng thêm vào kho (tùy chọn) --%>
          <div class="field span-2" style="border-top:1px dashed var(--border);padding-top:14px;margin-top:4px">
            <div style="display:flex;align-items:center;gap:8px;font-size:13.5px;font-weight:700;color:#065F46">
              📦 Thêm lô đầu vào kho
              <span style="font-weight:500;color:#059669;font-size:11.5px">— nhập số lượng muốn thêm vào ngay khi tạo thuốc, hệ thống sẽ tự tạo lô nhập kho (để 0 nếu chưa có hàng)</span>
            </div>
          </div>
          <div class="field">
            <label class="field-label">Số lượng thêm vào</label>
            <input type="number" id="initialQuantity" name="initialQuantity" class="field-input" value="0"
                   placeholder="VD: 100" min="0" oninput="onInitQtyChange()">
            <span class="field-hint">Hệ thống tự tạo lô nhập kho khi &gt; 0</span>
          </div>
          <div class="field">
            <label class="field-label">Ngày hết hạn lô <span id="initExpReq" class="req" style="display:none">*</span></label>
            <input type="date" id="initialExpiryDate" name="initialExpiryDate" class="field-input">
            <span class="field-hint">Bắt buộc khi có số lượng thêm vào</span>
          </div>
          <div class="field">
            <label class="field-label">Giá nhập kho (₫)</label>
            <div class="price-wrap">
              <input type="number" name="initialImportPrice" class="field-input"
                     placeholder="0" min="0" step="500" style="padding-right:36px">
              <span class="price-suffix">₫</span>
            </div>
            <span class="field-hint">Để trống nếu không biết</span>
          </div>
        </div>
      </div>

      <%-- Thông tin y tế --%>
      <div class="form-card">
        <div class="form-card-head">
          <div class="form-card-icon">🩺</div>
          <div><h2>Thông tin y tế</h2><p>Loại thuốc, liều dùng, bảo quản</p></div>
        </div>
        <div class="form-body">
          <div class="field span-2">
            <div class="checkbox-row">
              <input type="checkbox" id="rxCheck" name="isPrescriptionRequired" value="on">
              <label for="rxCheck">⚕️ Thuốc kê đơn (Rx) — cần đơn thuốc của bác sĩ khi bán</label>
            </div>
          </div>
          <div class="field span-2">
            <label class="field-label">Liều dùng / Hướng dẫn sử dụng</label>
            <textarea name="dosage" class="field-input" placeholder="VD: Người lớn: 1-2 viên/lần, 3-4 lần/ngày..."></textarea>
          </div>
          <div class="field span-2">
            <label class="field-label">Chống chỉ định</label>
            <textarea name="contraindications" class="field-input" placeholder="Các trường hợp không nên dùng..."></textarea>
          </div>
          <div class="field span-2">
            <label class="field-label">Điều kiện bảo quản</label>
            <textarea name="storageConditions" class="field-input" placeholder="VD: Nơi khô ráo, thoáng mát, tránh ánh nắng..."></textarea>
          </div>
        </div>
      </div>

      <div class="action-row">
        <button type="submit" class="btn-submit">➕ Tạo hồ sơ thuốc</button>
        <a href="${pageContext.request.contextPath}/medicines" class="btn-cancel">Hủy</a>
      </div>
    </form>

    <% } %><%-- end isNew/!isNew --%>
    <% } %><%-- end editNotFound check --%>

  </div><%-- /content --%>
</div><%-- /main --%>

<%-- ══ BATCH ADD MODAL (Edit mode only) ══ --%>
<% if (!isNew && !editNotFound) {
   java.math.BigDecimal lastImportPrice = (java.math.BigDecimal) request.getAttribute("lastImportPrice");
%>
<div class="modal-overlay" id="batchModal" onclick="closeBatchModal(event)">
  <div class="batch-modal">
    <div class="bm-head">
      <div>
        <div class="bm-title">📥 Nhập lô mới</div>
        <div class="bm-sub">
          💊 <%= vName %> &nbsp;·&nbsp; Tồn kho: ${totalStock} <%= vUnit %>
          <% if (lastImportPrice != null) { %>
          &nbsp;·&nbsp; Giá nhập trước: <strong><%= String.format("%,.0f", lastImportPrice) %>₫</strong>
          <% } %>
        </div>
      </div>
      <button class="bm-close" onclick="document.getElementById('batchModal').classList.remove('open')">✕</button>
    </div>
    <form id="batchModalForm" method="post" action="${pageContext.request.contextPath}/medicines">
      <input type="hidden" name="action" value="save-batch">
      <input type="hidden" name="medicineId" value="<%= m.getMedicineId() %>">
      <input type="hidden" name="poMode" value="none">
      <input type="hidden" name="returnTo" value="edit">
      <div class="bm-body">
        <div class="field span-2">
          <label class="field-label">Số lô hàng <span class="req">*</span>
            <span style="font-size:11px;font-weight:500;color:var(--muted)">— Nếu trùng lô cũ, hệ thống sẽ cộng thêm số lượng</span>
          </label>
          <input type="text" name="batchNumber" id="bmBatchNo" class="field-input"
                 placeholder="VD: BATCH-2024-001" required>
        </div>
        <div class="field">
          <label class="field-label">Số lượng nhập <span class="req">*</span></label>
          <input type="number" name="initialQuantity" id="bmQty" class="field-input"
                 placeholder="VD: 100" min="1" required>
        </div>
        <div class="field">
          <label class="field-label">Ngày hết hạn (HSD) <span class="req">*</span></label>
          <input type="date" name="expiryDate" id="bmExpiry" class="field-input" required>
          <span class="inline-err" id="bmExpiryErr"></span>
        </div>
        <div class="field">
          <label class="field-label">Giá nhập kho (₫) <span class="req">*</span></label>
          <div class="price-wrap">
            <input type="number" name="importPrice" id="bmPrice" class="field-input"
                   placeholder="0" min="0" step="500" required style="padding-right:36px">
            <span class="price-suffix">₫</span>
          </div>
          <span class="inline-warn" id="bmPriceWarn"></span>
        </div>
        <div class="field">
          <label class="field-label">Ngày sản xuất <span style="font-size:11px;font-weight:400;color:var(--muted)">(tùy chọn)</span></label>
          <input type="date" name="manufactureDate" id="bmMfDate" class="field-input">
          <span class="inline-err" id="bmMfErr"></span>
        </div>
      </div>
      <div class="bm-actions">
        <button type="submit" id="bmSubmitBtn" class="btn-submit" style="height:42px;font-size:14px">📥 Nhập lô vào kho</button>
        <button type="button" class="btn-cancel" onclick="document.getElementById('batchModal').classList.remove('open')" style="height:42px">Hủy</button>
        <span style="margin-left:auto;font-size:12px;color:var(--muted)">Sau khi nhập sẽ về lại trang này</span>
      </div>
    </form>
  </div>
</div>
<% } %>

<!-- ══ Modal tạo danh mục inline ══ -->
<div id="catModal" style="display:none;position:fixed;inset:0;background:rgba(11,22,40,.55);z-index:600;align-items:center;justify-content:center;backdrop-filter:blur(2px)">
  <div style="background:#fff;border-radius:18px;width:400px;max-width:92vw;overflow:hidden;box-shadow:0 20px 60px rgba(0,0,0,.3)">
    <div style="padding:18px 22px;background:linear-gradient(90deg,#0F2645,#1558A8);color:#fff;display:flex;align-items:center;justify-content:space-between">
      <h3 style="font-size:15px;font-weight:700;margin:0">📂 Thêm danh mục thuốc</h3>
      <button onclick="closeCatModal()" style="background:rgba(255,255,255,.15);border:none;color:#fff;width:28px;height:28px;border-radius:8px;cursor:pointer;font-size:14px">✕</button>
    </div>
    <div style="padding:22px">
      <div style="margin-bottom:14px">
        <label style="font-size:12.5px;font-weight:700;color:#0F2645;display:block;margin-bottom:6px">Tên danh mục <span style="color:#DC2626">*</span></label>
        <input id="catNameInput" type="text" placeholder="VD: Kháng sinh, Giảm đau..."
               style="width:100%;height:42px;padding:0 14px;border:1.5px solid #D5E0F0;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;outline:none;box-sizing:border-box"
               onkeydown="if(event.key==='Enter'){event.preventDefault();saveCat()}">
      </div>
      <div style="margin-bottom:18px">
        <label style="font-size:12.5px;font-weight:700;color:#0F2645;display:block;margin-bottom:6px">Mô tả (không bắt buộc)</label>
        <input id="catDescInput" type="text" placeholder="Mô tả ngắn"
               style="width:100%;height:42px;padding:0 14px;border:1.5px solid #D5E0F0;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;outline:none;box-sizing:border-box">
      </div>
      <div id="catErr" style="font-size:12px;color:#DC2626;margin-bottom:10px;display:none"></div>
      <div style="display:flex;gap:10px">
        <button onclick="saveCat()" style="flex:1;height:40px;background:linear-gradient(135deg,#1558A8,#0D3F85);color:#fff;border:none;border-radius:11px;font-family:'Outfit',sans-serif;font-size:14px;font-weight:700;cursor:pointer">➕ Tạo danh mục</button>
        <button onclick="closeCatModal()" style="height:40px;padding:0 18px;background:#fff;border:1.5px solid #D5E0F0;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;color:#7A90B0;cursor:pointer">Hủy</button>
      </div>
    </div>
  </div>
</div>

<!-- ══ Modal tạo nhà sản xuất inline ══ -->
<div id="mfrModal" style="display:none;position:fixed;inset:0;background:rgba(11,22,40,.55);z-index:600;align-items:center;justify-content:center;backdrop-filter:blur(2px)">
  <div style="background:#fff;border-radius:18px;width:420px;max-width:92vw;overflow:hidden;box-shadow:0 20px 60px rgba(0,0,0,.3)">
    <div style="padding:18px 22px;background:linear-gradient(90deg,#0F2645,#1558A8);color:#fff;display:flex;align-items:center;justify-content:space-between">
      <h3 style="font-size:15px;font-weight:700;margin:0">🏭 Thêm nhà sản xuất</h3>
      <button onclick="closeMfrModal()" style="background:rgba(255,255,255,.15);border:none;color:#fff;width:28px;height:28px;border-radius:8px;cursor:pointer;font-size:14px">✕</button>
    </div>
    <div style="padding:22px">
      <div style="margin-bottom:14px">
        <label style="font-size:12.5px;font-weight:700;color:#0F2645;display:block;margin-bottom:6px">Tên nhà sản xuất <span style="color:#DC2626">*</span></label>
        <input id="mfrNameInput" type="text" placeholder="VD: Sanofi, Pfizer, Imexpharm..."
               style="width:100%;height:42px;padding:0 14px;border:1.5px solid #D5E0F0;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;outline:none;box-sizing:border-box">
      </div>
      <div style="display:grid;grid-template-columns:1fr 1fr;gap:12px;margin-bottom:18px">
        <div>
          <label style="font-size:12.5px;font-weight:700;color:#0F2645;display:block;margin-bottom:6px">Quốc gia</label>
          <input id="mfrCountryInput" type="text" placeholder="VD: Pháp, Việt Nam"
                 style="width:100%;height:42px;padding:0 14px;border:1.5px solid #D5E0F0;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;outline:none;box-sizing:border-box">
        </div>
        <div>
          <label style="font-size:12.5px;font-weight:700;color:#0F2645;display:block;margin-bottom:6px">Liên hệ</label>
          <input id="mfrContactInput" type="text" placeholder="Website hoặc SĐT"
                 style="width:100%;height:42px;padding:0 14px;border:1.5px solid #D5E0F0;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;outline:none;box-sizing:border-box">
        </div>
      </div>
      <div id="mfrErr" style="font-size:12px;color:#DC2626;margin-bottom:10px;display:none"></div>
      <div style="display:flex;gap:10px">
        <button onclick="saveMfr()" style="flex:1;height:40px;background:linear-gradient(135deg,#1558A8,#0D3F85);color:#fff;border:none;border-radius:11px;font-family:'Outfit',sans-serif;font-size:14px;font-weight:700;cursor:pointer">➕ Tạo nhà sản xuất</button>
        <button onclick="closeMfrModal()" style="height:40px;padding:0 18px;background:#fff;border:1.5px solid #D5E0F0;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;color:#7A90B0;cursor:pointer">Hủy</button>
      </div>
    </div>
  </div>
</div>

<script>
const CTX = '${pageContext.request.contextPath}';
<%-- Giá nhập lần cuối để so sánh outlier — 0 nếu chưa có lô nào --%>
<% java.math.BigDecimal _lp = (java.math.BigDecimal) request.getAttribute("lastImportPrice"); %>
const LAST_IMPORT_PRICE = <%= _lp != null ? _lp.toPlainString() : "0" %>;

// ── TOAST ────────────────────────────────────────────────────────────────────
function showToast(type, msg, duration) {
  const box = document.getElementById('toastBox');
  if (!box) return;
  const icons = {ok:'✅', err:'❌', warn:'⚠️'};
  box.innerHTML = `<div class="toast toast-${type}"><span class="toast-icon">${icons[type]||'ℹ️'}</span><span>${msg}</span></div>`;
  setTimeout(() => { box.innerHTML = ''; }, duration || 4500);
}

// Đọc URL params và hiển thị toast ngay khi load
(function() {
  const p = new URLSearchParams(window.location.search);
  const msg = p.get('msg');
  const addedQty = p.get('addedQty');
  const batchErr = p.get('batchErr');
  if (batchErr) {
    showToast('err', decodeURIComponent(batchErr), 6000);
  } else if (msg === 'batch-added') {
    showToast('ok', 'Nhập lô mới thành công!');
  } else if (msg === 'batch-stock-added') {
    showToast('ok', `Đã cộng thêm ${addedQty || ''} vào lô hiện tại!`);
  } else if (msg === 'batch-updated') {
    showToast('ok', 'Đã cập nhật lô thành công!');
  } else if (msg === 'updated') {
    showToast('ok', 'Đã lưu thông tin thuốc!');
  } else if (msg === 'batch-stock-fail' || msg === 'error') {
    showToast('err', 'Có lỗi xảy ra, vui lòng thử lại.');
  }
  // Xóa query params khỏi URL (clean address bar)
  if (msg || batchErr) {
    const clean = window.location.pathname + (p.get('action') ? '?action=' + p.get('action') + (p.get('id') ? '&id=' + p.get('id') : '') : '');
    window.history.replaceState({}, '', clean);
  }
})();

// ── BATCH MODAL ──────────────────────────────────────────────────────────────
function openBatchModal() {
  const modal = document.getElementById('batchModal');
  if (!modal) return;
  const bno = document.getElementById('bmBatchNo');
  if (bno && !bno.value) {
    const ts = new Date().toISOString().slice(2,10).replace(/-/g,'');
    bno.value = 'LO-<%= m != null ? m.getMedicineId() : 0 %>-' + ts;
  }
  // Reset inline errors
  ['bmExpiryErr','bmMfErr','bmPriceWarn'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.textContent = '';
  });
  const btn = document.getElementById('bmSubmitBtn');
  if (btn) btn.disabled = false;
  modal.classList.add('open');
  setTimeout(() => { const q = document.getElementById('bmQty'); if (q) q.focus(); }, 120);
}
function closeBatchModal(e) {
  if (e && e.target !== document.getElementById('batchModal')) return;
  document.getElementById('batchModal').classList.remove('open');
}
document.addEventListener('keydown', e => {
  if (e.key === 'Escape') {
    const modal = document.getElementById('batchModal');
    if (modal) modal.classList.remove('open');
  }
});

// Client-side validation cho batch modal
const batchForm = document.getElementById('batchModalForm');
if (batchForm) {
  // Live: clear errors khi user sửa
  document.getElementById('bmExpiry').addEventListener('change', validateBatchDates);
  document.getElementById('bmMfDate').addEventListener('change', validateBatchDates);
  document.getElementById('bmPrice').addEventListener('input', checkPriceOutlier);

  batchForm.addEventListener('submit', function(e) {
    const ok = validateBatchDates();
    if (!ok) { e.preventDefault(); return; }
    checkPriceOutlier(); // warn only, không chặn
    // Disable button chống double-submit
    const btn = document.getElementById('bmSubmitBtn');
    if (btn) { btn.disabled = true; btn.textContent = '⏳ Đang xử lý...'; }
  });
}

function validateBatchDates() {
  const expiryVal  = document.getElementById('bmExpiry').value;
  const mfDateVal  = document.getElementById('bmMfDate').value;
  const expiryErr  = document.getElementById('bmExpiryErr');
  const mfErr      = document.getElementById('bmMfErr');
  expiryErr.textContent = '';
  mfErr.textContent = '';
  let ok = true;

  if (expiryVal) {
    const today = new Date(); today.setHours(0,0,0,0);
    const expDate = new Date(expiryVal);
    if (expDate <= today) {
      expiryErr.textContent = '⛔ Ngày hết hạn phải sau hôm nay!';
      ok = false;
    } else if (mfDateVal) {
      const mfDate = new Date(mfDateVal);
      if (mfDate >= expDate) {
        mfErr.textContent = '⛔ Ngày sản xuất không thể bằng hoặc sau ngày hết hạn!';
        ok = false;
      }
    }
  }
  return ok;
}

function checkPriceOutlier() {
  if (LAST_IMPORT_PRICE <= 0) return;
  const warn = document.getElementById('bmPriceWarn');
  const price = parseFloat(document.getElementById('bmPrice').value);
  if (!price || price <= 0) { warn.textContent = ''; return; }
  const ratio = price / LAST_IMPORT_PRICE;
  if (ratio > 1.5 || ratio < 0.5) {
    const prev = new Intl.NumberFormat('vi-VN').format(LAST_IMPORT_PRICE);
    warn.textContent = `⚠️ Giá chênh lệch nhiều so với lần trước (${prev}₫) — kiểm tra lại.`;
  } else {
    warn.textContent = '';
  }
}

// ── INIT STOCK (Create mode) — HSD bắt buộc khi có số lượng thêm vào ────────
function onInitQtyChange() {
  const qty = parseInt(document.getElementById('initialQuantity').value) || 0;
  const expInput = document.getElementById('initialExpiryDate');
  const reqStar  = document.getElementById('initExpReq');
  if (expInput) expInput.required = qty > 0;
  if (reqStar)  reqStar.style.display = qty > 0 ? 'inline' : 'none';
}

// ── CATEGORY MODAL ──────────────────────────────────────────────────────────
function openCatModal() {
  document.getElementById('catNameInput').value = '';
  document.getElementById('catDescInput').value = '';
  document.getElementById('catErr').style.display = 'none';
  document.getElementById('catModal').style.display = 'flex';
  setTimeout(() => document.getElementById('catNameInput').focus(), 100);
}
function closeCatModal() { document.getElementById('catModal').style.display = 'none'; }
document.getElementById('catModal').addEventListener('click', function(e){ if(e.target===this) closeCatModal(); });

function saveCat() {
  const name = document.getElementById('catNameInput').value.trim();
  const desc = document.getElementById('catDescInput').value.trim();
  const err  = document.getElementById('catErr');
  if (!name) { err.textContent = '⚠️ Vui lòng nhập tên danh mục!'; err.style.display='block'; return; }
  const fd = new FormData();
  fd.append('action', 'create-category-ajax');
  fd.append('categoryName', name);
  fd.append('description', desc);
  fetch(CTX + '/medicines', { method:'POST', body: fd })
    .then(r => r.json())
    .then(data => {
      if (data.ok) {
        const sel = document.getElementById('categoryId');
        sel.appendChild(new Option(data.name, data.id, true, true));
        closeCatModal();
        sel.style.borderColor='#059669'; setTimeout(()=>sel.style.borderColor='',1500);
      } else { err.textContent = data.error||'❌ Lỗi!'; err.style.display='block'; }
    })
    .catch(() => { err.textContent='❌ Lỗi kết nối!'; err.style.display='block'; });
}

// ── MANUFACTURER MODAL ───────────────────────────────────────────────────────
function openMfrModal() {
  ['mfrNameInput','mfrCountryInput','mfrContactInput'].forEach(id => document.getElementById(id).value = '');
  document.getElementById('mfrErr').style.display = 'none';
  document.getElementById('mfrModal').style.display = 'flex';
  setTimeout(() => document.getElementById('mfrNameInput').focus(), 100);
}
function closeMfrModal() { document.getElementById('mfrModal').style.display = 'none'; }
document.getElementById('mfrModal').addEventListener('click', function(e){ if(e.target===this) closeMfrModal(); });

function saveMfr() {
  const name    = document.getElementById('mfrNameInput').value.trim();
  const country = document.getElementById('mfrCountryInput').value.trim();
  const contact = document.getElementById('mfrContactInput').value.trim();
  const err = document.getElementById('mfrErr');
  if (!name) { err.textContent='⚠️ Vui lòng nhập tên nhà sản xuất!'; err.style.display='block'; return; }
  const fd = new FormData();
  fd.append('action','create-manufacturer-ajax');
  fd.append('name', name); fd.append('country', country); fd.append('contactInfo', contact);
  fetch(CTX + '/medicines', { method:'POST', body: fd })
    .then(r => r.json())
    .then(data => {
      if (data.ok) {
        const sel = document.getElementById('manufacturerId');
        sel.appendChild(new Option(data.name, data.id, true, true));
        closeMfrModal();
        sel.style.borderColor='#059669'; setTimeout(()=>sel.style.borderColor='',1500);
      } else { err.textContent=data.error||'❌ Lỗi!'; err.style.display='block'; }
    })
    .catch(() => { err.textContent='❌ Lỗi kết nối!'; err.style.display='block'; });
}

// ══ QUẢN LÝ VỊ TRÍ KỆ (CRUD tại chỗ) ══════════════════════════════════════════
const SHELF_DATA = [
  <% if (shelves != null) { boolean first = true;
       for (com.medicare.entity.Shelf sh : shelves) {
         if (!first) out.print(",");
         first = false; %>
  { id: <%= sh.getShelfId() %>, name: '<%= (sh.getShelfName() != null ? sh.getShelfName() : "Kệ " + sh.getShelfId()).replace("'", "\\'") %>' }
  <% } } %>
];

function openShelfMgr() {
  renderShelfList();
  document.getElementById('shelfMgrModal').style.display = 'flex';
}
function closeShelfMgr() { document.getElementById('shelfMgrModal').style.display = 'none'; }

function renderShelfList() {
  const box = document.getElementById('shelfMgrList');
  if (!SHELF_DATA.length) {
    box.innerHTML = '<div style="text-align:center;color:#94a3b8;font-size:13px;padding:18px 0">Chưa có kệ nào — thêm kệ đầu tiên bên dưới.</div>';
    return;
  }
  box.innerHTML = SHELF_DATA.map(s =>
    '<div style="display:flex;gap:8px;align-items:center;padding:7px 0;border-bottom:1px solid #f1f5f9" data-shelf="' + s.id + '">'
    + '<input type="text" value="' + s.name.replace(/"/g,'&quot;') + '" data-orig="' + s.name.replace(/"/g,'&quot;') + '"'
    + ' style="flex:1;border:1.5px solid #e2e8f0;border-radius:8px;padding:7px 10px;font-size:13px;font-family:inherit">'
    + '<button type="button" onclick="saveShelf(' + s.id + ',this)" style="background:#ECFDF5;border:1px solid #A7F3D0;color:#047857;border-radius:8px;padding:7px 11px;font-size:12px;font-weight:700;cursor:pointer;font-family:inherit">💾</button>'
    + '<button type="button" onclick="deleteShelf(' + s.id + ')" style="background:#FEF2F2;border:1px solid #FECACA;color:#B91C1C;border-radius:8px;padding:7px 11px;font-size:12px;font-weight:700;cursor:pointer;font-family:inherit">🗑️</button>'
    + '</div>').join('');
}

function shelfMgrMsg(text, isErr) {
  const el = document.getElementById('shelfMgrMsg');
  el.textContent = text;
  el.style.color = isErr ? '#B91C1C' : '#047857';
  el.style.display = 'block';
  setTimeout(() => { el.style.display = 'none'; }, 3200);
}

/** Cập nhật lại mọi <select name=shelfId> trên trang sau khi CRUD */
function syncShelfSelects() {
  document.querySelectorAll('select.shelf-select').forEach(sel => {
    const cur = sel.value;
    sel.innerHTML = '<option value="">-- Chọn kệ (tùy chọn) --</option>'
      + SHELF_DATA.map(s => '<option value="' + s.id + '">' + s.name + '</option>').join('');
    if ([...sel.options].some(o => o.value === cur)) sel.value = cur;
  });
}

async function addShelf() {
  const inp = document.getElementById('shelfNewName');
  const name = inp.value.trim();
  if (name.length < 1) { shelfMgrMsg('Nhập tên kệ trước đã!', true); return; }
  const fd = new URLSearchParams({ action: 'create-shelf-ajax', shelfName: name });
  try {
    const r = await fetch('${pageContext.request.contextPath}/medicines', { method: 'POST', body: fd,
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' } });
    const d = await r.json();
    if (d.ok) {
      SHELF_DATA.push({ id: d.id, name: d.name });
      inp.value = '';
      renderShelfList(); syncShelfSelects();
      shelfMgrMsg('✅ Đã thêm kệ "' + d.name + '"');
    } else shelfMgrMsg('❌ ' + (d.error || 'Lỗi'), true);
  } catch (e) { shelfMgrMsg('❌ Lỗi kết nối', true); }
}

async function saveShelf(id, btn) {
  const row = btn.closest('[data-shelf]');
  const inp = row.querySelector('input');
  const name = inp.value.trim();
  if (name.length < 1) { shelfMgrMsg('Tên kệ không được trống!', true); return; }
  if (name === inp.dataset.orig) { shelfMgrMsg('Chưa có thay đổi.', true); return; }
  const fd = new URLSearchParams({ action: 'update-shelf-ajax', shelfId: id, shelfName: name });
  try {
    const r = await fetch('${pageContext.request.contextPath}/medicines', { method: 'POST', body: fd,
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' } });
    const d = await r.json();
    if (d.ok) {
      const s = SHELF_DATA.find(x => x.id === id);
      if (s) s.name = name;
      inp.dataset.orig = name;
      syncShelfSelects();
      shelfMgrMsg('✅ Đã đổi tên kệ');
    } else shelfMgrMsg('❌ ' + (d.error || 'Lỗi'), true);
  } catch (e) { shelfMgrMsg('❌ Lỗi kết nối', true); }
}

async function deleteShelf(id) {
  const s = SHELF_DATA.find(x => x.id === id);
  if (!confirm('Xóa kệ "' + (s ? s.name : id) + '"?\nKệ đang có thuốc sẽ không xóa được.')) return;
  const fd = new URLSearchParams({ action: 'delete-shelf-ajax', shelfId: id });
  try {
    const r = await fetch('${pageContext.request.contextPath}/medicines', { method: 'POST', body: fd,
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' } });
    const d = await r.json();
    if (d.ok) {
      const i = SHELF_DATA.findIndex(x => x.id === id);
      if (i >= 0) SHELF_DATA.splice(i, 1);
      renderShelfList(); syncShelfSelects();
      shelfMgrMsg('🗑️ Đã xóa kệ');
    } else shelfMgrMsg('❌ ' + (d.error || 'Lỗi'), true);
  } catch (e) { shelfMgrMsg('❌ Lỗi kết nối', true); }
}
</script>

<%-- Modal quản lý kệ --%>
<div id="shelfMgrModal" style="display:none;position:fixed;inset:0;z-index:9700;background:rgba(11,22,40,.5);backdrop-filter:blur(3px);align-items:center;justify-content:center;padding:20px" onclick="if(event.target===this)closeShelfMgr()">
  <div style="background:#fff;border-radius:18px;max-width:440px;width:100%;max-height:85vh;display:flex;flex-direction:column;box-shadow:0 24px 70px rgba(0,0,0,.35);overflow:hidden">
    <div style="padding:16px 22px;background:linear-gradient(135deg,#0F2645,#1558A8);color:#fff;display:flex;align-items:center;justify-content:space-between">
      <h3 style="margin:0;font-size:16px;font-weight:800">🗂️ Quản lý vị trí kệ</h3>
      <button onclick="closeShelfMgr()" style="background:rgba(255,255,255,.15);border:none;color:#fff;width:30px;height:30px;border-radius:8px;font-size:14px;cursor:pointer">✕</button>
    </div>
    <div id="shelfMgrList" style="flex:1;overflow-y:auto;padding:12px 20px"></div>
    <div style="padding:14px 20px;border-top:1.5px solid #f1f5f9">
      <div id="shelfMgrMsg" style="display:none;font-size:12px;font-weight:700;margin-bottom:8px"></div>
      <div style="display:flex;gap:8px">
        <input type="text" id="shelfNewName" placeholder="Tên kệ mới (VD: Kệ A3 — tầng 2)"
               onkeydown="if(event.key==='Enter'){event.preventDefault();addShelf();}"
               style="flex:1;border:1.5px solid #e2e8f0;border-radius:10px;padding:10px 12px;font-size:13.5px;font-family:inherit">
        <button type="button" onclick="addShelf()" style="background:linear-gradient(135deg,#1558A8,#3ABDE0);border:none;color:#fff;border-radius:10px;padding:10px 18px;font-size:13px;font-weight:800;cursor:pointer;font-family:inherit">＋ Thêm kệ</button>
      </div>
    </div>
  </div>
</div>
</body>
</html>
