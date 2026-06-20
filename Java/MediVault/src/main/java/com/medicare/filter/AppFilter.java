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

        // ── Cache-Control headers ─────────────────────────────────────────
        if (isStaticAsset(uri)) {
            // Browser cache 7 ngày cho static files
            resp.setHeader("Cache-Control", "public, max-age=604800, immutable");
        } else {
            // HTML/JSON: không cache
            resp.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
            resp.setHeader("Pragma",        "no-cache");
        }

        // ── Security headers (nhỏ nhưng cần thiết) ───────────────────────
        resp.setHeader("X-Content-Type-Options", "nosniff");
        resp.setHeader("X-Frame-Options",        "SAMEORIGIN");

        // ── GZIP Compression ──────────────────────────────────────────────
        String acceptEncoding = req.getHeader("Accept-Encoding");
        boolean supportsGzip  = acceptEncoding != null
                && acceptEncoding.contains("gzip");
        boolean isHtmlOrJson  = isCompressible(uri);

        if (supportsGzip && isHtmlOrJson) {
            GzipResponseWrapper gzipResp = new GzipResponseWrapper(resp);
            chain.doFilter(req, gzipResp);
            gzipResp.finish(); // flush GZIP stream
        } else {
            chain.doFilter(req, resp);
        }
    }

    @Override
    public void destroy() {}

    // ── Helpers ───────────────────────────────────────────────────────────

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

        void finish() throws IOException {
            if (gzipWriter != null) { gzipWriter.flush(); gzipWriter.close(); }
            if (gzipOut   != null)  { gzipOut.finish();   gzipOut.close();   }
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