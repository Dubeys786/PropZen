package com.propzen.service.dto;

import jakarta.validation.constraints.NotBlank;
import java.time.OffsetDateTime;
import java.util.UUID;

public class CreateCustomerNoteRequest {

    @NotBlank(message = "Note is required")
    private String note;

    private UUID serviceRequestId;
    private String tags;
    private OffsetDateTime nextFollowupAt;

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }

    public UUID getServiceRequestId() { return serviceRequestId; }
    public void setServiceRequestId(UUID serviceRequestId) { this.serviceRequestId = serviceRequestId; }

    public String getTags() { return tags; }
    public void setTags(String tags) { this.tags = tags; }

    public OffsetDateTime getNextFollowupAt() { return nextFollowupAt; }
    public void setNextFollowupAt(OffsetDateTime nextFollowupAt) { this.nextFollowupAt = nextFollowupAt; }
}
