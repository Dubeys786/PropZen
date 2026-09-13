package com.propzen.crm.dto;

import com.propzen.crm.entity.LeadActivity;
import com.propzen.crm.model.ActivityType;

import java.time.OffsetDateTime;
import java.util.UUID;

public class LeadActivityDto {

    private UUID id;
    private UUID leadId;
    private UUID actorUserId;
    private ActivityType type;
    private String note;
    private OffsetDateTime scheduledAt;
    private OffsetDateTime completedAt;
    private OffsetDateTime createdAt;

    public LeadActivityDto() {
    }

    public static LeadActivityDto fromEntity(LeadActivity a) {
        if (a == null) return null;
        LeadActivityDto dto = new LeadActivityDto();
        dto.setId(a.getId());
        dto.setLeadId(a.getLeadId());
        dto.setActorUserId(a.getActorUserId());
        dto.setType(a.getType());
        dto.setNote(a.getNote());
        dto.setScheduledAt(a.getScheduledAt());
        dto.setCompletedAt(a.getCompletedAt());
        dto.setCreatedAt(a.getCreatedAt());
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

    public UUID getActorUserId() {
        return actorUserId;
    }

    public void setActorUserId(UUID actorUserId) {
        this.actorUserId = actorUserId;
    }

    public ActivityType getType() {
        return type;
    }

    public void setType(ActivityType type) {
        this.type = type;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }

    public OffsetDateTime getScheduledAt() {
        return scheduledAt;
    }

    public void setScheduledAt(OffsetDateTime scheduledAt) {
        this.scheduledAt = scheduledAt;
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
}
