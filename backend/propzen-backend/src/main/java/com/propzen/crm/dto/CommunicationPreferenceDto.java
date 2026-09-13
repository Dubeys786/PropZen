package com.propzen.crm.dto;

import com.propzen.crm.entity.CommunicationPreference;

public class CommunicationPreferenceDto {

    private String phone;
    private Boolean whatsappOptIn;
    private Boolean emailOptIn;
    private Boolean smsOptIn;
    private Boolean marketingOptIn;

    public CommunicationPreferenceDto() {
    }

    public static CommunicationPreferenceDto fromEntity(CommunicationPreference p) {
        if (p == null) return null;
        CommunicationPreferenceDto dto = new CommunicationPreferenceDto();
        dto.setPhone(p.getPhone());
        dto.setWhatsappOptIn(p.getWhatsappOptIn());
        dto.setEmailOptIn(p.getEmailOptIn());
        dto.setSmsOptIn(p.getSmsOptIn());
        dto.setMarketingOptIn(p.getMarketingOptIn());
        return dto;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public Boolean getWhatsappOptIn() {
        return whatsappOptIn;
    }

    public void setWhatsappOptIn(Boolean whatsappOptIn) {
        this.whatsappOptIn = whatsappOptIn;
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

    public Boolean getMarketingOptIn() {
        return marketingOptIn;
    }

    public void setMarketingOptIn(Boolean marketingOptIn) {
        this.marketingOptIn = marketingOptIn;
    }
}
