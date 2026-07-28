# MediVault — Project Tree

> **Stack**: Jakarta EE 10 · Tomcat 10 · SQL Server (remote) · JSP/JSTL · HikariCP · Caffeine Cache  
> **Cập nhật**: 2026-07-15

---

## Cấu trúc thư mục

```
MediVault/
├── pom.xml                          # Maven build (Jakarta EE 10, HikariCP, BCrypt, face-api)
└── src/main/
    ├── java/com/medicare/
    │   ├── config/                  # Cấu hình hệ thống
    │   │   ├── AppCache.java        # Khởi tạo Caffeine cache khi app start
    │   │   ├── CacheManager.java    # 4 tầng cache: SHORT(30s) / 3min / 5min / 15min
    │   │   ├── DBContext.java       # HikariCP pool (30 conn, QUOTED_IDENTIFIER ON)
    │   │   └── PayOSConfig.java     # Cấu hình cổng thanh toán PayOS
    │   │
    │   ├── controller/              # Servlets — xử lý HTTP request
    │   │   ├── AppTimeZoneListener.java   # Set JVM timezone Asia/Ho_Chi_Minh khi startup
    │   │   ├── AuthFilter.java            # Bộ lọc xác thực session cho toàn app
    │   │   ├── CustomerPortalServlet.java # Portal dành cho khách hàng (/portal)
    │   │   ├── ForgotPasswordServlet.java # Quên mật khẩu qua email OTP
    │   │   ├── LeaveRequestServlet.java   # Xin nghỉ phép (nhân viên gửi)
    │   │   ├── LoginServlet.java          # Đăng nhập admin (/login)
    │   │   ├── LogoutServlet.java         # Đăng xuất (/logout)
    │   │   ├── NfcAttendanceServlet.java  # Điểm danh bằng thẻ NFC
    │   │   ├── OtpServlet.java            # Xác minh OTP email
    │   │   ├── SessionListener.java       # Theo dõi session online (SessionTracker)
    │   │   │
    │   │   ├── admin/               # Servlet dành riêng cho Admin (roleId=1)
    │   │   │   ├── AccountDetailServlet.java    # Xem chi tiết 1 tài khoản
    │   │   │   ├── AccountServlet.java          # CRUD tài khoản nhân viên (/accounts)
    │   │   │   ├── AdminProfileServlet.java     # Trang hồ sơ admin (/admin-profile)
    │   │   │   ├── AttendanceServlet.java        # Quản lý chấm công (/attendance)
    │   │   │   ├── AuditLogServlet.java          # Nhật ký hành động (/audit-logs)
    │   │   │   ├── CategoryServlet.java          # CRUD danh mục thuốc (/categories)
    │   │   │   ├── CustomerServlet.java          # CRUD khách hàng (/customers)
    │   │   │   ├── DashboardServlet.java         # Trang chủ admin (/dashboard)
    │   │   │   ├── EncodingRepairServlet.java    # Tool sửa lỗi encoding dữ liệu cũ
    │   │   │   ├── FaceEnrollServlet.java        # Đăng ký khuôn mặt nhân viên (admin)
    │   │   │   ├── InventorySSEServlet.java      # SSE realtime tồn kho
    │   │   │   ├── InvoiceServlet.java           # Quản lý hóa đơn (/invoices)
    │   │   │   ├── MedicineServlet.java          # CRUD thuốc + lô hàng (/medicines)
    │   │   │   ├── PayrollServlet.java           # Quản lý bảng lương (/payroll)
    │   │   │   ├── PurchaseOrderServlet.java     # Đơn đặt hàng PENDING→COMPLETED (/purchase-orders)
    │   │   │   ├── ReportServlet.java            # Báo cáo doanh thu (/reports)
    │   │   │   ├── ResetRequestServlet.java      # Duyệt yêu cầu reset mật khẩu
    │   │   │   ├── ReturnsServlet.java           # Quản lý trả hàng (/returns)
    │   │   │   ├── ShelfServlet.java             # CRUD vị trí kệ thuốc (/shelves)
    │   │   │   ├── ShiftScheduleServlet.java     # Lịch làm việc nhân viên (/shift-schedules)
    │   │   │   ├── ShiftServlet.java             # Quản lý ca trực (/shifts)
    │   │   │   ├── ShiftTypeServlet.java         # Loại ca trực (/shift-types)
    │   │   │   └── SupplierServlet.java          # CRUD nhà cung cấp (/suppliers)
    │   │   │
    │   │   ├── pos/                 # Point-of-Sale
    │   │   │   ├── NfcBridgeServlet.java  # SSE bridge NFC card: phone→POS realtime
    │   │   │   └── PosServlet.java        # Màn hình bán hàng multi-quầy (/pos)
    │   │   │
    │   │   └── staff/               # Servlet dành cho nhân viên (roleId≥2)
    │   │       ├── FaceReenrollServlet.java      # Yêu cầu đăng ký lại khuôn mặt
    │   │       ├── StaffAttendanceServlet.java   # Xem bảng chấm công cá nhân
    │   │       ├── StaffDashboardServlet.java    # Trang chủ nhân viên (/staff-dashboard)
    │   │       ├── StaffFaceEnrollServlet.java   # Tự đăng ký khuôn mặt
    │   │       ├── StaffLoginServlet.java        # Đăng nhập nhân viên (/staff-login)
    │   │       ├── StaffNotificationServlet.java # Thông báo nội bộ (SSE + REST)
    │   │       ├── StaffPingServlet.java         # Ping cập nhật LastActiveAt (presence)
    │   │       ├── StaffProfileServlet.java      # Hồ sơ cá nhân nhân viên
    │   │       └── StaffShiftServlet.java        # Ca trực của tôi (/my-shifts)
    │   │
    │   ├── dao/                     # Data Access Objects — truy vấn SQL Server
    │   │   ├── interfaces/          # Interface cho từng DAO (dependency injection)
    │   │   │   ├── IAccountDAO.java
    │   │   │   ├── IAttendanceDAO.java
    │   │   │   ├── IAuditLogDAO.java
    │   │   │   ├── IBatchesDAO.java
    │   │   │   ├── ICategoryDAO.java
    │   │   │   ├── ICustomerDAO.java
    │   │   │   ├── IInvoiceDAO.java
    │   │   │   ├── IInvoiceDetailDAO.java
    │   │   │   ├── ILeaveRequestDAO.java
    │   │   │   ├── IMachineCommandDAO.java
    │   │   │   ├── IManufacturerDAO.java
    │   │   │   ├── IMedicineDAO.java
    │   │   │   ├── IPasswordResetDAO.java
    │   │   │   ├── IPayrollDAO.java
    │   │   │   ├── IPosStationDAO.java
    │   │   │   ├── IPrescriptionDAO.java
    │   │   │   ├── IPurchaseOrderDAO.java
    │   │   │   ├── IReturnsDAO.java
    │   │   │   ├── IShelfDAO.java
    │   │   │   ├── IShiftDAO.java
    │   │   │   ├── IShiftScheduleDAO.java
    │   │   │   ├── IShiftTypeDAO.java
    │   │   │   ├── IStaffAuditLogDAO.java
    │   │   │   └── ISupplierDAO.java
    │   │   │
    │   │   ├── AccountDAO.java          # Tài khoản: CRUD, softDelete (đổi username→__del_), restore (khôi phục username gốc), isEmailTaken lọc IsDeleted=0
    │   │   ├── AttendanceDAO.java       # Chấm công: NFC, khuôn mặt, thủ công
    │   │   ├── AuditLogDAO.java         # Nhật ký admin (fix OFFSET literal cho mssql-jdbc)
    │   │   ├── BatchesDAO.java          # Lô thuốc: tồn kho, hạn sử dụng, batchSummary
    │   │   ├── CategoryDAO.java         # Danh mục thuốc
    │   │   ├── CustomerDAO.java         # Khách hàng + thẻ tích điểm
    │   │   ├── InvoiceDAO.java          # Hóa đơn bán hàng
    │   │   ├── InvoiceDetailDAO.java    # Chi tiết hóa đơn
    │   │   ├── LeaveRequestDAO.java     # Đơn xin nghỉ
    │   │   ├── LoyaltyDAO.java          # Tích điểm khách hàng
    │   │   ├── MachineCommandDAO.java   # Lệnh máy tự động
    │   │   ├── ManufacturerDAO.java     # Nhà sản xuất
    │   │   ├── MedicineDAO.java         # Thuốc: phân trang, tìm kiếm, duplicate check
    │   │   ├── PasswordResetDAO.java    # Yêu cầu đặt lại mật khẩu
    │   │   ├── PayrollDAO.java          # Bảng lương
    │   │   ├── PosStationDAO.java       # Quầy POS (tên, trạng thái)
    │   │   ├── PrescriptionDAO.java     # Đơn thuốc
    │   │   ├── PurchaseOrderDAO.java    # Đặt hàng: PENDING→COMPLETED, confirmReceived
    │   │   ├── ReturnsDAO.java          # Trả hàng
    │   │   ├── ShelfDAO.java            # Vị trí kệ (bỏ computed column IsAutomated)
    │   │   ├── ShiftDAO.java            # Ca trực: tạo, đóng, lịch sử
    │   │   ├── ShiftScheduleDAO.java    # Lịch phân công ca
    │   │   ├── ShiftTypeDAO.java        # Loại ca (sáng/chiều/tối)
    │   │   ├── StaffAuditLogDAO.java    # Nhật ký hành động nhân viên
    │   │   ├── StaffNotificationDAO.java # Thông báo nội bộ admin→nhân viên
    │   │   └── SupplierDAO.java         # Nhà cung cấp: CRUD + toggleActive
    │   │
    │   ├── entity/                  # POJO Entity — ánh xạ bảng DB
    │   │   ├── Account.java             # Tài khoản (username, hash, face, NFC, re-enroll)
    │   │   ├── Attendance.java          # Bản ghi điểm danh
    │   │   ├── AuditLog.java            # Bản ghi nhật ký admin
    │   │   ├── Batches.java             # Lô thuốc (số lô, HSD, NSX, số lượng)
    │   │   ├── Category.java            # Danh mục thuốc
    │   │   ├── Customer.java            # Khách hàng (SĐT, điểm, thẻ NFC)
    │   │   ├── Invoice.java             # Hóa đơn (finalAmount, status, discount)
    │   │   ├── InvoiceDetail.java       # Chi tiết hóa đơn (batch, qty, price)
    │   │   ├── LeaveRequest.java        # Đơn xin nghỉ
    │   │   ├── LoyaltyCard.java         # Thẻ tích điểm
    │   │   ├── LoyaltyTier.java         # Hạng thành viên (đồng/bạc/vàng)
    │   │   ├── MachineCommand.java      # Lệnh máy tự động
    │   │   ├── Manufacturer.java        # Nhà sản xuất
    │   │   ├── Medicines.java           # Thuốc (tên, mã, danh mục, kệ, PackagingSpec)
    │   │   ├── OrderLog.java            # Log đặt hàng
    │   │   ├── PasswordResetRequest.java # Yêu cầu reset mật khẩu
    │   │   ├── Payroll.java             # Bảng lương
    │   │   ├── PointTransaction.java    # Lịch sử giao dịch điểm
    │   │   ├── PosStation.java          # Quầy POS (tên, trạng thái)
    │   │   ├── Prescription.java        # Đơn thuốc
    │   │   ├── PrescriptionDetails.java # Chi tiết đơn thuốc
    │   │   ├── PurchaseOrderDetail.java # Chi tiết đơn đặt hàng (lô, giá, hạn)
    │   │   ├── PurchaseOrders.java      # Phiếu nhập kho (PENDING/COMPLETED, paymentMethod)
    │   │   ├── Returns.java             # Trả hàng
    │   │   ├── Role.java                # Vai trò (Admin/Dược sĩ/Thủ kho)
    │   │   ├── Shelf.java               # Kệ thuốc (tên, loại, vị trí)
    │   │   ├── Shift.java               # Ca trực (giờ mở/đóng, quầy POS)
    │   │   ├── ShiftSchedule.java       # Phân công ca
    │   │   ├── ShiftType.java           # Loại ca (sáng 6h-14h, v.v.)
    │   │   ├── StaffAuditLog.java       # Nhật ký nhân viên
    │   │   ├── StockMovements.java      # Lịch sử xuất/nhập kho
    │   │   └── Supplier.java            # Nhà cung cấp (tên, MST, địa chỉ, SĐT)
    │   │
    │   ├── filter/
    │   │   └── AppFilter.java           # Filter encoding UTF-8 toàn bộ request
    │   │
    │   ├── service/                 # Business Logic Layer
    │   │   ├── interfaces/
    │   │   │   ├── IAccountService.java
    │   │   │   ├── IMedicineService.java
    │   │   │   └── ISaleService.java
    │   │   ├── AccountService.java      # Tạo TK (hash BCrypt, OTP email, notification)
    │   │   ├── MedicineService.java     # Nhập lô: PENDING PO hoặc COMPLETED
    │   │   ├── PayOSService.java        # Tích hợp cổng thanh toán PayOS
    │   │   ├── SaleService.java         # Logic bán hàng POS (giảm tồn, tích điểm)
    │   │   ├── ServiceResult.java       # Wrapper kết quả: ok(data) / fail(errors)
    │   │   └── ShiftAutoCloseService.java # Scheduler tự đóng ca quá giờ
    │   │
    │   ├── tools/                   # Tiện ích chạy 1 lần (không phải web servlet)
    │   │   ├── DatabaseFixer.java   # Sửa dữ liệu encoding lỗi trong DB
    │   │   ├── FixDB.java           # Script sửa schema/data
    │   │   └── TestDB.java          # Test kết nối DB
    │   │
    │   └── util/                    # Helper & Utilities
    │       ├── AuditHelper.java         # Ghi audit log tiện lợi (1 dòng gọi)
    │       ├── CsrfUtil.java            # CSRF token generate/validate
    │       ├── EmailUtil.java           # Gửi email (JavaMail, async thread)
    │       ├── FaceVerifier.java        # 1-vs-N face matching (cosine distance)
    │       ├── GenerateHash.java        # Tiện ích generate BCrypt hash
    │       ├── MojibakeUtil.java        # Sửa chuỗi bị lỗi encoding Mojibake
    │       ├── NotificationUtil.java    # Push thông báo nội bộ
    │       ├── OtpUtil.java             # Generate + validate OTP 6 số
    │       ├── PasswordUtil.java        # BCrypt hash/check
    │       ├── PricingUtil.java         # Tính tiền VND: kẹp giảm giá [0,subtotal], sàn total=0 (settle/calculateFinalTotal)
    │       ├── SessionTracker.java      # Theo dõi nhân viên đang online (in-memory Set)
    │       ├── SidebarHelper.java       # Load badge counts cho sidebar (cache 30s)
    │       ├── StaffNotifHelper.java    # Helper gửi thông báo chuẩn (created/reset/face)
    │       └── ValidationUtil.java      # Validate email, SĐT, CMND, mật khẩu, username
    │
    ├── resources/
    │   └── db.properties            # JDBC URL, credentials (không commit lên git)
    │
    └── webapp/
        ├── WEB-INF/
        │   ├── web.xml              # Servlet mapping, session config, error pages
        │   ├── context.xml          # Tomcat context (docBase)
        │   ├── dangky.jsp           # (Legacy) trang đăng ký
        │   └── views/
        │       ├── admin/           # JSP dành cho Admin Console
        │       │   ├── sidebar.jsp               # Sidebar chung (View Transitions, badge, nav)
        │       │   ├── dashboard.jsp             # Tổng quan: KPI, chart, ca hôm nay
        │       │   ├── account-list.jsp          # Danh sách nhân viên + khách hàng (tab)
        │       │   ├── account-form.jsp          # Tạo/sửa tài khoản (BCrypt, face enroll)
        │       │   ├── account-detail.jsp        # Xem chi tiết tài khoản
        │       │   ├── account-trash.jsp         # Thùng rác tài khoản
        │       │   ├── admin-profile.jsp         # Hồ sơ admin đang đăng nhập
        │       │   ├── admin-otp-confirm.jsp     # Xác nhận OTP reset mật khẩu
        │       │   ├── admin-set-password.jsp    # Đặt mật khẩu mới cho nhân viên
        │       │   ├── admin-delete-confirm.jsp  # Xác nhận xóa tài khoản
        │       │   ├── admin-delete-otp.jsp      # OTP xác nhận xóa
        │       │   ├── medicine-list.jsp         # Kho thuốc (pill tabs, hover card, batch)
        │       │   ├── medicine-form.jsp         # Thêm/sửa thuốc
        │       │   ├── medicine-detail.jsp       # Chi tiết thuốc
        │       │   ├── batch-form.jsp            # Nhập lô (packaging units, PENDING flow)
        │       │   ├── purchase-order-list.jsp   # Danh sách phiếu nhập (⏳/✅ status)
        │       │   ├── purchase-order-form.jsp   # Tạo phiếu nhập (multi-line, PENDING/COMPLETED)
        │       │   ├── purchase-order-detail.jsp # Chi tiết phiếu + Xác nhận hàng đã tới
        │       │   ├── supplier-list.jsp         # Danh sách nhà cung cấp
        │       │   ├── supplier-form.jsp         # Thêm/sửa nhà cung cấp
        │       │   ├── shelf-list.jsp            # Danh sách kệ thuốc
        │       │   ├── shelf-form.jsp            # Thêm/sửa kệ
        │       │   ├── category-list.jsp         # Danh mục thuốc
        │       │   ├── category-form.jsp         # Thêm/sửa danh mục
        │       │   ├── invoice-list.jsp          # Hóa đơn bán hàng + trả hàng (tab)
        │       │   ├── invoice-detail.jsp        # Chi tiết hóa đơn
        │       │   ├── returns-list.jsp          # Danh sách trả hàng
        │       │   ├── returns-form.jsp          # Tạo phiếu trả hàng
        │       │   ├── customer-list.jsp         # Danh sách khách hàng
        │       │   ├── customer-form.jsp         # Thêm/sửa khách hàng
        │       │   ├── customer-detail.jsp       # Chi tiết khách hàng + điểm tích lũy
        │       │   ├── shift-list.jsp            # Ca trực + lịch tuần 3D
        │       │   ├── shift-detail.jsp          # Chi tiết ca
        │       │   ├── shift-force-close.jsp     # Đóng ca cưỡng bức
        │       │   ├── shift-schedule-week.jsp   # Lịch phân công theo tuần
        │       │   ├── shift-schedule-detail.jsp # Chi tiết lịch phân công
        │       │   ├── attendance-list.jsp       # Danh sách chấm công
        │       │   ├── attendance-live.jsp       # Chấm công realtime (SSE)
        │       │   ├── attendance-monthly.jsp    # Báo cáo chấm công tháng
        │       │   ├── leave-request-list.jsp    # Danh sách đơn nghỉ phép
        │       │   ├── leave-request-pending.jsp # Duyệt đơn nghỉ chờ xử lý
        │       │   ├── payroll-list.jsp          # Danh sách bảng lương
        │       │   ├── payroll-detail.jsp        # Chi tiết lương 1 nhân viên
        │       │   ├── audit-log-list.jsp        # Nhật ký (filter: Role → NV → Loại)
        │       │   └── report-list.jsp           # Báo cáo doanh thu
        │       │
        │       ├── pos/
        │       │   └── pos.jsp              # POS bán hàng (multi-quầy, NFC bridge, customer)
        │       │
        │       ├── staff/               # JSP dành cho nhân viên
        │       │   ├── staff-login.jsp          # Đăng nhập nhân viên
        │       │   ├── staff-dashboard.jsp      # Trang chủ nhân viên
        │       │   ├── staff-dashboard-shift-section.jsp # Phần ca trực trong dashboard
        │       │   ├── staff-checkin.jsp        # Check-in điểm danh (face/NFC)
        │       │   ├── staff-profile.jsp        # Hồ sơ nhân viên
        │       │   ├── staff-my-shifts.jsp      # Ca trực của tôi
        │       │   ├── leave-request-form.jsp   # Form xin nghỉ phép
        │       │   ├── leave-request-my.jsp     # Đơn nghỉ của tôi
        │       │   └── pos.jsp                  # POS nhân viên (giới hạn quyền)
        │       │
        │       ├── portal/              # Cổng khách hàng
        │       │   ├── portal-login.jsp         # Đăng nhập khách hàng (SĐT + OTP)
        │       │   └── customer-portal.jsp      # Dashboard khách hàng (điểm, lịch sử)
        │       │
        │       ├── error/
        │       │   ├── 404.jsp
        │       │   └── 500.jsp
        │       │
        │       ├── login.jsp            # Đăng nhập admin
        │       ├── forgot-password.jsp  # Quên mật khẩu
        │       ├── otp-verify.jsp       # Nhập OTP
        │       ├── icons.jsp            # Thư viện icon SVG dùng chung
        │       └── loading.jsp          # Màn hình loading (đã tắt — gây white flash)
        │
        ├── css/
        │   └── staff-portal.css     # CSS riêng cho portal nhân viên
        │
        ├── js/
        │   ├── csrf.js              # Tự gắn token CSRF vào mọi fetch/XHR/form (POST/PUT/DELETE)
        │   └── face-api/
        │       └── face-api.min.js  # face-api.js (offline, bundle local)
        │
        ├── models/                  # Model weights face-api.js (offline)
        │   ├── tiny_face_detector_model-shard1
        │   ├── tiny_face_detector_model-weights_manifest.json
        │   ├── face_landmark_68_model-shard1
        │   ├── face_landmark_68_model-weights_manifest.json
        │   ├── face_recognition_model-shard1
        │   ├── face_recognition_model-shard2
        │   └── face_recognition_model-weights_manifest.json
        │
        ├── images/
        │   └── NEW_LOGO.png
        │
        └── uploads/
            └── avatars/             # Ảnh đại diện tài khoản

  (ĐÃ XOÁ vì lý do bảo mật — không khôi phục lại:
     fix.jsp      — script dev chạy UPDATE hàng loạt lên DB, không cần đăng nhập
     test-db.jsp  — in mật khẩu DB dạng plaintext ra source)
```

