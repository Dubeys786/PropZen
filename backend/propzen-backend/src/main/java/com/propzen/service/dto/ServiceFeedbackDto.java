package com.propzen.service.dto;

import com.propzen.service.entity.ServiceFeedback;
import java.time.OffsetDateTime;
import java.util.UUID;

public class ServiceFeedbackDto {
    private UUID id;
    private UUID serviceRequestId;
    private UUID customerId;
    private UUID partnerId;
    private Integer rating;
    private String comment;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    public static ServiceFeedbackDto fromEntity(ServiceFeedback entity) {
        ServiceFeedbackDto dto = new ServiceFeedbackDto();
        dto.setId(entity.getId());
        dto.setServiceRequestId(entity.getServiceRequestId());
        dto.setCustomerId(entity.getCustomerId());
        dto.setPartnerId(entity.getPartnerId());
        dto.setRating(entity.getRating());
        dto.setComment(entity.getComment());
        dto.setCreatedAt(entity.getCreatedAt());
        dto.setUpdatedAt(entity.getUpdatedAt());
        return dto;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getServiceRequestId() { return serviceRequestId; }
    public void setServiceRequestId(UUID serviceRequestId) { this.serviceRequestId = serviceRequestId; }

    public UUID getCustomerId() { return customerId; }
    public void setCustomerId(UUID customerId) { this.customerId = customerId; }

    public UUID getPartnerId() { return partnerId; }
    public void setPartnerId(UUID partnerId) { this.partnerId = partnerId; }

    public Integer getRating() { return rating; }
    public void setRating(Integer rating) { this.rating = rating; }

    public String getComment() { return comment; }
    public void setComment(String comment) { this.comment = comment; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}
