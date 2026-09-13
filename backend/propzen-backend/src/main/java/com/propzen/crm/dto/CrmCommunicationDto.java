package com.propzen.crm.dto;

import com.propzen.crm.entity.CrmCommunication;
import com.propzen.crm.model.CommunicationChannel;
import com.propzen.crm.model.CommunicationDirection;
import com.propzen.crm.model.CommunicationStatus;

import java.time.OffsetDateTime;
import java.util.UUID;

public class CrmCommunicationDto {

    private UUID id;
    private UUID leadId;
    private UUID customerId;
    private CommunicationChannel channel;
    private CommunicationDirection direction;
    private UUID templateId;
    private String providerMessageId;
    private String messagePreview;
    private CommunicationStatus status;
    private OffsetDateTime sentAt;
    private OffsetDateTime createdAt;

    public CrmCommunicationDto() {
    }

    public static CrmCommunicationDto fromEntity(CrmCommunication entity) {
        if (entity == null) return null;
        CrmCommunicationDto dto = new CrmCommunicationDto();
        dto.setId(entity.getId());
        dto.setLeadId(entity.getLeadId());
        dto.setCustomerId(entity.getCustomerId());
        dto.setChannel(entity.getChannel());
        dto.setDirection(entity.getDirection());
        dto.setTemplateId(entity.getTemplateId());
        dto.setProviderMessageId(entity.getProviderMessageId());
        dto.setMessagePreview(entity.getMessagePreview());
        dto.setStatus(entity.getStatus());
        dto.setSentAt(entity.getSentAt());
        dto.setCreatedAt(entity.getCreatedAt());
        return dto;
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
