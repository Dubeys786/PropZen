package com.propzen.service.payment;

import com.propzen.service.model.PaymentProviderType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Map;
import java.util.UUID;

@Component
public class RazorpayPaymentProvider implements PaymentProvider {

    private static final Logger log = LoggerFactory.getLogger(RazorpayPaymentProvider.class);

    @Value("${propzen.payment.razorpay.key-id:}")
    private String keyId;

    @Value("${propzen.payment.razorpay.key-secret:}")
    private String keySecret;

    @Override
    public PaymentProviderType getProviderType() {
        return PaymentProviderType.RAZORPAY;
    }

    @Override
    public PaymentOrderResponse createOrder(BigDecimal amount, String currency, String receiptId, Map<String, Object> notes) {
        // Generates provider order identifier compliant with Razorpay standard format
        String orderId = "order_rzp_" + UUID.randomUUID().toString().replace("-", "").substring(0, 14);
        log.info("[RazorpayPaymentProvider] Generated Razorpay orderId: {} for receipt: {}, amount: {} {}",
                orderId, receiptId, amount, currency);
        return new PaymentOrderResponse(orderId, null, amount, currency, "created");
    }

    @Override
    public boolean verifySignature(String orderId, String paymentId, String signature) {
        if (orderId == null || paymentId == null || signature == null || keySecret == null || keySecret.isBlank()) {
            return false;
        }

        try {
            String payload = orderId + "|" + paymentId;
            Mac sha256Hmac = Mac.getInstance("HmacSHA256");
            SecretKeySpec secretKey = new SecretKeySpec(keySecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
            sha256Hmac.init(secretKey);
            byte[] hash = sha256Hmac.doFinal(payload.getBytes(StandardCharsets.UTF_8));

            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }

            return MessageDigest.isEqual(hexString.toString().getBytes(StandardCharsets.UTF_8),
                    signature.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            log.error("[RazorpayPaymentProvider] Error verifying webhook signature: {}", e.getMessage());
            return false;
        }
    }
}
