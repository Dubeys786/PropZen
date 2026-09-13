package com.propzen.service.dto;

public class PaymentWebhookPayload {
    private String event;
    private String orderId;
    private String paymentId;
    private String status;
    private String signature;
    private String rawPayload;

    public String getEvent() { return event; }
    public void setEvent(String event) { this.event = event; }

    public String getOrderId() { return orderId; }
    public void setOrderId(String orderId) { this.orderId = orderId; }

    public String getPaymentId() { return paymentId; }
    public void setPaymentId(String paymentId) { this.paymentId = paymentId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getSignature() { return signature; }
    public void setSignature(String signature) { this.signature = signature; }

    public String getRawPayload() { return rawPayload; }
    public void setRawPayload(String rawPayload) { this.rawPayload = rawPayload; }
}
