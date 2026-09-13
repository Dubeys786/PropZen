package com.propzen.crm.dto;

import com.propzen.crm.entity.Campaign;
import com.propzen.crm.model.CampaignChannel;
import com.propzen.crm.model.CampaignStatus;
import com.propzen.crm.model.CampaignType;

import java.time.OffsetDateTime;
import java.util.UUID;

public class CampaignDto {

    private UUID id;
    private String name;
    private CampaignType type;
    private CampaignChannel channel;
    private CampaignStatus status;
    private UUID templateId;
    private UUID createdBy;
    private OffsetDateTime scheduledAt;
    private OffsetDateTime startedAt;
    private OffsetDateTime completedAt;
    private Integer totalRecipients;
    private Integer sentCount;
    private Integer deliveredCount;
    private Integer readCount;
    private Integer failedCount;
    private OffsetDateTime createdAt;

    public CampaignDto() {
    }

    public static CampaignDto fromEntity(Campaign c) {
        if (c == null) return null;
        CampaignDto dto = new CampaignDto();
        dto.setId(c.getId());
        dto.setName(c.getName());
        dto.setType(c.getType());
        dto.setChannel(c.getChannel());
        dto.setStatus(c.getStatus());
        dto.setTemplateId(c.getTemplateId());
        dto.setCreatedBy(c.getCreatedBy());
        dto.setScheduledAt(c.getScheduledAt());
        dto.setStartedAt(c.getStartedAt());
        dto.setCompletedAt(c.getCompletedAt());
        dto.setTotalRecipients(c.getTotalRecipients());
        dto.setSentCount(c.getSentCount());
        dto.setDeliveredCount(c.getDeliveredCount());
        dto.setReadCount(c.getReadCount());
        dto.setFailedCount(c.getFailedCount());
        dto.setCreatedAt(c.getCreatedAt());
        return dto;
    }

    // Getters and Setters

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public CampaignType getType() {
        return type;
    }

    public void setType(CampaignType type) {
        this.type = type;
    }

    public CampaignChannel getChannel() {
        return channel;
    }

    public void setChannel(CampaignChannel channel) {
        this.channel = channel;
    }

    public CampaignStatus getStatus() {
        return status;
    }

    public void setStatus(CampaignStatus status) {
        this.status = status;
    }

    public UUID getTemplateId() {
        return templateId;
    }

    public void setTemplateId(UUID templateId) {
        this.templateId = templateId;
    }

    public UUID getCreatedBy() {
        return createdBy;
    }

    public void setCreatedBy(UUID createdBy) {
        this.createdBy = createdBy;
    }

    public OffsetDateTime getScheduledAt() {
        return scheduledAt;
    }

    public void setScheduledAt(OffsetDateTime scheduledAt) {
        this.scheduledAt = scheduledAt;
    }

    public OffsetDateTime getStartedAt() {
        return startedAt;
    }

    public void setStartedAt(OffsetDateTime startedAt) {
        this.startedAt = startedAt;
    }

    public OffsetDateTime getCompletedAt() {
        return completedAt;
    }

    public void setCompletedAt(OffsetDateTime completedAt) {
        this.completedAt = completedAt;
    }

    public Integer getTotalRecipients() {
        return totalRecipients;
    }

    public void setTotalRecipients(Integer totalRecipients) {
        this.totalRecipients = totalRecipients;
    }

    public Integer getSentCount() {
        return sentCount;
    }

    public void setSentCount(Integer sentCount) {
        this.sentCount = sentCount;
    }

    public Integer getDeliveredCount() {
        return deliveredCount;
    }

    public void setDeliveredCount(Integer deliveredCount) {
        this.deliveredCount = deliveredCount;
    }

    public Integer getReadCount() {
        return readCount;
    }

    public void setReadCount(Integer readCount) {
        this.readCount = readCount;
    }

    public Integer getFailedCount() {
        return failedCount;
    }

    public void setFailedCount(Integer failedCount) {
        this.failedCount = failedCount;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
