package com.propzen.crm.dto;

import com.propzen.crm.entity.CrmActivity;
import com.propzen.crm.model.CrmActivityType;

import java.time.OffsetDateTime;
import java.util.UUID;

public class ActivityDto {

    private UUID id;
    private UUID leadId;
    private UUID customerId;
    private CrmActivityType activityType;
    private String title;
    private String description;
    private UUID performedBy;
    private String metadata;
    private OffsetDateTime createdAt;

    public ActivityDto() {
    }

    public static ActivityDto fromEntity(CrmActivity entity) {
        if (entity == null) return null;
        ActivityDto dto = new ActivityDto();
        dto.setId(entity.getId());
        dto.setLeadId(entity.getLeadId());
        dto.setCustomerId(entity.getCustomerId());
        dto.setActivityType(entity.getActivityType());
        dto.setTitle(entity.getTitle());
        dto.setDescription(entity.getDescription());
        dto.setPerformedBy(entity.getPerformedBy());
        dto.setMetadata(entity.getMetadata());
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

    public CrmActivityType getActivityType() {
        return activityType;
    }

    public void setActivityType(CrmActivityType activityType) {
        this.activityType = activityType;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public UUID getPerformedBy() {
        return performedBy;
    }

    public void setPerformedBy(UUID performedBy) {
        this.performedBy = performedBy;
    }

    public String getMetadata() {
        return metadata;
    }

    public void setMetadata(String metadata) {
        this.metadata = metadata;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
