package com.propzen.service.dto;

import com.propzen.service.entity.ServiceCustomerNote;
import java.time.OffsetDateTime;
import java.util.UUID;

public class CustomerNoteDto {
    private UUID id;
    private UUID customerId;
    private UUID partnerId;
    private UUID serviceRequestId;
    private String note;
    private String tags;
    private OffsetDateTime nextFollowupAt;
    private UUID createdBy;
    private OffsetDateTime createdAt;

    public static CustomerNoteDto fromEntity(ServiceCustomerNote entity) {
        CustomerNoteDto dto = new CustomerNoteDto();
        dto.setId(entity.getId());
        dto.setCustomerId(entity.getCustomerId());
        dto.setPartnerId(entity.getPartnerId());
        dto.setServiceRequestId(entity.getServiceRequestId());
        dto.setNote(entity.getNote());
        dto.setTags(entity.getTags());
        dto.setNextFollowupAt(entity.getNextFollowupAt());
        dto.setCreatedBy(entity.getCreatedBy());
        dto.setCreatedAt(entity.getCreatedAt());
        return dto;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getCustomerId() { return customerId; }
    public void setCustomerId(UUID customerId) { this.customerId = customerId; }

    public UUID getPartnerId() { return partnerId; }
    public void setPartnerId(UUID partnerId) { this.partnerId = partnerId; }

    public UUID getServiceRequestId() { return serviceRequestId; }
    public void setServiceRequestId(UUID serviceRequestId) { this.serviceRequestId = serviceRequestId; }

    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }

    public String getTags() { return tags; }
    public void setTags(String tags) { this.tags = tags; }

    public OffsetDateTime getNextFollowupAt() { return nextFollowupAt; }
    public void setNextFollowupAt(OffsetDateTime nextFollowupAt) { this.nextFollowupAt = nextFollowupAt; }

    public UUID getCreatedBy() { return createdBy; }
    public void setCreatedBy(UUID createdBy) { this.createdBy = createdBy; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }
}
