# Báo cáo đối chiếu Đồ án MediCare với Source Code thực tế

**Phạm vi:** `MediCare (1).docx` (đã chỉnh sửa trực tiếp) đối chiếu với `MediVault/Java/MediVault` (package `com.medicare`, xác nhận qua `PROJECT_TREE.md` cập nhật 2026-08-02) và các script SQL trong `TaiNguyen/`.

**Nguồn chân lý:** source code. Mọi mâu thuẫn được xử lý theo hướng sửa tài liệu cho khớp code, không sửa code cho khớp tài liệu.

---

## 1. Bảng đối chiếu tổng hợp (✓ Existing / ✗ Removed / △ Rewritten / ☆ New)

| Chương | Nội dung cũ | Vấn đề | Xử lý |
|---|---|---|---|
| 1.2 Lý do chọn đề tài | Đoạn giới thiệu xu hướng "Automated Drug Dispensing Machine" làm động lực chọn đề tài | ☆ Tính năng chưa từng được cài đặt (không có Servlet/JSP nào, chỉ còn `MachineCommand` entity/DAO mồ côi, 0 tham chiếu) | ✗ Xóa, thay bằng động lực thật: nhu cầu quản lý nhân sự (chấm công/lương), tự phục vụ khách hàng, thanh toán không tiền mặt |
| 1.3.2 Mục tiêu kỹ thuật | Bullet "Tích hợp module điều khiển máy cấp thuốc tự động" | ✗ Không tồn tại | △ Thay bằng "Face ID + NFC chấm công, PayOS" |
| 1.4 Đối tượng sử dụng | Actor "Máy cấp thuốc tự động (Hardware)" | ✗ Không tồn tại | ✗ Xóa, thay bằng actor **Thủ kho (Warehouse Keeper)** — vai trò roleId=3 có thật trong `AuthFilter.java` |
| 1.5 Phân hệ (5) | "Điều khiển cấp phát thuốc tự động" | ✗ Không tồn tại | △ Thay bằng phân hệ **Cổng thông tin Khách hàng** (`CustomerPortalServlet`, route `/portal`, có thật) |
| 3.1.6 | "Phân hệ Điều khiển máy cấp thuốc tự động" | ✗ Không tồn tại | △ Thay bằng **"Quản lý Ca làm việc, Chấm công & Bảng lương"** — khớp `AttendanceDAO`, `PayrollDAO`, `ShiftAutoCloseService`, `FaceVerifier` |
| 3.1.9 RBAC | "Admin/Manager/Staff" (roleId 1/2/3) | △ Sai tên role | △ Sửa thành **Admin / Nhân viên bán hàng-Dược sĩ / Thủ kho** đúng theo `AuthFilter.isAdminOnly`/`isStorekeeperAllowed` |
| 3.6.3 Actor Manager | "Quản lý (Manager + Inventory)", 4 Use Case gồm cả "Xem báo cáo doanh thu" | ✗ Role "Manager" không tồn tại; báo cáo doanh thu là quyền Admin-only (`/reports` không nằm trong `isStorekeeperAllowed`) | △ Đổi actor thành **Thủ kho**, xóa Use Case "Xem báo cáo doanh thu" (kể cả bullet "Xuất báo cáo Excel/PDF" — thư viện POI/iText không có trong `pom.xml`) |
| 3.6.5 Actor Máy cấp thuốc | 3 Use Case (Nhận lệnh/Thực hiện/Phản hồi) | ✗ Không tồn tại | ✗ Xóa toàn bộ (kể cả 3 hình sơ đồ minh họa), thay bằng actor **Thủ kho** với 3 Use Case thật: Nhập kho (Import Wizard), Tồn kho FEFO, Thu hồi & Nhiệm vụ kho |
| 3.7.2 Use Case Nhập kho | Luồng đơn giản 1 thuốc/1 lô, actor "Manager" | △ Thực tế là **wizard 4 bước, đa dòng, PENDING→COMPLETED, thanh toán CASH/TRANSFER/DEBT** (`PurchaseOrderDAO`, `WarehouseImportServlet`) | △ Viết lại toàn bộ luồng theo đúng code |
| 3.7.5 Use Case | "Máy cấp thuốc tự động" (poll API, motor, retry) | ✗ Không tồn tại | ✗ Xóa, thay bằng Use Case thật **"Chấm công & Tính lương"** (Face ID/NFC/web, `SP_AutoCloseOverdueShifts`) |
| 4.2 Class Diagram | Liệt kê `MachineCommand` trong nhóm Bán hàng | ✗ Entity mồ côi, không dùng | △ Bỏ khỏi danh sách, thêm `PosStation` |
| 4.3.4 Sequence Diagram | "Máy cấp thuốc" | ✗ Không tồn tại | △ Đổi thành **"Nhập kho theo lô (Purchase Order)"** — cần vẽ lại hình minh họa (đã xóa hình cũ vì mô tả sai nghiệp vụ) |
| 4.4.4 Activity Diagram | "Quy trình Máy cấp thuốc tự động" | ✗ Không tồn tại | △ Đổi thành **"Chấm công & Tự động đóng ca"** |
| 4.5.3 ERD | Nhóm "Bán hàng & Máy cấp thuốc", liệt kê bảng `MachineCommands` | ✗ | △ Đổi tên nhóm, thêm `PurchaseOrders`, `PurchaseOrderDetails`, `PosStations` |
| Toàn tài liệu | Thuật ngữ **FIFO** (First-In-First-Out) cho xuất kho | △ Stored Procedure `SP_AddSaleByFIFO` thực chất `ORDER BY ExpiryDate ASC` — đây là **FEFO** (First Expired First Out), tên gọi FIFO trong code chỉ là đặt tên lịch sử | △ Thay toàn bộ mô tả khái niệm sang FEFO; **giữ nguyên** tên định danh code (`SP_AddSaleByFIFO`, `addItemByFIFO`) vì đó là sự thật trong DB |
| Bảng FR (Table 3) | FR26–FR28 (MachineCommand, retry) | ✗ | ✗ Xóa 3 dòng, ☆ thêm 10 FR mới (chấm công, bảng lương, nghỉ phép, portal, PayOS, notification, import wizard, multi-POS/barcode, soft-delete) — đánh số lại FR01–FR43 |
| Bảng NFR (Table 4) | NFR02 "lệnh cấp thuốc trong 5 giây" | ✗ | ✗ Xóa, ☆ thêm NFR về cache Caffeine và CSRF — đánh số lại NFR01–NFR16 |
| Bảng 5 (thiết bị) | Dòng "Máy cấp thuốc tự động" (Wi-Fi/Ethernet, REST API) | ✗ | ✗ Xóa dòng |
| Bảng 7 (FR-03) | "Điều khiển máy cấp thuốc" | ✗ | △ Đổi thành "Chấm công, Ca làm việc & Bảng lương" |
| Bảng 8 (Actor) | Dòng "Máy cấp thuốc (Machine)"; "Quản lý (Manager)" | ✗ / △ | ✗ Xóa dòng Machine; △ đổi Manager → **Thủ kho** |
| Bảng 13 | Use Case Summary "Máy cấp thuốc tự động" (3 dòng) | ✗ | ✗ Xóa cả bảng |
| Bảng 20 (Test Module 6) | 6 test case TC039–044 cho máy cấp thuốc | ✗ | ✗ Xóa cả bảng + heading "6.2.6"; **đánh số lại toàn bộ TC039→TC140** xuyên suốt các bảng còn lại (108 → **102 test case**) |
| Bảng Module list (test plan) | Thiếu Module 7 (AuthFilter) và Module 9–12 (vốn đã có heading riêng nhưng quên liệt kê) | △ Bất nhất nội bộ *có sẵn từ bản gốc*, không liên quan máy cấp thuốc | △ Bổ sung đủ 11 module, đánh số lại |
| Bảng tổng hợp (Table 26) | Dòng "Máy cấp thuốc" 6TC; Tổng 108 | ✗ | ✗ Xóa dòng; tổng còn **102/102 Pass (100%)** |
| 4.1.4 Hạn chế | "Chưa có cache layer" | ✗ Sai — `CacheManager` (Caffeine, 4 tầng TTL) đã tồn tại | △ Sửa lại đúng thực trạng |
| 7.2 Điểm mạnh | "Tích hợp máy cấp thuốc tự động" là điểm khác biệt | ✗ | △ Thay bằng Face ID + NFC chấm công, PayOS |
| 7.3 Hạn chế | "Chưa có thông báo push khi máy cấp thuốc FAILED" | ✗ | ✗ Xóa hẳn (đã có SSE Notification Center thật) |
| 7.4 Hướng phát triển | "WebSocket khi máy cấp thuốc FAILED" | ✗ | △ Thay bằng "thay polling/SSE bằng WebSocket toàn hệ thống" |
| 7.5 Lời kết | Nhắc "module điều khiển máy cấp thuốc tự động" | ✗ | △ Thay bằng Face ID/NFC, Portal, PayOS |
| Thông tin nhóm (Table 0) | Vai trò 4 thành viên theo bản mô tả cũ | △ | △ Viết lại đúng theo yêu cầu: Khoa (PM, kiến trúc, Admin+Staff bán thuốc), Hậu (POS/Sales/Invoice), Khánh (Customer Portal/Auth), Thông (Warehouse/Batch/FEFO/Import/Barcode) |

