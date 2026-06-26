USE PharmacyPro_DB;
GO
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;

PRINT '=== Báº®T Äáº¦U INSERT Dá»® LIá»†U MáºªU 7 THUá»C ===';

/* â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
   1. CATEGORIES
â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• */
IF NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryName = N'Thuá»‘c háº¡ sá»‘t & giáº£m Ä‘au')
    INSERT INTO Categories (CategoryName, Description)
    VALUES (N'Thuá»‘c háº¡ sá»‘t & giáº£m Ä‘au', N'CÃ¡c loáº¡i thuá»‘c dÃ¹ng Ä‘á»ƒ háº¡ sá»‘t vÃ  giáº£m Ä‘au thÃ´ng thÆ°á»ng');

IF NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryName = N'KhÃ¡ng sinh')
    INSERT INTO Categories (CategoryName, Description)
    VALUES (N'KhÃ¡ng sinh', N'Thuá»‘c khÃ¡ng sinh Ä‘iá»u trá»‹ nhiá»…m khuáº©n, cáº§n kÃª Ä‘Æ¡n bÃ¡c sÄ©');

IF NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryName = N'Vitamin & KhoÃ¡ng cháº¥t')
    INSERT INTO Categories (CategoryName, Description)
    VALUES (N'Vitamin & KhoÃ¡ng cháº¥t', N'Bá»• sung vitamin vÃ  khoÃ¡ng cháº¥t thiáº¿t yáº¿u cho cÆ¡ thá»ƒ');

IF NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryName = N'Thuá»‘c tiÃªu hÃ³a')
    INSERT INTO Categories (CategoryName, Description)
    VALUES (N'Thuá»‘c tiÃªu hÃ³a', N'Äiá»u trá»‹ cÃ¡c bá»‡nh vá» dáº¡ dÃ y, Ä‘Æ°á»ng tiÃªu hÃ³a');

IF NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryName = N'Thuá»‘c dá»‹ á»©ng')
    INSERT INTO Categories (CategoryName, Description)
    VALUES (N'Thuá»‘c dá»‹ á»©ng', N'Äiá»u trá»‹ dá»‹ á»©ng, viÃªm mÅ©i dá»‹ á»©ng, ná»•i má» Ä‘ay');

IF NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryName = N'Thuá»‘c tiá»ƒu Ä‘Æ°á»ng')
    INSERT INTO Categories (CategoryName, Description)
    VALUES (N'Thuá»‘c tiá»ƒu Ä‘Æ°á»ng', N'Äiá»u trá»‹ vÃ  kiá»ƒm soÃ¡t Ä‘Æ°á»ng huyáº¿t cho bá»‡nh nhÃ¢n tiá»ƒu Ä‘Æ°á»ng');

IF NOT EXISTS (SELECT 1 FROM Categories WHERE CategoryName = N'KhÃ¡ng viÃªm & giáº£m Ä‘au')
    INSERT INTO Categories (CategoryName, Description)
    VALUES (N'KhÃ¡ng viÃªm & giáº£m Ä‘au', N'Thuá»‘c khÃ¡ng viÃªm khÃ´ng steroid (NSAIDs), giáº£m Ä‘au, háº¡ sá»‘t');

PRINT 'âœ“ Categories OK';

/* â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
   2. MANUFACTURERS
â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• */
IF NOT EXISTS (SELECT 1 FROM Manufacturers WHERE Name = N'Pymepharco')
    INSERT INTO Manufacturers (Name, Country, Address)
    VALUES (N'Pymepharco', N'Viá»‡t Nam', N'18 TrÆ°á»ng Chinh, Tuy HÃ²a, PhÃº YÃªn');

IF NOT EXISTS (SELECT 1 FROM Manufacturers WHERE Name = N'DHG Pharma')
    INSERT INTO Manufacturers (Name, Country, Address)
    VALUES (N'DHG Pharma', N'Viá»‡t Nam', N'288 Bis Nguyá»…n VÄƒn Cá»«, Ninh Kiá»u, Cáº§n ThÆ¡');

