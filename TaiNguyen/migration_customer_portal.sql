-- ════════════════════════════════════════════════════════════════════════
-- Migration: CUSTOMER PORTAL + NFC + LOYALTY seed
-- Chạy 1 lần trên PharmacyPro_DB. An toàn chạy lại (IF NOT EXISTS).
-- ════════════════════════════════════════════════════════════════════════
USE PharmacyPro_DB;
GO

-- ① Customers.NfcCardUid — UID thẻ NFC vật lý liên kết với khách
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Customers') AND name = 'NfcCardUid')
BEGIN
    ALTER TABLE Customers ADD NfcCardUid VARCHAR(64) NULL;
    PRINT 'Customers.NfcCardUid: ADDED';
END ELSE PRINT 'Customers.NfcCardUid: already exists';
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'UQ_Customers_NfcCardUid')
BEGIN
    CREATE UNIQUE INDEX UQ_Customers_NfcCardUid ON Customers(NfcCardUid) WHERE NfcCardUid IS NOT NULL;
    PRINT 'UQ_Customers_NfcCardUid: ADDED';
END ELSE PRINT 'UQ_Customers_NfcCardUid: already exists';
GO

-- ② Seed 4 hạng thẻ nếu bảng LoyaltyTiers trống
IF NOT EXISTS (SELECT 1 FROM LoyaltyTiers)
BEGIN
    INSERT INTO LoyaltyTiers (TierName, MinPoints, DiscountPct, Description) VALUES
    (N'Đồng',      0,    0,   N'Hạng khởi điểm'),
    (N'Bạc',       1000, 2,   N'Giảm 2% mỗi hóa đơn'),
    (N'Vàng',      3000, 5,   N'Giảm 5% mỗi hóa đơn'),
    (N'Bạch Kim',  8000, 8,   N'Giảm 8% mỗi hóa đơn + ưu tiên tư vấn');
    PRINT 'LoyaltyTiers: SEEDED 4 tiers';
END ELSE PRINT 'LoyaltyTiers: already has data';
GO

PRINT 'Migration customer portal HOÀN TẤT.';
GO
