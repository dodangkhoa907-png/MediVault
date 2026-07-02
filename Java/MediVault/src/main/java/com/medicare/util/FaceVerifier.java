package com.medicare.util;

import com.medicare.entity.Account;

import java.util.List;

/**
 * FaceVerifier — logic so khớp khuôn mặt dùng chung cho toàn hệ thống.
 *
 * Nguyên tắc verify CHẶT (chống nhận nhầm người):
 *  1. Khoảng cách Euclidean giữa descriptor gửi lên và FaceVector của
 *     tài khoản được claim phải ≤ MATCH_THRESHOLD (0.45 — chặt hơn chuẩn
 *     0.6 của face-api.js vì môi trường nhà thuốc cần độ chính xác cao).
 *  2. So 1-vs-N: descriptor phải GẦN NHẤT với chính tài khoản đó trong
 *     toàn bộ danh sách nhân viên đã đăng ký mặt. Nếu có người khác gần
 *     hơn → từ chối (impersonation).
 *  3. Biên an toàn (margin): người gần nhì phải cách xa hơn người khớp
 *     ít nhất AMBIGUITY_MARGIN. Nếu hai người quá giống nhau → từ chối
 *     với lý do "ambiguous" thay vì đoán bừa.
 */
public final class FaceVerifier {

    /** Ngưỡng khớp — chặt hơn mặc định 0.6 của face-api.js */
    public static final double MATCH_THRESHOLD = 0.45;
    /** Người gần nhì phải xa hơn người khớp ít nhất chừng này */
    public static final double AMBIGUITY_MARGIN = 0.08;
    /** Ngưỡng coi là "cùng một khuôn mặt" khi chặn enroll trùng */
    public static final double DUPLICATE_THRESHOLD = 0.5;

    private FaceVerifier() {}

    /**
     * Verify descriptor với tài khoản được claim, đối chiếu 1-vs-N.
     *
     * @param claimedAccountId tài khoản mà client khẳng định là chủ khuôn mặt
     * @param descriptorJson   JSON array 128 số từ face-api.js
     * @param allEnrolled      toàn bộ account đã đăng ký mặt (accountId + faceVector)
     * @return "MATCH" | "missing_descriptor" | "invalid_descriptor"
     *         | "no_face_enrolled" | "no_match" | "impersonation" | "ambiguous"
     */
    public static String verify(int claimedAccountId, String descriptorJson,
                                List<Account> allEnrolled) {
        double[] incoming = parseDescriptor(descriptorJson);
        if (descriptorJson == null || descriptorJson.trim().isEmpty()) return "missing_descriptor";
        if (incoming == null || incoming.length != 128) return "invalid_descriptor";

        double claimedDist = Double.MAX_VALUE;   // khoảng cách tới chính chủ
        double bestOtherDist = Double.MAX_VALUE; // khoảng cách gần nhất tới NGƯỜI KHÁC
        boolean claimedEnrolled = false;

        for (Account acc : allEnrolled) {
            double[] stored = parseDescriptor(acc.getFaceVector());
            if (stored == null || stored.length != incoming.length) continue;
            double dist = euclideanDistance(stored, incoming);
            if (acc.getAccountId() == claimedAccountId) {
                claimedEnrolled = true;
                claimedDist = dist;
            } else if (dist < bestOtherDist) {
                bestOtherDist = dist;
            }
        }

        if (!claimedEnrolled) return "no_face_enrolled";
        if (claimedDist > MATCH_THRESHOLD) return "no_match";
        // Có người khác còn gần hơn chính chủ → chắc chắn nhầm người
        if (bestOtherDist < claimedDist) return "impersonation";
        // Người khác gần sát mức khó phân biệt → từ chối cho an toàn
        if (bestOtherDist - claimedDist < AMBIGUITY_MARGIN && bestOtherDist <= MATCH_THRESHOLD) {
            return "ambiguous";
        }
        return "MATCH";
    }

    /**
     * Tìm account khác đã đăng ký khuôn mặt GIỐNG descriptor này (chặn 1 mặt
     * đăng ký cho 2 tài khoản). Trả về account trùng, hoặc null nếu không trùng.
     */
    public static Account findDuplicateFace(String descriptorJson, int excludeAccountId,
                                            List<Account> allEnrolled) {
        double[] incoming = parseDescriptor(descriptorJson);
        if (incoming == null) return null;
        Account closest = null;
        double closestDist = Double.MAX_VALUE;
        for (Account acc : allEnrolled) {
            if (acc.getAccountId() == excludeAccountId) continue;
            double[] stored = parseDescriptor(acc.getFaceVector());
            if (stored == null || stored.length != incoming.length) continue;
            double dist = euclideanDistance(stored, incoming);
            if (dist < closestDist) { closestDist = dist; closest = acc; }
        }
        return (closest != null && closestDist <= DUPLICATE_THRESHOLD) ? closest : null;
    }

    /** Parse JSON array "[0.1,-0.2,...]" thành double[]. Trả null nếu format sai. */
    public static double[] parseDescriptor(String json) {
        if (json == null) return null;
        try {
            String trimmed = json.trim();
            if (!trimmed.startsWith("[") || !trimmed.endsWith("]")) return null;
            String inner = trimmed.substring(1, trimmed.length() - 1).trim();
            if (inner.isEmpty()) return new double[0];
            String[] parts = inner.split(",");
            double[] result = new double[parts.length];
            for (int i = 0; i < parts.length; i++) {
                result[i] = Double.parseDouble(parts[i].trim());
            }
            return result;
        } catch (Exception e) {
            return null;
        }
    }

    public static double euclideanDistance(double[] a, double[] b) {
        double sum = 0;
        for (int i = 0; i < a.length; i++) {
            double diff = a[i] - b[i];
            sum += diff * diff;
        }
        return Math.sqrt(sum);
    }
}