---

## 2. Danh sách nội dung đã XÓA

- Toàn bộ nội dung, 2 Use Case, 1 bảng tóm tắt (Table 13), 1 bảng test case (Table 20, TC039–044), 1 heading test-module (6.2.6) và **3 hình sơ đồ** liên quan tới "máy cấp thuốc tự động / Automated Drug Dispensing Machine / MachineCommand" — tính năng chưa từng được lập trình (xác nhận 0 Servlet, 0 JSP, 0 route tham chiếu `MachineCommand` ngoài entity/DAO mồ côi).
- Use Case con "Xem báo cáo doanh thu" + bullet "Xuất báo cáo Excel/PDF" khỏi actor Thủ kho (quyền thực tế thuộc Admin; tính năng export Excel/PDF chưa có thư viện nào trong `pom.xml`).
- Giới hạn "chưa có thông báo push khi máy cấp thuốc FAILED" (đã lỗi thời kép: vừa nhắc tính năng không tồn tại, vừa sai vì Notification Center SSE đã có thật).
- Giới hạn "chưa có cache layer" (sai, `CacheManager` Caffeine đã triển khai).

## 3. Danh sách nội dung MỚI được bổ sung

- Phân hệ **3.1.10 Cổng thông tin Khách hàng**, **3.1.11 Thanh toán trực tuyến PayOS**, **3.1.12 Trung tâm Thông báo & Kiểm toán** (khớp `CustomerPortalServlet`, `PayOSService`, `NotificationUtil`, `StaffAuditLogDAO`).
- Actor **Thủ kho (Warehouse Keeper)** với 3 Use Case thật (Import Wizard, tồn kho FEFO, thu hồi/SOP).
- 10 yêu cầu chức năng mới (FR34–FR43) và 1 yêu cầu phi chức năng (NFR16 — chống CSRF).
- 5 module kiểm thử bổ sung vào bảng kế hoạch test (AuthFilter, Dashboard, Shift Schedule, Attendance, Leave Request, Payroll) để khớp với các bảng test case đã có sẵn nhưng chưa được liệt kê.

## 4. Danh sách các mục đã VIẾT LẠI hoàn toàn

