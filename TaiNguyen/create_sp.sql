USE PharmacyPro_DB;
GO
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

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

PRINT 'SP_AddSaleByFIFO created successfully';

-- Verify
SELECT name, type_desc FROM sys.objects WHERE name = 'SP_AddSaleByFIFO';
