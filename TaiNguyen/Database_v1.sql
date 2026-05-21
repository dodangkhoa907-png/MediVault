/* ================================================================
   MEDIVAULT DB v3.1 FINAL — PHIEN BAN HOAN CHINH
   ----------------------------------------------------------------
   Nhóm  : MediVault | DBMS: SQL Server 2019/2022
   ----------------------------------------------------------------
   11 Khu vuc | 6 Triggers | 7 Views | 4 Stored Procedures
   ================================================================ */

USE master;
GO
IF DB_ID('PharmacyPro_DB') IS NOT NULL
BEGIN
    ALTER DATABASE PharmacyPro_DB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE PharmacyPro_DB;
END
GO
CREATE DATABASE PharmacyPro_DB;
GO
USE PharmacyPro_DB;
GO

/* ================================================================
   BƯỚC 1 — TẠO TẤT CẢ BẢNG (không có FK)
   ================================================================ */

-- KV 1: Tài khoản & Phân quyền
CREATE TABLE Roles (
    RoleID   INT PRIMARY KEY IDENTITY(1,1),
    RoleName NVARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Accounts (
    AccountID    INT PRIMARY KEY IDENTITY(1,1),
    Username     VARCHAR(50)   NOT NULL UNIQUE,
    PasswordHash NVARCHAR(max) NOT NULL,
    FullName     NVARCHAR(100) NOT NULL,
    Email        VARCHAR(100)  NULL,
    Phone        VARCHAR(15)   NULL,
    RoleID       INT           NOT NULL,
    CitizenId           VARCHAR(12)   NOT NULL,
    ProfessionalCertNo  NVARCHAR(100) NULL,
    ProfessionalCertExp DATE          NULL,
    Position            NVARCHAR(100) NULL,
    TrainingDate        DATE          NULL,
    IsActive     BIT           NOT NULL DEFAULT 1,
    CreatedAt    DATETIME      NOT NULL DEFAULT GETDATE(),
    LastLoginAt  DATETIME      NULL,
    FaceEnrollmentPath NVARCHAR(500) NULL,   -- Duong dan du lieu khuon mat / Để chấm công
    CONSTRAINT CK_Account_Email CHECK (Email IS NULL OR Email LIKE '%_@_%._%')
);

-- KV 2: Ca làm việc & Audit Log
CREATE TABLE Shifts (
    ShiftID      INT PRIMARY KEY IDENTITY(1,1),
    AccountID    INT           NOT NULL,
    StartTime    DATETIME      NOT NULL DEFAULT GETDATE(),
    EndTime      DATETIME       NULL,
    OpeningCash  DECIMAL(18,2) NOT NULL DEFAULT 0,
    ClosingCash  DECIMAL(18,2) NULL,
    Notes        NVARCHAR(255) NULL,
    GracePeriodMinutes INT NOT NULL DEFAULT 5,
CONSTRAINT CK_Shift_Grace CHECK (GracePeriodMinutes >= 0 AND GracePeriodMinutes <= 8),    -- Gioi han thoi gian cho phep cham cong muon
    CONSTRAINT CK_Shift_Time CHECK (EndTime IS NULL OR EndTime >= StartTime),
    CONSTRAINT CK_Shift_Cash CHECK (OpeningCash >= 0 AND (ClosingCash IS NULL OR ClosingCash >= 0))
);
    
CREATE TABLE AuditLog (         --Thiết kế theo kiểu Appand-Only, không thể UPDATE/DELETE, đây là lịch sử hoạt động của người dùng
    LogID       BIGINT PRIMARY KEY IDENTITY(1,1),
    AccountID   INT           NULL,
    Action      VARCHAR(100)  NOT NULL,   -- Tang len 100 theo gop y
    EntityType  VARCHAR(50)   NULL,
    EntityID    INT           NULL,
    Description NVARCHAR(500) NULL,
    IPAddress   VARCHAR(45)   NULL,
    CreatedAt   DATETIME      NOT NULL DEFAULT GETDATE()
);

-- KV 3: Danh mục cơ bản
CREATE TABLE Categories (
    CategoryID   INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(100) NOT NULL UNIQUE,
    Description  NVARCHAR(255) NULL
);

CREATE TABLE Manufacturers (
    ManufacturerID INT PRIMARY KEY IDENTITY(1,1),
    Name           NVARCHAR(200) NOT NULL,
    Country        NVARCHAR(100) NULL,
    Address        NVARCHAR(255) NULL
);

CREATE TABLE Suppliers (
    SupplierID    INT PRIMARY KEY IDENTITY(1,1),
    SupplierName  NVARCHAR(200) NOT NULL,
    ContactName   NVARCHAR(100) NULL,
    Phone         VARCHAR(15)   NULL,
    Email         VARCHAR(100)  NULL,
    Address       NVARCHAR(255) NULL,
    LicenseNumber NVARCHAR(50)  NULL,
    IsActive      BIT           NOT NULL DEFAULT 1
);

-- KV 4: Kệ & Ngăn máy
CREATE TABLE Shelves (
    ShelfID         INT PRIMARY KEY IDENTITY(1,1),
    ShelfName       NVARCHAR(50)  NOT NULL UNIQUE,
    MachineSlotCode VARCHAR(50)   NULL UNIQUE,
    MotorID         VARCHAR(50)   NULL,
    LocationNotes   NVARCHAR(255) NULL,
    ShelfType VARCHAR(20) NOT NULL DEFAULT 'RETAIL',
    IsAutomated     AS (CASE WHEN MachineSlotCode IS NOT NULL
                             THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END) PERSISTED,
    CONSTRAINT CK_Shelf_Type CHECK (ShelfType IN ('RETAIL','STORAGE','MACHINE'))
);

-- KV 5: Thuốc & Lô thuốc
CREATE TABLE Medicines (
    MedicineID             INT PRIMARY KEY IDENTITY(1,1),
    MedicineCode           AS ('MED' + RIGHT('000000' + CAST(MedicineID AS VARCHAR(6)), 6)) PERSISTED,
    MedicineName           NVARCHAR(200) NOT NULL,
    GenericName            NVARCHAR(200) NULL,
    Barcode                VARCHAR(50)   NULL UNIQUE,
    RegistrationNumber     NVARCHAR(50)  NULL,
    CategoryID             INT           NOT NULL,
    ManufacturerID         INT           NOT NULL,
    Unit                   NVARCHAR(50)  NOT NULL,
    ShelfID                INT           NOT NULL,
    StorageTempMin         DECIMAL(5,2)  NULL,
    StorageTempMax         DECIMAL(5,2)  NULL,
    StorageConditions      NVARCHAR(255) NULL,

    -- Lieu dung THAM KHAO chung (in tren hop thuoc)
    Dosage                 NVARCHAR(500) NOT NULL,   -- "Nguoi lon: 1-2 vien/lan"
    DefaultDosageMin       DECIMAL(6,2)  NULL,       -- Lieu toi thieu: 0.5 vien
    DefaultDosageMax       DECIMAL(6,2)  NULL,       -- Lieu toi da: 2 vien
    DosageWarning          NVARCHAR(255) NULL,       -- "Khong qua 8 vien/ngay"

    Contraindications      NVARCHAR(500) NULL,
    IsPrescriptionRequired BIT           NOT NULL DEFAULT 0,
    SellingPrice           DECIMAL(18,2) NOT NULL DEFAULT 0,
    MinInventory           INT           NOT NULL DEFAULT 10,
    Status                 BIT           NOT NULL DEFAULT 1,
    CreatedAt              DATETIME      NOT NULL DEFAULT GETDATE(),
    
    ExpiryAlertDays INT NOT NULL DEFAULT 60, -- Ý nghĩa: cảnh báo trước bao nhiêu ngày?
    CONSTRAINT CK_Med_Price      CHECK (SellingPrice >= 0),
    CONSTRAINT CK_Med_MinInv     CHECK (MinInventory >= 0),
    CONSTRAINT CK_Med_Temp       CHECK (StorageTempMin IS NULL OR StorageTempMax IS NULL
                                        OR StorageTempMin <= StorageTempMax),
    CONSTRAINT CK_Med_DosageMin  CHECK (DefaultDosageMin IS NULL OR DefaultDosageMin > 0),
    CONSTRAINT CK_Med_DosageMax  CHECK (DefaultDosageMax IS NULL OR DefaultDosageMax > 0),
    CONSTRAINT CK_Med_DosageRange CHECK (DefaultDosageMin IS NULL OR DefaultDosageMax IS NULL
                                         OR DefaultDosageMin <= DefaultDosageMax),
    CONSTRAINT CK_Med_SellPrice  CHECK (Status = 0 OR SellingPrice > 0),
    CONSTRAINT CK_Med_AlertDays  CHECK (ExpiryAlertDays > 0)
);

CREATE TABLE PurchaseOrders (
    POID       INT PRIMARY KEY IDENTITY(1,1),
    POCode     AS ('PN' + RIGHT('000000' + CAST(POID AS VARCHAR(6)), 6)) PERSISTED,
    SupplierID INT           NOT NULL,
    AccountID  INT           NOT NULL,
    OrderDate  DATETIME      NOT NULL DEFAULT GETDATE(),
    TotalValue DECIMAL(18,2) NOT NULL DEFAULT 0,
    Notes      NVARCHAR(255) NULL,
    CONSTRAINT CK_PO_Total CHECK (TotalValue >= 0)
);

CREATE TABLE Batches (
    BatchID         INT PRIMARY KEY IDENTITY(1,1),
    MedicineID      INT           NOT NULL,
    POID            INT           NOT NULL,
    SupplierID      INT           NOT NULL,
    BatchNumber     VARCHAR(50)   NOT NULL,
    ManufactureDate DATE          NULL,
    ImportDate      DATE          NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    ExpiryDate      DATE          NOT NULL,
    ImportPrice     DECIMAL(18,2) NOT NULL DEFAULT 0,
    InitialQuantity INT           NOT NULL,
    CurrentQuantity INT           NOT NULL,
    CreatedAt       DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT CK_Batch_Qty   CHECK (CurrentQuantity >= 0 AND CurrentQuantity <= InitialQuantity),
    CONSTRAINT CK_Batch_Price CHECK (ImportPrice >= 0),
    CONSTRAINT CK_Batch_Dates CHECK (ManufactureDate IS NULL OR ExpiryDate > ManufactureDate),
    CONSTRAINT UQ_Batch       UNIQUE (MedicineID, BatchNumber)
);

CREATE TABLE StockMovements (
    MovementID   INT PRIMARY KEY IDENTITY(1,1),
    BatchID      INT           NOT NULL,
    MovementType VARCHAR(20)   NOT NULL,
    Quantity     INT           NOT NULL,
    RefTable     VARCHAR(50)   NULL,
    RefID        INT           NULL,
    AccountID    INT           NOT NULL,
    Notes        NVARCHAR(255) NULL,
    CreatedAt    DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT CK_SM_Type CHECK (MovementType IN ('IN','OUT','RETURN','EXPIRED','ADJUSTMENT'))
);

-- KV 6: Khach hang & Don thuoc bac si
CREATE TABLE Customers (
    CustomerID     INT PRIMARY KEY IDENTITY(1,1),
    CustomerName   NVARCHAR(100) NOT NULL,
    Phone          VARCHAR(15)   NULL UNIQUE,
    Email          VARCHAR(100)  NULL,
    Address        NVARCHAR(255) NULL,
    DateOfBirth    DATE          NULL,
    Gender         VARCHAR(10)   NULL,
    NationalId     VARCHAR(12)   NULL,          -- NULL: khach vang lai
    Occupation     NVARCHAR(100) NULL,
    AllergyHistory NVARCHAR(500) NULL,
    ChronicDisease NVARCHAR(500) NULL,
    CreatedAt      DATETIME      NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT CK_Cust_Gender CHECK (Gender IS NULL OR Gender IN ('M','F','OTHER')),
    CONSTRAINT CK_Cust_DOB    CHECK (DateOfBirth IS NULL
                               OR DateOfBirth < CAST(GETDATE() AS DATE))
);

CREATE TABLE Prescriptions (
    PrescriptionID   INT PRIMARY KEY IDENTITY(1,1),
    CustomerID       INT           NOT NULL,
    DoctorName       NVARCHAR(100) NULL,
    HospitalName     NVARCHAR(200) NULL,
    PrescriptionDate DATE          NULL,
    ImagePath        NVARCHAR(500) NULL,
    Notes            NVARCHAR(500) NULL,
    CreatedAt        DATETIME      NOT NULL DEFAULT GETDATE()
);

CREATE TABLE PrescriptionDetails (
    PrescriptionDetailID INT PRIMARY KEY IDENTITY(1,1),
    PrescriptionID       INT           NOT NULL,
    MedicineID           INT           NOT NULL,
    DosageQuantity       DECIMAL(6,2)  NOT NULL,  -- 1, 2, 0.5 vien
    DosageUnit           NVARCHAR(50)  NOT NULL,  -- Vien / Goi / Ong / ml
    Frequency            NVARCHAR(100) NULL,       -- "2 lan/ngay", "sang-trua-toi"
    Duration             INT           NULL,       -- So ngay dung thuoc
    UsageInstruction     NVARCHAR(255) NOT NULL,   -- "Uong sau khi an no"
    TotalPrescribedQty   INT           NOT NULL,   -- Tong so luong BS dan mua
    CONSTRAINT CK_PrescDetail_Qty         CHECK (TotalPrescribedQty > 0),
    CONSTRAINT CK_PrescDetail_DosageQty   CHECK (DosageQuantity > 0),
    CONSTRAINT CK_PrescDetail_Duration    CHECK (Duration IS NULL OR Duration > 0),
    CONSTRAINT CK_PrescDetail_Instruction CHECK (LEN(LTRIM(RTRIM(UsageInstruction))) > 0)
);
GO

-- KV 7: Bán hàng
CREATE TABLE Invoices (
    InvoiceID      INT PRIMARY KEY IDENTITY(1,1),
    InvoiceCode    AS ('HD' + RIGHT('000000' + CAST(InvoiceID AS VARCHAR(6)), 6)) PERSISTED,
    CreatedAt      DATETIME      NOT NULL DEFAULT GETDATE(),
    AccountID      INT           NOT NULL,
    ShiftID        INT           NULL,
    CustomerID     INT           NULL,
    PrescriptionID INT           NULL,
    FinalAmount    DECIMAL(18,2) NOT NULL DEFAULT 0,
    DiscountAmount DECIMAL(18,2) NOT NULL DEFAULT 0,
    PaymentMethod  VARCHAR(20)   NOT NULL DEFAULT 'CASH',
    Status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    CONSTRAINT CK_Inv_Amount CHECK (FinalAmount >= 0 AND DiscountAmount >= 0),
    CONSTRAINT CK_Inv_Pay    CHECK (PaymentMethod IN ('CASH','CARD','TRANSFER','EWALLET','QR_CODE')),
    CONSTRAINT CK_Inv_Status CHECK (Status IN ('COMPLETED','CANCELLED','PENDING'))
);

CREATE TABLE InvoiceDetails (
    DetailID  INT PRIMARY KEY IDENTITY(1,1),
    InvoiceID INT           NOT NULL,
    BatchID   INT           NOT NULL,
    Quantity  INT           NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    SubTotal  AS (Quantity * UnitPrice) PERSISTED,
    CONSTRAINT CK_IDt_Qty   CHECK (Quantity > 0),
    CONSTRAINT CK_IDt_Price CHECK (UnitPrice >= 0)
);

-- KV 8: Trả hàng
CREATE TABLE Returns (
    ReturnID     INT PRIMARY KEY IDENTITY(1,1),
    ReturnType   VARCHAR(30)   NOT NULL,
    BatchID      INT           NOT NULL,
    InvoiceID    INT           NULL,
    Quantity     INT           NOT NULL,
    Reason       NVARCHAR(500) NOT NULL,
    AccountID    INT           NOT NULL,
    RestoreStock BIT           NOT NULL DEFAULT 0,
    CreatedAt    DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT CK_Ret_Inv CHECK (ReturnType <> 'CUSTOMER_RETURN' OR InvoiceID IS NOT NULL),
    CONSTRAINT CK_Ret_Type CHECK (ReturnType IN ('CUSTOMER_RETURN','EXPIRED_DESTROY','RECALL')),
    CONSTRAINT CK_Ret_Qty  CHECK (Quantity > 0)
);

-- KV 9: Máy cấp thuốc
CREATE TABLE MachineCommands (
    CommandID       INT PRIMARY KEY IDENTITY(1,1),
    DetailID        INT           NOT NULL, -- FK → InvoiceDetails.DetailID (Robot gap nhung gi khach tra tien)
    MachineSlotCode VARCHAR(50)   NOT NULL,
    Quantity        INT           NOT NULL,
    Status          VARCHAR(20)   NOT NULL DEFAULT 'PENDING',
    CreatedAt       DATETIME      NOT NULL DEFAULT GETDATE(),
    ProcessedAt     DATETIME      NULL,
    RetryCount      INT           NOT NULL DEFAULT 0,
    ErrorMessage    NVARCHAR(500) NULL,
    CONSTRAINT CK_MC_Status CHECK (Status IN ('PENDING','PROCESSING','DONE','FAILED','CANCELLED')),
    CONSTRAINT CK_MC_Qty    CHECK (Quantity > 0),
    CONSTRAINT CK_MC_Retry  CHECK (RetryCount >= 0 AND RetryCount <= 5)
);

-- KV 10: Thẻ tích điểm
CREATE TABLE LoyaltyTiers (
    TierID      INT PRIMARY KEY IDENTITY(1,1),
    TierName    NVARCHAR(50)  NOT NULL UNIQUE,
    MinPoints   INT           NOT NULL DEFAULT 0,
    DiscountPct DECIMAL(5,2)  NOT NULL DEFAULT 0,
    Description NVARCHAR(255) NULL
);

CREATE TABLE LoyaltyCards (
    CardID      INT PRIMARY KEY IDENTITY(1,1),
    CardCode    AS ('CARD' + RIGHT('000000' + CAST(CardID AS VARCHAR(6)), 6)) PERSISTED,
    CustomerID  INT           NOT NULL UNIQUE,
    TierID      INT           NOT NULL DEFAULT 1,
    TotalPoints INT           NOT NULL DEFAULT 0,
    UsedPoints  INT           NOT NULL DEFAULT 0,
    IssuedAt    DATETIME      NOT NULL DEFAULT GETDATE(),
    ExpiredAt   DATETIME      NULL,
    IsActive    BIT           NOT NULL DEFAULT 1,
    CONSTRAINT CK_LC_Points CHECK (TotalPoints >= 0 AND UsedPoints >= 0
                                   AND UsedPoints <= TotalPoints)
);

CREATE TABLE PointTransactions (
    TransID       INT PRIMARY KEY IDENTITY(1,1),
    CardID        INT           NOT NULL,
    InvoiceID     INT           NULL,
    TransType     VARCHAR(20)   NOT NULL,
    Points        INT           NOT NULL,
    BalanceBefore INT           NOT NULL,
    BalanceAfter  INT           NOT NULL,
    Note          NVARCHAR(255) NULL,
    CreatedAt     DATETIME      NOT NULL DEFAULT GETDATE(),
    AccountID     INT           NULL,
    CONSTRAINT CK_PT_Type CHECK (TransType IN ('EARN','REDEEM','EXPIRE','ADJUST'))
);

-- KV 11: Order Logs
CREATE TABLE OrderLogs (
    LogID      BIGINT PRIMARY KEY IDENTITY(1,1),
    InvoiceID  INT           NOT NULL,
    OldStatus  VARCHAR(20)   NULL,
    NewStatus  VARCHAR(20)   NOT NULL,
    ChangedAt  DATETIME      NOT NULL DEFAULT GETDATE(),
    AccountID  INT           NULL,
    Source     VARCHAR(30)   NOT NULL DEFAULT 'SYSTEM',
    Note       NVARCHAR(500) NULL,
    CONSTRAINT CK_OL_Status CHECK (NewStatus IN ('PENDING','COMPLETED','CANCELLED','REFUNDED'))
);
GO


/* ================================================================
   BƯỚC 2 — THÊM FOREIGN KEYS (sau khi tất cả bảng đã tồn tại)
   ================================================================ */

-- KV 1
ALTER TABLE Accounts        ADD CONSTRAINT FK_Account_Role    FOREIGN KEY (RoleID)         REFERENCES Roles(RoleID);
-- KV 2
ALTER TABLE Shifts           ADD CONSTRAINT FK_Shift_Account   FOREIGN KEY (AccountID)      REFERENCES Accounts(AccountID);
ALTER TABLE AuditLog         ADD CONSTRAINT FK_Audit_Account   FOREIGN KEY (AccountID)      REFERENCES Accounts(AccountID);
-- KV 5
ALTER TABLE Medicines        ADD CONSTRAINT FK_Med_Cat         FOREIGN KEY (CategoryID)     REFERENCES Categories(CategoryID);
ALTER TABLE Medicines        ADD CONSTRAINT FK_Med_Manuf       FOREIGN KEY (ManufacturerID) REFERENCES Manufacturers(ManufacturerID);
ALTER TABLE Medicines        ADD CONSTRAINT FK_Med_Shelf       FOREIGN KEY (ShelfID)        REFERENCES Shelves(ShelfID);
ALTER TABLE PurchaseOrders   ADD CONSTRAINT FK_PO_Supplier     FOREIGN KEY (SupplierID)     REFERENCES Suppliers(SupplierID);
ALTER TABLE PurchaseOrders   ADD CONSTRAINT FK_PO_Account      FOREIGN KEY (AccountID)      REFERENCES Accounts(AccountID);
ALTER TABLE Batches          ADD CONSTRAINT FK_Batch_Med       FOREIGN KEY (MedicineID)     REFERENCES Medicines(MedicineID);
ALTER TABLE Batches          ADD CONSTRAINT FK_Batch_PO        FOREIGN KEY (POID)           REFERENCES PurchaseOrders(POID);
ALTER TABLE Batches          ADD CONSTRAINT FK_Batch_Supplier  FOREIGN KEY (SupplierID)     REFERENCES Suppliers(SupplierID);
ALTER TABLE StockMovements   ADD CONSTRAINT FK_SM_Batch        FOREIGN KEY (BatchID)        REFERENCES Batches(BatchID);
ALTER TABLE StockMovements   ADD CONSTRAINT FK_SM_Account      FOREIGN KEY (AccountID)      REFERENCES Accounts(AccountID);

-- KV 6 (bo sung PrescriptionDetails)
ALTER TABLE Prescriptions       ADD CONSTRAINT FK_Pres_Cust
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID);
ALTER TABLE PrescriptionDetails ADD CONSTRAINT FK_PrescD_Pres
    FOREIGN KEY (PrescriptionID) REFERENCES Prescriptions(PrescriptionID)
    ON DELETE CASCADE;
