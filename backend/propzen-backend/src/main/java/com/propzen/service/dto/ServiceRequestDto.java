package com.propzen.service.dto;

import com.propzen.service.entity.ServiceRequest;
import com.propzen.service.model.ServicePriority;
import com.propzen.service.model.ServiceRequestStatus;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public class ServiceRequestDto {
    private UUID id;
    private String serviceNumber;
    private UUID customerId;
    private UUID partnerId;
    private UUID serviceCategoryId;
    private String categoryName;
    private String propertyId;
    private String title;
    private String description;
    private String location;
    private BigDecimal budget;
    private OffsetDateTime preferredDate;
    private String preferredTime;
    private ServicePriority priority;
    private ServiceRequestStatus status;
    private OffsetDateTime assignedAt;
    private OffsetDateTime startedAt;
    private OffsetDateTime completedAt;
    private OffsetDateTime cancelledAt;
    private String rejectionReason;
    private String cancellationReason;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    public static ServiceRequestDto fromEntity(ServiceRequest entity) {
        ServiceRequestDto dto = new ServiceRequestDto();
        dto.setId(entity.getId());
        dto.setServiceNumber(entity.getServiceNumber());
        dto.setCustomerId(entity.getCustomerId());
        dto.setPartnerId(entity.getPartnerId());
        dto.setServiceCategoryId(entity.getServiceCategoryId());
        dto.setPropertyId(entity.getPropertyId());
        dto.setTitle(entity.getTitle());
        dto.setDescription(entity.getDescription());
        dto.setLocation(entity.getLocation());
        dto.setBudget(entity.getBudget());
        dto.setPreferredDate(entity.getPreferredDate());
        dto.setPreferredTime(entity.getPreferredTime());
        dto.setPriority(entity.getPriority());
        dto.setStatus(entity.getStatus());
        dto.setAssignedAt(entity.getAssignedAt());
        dto.setStartedAt(entity.getStartedAt());
        dto.setCompletedAt(entity.getCompletedAt());
        dto.setCancelledAt(entity.getCancelledAt());
        dto.setRejectionReason(entity.getRejectionReason());
        dto.setCancellationReason(entity.getCancellationReason());
        dto.setCreatedAt(entity.getCreatedAt());
        dto.setUpdatedAt(entity.getUpdatedAt());
        return dto;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public String getServiceNumber() { return serviceNumber; }
    public void setServiceNumber(String serviceNumber) { this.serviceNumber = serviceNumber; }

    public UUID getCustomerId() { return customerId; }
    public void setCustomerId(UUID customerId) { this.customerId = customerId; }

    public UUID getPartnerId() { return partnerId; }
    public void setPartnerId(UUID partnerId) { this.partnerId = partnerId; }

    public UUID getServiceCategoryId() { return serviceCategoryId; }
    public void setServiceCategoryId(UUID serviceCategoryId) { this.serviceCategoryId = serviceCategoryId; }

    public String getCategoryName() { return categoryName; }
    public void setCategoryName(String categoryName) { this.categoryName = categoryName; }

    public String getPropertyId() { return propertyId; }
    public void setPropertyId(String propertyId) { this.propertyId = propertyId; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public BigDecimal getBudget() { return budget; }
    public void setBudget(BigDecimal budget) { this.budget = budget; }

    public OffsetDateTime getPreferredDate() { return preferredDate; }
    public void setPreferredDate(OffsetDateTime preferredDate) { this.preferredDate = preferredDate; }

    public String getPreferredTime() { return preferredTime; }
    public void setPreferredTime(String preferredTime) { this.preferredTime = preferredTime; }

    public ServicePriority getPriority() { return priority; }
    public void setPriority(ServicePriority priority) { this.priority = priority; }

    public ServiceRequestStatus getStatus() { return status; }
    public void setStatus(ServiceRequestStatus status) { this.status = status; }

    public OffsetDateTime getAssignedAt() { return assignedAt; }
    public void setAssignedAt(OffsetDateTime assignedAt) { this.assignedAt = assignedAt; }

    public OffsetDateTime getStartedAt() { return startedAt; }
    public void setStartedAt(OffsetDateTime startedAt) { this.startedAt = startedAt; }

    public OffsetDateTime getCompletedAt() { return completedAt; }
    public void setCompletedAt(OffsetDateTime completedAt) { this.completedAt = completedAt; }

    public OffsetDateTime getCancelledAt() { return cancelledAt; }
    public void setCancelledAt(OffsetDateTime cancelledAt) { this.cancelledAt = cancelledAt; }

    public String getRejectionReason() { return rejectionReason; }
    public void setRejectionReason(String rejectionReason) { this.rejectionReason = rejectionReason; }

    public String getCancellationReason() { return cancellationReason; }
    public void setCancellationReason(String cancellationReason) { this.cancellationReason = cancellationReason; }

    public OffsetDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(OffsetDateTime createdAt) { this.createdAt = createdAt; }

    public OffsetDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(OffsetDateTime updatedAt) { this.updatedAt = updatedAt; }
}
