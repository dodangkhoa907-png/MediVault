-- =====================================================================
-- Sửa lỗi mojibake dữ liệu THẬT trong DB: chuỗi UTF-8 (tiếng Việt có dấu)
-- bị lưu nhầm thành byte Windows-1252 trước khi cấu hình encoding kết nối
-- được khắc phục (VD: "Việt Nam" bị lưu thành "Viá»‡t Nam").
--
-- Đã quét TOÀN BỘ 60 cột NVARCHAR/NCHAR của mọi bảng (dùng đúng
-- com.medicare.util.MojibakeUtil.fix() đã có sẵn trong code, đang áp dụng
-- cho shelf-list.jsp) — chỉ 3 bảng seed/demo bị ảnh hưởng, tổng 11 dòng:
--   Manufacturers (Country, Address), Suppliers (SupplierName/ContactName/
--   Address), PurchaseOrders (Notes).
--
-- 6 dòng đầu: fix() tự động cho kết quả sạch hoàn toàn (verify bằng cách
-- ghi ra file UTF-8 rồi đọc lại, KHÔNG dựa vào hiển thị terminal — terminal
-- Windows console không phải UTF-8, tự nó gây đọc sai thêm 1 lớp nữa).
--
-- 5 dòng sau (Manufacturers.Address x3, PurchaseOrders.Notes x2): fix() tự
-- động chỉ đúng ~95% (native hạn chế với 1 số byte, đặc biệt chữ "Đ/đ" bị
-- lệch thành "Ä"). Đây đều là địa danh/cụm từ tiếng Việt phổ biến, không mơ
-- hồ (Trường Chinh, Ninh Kiều - Cần Thơ, Đồng Tháp) — đã tự đối chiếu và
-- hoàn thiện thủ công, KHÔNG phải máy tự sinh mù.
-- =====================================================================

-- ── Tự động sửa sạch (verify qua MojibakeUtil.fix(), không lệch ký tự nào) ──
UPDATE [Manufacturers] SET [Country] = N'Việt Nam' WHERE [ManufacturerID] = 1;
UPDATE [Manufacturers] SET [Country] = N'Việt Nam' WHERE [ManufacturerID] = 2;
UPDATE [Manufacturers] SET [Country] = N'Việt Nam' WHERE [ManufacturerID] = 3;
UPDATE [Suppliers] SET [SupplierName] = N'Công ty CP Dược phẩm Trung Ương 1' WHERE [SupplierID] = 1;
UPDATE [Suppliers] SET [ContactName] = N'Nguyễn Văn Nam' WHERE [SupplierID] = 1;
UPDATE [Suppliers] SET [Address] = N'40 Phố Nhà Chung, Hoàn Kiếm, Hà Nội' WHERE [SupplierID] = 1;

-- ── Đã đối chiếu & hoàn thiện thủ công (fix() tự động chỉ đúng ~95%) ──
UPDATE [Manufacturers] SET [Address] = N'18 Trường Chinh, Tuy Hòa, Phú Yên' WHERE [ManufacturerID] = 1;
UPDATE [Manufacturers] SET [Address] = N'288 Bis Nguyễn Văn Cừ, Ninh Kiều, Cần Thơ' WHERE [ManufacturerID] = 2;
UPDATE [Manufacturers] SET [Address] = N'04 Đường 30/4, TP Cao Lãnh, Đồng Tháp' WHERE [ManufacturerID] = 3;
UPDATE [PurchaseOrders] SET [Notes] = N'Đơn nhập hàng mẫu — Seed data 2026' WHERE [POID] = 1;
UPDATE [PurchaseOrders] SET [Notes] = N'Đơn nhập bổ sung — Amoxicillin, VitC, Metformin' WHERE [POID] = 2;
GO
