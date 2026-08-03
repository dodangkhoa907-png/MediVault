package com.medicare.service.warehouse;

import java.util.List;

/** Toàn bộ dữ liệu wizard Xuất kho gửi lên ở bước cuối (Xác nhận) — 1 export = nhiều dòng thuốc. */
public class ExportSubmission {
    private final int reasonId;
    private final String receiver;
    private final String notes;
    private final String overrideReason; // bắt buộc nếu bất kỳ dòng nào overridden=true
    private final List<ExportLineRequest> lines;

    public ExportSubmission(int reasonId, String receiver, String notes, String overrideReason, List<ExportLineRequest> lines) {
        this.reasonId = reasonId;
        this.receiver = receiver;
        this.notes = notes;
        this.overrideReason = overrideReason;
        this.lines = lines;
    }

    public int getReasonId() { return reasonId; }
    public String getReceiver() { return receiver; }
    public String getNotes() { return notes; }
    public String getOverrideReason() { return overrideReason; }
    public List<ExportLineRequest> getLines() { return lines; }

    public boolean hasAnyOverride() {
        if (lines == null) return false;
        return lines.stream().anyMatch(ExportLineRequest::isOverridden);
    }
}
