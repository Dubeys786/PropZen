package com.propzen.service.payment;

import com.propzen.service.model.PaymentProviderType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.Map;
import java.util.UUID;

@Component
public class PayUPaymentProvider implements PaymentProvider {

    private static final Logger log = LoggerFactory.getLogger(PayUPaymentProvider.class);

    @Value("${propzen.payment.payu.key:${PAYU_KEY:payu_test_key_propzen}}")
    private String merchantKey;

    @Value("${propzen.payment.payu.salt:${PAYU_SALT:payu_test_salt_propzen}}")
    private String salt;

    @Override
    public PaymentProviderType getProviderType() {
        return PaymentProviderType.PAYU;
    }

    @Override
    public PaymentOrderResponse createOrder(BigDecimal amount, String currency, String receiptId, Map<String, Object> notes) {
        String txnId = "tx_payu_" + UUID.randomUUID().toString().replace("-", "").substring(0, 14);
        log.info("[PayUPaymentProvider] Created PayU txnId: {} for receipt: {}, amount: {} {}",
                txnId, receiptId, amount, currency);
        return new PaymentOrderResponse(txnId, null, amount, currency, "created");
    }

    @Override
    public boolean verifySignature(String orderId, String paymentId, String signature) {
        if (orderId == null || signature == null || salt == null || salt.isBlank()) {
            return false;
        }

        try {
            // PayU reverse hash format: salt|status||||||udf5|udf4|udf3|udf2|udf1|email|firstname|productinfo|amount|txnid|key
            String raw = salt + "|success||||||||||||" + orderId + "|" + merchantKey;
            MessageDigest md = MessageDigest.getInstance("SHA-512");
            byte[] digest = md.digest(raw.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : digest) {
                sb.append(String.format("%02x", b));
            }
            return MessageDigest.isEqual(sb.toString().getBytes(StandardCharsets.UTF_8),
                    signature.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            log.error("[PayUPaymentProvider] Error verifying webhook signature: {}", e.getMessage());
            return false;
        }
    }
}
