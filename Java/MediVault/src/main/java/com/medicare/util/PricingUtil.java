package com.medicare.util;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * PricingUtil — NGUỒN CHÂN LÝ về tính tiền cho MediVault (VND, đồng nguyên, scale = 0).
 *
 * <p>Toàn bộ phép tính tiền tệ đi qua đây để đảm bảo 3 bất biến tài chính:
 * <ol>
 *   <li><b>Sàn tuyệt đối</b>: tổng phải trả không bao giờ &lt; 0.</li>
 *   <li><b>Trần giảm giá</b>: số tiền giảm không bao giờ vượt quá tiền hàng
 *       (giảm cố định lớn hơn subtotal ⇒ tổng đúng bằng 0).</li>
 *   <li><b>Không giảm âm</b>: giảm giá âm bị kẹp về 0 (tránh "giảm âm" làm THỔI PHỒNG tổng).</li>
 * </ol>
 *
 * <p>VND không có đơn vị lẻ (không có "xu") nên mọi giá trị được làm tròn HALF_UP về
 * đồng nguyên (scale = 0). Rủi ro sai số float thực chất chỉ nằm ở phép tính phần trăm
 * — đó là lý do {@link #calculateFinalTotal} làm tròn tường minh ngay tại bước chia.
 *
 * <p><b>Cảnh báo:</b> Tuyệt đối KHÔNG tin số tiền do client gửi lên. Server luôn tự
 * đọc subtotal từ DB rồi gọi {@link #settle} để kẹp lại số tiền giảm trước khi ghi.
 */
public final class PricingUtil {

    private PricingUtil() {}

    /** Hai loại giảm giá được hỗ trợ. */
    public enum DiscountType { PERCENTAGE, FIXED_AMOUNT }

    private static final BigDecimal HUNDRED = BigDecimal.valueOf(100);

    /**
     * Kết quả tính tiền — bất biến: {@code discount <= subtotal}, {@code total = subtotal - discount},
     * {@code total >= 0}. Tất cả đều là đồng nguyên (scale = 0).
     */
    public static final class PriceResult {
        public final BigDecimal subtotal;
        public final BigDecimal discount;
        public final BigDecimal total;

        PriceResult(BigDecimal subtotal, BigDecimal discount, BigDecimal total) {
            this.subtotal = subtotal;
            this.discount = discount;
            this.total    = total;
        }
    }

    /**
     * Kẹp một số tiền giảm ĐÃ TÍNH SẴN (đồng) vào khoảng hợp lệ [0, subtotal] rồi tính tổng cuối.
     *
     * <p>Đây là hàm server dùng ở luồng thanh toán: client có thể gửi lên bất kỳ số nào
     * (âm, hoặc lớn hơn tiền hàng) — hàm này bảo đảm hóa đơn ghi vào DB luôn hợp lệ:
     * <ul>
     *   <li>discount &lt; 0  → kẹp về 0 (không cho giảm âm thổi phồng tổng)</li>
     *   <li>discount &gt; subtotal → kẹp về subtotal (tổng = 0, không âm)</li>
     * </ul>
     *
     * @param subtotal    tổng tiền hàng do SERVER tự tính (SUM SubTotal); null/âm coi như 0
     * @param rawDiscount số tiền giảm client gửi lên (có thể bất hợp lệ); null coi như 0
     * @return kết quả đã kẹp an toàn — không bao giờ ném lỗi, luôn cho ra hóa đơn hợp lệ
     */
    public static PriceResult settle(BigDecimal subtotal, BigDecimal rawDiscount) {
        BigDecimal base = nonNull(subtotal).max(BigDecimal.ZERO).setScale(0, RoundingMode.HALF_UP);
        BigDecimal raw  = nonNull(rawDiscount).setScale(0, RoundingMode.HALF_UP);

        // Kẹp discount vào [0, base]: chặn cả giảm âm lẫn giảm quá tay.
        BigDecimal discount = raw.max(BigDecimal.ZERO).min(base);
        BigDecimal total    = base.subtract(discount);   // luôn >= 0 do discount <= base
        return new PriceResult(base, discount, total);
    }

    /**
     * Tính tổng cuối từ LOẠI + GIÁ TRỊ giảm giá — financial-grade engine.
     *
     * @param subtotal tổng tiền hàng (&gt;= 0)
     * @param type     {@link DiscountType}; {@code null} ⇒ không giảm giá
     * @param value    với PERCENTAGE: phần trăm trong [0, 100]; với FIXED_AMOUNT: số tiền (&gt;= 0)
     * @return kết quả với 3 bất biến tài chính được bảo đảm
     * @throws IllegalArgumentException nếu subtotal âm, value âm/sai, hoặc phần trăm ngoài [0, 100]
     */
    public static PriceResult calculateFinalTotal(BigDecimal subtotal, DiscountType type, BigDecimal value) {
        if (subtotal == null || subtotal.signum() < 0)
            throw new IllegalArgumentException("subtotal phải >= 0");

        BigDecimal base = subtotal.setScale(0, RoundingMode.HALF_UP);
        BigDecimal discount;

        if (type == null) {
            discount = BigDecimal.ZERO;
        } else switch (type) {
            case PERCENTAGE:
                if (value == null || value.signum() < 0 || value.compareTo(HUNDRED) > 0)
                    throw new IllegalArgumentException("Phần trăm giảm phải trong [0, 100]");
                // (base × %) ÷ 100, làm tròn nửa-lên về đồng nguyên tại đúng bước chia.
                discount = base.multiply(value).divide(HUNDRED, 0, RoundingMode.HALF_UP);
                break;
            case FIXED_AMOUNT:
                if (value == null || value.signum() < 0)
                    throw new IllegalArgumentException("Số tiền giảm phải >= 0");
                discount = value.setScale(0, RoundingMode.HALF_UP).min(base); // trần = base
                break;
            default:
                throw new IllegalArgumentException("Loại giảm giá không hợp lệ: " + type);
        }

        BigDecimal total = base.subtract(discount).max(BigDecimal.ZERO); // sàn tuyệt đối = 0
        return new PriceResult(base, discount, total);
    }

    private static BigDecimal nonNull(BigDecimal v) {
        return v != null ? v : BigDecimal.ZERO;
    }
}
