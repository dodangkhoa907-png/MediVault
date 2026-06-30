USE PharmacyPro_DB;
GO
SET NOCOUNT ON;
PRINT '=== MediVault Migration: Multi-POS + Face Recognition ===';

-- ① Accounts.LastActiveAt (presence tracking — có thể đã tồn tại từ session trước)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Accounts') AND name = 'LastActiveAt')
BEGIN
    ALTER TABLE Accounts ADD LastActiveAt DATETIME NULL;
    PRINT 'Accounts.LastActiveAt: ADDED';
END ELSE PRINT 'Accounts.LastActiveAt: already exists';

-- ② Accounts.FaceVector (128-dim descriptor JSON từ face-api.js)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Accounts') AND name = 'FaceVector')
BEGIN
    ALTER TABLE Accounts ADD FaceVector NVARCHAR(MAX) NULL;
    PRINT 'Accounts.FaceVector: ADDED';
END ELSE PRINT 'Accounts.FaceVector: already exists';

-- ③ Accounts.FaceEnrolledAt
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Accounts') AND name = 'FaceEnrolledAt')
BEGIN
    ALTER TABLE Accounts ADD FaceEnrolledAt DATETIME NULL;
    PRINT 'Accounts.FaceEnrolledAt: ADDED';
END ELSE PRINT 'Accounts.FaceEnrolledAt: already exists';

-- ④ Accounts.FaceEnrollmentPath (ảnh preview — có thể đã có)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Accounts') AND name = 'FaceEnrollmentPath')
BEGIN
    ALTER TABLE Accounts ADD FaceEnrollmentPath NVARCHAR(500) NULL;
    PRINT 'Accounts.FaceEnrollmentPath: ADDED';
END ELSE PRINT 'Accounts.FaceEnrollmentPath: already exists';

-- ⑤ Invoices/Sales.PosStation (quầy bán hàng — 1,2,3,4...)
--    Kiểm tra tên bảng thực tế (Invoices vs Sales)
IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Invoices')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Invoices') AND name = 'PosStation')
    BEGIN
        ALTER TABLE Invoices ADD PosStation TINYINT NOT NULL DEFAULT 1;
        PRINT 'Invoices.PosStation: ADDED';
    END ELSE PRINT 'Invoices.PosStation: already exists';
END

IF EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Sales')
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Sales') AND name = 'PosStation')
    BEGIN
        ALTER TABLE Sales ADD PosStation TINYINT NOT NULL DEFAULT 1;
        PRINT 'Sales.PosStation: ADDED';
    END ELSE PRINT 'Sales.PosStation: already exists';
END

-- ⑥ ShiftSchedules.PosStation (nhân viên sẽ làm ở quầy nào)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('ShiftSchedules') AND name = 'PosStation')
BEGIN
    ALTER TABLE ShiftSchedules ADD PosStation TINYINT NULL;
    PRINT 'ShiftSchedules.PosStation: ADDED';
END ELSE PRINT 'ShiftSchedules.PosStation: already exists';

-- ⑦ Attendance.PosStation
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Attendance') AND name = 'PosStation')
BEGIN
    ALTER TABLE Attendance ADD PosStation TINYINT NULL;
    PRINT 'Attendance.PosStation: ADDED';
END ELSE PRINT 'Attendance.PosStation: already exists';

-- ⑦ Index nhanh cho presence tracking
--    Dùng dynamic SQL để tránh lỗi parse khi cột vừa được ADD trong cùng batch
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Accounts_LastActiveAt' AND object_id = OBJECT_ID('Accounts'))
BEGIN
    EXEC('CREATE NONCLUSTERED INDEX IX_Accounts_LastActiveAt ON Accounts (LastActiveAt DESC) WHERE LastActiveAt IS NOT NULL');
    PRINT 'Index IX_Accounts_LastActiveAt: CREATED';
END ELSE PRINT 'Index IX_Accounts_LastActiveAt: already exists';

PRINT '';
PRINT '=== Migration hoàn thành ===';
PRINT 'Chạy lệnh sau để kiểm tra:';
PRINT 'SELECT AccountID, FullName, FaceVector, FaceEnrolledAt, LastActiveAt FROM Accounts WHERE IsDeleted = 0;';
GO