ALTER TABLE PrescriptionDetails ADD CONSTRAINT FK_PrescD_Med
    FOREIGN KEY (MedicineID) REFERENCES Medicines(MedicineID);
-- KV 7
ALTER TABLE Invoices         ADD CONSTRAINT FK_Inv_Account     FOREIGN KEY (AccountID)      REFERENCES Accounts(AccountID);
ALTER TABLE Invoices         ADD CONSTRAINT FK_Inv_Shift       FOREIGN KEY (ShiftID)        REFERENCES Shifts(ShiftID);
ALTER TABLE Invoices         ADD CONSTRAINT FK_Inv_Cust        FOREIGN KEY (CustomerID)     REFERENCES Customers(CustomerID);
ALTER TABLE Invoices         ADD CONSTRAINT FK_Inv_Pres        FOREIGN KEY (PrescriptionID) REFERENCES Prescriptions(PrescriptionID);
ALTER TABLE InvoiceDetails   ADD CONSTRAINT FK_IDt_Inv         FOREIGN KEY (InvoiceID)      REFERENCES Invoices(InvoiceID) ON DELETE CASCADE;
ALTER TABLE InvoiceDetails   ADD CONSTRAINT FK_IDt_Batch       FOREIGN KEY (BatchID)        REFERENCES Batches(BatchID);
-- KV 8
ALTER TABLE Returns          ADD CONSTRAINT FK_Ret_Batch       FOREIGN KEY (BatchID)        REFERENCES Batches(BatchID);
ALTER TABLE Returns          ADD CONSTRAINT FK_Ret_Inv         FOREIGN KEY (InvoiceID)      REFERENCES Invoices(InvoiceID);
ALTER TABLE Returns          ADD CONSTRAINT FK_Ret_Account     FOREIGN KEY (AccountID)      REFERENCES Accounts(AccountID);
-- KV 9
ALTER TABLE MachineCommands  ADD CONSTRAINT FK_MC_Detail       FOREIGN KEY (DetailID)       REFERENCES InvoiceDetails(DetailID) ON DELETE CASCADE;
-- KV 10
ALTER TABLE LoyaltyCards     ADD CONSTRAINT FK_LC_Customer     FOREIGN KEY (CustomerID)     REFERENCES Customers(CustomerID);
ALTER TABLE LoyaltyCards     ADD CONSTRAINT FK_LC_Tier         FOREIGN KEY (TierID)         REFERENCES LoyaltyTiers(TierID);
ALTER TABLE PointTransactions ADD CONSTRAINT FK_PT_Card        FOREIGN KEY (CardID)         REFERENCES LoyaltyCards(CardID);
ALTER TABLE PointTransactions ADD CONSTRAINT FK_PT_Invoice     FOREIGN KEY (InvoiceID)      REFERENCES Invoices(InvoiceID);
ALTER TABLE PointTransactions ADD CONSTRAINT FK_PT_Account     FOREIGN KEY (AccountID)      REFERENCES Accounts(AccountID);
-- KV 11
ALTER TABLE OrderLogs        ADD CONSTRAINT FK_OL_Invoice      FOREIGN KEY (InvoiceID)      REFERENCES Invoices(InvoiceID);
ALTER TABLE OrderLogs        ADD CONSTRAINT FK_OL_Account      FOREIGN KEY (AccountID)      REFERENCES Accounts(AccountID);
GO


