package com.medicare.util;

import java.security.SecureRandom;

public class OtpUtil {
    public static String generate(int length) {
        SecureRandom random = new SecureRandom();
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < length; i++)
            sb.append(random.nextInt(10));
        return sb.toString();
    }
}
