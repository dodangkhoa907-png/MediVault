<%@ page pageEncoding="UTF-8" %>
<%--
  warehouse-sidebar.jsp — Sidebar dùng chung cho MỌI trang portal Quản lý kho.
  Static include: <%@ include file="warehouse-sidebar.jsp" %>

  Trang gọi PHẢI định nghĩa trước 2 biến page-scope:
    String uid       — id nhân sự (đưa vào mọi link ?uid=)
    String activeNav — 1 trong: dashboard|inventory|movement|reorder|recall|import|shelves|task|profile

  Sidebar CHỈ còn 4 mục chính (2026-08-01, rút gọn theo yêu cầu) — inventory/movement/
  reorder/recall gộp chung 1 mục "Quản lý tồn kho", chuyển qua lại bằng .section-tabs
  ngay trong từng trang (xem warehouse-inventory.jsp...) thay vì chiếm 4 dòng sidebar.
  "Nhập kho" (trước đây không có trong sidebar) được thêm lại, có tab riêng sang
  "Gợi ý đặt hàng". Bỏ "Bán thuốc (POS)" và "Điểm danh & Ca làm việc" khỏi sidebar này
  — Thủ kho vẫn vào được 2 chức năng đó qua route /pos (public) và qua sidebar Admin
  (nhánh isStorekeeper trong admin/sidebar.jsp) khi đăng nhập chung với tài khoản Staff.

  Badge "cận hạn" đọc từ request attribute "expiryCount" (nếu trang có set); trang
  không set thì không hiện badge — không lỗi. Badge "task" đọc từ "myOpenTaskCount"
  theo đúng cơ chế tương tự.
--%>
<%
  String _whCtx    = request.getContextPath();
  String _whUid    = (uid != null) ? uid : "";
  String _whActive = (activeNav != null) ? activeNav : "";
  Object _whExpiry = request.getAttribute("expiryCount");
  Object _whTasks  = request.getAttribute("myOpenTaskCount");
%>
<aside class="sidebar">
  <div class="sidebar-logo">
    <div class="logo-gem">📦</div>
    <div>
      <div class="logo-name">Medi<span>Care</span></div>
      <div class="logo-sub">Warehouse Console</div>
    </div>
  </div>

  <nav class="nav-block">
    <div class="nav-label">Tổng quan</div>
    <a href="<%= _whCtx %>/warehouse-dashboard"
       class="nav-item <%= "dashboard".equals(_whActive) ? "active" : "" %>">
      <span class="nav-icon">🏠</span> Trang chủ
    </a>
  </nav>

  <nav class="nav-block">
    <div class="nav-label">Kho hàng</div>
    <a href="<%= _whCtx %>/warehouse-inventory"
       class="nav-item <%= ("inventory".equals(_whActive) || "movement".equals(_whActive) || "reorder".equals(_whActive) || "recall".equals(_whActive)) ? "active" : "" %>">
      <span class="nav-icon">📦</span> Quản lý tồn kho
      <% if (_whExpiry != null && ((Integer) _whExpiry) > 0) { %><span class="nav-badge"><%= _whExpiry %></span><% } %>
    </a>
    <a href="<%= _whCtx %>/warehouse-import"
       class="nav-item <%= "import".equals(_whActive) ? "active" : "" %>">
      <span class="nav-icon">📥</span> Nhập kho
    </a>
    <%-- ShelfServlet đã cho phép roleId 3 từ trước (AuthFilter whitelist /shelves cho Thủ kho)
         nhưng chưa có lối vào nào trong Warehouse Console — chỉ thiếu link, không thiếu quyền.
         Dùng thẳng trang Admin có sẵn (shelf-list.jsp), không dựng trang wh-* riêng vì cùng 1
         danh sách kệ dùng chung cho cả Admin lẫn Thủ kho, tách ra 2 bản là 2 nguồn sự thật. --%>
    <a href="#" onclick="return whOpenShelfModal()"
       class="nav-item <%= "shelves".equals(_whActive) ? "active" : "" %>">
      <span class="nav-icon">🗄️</span> Quản lý kệ
    </a>
  </nav>

  <nav class="nav-block">
    <div class="nav-label">Công việc</div>
    <a href="<%= _whCtx %>/warehouse-task"
       class="nav-item <%= "task".equals(_whActive) ? "active" : "" %>">
      <span class="nav-icon">📋</span> Nhiệm vụ &amp; SOP
      <% if (_whTasks != null && ((Integer) _whTasks) > 0) { %><span class="nav-badge"><%= _whTasks %></span><% } %>
    </a>
  </nav>

  <nav class="nav-block">
    <div class="nav-label">Cá nhân</div>
    <a href="<%= _whCtx %>/warehouse-profile"
       class="nav-item <%= "profile".equals(_whActive) ? "active" : "" %>">
      <span class="nav-icon">👤</span> Hồ sơ cá nhân
    </a>
  </nav>

  <div class="sidebar-footer">
    <a href="<%= _whCtx %>/logout?from=warehouse" class="logout-btn-full">
      <span style="font-size:15px;line-height:1">⏻</span>
      <span>Đăng xuất</span>
    </a>
  </div>
