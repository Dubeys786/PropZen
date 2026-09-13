package com.propzen.verification.dto;

import com.propzen.verification.model.VerificationCaseStatus;
import jakarta.validation.constraints.NotNull;

public class UpdateVerificationStatusRequest {

    @NotNull(message = "Status is required")
    private VerificationCaseStatus status;

    private String adminNotes;

    public UpdateVerificationStatusRequest() {
    }

    public VerificationCaseStatus getStatus() { return status; }
    public void setStatus(VerificationCaseStatus status) { this.status = status; }

    public String getAdminNotes() { return adminNotes; }
    public void setAdminNotes(String adminNotes) { this.adminNotes = adminNotes; }
}
