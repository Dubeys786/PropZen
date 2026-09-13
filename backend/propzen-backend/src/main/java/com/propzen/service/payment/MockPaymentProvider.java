package com.propzen.service.payment;

import com.propzen.service.model.PaymentProviderType;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;

@Component
public class MockPaymentProvider implements PaymentProvider {

    private static final Logger log = LoggerFactory.getLogger(MockPaymentProvider.class);

    @Override
    public PaymentProviderType getProviderType() {
        return PaymentProviderType.MOCK;
    }

    @Override
    public PaymentOrderResponse createOrder(BigDecimal amount, String currency, String receiptId, Map<String, Object> notes) {
        String orderId = "order_mock_" + UUID.randomUUID().toString().substring(0, 8);
        String paymentId = "pay_mock_" + UUID.randomUUID().toString().substring(0, 8);
        log.info("[MockPaymentProvider] Created mock order {} for amount {} {}", orderId, amount, currency);
        return new PaymentOrderResponse(orderId, paymentId, amount, currency, "CREATED");
    }

    @Override
    public boolean verifySignature(String orderId, String paymentId, String signature) {
        log.info("[MockPaymentProvider] Verified mock signature for orderId={}, paymentId={}", orderId, paymentId);
        return signature != null && !signature.isBlank();
    }
}
