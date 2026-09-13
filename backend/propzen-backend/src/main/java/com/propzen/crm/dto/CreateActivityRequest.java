package com.propzen.crm.dto;

import com.propzen.crm.model.CrmActivityType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public class CreateActivityRequest {

    private UUID leadId;
    private UUID customerId;

    @NotNull(message = "Activity type is required")
    private CrmActivityType activityType;

    @NotBlank(message = "Title is required")
    private String title;

    private String description;
    private String metadata;

    public CreateActivityRequest() {
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

    public String getMetadata() {
        return metadata;
    }

    public void setMetadata(String metadata) {
        this.metadata = metadata;
    }
}