/* ================================================================
   BƯỚC 3 — INDEXES
   ================================================================ */

CREATE INDEX IX_Med_Name       ON Medicines(MedicineName);
CREATE INDEX IX_Med_Barcode    ON Medicines(Barcode)            WHERE Barcode IS NOT NULL;
CREATE INDEX IX_Med_SDK        ON Medicines(RegistrationNumber) WHERE RegistrationNumber IS NOT NULL;
CREATE INDEX IX_Batch_Expiry   ON Batches(ExpiryDate);
CREATE INDEX IX_Batch_Med_FIFO ON Batches(MedicineID, ExpiryDate);
CREATE INDEX IX_Inv_Date       ON Invoices(CreatedAt);
CREATE INDEX IX_Inv_Account    ON Invoices(AccountID, CreatedAt);
CREATE INDEX IX_Inv_Shift      ON Invoices(ShiftID);
CREATE INDEX IX_MC_Status      ON MachineCommands(Status, CreatedAt);
CREATE INDEX IX_Cust_Phone     ON Customers(Phone);
CREATE INDEX IX_SM_Batch       ON StockMovements(BatchID, CreatedAt);
CREATE INDEX IX_Audit_Date     ON AuditLog(CreatedAt);
CREATE INDEX IX_Audit_Account  ON AuditLog(AccountID, CreatedAt);
CREATE INDEX IX_Ret_Batch      ON Returns(BatchID);
CREATE INDEX IX_LC_Customer    ON LoyaltyCards(CustomerID);
CREATE INDEX IX_PT_Card        ON PointTransactions(CardID, CreatedAt);
CREATE INDEX IX_PT_Invoice     ON PointTransactions(InvoiceID);
CREATE INDEX IX_OL_Invoice     ON OrderLogs(InvoiceID, ChangedAt);
CREATE INDEX IX_OL_Date        ON OrderLogs(ChangedAt);
GO


