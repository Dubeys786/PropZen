package com.propzen.service.payment;

import com.propzen.service.model.PaymentProviderType;
import java.math.BigDecimal;
import java.util.Map;

public interface PaymentProvider {
    PaymentProviderType getProviderType();
    PaymentOrderResponse createOrder(BigDecimal amount, String currency, String receiptId, Map<String, Object> notes);
    boolean verifySignature(String orderId, String paymentId, String signature);
}