IF NOT EXISTS (SELECT 1 FROM Manufacturers WHERE Name = N'Imexpharm')
    INSERT INTO Manufacturers (Name, Country, Address)
    VALUES (N'Imexpharm', N'Viá»‡t Nam', N'04 ÄÆ°á»ng 30/4, TP Cao LÃ£nh, Äá»“ng ThÃ¡p');

PRINT 'âœ“ Manufacturers OK';

/* â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
   3. SUPPLIERS
â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• */
IF NOT EXISTS (SELECT 1 FROM Suppliers WHERE SupplierName = N'CÃ´ng ty CP DÆ°á»£c pháº©m Trung Æ¯Æ¡ng 1')
    INSERT INTO Suppliers (SupplierName, ContactName, Phone, Email, Address, LicenseNumber, IsActive)
    VALUES (N'CÃ´ng ty CP DÆ°á»£c pháº©m Trung Æ¯Æ¡ng 1', N'Nguyá»…n VÄƒn Nam', '0909123456',
            'supply@dupharma.vn', N'40 Phá»‘ NhÃ  Chung, HoÃ n Kiáº¿m, HÃ  Ná»™i', 'GP-TW1-001', 1);

PRINT 'âœ“ Suppliers OK';

/* â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
   4. SHELVES
â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• */
IF NOT EXISTS (SELECT 1 FROM Shelves WHERE ShelfName = N'Ká»‡ A1')
    INSERT INTO Shelves (ShelfName, LocationNotes, ShelfType)
    VALUES (N'Ká»‡ A1', N'Ká»‡ thuá»‘c OTC - háº¡ sá»‘t, giáº£m Ä‘au, dá»‹ á»©ng', 'RETAIL');

IF NOT EXISTS (SELECT 1 FROM Shelves WHERE ShelfName = N'Ká»‡ A2')
    INSERT INTO Shelves (ShelfName, LocationNotes, ShelfType)
    VALUES (N'Ká»‡ A2', N'Ká»‡ thuá»‘c kÃª Ä‘Æ¡n - khÃ¡ng sinh, tiá»ƒu Ä‘Æ°á»ng', 'RETAIL');

IF NOT EXISTS (SELECT 1 FROM Shelves WHERE ShelfName = N'Ká»‡ B1')
    INSERT INTO Shelves (ShelfName, LocationNotes, ShelfType)
    VALUES (N'Ká»‡ B1', N'Ká»‡ vitamin vÃ  thá»±c pháº©m bá»• sung', 'RETAIL');

PRINT 'âœ“ Shelves OK';

/* â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
   5. Láº¤Y IDs Cáº¦N THIáº¾T
â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• */
DECLARE @catPain       INT = (SELECT CategoryID FROM Categories WHERE CategoryName = N'Thuá»‘c háº¡ sá»‘t & giáº£m Ä‘au');
DECLARE @catAntibiotic INT = (SELECT CategoryID FROM Categories WHERE CategoryName = N'KhÃ¡ng sinh');
DECLARE @catVitamin    INT = (SELECT CategoryID FROM Categories WHERE CategoryName = N'Vitamin & KhoÃ¡ng cháº¥t');
DECLARE @catGastro     INT = (SELECT CategoryID FROM Categories WHERE CategoryName = N'Thuá»‘c tiÃªu hÃ³a');
DECLARE @catAllergy    INT = (SELECT CategoryID FROM Categories WHERE CategoryName = N'Thuá»‘c dá»‹ á»©ng');
DECLARE @catDiabetes   INT = (SELECT CategoryID FROM Categories WHERE CategoryName = N'Thuá»‘c tiá»ƒu Ä‘Æ°á»ng');
DECLARE @catNSAID      INT = (SELECT CategoryID FROM Categories WHERE CategoryName = N'KhÃ¡ng viÃªm & giáº£m Ä‘au');

