<%-- ══════════════════════════════════════════════════════════════
     sidebar.jsp  —  Admin sidebar dùng chung cho mọi trang
     Include bằng: <%@ include file="/WEB-INF/views/admin/sidebar.jsp" %>

     Biến cần có trước khi include (khai báo ở trang cha):
       String fullName  — tên hiển thị
       String initials  — 2 chữ cái viết tắt
       String activeNav — "dashboard"|"reports"|"audit"|"medicines"|
                          "purchase-orders"|"invoices"|"returns"|
                          "accounts"|"customers"|"shifts"|"hr"|
                          "attendance"|"payroll"|"task-management"

     Thứ tự ưu tiên (theo yêu cầu 2026-06-17):
       Tổng quan (Trang chủ) → Phân tích (Báo cáo, Nhật ký) →
       Quản lý (Kho hàng [Thuốc&Lô hàng + Đơn đặt hàng — 2 tab],
                Hóa đơn [Hóa đơn + Trả hàng — 2 tab],
                Nhân viên & Khách hàng [Tài khoản + Khách hàng — 2 tab]) →
       Nhân sự (Ca & Lịch làm việc, Điểm danh, Bảng lương)

     LƯU Ý GỘP MENU (2026-06-18, cập nhật 2026-06-19): "Đơn đặt hàng", "Trả hàng",
     "Khách hàng" không còn là mục riêng trên sidebar — vào qua tab-bar ngay trong
     trang Kho thuốc / Hóa đơn / Tài khoản (xem .section-tabs trong medicine-list.jsp,
     purchase-order-list.jsp, invoice-list.jsp, account-list.jsp). activeNav vẫn
     nhận "purchase-orders"/"returns"/"customers" để tô sáng đúng mục cha.
     Cả 4 tab phụ (Đơn đặt hàng, Hóa đơn, Trả hàng, Khách hàng) đều đã có
     servlet thật, không còn tab "Sắp ra mắt" nào.
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
    Integer _twc = (Integer) request.getAttribute("taskWatchdogCount");
    int taskWatchdog = (_twc != null) ? _twc : 0;

    com.medicare.entity.Account currentUser = (com.medicare.entity.Account) session.getAttribute("adminAccount");
    if (currentUser == null) {
        java.util.Enumeration<String> sessionNames = session.getAttributeNames();
        while (sessionNames.hasMoreElements()) {
            String name = sessionNames.nextElement();
            if (name.startsWith("staffAccount_")) {
                Object val = session.getAttribute(name);
                if (val instanceof com.medicare.entity.Account) {
                    currentUser = (com.medicare.entity.Account) val;
                    break;
                }
            }
        }
    }
    boolean isStorekeeper = (currentUser != null && currentUser.getRoleId() == 3);
    String uidParam = isStorekeeper ? "?uid=" + currentUser.getAccountId() : "";
    String uidAmp = isStorekeeper ? "&uid=" + currentUser.getAccountId() : "";
%>
<aside class="sidebar">
  <div class="sidebar-logo">
    <div style="width:36px;height:36px;border-radius:9px;overflow:hidden;flex-shrink:0;background:#fff"><img src="${pageContext.request.contextPath}/images/NEW_LOGO.png" alt="MediCare" style="width:100%;height:100%;object-fit:cover;object-position:center 15%;display:block"></div>
    <div>
      <div class="logo-text">Medi<span>Care</span></div>
      <div class="logo-sub"><%= isStorekeeper ? "Storekeeper" : "Admin Console" %></div>
    </div>
  </div>

  <% if (isStorekeeper) { %>
  <nav class="nav-section">
    <div class="nav-label">Tổng quan</div>
    <a href="${pageContext.request.contextPath}/staff-dashboard<%= uidParam %>"
       class="nav-item <%= "dashboard".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">🏠</span> Trang chủ
    </a>
  </nav>

  <nav class="nav-section">
    <div class="nav-label">Kho hàng</div>
    <%-- Không gắn uidParam ở 3 link này: MedicineServlet/PurchaseOrderServlet/ReturnsServlet
         đều tự lấy account từ session.getAttribute("staffUid") rồi tra staffAccount_<uid> —
         KHÔNG đọc uid từ URL. uidParam ở đây vốn thừa và làm lộ AccountID trên thanh địa chỉ
         mỗi khi Thủ kho rẽ từ Warehouse Console sang các trang dùng chung với Admin. --%>
    <a href="${pageContext.request.contextPath}/medicines"
       class="nav-item <%= ("medicines".equals(activeNav) || "purchase-orders".equals(activeNav)) ? "active" : "" %>">
      <span class="nav-icon">💊</span> Quản lý kho
      <% if (expiry > 0) { %>
      <span class="nav-badge"><%= expiry %></span>
      <% } %>
    </a>
    <a href="${pageContext.request.contextPath}/purchase-orders"
       class="nav-item <%= "purchase-orders".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">📦</span> Phiếu nhập kho
    </a>
    <a href="${pageContext.request.contextPath}/returns"
       class="nav-item <%= "returns".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">📤</span> Đơn trả/hủy hàng
    </a>
  </nav>

  <nav class="nav-section">
    <div class="nav-label">Cá nhân</div>
    <a href="${pageContext.request.contextPath}/staff-profile<%= uidParam %>"
       class="nav-item <%= "profile".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">👤</span> Hồ sơ của tôi
    </a>
    <a href="${pageContext.request.contextPath}/staff-checkin<%= uidParam %>"
       class="nav-item <%= "checkin".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">✅</span> Điểm danh
    </a>
    <a href="${pageContext.request.contextPath}/staff-my-shifts<%= uidParam %>"
       class="nav-item <%= "shifts".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">🕐</span> Ca làm việc
    </a>
    <a href="${pageContext.request.contextPath}/leave-requests?action=my<%= uidAmp %>"
       class="nav-item <%= "leave".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">🏖️</span> Xin nghỉ phép
    </a>
  </nav>

  <div class="sidebar-footer">
    <a href="${pageContext.request.contextPath}/logout?from=staff<%= uidAmp %>" class="logout-btn-full">
      <span style="font-size:15px;line-height:1">⏻</span>
      <span>Đăng xuất</span>
    </a>
  </div>
  <% } else { %>
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
    <a href="${pageContext.request.contextPath}/task-management"
       class="nav-item <%= "task-management".equals(activeNav) ? "active" : "" %>">
      <span class="nav-icon">🎯</span> Giao task &amp; Tiến độ kho
      <% if (taskWatchdog > 0) { %>
      <span class="nav-badge" style="background:#DC2626"><%= taskWatchdog %></span>
      <% } %>
    </a>
  </nav>

  <div class="sidebar-footer">
    <a href="${pageContext.request.contextPath}/logout" class="logout-btn-full">
      <span style="font-size:15px;line-height:1">⏻</span>
      <span>Đăng xuất</span>
    </a>
  </div>
  <% } %>
