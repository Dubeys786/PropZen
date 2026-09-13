package com.propzen.crm.entity;

import com.propzen.crm.model.LeadPriority;
import com.propzen.crm.model.LeadSource;
import com.propzen.crm.model.LeadStage;
import com.propzen.crm.model.LeadStatus;
import com.propzen.crm.model.LeadType;
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
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

/**
 * Authoritative JPA entity representing a CRM lead.
 */
@Entity
@Table(name = "crm_leads")
public class Lead implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", nullable = false, updatable = false)
    private UUID id;

    @Column(name = "lead_number", nullable = false, unique = true)
    private String leadNumber;

    @Column(name = "user_id")
    private UUID userId;

    @Column(name = "property_id")
    private String propertyId;

    @Column(name = "dealer_id")
    private UUID dealerId;

    @Column(name = "assigned_to")
    private UUID assignedTo;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "email")
    private String email;

    @Column(name = "phone", nullable = false)
    private String phone;

    @Column(name = "message", columnDefinition = "text")
    private String message;

    @Enumerated(EnumType.STRING)
    @Column(name = "source", nullable = false)
    private LeadSource source = LeadSource.PROPERTY_ENQUIRY;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private LeadStatus status = LeadStatus.NEW;

    @Enumerated(EnumType.STRING)
    @Column(name = "stage", nullable = false)
    private LeadStage stage = LeadStage.NEW_LEAD;

    @Enumerated(EnumType.STRING)
    @Column(name = "lead_type")
    private LeadType leadType = LeadType.BUYER;

    @Column(name = "notes", columnDefinition = "text")
    private String notes;

    @Enumerated(EnumType.STRING)
    @Column(name = "priority", nullable = false)
    private LeadPriority priority = LeadPriority.MEDIUM;

    @Column(name = "lead_score", nullable = false)
    private Integer leadScore = 50;

    @Column(name = "budget_min", precision = 12, scale = 4)
    private BigDecimal budgetMin;

    @Column(name = "budget_max", precision = 12, scale = 4)
    private BigDecimal budgetMax;

    @Column(name = "preferred_city")
    private String preferredCity;

    @Column(name = "preferred_sector")
    private String preferredSector;

    @Column(name = "preferred_property_type")
    private String preferredPropertyType;

    @Column(name = "preferred_bhk")
    private String preferredBhk;

    @Column(name = "next_follow_up_at")
    private OffsetDateTime nextFollowUpAt;

    @Column(name = "last_contacted_at")
    private OffsetDateTime lastContactedAt;

    @Column(name = "converted_at")
    private OffsetDateTime convertedAt;

    @Column(name = "lost_at")
    private OffsetDateTime lostAt;

    @Column(name = "lost_reason", columnDefinition = "text")
    private String lostReason;

    @Column(name = "metadata", columnDefinition = "text")
    private String metadata;

    @Column(name = "service_category", length = 100)
    private String serviceCategory;

    @Column(name = "assigned_partner_id")
    private UUID assignedPartnerId;

    @Column(name = "assignment_status", length = 50)
    private String assignmentStatus = "UNASSIGNED";

    @Column(name = "created_at", nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    public Lead() {
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

    // Getters and Setters

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public String getLeadNumber() {
        return leadNumber;
    }

    public void setLeadNumber(String leadNumber) {
        this.leadNumber = leadNumber;
    }

    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public String getPropertyId() {
        return propertyId;
    }

    public void setPropertyId(String propertyId) {
        this.propertyId = propertyId;
    }

    public UUID getDealerId() {
        return dealerId;
    }

    public void setDealerId(UUID dealerId) {
        this.dealerId = dealerId;
    }

    public UUID getAssignedTo() {
        return assignedTo;
    }

    public void setAssignedTo(UUID assignedTo) {
        this.assignedTo = assignedTo;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public LeadSource getSource() {
        return source;
    }

    public void setSource(LeadSource source) {
        this.source = source;
    }

    public LeadStatus getStatus() {
        return status;
    }

    public void setStatus(LeadStatus status) {
        this.status = status;
    }

    public LeadPriority getPriority() {
        return priority;
    }

    public void setPriority(LeadPriority priority) {
        this.priority = priority;
    }

    public Integer getLeadScore() {
        return leadScore;
    }

    public void setLeadScore(Integer leadScore) {
        this.leadScore = leadScore;
    }

    public BigDecimal getBudgetMin() {
        return budgetMin;
    }

    public void setBudgetMin(BigDecimal budgetMin) {
        this.budgetMin = budgetMin;
    }

    public BigDecimal getBudgetMax() {
        return budgetMax;
    }

    public void setBudgetMax(BigDecimal budgetMax) {
        this.budgetMax = budgetMax;
    }

    public String getPreferredCity() {
        return preferredCity;
    }

    public void setPreferredCity(String preferredCity) {
        this.preferredCity = preferredCity;
    }

    public String getPreferredSector() {
        return preferredSector;
    }

    public void setPreferredSector(String preferredSector) {
        this.preferredSector = preferredSector;
    }

    public String getPreferredPropertyType() {
        return preferredPropertyType;
    }

    public void setPreferredPropertyType(String preferredPropertyType) {
        this.preferredPropertyType = preferredPropertyType;
    }

    public String getPreferredBhk() {
        return preferredBhk;
    }

    public void setPreferredBhk(String preferredBhk) {
        this.preferredBhk = preferredBhk;
    }

    public OffsetDateTime getNextFollowUpAt() {
        return nextFollowUpAt;
    }

    public void setNextFollowUpAt(OffsetDateTime nextFollowUpAt) {
        this.nextFollowUpAt = nextFollowUpAt;
    }

    public OffsetDateTime getLastContactedAt() {
        return lastContactedAt;
    }

    public void setLastContactedAt(OffsetDateTime lastContactedAt) {
        this.lastContactedAt = lastContactedAt;
    }

    public OffsetDateTime getConvertedAt() {
        return convertedAt;
    }

    public void setConvertedAt(OffsetDateTime convertedAt) {
        this.convertedAt = convertedAt;
    }

    public OffsetDateTime getLostAt() {
        return lostAt;
    }

    public void setLostAt(OffsetDateTime lostAt) {
        this.lostAt = lostAt;
    }

    public String getLostReason() {
        return lostReason;
    }

    public void setLostReason(String lostReason) {
        this.lostReason = lostReason;
    }

    public String getMetadata() {
        return metadata;
    }

    public void setMetadata(String metadata) {
        this.metadata = metadata;
    }

    public OffsetDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(OffsetDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LeadStage getStage() {
        return stage;
    }

    public void setStage(LeadStage stage) {
        this.stage = stage;
    }

    public LeadType getLeadType() {
        return leadType;
    }

    public void setLeadType(LeadType leadType) {
        this.leadType = leadType;
    }

    public String getNotes() {
        return notes;
    }

    public void setNotes(String notes) {
        this.notes = notes;
    }

    public String getServiceCategory() {
        return serviceCategory;
    }

    public void setServiceCategory(String serviceCategory) {
        this.serviceCategory = serviceCategory;
    }

    public UUID getAssignedPartnerId() {
        return assignedPartnerId;
    }

    public void setAssignedPartnerId(UUID assignedPartnerId) {
        this.assignedPartnerId = assignedPartnerId;
    }

    public String getAssignmentStatus() {
        return assignmentStatus;
    }

    public void setAssignmentStatus(String assignmentStatus) {
        this.assignmentStatus = assignmentStatus;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(OffsetDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
