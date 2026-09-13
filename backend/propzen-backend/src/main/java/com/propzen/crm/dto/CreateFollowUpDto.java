package com.propzen.crm.dto;

import com.propzen.crm.model.FollowUpPriority;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.time.OffsetDateTime;
import java.util.UUID;

public class CreateFollowUpDto {

    private UUID leadId;
    private UUID assignedTo;

    @NotBlank(message = "Title is required")
    private String title;

    private String description;

    @NotNull(message = "Follow-up time is required")
    private OffsetDateTime followupAt;

    private FollowUpPriority priority = FollowUpPriority.MEDIUM;

    public CreateFollowUpDto() {
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
}
