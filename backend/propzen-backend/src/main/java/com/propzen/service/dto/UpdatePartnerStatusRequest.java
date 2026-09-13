package com.propzen.service.dto;

import com.propzen.service.model.PartnerStatus;
import jakarta.validation.constraints.NotNull;

public class UpdatePartnerStatusRequest {

    @NotNull(message = "Status is required")
    private PartnerStatus status;

    private String adminNotes;

    public PartnerStatus getStatus() { return status; }
    public void setStatus(PartnerStatus status) { this.status = status; }

    public String getAdminNotes() { return adminNotes; }
    public void setAdminNotes(String adminNotes) { this.adminNotes = adminNotes; }
}
