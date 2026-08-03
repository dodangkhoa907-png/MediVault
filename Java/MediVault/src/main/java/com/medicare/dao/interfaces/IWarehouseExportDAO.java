package com.medicare.dao.interfaces;

import com.medicare.entity.ExportReason;
import com.medicare.entity.ExportStatusHistory;
import com.medicare.entity.Medicines;
import com.medicare.entity.WarehouseExport;
import com.medicare.entity.WarehouseExportDetail;

import java.time.LocalDate;
import java.util.List;

/**
 * IWarehouseExportDAO — chứng từ Xuất kho (WarehouseExports/WarehouseExportDetails),
 * lịch sử trạng thái (ExportStatusHistory) và 7 lý do xuất kho (ExportReasons).
 * Xem database/warehouse_export_migration.sql.
 */
public interface IWarehouseExportDAO {

    List<ExportReason> findReasons();
    ExportReason findReasonById(int reasonId);

    /**
     * Ghi 1 phiếu xuất kho HOÀN CHỈNH trong 1 TRANSACTION: header (Status=CONFIRMED ngay,
     * wizard không có bước lưu nháp riêng) + từng dòng phân bổ lô + trừ Batches.CurrentQuantity
     * + StockMovements(OUT) + ExportStatusHistory. Trả về ExportID mới, -1 nếu lỗi/không đủ tồn.
     */
    int confirmExport(WarehouseExport header, List<WarehouseExportDetail> lines, int accountId);

    /** Huỷ phiếu — chỉ khi đang PENDING (chưa từng qua confirmExport). Không đụng tồn kho. */
    boolean cancelExport(int exportId, int accountId, String reason);

    /** Hoàn trả — chỉ khi đang CONFIRMED: cộng lại đúng CurrentQuantity vào ĐÚNG các lô đã xuất,
     *  ghi StockMovements(IN), chuyển Status sang REVERSED. */
    boolean reverseExport(int exportId, int accountId, String reason);

    WarehouseExport findById(int exportId);
    List<WarehouseExportDetail> findDetails(int exportId);
    List<ExportStatusHistory> findHistory(int exportId);

    List<WarehouseExport> findPaged(String status, LocalDate from, LocalDate to, String keyword, int page, int pageSize);

    int countByStatus(String status);
    int countCompletedToday();
    int countDistinctMedicinesToday();
    int countNearExpiryLotsToday();

    /** Các thuốc gần đây nhất từng xuất kho (bất kỳ trạng thái) — cho khung "Xuất gần đây" ở Bước 2. */
    List<Medicines> findRecentMedicines(int limit);
}