/* ================================================================
   BƯỚC 4 — TRIGGERS
   ================================================================ */

-- TRG 1: Bán hàng → trừ kho + log + lệnh máy
CREATE OR ALTER TRIGGER TRG_ProcessSaleAndMachine
ON InvoiceDetails
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1 FROM inserted i
        JOIN Batches b ON b.BatchID = i.BatchID
        GROUP BY i.BatchID, b.CurrentQuantity, b.ExpiryDate
        HAVING SUM(i.Quantity) > MIN(b.CurrentQuantity)
            OR MIN(b.ExpiryDate) < CAST(GETDATE() AS DATE)
    )
    BEGIN
        RAISERROR(N'Lo thuoc khong du ton kho hoac da het han.', 16, 1);
        ROLLBACK TRANSACTION; RETURN;
    END

    UPDATE b SET b.CurrentQuantity = b.CurrentQuantity - x.TotalQty
    FROM Batches b
    JOIN (SELECT BatchID, SUM(Quantity) AS TotalQty FROM inserted GROUP BY BatchID) x
      ON b.BatchID = x.BatchID;

    INSERT INTO StockMovements (BatchID, MovementType, Quantity, RefTable, RefID, AccountID, Notes)
    SELECT i.BatchID, 'OUT', -i.Quantity, 'Invoices', inv.InvoiceID, inv.AccountID,
           N'Ban hang - ' + inv.InvoiceCode
    FROM inserted i
    JOIN Invoices inv ON inv.InvoiceID = i.InvoiceID;

    INSERT INTO MachineCommands (DetailID, MachineSlotCode, Quantity)
    SELECT i.DetailID, s.MachineSlotCode, i.Quantity
    FROM inserted i
    JOIN Batches   b ON b.BatchID    = i.BatchID
    JOIN Medicines m ON m.MedicineID = b.MedicineID
    JOIN Shelves   s ON s.ShelfID    = m.ShelfID
    WHERE s.MachineSlotCode IS NOT NULL;