- 1.2 Lý do chọn đề tài, 1.3.2 Mục tiêu kỹ thuật, 1.4 Đối tượng sử dụng, 1.5 Phân hệ (5), 3.1.6, 3.1.9 (RBAC), 3.6.3, 3.6.5, 3.7.2, 3.7.5, 4.3.4, 4.4.4, 4.5.3, Bảng thành viên nhóm, toàn bộ đoạn văn có thuật ngữ FIFO→FEFO, mọi câu nhắc "Manager" (đổi thành Thủ kho/Admin/Dược sĩ tùy ngữ cảnh), 7.1.1/7.2/7.3/7.4/7.5, và phần tổng kết kiểm thử 6.3 (108→102 test case, 12→11 module).

## 5. Giới hạn của lần chỉnh sửa này (cần xử lý thủ công)

- **Sơ đồ (Use Case/Sequence/Activity/ERD)**: nội dung *text* mô tả đã cập nhật đúng, nhưng các **hình ảnh .drawio/.png cũ** (Use Case máy cấp thuốc) chỉ được xóa, chưa vẽ lại hình mới cho "Nhập kho theo lô" và "Chấm công". Cần vẽ lại 2 sequence/activity diagram này trong draw.io.
- **Chương 5 (Giao diện phần mềm)**: ảnh chụp màn hình hiện tại (Admin/Staff) nhiều khả năng đã lỗi thời so với UI thật (Warehouse Portal, Customer Portal, trang Attendance/Payroll hoàn toàn chưa có ảnh minh họa). Cần chụp lại màn hình mới.
- Số liệu "~25 lớp Entity" / "25+ bảng" (mục 4.2, 4.5) là ước lượng cũ, thực tế có ~32 entity — vẫn đúng về mặt "25+" nên không sửa, nhưng có thể cập nhật cho chính xác hơn nếu muốn.
- 2 hình ảnh ở cuối mục 3.7 (ngay trước "THIẾT KẾ KIẾN TRÚC") chưa xác định rõ nội dung (không có alt-text); nếu là sơ đồ liên quan máy cấp thuốc, cần xóa thủ công.

## 6. Xác minh tính toàn vẹn file

- File `MediCare (1).docx` được sửa **trực tiếp tại chỗ** (không tạo file mới), backup gốc lưu tại `MediCare_BACKUP_original.docx` trong thư mục làm việc tạm.
- Convert thử bằng LibreOffice → PDF thành công, không lỗi, **101 trang** (gần với ước lượng ~100 trang ban đầu của bạn).
- Số bảng: 28 → 26 (xóa 2 bảng liên quan máy cấp thuốc). Số ảnh: 77 → 72 (xóa 5 ảnh minh họa cho nội dung không có thật). Không phát hiện tham chiếu "máy cấp thuốc"/"MachineCommand"/"FIFO" (khái niệm) còn sót.

---

# ĐỢT RÀ SOÁT 2 (2026-08-03)

**Phạm vi:** đọc lại toàn bộ `MediCare (1).docx` (convert bằng pandoc, 1821 dòng markdown) đối chiếu trực tiếp với source code hiện tại trong `MediVault/Java/MediVault` (đọc `PROJECT_TREE.md`, `pom.xml`, toàn bộ `entity/`, `dao/`, `controller/`, `service/`, `util/`, các file `.sql` trong `database/`). Mục tiêu: kiểm tra xem đợt sửa 2026-08-02 đã khớp hoàn toàn với code chưa, và code có thay đổi gì thêm từ đó đến nay không.

**Kết luận chung:** đợt sửa 1 đã xử lý đúng phần lớn các mục lớn (xóa máy cấp thuốc tự động khỏi Use Case/Actor/FR/NFR/Test, đổi Manager→Thủ kho, thêm 3 phân hệ mới). Tuy nhiên phát hiện **7 vấn đề còn sót lại hoặc phát sinh mới**, chủ yếu do sửa cục bộ (tìm-thay theo đoạn) chứ chưa rà soát xuyên suốt toàn tài liệu — đặc biệt là **chương 4 (Class Diagram/ERD) chưa được cập nhật đồng bộ** với các phân hệ mới đã thêm ở chương 1–3.

## 7. Danh sách vấn đề phát hiện ở đợt rà soát 2

