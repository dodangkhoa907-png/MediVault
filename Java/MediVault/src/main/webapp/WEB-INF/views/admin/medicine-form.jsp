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

    String vName    = m != null && m.getMedicineName()     != null ? m.getMedicineName()     : "";
    String vGeneric = m != null && m.getGenericName()      != null ? m.getGenericName()      : "";
    String vBarcode = m != null && m.getBarcode()          != null ? m.getBarcode()          : "";
    String vRegNo   = m != null && m.getRegistrationNumber()!= null? m.getRegistrationNumber(): "";
    String vUnit    = m != null && m.getUnit()             != null ? m.getUnit()             : "";
    String vDosage  = m != null && m.getDosage()           != null ? m.getDosage()           : "";
    String vContra  = m != null && m.getContraindications()!= null ? m.getContraindications(): "";
    String vStorage = m != null && m.getStorageConditions()!= null ? m.getStorageConditions(): "";
    String vPrice   = m != null && m.getSellingPrice()     != null ? m.getSellingPrice().toPlainString() : "";
    int    vCatId   = m != null && m.getCategoryId()       != null ? m.getCategoryId()       : 0;
    int    vMfrId   = m != null && m.getManufacturerId()   != null ? m.getManufacturerId()   : 0;
    int    vShelfId = m != null && m.getShelfId()          != null ? m.getShelfId()          : 0;
    int    vMinInv  = m != null ? m.getMinInventory()  : 0;
    int    vExpDays = m != null ? m.getExpiryAlertDays(): 30;
    boolean vRx     = m != null && m.isPrescriptionRequired();

    @SuppressWarnings("unchecked")
    java.util.List<String> errs = (java.util.List<String>) request.getAttribute("errors");
    boolean hasErrors = errs != null && !errs.isEmpty();

    @SuppressWarnings("unchecked")
    java.util.List<com.medicare.entity.Category>     cats  = (java.util.List<com.medicare.entity.Category>)     request.getAttribute("categories");
    @SuppressWarnings("unchecked")
    java.util.List<com.medicare.entity.Manufacturer> mfrs  = (java.util.List<com.medicare.entity.Manufacturer>) request.getAttribute("manufacturers");
    @SuppressWarnings("unchecked")
    java.util.List<com.medicare.entity.Shelf>        shelves = (java.util.List<com.medicare.entity.Shelf>)      request.getAttribute("shelves");
