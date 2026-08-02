# Đối chiếu DOC_BAOCAO với mã nguồn thực tế (Java/MediVault)

Ngày đối chiếu: 02/08/2026 · So sánh: `MediCare (1).docx` (bản gốc) vs `src/main` hiện tại

---

## 1. Đã sửa: FIFO → FEFO

Phát hiện: cơ chế xuất kho trong Stored Procedure **luôn luôn** chọn lô theo `ORDER BY ExpiryDate ASC` — tức là chọn lô **hết hạn sớm nhất** trước, không phải lô **nhập kho sớm nhất** trước. Đây chính là **FEFO (First Expired, First Out)**, không phải FIFO (First-In, First-Out). Code JSP (medicine-detail, medicine-list, warehouse-*) đã dùng đúng thuật ngữ "FEFO" từ trước; DAO/Service cũng gọi stored procedure tên `SP_AddSaleByFEFO`. Nhưng script SQL khởi tạo DB và báo cáo vẫn còn dùng tên/thuật ngữ FIFO cũ — nếu setup DB mới từ script cũ, ứng dụng sẽ lỗi vì gọi `SP_AddSaleByFEFO` nhưng script chỉ tạo `SP_AddSaleByFIFO`.

Đã sửa đồng bộ toàn bộ dự án:

| File | Thay đổi |
|---|---|
| `TaiNguyen/create_sp.sql` | `SP_AddSaleByFIFO` → `SP_AddSaleByFEFO` |
| `TaiNguyen/Database_v1.sql` | `SP_AddSaleByFIFO` → `SP_AddSaleByFEFO`; `IX_Batch_Med_FIFO` → `IX_Batch_Med_FEFO` |
| `TaiNguyen/MediVault_Use_Case_Diagram.drawio` | "FIFO Stock Allocation", "Xem lịch sử xuất kho FIFO" → FEFO |
| `TaiNguyen/MediVault_Sequence_Diagram.drawio` | `addItemByFIFO()` → `addItemByFEFO()` |
| `Java/MediVault/.../dao/interfaces/IInvoiceDAO.java` | method `addItemByFIFO` → `addItemByFEFO` |
| `Java/MediVault/.../dao/InvoiceDAO.java` | method + comment + log message đổi sang FEFO |
| `Java/MediVault/.../service/SaleService.java` | comment "trừ kho FIFO" → "trừ kho FEFO" |
| `TaiNguyen/DOC_BAOCAO/MediCare (FEFO).docx` + `.pdf` | 46 chỗ FIFO → FEFO trong toàn bộ báo cáo (đoạn văn + 12 bảng), giữ nguyên định dạng gốc. Bản gốc `MediCare (1).docx` được giữ nguyên không đổi để đối chiếu. |

Đã build lại PDF từ docx đã sửa và quét lại toàn văn bản — xác nhận **0** chỗ còn sót "FIFO", **46** chỗ "FEFO".

---

## 2. Những phần báo cáo đã lỗi thời so với code (cần điều chỉnh)

Code hiện tại (178 file Java, 79 JSP) đã phát triển vượt xa những gì DOC_BAOCAO mô tả. Các điểm sau nên được cập nhật trước khi nộp/thuyết trình:

### 2.1. Mục 4.1.4 "Hạn chế" — sai lệch rõ nhất
Báo cáo ghi: *"Không có Service Layer chính thức — một số logic phức tạp đặt trong Servlet hoặc DAO"*.
Thực tế: đã có gói `service/` đầy đủ — `AccountService`, `MedicineService`, `SaleService`, `PayOSService`, `ReorderAlertService`, `ShiftAutoCloseService`, `TaskAutoGenService` + interface riêng (`service/interfaces`). `SaleService` ghi rõ trong Javadoc: *"Trước đây logic này nằm rải rác trong PosServlet + InvoiceDAO"* — nghĩa là refactor đã diễn ra sau khi viết báo cáo.
→ Câu này ở mục 4.1.4, mục 7.1.1, mục 7.3 (bullet 1) và mục 7.4.1 (bullet 1, "Thêm Service Layer chính thức") đều cần xóa/viết lại vì mục tiêu ngắn hạn này **đã hoàn thành**.

