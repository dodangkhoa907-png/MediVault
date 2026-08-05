/* ============================================================================
   MediVault — Migration: Returns.RefundMethod (Phương thức hoàn tiền)
   ----------------------------------------------------------------------------
   Chạy 1 lần trên DB PharmacyPro_DB (SSMS / Azure Data Studio).
   An toàn: chỉ THÊM cột (additive), DEFAULT 'CASH' nên KHÔNG phá dữ liệu cũ.
   Idempotent — chạy lại nhiều lần không lỗi (kể cả sau khi đã chạy bản cũ
   với danh sách CASH/QR_CODE/CARD — script tự chuẩn hoá dữ liệu & constraint).

   Dùng cho màn "Lịch sử hóa đơn" (POS) khi trả hàng: ghi nhận khách được
   hoàn lại bằng hình thức nào — CASH (tiền mặt) | VOUCHER (voucher giảm giá
   trị tương đương số tiền cần hoàn).
   ============================================================================ */
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Returns') AND name = 'RefundMethod')
    ALTER TABLE Returns ADD RefundMethod VARCHAR(20) NOT NULL DEFAULT 'CASH';
GO

-- Chuẩn hoá dữ liệu cũ (nếu đã từng có QR_CODE/CARD từ bản migration trước) về CASH
-- trước khi siết constraint mới — tránh ALTER TABLE ADD CONSTRAINT bị lỗi vi phạm dữ liệu hiện có.
UPDATE Returns SET RefundMethod = 'CASH' WHERE RefundMethod NOT IN ('CASH','VOUCHER');
GO

IF EXISTS (SELECT 1 FROM sys.check_constraints WHERE name = 'CK_Ret_RefundMethod')
    ALTER TABLE Returns DROP CONSTRAINT CK_Ret_RefundMethod;
GO

ALTER TABLE Returns ADD CONSTRAINT CK_Ret_RefundMethod CHECK (RefundMethod IN ('CASH','VOUCHER'));
GO

PRINT '✅ Returns.RefundMethod migration — hoàn tất.';
GO
