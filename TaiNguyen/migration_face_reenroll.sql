-- ════════════════════════════════════════════════════════════════════════
-- Migration: Luồng XIN ĐĂNG KÝ LẠI KHUÔN MẶT (face re-enrollment request)
-- Chạy 1 lần trên PharmacyPro_DB. An toàn chạy lại (IF NOT EXISTS).
--
-- Luồng: NV gửi yêu cầu (PENDING) → chặn quét mặt điểm danh (vẫn login được)
--        → mail admin → admin duyệt → xóa FaceVector → mail NV → NV đăng ký lại.
-- ════════════════════════════════════════════════════════════════════════
USE PharmacyPro_DB;
GO

-- Trạng thái yêu cầu: NULL = không có yêu cầu | 'PENDING' = chờ duyệt
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Accounts') AND name = 'FaceReenrollStatus')
BEGIN
    ALTER TABLE Accounts ADD FaceReenrollStatus VARCHAR(20) NULL;
    PRINT 'Accounts.FaceReenrollStatus: ADDED';
END ELSE PRINT 'Accounts.FaceReenrollStatus: already exists';
GO

-- Lý do nhân viên nêu khi xin đăng ký lại
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Accounts') AND name = 'FaceReenrollReason')
BEGIN
    ALTER TABLE Accounts ADD FaceReenrollReason NVARCHAR(500) NULL;
    PRINT 'Accounts.FaceReenrollReason: ADDED';
END ELSE PRINT 'Accounts.FaceReenrollReason: already exists';
GO

-- Thời điểm gửi yêu cầu
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Accounts') AND name = 'FaceReenrollRequestedAt')
BEGIN
    ALTER TABLE Accounts ADD FaceReenrollRequestedAt DATETIME NULL;
    PRINT 'Accounts.FaceReenrollRequestedAt: ADDED';
END ELSE PRINT 'Accounts.FaceReenrollRequestedAt: already exists';
GO

-- Admin xử lý (duyệt/từ chối) — ai, khi nào, ghi chú
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Accounts') AND name = 'FaceReenrollHandledBy')
BEGIN
    ALTER TABLE Accounts ADD FaceReenrollHandledBy INT NULL;
    PRINT 'Accounts.FaceReenrollHandledBy: ADDED';
END ELSE PRINT 'Accounts.FaceReenrollHandledBy: already exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Accounts') AND name = 'FaceReenrollHandledAt')
BEGIN
    ALTER TABLE Accounts ADD FaceReenrollHandledAt DATETIME NULL;
    PRINT 'Accounts.FaceReenrollHandledAt: ADDED';
END ELSE PRINT 'Accounts.FaceReenrollHandledAt: already exists';
GO

PRINT '════════════════════════════════════════════';
PRINT 'Migration face re-enroll HOÀN TẤT.';
PRINT 'Kiểm tra: SELECT AccountID, FullName, FaceReenrollStatus, FaceReenrollReason, FaceReenrollRequestedAt FROM Accounts WHERE FaceReenrollStatus IS NOT NULL;';
GO
