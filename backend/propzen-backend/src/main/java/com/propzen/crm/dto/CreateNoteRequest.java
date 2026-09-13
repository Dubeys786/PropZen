package com.propzen.crm.dto;

import jakarta.validation.constraints.NotBlank;

import java.util.UUID;

public class CreateNoteRequest {

    private UUID leadId;
    private UUID customerId;

    @NotBlank(message = "Note content is required")
    private String note;

    public CreateNoteRequest() {
    }

    public CreateNoteRequest(UUID leadId, UUID customerId, String note) {
        this.leadId = leadId;
        this.customerId = customerId;
        this.note = note;
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

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }
}
