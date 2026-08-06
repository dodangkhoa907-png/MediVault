-- Thêm Mã khách hàng (CustomerCode) — mã định danh duy nhất, cấp tại POS lúc tạo
-- tài khoản, dùng làm yếu tố thứ 2 (cùng SĐT) để đăng nhập Customer Portal.
-- Định dạng: KH + 6 chữ số theo CustomerID, ví dụ KH000123.

ALTER TABLE Customers ADD CustomerCode VARCHAR(10) NULL;
GO

UPDATE Customers
SET CustomerCode = 'KH' + RIGHT('000000' + CAST(CustomerID AS VARCHAR(6)), 6)
WHERE CustomerCode IS NULL;
GO

ALTER TABLE Customers ALTER COLUMN CustomerCode VARCHAR(10) NOT NULL;
GO

CREATE UNIQUE INDEX UQ_Customers_CustomerCode ON Customers(CustomerCode);
GO