END;
GO

-- TRG 2: Cập nhật tổng tiền HĐ
CREATE OR ALTER TRIGGER TRG_UpdateInvoiceTotal
ON InvoiceDetails
AFTER INSERT, DELETE, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @ids TABLE(InvoiceID INT PRIMARY KEY);
    INSERT INTO @ids SELECT DISTINCT InvoiceID FROM inserted
    UNION SELECT DISTINCT InvoiceID FROM deleted;

    UPDATE inv
    SET FinalAmount = ISNULL(t.Total, 0) - inv.DiscountAmount
    FROM Invoices inv
    JOIN @ids x ON x.InvoiceID = inv.InvoiceID
    LEFT JOIN (SELECT InvoiceID, SUM(SubTotal) AS Total
               FROM InvoiceDetails GROUP BY InvoiceID) t
      ON t.InvoiceID = inv.InvoiceID;
END;
GO

-- TRG 3: Nhập kho → log
CREATE OR ALTER TRIGGER TRG_LogStockIn
ON Batches
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO StockMovements (BatchID, MovementType, Quantity, RefTable, RefID, AccountID, Notes)
    SELECT i.BatchID, 'IN', i.InitialQuantity, 'PurchaseOrders', i.POID, p.AccountID,
           N'Nhap lo ' + i.BatchNumber
    FROM inserted i
    LEFT JOIN PurchaseOrders p ON p.POID = i.POID;
END;
GO

-- TRG 4: Trả hàng → cập nhật kho + log
CREATE OR ALTER TRIGGER TRG_ProcessReturn
ON Returns
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE b SET b.CurrentQuantity = b.CurrentQuantity + i.Quantity
    FROM Batches b JOIN inserted i ON i.BatchID = b.BatchID
    WHERE i.RestoreStock = 1;

    INSERT INTO StockMovements (BatchID, MovementType, Quantity, RefTable, RefID, AccountID, Notes)
    SELECT i.BatchID,
           CASE WHEN i.ReturnType = 'EXPIRED_DESTROY' THEN 'EXPIRED'
                WHEN i.ReturnType = 'CUSTOMER_RETURN'  THEN 'RETURN'
                ELSE 'ADJUSTMENT' END,
           CASE WHEN i.RestoreStock = 1 THEN i.Quantity ELSE -i.Quantity END,
           'Returns', i.ReturnID, i.AccountID,
           i.ReturnType + ' - ' + i.Reason
    FROM inserted i;
END;
GO

-- TRG 5: Tích điểm tự động sau HĐ COMPLETED
CREATE OR ALTER TRIGGER TRG_EarnLoyaltyPoints
ON Invoices
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT EXISTS (SELECT 1 FROM inserted WHERE Status = 'COMPLETED' AND CustomerID IS NOT NULL)
        RETURN;

    DECLARE @invID INT, @custID INT, @amount DECIMAL(18,2);
    DECLARE @cardID INT, @oldPts INT, @earnPts INT;

    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT InvoiceID, CustomerID, FinalAmount FROM inserted
        WHERE Status = 'COMPLETED' AND CustomerID IS NOT NULL;

    OPEN cur;
    FETCH NEXT FROM cur INTO @invID, @custID, @amount;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM LoyaltyCards WHERE CustomerID = @custID)
            INSERT INTO LoyaltyCards (CustomerID, TierID) VALUES (@custID, 1);

        SELECT @cardID = CardID, @oldPts = TotalPoints
        FROM LoyaltyCards WHERE CustomerID = @custID;

        SET @earnPts = CAST(@amount / 10000 AS INT);

        IF @earnPts > 0
        BEGIN
            UPDATE LoyaltyCards SET TotalPoints = TotalPoints + @earnPts WHERE CardID = @cardID;

            INSERT INTO PointTransactions
                (CardID, InvoiceID, TransType, Points, BalanceBefore, BalanceAfter, Note)
            VALUES (@cardID, @invID, 'EARN', @earnPts, @oldPts, @oldPts + @earnPts,
                    'Tich diem HD' + RIGHT('000000' + CAST(@invID AS VARCHAR(6)), 6));

            UPDATE lc SET lc.TierID = t.TierID
            FROM LoyaltyCards lc
            CROSS APPLY (
                SELECT TOP 1 TierID FROM LoyaltyTiers
                WHERE MinPoints <= lc.TotalPoints ORDER BY MinPoints DESC
            ) t
            WHERE lc.CardID = @cardID;
        END
        FETCH NEXT FROM cur INTO @invID, @custID, @amount;
    END
    CLOSE cur; DEALLOCATE cur;
