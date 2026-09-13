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
 * Customer consent and channel opt-in/opt-out preferences.
 */
@Entity
@Table(name = "crm_contact_preferences")
public class ContactPreference implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "customer_id")
    private UUID customerId;

    @Column(name = "phone", nullable = false, unique = true, length = 50)
    private String phone;

    @Column(name = "whatsapp_opt_in", nullable = false)
    private boolean whatsappOptIn = true;

    @Column(name = "marketing_opt_in", nullable = false)
    private boolean marketingOptIn = true;

    @Column(name = "email_opt_in", nullable = false)
    private boolean emailOptIn = true;

    @Column(name = "sms_opt_in", nullable = false)
    private boolean smsOptIn = true;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    public ContactPreference() {
    }

    public ContactPreference(String phone, UUID customerId) {
        this.phone = phone;
        this.customerId = customerId;
        this.whatsappOptIn = true;
        this.marketingOptIn = true;
        this.emailOptIn = true;
        this.smsOptIn = true;
    }

    @PrePersist
    protected void onCreate() {
        if (updatedAt == null) {
            updatedAt = OffsetDateTime.now();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
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
