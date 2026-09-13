package com.propzen.crm.dto;

import com.propzen.crm.entity.Lead;
import com.propzen.crm.model.LeadPriority;
import com.propzen.crm.model.LeadSource;
import com.propzen.crm.model.LeadStage;
import com.propzen.crm.model.LeadStatus;
import com.propzen.crm.model.LeadType;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

public class LeadDto {

    private UUID id;
    private String leadNumber;
    private UUID userId;
    private String propertyId;
    private UUID dealerId;
    private UUID assignedTo;
    private String name;
    private String email;
    private String phone;
    private String message;
    private LeadSource source;
    private LeadStatus status;
    private LeadStage stage;
    private LeadType leadType;
    private String notes;
    private LeadPriority priority;
    private Integer leadScore;
    private BigDecimal budgetMin;
    private BigDecimal budgetMax;
    private String preferredCity;
    private String preferredSector;
    private String preferredPropertyType;
    private String preferredBhk;
    private OffsetDateTime nextFollowUpAt;
    private OffsetDateTime lastContactedAt;
    private OffsetDateTime convertedAt;
    private OffsetDateTime lostAt;
    private String lostReason;
    private String serviceCategory;
    private UUID assignedPartnerId;
    private String assignmentStatus;
    private String assignedPartnerName;
    private OffsetDateTime createdAt;
    private OffsetDateTime updatedAt;

    public LeadDto() {
    }

    public static LeadDto fromEntity(Lead lead) {
        if (lead == null) return null;
        LeadDto dto = new LeadDto();
        dto.setId(lead.getId());
        dto.setLeadNumber(lead.getLeadNumber());
        dto.setUserId(lead.getUserId());
        dto.setPropertyId(lead.getPropertyId());
        dto.setDealerId(lead.getDealerId());
        dto.setAssignedTo(lead.getAssignedTo());
        dto.setName(lead.getName());
        dto.setEmail(lead.getEmail());
        dto.setPhone(lead.getPhone());
        dto.setMessage(lead.getMessage());
        dto.setSource(lead.getSource());
        dto.setStatus(lead.getStatus());
        dto.setStage(lead.getStage());
        dto.setLeadType(lead.getLeadType());
        dto.setNotes(lead.getNotes());
        dto.setPriority(lead.getPriority());
        dto.setLeadScore(lead.getLeadScore());
        dto.setBudgetMin(lead.getBudgetMin());
        dto.setBudgetMax(lead.getBudgetMax());
        dto.setPreferredCity(lead.getPreferredCity());
        dto.setPreferredSector(lead.getPreferredSector());
        dto.setPreferredPropertyType(lead.getPreferredPropertyType());
        dto.setPreferredBhk(lead.getPreferredBhk());
        dto.setNextFollowUpAt(lead.getNextFollowUpAt());
        dto.setLastContactedAt(lead.getLastContactedAt());
        dto.setConvertedAt(lead.getConvertedAt());
        dto.setLostAt(lead.getLostAt());
        dto.setLostReason(lead.getLostReason());
        dto.setServiceCategory(lead.getServiceCategory());
        dto.setAssignedPartnerId(lead.getAssignedPartnerId());
        dto.setAssignmentStatus(lead.getAssignmentStatus() != null ? lead.getAssignmentStatus() : "UNASSIGNED");
        dto.setCreatedAt(lead.getCreatedAt());
        dto.setUpdatedAt(lead.getUpdatedAt());
        return dto;
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

    public String getAssignedPartnerName() {
        return assignedPartnerName;
    }

    public void setAssignedPartnerName(String assignedPartnerName) {
        this.assignedPartnerName = assignedPartnerName;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(OffsetDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
