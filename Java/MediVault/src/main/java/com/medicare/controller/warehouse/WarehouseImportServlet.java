package com.medicare.controller.warehouse;

import com.medicare.dao.AccountDAO;
import com.medicare.dao.BatchesDAO;
import com.medicare.dao.MedicineDAO;
import com.medicare.dao.SupplierDAO;
import com.medicare.dao.PurchaseOrderDAO;
import com.medicare.entity.Account;
import com.medicare.entity.Batches;
import com.medicare.entity.Medicines;
import com.medicare.entity.Supplier;
import com.medicare.entity.PurchaseOrders;
import com.medicare.util.SidebarHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/warehouse-import")
public class WarehouseImportServlet extends HttpServlet {

    private static final int ROLE_WAREHOUSE = 3;

    private final BatchesDAO batchesDAO = new BatchesDAO();
    private final MedicineDAO medicineDAO = new MedicineDAO();
    private final SupplierDAO supplierDAO = new SupplierDAO();
    private final PurchaseOrderDAO poDAO = new PurchaseOrderDAO();
    private final AccountDAO accountDAO = new AccountDAO();

    private static final java.time.format.DateTimeFormatter DATE_TIME_VN =
            java.time.format.DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    /** Danh tinh Thu kho lay tu SESSION (WarehouseAuth) — khong con doc ?uid= tren URL. */
    private Account requireWarehouseStaff(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        return com.medicare.util.WarehouseAuth.require(req, resp);
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Account acc = requireWarehouseStaff(req, resp);
        if (acc == null) return;
        String uid = String.valueOf(acc.getAccountId());   // tu SESSION, khong tu URL

        // findAllWithStock (không phải findAll): wizard nhập kho cần tồn hiện tại và
        // ngưỡng tối thiểu để xem trước "tồn sau khi nhập" ngay tại bước xác nhận —
        // thủ kho thấy được hệ quả trước khi bấm, thay vì nhập xong mới đi kiểm tra.
        List<Medicines> medicines = ((MedicineDAO) medicineDAO).findAllWithStock();
        List<Supplier> suppliers = supplierDAO.findAll();
        List<PurchaseOrders> pos = poDAO.findAll();

        // Gợi ý "giá nhập / số lô lần gần nhất" theo từng thuốc — chỉ để hiển thị tham khảo
        // ngay cạnh ô nhập, KHÔNG tự điền: giá và số lô vẫn phải gõ tay theo đúng phiếu/hộp
        // thật đang cầm trên tay.
        Map<Integer, Batches> latestByMedicine = batchesDAO.getLatestBatchMap();

        req.setAttribute("staffUid", uid);
        req.setAttribute("staffAcc", acc);
        req.setAttribute("medicines", medicines);
        req.setAttribute("suppliers", suppliers);
        req.setAttribute("pos", pos);
        req.setAttribute("latestByMedicine", latestByMedicine);
        req.setAttribute("recentImports", loadRecentImports());
        // Đi thẳng từ nút giỏ hàng "Gợi ý đặt hàng" ở Tồn kho / cảnh báo hạn dùng — trước đây
        // nút đó chỉ đưa tới /warehouse-reorder để XEM gợi ý, không tới được chỗ thao tác thật
        // (nhập kho). Nay truyền medicineId qua để JS pre-select sẵn đúng thuốc ở Bước 1.
        req.setAttribute("preSelectMedicineId", req.getParameter("medicineId"));

        // Define activeNav for sidebar
        req.setAttribute("activeNav", "inventory");

        // 2 badge sidebar — SidebarHelper.load() cũ chỉ set expiryCount, thiếu myOpenTaskCount
        // nên badge "Nhiệm vụ & SOP" biến mất đúng lúc thủ kho đang ở trang Nhập kho.
        SidebarHelper.loadWarehouse(req, acc.getAccountId());

        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-import.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        Account acc = requireWarehouseStaff(req, resp);
        if (acc == null) return;
        String uid = String.valueOf(acc.getAccountId());   // tu SESSION, khong tu URL

        try {
            int medicineId = Integer.parseInt(req.getParameter("medicineId"));
            int supplierId = Integer.parseInt(req.getParameter("supplierId"));
            int poId = 0;
            String poIdStr = req.getParameter("poId");
            if (poIdStr != null && !poIdStr.trim().isEmpty()) {
                poId = Integer.parseInt(poIdStr);
            }

            String batchNumber = req.getParameter("batchNumber");
            LocalDate manufactureDate = LocalDate.parse(req.getParameter("manufactureDate"));
            LocalDate expiryDate = LocalDate.parse(req.getParameter("expiryDate"));
            LocalDate importDate = LocalDate.parse(req.getParameter("importDate"));
            BigDecimal importPrice = new BigDecimal(req.getParameter("importPrice"));
            int quantity = Integer.parseInt(req.getParameter("quantity"));

            // Chặn cứng dữ liệu KHÔNG THỂ có thật, không phải chuyện "rủi ro nghiệp vụ" như lô
            // sắp hết hạn (cái đó JS đã cảnh báo mềm ở bước 3, vẫn cho ghi). Đây là bất khả thi
            // vật lý — không có lý do nghiệp vụ nào hợp thức hoá được, nên chặn ở tầng server
            // dù JS đã chặn từ trước, phòng khi JS bị tắt hoặc bị qua mặt.
            if (!expiryDate.isAfter(manufactureDate)) {
                resp.sendRedirect(req.getContextPath() + "/warehouse-import?msg=import-error");
                return;
            }
            if (importDate.isBefore(manufactureDate)) {
                resp.sendRedirect(req.getContextPath() + "/warehouse-import?msg=import-error");
                return;
            }

            Batches batch = new Batches();
            batch.setMedicineId(medicineId);
            batch.setSupplierId(supplierId);
            batch.setBatchNumber(batchNumber);
            batch.setManufactureDate(manufactureDate);
            batch.setExpiryDate(expiryDate);
            batch.setImportDate(importDate);
            batch.setImportPrice(importPrice);
            batch.setInitialQuantity(quantity);
            batch.setCurrentQuantity(quantity);
            batch.setCreatedAt(LocalDateTime.now());

            boolean ok;
            if (poId > 0) {
                // Đã chọn PO có sẵn — gắn lô vào đúng PO đó, insert thẳng như cũ (nhánh này
                // vốn đã đúng, KHÔNG phải nguồn gây lỗi).
                batch.setPoId(poId);
                ok = batchesDAO.insert(batch);
            } else {
                // BUG THẬT Ở ĐÂY (đã fix): không chọn PO thì Batches.poId để nguyên giá trị
                // mặc định 0 của kiểu int — POID là khoá ngoại tới PurchaseOrders, không có
                // đơn nào mang id 0, nên INSERT luôn vi phạm FK. BatchesDAO.insert() lại tự
                // bắt Exception rồi trả về false thay vì ném lên, và dòng gọi trước đây
                // "batchesDAO.insert(batch);" bỏ luôn giá trị trả về — nên request vẫn redirect
                // sang trang "thành công" trong khi KHÔNG có dòng nào được ghi vào DB.
                //
                // Cách sửa: thủ kho đang ghi nhận hàng ĐÃ VỀ TAY ngay lúc này (khác với Admin
                // "đặt hàng cho tương lai"), nên tự tạo 1 Phiếu nhập (PurchaseOrders) trạng thái
                // COMPLETED để có POID hợp lệ — dùng lại đúng PurchaseOrderDAO.createWithBatches()
                // mà MedicineService (nhập kho bên Admin) đang dùng, không viết luồng insert mới.
                // Lợi ích phụ: phiếu này hiện thẳng trong "Đơn đặt hàng" của Admin, có lịch sử
                // đầy đủ thay vì trôi mất không dấu vết.
                PurchaseOrders po = new PurchaseOrders();
                po.setSupplierId(supplierId);
                po.setAccountId(acc.getAccountId());
                po.setStatus("COMPLETED");
                po.setNotes("Nhập nhanh bởi Thủ kho — " + acc.getFullName());
                po.setTotalValue(importPrice.multiply(BigDecimal.valueOf(quantity)));
                int newPoId = poDAO.createWithBatches(po, List.of(batch));
                ok = newPoId > 0;
            }

            if (!ok) {
                resp.sendRedirect(req.getContextPath() + "/warehouse-import?msg=import-error");
                return;
            }

            resp.sendRedirect(req.getContextPath() + "/warehouse-import?msg=success");
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/warehouse-import?msg=import-error");
        }
    }

