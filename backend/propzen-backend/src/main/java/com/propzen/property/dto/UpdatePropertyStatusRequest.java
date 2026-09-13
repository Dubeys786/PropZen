package com.propzen.property.dto;

import jakarta.validation.constraints.NotBlank;

/**
 * Payload for administrative property status changes.
 */
public class UpdatePropertyStatusRequest {

    @NotBlank(message = "Status is required")
    private String status;

    private String adminNote;

    public UpdatePropertyStatusRequest() {
    }

    public UpdatePropertyStatusRequest(String status, String adminNote) {
        this.status = status;
        this.adminNote = adminNote;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getAdminNote() {
        return adminNote;
    }

    public void setAdminNote(String adminNote) {
        this.adminNote = adminNote;
    }
}
