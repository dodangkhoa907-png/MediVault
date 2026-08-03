/* ============================================================================
   MediVault — Migration: MedicineBarcodes (đa mã vạch + lịch sử quét)
   ----------------------------------------------------------------------------
   Chạy 1 lần trên DB PharmacyPro_DB (SSMS / Azure Data Studio).
   HOÀN TOÀN ADDITIVE — chỉ tạo bảng MỚI, KHÔNG đụng tới cột Medicines.Barcode
   hiện có (vẫn là nguồn "mã vạch chính" cho mọi code cũ, không đổi hành vi
   findByBarcode() hiện tại). Bảng này chỉ CỘNG THÊM khả năng:
     - 1 thuốc có nhiều mã vạch (chính/phụ/NCC/nội bộ/QR)
     - Lịch sử quét (CreatedBy/CreatedAt/LastScannedAt/ScanCount/LastSource)
     - Chặn 1 mã vạch bị gán cho 2 thuốc khác nhau (UNIQUE trên Barcode)
   Idempotent — chạy lại nhiều lần không lỗi.
   ============================================================================ */
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'MedicineBarcodes')
BEGIN
    CREATE TABLE MedicineBarcodes (
        BarcodeID     INT IDENTITY(1,1) PRIMARY KEY,
        MedicineID    INT NOT NULL CONSTRAINT FK_MedicineBarcodes_Medicine REFERENCES Medicines(MedicineID),
        Barcode       NVARCHAR(64) NOT NULL,
        BarcodeType   VARCHAR(20) NOT NULL CONSTRAINT DF_MedicineBarcodes_Type DEFAULT 'primary'
                          CONSTRAINT CK_MedicineBarcodes_Type CHECK (BarcodeType IN ('primary','secondary','supplier','internal','qr')),
        CreatedBy     INT NULL CONSTRAINT FK_MedicineBarcodes_CreatedBy REFERENCES Accounts(AccountID),
        CreatedAt     DATETIME NOT NULL CONSTRAINT DF_MedicineBarcodes_CreatedAt DEFAULT GETDATE(),
        LastScannedAt DATETIME NULL,
        ScanCount     INT NOT NULL CONSTRAINT DF_MedicineBarcodes_ScanCount DEFAULT 0,
        LastSource    VARCHAR(10) NULL CONSTRAINT CK_MedicineBarcodes_Source CHECK (LastSource IN ('camera','usb','manual'))
    );

    -- 1 mã vạch chỉ thuộc về 1 thuốc — chặn gán trùng (mục "BARCODE VALIDATION").
    CREATE UNIQUE NONCLUSTERED INDEX UX_MedicineBarcodes_Barcode ON MedicineBarcodes(Barcode);
    CREATE NONCLUSTERED INDEX IX_MedicineBarcodes_MedicineID ON MedicineBarcodes(MedicineID);

    PRINT '✅ Đã tạo bảng MedicineBarcodes.';
END
ELSE
    PRINT 'ℹ️ Bảng MedicineBarcodes đã tồn tại — bỏ qua.';
GO

PRINT '✅ Barcode multi migration — hoàn tất.';
GO
