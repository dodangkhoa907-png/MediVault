package com.medicare.service.warehouse;

import java.util.ArrayList;
import java.util.List;

/** Kết quả kiểm tra 1 phiếu xuất kho trước khi ghi — lỗi cứng (errors) và thiếu hàng (shortfalls). */
public class ValidationResult {
    private final List<String> errors = new ArrayList<>();
    private final List<ShortfallInfo> shortfalls = new ArrayList<>();

    public List<String> getErrors() { return errors; }
    public List<ShortfallInfo> getShortfalls() { return shortfalls; }
    public boolean isValid() { return errors.isEmpty() && shortfalls.isEmpty(); }

    public void addError(String message) { errors.add(message); }
    public void addShortfall(ShortfallInfo shortfall) { shortfalls.add(shortfall); }
}