</aside>
</aside>
<%-- ══ CSS SIDEBAR CHUẨN — đặt trong body nên GHI ĐÈ style riêng của từng trang
     (thắng theo thứ tự nguồn), đảm bảo sidebar ĐỒNG NHẤT trên MỌI tab. ══ --%>
<style>
:root{--sidebar:232px}
.sidebar{width:232px;min-height:100vh;background:linear-gradient(175deg,#071022 0%,#0F2645 45%,#1558A8 100%);display:flex;flex-direction:column;position:fixed;left:0;top:0;bottom:0;z-index:100;box-shadow:4px 0 32px rgba(0,0,0,.18);overflow-y:auto}
.sidebar-logo{height:66px;padding:0 20px;display:flex;align-items:center;gap:11px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
.logo-text{font-size:16px;font-weight:800;color:#fff;letter-spacing:-.2px;line-height:1.1}
.logo-text span{color:#3ABDE0}
.logo-sub{font-size:9px;color:rgba(255,255,255,.3);letter-spacing:1.2px;text-transform:uppercase;margin-top:1px}
.nav-section{padding:12px 0 4px;flex-shrink:0}
.nav-label{font-size:9px;font-weight:750;letter-spacing:1.8px;text-transform:uppercase;color:rgba(255,255,255,.2);padding:0 20px 6px}
.nav-item{display:flex;align-items:center;gap:10px;padding:9px 12px 9px 20px;margin:1px 10px;border-radius:10px;font-size:13px;font-weight:750;color:rgba(255,255,255,.5);text-decoration:none;transition:all .18s;position:relative}
.nav-item:hover{color:rgba(255,255,255,.9);background:rgba(255,255,255,.06)}
.nav-item.active{color:#fff;background:rgba(58,189,224,.14);font-weight:750}
.nav-item.active::before{content:'';position:absolute;left:-10px;top:50%;transform:translateY(-50%);width:3px;height:56%;background:#3ABDE0;border-radius:2px}
.nav-icon{width:18px;text-align:center;font-size:14px;flex-shrink:0;opacity:.8}
.nav-item.active .nav-icon{opacity:1}
.nav-badge{margin-left:auto;background:#DC2626;color:#fff;font-size:10px;font-weight:750;padding:1px 7px;border-radius:20px;min-width:20px;text-align:center}
.main{margin-left:232px;flex:1;display:flex;flex-direction:column;min-height:100vh;min-width:0}
.sidebar-footer{margin-top:auto;padding:20px 14px 16px;border-top:1px solid rgba(255,255,255,.07);flex-shrink:0}
.logout-btn-full{display:flex;align-items:center;justify-content:center;gap:8px;width:100%;padding:10px 14px;border-radius:10px;background:rgba(220,38,38,.35);border:1.5px solid rgba(220,38,38,.3);color:#FF6B6B;text-decoration:none;font-family:'Plus Jakarta Sans',sans-serif;font-size:13px;font-weight:750;letter-spacing:.3px;transition:all .2s}
.logout-btn-full:hover{background:rgba(220,38,38,.58);color:#fff;border-color:#DC2626}
@media(max-width:820px){
  .sidebar{transform:translateX(-100%);transition:transform .25s ease}
  .sidebar.open{transform:translateX(0)}
  .main{margin-left:0}
}
/* ── Chuyển trang: đã TẮT View Transitions API (crossfade) ──
   Native navigation cần snapshot toàn bộ DOM before/after để composite crossfade —
   tốn paint time thật trên trang nặng (shift-list.jsp 47KB, medicine-list.jsp).
   App quản lý/POS cần thao tác nhanh, bấm phát ăn ngay nên bỏ hẳn hiệu ứng này,
   giữ lại các micro-interaction rẻ (hover, active state — chỉ opacity/transform, GPU nhẹ). */
</style>
<%-- Click mục đang active KHÔNG reload lại trang (giữ nguyên tab hiện tại) --%>
<script>
document.querySelectorAll('.sidebar .nav-item.active').forEach(function(a){
  a.addEventListener('click', function(e){ e.preventDefault(); });
});
</script>
