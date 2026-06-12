package com.medicare.config;

import com.medicare.dao.AccountDAO;
import com.medicare.dao.ShiftTypeDAO;
import com.medicare.dao.interfaces.IAccountDAO;
import com.medicare.dao.interfaces.IShiftTypeDAO;
import com.medicare.entity.Account;
import com.medicare.entity.ShiftType;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

/**
 * AppCache — In-memory cache cho dữ liệu ít thay đổi.
 *
 * Chiến lược: TTL-based, tự refresh khi stale.
 * Không cần thư viện ngoài — dùng ConcurrentHashMap + timestamp.
 *
 * Cache entries:
 *   allStaff      — 5 phút  (thay đổi khi admin thêm/sửa nhân viên)
 *   shiftTypes    — 10 phút (thay đổi khi admin sửa loại ca)
 *   accountMap    — 5 phút  (Map<Integer,Account> để lookup nhanh)
 *
 * Cách dùng:
 *   List<Account>       staff = AppCache.getStaff();
 *   List<ShiftType>     types = AppCache.getShiftTypes();
 *   Map<Integer,Account> map  = AppCache.getAccountMap();
 *   AppCache.invalidateStaff(); // gọi sau khi create/update account
 */
public class AppCache {

    // ── TTL (milliseconds) ─────────────────────────────────────────────────
    private static final long TTL_STAFF       = 5  * 60 * 1000L; // 5 phút
    private static final long TTL_SHIFT_TYPES = 10 * 60 * 1000L; // 10 phút
    private static final long TTL_ACCOUNT_MAP = 5  * 60 * 1000L; // 5 phút

    // ── DAO instances (stateless, safe to share) ───────────────────────────
    private static final IAccountDAO   accountDAO   = new AccountDAO();
    private static final IShiftTypeDAO shiftTypeDAO = new ShiftTypeDAO();

    // ── Cache storage ──────────────────────────────────────────────────────
    private static volatile List<Account>        _staff;
    private static volatile long                 _staffTime;

    private static volatile List<ShiftType>      _shiftTypes;
    private static volatile long                 _shiftTypesTime;

    private static volatile Map<Integer, Account> _accountMap;
    private static volatile long                  _accountMapTime;

    // ── Stats (để debug) ───────────────────────────────────────────────────
    private static long _hits   = 0;
    private static long _misses = 0;

    // ══════════════════════════════════════════════════════════════════════
    //  PUBLIC API
    // ══════════════════════════════════════════════════════════════════════

    /** Danh sách tất cả nhân viên (không gồm admin role=1) */
    public static List<Account> getStaff() {
        long now = System.currentTimeMillis();
        if (_staff == null || now - _staffTime > TTL_STAFF) {
            synchronized (AppCache.class) {
                if (_staff == null || now - _staffTime > TTL_STAFF) {
                    _staff     = accountDAO.findAllStaff();
                    _staffTime = System.currentTimeMillis();
                    _misses++;
                    return _staff;
                }
            }
        }
        _hits++;
        return _staff;
    }

    /** Danh sách loại ca active */
    public static List<ShiftType> getShiftTypes() {
        long now = System.currentTimeMillis();
        if (_shiftTypes == null || now - _shiftTypesTime > TTL_SHIFT_TYPES) {
            synchronized (AppCache.class) {
                if (_shiftTypes == null || now - _shiftTypesTime > TTL_SHIFT_TYPES) {
                    _shiftTypes     = shiftTypeDAO.findAllActive();
                    _shiftTypesTime = System.currentTimeMillis();
                    _misses++;
                    return _shiftTypes;
                }
            }
        }
        _hits++;
        return _shiftTypes;
    }

    /** Tất cả loại ca (kể cả inactive, cho admin) */
    public static List<ShiftType> getAllShiftTypes() {
        long now = System.currentTimeMillis();
        if (_shiftTypes == null || now - _shiftTypesTime > TTL_SHIFT_TYPES) {
            return getShiftTypes(); // đồng thời refresh cache active
        }
        _hits++;
        return _shiftTypes;
    }

    /** Map<AccountID, Account> để lookup O(1) thay vì loop */
    public static Map<Integer, Account> getAccountMap() {
        long now = System.currentTimeMillis();
        if (_accountMap == null || now - _accountMapTime > TTL_ACCOUNT_MAP) {
            synchronized (AppCache.class) {
                if (_accountMap == null || now - _accountMapTime > TTL_ACCOUNT_MAP) {
                    List<Account> all = accountDAO.findAll();
                    _accountMap     = all.stream()
                            .collect(Collectors.toConcurrentMap(
                                    Account::getAccountId, a -> a, (a, b) -> b));
                    _accountMapTime = System.currentTimeMillis();
                    _misses++;
                    return _accountMap;
                }
            }
        }
        _hits++;
        return _accountMap;
    }

    /** Lookup 1 account theo ID — từ cache Map */
    public static Account findAccount(int accountId) {
        return getAccountMap().get(accountId);
    }

    // ══════════════════════════════════════════════════════════════════════
    //  INVALIDATION — gọi khi data thay đổi
    // ══════════════════════════════════════════════════════════════════════

    /** Gọi sau khi tạo/sửa/xóa Account */
    public static void invalidateStaff() {
        _staff      = null;
        _staffTime  = 0;
        _accountMap = null;
        _accountMapTime = 0;
    }

    /** Gọi sau khi tạo/sửa/xóa ShiftType */
    public static void invalidateShiftTypes() {
        _shiftTypes     = null;
        _shiftTypesTime = 0;
    }

    /** Xóa tất cả cache (dùng khi cần force refresh) */
    public static void invalidateAll() {
        invalidateStaff();
        invalidateShiftTypes();
    }

    /** Stats để debug performance */
    public static String stats() {
        long total = _hits + _misses;
        double rate = total > 0 ? (double) _hits / total * 100 : 0;
        return String.format("AppCache: hits=%d misses=%d rate=%.1f%%", _hits, _misses, rate);
    }
}