DECLARE @mfrPyme INT = (SELECT ManufacturerID FROM Manufacturers WHERE Name = N'Pymepharco');
DECLARE @mfrDHG  INT = (SELECT ManufacturerID FROM Manufacturers WHERE Name = N'DHG Pharma');
DECLARE @mfrImex INT = (SELECT ManufacturerID FROM Manufacturers WHERE Name = N'Imexpharm');

DECLARE @shelfA1 INT = (SELECT ShelfID FROM Shelves WHERE ShelfName = N'Ká»‡ A1');
DECLARE @shelfA2 INT = (SELECT ShelfID FROM Shelves WHERE ShelfName = N'Ká»‡ A2');
DECLARE @shelfB1 INT = (SELECT ShelfID FROM Shelves WHERE ShelfName = N'Ká»‡ B1');

DECLARE @supplierID INT = (SELECT TOP 1 SupplierID FROM Suppliers WHERE IsActive = 1 ORDER BY SupplierID);
DECLARE @adminID    INT = (SELECT TOP 1 AccountID  FROM Accounts  WHERE RoleID  = 1 ORDER BY AccountID);

PRINT 'IDs: cat_pain=' + CAST(@catPain AS VARCHAR) + ', mfr_pyme=' + CAST(@mfrPyme AS VARCHAR)
    + ', shelf_a1=' + CAST(@shelfA1 AS VARCHAR) + ', supplier=' + CAST(@supplierID AS VARCHAR)
    + ', admin=' + CAST(@adminID AS VARCHAR);

/* â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
   6. MEDICINES (7 thuá»‘c máº«u)
â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• */

-- â‘  Paracetamol 500mg â€” háº¡ sá»‘t, giáº£m Ä‘au (OTC)
IF NOT EXISTS (SELECT 1 FROM Medicines WHERE MedicineName = N'Paracetamol 500mg')
    INSERT INTO Medicines (MedicineName, GenericName, Barcode, CategoryID, ManufacturerID,
                           Unit, ShelfID, Dosage, Contraindications,
                           IsPrescriptionRequired, SellingPrice, MinInventory, Status, ExpiryAlertDays)
    VALUES (N'Paracetamol 500mg', N'Paracetamol', '8934567890001',
            @catPain, @mfrPyme, N'ViÃªn', @shelfA1,
            N'NgÆ°á»i lá»›n: 1-2 viÃªn/láº§n, 3-4 láº§n/ngÃ y. CÃ¡ch nhau tá»‘i thiá»ƒu 4-6 giá».',
            N'Suy gan náº·ng, dá»‹ á»©ng vá»›i Paracetamol.',
            0, 5000, 20, 1, 30);

-- â‘¡ Amoxicillin 500mg â€” khÃ¡ng sinh (KÃª Ä‘Æ¡n)
IF NOT EXISTS (SELECT 1 FROM Medicines WHERE MedicineName = N'Amoxicillin 500mg')
    INSERT INTO Medicines (MedicineName, GenericName, Barcode, CategoryID, ManufacturerID,
                           Unit, ShelfID, Dosage, Contraindications,
                           IsPrescriptionRequired, SellingPrice, MinInventory, Status, ExpiryAlertDays)
    VALUES (N'Amoxicillin 500mg', N'Amoxicillin trihydrate', '8934567890002',
            @catAntibiotic, @mfrPyme, N'ViÃªn nang', @shelfA2,
            N'NgÆ°á»i lá»›n: 500mg x 3 láº§n/ngÃ y, uá»‘ng sau Äƒn, liá»‡u trÃ¬nh 7-10 ngÃ y.',
            N'Dá»‹ á»©ng Penicillin hoáº·c Cephalosporin.',
            1, 8000, 15, 1, 60);

