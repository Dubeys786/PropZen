package com.propzen.crm.dto;

import com.propzen.crm.model.ActivityType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.OffsetDateTime;

public class CreateFollowUpRequest {

    @NotNull(message = "Activity type is required")
    private ActivityType type = ActivityType.FOLLOW_UP;

    @NotBlank(message = "Note is required")
    private String note;

    private OffsetDateTime scheduledAt;

    private String metadata;

    public CreateFollowUpRequest() {
    }

    public CreateFollowUpRequest(ActivityType type, String note, OffsetDateTime scheduledAt) {
        this.type = type;
        this.note = note;
        this.scheduledAt = scheduledAt;
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

    public String getMetadata() {
        return metadata;
    }

    public void setMetadata(String metadata) {
        this.metadata = metadata;
    }
}
