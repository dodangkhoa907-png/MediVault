package com.medicare.service;

import java.util.List;

/**
 * Generic wrapper cho kết quả của một Service operation.
 * Dùng để truyền success/failure + data từ Service → Servlet mà không cần throw Exception.
 *
 * @param <T> kiểu dữ liệu trả về khi thành công
 */
public final class ServiceResult<T> {

    private final boolean ok;
    private final String  message;
    private final List<String> errors;
    private final T data;

    private ServiceResult(boolean ok, String message, List<String> errors, T data) {
        this.ok      = ok;
        this.message = message;
        this.errors  = errors;
        this.data    = data;
    }

    // ── Factory methods ──────────────────────────────────────────────────────

    /** Thành công, có dữ liệu trả về. */
    public static <T> ServiceResult<T> ok(T data) {
        return new ServiceResult<>(true, null, null, data);
    }

    /** Thành công, không có dữ liệu trả về. */
    public static <T> ServiceResult<T> ok() {
        return new ServiceResult<>(true, null, null, null);
    }

    /** Thất bại, kèm 1 thông báo lỗi. */
    public static <T> ServiceResult<T> fail(String message) {
        return new ServiceResult<>(false, message, null, null);
    }

    /** Thất bại, kèm danh sách lỗi validation (nhiều trường). */
    public static <T> ServiceResult<T> fail(List<String> errors) {
        return new ServiceResult<>(false, null, errors, null);
    }

    /** Thất bại, kèm cả message tổng và danh sách lỗi chi tiết. */
    public static <T> ServiceResult<T> fail(String message, List<String> errors) {
        return new ServiceResult<>(false, message, errors, null);
    }

    // ── Getters ──────────────────────────────────────────────────────────────

    public boolean isOk()          { return ok; }
    public boolean isFail()        { return !ok; }
    public String  getMessage()    { return message; }
    public List<String> getErrors(){ return errors; }
    public T       getData()       { return data; }

    /** Trả về message đầu tiên: nếu có errors list thì lấy phần tử đầu, nếu không thì dùng message. */
    public String firstError() {
        if (errors != null && !errors.isEmpty()) return errors.get(0);
        return message;
    }

    /** Kiểm tra xem có validation errors list không. */
    public boolean hasErrors() {
        return errors != null && !errors.isEmpty();
    }

    @Override
    public String toString() {
        return "ServiceResult{ok=" + ok + ", message='" + message + "', data=" + data + "}";
    }
}