-- â‘¢ Vitamin C 1000mg â€” bá»• sung vitamin (OTC)
IF NOT EXISTS (SELECT 1 FROM Medicines WHERE MedicineName = N'Vitamin C 1000mg')
    INSERT INTO Medicines (MedicineName, GenericName, Barcode, CategoryID, ManufacturerID,
                           Unit, ShelfID, Dosage, Contraindications,
                           IsPrescriptionRequired, SellingPrice, MinInventory, Status, ExpiryAlertDays)
    VALUES (N'Vitamin C 1000mg', N'Ascorbic acid', '8934567890003',
            @catVitamin, @mfrDHG, N'ViÃªn sá»§i', @shelfB1,
            N'1 viÃªn/ngÃ y, hÃ²a tan trong 200ml nÆ°á»›c lá»c, uá»‘ng sau bá»¯a Äƒn sÃ¡ng.',
            N'Sá»i tháº­n oxalate, tiá»ƒu Ä‘Æ°á»ng khÃ´ng kiá»ƒm soÃ¡t.',
            0, 12000, 10, 1, 45);

-- â‘£ Omeprazole 20mg â€” dáº¡ dÃ y (KÃª Ä‘Æ¡n)
IF NOT EXISTS (SELECT 1 FROM Medicines WHERE MedicineName = N'Omeprazole 20mg')
    INSERT INTO Medicines (MedicineName, GenericName, Barcode, CategoryID, ManufacturerID,
                           Unit, ShelfID, Dosage, Contraindications,
                           IsPrescriptionRequired, SellingPrice, MinInventory, Status, ExpiryAlertDays)
    VALUES (N'Omeprazole 20mg', N'Omeprazole', '8934567890004',
            @catGastro, @mfrImex, N'ViÃªn nang', @shelfA1,
            N'20-40mg/ngÃ y, uá»‘ng trÆ°á»›c Äƒn 30 phÃºt, khÃ´ng nhai vá»¡ viÃªn.',
            N'QuÃ¡ máº«n vá»›i Omeprazole hoáº·c Benzimidazole.',
            1, 6500, 15, 1, 60);

-- â‘¤ Cetirizine 10mg â€” dá»‹ á»©ng (OTC)
IF NOT EXISTS (SELECT 1 FROM Medicines WHERE MedicineName = N'Cetirizine 10mg')
    INSERT INTO Medicines (MedicineName, GenericName, Barcode, CategoryID, ManufacturerID,
                           Unit, ShelfID, Dosage, Contraindications,
                           IsPrescriptionRequired, SellingPrice, MinInventory, Status, ExpiryAlertDays)
    VALUES (N'Cetirizine 10mg', N'Cetirizine hydrochloride', '8934567890005',
            @catAllergy, @mfrDHG, N'ViÃªn', @shelfA1,
            N'1 viÃªn/ngÃ y, uá»‘ng vÃ o buá»•i tá»‘i trÆ°á»›c khi ngá»§. KhÃ´ng dÃ¹ng quÃ¡ 1 viÃªn/ngÃ y.',
            N'Suy tháº­n náº·ng, tráº» em dÆ°á»›i 2 tuá»•i.',
            0, 4000, 20, 1, 30);

-- â‘¥ Ibuprofen 400mg â€” khÃ¡ng viÃªm, giáº£m Ä‘au (OTC)
IF NOT EXISTS (SELECT 1 FROM Medicines WHERE MedicineName = N'Ibuprofen 400mg')
    INSERT INTO Medicines (MedicineName, GenericName, Barcode, CategoryID, ManufacturerID,
                           Unit, ShelfID, Dosage, Contraindications,
                           IsPrescriptionRequired, SellingPrice, MinInventory, Status, ExpiryAlertDays)
    VALUES (N'Ibuprofen 400mg', N'Ibuprofen', '8934567890006',
            @catNSAID, @mfrPyme, N'ViÃªn', @shelfA1,
            N'400mg x 3 láº§n/ngÃ y, uá»‘ng no sau bá»¯a Äƒn. Tá»‘i Ä‘a 1200mg/ngÃ y.',
            N'LoÃ©t dáº¡ dÃ y Ä‘ang tiáº¿n triá»ƒn, suy tháº­n, dá»‹ á»©ng Aspirin.',
            0, 6000, 15, 1, 30);

