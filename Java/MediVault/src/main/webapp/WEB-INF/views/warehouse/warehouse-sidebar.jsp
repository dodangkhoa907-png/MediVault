<%@ page pageEncoding="UTF-8" %>
<%--
  warehouse-sidebar.jsp — Sidebar dùng chung cho MỌI trang portal Quản lý kho.
  Static include: <%@ include file="warehouse-sidebar.jsp" %>

  Trang gọi PHẢI định nghĩa trước 2 biến page-scope:
    String uid       — id nhân sự (đưa vào mọi link ?uid=)
    String activeNav — 1 trong: dashboard|inventory|movement|reorder|recall|task|pos|checkin

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
    <a href="<%= _whCtx %>/warehouse-dashboard?uid=<%= _whUid %>"
       class="nav-item <%= "dashboard".equals(_whActive) ? "active" : "" %>">
      <span class="nav-icon">🏠</span> Trang chủ
    </a>
  </nav>

  <nav class="nav-block">
    <div class="nav-label">Kho hàng</div>
    <a href="<%= _whCtx %>/warehouse-inventory?uid=<%= _whUid %>"
       class="nav-item <%= "inventory".equals(_whActive) ? "active" : "" %>">
      <span class="nav-icon">📦</span> Quản lý tồn kho
    </a>
    <a href="<%= _whCtx %>/warehouse-stock-movement?uid=<%= _whUid %>"
       class="nav-item <%= "movement".equals(_whActive) ? "active" : "" %>">
      <span class="nav-icon">📤</span> Xuất kho &amp; Điều chỉnh
    </a>
    <a href="<%= _whCtx %>/warehouse-reorder?uid=<%= _whUid %>"
       class="nav-item <%= "reorder".equals(_whActive) ? "active" : "" %>">
      <span class="nav-icon">📈</span> Gợi ý đặt hàng
      <% if (_whExpiry != null && ((Integer) _whExpiry) > 0) { %><span class="nav-badge"><%= _whExpiry %></span><% } %>
    </a>
    <a href="<%= _whCtx %>/warehouse-recall?uid=<%= _whUid %>"
       class="nav-item <%= "recall".equals(_whActive) ? "active" : "" %>">
      <span class="nav-icon">🚨</span> Thu hồi khẩn cấp
    </a>
  </nav>

  <nav class="nav-block">
    <div class="nav-label">Công việc</div>
    <a href="<%= _whCtx %>/warehouse-task?uid=<%= _whUid %>"
       class="nav-item <%= "task".equals(_whActive) ? "active" : "" %>">
      <span class="nav-icon">📋</span> Nhiệm vụ &amp; SOP
      <% if (_whTasks != null && ((Integer) _whTasks) > 0) { %><span class="nav-badge"><%= _whTasks %></span><% } %>
    </a>
  </nav>

  <nav class="nav-block">
    <div class="nav-label">Bán hàng</div>
    <a href="<%= _whCtx %>/pos?uid=<%= _whUid %>"
       class="nav-item <%= "pos".equals(_whActive) ? "active" : "" %>">
      <span class="nav-icon">🛒</span> Bán thuốc (POS)
    </a>
  </nav>

  <nav class="nav-block">
    <div class="nav-label">Cá nhân</div>
    <a href="<%= _whCtx %>/staff-checkin?uid=<%= _whUid %>"
       class="nav-item <%= "checkin".equals(_whActive) ? "active" : "" %>">
      <span class="nav-icon">🕒</span> Điểm danh &amp; Ca làm việc
    </a>
  </nav>

  <div class="sidebar-footer">
    <a href="<%= _whCtx %>/logout?from=warehouse&uid=<%= _whUid %>" class="logout-btn-full">
      <span style="font-size:15px;line-height:1">⏻</span>
      <span>Đăng xuất</span>
    </a>
  </div>
</aside>
