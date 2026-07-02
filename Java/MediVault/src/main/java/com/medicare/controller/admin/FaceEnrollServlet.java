package com.medicare.controller.admin;

import com.medicare.config.AppCache;
import com.medicare.dao.AccountDAO;
import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.entity.Account;
import com.medicare.util.AuditHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;

/**
 * FaceEnrollServlet — Admin đăng ký / xóa khuôn mặt cho nhân viên.
 * URL: /face-enroll
 *
 * POST action=enroll  accountId=X  descriptor=[0.12,-0.03,...] (JSON array 128 số)
 *      → lưu vào Accounts.FaceVector, set FaceEnrolledAt = now
 * POST action=remove   accountId=X
 *      → xóa FaceVector (null), cho phép đăng ký lại từ đầu
 *
 * Response JSON: {"ok":true} hoặc {"ok":false,"reason":"..."}
 */
@WebServlet("/face-enroll")
public class FaceEnrollServlet extends HttpServlet {

    private final IAccountDAO dao = new AccountDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");
        req.setCharacterEncoding("UTF-8");

        HttpSession session = req.getSession(false);
        Account admin = session != null ? (Account) session.getAttribute("adminAccount") : null;
        if (admin == null || admin.getRoleId() != 1) {
            writeJson(resp, "{\"ok\":false,\"reason\":\"unauthorized\"}");
            return;
        }

        String action = req.getParameter("action");
        if ("remove".equals(action)) {
            handleRemove(req, resp, admin);
            return;
        }
        // default: enroll
        handleEnroll(req, resp, admin);
    }

    private void handleEnroll(HttpServletRequest req, HttpServletResponse resp, Account admin)
            throws IOException {
        String idStr = req.getParameter("accountId");
        String descriptor = req.getParameter("descriptor");

        if (idStr == null || idStr.isEmpty() || descriptor == null || descriptor.trim().isEmpty()) {
            writeJson(resp, "{\"ok\":false,\"reason\":\"missing_params\"}");
            return;
        }

        int accountId;
        try {
            accountId = Integer.parseInt(idStr);
        } catch (NumberFormatException e) {
            writeJson(resp, "{\"ok\":false,\"reason\":\"invalid_account_id\"}");
            return;
        }

        // Validate sơ bộ: descriptor phải là JSON array hợp lệ, đúng 128 phần tử
        String trimmed = descriptor.trim();
        if (!trimmed.startsWith("[") || !trimmed.endsWith("]")) {
            writeJson(resp, "{\"ok\":false,\"reason\":\"invalid_descriptor_format\"}");
            return;
        }
        String inner = trimmed.substring(1, trimmed.length() - 1).trim();
        int count = inner.isEmpty() ? 0 : inner.split(",").length;
        if (count != 128) {
            writeJson(resp, "{\"ok\":false,\"reason\":\"invalid_descriptor_length\",\"count\":" + count + "}");
            return;
        }

        Account target = dao.findById(accountId);
        if (target == null) {
            writeJson(resp, "{\"ok\":false,\"reason\":\"account_not_found\"}");
            return;
        }

        // Chặn 1 khuôn mặt đăng ký cho 2 tài khoản khác nhau
        Account dup = com.medicare.util.FaceVerifier.findDuplicateFace(
                trimmed, accountId, dao.findAllWithFaceVector());
        if (dup != null) {
            String dupName = dup.getFullName() != null ? dup.getFullName() : dup.getUsername();
            writeJson(resp, "{\"ok\":false,\"reason\":\"face_already_used\",\"usedBy\":\""
                    + dupName.replace("\"", "") + "\"}");
            return;
        }

        boolean success = dao.updateFaceVector(accountId, trimmed);
        if (success) {
            AppCache.invalidateStaff();
            AuditHelper.log(req, "FACE_ENROLL", "Account", accountId,
                    "Đăng ký khuôn mặt cho nhân viên: " + target.getFullName() + " (ID " + accountId + ")");
            writeJson(resp, "{\"ok\":true,\"accountId\":" + accountId + "}");
        } else {
            writeJson(resp, "{\"ok\":false,\"reason\":\"db_error\"}");
        }
    }

    private void handleRemove(HttpServletRequest req, HttpServletResponse resp, Account admin)
            throws IOException {
        String idStr = req.getParameter("accountId");
        if (idStr == null || idStr.isEmpty()) {
            writeJson(resp, "{\"ok\":false,\"reason\":\"missing_params\"}");
            return;
        }
        int accountId;
        try {
            accountId = Integer.parseInt(idStr);
        } catch (NumberFormatException e) {
            writeJson(resp, "{\"ok\":false,\"reason\":\"invalid_account_id\"}");
            return;
        }

        Account target = dao.findById(accountId);
        if (target == null) {
            writeJson(resp, "{\"ok\":false,\"reason\":\"account_not_found\"}");
            return;
        }

        boolean success = dao.updateFaceVector(accountId, null);
        if (success) {
            AppCache.invalidateStaff();
            AuditHelper.log(req, "FACE_REMOVE", "Account", accountId,
                    "Xóa dữ liệu khuôn mặt của nhân viên: " + target.getFullName() + " (ID " + accountId + ")");
            writeJson(resp, "{\"ok\":true,\"accountId\":" + accountId + "}");
        } else {
            writeJson(resp, "{\"ok\":false,\"reason\":\"db_error\"}");
        }
    }

    private void writeJson(HttpServletResponse resp, String json) throws IOException {
        try (PrintWriter out = resp.getWriter()) {
            out.print(json);
        }
    }
}