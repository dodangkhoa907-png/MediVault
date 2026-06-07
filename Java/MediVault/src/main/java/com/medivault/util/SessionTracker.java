package com.medivault.util;

import java.util.Collections;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * SessionTracker — Theo dõi staff online + single-session enforcement.
 *
 * Single session: mỗi staff chỉ được login 1 tab tại 1 thời điểm.
 * Khi login mới → tạo token mới → token cũ bị invalidate → tab cũ bị kick.
 */
public class SessionTracker {

    // ── Online set ──────────────────────────────────────────
    private static final Set<Integer> onlineStaff =
            Collections.newSetFromMap(new ConcurrentHashMap<>());

    // ── Login token map: accountId → token ──────────────────
    // Token mới ghi đè token cũ → tab cũ ping sẽ thấy token không khớp → bị kick
    private static final ConcurrentHashMap<Integer, String> loginTokens =
            new ConcurrentHashMap<>();
    private static final ConcurrentHashMap<Integer, String> activeTabIds =
            new ConcurrentHashMap<>();

    // ── Login: thêm vào online set + tạo token mới ──────────
    /**
     * Gọi khi staff login thành công.
     * @return token mới — truyền xuống tab qua URL ?uid=X&token=TOKEN
     */
    public static String login(int accountId) {
        onlineStaff.add(accountId);
        String token = UUID.randomUUID().toString().replace("-", "").substring(0, 16);
        loginTokens.put(accountId, token);
        activeTabIds.remove(accountId);
        return token;
    }

    // ── Logout: xóa khỏi online set + xóa token ────────────
    public static void logout(int accountId) {
        onlineStaff.remove(accountId);
        loginTokens.remove(accountId);
    }

    // ── Kiểm tra token còn hợp lệ không ────────────────────
    /**
     * @return true nếu token khớp (tab này vẫn là session hợp lệ)
     *         false nếu token không khớp (đã bị tab mới kick)
     */
    // ── Kiểm tra session hợp lệ (token + tabId) ────────────
    public static boolean isValidSession(int accountId, String token, String tabId) {
        // Bước 1: token phải khớp
        if (token == null || !token.equals(loginTokens.get(accountId))) return false;
        // Bước 2: tabId phải hợp lệ
        if (tabId == null || tabId.isEmpty()) return false;
        String registered = activeTabIds.get(accountId);
        if (registered == null) {
            // Lần đầu ping → đăng ký tabId này
            activeTabIds.put(accountId, tabId);
            return true;
        }
        // Tab đã đăng ký → chỉ đúng tabId mới được
        return registered.equals(tabId);
    }

    // ── Getters ──────────────────────────────────────────────
    public static boolean isOnline(int accountId) {
        return onlineStaff.contains(accountId);
    }

    public static Set<Integer> getOnlineSet() {
        return Collections.unmodifiableSet(onlineStaff);
    }
}

