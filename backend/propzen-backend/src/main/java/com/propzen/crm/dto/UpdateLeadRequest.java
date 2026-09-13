package com.propzen.crm.dto;

import com.propzen.crm.model.LeadPriority;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.OffsetDateTime;

public class UpdateLeadRequest {

    @Size(max = 255)
    private String name;

    private String email;

    @Size(max = 50)
    private String phone;

    private String message;
    private LeadPriority priority;
    private BigDecimal budgetMin;
    private BigDecimal budgetMax;
    private String preferredCity;
    private String preferredSector;
    private String preferredPropertyType;
    private String preferredBhk;
    private OffsetDateTime nextFollowUpAt;
    private String metadata;

    public UpdateLeadRequest() {
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

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
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

    public OffsetDateTime getNextFollowUpAt() {
        return nextFollowUpAt;
    }

    public void setNextFollowUpAt(OffsetDateTime nextFollowUpAt) {
        this.nextFollowUpAt = nextFollowUpAt;
    }

    public String getMetadata() {
        return metadata;
    }

    public void setMetadata(String metadata) {
        this.metadata = metadata;
    }
}
