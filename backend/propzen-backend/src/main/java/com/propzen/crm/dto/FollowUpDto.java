package com.propzen.crm.dto;

import com.propzen.crm.entity.CrmFollowUp;
import com.propzen.crm.model.FollowUpPriority;
import com.propzen.crm.model.FollowUpStatus;

import java.time.OffsetDateTime;
import java.util.UUID;

public class FollowUpDto {

    private UUID id;
    private UUID leadId;
    private UUID assignedTo;
    private String title;
    private String description;
    private OffsetDateTime followupAt;
    private FollowUpPriority priority;
    private FollowUpStatus status;
    private OffsetDateTime completedAt;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    public FollowUpDto() {
    }

    public static FollowUpDto fromEntity(CrmFollowUp entity) {
        if (entity == null) return null;
        FollowUpDto dto = new FollowUpDto();
        dto.setId(entity.getId());
        dto.setLeadId(entity.getLeadId());
        dto.setAssignedTo(entity.getAssignedTo());
        dto.setTitle(entity.getTitle());
        dto.setDescription(entity.getDescription());
        dto.setFollowupAt(entity.getFollowupAt());
        dto.setPriority(entity.getPriority());
        dto.setStatus(entity.getStatus());
        dto.setCompletedAt(entity.getCompletedAt());
        dto.setCreatedAt(entity.getCreatedAt());
        dto.setUpdatedAt(entity.getUpdatedAt());
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

    public UUID getAssignedTo() {
        return assignedTo;
    }

    public void setAssignedTo(UUID assignedTo) {
        this.assignedTo = assignedTo;
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

    public OffsetDateTime getFollowupAt() {
        return followupAt;
    }

    public void setFollowupAt(OffsetDateTime followupAt) {
        this.followupAt = followupAt;
    }

    public FollowUpPriority getPriority() {
        return priority;
    }

    public void setPriority(FollowUpPriority priority) {
        this.priority = priority;
    }

    public FollowUpStatus getStatus() {
        return status;
    }

    public void setStatus(FollowUpStatus status) {
        this.status = status;
    }

    public OffsetDateTime getCompletedAt() {
        return completedAt;
    }

    public void setCompletedAt(OffsetDateTime completedAt) {
        this.completedAt = completedAt;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(OffsetDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
