-- =====================================================================
-- Mở rộng bảng Tasks: Dự án dài hạn (Milestones) + Vùng cảnh báo hạn chót
-- (tài liệu "Phân hệ Quản lý & Giao Task Thủ kho" — mục V, ĐÃ ĐIỀU CHỈNH
-- để khớp với bảng Tasks THẬT đã tồn tại từ database/tasks_module_migration.sql)
--
-- KHÔNG tạo cột trùng chức năng với cột đã có:
--   - "TargetDeadline" trong tài liệu gốc  → tái dùng Tasks.DueDate (đã có)
--   - "TimeSubmitted"  trong tài liệu gốc  → tái dùng Tasks.CompletedAt (đã có)
--   - "IsOverdue" (BIT lưu cứng)           → KHÔNG thêm; tính tại thời điểm đọc
--     trong Java (Task.getZone()) từ DueDate so với thời gian hiện tại — 1 bit
--     lưu cứng cần job nền lật liên tục và dễ lệch với thực tế.
--
-- 4 cột THẬT SỰ mới: IsProject, ParentTaskID, ProgressPercentage, LastNudgeZone.
-- DueDate tiếp tục NULLABLE (không ép NOT NULL như tài liệu gốc) vì task
-- SYSTEM_AUTO (ROP/hết hạn/lệch ca) hiện không có hạn báo cáo cứng.
-- =====================================================================

ALTER TABLE Tasks ADD
    IsProject          BIT         NOT NULL DEFAULT 0,   -- 1 = Dự án dài hạn (có milestone con)
    ParentTaskID       INT         NULL,                  -- Milestone trỏ về Task cha (Dự án)
    ProgressPercentage INT         NOT NULL DEFAULT 0,    -- 0-100, tự tính từ milestone con
    LastNudgeZone      VARCHAR(10) NULL;                  -- Vùng cảnh báo đã nhắc lần gần nhất
                                                            -- (SAFE/WARNING/CRITICAL) — chống spam
GO

ALTER TABLE Tasks ADD CONSTRAINT FK_Task_Parent
    FOREIGN KEY (ParentTaskID) REFERENCES Tasks(TaskID);

ALTER TABLE Tasks ADD CONSTRAINT CK_Task_Progress
    CHECK (ProgressPercentage BETWEEN 0 AND 100);

-- Chỉ 2 cấp: Dự án → Milestone. Một milestone (có ParentTaskID) không được
-- tự nó là 1 Dự án khác (chặn lồng Dự án trong Dự án).
ALTER TABLE Tasks ADD CONSTRAINT CK_Task_NoNestedProject
    CHECK (ParentTaskID IS NULL OR IsProject = 0);
GO

-- Tách Status='COMPLETED' cũ thành COMPLETED_ON_TIME / COMPLETED_LATE — đúng
-- cơ chế "Báo xong TRƯỚC/SAU hạn" ở mục II.1 tài liệu. SQL Server không cho
-- ALTER CHECK tại chỗ nên phải DROP rồi ADD lại.
ALTER TABLE Tasks DROP CONSTRAINT CK_Task_Status;
ALTER TABLE Tasks DROP CONSTRAINT CK_Task_CompletedAt;
GO

ALTER TABLE Tasks ADD CONSTRAINT CK_Task_Status
    CHECK (Status = 'PENDING' OR Status = 'IN_PROGRESS'
           OR Status = 'COMPLETED_ON_TIME' OR Status = 'COMPLETED_LATE'
           OR Status = 'CANCELLED');

ALTER TABLE Tasks ADD CONSTRAINT CK_Task_CompletedAt
    CHECK (Status NOT IN ('COMPLETED_ON_TIME', 'COMPLETED_LATE') OR CompletedAt IS NOT NULL);
GO

-- Index phục vụ Watchdog widget (task chưa xong, sắp/đã tới hạn) và tra
-- milestone theo Dự án cha.
CREATE INDEX IX_Tasks_DueDate_Status ON Tasks(DueDate, Status) WHERE DueDate IS NOT NULL;
CREATE INDEX IX_Tasks_ParentTaskID   ON Tasks(ParentTaskID) WHERE ParentTaskID IS NOT NULL;
GO
