package com.medicare.util;

import com.medicare.dao.*;
import com.medicare.entity.*;

import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/**
 * Task.RefTable/RefID là polymorphic reference có sẵn từ database/tasks_module_migration.sql
 * (dùng cho task SYSTEM_AUTO trỏ ngược về bản ghi gốc — lô hết hạn, đơn nhập trễ...), nhưng
 * TRƯỚC GIỜ chưa có nơi nào JOIN ngược lại để hiển thị — TaskDAO chỉ trả 2 cột thô (RefTable
 * varchar, RefID int). Class này lần đầu tiên "giải mã" cặp đó thành thông tin thật (tên thuốc/
 * số lô/NCC/HSD...) cho khung "Warehouse Information" ở Task Detail — dùng lại đúng các DAO
 * findById() đã có sẵn, KHÔNG viết SQL mới, KHÔNG bịa trường không có thật.
 */
public final class TaskRefResolver {

    private static final DateTimeFormatter DF = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    public static class RefInfo {
        public String moduleLabel;              // nhãn "module" thân thiện (cho badge + analytics)
        public String title;                     // dòng tiêu đề ngắn
        public List<String[]> rows = new ArrayList<>(); // [nhãn, giá trị]
        public boolean found;
    }

    /** Nhãn "module" thân thiện từ RefTable thô — dùng CHUNG cho badge trên card lẫn Analytics
     *  "Tasks by Module" (TaskDAO.countByModule()) để không lệch nhãn giữa 2 nơi. */
    public static String moduleLabel(String refTable) {
        if (refTable == null || refTable.isEmpty()) return "Chung";
        return switch (refTable) {
            case "Batches", "Batch"       -> "Kho / Lô hàng";
            case "PurchaseOrders"          -> "Đơn nhập hàng";
            case "Medicines", "Medicine"   -> "Thuốc";
            case "Shifts", "ShiftSchedule" -> "Ca làm việc";
            case "Suppliers"                -> "Nhà cung cấp";
            default                          -> refTable;
        };
    }

    public static RefInfo resolve(String refTable, Integer refId) {
        RefInfo info = new RefInfo();
        info.moduleLabel = moduleLabel(refTable);
        if (refTable == null || refId == null) return info;

        try {
            switch (refTable) {
                case "Batches", "Batch" -> {
                    Batches b = new BatchesDAO().findById(refId);
                    if (b != null) {
                        info.found = true;
                        Medicines m = new MedicineDAO().findById(b.getMedicineId());
                        Supplier s = new SupplierDAO().findById(b.getSupplierId());
                        info.title = "Lô #" + b.getBatchNumber();
                        info.rows.add(new String[]{"Thuốc", m != null ? m.getMedicineName() : "#" + b.getMedicineId()});
                        info.rows.add(new String[]{"Số lô", b.getBatchNumber()});
                        info.rows.add(new String[]{"NCC", s != null ? s.getSupplierName() : "#" + b.getSupplierId()});
                        info.rows.add(new String[]{"Hạn sử dụng", b.getExpiryDate() != null ? b.getExpiryDate().format(DF) : "—"});
                        info.rows.add(new String[]{"Tồn hiện tại", b.getCurrentQuantity() + " / " + b.getInitialQuantity()});
                        info.rows.add(new String[]{"Trạng thái lô", b.getStatus()});
                        if (m != null) info.rows.add(new String[]{"Mã vạch", m.getBarcode() != null ? m.getBarcode() : "—"});
                    }
                }
                case "PurchaseOrders" -> {
                    PurchaseOrders po = new PurchaseOrderDAO().findById(refId);
                    if (po != null) {
                        info.found = true;
                        Supplier s = new SupplierDAO().findById(po.getSupplierId());
                        info.title = "Đơn nhập " + (po.getPoCode() != null ? po.getPoCode() : "#" + po.getPoId());
                        info.rows.add(new String[]{"Mã đơn", po.getPoCode() != null ? po.getPoCode() : "#" + po.getPoId()});
                        info.rows.add(new String[]{"NCC", s != null ? s.getSupplierName() : "#" + po.getSupplierId()});
                        info.rows.add(new String[]{"Trạng thái", po.getStatus()});
                        info.rows.add(new String[]{"Giá trị", po.getTotalValue() != null ? po.getTotalValue().toPlainString() : "—"});
                        if (po.getExpectedDate() != null) info.rows.add(new String[]{"Ngày dự kiến", po.getExpectedDate().format(DF)});
                    }
                }
                case "Medicines", "Medicine" -> {
                    Medicines m = new MedicineDAO().findById(refId);
                    if (m != null) {
                        info.found = true;
                        info.title = m.getMedicineName();
                        info.rows.add(new String[]{"Thuốc", m.getMedicineName()});
                        info.rows.add(new String[]{"Đơn vị", m.getUnit()});
                        info.rows.add(new String[]{"Mã vạch", m.getBarcode() != null ? m.getBarcode() : "—"});
                        info.rows.add(new String[]{"Tồn kho tối thiểu", String.valueOf(m.getMinInventory())});
                    }
                }
                case "Shifts", "ShiftSchedule" -> {
                    Shift sh = new ShiftDAO().findById(refId);
                    if (sh != null) {
                        info.found = true;
                        info.title = "Ca #" + sh.getShiftId() + " — " + sh.getFullName();
                        info.rows.add(new String[]{"Nhân viên", sh.getFullName()});
                        info.rows.add(new String[]{"Trạng thái ca", sh.getStatusLabel()});
                        info.rows.add(new String[]{"Thời lượng", sh.getDurationDisplay()});
                    }
                }
                default -> { /* RefTable không nằm trong danh sách đã biết — hiển thị thô, không bịa */ }
            }
        } catch (Exception e) {
            e.printStackTrace(); // tra cứu thêm thất bại KHÔNG được làm hỏng cả trang chi tiết task
        }
        return info;
    }
}
