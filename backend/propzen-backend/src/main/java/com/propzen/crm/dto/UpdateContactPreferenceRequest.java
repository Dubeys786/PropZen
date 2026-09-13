package com.propzen.crm.dto;

public class UpdateContactPreferenceRequest {

    private Boolean whatsappOptIn;
    private Boolean marketingOptIn;
    private Boolean emailOptIn;
    private Boolean smsOptIn;

    public UpdateContactPreferenceRequest() {
    }

    public UpdateContactPreferenceRequest(Boolean whatsappOptIn, Boolean marketingOptIn, Boolean emailOptIn, Boolean smsOptIn) {
        this.whatsappOptIn = whatsappOptIn;
        this.marketingOptIn = marketingOptIn;
        this.emailOptIn = emailOptIn;
        this.smsOptIn = smsOptIn;
    }

    public Boolean getWhatsappOptIn() {
        return whatsappOptIn;
    }

    public void setWhatsappOptIn(Boolean whatsappOptIn) {
        this.whatsappOptIn = whatsappOptIn;
    }

    public Boolean getMarketingOptIn() {
        return marketingOptIn;
    }

    public void setMarketingOptIn(Boolean marketingOptIn) {
        this.marketingOptIn = marketingOptIn;
    }

    public Boolean getEmailOptIn() {
        return emailOptIn;
    }

    public void setEmailOptIn(Boolean emailOptIn) {
        this.emailOptIn = emailOptIn;
    }

    public Boolean getSmsOptIn() {
        return smsOptIn;
    }

    public void setSmsOptIn(Boolean smsOptIn) {
        this.smsOptIn = smsOptIn;
    }
}
