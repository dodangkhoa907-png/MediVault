/* ============================================================================
   MediVault — Migration cho 3 tính năng Kho (ROP, Xuất/Điều chỉnh kho, Thu hồi lô)
   ----------------------------------------------------------------------------
   Chạy 1 lần trên DB PharmacyPro_DB (SSMS / Azure Data Studio).
   An toàn: chỉ THÊM cột (additive), có default nên KHÔNG phá dữ liệu cũ.
   Idempotent — chạy lại nhiều lần không lỗi.

   Lưu ý: Batches.Status và PurchaseOrders.Status KHÔNG cần ALTER gì thêm —
   cả 2 cột đã là VARCHAR tự do (không có CHECK constraint giới hạn giá trị),
   và SP_AddSaleByFEFO đã tự lọc "WHERE Status = 'ACTIVE'" nên các giá trị mới
   (QUARANTINE, RECALLED cho Batches; PENDING đã có sẵn cho PurchaseOrders)
   tự động được tôn trọng mà không cần sửa Stored Procedure nào.
   ============================================================================ */
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- Thời gian giao hàng trung bình của NCC (ngày) — dùng cho công thức ROP:
-- ROP = (tiêu thụ TB/ngày × LeadTimeDays) + MinInventory (an toàn kho)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Suppliers') AND name = 'LeadTimeDays')
    ALTER TABLE Suppliers ADD LeadTimeDays INT NOT NULL CONSTRAINT DF_Supplier_LeadTime DEFAULT 7;
GO

PRINT '✅ Warehouse features migration — hoàn tất.';
GO