    /**
     * 20 phiếu nhập gần nhất — cùng dữ liệu Admin thấy ở "Đơn đặt hàng" (PurchaseOrderDAO),
     * dựng lại đúng pattern PurchaseOrderServlet.showList() để thủ kho xem lại lô mình vừa
     * nhập ngay tại trang Nhập kho, không phải hỏi Admin hay đoán xem có ghi vào DB hay chưa.
     */
    private List<Map<String, Object>> loadRecentImports() {
        List<Map<String, Object>> rows = new java.util.ArrayList<>();
        for (PurchaseOrders po : poDAO.findRecent(20)) {
            Map<String, Object> row = new HashMap<>();
            Supplier sup = supplierDAO.findById(po.getSupplierId());
            Account by = accountDAO.findById(po.getAccountId());
            row.put("po", po);
            row.put("supplierName", sup != null ? sup.getSupplierName() : "—");
            row.put("byName", by != null ? by.getFullName() : "—");
            row.put("batchCount", poDAO.countBatches(po.getPoId()));
            // Ngày giờ format SẴN ở đây, không để JSP tự lo: <fmt:formatDate> của JSTL chỉ
            // nhận java.util.Date/Calendar, đưa LocalDateTime vào là ném exception giữa lúc
            // render → response đứt ngang (500) và phần <script> cuối trang không kịp gửi,
            // khiến các combo box "biến mất" trên màn hình. Đây chính là lỗi đã xảy ra.
            row.put("whenText", po.getOrderDate() != null
                    ? po.getOrderDate().format(DATE_TIME_VN) : "—");
            rows.add(row);
        }
        return rows;
    }
}
