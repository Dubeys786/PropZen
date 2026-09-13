package com.propzen.service.dto;

import com.propzen.service.model.PartnerVerificationStatus;
import jakarta.validation.constraints.NotNull;

public class UpdatePartnerVerificationRequest {

    @NotNull(message = "Verification status is required")
    private PartnerVerificationStatus verificationStatus;

    private String adminNotes;

    public PartnerVerificationStatus getVerificationStatus() { return verificationStatus; }
    public void setVerificationStatus(PartnerVerificationStatus verificationStatus) { this.verificationStatus = verificationStatus; }

    public String getAdminNotes() { return adminNotes; }
    public void setAdminNotes(String adminNotes) { this.adminNotes = adminNotes; }
}
