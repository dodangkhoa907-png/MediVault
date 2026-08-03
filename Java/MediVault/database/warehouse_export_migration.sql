/* ============================================================================
   MediVault — Migration: Xuất kho (WarehouseExports / FEFO)
   ----------------------------------------------------------------------------
   Chạy 1 lần trên DB PharmacyPro_DB (SSMS / Azure Data Studio).
   HOÀN TOÀN ADDITIVE — chỉ tạo bảng/cột MỚI, không đụng dữ liệu cũ.
     - Accounts.IsWarehouseManager: cờ "Quản lý kho" — chỉ tài khoản này mới được
       ghi đè (override) phân bổ FEFO tự động.
     - ExportReasons: 7 lý do xuất kho cố định (seed sẵn).
     - WarehouseExports / WarehouseExportDetails: chứng từ xuất kho (header/dòng),
       giống cặp PurchaseOrders/PurchaseOrderDetails.
     - ExportStatusHistory: lịch sử đổi trạng thái (Tạo/Xác nhận/Huỷ/Reverse).
   Idempotent — chạy lại nhiều lần không lỗi.
   ============================================================================ */
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Accounts') AND name = 'IsWarehouseManager')
    ALTER TABLE Accounts ADD IsWarehouseManager BIT NOT NULL
        CONSTRAINT DF_Accounts_IsWarehouseManager DEFAULT 0;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ExportReasons')
BEGIN
    CREATE TABLE ExportReasons (
        ReasonID         INT IDENTITY(1,1) PRIMARY KEY,
        ReasonCode       VARCHAR(30) NOT NULL,
        ReasonName       NVARCHAR(100) NOT NULL,
        Description      NVARCHAR(255) NULL,
        RequiresReceiver BIT NOT NULL CONSTRAINT DF_ExportReasons_ReqReceiver DEFAULT 0,
        IsActive         BIT NOT NULL CONSTRAINT DF_ExportReasons_IsActive DEFAULT 1
    );
    CREATE UNIQUE NONCLUSTERED INDEX UX_ExportReasons_Code ON ExportReasons(ReasonCode);

    INSERT INTO ExportReasons (ReasonCode, ReasonName, Description, RequiresReceiver) VALUES
        ('RETAIL_SALE',     N'Bán lẻ (POS)',            N'Xuất thuốc phục vụ bán hàng tại quầy POS', 0),
        ('CUSTOMER_ORDER',  N'Đơn hàng khách (Portal)',  N'Xuất thuốc cho đơn hàng đặt qua Cổng khách hàng', 1),
        ('TRANSFER',        N'Chuyển kho',               N'Chuyển thuốc sang kho/chi nhánh khác', 1),
        ('RETURN_SUPPLIER', N'Trả nhà cung cấp',         N'Trả hàng lỗi/sai cho nhà cung cấp', 1),
        ('EXPIRED_DISPOSAL',N'Tiêu huỷ hết hạn',         N'Tiêu huỷ thuốc hết hạn sử dụng', 0),
        ('INTERNAL_USAGE',  N'Sử dụng nội bộ',           N'Đào tạo, kiểm nghiệm, dùng thử nội bộ', 0),
        ('ADJUSTMENT',      N'Điều chỉnh tồn kho',       N'Hiệu chỉnh chênh lệch sau kiểm kê', 0);

    PRINT '✅ Đã tạo bảng ExportReasons (7 dòng seed).';
END
ELSE
    PRINT 'ℹ️ Bảng ExportReasons đã tồn tại — bỏ qua.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'WarehouseExports')
