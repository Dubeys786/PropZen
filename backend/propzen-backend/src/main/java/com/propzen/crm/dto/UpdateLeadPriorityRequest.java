package com.propzen.crm.dto;

import com.propzen.crm.model.LeadPriority;
import jakarta.validation.constraints.NotNull;

public class UpdateLeadPriorityRequest {

    @NotNull(message = "Priority is required")
    private LeadPriority priority;

    public UpdateLeadPriorityRequest() {
    }

    public UpdateLeadPriorityRequest(LeadPriority priority) {
        this.priority = priority;
    }

    public LeadPriority getPriority() {
        return priority;
    }

    public void setPriority(LeadPriority priority) {
        this.priority = priority;
    }
}
