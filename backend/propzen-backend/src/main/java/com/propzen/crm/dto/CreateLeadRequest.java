package com.propzen.crm.dto;

import com.propzen.crm.model.LeadPriority;
import com.propzen.crm.model.LeadSource;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.util.UUID;

public class CreateLeadRequest {

    @NotBlank(message = "Name is required")
    @Size(max = 255, message = "Name must not exceed 255 characters")
    private String name;

    private String email;

    @NotBlank(message = "Phone is required")
    @Size(max = 50, message = "Phone must not exceed 50 characters")
    private String phone;

    private String propertyId;
    private String message;
    private LeadSource source = LeadSource.WEBSITE;
    private LeadPriority priority = LeadPriority.MEDIUM;
    private BigDecimal budgetMin;
    private BigDecimal budgetMax;
    private String preferredCity;
    private String preferredSector;
    private String preferredPropertyType;
    private String preferredBhk;
    private UUID assignedTo;
    private UUID dealerId;
    private com.propzen.crm.model.LeadStage stage = com.propzen.crm.model.LeadStage.NEW_LEAD;
    private com.propzen.crm.model.LeadType leadType = com.propzen.crm.model.LeadType.BUYER;
    private String notes;
    private String serviceCategory;
    private UUID assignedPartnerId;
    private String assignmentStatus = "UNASSIGNED";

    public CreateLeadRequest() {
    }

    // Getters and Setters

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

    public String getPropertyId() {
        return propertyId;
    }

    public void setPropertyId(String propertyId) {
        this.propertyId = propertyId;
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

    public LeadPriority getPriority() {
        return priority;
    }

    public void setPriority(LeadPriority priority) {
        this.priority = priority;
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

    public UUID getAssignedTo() {
        return assignedTo;
    }

    public void setAssignedTo(UUID assignedTo) {
        this.assignedTo = assignedTo;
    }

    public UUID getDealerId() {
        return dealerId;
    }

    public com.propzen.crm.model.LeadStage getStage() {
        return stage;
    }

    public void setStage(com.propzen.crm.model.LeadStage stage) {
        this.stage = stage;
    }

    public com.propzen.crm.model.LeadType getLeadType() {
        return leadType;
    }

    public void setLeadType(com.propzen.crm.model.LeadType leadType) {
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
}
