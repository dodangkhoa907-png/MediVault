package com.medicare.util;

import java.nio.ByteBuffer;
import java.nio.CharBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.Charset;
import java.nio.charset.CharsetDecoder;
import java.nio.charset.CharsetEncoder;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;

/**
 * Sửa lỗi mojibake: dữ liệu UTF-8 bị lưu nhầm dưới dạng Windows-1252 bytes
 * trong SQL Server NVARCHAR trước khi cấu hình encoding được khắc phục.
 *
 * Xử lý 2 trường hợp:
 *   - Thuần mojibake (toàn bộ chuỗi sai) → decode toàn chuỗi qua CP1252 → UTF-8
 *   - Hỗn hợp (một phần đúng Unicode, một phần mojibake) → partial fix từng ký tự
 *
 * QUAN TRỌNG: mọi bước encode sang CP1252 dùng CharsetEncoder ở chế độ REPORT
 * (ném lỗi khi gặp ký tự không biểu diễn được), KHÔNG dùng String.getBytes(Charset)
 * vì API đó âm thầm thay ký tự không mã hóa được bằng '?' (REPLACE mặc định).
 * Tiếng Việt có dấu (ạ, ố, ư, đ...) không nằm trong CP1252 — nếu dùng getBytes()
 * trực tiếp, chuỗi tiếng Việt ĐÚNG sẽ bị biến thành các dấu '?' vô nghĩa.
 */
public final class MojibakeUtil {

    private static final Charset CP1252 = Charset.forName("windows-1252");

    private MojibakeUtil() {}

    public static String fix(String s) {
        if (s == null || s.isEmpty()) return s;

        // Bước 1: thử encode strict toàn chuỗi sang CP1252 rồi decode UTF-8
        // (chỉ thành công nếu MỌI ký tự trong chuỗi đều thuộc CP1252 — nghĩa là
        // chuỗi không thể là tiếng Việt có dấu đúng, an toàn để thử "sửa")
        try {
            byte[] bytes = encodeStrict(s);
            CharsetDecoder dec = StandardCharsets.UTF_8.newDecoder()
                .onMalformedInput(CodingErrorAction.REPORT)
                .onUnmappableCharacter(CodingErrorAction.REPORT);
            return dec.decode(ByteBuffer.wrap(bytes)).toString();
        } catch (Exception ignored) {}

        // Bước 2: partial fix — chỉ sửa từng đoạn byte mojibake hợp lệ,
        // giữ nguyên các ký tự không thuộc CP1252 (VD: tiếng Việt có dấu đúng)
        StringBuilder result = new StringBuilder(s.length());
        int i = 0;
        while (i < s.length()) {
            char c = s.charAt(i);
            Byte single = encodeCharStrict(c);
            if (single != null) {
                int b = single & 0xFF;
                // Kiểm tra xem byte này có phải là start byte của UTF-8 multi-byte không
                if (b >= 0xC2 && b <= 0xF4) {
                    int seqLen = (b <= 0xDF) ? 2 : (b <= 0xEF) ? 3 : 4;
                    if (i + seqLen <= s.length()) {
                        byte[] seq = new byte[seqLen];
                        seq[0] = single;
                        boolean valid = true;
                        for (int j = 1; j < seqLen; j++) {
                            Byte nb = encodeCharStrict(s.charAt(i + j));
                            if (nb == null) { valid = false; break; }
                            int nb0 = nb & 0xFF;
                            if (nb0 < 0x80 || nb0 > 0xBF) { valid = false; break; }
                            seq[j] = nb;
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

    private static byte[] encodeStrict(String s) throws CharacterCodingException {
        CharsetEncoder enc = CP1252.newEncoder()
            .onMalformedInput(CodingErrorAction.REPORT)
            .onUnmappableCharacter(CodingErrorAction.REPORT);
        ByteBuffer bb = enc.encode(CharBuffer.wrap(s));
        byte[] out = new byte[bb.remaining()];
        bb.get(out);
        return out;
    }

    /** Trả về byte CP1252 của 1 ký tự nếu mã hóa được, null nếu không (VD: tiếng Việt có dấu) */
    private static Byte encodeCharStrict(char c) {
        try {
            byte[] b = encodeStrict(String.valueOf(c));
            return b.length == 1 ? b[0] : null;
        } catch (Exception e) {
            return null;
        }
    }
}
