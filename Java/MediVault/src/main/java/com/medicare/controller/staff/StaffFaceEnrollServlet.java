package com.medicare.controller.staff;

import com.medicare.config.AppCache;
import com.medicare.dao.AccountDAO;
import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.entity.Account;
import com.medicare.entity.StaffAuditLog;
import com.medicare.dao.StaffAuditLogDAO;
import com.medicare.dao.interfaces.IStaffAuditLogDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.IOException;
import java.io.PrintWriter;

/**
 * StaffFaceEnrollServlet — Nhân viên tự đăng ký / xóa khuôn mặt CỦA CHÍNH MÌNH.
 * URL: /staff-face-enroll
 *
 * POST action=enroll  uid=X  descriptor=[0.12,-0.03,...] (JSON array 128 số)
 *      → lưu vào Accounts.FaceVector của TÀI KHOẢN ĐANG ĐĂNG NHẬP (không cho sửa người khác)
 * POST action=remove   uid=X
 *      → xóa FaceVector (null), cho phép đăng ký lại từ đầu
 *
 * Response JSON: {"ok":true} hoặc {"ok":false,"reason":"..."}
 */
@WebServlet("/staff-face-enroll")
public class StaffFaceEnrollServlet extends HttpServlet {

    private final IAccountDAO dao = new AccountDAO();
    private final IStaffAuditLogDAO staffAuditDAO = new StaffAuditLogDAO();

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.setContentType("application/json;charset=UTF-8");
        req.setCharacterEncoding("UTF-8");

        String uid = req.getParameter("uid");
        if (uid == null || uid.isEmpty()) {
            writeJson(resp, "{\"ok\":false,\"reason\":\"missing_uid\"}");
            return;
        }
        HttpSession session = req.getSession(false);
        Account staff = session != null
                ? (Account) session.getAttribute("staffAccount_" + uid) : null;
        if (staff == null) {
            writeJson(resp, "{\"ok\":false,\"reason\":\"unauthorized\"}");
            return;
        }

        String action = req.getParameter("action");
        if ("remove".equals(action)) {
            handleRemove(req, resp, staff);
            return;
        }
        handleEnroll(req, resp, staff);
    }

    private void handleEnroll(HttpServletRequest req, HttpServletResponse resp, Account staff)
            throws IOException {
        String descriptor = req.getParameter("descriptor");

        if (descriptor == null || descriptor.trim().isEmpty()) {
            writeJson(resp, "{\"ok\":false,\"reason\":\"missing_params\"}");
            return;
        }

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

        // Chặn 1 khuôn mặt đăng ký cho 2 tài khoản khác nhau
        Account dup = com.medicare.util.FaceVerifier.findDuplicateFace(
                trimmed, staff.getAccountId(), dao.findAllWithFaceVector());
        if (dup != null) {
            writeJson(resp, "{\"ok\":false,\"reason\":\"face_already_used\"}");
            return;
        }

        boolean success = dao.updateFaceVector(staff.getAccountId(), trimmed);
        if (success) {
            AppCache.invalidateStaff();
            staff.setFaceVector(trimmed);
            staff.setFaceEnrolledAt(java.time.LocalDateTime.now());
            req.getSession(false).setAttribute(
                    "staffAccount_" + req.getParameter("uid"), staff);
            staffAuditDAO.log(new StaffAuditLog(staff.getAccountId(), "FACE_ENROLL",
                    "Đăng ký khuôn mặt thành công", getIp(req)));
            writeJson(resp, "{\"ok\":true}");
        } else {
            writeJson(resp, "{\"ok\":false,\"reason\":\"db_error\"}");
        }
    }

    private void handleRemove(HttpServletRequest req, HttpServletResponse resp, Account staff)
            throws IOException {
        boolean success = dao.updateFaceVector(staff.getAccountId(), null);
        if (success) {
            AppCache.invalidateStaff();
            staff.setFaceVector(null);
            staff.setFaceEnrolledAt(null);
            req.getSession(false).setAttribute(
                    "staffAccount_" + req.getParameter("uid"), staff);
            staffAuditDAO.log(new StaffAuditLog(staff.getAccountId(), "FACE_REMOVE",
                    "Xóa dữ liệu khuôn mặt", getIp(req)));
            writeJson(resp, "{\"ok\":true}");
        } else {
            writeJson(resp, "{\"ok\":false,\"reason\":\"db_error\"}");
        }
    }

    private String getIp(HttpServletRequest req) {
        String ip = req.getHeader("X-Forwarded-For");
        if (ip == null || ip.isEmpty()) ip = req.getRemoteAddr();
        return ip;
    }

    private void writeJson(HttpServletResponse resp, String json) throws IOException {
        try (PrintWriter out = resp.getWriter()) {
            out.print(json);
        }
    }
}