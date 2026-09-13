package com.propzen.service.dto;

import com.propzen.service.entity.ServiceDeliverable;

import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.UUID;

public class ServiceDeliverableDto implements Serializable {

    private UUID id;
    private UUID serviceRequestId;
    private String title;
    private String description;
    private String fileUrl;
    private String status;
    private UUID submittedBy;
    private OffsetDateTime createdAt;

    public ServiceDeliverableDto() {
    }

    public static ServiceDeliverableDto fromEntity(ServiceDeliverable entity) {
        if (entity == null) return null;
        ServiceDeliverableDto dto = new ServiceDeliverableDto();
        dto.setId(entity.getId());
        dto.setServiceRequestId(entity.getServiceRequestId());
        dto.setTitle(entity.getTitle());
        dto.setDescription(entity.getDescription());
        dto.setFileUrl(entity.getFileUrl());
        dto.setStatus(entity.getStatus());
        dto.setSubmittedBy(entity.getSubmittedBy());
        dto.setCreatedAt(entity.getCreatedAt());
        return dto;
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getServiceRequestId() {
        return serviceRequestId;
    }

    public void setServiceRequestId(UUID serviceRequestId) {
        this.serviceRequestId = serviceRequestId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getFileUrl() {
        return fileUrl;
    }

    public void setFileUrl(String fileUrl) {
        this.fileUrl = fileUrl;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public UUID getSubmittedBy() {
        return submittedBy;
    }

    public void setSubmittedBy(UUID submittedBy) {
        this.submittedBy = submittedBy;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
