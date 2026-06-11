package com.medicare.util;

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

    // ── Login: thêm vào online set + tạo token mới ──────────
    public static String login(int accountId) {
        onlineStaff.add(accountId);
        String token = UUID.randomUUID().toString().replace("-", "").substring(0, 16);
        loginTokens.put(accountId, token);
        return token;
    }

    // ── Logout: xóa khỏi online set + xóa token ────────────
    public static void logout(int accountId) {
        onlineStaff.remove(accountId);
        loginTokens.remove(accountId);
    }

    // ── Kiểm tra session hợp lệ (chỉ token, bỏ tabId) ──────
    // tabId giữ trong signature để không đổi StaffPingServlet
    public static boolean isValidSession(int accountId, String token, String tabId) {
        return token != null && token.equals(loginTokens.get(accountId));
    }

    // ── Getters ──────────────────────────────────────────────
    public static boolean isOnline(int accountId) {
        return onlineStaff.contains(accountId);
    }

    public static Set<Integer> getOnlineSet() {
        return Collections.unmodifiableSet(onlineStaff);
    }
}