package com.medicare.controller.pos;

import jakarta.servlet.AsyncContext;
import jakarta.servlet.AsyncEvent;
import jakarta.servlet.AsyncListener;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * NfcBridgeServlet — Cầu nối realtime "điện thoại quét thẻ → màn hình POS".
 *
 * Bài toán: đầu đọc NFC là ĐIỆN THOẠI (app NFC Tools / app tự build), còn màn
 * bán hàng là TRÌNH DUYỆT trên PC. Hai thiết bị khác nhau nên PC không tự biết
 * điện thoại vừa quét thẻ gì — cần một kênh đẩy (push) từ server ra trình duyệt.
 *
 * Cơ chế: pub/sub theo QUẦY POS (posStation) qua Server-Sent Events (SSE).
 *   - GET  /pos/nfc-stream?station=N  → màn POS mở EventSource, "lắng nghe" quầy N.
 *   - POST /pos/nfc-scan?station=N&uid=XXXX → điện thoại bắn UID vừa quét về quầy N.
 *     Server đẩy sự kiện SSE tới mọi màn POS đang nghe quầy N.
 *
 * Servlet này CỐ TÌNH "ngu" — chỉ chuyển tiếp UID, KHÔNG tra DB. Trình duyệt POS
 * nhận UID rồi tự gọi /pos?action=nfc-lookup (tái dùng logic + cảnh báo dị ứng
 * sẵn có). Nhờ vậy phần realtime tách bạch, dễ test và bảo trì.
 *
 * Ghi chú bảo mật (MVP/LAN): endpoint scan chưa có token. Trong mạng nội bộ nhà
 * thuốc là chấp nhận được; khi mở ra ngoài nên thêm shared-secret theo quầy.
 */
@WebServlet(urlPatterns = {"/pos/nfc-stream", "/pos/nfc-scan"}, asyncSupported = true)
public class NfcBridgeServlet extends HttpServlet {

    /** station → danh sách màn POS đang lắng nghe (mỗi màn = 1 AsyncContext SSE). */
    private static final Map<Integer, List<AsyncContext>> SUBS = new ConcurrentHashMap<>();

    /** Heartbeat giữ kết nối SSE sống và dọn kết nối chết (proxy/nhàn rỗi hay ngắt). */
    private static final ScheduledExecutorService HEARTBEAT =
            Executors.newSingleThreadScheduledExecutor(r -> {
                Thread t = new Thread(r, "nfc-sse-heartbeat");
                t.setDaemon(true);
                return t;
            });

    @Override
    public void init() {
        HEARTBEAT.scheduleAtFixedRate(NfcBridgeServlet::pingAll, 20, 20, TimeUnit.SECONDS);
    }

    @Override
    public void destroy() {
        HEARTBEAT.shutdownNow();
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        if (req.getServletPath().endsWith("nfc-stream")) handleStream(req, resp);
        else handleScan(req, resp); // cho phép GET để dễ test từ browser điện thoại
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        handleScan(req, resp);
    }

    // ── Màn POS đăng ký lắng nghe 1 quầy ─────────────────────────────────────
    private void handleStream(HttpServletRequest req, HttpServletResponse resp) {
        int station = parseStation(req);
        resp.setContentType("text/event-stream");
        resp.setCharacterEncoding("UTF-8");
        resp.setHeader("Cache-Control", "no-cache, no-store");
        resp.setHeader("Connection", "keep-alive");
        resp.setHeader("X-Accel-Buffering", "no"); // tắt buffer nếu chạy sau nginx

        final AsyncContext ac = req.startAsync();
        ac.setTimeout(0); // không timeout — giữ mở tới khi client đóng

        final List<AsyncContext> list =
                SUBS.computeIfAbsent(station, k -> new CopyOnWriteArrayList<>());
        list.add(ac);

        ac.addListener(new AsyncListener() {
            @Override public void onComplete(AsyncEvent e)  { list.remove(ac); }
            @Override public void onTimeout(AsyncEvent e)   { list.remove(ac); safeComplete(ac); }
            @Override public void onError(AsyncEvent e)      { list.remove(ac); }
            @Override public void onStartAsync(AsyncEvent e) { }
        });

        try {
            PrintWriter w = ac.getResponse().getWriter();
            w.write(": connected station " + station + "\n\n");
            w.flush();
        } catch (IOException ignored) {
            list.remove(ac);
            safeComplete(ac);
        }
    }

    // ── Điện thoại bắn UID vừa quét về 1 quầy ────────────────────────────────
    private void handleScan(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        resp.setContentType("application/json;charset=UTF-8");
        resp.setHeader("Cache-Control", "no-store");
        resp.setHeader("Access-Control-Allow-Origin", "*"); // app mobile gọi cross-origin
        resp.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");

        int station = parseStation(req);
        String uid = req.getParameter("uid");
        if (uid == null || uid.trim().isEmpty()) {
            resp.getWriter().print("{\"ok\":false,\"reason\":\"missing_uid\"}");
            return;
        }
        // Chỉ giữ ký tự an toàn cho UID (hex + vài dấu ngăn cách) rồi CHUẨN HÓA HOA
        uid = uid.trim().toUpperCase().replaceAll("[^0-9A-F:\\- ]", "");
        if (uid.isEmpty()) {
            resp.getWriter().print("{\"ok\":false,\"reason\":\"invalid_uid\"}");
            return;
        }

        int delivered = push(station, "{\"uid\":\"" + uid + "\"}");
        resp.getWriter().print(
                "{\"ok\":true,\"station\":" + station + ",\"delivered\":" + delivered + "}");
    }

    // ── Đẩy sự kiện SSE tới mọi màn POS của 1 quầy ───────────────────────────
    private static int push(int station, String jsonData) {
        List<AsyncContext> list = SUBS.get(station);
        if (list == null || list.isEmpty()) return 0;
        int n = 0;
        for (AsyncContext ac : list) {
            try {
                PrintWriter w = ac.getResponse().getWriter();
                w.write("event: nfc\n");
                w.write("data: " + jsonData + "\n\n");
                w.flush();
                if (w.checkError()) throw new IOException("client gone");
                n++;
            } catch (Exception e) {
                list.remove(ac);
                safeComplete(ac);
            }
        }
        return n;
    }

    private static void pingAll() {
        for (List<AsyncContext> list : SUBS.values()) {
            for (AsyncContext ac : list) {
                try {
                    PrintWriter w = ac.getResponse().getWriter();
                    w.write(": ping\n\n");
                    w.flush();
                    if (w.checkError()) throw new IOException("client gone");
                } catch (Exception e) {
                    list.remove(ac);
                    safeComplete(ac);
                }
            }
        }
    }

    private static void safeComplete(AsyncContext ac) {
        try { ac.complete(); } catch (Exception ignored) {}
    }

    private int parseStation(HttpServletRequest req) {
        try {
            int s = Integer.parseInt(req.getParameter("station"));
            return s >= 1 ? s : 1;
        } catch (Exception e) {
            return 1; // mặc định quầy 1 cho trường hợp test nhanh
        }
    }
}
