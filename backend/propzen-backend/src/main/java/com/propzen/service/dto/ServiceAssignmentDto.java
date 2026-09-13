package com.propzen.service.dto;

import com.propzen.service.entity.ServiceRequestAssignment;
import com.propzen.service.model.AssignmentStatus;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public class ServiceAssignmentDto {
    private UUID id;
    private UUID serviceRequestId;
    private UUID partnerId;
    private UUID assignedBy;
    private AssignmentStatus assignmentStatus;
    private BigDecimal assignmentScore;
    private OffsetDateTime assignedAt;
    private OffsetDateTime acceptedAt;
    private OffsetDateTime rejectedAt;
    private String notes;

    public static ServiceAssignmentDto fromEntity(ServiceRequestAssignment entity) {
        ServiceAssignmentDto dto = new ServiceAssignmentDto();
        dto.setId(entity.getId());
        dto.setServiceRequestId(entity.getServiceRequestId());
        dto.setPartnerId(entity.getPartnerId());
        dto.setAssignedBy(entity.getAssignedBy());
        dto.setAssignmentStatus(entity.getAssignmentStatus());
        dto.setAssignmentScore(entity.getAssignmentScore());
        dto.setAssignedAt(entity.getAssignedAt());
        dto.setAcceptedAt(entity.getAcceptedAt());
        dto.setRejectedAt(entity.getRejectedAt());
        dto.setNotes(entity.getNotes());
        return dto;
    }

    public UUID getId() { return id; }
    public void setId(UUID id) { this.id = id; }

    public UUID getServiceRequestId() { return serviceRequestId; }
    public void setServiceRequestId(UUID serviceRequestId) { this.serviceRequestId = serviceRequestId; }

    public UUID getPartnerId() { return partnerId; }
    public void setPartnerId(UUID partnerId) { this.partnerId = partnerId; }

    public UUID getAssignedBy() { return assignedBy; }
    public void setAssignedBy(UUID assignedBy) { this.assignedBy = assignedBy; }

    public AssignmentStatus getAssignmentStatus() { return assignmentStatus; }
    public void setAssignmentStatus(AssignmentStatus assignmentStatus) { this.assignmentStatus = assignmentStatus; }

    public BigDecimal getAssignmentScore() { return assignmentScore; }
    public void setAssignmentScore(BigDecimal assignmentScore) { this.assignmentScore = assignmentScore; }

    public OffsetDateTime getAssignedAt() { return assignedAt; }
    public void setAssignedAt(OffsetDateTime assignedAt) { this.assignedAt = assignedAt; }

    public OffsetDateTime getAcceptedAt() { return acceptedAt; }
    public void setAcceptedAt(OffsetDateTime acceptedAt) { this.acceptedAt = acceptedAt; }

    public OffsetDateTime getRejectedAt() { return rejectedAt; }
    public void setRejectedAt(OffsetDateTime rejectedAt) { this.rejectedAt = rejectedAt; }

    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }
}
