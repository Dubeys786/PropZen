package com.propzen.service.payment;

import java.math.BigDecimal;

public class PaymentOrderResponse {
    private String orderId;
    private String paymentId;
    private BigDecimal amount;
    private String currency;
    private String status;

    public PaymentOrderResponse() {}

    public PaymentOrderResponse(String orderId, String paymentId, BigDecimal amount, String currency, String status) {
        this.orderId = orderId;
        this.paymentId = paymentId;
        this.amount = amount;
        this.currency = currency;
        this.status = status;
    }

    public String getOrderId() { return orderId; }
    public void setOrderId(String orderId) { this.orderId = orderId; }

    public String getPaymentId() { return paymentId; }
    public void setPaymentId(String paymentId) { this.paymentId = paymentId; }

    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
