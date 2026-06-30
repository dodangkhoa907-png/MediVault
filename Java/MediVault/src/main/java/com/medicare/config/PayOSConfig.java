package com.medicare.config;

/**
 * Cấu hình PayOS — điền thông tin từ dashboard.payos.vn
 * Hoặc set environment variables: PAYOS_CLIENT_ID, PAYOS_API_KEY, PAYOS_CHECKSUM_KEY
 */
public final class PayOSConfig {
    public static final String CLIENT_ID    = env("PAYOS_CLIENT_ID",    "bf2796c7-6b19-4eed-a1b9-7cc324cc24f9");
    public static final String API_KEY      = env("PAYOS_API_KEY",      "d6072c66-879c-47a1-8703-ba07e6347cce");
    public static final String CHECKSUM_KEY = env("PAYOS_CHECKSUM_KEY", "763aa74cc6c96a055d90ca6deede470dc2f2520f77589ef672f152710163b679");
    public static final String BASE_URL     = "https://api-merchant.payos.vn";
    /** Thời gian hết hạn QR (giây) — mặc định 5 phút */
    public static final int    EXPIRE_SECS  = 300;

    private PayOSConfig() {}

    private static String env(String name, String fallback) {
        String v = System.getenv(name);
        return (v != null && !v.isBlank()) ? v : fallback;
    }

    public static boolean isConfigured() {
        return !CLIENT_ID.startsWith("YOUR_")
            && !API_KEY.startsWith("YOUR_")
            && !CHECKSUM_KEY.startsWith("YOUR_");
    }
}
