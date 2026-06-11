package com.medivault.controller;

import com.medivault.config.DBContext;
import com.medivault.util.AuditHelper;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.sql.*;

/**
 * NfcAttendanceServlet — Nhận tín hiệu từ thẻ NFC.
 * URL: /nfc-checkin
 *
 * POST ?cardId=XXXX  → toggle check-in / check-out
 * GET  ?cardId=XXXX  → cũng toggle (dễ test từ browser/phone)
 *
 * Response JSON:
 *   {"ok":true,  "action":"CHECK_IN",  "name":"Nguyen Van A", "phase":"IN_SHIFT"}
 *   {"ok":true,  "action":"CHECK_OUT", "name":"Nguyen Van A", "deduct":15000}
 *   {"ok":true,  "action":"CHECK_OUT", "name":"Nguyen Van A", "deduct":0}
 *   {"ok":false, "reason":"NOT_FOUND"}
 *   {"ok":false, "reason":"GRACE_WINDOW", "minutesLeft":12}  -- trong window, nhắc đóng
 *
 * Thiết bị NFC (điện thoại Android + app) gửi POST về endpoint này.
 * cardId = giá trị NFC tag UID (hex string, vd: "A1B2C3D4")
 */
@WebServlet(urlPatterns = {"/nfc-checkin", "/api/nfc"})
public class NfcAttendanceServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        handleNfc(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        handleNfc(req, resp);
    }

    private void handleNfc(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        // Cho phép gọi từ app mobile (CORS)
        resp.setHeader("Access-Control-Allow-Origin", "*");
        resp.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");

        String cardId = req.getParameter("cardId");
        if (cardId == null || cardId.trim().isEmpty()) {
            resp.getWriter().print("{\"ok\":false,\"reason\":\"missing_cardId\"}");
            return;
        }
        cardId = cardId.trim().toUpperCase();

        try (Connection cn = DBContext.getConnection();
             CallableStatement cs = cn.prepareCall("{call SP_CheckNFCCard(?)}")) {
            cs.setString(1, cardId);
            try (ResultSet rs = cs.executeQuery()) {
                if (rs.next()) {
                    String result    = rs.getString("Result");
                    int    accountId = rs.getInt("AccountID");
                    String action    = rs.getString("Action");

                    // result: CHECKED_IN | CHECKED_OUT | NOT_FOUND
                    if ("NOT_FOUND".equals(result)) {
                        resp.getWriter().print(
                                "{\"ok\":false,\"reason\":\"NOT_FOUND\","
                                        + "\"msg\":\"Thẻ chưa được đăng ký hoặc tài khoản bị khóa\"}");
                        return;
                    }

                    // Lấy thêm thông tin để trả về UI
                    String name = getAccountName(cn, accountId);

                    // Kiểm tra xem có trong Grace Window không
                    String phase = getGracePhase(cn, accountId);
                    int minutesLeft = getMinutesBeforeAutoClose(cn, accountId);

                    // Log audit
                    AuditHelper.log(req,
                            "CHECK_IN".equals(action) ? "NFC Check-in" : "NFC Check-out",
                            "Attendance",
                            name + " quẹt thẻ NFC [" + cardId + "] — " + action
                                    + (phase != null ? " (phase: " + phase + ")" : ""),
                            accountId);

                    String json = "{\"ok\":true,"
                            + "\"action\":\"" + action + "\","
                            + "\"accountId\":" + accountId + ","
                            + "\"name\":\"" + name + "\","
                            + "\"phase\":\"" + (phase != null ? phase : "NORMAL") + "\","
                            + "\"minutesLeft\":" + minutesLeft
                            + "}";
                    resp.getWriter().print(json);

                } else {
                    resp.getWriter().print("{\"ok\":false,\"reason\":\"no_result\"}");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            resp.getWriter().print(
                    "{\"ok\":false,\"reason\":\"server_error\",\"msg\":\""
                            + e.getMessage().replace("\"", "'") + "\"}");
        }
    }

    private String getAccountName(Connection cn, int accountId) {
        try (PreparedStatement ps = cn.prepareStatement(
                "SELECT FullName FROM Accounts WHERE AccountID=?")) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getNString("FullName");
            }
        } catch (Exception ignored) {}
        return "ID " + accountId;
    }

    private String getGracePhase(Connection cn, int accountId) {
        try (PreparedStatement ps = cn.prepareStatement(
                "SELECT Phase FROM V_GraceWindowShifts WHERE AccountID=?")) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getString("Phase");
            }
        } catch (Exception ignored) {}
        return null;
    }

    private int getMinutesBeforeAutoClose(Connection cn, int accountId) {
        try (PreparedStatement ps = cn.prepareStatement(
                "SELECT ISNULL(MinutesBeforeAutoClose,0) AS m "
                        + "FROM V_GraceWindowShifts WHERE AccountID=?")) {
            ps.setInt(1, accountId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt("m");
            }
        } catch (Exception ignored) {}
        return 0;
    }
}