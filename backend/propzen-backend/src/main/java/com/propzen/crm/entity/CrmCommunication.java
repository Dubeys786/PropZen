package com.propzen.crm.entity;

import com.propzen.crm.model.CommunicationChannel;
import com.propzen.crm.model.CommunicationDirection;
import com.propzen.crm.model.CommunicationStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Entity tracking omnichannel communications across WhatsApp, SMS, Email, and In-App.
 */
@Entity
@Table(name = "crm_communications")
public class CrmCommunication implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "lead_id")
    private UUID leadId;

    @Column(name = "customer_id")
    private UUID customerId;

    @Enumerated(EnumType.STRING)
    @Column(name = "channel", nullable = false)
    private CommunicationChannel channel = CommunicationChannel.WHATSAPP;

    @Enumerated(EnumType.STRING)
    @Column(name = "direction", nullable = false)
    private CommunicationDirection direction = CommunicationDirection.OUTBOUND;

    @Column(name = "template_id")
    private UUID templateId;

    @Column(name = "provider_message_id")
    private String providerMessageId;

    @Column(name = "message_preview", length = 500)
    private String messagePreview;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private CommunicationStatus status = CommunicationStatus.QUEUED;

    @Column(name = "sent_at")
    private OffsetDateTime sentAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    public CrmCommunication() {
    }

    public CrmCommunication(UUID leadId, UUID customerId, CommunicationChannel channel, CommunicationDirection direction, String providerMessageId, String messagePreview, CommunicationStatus status) {
        this.leadId = leadId;
        this.customerId = customerId;
        this.channel = channel != null ? channel : CommunicationChannel.WHATSAPP;
        this.direction = direction != null ? direction : CommunicationDirection.OUTBOUND;
        this.providerMessageId = providerMessageId;
        this.messagePreview = messagePreview;
        this.status = status != null ? status : CommunicationStatus.QUEUED;
    }

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = OffsetDateTime.now();
        }
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getLeadId() {
        return leadId;
    }

    public void setLeadId(UUID leadId) {
        this.leadId = leadId;
    }

    public UUID getCustomerId() {
        return customerId;
    }

    public void setCustomerId(UUID customerId) {
        this.customerId = customerId;
    }

    public CommunicationChannel getChannel() {
        return channel;
    }

    public void setChannel(CommunicationChannel channel) {
        this.channel = channel;
    }

    public CommunicationDirection getDirection() {
        return direction;
    }

    public void setDirection(CommunicationDirection direction) {
        this.direction = direction;
    }

    public UUID getTemplateId() {
        return templateId;
    }

    public void setTemplateId(UUID templateId) {
        this.templateId = templateId;
    }

    public String getProviderMessageId() {
        return providerMessageId;
    }

    public void setProviderMessageId(String providerMessageId) {
        this.providerMessageId = providerMessageId;
    }

    public String getMessagePreview() {
        return messagePreview;
    }

    public void setMessagePreview(String messagePreview) {
        this.messagePreview = messagePreview;
    }

    public CommunicationStatus getStatus() {
        return status;
    }

    public void setStatus(CommunicationStatus status) {
        this.status = status;
    }

    public OffsetDateTime getSentAt() {
        return sentAt;
    }

    public void setSentAt(OffsetDateTime sentAt) {
        this.sentAt = sentAt;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
