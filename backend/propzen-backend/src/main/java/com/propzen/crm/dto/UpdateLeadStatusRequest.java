package com.propzen.crm.dto;

import com.propzen.crm.model.LeadStatus;
import jakarta.validation.constraints.NotNull;

public class UpdateLeadStatusRequest {

    @NotNull(message = "Status is required")
    private LeadStatus status;

    private String lostReason;
    private String note;

    public UpdateLeadStatusRequest() {
    }

    public UpdateLeadStatusRequest(LeadStatus status, String lostReason, String note) {
        this.status = status;
        this.lostReason = lostReason;
        this.note = note;
    }

    public LeadStatus getStatus() {
        return status;
    }

    public void setStatus(LeadStatus status) {
        this.status = status;
    }

    public String getLostReason() {
        return lostReason;
    }

    public void setLostReason(String lostReason) {
        this.lostReason = lostReason;
    }

    public String getNote() {
        return note;
    }

    public void setNote(String note) {
        this.note = note;
    }
}
