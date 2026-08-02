/* ============================================================================
   MediVault — Migration: PurchaseOrders.ExpectedDate (Ngày giao dự kiến)
   ----------------------------------------------------------------------------
   Chạy 1 lần trên DB PharmacyPro_DB (SSMS / Azure Data Studio).
   An toàn: chỉ THÊM cột (additive), NULL nên KHÔNG phá dữ liệu cũ.
   Idempotent — chạy lại nhiều lần không lỗi.

   Dùng cho trang "Đơn hàng" (Warehouse Console, /warehouse-orders): xác định
   đơn PENDING nào đã QUÁ HẠN giao (ExpectedDate < hôm nay) để cảnh báo Thủ kho.
   Không có CHECK constraint nào trên Status/ExpectedDate — giữ đúng quy ước tự
   do đã áp dụng cho PurchaseOrders.Status từ trước (xem warehouse_features_migration.sql).
   ============================================================================ */
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('PurchaseOrders') AND name = 'ExpectedDate')
    ALTER TABLE PurchaseOrders ADD ExpectedDate DATE NULL;
GO

PRINT '✅ PurchaseOrders.ExpectedDate migration — hoàn tất.';
GO