---

## URL Mapping (Servlet → JSP)

| URL | Servlet | JSP | Vai trò |
|-----|---------|-----|---------|
| `/login` | LoginServlet | login.jsp | Tất cả |
| `/dashboard` | DashboardServlet | admin/dashboard.jsp | Admin |
| `/medicines` | MedicineServlet | admin/medicine-list.jsp | Admin |
| `/purchase-orders` | PurchaseOrderServlet | admin/purchase-order-*.jsp | Admin |
| `/suppliers` | SupplierServlet | admin/supplier-*.jsp | Admin |
| `/shelves` | ShelfServlet | admin/shelf-*.jsp | Admin |
| `/accounts` | AccountServlet | admin/account-*.jsp | Admin |
| `/admin-profile` | AdminProfileServlet | admin/admin-profile.jsp | Admin |
| `/invoices` | InvoiceServlet | admin/invoice-*.jsp | Admin |
| `/returns` | ReturnsServlet | admin/returns-*.jsp | Admin |
| `/customers` | CustomerServlet | admin/customer-*.jsp | Admin |
| `/shifts` | ShiftServlet | admin/shift-*.jsp | Admin |
| `/shift-schedules` | ShiftScheduleServlet | admin/shift-schedule-*.jsp | Admin |
| `/attendance` | AttendanceServlet | admin/attendance-*.jsp | Admin |
| `/payroll` | PayrollServlet | admin/payroll-*.jsp | Admin |
| `/audit-logs` | AuditLogServlet | admin/audit-log-list.jsp | Admin |
| `/reports` | ReportServlet | admin/report-list.jsp | Admin |
| `/pos` | PosServlet | pos/pos.jsp | Dược sĩ |
| `/nfc-bridge` | NfcBridgeServlet | — (SSE) | POS |
| `/staff-dashboard` | StaffDashboardServlet | staff/staff-dashboard.jsp | Nhân viên |
| `/portal` | CustomerPortalServlet | portal/customer-portal.jsp | Khách hàng |

