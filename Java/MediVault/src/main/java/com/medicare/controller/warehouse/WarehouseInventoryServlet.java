package com.medicare.controller.warehouse;

import com.medicare.config.CacheManager;
import com.medicare.dao.BatchesDAO;
import com.medicare.dao.MedicineDAO;
import com.medicare.dao.interfaces.IBatchesDAO;
import com.medicare.dao.interfaces.IMedicineDAO;
import com.medicare.entity.Account;
import com.medicare.entity.Batches;
import com.medicare.entity.Medicines;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * WarehouseInventoryServlet — Quản lý tồn kho chuyên sâu cho Quản lý kho (roleId 3 = Thủ kho).
 * URL: /warehouse-inventory?uid=&lt;id&gt;&amp;q=&lt;keyword&gt;
 *
 * <p>Đây là bản "mở rộng" của trang thuốc bên admin dành riêng cho thủ kho: danh sách
 * thuốc kèm tồn kho thực tế (SUM CurrentQuantity theo lô), HSD gần nhất, trạng thái
 * sắp hết hàng, cùng 2 bảng chuyên sâu Lô cận hạn / Lô đã hết hạn.</p>
 */
@WebServlet("/warehouse-inventory")
public class WarehouseInventoryServlet extends HttpServlet {

    private static final int ROLE_WAREHOUSE = 3;

    private final IMedicineDAO medicineDAO = new MedicineDAO();
    private final IBatchesDAO  batchesDAO  = new BatchesDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String uid = req.getParameter("uid");
        HttpSession session = req.getSession(false);
        Account acc = (uid != null && session != null)
                ? (Account) session.getAttribute("staffAccount_" + uid) : null;
        if (acc == null || acc.getRoleId() != ROLE_WAREHOUSE) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login");
            return;
        }

        String q = req.getParameter("q");
        boolean hasKeyword = q != null && !q.trim().isEmpty();

        // Danh sách đầy đủ (cache 30s) — dùng làm map tên thuốc + danh sách mặc định
        MedicineDAO mdao = (MedicineDAO) medicineDAO;
        List<Medicines> allMeds = CacheManager.getShort("wh.allMedsStock", mdao::findAllWithStock);

        List<Medicines> displayMeds = hasKeyword ? mdao.searchWithStock(q.trim()) : allMeds;

        // Map medicineId → tên thuốc (để hiển thị tên trong bảng lô cận/hết hạn)
        Map<Integer, String> medNameMap = new HashMap<>();
        for (Medicines m : allMeds) medNameMap.put(m.getMedicineId(), m.getMedicineName());

        // Thống kê nhanh (tính từ allMeds để nhất quán với dữ liệu đang hiển thị)
        int lowStock = 0;
        for (Medicines m : allMeds) {
            if (m.getMinInventory() > 0 && m.getTotalStock() <= m.getMinInventory()) lowStock++;
        }
        List<Batches> expiringBatches = CacheManager.getShort("wh.expiringBatches", batchesDAO::findExpiringSoon);
        List<Batches> expiredBatches  = CacheManager.getShort("wh.expiredBatches",  batchesDAO::findExpired);

        req.setAttribute("staffUid",   uid);
        req.setAttribute("staffAcc",   acc);
        req.setAttribute("keyword",    hasKeyword ? q.trim() : "");
        req.setAttribute("medicines",  displayMeds);
        req.setAttribute("medNameMap", medNameMap);
        req.setAttribute("totalActive",     allMeds.size());
        req.setAttribute("lowStockCount",   lowStock);
        req.setAttribute("expiringBatches", expiringBatches);
        req.setAttribute("expiredBatches",  expiredBatches);

        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-inventory.jsp")
                .forward(req, resp);
    }
}
