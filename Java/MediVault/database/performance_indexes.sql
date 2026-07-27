/* ============================================================================
   MediVault — Performance Indexes
   ----------------------------------------------------------------------------
   Chạy 1 lần trên DB PharmacyPro_DB (SSMS / Azure Data Studio).
   An toàn: chỉ THÊM index (additive), KHÔNG sửa/xoá dữ liệu. Idempotent — chạy
   lại nhiều lần không lỗi (mỗi index có guard IF NOT EXISTS).

   Vì sao cần: các bản vá code đã đổi predicate sang dạng "sargable"
   (CreatedAt >= ? AND CreatedAt < ? thay cho CAST(CreatedAt AS DATE) BETWEEN).
   Nhưng SQL Server chỉ SEEK được khi CÓ index trên cột đó — nếu chưa có index,
   query vẫn full scan. Script này tạo đúng các index cho những cột đang bị
   scan liên tục ở Dashboard / Report / Invoice / Attendance / POS.

   Filtered index (có WHERE) BẮT BUỘC các SET option dưới đây khi TẠO.
   ============================================================================ */
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
GO

/* ── POS scan — hot path (<50ms): tìm thuốc theo Barcode khi quẹt máy ─────── */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Medicines_Barcode' AND object_id=OBJECT_ID('Medicines'))
    CREATE NONCLUSTERED INDEX IX_Medicines_Barcode
        ON Medicines(Barcode)
        INCLUDE (MedicineName, MedicineCode)
        WHERE Status = 1;   -- chỉ thuốc đang kinh doanh
GO

/* ── Invoices: lọc theo Status + khoảng ngày (Report, Dashboard, Hóa đơn) ── */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Invoices_Status_CreatedAt' AND object_id=OBJECT_ID('Invoices'))
    CREATE NONCLUSTERED INDEX IX_Invoices_Status_CreatedAt
        ON Invoices(Status, CreatedAt)
        INCLUDE (FinalAmount, DiscountAmount);
GO
-- Lọc hoá đơn theo nhân viên (InvoiceServlet filter, đối soát ca)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Invoices_AccountID' AND object_id=OBJECT_ID('Invoices'))
    CREATE NONCLUSTERED INDEX IX_Invoices_AccountID ON Invoices(AccountID);
GO

/* ── InvoiceDetails: join theo InvoiceID (chi tiết) và BatchID (COGS/doanh thu) */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_InvoiceDetails_InvoiceID' AND object_id=OBJECT_ID('InvoiceDetails'))
    CREATE NONCLUSTERED INDEX IX_InvoiceDetails_InvoiceID
        ON InvoiceDetails(InvoiceID)
        INCLUDE (BatchID, Quantity, SubTotal, UnitPrice);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_InvoiceDetails_BatchID' AND object_id=OBJECT_ID('InvoiceDetails'))
    CREATE NONCLUSTERED INDEX IX_InvoiceDetails_BatchID ON InvoiceDetails(BatchID);
GO

/* ── Batches: FEFO (SP_AddSaleByFEFO đọc mỗi dòng bán) + lô cận/hết hạn ───── */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Batches_Fefo' AND object_id=OBJECT_ID('Batches'))
    CREATE NONCLUSTERED INDEX IX_Batches_Fefo
        ON Batches(MedicineID, ExpiryDate)
        INCLUDE (CurrentQuantity, ImportPrice)
        WHERE Status = 'ACTIVE';
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Batches_Expiry' AND object_id=OBJECT_ID('Batches'))
    CREATE NONCLUSTERED INDEX IX_Batches_Expiry
        ON Batches(ExpiryDate)
        INCLUDE (MedicineID, CurrentQuantity)
        WHERE Status = 'ACTIVE';
GO

/* ── Attendance: điểm danh theo nhân viên + khoảng ngày (list & tổng hợp tháng) */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Attendance_Account_CheckIn' AND object_id=OBJECT_ID('Attendance'))
    CREATE NONCLUSTERED INDEX IX_Attendance_Account_CheckIn
        ON Attendance(AccountID, CheckInTime);
GO
-- Chế độ "tất cả nhân viên" (accountId=0): quét theo CheckInTime
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Attendance_CheckIn' AND object_id=OBJECT_ID('Attendance'))
    CREATE NONCLUSTERED INDEX IX_Attendance_CheckIn ON Attendance(CheckInTime);
GO

/* ── AuditLog: phân trang ORDER BY CreatedAt DESC (bảng phình nhanh nhất) ─── */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_AuditLog_CreatedAt' AND object_id=OBJECT_ID('AuditLog'))
    CREATE NONCLUSTERED INDEX IX_AuditLog_CreatedAt ON AuditLog(CreatedAt DESC);
GO

/* ── Returns: doanh thu trả hàng + giá vốn hàng trả (Report) ──────────────── */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Returns_Type_CreatedAt' AND object_id=OBJECT_ID('Returns'))
    CREATE NONCLUSTERED INDEX IX_Returns_Type_CreatedAt
        ON Returns(ReturnType, CreatedAt)
        INCLUDE (BatchID, InvoiceID, Quantity);
GO

/* ── ShiftSchedules & Shifts: lịch ca theo ngày / nhân viên ───────────────── */
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_ShiftSchedules_WorkDate' AND object_id=OBJECT_ID('ShiftSchedules'))
    CREATE NONCLUSTERED INDEX IX_ShiftSchedules_WorkDate
        ON ShiftSchedules(WorkDate)
        INCLUDE (AccountID, PosStation, Status, ShiftTypeID);
GO
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_Shifts_StartTime' AND object_id=OBJECT_ID('Shifts'))
    CREATE NONCLUSTERED INDEX IX_Shifts_StartTime ON Shifts(StartTime);
GO

PRINT '✅ MediVault performance indexes — hoàn tất (các index đã tồn tại được bỏ qua).';
GO