---

## Kiến trúc lớp

```
HTTP Request
    │
    ▼
AuthFilter (xác thực session, redirect nếu chưa login)
    │
    ▼
Controller (Servlet)  ←→  SidebarHelper (badge counts, cache 30s)
    │
    ├──► Service (business logic, validate, hash, email)
    │        │
    │        └──► DAO (SQL Server qua HikariCP)
    │                  │
    │                  └──► DBContext (HikariCP pool, 30 conn, QUOTED_IDENTIFIER ON)
    │
    └──► JSP + JSTL (render HTML)
              │
              └── sidebar.jsp (View Transitions, nav, badges)
```

---

## Các tính năng đặc biệt

| Tính năng | Mô tả | File chính |
|-----------|-------|-----------|
| **Face ID Điểm danh** | face-api.js offline, 1-vs-N matching | FaceVerifier.java, staff-checkin.jsp |
| **NFC Bridge SSE** | Realtime phone→POS qua Server-Sent Events | NfcBridgeServlet.java, pos.jsp |
| **Multi-POS** | Nhiều quầy bán hàng đồng thời | PosServlet.java, PosStationDAO.java |
| **PO Workflow** | Đặt hàng PENDING → Xác nhận hàng đến → COMPLETED | PurchaseOrderDAO.java |
| **Caffeine Cache** | 4 tầng: 30s/3min/5min/15min cho dashboard + sidebar | CacheManager.java |
| **View Transitions** | Crossfade mượt khi chuyển trang (native CSS) | sidebar.jsp |
| **Audit Log** | Mọi thao tác admin được ghi nhật ký | AuditHelper.java, AuditLogDAO.java |
| **Soft Delete** | Xóa mềm tài khoản (username giải phóng tự động) | AccountDAO.softDelete() |
| **PayOS** | Tích hợp thanh toán trực tuyến | PayOSService.java |
| **OTP Email** | Xác thực 2 bước qua Gmail SMTP | OtpUtil.java, EmailUtil.java |
