package com.medicare.service;

import com.google.gson.*;
import com.medicare.config.PayOSConfig;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.*;

public final class PayOSService {

    private PayOSService() {}

    // ── HMAC-SHA256 ──────────────────────────────────────────────────────────────
    public static String hmacSha256(String data, String key) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(key.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        byte[] raw = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
        StringBuilder sb = new StringBuilder(64);
        for (byte b : raw) sb.append(String.format("%02x", b));
        return sb.toString();
    }

    // ── HTTP helpers ─────────────────────────────────────────────────────────────
    private static String http(String method, String url, String body) throws Exception {
        HttpURLConnection con = (HttpURLConnection) new URL(url).openConnection();
        con.setRequestMethod(method);
        con.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
        con.setRequestProperty("x-client-id", PayOSConfig.CLIENT_ID);
        con.setRequestProperty("x-api-key",   PayOSConfig.API_KEY);
        con.setConnectTimeout(12_000);
        con.setReadTimeout(15_000);
        if (body != null) {
            con.setDoOutput(true);
            try (OutputStream os = con.getOutputStream()) {
                os.write(body.getBytes(StandardCharsets.UTF_8));
            }
        }
        InputStream is;
        try { is = con.getInputStream(); }
        catch (IOException e) {
            is = con.getErrorStream();
        }
        if (is == null) return "{}";
        return new String(is.readAllBytes(), StandardCharsets.UTF_8);
    }

    // ── Create payment order ─────────────────────────────────────────────────────
    /**
     * Tạo đơn thanh toán QR VietQR trên PayOS.
     *
     * @param orderCode unique positive long (e.g. millis % 100_000_000)
     * @param amount    số tiền VND (>= 1000)
     * @param desc      mô tả ASCII-only, max 25 ký tự
     * @param baseUrl   scheme://host:port/contextPath
     * @return map: ok, qrCode, checkoutUrl, orderCode, amount — hoặc ok=false, msg
     */
    public static Map<String, Object> createPayment(long orderCode, long amount,
                                                     String desc, String baseUrl) throws Exception {
        String returnUrl = baseUrl + "/pos";
        String cancelUrl = baseUrl + "/pos";

        // Signature: sorted alphabetical fields
        String signData = "amount=" + amount
                + "&cancelUrl=" + cancelUrl
                + "&description=" + desc
                + "&orderCode=" + orderCode
                + "&returnUrl=" + returnUrl;
        String sig = hmacSha256(signData, PayOSConfig.CHECKSUM_KEY);

        JsonObject body = new JsonObject();
        body.addProperty("orderCode",   orderCode);
        body.addProperty("amount",      amount);
        body.addProperty("description", desc);
        body.addProperty("returnUrl",   returnUrl);
        body.addProperty("cancelUrl",   cancelUrl);
        body.addProperty("signature",   sig);
        body.addProperty("expiredAt",   System.currentTimeMillis() / 1000 + PayOSConfig.EXPIRE_SECS);

        String raw  = http("POST", PayOSConfig.BASE_URL + "/v2/payment-requests", body.toString());
        JsonObject resp = JsonParser.parseString(raw).getAsJsonObject();

        Map<String, Object> result = new LinkedHashMap<>();
        String code = resp.has("code") ? resp.get("code").getAsString() : "ERR";
        if ("00".equals(code)) {
            JsonObject data = resp.getAsJsonObject("data");
            result.put("ok",          true);
            result.put("qrCode",      data.has("qrCode")      ? data.get("qrCode").getAsString()      : "");
            result.put("checkoutUrl", data.has("checkoutUrl") ? data.get("checkoutUrl").getAsString() : "");
            result.put("orderCode",   orderCode);
            result.put("amount",      amount);
        } else {
            String msgVal = resp.has("desc") ? resp.get("desc").getAsString() : ("PayOS error code=" + code);
            result.put("ok",  false);
            result.put("msg", msgVal);
        }
        return result;
    }

    // ── Check status ─────────────────────────────────────────────────────────────
    /** @return "PENDING" | "PAID" | "CANCELLED" | "EXPIRED" | "UNKNOWN" */
    public static String checkStatus(long orderCode) throws Exception {
        String raw  = http("GET", PayOSConfig.BASE_URL + "/v2/payment-requests/" + orderCode, null);
        JsonObject resp = JsonParser.parseString(raw).getAsJsonObject();
        if ("00".equals(resp.has("code") ? resp.get("code").getAsString() : "")) {
            JsonObject data = resp.getAsJsonObject("data");
            return data.has("status") ? data.get("status").getAsString() : "UNKNOWN";
        }
        return "UNKNOWN";
    }

    // ── Cancel order ─────────────────────────────────────────────────────────────
    public static boolean cancelPayment(long orderCode) {
        try {
            JsonObject body = new JsonObject();
            body.addProperty("cancellationReason", "Hủy từ POS");
            String raw  = http("PUT", PayOSConfig.BASE_URL + "/v2/payment-requests/" + orderCode + "/cancel",
                               body.toString());
            JsonObject resp = JsonParser.parseString(raw).getAsJsonObject();
            return "00".equals(resp.has("code") ? resp.get("code").getAsString() : "");
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    // ── Verify webhook signature ──────────────────────────────────────────────────
    /** Dùng khi nhận webhook từ PayOS để xác thực tính hợp lệ */
    public static boolean verifyWebhook(Map<String, Object> webhookData, String webhookSignature) {
        try {
            // Sort fields alphabetically, build sign string
            List<String> keys = new ArrayList<>(webhookData.keySet());
            Collections.sort(keys);
            StringBuilder sb = new StringBuilder();
            for (String k : keys) {
                Object v = webhookData.get(k);
                if (v != null && !(v instanceof List) && !(v instanceof Map)) {
                    if (sb.length() > 0) sb.append('&');
                    sb.append(k).append('=').append(v);
                }
            }
            String computed = hmacSha256(sb.toString(), PayOSConfig.CHECKSUM_KEY);
            return computed.equalsIgnoreCase(webhookSignature);
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
}
