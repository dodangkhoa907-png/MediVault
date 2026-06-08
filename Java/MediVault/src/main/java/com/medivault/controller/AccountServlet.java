package com.medivault.controller;

import com.medivault.dao.AccountDAO;
import com.medivault.entity.Account;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/accounts")
public class AccountServlet extends HttpServlet {

    private final AccountDAO dao = new AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        processRequest(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        processRequest(req, resp);
    }

    private void processRequest(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        if (action == null) action = "list";

        switch (action) {
            case "list" -> {
                // Giữ nguyên luồng hiển thị danh sách tài khoản cũ của bạn
                req.getRequestDispatcher("/account-list.jsp").forward(req, resp);
            }

            case "toggle" -> {
                try {
                    int toggleId = Integer.parseInt(req.getParameter("id"));
                    Account toggleAcc = dao.findById(toggleId);

                    // Kiểm tra an toàn xem tài khoản có tồn tại không
                    if (toggleAcc == null) {
                        resp.sendRedirect(req.getContextPath() + "/accounts?msg=error");
                        return;
                    }

                    // ==================== CHẶN TOGGLE KHI ĐANG PENDING RESET ====================
                    // Nếu tài khoản đang KHÓA và có cờ PENDING RESET -> Chặn ngay lập tức!
                    if (!toggleAcc.isActive() && toggleAcc.isPendingReset()) {
                        // Redirect đẩy Admin ngược về kèm mã lỗi để Frontend báo lỗi chặn
                        resp.sendRedirect(req.getContextPath() + "/accounts?msg=maintenance-lock");
                        return; // Ngắt luồng xử lý tại đây, không cho chạy xuống lệnh update ở dưới!
                    }
                    // ============================================================================

                    // KIỂM TRA PHỤ: Không cho phép khóa tài khoản Admin duy nhất còn lại
                    if (toggleAcc.getRoleId() == 1 && toggleAcc.isActive() && dao.countActiveAdmins() <= 1) {
                        resp.sendRedirect(req.getContextPath() + "/accounts?msg=last-admin");
                        return;
                    }

                    // Nếu tài khoản bình thường (vượt qua bộ lọc check chặn trên), tiến hành đảo trạng thái
                    dao.toggleActive(toggleId);
                    resp.sendRedirect(req.getContextPath() + "/accounts?msg=updated");

                } catch (Exception e) {
                    resp.sendRedirect(req.getContextPath() + "/accounts?msg=error");
                }
            }

            default -> resp.sendRedirect(req.getContextPath() + "/accounts");
        }
    }
}