%>
<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title><%= isNew ? "Thêm thuốc mới" : "Sửa thuốc" %> — MediCare</title>
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
.main{margin-left:var(--sidebar);flex:1;display:flex;flex-direction:column;min-height:100vh}
.topbar{height:62px;background:var(--white);border-bottom:1px solid var(--border);display:flex;align-items:center;padding:0 28px;gap:14px;position:sticky;top:0;z-index:50}
.topbar-title{font-family:'Outfit',sans-serif;font-size:16px;color:var(--ink)}
.btn-back{height:36px;padding:0 14px;background:var(--white);border:1.5px solid var(--border);border-radius:9px;font-size:13px;font-weight:600;color:var(--muted);text-decoration:none;display:inline-flex;align-items:center;gap:6px;margin-left:auto;transition:all .15s}
.btn-back:hover{border-color:var(--blue);color:var(--navy)}
.content{padding:28px;flex:1;max-width:860px}
.page-title{font-size:24px;font-weight:800;color:var(--ink);margin-bottom:4px}
.page-sub{font-size:13px;color:var(--muted);margin-bottom:24px}
.err-block{background:#FEF2F2;border:1.5px solid #FECACA;border-left:3px solid var(--red);border-radius:12px;padding:14px 18px;margin-bottom:18px}
.err-title{font-size:13px;font-weight:700;color:#991B1B;margin-bottom:7px}
.err-block li{font-size:12.5px;color:var(--red);margin-left:16px;padding:2px 0}
.form-card{background:var(--white);border:1px solid var(--border);border-radius:16px;overflow:hidden;box-shadow:0 2px 8px rgba(21,88,168,.04);margin-bottom:16px}
.form-card-head{padding:16px 22px;background:linear-gradient(90deg,#F5F8FD,var(--surface));border-bottom:1px solid var(--border);display:flex;align-items:center;gap:12px}
.form-card-head-icon{width:34px;height:34px;border-radius:9px;background:linear-gradient(135deg,var(--cyan),var(--blue));display:flex;align-items:center;justify-content:center;font-size:15px;flex-shrink:0}
.form-card-head h2{font-size:15px;font-weight:700;color:var(--ink)}
.form-card-head p{font-size:12px;color:var(--muted)}
.form-body{padding:22px;display:grid;grid-template-columns:1fr 1fr;gap:16px}
.span-2{grid-column:1/-1}
.field{display:flex;flex-direction:column;gap:6px}
.field-label{font-size:12.5px;font-weight:700;color:var(--navy)}
.req{color:var(--red)}
.field-input{height:42px;padding:0 14px;background:#fff;border:1.5px solid var(--border);border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;color:var(--ink);outline:none;transition:border-color .18s}
.field-input:focus{border-color:var(--cyan);box-shadow:0 0 0 3px rgba(58,189,224,.12)}
.field-input::placeholder{color:#B8CCE0}
select.field-input{appearance:none;cursor:pointer;background:#fff url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='10' height='6' fill='none'%3E%3Cpath stroke='%237A90B0' stroke-width='1.5' stroke-linecap='round' d='M1 1l4 4 4-4'/%3E%3C/svg%3E") no-repeat right 13px center;padding-right:32px}
textarea.field-input{height:80px;padding:10px 14px;resize:vertical}
.field-hint{font-size:11.5px;color:var(--muted)}
.checkbox-row{display:flex;align-items:center;gap:10px;padding:12px 16px;background:rgba(245,158,11,.06);border:1.5px solid rgba(245,158,11,.25);border-radius:11px;cursor:pointer}
.checkbox-row input[type=checkbox]{width:18px;height:18px;cursor:pointer;accent-color:var(--gold)}
.checkbox-row label{font-size:13.5px;font-weight:600;color:#92400E;cursor:pointer}
.price-wrap{position:relative}
.price-wrap .field-input{padding-right:50px}
.price-suffix{position:absolute;right:12px;top:50%;transform:translateY(-50%);font-size:12px;font-weight:700;color:var(--muted)}
.action-row{display:flex;align-items:center;gap:12px;padding:16px 22px;background:linear-gradient(90deg,#FAFBFD,var(--surface));border-top:1px solid var(--border)}
.btn-submit{height:40px;padding:0 24px;background:linear-gradient(135deg,var(--blue),#0D3F85);color:#fff;border:none;border-radius:11px;font-family:'Outfit',sans-serif;font-size:14px;font-weight:700;cursor:pointer;box-shadow:0 4px 14px rgba(21,88,168,.28);transition:all .2s}
.btn-submit:hover{transform:translateY(-1px)}
.btn-cancel{height:40px;padding:0 18px;background:var(--white);border:1.5px solid var(--border);border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;color:var(--muted);text-decoration:none;display:inline-flex;align-items:center;transition:all .18s}
.btn-cancel:hover{border-color:var(--blue);color:var(--navy)}
.add-cat-link{font-size:11.5px;color:var(--blue);text-decoration:none;font-weight:600}
.add-cat-link:hover{text-decoration:underline}
</style>
</head>
<body>

<%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

<div class="main">
  <div class="topbar">
    <span class="topbar-title"><%= isNew ? "➕ Thêm thuốc mới" : "✏️ Sửa thuốc" %></span>
    <a href="${pageContext.request.contextPath}/medicines" class="btn-back">← Kho thuốc</a>
  </div>

  <div class="content">
    <div class="page-title"><%= isNew ? "Thêm thuốc mới" : "Sửa thông tin thuốc" %></div>
    <div class="page-sub">Điền đầy đủ thông tin bên dưới — các trường có <span style="color:var(--red)">*</span> là bắt buộc.</div>

    <% if (hasErrors) { %>
    <div class="err-block">
      <div class="err-title">⚠️ Vui lòng kiểm tra lại:</div>
      <ul>
        <% for (String e : errs) { %><li><%= e %></li><% } %>
      </ul>
    </div>
    <% } %>

    <form method="post" action="${pageContext.request.contextPath}/medicines">
      <input type="hidden" name="action" value="save-medicine">
      <% if (!isNew) { %><input type="hidden" name="medicineId" value="<%= m.getMedicineId() %>"><% } %>

      <!-- ── Thông tin cơ bản ── -->
      <div class="form-card">
        <div class="form-card-head">
          <div class="form-card-head-icon">💊</div>
          <div>
            <h2>Thông tin cơ bản</h2>
            <p>Tên thuốc, phân loại và đơn vị tính</p>
          </div>
        </div>
        <div class="form-body">
          <div class="field span-2">
            <label class="field-label">Tên thuốc <span class="req">*</span></label>
            <input type="text" name="medicineName" class="field-input" value="<%= vName %>"
                   placeholder="VD: Paracetamol 500mg" required>
          </div>
          <div class="field">
            <label class="field-label">Tên hoạt chất (generic)</label>
            <input type="text" name="genericName" class="field-input" value="<%= vGeneric %>"
                   placeholder="VD: Acetaminophen">
          </div>
          <div class="field">
            <label class="field-label">Đơn vị tính <span class="req">*</span></label>
            <input type="text" name="unit" class="field-input" value="<%= vUnit %>"
                   placeholder="VD: Viên, Gói, Chai, Hộp" required>
          </div>
          <div class="field">
            <label class="field-label" style="justify-content:space-between;align-items:center">
              Danh mục <span class="req">*</span>
              <button type="button" onclick="openCatModal()"
                      style="height:28px;padding:0 10px;background:rgba(58,189,224,.1);border:1.5px solid rgba(58,189,224,.35);border-radius:8px;font-size:11.5px;font-weight:700;color:#1558A8;cursor:pointer;flex-shrink:0">
                ➕ Thêm danh mục
              </button>
            </label>
            <select name="categoryId" id="categoryId" class="field-input" required>
              <option value="">-- Chọn danh mục --</option>
              <% if (cats != null) for (com.medicare.entity.Category c : cats) { %>
              <option value="<%= c.getCategoryId() %>" <%= c.getCategoryId() == vCatId ? "selected" : "" %>><%= c.getCategoryName() %></option>
              <% } %>
            </select>
          </div>
          <div class="field">
            <label class="field-label" style="justify-content:space-between;align-items:center">
              Nhà sản xuất <span class="req">*</span>
              <button type="button" onclick="openMfrModal()"
                      style="height:28px;padding:0 10px;background:rgba(58,189,224,.1);border:1.5px solid rgba(58,189,224,.35);border-radius:8px;font-size:11.5px;font-weight:700;color:#1558A8;cursor:pointer;flex-shrink:0">
                ➕ Thêm NSX
              </button>
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
            <input type="text" name="barcode" class="field-input" value="<%= vBarcode %>"
                   placeholder="Quét hoặc nhập mã vạch">
          </div>
          <div class="field">
            <label class="field-label">Số đăng ký lưu hành</label>
            <input type="text" name="registrationNumber" class="field-input" value="<%= vRegNo %>"
                   placeholder="VD: VD-12345-16">
          </div>
        </div>
      </div>

      <!-- ── Giá & Tồn kho ── -->
      <div class="form-card">
        <div class="form-card-head">
          <div class="form-card-head-icon">💰</div>
          <div>
            <h2>Giá bán &amp; Tồn kho</h2>
            <p>Giá bán lẻ và ngưỡng cảnh báo tồn kho thấp</p>
          </div>
        </div>
        <div class="form-body">
          <div class="field">
            <label class="field-label">Giá bán (VNĐ) <span class="req">*</span></label>
            <div class="price-wrap">
              <input type="number" name="sellingPrice" class="field-input" value="<%= vPrice %>"
                     placeholder="0" min="0" step="500" required>
              <span class="price-suffix">₫</span>
            </div>
          </div>
          <div class="field">
            <label class="field-label">Tồn kho tối thiểu</label>
            <input type="number" name="minInventory" class="field-input" value="<%= vMinInv %>"
                   placeholder="0" min="0">
            <span class="field-hint">Cảnh báo khi tồn kho xuống dưới mức này</span>
          </div>
          <div class="field">
            <label class="field-label">Cảnh báo hết hạn (ngày)</label>
            <input type="number" name="expiryAlertDays" class="field-input" value="<%= vExpDays %>"
                   placeholder="30" min="1">
            <span class="field-hint">Cảnh báo trước khi thuốc hết hạn bao nhiêu ngày</span>
          </div>
          <div class="field">
            <label class="field-label">Vị trí kệ</label>
            <select name="shelfId" class="field-input">
              <option value="">-- Chọn kệ --</option>
              <% if (shelves != null) for (com.medicare.entity.Shelf sh : shelves) { %>
              <option value="<%= sh.getShelfId() %>" <%= sh.getShelfId() == vShelfId ? "selected" : "" %>><%= sh.getShelfName() != null ? sh.getShelfName() : "Kệ " + sh.getShelfId() %></option>
              <% } %>
            </select>
          </div>
        </div>
      </div>

      <!-- ── Thông tin y tế ── -->
      <div class="form-card">
        <div class="form-card-head">
          <div class="form-card-head-icon">🩺</div>
          <div>
            <h2>Thông tin y tế</h2>
            <p>Liều dùng, chống chỉ định và điều kiện bảo quản</p>
          </div>
        </div>
        <div class="form-body">
          <div class="field span-2">
            <div class="checkbox-row">
              <input type="checkbox" id="rxCheck" name="isPrescriptionRequired" value="on" <%= vRx ? "checked" : "" %>>
              <label for="rxCheck">⚕️ Thuốc kê đơn (cần đơn thuốc của bác sĩ để bán)</label>
            </div>
          </div>
          <div class="field span-2">
            <label class="field-label">Liều dùng / Hướng dẫn sử dụng</label>
            <textarea name="dosage" class="field-input" placeholder="VD: Người lớn: 1-2 viên/lần, 3-4 lần/ngày..."><%= vDosage %></textarea>
          </div>
          <div class="field span-2">
            <label class="field-label">Chống chỉ định</label>
            <textarea name="contraindications" class="field-input" placeholder="Các trường hợp không nên dùng..."><%= vContra %></textarea>
          </div>
          <div class="field span-2">
            <label class="field-label">Điều kiện bảo quản</label>
            <textarea name="storageConditions" class="field-input" placeholder="VD: Bảo quản nơi khô ráo, thoáng mát, tránh ánh nắng..."><%= vStorage %></textarea>
          </div>
        </div>
      </div>

      <div class="action-row" style="background:var(--white);border:1px solid var(--border);border-radius:16px;margin-top:4px">
        <button type="submit" class="btn-submit"><%= isNew ? "➕ Thêm thuốc" : "💾 Lưu thay đổi" %></button>
        <a href="${pageContext.request.contextPath}/medicines" class="btn-cancel">Hủy</a>
      </div>
    </form>
  </div>
</div>

<!-- ══ Modal tạo danh mục inline ══ -->
<div id="catModal" style="display:none;position:fixed;inset:0;background:rgba(11,22,40,.55);z-index:1000;align-items:center;justify-content:center;backdrop-filter:blur(2px)">
  <div style="background:#fff;border-radius:18px;width:400px;max-width:92vw;overflow:hidden;box-shadow:0 20px 60px rgba(0,0,0,.3)">
    <div style="padding:18px 22px;background:linear-gradient(90deg,#0F2645,#1558A8);color:#fff;display:flex;align-items:center;justify-content:space-between">
      <h3 style="font-size:15px;font-weight:700;margin:0">📂 Thêm danh mục thuốc</h3>
      <button onclick="closeCatModal()" style="background:rgba(255,255,255,.15);border:none;color:#fff;width:28px;height:28px;border-radius:8px;cursor:pointer;font-size:14px">✕</button>
    </div>
    <div style="padding:22px">
      <div style="margin-bottom:14px">
        <label style="font-size:12.5px;font-weight:700;color:#0F2645;display:block;margin-bottom:6px">Tên danh mục <span style="color:#DC2626">*</span></label>
        <input id="catNameInput" type="text" placeholder="VD: Kháng sinh, Giảm đau, Vitamin..."
               style="width:100%;height:42px;padding:0 14px;border:1.5px solid #D5E0F0;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;outline:none;box-sizing:border-box"
               onkeydown="if(event.key==='Enter'){event.preventDefault();saveCat()}">
      </div>
      <div style="margin-bottom:18px">
        <label style="font-size:12.5px;font-weight:700;color:#0F2645;display:block;margin-bottom:6px">Mô tả (không bắt buộc)</label>
        <input id="catDescInput" type="text" placeholder="Mô tả ngắn về danh mục"
               style="width:100%;height:42px;padding:0 14px;border:1.5px solid #D5E0F0;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;outline:none;box-sizing:border-box">
      </div>
      <div id="catErr" style="font-size:12px;color:#DC2626;margin-bottom:10px;display:none"></div>
      <div style="display:flex;gap:10px">
        <button onclick="saveCat()" style="flex:1;height:40px;background:linear-gradient(135deg,#1558A8,#0D3F85);color:#fff;border:none;border-radius:11px;font-family:'Outfit',sans-serif;font-size:14px;font-weight:700;cursor:pointer">
          ➕ Tạo danh mục
        </button>
        <button onclick="closeCatModal()" style="height:40px;padding:0 18px;background:#fff;border:1.5px solid #D5E0F0;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;color:#7A90B0;cursor:pointer">
          Hủy
        </button>
      </div>
    </div>
  </div>
</div>

<!-- ══ Modal tạo nhà sản xuất inline ══ -->
<div id="mfrModal" style="display:none;position:fixed;inset:0;background:rgba(11,22,40,.55);z-index:1000;align-items:center;justify-content:center;backdrop-filter:blur(2px)">
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
        <button onclick="saveMfr()" style="flex:1;height:40px;background:linear-gradient(135deg,#1558A8,#0D3F85);color:#fff;border:none;border-radius:11px;font-family:'Outfit',sans-serif;font-size:14px;font-weight:700;cursor:pointer">
          ➕ Tạo nhà sản xuất
        </button>
        <button onclick="closeMfrModal()" style="height:40px;padding:0 18px;background:#fff;border:1.5px solid #D5E0F0;border-radius:11px;font-family:'Outfit',sans-serif;font-size:13.5px;font-weight:600;color:#7A90B0;cursor:pointer">
          Hủy
        </button>
      </div>
    </div>
  </div>
</div>

<script>
const CTX = '${pageContext.request.contextPath}';

function openCatModal() {
  document.getElementById('catNameInput').value = '';
  document.getElementById('catDescInput').value = '';
  document.getElementById('catErr').style.display = 'none';
  const m = document.getElementById('catModal');
  m.style.display = 'flex';
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
        const opt = new Option(data.name, data.id, true, true);
        sel.appendChild(opt);
        closeCatModal();
        sel.style.borderColor = '#059669';
        sel.style.boxShadow = '0 0 0 3px rgba(5,150,105,.15)';
        setTimeout(() => { sel.style.borderColor=''; sel.style.boxShadow=''; }, 1500);
      } else {
        err.textContent = data.error || '❌ Lỗi không xác định!';
        err.style.display = 'block';
      }
    })
    .catch(() => { err.textContent = '❌ Lỗi kết nối!'; err.style.display='block'; });
}

function openMfrModal() {
  ['mfrNameInput','mfrCountryInput','mfrContactInput'].forEach(id => document.getElementById(id).value = '');
  document.getElementById('mfrErr').style.display = 'none';
  const m = document.getElementById('mfrModal');
  m.style.display = 'flex';
  setTimeout(() => document.getElementById('mfrNameInput').focus(), 100);
}
function closeMfrModal() { document.getElementById('mfrModal').style.display = 'none'; }
document.getElementById('mfrModal').addEventListener('click', function(e){ if(e.target===this) closeMfrModal(); });

function saveMfr() {
  const name    = document.getElementById('mfrNameInput').value.trim();
  const country = document.getElementById('mfrCountryInput').value.trim();
  const contact = document.getElementById('mfrContactInput').value.trim();
  const err = document.getElementById('mfrErr');
  if (!name) { err.textContent = '⚠️ Vui lòng nhập tên nhà sản xuất!'; err.style.display='block'; return; }
  const fd = new FormData();
  fd.append('action', 'create-manufacturer-ajax');
  fd.append('name', name);
  fd.append('country', country);
  fd.append('contactInfo', contact);
  fetch(CTX + '/medicines', { method:'POST', body: fd })
    .then(r => r.json())
    .then(data => {
      if (data.ok) {
        const sel = document.getElementById('manufacturerId');
        const opt = new Option(data.name, data.id, true, true);
        sel.appendChild(opt);
        closeMfrModal();
        sel.style.borderColor = '#059669';
        sel.style.boxShadow = '0 0 0 3px rgba(5,150,105,.15)';
        setTimeout(() => { sel.style.borderColor=''; sel.style.boxShadow=''; }, 1500);
      } else {
        err.textContent = data.error || '❌ Lỗi không xác định!';
        err.style.display = 'block';
      }
    })
    .catch(() => { err.textContent = '❌ Lỗi kết nối!'; err.style.display='block'; });
}
</script>
</body>
</html>
