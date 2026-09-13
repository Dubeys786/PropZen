package com.propzen.crm.dto;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public class AssignPartnerRequest {

    @NotNull(message = "partnerId is required")
    private UUID partnerId;

    public AssignPartnerRequest() {
    }

    public AssignPartnerRequest(UUID partnerId) {
        this.partnerId = partnerId;
    }

    public UUID getPartnerId() {
        return partnerId;
    }

    public void setPartnerId(UUID partnerId) {
        this.partnerId = partnerId;
    }
}
