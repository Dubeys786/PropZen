package com.propzen.crm.notification;

public class WhatsAppResponse {
    private boolean success;
    private String providerMessageId;
    private String errorMessage;
    private String status;

    public WhatsAppResponse() {
    }

    public WhatsAppResponse(boolean success, String providerMessageId, String status) {
        this.success = success;
        this.providerMessageId = providerMessageId;
        this.status = status;
    }

    public static WhatsAppResponse ok(String providerMessageId) {
        return new WhatsAppResponse(true, providerMessageId, "SENT");
    }

    public static WhatsAppResponse failed(String errorMessage) {
        WhatsAppResponse r = new WhatsAppResponse(false, null, "FAILED");
        r.setErrorMessage(errorMessage);
        return r;
    }

    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }

    public String getProviderMessageId() {
        return providerMessageId;
    }

    public void setProviderMessageId(String providerMessageId) {
        this.providerMessageId = providerMessageId;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}
