<%-- ══════════════════════════════════════════════════════════════
     sidebar.jsp  —  Admin sidebar dùng chung cho mọi trang
     Include bằng: <%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

     Biến cần có trước khi include (khai báo ở trang cha):
       String fullName  — tên hiển thị
       String initials  — 2 chữ cái viết tắt
       String activeNav — "dashboard"|"reports"|"audit"|"medicines"|
                          "purchase-orders"|"invoices"|"returns"|
                          "accounts"|"customers"|"shifts"|"hr"|
                          "attendance"|"payroll"

     Thứ tự ưu tiên (theo yêu cầu 2026-06-17):
       Tổng quan (Trang chủ) → Phân tích (Báo cáo, Nhật ký) →
       Quản lý (Kho hàng [Thuốc&Lô hàng + Đơn đặt hàng — 2 tab],
                Hóa đơn [Hóa đơn + Trả hàng — 2 tab],
                Nhân viên & Khách hàng [Tài khoản + Khách hàng — 2 tab]) →
       Nhân sự (Ca & Lịch làm việc, Điểm danh, Bảng lương)

     LƯU Ý GỘP MENU (2026-06-18): "Đơn đặt hàng", "Trả hàng", "Khách hàng"
     không còn là mục riêng trên sidebar — vào qua tab-bar ngay trong trang
     Kho thuốc / Hóa đơn / Tài khoản (xem .section-tabs trong medicine-list.jsp,
     purchase-order-list.jsp, invoice-list.jsp, account-list.jsp). activeNav vẫn
     nhận "purchase-orders"/"returns"/"customers" để tô sáng đúng mục cha.
     Tab "Khách hàng" và "Trả hàng" hiện disabled ("Sắp ra mắt") vì chưa có
     CustomerServlet/ReturnsServlet — chỉ là chỗ chờ sẵn.
══════════════════════════════════════════════════════════════ --%>
<%@ page contentType="text/html;charset=UTF-8" pageEncoding="UTF-8" %>
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
    <div style="width:36px;height:36px;border-radius:9px;overflow:hidden;flex-shrink:0;background:#fff"><img src="${pageContext.request.contextPath}/images/NEW_LOGO.png" alt="MediCare" style="width:100%;height:100%;object-fit:cover;object-position:center 15%;display:block"></div>
    <div>
      <div class="logo-text">Medi<span>Care</span></div>
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
    <div class="nav-label">Phân tích</div>
    <a href="${pageContext.request.contextPath}/reports"
       class="nav-item <%= "reports".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">📊</span> Báo cáo
    </a>
    <a href="${pageContext.request.contextPath}/audit-logs"
       class="nav-item <%= "audit".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">📋</span> Nhật ký
    </a>
  </nav>

  <nav class="nav-section">
    <div class="nav-label">Quản lý</div>
    <a href="${pageContext.request.contextPath}/medicines"
       class="nav-item <%= ("medicines".equals(activeNav) || "purchase-orders".equals(activeNav)) ? "active" : "" %>">
      <span class="nav-icon">💊</span> Kho hàng
      <% if (expiry > 0) { %>
      <span class="nav-badge"><%= expiry %></span>
      <% } %>
    </a>
    <a href="${pageContext.request.contextPath}/invoices"
       class="nav-item <%= ("invoices".equals(activeNav) || "returns".equals(activeNav)) ? "active" : "" %>">
      <span class="nav-icon">🧾</span> Hóa đơn
    </a>
    <a href="${pageContext.request.contextPath}/accounts"
       class="nav-item <%= ("accounts".equals(activeNav) || "customers".equals(activeNav)) ? "active" : "" %>">
      <span class="nav-icon">👤</span> Nhân viên &amp; Khách hàng
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

  <div class="sidebar-footer">
    <a href="${pageContext.request.contextPath}/logout" class="logout-btn-full">
      <span style="font-size:15px;line-height:1">⏻</span>
      <span>Đăng xuất</span>
    </a>
  </div>
</aside>
<style>
.sidebar-footer{margin-top:13px;padding:20px 14px 16px;border-top:1px solid rgba(255,255,255,.07);flex-shrink:0}
.logout-btn-full{display:flex;align-items:center;justify-content:center;gap:8px;width:100%;padding:10px 14px;border-radius:10px;background:rgba(220,38,38,.35);border:1.5px solid rgba(220,38,38,.3);color:#FF6B6B;text-decoration:none;font-family:'Outfit',sans-serif;font-size:13px;font-weight:700;letter-spacing:.3px;transition:all .2s}
.logout-btn-full:hover{background:rgba(220,38,38,.58);color:#fff;border-color:#DC2626}
</style>
