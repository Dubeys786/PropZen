package com.propzen.service.dto;

import com.propzen.service.entity.ServiceJourneyEvent;
import com.propzen.service.model.ServiceJourneyEventType;
import java.time.OffsetDateTime;
import java.util.UUID;

public class ServiceJourneyEventDto {
    private UUID id;
    private UUID serviceRequestId;
    private ServiceJourneyEventType eventType;
    private String title;
    private String description;
    private UUID createdBy;
    private String metadata;
    private OffsetDateTime createdAt;

    public static ServiceJourneyEventDto fromEntity(ServiceJourneyEvent entity) {
        ServiceJourneyEventDto dto = new ServiceJourneyEventDto();
        dto.setId(entity.getId());
        dto.setServiceRequestId(entity.getServiceRequestId());
        dto.setEventType(entity.getEventType());
        dto.setTitle(entity.getTitle());
        dto.setDescription(entity.getDescription());
        dto.setCreatedBy(entity.getCreatedBy());
        dto.setMetadata(entity.getMetadata());
        dto.setCreatedAt(entity.getCreatedAt());
        return dto;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getServiceRequestId() { return serviceRequestId; }
    public void setServiceRequestId(UUID serviceRequestId) { this.serviceRequestId = serviceRequestId; }

    public ServiceJourneyEventType getEventType() { return eventType; }
    public void setEventType(ServiceJourneyEventType eventType) { this.eventType = eventType; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public UUID getCreatedBy() { return createdBy; }
    public void setCreatedBy(UUID createdBy) { this.createdBy = createdBy; }

    public String getMetadata() { return metadata; }
    public void setMetadata(String metadata) { this.metadata = metadata; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }
}
