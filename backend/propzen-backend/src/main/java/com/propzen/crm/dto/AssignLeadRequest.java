package com.propzen.crm.dto;

import jakarta.validation.constraints.NotNull;

import java.util.UUID;

public class AssignLeadRequest {

    @NotNull(message = "Assigned user ID is required")
    private UUID assignedTo;

    private UUID dealerId;

    public AssignLeadRequest() {
    }

    public AssignLeadRequest(UUID assignedTo, UUID dealerId) {
        this.assignedTo = assignedTo;
        this.dealerId = dealerId;
    }

    public UUID getAssignedTo() {
        return assignedTo;
    }

    public void setAssignedTo(UUID assignedTo) {
        this.assignedTo = assignedTo;
    }

    public UUID getDealerId() {
        return dealerId;
    }

    public void setDealerId(UUID dealerId) {
        this.dealerId = dealerId;
    }
}
