package com.medivault.controller;

import com.medivault.dao.interfaces.IAccountDAO;
import com.medivault.entity.Account;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;
import java.io.IOException;
import java.io.PrintWriter;

@WebServlet("/account-detail-api")
public class AccountDetailServlet extends HttpServlet {

    private final IAccountDAO dao = new com.medivault.dao.AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        // Kiểm tra đăng nhập + admin
        HttpSession session = req.getSession(false);
        Account acc = session != null ? (Account) session.getAttribute("adminAccount") : null;
        if (acc == null || acc.getRoleId() != 1) {
            resp.setStatus(403);
            return;
        }

        int id;
        try { id = Integer.parseInt(req.getParameter("id")); }
        catch (Exception e) { resp.setStatus(400); return; }

        Account a = dao.findById(id);
        if (a == null) { resp.setStatus(404); return; }

        resp.setContentType("application/json;charset=UTF-8");
        PrintWriter out = resp.getWriter();

        // Trả về JSON thủ công (không cần Jackson)
        String roleName = a.getRoleId()==1 ? "Admin" : a.getRoleId()==2 ? "Dược sĩ bán hàng" : "Thủ kho";
        out.println("{");
        out.println("  \"accountId\": " + a.getAccountId() + ",");
        out.println("  \"username\": \"" + esc(a.getUsername()) + "\",");
        out.println("  \"fullName\": \"" + esc(a.getFullName()) + "\",");
        out.println("  \"email\": \"" + esc(a.getEmail()) + "\",");
        out.println("  \"phone\": \"" + esc(a.getPhone()) + "\",");
        out.println("  \"citizenId\": \"" + esc(a.getCitizenId()) + "\",");
        out.println("  \"position\": \"" + esc(a.getPosition()) + "\",");
        out.println("  \"roleId\": " + a.getRoleId() + ",");
        out.println("  \"roleName\": \"" + roleName + "\",");
        out.println("  \"isActive\": " + a.isActive() + ",");
        out.println("  \"professionalCertNo\": \"" + esc(a.getProfessionalCertNo()) + "\",");
        out.println("  \"faceEnrollmentPath\": \"" + esc(a.getFaceEnrollmentPath()) + "\",");
        out.println("  \"createdAt\": \"" + (a.getCreatedAt()!=null ? a.getCreatedAt().toString() : "") + "\",");
        out.println("  \"lastLoginAt\": \"" + (a.getLastLoginAt()!=null ? a.getLastLoginAt().toString() : "") + "\"");
        out.println("}");
    }

    private String esc(String s) {
        if (s == null) return "";
        return s.replace("\\","\\\\").replace("\"","\\\"");
    }
}