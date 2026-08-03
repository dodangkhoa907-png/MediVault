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
    private final com.medicare.dao.TaskDAO taskDAO = new com.medicare.dao.TaskDAO();
    private final com.medicare.dao.AttendanceDAO attendanceDAO = new com.medicare.dao.AttendanceDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        Account acc = com.medicare.util.WarehouseAuth.require(req, resp);
        if (acc == null) return;
        HttpSession session = req.getSession(false);
        String uid = String.valueOf(acc.getAccountId());

        // Tải lại thông tin mới nhất từ DB
        Account updatedAcc = accountDAO.findById(acc.getAccountId());
        if (updatedAcc != null) {
            session.setAttribute("staffAccount_" + uid, updatedAcc);
            req.setAttribute("staffAcc", updatedAcc);
        }

        req.setAttribute("staffUid", uid);
        loadStats(req, updatedAcc != null ? updatedAcc : acc);

        req.setAttribute("activeNav", "profile");
        // SidebarHelper.load() cũ chỉ set expiryCount, thiếu myOpenTaskCount nên badge
        // "Nhiệm vụ & SOP" biến mất đúng lúc thủ kho đang ở trang Hồ sơ cá nhân.
        SidebarHelper.loadWarehouse(req, (updatedAcc != null ? updatedAcc : acc).getAccountId());

        req.getRequestDispatcher("/WEB-INF/views/warehouse/warehouse-profile.jsp").forward(req, resp);
    }

    /**
     * Số liệu cá nhân cho trang hồ sơ — chỉ những con số CÓ THẬT trong DB.
     *
     * <p>Cố tình KHÔNG có "số lô đã nhập": bảng Batches không lưu người tạo, nên
     * con số đó sẽ phải bịa hoặc quy cho toàn hệ thống — cả hai đều sai với một
     * trang hồ sơ cá nhân. Muốn có thì phải thêm cột CreatedBy vào Batches.</p>
     */
    private void loadStats(HttpServletRequest req, Account acc) {
        int id = acc.getAccountId();

        // Nhiệm vụ: đếm từ bảng công việc chung rồi lọc theo người hoàn thành.
        int doneOnTime = 0, doneLate = 0, open = 0, streak = 0;
        try {
            java.util.List<com.medicare.entity.Task> mineDone = new java.util.ArrayList<>();
            for (com.medicare.entity.Task t : taskDAO.findBoard(null, null)) {
                boolean mine = t.getCompletedBy() != null && t.getCompletedBy() == id;
                if (!mine) continue;
                if ("COMPLETED_ON_TIME".equals(t.getStatus())) { doneOnTime++; mineDone.add(t); }
                else if ("COMPLETED_LATE".equals(t.getStatus())) { doneLate++; mineDone.add(t); }
            }
            // Chuỗi đúng hạn hiện tại = số việc ĐÚNG HẠN liên tiếp tính từ lần hoàn
            // thành gần nhất ngược về trước. Một lần trễ là chuỗi đứt.
            mineDone.sort((a, b) -> {
                if (a.getCompletedAt() == null) return 1;
                if (b.getCompletedAt() == null) return -1;
                return b.getCompletedAt().compareTo(a.getCompletedAt());
            });
            for (com.medicare.entity.Task t : mineDone) {
                if ("COMPLETED_ON_TIME".equals(t.getStatus())) streak++;
                else break;
            }
            open = taskDAO.countMyOpenTasks(id);
        } catch (Exception ignored) { }

        // Chấm công tháng này.
        java.time.LocalDate now = java.time.LocalDate.now();
        java.util.List<com.medicare.entity.Attendance> att;
        try {
            att = attendanceDAO.findByAccountAndMonth(id, now.getMonthValue(), now.getYear());
        } catch (Exception e) {
            att = java.util.Collections.emptyList();
        }

        // Tổng phút đi trễ trong tháng — nguồn cho huy hiệu "Không đi trễ".
        int lateMinutes = 0;
        for (com.medicare.entity.Attendance a : att) lateMinutes += a.getLateMinutes();

        req.setAttribute("stDoneOnTime", doneOnTime);
        req.setAttribute("stDoneLate",   doneLate);
        req.setAttribute("stOpenTasks",  open);
        req.setAttribute("stStreak",     streak);
        req.setAttribute("stLateMin",    lateMinutes);
        req.setAttribute("stAttDays",    att.size());
        req.setAttribute("attendance",   att);
        req.setAttribute("stMonthLabel", "Tháng " + now.getMonthValue() + "/" + now.getYear());
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
        req.setCharacterEncoding("UTF-8");
        Account acc = com.medicare.util.WarehouseAuth.require(req, resp);
        if (acc == null) return;
        HttpSession session = req.getSession(false);
        String uid = String.valueOf(acc.getAccountId());

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

            resp.sendRedirect(req.getContextPath() + "/warehouse-profile?msg=success");
        } catch (Exception e) {
            e.printStackTrace();
            resp.sendRedirect(req.getContextPath() + "/warehouse-profile?msg=error");
        }
    }
}
