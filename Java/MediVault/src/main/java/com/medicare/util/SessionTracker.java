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
    // Dùng khi: staff bấm nút Đăng nhập (StaffLoginServlet)
    public static String login(int accountId) {
        onlineStaff.add(accountId);
        String token = UUID.randomUUID().toString().replace("-", "").substring(0, 16);
        loginTokens.put(accountId, token);
        return token;
    }

    // ── LoginOrKeep: giữ token cũ nếu còn, tạo mới nếu chưa có ──
    // Dùng khi: AuthFilter tự restore session (F5, Tomcat restart)
    // Quan trọng: KHÔNG tạo token mới → tránh kick browser đang dùng
    public static String loginOrKeep(int accountId) {
        onlineStaff.add(accountId);
        return loginTokens.computeIfAbsent(accountId,
                k -> UUID.randomUUID().toString().replace("-", "").substring(0, 16));
    }

    // ── Logout: xóa khỏi online set + xóa token ────────────
    public static void logout(int accountId) {
        onlineStaff.remove(accountId);
        loginTokens.remove(accountId);
    }

    // ── Kiểm tra session hợp lệ ─────────────────────────────
    public static boolean isValidSession(int accountId, String token, String tabId) {
        if (token == null || token.isEmpty()) return false;
        String current = loginTokens.get(accountId);
        // Nếu loginTokens bị xóa (Tomcat restart) → không kick ngay
        // Browser sẽ tự navigate lại và AuthFilter sẽ restore + loginOrKeep
        if (current == null) return true; // grace: coi như OK, đừng kick
        return token.equals(current);
    }

    // ── Lấy token hiện tại (để StaffAttendanceServlet inject vào page) ──
    public static String getToken(int accountId) {
        return loginTokens.get(accountId);
    }

    // ── Getters ──────────────────────────────────────────────
    public static boolean isOnline(int accountId) {
        return onlineStaff.contains(accountId);
    }

    public static Set<Integer> getOnlineSet() {
        return Collections.unmodifiableSet(onlineStaff);
    }
}