| # | Vị trí | Nội dung sai / còn sót | Bằng chứng từ code | Đề xuất sửa |
|---|---|---|---|---|
| 1 | 1.4 Phạm vi áp dụng (đoạn "Phạm vi áp dụng") | "...có nhu cầu chuyển đổi số toàn diện và **muốn áp dụng công nghệ cấp thuốc tự động trong tương lai**" | Không có bất kỳ Servlet/JSP nào xử lý cấp phát tự động; chỉ còn `MachineCommand` entity/DAO mồ côi (0 tham chiếu ngoài chính nó) | Xóa vế "muốn áp dụng công nghệ cấp thuốc tự động trong tương lai" — nếu muốn giữ định hướng mở rộng, chuyển xuống mục 7.4 (Hướng phát triển) |
| 2 | 1.4 Đối tượng sử dụng (Actors) | Actor **"Thủ kho (Warehouse Keeper)" bị liệt kê 2 lần liên tiếp** với 2 mô tả khác nhau (dòng đầu mô tả ngắn, dòng cuối mô tả đầy đủ hơn — rõ ràng là phần thay thế actor "Máy cấp thuốc tự động" cũ nhưng quên xóa dòng Thủ kho gốc) | — (lỗi soạn thảo nội bộ tài liệu) | Gộp 2 dòng thành 1 mô tả Thủ kho duy nhất, đầy đủ nhất |
| 3 | "Chức năng nghiên cứu và phát triển" (đoạn mở đầu 12 phân hệ) | "...đảm bảo quy trình vận hành khép kín từ quản trị, nhập kho cho đến bán hàng và **điều khiển phần cứng**" | Không có phân hệ điều khiển phần cứng nào trong 12 phân hệ liệt kê ngay sau đó (đã đối chiếu — không phân hệ nào nói về hardware) | Sửa thành "...từ quản trị, nhập kho, bán hàng cho đến quản lý nhân sự và chăm sóc khách hàng" |
| 4 | Mục (1) Quản trị danh mục dược phẩm | "...định vị tọa độ vật lý trên hệ thống kệ và ngăn của **máy cấp phát tự động** (ShelfID + MachineSlotCode)" | `MachineSlotCode` **có thật** trong `Shelf` entity/`ShelfDAO`/`shelf-form.jsp` — nhưng chỉ là 1 trường metadata đánh dấu "ngăn kệ có hỗ trợ tự động hóa" (cột tính toán `IsAutomated`), **không có bất kỳ code nào thực sự điều khiển motor/cấp phát** (không Servlet, không job xử lý `MachineCommand`) | Sửa thành: "...định vị vị trí vật lý trên kệ (ShelfID), có hỗ trợ đánh dấu ngăn dự phòng cho khả năng tự động hóa trong tương lai (MachineSlotCode) — chưa triển khai phần điều khiển thực tế" — tránh gây hiểu nhầm là tính năng đã hoàn thiện |
| 5 | Mục 4.4.1 "Quy trình Bán thuốc tại POS" | "...tính tiền → tạo hóa đơn FEFO → **cấp thuốc tự động** → in hóa đơn" | `complete()`/`addItemByFIFO()` trong `InvoiceDAO` không có bước cấp thuốc tự động; luồng thật (đã mô tả đúng ở 3.7.1) là createPending→addItemByFIFO×N→complete→in hóa đơn | Xóa bước "cấp thuốc tự động" khỏi mô tả Activity Diagram, khớp với luồng đã sửa đúng ở 3.7.1 |
| 6 | **Toàn tài liệu — 7 vị trí**: FR18, FR21 (bảng FR), đoạn 3.1.3, đoạn 3.1.4, bước 9 mục 3.7.1, đoạn 4.1.2 (Tầng 3), đoạn 7.1.1 | Tất cả đều ghi **`SP_AddSaleByFIFO`** | Tên Stored Procedure thật trong code hiện tại là **`SP_AddSaleByFEFO`** (`InvoiceDAO.java` dòng 80, 270: `{CALL SP_AddSaleByFEFO(?, ?, ?)}`; comment dòng 17, 75 cũng ghi rõ FEFO). Đây khác với kết luận của đợt rà soát 1 (khi đó cho rằng SP tên là FIFO trong DB nên giữ nguyên) — **code hiện tại đã dùng đúng tên FEFO cho Stored Procedure**, chỉ riêng **tên method Java `addItemByFIFO()`** là còn giữ tên lịch sử "FIFO" (method name — nên giữ nguyên vì đó là định danh code thật) | Đổi toàn bộ 7 chỗ nhắc **tên Stored Procedure** trong docx từ `SP_AddSaleByFIFO` → `SP_AddSaleByFEFO`. Giữ nguyên tên method `addItemByFIFO()` vì đó là định danh code thật |
| 7 | FR16, FR17, FR30, đoạn 3.1.4, đoạn 3.1.8 (liệt kê 6 view), đoạn 4.1.2 (Tầng 3 — "SP_CheckExpiringBatches"), đoạn 4.5.2 | Tài liệu mô tả hệ thống dùng các **View SQL Server**: `V_ExpiringBatches`, `V_MedicineStock`, `V_DailySales`, `V_MonthlySales`, `V_TopSellingMedicines`, `V_StaffPerformance`, và Stored Procedure `SP_CheckExpiringBatches` | Grep toàn bộ `src/main/java` và toàn bộ file `.sql` trong `database/`: **không có bất kỳ dòng code nào** `SELECT ... FROM V_ExpiringBatches` / `V_MedicineStock` / `V_DailySales` / `V_MonthlySales` / `V_TopSellingMedicines` / `V_StaffPerformance`, và không có `SP_CheckExpiringBatches`. Thực tế: `BatchesDAO.findExpiringSoon()`/`findExpired()` dùng SQL thô (`SELECT * FROM Batches WHERE ExpiryDate <= DATEADD(day,30,GETDATE())...`); `DashboardServlet` tự `GROUP BY`/`SUM()` trực tiếp trên `Invoices`/`InvoiceDetails`. Hai view **thật** có dùng trong code nhưng **không được nhắc trong docx** là `V_GraceWindowShifts` và `V_CurrentlyWorking` (thuộc module chấm công) | Viết lại các đoạn này theo đúng cách hệ thống thật đang làm: cảnh báo/tồn kho/doanh thu tính bằng SQL trực tiếp trong DAO/Servlet (không qua view riêng), chỉ module chấm công có 2 view `V_GraceWindowShifts`/`V_CurrentlyWorking`. Nếu các view kia thực sự tồn tại sẵn trong SQL Server (tạo tay ngoài repo, không có script), cần nhóm xác minh trực tiếp trong DB — nếu không dùng thì nên xóa khỏi tài liệu để tránh mô tả sai kiến trúc |
| 8 | Đoạn 6.1.3 "Unit Testing" | "...Dùng **JUnit 5** để viết và chạy test cases" — trình bày như phương pháp kiểm thử **đang áp dụng** | `pom.xml` **không có** dependency JUnit/Mockito nào; repo **không có** thư mục `src/test`; toàn bộ 102 test case ở mục 6.2 là **test thủ công có ghi nhận kết quả** (Black-box/White-box), không phải test tự động | Sửa đoạn 6.1.3: bỏ câu "Dùng JUnit 5 để viết và chạy test cases" khỏi phần mô tả phương pháp hiện tại (JUnit 5 + Mockito đã được liệt kê đúng chỗ ở mục 7.4.1 "Hướng phát triển ngắn hạn" — giữ nguyên ở đó) |
| 9 | Mục 2.1 (đoạn mở đầu bảng yêu cầu) và mục 7.1.2 | Câu mở đầu ghi **"30 yêu cầu chức năng...15 yêu cầu phi chức năng"** (mục 2.1); mục 7.1.2 lại ghi **"36 FR và 15 NFR"** | Bảng FR thật đánh số **FR01→FR43 = 43 FR**; bảng NFR thật đánh số **NFR01→NFR16 = 16 NFR** (đã tự đối chiếu đếm dòng bảng) | Sửa thống nhất cả 2 chỗ thành **"43 yêu cầu chức năng và 16 yêu cầu phi chức năng"** |
| 10 | Mục 4.2 Class Diagram — liệt kê nhóm Entity | Chỉ liệt kê 4 nhóm ~20 Entity (Tài khoản & Hệ thống: Account/Role/Shift/AuditLog; Kho & Dược phẩm; Bán hàng; Khách hàng & Loyalty) và ghi "khoảng 25 lớp Entity chính" | Code thực tế có **34 lớp Entity** (`ls entity/*.java` = 34), trong đó **toàn bộ nhóm Nhân sự & Chấm công đã thêm ở mục 3.1.6/FR34-37** (`Attendance`, `ShiftSchedule`, `ShiftType`, `Payroll`, `LeaveRequest`, `StaffAuditLog`) và `Task`, `MedicineBarcode`, `PasswordResetRequest`, `PurchaseOrderDetail` **không hề xuất hiện** trong danh sách nhóm ở mục 4.2 — tức là mục 4.2 vẫn đang mô tả class diagram của bản cũ, chưa cập nhật theo các phân hệ mới đã thêm ở chương 1–3 | Thêm nhóm thứ 5 **"Nhân sự & Chấm công: Attendance, ShiftSchedule, ShiftType, Payroll, LeaveRequest, StaffAuditLog"**; bổ sung `Task` vào nhóm Kho, `MedicineBarcode`/`PurchaseOrderDetail` vào nhóm Kho/Bán hàng; sửa số liệu "khoảng 25" → "34 lớp Entity" |
| 11 | Mục 4.5 ERD — 4 nhóm bảng (4.5.1–4.5.4) | Tương tự mục 10 — hoàn toàn không nhắc `Attendance`, `Shifts`(cơ bản có ở 4.5.1 nhưng thiếu `ShiftSchedules`, `ShiftTypes`), `Payroll`, `LeaveRequests`, `StaffAuditLog`, `Tasks`, `MedicineBarcodes`, `PasswordResetRequests` dù các bảng này chắc chắn tồn tại (có DAO/Servlet/JSP đầy đủ) | Cùng bằng chứng entity/DAO như mục 10 | Thêm nhóm **"4.5.5 Nhân sự & Chấm công"**: `Shifts, ShiftSchedules, ShiftTypes, Attendances, Payrolls, LeaveRequests, StaffAuditLogs` — khớp đúng với phân hệ 3.1.6 đã mô tả chi tiết |