-- â‘¦ Metformin 500mg â€” tiá»ƒu Ä‘Æ°á»ng (KÃª Ä‘Æ¡n)
IF NOT EXISTS (SELECT 1 FROM Medicines WHERE MedicineName = N'Metformin 500mg')
    INSERT INTO Medicines (MedicineName, GenericName, Barcode, CategoryID, ManufacturerID,
                           Unit, ShelfID, Dosage, Contraindications,
                           IsPrescriptionRequired, SellingPrice, MinInventory, Status, ExpiryAlertDays)
    VALUES (N'Metformin 500mg', N'Metformin hydrochloride', '8934567890007',
            @catDiabetes, @mfrImex, N'ViÃªn', @shelfA2,
            N'500mg x 2-3 láº§n/ngÃ y, uá»‘ng trong hoáº·c sau bá»¯a Äƒn. TÄƒng liá»u tá»« tá»«.',
            N'Suy tháº­n (GFR < 30), suy gan náº·ng, nghiá»‡n rÆ°á»£u.',
            1, 5500, 10, 1, 60);

PRINT 'âœ“ Medicines (7 thuá»‘c) OK';

/* â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
   7. PURCHASE ORDER + BATCHES (tá»“n kho)
â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â• */
DECLARE @poID INT;
INSERT INTO PurchaseOrders (SupplierID, AccountID, Notes)
VALUES (@supplierID, @adminID, N'ÄÆ¡n nháº­p hÃ ng máº«u â€” Seed data 2026');
SET @poID = SCOPE_IDENTITY();

DECLARE @m1 INT = (SELECT MedicineID FROM Medicines WHERE MedicineName = N'Paracetamol 500mg');
DECLARE @m2 INT = (SELECT MedicineID FROM Medicines WHERE MedicineName = N'Amoxicillin 500mg');
DECLARE @m3 INT = (SELECT MedicineID FROM Medicines WHERE MedicineName = N'Vitamin C 1000mg');
DECLARE @m4 INT = (SELECT MedicineID FROM Medicines WHERE MedicineName = N'Omeprazole 20mg');
DECLARE @m5 INT = (SELECT MedicineID FROM Medicines WHERE MedicineName = N'Cetirizine 10mg');
DECLARE @m6 INT = (SELECT MedicineID FROM Medicines WHERE MedicineName = N'Ibuprofen 400mg');
DECLARE @m7 INT = (SELECT MedicineID FROM Medicines WHERE MedicineName = N'Metformin 500mg');

-- Paracetamol 500mg â€” 200 viÃªn
IF NOT EXISTS (SELECT 1 FROM Batches WHERE MedicineID = @m1 AND BatchNumber = 'PA-2024-001')
    INSERT INTO Batches (MedicineID, POID, SupplierID, BatchNumber, ManufactureDate, ExpiryDate,
                         ImportPrice, InitialQuantity, CurrentQuantity)
    VALUES (@m1, @poID, @supplierID, 'PA-2024-001', '2024-01-15', '2026-12-31', 3500, 200, 200);

-- Amoxicillin 500mg â€” 100 viÃªn nang
IF NOT EXISTS (SELECT 1 FROM Batches WHERE MedicineID = @m2 AND BatchNumber = 'AM-2024-001')
    INSERT INTO Batches (MedicineID, POID, SupplierID, BatchNumber, ManufactureDate, ExpiryDate,
                         ImportPrice, InitialQuantity, CurrentQuantity)
    VALUES (@m2, @poID, @supplierID, 'AM-2024-001', '2024-02-10', '2026-10-31', 5500, 100, 100);

-- Vitamin C 1000mg â€” 150 viÃªn sá»§i
IF NOT EXISTS (SELECT 1 FROM Batches WHERE MedicineID = @m3 AND BatchNumber = 'VC-2024-001')
    INSERT INTO Batches (MedicineID, POID, SupplierID, BatchNumber, ManufactureDate, ExpiryDate,
                         ImportPrice, InitialQuantity, CurrentQuantity)
    VALUES (@m3, @poID, @supplierID, 'VC-2024-001', '2024-03-05', '2027-03-31', 8000, 150, 150);

