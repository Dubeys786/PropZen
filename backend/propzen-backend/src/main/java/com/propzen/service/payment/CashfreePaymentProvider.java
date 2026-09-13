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
import java.util.Base64;
import java.util.Map;
import java.util.UUID;

@Component
public class CashfreePaymentProvider implements PaymentProvider {

    private static final Logger log = LoggerFactory.getLogger(CashfreePaymentProvider.class);

    @Value("${propzen.payment.cashfree.app-id:${CASHFREE_APP_ID:cf_test_app_propzen}}")
    private String appId;

    @Value("${propzen.payment.cashfree.secret-key:${CASHFREE_SECRET_KEY:cf_test_secret_propzen}}")
    private String secretKey;

    @Override
    public PaymentProviderType getProviderType() {
        return PaymentProviderType.CASHFREE;
    }

    @Override
    public PaymentOrderResponse createOrder(BigDecimal amount, String currency, String receiptId, Map<String, Object> notes) {
        String orderId = "order_cf_" + UUID.randomUUID().toString().replace("-", "").substring(0, 14);
        log.info("[CashfreePaymentProvider] Created Cashfree orderId: {} for receipt: {}, amount: {} {}",
                orderId, receiptId, amount, currency);
        return new PaymentOrderResponse(orderId, null, amount, currency, "ACTIVE");
    }

    @Override
    public boolean verifySignature(String orderId, String paymentId, String signature) {
        if (orderId == null || signature == null || secretKey == null || secretKey.isBlank()) {
            return false;
        }

        try {
            String data = orderId + (paymentId != null ? paymentId : "");
            Mac sha256Hmac = Mac.getInstance("HmacSHA256");
            SecretKeySpec secretKeySpec = new SecretKeySpec(secretKey.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
            sha256Hmac.init(secretKeySpec);
            byte[] hash = sha256Hmac.doFinal(data.getBytes(StandardCharsets.UTF_8));
            String computedSignature = Base64.getEncoder().encodeToString(hash);

            return MessageDigest.isEqual(computedSignature.getBytes(StandardCharsets.UTF_8),
                    signature.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            log.error("[CashfreePaymentProvider] Error verifying webhook signature: {}", e.getMessage());
            return false;
        }
    }
}
