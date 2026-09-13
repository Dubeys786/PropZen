package com.propzen.service.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public class AssignPartnerRequest {

    @NotNull(message = "Partner ID is required")
    private UUID partnerId;

    private String notes;

    public UUID getPartnerId() { return partnerId; }
    public void setPartnerId(UUID partnerId) { this.partnerId = partnerId; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }
}
