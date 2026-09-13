package com.propzen.service.dto;

import com.propzen.service.model.DocumentVerificationStatus;
import jakarta.validation.constraints.NotNull;

public class VerifyDocumentRequest {

    @NotNull(message = "Verification status is required")
    private DocumentVerificationStatus verificationStatus;

    private String rejectionReason;

    public DocumentVerificationStatus getVerificationStatus() { return verificationStatus; }
    public void setVerificationStatus(DocumentVerificationStatus verificationStatus) { this.verificationStatus = verificationStatus; }

    public String getRejectionReason() { return rejectionReason; }
    public void setRejectionReason(String rejectionReason) { this.rejectionReason = rejectionReason; }
}
