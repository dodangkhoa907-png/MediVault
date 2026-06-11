<%-- ══════════════════════════════════════════════════════════════
     _sidebar.jsp  —  Admin sidebar dùng chung cho mọi trang
     Include bằng: <%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

     Biến cần có trước khi include (khai báo ở trang cha):
       String fullName  — tên hiển thị
       String initials  — 2 chữ cái viết tắt
       String activeNav — "dashboard"|"hr"|"accounts"|"shifts"|
                          "medicines"|"invoices"|"customers"|
                          "returns"|"audit"|"reports"
══════════════════════════════════════════════════════════════ --%>
<%@ page contentType="text/html;charset=UTF-8" %>
<%@ taglib prefix="c" uri="jakarta.tags.core" %>
<%@ taglib prefix="fmt" uri="jakarta.tags.fmt" %>
<%@ taglib prefix="fn" uri="jakarta.tags.functions" %>


<%
    // Fallback an toàn nếu trang cha chưa khai báo
    if (fullName  == null) fullName  = "Admin";
    if (initials  == null) initials  = "AD";
    if (activeNav == null) activeNav = "";

    // Badge counts — đọc từ request attribute (set bởi Servlet)
    Integer _plc = (Integer) request.getAttribute("pendingLeaveCount");
    int pendingLeave = (_plc != null) ? _plc : 0;
    Integer _exc = (Integer) request.getAttribute("expiryCount");
    int expiry = (_exc != null) ? _exc : 0;
%>
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
    <a href="${pageContext.request.contextPath}/dashboard"
       class="nav-item <%= "dashboard".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">🏠</span> Trang chủ
    </a>
  </nav>

  <nav class="nav-section">
    <div class="nav-label">Nhân sự</div>
    <a href="${pageContext.request.contextPath}/shifts"
       class="nav-item <%= "shifts".equals(activeNav) || "hr".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">📅</span> Ca &amp; Lịch làm việc
      <% if (pendingLeave > 0) { %>
      <span class="nav-badge" style="background:#DC2626"><%= pendingLeave %></span>
      <% } %>
    </a>
    <a href="${pageContext.request.contextPath}/attendance"
       class="nav-item <%= "attendance".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">✅</span> Điểm danh
    </a>
    <a href="${pageContext.request.contextPath}/payroll"
       class="nav-item <%= "payroll".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">💰</span> Bảng lương
    </a>
  </nav>

  <nav class="nav-section">
    <div class="nav-label">Quản lý</div>
    <a href="${pageContext.request.contextPath}/accounts"
       class="nav-item <%= "accounts".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">👤</span> Tài khoản
    </a>
    <a href="${pageContext.request.contextPath}/medicines"
       class="nav-item <%= "medicines".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">💊</span> Kho thuốc
      <% if (expiry > 0) { %>
      <span class="nav-badge"><%= expiry %></span>
      <% } %>
    </a>
    <a href="${pageContext.request.contextPath}/invoices"
       class="nav-item <%= "invoices".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">🧾</span> Hóa đơn
    </a>
    <a href="${pageContext.request.contextPath}/customers"
       class="nav-item <%= "customers".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">👥</span> Khách hàng
    </a>
    <a href="${pageContext.request.contextPath}/returns"
       class="nav-item <%= "returns".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">↩️</span> Trả hàng
    </a>
  </nav>

  <nav class="nav-section">
    <div class="nav-label">Phân tích</div>
    <a href="${pageContext.request.contextPath}/audit-logs"
       class="nav-item <%= "audit".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">📋</span> Nhật ký
    </a>
    <a href="${pageContext.request.contextPath}/reports"
       class="nav-item <%= "reports".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">📊</span> Báo cáo
    </a>
  </nav>

  <div class="sidebar-footer">
    <div class="user-avatar-sm">
      <div>
        <div class="user-info-sm"><%= fullName %></div>
        <div class="user-info-sm">Admin</div>
      </div>
      <a href="${pageContext.request.contextPath}/logout" class="logout-btn" title="Đăng xuất" >⏻

      </a>
    </div>
  </div>
</aside>
