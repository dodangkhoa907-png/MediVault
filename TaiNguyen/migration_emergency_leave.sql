-- ════════════════════════════════════════════════════════════════════════
-- Migration: XIN NGHỈ ĐỘT XUẤT (emergency leave) — ảnh minh chứng + người thay
-- Chạy 1 lần trên PharmacyPro_DB. An toàn chạy lại (IF NOT EXISTS).
-- ════════════════════════════════════════════════════════════════════════
USE PharmacyPro_DB;
GO

-- Ảnh minh chứng (đơn thuốc, giấy nghỉ ốm…) — đường dẫn tương đối phục vụ qua contextPath
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('LeaveRequests') AND name = 'EvidencePath')
BEGIN
    ALTER TABLE LeaveRequests ADD EvidencePath NVARCHAR(500) NULL;
    PRINT 'LeaveRequests.EvidencePath: ADDED';
END ELSE PRINT 'LeaveRequests.EvidencePath: already exists';
GO

-- Người được điều phối làm thay (khi admin duyệt nghỉ đột xuất)
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('LeaveRequests') AND name = 'SubstituteAccountID')
BEGIN
    ALTER TABLE LeaveRequests ADD SubstituteAccountID INT NULL;
    PRINT 'LeaveRequests.SubstituteAccountID: ADDED';
END ELSE PRINT 'LeaveRequests.SubstituteAccountID: already exists';
GO

PRINT 'Migration emergency leave HOÀN TẤT.';
GO
