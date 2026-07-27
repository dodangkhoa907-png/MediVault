package com.medicare.controller.warehouse;

import com.medicare.dao.AccountDAO;
import com.medicare.entity.Account;
import com.medicare.util.SidebarHelper;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

import java.io.File;
import java.io.IOException;

@WebServlet("/warehouse-profile")
@MultipartConfig(fileSizeThreshold = 1024 * 512, maxFileSize = 5 * 1024 * 1024, maxRequestSize = 8 * 1024 * 1024)
public class WarehouseProfileServlet extends HttpServlet {

    private final AccountDAO accountDAO = new AccountDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        String uid = req.getParameter("uid");
        HttpSession session = req.getSession(false);
        if (uid == null || session == null) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login");
            return;
        }

        Account acc = (Account) session.getAttribute("staffAccount_" + uid);
        if (acc == null || acc.getRoleId() != 3) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login");
            return;
        }

        // Tải lại thông tin mới nhất từ DB
        Account updatedAcc = accountDAO.findById(acc.getAccountId());
        if (updatedAcc != null) {
            session.setAttribute("staffAccount_" + uid, updatedAcc);
            req.setAttribute("staffAcc", updatedAcc);
        }

        req.setAttribute("activeNav", "profile");
        SidebarHelper.load(req);

        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-profile.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        String uid = req.getParameter("uid");
        HttpSession session = req.getSession(false);

        if (uid == null || session == null) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login");
            return;
        }

        Account acc = (Account) session.getAttribute("staffAccount_" + uid);
        if (acc == null || acc.getRoleId() != 3) {
            resp.sendRedirect(req.getContextPath() + "/warehouse-login");
            return;
        }

        try {
            Part avatarPart = req.getPart("avatar");
            if (avatarPart != null && avatarPart.getSize() > 0) {
                String contentType = avatarPart.getContentType();
                if (contentType != null && contentType.startsWith("image/")) {
                    String uploadDir = getServletContext().getRealPath("/avatars");
                    File dir = new File(uploadDir);
                    if (!dir.exists()) dir.mkdirs();

                    String ext = "";
                    if (contentType.equals("image/jpeg")) ext = ".jpg";
                    else if (contentType.equals("image/png")) ext = ".png";
                    else ext = ".jpg"; // fallback

                    String filename = "avatar_" + acc.getAccountId() + "_" + System.currentTimeMillis() + ext;
                    avatarPart.write(uploadDir + File.separator + filename);

                    String relativePath = "avatars/" + filename;
                    acc.setFaceEnrollmentPath(relativePath);
                    accountDAO.update(acc);
                    
                    // Cập nhật lại session
                    session.setAttribute("staffAccount_" + uid, acc);
                }
            }

            resp.sendRedirect(req.getContextPath() + "/warehouse-profile?uid=" + uid + "&msg=success");
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/warehouse-profile?uid=" + uid + "&msg=error");
        }
    }
}