</aside>

<!-- ══ Modal "Quản lý kệ" — sidebar include ở MỌI trang Kho nên modal đặt ở đây dùng được
     khắp nơi. Chỉ đọc: đổi vị trí kệ vật lý vẫn phải qua Admin (/shelves). ══ -->
<div class="wh-modal" id="whShelfModal" onclick="if(event.target===this)whCloseShelfModal()">
  <div class="wh-modal-box" role="dialog" aria-modal="true" aria-labelledby="whShelfModalTitle" style="max-width:560px">
    <div class="wh-modal-head">
      <div class="wh-ic"><svg><use href="#ic-package"/></svg></div>
      <h3 id="whShelfModalTitle">Danh sách kệ</h3>
      <button type="button" class="wh-btn wh-btn-icon wh-btn-ghost" onclick="whCloseShelfModal()" aria-label="Đóng">
        <svg><use href="#ic-x"/></svg>
      </button>
    </div>
    <div class="wh-modal-body" id="whShelfModalBody">
      <div style="text-align:center;color:var(--muted);padding:20px 0">Đang tải…</div>
    </div>
  </div>
</div>

<script>
var _whShelfLoaded = false;
function whOpenShelfModal() {
  var modal = document.getElementById('whShelfModal');
  var body  = document.getElementById('whShelfModalBody');
  modal.classList.add('open');
  if (_whShelfLoaded) return false;
  fetch('<%= _whCtx %>/warehouse-inventory?action=shelves')
    .then(function (r) { return r.json(); })
    .then(function (d) {
      if (!d.ok || !d.shelves.length) {
        body.innerHTML = '<div style="text-align:center;color:var(--muted);padding:20px 0">Chưa có kệ nào được tạo.</div>';
        return;
      }
      _whShelfLoaded = true;
      body.innerHTML = d.shelves.map(function (s) {
        return '<div style="display:flex;justify-content:space-between;align-items:center;gap:10px;background:var(--surface);border-radius:11px;padding:10px 12px;margin-bottom:7px">'
          + '<div><div style="font-weight:750;font-size:13px">' + s.name + '</div>'
          + '<div style="font-size:11px;color:var(--muted)">' + (s.location || s.type) + (s.automated ? ' · Tự động' : '') + '</div></div>'
          + '<span class="wh-badge low">' + s.medicineCount + ' thuốc</span></div>';
      }).join('');
    })
    .catch(function () { body.innerHTML = '<div style="color:var(--danger);text-align:center;padding:16px 0">Lỗi kết nối.</div>'; });
  return false;
}
function whCloseShelfModal() { document.getElementById('whShelfModal').classList.remove('open'); }
</script>
