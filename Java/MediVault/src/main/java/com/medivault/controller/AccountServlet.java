package com.medivault.controller;

import com.medivault.dao.interfaces.IAccountDAO;
import com.medivault.entity.Account;
import com.medivault.util.AuditHelper; // Giả định helper ghi log của hệ thống
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;

@WebServlet("/accounts")
public class AccountServlet extends HttpServlet {

    private final IAccountDAO dao = new com.medivault.dao.AccountDAO();

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
        if (action == null) {
            action = "list";
        }

        switch (action) {
            case "list" -> {
                // Logic hiển thị danh sách tài khoản giữ nguyên của hệ thống...
                req.getRequestDispatcher("/account-list.jsp").forward(req, resp);
            }

            case "toggle" -> {
                try {
                    int toggleId = Integer.parseInt(req.getParameter("id"));
                    Account toggleAcc = dao.findById(toggleId);
                    boolean force = "true".equals(req.getParameter("force"));

                    if (toggleAcc == null) {
                        resp.sendRedirect(req.getContextPath() + "/accounts?msg=error");
                        return;
                    }

                    // 1. CHẶN NÚT TOGGLE KHI TÀI KHOẢN ĐANG CÓ PENDINGRESET
                    if (toggleAcc.isPendingReset()) {
                        resp.sendRedirect(req.getContextPath() + "/accounts?msg=pending-reset-lock");
                        return;
                    }

                    // 2. BẢO VỆ: Không cho phép khóa tài khoản Admin cuối cùng
                    if (toggleAcc.getRoleId() == 1
                            && toggleAcc.isActive()
                            && dao.countActiveAdmins() <= 1) {
                        resp.sendRedirect(req.getContextPath() + "/accounts?msg=last-admin");
                        return;
                    }

                    // 3. CHẶN MỞ KHÓA NẾU ĐANG BẢO TRÌ — Trừ khi bấm nút khẩn cấp (force=true)
                    if (!toggleAcc.isActive() && toggleAcc.isMaintenance() && !force) {
                        resp.sendRedirect(req.getContextPath() + "/accounts?msg=maintenance-lock");
                        return;
                    }

                    // Thực thi thay đổi trạng thái hoạt động (Active/Inactive)
                    dao.toggleActive(toggleId);

                    // Ghi lại lịch sử hệ thống (Audit Log)
                    AuditHelper.log(req, force ? "Mở khóa khẩn cấp" : "Khóa/Mở tài khoản",
                            "Account", toggleId,
                            (force ? "⚡ Khẩn cấp: " : "") + "Toggle @" + toggleAcc.getUsername());

                    resp.sendRedirect(req.getContextPath() + "/accounts?msg=updated");

                } catch (Exception e) {
                    System.err.println("[AccountServlet] Lỗi thực thi toggle: " + e.getMessage());
                    resp.sendRedirect(req.getContextPath() + "/accounts?msg=error");
                }
            }

            default -> resp.sendRedirect(req.getContextPath() + "/accounts");
        }
    }
}