BEGIN
    CREATE TABLE WarehouseExports (
        ExportID         INT IDENTITY(1,1) PRIMARY KEY,
        ExportCode       AS ('PX' + CAST(ExportID AS VARCHAR(10))) PERSISTED,
        ReasonID         INT NOT NULL CONSTRAINT FK_WhExports_Reason REFERENCES ExportReasons(ReasonID),
        Status           VARCHAR(20) NOT NULL CONSTRAINT DF_WhExports_Status DEFAULT 'PENDING'
                             CONSTRAINT CK_WhExports_Status CHECK (Status IN ('PENDING','CONFIRMED','CANCELLED','REVERSED')),
        Receiver         NVARCHAR(255) NULL,
        Notes            NVARCHAR(500) NULL,
        IsFefoOverridden BIT NOT NULL CONSTRAINT DF_WhExports_Override DEFAULT 0,
        OverrideReason   NVARCHAR(500) NULL,
        OverrideBy       INT NULL CONSTRAINT FK_WhExports_OverrideBy REFERENCES Accounts(AccountID),
        CreatedBy        INT NOT NULL CONSTRAINT FK_WhExports_CreatedBy REFERENCES Accounts(AccountID),
        CreatedAt        DATETIME NOT NULL CONSTRAINT DF_WhExports_CreatedAt DEFAULT GETDATE(),
        ConfirmedAt      DATETIME NULL
    );
    CREATE NONCLUSTERED INDEX IX_WhExports_Status ON WarehouseExports(Status);
    CREATE NONCLUSTERED INDEX IX_WhExports_CreatedAt ON WarehouseExports(CreatedAt);

    PRINT '✅ Đã tạo bảng WarehouseExports.';
END
ELSE
    PRINT 'ℹ️ Bảng WarehouseExports đã tồn tại — bỏ qua.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'WarehouseExportDetails')
BEGIN
    CREATE TABLE WarehouseExportDetails (
        ExportDetailID    INT IDENTITY(1,1) PRIMARY KEY,
        ExportID          INT NOT NULL CONSTRAINT FK_WhExpDetail_Export REFERENCES WarehouseExports(ExportID),
        MedicineID        INT NOT NULL CONSTRAINT FK_WhExpDetail_Medicine REFERENCES Medicines(MedicineID),
        BatchID           INT NOT NULL CONSTRAINT FK_WhExpDetail_Batch REFERENCES Batches(BatchID),
        RequestedQuantity INT NOT NULL,
        AllocatedQuantity INT NOT NULL,
        IsFefoOverridden  BIT NOT NULL CONSTRAINT DF_WhExpDetail_Override DEFAULT 0
    );
    CREATE NONCLUSTERED INDEX IX_WhExpDetail_ExportID ON WarehouseExportDetails(ExportID);
    CREATE NONCLUSTERED INDEX IX_WhExpDetail_BatchID ON WarehouseExportDetails(BatchID);

    PRINT '✅ Đã tạo bảng WarehouseExportDetails.';
END
ELSE
    PRINT 'ℹ️ Bảng WarehouseExportDetails đã tồn tại — bỏ qua.';
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ExportStatusHistory')
BEGIN
    CREATE TABLE ExportStatusHistory (
        HistoryID   INT IDENTITY(1,1) PRIMARY KEY,
        ExportID    INT NOT NULL CONSTRAINT FK_ExpHistory_Export REFERENCES WarehouseExports(ExportID),
        Status      VARCHAR(20) NOT NULL,
        AccountID   INT NULL CONSTRAINT FK_ExpHistory_Account REFERENCES Accounts(AccountID),
        Notes       NVARCHAR(500) NULL,
        CreatedAt   DATETIME NOT NULL CONSTRAINT DF_ExpHistory_CreatedAt DEFAULT GETDATE()
    );
    CREATE NONCLUSTERED INDEX IX_ExpHistory_ExportID ON ExportStatusHistory(ExportID);

    PRINT '✅ Đã tạo bảng ExportStatusHistory.';
END
ELSE
    PRINT 'ℹ️ Bảng ExportStatusHistory đã tồn tại — bỏ qua.';
GO

PRINT '✅ Warehouse export migration — hoàn tất.';
GO