END;
GO

-- TRG 6: Log trạng thái hóa đơn
CREATE OR ALTER TRIGGER TRG_LogOrderStatus
ON Invoices
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO OrderLogs (InvoiceID, OldStatus, NewStatus, AccountID, Source, Note)
    SELECT i.InvoiceID, NULL, i.Status, i.AccountID, 'SYSTEM',
           'Tao hoa don - ' + i.InvoiceCode
    FROM inserted i
    WHERE NOT EXISTS (SELECT 1 FROM deleted);

    INSERT INTO OrderLogs (InvoiceID, OldStatus, NewStatus, AccountID, Source, Note)
    SELECT i.InvoiceID, d.Status, i.Status, i.AccountID, 'MANUAL',
           'Cap nhat: ' + d.Status + ' -> ' + i.Status
    FROM inserted i JOIN deleted d ON d.InvoiceID = i.InvoiceID
    WHERE i.Status <> d.Status;
END;
GO

CREATE OR ALTER TRIGGER TRG_AssignGracePeriodShift
ON Invoices
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    -- Voi moi HĐ vua tao co ShiftID NULL hoac ShiftID la ca moi
    -- Kiem tra xem co nam trong Grace Period cua ca cu khong

    UPDATE inv
    SET inv.ShiftID = old_shift.ShiftID
    FROM Invoices inv
    JOIN inserted i ON i.InvoiceID = inv.InvoiceID
    -- Tim ca cu: da dong, cung AccountID, vua dong trong GracePeriodMinutes
    CROSS APPLY (
        SELECT TOP 1 
            s.ShiftID,
            s.GracePeriodMinutes
        FROM Shifts s
        WHERE s.AccountID = i.AccountID
          AND s.EndTime IS NOT NULL
          AND s.EndTime >= DATEADD(MINUTE, -s.GracePeriodMinutes, i.CreatedAt)
          AND s.EndTime <= i.CreatedAt
        ORDER BY s.EndTime DESC
    ) old_shift
    WHERE i.ShiftID IS NULL 
       OR EXISTS (
            SELECT 1 FROM Shifts new_s
            WHERE new_s.ShiftID = i.ShiftID
              AND new_s.StartTime >= DATEADD(MINUTE, -old_shift.GracePeriodMinutes, i.CreatedAt)
       );
END;
GO


/* ================================================================
   BƯỚC 5 — VIEWS
   ================================================================ */

CREATE OR ALTER VIEW V_MedicineStock AS
SELECT m.MedicineID, m.MedicineCode, m.MedicineName, m.Unit,
       ISNULL(SUM(b.CurrentQuantity), 0) AS TotalStock, m.MinInventory,
       CASE WHEN ISNULL(SUM(b.CurrentQuantity),0) <= m.MinInventory THEN 1 ELSE 0 END AS IsLowStock
FROM Medicines m
LEFT JOIN Batches b ON b.MedicineID = m.MedicineID AND b.ExpiryDate > CAST(GETDATE() AS DATE)
GROUP BY m.MedicineID, m.MedicineCode, m.MedicineName, m.Unit, m.MinInventory;
GO

CREATE OR ALTER VIEW V_ExpiringBatches AS
SELECT
    b.BatchID, b.BatchNumber,
    m.MedicineName, m.MedicineCode,
    b.CurrentQuantity, b.ExpiryDate,
    DATEDIFF(DAY, GETDATE(), b.ExpiryDate) AS DaysLeft,
    m.ExpiryAlertDays,
    -- Phan loai muc do canh bao
    CASE
        WHEN DATEDIFF(DAY, GETDATE(), b.ExpiryDate) <= 0
            THEN 'HET_HAN'
        WHEN DATEDIFF(DAY, GETDATE(), b.ExpiryDate) <= m.ExpiryAlertDays / 3
            THEN 'KHAN_CAP'    -- Con duoi 1/3 nguong canh bao
        WHEN DATEDIFF(DAY, GETDATE(), b.ExpiryDate) <= m.ExpiryAlertDays
            THEN 'CANH_BAO'   -- Con trong nguong canh bao
        ELSE 'AN_TOAN'
    END AS AlertLevel
FROM Batches b
JOIN Medicines m ON m.MedicineID = b.MedicineID
WHERE b.CurrentQuantity > 0
  AND b.ExpiryDate <= DATEADD(DAY, m.ExpiryAlertDays, GETDATE());
GO

CREATE OR ALTER VIEW V_DailySales AS
SELECT CAST(inv.CreatedAt AS DATE) AS SaleDate,
       COUNT(DISTINCT inv.InvoiceID) AS NumInvoices,
       SUM(inv.FinalAmount) AS Revenue
FROM Invoices inv WHERE inv.Status = 'COMPLETED'
GROUP BY CAST(inv.CreatedAt AS DATE);
GO

CREATE OR ALTER VIEW V_ShiftRevenue AS
SELECT s.ShiftID, a.FullName AS StaffName, s.StartTime, s.EndTime,
       s.OpeningCash, s.ClosingCash,
       COUNT(DISTINCT inv.InvoiceID) AS NumInvoices,
       ISNULL(SUM(inv.FinalAmount), 0) AS Revenue
FROM Shifts s
JOIN Accounts a ON a.AccountID = s.AccountID
LEFT JOIN Invoices inv ON inv.ShiftID = s.ShiftID AND inv.Status = 'COMPLETED'
GROUP BY s.ShiftID, a.FullName, s.StartTime, s.EndTime, s.OpeningCash, s.ClosingCash;
GO

CREATE OR ALTER VIEW V_TopSellingMedicines AS
SELECT TOP 10 m.MedicineID, m.MedicineCode, m.MedicineName,
       SUM(id.Quantity) AS TotalSold, SUM(id.SubTotal) AS TotalRevenue
FROM InvoiceDetails id
JOIN Batches   b   ON b.BatchID    = id.BatchID
JOIN Medicines m   ON m.MedicineID = b.MedicineID
JOIN Invoices  inv ON inv.InvoiceID = id.InvoiceID
WHERE inv.Status = 'COMPLETED'
GROUP BY m.MedicineID, m.MedicineCode, m.MedicineName
ORDER BY SUM(id.Quantity) DESC;
GO

CREATE OR ALTER VIEW V_LoyaltyStatus AS
SELECT c.CustomerID, c.CustomerName, c.Phone,
       lc.CardCode, lc.TotalPoints, lc.UsedPoints,
       lc.TotalPoints - lc.UsedPoints AS AvailablePoints,
       lt.TierName, lt.DiscountPct, lc.IssuedAt, lc.IsActive
FROM LoyaltyCards lc
JOIN Customers    c  ON c.CustomerID = lc.CustomerID
JOIN LoyaltyTiers lt ON lt.TierID    = lc.TierID;
GO

CREATE OR ALTER VIEW V_OrderHistory AS
SELECT ol.LogID, ol.InvoiceID, inv.InvoiceCode, inv.FinalAmount,
       ol.OldStatus, ol.NewStatus, ol.ChangedAt, ol.Source, ol.Note,
       a.FullName AS ChangedBy
