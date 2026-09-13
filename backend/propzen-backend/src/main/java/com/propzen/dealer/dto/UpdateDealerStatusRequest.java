package com.propzen.dealer.dto;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.propzen.dealer.model.DealerStatus;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.io.Serializable;

/**
 * Admin payload for transitioning dealer application status.
 */
@JsonIgnoreProperties(ignoreUnknown = true)
public class UpdateDealerStatusRequest implements Serializable {

    @NotNull(message = "Status is required")
    private DealerStatus status;

    @Size(max = 2000, message = "Admin notes must not exceed 2000 characters")
    private String adminNotes;

    public UpdateDealerStatusRequest() {
    }

    public UpdateDealerStatusRequest(DealerStatus status, String adminNotes) {
        this.status = status;
        this.adminNotes = adminNotes;
    }

    public DealerStatus getStatus() {
        return status;
    }

    public void setStatus(DealerStatus status) {
        this.status = status;
    }

    public String getAdminNotes() {
        return adminNotes;
    }

    public void setAdminNotes(String adminNotes) {
        this.adminNotes = adminNotes;
    }
}
