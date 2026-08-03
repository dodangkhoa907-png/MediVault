<%@ page pageEncoding="UTF-8" %>
<%--
  warehouse-sidebar.jsp — Sidebar dùng chung cho MỌI trang portal Quản lý kho.
  Static include: <%@ include file="warehouse-sidebar.jsp" %>

  Trang gọi PHẢI định nghĩa trước 2 biến page-scope:
    String uid       — id nhân sự (đưa vào mọi link ?uid=)
    String activeNav — 1 trong: dashboard|inventory|movement|reorder|recall|import|orders|export|shelves|task|profile
    ("orders" và "export" tô sáng chung với "import" — /warehouse-orders và /warehouse-export
    chỉ vào được qua tb-nav của Nhập kho, không có mục sidebar riêng.)

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
       class="nav-item <%= ("import".equals(_whActive) || "orders".equals(_whActive)) ? "active" : "" %>">
      <span class="nav-icon">📥</span> Nhập kho
    </a>
    <a href="<%= _whCtx %>/warehouse-export"
       class="nav-item <%= "export".equals(_whActive) ? "active" : "" %>">
      <span class="nav-icon">📤</span> Xuất kho
    </a>
    <%-- Trang riêng /warehouse-shelf (2026-08-05) — trước đây mở modal ngay ở đây, nhưng
         modal quá chật cho danh sách có thể dài và không có chỗ cho tìm kiếm/lọc về sau.
         Chỉ đọc: đổi vị trí kệ vật lý vẫn phải qua Admin (/shelves). --%>
    <a href="<%= _whCtx %>/warehouse-shelf"
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