## 8. Vấn đề đã kiểm tra và xác nhận ĐÚNG (không cần sửa)

Để tránh nghi ngờ oan, các claim sau đã được đối chiếu trực tiếp với code và **khớp chính xác**:

- `createPending()` / `addItemByFIFO()` / `complete()` / `cancel()` — đúng 4 method trong `InvoiceDAO.java`.
- `SP_AutoCloseOverdueShifts`, quy tắc "quá PlannedEnd + 20 phút" — khớp comment/code trong `ShiftAutoCloseService.java`.
- Grace period 5 phút, `LateToleranceMinutes` — khớp `StaffAttendanceServlet.java`/`ShiftScheduleDAO.java`.
- NFC toggle check-in/check-out (`CHECK_IN`/`CHECK_OUT`) — khớp `NfcAttendanceServlet.java`.
- PayOS ký HMAC-SHA256 — khớp `PayOSService.java`.
- Route `/portal` → `CustomerPortalServlet` — khớp `@WebServlet("/portal")`.
- Admin IP whitelist riêng (`ADMIN_IP_WHITELIST`) — có thật trong `AuthFilter.java`.
- CSRF token cho POST/AJAX — `CsrfUtil`/`csrf.js` được dùng ở 79 file, đúng diện rộng như NFR16 mô tả.
- pom.xml không có Apache POI/iText — khớp với việc tài liệu nói "báo cáo chưa hỗ trợ export Excel/PDF" (mục 7.3) và liệt kê export Excel/PDF là hướng phát triển (mục 7.4.1).
- `CacheManager` Caffeine 4 tầng (30s/3min/5min/15min) — khớp mục 4.1.4 và NFR02 **nhưng lưu ý mục 7.3 "Hạn chế hiện tại" vẫn còn câu "Chưa có cache layer (Redis/Memcached)"** — đây là **mâu thuẫn nội bộ giữa 2 mục trong cùng tài liệu** (4.1.4 nói đã có cache Caffeine, 7.3 nói chưa có cache) → cần sửa 7.3 cho khớp 4.1.4: đổi thành "Cache mới dừng ở Caffeine in-memory (single-node), chưa có giải pháp cache phân tán (Redis) cho kịch bản nhiều server".

## 9. Đã áp dụng vào file (2026-08-03)

Toàn bộ 12 mục ở phần 7 (10 dòng bảng + mục 6 SP name + mục 8/mâu thuẫn cache trong phần 8) đã được sửa **trực tiếp vào `MediCare (1).docx`** bằng cách sửa XML (`word/document.xml`), không tạo file mới:

- Xóa/sửa 4 chỗ còn sót "máy cấp thuốc tự động"/"điều khiển phần cứng"/"máy cấp phát tự động" (mục 1, 3, 4, 5 ở bảng phần 7).
- Gộp 2 bullet actor "Thủ kho" trùng lặp thành 1 bullet đầy đủ (mục 2).
- Đổi toàn bộ 7 chỗ `SP_AddSaleByFIFO` → `SP_AddSaleByFEFO` (mục 6).
- Viết lại các đoạn nhắc 6 view không tồn tại (`V_ExpiringBatches`, `V_MedicineStock`, `V_DailySales`, `V_MonthlySales`, `V_TopSellingMedicines`, `V_StaffPerformance`) và `SP_CheckExpiringBatches` thành mô tả đúng cách hệ thống thật đang làm (SQL trực tiếp trong DAO/Servlet; nhắc đúng 2 view thật `V_GraceWindowShifts`/`V_CurrentlyWorking`) — 6 vị trí (FR16, FR17, FR30, đoạn 3.1.4, đoạn 3.1.8, đoạn 4.1.2) (mục 7).
- Sửa đoạn 6.1.3: bỏ câu khẳng định "đang dùng JUnit 5" khỏi phương pháp hiện tại, làm rõ 102 test case ở mục 6.2 là test thủ công; JUnit 5 + Mockito vẫn giữ đúng chỗ ở mục 7.4.1 (mục 8).
- Thống nhất số liệu **43 FR / 16 NFR** ở cả mục 2.1 và mục 7.1.2 (mục 9).
- Mục 4.2 Class Diagram: sửa "khoảng 25" → "34 lớp Entity", "4 nhóm" → "5 nhóm", bổ sung nhóm mới **Nhân sự & Chấm công** (Attendance, ShiftSchedule, ShiftType, Payroll, LeaveRequest, StaffAuditLog) và bổ sung entity còn thiếu (StaffAuditLog, PasswordResetRequest, PurchaseOrderDetail, MedicineBarcode, Task) vào 2 nhóm sẵn có (mục 10).
- Mục 4.5 ERD: thêm mục **4.5.5 Nhóm Nhân sự & Chấm công** (Shifts, ShiftSchedules, ShiftTypes, Attendances, Payrolls, LeaveRequests, StaffAuditLogs) và bổ sung bảng còn thiếu vào 4.5.2 (mục 11).
- Sửa mục 7.3: "Chưa có cache layer" → làm rõ đã có Caffeine in-memory, chỉ còn thiếu cache phân tán (Redis) — hết mâu thuẫn với mục 4.1.4 (phần 8).

**Xác minh:**
- `validate.py --original` (so với file gốc vừa upload): **PASSED**, số đoạn văn 2808 → 2810 (khớp đúng: −1 bullet trùng bị xóa, +1 bullet Entity mới, +2 đoạn heading/nội dung 4.5.5).
- Convert LibreOffice → PDF thành công, không lỗi, **103 trang**.
- Grep xác nhận: không còn `SP_AddSaleByFIFO`, không còn 6 view ảo, không còn "điều khiển phần cứng"/"máy cấp phát tự động"/actor Thủ kho trùng lặp. 2 chỗ còn lại chứa cụm "cấp thuốc tự động" là nội dung lịch sử hợp lệ (câu hỏi khảo sát gốc, và câu xác nhận đã loại bỏ tính năng này khỏi test) — không phải lỗi.
- File đã ghi đè tại `MediCare (1).docx` và `MediCare (1).pdf` trong `DOC_BAOCAO` (backup bản trước khi sửa đợt này nằm ở `MediCare_source.docx` trong thư mục làm việc tạm).

---

# ĐỢT RÀ SOÁT 3 (2026-08-03, buổi tối)

**Bối cảnh:** bạn tự cross-check thêm 1 vòng (đối chiếu `pom.xml`, `.idea`, cấu hình Tomcat, git) và gửi lại danh sách phát hiện; mình xác minh lại bằng code + đọc kỹ thêm `PosServlet.java`/`InvoiceDAO.java`/`SaleService.java`/`LoyaltyDAO.java`/`ShiftDAO.java`/`Account.java`/`CategoryDAO.java`, và chạy `git branch -a` trực tiếp trên repo.

## 10. Xác nhận đúng các phát hiện bạn gửi (đã sửa vào docx)

| # | Sai / lệch | Bằng chứng | Đã sửa |
|---|---|---|---|
| 1 | Servlet API ghi "5.0" | `pom.xml`: `jakarta.servlet-api` **6.0.0**; `.idea`/SmartTomcat chạy Tomcat **10.1.54** (Tomcat 10.1.x = Servlet 6.0, còn 5.0 phải là Tomcat 10.0.x) | Đổi cả 2 chỗ ("Java 17 ... Servlet API 5.0" và "Tomcat 10.x ... Servlet 5.0") → **Servlet API 6.0**, ghi chú thêm "thực tế đang chạy 10.1.54" ở dòng Tomcat |
| 2 | "salt rounds = 12" | `PasswordUtil.java`: `BCrypt.hashpw(plainPassword, BCrypt.gensalt(10))` — **10 rounds**, không phải 12 | Sửa cả 3 chỗ (bảng công nghệ, NFR05, mục 7.1.1) → **salt rounds = 10** |
| 3 | "branch riêng (feature/xxx)" | `git branch -a`: các branch thật là `Khoa`, `Thong`, `Khanh`, `Hau_TY00340`, `main`, `test` — không theo quy ước `feature/xxx` | Sửa thành "branch riêng theo tên (Khoa, Thong, Khanh, Hau_TY00340)" |
| 4 | Java 17 | Theo yêu cầu của bạn (đổi hẳn Java 26, tự cập nhật `pom.xml` sau) | Đổi "Java 17 (JDK 17)" → **"Java 26 (Java SE Development Kit 26)"** — lưu ý: `pom.xml` hiện tại (`maven.compiler.source/target=17`) **chưa khớp**, cần bạn tự đổi trong code khi rảnh |

## 11. Phát hiện MỚI từ đợt rà soát 3 — sai kiến trúc quan trọng nhất từ đầu đến giờ

Khi đọc kỹ `PosServlet.java` để kiểm tra claim "POST /pos?action=create-pending → add-item → complete" (FR-02, bảng chi tiết bạn dán), phát hiện **toàn bộ luồng checkout POS trong tài liệu mô tả sai kiến trúc thật**:

- Grep toàn bộ `PosServlet.java` cho các action `create-pending`/`add-item`/`complete`: **0 kết quả**. Action thật xử lý thanh toán là **`complete-sale`** (1 request duy nhất, xác nhận tại `pos.jsp` dòng `fd.append('action', 'complete-sale')`).
- `PosServlet` → `SaleService.completeSale()` → `InvoiceDAO.completeSaleTransaction()` — đây là **1 giao dịch JDBC nguyên tử duy nhất** (`cn.setAutoCommit(false)` ... `cn.commit()` / `cn.rollback()` trong catch), thực hiện tuần tự trong cùng 1 connection: insert Invoice PENDING → vòng lặp gọi `SP_AddSaleByFEFO` cho từng dòng → tính lại subtotal/discount qua `PricingUtil.settle()` → UPDATE COMPLETED → commit.
- 3 method riêng lẻ `createPending()`, `addItemByFIFO()`, `complete()`, `cancel()` **vẫn tồn tại thật trong `InvoiceDAO.java`/`IInvoiceDAO.java`** nhưng **không còn được gọi ở bất kỳ đâu** trong luồng POS đang chạy (grep toàn bộ `src/main/java` không tìm thấy caller nào) — tức là **code mồ côi (dead code)**, có thể là pattern cũ trước khi refactor sang `completeSaleTransaction()`.
- Vì vậy rollback thật sự là JDBC `cn.rollback()` tự động trong khối catch, **không phải** gọi hàm `cancel(invoiceId)` riêng như tài liệu mô tả.

**Đã sửa 15 vị trí trong docx** để khớp đúng luồng `completeSaleTransaction()` một-giao-dịch: FR20, FR24 (cả cột Mô tả và Ghi chú), FR-02 (bảng yêu cầu chi tiết 3.2), đoạn 3.1.3 (mô tả phân hệ POS), Use Case 2 của Staff (2 bullet: "FEFO Stock Allocation" và "Lập hóa đơn PENDING"), 3.7.1 bước 8, luồng ngoại lệ E2 (cả heading và nội dung), mục 4.1.2 Tầng 2 (Service classes), Sequence Diagram 4.3.3 (bước 2, nhánh [success], nhánh [fail]), mục 6.1.3 White-box Testing, TC073 (cả input và kết quả mong đợi), mục 7.2 Điểm mạnh.

**Đã kiểm tra và xác nhận ĐÚNG (không sửa)** — các claim khác trong 2 bảng bạn dán:
- FR08 (chứng chỉ hành nghề/hạn/training) — khớp `Account.java` (`professionalCertNo`, `professionalCertExp`, `trainingDate`).
- FR11 (xóa Category kiểm tra FK) — khớp `CategoryDAO.delete()`/`CategoryServlet`.
- FR22 (discount, FinalAmount = SubTotal − DiscountAmount, kẹp về [0, subtotal]) — khớp `InvoiceDAO`/`PricingUtil.settle()`.
- FR23 (CASH/CARD/TRANSFER/EWALLET) — khớp field `paymentMethod` trong `Invoice.java` (comment liệt kê đúng 4 giá trị, có thêm `QR_CODE` không nhắc trong doc nhưng không sai — chỉ là chưa đủ, có thể bổ sung sau nếu muốn).
- FR27/FR28 (Loyalty tier tự nâng hạng theo MinPoints) — khớp `LoyaltyDAO` (`TierID = hạng cao nhất có MinPoints <= TotalPoints`).
- FR32/FR-04 (OpeningCash/ClosingCash) — khớp `ShiftDAO`.
- FR43 (soft delete) — khớp `AccountDAO`/`PROJECT_TREE.md`.
- FR-05 (bảng chi tiết): phát hiện thêm — câu "**Manager** có thể filter chi tiết..." còn sót thuật ngữ role không tồn tại (đã sửa thành **Admin**, vì Dashboard/Report là quyền Admin-only theo `AuthFilter`).

## 12. Còn tồn — cần bạn xử lý thủ công (không sửa được từ phía tài liệu)

- **`pom.xml` vẫn ghi `maven.compiler.source/target=17`**, chưa khớp với "Java 26" vừa sửa trong docx theo yêu cầu của bạn — nếu môi trường thật đã chuyển hẳn sang JDK 26, nên cập nhật `pom.xml` để tài liệu và code đồng bộ.
- **draw.io / View SQL Server**: không xác nhận được từ repo (không có file `.drawio`, không có `CREATE VIEW` trong migration scripts) — không sai nhưng không có bằng chứng, tùy bạn giữ nguyên mô tả hay ghi chú "thiết kế ngoài repo".
- **PaymentMethod có thêm `QR_CODE`** ngoài 4 giá trị tài liệu liệt kê (CASH/CARD/TRANSFER/EWALLET) — có thể bổ sung nếu muốn mô tả đầy đủ hơn, không bắt buộc.

## 13. Xác minh

- `validate.py --original` (so với bản trước round 3): **PASSED**, số đoạn văn 2814 → 2814 (không đổi — round này chỉ sửa nội dung text trong các đoạn/ô bảng có sẵn, không thêm/xóa đoạn).
- Convert LibreOffice → PDF thành công, không lỗi, **105 trang**.
- Grep xác nhận sạch hoàn toàn: 0 occurrence còn lại của `createPending`, `addItemByFIFO`, `cancel(invoiceId)`, `create-pending`, `add-item`, `salt rounds = 12`, `Servlet API 5.0`, `Servlet 5.0`, `feature/xxx`, `Java 17`.
- File đã ghi đè tại `MediCare (1).docx` và `MediCare (1).pdf` trong `DOC_BAOCAO`.

## 14. Mở rộng mục 6 "KIỂM THỬ PHẦN MỀM" (2026-08-03)

**Yêu cầu:** rà soát toàn diện mục 6, khai báo trung thực nếu còn thiếu chức năng chưa có test case (không cố tô hồng thành "100% coverage"), rồi bổ sung đầy đủ test case cho các chức năng thật trong code.

### 14.1. Phát hiện: 14 phân hệ có thật trong code nhưng CHƯA có test case nào

