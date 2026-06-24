USE PharmacyPro_DB;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
SET NOCOUNT ON;

-- IDs confirmed:
-- Categories:    2=Kháng sinh, 3=Vitamin, 6=Tiểu đường
-- Manufacturers: 1=Pymepharco, 2=DHG Pharma, 3=Imexpharm
-- Shelves:       4=Kệ A2, 5=Kệ B1
-- Suppliers:     1
-- AdminAccount:  3

-- ① Amoxicillin 500mg (Kháng sinh, Pymepharco, Kệ A2, Kê đơn)
IF NOT EXISTS (SELECT 1 FROM Medicines WHERE MedicineName = N'Amoxicillin 500mg')
    INSERT INTO Medicines (MedicineName, GenericName, Barcode, CategoryID, ManufacturerID,
                           Unit, ShelfID, Dosage, Contraindications,
                           IsPrescriptionRequired, SellingPrice, MinInventory, Status, ExpiryAlertDays)
    VALUES (N'Amoxicillin 500mg', N'Amoxicillin trihydrate', '8934567890002',
            2, 1, N'Viên nang', 4,
            N'Người lớn: 500mg x 3 lần/ngày, uống sau ăn, liệu trình 7-10 ngày.',
            N'Dị ứng Penicillin hoặc Cephalosporin.',
            1, 8000, 15, 1, 60);

-- ② Vitamin C 1000mg (Vitamin, DHG Pharma, Kệ B1, OTC)
IF NOT EXISTS (SELECT 1 FROM Medicines WHERE MedicineName = N'Vitamin C 1000mg')
    INSERT INTO Medicines (MedicineName, GenericName, Barcode, CategoryID, ManufacturerID,
                           Unit, ShelfID, Dosage, Contraindications,
                           IsPrescriptionRequired, SellingPrice, MinInventory, Status, ExpiryAlertDays)
    VALUES (N'Vitamin C 1000mg', N'Ascorbic acid', '8934567890003',
            3, 2, N'Viên sủi', 5,
            N'1 viên/ngày, hòa tan trong 200ml nước lọc, uống sau bữa ăn sáng.',
            N'Sỏi thận oxalate, tiểu đường không kiểm soát.',
            0, 12000, 10, 1, 45);

-- ③ Metformin 500mg (Tiểu đường, Imexpharm, Kệ A2, Kê đơn)
IF NOT EXISTS (SELECT 1 FROM Medicines WHERE MedicineName = N'Metformin 500mg')
    INSERT INTO Medicines (MedicineName, GenericName, Barcode, CategoryID, ManufacturerID,
                           Unit, ShelfID, Dosage, Contraindications,
                           IsPrescriptionRequired, SellingPrice, MinInventory, Status, ExpiryAlertDays)
    VALUES (N'Metformin 500mg', N'Metformin hydrochloride', '8934567890007',
            6, 3, N'Viên', 4,
            N'500mg x 2-3 lần/ngày, uống trong hoặc sau bữa ăn. Tăng liều từ từ.',
            N'Suy thận (GFR < 30), suy gan nặng, nghiện rượu.',
            1, 5500, 10, 1, 60);

PRINT '3 medicines inserted';

-- Tạo PurchaseOrder cho batch bổ sung
DECLARE @poID INT;
INSERT INTO PurchaseOrders (SupplierID, AccountID, Notes)
VALUES (1, 3, N'Đơn nhập bổ sung — Amoxicillin, VitC, Metformin');
SET @poID = SCOPE_IDENTITY();

DECLARE @m2 INT = (SELECT MedicineID FROM Medicines WHERE MedicineName = N'Amoxicillin 500mg');
DECLARE @m3 INT = (SELECT MedicineID FROM Medicines WHERE MedicineName = N'Vitamin C 1000mg');
DECLARE @m7 INT = (SELECT MedicineID FROM Medicines WHERE MedicineName = N'Metformin 500mg');

IF NOT EXISTS (SELECT 1 FROM Batches WHERE MedicineID = @m2 AND BatchNumber = 'AM-2024-001')
    INSERT INTO Batches (MedicineID, POID, SupplierID, BatchNumber, ManufactureDate, ExpiryDate,
                         ImportPrice, InitialQuantity, CurrentQuantity)
    VALUES (@m2, @poID, 1, 'AM-2024-001', '2024-02-10', '2026-10-31', 5500, 100, 100);

IF NOT EXISTS (SELECT 1 FROM Batches WHERE MedicineID = @m3 AND BatchNumber = 'VC-2024-001')
    INSERT INTO Batches (MedicineID, POID, SupplierID, BatchNumber, ManufactureDate, ExpiryDate,
                         ImportPrice, InitialQuantity, CurrentQuantity)
    VALUES (@m3, @poID, 1, 'VC-2024-001', '2024-03-05', '2027-03-31', 8000, 150, 150);

IF NOT EXISTS (SELECT 1 FROM Batches WHERE MedicineID = @m7 AND BatchNumber = 'ME-2024-001')
    INSERT INTO Batches (MedicineID, POID, SupplierID, BatchNumber, ManufactureDate, ExpiryDate,
                         ImportPrice, InitialQuantity, CurrentQuantity)
    VALUES (@m7, @poID, 1, 'ME-2024-001', '2024-03-15', '2027-02-28', 3800, 80, 80);

UPDATE PurchaseOrders
SET TotalValue = (SELECT ISNULL(SUM(b.ImportPrice * b.InitialQuantity), 0)
                  FROM Batches b WHERE b.POID = @poID)
WHERE POID = @poID;

PRINT 'Batches inserted';

-- Kết quả cuối
SELECT m.MedicineCode,
       m.MedicineName,
       CASE WHEN m.IsPrescriptionRequired = 1 THEN 'Ke don' ELSE 'OTC' END AS LoaiThuoc,
       m.Unit,
       CAST(m.SellingPrice AS INT) AS GiaBan,
       ISNULL(SUM(b.CurrentQuantity), 0) AS TonKho
FROM Medicines m
LEFT JOIN Batches b ON b.MedicineID = m.MedicineID
WHERE m.Status = 1
GROUP BY m.MedicineCode, m.MedicineName, m.IsPrescriptionRequired, m.Unit, m.SellingPrice
ORDER BY m.MedicineCode;
