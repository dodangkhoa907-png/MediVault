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
                // Giữ nguyên logic hiển thị danh sách tài khoản của bạn
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

                    // KIỂM TRA BẢO MẬT CHÍNH: Chặn thay đổi trạng thái nếu tài khoản đang ĐỒNG THỜI khóa và chờ khôi phục mật khẩu
                    if (!toggleAcc.isActive() && toggleAcc.isPendingReset()) {
                        // Trả về trang danh sách kèm mã thông báo chặn 'maintenance-lock'
                        resp.sendRedirect(req.getContextPath() + "/accounts?msg=maintenance-lock");
                        return; // Chặn đứng tại đây, không cho hệ thống chạy tiếp xuống lệnh update ở dưới!
                    }

                    // KIỂM TRA PHỤ: Không cho phép khóa tài khoản Admin duy nhất còn lại
                    if (toggleAcc.getRoleId() == 1 && toggleAcc.isActive() && dao.countActiveAdmins() <= 1) {
                        resp.sendRedirect(req.getContextPath() + "/accounts?msg=last-admin");
                        return;
                    }

                    // Nếu vượt qua các bước kiểm tra an toàn ở trên -> Tiến hành cập nhật trạng thái
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