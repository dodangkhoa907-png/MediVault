package com.medicare.controller.admin;

import com.medicare.dao.BatchesDAO;
import com.medicare.dao.MedicineDAO;
import jakarta.servlet.AsyncContext;
import jakarta.servlet.AsyncEvent;
import jakarta.servlet.AsyncListener;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

@WebServlet(urlPatterns = "/medicines/live", asyncSupported = true)
public class InventorySSEServlet extends HttpServlet {

    // Thread-safe list of all active SSE client connections
    private static final CopyOnWriteArrayList<AsyncContext> clients = new CopyOnWriteArrayList<>();

    private static final BatchesDAO  batchesDAO  = new BatchesDAO();
    private static final MedicineDAO medicineDAO = new MedicineDAO();

    private static ScheduledExecutorService scheduler;

    @Override
    public void init() {
        scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "SSE-heartbeat");
            t.setDaemon(true);
            return t;
        });
        // Heartbeat comment every 25s — keeps connections alive through proxies & firewalls
        scheduler.scheduleAtFixedRate(InventorySSEServlet::sendHeartbeat, 25, 25, TimeUnit.SECONDS);
    }

    @Override
    public void destroy() {
        if (scheduler != null) scheduler.shutdownNow();
        for (AsyncContext ctx : clients) {
            try { ctx.complete(); } catch (Exception ignored) {}
        }
        clients.clear();
    }

    // ── Nhận kết nối SSE từ browser ──────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("text/event-stream;charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");
        resp.setHeader("Cache-Control", "no-cache, no-store");
        resp.setHeader("Connection",    "keep-alive");
        resp.setHeader("X-Accel-Buffering", "no"); // tắt nginx buffer nếu có reverse proxy

        AsyncContext ctx = req.startAsync();
        ctx.setTimeout(0); // không timeout — giữ kết nối mãi
        clients.add(ctx);

        ctx.addListener(new AsyncListener() {
            @Override public void onComplete(AsyncEvent e) { clients.remove(ctx); }
            @Override public void onTimeout(AsyncEvent e)  { remove(ctx); }
            @Override public void onError(AsyncEvent e)    { remove(ctx); }
            @Override public void onStartAsync(AsyncEvent e) {}
        });

        // Đẩy dữ liệu ban đầu ngay khi client kết nối
        try {
            PrintWriter w = resp.getWriter();
            writeEvent(w, "stats",     buildStatsJson());
            writeEvent(w, "stock-map", buildStockMapJson());
            w.flush();
            if (w.checkError()) remove(ctx);
        } catch (Exception e) {
            remove(ctx);
        }
    }

    // ── Gọi từ PosServlet sau khi bán thành công — push tới tất cả tabs ─────
    public static void broadcast() {
        if (clients.isEmpty()) return;
        try {
            // BẮT BUỘC invalidate cache trước — buildStatsJson()/buildStockMapJson() giờ đọc
            // qua CacheManager (cache 30s, dùng chung với MedicineServlet để tránh query trùng
            // lúc load trang). Nếu không xóa cache ở đây, sau khi bán hàng có thể vẫn đẩy số
            // liệu CŨ (trong vòng 30s trước đó) thay vì tồn kho vừa trừ xong.
            com.medicare.config.CacheManager.invalidate("med.batchSummary");
            com.medicare.config.CacheManager.invalidate("med.stockMap");
            com.medicare.config.CacheManager.invalidate("med.countAll");
            com.medicare.config.CacheManager.invalidate("med.countLowStock");

            String statsJson    = buildStatsJson();
            String stockMapJson = buildStockMapJson();
            push(statsJson, stockMapJson);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // ── Heartbeat (comment SSE — không trigger event ở client) ───────────────
    private static void sendHeartbeat() {
        if (clients.isEmpty()) return;
        Iterator<AsyncContext> it = clients.iterator();
        while (it.hasNext()) {
            AsyncContext ctx = it.next();
            try {
                PrintWriter w = ctx.getResponse().getWriter();
                w.write(": hb\n\n");
                w.flush();
                if (w.checkError()) remove(ctx);
            } catch (Exception e) {
                remove(ctx);
            }
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────
    private static void push(String statsJson, String stockMapJson) {
        Iterator<AsyncContext> it = clients.iterator();
        while (it.hasNext()) {
            AsyncContext ctx = it.next();
            try {
                PrintWriter w = ctx.getResponse().getWriter();
                writeEvent(w, "stats",     statsJson);
                writeEvent(w, "stock-map", stockMapJson);
                w.flush();
                if (w.checkError()) remove(ctx);
            } catch (Exception e) {
                remove(ctx);
            }
        }
    }

    private static void remove(AsyncContext ctx) {
        clients.remove(ctx);
        try { ctx.complete(); } catch (Exception ignored) {}
    }

    private static void writeEvent(PrintWriter w, String name, String data) {
        w.write("event: " + name + "\n");
        w.write("data: "  + data + "\n\n");
    }

    // Đọc CHUNG key cache 30s với MedicineServlet — trang Kho hàng vừa tự query xong các số
    // liệu này lúc render, rồi ngay lập tức EventSource kết nối tới đây và gọi lại y hệt (2 lần
    // liên tiếp cùng dữ liệu) nếu không dùng chung cache. Đây là nguyên nhân chính khiến vào
    // trang Kho hàng bị "pending" rất lâu — mỗi lần vào trang chạy 2 lượt query giống hệt nhau.
    private static String buildStatsJson() {
        try {
            com.medicare.dao.BatchesDAO.BatchSummaryBundle bsb = batchesDAO.getCachedBatchSummary();
            int total        = com.medicare.config.CacheManager.getShort("med.countAll", medicineDAO::countAll);
            int lowStock     = com.medicare.config.CacheManager.getShort("med.countLowStock", medicineDAO::countLowStock);
            int expiringSoon = (int) bsb.soonCount.values().stream().filter(v -> v > 0).count();
            int expired      = (int) bsb.expiredCount.values().stream().filter(v -> v > 0).count();
            String ts = LocalTime.now().format(DateTimeFormatter.ofPattern("HH:mm:ss"));
            return String.format(
                "{\"total\":%d,\"lowStock\":%d,\"expiringSoon\":%d,\"expired\":%d,\"ts\":\"%s\"}",
                total, lowStock, expiringSoon, expired, ts);
        } catch (Exception e) {
            return "{\"total\":0,\"lowStock\":0,\"expiringSoon\":0,\"expired\":0,\"ts\":\"\"}";
        }
    }

    private static String buildStockMapJson() {
        try {
            // Cùng key "med.stockMap" mà MedicineServlet đã dùng — lý do tương tự ở trên.
            Map<Integer, Integer> stockMap =
                    com.medicare.config.CacheManager.getShort("med.stockMap", batchesDAO::getTotalQuantityMap);
            StringBuilder sb = new StringBuilder("{");
            boolean first = true;
            for (Map.Entry<Integer, Integer> entry : stockMap.entrySet()) {
                if (!first) sb.append(',');
                sb.append('"').append(entry.getKey()).append("\":")
                  .append(entry.getValue() != null ? entry.getValue() : 0);
                first = false;
            }
            sb.append('}');
            return sb.toString();
        } catch (Exception e) {
            return "{}";
        }
    }
}