FROM OrderLogs ol
JOIN Invoices  inv ON inv.InvoiceID = ol.InvoiceID
LEFT JOIN Accounts a ON a.AccountID = ol.AccountID;
GO


/* ================================================================
   BƯỚC 6 — STORED PROCEDURES
   ================================================================ */

CREATE OR ALTER PROCEDURE SP_AddSaleByFIFO
    @InvoiceID INT, @MedicineID INT, @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DECLARE @remain INT = @Quantity;
        DECLARE @batchId INT, @available INT, @price DECIMAL(18,2);
        SELECT @price = SellingPrice FROM Medicines WHERE MedicineID = @MedicineID;

        DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
            SELECT BatchID, CurrentQuantity FROM Batches
            WHERE MedicineID = @MedicineID AND CurrentQuantity > 0
              AND ExpiryDate > CAST(GETDATE() AS DATE)
            ORDER BY ExpiryDate ASC;

        OPEN cur;
        FETCH NEXT FROM cur INTO @batchId, @available;
        WHILE @@FETCH_STATUS = 0 AND @remain > 0
        BEGIN
            DECLARE @take INT = CASE WHEN @available >= @remain THEN @remain ELSE @available END;
            INSERT INTO InvoiceDetails (InvoiceID, BatchID, Quantity, UnitPrice)
            VALUES (@InvoiceID, @batchId, @take, @price);
            SET @remain -= @take;
            FETCH NEXT FROM cur INTO @batchId, @available;
        END
        CLOSE cur; DEALLOCATE cur;

        IF @remain > 0 BEGIN RAISERROR(N'Khong du ton kho.', 16, 1); ROLLBACK TRANSACTION; RETURN; END
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE SP_OpenShift
    @AccountID INT, @OpeningCash DECIMAL(18,2)
AS
BEGIN
    -- Dong ca cu neu con mo
    UPDATE Shifts 
    SET EndTime = GETDATE() 
    WHERE AccountID = @AccountID AND EndTime IS NULL;

    -- Mo ca moi
    INSERT INTO Shifts (AccountID, OpeningCash) 
    VALUES (@AccountID, @OpeningCash);
    
    SELECT SCOPE_IDENTITY() AS NewShiftID;
END;
GO

CREATE OR ALTER PROCEDURE SP_CloseShift
    @ShiftID INT, @ClosingCash DECIMAL(18,2)
AS
BEGIN
    UPDATE Shifts SET EndTime = GETDATE(), ClosingCash = @ClosingCash WHERE ShiftID = @ShiftID;
END;
GO

CREATE OR ALTER PROCEDURE SP_WriteAudit
    @AccountID INT, @Action VARCHAR(100),
    @EntityType VARCHAR(50) = NULL, @EntityID INT = NULL,
    @Description NVARCHAR(500) = NULL, @IPAddress VARCHAR(45) = NULL
AS
BEGIN
    INSERT INTO AuditLog (AccountID, Action, EntityType, EntityID, Description, IPAddress)
    VALUES (@AccountID, @Action, @EntityType, @EntityID, @Description, @IPAddress);
END;
GO


/* ================================================================
   BƯỚC 7 — SAMPLE DATA
   ================================================================ */

INSERT INTO Roles (RoleName) VALUES (N'Admin'), (N'Manager'), (N'Staff');

INSERT INTO Accounts (Username, PasswordHash, FullName, Email, Phone, RoleID,
    CitizenId, ProfessionalCertNo, ProfessionalCertExp, Position) VALUES
('admin',   '$2a$10$vk6YUYLb4LByJLSQX5LoEOAOXtxFSVDE1m.4OyTeEohHHgm8AFN7.', N'Quan tri he thong',
 'admin@pharmacy.vn',   '0900000001', 1, '012345678901', NULL, NULL, N'Quan tri vien'),
('manager', '$2a$10$vk6YUYLb4LByJLSQX5LoEOAOXtxFSVDE1m.4OyTeEohHHgm8AFN7.', N'Tran Quan Ly',
 'manager@pharmacy.vn', '0900000002', 2, '012345678902', 'DS-0001-2020', '2025-12-31', N'Duoc si phu trach'),
('staff01', '$2a$10$vk6YUYLb4LByJLSQX5LoEOAOXtxFSVDE1m.4OyTeEohHHgm8AFN7.', N'Nguyen Van Ban',
 'staff01@pharmacy.vn', '0900000003', 3, '012345678903', NULL, NULL, N'Nhan vien ban hang'),
('staff02', '$2a$10$vk6YUYLb4LByJLSQX5LoEOAOXtxFSVDE1m.4OyTeEohHHgm8AFN7.', N'Le Thi Tu Van',
 'staff02@pharmacy.vn', '0900000004', 3, '012345678904', NULL, NULL, N'Nhan vien ban hang');

INSERT INTO Categories (CategoryName, Description) VALUES
(N'Giam dau - Ha sot', N'Paracetamol, Ibuprofen...'),
(N'Khang sinh',        N'Yeu cau don thuoc bac si'),
(N'Vitamin & Khoang',  N'Bo sung dinh duong'),
(N'Tieu hoa',          N'Men tieu hoa, da day'),
(N'Ho hap',            N'Ho, viem hong');

INSERT INTO Manufacturers (Name, Country, Address) VALUES
(N'Sanofi Viet Nam', N'Viet Nam', N'Quan 9, TP HCM'),
(N'Pfizer',          N'My',       N'New York, USA'),
(N'DHG Pharma',      N'Viet Nam', N'Can Tho'),
(N'Traphaco',        N'Viet Nam', N'Ha Noi');

INSERT INTO Suppliers (SupplierName, ContactName, Phone, Email, Address, LicenseNumber) VALUES
(N'Cong ty Duoc Hau Giang',   N'Nguyen Van A', '0901234567', 'sales@dhg.vn',      N'Can Tho', N'GPKD-2020-DHG'),
(N'Cong ty CP Duoc Traphaco', N'Tran Thi B',   '0901234568', 'order@traphaco.vn', N'Ha Noi',  N'GPKD-2019-TRP'),
(N'Zuellig Pharma Viet Nam',  N'Le Van C',     '0901234569', 'vn@zuellig.com',    N'TP HCM',  N'GPKD-2018-ZP');

INSERT INTO Shelves (ShelfName, MachineSlotCode, MotorID, LocationNotes, ShelfType) VALUES
(N'Ke A1',       'A-01', 'M001', N'Ngan tu dong hang 1 cot 1', 'MACHINE'),
(N'Ke A2',       'A-02', 'M002', N'Ngan tu dong hang 1 cot 2', 'MACHINE'),
(N'Ke B1',       'B-01', 'M003', N'Ngan tu dong hang 2 cot 1', 'MACHINE'),
(N'Ke B2',       'B-02', 'M004', N'Ngan tu dong hang 2 cot 2', 'MACHINE'),
(N'Ke thuong C',  NULL,   NULL,  N'Ke thu cong - thuoc ke don', 'RETAIL');

