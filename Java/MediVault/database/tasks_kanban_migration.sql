-- =====================================================================
-- Task Management redesign (Investigation-Center-style Kanban) — mở rộng
-- bảng Tasks + 2 bảng MỚI (Checklist, Comments). Additive, KHÔNG đụng dữ
-- liệu cũ — mọi cột/bảng mới đều NULL/DEFAULT an toàn cho các dòng đã có.
--
-- 1) CK_Task_Status: nới thêm REVIEW, BLOCKED để Kanban có đủ 7 cột thật
--    (To Do/Assigned suy từ AssignedTo+PENDING · In Progress · Review ·
--    Done=COMPLETED_ON_TIME+LATE · Cancelled · Blocked) — cùng kỹ thuật
--    DROP rồi ADD lại constraint đã dùng ở tasks_projects_migration.sql
--    (SQL Server không cho ALTER CHECK tại chỗ).
-- 2) EstimatedHours: số giờ dự kiến, NULLABLE — chỉ hiển thị tham khảo,
--    KHÔNG có timer/giờ-thực-tế-đã-log (hệ thống chưa có cơ chế đó).
-- 3) TaskChecklistItems / TaskComments: 2 bảng con polymorphic-free (FK
--    thẳng TaskID), theo đúng convention FK NO ACTION + CHECK tường minh
--    + NVARCHAR cho text đã dùng xuyên suốt DB này.
-- =====================================================================

ALTER TABLE Tasks DROP CONSTRAINT CK_Task_Status;
GO
ALTER TABLE Tasks ADD CONSTRAINT CK_Task_Status
    CHECK (Status = 'PENDING' OR Status = 'IN_PROGRESS' OR Status = 'REVIEW'
           OR Status = 'BLOCKED'
           OR Status = 'COMPLETED_ON_TIME' OR Status = 'COMPLETED_LATE'
           OR Status = 'CANCELLED');
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Tasks') AND name = 'EstimatedHours')
    ALTER TABLE Tasks ADD EstimatedHours DECIMAL(6,2) NULL;
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TaskChecklistItems')
BEGIN
    CREATE TABLE TaskChecklistItems (
        ChecklistItemID INT IDENTITY(1,1) NOT NULL,
        TaskID          INT             NOT NULL,
        ItemText        NVARCHAR(255)   NOT NULL,
        IsDone          BIT             NOT NULL DEFAULT 0,
        SortOrder       INT             NOT NULL DEFAULT 0,
        CreatedAt       DATETIME        NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_TaskChecklistItems PRIMARY KEY (ChecklistItemID),
        CONSTRAINT FK_ChecklistItem_Task FOREIGN KEY (TaskID) REFERENCES Tasks(TaskID)
    );
    CREATE INDEX IX_TaskChecklistItems_TaskID ON TaskChecklistItems(TaskID);
    PRINT '✅ Đã tạo bảng TaskChecklistItems.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'TaskComments')
BEGIN
    CREATE TABLE TaskComments (
        TaskCommentID INT IDENTITY(1,1) NOT NULL,
        TaskID        INT             NOT NULL,
        AccountID     INT             NOT NULL,
        Body          NVARCHAR(1000)  NOT NULL,
        CreatedAt     DATETIME        NOT NULL DEFAULT GETDATE(),
        CONSTRAINT PK_TaskComments PRIMARY KEY (TaskCommentID),
        CONSTRAINT FK_TaskComment_Task    FOREIGN KEY (TaskID)    REFERENCES Tasks(TaskID),
        CONSTRAINT FK_TaskComment_Account FOREIGN KEY (AccountID) REFERENCES Accounts(AccountID)
    );
    CREATE INDEX IX_TaskComments_TaskID ON TaskComments(TaskID);
    PRINT '✅ Đã tạo bảng TaskComments.';
END
GO

PRINT '✅ Task Kanban migration — hoàn tất.';
GO
