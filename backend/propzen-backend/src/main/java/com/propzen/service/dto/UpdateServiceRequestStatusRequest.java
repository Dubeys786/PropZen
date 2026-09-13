package com.propzen.service.dto;

import com.propzen.service.model.ServiceRequestStatus;
import jakarta.validation.constraints.NotNull;

public class UpdateServiceRequestStatusRequest {

    @NotNull(message = "Status is required")
    private ServiceRequestStatus status;

    private String reason;

    public ServiceRequestStatus getStatus() { return status; }
    public void setStatus(ServiceRequestStatus status) { this.status = status; }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
}
