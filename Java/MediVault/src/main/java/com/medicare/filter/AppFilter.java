package com.medicare.filter;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.*;

import java.io.*;
import java.util.zip.GZIPOutputStream;

/**
 * AppFilter v2 — GZIP compression + Cache-Control headers.
 *
 * GZIP: giảm kích thước HTML response ~65-75%.
 *   shift-list.jsp:  ~80KB → ~15KB sau GZIP
 *   dashboard.jsp:   ~40KB → ~8KB  sau GZIP
 *
 * Cache-Control:
 *   Static assets (CSS/JS/images): cache 7 ngày ở browser
 *   HTML pages: no-cache (luôn fresh data)
 */
@WebFilter(urlPatterns = "/*", asyncSupported = true)
public class AppFilter implements Filter {

    private static final int GZIP_MIN_SIZE = 2048; // chỉ GZIP nếu > 2KB

    @Override
    public void init(FilterConfig cfg) {}

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  req  = (HttpServletRequest)  request;
        HttpServletResponse resp = (HttpServletResponse) response;

        String uri = req.getRequestURI();

        // ── Force UTF-8 Encoding ──────────────────────────────────────────
        req.setCharacterEncoding("UTF-8");
        resp.setCharacterEncoding("UTF-8");

        // ── Cache-Control headers ─────────────────────────────────────────
        if (isStaticAsset(uri)) {
            // Browser cache 7 ngày cho static files
            resp.setHeader("Cache-Control", "public, max-age=604800, immutable");
        } else {
            // HTML/JSON: không cache
            resp.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
            resp.setHeader("Pragma",        "no-cache");
        }

        // ── Security headers ──────────────────────────────────────────────
        resp.setHeader("X-Content-Type-Options",  "nosniff");
        resp.setHeader("X-Frame-Options",         "SAMEORIGIN");
        resp.setHeader("X-XSS-Protection",        "1; mode=block");
        resp.setHeader("Referrer-Policy",         "strict-origin-when-cross-origin");
        // CSP: cho phép fonts từ Google, Chart.js từ cdnjs, inline styles/scripts (cần cho JSP)
        resp.setHeader("Content-Security-Policy",
                "default-src 'self'; "
                + "script-src 'self' 'unsafe-inline' 'unsafe-eval' "
                + "  https://fonts.googleapis.com "
                + "  https://cdnjs.cloudflare.com "
                + "  https://cdn.jsdelivr.net; "
                + "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com https://fonts.gstatic.com; "
                + "font-src 'self' https://fonts.gstatic.com data:; "
                + "img-src 'self' data: blob:; "
                + "media-src 'self' data: blob:; "
                + "connect-src 'self' https://cdnjs.cloudflare.com https://cdn.jsdelivr.net; "
                + "frame-ancestors 'self';");

        // ── CSRF: phát token cho trang, và CHẶN mọi POST không kèm token hợp lệ ──────
        // Trước đây chỉ có dòng injectToRequest(): token được sinh ra, JSP in ra, nhưng
        // KHÔNG nơi nào gọi isValid() — nghĩa là toàn bộ POST của hệ thống không hề được
        // bảo vệ, kể cả 2 form đã chịu khó gửi kèm _csrf. Phần validate bên dưới mới là
        // thứ thực sự chặn tấn công CSRF.
        if (!isStaticAsset(uri)) {
            com.medicare.util.CsrfUtil.injectToRequest(req);

            if (com.medicare.util.CsrfUtil.requiresValidation(req)
                    && !com.medicare.util.CsrfUtil.isValid(req)) {
                rejectCsrf(req, resp);
                return;   // dừng hẳn — KHÔNG cho request đi tiếp vào servlet
            }
        }

        // ── GZIP Compression ──────────────────────────────────────────────
        String acceptEncoding = req.getHeader("Accept-Encoding");
        boolean supportsGzip  = acceptEncoding != null
                && acceptEncoding.contains("gzip");
        boolean isHtmlOrJson  = isCompressible(uri);

