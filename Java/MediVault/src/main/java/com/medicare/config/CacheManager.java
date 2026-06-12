package com.medicare.config;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.github.benmanes.caffeine.cache.stats.CacheStats;

import java.util.concurrent.TimeUnit;
import java.util.function.Supplier;

/**
 * CacheManager — Caffeine-based cache cho các giá trị tính toán nặng.
 *
 * Dùng cho: Dashboard KPIs, medicine counts, expiry counts...
 * Các giá trị này mất 3–8 DB queries nhưng chỉ thay đổi vài phút/lần.
 *
 * Cách dùng:
 *   int cnt = CacheManager.get("dashboard.lowStock", 3, () -> medicineDAO.countLowStock());
 *   // → Lần đầu: gọi lambda, cache 3 phút
 *   // → Lần sau: trả từ cache (0ms)
 */
public class CacheManager {

    // ── Caches với các TTL khác nhau ───────────────────────────────────────
    /** Cache 3 phút — KPI counts, expiry lists (thay đổi khi có POS transaction) */
    private static final Cache<String, Object> CACHE_3MIN = Caffeine.newBuilder()
            .expireAfterWrite(3, TimeUnit.MINUTES)
            .maximumSize(200)
            .recordStats()  // bật stats để debug
            .build();

    /** Cache 5 phút — Dashboard aggregations, payroll summary */
    private static final Cache<String, Object> CACHE_5MIN = Caffeine.newBuilder()
            .expireAfterWrite(5, TimeUnit.MINUTES)
            .maximumSize(100)
            .recordStats()
            .build();

    /** Cache 15 phút — Audit log counts, report data */
    private static final Cache<String, Object> CACHE_15MIN = Caffeine.newBuilder()
            .expireAfterWrite(15, TimeUnit.MINUTES)
            .maximumSize(50)
            .recordStats()
            .build();

    // ══════════════════════════════════════════════════════════════════════
    //  PUBLIC API
    // ══════════════════════════════════════════════════════════════════════

    /**
     * Lấy từ cache 3 phút, nếu miss thì gọi loader.
     * @param key     unique cache key, vd "dashboard.lowStock"
     * @param loader  lambda trả về giá trị cần cache
     */
    @SuppressWarnings("unchecked")
    public static <T> T get(String key, Supplier<T> loader) {
        return (T) CACHE_3MIN.get(key, k -> loader.get());
    }

    /**
     * Cache 5 phút.
     */
    @SuppressWarnings("unchecked")
    public static <T> T get5(String key, Supplier<T> loader) {
        return (T) CACHE_5MIN.get(key, k -> loader.get());
    }

    /**
     * Cache 15 phút.
     */
    @SuppressWarnings("unchecked")
    public static <T> T get15(String key, Supplier<T> loader) {
        return (T) CACHE_15MIN.get(key, k -> loader.get());
    }

    // ── Invalidation ───────────────────────────────────────────────────────

    /** Xóa 1 key cụ thể khỏi tất cả caches */
    public static void invalidate(String key) {
        CACHE_3MIN.invalidate(key);
        CACHE_5MIN.invalidate(key);
        CACHE_15MIN.invalidate(key);
    }

    /** Xóa tất cả keys bắt đầu bằng prefix (vd "dashboard.") */
    public static void invalidatePrefix(String prefix) {
        CACHE_3MIN.asMap().keySet().removeIf(k -> k.startsWith(prefix));
        CACHE_5MIN.asMap().keySet().removeIf(k -> k.startsWith(prefix));
        CACHE_15MIN.asMap().keySet().removeIf(k -> k.startsWith(prefix));
    }

    /** Xóa toàn bộ cache */
    public static void invalidateAll() {
        CACHE_3MIN.invalidateAll();
        CACHE_5MIN.invalidateAll();
        CACHE_15MIN.invalidateAll();
    }

    // ── Stats ──────────────────────────────────────────────────────────────

    public static String stats() {
        CacheStats s3  = CACHE_3MIN.stats();
        CacheStats s5  = CACHE_5MIN.stats();
        CacheStats s15 = CACHE_15MIN.stats();
        return String.format(
                "CacheManager | 3min: hits=%d miss=%d rate=%.0f%% | "
                        + "5min: hits=%d miss=%d rate=%.0f%% | "
                        + "15min: hits=%d miss=%d rate=%.0f%%",
                s3.hitCount(),  s3.missCount(),  s3.hitRate()  * 100,
                s5.hitCount(),  s5.missCount(),  s5.hitRate()  * 100,
                s15.hitCount(), s15.missCount(), s15.hitRate() * 100
        );
    }
}