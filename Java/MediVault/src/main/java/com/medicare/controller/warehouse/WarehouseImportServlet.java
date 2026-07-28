package com.medicare.controller.warehouse;

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
import java.util.List;

@WebServlet("/warehouse-import")
public class WarehouseImportServlet extends HttpServlet {

    private static final int ROLE_WAREHOUSE = 3;

    private final BatchesDAO batchesDAO = new BatchesDAO();
    private final MedicineDAO medicineDAO = new MedicineDAO();
    private final SupplierDAO supplierDAO = new SupplierDAO();
    private final PurchaseOrderDAO poDAO = new PurchaseOrderDAO();

    private Account requireWarehouseStaff(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String uid = req.getParameter("uid");
        if (uid == null || uid.trim().isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login");
            return null;
        }
        HttpSession session = req.getSession(false);
        if (session == null) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login");
            return null;
        }
        Account acc = (Account) session.getAttribute("staffAccount_" + uid);
        if (acc == null || acc.getRoleId() != ROLE_WAREHOUSE) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login");
            return null;
        }
        return acc;
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Account acc = requireWarehouseStaff(req, resp);
        if (acc == null) return;
        String uid = req.getParameter("uid");

        List<Medicines> medicines = medicineDAO.findAll();
        List<Supplier> suppliers = supplierDAO.findAll();
        List<PurchaseOrders> pos = poDAO.findAll();

        req.setAttribute("staffUid", uid);
        req.setAttribute("staffAcc", acc);
        req.setAttribute("medicines", medicines);
        req.setAttribute("suppliers", suppliers);
        req.setAttribute("pos", pos);
        
        // Define activeNav for sidebar
        req.setAttribute("activeNav", "inventory"); 
        
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-import.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        Account acc = requireWarehouseStaff(req, resp);
        if (acc == null) return;
        String uid = req.getParameter("uid");

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

            Batches batch = new Batches();
            batch.setMedicineId(medicineId);
            batch.setSupplierId(supplierId);
            if (poId > 0) batch.setPoId(poId);
            batch.setBatchNumber(batchNumber);
            batch.setManufactureDate(manufactureDate);
            batch.setExpiryDate(expiryDate);
            batch.setImportDate(importDate);
            batch.setImportPrice(importPrice);
            batch.setInitialQuantity(quantity);
            batch.setCurrentQuantity(quantity);
            batch.setCreatedAt(LocalDateTime.now());
            
            batchesDAO.insert(batch);

            resp.sendRedirect(req.getContextPath() + "/warehouse-inventory?uid=" + uid + "&msg=import-success");
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/warehouse-import?uid=" + uid + "&msg=import-error");
        }
    }
}