-- Thêm DefaultDosageMin, DefaultDosageMax, DosageWarning vào INSERT:
INSERT INTO Medicines (
    MedicineName, GenericName, Barcode, RegistrationNumber,
    CategoryID, ManufacturerID, ShelfID, Unit,
    StorageTempMin, StorageTempMax, StorageConditions,
    Dosage, DefaultDosageMin, DefaultDosageMax, DosageWarning,
    Contraindications, IsPrescriptionRequired, SellingPrice, MinInventory,
    ExpiryAlertDays -- Gọi tên cột cấu hình động vào đây
) VALUES
(N'Paracetamol 500mg', N'Paracetamol', '8934567000011', N'VD-12345-20', 1, 3, 1, N'vien', 15, 25, N'Tranh anh sang',
 N'Nguoi lon: 1-2 vien/lan, 4-6 lan/ngay', 0.5, 2.0, N'Khong qua 8 vien/ngay',
 N'Suy gan nang', 0, 2000, 100, 
 90), -- Hạn dài 18 tháng -> Cảnh báo trước 3 tháng (90 ngày) để đẩy hàng bán lẻ

(N'Panadol Extra', N'Paracetamol+Caffeine', '8934567000028', N'VD-23456-21', 1, 1, 2, N'vien', 15, 25, N'Tranh anh sang',
 N'1-2 vien/lan, toi da 8 vien/ngay', 0.5, 2.0, N'Khong qua 8 vien/ngay',
 N'Tre em duoi 12 tuoi', 0, 3500, 50, 
 90), -- Thuốc thông dụng -> Cảnh báo trước 90 ngày

(N'Amoxicillin 500mg', N'Amoxicillin', '8934567000035', N'VD-34567-19', 2, 3, 5, N'vien', 15, 30, N'Tranh am',
 N'Theo chi dinh bac si, 500mg x 3 lan/ngay', 1.0, 2.0, N'Khong tu y dung khang sinh',
 N'Di ung penicillin', 1, 4000, 30, 
 30), -- Hạn ngắn / Kháng sinh kê đơn -> Chỉ cần báo trước 1 tháng (30 ngày)

(N'Vitamin C 1000mg', N'Acid Ascorbic', '8934567000042', N'VD-45678-22', 3, 4, 3, N'vien', 15, 25, N'Tranh am sang',
 N'1 vien/ngay sau an', 0.5, 1.0, NULL,
 N'Soi than, tieu duong', 0, 3000, 80, 
 60), -- Thực phẩm chức năng -> Để mức trung bình 2 tháng (60 ngày)

(N'Smecta', N'Diosmectite', '8934567000059', N'VD-56789-20', 4, 1, 4, N'goi', 15, 30, N'Noi kho mat',
 N'1 goi x 3 lan/ngay, pha voi 50ml nuoc', 1.0, 1.0, NULL,
 N'Tac ruot', 0, 6000, 40, 
 45), -- Thuốc tiêu hóa dạng gói -> Cảnh báo trước 45 ngày

(N'Berberin', N'Berberin clorid', '8934567000066', N'VD-67890-21', 4, 4, 5, N'vien', 15, 25, N'Tranh am',
 N'2-4 vien x 2-3 lan/ngay, uong truoc an', 2.0, 4.0, NULL,
 N'Phu nu co thai', 0, 500, 200, 
 60); -- Thuốc quốc dân, số lượng tồn nhiều -> Để mặc định 60 ngày
GO
INSERT INTO PurchaseOrders (SupplierID, AccountID, OrderDate, TotalValue, Notes) VALUES
(1, 2, DATEADD(DAY,-30,GETDATE()), 5000000, N'Nhap dau thang'),
(2, 2, DATEADD(DAY,-15,GETDATE()), 3000000, N'Nhap bo sung');

INSERT INTO Batches (MedicineID,POID,SupplierID,BatchNumber,ManufactureDate,ImportDate,ExpiryDate,ImportPrice,InitialQuantity,CurrentQuantity) VALUES
(1,1,1,'PCM-2026-A',DATEADD(MONTH,-6,GETDATE()),DATEADD(DAY,-30,GETDATE()),DATEADD(MONTH,18,GETDATE()),1200,500,500),
(1,2,2,'PCM-2026-B',DATEADD(MONTH,-3,GETDATE()),DATEADD(DAY,-15,GETDATE()),DATEADD(MONTH,24,GETDATE()),1300,300,300),
(2,1,1,'PND-2026-A',DATEADD(MONTH,-4,GETDATE()),DATEADD(DAY,-30,GETDATE()),DATEADD(MONTH,20,GETDATE()),2200,200,200),
(3,1,1,'AMX-2026-A',DATEADD(MONTH,-2,GETDATE()),DATEADD(DAY,-30,GETDATE()),DATEADD(MONTH,12,GETDATE()),2500,150,150),
(4,2,2,'VTC-2026-A',DATEADD(MONTH,-5,GETDATE()),DATEADD(DAY,-15,GETDATE()),DATEADD(MONTH,30,GETDATE()),1800,400,400),
(5,1,1,'SMT-2026-A',DATEADD(MONTH,-3,GETDATE()),DATEADD(DAY,-30,GETDATE()),DATEADD(MONTH,18,GETDATE()),4000,100,100),
(6,2,2,'BBR-2026-A',DATEADD(MONTH,-1,GETDATE()),DATEADD(DAY,-15,GETDATE()),DATEADD(MONTH,24,GETDATE()), 300,1000,1000);

INSERT INTO Customers (CustomerName, Phone, Email, Address, AllergyHistory) VALUES
(N'Nguyen Thi Khach', '0911111111', 'kh1@gmail.com', N'Q1, TP HCM', NULL),
(N'Tran Van Binh',    '0922222222', 'kh2@gmail.com', N'Q3, TP HCM', N'Di ung Penicillin'),
(N'Le Hoang Nam',     '0933333333',  NULL,           N'Q5, TP HCM', NULL);

INSERT INTO LoyaltyTiers (TierName, MinPoints, DiscountPct, Description) VALUES
(N'Silver',      0, 0, N'Hang co ban - tich diem moi giao dich'),
(N'Gold',      500, 2, N'Tu 500 diem - giam 2% moi hoa don'),
(N'Platinum', 2000, 5, N'Tu 2000 diem - giam 5% + uu tien phuc vu');

INSERT INTO LoyaltyCards (CustomerID, TierID, TotalPoints) VALUES
(1, 2,  650),
(2, 1,  120),
(3, 1,   50);

INSERT INTO Shifts (AccountID, StartTime, OpeningCash) VALUES (3, GETDATE(), 500000);
GO

PRINT N'================================================';
PRINT N'PharmacyPro_DB v3.1 FINAL tao thanh cong!';
PRINT N'11 KV | 6 Triggers | 7 Views | 4 SPs';
PRINT N'TK: admin / manager / staff01 / staff02';
PRINT N'================================================';
GO
