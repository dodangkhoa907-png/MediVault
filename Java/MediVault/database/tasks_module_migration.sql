-- =====================================================================
-- Tasks Module — bảng Tasks cho To-do List / Task Management
-- (mục 4 trong tài liệu "To-do List Module" người dùng cung cấp)
--
-- Được thiết kế SAU KHI khảo sát trực tiếp schema thật của PharmacyPro_DB
-- (không dựa vào bản mẫu Users/UserID trong tài liệu gốc — bảng thật là
-- Accounts/AccountID). Các quy ước bám sát 100% theo DB hiện có:
--
--   1) Tên cột tham chiếu Accounts theo vai trò dùng hậu tố trần, KHÔNG có
--      "AccountID" phía sau — đúng như LeaveRequests.ApprovedBy,
--      Payroll.ConfirmedBy, ShiftSchedules.CreatedBy (đã kiểm tra trực tiếp
--      trong sys.columns).
--   2) MỌI cột kiểu enum (Status/Type/...) trong toàn DB đều có CHECK
--      constraint tường minh — không có ngoại lệ (đã liệt kê hết 35 CHECK
--      constraint hiện có). Task cũng theo đúng luật này.
--   3) NVARCHAR(MAX) trong toàn bộ DB CHỈ dùng cho Accounts.PasswordHash và
--      Accounts.FaceVector (dữ liệu thật sự không giới hạn). Description
--      không thuộc diện đó nên dùng NVARCHAR(1000) — đủ dài cho ghi chú
--      công việc, không phá quy ước.
--   4) MỌI FK trong DB đều ON DELETE NO ACTION (mặc định, không có CASCADE/
--      SET NULL ở bất kỳ đâu) — giữ nguyên convention, không thêm CASCADE.
--   5) RefTable/RefID: tái dùng đúng pattern polymorphic reference đã có
--      sẵn ở StockMovements (RefTable VARCHAR(50), RefID INT) để Task loại
--      SYSTEM_AUTO trỏ ngược về Batches/PurchaseOrders/Shifts... thay vì
--      bịa ra cơ chế mới.
--   6) LeaveRequests đã có sẵn tiền lệ 2 FK cùng trỏ Accounts từ 1 bảng
--      (AccountID = người xin nghỉ, ApprovedBy = người duyệt) — Tasks áp
--      dụng y hệt: AssignedTo (người nhận việc) + CreatedBy (người giao)
--      + CompletedBy (người bấm hoàn thành, để audit "ai làm lúc mấy giờ"
--      theo đúng yêu cầu ở mục 3 workflow).
-- =====================================================================

CREATE TABLE Tasks (
    TaskID          INT IDENTITY(1,1)   NOT NULL,
    Title           NVARCHAR(255)       NOT NULL,
    Description     NVARCHAR(1000)      NULL,

    -- 'SYSTEM_AUTO' = job nền tự sinh (hết hạn, ROP, lệch ca...)
    -- 'MANUAL'      = Quản lý tự tạo và giao việc
    TaskType        VARCHAR(20)         NOT NULL DEFAULT 'MANUAL',

    Priority        VARCHAR(10)         NOT NULL DEFAULT 'MEDIUM',

    Status          VARCHAR(20)         NOT NULL DEFAULT 'PENDING',

    -- Người được giao việc. NULL = task chung, ai trực ca cũng thấy/nhận
    AssignedTo      INT                 NULL,

    -- Người tạo task thủ công. NULL bắt buộc khi TaskType='SYSTEM_AUTO'
    CreatedBy       INT                 NULL,

    -- Tham chiếu polymorphic tới bản ghi gốc sinh ra task tự động
    -- (vd RefTable='Batches', RefID=123 cho task "lô sắp hết hạn")
    RefTable        VARCHAR(50)         NULL,
    RefID           INT                 NULL,

    DueDate         DATETIME            NULL,
    CreatedAt       DATETIME            NOT NULL DEFAULT GETDATE(),
    CompletedAt     DATETIME            NULL,
    CompletedBy     INT                 NULL,

    CONSTRAINT PK_Tasks PRIMARY KEY (TaskID),

    CONSTRAINT CK_Task_Type
        CHECK (TaskType = 'SYSTEM_AUTO' OR TaskType = 'MANUAL'),

    CONSTRAINT CK_Task_Priority
        CHECK (Priority = 'HIGH' OR Priority = 'MEDIUM' OR Priority = 'LOW'),

    CONSTRAINT CK_Task_Status
        CHECK (Status = 'PENDING' OR Status = 'IN_PROGRESS'
               OR Status = 'COMPLETED' OR Status = 'CANCELLED'),

    -- Đã COMPLETED thì bắt buộc phải có mốc thời gian hoàn thành (audit)
    CONSTRAINT CK_Task_CompletedAt
        CHECK (Status <> 'COMPLETED' OR CompletedAt IS NOT NULL),

    -- Đúng nghiệp vụ: SYSTEM_AUTO không có người tạo, MANUAL bắt buộc có
    CONSTRAINT CK_Task_Origin
        CHECK ((TaskType = 'SYSTEM_AUTO' AND CreatedBy IS NULL)
               OR (TaskType = 'MANUAL' AND CreatedBy IS NOT NULL)),

    CONSTRAINT FK_Task_AssignedTo FOREIGN KEY (AssignedTo)  REFERENCES Accounts(AccountID),
    CONSTRAINT FK_Task_CreatedBy  FOREIGN KEY (CreatedBy)   REFERENCES Accounts(AccountID),
    CONSTRAINT FK_Task_CompletedBy FOREIGN KEY (CompletedBy) REFERENCES Accounts(AccountID)
);
GO

-- Index phục vụ 2 truy vấn chính của module:
--  - "Nhiệm vụ của tôi hôm nay" (theo AssignedTo + Status)
--  - Dashboard Manager lọc theo Status/Priority toàn kho
CREATE INDEX IX_Tasks_AssignedTo_Status ON Tasks(AssignedTo, Status);
CREATE INDEX IX_Tasks_Status_Priority   ON Tasks(Status, Priority);
GO
