package com.medivault.util;

import java.util.Collections;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Theo dõi nhân viên đang online (đã đăng nhập, chưa logout).
 * Dùng ConcurrentHashMap để thread-safe với Tomcat multi-thread.
 */
public class SessionTracker {

    private static final Set<Integer> onlineStaff =
            Collections.newSetFromMap(new ConcurrentHashMap<>());

    /** Gọi khi staff login thành công */
    public static void login(int accountId) {
        onlineStaff.add(accountId);
    }

    /** Gọi khi staff logout */
    public static void logout(int accountId) {
        onlineStaff.remove(accountId);
    }

    /** Kiểm tra 1 account có đang online không */
    public static boolean isOnline(int accountId) {
        return onlineStaff.contains(accountId);
    }

    /** Trả về toàn bộ set (read-only) — dùng để pass vào JSP */
    public static Set<Integer> getOnlineSet() {
        return Collections.unmodifiableSet(onlineStaff);
    }
}