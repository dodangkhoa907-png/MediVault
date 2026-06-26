USE PharmacyPro_DB;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- TRG 1: Bán hàng → trừ kho + log StockMovements + lệnh máy
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

-- TRG 2: Cập nhật tổng tiền HĐ sau khi thêm/xóa/sửa InvoiceDetails
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

-- TRG 3: Nhập kho → ghi StockMovements
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

-- TRG 5: Tích điểm tự động sau HĐ COMPLETED (chỉ khi có CustomerID)
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

-- TRG 6: Log trạng thái thay đổi hóa đơn
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

-- TRG 7: Gán Grace Period Shift cho HĐ vừa tạo
CREATE OR ALTER TRIGGER TRG_AssignGracePeriodShift
ON Invoices
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE inv
    SET inv.ShiftID = old_shift.ShiftID
    FROM Invoices inv
    JOIN inserted i ON i.InvoiceID = inv.InvoiceID
    CROSS APPLY (
        SELECT TOP 1 s.ShiftID, s.GracePeriodMinutes
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

-- TRG: ShiftType minimum wage validation
CREATE OR ALTER TRIGGER TRG_ShiftType_MinWage
ON ShiftTypes AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM inserted WHERE HourlyRate < 50000)
    BEGIN
        RAISERROR(N'Luong gio toi thieu la 50,000d/gio. Vui long nhap lai.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

PRINT '=== Tat ca triggers da duoc tao thanh cong ===';

-- Verify
SELECT name, parent_object_id, OBJECT_NAME(parent_object_id) AS OnTable
FROM sys.triggers
WHERE parent_id > 0
ORDER BY name;
