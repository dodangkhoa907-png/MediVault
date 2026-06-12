package com.medicare.service;

import com.medicare.config.DBContext;
import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.logging.Logger;

/**
 * ShiftAutoCloseService — Background service tự động đóng ca quá giờ.
 *
 * Logic:
 *   - Mỗi 1 phút: gọi SP_AutoCloseOverdueShifts
 *   - SP tự tính: ca quá PlannedEnd + 20p → đóng + trừ 15p tiền
 *   - Grace window 5p (PlannedEnd → +5p): nhân viên tự quẹt thẻ không bị trừ
 *   - Penalty window (+5p → +20p): nếu không quẹt → trừ 15p × HourlyRate/60
 *
 * Khởi động cùng Tomcat nhờ @WebListener
 */
@WebListener
public class ShiftAutoCloseService implements ServletContextListener {

    private static final Logger log = Logger.getLogger(ShiftAutoCloseService.class.getName());
    private ScheduledExecutorService scheduler;

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "shift-auto-close");
            t.setDaemon(true); // tắt cùng JVM
            return t;
        });

        // Chạy mỗi 1 phút, delay đầu 1 phút sau khi start
        scheduler.scheduleAtFixedRate(this::runAutoClose, 1, 1, TimeUnit.MINUTES);
        log.info("[ShiftAutoClose] Service started — checking every 1 minute");
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        if (scheduler != null) {
            scheduler.shutdownNow();
            log.info("[ShiftAutoClose] Service stopped");
        }
    }

    private void runAutoClose() {
        try (Connection cn = DBContext.getConnection();
             CallableStatement cs = cn.prepareCall("{call SP_AutoCloseOverdueShifts}")) {
            // SP v2: SYSTEM_CLOSED thay vì FORCE_CLOSED, không trừ tiền tự động
            cs.execute();
            log.fine("[ShiftAutoClose] SP_AutoCloseOverdueShifts v2 executed — SYSTEM_CLOSED mode");
        } catch (Exception e) {
            // Không throw — service chạy liên tục không được crash
            log.warning("[ShiftAutoClose] Error: " + e.getMessage());
        }
    }
}