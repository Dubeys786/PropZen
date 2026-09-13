package com.propzen.crm.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Opt-in consent and communication preference record.
 */
@Entity
@Table(name = "crm_communication_preferences")
public class CommunicationPreference implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "phone", nullable = false, unique = true)
    private String phone;

    @Column(name = "whatsapp_opt_in", nullable = false)
    private Boolean whatsappOptIn = true;

    @Column(name = "email_opt_in", nullable = false)
    private Boolean emailOptIn = true;

    @Column(name = "sms_opt_in", nullable = false)
    private Boolean smsOptIn = true;

    @Column(name = "marketing_opt_in", nullable = false)
    private Boolean marketingOptIn = true;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    public CommunicationPreference() {
    }

    @PrePersist
    @PreUpdate
    protected void onPersist() {
        updatedAt = OffsetDateTime.now();
    }

    // Getters and Setters

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
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

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(OffsetDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