Trước đợt này, mục 6.2 chỉ có 11 module (102 test case), toàn bộ tập trung vào nhóm Bán hàng/Đăng nhập/Nhân sự. Đối chiếu với code thực tế, các phân hệ sau **hoàn toàn chưa được kiểm thử trong tài liệu** dù đã triển khai đầy đủ:

| # | Module còn thiếu | Nguồn code xác nhận |
|---|---|---|
| 12 | Quản lý Thuốc & Lô hàng | `MedicineServlet`, `BatchesDAO` |
| 13 | Nhà cung cấp / Nhà sản xuất / Kệ thuốc | `SupplierServlet`, `ShelfServlet` |
| 14 | Nhập kho theo lô — Purchase Order & Import Wizard | `PurchaseOrderServlet`, `WarehouseImportServlet` |
| 15 | Quản lý đổi trả (Returns) | `ReturnsServlet` |
| 16 | Khách hàng & Chương trình Loyalty | `CustomerServlet`, `LoyaltyDAO` |
| 17 | Cổng thông tin Khách hàng (Customer Portal) | `CustomerPortalServlet` |
| 18 | Thanh toán trực tuyến PayOS | `PayOSService` (HMAC-SHA256 webhook) |
| 19 | Warehouse Portal (tồn kho, gợi ý đặt hàng, thu hồi, nhiệm vụ) | `WarehouseReorderServlet`, `WarehouseRecallServlet`, `WarehouseTaskServlet` |
| 20 | Bán hàng đa quầy & Barcode (Multi-POS) | `PosStationDAO`, `PosServlet` |
| 21 | Trung tâm Thông báo | `StaffNotificationServlet` |
| 22 | Nhật ký kiểm toán (Audit Log) | `AuditLogServlet` |
| 23 | Đăng ký / Định danh khuôn mặt | `FaceEnrollServlet`, `FaceVerifier` |
| 24 | Quên mật khẩu / Đặt lại mật khẩu | `ForgotPasswordServlet` |
| 25 | Chống giả mạo yêu cầu (CSRF) | `CsrfUtil` |

→ Viết mới **81 test case** (TC141–TC221) cho 14 module trên, dựa trên đọc trực tiếp logic từng Servlet/DAO (không suy đoán).

### 14.2. Lỗi đánh số nội bộ đã sửa (tồn tại từ trước, không liên quan đợt bổ sung này)

Bảng tổng hợp 6.3 gọi sai số thứ tự 4 module cuối so với chính heading của chúng ở mục 6.2:

| Heading 6.2.x (đúng) | Bảng 6.3 (sai, đã sửa) |
|---|---|
| 6.2.8. Shift Schedule | ghi "(Module 9)" → sửa thành "(Module 8)" |
| 6.2.9. Attendance | ghi "(Module 10)" → sửa thành "(Module 9)" |
| 6.2.10. Leave Request | ghi "(Module 11)" → sửa thành "(Module 10)" |
| 6.2.11. Payroll & Penalty | ghi "(Module 12)" → sửa thành "(Module 11)" |

### 14.3. Mục "6.4. Hạn chế phạm vi kiểm thử" — bổ sung mới, khai báo trung thực

Theo đúng yêu cầu "thiếu thì cứ ghi thiếu không phải 100%", đã thêm mục 6.4 liệt kê rõ 8 hạng mục **chưa** nằm trong phạm vi kiểm thử: kiểm thử tự động/CI (toàn bộ 183 TC là thủ công), kiểm thử hiệu năng/tải, kiểm thử bảo mật chuyên sâu (pentest), kiểm thử đồng thời/race condition, các công cụ nội bộ dev không tính là tính năng người dùng cuối, kiểm thử thiết bị phần cứng thật, ma trận đa trình duyệt/thiết bị đầy đủ, và PayOS chỉ kiểm thử ở mức đọc code chứ chưa gọi API/webhook thật.

### 14.4. Kết quả sau khi bổ sung

- Mục 6.1.2 (phạm vi kiểm thử): 11 → **25 module**.
- Mục 6.2: 11 → **25 module** con, mỗi module có bảng test case đầy đủ.
- Mục 6.3 (tổng hợp): 102 → **183 test case**, tất cả Pass (100%) — cộng dồn đúng: 102 (cũ) + 81 (mới) = 183.
- Thêm mục 6.4 công khai giới hạn phạm vi kiểm thử.

### 14.5. Xác minh kỹ thuật

- Chèn XML bằng phương pháp nhân bản 1 dòng bảng/heading thật đã có sẵn (giữ nguyên toàn bộ định dạng, border, style), thay nội dung `<w:t>` theo đúng vị trí thứ tự.
- Phát hiện và sửa 1 bug khi build: `id` bookmark trùng lặp giữa 14 heading module mới (đều copy từ 1 template) → gán lại `id` và `name` bookmark duy nhất cho từng module (1012–1025).
- Phát hiện và sửa 1 bug khi chèn: dùng `rfind('<w:tr', ...)` bị trùng khớp nhầm với `<w:trPr>` (vì `<w:trPr` chứa chuỗi con `<w:tr`), khiến khối 14 dòng tổng hợp bị chèn lọt vào giữa dòng TỔNG CỘNG thay vì trước nó → sửa thành `rfind('<w:tr ', ...)` (có khoảng trắng) để chỉ khớp thẻ mở `<w:tr>` thật.
- `validate.py --original`: **PASSED** (0 lỗi XSD, 0 trùng ID, 0 tham chiếu hỏng). Số đoạn văn 2814 → 3630 (+816, tương ứng nội dung mới chèn vào).
- Convert LibreOffice → PDF thành công, **114 trang** (từ 105 trang).
- Grep PDF xác nhận: đủ 25 module ở cả bảng 6.1.2 và 6.3, tổng đúng 183/183/0/100%, mục 6.4 xuất hiện.
- File đã ghi đè tại `MediCare (1).docx` và `MediCare (1).pdf` trong `DOC_BAOCAO`.