### 2.2. Thiếu hẳn phân hệ Warehouse (kho vận độc lập)
Code có `controller/warehouse/` với 10 servlet riêng (đăng nhập kho, nhập hàng, tồn kho, thu hồi lô hàng lỗi — Recall, đặt hàng lại — Reorder, di chuyển kho — StockMovement, quản lý task kho) + 10 JSP tương ứng (`warehouse-*.jsp`) + `util/WarehouseAuth.java`. Đây là một actor/phân hệ hoàn toàn mới, không có trong mục 3.1 (9 phân hệ), không có trong Use Case Diagram, không có trong ERD.
→ Cần thêm mục "3.1.10 Phân hệ Kho vận (Warehouse)" + actor mới trong 3.5.1 + use case chi tiết.

### 2.3. Các module khác chưa được mô tả
- **Payroll** (`PayrollServlet`, `PayrollDAO`, entity `Payroll`) — quản lý bảng lương, không có trong ERD/đặc tả.
- **Task Management** (`TaskManagementServlet`, `TaskDAO`, `TaskAutoGenService`, entity `Task`) — sinh task tự động.
- **PayOS** (`PayOSService`, `PayOSConfig`) — tích hợp cổng thanh toán online. Đáng chú ý: mục 7.4.2 (hướng phát triển trung hạn) ghi *"Tích hợp cổng thanh toán điện tử (VNPay, MoMo)"* như một việc **chưa làm**, trong khi PayOS đã được tích hợp thực tế.
- **Face Recognition** (`FaceEnrollServlet`, `FaceReenrollServlet`, `StaffFaceEnrollServlet`, `util/FaceVerifier.java`, thư mục `webapp/js/face-api`) — điểm danh bằng khuôn mặt.
- **NFC** (`NfcAttendanceServlet`, `NfcBridgeServlet`) — điểm danh và đăng nhập POS bằng thẻ NFC.
- **Leave Request / Attendance / Shift Schedule** — nghỉ phép, chấm công, lịch ca chi tiết (`LeaveRequestServlet`, `AttendanceServlet`, `ShiftScheduleServlet`).
- **SSE realtime** — `InventorySSEServlet`, `StaffNotificationServlet` (thông báo đẩy realtime), trong khi mục 7.3 ghi hạn chế *"Chưa có tính năng thông báo push realtime"*.
- **Cache đa tầng (Caffeine)** — `config/AppCache.java`, `config/CacheManager.java` (4 tầng: 30s/3min/5min/15min), trong khi mục 4.1.4 và 7.3 ghi *"Chưa có cache layer"*.

### 2.4. ERD / Class Diagram (mục 4.2, 4.5) thiếu entity
33 entity trong code nhưng ERD báo cáo chỉ liệt kê ~25 bảng theo 4 nhóm. Thiếu: `PosStation`, `Task`, `Payroll`, `ShiftSchedule`, `ShiftType`, `StaffAuditLog`, `LeaveRequest`, `Attendance`, `PasswordResetRequest`, `PrescriptionDetails`, `PurchaseOrderDetail`.

### 2.5. Chương 6 (Kiểm thử) chỉ có 8 module
Test case liệt kê 8 module (Admin Login, Staff Login+OTP, Account CRUD, Category, POS, Máy cấp thuốc, AuthFilter, Dashboard). Không có test case cho Warehouse, Payroll, Face Recognition, NFC, Task, PayOS — đều là phần đã code nhưng chưa được kiểm thử/ghi nhận trong báo cáo.

### 2.6. Mục 7.3 "Hạn chế hiện tại" và 7.4 "Hướng phát triển" cần viết lại
Nhiều mục trong "hạn chế" đã được khắc phục (Service Layer, cache, push notification), và một số mục trong "hướng phát triển trung hạn" đã được làm xong (cổng thanh toán). Nên rà soát lại để tránh mâu thuẫn khi hội đồng đọc kỹ (một hạn chế tự nhận nhưng code lại chứng minh ngược lại sẽ gây mất điểm).

---

## 3. Đề xuất thứ tự xử lý tiếp theo

1. Viết lại mục 4.1.4, 7.1.1, 7.3, 7.4.1 (ưu tiên cao — mâu thuẫn trực tiếp, dễ bị hỏi khi bảo vệ).
2. Thêm phân hệ Warehouse vào mục 3.1, 3.5, 3.6 (khối lượng nội dung lớn nhất).
3. Cập nhật ERD/Class Diagram mục 4.2/4.5 với các bảng còn thiếu.
4. Bổ sung test case chương 6 cho các module mới.
5. Cập nhật lại hướng phát triển chương 7 cho khớp trạng thái thực tế (PayOS đã xong → chuyển mục khác lên làm ưu tiên mới).

Nói cho mình biết bạn muốn bắt đầu từ mục nào, mình sẽ viết nội dung chi tiết và chèn thẳng vào file docx.