        if (supportsGzip && isHtmlOrJson) {
            GzipResponseWrapper gzipResp = new GzipResponseWrapper(resp);
            try {
                chain.doFilter(req, gzipResp);
            } finally {
                gzipResp.finish(); // luôn flush/đóng GZIP, kể cả khi servlet ném lỗi
            }
        } else {
            chain.doFilter(req, resp);
        }
    }

    @Override
    public void destroy() {}

    // ── Helpers ───────────────────────────────────────────────────────────

    /**
     * Trả lời khi token CSRF thiếu/sai. Phân biệt AJAX (trả JSON để JS đọc được) và
     * điều hướng thường (trả trang HTML giải thích, tránh người dùng gặp trang trắng 403).
     */
    private void rejectCsrf(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        // Log rõ ràng: nếu sau này có form nào bị chặn oan vì quên gắn token,
        // dòng này chỉ thẳng ra endpoint nào đang thiếu.
        System.err.println("[CSRF] Đã chặn " + req.getMethod() + " " + req.getRequestURI()
                + " — thiếu hoặc sai token (_csrf / X-CSRF-Token)");

        resp.reset();
        resp.setStatus(HttpServletResponse.SC_FORBIDDEN);
        resp.setHeader("Cache-Control", "no-store");

        String accept = req.getHeader("Accept");
        boolean wantsJson = "XMLHttpRequest".equals(req.getHeader("X-Requested-With"))
                || (accept != null && accept.contains("application/json"));

        if (wantsJson) {
            resp.setContentType("application/json;charset=UTF-8");
            resp.getWriter().print("{\"ok\":false,\"error\":\"csrf\",\"msg\":"
                    + "\"Phiên làm việc đã hết hạn hoặc yêu cầu không hợp lệ. Vui lòng tải lại trang.\"}");
        } else {
            resp.setContentType("text/html;charset=UTF-8");
            resp.getWriter().print(
                "<!DOCTYPE html><html lang=\"vi\"><head><meta charset=\"UTF-8\">"
              + "<title>Yêu cầu bị từ chối</title></head><body>"
              + "<div style=\"font-family:system-ui,-apple-system,sans-serif;max-width:520px;"
              + "margin:60px auto;padding:24px;border:1px solid #FCA5A5;background:#FEF2F2;"
              + "border-radius:12px;color:#7F1D1D\">"
              + "<h2 style=\"margin:0 0 10px;font-size:19px\">⛔ Yêu cầu bị từ chối</h2>"
              + "<p style=\"margin:0 0 14px;line-height:1.65;font-size:14px\">Phiên làm việc đã hết hạn, "
              + "hoặc thao tác này không xuất phát từ trang của hệ thống (cơ chế chống CSRF).</p>"
              + "<p style=\"margin:0;font-size:14px\"><a href=\"" + req.getContextPath() + "/\" "
              + "style=\"color:#B91C1C;font-weight:700\">← Quay lại trang chủ và thử lại</a></p>"
              + "</div></body></html>");
        }
    }

    private boolean isStaticAsset(String uri) {
        return uri.endsWith(".css") || uri.endsWith(".js")
                || uri.endsWith(".png") || uri.endsWith(".jpg")
                || uri.endsWith(".ico") || uri.endsWith(".woff")
                || uri.endsWith(".woff2") || uri.endsWith(".svg");
    }

    private boolean isCompressible(String uri) {
        // GZIP cho HTML (JSP output) và JSON API
        return !isStaticAsset(uri); // mọi thứ không phải static đều compress
    }

    // ════════════════════════════════════════════════════════════════════
    //  GZIP Response Wrapper
    // ════════════════════════════════════════════════════════════════════

    static class GzipResponseWrapper extends HttpServletResponseWrapper {
        private GzipOutputStream gzipOut;
        private PrintWriter      gzipWriter;
        private final HttpServletResponse original;

        GzipResponseWrapper(HttpServletResponse resp) {
            super(resp);
            this.original = resp;
        }

        @Override
        public ServletOutputStream getOutputStream() throws IOException {
            if (gzipOut == null) {
                original.setHeader("Content-Encoding", "gzip");
                original.addHeader("Vary", "Accept-Encoding");
                gzipOut = new GzipOutputStream(original.getOutputStream());
            }
            return gzipOut;
        }

        @Override
        public PrintWriter getWriter() throws IOException {
            if (gzipWriter == null) {
                gzipWriter = new PrintWriter(
                        new OutputStreamWriter(getOutputStream(),
                                getCharacterEncoding() != null ? getCharacterEncoding() : "UTF-8"));
            }
            return gzipWriter;
        }

        // Không set Content-Length khi dùng GZIP (kích thước thay đổi)
        @Override public void setContentLength(int len)      {}
        @Override public void setContentLengthLong(long len) {}

        private boolean finished = false;

        void finish() throws IOException {
            if (finished) return;   // chống gọi finish() 2 lần (double-finish → Deflater đã đóng)
            finished = true;
            // Nếu servlet đã ném lỗi giữa chừng, deflater có thể đã đóng → nuốt lỗi,
            // tránh IllegalStateException "Deflater has been closed" nổi lên thành SEVERE 500.
            try {
                if (gzipWriter != null) { gzipWriter.flush(); }
                if (gzipOut   != null)  { gzipOut.finish(); gzipOut.close(); }
            } catch (IOException | IllegalStateException ignored) {}
        }
    }

    // ── GZIP ServletOutputStream ──────────────────────────────────────────
    static class GzipOutputStream extends ServletOutputStream {
        private final GZIPOutputStream gzip;
        private final ServletOutputStream underlying;

        GzipOutputStream(ServletOutputStream os) throws IOException {
            this.underlying = os;
            this.gzip       = new GZIPOutputStream(os, 8192); // 8KB buffer
        }

        @Override public void  write(int b)           throws IOException { gzip.write(b); }
        @Override public void  write(byte[] b)        throws IOException { gzip.write(b); }
        @Override public void  write(byte[] b, int o, int l) throws IOException { gzip.write(b, o, l); }
        @Override public void  flush()                throws IOException { gzip.flush(); }
        @Override public boolean isReady()                               { return true; }
        @Override public void  setWriteListener(WriteListener wl)       {}

        void finish() throws IOException { gzip.finish(); }

        @Override public void close() throws IOException {
            try { gzip.finish(); } catch (IOException ignored) {}
            underlying.close();
        }
    }
}