package com.propzen.crm.dto;

import com.propzen.crm.entity.ContactPreference;

import java.time.OffsetDateTime;
import java.util.UUID;

public class ContactPreferenceDto {

    private UUID id;
    private UUID customerId;
    private String phone;
    private boolean whatsappOptIn;
    private boolean marketingOptIn;
    private boolean emailOptIn;
    private boolean smsOptIn;
    private OffsetDateTime updatedAt;

    public ContactPreferenceDto() {
    }

    public static ContactPreferenceDto fromEntity(ContactPreference entity) {
        if (entity == null) return null;
        ContactPreferenceDto dto = new ContactPreferenceDto();
        dto.setId(entity.getId());
        dto.setCustomerId(entity.getCustomerId());
        dto.setPhone(entity.getPhone());
        dto.setWhatsappOptIn(entity.isWhatsappOptIn());
        dto.setMarketingOptIn(entity.isMarketingOptIn());
        dto.setEmailOptIn(entity.isEmailOptIn());
        dto.setSmsOptIn(entity.isSmsOptIn());
        dto.setUpdatedAt(entity.getUpdatedAt());
        return dto;
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getCustomerId() {
        return customerId;
    }

    public void setCustomerId(UUID customerId) {
        this.customerId = customerId;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public boolean isWhatsappOptIn() {
        return whatsappOptIn;
    }

    public void setWhatsappOptIn(boolean whatsappOptIn) {
        this.whatsappOptIn = whatsappOptIn;
    }

    public boolean isMarketingOptIn() {
        return marketingOptIn;
    }

    public void setMarketingOptIn(boolean marketingOptIn) {
        this.marketingOptIn = marketingOptIn;
    }

    public boolean isEmailOptIn() {
        return emailOptIn;
    }

    public void setEmailOptIn(boolean emailOptIn) {
        this.emailOptIn = emailOptIn;
    }

    public boolean isSmsOptIn() {
        return smsOptIn;
    }

    public void setSmsOptIn(boolean smsOptIn) {
        this.smsOptIn = smsOptIn;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(OffsetDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
