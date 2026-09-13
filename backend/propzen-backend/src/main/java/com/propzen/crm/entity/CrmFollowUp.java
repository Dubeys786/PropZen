package com.propzen.crm.entity;

import com.propzen.crm.model.FollowUpPriority;
import com.propzen.crm.model.FollowUpStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Entity representing scheduled follow-up actions for leads.
 */
@Entity
@Table(name = "crm_followups")
public class CrmFollowUp implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "lead_id")
    private UUID leadId;

    @Column(name = "assigned_to")
    private UUID assignedTo;

    @Column(name = "title", nullable = false)
    private String title;

    @Column(name = "description", columnDefinition = "text")
    private String description;

    @Column(name = "followup_at", nullable = false)
    private OffsetDateTime followupAt;

    @Enumerated(EnumType.STRING)
    @Column(name = "priority", nullable = false)
    private FollowUpPriority priority = FollowUpPriority.MEDIUM;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private FollowUpStatus status = FollowUpStatus.PENDING;

    @Column(name = "completed_at")
    private OffsetDateTime completedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    public CrmFollowUp() {
    }

    public CrmFollowUp(UUID leadId, UUID assignedTo, String title, String description, OffsetDateTime followupAt, FollowUpPriority priority) {
        this.leadId = leadId;
        this.assignedTo = assignedTo;
        this.title = title;
        this.description = description;
        this.followupAt = followupAt;
        this.priority = priority != null ? priority : FollowUpPriority.MEDIUM;
        this.status = FollowUpStatus.PENDING;
    }

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = OffsetDateTime.now();
        }
        if (updatedAt == null) {
            updatedAt = OffsetDateTime.now();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = OffsetDateTime.now();
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getLeadId() {
        return leadId;
    }

    public void setLeadId(UUID leadId) {
        this.leadId = leadId;
    }

    public UUID getAssignedTo() {
        return assignedTo;
    }

    public void setAssignedTo(UUID assignedTo) {
        this.assignedTo = assignedTo;
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

    public OffsetDateTime getFollowupAt() {
        return followupAt;
    }

    public void setFollowupAt(OffsetDateTime followupAt) {
        this.followupAt = followupAt;
    }

    public FollowUpPriority getPriority() {
        return priority;
    }

    public void setPriority(FollowUpPriority priority) {
        this.priority = priority;
    }

    public FollowUpStatus getStatus() {
        return status;
    }

    public void setStatus(FollowUpStatus status) {
        this.status = status;
    }

    public OffsetDateTime getCompletedAt() {
        return completedAt;
    }

    public void setCompletedAt(OffsetDateTime completedAt) {
        this.completedAt = completedAt;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(OffsetDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
