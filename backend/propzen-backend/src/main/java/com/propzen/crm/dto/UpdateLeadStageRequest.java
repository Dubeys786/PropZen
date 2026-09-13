package com.propzen.crm.dto;

import com.propzen.crm.model.LeadStage;
import jakarta.validation.constraints.NotNull;

public class UpdateLeadStageRequest {

    @NotNull(message = "Lead stage is required")
    private LeadStage stage;

    private String notes;

    public UpdateLeadStageRequest() {
    }

    public UpdateLeadStageRequest(LeadStage stage, String notes) {
        this.stage = stage;
        this.notes = notes;
    }

    public LeadStage getStage() {
        return stage;
    }

    public void setStage(LeadStage stage) {
        this.stage = stage;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }
}