-- Omeprazole 20mg â€” 120 viÃªn nang
IF NOT EXISTS (SELECT 1 FROM Batches WHERE MedicineID = @m4 AND BatchNumber = 'OM-2024-001')
    INSERT INTO Batches (MedicineID, POID, SupplierID, BatchNumber, ManufactureDate, ExpiryDate,
                         ImportPrice, InitialQuantity, CurrentQuantity)
    VALUES (@m4, @poID, @supplierID, 'OM-2024-001', '2024-01-20', '2026-11-30', 4500, 120, 120);

-- Cetirizine 10mg â€” 180 viÃªn
IF NOT EXISTS (SELECT 1 FROM Batches WHERE MedicineID = @m5 AND BatchNumber = 'CE-2024-001')
    INSERT INTO Batches (MedicineID, POID, SupplierID, BatchNumber, ManufactureDate, ExpiryDate,
                         ImportPrice, InitialQuantity, CurrentQuantity)
    VALUES (@m5, @poID, @supplierID, 'CE-2024-001', '2024-02-01', '2027-01-31', 2800, 180, 180);

-- Ibuprofen 400mg â€” 160 viÃªn
IF NOT EXISTS (SELECT 1 FROM Batches WHERE MedicineID = @m6 AND BatchNumber = 'IB-2024-001')
    INSERT INTO Batches (MedicineID, POID, SupplierID, BatchNumber, ManufactureDate, ExpiryDate,
                         ImportPrice, InitialQuantity, CurrentQuantity)
    VALUES (@m6, @poID, @supplierID, 'IB-2024-001', '2024-01-10', '2026-09-30', 4200, 160, 160);

-- Metformin 500mg â€” 80 viÃªn
IF NOT EXISTS (SELECT 1 FROM Batches WHERE MedicineID = @m7 AND BatchNumber = 'ME-2024-001')
    INSERT INTO Batches (MedicineID, POID, SupplierID, BatchNumber, ManufactureDate, ExpiryDate,
                         ImportPrice, InitialQuantity, CurrentQuantity)
    VALUES (@m7, @poID, @supplierID, 'ME-2024-001', '2024-03-15', '2027-02-28', 3800, 80, 80);

-- Cáº­p nháº­t TotalValue cho PO
UPDATE PurchaseOrders
SET TotalValue = (
    SELECT ISNULL(SUM(b.ImportPrice * b.InitialQuantity), 0)
    FROM Batches b WHERE b.POID = @poID
)
WHERE POID = @poID;

PRINT 'âœ“ Batches (tá»“n kho) OK';
PRINT '';
PRINT '=== KIá»‚M TRA Káº¾T QUáº¢ ===';

SELECT
    m.MedicineCode,
    m.MedicineName,
    c.CategoryName,
    mf.Name AS Manufacturer,
    m.Unit,
    m.SellingPrice,
    ISNULL(SUM(b.CurrentQuantity), 0) AS TonKho,
    CASE WHEN m.IsPrescriptionRequired = 1 THEN N'KÃª Ä‘Æ¡n' ELSE N'OTC' END AS LoaiThuoc
FROM Medicines m
JOIN Categories    c  ON c.CategoryID     = m.CategoryID
JOIN Manufacturers mf ON mf.ManufacturerID = m.ManufacturerID
LEFT JOIN Batches  b  ON b.MedicineID     = m.MedicineID
WHERE m.MedicineName IN (
    N'Paracetamol 500mg', N'Amoxicillin 500mg', N'Vitamin C 1000mg',
    N'Omeprazole 20mg',   N'Cetirizine 10mg',   N'Ibuprofen 400mg',
    N'Metformin 500mg'
)
GROUP BY m.MedicineCode, m.MedicineName, c.CategoryName, mf.Name, m.Unit,
         m.SellingPrice, m.IsPrescriptionRequired
ORDER BY m.MedicineCode;

PRINT '=== HOÃ€N THÃ€NH ===';

