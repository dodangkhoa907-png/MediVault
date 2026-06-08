package com.medivault.controller;

import com.medivault.entity.Account;
import com.medivault.filter.MaintenanceFilter;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/admin/toggle-maintenance")
public class ToggleMaintenanceServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Kiểm tra quyền Admin bảo mật
        HttpSession session = req.getSession(false);
        Account acc = (session != null) ? (Account) session.getAttribute("adminAccount") : null;
        if (acc == null || acc.getRoleId() != 1) {
            resp.sendError(403, "Bạn không có quyền thực hiện hành động này.");
            return;
        }

        // Đảo ngược trạng thái bảo trì toàn hệ thống
        MaintenanceFilter.isMaintenanceMode = !MaintenanceFilter.isMaintenanceMode;

        // Trả về thông báo trạng thái hiện tại
        resp.setContentType("text/html;charset=UTF-8");
        resp.getWriter().write("<h3>Trạng thái bảo trì hệ thống đã chuyển thành: "
                + (MaintenanceFilter.isMaintenanceMode ? "<b style='color:red;'>ĐANG BẢO TRÌ</b>" : "<b style='color:green;'>HOẠT ĐỘNG BÌNH THƯỜNG</b>")
                + "</h3><a href='" + req.getContextPath() + "/admin-dashboard'>Quay lại Dashboard (Trang quản trị)</a>");
    }
}