package com.medicare.util;

import java.nio.ByteBuffer;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;

/**
 * Sửa lỗi mojibake: dữ liệu UTF-8 bị lưu nhầm dưới dạng Windows-1252 bytes
 * trong SQL Server NVARCHAR trước khi cấu hình encoding được khắc phục.
 *
 * Xử lý 2 trường hợp:
 *   - Thuần mojibake (toàn bộ chuỗi sai) → decode toàn chuỗi qua CP1252 → UTF-8
 *   - Hỗn hợp (một phần đúng Unicode, một phần mojibake) → partial fix từng ký tự
 */
public final class MojibakeUtil {

    private static final Charset CP1252 = Charset.forName("windows-1252");

    private MojibakeUtil() {}

    public static String fix(String s) {
        if (s == null || s.isEmpty()) return s;

        // Bước 1: Thử decode toàn bộ (trường hợp chuỗi thuần mojibake)
        try {
            byte[] bytes = s.getBytes(CP1252);
            CharsetDecoder dec = StandardCharsets.UTF_8.newDecoder()
                .onMalformedInput(CodingErrorAction.REPORT)
                .onUnmappableCharacter(CodingErrorAction.REPORT);
            return dec.decode(ByteBuffer.wrap(bytes)).toString();
        } catch (Exception ignored) {}

        // Bước 2: Partial fix — sửa từng chuỗi byte mojibake, giữ nguyên ký tự Unicode đúng
        StringBuilder result = new StringBuilder(s.length());
        int i = 0;
        while (i < s.length()) {
            char c = s.charAt(i);
            byte[] cb = String.valueOf(c).getBytes(CP1252);
            if (cb.length == 1) {
                int b = cb[0] & 0xFF;
                // Kiểm tra xem byte này có phải là start byte của UTF-8 multi-byte không
                if (b >= 0xC2 && b <= 0xF4) {
                    int seqLen = (b <= 0xDF) ? 2 : (b <= 0xEF) ? 3 : 4;
                    if (i + seqLen <= s.length()) {
                        byte[] seq = new byte[seqLen];
                        seq[0] = (byte) b;
                        boolean valid = true;
                        for (int j = 1; j < seqLen; j++) {
                            byte[] nb = String.valueOf(s.charAt(i + j)).getBytes(CP1252);
                            if (nb.length != 1) { valid = false; break; }
                            int nb0 = nb[0] & 0xFF;
                            if (nb0 < 0x80 || nb0 > 0xBF) { valid = false; break; }
                            seq[j] = (byte) nb0;
                        }
                        if (valid) {
                            result.append(new String(seq, StandardCharsets.UTF_8));
                            i += seqLen;
                            continue;
                        }
                    }
                }
            }
            result.append(c);
            i++;
        }
        return result.toString();
    }
}
